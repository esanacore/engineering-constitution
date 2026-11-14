# Session: Adopt the engineering constitution

> Illustration only. This sample project is a skeleton, so the session below
> is synthetic: it shows the shape and level of detail of a real summary, not
> a record of work that happened.

- **Date:** 2026-01-12
- **Agent:** Example coding agent
- **Branch / PR:** `chore/adopt-constitution`, pull request 1
- **Topics:** bootstrap, constitution submodule, AGENTS.md, vendor instruction files, CLAUDE.md, Copilot, Cursor
- **Related:** `docs/adr/0001-record-architecture-decisions.md`

## Request

Bring the repository under Eric's Engineering Constitution before any feature
work starts. The maintainer asked for the smallest root listing that still
covers the three tools the team uses: Claude Code, GitHub Copilot, and Cursor.

## Context

- The repository was empty apart from `README.md` and `src/`.
- The maintainer had seen another project's root double after adoption and
  did not want that here.
- Asked whether the project is product-facing, the maintainer said "not
  yet": there are no users outside the team.

## Decisions

- **Install vendor files for three tools only** (maintainer's decision):
  `bootstrap.sh --agents=claude,copilot,cursor`. Rejected: `--agents=all`,
  which adds eleven files nobody on the team would read.
- **Defer the product-facing tier** (maintainer's decision): no
  `docs/PRODUCT_REQUIREMENTS.md` or `demo.html` until there is an outside
  user. Revisit when the first external consumer appears.
- **Pin the submodule to a release tag, not `main`** (agent's
  recommendation, accepted): the version gate compares against the latest
  tag, so a `main` pin would read as "ahead" on every check.

## Discoveries

- `bootstrap.sh` never overwrites an existing `README.md`; it writes the
  badge between `CONSTITUTION_START`/`CONSTITUTION_END` markers and leaves a
  merge copy of the template under `.constitution-bootstrap/templates/`.
- `check_compliance.sh` reports the product-facing files as warnings unless
  `--product` is passed, so deferring them does not fail CI.

## Outcome

Submodule added at `constitution/`, governance files installed, and
`check_compliance.sh .` reports no required gaps. No source code changed, so
no tests were added; the test plan still carries its placeholder command.

## Open Questions

- Which command is the project's "Full suite"? `docs/TEST_PLAN.md` cannot be
  finished until the first test exists.
