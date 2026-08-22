# Architecture and Design

The Constitution treats architecture as a set of practical guardrails rather than a reason to add ceremony. The authoritative rules live in `ARCHITECTURE.md`; this page explains the philosophy and how it connects to automation.

## Intentional, not elaborate

The goal is not to make every project look like an enterprise architecture diagram. The goal is to keep important boundaries intentional as a system grows.

The framework uses SOLID principles, the Dependency Rule, established design patterns, and Architecture Decision Records (ADRs) as shared engineering vocabulary. Each should solve a real problem rather than exist to satisfy a checklist.

## SOLID as practical guardrails

The Constitution frames SOLID in terms of recognizable engineering smells:

- **Single Responsibility** — split a module when genuinely different actors or stakeholders force it to change for unrelated reasons, not merely because the file is long.
- **Open/Closed** — introduce an extension point when a real second case appears rather than predicting abstractions that may never be needed.
- **Liskov Substitution** — if a subtype cannot honor the base contract, prefer composition over pretending it is substitutable.
- **Interface Segregation** — avoid forcing clients or implementers to depend on capabilities they do not use.
- **Dependency Inversion** — keep high-level policy independent of databases, frameworks, HTTP clients, and other implementation details.

## The Dependency Rule

Source dependencies should point toward higher-level policy. Domain and business rules should not need to know which database, UI framework, delivery mechanism, or third-party SDK happens to sit at the edge of the system.

Projects can document their actual layers in `docs/ARCHITECTURE.md` using a `Layer Boundaries` table. The Constitution's architecture checker can then verify that imports follow the declared direction and that the declared dependency graph is acyclic.

This makes architecture partly executable: a project documents the boundary once, then automation can detect concrete violations.

## Signals are not verdicts

The architecture checker may also report structural signals such as oversized files or crowded directories. Those are review prompts, not automatic failures.

That distinction is intentional. A long file can be perfectly cohesive, while a short file can still violate every meaningful boundary. The Constitution automates what can be objectively checked without pretending metrics can replace engineering judgment.

## Design patterns

Patterns are treated as a shared vocabulary for recurring problems, not badges to collect. The framework calls out patterns such as Factory, Adapter, Decorator, Facade, Strategy, Observer, Command, and Template Method while emphasizing two ideas:

- program to an interface, not an implementation;
- favor composition over inheritance.

A pattern should appear because a real second implementation, boundary, coupling problem, or testability problem exists—not because an agent recognizes an opportunity to make the code more abstract.

## Architecture Decision Records

Significant architectural decisions should be captured as ADRs so future humans and agents can understand not only *what* the architecture is, but *why* it became that way.

The bootstrap templates provide ADR scaffolding under `docs/adr/` for adopting projects.

## Why this matters for AI-assisted development

Coding agents are very good at making locally convenient changes. Architecture problems, however, often emerge from a sequence of locally convenient decisions.

By putting boundaries and design expectations in versioned repository context—and checking objective boundaries in CI—the Constitution gives agents a better chance of preserving the system-level design while moving quickly.

## See also

- [[Why the Constitution]]
- [[AI Development Workflow]]
- [[Standards Overview]]
- [[Governance Checkers]]
- [[Templates and Examples]]
