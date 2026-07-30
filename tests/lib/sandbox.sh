# sandbox.sh -- shared HOME-pin + .aid-subtree escape-canary for suites that
# need a throwaway HOME for the whole process (global-export isolation).
#
# Source it from a suite AFTER assert.sh -- sandbox_assert_aid_untouched calls
# assert.sh's pass/fail counters, so assert.sh must already be sourced:
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"    # first
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/sandbox.sh"   # after
#   TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
#   sandbox_pin_home                       # at setup, before any HOME-relative write
#   ... suite runs its cases ...
#   sandbox_assert_aid_untouched "<suite's existing canary label>"   # at the end
#
# Ordering: if the suite also resolves pwsh (pwsh.sh), call detect_pwsh
# BEFORE sandbox_pin_home (detect-before-pin invariant; see pwsh.sh).
#
# Why pin HOME for the whole process (not just per-invocation)?
#   bin/aid uses $HOME as the default scan root for sentinel-triggered scans.
#   Running a suite standalone (as tests/run-all.sh and CI do) without a HOME
#   pin can therefore scan the real $HOME and create stray .aid/dashboard/
#   dirs in unrelated repos on the machine (observed once:
#   <real-home>/projects/<repo>/.aid/dashboard/home.html). Exporting HOME to a
#   throwaway subdirectory before the suite runs means the WHOLE process and
#   every subprocess it spawns (aid, pwsh, harness scripts) inherits the
#   throwaway and can never reach the real HOME; SANDBOX_REAL_HOME is saved
#   first so the canary can prove it at the end.
#
# Windows twin: native (non-WSL) pwsh derives its automatic $HOME variable
# from $env:USERPROFILE (falling back to $env:HOMEDRIVE + $env:HOMEPATH), and
# NEVER from a bash-exported $HOME. bin/aid.ps1's user-tier registry path is
# `Join-Path $HOME '.aid'`, so leaving USERPROFILE untouched would let a
# pwsh-spawning suite's PS-side cases index/delete over the REAL developer
# registry on a native Windows run. sandbox_pin_home always pins
# USERPROFILE/HOMEDRIVE/HOMEPATH to the Windows-path form of the same
# throwaway dir (via cygpath) so bin/aid.ps1 resolves the sandbox too --
# harmless/no-op on Linux CI, where cygpath is absent (see
# reference_windows-pwsh-test-isolation).
#
# Provides:
#   sandbox_pin_home [FAKE_HOME]
#     Save the current $HOME into SANDBOX_REAL_HOME (once); export HOME to
#     FAKE_HOME (default "${TMP:?}/home") and mkdir -p it. When cygpath is
#     present (Windows/cygwin) also export USERPROFILE + HOMEDRIVE + HOMEPATH
#     to the Windows-path form of the same dir (no-op for those vars on Linux
#     CI). Auto-captures the .aid baseline into SANDBOX_AID_BEFORE.
#   sandbox_snapshot_aid [ROOT] [MAXDEPTH]
#     Print a deterministic, LC_ALL=C-sorted manifest of every ".aid"
#     occurrence under ROOT (default SANDBOX_REAL_HOME), bounded by MAXDEPTH
#     (default 6): both a ROOT-level ".aid" dir and any ".aid" dir nested
#     deeper in the tree (the escape-into-an-unrelated-repo case), one line
#     per entry:
#       <relpath>|<type>|<mtime>|<size>
#     <relpath> is relative to ROOT. Missing ROOT (or no ".aid" anywhere
#     under it) -> empty output. A SINGLE `find` invocation -- no
#     fork-in-loop (NFR-2).
#   sandbox_assert_aid_untouched LABEL [BEFORE]
#     Re-snapshot and compare to BEFORE (default SANDBOX_AID_BEFORE);
#     pass(LABEL) if byte-identical, else fail(LABEL -- <added/removed
#     summary>). Requires assert.sh to already be sourced (uses its
#     pass/fail).

# sandbox_pin_home [FAKE_HOME]
sandbox_pin_home() {
    local fake_home="${1:-${TMP:?}/home}"

    : "${SANDBOX_REAL_HOME:=$HOME}"

    export HOME="$fake_home"
    mkdir -p "$HOME"

    if command -v cygpath >/dev/null 2>&1; then
        local win_home
        win_home="$(cygpath -w "$HOME")"
        export USERPROFILE="$win_home"
        export HOMEDRIVE="${win_home:0:2}"
        export HOMEPATH="${win_home:2}"
    fi

    SANDBOX_AID_BEFORE="$(sandbox_snapshot_aid "$SANDBOX_REAL_HOME")"
}

# sandbox_snapshot_aid [ROOT] [MAXDEPTH]
sandbox_snapshot_aid() {
    local root="${1:-${SANDBOX_REAL_HOME:-$HOME}}"
    local maxdepth="${2:-6}"

    [[ -d "$root" ]] || return 0

    find "$root" -maxdepth "$maxdepth" \
        \( -path '*/.aid' -o -path '*/.aid/*' \) \
        -printf '%P|%y|%T@|%s\n' 2>/dev/null | LC_ALL=C sort
}

# sandbox_assert_aid_untouched LABEL [BEFORE]
sandbox_assert_aid_untouched() {
    local label="$1"
    local before="${2:-${SANDBOX_AID_BEFORE:-}}"
    local after
    after="$(sandbox_snapshot_aid "${SANDBOX_REAL_HOME:-$HOME}")"

    if [[ "$before" == "$after" ]]; then
        pass "$label"
        return 0
    fi

    local added removed
    added="$(LC_ALL=C comm -13 <(echo "$before") <(echo "$after"))"
    removed="$(LC_ALL=C comm -23 <(echo "$before") <(echo "$after"))"
    fail "$label -- .aid subtree changed under real HOME: added=[${added:-none}] removed=[${removed:-none}]"
}
