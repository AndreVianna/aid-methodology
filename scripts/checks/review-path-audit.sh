#!/usr/bin/env bash
# review-path-audit.sh -- four-layer audit proving AID has exactly one review path.
#
# PURPOSE
#   Proves the review stack is singular -- one skill (aid-review), one agent
#   (aid-reviewer) -- and that every review-family reference in canonical/
#   resolves to a real skill. Designed to catch a rival review system that slips
#   past the *review* glob by choosing a name outside it (e.g. aid-screener).
#
# LAYERS
#   L1 SINGLETON   canonical/skills/*review*/ and canonical/agents/*review*/ each == 1
#   L2 LEXICON     no skill or agent directory name matches the review-family
#                  lexicon (review, reviewer, screener, critique, audit, inspect,
#                  verif, grade, rubric) outside the sanctioned pair
#                  {aid-review, aid-reviewer}
#   L3 SLASH-REFS  every /aid-<name> slash-ref in canonical/**/*.md that is
#                  review-family resolves under canonical/skills/; non-review
#                  dangling refs are NOTEs, not failures
#   L4 AGENT-REFS  aid-reviewer resolves under canonical/agents/, and every agent
#                  directory is named somewhere in canonical/**/*.md
#
# USAGE
#   bash scripts/checks/review-path-audit.sh
#   Run from the repository root. No arguments.
#
# EXIT CODES
#   0  RESULT PASS -- all four layers pass, no vacuity violation
#   1  RESULT FAIL -- at least one layer reports a violation
#
# RE-DERIVATION THIS SCRIPT REMOVES
#   Deciding which /aid-<name> refs are dangling requires a guarded extraction.
#   The naive form is wrong: it produces false positives from a path prefix
#   (canonical/agents/aid-architect/ read as /aid-architect) and a template
#   placeholder ({/aid-command} in bespoke-components.md).
#
#   NAIVE form -- reports 6 dangling, every one of them a false positive:
#     aid-architect aid-clerk aid-command aid-create- aid-design- aid-reviewer
#
#     grep -rhoE '/aid-[a-z0-9-]+' canonical --include=*.md \
#       | sed 's|^/||' | sort -u \
#       | while read -r s; do [ -d "canonical/skills/$s" ] || echo "$s"; done
#
#   GUARDED form (the form this script uses) -- reports 0 dangling. It reported
#   one, `aid-graph`, until that leftover reference was removed from
#   design-lifecycle.md; the two forms differing by six is still the point.
#
#     grep -rhoE '(^|[^A-Za-z0-9/._{-])/aid-[a-z0-9]+(-[a-z0-9]+)*' canonical \
#       --include=*.md \
#       | grep -oE '/aid-[a-z0-9-]+' | sed 's|^/||' | sort -u \
#       | while read -r s; do [ -d "canonical/skills/$s" ] || echo "$s"; done
#
#   6 of 7 in the naive form are false positives. Re-running both commands
#   reproduces these figures. Embedding them here removes the need to re-derive
#   the guard at every future audit.

set -uo pipefail
export LC_ALL=C

# Review-family lexicon -- substring match against directory / ref names.
readonly LEXICON='review|screener|critique|audit|inspect|verif|grade|rubric'

# Sanctioned pair -- exempt from L2 lexicon check.
readonly SANCTIONED_SKILL='aid-review'
readonly SANCTIONED_AGENT='aid-reviewer'

FAIL=0
NOTES=""

# ── L1 SINGLETON ─────────────────────────────────────────────────────────────
# Exactly one *review* directory in each family.
skill_review_dirs=$(ls -d canonical/skills/*review*/ 2>/dev/null | wc -l | awk '{print $1+0}')
agent_review_dirs=$(ls -d canonical/agents/*review*/ 2>/dev/null | wc -l | awk '{print $1+0}')

printf '%-15sreview-skill-dirs=%s (expect 1)  reviewer-agent-dirs=%s (expect 1)\n' \
    'L1 SINGLETON' "$skill_review_dirs" "$agent_review_dirs"

if [[ "$skill_review_dirs" -ne 1 || "$agent_review_dirs" -ne 1 ]]; then
    FAIL=1
fi

# ── L2 LEXICON ────────────────────────────────────────────────────────────────
# No skill or agent directory name matches the review-family lexicon outside
# the sanctioned pair.  A rival named aid-screener passes L1 (glob returns 1
# agent) but is caught here.
unsanctioned=0
unsanctioned_list=""

while IFS= read -r name; do
    case "$name" in
        "$SANCTIONED_SKILL"|"$SANCTIONED_AGENT") continue ;;
    esac
    if printf '%s\n' "$name" | grep -qiE "$LEXICON"; then
        unsanctioned=$(( unsanctioned + 1 ))
        unsanctioned_list="${unsanctioned_list}${unsanctioned_list:+ }$name"
    fi
done < <(
    { ls -d canonical/skills/*/ 2>/dev/null; ls -d canonical/agents/*/ 2>/dev/null; } \
        | sed 's|/$||; s|.*/||' | sort -u
)

printf '%-15sreview-family names outside {aid-review, aid-reviewer}=%s (expect 0)\n' \
    'L2 LEXICON' "$unsanctioned"

if [[ $unsanctioned -gt 0 ]]; then
    for n in $unsanctioned_list; do
        printf '   VIOLATION unsanctioned %s\n' "$n"
    done
    FAIL=1
fi

# ── L3 SLASH-REFS ─────────────────────────────────────────────────────────────
# Extract every distinct /aid-<name> slash-ref from canonical/**/*.md using the
# guarded form, then classify each as review-family or not.
#
# The guard -- (^|[^A-Za-z0-9/._{-]) before the leading slash -- excludes:
#   * path prefixes: canonical/agents/aid-architect/ would match the naive form
#   * template placeholders: {/aid-command} in bespoke-components.md
#
# Vacuity guards: distinct=0 or review-family=0 is a VIOLATION rather than a
# pass (the check would be measuring nothing).
all_refs=$(grep -rhoE '(^|[^A-Za-z0-9/._{-])/aid-[a-z0-9]+(-[a-z0-9]+)*' \
    canonical --include=*.md 2>/dev/null \
    | grep -oE '/aid-[a-z0-9-]+' | sed 's|^/||' | sort -u || true)

distinct=$(printf '%s\n' "$all_refs" | awk 'NF{c++} END{print c+0}')

if [[ "$distinct" -eq 0 ]]; then
    printf '%-15sdistinct=0  VIOLATION: zero refs extracted (empty corpus or guard error)\n' \
        'L3 SLASH-REFS'
    FAIL=1
else
    review_count=$(printf '%s\n' "$all_refs" \
        | awk -v lex="$LEXICON" 'tolower($0) ~ lex {c++} END{print c+0}')

    if [[ "$review_count" -eq 0 ]]; then
        printf '%-15sdistinct=%s  review-family=0  VIOLATION: no review-family refs found\n' \
            'L3 SLASH-REFS' "$distinct"
        FAIL=1
    else
        dangling_review=0
        dangling_other=0
        dangling_other_list=""
        dangling_review_list=""

        while IFS= read -r s; do
            [[ -n "$s" ]] || continue
            if printf '%s\n' "$s" | grep -qiE "$LEXICON"; then
                if [[ ! -d "canonical/skills/$s" ]]; then
                    dangling_review=$(( dangling_review + 1 ))
                    dangling_review_list="${dangling_review_list}${dangling_review_list:+ }$s"
                fi
            else
                if [[ ! -d "canonical/skills/$s" ]]; then
                    dangling_other=$(( dangling_other + 1 ))
                    dangling_other_list="${dangling_other_list}${dangling_other_list:+ }$s"
                fi
            fi
        done <<< "$all_refs"

        printf '%-15sdistinct=%s  review-family=%s  dangling(review-family)=%s (expect 0)  dangling(other)=%s\n' \
            'L3 SLASH-REFS' "$distinct" "$review_count" "$dangling_review" "$dangling_other"

        if [[ $dangling_review -gt 0 ]]; then
            for n in $dangling_review_list; do
                printf 'VIOLATION /aid-%s is review-family and names no skill under canonical/skills/\n' "$n"
            done
            FAIL=1
        fi

        for n in $dangling_other_list; do
            NOTES="${NOTES}NOTE /${n} names no skill under canonical/skills/ (not review-family)\n"
        done
    fi
fi

# ── L4 AGENT-REFS ─────────────────────────────────────────────────────────────
# For each agent directory under canonical/agents/, confirm its name appears
# somewhere in canonical/**/*.md.  Count those that do as named-and-resolving.
# Hard failure: aid-reviewer directory is absent.
named_count=0

while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if grep -qrh "$name" canonical --include=*.md 2>/dev/null; then
        named_count=$(( named_count + 1 ))
    fi
done < <(ls -d canonical/agents/*/ 2>/dev/null | sed 's|/$||; s|.*/||' | sort -u)

reviewer_present='no'
[[ -d 'canonical/agents/aid-reviewer' ]] && reviewer_present='yes'

printf '%-15snamed-and-resolving=%s  reviewer-agent-present=%s\n' \
    'L4 AGENT-REFS' "$named_count" "$reviewer_present"

if [[ "$reviewer_present" = 'no' ]]; then
    printf 'VIOLATION aid-reviewer agent directory is absent\n'
    FAIL=1
fi

# ── RESULT ────────────────────────────────────────────────────────────────────
[[ -n "$NOTES" ]] && printf '%b' "$NOTES"
if [[ "$FAIL" -eq 0 ]]; then
    printf 'RESULT PASS\n'
    exit 0
else
    printf 'RESULT FAIL\n'
    exit 1
fi
