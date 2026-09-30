<!-- Keep the summary short; the diff is the record. Delete lines that do not apply. -->

## Summary

<!-- What changed and why, in two or three sentences. -->

## Workflow

- [ ] Full workflow (`AI_WORKFLOW.md`, Required Workflow)
- [ ] Trivial change, fast path (`AI_WORKFLOW.md`, "Proportionate Workflow") — say why it qualifies:

## Completion Checklist

- [ ] The requested change is implemented.
- [ ] Tests added or updated; `bash scripts/run_all_tests.sh` passes locally.
- [ ] `scripts/test_checker_contract.sh` passes if a checker was added or changed.
- [ ] Templates updated when a standard changed; the sample project updated when templates changed.
- [ ] Documentation updated: README contents and tree, TESTING.md checker list, wiki.
- [ ] `TODO.md` updated with discovered or completed work.
- [ ] `CHANGELOG.md` updated for user-facing changes.
- [ ] Security impact considered; `bash scripts/check_secrets.sh .` run.
- [ ] Release discipline evaluated (`RELEASES.md`): release cut, or reason stated below.
- [ ] `docs/MEMORY.md` proposals surfaced.
- [ ] Next Steps procedure below filled in, and copied into `docs/AGENT_HANDOFF.md`.
- [ ] `docs/SESSION_PLAN.md` cleared or archived.

## ADR

<!-- Does this change Required Files, the Required Workflow, the checker contract, or the compatibility policy? Then link the ADR. -->

## Release

<!-- Cut in this PR? Deferred, and why? Fleet bump planned? -->

## Next Steps

<!-- The Next Steps procedure (`AI_WORKFLOW.md`, "Next Steps Procedure"): numbered, in order, every step tagged **HUMAN**, **AGENT**, or **AUTOMATED**; human-only steps named in the line below and described (Why a human, Done when). Never empty. Check it with: gh pr view --json body -q .body | bash scripts/check_next_steps.sh --file - . -->

**Human action required:** step 1.

1. [ ] **HUMAN** — Review and merge this pull request
   - **Why a human:** merging is the maintainer's decision.
   - **Done when:** the pull request is merged and CI on the default branch is green.
