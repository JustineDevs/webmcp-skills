# WebMCP Skill Catalog

Canonical inventory for the repo-local skill surface. Normalize directory paths with a trailing `/`. A skill directory owns its `SKILL.md`; that file is not repeated as a separate file row.

Run `scripts/validate-skills.sh` before publication checks. It intentionally fails closed when the Codex skill validator or its PyYAML prerequisite is unavailable.

| Path | Kind | Owner | Role | Status | Notes |
| --- | --- | --- | --- | --- | --- |
| `.agents/` | directory | webmcp-maintainer | Codex project discovery surface | active | Alias namespace |
| `.agents/skills/` | directory | webmcp-maintainer | Codex project skill discovery | active | Symlink to `.codex/skills/` |
| `skills/` | directory | webmcp-maintainer | Agent Skills CLI discovery | active | Symlink to `.codex/skills/` |
| `.codex/` | directory | webmcp-maintainer | Repo-local agent skill surface | active | Product content |
| `.codex/skills/` | directory | webmcp-maintainer | Canonical skill collection | active | Exactly eleven skills plus catalog |
| `.codex/skills/catalog.md` | file | webmcp-maintainer | Canonical skill and repository inventory | active | Maintainer-owned catalog |
| [`.codex/skills/webmcp-core/`](webmcp-core/SKILL.md) | skill | webmcp-core | Normative API and authoring guidance | active | Owns `SKILL.md` |
| [`.codex/skills/webmcp-agent-browser/`](webmcp-agent-browser/SKILL.md) | skill | webmcp-agent-browser | Agent-browser loop plus UI↔UX verification | active | Operational only |
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
| `Makefile` | file | webmcp-maintainer | Bikeshed build, lint, and watch | active | Tracked file |
| `README.md` | file | webmcp-maintainer | Project README and skill entry point | active | Supporting, not normative |
| `docs/webmcp-explainer.md` | file | webmcp-core | Motivation and API explainer | active | Supporting, not normative |
| `declarative-api-explainer.md` | file | webmcp-declarative | Declarative API proposal source | exploratory | Proposal/TBD source |
| `implementation-status.md` | file | webmcp-maintainer | Browser/product support notes | active | Informational |
| `index.bs` | file | webmcp-core | Normative Bikeshed source | active | Sole normative authority |
| `security-privacy-questionnaire.md` | file | webmcp-security | W3C security/privacy review | active | Review source |
| `w3c.json` | file | webmcp-maintainer | W3C repository metadata | active | Tracked file |
| `.gitignore` | file | webmcp-maintainer | Generated-output policy | active | Ignores `index.html` |
| `.pr-preview.json` | file | webmcp-maintainer | Pull-request preview metadata | active | Points to `index.bs` |
| `scripts/` | directory | webmcp-maintainer | Repository validation helpers | active | Maintainer executable surface |
| `scripts/validate-skills.sh` | file | webmcp-maintainer | Skill/catalog validator | active | Run before publication checks |
| `.omx/` | excluded | workflow-runtime | Local OMX workflow state | excluded | Never product content |
| `index.html` | excluded | build-output | Ignored generated publication | excluded | Generate locally; do not commit |

## Source authority

`index.bs` is the only normative WebMCP source. Markdown files are explainers, status, reviews, or proposals. Declarative and service-worker material must preserve `TBD`, TODO, and open-question boundaries. The agent-browser skill is operational guidance inspired by Vercel's official workflow, not WebMCP conformance.
