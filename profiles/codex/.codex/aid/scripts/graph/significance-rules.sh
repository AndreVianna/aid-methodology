#!/usr/bin/env bash
# significance-rules.sh - sourceable rule library for graph source enumeration.
#
# Purpose:
#   The single home for every decision rule feature-004 applies while enumerating
#   project source: the FR-22 exclusion classes (D4), the kind partition (D2a),
#   the ordered artifact_class rule list (D2), the carrier -> qualifier map with
#   its precedence (D3a), the byte-exact evidence templates and the
#   token-formation rule (D3b), the evidence candidate-set enumerator and its
#   LC_ALL=C-least selector (D3a, two functions on purpose), and the three-state
#   ignore-list probe (D4a). scan-source.sh sources this file and calls these
#   functions; the test suite calls the same functions, so the scanner and its
#   tests exercise ONE implementation of each rule rather than two readings of it.
#
#   No top-level side effects when sourced: this file defines functions and
#   read-only constants only. `set -eu` would mutate the sourcing shell, so it is
#   applied only on direct execution (see the tail of this file) - the same
#   posture lib/aid-install-core.sh takes.
#
# Usage:
#   source "$(dirname "$0")/significance-rules.sh"
#   bash significance-rules.sh --help        # print this header
#
# Two call shapes, and why:
#   Every rule has a printing function (the readable, test-friendly shape) and,
#   where the scanner calls it thousands of times, a `*_into` twin that assigns a
#   documented global instead of printing. Both shapes run the SAME body - the
#   printing function is a wrapper over the `_into` one. The twin exists because a
#   command substitution costs ~100 ms under Windows Git Bash / MSYS on this
#   project's own hardware (measured), so `x=$(fn ...)` in a per-node loop is a
#   minutes-long run; a plain call costs ~40 us. Batched processes, never per-item
#   forks, is the same rule build-project-index.sh records for its own walk.
#
# Provides (printing shape -> the global its `_into` twin sets):
#   -- token formation and evidence rendering (D3b) --
#   sig_token <raw>                                  -> SIG_TOKEN
#   sig_evidence_phrase <tid>                        -> SIG_PHRASE (with SIG_SHAPE)
#   sig_evidence_shape <tid>                         -> SIG_SHAPE  (with SIG_PHRASE)
#   sig_render_evidence <tid> <subject> <token> <carrier> [<anchor>]
#                                                    -> SIG_EVIDENCE
#   sig_render_image_evidence <path> <ext>           -> SIG_EVIDENCE
#   sig_render_external_evidence <registry> <key>    -> SIG_EVIDENCE
#   -- the qualifier map and its precedence (D3a) --
#   sig_template_clause <tid>                        -> SIG_CLAUSE
#   sig_template_provenance <tid>                    -> SIG_PROVENANCE
#   sig_clause_qualifier <clause>                    -> SIG_QUALIFIER
#   sig_clause_rank <clause>                         -> SIG_RANK  (Q1>Q2>Q4>Q3, total)
#   sig_clause_level <clause>                        -> SIG_LEVEL (P1|P2|P3)
#   sig_stronger_clause <a> <b>                      -> SIG_CLAUSE
#   -- evidence selection (D3a), two functions on purpose --
#   sig_evidence_candidates <clause> <provenance>    -> SIG_CANDIDATES (array)
#        printing shape reads matches on stdin as  tid\tsubject\ttoken\tcarrier\tanchor
#        `_into` shape reads them from a named array (arg 3)
#   sig_evidence_select                              -> SIG_EVIDENCE
#        printing shape reads candidates on stdin; `_into` shape reads SIG_CANDIDATES
#   -- kind partition and the schema seam (D2a) --
#   sig_lower <text>                                 -> SIG_LOWER
#   sig_path_extension <path>                        -> SIG_EXT (folded; empty if none)
#   sig_set_image_extensions <ext ...>               (installs the loaded list)
#   sig_image_extensions                             -> the installed list
#   sig_is_image <path>                              exit 0 when the extension is a member
#   sig_load_schema <schema-file> [<loader>]         load image_extensions via
#                                                    feature-003's rel_load_schema
#   sig_validate_kinds <kind ...>                    the three emitted kinds are in the enum
#   -- artifact_class (D2) --
#   sig_artifact_class <node-id-or-path>             -> SIG_ARTIFACT_CLASS
#   -- exclusions (D4) --
#   sig_prune_names                                  find -name prune tokens
#   sig_prune_paths                                  find -path prune tokens
#   sig_class1_excluded <path>                       generated / derived trees
#   sig_class2_excluded <path>                       vendored third-party code
#   sig_class3_ignored <path> <patterns>             the project's own ignore globs
#   sig_class4_excluded <path>                       the dotfile/dot-dir partition, minus its
#                                                    four carve-outs, plus four root metadata files
#   sig_class5_allowlisted <path>                    maintainer tooling re-admitted
#   -- the ignore list (D4a) and the coverage notes (D7) --
#   sig_probe_ignore_list <read-setting> <settings> [<stderr-file>]
#                                                    -> SIG_PROBE (declared|undeclared|unsupported)
#   sig_ignore_note <state> <patterns> <split>       -> SIG_NOTE
#   sig_ignore_applied <state>                       -> SIG_APPLIED (yes|no)
#   sig_coverage_kind_note <kind>                    -> SIG_NOTE
#
# Exit codes (direct execution; also the return codes of the functions above):
#   0 - success / predicate true
#   1 - predicate false
#   2 - usage error, or a fail-closed schema load

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

# The three Kind values this feature emits. REQUIREMENTS 5.2's enum is data,
# carried by feature-003's relationship-schema.yml and loaded by rel_load_schema.
# These are named selectors INTO that enum, never a second copy of it:
# sig_validate_kinds checks all three against the loaded list and fails on a
# mismatch, so the schema stays the single carrier of the closed set.
SIG_KIND_SOURCE_ARTIFACT="source-artifact"
SIG_KIND_IMAGE="image"
SIG_KIND_WEB_PAGE="web-page"

# D1a's external-kind tier. B: the external-sources entry format carries no media
# type, so every registered key is a web-page and no external image node exists.
# ONE constant selects both the classification and D7's image coverage note, so a
# half-done flip to tier A fails a test rather than shipping a false note.
SIG_EXTERNAL_TIER="B"

# The one entry of Class 4's carve-out set that scan-source.sh must re-admit from
# the blanket ./.aid find-prune by hand (the scanner's step 4): every OTHER
# carve-out either was never pruned at that level (.github/workflows/) or already
# carries its own re-admission for an unrelated reason (.claude/skills/
# generate-profile/, Class 5). An allowlist entry is an exemption from an
# exclusion, never a grant of nodehood.
SIG_CLASS4_ALLOWLIST=".aid/settings.yml"

# Installed by sig_set_image_extensions / sig_load_schema. Never a literal list.
SIG_IMAGE_EXTENSIONS=""

# Globals the `_into` twins assign. Declared here so a reader can find them.
SIG_TOKEN=""; SIG_LOWER=""; SIG_EXT=""; SIG_PHRASE=""; SIG_SHAPE=""
SIG_EVIDENCE=""; SIG_CLAUSE=""; SIG_PROVENANCE=""; SIG_QUALIFIER=""
SIG_RANK=""; SIG_LEVEL=""; SIG_ARTIFACT_CLASS=""; SIG_PROBE=""
SIG_NOTE=""; SIG_APPLIED=""
SIG_CANDIDATES=()

# ---------------------------------------------------------------------------
# Case folding. `${v,,}` needs bash 4, and bash 3.2 (the macOS default) cannot
# even parse it, so the fast form is installed behind a version probe and the
# fallback forks tr exactly once per call. Defining a function is not a side
# effect - it is what sourcing this file is for.
# ---------------------------------------------------------------------------

if [ "${BASH_VERSINFO[0]:-3}" -ge 4 ]; then
    eval 'sig_lower_into() { SIG_LOWER="${1,,}"; }'
else
    sig_lower_into() {
        SIG_LOWER=$(printf '%s' "$1" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
    }
fi

sig_lower() { sig_lower_into "$1"; printf '%s' "$SIG_LOWER"; }

# ---------------------------------------------------------------------------
# Token formation (D3b, "Token formation")
#
# A token is a scalar, never a line: the value the carrier's OWN syntax yields for
# the match. A YAML list entry contributes its scalar with the `- ` marker and any
# surrounding quotes removed; a Markdown table cell contributes its content with
# the surrounding pipes, its padding and any inline-code backticks removed; edges
# are trimmed; a line terminator - and a CR immediately before it - is removed.
#
# One forced normalisation, and exactly one: a tab INSIDE a token becomes a single
# space, because a TSV field cannot carry a tab. No escaping is performed and none
# is needed - field 5 is never re-parsed.
# ---------------------------------------------------------------------------

sig_token_into() {
    local t="$1"
    t="${t//$'\r'/}"
    t="${t//$'\n'/}"
    t="${t#|}"
    t="${t%|}"
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    case "$t" in
        "- "*)     t="${t#- }" ;;
        "-"$'\t'*) t="${t#-}" ;;
    esac
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    while [ "${t#\`}" != "$t" ] && [ "${t%\`}" != "$t" ]; do
        t="${t#\`}"
        t="${t%\`}"
    done
    if [ "${#t}" -ge 2 ]; then
        case "$t" in
            \'*\') t="${t#\'}"; t="${t%\'}" ;;
            \"*\") t="${t#\"}"; t="${t%\"}" ;;
        esac
    fi
    t="${t#"${t%%[![:space:]]*}"}"
    t="${t%"${t##*[![:space:]]}"}"
    t="${t//$'\t'/ }"
    SIG_TOKEN="$t"
}

sig_token() { sig_token_into "$1"; printf '%s' "$SIG_TOKEN"; }

# ---------------------------------------------------------------------------
# Evidence rendering (D3b) - one function, every template, so no caller ever
# composes a string itself.
#
#   Shape A - the matched token IS the literal a reviewer greps in the carrier:
#       <subject> -- <carrier phrase> (search: "<token>" in <carrier path>)
#   Shape B - the pattern the scanner matched is NOT what a reviewer greps:
#       <subject> -- <carrier phrase> '<matched>' (search: "<anchor>" in <carrier path>)
#
# Shape B is needed for exactly the two convention arms, because module-map.md
# states its conventions in prose that does not contain the patterns verbatim, so
# a Shape-A template there would print a search token absent from the file it
# names. No third shape exists.
# ---------------------------------------------------------------------------

sig_template_meta_into() {
    case "$1" in
        1)  SIG_PHRASE="build-command script";       SIG_SHAPE="A" ;;
        2)  SIG_PHRASE="registered output path";     SIG_SHAPE="A" ;;
        3)  SIG_PHRASE="shortcut catalog row";       SIG_SHAPE="A" ;;
        4)  SIG_PHRASE="doc_set agent";              SIG_SHAPE="A" ;;
        5)  SIG_PHRASE="asset-kind root";            SIG_SHAPE="A" ;;
        6)  SIG_PHRASE="frontmatter sources: entry"; SIG_SHAPE="A" ;;
        7)  SIG_PHRASE="workflow command token";     SIG_SHAPE="A" ;;
        8)  SIG_PHRASE="published entry point";      SIG_SHAPE="A" ;;
        9)  SIG_PHRASE="published payload";          SIG_SHAPE="A" ;;
        10) SIG_PHRASE="suite discovery glob";       SIG_SHAPE="A" ;;
        11) SIG_PHRASE="convention";                 SIG_SHAPE="B" ;;
        12) SIG_PHRASE="convention";                 SIG_SHAPE="B" ;;
        13) SIG_PHRASE="inbound reference";          SIG_SHAPE="A" ;;
        14) SIG_PHRASE="executable header";          SIG_SHAPE="A" ;;
        *)  echo "significance-rules.sh: no evidence template '$1'" >&2; return 2 ;;
    esac
}

sig_evidence_phrase() { sig_template_meta_into "$1" || return 2; printf '%s' "$SIG_PHRASE"; }
sig_evidence_shape()  { sig_template_meta_into "$1" || return 2; printf '%s' "$SIG_SHAPE"; }

# sig_render_evidence_into <tid> <subject> <token> <carrier> [<anchor>]
# Template 14's carrier IS its subject; that repetition is deliberate, because a
# conditional component would give the template two forms.
sig_render_evidence_into() {
    local tid="$1" subject token carrier anchor phrase shape
    sig_template_meta_into "$tid" || return 2
    phrase="$SIG_PHRASE"; shape="$SIG_SHAPE"
    sig_token_into "$2"; subject="$SIG_TOKEN"
    sig_token_into "$3"; token="$SIG_TOKEN"
    sig_token_into "$4"; carrier="$SIG_TOKEN"
    if [ "$shape" = "B" ]; then
        if [ -z "${5:-}" ]; then
            echo "significance-rules.sh: template $tid needs an anchor" >&2
            return 2
        fi
        sig_token_into "$5"; anchor="$SIG_TOKEN"
        printf -v SIG_EVIDENCE '%s -- %s '\''%s'\'' (search: "%s" in %s)' \
            "$subject" "$phrase" "$token" "$anchor" "$carrier"
    else
        printf -v SIG_EVIDENCE '%s -- %s (search: "%s" in %s)' \
            "$subject" "$phrase" "$token" "$carrier"
    fi
}

sig_render_evidence() {
    sig_render_evidence_into "$@" || return 2
    printf '%s\n' "$SIG_EVIDENCE"
}

# D1a's in-repo image form. <ext> renders the FOLDED bytes - the ones actually
# tested - because the string asserts membership of a list that ships lowercase,
# so printing `PNG` would make the evidence contradict its own test.
sig_render_image_evidence_into() {
    local path ext
    sig_token_into "$1"; path="$SIG_TOKEN"
    sig_token_into "$2"; sig_lower_into "$SIG_TOKEN"; ext="$SIG_LOWER"
    printf -v SIG_EVIDENCE \
        '%s -- extension '\''%s'\'' listed in relationship-schema.yml (search: "image_extensions")' \
        "$path" "$ext"
}

sig_render_image_evidence() {
    sig_render_image_evidence_into "$@" || return 2
    printf '%s\n' "$SIG_EVIDENCE"
}

# D1a's external form: the registry file, plus the key as written in its cell.
sig_render_external_evidence_into() {
    local registry key
    sig_token_into "$1"; registry="$SIG_TOKEN"
    sig_token_into "$2"; key="$SIG_TOKEN"
    printf -v SIG_EVIDENCE '%s (search: "%s")' "$registry" "$key"
}

sig_render_external_evidence() {
    sig_render_external_evidence_into "$@" || return 2
    printf '%s\n' "$SIG_EVIDENCE"
}

# ---------------------------------------------------------------------------
# D3a - the carrier -> qualifier map, total over D3, and the precedence over it
# ---------------------------------------------------------------------------

# Every emitting arm of D3's carrier set maps to exactly one clause.
sig_template_clause_into() {
    case "$1" in
        1|7|8|14)     SIG_CLAUSE="Q1" ;;
        2|3|4|5|9|11) SIG_CLAUSE="Q2" ;;
        6|10|12)      SIG_CLAUSE="Q3" ;;
        13)           SIG_CLAUSE="Q4" ;;
        *) echo "significance-rules.sh: no evidence template '$1'" >&2; return 2 ;;
    esac
}

sig_template_clause() { sig_template_clause_into "$1" || return 2; printf '%s' "$SIG_CLAUSE"; }

# D3's two halves: the project stated it (declared) or the scanner computed it
# (derived). There is no third value - the `no-inferred-node` invariant.
sig_template_provenance_into() {
    case "$1" in
        [1-9]|10)    SIG_PROVENANCE="declared" ;;
        11|12|13|14) SIG_PROVENANCE="derived" ;;
        *) echo "significance-rules.sh: no evidence template '$1'" >&2; return 2 ;;
    esac
}

sig_template_provenance() {
    sig_template_provenance_into "$1" || return 2
    printf '%s' "$SIG_PROVENANCE"
}

sig_clause_qualifier_into() {
    case "$1" in
        Q1) SIG_QUALIFIER="entry-point" ;;
        Q2) SIG_QUALIFIER="public-surface" ;;
        Q3) SIG_QUALIFIER="named-unit" ;;
        Q4) SIG_QUALIFIER="depended-upon" ;;
        *) echo "significance-rules.sh: unknown clause '$1'" >&2; return 2 ;;
    esac
}

sig_clause_qualifier() { sig_clause_qualifier_into "$1" || return 2; printf '%s' "$SIG_QUALIFIER"; }

# P1 > P2 > P3, closed into a TOTAL order over clauses by the P1 tie-break
# (Q1 before Q2, because being executed is the more specific observation). The
# emitted qualifier is the maximum applicable clause, never the first match in
# flow order - which is what makes a severity function that is monotone in this
# precedence and constant on P1 monotone over this field.
sig_clause_rank_into() {
    case "$1" in
        Q1) SIG_RANK=4 ;;
        Q2) SIG_RANK=3 ;;
        Q4) SIG_RANK=2 ;;
        Q3) SIG_RANK=1 ;;
        *) echo "significance-rules.sh: unknown clause '$1'" >&2; return 2 ;;
    esac
}

sig_clause_rank() { sig_clause_rank_into "$1" || return 2; printf '%s' "$SIG_RANK"; }

sig_clause_level_into() {
    case "$1" in
        Q1|Q2) SIG_LEVEL="P1" ;;
        Q4)    SIG_LEVEL="P2" ;;
        Q3)    SIG_LEVEL="P3" ;;
        *) echo "significance-rules.sh: unknown clause '$1'" >&2; return 2 ;;
    esac
}

sig_clause_level() { sig_clause_level_into "$1" || return 2; printf '%s' "$SIG_LEVEL"; }

sig_stronger_clause_into() {
    local a="$1" b="$2" ra rb
    if [ -z "$a" ]; then SIG_CLAUSE="$b"; return 0; fi
    if [ -z "$b" ]; then SIG_CLAUSE="$a"; return 0; fi
    sig_clause_rank_into "$a" || return 2; ra="$SIG_RANK"
    sig_clause_rank_into "$b" || return 2; rb="$SIG_RANK"
    if [ "$ra" -ge "$rb" ]; then SIG_CLAUSE="$a"; else SIG_CLAUSE="$b"; fi
}

sig_stronger_clause() { sig_stronger_clause_into "$1" "$2" || return 2; printf '%s' "$SIG_CLAUSE"; }

# ---------------------------------------------------------------------------
# D3a - the evidence selection rule
#
# The enumerator and the selector are TWO functions, deliberately: the test
# recomputes the candidate set from the enumerator and checks the scanner's
# emitted string for membership and minimality against it, which a single
# combined function would make circular. What the pair decides is the SELECTOR
# given the enumerator - an enumerator that omits an admissible carrier is
# invisible to both, which is why the fixture also carries a golden expected value
# that neither function produces.
# ---------------------------------------------------------------------------

# sig_evidence_candidates_into <clause> <provenance> <match-array-name>
#   Each element of the named array is  tid \t subject \t token \t carrier \t anchor.
#   Fills SIG_CANDIDATES with every admissible evidence string, each formed by
#   D3b's template for the carrier that produced it.
sig_evidence_candidates_into() {
    local want_clause="$1" want_prov="$2" arr="$3"
    local n i row tid subject token carrier anchor
    SIG_CANDIDATES=()
    eval "n=\${#${arr}[@]}"
    i=0
    while [ "$i" -lt "$n" ]; do
        eval "row=\${${arr}[\$i]}"
        i=$((i + 1))
        [ -n "$row" ] || continue
        IFS=$'\t' read -r tid subject token carrier anchor <<<"$row"
        sig_template_clause_into "$tid" || return 2
        [ "$SIG_CLAUSE" = "$want_clause" ] || continue
        sig_template_provenance_into "$tid" || return 2
        [ "$SIG_PROVENANCE" = "$want_prov" ] || continue
        sig_render_evidence_into "$tid" "$subject" "$token" "$carrier" "$anchor" || return 2
        SIG_CANDIDATES+=("$SIG_EVIDENCE")
    done
}

# Printing shape: matches on stdin, candidates on stdout.
sig_evidence_candidates() {
    local want_clause="$1" want_prov="$2" line rows=()
    while IFS= read -r line; do
        rows+=("$line")
    done
    sig_evidence_candidates_into "$want_clause" "$want_prov" rows || return 2
    local c
    for c in ${SIG_CANDIDATES+"${SIG_CANDIDATES[@]}"}; do
        printf '%s\n' "$c"
    done
}

# The emitted evidence is the LC_ALL=C-least member of SIG_CANDIDATES.
#
# `local LC_ALL=C` pins the collation for the `<` comparison below, which is the
# same total order `LC_ALL=C sort | head -n 1` produces on a set of distinct byte
# strings - and this loop makes no fork, which `sort` in a per-node command
# substitution would (about 100 ms each under MSYS). LC_ALL=C is this work's
# precedent: build-project-index.sh:185, kb-freshness-check.sh:460 - deliberately
# not build-kb-index.sh:471's locale-dependent bare `sort`.
#
# The order is total on distinct byte strings, so there is no input it fails to
# decide and no secondary tie-break to specify. Two carriers producing the same
# string are the same member, and the emitted row is byte-identical either way.
sig_evidence_select_into() {
    local LC_ALL=C
    local c best="" seen=0
    for c in ${SIG_CANDIDATES+"${SIG_CANDIDATES[@]}"}; do
        if [ "$seen" -eq 0 ]; then
            best="$c"; seen=1
        elif [[ "$c" < "$best" ]]; then
            best="$c"
        fi
    done
    SIG_EVIDENCE="$best"
    [ "$seen" -eq 1 ]
}

# Printing shape: candidates on stdin, the least on stdout.
sig_evidence_select() {
    local line
    SIG_CANDIDATES=()
    while IFS= read -r line; do
        SIG_CANDIDATES+=("$line")
    done
    sig_evidence_select_into || return 1
    printf '%s\n' "$SIG_EVIDENCE"
}

# ---------------------------------------------------------------------------
# D2a - the kind partition, and the schema seam that feeds it
# ---------------------------------------------------------------------------

# The folded final extension of a path's basename; empty when there is none. A
# dotfile with no further dot (.gitignore) has no extension, and a directory
# artifact (trailing /) never has one.
sig_path_extension_into() {
    local p="$1" base stem
    SIG_EXT=""
    case "$p" in */) return 0 ;; esac
    base="${p##*/}"
    case "$base" in *.*) ;; *) return 0 ;; esac
    stem="${base%.*}"
    [ -n "$stem" ] || return 0
    sig_lower_into "${base##*.}"
    SIG_EXT="$SIG_LOWER"
}

sig_path_extension() { sig_path_extension_into "$1"; printf '%s' "$SIG_EXT"; }

sig_set_image_extensions() { SIG_IMAGE_EXTENSIONS="$*"; }
sig_image_extensions()     { printf '%s' "$SIG_IMAGE_EXTENSIONS"; }

# The extension is lower-cased BEFORE the membership test, since image_extensions
# ships as a lowercase list and feature-003's V13 tier 2 must fold the same way -
# a LOGO.PNG classified image here and re-checked case-sensitively there would be
# reported as a table defect with no defect in it. A directory is never an image
# (feature-003 D1a's rule, consumed rather than re-derived).
sig_is_image() {
    local e
    sig_path_extension_into "$1"
    [ -n "$SIG_EXT" ] || return 1
    for e in $SIG_IMAGE_EXTENSIONS; do
        if [ "$e" = "$SIG_EXT" ]; then
            return 0
        fi
    done
    return 1
}

# sig_load_schema <schema-file> [<loader-path>]
#
# image_extensions is DATA, read through feature-003's rel_load_schema (D9) and
# never copied into this feature's code. Loader-first: when relationship-schema.sh
# is present it is sourced and rel_load_schema is called, which is the contract and
# which itself fails closed on an absent, empty or malformed schema file.
#
# While that sibling script is not yet installed, the SAME shipped data file is
# read for its image_extensions line and a notice goes to stderr. That transitional
# arm copies no list and creates no second source of truth - it reads the one
# carrier the loader would have read - and it goes dormant the moment the loader
# lands. Exit 2 (fail closed) when neither path yields a list, so a configuration
# error is never reported as an enumeration result.
sig_load_schema() {
    local schema="$1" loader="${2:-}" exts=""
    if [ -n "$loader" ] && [ -f "$loader" ]; then
        # shellcheck disable=SC1090
        . "$loader" || { echo "significance-rules.sh: cannot source $loader" >&2; return 2; }
        if command -v rel_load_schema >/dev/null 2>&1; then
            rel_load_schema "$schema" || return 2
            if command -v rel_image_extensions >/dev/null 2>&1; then
                exts=$(rel_image_extensions)
            elif [ -n "${REL_IMAGE_EXTENSIONS:-}" ]; then
                exts="${REL_IMAGE_EXTENSIONS}"
            fi
        fi
    else
        echo "significance-rules.sh: notice: relationship-schema.sh is not installed; reading image_extensions directly from ${schema}" >&2
    fi
    if [ -z "$exts" ]; then
        if [ ! -f "$schema" ]; then
            echo "significance-rules.sh: schema file not found at ${schema}" >&2
            return 2
        fi
        exts=$(awk '
            /^image_extensions:[[:space:]]*\[/ {
                line = $0
                sub(/^image_extensions:[[:space:]]*\[/, "", line)
                sub(/\].*$/, "", line)
                gsub(/[",]/, " ", line)
                print line
                exit
            }
        ' "$schema")
    fi
    exts="${exts//,/ }"
    if [ -z "${exts// /}" ]; then
        echo "significance-rules.sh: no image_extensions in ${schema}" >&2
        return 2
    fi
    # shellcheck disable=SC2086  # deliberate word splitting: the list is space separated
    sig_set_image_extensions $exts
    return 0
}

# The three Kind values this feature emits must all be members of the loaded enum.
sig_validate_kinds() {
    local want k found
    for want in "$SIG_KIND_SOURCE_ARTIFACT" "$SIG_KIND_IMAGE" "$SIG_KIND_WEB_PAGE"; do
        found=1
        for k in "$@"; do
            if [ "$k" = "$want" ]; then
                found=0
                break
            fi
        done
        if [ "$found" -ne 0 ]; then
            echo "significance-rules.sh: Kind '${want}' is absent from the loaded enum" >&2
            return 1
        fi
    done
    return 0
}

# ---------------------------------------------------------------------------
# D2 - artifact_class, a first-match ordered rule list over the node id alone
#
# Order is the whole content of this list. Located rules sit above generic ones:
# settings.yml and generated-files.txt live under canonical/aid/templates/, so 8
# and 9 precede 11; tests/* carry .sh and dashboard/reader/* carries .py, so 10, 12
# and 13 precede the extension-based rule 14; .md is common enough that 15 sits
# last before the catch-all. Rule 16 is what makes the enum TOTAL for a project AID
# did not author, while keeping it closed. Nothing here consults evidence,
# provenance or the qualifier. Under `case` semantics * spans /, which is why the
# patterns are short.
# ---------------------------------------------------------------------------

sig_artifact_class_into() {
    local p="${1#int:}"
    case "$p" in
        .codex/skills/*/)                       SIG_ARTIFACT_CLASS="skill" ;;
        .codex/agents/*/)                       SIG_ARTIFACT_CLASS="agent" ;;
        .github/workflows/*)                       SIG_ARTIFACT_CLASS="workflow" ;;
        .claude/skills/generate-profile/scripts/*) SIG_ARTIFACT_CLASS="renderer" ;;
        install.sh|install.ps1)                    SIG_ARTIFACT_CLASS="installer" ;;
        bin/*|packages/*/bin/*)                    SIG_ARTIFACT_CLASS="cli-entrypoint" ;;
        lib/*)                                     SIG_ARTIFACT_CLASS="library" ;;
        .aid/settings.yml|.codex/aid/templates/settings.yml)
                                                   SIG_ARTIFACT_CLASS="settings-schema" ;;
        canonical/EMISSION-MANIFEST.md|*/package.json|*/pyproject.toml|.codex/aid/templates/generated-files.txt)
                                                   SIG_ARTIFACT_CLASS="manifest" ;;
        tests/*)                                   SIG_ARTIFACT_CLASS="test-suite" ;;
        .codex/aid/templates/*)                 SIG_ARTIFACT_CLASS="template" ;;
        dashboard/*)                               SIG_ARTIFACT_CLASS="dashboard-module" ;;
        site/*)                                    SIG_ARTIFACT_CLASS="site-module" ;;
        .codex/aid/scripts/*|*.sh|*.ps1|*.psm1|*.py)
                                                   SIG_ARTIFACT_CLASS="script" ;;
        *.md)                                      SIG_ARTIFACT_CLASS="doc" ;;
        *)                                         SIG_ARTIFACT_CLASS="source" ;;
    esac
}

sig_artifact_class() { sig_artifact_class_into "$1"; printf '%s' "$SIG_ARTIFACT_CLASS"; }

# ---------------------------------------------------------------------------
# D4 - the exclusion filter, applied before classification and before significance
#
# The git-native arms (check-ignore, check-attr) and the @generated header
# predicate are batched process-level mechanisms and live in the scanner's step 5,
# one process per mechanism and never one per file. What lives here is every
# path-shaped predicate, so the rule and its test read the same code.
# ---------------------------------------------------------------------------

# Directory names safe to prune anywhere in the tree: none carries an allowlist.
sig_prune_names() {
    printf '%s\n' .git .svn .hg node_modules .cursor .codex .agent
}

# Root-anchored directory prunes - root-anchored rather than by basename, because
# a target project may legitimately hold src/profiles/ or a nested dist/. .aid and
# .claude are pruned here and their two declared allowlist entries are re-admitted
# by the scanner, which is cheaper than walking a render tree only to drop it.
sig_prune_paths() {
    printf '%s\n' ./profiles ./site/dist ./.aid ./.claude
}

# Class 1 - generated / derived trees. Unconditional, never dependent on settings.
sig_class1_excluded() {
    case "$1" in
        profiles|profiles/*) return 0 ;;
        .claude/*|.cursor/*|.codex/*|.agent/*) return 0 ;;
        .github/aid/*) return 0 ;;
        packages/npm/bin/aid|packages/npm/bin/aid.ps1|packages/npm/bin/aid.cmd) return 0 ;;
        packages/npm/lib/*|packages/npm/dashboard/*|packages/npm/VERSION) return 0 ;;
        packages/pypi/aid_installer/_vendor/*|packages/pypi/dist/*) return 0 ;;
        site/dist/*) return 0 ;;
        .aid/generated/*) return 0 ;;
    esac
    return 1
}

# Class 2 - vendored third-party code. Unconditional.
sig_class2_excluded() {
    case "$1" in
        node_modules/*|*/node_modules/*) return 0 ;;
        packages/*/_vendor/*|*/_vendor/*) return 0 ;;
    esac
    return 1
}

# Class 3 - the project's own ignore list. <patterns> is read-setting.sh's
# comma-joined list; patterns are repo-relative globs matched with `case`
# semantics, the style build-project-index.sh uses for NOTABLE_PATH_PATTERNS. One
# limitation follows from the comma-joined transport and is stated rather than
# discovered later: an ignore pattern may not contain a comma (D4a).
sig_class3_ignored() {
    local path="$1" rest="${2:-}" pat
    [ -n "$rest" ] || return 1
    while [ -n "$rest" ]; do
        case "$rest" in
            *,*) pat="${rest%%,*}"; rest="${rest#*,}" ;;
            *)   pat="$rest"; rest="" ;;
        esac
        pat="${pat#"${pat%%[![:space:]]*}"}"
        pat="${pat%"${pat##*[![:space:]]}"}"
        [ -n "$pat" ] || continue
        # shellcheck disable=SC2254  # the pattern is data and must glob
        case "$path" in
            $pat) return 0 ;;
        esac
    done
    return 1
}

# Class 4 - the dotfile / dot-directory partition, plus four repo-root metadata
# files (generalised 2026-08-06, owner decision following an FR-21 finding that
# vetoed one candidate exclusion). A path is cut here when EITHER of two
# independent tests holds, checked in this order:
#
#   (a) it does not match one of the four root-anchored carve-outs below, AND
#       some '/'-delimited segment of the path begins with '.', at ANY depth -
#       not only at the repo root, so a fixture tree that carries its own
#       nested .aid/** (a project-under-test, not this one) is cut exactly like
#       a root one. A carve-out match is a path-PREFIX test ending on a '/'
#       boundary (or, for the one single-file entry, an exact match) - never a
#       substring test, so a path that merely shares a carve-out's text
#       (`.aid/knowledge-old/*`) is NOT exempted by it.
#   (b) the path is exactly one of four repo-root pointer/metadata files:
#       `CLAUDE.md`, `AGENTS.md`, `LICENSE`, `VERSION`. (Not
#       `packages/npm/VERSION`, already cut by Class 1 for an unrelated reason -
#       an unprefixed literal match is root-anchored by construction.)
#
# The four carve-outs, and why each earned its exemption rather than being cut
# with the rest of its dot-tree:
#   .aid/knowledge/                   the Knowledge Base - this graph's own
#                                     subject (owner decision)
#   .aid/settings.yml                 SPEC.md's "Class 4 - the .aid/ partition,
#                                     and why it is not optional": a declared
#                                     allowlist entry, an FR-11 staleness input,
#                                     and the only backing several KB claims cite
#                                     (owner decision, confirming the SPEC rather
#                                     than reopening it)
#   .claude/skills/generate-profile/  unique, hand-authored maintainer tooling
#                                     with no canonical/ original (Class 5's own
#                                     rationale, D2 rule 4 - re-admitted there
#                                     from Class 1, and carved out here too so
#                                     the general dot-rule does not re-cut it
#                                     first)
#   .github/workflows/                FR-21 / D3a's Q1 carrier table row 7: a
#                                     workflow step's command token is a
#                                     DECLARED entry-point carrier, and
#                                     scan-source.sh's template-7 carrier can
#                                     only read a workflow file if that file is
#                                     already a walked candidate - excluding it
#                                     retires the carrier, not just the node
#
# `.github/dependabot.yml` and `.github/ISSUE_TEMPLATE/**` are NOT exempted:
# `.github` is a dot segment like any other, and only `workflows/` earned a
# carve-out. The KB-side and int: node sets must stay disjoint (D1): the cut
# here is on a path becoming a node, not on reading - external-sources.md is
# read as a registry and never becomes an int: node, and nothing in this
# feature makes `.aid/knowledge/**` reachable past the scanner's own step-4
# find-prune, so the carve-out's admission of it is a predicate fact this
# function upholds without this feature enumerating a single KB document as a
# source-artifact candidate.
sig_class4_excluded() {
    case "$1" in
        .aid/knowledge|.aid/knowledge/*)                       return 1 ;;
        .aid/settings.yml)                                     return 1 ;;
        .claude/skills/generate-profile|.claude/skills/generate-profile/*) return 1 ;;
        .github/workflows|.github/workflows/*)                 return 1 ;;
    esac
    case "$1" in
        .*|*/.*)                          return 0 ;;
        CLAUDE.md|AGENTS.md|LICENSE|VERSION) return 0 ;;
    esac
    return 1
}

# Class 5 - maintainer tooling authored in place under a normally-excluded tree.
# .claude/skills/generate-profile/** is the renderer, not a render of canonical/.
sig_class5_allowlisted() {
    case "$1" in
        .claude/skills/generate-profile/*) return 0 ;;
    esac
    return 1
}

# ---------------------------------------------------------------------------
# D4a - the three-state ignore-list probe, and the notes it drives
# ---------------------------------------------------------------------------

# sig_probe_ignore_list <read-setting.sh> <settings-file> [<stderr-capture-file>]
#
# Sets SIG_PROBE to `declared` or `undeclared`, which is read-setting.sh --probe's
# stdout contract, or to `unsupported` when this installation's resolver does not
# carry --probe yet.
#
# `unsupported` is NOT a fourth state of the setting. It is the honest answer to a
# different question - "was the list probeable?" - and it is reported through its
# own note rather than collapsed into `undeclared`, which would assert that a probe
# ran and found the section absent when no probe ran at all. Collapsing the two
# would be the same silent-wrongness FR-22's reporting rule exists to prevent.
#
# Settings are read only through the resolver; this function never hand-parses
# settings.yml (coding-standards.md, "Reading config").
sig_probe_ignore_list() {
    local resolver="$1" settings="$2" errfile="${3:-/dev/null}" out
    SIG_PROBE="unsupported"
    if [ ! -f "$resolver" ]; then
        return 0
    fi
    if ! out=$(bash "$resolver" --probe --path graph.ignore --file "$settings" 2>"$errfile"); then
        return 0
    fi
    case "$out" in
        declared|undeclared) SIG_PROBE="$out" ;;
    esac
    return 0
}

# sig_ignore_note_into <state> <pattern-count> <comma-split-count>
sig_ignore_note_into() {
    local state="$1" n="${2:-0}" split="${3:-0}"
    case "$state" in
        undeclared)
            SIG_NOTE="setting absent -- ignore list unavailable (D-4)" ;;
        unsupported)
            SIG_NOTE="probe unsupported by this resolver -- ignore list unavailable (D-4)" ;;
        declared)
            if [ "$split" -gt 0 ]; then
                printf -v SIG_NOTE 'declared, %s patterns (%s item(s) contained a comma and were split)' \
                    "$n" "$split"
            else
                printf -v SIG_NOTE 'declared, %s patterns' "$n"
            fi ;;
        *) echo "significance-rules.sh: unknown probe state '$state'" >&2; return 2 ;;
    esac
}

sig_ignore_note() { sig_ignore_note_into "$@" || return 2; printf '%s' "$SIG_NOTE"; }

# Classes 1 and 2 are applied in all three states - FR-22 calls them unconditional
# and they never consult settings, which is what makes "proceed with the other two
# exclusions" a property of the code rather than an instruction.
sig_ignore_applied_into() {
    case "$1" in
        declared)               SIG_APPLIED="yes" ;;
        undeclared|unsupported) SIG_APPLIED="no" ;;
        *) echo "significance-rules.sh: unknown probe state '$1'" >&2; return 2 ;;
    esac
}

sig_ignore_applied() { sig_ignore_applied_into "$1" || return 2; printf '%s' "$SIG_APPLIED"; }

# ---------------------------------------------------------------------------
# D7 - the carrier-convention note per kind. The image row's text is selected by
# the SAME tier constant that selects the classification, so the pair cannot drift:
# whoever flips the tier changes the classification and the sentence in one edit.
# ---------------------------------------------------------------------------

sig_coverage_kind_note_into() {
    case "$1" in
        "$SIG_KIND_SOURCE_ARTIFACT")
            SIG_NOTE="project source, per FR-21 significance" ;;
        "$SIG_KIND_IMAGE")
            if [ "$SIG_EXTERNAL_TIER" = "B" ]; then
                SIG_NOTE="image files in-repo; no external key is an image (D-5)"
            else
                SIG_NOTE="image files in-repo; external keys typed as images"
            fi ;;
        "$SIG_KIND_WEB_PAGE")
            SIG_NOTE="entries in the external-sources file" ;;
        *) echo "significance-rules.sh: no coverage note for kind '$1'" >&2; return 2 ;;
    esac
}

sig_coverage_kind_note() { sig_coverage_kind_note_into "$1" || return 2; printf '%s' "$SIG_NOTE"; }

# ---------------------------------------------------------------------------
# Direct execution: this file is a library. Print the header on --help; anything
# else is a usage error. `set -eu` is applied here and nowhere else, so sourcing
# never mutates the caller's shell options.
# ---------------------------------------------------------------------------

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    set -eu
    case "${1:-}" in
        -h|--help)
            sed -n '2,85p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "significance-rules.sh: this is a sourceable library; use --help for its function index" >&2
            exit 2
            ;;
    esac
fi
