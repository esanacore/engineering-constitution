# Help

This file provides help for humans and AI agents working on this project.

## For Humans

- **Primary Maintainers**: <!-- Add names or team here -->
- **Getting Started**: Read `README.md` and `docs/SETUP.md`.
- **Asking for Help**: <!-- Add Slack channel, email, or issue tracker link here -->

## Using This Project in Your IDE

This project follows Eric's Engineering Constitution. You do **not** install
anything "for the constitution." Open the repository in your IDE with an AI
coding assistant installed, and the assistant automatically reads the
instruction files committed here — chiefly `AGENTS.md`, plus any tool-specific
file this repo carries — which point it at the read-only `constitution/`
submodule and its reading order.

| IDE | AI assistant | File it reads automatically |
|---|---|---|
| Visual Studio (2022 17.x / 2026 18.x) | GitHub Copilot (+ **Solon** custom agent) | `.github/copilot-instructions.md`, `AGENTS.md`, `.github/agents/solon.agent.md` |
| VS Code | GitHub Copilot / Continue.dev / Cursor | `.github/copilot-instructions.md`, `.continue/config.json`, `.cursor/rules/project.mdc`, `AGENTS.md` |
| JetBrains (IntelliJ, PyCharm, WebStorm, GoLand, Rider) | GitHub Copilot / Continue plugin | `.github/copilot-instructions.md`, `.continue/config.json`, `AGENTS.md` |

Some tool-specific files above are installed only when the project opted into
that tool at bootstrap time; `AGENTS.md` is always present and read by most
modern assistants directly. Run `git submodule update --init --recursive` after
cloning so the `constitution/` files the instructions point at exist.

To confirm the constitution is loaded, ask your assistant:
`Which engineering constitution files are you following, and what is the reading order?`
It should name `AGENTS.md` and describe the order starting from
`constitution/CONSTITUTION.md`.

Full per-IDE setup steps and Visual Studio / Solon details live in
`constitution/INTEGRATION.md`, "Using the Constitution in Your IDE."

## For AI Agents

- **Entry Point**: Read `AGENTS.md` and `constitution/CONSTITUTION.md`.
- **Workflow**: Follow `constitution/AI_WORKFLOW.md`.
- **Session Planning**: Check `docs/SESSION_PLAN.md` for a previous interrupted session; write your own plan there before implementing.
- **Project Memory**: Read `docs/MEMORY.md` to load project context, codebase learnings, and user preferences. Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.
- **Command Help**: See `docs/COMMAND_REFERENCE.md`.
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`.
- **Handoffs**: If you are finishing a session, see `docs/AGENT_HANDOFF.md` and clear or archive `docs/SESSION_PLAN.md`.

## Escalation Policy

If an agent is stuck or encounters an ambiguous situation:
1. Search `docs/TROUBLESHOOTING.md`.
2. Check `TODO.md` for related tasks or blockers.
3. Stop and ask the human user for clarification.
