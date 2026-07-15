# Jira Ticket Writer usage notes

Use these notes to generate Jira tickets that are complete, clear, and ready for implementation.

## Supported issue types

- task
- story
- bug
- epic

If issue type is not provided, infer the best fit from context and state the assumption.

## General rules

- Keep factual accuracy: do not invent data, links, or requirements.
- Keep sections in the exact order for each type.
- Keep section headings exactly as defined below.
- Use concise, practical language.
- When information is missing, add "TBD" and list the gap in "Open questions".

## Templates

### task

## Scope, Background & Context & Problem to solve
*Description of the scope and the boundaries of the change. Add background information giving more context (if needed). And add a description of the problem to solve or why this task is needed.*

## Documentation
*Link to relevant documentation*

- 

## Acceptance criteria
*Requirement(s) for ticket to be done*

-

### story

## Job Story
*When - the situation or the context, I want to - the goal or motivation, and So I can - expected outcome*

When ...
I want to ...
So I can ...

## Scope
*Define the scope here*

## Documentation
*Links to relevant documentation*

- 

## Acceptance Criteria
*When is the ticket done*

-

### bug

## Problem definition and Observed
*Describe the problem and what you see and what you do not expect to see. Add screenshots if relevant.*

## Expected
*Describe what you expect to see.*

## Steps to reproduce
*A detailed list of steps taken to observe the problem*

1.

### epic

## Objective
*A brief statement of what this epic aims to achieve and its value to the project*

## Scope & Context
*Description of the overall scope, context, and boundaries of this epic. What areas of the project does it cover? What is included and excluded?*

## Business & Technical Requirements

- Detailed list of business technical requirements that the epic should fulfil

## Documentation

- Links to relevant documentation that can help understand or implement the epic

## Risks & Dependencies

- List of potential risks and dependencies that might impact the delivery of the epic

## Stakeholders

-

## Ticket quality checklist

1. Title reflects the core problem or outcome.
2. Scope is explicit about what is in and out.
3. Acceptance criteria are testable and unambiguous.
4. Dependencies and risks are called out when relevant.
5. No generic filler text remains in the final output.

## Missing information handling

When critical information is missing:
- Add "TBD" in the relevant section.
- Append an "Open questions" section with only the missing items.
- Do not guess owners, due dates, or technical solutions.

## Example outputs

### Example task

## Scope, Background & Context & Problem to solve
The support team currently receives order-failure alerts in email only. This creates delays in response during high-traffic periods because alerts are not visible in the shared incident channel. Scope is limited to routing payment failure alerts from the payment service to Slack and documenting the new flow. Out of scope: changing payment retry logic.

## Documentation

- https://internal.docs/payments/alerting

## Acceptance criteria

- Payment failure alerts are posted to #ops-incidents within 30 seconds of failure.
- Alert payload includes order ID, customer region, and failure reason.
- Runbook is updated with troubleshooting steps for this alert.

### Example story

## Job Story
When I review a failed payout in the admin panel,
I want to see the provider error code and message,
So I can resolve merchant tickets without escalating to engineering.

## Scope
Add provider error details to the payout details page for failed payouts only. Include a short help tooltip for common error codes. Exclude historical backfill for payouts older than 90 days.

## Documentation

- https://internal.docs/payouts/error-codes

## Acceptance Criteria

- Failed payout view shows provider error code and message.
- Tooltip explains at least the top 5 error codes handled by support.
- Information is hidden for successful payouts.

### Example bug

## Problem definition and Observed
On mobile Safari, tapping "Save" on the profile form does not submit changes when the optional phone field is empty. The button shows loading for one second and returns to idle state with no confirmation message.

## Expected
Tapping "Save" should persist profile changes and show a success confirmation, regardless of whether the optional phone field is empty.

## Steps to reproduce

1. Open account profile on iOS Safari.
2. Clear the phone field.
3. Update first name.
4. Tap Save.
5. Observe that no success message appears and the change is not persisted.

### Example epic

## Objective
Improve checkout reliability and visibility so failed payments are detected earlier and recovered faster.

## Scope & Context
This epic covers payment observability, retry orchestration improvements, and support-facing diagnostics across checkout and payout flows. Includes alerting, dashboards, and error-surface improvements. Excludes payment-provider migration and pricing changes.

## Business & Technical Requirements

- Define SLO for payment authorization success rate.
- Implement standardized payment failure event schema.
- Add retry outcome tracking by provider and region.
- Expose actionable failure details in admin tooling.

## Documentation

- https://internal.docs/payments/roadmap-2026
- https://internal.docs/checkout/slo

## Risks & Dependencies

- Dependency on data-platform team for event ingestion pipeline.
- Risk of noisy alerts during initial rollout.
- Provider API rate limits may affect retry telemetry.

## Stakeholders

- Payments engineering
- Support operations
- Product manager, checkout
