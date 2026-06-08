# TODO Guidelines

TODO.md is the living roadmap for a repository.

It should always represent the best current understanding of remaining work.

## Categories

Use these categories.

### Features

New functionality.

### Technical Debt

Known compromises.

### Refactoring

Maintainability improvements.

### Testing

Coverage improvements.

### Documentation

Documentation work.

### Nice-to-Have

Future enhancements.

## Agent Responsibilities

Agents should:

- Add discovered work.
- Add technical debt.
- Add feature opportunities.
- Add refactoring opportunities.
- Add test coverage opportunities.
- Add documentation gaps.
- Remove completed items.
- Keep entries specific and actionable.

## Entry Format

Recommended format:

```markdown
- [ ] Short actionable task.
```

Use completed items only when useful for short-term visibility:

```markdown
- [x] Completed task.
```

Remove completed items during regular cleanup.

## Good TODO Entries

- [ ] Add regression tests for failed login lockout behavior.
- [ ] Document production deployment rollback procedure.
- [ ] Replace duplicated payment validation logic with shared validator.

## Weak TODO Entries

- [ ] Improve code.
- [ ] Fix stuff.
- [ ] Maybe tests.
