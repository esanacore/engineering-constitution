# TODO

## Features

- [x] Add retroactive version analysis mechanism.
- [x] Standardize the Eric's Engineering Constitution adoption badge across bootstrapped repositories.
- [ ] Add language-specific guidance for common stacks.
- [x] Add DevOps and infrastructure standards.
- [x] Add Goose / Goosetown agent integration (`.goosehints` + MCP extension guidance).
- [x] Add automated constitution version enforcement (Dependabot auto-PRs, CI version gate, `audit_adopters.sh`).

## Technical Debt

- [ ] Define a repeatable release process for framework updates (now includes the `vX.Y.Z` Git tag step in `RELEASES.md`).
- [ ] Cut the first `vX.Y.Z` release tag on `main`. The version-gate/audit machinery is built but no `v*` tag exists yet, so adopters' `constitution-version-check` gate still skips instead of enforcing. Tagging a release (for example `v1.16.0`) transitions it to actively passing/failing.

## Refactoring

- [ ] Consider splitting project bootstrap behavior into smaller reusable scripts if it grows.

## Testing

- [x] Add automated tests for `scripts/bootstrap.sh`.
- [x] Add continuous coverage evaluation and gap-analysis guidance to `TESTING.md`.
- [x] Add compliance checks that verify required files exist in integrated repositories. Implemented as `scripts/check_compliance.sh` with `scripts/test_check_compliance.sh` (required / recommended / product-facing tiers, `--strict` and `--product` modes).
- [x] Add an automated check that every requirement ID has a verifying test entry in the traceability matrix. Ship it with negative-case unit tests (per the "Governance Tooling Must Be Tested" standard in `TESTING.md`), including the substring-collision case where a layered ID like `BB-FR-007` must not satisfy a check for system `FR-007`. Implemented as `scripts/check_traceability.sh` with `scripts/test_check_traceability.sh`.
- [ ] Ship a CI workflow template that runs `scripts/check_traceability.sh` as a gate for product-facing repositories (alongside the existing constitution version-check workflow), so traceability is enforced and not only available on demand.

## Documentation

- [x] Add guidance for migrating existing project docs into the constitution structure.
- [x] Add language-specific override examples to `INTEGRATION.md`.
- [x] Add optional product requirements and MVP backlog templates for product-facing repositories.
- [ ] Add an example of a fully populated `docs/OPERATIONS.md` for a deployed service.

## Nice-to-Have

- [ ] Add repository health dashboards.
- [x] Add CI/CD enforcement examples.
- [ ] Add AI-generated release planning guidance.