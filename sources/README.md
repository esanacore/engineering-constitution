# sources/

Drop-in location for book and reference material that informs the
constitution. See [`../KNOWLEDGE_SOURCES.md`](../KNOWLEDGE_SOURCES.md) for
the full workflow.

- `raw/` — Gitignored. Drop your PDF/EPUB/DOCX/MD/TXT files here (subfolders
  are fine).
- `summaries/` — Tracked. One distilled summary per raw file, mirroring its
  relative path.
- `manifest.tsv` — Tracked. The hash ledger `scripts/check_source_summaries.sh`
  uses to detect new or changed files.

`raw/example/` and `summaries/example/` are a small worked demo showing the
whole loop already wired up — read `summaries/example/sample-source.md` for
a filled-in example, then delete both `example/` folders once you've dropped
in your own first source.
