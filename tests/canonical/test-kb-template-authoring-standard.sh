#!/usr/bin/env bash
# test-kb-template-authoring-standard.sh -- Mechanical authoring-standard checks for the
# 14 knowledge-base seed templates under canonical/aid/templates/knowledge-base/*.md.
# (README.md was retired from the knowledge-base seed templates in work-005, 15 -> 14.)
#
# Tests (AS01-AS05):
#
#   Per-template mechanical checks (run for each of the 14 seed templates):
#   AS01  each template starts with YAML frontmatter (first line is ---)
#   AS02  each template has a ## Contents index section
#   AS03  each template has NO change-log apparatus and no work reference:
#         AS03  no ## Change Log / ## Revision History section
#         AS03b no changelog: frontmatter field
#         AS03c no work-NNN reference (principles.md P1(e))
#   AS04  no template contains a mermaid diagram fence (```mermaid)
#   AS05  frontmatter contains the required fields (kb-category, intent)
#
#   Aggregate:
#   AS06  exactly 14 template files are present (the synth_default_seed count)
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
assert_eq "$TEMPLATE_COUNT" "14" \
  "AS06 exactly 14 knowledge-base template files present (synth_default_seed count)"

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
  # AS03: NO history apparatus. A KB doc carries no change-log section and no
  # `changelog:` frontmatter field -- per-doc history lives in git, and the
  # changelog was the main route by which transient work references leaked into
  # the KB (kb-authoring/principles.md P1(e)).
  # -------------------------------------------------------------------------
  hist_sections="$(grep -c '^## \(Change Log\|Revision History\)' "$tmpl" || true)"
  assert_eq "$hist_sections" "0" \
    "AS03 ${name}: no '## Change Log' / '## Revision History' section"

  cl_field="$(grep -c '^changelog:' "$tmpl" || true)"
  assert_eq "$cl_field" "0" \
    "AS03b ${name}: no 'changelog:' frontmatter field"

  work_refs="$(grep -cE 'work-[0-9]{3}' "$tmpl" || true)"
  assert_eq "$work_refs" "0" \
    "AS03c ${name}: no work reference (P1(e))"

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
# AS08: feature-inventory.md lives at canonical/aid/templates/feature-inventory.md
# (NOT under knowledge-base/), but aid-discover Step 6 copies it into .aid/knowledge/ as a
# KB doc, so it MUST also conform to the authoring standard (frontmatter / Contents /
# no change-log apparatus / no mermaid / kb-category+intent / concern tag).
# ---------------------------------------------------------------------------
FI="${REPO}/canonical/aid/templates/feature-inventory.md"
if [[ -f "$FI" ]]; then
  assert_eq "$(head -1 "$FI")" "---" \
    "AS08 feature-inventory.md: starts with YAML frontmatter delimiter (---)"

  if grep -q '^## Contents$' "$FI"; then
    pass "AS08 feature-inventory.md: has '## Contents' section"
  else
    fail "AS08 feature-inventory.md: missing '## Contents' section"
  fi

  assert_eq "$(grep -c '^## \(Change Log\|Revision History\)' "$FI" || true)" "0" \
    "AS08 feature-inventory.md: no '## Change Log' / '## Revision History' section"

  assert_eq "$(grep -c '^changelog:' "$FI" || true)" "0" \
    "AS08b feature-inventory.md: no 'changelog:' frontmatter field"

  fi_merm="$(grep -c '^\`\`\`mermaid' "$FI" || true)"
  assert_eq "$fi_merm" "0" \
    "AS08 feature-inventory.md: no mermaid diagram fence"

  fi_fm="$(awk '/^---$/{if(in_fm){exit}else{in_fm=1;next}} in_fm{print}' "$FI")"
  assert_output_contains "$fi_fm" "kb-category" \
    "AS08 feature-inventory.md: frontmatter has 'kb-category' field"
  assert_output_contains "$fi_fm" "intent" \
    "AS08 feature-inventory.md: frontmatter has 'intent' field"

  fi_tags="$(printf '%s\n' "$fi_fm" | grep -m1 '^tags:')"
  if printf '%s\n' "$fi_tags" | grep -Eq '\b(C[0-9]|D)\b'; then
    pass "AS08 feature-inventory.md: tags carry a concern ID (C0-C9/D)"
  else
    fail "AS08 feature-inventory.md: tags missing a concern ID (C0-C9/D)"
  fi
else
  fail "AS08 feature-inventory.md: template not found at $FI"
fi

# ---------------------------------------------------------------------------
# AS09: the no-history rule over the WHOLE template tree, not just knowledge-base/.
#
# AS03 above checks 14 files -- the knowledge-base/ subdirectory at maxdepth 1.
# The no-history rule binds every artifact, so a dated log in task-template.md or
# reviewer-dispatch.md was equally forbidden and equally unchecked. The narrow
# corpus is roughly a fifth of the tree, so four templates in five were exempt
# from a rule that applies to all of them.
#
# Only the history checks widen. AS01/AS02/AS05/AS07 stay narrow on purpose:
# they assert KB frontmatter and a '## Contents' section, which a general
# template such as delivery-plans/task-template.md correctly does not have.
# ---------------------------------------------------------------------------
mapfile -t ALL_TEMPLATES < <(find "${REPO}/canonical/aid/templates" -name '*.md' | sort)
WIDE_COUNT="${#ALL_TEMPLATES[@]}"

if [[ "$WIDE_COUNT" -gt "$TEMPLATE_COUNT" ]]; then
  pass "AS09 wide corpus (${WIDE_COUNT}) is larger than the narrow one (${TEMPLATE_COUNT})"
else
  fail "AS09 wide corpus (${WIDE_COUNT}) should exceed the narrow one (${TEMPLATE_COUNT})"
fi

wide_hist=0
wide_cl=0
for tmpl in "${ALL_TEMPLATES[@]}"; do
  n="$(grep -c '^## \(Change Log\|Revision History\)' "$tmpl" || true)"
  [[ "$n" -gt 0 ]] && { wide_hist=$((wide_hist + 1)); echo "    history section in: ${tmpl#"${REPO}/"}"; }
  c="$(grep -c '^changelog:' "$tmpl" || true)"
  [[ "$c" -gt 0 ]] && { wide_cl=$((wide_cl + 1)); echo "    changelog: field in: ${tmpl#"${REPO}/"}"; }
done

assert_eq "$wide_hist" "0" \
  "AS09 no '## Change Log' / '## Revision History' in any of ${WIDE_COUNT} templates"
assert_eq "$wide_cl" "0" \
  "AS09b no 'changelog:' frontmatter field in any of ${WIDE_COUNT} templates"

# ---------------------------------------------------------------------------
# AS10: the widening is load-bearing.
#
# AS09 passing proves the tree is clean; it does NOT prove the widened check
# would catch anything, because a check that never fires looks identical to a
# clean tree. The history sections were removed before this test was written, so
# there is no live before/after to point at. This fixture supplies one: a
# template-shaped file placed OUTSIDE knowledge-base/, carrying a history
# section. The wide corpus must catch it and the narrow corpus must miss it.
# Missing it is the whole point -- that gap is what AS09 exists to close.
# ---------------------------------------------------------------------------
FIXTURE_DIR="$(mktemp -d)"
trap 'rm -rf "$FIXTURE_DIR"' EXIT

mkdir -p "${FIXTURE_DIR}/templates/knowledge-base" "${FIXTURE_DIR}/templates/delivery-plans"
cat > "${FIXTURE_DIR}/templates/delivery-plans/rogue-template.md" <<'FIXTURE'
# rogue-template.md

A template-shaped file outside knowledge-base/, carrying the apparatus AS03 bans.

## Change Log

- 2026-01-01: initial authoring
FIXTURE

narrow_hits="$(find "${FIXTURE_DIR}/templates/knowledge-base" -maxdepth 1 -name '*.md' \
  -exec grep -l '^## \(Change Log\|Revision History\)' {} \; 2>/dev/null | wc -l)"
wide_hits="$(find "${FIXTURE_DIR}/templates" -name '*.md' \
  -exec grep -l '^## \(Change Log\|Revision History\)' {} \; 2>/dev/null | wc -l)"

assert_eq "$narrow_hits" "0" \
  "AS10 narrow corpus MISSES the rogue template (this is the gap AS09 closes)"
assert_eq "$wide_hits" "1" \
  "AS10 wide corpus CATCHES the rogue template"

rm -rf "$FIXTURE_DIR"
trap - EXIT

# ---------------------------------------------------------------------------
echo
test_summary
exit $?
