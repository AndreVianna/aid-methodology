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
#                   [--force] [--target <dir>] [<target-dir>]
#       Install AID into the target directory (default: current directory).
#
#   bash install.sh --update [--tool <name>[,...]] [--version <v>] [--from-bundle <path>]
#                   [--force] [--target <dir>]
#       Re-install / update an existing AID installation to the given or latest version.
#
#   bash install.sh --uninstall [--tool <name>[,...]] [--target <dir>]
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
# Environment variables:
#   AID_LIB_PATH   — absolute path to aid-install-core.sh to source directly (overrides
#                    sibling detection and remote fetch; useful for tests and vendored use).
#   AID_LIB_BASE   — base URL prefix for the remote lib fetch when the lib is not beside
#                    the script (piped/curl|bash case).  Defaults to the raw GitHub URL for
#                    the master branch.  Example for local test override:
#                      AID_LIB_BASE=file:///path/to/local/lib install.sh ...
#                    When AID_LIB_BASE is set, the lib is fetched as:
#                      ${AID_LIB_BASE}/aid-install-core.sh

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
# ---------------------------------------------------------------------------
usage() {
    sed -n '2,49p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Error helper.
# ---------------------------------------------------------------------------
die() {
    echo "ERROR: install.sh: $1" >&2
    exit "${2:-1}"
}

# ---------------------------------------------------------------------------
# Source the shared install core.
# Resolution order (first match wins):
#   1. AID_LIB_PATH env var — absolute path to the lib file (test override or vendored).
#   2. Sibling lib/aid-install-core.sh — present when invoked as a local file.
#   3. Remote fetch from AID_LIB_BASE (or default GitHub raw URL) into a temp dir —
#      used in the piped (curl|bash) case where no sibling lib is available.
# ---------------------------------------------------------------------------
_AID_TMPLIB_DIR=""

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
        # 3. Remote fetch (piped execution).
        local base_url="${AID_LIB_BASE:-https://raw.githubusercontent.com/AndreVianna/aid-methodology/master/lib}"
        local lib_url="${base_url}/aid-install-core.sh"
        _AID_TMPLIB_DIR="$(mktemp -d /tmp/aid-libfetch-XXXXXX)"
        lib_file="${_AID_TMPLIB_DIR}/aid-install-core.sh"
        echo "Fetching install core from ${lib_url} ..." >&2
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL -o "$lib_file" "$lib_url" || {
                echo "ERROR: install.sh: failed to fetch install core from ${lib_url}" >&2
                exit 3
            }
        elif command -v wget >/dev/null 2>&1; then
            wget -qO "$lib_file" "$lib_url" || {
                echo "ERROR: install.sh: failed to fetch install core from ${lib_url}" >&2
                exit 3
            }
        else
            echo "ERROR: install.sh: neither curl nor wget found; cannot fetch install core" >&2
            exit 3
        fi
    fi

    # shellcheck source=lib/aid-install-core.sh
    source "$lib_file"
}

_source_install_core

# Cleanup temp lib dir on exit (if created).
_cleanup_tmplib() {
    if [[ -n "${_AID_TMPLIB_DIR:-}" && -d "${_AID_TMPLIB_DIR}" ]]; then
        rm -rf "${_AID_TMPLIB_DIR}"
    fi
}
trap '_cleanup_tmplib; _cleanup_staging' EXIT

# ---------------------------------------------------------------------------
# Argument parsing.
# ---------------------------------------------------------------------------
MODE="install"         # install | update | uninstall
TOOL_ARG=""            # raw --tool value (comma-list or empty)
VERSION_ARG=""         # raw --version value (empty = latest)
FROM_BUNDLE=""         # path to tarball or directory (offline)
FORCE=0
TARGET=""

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
STAGING_BASE=""
_cleanup_staging() {
    if [[ -n "$STAGING_BASE" && -d "$STAGING_BASE" ]]; then
        rm -rf "$STAGING_BASE"
    fi
}
# Note: trap for _cleanup_staging is combined with _cleanup_tmplib above (set after
# sourcing the lib) to avoid overwriting each other.

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
            echo "--- ${tool} ---"
            prepare_tool_staging "$tool" "$VERSION_ARG" "$FROM_BUNDLE"
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
            echo "--- uninstall ${tool} ---"
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
