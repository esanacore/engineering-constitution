# Constitution Impact: <project name>

<!--
What adopting Eric's Engineering Constitution has done for this project, shown
with evidence. Create and refresh this file with:

    bash constitution/scripts/build_impact_report.sh .

The script writes only the Adoption Snapshot block. Everything else is written
by a person or an agent, and every claim cites evidence a reader can open: a
commit, a pull request, a CI run, a session summary, or a file path. A claim
with no evidence is left out. Costs are recorded as carefully as benefits; a
report with no costs reads as marketing and proves nothing.

Never record secrets, credentials, personal data, or customer data here: the
file is committed, and in a public repository it is published (constitution
DOCUMENTATION.md, "Constitution Impact Report"). Delete every comment once the
section under it is filled in, except the two impact:snapshot markers: the
script needs them to find the block it rewrites. Write "None yet." under a
heading rather than deleting it.
-->

## Summary

<!-- Two or three sentences a stakeholder can read cold: what the project is,
when it adopted the constitution, and the one or two changes that mattered
most. Plain statements, each backed by a row below. -->

<summary>

## Adoption Snapshot

<!-- impact:snapshot:start -->
_Not generated yet. Run `bash constitution/scripts/build_impact_report.sh .`._
<!-- impact:snapshot:end -->

## What Changed

<!-- One row per practice the constitution introduced or tightened here.
"Before" is the state at adoption (say "not recorded" when nobody wrote it
down; do not reconstruct a flattering baseline). "Evidence" is something the
reader can open. Delete the placeholder row once real rows exist. -->

| Practice | Before | Now | Evidence |
| --- | --- | --- | --- |
| `<practice, for example "secrets sweep before every push">` | `<state at adoption>` | `<state today>` | `<commit, pull request, CI run, or file>` |

## Catches

<!-- Problems a constitution gate, checker, or workflow step stopped before
they shipped, newest first. Add a row when it happens, not from memory at the
end of the quarter. "Caught by" names the checker, workflow, or workflow step.
Delete the placeholder row once real rows exist. -->

| Date | What was caught | Caught by | Evidence |
| --- | --- | --- | --- |
| `<YYYY-MM-DD>` | `<the defect, leak, or drift>` | `<checker or workflow step>` | `<pull request or CI run>` |

## What It Cost

<!-- The honest other side: false positives, CI minutes, time spent on a rule
that did not fit, session-start reading cost, a gate that blocked a release.
One bullet each, with evidence where there is any, and what was done about it
(an override, a TODO item, an upstream issue). -->

- <cost>

## Not Yet Adopted

<!-- Parts of the constitution this project has not taken up, or has opted out
of, and why. The snapshot's compliance row shows the missing files; this
section gives the reasons and links the TODO.md items. -->

- <gap>

## Keeping This Current

- Rerun `bash constitution/scripts/build_impact_report.sh .` after each
  constitution version bump and before each release of this project.
- Add a **Catches** row in the same pull request in which a gate caught
  something.
- Review **What Changed**, **What It Cost**, and **Not Yet Adopted** whenever
  the snapshot is refreshed.
