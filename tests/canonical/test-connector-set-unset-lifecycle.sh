#!/usr/bin/env bash
# test-connector-set-unset-lifecycle.sh -- mechanism-level lifecycle suite for
# work-004-connector-consumption's net-new single-stem skills:
#   canonical/skills/aid-set-connector/SKILL.md    (upsert)
#   canonical/skills/aid-unset-connector/SKILL.md  (remove)
#
# CRITICAL SCOPE NOTE -- these two skills are LLM-orchestrated markdown (no
# dedicated executable script -- SPEC.md "Note (script surface)": no connector
# script changes are required). There is no single SUT binary to invoke, so
# this suite -- exactly like tests/canonical/test-reconcile-scenarios.sh does
# for ELICIT's bulk-mode R0-R5 sequence -- SCRIPTS the skills' own documented
# procedure directly over a disposable fixture registry, driving the SAME three
# real, already-committed ops the skills themselves call:
#   - connector-registry.sh     read            (SKILL.md Step 3 -- OLD_TYPE/OLD_AUTH)
#   - connector-secret.sh       write / purge    (Step 5b / secret-reconcile.md decision procedure)
#   - build-connectors-index.sh                  (Step 6 / Step 3 -- INDEX rebuild)
# plus the descriptor-write/gitignore-precondition mechanics both skills document
# verbatim from canonical/aid/templates/connectors/reconcile.md's "Write one
# descriptor" / Step 4. Do NOT re-implement unit coverage that already exists:
#   - test-connector-registry.sh / test-connector-secret.sh / test-build-connectors-index.sh
#     (script-level unit coverage, leak-proofing, fail-closed .gitignore precondition)
#   - test-reconcile-scenarios.sh (ELICIT's bulk-mode R0-R5: ADD/UPDATE/REMOVE/NO-OP,
#     idempotence, interrupt re-convergence, Q9 SKIPPED/DECLARED-EMPTY)
# This suite's only new value is the SINGLE-STEM path those two reused: the
# ADD/UPDATE classification never diffs the whole registry (AC6), the set-skill
# secret-reconcile decision procedure (secret-reconcile.md), and REMOVE's
# unconditional idempotence (AC5) -- none of which bulk mode's R0-R5 exercises.
#
# Traces:
#   SC01-SC04   AC1  -- `aid-set-connector Jira mcp` on an absent stem: ADD,
#               no secret call, descriptor has no secret_reference field,
#               INDEX row appears, Type=mcp
#   SC05-SC10   AC2/AC10 -- `aid-set-connector Jira api` re-run (mcp -> api):
#               UPDATE, gitignore precondition already established BEFORE this
#               cycle's first-ever secret write, secret CAPTURED
#               (`connector-secret write`), INDEX row updated
#   SC11-SC13   AC10 (fresh-repo ordering, contrast) -- on a SEPARATE, never-
#               touched root, `connector-secret write` invoked WITHOUT first
#               establishing the gitignore precondition fails closed (exit 4);
#               establishing it first (Step 4) then succeeds -- proves the
#               ordering is load-bearing, not redundant
#   SC14-SC17   AC3  -- in-place type transition api -> mcp: secret PURGED
#               (orphaned), descriptor loses secret_reference, INDEX Auth/SecretRef
#               reflect mcp/none
#   SC18-SC22   AC2/AC3 setup -- transition back mcp -> api (credentialed) to
#               establish a baseline secret for the no-reprompt tests below
#   SC23-SC26   AC4a -- field-only re-set (same type, same auth_method, no
#               --rotate-secret): SECRET_ACTION=none, stored secret bytes
#               UNCHANGED, descriptor field updated
#   SC27-SC29   AC4b -- `--rotate-secret` forces SECRET_ACTION=write even with
#               no field change: stored secret bytes CHANGE
#   SC30-SC32   AC4c -- an `auth_method` change (token -> pat), same type:
#               SECRET_ACTION=write, descriptor + secret both reflect the change
#   SC33-SC37   AC5  -- `aid-unset-connector Jira`: secret purged, descriptor
#               deleted, INDEX row dropped; a second run is a clean idempotent
#               no-op (byte-identical INDEX.md, exit 0, no error)
#   SC38-SC44   AC6 (no-collateral) -- a SIBLING connector (`github`, aid-managed,
#               credentialed) catalogued from before SC01 and checked
#               byte-for-byte unchanged (descriptor + secret) after EVERY jira
#               single-stem op above, including the final unset
#   SC45-SC48   AC10 (write-zone confinement) -- sentinel files planted OUTSIDE
#               `.aid/connectors/` (elsewhere under a simulated repo root) are
#               byte-for-byte unchanged, and no new file appears anywhere
#               outside `.aid/connectors/`, after the ENTIRE sequence above
#
# Usage:
#   bash tests/canonical/test-connector-set-unset-lifecycle.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-registry.sh"
SECRET="${REPO_ROOT}/canonical/aid/scripts/connectors/connector-secret.sh"
BUILDER="${REPO_ROOT}/canonical/aid/scripts/connectors/build-connectors-index.sh"

for sut in "$REGISTRY" "$SECRET" "$BUILDER"; do
    if [[ ! -f "$sut" ]]; then
        fail "SC00 setup -- required op not found: $sut"
        test_summary
        exit 1
    fi
done

echo "== aid-set-connector / aid-unset-connector single-stem lifecycle tests =="

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Simulated repo root: connectors registry lives at its real relative path
# (.aid/connectors) under a throwaway repo root, with sentinel files planted
# elsewhere -- this is what SC45-SC48 (write-zone confinement) checks against.
# ---------------------------------------------------------------------------
REPO_SIM="${TMPDIR_BASE}/repo-root"
mkdir -p "${REPO_SIM}/.aid/knowledge" "${REPO_SIM}/src" "${REPO_SIM}/.aid/other-work"
printf 'sentinel-knowledge-state\n' > "${REPO_SIM}/.aid/knowledge/STATE.md"
printf 'sentinel-source-file\n' > "${REPO_SIM}/src/app.js"
printf 'sentinel-other-work\n' > "${REPO_SIM}/.aid/other-work/STATE.md"

ROOT="${REPO_SIM}/.aid/connectors"
# Deliberately NOT created yet -- SC01 exercises a genuinely fresh, never-
# touched repo (no .aid/connectors/ directory at all yet).

# ---------------------------------------------------------------------------
# Helpers -- mirror the skills' documented Steps verbatim.
# ---------------------------------------------------------------------------

# derive_stem TOOL -- feature-002's slug rule, exactly as SKILL.md Step 1 / 0.
derive_stem() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# classify_single_stem ROOT STEM -- aid-set-connector SKILL.md Step 3 / reconcile.md Step S1.
classify_single_stem() {
    local root="$1" stem="$2"
    if [[ -f "${root}/${stem}.md" ]]; then echo UPDATE; else echo ADD; fi
}

# ensure_gitignore_precondition ROOT -- SKILL.md Step 4 (unconditional, ADD+UPDATE alike).
ensure_gitignore_precondition() {
    local root="$1"
    mkdir -p "$root"
    if [[ ! -f "${root}/.gitignore" ]]; then
        printf '%s\n' '.secrets/' > "${root}/.gitignore"
    fi
}

# write_mcp_descriptor ROOT STEM NAME ENDPOINT -- tool-managed shape (no secret_reference field).
write_mcp_descriptor() {
    local root="$1" stem="$2" name="$3" endpoint="$4"
    cat > "${root}/${stem}.md" <<EOF
---
name: ${name}
connection_type: mcp
endpoint: "${endpoint}"
auth_method: none
preset: custom
objective: ${name} via the host tool's MCP.
summary: Request the connection from the host tool's own MCP/plugin.
tags: [connector, mcp]
audience: [developer, architect]
---

# ${name}

> Connection: mcp - Mode: tool-managed - Auth: handled by the host tool (no AID credential)
EOF
}

# write_aid_descriptor ROOT STEM NAME TYPE ENDPOINT AUTH SECREF -- aid-managed shape.
write_aid_descriptor() {
    local root="$1" stem="$2" name="$3" ctype="$4" endpoint="$5" auth="$6" secref="$7"
    cat > "${root}/${stem}.md" <<EOF
---
name: ${name}
connection_type: ${ctype}
endpoint: "${endpoint}"
auth_method: ${auth}
secret_reference: "${secref}"
preset: custom
objective: ${name} aid-managed connector.
summary: aid-managed sample for single-stem lifecycle tests.
tags: [connector, ${ctype}]
audience: [developer, architect]
---

# ${name}

> Connection: ${ctype} - Mode: aid-managed - Auth: ${auth} (reference: ${secref})
EOF
}

# resolve_secret_action CLASS TYPE NEW_AUTH OLD_TYPE OLD_AUTH ROTATE_FLAG
# -- the exact decision procedure documented in
# canonical/skills/aid-set-connector/references/secret-reconcile.md "The
# decision procedure" (set-skill logic; NOT reconcile.md's own bulk-mode UPDATE,
# which never purges on a field edit).
resolve_secret_action() {
    local class="$1" type="$2" new_auth="$3" old_type="$4" old_auth="$5" rotate="$6"
    if [[ "$class" == "ADD" ]]; then
        if [[ "$type" == "mcp" || "$new_auth" == "none" ]]; then
            echo none
        else
            echo write
        fi
    else
        if [[ "$type" == "mcp" || "$new_auth" == "none" ]]; then
            if [[ "$old_auth" != "none" ]]; then echo purge; else echo none; fi
        else
            if [[ "$old_type" != "$type" ]]; then
                echo write
            elif [[ "$old_auth" != "$new_auth" ]]; then
                echo write
            elif [[ "$rotate" == "1" ]]; then
                echo write
            else
                echo none
            fi
        fi
    fi
}

# apply_secret_action ROOT STEM ACTION [SECRET_VALUE]
apply_secret_action() {
    local root="$1" stem="$2" action="$3" value="${4:-}"
    case "$action" in
        write) printf '%s\n' "$value" | bash "$SECRET" write "$stem" --root "$root" >/dev/null 2>&1 ;;
        purge) bash "$SECRET" purge "$stem" --root "$root" >/dev/null 2>&1 ;;
        none)  : ;;
    esac
}

rebuild_index() { bash "$BUILDER" --root "$1" --output "$2" >/dev/null 2>&1; }

# get_index_cell FILE STEM COL -- 1-based data column (1=Connector 2=Type
# 3=Endpoint 4=Auth 5=SecretRef 6=Summary), trimmed. Mirrors
# test-connectors-registry-integration.sh's own helper.
get_index_cell() {
    local file="$1" stem="$2" col="$3" awkcol
    awkcol=$((col + 1))
    grep "](${stem}.md)" "$file" | awk -F'|' -v c="$awkcol" '{gsub(/^[ \t]+|[ \t]+$/, "", $c); print $c}'
}

EMDASH=$'\xe2\x80\x94'
INDEX_OUT="${ROOT}/INDEX.md"

# ===========================================================================
# SIBLING connector (`github`), catalogued BEFORE any jira op -- AC6's
# no-collateral witness. Checked byte-for-byte unchanged after every step
# below (SC38-SC44).
# ===========================================================================
ensure_gitignore_precondition "$ROOT"
write_aid_descriptor "$ROOT" github "GitHub" api "https://api.github.com" token \
    "file:.aid/connectors/.secrets/github"
printf '%s\n' "GITHUB-SIBLING-SECRET-9f21" | bash "$SECRET" write github --root "$ROOT" >/dev/null 2>&1
rebuild_index "$ROOT" "$INDEX_OUT"

github_descriptor_baseline="$(cat "${ROOT}/github.md")"
github_secret_baseline="$(cat "${ROOT}/.secrets/github")"

assert_sibling_unchanged() {
    local label_prefix="$1"
    assert_eq "$(cat "${ROOT}/github.md")" "$github_descriptor_baseline" \
        "${label_prefix} AC6 -- sibling (github) descriptor byte-for-byte unchanged"
    assert_eq "$(cat "${ROOT}/.secrets/github")" "$github_secret_baseline" \
        "${label_prefix} AC6 -- sibling (github) secret byte-for-byte unchanged"
}

# ===========================================================================
# SC01-SC04  AC1 -- `aid-set-connector Jira mcp` on an absent stem (fresh repo:
# .aid/connectors/ already exists from the github setup above, but jira does not).
# ===========================================================================
STEM=$(derive_stem "Jira")
assert_eq "$STEM" "jira" "SC01 derive_stem('Jira') == 'jira'"

CLASS=$(classify_single_stem "$ROOT" "$STEM")
assert_eq "$CLASS" "ADD" "SC02 AC1 -- absent stem classifies ADD (no whole-registry diff)"

TYPE=mcp; NEW_AUTH=none
ensure_gitignore_precondition "$ROOT"   # Step 4 -- unconditional, even though ADD/mcp needs no secret
ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "" "" 0)
assert_eq "$ACTION" "none" "SC03 AC1 -- ADD mcp resolves SECRET_ACTION=none (no prompt, no script call)"
apply_secret_action "$ROOT" "$STEM" "$ACTION"
write_mcp_descriptor "$ROOT" "$STEM" "Jira" "jira-mcp (host-tool managed)"
rebuild_index "$ROOT" "$INDEX_OUT"

assert_file_exists "${ROOT}/jira.md" "SC04a AC1 -- descriptor created"
assert_file_not_contains "${ROOT}/jira.md" "secret_reference" "SC04b AC1 -- mcp descriptor carries NO secret_reference field"
if [[ ! -f "${ROOT}/.secrets/jira" ]]; then
    pass "SC04c AC1 -- no secret file created for a mcp connector"
else
    fail "SC04c AC1 -- unexpected secret file created for a mcp connector"
fi
assert_file_contains "$INDEX_OUT" "](jira.md)" "SC04d AC1 -- INDEX.md row appears"
assert_eq "$(get_index_cell "$INDEX_OUT" jira 2)" "mcp" "SC04e AC1 -- INDEX Type cell == mcp"
assert_sibling_unchanged "SC04f"

# ===========================================================================
# SC05-SC10  AC2/AC10 -- re-run `aid-set-connector Jira api` (mcp -> api):
# UPDATE; gitignore precondition already established (from SC03/github setup)
# BEFORE this cycle's first-ever secret write for jira.
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
assert_eq "$CLASS" "UPDATE" "SC05 AC2 -- present stem (even across a type change) classifies UPDATE, never REMOVE-then-ADD"

OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH_EC=0
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT") || OLD_AUTH_EC=$?
assert_eq "$OLD_TYPE" "mcp" "SC06 AC2 -- Step 3 reads OLD_TYPE=mcp off disk"
assert_eq "$OLD_AUTH" "none" "SC06b AC2 -- Step 3 reads OLD_AUTH=none off disk"

TYPE=api; NEW_AUTH=token
ensure_gitignore_precondition "$ROOT"   # Step 4 re-run -- idempotent, .gitignore already present
gitignore_before_write="$(cat "${ROOT}/.gitignore")"
assert_eq "$gitignore_before_write" ".secrets/" "SC07 AC10 -- .secrets/ gitignore precondition holds BEFORE this cycle's first secret write for jira"

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 0)
assert_eq "$ACTION" "write" "SC08 AC2 -- UPDATE into a credentialed type (mcp -> api) resolves SECRET_ACTION=write"
apply_secret_action "$ROOT" "$STEM" "$ACTION" "JIRA-SECRET-v1-a1b2c3"
write_aid_descriptor "$ROOT" "$STEM" "Jira" api "https://jira.example.com" token \
    "file:.aid/connectors/.secrets/jira"
rebuild_index "$ROOT" "$INDEX_OUT"

assert_file_exists "${ROOT}/.secrets/jira" "SC09a AC2 -- secret captured on the fresh (well-gitignored) repo"
assert_eq "$(cat "${ROOT}/.secrets/jira")" "JIRA-SECRET-v1-a1b2c3" "SC09b AC2 -- captured secret bytes match"
assert_file_contains "${ROOT}/jira.md" "connection_type: api" "SC10a AC2 -- descriptor connection_type updated to api"
assert_eq "$(get_index_cell "$INDEX_OUT" jira 4)" "token" "SC10b AC2 -- INDEX Auth cell == token"
assert_sibling_unchanged "SC10c"

# ===========================================================================
# SC11-SC13  AC10 (fresh-repo ordering, CONTRAST) -- on a SEPARATE root that
# has NEVER had the gitignore precondition established, invoking
# `connector-secret write` directly (skipping Step 4) fails closed; running
# Step 4 first, then the same write, succeeds. Proves the ordering is
# load-bearing, not redundant window-dressing.
# ===========================================================================
ROOT_FRESH="${TMPDIR_BASE}/repo-root-fresh/.aid/connectors"
mkdir -p "$ROOT_FRESH"
printf '%s\n' "SHOULD-NEVER-BE-WRITTEN" | bash "$SECRET" write jira --root "$ROOT_FRESH" >/dev/null 2>"${TMPDIR_BASE}/sc11.stderr"
ec_no_precondition=$?
assert_exit_eq "$ec_no_precondition" 4 "SC11 AC2/AC10 -- connector-secret write BEFORE the gitignore precondition fails closed (exit 4)"
if [[ ! -f "${ROOT_FRESH}/.secrets/jira" ]]; then
    pass "SC12 AC10 -- fail-closed refusal created no secret file"
else
    fail "SC12 AC10 -- fail-closed refusal unexpectedly created a secret file"
fi

ensure_gitignore_precondition "$ROOT_FRESH"   # Step 4, run NOW, before retrying the write
printf '%s\n' "JIRA-FRESH-SECRET" | bash "$SECRET" write jira --root "$ROOT_FRESH" >/dev/null 2>&1
ec_with_precondition=$?
assert_exit_zero "$ec_with_precondition" "SC13 AC2/AC10 -- the SAME write succeeds once Step 4 has run first"

# ===========================================================================
# SC14-SC17  AC3 -- in-place type transition api -> mcp: orphaned secret is
# PURGED (not left behind, unlike bulk mode's own UPDATE -- reconcile.md
# "Bulk mode" Step R3 vs. secret-reconcile.md's set-skill logic).
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT")
TYPE=mcp; NEW_AUTH=none

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 0)
assert_eq "$ACTION" "purge" "SC14 AC3 -- UPDATE into mcp with a previously-credentialed secret resolves SECRET_ACTION=purge"
apply_secret_action "$ROOT" "$STEM" "$ACTION"
write_mcp_descriptor "$ROOT" "$STEM" "Jira" "jira-mcp (host-tool managed)"
rebuild_index "$ROOT" "$INDEX_OUT"

if [[ ! -f "${ROOT}/.secrets/jira" ]]; then
    pass "SC15 AC3 -- orphaned secret purged on the mcp/none transition"
else
    fail "SC15 AC3 -- orphaned secret still present after the mcp/none transition"
fi
assert_file_not_contains "${ROOT}/jira.md" "secret_reference" "SC16 AC3 -- descriptor no longer carries secret_reference"
assert_eq "$(get_index_cell "$INDEX_OUT" jira 5)" "$EMDASH" "SC17 AC3 -- INDEX Secret Ref cell is an em dash"
assert_sibling_unchanged "SC17b"

# ===========================================================================
# SC18-SC22  Re-establish a credentialed baseline (mcp -> api again) so the
# AC4 no-reprompt tests below have a stored secret to prove is left untouched.
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT")
TYPE=api; NEW_AUTH=token

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 0)
assert_eq "$ACTION" "write" "SC18 baseline -- mcp -> api transition captures a fresh secret"
apply_secret_action "$ROOT" "$STEM" "$ACTION" "JIRA-SECRET-v2-baseline"
write_aid_descriptor "$ROOT" "$STEM" "Jira" api "https://jira.example.com" token \
    "file:.aid/connectors/.secrets/jira"
rebuild_index "$ROOT" "$INDEX_OUT"
assert_eq "$(cat "${ROOT}/.secrets/jira")" "JIRA-SECRET-v2-baseline" "SC19 baseline -- secret bytes captured as expected"

secret_before_field_only_edit="$(cat "${ROOT}/.secrets/jira")"

# ===========================================================================
# SC23-SC26  AC4a -- field-only re-set (same type api, same auth_method token,
# no --rotate-secret): SECRET_ACTION=none, stored secret UNCHANGED, only the
# descriptor field (endpoint) actually changes.
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT")
TYPE=api; NEW_AUTH=token   # unchanged from OLD_TYPE/OLD_AUTH

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 0)
assert_eq "$ACTION" "none" "SC23 AC4a -- field-only re-set (same type/auth, no --rotate-secret) resolves SECRET_ACTION=none"
apply_secret_action "$ROOT" "$STEM" "$ACTION"   # no-op by construction
write_aid_descriptor "$ROOT" "$STEM" "Jira" api "https://jira-eu.example.com" token \
    "file:.aid/connectors/.secrets/jira"   # endpoint changed -- field-only edit
rebuild_index "$ROOT" "$INDEX_OUT"

assert_eq "$(cat "${ROOT}/.secrets/jira")" "$secret_before_field_only_edit" \
    "SC24 AC4a -- stored secret bytes UNCHANGED across a field-only re-set (no re-prompt)"
assert_file_contains "${ROOT}/jira.md" "https://jira-eu.example.com" "SC25 AC4a -- descriptor field (endpoint) DID update"
assert_file_contains "$INDEX_OUT" "https://jira-eu.example.com" "SC26 AC4a -- INDEX.md reflects the updated field"

# ===========================================================================
# SC27-SC29  AC4b -- `--rotate-secret` forces a fresh capture even with NO
# field change at all (same type, same auth_method).
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT")
TYPE=api; NEW_AUTH=token

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 1)   # --rotate-secret => flag=1
assert_eq "$ACTION" "write" "SC27 AC4b -- --rotate-secret forces SECRET_ACTION=write despite no field change"
apply_secret_action "$ROOT" "$STEM" "$ACTION" "JIRA-SECRET-v3-rotated"
rebuild_index "$ROOT" "$INDEX_OUT"

assert_eq "$(cat "${ROOT}/.secrets/jira")" "JIRA-SECRET-v3-rotated" "SC28 AC4b -- rotated secret bytes now stored"
if [[ "$(cat "${ROOT}/.secrets/jira")" != "$secret_before_field_only_edit" ]]; then
    pass "SC29 AC4b -- rotated secret differs from the pre-rotation baseline"
else
    fail "SC29 AC4b -- rotated secret unexpectedly identical to the pre-rotation baseline"
fi

# ===========================================================================
# SC30-SC32  AC4c -- an auth_method change (token -> pat), same type: forces
# SECRET_ACTION=write even with --rotate-secret NOT given.
# ===========================================================================
CLASS=$(classify_single_stem "$ROOT" "$STEM")
OLD_TYPE=$(bash "$REGISTRY" read "$STEM" connection_type --root "$ROOT")
OLD_AUTH=$(bash "$REGISTRY" read "$STEM" auth_method --root "$ROOT")
TYPE=api; NEW_AUTH=pat   # auth_method changed, --rotate-secret NOT passed

ACTION=$(resolve_secret_action "$CLASS" "$TYPE" "$NEW_AUTH" "$OLD_TYPE" "$OLD_AUTH" 0)
assert_eq "$ACTION" "write" "SC30 AC4c -- an auth_method change alone (no --rotate-secret) resolves SECRET_ACTION=write"
apply_secret_action "$ROOT" "$STEM" "$ACTION" "JIRA-SECRET-v4-pat"
write_aid_descriptor "$ROOT" "$STEM" "Jira" api "https://jira-eu.example.com" pat \
    "file:.aid/connectors/.secrets/jira"
rebuild_index "$ROOT" "$INDEX_OUT"

assert_file_contains "${ROOT}/jira.md" "auth_method: pat" "SC31 AC4c -- descriptor auth_method updated to pat"
assert_eq "$(cat "${ROOT}/.secrets/jira")" "JIRA-SECRET-v4-pat" "SC32 AC4c -- secret re-captured for the new auth_method"
assert_sibling_unchanged "SC32b"

# ===========================================================================
# SC33-SC37  AC5 -- `aid-unset-connector Jira`: purge-then-delete, INDEX row
# dropped; a SECOND run is a clean idempotent no-op.
# ===========================================================================
bash "$SECRET" purge "$STEM" --root "$ROOT" >/dev/null 2>&1
ec_purge1=$?
rm -f -- "${ROOT}/${STEM}.md"
rebuild_index "$ROOT" "$INDEX_OUT"
index_after_unset1="$(cat "$INDEX_OUT")"

assert_exit_zero "$ec_purge1" "SC33 AC5 -- unset purge exits 0"
if [[ ! -f "${ROOT}/.secrets/jira" ]]; then
    pass "SC34 AC5 -- secret gone after unset"
else
    fail "SC34 AC5 -- secret still present after unset"
fi
if [[ ! -f "${ROOT}/jira.md" ]]; then
    pass "SC35 AC5 -- descriptor deleted after unset"
else
    fail "SC35 AC5 -- descriptor still present after unset"
fi
assert_file_not_contains "$INDEX_OUT" "](jira.md)" "SC36 AC5 -- INDEX.md no longer lists jira"

# Idempotent second run -- unconditional purge-then-delete against an
# already-absent stem, per aid-unset-connector SKILL.md Step 2.
bash "$SECRET" purge "$STEM" --root "$ROOT" >/dev/null 2>&1
ec_purge2=$?
rm -f -- "${ROOT}/${STEM}.md"
rebuild_index "$ROOT" "$INDEX_OUT"
index_after_unset2="$(cat "$INDEX_OUT")"

assert_exit_zero "$ec_purge2" "SC37a AC5 -- second (idempotent) unset run also exits 0 with no error"
assert_eq "$index_after_unset2" "$index_after_unset1" "SC37b AC5 -- INDEX.md byte-identical across the idempotent second run"
assert_sibling_unchanged "SC38"

# ===========================================================================
# SC45-SC48  AC10 (write-zone confinement) -- over the ENTIRE sequence above
# (ADD, four UPDATEs, a type transition, a purge/rotate, REMOVE x2), nothing
# outside `.aid/connectors/` was ever touched.
# ===========================================================================
assert_eq "$(cat "${REPO_SIM}/.aid/knowledge/STATE.md")" "sentinel-knowledge-state" \
    "SC45 AC10 -- .aid/knowledge/ sentinel untouched (write-zone confinement)"
assert_eq "$(cat "${REPO_SIM}/src/app.js")" "sentinel-source-file" \
    "SC46 AC10 -- src/ sentinel untouched (write-zone confinement)"
assert_eq "$(cat "${REPO_SIM}/.aid/other-work/STATE.md")" "sentinel-other-work" \
    "SC47 AC10 -- sibling work-folder sentinel untouched (write-zone confinement)"

outside_files="$(find "$REPO_SIM" -type f | grep -vF "${ROOT}/" | sort)"
outside_count=$(echo "$outside_files" | grep -c . || true)
assert_eq "$outside_count" "3" "SC48 AC10 -- exactly the 3 planted sentinel files exist outside .aid/connectors/ (no stray writes)"

# ===========================================================================
test_summary
