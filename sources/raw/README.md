# Drop your files here

Put PDF, EPUB, DOCX, MD, or TXT files directly in this folder. Subfolders are
fine — they get mirrored into `../summaries/`.

This folder is gitignored (except this README and the `example/` demo below),
so nothing you drop here gets committed. Only the distilled summary you write
in `../summaries/` gets tracked.

Workflow:

```bash
bash scripts/check_source_summaries.sh scan
```

See [`../../KNOWLEDGE_SOURCES.md`](../../KNOWLEDGE_SOURCES.md) for the full
walkthrough. `example/sample-source.md` is a tiny worked demo — safe to
delete once you've dropped in your first real source.
