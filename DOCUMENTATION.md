# Documentation Standards

Documentation is part of the deliverable.

## Core Qualities

Documentation should be:

- Accurate
- Current
- Actionable
- Version controlled

Template placeholders do not count as finished documentation. A file copied
from the constitution must be customized or trimmed until it describes the real
repository instead of the example/template state.

## Required Files

Every repository should include:

- README.md
- docs/HELP.md
- CHANGELOG.md
- TODO.md
- .github/SECURITY.md
- AGENTS.md
- wiki/Home.md

### Keeping the Repository Root Readable

The repository root is the first thing a reader sees, so only files that must
live there belong there. Governance documents live where the hosting platform
still finds them:

| Document | Location | Why |
| --- | --- | --- |
| SECURITY.md | `.github/` | GitHub renders it as the security policy from `.github/` exactly as it does from the root. |
| CONTRIBUTING.md | `.github/` | Same: GitHub links it from the issue and pull request UI wherever it lives. |
| HELP.md | `docs/` | Read by humans, not tooling; belongs with the rest of the documentation. |
| SYSTEM_PROMPT.md | `docs/` | Reference material pasted into tools by hand, not auto-loaded. |

Repositories that adopted the constitution before v1.38.0 may keep these files
in the root. `scripts/check_compliance.sh` accepts either location, so moving
them is a cleanup you can schedule rather than a migration you must perform.

Agent instruction files follow the same principle. `AGENTS.md` is the
cross-vendor standard and is the only one every repository needs. Files that
exist solely because a tool hardcodes its own name — `CLAUDE.md`,
`.cursorrules`, `.goosehints`, `.openhands_instructions`, and the rest — are
installed only for the tools a project actually uses, via
`bootstrap.sh --agents=<list>`. Do not add a vendor file for a tool nobody on
the project runs.

## Strongly Encouraged

Repositories should also include:

- .github/CONTRIBUTING.md
- docs/SETUP.md
- docs/COMMAND_REFERENCE.md
- docs/TROUBLESHOOTING.md
- docs/ARCHITECTURE.md
- docs/adr/
- docs/AGENT_PROMPTS.md
- docs/AGENT_HANDOFF.md
- docs/PRODUCT_REQUIREMENTS.md for product-facing applications
- docs/REQUIREMENTS_TRACEABILITY.md for product-facing applications
- demo.html for product-facing applications
- docs/TEST_PLAN.md for repositories with automated tests
- docs/OTS_SOFTWARE.md for repositories with third-party dependencies
- docs/ENV_VARS.md for documenting environment variable requirements
- docs/MVP_BACKLOG.md for early-stage products or prototypes
- docs/OPERATIONS.md
- docs/SESSION_PLAN.md for crash-recovery session planning
- docs/MEMORY.md for user-discretionary project memory (learnings, preferences, decisions)
- API documentation
- Wiki content when appropriate

## Operations Documentation Expectations

Projects with deployments, services, scheduled jobs, or operator workflows should maintain `docs/OPERATIONS.md`.

That document should cover:

- deployment or release procedure
- monitoring, metrics, and alert locations
- backup and restore expectations
- rollback guidance
- incident response notes

`examples/OPERATIONS.example.md` is a fully worked runbook for a fictional
deployed service that fills in every one of these sections; use it as a model
when populating `docs/OPERATIONS.md`.

## Session Planning

Agent sessions can crash, time out, or be interrupted mid-work. When this happens, the next session has no reliable record of what was planned — only what was partially done. `docs/SESSION_PLAN.md` closes this gap by documenting session intent **before** implementation begins.

- **Write before implementing**: at the start of each session, write or update `docs/SESSION_PLAN.md` with the session's goals, approach, files expected to change, and risks. See `AI_WORKFLOW.md`'s Required Workflow.
- **Update during work**: keep the Resumption Notes section current as work progresses, so the plan stays useful if the session is interrupted.
- **Clear after completing**: once the session's outcomes are captured in commit messages, `docs/AGENT_HANDOFF.md`, or `CHANGELOG.md`, clear or archive the plan. The file is overwritten at the start of the next session.
- **Complementary to AGENT_HANDOFF.md**: the session plan captures *intent before work*; the handoff captures *state after work*. They are bookends of a session lifecycle.

## Project Memory

As agents and humans work on a project, they establish codebase learnings, discover quirks, make styling preferences, and agree on architectural decisions. The project memory file `docs/MEMORY.md` serves as a durable, cross-platform memory bank.

- **Durable cross-session context**: AI agents read `docs/MEMORY.md` at the start of each session to align with past context, and propose updates at the end of a session.
- **User-Discretionary Control**: The memory file is strictly under the user's discretion. The agent MUST NOT write to or update `docs/MEMORY.md` without presenting the proposed additions/edits directly to the user for explicit approval at the end of the session.
- **Complementary to Session Plans and Handoffs**: While `docs/SESSION_PLAN.md` and `docs/AGENT_HANDOFF.md` capture the active/temporary context of a single session, `docs/MEMORY.md` preserves long-term, cumulative learnings and preferences.

## Wiki

A wiki is a high-altitude, navigable catalogue of a project — what it is, how to
use it, and how its pieces fit — sitting above the reference documents in `docs/`
and the `README.md`. "Wiki content" is named in `CONSTITUTION.md` Principle 1 and
in the Documentation Review Checklist; this section describes how the framework
expects one to be built and kept current. The decision behind it is recorded in
`docs/adr/0001-wiki-subsystem.md`.

- **Author in-repo, publish to the native wiki.** Wiki pages live under `wiki/`
  in the repository, in GitHub-wiki-native Markdown (`Home.md` as the landing
  page, `_Sidebar.md` for navigation, `[[Page Name]]` links that resolve to
  `Page-Name.md`). They are reviewed through normal pull requests and versioned
  with the code, then published to the repository's built-in GitHub wiki
  (`<repo>.wiki.git`) on merge, so the rendered wiki is never stale relative to
  its reviewed source. Editing pages directly in the GitHub wiki UI is avoided:
  that surface escapes pull-request review and CI.
- **Keep it current mechanically.** `constitution-wiki.yml` (installed from the
  templates) runs `check_wiki_freshness.sh`, which flags a pull request that adds
  or removes source files without touching `wiki/` — a blunt tripwire on
  structural change, following the warn-by-default / `--strict` rollout contract.
  It is a higher bar than the README/CHANGELOG doc-freshness tripwire and does
  not replace it. The same workflow's `links` job runs `check_wiki_links.sh`,
  which flags dangling `[[WikiLinks]]` and orphan pages so the two most common
  forms of wiki rot — a link to a page that does not exist, and a page nothing
  links to — are caught mechanically. The constitution runs this checker in
  `--strict` mode as a pre-publish gate, so a broken wiki never reaches readers.
- **No placeholders.** As with every other document here, a wiki page copied from
  a template is not finished documentation until it describes the real project.

A wiki is a **required** governance artifact (ADR-0001 is Accepted): every
adopting repository carries `wiki/Home.md`, `scripts/check_compliance.sh` treats
it as a required file, and `scripts/bootstrap.sh` installs the
`templates/wiki/Home.md` scaffold and the `constitution-wiki.yml` workflow so a
freshly bootstrapped repository has one from the start. An existing adopter that
predates this requirement will see a required-file gap from `check_compliance.sh`
until it adds a `wiki/Home.md`; the scaffold is the intended starting point.

## Binary Assets and Images

Documentation often depends on images, diagrams, and other binary assets. Handle them so they render reliably and large originals stay out of the main history.

- **Images that must render inline in Markdown** (README screenshots, concept art, badges) are committed as **normal, web-optimized blobs** — reasonably small files committed directly to Git. Large originals, source files (for example, `.psd`, `.fig`, raw exports), and high-resolution masters belong in Git LFS.
- When a repository uses Git LFS, add a `.gitattributes` override so the inline, web-optimized copies are **excluded** from LFS and stored as normal blobs. Inline images stored in LFS can fail to render on hosted Git platforms because of private-repo or LFS-bandwidth limits.
- **Verify LFS objects actually uploaded** before declaring a push complete. A pushed LFS pointer with a missing object looks fine locally but breaks for everyone else. Check with `git lfs ls-files` and `git lfs fsck`, and confirm inline images render in the hosted view.
- **A README's primary Mermaid diagram should be committed as both source and a rendered image**: the `.mmd` source for diffability, plus a pre-rendered SVG/PNG embedded via normal Markdown image syntax so it displays on clients that don't execute Mermaid (notably GitHub's native mobile apps — see `ARCHITECTURE.md`'s "Visual Architecture" section). Keep both files together (for example under `assets/diagrams/`) and regenerate the image whenever the source changes.

## Documentation Review Checklist

For each meaningful change, review whether updates are needed for:

- README.md
- CHANGELOG.md
- TODO.md
- Architecture documentation
- Product requirements
- Requirements traceability matrix
- Demo page (`demo.html`) for product-facing repositories
- Test plan and coverage records
- OTS software inventory (when dependencies were added, removed, or upgraded)
- Environment contract (when environment variables were added or removed)
- MVP or delivery backlog
- API documentation
- Deployment documentation
- Configuration documentation
- Troubleshooting guidance
- Wiki content

Also verify that any adopted template files no longer contain placeholder text
such as `<add here>`, example commands, or HTML comment prompts.

## README Expectations

README.md should explain:

- What the project does
- Its current features/capabilities — see "Current Capabilities" below
- Who it is for
- Which platforms it supports, and how to install or set it up on each of
  them — see "Every Platform the Project Supports" below
- How to run it, on each supported platform
- Where to see it working — link `demo.html`, and its published URL when the
  repository is product-facing; see "Demo Page" below
- How to test it, on each supported platform
- How to contribute or work with AI agents
- Where to find architecture and roadmap information
- Its project structure, plus at least one infographic (component or flow diagram) whenever possible — this is the default, not only for non-trivial systems; see `ARCHITECTURE.md`'s "Visual Architecture" section

It should say all of that without making the reader scroll past the parts
that do not apply to them: the page reads short by default and expands on
demand — see "Progressive Disclosure" below. `templates/README.md` is the
worked example of both rules, and this repository's own `README.md` follows
them. `scripts/check_readme.sh` checks their mechanical half — command
blocks come with named platforms; collapsed blocks render, stay one level
deep, are closed, and keep their headings outside — in warn mode from
`constitution-compliance.yml`, `--strict` on request.

### Every Platform the Project Supports

A README that gives one set of commands is a README written for the author's
machine. Developers arrive from Windows, macOS, and Linux, and the commands
differ in ways that stop a newcomer cold: the shell (PowerShell, `cmd`, Git
Bash, zsh, bash), the package manager (`winget`/`choco`, Homebrew,
`apt`/`dnf`), path separators and home directories, how a virtual environment
is activated, how an environment variable is set, line endings, and whether a
symlink can be created at all. "Assume Linux" is the usual default because
Linux is what CI runs; it is not what the reader runs.

- **Name the supported platforms up front**, in the quick-start or install
  section: the operating systems (and versions, where they matter) on which
  the project is built, run, and tested. A platform the project does not
  support is named as unsupported rather than left out — silence reads as
  "probably works".
- **Break instructions out per platform wherever the commands differ.**
  Install, setup, run, and test instructions each carry one block per
  platform — Windows, macOS, and Linux at minimum for anything a developer
  runs; the platforms the product itself targets (Android and iOS, a board, a
  browser) for product-facing repositories — not a single `bash` block with a
  footnote. When a command is identical everywhere, say so once ("same on
  every platform") rather than repeating it three times.
- **A Windows block is written for a Windows shell.** It names the shell it
  assumes (PowerShell, `cmd`, or Git Bash) and uses that shell's syntax —
  `$env:VAR = "x"` rather than `export VAR=x`, `.\.venv\Scripts\Activate.ps1`
  rather than `source .venv/bin/activate`. "Use WSL" is a Linux instruction
  wearing a hat: offer it as an option if it works, but it does not satisfy
  the Windows block on its own.
- **Verified, not guessed.** Each platform's block has been run on that
  platform, by a person or by CI, and the README says which platforms CI
  covers. An agent that cannot run a platform writes its block from the
  project's CI configuration and documented behavior, and says so in the
  pull request, rather than inventing commands.
- **The same rule covers every document that hands the reader a command** —
  `docs/SETUP.md`, `docs/COMMAND_REFERENCE.md`, `docs/TROUBLESHOOTING.md`,
  the wiki. The README is where it matters most, because the README is where
  the reader starts.

### Progressive Disclosure

A README that documents everything in one scroll documents nothing in the
first screen, and per-platform instructions make the scroll longer: three
blocks where there was one. Use the renderer's collapsible sections —
`<details>` with a `<summary>` line — so the page reads short by default and
a reader expands only what applies to them, the way a long post keeps its
TL;DR visible and tucks the rest away.

**Always visible**, never inside a collapsed block:

- The title, the badges, and the one-paragraph "what this is and who it is
  for".
- The current capabilities list ("Current Capabilities" above): it is the
  first thing a reader looks for and the first thing to go stale.
- The hero infographic (`ARCHITECTURE.md`, "Visual Architecture") and the
  link to the demo page.
- The quick start: the supported-platforms line and the shortest path to a
  running project. A command that is the same on every platform stays
  visible; the per-platform variants sit directly under it, one collapsed
  block each.
- Every `##` section heading, so the rendered outline still lists the whole
  document. Collapse the body under a heading, never the heading itself.
- The version line and the pointers to the rest of the documentation
  (roadmap, changelog, architecture, contributing).

**Collapsed by default:**

- Per-platform install, run, and test blocks — one `<details>` per platform,
  its `<summary>` naming the platform and the shell ("Windows (PowerShell)",
  "macOS (zsh)", "Linux (bash)").
- The project-structure tree once it runs past a dozen lines (the heading
  stays visible; the tree is still required, see `CONSTITUTION.md`
  Principle 6).
- Alternative installation paths (from source, Docker, manual), long
  configuration and command references, troubleshooting, and anything most
  readers will not need on a first visit.

Mechanics, learned the hard way:

- The `<summary>` says what is inside — "Windows (PowerShell)", "Full
  project structure", "Manual installation" — never "Click to expand" or
  "More".
- Leave a blank line after the `<summary>` line and another before
  `</details>`, or the Markdown inside (fences, lists, tables) will not
  render.
- One level of nesting. A collapsed block inside a collapsed block is where
  content goes to be lost.
- Headings inside a `<details>` block do not appear in the rendered outline
  and cannot be linked to reliably; keep `##` and `###` headings outside the
  block and let the summary line title what is inside.
- Where `<details>` is not supported — a package-registry page or a terminal
  renderer that drops HTML — the body is shown inline, so nothing is lost;
  the always-visible list above is still what a reader must see without a
  click.

This is a documentation-wide pattern, not a README-only one. Any long rendered
document — the demo page ("Demo Page" below), a reference doc, a brief — leads
with the short version a reader needs and tucks the depth behind `<details>`.
The worked shape is a "why this matters" or "details" expander beneath the
thing it explains: the headline claim stays visible, the reasoning is one click
away. The always-visible / collapsed split and the mechanics above are the
same wherever the renderer honors `<details>`.

## Current Capabilities

Every project that grows over time needs a living, accurate answer to "what
can it do today?" This is a standing requirement, not a one-time README
section written at v0.1 and left to go stale — it decays fastest precisely
when a project is expanding fastest, which is exactly when it matters most to
a new contributor or an AI agent orienting itself.

- README.md must carry a current features/capabilities list. Update it in
  the **same change** that adds, changes, or removes user-facing
  functionality — not deferred to a separate "documentation pass" that may
  never happen.
- This applies to any adopting repository, not only product-facing ones:
  internal tools, libraries, and CLIs all accumulate capability over time and
  all need this answer kept current.
- `TESTING.md`'s "CI Enforcement" section describes `check_doc_freshness.sh`,
  a blunt tripwire that flags a pull request changing source files without
  touching README.md/CHANGELOG.md. It can only verify the file was *touched*,
  never that the content is actually accurate — treat it as a backstop for
  the mechanical case, never as the standard itself.

## Demo Page

A README tells a reader what a project does. A demo page shows them. Every
product-facing repository carries `demo.html` in its root: one self-contained
page that a reader can open — from a clone, or from the project's published
site — and come away understanding the product without installing it, standing
up a service, or owning the hardware it normally runs on.

This is a documentation artifact, not marketing. The distance between "I read
the README" and "I understand what this does" is where a project loses the
non-technical stakeholder, the evaluating engineer, and the agent orienting
itself in an unfamiliar repository. A page that demonstrates the product
closes that distance in a way prose cannot, and it does so for the audience
least able to read the code.

- **One file, no build, no backend, no network.** `demo.html` is a single file
  with its styles and scripts inline. It opens correctly from `file://` and
  from a static host. No npm install, no bundler, no CDN fonts or scripts, no
  API the reader must have running. Principle 7 (Dependency Hygiene) applies
  to the demo exactly as it applies to the product.
- **Honest about what is real.** A demo that fabricates output without saying
  so is a lie told in HTML. Simulated transcripts, canned data, and
  pre-recorded results are legitimate — a demo of a service nobody can reach
  is worth more than no demo — but the page must label them plainly, in the
  interface itself and not only in a footnote, and must say what the real
  thing requires.
- **Current with the product.** The demo is covered by the Documentation
  Review Checklist below: a change to user-facing behavior that leaves the
  demo showing the old behavior is an incomplete change. A stale demo is worse
  than none, because it is believed.
- **Published where the audience already is.** When the hosting platform
  offers static publishing, publish it — GitHub Pages from the default branch
  is the usual path — and link it from `README.md` so the page is one click
  from the front door.
- **Public-artifact safety rules apply.** A published demo is world-readable.
  It carries no credentials, tokens, private hostnames, internal IP addresses,
  or customer data, and `SECURITY.md`'s review applies to it like any other
  shipped surface.
- **Short by default, deep on demand.** A demo page is a long document, and
  the same progressive-disclosure rule the README follows applies to it: the
  first screen is what the product is and the smallest interaction that shows
  it working, and the deeper material — "why this matters", architecture
  detail, methodology, the caveats behind a number — sits in collapsible
  `<details>` sections the reader opens only if they want it. See "Progressive
  Disclosure" above for the mechanics, which are identical. When the page has
  a PDF twin (below), those expand sections are what becomes its appendix:
  detail that is one click away on screen and one page-turn away on paper.
- **Code it shows is themed consistently.** A demo that displays source,
  output, or a transcript themes it with the single canonical palette described
  in "Code Snippets in Rendered Documentation" below, so code reads the same on
  the page, in the PDF twin, and across the page's own light and dark themes.

Automated behavior with real data is the ideal, a scripted simulation is the
normal case, and an interactive explanation of the system is the floor.
Repositories that are not product-facing — internal libraries, pure
configuration repositories, research scratch space — are not expected to carry
one, which is why this sits in the product-facing tier rather than the
required one.

### Offline PDF Brief

`demo.html` assumes a browser. A PDF brief is the same demonstration for the
reader who wants to read, print, annotate, or attach it — the stakeholder who
lives in email, the reviewer who prints, the evaluator who files it. A
product-facing repository should offer its demo as a paginated PDF brief
alongside the page, living under `docs/` (for example `docs/<Project>.pdf`) and
linked from `README.md` beside the demo link.

The brief earns its place only if it cannot drift from the product, and the
discipline that makes that true is the point of this standard:

- **Generated from the repository's own sources, not hand-authored.** A build
  step produces the page and the PDF from one source of truth, so they tell the
  same story. Hand-maintaining a second artifact is how the version on the
  cover ends up three releases stale.
- **Code excerpts pulled from the real files at build time.** A code sample a
  human pasted into a brief is wrong the moment the file changes. The build
  reads the excerpt out of the actual source, so a brief that shows code shows
  the code that ships.
- **Guarded against drift mechanically.** The build has a check mode (run in
  CI) that fails when the page's content changed without the PDF being rebuilt
  — a fingerprint of the page's expand sections and excerpts stamped into the
  output, compared on every check. Page and PDF cannot diverge without the
  build noticing, which is the only reason a second artifact is safe to keep.
- **Same currency and safety rules as the page.** The Documentation Review
  Checklist covers it, and it is a published, world-readable artifact: no
  credentials, hostnames, or customer data, exactly as for `demo.html`.

The build step is the repository's own — Principle 7 still rules out dragging a
toolchain into the demo itself, but the brief is a build output, not a runtime
dependency of the page, so a generator script (in whatever language the project
already uses) is the expected mechanism. `ate-harness-demo` is the worked
example: `scripts/build_publish.py` emits `demo.html` and
`docs/ATE-Harness-Demo.pdf` from the same sources, highlights the C# excerpts at
build time, carries the page's "why this matters" sections into the PDF
appendix, and refuses to pass `--check` when the two would disagree.

Enforcement follows the framework's usual shape.
`scripts/check_compliance.sh` treats `demo.html` as a product-facing file
alongside `docs/PRODUCT_REQUIREMENTS.md` and
`docs/REQUIREMENTS_TRACEABILITY.md`: a warning for every repository, a failure
under `--product`. `scripts/bootstrap.sh` installs the `templates/demo.html`
scaffold so a freshly bootstrapped repository starts with a working page
rather than a blank requirement. The scaffold carries a placeholder marker,
so an unedited copy is reported as a placeholder in the same way a
template-shaped Markdown file is — copying the template is the start of the
work, not the end of it. The decision is recorded in
`docs/adr/0002-demo-page-requirement.md`.

`scripts/check_demo_page.sh` checks what the first and fourth bullets make
mechanical: no remote resource loads (scripts, stylesheets, fonts, images,
frames, CSS `url()`/`@import`, JavaScript module imports and `fetch` calls),
scripts and styles inline rather than in separate files, no references into
build output (`dist/`, `node_modules/`, ...), no URLs in markup or scripts
naming `localhost` or a private network address, and a link to the page from
`README.md`. Navigation links, local images, and page text (a labeled
simulated transcript showing `localhost`, say) are allowed.
`constitution-compliance.yml` runs it in warn mode whenever `demo.html`
exists; pass `--strict` to make it blocking. Honest labeling and currency with
the product remain review questions — no checker can tell a simulation that
says so from one that does not.

## Code Snippets in Rendered Documentation

A rendered-HTML documentation artifact that shows source code — the demo page,
a published brief, an HTML report — presents that code in one canonical dark
theme: **Solarized Dark** (Ethan Schoonover's palette). It is applied the same
way regardless of the surrounding page's light or dark theme, and the same way
on screen and in any PDF rendering, so a snippet reads identically everywhere
it appears.

This is Principle 12 applied to code *presentation*. The same reasoning that
makes a project follow the language's canonical style guide rather than a house
style (`CODE_STYLE.md`) makes it theme code with a documented, deliberately
contrast-tuned palette rather than an invented set of colors: Solarized is a
published standard with fixed hex values and a designed relationship between
them, so "the code blocks are Solarized Dark" is a reviewable fact, not one
person's taste. Pinning code to its own dark theme, independent of the page
chrome, is deliberate: code is read as code in every context, and a snippet
that re-themes itself with the page is a snippet a reader has to re-learn on
each visit.

The palette, as CSS custom properties (the exact Schoonover values):

| Role | Variable | Hex | Solarized name |
| --- | --- | --- | --- |
| Background | `--code-bg` | `#002b36` | base03 |
| Line highlight / rule | `--code-line` | `#073642` | base02 |
| Body text | `--code-text` | `#93a1a1` | base1 |
| Comments, prompts | `--code-dim` | `#839496` | base0 |
| Keywords | `--code-kw` | `#859900` | green |
| Types | `--code-type` | `#b58900` | yellow |
| Function / method calls | `--code-fn` | `#268bd2` | blue |
| Strings | `--code-str` | `#2aa198` | cyan |
| Numbers | `--code-num` | `#d33682` | magenta |
| Errors / failures | `--code-err` | `#dc322f` | red |

Mechanics, following the same constraints the demo page lives under:

- **Highlight at build time, not in the browser.** A single-file demo page and
  an offline PDF both forbid a CDN script, so the spans that carry these colors
  are emitted by the build (the same generator that produces the PDF brief),
  not by a highlighter library loaded at view time. Principle 7 (Dependency
  Hygiene) applies to the page exactly as it applies to the product.
- **Define the palette once, as variables.** Declaring the colors as CSS custom
  properties keeps them out of individual spans and makes "is this Solarized?" a
  one-place check rather than a hunt through the markup.
- **The highlighter is code, so it is tested.** A build-time highlighter has
  the usual failure modes — escaping, `//` inside a string literal, an entity
  in an identifier — and a snippet rendered wrong is a documentation defect.
  Cover it like any other code (`TESTING.md`).

## CHANGELOG Expectations

CHANGELOG.md should capture user-facing changes using release categories:

- Added
- Changed
- Fixed
- Removed
- Security

## TODO Expectations

TODO.md is the living roadmap. It should reflect the best current understanding of remaining work.

## Product Requirements Expectations

A repository is **product-facing** when it ships behavior to people other than
its own maintainers — an application, a service, an API, or a library with
consumers outside the team — so that someone outside the team can hold it to
a promise. Internal tooling, personal utilities, and this framework are not.
When unsure, treat the repository as product-facing: the cost is a
requirements document and a traceability matrix, and the alternative is
discovering the promise after it is broken. `scripts/check_compliance.sh
--product` enforces the product-facing tier.

Product-facing repositories should include `docs/PRODUCT_REQUIREMENTS.md` when implementation needs a clear contract between product intent and engineering work.

Product requirements should define:

- Functional requirements.
- Non-functional requirements.
- Requirement priority or level.
- Explicit non-goals.
- Acceptance criteria or validation expectations.

### Requirement Identifiers

Each requirement should carry a stable, unique identifier so it can be referenced from tests, commits, and the traceability matrix.

- Use a short, typed prefix and a zero-padded number, for example `FR-001` for functional requirements and `NFR-001` for non-functional requirements.
- Identifiers are stable: once assigned, an ID is never reused for a different requirement, even after the original is removed or superseded.
- Acceptance criteria for a requirement may carry sub-identifiers, for example `FR-001-AC-1`.

### Acceptance Criteria

Every `MUST` and `SHOULD` requirement should state explicit, verifiable acceptance criteria. Acceptance criteria describe the observable condition that confirms the requirement is met, written so that a test can check them.

## Requirements Traceability

Product-facing repositories should maintain `docs/REQUIREMENTS_TRACEABILITY.md`: a matrix that links each requirement to its evidence of completion.

The traceability matrix should map, for each requirement ID:

- The requirement description and level.
- Its acceptance criteria.
- The tests that verify it.
- Its current verification status (for example, Not Started, In Progress, Verified).

The matrix is a living document: update it in the same change that adds, modifies, or verifies a requirement. A requirement with no verifying test is a coverage gap and should be recorded in the `docs/TEST_PLAN.md` gap log and tracked in `TODO.md` under Testing.

### Requirement ID Grammars Must Not Collide

When a repository layers requirement namespaces — for example a product layer (`BB-FR-001`) on top of a system layer (`FR-001`) — the prefixes must be chosen so that one ID can never appear as a substring of another. Otherwise traceability tooling that matches IDs by pattern can satisfy a check for a missing system requirement with an unrelated product requirement that happens to share a number.

- Prefer fully distinct prefixes that cannot be substrings of each other.
- When tooling matches IDs by regular expression, anchor the matcher on both sides (require a left boundary that is not `-`), so `FR-001` does not match inside `BB-FR-001`.
- Never reuse a number across layers in a way that depends on the surrounding text to disambiguate.

Governance tooling that consumes these IDs must itself be correct and tested; see `TESTING.md`.

## OTS Software Inventory

Repositories with third-party dependencies should maintain `docs/OTS_SOFTWARE.md`: an inventory of every off-the-shelf (OTS) software component the project depends on — libraries, frameworks, runtimes, databases, container base images. The structure follows the intent of the FDA's OTS software guidance and IEC 62304's SOUP requirements, generalized for any repository: for most projects it is simply the auditable answer to "what third-party software are we shipping, and is anyone watching it?"

For each component, the inventory records:

- A stable component ID (`OTS-001`), never reused — removed components are marked `Removed`, not deleted.
- The name **exactly as declared in the dependency manifest**, so tooling can match manifest entries against inventory rows by exact value.
- Version, supplier/maintainer, and its purpose in this system.
- A risk level — at least `Medium` when the component sits in a trust-sensitive position (see `SECURITY.md`'s "Threat Modeling Triggers").
- Verification: how fitness for use was established.
- Anomaly review: where known defects/CVEs are tracked and when they were last reviewed.
- Update policy: how the version moves (pinned, ranged, bot-managed, vendored).

The inventory is a living document: update it in the **same change** that adds, removes, or upgrades a dependency, not in a later documentation pass. The framework ships `scripts/check_ots_inventory.sh` (see `TESTING.md`), which cross-checks the dependencies declared in root-level manifests (`package.json`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`) against the inventory's Name cells, so a dependency added without documentation is flagged automatically. System-level OTS (operating systems, databases, base images) cannot be discovered from manifests and is maintained by hand in the inventory's dedicated section.

## Environment & Configuration Contract

Repositories should maintain `docs/ENV_VARS.md`: an Environment & Configuration Contract that documents every environment variable required or optionally supported by the project. Undocumented configuration is technical debt that frequently breaks deployments.

For each environment variable, the contract records:
- The exact variable name (e.g. `NODE_ENV`).
- A description of what it configures.
- Whether it is required or optional.
- A default or example value.

The contract is a living document: update it in the **same change** that adds, modifies, or removes a configuration requirement from a manifest like `.env.example` or `docker-compose.yml`. The framework ships `scripts/check_env_vars.sh` (see `TESTING.md`), which parses variables from root-level configuration manifests and cross-checks them against `docs/ENV_VARS.md`, so a variable added to a manifest without documentation is flagged automatically.

## Architecture Decision Records

Major decisions are recorded as Architecture Decision Records in `docs/adr/` using the ADR template (`templates/ADR.md`). Beyond context, decision, consequences, and alternatives, each ADR captures:

- **Status lifecycle**: `Proposed → Accepted → Superseded` (or `Deprecated`). A `Proposed` ADR is drafted but not in force; an `Accepted` ADR is binding; a `Superseded` ADR has been replaced by a newer one; a `Deprecated` ADR no longer applies and is not directly replaced.
- **Relationships**: `extends` (builds on another ADR without replacing it), `supersedes` (replaces another ADR — set that ADR's status to `Superseded`), and `related`. This keeps the decision history navigable instead of expressed ad hoc.
- **Promotion criteria**: while an ADR is `Proposed`, it lists the concrete evidence, reviews, or outcomes required to move it to `Accepted`, and who gates the transition. The criteria are removed or marked met once the ADR is `Accepted`.

Maintain an ADR index so decisions and their provenance are discoverable.

### ADR Triggers for the Framework Itself

The framework holds itself to Principle 6. A change to any of the following is
a "major design change" for every adopter at once and gets an ADR in
`docs/adr/` before it ships:

- The **Required Files** list above, or the required tier of
  `scripts/check_compliance.sh`.
- The **Required Workflow** in `AI_WORKFLOW.md` — adding, removing, reordering
  in a way that changes meaning, or making a step conditional.
- The **checker contract** in `TESTING.md`'s "CI Enforcement" — the
  warn-by-default / `--strict` rollout, the exit-code meanings, or an
  exception to them.
- The framework's own **compatibility policy** (`RELEASES.md`, "Versioning
  the Framework Itself").

ADR-0001 (the wiki), ADR-0002 (the demo page), ADR-0003 (compatibility
policy), and ADR-0004 (the proportionate workflow) are the worked examples. Earlier decisions of this
kind — the root relocation in 1.38.0, the required critique pass in 1.45.0,
the reading-order scoping in 1.46.0 — shipped without one, which is the
reason this rule now exists.
