# CLAUDE.md

This repository follows Eric's Engineering Constitution.

## Required Reading

Before making changes, read:

- `constitution/CONSTITUTION.md`
- `constitution/AI_WORKFLOW.md`
- `constitution/TESTING.md`
- `constitution/DOCUMENTATION.md`
- `constitution/SECURITY.md`
- `constitution/CODE_STYLE.md`
- `README.md`
- `TODO.md`
- `CHANGELOG.md`
- `docs/MEMORY.md`

## gstack (Optional — delete this section if unused)

This section applies only if this project has adopted
[gstack](https://github.com/garrytan/gstack) for AI-assisted workflows.
gstack is a third-party skill suite, not a constitution requirement — if
this project doesn't use it, delete this entire section (through "Available
gstack skills" below).

If this project *does* use gstack, verify it's installed before relying on
any skill below:

```bash
test -d ~/.claude/skills/gstack/bin && echo "GSTACK_OK" || echo "GSTACK_MISSING"
```

If `GSTACK_MISSING`, the one-shot fix is `bash constitution/scripts/setup-machine.sh`
(installs Bun, gstack, goose, and goosetown together, idempotently, run
once per machine — see `constitution/INTEGRATION.md` "Provisioning a
Machine in One Step"). Or install gstack alone (requires [Bun](https://bun.sh)
v1.0+ — install with `curl -fsSL https://bun.sh/install | bash` first if
`bun --version` fails):

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup
```

On a Linux distro Playwright doesn't officially recognize yet (its browser
install fails with `Playwright does not support chromium on <distro>-x64`),
`/browse` and other browser-driving skills need one more step — a same-family
fallback build still works:

```bash
cd ~/.claude/skills/gstack/browse
PLAYWRIGHT_HOST_PLATFORM_OVERRIDE=ubuntu24.04-x64 bunx playwright install chromium chromium-headless-shell
```

(Swap `ubuntu24.04-x64` for the newest Ubuntu Playwright's installer actually
lists as supported at the time — check the error message it prints.)

- Use the `/browse` skill from gstack for **all** web browsing.
- **Never** use `mcp__claude-in-chrome__*` tools.
- Run `/setup-gbrain` once in this repository to initialize the project brain.

Available gstack skills:

- `/office-hours`
- `/plan-ceo-review`
- `/plan-eng-review`
- `/plan-design-review`
- `/design-consultation`
- `/design-shotgun`
- `/design-html`
- `/review`
- `/ship`
- `/land-and-deploy`
- `/canary`
- `/benchmark`
- `/browse`
- `/connect-chrome`
- `/qa`
- `/qa-only`
- `/design-review`
- `/setup-browser-cookies`
- `/setup-deploy`
- `/setup-gbrain`
- `/retro`
- `/investigate`
- `/document-release`
- `/document-generate`
- `/codex`
- `/cso`
- `/autoplan`
- `/plan-devex-review`
- `/devex-review`
- `/careful`
- `/freeze`
- `/guard`
- `/unfreeze`
- `/gstack-upgrade`
- `/learn`

## Completion Checklist

Before completing work:

- Confirm the requested change is implemented.
- Add or update relevant tests.
- Evaluate coverage against targets and record any gaps.
- Update requirements traceability for product-facing repositories.
- Update the OTS software inventory (`docs/OTS_SOFTWARE.md`) when third-party dependencies changed.
- Update documentation when needed.
- Update TODO.md with discovered or completed work.
- Update CHANGELOG.md for user-facing changes.
- Consider security impact.
- Propose new codebase learnings, user preferences, or major decisions to the user and (upon approval) record them in `docs/MEMORY.md`.
- Identify useful follow-up work.
- Clear or archive `docs/SESSION_PLAN.md`.
- Summarize changes and verification.