# Why the Constitution

AI coding agents can produce useful software remarkably quickly. That speed is valuable, but it also makes it easier to create code faster than a project can maintain its tests, documentation, architecture, security posture, dependency inventory, and operational knowledge.

Eric's Engineering Constitution treats AI-assisted development as an engineering workflow rather than a code-generation shortcut.

## The problem it addresses

A capable coding agent can implement a feature in minutes. The surrounding engineering work is easier to neglect:

- tests may prove only the happy path;
- documentation can stop matching the implementation;
- architectural boundaries can erode one convenient import at a time;
- dependencies can appear without an inventory or risk review;
- secrets and configuration can leak into source control;
- requirements can lose their connection to verification;
- TODOs and discovered improvements can disappear with the chat session;
- releases can accumulate indefinitely in an `Unreleased` section;
- a second human or agent may have no reliable context for continuing the work.

The Constitution makes those responsibilities part of the definition of completing a change.

## The central idea

**AI should increase engineering throughput without lowering engineering discipline.**

The framework gives humans and agents the same durable source of truth. The standards live with the project, are versioned with Git, and are backed by automation wherever a rule can be checked reliably.

That creates a workflow in which an agent is expected to understand the repository before changing it, plan the work, implement and test it, update the supporting engineering artifacts, review security and release impact, and leave the repository in a state another engineer can understand.

## Why a constitution instead of a giant prompt?

A prompt is temporary context. A repository is durable engineering context.

The Constitution separates concerns into versioned documents such as:

- `CONSTITUTION.md` for universal principles;
- `AI_WORKFLOW.md` for the required work sequence;
- `TESTING.md`, `SECURITY.md`, `ARCHITECTURE.md`, and other topic standards for deeper rules;
- project-local `AGENTS.md`, `TODO.md`, requirements, architecture, operations, and memory documents for repository-specific context.

This makes the system inspectable by humans, usable by multiple agent products, reviewable in pull requests, and improvable over time.

## Human and agent collaboration

The Constitution is intentionally not an attempt to remove humans from software engineering. It defines a common operating model for both.

Humans still own product intent, judgment, tradeoffs, approvals, and accountability. Agents can take on a large amount of implementation and maintenance work, but they are expected to show their work through tests, documentation, plans, traceability, changelogs, and reviewable Git history.

The result is closer to a disciplined engineering teammate than an unconstrained code generator.

## Automation as a backstop

The framework automates rules that can be checked objectively, including areas such as:

- repository governance completeness;
- requirements traceability;
- declared test execution;
- documentation freshness signals;
- architecture dependency direction;
- third-party software inventory drift;
- environment-variable documentation;
- secret detection;
- Constitution version alignment.

Automation is deliberately a backstop rather than a substitute for judgment. Structural signals can prompt review without pretending that every engineering decision can be reduced to a pass/fail rule.

## Designed to travel between tools

The principles are not tied to one model or coding-agent vendor. Repository-level instruction bridges, templates, and MCP resources make the same engineering expectations available across different agent environments.

That matters because tools will change. The engineering standards should survive the tool choice.

## Where to go next

- [[Getting Started]] — adopt the Constitution in a repository.
- [[AI Development Workflow]] — see what an AI-assisted change looks like end to end.
- [[Standards Overview]] — explore the twelve principles and topic standards.
- [[Governance Checkers]] — see how the framework turns standards into automated guardrails.
- [[Architecture and Design]] — understand the architectural philosophy behind the framework.
