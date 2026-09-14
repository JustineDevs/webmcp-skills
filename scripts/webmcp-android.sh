#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-android.sh probe [serial]
  scripts/webmcp-android.sh devices
  scripts/webmcp-android.sh screenshot [serial] <path>
  scripts/webmcp-android.sh dump-ui [serial] <path>
  scripts/webmcp-android.sh tap [serial] <x> <y>
  scripts/webmcp-android.sh swipe [serial] <x1> <y1> <x2> <y2> [duration-ms]
  scripts/webmcp-android.sh text [serial] <text>
  scripts/webmcp-android.sh keyevent [serial] <keycode>
  scripts/webmcp-android.sh launch [serial] <package> [activity]
  scripts/webmcp-android.sh shell [serial] -- <command> [args...]

The serial is optional only when exactly one authorized device is connected.
WEBMCP_ANDROID_SERIAL can provide the default serial. WEBMCP_ALLOW_SHELL=1 is
required for the raw shell command because it crosses from page automation into
the device OS.
EOF
}

die() {
  printf 'webmcp-android: %s\n' "$1" >&2
  exit 2
}

find_adb() {
  if [[ -n "${WEBMCP_ADB_BIN:-}" ]]; then
    printf '%s\n' "$WEBMCP_ADB_BIN"
    return
  fi
  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return
  fi
  local sdk_root candidate
  for sdk_root in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk"; do
    candidate="$sdk_root/platform-tools/adb"
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done
  candidate=$(find /home /opt /usr/local -path '*/platform-tools/adb' -type f -perm -111 -print -quit 2>/dev/null || true)
  [[ -n "$candidate" ]] && printf '%s\n' "$candidate" && return
}

adb_bin=$(find_adb || true)

require_adb() {
  [[ -n "$adb_bin" ]] || die 'adb is not installed or no Android SDK platform-tools/adb was found'
}

adb_cmd() {
  "$adb_bin" "$@"
}

json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

devices_raw() {
  require_adb
  adb_cmd devices -l
}

device_rows() {
  devices_raw | awk 'NR > 1 && $2 == "device" { print }'
}

resolve_serial() {
  local requested=${1:-${WEBMCP_ANDROID_SERIAL:-}}
  if [[ -n "$requested" ]]; then
    printf '%s\n' "$requested"
    return
  fi
  mapfile -t rows < <(device_rows)
  case "${#rows[@]}" in
    0) die 'no authorized Android device or emulator is connected' ;;
    1) awk '{print $1}' <<<"${rows[0]}" ;;
    *) die 'multiple Android devices are connected; pass an explicit serial' ;;
  esac
}

getprop() {
  local serial=$1 property=$2
  adb_cmd -s "$serial" shell getprop "$property" | tr -d '\r' | sed -n '1p'
}

probe() {
  local requested=${1:-}
  if [[ -z "$adb_bin" ]]; then
    printf '{"adapter":"adb","status":"unavailable","reason":"adb is not installed or no Android SDK platform-tools/adb was found"}\n'
    return 0
  fi
  if ! "$adb_bin" version >/dev/null 2>&1; then
    printf '{"adapter":"adb","status":"unavailable","reason":"adb could not start"}\n'
    return 0
  fi
  mapfile -t rows < <(device_rows)
  if [[ ${#rows[@]} -eq 0 ]]; then
    printf '{"adapter":"adb","status":"unavailable","reason":"no authorized device or emulator","devices":[]}\n'
    return 0
  fi
  local serial
  if [[ -n "$requested" ]]; then
    serial=$requested
  elif [[ -n "${WEBMCP_ANDROID_SERIAL:-}" ]]; then
    serial=$WEBMCP_ANDROID_SERIAL
  elif [[ ${#rows[@]} -eq 1 ]]; then
    serial=$(awk '{print $1}' <<<"${rows[0]}")
  else
    printf '{"adapter":"adb","status":"blocked","reason":"multiple devices; pass a serial","devices":['
    local first=1 row
    for row in "${rows[@]}"; do
      [[ $first -eq 0 ]] && printf ','
      first=0
      printf '%s' "$(json_escape "$(awk '{print $1}' <<<"$row")")"
    done
    printf ']}\n'
    return 0
  fi
  local state model manufacturer device release sdk
  state=$(adb_cmd -s "$serial" get-state 2>/dev/null | tr -d '\r' | sed -n '1p' || true)
  if [[ "$state" != device ]]; then
    printf '{"adapter":"adb","status":"unavailable","serial":%s,"state":%s}\n' "$(json_escape "$serial")" "$(json_escape "${state:-offline}")"
    return 0
  fi
  model=$(getprop "$serial" ro.product.model)
  manufacturer=$(getprop "$serial" ro.product.manufacturer)
  device=$(getprop "$serial" ro.product.device)
  release=$(getprop "$serial" ro.build.version.release)
  sdk=$(getprop "$serial" ro.build.version.sdk)
  printf '{"adapter":"adb","status":"ready","serial":%s,"model":%s,"manufacturer":%s,"device":%s,"android":%s,"sdk":%s,"capabilities":{"observe":true,"screenshot":true,"dumpUi":true,"tap":true,"swipe":true,"text":true,"keyevent":true,"launch":true,"shell":%s}}\n' \
    "$(json_escape "$serial")" "$(json_escape "$model")" "$(json_escape "$manufacturer")" "$(json_escape "$device")" "$(json_escape "$release")" "$(json_escape "$sdk")" "$(if [[ "${WEBMCP_ALLOW_SHELL:-0}" == 1 ]]; then printf true; else printf false; fi)"
}

serial_and_path() {
  [[ $# -ge 2 ]] || die 'a serial/path or path is required'
  if [[ $# -eq 2 ]]; then
    printf '%s\n%s\n' "$(resolve_serial)" "$2"
  else
    printf '%s\n%s\n' "$(resolve_serial "$2")" "$3"
  fi
}

case "${1:-}" in
  devices)
    [[ $# -eq 1 ]] || die 'devices takes no arguments'
    devices_raw
    ;;
  probe)
    [[ $# -le 2 ]] || die 'probe accepts an optional serial'
    probe "${2:-}"
    ;;
  screenshot|dump-ui)
    mapfile -t values < <(serial_and_path "$@")
    serial=${values[0]}
    output=${values[1]}
    mkdir -p "$(dirname -- "$output")"
    if [[ "$1" == screenshot ]]; then
      adb_cmd -s "$serial" exec-out screencap -p >"$output"
      printf '{"adapter":"adb","status":"completed","action":"screenshot","serial":%s,"path":%s}\n' "$(json_escape "$serial")" "$(json_escape "$output")"
    else
      adb_cmd -s "$serial" exec-out uiautomator dump /dev/tty 2>/dev/null >"$output"
      printf '{"adapter":"adb","status":"completed","action":"dump-ui","serial":%s,"path":%s}\n' "$(json_escape "$serial")" "$(json_escape "$output")"
    fi
    ;;
  tap)
    [[ $# -eq 3 || $# -eq 4 ]] || die 'tap requires [serial] x y'
    if [[ $# -eq 3 ]]; then serial=$(resolve_serial); x=$2; y=$3; else serial=$(resolve_serial "$2"); x=$3; y=$4; fi
    [[ "$x" =~ ^[0-9]+$ && "$y" =~ ^[0-9]+$ ]] || die 'tap coordinates must be non-negative integers'
    adb_cmd -s "$serial" shell input tap "$x" "$y"
    printf '{"adapter":"adb","status":"completed","action":"tap","serial":%s,"x":%s,"y":%s}\n' "$(json_escape "$serial")" "$x" "$y"
    ;;
  swipe)
    [[ $# -ge 6 && $# -le 8 ]] || die 'swipe requires [serial] x1 y1 x2 y2 [duration-ms]'
    if [[ "$2" =~ ^[0-9]+$ ]]; then
      serial=$(resolve_serial); x1=$2; y1=$3; x2=$4; y2=$5; duration=${6:-300}
    else
      serial=$(resolve_serial "$2"); x1=$3; y1=$4; x2=$5; y2=$6; duration=${7:-300}
    fi
    for value in "$x1" "$y1" "$x2" "$y2" "$duration"; do [[ "$value" =~ ^[0-9]+$ ]] || die 'swipe values must be non-negative integers'; done
    adb_cmd -s "$serial" shell input swipe "$x1" "$y1" "$x2" "$y2" "$duration"
    printf '{"adapter":"adb","status":"completed","action":"swipe","serial":%s}\n' "$(json_escape "$serial")"
    ;;
  text)
    [[ $# -eq 2 || $# -eq 3 ]] || die 'text requires [serial] text'
    if [[ $# -eq 2 ]]; then serial=$(resolve_serial); value=$2; else serial=$(resolve_serial "$2"); value=$3; fi
    adb_cmd -s "$serial" shell input text "$value"
    printf '{"adapter":"adb","status":"completed","action":"text","serial":%s}\n' "$(json_escape "$serial")"
    ;;
  keyevent)
    [[ $# -eq 2 || $# -eq 3 ]] || die 'keyevent requires [serial] keycode'
    if [[ $# -eq 2 ]]; then serial=$(resolve_serial); key=$2; else serial=$(resolve_serial "$2"); key=$3; fi
    [[ "$key" =~ ^[A-Za-z0-9_]+$ ]] || die 'keycode contains unsupported characters'
    adb_cmd -s "$serial" shell input keyevent "$key"
    printf '{"adapter":"adb","status":"completed","action":"keyevent","serial":%s,"keycode":%s}\n' "$(json_escape "$serial")" "$(json_escape "$key")"
    ;;
  launch)
    [[ $# -eq 2 || $# -eq 3 || $# -eq 4 ]] || die 'launch requires [serial] package [activity]'
    if [[ $# -le 3 && "$2" =~ ^[A-Za-z0-9_.]+$ ]]; then
      serial=$(resolve_serial); package=$2; activity=${3:-}
    else
      serial=$(resolve_serial "$2"); package=$3; activity=${4:-}
    fi
    [[ "$package" =~ ^[A-Za-z0-9_.]+$ ]] || die 'package contains unsupported characters'
    if [[ -n "$activity" ]]; then
      [[ "$activity" =~ ^[A-Za-z0-9_.$/]+$ ]] || die 'activity contains unsupported characters'
      component="$package/$activity"
      adb_cmd -s "$serial" shell am start -n "$component"
    else
      adb_cmd -s "$serial" shell monkey -p "$package" -c android.intent.category.LAUNCHER 1 >/dev/null
    fi
    printf '{"adapter":"adb","status":"completed","action":"launch","serial":%s,"package":%s}\n' "$(json_escape "$serial")" "$(json_escape "$package")"
    ;;
  shell)
    [[ "${WEBMCP_ALLOW_SHELL:-0}" == 1 ]] || die 'raw shell requires WEBMCP_ALLOW_SHELL=1'
    [[ $# -ge 3 ]] || die 'shell requires [serial] -- command [args...]'
    if [[ "$2" == -- ]]; then
      serial=$(resolve_serial); command_name=$3; shift 3
    else
      [[ "$3" == -- && $# -ge 4 ]] || die 'shell requires [serial] -- command [args...]'
      serial=$(resolve_serial "$2"); command_name=$4; shift 4
    fi
    [[ -n "$command_name" ]] || die 'shell command is empty'
    adb_cmd -s "$serial" shell "$command_name" "$@"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
