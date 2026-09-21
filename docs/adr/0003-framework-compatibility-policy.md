# ADR-0003: A Compatibility Policy for the Framework's Own Releases

Status: Accepted

Date: 2026-09-16 (proposed and accepted)

## Relationships

- Extends: none
- Supersedes: none
- Related: ADR-0001 (the release whose rollout motivated this), `RELEASES.md`
  ("Versioning the Framework Itself"), `TESTING.md` ("CI Enforcement"),
  `DOCUMENTATION.md` ("ADR Triggers for the Framework Itself")

## Promotion Criteria (met at acceptance)

Accepted by the framework maintainer (Eric) on 2026-09-16 in the session that
proposed it, as part of a batch of improvements he approved in full. The
policy text lives in `RELEASES.md`; this ADR records why it exists and what
was considered.

## Context

`RELEASES.md` has always said "follow semantic versioning", and every release
of this framework has been MINOR or PATCH. But SemVer is defined in terms of a
public API, and the framework never said what its API is. In practice it is
the contract an adopter's CI depends on: which files `check_compliance.sh`
requires, whether a checker warns or fails by default, which scripts and
workflow templates exist and what options they take.

Release 1.44.0 made `wiki/Home.md` a required file. ADR-0001 called out that
this "departs from the usual warn-first rollout", and the changelog carried a
migration note, but the version number said MINOR. Every adopter that bumped
its submodule saw its compliance gate go red with no change on its side —
exactly what a MAJOR bump is supposed to signal. The framework has also
learned (recorded in `docs/MEMORY.md`) that *any* release strands the whole
fleet one tag behind, blocking pull requests wherever the version gate is a
required check, so the cost of a release is never zero and the fleet bump is
part of the release, not a follow-up.

The framework needed to answer: what counts as breaking here, how can a
breaking-shaped change still ship without a MAJOR bump, and who bumps the
fleet.

## Decision

Define the framework's versioning semantics in `RELEASES.md`, "Versioning the
Framework Itself":

1. **MAJOR** is any change that can turn an adopter's CI red or break a
   documented invocation without any change on the adopter's side — a new
   required file, a warn-to-fail default flip, a removed or renamed script,
   template, or workflow, a changed exit code or option in a script that a
   shipped workflow template or documented CI invocation depends on
   (on-demand tools such as `version_analyzer.sh` are not on that path).
2. **MINOR** is anything additive that warns by default; **PATCH** changes no
   contract.
3. **A deprecation window converts MAJOR-shaped into MINOR**: the requirement
   ships warn-by-default with a `Deprecation` notice in `CHANGELOG.md` naming
   the enforcing release, and enforcement lands no sooner than the next MINOR.
   Skipping the window makes the change MAJOR regardless of size.
4. **The fleet bump is step 9 of "Cutting a Release"**, executed with
   `scripts/bump_adopters.sh`, so the strand-the-fleet effect is handled by
   the release rather than discovered by the adopters.

Changing this policy is itself an ADR trigger (`DOCUMENTATION.md`).

## Consequences

Positive:

- Adopters can read a version number and know whether bumping is safe.
- The warn-first rollout contract in `TESTING.md` becomes the *default path*
  for new requirements rather than a convention that can be skipped.
- The fleet bump stops depending on memory.

Negative / costs:

- Some changes that feel small will carry a MAJOR bump or wait a release for
  their window; that friction is the point.
- The policy adds a pre-release review item and a release step.

## Alternatives Considered

- **Keep informal SemVer.** Rejected: it produced 1.44.0.
- **Always MAJOR for any required-file change, no deprecation window.**
  Rejected: MAJOR bumps every few months would numb adopters to them; the
  window keeps MAJOR meaningful while still letting requirements tighten.
- **Version the checkers separately from the standards.** Rejected: adopters
  pin one submodule, so one version is what they can act on.
