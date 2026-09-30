# Session Plan

## Goals

Every push ends with a human-readable **Next Steps procedure**: an ordered
checklist where each step names who acts (`HUMAN`, `AGENT`, `AUTOMATED`), and
steps only a person can do (hardware setup, credentials, approvals, UI-only
settings) are called out and described well enough to follow cold. At least
one step is always present, even if it is only a suggestion.

## Approach

- `AI_WORKFLOW.md`: a "Next Steps Procedure" section defining the format; the
  Required Workflow's summary step and "Before Completing Work" require it.
  ADR-0005 records the Required Workflow change (ADR rule from 1.48.0).
- Where it lives: the end-of-push summary, the PR description (template
  section), and `docs/AGENT_HANDOFF.md` (template + this repo's own).
- `scripts/check_next_steps.sh` + `scripts/test_check_next_steps.sh`: verify
  a Markdown file's "Next Steps" section is a numbered checklist, every step
  tagged, every HUMAN step carrying "Why a human" and "Done when". Warn by
  default; `--strict` in this repo's CI; warn-mode step in the adopter
  compliance template (skips older pins).
- Instruction files (root, templates, sample project) carry the rule;
  `tests.yml` enforces it with `check_instruction_templates.sh --anchor`
  rather than changing the default anchors (that would be a breaking strict
  default for adopters — ADR-0003).

## Files expected to change

AI_WORKFLOW.md, docs/adr/0005-*.md, docs/adr/README.md,
docs/AGENT_HANDOFF.md, templates/docs/AGENT_HANDOFF.md,
.github/pull_request_template.md (+ template copy if any),
scripts/check_next_steps.sh, scripts/test_check_next_steps.sh,
.github/workflows/tests.yml, templates/.github/workflows/constitution-compliance.yml,
~40 instruction files, README.md, TESTING.md, wiki pages, docs/COMMAND_REFERENCE.md,
docs/SETUP.md, TODO.md, CHANGELOG.md.

## Risks

- Instruction-file edits across many formats (JSON, YAML comments, numbered lists).
- Checker too strict on prose-y handoffs; keep format minimal and documented.

## Resumption Notes

- Started 2026-09-30, after v1.50.0 merged (tag pending with Eric).
