# Troubleshooting

Known failure modes when working on the framework itself, most of them
learned the hard way (see `docs/MEMORY.md` for the fuller history).

## Common Issues

### A test suite fails with `Permission denied` on a fresh clone

- **Symptoms**: `test_check_<x>.sh` dies immediately; the checker it invokes is not executable.
- **Cause**: the checker was committed as `100644`. Suites invoke checkers directly, not through `bash`.
- **Fix**: `git update-index --chmod=+x scripts/check_<x>.sh`, commit. `scripts/test_checker_contract.sh` now fails on this before it can ship.

### `bootstrap.sh` sources a library that does not exist

- **Symptoms**: `scripts/lib/bootstrap_*.sh: No such file or directory` on a clone, while the working tree passes.
- **Cause**: a global gitignore with a bare `lib/` entry kept the directory out of `git add -A`.
- **Fix**: the repository `.gitignore` un-ignores `scripts/lib/`; make sure the files are tracked (`git ls-files scripts/lib`).

### A suite fails only on Windows Git Bash

- **Symptoms**: `curl: (37) Could not open file`, or a sandboxed `PATH` cannot find `git`.
- **Cause**: MSYS2 splits tools across `/mingw64/bin` and `/usr/bin`, and native curl needs Windows-style `file://` paths.
- **Fix**: resolve tool directories with `command -v` and build `file://` URLs through `cygpath -m` when available, as `test_setup_machine.sh` does.

### `test_release_docs.sh` or `test_mcp_resources.sh` fails after a version bump

- **Symptoms**: a file still mentions the previous version.
- **Cause**: version references live in six places: `VERSION`, `README.md`, `CONSTITUTION.md`, `demo.html`, `wiki/Home.md`, and `mcp-server/package.json` (plus its lockfile).
- **Fix**: `grep -rn "<previous version>" --include='*.md' --include='*.html' --include='*.json' .` and update the stragglers.

### `check_compliance.sh .` reports `constitution (required)` missing here

- **Symptoms**: the source repository fails its own required-file check.
- **Cause**: expected. The checker looks for the `constitution/` submodule an adopter carries; the source repository is the thing being adopted.
- **Fix**: none; run it for the recommended-tier report only.

### The wiki publish job fails with a clone error

- **Symptoms**: `Could not clone <repo>.wiki.git`.
- **Cause**: GitHub creates the wiki repository only after the wiki is enabled and its first page is created in the UI.
- **Fix**: Settings → Features → Wikis, create the Home page once, re-run the job.

## Environment Reset

```bash
git clean -fdx -e .claude/settings.local.json   # drops mktemp leftovers and node_modules
cd mcp-server && npm ci && cd ..
bash scripts/run_all_tests.sh --quiet
```
