# slides — markdown to polished HTML / PDF decks

User-level Claude Code skill. Converts a markdown slide-deck source file into one self-contained HTML presentation (or a PDF rendered from it). Default visual language: deep blue `#1E3A8A` + teal `#0D9488`, slate neutrals, system-ui body / ui-monospace labels. Supports light (default) and dark themes via frontmatter.

Author decks in small diffable markdown chunks instead of hand-written HTML.

## Files

- `SKILL.md` — the skill prompt: grammar, design rules, CSS block, deck engine JS, templates, error handling, design-review checklist.
- `example-input.md` — canonical example source, 8 slides exercising title / content / divider / two-column / table / diagram / references layouts.
- `example-output.html` — the rendered example. Open in a browser to see what the skill produces.
- `README.md` — this file.
- `vendor/` — pinned `mermaid.min.js` and `highlight.min.js` inlined into every rendered deck so the output has zero external dependencies.

## Invocation

From any Claude Code session:

```
/slides path/to/deck.md                 # writes deck.html next to the source
/slides path/to/deck.md deck.pdf        # writes the PDF (HTML is still generated first)
/slides path/to/deck.md --pdf           # same, PDF named after the source
```

Or conversationally: "render `deck.md` with the slides skill" / "compile this to a PDF" — the skill description matches either intent.

The skill writes the output next to the source (or at a path you specify) and prints the absolute path. It does not open the browser. To view locally:

```
open path/to/deck.html        # macOS
xdg-open path/to/deck.html    # Linux
```

## Markdown grammar in one glance

```
---                                  # document frontmatter (YAML)
title: ...
subtitle: ...
author: ...
date: ...
theme: light                          # light (default) or dark
---

<!-- layout: title -->
# Display heading
## Subtitle line

---                                   # slide separator (blank lines required around it)

<!-- layout: content -->
<!-- label: Section eyebrow -->
## Slide heading

Optional lede paragraph.

- Bullet one (max 5 bullets, each ≤12 words)
- Bullet two
- Bullet three
```

Supported layouts: `title`, `divider`, `content`, `two-column`, `table`, `code`, `diagram`, `image`, `image-full`, `quote`, `references`.

Speaker notes go in an HTML comment: `<!-- notes: ... -->` — rendered as `data-notes` on the slide element.

Full grammar, density budgets, role-var palette (light + dark), and the design-review checklist are in `SKILL.md`.

## Themes

Set `theme: light` (default) or `theme: dark` in frontmatter. The CSS uses role vars (`--bg`, `--fg`, `--surface`, `--heading`, `--display`, etc.) that flip between themes via `[data-theme="dark"]` on `<html>`. Divider slides, code blocks, and table headers stay high-contrast navy + white in both themes by design. Mermaid diagrams get theme-matched colors automatically.

## PDF output

When an output path ends in `.pdf` or `--pdf` is passed, the skill first renders the HTML as usual, then uses headless Chrome (`/Applications/Google Chrome.app/...` on macOS, `google-chrome` or `chromium` on Linux) to print to PDF via `--print-to-pdf`. One landscape page per slide, background colors preserved. Dark-mode decks produce dark-background PDFs.

If no Chrome binary is found, the skill falls back to the Playwright MCP server (screenshot-per-slide → `convert` into a PDF). If neither is available, it writes HTML only and tells you why.

## Design constraints (enforced by the skill)

- Max 5 bullets per content slide, each ≤12 words. Over budget → split or raise a warning.
- Title heading ≤60 chars, divider heading ≤50 chars.
- Tables ≤8 rows × 5 columns.
- Every image must have alt text.
- No gradient text, no emoji icons, no stock icons, no indigo/violet/pink accents.
- Fully self-contained output — no `<link>` tags, no external `<script src>`, no remote fonts, no remote images. Mermaid and highlight.js are inlined from `vendor/`. Every image becomes a `data:` URI.
- Print-clean: headless-Chrome PDF or `Ctrl+P → Save as PDF` both produce a usable handout.

## Keyboard navigation (in the rendered HTML deck)

- Arrow keys, Space, PageDown/PageUp — advance
- Home / End — jump to first / last slide
- Scroll wheel / touch-swipe — advance
- Click the right-edge dots to jump to a specific slide
