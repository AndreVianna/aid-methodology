#!/usr/bin/env bash
# kb-write-fence.sh - turn /aid-graph's read-only claim into a checked post-condition.
#
# Purpose:
#   /aid-graph reads the Knowledge Base and writes exactly three paths inside it.
#   An allowlist alone cannot see a write that ignores it, so this script snapshots
#   the COMPLEMENT of that allowlist before the first write and re-walks the same set
#   at the end of the run. A file added, removed or changed anywhere in that
#   complement is a violation, named path by path.
#
#   Two properties are what make the check non-vacuous. The fenced set is the
#   complement, so kb.html, INDEX.md, STATE.md, every Knowledge Base document and
#   .cache/** are all inside it. And --verify FAILS CLOSED: with no snapshot on disk
#   it exits 2 rather than reporting a clean run, so a route that skipped --snapshot
#   cannot pass verification by having done nothing.
#
# Usage:
#   kb-write-fence.sh --snapshot [--kb-dir PATH] [--snapshot-file PATH]
#   kb-write-fence.sh --verify   [--kb-dir PATH] [--snapshot-file PATH]
#   kb-write-fence.sh --list-allowlist
#   kb-write-fence.sh -h | --help
#
# Modes (exactly one is required):
#   --snapshot        Walk the Knowledge Base directory recursively and record
#                     `<path>\t<sha256>` for every file NOT on the allowlist, sorted
#                     under LC_ALL=C. Paths are recorded relative to --kb-dir.
#   --verify          Re-walk the same set and diff it against the snapshot.
#   --list-allowlist  Print the allowlist, one pattern per line, relative to the
#                     Knowledge Base directory. A pattern ending in `/**` matches
#                     that directory and everything below it; every other pattern is
#                     an exact path. This is the single source of the pattern list:
#                     graph-stale-check.sh reads it rather than carrying a copy.
#
# Flags:
#   --kb-dir PATH        The Knowledge Base directory. Default: .aid/knowledge
#   --snapshot-file PATH Where the snapshot lives. Default: .aid/.temp/graph/kb-fence.txt
#
# Scope note:
#   The allowlist below is the part of the run's write allowlist that lies INSIDE the
#   Knowledge Base directory. The run's other writable paths -- its reviewer ledgers
#   and its scratch -- are outside that directory, so this walk never reaches them and
#   they need no pattern here.
#
# Output:
#   stdout: the fenced-file count on --snapshot; the verdict, every offending path and
#           the closing summary on --verify; the pattern list on --list-allowlist.
#   stderr: diagnostics, prefixed `kb-write-fence.sh: `.
#
# Exit codes:
#   0 - the snapshot was written, or verification found no change
#   1 - verification found at least one added, removed or changed path
#   2 - a usage error, an unreadable Knowledge Base directory, a missing snapshot on
#       --verify, or a fenced set that came out empty (which would make --verify
#       vacuous)

set -euo pipefail
export LC_ALL=C

SELF="kb-write-fence.sh"

KB_DIR=".aid/knowledge"
SNAPSHOT_FILE=".aid/.temp/graph/kb-fence.txt"
MODE=""

# The allowlist, once. `/**` means "this directory and everything below it".
ALLOWLIST=(
    "relationships.md"
    "graph.html"
    "graph-assets/**"
)

while [ $# -gt 0 ]; do
    case "$1" in
        --snapshot|--verify|--list-allowlist)
            if [ -n "$MODE" ]; then
                echo "${SELF}: ${1} conflicts with ${MODE}; pass exactly one mode" >&2
                exit 2
            fi
            MODE="$1"
            shift
            ;;
        --kb-dir)        KB_DIR="$2"; shift 2 ;;
        --snapshot-file) SNAPSHOT_FILE="$2"; shift 2 ;;
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

if [ -z "$MODE" ]; then
    echo "${SELF}: one of --snapshot, --verify or --list-allowlist is required" >&2
    exit 2
fi

if [ "$MODE" = "--list-allowlist" ]; then
    printf '%s\n' "${ALLOWLIST[@]}"
    exit 0
fi

# ---------------------------------------------------------------------------
# The hasher. sha256sum, shasum and openssl all print the digest as the first 64
# characters of their line, so the digest is taken by offset and the trailing
# path form -- which differs between platforms (`  path` against `*path`) -- is
# never parsed. Paths are zipped back by argument order, which every one of the
# three preserves.
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

hash_batch() {
    local -a paths=("$@")
    local i=0 line p
    if [ "$HASH_CMD" = "openssl-dgst" ]; then
        for p in "${paths[@]}"; do
            line=$(openssl dgst -sha256 -r "$p") || return 1
            printf '%s\t%s\n' "$p" "${line:0:64}"
        done
        return 0
    fi
    while IFS= read -r line; do
        printf '%s\t%s\n' "${paths[$i]}" "${line:0:64}"
        i=$((i + 1))
    done < <(
        # shellcheck disable=SC2086  # deliberate splitting: "shasum -a 256"
        $HASH_CMD "${paths[@]}"
    )
    [ "$i" -eq "${#paths[@]}" ]
}

# Reads newline-separated paths on stdin, prints `<path>\t<sha256>` in input order.
# Batched so a Knowledge Base of N files costs N/200 forks and not N -- forking is
# expensive on the Windows shells this project is authored on.
hash_paths() {
    local -a batch=()
    local p
    while IFS= read -r p; do
        [ -n "$p" ] || continue
        batch+=("$p")
        if [ "${#batch[@]}" -ge 200 ]; then
            hash_batch "${batch[@]}" || return 1
            batch=()
        fi
    done
    if [ "${#batch[@]}" -gt 0 ]; then
        hash_batch "${batch[@]}" || return 1
    fi
}

is_allowlisted() {
    local rel="$1" pattern dir
    for pattern in "${ALLOWLIST[@]}"; do
        case "$pattern" in
            */\*\*)
                dir="${pattern%/\*\*}"
                if [ "$rel" = "$dir" ]; then
                    return 0
                fi
                case "$rel" in
                    "$dir"/*) return 0 ;;
                esac
                ;;
            *)
                if [ "$rel" = "$pattern" ]; then
                    return 0
                fi
                ;;
        esac
    done
    return 1
}

KB_DIR="${KB_DIR%/}"
if [ ! -d "$KB_DIR" ]; then
    echo "${SELF}: Knowledge Base directory not found at ${KB_DIR}" >&2
    exit 2
fi

W=$(mktemp -d 2>/dev/null) || { echo "${SELF}: cannot create a scratch directory" >&2; exit 2; }
trap 'rm -rf "$W"' EXIT

# The walk: recursive, dotfiles included, paths made relative to KB_DIR, then
# filtered through the allowlist. One `find` and one hasher batch per 200 files.
: > "$W/candidates"
while IFS= read -r abs; do
    rel="${abs#"$KB_DIR"/}"
    is_allowlisted "$rel" && continue
    printf '%s\n' "$rel" >> "$W/candidates"
done < <(find "$KB_DIR" -type f | sort)

if [ ! -s "$W/candidates" ]; then
    echo "${SELF}: the fenced set is empty under ${KB_DIR}; verification would be vacuous" >&2
    exit 2
fi

( cd "$KB_DIR" && hash_paths ) < "$W/candidates" > "$W/current" || {
    echo "${SELF}: hashing failed under ${KB_DIR}" >&2
    exit 2
}
sort -o "$W/current" "$W/current"

FENCED=$(wc -l < "$W/current" | tr -d ' ')

if [ "$MODE" = "--snapshot" ]; then
    SNAP_DIR=$(dirname -- "$SNAPSHOT_FILE")
    mkdir -p "$SNAP_DIR" || { echo "${SELF}: cannot create ${SNAP_DIR}" >&2; exit 2; }
    cp -- "$W/current" "$SNAPSHOT_FILE"
    echo "🔒 Fence raised: ${FENCED} file(s) under ${KB_DIR} are read-only for this run."
    echo "   Snapshot: ${SNAPSHOT_FILE}"
    exit 0
fi

# --- --verify: fails closed ------------------------------------------------
if [ ! -f "$SNAPSHOT_FILE" ]; then
    echo "${SELF}: no fence snapshot at ${SNAPSHOT_FILE}; cannot verify" >&2
    echo "${SELF}: --verify fails closed by design -- a run that never snapshotted cannot pass verification" >&2
    exit 2
fi

awk -F'\t' '
    NR==FNR { old[$1] = $2; seen[$1] = 1; next }
    {
        if (!($1 in seen))        { print "added\t"   $1 }
        else if (old[$1] != $2)   { print "changed\t" $1 }
        current[$1] = 1
    }
    END { for (p in old) if (!(p in current)) print "removed\t" p }
' "$SNAPSHOT_FILE" "$W/current" | sort > "$W/violations"

if [ ! -s "$W/violations" ]; then
    echo "✅ Fence verified: ${FENCED} file(s) under ${KB_DIR} are unchanged."
    exit 0
fi

echo "❌ Fence violated: the run wrote outside its allowlist."
while IFS=$'\t' read -r what rel; do
    echo "   ${what}: ${KB_DIR}/${rel}"
done < "$W/violations"
echo ""
echo "   The Knowledge Base was modified outside ${SELF}'s allowlist, so this run's"
echo "   artifacts must not be trusted: /aid-graph is only sound as a read-only"
echo "   observer of the Knowledge Base. Restore the listed paths and re-run."
exit 1
