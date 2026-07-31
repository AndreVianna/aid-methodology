#!/usr/bin/env bash
# test-dogfood-byte-identity.sh -- SS7a / C2 (.claude/) + FR-26 (.cursor/) dogfood
# byte-identity guard.
#
# ONE implementation of THREE directions, driven TWICE over the tuple
#   (manifest, profile tree, dogfood tree, dst prefix, key prefix, allowlist fn):
#
#   tuple 1 -- .claude/  profiles/claude-code/emission-manifest.jsonl
#                        profiles/claude-code/.claude  <->  repo-root .claude
#                        keys  DBI00 DBI00b DBI00c DBI01 DBI-FWD DBI-REV DBI-ORPHAN
#   tuple 2 -- .cursor/  profiles/cursor/emission-manifest.jsonl
#                        profiles/cursor/.cursor       <->  repo-root .cursor
#                        keys  DBI-CUR00 DBI-CUR00b DBI-CUR00c DBI-CUR01
#                              DBI-CUR-FWD DBI-CUR-REV DBI-CUR-ORPHAN
#
# The two key sets are deliberately DISJOINT so the two direction sets stay
# separable in tests/coverage-baseline.tsv and in a failure report.
#
#   Direction 1 (forward):  for each dst entry in the emission manifest that
#       starts with the tuple's prefix, assert the corresponding file under the
#       repo-root dogfood tree exists AND its sha256 matches the manifest
#       record -- and, for completeness, that the profile-tree copy matches too.
#
#   Direction 2 (reverse):  for each file present under the profile tree,
#       assert it appears as a dst in the manifest (i.e. the manifest is
#       complete -- no generator-produced file was silently omitted from it).
#
#   Direction 3 (repo-orphan sweep):  for each file present under the repo-root
#       dogfood tree, assert it is EITHER a generator-owned manifest dst OR an
#       explicitly DOCUMENTED non-generator file (the closed allowlist for that
#       tuple) -- so a generator-shaped repo-side orphan that bypassed the
#       manifest is caught (SS7a: the guard excludes nothing in the AID-owned
#       tree; the only un-compared files are the documented ones).
#
# WHAT THESE DIRECTIONS PROVE -- AND WHAT THEY DO NOT
# ---------------------------------------------------
# Read this before citing a green run as evidence of anything.
#
# All three artifacts each tuple compares -- the emission manifest, the profile
# tree and the dogfood tree -- are OUTPUTS of the same generator run.
# `canonical/`, the generator's INPUT, is not among them. Therefore:
#
#   * every direction in BOTH tuples proves MUTUAL CONSISTENCY of one
#     generator run's outputs;
#   * NO direction in either tuple proves FRESHNESS. If all three artifacts are
#     consistently stale, this suite is green.
#
# That is not hypothetical: this suite was green over the stale trees that
# work-004 delivery-002's re-render existed to replace, both before and after
# that re-render, and could not have detected the staleness either time.
#
#   consistency oracle (this suite) : manifest <-> profile tree <-> dogfood tree
#   freshness oracle   (NOT here)   : re-run the generator, then
#                                     `git diff --exit-code -- profiles/`
#
# The DBI-CUR-MUT-* controls at the end differ in kind but not in property:
# they prove the .cursor/ directions CAN go red (they are not vacuous). That is
# a statement about the check, still not about freshness.
#
# The manifest is the authoritative comparison set for both tuples -- read from
# the file rather than re-derived by walking a tree, so a file the manifest
# forgot cannot be silently excused by a walk that forgot it too.
#
# On any mismatch the suite fails loudly, naming the divergent path.
#
# Registered automatically: tests/run-all.sh discovers all
# tests/canonical/test-*.sh by glob; no workflow YAML edit is needed.
#
# Usage:
#   bash tests/canonical/test-dogfood-byte-identity.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

MANIFEST_CLAUDE="${REPO_ROOT}/profiles/claude-code/emission-manifest.jsonl"
PROFILE_CLAUDE="${REPO_ROOT}/profiles/claude-code/.claude"
DOGFOOD_CLAUDE="${REPO_ROOT}/.claude"

MANIFEST_CURSOR="${REPO_ROOT}/profiles/cursor/emission-manifest.jsonl"
PROFILE_CURSOR="${REPO_ROOT}/profiles/cursor/.cursor"
DOGFOOD_CURSOR="${REPO_ROOT}/.cursor"

# Scratch root for the DBI-CUR-MUT-* negative controls. Nothing else writes.
# Removed by the EXIT trap on every path, including failure and early bail.
DBI_SCRATCH="$(mktemp -d)"
trap 'rm -rf "${DBI_SCRATCH}"' EXIT

echo "=== dogfood byte-identity guard (SS7a / C2 .claude/ + FR-26 .cursor/) ==="

# ---------------------------------------------------------------------------
# Probe mode.
#
# The DBI-CUR-MUT-* controls need to run the SAME direction implementation over
# a deliberately broken tree and observe that it REPORTS a failure -- without
# that failure counting against the suite. So the directions never call
# pass/fail directly: they call dbi_pass/dbi_fail, which in normal mode forward
# to pass/fail and in probe mode collect into DBI_FINDINGS instead.
#
# This keeps ONE implementation for the real runs and the controls: a control
# that exercised a copy of the logic would prove nothing about the logic that
# actually runs.
# ---------------------------------------------------------------------------
DBI_PROBE=0
DBI_FINDINGS=()

dbi_pass() { [[ $DBI_PROBE -eq 1 ]] || pass "$*"; }
dbi_fail() {
    if [[ $DBI_PROBE -eq 1 ]]; then
        DBI_FINDINGS+=("$*")
    else
        fail "$*"
    fi
}

# Repo-relative rendering of an absolute path, for stable human labels.
dbi_rel() { printf '%s' "${1#${REPO_ROOT}/}"; }

# ---------------------------------------------------------------------------
# Direction-3 allowlists -- one per tuple, and they are NOT interchangeable.
# ---------------------------------------------------------------------------

# .claude/ : the non-generator files that legitimately live in the dogfood
# .claude/ (no profile counterpart, not emitted by render.py). SEVEN patterns
# over SIX case arms:
#   settings.json / settings.local.json : Claude Code settings  (one arm, two patterns)
#   projects/**                          : Claude Code session + memory state
#   worktrees/**                         : git worktree metadata
#   skills/README.md                     : maintainer index of skills (AID doc, not profile-emitted)
#   skills/generate-profile/**           : the generate-profile toolchain itself (render.py et al + caches)
#   skills/release-aid/**                : the maintainer-only release-aid ops skill (repo-local, never shipped)
dbi_allowlisted() {
    local rel="$1"
    case "$rel" in
        settings.json | settings.local.json) return 0 ;;
        projects/*)                return 0 ;;
        worktrees/*)               return 0 ;;
        skills/README.md)          return 0 ;;
        skills/generate-profile/*) return 0 ;;
        skills/release-aid/*)      return 0 ;;
        *) return 1 ;;
    esac
}

# .cursor/ : EMPTY plus worktrees/*, and copying the .claude/ list above would
# be the defect (feature-006 risk 8). Six of that list's seven patterns are
# deliberately NOT carried over -- settings.json, settings.local.json,
# projects/*, skills/README.md, skills/generate-profile/* and
# skills/release-aid/* have no counterpart under .cursor/ at all, so importing
# them would excuse files that do not exist and check strictly less.
#
# What makes EMPTY correct is an ORPHAN count, not a directory count: the
# repo-root .cursor/ file set and the cursor manifest's .cursor/ dst set
# coincide exactly, so there is nothing for an allowlist to excuse before
# worktrees/* excludes anything. (The .claude/-vs-.cursor/ skills-directory
# comparison explains only why .claude/ needs its two skills/* arms; it says
# nothing about the other four patterns.)
#
# worktrees/* is load-bearing only in the PRIMARY checkout, whose .cursor/
# carries agents, aid, skills AND worktrees. A worktree checkout's .cursor/
# holds only agents, aid, skills, so a green run from a worktree never
# exercises this arm through the live tree -- which is precisely why
# DBI-CUR-MUT-ALLOW below exercises it against a scratch copy instead.
dbi_cursor_allowlisted() {
    local rel="$1"
    case "$rel" in
        worktrees/*) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Prerequisites for one tuple. Always real asserts (never probed).
# ---------------------------------------------------------------------------
dbi_prereqs() {
    local manifest="$1" profile_tree="$2" dogfood_tree="$3" dst_prefix="$4" keyp="$5"
    assert_file_exists "$manifest"     "${keyp}00 $(basename "$manifest") exists"
    assert_dir_exists  "$profile_tree" "${keyp}00b $(dbi_rel "$profile_tree")/ exists"
    assert_dir_exists  "$dogfood_tree" "${keyp}00c repo-root ${dst_prefix} exists"
}

# ---------------------------------------------------------------------------
# Load the comparison set for one tuple from its manifest: every dst under the
# tuple's prefix plus its sha256, in a SINGLE awk pass (no python3 dependency,
# no per-entry re-scan). awk extracts "dst"/"sha256" from each JSON object line
# whose dst starts with the prefix and emits "dst<TAB>sha256"; the single sort
# keys on the unique dst, giving a deterministic iteration order. A dst with no
# matched sha256 is still emitted (with an empty sha field) so it is never
# silently dropped from MANIFEST_DSTS -- its forward check falls through to the
# MISMATCH branch instead of vanishing from the comparison set. The prefix is
# compared with substr() rather than spliced into a regex, so no caller has to
# escape it.
#
# The loaded ENTRY COUNT is logged rather than embedded in the pass label:
# coverage-parity's normalize_key collapses `DBI01 ...` to its leading token but
# keys the hyphenated `DBI-CUR01 ...` on the whole masked label, so a count in
# that label would re-key the assertion every time the manifest changes size.
# ---------------------------------------------------------------------------
declare -A MANIFEST_SHA MANIFEST_SET DOGFOOD_SHA PROFILE_SHA
MANIFEST_DSTS=()
TOTAL_MANIFEST=0

dbi_load_manifest() {
    local manifest="$1" dst_prefix="$2" keyp="$3"
    local dst sha

    unset MANIFEST_SHA MANIFEST_SET
    declare -gA MANIFEST_SHA MANIFEST_SET
    MANIFEST_DSTS=()

    while IFS=$'\t' read -r dst sha; do
        [[ -z "$dst" ]] && continue
        MANIFEST_DSTS+=("$dst")
        MANIFEST_SHA["$dst"]="$sha"
        MANIFEST_SET["$dst"]=1
    done < <(
        awk -v pfx="$dst_prefix" '{
            d=""; s=""
            if (match($0, /"dst"[[:space:]]*:[[:space:]]*"([^"]+)"/, da)) d=da[1]
            if (d == "" || substr(d, 1, length(pfx)) != pfx) next
            if (match($0, /"sha256"[[:space:]]*:[[:space:]]*"([a-f0-9]{64})"/, sa)) s=sa[1]
            print d "\t" s
        }' "$manifest" | sort
    )

    TOTAL_MANIFEST=${#MANIFEST_DSTS[@]}
    if [[ $TOTAL_MANIFEST -eq 0 ]]; then
        dbi_fail "${keyp}01 manifest contains no ${dst_prefix} entries -- is the manifest empty?"
        return 1
    fi
    log "${keyp}01 loaded ${TOTAL_MANIFEST} manifest dst entries under ${dst_prefix} from $(dbi_rel "$manifest") (dst ENTRIES, not file lines -- the manifest carries one extra _manifest_version header line)"
    dbi_pass "${keyp}01 manifest loaded -- generator-owned ${dst_prefix} entries"
    return 0
}

# ---------------------------------------------------------------------------
# Batch hashing helper: collect the existing dogfood + profile paths via the
# builtin [[ -f ]] test (no forks), then hash each list ONCE via a single
# `sha256sum` invocation over all paths (piped through `xargs -0` so an
# arbitrarily long list never overflows argv). Two forks total instead of two
# per manifest entry.
# ---------------------------------------------------------------------------
hash_into() {
    # $1 = target map name (DOGFOOD_SHA / PROFILE_SHA), rest = file list.
    local -n _map="$1"; shift
    [[ $# -eq 0 ]] && return 0
    local line
    while IFS= read -r line; do
        # sha256sum emits "<64-hex><SEP><SEP>path" where SEP SEP is "  " in
        # text mode or " *" in cygwin binary mode -- always exactly 2 chars
        # after the fixed 64-hex hash. The fixed-offset parse is mode-
        # agnostic and needs no per-line awk fork.
        _map["${line:66}"]="${line:0:64}"
    done < <(printf '%s\0' "$@" | xargs -0 -r sha256sum)
}

# ---------------------------------------------------------------------------
# Direction 1 (forward): every manifest entry must exist in the dogfood tree
# AND its sha256 must match the manifest record.
# ---------------------------------------------------------------------------
dbi_direction_fwd() {
    local profile_tree="$1" dogfood_tree="$2" dst_prefix="$3" keyp="$4"
    log "Direction 1: manifest -> dogfood ${dst_prefix}"

    local dst rel profile_file dogfood_file expected_sha actual_sha profile_sha
    local -a dogfood_list=() profile_list=()

    for dst in "${MANIFEST_DSTS[@]}"; do
        rel="${dst#${dst_prefix}}"
        [[ -f "${dogfood_tree}/${rel}" ]] && dogfood_list+=("${dogfood_tree}/${rel}")
        [[ -f "${profile_tree}/${rel}" ]] && profile_list+=("${profile_tree}/${rel}")
    done

    unset DOGFOOD_SHA PROFILE_SHA
    declare -gA DOGFOOD_SHA PROFILE_SHA
    hash_into DOGFOOD_SHA "${dogfood_list[@]}"
    hash_into PROFILE_SHA "${profile_list[@]}"

    for dst in "${MANIFEST_DSTS[@]}"; do
        # Strip the tuple's leading prefix to get the path inside the tree.
        rel="${dst#${dst_prefix}}"

        profile_file="${profile_tree}/${rel}"
        dogfood_file="${dogfood_tree}/${rel}"
        expected_sha="${MANIFEST_SHA[$dst]}"

        # a) The file must exist in the dogfood tree.
        if [[ ! -f "$dogfood_file" ]]; then
            dbi_fail "${keyp}-FWD ${dst} -- MISSING in dogfood ${dst_prefix} (${dogfood_file})"
            continue
        fi

        # b) The dogfood file sha256 must match the manifest record.
        actual_sha="${DOGFOOD_SHA[$dogfood_file]:-}"
        if [[ "$actual_sha" != "$expected_sha" ]]; then
            dbi_fail "${keyp}-FWD ${dst} -- sha256 MISMATCH: manifest=${expected_sha} dogfood=${actual_sha}"
            continue
        fi

        # c) For completeness: the profile file sha256 must also match (guards
        #    the profile tree itself against silent drift, e.g. an accidental
        #    direct edit to the profile file that bypassed the generator).
        if [[ ! -f "$profile_file" ]]; then
            dbi_fail "${keyp}-FWD ${dst} -- MISSING in profile ${dst_prefix} (${profile_file})"
            continue
        fi
        profile_sha="${PROFILE_SHA[$profile_file]:-}"
        if [[ "$profile_sha" != "$expected_sha" ]]; then
            dbi_fail "${keyp}-FWD ${dst} -- sha256 MISMATCH: manifest=${expected_sha} profile=${profile_sha}"
            continue
        fi

        dbi_pass "${keyp}-FWD ${dst}"
    done
    return 0
}

# ---------------------------------------------------------------------------
# Direction 2 (reverse): every file present under the profile tree must have a
# corresponding manifest entry (ensures the manifest is complete and no
# generator-produced file was silently dropped from it).
# ---------------------------------------------------------------------------
dbi_direction_rev() {
    local profile_tree="$1" dst_prefix="$2" keyp="$3"
    local profile_rel; profile_rel="$(dbi_rel "$profile_tree")"
    log "Direction 2: ${profile_rel}/ -> manifest"

    local profile_file rel dst
    while IFS= read -r profile_file; do
        # Derive the dst key as it would appear in the manifest.
        rel="${profile_file#${profile_tree}/}"
        dst="${dst_prefix}${rel}"

        if [[ -z "${MANIFEST_SET[$dst]+_}" ]]; then
            dbi_fail "${keyp}-REV ${dst} -- file exists in ${profile_rel}/ but is NOT in manifest"
        else
            dbi_pass "${keyp}-REV ${dst}"
        fi
    done < <(find "$profile_tree" -type f -not -path '*/node_modules/*' -not -path '*/.git/*' | sort)
    return 0
}

# ---------------------------------------------------------------------------
# Direction 3 (repo-orphan sweep): every file under the repo-root dogfood tree
# must be EITHER a generator-owned manifest dst (asserted in Direction 1) OR an
# explicitly DOCUMENTED non-generator file. A generator-shaped repo-side orphan
# -- a file that bypassed the manifest -- fails loudly. This closes the SS7a
# requirement that the guard excludes nothing in the AID-owned tree: nothing is
# blindly skipped; the only files not compared are the closed, documented
# allowlist for this tuple.
# ---------------------------------------------------------------------------
dbi_direction_orphan() {
    local dogfood_tree="$1" dst_prefix="$2" keyp="$3" allow_fn="$4"
    log "Direction 3: repo ${dst_prefix} -> manifest-or-allowlist (orphan sweep)"

    local orphan_found=0 dogfood_file rel dst
    while IFS= read -r dogfood_file; do
        rel="${dogfood_file#${dogfood_tree}/}"
        dst="${dst_prefix}${rel}"
        [[ -n "${MANIFEST_SET[$dst]+_}" ]] && continue   # generator-owned: covered by Direction 1
        if "$allow_fn" "$rel"; then
            [[ $VERBOSE -eq 1 ]] && log "${keyp}-ORPHAN skip (documented non-generator): ${dst}"
            continue
        fi
        dbi_fail "${keyp}-ORPHAN ${dst} -- generator-shaped file in repo ${dst_prefix} is NOT in the manifest and NOT in the documented allowlist (a repo-side orphan that bypassed the generator)"
        orphan_found=1
    done < <(find "$dogfood_tree" -type f | sort)
    [[ $orphan_found -eq 0 ]] && dbi_pass "${keyp}-ORPHAN repo ${dst_prefix} has no undocumented generator-shaped orphans"
    return 0
}

# ---------------------------------------------------------------------------
# All three directions for one tuple.
# ---------------------------------------------------------------------------
dbi_run_directions() {
    local manifest="$1" profile_tree="$2" dogfood_tree="$3" dst_prefix="$4" keyp="$5" allow_fn="$6"
    dbi_load_manifest "$manifest" "$dst_prefix" "$keyp" || return 1
    dbi_direction_fwd    "$profile_tree" "$dogfood_tree" "$dst_prefix" "$keyp"
    dbi_direction_rev    "$profile_tree" "$dst_prefix" "$keyp"
    dbi_direction_orphan "$dogfood_tree" "$dst_prefix" "$keyp" "$allow_fn"
    return 0
}

# Run the same three directions with pass/fail suppressed, collecting failures
# into DBI_FINDINGS for the caller to assert on.
dbi_probe() {
    DBI_FINDINGS=()
    DBI_PROBE=1
    dbi_run_directions "$@"
    DBI_PROBE=0
    return 0
}

# Findings present in DBI_FINDINGS but NOT in the clean-copy baseline
# DBI_BASE_FINDINGS, one per line on stdout.
#
# The mutation controls assert on this DELTA rather than on an absolute finding
# count, so that a pre-existing REAL failure in the live .cursor/ tree (which
# the scratch copy faithfully inherits) reports ONCE -- through the live
# DBI-CUR-* direction that found it -- instead of cascading into a spurious
# failure of every control below it.
DBI_BASE_FINDINGS=()
dbi_new_findings() {
    local f b seen
    for f in ${DBI_FINDINGS[@]+"${DBI_FINDINGS[@]}"}; do
        seen=0
        for b in ${DBI_BASE_FINDINGS[@]+"${DBI_BASE_FINDINGS[@]}"}; do
            [[ "$f" == "$b" ]] && { seen=1; break; }
        done
        [[ $seen -eq 0 ]] && printf '%s\n' "$f"
    done
    return 0
}

# ===========================================================================
# Prerequisites for BOTH tuples, then bail early if any is missing --
# remaining asserts would all cascade-fail with misleading messages.
# ===========================================================================
dbi_prereqs "$MANIFEST_CLAUDE" "$PROFILE_CLAUDE" "$DOGFOOD_CLAUDE" ".claude/" "DBI"
dbi_prereqs "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$DOGFOOD_CURSOR" ".cursor/" "DBI-CUR"

if [[ $FAIL -gt 0 ]]; then
    test_summary
    exit 1
fi

# ===========================================================================
# Tuple 1 -- .claude/  (SS7a / C2)
# ===========================================================================
log "=== tuple 1: .claude/ ==="
if ! dbi_run_directions "$MANIFEST_CLAUDE" "$PROFILE_CLAUDE" "$DOGFOOD_CLAUDE" \
                        ".claude/" "DBI" dbi_allowlisted; then
    test_summary
    exit 1
fi

# ===========================================================================
# Tuple 2 -- .cursor/  (FR-26)
# ===========================================================================
log "=== tuple 2: .cursor/ ==="
if ! dbi_run_directions "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$DOGFOOD_CURSOR" \
                        ".cursor/" "DBI-CUR" dbi_cursor_allowlisted; then
    test_summary
    exit 1
fi

# ===========================================================================
# DBI-CUR-MUT-* -- PERMANENT negative controls for the .cursor/ tuple
# (feature-006 proof P5). A direction that can never fail is not a guard, so
# the demonstrated red lives here, re-run on every CI run, rather than once in
# a transient work folder.
#
# Every mutation is applied to a `cp -r` COPY of the dogfood .cursor/ tree under
# the mktemp -d scratch root. Nothing under repo-root .cursor/ or under
# profiles/ is ever WRITTEN; the real profile tree and the real manifest are
# READ by the probes exactly as the live run reads them (they must be -- the
# manifest is the comparison set under test).
#
# No scratch path is ever printed on the passing path, so two consecutive runs
# at the same commit produce identical output despite the random mktemp name.
# ===========================================================================
log "=== .cursor/ negative controls (mutations on a scratch copy) ==="

MUT_COPY="${DBI_SCRATCH}/cursor-dogfood-copy"
cp -r "$DOGFOOD_CURSOR" "$MUT_COPY"

# Deterministic mutation target: the lexicographically first SKILL.md in the
# copied tree.
MUT_REL=""
if [[ -d "$MUT_COPY" ]]; then
    MUT_REL="$(cd "$MUT_COPY" && find . -type f -name 'SKILL.md' | sort | sed -n '1p')"
    MUT_REL="${MUT_REL#./}"
fi

if [[ ! -d "$MUT_COPY" ]]; then
    fail "DBI-CUR-MUT-SETUP the scratch copy of the dogfood .cursor/ tree was not created -- the mutation controls cannot run"
elif [[ -z "$MUT_REL" ]]; then
    fail "DBI-CUR-MUT-SETUP no SKILL.md found in the copied dogfood .cursor/ tree -- the byte mutation has no target"
else
    # --- Control 0: the UNMUTATED copy must probe CLEAN -------------------
    # Positive control for the zeros the controls below rely on. A probe
    # harness that always reported findings would make every control below
    # pass for the wrong reason.
    #
    # Its findings also become the BASELINE that the three mutation controls
    # subtract, so a genuine live-tree failure (faithfully inherited by the
    # copy) is reported once by the live direction and once here, instead of
    # cascading into all four controls.
    dbi_probe "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$MUT_COPY" \
              ".cursor/" "DBI-CUR" dbi_cursor_allowlisted
    DBI_BASE_FINDINGS=(${DBI_FINDINGS[@]+"${DBI_FINDINGS[@]}"})
    if [[ ${#DBI_BASE_FINDINGS[@]} -eq 0 ]]; then
        pass "DBI-CUR-MUT-CTRL unmutated scratch copy of the dogfood .cursor/ tree probes clean"
    else
        fail "DBI-CUR-MUT-CTRL unmutated scratch copy probed DIRTY (${#DBI_BASE_FINDINGS[@]} findings) -- it faithfully mirrors a live .cursor/ failure reported above; the controls below subtract this baseline and stay valid. First: ${DBI_BASE_FINDINGS[0]:-<none>}"
    fi

    # --- Control 1: BYTE mutation -> DBI-CUR-FWD sha256 mismatch ----------
    # One byte appended to one SKILL.md in the COPY (append rather than an
    # in-place flip: both change the sha256, and append needs no re-write of
    # the file). The expected finding names the .cursor/ dst, which is also
    # what proves this direction reads the CURSOR tree and not the .claude/
    # one -- a direction pointed at the wrong tree passes every mutation.
    printf '\n' >> "${MUT_COPY}/${MUT_REL}"
    dbi_probe "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$MUT_COPY" \
              ".cursor/" "DBI-CUR" dbi_cursor_allowlisted
    mapfile -t MUT_NEW < <(dbi_new_findings)
    if [[ ${#MUT_NEW[@]} -eq 1 \
          && "${MUT_NEW[0]}" == *"DBI-CUR-FWD .cursor/${MUT_REL} -- sha256 MISMATCH"* ]]; then
        pass "DBI-CUR-MUT-BYTE a one-byte mutation under the scratch .cursor/ copy makes DBI-CUR-FWD fail with a sha256 mismatch naming .cursor/${MUT_REL}"
    else
        fail "DBI-CUR-MUT-BYTE expected exactly 1 NEW finding 'DBI-CUR-FWD .cursor/${MUT_REL} -- sha256 MISMATCH', got ${#MUT_NEW[@]}. First: ${MUT_NEW[0]:-<none>}"
    fi
    # Restore the mutated file from the real tree (read-only source).
    cp "${DOGFOOD_CURSOR}/${MUT_REL}" "${MUT_COPY}/${MUT_REL}"

    # --- Control 2: ORPHAN mutation -> DBI-CUR-ORPHAN fails ---------------
    # One unlisted, generator-shaped file added to the COPY. This is the only
    # available evidence that the .cursor/ allowlist is not too WIDE: the live
    # tree has zero orphans, so the live run never exercises the reject path.
    MUT_ORPHAN_REL="skills/dbi-cur-orphan-probe/PROBE.md"
    mkdir -p "$(dirname "${MUT_COPY}/${MUT_ORPHAN_REL}")"
    printf 'synthetic orphan injected by DBI-CUR-MUT-ORPHAN\n' > "${MUT_COPY}/${MUT_ORPHAN_REL}"
    dbi_probe "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$MUT_COPY" \
              ".cursor/" "DBI-CUR" dbi_cursor_allowlisted
    mapfile -t MUT_NEW < <(dbi_new_findings)
    if [[ ${#MUT_NEW[@]} -eq 1 \
          && "${MUT_NEW[0]}" == *"DBI-CUR-ORPHAN .cursor/${MUT_ORPHAN_REL} --"* ]]; then
        pass "DBI-CUR-MUT-ORPHAN an unlisted generator-shaped file under the scratch .cursor/ copy makes DBI-CUR-ORPHAN fail naming .cursor/${MUT_ORPHAN_REL}"
    else
        fail "DBI-CUR-MUT-ORPHAN expected exactly 1 NEW finding naming .cursor/${MUT_ORPHAN_REL}, got ${#MUT_NEW[@]}. First: ${MUT_NEW[0]:-<none>}"
    fi
    rm -rf "${MUT_COPY}/skills/dbi-cur-orphan-probe"

    # --- Control 3: the worktrees/* arm is LIVE, not dead ------------------
    # The .cursor/ allowlist's single arm is inert in a worktree checkout (no
    # .cursor/worktrees/ there), so without this control a green run would say
    # nothing about whether the arm works at all. Injecting a worktrees/ file
    # into the COPY exercises it: paired with control 2 it shows the allowlist
    # is neither too wide (an unlisted orphan still fails) nor dead (a
    # worktrees/ file is excused).
    MUT_ALLOW_REL="worktrees/dbi-cur-allowlist-probe/PROBE.md"
    mkdir -p "$(dirname "${MUT_COPY}/${MUT_ALLOW_REL}")"
    printf 'synthetic worktrees/ file injected by DBI-CUR-MUT-ALLOW\n' > "${MUT_COPY}/${MUT_ALLOW_REL}"
    dbi_probe "$MANIFEST_CURSOR" "$PROFILE_CURSOR" "$MUT_COPY" \
              ".cursor/" "DBI-CUR" dbi_cursor_allowlisted
    mapfile -t MUT_NEW < <(dbi_new_findings)
    if [[ ${#MUT_NEW[@]} -eq 0 ]]; then
        pass "DBI-CUR-MUT-ALLOW the worktrees/* allowlist arm excuses a scratch .cursor/worktrees/ file (arm is live, not dead)"
    else
        fail "DBI-CUR-MUT-ALLOW expected 0 NEW findings for a .cursor/worktrees/ file, got ${#MUT_NEW[@]}. First: ${MUT_NEW[0]:-<none>}"
    fi
    rm -rf "${MUT_COPY}/worktrees"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
test_summary
