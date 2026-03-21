#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate target directory argument
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target-directory>" >&2
  exit 1
fi

TARGET="$1"

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

# Copy helper: asks before overwriting
copy_file() {
  local src="$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"
  if [[ -e "$dst" ]]; then
    read -rp "Overwrite '$dst'? [y/N] " yn
    case "$yn" in
      [yY]*) ;;
      *) echo "  Skipped: $dst"; return ;;
    esac
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

# Claude Code
if [[ "${selected[1]}" -eq 1 ]]; then
  echo "--- Claude Code ---"
  copy_dir "$SCRIPT_DIR/claude-code/.claude" "$TARGET/.claude"
  copy_file "$SCRIPT_DIR/claude-code/AGENTS.md" "$TARGET/AGENTS.md"
  copy_file "$SCRIPT_DIR/claude-code/CLAUDE.md" "$TARGET/CLAUDE.md"
fi

# Codex
if [[ "${selected[2]}" -eq 1 ]]; then
  echo "--- Codex ---"
  copy_dir "$SCRIPT_DIR/codex/.codex" "$TARGET/.codex"
  copy_file "$SCRIPT_DIR/codex/AGENTS.md" "$TARGET/AGENTS.md"
fi

# Cursor
if [[ "${selected[3]}" -eq 1 ]]; then
  echo "--- Cursor ---"
  copy_dir "$SCRIPT_DIR/cursor/.cursor" "$TARGET/.cursor"
  copy_file "$SCRIPT_DIR/cursor/AGENTS.md" "$TARGET/AGENTS.md"
fi

echo ""
echo "Done. Files installed into: $TARGET"
echo ""
echo "Next steps:"
echo "  1. Edit AGENTS.md (and CLAUDE.md if using Claude Code) with your project details."
echo "  2. Run the aid-discover skill to generate knowledge/INDEX.md."
