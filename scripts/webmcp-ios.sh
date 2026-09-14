#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-ios.sh probe [udid]
  scripts/webmcp-ios.sh devices
  scripts/webmcp-ios.sh boot [udid]
  scripts/webmcp-ios.sh shutdown [udid]
  scripts/webmcp-ios.sh screenshot [udid] <path>
  scripts/webmcp-ios.sh dump-ui [udid] <path>
  scripts/webmcp-ios.sh tap [udid] <x> <y>
  scripts/webmcp-ios.sh swipe [udid] <x1> <y1> <x2> <y2>
  scripts/webmcp-ios.sh text [udid] <text>
  scripts/webmcp-ios.sh launch [udid] <bundle-id>
  scripts/webmcp-ios.sh openurl [udid] <url>

The simulator UDID is optional only when exactly one booted simulator exists.
UI discovery and touch/text input use Facebook idb when installed; simctl
provides lifecycle, screenshots, app launch, and URL operations.
EOF
}

die() {
  printf 'webmcp-ios: %s\n' "$1" >&2
  exit 2
}

find_xcrun() {
  if [[ -n "${WEBMCP_XCRUN_BIN:-}" ]]; then printf '%s\n' "$WEBMCP_XCRUN_BIN"; return; fi
  command -v xcrun 2>/dev/null || true
}

xcrun_bin=$(find_xcrun)
idb_bin=${WEBMCP_IDB_BIN:-$(command -v idb 2>/dev/null || true)}

json_escape() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

require_xcrun() {
  [[ -n "$xcrun_bin" ]] || die 'xcrun is unavailable; iOS Simulator requires macOS with Xcode command-line tools'
}

simctl() {
  require_xcrun
  "$xcrun_bin" simctl "$@"
}

devices_json() {
  simctl list devices available --json
}

booted_udids() {
  devices_json | node -e '
    let input="";
    process.stdin.on("data", chunk => input += chunk);
    process.stdin.on("end", () => {
      const root = JSON.parse(input);
      for (const devices of Object.values(root.devices || {})) {
        for (const device of devices) if (device.state === "Booted") console.log(device.udid);
      }
    });
  '
}

resolve_udid() {
  local requested=${1:-${WEBMCP_IOS_UDID:-}}
  [[ -n "$requested" ]] && printf '%s\n' "$requested" && return
  mapfile -t booted < <(booted_udids)
  case "${#booted[@]}" in
    0) die 'no booted iOS simulator; pass a UDID after booting one' ;;
    1) printf '%s\n' "${booted[0]}" ;;
    *) die 'multiple iOS simulators are booted; pass an explicit UDID' ;;
  esac
}

probe() {
  local requested=${1:-}
  if [[ -z "$xcrun_bin" ]]; then
    printf '{"adapter":"ios-simctl","status":"unavailable","reason":"xcrun is unavailable; iOS Simulator requires macOS with Xcode command-line tools"}\n'
    return 0
  fi
  local data
  if ! data=$(devices_json 2>/dev/null); then
    printf '{"adapter":"ios-simctl","status":"unavailable","reason":"simctl could not list available devices"}\n'
    return 0
  fi
  printf '%s' "$data" | node -e '
    let input="";
    process.stdin.on("data", chunk => input += chunk);
    process.stdin.on("end", () => {
      const root = JSON.parse(input);
      const devices = [];
      for (const [runtime, entries] of Object.entries(root.devices || {})) {
        for (const device of entries) devices.push({runtime, name: device.name, udid: device.udid, state: device.state, available: device.isAvailable !== false});
      }
      const booted = devices.filter(device => device.state === "Booted");
      process.stdout.write(JSON.stringify({
        adapter: "ios-simctl",
        status: devices.length ? "ready" : "unavailable",
        selected: process.argv[1] || (booted.length === 1 ? booted[0].udid : null),
        devices,
        idb: process.env.WEBMCP_IDB_PRESENT === "1",
        capabilities: {lifecycle: true, screenshot: true, launch: true, openurl: true, dumpUi: process.env.WEBMCP_IDB_PRESENT === "1", tap: process.env.WEBMCP_IDB_PRESENT === "1", swipe: process.env.WEBMCP_IDB_PRESENT === "1", text: process.env.WEBMCP_IDB_PRESENT === "1"}
      }) + "\\n");
    });
  ' "$requested"
}

require_idb() {
  [[ -n "$idb_bin" ]] || die 'idb is required for iOS UI tree, tap, swipe, and text; install idb-companion and fb-idb'
}

idb_cmd() {
  require_idb
  "$idb_bin" "$@"
}

serial_and_path() {
  [[ $# -ge 2 ]] || die 'a UDID/path or path is required'
  if [[ $# -eq 2 ]]; then
    printf '%s\n%s\n' "$(resolve_udid)" "$2"
  else
    printf '%s\n%s\n' "$(resolve_udid "$2")" "$3"
  fi
}

case "${1:-}" in
  devices)
    [[ $# -eq 1 ]] || die 'devices takes no arguments'
    devices_json
    ;;
  probe)
    [[ $# -le 2 ]] || die 'probe accepts an optional UDID'
    WEBMCP_IDB_PRESENT=$([[ -n "$idb_bin" ]] && printf 1 || printf 0) probe "${2:-}"
    ;;
  boot)
    [[ $# -le 2 ]] || die 'boot accepts an optional UDID'
    udid=${2:-}
    [[ -n "$udid" ]] || udid=$(devices_json | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const r=JSON.parse(s);for(const ds of Object.values(r.devices||{})){const d=ds.find(x=>x.isAvailable!==false && x.state!=="Booted");if(d){process.stdout.write(d.udid);return}}process.exit(2)})') || die 'no available simulator to boot'
    simctl boot "$udid" >/dev/null
    printf '{"adapter":"ios-simctl","status":"completed","action":"boot","udid":%s}\n' "$(json_escape "$udid")"
    ;;
  shutdown)
    [[ $# -le 2 ]] || die 'shutdown accepts an optional UDID'
    udid=$(resolve_udid "${2:-}")
    simctl shutdown "$udid" >/dev/null
    printf '{"adapter":"ios-simctl","status":"completed","action":"shutdown","udid":%s}\n' "$(json_escape "$udid")"
    ;;
  screenshot|dump-ui)
    mapfile -t values < <(serial_and_path "$@")
    udid=${values[0]}; output=${values[1]}; mkdir -p "$(dirname -- "$output")"
    if [[ "$1" == screenshot ]]; then
      simctl io "$udid" screenshot "$output" >/dev/null
    else
      idb_cmd ui describe-all --udid "$udid" >"$output"
    fi
    printf '{"adapter":"ios-simctl","status":"completed","action":%s,"udid":%s,"path":%s}\n' "$(json_escape "$1")" "$(json_escape "$udid")" "$(json_escape "$output")"
    ;;
  tap)
    [[ $# -eq 3 || $# -eq 4 ]] || die 'tap requires [udid] x y'
    if [[ $# -eq 3 ]]; then udid=$(resolve_udid); x=$2; y=$3; else udid=$(resolve_udid "$2"); x=$3; y=$4; fi
    idb_cmd ui tap --udid "$udid" "$x" "$y"
    printf '{"adapter":"ios-simctl","status":"completed","action":"tap","udid":%s}\n' "$(json_escape "$udid")"
    ;;
  swipe)
    [[ $# -eq 5 || $# -eq 6 ]] || die 'swipe requires [udid] x1 y1 x2 y2'
    if [[ $# -eq 5 ]]; then udid=$(resolve_udid); x1=$2; y1=$3; x2=$4; y2=$5; else udid=$(resolve_udid "$2"); x1=$3; y1=$4; x2=$5; y2=$6; fi
    idb_cmd ui swipe --udid "$udid" "$x1" "$y1" "$x2" "$y2"
    printf '{"adapter":"ios-simctl","status":"completed","action":"swipe","udid":%s}\n' "$(json_escape "$udid")"
    ;;
  text)
    [[ $# -eq 2 || $# -eq 3 ]] || die 'text requires [udid] text'
    if [[ $# -eq 2 ]]; then udid=$(resolve_udid); value=$2; else udid=$(resolve_udid "$2"); value=$3; fi
    idb_cmd ui text --udid "$udid" "$value"
    printf '{"adapter":"ios-simctl","status":"completed","action":"text","udid":%s}\n' "$(json_escape "$udid")"
    ;;
  launch)
    [[ $# -eq 2 || $# -eq 3 ]] || die 'launch requires [udid] bundle-id'
    if [[ $# -eq 2 ]]; then udid=$(resolve_udid); bundle=$2; else udid=$(resolve_udid "$2"); bundle=$3; fi
    simctl launch "$udid" "$bundle"
    printf '{"adapter":"ios-simctl","status":"completed","action":"launch","udid":%s,"bundle":%s}\n' "$(json_escape "$udid")" "$(json_escape "$bundle")"
    ;;
  openurl)
    [[ $# -eq 2 || $# -eq 3 ]] || die 'openurl requires [udid] url'
    if [[ $# -eq 2 ]]; then udid=$(resolve_udid); url=$2; else udid=$(resolve_udid "$2"); url=$3; fi
    simctl openurl "$udid" "$url"
    printf '{"adapter":"ios-simctl","status":"completed","action":"openurl","udid":%s,"url":%s}\n' "$(json_escape "$udid")" "$(json_escape "$url")"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
