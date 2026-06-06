#!/usr/bin/env bash
# install.sh - AID installer bootstrap (Bash 4+).
#
# Purpose:
#   Bootstrap / install the persistent global `aid` CLI and (optionally) add
#   an AID profile to the current project in a single command.  Also retains
#   the legacy flag-style direct-install path for one release.
#
# Usage (new - preferred):
#   bash install.sh
#       Install the global aid CLI into $AID_HOME (~/.aid by default) and wire
#       PATH.  No project install - run 'aid add <tool>' afterwards.
#
#   bash install.sh <subcommand> [args]
#       Bootstrap the CLI (if not already installed), then immediately run
#       'aid <subcommand> [args]' in the current directory.
#       Subcommands: status add remove update version help
#       Examples:
#         bash install.sh add codex --from-bundle ./aid-codex-v0.7.0.tar.gz
#         bash install.sh status
#
#   bash install.sh --uninstall-cli [--force]
#       Remove the global aid CLI (PATH wiring + $AID_HOME).  Fallback for
#       when 'aid' is not yet on PATH.
#
# Usage (legacy - back-compat, hidden, retained for one release):
#   bash install.sh [--tool <name>[,...]] [--version <v>] [--from-bundle <path>]
#                   [--force] [--verbose] [--target <dir>] [<target-dir>]
#       Direct project install (no global CLI install).  Identical to the
#       pre-CLI-evolution behavior.  Triggers when --tool is given or when
#       the first non-flag argument is NOT a known subcommand.
#
#   bash install.sh --update [...]
#   bash install.sh --uninstall [...]
#       Legacy update/uninstall modes (flag style).
#
#   bash install.sh -h | --help
#       Print this help and exit 0.
#
# Environment variables:
#   AID_HOME           Override global install dir (default: ~/.aid).
#   AID_TOOL           Equivalent to --tool (legacy) or tool arg for 'add'.
#   AID_VERSION        Equivalent to --version.
#   AID_TARGET         Equivalent to --target.
#   AID_FORCE          Set '1'/'true' to enable --force.
#   AID_VERBOSE        Set '1' to enable per-file output.
#   AID_NO_PATH        Set '1' to skip PATH wiring (new bootstrap mode).
#   AID_LIB_PATH       Absolute path to aid-install-core.sh (test/override).
#   AID_LIB_BASE       Base URL for remote lib fetch.
#   AID_SUMS_URL       Override URL for SHA256SUMS verification.
#   AID_LIB_VERSION    Pin the remote lib fetch to a specific release version.
#   AID_INSECURE_SKIP_LIB_VERIFY  Set '1' to bypass lib checksum (INSECURE).
#   AID_CLI_BUNDLE_URL Direct URL for the CLI bundle tarball (test/override).
#   AID_CLI_BUNDLE_BASE Base URL for CLI bundle fetch (default: release download base).
#
# Exit codes:
#   0   success
#   1   generic runtime failure
#   2   usage error
#   3   network / fetch failure
#   4   checksum verification failed
#   5   protect-on-diff blocked (--force not given)
#   6   uninstall with no manifest
#   7   aid status: no AID install in cwd

set -uo pipefail
# Note: -e (errexit) intentionally omitted - error paths use explicit exit codes.

# ---------------------------------------------------------------------------
# Locate script dir (used in sibling-lib detection).
# ---------------------------------------------------------------------------
_SCRIPT_SELF="${BASH_SOURCE[0]:-}"
if [[ -n "$_SCRIPT_SELF" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$_SCRIPT_SELF")" && pwd)"
else
    SCRIPT_DIR="$(pwd)"
fi
LIB_DIR="${SCRIPT_DIR}/lib"

# ---------------------------------------------------------------------------
# Known subcommands (for disambiguation).
# ---------------------------------------------------------------------------
_KNOWN_SUBCMDS="status add remove update version help"

_is_known_subcmd() {
    local w="$1"
    case "$w" in
        status|add|remove|update|version|help) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Detect the install.sh invocation mode.
#
# Modes (mutually exclusive, detected from $@):
#   BOOTSTRAP  - no args (or only bootstrap flags: --version, --no-path, --from-bundle)
#   CONVENIENCE - first non-flag arg is a known subcommand
#   UNINSTALL_CLI - --uninstall-cli flag present
#   LEGACY     - --tool / --update / --uninstall flags (or first positional is not a subcmd)
# ---------------------------------------------------------------------------
_INSTALL_MODE="BOOTSTRAP"  # default

# Peek at arguments to determine mode before full parse.
# Disambiguation rules (in priority order):
#   1. --uninstall-cli            -> UNINSTALL_CLI
#   2. --tool / --update / --uninstall flags  -> LEGACY
#   3. --from-bundle or --target (without a subcommand) -> LEGACY (project-install flags)
#   4. First non-flag = known subcommand  -> CONVENIENCE
#   5. First non-flag = unknown word      -> LEGACY (unknown positional arg)
#   6. No args / only bootstrap flags     -> BOOTSTRAP
_peek_first_nonopt=""
_peek_has_tool=0
_peek_has_update=0
_peek_has_uninstall=0
_peek_has_uninstall_cli=0
_peek_has_legacy_project_flag=0  # --from-bundle or --target seen (before any subcommand)
_peek_found_subcommand=0
_peek_next_skip=0

for _peek_arg in "$@"; do
    if [[ "$_peek_next_skip" -eq 1 ]]; then
        _peek_next_skip=0
        continue
    fi
    case "$_peek_arg" in
        --tool)
            _peek_has_tool=1
            _peek_next_skip=1
            ;;
        --from-bundle|--target)
            # These are project-install flags; mark LEGACY (unless a subcommand was seen first).
            [[ "$_peek_found_subcommand" -eq 0 ]] && _peek_has_legacy_project_flag=1
            _peek_next_skip=1
            ;;
        --version|--profile-file|--notes-file)
            _peek_next_skip=1
            ;;
        --update)   _peek_has_update=1 ;;
        --uninstall) _peek_has_uninstall=1 ;;
        --uninstall-cli) _peek_has_uninstall_cli=1 ;;
        --force|--verbose|--no-path|-h|--help) ;;
        -*)
            # Unknown flag - treat as LEGACY.
            [[ -z "$_peek_first_nonopt" ]] && _peek_first_nonopt="$_peek_arg"
            ;;
        --)
            break  # Stop at end-of-flags marker.
            ;;
        *)
            if [[ -z "$_peek_first_nonopt" ]]; then
                _peek_first_nonopt="$_peek_arg"
                _is_known_subcmd "$_peek_arg" && _peek_found_subcommand=1
            fi
            ;;
    esac
done

if [[ "$_peek_has_uninstall_cli" -eq 1 ]]; then
    _INSTALL_MODE="UNINSTALL_CLI"
elif [[ "$_peek_has_tool" -eq 1 || "$_peek_has_update" -eq 1 || "$_peek_has_uninstall" -eq 1 ]]; then
    _INSTALL_MODE="LEGACY"
elif [[ "$_peek_has_legacy_project_flag" -eq 1 ]]; then
    # --from-bundle or --target before any subcommand -> project-install (legacy).
    _INSTALL_MODE="LEGACY"
elif [[ -n "$_peek_first_nonopt" ]]; then
    if _is_known_subcmd "$_peek_first_nonopt"; then
        _INSTALL_MODE="CONVENIENCE"
    else
        _INSTALL_MODE="LEGACY"
    fi
fi

# AID_TOOL env-var: if set and no legacy-project flags in args, treat as convenience chain.
# If legacy-project flags are present (e.g. AID_TOOL=codex install.sh --from-bundle X),
# keep LEGACY mode so the existing install path handles AID_TOOL as --tool equivalent.
if [[ "$_INSTALL_MODE" == "BOOTSTRAP" && -n "${AID_TOOL:-}" ]]; then
    _INSTALL_MODE="CONVENIENCE"
    _AID_TOOL_ENV_ONLY=1
fi

# ---------------------------------------------------------------------------
# Usage helper (adapted for dual-mode).
# ---------------------------------------------------------------------------
usage() {
    if [[ ! -r "$0" ]]; then
        printf 'install.sh - AID bootstrap (Bash 4+).\n'
        printf '\n'
        printf 'Usage:\n'
        printf '  bash install.sh                          Install global aid CLI\n'
        printf '  bash install.sh <subcommand> [args]      Bootstrap + run aid <subcmd>\n'
        printf '  bash install.sh --uninstall-cli [--force] Remove global aid CLI\n'
        printf '  bash install.sh -h | --help              Print this help\n'
        printf '\n'
        printf 'Legacy (back-compat, one release):\n'
        printf '  bash install.sh [--tool X] [--version v] [--from-bundle p] [--force] [--target d]\n'
        printf '  bash install.sh --update [...]  | --uninstall [...]\n'
        printf '\n'
        printf 'Subcommands: status add remove update version help\n'
        printf '\n'
        printf 'Exit codes: 0 ok, 1 failure, 2 usage, 3 network, 4 checksum,\n'
        printf '            5 protect-on-diff, 6 no manifest, 7 not an AID project\n'
    else
        sed -n '2,55p' "$0" | sed 's/^# \{0,1\}//'
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
# Cleanup helpers - defined BEFORE the EXIT trap.
# ---------------------------------------------------------------------------
_AID_TMPLIB_DIR=""

_cleanup_tmplib() {
    if [[ -n "${_AID_TMPLIB_DIR:-}" && -d "${_AID_TMPLIB_DIR}" ]]; then
        rm -rf "${_AID_TMPLIB_DIR}"
    fi
}

# Exposed by _source_install_core when it performs a remote fetch:
#   _REMOTE_RESOLVED_VER  - the version resolved during lib fetch (e.g. "0.7.0")
#   _REMOTE_SUMS_FILE     - path to the fetched SHA256SUMS (reusable for CLI bundle check)
_REMOTE_RESOLVED_VER=""
_REMOTE_SUMS_FILE=""

STAGING_BASE=""
_cleanup_staging() {
    if [[ -n "$STAGING_BASE" && -d "$STAGING_BASE" ]]; then
        rm -rf "$STAGING_BASE"
    fi
}

trap '_cleanup_tmplib; _cleanup_staging' EXIT

# ---------------------------------------------------------------------------
# _fetch_and_verify_cli_bundle <resolved_ver> <sums_url>
#
# Fetches aid-cli-v<resolved_ver>.tar.gz from the release download base,
# verifies its sha256 against the SHA256SUMS file at <sums_url> (which was
# already fetched and cached during the lib-fetch step), extracts to a temp
# dir, and sets _AID_CLI_BUNDLE_EXTRACT_DIR to the extracted root.
#
# Honors AID_CLI_BUNDLE_URL (direct URL) and AID_CLI_BUNDLE_BASE (base URL).
# Reuses AID_SUMS_URL / AID_INSECURE_SKIP_LIB_VERIFY semantics.
#
# Exit codes:
#   3  fetch failure
#   4  checksum mismatch
# On success, _AID_CLI_BUNDLE_EXTRACT_DIR is set and the function returns 0.
# ---------------------------------------------------------------------------
_AID_CLI_BUNDLE_EXTRACT_DIR=""
_AID_CLI_BUNDLE_TMPDIR=""

_cleanup_cli_bundle() {
    if [[ -n "${_AID_CLI_BUNDLE_TMPDIR:-}" && -d "${_AID_CLI_BUNDLE_TMPDIR}" ]]; then
        rm -rf "${_AID_CLI_BUNDLE_TMPDIR}"
    fi
}

_fetch_and_verify_cli_bundle() {
    local resolved_ver="$1"
    local sums_file="$2"   # path to already-fetched SHA256SUMS (may be "" if not fetched yet)

    _AID_CLI_BUNDLE_TMPDIR="$(mktemp -d /tmp/aid-clibundle-XXXXXX)"
    trap '_cleanup_tmplib; _cleanup_staging; _cleanup_cli_bundle' EXIT

    local bundle_filename="aid-cli-v${resolved_ver}.tar.gz"
    local bundle_file="${_AID_CLI_BUNDLE_TMPDIR}/${bundle_filename}"

    # Resolve the CLI bundle URL.
    local _bundle_url=""
    if [[ -n "${AID_CLI_BUNDLE_URL:-}" ]]; then
        _bundle_url="${AID_CLI_BUNDLE_URL}"
    else
        local _default_bundle_base="https://github.com/AndreVianna/aid-methodology/releases/download/v${resolved_ver}"
        local _bundle_base="${AID_CLI_BUNDLE_BASE:-${_default_bundle_base}}"
        _bundle_url="${_bundle_base}/${bundle_filename}"
    fi

    echo "Fetching CLI bundle from ${_bundle_url} ..." >&2
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "${bundle_file}" "${_bundle_url}" || {
            echo "ERROR: install.sh: failed to fetch CLI bundle from ${_bundle_url}" >&2
            exit 3
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "${bundle_file}" "${_bundle_url}" || {
            echo "ERROR: install.sh: failed to fetch CLI bundle from ${_bundle_url}" >&2
            exit 3
        }
    else
        echo "ERROR: install.sh: neither curl nor wget found; cannot fetch CLI bundle" >&2
        exit 3
    fi

    # Checksum verification (reuses the same SHA256SUMS used for lib verification).
    if [[ "${AID_INSECURE_SKIP_LIB_VERIFY:-0}" == "1" ]]; then
        echo "WARN: install.sh: AID_INSECURE_SKIP_LIB_VERIFY=1 set - skipping CLI bundle checksum verification (INSECURE)" >&2
    else
        # If sums_file is empty, we need to fetch it now.
        local _local_sums=""
        if [[ -n "$sums_file" && -f "$sums_file" ]]; then
            _local_sums="$sums_file"
        else
            # Derive the SHA256SUMS URL (same logic as _source_install_core).
            local _sums_url="${AID_SUMS_URL:-}"
            if [[ -z "$_sums_url" ]]; then
                if [[ -n "${AID_LIB_BASE:-}" ]]; then
                    local _parent_base
                    _parent_base="${AID_LIB_BASE%/lib}"
                    _parent_base="${_parent_base%/lib/}"
                    _sums_url="${_parent_base}/SHA256SUMS"
                elif [[ -n "${AID_CLI_BUNDLE_BASE:-}" ]]; then
                    # Derive from AID_CLI_BUNDLE_BASE parent.
                    _sums_url="${AID_CLI_BUNDLE_BASE}/SHA256SUMS"
                else
                    _sums_url="https://github.com/AndreVianna/aid-methodology/releases/download/v${resolved_ver}/SHA256SUMS"
                fi
            fi
            _local_sums="${_AID_CLI_BUNDLE_TMPDIR}/SHA256SUMS"
            local _sums_ok=0
            echo "Fetching SHA256SUMS from ${_sums_url} ..." >&2
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL -o "${_local_sums}" "${_sums_url}" 2>/dev/null && _sums_ok=1 || _sums_ok=0
            elif command -v wget >/dev/null 2>&1; then
                wget -qO "${_local_sums}" "${_sums_url}" 2>/dev/null && _sums_ok=1 || _sums_ok=0
            fi
            if [[ "$_sums_ok" -ne 1 || ! -f "$_local_sums" ]]; then
                echo "ERROR: install.sh: could not fetch SHA256SUMS; refusing to install unverified CLI bundle (fail-closed)" >&2
                echo "ERROR: install.sh: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)" >&2
                exit 3
            fi
        fi

        # Compute hash of the fetched bundle.
        local _bundle_sha=""
        if command -v sha256sum >/dev/null 2>&1; then
            _bundle_sha="$(sha256sum "${bundle_file}" | awk '{print $1}')"
        elif command -v shasum >/dev/null 2>&1; then
            _bundle_sha="$(shasum -a 256 "${bundle_file}" | awk '{print $1}')"
        fi
        if [[ -z "$_bundle_sha" ]]; then
            echo "ERROR: install.sh: could not compute sha256 of CLI bundle; refusing to install unverified bundle" >&2
            exit 3
        fi

        local _expected_sha
        _expected_sha="$(grep "[[:space:]]${bundle_filename}$" "${_local_sums}" | awk '{print $1}')"
        if [[ -z "$_expected_sha" ]]; then
            echo "ERROR: install.sh: ${bundle_filename} not found in SHA256SUMS; refusing to install unverified CLI bundle (fail-closed)" >&2
            echo "ERROR: install.sh: set AID_INSECURE_SKIP_LIB_VERIFY=1 to bypass (insecure)" >&2
            exit 3
        elif [[ "$_bundle_sha" != "$_expected_sha" ]]; then
            echo "ERROR: install.sh: checksum mismatch for ${bundle_filename}: expected ${_expected_sha}, got ${_bundle_sha}" >&2
            exit 4
        else
            echo "Checksum OK: ${bundle_filename}" >&2
        fi
    fi

    # Extract the bundle to a temp dir.
    _AID_CLI_BUNDLE_EXTRACT_DIR="${_AID_CLI_BUNDLE_TMPDIR}/extracted"
    mkdir -p "${_AID_CLI_BUNDLE_EXTRACT_DIR}"
    if command -v tar >/dev/null 2>&1; then
        tar -xzf "${bundle_file}" -C "${_AID_CLI_BUNDLE_EXTRACT_DIR}" || {
            echo "ERROR: install.sh: failed to extract CLI bundle ${bundle_file}" >&2
            exit 1
        }
    else
        echo "ERROR: install.sh: tar not found; cannot extract CLI bundle" >&2
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Source the shared install core (same logic as before - resolution order:
#   1. AID_LIB_PATH env var
#   2. Sibling lib/aid-install-core.sh
#   3. Remote fetch (piped execution) with fail-closed checksum verification
# ---------------------------------------------------------------------------

_source_install_core() {
    local lib_file

    if [[ -n "${AID_LIB_PATH:-}" ]]; then
        if [[ ! -f "$AID_LIB_PATH" ]]; then
            echo "ERROR: install.sh: AID_LIB_PATH set but file not found: ${AID_LIB_PATH}" >&2
            exit 1
        fi
        lib_file="$AID_LIB_PATH"
    elif [[ -f "${LIB_DIR}/aid-install-core.sh" ]]; then
        lib_file="${LIB_DIR}/aid-install-core.sh"
    else
        _AID_TMPLIB_DIR="$(mktemp -d /tmp/aid-libfetch-XXXXXX)"
        lib_file="${_AID_TMPLIB_DIR}/aid-install-core.sh"

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

        local _default_lib_base="https://raw.githubusercontent.com/AndreVianna/aid-methodology/v${_resolved_ver}/lib"
        local _base_url="${AID_LIB_BASE:-${_default_lib_base}}"
        local _lib_url="${_base_url}/aid-install-core.sh"

        local _default_sums_url="https://github.com/AndreVianna/aid-methodology/releases/download/v${_resolved_ver}/SHA256SUMS"
        local _sums_url="${AID_SUMS_URL:-}"
        if [[ -z "$_sums_url" ]]; then
            if [[ -n "${AID_LIB_BASE:-}" ]]; then
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

        if [[ "${AID_INSECURE_SKIP_LIB_VERIFY:-0}" == "1" ]]; then
            echo "WARN: install.sh: AID_INSECURE_SKIP_LIB_VERIFY=1 set - skipping lib checksum verification (INSECURE)" >&2
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

            local _lib_sha=""
            if command -v sha256sum >/dev/null 2>&1; then
                _lib_sha="$(sha256sum "$lib_file" | awk '{print $1}')"
            elif command -v shasum >/dev/null 2>&1; then
                _lib_sha="$(shasum -a 256 "$lib_file" | awk '{print $1}')"
            fi
            if [[ -z "$_lib_sha" ]]; then
                echo "ERROR: install.sh: could not compute sha256 of fetched lib; refusing to source unverified lib" >&2
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
            # Cache the fetched SHA256SUMS path and resolved version for reuse by
            # the CLI bundle fetch (avoids a second download of the same file).
            _REMOTE_SUMS_FILE="$_sums_file"
        fi
        # Expose the resolved version for the CLI bundle fetch.
        _REMOTE_RESOLVED_VER="$_resolved_ver"
    fi

    # shellcheck source=lib/aid-install-core.sh
    source "$lib_file"

    # Return the resolved lib file path (used by BOOTSTRAP mode to copy into AID_HOME).
    _SOURCED_LIB_FILE="$lib_file"
}

# ---------------------------------------------------------------------------
# Early --help check (before lib source).
# ---------------------------------------------------------------------------
for _early_arg in "$@"; do
    if [[ "$_early_arg" == "-h" || "$_early_arg" == "--help" ]]; then
        usage
        exit 0
    fi
    [[ "$_early_arg" == "--" ]] && break
done

_source_install_core "$@"

# After sourcing the core, _SOURCED_LIB_FILE holds the path to the lib.
_SOURCED_LIB_FILE="${_SOURCED_LIB_FILE:-${LIB_DIR}/aid-install-core.sh}"

# ---------------------------------------------------------------------------
# ============================================================================
# UNINSTALL_CLI mode - remove the global aid CLI (fallback path)
# ============================================================================
# ---------------------------------------------------------------------------
if [[ "$_INSTALL_MODE" == "UNINSTALL_CLI" ]]; then
    _UC_FORCE=0
    _UC_NO_PATH=0
    _UC_PROFILE_FILE=""
    _uc_args=("$@")
    _uc_i=0
    while [[ "$_uc_i" -lt "${#_uc_args[@]}" ]]; do
        _uc_a="${_uc_args[$_uc_i]}"
        case "$_uc_a" in
            --uninstall-cli) ;;
            --force)   _UC_FORCE=1 ;;
            --no-path) _UC_NO_PATH=1 ;;
            --profile-file)
                _uc_i=$((_uc_i + 1))
                _UC_PROFILE_FILE="${_uc_args[$_uc_i]:-}"
                ;;
        esac
        _uc_i=$((_uc_i + 1))
    done

    if [[ "$_UC_FORCE" -eq 0 && ( "${AID_FORCE:-0}" == "1" || "${AID_FORCE:-0}" == "true" ) ]]; then
        _UC_FORCE=1
    fi

    AID_HOME="${AID_HOME:-${HOME}/.aid}"

    if [[ "$_UC_FORCE" -eq 0 ]]; then
        printf 'This will remove the aid CLI from %s and the PATH wiring.\n' "$AID_HOME"
        printf 'Per-project AID installs are NOT affected.\n'
        printf 'Confirm? [y/N] '
        read -r _uc_answer
        if [[ "$_uc_answer" != "y" && "$_uc_answer" != "Y" ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    _uc_partial=0

    # Remove PATH wiring from all standard rc files (or a single explicit file).
    if [[ "$_UC_NO_PATH" -eq 0 ]]; then
        _uc_unwire_one() {
            local _uc_f="$1"
            if [[ -f "$_uc_f" ]] && grep -qF '# >>> aid CLI >>>' "$_uc_f" 2>/dev/null; then
                local _uc_tmp
                _uc_tmp="$(mktemp "${_uc_f}.aid-tmp.XXXXXX")"
                awk 'BEGIN{skip=0} /# >>> aid CLI >>>/{ skip=1; next } skip && /# <<< aid CLI <<</{ skip=0; next } skip{next} {print}' \
                    "$_uc_f" > "$_uc_tmp"
                mv "$_uc_tmp" "$_uc_f"
                echo "PATH wiring removed from ${_uc_f}."
            fi
        }
        if [[ -n "$_UC_PROFILE_FILE" ]]; then
            _uc_unwire_one "$_UC_PROFILE_FILE"
        else
            for _uc_rc in \
                "${ZDOTDIR:-${HOME}}/.zshrc" \
                "${HOME}/.bashrc" \
                "${HOME}/.bash_profile" \
                "${HOME}/.profile"
            do
                _uc_unwire_one "$_uc_rc"
            done
        fi
    fi

    if [[ -d "$AID_HOME" ]]; then
        rm -rf "$AID_HOME" || {
            echo "ERROR: install.sh: failed to remove ${AID_HOME}" >&2
            _uc_partial=1
        }
    fi

    if [[ "$_uc_partial" -eq 1 ]]; then
        echo "aid CLI partially removed."
        exit 1
    fi
    echo "aid CLI removed. Per-project AID installs are unaffected; run 'aid uninstall' in a project before removing the CLI if you also want to remove those."
    exit 0
fi

# ---------------------------------------------------------------------------
# ============================================================================
# BOOTSTRAP mode - install the global aid CLI and optionally wire PATH
# ============================================================================
# ---------------------------------------------------------------------------
if [[ "$_INSTALL_MODE" == "BOOTSTRAP" ]]; then
    # Parse bootstrap flags.
    _BOOTSTRAP_VERSION=""
    _BOOTSTRAP_FROM_BUNDLE=""
    _BOOTSTRAP_NO_PATH="${AID_NO_PATH:-0}"
    _BOOTSTRAP_PROFILE_FILE=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                [[ $# -lt 2 ]] && die "--version requires a value" 2
                _BOOTSTRAP_VERSION="$2"; shift 2 ;;
            --from-bundle)
                [[ $# -lt 2 ]] && die "--from-bundle requires a value" 2
                _BOOTSTRAP_FROM_BUNDLE="$2"; shift 2 ;;
            --no-path) _BOOTSTRAP_NO_PATH=1; shift ;;
            --profile-file)
                [[ $# -lt 2 ]] && die "--profile-file requires a value" 2
                _BOOTSTRAP_PROFILE_FILE="$2"; shift 2 ;;
            -h|--help) usage; exit 0 ;;
            --) shift; break ;;
            -*) die "unknown flag: $1" 2 ;;
            *)  die "unexpected argument: $1 (no subcommand; did you mean 'install.sh add $1'?)" 2 ;;
        esac
    done

    # Apply env-var overrides.
    [[ -z "$_BOOTSTRAP_VERSION" && -n "${AID_VERSION:-}" ]] && _BOOTSTRAP_VERSION="${AID_VERSION#v}"
    _BOOTSTRAP_VERSION="${_BOOTSTRAP_VERSION#v}"

    AID_HOME="${AID_HOME:-${HOME}/.aid}"
    local_bin_dir="${AID_HOME}/bin"
    local_lib_dir="${AID_HOME}/lib"

    # Determine CLI version (what we are installing).
    # If the lib was fetched remotely, we can derive the version from the lib-fetch
    # resolution already done.  If from sibling, use _BOOTSTRAP_VERSION or read VERSION file.
    _CLI_VERSION="${_BOOTSTRAP_VERSION}"
    if [[ -z "$_CLI_VERSION" ]]; then
        if [[ -f "${SCRIPT_DIR}/VERSION" ]]; then
            _CLI_VERSION="$(tr -d '[:space:]' < "${SCRIPT_DIR}/VERSION")"
        else
            _CLI_VERSION="0.0.0"
        fi
    fi

    # Locate the dispatcher (bin/aid) to install.
    # It lives at: <script-dir>/bin/aid (relative to install.sh in the release tree).
    # When absent (piped/curl execution), fetch the CLI bundle from the release.
    _BOOTSTRAP_AID_BIN="${SCRIPT_DIR}/bin/aid"
    if [[ ! -f "$_BOOTSTRAP_AID_BIN" ]]; then
        # Piped bootstrap: bin/aid not beside install.sh.
        # Fetch, verify, and extract the CLI bundle from the release.
        # Version resolution: prefer cached remote lib-fetch value; fall back to
        # AID_LIB_VERSION env var or _CLI_VERSION (covers local-lib-path installs too).
        _bs_resolved_ver="${_REMOTE_RESOLVED_VER:-}"
        [[ -z "$_bs_resolved_ver" && -n "${AID_LIB_VERSION:-}" ]] && _bs_resolved_ver="${AID_LIB_VERSION#v}"
        [[ -z "$_bs_resolved_ver" && -n "$_CLI_VERSION" && "$_CLI_VERSION" != "0.0.0" ]] && _bs_resolved_ver="$_CLI_VERSION"
        if [[ -z "$_bs_resolved_ver" ]]; then
            die "Cannot determine release version for CLI bundle fetch; set AID_LIB_VERSION or --version." 3
        fi
        _fetch_and_verify_cli_bundle "$_bs_resolved_ver" "${_REMOTE_SUMS_FILE:-}"
        # _AID_CLI_BUNDLE_EXTRACT_DIR now contains: bin/aid, bin/aid.ps1, bin/aid.cmd,
        # lib/aid-install-core.sh, lib/AidInstallCore.psm1, VERSION.
        _BOOTSTRAP_AID_BIN="${_AID_CLI_BUNDLE_EXTRACT_DIR}/bin/aid"
        # Use the version from the bundle's VERSION file.
        if [[ -f "${_AID_CLI_BUNDLE_EXTRACT_DIR}/VERSION" ]]; then
            _CLI_VERSION="$(tr -d '[:space:]' < "${_AID_CLI_BUNDLE_EXTRACT_DIR}/VERSION")"
        fi
        _SOURCED_LIB_FILE="${_AID_CLI_BUNDLE_EXTRACT_DIR}/lib/aid-install-core.sh"
    fi

    # Stage into a temp dir, then atomic-move into AID_HOME to avoid partial writes.
    _BOOTSTRAP_STAGE="$(mktemp -d /tmp/aid-bootstrap-XXXXXX)"
    trap '_cleanup_tmplib; _cleanup_staging; _cleanup_cli_bundle; rm -rf "${_BOOTSTRAP_STAGE:-}"' EXIT

    mkdir -p "${_BOOTSTRAP_STAGE}/bin" "${_BOOTSTRAP_STAGE}/lib"
    cp "$_BOOTSTRAP_AID_BIN" "${_BOOTSTRAP_STAGE}/bin/aid"
    chmod +x "${_BOOTSTRAP_STAGE}/bin/aid"
    # Also install aid.ps1 and aid.cmd if available (from bundle or release tree).
    _BOOTSTRAP_AID_PS1="${SCRIPT_DIR}/bin/aid.ps1"
    _BOOTSTRAP_AID_CMD="${SCRIPT_DIR}/bin/aid.cmd"
    if [[ -n "${_AID_CLI_BUNDLE_EXTRACT_DIR:-}" ]]; then
        _BOOTSTRAP_AID_PS1="${_AID_CLI_BUNDLE_EXTRACT_DIR}/bin/aid.ps1"
        _BOOTSTRAP_AID_CMD="${_AID_CLI_BUNDLE_EXTRACT_DIR}/bin/aid.cmd"
    fi
    [[ -f "$_BOOTSTRAP_AID_PS1" ]] && cp "$_BOOTSTRAP_AID_PS1" "${_BOOTSTRAP_STAGE}/bin/aid.ps1"
    [[ -f "$_BOOTSTRAP_AID_CMD" ]] && cp "$_BOOTSTRAP_AID_CMD" "${_BOOTSTRAP_STAGE}/bin/aid.cmd"
    # Pre-copy sanity: verify the source lib contains the required sentinel function.
    # This catches a bad AID_LIB_PATH (empty file, truncated download, wrong file).
    if ! grep -qF 'aid_status_body' "$_SOURCED_LIB_FILE" 2>/dev/null; then
        echo "ERROR: install.sh: installer could not refresh the CLI core; the source lib at ${_SOURCED_LIB_FILE} does not contain the expected function 'aid_status_body'. Delete ${AID_HOME} and reinstall." >&2
        exit 1
    fi

    cp "$_SOURCED_LIB_FILE" "${_BOOTSTRAP_STAGE}/lib/aid-install-core.sh"
    printf '%s\n' "$_CLI_VERSION" > "${_BOOTSTRAP_STAGE}/VERSION"

    # Clean-replace: remove stale files before copying so upgrades never leave old bits.
    rm -f "${local_bin_dir}/aid" "${local_bin_dir}/aid.ps1" "${local_bin_dir}/aid.cmd" \
          "${local_lib_dir}/aid-install-core.sh" 2>/dev/null || true

    # Atomic install: move staged files into AID_HOME.
    mkdir -p "$local_bin_dir" "$local_lib_dir"
    cp "${_BOOTSTRAP_STAGE}/bin/aid" "${local_bin_dir}/aid"
    chmod +x "${local_bin_dir}/aid"
    [[ -f "${_BOOTSTRAP_STAGE}/bin/aid.ps1" ]] && cp "${_BOOTSTRAP_STAGE}/bin/aid.ps1" "${local_bin_dir}/aid.ps1"
    [[ -f "${_BOOTSTRAP_STAGE}/bin/aid.cmd" ]] && cp "${_BOOTSTRAP_STAGE}/bin/aid.cmd" "${local_bin_dir}/aid.cmd"
    cp "${_BOOTSTRAP_STAGE}/lib/aid-install-core.sh" "${local_lib_dir}/aid-install-core.sh"
    cp "${_BOOTSTRAP_STAGE}/VERSION" "${AID_HOME}/VERSION"

    # Post-copy verify: sha256 of installed lib must match the source we copied from.
    # A grep-based sentinel check (the previous approach) passes stale/partial files
    # that contain the sentinel string in a comment earlier in the file.
    _bs_src_sha=""
    _bs_dest_sha=""
    if command -v sha256sum >/dev/null 2>&1; then
        _bs_src_sha="$(sha256sum "$_SOURCED_LIB_FILE" | awk '{print $1}')"
        _bs_dest_sha="$(sha256sum "${local_lib_dir}/aid-install-core.sh" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
        _bs_src_sha="$(shasum -a 256 "$_SOURCED_LIB_FILE" | awk '{print $1}')"
        _bs_dest_sha="$(shasum -a 256 "${local_lib_dir}/aid-install-core.sh" | awk '{print $1}')"
    fi
    if [[ -z "$_bs_src_sha" || "$_bs_src_sha" != "$_bs_dest_sha" ]]; then
        echo "ERROR: install.sh: installer could not refresh the CLI core at ${local_lib_dir}/aid-install-core.sh; sha256 mismatch between source and installed copy (source: ${_bs_src_sha}, installed: ${_bs_dest_sha}). Delete ${AID_HOME} and reinstall." >&2
        exit 1
    fi

    echo "aid CLI v${_CLI_VERSION} installed to ${AID_HOME}."

    # Wire PATH (idempotent marked-block) into a single profile file.
    # Usage: _wire_profile_block <bin_dir> <profile>
    # Does NOT handle --no-path; caller must check before calling.
    _wire_profile_block() {
        local bin_dir="$1"
        local profile="$2"

        if [[ ! -f "$profile" ]]; then
            touch "$profile" 2>/dev/null || {
                echo "WARN: install.sh: could not create ${profile}; PATH not wired." >&2
                printf 'Add "%s" to your PATH manually.\n' "$bin_dir"
                return 0
            }
        fi

        local fence_start='# >>> aid CLI >>>'
        local fence_end='# <<< aid CLI <<<'
        # Duplicate-guarded export: safe even when multiple rc files are sourced.
        local path_line="case \":\$PATH:\" in *\":${bin_dir}:\"*) ;; *) export PATH=\"${bin_dir}:\$PATH\" ;; esac"

        if grep -qF "$fence_start" "$profile" 2>/dev/null; then
            local tmp_p
            tmp_p="$(mktemp "${profile}.aid-tmp.XXXXXX")"
            awk -v fs="$fence_start" -v fe="$fence_end" -v pl="$path_line" \
                'BEGIN{skip=0}
                 $0==fs{skip=1; print fs; print pl; print fe; next}
                 skip && $0==fe{skip=0; next}
                 skip{next}
                 {print}' "$profile" > "$tmp_p"
            mv "$tmp_p" "$profile"
            echo "PATH wiring updated in ${profile}."
        else
            printf '\n%s\n%s\n%s\n' "$fence_start" "$path_line" "$fence_end" >> "$profile"
            echo "PATH wiring added to ${profile}."
        fi
    }

    # Wire PATH into all standard rc files that exist (rustup/nvm pattern).
    # --profile-file overrides to a single explicit file.
    if [[ "$_BOOTSTRAP_NO_PATH" -eq 1 ]]; then
        printf 'Add "%s" to your PATH manually.\n' "$local_bin_dir"
    elif [[ -n "$_BOOTSTRAP_PROFILE_FILE" ]]; then
        _wire_profile_block "$local_bin_dir" "$_BOOTSTRAP_PROFILE_FILE"
        echo "Open a new shell, or run: export PATH=\"${local_bin_dir}:\$PATH\" (or: source ${_BOOTSTRAP_PROFILE_FILE})"
    else
        # Candidate rc files; wire every one that already exists.
        _bs_rc_candidates=(
            "${ZDOTDIR:-${HOME}}/.zshrc"
            "${HOME}/.bashrc"
            "${HOME}/.bash_profile"
            "${HOME}/.profile"
        )
        _bs_wired=()
        for _bs_rc in "${_bs_rc_candidates[@]}"; do
            if [[ -f "$_bs_rc" ]]; then
                _wire_profile_block "$local_bin_dir" "$_bs_rc"
                _bs_wired+=("$_bs_rc")
            fi
        done
        # If none exist, create and wire ~/.profile.
        if [[ "${#_bs_wired[@]}" -eq 0 ]]; then
            _wire_profile_block "$local_bin_dir" "${HOME}/.profile"
            _bs_wired+=("${HOME}/.profile")
        fi
        # Summarise wired files.
        _bs_wired_display=""
        for _bs_w in "${_bs_wired[@]}"; do
            _bs_rel="${_bs_w/#${HOME}/~}"
            _bs_wired_display="${_bs_wired_display:+${_bs_wired_display}, }${_bs_rel}"
        done
        echo "PATH wiring added to: ${_bs_wired_display}"
        echo "Open a new shell to pick up the updated PATH."
    fi

    printf '\nThen: aid add <tool>    (e.g. aid add codex)\n'
    exit 0
fi

# ---------------------------------------------------------------------------
# ============================================================================
# CONVENIENCE mode - bootstrap CLI (if needed) then exec 'aid <subcmd> ...'
# ============================================================================
# ---------------------------------------------------------------------------
if [[ "$_INSTALL_MODE" == "CONVENIENCE" ]]; then
    # Parse args: strip bootstrap-only flags (--no-path, --profile-file) from both
    # the pre-subcommand and post-subcommand positions; pass everything else to aid.
    _CONV_NO_PATH="${AID_NO_PATH:-0}"
    _CONV_PROFILE_FILE=""
    _CONV_SUBCMD_ARGS=()

    _conv_args=("$@")
    _conv_i=0
    while [[ "$_conv_i" -lt "${#_conv_args[@]}" ]]; do
        _conv_a="${_conv_args[$_conv_i]}"
        case "$_conv_a" in
            --no-path)
                _CONV_NO_PATH=1
                ;;
            --profile-file)
                _conv_i=$((_conv_i + 1))
                _CONV_PROFILE_FILE="${_conv_args[$_conv_i]:-}"
                ;;
            *)
                _CONV_SUBCMD_ARGS+=("$_conv_a")
                ;;
        esac
        _conv_i=$((_conv_i + 1))
    done

    # If triggered by AID_TOOL env-var only (no args), synthesize 'add <AID_TOOL>'.
    if [[ "${_AID_TOOL_ENV_ONLY:-0}" -eq 1 && "${#_CONV_SUBCMD_ARGS[@]}" -eq 0 ]]; then
        _CONV_SUBCMD_ARGS=("add" "${AID_TOOL}")
    fi

    AID_HOME="${AID_HOME:-${HOME}/.aid}"
    _CONV_AID_BIN="${AID_HOME}/bin/aid"

    # Bootstrap the CLI if not already present or if it needs upgrading.
    # (Reuse BOOTSTRAP logic by detecting whether AID_HOME/bin/aid exists.)
    if [[ ! -f "$_CONV_AID_BIN" ]]; then
        # Install the CLI first.
        _CONV_BIN_SRC="${SCRIPT_DIR}/bin/aid"
        _CONV_CLI_BUNDLE_EXTRACT=""
        if [[ ! -f "$_CONV_BIN_SRC" ]]; then
            # Piped bootstrap: bin/aid not beside install.sh - fetch CLI bundle.
            _conv_resolved_ver="${_REMOTE_RESOLVED_VER:-}"
            [[ -z "$_conv_resolved_ver" && -n "${AID_LIB_VERSION:-}" ]] && _conv_resolved_ver="${AID_LIB_VERSION#v}"
            [[ -z "$_conv_resolved_ver" && -n "$_CONV_CLI_VER" && "$_CONV_CLI_VER" != "0.0.0" ]] && _conv_resolved_ver="$_CONV_CLI_VER"
            if [[ -z "$_conv_resolved_ver" ]]; then
                die "Cannot determine release version for CLI bundle fetch; set AID_LIB_VERSION." 3
            fi
            _fetch_and_verify_cli_bundle "$_conv_resolved_ver" "${_REMOTE_SUMS_FILE:-}"
            _CONV_CLI_BUNDLE_EXTRACT="${_AID_CLI_BUNDLE_EXTRACT_DIR}"
            _CONV_BIN_SRC="${_AID_CLI_BUNDLE_EXTRACT_DIR}/bin/aid"
        fi
        _CONV_VERSION_FILE="${SCRIPT_DIR}/VERSION"
        _CONV_CLI_VER="0.0.0"
        if [[ -n "$_CONV_CLI_BUNDLE_EXTRACT" && -f "${_CONV_CLI_BUNDLE_EXTRACT}/VERSION" ]]; then
            _CONV_CLI_VER="$(tr -d '[:space:]' < "${_CONV_CLI_BUNDLE_EXTRACT}/VERSION")"
        elif [[ -f "$_CONV_VERSION_FILE" ]]; then
            _CONV_CLI_VER="$(tr -d '[:space:]' < "$_CONV_VERSION_FILE")"
        fi

        mkdir -p "${AID_HOME}/bin" "${AID_HOME}/lib"

        # Clean-replace: remove stale files before copying so upgrades never leave old bits.
        rm -f "${AID_HOME}/bin/aid" "${AID_HOME}/bin/aid.ps1" "${AID_HOME}/bin/aid.cmd" \
              "${AID_HOME}/lib/aid-install-core.sh" 2>/dev/null || true

        cp "$_CONV_BIN_SRC" "${AID_HOME}/bin/aid"
        chmod +x "${AID_HOME}/bin/aid"
        # Install aid.ps1 / aid.cmd if available.
        _conv_ps1_src="${SCRIPT_DIR}/bin/aid.ps1"
        _conv_cmd_src="${SCRIPT_DIR}/bin/aid.cmd"
        [[ -n "$_CONV_CLI_BUNDLE_EXTRACT" ]] && _conv_ps1_src="${_CONV_CLI_BUNDLE_EXTRACT}/bin/aid.ps1"
        [[ -n "$_CONV_CLI_BUNDLE_EXTRACT" ]] && _conv_cmd_src="${_CONV_CLI_BUNDLE_EXTRACT}/bin/aid.cmd"
        [[ -f "$_conv_ps1_src" ]] && cp "$_conv_ps1_src" "${AID_HOME}/bin/aid.ps1"
        [[ -f "$_conv_cmd_src" ]] && cp "$_conv_cmd_src" "${AID_HOME}/bin/aid.cmd"
        _conv_lib_src="$_SOURCED_LIB_FILE"
        [[ -n "$_CONV_CLI_BUNDLE_EXTRACT" && -f "${_CONV_CLI_BUNDLE_EXTRACT}/lib/aid-install-core.sh" ]] && \
            _conv_lib_src="${_CONV_CLI_BUNDLE_EXTRACT}/lib/aid-install-core.sh"

        # Pre-copy sanity: verify the source lib contains the required sentinel function.
        # This catches a bad AID_LIB_PATH (empty file, truncated download, wrong file).
        if ! grep -qF 'aid_status_body' "$_conv_lib_src" 2>/dev/null; then
            echo "ERROR: install.sh: installer could not refresh the CLI core; the source lib at ${_conv_lib_src} does not contain the expected function 'aid_status_body'. Delete ${AID_HOME} and reinstall." >&2
            exit 1
        fi

        cp "$_conv_lib_src" "${AID_HOME}/lib/aid-install-core.sh"

        # Post-copy verify: sha256 of installed lib must match the source we copied from.
        # A grep-based sentinel check (the previous approach) passes stale/partial files
        # that contain the sentinel string in a comment earlier in the file.
        _cv_src_sha=""
        _cv_dest_sha=""
        if command -v sha256sum >/dev/null 2>&1; then
            _cv_src_sha="$(sha256sum "$_conv_lib_src" | awk '{print $1}')"
            _cv_dest_sha="$(sha256sum "${AID_HOME}/lib/aid-install-core.sh" | awk '{print $1}')"
        elif command -v shasum >/dev/null 2>&1; then
            _cv_src_sha="$(shasum -a 256 "$_conv_lib_src" | awk '{print $1}')"
            _cv_dest_sha="$(shasum -a 256 "${AID_HOME}/lib/aid-install-core.sh" | awk '{print $1}')"
        fi
        if [[ -z "$_cv_src_sha" || "$_cv_src_sha" != "$_cv_dest_sha" ]]; then
            echo "ERROR: install.sh: installer could not refresh the CLI core at ${AID_HOME}/lib/aid-install-core.sh; sha256 mismatch between source and installed copy (source: ${_cv_src_sha}, installed: ${_cv_dest_sha}). Delete ${AID_HOME} and reinstall." >&2
            exit 1
        fi

        printf '%s\n' "$_CONV_CLI_VER" > "${AID_HOME}/VERSION"
        echo "aid CLI v${_CONV_CLI_VER} installed to ${AID_HOME}."

        # Wire PATH into all standard rc files that exist (or a single explicit file).
        _cp_bin="${AID_HOME}/bin"
        _cp_fence='# >>> aid CLI >>>'
        _cp_fence_end='# <<< aid CLI <<<'
        # Duplicate-guarded export.
        _cp_line="case \":\$PATH:\" in *\":${_cp_bin}:\"*) ;; *) export PATH=\"${_cp_bin}:\$PATH\" ;; esac"

        _conv_wire_one() {
            local _cv_f="$1"
            [[ ! -f "$_cv_f" ]] && touch "$_cv_f" 2>/dev/null || true
            if grep -qF "$_cp_fence" "$_cv_f" 2>/dev/null; then
                local _cv_tmp
                _cv_tmp="$(mktemp "${_cv_f}.aid-tmp.XXXXXX")"
                awk -v fs="$_cp_fence" -v fe="$_cp_fence_end" -v pl="$_cp_line" \
                    'BEGIN{skip=0}
                     $0==fs{skip=1; print fs; print pl; print fe; next}
                     skip && $0==fe{skip=0; next}
                     skip{next}
                     {print}' "$_cv_f" > "$_cv_tmp"
                mv "$_cv_tmp" "$_cv_f"
                echo "PATH wiring updated in ${_cv_f}."
            else
                printf '\n%s\n%s\n%s\n' "$_cp_fence" "$_cp_line" "$_cp_fence_end" >> "$_cv_f"
                echo "PATH wiring added to ${_cv_f}."
            fi
        }

        if [[ "$_CONV_NO_PATH" -eq 0 ]]; then
            if [[ -n "$_CONV_PROFILE_FILE" ]]; then
                _conv_wire_one "$_CONV_PROFILE_FILE"
            else
                _cv_rc_candidates=(
                    "${ZDOTDIR:-${HOME}}/.zshrc"
                    "${HOME}/.bashrc"
                    "${HOME}/.bash_profile"
                    "${HOME}/.profile"
                )
                _cv_wired=()
                for _cv_rc in "${_cv_rc_candidates[@]}"; do
                    if [[ -f "$_cv_rc" ]]; then
                        _conv_wire_one "$_cv_rc"
                        _cv_wired+=("$_cv_rc")
                    fi
                done
                if [[ "${#_cv_wired[@]}" -eq 0 ]]; then
                    _conv_wire_one "${HOME}/.profile"
                fi
            fi
        fi
    fi

    # Exec 'aid <subcmd> ...' directly (bypass PATH refresh requirement).
    exec "$_CONV_AID_BIN" "${_CONV_SUBCMD_ARGS[@]+"${_CONV_SUBCMD_ARGS[@]}"}"
    # exec replaces process; we never reach here.
    exit 0
fi

# ---------------------------------------------------------------------------
# ============================================================================
# LEGACY mode - original flag-style direct project install (back-compat).
#
# Identical behavior to the pre-CLI-evolution install.sh.
# Preserved for one release so existing test fixtures keep passing.
# ============================================================================
# ---------------------------------------------------------------------------

# Argument parsing (verbatim from the original install.sh).
MODE="install"
TOOL_ARG=""
VERSION_ARG=""
FROM_BUNDLE=""
FORCE=0
TARGET=""
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
        --uninstall-cli)
            # Should have been handled above; re-route.
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
        --no-path)
            # Bootstrap-only flag; silently ignore in legacy mode.
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "unknown flag: $1" 2
            ;;
        *)
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

# Apply env-var fallbacks.
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

# Validation.
if [[ -n "$FROM_BUNDLE" && -n "$VERSION_ARG" ]]; then
    die "--from-bundle and --version are mutually exclusive" 2
fi
if [[ "$MODE" == "uninstall" ]]; then
    if [[ -n "$FROM_BUNDLE" ]]; then
        die "--from-bundle is not valid with --uninstall" 2
    fi
    if [[ -n "$VERSION_ARG" ]]; then
        die "--version is not valid with --uninstall" 2
    fi
fi

TARGET="${TARGET:-.}"
if [[ ! -d "$TARGET" ]]; then
    die "target directory does not exist: ${TARGET}" 2
fi
TARGET="$(cd "$TARGET" && pwd)"
VERSION_ARG="${VERSION_ARG#v}"

# Resolve tool list (same logic as original).
_RESOLVE_TOOLS_RC=0
_resolve_tools() {
    local raw="$1" target_dir="$2" mode="$3" outfile="$4"

    if [[ -z "$raw" ]]; then
        if [[ "$mode" == "uninstall" ]]; then
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
        local detected
        detected="$(detect_tool "$target_dir")"
        local _rc=$?
        if [[ "$_rc" -ne 0 ]]; then
            return "$_rc"
        fi
        echo "$detected" >> "$outfile"
        return 0
    fi

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

STAGING_DIR=""
RESOLVED_VERSION=""

prepare_tool_staging() {
    local tool="$1" version="$2" from_bundle="$3"

    local tool_staging
    tool_staging="$(mktemp -d "${STAGING_BASE}/staging-${tool}-XXXXXX")"

    if [[ -n "$from_bundle" ]]; then
        local tarball="$from_bundle"
        if [[ -d "$from_bundle" ]]; then
            tarball="$(ls "${from_bundle}"/aid-${tool}-v*.tar.gz 2>/dev/null | head -1)"
            if [[ -z "$tarball" ]]; then
                die "no tarball found for tool '${tool}' in bundle directory: ${from_bundle}" 1
            fi
        fi
        if [[ ! -f "$tarball" ]]; then
            die "bundle file not found: ${tarball}" 1
        fi
        verify_bundle_checksum "$tarball" || exit $?
        local tbase
        tbase="$(basename "$tarball")"
        RESOLVED_VERSION="$(echo "$tbase" | sed "s/aid-${tool}-v//" | sed 's/\.tar\.gz$//')"
        [[ -z "$RESOLVED_VERSION" ]] && RESOLVED_VERSION="${version:-unknown}"
        extract_tarball "$tarball" "$tool_staging" || exit $?
    else
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

STAGING_BASE="$(mktemp -d /tmp/aid-install-XXXXXX)"

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

OVERALL_BLOCKED=0

case "$MODE" in
    install|update)
        for tool in "${TOOLS[@]}"; do
            echo ""
            prepare_tool_staging "$tool" "$VERSION_ARG" "$FROM_BUNDLE"
            echo "Installing ${tool} v${RESOLVED_VERSION} -> ${TARGET}"
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
