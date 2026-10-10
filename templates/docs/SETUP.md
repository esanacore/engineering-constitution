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

## Supported Platforms

<!-- Name the operating systems (and versions, where they matter) this project is built, run, and tested on, and name what is not supported. Say which platforms CI covers. -->

- Windows: <!-- e.g. Windows 11, PowerShell 7 -->
- macOS: <!-- e.g. macOS 14+ -->
- Linux: <!-- e.g. Ubuntu 22.04+ -->

## Prerequisites

<!-- List required runtimes, tools, and versions (e.g., Node.js 20+, Python 3.12, git-lfs) -->

Pin the toolchain in a canonical file (for example, `.python-version`, `.tool-versions`, or `.nvmrc`) so every clone uses the same versions.

Where installing a prerequisite differs by platform, give one block per platform, written for that platform's shell (`constitution/DOCUMENTATION.md`, "Every Platform the Project Supports"):

<details>
<summary>Windows (PowerShell)</summary>

```powershell
# e.g., winget install --id Git.Git -e
```

</details>

<details>
<summary>macOS (zsh)</summary>

```bash
# e.g., brew install git
```

</details>

<details>
<summary>Linux (bash)</summary>

```bash
# e.g., sudo apt install git
```

</details>

## Verify Prerequisites

Run the prerequisite check before installing. It should fail fast and name exactly what is missing (interpreter version, `git-lfs`, initialized submodules).

```bash
# e.g., make doctor
```

## Installation

```bash
# Clone the repository — same on every platform
git clone <repository-url>
cd <project-directory>

# Install dependencies
# e.g., npm install or pip install -r requirements.txt
```

<!-- When a step differs by platform (virtual-environment activation, path syntax, a native build tool), add one collapsed block per platform as in Prerequisites rather than a Linux block with a footnote. -->

## First Run

```bash
# Run the application in development mode
# e.g., npm start or python main.py
```

## Environment Variables

Copy `.env.example` to `.env` and fill in the required values.

```bash
cp .env.example .env            # macOS, Linux, Git Bash
```

```powershell
Copy-Item .env.example .env     # Windows PowerShell
```
