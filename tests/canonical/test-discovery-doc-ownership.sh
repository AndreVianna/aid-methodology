#!/usr/bin/env bash
# test-discovery-doc-ownership.sh — Regression guard for discovery doc-ownership consistency.
#
# Invariant: for each standard KB doc, exactly one discovery agent "produces" it, and every
# agent's self-understanding (AGENT.md Produce line + What-You-Don't-Do) agrees with the
# authoritative dispatch table in state-generate.md.
#
# Checks:
#   T01  scout Produce line names project-structure.md
#   T02  scout Produce line names external-sources.md
#   T03  scout Produce line does NOT name infrastructure.md
#   T04  scout What-You-Don't-Do disclaims infrastructure → points to Quality
#   T05  scout frontmatter description names project-structure.md
#   T06  scout frontmatter description names external-sources.md
#   T07  scout frontmatter description does NOT name infrastructure.md
#   T08  quality Produce line names infrastructure.md
#   T09  quality Produce line names test-landscape.md
#   T10  quality Produce line names tech-debt.md
#   T11  quality What-You-Don't-Do does NOT disclaim infrastructure
#   T12  dispatch table Step 1 assigns project-structure.md to scout
#   T13  dispatch table Step 1 assigns external-sources.md to scout
#   T14  dispatch table [5/5] row assigns infrastructure.md to quality
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
SCOUT_AGENT="${CANONICAL}/agents/discovery-scout/AGENT.md"
QUALITY_AGENT="${CANONICAL}/agents/discovery-quality/AGENT.md"
STATE_GENERATE="${CANONICAL}/skills/aid-discover/references/state-generate.md"

# --- Scout AGENT.md checks ---

# Extract the Produce line(s) from ## What You Do
SCOUT_PRODUCE=$(grep -F "Produce \`.aid/knowledge/" "${SCOUT_AGENT}" || true)

assert_output_contains "${SCOUT_PRODUCE}" "project-structure.md" \
    "T01 scout Produce line includes project-structure.md"

assert_output_contains "${SCOUT_PRODUCE}" "external-sources.md" \
    "T02 scout Produce line includes external-sources.md"

assert_output_not_contains "${SCOUT_PRODUCE}" "infrastructure.md" \
    "T03 scout Produce line does NOT include infrastructure.md"

# Check What-You-Don't-Do section: must contain "infrastructure" and "Quality"
# Extract lines in the "## What You Don't Do" to "## Key Constraints" range
SCOUT_WYNDDO=$(sed -n '/^## What You Don'"'"'t Do/,/^## Key Constraints/p' "${SCOUT_AGENT}")

assert_output_contains "${SCOUT_WYNDDO}" "infrastructure" \
    "T04 scout What-You-Don't-Do contains infrastructure disclaimer"

INFRA_LINE=$(echo "${SCOUT_WYNDDO}" | grep -i "infrastructure" || true)
assert_output_contains "${INFRA_LINE}" "Quality" \
    "T04b scout infrastructure disclaimer targets Discovery Quality"

# Extract frontmatter description (line 3)
SCOUT_DESC=$(sed -n '3p' "${SCOUT_AGENT}")

assert_output_contains "${SCOUT_DESC}" "project-structure.md" \
    "T05 scout description includes project-structure.md"

assert_output_contains "${SCOUT_DESC}" "external-sources.md" \
    "T06 scout description includes external-sources.md"

assert_output_not_contains "${SCOUT_DESC}" "infrastructure.md" \
    "T07 scout description does NOT include infrastructure.md"

# --- Quality AGENT.md checks ---

QUALITY_PRODUCE=$(grep -F "Produce \`.aid/knowledge/" "${QUALITY_AGENT}" || true)

assert_output_contains "${QUALITY_PRODUCE}" "infrastructure.md" \
    "T08 quality Produce line includes infrastructure.md"

assert_output_contains "${QUALITY_PRODUCE}" "test-landscape.md" \
    "T09 quality Produce line includes test-landscape.md"

assert_output_contains "${QUALITY_PRODUCE}" "tech-debt.md" \
    "T10 quality Produce line includes tech-debt.md"

QUALITY_WYNDDO=$(sed -n '/^## What You Don'"'"'t Do/,/^## Key Constraints/p' "${QUALITY_AGENT}")

assert_output_not_contains "${QUALITY_WYNDDO}" "infrastructure" \
    "T11 quality What-You-Don't-Do does NOT disclaim infrastructure"

# --- Dispatch table checks (state-generate.md) ---

# Step 1 text block must mention both docs scout produces
STEP1_BLOCK=$(sed -n '/^## Step 1:/,/^### Steps 2-5/p' "${STATE_GENERATE}")

assert_output_contains "${STEP1_BLOCK}" "project-structure.md" \
    "T12 dispatch Step 1 mentions project-structure.md"

assert_output_contains "${STEP1_BLOCK}" "external-sources.md" \
    "T13 dispatch Step 1 mentions external-sources.md"

# The dispatch table row for [5/5] / discovery-quality must include infrastructure.md
ROW_55=$(grep "discovery-quality" "${STATE_GENERATE}" | grep "infrastructure.md" || true)

assert_output_contains "${ROW_55}" "infrastructure.md" \
    "T14 dispatch table assigns infrastructure.md to discovery-quality"

# --- Summary ---
test_summary
