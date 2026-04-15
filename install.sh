#!/usr/bin/env bash
#
# install.sh — symlink skills from this repo into Claude Code.
#
# Default scope is "user" (~/.claude/skills). Use --project to install into a
# specific project's .claude/skills dir instead. Pass skill names positionally
# to install a subset, or omit to install everything.
#
# Usage:
#   ./install.sh                       Install every discoverable skill to ~/.claude/skills
#   ./install.sh --user                Same as default
#   ./install.sh --project             Install to $PWD/.claude/skills
#   ./install.sh --project PATH        Install to PATH/.claude/skills
#   ./install.sh --dest DIR            Install to a custom directory
#   ./install.sh slides ollama-image   Install only the named skills (any scope)
#   ./install.sh --list                List discoverable skills and exit
#   ./install.sh --force               Overwrite existing entries at the destination
#   ./install.sh --dry-run             Print what would happen, change nothing
#   ./install.sh --uninstall [names]   Remove symlinks this script would create
#   ./install.sh -h | --help           Show this help
#
set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

scope="user"
project_path=""
custom_dest=""
force=0
dry_run=0
list_only=0
uninstall=0
selected=()

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed '$d' | sed 's/^#\s\{0,1\}//'
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage 0 ;;
    --user) scope="user"; shift ;;
    --project)
      scope="project"; shift
      if [[ $# -gt 0 && "$1" != -* ]]; then project_path="$1"; shift; fi
      ;;
    --dest)
      [[ $# -ge 2 ]] || { echo "--dest needs a directory" >&2; exit 2; }
      scope="dest"; custom_dest="$2"; shift 2
      ;;
    --force) force=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --list) list_only=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    --) shift; while [[ $# -gt 0 ]]; do selected+=("$1"); shift; done ;;
    -*) echo "unknown flag: $1" >&2; usage 2 ;;
    *) selected+=("$1"); shift ;;
  esac
done

case "$scope" in
  user)    dest="$HOME/.claude/skills" ;;
  project) project_path="${project_path:-$PWD}"; dest="$project_path/.claude/skills" ;;
  dest)    dest="$custom_dest" ;;
esac

# Discover installable skills. A "skill" is any top-level directory in this
# repo that contains a SKILL.md somewhere within it (searched up to 4 levels
# deep to handle plugin-style layouts like visual-explainer/plugins/<name>/SKILL.md).
# The symlink source is the directory that actually contains SKILL.md, so
# Claude Code sees the expected layout regardless of where it sits in the repo.
discover_skills() {
  local entry name skill_file src
  for entry in "$SCRIPT_DIR"/*/; do
    [ -d "$entry" ] || continue
    name="$(basename "$entry")"
    case "$name" in
      .git|node_modules|vendor) continue ;;
    esac
    skill_file="$(find "$entry" -maxdepth 4 -name SKILL.md -print 2>/dev/null | head -n 1 || true)"
    [ -n "$skill_file" ] || continue
    src="$(cd "$(dirname "$skill_file")" && pwd)"
    printf '%s\t%s\n' "$name" "$src"
  done
}

matches_selection() {
  local name="$1" s
  [ ${#selected[@]} -eq 0 ] && return 0
  for s in "${selected[@]}"; do [[ "$s" == "$name" ]] && return 0; done
  return 1
}

if [[ $list_only -eq 1 ]]; then
  printf 'Discoverable skills in %s:\n' "$SCRIPT_DIR"
  discover_skills | awk -F'\t' '{ printf "  %-20s -> %s\n", $1, $2 }'
  exit 0
fi

printf 'Destination: %s\n' "$dest"
[[ $dry_run -eq 1 ]] && printf '(dry run — nothing will change)\n'

if [[ $uninstall -eq 1 ]]; then
  removed=0
  while IFS=$'\t' read -r name _src; do
    matches_selection "$name" || continue
    target="$dest/$name"
    if [ -L "$target" ] || [ -e "$target" ]; then
      printf 'remove %s\n' "$target"
      [[ $dry_run -eq 0 ]] && rm -rf "$target"
      removed=$((removed+1))
    fi
  done < <(discover_skills)
  printf '\nDone. %d removed.\n' "$removed"
  exit 0
fi

[[ $dry_run -eq 1 ]] || mkdir -p "$dest"

installed=0
skipped=0
while IFS=$'\t' read -r name src; do
  matches_selection "$name" || continue

  target="$dest/$name"
  if [ -L "$target" ] || [ -e "$target" ]; then
    if [[ $force -eq 1 ]]; then
      [[ $dry_run -eq 0 ]] && rm -rf "$target"
    else
      printf 'skip   %-20s (exists — use --force to overwrite)\n' "$name"
      skipped=$((skipped+1))
      continue
    fi
  fi

  printf 'link   %-20s -> %s\n' "$name" "$src"
  if [[ $dry_run -eq 0 ]]; then
    ln -s "$src" "$target"
  fi
  installed=$((installed+1))
done < <(discover_skills)

printf '\nDone. %d installed, %d skipped.\n' "$installed" "$skipped"
