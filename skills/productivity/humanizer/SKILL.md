---
name: humanizer
description: "Rewrite AI-sounding text into natural human writing while preserving meaning, voice, and factual accuracy."
metadata:
  version: "0.1.0"
argument-hint: "text to humanize"
---

# Humanizer

## When to use

Use this skill when the user wants text to sound less synthetic and more naturally human, while keeping the same meaning.

Common trigger phrases:
- "Humanize this"
- "This sounds AI, rewrite it"
- "Make this sound natural"
- "Keep my point but make it less robotic"

Use it for:
- Email drafts and status updates
- Blog posts, docs, and product copy
- Cover letters, statements, and outreach messages
- Meeting notes rewritten into natural prose

Do not use it to:
- Invent facts, sources, dates, or names
- Change the author's core claim or confidence level
- Add personality where neutral tone is required (legal, compliance, technical specs)

## Workflow

1. Identify the target register and format (business, casual, technical, academic, personal).
2. Preserve intent first: keep meaning, stance, and certainty level unchanged.
3. Remove common AI tells and mechanical patterns using [Usage notes](./references/usage.md).
4. Keep structure proportional to source length. Rewrite, do not collapse.
5. If the user provides a writing sample, mirror their rhythm, vocabulary level, and punctuation habits.
6. Run a final quality pass:
- no em dashes
- sentence case headings and bullets
- no chatbot artifacts or filler closers
- no added claims or fabricated detail

Default output format:
- Final rewrite only.
- If user asks for explanation, add a short "Changes made" section after the rewrite.

Quality bar:
- Sounds human, specific, and readable aloud.
- Keeps factual content and practical intent.
- Uses natural sentence-length variation.
- Avoids hype, generic positivity, and performative rhetoric.

If source quality is already natural:
- Make minimal edits.
- Say briefly that only light editing was needed.

## References

- [Usage notes](./references/usage.md)
