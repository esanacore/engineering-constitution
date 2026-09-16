# OTS Software Inventory

Off-the-shelf software this framework depends on. The framework is
deliberately zero-dependency for everything adopters run (bash, awk, sed,
Git); the one third-party runtime dependency belongs to the optional MCP
server. `scripts/check_ots_inventory.sh --manifest-dir mcp-server .`
cross-checks this table in CI.

## Conventions

See `templates/docs/OTS_SOFTWARE.md` for the column definitions. Component IDs
are never reused; removed components are marked `Removed`.

## Managed Dependencies

| Component ID | Name | Version | Supplier / Maintainer | Purpose | License | Risk | Verification | Anomaly Review | Update Policy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTS-001 | `@modelcontextprotocol/sdk` | `^1.20.1` | Anthropic (modelcontextprotocol.io) | Implements the MCP server transport and request handling in `mcp-server/index.js`, exposing the standards and source summaries to MCP-connected agents. | MIT | Medium (parses requests from a connected agent; runs with the developer's local file access, read-only by design) | Upstream test suite; `scripts/test_mcp_resources.sh` covers this repository's resource wiring; manual smoke test of `ListResources`/`ReadResource` on release. | GitHub Advisory Database for the package, last reviewed 2026-09-16 (no open advisories) | Caret range in `package.json`, lockfile committed; no bot manages it | Active |

## System-Level OTS

| Component ID | Name | Version | Supplier / Maintainer | Purpose | License | Risk | Verification | Anomaly Review | Update Policy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTS-101 | GNU bash | 4.x or later (5.x on the CI runner and Git Bash) | GNU Project | Interpreter for every script under `scripts/` | GPL-3.0 | Low | The full test suite runs on ubuntu-latest in CI and on Windows Git Bash locally | Ubuntu and Git for Windows security updates | Whatever the platform provides; no pin | Active |
| OTS-102 | Git | 2.x | Git project | Submodule mechanism, tag history, and every checker that reads tracked files | GPL-2.0 | Low | Exercised by every suite that builds a fixture repository | Platform security updates | Whatever the platform provides; no pin | Active |
| OTS-103 | Node.js | 20 or later | OpenJS Foundation | Runtime for the optional MCP server only | MIT | Low | `node --check mcp-server/index.js` locally; server started by hand during release smoke test | Node.js security releases | Whatever the platform provides; no pin | Active |
| OTS-104 | GitHub Actions: `actions/checkout` | v4.3.0 (SHA-pinned) | GitHub | Checks out the repository in every workflow here and in every workflow template | MIT | Medium (runs with the workflow token) | Pinned by full commit SHA in every workflow; Dependabot `github-actions` ecosystem proposes bumps | GitHub Advisory Database, last reviewed 2026-09-16 | SHA-pinned, Dependabot-managed | Active |

## Review Cadence

Re-review the Anomaly Review column at every release (`RELEASES.md`, "Cutting a
Release", pre-release review), and update a row in the same change that
changes the dependency.
