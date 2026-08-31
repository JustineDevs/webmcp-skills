# webmcp-agents

Curated agent skills for building, exposing, operating, securing, evaluating, and maintaining WebMCP tools in the browser.

WebMCP is a proposed web standard for structured tools that help AI agents interact with web applications. This project organizes implementation guidance around the page, its live application state, and the user's visible UI↔UX journey. It does not implement a browser, agent, CLI, MCP server, or WebMCP runtime.

## Install

The canonical install is:

```sh
npx skills add JustineDevs/webmcp-skills
```

For an unattended global install to the detected agent, use `npx skills add JustineDevs/webmcp-skills -y -g`. For every supported vendor, use `npx skills add JustineDevs/webmcp-skills --skill '*' --agent '*' -y -g`. For a project-local installation, omit `-g`; for one vendor, use `--agent <id>`. The repository URL remains `JustineDevs/webmcp-skills` until the GitHub repository is renamed.

The root `skills/` alias is the portable discovery surface. `.agents/skills/` and `.codex/skills/` are repository-local compatibility aliases, not copies, so one `SKILL.md` remains the source of truth.

### Agent vendor matrix

The Skills CLI writes each skill into the vendor's native project or global directory. Use the vendor ID shown below, or use `--agent '*'` to target all detected vendors:

| Agent vendor | Skills CLI agent ID | Install command |
| --- | --- | --- |
| Claude Code | `claude-code` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent claude-code` |
| OpenAI Codex | `codex` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent codex` |
| Cursor | `cursor` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent cursor` |
| GitHub Copilot | `github-copilot` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent github-copilot` |
| Windsurf | `windsurf` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent windsurf` |
| Gemini CLI | `gemini-cli` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent gemini-cli` |
| Cline | `cline` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent cline` |
| Amp | `amp` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent amp` |
| OpenCode | `opencode` | `npx skills add JustineDevs/webmcp-skills --skill '*' --agent opencode` |

The CLI's supported-agent list can change. Confirm available IDs with `npx skills add --help`; the portable contract is the `SKILL.md` format and the repository's root `skills/` discovery path, not a vendor-specific prompt or duplicate skill tree. The `--copy` option is available when a vendor or filesystem does not support symlinks.

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
```

Use `npx skills list --json` for the installed-agent inventory, or replace `'*'` with one valid agent ID in `npx skills list -a <id>`. `*` is valid for `skills add`, not for the `skills list` filter. Start a fresh agent session after installation so it reloads the skill directories.

## Start here

1. Read [`ARCHITECTURE.md`](ARCHITECTURE.md) for repository boundaries and data flow.
2. Use the [skill catalog](.codex/skills/catalog.md) to load the smallest relevant skill.
3. Treat [`index.bs`](index.bs) as the sole normative WebMCP source.
4. Run `SKILL_VALIDATOR_PYTHON=/usr/bin/python3 bash scripts/validate-skills.sh` before publishing skill changes.

For the original WebMCP motivation, API explainer, use cases, and open questions, read [`docs/webmcp-explainer.md`](docs/webmcp-explainer.md).

## What the skills cover

| Skill | Use it for |
| --- | --- |
| [`webmcp-agent-browser`](.codex/skills/webmcp-agent-browser/SKILL.md) | WebMCP-first browser interaction with inspect, execute, refresh, and verify |
| [`webmcp-core`](.codex/skills/webmcp-core/SKILL.md) | Normative API, registration, discovery, execution, lifecycle, and cancellation |
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
bash -n scripts/validate-skills.sh
git diff --check
```

`make` builds the Bikeshed publication when needed. `index.html` is generated output and is intentionally ignored. No local conformance suite is included; keep claims scoped to the specification, explainers, browser documentation, and recorded implementation evidence.
