#!/usr/bin/env bash
# install.sh — AID installer bootstrap (Bash 4+).
#
# Purpose:
#   Install, update, or uninstall the AID (AI-Driven Development) methodology
#   files into a target repository.  Parses CLI flags, sources the shared install
#   core library (lib/aid-install-core.sh), then dispatches install/update/uninstall
#   across the five canonical tool layouts.  Designed for non-interactive use
#   (curl | bash, CI) — no /dev/tty prompts.
#
# Usage:
#   bash install.sh [--tool <name>[,<name>...]] [--version <v>] [--from-bundle <path>]
#                   [--force] [--verbose] [--target <dir>] [<target-dir>]
#       Install AID into the target directory (default: current directory).
#
#   bash install.sh --update [--tool <name>[,...]] [--version <v>] [--from-bundle <path>]
#                   [--force] [--verbose] [--target <dir>]
#       Re-install / update an existing AID installation to the given or latest version.
#
#   bash install.sh --uninstall [--tool <name>[,...]] [--verbose] [--target <dir>]
#       Remove AID-installed files (manifest-driven).
#
#   bash install.sh -h | --help
#       Print this help and exit 0.
#
# Flags:
#   --tool <name>[,...]    Host tool(s) to install.  Canonical ids: claude-code, codex,
#                          cursor, copilot-cli, antigravity.  Case-insensitive.  Comma-list
#                          installs multiple tools.  Omit to auto-detect from target dir.
#   --version <v>          Pin to a specific release version (e.g. 0.7.0 or v0.7.0).
#                          Mutually exclusive with --from-bundle.
#   --from-bundle <path>   Offline install from a pre-downloaded tarball (single --tool) or
#                          a directory of tarballs (comma-list).  No network.
#   --force                Overwrite files that exist and differ, including root agent files.
#   --verbose              Print per-file Copied:/Up to date:/Updated:/Removed: lines.
#                          Default: concise per-tool summary only.
#   --update               Re-install over an existing AID setup (refresh to version/latest).
#   --uninstall            Manifest-driven removal.  --tool limits to that tool; without it,
#                          removes all installed tools.
#   --target <dir>         Install root (default: current directory).  Also accepted as a
#                          trailing positional argument.
#   -h, --help             Print this help and exit 0.
#
# Exit codes:
#   0   success
#   1   generic runtime failure
#   2   usage error (unknown flag, bad args, ambiguous tool, missing target, etc.)
#   3   network / fetch failure
#   4   checksum verification failed
#   5   protect-on-diff blocked a root agent file (--force was not given)
#   6   uninstall with no manifest (nothing installed)

set -uo pipefail
# Note: -e (errexit) intentionally omitted — this script is designed for non-interactive
# piped execution (curl|bash, CI).  Error paths use explicit exit codes and the die()
# helper so that partial-success cases (exit 5 protect-on-diff) are correctly propagated.
# Adding -e would cause subshell exit codes (e.g. from _resolve_tools) to terminate the
# script silently rather than letting the caller inspect and act on them.
#
# Environment variables (installer options — take effect when the explicit flag is NOT given):
#   AID_TOOL       — equivalent to --tool <value>.  Accepts a comma-list.
#                    Useful for piped invocations: AID_TOOL=claude-code curl … | bash
#                    Precedence: explicit --tool flag > AID_TOOL > auto-detect.
#   AID_VERSION    — equivalent to --version <value>.
#                    Precedence: explicit --version flag > AID_VERSION > resolve latest.
#   AID_TARGET     — equivalent to --target <dir>.
#                    Precedence: explicit --target / positional arg > AID_TARGET > cwd.
#   AID_FORCE      — set to '1' or 'true' to enable --force.
#                    Precedence: explicit --force flag > AID_FORCE.
#   AID_VERBOSE    — set to '1' to enable --verbose (per-file output).
#                    Precedence: explicit --verbose flag > AID_VERBOSE.
#
# Environment variables (bootstrap/lib fetch — existing):
#   AID_LIB_PATH   — absolute path to aid-install-core.sh to source directly (overrides
#                    sibling detection and remote fetch; useful for tests and vendored use).
#   AID_LIB_BASE   — base URL prefix for the remote lib fetch when the lib is not beside
#                    the script (piped/curl|bash case).  Defaults to the raw GitHub raw URL
#                    for the resolved release tag.  Example for local test override:
#                      AID_LIB_BASE=http://localhost:8000/lib install.sh ...
#                    When AID_LIB_BASE is set, the lib is fetched as:
#                      ${AID_LIB_BASE}/aid-install-core.sh
#                    When AID_LIB_BASE is set, SHA256SUMS is fetched from the same base dir
#                    as SHA256SUMS (i.e. one directory up from lib/):
#                      <parent-of-AID_LIB_BASE>/SHA256SUMS
#                    or AID_SUMS_URL may be set to override the checksum URL directly.
#   AID_SUMS_URL   — override URL for SHA256SUMS used during lib checksum verification.
#                    Useful for tests.  When unset, derived from the release tag URL.
#   AID_LIB_VERSION — pin the lib fetch to a specific release version (avoids API call).
#   AID_INSECURE_SKIP_LIB_VERIFY — set to '1' to skip lib checksum verification for the
#                    remote-fetch path.  INSECURE — for restricted test environments only.
#                    Default is fail-closed: SHA256SUMS must be fetchable and the hash must
#                    match.  Do not set in production.
#
# Trust model: curl|bash trusts the GitHub repo at the resolved pinned tag (fail-closed:
#   SHA256SUMS must be fetchable and hash must match before the lib is sourced; exit 3 if
#   SHA256SUMS unreachable or entry missing; exit 4 on mismatch).  Offline --from-bundle
#   installs remain the recommended verify-before-install path for air-gapped and
#   high-security adopters.

# ---------------------------------------------------------------------------
# Locate repo root (the directory containing this script).
# When piped via stdin BASH_SOURCE[0] is unset or empty — guard with :-
# ---------------------------------------------------------------------------
_SCRIPT_SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$_SCRIPT_SELF" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$_SCRIPT_SELF")" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
LIB_DIR="${SCRIPT_DIR}/lib"

# ---------------------------------------------------------------------------
# Usage helper (prints the header block as plain text).
# Fix #11: when $0 is not a readable file (piped via curl|bash), print a
# concise stub so that --help and early error exits never emit
# "sed: can't read bash".  When $0 IS a readable file keep the sed path.
# ---------------------------------------------------------------------------
usage() {
    if [[ ! -r "$0" ]]; then
        # Piped execution — print a minimal stub mirroring install.ps1's Show-Usage stub.
        printf 'install.sh — AID installer bootstrap (Bash 4+).\n'
        printf '\n'
        printf 'Usage:\n'
        printf '  bash install.sh [--tool <name>[,...]] [--version <v>] [--from-bundle <path>]\n'
        printf '                  [--force] [--target <dir>] [<target-dir>]\n'
        printf '  bash install.sh --update  [...flags...]\n'
        printf '  bash install.sh --uninstall [--tool <name>[,...]] [--target <dir>]\n'
        printf '  bash install.sh -h | --help\n'
        printf '\n'
        printf 'Key flags:\n'
        printf '  --tool <name>[,...]  Tool id: claude-code, codex, cursor, copilot-cli, antigravity\n'
        printf '  --version <v>        Pin to release version (e.g. 0.7.0)\n'
        printf '  --from-bundle <path> Offline install from pre-downloaded tarball\n'
        printf '  --force              Overwrite differing files including root agent files\n'
        printf '  --verbose            Print per-file detail (default: concise summary)\n'
        printf '  --target <dir>       Install root (default: current directory)\n'
        printf '\n'
        printf 'Env vars: AID_TOOL, AID_VERSION, AID_TARGET, AID_FORCE, AID_VERBOSE\n'
        printf '  (equivalent to the flags; flags take precedence)\n'
        printf '\n'
        printf 'Exit codes: 0 success, 1 failure, 2 usage error, 3 network error,\n'
        printf '            4 checksum mismatch, 5 protect-on-diff blocked, 6 no manifest\n'
        printf '\n'
        printf 'Full docs: https://github.com/AndreVianna/aid-methodology/blob/master/docs/install.md\n'
    else
        sed -n '2,51p' "$0" | sed 's/^# \{0,1\}//'
    fi
}

# ---------------------------------------------------------------------------
# Error helper.
# ---------------------------------------------------------------------------
die() {
    echo "ERROR: install.sh: $1" >&2
    exit "${2:-1}"
}

# ---------------------------------------------------------------------------
# Cleanup helpers — defined BEFORE the EXIT trap (fix #13).
# ---------------------------------------------------------------------------
_AID_TMPLIB_DIR=""

_cleanup_tmplib() {
    if [[ -n "${_AID_TMPLIB_DIR:-}" && -d "${_AID_TMPLIB_DIR}" ]]; then
        rm -rf "${_AID_TMPLIB_DIR}"
    fi
}

# _cleanup_staging is defined later (after STAGING_BASE is declared), but the
# function definition itself must exist before the trap fires.  We pre-define
# a placeholder here; the real body is set below.
STAGING_BASE=""
_cleanup_staging() {
    if [[ -n "$STAGING_BASE" && -d "$STAGING_BASE" ]]; then
        rm -rf "$STAGING_BASE"
    fi
}

# Register the EXIT trap NOW — both cleanup functions are already defined.
trap '_cleanup_tmplib; _cleanup_staging' EXIT

# ---------------------------------------------------------------------------
# Source the shared install core.
# Resolution order (first match wins):
#   1. AID_LIB_PATH env var — absolute path to the lib file (test override or vendored).
#   2. Sibling lib/aid-install-core.sh — present when invoked as a local file.
#   3. Remote fetch (piped execution) — fix #12:
#      a. Resolve the release version (from --version flag or GitHub API latest).
#      b. Fetch the lib from the IMMUTABLE release tag raw URL (not master).
#      c. Fetch SHA256SUMS from the same release tag.
#      d. Verify the lib's sha256 against SHA256SUMS — exit 4 on mismatch.
#      e. Source the verified lib.
#      AID_LIB_BASE / AID_SUMS_URL env overrides allow hermetic tests without
#      any network access.
# ---------------------------------------------------------------------------

_source_install_core() {
    local lib_file

    # 1. Explicit override.
    if [[ -n "${AID_LIB_PATH:-}" ]]; then
        if [[ ! -f "$AID_LIB_PATH" ]]; then
            echo "ERROR: install.sh: AID_LIB_PATH set but file not found: ${AID_LIB_PATH}" >&2
            exit 1
        fi
        lib_file="$AID_LIB_PATH"
    # 2. Sibling lib.
    elif [[ -f "${LIB_DIR}/aid-install-core.sh" ]]; then
        lib_file="${LIB_DIR}/aid-install-core.sh"
    else
        # 3. Remote fetch with pinned tag + checksum verification (fix #12).
        _AID_TMPLIB_DIR="$(mktemp -d /tmp/aid-libfetch-XXXXXX)"
        lib_file="${_AID_TMPLIB_DIR}/aid-install-core.sh"

        # Determine the version to pin.  Resolution order:
        #   1. AID_LIB_VERSION env var (test/override: avoids API call without
        #      requiring --version which is mutually exclusive with --from-bundle).
        #   2. --version / -Version flag from $@ (quick scan without full parse).
        #   3. GitHub API latest (requires network).
        local _pin_ver="${AID_LIB_VERSION:-}"
        if [[ -n "$_pin_ver" ]]; then
            _pin_ver="${_pin_ver#v}"
        else
            local _scan_arg
            local _next_is_ver=0
            for _scan_arg in "$@"; do
                if [[ "$_next_is_ver" -eq 1 ]]; then
                    _pin_ver="${_scan_arg#v}"
                    break
                fi
                if [[ "$_scan_arg" == "--version" || "$_scan_arg" == "-Version" ]]; then
                    _next_is_ver=1
                fi
            done
        fi

        local _resolved_ver=""
        if [[ -n "$_pin_ver" ]]; then
            _resolved_ver="$_pin_ver"
        else
            # Resolve latest from GitHub API.
            local _api_url="https://api.github.com/repos/AndreVianna/aid-methodology/releases/latest"
            local _curl_args=(-fsSL)
            local _token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
            if [[ -n "$_token" ]]; then
                _curl_args+=(-H "Authorization: Bearer ${_token}")
            fi
            local _api_resp=""
            if command -v curl >/dev/null 2>&1; then
                _api_resp="$(curl "${_curl_args[@]}" "$_api_url" 2>/dev/null)" || true
            fi
            _resolved_ver="$(echo "$_api_resp" | grep '"tag_name"' | head -1 \
                | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
            _resolved_ver="${_resolved_ver#v}"
            if [[ -z "$_resolved_ver" ]]; then
                echo "ERROR: install.sh: failed to resolve latest release version from ${_api_url}" >&2
                exit 3
            fi
        fi

        # Build URLs.  AID_LIB_BASE overrides the lib base URL (for tests).
        # AID_SUMS_URL overrides the SHA256SUMS URL (for tests).
        local _default_lib_base="https://raw.githubusercontent.com/AndreVianna/aid-methodology/v${_resolved_ver}/lib"
        local _base_url="${AID_LIB_BASE:-${_default_lib_base}}"
        local _lib_url="${_base_url}/aid-install-core.sh"

        # SHA256SUMS sits at the release root (one dir up from lib/).
        # When AID_LIB_BASE is overridden (test), derive sums URL from its parent dir
        # unless AID_SUMS_URL is set directly.
        local _default_sums_url="https://github.com/AndreVianna/aid-methodology/releases/download/v${_resolved_ver}/SHA256SUMS"
        local _sums_url="${AID_SUMS_URL:-}"
        if [[ -z "$_sums_url" ]]; then
            if [[ -n "${AID_LIB_BASE:-}" ]]; then
                # Derive sums URL from parent directory of AID_LIB_BASE.
                local _parent_base
                _parent_base="${AID_LIB_BASE%/lib}"
                _parent_base="${_parent_base%/lib/}"
                _sums_url="${_parent_base}/SHA256SUMS"
            else
                _sums_url="$_default_sums_url"
            fi
        fi

        echo "Fetching install core from ${_lib_url} ..." >&2
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "$lib_file" "$_lib_url" || {
                echo "ERROR: install.sh: failed to fetch install core from ${_lib_url}" >&2
                exit 3
            }
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$lib_file" "$_lib_url" || {
                echo "ERROR: install.sh: failed to fetch install core from ${_lib_url}" >&2
                exit 3
            }
        else
            echo "ERROR: install.sh: neither curl nor wget found; cannot fetch install core" >&2
            exit 3
        fi

        # Verify checksum (fix #12, fix #14: fail-closed).
        # AID_INSECURE_SKIP_LIB_VERIFY=1 is an explicit opt-out — must be deliberately set.
        # Default: fail closed if SHA256SUMS is unreachable OR entry is missing OR hash mismatches.
        if [[ "${AID_INSECURE_SKIP_LIB_VERIFY:-0}" == "1" ]]; then
            echo "WARN: install.sh: AID_INSECURE_SKIP_LIB_VERIFY=1 set — skipping lib checksum verification (INSECURE)" >&2
        else
            local _sums_file="${_AID_TMPLIB_DIR}/SHA256SUMS"
            echo "Fetching SHA256SUMS from ${_sums_url} ..." >&2
            local _sums_ok=0
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL -o "$_sums_file" "$_sums_url" 2>/dev/null && _sums_ok=1 || _sums_ok=0
            elif command -v wget >/dev/null 2>&1; then
                wget -qO "$_sums_file" "$_sums_url" 2>/dev/null && _sums_ok=1 || _sums_ok=0
            fi

            if [[ "$_sums_ok" -ne 1 || ! -f "$_sums_file" ]]; then
                echo "ERROR: install.sh: could not fetch SHA256SUMS from ${_sums_url}; refusing to source unverified lib (fail-closed)" >&2
                echo "ERROR: install.sh: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)" >&2
                exit 3
            fi

            # Verify the lib's sha256 against the entry in SHA256SUMS.
            local _lib_sha=""
            if command -v sha256sum >/dev/null 2>&1; then
                _lib_sha="$(sha256sum "$lib_file" | awk '{print $1}')"
            elif command -v shasum >/dev/null 2>&1; then
                _lib_sha="$(shasum -a 256 "$lib_file" | awk '{print $1}')"
            fi
            if [[ -z "$_lib_sha" ]]; then
                echo "ERROR: install.sh: could not compute sha256 of fetched lib (no sha256sum/shasum); refusing to source unverified lib" >&2
                exit 3
            fi
            local _expected_sha
            _expected_sha="$(grep '[[:space:]]aid-install-core\.sh$' "$_sums_file" | awk '{print $1}')"
            if [[ -z "$_expected_sha" ]]; then
                echo "ERROR: install.sh: aid-install-core.sh not found in SHA256SUMS from ${_sums_url}; refusing to source unverified lib (fail-closed)" >&2
                echo "ERROR: install.sh: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)" >&2
                exit 3
            elif [[ "$_lib_sha" != "$_expected_sha" ]]; then
                echo "ERROR: install.sh: checksum mismatch for aid-install-core.sh: expected ${_expected_sha}, got ${_lib_sha}" >&2
                exit 4
            else
                echo "Checksum OK: aid-install-core.sh" >&2
            fi
        fi
    fi

    # shellcheck source=lib/aid-install-core.sh
    source "$lib_file"
}

# ---------------------------------------------------------------------------
# Early --help check (before lib source): print usage and exit immediately.
# This avoids attempting network resolution when the user only wants help.
# ---------------------------------------------------------------------------
for _early_arg in "$@"; do
    if [[ "$_early_arg" == "-h" || "$_early_arg" == "--help" ]]; then
        usage
        exit 0
    fi
    # Stop at '--' (end of flags).
    [[ "$_early_arg" == "--" ]] && break
done

_source_install_core "$@"

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------
MODE="install"         # install | update | uninstall
TOOL_ARG=""            # raw --tool value (comma-list or empty)
VERSION_ARG=""         # raw --version value (empty = latest)
FROM_BUNDLE=""         # path to tarball or directory (offline)
FORCE=0
TARGET=""
# AID_VERBOSE is exported so lib/aid-install-core.sh can read it.
# Initialize from env var; may be overridden by --verbose flag below.
AID_VERBOSE="${AID_VERBOSE:-0}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --update)
            MODE="update"
            shift
            ;;
        --uninstall)
            MODE="uninstall"
            shift
            ;;
        --tool)
            [[ $# -lt 2 ]] && die "--tool requires a value" 2
            TOOL_ARG="$2"
            shift 2
            ;;
        --version)
            [[ $# -lt 2 ]] && die "--version requires a value" 2
            VERSION_ARG="$2"
            shift 2
            ;;
        --from-bundle)
            [[ $# -lt 2 ]] && die "--from-bundle requires a value" 2
            FROM_BUNDLE="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --verbose)
            AID_VERBOSE=1
            shift
            ;;
        --target)
            [[ $# -lt 2 ]] && die "--target requires a value" 2
            TARGET="$2"
            shift 2
            ;;
        --)
            shift
            # Remaining args are positional.
            break
            ;;
        -*)
            die "unknown flag: $1" 2
            ;;
        *)
            # Trailing positional → target dir.
            if [[ -z "$TARGET" ]]; then
                TARGET="$1"
                shift
            else
                die "unexpected argument: $1 (target already set to '${TARGET}')" 2
            fi
            ;;
    esac
done

# Consume remaining positionals (after --).
while [[ $# -gt 0 ]]; do
    if [[ -z "$TARGET" ]]; then
        TARGET="$1"
        shift
    else
        die "unexpected argument: $1 (target already set to '${TARGET}')" 2
    fi
done

# ---------------------------------------------------------------------------
# Apply env-var fallbacks (AID_TOOL, AID_VERSION, AID_TARGET, AID_FORCE).
# Precedence: explicit flag/arg > env var > auto-detect/default.
# ---------------------------------------------------------------------------
if [[ -z "$TOOL_ARG" && -n "${AID_TOOL:-}" ]]; then
    TOOL_ARG="$AID_TOOL"
fi
if [[ -z "$VERSION_ARG" && -n "${AID_VERSION:-}" ]]; then
    VERSION_ARG="$AID_VERSION"
fi
if [[ -z "$TARGET" && -n "${AID_TARGET:-}" ]]; then
    TARGET="$AID_TARGET"
fi
if [[ "$FORCE" -eq 0 && ( "${AID_FORCE:-0}" == "1" || "${AID_FORCE:-0}" == "true" ) ]]; then
    FORCE=1
fi
export AID_VERBOSE

# ---------------------------------------------------------------------------
# Validation.
# ---------------------------------------------------------------------------

# --from-bundle and --version are mutually exclusive.
if [[ -n "$FROM_BUNDLE" && -n "$VERSION_ARG" ]]; then
    die "--from-bundle and --version are mutually exclusive" 2
fi

# Uninstall does not accept --from-bundle or --version.
if [[ "$MODE" == "uninstall" ]]; then
    if [[ -n "$FROM_BUNDLE" ]]; then
        die "--from-bundle is not valid with --uninstall" 2
    fi
    if [[ -n "$VERSION_ARG" ]]; then
        die "--version is not valid with --uninstall" 2
    fi
fi

# Target defaults to current directory.
TARGET="${TARGET:-.}"

# Resolve and validate target.
if [[ ! -d "$TARGET" ]]; then
    die "target directory does not exist: ${TARGET}" 2
fi
TARGET="$(cd "$TARGET" && pwd)"

# Strip leading 'v' from version.
VERSION_ARG="${VERSION_ARG#v}"

# ---------------------------------------------------------------------------
# Resolve tool list.
# ---------------------------------------------------------------------------
# _resolve_tools writes tool ids (one per line) to a temp file and sets
# _RESOLVE_TOOLS_RC to the exit code. This avoids the subshell problem.
_RESOLVE_TOOLS_RC=0
_resolve_tools() {
    local raw="$1" target_dir="$2" mode="$3" outfile="$4"

    if [[ -z "$raw" ]]; then
        if [[ "$mode" == "uninstall" ]]; then
            # No --tool for uninstall → all tools in manifest.
            local manifest="${target_dir}/.aid/.aid-manifest.json"
            if [[ ! -f "$manifest" ]]; then
                return 0
            fi
            if command -v python3 >/dev/null 2>&1; then
                python3 - "$manifest" >> "$outfile" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for t in data.get("tools", {}).keys():
        print(t)
except Exception:
    pass
PY
            else
                grep -o '"[a-z][a-zA-Z-]*"[[:space:]]*:[[:space:]]*{' "$manifest" | \
                    grep -v '"tools"' | sed 's/"//g' | sed 's/[[:space:]]*:[[:space:]]*{//' >> "$outfile"
            fi
            return 0
        fi
        # Auto-detect.
        local detected
        detected="$(detect_tool "$target_dir")"
        local _rc=$?
        if [[ "$_rc" -ne 0 ]]; then
            return "$_rc"
        fi
        echo "$detected" >> "$outfile"
        return 0
    fi

    # Split on comma.
    local -a raw_tools=()
    IFS=',' read -ra raw_tools <<< "$raw"
    for t in "${raw_tools[@]}"; do
        t="$(echo "$t" | tr -d '[:space:]')"
        local canonical
        canonical="$(normalize_tool "$t")"
        local _rc=$?
        if [[ "$_rc" -ne 0 ]]; then
            return "$_rc"
        fi
        echo "$canonical" >> "$outfile"
    done
    return 0
}

# ---------------------------------------------------------------------------
# Staging area management.
# ---------------------------------------------------------------------------
# Note: _cleanup_staging and _cleanup_tmplib are defined and the EXIT trap is
# registered earlier in the file (before _source_install_core) so that any
# exit between the function defs and here is still handled correctly (fix #13).

# get_tarball_for_tool <tool> <version> <from_bundle>
# Populates STAGING_DIR (per-tool extracted staging dir) and RESOLVED_VERSION.
STAGING_DIR=""
RESOLVED_VERSION=""

prepare_tool_staging() {
    local tool="$1" version="$2" from_bundle="$3"

    # Create the per-tool staging dir.
    local tool_staging
    tool_staging="$(mktemp -d "${STAGING_BASE}/staging-${tool}-XXXXXX")"

    if [[ -n "$from_bundle" ]]; then
        # Offline mode.
        local tarball="$from_bundle"
        if [[ -d "$from_bundle" ]]; then
            # Directory of tarballs.
            local fname="aid-${tool}-v"
            tarball="$(ls "${from_bundle}"/aid-${tool}-v*.tar.gz 2>/dev/null | head -1)"
            if [[ -z "$tarball" ]]; then
                die "no tarball found for tool '${tool}' in bundle directory: ${from_bundle}" 1
            fi
        fi
        if [[ ! -f "$tarball" ]]; then
            die "bundle file not found: ${tarball}" 1
        fi
        # Verify sibling SHA256SUMS if present.
        verify_bundle_checksum "$tarball" || exit $?
        # Extract version from filename: aid-<tool>-v<version>.tar.gz
        local tbase
        tbase="$(basename "$tarball")"
        RESOLVED_VERSION="$(echo "$tbase" | sed "s/aid-${tool}-v//" | sed 's/\.tar\.gz$//')"
        [[ -z "$RESOLVED_VERSION" ]] && RESOLVED_VERSION="${version:-unknown}"
        extract_tarball "$tarball" "$tool_staging" || exit $?
    else
        # Online mode.
        if [[ -z "$version" ]]; then
            RESOLVED_VERSION="$(resolve_version)" || exit $?
        else
            RESOLVED_VERSION="$version"
        fi
        local dl_dir
        dl_dir="$(mktemp -d "${STAGING_BASE}/download-${tool}-XXXXXX")"
        fetch_tarball "$tool" "$RESOLVED_VERSION" "$dl_dir" || exit $?
        local tarball="${dl_dir}/aid-${tool}-v${RESOLVED_VERSION}.tar.gz"
        extract_tarball "$tarball" "$tool_staging" || exit $?
    fi

    STAGING_DIR="$tool_staging"
}

# ---------------------------------------------------------------------------
# Main dispatch.
# ---------------------------------------------------------------------------

STAGING_BASE="$(mktemp -d /tmp/aid-install-XXXXXX)"

# Resolve tool list using a temp file to preserve exit code across the subshell boundary.
_TOOLS_FILE="$(mktemp "${STAGING_BASE}/tools.XXXXXX")"
_resolve_tools "$TOOL_ARG" "$TARGET" "$MODE" "$_TOOLS_FILE"
_RESOLVE_TOOLS_RC=$?
if [[ "$_RESOLVE_TOOLS_RC" -ne 0 ]]; then
    exit "$_RESOLVE_TOOLS_RC"
fi
mapfile -t TOOLS < "$_TOOLS_FILE"

if [[ "${#TOOLS[@]}" -eq 0 && "$MODE" == "uninstall" ]]; then
    die "uninstall: no manifest found at ${TARGET}/.aid/.aid-manifest.json (exit 6)" 6
fi

# Track overall blocked status for exit 5.
OVERALL_BLOCKED=0

case "$MODE" in
    install|update)
        for tool in "${TOOLS[@]}"; do
            echo ""
            prepare_tool_staging "$tool" "$VERSION_ARG" "$FROM_BUNDLE"
            echo "Installing ${tool} v${RESOLVED_VERSION} → ${TARGET}"
            install_tool "$STAGING_DIR" "$tool" "$TARGET" "$RESOLVED_VERSION" "$FORCE" || {
                _RC=$?
                if [[ "$_RC" -eq 5 ]]; then
                    OVERALL_BLOCKED=1
                else
                    exit "$_RC"
                fi
            }
        done

        echo ""
        if [[ "$OVERALL_BLOCKED" -eq 1 ]]; then
            echo "Install complete with warnings: one or more root agent files were not overwritten."
            echo "Review the *.aid-new file(s) and merge, or re-run with --force to overwrite."
            exit 5
        fi
        echo "Done. AID ${RESOLVED_VERSION:-} installed into: ${TARGET}"
        exit 0
        ;;

    uninstall)
        _MANIFEST="${TARGET}/.aid/.aid-manifest.json"
        manifest_exists "$_MANIFEST" || {
            echo "ERROR: install.sh: no manifest at ${TARGET}/.aid/.aid-manifest.json; nothing to uninstall" >&2
            exit 6
        }

        for tool in "${TOOLS[@]}"; do
            echo ""
            echo "Uninstalling ${tool} from ${TARGET}"
            uninstall_tool "$_MANIFEST" "$tool" "$TARGET" || {
                _RC=$?
                [[ "$_RC" -eq 6 ]] && exit 6
                exit "$_RC"
            }
        done

        echo ""
        echo "Uninstall complete."
        exit 0
        ;;
esac
