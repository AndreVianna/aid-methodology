#!/usr/bin/env bash
# graph-stale-check.sh - decide whether /aid-graph must regenerate, and say why.
#
# Purpose:
#   /aid-graph may write no Knowledge Base file outside its own artifacts, so it has
#   nowhere to stamp a last-run date; and a date could not see a source-tree change
#   in any case. Staleness is therefore CONTENT-ADDRESSED: this script recomputes one
#   digest component per staleness input, joins them into a single scalar, and
#   compares that scalar against the one the previous run left in
#   .aid/knowledge/relationships.md's own frontmatter. No new state file exists.
#
#   The composite is what decides the verdict. Its named parts are what let the run
#   say WHICH input changed instead of printing a bare verdict -- attribution a single
#   opaque hash cannot give without stored per-component state, and there is nowhere
#   durable to store any.
#
#   The six file sets are pairwise disjoint, which is what makes the changed-component
#   report true rather than approximate.
#
# Usage:
#   graph-stale-check.sh [--reset] [--install-root PATH] [--stream-dir PATH]
#   graph-stale-check.sh -h | --help
#
# Flags:
#   --reset              Discard the digest comparison, and nothing else: no artifact
#                        is deleted and no ledger is preserved. The verdict can then
#                        never be CURRENT.
#   --install-root PATH  The installed AID tree. Default: resolved from this script's
#                        own location, which holds for the canonical tree and for
#                        every rendered profile alike.
#   --stream-dir PATH    Where the enumeration wrote its streams. Default:
#                        .aid/.temp/graph
#
# The digest components, one per staleness input, in the inputs' own order:
#   kb     every .aid/knowledge/*.md at depth 1, minus every allowlisted path (read
#          from kb-write-fence.sh --list-allowlist, which is where the allowlist
#          lives) and minus external-sources.md, which `ext` counts once
#   src     every enumerated in-repo artifact: the node ids of nodes.tsv plus the
#          `int:`-prefixed ids of media-nodes.tsv. An `ext:` id has no repo path and
#          its content is `ext`. A directory artifact contributes one line per file
#          below it, because a directory has no bytes of its own and hashing only its
#          name would make an edit inside it invisible
#   ext     .aid/knowledge/external-sources.md, or the literal `absent`
#   cfg     .aid/settings.yml whole, or the literal `absent`
#   vocab   the installed core relation vocabulary, then the project extension at
#          .aid/graph/relation-vocabulary.yml or the literal `absent`
#   tool    BOTH forms: the installed version string from .aid/.aid-manifest.json's
#          `aid_version` (or `absent`), AND a digest over the installed files that can
#          change a byte of either artifact. A version string is a claim about the
#          installed bytes rather than a measurement of them, and it does not move
#          when an installed file is edited in place -- the normal condition on a
#          development branch -- so taking only the string would reintroduce the
#          silent staleness this input exists to close
#
#   Areas the `tool` digest covers: aid/scripts/graph/**, aid/templates/graph/**
#   (minus the two paths `vocab` covers), aid/templates/knowledge-graph/**, and the
#   reused files that assemble or are inlined into the page. Excluded by name: every
#   validator (each reads an artifact and writes none of it), this feature's own four
#   verdict scripts, scale-ceiling.yml (it decides a warning, not a byte), and the
#   endpoint-satisfiability report (it gates nothing and emits nothing into either
#   artifact). Every path is recorded relative to the install root, so relocating the
#   install does not read as a change.
#
#   Component values compose from `<path>\t<sha256>` lines sorted under LC_ALL=C,
#   which is what makes the scalar byte-stable across runs and platforms.
#
# Output (stdout):
#   the per-component values, the recomputed scalar on a `graph_inputs_digest:` line
#   for the emitter to carry, the stored scalar, the changed components, the expected
#   artifacts, and THE VERDICT AS THE LAST LINE -- one of FIRST_RUN, STALE, CURRENT.
#   No timestamp is printed anywhere, so two runs over unchanged inputs produce
#   byte-identical output.
#
# Exit codes:
#   0 - for EVERY verdict; the decision is informational, not a failure
#   1 - a required input could not be read
#   2 - a usage error

# A read-only analyser, so `-e` is dropped on this project's stated convention for
# that class. Every fallible step below is checked explicitly at its call site --
# a silently truncated component would be a wrong verdict, which is the one outcome
# this script must not produce.
set -uo pipefail
export LC_ALL=C

SELF="graph-stale-check.sh"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
INSTALL_ROOT=$(cd -- "${SCRIPT_DIR}/../../.." && pwd)
FENCE="${SCRIPT_DIR}/kb-write-fence.sh"

RESET=0
STREAM_DIR=""

while [ $# -gt 0 ]; do
    case "$1" in
        --reset)        RESET=1; shift ;;
        --install-root) INSTALL_ROOT="$2"; shift 2 ;;
        --stream-dir)   STREAM_DIR="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,/^[^#]/{ /^#/!d; s/^# \{0,1\}//; p }' "$0"
            exit 0
            ;;
        *)
            echo "${SELF}: unknown flag: $1" >&2
            exit 2
            ;;
    esac
done

die() {
    echo "${SELF}: $1" >&2
    exit 1
}

# Paths below are resolved against the repository root, which is where the ids in
# the enumerated streams are relative to. Preflight P7 guarantees a git work tree on
# a real run; without one the current directory is used and a notice says so.
if ROOT=$(git rev-parse --show-toplevel 2>/dev/null); then
    cd "$ROOT" || die "cannot enter the repository root at ${ROOT}"
else
    echo "${SELF}: notice: not inside a git work tree; resolving paths against $(pwd)" >&2
fi

KB_DIR=".aid/knowledge"
ARTIFACT="${KB_DIR}/relationships.md"
VIEW_ARTIFACT="${KB_DIR}/graph.html"
EXTERNAL_SOURCES="${KB_DIR}/external-sources.md"
SETTINGS=".aid/settings.yml"
MANIFEST=".aid/.aid-manifest.json"
PROJECT_VOCAB=".aid/graph/relation-vocabulary.yml"
CORE_VOCAB_REL="aid/templates/graph/relation-vocabulary.yml"
SKELETON_REL="aid/templates/knowledge-graph/graph-skeleton.html"
[ -n "$STREAM_DIR" ] || STREAM_DIR=".aid/.temp/graph"

W=$(mktemp -d 2>/dev/null) || die "cannot create a scratch directory"
trap 'rm -rf "$W"' EXIT

# ---------------------------------------------------------------------------
# The hasher. sha256sum, shasum and openssl all print the digest as the first 64
# characters of their line, so the digest is taken by offset and the trailing path
# form -- which differs between platforms -- is never parsed. Paths are zipped back
# by argument order, which every one of the three preserves.
# ---------------------------------------------------------------------------
HASH_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    HASH_CMD="shasum -a 256"
elif command -v openssl >/dev/null 2>&1; then
    HASH_CMD="openssl-dgst"
else
    echo "${SELF}: no sha256 tool found (looked for sha256sum, shasum, openssl)" >&2
    exit 2
fi

hash_one() {
    local line
    if [ "$HASH_CMD" = "openssl-dgst" ]; then
        line=$(openssl dgst -sha256 -r -- "$1") || return 1
    else
        # shellcheck disable=SC2086  # deliberate splitting: "shasum -a 256"
        line=$($HASH_CMD -- "$1") || return 1
    fi
    printf '%s' "${line:0:64}"
}

hash_batch() {
    local -a paths=("$@")
    local i=0 line p
    if [ "$HASH_CMD" = "openssl-dgst" ]; then
        for p in "${paths[@]}"; do
            line=$(openssl dgst -sha256 -r -- "$p") || return 1
            printf '%s\t%s\n' "$p" "${line:0:64}"
        done
        return 0
    fi
    while IFS= read -r line; do
        printf '%s\t%s\n' "${paths[$i]}" "${line:0:64}"
        i=$((i + 1))
    done < <(
        # shellcheck disable=SC2086  # deliberate splitting: "shasum -a 256"
        $HASH_CMD -- "${paths[@]}"
    )
    [ "$i" -eq "${#paths[@]}" ]
}

# Reads newline-separated paths on stdin (relative to $2 if given, else the current
# directory) and prints `<recorded-path>\t<sha256>` lines. $2 lets a component record
# install-root-relative paths while hashing the file where it actually is.
# Batched so N files cost N/200 forks and not N -- forking is expensive on the
# Windows shells this project is authored on.
hash_paths() {
    local base="${1:-}"
    local -a batch=()
    local p
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        batch+=("$p")
        if [ "${#batch[@]}" -ge 200 ]; then
            ( [ -z "$base" ] || cd "$base" || exit 1; hash_batch "${batch[@]}" ) || return 1
            batch=()
        fi
    done
    if [ "${#batch[@]}" -gt 0 ]; then
        ( [ -z "$base" ] || cd "$base" || exit 1; hash_batch "${batch[@]}" ) || return 1
    fi
}

# A component's value: sha256 over its sorted `<path>\t<sha256>` line stream.
component_of_stream() {
    local stream="$1"
    sort -o "$stream" "$stream" || return 1
    hash_one "$stream"
}

# ---------------------------------------------------------------------------
# kb -- input 1
# ---------------------------------------------------------------------------
if [ ! -d "$KB_DIR" ]; then
    die "${KB_DIR} does not exist"
fi

if [ ! -f "$FENCE" ]; then
    die "the write-allowlist source ${FENCE} is missing; the kb component cannot exclude the run's own output"
fi
if ! bash "$FENCE" --list-allowlist > "$W/allowlist" 2>"$W/allowlist.err"; then
    cat "$W/allowlist.err" >&2
    die "cannot read the write allowlist from ${FENCE}"
fi

# Only exact-path allowlist patterns can ever match a depth-1 *.md candidate: a
# `dir/**` pattern names something below depth 1, and graph.html is not *.md. So an
# -F -x -v filter over the pattern list is exactly right here, and the recursive
# glob semantics stay inside the fence, which is the one place that needs them.
: > "$W/kb.paths"
for f in "$KB_DIR"/*.md; do
    [ -f "$f" ] || continue
    printf '%s\n' "${f##*/}" >> "$W/kb.paths"
done
if [ -s "$W/kb.paths" ]; then
    grep -Fxv -f "$W/allowlist" "$W/kb.paths" > "$W/kb.kept" || : > "$W/kb.kept"
    grep -Fxv 'external-sources.md' "$W/kb.kept" > "$W/kb.final" || : > "$W/kb.final"
    sed "s|^|${KB_DIR}/|" "$W/kb.final" > "$W/kb.list"
else
    : > "$W/kb.list"
fi
sort -o "$W/kb.list" "$W/kb.list"
hash_paths < "$W/kb.list" > "$W/kb.stream" || die "cannot hash the Knowledge Base documents"
KB_C=$(component_of_stream "$W/kb.stream") || die "cannot compute the kb component"

# ---------------------------------------------------------------------------
# src -- input 2
# ---------------------------------------------------------------------------
NODES="${STREAM_DIR}/nodes.tsv"
MEDIA_NODES="${STREAM_DIR}/media-nodes.tsv"
for s in "$NODES" "$MEDIA_NODES"; do
    [ -f "$s" ] || die "the enumerated stream ${s} is missing; ENUMERATE must run before STALE-CHECK"
    [ -r "$s" ] || die "the enumerated stream ${s} is unreadable"
done

cut -f1 "$NODES" "$MEDIA_NODES" 2>/dev/null \
    | grep '^int:' \
    | sed 's|^int:||' \
    | sort -u > "$W/src.ids" || : > "$W/src.ids"

: > "$W/src.files"
: > "$W/src.absent"
while IFS= read -r p; do
    [ -n "$p" ] || continue
    if [ -f "$p" ]; then
        printf '%s\n' "$p" >> "$W/src.files"
    elif [ -d "$p" ]; then
        find "$p" -type f >> "$W/src.files" 2>/dev/null || true
    else
        printf '%s\tabsent\n' "$p" >> "$W/src.absent"
    fi
done < "$W/src.ids"

sort -u -o "$W/src.files" "$W/src.files"
hash_paths < "$W/src.files" > "$W/src.stream" || die "cannot hash the enumerated source artifacts"
cat "$W/src.absent" >> "$W/src.stream"
SRC_C=$(component_of_stream "$W/src.stream") || die "cannot compute the src component"

# ---------------------------------------------------------------------------
# ext -- input 3.  A missing registry is zero rows, not an error.
# ---------------------------------------------------------------------------
if [ -f "$EXTERNAL_SOURCES" ]; then
    EXT_C=$(hash_one "$EXTERNAL_SOURCES") || die "cannot hash ${EXTERNAL_SOURCES}"
else
    EXT_C="absent"
fi

# ---------------------------------------------------------------------------
# cfg -- input 4.  The whole file: the requirement names the file, and
# over-triggering costs one attributable run while under-triggering is silent
# staleness.
# ---------------------------------------------------------------------------
if [ -f "$SETTINGS" ]; then
    CFG_C=$(hash_one "$SETTINGS") || die "cannot hash ${SETTINGS}"
else
    CFG_C="absent"
fi

# ---------------------------------------------------------------------------
# vocab -- input 5: core and project extension.
# ---------------------------------------------------------------------------
CORE_VOCAB="${INSTALL_ROOT}/${CORE_VOCAB_REL}"
[ -f "$CORE_VOCAB" ] || die "the installed core relation vocabulary is missing at ${CORE_VOCAB}"
: > "$W/vocab.stream"
CORE_VOCAB_HASH=$(hash_one "$CORE_VOCAB") || die "cannot hash ${CORE_VOCAB}"
printf '%s\t%s\n' "$CORE_VOCAB_REL" "$CORE_VOCAB_HASH" >> "$W/vocab.stream"
if [ -f "$PROJECT_VOCAB" ]; then
    PROJECT_VOCAB_HASH=$(hash_one "$PROJECT_VOCAB") || die "cannot hash ${PROJECT_VOCAB}"
    printf '%s\t%s\n' "$PROJECT_VOCAB" "$PROJECT_VOCAB_HASH" >> "$W/vocab.stream"
else
    printf '%s\tabsent\n' "$PROJECT_VOCAB" >> "$W/vocab.stream"
fi
VOCAB_C=$(component_of_stream "$W/vocab.stream") || die "cannot compute the vocab component"

# ---------------------------------------------------------------------------
# tool -- input 6: the version string AND a digest of the installed files.
# ---------------------------------------------------------------------------
AID_VERSION="absent"
if [ -f "$MANIFEST" ]; then
    V=$(sed -n 's/.*"aid_version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$MANIFEST" | head -1)
    [ -z "$V" ] || AID_VERSION="$V"
fi

# Excluded by BASENAME. Each entry is excluded because it decides a verdict or a
# warning rather than a byte of either artifact.
TOOL_EXCLUDE=(
    "validate-relationships.sh"
    "validate-html-output.sh"
    "validate-visuals.mjs"
    "contrast-check.mjs"
    "grade.sh"
    "graph-preflight.sh"
    "graph-stale-check.sh"
    "kb-write-fence.sh"
    "grade-graph.sh"
    "scale-ceiling.yml"
    "report-endpoint-satisfiability.sh"
    "relation-vocabulary.yml"
)
printf '%s\n' "${TOOL_EXCLUDE[@]}" | sort > "$W/tool.exclude"

: > "$W/tool.candidates"
for area in "aid/scripts/graph" "aid/templates/graph" "aid/templates/knowledge-graph"; do
    if [ -d "${INSTALL_ROOT}/${area}" ]; then
        ( cd "$INSTALL_ROOT" && find "$area" -type f ) >> "$W/tool.candidates" 2>/dev/null || true
    fi
done
for reused in \
    "aid/scripts/summarize/assemble.sh" \
    "aid/templates/knowledge-summary/component-css.css" \
    "aid/templates/knowledge-summary/lightbox.js" \
    "aid/templates/knowledge-summary/design-tokens.md"
do
    [ -f "${INSTALL_ROOT}/${reused}" ] && printf '%s\n' "$reused" >> "$W/tool.candidates"
done

: > "$W/tool.list"
while IFS= read -r p; do
    [ -n "$p" ] || continue
    if grep -Fxq "${p##*/}" "$W/tool.exclude"; then
        continue
    fi
    printf '%s\n' "$p" >> "$W/tool.list"
done < "$W/tool.candidates"
sort -u -o "$W/tool.list" "$W/tool.list"

hash_paths "$INSTALL_ROOT" < "$W/tool.list" > "$W/tool.files" || die "cannot hash the installed graph area"
sort -o "$W/tool.files" "$W/tool.files"
TOOL_FILES_C=$(hash_one "$W/tool.files") || die "cannot compute the tool file digest"

: > "$W/tool.stream"
printf 'aid_version\t%s\n' "$AID_VERSION" >> "$W/tool.stream"
cat "$W/tool.files" >> "$W/tool.stream"
TOOL_C=$(component_of_stream "$W/tool.stream") || die "cannot compute the tool component"

# ---------------------------------------------------------------------------
# The composite, and the comparison.
# ---------------------------------------------------------------------------
DIGEST="kb=${KB_C},src=${SRC_C},ext=${EXT_C},cfg=${CFG_C},vocab=${VOCAB_C},tool=${TOOL_C}"

STORED=""
if [ -f "$ARTIFACT" ]; then
    STORED=$(awk '
        NR==1 && $0 !~ /^---[ \t]*$/ { exit }
        NR==1 { in_fm=1; next }
        in_fm && /^---[ \t]*$/ { exit }
        in_fm && /^graph_inputs_digest:/ {
            sub(/^graph_inputs_digest:[ \t]*/, "")
            gsub(/^["\047]|["\047]$/, "")
            sub(/[ \t]+$/, "")
            print
            exit
        }
    ' "$ARTIFACT")
fi

# view_expected -- one decidable fact, and the same fact grade-graph.sh reads for its
# view rubric rows: the view is in scope for a run iff the skeleton is installed.
VIEW_EXPECTED=0
[ -f "${INSTALL_ROOT}/${SKELETON_REL}" ] && VIEW_EXPECTED=1

echo "[stale-check] component values:"
echo "  kb    = ${KB_C}"
echo "  src   = ${SRC_C}"
echo "  ext   = ${EXT_C}"
echo "  cfg   = ${CFG_C}"
echo "  vocab = ${VOCAB_C}"
echo "  tool  = ${TOOL_C}"
echo "  tool arms: aid_version=${AID_VERSION} installed-files=${TOOL_FILES_C}"
echo "graph_inputs_digest: ${DIGEST}"

if [ -n "$STORED" ]; then
    echo "[stale-check] stored digest:    ${STORED}"
else
    echo "[stale-check] stored digest:    none"
fi

# Missing expected artifacts.
MISSING=""
[ -f "$ARTIFACT" ] || MISSING="${MISSING} ${ARTIFACT}"
if [ "$VIEW_EXPECTED" -eq 1 ]; then
    echo "[stale-check] expected artifacts: ${ARTIFACT}, ${VIEW_ARTIFACT} (the view is installed)"
    [ -f "$VIEW_ARTIFACT" ] || MISSING="${MISSING} ${VIEW_ARTIFACT}"
else
    echo "[stale-check] expected artifacts: ${ARTIFACT} (the view templates are not installed)"
fi

# Changed components, named one per input. Reported whenever a stored scalar exists,
# so a STALE verdict is always attributable.
report_changes() {
    local name new old changed=""
    for name in kb src ext cfg vocab tool; do
        case "$name" in
            kb)    new="$KB_C" ;;
            src)   new="$SRC_C" ;;
            ext)   new="$EXT_C" ;;
            cfg)   new="$CFG_C" ;;
            vocab) new="$VOCAB_C" ;;
            tool)  new="$TOOL_C" ;;
        esac
        old=$(printf '%s' "$STORED" | tr ',' '\n' | sed -n "s/^${name}=//p" | head -1)
        if [ -z "$old" ]; then
            changed="${changed} ${name}(new)"
        elif [ "$old" != "$new" ]; then
            changed="${changed} ${name}"
        fi
    done
    if [ -n "$changed" ]; then
        echo "[stale-check] changed components:${changed}"
        case "$changed" in
            *tool*)
                echo "               the tool component covers both of its arms; the two values printed"
                echo "               above are what name an upgrade against an in-place edit"
                ;;
        esac
    else
        echo "[stale-check] changed components: none"
    fi
}

if [ "$RESET" -eq 1 ]; then
    echo "[stale-check] --reset: the digest comparison is discarded (no artifact deleted, no ledger preserved)."
    [ -z "$STORED" ] || report_changes
    if [ -z "$STORED" ]; then
        echo "FIRST_RUN"
    else
        echo "STALE"
    fi
    exit 0
fi

if [ -z "$STORED" ]; then
    if [ -f "$ARTIFACT" ]; then
        echo "[stale-check] ${ARTIFACT} carries no graph_inputs_digest scalar."
    else
        echo "[stale-check] ${ARTIFACT} does not exist."
    fi
    echo "FIRST_RUN"
    exit 0
fi

report_changes

if [ -n "$MISSING" ]; then
    echo "[stale-check] missing expected artifact(s):${MISSING}"
    echo "STALE"
    exit 0
fi

if [ "$STORED" != "$DIGEST" ]; then
    echo "STALE"
    exit 0
fi

echo "[stale-check] every component is unchanged and every expected artifact is present."
echo "CURRENT"
exit 0
