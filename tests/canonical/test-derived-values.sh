#!/usr/bin/env bash
# test-derived-values.sh -- the repo-wide derived-value guard, and proof that it can fail.
#
# The guard (check-derived-values.mjs) sweeps the tree for stated values that disagree with the
# source they describe. This suite runs it, and then breaks things to show each mechanism bites.
#
# WHY THE CONTROLS MATTER MORE THAN THE GREEN RUN
#
# The defect this guard exists to catch -- a value written in two places, one updated -- is the
# same defect a guard can have about itself. Every mechanism below was, at some point during its
# construction, silently inert:
#
#   the joined-line pass    reported every finding twice (span test compared a de-emphasised index
#                           against a raw length), then reported none
#   the minimum_grade rule  matched the ARTICLE in "is a valid grade" and reported the letter A
#   the exempt marker       was only looked for on the line AFTER a claim, never the line above
#   the superseded rule     contained a literal 0x08 where a `\b` was meant, so it never matched
#
# None of those was visible in a passing run. Each was found by breaking something and watching
# whether the guard noticed. So: every assertion here that says "the guard is clean" is paired
# with one that plants a defect and requires it to be caught.
#
# Usage: bash tests/canonical/test-derived-values.sh
# Exit:  0 all pass / 1 any fail

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GUARD="$ROOT/tests/canonical/check-derived-values.mjs"
REGISTRY="$ROOT/tests/canonical/derived-values.mjs"

pass=0; fail=0
ok() { pass=$((pass+1)); printf '  ok   %s -- %s\n' "$1" "$2"; }
no() { fail=$((fail+1)); printf '  FAIL %s -- %s\n' "$1" "$2"; }

if ! command -v node >/dev/null 2>&1; then
    echo "node is required for the derived-value guard"; exit 1
fi

echo "== the guard runs clean on the tree as it stands =="

OUT="$(node "$GUARD" 2>&1)"; RC=$?
if [[ "$RC" -eq 0 ]]; then
    ok DV01 "the repo has no stated value that disagrees with its source"
else
    no DV01 "guard exit $RC: $(printf '%s' "$OUT" | grep -A6 'WRONG VALUES' | head -7 | tr '\n' ' ')"
fi

# Non-vacuity. A sweep that stops reaching the corpus reports "all agree" and is indistinguishable
# from a clean repo -- so the count it examined is itself an assertion.
CHECKED="$(printf '%s' "$OUT" | sed -n 's/^Claims checked: *\([0-9]*\).*/\1/p' | head -1)"
if [[ "${CHECKED:-0}" -ge 100 ]]; then
    ok DV02 "the sweep examined ${CHECKED} claims (not vacuous)"
else
    no DV02 "the sweep examined only ${CHECKED:-0} claims -- it is not reaching the corpus"
fi

# The registry must actually derive things. A derivation that returns null is skipped silently by
# the engine, so an empty registry would also produce a clean run.
# Written to a real .mjs rather than passed to `node -e`: an ES import needs module input type,
# and the -e form silently produced "0 0" -- which is the same output an empty registry gives, so
# the assertion would have failed for a reason that had nothing to do with the registry.
# An MSYS path handed to node is read as a Windows path: `/c/Projects/...` resolved to
# `C:\c\Projects\...` and the import failed, which the probe reported as "0 0" -- indistinguishable
# from an empty registry. Convert to a native path where cygpath exists.
native() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s' "$1"; fi; }
PROBE="$(mktemp -d)/probe.mjs"
cat > "$PROBE" <<PROBE_EOF
import { buildRegistry } from 'file:///$(native "$REGISTRY")';
const r = buildRegistry(String.raw\`$(native "$ROOT")\`);
const scalars = r.filter((e) => e.kind === 'scalar' && e.derive() != null).length;
const relations = r.filter((e) => e.kind === 'relation' && e.table.size > 0).length;
console.log(scalars + ' ' + relations);
PROBE_EOF
DERIVED="$(node "$PROBE" 2>&1 | tail -1)"
read -r N_SCALAR N_REL <<<"${DERIVED:-0 0}"
if [[ "${N_SCALAR:-0}" -ge 3 && "${N_REL:-0}" -ge 2 ]]; then
    ok DV03 "the registry resolves ${N_SCALAR} scalar derivations and ${N_REL} populated relations"
else
    no DV03 "registry under-populated: ${N_SCALAR:-0} scalars, ${N_REL:-0} relations -- a null derivation is skipped silently"
fi

echo
echo "== and it can fail: each mechanism, broken on a scratch copy =="

# Every mutation runs against a COPY of the tree. The guard resolves REPO_ROOT from its own
# location, so copying the guard beside a mutated corpus is what points it at the mutation.
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

plant() {   # plant NAME FILE_REL SED_EXPR -- returns the guard's exit code and output
    local name="$1" rel="$2" expr="$3"
    local dir="$SCRATCH/$name"
    rm -rf "$dir"; mkdir -p "$dir/tests/canonical"
    # Only the trees the guard sweeps, plus what the derivations read.
    cp -r "$ROOT/canonical" "$dir/" 2>/dev/null
    mkdir -p "$dir/.aid"; cp -r "$ROOT/.aid/knowledge" "$dir/.aid/" 2>/dev/null
    cp "$ROOT/.aid/settings.yml" "$dir/.aid/" 2>/dev/null
    cp "$ROOT/README.md" "$dir/" 2>/dev/null
    cp "$GUARD" "$REGISTRY" "$dir/tests/canonical/"
    [[ -n "$expr" ]] && sed -i "$expr" "$dir/$rel"
    node "$dir/tests/canonical/check-derived-values.mjs" 2>&1
}

# DV04 -- a scalar claim gone stale. The agent count is the family that was wrong in five files.
out="$(plant scalar 'README.md' 's/10 specialized agents/9 specialized agents/')"
if printf '%s' "$out" | grep -q 'WRONG VALUES'; then
    ok DV04 "a stale scalar claim is caught (agent count 10 -> 9 in README)"
else
    no DV04 "planting a wrong agent count did NOT fail the guard"
fi

# DV05 -- a relation gone stale. This is the family SEV01 could not see: a severity stated for a
# rule in PROSE rather than in a table row.
out="$(plant relation 'canonical/aid/templates/kb-authoring/review-rubric.md' \
      's/`\[LOW\]` (escaping to `\[MEDIUM\]` beyond one doc) `\[CAL-COVERAGE\]`/`[CRITICAL]` `[CAL-COVERAGE]`/')"
if printf '%s' "$out" | grep -qE 'WRONG VALUES|stated \[CRITICAL\]'; then
    ok DV05 "a severity that disagrees with the rule it cites is caught"
else
    no DV05 "planting a wrong severity beside a rule ID did NOT fail the guard"
fi

# DV06 -- the CLAIM MUST BE SEEN THROUGH MARKDOWN EMPHASIS. `**9** agents` is the form that
# defeated every plain-adjacency pattern in the guard this one is modelled on.
out="$(plant emphasis 'README.md' 's/10 specialized agents/**9** specialized agents/')"
if printf '%s' "$out" | grep -q 'WRONG VALUES'; then
    ok DV06 "a stale claim wrapped in markdown emphasis is still caught"
else
    no DV06 "an emphasised wrong value slipped through -- de-emphasis is not working"
fi

# DV07 -- the exempt marker must WORK, or every legitimate example becomes noise and the guard
# gets switched off. Plant a wrong value AND its marker; expect clean.
out="$(plant marker 'README.md' 's/10 specialized agents/9 specialized agents <!-- derived-value-exempt: test -->/')"
if printf '%s' "$out" | grep -q 'WRONG VALUES'; then
    no DV07 "an explicitly exempted line was still reported -- the escape hatch does not work"
else
    ok DV07 "an explicitly exempted stale value is not reported"
fi

# DV08 -- ...and the marker must not be a blanket off-switch. It exempts the line it is on, not
# the file. Plant the marker on one line and a wrong value on a DIFFERENT one.
out="$(plant marker-scope 'README.md' \
      's/^# AID/# AID <!-- derived-value-exempt: test -->/; s/10 specialized agents/9 specialized agents/')"
if printf '%s' "$out" | grep -q 'WRONG VALUES'; then
    ok DV08 "the marker exempts its own line only, not the whole file"
else
    no DV08 "a marker elsewhere in the file suppressed an unrelated wrong value"
fi

# DV09 -- the non-vacuity floor must fire when the sweep stops reaching the corpus. Emptying the
# scanned trees is the shape of a moved directory or a broken walk.
dir="$SCRATCH/floor"; rm -rf "$dir"; mkdir -p "$dir/tests/canonical" "$dir/.aid"
cp "$GUARD" "$REGISTRY" "$dir/tests/canonical/"
cp "$ROOT/.aid/settings.yml" "$dir/.aid/" 2>/dev/null
node "$dir/tests/canonical/check-derived-values.mjs" >/dev/null 2>&1
if [[ "$?" -eq 2 ]]; then
    ok DV09 "an empty corpus exits 2 (floor), not 0 -- a scan that reaches nothing is not a pass"
else
    no DV09 "an empty corpus did not trip the non-vacuity floor"
fi

# DV10 -- no control byte in the guard or its registry. A `\b` written through a shell heredoc
# becomes 0x08, and `regex.source` prints it INVISIBLY: the pattern looks right in every
# diagnostic while never matching. That is exactly how the superseded-row rule shipped inert.
cb_bad=()
for f in "$GUARD" "$REGISTRY"; do
    LC_ALL=C grep -qP '[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]' "$f" 2>/dev/null && cb_bad+=("$(basename "$f")")
done
if [[ "${#cb_bad[@]}" -eq 0 ]]; then
    ok DV10 "no stray control byte in the guard or its registry"
else
    no DV10 "control byte(s) in: ${cb_bad[*]} -- an escape was written through a layer that ate it"
fi

# DV11 -- control: the detector above must be able to SEE a planted control byte, or DV10 passes
# for the wrong reason.
probe="$SCRATCH/probe.mjs"; printf 'const re = /a\bb/;\n' > "$probe"
if LC_ALL=C grep -qP '[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]' "$probe" 2>/dev/null; then
    ok DV11 "the control-byte detector DOES see a planted 0x08 (control)"
else
    no DV11 "the control-byte detector cannot see a planted 0x08 -- DV10 proves nothing"
fi

echo
echo "=== Summary ==="
echo "  Tests passed: $pass"
echo "  Tests failed: $fail"
[[ "$fail" -eq 0 ]] && { echo; echo "All tests passed."; exit 0; }
echo; echo "Some tests failed."; exit 1
