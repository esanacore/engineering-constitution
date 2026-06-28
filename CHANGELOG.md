# Changelog

All notable user-facing changes to Eric's Engineering Constitution Framework are documented in this file.

This project follows semantic versioning.

## Unreleased

### Added

- Added `scripts/test_release_docs.sh`, a regression check that fails when the published version references in `README.md`, `CONSTITUTION.md`, and `wiki/Home.md` drift from the root `VERSION` file.

### Fixed

- Corrected the stale `1.20.0` version references in `README.md` and `wiki/Home.md` to match the released framework version `1.22.0`.

## 1.22.0 - 2026-06-27

### Added

- Added Continue.dev template at `templates/.continue/config.json`. The bootstrap script installs it into every adopted repository, setting a system message that loads the constitution reading order and workflow for in-editor AI sessions.
- Added Aider templates: `templates/.aider.conf.yml` (disables auto-commits, loads constitution files as read-only context) and `templates/.aiderignore` (prevents aider from modifying the read-only `constitution/` submodule). Both are installed by `scripts/bootstrap.sh`.
- Added `templates/.pre-commit-config.yaml` with a language-agnostic baseline of pre-commit hooks (trailing whitespace, end-of-file fixer, YAML/JSON syntax checking, merge-conflict marker detection, large-file guard, and private-key detection). Installed by `scripts/bootstrap.sh`.
- Added `templates/.devcontainer/devcontainer.json` providing a reproducible Ubuntu 24.04 development container with Node.js, Git, and VS Code extensions for Copilot and Continue.dev. Runs `git submodule update --init --recursive` on container creation so the constitution submodule is always ready. Installed by `scripts/bootstrap.sh`.
- Added Continue.dev and Aider to the "Override Locations by Agent" table in `INTEGRATION.md`.
- Added dedicated sections to `INTEGRATION.md` for Continue.dev, Aider, Pre-Commit Hooks, and Devcontainer, each covering configuration, customization examples, and language-specific override patterns.
- Added "Migrating Existing Repositories to New Framework Versions" section to `INTEGRATION.md` with a five-step checklist (read changelog → diff templates → copy new files → run new tool-setup steps → commit) so existing adopters can pick up new framework features after merging a Dependabot constitution update PR.
- Updated the Project File Structure diagram in `INTEGRATION.md` to include the new files.

### Changed

- `scripts/bootstrap.sh` now installs `.continue/config.json`, `.aider.conf.yml`, `.aiderignore`, `.pre-commit-config.yaml`, and `.devcontainer/devcontainer.json`, and reports their status in the adoption report.
- Adoption report "Recommended Tool Setup" section now includes the pre-commit activation command and MCP server prep step alongside the existing gstack instructions.
- `INTEGRATION.md` "Application" paragraph updated to name the full set of tool-specific files that load automatically.

## 1.21.0 - 2026-06-27

### Added

- Added gstack and gbrain setup to the framework. `templates/CLAUDE.md` now includes a `## gstack` section with the full skills list and the rule to always use `/browse` for web browsing instead of `mcp__claude-in-chrome__*` tools. This section propagates to every adopted repository via `scripts/bootstrap.sh`, so all projects inherit gstack conventions automatically.
- Added a "gstack and gbrain" section to `INTEGRATION.md` covering installation, gbrain initialization via `/setup-gbrain`, the required browser-automation conventions, the skill reference table, and goosetown integration guidance.
- Added a "Recommended Tool Setup" section to the `scripts/bootstrap.sh` adoption report, instructing adopters to run `/setup-gbrain` and `/setup-deploy` in Claude Code after completing the merge steps.

### Changed

- `AI_WORKFLOW.md` "During Work" section now explicitly requires using the `/browse` gstack skill for all web browsing and prohibits direct `mcp__claude-in-chrome__*` tool calls.

## 1.20.0 - 2026-06-27

### Added

- Added `examples/OPERATIONS.example.md`, a fully worked `docs/OPERATIONS.md` runbook for a fictional deployed service ("Orders API"). It fills in every section the blank template leaves as a placeholder — environments and promotion path, toolchain prerequisites, deployment procedure with approvals and rollback, monitoring/alert thresholds, backup and restore (with a restore drill), maintenance mode, expand/contract migrations, secrets and rotation, dependency failure behavior, and an incident-response runbook with severities, on-call, and common runbooks.

### Changed

- Referenced the worked operations example from `OPERATIONS.md`, `DOCUMENTATION.md`, the blank `templates/docs/OPERATIONS.md`, and the `README.md` repository contents so adopters can find a complete model when populating their own runbook.

## 1.19.0 - 2026-06-27

### Added

- Added `templates/.github/workflows/constitution-compliance.yml`, a CI gate that `scripts/bootstrap.sh` now installs into every adopted repository. It runs `constitution/scripts/check_compliance.sh` to confirm the required governance files are present and `constitution/scripts/check_traceability.sh` to confirm every declared requirement has a verifying test (the traceability step runs only when `docs/PRODUCT_REQUIREMENTS.md` and `docs/REQUIREMENTS_TRACEABILITY.md` exist, so non-product repositories are not forced to maintain them). Runs on pull requests, pushes to the default branch, and a daily schedule. This turns the two checkers from on-demand tools into enforced gates, alongside the existing version gate.

### Changed

- `scripts/bootstrap.sh` installs the compliance workflow and records it in the adoption report; `scripts/test_bootstrap.sh` verifies it is installed.
- Documented the compliance gate workflow in the `INTEGRATION.md` "Verifying Adoption Compliance" section.

## 1.18.0 - 2026-06-27

### Added

- Added `scripts/check_compliance.sh`, a reference checker that verifies an adopting repository carries the governance files the constitution expects. It checks three tiers — required (the `DOCUMENTATION.md` "Required Files" plus the adoption markers `AGENTS.md`, `CLAUDE.md`, `VERSION`, and the `constitution/` submodule), recommended (the "Strongly Encouraged" files), and product-facing (`docs/PRODUCT_REQUIREMENTS.md`, `docs/REQUIREMENTS_TRACEABILITY.md`) — and exits non-zero on a missing required file. `--strict` promotes recommended gaps to failures and `--product` promotes product-facing gaps to failures. Adopters run it from their repository root through the `constitution/` submodule.
- Added `scripts/test_check_compliance.sh` with positive and negative cases per the "Governance Tooling Must Be Tested" standard, including a missing required file, a missing `constitution/` submodule directory, recommended-tier warn-vs-strict behavior, product-facing warn-vs-`--product` behavior, and usage errors.

### Changed

- Added a "Verifying Adoption Compliance" section to `INTEGRATION.md` describing how to run the compliance checker through the submodule and noting that the constitution source repository is intentionally not a self-compliant target.
- Noted the compliance checker alongside the traceability checker in the `TESTING.md` "Governance Tooling Must Be Tested" standard.

## 1.17.0 - 2026-06-27

### Added

- Added `scripts/check_traceability.sh`, a reference requirements-traceability checker that confirms every requirement ID declared in `docs/PRODUCT_REQUIREMENTS.md` has a non-empty verifying-test entry in `docs/REQUIREMENTS_TRACEABILITY.md`. It matches IDs by exact matrix-cell value (never by substring) so a layered ID such as `BB-FR-007` cannot satisfy a check for the system-layer `FR-007`, parses each table by its own header columns so an unrelated table (for example the Coverage Summary) is not read as requirements, and exits non-zero when any requirement is missing a row or has only a gap entry. Adopters run it through the `constitution/` submodule.
- Added `scripts/test_check_traceability.sh` with positive and negative cases per the "Governance Tooling Must Be Tested" standard, including the `BB-FR-007` / `FR-007` substring-collision case, gap-marker and unfilled-placeholder detection, the layered-ID independence case, multi-table parsing, and usage errors.

### Changed

- Pointed the "Governance Tooling Must Be Tested" standard in `TESTING.md` at the shipped `scripts/check_traceability.sh` as the worked reference implementation.
- Added a "Verifying the Flow Automatically" subsection to the `INTEGRATION.md` traceability flow describing how to run the checker through the submodule and gate CI on it.

## 1.16.0 - 2026-06-24

### Added

- Added a **Threat Modeling Triggers** section to `SECURITY.md` enumerating concrete changes that mandate a threat model (new egress path, new auth/authz surface, new data leaving the boundary, new trust-sensitive dependency, new untrusted-input sink). Added a matching checklist item to `templates/SECURITY.md` so adopters inherit the trigger.
- Added a **Toolchain Parity** standard to `OPERATIONS.md` requiring repositories to pin their toolchain, declare minimum tool versions, and provide a fast prerequisite check (for example, `make doctor`) that fails fast with a clear message. Enriched `templates/docs/SETUP.md` with a "Verify Prerequisites" step.
- Added a **Binary Assets and Images** section to `DOCUMENTATION.md`: render-inline images are committed as normal web-optimized blobs (large originals go to LFS), with a `.gitattributes` LFS override and explicit verification (`git lfs ls-files` / `git lfs fsck`) before a push is considered complete.
- Added a **Governance Tooling Must Be Tested** section to `TESTING.md` requiring reference checkers and gates to ship unit tests including negative cases, with the traceability-checker substring-collision case called out.
- Added a **Requirement ID Grammars Must Not Collide** subsection and a dedicated **Architecture Decision Records** section to `DOCUMENTATION.md` documenting the ADR status lifecycle, relationships, and promotion criteria.
- Added a **Repository Settings Checklist** to `INTEGRATION.md` (enable "Automatically delete head branches", default-branch protection, Dependabot submodule PRs); the bootstrap adoption report now recommends these settings.

### Changed

- Enriched `templates/ADR.md` with a `Proposed → Accepted → Superseded/Deprecated` status lifecycle, a `Relationships` field (`extends` / `supersedes` / `related`), and a `Promotion Criteria` section for `Proposed` ADRs. Updated `CONSTITUTION.md` Principle 6 and the sample-project ADR to match.
- Corrected the stale `CONSTITUTION.md` version header (was `1.12.0`) and the `README.md` version display to track the released `VERSION`.

## 1.15.0 - 2026-06-13

### Added

- Added automated constitution version enforcement so adopting repositories stay on the latest release. `scripts/bootstrap.sh` now installs two templates into every project:
  - `.github/workflows/constitution-version.yml` — a CI gate that runs on pull requests, pushes to the default branch, and a daily schedule, and **fails the build** when the pinned `constitution/` submodule is behind the latest `v*` release tag.
  - `.github/dependabot.yml` — a `gitsubmodule` Dependabot configuration that opens a pull request whenever the constitution submodule falls behind, scoped to the `constitution` submodule.
- Added `scripts/audit_adopters.sh`, a fleet audit that scans parent directories and reports each adopting repository as `CURRENT`, `BEHIND`, or `AHEAD/DIVERGED`, exiting non-zero when any repository is behind so it can drive a centralized check.
- Added `scripts/test_audit_adopters.sh` covering the current, behind, and non-adopter cases and the script's exit status.
- Added a "Keeping Adopters On the Latest Version Automatically" section to `INTEGRATION.md` describing the auto-update, CI gate, and audit layers.

### Changed

- Added a "Git Tags" rule to `RELEASES.md` requiring every release to be tagged `vMAJOR.MINOR.PATCH`; the CI gate and audit script compare adopters against the latest release tag.
- `scripts/test_bootstrap.sh` now verifies the Dependabot config and version-check workflow are installed.

## 1.14.0 - 2026-06-13

### Added

- Added an "Example Traceability Flow" section to `INTEGRATION.md` showing the concrete path from a product requirement ID through the traceability matrix, test plan coverage gaps, the verifying test, and a TODO follow-up. Salvaged from the abandoned `codex/constitution-traceability-docs` branch (the obsolete README version edit it also carried was dropped).

## 1.13.0 - 2026-06-13

### Added

- Added Goose / Goosetown integration. `scripts/bootstrap.sh` now installs a `.goosehints` bridge file in every adopted repository so the [goose](https://github.com/aaif-goose/goose) agent — and the [goosetown](https://github.com/aaif-goose/goosetown) multi-agent orchestrator that wraps it — apply the constitution's reading order and standards on every task.
- Added a "Goose and Goosetown" section to `INTEGRATION.md` covering the `.goosehints` hints file, multi-agent reviewer expectations, and how to register the constitution MCP server (`mcp-server/`) as a goose stdio extension.
- Added `.goosehints` coverage to `scripts/test_bootstrap.sh`.

### Changed

- Added Goose / Goosetown to the agent override table, the auto-loading tool-file list, and the project file structure tree in `INTEGRATION.md`.

## 1.12.0 - 2026-06-13

### Added

- Standardized the "Eric's Engineering Constitution" adoption badge as part of the framework. `scripts/bootstrap.sh` now adds or refreshes the badge in every adopted repository's `README.md`, including existing READMEs that are otherwise preserved.
- Added idempotent badge handling using stable `<!-- CONSTITUTION_START -->` / `<!-- CONSTITUTION_END -->` markers: the badge is inserted after the first heading (or prepended when there is no heading), refreshed in place on re-runs, and never duplicated.
- Added a "Files Updated In Place" section to the bootstrap adoption report so badge updates to existing files are recorded.
- Added `scripts/test_bootstrap.sh` coverage for badge injection, idempotency, and the no-heading case.

### Changed

- The README badge link is derived from the bootstrap source URL when it is a public Git URL, falling back to the canonical repository otherwise.

## 1.11.0 - 2026-06-13

### Added

- Added continuous coverage evaluation, coverage targets, and coverage gap analysis guidance to `TESTING.md`.
- Added requirements traceability guidance to `DOCUMENTATION.md`, including stable requirement identifiers and explicit acceptance criteria.
- Added `docs/TEST_PLAN.md` template with coverage targets, a continuous coverage record, and a coverage gap log.
- Added `docs/REQUIREMENTS_TRACEABILITY.md` template providing a requirement-to-test traceability matrix.

### Changed

- `docs/PRODUCT_REQUIREMENTS.md` template now uses numbered requirement IDs (`FR-`/`NFR-`), per-requirement acceptance criteria, and links to the traceability matrix.
- Strengthened `CONSTITUTION.md` Principles 1 and 2 to require requirements traceability and continuous coverage evaluation.
- Added coverage-gap and traceability steps to `AI_WORKFLOW.md` and the `CLAUDE.md` completion checklists.
- `scripts/bootstrap.sh` now installs the test plan and requirements traceability templates.

## 1.10.0 - 2026-06-12

### Added

- Added framework-level operations and infrastructure standards in `OPERATIONS.md`.
- Added optional product requirements and MVP backlog documentation guidance.
- Added `docs/PRODUCT_REQUIREMENTS.md` and `docs/MVP_BACKLOG.md` templates for product-facing repositories.

### Changed

- Promoted operations review into the Constitution workflow and documentation expectations.
- Updated `CONSTITUTION.md`, `AI_WORKFLOW.md`, `DOCUMENTATION.md`, and `AGENTS.md` to make operational guidance part of the standard review path.
- Updated the sample project and operations template to reflect the new standards.
- Corrected the README version display to match `VERSION`.

## 1.9.0 - 2026-06-11

### Changed

- Rebranded the framework to **Eric's Engineering Constitution**.
- Updated all documentation, templates, and scripts to reflect the new name.
- Simplified `README.md` templates by replacing the dedicated "Engineering Constitution" section with a minimal badge/link at the top of the file.

## 1.8.1 - 2026-06-11

### Fixed

- Cleaned up `DevLaunchpad` repository by ignoring `.constitution-bootstrap/` and resetting submodule state.
- Documented the `version_analyzer.sh` tool in `RELEASES.md`.

## 1.8.0 - 2026-06-11

### Added

- Added `scripts/version_analyzer.sh` to help determine retroactive and proactive Semantic Version bumps based on project history.

## 1.7.0 - 2026-06-10

### Added

- Mandated **Semantic Versioning (SemVer)** for all projects in `CONSTITUTION.md`.
- Added a standard `VERSION` file template (initialized at `0.1.0`).
- Updated `bootstrap.sh` to install the `VERSION` file in all repositories by default.
- Enhanced `RELEASES.md` with explicit instructions for managing the `VERSION` file.

## 1.6.1 - 2026-06-10

### Fixed

- Improved `templates/README.md` with explicit `<!-- CONSTITUTION_START -->` markers to prevent documentation pollution during manual merging.
- Cleaned up `DevLaunchpad` README to remove redundant headers and duplicate description lines.

## 1.6.0 - 2026-06-10

### Added

- Added generic fallback and open-source agent bridge files: `.project-rules.md`, `.openhands_instructions`, and `SYSTEM_PROMPT.md`.
- Updated `bootstrap.sh` to install these files by default, completing the "Universal Instruction Bridge".

## 1.5.0 - 2026-06-10

### Added

- Added expanded universal discoverability: `.antigravity/instructions.md` (for Antigravity 2.0) and `CONTRIBUTING.md` (standard agent/human onboarding).
- Updated `bootstrap.sh` to install these new bridge files by default.

### Changed

- Renamed the "Universal Agent Discoverability" strategy to the "Universal Instruction Bridge" to reflect its multi-tool coverage.

## 1.4.0 - 2026-06-10

### Added

- Added universal agent discoverability files: `.agent-instructions.md` (for Devin, Gemini, etc.) and `.cursorrules` (for Cursor/legacy).
- Updated `bootstrap.sh` to install these universal entry points by default.

### Changed

- Updated `AGENTS.md` and other instruction files to be more assertive about the constitution's authority.

## 1.3.0 - 2026-06-10

### Added

- Added new standard documentation templates: `HELP.md`, `SECURITY.md`, `docs/SETUP.md`, `docs/COMMAND_REFERENCE.md`, `docs/TROUBLESHOOTING.md`, `docs/ARCHITECTURE.md`, `docs/AGENT_PROMPTS.md`, `docs/AGENT_HANDOFF.md`, and `docs/OPERATIONS.md`.
- Updated `bootstrap.sh` to automatically install these new templates in all repositories.
- Updated `DOCUMENTATION.md` to reflect the expanded documentation requirements.

### Changed

- `bootstrap.sh` now creates the `docs/` directory and populates it with standard templates by default.

## 1.2.0 - 2026-06-10

### Added

- Added automated test suite for `scripts/bootstrap.sh` in `scripts/test_bootstrap.sh`.
- Added migration guidance for existing project documentation to `DOCUMENTATION.md`.
- Added language-specific override examples (Node.js/TypeScript, Python/FastAPI) to `INTEGRATION.md`.

### Changed

- Updated `scripts/bootstrap.sh` to allow the `file` protocol for git submodules, supporting local repository sources.
- Rewrote README.md to eliminate repetitive install sections and clarify setup flow.
- Removed duplicate "Required Workflow" list and "Repository Integration Strategy" from CONSTITUTION.md; both are now covered in AI_WORKFLOW.md and README.md/INTEGRATION.md.

### Fixed

### Removed

### Security

## 1.1.0 - 2026-06-08

### Added

- Added `templates/.github/copilot-instructions.md` for GitHub Copilot auto-loading via the standard `.github/` location.
- Added `templates/.cursor/rules/project.mdc` for Cursor auto-loading with `alwaysApply: true` frontmatter.
- Added `INTEGRATION.md` documenting agent reading order, project-specific override patterns, VERSION-based update strategy, and project file structure.
- Updated bootstrap script to install `.github/copilot-instructions.md` and `.cursor/rules/project.mdc` instead of root-level `COPILOT_INSTRUCTIONS.md`.
- Updated sample project to include `.github/copilot-instructions.md` and `.cursor/rules/project.mdc`.

### Changed

- `scripts/bootstrap.sh` now creates `.github/copilot-instructions.md` (GitHub Copilot standard location) and `.cursor/rules/project.mdc` (Cursor standard location) instead of the generic root-level `COPILOT_INSTRUCTIONS.md`.
- README updated to reflect new template files and project structure.
- AGENTS.md updated to include `INTEGRATION.md` in the required reading list.
- VERSION bumped to 1.1.0.

### Fixed

### Removed

### Security

## 1.0.0 - 2026-06-08

### Added

- Added Eric's Engineering Constitution Framework v1.0.0.
- Added AI workflow, testing, documentation, security, architecture, release, and TODO guidance.
- Added project templates for agent instructions, TODO, changelog, README, and ADRs.
- Added sample project structure.
- Added bootstrap script for integrating the constitution into existing Git repositories.

### Changed

### Fixed

### Removed

### Security

- Added security review standards covering validation, secrets, permissions, dependencies, logging, and auditing.
