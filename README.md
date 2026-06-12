# Eric's Engineering Constitution

Eric's Engineering Constitution is a reusable framework for AI-assisted software development standards. It is the single source of truth for how humans and AI agents should work across your software repositories.

Each project includes this repository as a `constitution/` Git submodule alongside a small set of local project files, giving every project:

- Shared engineering principles
- Standard AI-agent workflow instructions
- Baseline templates for README, TODO, CHANGELOG, AGENTS, Claude, Copilot, and ADR files
- A bootstrap script that installs those files into an existing Git repository

## Repository Contents

- `CONSTITUTION.md`: Authoritative engineering principles.
- `AI_WORKFLOW.md`: Step-by-step AI agent workflow.
- `INTEGRATION.md`: Submodule workflow, agent reading order, project-specific overrides, and VERSION update strategy.
- `TESTING.md`: Testing expectations and reporting standards.
- `DOCUMENTATION.md`: Documentation requirements and checklists.
- `SECURITY.md`: Security review standards.
- `ARCHITECTURE.md`: Architecture and ADR expectations.
- `RELEASES.md`: Release and changelog standards.
- `TODO_GUIDELINES.md`: TODO.md structure and maintenance rules.
- `templates/`: Files to copy into projects.
- `examples/sample-project/`: Example project layout.
- `scripts/bootstrap.sh`: Script to initialize an existing repository.

## Version

Current version: 1.1.0

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

### Manual Installation

If you prefer not to use the bootstrap script:

```bash
git submodule add <repository-url> constitution
cp constitution/templates/AGENTS.md AGENTS.md
cp constitution/templates/CLAUDE.md CLAUDE.md
mkdir -p .github
cp constitution/templates/.github/copilot-instructions.md .github/copilot-instructions.md
mkdir -p .cursor/rules
cp constitution/templates/.cursor/rules/project.mdc .cursor/rules/project.mdc
cp constitution/templates/TODO.md TODO.md
cp constitution/templates/CHANGELOG.md CHANGELOG.md
mkdir -p docs/adr
cp constitution/templates/ADR.md docs/adr/0001-record-architecture-decisions.md
```

## Updating Projects

When universal rules change:

1. Update this repository and increment `VERSION`.
2. Pull the updated submodule into each project:

```bash
cd /path/to/project
git submodule update --remote constitution
git add constitution
git commit -m "Update Eric's engineering constitution"
```

See `INTEGRATION.md` for version checking, template diffing, and project file structure.
