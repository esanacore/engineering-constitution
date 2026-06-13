# Integration Guide

This guide explains how AI agents should read and apply Eric's Engineering Constitution, how project-specific rules override universal rules, and how to keep projects up to date as the constitution evolves.

For setup instructions, see [README.md](README.md).

## How Agents Should Read and Apply the Constitution

### Reading Order

1. Read `AGENTS.md` — the project entry point. It defines what to read and any local overrides.
2. Read `constitution/CONSTITUTION.md` — universal engineering principles.
3. Read `constitution/AI_WORKFLOW.md` — the required step-by-step workflow.
4. Read `README.md`, `TODO.md`, `CHANGELOG.md` — project context.

### Application

Agents follow the workflow in `constitution/AI_WORKFLOW.md` and the principles in `constitution/CONSTITUTION.md` for every task. When there is a conflict between a universal rule and a project-specific rule, the project-specific rule wins.

Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/project.mdc`, `.goosehints`) load automatically for each respective agent. They point to the constitution and add any project-level context the agent needs.

## Project-Specific Rules and Overrides

The constitution provides universal defaults. Each project can override or extend them in its local files.

### Override Locations by Agent

| Agent | File |
|---|---|
| Any / Generic | `AGENTS.md` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/project.mdc` |
| Goose / Goosetown | `.goosehints` |

### What to Override

Good candidates for project-specific rules:

- Language and runtime requirements (e.g., "Use Python 3.12+. Always use type hints.")
- Framework conventions (e.g., "Use FastAPI dependency injection for all handlers.")
- Test commands (e.g., "Run `make test` to verify changes.")
- Required file updates (e.g., "Update the OpenAPI spec for all API changes.")
- Monorepo scoping (e.g., "Only modify files under `services/payments/`.")
- Deployment constraints (e.g., "All infrastructure changes go through Terraform.")

### What Not to Override

Avoid overriding the core workflow principles unless the project has a genuine reason. Consistent behavior across all projects is the main benefit of the framework.

### Override Example

In `.github/copilot-instructions.md`, add a `## Project-Specific Rules` section after the constitution defaults:

```markdown
## Project-Specific Rules

- This project uses Python 3.12. Always use type hints.
- Run `make test` before considering any change complete.
- All database schema changes require a migration file in `migrations/`.
- Record architectural decisions in `docs/adr/` using the ADR template.
```

The same pattern applies to `AGENTS.md`, `CLAUDE.md`, and `.cursor/rules/project.mdc`.

## Goose and Goosetown

[Goose](https://github.com/aaif-goose/goose) is an extensible AI agent, and [goosetown](https://github.com/aaif-goose/goosetown) orchestrates flocks of goose agents (researchers, workers, writers, reviewers) to build software in parallel. Because goosetown wraps the goose CLI, supporting goose automatically extends the constitution to goosetown's multi-agent runs.

### Hints File

The bootstrap script installs `.goosehints` in the project root. Goose loads this file automatically and applies the constitution's reading order and standards to every task. Add project-specific rules to `.goosehints` (or to `AGENTS.md`) the same way as for any other agent.

For goosetown specifically, the hints file instructs every agent in the flock — including the adversarial reviewers — to check changes against `constitution/TESTING.md`, `constitution/SECURITY.md`, and `constitution/DOCUMENTATION.md` before approving.

### MCP Extension (optional)

The constitution ships an MCP server at `constitution/mcp-server/`. Registering it as a goose stdio extension lets agents read constitution documents as resources and run the `validate_project_structure` tool.

Add it to your goose configuration (`~/.config/goose/config.yaml`):

```yaml
extensions:
  engineering-constitution:
    type: stdio
    cmd: node
    args:
      - constitution/mcp-server/index.js
    enabled: true
```

Or interactively, run `goose configure`, choose **Add Extension → Command-line Extension**, and use `node constitution/mcp-server/index.js`. Run `npm install` in `constitution/mcp-server/` first so the SDK dependency is available.

## Language-Specific Examples

### Node.js / TypeScript

In your project-specific rules, consider adding:

```markdown
- Use TypeScript with strict mode enabled.
- Prefer functional components and hooks for React code.
- Use `zod` for input validation.
- All new API endpoints must be documented in `openapi.yaml`.
- Run `npm run lint` and `npm test` before every commit.
```

### Python / FastAPI

In your project-specific rules, consider adding:

```markdown
- Use Python 3.11+.
- Use Pydantic v2 for data modeling.
- Follow PEP 8 style guidelines.
- Use `pytest` for all tests.
- All service methods must include docstrings following the Google style.
- Run `ruff check .` for linting.
```

## VERSION-Based Update Strategy

The `constitution/VERSION` file records the constitution version the project is currently pinned to. Projects pin the constitution at a specific commit via the submodule reference.

### Checking the Current Version

```bash
cat constitution/VERSION
```

### Updating to a New Version

```bash
cd /path/to/project
git submodule update --remote constitution
cat constitution/VERSION        # confirm expected version
cat constitution/CHANGELOG.md   # review what changed
git add constitution
git commit -m "Update Eric's engineering constitution to $(cat constitution/VERSION)"
```

### Reviewing Template Changes

After a constitution update, check whether your local project files need to be refreshed:

```bash
diff AGENTS.md constitution/templates/AGENTS.md
diff CLAUDE.md constitution/templates/CLAUDE.md
diff .github/copilot-instructions.md constitution/templates/.github/copilot-instructions.md
diff .cursor/rules/project.mdc constitution/templates/.cursor/rules/project.mdc
```

Merge any relevant changes manually, keeping your project-specific rules intact.

## Project File Structure

Every project using this constitution should eventually contain:

```text
project/
├── constitution/                          ← Git submodule (universal rules, read-only)
├── AGENTS.md                              ← Agent entry point (project rules + pointer to constitution)
├── CLAUDE.md                              ← Claude Code rules
├── .github/
│   └── copilot-instructions.md           ← GitHub Copilot rules
├── .cursor/
│   └── rules/
│       └── project.mdc                   ← Cursor rules
├── .goosehints                            ← Goose / Goosetown hints
├── TODO.md                                ← Living roadmap
├── CHANGELOG.md                           ← Release history
├── README.md                              ← Project documentation
└── docs/
    └── adr/                               ← Architecture Decision Records
```

The `constitution/` directory is managed by Git submodule. Never edit files inside it directly. Changes to universal rules belong in this constitution repository.
