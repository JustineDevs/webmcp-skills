# webmcp-agents

Curated agent skills for building, exposing, operating, securing, evaluating, and maintaining WebMCP tools in the browser.

[![skills.sh](https://skills.sh/b/JustineDevs/webmcp-skills)](https://skills.sh/JustineDevs/webmcp-skills)

WebMCP is a proposed web standard for structured tools that help AI agents interact with web applications. This project organizes implementation guidance around the page, its live application state, and the user's visible UI↔UX journey. It also ships executable adapters for browser WebMCP, Chrome DevTools/Lighthouse, Android, iOS, and desktop hosts. The adapters use real host sessions and return explicit machine-readable outcomes when a prerequisite is unavailable.

## Install

The canonical install is:

```sh
npx skills add JustineDevs/webmcp-skills
```

For an unattended global install to the detected agent, use `npx skills add JustineDevs/webmcp-skills --all`. For a project-local installation, omit `-g`; for one agent, use `--agent <id>`. To update installed copies later, use `npx skills update` (or `npx skills update <skill>`). The repository URL remains `JustineDevs/webmcp-skills` until the GitHub repository is renamed.

The root `skills/` alias is the portable discovery surface. `.agents/skills/` and `.codex/skills/` are repository-local compatibility aliases, not copies, so one `SKILL.md` remains the source of truth.

### Agent targets

The Skills CLI writes each skill into the selected agent's native project or global directory. Use `--all` for every supported agent detected by the current CLI, or inspect the live agent list with `npx skills --help` and pass one or more IDs to `--agent`. The portable contract is the `SKILL.md` format and the repository's root `skills/` discovery path, not a vendor-specific prompt or duplicate skill tree. Use `--copy` when a vendor or filesystem does not support symlinks.

### Codex plugin and marketplace

Codex plugins are a separate package format from loose Agent Skills. A published plugin must contain `.codex-plugin/plugin.json`, expose its skills through the manifest, and be listed in a Codex `marketplace.json`. When this repository is packaged as a Codex plugin, install it with:

```text
codex plugin marketplace add JustineDevs/webmcp-skills
codex plugin add webmcp-agents@webmcp-agents
```

The repository currently ships the skills collection and `npx skills` path; it does not claim a published Codex plugin manifest until that package wrapper exists. Do not use the plugin commands against this repository before that marketplace entry is published.

### Verify installation

```sh
npx skills list --json
npx skills add . --list
npx skills update --help
```

Use `npx skills list --json` for the installed-agent inventory and `npx skills add . --list` to verify that all repository skills are discoverable. Start a fresh agent session after installation so it reloads the skill directories. See the [skills.sh CLI reference](https://www.skills.sh/docs/cli) for current options.

## Start here

1. Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for repository boundaries and data flow.
2. Load [`webmcp-agents`](.codex/skills/webmcp-agents/SKILL.md) as the universal entrypoint, then use the [skill catalog](.codex/skills/catalog.md) to load the smallest specialist.
3. Load [`webmcp-runtime`](.codex/skills/webmcp-runtime/SKILL.md) and probe the actual host before claiming page or emulator access.
4. Treat [`index.bs`](index.bs) as the sole normative WebMCP source.
5. Run `SKILL_VALIDATOR_PYTHON=/usr/bin/python3 bash scripts/validate-skills.sh` before publishing skill changes.

### Run the adapters

```sh
# Browser WebMCP through an agent-browser session.
AGENT_BROWSER_SESSION=app agent-browser open https://example.com
AGENT_BROWSER_SESSION=app scripts/webmcp-agent-browser.sh probe
AGENT_BROWSER_SESSION=app scripts/webmcp-agent-browser.sh list

# Chrome DevTools MCP auto-starts with an installed Chromium executable and
# enables its WebMCP category. It falls back to npx when the CLI is not global.
scripts/webmcp-chrome-devtools.sh start
scripts/webmcp-chrome-devtools.sh pages
scripts/webmcp-chrome-devtools.sh audit 1 snapshot mobile

# Native Android emulator/device control is separate from page WebMCP.
scripts/webmcp-android.sh probe
scripts/webmcp-android.sh screenshot /tmp/android.png
scripts/webmcp-android.sh dump-ui /tmp/android.xml
scripts/webmcp-android.sh tap 540 960

# iOS Simulator lifecycle/capture; install idb for UI input.
scripts/webmcp-ios.sh probe
scripts/webmcp-ios.sh screenshot /tmp/ios.png

# macOS, Windows, or Linux desktop host.
scripts/webmcp-desktop.sh probe
scripts/webmcp-desktop.sh screenshot /tmp/desktop.png

# Probe every native backend through one command.
scripts/webmcp-device.sh probe all

# Run deterministic domain checks and host readiness diagnostics.
scripts/webmcp-toolkit.sh schema tests/fixtures/tools.json
scripts/webmcp-toolkit.sh security tests/fixtures/tools.json
scripts/webmcp-toolkit.sh eval tests/fixtures/evals.json
scripts/webmcp-toolkit.sh design tests/fixtures/DESIGN.md
scripts/webmcp-toolkit.sh doctor
```

Run `scripts/test-adapters.sh` for a deterministic browser fixture test and live Android/iOS/desktop capability probes. Set `WEBMCP_ANDROID_SERIAL` or `WEBMCP_IOS_UDID` when more than one device is connected; set `WEBMCP_CHROME_EXECUTABLE` to choose a specific Chrome/Chromium/Brave binary.

For the original WebMCP motivation, API explainer, use cases, and open questions, read [`docs/webmcp-explainer.md`](docs/webmcp-explainer.md).

## What the skills cover

| Skill | Use it for |
| --- | --- |
| [`webmcp-agents`](.codex/skills/webmcp-agents/SKILL.md) | Universal routing, capability truthfulness, and the inspect → act → verify contract |
| [`webmcp-agent-browser`](.codex/skills/webmcp-agent-browser/SKILL.md) | WebMCP-first browser interaction with inspect, execute, refresh, and verify |
| [`webmcp-core`](.codex/skills/webmcp-core/SKILL.md) | Normative API, registration, discovery, execution, lifecycle, and cancellation |
| [`webmcp-runtime`](.codex/skills/webmcp-runtime/SKILL.md) | Host capability probing, page execution adapters, browser fallback, and native/mobile boundaries |
| [`webmcp-declarative`](.codex/skills/webmcp-declarative/SKILL.md) | Declarative form proposal and version-gated behavior |
| [`webmcp-design-md`](.codex/skills/webmcp-design-md/SKILL.md) | DESIGN.md analysis through Lexer → Parser/AST → semantic model → Renderer |
| [`webmcp-evals`](.codex/skills/webmcp-evals/SKILL.md) | Tool selection, arguments, journeys, safety, recovery, and output evaluation |
| [`webmcp-frameworks`](.codex/skills/webmcp-frameworks/SKILL.md) | React, Angular, TypeScript, lifecycle, SSR, remount, and cancellation integration |
| [`webmcp-maintainer`](.codex/skills/webmcp-maintainer/SKILL.md) | Bikeshed, validation, catalog ownership, CI, and contribution hygiene |
| [`webmcp-security`](.codex/skills/webmcp-security/SKILL.md) | Origin, permissions, untrusted content, confirmation, and agent defense-in-depth |
| [`webmcp-service-workers`](.codex/skills/webmcp-service-workers/SKILL.md) | Exploratory background, routing, tab, and session design |
| [`webmcp-setup`](.codex/skills/webmcp-setup/SKILL.md) | Chrome testing, origin trials, support checks, and progressive enhancement |
| [`webmcp-tool-design`](.codex/skills/webmcp-tool-design/SKILL.md) | User goals, schemas, state transitions, UI↔UX, and recovery contracts |

## How WebMCP works here

The skills follow WebMCP's page-local model:

```text
user intent
  → browser agent discovers page tools with document.modelContext.getTools()
  → agent selects a matching tool and validates its input schema
  → browser mediates document.modelContext.executeTool(tool, input, options)
  → page executes existing client-side logic with the live session and state
  → page updates the visible UI and returns the API-defined result
  → agent verifies the result against settled page state
```

The agent-browser behavior is an operational loop around the WebMCP boundary:

```text
open → inspect/read/snapshot → choose semantic tool → execute → fresh observation → verify
```

DOM snapshots, refs, screenshots, keyboard, and mouse actions remain observation or recovery primitives. When a suitable WebMCP tool exists, the agent uses that page-owned capability instead of simulating clicks. If no tool can complete the goal, fallback browser actuation is explicit, origin-scoped, confirmed where necessary, and verified afterward.

The host boundary is explicit:

```text
visible surface
  → capability probe
  → page-local WebMCP context, if reachable
  → browser/CDP fallback, if authorized
  → native-device bridge only when separately exposed and verified
```

The included `scripts/webmcp-agent-browser.sh` adapter probes, lists, executes, observes, and captures diagnostics against the current `agent-browser` page session. `scripts/webmcp-chrome-devtools.sh` auto-starts the official Chrome DevTools MCP CLI with WebMCP enabled and exposes page snapshots, screenshots, console/network logs, traces, emulation, and Lighthouse audits. `scripts/webmcp-android.sh`, `scripts/webmcp-ios.sh`, and `scripts/webmcp-desktop.sh` provide explicit native Android, iOS Simulator, and macOS/Windows/Linux desktop control; `scripts/webmcp-device.sh` unifies their probes and dispatch. Native control never gets conflated with page-local WebMCP.

For Chrome-based workflows, the runtime skill also maps the complete DevTools surface: WebMCP listing/execution, page targeting, snapshots, screenshots, script evaluation, console and network inspection, performance traces, emulation, memory diagnostics, extension tooling, and Lighthouse audits. Those are optional host capabilities; they do not expand the WebMCP standard or imply support in another browser.

## UI↔UX contract

A WebMCP tool is complete only when the agent path and human path remain connected:

```text
intent → affordance → precondition → action → progress → settled UI state → result → recovery
```

Tool descriptions, titles, labels, accessible names, schemas, visible status, focus behavior, keyboard access, loading states, errors, confirmation, cancellation, and human takeover must describe one coherent journey. A successful result does not override a pending, inaccessible, stale, or failed UI.

## DESIGN.md capability

The [`webmcp-design-md`](.codex/skills/webmcp-design-md/SKILL.md) skill applies the external alpha DESIGN.md format to WebMCP authoring. It keeps exact tokens in YAML front matter and rationale in Markdown, then processes the document as:

```text
source text or live page
  → Lexer / tokenizer
  → Parser / abstract syntax tree (AST)
  → semantic resolution of tokens, components, and states
  → Renderer / generator for DESIGN.md or an export
```

This is a skill-level authoring pattern, not a new WebMCP API. The page may expose narrow tools for analysis, parsing, validation, comparison, rendering, or preview using the standard WebMCP registration and execution model. Generated changes remain reviewable and must not be silently persisted.

## Source authority and status

- [`index.bs`](index.bs) is the normative WebMCP specification source.
- [`docs/webmcp-explainer.md`](docs/webmcp-explainer.md) is the developer-facing WebMCP explainer.
- [`declarative-api-explainer.md`](declarative-api-explainer.md) and [`docs/service-workers.md`](docs/service-workers.md) are exploratory proposal documents and preserve unresolved `TBD` behavior.
- [`implementation-status.md`](implementation-status.md) records browser and product status; support can change independently of the draft.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) describes repository ownership, pipelines, and boundaries.

WebMCP is under active development. Check the [official Chrome WebMCP documentation](https://developer.chrome.com/docs/ai/webmcp), [Imperative API guide](https://developer.chrome.com/docs/ai/webmcp/imperative-api), [Declarative API guide](https://developer.chrome.com/docs/ai/webmcp/declarative-api), [best practices](https://developer.chrome.com/docs/ai/webmcp/best-practices), and [tool security guidance](https://developer.chrome.com/docs/ai/webmcp/secure-tools) for current browser behavior. Use the [Google DESIGN.md specification](https://github.com/google-labs-code/design.md) for the external design-document format.

## Development checks

```sh
SKILL_VALIDATOR_PYTHON=/usr/bin/python3 bash scripts/validate-skills.sh
scripts/test-adapters.sh
make toolkit
make doctor
bash -n scripts/validate-skills.sh
git diff --check
```

`make` builds the Bikeshed publication when needed. `index.html` is generated output and is intentionally ignored. The adapter fixture is not a browser conformance suite; use browser/version-specific evidence and the live adapter outputs for support claims.
