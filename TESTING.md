# Testing Standards

Testing is required for sustainable software delivery.

## Core Expectations

- All new functionality should include automated tests.
- Bug fixes should include regression tests.
- Changed behavior should update existing tests.
- Broken tests should be repaired rather than bypassed.
- Coverage should not be reduced without explicit justification.
- Every requirement with a stable ID should map to at least one test (see `DOCUMENTATION.md` and `docs/REQUIREMENTS_TRACEABILITY.md`).

## Preferred Testing Pyramid

Use a balanced testing strategy:

1. Unit tests for isolated behavior.
2. Integration tests for interactions across modules, services, or storage.
3. End-to-end tests for critical user workflows.

## Testability

Testability is a design requirement.

Prefer designs that:

- Separate pure logic from side effects.
- Make dependencies explicit.
- Support deterministic tests.
- Avoid hidden global state.
- Provide stable interfaces for verification.

## Coverage Targets

Each repository should declare explicit coverage targets in `docs/TEST_PLAN.md` rather than relying on an implicit goal. Targets should be expressed as concrete, measurable thresholds, for example:

- A line or statement coverage floor (for example, 80 percent).
- A branch coverage floor for critical modules.
- A requirement may state that security-critical or high-risk modules carry a higher floor than the repository-wide default.

New or modified code should meet the declared floor on its own rather than relying on untouched legacy code to keep the aggregate number up.

## Continuous Coverage Evaluation

Coverage should be evaluated continuously, not measured once. On every change, coverage should be measured locally and, where possible, enforced in CI, with the latest figures recorded in `docs/TEST_PLAN.md`.

- Treat a downward trend as a signal to investigate, even when the number stays above the floor.
- A change that drops measured coverage below a declared floor requires explicit, documented justification.

## Coverage Gap Analysis

An aggregate coverage percentage hides which behavior is untested. Coverage gaps should be analyzed and recorded rather than left implicit behind a single number.

- Record known untested behavior in the `docs/TEST_PLAN.md` gap log, with a risk level and a follow-up item in `TODO.md` under Testing.
- For product-facing repositories, any requirement ID with no verifying test is a coverage gap; reconcile gaps against `docs/REQUIREMENTS_TRACEABILITY.md`.

## Governance Tooling Must Be Tested

Scripts that enforce the standards — coverage gates, requirements-traceability checkers, version gates, bootstrap and audit scripts — are themselves code, and a silent bug in them removes the protection they appear to provide. Treat governance tooling as production code:

- Give every reference checker or gate unit tests, including **negative cases** that prove it fails when it should.
- A traceability checker must have a test proving a missing system-layer ID (for example, `FR-007`) is still detected when a same-numbered ID from another layer (for example, `BB-FR-007`) is present. Pattern matchers that are not anchored on both sides pass this case incorrectly; see the ID-grammar guidance in `DOCUMENTATION.md`.
- A checker that can only pass is worse than no checker, because it advertises a guarantee it does not deliver.

The framework ships a reference traceability checker, `scripts/check_traceability.sh`, that adopters can run through the `constitution/` submodule. It confirms that every requirement ID declared in `docs/PRODUCT_REQUIREMENTS.md` has a non-empty verifying-test entry in `docs/REQUIREMENTS_TRACEABILITY.md`, matching IDs by exact cell value so a layered ID never satisfies a system-layer ID. Its own negative-case suite (`scripts/test_check_traceability.sh`) includes the `BB-FR-007` / `FR-007` collision case described above. Use it as the worked example of this standard.

The framework also ships `scripts/check_compliance.sh`, which verifies an adopting repository carries the required governance files, with negative-case tests (`scripts/test_check_compliance.sh`) proving it fails on a missing required file and honors its strict modes.

The framework also ships `scripts/check_source_summaries.sh`, which detects drift between dropped knowledge sources (`sources/raw/`) and their generated summaries (`sources/summaries/`); see `KNOWLEDGE_SOURCES.md`. Its negative-case tests (`scripts/test_check_source_summaries.sh`) prove a file with no manifest entry is reported `NEW` rather than silently passing, and that `record` refuses to mark a source processed until its summary has actually been written.

The framework also ships `scripts/check_version_alignment.sh`, which verifies that adopter-facing files do not drift away from the actual pinned `constitution/VERSION`. Its companion tests (`scripts/test_check_version_alignment.sh`) cover both a mismatched `CONSTITUTION_VERSION` file and a stale governance-document reference.

The framework also ships `scripts/run_declared_tests.sh`, which extracts the "Full suite" command an adopter declares in `docs/TEST_PLAN.md` and runs it, so "run all automated tests" is enforced in CI rather than left to an agent remembering to run them locally. Its negative-case tests (`scripts/test_run_declared_tests.sh`) prove a missing or still-placeholder command warns by default and fails under `--strict`, and — the more important guarantee — that a *declared* command which fails always fails this checker, with or without `--strict`. A checker that only enforces the "did you declare something" case and not the "does the declared thing actually pass" case would let broken tests through unnoticed.

The framework also ships `scripts/check_doc_freshness.sh`, a CI Enforcement tripwire (below) that flags a pull request changing source files without touching `README.md`/`CHANGELOG.md`. It is intentionally blunt, not smart change detection — pure refactors and test-only changes will sometimes trip it too, which is why it warns by default rather than failing. Its tests (`scripts/test_check_doc_freshness.sh`) prove both directions: a real doc-worthy change with no doc update is flagged, and changes limited to the ignore list (`docs/**`, lockfiles, etc.) are correctly *not* flagged even under `--strict` — a checker whose ignore list silently does nothing would just be noise with extra steps.

The framework also ships `scripts/check_secrets.sh`, which sweeps tracked and untracked-but-not-gitignored files for secrets that should never reach a remote: credential-shaped filenames (`.env`, `id_rsa`, `*.pem`, `credentials.json`, ...) and high-confidence content patterns (AWS access keys, GitHub/Slack tokens, PEM private key blocks). See `SECURITY.md`'s "Secrets Sweep" section. Its tests (`scripts/test_check_secrets.sh`) prove a real hit always fails regardless of `--strict` — for both a tracked secret-shaped file and an untracked one that was never even committed — that a placeholder file (`.env.example`) is not flagged, and that the separate `.gitignore`-coverage recommendation follows the warn-by-default, `--strict`-to-fail contract the other checkers use.

The framework also ships `scripts/check_ots_inventory.sh`, which cross-checks the runtime dependencies declared in a repository's root-level manifests (`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`) against the OTS software inventory (`docs/OTS_SOFTWARE.md`; see `DOCUMENTATION.md`'s "OTS Software Inventory" section), so a dependency added without documentation is flagged in the same change rather than found in a later audit. Manifest names are matched against the inventory's Name cells by exact value (case-insensitive), never by substring — its negative-case tests (`scripts/test_check_ots_inventory.sh`) prove an inventory row for `dunder-proto` cannot satisfy a check for the dependency `proto`, that unfilled `<placeholder>` rows never count as documentation, and that the declared scope is real: package.json `devDependencies`, Cargo.toml `[dev-dependencies]`, and go.mod `// indirect` requires are excluded, while inventory rows beyond the manifests (system-level OTS such as databases) are informational and never fail the check.

The framework also ships `scripts/check_env_vars.sh`, which cross-checks the environment variables declared in a repository's root-level manifests (`.env.example`, `.env.template`, `docker-compose.yml`) against the Environment & Configuration Contract (`docs/ENV_VARS.md`; see `DOCUMENTATION.md`'s "Environment & Configuration Contract" section), so a configuration variable added without documentation is flagged in the same change rather than found in a later deployment issue. Variables are matched against the contract's Variable cells by exact value. Negative-case tests (`scripts/test_check_env_vars.sh`) verify that missing variables fail the check in strict mode, and that unfilled `<placeholder>` rows do not satisfy the check.

The framework also ships `scripts/check_architecture.sh`, the one checker that verifies code *structure* rather than the presence of a file: a repository can carry every governance document and still have its domain layer importing its web framework. When a project declares its layers in `docs/ARCHITECTURE.md` under a `Layer Boundaries` heading (see `ARCHITECTURE.md`'s "Enforcing the Dependency Rule"), it scans every source file under each layer and reports imports that resolve to a layer the importing layer may not depend on, across Python, JavaScript/TypeScript, Go, Java/Kotlin/Scala, Swift, Rust, C#, Ruby, and PHP. Relative imports are resolved against the importing file's directory first, so `from '../infrastructure/repo'` is caught even though it never spells the layer path literally. It also runs a graph pass over the declared table, because a cycle is invisible to a per-import check: if two layers may each depend on the other, every edge of that cycle is individually legal under its own allow-list, yet dependencies cannot point inward. Checking the declared graph is sufficient rather than a shortcut — every real import is either permitted (an edge already in that graph) or a violation already reported — and it catches an unsound architecture before any code exercises it. A `May Depend On` entry naming no declared layer is surfaced too, since a typo there permits nothing and silently makes a layer stricter than intended. It reads each language's module roots — the `module` prefix from `go.mod`, `paths` aliases and `baseUrl` from `tsconfig.json`, a top-level `src/` for src-layout projects — so an import can be compared to a layer path in the same terms rather than by directory name alone. Attribution then runs in two passes over every candidate form of the reference: full declared paths across all layers first, directory names only afterwards. The ordering is load-bearing, and getting it wrong produced a false negative that shipped in 1.39.0: testing both matches per layer in turn let an earlier layer's directory name beat a later layer's exact path, and when the wrong answer was the importing layer itself the import was dropped as a self-import and the violation vanished silently. Layers sharing a directory name are reported and skipped in the second pass rather than guessed at. Imports are attributed by path *component*, never by substring; negative-case tests (`scripts/test_check_architecture.sh`) prove a layer named `db` is not matched by an import of `dbutils`, that a legal inward dependency is never flagged, that a third-party Go import is not mistaken for an internal one, that an acyclic diamond is not mistaken for a cycle, that a cycle reachable from several entry points is reported once rather than once per path, and that vendored code under `node_modules/` is not attributed to the project. Layer enforcement is opt-in per project, since only the project knows its own layering — a repository with no table is never failed for lacking one.

That checker also reports **structural signals** (oversized files, crowded directories) which are advisory and never affect exit status, even under `--strict`. This is a deliberate exception to the usual pattern: `ARCHITECTURE.md`'s SRP guardrail says not to split a module merely because it is long, so failing a build on line count would contradict the principle the checker exists to serve. Its tests assert this directly — a 700-line file under `--strict` must still exit 0.

## CI Enforcement

Governance checkers are only as strong as the CI wiring around them. The framework ships CI workflow templates (installed by `scripts/bootstrap.sh` into `.github/workflows/`) for every checker above:

- `constitution-compliance.yml` — required-file presence (`check_compliance.sh`) and requirements traceability (`check_traceability.sh`).
- `constitution-version.yml` — the pinned `constitution/` submodule is current.
- `constitution-tests.yml` — runs the project's own declared test suite (`run_declared_tests.sh`) on every push and pull request. The constitution cannot know a project's language or runtime, so adopters add their own setup step before the test-run step; see the template's comments.
- `constitution-doc-freshness.yml` — the documentation decay tripwire (`check_doc_freshness.sh`) on pull requests only (it's meaningless on pushes).
- `constitution-secrets.yml` — the secrets sweep (`check_secrets.sh`) on every push and pull request.
- `constitution-ots.yml` — the OTS software inventory cross-check (`check_ots_inventory.sh`) on every push and pull request, plus a daily schedule.
- `constitution-env.yml` — the Environment Contract cross-check (`check_env_vars.sh`) on every push and pull request.
- `constitution-architecture.yml` — the Dependency Rule check (`check_architecture.sh`) on every push and pull request, plus a daily schedule.

All follow the same rollout contract: **warn by default, `--strict` to fail.** A newly bootstrapped or newly updated repository should never go instantly red because it hasn't caught up to a new rule yet — adopters opt into `--strict` per checker, per repository, once they've confirmed it's actually compliant. There are two exceptions, where the check itself is never optional regardless of `--strict`: `run_declared_tests.sh`, once a real test command is declared, always fails on that command's failure (`--strict` only governs the "nothing declared yet" case); and `check_secrets.sh` always fails on a real secret-shaped hit (`--strict` only governs the separate `.gitignore`-coverage recommendation). `check_architecture.sh` runs the exception the other way: its structural signals never fail, with or without `--strict`, because line count is a prompt to look rather than a verdict — only its layer violations respond to `--strict`.
