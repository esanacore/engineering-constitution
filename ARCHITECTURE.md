# Architecture Standards

Architecture should be intentional, documented, and revisited as systems evolve.

## Design Principles

Code-level structure should follow the SOLID principles and the Dependency Rule.
Treat them as guardrails for reducing real coupling, not as ceremony — apply a
principle where it prevents a concrete future pain, and skip it where it would
only add indirection. These draw on Robert C. Martin's *Clean Architecture*
(2017); when a rule becomes contentious in review, the book is the tie-breaker.

### SOLID

**Single Responsibility (SRP)** — A module should have one reason to change: one
actor or stakeholder it answers to.

- Smell: one class is edited by two unrelated teams; its description needs an "and."
- Guardrail: split when two stakeholders pull a module in different directions.
  Do not split merely because a file is long.

**Open/Closed (OCP)** — Modules should be open for extension but closed for
modification: add behavior by adding code, not by editing tested code.

- Smell: a growing `switch`/`if-else` on a type tag that you touch every time a
  new case appears.
- Guardrail: introduce an abstraction (interface, strategy, polymorphism) only
  when a real second case arrives. Do not pre-build extension points for cases
  that may never exist.

**Liskov Substitution (LSP)** — A subtype must be usable anywhere its base type
is expected, without surprising the caller.

- Smell: an override that throws "not supported," weakens a guarantee, or makes
  callers check the concrete type before using it.
- Guardrail: if a subtype cannot honor the base contract, it is not a subtype —
  prefer composition over inheritance.

**Interface Segregation (ISP)** — Clients should not depend on methods they do
not use.

- Smell: implementers forced to stub methods they have no use for; a "fat"
  interface that pulls in unrelated dependencies.
- Guardrail: prefer several small, role-specific interfaces over one broad one.

**Dependency Inversion (DIP)** — High-level policy should not depend on
low-level detail; both should depend on abstractions. Program to an interface,
not an implementation.

- Smell: a business rule that imports a concrete database, HTTP client, or
  third-party SDK directly.
- Guardrail: have the high-level module own the interface and inject the
  concrete implementation at the edge.

### The Dependency Rule

Source-code dependencies must point inward, toward higher-level policy.

- Inner layers (entities, business rules, use cases) know nothing about outer
  layers (UI, database, frameworks, the web). Outer layers depend on inner ones,
  never the reverse.
- Cross a boundary with an interface owned by the inner layer — this is DIP
  applied at architectural scale.
- Frameworks, databases, and delivery mechanisms are details. Keep them at the
  edges so they can be replaced without touching business rules.
- Smell: a core domain type that imports an ORM model, an HTTP request object,
  or a framework annotation.
- Guardrail: if you cannot test a business rule without standing up a database
  or web server, a dependency is pointing the wrong way.

#### Enforcing the Dependency Rule

The rule above is checkable, not just advisory. Declare the project's layers in
`docs/ARCHITECTURE.md` under a `Layer Boundaries` heading and
`scripts/check_architecture.sh` will verify that every import points inward:

```markdown
## Layer Boundaries

| Layer          | Path               | May Depend On       |
| -------------- | ------------------ | ------------------- |
| domain         | src/domain         | --                  |
| application    | src/application    | domain              |
| infrastructure | src/infrastructure | domain, application |
```

List layers inner-first. `May Depend On` names the layers each one may import;
an em dash means none. A layer may always import itself, and imports that do not
resolve to a declared layer — third-party and standard-library packages — are
ignored.

The declared graph must be **acyclic**. If two layers may each depend on the
other, dependencies cannot point inward — and no per-import check can catch it,
because every edge of the cycle is individually legal under its own allow-list.
The checker runs a graph pass over the table for this reason.

Checking the declared graph rather than the observed imports is sufficient
rather than a shortcut: every real import is either permitted, and therefore an
edge already present in the declared graph, or it is a violation the checker
already reports. An acyclic declaration admits no cycle among the imports that
pass. It also catches an unsound architecture before any code exercises it.

A `May Depend On` entry naming no declared layer is reported as well. A typo
there is silent by construction — the intended dependency is never permitted, so
the layer quietly enforces more than its author wrote.

Enforcement is opt-in per project: only the project knows its own layering, so a
repository without this table is never failed for lacking one. Once the table is
accurate, switch `.github/workflows/constitution-architecture.yml` to `--strict`
so an outward-pointing dependency or a cyclic declaration fails the build.

The checker also reports **structural signals** — oversized files, crowded
directories. These are review prompts and never fail a build, even under
`--strict`. That is deliberate: the SRP guardrail above says not to split a
module merely because it is long, so a checker that failed on line count would
contradict the principle it exists to serve. A long file is a reason to look,
not a verdict.

### Design Patterns

The patterns from *Design Patterns* (Gamma, Helm, Johnson, Vlissides, 1994) are a
shared vocabulary for recurring designs — not a checklist to satisfy. Reach for
one when you recognize the problem it solves; never restructure working code just
to name a pattern. Two maxims from the book govern the rest:

- **Program to an interface, not an implementation.** Depend on what a
  collaborator does, not how it does it — this is DIP at the object level.
- **Favor object composition over class inheritance.** Use inheritance only for
  genuine is-a substitutability (see LSP); reach for composition and delegation
  for everything else.

Patterns worth knowing by name, and when to reach for each:

- **Factory Method / Abstract Factory** (creational) — when construction logic
  would otherwise leak into callers, or you need to swap whole families of
  implementations. Constructs details at the edge, keeping the Dependency Rule intact.
- **Adapter** (structural) — wrap a third-party or legacy interface to match the
  one your code owns. The primary tool for keeping frameworks at the boundary.
- **Decorator** (structural) — add behavior (caching, logging, retries) without
  subclassing or editing the wrapped type. Composition over inheritance in action; supports OCP.
- **Facade** (structural) — present one simple interface over a complex
  subsystem; useful at module boundaries.
- **Strategy** (behavioral) — encapsulate interchangeable algorithms or policies
  behind an interface. The standard answer to a growing type `switch` (see OCP).
- **Observer** (behavioral) — decouple producers from consumers of events;
  underpins most event and pub/sub systems.
- **Command** (behavioral) — turn a request into an object so it can be queued,
  logged, undone, or retried.
- **Template Method** (behavioral) — fix the skeleton of an operation and let
  subclasses fill steps. Use sparingly; Strategy (composition) is often the better default.

- Smell: a codebase where nearly every class is a `…Factory`, `…Strategy`,
  `…Manager`, or `…Visitor`; indirection with no second implementation behind it.
  Singleton in particular often just hides global state and breaks testability —
  prefer dependency injection.
- Guardrail: introduce a pattern when a second case or a real testability or
  coupling problem arrives, not in anticipation. A pattern with exactly one
  implementation and one caller is usually premature.

Record significant applications of these principles — chosen layer boundaries,
key abstractions, patterns adopted at a boundary — as ADRs (below) so the
structure stays intentional.

## Architecture Decision Records

Use Architecture Decision Records (ADRs) for major architectural decisions.

Create ADRs for:

- New frameworks
- Database changes
- Infrastructure changes
- Major design changes
- Security decisions
- Significant dependency choices
- Cross-service contracts

## ADR Location

Project ADRs should live in:

```text
docs/adr/
```

## ADR Template

Each ADR should include:

- Title
- Status
- Date
- Context
- Decision
- Consequences
- Alternatives considered

Use `templates/ADR.md` as the baseline.

## Architecture Documentation

Architecture documentation should describe:

- System boundaries
- Major components
- Data flow
- External dependencies
- Deployment model
- Operational concerns
- Security-sensitive areas

## Visual Architecture

Prose descriptions of structure are easy to skim past and quick to go stale.
Every repository's README.md should also carry a visual answer to "how is this
put together," not only a written one. **Include at least one infographic —
a diagram, not just prose or a bullet list — in the README whenever possible.**
This is the default expectation, not a special case reserved for large or
multi-service systems. The only repositories that can skip the diagram are
genuinely single-file or trivial-structure ones where a diagram would add
nothing a directory tree doesn't already say; when in doubt, include one.

- **A project structure section**: a fenced `text` code block containing a
  directory tree of the repository's top-level layout, annotated with a short
  comment per entry explaining what lives there. This is the fastest
  orientation tool for a new contributor or an AI agent — faster than reading
  `ls` output or a wall of bullets.
- **A component or flow diagram**: a visual infographic — boxes, arrows,
  swimlanes — of how the pieces fit together: components and their
  connections, a data or request flow, a deployment topology, or (for a
  framework/tooling repository with no runtime components) an adoption or
  integration flow. Almost every repository has at least one of these worth
  drawing; a single box-and-line diagram usually replaces a paragraph of prose
  and is read where the prose gets skipped.

Use [Mermaid](https://mermaid.js.org/) for these diagrams by default. It is
plain text (diffable in pull requests, no binary asset to keep in sync), needs
no external tool or build step, and renders natively in GitHub's and GitLab's
web Markdown preview (desktop or mobile browser).

**GitHub's native mobile apps (iOS/Android) do not render `mermaid` fenced
code blocks** — they show the raw source text instead, with no fix on
GitHub's roadmap as of this writing. This matters specifically for a README's
primary/hero diagram, since that's the one most likely to be read on a phone.
For that diagram: keep the Mermaid `.mmd` source in the repository for
diffability and editing, but also render it ahead of time to a static SVG (or
PNG) and commit that image, embedding the image in the README with standard
Markdown image syntax rather than a live `mermaid` fence — this way it
displays on every client, apps included. Diagrams deeper in the docs (for
example `docs/ARCHITECTURE.md`'s Component Diagram) are read in a browser far
more often and can stay as plain fenced Mermaid blocks.

A rendered diagram still needs to actually look good, not just render:
mermaid's default theme (bright yellow cluster backgrounds, saturated purple
node fills, curvy bezier edges) reads as cluttered, and a graph with a
feedback loop back into an earlier node tangles visibly under mermaid's
automatic layout even when every individual edge is intentional. Favor a
muted custom theme (light tinted node fills, gray hairline borders/lines,
`curve: linear` for straight edges) and a one-directional acyclic layout;
push any true feedback relationship (for example "CI keeps X updated") into
the surrounding prose instead of forcing a loop-back arrow into the diagram.
Prefer a tall/narrow (`flowchart TD`) layout over a wide/short one (`LR`) for
anything embedded in a README: the image is scaled to the reader's column
width, so a wide diagram shrinks its text toward illegibility on a phone
while a tall one scales up and stays readable. `assets/diagrams/README.md`
in this repository documents the worked rendering setup (theme, curve,
layout choice) behind its own README diagram.

`docs/ARCHITECTURE.md`'s "Component Diagram" section (see
`templates/docs/ARCHITECTURE.md`) is where the Mermaid source for a project's
architecture lives; the README should link to it rather than duplicate it, but
may inline a smaller high-level diagram directly for a reader who never leaves
the README. This repository's own `README.md` ("Project Structure" and "How It
Works" sections) and `assets/diagrams/` are a worked example of both
patterns — including the pre-rendered-image pattern — applied to a
non-service, framework-shaped repository.

Like the "Current Capabilities" README requirement in `DOCUMENTATION.md`,
these are living artifacts: update the tree and diagrams in the same change
that changes the structure they describe, not in a deferred documentation pass.

## Maintenance

Architecture documentation should be updated when:

- A major design changes.
- A new service or integration is added.
- Data storage or flow changes.
- Deployment or infrastructure changes.
- A security-sensitive decision is made.
