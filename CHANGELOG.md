# Changelog

All notable user-facing changes to Eric's Engineering Constitution Framework are documented in this file.

This project follows semantic versioning.

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
