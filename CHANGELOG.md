# Changelog

All notable user-facing changes to Eric's Engineering Constitution Framework are documented in this file.

This project follows semantic versioning.

## Unreleased

## 1.33.0 - 2026-07-11

### Added

- Added `CONSTITUTION.md` Principle 12 (Industry-Standard Code Conventions), requiring code style, comments, docstrings, and technical diagrams to follow the official, canonical style guide published by the language or platform owner (for example, Kotlin/Android code follows `developer.android.com`'s Kotlin style guide) rather than an ad hoc, project-invented convention. Backed by two new files: `CODE_STYLE.md` (the principle, including that comment/docstring *format* follows the platform's canonical convention — KDoc, Javadoc, PEP 257, JSDoc, Go doc comments, etc. — while the existing "why, not what" comment-content policy is unchanged) and a new tracked `sources/STYLE_GUIDES.md` registry (canonical style guide URL + docstring convention per language/platform, seeded with Kotlin/Android, Java, Python, Swift, JS/TS, Go, C#, Rust, and Shell), living in the same `sources/` directory as the existing book/paper digestion workflow. `KNOWLEDGE_SOURCES.md` now explains the two kinds of sources side by side (downloaded-and-digested books/papers vs. cited-by-reference living style guides). Both `CODE_STYLE.md` and `sources/STYLE_GUIDES.md` are added to `CLAUDE.md`/`templates/CLAUDE.md`'s Required Reading and surfaced as MCP resources in `mcp-server/index.js`. Closes the "Coding standards" / "Language-specific guidance" items from `CONSTITUTION.md`'s Future Roadmap.
- Added `templates/docs/SESSION_PLAN.md`, a crash-recovery session planning template that agents write before implementation begins. It documents the session's goals, approach, files expected to change, and risks, so if a session is interrupted, the next agent or human can resume without guessing what was intended. The file is overwritten at the start of each session; previous session outcomes should be captured in `docs/AGENT_HANDOFF.md` or commit messages first.
- Added three new steps to `AI_WORKFLOW.md`'s Required Workflow: check for an existing session plan from a previous interrupted session (step 8), write or update `docs/SESSION_PLAN.md` before implementation (step 10), and clear or archive the plan before completing work (step 22). Added corresponding bullets to the Before Beginning Work, During Work, and Before Completing Work sections.
- Added a "Session Planning" section to `DOCUMENTATION.md` explaining the purpose and lifecycle of `docs/SESSION_PLAN.md` and its relationship to `docs/AGENT_HANDOFF.md` as complementary bookends of a session lifecycle.
- Added `docs/SESSION_PLAN.md` to the Strongly Encouraged files list in `DOCUMENTATION.md`.
- Added session plan awareness to every agent instruction template: `templates/AGENTS.md`, `templates/CLAUDE.md`, `templates/.goosehints`, `templates/.github/copilot-instructions.md`, `templates/COPILOT_INSTRUCTIONS.md`, `templates/.agent-instructions.md`, and `templates/.openhands_instructions`.
- Added a pointer from `templates/docs/AGENT_HANDOFF.md` to `docs/SESSION_PLAN.md` so the next agent checks intent-before-work alongside state-after-work.
- Extended session plan awareness to the remaining agent-instruction templates that were missed in the initial rollout: `templates/.cursorrules`, `templates/.cursor/rules/project.mdc`, `templates/.continue/config.json`, `templates/.aider.conf.yml` (which now auto-loads `docs/SESSION_PLAN.md` as context), `templates/.project-rules.md`, `templates/SYSTEM_PROMPT.md`, `templates/CONTRIBUTING.md`, and `templates/HELP.md` — closing the gap where roughly half of `INTEGRATION.md`'s named tool-specific override files didn't know about the workflow step.
- Added `docs/SESSION_PLAN.md` to `scripts/check_compliance.sh`'s recommended-files list, matching `DOCUMENTATION.md`'s Strongly Encouraged list, with a dedicated exemption from the placeholder-content check: unlike every other recommended doc, `docs/SESSION_PLAN.md` is *designed* to sit in placeholder form between sessions (it's cleared/overwritten each time), so flagging that as neglect would be a permanent false positive. Covered by a new negative-case test in `scripts/test_check_compliance_placeholders.sh`.
- Added `docs/SESSION_PLAN.md` to `scripts/test_bootstrap.sh`'s installed-file assertions, so bootstrap's own test suite actually proves the file gets installed, matching every other file `scripts/bootstrap.sh` installs.

### Changed

- `CONSTITUTION.md` Principle 1 (Documentation Is Part of the Deliverable) now explicitly states that planned work should be documented before implementation begins, pointing to `docs/SESSION_PLAN.md` and `AI_WORKFLOW.md`.
- `INTEGRATION.md` now describes the session plan in its "How Agents Should Read and Apply the Constitution" section and includes `docs/SESSION_PLAN.md` in the Project File Structure diagram.
- `scripts/bootstrap.sh` now installs `docs/SESSION_PLAN.md` and reports its status in the adoption report.
- `templates/CLAUDE.md`'s "gstack" section is now explicitly marked optional ("gstack (Optional — delete this section if unused)"), with a preamble clarifying gstack is a third-party skill suite, not a constitution requirement, and instructing adopters without it to delete the whole section. Previously every bootstrapped repo inherited a personal tooling mandate (use `/browse` for all web browsing, never use `mcp__claude-in-chrome__*`) with no indication it was optional.

## 1.32.0 - 2026-07-11

### Added

- Added `scripts/setup-machine.sh`, a one-time, per-machine installer for Bun, gstack, goose, and goosetown, run explicitly and separately from `scripts/bootstrap.sh` (which continues to only ever write files into an adopting repository, never make network calls beyond `git submodule add`). Idempotent — skips any tool already present — and automatically detects and works around the Playwright too-new-distro browser-install gap documented in v1.31.0's `INTEGRATION.md` addition. `templates/CLAUDE.md`, `templates/.goosehints`, and `INTEGRATION.md` now point to it as the fast path alongside the existing manual per-tool instructions.
- Added `scripts/test_setup_machine.sh` (7 cases), exercising the real install code paths — not just mocked function calls — against local git-repo and installer-script fixtures wired in through `setup-machine.sh`'s new `GSTACK_REPO_URL`/`GOOSE_INSTALLER_URL`/`GOOSETOWN_REPO_URL`/`BUN_INSTALLER_URL` overrides, per `TESTING.md` "Governance Tooling Must Be Tested." Caught two real bugs during development: gstack's `./setup` output was being captured into a temp file that was deleted even on failure (so a failure's diagnostic output was unrecoverable — fixed by streaming through `tee`), and the Playwright-fallback test's own fixture initially checked for the override platform in `bunx`'s arguments instead of its environment, which doesn't reflect how `PLAYWRIGHT_HOST_PLATFORM_OVERRIDE` is actually passed.

### Fixed

- `scripts/check_secrets.sh` and `scripts/test_check_secrets.sh` (added in v1.31.0's merge) had also lost their executable bit, same root cause as the eight scripts fixed in v1.31.0. Restored `+x` for consistency with every other script under `scripts/`.

## 1.31.0 - 2026-07-11

### Added

- `templates/CLAUDE.md` and `templates/.goosehints` now carry real, verified install instructions for gstack (`garrytan/gstack`, requires Bun) and goose/goosetown (`aaif-goose` org, renamed from `block`) instead of only naming the tools and skill lists. `INTEGRATION.md`'s "gstack and gbrain" and "Goose and Goosetown" sections gained the same concrete commands, plus a documented workaround (`PLAYWRIGHT_HOST_PLATFORM_OVERRIDE`) for gstack's browser install failing on Linux distros newer than Playwright's support matrix. Previously an agent following these docs literally had no path to actually install anything — "follow the installation guide for your platform" pointed nowhere.
- Added a "Visual Architecture" policy to `ARCHITECTURE.md` requiring every README.md to carry a directory-tree project structure section and, **whenever possible**, at least one infographic — a Mermaid component/flow diagram — as the default expectation rather than an exception reserved for complex systems, kept current the same way as the existing "Current Capabilities" requirement. `CONSTITUTION.md` Principle 6 and `DOCUMENTATION.md`'s README Expectations now point to it. `templates/README.md` gained a "Project Structure" tree placeholder plus an explicit prompt to add an infographic, and `templates/docs/ARCHITECTURE.md`'s Component Diagram section gained a worked Mermaid example, so adopting repositories start with the pattern instead of a bare comment. This repository's own `README.md` carries a real "Project Structure" tree and a "How It Works" Mermaid diagram of the adoption flow, serving as the worked example the policy points to.
- Added `scripts/check_release_tag_alignment.sh`, a source-repo checker that verifies the released `VERSION`, the matching `v<VERSION>` tag, and `HEAD` all stay aligned. This catches the specific failure mode where framework changes are merged and versioned but the release tag is never cut, leaving adopter audits and version gates stuck on the previous release.
- Added `scripts/test_check_release_tag_alignment.sh` covering the aligned case plus missing-tag, tag-off-HEAD, latest-tag-mismatch, and usage-error failures.
- Added `scripts/check_secrets.sh`, a zero-dependency (bash + Git only) secrets sweep: it flags credential-shaped filenames (`.env`, `id_rsa`, `*.pem`, `credentials.json`, `terraform.tfstate`, ...) and high-confidence content patterns (AWS access keys, GitHub/Slack tokens, PEM private key blocks, Google/Stripe API keys) across both tracked files and untracked-but-not-gitignored files, and reports whether `.gitignore` covers the known secret-file patterns. A real hit always fails, with or without `--strict`; `--strict` only governs the separate `.gitignore`-coverage recommendation. Sweeping the whole project for secrets that should be gitignored is now standard practice on every repository adopting this constitution, enforced both locally and in CI, not left to individual discipline.
- Added `scripts/test_check_secrets.sh` (7 cases) covering tracked and untracked secret hits, the `.env.example` placeholder exclusion, full and missing `.gitignore` coverage under `--strict`, and the usage-error path.
- Added `templates/.github/workflows/constitution-secrets.yml`, wired into `scripts/bootstrap.sh` exactly like the existing compliance/version/tests/doc-freshness templates, running the secrets sweep on every push, pull request, and a daily schedule.
- Added a `pre-push`-stage local hook to `templates/.pre-commit-config.yaml` that runs `constitution/scripts/check_secrets.sh` before every `git push`, so the sweep happens before a secret ever reaches a remote rather than only after CI runs.

### Changed

- `RELEASES.md` now tells maintainers to run `scripts/check_release_tag_alignment.sh` immediately after tagging, so release follow-through is checked with the same rigor as the document-version guardrails.
- `ARCHITECTURE.md`'s "Visual Architecture" policy and `DOCUMENTATION.md`'s "Binary Assets and Images" section now document that GitHub's native mobile apps do not render `mermaid` fenced code blocks (only github.com in a browser does, with no fix on GitHub's roadmap), and prescribe committing a README's primary Mermaid diagram as both `.mmd` source and a pre-rendered SVG image so it displays on every client.
- `AI_WORKFLOW.md`, `SECURITY.md`, `TESTING.md`, and `INTEGRATION.md` now document the secrets sweep as a required step before pushing, alongside the other CI-enforced governance checks.

### Fixed

- `scripts/run_declared_tests.sh` and seven other scripts under `scripts/` had lost their executable bit (likely a checkout/tooling artifact, not a deliberate change — all other scripts are invoked via `bash scripts/foo.sh` throughout this repo and its own test suite, which masked the issue everywhere except `test_run_declared_tests.sh`'s one direct-execution test path). Restored `+x` on all of them.
- `README.md`'s "How It Works" diagram no longer falls back to raw Mermaid source text when viewed in GitHub's native iOS/Android apps. It's now a pre-rendered SVG (`assets/diagrams/how-it-works.svg`) embedded as a normal image, with the editable Mermaid source and regeneration instructions kept alongside it in `assets/diagrams/`.
- Redesigned that same diagram: mermaid's default theme (clashing yellow cluster backgrounds, saturated purple nodes) is replaced with a muted custom theme, a feedback-loop edge that tangled under auto-layout is removed in favor of a one-directional flow, the layout switched from wide/short (`LR`) to tall/narrow (`TD`) so the embedded image scales up and stays legible on a phone-width column instead of shrinking its text, and node/rank/diagram spacing increased (`nodeSpacing`, `rankSpacing`, `diagramPadding` in `mermaid-config.json`) so it no longer reads as cramped. `ARCHITECTURE.md`'s "Visual Architecture" policy and `assets/diagrams/README.md` document these choices for future diagrams.
- Framework-repo agent-config files (`CLAUDE.md`, `.agent-instructions.md`, `.project-rules.md`, `.cursorrules`, `.openhands_instructions`, `SYSTEM_PROMPT.md`, `CONTRIBUTING.md`, `HELP.md`) pointed at governance docs via the adopter-only `constitution/` submodule prefix (for example `constitution/CONSTITUTION.md`), a path that does not resolve inside this repository where those docs live at the root. They now use root-relative paths, matching the already-correct `AGENTS.md` and `COPILOT_INSTRUCTIONS.md`. The `templates/` copies keep the `constitution/` prefix, which is correct for adopters that mount the framework as a submodule.

### Added

- Added an "Adding Reference Sources to the Constitution" section to `README.md`: a short, self-contained walkthrough of the `sources/` workflow (drop a file in `sources/raw/`, `scan`, write a summary, `record`) plus the deliberate, separately-reviewed step of promoting a summary's insight into an actual constitution document. The full reference remains `KNOWLEDGE_SOURCES.md`; this closes the gap where that workflow was only reachable via a one-line pointer in "Repository Contents." Also fixed the "Manual Installation" section's code fence, which was left unclosed, silently swallowing everything after it.

## 1.30.0 - 2026-07-04

### Added

- Added a small worked demo to `sources/` — `raw/example/sample-source.md` and its matching `summaries/example/sample-source.md`, already recorded in `manifest.tsv` — so `scripts/check_source_summaries.sh scan` reports something real (`OK`) immediately after cloning instead of an empty, unexplained directory. Added `sources/README.md` and a gitignore-excepted `sources/raw/README.md` pointing back to `KNOWLEDGE_SOURCES.md` so the workflow is discoverable from a file browser alone.
- Added `scripts/run_declared_tests.sh`, which extracts and runs the "Full suite" command an adopting repository declares in `docs/TEST_PLAN.md`, so "run all automated tests" is enforced in CI instead of depending on an agent remembering to run them. A declared command that fails always fails this checker, with or without `--strict` — `--strict` only governs the "nothing declared yet" case. Added `scripts/test_run_declared_tests.sh` covering both.
- Added `scripts/check_doc_freshness.sh`, a blunt CI tripwire that flags a pull request changing source files without touching `README.md`/`CHANGELOG.md`, with an ignore list for docs/lockfiles/dotfiles. Added `scripts/test_check_doc_freshness.sh`, including the case proving the ignore list actually suppresses false positives rather than flagging everything.
- Added two CI workflow templates, installed by `scripts/bootstrap.sh` alongside the existing compliance/version gates: `constitution-tests.yml` (runs `run_declared_tests.sh` on push/PR) and `constitution-doc-freshness.yml` (runs `check_doc_freshness.sh` on PRs). Both warn by default; `--strict` opts a repository in once it's actually compliant, matching the existing `check_compliance.sh`/`check_traceability.sh` rollout contract.
- Added a "CI Enforcement" section to `TESTING.md` describing all four CI gates and their shared warn/`--strict` contract.

### Changed

- `DOCUMENTATION.md` gets a dedicated "Current Capabilities" section (promoted out of a single README-expectations bullet): every project needs a living, accurate "what can it do today?" answer, updated in the same change that adds/changes/removes functionality, not deferred to a separate documentation pass. `CONSTITUTION.md` Principle 1 and `AI_WORKFLOW.md`'s documentation step and completion checklist now call this out explicitly by name instead of folding it into generic "update documentation" language.
- `AI_WORKFLOW.md` strengthens the test-writing and documentation steps: add as many automated tests across the pyramid as a change genuinely calls for, run `run_declared_tests.sh` locally before calling work done, and keep README's features list current — with CI's new gates as the backstop, not the reason to skip verifying locally.
- `INTEGRATION.md` documents the two new CI workflows alongside the existing compliance/version-gate sections.

### Fixed

- `scripts/check_source_summaries.sh` no longer treats a `README.md` (or `readme.markdown`/`readme.txt`) left in `sources/raw/` as a pending source, even though `.md` is a recognized extension — it's documentation, not something to summarize. `record` also refuses to record one. Caught while adding the `sources/raw/README.md` pointer above, which `scan` was reporting as a false `NEW` entry before this fix. Covered by a new negative-case test in `scripts/test_check_source_summaries.sh`.

## 1.29.0 - 2026-07-03

### Added

- Added placeholder-content detection to `scripts/check_compliance.sh`, so repositories no longer pass compliance with copied template text still sitting in recommended or product-facing governance docs.
- Added `scripts/test_check_compliance_placeholders.sh` covering recommended and product-facing placeholder failures.

### Changed

- Clarified in `DOCUMENTATION.md` that copied template placeholders do not count as finished documentation and should be customized or removed before a repository is considered aligned.

## 1.28.0 - 2026-07-03

### Added

- Added `sources/`, a drop-in location for book and reference sources (PDF/EPUB/DOCX/MD/TXT) that feed the constitution the same way *Clean Architecture* and *Design Patterns* already do, without absorbing new influence ad hoc. Raw files live in `sources/raw/` and are gitignored (copyright, repo bloat); distilled summaries live in `sources/summaries/` and are tracked, mirroring each raw file's relative path.
- Added `scripts/check_source_summaries.sh`, a governance-tooling script (`scan` / `record`) that hashes files under `sources/raw/` against `sources/manifest.tsv` to report `NEW`, `CHANGED`, `SUMMARY_MISSING`, `OK`, and `ORPHANED SUMMARY` entries, plus `scripts/test_check_source_summaries.sh` covering all five states and the negative case where `record` refuses to run before a summary exists (per `TESTING.md`, "Governance Tooling Must Be Tested").
- Added `KNOWLEDGE_SOURCES.md` documenting the drop-in workflow and the summary template (Title, Author, Processed date, Why This Matters, Key Takeaways, Where It Could Apply).
- `mcp-server/index.js` now dynamically lists every file under `sources/summaries/` as a `constitution://source-summary/<relative-path>` resource at request time, alongside the existing static constitution-document resources, so MCP-connected agents can pull in distilled source knowledge without reading the filesystem directly.

## 1.27.0 - 2026-07-02

### Added

- `AI_WORKFLOW.md`'s Required Workflow now includes an explicit step to evaluate whether accumulated work should trigger a release (bump `VERSION`, tag, publish) rather than leaving user-facing changes sitting in `CHANGELOG.md`'s `Unreleased` section indefinitely, plus a matching "Before Completing Work" checklist item. Prompted by an adopting repository (AI Process Engineer) whose entire multi-month history sat unreleased — every session dutifully updated `CHANGELOG.md` but nothing ever prompted an agent to actually run the Cutting a Release process from `RELEASES.md`.

### Changed

- `CONSTITUTION.md` Principle 10 (Release Discipline) now points to `AI_WORKFLOW.md` and `RELEASES.md` for the release-cadence process, mirroring how Principle 6 (Architecture Awareness) points to `ARCHITECTURE.md`.

## 1.26.0 - 2026-07-02

### Added

- Added `scripts/check_version_alignment.sh`, a governance checker adopters can run through the `constitution/` submodule to verify that their pinned `constitution/VERSION`, optional `CONSTITUTION_VERSION` file, and common adoption/governance docs do not drift apart. This catches a recurring stewardship failure mode where a repo updates the submodule pointer but leaves stale "Engineering Constitution version X.Y.Z" text behind in README, agent instructions, or adoption notes.
- Added `scripts/test_check_version_alignment.sh` with negative-case coverage for a mismatched `CONSTITUTION_VERSION`, a stale governance-document reference, a missing `constitution/VERSION`, and usage errors.
- Added a "review non-default branches, worktrees, and open pull requests" step to `AI_WORKFLOW.md`'s Required Workflow and "Before Beginning Work" checklist, so agents check for related or conflicting in-progress work before starting rather than discovering it during cleanup.

### Changed

- Documented the new version-alignment checker in `README.md`, `INTEGRATION.md`, and `TESTING.md` so adopters know when to run it alongside the existing compliance and traceability checks.
- Strengthened the Git-cleanup guidance in `AI_WORKFLOW.md`: completed work must be merged (or have an open pull request) before its branch is deleted, and agents must not delete branches or worktrees they did not create without a human confirming they're safe to remove — they may belong to another in-progress session or automation.

## 1.25.0 - 2026-06-29

### Added

- Added a GitHub Copilot **custom agent**, "Solon", at `.github/agents/solon.agent.md` (and the adopter template `templates/.github/agents/solon.agent.md`). Solon is a constitution-aware persona for GitHub Copilot in Visual Studio 2026 (v18.4+) that reviews and guides changes against the constitution's principles and required workflow, distinguishing must-fix violations from opportunities to record in `TODO.md`. The bootstrap script now installs it into adopting repositories, and `scripts/test_bootstrap.sh` asserts its presence.
- Added a "GitHub Copilot Custom Agent (Solon)" section to `INTEGRATION.md` covering invocation (`@Solon` or the agent picker), the user-level `%USERPROFILE%/.github/agents/` location for cross-project use, and customization. Added Solon to the "Override Locations by Agent" table, the Project File Structure diagram, and the migration/update diff checklists.

### Fixed

- Corrected the context-file paths in the root `COPILOT_INSTRUCTIONS.md`, which pointed at a non-existent `constitution/` subdirectory. In this framework repository the constitution documents live at the repository root (as `AGENTS.md` already referenced them), so the `constitution/` prefix resolved to nothing. Adopter templates under `templates/` are unaffected — they correctly use the `constitution/` submodule prefix.

## 1.24.0 - 2026-06-28

### Changed

- Rewrote the release checklist in `RELEASES.md` into an ordered, concrete "Cutting a Release" gate that explicitly covers bumping every in-repo version reference (the `README.md` "Current version" line and `CONSTITUTION.md` header), with a grep step to catch stragglers. Addresses a recurring miss where the README version banner lagged the released `VERSION` across the 1.21.0–1.23.0 releases.
- Added a "Publishing a GitHub Release" section to `RELEASES.md` clarifying that a Git tag and a GitHub Release are distinct, and documenting the `gh release create … --latest` step that publishes human-facing notes from the version's CHANGELOG section. The framework's earlier releases were tagged inconsistently and never published as Releases.

## 1.23.0 - 2026-06-28

### Added

- Added a "Design Principles" section to `ARCHITECTURE.md` codifying the SOLID principles (SRP, OCP, LSP, ISP, DIP) and the Dependency Rule as pragmatic guardrails. Each principle is stated as a one-line rule with a concrete code smell and an actionable guardrail, drawing on Robert C. Martin's *Clean Architecture* (2017). The section emphasizes applying principles where they reduce real coupling rather than as ceremony.
- Added a "Design Patterns" subsection to `ARCHITECTURE.md` covering the two governing maxims from the Gang of Four's *Design Patterns* (1994) — "program to an interface" and "favor composition over inheritance" — plus a curated subset of high-leverage patterns (Factory, Adapter, Decorator, Facade, Strategy, Observer, Command, Template Method) with guidance on when to reach for each and an anti-pattern guardrail against premature or decorative pattern use.

### Changed

- `CONSTITUTION.md` Principle 6 (Architecture Awareness) now points to the SOLID principles and Dependency Rule in `ARCHITECTURE.md` for code-level structure guidance.

## 1.22.0 - 2026-06-27

### Added

- Added Continue.dev template at `templates/.continue/config.json`. The bootstrap script installs it into every adopted repository, setting a system message that loads the constitution reading order and workflow for in-editor AI sessions.
- Added Aider templates: `templates/.aider.conf.yml` (disables auto-commits, loads constitution files as read-only context) and `templates/.aiderignore` (prevents aider from modifying the read-only `constitution/` submodule). Both are installed by `scripts/bootstrap.sh`.
- Added `templates/.pre-commit-config.yaml` with a language-agnostic baseline of pre-commit hooks (trailing whitespace, end-of-file fixer, YAML/JSON syntax checking, merge-conflict marker detection, large-file guard, and private-key detection). Installed by `scripts/bootstrap.sh`.
- Added `templates/.devcontainer/devcontainer.json` providing a reproducible Ubuntu 24.04 development container with Node.js, Git, and VS Code extensions for Copilot and Continue.dev. Runs `git submodule update --init --recursive` on container creation so the constitution submodule is always ready. Installed by `scripts/bootstrap.sh`.
- Added Continue.dev and Aider to the "Override Locations by Agent" table in `INTEGRATION.md`.
- Added dedicated sections to `INTEGRATION.md` for Continue.dev, Aider, Pre-Commit Hooks, and Devcontainer, each covering configuration, customization examples, and language-specific override patterns.
- Added "Migrating Existing Repositories to New Framework Versions" section to `INTEGRATION.md` with a five-step checklist (read changelog → diff templates → copy new files → run new tool-setup steps → commit) so existing adopters can pick up new framework features after merging a Dependabot constitution update PR.
- Updated the Project File Structure diagram in `INTEGRATION.md` to include the new files.

### Changed

- `scripts/bootstrap.sh` now installs `.continue/config.json`, `.aider.conf.yml`, `.aiderignore`, `.pre-commit-config.yaml`, and `.devcontainer/devcontainer.json`, and reports their status in the adoption report.
- Adoption report "Recommended Tool Setup" section now includes the pre-commit activation command and MCP server prep step alongside the existing gstack instructions.
- `INTEGRATION.md` "Application" paragraph updated to name the full set of tool-specific files that load automatically.

## 1.21.0 - 2026-06-27

### Added

- Added gstack and gbrain setup to the framework. `templates/CLAUDE.md` now includes a `## gstack` section with the full skills list and the rule to always use `/browse` for web browsing instead of `mcp__claude-in-chrome__*` tools. This section propagates to every adopted repository via `scripts/bootstrap.sh`, so all projects inherit gstack conventions automatically.
- Added a "gstack and gbrain" section to `INTEGRATION.md` covering installation, gbrain initialization via `/setup-gbrain`, the required browser-automation conventions, the skill reference table, and goosetown integration guidance.
- Added a "Recommended Tool Setup" section to the `scripts/bootstrap.sh` adoption report, instructing adopters to run `/setup-gbrain` and `/setup-deploy` in Claude Code after completing the merge steps.

### Changed

- `AI_WORKFLOW.md` "During Work" section now explicitly requires using the `/browse` gstack skill for all web browsing and prohibits direct `mcp__claude-in-chrome__*` tool calls.

## 1.20.0 - 2026-06-27

### Added

- Added `examples/OPERATIONS.example.md`, a fully worked `docs/OPERATIONS.md` runbook for a fictional deployed service ("Orders API"). It fills in every section the blank template leaves as a placeholder — environments and promotion path, toolchain prerequisites, deployment procedure with approvals and rollback, monitoring/alert thresholds, backup and restore (with a restore drill), maintenance mode, expand/contract migrations, secrets and rotation, dependency failure behavior, and an incident-response runbook with severities, on-call, and common runbooks.

### Changed

- Referenced the worked operations example from `OPERATIONS.md`, `DOCUMENTATION.md`, the blank `templates/docs/OPERATIONS.md`, and the `README.md` repository contents so adopters can find a complete model when populating their own runbook.

## 1.19.0 - 2026-06-27

### Added

- Added `templates/.github/workflows/constitution-compliance.yml`, a CI gate that `scripts/bootstrap.sh` now installs into every adopted repository. It runs `constitution/scripts/check_compliance.sh` to confirm the required governance files are present and `constitution/scripts/check_traceability.sh` to confirm every declared requirement has a verifying test (the traceability step runs only when `docs/PRODUCT_REQUIREMENTS.md` and `docs/REQUIREMENTS_TRACEABILITY.md` exist, so non-product repositories are not forced to maintain them). Runs on pull requests, pushes to the default branch, and a daily schedule. This turns the two checkers from on-demand tools into enforced gates, alongside the existing version gate.

### Changed

- `scripts/bootstrap.sh` installs the compliance workflow and records it in the adoption report; `scripts/test_bootstrap.sh` verifies it is installed.
- Documented the compliance gate workflow in the `INTEGRATION.md` "Verifying Adoption Compliance" section.

## 1.18.0 - 2026-06-27

### Added

- Added `scripts/check_compliance.sh`, a reference checker that verifies an adopting repository carries the governance files the constitution expects. It checks three tiers — required (the `DOCUMENTATION.md` "Required Files" plus the adoption markers `AGENTS.md`, `CLAUDE.md`, `VERSION`, and the `constitution/` submodule), recommended (the "Strongly Encouraged" files), and product-facing (`docs/PRODUCT_REQUIREMENTS.md`, `docs/REQUIREMENTS_TRACEABILITY.md`) — and exits non-zero on a missing required file. `--strict` promotes recommended gaps to failures and `--product` promotes product-facing gaps to failures. Adopters run it from their repository root through the `constitution/` submodule.
- Added `scripts/test_check_compliance.sh` with positive and negative cases per the "Governance Tooling Must Be Tested" standard, including a missing required file, a missing `constitution/` submodule directory, recommended-tier warn-vs-strict behavior, product-facing warn-vs-`--product` behavior, and usage errors.

### Changed

- Added a "Verifying Adoption Compliance" section to `INTEGRATION.md` describing how to run the compliance checker through the submodule and noting that the constitution source repository is intentionally not a self-compliant target.
- Noted the compliance checker alongside the traceability checker in the `TESTING.md` "Governance Tooling Must Be Tested" standard.

## 1.17.0 - 2026-06-27

### Added

- Added `scripts/check_traceability.sh`, a reference requirements-traceability checker that confirms every requirement ID declared in `docs/PRODUCT_REQUIREMENTS.md` has a non-empty verifying-test entry in `docs/REQUIREMENTS_TRACEABILITY.md`. It matches IDs by exact matrix-cell value (never by substring) so a layered ID such as `BB-FR-007` cannot satisfy a check for the system-layer `FR-007`, parses each table by its own header columns so an unrelated table (for example the Coverage Summary) is not read as requirements, and exits non-zero when any requirement is missing a row or has only a gap entry. Adopters run it through the `constitution/` submodule.
- Added `scripts/test_check_traceability.sh` with positive and negative cases per the "Governance Tooling Must Be Tested" standard, including the `BB-FR-007` / `FR-007` substring-collision case, gap-marker and unfilled-placeholder detection, the layered-ID independence case, multi-table parsing, and usage errors.

### Changed

- Pointed the "Governance Tooling Must Be Tested" standard in `TESTING.md` at the shipped `scripts/check_traceability.sh` as the worked reference implementation.
- Added a "Verifying the Flow Automatically" subsection to the `INTEGRATION.md` traceability flow describing how to run the checker through the submodule and gate CI on it.

## 1.16.0 - 2026-06-24

### Added

- Added a **Threat Modeling Triggers** section to `SECURITY.md` enumerating concrete changes that mandate a threat model (new egress path, new auth/authz surface, new data leaving the boundary, new trust-sensitive dependency, new untrusted-input sink). Added a matching checklist item to `templates/SECURITY.md` so adopters inherit the trigger.
- Added a **Toolchain Parity** standard to `OPERATIONS.md` requiring repositories to pin their toolchain, declare minimum tool versions, and provide a fast prerequisite check (for example, `make doctor`) that fails fast with a clear message. Enriched `templates/docs/SETUP.md` with a "Verify Prerequisites" step.
- Added a **Binary Assets and Images** section to `DOCUMENTATION.md`: render-inline images are committed as normal web-optimized blobs (large originals go to LFS), with a `.gitattributes` LFS override and explicit verification (`git lfs ls-files` / `git lfs fsck`) before a push is considered complete.
- Added a **Governance Tooling Must Be Tested** section to `TESTING.md` requiring reference checkers and gates to ship unit tests including negative cases, with the traceability-checker substring-collision case called out.
- Added a **Requirement ID Grammars Must Not Collide** subsection and a dedicated **Architecture Decision Records** section to `DOCUMENTATION.md` documenting the ADR status lifecycle, relationships, and promotion criteria.
- Added a **Repository Settings Checklist** to `INTEGRATION.md` (enable "Automatically delete head branches", default-branch protection, Dependabot submodule PRs); the bootstrap adoption report now recommends these settings.

### Changed

- Enriched `templates/ADR.md` with a `Proposed → Accepted → Superseded/Deprecated` status lifecycle, a `Relationships` field (`extends` / `supersedes` / `related`), and a `Promotion Criteria` section for `Proposed` ADRs. Updated `CONSTITUTION.md` Principle 6 and the sample-project ADR to match.
- Corrected the stale `CONSTITUTION.md` version header (was `1.12.0`) and the `README.md` version display to track the released `VERSION`.

## 1.15.0 - 2026-06-13

### Added

- Added automated constitution version enforcement so adopting repositories stay on the latest release. `scripts/bootstrap.sh` now installs two templates into every project:
  - `.github/workflows/constitution-version.yml` — a CI gate that runs on pull requests, pushes to the default branch, and a daily schedule, and **fails the build** when the pinned `constitution/` submodule is behind the latest `v*` release tag.
  - `.github/dependabot.yml` — a `gitsubmodule` Dependabot configuration that opens a pull request whenever the constitution submodule falls behind, scoped to the `constitution` submodule.
- Added `scripts/audit_adopters.sh`, a fleet audit that scans parent directories and reports each adopting repository as `CURRENT`, `BEHIND`, or `AHEAD/DIVERGED`, exiting non-zero when any repository is behind so it can drive a centralized check.
- Added `scripts/test_audit_adopters.sh` covering the current, behind, and non-adopter cases and the script's exit status.
- Added a "Keeping Adopters On the Latest Version Automatically" section to `INTEGRATION.md` describing the auto-update, CI gate, and audit layers.

### Changed

- Added a "Git Tags" rule to `RELEASES.md` requiring every release to be tagged `vMAJOR.MINOR.PATCH`; the CI gate and audit script compare adopters against the latest release tag.
- `scripts/test_bootstrap.sh` now verifies the Dependabot config and version-check workflow are installed.

## 1.14.0 - 2026-06-13

### Added

- Added an "Example Traceability Flow" section to `INTEGRATION.md` showing the concrete path from a product requirement ID through the traceability matrix, test plan coverage gaps, the verifying test, and a TODO follow-up. Salvaged from the abandoned `codex/constitution-traceability-docs` branch (the obsolete README version edit it also carried was dropped).

## 1.13.0 - 2026-06-13

### Added

- Added Goose / Goosetown integration. `scripts/bootstrap.sh` now installs a `.goosehints` bridge file in every adopted repository so the [goose](https://github.com/aaif-goose/goose) agent — and the [goosetown](https://github.com/aaif-goose/goosetown) multi-agent orchestrator that wraps it — apply the constitution's reading order and standards on every task.
- Added a "Goose and Goosetown" section to `INTEGRATION.md` covering the `.goosehints` hints file, multi-agent reviewer expectations, and how to register the constitution MCP server (`mcp-server/`) as a goose stdio extension.
- Added `.goosehints` coverage to `scripts/test_bootstrap.sh`.

### Changed

- Added Goose / Goosetown to the agent override table, the auto-loading tool-file list, and the project file structure tree in `INTEGRATION.md`.

## 1.12.0 - 2026-06-13

### Added

- Standardized the "Eric's Engineering Constitution" adoption badge as part of the framework. `scripts/bootstrap.sh` now adds or refreshes the badge in every adopted repository's `README.md`, including existing READMEs that are otherwise preserved.
- Added idempotent badge handling using stable `<!-- CONSTITUTION_START -->` / `<!-- CONSTITUTION_END -->` markers: the badge is inserted after the first heading (or prepended when there is no heading), refreshed in place on re-runs, and never duplicated.
- Added a "Files Updated In Place" section to the bootstrap adoption report so badge updates to existing files are recorded.
- Added `scripts/test_bootstrap.sh` coverage for badge injection, idempotency, and the no-heading case.

### Changed

- The README badge link is derived from the bootstrap source URL when it is a public Git URL, falling back to the canonical repository otherwise.

## 1.11.0 - 2026-06-13

### Added

- Added continuous coverage evaluation, coverage targets, and coverage gap analysis guidance to `TESTING.md`.
- Added requirements traceability guidance to `DOCUMENTATION.md`, including stable requirement identifiers and explicit acceptance criteria.
- Added `docs/TEST_PLAN.md` template with coverage targets, a continuous coverage record, and a coverage gap log.
- Added `docs/REQUIREMENTS_TRACEABILITY.md` template providing a requirement-to-test traceability matrix.

### Changed

- `docs/PRODUCT_REQUIREMENTS.md` template now uses numbered requirement IDs (`FR-`/`NFR-`), per-requirement acceptance criteria, and links to the traceability matrix.
- Strengthened `CONSTITUTION.md` Principles 1 and 2 to require requirements traceability and continuous coverage evaluation.
- Added coverage-gap and traceability steps to `AI_WORKFLOW.md` and the `CLAUDE.md` completion checklists.
- `scripts/bootstrap.sh` now installs the test plan and requirements traceability templates.

## 1.10.0 - 2026-06-12

### Added

- Added framework-level operations and infrastructure standards in `OPERATIONS.md`.
- Added optional product requirements and MVP backlog documentation guidance.
- Added `docs/PRODUCT_REQUIREMENTS.md` and `docs/MVP_BACKLOG.md` templates for product-facing repositories.

### Changed

- Promoted operations review into the Constitution workflow and documentation expectations.
- Updated `CONSTITUTION.md`, `AI_WORKFLOW.md`, `DOCUMENTATION.md`, and `AGENTS.md` to make operational guidance part of the standard review path.
- Updated the sample project and operations template to reflect the new standards.
- Corrected the README version display to match `VERSION`.

## 1.9.0 - 2026-06-11

### Changed

- Rebranded the framework to **Eric's Engineering Constitution**.
- Updated all documentation, templates, and scripts to reflect the new name.
- Simplified `README.md` templates by replacing the dedicated "Engineering Constitution" section with a minimal badge/link at the top of the file.

## 1.8.1 - 2026-06-11

### Fixed

- Cleaned up `DevLaunchpad` repository by ignoring `.constitution-bootstrap/` and resetting submodule state.
- Documented the `version_analyzer.sh` tool in `RELEASES.md`.

## 1.8.0 - 2026-06-11

### Added

- Added `scripts/version_analyzer.sh` to help determine retroactive and proactive Semantic Version bumps based on project history.

## 1.7.0 - 2026-06-10

### Added

- Mandated **Semantic Versioning (SemVer)** for all projects in `CONSTITUTION.md`.
- Added a standard `VERSION` file template (initialized at `0.1.0`).
- Updated `bootstrap.sh` to install the `VERSION` file in all repositories by default.
- Enhanced `RELEASES.md` with explicit instructions for managing the `VERSION` file.

## 1.6.1 - 2026-06-10

### Fixed

- Improved `templates/README.md` with explicit `<!-- CONSTITUTION_START -->` markers to prevent documentation pollution during manual merging.
- Cleaned up `DevLaunchpad` README to remove redundant headers and duplicate description lines.

## 1.6.0 - 2026-06-10

### Added

- Added generic fallback and open-source agent bridge files: `.project-rules.md`, `.openhands_instructions`, and `SYSTEM_PROMPT.md`.
- Updated `bootstrap.sh` to install these files by default, completing the "Universal Instruction Bridge".

## 1.5.0 - 2026-06-10

### Added

- Added expanded universal discoverability: `.antigravity/instructions.md` (for Antigravity 2.0) and `CONTRIBUTING.md` (standard agent/human onboarding).
- Updated `bootstrap.sh` to install these new bridge files by default.

### Changed

- Renamed the "Universal Agent Discoverability" strategy to the "Universal Instruction Bridge" to reflect its multi-tool coverage.

## 1.4.0 - 2026-06-10

### Added

- Added universal agent discoverability files: `.agent-instructions.md` (for Devin, Gemini, etc.) and `.cursorrules` (for Cursor/legacy).
- Updated `bootstrap.sh` to install these universal entry points by default.

### Changed

- Updated `AGENTS.md` and other instruction files to be more assertive about the constitution's authority.

## 1.3.0 - 2026-06-10

### Added

- Added new standard documentation templates: `HELP.md`, `SECURITY.md`, `docs/SETUP.md`, `docs/COMMAND_REFERENCE.md`, `docs/TROUBLESHOOTING.md`, `docs/ARCHITECTURE.md`, `docs/AGENT_PROMPTS.md`, `docs/AGENT_HANDOFF.md`, and `docs/OPERATIONS.md`.
- Updated `bootstrap.sh` to automatically install these new templates in all repositories.
- Updated `DOCUMENTATION.md` to reflect the expanded documentation requirements.

### Changed

- `bootstrap.sh` now creates the `docs/` directory and populates it with standard templates by default.

## 1.2.0 - 2026-06-10

### Added

- Added automated test suite for `scripts/bootstrap.sh` in `scripts/test_bootstrap.sh`.
- Added migration guidance for existing project documentation to `DOCUMENTATION.md`.
- Added language-specific override examples (Node.js/TypeScript, Python/FastAPI) to `INTEGRATION.md`.

### Changed

- Updated `scripts/bootstrap.sh` to allow the `file` protocol for git submodules, supporting local repository sources.
- Rewrote README.md to eliminate repetitive install sections and clarify setup flow.
- Removed duplicate "Required Workflow" list and "Repository Integration Strategy" from CONSTITUTION.md; both are now covered in AI_WORKFLOW.md and README.md/INTEGRATION.md.

### Fixed

### Removed

### Security

## 1.1.0 - 2026-06-08

### Added

- Added `templates/.github/copilot-instructions.md` for GitHub Copilot auto-loading via the standard `.github/` location.
- Added `templates/.cursor/rules/project.mdc` for Cursor auto-loading with `alwaysApply: true` frontmatter.
- Added `INTEGRATION.md` documenting agent reading order, project-specific override patterns, VERSION-based update strategy, and project file structure.
- Updated bootstrap script to install `.github/copilot-instructions.md` and `.cursor/rules/project.mdc` instead of root-level `COPILOT_INSTRUCTIONS.md`.
- Updated sample project to include `.github/copilot-instructions.md` and `.cursor/rules/project.mdc`.

### Changed

- `scripts/bootstrap.sh` now creates `.github/copilot-instructions.md` (GitHub Copilot standard location) and `.cursor/rules/project.mdc` (Cursor standard location) instead of the generic root-level `COPILOT_INSTRUCTIONS.md`.
- README updated to reflect new template files and project structure.
- AGENTS.md updated to include `INTEGRATION.md` in the required reading list.
- VERSION bumped to 1.1.0.

### Fixed

### Removed

### Security

## 1.0.0 - 2026-06-08

### Added

- Added Eric's Engineering Constitution Framework v1.0.0.
- Added AI workflow, testing, documentation, security, architecture, release, and TODO guidance.
- Added project templates for agent instructions, TODO, changelog, README, and ADRs.
- Added sample project structure.
- Added bootstrap script for integrating the constitution into existing Git repositories.

### Changed

### Fixed

### Removed

### Security

- Added security review standards covering validation, secrets, permissions, dependencies, logging, and auditing.
