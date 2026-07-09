# Project Name

<!-- CONSTITUTION_START -->
[![Eric's Engineering Constitution](https://img.shields.io/badge/Eric's%20Engineering%20Constitution-Adopted-blue)](https://github.com/esanacore/engineering-constitution)
<!-- CONSTITUTION_END -->

Briefly describe what this project does and who it is for.

## Getting Started

Document setup steps here.

```bash
# Example
make setup
```

## Run

Document how to run the project.

```bash
# Example
make run
```

## Test

Document how to run tests.

```bash
# Example
make test
```

## Project Structure

<!--
  A directory tree of the top-level layout, annotated with a short comment
  per entry. See the engineering-constitution repository's own README.md for
  a worked example. Update this in the same change that changes the layout.
-->

```text
project/
├── src/          ← Core logic
├── tests/        ← Automated tests
├── docs/         ← Supplemental documentation, including ARCHITECTURE.md
└── constitution/ ← Universal engineering rules (git submodule)
```

For a component or data-flow diagram, see `docs/ARCHITECTURE.md`.

## Documentation

- Roadmap: `TODO.md`
- Changelog: `CHANGELOG.md`
- Architecture decisions: `docs/adr/`
- Operations runbook: `docs/OPERATIONS.md` when the project has runtime or deployment behavior
- Product requirements: `docs/PRODUCT_REQUIREMENTS.md` when applicable
- MVP backlog: `docs/MVP_BACKLOG.md` when applicable

## Contributing

Before completing work:

- Update tests.
- Update documentation.
- Update TODO.md.
- Update CHANGELOG.md for user-facing changes.
- Review security impact.
