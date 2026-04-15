# skills

Personal collection of [Claude Code](https://claude.com/claude-code) skills. Some are authored here; others are pulled in as submodules from their upstream repos.

## Contents

| Skill | Origin | What it does |
|---|---|---|
| [`slides/`](./slides) | in-tree | Convert a markdown slide deck into a self-contained HTML presentation or a PDF. Light + dark themes, print-clean, zero external dependencies in the output. |
| [`humanizer/`](./humanizer) | submodule → [`blader/humanizer`](https://github.com/blader/humanizer) | Rewrite text to remove signs of AI-generated writing. |
| [`visual-explainer/`](./visual-explainer) | submodule → [`nicobailon/visual-explainer`](https://github.com/nicobailon/visual-explainer) | Generate self-contained HTML pages that visually explain systems, diffs, plans, and data. |

## Cloning

This repo uses git submodules. Clone recursively so the submodules come with you:

```bash
git clone --recurse-submodules https://github.com/markuskreitzer/skills.git
```

Or if you've already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

## Installing a skill into Claude Code

Claude Code reads skills from `~/.claude/skills/<name>/`. To install any of the skills here, copy or symlink the directory into that location:

```bash
# symlink (updates stay in sync with this repo)
ln -s "$(pwd)/slides" ~/.claude/skills/slides

# or copy
cp -R slides ~/.claude/skills/slides
```

Then invoke the skill in any Claude Code session with `/slides path/to/deck.md` (or whatever trigger the skill's `SKILL.md` defines).

## Updating submodules

The submodules are pinned to a specific commit. To pull in newer upstream versions:

```bash
git submodule update --remote humanizer visual-explainer
git add humanizer visual-explainer
git commit -m "bump submodules to latest"
```

## Licensing

Each skill carries its own license. `slides/` is MIT (see the top-level `LICENSE` file). The submodules are governed by their upstream repo licenses — `blader/humanizer` is MIT, `nicobailon/visual-explainer` has its own terms in its repo.
