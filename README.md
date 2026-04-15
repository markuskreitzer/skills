# skills

Personal collection of [Claude Code](https://claude.com/claude-code) skills. Some are authored here; others are pulled in as submodules from their upstream repos.

## Contents

| Skill | Origin | What it does |
|---|---|---|
| [`slides/`](./slides) | in-tree | Convert a markdown slide deck into a self-contained HTML presentation or a PDF. Light + dark themes, print-clean, zero external dependencies in the output. |
| [`ollama-image/`](./ollama-image) | in-tree | Generate images locally with Ollama's experimental image-generation models (`x/z-image-turbo`, `x/flux2-klein`). macOS only during beta. |
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

## Installing skills into Claude Code

Use the bundled `install.sh` script. It symlinks each skill in this repo into the right `.claude/skills/` directory so updates here stay in sync with Claude Code. The script auto-detects where each skill's `SKILL.md` actually lives (handy for plugin-style layouts like `visual-explainer/plugins/visual-explainer/`).

**Default — install everything globally for your user:**

```bash
./install.sh
```

This symlinks every skill into `~/.claude/skills/<name>`. Claude Code will pick them up in every session.

**Project scope — only inside one project:**

```bash
# from inside the project directory:
./install.sh --project

# or from anywhere, pointing at the project:
./install.sh --project /path/to/some/project
```

This writes the symlinks into `<project>/.claude/skills/<name>`, so the skills are only active when Claude Code is running inside that project.

**Install a subset:**

```bash
./install.sh slides ollama-image              # user scope, two skills
./install.sh --project . visual-explainer     # project scope, just one
```

**Other flags:**

| Flag | What it does |
|---|---|
| `--user` | Install to `~/.claude/skills` (the default) |
| `--project [PATH]` | Install to `PATH/.claude/skills` (default `PATH` is `$PWD`) |
| `--dest DIR` | Install to an arbitrary destination directory |
| `--list` | Show what would be installed from this repo and where each `SKILL.md` is sourced from |
| `--dry-run` | Print what would happen without touching the filesystem |
| `--force` | Overwrite existing entries at the destination (dangerous if those are real directories — it uses `rm -rf`) |
| `--uninstall` | Remove the symlinks this script would have created (respects `--user` / `--project` / `--dest` and positional selection) |
| `-h`, `--help` | Show usage |

**Examples:**

```bash
./install.sh --list                        # what's available?
./install.sh --dry-run --project .         # preview project-scope install
./install.sh --force                       # replace whatever's at ~/.claude/skills/<name>
./install.sh --uninstall slides            # remove the slides symlink from ~/.claude/skills
./install.sh --uninstall --project .       # remove everything this repo installed into the current project
```

Once installed, invoke a skill in any Claude Code session the normal way — e.g. `/slides path/to/deck.md`, or just ask Claude to "generate an image of X locally" to trigger `ollama-image`.

## Updating submodules

The submodules are pinned to a specific commit. To pull in newer upstream versions:

```bash
git submodule update --remote humanizer visual-explainer
git add humanizer visual-explainer
git commit -m "bump submodules to latest"
```

## Licensing

Each skill carries its own license. `slides/` and `ollama-image/` are MIT (see the top-level `LICENSE` file). The submodules are governed by their upstream repo licenses — `blader/humanizer` is MIT, `nicobailon/visual-explainer` has its own terms in its repo.
