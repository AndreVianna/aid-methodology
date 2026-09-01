#!/usr/bin/env bash
# test-expectations-single-source.sh — Guard against per-doc expectation duplication.
#
# Invariants:
#   (1) Single-source invariant — the canary block key "### architecture.md" resolves
#       only to document-expectations.md; aid-reviewer/AGENT.md has 0 per-doc
#       "### *.md" blocks (heading-only pointer is allowed).
#       (Note: formerly tested discovery-reviewer/AGENT.md; merged into aid-reviewer per work-001.)
#   (2) Reviewer-has-access invariant — {{DOCUMENT_EXPECTATIONS}} placeholder is present
#       in reviewer-prompt.md AND document-expectations.md is named (read+substitute wiring)
#       in BOTH state-review.md and state-fix.md — so a missing FIX-mode wiring fails here.
#
# Checks:
#   T01  canary "### architecture.md" found in document-expectations.md
#   T02  canary "### architecture.md" NOT found in aid-reviewer/AGENT.md
#   T03  aid-reviewer/AGENT.md has 0 per-doc "### *.md" blocks
#   T04  {{DOCUMENT_EXPECTATIONS}} placeholder present in reviewer-prompt.md
#   T05  document-expectations.md named in state-review.md (REVIEW dispatch wiring)
#   T06  document-expectations.md named in state-fix.md (FIX dispatch wiring)
#   T07  document-expectations.md is superset: contains "### {reviewer_output_file}"
#   T08  document-expectations.md retains "### project-structure.md"
#   T09  document-expectations.md retains "### external-sources.md"
#
# Usage:
#   bash test-expectations-single-source.sh [--verbose]
#
# Exit codes:
#   0  all tests passed
#   1  one or more tests failed

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"

CANONICAL="${SCRIPT_DIR}/../../canonical"
DOC_EXPECTATIONS="${CANONICAL}/skills/aid-discover/references/document-expectations.md"
REVIEWER_AGENT="${CANONICAL}/agents/aid-reviewer/AGENT.md"
REVIEWER_PROMPT="${CANONICAL}/skills/aid-discover/references/reviewer-prompt.md"
STATE_REVIEW="${CANONICAL}/skills/aid-discover/references/state-review.md"
STATE_FIX="${CANONICAL}/skills/aid-discover/references/state-fix.md"

# --- (1) Single-source invariant ---

# T01: canary block key exists in document-expectations.md
if grep -q '^### architecture.md' "${DOC_EXPECTATIONS}" 2>/dev/null; then
    pass "T01 canary '### architecture.md' found in document-expectations.md"
else
    fail "T01 canary '### architecture.md' NOT found in document-expectations.md"
fi

# T02: canary block key NOT in aid-reviewer/AGENT.md
if ! grep -q '^### architecture.md' "${REVIEWER_AGENT}" 2>/dev/null; then
    pass "T02 canary '### architecture.md' NOT present in aid-reviewer/AGENT.md"
else
    fail "T02 canary '### architecture.md' found in aid-reviewer/AGENT.md (per-doc block still present)"
fi

# T03: aid-reviewer/AGENT.md has zero per-doc "### *.md" blocks
PERDOC_COUNT=$(grep -c '^### .*\.md' "${REVIEWER_AGENT}" 2>/dev/null; true)
PERDOC_COUNT="${PERDOC_COUNT:-0}"
if [[ "$PERDOC_COUNT" -eq 0 ]]; then
    pass "T03 aid-reviewer/AGENT.md has 0 per-doc '### *.md' blocks"
else
    fail "T03 aid-reviewer/AGENT.md still has $PERDOC_COUNT per-doc '### *.md' block(s)"
fi

# --- (2) Reviewer-has-access invariant ---

# T04: {{DOCUMENT_EXPECTATIONS}} placeholder present in reviewer-prompt.md
assert_file_contains "${REVIEWER_PROMPT}" "{{DOCUMENT_EXPECTATIONS}}" \
    "T04 {{DOCUMENT_EXPECTATIONS}} placeholder present in reviewer-prompt.md"

# T05: document-expectations.md named in state-review.md (REVIEW dispatch wiring)
assert_file_contains "${STATE_REVIEW}" "document-expectations.md" \
    "T05 document-expectations.md named in state-review.md (REVIEW dispatch wiring)"

# T06: document-expectations.md named in state-fix.md (FIX dispatch wiring)
assert_file_contains "${STATE_FIX}" "document-expectations.md" \
    "T06 document-expectations.md named in state-fix.md (FIX dispatch wiring)"

# --- Merge-completeness: document-expectations.md is a superset ---

# T07: ported block present
assert_file_contains "${DOC_EXPECTATIONS}" "### {reviewer_output_file}" \
    "T07 document-expectations.md contains '### {reviewer_output_file}' (ported from reviewer)"

# T08: retained block present
assert_file_contains "${DOC_EXPECTATIONS}" "### project-structure.md" \
    "T08 document-expectations.md retains '### project-structure.md'"

# T09: retained block present
assert_file_contains "${DOC_EXPECTATIONS}" "### external-sources.md" \
    "T09 document-expectations.md retains '### external-sources.md'"

# --- Summary ---
test_summary
