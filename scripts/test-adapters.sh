#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

fail() { printf 'test-adapters: %s\n' "$1" >&2; exit 1; }
assert_json() {
  local expression=$1 payload=$2
  node -e "const value=JSON.parse(process.argv[1]); if (!(${expression})) process.exit(2)" "$payload" || fail "JSON assertion failed: $expression"
}

bash -n scripts/webmcp-agent-browser.sh scripts/webmcp-chrome-devtools.sh scripts/webmcp-android.sh scripts/webmcp-ios.sh scripts/webmcp-desktop.sh scripts/webmcp-device.sh scripts/webmcp-toolkit.sh
node --check scripts/webmcp-toolkit.mjs
scripts/webmcp-agent-browser.sh --help >/dev/null
scripts/webmcp-chrome-devtools.sh --help >/dev/null
scripts/webmcp-android.sh --help >/dev/null
scripts/webmcp-ios.sh --help >/dev/null
scripts/webmcp-desktop.sh --help >/dev/null
scripts/webmcp-device.sh --help >/dev/null

native_probe=$(scripts/webmcp-device.sh probe all)
printf '%s\n' "$native_probe" | node -e '
  let input="";
  process.stdin.on("data", chunk => input += chunk);
  process.stdin.on("end", () => {
    const rows = input.trim().split(/\n+/).map(JSON.parse);
    if (rows.length !== 3 || rows.some(row => !["ready", "unavailable", "unsupported", "blocked"].includes(row.status))) process.exit(2);
  });
'

session="webmcp-adapter-test-$$"
fixture_url="file://$repo_dir/tests/fixtures/webmcp-fixture.html"
cleanup() {
  AGENT_BROWSER_SESSION="$session" agent-browser close --all >/dev/null 2>&1 || true
  scripts/webmcp-chrome-devtools.sh stop >/dev/null 2>&1 || true
}
trap cleanup EXIT

AGENT_BROWSER_SESSION="$session" agent-browser --init-script "$repo_dir/tests/fixtures/webmcp-fixture.js" --json open "$fixture_url" >/dev/null
probe=$(AGENT_BROWSER_SESSION="$session" scripts/webmcp-agent-browser.sh probe)
assert_json 'value.data.result.webmcp === "supported" && value.data.result.canDiscover && value.data.result.canExecute && value.data.result.toolCount === 1' "$probe"
list=$(AGENT_BROWSER_SESSION="$session" scripts/webmcp-agent-browser.sh list)
assert_json 'value.data.result.status === "ready" && value.data.result.tools[0].name === "echo"' "$list"
result=$(printf '%s' '{"message":"adapter smoke"}' | AGENT_BROWSER_SESSION="$session" scripts/webmcp-agent-browser.sh execute echo)
assert_json 'value.data.result.status === "completed" && JSON.parse(value.data.result.result).verified === true' "$result"

if command -v adb >/dev/null 2>&1 || [[ -x "${ANDROID_HOME:-}/platform-tools/adb" || -x "${ANDROID_SDK_ROOT:-}/platform-tools/adb" || -x "$HOME/Android/Sdk/platform-tools/adb" ]]; then
  android=$(scripts/webmcp-android.sh probe)
  assert_json 'value.adapter === "adb" && ["ready","unavailable","blocked"].includes(value.status)' "$android"
fi

printf 'test-adapters: browser WebMCP discovery/execution passed; Android, iOS, desktop, and universal native probes passed\n'
