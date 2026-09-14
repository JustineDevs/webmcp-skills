# WebMCP Skill Catalog

Canonical inventory for the repo-local skill surface. Normalize directory paths with a trailing `/`. A skill directory owns its `SKILL.md`; that file is not repeated as a separate file row.

Run `scripts/validate-skills.sh` before publication checks. It intentionally fails closed when the Codex skill validator or its PyYAML prerequisite is unavailable.

| Path | Kind | Owner | Role | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| `.agents/` | directory | webmcp-maintainer | Codex project discovery surface | active | Alias namespace |
| `.agents/skills/` | directory | webmcp-maintainer | Codex project skill discovery | active | Symlink to `.codex/skills/` |
| `skills/` | directory | webmcp-maintainer | Agent Skills CLI discovery | active | Symlink to `.codex/skills/` |
| `.codex/` | directory | webmcp-maintainer | Repo-local agent skill surface | active | Product content |
| `.codex/skills/` | directory | webmcp-maintainer | Canonical skill collection | active | Exactly thirteen skills plus catalog |
| `.codex/skills/catalog.md` | file | webmcp-maintainer | Canonical skill and repository inventory | active | Maintainer-owned catalog |
| [`.codex/skills/webmcp-agents/`](webmcp-agents/SKILL.md) | skill | webmcp-agents | Universal WebMCP routing and capability contract | active | Owns `SKILL.md` |
| [`.codex/skills/webmcp-core/`](webmcp-core/SKILL.md) | skill | webmcp-core | Normative API and authoring guidance | active | Owns `SKILL.md` |
| [`.codex/skills/webmcp-agent-browser/`](webmcp-agent-browser/SKILL.md) | skill | webmcp-agent-browser | Agent-browser loop plus UI↔UX verification | active | Operational only |
| [`.codex/skills/webmcp-runtime/`](webmcp-runtime/SKILL.md) | skill | webmcp-runtime | Browser, DevTools, Lighthouse, and native adapter boundaries | active | Operational only |
| [`.codex/skills/webmcp-declarative/`](webmcp-declarative/SKILL.md) | skill | webmcp-declarative | Declarative form proposal guidance | exploratory | Preserves TBD |
| [`.codex/skills/webmcp-design-md/`](webmcp-design-md/SKILL.md) | skill | webmcp-design-md | DESIGN.md lexer, AST, token, renderer, and UI↔UX pipeline | active | External format is alpha |
| [`.codex/skills/webmcp-service-workers/`](webmcp-service-workers/SKILL.md) | skill | webmcp-service-workers | Service-worker proposal guidance | exploratory | Preserves TBD |
| [`.codex/skills/webmcp-security/`](webmcp-security/SKILL.md) | skill | webmcp-security | Security, privacy, and consent review | active | Normative risks plus gaps |
| [`.codex/skills/webmcp-maintainer/`](webmcp-maintainer/SKILL.md) | skill | webmcp-maintainer | Spec build, catalog, and contribution maintenance | active | Owns repo plumbing |
| [`.codex/skills/webmcp-tool-design/`](webmcp-tool-design/SKILL.md) | skill | webmcp-tool-design | Tool, UI↔UX, lifecycle, and recovery design | active | Tool strategy and journey design |
| [`.codex/skills/webmcp-evals/`](webmcp-evals/SKILL.md) | skill | webmcp-evals | Probabilistic tool and journey evaluation | active | Selection, chaining, safety, and output tests |
| [`.codex/skills/webmcp-frameworks/`](webmcp-frameworks/SKILL.md) | skill | webmcp-frameworks | React, Angular, and TypeScript integration | active | Experimental framework guidance |
| [`.codex/skills/webmcp-setup/`](webmcp-setup/SKILL.md) | skill | webmcp-setup | Chrome setup, origin trials, and support checks | active | Progressive-enhancement setup |
| `.github/` | directory | webmcp-maintainer | CI and dependency automation | active | Tracked directory |
| `.github/workflows/` | directory | webmcp-maintainer | Publication workflow | active | Tracked directory |
| `.github/dependabot.yml` | file | webmcp-maintainer | GitHub Actions update policy | active | Tracked file |
| `.github/workflows/auto-publish.yml` | file | webmcp-maintainer | Build, validate, and deploy workflow | active | Tracked file |
| `assets/` | directory | webmcp-maintainer | Repository branding assets | active | Tracked directory |
| `assets/openai.svg` | file | webmcp-maintainer | Light branding asset | active | Tracked file |
| `assets/openai-white.svg` | file | webmcp-maintainer | Dark branding asset | active | Tracked file |
| `docs/` | directory | webmcp-maintainer | Exploratory proposal documents | active | Tracked directory |
| `docs/service-workers.md` | file | webmcp-service-workers | Service-worker explainer source | exploratory | Proposal/TBD source |
| `ARCHITECTURE.md` | file | webmcp-maintainer | Repository navigation | active | Product documentation |
| `CONTRIBUTING.md` | file | webmcp-maintainer | W3C contribution rules | active | Tracked file |
| `LICENSE.md` | file | webmcp-maintainer | W3C license notice | active | Tracked file |
| `Makefile` | file | webmcp-maintainer | Bikeshed build, lint, watch, toolkit, and doctor checks | active | Tracked file |
| `README.md` | file | webmcp-maintainer | Project README and skill entry point | active | Supporting, not normative |
| `docs/webmcp-explainer.md` | file | webmcp-core | Motivation and API explainer | active | Supporting, not normative |
| `declarative-api-explainer.md` | file | webmcp-declarative | Declarative API proposal source | exploratory | Proposal/TBD source |
| `implementation-status.md` | file | webmcp-maintainer | Browser/product support notes | active | Informational |
| `index.bs` | file | webmcp-core | Normative Bikeshed source | active | Sole normative authority |
| `security-privacy-questionnaire.md` | file | webmcp-security | W3C security/privacy review | active | Review source |
| `w3c.json` | file | webmcp-maintainer | W3C repository metadata | active | Tracked file |
| `.gitignore` | file | webmcp-maintainer | Generated-output policy | active | Ignores `index.html` |
| `.pr-preview.json` | file | webmcp-maintainer | Pull-request preview metadata | active | Points to `index.bs` |
| `scripts/` | directory | webmcp-maintainer | Repository validation and host-adapter helpers | active | Maintainer executable surface |
| `scripts/validate-skills.sh` | file | webmcp-maintainer | Skill/catalog validator | active | Run before publication checks |
| `scripts/webmcp-agent-browser.sh` | file | webmcp-maintainer | Page-local WebMCP discovery, execution, and observation adapter | active | Uses the installed agent-browser session |
| `scripts/webmcp-chrome-devtools.sh` | file | webmcp-maintainer | WebMCP, DevTools, and Lighthouse adapter over Chrome DevTools CLI | active | Auto-resolves CLI and Chromium executable |
| `scripts/webmcp-android.sh` | file | webmcp-maintainer | Native Android emulator/device adapter over ADB | active | Requires an authorized Android target |
| `scripts/webmcp-ios.sh` | file | webmcp-maintainer | iOS Simulator lifecycle and UI adapter over simctl/idb | active | Requires macOS/Xcode; idb enables UI input |
| `scripts/webmcp-desktop.sh` | file | webmcp-maintainer | macOS, Windows, and Linux desktop adapter | active | Uses native screenshot/input tools |
| `scripts/webmcp-device.sh` | file | webmcp-maintainer | Universal Android/iOS/desktop adapter dispatcher | active | One cross-platform command surface |
| `scripts/webmcp-toolkit.mjs` | file | webmcp-maintainer | Dependency-free schema, security, eval, design, setup, and doctor runtime | active | Shared domain implementation |
| `scripts/webmcp-toolkit.sh` | file | webmcp-maintainer | Portable toolkit launcher | active | Node runtime wrapper |
| `scripts/test-adapters.sh` | file | webmcp-maintainer | Browser fixture and native adapter smoke test | active | Exercises real discovery, execution, and device probing |
| `tests/` | directory | webmcp-maintainer | Runtime adapter fixtures | active | Maintainer test surface |
| `tests/fixtures/` | directory | webmcp-maintainer | WebMCP, manifest, eval, and DESIGN.md fixtures | active | Used by adapter and toolkit checks |
| `tests/fixtures/webmcp-fixture.html` | file | webmcp-maintainer | Browser fixture document | active | Local deterministic page |
| `tests/fixtures/webmcp-fixture.js` | file | webmcp-maintainer | Browser fixture WebMCP context | active | Exposes a real discovery/execution-shaped tool |
| `tests/fixtures/tools.json` | file | webmcp-maintainer | Tool schema/security fixture | active | Closed schemas and safe annotations |
| `tests/fixtures/evals.json` | file | webmcp-maintainer | Deterministic WebMCP eval fixture | active | Includes refusal and confirmation cases |
| `tests/fixtures/DESIGN.md` | file | webmcp-maintainer | DESIGN.md parser fixture | active | Front matter, references, states, and accessibility |
| `.omx/` | excluded | workflow-runtime | Local OMX workflow state | excluded | Never product content |
| `index.html` | excluded | build-output | Ignored generated publication | excluded | Generate locally; do not commit |

## Source authority

`index.bs` is the only normative WebMCP source. Markdown files are explainers, status, reviews, or proposals. Declarative and service-worker material must preserve `TBD`, TODO, and open-question boundaries. The agent-browser skill is operational guidance inspired by Vercel's official workflow, not WebMCP conformance.
