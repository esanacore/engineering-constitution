# MCP Server

`mcp-server/` is a minimal Node.js module built on
`@modelcontextprotocol/sdk` that exposes the constitution to AI agents over the
Model Context Protocol, so an agent can read the standards as structured
resources instead of guessing at file paths.

## Resources

The server exposes every root standards document as an MCP resource —
`CONSTITUTION.md`, `AI_WORKFLOW.md`, `INTEGRATION.md`, `TESTING.md`,
`DOCUMENTATION.md`, `SECURITY.md`, `OPERATIONS.md`, `ARCHITECTURE.md`,
`RELEASES.md`, `CODE_STYLE.md`, `TODO_GUIDELINES.md`, `KNOWLEDGE_SOURCES.md` —
plus the canonical style-guide registry (`sources/STYLE_GUIDES.md`). It also
surfaces distilled knowledge-source summaries as dynamic
`constitution://source-summary/*` resources, connecting the `sources/`
book-digestion workflow to agents at runtime.

The server reports the framework's `VERSION` as its own version, so an MCP
client can see which constitution release it is talking to, and
`scripts/test_mcp_resources.sh` fails the build if a standards document is
missing from the resource list or the package version drifts from `VERSION`
(it once sat at 1.0.0 while the framework reached 1.46.0).

## Tools

- `validate_project_structure` — checks whether a target project contains the
  baseline governance files (`AGENTS.md`, `CHANGELOG.md`, `TODO.md`, and
  `VERSION`). It is a lightweight, agent-callable complement to the fuller
  `scripts/check_compliance.sh`; see [[Governance Checkers]].

## Relationship to the CI checkers

The MCP server and the Bash checkers serve different moments. The checkers run
in CI and locally as gates on a change; the MCP server gives an agent
read access to the standards *while it works*, before a gate is ever reached.
Both draw on the same source files in this repository, so neither can drift from
the other.

## See also

- [[Governance Checkers]]
- [[Standards Overview]]
