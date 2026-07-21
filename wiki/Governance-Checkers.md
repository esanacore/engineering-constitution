# Governance Checkers

The framework ships zero-dependency Bash checkers under `scripts/`, each with a
matching `test_*.sh` negative-case suite and a `constitution-*.yml` workflow
template that runs it in an adopting repository's CI. Every checker is
governance tooling, so every checker is itself tested (`TESTING.md`,
"Governance Tooling Must Be Tested").

## Rollout contract

All checkers follow the same contract: **warn by default, `--strict` to fail.**
A newly bootstrapped or newly updated repository should never go instantly red
because it has not caught up to a new rule yet — adopters opt into `--strict`
per checker, per repository, once they have confirmed compliance.

Two exceptions never merely warn: `run_declared_tests.sh` always fails when a
*declared* test command fails (`--strict` only governs the "nothing declared
yet" case), and `check_secrets.sh` always fails on a real secret-shaped hit
(`--strict` only governs the separate `.gitignore`-coverage recommendation).
`check_architecture.sh` runs the exception the other way: its structural
signals never fail, because line count is a prompt to look, not a verdict —
only its layer violations respond to `--strict`.

## The checkers

| Script | What it verifies |
| --- | --- |
| `check_compliance.sh` | The repository carries the required, recommended, and product-facing governance files, and that recommended/product docs are not still template placeholders. |
| `check_traceability.sh` | Every requirement ID in `docs/PRODUCT_REQUIREMENTS.md` has a non-gap verifying-test row in `docs/REQUIREMENTS_TRACEABILITY.md`, matched by exact value so a layered ID never satisfies a system-layer ID. |
| `run_declared_tests.sh` | Runs the "Full suite" command declared in `docs/TEST_PLAN.md`, so "run all automated tests" is enforced in CI. |
| `check_doc_freshness.sh` | Flags a PR that changes source but never touches `README.md`/`CHANGELOG.md`. Blunt tripwire. |
| `check_wiki_freshness.sh` | Flags a PR that **adds or removes** source files without touching the wiki that catalogues them — a higher bar than doc-freshness (modifications do not trip it). See [[Home]] and `docs/adr/0001-wiki-subsystem.md`. |
| `check_ots_inventory.sh` | Cross-checks runtime dependencies in root manifests against `docs/OTS_SOFTWARE.md`, matched by exact name, so an undocumented dependency is flagged. |
| `check_env_vars.sh` | Cross-checks environment variables in root manifests against `docs/ENV_VARS.md`. |
| `check_architecture.sh` | Verifies every import points inward per the Dependency Rule, using layers a project declares in `docs/ARCHITECTURE.md`; also detects cycles and unknown layer references. |
| `check_secrets.sh` | Sweeps tracked and untracked-but-not-gitignored files for credential-shaped filenames and high-confidence secret patterns. |
| `check_version_alignment.sh` | Catches adopter-facing version references that drifted from the pinned `constitution/VERSION`. |
| `check_constitution_freshness.sh` | Warns at session start when the pinned `constitution/` submodule is behind the latest release. |
| `check_source_summaries.sh` | Detects drift between dropped knowledge sources (`sources/raw/`) and their generated summaries. |

## See also

- [[Standards Overview]]
- [[Bootstrap Script]]
- [[Templates and Examples]]
