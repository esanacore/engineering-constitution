# ADR-0008: A Plate for Every Repository, a Drawing Set for Every Physical One

Status: Accepted

Date: 2026-11-20 (requested and accepted)

## Relationships

- Extends: ADR-0002 (the demo page shows the product working; the plate
  shows what it is made of)
- Supersedes: none
- Related: ADR-0003 (the rollout follows its warn-first rule and its
  deprecation window), `DOCUMENTATION.md` ("Drawings"), `ARCHITECTURE.md`
  ("Visual Architecture")

## Promotion Criteria (met at acceptance)

Requested by the framework maintainer (Eric) on 2026-11-20, after a private
hardware adopter gained a mechanical drawing set generated from its CAD and
an exploded view drawn like an antique patent plate: "let's actually go ahead
and make this a requirement of all adopters of the engineering-constitution
(where it applies) even if it is only another simplified patent-application
style visual for software/ideas when there is no physical component." A
change to what `check_compliance.sh` expects is an ADR trigger under
`DOCUMENTATION.md`; this ADR records the reasoning.

## Context

The framework asks a repository to describe itself in three ways already: a
README in prose, an architecture diagram that is precise and complete, and,
for product-facing repositories, a demo page that shows the product working.
None of them answers "what is this thing made of?" in one look.

For a physical product the gap is larger. A repository can hold CAD and
ready-to-print files and still have no drawing a mechanical engineer could
review: no dimensions on paper, no sections, no parts list. The hardware
adopter that prompted this had exactly that gap until its drawings were
generated from the model.

That adopter's exploded plate also turned out to be the most readable
picture in the repository. The patent-drawing form forces every part to be
drawn as an object and given a number, with no prose to hide behind.

## Decision

1. **Every adopting repository carries a plate** at
   `docs/drawings/plate.svg`: one self-contained SVG in the manner of an
   antique patent drawing, with numbered parts and a key in
   `docs/drawings/README.md`. Physical projects draw an exploded view.
   Software and ideas draw a simplified apparatus of their main parts.
2. **Every repository with a physical component also carries a drawing
   set** generated from its CAD: a dimensioned sheet per made part with
   sections, an assembly sheet with an exploded view and parts list, a
   dimension table where there are variants, and a title block whose
   revision tracks the model.
3. **The plate says it is not a patent.**
4. **`scripts/check_drawings.sh` checks the mechanical half**, warn by
   default with `--strict`, and the adopter compliance workflow runs it in
   warn mode wherever `docs/drawings/` exists.
5. **Rollout is warn-first.** `docs/drawings` enters the recommended tier of
   `check_compliance.sh` in 1.57.0. The maintainer's intent is a
   requirement, so 1.57.0 announces that it will move to the required tier,
   and that move lands no sooner than the next MINOR release (ADR-0003).
6. **Every agent instruction file, the Solon reviewer, and both pull
   request templates carry the rule** to keep the drawings current.

## Consequences

- Every adopter owes a plate. Drawing one is an hour of work for a small
  system, and the template ships the paper, the hand-drawn filter, and a
  starting figure. Strict-mode adopters need it in the same fleet-bump pull
  request that moves them to 1.57.0 (`RELEASES.md`, "Cutting a Release").
- Hardware adopters owe a generator, which is real work: the reference
  implementation is a hidden-line renderer plus a sheet layout script of a
  few hundred lines. The framework does not ship one yet, because it depends
  on the CAD tool. Until it does, a hardware adopter writes its own.
- The plate overlaps the architecture diagram. They are kept apart by
  purpose: the diagram is precise and complete, the plate is a one-look
  summary that may leave things out.
- The checker cannot tell a true figure from a pretty one. A plate that
  draws a system the code does not implement passes. Review owns that.
- A plate is partly an aesthetic choice, and this ADR does not pretend
  otherwise. The cost is accepted because a picture that people stop to read
  earns its place, and because drawing the parts as objects exposes a design
  nobody can name the parts of.
- Instruction files grow by one rule each.

## Alternatives Considered

- **Require drawings only where there is hardware.** Rejected by the
  maintainer: the plate is wanted everywhere, in simplified form.
- **Let the architecture diagram stand in for the plate.** Rejected: a
  Mermaid flowchart is exact and unread. The two do different jobs.
- **Make `docs/drawings` required in 1.57.0.** Rejected: it would turn every
  adopter's compliance gate red on the fleet bump, which is the MAJOR-shaped
  change ADR-0003 exists to prevent.
- **Ship the hardware drawing generator in the framework now.** Deferred:
  the only implementation reads OpenSCAD and belongs to a private adopter.
  Tracked in `TODO.md`.
