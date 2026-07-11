# Knowledge Sources

The constitution already draws on specific books as authoritative tie-breakers
(for example, `ARCHITECTURE.md` cites Robert C. Martin's *Clean Architecture*
and the Gang of Four's *Design Patterns*). This document defines a repeatable
place to drop new primary sources — books, papers, long-form articles — so any
future influence on the constitution goes through the same careful-evaluation
step instead of being absorbed ad hoc.

## Two Kinds of Sources

This directory covers two different shapes of external material, handled
differently:

- **Books, papers, long-form articles** — static, often copyrighted files.
  Drop them in `raw/`, write a distilled summary in `summaries/`, and record
  the pairing in `manifest.tsv`. This is the workflow documented below.
- **Official, canonical style guides and standards** — public, continuously
  updated web pages maintained by a language or platform owner (for example,
  `developer.android.com`'s Kotlin style guide). These aren't downloaded or
  digested; they're recorded by reference in `sources/STYLE_GUIDES.md`, a
  simple tracked registry of URL + docstring/comment convention per
  language/platform. See `CODE_STYLE.md` for the principle this supports and
  `sources/STYLE_GUIDES.md` for the registry itself.

The rest of this document describes the raw/summary workflow for the first
kind.

## Directory Layout

```text
sources/
├── raw/               Gitignored. Drop PDF/EPUB/DOCX/MD/TXT files here, any depth.
├── summaries/          Tracked. One .md summary per raw file, mirrored path.
├── manifest.tsv         Tracked. path<TAB>sha256<TAB>summary<TAB>processed_at
└── STYLE_GUIDES.md      Tracked. Registry of official style guide URLs by language/platform.
```

Raw files are **never committed**. This avoids checking copyrighted book
files into Git history and keeps the repository small. Only the hash manifest
and the distilled summaries are tracked, so anyone can see what has been
evaluated and why without needing the original file.

`sources/README.md` and `sources/raw/README.md` are small tracked pointers
back to this document, so the workflow is discoverable straight from a file
browser without already knowing this file exists. A `README.md` (or
`readme.markdown`/`readme.txt`) left in `raw/` is deliberately invisible to
the scanner and to `record` — it's documentation, not a source.

## Try It First

`sources/raw/example/sample-source.md` and its matching
`sources/summaries/example/sample-source.md` are a tiny worked demo, already
recorded in `manifest.tsv`. Running `scan` right after cloning reports it as
`OK` — that's the demo, not a bug. Read the summary file to see the template
filled in, then delete both `example/` folders once you've dropped in your
first real source (or leave them; they don't interfere with anything).

## Workflow

1. Drop a file (or several) into `sources/raw/`. Subdirectories are fine and
   are mirrored into `sources/summaries/`.
2. Run the scanner to see what needs attention:

   ```bash
   bash scripts/check_source_summaries.sh scan
   ```

   Each file is reported as one of:
   - `NEW` — no manifest entry yet.
   - `CHANGED` — the file's contents changed since it was last processed.
   - `SUMMARY_MISSING` — recorded, but its summary file is gone.
   - `OK` — up to date.
   - `ORPHANED SUMMARY` — a summary exists for a raw file that was removed
     (warning only; consider deleting the stale summary and manifest row).

   `scan` exits `1` when anything is `NEW`/`CHANGED`/`SUMMARY_MISSING`, so it
   can be used as an on-demand check for pending work.
3. For each `NEW` or `CHANGED` entry, **read the source carefully** and write
   or update its summary at `sources/summaries/<same relative path, .md
   extension>`, following the template below.
4. Mark it processed:

   ```bash
   bash scripts/check_source_summaries.sh record <relative-path>
   ```

   This recomputes the file's hash and records it in `manifest.tsv`. It
   refuses to run if the summary has not been written yet — you cannot mark a
   source processed without actually producing the distillation.
5. Re-run `scan` to confirm everything is `OK`.

## Summary Template

```markdown
# <Title>

- **Source:** sources/raw/<relative path>
- **Author:** <author name(s)>
- **Processed:** <YYYY-MM-DD>

## Why This Matters

<1-3 sentences on why this source is relevant to the engineering constitution.>

## Key Takeaways

- <bulleted, concrete takeaways — not a chapter-by-chapter recap>

## Where It Could Apply

- <which constitution documents or principles this could eventually inform.
  This is informational only — writing a summary does not itself change
  CONSTITUTION.md, ARCHITECTURE.md, or any other governance document. Treat
  it as a lead for a future, separately reviewed change.>
```

Keep summaries honest distillations, not marketing copy: note tensions with
existing constitution principles as readily as agreements.

## Surfacing to Agents

Summaries are exposed through the constitution's MCP server
(`mcp-server/index.js`), which lists every file under `sources/summaries/` as
a resource (`constitution://source-summary/<relative-path>`) at request time.
Any MCP-connected agent can pull them in without reading the filesystem
directly. See `INTEGRATION.md` for how to register the MCP server.

Writing a summary does not automatically change any constitution document —
promoting an idea from a summary into `CONSTITUTION.md`, `ARCHITECTURE.md`, or
elsewhere is a deliberate, separately reviewed edit, same as any other change
to this framework.
