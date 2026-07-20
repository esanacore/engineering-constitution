# Eric's Engineering Constitution

Eric's Engineering Constitution is a reusable framework for AI-assisted software development standards. It is the single source of truth for how humans and AI agents should work across your software repositories.

Each project includes this repository as a `constitution/` Git submodule alongside a small set of local project files, giving every project:

- Shared engineering principles
- Standard AI-agent workflow instructions
- Baseline templates for README, TODO, CHANGELOG, AGENTS, Claude, Copilot, and ADR files
- A standardized "Eric's Engineering Constitution" adoption badge in the README
- A bootstrap script that installs those files into an existing Git repository

[![Eric's Engineering Constitution Framework](assets/diagrams/constitution_infographic.jpg)](https://esanacore.github.io/engineering-constitution/demo.html)
*Click the infographic above or open [the interactive dashboard](https://esanacore.github.io/engineering-constitution/demo.html) to view it live.*

## Repository Contents

- `CONSTITUTION.md`: Authoritative engineering principles.
- `AI_WORKFLOW.md`: Step-by-step AI agent workflow.
- `INTEGRATION.md`: Submodule workflow, agent reading order, project-specific overrides, and VERSION update strategy.
- `TESTING.md`: Testing expectations and reporting standards.
- `DOCUMENTATION.md`: Documentation requirements and checklists.
- `SECURITY.md`: Security review standards.
- `OPERATIONS.md`: Operations and infrastructure standards.
- `ARCHITECTURE.md`: Architecture and ADR expectations.
- `RELEASES.md`: Release and changelog standards.
- `TODO_GUIDELINES.md`: TODO.md structure and maintenance rules.
- `KNOWLEDGE_SOURCES.md`: How to drop in book/reference sources and turn them into agent-consumable summaries via `sources/`.
- `skills/`: 25 built-in agent skills that enforce constitution rules autonomously.
- `templates/`: Files to copy into projects.
- `templates/docs/PRODUCT_REQUIREMENTS.md`: Optional product requirements template.
- `templates/docs/MVP_BACKLOG.md`: Optional milestone backlog template for early-stage products.
- `templates/docs/SESSION_PLAN.md`: Session planning template for crash-recovery documentation.
- `templates/docs/OTS_SOFTWARE.md`: OTS software inventory template (FDA OTS / IEC 62304 SOUP-informed third-party dependency register).
- `examples/sample-project/`: Example project layout.
- `examples/OPERATIONS.example.md`: Fully worked `docs/OPERATIONS.md` runbook for a deployed service.
- `scripts/bootstrap.sh`: Script to initialize an existing repository.
- `scripts/check_traceability.sh`: Reference checker that verifies every requirement ID has a verifying-test entry in the traceability matrix.
- `scripts/check_ots_inventory.sh`: Reference checker that cross-checks the dependencies declared in root-level manifests against the OTS software inventory (`docs/OTS_SOFTWARE.md`), so a dependency added without documentation is flagged in the same change.
- `scripts/check_compliance.sh`: Reference checker that verifies an adopting repository carries the expected governance files.
- `scripts/check_version_alignment.sh`: Reference checker that verifies adopter-facing Constitution version references match the pinned `constitution/VERSION`.
- `scripts/check_release_tag_alignment.sh`: Source-repo checker that verifies `VERSION`, the matching `v<VERSION>` tag, and `HEAD` stay aligned after a release.
- `scripts/check_constitution_freshness.sh`: Single-repository freshness check (the `audit_adopters.sh` companion for one repository instead of a fleet), run by the `.claude/settings.json` SessionStart hook so a Claude Code session flags a stale `constitution/` submodule immediately instead of waiting on CI or Dependabot.
- `scripts/run_declared_tests.sh`: Runs the test command an adopting repository declares in `docs/TEST_PLAN.md`, enforcing it in CI.
- `scripts/check_doc_freshness.sh`: Blunt CI tripwire that flags a pull request changing source files without touching README.md/CHANGELOG.md.
- `scripts/check_secrets.sh`: Sweeps tracked and untracked-but-not-gitignored files for secrets that should never reach a remote (credential-shaped filenames, high-confidence content patterns), and checks .gitignore coverage.
- `scripts/setup-machine.sh`: One-time, per-machine installer for the AI-agent toolchain the templates point at (Bun, gstack, goose, goosetown). Not invoked by `bootstrap.sh` — a machine is provisioned once, explicitly; a repository is bootstrapped by writing files only. Idempotent, skips anything already installed.
- `.github/workflows/release-tag-alignment.yml`: Source-repo release guard that runs `scripts/check_release_tag_alignment.sh` on every pushed `v*` tag, and can be re-run manually for a chosen ref.

## Project Structure

```text
engineering-constitution/
├── CONSTITUTION.md                       ← Authoritative engineering principles (start here)
├── AI_WORKFLOW.md                        ← Required step-by-step AI agent workflow
├── INTEGRATION.md                        ← Submodule workflow, agent reading order, multi-tool setup
├── TESTING.md                            ← Testing expectations, coverage, CI enforcement
├── DOCUMENTATION.md                      ← Documentation requirements and README/CHANGELOG standards
├── SECURITY.md                           ← Security review standards
├── OPERATIONS.md                         ← Operations and infrastructure standards
├── ARCHITECTURE.md                       ← Architecture, ADR, and visual-diagram expectations
├── RELEASES.md                           ← Versioning, changelog, and release-cutting standards
├── TODO_GUIDELINES.md                    ← TODO.md structure and maintenance rules
├── KNOWLEDGE_SOURCES.md                  ← How to drop in reference sources under sources/
├── VERSION                               ← Single source of truth for the framework's version
├── README.md / TODO.md / CHANGELOG.md    ← This repository's own governance docs
├── AGENTS.md, CLAUDE.md, COPILOT_INSTRUCTIONS.md, ...  ← This repo's own agent instructions
│
├── templates/                            ← Files scripts/bootstrap.sh copies into adopting projects
│   ├── docs/                             ← docs/ templates (ARCHITECTURE, SETUP, TEST_PLAN, SESSION_PLAN, ADR, ...)
│   └── .github/
│       ├── workflows/                    ← CI gate templates (version, compliance, tests, doc-freshness)
│       └── agents/                       ← Solon, the Copilot custom agent
│
├── .github/workflows/release-tag-alignment.yml  ← Post-tag release validation for this source repo
├── scripts/                              ← bootstrap.sh plus every checker, auditor, and its tests
├── examples/                             ← A worked sample-project layout + OPERATIONS.example.md
├── sources/                              ← Book/reference sources distilled into agent-consumable summaries
├── skills/                               ← 25 built-in agent skills that execute constitution rules autonomously
├── mcp-server/                           ← MCP server exposing constitution docs/sources as resources
└── wiki/                                 ← Wiki content (Home.md)
```

`INTEGRATION.md`'s "Project File Structure" section shows the mirror image of this: what an **adopting** project looks like once it pulls this repository in as a `constitution/` submodule.

## How It Works

![How It Works: engineering-constitution adoption flow](assets/diagrams/how-it-works.svg)

Every adopting project pulls this repository in as a read-only `constitution/` submodule, layers a small set of local files on top (agent entry points, tool-specific rule files, CI workflows), and lets AI agents and CI gates enforce the same standards documented here — see `INTEGRATION.md` for the full reading order and multi-tool setup.

Diagram source: `assets/diagrams/how-it-works.mmd` (see `assets/diagrams/README.md` to regenerate the SVG after editing it). It's a pre-rendered image rather than a live `mermaid` code block because GitHub's native mobile apps don't render Mermaid — only github.com in a browser does.

## Version

Current version: 1.37.0

See `VERSION`.

## Getting Started

### Step 1: Publish This Repository

Publish this repository somewhere your projects can access it:

```bash
cd /path/to/engineering-constitution
git remote add origin <repository-url>
git push -u origin main
```

Use that `<repository-url>` in the bootstrap commands below.

### Step 2: Bootstrap a Project

Run the bootstrap script to set up the constitution in any Git repository:

```bash
./scripts/bootstrap.sh /path/to/project <repository-url>
```

The target project must already be a Git repository. Pass `--force` to overwrite previously generated files:

```bash
./scripts/bootstrap.sh --force /path/to/project <repository-url>
```

#### Choosing AI Tool Instruction Files

By default, bootstrap installs **one** agent instruction file: `AGENTS.md`, the
cross-vendor standard that most tools read directly. Tools that hardcode their
own filename are opt-in, so an adopting repository does not carry instruction
files for tools nobody on the project uses:

```bash
# Just AGENTS.md (default)
./scripts/bootstrap.sh /path/to/project <repository-url>

# Add Claude Code and Cursor support
./scripts/bootstrap.sh --agents=claude,cursor /path/to/project <repository-url>

# Every vendor file (the pre-1.38.0 behavior)
./scripts/bootstrap.sh --agents=all /path/to/project <repository-url>
```

Supported keys: `claude`, `cursor`, `copilot`, `goose`, `openhands`,
`antigravity`, `continue`, `aider`, `generic`, `all`. Run
`./scripts/bootstrap.sh --help` for the files each one installs.

A default bootstrap adds 12 root entries instead of 24.

#### New Repository

```bash
mkdir my-project
cd my-project
git init
cd /path/to/engineering-constitution
./scripts/bootstrap.sh /path/to/my-project <repository-url>
```

Customize the generated files (`README.md`, `TODO.md`, `CHANGELOG.md`, `docs/adr/0001-record-architecture-decisions.md`), then commit:

```bash
cd /path/to/my-project
git add .
git commit -m "Add Eric's engineering constitution"
```

#### Existing Repository

```bash
./scripts/bootstrap.sh /path/to/existing-project <repository-url>
```

The script adds the `constitution` submodule, creates missing governance files, and writes an adoption report to `.constitution-bootstrap/adoption-report.md`. Existing files are never overwritten by default — template copies are placed in `.constitution-bootstrap/templates/` for manual merging.

After running it:

1. Review `.constitution-bootstrap/adoption-report.md` for detected project context and recommended merge steps.
2. Merge any relevant template content into skipped files.
3. Customize generated placeholders.
4. Commit `.gitmodules`, the `constitution` submodule reference, generated files, and any merged changes.

### Adoption Badge

Every repository the bootstrap script touches gets a standardized adoption badge in its `README.md`:

```markdown
<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->
```

The badge is managed between the `CONSTITUTION_START` / `CONSTITUTION_END` markers, so it is added to existing READMEs (after the first heading), refreshed in place when the constitution is updated, and never duplicated on re-runs. The badge link points at the bootstrap source when it is a public Git URL and falls back to the canonical repository otherwise.

### Manual Installation

If you prefer not to use the bootstrap script:

```bash
git submodule add <repository-url> constitution
cp constitution/templates/AGENTS.md AGENTS.md
cp constitution/templates/CLAUDE.md CLAUDE.md
# ...and so on for the other template files; see scripts/bootstrap.sh for the full list
```

## Adding Reference Sources to the Constitution

The constitution deliberately draws on named authoritative sources (see
`ARCHITECTURE.md`'s citations of *Clean Architecture* and *Design Patterns*)
rather than absorbing influence ad hoc. `sources/` is the drop-in location for
new books, papers, or long-form articles that could inform a future change,
and `KNOWLEDGE_SOURCES.md` is the full reference for this workflow — this is
the short version, for working in your own clone of this repository:

1. Drop the file (PDF/EPUB/DOCX/MD/TXT) into `sources/raw/` — gitignored, so
   it's never committed.
2. Run `bash scripts/check_source_summaries.sh scan` to see what's `NEW` or
   `CHANGED` and needs a summary.
3. Read the source and write a distilled summary at the mirrored path under
   `sources/summaries/`, following the template in `KNOWLEDGE_SOURCES.md`
   (Why This Matters, Key Takeaways, Where It Could Apply).
4. Mark it processed: `bash scripts/check_source_summaries.sh record
   <relative-path>`. This refuses to run until the summary actually exists.
5. **Promote the insight, if warranted.** Writing a summary does not itself
   change any constitution document — that's intentional, so influence is
   evaluated deliberately instead of absorbed automatically. If a summary's
   "Where It Could Apply" section points to a real gap, make a separate,
   normal edit to the relevant document (`CONSTITUTION.md`, `ARCHITECTURE.md`,
   `TESTING.md`, etc.), then update `CHANGELOG.md` and `TODO.md` per this
   repository's own Completion Checklist and cut a release per `RELEASES.md`
   once user-facing changes accumulate.
