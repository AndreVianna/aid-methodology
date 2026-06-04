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

# ---------------------------------------------------------------------------
# Locate repo root (the directory containing this script).
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
# ---------------------------------------------------------------------------
if [[ ! -f "${LIB_DIR}/aid-install-core.sh" ]]; then
    die "Shared install core not found: ${LIB_DIR}/aid-install-core.sh" 1
fi
# shellcheck source=lib/aid-install-core.sh
source "${LIB_DIR}/aid-install-core.sh"

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
trap '_cleanup_staging' EXIT

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
