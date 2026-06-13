# Eric's Engineering Constitution

A reusable framework for AI-assisted software development standards.

It is the single source of truth for how humans and AI agents should work across your software repositories.

## Why adopt this?

Each project that adopts this framework gets:

- Shared engineering principles
- Standard AI-agent workflow instructions
- Baseline templates for README, TODO, CHANGELOG, AGENTS, Claude, Copilot, and ADR files
- A standardized adoption badge in the project README
- A bootstrap script to install and update those files in existing repositories

## What you get

| Path | Purpose |
|---|---|
| `CONSTITUTION.md` | Authoritative engineering principles |
| `AI_WORKFLOW.md` | Step-by-step AI agent workflow |
| `INTEGRATION.md` | Submodule workflow, reading order, overrides, and update strategy |
| `TESTING.md` | Testing expectations and reporting standards |
| `DOCUMENTATION.md` | Documentation requirements and checklists |
| `SECURITY.md` | Security review standards |
| `OPERATIONS.md` | Operations and infrastructure standards |
| `ARCHITECTURE.md` | Architecture and ADR expectations |
| `RELEASES.md` | Release and changelog standards |
| `TODO_GUIDELINES.md` | TODO.md structure and maintenance rules |
| `templates/` | Files to copy into projects |
| `examples/sample-project/` | Example adopted project layout |
| `scripts/bootstrap.sh` | Script to initialize an existing repository |

## Version

Current version: **1.14.0**

See `VERSION`.

## Quick Start

### 1) Publish this repository

Publish this repository somewhere your projects can access:

```bash
cd /path/to/engineering-constitution
git remote add origin <repository-url>
git push -u origin main
```

Use that `<repository-url>` in the bootstrap commands below.

### 2) Bootstrap a project

Run the bootstrap script to set up the constitution in any Git repository:

```bash
./scripts/bootstrap.sh /path/to/project <repository-url>
```

The target project must already be a Git repository. Pass `--force` to overwrite previously generated files:

```bash
./scripts/bootstrap.sh --force /path/to/project <repository-url>
```

#### New repository

```bash
mkdir my-project
cd my-project
git init
cd /path/to/engineering-constitution
./scripts/bootstrap.sh /path/to/my-project <repository-url>
```

Customize generated files (`README.md`, `TODO.md`, `CHANGELOG.md`, `docs/adr/0001-record-architecture-decisions.md`), then commit:

```bash
cd /path/to/my-project
git add .
git commit -m "Add Eric's engineering constitution"
```

#### Existing repository

```bash
./scripts/bootstrap.sh /path/to/existing-project <repository-url>
```

The script adds the `constitution` submodule, creates missing governance files, and writes an adoption report to `.constitution-bootstrap/adoption-report.md`.

Existing files are not overwritten by default. Template copies are written to `.constitution-bootstrap/templates/` for manual merging.

After running it:

1. Review `.constitution-bootstrap/adoption-report.md` for detected context and recommended merge steps.
2. Merge relevant template content into skipped files.
3. Customize generated placeholders.
4. Commit `.gitmodules`, the `constitution` submodule reference, generated files, and merged changes.

## Adoption badge

Every repository the bootstrap script touches gets a standardized adoption badge in `README.md`:

```markdown
<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->
```

The badge is managed between the `CONSTITUTION_START` / `CONSTITUTION_END` markers, so it is added after the first heading, refreshed in place when updated, and never duplicated on re-runs.

## Manual installation

If you prefer not to use the bootstrap script:

```bash
git submodule add <repository-url> constitution
cp constitution/templates/AGENTS.md AGENTS.md
cp constitution/templates/CLAUDE.md CLAUDE.md
cp constitution/templates/.github/copilot-instructions.md .github/copilot-instructions.md
cp constitution/templates/TODO.md TODO.md
cp constitution/templates/CHANGELOG.md CHANGELOG.md
mkdir -p docs/adr
cp constitution/templates/ADR.md docs/adr/0001-record-architecture-decisions.md
```

Then copy any other needed files from `constitution/templates/` into your project.

## See also

- `INTEGRATION.md` for reading order and local override strategy
- `CHANGELOG.md` for release history
- `examples/sample-project/` for a concrete adopted layout
