# Session: Add the Constitution Impact Report for adopters

- **Date:** 2026-11-16
- **Agent:** Claude Code
- **Branch / PR:** `claude/blissful-allen-ix6z3j`; no pull request opened (not requested)
- **Topics:** Constitution Impact Report, docs/CONSTITUTION_IMPACT.md, build_impact_report.sh, adopters, adoption snapshot, evidence, catches, what it cost, templates/docs, sample-project, consulting proof, impact:snapshot markers
- **Related:** `docs/sessions/2026-11-14-pitch-deck.md` (consulting positioning the report supports); `docs/sessions/2026-11-14-generated-session-index.md` (the generated-block precedent); ADR-0003 (warn-first rollout)

## Request

The maintainer asked for a new documentation feature for adopters: a document
that outlines "how the engineering-constitution supercharged this project",
"something along those lines". One message; the name, shape, and enforcement
were left open.

## Context

- No clarifying questions were asked; the request was clear enough to build a
  first version and the choices below are easy to revise in review.
- The framework had no record of its own effect on an adopter.
  `check_compliance.sh` says which files exist, the session log says what
  each session did, and nothing adds them up for a maintainer or stakeholder
  asking what the process buys.
- The maintainer's recorded positioning (`docs/MEMORY.md`) treats the
  constitution as proof of craft for consulting work, so a per-project
  record of results is also sales evidence. That raises the bar for honesty
  rather than lowering it: a report a skeptic does not believe is worth
  nothing.
- A new recommended-tier file broke two `--strict` adopters on the 1.55.0
  fleet bump (`docs/MEMORY.md`), which shaped the rollout choice.

## Decisions

All by the agent, on the maintainer's behalf, and open to revision.

- **Name it "Constitution Impact Report", at `docs/CONSTITUTION_IMPACT.md`.**
  "Supercharged" was kept out of the file name, title, and standard: the
  document has to survive a skeptical reader, and the claim is made by the
  evidence in it. Rejected: a marketing-style page, and folding it into the
  README or the demo page (different readers, different update rhythm).
- **Two halves: a generated Adoption Snapshot and hand-written sections.**
  The numbers come from `scripts/build_impact_report.sh`, between two marker
  comments, as `build_session_index.sh` does for the session index. The
  judgment (What Changed, Catches, What It Cost, Not Yet Adopted) is written
  by a person or agent and never touched by the script.
- **Four rules in `DOCUMENTATION.md`:** evidence or nothing, costs beside
  benefits, no reconstructed baseline, measured where it can be. A "What It
  Cost" section is mandatory in the template because a report with only wins
  reads as marketing.
- **Opt-in, with no enforcement.** Listed under "Strongly Encouraged"; in no
  `check_compliance.sh` tier; not installed by `bootstrap.sh`; no Required
  Workflow step; no instruction-file change. The first run of the script is
  the opt-in. This keeps every adopter's CI unchanged and means none of the
  ADR triggers in `DOCUMENTATION.md` applies, so no ADR was written.
  Rejected: the recommended tier (breaks `--strict` adopters) and a workflow
  step (an ADR, eleven instruction files, and a rule nobody has tried yet).
- **A meter, not a gate.** The script never fails because a number is low,
  reports a missing source as "not present" rather than zero, and has no
  `--check` mode: session and TODO counts move every session, so a staleness
  gate would fail constantly.
- **A rerun that changes only the date leaves the file alone**, so refreshing
  is free and does not create diff noise.
- **A shallow clone keeps the adoption date already recorded.** The date
  comes from git history, CI and remote agent sessions clone shallow, and
  without this a refresh there would replace a real date with "unknown".
- **The sample project's report is synthetic, snapshot included**, under an
  "Illustration only" banner, like its session summary. The skeleton's real
  numbers (5 of 9 required files, no workflows) would not show what a filled
  report looks like.
- **No release cut.** One MINOR-sized addition sits in `Unreleased`; tagging
  is not possible from a remote session, and piloting the report on a real
  adopter first may change the template.

## Discoveries

- `bootstrap.sh` copies `templates/docs/` files one by one, not by glob, so a
  new template there is not installed until a `copy_file` line is added.
- `check_compliance.sh` prints one `OK`/`WARN`/`MISSING` line per entry under
  `Required:`, `Recommended:`, and `Product-facing` headings, which is enough
  to count per-tier totals without touching the checker.
- Run against this repository, `check_compliance.sh` reports 8 of 9 required
  (no `constitution/` submodule, as `INTEGRATION.md` says it will).
- This session's own clone was shallow, which is how the adoption-date
  problem was noticed.
- `shellcheck` is not installed in the remote environment; the script was not
  linted with it.
- `scripts/test_*.sh` now numbers 37 suites.

## Outcome

- New: `templates/docs/CONSTITUTION_IMPACT.md`,
  `scripts/build_impact_report.sh`, `scripts/test_build_impact_report.sh`,
  `examples/sample-project/docs/CONSTITUTION_IMPACT.md`, this summary.
- Changed: `DOCUMENTATION.md` (Strongly Encouraged entry and a "Constitution
  Impact Report" section), `INTEGRATION.md` ("Showing What Adoption
  Changed"), `README.md`, `docs/COMMAND_REFERENCE.md`, `docs/TEST_PLAN.md`,
  the wiki (Home, Governance Checkers, Templates and Examples), `demo.html`,
  `CHANGELOG.md`, `TODO.md`, `docs/AGENT_HANDOFF.md`.
- Verified: the full declared suite (37 suites) and the self-governance
  checkers pass locally.
- An independent review of the diff (a fresh agent given the diff, not the
  conversation) found no loss of hand-written content but several wrong
  measurements. It finished after the first push, so the fixes are a second
  commit, with regression tests (the suite went from 14 to 18 cases):
  symlinked `docs/sessions` or workflow directories counted as empty; a real
  table row mentioning `<form>` was dropped as a placeholder; `**Verified**`,
  a marked status, or a trailing Notes column was not counted as verified; a
  test command containing `<` read "not declared"; headings and checkboxes
  inside code fences were counted; `--file` and `--constitution-dir` could
  point outside the root; impossible dates were accepted; the template told
  the writer to delete every comment, markers included.
- Review findings not acted on, recorded in `TODO.md`: the write is not
  atomic, a CRLF report gets LF snapshot lines, and a report with no final
  newline gains one. Left as is: a shallow clone trusts the adoption date
  already in the report, which is the intended behavior.
- Left out on purpose, all in `TODO.md`: a format checker for the evidence
  cells, a baseline captured at adoption, a writer skill, a fleet roll-up,
  and gate outcomes from the GitHub API.

## Open Questions

- Is "Constitution Impact Report" the name the maintainer wants, or should
  the title carry more of the original "supercharged" framing?
- Should the report become a recommended file once a pilot shows it earns
  its keep, with the deprecation window ADR-0003 asks for?
- Existing adopters have no recorded baseline, so their "Before" column will
  mostly read "not recorded". Is that acceptable, or is a best-effort
  baseline from git history worth building?
- Private adopters' numbers must stay out of this public repository; a fleet
  roll-up needs a home outside it.
