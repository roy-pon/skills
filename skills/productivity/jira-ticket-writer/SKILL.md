---
name: jira-ticket-writer
description: "Draft clear Jira tickets from raw input using standardized templates and acceptance criteria."
metadata:
  version: "0.1.0"
argument-hint: "ticket context, notes, or incident details"
---

# Jira Ticket Writer

## When to use

Use this skill when the user wants a clean, actionable Jira ticket from rough notes, chat threads, meeting outcomes, or incident details.

Supported Jira issue types in this skill:
- task
- story
- bug
- epic

Common trigger phrases:
- "Write a Jira ticket"
- "Turn this into a story"
- "Draft a bug ticket"
- "Create an epic from this initiative"

## Workflow

1. Identify ticket type first. If unclear, choose the best fit and state the assumption.
2. Extract only verifiable facts from the source. Do not invent details.
3. Produce the ticket using the exact format for the selected type from [Usage notes](./references/usage.md).
4. Ensure each section is complete, concise, and practical.
5. Add explicit unknowns when data is missing instead of guessing.

Quality bar:
- Clear problem statement and scope boundaries.
- Concrete, testable acceptance criteria where applicable.
- Actionable language without vague filler.
- Consistent Markdown section formatting.

Output rules:
- Return only the final ticket by default.
- If assumptions were made, include a short "Assumptions" list at the end.
- If required information is missing, include a short "Open questions" list.

## References

- [Usage notes](./references/usage.md)
