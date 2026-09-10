# Session Plan

_No active session. This file is written at the start of a session with its
goals, approach, expected file changes, and risks (see `AI_WORKFLOW.md`), and
cleared once the outcomes are captured in commit messages, `CHANGELOG.md`, or
`docs/AGENT_HANDOFF.md`._

## Last completed

Instruction-weight audit — the final "Harness Is the Thing" promotion lead.
Shipped `scripts/measure_instruction_weight.sh` (+9-case test suite, README
and wiki catalogue entries). Findings recorded in `TODO.md`: rule docs are
lean (~16.5k est. tokens); the weight is in unbounded CHANGELOG (~20.5k) and
TODO (~8k). Digest rejected on the data; a reading-order scoping proposal is
queued in `TODO.md` awaiting Eric's decision. All 20 test suites green.
