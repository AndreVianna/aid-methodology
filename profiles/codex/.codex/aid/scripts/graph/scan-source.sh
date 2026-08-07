#!/usr/bin/env bash
# scan-source.sh - enumerate the project's source, media and external graph nodes.
#
# Purpose:
#   The single traversal of the project source behind /aid-graph. One walk decides
#   which artifacts are structurally significant (FR-21), classifies in-repo images
#   and registered external keys by kind (FR-21a), applies the three FR-22
#   exclusions, and records every reference it sees on the way past. Enumeration is
#   independent of the Knowledge Base (FR-19), so an artifact the KB never mentions
#   still becomes a node and can be reported as a gap.
#
#   There is exactly one walk. Sibling scripts under this directory read what this
#   one wrote; a second repository traversal would drift from this one and the two
#   would disagree about what exists.
#
# Usage:
#   scan-source.sh [--schema PATH] [--external-sources PATH] [--out-dir PATH]
#   scan-source.sh -h | --help
#
# Flags:
#   --schema PATH            relationship-schema.yml, for image_extensions and the
#                            Kind enum. Default: <install-root>/aid/templates/graph/
#                            relationship-schema.yml, resolved from this script's
#                            own location.
#   --external-sources PATH  the external-sources registry to read.
#                            Default: <repo>/.aid/knowledge/external-sources.md.
#   --out-dir PATH           where the streams are written.
#                            Default: <repo>/.aid/.temp/graph.
#
# Outputs (all TSV, no header, LF endings, LC_ALL=C-sorted, byte-stable):
#   nodes.tsv        node_id, name, artifact_class, qualifier, evidence,
#                    evidence_provenance, node_kind - one row per significant
#                    source-artifact (D1)
#   media-nodes.tsv  node_id, name, node_kind, evidence, evidence_provenance -
#                    one row per in-repo image and per registered external key.
#                    There is no qualifier field, which is how FR-21a's "by kind,
#                    not by significance" exemption is made unrepresentable (D1a)
#   observations.tsv from_id, to_id, observation_kind, evidence - one row per
#                    reference seen during the same walk, untyped (D5)
#   candidates.tsv   candidate_kind, subject, context, drop_reason - what the rules
#                    noticed but could not qualify or resolve (D6). Write-only: no
#                    candidate is ever promoted to a node
#   coverage.tsv     scope, key, status, count, note - this run's contribution to
#                    the report's coverage notes, in fixed row order (D7)
#
#   No field carries a timestamp, an absolute path, a line number or a file size,
#   and no row order depends on a count. That is what makes two runs over an
#   unchanged tree byte-identical (FR-32).
#
# Read-only: this script writes only under --out-dir and modifies no source or KB
# file (FR-10).
#
# Exit codes:
#   0 - the scan completed
#   1 - a write failure, or a single-writer assertion rejected a row
#   2 - a usage error, a fail-closed schema load, or a non-git working tree

set -euo pipefail

# Byte order everywhere: every sort, every string comparison, every awk range.
# This is the collation the streams are specified in and the one the evidence
# selection rule names (build-project-index.sh:185, kb-freshness-check.sh:460).
export LC_ALL=C

SELF="scan-source.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# <install-root>/aid/scripts/graph -> <install-root>. Holds for the canonical tree
# (canonical/aid/scripts/graph -> canonical/) and for every rendered profile, so no
# separate resolution rule is needed for either.
INSTALL_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)

# shellcheck source=./significance-rules.sh
. "${SCRIPT_DIR}/significance-rules.sh"

SCHEMA=""
EXTERNAL_SOURCES=""
OUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --schema)           SCHEMA="$2"; shift 2 ;;
        --external-sources) EXTERNAL_SOURCES="$2"; shift 2 ;;
        --out-dir)          OUT_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,56p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "${SELF}: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

[ -n "$SCHEMA" ] || SCHEMA="${INSTALL_ROOT}/aid/templates/graph/relationship-schema.yml"
SCHEMA_LOADER="${SCRIPT_DIR}/relationship-schema.sh"

# ---------------------------------------------------------------------------
# Step 1 - resolve the repository root.
#
# Classes 1-3 rest on `git check-ignore` and `git check-attr`, so a non-git
# checkout cannot produce a reproducible exclusion set. Fail rather than silently
# enumerate a different set of nodes than the same tree would produce under git.
# ---------------------------------------------------------------------------

if ! ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "${SELF}: not inside a git working tree; the FR-22 exclusions need git check-ignore and git check-attr" >&2
    exit 2
fi
cd "$ROOT"

[ -n "$OUT_DIR" ] || OUT_DIR=".aid/.temp/graph"
[ -n "$EXTERNAL_SOURCES" ] || EXTERNAL_SOURCES=".aid/knowledge/external-sources.md"

KB_DIR=".aid/knowledge"
SETTINGS_FILE=".aid/settings.yml"
RESOLVER="${INSTALL_ROOT}/aid/scripts/config/read-setting.sh"

W=$(mktemp -d 2>/dev/null) || { echo "${SELF}: cannot create a scratch directory" >&2; exit 1; }
trap 'rm -rf "$W"' EXIT

# ---------------------------------------------------------------------------
# Step 2 - load the schema.
#
# image_extensions and the Kind enum are data, read through feature-003's loader
# and never copied here. Loading before the walk means a configuration error is
# never reported as an enumeration result.
# ---------------------------------------------------------------------------

sig_load_schema "$SCHEMA" "$SCHEMA_LOADER" || exit 2
if [ -n "${REL_KINDS:-}" ]; then
    # shellcheck disable=SC2086  # deliberate word splitting over the loaded enum
    sig_validate_kinds ${REL_KINDS} || exit 2
fi

# ---------------------------------------------------------------------------
# Step 3 - probe the ignore list, read its patterns, load the external registry.
#
# Three states, one probe: `declared` and `undeclared` are distinct, because "you
# configured an empty list" and "there is no list to configure" are the difference
# the report exists to preserve. Settings are read only through the resolver.
# ---------------------------------------------------------------------------

sig_probe_ignore_list "$RESOLVER" "$SETTINGS_FILE" "$W/probe.err"
IGNORE_STATE="$SIG_PROBE"
IGNORE_PATTERNS=""
IGNORE_COUNT=0
IGNORE_SPLIT=0

if [ "$IGNORE_STATE" = "declared" ]; then
    IGNORE_PATTERNS=$(bash "$RESOLVER" --path graph.ignore --file "$SETTINGS_FILE" --default '' 2>/dev/null || true)
    if [ -n "$IGNORE_PATTERNS" ]; then
        _rest="$IGNORE_PATTERNS"
        while [ -n "$_rest" ]; do
            case "$_rest" in
                *,*) _rest="${_rest#*,}" ;;
                *)   _rest="" ;;
            esac
            IGNORE_COUNT=$((IGNORE_COUNT + 1))
        done
    fi
    # The comma limitation is only decidable inside the resolver, where the raw
    # items are still separate; --probe warns once per offending item on stderr and
    # the durable note carries the count.
    if [ -s "$W/probe.err" ]; then
        IGNORE_SPLIT=$(grep -c 'contains a comma' "$W/probe.err" 2>/dev/null || true)
        [ -n "$IGNORE_SPLIT" ] || IGNORE_SPLIT=0
    fi
elif [ "$IGNORE_STATE" = "undeclared" ]; then
    echo "[scan] notice: graph.ignore not declared in ${SETTINGS_FILE} -- ignore list unavailable; proceeding with the unconditional exclusions" >&2
else
    echo "[scan] notice: ${RESOLVER} does not support --probe -- ignore list unavailable; proceeding with the unconditional exclusions" >&2
fi

# The display form of the registry path, which is what reaches field 4 of every
# ext: media row. It is NEVER the resolved absolute path: D1a requires the evidence
# to be greppable in the target repository and byte-stable across machines, and an
# absolute path is neither - it would put a developer's home directory into a stream
# that FR-32 requires two machines to reproduce byte for byte. Repo-relative when
# the registry lives inside the repository (the default case, which yields D1a's
# exact bytes), else the bare basename, which is the same fallback D1a applies to
# the schema file for the same reason.
EXTERNAL_SOURCES_REL="$EXTERNAL_SOURCES"
case "$EXTERNAL_SOURCES_REL" in
    "${ROOT}/"*) EXTERNAL_SOURCES_REL="${EXTERNAL_SOURCES_REL#"${ROOT}/"}" ;;
esac
case "$EXTERNAL_SOURCES_REL" in
    /*|[A-Za-z]:[/\\]*) EXTERNAL_SOURCES_REL="${EXTERNAL_SOURCES_REL##*/}" ;;
esac

# The ext: registry: within `## Sources`, a GFM table row whose first cell is a key
# rendered as inline code registers that key (feature-003 D2c). The predicate is
# match-based, so an absent or key-less file registers nothing and is not an error.
: > "$W/ext.keys"
if [ -f "$EXTERNAL_SOURCES" ]; then
    awk '
        /^##[[:space:]]/ { insec = ($0 ~ /^##[[:space:]]+Sources[[:space:]]*$/) ; next }
        !insec { next }
        /^\|[[:space:]]*`[^`]+`[[:space:]]*\|/ {
            line = $0
            sub(/^\|[[:space:]]*`/, "", line)
            sub(/`.*$/, "", line)
            if (line ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) print line
        }
    ' "$EXTERNAL_SOURCES" | sort -u > "$W/ext.keys"
fi
EXT_KEY_COUNT=$(wc -l < "$W/ext.keys" | tr -d ' ')

# ---------------------------------------------------------------------------
# Step 4 - collect candidate paths.
#
# One find from the root with a directory-prune expression, then LC_ALL=C sort. The
# prune set is the cheap, directory-shaped half of D4; the remaining exclusions are
# path- and content-shaped and run in step 5. .aid and .claude are pruned here and
# their two DECLARED allowlist entries are re-admitted immediately below - walking
# a render tree only to drop it costs time and buys nothing.
# ---------------------------------------------------------------------------

PRUNE=()
while IFS= read -r _n; do
    [ ${#PRUNE[@]} -eq 0 ] || PRUNE+=( -o )
    PRUNE+=( -name "$_n" )
done < <(sig_prune_names)
while IFS= read -r _p; do
    PRUNE+=( -o -path "$_p" )
done < <(sig_prune_paths)

find . \( "${PRUNE[@]}" \) -prune -o -type f -print 2>/dev/null \
    | sed 's|^\./||' > "$W/paths.found"

# Re-admit the two declared allowlist entries the prune above removed. Neither is a
# second walk of the project source: one is a single named file, the other a fixed
# subdirectory named by the allowlist itself.
if [ -f "$SIG_CLASS4_ALLOWLIST" ]; then
    printf '%s\n' "$SIG_CLASS4_ALLOWLIST" >> "$W/paths.found"
fi
if [ -d ".claude/skills/generate-profile" ]; then
    find .claude/skills/generate-profile -type f -print 2>/dev/null \
        | sed 's|^\./||' >> "$W/paths.found"
fi

sort -u "$W/paths.found" -o "$W/paths.found"

# ---------------------------------------------------------------------------
# Step 5 - apply the exclusion filter (D4), in class order, as batched removals.
#
# One process per mechanism, never one per file: build-project-index.sh records
# that per-file forks under Windows Git Bash / MSYS cost 0.5-1.8 s each and
# dominated its runtime. Removal-only, so the result is order-independent.
# ---------------------------------------------------------------------------

: > "$W/excl.git"
if [ -s "$W/paths.found" ]; then
    # -c core.excludesFile=/dev/null neutralises the developer's global gitignore,
    # which is what makes the exclusion set identical on every machine.
    git -c core.excludesFile=/dev/null check-ignore --stdin < "$W/paths.found" \
        >> "$W/excl.git" 2>/dev/null || true
    git check-attr --stdin linguist-generated linguist-vendored < "$W/paths.found" 2>/dev/null \
        | sed -n -E 's/: linguist-(generated|vendored): (set|true)$//p' >> "$W/excl.git" || true
    tr '\n' '\0' < "$W/paths.found" \
        | xargs -0 awk 'FNR<=2 && /@generated|DO NOT EDIT|DO NOT MODIFY/ { print FILENAME }' \
            2>/dev/null >> "$W/excl.git" || true
fi
sort -u "$W/excl.git" -o "$W/excl.git"

# The exclusion set is loaded in BEGIN rather than through the NR==FNR two-file
# idiom, and that is load-bearing: when the first file is EMPTY, awk never reads a
# record from it, so NR==FNR is still true on the second file's first record and the
# whole second file is swallowed. An empty excl.git is the normal case for a project
# with nothing gitignored, which is precisely where the idiom would have dropped
# every candidate path. Every join in this script uses the BEGIN form for the same
# reason.
awk -F'\t' -v EXCL="$W/excl.git" '
    BEGIN { while ((getline l < EXCL) > 0) ex[l] = 1; close(EXCL) }
    { print $0 "\t" (($0 in ex) ? 1 : 0) }
' "$W/paths.found" > "$W/paths.marked"

# ---------------------------------------------------------------------------
# Steps 5 (path-shaped classes), 6 (kind partition + granularity cut) - one pass.
#
# The kind partition runs BEFORE any significance clause is evaluated, and the
# ordering is forced rather than chosen: feature-003's V13 tier 2 asserts that an
# int: id is `image` iff its extension is in image_extensions, so qualifying first
# and classifying second could write an image into nodes.tsv as depended-upon and
# fail the table. A path lands in exactly one stream.
#
# The granularity cut is applied to the source-artifact side only: skill and agent
# directories collapse to one directory id and their member files are suppressed.
# Image members are EXEMPT - an image is not source, and suppressing it would make
# a document-depicts-image edge unrepresentable whenever the picture happened to
# live under a collapsed directory. No code path here produces a `#` in an int: id.
# ---------------------------------------------------------------------------

: > "$W/img.paths"
: > "$W/nodemap.tsv"
: > "$W/convdir.tsv"

while IFS=$'\t' read -r p gitex; do
    [ -n "$p" ] || continue
    # Class 5 re-admits FROM CLASS 1 and from nothing else, which is exactly what
    # D4 says. It is not a blanket exemption: the renderer tree is hand-authored
    # source that happens to sit under a rendered install root, but a gitignored
    # __pycache__/*.pyc beneath it is still generated output and Class 3's
    # git-native arm is still the right thing to cut it with.
    if [ "$gitex" = "1" ]; then continue; fi
    if sig_class2_excluded "$p"; then continue; fi
    if sig_class4_excluded "$p"; then continue; fi
    if ! sig_class5_allowlisted "$p"; then
        if sig_class1_excluded "$p"; then continue; fi
    fi
    if [ "$IGNORE_STATE" = "declared" ] && sig_class3_ignored "$p" "$IGNORE_PATTERNS"; then
        continue
    fi

    if sig_is_image "$p"; then
        printf '%s\n' "$p" >> "$W/img.paths"
        continue
    fi

    node="$p"
    case "$p" in
        .codex/skills/*/*)
            _rest="${p#.codex/skills/}"
            node=".codex/skills/${_rest%%/*}/"
            case "${_rest#*/}" in
                SKILL.md) printf '%s\tskill\n' "$node" >> "$W/convdir.tsv" ;;
            esac
            ;;
        .codex/agents/*/*)
            _rest="${p#.codex/agents/}"
            node=".codex/agents/${_rest%%/*}/"
            case "${_rest#*/}" in
                AGENT.md) printf '%s\tagent\n' "$node" >> "$W/convdir.tsv" ;;
            esac
            ;;
    esac
    printf '%s\t%s\n' "$p" "$node" >> "$W/nodemap.tsv"
done < "$W/paths.marked"

sort -u "$W/nodemap.tsv" -o "$W/nodemap.tsv"
sort -u "$W/img.paths" -o "$W/img.paths"
sort -u "$W/convdir.tsv" -o "$W/convdir.tsv"

cut -f2 "$W/nodemap.tsv" | sort -u > "$W/cand.ids"
awk -F'\t' '$1 == $2 { print $1 }' "$W/nodemap.tsv" > "$W/files.filelevel"

SRC_CANDIDATES=$(wc -l < "$W/cand.ids" | tr -d ' ')
IMG_CARRIERS=$(wc -l < "$W/img.paths" | tr -d ' ')

# Lookup tables. idmap.src resolves a carrier's path token to the source-artifact
# node that owns it: a suppressed member of a collapsed directory maps to that
# directory, because the collapse means the directory IS the artifact. idmap.all
# adds the image ids, which references must resolve to (D5) so a citation of a
# picture is not recorded as a spurious unresolved candidate.
{
    cat "$W/nodemap.tsv"
    awk -F'\t' '{ print $2 "\t" $2 }' "$W/nodemap.tsv"
} | sort -u > "$W/idmap.src.tsv"
{
    cat "$W/idmap.src.tsv"
    awk '{ print $0 "\t" $0 }' "$W/img.paths"
} | sort -u > "$W/idmap.all.tsv"

# Basename index over the enumerated node set, for D5's single-valued basename arm.
awk -F'\t' '
    { id = $2; base = id; sub(/\/$/, "", base); sub(/^.*\//, "", base)
      if (!(id in seenid)) { seenid[id] = 1; cnt[base]++; one[base] = id } }
    END { for (b in cnt) printf "%s\t%d\t%s\n", b, cnt[b], one[b] }
' "$W/idmap.all.tsv" | sort > "$W/basemap.tsv"

# ---------------------------------------------------------------------------
# Step 7 - emit the in-repo image nodes.
#
# No significance clause is evaluated: FR-21a makes these nodes by kind, and the
# media writer has no field to record a verdict in.
# ---------------------------------------------------------------------------

MEDIA_ROWS="$W/media.rows"
: > "$MEDIA_ROWS"
IMAGE_NODES=0

# The single writer for media-nodes.tsv, carrying D3's four assertions. A row that
# trips one is a scanner bug, not a data condition, so it aborts rather than being
# filtered.
emit_media_row() {
    local id="$1" name="$2" kind="$3" ev="$4" prov="$5" row
    case "$prov" in
        declared|derived) ;;
        *) echo "${SELF}: refusing a media row with evidence_provenance '${prov}' (${id})" >&2; exit 1 ;;
    esac
    case "$id" in
        int:*\#*|ext:*\#*) echo "${SELF}: refusing a media id carrying a fragment: ${id}" >&2; exit 1 ;;
    esac
    case "$id" in
        int:*)
            local _p="${id#int:}"
            if sig_class2_excluded "$_p" || sig_class4_excluded "$_p"; then
                echo "${SELF}: refusing an excluded path as a media node: ${_p}" >&2; exit 1
            fi
            if ! sig_class5_allowlisted "$_p" && sig_class1_excluded "$_p"; then
                echo "${SELF}: refusing an excluded path as a media node: ${_p}" >&2; exit 1
            fi ;;
    esac
    printf -v row '%s\t%s\t%s\t%s\t%s' "$id" "$name" "$kind" "$ev" "$prov"
    case "$row" in
        *$'\t'*$'\t'*$'\t'*$'\t'*$'\t'*)
            echo "${SELF}: refusing a media row containing a tab inside a field: ${id}" >&2; exit 1 ;;
    esac
    printf '%s\n' "$row" >> "$MEDIA_ROWS"
}

while IFS= read -r p; do
    [ -n "$p" ] || continue
    sig_path_extension_into "$p"
    sig_render_image_evidence_into "$p" "$SIG_EXT"
    emit_media_row "int:${p}" "$p" "$SIG_KIND_IMAGE" "$SIG_EVIDENCE" "derived"
    IMAGE_NODES=$((IMAGE_NODES + 1))
done < "$W/img.paths"

# ---------------------------------------------------------------------------
# Step 8 - qualify the source artifacts by rule (first pass).
#
# Each carrier below writes rows of  node \t template \t token \t carrier \t anchor
# into matches.tsv. The template id is what ties a match to its clause, its
# provenance and its evidence bytes, all three of which live in the library - so
# adding a carrier is a matter of naming its template, never of composing a string
# here.
# ---------------------------------------------------------------------------

MATCHES="$W/matches.tsv"
: > "$MATCHES"

# --- Q1: the executable header (template 14, derived) ----------------------
# The file's first line is a #!/usr/bin/env {bash,node,python3} shebang, or the
# file is a .ps1 carrying #Requires -Version 5.1. File-level nodes only: a
# collapsed directory artifact has no first line, so this mechanism does not reach
# one, and inventing a header for it would manufacture a P1 qualification.
if [ -s "$W/files.filelevel" ]; then
    tr '\n' '\0' < "$W/files.filelevel" | xargs -0 awk '
        function clean(s) { sub(/\r$/, "", s); gsub(/\t/, " ", s); return s }
        FNR == 1 && /^#!\/usr\/bin\/env (bash|node|python3)([[:space:]]|\r|$)/ {
            printf "%s\t14\t%s\t%s\t\n", FILENAME, clean($0), FILENAME
            done14[FILENAME] = 1
            next
        }
        FILENAME ~ /\.ps1$/ && !(FILENAME in done14) && /^#Requires -Version 5\.1/ {
            printf "%s\t14\t%s\t%s\t\n", FILENAME, clean($0), FILENAME
            done14[FILENAME] = 1
        }
    ' 2>/dev/null >> "$MATCHES" || true
fi

# --- Q2/Q3: convention membership (templates 11, 12, derived) --------------
# Each pattern is quoted from a rule the project actually states, and the rule's
# presence is checked rather than assumed: on a project whose module-map carries no
# such heading, the convention is not a convention and qualifies nothing (FR-8a).
MODULE_MAP="${KB_DIR}/module-map.md"
RUN_ALL="tests/run-all.sh"
TEST_GLOB='tests/canonical/test-*.sh'
HAS_SKILL_RULE=0; HAS_AGENT_RULE=0; HAS_SCRIPT_RULE=0; HAS_TEST_GLOB=0
if [ -f "$MODULE_MAP" ]; then
    if grep -qF 'Where a new skill goes'         "$MODULE_MAP"; then HAS_SKILL_RULE=1; fi
    if grep -qF 'Where a new agent goes'         "$MODULE_MAP"; then HAS_AGENT_RULE=1; fi
    if grep -qF 'Where a new helper script goes' "$MODULE_MAP"; then HAS_SCRIPT_RULE=1; fi
fi
if [ -f "$RUN_ALL" ]; then
    if grep -qF "$TEST_GLOB" "$RUN_ALL"; then HAS_TEST_GLOB=1; fi
fi

while IFS=$'\t' read -r dir marker; do
    [ -n "$dir" ] || continue
    if [ "$marker" = "skill" ] && [ "$HAS_SKILL_RULE" = "1" ]; then
        printf '%s\t11\tcanonical/skills/*/SKILL.md\t%s\tWhere a new skill goes\n' "$dir" "$MODULE_MAP" >> "$MATCHES"
    elif [ "$marker" = "agent" ] && [ "$HAS_AGENT_RULE" = "1" ]; then
        printf '%s\t11\tcanonical/agents/*/AGENT.md\t%s\tWhere a new agent goes\n' "$dir" "$MODULE_MAP" >> "$MATCHES"
    fi
done < "$W/convdir.tsv"

while IFS= read -r id; do
    [ -n "$id" ] || continue
    if [ "$HAS_SCRIPT_RULE" = "1" ]; then
        case "$id" in
            .codex/aid/scripts/*/*)
                printf '%s\t12\tcanonical/aid/scripts/<area>/*\t%s\tWhere a new helper script goes\n' \
                    "$id" "$MODULE_MAP" >> "$MATCHES" ;;
        esac
    fi
    if [ "$HAS_TEST_GLOB" = "1" ]; then
        case "$id" in
            tests/canonical/test-*.sh)
                # The declared carrier (the runner states the glob) and the derived
                # convention are the same fact with two provenances; both are Q3, and
                # declared-before-derived inside the clause decides which is emitted.
                printf '%s\t10\t%s\t%s\t\n'    "$id" "$TEST_GLOB" "$RUN_ALL" >> "$MATCHES"
                printf '%s\t12\t%s\t%s\t%s\n'  "$id" "$TEST_GLOB" "$RUN_ALL" "$TEST_GLOB" >> "$MATCHES" ;;
        esac
    fi
done < "$W/cand.ids"

# --- Q3: a KB document's frontmatter sources: entry (template 6, declared) --
# One of the two narrow KB reads this feature performs, and it reads a file rather
# than discovering one: it can only ADD a qualification to a path the walk already
# found, never withhold one, so FR-19's independence survives it.
: > "$W/kbsources.tsv"
if [ -d "$KB_DIR" ]; then
    find "$KB_DIR" -maxdepth 1 -type f -name '*.md' ! -name '.*' -print 2>/dev/null \
        | sort > "$W/kbdocs.txt"
    if [ -s "$W/kbdocs.txt" ]; then
        tr '\n' '\0' < "$W/kbdocs.txt" | xargs -0 awk '
            FNR == 1 { fm = 0; insources = 0 }
            FNR == 1 && /^---[[:space:]]*\r?$/ { fm = 1; next }
            fm == 0 { next }
            /^---[[:space:]]*\r?$/ { fm = 0; insources = 0; next }
            /^sources:[[:space:]]*\r?$/ { insources = 1; next }
            /^[A-Za-z_][A-Za-z0-9_]*:/ { insources = 0 }
            insources && /^[[:space:]]*-[[:space:]]*/ {
                entry = $0
                sub(/\r$/, "", entry)
                sub(/^[[:space:]]*-[[:space:]]*/, "", entry)
                gsub(/^["'\'']|["'\'']$/, "", entry)
                gsub(/\t/, " ", entry)
                sub(/[[:space:]]+$/, "", entry)
                if (entry != "" && entry != "(none)") printf "%s\t%s\n", FILENAME, entry
            }
        ' 2>/dev/null | sort -u > "$W/kbsources.tsv" || true
    fi
fi
if [ -s "$W/kbsources.tsv" ]; then
    awk -F'\t' -v OFS='\t' -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "	"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        {
            doc = $1; entry = $2
            if (entry in node) { print node[entry], 6, entry, doc, ""; next }
            # a trailing / is a directory prefix; a * makes it a glob
            if (entry ~ /\/$/) { pfx[entry] = doc; next }
            if (entry ~ /\*/)  { gl[entry] = doc;  next }
        }
        END {
            for (e in pfx) for (k in node) if (index(k, e) == 1) print node[k], 6, e, pfx[e], ""
            for (e in gl)  for (k in node) if (k ~ ("^" glob2re(e) "$")) print node[k], 6, e, gl[e], ""
        }
        function glob2re(g,   r, i, c) {
            r = ""
            for (i = 1; i <= length(g); i++) {
                c = substr(g, i, 1)
                if (c == "*") r = r ".*"
                else if (index(".^$+?()[]{}|\\", c) > 0) r = r "\\" c
                else r = r c
            }
            return r
        }
    ' "$W/kbsources.tsv" | sort -u >> "$MATCHES"
fi

# --- Q2: a shortcut-catalog row (template 3, declared) ---------------------
SHORTCUT_CATALOG=".codex/aid/templates/shortcut-catalog.yml"
if [ -f "$SHORTCUT_CATALOG" ]; then
    awk -F'\t' -v OFS='\t' -v CAT="$SHORTCUT_CATALOG" -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "	"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*-[[:space:]]*name:[[:space:]]*/ {
            v = $0
            sub(/\r$/, "", v)
            sub(/^[[:space:]]*-[[:space:]]*name:[[:space:]]*/, "", v)
            sub(/[[:space:]]*#.*$/, "", v)
            gsub(/^["'\'']|["'\'']$/, "", v)
            sub(/[[:space:]]+$/, "", v)
            if (v == "") next
            k = ".codex/skills/" v "/"
            if (k in node) print node[k], 3, v, CAT, ""
        }
    ' "$SHORTCUT_CATALOG" | sort -u >> "$MATCHES"
fi

# --- Q2: an EMISSION-MANIFEST "Asset Kinds" root (template 5, declared) ----
# A canonical asset root is what the renderer emits to a target project, so every
# surviving artifact under that root is a published surface. The cell is the token,
# never the whole row.
EMISSION_MANIFEST="canonical/EMISSION-MANIFEST.md"
if [ -f "$EMISSION_MANIFEST" ]; then
    awk -F'\t' -v OFS='\t' -v MAN="$EMISSION_MANIFEST" -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "	"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        /^##[[:space:]]/ { insec = ($0 ~ /^##[[:space:]]+Asset Kinds[[:space:]]*$/); next }
        !insec { next }
        /^\|[[:space:]]*`[^`]+`[[:space:]]*\|/ {
            cell = $0
            sub(/^\|[[:space:]]*`/, "", cell)
            sub(/`.*$/, "", cell)
            if (cell == "") next
            roots[cell] = 1
        }
        END {
            for (r in roots) for (k in node) if (index(k, r) == 1 && k != r) print node[k], 5, r, MAN, ""
        }
    ' "$EMISSION_MANIFEST" | sort -u >> "$MATCHES"
fi

# --- Q2: knowledge.doc_set's agent arm (template 4, declared) --------------
# Read through the resolver, never by hand-parsing settings.yml.
if [ -f "$SETTINGS_FILE" ] && [ -f "$RESOLVER" ]; then
    DOC_SET=$(bash "$RESOLVER" --path knowledge.doc_set --file "$SETTINGS_FILE" --default '' 2>/dev/null || true)
    if [ -n "$DOC_SET" ]; then
        _rest="$DOC_SET"
        while [ -n "$_rest" ]; do
            case "$_rest" in
                *,*) _item="${_rest%%,*}"; _rest="${_rest#*,}" ;;
                *)   _item="$_rest"; _rest="" ;;
            esac
            sig_token_into "$_item"
            _item="$SIG_TOKEN"
            case "$_item" in
                *\|*)
                    _agent="${_item#*|}"
                    _agent="${_agent%%|*}"
                    ;;
                *) _agent="" ;;
            esac
            [ -n "$_agent" ] || continue
            _dir=".codex/agents/${_agent}/"
            if grep -qxF "$_dir" "$W/cand.ids"; then
                printf '%s\t4\t%s\t%s\t\n' "$_dir" "$_agent" "$SETTINGS_FILE" >> "$MATCHES"
            fi
        done
    fi
fi

# --- Q1/Q2: the generated-files registry (templates 1, 2, declared) --------
GENERATED_FILES=".codex/aid/templates/generated-files.txt"
if [ -f "$GENERATED_FILES" ]; then
    awk -F'\t' -v OFS='\t' -v REG="$GENERATED_FILES" -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "	"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        {
            line = $0; sub(/\r$/, "", line)
            bar = index(line, "|")
            if (bar == 0) next
            out = substr(line, 1, bar - 1)
            cmd = substr(line, bar + 1)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", out)
            if (out != "" && (out in node)) print node[out], 2, out, REG, ""
            n = split(cmd, w, /[[:space:]]+/)
            for (i = 1; i <= n; i++) if (w[i] != "" && (w[i] in node)) print node[w[i]], 1, w[i], REG, ""
        }
    ' "$GENERATED_FILES" | sort -u >> "$MATCHES"
fi

# --- Q1: a workflow command token (template 7, declared) -------------------
# Scoped to the bytes of a step's command: a `run:` scalar and the block that
# follows it, so a path appearing in a `paths:` trigger filter is not read as an
# invocation.
grep -E '^\.github/workflows/' "$W/cand.ids" > "$W/workflows.txt" 2>/dev/null || true
if [ -s "$W/workflows.txt" ]; then
    tr '\n' '\0' < "$W/workflows.txt" | xargs -0 awk -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "\t"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        FNR == 1 { inrun = 0; runind = -1 }
        {
            line = $0; sub(/\r$/, "", line)
            ind = match(line, /[^ ]/) ? RSTART - 1 : 0
            isrun = (line ~ /^[[:space:]]*-?[[:space:]]*run:/)
            if (isrun) { inrun = 1; runind = ind }
            else if (inrun && line !~ /^[[:space:]]*$/ && ind <= runind) { inrun = 0 }
            if (!inrun) next
            n = split(line, w, /[^A-Za-z0-9._\/*-]+/)
            for (i = 1; i <= n; i++) {
                t = w[i]
                if (t == "") continue
                if (t in node) printf "%s\t7\t%s\t%s\t\n", node[t], t, FILENAME
            }
        }
    ' 2>/dev/null | sort -u >> "$MATCHES" || true
fi

# --- Q1/Q2: published entry points and payloads (templates 8, 9, declared) -
# The emitted token is the matched ENTRY's path-bearing side rather than its key:
# the key of a package.json bin map ("aid") occurs throughout the manifest, so it
# is not the durable anchor FR-24 asks for, while the value names the subject and
# is greppable in the file the evidence cites.
grep -E '(^|/)package\.json$' "$W/cand.ids" > "$W/manifests.json" 2>/dev/null || true
if [ -s "$W/manifests.json" ]; then
    tr '\n' '\0' < "$W/manifests.json" | xargs -0 awk -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "\t"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        FNR == 1 { dir = FILENAME; sub(/\/[^\/]*$/, "", dir); if (dir == FILENAME) dir = ""
                   inbin = 0; infiles = 0 }
        {
            line = $0; sub(/\r$/, "", line)
            if (line ~ /"bin"[[:space:]]*:[[:space:]]*\{/)   { inbin = 1;   next }
            if (line ~ /"files"[[:space:]]*:[[:space:]]*\[/) { infiles = 1; next }
            if (inbin   && line ~ /\}/) { inbin = 0;   next }
            if (infiles && line ~ /\]/) { infiles = 0; next }
            if (inbin) {
                if (match(line, /:[[:space:]]*"[^"]+"/)) {
                    v = substr(line, RSTART, RLENGTH)
                    sub(/^:[[:space:]]*"/, "", v); sub(/"$/, "", v)
                    emit(v, 8, dir, FILENAME)
                }
                next
            }
            if (infiles) {
                if (match(line, /"[^"]+"/)) {
                    v = substr(line, RSTART + 1, RLENGTH - 2)
                    emit(v, 9, dir, FILENAME)
                }
            }
        }
        function emit(v, tid, d, carrier,   full, k) {
            if (v == "") return
            full = (d == "" ? v : d "/" v)
            if (full in node) { printf "%s\t%d\t%s\t%s\t\n", node[full], tid, v, carrier; return }
            if (full ~ /\/$/) {
                for (k in node) if (index(k, full) == 1) printf "%s\t%d\t%s\t%s\t\n", node[k], tid, v, carrier
            }
        }
    ' 2>/dev/null | sort -u >> "$MATCHES" || true
fi

grep -E '(^|/)pyproject\.toml$' "$W/cand.ids" > "$W/manifests.toml" 2>/dev/null || true
if [ -s "$W/manifests.toml" ]; then
    tr '\n' '\0' < "$W/manifests.toml" | xargs -0 awk -v IDMAP="$W/idmap.src.tsv" '
        BEGIN {
            while ((getline l < IDMAP) > 0) { split(l, a, "\t"); node[a[1]] = a[2] }
            close(IDMAP)
        }
        FNR == 1 { dir = FILENAME; sub(/\/[^\/]*$/, "", dir); if (dir == FILENAME) dir = ""
                   inscripts = 0 }
        {
            line = $0; sub(/\r$/, "", line)
            if (line ~ /^\[/) { inscripts = (line ~ /^\[project\.scripts\]/); next }
            if (!inscripts) next
            if (!match(line, /=[[:space:]]*"[^"]+"/)) next
            v = substr(line, RSTART, RLENGTH)
            sub(/^=[[:space:]]*"/, "", v); sub(/"$/, "", v)
            mod = v; sub(/:.*$/, "", mod); gsub(/\./, "/", mod)
            full = (dir == "" ? mod ".py" : dir "/" mod ".py")
            if (full in node) printf "%s\t8\t%s\t%s\t\n", node[full], v, FILENAME
        }
    ' 2>/dev/null | sort -u >> "$MATCHES" || true
fi

sort -u "$MATCHES" -o "$MATCHES"

# --- evaluate the clauses, in clause order ---------------------------------
#
# Test Q1, then Q2, then Q3, and stop at the first clause any of whose carriers
# matched. That clause alone decides the qualifier: Q1 and Q2 are FINAL on match,
# since nothing outranks P1; Q3 is PROVISIONAL, because P2's clause is decidable
# only at step 9. Then, and only INSIDE the matched clause, declared carriers come
# before derived ones to pick the evidence/provenance pair. That ordering runs
# inside the matched clause only; it is never consulted across two clauses, and
# therefore never across a precedence level either. Where the chosen class holds
# more than one matching carrier, the emitted evidence is the LC_ALL=C-least of the
# admissible strings for that clause and class.
: > "$W/q0.tsv"

flush_node() {
    local node="$1" clause="" tid rest have_declared=0
    [ -n "$node" ] || return 0
    [ ${#ROWS[@]} -gt 0 ] || return 0
    for rest in "${ROWS[@]}"; do
        tid="${rest%%$'\t'*}"
        sig_template_clause_into "$tid" || exit 1
        sig_stronger_clause_into "$clause" "$SIG_CLAUSE" || exit 1
        clause="$SIG_CLAUSE"
    done
    for rest in "${ROWS[@]}"; do
        tid="${rest%%$'\t'*}"
        sig_template_clause_into "$tid" || exit 1
        [ "$SIG_CLAUSE" = "$clause" ] || continue
        sig_template_provenance_into "$tid" || exit 1
        if [ "$SIG_PROVENANCE" = "declared" ]; then have_declared=1; break; fi
    done
    local prov="derived"
    [ "$have_declared" -eq 1 ] && prov="declared"
    sig_evidence_candidates_into "$clause" "$prov" ROWS || exit 1
    sig_evidence_select_into || {
        echo "${SELF}: no admissible evidence for ${node} under ${clause}/${prov}" >&2
        exit 1
    }
    printf '%s\t%s\t%s\t%s\n' "$node" "$clause" "$SIG_EVIDENCE" "$prov" >> "$W/q0.tsv"
}

ROWS=()
cur=""
while IFS=$'\t' read -r node tid token carrier anchor; do
    [ -n "$node" ] || continue
    if [ "$node" != "$cur" ]; then
        flush_node "$cur"
        cur="$node"
        ROWS=()
    fi
    ROWS+=("${tid}"$'\t'"${node}"$'\t'"${token}"$'\t'"${carrier}"$'\t'"${anchor}")
done < "$MATCHES"
flush_node "$cur"
ROWS=()

# ---------------------------------------------------------------------------
# Step 9 - settle depended-upon (second pass).
#
# One tokenising pass builds the citation graph over every surviving candidate;
# the fixed point is then reachability from the step-8 qualified set within that
# graph, which is the same set the round-by-round iteration reaches and is
# independent of traversal order by construction. The rounds decide qualification
# only: evidence is assigned in ONE pass after the last round, over the completed
# observation stream, so field 5 never depends on the round a node qualified in.
# ---------------------------------------------------------------------------

cut -f1 "$W/nodemap.tsv" > "$W/scanfiles.txt"
: > "$W/scan.raw"
if [ -s "$W/scanfiles.txt" ]; then
    tr '\n' '\0' < "$W/scanfiles.txt" | xargs -0 awk \
        -v IDMAP="$W/idmap.all.tsv" -v BASEMAP="$W/basemap.tsv" \
        -v EXTKEYS="$W/ext.keys" -v IMGS="$W/img.paths" '
        BEGIN {
            while ((getline l < IDMAP) > 0)  { split(l, a, "\t"); node[a[1]] = a[2] }
            close(IDMAP)
            while ((getline l < BASEMAP) > 0){ split(l, a, "\t"); bcnt[a[1]] = a[2] + 0; bid[a[1]] = a[3] }
            close(BASEMAP)
            while ((getline l < EXTKEYS) > 0){ extkey[l] = 1 }
            close(EXTKEYS)
            while ((getline l < IMGS) > 0)   { isimg[l] = 1 }
            close(IMGS)
            manif["package.json"] = 1; manif["pyproject.toml"] = 1
            manif["generated-files.txt"] = 1; manif["shortcut-catalog.yml"] = 1
            manif["settings.yml"] = 1
        }
        function base(p,   b) { b = p; sub(/\/$/, "", b); sub(/^.*\//, "", b); return b }
        function hasext(p) { return (p ~ /\.[A-Za-z0-9]+$/) }
        function normalise(d, ref,   full, n, i, parts, out, m, r, trail) {
            trail = (ref ~ /\/$/) ? "/" : ""
            full = (d == "" ? ref : d "/" ref)
            n = split(full, parts, "/")
            m = 0
            for (i = 1; i <= n; i++) {
                if (parts[i] == "." || parts[i] == "") continue
                if (parts[i] == "..") { if (m == 0) return "!ESCAPE"; m--; continue }
                m++; out[m] = parts[i]
            }
            r = ""
            for (i = 1; i <= m; i++) r = (r == "" ? out[i] : r "/" out[i])
            return r trail
        }
        function kindof(target, matched, line, from,   fb) {
            if (isimg[target]) {
                if (index(line, "](" matched) > 0 || index(line, "src=\"" matched) > 0 ||
                    index(line, "src='\''" matched) > 0 || index(line, "href=\"" matched) > 0 ||
                    index(line, "href='\''" matched) > 0) return "image-reference"
            }
            if (index(line, "bash " matched) > 0 || index(line, "sh " matched) > 0 ||
                index(line, "source " matched) > 0 || index(line, ". " matched) > 0 ||
                index(line, "node " matched) > 0 || index(line, "python " matched) > 0 ||
                index(line, "python3 " matched) > 0 || index(line, "pwsh -File " matched) > 0 ||
                index(line, "powershell -File " matched) > 0 ||
                index(line, "Import-Module " matched) > 0) return "invocation"
            fb = base(from)
            if (fb in manif) return "dependency"
            if (from ~ /^profiles\/.*\.toml$/) return "dependency"
            if (from ~ /^canonical\/skills\// && target == ".codex/aid/templates/shortcut-engine.md")
                return "convention"
            return "path-reference"
        }
        FNR == 1 {
            citer = node[FILENAME]
            dir = FILENAME; sub(/\/[^\/]*$/, "", dir); if (dir == FILENAME) dir = ""
        }
        {
            line = $0; sub(/\r$/, "", line)
            # the include directive is a named edge, not a path token
            rest = line
            while (match(rest, /\{\{include:[A-Za-z0-9._-]+\}\}/)) {
                nm = substr(rest, RSTART + 11, RLENGTH - 13)
                tgt = ".codex/aid/templates/" nm ".md"
                if (tgt in node && node[tgt] != citer)
                    printf "E\t%s\t%s\tinclude\t%s\n", citer, node[tgt], "{{include:" nm "}}"
                rest = substr(rest, RSTART + RLENGTH)
            }
            n = split(line, w, /[^A-Za-z0-9._\/*-]+/)
            for (i = 1; i <= n; i++) {
                t = w[i]
                if (t == "" || length(t) < 2) continue
                if (t in extkey) {
                    if (citer != "ext:" t)
                        printf "E\t%s\text:%s\tpath-reference\t%s\n", citer, t, t
                    continue
                }
                # A site-absolute URL path is not a repository path, so it is never
                # guessed onto a framework convention directory (the D5 favicon case).
                # It is still worth RECORDING when it is path-shaped and names
                # something the tree holds; a bare /aid-execute is a slash command,
                # not a path, and recording it would pad the candidate stream with a
                # class no consumer can act on.
                if (substr(t, 1, 1) == "/") {
                    if (hasext(t) && (base(t) in bcnt))
                        printf "C\tedge\t%s\t%s\tunresolved-reference\n", citer, t
                    continue
                }
                dotted = (t ~ /^\.\.?\//)
                # a full repo-relative path that matches an enumerated node
                if (!dotted && (t in node)) {
                    if (node[t] != citer)
                        printf "E\t%s\t%s\t%s\t%s\n", citer, node[t], kindof(t, t, line, FILENAME), t
                    continue
                }
                # a RELATIVE reference - resolved against the directory of the citing
                # file, normalised, then matched as a full path. The rule keys on the
                # FORM of the reference, not on the language of the citing file, and a
                # bare images/x.png is as relative as ./images/x.png. Normalisation
                # happens before the id is formed, so no `..` reaches an int: id; a
                # reference normalising above the root is not resolved at all.
                nrm = normalise(dir, t)
                if (nrm == "!ESCAPE") { printf "C\tedge\t%s\t%s\toutside-repo-root\n", citer, t; continue }
                if (nrm != "" && (nrm in node)) {
                    if (node[nrm] != citer)
                        printf "E\t%s\t%s\t%s\t%s\n", citer, node[nrm], kindof(nrm, t, line, FILENAME), t
                    continue
                }
                if (dotted) {
                    if (hasext(t)) printf "C\tedge\t%s\t%s\tunresolved-reference\n", citer, t
                    continue
                }
                s = t
                while (1) {
                    if (s in node) {
                        if (node[s] != citer)
                            printf "E\t%s\t%s\t%s\t%s\n", citer, node[s], kindof(s, s, line, FILENAME), s
                        break
                    }
                    if (index(s, "/") == 0) {
                        if (s in bcnt) {
                            if (bcnt[s] == 1) {
                                if (bid[s] != citer)
                                    printf "E\t%s\t%s\t%s\t%s\n", citer, bid[s], kindof(bid[s], s, line, FILENAME), s
                            } else {
                                printf "C\tedge\t%s\t%s\tambiguous-basename\n", citer, s
                            }
                        }
                        break
                    }
                    s = substr(s, index(s, "/") + 1)
                }
            }
        }
    ' 2>/dev/null >> "$W/scan.raw" || true
fi

grep '^E' "$W/scan.raw" 2>/dev/null | cut -f2- | sort -u > "$W/edges.tsv" || : > "$W/edges.tsv"
grep '^C' "$W/scan.raw" 2>/dev/null | cut -f2- | sort -u > "$W/edgecands.tsv" || : > "$W/edgecands.tsv"

# The fixed point: reachability from the step-8 qualified set. A qualifier moves at
# most once and only in one direction (P3 -> P2), the qualified set only grows and
# is bounded by the candidate set, so the iteration terminates.
cut -f1 "$W/q0.tsv" | sort -u > "$W/q0.ids"
awk -F'\t' -v QF="$W/q0.ids" -v CANDS="$W/cand.ids" '
    BEGIN {
        while ((getline l < QF) > 0) q[l] = 1
        close(QF)
        while ((getline l < CANDS) > 0) cand[l] = 1
        close(CANDS)
    }
    { from[NR] = $1; to[NR] = $2; nrec = NR }
    END {
        changed = 1
        while (changed) {
            changed = 0
            for (i = 1; i <= nrec; i++)
                if ((from[i] in q) && !(to[i] in q) && (to[i] in cand)) { q[to[i]] = 1; changed = 1 }
        }
        for (k in q) print k
    }
' "$W/edges.tsv" | sort -u > "$W/qf.ids"

# observations.tsv carries the references of the nodes that are qualified at the
# fixed point, and nothing else.
awk -F'\t' -v QF="$W/qf.ids" '
    BEGIN { while ((getline l < QF) > 0) q[l] = 1; close(QF) }
    ($1 in q) { print }
' "$W/edges.tsv" | sort -u > "$W/obs.tsv"

awk -F'\t' -v QF="$W/qf.ids" '
    BEGIN { while ((getline l < QF) > 0) q[l] = 1; close(QF) }
    ($2 in q) { print }
' "$W/edgecands.tsv" | sort -u > "$W/edgecands.kept.tsv"

# ---------------------------------------------------------------------------
# Steps 10-12 - external nodes, the residue, and emission.
# ---------------------------------------------------------------------------

# Step 10: one media row per registered key. Under tier B every key is a web-page
# and no external image node is emitted, so the class is EMPTY rather than
# mis-populated - a wrong image kind is undetectable by any validator, so the
# conservative constant is the only assignment whose error mode is bounded.
WEB_PAGE_NODES=0
while IFS= read -r key; do
    [ -n "$key" ] || continue
    sig_render_external_evidence_into "$EXTERNAL_SOURCES_REL" "$key"
    emit_media_row "ext:${key}" "$key" "$SIG_KIND_WEB_PAGE" "$SIG_EVIDENCE" "declared"
    WEB_PAGE_NODES=$((WEB_PAGE_NODES + 1))
done < "$W/ext.keys"

# Step 9's evidence pass and step 11's finalisation, together: every node in the
# fixed point either kept its step-8 clause, was promoted P3 -> P2, or qualified
# under Q4 outright. Evidence for the last two is the LC_ALL=C-least template-13
# string over the node's inbound observations as they stand at the fixed point.
awk -F'\t' '{ print $2 "\t" $1 "\t" $4 }' "$W/obs.tsv" | sort -u > "$W/inbound.tsv"

NODE_ROWS="$W/node.rows"
: > "$NODE_ROWS"
SRC_NODES=0

# The single writer for nodes.tsv, carrying D3's four assertions at one choke point
# rather than as four scattered guards.
emit_node_row() {
    local id="$1" name="$2" cls="$3" qual="$4" ev="$5" prov="$6" kind="$7" row _p
    case "$prov" in
        declared|derived) ;;
        *) echo "${SELF}: refusing a node row with evidence_provenance '${prov}' (${id})" >&2; exit 1 ;;
    esac
    case "$id" in
        *\#*) echo "${SELF}: refusing an int: id carrying a fragment: ${id}" >&2; exit 1 ;;
    esac
    _p="${id#int:}"
    if sig_class2_excluded "$_p" || sig_class4_excluded "$_p"; then
        echo "${SELF}: refusing an excluded path as a node: ${_p}" >&2; exit 1
    fi
    if ! sig_class5_allowlisted "$_p" && sig_class1_excluded "$_p"; then
        echo "${SELF}: refusing an excluded path as a node: ${_p}" >&2; exit 1
    fi
    printf -v row '%s\t%s\t%s\t%s\t%s\t%s\t%s' "$id" "$name" "$cls" "$qual" "$ev" "$prov" "$kind"
    case "$row" in
        *$'\t'*$'\t'*$'\t'*$'\t'*$'\t'*$'\t'*$'\t'*)
            echo "${SELF}: refusing a node row containing a tab inside a field: ${id}" >&2; exit 1 ;;
    esac
    printf '%s\n' "$row" >> "$NODE_ROWS"
}

# q0 lookup, joined against the fixed point and the inbound stream in one awk so the
# per-node bash loop below does no searching of its own.
awk -F'\t' -v QF="$W/qf.ids" -v INB="$W/inbound.tsv" '
    BEGIN {
        while ((getline l < QF) > 0) qf[l] = 1
        close(QF)
        while ((getline l < INB) > 0) { split(l, a, "\t"); hasin[a[1]] = 1 }
        close(INB)
    }
    { clause[$1] = $2; ev[$1] = $3; prov[$1] = $4 }
    END {
        for (k in qf) {
            if (k in clause) {
                c = clause[k]
                # the one promotion: a provisional named-unit that receives an
                # inbound reference is P3 -> P2, with its evidence and provenance
                # replaced, because the emitted qualifier is the strongest
                # applicable clause
                if (c == "Q3" && (k in hasin)) print k "\tQ4\t\t"
                else print k "\t" c "\t" ev[k] "\t" prov[k]
            } else {
                print k "\tQ4\t\t"
            }
        }
    }
' "$W/q0.tsv" | sort > "$W/final.tsv"

# Template-13 evidence for every step-9 qualification, computed once over the
# completed observation stream. Because the set only grows across rounds, the least
# member can only fall, so this is the minimum over the whole run.
: > "$W/q4.evidence.tsv"
cur=""
SIG_CANDIDATES=()
while IFS=$'\t' read -r to from token; do
    [ -n "$to" ] || continue
    if [ "$to" != "$cur" ]; then
        if [ -n "$cur" ] && sig_evidence_select_into; then
            printf '%s\t%s\n' "$cur" "$SIG_EVIDENCE" >> "$W/q4.evidence.tsv"
        fi
        cur="$to"
        SIG_CANDIDATES=()
    fi
    sig_render_evidence_into 13 "$to" "$token" "$from" || exit 1
    SIG_CANDIDATES+=("$SIG_EVIDENCE")
done < "$W/inbound.tsv"
if [ -n "$cur" ] && sig_evidence_select_into; then
    printf '%s\t%s\n' "$cur" "$SIG_EVIDENCE" >> "$W/q4.evidence.tsv"
fi
sort -u "$W/q4.evidence.tsv" -o "$W/q4.evidence.tsv"

awk -F'\t' -v Q4EV="$W/q4.evidence.tsv" '
    BEGIN { while ((getline l < Q4EV) > 0) { split(l, a, "\t"); e[a[1]] = a[2] } close(Q4EV) }
    { if ($2 == "Q4" && $3 == "") print $1 "\t" $2 "\t" e[$1] "\tderived"; else print }
' "$W/final.tsv" > "$W/final.filled.tsv"

# Step 12: artifact_class is assigned HERE - a pure function of the node id,
# evaluated at emit rather than during qualification, so no path can reach the
# writer without a value for a required field.
while IFS=$'\t' read -r id clause ev prov; do
    [ -n "$id" ] || continue
    if [ -z "$ev" ]; then
        echo "${SELF}: no evidence resolved for ${id} (${clause})" >&2
        exit 1
    fi
    sig_clause_qualifier_into "$clause" || exit 1
    sig_artifact_class_into "$id"
    emit_node_row "int:${id}" "$id" "$SIG_ARTIFACT_CLASS" "$SIG_QUALIFIER" "$ev" "$prov" \
        "$SIG_KIND_SOURCE_ARTIFACT"
    SRC_NODES=$((SRC_NODES + 1))
done < "$W/final.filled.tsv"

# Step 11: the residue. Every still-unqualified source-artifact candidate becomes a
# candidates.tsv row. File existence alone never qualifies - this is where that
# requirement is actually enforced, and a DECLARED allowlist entry is subject to it
# like any other candidate: an allowlist re-admits, it does not grant nodehood.
comm -23 "$W/cand.ids" "$W/qf.ids" > "$W/dropped.ids"
DROPPED=$(wc -l < "$W/dropped.ids" | tr -d ' ')

{
    awk '{ printf "node\tint:%s\t\tno-rule-match\n", $0 }' "$W/dropped.ids"
    awk -F'\t' '{ printf "edge\t%s\tint:%s\t%s\n", $3, $2, $4 }' "$W/edgecands.kept.tsv"
} | sort -u > "$W/candidates.rows"

mkdir -p "$OUT_DIR" || { echo "${SELF}: cannot create ${OUT_DIR}" >&2; exit 1; }

write_stream() {
    local dest="$1" src="$2"
    if [ -s "$src" ]; then
        sort "$src" > "${dest}.tmp" && mv -f "${dest}.tmp" "$dest"
    else
        : > "$dest"
    fi
}

write_stream "${OUT_DIR}/nodes.tsv"        "$NODE_ROWS"
write_stream "${OUT_DIR}/media-nodes.tsv"  "$MEDIA_ROWS"

# Fields 1 and 2 carry full node ids; field 4 carries D3b's template 13 byte for
# byte, whose <subject> is the id minus its int: prefix and any other id verbatim.
# Step 9 draws a step-9-qualified node's evidence from THIS stream, so the
# observation string and the node string are the same bytes by construction.
: > "$W/obs.rows"
while IFS=$'\t' read -r from to kind token; do
    [ -n "$from" ] || continue
    sig_render_evidence_into 13 "$to" "$token" "$from" || exit 1
    case "$to" in
        ext:*) to_id="$to" ;;
        *)     to_id="int:${to}" ;;
    esac
    printf '%s\t%s\t%s\t%s\n' "int:${from}" "$to_id" "$kind" "$SIG_EVIDENCE" >> "$W/obs.rows"
done < "$W/obs.tsv"
write_stream "${OUT_DIR}/observations.tsv" "$W/obs.rows"
write_stream "${OUT_DIR}/candidates.tsv"   "$W/candidates.rows"

# The coverage contribution (D7), emitted in FIXED order - never sorted by a count,
# which would reorder the section whenever a count changed and break FR-32.
#
# `present` iff this project supplied at least one instance of the kind's CARRIER
# convention, which is a count the run already holds before it emits anything. The
# count stays the node count, so `present` with a count of 0 is legal and
# meaningful: the carrier was there and the rule that reads it qualified nothing.
# Only source-artifact can read that way, because only it has a rule that can
# reject its own input - and the dropped row below then shows the size of the cut.
status_of() { if [ "$1" -ge 1 ]; then printf '%s' "present"; else printf '%s' "absent"; fi; }

{
    sig_coverage_kind_note_into "$SIG_KIND_SOURCE_ARTIFACT"
    printf 'kind\t%s\t%s\t%s\t%s\n' "$SIG_KIND_SOURCE_ARTIFACT" "$(status_of "$SRC_CANDIDATES")" \
        "$SRC_NODES" "$SIG_NOTE"
    sig_coverage_kind_note_into "$SIG_KIND_IMAGE"
    printf 'kind\t%s\t%s\t%s\t%s\n' "$SIG_KIND_IMAGE" "$(status_of "$IMG_CARRIERS")" \
        "$IMAGE_NODES" "$SIG_NOTE"
    sig_coverage_kind_note_into "$SIG_KIND_WEB_PAGE"
    printf 'kind\t%s\t%s\t%s\t%s\n' "$SIG_KIND_WEB_PAGE" "$(status_of "$EXT_KEY_COUNT")" \
        "$WEB_PAGE_NODES" "$SIG_NOTE"
    printf 'kind\timage-external\tabsent\t0\texternal-sources entries carry no media type -- external image nodes cannot be distinguished from web pages (D-5)\n'
    printf 'kind\tsource-artifact-dropped\t--\t--\tpaths surviving exclusions that no significance clause qualified: %s\n' "$DROPPED"
    printf 'exclusion\tgenerated-trees\tyes\t--\tunconditional (FR-22)\n'
    printf 'exclusion\tvendored-code\tyes\t--\tunconditional (FR-22)\n'
    sig_ignore_applied_into "$IGNORE_STATE"
    sig_ignore_note_into "$IGNORE_STATE" "$IGNORE_COUNT" "$IGNORE_SPLIT"
    printf 'exclusion\tignore-list\t%s\t--\t%s\n' "$SIG_APPLIED" "$SIG_NOTE"
} > "${OUT_DIR}/coverage.tsv.tmp" && mv -f "${OUT_DIR}/coverage.tsv.tmp" "${OUT_DIR}/coverage.tsv"

OBS_ROWS=$(wc -l < "${OUT_DIR}/observations.tsv" | tr -d ' ')
CAND_ROWS=$(wc -l < "${OUT_DIR}/candidates.tsv" | tr -d ' ')

echo "[scan] ${SRC_NODES} source-artifact, ${IMAGE_NODES} image, ${WEB_PAGE_NODES} web-page nodes; ${OBS_ROWS} observations; ${CAND_ROWS} candidates; ${DROPPED} unqualified -> ${OUT_DIR}" >&2

exit 0
