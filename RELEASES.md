# Release Standards

Release discipline makes change understandable and recoverable.

## Semantic Versioning

Follow semantic versioning:

- MAJOR for incompatible changes
- MINOR for backward-compatible functionality
- PATCH for backward-compatible fixes

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
