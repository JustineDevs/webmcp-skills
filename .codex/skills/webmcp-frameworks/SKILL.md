---
name: webmcp-frameworks
description: "Use when integrating WebMCP with React, Angular, TypeScript, component lifecycles, schema typing, or framework-specific tool registration."
---

# WebMCP framework integration

Keep WebMCP registration aligned with the framework lifecycle without hiding the browser standard.

## Authority and boundaries

The normative API is [`index.bs`](../../../index.bs). React and Angular integrations are experimental convenience layers documented by Chrome; verify package and framework behavior against their current documentation before shipping.

## Core workflow

1. Define the tool contract independently of the component or dependency-injection container.
2. Use TypeScript types for the tool input and output; use `webmcp-types` when the project needs API typings.
3. Register on mount or application initialization and unregister on unmount or unusable state.
4. Pass cancellation signals through framework-managed async work.
5. Keep execution state and visible UI updates synchronized.
6. Test remounts, duplicate registration, stale closures, navigation, cancellation, and SSR/client boundaries.

## React

Use the experimental `useWebMCP` integration only when its version and lifecycle guarantees are acceptable. The hook should make registration follow component mount/unmount and expose schema-driven input inference or local execution state without replacing direct WebMCP semantics.

## Angular

Use experimental Angular support only with explicit version validation. Bind registration to the application's dependency-injection lifecycle and Signal Forms lifecycle; ensure destroyed providers cannot keep tools registered.

## Framework-agnostic rule

Framework code must still produce a normal WebMCP tool with a stable name, clear description, JSON Schema, annotations, and cancellable `execute`. Do not rely on framework state that is not represented in the tool's preconditions or visible result.

## Output checklist

- [ ] API typings and framework versions are identified.
- [ ] Registration and cleanup follow the actual lifecycle.
- [ ] Async work receives and honors `AbortSignal`.
- [ ] SSR, remount, duplicate, stale-state, and cancellation cases are tested.
- [ ] The resulting contract remains understandable without the framework.
