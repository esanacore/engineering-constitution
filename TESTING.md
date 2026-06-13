# Testing Standards

Testing is required for sustainable software delivery.

## Core Expectations

- All new functionality should include automated tests.
- Bug fixes should include regression tests.
- Changed behavior should update existing tests.
- Broken tests should be repaired rather than bypassed.
- Coverage should not be reduced without explicit justification.
- Every requirement with a stable ID should map to at least one test (see `DOCUMENTATION.md` and `docs/REQUIREMENTS_TRACEABILITY.md`).

## Preferred Testing Pyramid

Use a balanced testing strategy:

1. Unit tests for isolated behavior.
2. Integration tests for interactions across modules, services, or storage.
3. End-to-end tests for critical user workflows.

## Testability

Testability is a design requirement.

Prefer designs that:

- Separate pure logic from side effects.
- Make dependencies explicit.
- Support deterministic tests.
- Avoid hidden global state.
- Provide stable interfaces for verification.

## Coverage Targets

Each repository should declare explicit coverage targets in `docs/TEST_PLAN.md` rather than relying on an implicit goal. Targets should be expressed as concrete, measurable thresholds, for example:

- A line or statement coverage floor (for example, 80 percent).
- A branch coverage floor for critical modules.
- A requirement may state that security-critical or high-risk modules carry a higher floor than the repository-wide default.

New or modified code should meet the declared floor on its own rather than relying on untouched legacy code to keep the aggregate number up.

## Continuous Coverage Evaluation

Coverage should be evaluated continuously, not measured once. On every change, coverage should be measured locally and, where possible, enforced in CI, with the latest figures recorded in `docs/TEST_PLAN.md`.

- Treat a downward trend as a signal to investigate, even when the number stays above the floor.
- A change that drops measured coverage below a declared floor requires explicit, documented justification.

## Coverage Gap Analysis

An aggregate coverage percentage hides which behavior is untested. Coverage gaps should be analyzed and recorded rather than left implicit behind a single number.

- Record known untested behavior in the `docs/TEST_PLAN.md` gap log, with a risk level and a follow-up item in `TODO.md` under Testing.
- For product-facing repositories, any requirement ID with no verifying test is a coverage gap; reconcile gaps against `docs/REQUIREMENTS_TRACEABILITY.md`.