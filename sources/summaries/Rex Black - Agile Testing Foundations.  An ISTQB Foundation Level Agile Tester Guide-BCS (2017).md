# Agile Testing Foundations: An ISTQB Foundation Level Agile Tester Guide

- **Source:** sources/raw/Rex Black - Agile Testing Foundations.  An ISTQB Foundation Level Agile Tester Guide-BCS (2017).pdf
- **Author:** Edited by Rex Black, with Gerry Coleman, Marie Walsh, Bertrand Cornanguer, Istvan Forgács, Kari Kakkonen and Jan Sabak (BCS, 2017)
- **Processed:** 2026-07-08

## Why This Matters

This is the companion study guide to the ISTQB Foundation Level Agile Tester
syllabus — the closest thing the industry has to a consensus baseline for how
testing works on Agile teams. It gives the constitution an authoritative,
citable reference for `TESTING.md`, particularly the testing pyramid it already
endorses, and a vocabulary (testing quadrants, test-first practices, whole-team
quality ownership) for reasoning about *what kinds* of tests a change needs, not
just how much coverage it has.

## Key Takeaways

- **The test pyramid is deliberately a metaphor, not a ratio.** More tests at
  lower levels (unit) than higher (acceptance) gives earlier, cheaper defect
  removal, but the book is explicit that there is "no mathematical proportion" —
  a complex system-of-systems may legitimately have more integration than unit
  tests, and comparing test *counts* across levels is meaningless because the
  tests cover wildly different amounts of the system. Attributed to Mike Cohn
  (2005), popularized by Crispin & Gregory.
- **Automated tests alone are never sufficient.** Gregory & Crispin's "exploratory
  cloud" sits on top of the pyramid: even when every level is automated, manual
  and exploratory testing still finds defects the scripted tests miss, because it
  emphasizes *validation* ("did we build what was needed") over *verification*
  ("did we build what we defined").
- **Testing quadrants** classify tests on two axes — business-facing vs
  technology-facing, and supporting-the-team (guiding development, mostly
  regression/verification) vs critiquing-the-product (finding defects,
  validation). Q1 unit/component/TDD; Q2 story/ATDD/BDD functional; Q3
  exploratory/usability/UAT; Q4 the "-ilities": performance, load, security,
  maintainability, portability. A team doing only Q1 (unit tests) has a blind
  spot on the business and non-functional sides.
- **Test-first is one practice, not a mandate.** TDD (unit-level), ATDD
  (acceptance-level), and BDD (behaviour, Given-When-Then) are all "X-driven"
  test-first techniques. The book is refreshingly candid that TDD is *not* used
  on all projects and is contested — it cites Jim Coplien's "unit testing is
  mostly waste" and warns that if a developer misunderstands the requirement,
  TDD faithfully encodes the misunderstanding into green tests. Its stated
  strength is writing only enough code to pass, keeping code lean and
  refactoring cheap.
- **Quality is a whole-team responsibility.** Agile's cross-functional,
  co-located team dissolves the developer→tester handoff (and the "quality
  police" dynamic it breeds). Concrete practice cited: Crispin & Gregory's
  "Power of Three" — every feature discussion includes a business rep, a
  developer, and a tester.
- **Regression risk is the central testing problem in Agile,** because code
  changes every iteration. The answer is a *maintained, risk-prioritized*
  automated regression suite wired into continuous integration — one that is
  reviewed, updated, and retired, and whose selection starts from risk coverage.
  Unmaintained regression suites accumulate technical debt and higher
  maintenance cost.
- **A common target cited is 100% decision (branch) coverage for unit tests** —
  though the book treats this as a typical aim, not a universal law.
- **Independent testing still has a place.** The syllabus establishes a genuine
  need for testing skill and (some) independence even inside a self-organizing
  team; being "cross-functional" does not mean testing expertise is optional.

## Where It Could Apply

Informational only — a lead for future, separately reviewed changes, not an
edit to any governance document.

- **`TESTING.md` — "Preferred Testing Pyramid."** Strong direct support for the
  existing three-tier pyramid, with a citable source. Worth considering: the
  book's caveat that the pyramid is a metaphor with no fixed ratio, which would
  soften any reading of the constitution's pyramid as a prescribed proportion.
- **`TESTING.md` — test-type taxonomy.** The testing quadrants offer a richer
  lens than a purely vertical pyramid: they add the business-facing vs
  technology-facing and non-functional (Q4) dimensions the current pyramid
  (unit/integration/e2e) doesn't name. Could inform guidance that coverage
  targets alone don't guarantee the *right kinds* of tests exist.
- **`TESTING.md` — exploratory/manual testing.** The constitution's pyramid is
  entirely automated tiers; the book's "exploratory cloud" argues manual
  validation testing remains necessary. A potential gap to acknowledge.
- **`SECURITY.md`.** Q4 explicitly places security testing (including static
  analysis for vulnerability-prone code) inside the standard test taxonomy,
  reinforcing that security testing is testing, not a separate afterthought.
- **`CONSTITUTION.md` / `AI_WORKFLOW.md`.** "Quality is everyone's
  responsibility" and the whole-team approach align with treating tests as part
  of every change rather than a downstream gate.

### Tensions worth flagging

- The book's candor about **TDD being contested and optional** sits alongside
  the constitution's firm "all new functionality should include automated
  tests." These are compatible — the constitution mandates *tests*, not
  *test-first* — but the source is a useful reminder not to escalate the pyramid
  or TDD into dogma.
- The book warns that **test counts and coverage percentages are weak proxies**
  (tests at different levels aren't comparable; a passing test can encode a
  misunderstood requirement). This is a healthy counterweight to `TESTING.md`'s
  coverage-floor machinery, and aligns with its own "Coverage Gap Analysis"
  point that an aggregate percentage hides which behavior is untested.
