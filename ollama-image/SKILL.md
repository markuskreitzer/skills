---
name: ollama-image
description: Generate images locally with Ollama using the experimental image-generation models (x/z-image-turbo, x/flux2-klein). Use when the user asks to generate, draw, render, or make an image/picture/illustration locally, offline, or with Ollama — or explicitly names one of the supported models. Currently macOS only.
metadata:
  version: "0.1.0"
  status: beta
---

# ollama-image — local image generation via Ollama

You generate images on the user's machine with Ollama's experimental image-generation models. The output is one or more PNG files written to the current working directory.

## When to use this skill

- "Generate an image of …", "draw …", "make a picture of …", "render …"
- User explicitly asks for **local** / **offline** / **on-device** image generation
- User mentions Ollama image generation, `z-image-turbo`, `flux2-klein`, Z-Image, or FLUX.2 Klein
- User wants zero-cost iteration on prompts without hitting a cloud API

Do **not** use this skill for:

- Generating diagrams or visualizations from structured data — use `visual-explainer` or `generate-web-diagram` instead.
- Editing existing images, upscaling, or inpainting — these models are text-to-image only.

## Prerequisites (verify once per session)

1. **Platform**: `uname` should report `Darwin`. Ollama image generation is macOS-only during beta; Windows/Linux are not supported yet. If the user is on another OS, stop and tell them.
2. **Ollama installed**: run `ollama --version`. If missing, tell the user to install from https://ollama.com/download and stop.
3. **Model pulled**: the first `ollama run` of a model will download it (multi-GB). Warn the user before kicking off a large pull. You can list local models with `ollama list`.

## The two models

| Model | Params | Strengths | Pick when |
|---|---|---|---|
| `x/z-image-turbo` | 6B | Photorealistic output, fast, bilingual text rendering (English + Chinese) | Default choice. Photos, scenes, portraits, product shots, anything where you want a real-looking image quickly. |
| `x/flux2-klein` | 4B / 9B | Strong, legible in-image text; good for UI mockups, posters, signage, typography-heavy compositions | The prompt includes readable text, a logo, a UI mock, a poster, a sign, or anything where typography has to land correctly. |

If the user doesn't specify, pick based on the prompt: text/UI/typography → flux2-klein, everything else → z-image-turbo. State your pick in one short sentence so the user can redirect.

## Running the models

### Non-interactive (what you almost always use)

The Bash tool has no TTY, so the interactive REPL (`ollama run x/z-image-turbo` with no prompt) is not usable from inside a Claude Code session. Always pass the prompt as an argument:

```bash
ollama run x/z-image-turbo "a chef in a busy kitchen, steam rising from pots, 35mm film"
```

The image is written to the **current working directory** as a PNG. Before running, `cd` into (or otherwise target) the directory where the user wants the output, then list new files afterward to confirm and report the exact path:

```bash
cd /absolute/path/to/output/dir
before=$(ls *.png 2>/dev/null)
ollama run x/z-image-turbo "prompt here"
ls -lt *.png | head -5
```

Report the resulting absolute path(s) back to the user.

### Interactive (user runs it themselves)

If the user wants to iterate on a prompt, use `/set width`, `/set height`, set a seed, etc., they need to drive the interactive REPL themselves. Tell them to run it in their own terminal (not through you):

```
ollama run x/z-image-turbo
>>> a mountain lake at sunrise
>>> /set width 768
>>> /set height 1024
>>> the same lake, but at dusk with fireflies
```

Don't try to drive `/set` commands yourself — they only exist in the interactive REPL.

## Writing good prompts

These models respond to **specific, concrete, visual** descriptions. Push past the first draft.

- **Subject**: who or what, doing what
- **Setting**: where, time of day, weather, mood
- **Lens / medium**: "35mm film", "overhead shot", "macro", "studio lighting", "soft bokeh"
- **Style anchors**: "natural window light", "candid", "editorial", "product photography"
- **For flux2-klein**: quote any in-image text exactly as you want it rendered, and describe where on the composition it sits

**Good:**

> A young woman in a cozy coffee shop, natural window lighting, cream knit sweater, holding a ceramic mug, soft bokeh background with warm ambient lights, candid moment, shot on 35mm film

**Bad:**

> a nice picture of a girl drinking coffee

When the user gives you a thin prompt, offer to expand it in one pass before generating — don't silently rewrite without telling them, and don't burn a generation on the thin version first.

## Workflow

1. **Verify prerequisites** once (macOS, `ollama --version`). Skip on subsequent generations in the same session.
2. **Pick the model** based on the prompt (or user's explicit choice). State the pick in one sentence.
3. **Expand the prompt** if it's thin. Show the user the expanded version before running if you made meaningful changes.
4. **Warn about first-pull latency** if `ollama list` doesn't show the model — the download is multi-GB and will take a while.
5. **Run it** in the target output directory with the prompt passed as an argument.
6. **Report the output path** — list new PNGs after the run and tell the user the absolute path(s). If the terminal supports inline images (iTerm2, Ghostty, kitty), the user will also see it in their own terminal; don't assume you can see it.
7. **Iterate** if asked. Each run is a new invocation — there is no session-persistent seed from inside the Bash tool.

## Known limitations and gotchas

- **macOS only** right now. Windows and Linux are on the roadmap but not shipped.
- **Experimental / beta**. Flags, model names, and behavior may change. If a command fails unexpectedly, check `ollama --version` and the model pages (https://ollama.com/x/z-image-turbo, https://ollama.com/x/flux2-klein) before flailing.
- **No `/set` from non-interactive mode.** Width, height, seed, steps, and negative prompts are set inside the interactive REPL, which you can't drive. If the user needs those, tell them to run it themselves.
- **Memory.** These models are multi-GB in RAM; generating 1024×1024 is the recommended default for z-image-turbo. If generation OOMs, suggest the user drop width/height in their own interactive session.
- **First run downloads the model.** Don't kick off `ollama run` on a fresh machine without warning the user that it will pull several GB.
- **Output directory = CWD.** There is no `-o` flag. The only way to control where the file lands is to `cd` first.
- **Don't invent flags.** If you're tempted to pass `--seed`, `--steps`, `--width`, a config file, or anything similar, stop and check the Ollama docs first. Making up flags will silently produce wrong output or errors.

## Reporting back

After a successful generation, keep the message short:

- Which model you used and why (one clause)
- The absolute path to the PNG(s)
- One sentence inviting iteration ("want a variant with different lighting / a different angle / larger?")

Don't describe what's in the image — you haven't seen it.
