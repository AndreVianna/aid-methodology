#!/usr/bin/env bash
# test-review-rubrics.sh -- structural integrity of the review rubric catalog.
#
# The catalog's whole value rests on one property: a rule may exist only if a document already
# declares it. So the load-bearing assertion here is RR07 -- every Criterion resolves to a file
# that exists and a heading that is greppable in it. Without that, the catalog quietly becomes the
# third source of truth it was built to prevent.
#
# Usage: bash tests/canonical/test-review-rubrics.sh [--verbose]
# Exit:  0 all pass, 1 any fail.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${SCRIPT_DIR}/../.."
source "${SCRIPT_DIR}/../lib/assert.sh"

CAT="${REPO}/canonical/aid/templates/review-rubrics"
KB="${REPO}/.aid/knowledge"
TPL="${REPO}/canonical/aid/templates"

echo "== test-review-rubrics.sh =="

[[ -d "$CAT" ]] || { echo "FATAL: catalog not found at $CAT" >&2; exit 2; }

# ---------------------------------------------------------------------------
# RR01 -- the catalog exists with an INDEX and at least the six family files.
# ---------------------------------------------------------------------------
assert_eq "$([[ -f "$CAT/INDEX.md" ]] && echo yes)" "yes" "RR01 INDEX.md exists"

for fam in definition executable interface presentation narrative process; do
  assert_eq "$([[ -f "$CAT/${fam}.md" ]] && echo yes)" "yes" "RR02 family file ${fam}.md exists"
done

# ---------------------------------------------------------------------------
# RR03 -- the universal tier lives in INDEX.md and nowhere else. A family file
# that restates the defect taxonomy has forked it.
# ---------------------------------------------------------------------------
tax_hosts=0
for f in "$CAT"/*.md; do
  [[ "$(basename "$f")" == "INDEX.md" ]] && continue
  if grep -qE '^\| *1 *\| *\*\*Contract violation\*\*' "$f"; then
    tax_hosts=$((tax_hosts + 1))
    echo "    (taxonomy restated in $(basename "$f"))"
  fi
done
assert_eq "$tax_hosts" "0" "RR03 the defect taxonomy is declared only in INDEX.md"

# ---------------------------------------------------------------------------
# RR04 -- severity is never redefined in the catalog; it is pointed at.
# ---------------------------------------------------------------------------
sev_defs=$(grep -rlE '^\| *`?\[CRITICAL\]`? *\|' "$CAT" 2>/dev/null | wc -l)
assert_eq "$sev_defs" "0" "RR04 no catalog file redefines the severity bands"

ptr_missing=0
for f in "$CAT"/*.md; do
  grep -q 'grading-rubric.md#severity-scale' "$f" || { ptr_missing=$((ptr_missing+1)); echo "    (no severity pointer in $(basename "$f"))"; }
done
assert_eq "$ptr_missing" "0" "RR05 every catalog file points at the canonical severity scale"

# ---------------------------------------------------------------------------
# RR06 -- rule IDs, modality, mode and severity anchors are all well formed.
# A rule row is any table row whose first cell matches the ID format.
# ---------------------------------------------------------------------------
# PERFORMANCE NOTE. An earlier version ran several `echo | awk | grep` pipelines PER ROW. At ~60
# rows that is ~400 process spawns, which costs ~220s on Windows/Git Bash -- close enough to
# run-all.sh's 300s per-suite timeout to be a flake risk. Everything below is now TWO bulk passes
# (one awk over the catalog, one grep over the cited docs) plus in-memory bash loops.
#
# Pass 1: parse every rule row once into a TSV of
#   file, id, cellcount, modality, mode, severity, criterion
ROWS="$(awk -F'|' '
  FILENAME != last { last = FILENAME }
  /^\|/ {
    id = $2; gsub(/[ `*]/, "", id)
    if (id !~ /^[A-Z]{2,12}-[0-9]{2}$/) next
    mod = $5;  gsub(/[ `*]/, "", mod)
    mode = $6; gsub(/[ `*]/, "", mode)
    sev = $8;  sub(/^ +/, "", sev); sub(/ +$/, "", sev)
    crit = $4; chk = $3; ev = $7
    n = split(FILENAME, pp, "/")
    printf "%s\t%s\t%d\t%s\t%s\t%s\t%s\t%s\t%s\n", pp[n], id, NF, mod, mode, sev, crit, chk, ev
  }
' "$CAT"/*.md)"

bad_id=0; bad_mod=0; bad_mode=0; bad_sev=0; rule_count=0
while IFS=$'\t' read -r f id ncell mod mode sev crit; do
  [[ -z "${id:-}" ]] && continue
  rule_count=$((rule_count + 1))
  [[ "$ncell" -ge 8 ]] || { bad_id=$((bad_id+1)); echo "    ($id in $f has $((ncell-2)) cells, want 7)"; }
  case "$mod"  in MUST|SHOULD|COULD)     ;; *) bad_mod=$((bad_mod+1));  echo "    ($id modality='$mod')" ;; esac
  case "$mode" in mechanical|judgment)   ;; *) bad_mode=$((bad_mode+1)); echo "    ($id mode='$mode')" ;; esac
  # legal: a bracketed token first (optionally with an escape clause), or the literal `Step 2`
  case "$sev" in
    '`[CRITICAL]'*|'[CRITICAL]'*|'`[HIGH]'*|'[HIGH]'*|'`[MEDIUM]'*|'[MEDIUM]'*) ;;
    '`[LOW]'*|'[LOW]'*|'`[MINOR]'*|'[MINOR]'*|'`Step 2'*|'Step 2'*) ;;
    *) bad_sev=$((bad_sev+1)); echo "    ($id severity='${sev:0:40}')" ;;
  esac
done <<< "$ROWS"

assert_eq "$bad_id"   "0" "RR06 every rule row has seven cells"

# A seven-cell row with an empty Check, Criterion or Evidence satisfies the shape and carries no
# content. The gate wants three ANCHORS present, not three columns present -- so assert the cells
# are populated, and that a `mechanical` row's Evidence actually looks like something runnable.
bad_empty=0; bad_cmd=0
while IFS=$'\t' read -r f id ncell mod mode sev crit chk ev; do
  [[ -z "${id:-}" ]] && continue
  for pair in "Check:$chk" "Criterion:$crit" "Evidence:$ev"; do
    nm="${pair%%:*}"; val="${pair#*:}"
    val="${val//[[:space:]]/}"
    [[ -n "$val" ]] || { bad_empty=$((bad_empty+1)); echo "    ($id has an empty $nm cell)"; }
  done
  if [[ "$mode" == "mechanical" ]]; then
    case "$ev" in
      *'`'*|*bash*|*grep*|*find*|*awk*|*sed*|*diff*|*Run\ *|*run\ *|*Compare*|*Validate*|*Check*|*Load*) ;;
      *) bad_cmd=$((bad_cmd+1)); echo "    ($id is mechanical but Evidence names no command: '${ev:0:50}')" ;;
    esac
  fi
done <<< "$ROWS"
assert_eq "$bad_empty" "0" "RR22 no rule row has an empty Check, Criterion or Evidence cell"
assert_eq "$bad_cmd"   "0" "RR23 every mechanical row's Evidence names a runnable check"
assert_eq "$bad_mod"  "0" "RR07 every Modality is MUST / SHOULD / COULD"
assert_eq "$bad_mode" "0" "RR08 every Mode is mechanical or judgment"
assert_eq "$bad_sev"  "0" "RR09 every Severity anchor is a bracketed token or 'Step 2'"

if [[ "$rule_count" -gt 0 ]]; then
  pass "RR10 the catalog contains rule rows ($rule_count found)"
else
  fail "RR10 no rule rows found -- the parser or the catalog is broken"
fi

# ---------------------------------------------------------------------------
# RR11 / RR12 -- THE LOAD-BEARING PAIR. Every Criterion resolves: the cited
# document exists, and where a section is named, that heading is greppable in
# it. No Criterion, no row -- so an unresolvable Criterion is a rule with no
# declaring authority, which is the catalog becoming the third source of truth
# it was built to prevent.
#
# PARSING NOTE, learned by negative control: a Criterion cell is written
# `doc.md § Section Name` -- ONE backtick pair wrapping BOTH the document and
# the section. An earlier version of this check required a closing backtick
# immediately after `.md`, so it matched nothing and both assertions passed on
# deliberately broken citations. RR16/RR17 below now guard that regression
# directly: the checker must fail on a bad citation, and it is tested for it.
# ---------------------------------------------------------------------------
unresolved=0; checked=0; bad_anchor=0; anchors=0

# Pass 2a: split every Criterion into `doc<TAB>section` claims, in ONE awk pass.
#   The document is ONLY what precedes the first `§`. Section names may themselves end in `.md`
#   (e.g. `artifact-schemas.md § Feature SPEC.md`), so scanning a whole span for a document-shaped
#   token misreads the section as a second document -- exactly what the first working version did.
#   A claim with no section emits an empty section field.
CLAIMS="$(printf '%s\n' "$ROWS" | awk -F'\t' '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
  {
    id = $2; crit = $7
    n = split(crit, spans, "`")
    for (i = 2; i <= n; i += 2) {                       # odd-indexed = inside backticks
      span = spans[i]
      si = index(span, "§")
      head = (si ? substr(span, 1, si - 1) : span)
      if (match(head, /[A-Za-z0-9_\/.-]+\.(md|yml|sh)/) == 0) continue
      doc = substr(head, RSTART, RLENGTH)
      if (si == 0) { print id "\t" doc "\t"; continue }
      rest = substr(span, si)
      m = split(rest, secs, "§")
      for (j = 2; j <= m; j++) {
        s = trim(secs[j])
        if (s != "") print id "\t" doc "\t" s
      }
    }
  }
')"

# Pass 2b: one grep for every `## ` heading in the candidate documents, so heading membership is an
# in-memory lookup rather than a grep per anchor.
declare -A DOCPATH=() HEADINGS=()
while IFS=$'\t' read -r _id doc _sec; do
  [[ -z "${doc:-}" || -n "${DOCPATH[$doc]:-}" ]] && continue
  for base in "$KB" "$TPL" "$CAT" "$REPO"; do
    [[ -f "$base/$doc" ]] && { DOCPATH[$doc]="$base/$doc"; break; }
  done
  [[ -z "${DOCPATH[$doc]:-}" ]] && DOCPATH[$doc]="__MISSING__"
done <<< "$CLAIMS"

for doc in "${!DOCPATH[@]}"; do
  p="${DOCPATH[$doc]}"
  [[ "$p" == "__MISSING__" ]] && continue
  while IFS= read -r h; do
    HEADINGS["$doc|$h"]=1
  done < <(sed -n 's/^## //p' "$p")
done

while IFS=$'\t' read -r id doc sec; do
  [[ -z "${doc:-}" ]] && continue
  checked=$((checked + 1))
  if [[ "${DOCPATH[$doc]}" == "__MISSING__" ]]; then
    [[ "$doc" == "INDEX.md" ]] && continue      # catalog-relative self-reference
    unresolved=$((unresolved + 1))
    echo "    ($id cites '$doc' -- no such file)"
    continue
  fi
  [[ -z "${sec:-}" ]] && continue
  anchors=$((anchors + 1))
  [[ -n "${HEADINGS["$doc|$sec"]:-}" ]] || {
    bad_anchor=$((bad_anchor + 1))
    echo "    ($id cites '$doc § $sec' -- heading not found)"
  }
done <<< "$CLAIMS"

assert_eq "$unresolved" "0" "RR11 every cited Criterion document exists ($checked citations checked)"
assert_eq "$bad_anchor"  "0" "RR12 every cited section heading exists ($anchors anchors checked)"

# Non-vacuity: these two assertions are worthless unless they actually inspected something.
if [[ "$checked" -ge 20 ]]; then
  pass "RR16 the Criterion checker inspected $checked citations (not vacuous)"
else
  fail "RR16 the Criterion checker only inspected $checked citations -- parser is broken"
fi
if [[ "$anchors" -ge 20 ]]; then
  pass "RR17 the anchor checker inspected $anchors section references (not vacuous)"
else
  fail "RR17 the anchor checker only inspected $anchors section references -- parser is broken"
fi

# ---------------------------------------------------------------------------
# RR13 -- rule IDs are unique across the catalog.
# ---------------------------------------------------------------------------
dupes=$(grep -rhoE '^\| *`?[A-Z]{2,12}-[0-9]{2}`? *\|' "$CAT" \
        | tr -d '|` ' | sort | uniq -d | tr '\n' ' ')
assert_eq "${dupes:-none}" "none" "RR13 rule IDs are unique across the catalog"

# ---------------------------------------------------------------------------
# RR14 -- the routing table resolves each class to exactly one rule set, AND the
# resolution order is stated. The table deliberately does not list every class
# (family fallback covers the rest), so without an explicit ordered procedure a
# class like RESEARCH or API would route to nothing at all.
# ---------------------------------------------------------------------------
idx="$(cat "$CAT/INDEX.md")"
assert_output_contains "$idx" "Routing table" "RR14 INDEX.md carries a routing table"
assert_output_contains "$idx" "How to resolve an artifact to a rule set" \
  "RR18 INDEX.md states the artifact-to-rule-set resolution procedure"
assert_output_contains "$idx" "Family fallback" \
  "RR19 the procedure names family fallback for unlisted classes"

# Every rule set named in the routing table must exist on disk. A route to a missing file is worse
# than no route: it reads as covered and resolves to nothing.
#
# EXTRACTION NOTE, learned by negative control (the third vacuous assertion in this suite): routing
# rows end with a trailing `|`, so with -F'|' the LAST field is empty and never matches `\.md`. An
# earlier guard on $NF therefore skipped every row and this assertion inspected nothing. Scope is
# also restricted to the routing-table section -- other tables in INDEX.md cite KB documents
# (`artifact-schemas.md`, `test-landscape.md`) that are correctly absent from the catalog.
routing_sets="$(awk '
  /^## Routing table/     { inrt = 1; next }
  inrt && /^## /          { inrt = 0 }
  inrt && /^\|/           {
    n = split($0, c, "`")
    for (i = 2; i <= n; i += 2) if (c[i] ~ /^[a-z-]+\.md$/) last = c[i]
    if (last != "") { print last; last = "" }
  }
' "$CAT/INDEX.md" | sort -u)"

missing_rs=0; routed=0
while IFS= read -r rs; do
  [[ -z "$rs" ]] && continue
  routed=$((routed + 1))
  [[ -f "$CAT/$rs" ]] || { missing_rs=$((missing_rs+1)); echo "    (routing table names '$rs' -- not in catalog)"; }
done <<< "$routing_sets"

assert_eq "$missing_rs" "0" "RR20 every rule set named in the routing table exists ($routed routes checked)"
if [[ "$routed" -ge 4 ]]; then
  pass "RR21 the routing extractor found $routed rule sets (not vacuous)"
else
  fail "RR21 the routing extractor found only $routed rule sets -- the extractor is broken"
fi

# ---------------------------------------------------------------------------
# RR15 -- the SUMMARY class carries content-truth rows, not only family rows.
# Required so the adversarial summary pass has a rule set at all.
# ---------------------------------------------------------------------------
if [[ -f "$CAT/summary.md" ]]; then
  assert_output_contains "$(cat "$CAT/summary.md")" "SUMMARY-04" "RR15 summary.md carries a contradiction rule"
else
  fail "RR15 summary.md missing"
fi

echo
test_summary
exit $?
