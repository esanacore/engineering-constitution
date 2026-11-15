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

### Session: 2026-11-14 (1.55.0 tagged, released, and rolled to the fleet)

`v1.55.0` is tagged on merge commit `111769c` and published as the Latest
GitHub Release. On the maintainer's decision the history gap was closed too:
`v1.54.0` is tagged on `2a7ec3c`, and Releases now exist for 1.53.0 and
1.54.0. `release-tag-alignment` passed on the new tag.

`bump_adopters.sh` opened a `constitution/bump-v1.55.0` pull request in all
18 adopters (18 bumped, 0 failed). Fourteen are green. The consulting pitch
deck (`pitch-deck.html`, PR #112) is merged; its summary is
`docs/sessions/2026-11-14-pitch-deck.md`.

**Known blockers:**

- 1.55.0 put `docs/sessions` in the recommended compliance tier, which fails
  any adopter running `check_compliance.sh --strict`. Two do
  (`patients-served`, `MultiplatformTestApp`); their bump branches now carry
  the session-log index and template, and the compliance gate passes.
- Remaining red checks on four bump pull requests are the adopters' own:
  `SSH_DeviceManager` (Python 3.8/3.9 missing from the Ubuntu 26.04 runner),
  `MultiplatformTestApp` (Gradle fails on the runner's JDK 25),
  `AI-Process-Engineer` (`Desktop CI / e2e`, also red on October pull
  requests), `patients-served` (`validate-docs` baseline drift, red on the
  merged 1.52.0 bump as well).

**Context hints:** `docs/sessions/2026-11-14-release-1-55-0.md` (release
decisions and the follow-up), `docs/sessions/2026-11-14-session-summaries.md`
(the feature and its two open design questions).

## Next Steps

**Human action required:** steps 1, 2, 3, and 4.

1. [ ] **HUMAN** — Review and merge the 18 `constitution/bump-v1.55.0` pull
   requests.
   - **Why a human:** merging into each adopter's default branch is the
     maintainer's decision.
   - **You need:** `gh pr list --search "constitution: bump to v1.55.0 user:esanacore"`
     lists them. Four have red checks unrelated to the pin (see Known
     blockers); decide per repository whether to merge past them.
   - **Done when:** every adopter's `constitution/` gitlink is `111769c`.
2. [ ] **HUMAN** — Decide whether `docs/sessions` stays in the recommended
   compliance tier, and whether session summaries need approval before they
   are committed, as `docs/MEMORY.md` does.
   - **Why a human:** both set policy for every adopter; the first already
     broke two strict-mode repositories on this bump.
   - **Done when:** the decision is stated; an agent records it in ADR-0007.
3. [ ] **HUMAN** — Walk the pitch deck; approve the voice or list edits, and
   give a consulting contact for the call to action if you want one.
   - **Why a human:** personal brand and public contact details are the
     author's.
   - **Done when:** the deck is approved as-is, or edits and a contact string
     are given.
4. [ ] **HUMAN** — Choose a pilot participant, a real bounded request, and a
   product decision owner for the discovery pilot.
   - **Why a human:** participation, business priorities, and data-sharing
     consent belong to the people who own them.
   - **Done when:** participant and owner agree on a request and the
     permitted material.
5. [ ] **AGENT** — Add the session-log index, template, and instruction-file
   line to the 16 adopters that do not have them yet _(blocked by step 2)_
6. [ ] **AGENT** — Confirm
   `https://esanacore.github.io/engineering-constitution/pitch-deck.html`
   loads from Pages.
7. [ ] **AGENT** _(suggestion)_ — Fix the adopter CI drift the bump exposed:
   Python 3.8/3.9 on `SSH_DeviceManager`, the JDK pin on
   `MultiplatformTestApp`.
8. [ ] **AGENT** _(suggestion)_ — Generate the session-log index from the
   entries instead of maintaining it by hand.
