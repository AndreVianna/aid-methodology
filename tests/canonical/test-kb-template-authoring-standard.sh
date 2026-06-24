#!/usr/bin/env bash
# test-kb-template-authoring-standard.sh -- Mechanical authoring-standard checks for the
# 15 knowledge-base seed templates under canonical/aid/templates/knowledge-base/*.md.
#
# Tests (AS01-AS05):
#
#   Per-template mechanical checks (run for each of the 15 seed templates):
#   AS01  each template starts with YAML frontmatter (first line is ---)
#   AS02  each template has a ## Contents index section
#   AS03  each template has ## Change Log as the LAST top-level section
#   AS04  no template contains a mermaid diagram fence (```mermaid)
#   AS05  frontmatter contains the required fields (kb-category, intent)
#
#   Aggregate:
#   AS06  exactly 15 template files are present (the synth_default_seed count)
#
# Every check is run for every template, so a failure names the offending file.
#
# Usage:
#   bash tests/canonical/test-kb-template-authoring-standard.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-kb-template-authoring-standard.sh =="

KB_TEMPLATES="${REPO}/canonical/aid/templates/knowledge-base"

if [[ ! -d "$KB_TEMPLATES" ]]; then
  echo "FATAL: knowledge-base templates directory not found at $KB_TEMPLATES" >&2
  exit 2
fi

# Collect all .md template files (sorted for determinism)
mapfile -t TEMPLATES < <(find "$KB_TEMPLATES" -maxdepth 1 -name '*.md' | sort)
TEMPLATE_COUNT="${#TEMPLATES[@]}"

# ---------------------------------------------------------------------------
# AS06: exactly 15 template files present
# ---------------------------------------------------------------------------
assert_eq "$TEMPLATE_COUNT" "15" \
  "AS06 exactly 15 knowledge-base template files present (synth_default_seed count)"

# ---------------------------------------------------------------------------
# Per-template checks (AS01-AS05)
# ---------------------------------------------------------------------------
for tmpl in "${TEMPLATES[@]}"; do
  name="$(basename "$tmpl")"

  # -------------------------------------------------------------------------
  # AS01: first line must be '---' (YAML frontmatter opening delimiter)
  # -------------------------------------------------------------------------
  first_line="$(head -1 "$tmpl")"
  assert_eq "$first_line" "---" \
    "AS01 ${name}: starts with YAML frontmatter delimiter (---)"

  # -------------------------------------------------------------------------
  # AS02: must contain a ## Contents section
  # -------------------------------------------------------------------------
  if grep -q '^## Contents$' "$tmpl"; then
    pass "AS02 ${name}: has '## Contents' section"
  else
    fail "AS02 ${name}: missing '## Contents' section"
  fi

  # -------------------------------------------------------------------------
  # AS03: ## Change Log must be the LAST top-level (##) section
  # The last line matching '^## ' must be '## Change Log'
  # -------------------------------------------------------------------------
  last_section="$(grep '^## ' "$tmpl" | tail -1)"
  assert_eq "$last_section" "## Change Log" \
    "AS03 ${name}: '## Change Log' is the last top-level section"

  # -------------------------------------------------------------------------
  # AS04: no mermaid diagram fences
  # -------------------------------------------------------------------------
  mermaid_count="$(grep -c '^\`\`\`mermaid' "$tmpl" || true)"
  assert_eq "$mermaid_count" "0" \
    "AS04 ${name}: no mermaid diagram fence"

  # -------------------------------------------------------------------------
  # AS05: frontmatter contains required fields kb-category and intent
  # Extract only the frontmatter block (between the first two --- delimiters)
  # -------------------------------------------------------------------------
  frontmatter="$(awk '/^---$/{if(in_fm){exit}else{in_fm=1;next}} in_fm{print}' "$tmpl")"
  assert_output_contains "$frontmatter" "kb-category" \
    "AS05 ${name}: frontmatter has 'kb-category' field"
  assert_output_contains "$frontmatter" "intent" \
    "AS05 ${name}: frontmatter has 'intent' field"

  # -------------------------------------------------------------------------
  # AS07: concern ID (C0-C9 or D) present in tags for concern-mapped docs.
  # Orientation/meta docs (external-sources, README) carry no concern per
  # concern-model.md and are exempt.
  # -------------------------------------------------------------------------
  case "$name" in
    external-sources.md|README.md)
      : ;;  # orientation/meta -- exempt (no concern dimension)
    *)
      tags_line="$(printf '%s\n' "$frontmatter" | grep -m1 '^tags:')"
      if printf '%s\n' "$tags_line" | grep -Eq '\b(C[0-9]|D)\b'; then
        pass "AS07 ${name}: tags carry a concern ID (C0-C9/D)"
      else
        fail "AS07 ${name}: tags missing a concern ID (C0-C9/D)"
      fi ;;
  esac
done

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
