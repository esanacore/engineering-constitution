# Release Standards

Release discipline makes change understandable and recoverable.

## Semantic Versioning

Follow semantic versioning (SemVer) for all repositories:

- **MAJOR**: Incompatible changes (breaking changes)
- **MINOR**: Backward-compatible functionality (new features)
- **PATCH**: Backward-compatible fixes (bug fixes, maintenance)

## The VERSION File

Every repository must include a root-level `VERSION` file. This file:
- Contains only the version string (e.g., `1.2.3`).
- Is the single source of truth for the project's current state.
- Must be updated by agents/humans before any release.

## Version Analysis Tool

The framework includes a tool to help determine the correct version based on project history:

```bash
# Analyze a project directory
bash constitution/scripts/version_analyzer.sh .
```

This tool scans Git tags and commit messages for SemVer-aligned prefixes (e.g., `feat:`, `fix:`, `BREAKING CHANGE`) to suggest the next appropriate version bump.

## CHANGELOG Format

Use these categories:

```markdown
## Added

## Changed

## Fixed

## Removed

## Security
```

## User-Facing Changes

User-facing changes should be reflected in CHANGELOG.md.

Examples:

- New features
- Changed workflows
- Bug fixes visible to users
- Removed behavior
- Security fixes or hardening
- Configuration changes
- Migration requirements

## Agent Responsibilities

Agents should:

- Identify release notes when appropriate.
- Update CHANGELOG.md for user-facing changes.
- Note breaking changes clearly.
- Mention migration steps when required.
- Avoid adding noisy entries for purely internal changes unless useful.

## Release Review Checklist

Before release:

- Version updated where applicable
- CHANGELOG.md updated
- Tests passing
- Documentation updated
- Security-sensitive changes reviewed
- Migration notes included when required
