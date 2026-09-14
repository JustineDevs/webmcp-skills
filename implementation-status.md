# Implementation Status

This document shows the implementation status of WebMCP across different browsers.

## Runtime support contract

Browser support and host-tool support are separate dimensions. A browser is WebMCP-capable only when the live target passes feature detection for `document.modelContext`, `getTools`, and `executeTool`, then satisfies its secure-context, origin-isolation, `tools` Permissions Policy, and browser-specific trial or flag requirements. Chrome DevTools MCP is a Chrome-focused host adapter; its availability must not be used as a claim that another browser supports WebMCP.

For every browser listed below, test the page-local API first. If it is unavailable, retain ordinary UI and browser automation fallback. Record the browser/version, host adapter, origin-trial or flag state, DevTools categories, and date of the test.

## Executable host adapters

This repository now includes working host adapters, independent of whether the
target browser has WebMCP enabled:

- `scripts/webmcp-agent-browser.sh` probes and executes the page-local API and
  exposes snapshots, screenshots, console, errors, traces, and browser actions
  through an existing `agent-browser` session.
- `scripts/webmcp-chrome-devtools.sh` starts the Chrome DevTools MCP CLI through
  PATH or `npx`, selects an installed Chromium-family executable, enables the
  experimental WebMCP category, and exposes the full CLI including Lighthouse,
  performance, network, emulation, screenshots, and page evaluation.
- `scripts/webmcp-android.sh` controls a separately selected Android emulator or
  device through ADB, including screenshots, UI dumps, taps, swipes, text, key
  events, and launches. This is native control, not WebMCP.
- `scripts/webmcp-ios.sh` controls iOS Simulators through `xcrun simctl` for
  lifecycle, screenshots, app launches, and deep links; Facebook `idb` adds
  accessibility trees and touch/text input.
- `scripts/webmcp-desktop.sh` controls macOS, Windows, and Linux desktop hosts
  through their native screenshot, window, keyboard, mouse, and app-launch
  tools when the host session grants the required permissions.
- `scripts/webmcp-device.sh` provides one dispatcher for Android, iOS, and
  desktop probes/actions.
- `scripts/webmcp-toolkit.sh` provides dependency-free schema, security, eval,
  DESIGN.md, host setup, and repository doctor checks for the surrounding skill
  domains.

Run `scripts/test-adapters.sh` or `make test-adapters` to verify the browser
fixture and probe the currently connected native target. A successful host
adapter does not override a page that fails `document.modelContext` feature
detection.

<a href="#brave"><img width=64 src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/brave/brave_128x128.png" alt="Brave logo"></a> <a href="#chatgpt-desktop"><picture><source media="(prefers-color-scheme: dark)" srcset="assets/openai-white.svg"><source media="(prefers-color-scheme: light)" srcset="assets/openai.svg"><img width=64 src="assets/openai.svg" alt="OpenAI logo"></picture></a> <a href="#chrome"><img width=64 src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/chrome/chrome_128x128.png" alt="Chrome logo"></a> <a href="#edge"><img width=64 src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/edge/edge_128x128.png" alt="Edge logo"></a> <a href="#firefox"><img width=64 src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/firefox/firefox_128x128.png" alt="Firefox logo"></a> <a href="#safari"><img width=64 src="https://raw.githubusercontent.com/alrra/browser-logos/master/src/safari/safari_128x128.png" alt="Safari logo"></a>

# Brave

Experimental support is added to [Leo AI chat](https://brave.com/leo/).

* [Issue 55232](https://github.com/brave/brave-browser/issues/55232)

# ChatGPT Desktop

WebMCP is supported in [ChatGPT Desktop](https://chatgpt.com/download/).

# Chrome

An [Origin Trial](https://developer.chrome.com/blog/ai-webmcp-origin-trial) is live in Chrome 149.

* [Early preview program](https://developer.chrome.com/docs/ai/join-epp)
* [Intent to Experiment](https://groups.google.com/a/chromium.org/g/blink-dev/c/gmYffo5WOE8/m/OJxuQRP3AAAJ)
* [Chrome Status entry](https://chromestatus.com/feature/5117755740913664)

# Edge

An [Origin Trial](https://developer.microsoft.com/en-us/microsoft-edge/origin-trials/trials/0b76fe60-b266-458e-a285-04e375c0c31a) is live in Edge 150.

Refer to Chrome implementation status for platform support.

# Firefox

* [Mozilla standards-positions](https://github.com/mozilla/standards-positions/issues/1412)
* [Bugzilla entry](https://bugzilla.mozilla.org/show_bug.cgi?id=2018306)

# Safari

* [WebKit standards-positions](https://github.com/WebKit/standards-positions/issues/670)
