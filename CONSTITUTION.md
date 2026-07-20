# Eric's Engineering Constitution Framework

Version: 1.39.0

## Purpose

Eric's Engineering Constitution Framework establishes universal standards, workflows, and expectations for AI-assisted software development across all repositories.

The goals are:

- Consistent development practices
- High documentation quality
- High automated test coverage
- Continuous improvement
- Security awareness
- Sustainable project maintenance
- Effective collaboration between humans and AI agents

This framework serves as the authoritative source of engineering guidance for all projects.

## Principle 1: Documentation Is Part of the Deliverable

All changes must consider documentation impact.

Review:

- README.md, including its current features/capabilities list — an ever-expanding project's "what can it do today?" answer is never optional and decays fastest exactly when the project is growing fastest. See `DOCUMENTATION.md`'s "Current Capabilities" section.
- CHANGELOG.md
- Architecture documentation
- API documentation
- Deployment documentation
- Wiki content
- Project memory (`docs/MEMORY.md`) to record codebase learnings, decisions, and user preferences

A task is not complete until documentation impact has been evaluated.

Planned work should be documented before implementation begins (see `docs/SESSION_PLAN.md` and `AI_WORKFLOW.md`). If a session is interrupted, the plan enables the next agent or human to resume without guessing what was intended. Cumulative codebase learnings, conventions, and approved decisions are preserved across sessions in the project memory bank (`docs/MEMORY.md`) at the user's discretion.

Product-facing repositories should give each requirement a stable identifier and explicit acceptance criteria, and maintain a requirements traceability matrix mapping each requirement to its verifying tests and status. See `DOCUMENTATION.md`.

## Principle 2: Testing Is Required

All new functionality should include automated tests.

Bug fixes should include regression tests.

Agents should:

- Add tests for new behavior
- Update tests for changed behavior
- Repair broken tests
- Avoid reducing coverage

Coverage should be evaluated continuously against declared targets, and coverage gaps should be analyzed and recorded rather than hidden behind an aggregate percentage. Tests should trace to requirement identifiers where those exist. See `TESTING.md`.

Testability is a design requirement.

## Principle 3: TODO Management

Maintain TODO.md as the living roadmap.

Agents should:

- Add discovered work
- Add technical debt
- Add feature opportunities
- Add refactoring opportunities
- Remove completed items

TODO.md should always represent the best understanding of remaining work.

## Principle 4: Continuous Improvement

Agents should actively identify:

- Missing functionality
- User experience improvements
- Performance improvements
- Reliability improvements
- Security improvements
- Developer experience improvements

Record findings in TODO.md.

## Principle 5: Security

All significant changes should consider:

- Authentication
- Authorization
- Input validation
- Secret management
- Dependency risk
- Logging
- Auditing

Security concerns should be documented.

## Principle 6: Architecture Awareness

Major architectural decisions must be documented.

Use Architecture Decision Records (ADR).

Create ADRs for:

- New frameworks
- Database changes
- Infrastructure changes
- Major design changes
- Security decisions

ADRs follow a lifecycle of `Proposed → Accepted → Superseded` (or `Deprecated`), record their relationships to other ADRs (`extends`, `supersedes`, `related`), and state explicit promotion criteria while `Proposed`. See `DOCUMENTATION.md`.

Code-level structure should follow the SOLID principles and the Dependency Rule, applied as pragmatic guardrails rather than ceremony. See `ARCHITECTURE.md`.

The Dependency Rule is enforceable, not merely aspirational: declare the project's layers in `docs/ARCHITECTURE.md` and `scripts/check_architecture.sh` verifies that every import points inward. Compliance is not the same as good structure — a repository can carry every governance document this constitution requires and still have its business rules importing its database. Declaring layers is what closes that gap. See `ARCHITECTURE.md`'s "Enforcing the Dependency Rule".

Every README.md should include a visual project-structure tree and, whenever possible, at least one infographic — a component or flow diagram (Mermaid by default) — not just prose. This is the default, not an exception for complex systems. Keep both current in the same change that changes the structure. See `ARCHITECTURE.md`'s "Visual Architecture" section.

The repository root is an architectural surface, not a junk drawer. It is the first thing a reader sees, and a root crowded with configuration and near-duplicate instruction files hides the project's actual shape. Keep it to the files that must live there: put governance documents where the hosting platform still finds them (`.github/`), reference documentation in `docs/`, and add a tool's configuration file only when the project actually uses that tool. Adopting a framework must not be the reason a root listing doubles. See `DOCUMENTATION.md`'s "Keeping the Repository Root Readable".

## Principle 7: Dependency Hygiene

Prefer:

- Fewer dependencies
- Mature dependencies
- Actively maintained dependencies

Remove unused dependencies.

Review dependency risk regularly.

Repositories with third-party dependencies should maintain an OTS software inventory (`docs/OTS_SOFTWARE.md`) documenting each component's purpose, risk, verification, and known-anomaly posture — updated in the same change that adds, removes, or upgrades a dependency. See `DOCUMENTATION.md`'s "OTS Software Inventory" section and `SECURITY.md`.

## Principle 8: Observability

New systems should consider:

- Logging
- Metrics
- Diagnostics
- Monitoring
- Tracing

Systems should be observable by design.

## Principle 9: Operations and Infrastructure Discipline

Operational changes should be:

- Documented
- Reviewable
- Observable
- Recoverable

Projects should define:

- Environment expectations
- CI/CD validation paths
- Rollback guidance
- Backup and restore expectations
- Incident response ownership

## Principle 10: Release Discipline

User-facing changes should be reflected in CHANGELOG.md.

Agents should identify release notes when appropriate.

Accumulated user-facing changes should not sit unreleased indefinitely — cut a release (bump `VERSION`, tag, publish) once they build up, following the Required Workflow and RELEASES.md's Cutting a Release process. See `AI_WORKFLOW.md` and `RELEASES.md`.

## Principle 11: Opportunity Discovery

Agents should not merely complete assigned work.

Agents should identify:

- Future features
- Refactoring opportunities
- Test improvements
- Documentation improvements
- Automation opportunities

Document findings in TODO.md.

## Principle 12: Industry-Standard Code Conventions

Code style, comments, docstrings, and technical diagrams should follow the
official, canonical style guide published by the language or platform owner
rather than an ad hoc, project-invented convention.

For example, Kotlin/Android code follows
[developer.android.com's Kotlin style guide](https://developer.android.com/kotlin/style-guide).

Docstring and comment *format* follows the platform's canonical convention
(KDoc, Javadoc, PEP 257/Google-style docstrings, JSDoc, Go doc comments, and
so on); this governs form, not when to write a comment — the existing
"why, not what" comment-content policy is unchanged.

See `CODE_STYLE.md` for the full principle and `sources/STYLE_GUIDES.md` for
the maintained registry of canonical style guides by language/platform.

## Required Workflow

See `AI_WORKFLOW.md` for the complete step-by-step workflow.

## Future Roadmap

Potential future additions:

- AI agent scorecards
- Quality metrics
- Repository health dashboards
- Automated compliance validation
- CI/CD enforcement
- AI-generated release planning
