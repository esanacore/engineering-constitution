# Code Style Standards

Code style, comments, docstrings, and technical diagrams should follow the
**official, canonical style guide** published by the language or platform
owner — not a project-invented convention. When there is an authoritative
source (a language maintainer, a platform vendor, a standards body), that
source is the tie-breaker, the same way `ARCHITECTURE.md` treats *Clean
Architecture* and the Gang of Four's *Design Patterns* as authoritative
tie-breakers for structural decisions.

Example: Kotlin/Android code follows
[developer.android.com's Kotlin style guide](https://developer.android.com/kotlin/style-guide),
not an ad hoc house style.

## Why an Official Source, Not a House Style

- **Onboarding cost.** A contributor who already knows Kotlin already knows
  Android's official style guide. A bespoke house style is one more thing to
  learn and one more thing to get wrong.
- **Tooling alignment.** Official style guides are what the language's
  formatters, linters, and IDEs default to (`ktlint`/Android Studio for
  Kotlin, `gofmt` for Go, `black`/`ruff` for Python, etc.). Fighting the
  default tooling is wasted effort.
- **Longevity.** Platform owners maintain their style guides as the language
  evolves. A project-local style doc goes stale; the canonical one doesn't.

This principle governs *which convention to follow*, not *whether to write
code well* — it doesn't relax any other constitution principle.

## Docstrings and Comments

Comment and docstring **format** follows the platform's canonical
convention:

| Language/Platform | Docstring/Comment Convention |
| --- | --- |
| Kotlin/Android | [KDoc](https://kotlinlang.org/docs/kotlin-doc.html) |
| Java | [Javadoc](https://www.oracle.com/technical-resources/articles/java/javadoc-tool.html) |
| Python | [PEP 257](https://peps.python.org/pep-0257/) docstrings (Google or NumPy style body) |
| Swift | [Swift documentation comments](https://www.swift.org/documentation/docc/) (`///`) |
| Go | [Go doc comments](https://go.dev/doc/comment) |

See `sources/STYLE_GUIDES.md` for the full, maintained registry across more
languages and platforms.

This governs **form**, not **when to write a comment**. The constitution's
existing "why, not what" policy still applies: default to no comments, and
only add one when the reasoning behind the code isn't obvious from
well-named identifiers — a hidden constraint, a non-obvious invariant, a
workaround for a specific bug. When a comment or docstring is warranted, it
uses the platform's canonical format.

## Diagrams and Flowcharts

`ARCHITECTURE.md`'s "Visual Architecture" section already establishes
[Mermaid](https://mermaid.js.org/) as the default for component and flow
diagrams in README.md — that default is unchanged.

For diagrams that describe platform-specific concepts (an Android activity
lifecycle, an iOS view controller hierarchy, a sequence of API calls), prefer
the notation that platform's own documentation uses — standard sequence
diagram or UML conventions, for example — over an invented shorthand, so the
diagram reads as immediately familiar to an engineer already fluent in that
ecosystem. Mermaid supports standard sequence, class, and state diagram
syntax and remains the preferred renderer; the guidance here is about
*notation*, not about switching tools away from Mermaid.

## The Style Guide Registry

`sources/STYLE_GUIDES.md` is the living, tracked registry of canonical style
guide URLs and docstring conventions per language/platform, kept in the same
`sources/` directory as the book/paper digestion workflow described in
`KNOWLEDGE_SOURCES.md`. Add a row there when adopting a new language or
platform rather than duplicating the list in this file.

Unlike `sources/raw/` (gitignored downloads of books and papers, distilled
into `sources/summaries/`), official style guides are public, continuously
maintained web pages — they're recorded by reference (a URL), not downloaded
or snapshotted. See `KNOWLEDGE_SOURCES.md` for the full distinction.
