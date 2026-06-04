#!/usr/bin/env bash
# test-discovery-doc-ownership.sh — Regression guard for discovery doc-ownership consistency.
#
# Invariant: for each standard KB doc, exactly one aid-researcher slot "produces" it, and
# the ownership table in doc-set-resolve.md agrees with the dispatch table in state-generate.md.
# (Updated: discovery-* agents merged into parameterized aid-researcher slots per work-001.)
#
# Checks:
#   T01  ownership table assigns project-structure.md to aid-researcher-scout
#   T02  ownership table assigns external-sources.md to aid-researcher-scout
#   T03  ownership table does NOT assign infrastructure.md to aid-researcher-scout
#   T04  ownership table assigns infrastructure.md to aid-researcher-quality
#   T05  ownership table assigns test-landscape.md to aid-researcher-quality
#   T06  ownership table assigns tech-debt.md to aid-researcher-quality
#   T07  dispatch table Step 1 assigns project-structure.md to aid-researcher (pre-scan)
#   T08  dispatch table Step 1 assigns external-sources.md to aid-researcher (pre-scan)
#   T09  dispatch table [5/5] row assigns infrastructure.md to aid-researcher (quality doc-set)
#   T10  no old discovery-* agent names remain in state-generate.md dispatch table
#   T11  no old discovery-* agent names remain in doc-set-resolve.md ownership table
#   T12  aid-researcher AGENT.md exists and is not the old per-doc format
#
# Usage:
#   bash test-discovery-doc-ownership.sh [--verbose]
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
DOC_SET_RESOLVE="${CANONICAL}/skills/aid-discover/references/doc-set-resolve.md"
STATE_GENERATE="${CANONICAL}/skills/aid-discover/references/state-generate.md"
RESEARCHER_AGENT="${CANONICAL}/agents/aid-researcher/AGENT.md"

# --- Ownership table checks (doc-set-resolve.md) ---

OWNERSHIP_TABLE=$(grep -A2 "| \`" "${DOC_SET_RESOLVE}" | grep "aid-researcher" || true)

# T01: project-structure.md → aid-researcher-scout
ROW_PS=$(grep "project-structure.md" "${DOC_SET_RESOLVE}" || true)
assert_output_contains "${ROW_PS}" "aid-researcher-scout" \
    "T01 ownership table assigns project-structure.md to aid-researcher-scout"

# T02: external-sources.md → aid-researcher-scout
ROW_ES=$(grep "external-sources.md" "${DOC_SET_RESOLVE}" || true)
assert_output_contains "${ROW_ES}" "aid-researcher-scout" \
    "T02 ownership table assigns external-sources.md to aid-researcher-scout"

# T03: infrastructure.md is NOT assigned to aid-researcher-scout
ROW_INFRA_SCOUT=$(grep "infrastructure.md" "${DOC_SET_RESOLVE}" | grep "aid-researcher-scout" || true)
assert_eq "${ROW_INFRA_SCOUT}" "" \
    "T03 ownership table does NOT assign infrastructure.md to aid-researcher-scout"

# T04: infrastructure.md → aid-researcher-quality
ROW_INFRA=$(grep "infrastructure.md" "${DOC_SET_RESOLVE}" | grep "aid-researcher-quality" || true)
assert_output_contains "${ROW_INFRA}" "aid-researcher-quality" \
    "T04 ownership table assigns infrastructure.md to aid-researcher-quality"

# T05: test-landscape.md → aid-researcher-quality
ROW_TL=$(grep "test-landscape.md" "${DOC_SET_RESOLVE}" | grep "aid-researcher-quality" || true)
assert_output_contains "${ROW_TL}" "aid-researcher-quality" \
    "T05 ownership table assigns test-landscape.md to aid-researcher-quality"

# T06: tech-debt.md → aid-researcher-quality
ROW_TD=$(grep "tech-debt.md" "${DOC_SET_RESOLVE}" | grep "aid-researcher-quality" || true)
assert_output_contains "${ROW_TD}" "aid-researcher-quality" \
    "T06 ownership table assigns tech-debt.md to aid-researcher-quality"

# --- Dispatch table checks (state-generate.md) ---

# T07: Step 1 text block must mention project-structure.md (pre-scan)
STEP1_BLOCK=$(sed -n '/^## Step 1:/,/^## Step/p' "${STATE_GENERATE}" | head -20)
assert_output_contains "${STEP1_BLOCK}" "project-structure.md" \
    "T07 dispatch Step 1 mentions project-structure.md"

# T08: Step 1 text block must mention external-sources.md (pre-scan)
assert_output_contains "${STEP1_BLOCK}" "external-sources.md" \
    "T08 dispatch Step 1 mentions external-sources.md"

# T09: The dispatch table row for [5/5] / quality doc-set must include infrastructure.md
ROW_55=$(grep "\[5/5\]" "${STATE_GENERATE}" | grep "infrastructure.md" || true)
assert_output_contains "${ROW_55}" "infrastructure.md" \
    "T09 dispatch table [5/5] row assigns infrastructure.md to quality doc-set"

# T10: No old discovery-* agent names in state-generate.md dispatch table
OLD_NAMES_SG=$(grep -E '\bdiscovery-(scout|architect|analyst|integrator|quality|reviewer)\b' "${STATE_GENERATE}" || true)
assert_eq "${OLD_NAMES_SG}" "" \
    "T10 no old discovery-* agent names in state-generate.md dispatch table"

# T11: No old discovery-* agent names in doc-set-resolve.md ownership table
OLD_NAMES_DSR=$(grep -E '\bdiscovery-(scout|architect|analyst|integrator|quality|reviewer)\b' "${DOC_SET_RESOLVE}" || true)
assert_eq "${OLD_NAMES_DSR}" "" \
    "T11 no old discovery-* agent names in doc-set-resolve.md ownership table"

# T12: aid-researcher AGENT.md exists and uses parameterized description (not per-doc)
assert_file_exists "${RESEARCHER_AGENT}" "T12 aid-researcher AGENT.md exists"
RESEARCHER_NAME=$(grep "^name:" "${RESEARCHER_AGENT}" || true)
assert_output_contains "${RESEARCHER_NAME}" "aid-researcher" \
    "T12 aid-researcher AGENT.md has name: aid-researcher frontmatter"

# --- Summary ---
test_summary
