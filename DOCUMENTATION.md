# Documentation Standards

Documentation is part of the deliverable.

## Core Qualities

Documentation should be:

- Accurate
- Current
- Actionable
- Version controlled

Template placeholders do not count as finished documentation. A file copied
from the constitution must be customized or trimmed until it describes the real
repository instead of the example/template state.

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

`examples/OPERATIONS.example.md` is a fully worked runbook for a fictional
deployed service that fills in every one of these sections; use it as a model
when populating `docs/OPERATIONS.md`.

## Binary Assets and Images

Documentation often depends on images, diagrams, and other binary assets. Handle them so they render reliably and large originals stay out of the main history.

- **Images that must render inline in Markdown** (README screenshots, concept art, badges) are committed as **normal, web-optimized blobs** — reasonably small files committed directly to Git. Large originals, source files (for example, `.psd`, `.fig`, raw exports), and high-resolution masters belong in Git LFS.
- When a repository uses Git LFS, add a `.gitattributes` override so the inline, web-optimized copies are **excluded** from LFS and stored as normal blobs. Inline images stored in LFS can fail to render on hosted Git platforms because of private-repo or LFS-bandwidth limits.
- **Verify LFS objects actually uploaded** before declaring a push complete. A pushed LFS pointer with a missing object looks fine locally but breaks for everyone else. Check with `git lfs ls-files` and `git lfs fsck`, and confirm inline images render in the hosted view.

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

Also verify that any adopted template files no longer contain placeholder text
such as `<add here>`, example commands, or HTML comment prompts.

## README Expectations

README.md should explain:

- What the project does
- Its current features/capabilities — see "Current Capabilities" below
- Who it is for
- How to install or set it up
- How to run it
- How to test it
- How to contribute or work with AI agents
- Where to find architecture and roadmap information
- Its project structure and, for non-trivial systems, a component/flow diagram — see `ARCHITECTURE.md`'s "Visual Architecture" section

## Current Capabilities

Every project that grows over time needs a living, accurate answer to "what
can it do today?" This is a standing requirement, not a one-time README
section written at v0.1 and left to go stale — it decays fastest precisely
when a project is expanding fastest, which is exactly when it matters most to
a new contributor or an AI agent orienting itself.

- README.md must carry a current features/capabilities list. Update it in
  the **same change** that adds, changes, or removes user-facing
  functionality — not deferred to a separate "documentation pass" that may
  never happen.
- This applies to any adopting repository, not only product-facing ones:
  internal tools, libraries, and CLIs all accumulate capability over time and
  all need this answer kept current.
- `TESTING.md`'s "CI Enforcement" section describes `check_doc_freshness.sh`,
  a blunt tripwire that flags a pull request changing source files without
  touching README.md/CHANGELOG.md. It can only verify the file was *touched*,
  never that the content is actually accurate — treat it as a backstop for
  the mechanical case, never as the standard itself.

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

### Requirement ID Grammars Must Not Collide

When a repository layers requirement namespaces — for example a product layer (`BB-FR-001`) on top of a system layer (`FR-001`) — the prefixes must be chosen so that one ID can never appear as a substring of another. Otherwise traceability tooling that matches IDs by pattern can satisfy a check for a missing system requirement with an unrelated product requirement that happens to share a number.

- Prefer fully distinct prefixes that cannot be substrings of each other.
- When tooling matches IDs by regular expression, anchor the matcher on both sides (require a left boundary that is not `-`), so `FR-001` does not match inside `BB-FR-001`.
- Never reuse a number across layers in a way that depends on the surrounding text to disambiguate.

Governance tooling that consumes these IDs must itself be correct and tested; see `TESTING.md`.

## Architecture Decision Records

Major decisions are recorded as Architecture Decision Records in `docs/adr/` using the ADR template (`templates/ADR.md`). Beyond context, decision, consequences, and alternatives, each ADR captures:

- **Status lifecycle**: `Proposed → Accepted → Superseded` (or `Deprecated`). A `Proposed` ADR is drafted but not in force; an `Accepted` ADR is binding; a `Superseded` ADR has been replaced by a newer one; a `Deprecated` ADR no longer applies and is not directly replaced.
- **Relationships**: `extends` (builds on another ADR without replacing it), `supersedes` (replaces another ADR — set that ADR's status to `Superseded`), and `related`. This keeps the decision history navigable instead of expressed ad hoc.
- **Promotion criteria**: while an ADR is `Proposed`, it lists the concrete evidence, reviews, or outcomes required to move it to `Accepted`, and who gates the transition. The criteria are removed or marked met once the ADR is `Accepted`.

Maintain an ADR index so decisions and their provenance are discoverable.
