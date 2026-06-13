# Documentation Standards

Documentation is part of the deliverable.

## Core Qualities

Documentation should be:

- Accurate
- Current
- Actionable
- Version controlled

## Required Files

Every repository should include:

- README.md
- HELP.md
- CHANGELOG.md
- TODO.md
- SECURITY.md

## Strongly Encouraged

Repositories should also include:

- docs/SETUP.md
- docs/COMMAND_REFERENCE.md
- docs/TROUBLESHOOTING.md
- docs/ARCHITECTURE.md
- docs/adr/
- docs/AGENT_PROMPTS.md
- docs/AGENT_HANDOFF.md
- docs/PRODUCT_REQUIREMENTS.md for product-facing applications
- docs/REQUIREMENTS_TRACEABILITY.md for product-facing applications
- docs/TEST_PLAN.md for repositories with automated tests
- docs/MVP_BACKLOG.md for early-stage products or prototypes
- docs/OPERATIONS.md
- API documentation
- Wiki content when appropriate

## Operations Documentation Expectations

Projects with deployments, services, scheduled jobs, or operator workflows should maintain `docs/OPERATIONS.md`.

That document should cover:

- deployment or release procedure
- monitoring, metrics, and alert locations
- backup and restore expectations
- rollback guidance
- incident response notes

## Documentation Review Checklist

For each meaningful change, review whether updates are needed for:

- README.md
- CHANGELOG.md
- TODO.md
- Architecture documentation
- Product requirements
- Requirements traceability matrix
- Test plan and coverage records
- MVP or delivery backlog
- API documentation
- Deployment documentation
- Configuration documentation
- Troubleshooting guidance
- Wiki content

## README Expectations

README.md should explain:

- What the project does
- Who it is for
- How to install or set it up
- How to run it
- How to test it
- How to contribute or work with AI agents
- Where to find architecture and roadmap information

## CHANGELOG Expectations

CHANGELOG.md should capture user-facing changes using release categories:

- Added
- Changed
- Fixed
- Removed
- Security

## TODO Expectations

TODO.md is the living roadmap. It should reflect the best current understanding of remaining work.

## Product Requirements Expectations

Product-facing repositories should include `docs/PRODUCT_REQUIREMENTS.md` when implementation needs a clear contract between product intent and engineering work.

Product requirements should define:

- Functional requirements.
- Non-functional requirements.
- Requirement priority or level.
- Explicit non-goals.
- Acceptance criteria or validation expectations.

### Requirement Identifiers

Each requirement should carry a stable, unique identifier so it can be referenced from tests, commits, and the traceability matrix.

- Use a short, typed prefix and a zero-padded number, for example `FR-001` for functional requirements and `NFR-001` for non-functional requirements.
- Identifiers are stable: once assigned, an ID is never reused for a different requirement, even after the original is removed or superseded.
- Acceptance criteria for a requirement may carry sub-identifiers, for example `FR-001-AC-1`.

### Acceptance Criteria

Every `MUST` and `SHOULD` requirement should state explicit, verifiable acceptance criteria. Acceptance criteria describe the observable condition that confirms the requirement is met, written so that a test can check them.

## Requirements Traceability

Product-facing repositories should maintain `docs/REQUIREMENTS_TRACEABILITY.md`: a matrix that links each requirement to its evidence of completion.

The traceability matrix should map, for each requirement ID:

- The requirement description and level.
- Its acceptance criteria.
- The tests that verify it.
- Its current verification status (for example, Not Started, In Progress, Verified).

The matrix is a living document: update it in the same change that adds, modifies, or verifies a requirement. A requirement with no verifying test is a coverage gap and should be recorded in the `docs/TEST_PLAN.md` gap log and tracked in `TODO.md` under Testing.