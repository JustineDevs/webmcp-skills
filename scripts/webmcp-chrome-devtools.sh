#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-chrome-devtools.sh start
  scripts/webmcp-chrome-devtools.sh pages
  scripts/webmcp-chrome-devtools.sh list <page-id>
  printf '%s' '<json>' | scripts/webmcp-chrome-devtools.sh execute <page-id> <tool-name>
  scripts/webmcp-chrome-devtools.sh audit <page-id> [navigation|snapshot] [desktop|mobile]
  scripts/webmcp-chrome-devtools.sh observe <page-id> [screenshot-path]
  scripts/webmcp-chrome-devtools.sh run <chrome-devtools-command> [args...]

The CLI is resolved in this order: WEBMCP_CHROME_DEVTOOLS_BIN, PATH, then
`npx --yes --package chrome-devtools-mcp@latest chrome-devtools`.
WEBMCP_CHROME_EXECUTABLE can select Chrome/Chromium/Brave explicitly.
EOF
}

die() {
  printf 'webmcp-chrome-devtools: %s\n' "$1" >&2
  exit 2
}

find_browser() {
  if [[ -n "${WEBMCP_CHROME_EXECUTABLE:-}" ]]; then
    [[ -x "$WEBMCP_CHROME_EXECUTABLE" ]] || die "WEBMCP_CHROME_EXECUTABLE is not executable: $WEBMCP_CHROME_EXECUTABLE"
    printf '%s\n' "$WEBMCP_CHROME_EXECUTABLE"
    return
  fi
  local name path
  for name in google-chrome google-chrome-stable chromium chromium-browser brave brave-browser microsoft-edge microsoft-edge-stable msedge vivaldi opera; do
    path=$(command -v "$name" 2>/dev/null || true)
    if [[ -n "$path" && -x "$path" ]]; then
      printf '%s\n' "$path"
      return
    fi
  done
  path=$(find "$HOME/.cache/ms-playwright" /snap /opt -maxdepth 8 -type f \( -name chrome -o -name chromium -o -name brave \) -perm -111 -print -quit 2>/dev/null || true)
  [[ -n "$path" ]] && printf '%s\n' "$path" && return
  die 'no Chrome/Chromium executable found; set WEBMCP_CHROME_EXECUTABLE'
}

run_cli() {
  local bin=${WEBMCP_CHROME_DEVTOOLS_BIN:-}
  if [[ -n "$bin" ]]; then
    "$bin" "$@"
  elif command -v chrome-devtools >/dev/null 2>&1; then
    chrome-devtools "$@"
  else
    npx --yes --package=chrome-devtools-mcp@latest chrome-devtools "$@"
  fi
}

status() {
  run_cli status 2>/dev/null || true
}

ensure_started() {
  local daemon_status
  daemon_status=$(status)
  if printf '%s' "$daemon_status" | rg -q 'daemon is running' && \
    printf '%s' "$daemon_status" | rg -q 'category-experimental-webmcp'; then
    return
  fi
  if printf '%s' "$daemon_status" | rg -q 'daemon is running'; then
    run_cli stop >/dev/null 2>&1 || true
  fi
  local executable
  executable=$(find_browser)
  run_cli start \
    --headless "${WEBMCP_CHROME_HEADLESS:-true}" \
    --executablePath "$executable" \
    --categoryExperimentalWebmcp true \
    --no-usage-statistics \
    --no-performance-crux \
    --pageIdRouting true >/dev/null
}

json_cli() {
  run_cli "$@" --output-format=json
}

read_input() {
  local input=${WEBMCP_INPUT_JSON:-}
  if [[ -z "$input" && ! -t 0 ]]; then input=$(cat); fi
  [[ -n "$input" ]] || input='{}'
  node -e 'const value=JSON.parse(process.argv[1]); if (typeof value !== "object" || value === null || Array.isArray(value)) process.exit(2)' "$input" >/dev/null 2>&1 || die 'stdin is not a JSON object'
  printf '%s' "$input"
}

case "${1:-}" in
  start)
    [[ $# -eq 1 ]] || die 'start takes no arguments'
    ensure_started
    printf '{"adapter":"chrome-devtools","status":"ready","categoryExperimentalWebmcp":true}\n'
    ;;
  pages)
    [[ $# -eq 1 ]] || die 'pages takes no arguments'
    ensure_started
    json_cli list_pages
    ;;
  list)
    [[ $# -eq 2 ]] || die 'list requires a page id'
    ensure_started
    json_cli list_webmcp_tools "$2"
    ;;
  execute)
    [[ $# -eq 3 ]] || die 'execute requires a page id and tool name'
    ensure_started
    input=$(read_input)
    json_cli execute_webmcp_tool "$2" "$3" --input "$input"
    ;;
  audit)
    [[ $# -ge 2 && $# -le 4 ]] || die 'audit requires a page id and optional mode/device'
    mode=${3:-navigation}
    device=${4:-desktop}
    case "$mode" in navigation|snapshot) ;; *) die 'audit mode must be navigation or snapshot' ;; esac
    case "$device" in desktop|mobile) ;; *) die 'audit device must be desktop or mobile' ;; esac
    ensure_started
    json_cli lighthouse_audit "$2" --mode "$mode" --device "$device"
    ;;
  observe)
    [[ $# -ge 2 && $# -le 3 ]] || die 'observe requires a page id and optional screenshot path'
    ensure_started
    json_cli take_snapshot "$2"
    json_cli list_console_messages "$2"
    json_cli list_network_requests "$2"
    if [[ -n "${3:-}" ]]; then json_cli take_screenshot "$2" --filePath "$3"; fi
    ;;
  run)
    [[ $# -ge 2 ]] || die 'run requires a chrome-devtools command'
    ensure_started
    shift
    json_cli "$@"
    ;;
  stop)
    [[ $# -eq 1 ]] || die 'stop takes no arguments'
    run_cli stop >/dev/null 2>&1 || true
    printf '{"adapter":"chrome-devtools","status":"stopped"}\n'
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
