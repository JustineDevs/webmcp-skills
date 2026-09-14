---
name: webmcp-agents
description: "Use as the entrypoint for WebMCP work: choose the right skill, detect the available browser or emulator adapter, and operate through a verified page-local tool loop."
---

# WebMCP agents

Use this skill as the universal entrypoint for WebMCP tasks. It routes the request to the smallest specialized skill while keeping one operating contract for discovery, execution, observation, verification, safety, and recovery.

## Authority and boundaries

[`index.bs`](../../../index.bs) is the normative WebMCP authority. The specialized skills are operational or design guidance around that API. This skill does not create browser, MCP, desktop, or native-device capabilities: a host adapter must expose the target page or device before an agent can act on it.

## Route the task

- [`webmcp-runtime`](../webmcp-runtime/SKILL.md) — detect and use the available page, browser, CDP, extension, or native-device adapter. The repository implementations are `scripts/webmcp-agent-browser.sh`, `scripts/webmcp-chrome-devtools.sh`, `scripts/webmcp-android.sh`, `scripts/webmcp-ios.sh`, `scripts/webmcp-desktop.sh`, and `scripts/webmcp-device.sh`.
- [`webmcp-agent-browser`](../webmcp-agent-browser/SKILL.md) — inspect, discover, execute, refresh, and verify through an agent-browser-compatible host.
- [`webmcp-core`](../webmcp-core/SKILL.md) — normative registration, discovery, execution, lifecycle, and cancellation.
- [`webmcp-tool-design`](../webmcp-tool-design/SKILL.md) — tools, schemas, state transitions, confirmation, and recovery.
- [`webmcp-declarative`](../webmcp-declarative/SKILL.md) — exploratory HTML-form tools and preview behavior.
- [`webmcp-frameworks`](../webmcp-frameworks/SKILL.md) — React, Angular, TypeScript, SSR, remount, and cancellation integration.
- [`webmcp-design-md`](../webmcp-design-md/SKILL.md) — DESIGN.md token, AST, semantic-model, and renderer workflows.
- [`webmcp-security`](../webmcp-security/SKILL.md) — origin, permissions, privacy, untrusted content, and consequential actions.
- [`webmcp-evals`](../webmcp-evals/SKILL.md) — selection, chaining, outputs, reliability, and prompt-injection evaluation.
- [`webmcp-service-workers`](../webmcp-service-workers/SKILL.md) — exploratory background routing and multi-tab architecture.
- [`webmcp-setup`](../webmcp-setup/SKILL.md) — browser flags, origin trials, support checks, and fallback behavior.
- [`webmcp-maintainer`](../webmcp-maintainer/SKILL.md) — source authority, validation, publication, and stale-content checks.

## Universal operating loop

1. State the target page, origin, session, device, and intended side effect.
2. Load [`webmcp-runtime`](../webmcp-runtime/SKILL.md) and run its capability probe before claiming that the target is accessible.
3. Observe the live page or device state. A screenshot proves visibility only; it does not prove that the agent can control the target.
4. Discover current WebMCP tools and inspect their names, descriptions, schemas, annotations, and origins.
5. Validate input, confirmation, origin scope, and preconditions before execution.
6. Execute the smallest page-owned semantic tool with cancellation when supported.
7. Re-observe after navigation, mutation, re-render, or asynchronous work. Refs, tool objects, and visible state may be stale.
8. Verify both the structured result and the settled human-visible state. If either is missing or contradictory, report the state as unverified and recover.

Prefer WebMCP over DOM, screenshot, keyboard, mouse, or native-device actuation when a matching page-owned tool exists. Use fallback actuation only when the user has put it in scope, the adapter is available, and the fallback result can be verified.

## Capability truthfulness

- A page-local WebMCP context controls web-page logic, not an Android emulator or arbitrary desktop window.
- A browser/CDP adapter can expose WebMCP and browser fallback actions only for the connected browser session.
- A native emulator requires a separate authorized adapter such as ADB or a product-specific device bridge. Do not infer native control from a browser screenshot or from a connected-looking UI label.
- For Android, use `scripts/webmcp-android.sh probe` before `screenshot`, `dump-ui`, `tap`, `swipe`, `text`, `keyevent`, `launch`, or guarded `shell` actions; the adapter verifies the serial and returns only after the ADB operation exits.
- For iOS, use `scripts/webmcp-ios.sh probe` before simctl or idb actions; lifecycle/capture use Xcode's `simctl`, while accessibility/touch/text require a live idb installation.
- For macOS, Windows, or Linux desktop control, use `scripts/webmcp-desktop.sh probe` first and keep native host permissions, window selection, screenshots, and input evidence separate from page-local WebMCP evidence.
- If discovery, execution, observation, or verification is unavailable, report the missing capability and stop at the last verified state instead of simulating success.

## Output contract

- Identify the adapter and origin/session used.
- Report discovered tools or the precise reason discovery was unavailable.
- Report the action, confirmation boundary, cancellation status, and fresh verification evidence.
- Separate `completed`, `failed`, `cancelled`, `unsupported`, and `unverified` outcomes.
