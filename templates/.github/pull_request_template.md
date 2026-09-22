<!-- Keep the summary short; the diff is the record. Delete lines that do not apply. -->

## Summary

<!-- What changed and why, in two or three sentences. -->

## Workflow

- [ ] Full workflow (`constitution/AI_WORKFLOW.md`, Required Workflow)
- [ ] Trivial change, fast path (`constitution/AI_WORKFLOW.md`, "Proportionate Workflow") — say why it qualifies:

## Completion Checklist

<!-- Mirrors the Completion Checklist in AGENTS.md. Check what was done; strike what does not apply and say why. -->

- [ ] The requested change is implemented.
- [ ] Tests added or updated; the declared full suite passes locally.
- [ ] Coverage evaluated against `docs/TEST_PLAN.md`; gaps recorded.
- [ ] Requirements traceability updated (product-facing repositories).
- [ ] `docs/OTS_SOFTWARE.md` updated if dependencies changed.
- [ ] `docs/ENV_VARS.md` updated if environment variables changed.
- [ ] Documentation updated, including README's current capabilities and the wiki.
- [ ] `TODO.md` updated with discovered or completed work.
- [ ] `CHANGELOG.md` updated for user-facing changes.
- [ ] Security impact considered; secrets sweep (`constitution/scripts/check_secrets.sh`) run.
- [ ] Release discipline evaluated (`constitution/RELEASES.md`): release cut, or reason stated below.
- [ ] `docs/MEMORY.md` proposals surfaced to the user (if any).
- [ ] `docs/SESSION_PLAN.md` cleared or archived.

## Security

<!-- Auth, input validation, secrets, dependencies, data classification, logging. "None" is an answer if it is true. -->

## Release

<!-- Cut in this PR? Deferred, and why? -->
