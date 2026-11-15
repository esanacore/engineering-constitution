# Session Log

One summary per working session: what was asked, the context the conversation
established, the decisions and their reasoning, what was learned, and what
shipped. Commits and the changelog record *what changed*; this log records
*why*, so a later agent or person can find it instead of rediscovering it.

**Before starting work**, read the newest rows below, then search the log for
the task's topic and read the summaries that match:

```bash
bash scripts/find_sessions.sh <keyword> [<keyword>...]
```

The scripts are bash and the commands are the same on every platform: Linux
and macOS run them as written; on Windows, run them from Git Bash or WSL.

**Before completing non-trivial work**, copy `TEMPLATE.md` to `YYYY-MM-DD-<slug>.md`, fill
it in, and rebuild the table below with
`bash scripts/build_session_index.sh .` (it is generated from the entries; do not
edit rows by hand). Summaries are append-only:
correct a mistake with a dated note, and record a change of direction in a
new summary that links the old one. A summary is not a transcript and never
carries secrets, credentials, personal data, or customer data.

`bash scripts/check_session_summaries.sh .` checks the format and
that every summary is listed here.

## Index

Newest first.

| Date | Session | Topics |
| --- | --- | --- |
| 2026-11-14 | [Tag and roll out 1.55.0, then generate the session-log index](2026-11-14-generated-session-index.md) | build_session_index.sh, session log index, docs/sessions/README.md, fleet bump, bump_adopters.sh, check_compliance.sh --strict, recommended tier, ubuntu-latest, Python 3.8, JDK 25, v1.54.0 backfill |
| 2026-11-14 | [Sales pitch deck for the engineering constitution](2026-11-14-pitch-deck.md) | pitch-deck.html, consulting, AI-native FDE, harness expert, sales, marketing, demo.html, stakeholder presentation |
| 2026-11-14 | [Prepare the 1.55.0 release](2026-11-14-release-1-55-0.md) | release, 1.55.0, version references, CHANGELOG, missing tag, v1.54.0, v1.53.0, GitHub Release, OTS inventory, Dependabot, fleet bump |
| 2026-11-14 | [Prepare the 1.56.0 release and settle the session-log questions](2026-11-14-release-1-56-0.md) | release, 1.56.0, ADR-0007 decisions, recommended tier, approval gating, docs/MEMORY.md, build_session_index.sh --check, constitution-compliance.yml, RELEASES.md, fleet rollout |
| 2026-11-14 | [Add session summaries and a searchable session log](2026-11-14-session-summaries.md) | session summaries, session log, docs/sessions, conversational context, decisions, agent memory, find_sessions.sh, check_session_summaries.sh, AI_WORKFLOW steps 9 10 27, next_steps_hook.sh, instruction templates, ADR-0007 |
