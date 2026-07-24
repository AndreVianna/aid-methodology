# pwsh.sh -- shared pwsh 7 detection for suites that spawn PowerShell.
#
# Source it from a suite (near the top, right after assert.sh, and BEFORE any
# HOME pin -- see the ordering invariant below):
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"
#   source "$(dirname "${BASH_SOURCE[0]}")/../lib/pwsh.sh"
#   PWSH="$(detect_pwsh || true)"
#   [[ -z "$PWSH" ]] && { echo "SKIP: pwsh not found on PATH -- skipping <suite>."; exit 0; }
#
# Provides:
#   detect_pwsh
#     Echo the resolved pwsh (7+) command/path to stdout and return 0 if
#     found; print nothing and return 1 if not. NEVER exits -- the caller
#     owns the SKIP decision and message.
#
# Ordering invariant (detect-before-pin):
#   _AID_REAL_HOME is captured ONCE, at SOURCE time, before this file (or the
#   caller) ever reassigns $HOME:
#       : "${_AID_REAL_HOME:=$HOME}"
#   This makes detect_pwsh's fallback resolution ORDER-INDEPENDENT of a later
#   sandbox_pin_home call (sandbox.sh) -- the user-local fallback still
#   resolves against the developer's real HOME even if detect_pwsh is
#   (mis-)invoked after a HOME pin. Belt-and-suspenders, the contract ALSO
#   mandates the call order in every consumer: resolve pwsh (detect_pwsh)
#   BEFORE pinning HOME (sandbox_pin_home) -- both mechanisms hold, neither
#   is a substitute for the other. If sandbox.sh is also sourced, its
#   SANDBOX_REAL_HOME captures the same value independently.

: "${_AID_REAL_HOME:=$HOME}"

# detect_pwsh
#   Resolution order (first hit wins):
#     1. $AID_PWSH override      -- if set and runnable (on PATH or -x), used verbatim
#     2. command -v pwsh         -- pwsh 7 on PATH (the CI + normal-dev case)
#     3. well-known fallbacks, probed with -x (anchored to _AID_REAL_HOME, NOT
#        the live $HOME, so a post-pin call still finds the real install):
#          "${_AID_REAL_HOME}/.local/pwsh/pwsh"   -- user-local install (real HOME)
#          /opt/microsoft/powershell/7/pwsh        -- MS tarball/rpm default
#          /usr/local/bin/pwsh                     -- common symlink target
#          /snap/bin/pwsh                          -- snap install
#          "${_AID_REAL_HOME}/.dotnet/tools/pwsh"  -- dotnet global tool (real HOME)
#   Intentionally does NOT fall back to Windows PowerShell 5.1 (`powershell`):
#   these suites assert the pwsh-7 cross-platform twin, so "pwsh 7 or SKIP"
#   behavior is preserved exactly (no silent runtime switch).
detect_pwsh() {
    if [[ -n "${AID_PWSH:-}" ]]; then
        if command -v "$AID_PWSH" >/dev/null 2>&1 || [[ -x "$AID_PWSH" ]]; then
            echo "$AID_PWSH"
            return 0
        fi
    fi

    if command -v pwsh >/dev/null 2>&1; then
        echo "pwsh"
        return 0
    fi

    local candidate
    for candidate in \
        "${_AID_REAL_HOME}/.local/pwsh/pwsh" \
        /opt/microsoft/powershell/7/pwsh \
        /usr/local/bin/pwsh \
        /snap/bin/pwsh \
        "${_AID_REAL_HOME}/.dotnet/tools/pwsh"
    do
        if [[ -x "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}
