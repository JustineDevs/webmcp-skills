---
name: webmcp-setup
description: "Use when enabling WebMCP locally, preparing Chrome origin-trial experiments, checking browser support, or documenting WebMCP development setup."
---

# WebMCP setup and support

Prepare a reproducible browser environment for WebMCP experimentation without presenting preview APIs as stable production guarantees. Configure a real observation/execution host and verify the browser feature separately from the host tooling.

## Authority and boundaries

WebMCP is a proposed standard under active discussion. Follow the official Chrome documentation and origin-trial terms for the current browser version. This skill documents setup; it does not install Chrome, enroll users, or claim universal support.

## Core workflow

1. Install the skill collection with `npx skills add JustineDevs/webmcp-skills`; for unattended installation across all agents detected by the current CLI, use `--all`; for one agent, use `--agent <id>`. Use `npx skills update` to refresh installed copies. Check the current CLI contract with `npx skills --help` because supported agents and options can change.
2. Record the target Chrome version, operating system, origin, and feature status.
3. For local development, enable `chrome://flags/#enable-webmcp-testing` and relaunch Chrome.
4. For an origin-trial experiment, follow Chrome's current Origin Trial enrollment and token rules.
5. Choose and verify one host adapter: in-page JavaScript, `agent-browser` over CDP, Playwright/CDP, or Chrome DevTools MCP.
6. For Chrome DevTools MCP, enable the experimental WebMCP category when the server supports it:

   ```text
   npx -y chrome-devtools-mcp@latest --categoryExperimentalWebmcp --no-usage-statistics
   ```

   Confirm that `list_webmcp_tools` and `execute_webmcp_tool` are present. If they are not present, use `evaluate_script` or the `agent-browser` adapter; do not infer category support from server startup.

7. Verify tool registration, discovery, schema parsing, execution, cancellation, and visible state in a real browser. Use DevTools snapshots, screenshots, console/network inspection, traces, and Lighthouse when they are part of the acceptance criteria.
8. Record browser name/version, secure-context and origin-isolation state, `tools` Permissions Policy, origin-trial/flag state, host adapter, enabled DevTools categories, unsupported browsers, fallback UI behavior, and the date/version tested.

## Distribution surfaces

`npx skills add` installs the repository's loose Agent Skills for the detected agent by default. Use `--agent <id>` for one agent or the current CLI's `--all` shorthand for every supported agent. The root `skills/` path is the portable discovery alias for the canonical `.codex/skills/` collection; `.agents/skills/` remains a project-discovery alias. Vendor-specific installation directories are created by the CLI, not maintained in this repository. A Codex plugin is a separate distribution wrapper: it requires `.codex-plugin/plugin.json`, a manifest skill path, and a marketplace entry before `codex plugin marketplace add` and `codex plugin add` can be used. Do not present an unpublished wrapper as available.

## Progressive enhancement

The site must remain usable without WebMCP. Keep ordinary forms, keyboard access, visible controls, and server-side validation intact. WebMCP should improve agent interaction, not become the only path to a user action. The skills.sh registry is a distribution index; it does not grant runtime access to a browser, emulator, or desktop.

## Cross-browser support contract

Do not make Chromium or Chrome DevTools MCP a proxy for WebMCP support. On every target browser, feature-detect `document.modelContext`, `getTools`, and `executeTool`; then verify secure context, origin isolation, permissions policy, and any browser-specific trial or flag. The current implementation status distinguishes Chrome/Edge preview support, Brave/ChatGPT Desktop product experiments, and Firefox/Safari standards work. Unsupported browsers must retain the normal UI and a documented fallback path.

## Output checklist

- [ ] Browser version and feature enablement are recorded.
- [ ] Origin-trial or local-flag assumptions are explicit.
- [ ] Non-WebMCP fallback remains functional.
- [ ] API and user-journey smoke tests pass in the target browser.
- [ ] The selected browser feature-detects WebMCP independently of the selected DevTools or automation host.
- [ ] DevTools, Lighthouse, or agent-browser verification is recorded separately from WebMCP execution.
- [ ] Support limitations and test date are documented.

## Local readiness and doctor checks

Use the repository toolkit to inspect the host and run the deterministic fixture suite:

```sh
./scripts/webmcp-toolkit.sh setup
./scripts/webmcp-toolkit.sh doctor
```

The report distinguishes available host binaries from unavailable platform backends and never presents an absent iOS, desktop, or Android tool as simulated support.
