---
name: webmcp-declarative
description: "Use for exploratory design and review of HTML form-based WebMCP tools, schema synthesis, agent-filled forms, and form responses."
---

# WebMCP declarative forms

Use this skill for the form-based proposal, not for settled WebMCP conformance claims.

## Authority and boundaries

The source is [`declarative-api-explainer.md`](../../../declarative-api-explainer.md), with draft context in [`index.bs`](../../../index.bs). This surface is exploratory and contains `TBD`, TODO, and issue-linked questions. Treat schema synthesis, response extraction, pseudo-classes, events, and imperative integration as proposal material unless `index.bs` later defines them.

## Proposal model

The proposal adds `toolname`, `tooldescription`, `toolautosubmit`, and `toolparamdescription`. Form controls contribute named properties and constraints to generated JSON Schema. A form may await review or auto-submit after agent filling.

## Review workflow

1. Decide whether the behavior is an existing HTML form flow or a new JavaScript operation.
2. Record controls, names, required fields, constraints, and submit behavior.
3. Separate settled HTML semantics from proposal schema synthesis.
4. Preserve the user review boundary without `toolautosubmit`.
5. Define reset, removal, declaration changes, cancellation, and navigation behavior.
6. State the response strategy; `SubmitEvent#respondWith()` and cross-document response extraction remain under discussion.
7. Link unresolved decisions to issues instead of inventing normative answers.

## Safety checks

Do not infer permission to submit a consequential form from agent-filled fields. Validate names, required controls, ranges, enumerations, and origin context. Treat form values and target-page JSON-LD as untrusted. Test reset, removal, changed metadata, blocked submission, navigation, and cancellation.

## Current Chrome surface

The current Chrome preview guide documents `toolname`, `tooldescription`, `toolautosubmit`, `toolparamdescription`, response handling, and activation/cancellation behavior. These remain preview guidance and nonnormative for this repository until `index.bs` defines them; preserve the proposal source and version-gate implementations.

In the preview surface, agent invocation can focus and populate form controls, attribute removal unregisters the generated tool, labels and ARIA descriptions contribute context, and `agentInvoked`/`respondWith()` can observe or replace response handling. `preventDefault()`, the `toolcancel` event, and WebMCP-related pseudo-classes affect submission and cancellation state. Verify each detail against the [current Chrome Declarative API guide](https://developer.chrome.com/docs/ai/webmcp/declarative-api) and keep it separate from repository conformance.

## Output checklist

- [ ] Standard form behavior remains usable without WebMCP.
- [ ] `toolname` and `tooldescription` are clear and action-oriented.
- [ ] Proposed attributes are labeled exploratory.
- [ ] Schema, submission, response, reset, navigation, and cancellation behavior is tested.
