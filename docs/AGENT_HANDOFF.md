# Agent Handoff

Session-to-session handoff for work on the framework itself. The session plan
(`docs/SESSION_PLAN.md`) captures intent before work; this file captures state
after work. Durable learnings go to `docs/MEMORY.md` on the maintainer's
approval, not here.

## How to Handoff

At the end of every push, replace the entry below (only the latest handoff is
kept; history lives in `CHANGELOG.md` and the commit log):

1. **Current Status**: what was achieved.
2. **Next Steps**: the Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps
   Procedure") — the same one that ends the summary and the pull request
   description. `scripts/check_next_steps.sh --strict .` runs in CI.
3. **Known Blockers**: what was encountered.
4. **Context Hints**: files or decisions the next agent should read.

## Latest Handoff

### Session: 2026-10-11 (Dependabot cleanup)

- **Accomplishments**: the three Dependabot branches resolved. #87
  (`@modelcontextprotocol/sdk` 1.29.0 -> 1.31.0) and #88 (`proxy-addr`
  2.0.7 -> 2.0.8, CVE-2026-90711) merged; #65 (`actions/checkout` 4.3.0 ->
  7.0.1) closed because it moved only the 4 workflows under
  `.github/workflows/` and left the 8 adopter templates on the old pin.
  This branch replaces it: all 12 pinned workflows move to
  `3d3c42e5aac5ba805825da76410c181273ba90b1`, verified against the upstream
  `v7.0.1` tag with `git ls-remote` (the session's GitHub API access is
  scoped to this repository, so the tag could not be read through the API).
  OTS-104 and OTS-001 re-reviewed; the #65 `TODO.md` item closed.
- **Verification Run**: `bash scripts/run_all_tests.sh --quiet` (31 suites
  green), every `tests.yml` self-governance step locally, all 12 workflows
  parsed as YAML. No isolated critique agent for a mechanical SHA
  replacement: the final diff was re-read line by line and the pin verified
  against upstream, which is the check that matters here.
- **Known Blockers**: v1.54.0 untagged, v1.53.0 unpublished; three
  `Unreleased` entries now wait on the local-session handoff.
- **Context Hints**: `AGENTS.md` already lists `INTEGRATION.md` as a
  conditional read ("when the task touches adopter integration, bootstrap,
  or IDE/multi-tool setup"); the meter counts it whole only because that
  qualifier is not one it recognizes. Teaching
  `measure_instruction_weight.sh` an "on demand" qualifier (measured as
  0 in the as-instructed total, listed separately) resolves the
  `INTEGRATION.md` item without touching the reading order.

#### Next Steps

**Human action required:** steps 1, 3, and 4.

1. [ ] **HUMAN** — Review and merge the `actions/checkout` pin bump pull request
   - **Why a human:** it moves a SHA pin that every adopter inherits (`SECURITY.md`, CI/CD supply chain); the review is the control.
   - **You need:** the pin `3d3c42e5aac5ba805825da76410c181273ba90b1`; confirm it with `git ls-remote https://github.com/actions/checkout.git refs/tags/v7.0.1` if you want a second pair of eyes.
   - **Done when:** the PR is merged and CI on `main` is green.
2. [ ] **AUTOMATED** — `tests.yml` runs on the PR with the new pin, which is itself the first exercise of v7.0.1 here; watch for a red run.
3. [ ] **HUMAN** — Run the local-session handoff for 1.54.0 (tag `v1.54.0`, publish the v1.53.0 and v1.54.0 releases, bump the fleet with the Stop hook rollout)
   - **Why a human:** remote sessions cannot push tags, publish releases, or reach adopter repositories.
   - **You need:** the `local-session-handoff-1.54.0.md` prompt from the cloud session, a local clone, `gh` signed in.
   - **Done when:** `gh release list` shows v1.54.0 as Latest and every adopter's `constitution-version.yml` is green.
4. [ ] **HUMAN** — Decide whether 1.55.0 is cut right after step 3 (three `Unreleased` entries are waiting, one of them a security pin) and whether the proposed memory entry (no regex interval expressions in shipped awk) is recorded _(blocked by step 3)_
   - **Why a human:** release cadence and `docs/MEMORY.md` entries are the maintainer's call.
   - **Done when:** either a release PR is open or the decision is recorded in `TODO.md`; the memory entry is recorded or declined.
5. [ ] **AGENT** — Audit the fleet's READMEs with `check_readme.sh` and open per-adopter PRs for the findings (`TODO.md` → Documentation) _(blocked by step 3)_.
6. [ ] **AGENT** _(suggestion)_ — Teach the meter an "on demand" qualifier so `INTEGRATION.md`'s conditional read is reported as such (`TODO.md` → Features), closing the last `HEAVY` row without changing the reading order.
