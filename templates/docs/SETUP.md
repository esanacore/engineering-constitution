# Workstation Setup

This guide describes how to set up your local environment and run the project for the first time.

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
