# Test Plan

This document defines how Eric's Engineering Constitution Framework is tested,
what coverage it targets, and where the known gaps are. It is the framework
holding itself to `TESTING.md`.

## Test Strategy

The framework is bash governance tooling plus Markdown standards, so the pyramid
is shallow by nature:

- **Unit / negative-case suites**: every checker, the bootstrap script, and the
  release tooling has a paired `scripts/test_<name>.sh` that builds throwaway
  fixtures under `mktemp -d` and proves the tool fails when it should (see
  `TESTING.md`, "Governance Tooling Must Be Tested"). Location: `scripts/`.
- **Contract / meta tests**: `scripts/test_checker_contract.sh` proves every
  `scripts/check_*.sh` honors the shared checker contract (`--help`, exit `2`
  on a bad option, `--strict` where the warn/strict rollout applies, executable
  bit, CI annotations). `scripts/test_release_docs.sh` proves every version
  reference agrees with `VERSION`. `scripts/test_mcp_resources.sh` proves the
  MCP server exposes every standards document.
- **End-to-end**: `scripts/test_bootstrap.sh` runs a real bootstrap against a
  fresh Git repository and inspects the result; `.github/workflows/tests.yml`'s
  `self-governance` job runs the shipped checkers against this repository.

## How to Run Tests

- Full suite: `bash scripts/run_all_tests.sh`
- With coverage: `n/a` (see Coverage Targets)
- A single test or subset: `bash scripts/test_<name>.sh`

`run_all_tests.sh --quiet` shows one line per suite and replays only failing
output; CI runs the full suite through `scripts/run_declared_tests.sh --strict`
so the command declared here is the one that is enforced.

## Coverage Targets

There is no line-coverage tool for bash in this repository's zero-dependency
toolchain, so the target is expressed structurally rather than as a
percentage:

| Scope | Metric | Floor |
| --- | --- | --- |
| Every `scripts/check_*.sh` | Has a paired `test_check_*.sh` with at least one negative case | 100% |
| Every script `bootstrap.sh` installs | Asserted present by `test_bootstrap.sh` | 100% |
| Every shared library under `scripts/lib/` | Exercised by the suite of the script that sources it | 100% |

`scripts/test_checker_contract.sh` enforces the first row mechanically.

## Continuous Coverage Evaluation

| Date | Suites | Notes |
| --- | --- | --- |
| 2026-09-16 | 27 | Baseline: first run under `run_all_tests.sh` in CI. |

## Coverage Gap Log

| Gap ID | Area / behavior | Risk | Related requirement | Status | TODO ref |
| --- | --- | --- | --- | --- | --- |
| GAP-001 | `scripts/bump_adopters.sh` is exercised only against local bare repositories; the GitHub pull-request step (`--no-pr` skipped in tests) is verified by hand during fleet rollouts. | Medium | n/a | Open | TODO.md → Testing |
| GAP-002 | `scripts/audit_adopters.sh` and `scripts/setup-machine.sh` have suites, but their network paths (`--fetch`, real installers) are stubbed with fixtures. | Low | n/a | Open | TODO.md → Testing |
| GAP-003 | `mcp-server/index.js` has a resource-coverage test but no runtime test of the MCP protocol handlers (would need Node and the SDK in CI). | Low | n/a | Open | TODO.md → Testing |

## Requirement Coverage

Not applicable: this is not a product-facing repository (see `DOCUMENTATION.md`,
"Product Requirements Expectations", for the definition).
