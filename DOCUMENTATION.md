# Documentation Standards

Documentation is part of the deliverable.

## Core Qualities

Documentation should be:

- Accurate
- Current
- Actionable
- Version controlled

## Required Files

Every repository should include:

- README.md
- HELP.md
- CHANGELOG.md
- TODO.md
- SECURITY.md

## Strongly Encouraged

Repositories should also include:

- docs/SETUP.md
- docs/COMMAND_REFERENCE.md
- docs/TROUBLESHOOTING.md
- docs/ARCHITECTURE.md
- docs/adr/
- docs/AGENT_PROMPTS.md
- docs/AGENT_HANDOFF.md
- docs/OPERATIONS.md
- API documentation
- Wiki content when appropriate

## Documentation Review Checklist

For each meaningful change, review whether updates are needed for:

- README.md
- CHANGELOG.md
- TODO.md
- Architecture documentation
- API documentation
- Deployment documentation
- Configuration documentation
- Troubleshooting guidance
- Wiki content

## README Expectations

README.md should explain:

- What the project does
- Who it is for
- How to install or set it up
- How to run it
- How to test it
- How to contribute or work with AI agents
- Where to find architecture and roadmap information

## CHANGELOG Expectations

CHANGELOG.md should capture user-facing changes using release categories:

- Added
- Changed
- Fixed
- Removed
- Security

## TODO Expectations

TODO.md is the living roadmap. It should reflect the best current understanding of remaining work.

## Migrating Existing Documentation

When adopting the Engineering Constitution in an existing repository, follow these steps to migrate your documentation:

1. **Audit Existing Files**: Identify your current `README.md`, `CHANGELOG`, `CONTRIBUTING`, and any design documents.
2. **Merge with Templates**: Use the copies in `.constitution-bootstrap/templates/` to merge constitution standards into your existing files.
3. **Migrate Backlogs**: If you have a separate task list (e.g., `BACKLOG.md`), move active items into the appropriate sections of the new `TODO.md`.
4. **Initialize ADRs**: Move existing architectural decisions into `docs/adr/` using the ADR template. If decisions were only documented in PRs or Slack, consider creating "retroactive" ADRs for the most critical ones.
5. **Update Agent Instructions**: Ensure your `AGENTS.md` and tool-specific instruction files point to any legacy documentation that hasn't been migrated yet.
6. **Retire Old Files**: Once content is successfully moved and verified, delete the old files to maintain a single source of truth.
