#!/usr/bin/env bash
# test-kb-scanner-scope.sh -- the KB scanners must NOT walk AID tool-install
# ("dogfood") trees at the repo root (.claude/ .cursor/ .codex/). Guards work-010:
# on a project that has AID installed, those trees are the AID install itself,
# never target-project source, and the KB makes no claims about them (same rule
# that already prunes .aid). Walking them polluted candidate-concepts.md /
# project-index.md and broke byte-reproducibility across AID updates.
#
#   S01  project-index.md lists NO path under .claude/ .cursor/ .codex/
#   S02  project-index.md STILL lists the target source file (no over-prune)
#   S03  candidate-concepts.md has NO term/path from the tool trees
#        (incl. a deeply nested .cursor/deep/nested/ file -- prune is depth-agnostic)
#   S04  candidate-concepts.md STILL surfaces a target-project coined term (no over-prune)
#   S05  the two scanners' SKIP_DIRS arrays are byte-identical (lockstep)
#
# Auto-discovered by tests/run-all.sh (glob tests/canonical/test-*.sh).
#
# Usage:
#   bash tests/canonical/test-kb-scanner-scope.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
BPI="${REPO}/canonical/aid/scripts/kb/build-project-index.sh"
HARVEST="${REPO}/canonical/aid/scripts/kb/harvest-coined-terms.sh"

source "${SCRIPT_DIR}/../lib/assert.sh"

echo "== test-kb-scanner-scope.sh =="

for f in "$BPI" "$HARVEST"; do
  [[ -f "$f" ]] || { echo "FATAL: scanner not found at $f" >&2; exit 2; }
done

# ---------------------------------------------------------------------------
# Build a target project that ALSO contains repo-root AID tool-install trees.
# The tool trees carry unique tokens so any leakage is unmistakable.
# ---------------------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FX="$TMP/proj"
mkdir -p "$FX/src" "$FX/.claude/aid/scripts/config" "$FX/.cursor/deep/nested" "$FX/.codex"

# -- target-project source (real content, cross-source coined terms) --
cat > "$FX/src/app.ts" <<'EOF'
// The WidgetEngine drives the FrobnicationPipeline.
export class WidgetEngine { runFrobnicationPipeline() { return 42; } }
EOF
cat > "$FX/README.md" <<'EOF'
# Demo project
The WidgetEngine and its FrobnicationPipeline are the core abstractions.
EOF

# -- AID tool-install trees (must be pruned); each plants a unique token --
cat > "$FX/.claude/aid/scripts/config/read-setting.sh" <<'EOF'
#!/usr/bin/env bash
echo "ClaudeInstallToken resolves things"
ClaudeHelperFn() { echo hi; }
EOF
echo 'function CursorInstallToken(){ return 1; }'    > "$FX/.cursor/thing.js"
echo 'q=CursorNestedInstallToken'                    > "$FX/.cursor/deep/nested/y.sh"
echo 'def CodexInstallToken(): pass'                 > "$FX/.codex/z.py"

IDX="$TMP/project-index.md"
CAND="$TMP/candidate-concepts.md"
bash "$BPI"     --root "$FX" --output "$IDX"  >/dev/null 2>&1
bash "$HARVEST" --root "$FX" --output "$CAND" >/dev/null 2>&1

TOOL_PATH_RE='\.claude/|\.cursor/|\.codex/'
TOOL_TOKEN_RE='ClaudeInstallToken|ClaudeHelperFn|CursorInstallToken|CursorNestedInstallToken|CodexInstallToken'

# --- S01: no tool-tree paths in the project index -------------------------
if [[ -f "$IDX" ]] && grep -qE "$TOOL_PATH_RE" "$IDX"; then
  fail "S01 project-index.md must not list any .claude/.cursor/.codex path"
  [[ "$VERBOSE" -eq 1 ]] && grep -nE "$TOOL_PATH_RE" "$IDX"
else
  pass "S01 project-index.md lists no AID tool-install-tree paths"
fi

# --- S02: target source still indexed (no over-prune) ---------------------
assert_file_contains "$IDX" "src/app.ts" "S02 project-index.md still lists the target source file (no over-prune)"

# --- S03: no tool-derived terms/paths in the candidate universe -----------
if [[ -f "$CAND" ]] && grep -qE "${TOOL_PATH_RE}|${TOOL_TOKEN_RE}" "$CAND"; then
  fail "S03 candidate-concepts.md must not contain any tool-install-tree term or path"
  [[ "$VERBOSE" -eq 1 ]] && grep -nE "${TOOL_PATH_RE}|${TOOL_TOKEN_RE}" "$CAND"
else
  pass "S03 candidate-concepts.md has no tool-tree terms/paths (incl. nested .cursor/deep/nested)"
fi

# --- S04: target coined term still surfaces (no over-prune) ---------------
if [[ -f "$CAND" ]] && grep -qiE 'widget|frobnication' "$CAND"; then
  pass "S04 candidate-concepts.md still surfaces a target-project coined term (no over-prune)"
else
  fail "S04 candidate-concepts.md dropped the target-project coined terms (over-prune)"
fi

# --- S05: SKIP_DIRS lockstep between the two scanners ---------------------
extract_skip() { awk '/^SKIP_DIRS=\(/{p=1} p{print} /^\)/{if(p)exit}' "$1"; }
if diff <(extract_skip "$BPI") <(extract_skip "$HARVEST") >/dev/null 2>&1; then
  pass "S05 SKIP_DIRS arrays are byte-identical across both scanners (lockstep)"
else
  fail "S05 SKIP_DIRS arrays diverge between build-project-index.sh and harvest-coined-terms.sh"
  [[ "$VERBOSE" -eq 1 ]] && diff <(extract_skip "$BPI") <(extract_skip "$HARVEST")
fi

test_summary
