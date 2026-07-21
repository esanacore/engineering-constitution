# Standards Overview

The constitution is expressed as a set of principles in `CONSTITUTION.md`, a
required workflow in `AI_WORKFLOW.md`, and topic standards that expand on them.
This page is a map; the source files are authoritative.

## The principles

`CONSTITUTION.md` defines twelve principles:

1. **Documentation is part of the deliverable** — including the "what can it do
   today?" capabilities list, and wiki content.
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
| `AI_WORKFLOW.md` | The required step-by-step workflow for AI-assisted changes. |
| `TESTING.md` | Test pyramid, coverage, and CI enforcement expectations. |
| `DOCUMENTATION.md` | Required/encouraged documents, requirements traceability, ADRs, and the wiki. |
| `SECURITY.md` | Security review expectations and the secrets sweep. |
| `ARCHITECTURE.md` | SOLID, the Dependency Rule and how it is enforced, design patterns, and visual architecture. |
| `OPERATIONS.md` | Deployment, monitoring, backup/restore, rollback, incident response. |
| `RELEASES.md` | Semantic versioning and the ordered release process. |
| `CODE_STYLE.md` | Principle 12 in full, plus the canonical style-guide registry. |
| `INTEGRATION.md` | Agent-tool integration and machine provisioning. |

## How it is enforced

Principles are backed by automation wherever possible: the CI checkers in
[[Governance Checkers]], the MCP server in [[MCP Server]], and the Solon agent
(`.github/agents/solon.agent.md`), which reviews changes against these same
documents. Decisions that shape the framework itself are recorded as ADRs under
`docs/adr/`.

## See also

- [[Home]]
- [[Governance Checkers]]
- [[Getting Started]]
