# TODO

## Features

- [x] Add retroactive version analysis mechanism.
- [x] Standardize the Eric's Engineering Constitution adoption badge across bootstrapped repositories.
- [ ] Add language-specific guidance for common stacks.
- [x] Ship a GitHub Copilot custom agent ("Solon") at `.github/agents/solon.agent.md`, install it via bootstrap, and document it in `INTEGRATION.md`. Shipped in 1.25.0 for Visual Studio 2026 (v18.4+).
- [x] Harden the release process in `RELEASES.md` with an ordered "Cutting a Release" gate (bump every version reference, tag, publish GitHub Release). Shipped in 1.24.0 after the README banner and tags lagged across 1.21.0–1.23.0.
- [x] Add GoF design-pattern guidance (the two maxims plus a curated subset of patterns) to `ARCHITECTURE.md`, building on the SOLID + Dependency Rule design principles. Shipped in 1.23.0 alongside the design principles.
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
- [x] Ship a CI workflow template that runs `scripts/check_traceability.sh` as a gate for product-facing repositories (alongside the existing constitution version-check workflow), so traceability is enforced and not only available on demand. Implemented as `templates/.github/workflows/constitution-compliance.yml`, which also runs `scripts/check_compliance.sh`; installed by `scripts/bootstrap.sh` and covered by `scripts/test_bootstrap.sh`.

## Documentation

- [x] Add guidance for migrating existing project docs into the constitution structure.
- [x] Add language-specific override examples to `INTEGRATION.md`.
- [x] Add optional product requirements and MVP backlog templates for product-facing repositories.
- [x] Add an example of a fully populated `docs/OPERATIONS.md` for a deployed service. Added `examples/OPERATIONS.example.md` (a worked runbook for the fictional "Orders API" service), referenced from `OPERATIONS.md`, `DOCUMENTATION.md`, the blank template, and `README.md`.

## Nice-to-Have

- [ ] Add repository health dashboards.
- [x] Add CI/CD enforcement examples.
- [ ] Add AI-generated release planning guidance.