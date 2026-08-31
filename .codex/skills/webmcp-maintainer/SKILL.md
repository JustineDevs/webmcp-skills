---
name: webmcp-maintainer
description: "Use for maintaining this WebMCP specification repository: Bikeshed builds, validation, catalog ownership, CI metadata, contribution rules, and stale-content checks."
---

# WebMCP repository maintenance

Use this skill for repository hygiene, publication, contribution, and skill-suite maintenance.

## Authority and boundaries

The normative source is [`index.bs`](../../../index.bs). This skill owns [`Makefile`](../../../Makefile), [`w3c.json`](../../../w3c.json), [`CONTRIBUTING.md`](../../../CONTRIBUTING.md), [`LICENSE.md`](../../../LICENSE.md), [`.github/`](../../../.github/), [`.pr-preview.json`](../../../.pr-preview.json), [`.gitignore`](../../../.gitignore), [`ARCHITECTURE.md`](../../../ARCHITECTURE.md), the catalog, and `scripts/validate-skills.sh`.

## Publication workflow

- `make` generates `index.html` using local Bikeshed or the CSSWG Bikeshed API fallback.
- `make lint` runs local Bikeshed diagnostics when installed.
- `make watch` regenerates while editing when local Bikeshed is installed.
- `index.html` is generated output and must remain ignored and untracked.
- Never treat a remote redirect or error page as successful publication.

## Skill distribution

- The canonical install is `npx skills add JustineDevs/webmcp-skills`; automation for the detected agent uses `-y -g`, while all-vendor automation uses `--skill '*' --agent '*' -y -g`.
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
6. Run `git diff --check`; run `make lint` when local Bikeshed is available.

## Contribution checks

Read [`CONTRIBUTING.md`](../../../CONTRIBUTING.md) before substantive changes. Preserve W3C attribution rules, license terms, CI publication behavior, preview metadata, architecture documentation, and catalog ownership.

## Output checklist

- [ ] Every repository file and directory has one catalog owner and role.
- [ ] Exactly the catalog allowlist exists under `.codex/skills/`.
- [ ] Validation, diff hygiene, and available publication checks pass.
- [ ] Generated output and environment-only gaps are reported explicitly.
