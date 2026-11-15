# Session: Sales pitch deck for the engineering constitution

- **Date:** 2026-11-14
- **Agent:** Cursor (Composer)
- **Branch / PR:** release/v1.55.0 (local; uncommitted until requested)
- **Topics:** pitch-deck.html, consulting, AI-native FDE, harness expert, sales, marketing, demo.html, stakeholder presentation
- **Related:** sources/summaries/articles/the-harness-is-the-thing.md; DOCUMENTATION.md Demo Page; ADR-0002

## Request

Generate a polished, clear pitch deck for the engineering constitution so it can be used with sales leads — marketing the solution as something a harness expert developed and can install/coach for clients, not only listing open-source features. Follow-up: be seen as a harness expert and a competent AI-native forward-deployed engineer starting consulting work.

## Context

The requester wants a presentable artifact for stakeholder conversations while starting consulting. Positioning must lead with Eric (AI-native FDE / harness expert), not the open-source product alone; the constitution is proof of craft and the system installed on engagement. The repository already has `demo.html` as a product explainer; the pitch deck is the consulting narrative.

## Decisions

- **HTML fullscreen slide deck (`pitch-deck.html`), not PowerPoint** — agent: self-contained, shareable via GitHub Pages / `file://`, keyboard nav, print-to-PDF; matches the repo’s offline documentation habit.
- **Lead with the person, prove with the system:** title/CTA sell consulting FDE capacity; constitution slides are “what I bring / what you can audit.”
- **Narrative arc:** problem → harness thesis → who you hire (FDE) → system → deploy path → feature maps → credibility → consulting engagement shapes → fit → CTA.
- **Visual direction:** cool paper + deep ink + teal accent (avoid purple/indigo, cream+terracotta, broadsheet). No remote font/CDN loads so the artifact stays offline-friendly.
- **Link from README, demo, and wiki Home** so the deck is discoverable next to the product demo.

## Discoveries

- No prior session covered pitch/marketing decks.
- Playwright MCP Chrome is not installed in this environment; Firefox headless screenshot was unreliable due to an existing Firefox process — visual QA was done by structure/CSS review rather than screenshots.
- JFrog package-resolution hooks block npm installs until `jf` is configured; that blocked installing Playwright Chrome for visual capture.

## Outcome

Shipped and then reframed `pitch-deck.html` (12 slides) for consulting: Eric as AI-native FDE / harness expert; constitution as inspectable delivery system; engagement shapes (sprint / embedded weeks / retainer). Linked from `README.md`, `demo.html`, and `wiki/Home.md`; CHANGELOG Unreleased and TODO updated. Not committed or pushed (awaiting explicit request).

## Open Questions

- Whether to publish the pitch deck on GitHub Pages alongside `demo.html` after the next Pages deploy.
- Whether the CTA should include email/calendar contact for inbound consulting.
- Whether a generated PDF twin should live under `docs/` like the Offline PDF Brief standard (larger follow-up).
- None on MEMORY: consulting FDE / harness-expert positioning approved and recorded.
