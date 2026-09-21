# Templates and Examples

## Templates

`templates/` is the payload `scripts/bootstrap.sh` installs into an adopting
repository. Notable groups:

- **Agent-instruction bridges** — `AGENTS.md` (the cross-vendor default), plus
  opt-in vendor files (`CLAUDE.md`, `.cursorrules`, `.goosehints`,
  `.openhands_instructions`, `.project-rules.md`, `SYSTEM_PROMPT.md`, and
  others) installed only for the tools a project actually uses.
- **Project governance files** — `AGENTS.md`, `CONTRIBUTING.md`, `HELP.md`,
  `README.md`, `SECURITY.md`, `TODO.md`, `CHANGELOG.md`, and `VERSION`.
- **Documentation scaffolds** under `templates/docs/` — `SETUP.md`,
  `COMMAND_REFERENCE.md`, `TROUBLESHOOTING.md`, `ARCHITECTURE.md`,
  `OPERATIONS.md`, `TEST_PLAN.md`, `PRODUCT_REQUIREMENTS.md`,
  `REQUIREMENTS_TRACEABILITY.md`, `OTS_SOFTWARE.md`, `ENV_VARS.md`, `MEMORY.md`,
  `SESSION_PLAN.md`, `AGENT_HANDOFF.md`, and `MVP_BACKLOG.md`.
- **Demo page** — `templates/demo.html`, a working single-file page (inline
  styles and scripts, no build, no backend, no network) that product-facing
  repositories fill in and publish. See `DOCUMENTATION.md`'s "Demo Page" and
  `docs/adr/0002-demo-page-requirement.md`.
- **GitHub automation** under `templates/.github/` — Copilot instructions,
  Dependabot configuration, the Solon agent, and the `constitution-*.yml`
  workflow templates (including `constitution-wiki.yml`; see [[Home]]).

A template is a starting point, not a finished document. `check_compliance.sh`
flags recommended and product-facing docs that still hold copied placeholder
text, so adoption is not "done" until each template has been customized or
trimmed to describe the real repository. `demo.html` is checked the same way
but by a different signal: HTML comments are ordinary markup rather than
template prompts, so the scaffold carries an explicit
`constitution-demo-template-placeholder` marker that the adopter deletes.

## Example project

`examples/sample-project/` demonstrates the shape a bootstrapped repository is
expected to have: top-level governance docs, a `constitution/` submodule, a
`docs/` directory, `src/`, and editor/assistant configuration directories such
as `.github/` and `.cursor/`.

`examples/OPERATIONS.example.md` is a fully worked operations runbook for a
fictional deployed service, filling in every section
`docs/OPERATIONS.md` is expected to cover.

## See also

- [[Bootstrap Script]]
- [[Standards Overview]]
- [[MCP Server]]
