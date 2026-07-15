---
name: tldr
description: "Create concise TLDR summaries with key points, actions, and decisions for long text, documents, and discussions."
metadata:
  version: "0.1.0"
argument-hint: "text to summarize"
---

# TLDR

## When to use

Use this skill when the user asks for a short, high-signal summary of longer content.

Common trigger phrases:
- "TLDR this"
- "Summarize this quickly"
- "Give me the key points only"
- "What matters here?"
- "What should I do next from this?"

Use it for:
- Meeting notes and transcripts
- Email and Slack threads
- Product documents, PRDs, RFCs, and proposals
- Incident writeups, postmortems, and status updates
- Articles, reports, and long-form research notes

## Workflow

1. Identify the source type (meeting, thread, doc, report) and desired audience if provided.
2. Extract only high-value content: decisions, blockers, risks, deadlines, owners, and open questions.
3. Remove repetition, examples, and background details that do not change decisions or actions.
4. Produce a compact summary using the default output format below.
5. If information is missing or ambiguous, state it explicitly under "Unknowns" instead of guessing.

Default output format:
- TLDR: one sentence with the main outcome.
- Key points: 3-5 bullets with facts that matter.
- Actions: 1-5 bullets with clear owners and due dates when available.
- Risks/unknowns: optional bullets for unresolved items.

Quality bar:
- Short, direct, and unambiguous.
- Faithful to source intent and certainty level.
- No invented facts, owners, or dates.
- Prefer concrete language over generic phrasing.

## References

- [Usage notes](./references/usage.md)
