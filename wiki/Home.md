# Home

Eric's Engineering Constitution is a reusable framework for AI-assisted software development standards. It gives teams a single source of truth for how humans and AI agents should work across repositories, then ships the scripts and templates needed to roll that standard into existing Git projects.

## What you get

When a project adopts this constitution, it gains:

- Shared engineering principles in `CONSTITUTION.md`
- A required agent workflow in `AI_WORKFLOW.md`
- Standards for testing, documentation, security, operations, architecture, releases, and roadmap hygiene
- Bootstrap templates for governance files like `README.md`, `TODO.md`, `CHANGELOG.md`, `AGENTS.md`, `CLAUDE.md`, and ADRs
- CI-ready governance tooling such as traceability and compliance checks
- A standardized Eric's Engineering Constitution adoption badge for project READMEs

## Repository map

- **Core standards**: `CONSTITUTION.md`, `AI_WORKFLOW.md`, `TESTING.md`, `DOCUMENTATION.md`, `SECURITY.md`, `OPERATIONS.md`, `ARCHITECTURE.md`, `RELEASES.md`, `TODO_GUIDELINES.md`, `INTEGRATION.md`
- **Templates**: `templates/` contains the files copied into adopting repositories, including documentation stubs, agent-instruction bridges, workflows, and ADR scaffolding
- **Automation**: `scripts/` contains the bootstrap installer plus governance checkers and their test scripts
- **Examples**: `examples/sample-project/` shows the expected project shape after adoption, and `examples/OPERATIONS.example.md` is a worked operations runbook
- **MCP integration**: `mcp-server/` contains a small Node.js MCP server exposing constitution resources and a project-structure validation tool

## Typical workflow

1. Publish or clone this repository somewhere your projects can access.
2. Run `./scripts/bootstrap.sh /path/to/project <repository-url>` from this repo.
3. Review `.constitution-bootstrap/adoption-report.md` in the target project.
4. Merge any skipped template content into existing project files.
5. Commit the `constitution` submodule plus the generated governance files.

## Key scripts

### `scripts/bootstrap.sh`
Initializes an existing Git repository with the constitution submodule and local governance files. It:

- Adds `constitution/` as a fixed-path Git submodule
- Copies templates such as `AGENTS.md`, `HELP.md`, `SECURITY.md`, `VERSION`, and docs under `docs/`
- Installs automation like `.github/dependabot.yml`, `.github/workflows/constitution-version.yml`, and `.github/workflows/constitution-compliance.yml`
- Preserves existing files by default, writing merge-ready copies to `.constitution-bootstrap/templates/`
- Injects or refreshes the standardized README adoption badge
- Generates `.constitution-bootstrap/adoption-report.md`

### `scripts/check_traceability.sh`
Validates that every bold requirement ID declared in `docs/PRODUCT_REQUIREMENTS.md` has an exact-match row with a non-gap verifying-test entry in `docs/REQUIREMENTS_TRACEABILITY.md`. It is designed to avoid substring collisions like `FR-007` versus `BB-FR-007`.

### `scripts/check_compliance.sh`
Checks whether an adopting repository includes the governance files the constitution expects. It reports:

- **Required** files such as `README.md`, `HELP.md`, `CHANGELOG.md`, `TODO.md`, `SECURITY.md`, `AGENTS.md`, `CLAUDE.md`, `VERSION`, and the `constitution/` submodule
- **Recommended** files such as `docs/SETUP.md`, `docs/COMMAND_REFERENCE.md`, `docs/TROUBLESHOOTING.md`, `docs/OPERATIONS.md`, and `docs/TEST_PLAN.md`
- **Product-facing** files such as `docs/PRODUCT_REQUIREMENTS.md` and `docs/REQUIREMENTS_TRACEABILITY.md`

### Test coverage for governance tooling
The repository tests the bootstrap and checker scripts with shell-based regression suites including negative cases:

- `scripts/test_bootstrap.sh`
- `scripts/test_check_traceability.sh`
- `scripts/test_check_compliance.sh`
- `scripts/test_audit_adopters.sh`
- `scripts/test_release_docs.sh`

## Templates and examples

### Templates
`templates/` is the payload that gets installed into adopting repositories. Notable groups include:

- Agent bridge files such as `.agent-instructions.md`, `.openhands_instructions`, `.goosehints`, `.project-rules.md`, and `SYSTEM_PROMPT.md`
- Project governance files such as `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `HELP.md`, `README.md`, `SECURITY.md`, `TODO.md`, `CHANGELOG.md`, and `VERSION`
- Documentation scaffolds under `templates/docs/`, including `SETUP.md`, `COMMAND_REFERENCE.md`, `TROUBLESHOOTING.md`, `ARCHITECTURE.md`, `OPERATIONS.md`, `TEST_PLAN.md`, `PRODUCT_REQUIREMENTS.md`, `REQUIREMENTS_TRACEABILITY.md`, and `MVP_BACKLOG.md`
- GitHub automation under `templates/.github/`, including Copilot instructions, Dependabot configuration, and workflow templates

### Example project
`examples/sample-project/` demonstrates the structure a bootstrapped repository is expected to have: top-level governance docs, a `constitution/` submodule, `docs/`, `src/`, and editor/assistant-specific configuration directories such as `.github/` and `.cursor/`.

## MCP server

The `mcp-server/` directory is a minimal Node.js module using `@modelcontextprotocol/sdk`. It exposes:

- Resources for the core constitution, AI workflow, and testing standards
- A `validate_project_structure` tool that checks whether a target project contains `AGENTS.md`, `CHANGELOG.md`, `TODO.md`, and `VERSION`

## Versioning and recent direction

The current framework version in `README.md` and `CONSTITUTION.md` is `1.28.0`. Recent releases have focused on:

- A `sources/` drop-in location for book/reference sources with change detection and distilled summaries, surfaced to agents via the MCP server (`check_source_summaries.sh`, `KNOWLEDGE_SOURCES.md`, `mcp-server/index.js`)
- Requiring agents to evaluate whether accumulated work should trigger a release, not just update `CHANGELOG.md`'s `Unreleased` section indefinitely (`AI_WORKFLOW.md`, `CONSTITUTION.md` Principle 10)
- Required review of other branches, worktrees, and open pull requests before starting work, and merge-before-delete Git cleanup discipline, in `AI_WORKFLOW.md`
- A checker that catches stale adopter-facing version references after a submodule bump (`check_version_alignment.sh`)
- Compliance checking and CI gates
- Requirements traceability enforcement
- Automated constitution version drift detection for adopters
- Worked operations documentation examples
- Editor/tooling bootstrap support for Continue.dev, Aider, pre-commit, and devcontainers

## See also

- [[Getting Started]]
- [[Bootstrap Script]]
- [[Governance Checkers]]
- [[Templates and Examples]]
- [[MCP Server]]
- [[Standards Overview]]
