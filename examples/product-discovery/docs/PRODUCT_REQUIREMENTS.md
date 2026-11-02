# Report Export Requirements — Synthetic Example

Intent revision: 2

## Product Summary

Allow account users to export their currently filtered report to CSV. CSV
sufficiency remains a hypothesis, not observed customer evidence.

## Functional Requirements

**FR-001** `MUST` export at most 1,000 filtered rows visible to the requester.

- FR-001-AC-1: At 1,000 or fewer matching rows, export those rows with headers.
- FR-001-AC-2: Above 1,000 rows, return an actionable limit message and no
  partial export; the user can narrow filters and retry.
- Revision 2 replaces the proposed 10,000-row first slice. The ID is preserved
  because this revises the same capability; it is not assigned to new behavior.

**FR-002** `MUST` enforce the requester's existing account permissions.

- FR-002-AC-1: Requests without report access yield no report data.
- FR-002-AC-2: Export contains no rows from another account.

## Non-Functional Requirements

**NFR-001** `MUST` avoid exposing report data in failure logs.

- NFR-001-AC-1: A failed export logs an error reference without report contents.

## Non-Goals

Scheduled exports, cross-account exports, and an Excel-native format are out.

## Success Measures

Provisional measure: export task completion. Target unknown until an authorized
pilot establishes the baseline. Fictional owner: Morgan. Observation window:
the first two weeks of a future pilot. Revisit: 2026-11-09. No measured result.
