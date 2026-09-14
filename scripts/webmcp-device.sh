#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-device.sh probe [android|ios|desktop|all]
  scripts/webmcp-device.sh <android|ios|desktop> <adapter-command> [args...]

Examples:
  scripts/webmcp-device.sh probe all
  scripts/webmcp-device.sh android screenshot /tmp/android.png
  scripts/webmcp-device.sh ios screenshot <udid> /tmp/ios.png
  scripts/webmcp-device.sh desktop screenshot /tmp/desktop.png
EOF
}

die() {
  printf 'webmcp-device: %s\n' "$1" >&2
  exit 2
}

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

adapter_script() {
  case "$1" in
    android) printf '%s\n' "$repo_dir/scripts/webmcp-android.sh" ;;
    ios) printf '%s\n' "$repo_dir/scripts/webmcp-ios.sh" ;;
    desktop) printf '%s\n' "$repo_dir/scripts/webmcp-desktop.sh" ;;
    *) die "unknown adapter: $1" ;;
  esac
}

run_probe() {
  local adapter=$1
  "$(adapter_script "$adapter")" probe
}

case "${1:-}" in
  probe)
    target=${2:-all}
    case "$target" in
      android|ios|desktop) [[ $# -eq 2 ]] || die 'probe accepts one target'; run_probe "$target" ;;
      all)
        [[ $# -le 2 ]] || die 'probe accepts android, ios, desktop, or all'
        run_probe android
        run_probe ios
        run_probe desktop
        ;;
      *) die 'probe target must be android, ios, desktop, or all' ;;
    esac
    ;;
  android|ios|desktop)
    adapter=$1; shift
    [[ $# -ge 1 ]] || die "$adapter requires an adapter command"
    "$(adapter_script "$adapter")" "$@"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
