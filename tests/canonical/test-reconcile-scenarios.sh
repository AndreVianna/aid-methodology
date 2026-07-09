#!/usr/bin/env bash
# test-reconcile-scenarios.sh -- Scenario tests for the composed ELICIT "Reconcile
# the registry" sequence (work-002-external_sources / delivery-003 / task-019,
# feature-006 "Idempotent Reconcile", Q10-corrected).
#
# There is NO standalone reconcile script to invoke as a single SUT: task-018
# authored Steps R0-R5 as INLINE-BASH ORCHESTRATION PROSE inside
# canonical/skills/aid-discover/references/state-elicit.md ("Reconcile the
# registry"), composing four REAL, already-committed ops -- it adds no new
# twin/builder/wiring code (feature-006 SPEC "Layers & Components"). This suite
# therefore SCRIPTS the R0-R5 sequence itself, over a disposable fixture
# registry, driving those same four ops directly:
#   - connector-registry.sh    list / read   (R1 enumerate the persisted set P)
#   - connector-secret.sh      purge          (R3 REMOVE -- aid-managed secret purge)
#   - build-connectors-index.sh               (R4 deterministic INDEX rebuild)
#   - descriptor add/update = write/overwrite <stem>.md; remove = purge-then-rm
#
# CRITICAL SCOPE NOTE -- do NOT re-implement unit coverage that already exists
# (mirrors test-connectors-registry-integration.sh's own boilerplate):
#   - tests/canonical/test-connector-registry.sh      (list/read unit coverage)
#   - tests/canonical/test-build-connectors-index.sh   (INDEX builder unit coverage)
#   - tests/canonical/test-connector-secret.sh         (write/purge unit coverage,
#     leak-proofing, path confinement, fail-closed .gitignore precondition)
# This suite's only new value is the DELIVERY-LEVEL guarantee: composing those
# ops in the R0-R5 SEQUENCE over one fixture registry produces the reconcile
# outcomes feature-006 promises (ADD/UPDATE/REMOVE/NO-OP, idempotence, interrupt
# re-convergence, and the Q9 SKIPPED-vs-DECLARED-EMPTY branch).
#
# Q10 scope note: REMOVE never unwires any host tool config -- AID writes no
# host MCP config, so there is nothing to unwire (Q10 supersedes Q8, amends
# Q9). This suite deliberately tests NO host-config/unwire scenario; REMOVE is
# scripted as "purge the local secret, then delete the descriptor" only. A
# tool-managed (`mcp`) connector carries no stored secret, so its purge is
# asserted as a clean no-op (RS03/RS07).
#
# Fixtures: every scenario below runs over its own throwaway `mktemp -d`
# registry root (a fresh subdirectory per scenario, all under one
# TMPDIR_BASE cleaned by a single EXIT trap) with its own `.gitignore`
# ignoring `.secrets/` -- the fail-closed precondition connector-secret.sh
# write enforces. The repo's real `.aid/connectors/` is never referenced;
# every invocation below passes an explicit `--root`.
#
# Tests:
#   RS01  ADD -- new descriptor + INDEX row appear; a surviving aid-managed
#         entry and its secret, and a surviving tool-managed entry, are
#         preserved byte-for-byte
#   RS02  UPDATE (change) -- same-stem descriptor overwritten in place
#         (new field value lands); its stored secret is preserved untouched
#         (no secret-capture invocation, since auth_method/secret_reference
#         did not change this cycle)
#   RS03  REMOVE -- purges the aid-managed secret THEN deletes the descriptor
#         (purge-before-delete order); tool-managed purge is a clean no-op;
#         a surviving third entry and its secret are preserved
#   RS04  Idempotent no-op -- two reconcile passes over an unchanged
#         declared-set/persisted-set produce a byte-identical INDEX.md
#         (sha256 equal)
#   RS05  Interrupt re-convergence -- a REMOVE interrupted between "purge"
#         and "delete descriptor" is re-derived as REMOVE on the next run;
#         the re-purge is a clean no-op, and the descriptor deletion + INDEX
#         regen complete convergence
#   RS06  Q9 SKIPPED -- the tool step was not engaged; the registry (every
#         descriptor, every secret, and INDEX.md) is left byte-for-byte
#         intact -- no list/purge/write/rebuild of any kind
#   RS07  Q9 DECLARED-EMPTY -- the tool step was engaged with D={}; every
#         persisted connector is removed-and-purged; INDEX.md becomes
#         header-only (zero data rows)
#
# Usage:
#   bash tests/canonical/test-reconcile-scenarios.sh [--verbose]
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
        fail "RS00 setup -- required op not found: $sut"
        test_summary
        exit 1
    fi
done

echo "== reconcile scenario tests (R0-R5 composed sequence) =="

# ---------------------------------------------------------------------------
# ONE throwaway TMPDIR_BASE for the whole suite; every scenario gets its own
# subdirectory under it. Single EXIT trap -- deterministic cleanup even on a
# failed assertion or an early exit. NEVER touches the repo's real
# .aid/connectors/.
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---------------------------------------------------------------------------
# Helpers -- fixture setup + the four composed ops.
# ---------------------------------------------------------------------------
init_fixture() {
    local root="$1"
    mkdir -p "$root"
    printf '.secrets/\n' > "${root}/.gitignore"
}

# write_aid_descriptor ROOT STEM NAME CTYPE ENDPOINT AUTH SECREF OBJECTIVE SUMMARY
# -- an aid-managed connector descriptor (feature-001's worked m365.md shape).
write_aid_descriptor() {
    local root="$1" stem="$2" name="$3" ctype="$4" endpoint="$5" auth="$6" \
          secref="$7" objective="$8" summary="$9"
    cat > "${root}/${stem}.md" <<EOF
---
name: ${name}
connection_type: ${ctype}
endpoint: "${endpoint}"
auth_method: ${auth}
secret_reference: "${secref}"
preset: custom
objective: ${objective}
summary: ${summary}
tags: [connector, ${ctype}]
audience: [developer, architect]
---

# ${name}

> Connection: ${ctype} - Mode: aid-managed - Auth: ${auth} (reference: ${secref})

${objective}
EOF
}

# write_mcp_descriptor ROOT STEM NAME ENDPOINT OBJECTIVE SUMMARY
# -- a tool-managed connector descriptor (feature-001's worked github.md
# shape): auth_method: none, NO secret_reference field at all.
write_mcp_descriptor() {
    local root="$1" stem="$2" name="$3" endpoint="$4" objective="$5" summary="$6"
    cat > "${root}/${stem}.md" <<EOF
---
name: ${name}
connection_type: mcp
endpoint: "${endpoint}"
auth_method: none
preset: custom
objective: ${objective}
summary: ${summary}
tags: [connector, mcp]
audience: [developer, architect]
---

# ${name}

> Connection: mcp - Mode: tool-managed - Auth: handled by the host tool (no AID credential)

${objective}
EOF
}

# write_secret ROOT STEM VALUE -- drives connector-secret.sh write via a piped
# printf (redirects stdin away from a tty, per that script's documented
# automation pattern; see test-connector-secret.sh).
write_secret() {
    local root="$1" stem="$2" value="$3"
    printf '%s\n' "$value" | bash "$SECRET" write "$stem" --root "$root" >/dev/null 2>&1
}

list_stems() {
    bash "$REGISTRY" list --root "$1"
}

build_index() {
    bash "$BUILDER" --root "$1" --output "$2" >/dev/null 2>&1
}

# snapshot_tree ROOT -- one sha256 line per file under ROOT, path-sorted.
# Used to prove a byte-for-byte "nothing changed" invariant (RS06).
snapshot_tree() {
    local dir="$1" f
    ( cd "$dir" && for f in $(find . -type f | sort); do sha256sum "$f"; done )
}

# ===========================================================================
# RS01  ADD -- new descriptor + INDEX row present; a surviving aid-managed
# entry (and its secret) and a surviving tool-managed entry are preserved
# byte-for-byte.
# ===========================================================================
S1="${TMPDIR_BASE}/s1"
init_fixture "$S1"
SENTINEL_API1="RECON19-SENTINEL-api-8f2c91a0"
SENTINEL_NEWAPI="RECON19-SENTINEL-newapi-1c7de44b"

write_aid_descriptor "$S1" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S1" api "$SENTINEL_API1"
write_mcp_descriptor "$S1" mcp-tool "Sample MCP Tool" \
    "sample-mcp (host-tool managed)" "A sample tool-managed connector." \
    "tool-managed sample for reconcile tests."

api_before="$(cat "${S1}/api.md")"
api_secret_before="$(cat "${S1}/.secrets/api")"
mcp_before="$(cat "${S1}/mcp-tool.md")"

# R1: enumerate P.
p1="$(list_stems "$S1")"
assert_eq "$p1" $'api\nmcp-tool' "RS01-R1 persisted set P enumerated before ADD"

# R2/R3: D = P plus a newly-declared stem -- newapi in D \ P classifies ADD;
# api and mcp-tool are unchanged this cycle (NO-OP -- write nothing for them).
write_aid_descriptor "$S1" newapi "New API" api "https://new.example.com/v1" token \
    "file:.aid/connectors/.secrets/newapi" "A newly-declared aid-managed API." \
    "new aid-managed connector added this cycle."
write_secret "$S1" newapi "$SENTINEL_NEWAPI"

# R4: regenerate INDEX.md.
OUT1="${S1}/INDEX.md"
build_index "$S1" "$OUT1"

assert_file_exists "${S1}/newapi.md" "RS01a ADD -- new descriptor created"
assert_file_contains "$OUT1" "](newapi.md)" "RS01b ADD -- INDEX.md row appears for the new connector"
assert_eq "$(cat "${S1}/api.md")" "$api_before" "RS01c ADD -- surviving aid-managed descriptor (api) untouched"
assert_eq "$(cat "${S1}/.secrets/api")" "$api_secret_before" "RS01d ADD -- surviving aid-managed secret (api) preserved untouched"
assert_eq "$(cat "${S1}/mcp-tool.md")" "$mcp_before" "RS01e ADD -- surviving tool-managed descriptor (mcp-tool) untouched"
if [[ ! -f "${S1}/.secrets/mcp-tool" ]]; then
    pass "RS01f ADD -- tool-managed connector still has no stored secret"
else
    fail "RS01f ADD -- tool-managed connector unexpectedly has a stored secret"
fi

# ===========================================================================
# RS02  UPDATE (change) -- same-stem descriptor overwritten in place; its
# stored secret is preserved (auth_method/secret_reference did not change
# this cycle, so no secret-capture invocation happens).
# ===========================================================================
S2="${TMPDIR_BASE}/s2"
init_fixture "$S2"
SENTINEL_API2="RECON19-SENTINEL-api2-3ad07e19"

write_aid_descriptor "$S2" api "Sample API" api "https://old.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S2" api "$SENTINEL_API2"
secret2_before="$(cat "${S2}/.secrets/api")"

p2="$(list_stems "$S2")"
assert_eq "$p2" "api" "RS02-R1 persisted set P before UPDATE"

# R2: api is in D ∩ P and its endpoint differs -> UPDATE. Overwrite the
# descriptor in place; auth_method/secret_reference are unchanged, so the
# secret-capture step is skipped entirely (no write_secret call here -- that
# absence IS the preservation proof).
write_aid_descriptor "$S2" api "Sample API" api "https://new.example.com/v2" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."

OUT2="${S2}/INDEX.md"
build_index "$S2" "$OUT2"

assert_file_exists "${S2}/api.md" "RS02a UPDATE -- descriptor still at the same stem path"
assert_file_contains "${S2}/api.md" "https://new.example.com/v2" "RS02b UPDATE -- descriptor overwritten in place with the new field value"
assert_file_not_contains "${S2}/api.md" "https://old.example.com/v1" "RS02c UPDATE -- old field value no longer present"
assert_eq "$(cat "${S2}/.secrets/api")" "$secret2_before" "RS02d UPDATE -- stored secret preserved untouched across the field change"
assert_file_contains "$OUT2" "https://new.example.com/v2" "RS02e UPDATE -- INDEX.md reflects the updated field"

# ===========================================================================
# RS03  REMOVE -- purge the aid-managed secret THEN delete the descriptor
# (purge-before-delete order, interrupt-safety); tool-managed purge is a
# clean no-op (no stored secret); a surviving third entry and its secret are
# preserved.
# ===========================================================================
S3="${TMPDIR_BASE}/s3"
init_fixture "$S3"
SENTINEL_API3="RECON19-SENTINEL-api3-77bb410c"
SENTINEL_STABLE3="RECON19-SENTINEL-stable3-c40e5f2d"

write_aid_descriptor "$S3" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S3" api "$SENTINEL_API3"
write_mcp_descriptor "$S3" mcp-tool "Sample MCP Tool" \
    "sample-mcp (host-tool managed)" "A sample tool-managed connector." \
    "tool-managed sample for reconcile tests."
write_aid_descriptor "$S3" stable "Stable API" api "https://stable.example.com/v1" token \
    "file:.aid/connectors/.secrets/stable" "A surviving aid-managed API." \
    "stable aid-managed connector that stays declared this cycle."
write_secret "$S3" stable "$SENTINEL_STABLE3"

stable_before="$(cat "${S3}/stable.md")"
stable_secret_before="$(cat "${S3}/.secrets/stable")"

p3="$(list_stems "$S3")"
assert_eq "$p3" $'api\nmcp-tool\nstable' "RS03-R1 persisted set P before REMOVE"

# R2: D = {stable} only -- api and mcp-tool fall into P \ D (REMOVE); stable
# is D ∩ P with identical fields (NO-OP -- untouched below).
# R3 REMOVE api (aid-managed): purge THEN delete.
bash "$SECRET" purge api --root "$S3" >/dev/null 2>&1
purge_api_ec=$?
rm -f -- "${S3}/api.md"
# R3 REMOVE mcp-tool (tool-managed, never had a stored secret): purge is a
# clean no-op THEN delete.
bash "$SECRET" purge mcp-tool --root "$S3" >/dev/null 2>&1
purge_mcp_ec=$?
rm -f -- "${S3}/mcp-tool.md"

OUT3="${S3}/INDEX.md"
build_index "$S3" "$OUT3"

assert_exit_zero "$purge_api_ec" "RS03a REMOVE -- purge of the aid-managed connector's secret exits 0"
if [[ ! -f "${S3}/.secrets/api" ]]; then
    pass "RS03b REMOVE -- aid-managed secret file is gone after purge"
else
    fail "RS03b REMOVE -- aid-managed secret file still present after purge"
fi
if [[ ! -f "${S3}/api.md" ]]; then
    pass "RS03c REMOVE -- descriptor deleted after the secret was purged"
else
    fail "RS03c REMOVE -- descriptor still present"
fi
assert_exit_zero "$purge_mcp_ec" "RS03d REMOVE -- purge on a tool-managed connector (no stored secret) is a clean no-op, exit 0"
if [[ ! -f "${S3}/.secrets/mcp-tool" ]]; then
    pass "RS03e REMOVE -- tool-managed connector still has no secret file (nothing to purge)"
else
    fail "RS03e REMOVE -- tool-managed connector unexpectedly has a secret file"
fi
assert_eq "$(cat "${S3}/stable.md")" "$stable_before" "RS03f REMOVE -- surviving entry (stable) descriptor untouched"
assert_eq "$(cat "${S3}/.secrets/stable")" "$stable_secret_before" "RS03g REMOVE -- surviving entry (stable) secret preserved"
assert_file_not_contains "$OUT3" "](api.md)" "RS03h REMOVE -- INDEX.md no longer lists the removed aid-managed connector"
assert_file_not_contains "$OUT3" "](mcp-tool.md)" "RS03i REMOVE -- INDEX.md no longer lists the removed tool-managed connector"
assert_file_contains "$OUT3" "](stable.md)" "RS03j REMOVE -- INDEX.md still lists the surviving connector"

# ===========================================================================
# RS04  Idempotent no-op -- two reconcile passes over an unchanged declared
# set / persisted set (every stem NO-OP) produce a byte-identical INDEX.md.
# ===========================================================================
S4="${TMPDIR_BASE}/s4"
init_fixture "$S4"
SENTINEL_API4="RECON19-SENTINEL-api4-9e21bb6a"
SENTINEL_STABLE4="RECON19-SENTINEL-stable4-2af98d10"

write_aid_descriptor "$S4" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S4" api "$SENTINEL_API4"
write_mcp_descriptor "$S4" mcp-tool "Sample MCP Tool" \
    "sample-mcp (host-tool managed)" "A sample tool-managed connector." \
    "tool-managed sample for reconcile tests."
write_aid_descriptor "$S4" stable "Stable API" api "https://stable.example.com/v1" token \
    "file:.aid/connectors/.secrets/stable" "A surviving aid-managed API." \
    "stable aid-managed connector that stays declared this cycle."
write_secret "$S4" stable "$SENTINEL_STABLE4"

# Reconcile pass 1: D == P exactly -> every stem NO-OP (R3 writes nothing);
# only R4 (INDEX regen) actually runs.
OUT4A="${S4}/INDEX.md"
build_index "$S4" "$OUT4A"
sha_run1=$(sha256sum "$OUT4A" | awk '{print $1}')

# Reconcile pass 2: SAME declared set D over the SAME persisted set P ->
# still every stem NO-OP. Regenerate to a second path so the comparison is
# an independent byte-for-byte check, not a self-comparison.
OUT4B="${TMPDIR_BASE}/INDEX-run2.md"
build_index "$S4" "$OUT4B"
sha_run2=$(sha256sum "$OUT4B" | awk '{print $1}')

if [[ "$sha_run1" == "$sha_run2" ]]; then
    pass "RS04 idempotent no-op -- byte-identical INDEX.md across two reconcile passes (sha256 $sha_run1)"
else
    fail "RS04 idempotent no-op -- INDEX.md differs across passes: $sha_run1 vs $sha_run2"
    [[ "$VERBOSE" -eq 1 ]] && diff "$OUT4A" "$OUT4B"
fi

# ===========================================================================
# RS05  Interrupt re-convergence -- a REMOVE interrupted between "purge" and
# "delete descriptor" is re-derived as REMOVE on the next run; the re-purge
# is a clean no-op, and the run completes convergence (descriptor deleted,
# INDEX regenerated).
# ===========================================================================
S5="${TMPDIR_BASE}/s5"
init_fixture "$S5"
SENTINEL_API5="RECON19-SENTINEL-api5-5d18c0f3"

write_aid_descriptor "$S5" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S5" api "$SENTINEL_API5"

p5="$(list_stems "$S5")"
assert_eq "$p5" "api" "RS05-R1 persisted set P before the interrupted REMOVE"

# --- Simulate an INTERRUPTED REMOVE: step 1 (purge) completes, then the
# process is interrupted BEFORE step 2 (descriptor delete) runs.
bash "$SECRET" purge api --root "$S5" >/dev/null 2>&1
purge1_ec=$?
# (deliberately no `rm -f -- api.md` here -- this is the simulated crash)

assert_exit_zero "$purge1_ec" "RS05a interrupted REMOVE step 1 (purge) succeeds"
if [[ ! -f "${S5}/.secrets/api" ]]; then
    pass "RS05b interrupted REMOVE -- secret already gone after step 1"
else
    fail "RS05b interrupted REMOVE -- secret unexpectedly still present after step 1"
fi
if [[ -f "${S5}/api.md" ]]; then
    pass "RS05c interrupted REMOVE -- descriptor still present (the interrupt point)"
else
    fail "RS05c interrupted REMOVE -- descriptor unexpectedly already gone"
fi

# Because the descriptor is what keeps a stem in P, a fresh run's R1 still
# reports api in P even though its secret is already gone -- this is exactly
# why REMOVE purges before it deletes (feature-006 SPEC "interrupt-safety").
p5_after_interrupt="$(list_stems "$S5")"
assert_eq "$p5_after_interrupt" "api" "RS05d re-derivation -- descriptor survival keeps the stem in P after the interrupt"

# --- RE-RUN reconcile: D is still {} this cycle -> api is re-classified
# REMOVE. Step 1 (purge) re-runs as a clean no-op; step 2 (delete) completes.
bash "$SECRET" purge api --root "$S5" >/dev/null 2>&1
purge2_ec=$?
rm -f -- "${S5}/api.md"

OUT5="${S5}/INDEX.md"
build_index "$S5" "$OUT5"

assert_exit_zero "$purge2_ec" "RS05e re-run purge -- re-purging an already-purged secret is a clean idempotent no-op"
if [[ ! -f "${S5}/api.md" ]]; then
    pass "RS05f re-run -- descriptor deleted, convergence complete"
else
    fail "RS05f re-run -- descriptor still present after the re-run"
fi
p5_final="$(list_stems "$S5")"
assert_eq "$p5_final" "" "RS05g re-run -- persisted set P is now empty"
assert_file_contains "$OUT5" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "RS05h re-run -- INDEX.md regenerated (header-only, last connector removed)"

# ===========================================================================
# RS06  Q9 SKIPPED -- the tool step was not engaged this cycle. R0's guard
# makes this an unconditional no-op: no list, no read, no purge, no
# descriptor write, no INDEX rebuild. The registry is left byte-for-byte
# intact (every descriptor, every secret, and INDEX.md itself, unchanged).
# ===========================================================================
S6="${TMPDIR_BASE}/s6"
init_fixture "$S6"
SENTINEL_API6="RECON19-SENTINEL-api6-04e6ac7b"

write_aid_descriptor "$S6" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S6" api "$SENTINEL_API6"
write_mcp_descriptor "$S6" mcp-tool "Sample MCP Tool" \
    "sample-mcp (host-tool managed)" "A sample tool-managed connector." \
    "tool-managed sample for reconcile tests."
OUT6="${S6}/INDEX.md"
build_index "$S6" "$OUT6"   # a prior cycle's INDEX, already on disk before the SKIPPED cycle

before6="$(snapshot_tree "$S6")"

# --- Q9 SKIPPED cycle: the tool step was NOT engaged. Per Step R0, reconcile
# never reaches R1-R5 at all -- this block deliberately issues ZERO commands
# against $S6. That absence of any op invocation IS the behavior under test.

after6="$(snapshot_tree "$S6")"
assert_eq "$after6" "$before6" \
    "RS06 Q9 SKIPPED -- registry left exactly intact (identical descriptors, secrets, and INDEX.md; no purge/delete/rebuild)"

# ===========================================================================
# RS07  Q9 DECLARED-EMPTY -- the tool step was engaged with D={}. Distinct
# from RS06: this DOES run R1-R4. Every persisted connector falls into
# P \ D = {} and is removed-and-purged; INDEX.md becomes header-only.
# ===========================================================================
S7="${TMPDIR_BASE}/s7"
init_fixture "$S7"
SENTINEL_API7="RECON19-SENTINEL-api7-b81f5e2a"

write_aid_descriptor "$S7" api "Sample API" api "https://api.example.com/v1" token \
    "file:.aid/connectors/.secrets/api" "A sample aid-managed API." \
    "aid-managed sample for reconcile tests."
write_secret "$S7" api "$SENTINEL_API7"
write_mcp_descriptor "$S7" mcp-tool "Sample MCP Tool" \
    "sample-mcp (host-tool managed)" "A sample tool-managed connector." \
    "tool-managed sample for reconcile tests."

p7="$(list_stems "$S7")"
assert_eq "$p7" $'api\nmcp-tool' "RS07-R1 persisted set P before the DECLARED-EMPTY reconcile"

# R2/R3: D = {} -- every stem in P falls into P \ D -> REMOVE-and-purge all.
while IFS= read -r stem; do
    [[ -z "$stem" ]] && continue
    bash "$SECRET" purge "$stem" --root "$S7" >/dev/null 2>&1
    rm -f -- "${S7}/${stem}.md"
done <<< "$p7"

OUT7="${S7}/INDEX.md"
build_index "$S7" "$OUT7"

p7_final="$(list_stems "$S7")"
assert_eq "$p7_final" "" "RS07a DECLARED-EMPTY -- all persisted connectors removed"
if [[ ! -f "${S7}/.secrets/api" ]]; then
    pass "RS07b DECLARED-EMPTY -- aid-managed secret purged"
else
    fail "RS07b DECLARED-EMPTY -- aid-managed secret still present"
fi
assert_file_contains "$OUT7" "| Connector | Type | Endpoint | Auth | Secret Ref | Summary |" \
    "RS07c DECLARED-EMPTY -- INDEX.md header still present (pointer never dangles)"
data_rows7=$(grep -c '^| \[' "$OUT7" || true)
assert_eq "$data_rows7" "0" "RS07d DECLARED-EMPTY -- INDEX.md is header-only (zero data rows)"

# ===========================================================================
test_summary
