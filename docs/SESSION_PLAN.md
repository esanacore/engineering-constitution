# Session Plan

_No active session. This file is written at the start of a session with its
goals, approach, expected file changes, and risks (see `AI_WORKFLOW.md`), and
cleared once the outcomes are captured in commit messages, `CHANGELOG.md`, or
`docs/AGENT_HANDOFF.md`._

## Last completed

`scripts/check_demo_page.sh` + `scripts/test_check_demo_page.sh`: the Demo
Page standard checked mechanically rather than by presence. Wired into
`tests.yml` (`--strict`, self-governance) and the adopter
`constitution-compliance.yml` template (warn mode, skips older pins). The
constitution's own `demo.html` dropped its Google Fonts to pass. An isolated
critique pass surfaced missed loads (ES-module imports, SVG, `<base>`, `>` in
quoted attributes) and false positives (page text, mid-path `out/`); all fixed
with regression tests, and a quadratic scan (56s on a 5.5 MB page) was made
linear (0.7s). Outcomes are in `CHANGELOG.md` `Unreleased`. Not yet released.
