# Test Plan

This document defines how this repository is tested, what coverage it targets, and where coverage gaps currently exist.

It is a living document. Update it whenever the test strategy, targets, or known gaps change.

## Test Strategy

Describe the testing approach for this repository using the standard pyramid:

- **Unit tests**: isolated behavior. Location / command: `<add here>`.
- **Integration tests**: interactions across modules, services, or storage. Location / command: `<add here>`.
- **End-to-end tests**: critical user workflows. Location / command: `<add here>`.

## How to Run Tests

- Full suite: `<command>`
- With coverage: `<command>`
- A single test or subset: `<command>`

## Coverage Targets

Targets are a floor, not a ceiling. Changes that drop measured coverage below a floor require explicit, documented justification.

| Scope | Metric | Floor |
| --- | --- | --- |
| Repository default | Line / statement | `<e.g. 80%>` |
| Critical modules | Branch | `<e.g. 90%>` |
| Security-sensitive code | Line + branch | `<e.g. 95%>` |

New or modified code should meet the floor on its own, not lean on untouched legacy code.

## Continuous Coverage Evaluation

Coverage is measured on every change (locally and, where possible, in CI). Record the latest figures here so trends stay visible.

| Date | Overall coverage | Notes |
| --- | --- | --- |
| `<YYYY-MM-DD>` | `<e.g. 0%>` | Baseline |

A downward trend is a signal to investigate, even when the number stays above the floor.

## Coverage Gap Log

Track known untested behavior here. A percentage alone hides gaps; this log makes them explicit. Each entry should have a follow-up item in `TODO.md` under Testing.

| Gap ID | Area / behavior | Risk | Related requirement | Status | TODO ref |
| --- | --- | --- | --- | --- | --- |
| GAP-001 | `<untested behavior>` | `<low / med / high>` | `<FR-xxx or n/a>` | Open | `<link>` |

## Requirement Coverage

For product-facing repositories, every requirement ID should map to at least one test. The authoritative mapping lives in `docs/REQUIREMENTS_TRACEABILITY.md`. Requirements with no verifying test are gaps and should appear in the gap log above.
