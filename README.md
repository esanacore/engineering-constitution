# Engineering Constitution

The Engineering Constitution is a reusable framework for AI-assisted software development standards.

It is intended to be the single source of truth for how humans and AI agents should work across your software repositories. Instead of copying long instructions into every project and letting them drift, each project includes this repository as a `constitution/` Git submodule and keeps a small set of local project files beside it.

In practical terms, this repository gives every project:

- Shared engineering principles.
- Standard AI-agent workflow instructions.
- Baseline templates for README, TODO, CHANGELOG, AGENTS, Claude, Copilot, and ADR files.
- A bootstrap script that installs those files into an existing Git repository.

It defines shared expectations for:

- Documentation
- Testing
- TODO management
- Security review
- Architecture decisions
- Dependency hygiene
- Observability
- Release discipline
- Opportunity discovery

## How It Works

Each project gets:

- `constitution/`: Git submodule pointing to this repository.
- `AGENTS.md`: Project-specific entry point for AI agents.
- `CLAUDE.md`: Claude-specific guidance.
- `.github/copilot-instructions.md`: GitHub Copilot guidance (auto-loaded by Copilot).
- `.cursor/rules/project.mdc`: Cursor guidance (auto-loaded by Cursor).
- `TODO.md`: Living roadmap.
- `CHANGELOG.md`: Release history.
- `docs/adr/`: Architecture Decision Records.

The submodule keeps universal rules centralized. The project-level files keep local context close to the code.

## Version

Current version: 1.1.0

See `VERSION`.

## Repository Contents

- `CONSTITUTION.md`: Authoritative principles and required workflow.
- `AI_WORKFLOW.md`: Step-by-step AI agent workflow.
- `INTEGRATION.md`: Submodule workflow, VERSION strategy, agent overrides, and project-specific rules.
- `TESTING.md`: Testing expectations and reporting standards.
- `DOCUMENTATION.md`: Documentation requirements and checklists.
- `SECURITY.md`: Security review standards.
- `ARCHITECTURE.md`: Architecture and ADR expectations.
- `RELEASES.md`: Release and changelog standards.
- `TODO_GUIDELINES.md`: TODO.md structure and maintenance rules.
- `templates/`: Files to copy into projects.
- `examples/sample-project/`: Example project layout.
- `scripts/bootstrap.sh`: Script to initialize an existing repository.

## Quick Start

Use the bootstrap script for new or existing Git repositories:

```bash
/path/to/engineering-constitution/scripts/bootstrap.sh /path/to/project <repository-url>
```

Use `--force` only when you intentionally want to overwrite generated files:

```bash
/path/to/engineering-constitution/scripts/bootstrap.sh --force /path/to/project <repository-url>
```

The target project must already be a Git repository.

## Deploy This Constitution Repository

To use this framework across projects, publish this repository somewhere your projects can access it:

```bash
cd /path/to/engineering-constitution
git remote add origin <repository-url>
git push -u origin main
```

Use that `<repository-url>` when bootstrapping projects.

Example:

```bash
./scripts/bootstrap.sh ~/Repos/my-app git@github.com:your-org/engineering-constitution.git
```

## Add to a New Repository

Create or enter a new Git repository:

```bash
mkdir my-project
cd my-project
git init
```

Bootstrap the constitution:

```bash
/path/to/engineering-constitution/scripts/bootstrap.sh . <repository-url>
```

Review and customize:

- `README.md`
- `TODO.md`
- `CHANGELOG.md`
- `docs/adr/0001-record-architecture-decisions.md`

Commit the initialized structure:

```bash
git add .
git commit -m "Add engineering constitution"
```

## Add to an Existing Repository

From this repository, run:

```bash
./scripts/bootstrap.sh /path/to/existing-project <repository-url>
```

The script will:

- Add the constitution as a submodule at `constitution/`.
- Add missing agent and project governance files.
- Create `docs/adr/`.
- Skip files that already exist.
- Write an adoption report to `.constitution-bootstrap/adoption-report.md`.
- Copy template versions of skipped files into `.constitution-bootstrap/templates/` so you can merge them manually.

After running it:

1. Review skipped files and decide whether to merge template content manually.
2. Customize generated placeholders.
3. Review `.constitution-bootstrap/adoption-report.md` for detected project context and recommended merge steps.
4. Commit `.gitmodules`, the `constitution` submodule reference, generated files, and any merged documentation changes.

## Manual Submodule Installation

If you do not want to use the bootstrap script, add this repository to a project as a submodule:

```bash
git submodule add <repository-url> constitution
```

Then copy or generate the project-level files:

```bash
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

## Bootstrap Script Behavior

The script adds:

- `constitution` submodule
- `AGENTS.md`
- `CLAUDE.md`
- `.github/copilot-instructions.md`
- `.cursor/rules/project.mdc`
- `TODO.md`
- `CHANGELOG.md`
- `README.md` if missing
- `docs/adr/`
- `docs/adr/0001-record-architecture-decisions.md`
- `.constitution-bootstrap/adoption-report.md`
- `.constitution-bootstrap/templates/` for skipped existing files

By default, the script does not overwrite existing files. Pass `--force` to overwrite generated files from the templates.

For existing repositories, the adoption report pulls together useful project context without modifying the original files:

- Existing governance files
- Files written by the bootstrap script
- Existing files preserved
- Detected project signals such as package metadata, Makefiles, Docker files, and GitHub Actions workflows
- Recommended merge steps
- Suggested AGENTS.md context

When possible, the script initializes framework files from existing project content:

- If `TODO.md` is missing and `COPILOT_TASK_BACKLOG.md` exists, `TODO.md` is generated from that backlog instead of using a blank placeholder.
- If `CHANGELOG.md` is missing and a `RELEASE_NOTES*.md` file exists, `CHANGELOG.md` is generated from those release notes instead of using a blank placeholder.

Existing files are still preserved by default. The generated adoption report and merge templates show what should be reviewed manually.

## Update Existing Projects

When universal rules change:

1. Update this repository.
2. Increment `VERSION`.
3. Pull latest submodule changes into projects.
4. Commit updated submodule references.

Example update inside a project:

```bash
cd /path/to/project
git submodule update --remote constitution
git add constitution
git commit -m "Update engineering constitution"
```

## Project Template Structure

Every project should eventually contain:

```text
project/
├── constitution/
├── AGENTS.md
├── CLAUDE.md
├── .github/
│   └── copilot-instructions.md
├── .cursor/
│   └── rules/
│       └── project.mdc
├── TODO.md
├── CHANGELOG.md
├── README.md
├── docs/
│   └── adr/
└── src/
```
