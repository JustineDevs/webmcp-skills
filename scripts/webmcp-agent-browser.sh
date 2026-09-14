#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/webmcp-agent-browser.sh probe
  scripts/webmcp-agent-browser.sh list
  printf '%s' '<json>' | scripts/webmcp-agent-browser.sh execute <tool-name>
  scripts/webmcp-agent-browser.sh observe [screenshot-path]
  scripts/webmcp-agent-browser.sh devtools <agent-browser-command> [args...]

Environment:
  WEBMCP_ABORT_AFTER_MS  Abort an execution after this many milliseconds.
  AGENT_BROWSER_SESSION  Select the isolated agent-browser session.
EOF
}

die() {
  printf 'webmcp-agent-browser: %s\n' "$1" >&2
  exit 2
}

command -v agent-browser >/dev/null 2>&1 || die 'agent-browser is not installed or not on PATH'

run_eval() {
  agent-browser --json eval --stdin
}

run_browser_json() {
  agent-browser --json "$@"
}

encode_base64() {
  printf '%s' "$1" | base64 | tr -d '\n'
}

probe() {
  run_eval <<'EOF'
(async () => {
  const context = document.modelContext;
  const canDiscover = Boolean(context && typeof context.getTools === "function");
  const canExecute = Boolean(context && typeof context.executeTool === "function");
  const permissions = document.permissionsPolicy?.allows?.("tools");
  let toolCount = null;
  let error = null;
  if (canDiscover) {
    try {
      toolCount = (await context.getTools()).length;
    } catch (cause) {
      error = { name: cause?.name || "Error", message: String(cause?.message || cause) };
    }
  }
  return {
    adapter: "agent-browser",
    origin: location.origin,
    webmcp: canDiscover && canExecute ? "supported" : "unsupported",
    canDiscover,
    canExecute,
    permissionsPolicy: permissions === undefined ? "unknown" : permissions ? "allowed" : "blocked",
    toolCount,
    error
  };
})()
EOF
}

list_tools() {
  run_eval <<'EOF'
(async () => {
  const context = document.modelContext;
  if (!context || typeof context.getTools !== "function") {
    return { status: "unsupported", reason: "document.modelContext.getTools is unavailable", origin: location.origin };
  }
  try {
    const tools = await context.getTools();
    return {
      status: "ready",
      origin: location.origin,
      tools: tools.map(({ name, title, description, inputSchema, annotations, origin }) =>
        ({ name, title, description, inputSchema, annotations, origin }))
    };
  } catch (cause) {
    return { status: "blocked", origin: location.origin, error: { name: cause?.name || "Error", message: String(cause?.message || cause) } };
  }
})()
EOF
}

observe() {
  local screenshot_path=${1:-}
  run_browser_json get url
  run_browser_json get title
  run_browser_json snapshot -c
  run_browser_json console
  run_browser_json errors
  if [[ -n "$screenshot_path" ]]; then
    run_browser_json screenshot "$screenshot_path"
  fi
}

devtools() {
  [[ $# -ge 1 ]] || die 'devtools requires an agent-browser command'
  run_browser_json "$@"
}

execute_tool() {
  [[ $# -eq 1 ]] || die 'execute requires exactly one tool name'
  local tool_name=$1
  local input_json=${WEBMCP_INPUT_JSON:-}
  if [[ -z "$input_json" && ! -t 0 ]]; then
    input_json=$(cat)
  fi
  [[ -n "$input_json" ]] || input_json='{}'
  node -e 'JSON.parse(process.argv[1])' "$input_json" >/dev/null 2>&1 || die 'stdin is not valid JSON'

  local tool_b64 input_b64 abort_after_ms
  tool_b64=$(encode_base64 "$tool_name")
  input_b64=$(encode_base64 "$input_json")
  abort_after_ms=${WEBMCP_ABORT_AFTER_MS:-0}
  [[ "$abort_after_ms" =~ ^[0-9]+$ ]] || die 'WEBMCP_ABORT_AFTER_MS must be a non-negative integer'

  run_eval <<EOF
(async () => {
  const decode = (value) => new TextDecoder().decode(Uint8Array.from(atob(value), character => character.charCodeAt(0)));
  const wantedName = decode("$tool_b64");
  const input = JSON.parse(decode("$input_b64"));
  const context = document.modelContext;
  if (!context || typeof context.getTools !== "function" || typeof context.executeTool !== "function") {
    return { status: "unsupported", reason: "WebMCP discovery or execution is unavailable", origin: location.origin };
  }
  const tools = await context.getTools();
  const tool = tools.find(candidate => candidate.name === wantedName);
  if (!tool) {
    return { status: "tool_not_found", name: wantedName, available: tools.map(candidate => candidate.name), origin: location.origin };
  }
  const controller = new AbortController();
  const abortAfterMs = Number("$abort_after_ms");
  const timer = abortAfterMs > 0 ? setTimeout(() => controller.abort("adapter timeout"), abortAfterMs) : null;
  try {
    const result = await context.executeTool(tool, input, { signal: controller.signal });
    return { status: result === null ? "navigation_or_null" : "completed", name: wantedName, result, origin: location.origin };
  } catch (cause) {
    return {
      status: controller.signal.aborted ? "cancelled" : "failed",
      name: wantedName,
      error: { name: cause?.name || "Error", message: String(cause?.message || cause) },
      origin: location.origin
    };
  } finally {
    if (timer !== null) clearTimeout(timer);
  }
})()
EOF
}

command=${1:-}
case "$command" in
  probe)
    [[ $# -eq 1 ]] || die 'probe takes no arguments'
    probe
    ;;
  list)
    [[ $# -eq 1 ]] || die 'list takes no arguments'
    list_tools
    ;;
  observe)
    [[ $# -le 2 ]] || die 'observe accepts an optional screenshot path'
    observe "${2:-}"
    ;;
  devtools)
    shift
    devtools "$@"
    ;;
  execute)
    shift
    execute_tool "$@"
    ;;
  -h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
