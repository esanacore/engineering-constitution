# Agent Handoff

Session-to-session handoff for work on the framework itself. The session plan
(`docs/SESSION_PLAN.md`) captures intent before work; this file captures state
after work. Durable learnings go to `docs/MEMORY.md` on the maintainer's
approval, not here.

## How to Handoff

At the end of a session, replace the entry below (only the latest handoff is
kept; history lives in `CHANGELOG.md` and the commit log):

1. **Current Status**: what was achieved.
2. **Next Steps**: what the next agent should do first.
3. **Known Blockers**: what was encountered.
4. **Context Hints**: files or decisions the next agent should read.

## Latest Handoff

### Session: 2026-09-16

- **Accomplishments**: the approved improvement batch (see `CHANGELOG.md`
  `Unreleased` / 1.48.0): own tests in CI, self-compliance docs, instruction
  template and skills checkers, checker contract meta-test with CI
  annotations, MCP server drift fix, ADR rule plus ADR-0003/0004, agent-facing
  security, CI supply chain, proportionate workflow, PR/CODEOWNERS templates,
  commit conventions, product-facing definition, postmortem template, data
  classification, OTS license column, framework SemVer semantics, fleet bump
  script.
- **Pending Work**: tag `v1.48.0` and publish the GitHub Release after merge
  (maintainer); run `scripts/bump_adopters.sh` for the fleet.
- **Verification Run**: `bash scripts/run_all_tests.sh` (all suites green) and
  every self-governance checker in `--strict` mode.
- **Instructions for Next Agent**: read `TODO.md`'s open items; the
  `bump_adopters.sh` GitHub pull-request path is untested from CI (GAP-001 in
  `docs/TEST_PLAN.md`), so verify it by hand on the first real rollout.
