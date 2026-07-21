# Getting Started

This page walks a new project through adopting Eric's Engineering Constitution.
It is the wiki companion to `README.md`'s "Getting Started" section.

## Prerequisites

- A Git repository for the project you want to bring under the constitution.
- Network access to this constitution repository (to add it as a submodule).
- Bash available on the machine running the bootstrap.

## Adoption in three steps

1. **Make this repository reachable.** Publish or clone Eric's Engineering
   Constitution somewhere your projects can add it as a submodule.

2. **Bootstrap the target project.** From this repository, run the installer
   against the project you want to adopt the standard:

   ```bash
   ./scripts/bootstrap.sh /path/to/project <repository-url>
   ```

   By default only `AGENTS.md` is installed as the agent-instruction bridge.
   Add vendor-specific files for the tools the project actually uses:

   ```bash
   ./scripts/bootstrap.sh --agents=claude,cursor /path/to/project <repository-url>
   ```

   See [[Bootstrap Script]] for exactly what gets installed and why the default
   is deliberately minimal.

3. **Review and finish the adoption.** Open
   `.constitution-bootstrap/adoption-report.md` in the target project, merge any
   skipped template content into existing files, and replace every template
   placeholder with real, project-specific content — a copied template is not
   finished documentation. Then commit the `constitution/` submodule together
   with the generated governance files.

## After adoption

- Read the core standards, starting with `CONSTITUTION.md` and `AI_WORKFLOW.md`.
  [[Standards Overview]] summarizes the full set.
- Fill in the recommended documents under `docs/` (`TEST_PLAN.md`,
  `OTS_SOFTWARE.md`, `ENV_VARS.md`, and the rest) as they become relevant.
- Turn on the CI governance checks, which start in warn-only mode. See
  [[Governance Checkers]] for what each one enforces and when to move it to
  `--strict`.

## See also

- [[Bootstrap Script]]
- [[Governance Checkers]]
- [[Standards Overview]]
