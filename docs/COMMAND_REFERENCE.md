# Command Reference

Every command runs from the repository root. Checkers follow the shared
contract in `TESTING.md` ("CI Enforcement"): warn by default, `--strict` to
fail, `--help` for usage, exit `2` on a usage error.

## Testing

- `bash scripts/run_all_tests.sh`: run every `scripts/test_*.sh` suite (the declared "Full suite").
- `bash scripts/run_all_tests.sh --quiet`: one line per suite; failing output replayed.
- `bash scripts/test_<name>.sh`: run one suite.
- `bash scripts/run_declared_tests.sh --strict .`: what CI runs; reads the command from `docs/TEST_PLAN.md`.

## Self-Governance (what CI runs against this repository)

- `bash scripts/check_secrets.sh --strict .`
- `bash scripts/check_instruction_templates.sh --strict .` (also `templates` and `examples/sample-project`)
- `bash scripts/check_skills.sh --strict .`
- `bash scripts/check_wiki_links.sh --strict .`
- `bash scripts/check_ots_inventory.sh --strict --manifest-dir mcp-server .`
- `bash scripts/test_release_docs.sh`
- `bash scripts/check_compliance.sh .` (informational: the source repository has no `constitution/` submodule)

## Adopter-Facing Checkers (run through the submodule by adopters)

- `check_compliance.sh`, `check_traceability.sh`, `check_version_alignment.sh`, `check_constitution_freshness.sh`
- `check_doc_freshness.sh --base <sha> --head <sha>`, `check_wiki_freshness.sh --base <sha> --head <sha>`
- `check_ots_inventory.sh`, `check_env_vars.sh`, `check_architecture.sh`, `check_secrets.sh`
- `run_declared_tests.sh`, `measure_instruction_weight.sh`

## Bootstrap and Fleet

- `bash scripts/bootstrap.sh [--force] [--agents=<list>] <project> <constitution-url>`: adopt the constitution in a repository.
- `bash scripts/audit_adopters.sh [--fetch] <parent-dir>...`: report which adopters are behind.
- `bash scripts/bump_adopters.sh --sha <commit> --repos <file> [--no-pr]`: pin the fleet to a release (see `RELEASES.md`).
- `bash scripts/setup-machine.sh`: one-time per-machine agent toolchain install.

## Release

- `bash scripts/version_analyzer.sh .`: suggest the next version from Conventional Commit prefixes.
- `bash scripts/check_release_tag_alignment.sh .`: prove `VERSION`, `HEAD`, and the latest tag agree.

## Knowledge Sources

- `bash scripts/check_source_summaries.sh scan`: list sources needing a summary.
- `bash scripts/check_source_summaries.sh record <relative-path>`: mark a source processed.

## MCP Server

- `cd mcp-server && npm install && node index.js`: run the server on stdio.
