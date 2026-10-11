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
| OTS-001 | `@modelcontextprotocol/sdk` | `^1.31.0` | Anthropic (modelcontextprotocol.io) | Implements the MCP server transport and request handling in `mcp-server/index.js`, exposing the standards and source summaries to MCP-connected agents. | MIT | Medium (parses requests from a connected agent; runs with the developer's local file access, read-only by design) | Upstream test suite; `scripts/test_mcp_resources.sh` covers this repository's resource wiring; manual smoke test of `ListResources`/`ReadResource` on release. | GitHub Advisory Database for the package, re-reviewed 2026-09-27 for the 1.49.0 release: Dependabot reports no open advisories against this repository. Previously, last reviewed 2026-09-23. Dependabot alerts were enabled on this repository that day and surfaced 23 transitive advisories under this SDK (7 high, 14 medium, 2 low) that the prior manual review had missed because alerting was off; all were resolved by lockfile bumps in 1.48.1 (`hono` >= 4.13.5, `fast-uri` >= 3.1.6, `ip-address` >= 10.3.1, `qs` >= 6.16.0, `@hono/node-server` >= 1.19.15, `body-parser` >= 2.3.0). No open advisories. | Caret range in `package.json`, lockfile committed; Dependabot alerts and security updates enabled Bumped 1.29.0 -> 1.31.0 by Dependabot PR #87 (2026-10-11); lockfile audit clean at merge. | Active |

## System-Level OTS

| Component ID | Name | Version | Supplier / Maintainer | Purpose | License | Risk | Verification | Anomaly Review | Update Policy | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| OTS-101 | GNU bash | 4.x or later (5.x on the CI runner and Git Bash) | GNU Project | Interpreter for every script under `scripts/` | GPL-3.0 | Low | The full test suite runs on ubuntu-latest in CI and on Windows Git Bash locally | Ubuntu and Git for Windows security updates | Whatever the platform provides; no pin | Active |
| OTS-102 | Git | 2.x | Git project | Submodule mechanism, tag history, and every checker that reads tracked files | GPL-2.0 | Low | Exercised by every suite that builds a fixture repository | Platform security updates | Whatever the platform provides; no pin | Active |
| OTS-103 | Node.js | 20 or later | OpenJS Foundation | Runtime for the optional MCP server only | MIT | Low | `node --check mcp-server/index.js` locally; server started by hand during release smoke test | Node.js security releases | Whatever the platform provides; no pin | Active |
| OTS-104 | GitHub Actions: `actions/checkout` | v7.0.1 (SHA-pinned) | GitHub | Checks out the repository in every workflow here and in every workflow template | MIT | Medium (runs with the workflow token) | Pinned by full commit SHA in every workflow; Dependabot `github-actions` ecosystem proposes bumps | GitHub Advisory Database, re-reviewed 2026-09-27 (no open advisories). Still pinned to v4.3.0 by SHA. Dependabot pull request #65 proposes v7.0.1, a three-major jump that changes the pin every adopter inherits from the workflow templates; it is deliberately not part of 1.49.0 and awaits review against SECURITY.md's CI/CD supply-chain section. | GitHub Advisory Database, re-reviewed 2026-10-11 (no open advisories). Pin moved v4.3.0 -> v7.0.1 (SHA `3d3c42e5aac5ba805825da76410c181273ba90b1`, verified against the upstream `v7.0.1` tag with `git ls-remote`); v5+ needs a runner with Node 24, which every GitHub-hosted runner has. Dependabot PR #65 was closed because it moved only 4 of the 12 pinned workflows. | Active |

## Review Cadence

Re-review the Anomaly Review column at every release (`RELEASES.md`, "Cutting a
Release", pre-release review), and update a row in the same change that
changes the dependency.
