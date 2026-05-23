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

tool_name() {
  case "$1" in
    1) echo "Claude Code" ;;
    2) echo "Codex" ;;
    3) echo "Cursor" ;;
  esac
}

print_menu() {
  echo ""
  echo "Select tools to install into: $TARGET"
  echo ""
  for i in 1 2 3; do
    if [[ "${selected[$i]}" -eq 1 ]]; then
      echo "  [$i] [x] $(tool_name $i)"
    else
      echo "  [$i] [ ] $(tool_name $i)"
    fi
  done
  echo "  [4] Done"
  echo ""
}

while true; do
  print_menu
  read -rp "Selection: " choice
  case "$choice" in
    1|2|3)
      if [[ "${selected[$choice]}" -eq 1 ]]; then
        selected[$choice]=0
      else
        selected[$choice]=1
      fi
      ;;
    4)
      break
      ;;
    *)
      echo "Invalid choice. Enter 1, 2, 3, or 4."
      ;;
  esac
done

# Check if anything selected
any=0
for i in 1 2 3; do
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

echo ""
echo "Installing selected tools..."
echo ""

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

echo ""
echo "Done. Files installed into: $TARGET"
echo ""
echo "Next steps:"
echo "  1. Run /aid-init to scaffold the Knowledge Base structure and project placeholders."
echo "  2a. Brownfield (existing code): Run /aid-discover to analyze the codebase and fill in the KB."
echo "  2b. Greenfield (new project):   Run /aid-interview to start requirements gathering."
