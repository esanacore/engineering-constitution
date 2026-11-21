# ADR-0008: A Plate for Every Repository, a Drawing Set for Every Physical One

Status: Accepted

Date: 2026-11-20 (requested and accepted)

## Relationships

- Extends: ADR-0002 (the demo page shows the product working; the plate
  shows what it is made of)
- Supersedes: none
- Related: ADR-0003 (the rollout follows its warn-first rule), `DOCUMENTATION.md` ("Drawings"), `ARCHITECTURE.md`
  ("Visual Architecture")

## Promotion Criteria (met at acceptance)

Requested by the framework maintainer (Eric) on 2026-11-20: "let's actually go ahead
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
review: no dimensions on paper, no sections, no parts list.

The patent-drawing form suits the one-look picture because it constrains:
every part must be drawn as an object and given a number, with no prose to
hide behind.

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
3a. **The drawing set has a floor.** `DOCUMENTATION.md` lists the least a set
   carries; the maintainer's direction is that drawings are "always at least
   this detailed and ideally legally strong." The checker looks for a title
   block on every sheet and for a section, a parts list, and material,
   tolerance, and projection notes across the set; each repository holds the
   finer floor (named views, minimum dimension counts) in its own tests.
3b. **Drawings are kept as a record**: attributed, dated, tied to the model
   by a hash, and listed in a committed manifest. A repository may add
   formal figures laid out to patent-office form. The standard says plainly
   what such a record is and is not worth, and that a public drawing is a
   public disclosure.
4. **`scripts/check_drawings.sh` checks the mechanical half**, warn by
   default with `--strict`, and the adopter compliance workflow runs it in
   warn mode wherever `docs/drawings/` exists.
5. **It is part of the documentation workflow, not a gate.** The maintainer's
   direction: "it needs to be something that is part of documentation
   workflows, not necessarily CI." `docs/drawings` enters the recommended
   tier of `check_compliance.sh`, where its absence is a warning, and there
   is no plan to move it to the required tier.
6. **Every agent instruction file, the Solon reviewer, and both pull
   request templates carry the rule** to keep the drawings current.

## Consequences

- Every adopter owes a plate. Drawing one is an hour of work for a small
  system, and the template ships the paper, the hand-drawn filter, and a
  starting figure. Adopters that run `check_compliance.sh --strict` need it
  in the same fleet-bump pull request (`RELEASES.md`, "Cutting a Release").
- Hardware adopters owe a generator, which is real work. The framework does
  not ship one, because it depends on the CAD tool; each hardware adopter
  writes its own.
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
- The standard now touches patent law. It states general facts, cites the
  regulation, says it is not legal advice, and sends the reader to a patent
  practitioner. It does not tell anyone what to file.

## Alternatives Considered

- **Require drawings only where there is hardware.** Rejected by the
  maintainer: the plate is wanted everywhere, in simplified form.
- **Let the architecture diagram stand in for the plate.** Rejected: a
  Mermaid flowchart is exact and unread. The two do different jobs.
- **Make `docs/drawings` a required entry.** Rejected by the maintainer:
  this is a documentation habit, and a red compliance gate is the wrong tool
  for it.
- **Ship a drawing-set generator in the framework.** Not done: a generator is
  tied to one CAD tool, and adopters do not contribute their own work back
  to the framework.
