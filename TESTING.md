# Testing Standards

Testing is required for sustainable software delivery.

## Core Expectations

- All new functionality should include automated tests.
- Bug fixes should include regression tests.
- Changed behavior should update existing tests.
- Broken tests should be repaired rather than bypassed.
- Coverage should not be reduced without explicit justification.

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

## Bug Fixes

Bug fixes should include regression tests that fail before the fix and pass after the fix whenever practical.

If a regression test is not practical, document why in the work summary or relevant project notes.

## Agent Reporting

Agents should report:

- Added tests
- Updated tests
- Test commands run
- Test failures and suspected causes
- Coverage concerns
- Any tests that could not be run

## Coverage Concerns

When coverage is weak, record follow-up work in TODO.md under Testing.
