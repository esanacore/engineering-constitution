# Adoption Guide

This guide is for teams or individual developers evaluating whether and how to introduce Eric's Engineering Constitution into an existing repository.

For the command-level installation path, see [[Getting Started]] and [[Bootstrap Script]].

## Start with the goal

The Constitution is most useful when you want AI-assisted development to operate within explicit engineering expectations rather than relying on each chat session to rediscover how the project should be maintained.

You do not need to adopt every optional artifact on day one. The bootstrap process distinguishes required, recommended, and product-facing documentation so adoption can match the maturity and risk of the project.

## What adoption changes

A typical adopting repository gains:

- a `constitution/` Git submodule pointing to the framework;
- agent-facing instructions such as `AGENTS.md` and `CLAUDE.md`;
- governance files for changelog, TODOs, security, help, and versioning;
- documentation scaffolds for architecture, setup, operations, testing, requirements, traceability, dependencies, and configuration;
- CI workflows and local checks for selected governance rules;
- a standardized adoption badge in the README.

Existing files are preserved by default. When the bootstrap process encounters a file that already exists, it provides merge-ready template material rather than silently replacing the project's documentation.

## Suggested adoption levels

### Personal or experimental project

Start with the core workflow, tests, README, TODO, changelog, security guidance, and basic CI checks. Add deeper artifacts when the project actually needs them.

### Team software project

In addition to the core files, document architecture, setup, test strategy, operations, environment variables, and third-party dependencies. Make project-specific expectations explicit in `AGENTS.md`.

### Product-facing or higher-assurance project

Add formal product requirements, requirements traceability, OTS/dependency inventory, architecture boundaries, operations/recovery documentation, and stricter CI enforcement where appropriate.

The framework was influenced in part by experience with disciplined and regulated engineering practices, but adopting it does **not** by itself make a project compliant with any regulatory standard. Teams remain responsible for determining and validating their actual compliance obligations.

## Roll out enforcement gradually

Many checkers support warning-oriented adoption before strict enforcement. That is useful for established repositories that may initially have documentation gaps.

A sensible rollout is:

1. bootstrap the framework;
2. review the adoption report;
3. merge project-specific content into generated templates;
4. run governance checks locally;
5. fix meaningful gaps;
6. enable stricter CI behavior only when the underlying documentation is accurate enough to enforce.

Strict automation applied to inaccurate documentation creates false confidence. The documented contract should become trustworthy before it becomes a gate.

## Customize the project, not the universal standard

The Constitution is designed to separate reusable engineering principles from repository-specific rules.

Keep project-specific commands, architectural details, preferences, and exceptions in the adopting repository's own files. This allows the shared Constitution to evolve without overwriting the identity of each project.

## Keep the Constitution current

Adopting projects pin the Constitution through a Git submodule. Version-alignment and freshness tooling can tell agents and CI when the project is behind the latest framework release.

Updates should still be reviewed like any dependency change. A newer Constitution may introduce new expectations that require project-level documentation or workflow changes.

## Evaluate success

A successful adoption should make the repository easier to understand and safer to change. Useful signals include:

- agents require less repeated prompting about project conventions;
- tests and documentation change alongside implementation more consistently;
- requirements and verification remain connected;
- dependency and configuration changes are visible in review;
- interrupted work is easier to resume;
- architecture and operational decisions are easier to explain;
- another human or agent can enter the repository and understand how work is expected to proceed.

## See also

- [[Getting Started]]
- [[Bootstrap Script]]
- [[AI Development Workflow]]
- [[Governance Checkers]]
- [[Templates and Examples]]
