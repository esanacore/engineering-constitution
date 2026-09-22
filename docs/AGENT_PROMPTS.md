# Agent Prompts

Copyable prompts for working on the framework itself with an AI agent. Each
one assumes the agent has already run the Required Workflow's reading steps.

## Add a New Governance Checker

```text
Add scripts/check_<name>.sh following the checker contract in TESTING.md ("CI Enforcement"): --help, --strict, exit 2 on usage errors, source scripts/lib/ci_annotations.sh, warn by default. Ship scripts/test_check_<name>.sh with negative cases proving it fails when it should, a templates/.github/workflows/constitution-<name>.yml, bootstrap.sh installation with a test_bootstrap.sh assertion, and the TESTING.md / README.md / wiki Governance-Checkers entries. scripts/test_checker_contract.sh must pass.
```

## Promote a Knowledge Source

```text
Run `bash scripts/check_source_summaries.sh scan`. For each NEW source, read it and write the summary per KNOWLEDGE_SOURCES.md, record it, then list the "Where It Could Apply" leads in TODO.md as separate items. Do not change any standards document in the same change.
```

## Cut a Release

```text
Follow RELEASES.md "Cutting a Release" exactly: bump VERSION and every reference (README, CONSTITUTION, demo.html, wiki/Home.md, mcp-server/package.json and lockfile), date the CHANGELOG section, run `bash scripts/run_all_tests.sh`, commit, and hand me the tag command with the exact merge-commit SHA pinned plus the pre-filled GitHub Release link. Then prepare the fleet bump with scripts/bump_adopters.sh.
```

## Audit the Framework Against Itself

```text
Run every checker in .github/workflows/tests.yml's self-governance job against this repository in --strict mode and the compliance checker for its recommended-tier report. Fix anything that fails; for anything you leave open, add a TODO.md item with the reason.
```

## Critique a Diff From a Fresh Context

```text
Read only `git diff main...HEAD`. Is the change correct, minimal, and simpler than it could be? Does it respect the Core Principles and docs/MEMORY.md? List concrete findings; do not restate the diff.
```
