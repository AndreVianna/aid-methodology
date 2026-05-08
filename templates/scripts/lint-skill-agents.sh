#!/usr/bin/env bash
# lint-skill-agents.sh — verify SKILL.md Agent Selection / Agents Involved
# sections reference real agent definitions.
#
# Walks the three known install variants (claude-code/.claude, cursor/.cursor,
# codex/.agents + codex/.codex) and for each SKILL.md, extracts backtick-quoted
# agent names from "## Agent Selection" or "## Agents Involved" sections, then
# verifies each referenced name has a corresponding agent file.
#
# Usage:
#   lint-skill-agents.sh                  # lint from current directory (repo root)
#   lint-skill-agents.sh --root PATH      # lint a different repo root
#
# Exit codes:
#   0 — all references valid
#   1 — at least one missing agent reference
#   2 — invalid arguments

set -euo pipefail

ROOT="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "lint-skill-agents.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# Variants: skills_subdir | agents_subdir | label
VARIANTS=(
  "claude-code/.claude/skills|claude-code/.claude/agents|claude-code"
  "cursor/.cursor/skills|cursor/.cursor/agents|cursor"
  "codex/.agents/skills|codex/.codex/agents|codex"
)

check_skill() {
  local skill_file="$1"
  local agents_dir="$2"
  local label="$3"
  local skill_name
  skill_name=$(basename "$(dirname "$skill_file")")

  # Build set of known agent names (basename without .md/.toml extension)
  local known
  known=$(ls "$agents_dir" 2>/dev/null | sed -E 's/\.(md|toml)$//' | sort -u)
  if [[ -z "$known" ]]; then
    return 0
  fi

  # Extract content under "## Agent Selection" or "## Agents Involved"
  # Stops at the next ## section header.
  local section_text
  section_text=$(awk '
    /^##[^#]/ && !/^## (Agent Selection|Agents Involved)/ { in_section = 0 }
    /^## Agent Selection/ || /^## Agents Involved/ { in_section = 1; next }
    in_section { print }
  ' "$skill_file")

  if [[ -z "$section_text" ]]; then
    # Skill has no agent selection section — fine
    return 0
  fi

  # Extract backtick-quoted lowercase-hyphenated tokens (agent naming convention).
  # `RESEARCH` (all caps) and `agent.md` (with extension) won't match.
  local refs
  refs=$(echo "$section_text" | grep -oE '`[a-z][a-z0-9-]*`' | tr -d '`' | sort -u)

  # Skip-list: common backticked tokens that are NOT agent names.
  # - aid-* are skill names, not agents
  # - Common parameter/concept names: model, task, feature, delivery, etc.
  local skip_pattern='^(aid-[a-z-]+|model|task|feature|delivery|spec|plan|index|kb|review|fix|done|done|approval|q-and-a|state|approved|pending|skipped|answered|commit|build|test|lint)$'

  local skill_failed=0
  for ref in $refs; do
    # Skip known non-agent tokens
    if echo "$ref" | grep -qE "$skip_pattern"; then
      continue
    fi
    if ! echo "$known" | grep -qx "$ref"; then
      echo "  [$label] $skill_name: references unknown agent '$ref'" >&2
      skill_failed=1
    fi
  done

  return $skill_failed
}

exit_code=0
total_skills=0
total_failures=0

for variant in "${VARIANTS[@]}"; do
  skills_dir="$ROOT/${variant%%|*}"
  rest="${variant#*|}"
  agents_dir="$ROOT/${rest%%|*}"
  label="${rest#*|}"

  if [[ ! -d "$skills_dir" ]]; then
    continue
  fi

  for skill in "$skills_dir"/*/SKILL.md; do
    [[ ! -f "$skill" ]] && continue
    total_skills=$((total_skills + 1))
    if ! check_skill "$skill" "$agents_dir" "$label"; then
      total_failures=$((total_failures + 1))
      exit_code=1
    fi
  done
done

if [[ $exit_code -eq 0 ]]; then
  echo "✓ All $total_skills skills reference valid agents (across 3 install variants)."
else
  echo "" >&2
  echo "$total_failures skill(s) had issues across $total_skills total. See errors above." >&2
fi

exit $exit_code
