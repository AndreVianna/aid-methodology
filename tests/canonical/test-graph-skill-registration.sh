#!/usr/bin/env bash
# test-graph-skill-registration.sh -- is the aid-graph skill actually registered
# everywhere the toolkit says a skill is registered?
#
# Assertions, by the identifier the feature contract gives them:
#   GR01  the preflight, and the reason every set comparison below is non-vacuous:
#         (a) the canonical SKILL.md exists and declares all four frontmatter keys;
#         (b) the canonical skill root, the canonical graph script area and the
#             profile set are each present and NON-EMPTY, asserted BEFORE any set
#             derived from them is compared
#   GR02  per profile: the rendered skill file set EQUALS the set derived from
#         canonical under the generator's own emission rules
#   GR03  the same equality for the repo-root dogfood tree
#   GR04  per profile, per canonical path: exactly ONE manifest record names it,
#         and the file at that record's dst exists carrying that record's sha256
#   GR05  (a) the rendered graph script file set equals the canonically derived set;
#         (b) coverage-predicate.mjs is byte-identical in all five profiles and the
#             dogfood tree, AND the canonical file carries no substitution trigger
#             on a non-comment line -- both halves, because byte-identity for a
#             transformed file is a CONDITIONAL guarantee and asserting the
#             consequent alone asserts it unconditionally
#   GR06  no package.json under any rendered knowledge-graph template directory,
#         asserted only after that directory is confirmed present in each tree
#   GR07  the sibling clamp: every hand-authored documentation file that names
#         aid-summarize also names aid-graph, so a surface added later cannot be
#         missed silently (the file-set half of the contract's GR07)
#   GR09  the site surfaces: the per-skill page exists, the roster lists aid-graph
#         under the SAME group heading as its sibling, and the synced methodology
#         copy names it
#   plus  the shared module resolves under Node from a RENDERED location with no
#         package.json marker on its ancestor chain inside the shipped tree
#
# Fixture policy, and why it is the opposite of the sibling suite's:
#   This suite reads canonical/ and profiles/ DIRECTLY. That is deliberate and is
#   the whole point of the suite: the subject under test IS the rendered
#   repository, and a mktemp fixture cannot observe a render that never happened.
#   The sibling suite test-graph-gap-ledger.sh builds everything under a scratch
#   directory instead, because there the subject is a program's behaviour.
#   Neither suite reads a pipeline work folder, so both survive one being pruned.
#
#   Every expectation is derived from canonical/ and compared to each tree
#   independently. No tree is ever compared to another tree, and no expectation is
#   ever read out of a manifest. That rule exists because the recorded failure it
#   guards against is five manifests and two installer lists all asserting each
#   other while every one of them was stale.
#
# Usage:
#   bash test-graph-skill-registration.sh [-v | --verbose]
#
# Exit codes:
#   0 -- every assertion passed (skips are reported and do not fail the suite)
#   1 -- one or more assertions failed

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

cd "$REPO_ROOT"

SKILL_SLUG="aid-graph"
SIBLING_SLUG="aid-summarize"
CANON_SKILL="canonical/skills/${SKILL_SLUG}"
CANON_GRAPH_SCRIPTS="canonical/aid/scripts/graph"
CANON_KG_TEMPLATES="canonical/aid/templates/knowledge-graph"
PREDICATE_NAME="coverage-predicate.mjs"
DOGFOOD_ROOT=".claude"

SKIPPED=()
skip() { SKIPPED+=("$*"); echo "  SKIP: $*"; }

WORK=".aid/.temp/graph-registration.$$"
rm -rf "$WORK"; mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

# ===========================================================================
# Helpers
# ===========================================================================

# The set of paths the generator emits for a skill directory, relative to the
# rendered skill root: SKILL.md, references/*.md, and the direct FILE children of
# scripts/. Derived from canonical, which is the only sound ground truth.
derive_skill_set() {
    local root="$1"
    [[ -f "$root/SKILL.md" ]] && echo "SKILL.md"
    if [[ -d "$root/references" ]]; then
        find "$root/references" -maxdepth 1 -type f -name '*.md' | sed "s|^${root}/||"
    fi
    if [[ -d "$root/scripts" ]]; then
        find "$root/scripts" -maxdepth 1 -type f | sed "s|^${root}/||"
    fi
}

# The set of paths under a directory, relative to it, applying the generator's
# verbatim-copy exclusions: no dot-prefixed file names, no node_modules/, no .git/.
# `find -printf` is deliberately avoided throughout -- it is a GNU extension, and
# a sed strip of the root prefix is portable and costs one process.
derive_tree_set() {
    local root="$1"
    [[ -d "$root" ]] || return 0
    find "$root" -type f \
        -not -name '.*' \
        -not -path '*/node_modules/*' \
        -not -path '*/.git/*' \
        | sed "s|^${root}/||"
}

# The rendered file set under a directory, relative to it.
actual_tree_set() {
    local root="$1"
    [[ -d "$root" ]] || return 0
    find "$root" -type f | sed "s|^${root}/||"
}

sorted() { sort; }

# Compare two newline-separated sets, reporting the two-sided difference by NAME
# rather than as an opaque diff -- a missing path and an unexplained extra path are
# different defects and a reader needs to know which one fired.
assert_set_eq() {
    local expected_file="$1" actual_file="$2" label="$3"
    local missing extra
    missing=$(comm -23 "$expected_file" "$actual_file" | paste -sd, -)
    extra=$(comm -13 "$expected_file" "$actual_file" | paste -sd, -)
    if [[ -z "$missing" && -z "$extra" ]]; then
        pass "$label"
    else
        local why=""
        [[ -n "$missing" ]] && why="not rendered: $missing"
        [[ -n "$extra" ]] && why="${why:+$why; }no canonical source: $extra"
        fail "$label — $why"
    fi
}

file_sha() {
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

# ===========================================================================
# GR01 -- the preflight. Everything below is a universal; these make them real.
# ===========================================================================
echo "=== GR01: preflight ==="

assert_file_exists "$CANON_SKILL/SKILL.md" "GR01.a1 the canonical SKILL.md exists"

# The four keys the skill-frontmatter convention requires. Presence only: whether
# `description` reads as a complete summary is not mechanically decidable.
FM=$(sed -n '/^---$/,/^---$/p' "$CANON_SKILL/SKILL.md" 2>/dev/null | head -n -1)
if [[ -n "$FM" ]]; then
    pass "GR01.a2 non-vacuity: a frontmatter block was extracted from SKILL.md"
else
    fail "GR01.a2 no frontmatter block could be extracted from $CANON_SKILL/SKILL.md"
fi
for key in name description allowed-tools argument-hint; do
    if grep -qE "^${key}:" <<< "$FM"; then
        pass "GR01.a3 SKILL.md frontmatter declares '${key}'"
    else
        fail "GR01.a3 SKILL.md frontmatter is missing '${key}'"
    fi
done
if grep -qE "^name: *${SKILL_SLUG}\$" <<< "$FM"; then
    pass "GR01.a4 the declared name matches the directory slug"
else
    fail "GR01.a4 the declared name does not match the directory slug '${SKILL_SLUG}'"
fi

# (b) Every root a set is derived from, asserted present and NON-EMPTY here, so no
# comparison below can be satisfied by the empty set equalling the empty set.
derive_skill_set "$CANON_SKILL" | sorted > "$WORK/canon-skill.set"
CANON_SKILL_N=$(grep -c . "$WORK/canon-skill.set" || true)
if [[ "${CANON_SKILL_N:-0}" -gt 0 ]]; then
    pass "GR01.b1 the canonical skill root yields $CANON_SKILL_N emitted paths (non-empty)"
else
    fail "GR01.b1 the canonical skill root yields no emitted paths — every set comparison below would hold trivially"
fi

derive_tree_set "$CANON_GRAPH_SCRIPTS" | sorted > "$WORK/canon-scripts.set"
CANON_SCRIPTS_N=$(grep -c . "$WORK/canon-scripts.set" || true)
if [[ "${CANON_SCRIPTS_N:-0}" -gt 0 ]]; then
    pass "GR01.b2 the canonical graph script area holds $CANON_SCRIPTS_N files (non-empty)"
else
    fail "GR01.b2 the canonical graph script area is empty"
fi

# The profile set, taken from the same glob the generator enumerates, with each
# profile's skills root read from its own root_dir key.
PROFILES=()
for toml in profiles/*.toml; do
    [[ -e "$toml" ]] || continue
    pname="$(basename "$toml" .toml)"
    rdir="$(sed -n 's/^root_dir[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$toml" | head -1)"
    if [[ -z "$rdir" ]]; then
        fail "GR01.b3 profile '$pname' declares no root_dir"
        continue
    fi
    PROFILES+=("${pname}:${rdir}")
done
if [[ "${#PROFILES[@]}" -gt 0 ]]; then
    pass "GR01.b3 the profile set is non-empty (${#PROFILES[@]}: ${PROFILES[*]})"
else
    fail "GR01.b3 no profile was enumerated — GR02, GR04, GR05 and GR06 would all hold vacuously"
fi
assert_dir_exists "$CANON_KG_TEMPLATES" "GR01.b4 the canonical knowledge-graph template directory exists"

# ===========================================================================
# GR02 / GR04 -- per profile: the rendered set, and the manifest that describes it
# ===========================================================================
echo ""
echo "=== GR02 / GR04: per-profile skill render and manifest ==="

for entry in "${PROFILES[@]}"; do
    p="${entry%%:*}"; r="${entry##*:}"
    tree="profiles/${p}/${r}/skills/${SKILL_SLUG}"
    manifest="profiles/${p}/emission-manifest.jsonl"

    if [[ ! -d "$tree" ]]; then
        fail "GR02.a [$p] the rendered skill directory does not exist: $tree"
        continue
    fi
    pass "GR02.a [$p] the rendered skill directory exists"

    actual_tree_set "$tree" | sorted > "$WORK/${p}-skill.set"
    assert_set_eq "$WORK/canon-skill.set" "$WORK/${p}-skill.set" \
        "GR02.b [$p] the rendered skill file set equals the canonically derived set"

    if [[ ! -f "$manifest" ]]; then
        fail "GR04.a [$p] no emission manifest at $manifest"
        continue
    fi
    pass "GR04.a [$p] the emission manifest exists"

    # Exactly one record per canonical path, and the file it names exists with the
    # recorded hash. The quantifier comes from canonical/, never from the manifest.
    #
    # Records and disk hashes are gathered in TWO processes per profile rather than
    # two per record: this repository is developed on Windows, where a fork costs
    # about a tenth of a second, and a per-record shell-out turned a static
    # assertion suite into a minute and a half of process spawning.
    #
    # The record keys are emitted in sorted order (dst, profile, sha256, src), so a
    # single substitution splits every line into rel<TAB>dst<TAB>sha.
    grep -F "\"src\": \"canonical/skills/${SKILL_SLUG}/" "$manifest" 2>/dev/null \
        | sed -E "s|.*\"dst\": \"([^\"]*)\".*\"sha256\": \"([^\"]*)\".*\"src\": \"canonical/skills/${SKILL_SLUG}/([^\"]*)\".*|\3\t\1\t\2|" \
        | sort > "$WORK/${p}-records.tsv" || true

    # One hashing process for every destination the records name.
    ( cd "profiles/${p}" 2>/dev/null && cut -f2 "${REPO_ROOT}/${WORK}/${p}-records.tsv" \
        | tr '\n' '\0' | xargs -0 -r sha256sum 2>/dev/null ) \
        | sed 's|^\([0-9a-f]*\) [ *]|\1 |' > "$WORK/${p}-disk.sha" || true

    # Index the two files into shell arrays -- no further processes.
    declare -A REC_DST=() REC_SHA=() REC_N=() DISK_SHA=()
    while IFS=$'\t' read -r rel dst sha; do
        [[ -z "$rel" ]] && continue
        REC_N["$rel"]=$(( ${REC_N["$rel"]:-0} + 1 ))
        REC_DST["$rel"]="$dst"
        REC_SHA["$rel"]="$sha"
    done < "$WORK/${p}-records.tsv"
    while read -r sha path; do
        [[ -z "$path" ]] && continue
        DISK_SHA["$path"]="$sha"
    done < "$WORK/${p}-disk.sha"

    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        n="${REC_N["$rel"]:-0}"
        if [[ "$n" -ne 1 ]]; then
            fail "GR04.b [$p] expected exactly one manifest record for 'canonical/skills/${SKILL_SLUG}/${rel}', found $n"
            continue
        fi
        pass "GR04.b [$p] exactly one manifest record names '$rel'"
        dst="${REC_DST["$rel"]}"
        rec_sha="${REC_SHA["$rel"]}"
        if [[ ! -f "profiles/${p}/${dst}" ]]; then
            fail "GR04.c [$p] the record's dst does not exist: profiles/${p}/${dst}"
            continue
        fi
        actual_sha="${DISK_SHA["$dst"]:-}"
        if [[ -n "$actual_sha" && "$actual_sha" == "$rec_sha" ]]; then
            pass "GR04.c [$p] '$rel' exists at its recorded dst carrying its recorded sha256"
        else
            fail "GR04.c [$p] '$rel' sha256 mismatch — manifest $rec_sha, disk ${actual_sha:-<unhashed>}"
        fi
    done < "$WORK/canon-skill.set"
    unset REC_DST REC_SHA REC_N DISK_SHA
done

# ===========================================================================
# GR03 -- the dogfood tree, anchored to canonical and NOT to profiles/claude-code
# ===========================================================================
echo ""
echo "=== GR03: the dogfood tree ==="

DOG_SKILL="${DOGFOOD_ROOT}/skills/${SKILL_SLUG}"
if [[ -d "$DOG_SKILL" ]]; then
    pass "GR03.a the dogfood skill directory exists"
    actual_tree_set "$DOG_SKILL" | sorted > "$WORK/dogfood-skill.set"
    # Ground truth is canonical/. Anchoring this to profiles/claude-code/ would be
    # the sibling-copy comparison that lets two stale trees agree with each other.
    assert_set_eq "$WORK/canon-skill.set" "$WORK/dogfood-skill.set" \
        "GR03.b the dogfood skill file set equals the CANONICALLY derived set"
else
    fail "GR03.a the dogfood skill directory does not exist: $DOG_SKILL"
fi

# ===========================================================================
# GR05 -- the graph script area, and the one file executed in two runtimes
# ===========================================================================
echo ""
echo "=== GR05: the graph script area and the shared predicate ==="

CANON_PREDICATE="${CANON_GRAPH_SCRIPTS}/${PREDICATE_NAME}"
assert_file_exists "$CANON_PREDICATE" \
    "GR05.b1 the canonical shared predicate exists (GR01.b2's non-empty directory does not imply this file)"

# Clause (b), first half: the file carries no substitution trigger on a non-comment
# line. Byte-identity for a text-processed file holds IF AND ONLY IF that is true,
# so asserting the byte claim alone would assert a conditional unconditionally.
TRIGGERS=$(grep -nE 'canonical/(scripts|templates|skills|agents|recipes|aid)/|\{(project_context_file|reviewer_output_file|open_questions_file)\}' \
    "$CANON_PREDICATE" 2>/dev/null | grep -vE ':[[:space:]]*(//|\*|/\*)' | grep -c . || true)
assert_eq "${TRIGGERS:-x}" "0" \
    "GR05.b2 the canonical predicate carries no render substitution trigger on a non-comment line"

CANON_PRED_SHA=$(file_sha "$CANON_PREDICATE")
if [[ -n "$CANON_PRED_SHA" ]]; then
    pass "GR05.b3 non-vacuity: the canonical predicate hashes to $CANON_PRED_SHA"
else
    fail "GR05.b3 the canonical predicate could not be hashed"
fi

for entry in "${PROFILES[@]}"; do
    p="${entry%%:*}"; r="${entry##*:}"
    rendered_dir="profiles/${p}/${r}/aid/scripts/graph"

    if [[ ! -d "$rendered_dir" ]]; then
        fail "GR05.a [$p] the rendered graph script area does not exist: $rendered_dir"
        continue
    fi
    actual_tree_set "$rendered_dir" | sorted > "$WORK/${p}-scripts.set"
    assert_set_eq "$WORK/canon-scripts.set" "$WORK/${p}-scripts.set" \
        "GR05.a [$p] the rendered graph script file set equals the canonically derived set"

    rendered_pred="${rendered_dir}/${PREDICATE_NAME}"
    if [[ ! -f "$rendered_pred" ]]; then
        fail "GR05.b4 [$p] the rendered predicate is missing"
        continue
    fi
    assert_eq "$(file_sha "$rendered_pred")" "$CANON_PRED_SHA" \
        "GR05.b4 [$p] the rendered predicate is byte-identical to the canonical one"
done

DOG_PRED="${DOGFOOD_ROOT}/aid/scripts/graph/${PREDICATE_NAME}"
if [[ -f "$DOG_PRED" ]]; then
    assert_eq "$(file_sha "$DOG_PRED")" "$CANON_PRED_SHA" \
        "GR05.b5 the dogfood predicate is byte-identical to the canonical one"
else
    fail "GR05.b5 the dogfood predicate is missing: $DOG_PRED"
fi

# ===========================================================================
# GR06 -- no ESM marker file ships, in any tree
# ===========================================================================
echo ""
echo "=== GR06: no package.json marker in a rendered template tree ==="

KG_REL="aid/templates/knowledge-graph"
check_no_marker() {
    local label="$1" dir="$2"
    if [[ ! -d "$dir" ]]; then
        fail "GR06.a $label the knowledge-graph template directory is missing: $dir"
        return
    fi
    pass "GR06.a $label the knowledge-graph template directory is present (the precondition the negative needs)"
    local hits
    hits=$(find "$dir" -name 'package.json' -type f 2>/dev/null | paste -sd, -)
    if [[ -z "$hits" ]]; then
        pass "GR06.b $label no package.json under the rendered knowledge-graph templates"
    else
        fail "GR06.b $label a package.json ships in a template tree: $hits"
    fi
}
for entry in "${PROFILES[@]}"; do
    p="${entry%%:*}"; r="${entry##*:}"
    check_no_marker "[$p]" "profiles/${p}/${r}/${KG_REL}"
done
check_no_marker "[dogfood]" "${DOGFOOD_ROOT}/${KG_REL}"

# ===========================================================================
# The shared module actually resolves from a RENDERED location
# ===========================================================================
echo ""
echo "=== the rendered predicate resolves under Node, with no marker on its ancestors ==="

NODE_OK=0
if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
    [[ "${NODE_MAJOR:-0}" =~ ^[0-9]+$ ]] || NODE_MAJOR=0
    [[ "$NODE_MAJOR" -ge 20 ]] && NODE_OK=1
fi

# The ancestor chain INSIDE the shipped tree. An adopter's own project root may
# carry a package.json of its own -- which is precisely why the marker must not
# ship inside the tree AID installs.
for entry in "${PROFILES[@]}"; do
    p="${entry%%:*}"; r="${entry##*:}"
    chain_hits=""
    for d in "profiles/${p}/${r}/aid/scripts/graph" "profiles/${p}/${r}/aid/scripts" \
             "profiles/${p}/${r}/aid" "profiles/${p}/${r}"; do
        [[ -f "$d/package.json" ]] && chain_hits="${chain_hits}${d}/package.json,"
    done
    if [[ -z "$chain_hits" ]]; then
        pass "MOD01 [$p] no package.json on the predicate's ancestor chain inside the shipped tree"
    else
        fail "MOD01 [$p] a package.json sits above the predicate inside the shipped tree: $chain_hits"
    fi
done

if [[ "$NODE_OK" -ne 1 ]]; then
    skip "MOD02 the rendered predicate's import check — node >= 20 unavailable (found major '${NODE_MAJOR:-none}')"
else
    for entry in "${PROFILES[@]}"; do
        p="${entry%%:*}"; r="${entry##*:}"
        rendered_dir="profiles/${p}/${r}/aid/scripts/graph"
        [[ -d "$rendered_dir" ]] || continue
        out=$(cd "$rendered_dir" && node --input-type=module -e \
            'import { detectArtifactGaps, kbUnbacked, COVERAGE_BEARING, RELATION_CATEGORY } from "./coverage-predicate.mjs";
             const ok = [detectArtifactGaps, kbUnbacked, COVERAGE_BEARING, RELATION_CATEGORY].every(Boolean);
             console.log(ok ? "BOUND" : "MISSING");' 2>&1)
        assert_eq "$out" "BOUND" "MOD02 [$p] the RENDERED predicate imports and binds all four exports with no marker file"
    done
    # And the sibling detector next to it resolves the module by its own specifier.
    for entry in "${PROFILES[@]}"; do
        p="${entry%%:*}"; r="${entry##*:}"
        det="profiles/${p}/${r}/aid/scripts/graph/detect-kb-gaps.mjs"
        if [[ -f "$det" ]]; then
            out=$(node "$det" --help 2>&1); code=$?
            assert_exit_eq "$code" 0 "MOD03 [$p] the rendered detector runs, so its sibling import resolves in the shipped tree"
        else
            fail "MOD03 [$p] the rendered detector is missing: $det"
        fi
    done
fi

# ===========================================================================
# GR07 -- the sibling clamp over documentation surfaces
# ===========================================================================
echo ""
echo "=== GR07: the documentation sibling clamp ==="

DOC_FILES=(README.md)
while IFS= read -r f; do DOC_FILES+=("$f"); done < <(find docs -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
if [[ "${#DOC_FILES[@]}" -gt 1 ]]; then
    pass "GR07.a non-vacuity: ${#DOC_FILES[@]} hand-authored documentation files enumerated"
else
    fail "GR07.a no documentation file set could be enumerated"
fi
# One grep per slug over the whole set, not one per file per slug.
grep -lF -- "$SIBLING_SLUG" "${DOC_FILES[@]}" 2>/dev/null | sort > "$WORK/sibling.set" || true
grep -lF -- "$SKILL_SLUG" "${DOC_FILES[@]}" 2>/dev/null | sort > "$WORK/subject.set" || true
SIB_N=$(grep -c . "$WORK/sibling.set" || true)
if [[ "${SIB_N:-0}" -gt 0 ]]; then
    pass "GR07.b non-vacuity: $SIB_N documentation files name the sibling skill"
else
    fail "GR07.b no documentation file names '$SIBLING_SLUG' — the clamp has no reference set"
fi
# Every surface that names the sibling must name the subject. Reported BY NAME, so
# a documentation surface added after the contract was written fails loudly instead
# of being missed forever.
UNCLAMPED=$(comm -23 "$WORK/sibling.set" "$WORK/subject.set" | paste -sd, -)
assert_eq "$UNCLAMPED" "" \
    "GR07.c every documentation file naming '$SIBLING_SLUG' also names '$SKILL_SLUG'"

# ===========================================================================
# GR09 -- the site surfaces
# ===========================================================================
echo ""
echo "=== GR09: the site surfaces ==="

SITE_PAGE="site/src/content/docs/skills/${SKILL_SLUG}.md"
SITE_INDEX="site/src/content/docs/skills/index.md"
SITE_METHOD="site/src/content/docs/concepts/methodology.md"

if [[ -d site ]]; then
    assert_file_exists "$SITE_PAGE" "GR09.a the per-skill site page exists"
    if [[ -f "$SITE_INDEX" ]]; then
        # The group heading is located by the SIBLING's own occurrence, never by a
        # line number written into this suite.
        SIB_H=$(awk -v s="$SIBLING_SLUG" '/^## /{h=$0} index($0,s){print h; exit}' "$SITE_INDEX")
        SUB_H=$(awk -v s="$SKILL_SLUG" '/^## /{h=$0} index($0,s){print h; exit}' "$SITE_INDEX")
        if [[ -n "$SIB_H" ]]; then
            pass "GR09.b non-vacuity: the sibling's group heading resolved to '$SIB_H'"
        else
            fail "GR09.b the sibling is not listed in the site roster, so there is no heading to match"
        fi
        assert_eq "$SUB_H" "$SIB_H" "GR09.c the roster lists '$SKILL_SLUG' under the same group heading as its sibling"
    else
        fail "GR09.b the site roster is missing: $SITE_INDEX"
    fi
    if [[ -f "$SITE_METHOD" ]]; then
        assert_file_contains "$SITE_METHOD" "$SKILL_SLUG" \
            "GR09.d the synced methodology copy names '$SKILL_SLUG' (a source edit with no sync run fails here)"
        assert_file_contains "$SITE_METHOD" "$SIBLING_SLUG" \
            "GR09.e non-vacuity: the synced methodology copy names the sibling too"
    else
        fail "GR09.d the synced methodology copy is missing: $SITE_METHOD"
    fi
else
    skip "GR09.a-e the site tree is absent from this checkout"
fi

# ===========================================================================
# Summary
# ===========================================================================
echo ""
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    echo "=== Skipped (${#SKIPPED[@]}) ==="
    for s in "${SKIPPED[@]}"; do echo "  - $s"; done
    echo ""
fi
test_summary
exit $?
