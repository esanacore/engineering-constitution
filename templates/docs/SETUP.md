# Workstation Setup

This guide describes how to set up your local environment and run the project for the first time.

## IDE Setup

This project follows Eric's Engineering Constitution. To have it applied
automatically in **Visual Studio**, **VS Code**, or a **JetBrains IDE**, install
an AI coding assistant (GitHub Copilot, Continue.dev, or Cursor) and open the
repository — the assistant reads the instruction files committed here and picks
up the constitution with no extra configuration. After cloning, run
`git submodule update --init --recursive` so the `constitution/` submodule is
present. See `docs/HELP.md`, "Using This Project in Your IDE," for the per-IDE
file mapping and `constitution/INTEGRATION.md` for full details.

## Prerequisites

<!-- List required runtimes, tools, and versions (e.g., Node.js 20+, Python 3.12, git-lfs) -->

Pin the toolchain in a canonical file (for example, `.python-version`, `.tool-versions`, or `.nvmrc`) so every clone uses the same versions.

## Verify Prerequisites

Run the prerequisite check before installing. It should fail fast and name exactly what is missing (interpreter version, `git-lfs`, initialized submodules).

```bash
# e.g., make doctor
```

## Installation

```bash
# Clone the repository
git clone <repository-url>
cd <project-directory>

# Install dependencies
# e.g., npm install or pip install -r requirements.txt
```

## First Run

```bash
# Run the application in development mode
# e.g., npm start or python main.py
```

## Environment Variables

Copy `.env.example` to `.env` and fill in the required values.

```bash
cp .env.example .env
```
