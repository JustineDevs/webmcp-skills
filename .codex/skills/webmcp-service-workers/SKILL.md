---
name: webmcp-service-workers
description: "Use for exploratory WebMCP service-worker architecture, discovery, routing, multi-tab sessions, and client-scoped state."
---

# WebMCP service workers

Use this skill to analyze or extend the service-worker proposal. It is not a statement that service-worker WebMCP is standardized.

## Authority and boundaries

The source is [`docs/service-workers.md`](../../../docs/service-workers.md), supported by [`index.bs`](../../../index.bs). Discovery, installation, routing, session management, and multi-origin safety remain `TBD`. Keep guidance exploratory and do not present it as current page API behavior.

## Architectural model

Treat each page or service worker that exposes tools as a distinct tool server. A browser may have an active page, several tabs, and an installed worker. Routing must choose one recipient; a call must not be silently delivered to multiple servers.

## Core workflow

1. Define how the agent discovers the site and activates the worker.
2. Identify state owned by the worker, client, tab, or conversation.
3. Define routing for one tab, worker-only use, and tabs plus worker.
4. Add a session identifier when multiple conversations share one worker.
5. Disambiguate similar page and worker tools.
6. Define termination, tab closure, navigation, retry, and stale-session behavior.
7. Review private data, untrusted content, external communication, and cross-origin state.

## Do not overclaim

This proposal is not a backend MCP replacement, settled discovery manifest, or permission bypass. Keep alternatives, issue links, and unresolved decisions visible.

## Output checklist

- [ ] Page, worker, tab, and conversation ownership are explicit.
- [ ] Routing, session identity, termination, and stale-state behavior are defined.
- [ ] Cross-origin and private-data risks are reviewed.
- [ ] All unsettled behavior remains labeled `TBD` or proposal-only.
