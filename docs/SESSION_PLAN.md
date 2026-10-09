# Session Plan

## Session: 2026-10-09 — README instructions per platform, collapsed by default

### Goals

1. Make the constitution insist that README (and other command-bearing docs)
   break out setup, run, and test instructions per operating system —
   Windows, macOS, Linux at minimum — instead of assuming Linux.
2. Adopt progressive disclosure for READMEs: `<details>`/`<summary>`
   collapsible sections so the page reads short by default, with a stated
   list of what always stays visible.
3. Apply both to this repository's own README and the README template as the
   worked examples; cut 1.53.0.

### Approach

- `DOCUMENTATION.md` "README Expectations": two new subsections ("Every
  Platform the Project Supports", "Progressive Disclosure") plus bullets.
- `CONSTITUTION.md` Principle 1: one paragraph naming the rule.
- `templates/README.md`: restructure as the worked example (visible
  capabilities + quick start with supported-platforms line; one collapsed
  block per platform; collapsed project tree).
- `README.md` (this repo): per-platform prerequisites (macOS ships bash 3.2,
  Windows uses Git Bash), long sections collapsed, required content visible.
- `templates/docs/SETUP.md`: per-platform structure in Installation.
- Skill `readme-capabilities-sync`, Solon (root + template), wiki
  (Standards-Overview, Home, Templates-and-Examples), `demo.html` Principle 1
  text, CHANGELOG 1.53.0, TODO, version references, handoff.

### Files expected to change

`DOCUMENTATION.md`, `CONSTITUTION.md`, `README.md`, `templates/README.md`,
`templates/docs/SETUP.md`, `skills/readme-capabilities-sync/SKILL.md`,
`.github/agents/solon.agent.md`, `templates/.github/agents/solon.agent.md`,
`demo.html`, `wiki/*.md`, `CHANGELOG.md`, `TODO.md`, `VERSION`,
`mcp-server/package.json`, `mcp-server/package-lock.json`,
`docs/AGENT_HANDOFF.md`, this file.

### Risks

- `test_release_docs.sh` / `check_demo_page.sh` grep README for the version
  line and the demo link: both must stay outside any `<details>` block they
  would otherwise still match, but keep them visible anyway.
- MINOR-shaped (new advisory guidance, no checker, no CI effect): no ADR
  trigger, no deprecation window needed.

### Resumption Notes

- All edits made; full suite and self-governance checks green; 1.53.0 cut.
- Isolated critique pass in flight; fold findings in, clear this plan, open the PR.
