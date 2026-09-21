# ADR-0002: A Demo Page for Product-Facing Repositories

Status: Accepted

Date: 2026-09-21

## Relationships

- Extends: none
- Supersedes: none
- Related: `DOCUMENTATION.md` ("Demo Page", "Current Capabilities"),
  `CONSTITUTION.md` Principle 1 and Principle 7

## Context

The framework's documentation standards are entirely textual. A compliant
repository explains what it does in `README.md`, enumerates its capabilities,
records requirements and traceability, and catalogues itself in a wiki — and a
reader can still finish all of it without ever seeing the product work.

That gap is expensive in exactly the cases the framework cares most about:

- **Non-technical stakeholders** decide whether a project is worth their
  attention from the surface it presents. Prose about an inference host is not
  the same as a page they can click.
- **Evaluating engineers** measure a project by time-to-understanding. A demo
  collapses a setup guide they were never going to follow into thirty seconds.
- **Agents** orienting in an unfamiliar repository benefit from one artifact
  that states, concretely and in the product's own vocabulary, what the thing
  does.

The framework already dogfoods the answer without having written it down: this
repository ships `demo.html`, an interactive dashboard published through GitHub
Pages and linked from `README.md`, and `RELEASES.md` step 2 even instructs a
release to update the demo's version badge. So the artifact is real, it is
maintained, and it is load-bearing in the release process — but no standard
asks adopters for one, no template exists, and no checker notices its absence.
A practice that lives only in one repository's habits is not a framework
practice.

Two constraints bound the design. Principle 7 (Dependency Hygiene) rules out a
demo that needs a build toolchain or a site generator, and the framework is
language-agnostic, so it cannot assume Node or Python is present. And most
demos cannot reach the real system — a product that only runs on hardware the
reader does not have, or behind a network they cannot join — so the standard
has to make room for simulated content without licensing dishonesty.

## Decision

Make a self-contained `demo.html` in the repository root a **product-facing**
expectation, enforced in the same tier as `docs/PRODUCT_REQUIREMENTS.md` and
`docs/REQUIREMENTS_TRACEABILITY.md`.

**Standard.** `DOCUMENTATION.md` gains a "Demo Page" section requiring one
file with inline styles and scripts, working from `file://` with no build, no
backend, and no network; plain in-interface labelling of anything simulated;
currency with the product through the Documentation Review Checklist;
publication through the platform's static hosting when available; and the same
no-secrets rule as any other published artifact.

**Tier.** Product-facing, not required. An internal library or a pure
configuration repository has no product to demonstrate, and a required tier
would either produce empty ceremonial pages or fail honest repositories.
`check_compliance.sh` therefore warns for every repository and fails under
`--product`, which is the flag a product-facing repository's CI already passes.

**Placeholder detection.** The existing placeholder grep is Markdown-shaped and
treats `<!--` as evidence of an unfinished template. In HTML a comment is
ordinary markup, so applying that rule to `demo.html` would flag finished
pages. `demo.html` instead gets a single explicit marker,
`constitution-demo-template-placeholder`, written into `templates/demo.html`
and removed by the adopter. Copying the scaffold is the start of the work, and
the checker says so until the marker is gone.

**Scaffold.** `bootstrap.sh` installs `templates/demo.html`: a working,
dependency-free page with a scripted example, so a freshly bootstrapped
repository starts from something that runs rather than from a blank
requirement.

## Consequences

Positive:

- The framework asks adopters for what it already does itself, and the
  practice becomes reviewable and mechanically noticed rather than cultural.
- Every product-facing adopter gains an artifact aimed at the audience least
  served by the rest of the documentation set.
- The rollout is non-breaking: existing adopters see a warning, and only a
  repository that opted into `--product` sees a failure.

Negative / costs:

- One more artifact to keep current, and a stale demo misleads more than stale
  prose does. Mitigated by the Documentation Review Checklist entry and by the
  standard's explicit "current with the product" rule.
- "Product-facing" remains a judgment call the checker cannot make; the
  `--product` flag keeps that judgment with the adopter.
- The single-file, no-dependency constraint limits how elaborate a demo can
  be. This is deliberate: the constraint is what keeps the page from acquiring
  a build system of its own.

## Alternatives Considered

- **Required tier for every repository.** Rejected: it would immediately fail
  honest non-product repositories and produce ceremonial pages that nobody
  maintains, which is worse than no demo.
- **Strongly Encouraged only, with no checker entry.** Rejected as too weak to
  change behavior; the framework's pattern is that a standard worth writing is
  a standard worth noticing mechanically.
- **A live hosted demo rather than a file.** Rejected as the default: it
  assumes a deployment the project may not have, and it cannot be reviewed in
  a pull request. Publishing the file through GitHub Pages gets most of the
  benefit with none of the infrastructure.
- **A demo directory (`demo/`) with separate assets.** Rejected: multiple
  files invite a build step and break the "open it from a clone" promise. One
  file is the constraint that keeps the artifact cheap.
- **Reusing the generic placeholder grep for `demo.html`.** Rejected: it would
  report finished pages as templates because HTML comments are normal markup.
