---
name: webmcp-runtime
description: "Use when a WebMCP task needs a real host adapter: capability probing, page-local execution, browser/CDP fallback, or explicit native/mobile emulator boundaries."
---

# WebMCP runtime adapters

WebMCP skills provide operating instructions; they do not automatically grant access to a browser tab, an embedded page, a desktop window, or a native device. Use this skill to identify the real adapter before attempting an action.

## Authority and boundaries

[`index.bs`](../../../index.bs) defines the page-local WebMCP API. Adapter commands and fallback policy here are operational guidance, not additional WebMCP API surface. A native emulator bridge is outside WebMCP and must be separately authorized, scoped, and verified.

## Capability matrix

| Adapter | Discovery and execution | Observation and verification | Boundary |
| --- | --- | --- | --- |
| In-page JavaScript | `document.modelContext.getTools()` and `executeTool()` | Page state, DOM, accessibility, or app-owned status | Same document or explicitly exposed secure origins |
| `agent-browser` over CDP | `eval` the page-local API; use snapshots and refs as fallback | Snapshot, text, URL, screenshot, console, and page state | Requires a connected Chrome/Chromium session |
| Chrome DevTools MCP | `list_webmcp_tools` and `execute_webmcp_tool` when the experimental WebMCP category is enabled; `evaluate_script` is a fallback | Pages, snapshots, screenshots, console, network, traces, emulation, memory, and `lighthouse_audit` | Officially supports Google Chrome and Chrome for Testing; other Chromium browsers are best-effort |
| Playwright/CDP host | Evaluate the same page-local API in the connected target | Host-provided DOM, accessibility, screenshot, and network state | Requires an attached target and correct frame/origin |
| Browser extension or embedded agent | Host-specific WebMCP discovery and execution | Host-specific page observation | Requires page access, host permissions, secure origin, and exposure policy |
| Android/iOS/native emulator | Not WebMCP; use the included ADB or simctl/idb bridge | Device screenshot, accessibility, logs, and device state from that bridge | Requires a verified device selector and explicit native-action scope |
| macOS/Windows/Linux desktop host | Not WebMCP; use the included native desktop bridge | Native screenshots, windows, keyboard, mouse, and app/URL launch where supported | Requires an interactive desktop session and OS accessibility/input permissions |

The included adapters implement these operations rather than merely describing them. `scripts/webmcp-agent-browser.sh` provides page probing, tool listing, execution with timeout/cancellation, snapshots, screenshots, console/errors, and the agent-browser command surface. `scripts/webmcp-chrome-devtools.sh` auto-resolves the official CLI through PATH or `npx`, starts a compatible Chromium executable, enables `categoryExperimentalWebmcp`, and exposes WebMCP, page snapshots, screenshots, JavaScript evaluation, console/network logs, performance tools, emulation, heap tools, extension-capable commands, and Lighthouse. `scripts/webmcp-android.sh` provides explicit Android observation and actuation through ADB: device discovery, screenshots, UI hierarchy dumps, taps, swipes, text, key events, app launches, and guarded shell commands. `scripts/webmcp-ios.sh` provides iOS Simulator lifecycle, screenshots, launches, deep links, and idb-backed accessibility/touch/text controls. `scripts/webmcp-desktop.sh` provides macOS, Windows, and Linux screenshots, windows, app/URL launch, keyboard, text, and coordinate input through native host tools. `scripts/webmcp-device.sh` dispatches all native targets through one command surface.

The adapter is ready only when the required operations are available: `discover`, `execute`, `observe`, and `verify`. A visible emulator panel or screenshot satisfies none of these by itself. Browser access must also satisfy the WebMCP `Permissions Policy` and origin rules. Native Android control is verified separately by the ADB serial and device state; it is never inferred from a browser page or WebMCP tool list.

The dependency-free [`scripts/webmcp-toolkit.sh`](../../../scripts/webmcp-toolkit.sh) closes the cross-domain validation gap: `schema` validates tool contracts, `security` scans metadata and origin/annotation risks, `eval` checks deterministic journey traces, `design` parses DESIGN.md front matter/sections/references/states, `setup` reports host prerequisites, and `doctor` runs repository validation plus all fixtures. These checks are executable evidence for the core, tool-design, security, evals, design-md, and setup skills; they do not turn proposal-only declarative or service-worker behavior into a normative API.

## Probe before acting

Run the portable probe when `agent-browser` is the host:

```sh
scripts/webmcp-agent-browser.sh probe
scripts/webmcp-agent-browser.sh list
```

The probe must report the current origin, whether `document.modelContext` exists, whether discovery and execution are callable, and the host failure if no page is connected. Treat a missing context as `unsupported`, a permission or origin failure as `blocked`, and a transport failure as `unavailable`; do not silently fall back to simulated success.

When Chrome DevTools MCP is available, enable its experimental WebMCP category and use the page ID from `list_pages`:

```text
npx -y chrome-devtools-mcp@latest --categoryExperimentalWebmcp --no-usage-statistics
list_pages
list_webmcp_tools(pageId)
execute_webmcp_tool(pageId, toolName, input)
```

The exact MCP tool names are `list_webmcp_tools` and `execute_webmcp_tool`. They are optional experimental tools, so first confirm that they are present in the live MCP tool list. If they are absent, use `evaluate_script` for the same page-local probe or switch to the `agent-browser` adapter. Do not claim that a tool category is enabled because the server started successfully.

For another host, run the equivalent JavaScript in the connected page:

```js
const context = document.modelContext;
const tools = context ? await context.getTools() : [];
({
  supported: Boolean(context),
  canDiscover: Boolean(context?.getTools),
  canExecute: Boolean(context?.executeTool),
  origin: location.origin,
  tools: tools.map(({ name, title, description, inputSchema, annotations, origin }) =>
    ({ name, title, description, inputSchema, annotations, origin }))
});
```

Never serialize or expose `RegisteredTool.window` as a capability claim. It is a live object, not portable result data.

## Discover, validate, execute, verify

1. Use the current page/session and record its origin and frame or tab.
2. Discover tools again after navigation, frame changes, `toolchange`, or any re-render that can change registration.
3. Select by semantic purpose, not by a name that merely resembles the user's wording.
4. Validate the input against the current schema. Missing or ambiguous values require user input; do not guess IDs, origins, amounts, or device targets.
5. For consequential tools, require explicit user confirmation immediately before execution. An annotation or page description is not consent.
6. Execute through the current tool object. Pass an `AbortSignal` for work that may outlive the user's patience.
7. Treat a `null` result, navigation, rejection, timeout, or disconnect as an outcome requiring fresh observation. Do not retry a mutation blindly.
8. Verify structured output, URL/frame/session, visible settled state, and any device state that the selected adapter can actually observe.

With the included `agent-browser` adapter:

```sh
# Discover the current page tools.
scripts/webmcp-agent-browser.sh list

# Read JSON input from stdin and execute one discovered tool.
printf '%s' '{"query":"milk"}' | scripts/webmcp-agent-browser.sh execute search-products

# Refresh browser-level evidence after the action.
agent-browser snapshot -i
agent-browser get url
```

The adapter uses `agent-browser eval --stdin`, so it requires a running or connected Chrome/Chromium session. Its `observe` and `devtools` commands expose the same session's snapshots, screenshots, console, errors, trace, profiler, network, and browser interaction commands. It does not attach to the Codex desktop window or a native emulator; use the explicit ADB adapter for that.

With the native Android adapter:

```sh
scripts/webmcp-android.sh probe
scripts/webmcp-android.sh screenshot /tmp/device.png
scripts/webmcp-android.sh dump-ui /tmp/device.xml
scripts/webmcp-android.sh tap 540 960
scripts/webmcp-android.sh text 'hello%sworld'
scripts/webmcp-android.sh keyevent KEYCODE_ENTER
scripts/webmcp-android.sh launch com.example.app
```

Every native action selects one explicit authorized device (or requires `WEBMCP_ANDROID_SERIAL`/`WEBMCP_IOS_UDID` when multiple devices exist), returns a structured completion only after the platform command exits successfully, and exposes raw Android shell only under `WEBMCP_ALLOW_SHELL=1`.

With the iOS and desktop adapters:

```sh
scripts/webmcp-ios.sh probe
scripts/webmcp-ios.sh boot
scripts/webmcp-ios.sh screenshot /tmp/ios.png
scripts/webmcp-ios.sh launch com.example.app

scripts/webmcp-desktop.sh probe
scripts/webmcp-desktop.sh screenshot /tmp/desktop.png
scripts/webmcp-desktop.sh open https://example.com
scripts/webmcp-device.sh probe all
```

The iOS backend uses `xcrun simctl` for simulator lifecycle and capture, and
requires Facebook `idb` for accessibility/touch/text operations. The desktop
backend controls the actual host desktop only when its native tool and
accessibility/session permissions are live.

With Chrome DevTools MCP, use the full DevTools surface around the WebMCP call:

- `list_pages`, `new_page`, `select_page`, and `wait_for` establish the target and settled state.
- `take_snapshot`, `take_screenshot`, and `evaluate_script` observe the UI and page-local state.
- `list_console_messages`, `get_console_message`, `list_network_requests`, and `get_network_request` diagnose tool failures.
- `performance_start_trace`, `performance_stop_trace`, and `performance_analyze_insight` inspect interaction cost and responsiveness.
- `lighthouse_audit` verifies performance, accessibility, best practices, and SEO after the journey. Lighthouse is an audit/verifier, not a WebMCP execution transport.
- `emulate` and `resize_page` validate responsive and device-specific behavior without changing the WebMCP origin contract.
- Heap snapshots and extension tools are opt-in diagnostics and require the corresponding server categories and explicit scope.

For shell-driven Chrome DevTools MCP use [`scripts/webmcp-chrome-devtools.sh`](../../../scripts/webmcp-chrome-devtools.sh). It provides bounded WebMCP listing/execution and Lighthouse entry points while leaving the full DevTools CLI available through its `run` command.

For a standalone Lighthouse run, keep the report as an explicit artifact and do not treat a passing audit as proof that a WebMCP tool executed:

```sh
lighthouse https://example.com --output=json --output-path=./lighthouse-report.json --quiet
```

The Lighthouse CLI has its own browser/version requirements. Record them with the WebMCP browser and host versions.

## Fallback and recovery

- If WebMCP is unsupported but browser observation is available, use semantic locators or fresh accessibility refs only when browser actuation is in scope; preserve confirmation and verify the visible result.
- If a browser exposes WebMCP but the selected DevTools MCP category is missing, keep using the page's feature detection and `evaluate_script`; category availability is a host configuration issue, not proof that the browser lacks WebMCP.
- Run Lighthouse or DevTools traces after a journey when performance, accessibility, or rendering quality is part of the acceptance criteria. Keep those results separate from tool-execution success.
- If a browser adapter is unavailable, do not claim page access. Report the exact missing transport, such as no CDP target or no host permission.
- If only an emulator screenshot is available, report `observe-only`; do not claim that taps, text input, or app launches succeeded.
- If native control is required, switch explicitly to the authorized native bridge and verify the device serial/model before acting. Do not mix page-origin trust with device-shell trust.

## Output checklist

- [ ] Adapter, origin, session, frame, and device selector are identified.
- [ ] `discover`, `execute`, `observe`, and `verify` capabilities were probed.
- [ ] Current tool metadata and schema were used.
- [ ] Confirmation and cancellation boundaries were enforced.
- [ ] Fresh page or device evidence supports the final outcome.
- [ ] Browser-specific support, flag/origin-trial state, and DevTools category availability are recorded.
- [ ] Lighthouse/trace results are reported separately from WebMCP execution results.
- [ ] Unsupported, blocked, unavailable, failed, cancelled, and unverified states are distinguished.
