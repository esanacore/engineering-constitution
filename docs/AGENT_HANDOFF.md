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

### Session: 2026-11-14 (Release 1.55.0 prepared)

The session log (ADR-0007, pull requests 109 and 110) is merged. This push
prepares release 1.55.0: every version reference is bumped, the changelog
section is dated 2026-11-14 with an empty `Unreleased` above it, and
`docs/OTS_SOFTWARE.md` OTS-001 is re-reviewed (no open Dependabot alerts,
`npm audit` clean). The release also carries product discovery (ADR-0006)
and the demo-page overhaul. MINOR: nothing required, no default flipped.

Verified: `bash scripts/run_all_tests.sh` — 35 suites, zero failures;
`test_release_docs.sh` and `test_mcp_resources.sh` agree on 1.55.0; secrets
sweep clean. No tag was pushed and no GitHub Release published.

**Found while preparing it:** `v1.54.0` was never tagged (newest tag is
`v1.53.0`) and neither 1.53.0 nor 1.54.0 has a GitHub Release (newest is
`v1.52.0`). Adopter version gates have been comparing against 1.53.0.

Read first: `docs/sessions/2026-11-14-release-1-55-0.md`.

**Known blockers:** none.

## Next Steps

**Human action required:** steps 1, 2, 3, and 6.

1. [ ] **HUMAN** — Review and merge the 1.55.0 release pull request
   - **Why a human:** cutting a release is the maintainer's decision.
   - **Done when:** the pull request shows as merged with CI green.
2. [ ] **HUMAN** — Tag `v1.55.0` on the release merge commit and publish the
   GitHub Release _(blocked by step 1)_
   - **Why a human:** tags and published releases are the maintainer's.
   - **You need:** a local clone with `gh` signed in.
   - **Procedure:**
     1. `git checkout main && git pull`, then confirm `cat VERSION` prints
        `1.55.0` and note the merge commit: `git rev-parse HEAD`.
     2. `git tag -a v1.55.0 <that SHA> -m "v1.55.0"` and
        `git push origin v1.55.0`.
     3. `bash scripts/check_release_tag_alignment.sh .`
     4. Publish the Release from the `## 1.55.0` section of `CHANGELOG.md`,
        marked Latest.
   - **Done when:** `git show v1.55.0^{commit}:VERSION` prints `1.55.0` and
     the Release is marked Latest.
3. [ ] **HUMAN** — Decide whether to backfill the missing `v1.54.0` tag and
   the 1.53.0 and 1.54.0 GitHub Releases
   - **Why a human:** rewriting the public release history is the
     maintainer's call; 1.55.0 supersedes both either way.
   - **You need:** the 1.54.0 commit, `2a7ec3c` (`git show 2a7ec3c:VERSION`
     prints `1.54.0`). Tag it **before** `v1.55.0` if you backfill, so the
     newest tag is never the older version.
   - **Done when:** either `v1.54.0` exists on `2a7ec3c`, or you have
     decided to leave the gap and said so.
4. [ ] **AGENT** — Roll the fleet: `bump_adopters.sh --sha <release commit>`
   for all adopters, plus the session-log index, template, and
   instruction-file line in each _(blocked by step 2)_
5. [ ] **AUTOMATED** — `release-tag-alignment.yml` runs when the tag lands;
   watch for a red run.
6. [ ] **HUMAN** — Choose an authorized pilot participant, a real bounded
   request, and a product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** the participant and owner agree on a request and the
     permitted material.
7. [ ] **AGENT** _(suggestion)_ — Generate the session-log index from the
   entries so concurrent sessions stop conflicting on its top row.
