# Workstation Setup

How to work on the framework itself. Adopters do not need this; they run
`scripts/bootstrap.sh` from a clone and follow their own `docs/SETUP.md`.

## Prerequisites

- **bash 4+** and **Git 2.x**. On Windows use Git Bash (MSYS2); the suites are
  kept portable to it (see `docs/TROUBLESHOOTING.md`).
- **Node.js 20+** only if you touch `mcp-server/`.
- **Python 3** is not required by anything shipped, but `pre-commit` (Python)
  is the recommended way to run the pre-push secrets sweep locally.

## Verify Prerequisites

```bash
bash --version | head -n 1
git --version
bash scripts/run_all_tests.sh --quiet   # the full suite is the prerequisite check
```

If the suite fails on a fresh clone, the most common causes are a missing
executable bit (never on a clone from GitHub; see `docs/TROUBLESHOOTING.md`)
or a global gitignore hiding `scripts/lib/` (`.gitignore` here un-ignores it).

## Installation

```bash
git clone https://github.com/esanacore/engineering-constitution.git
cd engineering-constitution
pip install pre-commit && pre-commit install && pre-commit install --hook-type pre-push
cd mcp-server && npm install && cd ..   # optional, MCP server only
```

## First Run

```bash
bash scripts/run_all_tests.sh --quiet
bash scripts/check_instruction_templates.sh --strict .
bash scripts/check_skills.sh --strict .
bash scripts/check_wiki_links.sh --strict .
```

## IDE Setup

Open the repository in any IDE with an AI assistant; `AGENTS.md`, `CLAUDE.md`,
and `.github/copilot-instructions.md` point the assistant at the standards.
See `INTEGRATION.md`, "Using the Constitution in Your IDE".
