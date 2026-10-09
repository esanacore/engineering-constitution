# Project Name

<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->

Briefly describe what this project does and who it is for.

<!--
  This template follows constitution/DOCUMENTATION.md, "README Expectations":
  - "Every Platform the Project Supports": name the supported platforms, and
    give install, run, and test instructions one block per platform
    (Windows, macOS, Linux at minimum) wherever the commands differ. A
    Windows block is written for a Windows shell, not for WSL.
  - "Progressive Disclosure": the capabilities list, the quick start, the
    hero diagram, and every ## heading stay visible; per-platform blocks,
    the project tree, and alternative install paths are collapsed with
    <details>. Keep a blank line after <summary> and before </details>.
  Delete these comments once the README describes the real project.
-->

## Current Capabilities

<!-- The "what can it do today?" list. Update it in the same change that adds, changes, or removes a feature. -->

- Capability one
- Capability two

## Quick Start

**Supported platforms:** <!-- e.g. Windows 11 (PowerShell 7), macOS 14+, Ubuntu 22.04+ — and name what is not supported --> CI runs on <!-- e.g. Ubuntu and Windows -->.

<!-- A command that is the same on every platform stays visible here; everything that differs goes into the per-platform blocks below. -->

```bash
git clone <repository-url>
cd <project-directory>
```

<details>
<summary>Windows (PowerShell)</summary>

```powershell
# Example
winget install --id Git.Git -e
.\scripts\setup.ps1
```

</details>

<details>
<summary>macOS (zsh)</summary>

```bash
# Example
brew install <tool>
make setup
```

</details>

<details>
<summary>Linux (bash)</summary>

```bash
# Example
sudo apt install <tool>
make setup
```

</details>

## Run

<!-- Same on every platform? Say so once and keep one block. Otherwise one collapsed block per platform, as in Quick Start. -->

```bash
# Example — same on every platform
make run
```

## Test

<!-- Same on every platform? Say so once and keep one block. Otherwise one collapsed block per platform, as in Quick Start. -->

```bash
# Example — same on every platform
make test
```

## Demo

<!-- Product-facing repositories link demo.html here (its published URL when there is one); others delete this section. -->

Open [`demo.html`](demo.html) to see the product work without installing it.

## Project Structure

<!--
  A directory tree of the top-level layout, annotated with a short comment
  per entry. See the engineering-constitution repository's own README.md for
  a worked example. Update this in the same change that changes the layout.
  The heading stays visible; the tree is collapsed once it runs past a dozen
  lines.
-->

<details>
<summary>Full project structure</summary>

```text
project/
├── src/          ← Core logic
├── tests/        ← Automated tests
├── docs/         ← Supplemental documentation, including ARCHITECTURE.md
└── constitution/ ← Universal engineering rules (git submodule)
```

</details>

Add at least one infographic (a component or data-flow diagram) whenever possible, and keep it visible rather than collapsed — see `docs/ARCHITECTURE.md`'s Component Diagram section for the Mermaid source, and inline a smaller version here if it helps a reader who never leaves the README.

## Documentation

- Setup, per platform: `docs/SETUP.md`
- Roadmap: `TODO.md`
- Changelog: `CHANGELOG.md`
- Architecture decisions: `docs/adr/`
- Operations runbook: `docs/OPERATIONS.md` when the project has runtime or deployment behavior
- Product requirements: `docs/PRODUCT_REQUIREMENTS.md` when applicable
- MVP backlog: `docs/MVP_BACKLOG.md` when applicable

## Contributing

Before completing work:

- Update tests.
- Update documentation, including the per-platform instructions above for every platform the change touches.
- Update TODO.md.
- Update CHANGELOG.md for user-facing changes.
- Review security impact.
