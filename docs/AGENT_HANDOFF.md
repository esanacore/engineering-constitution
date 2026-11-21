# Agent Handoff

Session-to-session handoff for work on the framework itself. The session plan
(`docs/SESSION_PLAN.md`) captures intent before work; this file captures state
after work. Durable learnings go to `docs/MEMORY.md` on the maintainer's
approval, not here. The lasting record of each session — what was asked,
decided, and learned — is its summary in `docs/sessions/`.

## How to Handoff

At the end of every push, replace the entry below (only the latest handoff is
kept; history lives in `docs/sessions/`, `CHANGELOG.md`, and the commit log):

1. **Current Status**: what was achieved.
2. **Next Steps**: the Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps
   Procedure") — the same one that ends the summary and the pull request
   description. `scripts/check_next_steps.sh --strict .` runs in CI.
3. **Known Blockers**: what was encountered.
4. **Context Hints**: files or decisions the next agent should read.

## Latest Handoff

### Session: 2026-11-20 (Drawings standard, ADR-0008)

On `feat/drawings-and-plate`: every adopter is asked for a patent-style
plate in `docs/drawings/` (numbered parts, a key, a line saying it is not a
patent), and every adopter with a physical component for a dimensioned
drawing set generated from its CAD. Shipped with it: `DOCUMENTATION.md`
"Drawings", ADR-0008, `scripts/check_drawings.sh` (14 test cases), the
scaffold in `templates/docs/drawings/`, `docs/drawings` in the recommended
compliance tier, the rule in every instruction file, and the framework's own
plate in `README.md` and `demo.html`. Summary:
`docs/sessions/2026-11-20-drawings-and-the-plate.md`.

**Known blockers:** none. The 1.56.0 follow-ups from the previous handoff
(tag, fleet bump, superseded 1.55.0 pull requests, pitch deck review, pilot)
are not touched by this branch; check their state before releasing.

**Context hints:** the drawings are a documentation-workflow expectation by
the maintainer's decision: warn-only, recommended tier, no plan to make them
required. The framework ships no drawing-set generator. Adopters never
provide information back to the framework or publicly, so nothing from an
adopter belongs in this repository.

## Next Steps

**Human action required:** step 1.

1. [ ] **HUMAN** — Review the pull request and merge it when CI is green.
   - **Why a human:** a new standard for every adopter is the maintainer's
     to approve.
   - **Done when:** the pull request is merged, or changes are requested.
2. [ ] **AGENT** — Cut the release that carries this (the next MINOR after
   the latest tag; check the tag first) _(blocked by step 1)_
3. [ ] **AGENT** — On the fleet bump, draw a plate for each adopter and add
   the instruction-file line; hardware adopters also link their drawing set
   _(blocked by step 2)_
4. [ ] **AUTOMATED** — `tests.yml` runs the suite and the self-governance
   checks, including `check_drawings.sh --strict`, on the pull request.
