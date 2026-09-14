---
name: webmcp-maintainer
description: "Use for maintaining this WebMCP specification repository: Bikeshed builds, validation, catalog ownership, CI metadata, contribution rules, and stale-content checks."
---

# WebMCP repository maintenance

Use this skill for repository hygiene, publication, contribution, and skill-suite maintenance.

## Authority and boundaries

The normative source is [`index.bs`](../../../index.bs). This skill owns [`Makefile`](../../../Makefile), [`w3c.json`](../../../w3c.json), [`CONTRIBUTING.md`](../../../CONTRIBUTING.md), [`LICENSE.md`](../../../LICENSE.md), [`.github/`](../../../.github/), [`.pr-preview.json`](../../../.pr-preview.json), [`.gitignore`](../../../.gitignore), [`ARCHITECTURE.md`](../../../ARCHITECTURE.md), the catalog, and the executable adapter/validation scripts under `scripts/`.

## Publication workflow

- `make` generates `index.html` using local Bikeshed or the CSSWG Bikeshed API fallback.
- `make lint` runs local Bikeshed diagnostics when installed.
- `make watch` regenerates while editing when local Bikeshed is installed.
- `make test-adapters` runs the browser fixture and live Android/iOS/desktop native adapter probes.
- `make toolkit` runs deterministic schema, security, eval, and DESIGN.md fixture checks.
- `make doctor` combines skill validation, host readiness, and all deterministic fixture checks.
- `index.html` is generated output and must remain ignored and untracked.
- Never treat a remote redirect or error page as successful publication.

## Skill distribution

- The canonical install is `npx skills add JustineDevs/webmcp-skills`; unattended all-agent installation uses the current CLI's `--all` shorthand, and installed copies are refreshed with `npx skills update`.
- Keep the README's skills.sh badge and CLI guidance aligned with the current [skills.sh CLI reference](https://www.skills.sh/docs/cli); do not maintain a frozen vendor allowlist when the CLI can enumerate supported agents.
- Keep `skills/` and `.agents/skills/` as aliases to the canonical `.codex/skills/` collection; never duplicate `SKILL.md` content or add vendor-specific copies.
- Verify discovery with `npx skills add . --list` before publishing; the repository must expose every intended `SKILL.md`.
- Verify the current vendor IDs with `npx skills add --help`; do not hard-code an exhaustive vendor list into the skill tree because the CLI owns that compatibility map.
- Treat Codex plugin distribution as a separate package surface requiring `.codex-plugin/plugin.json` and a marketplace entry. Do not document plugin installation until those manifests are published and verified.

## Skill-suite maintenance

1. Keep exactly the skill directories named in [`catalog.md`](../catalog.md); the validator's fixed allowlist is the change gate.
2. Keep one `SKILL.md` per skill directory; the directory owns it in the catalog.
3. Link to source documents instead of copying large normative sections.
4. Preserve `TBD`, TODO, and open-question language in proposal skills.
5. Run `bash scripts/validate-skills.sh` before claiming the suite is healthy.
6. Keep browser support claims in [`implementation-status.md`](../../../implementation-status.md) separate from host-tool availability. Chrome DevTools MCP is a Chrome-focused adapter; WebMCP support must still be feature-detected in each browser.
7. Run `git diff --check`; run `make lint` when local Bikeshed is available.

## Contribution checks

Read [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) before substantive changes. Preserve W3C attribution rules, license terms, CI publication behavior, preview metadata, architecture documentation, and catalog ownership.

## Output checklist

- [ ] Every repository file and directory has one catalog owner and role.
- [ ] Exactly the catalog allowlist exists under `.codex/skills/`.
- [ ] Validation, adapter smoke tests, diff hygiene, and available publication checks pass.
- [ ] Adapter scripts are executable, documented, and use a real browser page or verified native target; missing host tools fail explicitly rather than fabricating success.
- [ ] Browser support and DevTools/Lighthouse host support are not conflated.
- [ ] Generated output and environment-only gaps are reported explicitly.
