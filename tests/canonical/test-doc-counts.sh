#!/usr/bin/env bash
# test-doc-counts.sh -- CI guard against skill/agent/profile/catalog count drift in the
# user-facing docs (tech-debt M3).
#
# The problem: hand-written counts (92 skills, 9 agents, 76 shortcuts, 80-row catalog) are
# repeated as prose across the README, docs/, and the profile READMEs, and drift whenever
# the canonical inventory changes. Before this guard, drift was caught only by manual review
# or /aid-housekeep -- so a newcomer could trust a stale count (this very cycle shipped
# docs/install.md reading "82 skills / 67 shortcuts").
#
# The guard (same shape as check-version-sync.sh): derive the counts from the canonical tree
# (the single source of truth), then assert each user-facing surface states the CURRENT
# number. Because every needle is parameterized on the derived count, the assertions
# auto-update when the tree legitimately changes -- you regenerate the docs, not this test.
# Only live headline surfaces are asserted (never changelog/history lines, which legitimately
# cite superseded counts), so there are no false positives on history.
#
# SCOPE: the public-facing docs a reader trusts (README + docs/ + profile READMEs). The KB
# under .aid/knowledge/ is intentionally NOT asserted here -- it carries heavy version-history
# sections and is reconciled by /aid-housekeep; guarding it by prose-grep would false-positive.
#
#   DC01  canonical counts derive cleanly and the catalog is internally consistent
#         (canonical rows + alias rows == total rows)
#   DC02+ each listed (file, phrase) states the current canonical number
#
# Fast + hermetic: reads files only, binds no port, mutates nothing.
#
# Usage: bash test-doc-counts.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$REPO_ROOT"

CATALOG="canonical/aid/templates/shortcut-catalog.yml"

# --- Derive the canonical counts (single source of truth) --------------------
SKILLS=$(find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
AGENTS=$(find canonical/agents -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
PROFILES=$(find profiles -maxdepth 1 -name '*.toml' | wc -l | tr -d ' ')
ROWS=$(grep -c '^  - name:' "$CATALOG")
CANON=$(grep -c '^    alias_of: null' "$CATALOG")
ALIAS=$(grep -c '^    alias_of: aid-' "$CATALOG")
REPURPOSE=$(grep -c '^    repurpose: true' "$CATALOG")
SHORTCUTS=$((ROWS - REPURPOSE))

log "derived: SKILLS=$SKILLS AGENTS=$AGENTS PROFILES=$PROFILES ROWS=$ROWS CANON=$CANON ALIAS=$ALIAS REPURPOSE=$REPURPOSE SHORTCUTS=$SHORTCUTS"

# --- DC01: catalog internal consistency --------------------------------------
assert_eq "$((CANON + ALIAS))" "$ROWS" "DC01a catalog: canonical($CANON) + alias($ALIAS) == total rows($ROWS)"
if [[ "$SKILLS" -gt 0 && "$AGENTS" -gt 0 && "$PROFILES" -gt 0 && "$SHORTCUTS" -gt 0 ]]; then
    pass "DC01b canonical counts derive cleanly (skills=$SKILLS agents=$AGENTS profiles=$PROFILES shortcuts=$SHORTCUTS)"
else
    fail "DC01b a derived count is zero (skills=$SKILLS agents=$AGENTS profiles=$PROFILES shortcuts=$SHORTCUTS) -- tree/catalog layout changed?"
fi

# --- DC02+: each user-facing surface states the CURRENT number ---------------
# Format: "<file>|<needle>"  -- needle embeds the derived count; grep -F (literal).
ASSERTIONS=(
    "README.md|${SKILLS} skills"
    "README.md|${AGENTS} agents"
    "README.md|${SHORTCUTS} shortcuts"
    "docs/repository-structure.md|${SKILLS} skill definitions"
    "docs/repository-structure.md|${AGENTS} agent definitions"
    "docs/repository-structure.md|${ROWS}-row catalog"
    "docs/aid-methodology.md|${SKILLS} skill directories"
    "docs/aid-methodology.md|${AGENTS} agents"
    "docs/aid-methodology.md|${SHORTCUTS} verb-first shortcuts"
    "docs/aid-methodology.md|${ROWS}-row catalog"
    "docs/glossary.md|${SKILLS} skills total"
    "docs/glossary.md|${SHORTCUTS} shortcut skills"
    "docs/glossary.md|${ROWS}-row catalog"
    "docs/diagram-content-reference.md|${SKILLS} skills"
    "docs/diagram-content-reference.md|${AGENTS} agents"
    "docs/diagram-content-reference.md|${SHORTCUTS} shortcuts"
    "docs/install.md|${SKILLS} \`aid-\`-prefixed skill"
    "docs/install.md|${AGENTS} \`aid-\`-prefixed agent"
    "docs/install.md|${SHORTCUTS} Lite-Path shortcut"
    "profiles/claude-code/README.md|${SKILLS} skills"
    "profiles/claude-code/README.md|${AGENTS} agents"
    "profiles/codex/README.md|${SKILLS} skills"
    "profiles/codex/README.md|${AGENTS} agents"
    "profiles/cursor/README.md|${SKILLS} skills"
    "profiles/cursor/README.md|${AGENTS} agents"
    "profiles/copilot-cli/README.md|${SKILLS} skills"
    "profiles/copilot-cli/README.md|${AGENTS} agents"
    "profiles/antigravity/README.md|${SKILLS} skills"
    "profiles/antigravity/README.md|${AGENTS} agents"
)

for _a in "${ASSERTIONS[@]}"; do
    _file="${_a%%|*}"
    _needle="${_a#*|}"
    if [[ ! -f "$_file" ]]; then
        fail "DC02 ${_file} -- file not found"
    elif grep -qF "$_needle" "$_file"; then
        pass "DC02 ${_file} states '${_needle}'"
    else
        fail "DC02 ${_file} does NOT state '${_needle}' -- count drift (canonical tree changed but this doc was not updated; regenerate/reconcile the doc)"
    fi
done

test_summary
