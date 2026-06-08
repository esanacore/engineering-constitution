# Integration Guide

This guide explains how AI agents should read and apply the Engineering Constitution, how project-specific rules override universal rules, and how to keep projects up to date as the constitution evolves.

For setup instructions, see [README.md](README.md).

## How Agents Should Read and Apply the Constitution

### Reading Order

1. Read `AGENTS.md` — the project entry point. It defines what to read and any local overrides.
2. Read `constitution/CONSTITUTION.md` — universal engineering principles.
3. Read `constitution/AI_WORKFLOW.md` — the required step-by-step workflow.
4. Read `README.md`, `TODO.md`, `CHANGELOG.md` — project context.

### Application

Agents follow the workflow in `constitution/AI_WORKFLOW.md` and the principles in `constitution/CONSTITUTION.md` for every task. When there is a conflict between a universal rule and a project-specific rule, the project-specific rule wins.

Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/project.mdc`) load automatically for each respective agent. They point to the constitution and add any project-level context the agent needs.

## Project-Specific Rules and Overrides

The constitution provides universal defaults. Each project can override or extend them in its local files.

### Override Locations by Agent

| Agent | File |
|---|---|
| Any / Generic | `AGENTS.md` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| Cursor | `.cursor/rules/project.mdc` |

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
git commit -m "Update engineering constitution to $(cat constitution/VERSION)"
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
├── TODO.md                                ← Living roadmap
├── CHANGELOG.md                           ← Release history
├── README.md                              ← Project documentation
└── docs/
    └── adr/                               ← Architecture Decision Records
```

The `constitution/` directory is managed by Git submodule. Never edit files inside it directly. Changes to universal rules belong in this constitution repository.
