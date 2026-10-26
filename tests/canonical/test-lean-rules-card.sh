#!/usr/bin/env bash
# test-lean-rules-card.sh -- the always-loaded context stays small: the rules file is short and
# points at the project card, and the card (template and this repo's own) holds what it promises.
#
#   LR01  canonical/aid/rules.md is at most 60 lines
#   LR02  its summary block is valid "- " bullets, the first sends the reader to PROJECT.md
#   LR03  every rules line that names INDEX.md limits it to finding a document (no unconditional INDEX read)
#   LR04  the project-card template carries the six sections the card promises
#   LR05  this repo's card .aid/knowledge/PROJECT.md is at most 60 lines, has the six sections and at most 10 rules
#   LR06  every repo path named in code spans on the card exists
#   LR07  the card is routed by the KB index, and the type registry knows it (a kb-card row and PC- criteria)
#   LR08  the path check is falsifiable (it reports a planted missing path)
#   LR09  the skill list stays small: no description over 300 characters, at most 12 over 110,
#         all together at most 16,000 characters (about 4k tokens), and no skill hidden from the model
#
# Usage: bash test-lean-rules-card.sh [--verbose]

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
RULES="${REPO_ROOT}/canonical/aid/rules.md"
TEMPLATE="${REPO_ROOT}/canonical/aid/templates/project-card.md"
CARD="${REPO_ROOT}/.aid/knowledge/PROJECT.md"
INDEX="${REPO_ROOT}/.aid/knowledge/INDEX.md"
REGISTRY="${REPO_ROOT}/.aid/knowledge/authoring-conventions.md"

SECTIONS=("What it is" "Stack" "Commands" "Where things live" "Rules that never bend" "Detail")

# LR01
assert_file_exists "$RULES" "LR01 rules source exists"
rules_lines="$(wc -l < "$RULES" | tr -d ' ')"
if [[ "$rules_lines" -le 60 ]]; then
    pass "LR01 rules.md is ${rules_lines} lines (limit 60)"
else
    fail "LR01 rules.md is ${rules_lines} lines, over the limit of 60"
fi

# LR02: every non-continuation line of the summary block starts with "- "; continuation lines are indented.
summary="$(sed -n '/^<!-- AID:SUMMARY:BEGIN -->$/,/^<!-- AID:SUMMARY:END -->$/p' "$RULES" | sed '1d;$d')"
bad_summary="$(printf '%s\n' "$summary" | grep -vE '^(- |  )' || true)"
assert_eq "$bad_summary" "" "LR02 summary block holds only bullets and indented continuations"
assert_eq "$(printf '%s\n' "$summary" | head -n 1 | grep -c 'knowledge/PROJECT.md')" "1" "LR02 the first summary bullet names the project card"

# LR03
index_lines="$(grep -c 'knowledge/INDEX\.md' "$RULES")"
unbounded="$(grep 'knowledge/INDEX\.md' "$RULES" | grep -v 'only to find' || true)"
assert_eq "$unbounded" "" "LR03 every rules line naming INDEX.md opens it only to find a document (${index_lines} line(s))"

# LR04, LR05: sections in order, rule count, size.
check_sections() { # <file> <label>
    local f="$1" label="$2" got want
    got="$(grep -E '^## ' "$f" | sed 's/^## //')"
    want="$(printf '%s\n' "${SECTIONS[@]}")"
    assert_eq "$got" "$want" "${label} has the six sections in order"
}
assert_file_exists "$TEMPLATE" "LR04 project-card template exists"
check_sections "$TEMPLATE" "LR04 template"

assert_file_exists "$CARD" "LR05 project card exists"
check_sections "$CARD" "LR05 card"
card_lines="$(wc -l < "$CARD" | tr -d ' ')"
if [[ "$card_lines" -le 60 ]]; then
    pass "LR05 card is ${card_lines} lines (limit 60)"
else
    fail "LR05 card is ${card_lines} lines, over the limit of 60"
fi
rule_count="$(sed -n '/^## Rules that never bend$/,/^## Detail$/p' "$CARD" | grep -cE '^[0-9]+\. ')"
if [[ "$rule_count" -ge 1 && "$rule_count" -le 10 ]]; then
    pass "LR05 card lists ${rule_count} rules (1 to 10)"
else
    fail "LR05 card lists ${rule_count} rules, expected 1 to 10"
fi

# LR06: every repo path in a code span exists. Spans with placeholders, globs or flags are not paths.
missing_paths() { # <file>: print each named path that is absent from the repo
    local f="$1" span tok
    while IFS= read -r span; do
        for tok in $span; do
            tok="${tok%[,;:.]}"
            case "$tok" in
                -*|*'<'*|*'>'*|*'*'*|*'$'*|*'{'*|*://*) continue ;;
                */*) [[ -e "${REPO_ROOT}/${tok}" ]] || printf '%s\n' "$tok" ;;
            esac
        done
    done < <(grep -oE '`[^`]+`' "$f" | tr -d '`')
}
assert_eq "$(missing_paths "$CARD")" "" "LR06 every path named in a code span on the card exists"

# LR07
assert_file_contains "$INDEX" "[PROJECT.md](../knowledge/PROJECT.md)" "LR07 INDEX.md routes the card"
assert_file_contains "$REGISTRY" '| `kb-card` |' "LR07 the type registry has a kb-card row"
assert_file_contains "$REGISTRY" '| PC-01 | `kb-card` |' "LR07 the registry carries the card criteria"

# LR08: falsify the path check.
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
printf 'Run `bash no/such/script.sh` and read `tests/run-all.sh`.\n' > "$scratch/card.md"
assert_eq "$(missing_paths "$scratch/card.md")" "no/such/script.sh" "LR08 the path check reports a planted missing path and accepts a real one"

# LR09: description budget over canonical/skills/*/SKILL.md (description plus when_to_use).
budget="$(python3 - "${REPO_ROOT}/canonical/skills" <<'PY'
import pathlib, re, sys
sizes, hidden = {}, []
for f in sorted(pathlib.Path(sys.argv[1]).glob("*/SKILL.md")):
    fm = f.read_text(encoding="utf-8").split("\n---", 1)[0].splitlines()[1:]
    total, i = 0, 0
    while i < len(fm):
        m = re.match(r"(description|when_to_use|disable-model-invocation):\s*(.*)$", fm[i])
        i += 1
        if not m:
            continue
        key, val = m.groups()
        if key == "disable-model-invocation":
            hidden += [f.parent.name] if val.strip().lower() == "true" else []
            continue
        parts = [] if val.strip() in (">", "|", ">-", "|-") else [val.strip().strip('"')]
        while i < len(fm) and fm[i].startswith("  "):
            parts.append(fm[i].strip()); i += 1
        total += len(" ".join(parts))
    sizes[f.parent.name] = total
long = sorted(n for n, s in sizes.items() if s > 110)
print(len(sizes), max(sizes.values()), len(long), sum(sizes.values()), ",".join(hidden) or "-")
PY
)"
read -r n_skills max_len n_long total hidden <<< "$budget"
if [[ "$n_skills" -gt 0 && "$max_len" -le 300 ]]; then pass "LR09 longest description is ${max_len} characters (limit 300, ${n_skills} skills)"; else fail "LR09 longest description is ${max_len} characters, over 300 (${n_skills} skills)"; fi
if [[ "$n_long" -le 12 ]]; then pass "LR09 ${n_long} descriptions are over 110 characters (limit 12)"; else fail "LR09 ${n_long} descriptions are over 110 characters, limit 12"; fi
if [[ "$total" -le 16000 ]]; then pass "LR09 descriptions total ${total} characters (limit 16000)"; else fail "LR09 descriptions total ${total} characters, over 16000"; fi
assert_eq "$hidden" "-" "LR09 no skill is hidden from the model (disable-model-invocation)"

test_summary
