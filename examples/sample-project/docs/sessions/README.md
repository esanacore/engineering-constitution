# Session Log

One summary per working session: what was asked, the context the conversation
established, the decisions and their reasoning, what was learned, and what
shipped. Commits and the changelog record *what changed*; this log records
*why*, so a later agent or person can find it instead of rediscovering it.

**Before starting work**, read the newest rows below, then search the log for
the task's topic and read the summaries that match:

```bash
bash constitution/scripts/find_sessions.sh <keyword> [<keyword>...]
```

The scripts are bash and the commands are the same on every platform: Linux
and macOS run them as written; on Windows, run them from Git Bash or WSL.

**Before completing non-trivial work**, copy `TEMPLATE.md` to `YYYY-MM-DD-<slug>.md`, fill
it in, and add a row at the top of the table. Summaries are append-only:
correct a mistake with a dated note, and record a change of direction in a
new summary that links the old one. A summary is not a transcript and never
carries secrets, credentials, personal data, or customer data.

`bash constitution/scripts/check_session_summaries.sh .` checks the format and
that every summary is listed here.

## Index

Newest first.

| Date | Session | Topics |
| --- | --- | --- |
| 2026-01-12 | [Adopt the engineering constitution](2026-01-12-adopt-constitution.md) | bootstrap, constitution submodule, AGENTS.md, vendor instruction files |
