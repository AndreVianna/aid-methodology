#!/usr/bin/env bash
# test-graph-source-enumeration.sh -- feature-004 source/media/external enumeration.
#
# COVERS -- the change set that must re-run this suite; see select-suites.sh.
# A trailing slash means the directory and everything under it. Omitting the
# header entirely is fail-safe (the suite is then always selected); a WRONG
# entry is the only way to lose coverage, so these are reviewed as claims.
# COVERS: canonical/aid/scripts/graph/scan-source.sh
# COVERS: canonical/aid/scripts/graph/significance-rules.sh
# COVERS: canonical/aid/scripts/graph/relationship-schema.sh
# COVERS: canonical/aid/templates/graph/relationship-schema.yml
# COVERS: canonical/aid/scripts/config/read-setting.sh
#
# Subject:
#   canonical/aid/scripts/graph/scan-source.sh        (the single walk)
#   canonical/aid/scripts/graph/significance-rules.sh (the rule library)
#
# AC-MAP -- feature-004's acceptance criteria to the LIVE assertion that closes each.
#   Added 2026-08-06 by the wave-1 gate. task-005 reported this map in its hand-off but
#   never wrote it here, so only 4 of 12 ACs were literally tagged in-file and the rest
#   were unauditable from the suite. An AC with no named assertion here is NOT closed.
#
#     AC-1    R-DOWN-09  (`int:` ids resolve; `ext:` is closed by construction in the
#             emit loop -- verified by code read, no assertion can observe an empty set)
#     AC-16   R-EXCL-01/02, R-IGN-06, R-COLLAPSE-07, R-DOWN-09
#     AC-19   R-EXT-09..12, R-PREMISE-02
#     AC-20   R-COV-01..16, R-IGN-02..23
#     AC-S1   R-QUAL loop           AC-S2  R-EXCL-05/06
#     AC-S3   R-QUAL-07 (Q4-only qualification, no KB carrier), R-NRFNR-04/05
#     AC-S4   R-DOWN-02  (checkable evidence, never `inferred`)
#     AC-S5   R-MEDIA-01/02/04/06   AC-S6  R-MEDIA-11 (an unreferenced image is a node)
#     AC-S7   R-IGN group, R-PREMISE-01..04, and CRITICALLY R-IGN-01/01b/24-27 which
#             drive `--probe` through $REAL_RESOLVER (:113) rather than $STUB. Before
#             task-030 all three ignore-list states were asserted against a stub while
#             the shipped resolver had no --probe at all, so two of three were
#             unreachable in production while AC-S7 read as closed. Do not re-point
#             these at the stub.
#     AC-S8   R-DET group, R-COV-16, R-EXT-08
#     AC-S9   R-QUAL loop + R-QUAL-10..12 (promotion, byte-exact evidence AND
#             evidence_provenance -- the qualifier alone was covered before, so a
#             promotion leaving stale Q3 evidence behind used to pass), R-PRECED-01..05
#             (the derived-Q1 / declared-Q2 P1 tie-break, previously uncovered),
#             R-EVID group, R-D3B-01..11 (all 14 of D3b's evidence templates byte-exact
#             plus a totality check; only 4 of 14 were covered before)
#
#   NOT claimed, and stated so rather than left ambiguous: D5's `observation_kind` enum
#   has no live fixture for `dependency`/`include`/`convention` -- R-REF-08 proves only
#   that no DISALLOWED value appears, not that all six are reachable. And 9 of D2's 16
#   `artifact_class` rules have no direct assertion. Neither is named in task-005's
#   acceptance criteria (only in its Scope, descriptively), so both are residuals for
#   feature-004 rather than gaps in this task's closure.
#
# S1 -- SUBJECT INVOCATION BUDGET: 5 scans, one per distinct input.
#   Enumerated so a future author cannot add a sixth casually: FXA (x2 -- the second
#   is the byte-identity re-run, a genuinely distinct input state), FXB, and FXC (x2 --
#   the two ignore-list states). All 227 assertions read the cached output dirs those
#   5 scans produce, or (R-IGN-14..27, R-LIB) call the rule library / read-setting.sh
#   directly with no scan at all; none re-invokes the subject. `scan_into` at :456 is
#   the wrapper, not a 6th call. Adding an invocation is allowed (S4 forbids trading
#   coverage for time) but it must be counted here.
#
# Scope:
#   Every assertion runs against a SELF-BUILT fixture corpus in a mktemp dir, never
#   against this repository. That is deliberate, and it is the lesson of the first
#   verification pass: two live-repo scans differed (1,203 vs 1,204 nodes) purely
#   because sibling agents were writing into the tree mid-run. A determinism
#   assertion against the live tree therefore asserts the absence of concurrent
#   writers rather than a property of the scanner. A fixture nobody else writes to is
#   the only honest place to assert byte-identity.
#
# The highest-value assertion here is R-NRFNR. awk's two-file `NR==FNR` idiom is
#   still true on the SECOND file's first record when the FIRST file is empty. The
#   first file was the git-exclusion list, which is empty on any tree with nothing
#   gitignored -- so every candidate path was silently dropped and the scanner
#   emitted zero nodes. It is invisible on this repository, which always has
#   something gitignored. Fixture A therefore carries NO .gitignore at all, and
#   R-PREMISE-04 asserts that premise before the group relies on it. Mutant M1 puts
#   the defect back and requires this suite to die.
#
# Groups:
#   R-PREMISE  fixture invariants the other groups depend on
#   R-NRFNR    the empty-exclusion-list regression (the defect this exists for)
#   R-SHEBANG  a shebang-carrying tests/canonical/test-*.sh is entry-point/[HIGH],
#              asserted in BOTH directions -- and NOT named-unit/[LOW], the rejected
#              `declared`-across-clauses reading
#   R-QUAL     all four qualifier values reachable, the value space closed
#   R-MEDIA    the D2a partition, case folding, collapse exemption, disjointness
#   R-COLLAPSE whole-artifact granularity, no fragment in any id
#   R-EVID     the multi-candidate evidence rule: golden bytes + enumerator recompute
#   R-REF      D5 resolution: bare relative, dotted, site-absolute, escape, ambiguous
#   R-EXT      the external registry, tier B, and evidence carrying no absolute path
#   R-COV      the coverage contribution: fixed row order, counts, statuses
#   R-IGN      the ignore list in all three states plus the comma case
#   R-EXCL     the FR-22 exclusion classes, incl. the Class-5-override defect
#   R-DET      byte-identity across two scans of one frozen fixture
#   R-DOWN     the shape downstream consumers now read for real
#   R-LIB      rule-library units (no scan)
#   R-HELP     --help documents exactly the flags the code parses
#
# Runtime shape, because it is not free and the reason is worth recording:
#   The subject costs ~14 s per invocation REGARDLESS of tree size -- a 3-file
#   fixture scans as slowly as a 30-file one, because the cost is the scanner's fixed
#   set of batched processes on Windows Git Bash, not per-file work. Scan COUNT is
#   therefore the only lever, and this suite uses FIVE. Everything else the suite
#   does is fork-free: streams are read into arrays once and every lookup is
#   parameter expansion (measured: 300 command substitutions 20.7 s, 300 plain calls
#   0.16 s), so the suite's own overhead is a rounding error beside the five scans.
#
# Usage:
#   bash test-graph-source-enumeration.sh [-v | --verbose]
#   bash test-graph-source-enumeration.sh --self-mutate   # mutation-test THIS suite
#
#   --self-mutate copies the scripts into a mktemp dir, mutates the COPY by
#   exact-string replacement, and re-runs this suite against the copy requiring a
#   non-zero exit. The tree is never mutated: a sibling suite mutated canonical/ in
#   place and a quota kill left a `return 0` at the top of a live function, so the
#   window between mutate and restore is a liability no result justifies. Every
#   mutant re-checks the source digests afterwards and aborts everything on a change.
#
# Environment:
#   GRAPH_SCRIPTS_DIR  scripts under test (default: canonical/aid/scripts/graph)
#   GRAPH_SCHEMA       relationship-schema.yml (default: the canonical template)
#
# Exit codes:
#   0 -- all assertions pass
#   1 -- one or more assertions failed
#   2 -- the environment cannot support the run (missing subject, or no git)

set -u

VERBOSE=0
MODE="assert"
case "${1:-}" in
    -v|--verbose)  VERBOSE=1 ;;
    --self-mutate) MODE="mutate" ;;
    "")            ;;
    *) echo "test-graph-source-enumeration.sh: unknown argument: $1" >&2; exit 2 ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "${SCRIPT_DIR}/../lib/assert.sh"

GRAPH_DIR="${GRAPH_SCRIPTS_DIR:-${REPO_ROOT}/canonical/aid/scripts/graph}"
SCHEMA="${GRAPH_SCHEMA:-${REPO_ROOT}/canonical/aid/templates/graph/relationship-schema.yml}"
SCAN="${GRAPH_DIR}/scan-source.sh"
LIB="${GRAPH_DIR}/significance-rules.sh"
REAL_RESOLVER="${REPO_ROOT}/canonical/aid/scripts/config/read-setting.sh"

for required in "$SCAN" "$LIB" "$SCHEMA"; do
    if [[ ! -f "$required" ]]; then
        echo "test-graph-source-enumeration.sh: missing subject: $required" >&2
        exit 2
    fi
done
if ! command -v git >/dev/null 2>&1; then
    echo "test-graph-source-enumeration.sh: git is required (the FR-22 exclusions are git-native)" >&2
    exit 2
fi

WORK="$(mktemp -d 2>/dev/null)" || { echo "cannot mktemp" >&2; exit 2; }
cleanup() { cd /; rm -rf "$WORK"; }
trap cleanup EXIT

# ===========================================================================
# Delimited-field helpers -- all fork-free.
#
# Every id/field assertion compares a WHOLE TSV FIELD, never a substring. Substring
# absence standing in for cell absence is a known false-PASS shape here: a path
# legitimately appears inside another row's evidence anchor -- `src/cited.sh` occurs
# in `... (search: "src/cited.sh" in bin/one.sh)` -- so `grep -F src/cited.sh
# nodes.tsv` is true even when no row carries it as an id.
# ===========================================================================

tsv_load() {                       # <array-name> <file>
    local name="$1" file="$2" l
    eval "$name=()"
    while IFS= read -r l; do eval "$name+=(\"\$l\")"; done < "$file"
}
TSV_ROW=""; TSV_OK=0
tsv_row() {                        # <array-name> <exact first field> -> TSV_ROW / TSV_OK
    local name="$1" key="$2" n i l
    TSV_ROW=""; TSV_OK=0
    eval "n=\${#$name[@]}"
    i=0
    while [[ "$i" -lt "$n" ]]; do
        eval "l=\${$name[\$i]}"
        if [[ "${l%%$'\t'*}" == "$key" ]]; then TSV_ROW="$l"; TSV_OK=1; return 0; fi
        i=$((i + 1))
    done
    return 1
}
TSV_FIELD=""
tsv_field() {                      # <row> <1-based field number> -> TSV_FIELD
    local l="$1" k="$2" i=1
    while [[ "$i" -lt "$k" ]]; do
        case "$l" in
            *$'\t'*) l="${l#*$'\t'}" ;;
            *)       TSV_FIELD=""; return 1 ;;
        esac
        i=$((i + 1))
    done
    TSV_FIELD="${l%%$'\t'*}"
}
TSV_N=0
tsv_len() { eval "TSV_N=\${#$1[@]}"; }
TSV_COUNT=0
tsv_count() {                      # <array-name> <field no> <value>
    local name="$1" n="$2" v="$3" len i l
    TSV_COUNT=0
    eval "len=\${#$name[@]}"
    i=0
    while [[ "$i" -lt "$len" ]]; do
        eval "l=\${$name[\$i]}"
        if tsv_field "$l" "$n" && [[ "$TSV_FIELD" == "$v" ]]; then TSV_COUNT=$((TSV_COUNT + 1)); fi
        i=$((i + 1))
    done
}
TSV_FIELDS=""
tsv_field_at() {                   # <array-name> <index> <field no> -> TSV_FIELD
    local name="$1" i="$2" n="$3" l
    eval "l=\${$name[\$i]}"
    tsv_field "$l" "$n"
}

assert_row_present() {
    local name="$1" id="$2" label="$3"
    if tsv_row "$name" "$id"; then pass "$label"
    else fail "$label -- no row whose first field is exactly '$id' in $name"; fi
}
assert_row_absent() {
    local name="$1" id="$2" label="$3"
    if ! tsv_row "$name" "$id"; then pass "$label"
    else fail "$label -- unexpected row whose first field is exactly '$id' in $name"; fi
}
assert_field() {
    local name="$1" id="$2" n="$3" expected="$4" label="$5"
    if ! tsv_row "$name" "$id"; then fail "$label -- no row for '$id' in $name"; return; fi
    tsv_field "$TSV_ROW" "$n"
    if [[ "$TSV_FIELD" == "$expected" ]]; then pass "$label"
    else fail "$label -- field $n: expected '$expected' got '$TSV_FIELD'"; fi
}
assert_field_ne() {
    local name="$1" id="$2" n="$3" unexpected="$4" label="$5"
    if ! tsv_row "$name" "$id"; then fail "$label -- no row for '$id' in $name"; return; fi
    tsv_field "$TSV_ROW" "$n"
    if [[ "$TSV_FIELD" != "$unexpected" ]]; then pass "$label"
    else fail "$label -- field $n was '$unexpected', the value this rule exists to prevent"; fi
}
assert_nonempty_arr() {
    local name="$1" label="$2"
    tsv_len "$name"
    if [[ "$TSV_N" -gt 0 ]]; then pass "$label ($TSV_N rows)"
    else fail "$label -- stream is empty: $name"; fi
}
# A universal over an empty set is vacuously true, so this proves its own set
# non-empty FIRST and fails loudly when it is not.
assert_set_all() {                 # <label> <allowed|values> <array-name> <col>
    local label="$1" allowed="|$2|" name="$3" col="$4" len i l n=0 bad=""
    eval "len=\${#$name[@]}"
    i=0
    while [[ "$i" -lt "$len" ]]; do
        eval "l=\${$name[\$i]}"
        if tsv_field "$l" "$col"; then
            n=$((n + 1))
            case "$allowed" in
                *"|$TSV_FIELD|"*) ;;
                *) if [[ -z "$bad" ]]; then bad="$TSV_FIELD"; fi ;;
            esac
        fi
        i=$((i + 1))
    done
    if [[ "$n" -eq 0 ]]; then
        fail "$label -- the set is EMPTY, so the universal would pass vacuously"; return
    fi
    if [[ -z "$bad" ]]; then pass "$label (over $n rows)"
    else fail "$label -- disallowed value: '$bad'"; fi
}
# Membership of a value in a loaded array's first field, fork-free.
in_first_field() {                 # <array-name> <value>
    tsv_row "$1" "$2"
}

# ===========================================================================
# Fixtures
# ===========================================================================

# Fixture A -- the main corpus. NO .gitignore, deliberately (see R-NRFNR).
build_fixture_a() {
    local d="$1"
    mkdir -p "$d"/{.aid/knowledge,.aid/works/w1,bin,lib,src/deep,docs/images,assets,data} \
             "$d"/{tests/canonical,canonical/skills/aid-demo,canonical/agents/aid-demo} \
             "$d"/{canonical/aid/templates,dashboard/reader,profiles/claude-code,site/dist,node_modules/dep,plain}

    printf 'format_version: 3\nname: fixture-a\n' > "$d/.aid/settings.yml"

    # module-map states the three conventions. It deliberately has NO frontmatter, so
    # it contributes no `sources:` carrier and cannot perturb R-EVID's candidate counts.
    cat > "$d/.aid/knowledge/module-map.md" <<'MM'
# Module Map
- **Where a new skill goes:** create `canonical/skills/aid-<name>/SKILL.md`
- **Where a new agent goes:** create `canonical/agents/aid-<role>/AGENT.md`
- **Where a new helper script goes:** place it under the phase area it serves
MM

    # Two KB documents reach lib/shared.sh through DIFFERENT tokens -- the literal
    # path and the `lib/` glob -- so its clause admits two evidence strings, and the
    # LC_ALL=C-least is beta's, which a sorted-path traversal reaches SECOND.
    cat > "$d/.aid/knowledge/alpha.md" <<'AL'
---
sources:
  - lib/shared.sh
  - docs/guide.md
---
# Alpha
AL
    cat > "$d/.aid/knowledge/beta.md" <<'BE'
---
sources:
  - lib/
---
# Beta
BE

    cat > "$d/.aid/knowledge/external-sources.md" <<'ES'
# External Sources

## Sources

| Key | Origin | Contributed to |
|-----|--------|----------------|
| `docker-dockerfile` | https://docs.docker.com/ | alpha.md |
| `semver-spec` | https://semver.org/ | beta.md |
ES

    printf 'transient work state, never a node\n' > "$d/.aid/works/w1/STATE.md"

    # Q1 by shebang. bin/one.sh cites src/cited.sh by FULL PATH, bin/two.sh by BARE
    # BASENAME, so R-EVID has a real choice between two admissible strings.
    cat > "$d/bin/one.sh" <<'ONE'
#!/usr/bin/env bash
bash src/cited.sh
bash lib/promoted.sh
bash dashboard/reader/parsers.py
cat data/table.csv
cat canonical/aid/templates/agent-boilerplate.md
ONE
    cat > "$d/bin/two.sh" <<'TWO'
#!/usr/bin/env bash
bash cited.sh
TWO

    printf 'shared helper, no shebang, nothing cites it\n'      > "$d/lib/shared.sh"
    printf 'promoted helper, no shebang, cited by bin/one.sh\n' > "$d/lib/promoted.sh"
    printf 'cited helper, no shebang, no Q1/Q2/Q3 carrier\n'    > "$d/src/cited.sh"

    # The D5 shapes, from a file that is itself qualified (shebang) so its bytes are
    # actually scanned at step 9.
    cat > "$d/src/deep/rel.sh" <<'REL'
#!/usr/bin/env bash
cat ../../docs/images/pic.png
cat ../../../outside.txt
cat /pic.png
cat pic.png
REL

    cat > "$d/tests/run-all.sh" <<'RA'
#!/usr/bin/env bash
suites=( tests/canonical/test-*.sh )
echo "${#suites[@]}"
RA
    # THE case: a shebang (Q1, derived) AND the suite glob (Q3, declared). Precedence
    # must pick Q1; the rejected declared-across-clauses reading would pick Q3.
    printf '#!/usr/bin/env bash\necho sample\n' > "$d/tests/canonical/test-sample.sh"
    # No shebang: Q3 only, so named-unit is genuinely reachable and R-SHEBANG-03 is
    # not passing merely because nothing in this fixture can ever be named-unit.
    printf '# no shebang here\necho plain\n'    > "$d/tests/canonical/test-noshebang.sh"

    printf '# Guide\n\n![pic](images/pic.png)\n' > "$d/docs/guide.md"
    printf 'PNGDATA\n' > "$d/docs/images/pic.png"
    printf 'PNGDATA\n' > "$d/assets/pic.png"
    printf 'PNGDATA\n' > "$d/assets/LOGO.PNG"
    printf 'a,b\n1,2\n' > "$d/data/table.csv"
    printf 'print("reader")\n' > "$d/dashboard/reader/parsers.py"
    printf 'boilerplate template\n' > "$d/canonical/aid/templates/agent-boilerplate.md"
    # The P1 tie-break shape the D3a reopen turned on: a path whose ONLY Q1 carrier
    # is the derived executable header, and which ALSO carries a declared Q2 carrier
    # (EMISSION-MANIFEST.md's "canonical/aid/templates/" asset-kind root, below). The
    # clause order (Q1 > Q2) must decide the qualifier; the rejected declared-before-
    # derived-across-clauses reading would pick the declared Q2 evidence instead.
    cat > "$d/canonical/aid/templates/tool-helper.sh" <<'TH'
#!/usr/bin/env bash
echo tool-helper
TH

    printf '# Demo skill\n' > "$d/canonical/skills/aid-demo/SKILL.md"
    printf 'PNGDATA\n'      > "$d/canonical/skills/aid-demo/nested.png"
    printf '# Demo agent\n' > "$d/canonical/agents/aid-demo/AGENT.md"

    cat > "$d/canonical/EMISSION-MANIFEST.md" <<'EM'
# Emission Manifest

## Asset Kinds

| Canonical source | Claude Code |
|-----------------|-------------|
| `canonical/skills/` | `.claude/skills/` |
| `canonical/agents/` | `.claude/agents/` |
| `canonical/aid/templates/` | `.claude/aid/templates/` |
EM

    printf 'rendered copy, never a node\n' > "$d/profiles/claude-code/copy.md"
    printf 'built output, never a node\n'  > "$d/site/dist/bundle.js"
    printf 'vendored, never a node\n'      > "$d/node_modules/dep/index.js"
    printf 'nothing qualifies this\n'      > "$d/plain/orphan.txt"

    git -C "$d" init -q .
}

# Fixture B -- carries a .gitignore, so the git-native arm is non-empty. This is
# where the Class-5-override defect lives: the renderer tree is allow-listed back in
# FROM CLASS 1, but a gitignored __pycache__ beneath it is still generated output.
# It also has no external-sources file at all, which is AC-19's missing-registry case.
build_fixture_b() {
    local d="$1"
    mkdir -p "$d"/{.aid,.claude/skills/generate-profile/scripts/__pycache__,bin}
    printf 'format_version: 3\nname: fixture-b\n' > "$d/.aid/settings.yml"
    printf '__pycache__/\ngenerated_*.sh\n' > "$d/.gitignore"
    printf '#!/usr/bin/env python3\nprint("render")\n' > "$d/.claude/skills/generate-profile/scripts/render.py"
    printf 'COMPILEDBYTES\n' > "$d/.claude/skills/generate-profile/scripts/__pycache__/render.cpython-313.pyc"
    # A GITIGNORED file under the allow-listed renderer tree that WOULD qualify on its
    # own merits (Q1, shebang). This is the discriminating shape for the Class-5
    # widening defect: the pyc alone is not, because nothing can qualify a pyc, so
    # letting it through the git arm changes no stream a reader would notice. With a
    # shebang the same leak produces a visible entry-point NODE.
    printf '#!/usr/bin/env bash\necho generated\n' > "$d/.claude/skills/generate-profile/scripts/generated_helper.sh"
    printf '#!/usr/bin/env bash\necho b\n' > "$d/bin/tool.sh"
    git -C "$d" init -q .
}

# Fixture C -- minimal, for the two end-to-end ignore-list scans.
build_fixture_c() {
    local d="$1"
    mkdir -p "$d/.aid" "$d/keep" "$d/drop"
    printf '#!/usr/bin/env bash\necho keep\n' > "$d/keep/a.sh"
    printf '#!/usr/bin/env bash\necho drop\n' > "$d/drop/b.sh"
    git -C "$d" init -q .
}

# A stub resolver standing in for `read-setting.sh --probe`. The real resolver DOES
# carry --probe (R-IGN-01/-24..-27 assert that against REAL_RESOLVER, not $STUB --
# task-030/W5-8), so this stub is kept only to run fixture C's two end-to-end scans
# against an installed-tree layout isolated from this repository's own resolver,
# never because the real one is unsupported.
build_stub_install() {
    local root="$1"
    mkdir -p "$root/aid/scripts/graph" "$root/aid/scripts/config" "$root/aid/templates/graph"
    cp "$SCAN" "$LIB" "$root/aid/scripts/graph/"
    cp "$SCHEMA" "$root/aid/templates/graph/relationship-schema.yml"
    cat > "$root/aid/scripts/config/read-setting.sh" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
PROBE=0; DPATH=""; FILE=".aid/settings.yml"; DEFAULT=""
while [[ $# -gt 0 ]]; do case "$1" in
  --probe)   PROBE=1; shift ;;
  --path)    DPATH="$2"; shift 2 ;;
  --file)    FILE="$2"; shift 2 ;;
  --default) DEFAULT="$2"; shift 2 ;;
  *) echo "stub: unknown flag: $1" >&2; exit 2 ;;
esac; done
sec="${DPATH%%.*}"; key="${DPATH#*.}"
if [[ ! -f "$FILE" ]]; then
  if [[ $PROBE -eq 1 ]]; then echo undeclared; exit 0; fi
  echo "$DEFAULT"; exit 0
fi
scan() {
  awk -v s="$sec" -v k="$key" -v mode="$1" '
    $0 ~ "^"s":" { ins = 1; next }
    ins && /^[A-Za-z_]/ { ins = 0 }
    ins && $0 ~ "^[[:space:]]+"k":" { decl = 1; inl = 1; next }
    inl && /^[[:space:]]+-[[:space:]]*/ {
      v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v)
      if (mode == "warn" && index(v, ",") > 0)
        print "[read-setting] warning: " s "." k " item \"" v "\" contains a comma; it will be split into separate patterns" > "/dev/stderr"
      items = items (n++ ? "," : "") v
      next
    }
    inl && /^[[:space:]]*[A-Za-z_]/ { inl = 0 }
    END { if (mode == "decl") print (decl ? "declared" : "undeclared"); else print items }
  ' "$FILE"
}
if [[ $PROBE -eq 1 ]]; then scan decl; scan warn >/dev/null; exit 0; fi
out="$(scan items)"
if [[ -n "$out" ]]; then echo "$out"; else echo "$DEFAULT"; fi
STUB
    chmod +x "$root/aid/scripts/config/read-setting.sh"
}

# Run one scan. Never asserts. `--schema` is always explicit so a copied (mutated)
# script tree needs no template directory beside it.
scan_into() {
    local tree="$1" out="$2" errfile="$3" scanner="$4"; shift 4
    ( cd "$tree" && bash "$scanner" --schema "$SCHEMA" --out-dir "$out" "$@" ) 2>"$errfile"
}

# ===========================================================================
if [[ "$MODE" == "assert" ]]; then
# ===========================================================================

FXA="$WORK/fxA"; FXB="$WORK/fxB"; FXC="$WORK/fxC"
OUTA="$WORK/outA"; OUTA2="$WORK/outA2"; OUTB="$WORK/outB"
OUTC1="$WORK/outC1"; OUTC2="$WORK/outC2"
STUB="$WORK/stub"

build_fixture_a "$FXA"
build_fixture_b "$FXB"
build_fixture_c "$FXC"
build_stub_install "$STUB"
STUB_SCAN="$STUB/aid/scripts/graph/scan-source.sh"
cp "$FXA/.aid/knowledge/external-sources.md" "$WORK/ext-abs.md"

# ---- the five scans -------------------------------------------------------
scan_into "$FXA" "$OUTA"  "$WORK/errA"  "$SCAN"; RC_A=$?
scan_into "$FXA" "$OUTA2" "$WORK/errA2" "$SCAN"; RC_A2=$?
scan_into "$FXB" "$OUTB"  "$WORK/errB"  "$SCAN"; RC_B=$?
printf 'format_version: 3\nname: c\ngraph:\n  ignore:\n' > "$FXC/.aid/settings.yml"
scan_into "$FXC" "$OUTC1" "$WORK/errC1" "$STUB_SCAN"; RC_C1=$?
printf 'format_version: 3\nname: c\ngraph:\n  ignore:\n    - drop/**\n' > "$FXC/.aid/settings.yml"
scan_into "$FXC" "$OUTC2" "$WORK/errC2" "$STUB_SCAN" \
    --external-sources "$WORK/ext-abs.md"; RC_C2=$?

tsv_load NA "$OUTA/nodes.tsv";        tsv_load MA "$OUTA/media-nodes.tsv"
tsv_load OA "$OUTA/observations.tsv"; tsv_load CA "$OUTA/candidates.tsv"
tsv_load VA "$OUTA/coverage.tsv"
tsv_load NB "$OUTB/nodes.tsv";        tsv_load MB "$OUTB/media-nodes.tsv"
tsv_load VB "$OUTB/coverage.tsv";     tsv_load CB "$OUTB/candidates.tsv"
tsv_load NC1 "$OUTC1/nodes.tsv";      tsv_load VC1 "$OUTC1/coverage.tsv"
tsv_load NC2 "$OUTC2/nodes.tsv";      tsv_load VC2 "$OUTC2/coverage.tsv"
tsv_load MC2 "$OUTC2/media-nodes.tsv"

# --- R-PREMISE ------------------------------------------------------------
echo "--- R-PREMISE: fixture invariants the rest of the suite rests on ---"
assert_exit_eq "$RC_A"  0 "R-PREMISE-01 fixture A scan completes"
assert_exit_eq "$RC_B"  0 "R-PREMISE-02 fixture B scan completes"
assert_exit_eq "$RC_C1" 0 "R-PREMISE-03 fixture C declared-empty scan completes"
assert_exit_eq "$RC_C2" 0 "R-PREMISE-04 fixture C declared-pattern scan completes"
for s in nodes media-nodes observations candidates coverage; do
    assert_file_exists "$OUTA/$s.tsv" "R-PREMISE-05 fixture A emits $s.tsv"
done
FXA_IGNORED="$( (cd "$FXA" && find . -type f | sed 's|^\./||' \
    | git -C "$FXA" -c core.excludesFile=/dev/null check-ignore --stdin 2>/dev/null) | wc -l | tr -d ' ')"
assert_eq "${FXA_IGNORED:-x}" "0" "R-PREMISE-06 fixture A has NOTHING gitignored (the R-NRFNR premise)"
assert_file_exists "$FXB/.gitignore" "R-PREMISE-07 fixture B does carry a .gitignore"

# --- R-NRFNR: the regression this suite exists for ------------------------
echo "--- R-NRFNR: an empty git-exclusion list must not swallow the candidate set ---"
assert_nonempty_arr NA "R-NRFNR-01 nodes.tsv is non-empty on a tree with nothing gitignored"
assert_nonempty_arr CA "R-NRFNR-02 candidates.tsv is non-empty (the same join feeds it)"
assert_nonempty_arr MA "R-NRFNR-03 media-nodes.tsv is non-empty (the partition ran at all)"
assert_row_present NA "int:bin/one.sh"        "R-NRFNR-04 a plain shebang node survives the exclusion join"
assert_row_present NA "int:tests/run-all.sh"  "R-NRFNR-05 a second, unrelated node survives too"

# --- R-SHEBANG: both directions -------------------------------------------
echo "--- R-SHEBANG: shebang test-*.sh is entry-point/[HIGH], not named-unit/[LOW] ---"
SH_ID="int:tests/canonical/test-sample.sh"
assert_row_present NA "$SH_ID" "R-SHEBANG-01 the shebang test suite is a node"
assert_field    NA "$SH_ID" 4 "entry-point" "R-SHEBANG-02 qualifier is entry-point (Q1 outranks Q3)"
assert_field_ne NA "$SH_ID" 4 "named-unit"  "R-SHEBANG-03 qualifier is NOT named-unit (the rejected reading)"
assert_field    NA "$SH_ID" 6 "derived"     "R-SHEBANG-04 provenance is derived (the shebang, not the declared glob)"
assert_field    NA "$SH_ID" 3 "test-suite"  "R-SHEBANG-05 artifact_class stays test-suite as the discriminator"
tsv_row NA "$SH_ID"; tsv_field "$TSV_ROW" 5; SH_EV="$TSV_FIELD"
assert_output_contains     "$SH_EV" 'executable header'    "R-SHEBANG-06 evidence names the executable header"
assert_output_contains     "$SH_EV" '#!/usr/bin/env bash'  "R-SHEBANG-07 evidence carries the shebang line"
assert_output_not_contains "$SH_EV" 'suite discovery glob' "R-SHEBANG-08 evidence is NOT the declared Q3 carrier"
assert_output_not_contains "$SH_EV" 'tests/run-all.sh'     "R-SHEBANG-09 the carrier order never reached across clauses"
# feature-006 D4's severity map, reproduced only to show where the qualifier lands.
severity_of() { case "$1" in entry-point|public-surface) echo '[HIGH]';; depended-upon) echo '[MEDIUM]';; named-unit) echo '[LOW]';; *) echo '[?]';; esac; }
tsv_row NA "$SH_ID"; tsv_field "$TSV_ROW" 4
assert_eq "$(severity_of "$TSV_FIELD")" "[HIGH]" "R-SHEBANG-10 the emitted qualifier maps to [HIGH]"
assert_eq "$(severity_of named-unit)"   "[LOW]"  "R-SHEBANG-11 named-unit would have mapped to [LOW] -- the severity avoided"
assert_field NA "int:tests/canonical/test-noshebang.sh" 4 "named-unit" \
    "R-SHEBANG-12 a test file WITHOUT a shebang IS named-unit, so R-SHEBANG-03 is not vacuous"

# --- R-QUAL ---------------------------------------------------------------
echo "--- R-QUAL: all four qualifier values reachable, value space closed ---"
for q in entry-point public-surface depended-upon named-unit; do
    tsv_count NA 4 "$q"
    if [[ "$TSV_COUNT" -gt 0 ]]; then pass "R-QUAL qualifier '$q' is emitted ($TSV_COUNT rows)"
    else fail "R-QUAL qualifier '$q' never emitted -- part of the severity domain is unreachable"; fi
done
assert_set_all "R-QUAL-05 every qualifier is one of the four declared values" \
    "entry-point|public-surface|depended-upon|named-unit" NA 4
assert_field NA "int:lib/promoted.sh" 4 "depended-upon" \
    "R-QUAL-06 a Q3 carrier that is also referenced is PROMOTED P3 -> P2"
assert_field NA "int:src/cited.sh" 4 "depended-upon" \
    "R-QUAL-07 a path with no Q1/Q2/Q3 carrier qualifies under Q4 alone"
assert_field NA "int:lib/shared.sh" 4 "named-unit" \
    "R-QUAL-08 a Q3 carrier with no inbound reference stays named-unit"
assert_field NA "int:canonical/skills/aid-demo/" 4 "public-surface" \
    "R-QUAL-09 an asset-kind root makes a skill directory public-surface"
# The promotion moves the whole record, not just the qualifier field: evidence and
# evidence_provenance must be Q4's own, never the superseded Q3 declared strings.
assert_field NA "int:lib/promoted.sh" 5 \
    'lib/promoted.sh -- inbound reference (search: "lib/promoted.sh" in bin/one.sh)' \
    "R-QUAL-10 the promoted node's evidence is the inbound-reference string (byte-exact)"
assert_field NA "int:lib/promoted.sh" 6 "derived" \
    "R-QUAL-11 the promoted node's evidence_provenance is Q4's own (derived), not the superseded Q3 declared class"
assert_field_ne NA "int:lib/promoted.sh" 5 \
    'lib/promoted.sh -- frontmatter sources: entry (search: "lib/" in .aid/knowledge/beta.md)' \
    "R-QUAL-12 and NOT the superseded Q3 evidence beta.md's prefix carrier would have written"

# --- R-PRECED --------------------------------------------------------------
echo "--- R-PRECED: the P1 tie-break -- clause order decides over provenance order ---"
# The shape the D3a reopen turned on: a path whose ONLY Q1 carrier is the DERIVED
# executable header, and which ALSO carries a DECLARED Q2 carrier (EMISSION-MANIFEST's
# canonical/aid/templates/ asset-kind root). The rejected declared-before-derived-
# across-clauses reading would emit public-surface with the Q2 evidence; the clause
# order Q1 > Q2 must decide entry-point with the shebang as evidence instead.
TH_ID="int:canonical/aid/templates/tool-helper.sh"
assert_row_present NA "$TH_ID" "R-PRECED-01 the tie-break fixture path is a node"
assert_field NA "$TH_ID" 4 "entry-point" \
    "R-PRECED-02 qualifier is entry-point -- clause order (Q1 > Q2) decides, never provenance"
assert_field NA "$TH_ID" 6 "derived" \
    "R-PRECED-03 evidence_provenance is derived -- the shebang, not the declared EMISSION-MANIFEST row"
EXP_TH_Q1='canonical/aid/templates/tool-helper.sh -- executable header (search: "#!/usr/bin/env bash" in canonical/aid/templates/tool-helper.sh)'
EXP_TH_Q2='canonical/aid/templates/tool-helper.sh -- asset-kind root (search: "canonical/aid/templates/" in canonical/EMISSION-MANIFEST.md)'
assert_field NA "$TH_ID" 5 "$EXP_TH_Q1" \
    "R-PRECED-04 evidence is the shebang line, byte-exact"
assert_field_ne NA "$TH_ID" 5 "$EXP_TH_Q2" \
    "R-PRECED-05 and NOT the declared Q2 evidence -- the rejected declared-across-clauses reading"

# --- R-MEDIA --------------------------------------------------------------
echo "--- R-MEDIA: the D2a partition precedes significance ---"
assert_row_present MA "int:docs/images/pic.png" "R-MEDIA-01 an image is a media node"
assert_row_absent  NA "int:docs/images/pic.png" "R-MEDIA-02 and is NOT a source-artifact node"
assert_field MA "int:docs/images/pic.png" 3 "image" "R-MEDIA-03 node_kind is image, decided by the extension test"
assert_row_present MA "int:assets/LOGO.PNG" "R-MEDIA-04 an UPPER-CASE extension still classifies as image"
assert_field MA "int:assets/LOGO.PNG" 4 \
  "assets/LOGO.PNG -- extension 'png' listed in relationship-schema.yml (search: \"image_extensions\")" \
  "R-MEDIA-05 the fold is visible in evidence as 'png', byte for byte"
assert_row_present MA "int:canonical/skills/aid-demo/nested.png" \
    "R-MEDIA-06 an image inside a collapsed skill directory survives the collapse"
assert_set_all "R-MEDIA-07 every media node_kind is image or web-page" "image|web-page" MA 3
assert_set_all "R-MEDIA-08 media provenance is declared or derived"    "declared|derived" MA 5
# Field counts: media has 5 (no qualifier field exists to fill), nodes has 7.
MEDIA_NF_BAD=0; tsv_len MA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    if tsv_field_at MA "$i" 6; then MEDIA_NF_BAD=$((MEDIA_NF_BAD + 1)); fi
    i=$((i + 1))
done
assert_eq "$MEDIA_NF_BAD" "0" "R-MEDIA-09 media rows have no 6th field -- no qualifier field exists"
NODE_NF_BAD=0; tsv_len NA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    if ! tsv_field_at NA "$i" 7; then NODE_NF_BAD=$((NODE_NF_BAD + 1)); fi
    i=$((i + 1))
done
assert_eq "$NODE_NF_BAD" "0" "R-MEDIA-10 every node row carries all 7 fields"
SHARED=0; tsv_len MA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at MA "$i" 1
    if in_first_field NA "$TSV_FIELD"; then SHARED=$((SHARED + 1)); fi
    i=$((i + 1))
done
assert_eq "$SHARED" "0" "R-MEDIA-11 the two streams are disjoint by id"

# --- R-COLLAPSE -----------------------------------------------------------
echo "--- R-COLLAPSE: whole-artifact granularity ---"
assert_row_present NA "int:canonical/skills/aid-demo/"        "R-COLLAPSE-01 a skill collapses to its directory id"
assert_row_absent  NA "int:canonical/skills/aid-demo/SKILL.md" "R-COLLAPSE-02 its member file is suppressed"
assert_row_present NA "int:canonical/agents/aid-demo/"        "R-COLLAPSE-03 an agent collapses the same way"
assert_row_absent  NA "int:canonical/agents/aid-demo/AGENT.md" "R-COLLAPSE-04 its member file is suppressed"
assert_field NA "int:canonical/skills/aid-demo/" 3 "skill" "R-COLLAPSE-05 the directory node is class skill"
assert_field NA "int:canonical/agents/aid-demo/" 3 "agent" "R-COLLAPSE-06 the directory node is class agent"
FRAG=0
for arr in NA MA; do
    tsv_len "$arr"; i=0
    while [[ "$i" -lt "$TSV_N" ]]; do
        tsv_field_at "$arr" "$i" 1
        case "$TSV_FIELD" in *'#'*) FRAG=$((FRAG + 1)) ;; esac
        i=$((i + 1))
    done
done
assert_eq "$FRAG" "0" "R-COLLAPSE-07 no emitted id carries a '#' fragment of any kind"

# --- R-EVID ---------------------------------------------------------------
echo "--- R-EVID: LC_ALL=C-least over a multi-candidate set ---"
EXP_SHARED='lib/shared.sh -- frontmatter sources: entry (search: "lib/" in .aid/knowledge/beta.md)'
EXP_SHARED_FIRST='lib/shared.sh -- frontmatter sources: entry (search: "lib/shared.sh" in .aid/knowledge/alpha.md)'
assert_field    NA "int:lib/shared.sh" 5 "$EXP_SHARED" \
    "R-EVID-01 two declared carriers in one clause: the LEAST is emitted (golden bytes)"
assert_field_ne NA "int:lib/shared.sh" 5 "$EXP_SHARED_FIRST" \
    "R-EVID-02 and NOT the one a sorted-path traversal reaches first"
EXP_CITED='src/cited.sh -- inbound reference (search: "cited.sh" in bin/two.sh)'
EXP_CITED_FIRST='src/cited.sh -- inbound reference (search: "src/cited.sh" in bin/one.sh)'
assert_field    NA "int:src/cited.sh" 5 "$EXP_CITED" \
    "R-EVID-03 two citers: the LEAST template-13 string is emitted (golden bytes)"
assert_field_ne NA "int:src/cited.sh" 5 "$EXP_CITED_FIRST" \
    "R-EVID-04 and NOT the citer a sorted walk reaches first"
# Membership + minimality against the SEPARATELY recomputed candidate set, with the
# set asserted multi-membered first: both checks are vacuous on a single candidate.
EVID_CHECK="$(
    export LC_ALL=C
    # shellcheck disable=SC1090
    . "$LIB"
    rows=(
      "6	lib/shared.sh	lib/shared.sh	.aid/knowledge/alpha.md	"
      "6	lib/shared.sh	lib/	.aid/knowledge/beta.md	"
    )
    sig_evidence_candidates_into Q3 declared rows
    echo "COUNT=${#SIG_CANDIDATES[@]}"
    if sig_evidence_select_into; then echo "LEAST=$SIG_EVIDENCE"; fi
    printf 'MEMBER=%s\n' "$(printf '%s\n' "${SIG_CANDIDATES[@]}" | grep -cxF "$SIG_EVIDENCE" || true)"
    printf 'BEFORE=%s\n' "$(printf '%s\n' "${SIG_CANDIDATES[@]}" | LC_ALL=C sort \
        | awk -v e="$SIG_EVIDENCE" '$0 == e { exit } { c++ } END { print c + 0 }')"
)"
assert_output_contains "$EVID_CHECK" "COUNT=2" "R-EVID-05 the recomputed candidate set has 2 members (not vacuous)"
assert_output_contains "$EVID_CHECK" "LEAST=$EXP_SHARED" "R-EVID-06 enumerator+selector agree with the emitted bytes"
assert_output_contains "$EVID_CHECK" "MEMBER=1" "R-EVID-07 the emitted evidence is a MEMBER of the recomputed set"
assert_output_contains "$EVID_CHECK" "BEFORE=0" "R-EVID-08 no member sorts before it under LC_ALL=C"

# --- R-REF ---------------------------------------------------------------
echo "--- R-REF: reference resolution never guesses ---"
assert_nonempty_arr OA "R-REF-01 observations.tsv is non-empty"
obs_kind() {                       # <from-id> <to-id> -> TSV_FIELD
    local f="$1" t="$2" len i l a b
    TSV_FIELD=""
    eval "len=\${#OA[@]}"; i=0
    while [[ "$i" -lt "$len" ]]; do
        eval "l=\${OA[\$i]}"
        a="${l%%$'\t'*}"
        tsv_field "$l" 2; b="$TSV_FIELD"
        if [[ "$a" == "$f" && "$b" == "$t" ]]; then tsv_field "$l" 3; return 0; fi
        i=$((i + 1))
    done
    TSV_FIELD="<none>"; return 1
}
obs_kind "int:docs/guide.md" "int:docs/images/pic.png"
assert_eq "$TSV_FIELD" "image-reference" "R-REF-02 a BARE relative reference resolves against the citing directory"
obs_kind "int:src/deep/rel.sh" "int:docs/images/pic.png"
assert_eq "$TSV_FIELD" "path-reference" "R-REF-03 a ../.. relative reference normalises and resolves"
cand_reason() {                    # <subject> -> TSV_FIELD
    local s="$1" len i l b
    TSV_FIELD=""
    eval "len=\${#CA[@]}"; i=0
    while [[ "$i" -lt "$len" ]]; do
        eval "l=\${CA[\$i]}"
        tsv_field "$l" 2; b="$TSV_FIELD"
        if [[ "$b" == "$s" ]]; then tsv_field "$l" 4; return 0; fi
        i=$((i + 1))
    done
    TSV_FIELD="<none>"; return 1
}
cand_reason "/pic.png";               assert_eq "$TSV_FIELD" "unresolved-reference" \
    "R-REF-04 a site-absolute path is unresolved, never guessed onto a directory"
cand_reason "../../../outside.txt";   assert_eq "$TSV_FIELD" "outside-repo-root" \
    "R-REF-05 a reference normalising above the root is refused"
cand_reason "pic.png";                assert_eq "$TSV_FIELD" "ambiguous-basename" \
    "R-REF-06 a basename matching two nodes is ambiguous, never a coin flip"
DOTDOT=0; tsv_len OA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at OA "$i" 2
    case "$TSV_FIELD" in *'..'*) DOTDOT=$((DOTDOT + 1)) ;; esac
    i=$((i + 1))
done
assert_eq "$DOTDOT" "0" "R-REF-07 no emitted id carries a '..' segment (normalisation precedes id formation)"
assert_set_all "R-REF-08 every observation_kind is one of the six declared kinds" \
    "path-reference|invocation|dependency|include|convention|image-reference" OA 3

# --- R-EXT ---------------------------------------------------------------
echo "--- R-EXT: the external registry under tier B ---"
assert_row_present MA "ext:docker-dockerfile" "R-EXT-01 a registered key becomes a node"
assert_row_present MA "ext:semver-spec"       "R-EXT-02 every registered key, not just the first"
assert_field MA "ext:docker-dockerfile" 3 "web-page" "R-EXT-03 tier B types every key as web-page"
assert_field MA "ext:docker-dockerfile" 5 "declared" "R-EXT-04 the project registered it, so provenance is declared"
assert_field MA "ext:docker-dockerfile" 4 \
  '.aid/knowledge/external-sources.md (search: "docker-dockerfile")' \
  "R-EXT-05 evidence is repo-relative and greppable, byte for byte"
EXT_IMG=0; tsv_len MA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at MA "$i" 1; id="$TSV_FIELD"
    tsv_field_at MA "$i" 3
    case "$id" in ext:*) [[ "$TSV_FIELD" == "image" ]] && EXT_IMG=$((EXT_IMG + 1)) ;; esac
    i=$((i + 1))
done
assert_eq "$EXT_IMG" "0" "R-EXT-06 no external key is typed image under tier B"
# Scan 5 pointed --external-sources at an ABSOLUTE path outside the tree.
assert_field MC2 "ext:docker-dockerfile" 4 'ext-abs.md (search: "docker-dockerfile")' \
    "R-EXT-07 a registry outside the tree degrades to its BASENAME, never an absolute path"
ABSHITS=0
for arr in NC2 MC2 VC2; do
    tsv_len "$arr"; i=0
    while [[ "$i" -lt "$TSV_N" ]]; do
        eval "l=\${$arr[\$i]}"
        case "$l" in *:/*|*/AppData/*|*/tmp/*) ABSHITS=$((ABSHITS + 1)) ;; esac
        i=$((i + 1))
    done
done
assert_eq "$ABSHITS" "0" "R-EXT-08 no absolute path appears in any stream (FR-32 holds across machines)"
# Fixture B has no registry at all: zero external nodes, and that is not an error.
EXTB=0; tsv_len MB; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at MB "$i" 1
    case "$TSV_FIELD" in ext:*) EXTB=$((EXTB + 1)) ;; esac
    i=$((i + 1))
done
assert_eq "$EXTB" "0" "R-EXT-09 a MISSING registry yields zero external nodes (AC-19)"
assert_field VB "kind" 1 "kind" "R-EXT-10 fixture B still emits a coverage contribution"
tsv_field "${VB[2]}" 3; assert_eq "$TSV_FIELD" "absent" \
    "R-EXT-11 the web-page carrier is reported absent"
tsv_field "${VB[2]}" 4; assert_eq "$TSV_FIELD" "0" \
    "R-EXT-12 with a count of 0"

# --- R-COV ---------------------------------------------------------------
echo "--- R-COV: the coverage contribution, in fixed row order ---"
tsv_len VA; assert_eq "$TSV_N" "8" "R-COV-01 exactly eight contribution rows"
cov_pair() { local i="$1" a b; tsv_field_at VA "$i" 1; a="$TSV_FIELD"; tsv_field_at VA "$i" 2; b="$TSV_FIELD"; echo "$a/$b"; }
assert_eq "$(cov_pair 0)" "kind/source-artifact"         "R-COV-02 row 1 is the source-artifact kind"
assert_eq "$(cov_pair 1)" "kind/image"                   "R-COV-03 row 2 is the image kind"
assert_eq "$(cov_pair 2)" "kind/web-page"                "R-COV-04 row 3 is the web-page kind"
assert_eq "$(cov_pair 3)" "kind/image-external"          "R-COV-05 row 4 is the extra image-external row"
assert_eq "$(cov_pair 4)" "kind/source-artifact-dropped" "R-COV-06 row 5 is the extra dropped row"
assert_eq "$(cov_pair 5)" "exclusion/generated-trees"    "R-COV-07 row 6 is the generated-trees exclusion"
assert_eq "$(cov_pair 6)" "exclusion/vendored-code"      "R-COV-08 row 7 is the vendored-code exclusion"
assert_eq "$(cov_pair 7)" "exclusion/ignore-list"        "R-COV-09 row 8 is the ignore-list exclusion"
tsv_field_at VA 0 4; COV_SRC="$TSV_FIELD"; tsv_len NA
assert_eq "$COV_SRC" "$TSV_N" "R-COV-10 the source-artifact count equals the nodes.tsv row count"
tsv_field_at VA 1 4; COV_IMG="$TSV_FIELD"; tsv_count MA 3 "image"
assert_eq "$COV_IMG" "$TSV_COUNT" "R-COV-11 the image count equals the image rows in media-nodes.tsv"
tsv_field_at VA 2 4; COV_WEB="$TSV_FIELD"; tsv_count MA 3 "web-page"
assert_eq "$COV_WEB" "$TSV_COUNT" "R-COV-12 the web-page count equals the web-page rows"
tsv_field_at VA 3 3; COV_IE_S="$TSV_FIELD"; tsv_field_at VA 3 4; COV_IE_C="$TSV_FIELD"
assert_eq "${COV_IE_S}/${COV_IE_C}" "absent/0" "R-COV-13 the blocked external-image arm reports an explicit zero"
tsv_field_at VA 4 5
assert_output_contains "$TSV_FIELD" "paths surviving exclusions that no significance clause qualified:" \
    "R-COV-14 the significance rule's cut is reported"
tsv_field_at VA 0 3; assert_eq "$TSV_FIELD" "present" \
    "R-COV-15 the carrier-instance predicate reports present when source reached the evaluator"
CLOCK=0
for arr in NA MA OA CA VA; do
    tsv_len "$arr"; i=0
    while [[ "$i" -lt "$TSV_N" ]]; do
        eval "l=\${$arr[\$i]}"
        case "$l" in
            *[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T*) CLOCK=$((CLOCK + 1)) ;;
            *[0-9][0-9]:[0-9][0-9]:[0-9][0-9]*)           CLOCK=$((CLOCK + 1)) ;;
        esac
        i=$((i + 1))
    done
done
assert_eq "$CLOCK" "0" "R-COV-16 no timestamp appears in any stream"

# --- R-IGN ---------------------------------------------------------------
echo "--- R-IGN: the ignore list, all three states plus the comma case ---"
# R-IGN-01 drives the probe through REAL_RESOLVER (:113), never $STUB -- this is
# W5-8's oracle half (task-030): the flag's ABSENCE must fail this assertion, not
# merely fail to be exercised. Fixture A's settings.yml carries no graph: section
# at all, so the real resolver's honest answer is `undeclared` at exit 0 -- NOT a
# usage/unsupported failure, which is what the pre-task-030 resolver produced and
# what the old form of this assertion checked for.
REAL_PROBE_RC=0
REAL_PROBE_OUT=""
if [[ -f "$REAL_RESOLVER" ]]; then
    REAL_PROBE_OUT=$(bash "$REAL_RESOLVER" --probe --path graph.ignore --file "$FXA/.aid/settings.yml" 2>/dev/null) \
        || REAL_PROBE_RC=$?
fi
assert_exit_eq "$REAL_PROBE_RC" 0 \
    "R-IGN-01 the real read-setting.sh SUPPORTS --probe and exits 0 (drives REAL_RESOLVER, not \$STUB -- the flag's absence fails this)"
assert_eq "$REAL_PROBE_OUT" "undeclared" \
    "R-IGN-01b and reports undeclared against fixture A's graph-less settings.yml, through the real resolver"
tsv_field_at VA 7 5; IGN_NOTE_A="$TSV_FIELD"; tsv_field_at VA 7 3; IGN_APP_A="$TSV_FIELD"
assert_output_contains "$IGN_NOTE_A" "ignore list unavailable (D-4)" \
    "R-IGN-02 with graph.ignore undeclared the run degrades and SAYS SO in the durable note"
assert_eq "$IGN_APP_A" "no" "R-IGN-03 the ignore arm reports itself not applied"
assert_file_contains "$WORK/errA" "[scan] notice:" "R-IGN-04 and a notice reaches stderr"
tsv_field_at VA 5 3
assert_eq "$TSV_FIELD" "yes" "R-IGN-05 the unconditional exclusions still apply while the list is unavailable"
assert_row_absent NA "int:profiles/claude-code/copy.md" \
    "R-IGN-06 and they really do exclude (a rendered tree stays out)"
# State 2 end-to-end: DECLARED but empty -- applied, excluding nothing.
tsv_field_at VC1 7 3; IGN_APP_C1="$TSV_FIELD"; tsv_field_at VC1 7 5; IGN_NOTE_C1="$TSV_FIELD"
assert_eq "$IGN_APP_C1"  "yes"                 "R-IGN-07 state DECLARED-EMPTY is applied"
assert_eq "$IGN_NOTE_C1" "declared, 0 patterns" "R-IGN-08 and the note says zero patterns"
assert_row_present NC1 "int:drop/b.sh" "R-IGN-09 a declared-EMPTY list excludes nothing"
# State 3 end-to-end: DECLARED with one pattern -- applied, and it bites.
tsv_field_at VC2 7 3; IGN_APP_C2="$TSV_FIELD"; tsv_field_at VC2 7 5; IGN_NOTE_C2="$TSV_FIELD"
assert_eq "$IGN_APP_C2"  "yes"                  "R-IGN-10 state DECLARED is applied"
assert_eq "$IGN_NOTE_C2" "declared, 1 patterns" "R-IGN-11 and the note counts the patterns"
assert_row_absent  NC2 "int:drop/b.sh" "R-IGN-12 the declared pattern really excludes"
assert_row_present NC2 "int:keep/a.sh" "R-IGN-13 while an unmatched path survives (not a wipe-out)"
# The remaining two states through the rule library, which is where the note text and
# the applied flag are decided. This needs no further scan.
IGN_LIB="$(
    export LC_ALL=C
    # shellcheck disable=SC1090
    . "$LIB"
    printf 'format_version: 3\nname: x\n' > "$WORK/set-undecl.yml"
    printf 'format_version: 3\nname: x\ngraph:\n  ignore:\n    - a/**,b/**\n' > "$WORK/set-comma.yml"
    R="$STUB/aid/scripts/config/read-setting.sh"
    sig_probe_ignore_list "$R" "$WORK/set-undecl.yml" "$WORK/pe1"; echo "P_UNDECL=$SIG_PROBE"
    sig_probe_ignore_list "$R" "$WORK/set-comma.yml"  "$WORK/pe2"; echo "P_COMMA=$SIG_PROBE"
    sig_probe_ignore_list "/nonexistent/read-setting.sh" "$WORK/set-undecl.yml"; echo "P_MISSING=$SIG_PROBE"
    sig_ignore_note_into undeclared 0 0;  echo "N_UNDECL=$SIG_NOTE"
    sig_ignore_note_into unsupported 0 0; echo "N_UNSUPP=$SIG_NOTE"
    sig_ignore_note_into declared 0 0;    echo "N_EMPTY=$SIG_NOTE"
    sig_ignore_note_into declared 2 1;    echo "N_COMMA=$SIG_NOTE"
    sig_ignore_applied_into undeclared;   echo "A_UNDECL=$SIG_APPLIED"
    sig_ignore_applied_into declared;     echo "A_DECL=$SIG_APPLIED"
    printf 'WARN=%s\n' "$(grep -c 'contains a comma' "$WORK/pe2" || true)"
)"
assert_output_contains "$IGN_LIB" "P_UNDECL=undeclared" "R-IGN-14 state ABSENT: the probe reports undeclared"
assert_output_contains "$IGN_LIB" "P_COMMA=declared"    "R-IGN-15 a declared list probes as declared"
assert_output_contains "$IGN_LIB" "P_MISSING=unsupported" \
    "R-IGN-16 a resolver without --probe is 'unsupported', NOT silently 'undeclared'"
assert_output_contains "$IGN_LIB" "N_UNDECL=setting absent -- ignore list unavailable (D-4)" \
    "R-IGN-17 the ABSENT note names the absent setting"
assert_output_contains "$IGN_LIB" "N_UNSUPP=probe unsupported by this resolver -- ignore list unavailable (D-4)" \
    "R-IGN-18 the unsupported note is DISTINCT from the absent one"
assert_output_contains "$IGN_LIB" "N_COMMA=declared, 2 patterns (1 item(s) contained a comma and were split)" \
    "R-IGN-19 the comma limitation is carried in the durable note, not only on stderr"
assert_output_contains "$IGN_LIB" "A_UNDECL=no" "R-IGN-20 an unavailable list is not applied"
assert_output_contains "$IGN_LIB" "A_DECL=yes"  "R-IGN-21 a declared list is applied"
assert_output_contains "$IGN_LIB" "WARN=1"      "R-IGN-22 the probe warns on stderr for the comma item"
# R-IGN-24..27 close the other half of W5-8's oracle gap: R-IGN-14/-15 above prove
# the DECLARED states reachable only through $STUB, so re-run the identical checks
# through sig_probe_ignore_list against REAL_RESOLVER (:113) directly -- no scan
# needed, so this costs nothing against the S1 budget. Together with R-IGN-01/-01b
# above (the UNDECLARED state, end-to-end), this is AC-S7's "all three states
# reachable in production, not two of three stub-only" against the real resolver.
IGN_REAL="$(
    export LC_ALL=C
    # shellcheck disable=SC1090
    . "$LIB"
    printf 'format_version: 3\nname: x\ngraph:\n  ignore:\n'                  > "$WORK/real-decl-empty.yml"
    printf 'format_version: 3\nname: x\ngraph:\n  ignore:\n    - drop/**\n'    > "$WORK/real-decl.yml"
    printf 'format_version: 3\nname: x\ngraph:\n  ignore:\n    - a/**,b/**\n' > "$WORK/real-decl-comma.yml"
    sig_probe_ignore_list "$REAL_RESOLVER" "$WORK/real-decl-empty.yml" "$WORK/rpe1"; echo "R_EMPTY=$SIG_PROBE"
    sig_probe_ignore_list "$REAL_RESOLVER" "$WORK/real-decl.yml"       "$WORK/rpe2"; echo "R_DECL=$SIG_PROBE"
    sig_probe_ignore_list "$REAL_RESOLVER" "$WORK/real-decl-comma.yml" "$WORK/rpe3"; echo "R_COMMA=$SIG_PROBE"
    printf 'R_WARN=%s\n' "$(grep -c 'contains a comma' "$WORK/rpe3" || true)"
)"
assert_output_contains "$IGN_REAL" "R_EMPTY=declared" \
    "R-IGN-24 REAL_RESOLVER: state DECLARED-EMPTY probes as declared (not stub-only)"
assert_output_contains "$IGN_REAL" "R_DECL=declared" \
    "R-IGN-25 REAL_RESOLVER: state DECLARED-WITH-PATTERNS probes as declared (not stub-only)"
assert_output_contains "$IGN_REAL" "R_COMMA=declared" \
    "R-IGN-26 REAL_RESOLVER: a comma-containing item still probes as declared"
assert_output_contains "$IGN_REAL" "R_WARN=1" \
    "R-IGN-27 REAL_RESOLVER: the comma item warns on stderr exactly once, through the real resolver"
# The three reports must be pairwise distinct -- that is the whole of FR-22's rule.
if [[ "$IGN_NOTE_A" != "$IGN_NOTE_C1" && "$IGN_NOTE_C1" != "$IGN_NOTE_C2" && "$IGN_NOTE_A" != "$IGN_NOTE_C2" ]]; then
    pass "R-IGN-23 the three observed ignore-list reports are pairwise DISTINCT"
else
    fail "R-IGN-23 two ignore-list states collapsed to the same report"
fi

# --- R-EXCL --------------------------------------------------------------
echo "--- R-EXCL: the FR-22 exclusion classes ---"
assert_row_absent NA "int:site/dist/bundle.js"       "R-EXCL-01 built output is excluded"
assert_row_absent NA "int:node_modules/dep/index.js" "R-EXCL-02 vendored code is excluded"
assert_row_absent NA "int:.aid/works/w1/STATE.md"    "R-EXCL-03 transient work state is excluded"
AIDN=0
for arr in NA MA; do
    tsv_len "$arr"; i=0
    while [[ "$i" -lt "$TSV_N" ]]; do
        tsv_field_at "$arr" "$i" 1
        case "$TSV_FIELD" in
            "int:.aid/settings.yml") ;;
            int:.aid/*) AIDN=$((AIDN + 1)) ;;
        esac
        i=$((i + 1))
    done
done
assert_eq "$AIDN" "0" "R-EXCL-04 nothing under .aid/ becomes a node except the one allowlist entry"
assert_row_absent NA "int:plain/orphan.txt" "R-EXCL-05 file existence alone never qualifies"
DROPPED=0; tsv_len CA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at CA "$i" 1; k="$TSV_FIELD"
    tsv_field_at CA "$i" 2; s="$TSV_FIELD"
    tsv_field_at CA "$i" 4; r="$TSV_FIELD"
    if [[ "$k" == "node" && "$s" == "int:plain/orphan.txt" && "$r" == "no-rule-match" ]]; then DROPPED=1; fi
    i=$((i + 1))
done
assert_eq "$DROPPED" "1" "R-EXCL-06 the unqualified path is recorded with drop_reason no-rule-match"
# The Class-5 defect: the renderer tree is allow-listed back in FROM CLASS 1 and from
# nothing else, so Class 3's git-native arm still cuts generated output beneath it.
#
# Asserting only that the pyc is absent from nodes.tsv is NOT enough, and the mutation
# harness proved it: mutant M5 widens Class 5 into a blanket exemption and SURVIVED
# that assertion, because a pyc cannot qualify under any clause even when the leak
# lets it in -- it lands in candidates.tsv instead and nodes.tsv never changes. The
# discriminating assertions are therefore (a) a gitignored file that WOULD qualify on
# its own merits, and (b) absence from the candidate set, which is where a leaked path
# actually shows up.
assert_row_present NB "int:.claude/skills/generate-profile/scripts/render.py" \
    "R-EXCL-07 the renderer tree IS re-admitted from Class 1"
assert_row_absent NB "int:.claude/skills/generate-profile/scripts/__pycache__/render.cpython-313.pyc" \
    "R-EXCL-08 a GITIGNORED pyc beneath it is not a node"
assert_row_absent MB "int:.claude/skills/generate-profile/scripts/__pycache__/render.cpython-313.pyc" \
    "R-EXCL-09 nor is it smuggled in through the media stream"
assert_row_absent NB "int:.claude/skills/generate-profile/scripts/generated_helper.sh" \
    "R-EXCL-10 a GITIGNORED but otherwise-qualifying script beneath it is still excluded"
GITEX_LEAK=0; tsv_len CB; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at CB "$i" 2; s="$TSV_FIELD"
    case "$s" in
        int:.claude/skills/generate-profile/scripts/__pycache__/*) GITEX_LEAK=$((GITEX_LEAK + 1)) ;;
        int:.claude/skills/generate-profile/scripts/generated_*)   GITEX_LEAK=$((GITEX_LEAK + 1)) ;;
    esac
    i=$((i + 1))
done
assert_eq "$GITEX_LEAK" "0" \
    "R-EXCL-11 a gitignored path under the allowlist never reaches the CANDIDATE set either"
assert_nonempty_arr CB "R-EXCL-12 fixture B does produce candidates, so R-EXCL-11 is not vacuous"

# --- R-DET ---------------------------------------------------------------
echo "--- R-DET: byte-identity across two scans of one frozen fixture ---"
assert_exit_eq "$RC_A2" 0 "R-DET-01 the second scan of the unchanged fixture completes"
for s in nodes media-nodes observations candidates coverage; do
    if cmp -s "$OUTA/$s.tsv" "$OUTA2/$s.tsv"; then pass "R-DET $s.tsv is byte-identical across runs"
    else fail "R-DET $s.tsv differs between two runs of an unchanged tree"; fi
done
for s in nodes media-nodes observations candidates; do
    if LC_ALL=C sort -c "$OUTA/$s.tsv" 2>/dev/null; then pass "R-DET $s.tsv is in LC_ALL=C order"
    else fail "R-DET $s.tsv is not in LC_ALL=C order"; fi
done
CR="$(cat "$OUTA"/*.tsv | tr -dc '\r' | wc -c | tr -d ' ')"
assert_eq "${CR:-x}" "0" "R-DET-11 every stream is LF-only"

# --- R-DOWN --------------------------------------------------------------
echo "--- R-DOWN: the shape downstream consumers read ---"
assert_set_all "R-DOWN-01 nodes.tsv node_kind is the constant source-artifact" "source-artifact" NA 7
assert_set_all "R-DOWN-02 nodes.tsv provenance is declared or derived, never inferred" "declared|derived" NA 6
BADNAME=0; tsv_len NA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at NA "$i" 1; id="$TSV_FIELD"
    tsv_field_at NA "$i" 2; nm="$TSV_FIELD"
    [[ "$nm" == "${id#int:}" ]] || BADNAME=$((BADNAME + 1))
    i=$((i + 1))
done
assert_eq "$BADNAME" "0" "R-DOWN-03 field 2 is always field 1 minus its int: prefix"
EMPTYCLASS=0; tsv_len NA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at NA "$i" 3
    [[ -n "$TSV_FIELD" ]] || EMPTYCLASS=$((EMPTYCLASS + 1))
    i=$((i + 1))
done
assert_eq "$EMPTYCLASS" "0" "R-DOWN-04 artifact_class is total: no row is empty"
# Every observation endpoint must already be a node -- the closed-node-set bound.
tsv_len OA; OBS_N="$TSV_N"
if [[ "$OBS_N" -gt 0 ]]; then
    BADFROM=0; BADTO=0; i=0
    while [[ "$i" -lt "$OBS_N" ]]; do
        tsv_field_at OA "$i" 1; f="$TSV_FIELD"
        tsv_field_at OA "$i" 2; t="$TSV_FIELD"
        in_first_field NA "$f" || in_first_field MA "$f" || BADFROM=$((BADFROM + 1))
        in_first_field NA "$t" || in_first_field MA "$t" || BADTO=$((BADTO + 1))
        i=$((i + 1))
    done
    assert_eq "$BADFROM" "0" "R-DOWN-05 every observation from_id is an emitted node id"
    assert_eq "$BADTO"   "0" "R-DOWN-06 every observation to_id is an emitted node id"
else
    fail "R-DOWN-05 the observation set is empty -- these universals would pass vacuously"
fi
CANDN=0; PROMOTED=0; tsv_len CA; i=0
while [[ "$i" -lt "$TSV_N" ]]; do
    tsv_field_at CA "$i" 1; k="$TSV_FIELD"
    if [[ "$k" == "node" ]]; then
        CANDN=$((CANDN + 1))
        tsv_field_at CA "$i" 2; s="$TSV_FIELD"
        if in_first_field NA "$s" || in_first_field MA "$s"; then PROMOTED=$((PROMOTED + 1)); fi
    fi
    i=$((i + 1))
done
if [[ "$CANDN" -gt 0 ]]; then
    assert_eq "$PROMOTED" "0" "R-DOWN-07 no node candidate was also emitted as a node (no promotion path)"
else
    fail "R-DOWN-07 the candidate-node set is empty -- the universal would pass vacuously"
fi
assert_set_all "R-DOWN-08 every candidate drop_reason is one of the four declared" \
    "no-rule-match|ambiguous-basename|unresolved-reference|outside-repo-root" CA 4
MISSING=0
for arr in NA MA; do
    tsv_len "$arr"; i=0
    while [[ "$i" -lt "$TSV_N" ]]; do
        tsv_field_at "$arr" "$i" 1; id="$TSV_FIELD"
        case "$id" in
            int:*/) [[ -d "$FXA/${id#int:}" ]] || MISSING=$((MISSING + 1)) ;;
            int:*)  [[ -f "$FXA/${id#int:}" ]] || MISSING=$((MISSING + 1)) ;;
        esac
        i=$((i + 1))
    done
done
assert_eq "$MISSING" "0" "R-DOWN-09 every int: id names a path that exists (AC-1)"

# --- R-LIB ---------------------------------------------------------------
echo "--- R-LIB: rule library units ---"
LIBOUT="$(
    export LC_ALL=C
    # shellcheck disable=SC1090
    . "$LIB"
    sig_set_image_extensions png jpg svg
    echo "SHAPEA=$(sig_render_evidence 14 'x.sh' '#!/usr/bin/env bash' 'x.sh')"
    echo "SHAPEB=$(sig_render_evidence 12 'tests/canonical/test-x.sh' 'tests/canonical/test-*.sh' 'tests/run-all.sh' 'tests/canonical/test-*.sh')"
    echo "CLAUSE14=$(sig_template_clause 14)"
    echo "CLAUSE10=$(sig_template_clause 10)"
    echo "PROV14=$(sig_template_provenance 14)"
    echo "PROV10=$(sig_template_provenance 10)"
    echo "STRONGER=$(sig_stronger_clause Q3 Q1)"
    echo "RANKS=$(sig_clause_rank Q1)$(sig_clause_rank Q2)$(sig_clause_rank Q4)$(sig_clause_rank Q3)"
    echo "QUAL1=$(sig_clause_qualifier Q1)"
    echo "QUAL3=$(sig_clause_qualifier Q3)"
    echo "LEVEL1=$(sig_clause_level Q1)$(sig_clause_level Q4)$(sig_clause_level Q3)"
    echo "EXTUP=$(sig_path_extension 'A/LOGO.PNG')"
    echo "EXTDOT=[$(sig_path_extension '.gitignore')]"
    if sig_is_image 'a/b.PNG'; then echo "IMGUP=yes"; else echo "IMGUP=no"; fi
    if sig_is_image 'a/b/';   then echo "IMGDIR=yes"; else echo "IMGDIR=no"; fi
    echo "CLS_TESTS=$(sig_artifact_class 'tests/canonical/test-x.sh')"
    echo "CLS_DASH=$(sig_artifact_class 'dashboard/reader/parsers.py')"
    echo "CLS_TMPL=$(sig_artifact_class 'canonical/aid/templates/x.md')"
    echo "CLS_CATCH=$(sig_artifact_class 'weird/thing.xyz')"
    echo "CLS_SKILL=$(sig_artifact_class 'canonical/skills/aid-x/')"
    if sig_class3_ignored 'lib/x.sh' 'lib/**'; then echo "IGNHIT=yes"; else echo "IGNHIT=no"; fi
    if sig_class3_ignored 'bin/x.sh' 'lib/**'; then echo "IGNMISS=yes"; else echo "IGNMISS=no"; fi
    if sig_class4_excluded '.aid/settings.yml'; then echo "ALLOW=excluded"; else echo "ALLOW=readmitted"; fi
    if sig_class4_excluded '.aid/knowledge/x.md'; then echo "AIDCUT=yes"; else echo "AIDCUT=no"; fi
    if sig_class5_allowlisted '.claude/skills/generate-profile/scripts/x.py'; then echo "C5=yes"; else echo "C5=no"; fi
    echo "TOKEN=[$(sig_token '  - `docs/x.md`  ')]"
    echo "IMGEV=$(sig_render_image_evidence 'A/LOGO.PNG' 'PNG')"
)"
assert_output_contains "$LIBOUT" 'SHAPEA=x.sh -- executable header (search: "#!/usr/bin/env bash" in x.sh)' \
    "R-LIB-01 Shape A renders byte-exactly"
assert_output_contains "$LIBOUT" "SHAPEB=tests/canonical/test-x.sh -- convention 'tests/canonical/test-*.sh' (search: \"tests/canonical/test-*.sh\" in tests/run-all.sh)" \
    "R-LIB-02 Shape B separates the matched pattern from the greppable anchor"
assert_output_contains "$LIBOUT" "CLAUSE14=Q1"     "R-LIB-03 the executable header maps to Q1"
assert_output_contains "$LIBOUT" "CLAUSE10=Q3"     "R-LIB-04 the suite glob maps to Q3"
assert_output_contains "$LIBOUT" "PROV14=derived"  "R-LIB-05 the header is derived evidence"
assert_output_contains "$LIBOUT" "PROV10=declared" "R-LIB-06 the runner glob is declared evidence"
assert_output_contains "$LIBOUT" "STRONGER=Q1"     "R-LIB-07 Q1 outranks Q3 regardless of argument order"
assert_output_contains "$LIBOUT" "RANKS=4321"      "R-LIB-08 the clause order is total: Q1 > Q2 > Q4 > Q3"
assert_output_contains "$LIBOUT" "QUAL1=entry-point" "R-LIB-09 Q1 writes entry-point"
assert_output_contains "$LIBOUT" "QUAL3=named-unit"  "R-LIB-10 Q3 writes named-unit"
assert_output_contains "$LIBOUT" "LEVEL1=P1P2P3"     "R-LIB-11 the precedence levels are P1 > P2 > P3"
assert_output_contains "$LIBOUT" "EXTUP=png"        "R-LIB-12 the extension is folded before the membership test"
assert_output_contains "$LIBOUT" "EXTDOT=[]"        "R-LIB-13 a dotfile with no second dot has no extension"
assert_output_contains "$LIBOUT" "IMGUP=yes"        "R-LIB-14 an upper-case extension is still an image"
assert_output_contains "$LIBOUT" "IMGDIR=no"        "R-LIB-15 a directory artifact is never an image"
assert_output_contains "$LIBOUT" "CLS_TESTS=test-suite"      "R-LIB-16 tests/* precedes the extension rule"
assert_output_contains "$LIBOUT" "CLS_DASH=dashboard-module" "R-LIB-17 dashboard/* precedes the extension rule"
assert_output_contains "$LIBOUT" "CLS_TMPL=template"         "R-LIB-18 templates precede the .md rule"
assert_output_contains "$LIBOUT" "CLS_CATCH=source"          "R-LIB-19 the catch-all makes the enum total"
assert_output_contains "$LIBOUT" "CLS_SKILL=skill"           "R-LIB-20 a directory id resolves to skill"
assert_output_contains "$LIBOUT" "IGNHIT=yes"       "R-LIB-21 an ignore glob matches with case semantics"
assert_output_contains "$LIBOUT" "IGNMISS=no"       "R-LIB-22 and does not over-match"
assert_output_contains "$LIBOUT" "ALLOW=readmitted" "R-LIB-23 the Class 4 allowlist re-admits its one entry"
assert_output_contains "$LIBOUT" "AIDCUT=yes"       "R-LIB-24 while the rest of .aid/ stays cut"
assert_output_contains "$LIBOUT" "C5=yes"           "R-LIB-25 the Class 5 allowlist covers the renderer tree"
assert_output_contains "$LIBOUT" 'TOKEN=[docs/x.md]' "R-LIB-26 token formation strips the marker and the backticks"
assert_output_contains "$LIBOUT" "IMGEV=A/LOGO.PNG -- extension 'png' listed in relationship-schema.yml (search: \"image_extensions\")" \
    "R-LIB-27 the image evidence folds the extension but keeps the path bytes"

# --- R-D3B -----------------------------------------------------------------
# Every D3b template asserted to the byte, one case per carrier. Templates 6, 12, 13
# and 14 are already golden-byte-checked elsewhere (R-EVID over a real scan; R-LIB
# over sig_render_evidence directly) -- this group closes the remaining ten, plus a
# totality check over D3a's carrier -> clause map (all 14 templates, and template 15
# does not exist and must error rather than silently match).
echo "--- R-D3B: every D3b evidence template rendered to the byte; the clause map is total ---"
D3BOUT="$(
    export LC_ALL=C
    # shellcheck disable=SC1090
    . "$LIB"
    echo "T1=$(sig_render_evidence 1 'bin/gen.sh' 'bin/gen.sh' 'canonical/aid/templates/generated-files.txt')"
    echo "T2=$(sig_render_evidence 2 'docs/genout.md' 'docs/genout.md' 'canonical/aid/templates/generated-files.txt')"
    echo "T3=$(sig_render_evidence 3 'canonical/skills/aid-demo/' 'aid-demo' 'canonical/aid/templates/shortcut-catalog.yml')"
    echo "T4=$(sig_render_evidence 4 'canonical/agents/aid-demo/' 'aid-demo' '.aid/settings.yml')"
    echo "T5=$(sig_render_evidence 5 'canonical/skills/aid-demo/' 'canonical/skills/' 'canonical/EMISSION-MANIFEST.md')"
    echo "T7=$(sig_render_evidence 7 'bin/deploy.sh' 'bin/deploy.sh' '.github/workflows/release.yml')"
    echo "T8=$(sig_render_evidence 8 'packages/npm/bin/aid.js' 'bin/aid.js' 'packages/npm/package.json')"
    echo "T9=$(sig_render_evidence 9 'packages/npm/lib/core.js' 'lib/core.js' 'packages/npm/package.json')"
    echo "T10=$(sig_render_evidence 10 'tests/canonical/test-x.sh' 'tests/canonical/test-*.sh' 'tests/run-all.sh')"
    echo "T11=$(sig_render_evidence 11 'canonical/skills/aid-demo/' 'canonical/skills/*/SKILL.md' '.aid/knowledge/module-map.md' 'Where a new skill goes')"
    for t in 1 2 3 4 5 6 7 8 9 10 11 12 13 14; do
        echo "CLS${t}=$(sig_template_clause "$t")"
    done
    if sig_template_clause 15 >/dev/null 2>&1; then echo "CLS15=matched"; else echo "CLS15=rejected"; fi
)"
assert_output_contains "$D3BOUT" 'T1=bin/gen.sh -- build-command script (search: "bin/gen.sh" in canonical/aid/templates/generated-files.txt)' \
    "R-D3B-01 template 1 (build-command script, Q1) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T2=docs/genout.md -- registered output path (search: "docs/genout.md" in canonical/aid/templates/generated-files.txt)' \
    "R-D3B-02 template 2 (registered output path, Q2) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T3=canonical/skills/aid-demo/ -- shortcut catalog row (search: "aid-demo" in canonical/aid/templates/shortcut-catalog.yml)' \
    "R-D3B-03 template 3 (shortcut catalog row, Q2) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T4=canonical/agents/aid-demo/ -- doc_set agent (search: "aid-demo" in .aid/settings.yml)' \
    "R-D3B-04 template 4 (doc_set agent, Q2) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T5=canonical/skills/aid-demo/ -- asset-kind root (search: "canonical/skills/" in canonical/EMISSION-MANIFEST.md)' \
    "R-D3B-05 template 5 (asset-kind root, Q2) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T7=bin/deploy.sh -- workflow command token (search: "bin/deploy.sh" in .github/workflows/release.yml)' \
    "R-D3B-06 template 7 (workflow command token, Q1) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T8=packages/npm/bin/aid.js -- published entry point (search: "bin/aid.js" in packages/npm/package.json)' \
    "R-D3B-07 template 8 (published entry point, Q1) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T9=packages/npm/lib/core.js -- published payload (search: "lib/core.js" in packages/npm/package.json)' \
    "R-D3B-08 template 9 (published payload, Q2) renders byte-exactly"
assert_output_contains "$D3BOUT" 'T10=tests/canonical/test-x.sh -- suite discovery glob (search: "tests/canonical/test-*.sh" in tests/run-all.sh)' \
    "R-D3B-09 template 10 (suite discovery glob, Q3, declared) renders byte-exactly"
assert_output_contains "$D3BOUT" "T11=canonical/skills/aid-demo/ -- convention 'canonical/skills/*/SKILL.md' (search: \"Where a new skill goes\" in .aid/knowledge/module-map.md)" \
    "R-D3B-10 template 11 (Shape B convention, Q2) renders byte-exactly"
# D3a's carrier -> clause map is total over templates 1-14 and closed exactly there.
for pair in 1:Q1 2:Q2 3:Q2 4:Q2 5:Q2 6:Q3 7:Q1 8:Q1 9:Q2 10:Q3 11:Q2 12:Q3 13:Q4 14:Q1; do
    tid="${pair%%:*}"; want="${pair#*:}"
    assert_output_contains "$D3BOUT" "CLS${tid}=${want}" "R-D3B-total template ${tid} maps to clause ${want} (D3a's carrier map, checked at this tid)"
done
assert_output_contains "$D3BOUT" "CLS15=rejected" "R-D3B-11 template 15 does not exist -- the map is closed, not open-ended"

# --- R-HELP --------------------------------------------------------------
echo "--- R-HELP: --help documents exactly what the code parses ---"
HELP_OUT="$(bash "$SCAN" --help 2>&1)"; RC_H=$?
assert_exit_eq "$RC_H" 0 "R-HELP-01 --help exits 0"
DOCUMENTED="$(printf '%s\n' "$HELP_OUT" | grep -oE '^  --[a-z-]+' | tr -d ' ' | sort -u)"
PARSED="$(grep -oE '^ +--[a-z-]+\)' "$SCAN" | tr -d ' )' | sort -u)"
if [[ -n "$DOCUMENTED" && -n "$PARSED" ]]; then
    assert_eq "$DOCUMENTED" "$PARSED" "R-HELP-02 the documented flag set equals the parsed flag set"
else
    fail "R-HELP-02 one of the flag sets is empty -- the comparison would be vacuous"
fi
assert_output_contains "$HELP_OUT" "--schema"           "R-HELP-03 --schema is documented"
assert_output_contains "$HELP_OUT" "--external-sources" "R-HELP-04 --external-sources is documented"
assert_output_contains "$HELP_OUT" "--out-dir"          "R-HELP-05 --out-dir is documented"
UNK_RC=0; bash "$SCAN" --no-such-flag >/dev/null 2>&1 || UNK_RC=$?
assert_exit_eq "$UNK_RC" 2 "R-HELP-06 an unknown flag is a usage error (exit 2)"
LIBH_RC=0; bash "$LIB" --help >/dev/null 2>&1 || LIBH_RC=$?
assert_exit_eq "$LIBH_RC" 0 "R-HELP-07 the library prints its own header on --help"
LIBX_RC=0; bash "$LIB" >/dev/null 2>&1 || LIBX_RC=$?
assert_exit_eq "$LIBX_RC" 2 "R-HELP-08 executing the library directly is a usage error"

echo ""
test_summary
exit $?

# ===========================================================================
else   # MODE == mutate
# ===========================================================================

MUT_SRC="${REPO_ROOT}/canonical/aid/scripts/graph"
SELF="${BASH_SOURCE[0]}"

digest_src() { sha256sum "$MUT_SRC/scan-source.sh" "$MUT_SRC/significance-rules.sh" | awk '{ print $1 }' | tr '\n' ' '; }
BASE_DIGEST="$(digest_src)"

# Exact-string replacement. NO numeric line addresses anywhere: a `sed 'Ns/...'`
# against a line number that shifts is a known false-PASS shape, so the anchor is the
# text itself. Aborts unless the anchor occurs EXACTLY once AND the write changed the
# file -- an anchor that has drifted must fail loudly, never mutate nothing and
# report a survivor.
mutate_apply() {
    local file="$1" from="$2" to="$3" n
    n="$(awk -v s="$from" 'index($0, s) > 0 { c++ } END { print c + 0 }' "$file")"
    if [[ "$n" -ne 1 ]]; then
        echo "    ABORT: anchor occurs $n times (need exactly 1): ${from:0:60}" >&2
        return 1
    fi
    awk -v s="$from" -v r="$to" '
        { p = index($0, s); if (p > 0) $0 = substr($0, 1, p - 1) r substr($0, p + length(s)); print }
    ' "$file" > "$file.mut" || return 1
    if cmp -s "$file" "$file.mut"; then
        echo "    ABORT: replacement changed nothing" >&2
        rm -f "$file.mut"; return 1
    fi
    mv -f "$file.mut" "$file"
}

MUT_TOTAL=0; MUT_KILLED=0; MUT_SURVIVED=0; MUT_ABORTED=0

run_mutant() {
    local name="$1" file="$2" from="$3" to="$4"
    MUT_TOTAL=$((MUT_TOTAL + 1))
    local dir="$WORK/mut$MUT_TOTAL"
    mkdir -p "$dir"
    cp "$MUT_SRC/scan-source.sh" "$MUT_SRC/significance-rules.sh" "$dir/"
    echo "=== $name"
    if ! mutate_apply "$dir/$file" "$from" "$to"; then
        echo "    RESULT: ABORTED (anchor drifted -- the mutant proves nothing; fix the anchor)"
        MUT_ABORTED=$((MUT_ABORTED + 1)); return
    fi
    local out rc=0 flipped
    out="$(GRAPH_SCRIPTS_DIR="$dir" bash "$SELF" 2>&1)" || rc=$?
    flipped="$(printf '%s\n' "$out" | grep -cE '^  FAIL: ' || true)"
    if [[ "$rc" -ne 0 ]]; then
        echo "    RESULT: KILLED (suite exit $rc, $flipped assertion(s) flipped)"
        printf '%s\n' "$out" | grep -E '^  FAIL: ' | head -3 | sed 's/^/      /'
        MUT_KILLED=$((MUT_KILLED + 1))
    else
        echo "    RESULT: *** SURVIVED *** -- this defect is invisible to the suite"
        MUT_SURVIVED=$((MUT_SURVIVED + 1))
    fi
    if [[ "$(digest_src)" == "$BASE_DIGEST" ]]; then
        echo "    source tree: UNTOUCHED (digests match)"
    else
        echo "    source tree: *** MODIFIED *** -- aborting everything"
        exit 1
    fi
}

echo "=========================================================================="
echo " Mutation harness -- mutating COPIES under $WORK, never the tree"
echo " baseline digests: $BASE_DIGEST"
echo "=========================================================================="

run_mutant "M1 the NR==FNR defect put back (an empty first file swallows the second)" \
    scan-source.sh \
    '    BEGIN { while ((getline l < EXCL) > 0) ex[l] = 1; close(EXCL) }' \
    '    NR==FNR { ex[$0] = 1; next }'

run_mutant "M2 media node_kind stops reflecting the extension test (the Q21 proxy)" \
    scan-source.sh \
    'emit_media_row "int:${p}" "$p" "$SIG_KIND_IMAGE"' \
    'emit_media_row "int:${p}" "$p" "$SIG_KIND_SOURCE_ARTIFACT"'

run_mutant "M3 clause precedence inverted -- Q1 becomes the weakest clause" \
    significance-rules.sh \
    '        Q1) SIG_RANK=4 ;;' \
    '        Q1) SIG_RANK=0 ;;'

run_mutant "M4 the evidence selector takes the GREATEST instead of the least" \
    significance-rules.sh \
    '        elif [[ "$c" < "$best" ]]; then' \
    '        elif [[ "$c" > "$best" ]]; then'

run_mutant "M5 Class 5 widened into a blanket exemption (the __pycache__ defect)" \
    scan-source.sh \
    '    if [ "$gitex" = "1" ]; then continue; fi' \
    '    if [ "$gitex" = "1" ] && ! sig_class5_allowlisted "$p"; then continue; fi'

run_mutant "M6 D5 bare relative references stop resolving" \
    scan-source.sh \
    '                nrm = normalise(dir, t)' \
    '                nrm = dotted ? normalise(dir, t) : "!NONE"'

run_mutant "M7 the external registry path leaks into evidence unrelativised" \
    scan-source.sh \
    '    sig_render_external_evidence_into "$EXTERNAL_SOURCES_REL" "$key"' \
    '    sig_render_external_evidence_into "$EXTERNAL_SOURCES" "$key"'

echo "=========================================================================="
echo " mutants: $MUT_TOTAL   killed: $MUT_KILLED   survived: $MUT_SURVIVED   aborted: $MUT_ABORTED"
echo " source tree after every mutant: $(digest_src)"
echo "=========================================================================="
if [[ "$MUT_SURVIVED" -gt 0 || "$MUT_ABORTED" -gt 0 || "$MUT_KILLED" -ne "$MUT_TOTAL" ]]; then
    echo "MUTATION TESTING FAILED"
    exit 1
fi
echo "All mutants killed."
exit 0

fi
