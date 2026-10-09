---
name: "readme-capabilities-sync"
description: "Enforces Principle 1. Analyzes PR/diffs and updates the Current Capabilities section of README.md, and keeps its setup, run, and test instructions broken out per platform and collapsed by default."
---
# README Capabilities Sync

Use this skill to ensure `README.md` stays up-to-date with new features. When modifying code that adds functionality, you MUST update the "What can it do today?" section in the README to reflect the change.

## Platform coverage and progressive disclosure

When a change touches how the project is installed, run, or tested, hold the README to `constitution/DOCUMENTATION.md`'s "Every Platform the Project Supports" and "Progressive Disclosure":

1. The README names the supported platforms, and the install, run, and test instructions carry one block per platform — Windows, macOS, Linux at minimum — wherever the commands differ. A Windows block is written for a Windows shell (PowerShell, `cmd`, or Git Bash), not for WSL. A command that is identical everywhere is given once.
2. Each platform block you add or change has been run on that platform, by you or by CI; if you cannot run one, write it from the project's CI configuration and say so in the pull request.
3. Per-platform blocks, the project tree, and alternative install paths sit in `<details>` blocks whose `<summary>` names the platform and shell; the capabilities list, the quick start, the hero diagram, the demo link, and every `##` heading stay visible. Keep a blank line after `<summary>` and before `</details>` so the Markdown inside renders.
4. Apply the same platform rule to `docs/SETUP.md`, `docs/COMMAND_REFERENCE.md`, and `docs/TROUBLESHOOTING.md` when the change touches a command they give.

**Constitution Alignment**: This skill strictly enforces the principles laid out in Eric's Engineering Constitution. Always adhere to the established workflows when applying this skill.
