# TLDR usage notes

## Purpose

Transform long or messy input into a concise summary that is immediately useful for decision-making and execution.

## Output variants

Use the variant that best matches user intent:

1. Executive TLDR (default)
   - TLDR: one sentence
   - Key points: 3-5 bullets
   - Actions: 1-5 bullets
   - Risks/unknowns: optional

2. Ultra-short TLDR
   - TLDR: one sentence
   - Key points: max 3 bullets

3. Action-first TLDR
   - TLDR: one sentence
   - Immediate actions: prioritized bullets
   - Follow-ups: lower-priority bullets

## Compression guidance

- Preserve decisions, constraints, metrics, deadlines, and owners.
- Drop examples, anecdotes, and repeated context.
- Convert vague statements into clear neutral summaries without changing meaning.
- Keep names, dates, and numbers exact when present.

## Safety and correctness rules

- Do not infer commitments that are not explicitly stated.
- Do not invent action owners, timelines, or outcomes.
- If the source conflicts internally, capture the conflict under risks/unknowns.
- If input is too short to summarize meaningfully, provide a brief restatement and note limited context.
