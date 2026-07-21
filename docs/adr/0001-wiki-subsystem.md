# ADR-0001: A Wiki Subsystem That Stays Current

Status: Proposed

Date: 2026-07-21

## Relationships

- Extends: none
- Supersedes: none
- Related: `DOCUMENTATION.md` ("Wiki"), `CONSTITUTION.md` Principle 1

## Promotion Criteria

This ADR moves to **Accepted** when, gated by the framework maintainer (Eric):

- The first slice (checker + tests + workflow template + the constitution's own
  finished wiki) has shipped and the checker's tests pass in the declared suite.
- The publish-on-merge sync has run successfully at least once against the
  constitution's own `.wiki.git`, confirming the mechanism end to end.
- A decision is taken on whether a wiki is **Recommended** or **Required** for
  adopters, which gates wiring `check_wiki_freshness.sh` into
  `check_compliance.sh` and installing `constitution-wiki.yml` from
  `bootstrap.sh`.

Until then, the tooling ships and the constitution dogfoods it, but a wiki is
not yet a binding obligation on adopting repositories.

## Context

"Wiki content" is already named as part of the deliverable in `CONSTITUTION.md`
Principle 1, in `DOCUMENTATION.md`'s Documentation Review Checklist and
Strongly Encouraged list, and in Solon's law (`.github/agents/solon.agent.md`).
But the framework ships no wiki template, no automation, and no publishing path,
and the constitution's own `wiki/Home.md` ends with six dangling `[[links]]` to
pages that were never written. The principle exists; the mechanism does not.

The framework needs to answer two questions to close that gap:

1. **Where does a wiki live** so it is reviewed and versioned like the rest of
   the deliverable rather than drifting on a separate, unreviewed surface?
2. **What keeps it current**, in the same spirit as the existing CI tripwires
   (`check_doc_freshness.sh`, `check_ots_inventory.sh`, `check_env_vars.sh`)
   that catch documentation drift mechanically instead of relying on an agent
   remembering?

Two constraints bound the design. Principle 7 (Dependency Hygiene) discourages
adding a build toolchain or new runtime dependency. And any new governance
feature is expected to fit the established mold: a zero-dependency bash
`check_*.sh`, a matching `test_check_*.sh`, a `constitution-*.yml` workflow
template, and standards text — installed by `bootstrap.sh`, surfaced by
`check_compliance.sh`.

## Decision

Adopt an **author-in-repo, publish-to-the-native-wiki** model, and make "stays
current" a layered guarantee rather than a single mechanism.

**Hosting.** Wiki pages are authored under `wiki/` in the main repository, in
GitHub-Wiki-native Markdown (`Home.md`, `_Sidebar.md`, `[[WikiLinks]]`). They
are reviewed through normal pull requests and versioned with the code. A
workflow publishes `wiki/` to the repository's `<repo>.wiki.git` on merge to the
default branch, so the rendered wiki is never stale relative to its source. This
keeps the single source of truth inside the reviewed, CI-guarded repository
while still giving readers the native GitHub wiki UI. It is the model the
existing `wiki/Home.md` already implies. A static-site generator (MkDocs,
Docusaurus, Docsify) was rejected as the default — see Alternatives.

**Staying current, in layers:**

1. *Workflow discipline* — the agent updates wiki content in the same change as
   the code, exactly as it already does for README/CHANGELOG.
2. *Structural freshness tripwire* — `check_wiki_freshness.sh` flags a pull
   request that **adds or removes** source files (a change to what the
   repository contains) without touching the wiki that catalogues them. It is a
   deliberately *higher* bar than `check_doc_freshness.sh`: modifying existing
   files never trips it, only additions and deletions do, because a wiki is a
   high-altitude catalogue of capabilities, not a per-line mirror of the code.
   Warn by default, `--strict` to fail — the standard rollout contract.
3. *Publish-on-merge sync* — `constitution-wiki.yml` pushes `wiki/` to
   `<repo>.wiki.git` on merge, so the reader-facing surface is continuously
   current by construction.

Two further layers are recorded as follow-up slices, not built now: *generated
pages* for the mechanical sections (a Governance Checkers page derived from the
`scripts/check_*.sh` headers), and *scheduled agent regeneration* using the
existing `.github/agents/` mechanism (Solon) to open a reconciliation PR on a
cadence — the genuinely "self-updating" layer, kept out of slice 1 because it is
higher-risk and depends on this foundation.

**Staging.** Because this ADR is Proposed, slice 1 ships the tooling and
dogfoods it on the constitution's own wiki, but does not make a wiki binding for
adopters. Compliance/bootstrap wiring waits for Acceptance (see Promotion
Criteria).

## Consequences

Positive:

- Wiki content becomes reviewable, versioned, and CI-guarded like every other
  deliverable, instead of a separate surface that escapes review.
- The reader-facing wiki cannot silently lag its source once sync is enabled.
- The feature fits the existing governance mold exactly (checker + test +
  workflow + docs), so it is maintained the same way as its siblings and adds
  no new runtime dependency.
- The constitution stops shipping a wiki stub with broken links — it dogfoods
  the standard it asks adopters to follow.

Negative / costs:

- One more workflow template and checker to maintain.
- The publish job requires the wiki repo to be initialized once in the GitHub
  UI before `<repo>.wiki.git` exists; this is a documented prerequisite, not an
  automated step.
- The structural tripwire is blunt: adding a non-capability file will sometimes
  trip it. Mitigated by warn-by-default and by narrowing the trigger to
  additions/removals rather than every change.

## Alternatives Considered

- **Native GitHub Wiki as the source of truth (edit in the wiki UI).** Rejected:
  the wiki is a separate `.wiki.git` repo that escapes the main repo's pull
  request review and CI entirely — precisely the drift this framework exists to
  prevent.
- **In-repo `docs/` published to a static site (MkDocs/Docusaurus/Docsify).**
  Rejected as the default: it adds a build step and a runtime/tooling dependency,
  in tension with Principle 7, and the framework is language-agnostic so it
  cannot assume a Node or Python site toolchain. Left open as an adopter's own
  choice; not the framework default.
- **A single freshness rule identical to `check_doc_freshness.sh` but targeting
  the wiki.** Rejected: firing on every source change would be pure noise and
  redundant with doc-freshness. The structural (add/remove) heuristic gives the
  wiki checker a distinct, defensible identity.
- **Building scheduled agent regeneration now.** Deferred: it is the most
  valuable "self-updating" layer but the highest-risk, and it depends on the
  `wiki/` foundation and sync existing first.
