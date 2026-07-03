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

## Governance Tooling Must Be Tested

Scripts that enforce the standards — coverage gates, requirements-traceability checkers, version gates, bootstrap and audit scripts — are themselves code, and a silent bug in them removes the protection they appear to provide. Treat governance tooling as production code:

- Give every reference checker or gate unit tests, including **negative cases** that prove it fails when it should.
- A traceability checker must have a test proving a missing system-layer ID (for example, `FR-007`) is still detected when a same-numbered ID from another layer (for example, `BB-FR-007`) is present. Pattern matchers that are not anchored on both sides pass this case incorrectly; see the ID-grammar guidance in `DOCUMENTATION.md`.
- A checker that can only pass is worse than no checker, because it advertises a guarantee it does not deliver.

The framework ships a reference traceability checker, `scripts/check_traceability.sh`, that adopters can run through the `constitution/` submodule. It confirms that every requirement ID declared in `docs/PRODUCT_REQUIREMENTS.md` has a non-empty verifying-test entry in `docs/REQUIREMENTS_TRACEABILITY.md`, matching IDs by exact cell value so a layered ID never satisfies a system-layer ID. Its own negative-case suite (`scripts/test_check_traceability.sh`) includes the `BB-FR-007` / `FR-007` collision case described above. Use it as the worked example of this standard.

The framework also ships `scripts/check_compliance.sh`, which verifies an adopting repository carries the required governance files, with negative-case tests (`scripts/test_check_compliance.sh`) proving it fails on a missing required file and honors its strict modes.

The framework also ships `scripts/check_source_summaries.sh`, which detects drift between dropped knowledge sources (`sources/raw/`) and their generated summaries (`sources/summaries/`); see `KNOWLEDGE_SOURCES.md`. Its negative-case tests (`scripts/test_check_source_summaries.sh`) prove a file with no manifest entry is reported `NEW` rather than silently passing, and that `record` refuses to mark a source processed until its summary has actually been written.