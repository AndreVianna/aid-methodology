#!/usr/bin/env bash
# lint-settings.sh -- validate .aid/settings.yml, the file that sets every gate's quality bar.
#
# WHY THIS GATE EXISTS
# `minimum_grade` decides when EVERY review-state skill is allowed to stop. Nothing validated it. A
# typo (`minimum_grade: A1`) does not fail loudly -- `read-setting.sh` returns the string, the caller
# compares it against a computed grade, and the comparison quietly never succeeds or quietly always
# does. The file with the most leverage over quality was the one file with no checks on it.
#
# WHY THE ENUMS ARE DERIVED, NOT RESTATED
# There were already five places describing grades. A sixth copy here would be the defect this work
# exists to remove, and it would be the worst copy: a validator whose idea of a valid grade has drifted
# from the grader's rejects exactly the settings the grader would honour. So:
#
#   * the grade alphabet comes from `grading-rubric.md`'s `## Grade Ordering` line
#   * `type` and `source_control` enums come from the settings TEMPLATE's own trailing comments
#
# If a source cannot be read or parsed, this script FAILS -- it never falls back to a built-in list,
# because a silent fallback is how the restatement would creep back in.
#
# USAGE
#   lint-settings.sh [--file .aid/settings.yml] [--template PATH] [--rubric PATH] [--quiet]
#
# EXIT CODES (linter alphabet: 0 clean, 1 violations, 2 usage/unresolvable source)
#   0  the settings file is valid
#   1  at least one violation
#   2  usage error, or an enum source could not be read/parsed
set -uo pipefail

SCRIPT_NAME="lint-settings.sh"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILE=".aid/settings.yml"
TEMPLATE="${HERE}/../../templates/settings.yml"
RUBRIC="${HERE}/../../templates/grading-rubric.md"
QUIET=0

die()  { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit 2; }
say()  { [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*"; }
usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --file)     [[ $# -lt 2 ]] && die "--file requires a path";     FILE="$2"; shift 2 ;;
        --template) [[ $# -lt 2 ]] && die "--template requires a path"; TEMPLATE="$2"; shift 2 ;;
        --rubric)   [[ $# -lt 2 ]] && die "--rubric requires a path";   RUBRIC="$2"; shift 2 ;;
        --quiet)    QUIET=1; shift ;;
        -h|--help)  usage; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
done

[[ -f "$FILE" ]]     || die "settings file not found: $FILE"
[[ -f "$TEMPLATE" ]] || die "settings template not found (needed to derive enums): $TEMPLATE"
[[ -f "$RUBRIC" ]]   || die "grading rubric not found (needed to derive the grade alphabet): $RUBRIC"

# ---------------------------------------------------------------------------
# Derive the grade alphabet from the rubric's ordering line, which is the one
# place that states every grade AND their order on a single line.
# ---------------------------------------------------------------------------
GRADES="$(awk '
  /^## Grade Ordering/ { want = 1; next }
  want && NF {
    if ($0 ~ />/) { print; exit }
  }
' "$RUBRIC" | tr -d ' ' | tr '>' ' ')"

[[ -n "${GRADES// /}" ]] || die "could not derive the grade alphabet from ${RUBRIC} (## Grade Ordering)"

# Sanity-check the derivation itself: a parse that silently yields one token would make every grade
# except that token invalid, so refuse to run on an implausible alphabet.
grade_count=$(wc -w <<<"$GRADES")
[[ "$grade_count" -ge 4 ]] || die "derived only ${grade_count} grade(s) from ${RUBRIC} -- parse is wrong, refusing to validate against it"

grade_valid() {
    local g="$1" k
    for k in $GRADES; do [[ "$g" == "$k" ]] && return 0; done
    return 1
}

# ---------------------------------------------------------------------------
# Derive scalar enums from the template's trailing comments, e.g.
#   type: brownfield        # brownfield | greenfield
# ---------------------------------------------------------------------------
enum_for() {
    # Print the space-separated alternatives documented for KEY in the template, or nothing.
    awk -v key="$1" '
      $0 ~ "^" key ":" {
        i = index($0, "#")
        if (i == 0) next
        c = substr($0, i + 1)
        if (c !~ /\|/) next            # only a pipe-separated list is an enum
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        n = split(c, parts, "|")
        for (j = 1; j <= n; j++) {
          v = parts[j]
          gsub(/^[ \t]+|[ \t]+$/, "", v)
          if (v ~ /^[A-Za-z][A-Za-z0-9_-]*$/) printf "%s ", v
        }
        exit
      }
    ' "$TEMPLATE"
}

# Read every top-level scalar ONCE into an associative array. Spawning an awk per key looks harmless
# until the caller is a test suite running this script twenty times: on Windows/Git Bash the process
# spawns, not the parsing, are the cost.
declare -A SCALARS=()
while IFS=$'\t' read -r k v; do
    [[ -n "$k" ]] && SCALARS["$k"]="$v"
done < <(awk '
  /^[A-Za-z_][A-Za-z0-9_]*:/ {
    key = $0; sub(/:.*/, "", key)
    val = $0; sub("^" key ":[ \t]*", "", val)
    sub(/[ \t]*#.*$/, "", val)
    gsub(/^[ \t]+|[ \t]+$/, "", val)
    gsub(/^["'"'"']|["'"'"']$/, "", val)
    if (!(key in seen)) { seen[key] = 1; printf "%s\t%s\n", key, val }
  }
' "$FILE")

scalar() { printf '%s' "${SCALARS[$1]:-}"; }

violations=0
bad() { violations=$((violations + 1)); say "  [FAIL] $*"; }
good() { say "  [ ok ] $*"; }

say "=== ${SCRIPT_NAME}: ${FILE} ==="
say "derived grade alphabet (${grade_count}): ${GRADES}"

# --- S1: minimum_grade -------------------------------------------------------
mg="$(scalar minimum_grade)"
if [[ -z "$mg" ]]; then
    bad "S1 minimum_grade is absent -- every gate's bar is undefined"
elif ! grade_valid "$mg"; then
    bad "S1 minimum_grade '${mg}' is not a grade. Valid: ${GRADES}"
else
    good "S1 minimum_grade '${mg}' is a valid grade"
fi

# --- S2/S3: enum scalars, with the enum taken from the template --------------
for key in type source_control; do
    allowed="$(enum_for "$key")"
    val="$(scalar "$key")"
    if [[ -z "${allowed// /}" ]]; then
        bad "S2 cannot derive the '${key}' enum from ${TEMPLATE} -- add a '# a | b' comment there"
        continue
    fi
    if [[ -z "$val" ]]; then
        bad "S2 ${key} is absent (expected one of: ${allowed})"
        continue
    fi
    hit=0
    for a in $allowed; do [[ "$val" == "$a" ]] && hit=1; done
    if [[ "$hit" -eq 1 ]]; then good "S2 ${key} '${val}' is in the documented enum"
    else bad "S2 ${key} '${val}' is not one of: ${allowed}"; fi
done

# --- S4: heartbeat_interval is a positive integer ----------------------------
hb="$(scalar heartbeat_interval)"
if [[ -z "$hb" ]]; then
    bad "S4 heartbeat_interval is absent"
elif [[ ! "$hb" =~ ^[0-9]+$ ]] || [[ "$hb" -lt 1 ]]; then
    bad "S4 heartbeat_interval '${hb}' is not a positive integer (minutes)"
else
    good "S4 heartbeat_interval ${hb} is a positive integer"
fi

# --- S5: name and description are present and not still placeholders ---------
for key in name description; do
    val="$(scalar "$key")"
    if [[ -z "$val" ]]; then
        bad "S5 ${key} is absent"
    elif [[ "$val" == "<"*">" ]]; then
        bad "S5 ${key} is still the template placeholder '${val}' -- /aid-config never completed"
    else
        good "S5 ${key} is set"
    fi
done

# --- S6: knowledge.doc_set rows are name|producer|requirement ----------------
# The rows are pipe-delimited, so a stray pipe shifts every field after it -- the same positional
# fragility the rule catalog hit. Validate shape rather than trusting it.
#
# ONE awk pass, not one per row. Three subprocesses per row over 19 rows, times every invocation in the
# test suite, dominated the runtime badly enough to threaten run-all.sh's per-suite budget on Windows --
# the same problem, and the same fix, as the rule-catalog integrity check.
#
# A line inside the block that is NOT a list item is reported rather than ignored: a half-edited row
# (`  project-structure.md|owner|required`, the leading `- ` lost) would otherwise vanish from the doc set
# silently, which is worse than a malformed row because nothing anywhere complains.
ds_report="$(awk '
  function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
  /^[[:space:]]*doc_set:[[:space:]]*$/ { in_ds = 1; next }
  in_ds && /^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*:/ { in_ds = 0 }
  in_ds {
    if ($0 ~ /^[[:space:]]*$/) next
    if ($0 !~ /^[[:space:]]*-[[:space:]]/) {
      printf "STRAY|%s\n", trim($0)
      next
    }
    row = $0
    sub(/^[[:space:]]*-[[:space:]]*/, "", row)
    seen++
    n = split(row, f, "|")
    if (n != 3) { printf "FIELDS|%d|%s\n", n, row; next }
    doc = trim(f[1]); req = trim(f[3])
    if (req != "required" && req != "optional") printf "REQ|%s|%s\n", doc, req
    if (doc !~ /\.md$/)                        printf "DOC|%s\n", doc
  }
  END { printf "SEEN|%d\n", seen + 0 }
' "$FILE")"

ds_seen=$(sed -n 's/^SEEN|//p' <<<"$ds_report")
ds_bad=0
while IFS='|' read -r kind a b; do
    case "$kind" in
        STRAY)  bad "S6 doc_set contains a line that is not a list item -- the row would be silently dropped: ${a}"; ds_bad=1 ;;
        FIELDS) bad "S6 doc_set row has ${a} field(s), expected 3 (name|producer|requirement): ${b}"; ds_bad=1 ;;
        REQ)    bad "S6 doc_set row '${a}' has requirement '${b}', expected required|optional"; ds_bad=1 ;;
        DOC)    bad "S6 doc_set row names '${a}', which is not a .md document"; ds_bad=1 ;;
    esac
done < <(grep -v '^SEEN|' <<<"$ds_report")

[[ "${ds_seen:-0}" -eq 0 && "$ds_bad" -eq 0 ]] && good "S6 no doc_set rows to validate (not yet written by aid-discover)"
[[ "${ds_seen:-0}" -gt 0 && "$ds_bad" -eq 0 ]] && good "S6 all ${ds_seen} doc_set rows are well-formed"

# --- S7: term_exclusions have no blank or duplicate entries ------------------
te_file="$(mktemp)"; trap 'rm -f "$te_file"' EXIT
awk '
  /^[[:space:]]*term_exclusions:/ { in_te = 1; next }
  in_te && /^[[:space:]]*-[[:space:]]*/ { sub(/^[[:space:]]*-[[:space:]]*/, ""); print; next }
  in_te && /^[[:space:]]*[A-Za-z_]+:/ { in_te = 0 }
' "$FILE" > "$te_file"
te_seen=$(grep -c . "$te_file" || true)
dupes="$(sort "$te_file" | uniq -d | head -5)"
if [[ -n "$dupes" ]]; then
    bad "S7 term_exclusions contains duplicates: $(tr '\n' ',' <<<"$dupes")"
else
    good "S7 term_exclusions has ${te_seen} entries, no duplicates"
fi

# --- S8: every top-level key in the live file is one the template knows ------
# Catches a typo'd key, which is otherwise invisible: read-setting.sh would fall through to its
# --default and the misspelled setting would appear to be honoured while doing nothing.
tmpl_keys="$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$TEMPLATE" | sort -u)"
live_keys="$(awk '/^[A-Za-z_][A-Za-z0-9_]*:/ { sub(/:.*/, ""); print }' "$FILE" | sort -u)"
# format_version is written by the migrator, not seeded in the template, so it is added to the known set
# BEFORE sorting -- comm requires both inputs sorted, and appending after the sort silently breaks it.
known_keys="$(printf '%s\nformat_version\n' "$tmpl_keys" | grep -v '^$' | sort -u)"
unknown="$(comm -23 <(printf '%s\n' "$live_keys" | grep -v '^$' | sort -u) <(printf '%s\n' "$known_keys") || true)"
if [[ -n "$unknown" ]]; then
    bad "S8 unknown top-level key(s), not in the template: $(tr '\n' ' ' <<<"$unknown")"
else
    good "S8 every top-level key is known to the template"
fi

# --- S9: no gate-relevant key escapes validation -----------------------------
# Derived, not listed: any template key whose comment mentions grade/quality/gate must be checked by
# this script. If someone adds such a key later, this fires instead of silently leaving it unvalidated.
VALIDATED="minimum_grade type source_control heartbeat_interval name description knowledge"
while IFS= read -r k; do
    [[ -z "$k" ]] && continue
    case " $VALIDATED " in *" $k "*) continue ;; esac
    bad "S9 template key '${k}' looks gate-relevant but this lint does not validate it"
done < <(awk '
  /^[A-Za-z_][A-Za-z0-9_]*:/ {
    line = $0
    key = $0; sub(/:.*/, "", key)
    if (tolower(line) ~ /grade|quality|gate|bar|threshold/) print key
  }
' "$TEMPLATE")

say
if [[ "$violations" -eq 0 ]]; then
    say "OK: ${SCRIPT_NAME}: ${FILE} is valid (bar = ${mg})"
    exit 0
fi
echo "FAIL: ${SCRIPT_NAME}: ${violations} violation(s) in ${FILE}" >&2
exit 1
