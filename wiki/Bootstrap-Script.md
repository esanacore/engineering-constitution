# Bootstrap Script

`scripts/bootstrap.sh` initializes an existing Git repository with the
constitution submodule and the local governance files an adopting project is
expected to carry.

## What it does

- Adds `constitution/` as a fixed-path Git submodule pinned to a specific
  version of this framework.
- Copies template governance files such as `AGENTS.md`, `HELP.md`,
  `SECURITY.md`, `VERSION`, and the documentation scaffolds under `docs/`.
- Installs automation, including `.github/dependabot.yml` and the
  `.github/workflows/constitution-*.yml` CI checks (compliance, version,
  tests, doc-freshness, OTS, env, architecture, secrets, and wiki).
- Preserves existing files by default: when a target file already exists, a
  merge-ready copy is written to `.constitution-bootstrap/templates/` instead of
  overwriting it.
- Injects or refreshes the standardized README adoption badge.
- Generates `.constitution-bootstrap/adoption-report.md` describing what was
  installed, skipped, or left for manual merge.

## Choosing agent-instruction files

The repository root is an architectural surface, not a junk drawer
(`CONSTITUTION.md` Principle 6). `AGENTS.md` is the cross-vendor standard and is
the only agent-instruction file every repository needs, so it is the default.
Vendor files that exist only because a tool hardcodes its own name
(`CLAUDE.md`, `.cursorrules`, `.goosehints`, `.openhands_instructions`, and the
rest) are opt-in per tool:

```bash
# Just AGENTS.md (default)
./scripts/bootstrap.sh /path/to/project <repository-url>

# Add Claude Code and Cursor support
./scripts/bootstrap.sh --agents=claude,cursor /path/to/project <repository-url>

# Every vendor file (the pre-1.38.0 behavior)
./scripts/bootstrap.sh --agents=all /path/to/project <repository-url>
```

A default bootstrap adds roughly half the root entries the old "install
everything" behavior did. Repositories adopted before the root-hygiene change
are grandfathered — `scripts/check_compliance.sh` accepts the old root
locations, so moving files into `.github/` and `docs/` is a cleanup you can
schedule, not a migration you must perform.

## Related, but deliberately separate

`scripts/setup-machine.sh` provisions a machine's global AI-agent toolchain
(Bun, gstack, goose, goosetown). It is intentionally **not** called by
`bootstrap.sh`: provisioning a machine and bootstrapping a repository's
governance files are different concerns with different blast radii. See
`INTEGRATION.md`, "Provisioning a Machine in One Step."

## See also

- [[Getting Started]]
- [[Governance Checkers]]
- [[Templates and Examples]]
