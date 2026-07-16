# Contributing to this Project

Thank you for contributing! This project follows [Eric's Engineering Constitution](constitution/CONSTITUTION.md).

## For Humans

Please follow the standard Git Flow:
1. Fork the repository.
2. Create a feature branch.
3. Commit your changes with clear, descriptive messages.
4. Submit a Pull Request.

## For AI Agents

This repository is "agent-first." You are expected to operate autonomously while adhering to the following:

### 1. Mandatory Reading
Before starting, you MUST read:
- `constitution/CONSTITUTION.md` (Universal Principles)
- `constitution/AI_WORKFLOW.md` (Required Workflow)
- `AGENTS.md` (Project-Specific Rules)
- `docs/MEMORY.md` (Project Memory)

### 2. Operational Standards
- **Session Planning**: Check `docs/SESSION_PLAN.md` for a previous interrupted session, then write your own plan there before implementing.
- **Project Memory**: Read `docs/MEMORY.md` to load project context and preferences. Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md` before completing work.
- **Testing**: Every change requires updated or new automated tests.
- **Documentation**: Update `README.md`, `CHANGELOG.md`, and `TODO.md` for every task.
- **Security**: Perform a security review of your changes.
- **Handoff**: Record your progress in `docs/AGENT_HANDOFF.md` at the end of your session, and clear or archive `docs/SESSION_PLAN.md`.

## Getting Help

If you are stuck, refer to `HELP.md` or `docs/TROUBLESHOOTING.md`.
