# MCP Server

`mcp-server/` is a minimal Node.js module built on
`@modelcontextprotocol/sdk` that exposes the constitution to AI agents over the
Model Context Protocol, so an agent can read the standards as structured
resources instead of guessing at file paths.

## Resources

The server exposes the core standards as MCP resources, including the
constitution itself, the AI workflow, testing standards, code style, and the
canonical style-guide registry (`sources/STYLE_GUIDES.md`). It also surfaces
distilled knowledge-source summaries as dynamic `constitution://source-summary/*`
resources, connecting the `sources/` book-digestion workflow to agents at
runtime.

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
