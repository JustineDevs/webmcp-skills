---
name: webmcp-core
description: Use for normative WebMCP API authoring, tool registration, discovery, execution, lifecycle, and spec-grounded implementation guidance.
---

# WebMCP core

Use this skill when a task concerns the WebMCP API itself or needs a source-grounded decision about page tools.

## Authority and boundaries

[`index.bs`](../../../index.bs) is the normative authority for Web IDL, algorithms, lifecycle rules, exceptions, permissions policy, and security requirements. [`README.md`](../../../README.md) is explanatory context. Do not promote declarative or service-worker proposals into normative behavior.

## Model

Treat `document.modelContext` as the page-local tool container. A tool has a constrained name, optional title, description, input schema, execute callback, and annotations; `exposedTo` is supplied separately in the `registerTool()` options. Tool registrations are document-lifetime state.

The core API supports `registerTool(tool, options)`, `getTools(options)`, `executeTool(tool, inputObject, options)`, `ontoolchange`, and `AbortSignal` cancellation. Use the exact IDL and algorithms in `index.bs` when behavior matters.

## Authoring workflow

1. Reuse the existing page function that performs the user-visible operation.
2. Give the tool a stable name and a description that explains when it should be used.
3. Declare the smallest JSON Schema input needed.
4. Reuse the page's state and UI update path inside `execute`.
5. Pass the abort signal to cancellable work and avoid reporting success before state settles.
6. Set `readOnlyHint` only for operations that truly do not modify state; use `untrustedContentHint` for untrusted output.
7. Test duplicate names, malformed schemas, inactive documents, policy denial, cancellation, and dynamic tool changes.

## Current API details

- `getTools()` returns authorized tools for the calling document. Request cross-origin tools with `fromOrigins` only after the hosting origin exposes them with `exposedTo`.
- The repository IDL defines `executeTool(tool, inputObject, options)` with an object input and a `DOMString` result. Some Chrome preview documentation shows JSON text at the browser-agent boundary and `null` on navigation; version-gate that adapter and keep the repository IDL primary here.
- `AbortSignal` cancels pending execution. Registration cleanup is a separate lifecycle and must not be assumed to cancel in-flight work.
- Use [`webmcp-types`](https://www.npmjs.com/package/webmcp-types) for TypeScript declarations when appropriate, after checking version compatibility.

## Lifecycle

The conceptual lifecycle is registration → discovery → invocation → execution → result. Browser agents use browser-mediated discovery; in-page agents use `getTools()`. Tool results are stringified by the API contract, so return stable, concise, machine-readable values.

## Do not assume

Browser observation formats are implementation-defined. Declarative forms and service workers remain proposal material. Tool descriptions and annotations are not authorization.

## Output checklist

- [ ] Claims are checked against `index.bs`.
- [ ] Name, description, schema, annotations, options, and cancellation are explicit.
- [ ] Same-origin and cross-origin access rules are correct.
- [ ] Navigation, invalid input, policy denial, and inactive-document behavior are tested.
