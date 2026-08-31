---
name: webmcp-setup
description: "Use when enabling WebMCP locally, preparing Chrome origin-trial experiments, checking browser support, or documenting WebMCP development setup."
---

# WebMCP setup and support

Prepare a reproducible browser environment for WebMCP experimentation without presenting preview APIs as stable production guarantees.

## Authority and boundaries

WebMCP is a proposed standard under active discussion. Follow the official Chrome documentation and origin-trial terms for the current browser version. This skill documents setup; it does not install Chrome, enroll users, or claim universal support.

## Core workflow

1. Install the skill collection with `npx skills add JustineDevs/webmcp-skills`; for unattended global installation to the detected agent, add `-y -g`; for every vendor, add `--skill '*' --agent '*' -y -g`.
2. Record the target Chrome version, operating system, origin, and feature status.
3. For local development, enable `chrome://flags/#enable-webmcp-testing` and relaunch Chrome.
4. For an origin-trial experiment, follow Chrome's current Origin Trial enrollment and token rules.
5. Verify tool registration, discovery, schema parsing, execution, cancellation, and visible state in a real browser.
6. Record unsupported browsers, fallback UI behavior, and the date/version tested.

## Distribution surfaces

`npx skills add` installs the repository's loose Agent Skills for the detected agent by default. Use `--agent <id>` for one vendor or `--agent '*'` for every supported vendor. The root `skills/` path is the portable discovery alias for the canonical `.codex/skills/` collection; `.agents/skills/` remains a project-discovery alias. Vendor-specific install directories are created by the CLI, not maintained in this repository. A Codex plugin is a separate distribution wrapper: it requires `.codex-plugin/plugin.json`, a manifest skill path, and a marketplace entry before `codex plugin marketplace add` and `codex plugin add` can be used. Do not present an unpublished wrapper as available.

## Progressive enhancement

The site must remain usable without WebMCP. Keep ordinary forms, keyboard access, visible controls, and server-side validation intact. WebMCP should improve agent interaction, not become the only path to a user action.

## Output checklist

- [ ] Browser version and feature enablement are recorded.
- [ ] Origin-trial or local-flag assumptions are explicit.
- [ ] Non-WebMCP fallback remains functional.
- [ ] API and user-journey smoke tests pass in the target browser.
- [ ] Support limitations and test date are documented.
