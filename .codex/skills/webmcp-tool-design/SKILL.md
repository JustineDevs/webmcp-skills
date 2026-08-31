---
name: webmcp-tool-design
description: "Use when planning or designing WebMCP tools, critical user journeys, schemas, tool descriptions, registration strategy, state transitions, or recovery behavior."
---

# WebMCP tool design

Design small, semantic tools that complete real user goals through the live page.

## Authority and boundaries

Use [`index.bs`](../../../index.bs) for normative API behavior. Use Chrome's WebMCP guidance for design practice, but do not turn examples or proposal text into conformance requirements. WebMCP is a progressive enhancement for a live tab, not a replacement for backend MCP.

## Core workflow

1. Define the user's desired outcome, required context, boundaries, and success signal.
2. Map the critical journey and identify the smallest non-overlapping tool functions.
3. Name tools with precise verbs and describe what they do and when to use them.
4. Design a minimal JSON Schema with formats, enums, required fields, and useful descriptions.
5. Define registration state, preconditions, visible UI effects, result shape, and recovery errors.
6. Simulate vague requests, chained calls, invalid input, stale state, cancellation, and confirmation.

### UI↔UX connection contract

Design the tool and page journey together:

`intent → affordance → precondition → action → progress → settled UI state → structured result → recovery`

The tool must reuse the same application state transition as the human UI. Define loading, disabled, success, empty, error, and cancellation states; focus/status behavior; and where a person can review, interrupt, edit, or take over. Keep labels, accessible names, descriptions, and tool metadata semantically aligned, but do not treat metadata as permission to act.

Acceptance requires both sides: an agent can discover, select, validate, execute, and verify the tool; a human can understand what changed, why it changed, what failed, and what to do next without an agent. If the structured result says success while the rendered UI is pending, ambiguous, or showing an error, the contract is incorrect.

## Design rules

- Prefer one clear function per tool; avoid overlapping tools competing for the same intent.
- Static registration is the default. Dynamically register or unregister only when page state changes usability.
- Let the agent ask for missing information. Do not encode a brittle, hidden sequence of negative instructions.
- Return concise, stable, machine-readable results and context-aware errors.
- Keep tools tied to existing application logic and visible user-facing state.
- Mark read-only and untrusted-output behavior with annotations; annotations are signals, not authorization.

## Tool contract

```ts
await document.modelContext.registerTool({
  name: "lookup_order",
  title: "Look up an order",
  description: "Find an order by its number and return its current status.",
  inputSchema: {
    type: "object",
    properties: { orderNumber: { type: "string", minLength: 1 } },
    required: ["orderNumber"],
    additionalProperties: false,
  },
  annotations: { readOnlyHint: true },
  execute: async ({ orderNumber }, { signal }) => {
    const response = await fetch(`/orders/${encodeURIComponent(orderNumber)}`, { signal });
    if (!response.ok) return `Order lookup failed with status ${response.status}.`;
    return await response.json();
  },
});
```

## Recovery contract

Errors should tell the agent what is wrong and what information or prerequisite resolves it. For example: `No search results exist. Run search_flights first.` Avoid raw stack traces, silent failures, and automatic retries that could repeat a side effect.

## Output checklist

- [ ] User goal, scope, and success state are explicit.
- [ ] Intent, affordance, progress, settled UI state, feedback, accessibility, and human takeover are defined.
- [ ] Tools are non-overlapping and named with precise verbs.
- [ ] Schema and validation cover malformed, missing, and ambiguous input.
- [ ] Registration, visible effects, result, error, cancellation, and confirmation behavior are defined.
- [ ] The journey is tested with representative and adversarial inputs.
