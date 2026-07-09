# Diagrams

Rendered images for diagrams embedded in `README.md`.

GitHub's native mobile apps (iOS/Android) do not render ` ```mermaid ` fenced
code blocks — they show the raw source text instead. Only github.com in a
browser (desktop or mobile) renders Mermaid live. To make a README diagram
display everywhere, its Mermaid source is committed here and rendered ahead
of time to a static SVG that `README.md` embeds as a normal image. See
`ARCHITECTURE.md`'s "Visual Architecture" section for the full policy.

## Files

- `how-it-works.mmd`: Mermaid source for the diagram in README.md's "How It
  Works" section.
- `how-it-works.svg`: Rendered output, embedded directly in `README.md`.
- `mermaid-config.json`: Rendering config (`htmlLabels: false`) so node/edge
  text renders as native SVG `<text>` instead of HTML-in-`foreignObject`,
  maximizing compatibility with SVG viewers.

## Regenerating

After editing a `.mmd` file, re-render its `.svg`:

```bash
npm install --no-save @mermaid-js/mermaid-cli
npx mmdc -i assets/diagrams/how-it-works.mmd -o assets/diagrams/how-it-works.svg \
    -b white -c assets/diagrams/mermaid-config.json
```

Commit both files together so the source and the rendered image never drift.
