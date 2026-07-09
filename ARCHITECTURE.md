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
put together," not only a written one:

- **A project structure section**: a fenced `text` code block containing a
  directory tree of the repository's top-level layout, annotated with a short
  comment per entry explaining what lives there. This is the fastest
  orientation tool for a new contributor or an AI agent — faster than reading
  `ls` output or a wall of bullets.
- **A component or flow diagram** for any system with more than one moving
  part: multiple services, a non-trivial data flow, an integration/adoption
  flow, or a request lifecycle worth seeing at a glance. A single box-and-line
  diagram often replaces a paragraph of prose.

Use [Mermaid](https://mermaid.js.org/) for these diagrams by default. It is
plain text (diffable in pull requests, no binary asset to keep in sync), needs
no external tool or build step, and renders natively in GitHub's and GitLab's
Markdown preview. Reach for a linked image only when a diagram genuinely needs
something Mermaid cannot express.

`docs/ARCHITECTURE.md`'s "Component Diagram" section (see
`templates/docs/ARCHITECTURE.md`) is where the Mermaid source for a project's
architecture lives; the README should link to it rather than duplicate it, but
may inline a smaller high-level diagram directly for a reader who never leaves
the README. This repository's own `README.md` ("Project Structure" and "How It
Works" sections) is a worked example of both patterns applied to a
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
