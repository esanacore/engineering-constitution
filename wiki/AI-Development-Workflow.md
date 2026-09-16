# AI Development Workflow

The Constitution defines a repeatable lifecycle for AI-assisted changes. The authoritative checklist lives in `AI_WORKFLOW.md`; this page explains the intent behind it.

## 1. Load the engineering context

Before changing code, the agent reads the repository's instructions and current state: agent rules, Constitution standards, README, TODOs, changelog, relevant operations documentation, project memory, and any interrupted-session plan.

It also checks branches, worktrees, and open pull requests for overlapping work. This reduces the risk of an agent solving an already-solved problem or colliding with another engineer or agent.

## 2. Create a recoverable plan

The agent writes or updates `docs/SESSION_PLAN.md` before implementation begins. The plan records goals, approach, expected files, risks, and resumption notes.

This is deliberately stored in the repository rather than only in a chat window. If an agent session crashes or context is lost, another agent or human can recover the intended direction.

## 2a. Scale the workflow to the change

Not every change is a feature. `AI_WORKFLOW.md`'s "Proportionate Workflow"
(ADR-0003) defines a **trivial** change by four tests that must all hold — no
behavior change, small enough for one screen, nothing on the sensitive list
(dependencies, environment variables, secrets, auth, CI, instruction files,
checkers, templates), and nobody has asked for the full workflow — and names
exactly which steps such a change may skip: the session plan, the
implementation plan, coverage evaluation, the isolated critique, traceability
and inventory updates, release evaluation, and memory proposals. The scoped
reads, the secrets sweep, and the pull request never shrink to nothing, and
the pull request says the fast path was taken so a reviewer can disagree.
When in doubt, it is not trivial.

## 3. Implement within the existing architecture

Changes should follow the repository's established conventions and architectural boundaries. The Constitution discourages unrelated refactoring and speculative abstractions while still requiring agents to recognize genuine coupling, security, or maintainability problems.

See [[Architecture and Design]] for the design philosophy.

## 4. Prove the behavior

Behavioral changes require appropriate automated tests. The goal is not simply to add one test that turns CI green; the agent evaluates which levels of the test pyramid genuinely apply and runs the project's declared suite.

Bug fixes should include regression coverage. Coverage gaps are evaluated rather than hidden.

## 5. Critique from a fresh context

Before documentation begins, the finished diff gets an isolated critique pass: a fresh context — a sub-agent, a second session, or at minimum a distinct pass that re-reads only the final diff rather than the conversation that produced it — questions whether the change is correct, minimal, and as simple as it could be.

The same context that planned and implemented a change is a poor judge of it; isolating the critique restores the distance that makes human code review work.

## 6. Keep engineering artifacts synchronized

Implementation is only part of the change. Depending on impact, the same work may also update:

- requirements and requirements traceability;
- third-party/OTS software inventory;
- environment and configuration contracts;
- architecture documentation and ADRs;
- operations/runbook documentation;
- README capabilities;
- TODO roadmap;
- changelog and version information.

The principle is simple: documentation debt should not be deliberately created as a side effect of moving faster.

## 7. Review security and release impact

Before completion, the agent evaluates security impact and performs the repository's secret sweep. It also asks whether accumulated user-facing work should trigger a release rather than allowing changes to remain indefinitely under `Unreleased`.

## 8. Preserve useful learning

During work, an agent may discover a repository-specific convention, user preference, or important decision. The Constitution tells the agent to propose durable learnings to the user and, after approval, record them in project memory.

This allows useful context to accumulate intentionally without treating every chat statement as permanent policy.

## 9. Finish cleanly

Before declaring the task complete, the agent verifies tests and documentation, clears or archives the session plan, summarizes the work, merges or opens a pull request, and cleans up only the Git state it owns.

The repository should be easier for the next engineer to understand than it was before the change.

## What this workflow is trying to prevent

The workflow specifically guards against common failure modes of high-speed AI development:

- coding before understanding the project;
- duplicate or conflicting parallel work;
- untested generated behavior;
- unexamined self-review, where the context that wrote a change is the only one that ever questioned it;
- stale README and requirements documentation;
- undocumented dependencies and configuration;
- architecture drift;
- leaked secrets;
- abandoned branches and worktrees;
- important decisions trapped inside an expired chat session.

## Authoritative source

This page is explanatory. `AI_WORKFLOW.md` in the repository is the authoritative and versioned workflow.

## See also

- [[Why the Constitution]]
- [[Getting Started]]
- [[Governance Checkers]]
- [[Standards Overview]]
- [[Architecture and Design]]
