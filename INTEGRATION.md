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

Tool-specific files (`CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules/project.mdc`, `.goosehints`, `.continue/config.json`, `.aider.conf.yml`) load automatically for each respective agent. They point to the constitution and add any project-level context the agent needs.

## Project-Specific Rules and Overrides

The constitution provides universal defaults. Each project can override or extend them in its local files.

### Override Locations by Agent

| Agent | File |
|---|---|
| Any / Generic | `AGENTS.md` |
| Claude Code | `CLAUDE.md` |
| GitHub Copilot | `.github/copilot-instructions.md` |
| GitHub Copilot custom agent (Solon) | `.github/agents/solon.agent.md` |
| Cursor | `.cursor/rules/project.mdc` |
| Goose / Goosetown | `.goosehints` |
| Continue.dev | `.continue/config.json` |
| Aider | `.aider.conf.yml` |

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

## GitHub Copilot Custom Agent (Solon)

In addition to the repository-wide `.github/copilot-instructions.md`, the
bootstrap script installs a named GitHub Copilot **custom agent** at
`.github/agents/solon.agent.md`. **Solon** is a constitution-aware persona that
reviews and guides changes against the constitution's principles and workflow.

Custom agents are Markdown files with YAML frontmatter (`name`, `description`,
optional `model` and `tools`) stored under `.github/agents/`. They require
Visual Studio 2026 version 18.4 or later (or a current Copilot client that
supports custom agents).

### Using Solon

- In Copilot Chat, type `@Solon` followed by your request (for example,
  `@Solon Review my changes against the constitution`), or select **Solon** from
  the agent-picker dropdown.
- To make Solon available across **all** your projects regardless of which repo
  is open, copy the file to the user-level location `%USERPROFILE%/.github/agents/`
  (configurable under **Tools > Options > GitHub > Copilot**).

### Customizing Solon

Edit the Markdown body of `.github/agents/solon.agent.md` to add project-specific
review rules, or adjust the `tools` array to match the tool names available in
your Copilot client (click the **Tools** icon in Copilot Chat to see them). Tool
names can vary across Copilot platforms, so verify them before relying on the
agent in CI-adjacent workflows.

## Goose and Goosetown

[Goose](https://github.com/aaif-goose/goose) is an extensible AI agent, and [goosetown](https://github.com/aaif-goose/goosetown) orchestrates flocks of goose agents (researchers, workers, writers, reviewers) to build software in parallel. Because goosetown wraps the goose CLI, supporting goose automatically extends the constitution to goosetown's multi-agent runs.

Both repos live under the `aaif-goose` GitHub org (renamed from `block`;
old `block/...` URLs still redirect, but their own READMEs haven't all been
updated — use `aaif-goose/...` directly). Neither ships with an adopting
repo or with this framework; install them on the machine that will run them.

The fastest path is this repository's own installer, run once per
machine (not per repo — see "Provisioning a Machine in One Step" below):

```bash
bash scripts/setup-machine.sh --skip-gstack
```

Or by hand:

```bash
# goose CLI (required by goosetown too)
curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash

# goosetown (multi-agent orchestration), requires goose v1.25.0+
git clone https://github.com/aaif-goose/goosetown.git
cd goosetown && ./goose
```

`templates/.goosehints` (installed into every adopting repo by
`scripts/bootstrap.sh`) carries this same install block so agents that read
it can self-diagnose a missing install rather than silently failing.

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

## gstack and gbrain

[gstack](https://github.com/garrytan/gstack) (Garry Tan, MIT license) is a browser automation and AI skill toolkit for Claude Code. It ships a library of slash-command skills — `/browse`, `/qa`, `/design-review`, `/ship`, `/review`, `/document-release`, and more — that Claude Code invokes directly. gbrain is gstack's persistent project-memory layer; once initialized in a repository, Claude Code can store and recall project context across sessions.

### Installing gstack

Requires [Bun](https://bun.sh) v1.0+ (`curl -fsSL https://bun.sh/install | bash` if `bun --version` fails) and Git.

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

Or run `bash scripts/setup-machine.sh --skip-goose --skip-goosetown` — see
"Provisioning a Machine in One Step" below, which also handles the
Playwright fallback described next automatically.

Once installed, its skills appear automatically in Claude Code — no restart
observed to be necessary, but if a freshly-installed skill doesn't show up,
start a new session.

For repos this framework bootstraps, `templates/CLAUDE.md` already carries
an install-verification block (`test -d ~/.claude/skills/gstack/bin`) plus
this same install command, so an agent working in an adopted repo can
self-install rather than silently skipping `/browse` and friends.

**Known gap on very new Linux distros**: gstack's `./setup` downloads a
Playwright-managed Chromium for `/browse` and other browser-driving skills.
If your distro is newer than Playwright has added to its support matrix,
that download fails with `Playwright does not support chromium on
<distro>-x64`. Work around it with a same-family fallback build:

```bash
cd ~/.claude/skills/gstack/browse
PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 bunx playwright install chromium chromium-headless-shell
```

Adjust the override to whatever LTS Playwright's own error message says it
does support — this is a Playwright-support-matrix lag, not a gstack bug,
so the right target version will change over time.

### Provisioning a Machine in One Step

`scripts/setup-machine.sh` installs Bun, gstack, goose, and goosetown in
one run. It is **not** called by `scripts/bootstrap.sh` — bootstrapping a
repository only ever writes files (see "Repository Settings Checklist"
below for the same separation-of-concerns reasoning applied to host
settings); provisioning a machine's global AI-agent toolchain is a
different, explicitly human-triggered action, run once per machine rather
than once per adopted repository.

```bash
bash scripts/setup-machine.sh
```

It's idempotent (safe to re-run; each tool is skipped if already present),
detects and works around the Playwright too-new-distro gap automatically,
and supports `--skip-bun`, `--skip-gstack`, `--skip-goose`,
`--skip-goosetown` plus environment overrides for install locations and
source URLs — see the script's own header comment for the full list. Its
test suite (`scripts/test_setup_machine.sh`) exercises every install path
against local fixtures, never the real network, per `TESTING.md`
"Governance Tooling Must Be Tested."

### Initializing gbrain

After bootstrapping a new project, run `/setup-gbrain` once inside Claude Code from the project root:

```
/setup-gbrain
```

This creates the project-level memory infrastructure that gstack uses to persist context across Claude Code sessions. Re-running it is safe.

### Required gstack Conventions

Every adopted repository must follow these conventions, enforced by `CLAUDE.md`:

- **Use `/browse` for all web browsing.** Never call `mcp__claude-in-chrome__*` tools directly — gstack wraps them with safety guardrails and session management.
- Use gstack skills whenever a skill covers the task:

| Task | Skill |
|---|---|
| Browse a web page | `/browse` |
| Full QA run | `/qa` |
| Visual / design review | `/design-review` |
| Ship a change | `/ship` |
| Review a GitHub PR | `/review` |
| Configure deployment | `/setup-deploy` |
| Post-ship release docs | `/document-release` |
| Generate missing docs | `/document-generate` |
| Investigate a problem | `/investigate` |

### Integration with Goosetown

Goosetown worker agents can invoke gstack skills the same way Claude Code does. Add gstack skill calls to worker prompts to enable browser-based research, QA, and deployment steps within multi-agent pipelines. Every goosetown agent is bound by the `.goosehints` file, which already instructs agents to follow this constitution; add a `## gstack` section to `.goosehints` with any project-specific gstack conventions.

## Continue.dev

[Continue.dev](https://continue.dev) is an open-source AI coding assistant for VS Code and JetBrains. The bootstrap script installs `.continue/config.json` in the project root. Continue loads this file automatically and applies the constitution's system message to every in-editor AI session.

### Customizing Continue.dev

Add project-specific context to `.continue/config.json` by extending the `systemMessage` field:

```json
{
  "systemMessage": "This repository follows Eric's Engineering Constitution ... Use Python 3.12 with type hints. Run `make test` before marking work complete."
}
```

The same override principles from the "Project-Specific Rules" section apply — keep the constitution baseline and append project rules.

## Aider

[Aider](https://aider.chat) is an AI pair-programming CLI. The bootstrap script installs `.aider.conf.yml` (which loads constitution files as read-only context and disables auto-commits to match the constitution workflow) and `.aiderignore` (which prevents aider from modifying the read-only `constitution/` submodule).

### Customizing Aider

Add project-specific options to `.aider.conf.yml`:

```yaml
# Language model override:
model: claude-opus-4-8

# Additional read-only context files:
read:
  - docs/ARCHITECTURE.md
  - docs/SETUP.md
```

## Pre-Commit Hooks

The bootstrap script installs `.pre-commit-config.yaml` with a universal baseline of hooks (trailing whitespace, end-of-file fixer, YAML/JSON syntax, merge-conflict markers, large-file guard, and private-key detection). Activate them once after bootstrapping:

```bash
pip install pre-commit && pre-commit install
```

### Adding Language-Specific Hooks

Append language hooks below the universal set. For example, for Python:

```yaml
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.0
    hooks:
      - id: ruff
      - id: ruff-format
```

For Node.js:

```yaml
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.57.0
    hooks:
      - id: eslint
```

## Devcontainer

The bootstrap script installs `.devcontainer/devcontainer.json` with a base Ubuntu 24.04 image, Node.js, Git, and VS Code extensions for Copilot and Continue.dev pre-installed. Opening the repository in VS Code or GitHub Codespaces will prompt to reopen in the container, giving every contributor (and any cloud agent) an identical, reproducible development environment.

Customize the base image and features for your stack. For example, for Python:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" },
    "ghcr.io/devcontainers/features/git:1": {}
  }
}
```

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
diff .github/agents/solon.agent.md constitution/templates/.github/agents/solon.agent.md
diff .cursor/rules/project.mdc constitution/templates/.cursor/rules/project.mdc
```

Merge any relevant changes manually, keeping your project-specific rules intact.

## Keeping Adopters On the Latest Version Automatically

Manual `git submodule update --remote` works, but it relies on someone
remembering to run it in every repository. To guarantee that adopting
repositories stay on the latest release, the framework ships three layers that
`scripts/bootstrap.sh` installs into every project:

1. **Auto-update pull requests** — `.github/dependabot.yml` (using the
   `gitsubmodule` ecosystem) makes GitHub open a pull request whenever the
   `constitution/` submodule falls behind the branch it tracks. The submodule
   moves forward without anyone running git commands by hand.
2. **A CI version gate** — `.github/workflows/constitution-version.yml` runs on
   every pull request, on pushes to the default branch, and on a daily schedule.
   It fetches the constitution's release tags and **fails the build** when the
   pinned submodule is behind the latest `v*` tag. This is the layer that
   enforces "latest at all times": a repository cannot stay green while stale.
3. **A fleet audit** — `scripts/audit_adopters.sh <parent-dir>` (in the
   constitution repository) scans every repository under one or more parent
   directories and reports which are `CURRENT`, `BEHIND`, or
   `AHEAD/DIVERGED`. It exits non-zero when any repository is behind, so it can
   also drive a centralized cron job.

```bash
# One-shot snapshot across all your checked-out repositories:
bash constitution/scripts/audit_adopters.sh --fetch ~/code ~/work
```

The CI gate compares against the latest **release tag**, not every commit on
`main`, so in-progress constitution work does not turn every adopter red — only
tagged releases do. See `constitution/RELEASES.md` for the tagging rule.

If a repository already has its own `.github/dependabot.yml`, the bootstrap
script preserves it and writes the constitution version to
`.constitution-bootstrap/templates/` for manual merging.

## Migrating Existing Repositories to New Framework Versions

When Dependabot opens a constitution submodule update PR, merging it bumps the submodule pointer but does **not** automatically update your local project files (like `CLAUDE.md`, `.goosehints`, or any newly added templates). After merging, follow this checklist to pick up everything the new version ships.

### Step 1 — Read the changelog

```bash
cat constitution/CHANGELOG.md
```

The changelog describes every template that changed and every new file the version adds. Read it before diffing.

### Step 2 — Diff changed templates

Compare each template the changelog mentions against your local copy:

```bash
diff CLAUDE.md constitution/templates/CLAUDE.md
diff AGENTS.md constitution/templates/AGENTS.md
diff .goosehints constitution/templates/.goosehints
diff .github/copilot-instructions.md constitution/templates/.github/copilot-instructions.md
diff .github/agents/solon.agent.md constitution/templates/.github/agents/solon.agent.md
diff .cursor/rules/project.mdc constitution/templates/.cursor/rules/project.mdc
diff .continue/config.json constitution/templates/.continue/config.json
diff .aider.conf.yml constitution/templates/.aider.conf.yml
diff .pre-commit-config.yaml constitution/templates/.pre-commit-config.yaml
```

Merge relevant sections manually, keeping your project-specific rules intact. The project-specific rule always wins over the universal default.

### Step 3 — Copy new template files

When the changelog adds a file your repository does not yet have, copy it directly:

```bash
# Example: picking up a new template file added in a framework update
cp constitution/templates/.devcontainer/devcontainer.json .devcontainer/devcontainer.json
```

Or re-run bootstrap with `--force` on specific files you want to regenerate, then restore your project-specific content.

### Step 4 — Run new tool-setup steps

When the changelog adds a new tool integration (like gbrain or pre-commit), run its one-time setup:

| New integration | One-time setup |
|---|---|
| gstack / gbrain | `/setup-gbrain` in Claude Code |
| pre-commit hooks | `pip install pre-commit && pre-commit install` |
| Devcontainer | Reopen in container in VS Code / Codespaces |
| MCP server | `npm install` in `constitution/mcp-server/`, then register (see "Goose and Goosetown") |

### Step 5 — Commit and push

```bash
git add constitution CLAUDE.md .goosehints  # add whichever files changed
git commit -m "Migrate to Eric's Engineering Constitution $(cat constitution/VERSION)"
git push
```

The CI version gate will turn green once the submodule pointer and your local templates are consistent.

## Repository Settings Checklist

Some hygiene is enforced by host-side repository settings, not by files in the repo. When adopting the constitution, configure these once on the hosting platform (for example, GitHub repository settings):

- **Enable "Automatically delete head branches."** After a pull request merges, the host deletes the merged feature branch server-side. This keeps `origin/*` free of stale merged branches regardless of whether a contributor or agent has permission to push branch deletions.
- **Protect the default branch** with required status checks (including the constitution version gate) and required review.
- **Enable Dependabot / submodule update PRs** so the pinned `constitution/` submodule stays current (the bootstrap script installs `.github/dependabot.yml`).

## Verifying Adoption Compliance

`scripts/audit_adopters.sh` answers "is the submodule current?"; the companion
`scripts/check_compliance.sh` answers "does this repository actually carry the
governance files the constitution expects?" Run it from an **adopting**
repository's root through the submodule:

```bash
# Defaults to the current directory; checks required, recommended, and
# product-facing files.
bash constitution/scripts/check_compliance.sh

# Treat recommended files as required, or enforce the product-facing docs:
bash constitution/scripts/check_compliance.sh --strict
bash constitution/scripts/check_compliance.sh --product
```

To catch stale adoption metadata after a Constitution bump, run the version
alignment checker as well:

```bash
bash constitution/scripts/check_version_alignment.sh
```

It compares `constitution/VERSION` to the optional repository-level
`CONSTITUTION_VERSION` file and scans common governance files (README, agent
instructions, setup/index docs, and `docs/governance/*.md`) for stale semantic
version references on Constitution-related lines.

It exits non-zero when a required file (or, in the matching strict mode, a
recommended or product-facing file) is missing, so it can run locally or as a CI
gate. Required entries are the constitution's mandated files plus the adoption
markers (`AGENTS.md`, `CLAUDE.md`, `VERSION`, and the `constitution/` submodule);
recommended and product-facing entries are reported as warnings by default.

Run it against an adopting project, not against this constitution source
repository — the source repository keeps its documents at the root and has no
`constitution/` submodule, so it is intentionally not a self-compliant target.

`scripts/bootstrap.sh` installs `.github/workflows/constitution-compliance.yml`
into every adopted repository, which runs both this compliance check and the
traceability check (the latter only when the product-facing documents exist) on
pull requests, pushes to the default branch, and a daily schedule. This is the
CI gate that turns the two checkers from on-demand tools into enforced ones,
alongside the version gate described above.

## Running the Adopter's Own Tests and Catching Doc Drift

Two more CI gates round out the enforcement layer, both installed by
`scripts/bootstrap.sh` and both following the same warn-by-default,
`--strict`-to-fail contract as the checkers above (see `TESTING.md`'s "CI
Enforcement" section for the full rationale):

- **`.github/workflows/constitution-tests.yml`** runs
  `constitution/scripts/run_declared_tests.sh`, which extracts and runs the
  "Full suite" command declared in `docs/TEST_PLAN.md`'s "How to Run Tests"
  section. The constitution can't know a project's language or runtime, so
  the template leaves a clearly marked spot for the adopter's own setup step
  (`actions/setup-node`, `actions/setup-python`, etc.) before the test-run
  step. Once a real command is declared, a failure there always fails the
  build — `--strict` only changes what happens when nothing is declared yet.
- **`.github/workflows/constitution-doc-freshness.yml`** runs
  `constitution/scripts/check_doc_freshness.sh` on pull requests, flagging a
  diff that changes source files without touching `README.md` or
  `CHANGELOG.md`. It's a blunt tripwire, not smart change detection — expect
  occasional false positives on pure refactors, which is exactly why it warns
  by default instead of failing.

## Sweeping for Secrets Before They're Pushed

`.github/workflows/constitution-secrets.yml` runs
`constitution/scripts/check_secrets.sh` on every push and pull request, plus a
daily schedule. Unlike the checkers above, a real hit here **always** fails
the build, with or without `--strict` — `--strict` only governs the separate
`.gitignore`-coverage recommendation (see `SECURITY.md`'s "Secrets Sweep"
section for what it looks for).

CI is the backstop, not the first line of defense: `scripts/bootstrap.sh`
also installs a local `pre-commit` hook bound to the `pre-push` stage
(`.pre-commit-config.yaml`), so the same sweep runs before every `git push`
from a machine that has run:

```bash
pip install pre-commit && pre-commit install && pre-commit install --hook-type pre-push
```

Run the sweep manually at any time with:

```bash
bash constitution/scripts/check_secrets.sh
bash constitution/scripts/check_secrets.sh --strict   # also enforce .gitignore coverage
```

## Example Traceability Flow

For product-facing repositories, keep one visible path from product intent to automated verification:

1. Add a stable requirement ID and acceptance criteria in `docs/PRODUCT_REQUIREMENTS.md`.
2. Mirror that ID in `docs/REQUIREMENTS_TRACEABILITY.md` with its current verification status.
3. Record repository-wide coverage targets and uncovered gaps in `docs/TEST_PLAN.md`.
4. Reference the requirement ID in the verifying automated test name, comment, or tag.
5. When a gap remains open, add a matching follow-up item in `TODO.md` under Testing.

Example:

```text
docs/PRODUCT_REQUIREMENTS.md      FR-012  Generate automation-blueprint.md
docs/REQUIREMENTS_TRACEABILITY.md FR-012  Partial  Tests pending
docs/TEST_PLAN.md                 GAP-003 Missing generator coverage
tests/test_processor_sop.py       FR-012  SOP artifact regression coverage
TODO.md                           Add explicit tests once generator exists
```

### Verifying the Flow Automatically

The framework ships `scripts/check_traceability.sh`, available through the
`constitution/` submodule, to confirm that every requirement ID declared in the
product requirements file has a verifying-test entry in the matrix. It matches
IDs by exact cell value, so a layered ID (for example `BB-FR-012`) never
satisfies a check for the system-layer `FR-012`.

```bash
# Defaults to docs/PRODUCT_REQUIREMENTS.md and docs/REQUIREMENTS_TRACEABILITY.md
bash constitution/scripts/check_traceability.sh

# Or pass explicit paths
bash constitution/scripts/check_traceability.sh docs/PRODUCT_REQUIREMENTS.md docs/REQUIREMENTS_TRACEABILITY.md
```

It exits non-zero when any requirement has no matrix row or only a gap entry, so
product-facing repositories can run it locally or wire it into CI as a gate
alongside the constitution version check.

## Project File Structure

Every project using this constitution should eventually contain:

```text
project/
├── constitution/                          ← Git submodule (universal rules, read-only)
├── AGENTS.md                              ← Agent entry point (project rules + pointer to constitution)
├── CLAUDE.md                              ← Claude Code rules (includes gstack skill list)
├── .github/
│   ├── copilot-instructions.md           ← GitHub Copilot rules
│   └── agents/
│       └── solon.agent.md                ← Copilot custom agent (Visual Studio 2026)
├── .cursor/
│   └── rules/
│       └── project.mdc                   ← Cursor rules
├── .continue/
│   └── config.json                       ← Continue.dev system message
├── .goosehints                            ← Goose / Goosetown hints
├── .aider.conf.yml                        ← Aider config (read-only context + no auto-commits)
├── .aiderignore                           ← Prevents aider from touching constitution/
├── .pre-commit-config.yaml               ← Pre-commit hooks (lint, format, secret detection)
├── .devcontainer/
│   └── devcontainer.json                 ← Reproducible dev environment
├── TODO.md                                ← Living roadmap
├── CHANGELOG.md                           ← Release history
├── README.md                              ← Project documentation
└── docs/
    └── adr/                               ← Architecture Decision Records
```

The `constitution/` directory is managed by Git submodule. Never edit files inside it directly. Changes to universal rules belong in this constitution repository.
