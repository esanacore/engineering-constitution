# Eric's Engineering Constitution

Eric's Engineering Constitution is a reusable framework for AI-assisted software development standards. It is the single source of truth for how humans and AI agents should work across your software repositories.

Each project includes this repository as a `constitution/` Git submodule alongside a small set of local project files, giving every project:

- Shared engineering principles
- Standard AI-agent workflow instructions
- Baseline templates for README, TODO, CHANGELOG, AGENTS, Claude, Copilot, and ADR files
- A standardized "Eric's Engineering Constitution" adoption badge in the README
- A bootstrap script that installs those files into an existing Git repository

## Repository Contents

- `CONSTITUTION.md`: Authoritative engineering principles.
- `AI_WORKFLOW.md`: Step-by-step AI agent workflow.
- `INTEGRATION.md`: Submodule workflow, agent reading order, project-specific overrides, and VERSION update strategy.
- `TESTING.md`: Testing expectations and reporting standards.
- `DOCUMENTATION.md`: Documentation requirements and checklists.
- `SECURITY.md`: Security review standards.
- `OPERATIONS.md`: Operations and infrastructure standards.
- `ARCHITECTURE.md`: Architecture and ADR expectations.
- `RELEASES.md`: Release and changelog standards.
- `TODO_GUIDELINES.md`: TODO.md structure and maintenance rules.
- `KNOWLEDGE_SOURCES.md`: How to drop in book/reference sources and turn them into agent-consumable summaries via `sources/`.
- `templates/`: Files to copy into projects.
- `templates/docs/PRODUCT_REQUIREMENTS.md`: Optional product requirements template.
- `templates/docs/MVP_BACKLOG.md`: Optional milestone backlog template for early-stage products.
- `examples/sample-project/`: Example project layout.
- `examples/OPERATIONS.example.md`: Fully worked `docs/OPERATIONS.md` runbook for a deployed service.
- `scripts/bootstrap.sh`: Script to initialize an existing repository.
- `scripts/check_traceability.sh`: Reference checker that verifies every requirement ID has a verifying-test entry in the traceability matrix.
- `scripts/check_compliance.sh`: Reference checker that verifies an adopting repository carries the expected governance files.
- `scripts/check_version_alignment.sh`: Reference checker that verifies adopter-facing Constitution version references match the pinned `constitution/VERSION`.
- `scripts/run_declared_tests.sh`: Runs the test command an adopting repository declares in `docs/TEST_PLAN.md`, enforcing it in CI.
- `scripts/check_doc_freshness.sh`: Blunt CI tripwire that flags a pull request changing source files without touching README.md/CHANGELOG.md.

## Version

Current version: 1.30.0

See `VERSION`.

## Getting Started

### Step 1: Publish This Repository

Publish this repository somewhere your projects can access it:

```bash
cd /path/to/engineering-constitution
git remote add origin <repository-url>
git push -u origin main
```

Use that `<repository-url>` in the bootstrap commands below.

### Step 2: Bootstrap a Project

Run the bootstrap script to set up the constitution in any Git repository:

```bash
./scripts/bootstrap.sh /path/to/project <repository-url>
```

The target project must already be a Git repository. Pass `--force` to overwrite previously generated files:

```bash
./scripts/bootstrap.sh --force /path/to/project <repository-url>
```

#### New Repository

```bash
mkdir my-project
cd my-project
git init
cd /path/to/engineering-constitution
./scripts/bootstrap.sh /path/to/my-project <repository-url>
```

Customize the generated files (`README.md`, `TODO.md`, `CHANGELOG.md`, `docs/adr/0001-record-architecture-decisions.md`), then commit:

```bash
cd /path/to/my-project
git add .
git commit -m "Add Eric's engineering constitution"
```

#### Existing Repository

```bash
./scripts/bootstrap.sh /path/to/existing-project <repository-url>
```

The script adds the `constitution` submodule, creates missing governance files, and writes an adoption report to `.constitution-bootstrap/adoption-report.md`. Existing files are never overwritten by default — template copies are placed in `.constitution-bootstrap/templates/` for manual merging.

After running it:

1. Review `.constitution-bootstrap/adoption-report.md` for detected project context and recommended merge steps.
2. Merge any relevant template content into skipped files.
3. Customize generated placeholders.
4. Commit `.gitmodules`, the `constitution` submodule reference, generated files, and any merged changes.

### Adoption Badge

Every repository the bootstrap script touches gets a standardized adoption badge in its `README.md`:

```markdown
<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->
```

The badge is managed between the `CONSTITUTION_START` / `CONSTITUTION_END` markers, so it is added to existing READMEs (after the first heading), refreshed in place when the constitution is updated, and never duplicated on re-runs. The badge link points at the bootstrap source when it is a public Git URL and falls back to the canonical repository otherwise.

### Manual Installation

If you prefer not to use the bootstrap script:

```bash
git submodule add <repository-url> constitution
cp constitution/templates/AGENTS.md AGENTS.md
cp constitution/templates/CLAUDE.md CLAUDE.md
