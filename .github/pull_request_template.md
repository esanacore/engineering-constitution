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
- [ ] `docs/SESSION_PLAN.md` cleared or archived.

## ADR

<!-- Does this change Required Files, the Required Workflow, the checker contract, or the compatibility policy? Then link the ADR. -->

## Release

<!-- Cut in this PR? Deferred, and why? Fleet bump planned? -->
