#!/usr/bin/env bash
# test-graph-gap-ledger.sh -- the knowledge-base gap ledger detector, end to end.
#
# Subject under test:
#   canonical/aid/scripts/graph/detect-kb-gaps.mjs, and the boundary between it and
#   canonical/aid/scripts/graph/coverage-predicate.mjs -- the one coverage predicate,
#   executed under Node here and inlined into the graph page in the browser.
#
# Assertions, by the identifier the feature contract gives them:
#   GL01  a coverage-bearing edge clears a gap at ANY Provenance, inferred included
#   GL02  coverage through an ancestor directory path clears a gap (the totality arm)
#   GL03  the no-inferred-node invariant at the seam, and no dropped candidate is a row
#   GL04  severity is a total function of the four-value qualifier; a fifth value aborts
#   GL05  the emitted file is exactly one seven-column reviewer ledger, nothing else
#   GL06  every Line cell is an em dash; every Doc is a real repo-relative path;
#         a directory artifact keeps its trailing separator
#   GL07  many gaps -> a non-empty ledger AND exit 0 (reporting never gates)
#   GL08  grade.sh over the own-artifact ledger is A+ while the gap ledger holds [HIGH]
#   GL09  the kb_gaps ids, the ledger Doc column and an in-test predicate call agree;
#         and no unbacked knowledge-base node appears in either carrier
#   GL10  the Pending -> Fixed -> Recurred lifecycle, renumbering nothing, and leaving
#         a hand-set human-cycle Status untouched
#   GL11  grade.sh over an all-Fixed ledger is A+ (the Status enum is written in the
#         form the grader counts)
#   GL12  the shared module binds all four exports from the detector's own directory
#         with no package.json marker anywhere in that directory
#   GL13  the zero-row node: a row with the right severity, a kb_gaps entry carrying
#         id and name, the exact Description suffix, and disappearance when the node
#         leaves the inventory -- proving the candidate set is the inventory
#   GL14  a candidate row of another kind aborts with exit 2, no ledger, and a message
#         naming the offending id and field
#   GL15  no ledger Doc carries an image extension (case-folded); the image is in the
#         media stream and not the candidate stream; kb_gaps is disjoint from it
#   GL16  the Evidence cell's recheck, parsed out of the emitted ledger and run
#         VERBATIM, reports the rows and returns the same uncovered verdict
#   GL17  the extension-relation counter is non-zero with such a row and zero without
#   GL18  the routing block states the retention shortfall, names the durable carrier
#         and prints the reproduce command; and the shared schema carries no local
#         retention exception (asserted as an ABSENCE)
#   GL19  the cluster line is deterministic, and omitted when no group holds two rows
#   GL20  the route onward is printed, no ticket command is referenced anywhere, and
#         the run's writes are exactly the two declared outputs
#   plus  the exit-code contract over all 27 abort sites, byte determinism across runs,
#         and frontmatter IDEMPOTENCE across first-insert and replace-in-place
#
# Fixture policy, and why it differs from the sibling registration suite:
#   Everything here is SELF-BUILT under .aid/.temp/ (gitignored scratch, removed on
#   exit). Nothing is read from a pipeline work folder, so this suite survives any
#   work folder being pruned. The sibling suite test-graph-skill-registration.sh reads
#   canonical/ and profiles/ directly instead, because there the subject IS the
#   rendered repository and a temporary fixture cannot observe a missed render.
#
#   Every command runs from the repository root with RELATIVE paths. That is not a
#   style choice: this repository is authored on Windows, where a native node.exe
#   cannot resolve an MSYS /c/... absolute path, so no absolute path crosses the
#   bash-to-node boundary anywhere in this file.
#
# Three false-PASS shapes this suite is built to avoid, each one hit for real while
# the detector was being verified:
#   1. a negative fixture built with `sed 'Ns/.../.../'` against a line number that
#      had shifted -- it changed nothing and the case reported a clean exit. EVERY
#      mutation here goes through mutate(), which fails the assertion unless the
#      mutated file actually differs from its source;
#   2. `count=$(grep -c pattern file || echo 0)` emits "0\n0" on no match, which is
#      never equal to "0" -- so every COVERED case was mislabelled. Counting here is
#      `|| true`, never `|| echo`;
#   3. a universal quantified over a set that was empty. Every set comparison below
#      asserts its own set non-empty first.
#
# Usage:
#   bash test-graph-gap-ledger.sh [-v | --verbose]
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

# --- Subject paths, all relative to the repository root ---------------------
DETECTOR="canonical/aid/scripts/graph/detect-kb-gaps.mjs"
PREDICATE="canonical/aid/scripts/graph/coverage-predicate.mjs"
GRAPH_SCRIPT_DIR="canonical/aid/scripts/graph"
GRADE_SH="canonical/aid/scripts/grade.sh"
LEDGER_SCHEMA="canonical/aid/templates/reviewer-ledger-schema.md"
COVERAGE_BEARING_YML="canonical/aid/templates/graph/coverage-bearing.yml"
RELATION_VOCAB_YML="canonical/aid/templates/graph/relation-vocabulary.yml"
RELATIONSHIP_SCHEMA_YML="canonical/aid/templates/graph/relationship-schema.yml"

# The number of abort sites in the detector. Pinned so that adding one without a
# negative case here fails loudly rather than shipping untested.
EXPECTED_ABORT_SITES=27

# --- Skip accounting -------------------------------------------------------
# assert.sh has no skip outcome. A check that cannot run must be recorded as
# skipped and never counted as a pass.
SKIPPED=()
skip() { SKIPPED+=("$*"); echo "  SKIP: $*"; }

# --- Fixture root ----------------------------------------------------------
# $$ keeps concurrent suites from colliding: run-all.sh dispatches in parallel.
FIXTURE=".aid/.temp/graph-gap-ledger-fixture.$$"
rm -rf "$FIXTURE"
mkdir -p "$FIXTURE"
trap 'rm -rf "$FIXTURE"' EXIT

# ===========================================================================
# Helpers
# ===========================================================================

# Copy a file through a sed expression and PROVE the copy differs. A negative
# fixture that silently matched nothing is false-PASS shape 1.
mutate() {
    local src="$1" dst="$2" expr="$3" label="$4"
    sed "$expr" "$src" > "$dst"
    if cmp -s "$src" "$dst"; then
        fail "$label — fixture mutation changed nothing (pattern did not match)"
        return 1
    fi
    pass "$label fixture differs from its source"
    return 0
}

# Count matching lines without the "0\n0" trap of `|| echo 0`.
count_matches() {
    local pattern="$1" file="$2"
    grep -c -- "$pattern" "$file" 2>/dev/null || true
}

# Emit one TSV row of the seven-field candidate record.
node_row() {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

# The ten-column relationship row.
edge_row() {
    printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
        "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10}"
}

# ===========================================================================
# Fixture
# ===========================================================================
# Eight candidates covering all four qualifier values, a directory artifact, two
# zero-row nodes, an ancestor-covered descendant, a mentions-only node and a node
# reachable only through a project-extension relation.
build_fixture() {
    local d="$1"
    mkdir -p "$d/out"

    # --- the candidate inventory: seven tab-separated fields, no header -----
    {
        node_row 'int:bin/entry.sh' 'bin/entry.sh' 'script' 'entry-point' \
                 "bin/entry.sh: '#!/usr/bin/env bash' (derived)" 'derived' 'source-artifact'
        node_row 'int:lib/mentioned.sh' 'lib/mentioned.sh' 'script' 'depended-upon' \
                 'lib/mentioned.sh: sourced at bin/entry.sh (derived)' 'derived' 'source-artifact'
        node_row 'int:pkg/plugin/' 'pkg/plugin/' 'skill' 'public-surface' \
                 'pkg/plugin/: skill entry directory (declared)' 'declared' 'source-artifact'
        node_row 'int:pkg/tools/deep/file.sh' 'pkg/tools/deep/file.sh' 'script' 'named-unit' \
                 "pkg/tools/deep/file.sh: convention 'pkg/tools/**' (declared)" 'declared' 'source-artifact'
        node_row 'int:site/src/a.ts' 'site/src/a.ts' 'source' 'public-surface' \
                 "site/src/a.ts: matched glob 'site/src/*.ts|tsx' (declared)" 'declared' 'source-artifact'
        node_row 'int:site/src/b.ts' 'site/src/b.ts' 'source' 'public-surface' \
                 "site/src/b.ts: export 'mount' (derived)" 'derived' 'source-artifact'
        node_row 'int:tools/gen.mjs' 'tools/gen.mjs' 'script' 'depended-upon' \
                 "tools/gen.mjs: sources: glob 'tools/' in arch.md (declared)" 'declared' 'source-artifact'
        node_row 'int:tools/orphan.sh' 'tools/orphan.sh' 'script' 'named-unit' \
                 "tools/orphan.sh: convention 'tools/*.sh' (declared)" 'declared' 'source-artifact'
    } > "$d/nodes.tsv"

    # --- the media stream: five fields, NO qualifier field at all -----------
    # The upper-case extension is deliberate: the image-extension test folds case,
    # and no ordinary path exercises that.
    {
        printf '%s\t%s\t%s\t%s\t%s\n' 'ext:project-site' 'project-site' 'web-page' \
               'external-sources.md: key project-site (declared)' 'declared'
        printf '%s\t%s\t%s\t%s\t%s\n' 'int:site/img/LOGO.PNG' 'site/img/LOGO.PNG' 'image' \
               "site/img/LOGO.PNG: extension 'png' (declared)" 'declared'
    } > "$d/media-nodes.tsv"

    # --- dropped candidates: qualified only by a reading, so never nodes ----
    {
        printf '%s\t%s\t%s\n' 'int:lib/guessed.sh' 'script' 'qualified-only-by-inference'
        printf '%s\t%s\t%s\n' 'int:doc/notes.txt' 'doc' 'no-significance-clause-matched'
    } > "$d/candidates.tsv"

    # --- the real tree the Doc cells must be openable against ---------------
    mkdir -p "$d/bin" "$d/lib" "$d/pkg/plugin" "$d/pkg/tools/deep" "$d/site/src" \
             "$d/site/img" "$d/tools" "$d/kb"
    : > "$d/bin/entry.sh"
    : > "$d/lib/mentioned.sh"
    : > "$d/pkg/tools/deep/file.sh"
    : > "$d/site/src/a.ts"
    : > "$d/site/src/b.ts"
    : > "$d/site/img/LOGO.PNG"
    : > "$d/tools/gen.mjs"
    : > "$d/tools/orphan.sh"

    # --- the final relationship table --------------------------------------
    {
        printf -- '---\n'
        printf 'objective: |\n  Self-built fixture relationship table.\n'
        printf 'source: generated\n'
        printf 'generator: build-relationships.sh\n'
        printf 'graph_inputs_digest: "fixture0000"\n'
        printf -- '---\n'
        printf '<!-- AUTO-GENERATED by a test fixture builder. -->\n\n'
        printf '# Relationships\n\n'
        edge_row 'Source Id' 'Source Kind' 'Source Name' 'Target Id' 'Target Kind' \
                 'Target Name' 'S2T Relation' 'T2S Relation' 'Provenance' 'Observation'
        printf '|---|---|---|---|---|---|---|---|---|---|\n'
        # mentions-only: a row exists, and it must NOT clear the gap
        edge_row 'int:lib/mentioned.sh' 'source-artifact' 'lib/mentioned.sh' \
                 'kb:kb/arch.md' 'document' 'arch.md' 'mentioned-in' 'mentions' 'inferred' 'pass-2 reading'
        # the ancestor directory: covers pkg/tools/deep/file.sh through condition 1
        edge_row 'int:pkg/tools/' 'source-artifact' 'pkg/tools/' \
                 'kb:kb/arch.md' 'document' 'arch.md' 'documented-by' 'documents' 'declared' 'frontmatter-sources-path'
        # artifact-to-artifact: no knowledge-base endpoint, so no coverage
        edge_row 'int:site/src/a.ts' 'source-artifact' 'site/src/a.ts' \
                 'int:site/src/b.ts' 'source-artifact' 'site/src/b.ts' 'depends-on' 'dependency-of' 'derived' 'import graph'
        # a PROJECT-EXTENSION relation pair: the measured false-gap class
        edge_row 'int:site/src/b.ts' 'source-artifact' 'site/src/b.ts' \
                 'kb:kb/deploy.md' 'document' 'deploy.md' 'deploys-to' 'deployed-from' 'declared' 'project extension'
        # covered, and the covering row is INFERRED -- coverage counts from any provenance
        edge_row 'int:tools/gen.mjs' 'source-artifact' 'tools/gen.mjs' \
                 'kb:kb/arch.md' 'document' 'arch.md' 'documented-by' 'documents' 'inferred' 'pass-2 reading'
        # covered with the knowledge-base node on the SOURCE side (the other reading)
        edge_row 'kb:kb/facts.md#f1' 'fact' '"entry.sh is the runner"' \
                 'int:bin/entry.sh' 'source-artifact' 'bin/entry.sh' 'cites-as-evidence' 'cited-as-evidence-by' 'declared' 'kb-fact-anchor'
        # an in-repo IMAGE in the table: a prefix-keyed implementation would report it
        edge_row 'int:site/img/LOGO.PNG' 'image' 'site/img/LOGO.PNG' \
                 'kb:kb/arch.md' 'document' 'arch.md' 'illustrates' 'illustrated-by' 'declared' 'inline image reference'
        # an unbacked document: no incident source-artifact edge. Lens-only, never a row
        edge_row 'kb:kb/lonely.md' 'document' 'lonely.md' \
                 'kb:kb/terms.md#widget' 'concept' 'Widget' 'mentions' 'mentioned-in' 'declared' 'kb-inline'
        printf '\n## Coverage notes\n\n'
        # THE PARSER TRAP. Column-compatible with the real header, so a parser that
        # runs past the first non-table line reads this as an edge and silently marks
        # the zero-row node covered -- the worst finding vanishing with no error.
        edge_row 'Source Id' 'Source Kind' 'Source Name' 'Target Id' 'Target Kind' \
                 'Target Name' 'S2T Relation' 'T2S Relation' 'Provenance' 'Observation'
        printf '|---|---|---|---|---|---|---|---|---|---|\n'
        edge_row 'kb:kb/arch.md' 'document' 'arch.md' 'int:tools/orphan.sh' 'source-artifact' \
                 'tools/orphan.sh' 'documents' 'documented-by' 'present' 'TRAP: reading past the table covers the zero-row node'
    } > "$d/relationships.md"

    # --- the run's OWN-artifact ledger: a different file, never graded together
    {
        printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n'
        printf '|---|---|---|---|---|---|---|\n'
    } > "$d/graph.md"

    # --- an in-fixture probe of the shared predicate ------------------------
    # Imported by file URL so no absolute native path is ever spelled by hand.
    cat > "$d/predicate-probe.mjs" <<'PROBE'
// Call the shared predicate directly, so the carrier can be checked against what
// the one implementation returns rather than against a second reading of it.
import { pathToFileURL } from 'node:url';
import { readFileSync } from 'node:fs';

const [modulePath, tablePath, nodesPath] = process.argv.slice(2);
const mod = await import(pathToFileURL(modulePath).href);
const BS = String.fromCharCode(92);

const splitRow = (line) => {
	const cells = [];
	let cur = '';
	const t = line.trim();
	for (let i = 0; i < t.length; i += 1) {
		if (t[i] === BS && t[i + 1] === '|') { cur += '|'; i += 1; }
		else if (t[i] === '|') { cells.push(cur); cur = ''; }
		else cur += t[i];
	}
	cells.push(cur);
	return cells.slice(1, -1).map((c) => c.trim());
};

// Parse the table exactly as its contract states: start at the heading, stop at
// the first line that is not a table row.
const lines = readFileSync(tablePath, 'utf8').split('\n');
let i = lines.findIndex((l) => l.trim() === '# Relationships') + 1;
while (lines[i].trim() === '') i += 1;
const header = splitRow(lines[i]);
const at = (name) => header.indexOf(name);
i += 2;
const edges = [];
const nodes = [];
const seen = new Set();
for (; i < lines.length && lines[i].trim().startsWith('|'); i += 1) {
	const c = splitRow(lines[i]);
	const e = {
		sourceId: c[at('Source Id')], sourceKind: c[at('Source Kind')],
		targetId: c[at('Target Id')], targetKind: c[at('Target Kind')],
		s2t: c[at('S2T Relation')], t2s: c[at('T2S Relation')],
	};
	edges.push(e);
	for (const [id, kind] of [[e.sourceId, e.sourceKind], [e.targetId, e.targetKind]]) {
		if (!seen.has(id)) { seen.add(id); nodes.push({ id, kind }); }
	}
}

// The full enumerated inventory -- including nodes in no table row at all.
const nodeIds = readFileSync(nodesPath, 'utf8').split('\n')
	.filter((l) => l.trim() !== '').map((l) => l.split('\t')[0]);

console.log(JSON.stringify({
	gaps: mod.detectArtifactGaps({ nodeIds, edges }),
	unbacked: mod.kbUnbacked({ nodes, edges }),
	coverageBearing: [...mod.COVERAGE_BEARING].sort(),
	relationCount: Object.keys(mod.RELATION_CATEGORY).length,
	categoryCount: new Set(Object.values(mod.RELATION_CATEGORY)).size,
}));
PROBE

    # --- an in-fixture validator for the shared ledger schema ---------------
    cat > "$d/ledger-schema.mjs" <<'SCHEMA'
// Validate a ledger against the project-wide reviewer-ledger schema. Prints one
// "OK <label>" or "BAD <label>" line per check; the caller turns each into a
// suite assertion so a schema breach is reported per property, not in aggregate.
import { readFileSync } from 'node:fs';

const BS = String.fromCharCode(92);
const COLUMNS = ['#', 'Severity', 'Status', 'Doc', 'Line', 'Description', 'Evidence'];
const SEVERITY = ['[CRITICAL]', '[HIGH]', '[MEDIUM]', '[LOW]', '[MINOR]'];
const STATUS = ['Pending', 'Fixed', 'Recurred', 'Accepted', 'OOS', 'Invalid'];
const EM_DASH = String.fromCharCode(0x2014);

const raw = readFileSync(process.argv[2], 'utf8');
const say = (ok, label) => console.log((ok ? 'OK ' : 'BAD ') + label);
const splitRow = (line) => {
	const cells = [];
	let cur = '';
	const t = line.trim();
	for (let i = 0; i < t.length; i += 1) {
		if (t[i] === BS && t[i + 1] === '|') { cur += '|'; i += 1; }
		else if (t[i] === '|') { cells.push(cur); cur = ''; }
		else cur += t[i];
	}
	cells.push(cur);
	return cells.slice(1, -1).map((c) => c.trim());
};

const lines = raw.split('\n');
const body = lines.slice(0, lines.length - 1);
say(!raw.includes(String.fromCharCode(13)), 'GL05.a LF only, no carriage return');
say(raw.endsWith('\n'), 'GL05.b file ends with a newline');
say(lines[lines.length - 1] === '', 'GL05.c exactly one trailing newline');
say(body.length >= 2 && body.every((l) => l.startsWith('|')),
	'GL05.d every line is a table row: no frontmatter, heading, narrative or blank line');
say(!/^#/m.test(raw), 'GL05.e no markdown heading anywhere');
say(!/Summary/.test(raw), 'GL05.f no Summary section');
say(JSON.stringify(splitRow(body[0])) === JSON.stringify(COLUMNS),
	'GL05.g header row is exactly the seven schema columns');
const delim = splitRow(body[1]);
say(delim.length === 7 && delim.every((c) => /^:?-+:?$/.test(c)),
	'GL05.h delimiter row has exactly seven cells');

const seen = new Set();
let n = 0;
for (const line of body.slice(2)) {
	n += 1;
	const c = splitRow(line);
	if (c.length !== 7) { say(false, 'GL05.i row ' + n + ' has ' + c.length + ' cells, not 7'); continue; }
	say(true, 'GL05.i row ' + n + ' has exactly seven cells');
	const uniqueInt = /^[0-9]+$/.test(c[0]) && !seen.has(c[0]);
	seen.add(c[0]);
	say(uniqueInt, 'GL05.j row ' + n + ' number is a unique integer');
	say(SEVERITY.includes(c[1]), 'GL05.k row ' + n + ' Severity in enum (' + c[1] + ')');
	say(STATUS.includes(c[2]), 'GL05.l row ' + n + ' Status in enum (' + c[2] + ')');
	say(c[3] !== '' && !c[3].startsWith('int:'),
		'GL06.a row ' + n + ' Doc is a repo-relative path, prefix stripped (' + c[3] + ')');
	say(c[4] === EM_DASH, 'GL06.b row ' + n + ' Line cell is an em dash');
	say(c[5] !== '' && !c[5].includes('\n'), 'GL05.m row ' + n + ' Description is one non-empty line');
	say(c[6] !== '', 'GL05.n row ' + n + ' Evidence is non-empty');
	say(line.split(BS + '|').join('').split('|').length - 1 === 8,
		'GL05.o row ' + n + ' has exactly eight unescaped pipe delimiters');
}
say(n > 0 || process.argv[3] === 'allow-empty', 'GL05.p the ledger has at least one row');
SCHEMA
}

# Run the detector from the repository root. Echoes nothing; the caller captures.
run_detector() {
    node "$DETECTOR" "$@"
}

build_fixture "$FIXTURE"

# ===========================================================================
# Preflight -- the subject exists, and Node can run it
# ===========================================================================
echo "=== Preflight ==="

assert_file_exists "$DETECTOR" "PRE01 the detector exists"
assert_file_exists "$PREDICATE" "PRE02 the shared predicate module exists"
assert_file_exists "$GRADE_SH" "PRE03 grade.sh exists"
assert_file_exists "$LEDGER_SCHEMA" "PRE04 the reviewer-ledger schema exists"

NODE_OK=0
NODE_MAJOR=0
if command -v node >/dev/null 2>&1; then
    NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
    [[ "${NODE_MAJOR:-0}" =~ ^[0-9]+$ ]] || NODE_MAJOR=0
    if [[ "$NODE_MAJOR" -ge 20 ]]; then
        NODE_OK=1
        pass "PRE05 node present at major $NODE_MAJOR (the ES-module floor is 20)"
    fi
fi
if [[ "$NODE_OK" -ne 1 ]]; then
    skip "PRE05 node >= 20 unavailable (found major '${NODE_MAJOR}') — every executable assertion below is SKIPPED, not passed"
fi

# ===========================================================================
# Static assertions -- true of the source whether or not Node is available
# ===========================================================================
echo ""
echo "=== Static source properties ==="

assert_file_contains "$DETECTOR" '#!/usr/bin/env node' "ST01 the detector carries the node shebang"
for section in '// Purpose:' '// Usage:' '// Exit codes:' '// Output:'; do
    assert_file_contains "$DETECTOR" "$section" "ST02 header block carries '${section#// }'"
done

# One implementation of the predicate. The detector must import it and restate no
# part of it -- a second copy is the defect that unifying the two removed.
assert_file_contains "$DETECTOR" "from './coverage-predicate.mjs'" \
    "ST03 the detector imports the shared predicate as a plain relative sibling"
for forbidden in 'COVERAGE_BEARING = ' 'function isCovered' 'KB_KINDS' 'artifactEndpoints'; do
    assert_file_not_contains "$DETECTOR" "$forbidden" \
        "ST04 the detector declares no '$forbidden' of its own (one predicate, not two)"
done

# Render safety: this file is text-processed into five profile trees.
assert_file_not_contains "$DETECTOR" 'canonical/' \
    "ST05 the detector spells no canonical/ path (it would diverge per rendered copy)"
for ph in '{project_context_file}' '{reviewer_output_file}' '{open_questions_file}'; do
    assert_file_not_contains "$DETECTOR" "$ph" "ST06 the detector carries no $ph placeholder"
done

# The reporting-only boundary, asserted as an absence.
for cmd in '/aid-create-ticket' '/aid-update-ticket' '/aid-read-ticket'; do
    assert_file_not_contains "$DETECTOR" "$cmd" "GL20.a the detector references no $cmd"
done

# GL18's second half: no local retention carve-out was written into the shared schema.
assert_file_not_contains "$LEDGER_SCHEMA" 'graph-kb-gaps' \
    "GL18.a the shared ledger schema carries NO retention exception for graph-kb-gaps.md"

# The abort-site pin. If a new abort is added with no negative case below, this fails.
ABORT_SITES=$(grep -n 'fail(' "$DETECTOR" | grep -vE ':\s*(//|\*|/\*)' | grep -c . || true)
assert_eq "$((ABORT_SITES - 1))" "$EXPECTED_ABORT_SITES" \
    "ST07 the detector has exactly $EXPECTED_ABORT_SITES abort sites, all exercised below"

# ===========================================================================
# The executable half
# ===========================================================================
if [[ "$NODE_OK" -ne 1 ]]; then
    echo ""
    skip "GL01–GL20 and the exit-code sweep — node >= 20 unavailable"
    echo ""
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo "=== Skipped (${#SKIPPED[@]}) ==="
        for s in "${SKIPPED[@]}"; do echo "  - $s"; done
    fi
    echo ""
    test_summary
    exit $?
fi

F="$FIXTURE"
LEDGER="$F/out/graph-kb-gaps.md"

echo ""
echo "=== GL07 / GL20: the run reports and never gates ==="

OUT=$(run_detector --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$LEDGER" 2>&1)
CODE=$?
assert_exit_eq "$CODE" 0 "GL07.a a fixture with five gaps exits 0"
assert_file_exists "$LEDGER" "GL07.b the ledger was written"
ROWS=$(count_matches '^| [0-9]' "$LEDGER")
if [[ "${ROWS:-0}" -gt 0 ]]; then
    pass "GL07.c the ledger is non-empty ($ROWS rows) — many gaps, still exit 0"
else
    fail "GL07.c the ledger is empty — the many-gaps case is the tested case"
fi
assert_output_contains "$OUT" '/aid-update-kb' "GL20.b stdout names the targeted repair skill"
assert_output_contains "$OUT" '/aid-housekeep' "GL20.c stdout names the broad-sweep repair skill"
assert_output_contains "$OUT" 'Route onward' "GL20.d the route onward is printed"

echo ""
echo "=== GL18: the retention shortfall is stated honestly ==="
assert_output_contains "$OUT" 'NOT RETAINED past skill DONE' "GL18.b the block says the ledger does not survive DONE"
assert_output_contains "$OUT" 'kb_gaps:' "GL18.c the block names the durable carrier"
assert_output_contains "$OUT" '/aid-graph --reset' "GL18.d the block prints the reproduce command"
assert_output_contains "$OUT" "$F/out/graph-kb-gaps.md" "GL18.e the block echoes the ledger path it was given"

echo ""
echo "=== GL01 / GL02: what clears a gap ==="
# Each of these asserts the absence of a DOC CELL, delimited by its pipes -- not
# the absence of a substring. A bare substring test fails on a path that merely
# appears inside another row's Evidence anchor, which is a false failure of the
# same family as a fixture that silently matched nothing.
assert_file_not_contains "$LEDGER" '| tools/gen.mjs |' \
    "GL01.a a node covered by a 'documents' edge on an INFERRED row emits no row"
assert_file_not_contains "$LEDGER" '| bin/entry.sh |' \
    "GL01.b a node covered with the knowledge-base node on the source side emits no row"
assert_file_not_contains "$LEDGER" '| pkg/tools/deep/file.sh |' \
    "GL02.a a node covered only through an ancestor directory path emits no row"
# ...and each covered node must really be in the inventory, or the three absences
# above would hold because the node was never a candidate at all.
for covered in 'int:tools/gen.mjs' 'int:bin/entry.sh' 'int:pkg/tools/deep/file.sh'; do
    if grep -q "^${covered}	" "$F/nodes.tsv"; then
        pass "GL01.c non-vacuity: '$covered' IS an enumerated candidate"
    else
        fail "GL01.c non-vacuity: '$covered' is not in the inventory, so its absence proves nothing"
    fi
done
# Non-vacuity for GL02: the descendant IS in the inventory and IS absent from the table.
if grep -q 'int:pkg/tools/deep/file.sh' "$F/nodes.tsv" && \
   ! grep -q 'int:pkg/tools/deep/file.sh' <(sed -n '/^# Relationships/,/^## Coverage notes/p' "$F/relationships.md"); then
    pass "GL02.b non-vacuity: the descendant is enumerated and names no table row of its own"
else
    fail "GL02.b non-vacuity: the ancestor case is not the shape it claims to be"
fi

echo ""
echo "=== KIND: the endpoint Kind is DATA, read from the table's own Kind columns ==="
# This is the pair no other assertion in this file can make, and the one a mutation
# test proved was missing: on a well-formed table the four knowledge-base kinds all
# carry the kb: prefix, so an implementation that INFERRED the kind from the id
# prefix agrees with a correct one on every ordinary row and passes everything else
# here. It takes two probes pointing in opposite directions to separate them, and a
# prefix-inferring implementation gets BOTH backwards.
#
# One candidate, one table row, one cell varied at a time.
node_row 'int:pkg/tools/deep/file.sh' 'pkg/tools/deep/file.sh' 'script' 'named-unit' \
         'pkg/tools/deep/file.sh: convention (declared)' 'declared' 'source-artifact' > "$F/k-nodes.tsv"
kind_table() {
    local out="$1" sid="$2" skind="$3" tid="$4" tkind="$5" s2t="$6" t2s="$7"
    {
        printf -- '---\nsource: generated\n---\n\n# Relationships\n\n'
        edge_row 'Source Id' 'Source Kind' 'Source Name' 'Target Id' 'Target Kind' \
                 'Target Name' 'S2T Relation' 'T2S Relation' 'Provenance' 'Observation'
        printf '|---|---|---|---|---|---|---|---|---|---|\n'
        edge_row "$sid" "$skind" 'n' "$tid" "$tkind" 'n' "$s2t" "$t2s" 'declared' 'kind probe'
    } > "$out"
}
# Emits "COVERED" when the one candidate produced no ledger row, "GAP" when it did.
kind_verdict() {
    local table="$1" led="$F/out/k-led.md"
    rm -f "$led"
    node "$DETECTOR" --table "$table" --nodes "$F/k-nodes.tsv" --output "$led" > /dev/null 2>&1
    local n
    n=$(count_matches '^| [0-9]' "$led")
    if [[ "${n:-0}" -eq 0 ]]; then echo "COVERED"; else echo "GAP"; fi
}

kind_table "$F/k1.md" 'int:pkg/tools/' 'source-artifact' 'kb:kb/a.md' 'document' 'documented-by' 'documents'
assert_eq "$(kind_verdict "$F/k1.md")" "COVERED" \
    "KIND01 control: a document endpoint on an ancestor path, relation toward the artifact, covers it"

kind_table "$F/k2.md" 'int:pkg/tools/' 'source-artifact' 'kb:kb/a.md' 'source-artifact' 'documented-by' 'documents'
assert_eq "$(kind_verdict "$F/k2.md")" "GAP" \
    "KIND02 changing ONLY the Target Kind cell to source-artifact turns COVERED into GAP — a prefix-inferring reading still says COVERED"

kind_table "$F/k3.md" 'int:pkg/tools/' 'source-artifact' 'weird:no-prefix' 'document' 'documented-by' 'documents'
assert_eq "$(kind_verdict "$F/k3.md")" "COVERED" \
    "KIND03 a kind of document with NO kb: prefix still covers — a prefix-inferring reading says GAP"

kind_table "$F/k4.md" 'int:pkg/tools/deep/file.sh' 'source-artifact' 'kb:kb/a.md' 'document' 'documents' 'documented-by'
assert_eq "$(kind_verdict "$F/k4.md")" "GAP" \
    "KIND04 the coverage-bearing relation in the WRONG direction cell does not cover — the direction rule is not symmetric"

kind_table "$F/k5.md" 'int:pkg/other/' 'source-artifact' 'kb:kb/a.md' 'document' 'documented-by' 'documents'
assert_eq "$(kind_verdict "$F/k5.md")" "GAP" \
    "KIND05 a sibling directory is not an ancestor and does not cover"

kind_table "$F/k6.md" 'int:pkg/tools/deep/file.sh' 'source-artifact' 'kb:kb/a.md' 'document' 'mentioned-in' 'mentions'
assert_eq "$(kind_verdict "$F/k6.md")" "GAP" \
    "KIND06 a bare mention on the node itself does not cover — condition 3 is live"

# The Source-side readings of the same pair, so neither cell is asserted in one
# orientation only.
kind_table "$F/k7.md" 'kb:kb/a.md' 'document' 'int:pkg/tools/deep/file.sh' 'source-artifact' 'documents' 'documented-by'
assert_eq "$(kind_verdict "$F/k7.md")" "COVERED" \
    "KIND07 the same coverage with the knowledge-base node as the row's Source"
kind_table "$F/k8.md" 'kb:kb/a.md' 'source-artifact' 'int:pkg/tools/deep/file.sh' 'source-artifact' 'documents' 'documented-by'
assert_eq "$(kind_verdict "$F/k8.md")" "GAP" \
    "KIND08 changing ONLY the Source Kind cell turns that coverage into a GAP"
kind_table "$F/k9.md" 'weird:no-prefix' 'document' 'int:pkg/tools/deep/file.sh' 'source-artifact' 'documents' 'documented-by'
assert_eq "$(kind_verdict "$F/k9.md")" "COVERED" \
    "KIND09 a Source kind of document with NO kb: prefix still covers"

echo ""
echo "=== the parser trap: the coverage notes must never be read as edges ==="
assert_file_contains "$LEDGER" 'tools/orphan.sh' \
    "TRAP.a the zero-row node IS reported — the notes' column-compatible row did not cover it"
assert_file_contains "$F/relationships.md" 'TRAP: reading past the table' \
    "TRAP.b non-vacuity: the trap row is present in the fixture's coverage notes"
if grep -A2 '^## Coverage notes' "$F/relationships.md" | grep -q 'Source Id'; then
    pass "TRAP.c non-vacuity: the trap table repeats the real ten-column header"
else
    fail "TRAP.c the trap is not column-compatible, so it would fail loudly instead of silently"
fi

echo ""
echo "=== GL13: the zero-row node ==="
assert_file_contains "$LEDGER" '; no relationships in the table)' \
    "GL13.a the zero-row Description carries the exact suffix, closing parenthesis included"
if grep -q '^| [0-9]* | \[LOW\] | Pending | tools/orphan.sh ' "$LEDGER"; then
    pass "GL13.b the zero-row node's severity comes from its named-unit qualifier"
else
    fail "GL13.b the zero-row node's row is missing or mis-ranked"
fi
assert_file_contains "$F/relationships.md" 'name: "tools/orphan.sh"' \
    "GL13.c the kb_gaps entry carries name as well as id, so a zero-row node is presentable"
assert_file_contains "$F/relationships.md" 'id: "int:tools/orphan.sh"' \
    "GL13.d the kb_gaps entry carries the node id"

# Remove the node from the inventory only -- the table is untouched. The row must
# disappear, which is what proves the candidate set is the inventory.
if mutate "$F/nodes.tsv" "$F/nodes-no-orphan.tsv" '/^int:tools\/orphan\.sh\t/d' "GL13.e"; then
    cp "$F/relationships.md" "$F/rel-no-orphan.md"
    run_detector --table "$F/rel-no-orphan.md" --nodes "$F/nodes-no-orphan.tsv" \
        --output "$F/out/led-no-orphan.md" > /dev/null 2>&1
    assert_file_not_contains "$F/out/led-no-orphan.md" 'tools/orphan.sh' \
        "GL13.f removing the node from the inventory removes the row — the candidate set is the inventory, not the table"
fi

echo ""
echo "=== GL04: severity is a total function of the qualifier ==="
for pair in 'entry-point:bin/entry.sh' 'public-surface:site/src/a.ts' \
            'depended-upon:lib/mentioned.sh' 'named-unit:tools/orphan.sh'; do
    q="${pair%%:*}"
    if grep -q "	${q}	" "$F/nodes.tsv"; then
        pass "GL04.a the fixture exercises qualifier '$q'"
    else
        fail "GL04.a the fixture never exercises qualifier '$q'"
    fi
done
for pair in 'HIGH:site/src/a.ts' 'MEDIUM:lib/mentioned.sh' 'LOW:tools/orphan.sh'; do
    sev="${pair%%:*}"; doc="${pair##*:}"
    if grep -q "| \[${sev}\] | Pending | ${doc} " "$LEDGER"; then
        pass "GL04.b '$doc' is ranked [$sev]"
    else
        fail "GL04.b '$doc' is not ranked [$sev]"
    fi
done
assert_file_not_contains "$LEDGER" '[CRITICAL]' "GL04.c [CRITICAL] is never assigned"
assert_file_not_contains "$LEDGER" '[MINOR]'    "GL04.d [MINOR] is never assigned"

echo ""
echo "=== GL05 / GL06: the emitted file is exactly one seven-column ledger ==="
while IFS= read -r line; do
    case "$line" in
        'OK '*)  pass "${line#OK }" ;;
        'BAD '*) fail "${line#BAD }" ;;
    esac
done < <(node "$F/ledger-schema.mjs" "$LEDGER")

# GL06's other half: every Doc names something that exists in the fixture tree.
DOC_CHECKED=0
while IFS= read -r doc; do
    [[ -z "$doc" ]] && continue
    DOC_CHECKED=$((DOC_CHECKED + 1))
    if [[ -e "$F/$doc" ]]; then
        pass "GL06.c Doc '$doc' exists in the fixture tree"
    else
        fail "GL06.c Doc '$doc' names nothing in the fixture tree"
    fi
done < <(sed -n 's/^| [0-9]* | \[[A-Z]*\] | [A-Za-z]* | \([^|]*\) |.*/\1/p' "$LEDGER" | sed 's/ *$//')
if [[ "$DOC_CHECKED" -gt 0 ]]; then
    pass "GL06.d non-vacuity: $DOC_CHECKED Doc cells were parsed and checked"
else
    fail "GL06.d non-vacuity: no Doc cell was parsed, so GL06.c asserted nothing"
fi
assert_file_contains "$LEDGER" '| pkg/plugin/ |' \
    "GL06.e a directory artifact's Doc cell keeps its trailing separator"

echo ""
echo "=== GL03: the no-inferred-node invariant, at the seam ==="
BAD_PROV=$(awk -F'\t' '$6 != "declared" && $6 != "derived" { print $1 }' "$F/nodes.tsv" | grep -c . || true)
assert_eq "${BAD_PROV:-x}" "0" \
    "GL03.a every enumerated node carries evidence_provenance of declared or derived"
INV_ROWS=$(grep -c . "$F/nodes.tsv" || true)
if [[ "${INV_ROWS:-0}" -gt 0 ]]; then
    pass "GL03.b non-vacuity: the inventory holds $INV_ROWS rows to quantify over"
else
    fail "GL03.b non-vacuity: the inventory is empty, so GL03.a holds trivially"
fi
CAND_ROWS=$(grep -c . "$F/candidates.tsv" || true)
if [[ "${CAND_ROWS:-0}" -gt 0 ]]; then
    pass "GL03.c non-vacuity: the dropped-candidate stream holds $CAND_ROWS rows"
else
    fail "GL03.c non-vacuity: candidates.tsv is empty, so GL03.d holds trivially"
fi
while IFS= read -r cid; do
    [[ -z "$cid" ]] && continue
    cpath="${cid#int:}"
    assert_file_not_contains "$LEDGER" "| $cpath |" \
        "GL03.d the dropped candidate '$cpath' is not a ledger row"
    assert_file_not_contains "$F/relationships.md" "id: \"$cid\"" \
        "GL03.e the dropped candidate '$cpath' is not a kb_gaps entry"
done < <(cut -f1 "$F/candidates.tsv")

echo ""
echo "=== GL15: the keying, from the output side ==="
# The extension list is read from the schema carrier, never restated here.
IMG_EXT=$(sed -n 's/^image_extensions: *\[\(.*\)\]/\1/p' "$RELATIONSHIP_SCHEMA_YML" | tr -d ' ' | tr ',' ' ')
if [[ -n "$IMG_EXT" ]]; then
    pass "GL15.a non-vacuity: image_extensions read from the schema carrier ($IMG_EXT)"
else
    fail "GL15.a image_extensions could not be read from $RELATIONSHIP_SCHEMA_YML"
fi
for ext in $IMG_EXT; do
    HITS=$(sed -n 's/^| [0-9]* | \[[A-Z]*\] | [A-Za-z]* | \([^|]*\) |.*/\1/p' "$LEDGER" \
           | tr 'A-Z' 'a-z' | grep -c "\.${ext}[[:space:]]*$" || true)
    assert_eq "${HITS:-x}" "0" "GL15.b no ledger Doc has the image extension '.$ext' (case-folded)"
done
assert_file_contains "$F/media-nodes.tsv" 'int:site/img/LOGO.PNG' \
    "GL15.c the in-repo image is in the media stream"
assert_file_not_contains "$F/nodes.tsv" 'int:site/img/LOGO.PNG' \
    "GL15.d the in-repo image is NOT in the candidate stream"
assert_file_contains "$F/relationships.md" 'int:site/img/LOGO.PNG' \
    "GL15.e non-vacuity: the image IS in the table, so a prefix-keyed reading would have reported it"
while IFS= read -r mid; do
    [[ -z "$mid" ]] && continue
    assert_file_not_contains "$F/relationships.md" "id: \"$mid\"" \
        "GL15.f the kb_gaps id set is disjoint from the media stream ('$mid')"
done < <(cut -f1 "$F/media-nodes.tsv")

echo ""
echo "=== GL09: the ledger, the carrier and the one predicate agree ==="
PROBE_JSON=$(node "$F/predicate-probe.mjs" "$PREDICATE" "$F/relationships.md" "$F/nodes.tsv" 2>&1)
PROBE_CODE=$?
if [[ "$PROBE_CODE" -ne 0 ]]; then
    fail "GL09.a the in-test predicate call failed — $PROBE_JSON"
else
    pass "GL09.a the shared predicate is callable directly from a test"
    PRED_GAPS=$(node -e 'const d=JSON.parse(process.argv[1]);console.log(d.gaps.map(i=>i.replace(/^int:/,"")).sort().join(","))' "$PROBE_JSON")
    LEDGER_DOCS=$(sed -n 's/^| [0-9]* | \[[A-Z]*\] | [A-Za-z]* | \([^|]*\) |.*/\1/p' "$LEDGER" | sed 's/ *$//' | sort | paste -sd, -)
    KB_GAPS_IDS=$(sed -n 's/^  - id: "int:\(.*\)"$/\1/p' "$F/relationships.md" | sort | paste -sd, -)
    if [[ -n "$PRED_GAPS" ]]; then
        pass "GL09.b non-vacuity: the predicate returned a non-empty gap set"
    else
        fail "GL09.b non-vacuity: the predicate returned no gaps, so the equalities are trivial"
    fi
    assert_eq "$LEDGER_DOCS" "$PRED_GAPS" "GL09.c the ledger Doc column equals the predicate's own gap set"
    assert_eq "$KB_GAPS_IDS" "$PRED_GAPS" "GL09.d the kb_gaps id list equals the predicate's own gap set"

    UNBACKED=$(node -e 'const d=JSON.parse(process.argv[1]);console.log(d.unbacked.join(" "))' "$PROBE_JSON")
    if [[ -n "$UNBACKED" ]]; then
        pass "GL09.e non-vacuity: the fixture yields an unbacked knowledge-base node ($UNBACKED)"
    else
        fail "GL09.e non-vacuity: the fixture yields no unbacked node, so GL09.f asserts nothing"
    fi
    for u in $UNBACKED; do
        assert_file_not_contains "$LEDGER" "$u" "GL09.f the unbacked node '$u' has NO ledger row (lens-only)"
        assert_file_not_contains "$F/relationships.md" "id: \"$u\"" \
            "GL09.g the unbacked node '$u' is NOT a kb_gaps entry"
    done
    OVERLAP=$(node -e 'const d=JSON.parse(process.argv[1]);const g=new Set(d.gaps);console.log(d.unbacked.filter(u=>g.has(u)).join(" "))' "$PROBE_JSON")
    assert_eq "$OVERLAP" "" "GL09.h the unbacked set and the gap set are disjoint — two classes, two exports"

    # The reviewable copy of the coverage-bearing selection must equal the executable one.
    YML_CB=$(sed -n 's/^  - \([a-z-]*\)$/\1/p' "$COVERAGE_BEARING_YML" | sort | paste -sd, -)
    EXEC_CB=$(node -e 'const d=JSON.parse(process.argv[1]);console.log(d.coverageBearing.join(","))' "$PROBE_JSON")
    assert_eq "$YML_CB" "$EXEC_CB" "GL09.i the reviewable coverage_bearing list equals the executable constant"
    VOCAB_N=$(grep -cE '^[[:space:]]*-[[:space:]]+relation:' "$RELATION_VOCAB_YML" || true)
    EXEC_N=$(node -e 'const d=JSON.parse(process.argv[1]);console.log(d.relationCount)' "$PROBE_JSON")
    assert_eq "${VOCAB_N:-x}" "$EXEC_N" "GL09.j the vocabulary's relation-key count equals RELATION_CATEGORY's entry count"
fi

echo ""
echo "=== GL16: the Evidence cell never contradicts the row it justifies ==="
RECHECK=$(sed -n 's/.*coverage recheck: node detect-kb-gaps\.mjs \(--explain int:lib\/mentioned\.sh[^|]*\).*/\1/p' "$LEDGER" | sed 's/ *$//')
if [[ -n "$RECHECK" ]]; then
    pass "GL16.a the mentions-only row's Evidence cell carries a recheck command"
    for flag in '--explain' '--table' '--nodes'; do
        assert_output_contains "$RECHECK" "$flag" "GL16.b the cell spells out $flag (a partial command would exit 2)"
    done
    # Run it VERBATIM. Word-splitting is the point: this is the reviewer's paste.
    # shellcheck disable=SC2086
    EXP=$(node "$DETECTOR" $RECHECK 2>&1)
    EXP_CODE=$?
    assert_exit_eq "$EXP_CODE" 0 "GL16.c the pasted recheck runs clean"
    assert_output_contains "$EXP" 'mentions' "GL16.d it names 'mentions' as the relation toward the artifact"
    assert_output_contains "$EXP" 'uncovered' "GL16.e it returns the same uncovered verdict"
    assert_output_contains "$EXP" 'rows naming this artifact: 1' "GL16.f it lists the row that exists"
    assert_file_contains "$LEDGER" '| lib/mentioned.sh |' "GL16.g and the row is emitted all the same"
    # The withdrawn recheck form, over the same node, returns non-zero -- which is
    # exactly why a count could not stand in for the predicate.
    GREPC=$(count_matches 'int:lib/mentioned.sh' "$F/relationships.md")
    if [[ "${GREPC:-0}" -gt 0 ]]; then
        pass "GL16.h the withdrawn 'grep -c' recheck returns $GREPC for a node that IS a gap"
    else
        fail "GL16.h the withdrawn recheck form no longer demonstrates the contradiction"
    fi
else
    fail "GL16.a no recheck command could be parsed out of the ledger's Evidence cell"
fi

echo ""
echo "=== GL17: the extension-relation counter ==="
assert_output_contains "$OUT" 'Rows typed by a project-extension relation: 1' \
    "GL17.a a row typed outside the core vocabulary is counted"
if mutate "$F/relationships.md" "$F/rel-no-ext.md" 's/| deploys-to | deployed-from |/| documented-by | documents |/' "GL17.b"; then
    OUT_NOEXT=$(run_detector --table "$F/rel-no-ext.md" --nodes "$F/nodes.tsv" --output "$F/out/led-noext.md" 2>&1)
    assert_output_contains "$OUT_NOEXT" 'Rows typed by a project-extension relation: 0' \
        "GL17.c the same fixture with no extension row reports zero"
    assert_output_contains "$OUT_NOEXT" 'Rows typed by' \
        "GL17.d the counter is printed even at zero — an affirmative statement, not noise"
fi

echo ""
echo "=== GL19: the cluster line ==="
assert_output_contains "$OUT" 'most in one subtree: site/src/ (2)' \
    "GL19.a the cluster line names the two-segment prefix holding the most rows"
# A fixture whose gaps share no prefix must omit the line entirely.
{
    node_row 'int:one/x.sh' 'one/x.sh' 'script' 'named-unit' 'one/x.sh: convention (declared)' 'declared' 'source-artifact'
    node_row 'int:two/y.sh' 'two/y.sh' 'script' 'depended-upon' 'two/y.sh: cited (derived)' 'derived' 'source-artifact'
} > "$F/nodes-spread.tsv"
{
    printf -- '---\nsource: generated\n---\n\n# Relationships\n\n'
    edge_row 'Source Id' 'Source Kind' 'Source Name' 'Target Id' 'Target Kind' \
             'Target Name' 'S2T Relation' 'T2S Relation' 'Provenance' 'Observation'
    printf '|---|---|---|---|---|---|---|---|---|---|\n'
    edge_row 'int:one/x.sh' 'source-artifact' 'one/x.sh' 'kb:kb/a.md' 'document' 'a.md' \
             'mentioned-in' 'mentions' 'declared' 'bare mention'
    edge_row 'int:two/y.sh' 'source-artifact' 'two/y.sh' 'kb:kb/a.md' 'document' 'a.md' \
             'mentioned-in' 'mentions' 'declared' 'bare mention'
} > "$F/rel-spread.md"
OUT_SPREAD=$(run_detector --table "$F/rel-spread.md" --nodes "$F/nodes-spread.tsv" --output "$F/out/led-spread.md" 2>&1)
assert_output_contains "$OUT_SPREAD" 'KB gaps: 2' "GL19.b non-vacuity: the spread fixture really does produce two gaps"
assert_output_not_contains "$OUT_SPREAD" 'most in one subtree' \
    "GL19.c the cluster line is omitted when no group holds two rows"
assert_output_not_contains "$OUT_SPREAD" 'with no relationships at all' \
    "GL19.d the no-relationship slice is omitted when it is zero"

# And the zero-gap shape: every clause that depends on a gap disappears.
if mutate "$F/rel-spread.md" "$F/rel-covered.md" 's/| mentioned-in | mentions |/| documented-by | documents |/' "GL19.e"; then
    OUT_ZERO=$(run_detector --table "$F/rel-covered.md" --nodes "$F/nodes-spread.tsv" --output "$F/out/led-zero.md" 2>&1)
    ZCODE=$?
    assert_exit_eq "$ZCODE" 0 "GL19.f a run that finds no gaps exits 0 too"
    assert_output_contains "$OUT_ZERO" 'KB gaps: 0' "GL19.g the zero-gap count is reported"
    assert_output_not_contains "$OUT_ZERO" 'Route onward' "GL19.h no route onward when there is nothing to route"
    assert_file_contains "$F/rel-covered.md" 'kb_gaps: []' "GL19.i the empty gap set is recorded as an empty list"
    while IFS= read -r l; do
        case "$l" in 'OK '*) pass "${l#OK }" ;; 'BAD '*) fail "${l#BAD }" ;; esac
    done < <(node "$F/ledger-schema.mjs" "$F/out/led-zero.md" allow-empty)
fi

echo ""
echo "=== GL08 / GL11: the two ledgers are separated by FILE, not by row ==="
G_OWN=$(bash "$GRADE_SH" "$F/graph.md" 2>&1)
assert_eq "$G_OWN" "A+" "GL08.a grade.sh over the own-artifact ledger is A+"
assert_file_contains "$LEDGER" '[HIGH]' "GL08.b non-vacuity: the gap ledger really does hold [HIGH] rows"
G_GAPS=$(bash "$GRADE_SH" "$LEDGER" 2>&1)
assert_eq "$G_GAPS" "D" "GL08.c the same grader over the gap ledger would grade it D — so the file separation is what protects the run"
sed 's/| Pending |/| Fixed |/' "$LEDGER" > "$F/all-fixed.md"
G_FIXED=$(bash "$GRADE_SH" "$F/all-fixed.md" 2>&1)
assert_eq "$G_FIXED" "A+" "GL11.a grade.sh over an all-Fixed ledger is A+ — the Status enum is written in the form the grader counts"

echo ""
echo "=== GL10: the Status lifecycle across four cycles ==="
cp "$LEDGER" "$F/cycle1.md"
C1_PENDING=$(count_matches '| Pending |' "$F/cycle1.md")
assert_eq "${C1_PENDING:-x}" "5" "GL10.a cycle 1 opens every row Pending"

# Cycle 2: the mentions-only node becomes covered, and a new gap appears.
cp "$F/nodes.tsv" "$F/nodes-c2.tsv"
node_row 'int:zz/new.sh' 'zz/new.sh' 'script' 'named-unit' "zz/new.sh: convention 'zz/*.sh' (declared)" 'declared' 'source-artifact' >> "$F/nodes-c2.tsv"
mkdir -p "$F/zz"; : > "$F/zz/new.sh"
if mutate "$F/relationships.md" "$F/rel-c2.md" 's/| mentioned-in | mentions | inferred |/| documented-by | documents | inferred |/' "GL10.b"; then
    run_detector --table "$F/rel-c2.md" --nodes "$F/nodes-c2.tsv" \
        --output "$F/out/cycle2.md" --previous "$F/cycle1.md" > /dev/null 2>&1
    assert_exit_eq "$?" 0 "GL10.c cycle 2 runs clean"
    if grep -q '^| 1 | \[MEDIUM\] | Fixed | lib/mentioned.sh ' "$F/out/cycle2.md"; then
        pass "GL10.d a now-covered node moves Pending -> Fixed, keeping its number and severity"
    else
        fail "GL10.d the now-covered node did not move to Fixed"
    fi
    if grep -q '^| 6 | \[LOW\] | Pending | zz/new.sh ' "$F/out/cycle2.md"; then
        pass "GL10.e a new gap is appended as row 6, Pending"
    else
        fail "GL10.e the new gap was not appended with the next number"
    fi

    # Cycle 3: coverage is removed again, and an orchestrator has hand-set one row.
    sed 's/^| 5 | \[LOW\] | Pending |/| 5 | [LOW] | Accepted |/' "$F/out/cycle2.md" > "$F/cycle2-accepted.md"
    if cmp -s "$F/out/cycle2.md" "$F/cycle2-accepted.md"; then
        fail "GL10.f fixture mutation changed nothing — no row was hand-set to Accepted"
    else
        pass "GL10.f fixture differs: row 5 hand-set to Accepted"
        run_detector --table "$F/relationships.md" --nodes "$F/nodes-c2.tsv" \
            --output "$F/out/cycle3.md" --previous "$F/cycle2-accepted.md" > /dev/null 2>&1
        if grep -q '^| 1 | \[MEDIUM\] | Recurred | lib/mentioned.sh ' "$F/out/cycle3.md"; then
            pass "GL10.g a re-broken node moves Fixed -> Recurred"
        else
            fail "GL10.g the re-broken node did not move to Recurred"
        fi
        if grep -q '^| 5 | \[LOW\] | Accepted | tools/orphan.sh ' "$F/out/cycle3.md"; then
            pass "GL10.h a hand-set human-cycle Status is left untouched — the generator is not that actor"
        else
            fail "GL10.h the generator overwrote a hand-set Accepted"
        fi
        # Cycle 4: nothing changes. Every number, severity and description must hold.
        run_detector --table "$F/relationships.md" --nodes "$F/nodes-c2.tsv" \
            --output "$F/out/cycle4.md" --previous "$F/cycle3.md" > /dev/null 2>&1
        C3_NUMS=$(sed -n 's/^| \([0-9]*\) |.*/\1/p' "$F/out/cycle3.md" | paste -sd, -)
        C4_NUMS=$(sed -n 's/^| \([0-9]*\) |.*/\1/p' "$F/out/cycle4.md" | paste -sd, -)
        assert_eq "$C4_NUMS" "$C3_NUMS" "GL10.i cycle 4 renumbers nothing"
        C3_SEV=$(sed -n 's/^| [0-9]* | \(\[[A-Z]*\]\) |.*/\1/p' "$F/out/cycle3.md" | paste -sd, -)
        C4_SEV=$(sed -n 's/^| [0-9]* | \(\[[A-Z]*\]\) |.*/\1/p' "$F/out/cycle4.md" | paste -sd, -)
        assert_eq "$C4_SEV" "$C3_SEV" "GL10.j cycle 4 changes no severity — only Status may move"
        if [[ -n "$C3_NUMS" ]]; then
            pass "GL10.k non-vacuity: the compared row-number sequence is non-empty ($C3_NUMS)"
        else
            fail "GL10.k non-vacuity: no rows were compared, so GL10.i holds trivially"
        fi
    fi
fi

echo ""
echo "=== GL12: the shared module binds from the detector's own directory ==="
if [[ -e "$GRAPH_SCRIPT_DIR/package.json" ]]; then
    fail "GL12.a $GRAPH_SCRIPT_DIR contains a package.json — the .mjs repoint withdrew that marker"
else
    pass "GL12.a the graph script area contains no package.json marker"
fi
BIND=$(cd "$GRAPH_SCRIPT_DIR" && node --input-type=module -e \
    'import { detectArtifactGaps, kbUnbacked, COVERAGE_BEARING, RELATION_CATEGORY } from "./coverage-predicate.mjs";
     const ok = [detectArtifactGaps, kbUnbacked, COVERAGE_BEARING, RELATION_CATEGORY].every(Boolean);
     console.log(ok ? "BOUND" : "MISSING");' 2>&1)
assert_eq "$BIND" "BOUND" "GL12.b all four exports bind from the detector's own directory with no marker file"
BIND2=$(cd "$GRAPH_SCRIPT_DIR" && node --input-type=module -e \
    'const m = await import("../graph/coverage-predicate.mjs");
     console.log("RELATION_CATEGORY" in m ? "BOUND" : "MISSING");' 2>&1)
assert_eq "$BIND2" "BOUND" "GL12.c the ../graph/ form the contract spells resolves to the same module"

echo ""
echo "=== Determinism and idempotence ==="
# Determinism is byte-equality across runs. Idempotence is the stronger property:
# the FIRST run inserts kb_gaps and later runs replace it in place, and all three
# must land on the same bytes.
# Both runs must use the SAME --output, because the routing block echoes the path
# it was given: two different output paths make stdout differ by design, which
# would report a determinism failure that is really a harness mistake.
cp "$F/relationships.md" "$F/idem-a.md"
run_detector --table "$F/idem-a.md" --nodes "$F/nodes.tsv" --output "$F/out/idem.md" > "$F/idem-1.txt" 2>&1
cp "$F/out/idem.md" "$F/out/idem-1.md"; cp "$F/idem-a.md" "$F/idem-after1.md"
run_detector --table "$F/idem-a.md" --nodes "$F/nodes.tsv" --output "$F/out/idem.md" > "$F/idem-2.txt" 2>&1
cp "$F/out/idem.md" "$F/out/idem-2.md"; cp "$F/idem-a.md" "$F/idem-after2.md"
if cmp -s "$F/out/idem-1.md" "$F/out/idem-2.md"; then
    pass "DET01 the ledger is byte-identical across runs"
else
    fail "DET01 the ledger differs between two runs of the same inputs"
fi
if cmp -s "$F/idem-after1.md" "$F/idem-after2.md"; then
    pass "DET02 the kb_gaps rewrite is IDEMPOTENT: replace-in-place lands on the first-insert bytes"
else
    fail "DET02 the kb_gaps rewrite is not idempotent between runs"
fi
if cmp -s "$F/idem-1.txt" "$F/idem-2.txt"; then
    pass "DET03 stdout is byte-identical across runs"
else
    fail "DET03 stdout differs between two runs"
fi
# A fresh table, never yet carrying the key, must reach the same bytes as one that did.
if grep -q '^kb_gaps:' "$F/idem-after1.md"; then
    pass "DET04 non-vacuity: the first run really did insert the kb_gaps key"
else
    fail "DET04 non-vacuity: no kb_gaps key was inserted, so DET02 compared nothing"
fi
if [[ -s "$F/idem-1.txt" ]]; then
    pass "DET05 non-vacuity: stdout is non-empty, so DET03 compared real output"
else
    fail "DET05 non-vacuity: stdout was empty"
fi

echo ""
echo "=== The exit-code contract: 27 abort sites, no ledger written ==="
NEG_LEDGER="$F/out/never.md"
neg() {
    local label="$1"; shift
    rm -f "$NEG_LEDGER"
    local out code
    out=$(node "$DETECTOR" "$@" 2>&1)
    code=$?
    if [[ "$code" -eq 2 && ! -e "$NEG_LEDGER" ]]; then
        pass "$label — exit 2, no ledger"
    elif [[ "$code" -ne 2 ]]; then
        fail "$label — expected exit 2, got $code"
    else
        fail "$label — exit 2 but a ledger was written"
    fi
    NEG_COUNT=$((NEG_COUNT + 1))
    # Every abort must be attributable: prefixed, on stderr, naming the script.
    if grep -qF 'detect-kb-gaps.mjs: ' <<< "$out"; then
        pass "$label — diagnostic is prefixed with the script name"
    else
        fail "$label — no prefixed diagnostic: $out"
    fi
}
NEG_COUNT=0

# --- arguments and usage (9 sites) --------------------------------------------
neg "NEG01 no arguments at all"
neg "NEG02 an unknown flag"                 --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER" --bogus x
neg "NEG03 an inherited object key as a flag" --toString x
neg "NEG04 the same flag twice"              --table "$F/relationships.md" --table "$F/rel-c2.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
neg "NEG05 a flag with no value"             --table
neg "NEG06 a flag whose value is a flag"     --table --nodes
neg "NEG07 write mode with no --output"      --table "$F/relationships.md" --nodes "$F/nodes.tsv"
neg "NEG08 --explain with a write-mode flag" --explain int:x --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
neg "NEG09 --explain with --previous"        --explain int:x --table "$F/relationships.md" --nodes "$F/nodes.tsv" --previous "$F/cycle1.md"
neg "NEG10 --explain with no --nodes"        --explain int:x --table "$F/relationships.md"

# --- the candidate inventory (10 sites) ---------------------------------------
{ head -3 "$F/nodes.tsv"; node_row 'int:site/img/LOGO.PNG' 'site/img/LOGO.PNG' 'image' 'entry-point' 'x (declared)' 'declared' 'image'; } > "$F/n-kind.tsv"
NEG_OUT=$(node "$DETECTOR" --table "$F/relationships.md" --nodes "$F/n-kind.tsv" --output "$NEG_LEDGER" 2>&1 || true)
neg "NEG11 a candidate row whose node_kind is image" --table "$F/relationships.md" --nodes "$F/n-kind.tsv" --output "$NEG_LEDGER"
assert_output_contains "$NEG_OUT" 'node_kind' "GL14.a the message names the offending FIELD"
assert_output_contains "$NEG_OUT" 'int:site/img/LOGO.PNG' "GL14.b the message names the offending ID"
assert_output_contains "$NEG_OUT" 'source-artifact' "GL14.c the message names the kind a candidate must carry"

{ head -3 "$F/nodes.tsv"; node_row 'int:x/web' 'x/web' 'source' 'named-unit' 'x (declared)' 'declared' 'web-page'; } > "$F/n-kind2.tsv"
neg "NEG12 a candidate row whose node_kind is web-page" --table "$F/relationships.md" --nodes "$F/n-kind2.tsv" --output "$NEG_LEDGER"
{ head -3 "$F/nodes.tsv"; node_row 'int:lib/odd.sh' 'lib/odd.sh' 'script' 'interesting' 'x (declared)' 'declared' 'source-artifact'; } > "$F/n-qual.tsv"
NEG_OUT2=$(node "$DETECTOR" --table "$F/relationships.md" --nodes "$F/n-qual.tsv" --output "$NEG_LEDGER" 2>&1 || true)
neg "NEG13 a qualifier outside the four-value enum" --table "$F/relationships.md" --nodes "$F/n-qual.tsv" --output "$NEG_LEDGER"
assert_output_contains "$NEG_OUT2" 'qualifier' "GL04.e the message names the qualifier field rather than defaulting a severity"
{ head -3 "$F/nodes.tsv"; node_row 'int:lib/odd.sh' 'lib/odd.sh' 'script' '' 'x (declared)' 'declared' 'source-artifact'; } > "$F/n-eq.tsv"
neg "NEG14 an empty qualifier"                     --table "$F/relationships.md" --nodes "$F/n-eq.tsv" --output "$NEG_LEDGER"
printf '%s\t%s\t%s\n' 'int:a.sh' 'a.sh' 'script' > "$F/n-short.tsv"
neg "NEG15 a record with three fields, not seven"  --table "$F/relationships.md" --nodes "$F/n-short.tsv" --output "$NEG_LEDGER"
node_row '' 'a.sh' 'script' 'named-unit' 'e' 'declared' 'source-artifact' > "$F/n-noid.tsv"
neg "NEG16 an empty node_id"                       --table "$F/relationships.md" --nodes "$F/n-noid.tsv" --output "$NEG_LEDGER"
node_row 'kb:a.md' 'a.md' 'script' 'named-unit' 'e' 'declared' 'source-artifact' > "$F/n-pre.tsv"
neg "NEG17 an id that is not path-prefixed"        --table "$F/relationships.md" --nodes "$F/n-pre.tsv" --output "$NEG_LEDGER"
node_row 'int:' 'x' 'script' 'named-unit' 'e' 'declared' 'source-artifact' > "$F/n-bare.tsv"
neg "NEG18 an id that is the bare prefix"          --table "$F/relationships.md" --nodes "$F/n-bare.tsv" --output "$NEG_LEDGER"
node_row 'int:a.sh' '' 'script' 'named-unit' 'e' 'declared' 'source-artifact' > "$F/n-noname.tsv"
neg "NEG19 an empty display name"                  --table "$F/relationships.md" --nodes "$F/n-noname.tsv" --output "$NEG_LEDGER"
node_row 'int:a.sh' 'a.sh' 'script' 'named-unit' '' 'declared' 'source-artifact' > "$F/n-noev.tsv"
neg "NEG20 an empty evidence anchor"               --table "$F/relationships.md" --nodes "$F/n-noev.tsv" --output "$NEG_LEDGER"
{ head -2 "$F/nodes.tsv"; head -1 "$F/nodes.tsv"; } > "$F/n-dup.tsv"
neg "NEG21 a duplicated node_id"                   --table "$F/relationships.md" --nodes "$F/n-dup.tsv" --output "$NEG_LEDGER"
neg "NEG22 a --nodes path that does not exist"     --table "$F/relationships.md" --nodes "$F/absent.tsv" --output "$NEG_LEDGER"

# --- the relationship table (8 sites) ----------------------------------------
neg "NEG23 a --table path that does not exist"     --table "$F/absent.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
grep -v '^# Relationships' "$F/relationships.md" > "$F/t-noh1.md"
neg "NEG24 no '# Relationships' heading"           --table "$F/t-noh1.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
if mutate "$F/relationships.md" "$F/t-nocol.md" 's/| S2T Relation | T2S Relation |/| S2T Relation | Renamed |/' "NEG25.pre"; then
    neg "NEG25 a header missing a consumed column" --table "$F/t-nocol.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
fi
awk 'BEGIN{seen=0} /^\|---\|---\|---\|---\|---\|---\|---\|---\|---\|---\|$/ && seen==0 {seen=1; next} {print}' \
    "$F/relationships.md" > "$F/t-nodelim.md"
if cmp -s "$F/relationships.md" "$F/t-nodelim.md"; then
    fail "NEG26.pre fixture mutation changed nothing — the delimiter row was not removed"
else
    pass "NEG26.pre fixture differs: the delimiter row is gone"
    neg "NEG26 no delimiter row under the header"  --table "$F/t-nodelim.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
fi
if mutate "$F/relationships.md" "$F/t-short.md" 's#^| int:site/src/a\.ts | source-artifact | site/src/a\.ts |.*#| int:site/src/a.ts | source-artifact | truncated |#' "NEG27.pre"; then
    neg "NEG27 a data row with the wrong cell count" --table "$F/t-short.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
fi
if mutate "$F/relationships.md" "$F/t-empty.md" 's#| int:lib/mentioned.sh | source-artifact | lib/mentioned.sh | kb:kb/arch.md |#| int:lib/mentioned.sh | source-artifact | lib/mentioned.sh |  |#' "NEG28.pre"; then
    neg "NEG28 a consumed cell left empty"         --table "$F/t-empty.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
fi
sed -n '/^<!-- AUTO-GENERATED/,$p' "$F/relationships.md" > "$F/t-nofm.md"
if grep -q '^---$' "$F/t-nofm.md"; then
    fail "NEG29.pre fixture still carries a frontmatter block"
else
    pass "NEG29.pre fixture differs: the frontmatter block is gone"
    neg "NEG29 a table file with no frontmatter"   --table "$F/t-nofm.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"
fi
printf -- '---\nx: 1\n---\n\n# Relationships\n\nnot a table\n' > "$F/t-notable.md"
neg "NEG30 no table after the heading"             --table "$F/t-notable.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER"

# --- the previous ledger (3 sites) -------------------------------------------
printf '| # | Severity | Status | Doc | Line | Description | Evidence |\n|---|---|---|---|---|---|---|\n| 1 | [HIGH] | Pending | a.sh | five cells |\n' > "$F/p-short.md"
neg "NEG31 a previous ledger row with five cells"  --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER" --previous "$F/p-short.md"
if mutate "$F/cycle1.md" "$F/p-badnum.md" 's/^| 1 |/| one |/' "NEG32.pre"; then
    neg "NEG32 a previous ledger row number that is not an integer" --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER" --previous "$F/p-badnum.md"
fi
mkdir -p "$F/adir"
neg "NEG33 --previous naming a directory"          --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER" --previous "$F/adir"

# --- the two write failures --------------------------------------------------
printf 'a file, not a directory\n' > "$F/blocker"
OUT_W=$(node "$DETECTOR" --table "$F/relationships.md" --nodes "$F/nodes.tsv" --output "$F/blocker/led.md" 2>&1)
assert_exit_eq "$?" 2 "NEG34 an --output whose parent is an existing file"
assert_output_contains "$OUT_W" 'cannot write the ledger' "NEG34.a the diagnostic names the failing write"
NEG_COUNT=$((NEG_COUNT + 1))

# A read-only table exercises the kb_gaps write failure. chmod is a no-op on some
# Windows filesystems, so this is verified before it is asserted, and skipped if the
# attribute did not take -- a check that cannot run must never pass.
cp "$F/relationships.md" "$F/ro-table.md"
chmod 444 "$F/ro-table.md" 2>/dev/null || true
if [[ -w "$F/ro-table.md" ]]; then
    skip "NEG35 a read-only --table (the kb_gaps write failure) — chmod did not take on this filesystem"
else
    rm -f "$NEG_LEDGER"
    OUT_RO=$(node "$DETECTOR" --table "$F/ro-table.md" --nodes "$F/nodes.tsv" --output "$NEG_LEDGER" 2>&1)
    RO_CODE=$?
    assert_exit_eq "$RO_CODE" 2 "NEG35 a read-only --table aborts"
    assert_output_contains "$OUT_RO" 'cannot write kb_gaps' "NEG35.a the diagnostic names the failing frontmatter write"
    if [[ -e "$NEG_LEDGER" ]]; then
        fail "NEG35.b a ledger was written even though the durable carrier could not be"
    else
        pass "NEG35.b no ledger is written when the durable carrier cannot be"
    fi
    NEG_COUNT=$((NEG_COUNT + 1))
fi
chmod 644 "$F/ro-table.md" 2>/dev/null || true

# The pin: as many negative cases as the detector has abort sites.
if [[ "$NEG_COUNT" -ge "$EXPECTED_ABORT_SITES" ]]; then
    pass "NEG00 $NEG_COUNT negative cases cover the detector's $EXPECTED_ABORT_SITES abort sites"
else
    fail "NEG00 only $NEG_COUNT negative cases for $EXPECTED_ABORT_SITES abort sites — an abort is untested"
fi

echo ""
echo "=== GL20: the run's writes are exactly the two declared outputs ==="
W="$F/writescope"
mkdir -p "$W/out"
cp "$F/relationships.md" "$W/t.md"
cp "$F/nodes.tsv" "$W/n.tsv"
find "$W" -type f | sort > "$F/w-before.txt"
run_detector --table "$W/t.md" --nodes "$W/n.tsv" --output "$W/out/led.md" > /dev/null 2>&1
assert_exit_eq "$?" 0 "GL20.e the scoped run succeeds"
find "$W" -type f | sort > "$F/w-after.txt"
NEW_PATHS=$(comm -13 "$F/w-before.txt" "$F/w-after.txt" | paste -sd, -)
assert_eq "$NEW_PATHS" "$W/out/led.md" "GL20.f the only path created is the declared --output"
if [[ -s "$F/w-before.txt" ]]; then
    pass "GL20.g non-vacuity: the before-listing was non-empty"
else
    fail "GL20.g non-vacuity: the before-listing was empty"
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
