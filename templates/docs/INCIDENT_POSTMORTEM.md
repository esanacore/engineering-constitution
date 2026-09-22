# Postmortem: <short incident title>

- **Date of incident**: <YYYY-MM-DD>
- **Duration**: <detection to resolution, e.g. 2h 15m>
- **Severity**: <Sev-1 / Sev-2 / Sev-3, per docs/OPERATIONS.md>
- **Author**: <name>
- **Status**: Draft | Reviewed | Actions complete

Blameless: this document exists to change systems, not to assign fault.

## Summary

<Two or three sentences: what broke, who was affected, how it was resolved.>

## Impact

- **Users / systems affected**: <add here>
- **Data affected**: <none / classification level per SECURITY.md "Data Classification">
- **Duration of user-visible impact**: <add here>

## Timeline

All times in <timezone>.

| Time | Event |
| --- | --- |
| <HH:MM> | <first symptom, alert, or report> |
| <HH:MM> | <detection / escalation> |
| <HH:MM> | <mitigation applied> |
| <HH:MM> | <resolution confirmed> |

## Root Cause

<The underlying cause, not the trigger. "The deploy failed" is a trigger; "the rollback path assumed a schema that migration 42 removed" is a cause.>

## Contributing Factors

- <missing test, missing alert, undocumented step, stale runbook, ...>

## Detection

<How it was noticed, and how long after it began. If a person noticed before monitoring did, say so — that is a finding.>

## Response

<What worked, what was slow, what the runbook lacked.>

## Corrective Actions

Each action is also a `TODO.md` item so it is tracked to completion.

| Action | Type | Owner | TODO ref | Status |
| --- | --- | --- | --- | --- |
| <e.g. add regression test for rollback across migration 42> | Prevent | <name> | <link> | Open |
| <e.g. alert on error rate > 2% for 5 min> | Detect | <name> | <link> | Open |
| <e.g. document the manual restore step in docs/OPERATIONS.md> | Mitigate | <name> | <link> | Open |

## Lessons

<What the team would tell a new engineer about this incident in one paragraph.>
