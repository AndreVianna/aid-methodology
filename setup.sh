#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# (args parsed above)

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-directory> [--force]" >&2
  exit 1
fi

TARGET="$1"
FORCE=0
if [[ "${2:-}" == "--force" ]]; then
  FORCE=1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: directory '$TARGET' does not exist." >&2
  exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

# Menu state
declare -A selected
selected[1]=0
selected[2]=0
selected[3]=0
selected[4]=0
selected[5]=0

tool_name() {
  case "$1" in
    1) echo "Claude Code" ;;
    2) echo "Codex" ;;
    3) echo "Cursor" ;;
    4) echo "GitHub Copilot CLI" ;;
    5) echo "Antigravity" ;;
  esac
}

print_menu() {
  echo ""
  echo "Select tools to install into: $TARGET"
  echo ""
  for i in 1 2 3 4 5; do
    if [[ "${selected[$i]}" -eq 1 ]]; then
      echo "  [$i] [x] $(tool_name $i)"
    else
      echo "  [$i] [ ] $(tool_name $i)"
    fi
  done
  echo "  [6] Done"
  echo ""
}

while true; do
  print_menu
  read -rp "Selection: " choice
  case "$choice" in
    1|2|3|4|5)
      if [[ "${selected[$choice]}" -eq 1 ]]; then
        selected[$choice]=0
      else
        selected[$choice]=1
      fi
      ;;
    6)
      break
      ;;
    *)
      echo "Invalid choice. Enter 1-6."
      ;;
  esac
done

# Check if anything selected
any=0
for i in 1 2 3 4 5; do
  if [[ "${selected[$i]}" -eq 1 ]]; then any=1; break; fi
done

if [[ $any -eq 0 ]]; then
  echo "Nothing selected. Exiting."
  exit 0
fi

# Copy helper: new=copy, identical=skip, different=ask (or overwrite with --force)
copy_file() {
  local src="$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"
  if [[ -e "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      echo "  Up to date: $dst"
      return
    fi
    if [[ "$FORCE" -eq 1 ]]; then
      cp -r "$src" "$dst"
      echo "  Updated: $dst"
    elif [[ "${AGENTS_COLLISION:-0}" -eq 1 && "$(basename "$dst")" == "AGENTS.md" ]]; then
      cp -r "$src" "$dst"
      echo "  Updated: $dst (AGENTS.md last-writer-wins — collision resolved non-interactively)"
    else
      read -rp "Overwrite '$dst'? (files differ) [y/N] " yn </dev/tty
      case "$yn" in
        [yY]*) cp -r "$src" "$dst"; echo "  Updated: $dst" ;;
        *) echo "  Skipped: $dst" ;;
      esac
    fi
    return
  fi
  cp -r "$src" "$dst"
  echo "  Copied: $dst"
}

# Copy directory recursively, file by file (preserves empty dirs)
copy_dir() {
  local src="$1"
  local dst="$2"
  # Create directory structure first
  while IFS= read -r -d '' dir; do
    rel="${dir#$src/}"
    mkdir -p "$dst/$rel"
  done < <(find "$src" -mindepth 1 -type d -print0)
  # Then copy files
  while IFS= read -r -d '' file; do
    rel="${file#$src/}"
    copy_file "$file" "$dst/$rel"
  done < <(find "$src" -type f -print0)
}

AGENTS_COLLISION=0

echo ""
echo "Installing selected tools..."
echo ""

# AGENTS.md collision pre-copy block (Option A):
# Codex (2), Cursor (3), Copilot CLI (4), and Antigravity (5) all write a root AGENTS.md.
# When >=2 are selected, set AGENTS_COLLISION=1 and warn once; the last-installed (highest-
# numbered selected writer, fixed by per-tool block order) wins — no interactive prompt.
_agents_writers=()
for _i in 2 3 4 5; do
  if [[ "${selected[$_i]}" -eq 1 ]]; then
    _agents_writers+=("$(tool_name $_i)")
  fi
done
if [[ "${#_agents_writers[@]}" -ge 2 ]]; then
  AGENTS_COLLISION=1
  # Survivor = highest-numbered selected AGENTS.md-writing tool (fixed block order)
  _survivor=""
  for _i in 2 3 4 5; do
    if [[ "${selected[$_i]}" -eq 1 ]]; then
      _survivor="$(tool_name $_i)"
    fi
  done
  _writers_list=""
  for _w in "${_agents_writers[@]}"; do _writers_list+="${_writers_list:+, }$_w"; done
  echo "Note: ${_writers_list} all install a shared AGENTS.md; the last-installed tool's version wins — survivor is decided by fixed per-tool install order (highest-numbered selected tool), not the order you toggled them (others are not preserved): ${_survivor} wins."
fi

# Claude Code — uses CLAUDE.md only (no AGENTS.md)
if [[ "${selected[1]}" -eq 1 ]]; then
  echo "--- Claude Code ---"
  copy_dir "$SCRIPT_DIR/profiles/claude-code/.claude" "$TARGET/.claude"
  copy_file "$SCRIPT_DIR/profiles/claude-code/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# Codex — uses AGENTS.md only (no CLAUDE.md)
if [[ "${selected[2]}" -eq 1 ]]; then
  echo "--- Codex ---"
  copy_dir "$SCRIPT_DIR/profiles/codex/.codex" "$TARGET/.codex"
  copy_dir "$SCRIPT_DIR/profiles/codex/.agents" "$TARGET/.agents"
  copy_file "$SCRIPT_DIR/profiles/codex/AGENTS.md" "$TARGET/AGENTS.md"
fi

# Cursor — uses AGENTS.md + .cursor/rules/aid-project.mdc (no CLAUDE.md)
if [[ "${selected[3]}" -eq 1 ]]; then
  echo "--- Cursor ---"
  copy_dir "$SCRIPT_DIR/profiles/cursor/.cursor" "$TARGET/.cursor"
  copy_file "$SCRIPT_DIR/profiles/cursor/AGENTS.md" "$TARGET/AGENTS.md"
fi

# GitHub Copilot CLI — uses .github subtree + root AGENTS.md (no mcp-config.json)
if [[ "${selected[4]}" -eq 1 ]]; then
  echo "--- GitHub Copilot CLI ---"
  copy_dir "$SCRIPT_DIR/profiles/copilot-cli/.github" "$TARGET/.github"
  copy_file "$SCRIPT_DIR/profiles/copilot-cli/AGENTS.md" "$TARGET/AGENTS.md"
fi

# Antigravity — uses .agent subtree + root AGENTS.md
if [[ "${selected[5]}" -eq 1 ]]; then
  echo "--- Antigravity ---"
  copy_dir "$SCRIPT_DIR/profiles/antigravity/.agent" "$TARGET/.agent"
  copy_file "$SCRIPT_DIR/profiles/antigravity/AGENTS.md" "$TARGET/AGENTS.md"
fi

echo ""
echo "Done. Files installed into: $TARGET"
echo "Installed AID version: $(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "(unknown)")"
echo ""
echo "Next steps:"
echo "  1. Run /aid-config to scaffold the Knowledge Base structure and project placeholders."
echo "  2a. Brownfield (existing code): Run /aid-discover to analyze the codebase and fill in the KB."
echo "  2b. Greenfield (new project):   Run /aid-interview to start requirements gathering."
