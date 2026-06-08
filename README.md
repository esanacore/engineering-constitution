# Engineering Constitution

The Engineering Constitution is a reusable framework for AI-assisted software development standards.

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

## Version

Current version: 1.0.0

See `VERSION`.

## Repository Contents

- `CONSTITUTION.md`: Authoritative principles and required workflow.
- `AI_WORKFLOW.md`: Step-by-step AI agent workflow.
- `TESTING.md`: Testing expectations and reporting standards.
- `DOCUMENTATION.md`: Documentation requirements and checklists.
- `SECURITY.md`: Security review standards.
- `ARCHITECTURE.md`: Architecture and ADR expectations.
- `RELEASES.md`: Release and changelog standards.
- `TODO_GUIDELINES.md`: TODO.md structure and maintenance rules.
- `templates/`: Files to copy into projects.
- `examples/sample-project/`: Example project layout.
- `scripts/bootstrap.sh`: Script to initialize an existing repository.

## Use as a Submodule

Add this repository to a project as a submodule:

```bash
git submodule add <repository-url> constitution
```

Then copy or generate the project-level files:

```bash
cp constitution/templates/AGENTS.md AGENTS.md
cp constitution/templates/CLAUDE.md CLAUDE.md
cp constitution/templates/COPILOT_INSTRUCTIONS.md COPILOT_INSTRUCTIONS.md
cp constitution/templates/TODO.md TODO.md
cp constitution/templates/CHANGELOG.md CHANGELOG.md
mkdir -p docs/adr
cp constitution/templates/ADR.md docs/adr/0001-record-architecture-decisions.md
```

## Bootstrap an Existing Repository

From this repository, run:

```bash
./scripts/bootstrap.sh /path/to/project <repository-url>
```

The script adds:

- `constitution` submodule
- `AGENTS.md`
- `CLAUDE.md`
- `COPILOT_INSTRUCTIONS.md`
- `TODO.md`
- `CHANGELOG.md`
- `docs/adr/`
- Starter ADR

The script will not overwrite existing files unless `--force` is passed.

## Update Existing Projects

When universal rules change:

1. Update this repository.
2. Increment `VERSION`.
3. Pull latest submodule changes into projects.
4. Commit updated submodule references.

## Project Template Structure

Every project should eventually contain:

```text
project/
├── constitution/
├── AGENTS.md
├── CLAUDE.md
├── COPILOT_INSTRUCTIONS.md
├── TODO.md
├── CHANGELOG.md
├── README.md
├── docs/
│   └── adr/
└── src/
```
