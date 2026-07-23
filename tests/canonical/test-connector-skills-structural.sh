#!/usr/bin/env bash
# test-connector-skills-structural.sh -- structural guard suite for
# work-004-connector-consumption's net-new markdown artifacts: the two skills
# (aid-set-connector / aid-unset-connector), the shared reconcile.md
# (bulk + single-stem modes), the ELICIT regression pointer, the
# "no new scripts" contract, and the AC8 profile `## Connectors` presence
# check (byte-identity across the four AGENTS.md is ALREADY covered by
# tests/canonical/test-agents-md-invariant.sh -- this suite does not
# duplicate that; it only confirms PRESENCE + substance across all 5 profile
# context files, which that suite does not check).
#
# Traces:
#   ST01-ST04   aid-set-connector/SKILL.md exists with the right signature
#               (name, <tool> <type> [--rotate-secret] argument-hint,
#               AskUserQuestion in allowed-tools, never invokes /aid-discover)
#   ST05-ST08   aid-unset-connector/SKILL.md exists with the right signature
#               (name, <tool> argument-hint, never invokes /aid-discover)
#   ST09-ST12   both skills documented as on-demand/off-pipeline (no phase
#               gate references them -- matches the aid-config/aid-housekeep
#               convention); neither is registered in shortcut-catalog.yml
#   ST13-ST18   reconcile.md documents BOTH modes (bulk + single-stem), the
#               ADD/UPDATE/NO-OP/REMOVE class table, the `persisted \ declared`
#               diff, and the AC6 no-collateral guarantee
#   ST19-ST24   AC7 -- state-elicit.md points to reconcile.md's bulk mode
#               (not an inline copy); the real E2 markers SKIPPED /
#               DECLARED-EMPTY / ENGAGED are present; the forbidden marker
#               spelling `RESOLVED` is absent (work-004 SPEC gate-fix history)
#   ST25-ST30   "no new scripts" (SPEC.md Note, work-004-connector-consumption)
#               -- every script path the two SKILL.md files / reconcile.md /
#               consumption-protocol.md reference resolves to one of the 3
#               pre-existing connector scripts (unchanged by this suite's own
#               later history); the scripts/connectors/ directory listing is a
#               closed set of the 3 pre-existing twins PLUS the one documented
#               exception -- `write-connector.sh`, introduced by a LATER, separate
#               work (feature-007-connectors-list, work-017 task-018) as the
#               dashboard-dispatchable, bash-only, non-interactive counterpart to
#               the two skills (SEC-4: the skills require AskUserQuestion/LLM
#               authoring, which the LLM-free dashboard server cannot invoke); no
#               OTHER stray script/template file exists under
#               canonical/aid/scripts/connectors/ or
#               canonical/aid/templates/connectors/
#   ST31-ST38   AC8 -- `## Connectors` is present (and substantively wired to
#               aid-set-connector/aid-unset-connector + MCP-first consumption)
#               in all 5 shipped profile context files, plus the dogfood root
#               CLAUDE.md
#
# Usage:
#   bash tests/canonical/test-connector-skills-structural.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SET_SKILL="${REPO_ROOT}/canonical/skills/aid-set-connector/SKILL.md"
UNSET_SKILL="${REPO_ROOT}/canonical/skills/aid-unset-connector/SKILL.md"
RECONCILE="${REPO_ROOT}/canonical/aid/templates/connectors/reconcile.md"
CONSUMPTION="${REPO_ROOT}/canonical/aid/templates/connectors/consumption-protocol.md"
ELICIT="${REPO_ROOT}/canonical/skills/aid-discover/references/state-elicit.md"
SHORTCUT_CATALOG="${REPO_ROOT}/canonical/aid/templates/shortcut-catalog.yml"
SCRIPTS_DIR="${REPO_ROOT}/canonical/aid/scripts/connectors"
TEMPLATES_DIR="${REPO_ROOT}/canonical/aid/templates/connectors"

for f in "$SET_SKILL" "$UNSET_SKILL" "$RECONCILE" "$CONSUMPTION" "$ELICIT" "$SHORTCUT_CATALOG"; do
    if [[ ! -f "$f" ]]; then
        fail "ST00 setup -- required file not found: $f"
        test_summary
        exit 1
    fi
done

echo "== connector skills structural guard tests =="

# assert_wrapped_contains FILE PATTERN LABEL -- like assert_file_contains, but
# tolerant of markdown's own line-wrapping: newlines and runs of whitespace
# are squashed to single spaces before the fixed-string search, so a phrase
# that happens to wrap across two source lines is still found. Used only for
# multi-word prose phrases below; single-token/short-phrase checks above use
# the shared assert_file_contains (which is NOT wrap-tolerant, by design --
# most of those phrases are guaranteed single-line, e.g. table cells).
assert_wrapped_contains() {
    local file="$1" pattern="$2" label="$3" squashed
    # Strip a leading markdown blockquote marker ("> ") per line first -- a
    # phrase that wraps across a `>`-quoted paragraph would otherwise gain a
    # stray "> " in the middle once newlines are squashed to spaces.
    squashed="$(sed -E 's/^>[[:space:]]*//' "$file" | tr '\n' ' ' | tr -s ' ')"
    if grep -qF -- "$pattern" <<< "$squashed"; then
        pass "$label"
    else
        fail "$label — pattern not found (line-wrap-tolerant): '$pattern' in $file"
    fi
}

# ===========================================================================
# ST01-ST04  aid-set-connector/SKILL.md signature.
# ===========================================================================
assert_file_contains "$SET_SKILL" "name: aid-set-connector" "ST01 aid-set-connector/SKILL.md frontmatter name"
assert_file_contains "$SET_SKILL" '<tool> <type> [--rotate-secret]' "ST02 aid-set-connector argument-hint covers <tool> <type> [--rotate-secret]"
assert_file_contains "$SET_SKILL" "AskUserQuestion" "ST03 aid-set-connector allowed-tools includes AskUserQuestion (interactive question-set)"
assert_file_contains "$SET_SKILL" "never invokes" "ST04 aid-set-connector documents that it never invokes /aid-discover"

# ===========================================================================
# ST05-ST08  aid-unset-connector/SKILL.md signature.
# ===========================================================================
assert_file_contains "$UNSET_SKILL" "name: aid-unset-connector" "ST05 aid-unset-connector/SKILL.md frontmatter name"
assert_file_contains "$UNSET_SKILL" 'argument-hint: "<tool>' "ST06 aid-unset-connector argument-hint covers <tool>"
assert_file_contains "$UNSET_SKILL" "never invokes" "ST07 aid-unset-connector documents that it never invokes /aid-discover"
assert_file_contains "$UNSET_SKILL" "idempotent" "ST08 aid-unset-connector documents idempotent removal (AC5)"

# ===========================================================================
# ST09-ST12  On-demand / off-pipeline positioning -- matches aid-config /
# aid-housekeep (neither of those appears in shortcut-catalog.yml either;
# this is the established pattern for optional, non-pipeline skills).
# ===========================================================================
assert_file_contains "$SET_SKILL" "Absent from the mandatory pipeline flow" "ST09 aid-set-connector documents itself as absent from the mandatory pipeline flow"
assert_file_contains "$UNSET_SKILL" "Absent from the mandatory pipeline flow" "ST10 aid-unset-connector documents itself as absent from the mandatory pipeline flow"
assert_file_not_contains "$SHORTCUT_CATALOG" "aid-set-connector" "ST11 aid-set-connector is NOT registered in shortcut-catalog.yml (on-demand, not a shortcut)"
assert_file_not_contains "$SHORTCUT_CATALOG" "aid-unset-connector" "ST12 aid-unset-connector is NOT registered in shortcut-catalog.yml (on-demand, not a shortcut)"

# ===========================================================================
# ST13-ST18  reconcile.md documents BOTH modes.
# ===========================================================================
assert_file_contains "$RECONCILE" "## Bulk mode (ELICIT)" "ST13 reconcile.md documents Bulk mode (ELICIT)"
assert_file_contains "$RECONCILE" "## Single-stem mode (set/unset)" "ST14 reconcile.md documents Single-stem mode (set/unset)"
assert_file_contains "$RECONCILE" "| ADD | \`stem" "ST15a reconcile.md's class table documents ADD"
assert_file_contains "$RECONCILE" "| UPDATE | \`stem" "ST15b reconcile.md's class table documents UPDATE"
assert_file_contains "$RECONCILE" "| NO-OP | \`stem" "ST15c reconcile.md's class table documents NO-OP"
assert_file_contains "$RECONCILE" "| REMOVE | \`stem" "ST15d reconcile.md's class table documents REMOVE"
assert_file_contains "$RECONCILE" 'stem ∈ P \ D' "ST16 reconcile.md documents the persisted-minus-declared (P \\ D) diff"
assert_file_contains "$RECONCILE" "No-collateral guarantee (AC6)" "ST17 reconcile.md documents the AC6 no-collateral guarantee"
assert_wrapped_contains "$RECONCILE" "never diffs against the rest of the registry" "ST18 reconcile.md's single-stem mode intro states it never diffs the whole registry"

# ===========================================================================
# ST19-ST24  AC7 -- ELICIT points at reconcile.md's bulk mode (relocated, not
# duplicated); the real E2 markers are present; the forbidden `RESOLVED`
# marker spelling is absent (work-004 SPEC GATE cycle-1 fix: "task-001 ELICIT
# marker RESOLVED -> ENGAGED").
# ===========================================================================
assert_file_contains "$ELICIT" "canonical/aid/templates/connectors/reconcile.md" \
    "ST19 state-elicit.md points to canonical/aid/templates/connectors/reconcile.md"
assert_file_contains "$ELICIT" 'Bulk mode (ELICIT)' \
    "ST20 state-elicit.md's pointer names reconcile.md's Bulk mode (ELICIT) section"
assert_wrapped_contains "$ELICIT" "relocated so it can also be reused by the net-new single-stem" \
    "ST21 state-elicit.md documents this as a relocation (behavior-preserving), not new logic"
assert_file_contains "$ELICIT" "SKIPPED" "ST22a state-elicit.md E2 marker table documents SKIPPED"
assert_file_contains "$ELICIT" "DECLARED-EMPTY" "ST22b state-elicit.md E2 marker table documents DECLARED-EMPTY"
assert_file_contains "$ELICIT" "ENGAGED" "ST22c state-elicit.md E2 marker table documents ENGAGED"
assert_file_not_contains "$ELICIT" "RESOLVED" \
    "ST23 state-elicit.md contains no 'RESOLVED' marker spelling (distinct from the unrelated 'Resolved:' frontmatter field)"
assert_file_contains "$RECONCILE" "R0-R5; feature-006 orchestration" \
    "ST24 reconcile.md's bulk mode documents the R0-R5 step numbering ELICIT's own text also cites"

# ===========================================================================
# ST25-ST30  "No new scripts" (SPEC.md's own Note, work-004-connector-consumption)
# -- every script reference in the two skills' / reconcile.md's / consumption-
# protocol.md's markdown resolves to one of the 3 pre-existing connector
# scripts; the scripts/connectors/ directory is a closed set of those 3 twins
# PLUS the one later, documented exception (write-connector.sh, feature-007-
# connectors-list / work-017 task-018 -- a deliberate bash-only, no-.ps1-twin
# script the LLM-free dashboard server dispatches; see that script's own header
# and DETAIL.md for the full rationale); no OTHER stray file exists under
# scripts/connectors/ or templates/connectors/.
# ===========================================================================
KNOWN_SCRIPT_BASES="connector-registry connector-secret build-connectors-index"

referenced_scripts="$(grep -ohE 'connectors/[A-Za-z0-9_-]+\.(sh|ps1)' \
    "$SET_SKILL" "$UNSET_SKILL" "$RECONCILE" "$CONSUMPTION" \
    | sed -E 's#^connectors/##' | sort -u)"

unexpected_script=""
while IFS= read -r ref; do
    [[ -z "$ref" ]] && continue
    base="${ref%.ps1}"; base="${base%.sh}"
    if ! grep -qw -- "$base" <<< "$KNOWN_SCRIPT_BASES"; then
        unexpected_script="${unexpected_script}${ref} "
    fi
done <<< "$referenced_scripts"

assert_eq "$unexpected_script" "" \
    "ST25 every script the new markdown references is one of the 3 known connector scripts (no new script introduced)"

script_files="$(cd "$SCRIPTS_DIR" && ls -1 | sort | tr '\n' ' ')"
assert_eq "$script_files" "build-connectors-index.ps1 build-connectors-index.sh connector-registry.ps1 connector-registry.sh connector-secret.ps1 connector-secret.sh write-connector.sh " \
    "ST26 canonical/aid/scripts/connectors/ contains exactly the 6 pre-existing files (3 scripts x 2 twins) plus the one documented exception (write-connector.sh, feature-007/task-018) -- no OTHER new script file"

template_files="$(cd "$TEMPLATES_DIR" && ls -1 | sort | tr '\n' ' ')"
assert_eq "$template_files" "consumption-protocol.md preset-catalog.md reconcile.md ticket-resolution.md " \
    "ST27 canonical/aid/templates/connectors/ contains exactly the 4 expected reference docs (incl. the shared ticket-resolution.md), no stray file"

assert_file_contains "$SET_SKILL" "No new script is introduced by this skill" \
    "ST28 aid-set-connector/SKILL.md's Reused scripts section states no new script is introduced"
assert_wrapped_contains "$UNSET_SKILL" "No new script is introduced by this skill" \
    "ST29 aid-unset-connector/SKILL.md's Reused scripts section states no new script is introduced"
assert_file_contains "$RECONCILE" "adds no new twin, builder, or wiring code" \
    "ST30 reconcile.md itself states it adds no new twin/builder/wiring code"

# ===========================================================================
# ST31-ST38  AC8 -- `## Connectors` present + substantively wired in all 5
# shipped profile context files, plus the dogfood root CLAUDE.md. Byte-
# identity across the four AGENTS.md is asserted elsewhere
# (test-agents-md-invariant.sh AG02) -- NOT re-checked here.
# ===========================================================================
PROFILE_CONTEXT_FILES=(
    "profiles/claude-code/CLAUDE.md"
    "profiles/codex/AGENTS.md"
    "profiles/cursor/AGENTS.md"
    "profiles/copilot-cli/AGENTS.md"
    "profiles/antigravity/AGENTS.md"
)

for rel in "${PROFILE_CONTEXT_FILES[@]}"; do
    f="${REPO_ROOT}/${rel}"
    assert_file_contains "$f" "## Connectors" "ST31 ${rel} has a ## Connectors section"
    assert_file_contains "$f" "aid-set-connector" "ST32 ${rel} ## Connectors mentions aid-set-connector"
    assert_file_contains "$f" "aid-unset-connector" "ST33 ${rel} ## Connectors mentions aid-unset-connector"
    assert_file_contains "$f" "MCP-first" "ST34 ${rel} ## Connectors documents MCP-first consumption"
    assert_file_contains "$f" "consumption-protocol.md" "ST35 ${rel} ## Connectors points to consumption-protocol.md"
done

DOGFOOD_CLAUDE_MD="${REPO_ROOT}/CLAUDE.md"
assert_file_exists "$DOGFOOD_CLAUDE_MD" "ST36 dogfood root CLAUDE.md exists"
assert_file_contains "$DOGFOOD_CLAUDE_MD" "## Connectors" "ST37 dogfood root CLAUDE.md has a ## Connectors section"
assert_file_contains "$DOGFOOD_CLAUDE_MD" "aid-set-connector" "ST38 dogfood root CLAUDE.md ## Connectors mentions aid-set-connector"

# ===========================================================================
test_summary
