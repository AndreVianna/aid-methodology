#!/usr/bin/env bash
# gap-register.sh -- the durable criteria-gap register.
#
# WHY THIS EXISTS
# A reviewer ledger lives under .aid/.temp/ and is deleted at skill DONE. So a gap recorded only in a
# ledger evaporates -- along with the user's answer to it. This writes the gap, and its answer, into a
# git-tracked STATE.md, which is what makes "a refusal is never re-asked" true across invocations
# rather than only within one.
#
# WHY SEPARATE FROM check-gaps.sh
# That one is a linter whose exit code IS its finding (0 clean / 1 gap). This is a state writer that
# must distinguish a bad argument from an unreadable file from a failed write. One exit-code alphabet
# cannot serve both without lying about one of them.
#
# USAGE
#   gap-register.sh --state PATH --promote --gap-key KEY --kind criteria|evidence \
#       --scope SCOPE --criterion TEXT [--status Pending|Answered|Declined|Superseded] \
#       [--depth 0|1|2] [--resolution TEXT]
#
#   gap-register.sh --state PATH --resolved-keys        # print keys that must NOT be re-asked
#   gap-register.sh --state PATH --open-keys           # print keys still Pending
#   gap-register.sh --state PATH --depth-of KEY        # print a key's recorded depth
#   gap-register.sh --state PATH --set-status --gap-key KEY --status STATUS [--resolution TEXT]
#
# IDEMPOTENCE, and the one rule that makes loop detection meaningful
#   --promote is idempotent on --gap-key. A repeat does NOT append a second row. Whether it
#   increments Recurrences depends on the existing row's Status:
#       still Pending           -> no increment. A slow human is not a loop.
#       Answered | Declined     -> increment. The gap came BACK after being resolved, which is the
#                                  only thing worth flagging.
#   That asymmetry is the whole point: without it, re-running a review while a gap sits Pending would
#   look identical to a genuine resolution loop.
#
# EXIT CODES (writer alphabet, aligned with writeback-state.sh)
#   0 success
#   1 state file unreadable, or its parent directory absent
#   2 lock contention -- a bug signal
#   3 write produced empty or unverifiable output; original preserved
#   4 invalid argument -- bad key, kind, status, or depth
#   5 missing required argument
#   7 --gap-key not found (for --set-status / --depth-of)
set -uo pipefail

SCRIPT_NAME="gap-register.sh"
SECTION="## Criteria Gaps"
HDR='| Gap Key | Kind | Status | Depth | Recurrences | Scope | Criterion | Resolution |'
SEP='|---|---|---|---|---|---|---|---|'
LOCK_TIMEOUT="${LOCK_TIMEOUT:-20}"

die() { echo "ERROR: ${SCRIPT_NAME}: $*" >&2; exit "${2:-1}"; }
usage() { sed -n '/^# USAGE/,/^set -uo/p' "$0" | sed 's/^# \{0,1\}//; $d'; }

STATE=""; MODE=""
GAP_KEY=""; KIND=""; STATUS=""; DEPTH=""; SCOPE=""; CRITERION=""; RESOLUTION=""; DEPTH_OF=""

set_mode() { [[ -z "$MODE" ]] || die "two modes given: --$MODE and --$1" 4; MODE="$1"; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --state)         STATE="${2:-}"; shift 2 ;;
        --promote)       set_mode promote; shift ;;
        --resolved-keys) set_mode resolved-keys; shift ;;
        --open-keys)     set_mode open-keys; shift ;;
        --set-status)    set_mode set-status; shift ;;
        --depth-of)      set_mode depth-of; DEPTH_OF="${2:-}"; shift 2 ;;
        --gap-key)       GAP_KEY="${2:-}"; shift 2 ;;
        --kind)          KIND="${2:-}"; shift 2 ;;
        --status)        STATUS="${2:-}"; shift 2 ;;
        --depth)         DEPTH="${2:-}"; shift 2 ;;
        --scope)         SCOPE="${2:-}"; shift 2 ;;
        --criterion)     CRITERION="${2:-}"; shift 2 ;;
        --resolution)    RESOLUTION="${2:-}"; shift 2 ;;
        -h|--help)       usage; exit 0 ;;
        *)               die "unknown argument: $1" 4 ;;
    esac
done

[[ -n "$STATE" ]] || die "--state is required" 5
[[ -n "$MODE" ]]  || die "one mode is required (--promote / --resolved-keys / --open-keys / --set-status / --depth-of)" 5

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
# The key must be content-derived and stable. A key carrying a row ID, cycle number, date or a
# movable path breaks dedupe -- and dedupe is what makes "never re-ask" and loop detection work, so a
# bad key silently disables both. Hence a hard reject rather than a warning.
KEY_RE='^[a-z0-9][a-z0-9./-]{2,63}$'

valid_status() { case "$1" in Pending|Answered|Declined|Superseded) return 0 ;; *) return 1 ;; esac; }
valid_kind()   { case "$1" in criteria|evidence) return 0 ;; *) return 1 ;; esac; }

check_key() {
    [[ -n "$1" ]] || die "--gap-key is required" 5
    [[ "$1" =~ $KEY_RE ]] || die "invalid --gap-key '$1'; expected ${KEY_RE} (lowercase, content-derived, no row ID / date / cycle number)" 4
    case "$1" in
        *[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]*) die "--gap-key '$1' looks like it contains a date; a key must be content-derived so it dedupes across invocations" 4 ;;
    esac
}

esc_pipe() { printf '%s' "${1//|/\\|}"; }
reject_newline() { [[ "$2" == *$'\n'* || "$2" == *$'\r'* ]] && die "--$1 contains a raw newline; not permitted" 4; return 0; }
nz() { [[ -n "$1" ]] && printf '%s' "$1" || printf '%s' '--'; }

# ---------------------------------------------------------------------------
# Lock -- same sentinel pattern as writeback-state.sh / writeback-ledger.sh.
# ---------------------------------------------------------------------------
LOCK_FILE=""; LOCK_ACQUIRED=0
init_lock_file() { LOCK_FILE="$(dirname "$1")/.gap-register.lock"; }
acquire_lock() {
    local parent; parent="$(dirname "$LOCK_FILE")"
    [[ -d "$parent" ]] || die "lock directory does not exist: $parent" 1
    local n=0
    while true; do
        if ( set -o noclobber; echo $$ > "$LOCK_FILE" ) 2>/dev/null; then LOCK_ACQUIRED=1; return 0; fi
        n=$((n + 1))
        [[ "$n" -ge "$LOCK_TIMEOUT" ]] && die "lock contention: $LOCK_FILE held after $n retries. This is a bug signal." 2
        sleep 0.5
    done
}
release_lock() { [[ "$LOCK_ACQUIRED" -eq 1 ]] && { rm -f "$LOCK_FILE"; LOCK_ACQUIRED=0; }; return 0; }
trap 'release_lock' EXIT

# ---------------------------------------------------------------------------
# CRLF / trailing-newline invariance, same guards as the ledger writer.
# ---------------------------------------------------------------------------
HAS_CRLF=0; HAD_TRAILING_NL=1
detect_eol() {
    HAS_CRLF=0; HAD_TRAILING_NL=1
    [[ -s "$STATE" ]] || return 0
    local first=""
    IFS= read -r first < "$STATE" 2>/dev/null || true
    [[ "$first" == *$'\r' ]] && HAS_CRLF=1
    [[ "$(tail -c1 "$STATE" | wc -l)" -eq 0 ]] && HAD_TRAILING_NL=0
    return 0
}
emit_transformed() {
    local prog="$1"; shift
    local out
    if [[ "$HAS_CRLF" -eq 1 ]]; then
        out="$(sed 's/\r$//' "$STATE" | awk "$@" "$prog" | sed 's/$/\r/'; printf 'X')"
    else
        out="$(awk "$@" "$prog" "$STATE"; printf 'X')"
    fi
    out="${out%X}"
    if [[ "$HAD_TRAILING_NL" -eq 0 ]]; then
        if [[ "$HAS_CRLF" -eq 1 ]]; then out="${out%$'\r\n'}"; else out="${out%$'\n'}"; fi
    fi
    printf '%s' "$out"
}

# ---------------------------------------------------------------------------
# Register access
# ---------------------------------------------------------------------------
require_state() {
    [[ -f "$STATE" ]] || die "state file does not exist: $STATE" 1
    [[ -r "$STATE" ]] || die "state file is not readable: $STATE" 1
}

has_section() { grep -qF "$SECTION" "$STATE" 2>/dev/null; }

# Existing STATE.md files predate this section, so the writer creates it rather than requiring a
# migration pass over every work folder in every adopter's repo.
ensure_section() {
    has_section && return 0
    detect_eol
    local tmp; tmp="$(mktemp)"
    # Append at end of file, preceded by a blank line.
    {
        cat "$STATE"
        printf '\n%s\n\n' "$SECTION"
        printf '<!-- AUTHORED by gap-register.sh, never by hand. Section created on first use.\n'
        printf '     Cell contracts: aid/templates/work-state-template.md %s -->\n\n' "$SECTION"
        printf '%s\n%s\n' "$HDR" "$SEP"
    } > "$tmp"
    [[ -s "$tmp" ]] || { rm -f "$tmp"; die "failed to create the $SECTION section" 3; }
    mv "$tmp" "$STATE" || { rm -f "$tmp"; die "could not write $STATE" 3; }
}

# Print a register row by key, or nothing.
find_gap() {
    local key="$1"
    awk -v want="$key" '
      index($0, "## Criteria Gaps") { inreg = 1; next }
      inreg && /^## / { inreg = 0 }
      inreg && /^\|/ {
        if ($0 ~ /^\|[ \t:|-]+\|$/) next
        n = split($0, c, "|")
        k = c[2]; gsub(/^[ \t]+|[ \t]+$/, "", k)
        if (k == want) { print; exit }
      }
    ' "$STATE"
}

cell_of() { printf '%s' "$1" | awk -F'|' -v i="$2" '{gsub(/^[ \t]+|[ \t]+$/,"",$i); print $i}'; }

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------
mode_promote() {
    check_key "$GAP_KEY"
    [[ -n "$KIND" ]] || die "--kind is required (criteria | evidence)" 5
    valid_kind "$KIND" || die "invalid --kind '$KIND'; expected criteria | evidence" 4
    [[ -n "$SCOPE" ]] || die "--scope is required" 5
    [[ -n "$CRITERION" ]] || die "--criterion is required" 5
    [[ -z "$STATUS" ]] && STATUS="Pending"
    valid_status "$STATUS" || die "invalid --status '$STATUS'" 4
    [[ -z "$DEPTH" ]] && DEPTH="0"
    case "$DEPTH" in 0|1|2) ;; *) die "invalid --depth '$DEPTH'; the chain is capped at 2 -- a deeper chain means the KB has a structural hole belonging to a full /aid-discover" 4 ;; esac
    reject_newline scope "$SCOPE"
    reject_newline criterion "$CRITERION"
    reject_newline resolution "$RESOLUTION"

    require_state
    init_lock_file "$STATE"; acquire_lock
    ensure_section

    local existing; existing="$(find_gap "$GAP_KEY")"

    if [[ -n "$existing" ]]; then
        local old_status old_recur new_recur
        old_status="$(cell_of "$existing" 4)"
        old_recur="$(cell_of "$existing" 6)"
        [[ "$old_recur" =~ ^[0-9]+$ ]] || old_recur=0

        # THE ASYMMETRY THAT MAKES LOOP DETECTION MEAN ANYTHING: only a gap that had been resolved
        # and came back counts as a recurrence. A gap still sitting Pending is a slow human.
        local keep_status="$STATUS"
        if [[ "$old_status" == "Answered" || "$old_status" == "Declined" || "$old_status" == "Superseded" ]]; then
            new_recur=$((old_recur + 1))
            # ...AND THE ANSWER STANDS. A recurrence must NOT reset the status to Pending: doing so
            # drops the key out of --resolved-keys, so the next batch re-asks a question the user has
            # already settled -- the single failure this register exists to prevent. The recurrence
            # count is the signal; the recorded answer is still the answer.
            #
            # Only an explicit terminal --status may change a terminal status (e.g. Declined ->
            # Superseded when a later decision overrides an earlier one).
            if [[ "$STATUS" == "Pending" ]]; then
                keep_status="$old_status"
            fi
        else
            new_recur="$old_recur"
        fi

        local tmp; tmp="$(mktemp)"
        detect_eol
        TARGET="$GAP_KEY" NEWSTATUS="$keep_status" NEWRECUR="$new_recur" NEWDEPTH="$DEPTH" \
        emit_transformed '
          function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
          index($0, "## Criteria Gaps") { inreg = 1; print; next }
          inreg && /^## / { inreg = 0 }
          inreg && /^\|/ && $0 !~ /^\|[ \t:|-]+\|$/ {
            n = split($0, c, "|")
            k = trim(c[2])
            if (k == ENVIRON["TARGET"]) {
              c[4] = " " ENVIRON["NEWSTATUS"] " "
              c[5] = " " ENVIRON["NEWDEPTH"] " "
              c[6] = " " ENVIRON["NEWRECUR"] " "
              out = ""
              for (i = 2; i <= n; i++) out = out "|" c[i]
              print out
              next
            }
          }
          { print }
        ' > "$tmp"
        [[ -s "$tmp" ]] || { rm -f "$tmp"; die "write produced empty output; original preserved" 3; }
        grep -qF "| $GAP_KEY |" "$tmp" || { rm -f "$tmp"; die "target key vanished from output; original preserved" 3; }
        mv "$tmp" "$STATE" || { rm -f "$tmp"; die "could not replace $STATE" 3; }

        if [[ "$new_recur" != "$old_recur" ]]; then
            echo "OK: ${STATE} -- gap '${GAP_KEY}' RECURRED after ${old_status} (recurrences=${new_recur}); the ${keep_status} answer STANDS and will not be re-asked"
        else
            echo "OK: ${STATE} -- gap '${GAP_KEY}' already registered, still ${old_status}; no recurrence counted (status=${keep_status})"
        fi
        return 0
    fi

    # New row.
    local row tmp
    row="| ${GAP_KEY} | ${KIND} | ${STATUS} | ${DEPTH} | 0 | $(esc_pipe "$SCOPE") | $(esc_pipe "$CRITERION") | $(nz "$(esc_pipe "$RESOLUTION")") |"
    tmp="$(mktemp)"
    detect_eol
    ROW="$row" emit_transformed '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      index($0, "## Criteria Gaps") { inreg = 1; print; next }
      inreg && /^## / {
        if (!done) { print ENVIRON["ROW"]; done = 1 }
        inreg = 0
      }
      inreg && /^\|/ {
        # drop the "_none yet_" placeholder the templates ship with
        if ($0 ~ /_none yet_/) next
        last = 1
      }
      { print }
      END { if (inreg && !done) print ENVIRON["ROW"] }
    ' > "$tmp"
    [[ -s "$tmp" ]] || { rm -f "$tmp"; die "write produced empty output; original preserved" 3; }
    grep -qF "| $GAP_KEY |" "$tmp" || { rm -f "$tmp"; die "the new row is absent from output; original preserved" 3; }
    mv "$tmp" "$STATE" || { rm -f "$tmp"; die "could not replace $STATE" 3; }
    echo "OK: ${STATE} -- registered gap '${GAP_KEY}' (${KIND}, ${STATUS}, depth ${DEPTH})"
}

mode_set_status() {
    check_key "$GAP_KEY"
    [[ -n "$STATUS" ]] || die "--status is required for --set-status" 5
    valid_status "$STATUS" || die "invalid --status '$STATUS'" 4
    require_state
    local existing; existing="$(find_gap "$GAP_KEY")"
    [[ -n "$existing" ]] || die "--gap-key '$GAP_KEY' not found in $STATE" 7

    init_lock_file "$STATE"; acquire_lock
    local tmp; tmp="$(mktemp)"
    detect_eol
    TARGET="$GAP_KEY" NEWSTATUS="$STATUS" NEWRES="$(esc_pipe "$RESOLUTION")" \
    emit_transformed '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      index($0, "## Criteria Gaps") { inreg = 1; print; next }
      inreg && /^## / { inreg = 0 }
      inreg && /^\|/ && $0 !~ /^\|[ \t:|-]+\|$/ {
        n = split($0, c, "|")
        if (trim(c[2]) == ENVIRON["TARGET"]) {
          c[4] = " " ENVIRON["NEWSTATUS"] " "
          if (ENVIRON["NEWRES"] != "") c[9] = " " ENVIRON["NEWRES"] " "
          out = ""
          for (i = 2; i <= n; i++) out = out "|" c[i]
          print out
          next
        }
      }
      { print }
    ' > "$tmp"
    [[ -s "$tmp" ]] || { rm -f "$tmp"; die "write produced empty output; original preserved" 3; }
    mv "$tmp" "$STATE" || { rm -f "$tmp"; die "could not replace $STATE" 3; }
    echo "OK: ${STATE} -- gap '${GAP_KEY}' status set to '${STATUS}'"
}

# The read side of "never re-ask". Answered, Declined and Superseded all mean the question has been
# settled -- Declined loudest of all, because a recorded "no" that gets re-asked is the exact failure
# this register exists to prevent.
list_keys() {
    local want="$1"
    require_state
    awk -v want="$want" '
      function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
      index($0, "## Criteria Gaps") { inreg = 1; next }
      inreg && /^## / { inreg = 0 }
      inreg && /^\|/ {
        if ($0 ~ /^\|[ \t:|-]+\|$/) next
        n = split($0, c, "|")
        k = trim(c[2]); st = trim(c[4])
        if (k == "" || k == "Gap Key" || k ~ /_none yet_/) next
        if (want == "resolved" && (st == "Answered" || st == "Declined" || st == "Superseded")) print k
        if (want == "open"     && st == "Pending") print k
      }
    ' "$STATE"
}

mode_depth_of() {
    [[ -n "$DEPTH_OF" ]] || die "--depth-of requires a key" 5
    require_state
    local row; row="$(find_gap "$DEPTH_OF")"
    [[ -n "$row" ]] || die "--gap-key '$DEPTH_OF' not found in $STATE" 7
    cell_of "$row" 5
}

case "$MODE" in
    promote)       mode_promote ;;
    set-status)    mode_set_status ;;
    resolved-keys) list_keys resolved ;;
    open-keys)     list_keys open ;;
    depth-of)      mode_depth_of ;;
    *)             die "unhandled mode: $MODE" 4 ;;
esac
