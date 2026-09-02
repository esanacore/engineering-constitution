# The Harness Is the Thing

- **Source:** sources/raw/articles/the-harness-is-the-thing.md
  (captured from https://scott-fryxell.github.io/blog/the-harness-is-the-thing/, published 2026-08-25)
- **Author:** Scott Fryxell
- **Processed:** 2026-09-01

## Why This Matters

Fryxell's central claim — "the harness is the thing; the fulcrum from which my
expectations meet the LLM's capabilities" — is this framework's thesis stated
from a solo practitioner's angle: the durable asset in AI-assisted development
is the organizing system around the models (shared instructions, skills,
plans, auditable outputs), not the models themselves, which he treats as
commodified and swappable. He arrives at several structures this constitution
already ships, and at a few it doesn't, so the article works both as outside
validation and as a source of concrete leads.

## Key Takeaways

- **One harness, many tools.** He runs three TUIs (Cursor, Claude Code, Pi)
  against a single shared `AGENTS.md` + `skills/` set and reports "a unified
  experience… there is no magic sauce or special experience in Claude or
  Cursor that I need in order to be productive." Same bet as this framework's
  vendor-neutral `AGENTS.md`-first bootstrap — but he anchors the harness at a
  personal root directory spanning all his repos (`brayness/` with `work/`
  underneath), where the constitution anchors per-repository via submodule.
  His mechanism for the spanning layer is a shell wrapper that walks parent
  directories and auto-loads the nearest `AGENTS.md` into the agent's system
  prompt.
- **Isolated roles in a planning arc.** Explore → planner → worker → critic →
  promoter, because "a single prompt that plans, executes, and critiques
  itself confuses its own objectives, so each role gets isolated instead."
  The plan is formalized as an explicit DAG task list; the worker implements
  it one node at a time; the critic "simplify[ies] and question[s] what was
  implemented" and routinely sends work back to the worker phase.
- **A "promoter" closes every job.** His explicit final role exists because "a
  job is not complete until you've properly communicated it to others." The
  constitution's CHANGELOG/README/wiki/release requirements are the same idea,
  institutionalized.
- **Cost-tiered model routing.** Cheap models (deepseek-v4-flash) for
  maintenance and routine execution; frontier models reserved for
  exploration, planning, critique, and communication. He cites "prewalk":
  frontier does the planning phase and the first task, "then hands off once
  the pattern is set." Net effect: frontier usage down 75% with no reported
  quality loss.
- **Scripts over repeated inference.** A capability the LLM figured out once
  gets frozen into a script "so it can run a billion times without burning
  tokens." Strongly matches this repo's deterministic `check_*.sh` governance
  checkers and skills.
- **Auditability as a standing rule.** Agents are "instructed to keep things
  inside the artifacts/ directory" so outputs stay inspectable — the same
  instinct behind `docs/SESSION_PLAN.md`, `docs/AGENT_HANDOFF.md`, and the
  bootstrap adoption report.
- **Instruction weight is a real cost.** "Initially I was too prescriptive
  with my skills; I am learning to lighten the specificity… there is a line
  past which you are burning tokens mansplaining to clankers." He also
  concedes needing "a more empirical approach to confirming the impact of
  changes" to instructions. This is the article's sharpest tension with the
  constitution, whose required reading order spans a dozen documents per
  session: prescriptiveness has a per-session token price and an
  instruction-following price, and neither is currently measured here.
- **Model diversification as resilience.** Regulatory disruption pushed him to
  multi-vendor overnight; the harness made that switch a non-event. Supports
  keeping every constitution mechanism vendor-neutral (the `--agents` opt-in
  already points this way).

## Where It Could Apply

- `AI_WORKFLOW.md` — the linear 28-step workflow contains planner
  (`docs/SESSION_PLAN.md`) and promoter (docs/changelog/release steps)
  equivalents but no isolated **critic** pass: implementation and
  self-review happen inside one prompt, which is exactly what Fryxell warns
  confuses objectives. TODO.md already carries an "automated Self-Critique
  pre-flight" idea (`scripts/ai_preflight.sh`); this source strengthens the
  case and suggests the cheaper form first — a workflow step directing a
  *fresh* agent/context to critique the diff before completion.
- `AI_WORKFLOW.md` or `INTEGRATION.md` — optional guidance on cost-tiered
  model routing (frontier for planning/critique/communication, cheaper models
  for well-patterned execution), kept advisory since the constitution is
  model-agnostic.
- `INTEGRATION.md` — document the parent-directory `AGENTS.md` auto-load
  wrapper as a pattern for people running many adopting repos under one
  workspace root; it composes cleanly with the per-repo submodule model.
- Framework-wide (tension to weigh, not a doc edit yet) — an
  instruction-weight audit: measure what the required reading order costs per
  session in tokens and attention, and consider a condensed agent digest of
  the constitution documents for session start, with the full documents as
  reference. Any such change should follow his other lesson and be validated
  empirically rather than by taste.
