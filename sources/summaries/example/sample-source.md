# Example Source (Demo Fixture)

- **Source:** sources/raw/example/sample-source.md
- **Author:** N/A — demo fixture, not a real source
- **Processed:** 2026-07-04

## Why This Matters

It doesn't — this is a worked example, not a real evaluation. It exists to
show what a completed summary and manifest entry look like, and to give
`scripts/check_source_summaries.sh scan` something to report as `OK`
immediately after cloning, instead of an empty directory with no obvious
next step.

## Key Takeaways

- Drop a real file into `sources/raw/` (subfolders are fine — they're
  mirrored here).
- Run `bash scripts/check_source_summaries.sh scan` to see it reported as
  `NEW`.
- Read it carefully and write its summary at the mirrored path under
  `sources/summaries/`, following this file's structure.
- Run `bash scripts/check_source_summaries.sh record <relative-path>` to
  mark it processed.
- Delete this `example/` folder (in both `raw/` and `summaries/`) whenever
  you're ready — it's not required for the tool to work.

## Where It Could Apply

- Nowhere — it's a fixture, not a real source. Real entries go here once
  you've actually evaluated something.
