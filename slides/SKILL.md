---
name: slides
description: Convert a markdown slide-deck source file into a polished, self-contained HTML presentation or PDF. Use when the user asks to render, build, or generate slides from a markdown file, or says things like "turn this deck into HTML" or "compile slides.md". The markdown grammar is defined in this skill — author in small diffable chunks, get a magazine-quality single-file deck out.
metadata:
  version: "1.1.0"
  palette: "deep-blue-teal"
---

# slides — markdown to polished HTML / PDF decks

You turn a markdown source file into ONE self-contained HTML file (or a PDF rendered from that HTML) that looks hand-crafted, not templated. The reviewer is a senior engineer who hates AI slop. The output must pass the squint test: distinctive typography, intentional whitespace, no bullet walls, no emoji icons, no gradient text.

The default visual language is deep blue (`#1E3A8A`) + teal (`#0D9488`), slate neutrals, system-ui body / ui-monospace labels. Decks can render in **light** or **dark** mode (default: light). HTML output is **fully self-contained with no external assets** — it must render correctly in environments that block CDN scripts, remote fonts, and remote images (e.g., enterprise chat clients, airgapped networks, file attachments).

## Invocation

The user runs this skill with a markdown file path. Produce a single output file next to it (or at a path the user specifies):

- `slides.md` → `slides.html` (default)
- `slides.md --pdf` or an output path ending in `.pdf` → `slides.pdf` (see "PDF output" below)

Do not create any other files. If the user gives you `slides.md` without an output path, write to `slides.html` in the same directory and tell them the absolute path.

## Markdown grammar (v1 spec)

### Document frontmatter

YAML at the top of the file between `---` fences. Optional but recommended.

```yaml
---
title: Meridian Observatory Pipeline
subtitle: From photon to published catalog in 12 hours
author: Meridian Data Engineering
date: 2026-04-14
theme: light        # light (default) or dark
---
```

`title` becomes `<title>` and the first title-slide heading if no explicit title slide is defined. `subtitle`, `author`, `date` flow into the title slide if present. `theme` picks the palette variant (see "Themes" below).

### Slide separator

A line containing exactly `---` (three dashes) on its own, with blank lines before and after, separates slides. **Inside** a slide, never use `---` — use `***` for horizontal rules if you need one.

The document frontmatter's closing `---` does not count as a slide separator.

### Per-slide layout hint

The FIRST non-blank line of a slide may be an HTML comment:

```markdown
<!-- layout: content -->
```

Valid layouts: `title`, `divider`, `content`, `two-column`, `table`, `code`, `diagram`, `image`, `image-full`, `quote`, `references`.

If no hint is given, infer from content:
- Starts with H1 (`#`) and no other content → `title`
- Starts with H1 and has a subtitle line → `title`
- Single H2 with nothing else or a one-line subtitle → `divider`
- Contains a markdown table (`| ... |`) → `table`
- Contains a fenced ` ```mermaid ` block → `diagram`
- Contains a fenced code block (other language) → `code`
- Starts with `> ` (blockquote) → `quote`
- Has exactly two top-level sections separated by `***` → `two-column`
- Otherwise → `content`

Layout hints win over inference.

### Per-slide optional metadata

Additional HTML-comment directives on subsequent lines before the content:

```markdown
<!-- layout: content -->
<!-- label: The Problem -->
<!-- notes: Pause here. Ask the audience what breaks first. -->
```

- `label:` — small uppercase eyebrow above the heading.
- `notes:` — speaker notes. Emitted as `data-notes` on the slide. Not visible in v1.
- `bg:` — one of `default`, `tint`, `dark`. Controls slide background treatment.
- `number:` — override automatic slide number (for `divider` layout's big corner numeral).

### Layout-specific content rules

**title**
```markdown
<!-- layout: title -->
# Meridian
## From photon to published catalog in twelve hours
<!-- notes: Open with the March outage story. -->
```
- H1 → display type (huge). H2 → subtitle. Author/date pulled from frontmatter.

**divider**
```markdown
<!-- layout: divider -->
<!-- number: 02 -->
# Part Two: Pipeline rebuild, ground up
```
- Renders as full-bleed accent-tinted panel, massive slide number behind the heading.

**content**
```markdown
<!-- layout: content -->
<!-- label: The Problem -->
## A night of observations was taking nine days to reach astronomers

Every hour the array captures two terabytes of raw frames. For most of 2025, the gap between photons and a reviewable catalog was measured in weeks.

- Calibration ran on a single node with no retries
- Object detection depended on a twenty-year-old C binary
- Every failure required a human to re-queue the batch
- Astronomers were waiting, not observing
```
- H2 heading, optional lede paragraph, bullets. **Maximum 5 bullets, each ≤12 words** (see design rules). If more, split across slides.

**two-column**
```markdown
<!-- layout: two-column -->
<!-- label: Before vs After -->
## What changed at the architectural level

### Before
- Monolithic Python orchestrator
- Shared NFS for intermediate files
- Manual re-queue on every crash
- One astronomer on pager per night

***

### After
- Event-driven workers on Kubernetes
- Object storage with content addressing
- Automatic retries with dead-letter queue
- Pager duty is exception-only
```
- H2 headline, then two H3 sections separated by `***`.

**table**
```markdown
<!-- layout: table -->
<!-- label: Stage Budget -->
## Each stage has a latency SLO we actually hit

| Stage     | Input        | Output            | P95 latency | Owner     |
|-----------|--------------|-------------------|-------------|-----------|
| Ingest    | Raw FITS     | Content-addressed | 4 min       | Platform  |
| Calibrate | Raw frame    | Flat-fielded      | 12 min      | Photonics |
| Detect    | Calibrated   | Source list       | 22 min      | Detection |
| Catalog   | Source list  | Catalog rows      | 8 min       | Catalog   |
| Publish   | Catalog rows | API + mirror      | 2 min       | Platform  |
```
- Zebra-striped, sticky header, teal left-border accent, mono cells.

**code**
```markdown
<!-- layout: code -->
## Ingest worker entry point

` ``go
func main() {
    srv := server.New()
    srv.ListenAndServe()
}
` ``
```
- Dark code block (`#0f172a`), highlight.js colorization, filename/language label chip.

**diagram**
```markdown
<!-- layout: diagram -->
## Stages communicate through a single event bus

` ``mermaid
graph LR
  Telescope --> Ingest --> Bus --> Calibrate --> Publish
` ``
```
- Mermaid renders client-side with neutral theme (see Mermaid config below).

**image / image-full**
```markdown
<!-- layout: image -->
## Current dashboard

![Pipeline health dashboard](./screenshots/dashboard.png)

*Latency per stage over the last 24 hours*
```
- `image` = padded with 5% margin. `image-full` = edge-to-edge. Trailing italic line becomes the caption. **Every image must have alt text** — enforce this in the checklist.

**quote**
```markdown
<!-- layout: quote -->
> Every failure should retry itself before paging a human.

— Meridian operating principle
```
- Large pull quote, serif-weight display, attribution in mono.

**references**
```markdown
<!-- layout: references -->
## References

- **Meridian SRE runbook 2026-Q1** — Internal incident retrospectives and latency targets.
- **Event-driven architecture (Fowler, 2017)** — Informed the broker topology. <https://martinfowler.com/articles/201701-event-driven.html>
- **Content-addressed storage for scientific data (IVOA, 2023)** — Model for intermediate artifact handling.
```
- 3-column CSS grid, small type, bold title, muted URL on its own line.

## Rendering algorithm

Follow these steps exactly when the skill is invoked.

1. **Read the source file.** Parse YAML frontmatter (if present) and everything after it as the slide body.
2. **Split into slides.** Walk the body. A slide boundary is a line that matches `^---\s*$` AND has a blank line before and after it. The first slide is everything from the start of the body to the first boundary.
3. **For each slide:**
   a. Extract leading `<!-- ... -->` directive comments into a metadata object.
   b. If no explicit `layout:` directive, run the inference rules above.
   c. Validate the slide against the layout's density budget (see design rules).
   d. If the slide violates the budget, split it into two slides with a `(cont.)` suffix on the heading, OR raise a warning in a comment inside the HTML. Prefer splitting.
4. **Emit the HTML skeleton** with the inline `<style>` block from this skill, the deck chrome (progress bar, dots, counter), and one `<section class="slide slide--{layout}">` per slide.
5. **Inside each section**, render the slide body according to its layout template (see templates below).
6. **Run the design-review checklist** on your own output. If any check fails, fix it before returning.
7. **Write the file**, print the absolute path, and stop. Do not open a browser; do not preview; do not run it on any real project deck.

## PDF output (optional path)

When the user asks for a PDF — either by passing an output path ending in `.pdf`, passing `--pdf`, or saying "render as PDF" / "generate a PDF" — render the HTML first, then print it to PDF via headless Chrome. Do **not** skip the HTML step; the PDF is generated *from* the HTML, not in place of it.

### Steps

1. **Render HTML as normal.** Run the full rendering algorithm above to produce `<source>.html` (or a temp file in the same directory if the user only asked for `.pdf`). Always write the HTML; the PDF job depends on it being a real file on disk so Chrome can load it via `file://`.

2. **Locate a headless Chrome binary.** Try these paths in order, using the first one that exists (check with `ls`):
   - `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` (macOS)
   - `/Applications/Chromium.app/Contents/MacOS/Chromium` (macOS)
   - `/usr/bin/google-chrome` (Linux)
   - `/usr/bin/chromium` (Linux)
   - `which chrome || which chromium || which google-chrome-stable` (fallback)

3. **Invoke headless Chrome to print to PDF.** Use the Bash tool with an invocation shaped like:
   ```bash
   "<chrome>" \
     --headless=new \
     --disable-gpu \
     --no-margins \
     --no-pdf-header-footer \
     --virtual-time-budget=10000 \
     --run-all-compositor-stages-before-draw \
     --hide-scrollbars \
     --print-to-pdf-no-header \
     --print-to-pdf="<absolute output path>.pdf" \
     "file://<absolute path to rendered html>"
   ```
   `--virtual-time-budget=10000` gives mermaid + highlight.js time to finish rendering before the snapshot. `--no-margins` + `--no-pdf-header-footer` + `--print-to-pdf-no-header` strip the default Chrome header/footer. The resulting PDF has one landscape page per slide because the inline `@media print` block sets `@page{size:landscape;margin:0}` and `page-break-after:always` on every `.slide`.

4. **Verify the PDF exists** (`ls -la` the output path) and print both absolute paths (HTML and PDF) to the user.

### Fallback: Playwright MCP

If no Chrome binary is available but the Playwright MCP server (`mcp__plugin_playwright_playwright__*`) is loaded, use it as a secondary path:
1. `browser_navigate` → `file://<path to html>`.
2. `browser_resize` → `{width: 1600, height: 900}`.
3. `browser_wait_for` on a short text fragment from the final slide's heading (or a 1s delay) so mermaid finishes.
4. `browser_evaluate` with `() => document.querySelectorAll('.slide').forEach(s => s.classList.add('visible'))` so reveal animations are already settled.
5. `browser_take_screenshot` per slide at 1600×900, then assemble into a PDF via ImageMagick: `convert slide-*.png output.pdf`. This is a pixel-fidelity path, not a vector print — prefer headless Chrome when both are available.

### If neither is available

Degrade gracefully: emit the HTML as usual and tell the user:

> PDF export needs either a local Chrome/Chromium binary or the Playwright MCP server. Neither was found. HTML rendered to `<path>` — use `Ctrl+P → Save as PDF` in a browser for a local PDF.

Do **not** silently succeed with only HTML when a PDF was requested. The user asked for a PDF; tell them why they didn't get one.

### Notes

- The inline `@media print` block already hides deck chrome (progress bar, dots, counter, hints) and forces `-webkit-print-color-adjust:exact` on coloured slides, so the printed output keeps the dark navy backgrounds on divider/title/table-header slides.
- Dark-mode decks (`theme: dark` in frontmatter) produce dark-background PDFs. This is intended — do not force-flip to light for printing.
- The PDF's page size follows the printed viewport. 16:9 landscape is the target; the `@page{size:landscape}` rule handles this for Chrome.

## Design rules (non-negotiable)

These are constraints the rendered output MUST satisfy. Check them in step 6.

### Typography
- Body: `-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif` (system stack — no external fonts).
- Mono / labels: `ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace`.
- Display (title): `clamp(56px, 9vw, 96px)`, weight 800, letter-spacing -2px, line-height 0.95.
- H2 (content heading): `clamp(28px, 4vw, 44px)`, weight 700, letter-spacing -0.5px.
- Body: `clamp(15px, 1.8vw, 19px)`, line-height 1.55.
- Captions / labels: `clamp(10px, 1vw, 12px)`, uppercase, letter-spacing 1.5px.
- Never use gradient text. Never use Inter or Roboto.

### Color (fixed palette, theme-aware)

**Brand** — same in both themes:
- `--gf-blue: #1E3A8A` — divider background, table header, eyebrow accent.
- `--gf-blue-dark: #172554` — hover / deepest surfaces.
- `--gf-teal: #0D9488` — accent, left borders, hairlines, mermaid secondary.
- `--amber-600: #d97706` — warning indicator only.
- `--rose-600: #dc2626` — error indicator only.

**Role vars** — flip between light (default) and dark via `theme:` in frontmatter. The CSS sets the light values in `:root` and dark overrides in `[data-theme="dark"]`:

| Role            | Light      | Dark       | Used for                    |
|-----------------|------------|------------|-----------------------------|
| `--bg`          | `#ffffff`  | `#0b1220`  | page background             |
| `--fg`          | `#0f172a`  | `#f1f5f9`  | primary text                |
| `--fg-muted`    | `#334155`  | `#cbd5e1`  | body paragraphs, bullets    |
| `--fg-dim`      | `#64748b`  | `#94a3b8`  | captions, meta, muted URLs  |
| `--surface`     | `#f8fafc`  | `#111a2e`  | zebra rows, subtle panels   |
| `--surface-alt` | `#f1f5f9`  | `#0f172a`  | code inline bg, table code  |
| `--border`      | `#e2e8f0`  | `#1e293b`  | hairlines, borders          |
| `--heading`     | `#0f172a`  | `#f1f5f9`  | h2 color, strong text       |
| `--display`     | `#1E3A8A`  | `#60a5fa`  | title-slide display heading |

No red except errors. No violet. No gradient meshes. Divider slides (`--gf-blue` bg + white text) and the code block (`#0f172a` bg + `#e2e8f0` text) stay visually dark in both themes — they're already high-contrast.

### Layout
- Every slide is exactly one viewport tall (`height: 100dvh`), no inner scroll.
- `title` slides: centered, generous top/bottom margin, 1px teal hairline 40px below the display title (width: 80px, `background: var(--gf-teal)`). Background is a theme-aware gradient using `--surface` / `--bg` / `--surface-alt`.
- `divider`: full-bleed `var(--gf-blue)` background, white text, massive slide number top-right at `font-size: clamp(120px, 22vw, 260px); opacity: 0.08`. Unchanged between themes.
- `content` with ≥3 bullets and a label: two-column grid `grid-template-columns: minmax(0, 0.45fr) minmax(0, 0.55fr)` — left = label + heading + lede, right = bullets. Fewer than 3 bullets: single column, left-margin generous.
- `table`: max width 1100px, `thead` background `var(--gf-blue)`, white text, sticky. Zebra with `var(--surface)` even rows. Left border on every row: `border-left: 3px solid var(--gf-teal)`.
- `code`: dark `#0f172a` background, `#e2e8f0` body text (always dark regardless of theme), `ui-monospace` stack, highlight.js coloring. Tiny filename/language chip above the block in teal.
- `diagram`: centered mermaid, 80% max-width, teal caption above. Mermaid init uses theme-aware colors (see engine block).
- `image`: 5% horizontal padding. `image-full`: edge-to-edge. Caption in muted mono below.
- `quote`: centered, serif-weight body, thin teal vertical rule on the left (4px), attribution in uppercase mono.
- `references`: `grid-template-columns: repeat(3, 1fr); gap: 32px`. Entry font-size 13px. Title bold, URL wrapped, muted.

### Density budget (enforced)
- **content**: max 5 bullets, each ≤12 words, plus max 1 lede paragraph.
- **two-column**: max 4 bullets per column.
- **table**: max 8 data rows, max 5 columns. Over budget → split.
- **references**: max 9 entries (3 columns × 3 rows).
- **title heading**: ≤60 characters.
- **divider heading**: ≤50 characters.
- **image**: the image never exceeds `calc(100vh - 300px)` in height and `92%` in width. The renderer must confirm this in the output — compute `getBoundingClientRect()` on the `<img>` and its parent `.slide` and assert the image fits. Using plain `72vh` or similar ignores the space needed for label + heading + caption + padding and causes the image to overflow the slide on any normal viewport.

### Forbidden
- No emoji icons. No Font Awesome. No stock clip-art.
- No gradient text (`background-clip: text`).
- No glowing `box-shadow` animations.
- No rounded corners over 12px (industrial feel, not playful).
- No drop-shadow clouds — use thin 1px `var(--border)` hairlines for depth instead.
- No more than 5 bullets on any content slide.
- No headings over 60 characters.

## The inline `<style>` block

Every output HTML file embeds this exact stylesheet (compactly — remove newlines/spaces the browser doesn't need if you need to save tokens, but keep it readable in the source). Substitute values only where marked with `{{...}}`.

```css
:root{
  --font-body:-apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,sans-serif;
  --font-mono:ui-monospace,"SF Mono",Menlo,Consolas,"Liberation Mono",monospace;
  /* brand — identical in both themes */
  --gf-blue:#1E3A8A;--gf-blue-dark:#172554;
  --gf-teal:#0D9488;--gf-teal-dim:rgba(13,148,136,0.08);
  --amber-600:#d97706;--rose-600:#dc2626;
  /* role vars — LIGHT theme defaults */
  --bg:#ffffff;
  --fg:#0f172a;
  --fg-muted:#334155;
  --fg-dim:#64748b;
  --surface:#f8fafc;
  --surface-alt:#f1f5f9;
  --border:#e2e8f0;
  --heading:#0f172a;
  --display:#1E3A8A;
  --title-grad-a:#f8fafc;
  --title-grad-b:#ffffff;
  --title-grad-c:#f1f5f9;
  --title-wash-a:rgba(30,58,138,.04);
  --title-wash-b:rgba(13,148,136,.04);
}
[data-theme="dark"]{
  --bg:#0b1220;
  --fg:#f1f5f9;
  --fg-muted:#cbd5e1;
  --fg-dim:#94a3b8;
  --surface:#111a2e;
  --surface-alt:#0f172a;
  --border:#1e293b;
  --heading:#f1f5f9;
  --display:#60a5fa;
  --title-grad-a:#0b1220;
  --title-grad-b:#111a2e;
  --title-grad-c:#0b1220;
  --title-wash-a:rgba(96,165,250,.08);
  --title-wash-b:rgba(13,148,136,.10);
  --gf-teal-dim:rgba(13,148,136,0.14);
}
*{margin:0;padding:0;box-sizing:border-box}
html,body{background:var(--bg);color:var(--fg);font-family:var(--font-body);-webkit-font-smoothing:antialiased}
body{overflow:hidden}
.deck{height:100dvh;overflow-y:auto;scroll-snap-type:y mandatory;scroll-behavior:smooth}
.slide{height:100dvh;scroll-snap-align:start;position:relative;display:flex;flex-direction:column;justify-content:center;padding:clamp(40px,6vh,80px) clamp(48px,8vw,120px);overflow:hidden;opacity:0;transform:translateY(16px);transition:opacity .45s cubic-bezier(.16,1,.3,1),transform .45s cubic-bezier(.16,1,.3,1)}
.slide.visible{opacity:1;transform:none}
.slide .reveal{opacity:0;transform:translateY(10px);transition:opacity .4s cubic-bezier(.16,1,.3,1),transform .4s cubic-bezier(.16,1,.3,1)}
.slide.visible .reveal{opacity:1;transform:none}
.slide.visible .reveal:nth-child(1){transition-delay:.08s}
.slide.visible .reveal:nth-child(2){transition-delay:.14s}
.slide.visible .reveal:nth-child(3){transition-delay:.2s}
.slide.visible .reveal:nth-child(4){transition-delay:.26s}
.slide.visible .reveal:nth-child(5){transition-delay:.32s}
.slide.visible .reveal:nth-child(6){transition-delay:.38s}
@media(prefers-reduced-motion:reduce){.slide,.slide .reveal{opacity:1!important;transform:none!important;transition:none!important}}

/* chrome */
.deck-progress{position:fixed;top:0;left:0;height:3px;background:var(--gf-teal);z-index:100;transition:width .3s;pointer-events:none}
.deck-dots{position:fixed;right:clamp(10px,1.5vw,20px);top:50%;transform:translateY(-50%);display:flex;flex-direction:column;gap:7px;z-index:100}
.deck-dot{width:7px;height:7px;border-radius:50%;background:var(--fg-dim);opacity:.25;border:none;padding:0;cursor:pointer;transition:all .2s}
.deck-dot:hover{opacity:.55}
.deck-dot.active{opacity:1;transform:scale(1.6);background:var(--gf-teal)}
.deck-counter{position:fixed;bottom:clamp(12px,2vh,20px);right:clamp(12px,2vw,22px);font-family:var(--font-mono);font-size:11px;color:var(--fg-dim);z-index:100;font-variant-numeric:tabular-nums}
.deck-hints{position:fixed;bottom:clamp(12px,2vh,20px);left:50%;transform:translateX(-50%);font-family:var(--font-mono);font-size:10px;color:var(--fg-dim);opacity:.55;z-index:100;transition:opacity .5s;white-space:nowrap;letter-spacing:.5px}
.deck-hints.faded{opacity:0;pointer-events:none}

/* shared */
.slide__eyebrow{font-family:var(--font-mono);font-size:clamp(10px,1vw,12px);font-weight:600;text-transform:uppercase;letter-spacing:1.8px;color:var(--gf-teal);margin-bottom:14px}
.slide__heading{font-size:clamp(28px,4vw,44px);font-weight:700;letter-spacing:-.5px;line-height:1.15;color:var(--heading);text-wrap:balance}
.slide__lede{font-size:clamp(15px,1.8vw,19px);line-height:1.55;color:var(--fg-muted);margin-top:18px;max-width:64ch;text-wrap:pretty}
.slide__bullets{list-style:none;padding:0;margin-top:22px}
.slide__bullets li{position:relative;padding-left:26px;margin-bottom:14px;font-size:clamp(14px,1.7vw,18px);line-height:1.5;color:var(--fg-muted)}
.slide__bullets li::before{content:"";position:absolute;left:0;top:11px;width:14px;height:2px;background:var(--gf-teal)}
.slide__bullets li strong{color:var(--heading);font-weight:600}

/* title */
.slide--title{align-items:center;text-align:center;background:linear-gradient(180deg,var(--title-grad-a) 0%,var(--title-grad-b) 55%,var(--title-grad-c) 100%)}
.slide--title::after{content:"";position:absolute;inset:0;background:radial-gradient(ellipse at 30% 20%,var(--title-wash-a),transparent 55%),radial-gradient(ellipse at 75% 80%,var(--title-wash-b),transparent 55%);pointer-events:none}
.slide--title .slide__kicker{font-family:var(--font-mono);font-size:clamp(11px,1.2vw,14px);color:var(--display);letter-spacing:2.5px;text-transform:uppercase;margin-bottom:28px}
.slide--title .slide__display{font-size:clamp(56px,9vw,96px);font-weight:800;letter-spacing:-2px;line-height:.95;color:var(--display);text-wrap:balance}
.slide--title .slide__rule{width:80px;height:1px;background:var(--gf-teal);margin:36px auto 36px}
.slide--title .slide__subtitle{font-size:clamp(16px,2vw,22px);color:var(--fg-muted);font-weight:400;text-wrap:balance;max-width:36ch}
.slide--title .slide__meta{font-family:var(--font-mono);font-size:12px;color:var(--fg-dim);margin-top:44px;letter-spacing:.5px}

/* divider — always high-contrast navy + white, both themes */
.slide--divider{background:var(--gf-blue);color:#ffffff;justify-content:center}
.slide--divider::before{content:attr(data-num);position:absolute;top:clamp(24px,5vh,60px);right:clamp(32px,6vw,90px);font-family:var(--font-mono);font-size:clamp(120px,22vw,260px);font-weight:200;line-height:.85;color:#ffffff;opacity:.07;font-variant-numeric:tabular-nums;pointer-events:none}
.slide--divider .slide__eyebrow{color:rgba(255,255,255,.65)}
.slide--divider .slide__heading{color:#ffffff;font-size:clamp(36px,5.5vw,64px);max-width:20ch}
.slide--divider .slide__lede{color:rgba(255,255,255,.75)}

/* content */
.slide--content .slide__inner{width:100%;max-width:1180px;margin:0 auto}
.slide--content.has-sidebar .slide__inner{display:grid;grid-template-columns:minmax(0,.42fr) minmax(0,.58fr);gap:clamp(32px,5vw,72px);align-items:start}

/* two-column */
.slide--two-column .slide__inner{width:100%;max-width:1200px;margin:0 auto}
.slide--two-column .slide__pair{display:grid;grid-template-columns:1fr 1fr;gap:clamp(32px,5vw,64px);margin-top:28px}
.slide--two-column .slide__col h3{font-size:clamp(14px,1.5vw,17px);font-family:var(--font-mono);text-transform:uppercase;letter-spacing:1.5px;color:var(--gf-teal);margin-bottom:16px;padding-bottom:10px;border-bottom:1px solid var(--border)}

/* table */
.slide--table .slide__inner{width:100%;max-width:1150px;margin:0 auto}
.slide--table table{width:100%;border-collapse:collapse;margin-top:22px;font-size:clamp(12px,1.4vw,15px);background:var(--bg);border:1px solid var(--border);border-radius:6px;overflow:hidden;font-variant-numeric:tabular-nums}
.slide--table thead{background:var(--gf-blue)}
.slide--table th{text-align:left;padding:14px 18px;font-weight:600;font-size:clamp(10px,1.1vw,12px);text-transform:uppercase;letter-spacing:1.2px;color:#ffffff;white-space:nowrap}
.slide--table tbody tr{border-left:3px solid var(--gf-teal)}
.slide--table tbody tr:nth-child(even){background:var(--surface)}
.slide--table td{padding:13px 18px;border-top:1px solid var(--border);color:var(--fg-muted);vertical-align:top}
.slide--table td strong{color:var(--heading);font-weight:600}
.slide--table td code,.slide--table th code{font-family:var(--font-mono);font-size:.9em;background:var(--surface-alt);padding:2px 6px;border-radius:3px;color:var(--heading)}

/* code — always dark, both themes */
.slide--code .slide__inner{width:100%;max-width:1100px;margin:0 auto}
.slide--code .code-chip{display:inline-block;font-family:var(--font-mono);font-size:11px;text-transform:uppercase;letter-spacing:1.5px;color:var(--gf-teal);padding:4px 10px;border:1px solid var(--border);border-radius:999px;margin-bottom:14px;background:var(--bg)}
.slide--code pre{background:#0f172a;color:#e2e8f0;border-radius:8px;padding:24px 28px;font-family:var(--font-mono);font-size:clamp(12px,1.4vw,15px);line-height:1.6;overflow:auto;border:1px solid var(--border)}
.slide--code pre code{font-family:inherit;background:none;padding:0}
.hljs-keyword,.hljs-selector-tag,.hljs-built_in{color:#5eead4}
.hljs-string,.hljs-attr{color:#fde68a}
.hljs-number,.hljs-literal{color:#93c5fd}
.hljs-comment{color:#64748b;font-style:italic}
.hljs-function,.hljs-title{color:#a5b4fc}

/* diagram */
.slide--diagram .slide__inner{width:100%;max-width:1200px;margin:0 auto;display:flex;flex-direction:column;align-items:center}
.slide--diagram .mermaid{width:100%;max-width:1000px;display:flex;justify-content:center}
.slide--diagram .mermaid svg{max-width:100%;height:auto;max-height:65vh}

/* image — the image must leave room for label + heading + caption + slide padding,
   so max-height is computed from viewport minus a 300px chrome budget. object-fit:contain
   preserves aspect ratio and prevents distortion. Do NOT use plain 72vh — that overflows
   the slide on any viewport with normal chrome. */
.slide--image .slide__inner,.slide--image-full .slide__inner{width:100%;display:flex;flex-direction:column;align-items:center;gap:14px}
.slide--image .slide__inner>*{flex-shrink:0}
.slide--image img{display:block;max-width:92%;width:auto;height:auto;max-height:calc(100vh - 300px);object-fit:contain;border:1px solid var(--border);border-radius:6px}
.slide--image-full{padding:0}
.slide--image-full img{display:block;width:100vw;height:100vh;object-fit:cover}
.slide--image .slide__caption,.slide--image-full .slide__caption{font-family:var(--font-mono);font-size:12px;color:var(--fg-dim);text-transform:uppercase;letter-spacing:1.2px;text-align:center;max-width:80%}

/* quote */
.slide--quote{justify-content:center;align-items:center;text-align:center}
.slide--quote blockquote{position:relative;max-width:28ch;font-size:clamp(28px,4.5vw,48px);line-height:1.25;font-weight:500;color:var(--heading);letter-spacing:-.5px;padding-left:32px;border-left:4px solid var(--gf-teal);text-align:left;text-wrap:balance}
.slide--quote cite{display:block;margin-top:28px;font-family:var(--font-mono);font-size:12px;color:var(--fg-dim);text-transform:uppercase;letter-spacing:2px;font-style:normal}

/* references */
.slide--references .slide__inner{width:100%;max-width:1200px;margin:0 auto}
.slide--references .ref-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:28px 36px;margin-top:24px}
.slide--references .ref{font-size:13px;line-height:1.5;color:var(--fg-muted);padding-top:10px;border-top:1px solid var(--border)}
.slide--references .ref strong{display:block;color:var(--heading);font-weight:600;margin-bottom:4px}
.slide--references .ref a,.slide--references .ref code.url{font-family:var(--font-mono);font-size:11px;color:var(--fg-dim);word-break:break-all;text-decoration:none}

/* print */
@media print{
  @page{size:landscape;margin:0}
  body{overflow:visible;background:var(--bg)}
  .deck{height:auto;overflow:visible;scroll-snap-type:none}
  .slide{height:100vh;min-height:100vh;page-break-after:always;page-break-inside:avoid;opacity:1!important;transform:none!important}
  .slide .reveal{opacity:1!important;transform:none!important}
  .deck-progress,.deck-dots,.deck-counter,.deck-hints{display:none!important}
  .slide--divider,.slide--title,.slide--table thead{-webkit-print-color-adjust:exact;print-color-adjust:exact}
}
```

## Portability constraint — everything must be inline

**The output HTML must be fully self-contained.** No CDN references, no external stylesheets, no external images, no external fonts. Decks are often shared in environments where CDN script tags, Google Fonts, and remote images are blocked or stripped (enterprise chat clients, airgapped networks, email attachments). Violation of this rule makes the skill useless for its primary use case.

Three things get inlined at render time:

1. **`vendor/mermaid.min.js`** — vendored at `~/.claude/skills/slides/vendor/mermaid.min.js` (~3 MB). Read it with the Read tool, wrap in a `<script>...</script>` tag, and inject it into the HTML head. Do NOT import mermaid from jsDelivr.
2. **`vendor/highlight.min.js`** — vendored at `~/.claude/skills/slides/vendor/highlight.min.js` (~125 KB). Same pattern. Do NOT fetch from jsDelivr.
3. **Every `<img>` source** — read the image from disk via Bash `base64 -i <path>`, wrap as `data:image/<ext>;base64,<output>`, emit as the `src` attribute. No external image URLs. If a local image path is missing, emit a visible caption `(image not found: {path})` and a small placeholder SVG inline — do not leave a broken link.
4. **Fonts** — NO Google Fonts import. Use a system font stack:
   - UI: `-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif`
   - Mono: `ui-monospace, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace`
   - This gives Segoe UI on Windows, SF on macOS, and Liberation on Linux — all legible and familiar, no FOUT.

## The inline `<script>` block (deck engine)

The skill's render step must concatenate three pieces inside `<body>` at the end:

1. `<script>` + contents of `~/.claude/skills/slides/vendor/mermaid.min.js` + `</script>`
2. A short `<script>` that calls `mermaid.initialize({...})` with the deck palette (light or dark, matching the active theme)
3. `<script>` + contents of `~/.claude/skills/slides/vendor/highlight.min.js` + `</script>`
4. A short `<script>` that runs `hljs.highlightElement` on every `pre code`
5. The deck-navigation script (keyboard + progress bar + dot nav)

The initialization / navigation block (the only hand-written JS):

```html
<script>
  if(window.mermaid){
    var isDark=document.documentElement.getAttribute('data-theme')==='dark';
    window.mermaid.initialize({
      startOnLoad:true, theme:'base', securityLevel:'loose',
      themeVariables: isDark ? {
        primaryColor:'#111a2e', primaryBorderColor:'#60a5fa', primaryTextColor:'#f1f5f9',
        secondaryColor:'#0f172a', secondaryBorderColor:'#0D9488', secondaryTextColor:'#f1f5f9',
        tertiaryColor:'#0b1220', tertiaryBorderColor:'#94a3b8', tertiaryTextColor:'#cbd5e1',
        lineColor:'#94a3b8', fontSize:'16px',
        fontFamily:'-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif'
      } : {
        primaryColor:'#ffffff', primaryBorderColor:'#1E3A8A', primaryTextColor:'#0f172a',
        secondaryColor:'#f1f5f9', secondaryBorderColor:'#0D9488', secondaryTextColor:'#0f172a',
        tertiaryColor:'#f8fafc', tertiaryBorderColor:'#64748b', tertiaryTextColor:'#334155',
        lineColor:'#64748b', fontSize:'16px',
        fontFamily:'-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif'
      }
    });
  }
  if(window.hljs){document.querySelectorAll('pre code').forEach(function(el){try{hljs.highlightElement(el);}catch(e){}});}
  (function(){
    var deck=document.querySelector('.deck');
    var slides=[].slice.call(document.querySelectorAll('.slide'));
    var bar=document.createElement('div');bar.className='deck-progress';document.body.appendChild(bar);
    var dots=document.createElement('div');dots.className='deck-dots';
    slides.forEach(function(_,i){var d=document.createElement('button');d.className='deck-dot';d.title='Slide '+(i+1);d.onclick=function(){slides[i].scrollIntoView({behavior:'smooth'});};dots.appendChild(d);});
    document.body.appendChild(dots);
    var dotEls=[].slice.call(dots.children);
    var counter=document.createElement('div');counter.className='deck-counter';document.body.appendChild(counter);
    var hints=document.createElement('div');hints.className='deck-hints';hints.textContent='\u2190 \u2192  space  scroll  to navigate';document.body.appendChild(hints);
    setTimeout(function(){hints.classList.add('faded');},4000);
    var current=0;
    function update(){bar.style.width=((current+1)/slides.length*100)+'%';dotEls.forEach(function(d,i){d.classList.toggle('active',i===current);});counter.textContent=(current+1)+' / '+slides.length;}
    var obs=new IntersectionObserver(function(entries){entries.forEach(function(e){if(e.isIntersecting){e.target.classList.add('visible');current=slides.indexOf(e.target);update();}});},{threshold:.5});
    slides.forEach(function(s){obs.observe(s);});
    function go(i){slides[Math.max(0,Math.min(i,slides.length-1))].scrollIntoView({behavior:'smooth'});}
    document.addEventListener('keydown',function(e){
      if(e.target.closest('input,textarea,[contenteditable]'))return;
      if(['ArrowDown','ArrowRight',' ','PageDown'].indexOf(e.key)>-1){e.preventDefault();go(current+1);}
      else if(['ArrowUp','ArrowLeft','PageUp'].indexOf(e.key)>-1){e.preventDefault();go(current-1);}
      else if(e.key==='Home'){e.preventDefault();go(0);}
      else if(e.key==='End'){e.preventDefault();go(slides.length-1);}
      hints.classList.add('faded');
    });
    var tY=0;
    deck.addEventListener('touchstart',function(e){tY=e.touches[0].clientY;},{passive:true});
    deck.addEventListener('touchend',function(e){var dy=tY-e.changedTouches[0].clientY;if(Math.abs(dy)>50){go(current+(dy>0?1:-1));}});
    update();
  })();
</script>
```

Highlight.js CSS classes are styled directly in the main stylesheet above (see the `.hljs-*` block). No external theme stylesheet needed.

## Slide templates (what to emit)

Each template takes parsed slide data `{layout, label, heading, subtitle, body, bullets, notes, table, code, mermaid, image, quote, attribution, references, number}` and emits HTML. Wrap the `section` element with `data-notes="{escaped notes}"` if notes are present.

**title**
```html
<section class="slide slide--title"{{#notes}} data-notes="{{notes}}"{{/notes}}>
  <div class="slide__inner" style="display:flex;flex-direction:column;align-items:center">
    {{#kicker}}<div class="slide__kicker reveal">{{kicker}}</div>{{/kicker}}
    <h1 class="slide__display reveal">{{heading}}</h1>
    <div class="slide__rule reveal"></div>
    {{#subtitle}}<p class="slide__subtitle reveal">{{subtitle}}</p>{{/subtitle}}
    {{#meta}}<p class="slide__meta reveal">{{meta}}</p>{{/meta}}
  </div>
</section>
```
`kicker` = document `author` or project name; `meta` = `date` from frontmatter.

**divider**
```html
<section class="slide slide--divider" data-num="{{number}}">
  {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
  <h2 class="slide__heading reveal">{{heading}}</h2>
  {{#lede}}<p class="slide__lede reveal">{{lede}}</p>{{/lede}}
</section>
```

**content** (with sidebar variant when ≥3 bullets + label + heading)
```html
<section class="slide slide--content has-sidebar">
  <div class="slide__inner">
    <div>
      {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
      <h2 class="slide__heading reveal">{{heading}}</h2>
      {{#lede}}<p class="slide__lede reveal">{{lede}}</p>{{/lede}}
    </div>
    <div>
      <ul class="slide__bullets reveal">{{#bullets}}<li>{{.}}</li>{{/bullets}}</ul>
    </div>
  </div>
</section>
```

**two-column**
```html
<section class="slide slide--two-column">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    <h2 class="slide__heading reveal">{{heading}}</h2>
    <div class="slide__pair reveal">
      <div class="slide__col"><h3>{{left.title}}</h3><ul class="slide__bullets">{{left.bullets}}</ul></div>
      <div class="slide__col"><h3>{{right.title}}</h3><ul class="slide__bullets">{{right.bullets}}</ul></div>
    </div>
  </div>
</section>
```

**table**
```html
<section class="slide slide--table">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    <h2 class="slide__heading reveal">{{heading}}</h2>
    <table class="reveal"><thead><tr>{{headers→th}}</tr></thead><tbody>{{rows→tr/td}}</tbody></table>
  </div>
</section>
```

**code**
```html
<section class="slide slide--code">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    <h2 class="slide__heading reveal">{{heading}}</h2>
    <span class="code-chip reveal">{{language}}{{#filename}} · {{filename}}{{/filename}}</span>
    <pre class="reveal"><code class="language-{{language}}">{{escaped code}}</code></pre>
  </div>
</section>
```

**diagram**
```html
<section class="slide slide--diagram">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    <h2 class="slide__heading reveal">{{heading}}</h2>
    <pre class="mermaid reveal">{{mermaid source}}</pre>
  </div>
</section>
```

**image** / **image-full**
```html
<section class="slide slide--image{{#full}}-full{{/full}}">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    {{#heading}}<h2 class="slide__heading reveal">{{heading}}</h2>{{/heading}}
    <img class="reveal" src="{{src}}" alt="{{alt}}">
    {{#caption}}<div class="slide__caption reveal">{{caption}}</div>{{/caption}}
  </div>
</section>
```

**quote**
```html
<section class="slide slide--quote">
  <blockquote class="reveal">{{text}}</blockquote>
  {{#attribution}}<cite class="reveal">— {{attribution}}</cite>{{/attribution}}
</section>
```

**references**
```html
<section class="slide slide--references">
  <div class="slide__inner">
    {{#label}}<div class="slide__eyebrow reveal">{{label}}</div>{{/label}}
    <h2 class="slide__heading reveal">{{heading}}</h2>
    <div class="ref-grid reveal">
      {{#each refs}}<div class="ref"><strong>{{title}}</strong>{{#description}}{{description}}{{/description}}{{#url}}<br><a href="{{url}}">{{url}}</a>{{/url}}</div>{{/each}}
    </div>
  </div>
</section>
```

## HTML skeleton

```html
<!DOCTYPE html>
<html lang="en" data-theme="{{frontmatter.theme|light}}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{frontmatter.title}}</title>
<style>{{the stylesheet from above}}</style>
</head>
<body>
<div class="deck">
{{each slide section, with every <img> src as a data: URI}}
</div>
<script>{{entire contents of ~/.claude/skills/slides/vendor/mermaid.min.js}}</script>
<script>{{entire contents of ~/.claude/skills/slides/vendor/highlight.min.js}}</script>
{{the initialization + deck-navigation script from above}}
</body>
</html>
```

`data-theme` is `"light"` (default) or `"dark"`, taken from the frontmatter `theme:` field. Any unrecognized value falls back to `"light"`. The attribute lives on `<html>` so CSS variable overrides in `[data-theme="dark"]` apply to the whole document, and the mermaid init script reads it with `document.documentElement.getAttribute('data-theme')`.

**No `<link>` tags. No `<script src="...">` tags. No external resources at all.** The only tags that ever load network content are the `<script>` blocks containing the vendored JS, and those are inline. Verify this in step 12 of the design-review checklist.

## Error handling

- **Missing layout hint, ambiguous content** → apply the inference rules, then fall back to `content`.
- **Malformed markdown table** (inconsistent columns) → emit the table as written and inject an HTML comment `<!-- WARN: table row N has M columns, expected K -->` inside the slide so the author sees it when viewing source.
- **Broken image path** → do not fail the render. Emit the `<img>` tag as-is and add a visible caption `(image not found: {path})` below. Do NOT synthesize a placeholder image.
- **Missing alt text on an image** → inject alt text from the caption if present, otherwise from the nearest heading. If neither exists, fail the checklist.
- **Empty slide** (no content after the separator) → skip with a warning comment in the HTML.
- **Density budget violated** → split the slide. Keep the same label on both halves. Append `(cont.)` to the second-half heading. Note the split with an HTML comment.
- **Unknown layout name** → fall back to `content` and emit `<!-- WARN: unknown layout '{name}', rendered as content -->`.
- **Mermaid parse error** → leave the source visible inside the `<pre class="mermaid">` and let mermaid show its own error in the browser. Do not try to fix the diagram source.
- **Code block with no language** → tag it `text` and skip highlight.js colorization for that block.

## Design-review checklist (run before returning)

Before writing the HTML file, walk through every slide and verify these conditions. If any fails, fix it.

1. Every slide has a layout class that matches one of the supported layouts.
2. No content slide has more than 5 bullets.
3. No bullet exceeds 12 words (tolerate up to 15 if wrapping a proper noun that can't be shortened).
4. No title-slide heading exceeds 60 characters.
5. No divider heading exceeds 50 characters.
6. Every `<img>` has a non-empty `alt` attribute **and** its CSS max-height is `calc(100vh - 300px)` or smaller. Test with Playwright at 1280×720: `slides[i].querySelector('img').getBoundingClientRect().height <= 720 - 300 = 420`. If any image exceeds the slide height, the CSS is wrong.
7. Every table has ≤8 rows and ≤5 columns.
8. No `background-clip: text`, no gradient text anywhere.
9. No emoji characters in rendered HTML text unless they were already in the source markdown.
10. Every reference slide entry has a bold title. URLs, if present, are on their own line in mono font.
11. The `<title>` tag matches the frontmatter title.
12. The file is fully self-contained. **No external `<link>` tags, no external `<script src="...">` tags, no CDN references at all.** Grep the output for `https://` — the only matches should be URLs in reference-slide content (user-provided links). If mermaid or highlight.js is referenced from a CDN, the render is invalid; re-inline from `~/.claude/skills/slides/vendor/`. Every `<img>` must have a `data:` URI or the image-not-found caption fallback.
13. `@media print` block is present and hides deck chrome.
14. `prefers-reduced-motion` block is present.
15. Speaker notes (if any) are emitted as `data-notes` on the slide and are HTML-escaped.

If a check fails, fix it in place and run the list again. Do not return until every check passes.

## Anti-AI-slop discipline

Before declaring done, do the squint test: if you blurred the screen, would you still see clear hierarchy, intentional whitespace, and distinct sections? If the deck would be indistinguishable from a generic Tailwind+Inter template with purple accents, regenerate the layout. The palette is fixed, but slide composition (left-heavy, right-heavy, centered, split) must vary between consecutive slides. Three centered slides in a row means push one off-center.

Never position any slide as "auto-generated." The reviewer is skeptical of AI work. The output has to read like a human designer made it, which means: committing to the constraints, respecting the density budget, and using the typography scale as a real hierarchy instead of "headings big, body smaller."
