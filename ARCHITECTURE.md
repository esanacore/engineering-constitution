# Architecture Standards

Architecture should be intentional, documented, and revisited as systems evolve.

## Architecture Decision Records

Use Architecture Decision Records (ADRs) for major architectural decisions.

Create ADRs for:

- New frameworks
- Database changes
- Infrastructure changes
- Major design changes
- Security decisions
- Significant dependency choices
- Cross-service contracts

## ADR Location

Project ADRs should live in:

```text
docs/adr/
```

## ADR Template

Each ADR should include:

- Title
- Status
- Date
- Context
- Decision
- Consequences
- Alternatives considered

Use `templates/ADR.md` as the baseline.

## Architecture Documentation

Architecture documentation should describe:

- System boundaries
- Major components
- Data flow
- External dependencies
- Deployment model
- Operational concerns
- Security-sensitive areas

## Maintenance

Architecture documentation should be updated when:

- A major design changes.
- A new service or integration is added.
- Data storage or flow changes.
- Deployment or infrastructure changes.
- A security-sensitive decision is made.
