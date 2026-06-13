# Requirements Traceability Matrix

This matrix links each requirement to its acceptance criteria, the tests that verify it, and its current verification status. It provides a single, auditable view from product intent to evidence of completion.

It is a living document. Update it in the same change that adds, modifies, or verifies a requirement.

Related documents:

- `docs/PRODUCT_REQUIREMENTS.md` — the source of requirement definitions and IDs.
- `docs/TEST_PLAN.md` — coverage targets, continuous evaluation, and the gap log.

## Conventions

- **Requirement ID**: matches the ID in `docs/PRODUCT_REQUIREMENTS.md` (for example, `FR-001`, `NFR-001`).
- **Level**: `MUST`, `SHOULD`, `COULD`, or `WON'T`.
- **Acceptance criteria**: the verifiable conditions for the requirement (may be referenced as `FR-001-AC-1`).
- **Verifying tests**: the test names, files, or IDs that exercise the requirement.
- **Status**: `Not Started`, `In Progress`, `Verified`, or `Deferred`.

A requirement with no verifying test is a coverage gap. Record it in `docs/TEST_PLAN.md` (gap log) and in `TODO.md` under Testing.

## Functional Requirements

| Requirement ID | Level | Description | Acceptance Criteria | Verifying Tests | Status |
| --- | --- | --- | --- | --- | --- |
| FR-001 | MUST | `<requirement description>` | `<FR-001-AC-1: observable condition>` | `<test reference or "none — GAP">` | Not Started |

## Non-Functional Requirements

| Requirement ID | Level | Description | Acceptance Criteria | Verifying Tests | Status |
| --- | --- | --- | --- | --- | --- |
| NFR-001 | MUST | `<requirement description>` | `<NFR-001-AC-1: observable condition>` | `<test reference or "none — GAP">` | Not Started |

## Coverage Summary

| Metric | Count |
| --- | --- |
| Total requirements | `<n>` |
| Verified | `<n>` |
| In progress | `<n>` |
| Not started | `<n>` |
| Requirements without a verifying test (gaps) | `<n>` |
