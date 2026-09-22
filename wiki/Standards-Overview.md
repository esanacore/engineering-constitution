# Standards Overview

The constitution is expressed as a set of principles in `CONSTITUTION.md`, a
required workflow in `AI_WORKFLOW.md`, and topic standards that expand on them.
This page is a map; the source files are authoritative.

## The principles

`CONSTITUTION.md` defines twelve principles:

1. **Documentation is part of the deliverable** — including the "what can it do
   today?" capabilities list, wiki content, and a demo page for product-facing
   repositories.
2. **Testing is required** — new behavior gets tests, bug fixes get regression
   tests, coverage is evaluated against declared targets, gaps are recorded.
3. **TODO management** — `TODO.md` is the living roadmap.
4. **Continuous improvement** — actively surface missing functionality and
   improvements.
5. **Security** — significant changes consider auth, input validation, secrets,
   dependency risk, logging, and auditing.
6. **Architecture awareness** — major decisions get ADRs; the repository root
   stays readable; code follows SOLID and the Dependency Rule.
7. **Dependency hygiene** — fewer, mature, actively maintained dependencies,
   inventoried in `docs/OTS_SOFTWARE.md`.
8. **Observability** — systems are observable by design.
9. **Operations and infrastructure discipline** — documented, reviewable,
   observable, recoverable.
10. **Release discipline** — user-facing changes reach `CHANGELOG.md`, and
    accumulated changes are actually released.
11. **Opportunity discovery** — record future features, refactors, and
    automation.
12. **Industry-standard code conventions** — follow the language/platform's own
    canonical style guide (`CODE_STYLE.md`, `sources/STYLE_GUIDES.md`).

## Topic standards

| Document | Covers |
| --- | --- |
| `AI_WORKFLOW.md` | The required step-by-step workflow for AI-assisted changes, and the proportionate fast path for trivial ones (ADR-0004). |
| `TESTING.md` | Test pyramid, coverage, and CI enforcement expectations. |
| `DOCUMENTATION.md` | Required/encouraged documents, requirements traceability, ADRs, the wiki, the demo page, and the definition of "product-facing". |
| `SECURITY.md` | Security review expectations, the secrets sweep, untrusted content reaching AI agents (prompt injection), the agent deny list, CI/CD supply chain (SHA-pinned actions), and data classification. |
| `ARCHITECTURE.md` | SOLID, the Dependency Rule and how it is enforced, design patterns, and visual architecture. |
| `OPERATIONS.md` | Deployment, monitoring, backup/restore, rollback, incident response. |
| `RELEASES.md` | Semantic versioning, what "breaking" means for the framework itself and the deprecation window (ADR-0003), Conventional Commit messages, the ordered release process, and the fleet bump. |
| `CODE_STYLE.md` | Principle 12 in full, plus the canonical style-guide registry. |
| `INTEGRATION.md` | Agent-tool integration and machine provisioning. |

## How it is enforced

Principles are backed by automation wherever possible: the CI checkers in
[[Governance Checkers]], the MCP server in [[MCP Server]], and the Solon agent
(`.github/agents/solon.agent.md`), which reviews changes against these same
documents. Decisions that shape the framework itself are recorded as ADRs under
`docs/adr/` — and since 1.48.0 that is a rule, not a habit: a change to the
Required Files, the Required Workflow, the checker contract, or the
compatibility policy gets an ADR first (`DOCUMENTATION.md`, "ADR Triggers for
the Framework Itself"). The framework also runs its own suites and checkers on
every pull request (`.github/workflows/tests.yml`), so it is held to the
same gates it ships.

## See also

- [[Home]]
- [[Governance Checkers]]
- [[Getting Started]]
