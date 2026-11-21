# Session: Drawings standard: a plate for every repository, a drawing set for hardware

- **Date:** 2026-11-20
- **Agent:** Claude (Fable 5.2), remote session
- **Branch / PR:** feat/drawings-and-plate
- **Topics:** drawings, plate, patent-style drawing, exploded view, docs/drawings, check_drawings.sh, mechanical drawings, CAD, drawing set, ADR-0008, recommended tier, deprecation window
- **Related:** ADR-0008, ADR-0002, ADR-0003; `DOCUMENTATION.md` "Drawings"

## Request

The maintainer asked that drawings become an expectation of every adopter:
"let's actually go ahead and make this a requirement of all adopters of the
engineering-constitution (where it applies) even if it is only another
simplified patent-application style visual for software/ideas when there is
no physical component." He later clarified the weight: "Warn first, I mean it
needs to be something that is part of documentation workflows not
necessarily CI or something."

## Context

"Where it applies" was read as: the plate applies to every adopter; the
dimensioned drawing set applies only where there is a physical component.

The maintainer also restated a standing rule while reviewing this work:
adopters never provide information back to the framework or publicly. Nothing
in this change comes from an adopter.

## Decisions

- **A plate for every adopter, a drawing set for physical ones** (the
  maintainer's decision; ADR-0008).
- **A documentation-workflow expectation, not a gate** (the maintainer's
  decision): `docs/drawings` sits in the recommended compliance tier, where
  its absence is a warning, with no plan to make it required. The first
  draft announced a later move to the required tier; the maintainer removed
  that.
- **The framework ships no drawing-set generator** (the maintainer's
  decision): a generator is tied to one CAD tool, and adopters do not
  contribute their work back. Each hardware adopter writes its own.
- **The plate must say it is not a patent** (the agent's call): a page styled
  as a patent plate with a person's name across the top can be mistaken for
  a filing. The checker enforces the line.
- **The plate is a hand-maintained SVG, with no generator shipped** (the
  agent's call): the framework's scripts are Bash, and a plate for a software
  project is drawn, not derived.
- **Key numerals are read only from the table under a `Key` heading**, so a
  numbered sheet list in the same file is not mistaken for reference
  numerals.

## Discoveries

- The hand-drawn look needs no drawing tool: an SVG `feTurbulence` plus
  `feDisplacementMap` filter over ordinary line work gives the unsteady ink
  line, and a second turbulence filter gives paper grain. Both render in
  browsers, on GitHub, and in `rsvg-convert`.
- Bash `${var/## Key/}` did not remove the heading in a test, for the reason
  already in `docs/MEMORY.md` (`#` after the first `/` anchors the match).
  The test uses `grep -v` instead.
- A level-3 "Drawing set" heading under a level-2 "Key" heading is inside the
  Key section. The checker's section scan ends only at a heading of the same
  or a higher level, which is the right behaviour, and the test was wrong.

## Outcome

On `feat/drawings-and-plate`: the "Drawings" section of `DOCUMENTATION.md`,
ADR-0008, `scripts/check_drawings.sh` with 14 test cases, the plate scaffold
in `templates/docs/drawings/` installed by `bootstrap.sh`, `docs/drawings` in
the recommended compliance tier, the rule in every agent instruction file,
the Solon reviewer and both pull request templates, the framework's own plate
(shown in `README.md` and `demo.html`), a plate for the sample project, and
CI wiring. `bash scripts/run_all_tests.sh` passes (37 suites) and the
self-governance checks pass locally. Not done: the release, the fleet bump,
and the adopters' plates.

## Open Questions

- Is the plate's inventor line ("E. SANACORE.") right for the framework's own
  plate, and what should adopters owned by other people put there?
