#!/usr/bin/env bash
# aid-install-core.sh - Shared Bash install-core library for the AID installer.
#
# Purpose:
#   Sourceable library of pure functions used by install.sh (Bash bootstrap) and
#   any future in-language caller.  No top-level side effects when sourced - every
#   function is defined here; nothing executes at source time.
#
# Provides:
#   sha256_file <path>          -> hex sha256 of file content (stdout)
#   normalize_tool <id>         -> canonical lower-case-hyphen tool id (stdout)
#   detect_tool <target>        -> detected tool id (stdout); exit 2 on 0 or >1 matches
#   resolve_version             -> latest GitHub release version (stdout); exit 3 on fail
#   fetch_tarball <tool> <ver> <dest_dir>
#                               -> downloads aid-<tool>-v<ver>.tar.gz + SHA256SUMS into
#                                 dest_dir; verifies sha256; exit 3 on fetch, 4 on mismatch
#   extract_tarball <tarball> <dest_dir>
#                               -> extracts tarball (flat root) into dest_dir; exit 1 on fail
#   verify_bundle_checksum <tarball>
#                               -> verifies sibling SHA256SUMS when present; exit 4 on mismatch
#   copy_file <src> <dst> [force]
#                               -> copy semantics (skip-identical/skip-on-diff/force)
#   copy_dir <src_dir> <dst_dir> [force]
#                               -> recursive copy via copy_file
#   install_tool <staging> <tool> <target> <version> [force]
#                               -> run the full install for one tool (copy + manifest + root-agent region update)
#   manifest_read_tool_paths <manifest> <tool>
#                               -> newline-delimited paths from tools.<tool>.paths (stdout)
#   manifest_read_tool_version <manifest> <tool>
#                               -> version string from tools.<tool>.version (stdout)
#   manifest_read_root_agent <manifest> <tool> <path>
#                               -> sha256 from root_agent_files entry (stdout); empty if absent
#   manifest_read_root_agent_status <manifest> <tool> <path>
#                               -> status field from root_agent_files entry (stdout)
#   manifest_write <manifest> <tool> <version> <paths_arr_name> <root_entries_arr_name>
#                               -> atomically writes/merges the manifest JSON
#   manifest_remove_tool <manifest> <tool>
#                               -> removes a tool section from the manifest
#   manifest_exists <manifest>  -> exit 0 when manifest exists and is parseable, else exit 6
#   uninstall_tool <manifest> <tool> <target>
#                               -> manifest-driven removal of one tool's files
#   write_version_marker <target> <version>
#                               -> writes <target>/.aid/.aid-version
#
# Verbose mode:
#   Set AID_VERBOSE=1 (or pass --verbose to install.sh) to print per-file
#   Copied:/Up to date:/Updated:/Skipped:/Removed: lines.  Default (0) prints
#   only the per-tool summary line.
#
# Exit codes (from install.sh):
#   0  success
#   1  generic runtime failure
#   2  usage error
#   3  network / fetch failure
#   4  checksum mismatch
#   6  uninstall with no manifest

# Guard against being sourced more than once.
[[ -n "${_AID_INSTALL_CORE_LOADED:-}" ]] && return 0
_AID_INSTALL_CORE_LOADED=1

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

AID_REPO_SLUG="AndreVianna/aid-methodology"
# Release source. Defaults to GitHub; both are env-overridable so an air-gapped /
# enterprise mirror (or a local pre-release verification mirror) can serve the
# release JSON and assets without changing the published defaults.
AID_API_BASE="${AID_API_BASE:-https://api.github.com/repos/${AID_REPO_SLUG}}"
AID_DOWNLOAD_BASE="${AID_DOWNLOAD_BASE:-https://github.com/${AID_REPO_SLUG}/releases/download}"

# Canonical tool ids.
AID_TOOLS=(claude-code codex cursor copilot-cli antigravity)

# Root agent file per tool.
_root_agent_file() {
    case "$1" in
        claude-code)  echo "CLAUDE.md" ;;
        codex|cursor|copilot-cli|antigravity) echo "AGENTS.md" ;;
    esac
}

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

# sha256_file <path> - print lower-case hex sha256 of file.
sha256_file() {
    local f="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$f" | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$f" | awk '{print $1}'
    else
        echo "ERROR: aid-install-core: no sha256 utility (need sha256sum or shasum)" >&2
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Tool-id normalization + detection
# ---------------------------------------------------------------------------

# normalize_tool <input> - print canonical id or exit 2 on unknown.
normalize_tool() {
    local raw
    raw="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
    case "$raw" in
        claude-code|claudecode) echo "claude-code" ;;
        codex)                  echo "codex" ;;
        cursor)                 echo "cursor" ;;
        copilot-cli|copilotcli) echo "copilot-cli" ;;
        antigravity)            echo "antigravity" ;;
        *)
            echo "ERROR: aid-install-core: unknown tool id: $1 (valid: claude-code, codex, cursor, copilot-cli, antigravity)" >&2
            return 2
            ;;
    esac
}

# detect_tool <target> - auto-detect the installed host tool from tree markers.
# Prints the canonical id.  Exits 2 on ambiguous (>1) or undetectable (0).
detect_tool() {
    local target="$1"
    local found=()

    [[ -d "${target}/.claude" ]] && found+=("claude-code")
    # codex: .codex or .agents dir
    if [[ -d "${target}/.codex" || -d "${target}/.agents" ]]; then
        found+=("codex")
    fi
    [[ -d "${target}/.cursor" ]] && found+=("cursor")
    # copilot-cli: .github with AID copilot subtree (.github/agents/ or .github/skills/)
    if [[ -d "${target}/.github" ]] && \
       ( [[ -d "${target}/.github/agents" ]] || [[ -d "${target}/.github/skills" ]] ); then
        found+=("copilot-cli")
    fi
    [[ -d "${target}/.agent" ]] && found+=("antigravity")

    if [[ "${#found[@]}" -eq 1 ]]; then
        echo "${found[0]}"
        return 0
    elif [[ "${#found[@]}" -eq 0 ]]; then
        echo "ERROR: cannot auto-detect host tool; pass --tool <name>" >&2
        return 2
    else
        local list
        list="$(printf '%s, ' "${found[@]}")"
        list="${list%, }"
        echo "ERROR: ambiguous host tool (found: ${list}); pass --tool <name>" >&2
        return 2
    fi
}

# ---------------------------------------------------------------------------
# Version resolution (online)
# ---------------------------------------------------------------------------

# resolve_version - fetch the latest release tag from GitHub API.
# Prints the version without leading 'v'.  Exits 3 on failure.
resolve_version() {
    local url="${AID_API_BASE}/releases/latest"
    local curl_args=(-fsSL)
    # Optional bearer token for rate-limit relief.
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer ${token}")
    fi

    local response
    response="$(curl "${curl_args[@]}" "$url" 2>/dev/null)" || {
        echo "ERROR: aid-install-core: failed to fetch ${url}" >&2
        return 3
    }

    # Extract tag_name via grep+sed (no jq required).
    local tag
    tag="$(echo "$response" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
    if [[ -z "$tag" ]]; then
        echo "ERROR: aid-install-core: could not parse tag_name from GitHub API response" >&2
        return 3
    fi
    # Strip leading 'v'
    echo "${tag#v}"
}

# ---------------------------------------------------------------------------
# Fetch + extract (online mode)
# ---------------------------------------------------------------------------

# fetch_tarball <tool> <version> <dest_dir>
# Downloads the tarball + SHA256SUMS into dest_dir and verifies.
# Exits 3 on fetch failure, 4 on checksum mismatch.
fetch_tarball() {
    local tool="$1" version="$2" dest_dir="$3"
    local filename="aid-${tool}-v${version}.tar.gz"
    local url="${AID_DOWNLOAD_BASE}/v${version}/${filename}"
    local sums_url="${AID_DOWNLOAD_BASE}/v${version}/SHA256SUMS"
    local tarball="${dest_dir}/${filename}"
    local sums_file="${dest_dir}/SHA256SUMS"

    local curl_args=(-fsSL)
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer ${token}")
    fi

    echo "Fetching ${filename} ..." >&2
    curl "${curl_args[@]}" -o "$tarball" "$url" || {
        echo "ERROR: aid-install-core: failed to download ${url}" >&2
        return 3
    }

    # Fetch SHA256SUMS (best-effort: warn if absent on older releases).
    if curl "${curl_args[@]}" -o "$sums_file" "$sums_url" 2>/dev/null; then
        _verify_checksum "$tarball" "$sums_file" || return 4
    else
        echo "WARN: aid-install-core: SHA256SUMS not available for v${version}; skipping checksum verification" >&2
    fi
}

# _verify_checksum <tarball> <sums_file>
# Fails with exit 4 if the tarball's sha256 is not in the sums file.
_verify_checksum() {
    local tarball="$1" sums_file="$2"
    local filename
    filename="$(basename "$tarball")"

    local expected
    expected="$(grep "[[:space:]]${filename}$" "$sums_file" | awk '{print $1}')"
    if [[ -z "$expected" ]]; then
        echo "ERROR: aid-install-core: ${filename} not found in SHA256SUMS" >&2
        return 4
    fi

    local actual
    actual="$(sha256_file "$tarball")"
    if [[ "$actual" != "$expected" ]]; then
        echo "ERROR: aid-install-core: checksum mismatch for ${filename}: expected ${expected}, got ${actual}" >&2
        return 4
    fi
    echo "Checksum OK: ${filename}" >&2
}

# verify_bundle_checksum <tarball>
# Checks for a sibling SHA256SUMS file next to the tarball.
# No-op if absent; exits 4 on mismatch.
verify_bundle_checksum() {
    local tarball="$1"
    local dir
    dir="$(dirname "$tarball")"
    local sums_file="${dir}/SHA256SUMS"
    [[ -f "$sums_file" ]] || return 0
    _verify_checksum "$tarball" "$sums_file" || return 4
}

# extract_tarball <tarball> <dest_dir>
# Extracts into dest_dir.  feature-002 S2.3 guarantees a flat-root tarball (no
# wrapping top-level directory).  Asserts this contract and fails loudly when
# violated rather than silently stripping components.
extract_tarball() {
    local tarball="$1" dest_dir="$2"
    mkdir -p "$dest_dir"

    # Verify flat-root contract: the first entry must NOT be a bare directory
    # (i.e. must not be "somedir/" with no slash before the trailing slash at the
    # very start of the path component, e.g. "topdir/").
    # Use a temp file to avoid pipefail from SIGPIPE when piping tar -t to head.
    local _first_member_file
    _first_member_file="$(mktemp)"
    tar -tzf "$tarball" > "$_first_member_file" 2>/dev/null
    local _tar_list_rc=$?
    local first_member
    first_member="$(head -1 "$_first_member_file")"
    rm -f "$_first_member_file"

    if [[ "$_tar_list_rc" -ne 0 && -z "$first_member" ]]; then
        echo "ERROR: aid-install-core: failed to list tarball contents: ${tarball}" >&2
        return 1
    fi

    # A wrapping dir would look like "topdir/" (a single path component ending with /).
    # Pattern: starts with optional "./" then one path component (no inner slashes) then "/"
    # at the end of the string (meaning the entire entry IS just "topdir/").
    # "./topdir/" counts as a wrapping dir; "./.claude/file.md" does not.
    local _stripped="${first_member#./}"
    if [[ "$_stripped" =~ ^[^/]+/$ ]]; then
        echo "ERROR: aid-install-core: tarball has a wrapping top-level directory ('${first_member}') - expected flat-root per feature-002 S2.3 contract: ${tarball}" >&2
        return 1
    fi

    # Flat tarball (expected feature-002 layout).
    tar -xzf "$tarball" -C "$dest_dir" || {
        echo "ERROR: aid-install-core: failed to extract ${tarball}" >&2
        return 1
    }
}

# ---------------------------------------------------------------------------
# Copy semantics
# ---------------------------------------------------------------------------

# copy_file <src> <dst> [force]
# Returns 0 always (errors are logged).
# Prints per-file lines only when AID_VERBOSE=1.
# Increments counters: _COPY_COUNT_COPIED, _COPY_COUNT_UPTODATE, _COPY_COUNT_UPDATED,
#   _COPY_COUNT_SKIPPED (caller initialises before iterating; install_tool reads them).
# This function handles NON-root-agent files only.
# Root agent files go through _copy_root_agent_file in install_tool.
copy_file() {
    local src="$1" dst="$2" force="${3:-0}"
    local dst_dir
    dst_dir="$(dirname "$dst")"
    mkdir -p "$dst_dir"

    if [[ ! -e "$dst" ]]; then
        cp "$src" "$dst"
        _COPY_COUNT_COPIED=$((_COPY_COUNT_COPIED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"
        return 0
    fi

    if cmp -s "$src" "$dst"; then
        _COPY_COUNT_UPTODATE=$((_COPY_COUNT_UPTODATE + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Up to date: ${dst}"
        return 0
    fi

    # File exists and differs.
    if [[ "$force" -eq 1 ]]; then
        cp "$src" "$dst"
        _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst}"
    else
        _COPY_COUNT_SKIPPED=$((_COPY_COUNT_SKIPPED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Skipped (differs; use --force): ${dst}"
    fi
}

# copy_dir <src_dir> <dst_dir> [force]
# Recursively copies a directory tree, file by file (preserving empty dirs).
# Root agent files in the source dir are skipped - caller handles them.
copy_dir() {
    local src="$1" dst="$2" force="${3:-0}"

    # Create directory structure first.
    while IFS= read -r -d '' dir; do
        local rel="${dir#${src}/}"
        mkdir -p "${dst}/${rel}"
    done < <(find "$src" -mindepth 1 -type d -print0 2>/dev/null)

    # Copy files.
    while IFS= read -r -d '' file; do
        local rel="${file#${src}/}"
        copy_file "$file" "${dst}/${rel}" "$force"
    done < <(find "$src" -type f -print0 2>/dev/null | sort -z)
}

# ---------------------------------------------------------------------------
# Root agent file region update (Pillar 3)
# ---------------------------------------------------------------------------

# _copy_root_agent_file <src> <dst> <tool> <force> <manifest>
#
# Updates the root agent file (CLAUDE.md / AGENTS.md) using in-place region
# semantics.  Never writes a backup/sidecar file under any branch.
#
# Algorithm:
#   A. Dst absent              -> write full source (markers included).
#   B. Dst has AID:BEGIN/END   -> replace only the marked region; preserve all
#                                 content outside the markers verbatim.
#   C. Dst has no markers      -> migrate:
#      C1. Sha matches recorded manifest sha -> clean rewrite to full marked source.
#      C2. Sha mismatch        -> excise known AID-managed sections by stem match
#                                 (## Knowledge Base, ## Review output format,
#                                 ## Permissions -- tolerating trailing parenthetical
#                                 suffix on the heading) and re-insert them wrapped
#                                 in AID:BEGIN/END markers in place; preserve
#                                 ## Project / ## Project Overview and all other
#                                 user content.  No backup file is ever written.
#
# Returns:
#   0 - success (copied/up-to-date/updated)
#
# Sets _CORE_ROOT_AGENT_STATUS="owned" always (the .aid-new / pending-merge path
# is eliminated; all divergence is resolved in-place).
_copy_root_agent_file() {
    local src="$1" dst="$2" tool="$3" force="${4:-0}" manifest="${5:-}"

    _CORE_ROOT_AGENT_STATUS="owned"
    local src_sha
    src_sha="$(sha256_file "$src")"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    # ------------------------------------------------------------------
    # Branch A: destination absent -> write full source.
    # ------------------------------------------------------------------
    if [[ ! -e "$dst" ]]; then
        mkdir -p "$dst_dir"
        cp "$src" "$dst"
        _COPY_COUNT_COPIED=$((_COPY_COUNT_COPIED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"
        return 0
    fi

    local disk_sha
    disk_sha="$(sha256_file "$dst")"

    # Identical on disk -> nothing to do.
    if [[ "$disk_sha" == "$src_sha" ]]; then
        _COPY_COUNT_UPTODATE=$((_COPY_COUNT_UPTODATE + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Up to date: ${dst}"
        return 0
    fi

    # ------------------------------------------------------------------
    # Branch B: destination already has AID:BEGIN/END markers.
    # Replace only the marked region; preserve everything outside verbatim.
    # ------------------------------------------------------------------
    if grep -qF '<!-- AID:BEGIN -->' "$dst" 2>/dev/null; then
        # Extract the marked region from the source (inclusive of marker lines).
        local src_region
        src_region="$(awk '/^<!-- AID:BEGIN -->/{found=1} found{print} /^<!-- AID:END -->/{if(found){exit}}' "$src")"

        # Rebuild dst: output lines before the marker, then the new region,
        # then lines after the closing marker.
        local tmp
        tmp="$(mktemp "${dst_dir}/.aid-root-agent.XXXXXX")"
        awk -v region="$src_region" '
        BEGIN { in_aid=0; printed_region=0 }
        /^<!-- AID:BEGIN -->/ {
            if (!printed_region) {
                print region
                printed_region=1
            }
            in_aid=1
            next
        }
        in_aid && /^<!-- AID:END -->/ { in_aid=0; next }
        in_aid { next }
        { print }
        ' "$dst" > "$tmp"
        mv "$tmp" "$dst"

        _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst} (region replaced)"
        return 0
    fi

    # ------------------------------------------------------------------
    # Branch C: destination has no markers -- migration path.
    # ------------------------------------------------------------------

    # Read recorded sha from manifest (the sha AID last wrote to this file).
    local recorded_sha=""
    if [[ -n "$manifest" && -f "$manifest" ]]; then
        recorded_sha="$(manifest_read_root_agent "$manifest" "$tool" "$(basename "$dst")")"
    fi

    # C1: sha still matches the AID-recorded value -> clean rewrite.
    if [[ -n "$recorded_sha" && "$disk_sha" == "$recorded_sha" ]]; then
        cp "$src" "$dst"
        _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst} (migrated: clean rewrite)"
        return 0
    fi

    # C2: sha mismatch (user has edited the file) -> excise AID sections by
    # stem match and re-insert as a marked region.
    #
    # AID section stems to excise (exact heading stem; tolerate trailing
    # parenthetical like " (global)" or " (IMPERATIVE)"):
    #   ## Knowledge Base
    #   ## Review output format
    #   ## Permissions
    #   ## Tracking discipline
    #
    # A section runs from its "## Stem..." heading line until the next "## "
    # heading (exclusive) or end-of-file.
    #
    # The new marked region (from the source) is inserted at the position of
    # the first excised section.  All other content (## Project, user sections)
    # is preserved verbatim.

    # Extract the new marked region from source.
    local new_region
    new_region="$(awk '/^<!-- AID:BEGIN -->/{found=1} found{print} /^<!-- AID:END -->/{if(found){exit}}' "$src")"

    local tmp
    tmp="$(mktemp "${dst_dir}/.aid-root-agent.XXXXXX")"

    # Use awk to perform the excise-and-reinsert in one pass.
    # The awk script:
    #   - Identifies AID-managed section headings by stem prefix match.
    #   - Suppresses those sections (and their body lines).
    #   - At the position of the first suppressed section, emits the new region.
    #   - All other lines are emitted verbatim.
    awk -v new_region="$new_region" '
    function is_aid_heading(line,    stem) {
        # Match "## StemText" optionally followed by " (anything)".
        # Stems: Knowledge Base, Review output format, Permissions,
        #        Tracking discipline.
        if (line !~ /^## /) return 0
        stem = line
        gsub(/^## /, "", stem)
        # Strip trailing parenthetical suffix: " (..." -> ""
        gsub(/ \([^)]*\)$/, "", stem)
        if (stem == "Knowledge Base") return 1
        if (stem == "Review output format") return 1
        if (stem == "Permissions") return 1
        if (stem == "Tracking discipline") return 1
        return 0
    }
    BEGIN {
        in_aid_section=0
        region_inserted=0
    }
    /^## / {
        if (is_aid_heading($0)) {
            # Start suppressing this AID section.
            in_aid_section=1
            # Insert the new marked region at the first AID section position.
            if (!region_inserted) {
                print new_region
                region_inserted=1
            }
            next
        } else {
            # A non-AID heading ends any current AID section suppression.
            in_aid_section=0
        }
    }
    in_aid_section { next }
    { print }
    END {
        # No AID section existed to anchor the region (a brownfield file with no
        # prior AID content) -> append the marked region at end of file. Without
        # this the AID block would be silently dropped and the file never gains
        # AID instructions.
        if (!region_inserted) {
            print ""
            print new_region
        }
    }
    ' "$dst" > "$tmp"

    mv "$tmp" "$dst"

    _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst} (migrated: AID sections re-wrapped in markers)"
    return 0
}

# ---------------------------------------------------------------------------
# Manifest - pure-Bash reader (no jq/python required)
# ---------------------------------------------------------------------------
#
# The manifest has this shape (2-space indent, \n newlines):
# {
#   "manifest_version": 1,
#   "aid_version": "0.7.0",
#   "installed_at": "...",
#   "tools": {
#     "claude-code": {
#       "version": "0.7.0",
#       "installed_at": "...",
#       "paths": ["..."],
#       "root_agent_files": [{"path": "...", "sha256": "...", "status": "owned"}]
#     }
#   }
# }
#
# Readers use grep/sed/awk to extract what they need - sufficient because the
# schema is flat enough.

# manifest_read_tool_paths <manifest> <tool>
# Prints one path per line (from the "paths" array of the named tool section).
manifest_read_tool_paths() {
    local manifest="$1" tool="$2"
    [[ -f "$manifest" ]] || return 0
    # Fast path: python3
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" "$tool" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for p in data.get("tools", {}).get(sys.argv[2], {}).get("paths", []):
        print(p)
except Exception:
    pass
PY
        return
    fi
    # Pure-Bash fallback: extract section between "tool": { ... } and next top-level "tool":
    # Use awk to capture paths array lines for the target tool.
    awk -v tool="$tool" '
    BEGIN { in_tool=0; in_paths=0 }
    /"'"${tool}"'"[[:space:]]*:/ { in_tool=1; next }
    in_tool && /"paths"[[:space:]]*:/ { in_paths=1; next }
    in_tool && in_paths && /\]/ { exit }
    in_tool && in_paths && /"[^"]*"/ {
        # Extract the quoted string.
        s=$0; gsub(/^[^"]*"/, "", s); gsub(/".*/, "", s)
        if (s != "") print s
    }
    ' "$manifest"
}

# manifest_read_tool_version <manifest> <tool>
# Prints the version string for the named tool.
manifest_read_tool_version() {
    local manifest="$1" tool="$2"
    [[ -f "$manifest" ]] || return 0
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" "$tool" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    v = data.get("tools", {}).get(sys.argv[2], {}).get("version", "")
    if v: print(v)
except Exception:
    pass
PY
        return
    fi
    # Pure-Bash: find version line inside the tool block.
    awk -v tool="$tool" '
    BEGIN { in_tool=0; depth=0 }
    /"'"${tool}"'"[[:space:]]*:/ { in_tool=1; depth=0; next }
    in_tool && /\{/ { depth++ }
    in_tool && /\}/ { depth--; if (depth<0) exit }
    in_tool && depth==1 && /"version"/ {
        s=$0; gsub(/.*"version"[^:]*:[^"]*"/, "", s); gsub(/".*/, "", s)
        print s; exit
    }
    ' "$manifest"
}

# manifest_read_root_agent <manifest> <tool> <filename>
# Prints the sha256 for the root agent file entry (empty if not present).
manifest_read_root_agent() {
    local manifest="$1" tool="$2" fname="$3"
    [[ -f "$manifest" ]] || return 0
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" "$tool" "$fname" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for e in data.get("tools", {}).get(sys.argv[2], {}).get("root_agent_files", []):
        if e.get("path") == sys.argv[3]:
            print(e.get("sha256", ""))
            break
except Exception:
    pass
PY
        return
    fi
    # Pure-Bash: find root_agent_files section for tool, look for fname.
    awk -v tool="$tool" -v fname="$fname" '
    BEGIN { in_tool=0; in_raf=0; in_entry=0; found_path=0 }
    /"'"${tool}"'"[[:space:]]*:/ { in_tool=1 }
    in_tool && /"root_agent_files"/ { in_raf=1 }
    in_raf && /\{/ { in_entry=1; found_path=0 }
    in_raf && in_entry && /"path"/ {
        s=$0; gsub(/.*"path"[^:]*:[^"]*"/, "", s); gsub(/".*/, "", s)
        if (s == fname) found_path=1
    }
    in_raf && in_entry && found_path && /"sha256"/ {
        s=$0; gsub(/.*"sha256"[^:]*:[^"]*"/, "", s); gsub(/".*/, "", s)
        print s; exit
    }
    in_raf && /\]/ { exit }
    ' "$manifest"
}

# manifest_read_root_agent_status <manifest> <tool> <filename>
# Prints the status field ("owned" or "pending-merge") for the root agent entry.
manifest_read_root_agent_status() {
    local manifest="$1" tool="$2" fname="$3"
    [[ -f "$manifest" ]] || return 0
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" "$tool" "$fname" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for e in data.get("tools", {}).get(sys.argv[2], {}).get("root_agent_files", []):
        if e.get("path") == sys.argv[3]:
            print(e.get("status", "owned"))
            break
except Exception:
    pass
PY
        return
    fi
    awk -v tool="$tool" -v fname="$fname" '
    BEGIN { in_tool=0; in_raf=0; in_entry=0; found_path=0 }
    /"'"${tool}"'"[[:space:]]*:/ { in_tool=1 }
    in_tool && /"root_agent_files"/ { in_raf=1 }
    in_raf && /\{/ { in_entry=1; found_path=0 }
    in_raf && in_entry && /"path"/ {
        s=$0; gsub(/.*"path"[^:]*:[^"]*"/, "", s); gsub(/".*/, "", s)
        if (s == fname) found_path=1
    }
    in_raf && in_entry && found_path && /"status"/ {
        s=$0; gsub(/.*"status"[^:]*:[^"]*"/, "", s); gsub(/".*/, "", s)
        print s; exit
    }
    in_raf && /\]/ { exit }
    ' "$manifest"
}

# ---------------------------------------------------------------------------
# Manifest writer (pure Bash + python3 fast-path)
# ---------------------------------------------------------------------------

# manifest_write <manifest_path> <tool> <version> <paths_varname> <root_entries_varname>
#
# <paths_varname>        - name of a Bash array variable holding relative POSIX paths.
# <root_entries_varname> - name of a Bash array variable holding entries, each formatted as
#                          "path|sha256|status" (pipe-delimited).
#
# Reads the existing manifest (if any), merges the tool's entry, writes back atomically
# via a temp file.  Creates <target>/.aid/ as needed.
manifest_write() {
    local manifest="$1" tool="$2" version="$3"
    local paths_var="$4"       # indirect reference to array
    local root_var="$5"        # indirect reference to array

    # Dereference array variables (Bash 4.3+ nameref or indirect via eval).
    local -a paths_arr=()
    local -a root_arr=()
    eval "paths_arr=(\"\${${paths_var}[@]}\")"
    eval "root_arr=(\"\${${root_var}[@]}\")"

    local manifest_dir
    manifest_dir="$(dirname "$manifest")"
    mkdir -p "$manifest_dir"

    local now
    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    if command -v python3 >/dev/null 2>&1; then
        _manifest_write_python "$manifest" "$tool" "$version" "$now" "${paths_arr[@]+"${paths_arr[@]}"}" -- "${root_arr[@]+"${root_arr[@]}"}"
    else
        _manifest_write_bash "$manifest" "$tool" "$version" "$now" "${paths_arr[@]+"${paths_arr[@]}"}" -- "${root_arr[@]+"${root_arr[@]}"}"
    fi
}

# _manifest_write_python - write manifest via python3 (fast path).
# Signature: <manifest> <tool> <version> <now> [paths...] -- [root_entries...]
_manifest_write_python() {
    local manifest="$1" tool="$2" version="$3" now="$4"
    shift 4

    local -a paths_arr=()
    local -a root_arr=()
    local past_sep=0
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            past_sep=1
            continue
        fi
        if [[ "$past_sep" -eq 0 ]]; then
            paths_arr+=("$arg")
        else
            root_arr+=("$arg")
        fi
    done

    python3 - "$manifest" "$tool" "$version" "$now" \
        "$(printf '%s\n' "${paths_arr[@]+"${paths_arr[@]}"}")" \
        "$(printf '%s\n' "${root_arr[@]+"${root_arr[@]}"}")" <<'PY'
import json, sys, os, tempfile

manifest_path = sys.argv[1]
tool          = sys.argv[2]
version       = sys.argv[3]
now           = sys.argv[4]
paths_raw     = sys.argv[5]
roots_raw     = sys.argv[6]

paths = [p for p in paths_raw.splitlines() if p]
roots = []
for line in roots_raw.splitlines():
    if not line:
        continue
    parts = line.split("|", 2)
    entry = {"path": parts[0], "sha256": parts[1] if len(parts) > 1 else "",
             "status": parts[2] if len(parts) > 2 else "owned"}
    roots.append(entry)

# Load existing manifest.
data = {}
if os.path.isfile(manifest_path):
    try:
        with open(manifest_path) as f:
            data = json.load(f)
    except Exception:
        data = {}

if not isinstance(data.get("tools"), dict):
    data["tools"] = {}

# Merge: preserve existing installed_at for the tool if present.
existing_tool = data["tools"].get(tool, {})
tool_installed_at = existing_tool.get("installed_at", now)

# De-duplicate paths (union).
existing_paths = existing_tool.get("paths", [])
merged_paths = list(dict.fromkeys(existing_paths + paths))

# Merge root_agent_files: update or add per path.
existing_raf = {e["path"]: e for e in existing_tool.get("root_agent_files", [])}
for e in roots:
    existing_raf[e["path"]] = e
merged_raf = list(existing_raf.values())

data["tools"][tool] = {
    "version": version,
    "installed_at": tool_installed_at,
    "paths": merged_paths,
    "root_agent_files": merged_raf,
}

# Build output with canonical key order.
top_installed_at = data.get("installed_at", now)
output = {
    "manifest_version": 1,
    "aid_version": version,
    "installed_at": top_installed_at,
    "tools": data["tools"],
}
data = output

# Write atomically.
manifest_dir = os.path.dirname(manifest_path)
fd, tmp = tempfile.mkstemp(dir=manifest_dir, suffix=".tmp")
try:
    with os.fdopen(fd, "w", newline="\n") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, manifest_path)
except Exception as e:
    os.unlink(tmp)
    print(f"ERROR: aid-install-core: manifest write failed: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# _manifest_write_bash - pure-Bash fallback manifest writer.
# Signature same as _manifest_write_python.
_manifest_write_bash() {
    local manifest="$1" tool="$2" version="$3" now="$4"
    shift 4

    local -a paths_arr=()
    local -a root_arr=()
    local past_sep=0
    for arg in "$@"; do
        if [[ "$arg" == "--" ]]; then
            past_sep=1
            continue
        fi
        if [[ "$past_sep" -eq 0 ]]; then
            paths_arr+=("$arg")
        else
            root_arr+=("$arg")
        fi
    done

    local manifest_dir
    manifest_dir="$(dirname "$manifest")"

    # Load existing manifest fields we need to preserve.
    local top_installed_at="$now"
    local tool_installed_at="$now"
    local -a existing_paths=()
    local existing_aid_version=""

    if [[ -f "$manifest" ]]; then
        top_installed_at="$(grep '"installed_at"' "$manifest" | head -1 | sed 's/.*"installed_at"[^:]*:[^"]*"\([^"]*\)".*/\1/')"
        [[ -z "$top_installed_at" ]] && top_installed_at="$now"

        # Collect existing paths for this tool.
        while IFS= read -r p; do
            [[ -n "$p" ]] && existing_paths+=("$p")
        done < <(manifest_read_tool_paths "$manifest" "$tool")

        local t_inst
        t_inst="$(manifest_read_tool_version "$manifest" "$tool")"
        # Read tool-specific installed_at (reuse existing or now).
        tool_installed_at="$(awk -v tool="$tool" '
        BEGIN{in_tool=0}
        /"'"${tool}"'"/{in_tool=1}
        in_tool && /"installed_at"/{
            s=$0; gsub(/.*"installed_at"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); print s; exit
        }' "$manifest")"
        [[ -z "$tool_installed_at" ]] && tool_installed_at="$now"
    fi

    # Merge paths (de-duplicate).
    local -a merged_paths=()
    declare -A _seen_paths=()
    for p in "${existing_paths[@]+"${existing_paths[@]}"}" "${paths_arr[@]+"${paths_arr[@]}"}"; do
        if [[ -z "${_seen_paths[$p]+x}" ]]; then
            _seen_paths[$p]=1
            merged_paths+=("$p")
        fi
    done

    # Assemble paths JSON array.
    local paths_json="["
    local first=1
    for p in "${merged_paths[@]+"${merged_paths[@]}"}"; do
        [[ "$first" -eq 0 ]] && paths_json+=","
        paths_json+=$'\n        "'
        paths_json+="$p"
        paths_json+='"'
        first=0
    done
    if [[ "${#merged_paths[@]}" -gt 0 ]]; then
        paths_json+=$'\n      '
    fi
    paths_json+="]"

    # Assemble root_agent_files JSON array.
    # Merge with existing entries.
    local -a all_root=()
    if [[ -f "$manifest" ]]; then
        # Read existing root_agent_files for this tool from manifest.
        local _existing_raf_paths=()
        while IFS= read -r _raf_line; do
            [[ -n "$_raf_line" ]] && _existing_raf_paths+=("$_raf_line")
        done < <(awk -v tool="$tool" '
        BEGIN{in_tool=0;in_raf=0;in_entry=0}
        /"'"${tool}"'"[[:space:]]*:/{in_tool=1}
        in_tool && /"root_agent_files"/{in_raf=1}
        in_raf && /\{/{in_entry=1; cur_path=""; cur_sha=""; cur_status="owned"}
        in_raf && in_entry && /"path"/{
            s=$0; gsub(/.*"path"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_path=s
        }
        in_raf && in_entry && /"sha256"/{
            s=$0; gsub(/.*"sha256"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_sha=s
        }
        in_raf && in_entry && /"status"/{
            s=$0; gsub(/.*"status"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_status=s
        }
        in_raf && in_entry && /\}/ {
            if (cur_path!="") print cur_path "|" cur_sha "|" cur_status
            in_entry=0
        }
        in_raf && /\]/{exit}
        ' "$manifest")

        # Build map of existing entries.
        declare -A _raf_map=()
        for _entry in "${_existing_raf_paths[@]+"${_existing_raf_paths[@]}"}"; do
            local _k="${_entry%%|*}"
            _raf_map["$_k"]="$_entry"
        done
        # Override with incoming entries.
        for _entry in "${root_arr[@]+"${root_arr[@]}"}"; do
            local _k="${_entry%%|*}"
            _raf_map["$_k"]="$_entry"
        done
        for _k in "${!_raf_map[@]}"; do
            all_root+=("${_raf_map[$_k]}")
        done
    else
        all_root=("${root_arr[@]+"${root_arr[@]}"}")
    fi

    local raf_json="["
    local first=1
    for entry in "${all_root[@]+"${all_root[@]}"}"; do
        local rpath rsha rstatus
        IFS='|' read -r rpath rsha rstatus <<< "$entry"
        [[ "$first" -eq 0 ]] && raf_json+=","
        raf_json+=$'\n        '
        raf_json+='{ "path": "'"${rpath}"'", "sha256": "'"${rsha}"'", "status": "'"${rstatus}"'" }'
        first=0
    done
    if [[ "${#all_root[@]}" -gt 0 ]]; then
        raf_json+=$'\n      '
    fi
    raf_json+="]"

    # Read all existing tools to preserve them.
    local -a all_tool_ids=()
    if [[ -f "$manifest" ]]; then
        while IFS= read -r tid; do
            [[ -n "$tid" && "$tid" != "$tool" ]] && all_tool_ids+=("$tid")
        done < <(grep -o '"[a-z][a-zA-Z-]*"[[:space:]]*:' "$manifest" | \
                 grep -v 'manifest_version\|aid_version\|installed_at\|version\|paths\|root_agent_files\|sha256\|status\|path\|tools' | \
                 sed 's/"//g' | sed 's/[[:space:]]*://g')
    fi

    # Assemble complete manifest JSON.
    local tmp_file
    tmp_file="$(mktemp "${manifest_dir}/.manifest.tmp.XXXXXX")"

    {
        printf '{\n'
        printf '  "manifest_version": 1,\n'
        printf '  "aid_version": "%s",\n' "$version"
        printf '  "installed_at": "%s",\n' "$top_installed_at"
        printf '  "tools": {\n'

        # Write other tools first (preserve existing).
        local need_comma=0
        for tid in "${all_tool_ids[@]+"${all_tool_ids[@]}"}"; do
            # Re-serialize existing tool block.
            if [[ "$need_comma" -eq 1 ]]; then printf ',\n'; fi
            local t_ver t_iat
            t_ver="$(manifest_read_tool_version "$manifest" "$tid")"
            t_iat="$(awk -v t="$tid" 'BEGIN{in_t=0} /"'"${tid}"'"/{in_t=1} in_t && /"installed_at"/{s=$0; gsub(/.*"installed_at"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); print s; exit}' "$manifest")"
            [[ -z "$t_iat" ]] && t_iat="$now"
            printf '    "%s": {\n' "$tid"
            printf '      "version": "%s",\n' "$t_ver"
            printf '      "installed_at": "%s",\n' "$t_iat"
            # Re-read and emit paths for existing tool.
            local t_paths_json="["
            local tp_first=1
            while IFS= read -r tp; do
                [[ -z "$tp" ]] && continue
                [[ "$tp_first" -eq 0 ]] && t_paths_json+=","
                t_paths_json+=$'\n        "'
                t_paths_json+="$tp"
                t_paths_json+='"'
                tp_first=0
            done < <(manifest_read_tool_paths "$manifest" "$tid")
            [[ "$tp_first" -eq 0 ]] && t_paths_json+=$'\n      '
            t_paths_json+="]"
            printf '      "paths": %s,\n' "$t_paths_json"
            # Re-read root_agent_files for existing tool using the awk RAF parser.
            local t_raf_json="["
            local tr_first=1
            local -a _t_raf_lines=()
            while IFS= read -r _t_raf_line; do
                [[ -n "$_t_raf_line" ]] && _t_raf_lines+=("$_t_raf_line")
            done < <(awk -v tool="$tid" '
            BEGIN{in_tool=0;in_raf=0;in_entry=0}
            /"'"${tid}"'"[[:space:]]*:/{in_tool=1}
            in_tool && /"root_agent_files"/{in_raf=1}
            in_raf && /\{/{in_entry=1; cur_path=""; cur_sha=""; cur_status="owned"}
            in_raf && in_entry && /"path"/{
                s=$0; gsub(/.*"path"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_path=s
            }
            in_raf && in_entry && /"sha256"/{
                s=$0; gsub(/.*"sha256"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_sha=s
            }
            in_raf && in_entry && /"status"/{
                s=$0; gsub(/.*"status"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_status=s
            }
            in_raf && in_entry && /\}/ {
                if (cur_path!="") print cur_path "|" cur_sha "|" cur_status
                in_entry=0
            }
            in_raf && /\]/{exit}
            ' "$manifest")
            for _t_entry in "${_t_raf_lines[@]+"${_t_raf_lines[@]}"}"; do
                local _t_rpath _t_rsha _t_rstatus
                IFS='|' read -r _t_rpath _t_rsha _t_rstatus <<< "$_t_entry"
                [[ "$tr_first" -eq 0 ]] && t_raf_json+=","
                t_raf_json+=$'\n        '
                t_raf_json+='{ "path": "'"${_t_rpath}"'", "sha256": "'"${_t_rsha}"'", "status": "'"${_t_rstatus}"'" }'
                tr_first=0
            done
            if [[ "${#_t_raf_lines[@]}" -gt 0 ]]; then
                t_raf_json+=$'\n      '
            fi
            t_raf_json+="]"
            printf '      "root_agent_files": %s\n' "$t_raf_json"
            printf '    }'
            need_comma=1
        done

        # Write the current tool.
        if [[ "$need_comma" -eq 1 ]]; then printf ',\n'; fi
        printf '    "%s": {\n' "$tool"
        printf '      "version": "%s",\n' "$version"
        printf '      "installed_at": "%s",\n' "$tool_installed_at"
        printf '      "paths": %s,\n' "$paths_json"
        printf '      "root_agent_files": %s\n' "$raf_json"
        printf '    }\n'

        printf '  }\n'
        printf '}\n'
    } > "$tmp_file"

    mv "$tmp_file" "$manifest"
}

# manifest_remove_tool <manifest> <tool>
# Removes a tool's section from the manifest.  If no tools remain, removes the manifest.
manifest_remove_tool() {
    local manifest="$1" tool="$2"
    [[ -f "$manifest" ]] || return 0

    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" "$tool" <<'PY'
import json, sys, os, tempfile

manifest_path = sys.argv[1]
tool          = sys.argv[2]

try:
    with open(manifest_path) as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

tools = data.get("tools", {})
tools.pop(tool, None)
data["tools"] = tools

if not tools:
    os.remove(manifest_path)
    sys.exit(0)

manifest_dir = os.path.dirname(manifest_path)
fd, tmp = tempfile.mkstemp(dir=manifest_dir, suffix=".tmp")
try:
    with os.fdopen(fd, "w", newline="\n") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    os.replace(tmp, manifest_path)
except Exception as e:
    os.unlink(tmp)
    print(f"ERROR: manifest remove failed: {e}", file=sys.stderr)
    sys.exit(1)
PY
    else
        # Pure-Bash: re-read all other tools and write a new manifest.
        # Collect remaining tool ids.
        local -a remaining=()
        while IFS= read -r tid; do
            [[ -n "$tid" && "$tid" != "$tool" ]] && remaining+=("$tid")
        done < <(awk '/"tools"/{found=1} found && /^    "[a-z]/{gsub(/[^a-zA-Z-]/,"",$1); print $1}' "$manifest" | sort -u)

        if [[ "${#remaining[@]}" -eq 0 ]]; then
            rm -f "$manifest"
            return
        fi

        # Rebuild the manifest with only remaining tools.
        local now
        now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        local top_iat
        top_iat="$(grep '"installed_at"' "$manifest" | head -1 | sed 's/.*"installed_at"[^:]*:[^"]*"\([^"]*\)".*/\1/')"
        [[ -z "$top_iat" ]] && top_iat="$now"
        local last_ver
        last_ver="$(grep '"aid_version"' "$manifest" | head -1 | sed 's/.*"aid_version"[^:]*:[^"]*"\([^"]*\)".*/\1/')"
        [[ -z "$last_ver" ]] && last_ver="0.0.0"

        local tmp_file
        tmp_file="$(mktemp "$(dirname "$manifest")/.manifest.tmp.XXXXXX")"
        {
            printf '{\n'
            printf '  "manifest_version": 1,\n'
            printf '  "aid_version": "%s",\n' "$last_ver"
            printf '  "installed_at": "%s",\n' "$top_iat"
            printf '  "tools": {\n'
            local need_comma=0
            for tid in "${remaining[@]}"; do
                [[ "$need_comma" -eq 1 ]] && printf ',\n'
                local t_ver t_iat
                t_ver="$(manifest_read_tool_version "$manifest" "$tid")"
                t_iat="$(awk -v t="$tid" 'BEGIN{in_t=0} /"'"${tid}"'"/{in_t=1} in_t && /"installed_at"/{s=$0; gsub(/.*"installed_at"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); print s; exit}' "$manifest")"
                [[ -z "$t_iat" ]] && t_iat="$now"
                printf '    "%s": {\n' "$tid"
                printf '      "version": "%s",\n' "$t_ver"
                printf '      "installed_at": "%s",\n' "$t_iat"
                # Re-read paths for this tool.
                local rm_paths_json="["
                local rm_tp_first=1
                while IFS= read -r rm_tp; do
                    [[ -z "$rm_tp" ]] && continue
                    [[ "$rm_tp_first" -eq 0 ]] && rm_paths_json+=","
                    rm_paths_json+=$'\n        "'
                    rm_paths_json+="$rm_tp"
                    rm_paths_json+='"'
                    rm_tp_first=0
                done < <(manifest_read_tool_paths "$manifest" "$tid")
                [[ "$rm_tp_first" -eq 0 ]] && rm_paths_json+=$'\n      '
                rm_paths_json+="]"
                printf '      "paths": %s,\n' "$rm_paths_json"
                # Re-read root_agent_files for this tool using the awk RAF parser.
                local rm_raf_json="["
                local rm_tr_first=1
                local -a _rm_raf_lines=()
                while IFS= read -r _rm_raf_line; do
                    [[ -n "$_rm_raf_line" ]] && _rm_raf_lines+=("$_rm_raf_line")
                done < <(awk -v tool="$tid" '
                BEGIN{in_tool=0;in_raf=0;in_entry=0}
                /"'"${tid}"'"[[:space:]]*:/{in_tool=1}
                in_tool && /"root_agent_files"/{in_raf=1}
                in_raf && /\{/{in_entry=1; cur_path=""; cur_sha=""; cur_status="owned"}
                in_raf && in_entry && /"path"/{
                    s=$0; gsub(/.*"path"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_path=s
                }
                in_raf && in_entry && /"sha256"/{
                    s=$0; gsub(/.*"sha256"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_sha=s
                }
                in_raf && in_entry && /"status"/{
                    s=$0; gsub(/.*"status"[^:]*:[^"]*"/,"",s); gsub(/".*$/,"",s); cur_status=s
                }
                in_raf && in_entry && /\}/ {
                    if (cur_path!="") print cur_path "|" cur_sha "|" cur_status
                    in_entry=0
                }
                in_raf && /\]/{exit}
                ' "$manifest")
                for _rm_entry in "${_rm_raf_lines[@]+"${_rm_raf_lines[@]}"}"; do
                    local _rm_rpath _rm_rsha _rm_rstatus
                    IFS='|' read -r _rm_rpath _rm_rsha _rm_rstatus <<< "$_rm_entry"
                    [[ "$rm_tr_first" -eq 0 ]] && rm_raf_json+=","
                    rm_raf_json+=$'\n        '
                    rm_raf_json+='{ "path": "'"${_rm_rpath}"'", "sha256": "'"${_rm_rsha}"'", "status": "'"${_rm_rstatus}"'" }'
                    rm_tr_first=0
                done
                if [[ "${#_rm_raf_lines[@]}" -gt 0 ]]; then
                    rm_raf_json+=$'\n      '
                fi
                rm_raf_json+="]"
                printf '      "root_agent_files": %s\n' "$rm_raf_json"
                printf '    }'
                need_comma=1
            done
            printf '\n  }\n'
            printf '}\n'
        } > "$tmp_file"
        mv "$tmp_file" "$manifest"
    fi
}

# manifest_list_tools <manifest>
# Prints each installed tool id (one per line) from tools.<id> keys.
# Exits 0 even when the manifest is absent (prints nothing).
manifest_list_tools() {
    local manifest="$1"
    [[ -f "$manifest" ]] || return 0
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    for t in data.get("tools", {}).keys():
        print(t)
except Exception:
    pass
PY
        return
    fi
    # Pure-Bash fallback: extract tool keys from the "tools" section.
    # Each tool entry looks like:    "tool-name": {  at 4-space indent.
    awk '
    BEGIN { in_tools=0; depth=0 }
    /"tools"[[:space:]]*:/ { in_tools=1; depth=0; next }
    in_tools && /\{/ { depth++ }
    in_tools && /\}/ { depth--; if (depth<=0) exit }
    in_tools && depth==1 && /^    "[a-z][a-zA-Z-]*"[[:space:]]*:/ {
        s=$0; gsub(/^[[:space:]]*"/, "", s); gsub(/".*/, "", s)
        if (s != "") print s
    }
    ' "$manifest"
}

# ---------------------------------------------------------------------------
# Semver comparison helpers
# ---------------------------------------------------------------------------

# _semver_lt <a> <b>
# Returns 0 (true) when version a < version b using simple numeric major.minor.patch
# comparison.  Non-numeric segments are treated as 0.  Returns 1 when a >= b.
_semver_lt() {
    local a="$1" b="$2"
    local -a pa=() pb=()
    IFS='.' read -ra pa <<< "$a"
    IFS='.' read -ra pb <<< "$b"
    local i
    for i in 0 1 2; do
        local va="${pa[$i]:-0}" vb="${pb[$i]:-0}"
        # Strip non-numeric suffixes (e.g. "1-rc1" -> "1").
        va="${va%%[^0-9]*}"
        vb="${vb%%[^0-9]*}"
        [[ -z "$va" ]] && va=0
        [[ -z "$vb" ]] && vb=0
        if (( va < vb )); then return 0; fi
        if (( va > vb )); then return 1; fi
    done
    return 1  # equal -> not less than
}

# ---------------------------------------------------------------------------
# Shared tool-list renderer (used by both aid_status_body and aid_status)
# ---------------------------------------------------------------------------

# _render_tools_block <manifest> <ref_version> <header_prefix>
#
# <manifest>       - path to the .aid-manifest.json
# <ref_version>    - the CLI's own version (from $AID_HOME/VERSION)
# <header_prefix>  - text before the "- all at vX:" collapse suffix (e.g.
#                    "Installed tools (in /path)" or "Installed tools")
#
# Outputs the complete tools block:
#   - uniform case:  "<header_prefix> - all at v<V>[update hint]:\n  <tool>\n..."
#   - divergent case: "<header_prefix>:\n  <tool>   v<ver>[update hint]\n..."
# Root-agent annotation only when status != "owned".
_render_tools_block() {
    local manifest="$1"
    local ref_version="$2"
    local header_prefix="$3"

    # Enumerate tools (sorted by insertion order from manifest).
    local -a tools=()
    while IFS= read -r t; do
        [[ -n "$t" ]] && tools+=("$t")
    done < <(manifest_list_tools "$manifest")

    if [[ "${#tools[@]}" -eq 0 ]]; then
        # Nothing to show - shouldn't happen if manifest exists, but safe guard.
        printf '%s:\n' "$header_prefix"
        return 0
    fi

    # Collect per-tool version + root-agent status.
    local -a tool_vers=()
    local -a tool_rstatus=()
    for tool_id in "${tools[@]}"; do
        local ver
        ver="$(manifest_read_tool_version "$manifest" "$tool_id")"
        tool_vers+=("${ver:-}")
        local root_agent
        root_agent="$(_root_agent_file "$tool_id")"
        local root_status=""
        if [[ -n "$root_agent" ]]; then
            root_status="$(manifest_read_root_agent_status "$manifest" "$tool_id" "$root_agent")"
        fi
        tool_rstatus+=("${root_status:-owned}")
    done

    # Determine uniform vs divergent.
    local first_ver="${tool_vers[0]:-}"
    local uniform=1
    local ver
    for ver in "${tool_vers[@]}"; do
        if [[ "$ver" != "$first_ver" ]]; then
            uniform=0
            break
        fi
    done

    if [[ "$uniform" -eq 1 ]]; then
        # Uniform case.
        local hint=""
        if [[ -n "$ref_version" && -n "$first_ver" ]] && _semver_lt "$first_ver" "$ref_version"; then
            hint=" (update -> v${ref_version})"
        fi
        printf '%s - all at v%s%s:\n' "$header_prefix" "$first_ver" "$hint"
        local idx=0
        for tool_id in "${tools[@]}"; do
            local rs="${tool_rstatus[$idx]}"
            local extra=""
            if [[ "$rs" != "owned" && -n "$rs" ]]; then
                extra="  (root pending merge)"
            fi
            printf '  %s%s\n' "$tool_id" "$extra"
            # --verbose: also show file count
            if [[ "${AID_VERBOSE:-0}" == "1" ]]; then
                local count=0
                while IFS= read -r _p; do
                    [[ -n "$_p" ]] && count=$((count + 1))
                done < <(manifest_read_tool_paths "$manifest" "$tool_id")
                printf '                 (%d files installed)\n' "$count"
            fi
            idx=$((idx + 1))
        done
    else
        # Divergent case.
        printf '%s:\n' "$header_prefix"
        local idx=0
        for tool_id in "${tools[@]}"; do
            local ver="${tool_vers[$idx]}"
            local rs="${tool_rstatus[$idx]}"
            local hint=""
            if [[ -n "$ref_version" && -n "$ver" ]] && _semver_lt "$ver" "$ref_version"; then
                hint="  (update -> v${ref_version})"
            fi
            local root_extra=""
            if [[ "$rs" != "owned" && -n "$rs" ]]; then
                root_extra="  (root pending merge)"
            fi
            # Pad tool id to 14 chars for alignment.
            local line
            printf -v line '  %-14s v%s%s%s' "$tool_id" "$ver" "$hint" "$root_extra"
            printf '%s\n' "$line"
            # --verbose: also show file count
            if [[ "${AID_VERBOSE:-0}" == "1" ]]; then
                local count=0
                while IFS= read -r _p; do
                    [[ -n "$_p" ]] && count=$((count + 1))
                done < <(manifest_read_tool_paths "$manifest" "$tool_id")
                printf '                 (%d files installed)\n' "$count"
            fi
            idx=$((idx + 1))
        done
    fi
    return 0
}

# aid_status_body <target>
# Renders only the installed-tools block for an AID project rooted at <target>.
# Caller is responsible for checking whether a manifest exists first.
# Prints:
#   Installed tools (in <cwd>) - all at v<V>[hint]:
#   <per-tool lines (name-only when uniform)>
# OR (divergent):
#   Installed tools (in <cwd>):
#   <per-tool lines with version + hint>
# OR (when no manifest):
#   No AID tools installed in <cwd> yet - run 'aid add <tool>'.
# Returns:
#   0 - always (no exit-7; caller decides what to do on missing manifest)
aid_status_body() {
    local target="${1:-.}"
    local manifest="${target}/.aid/.aid-manifest.json"
    local cwd_display
    cwd_display="$(cd "$target" && pwd)"

    if [[ ! -f "$manifest" ]] || ! grep -q '"manifest_version"' "$manifest" 2>/dev/null; then
        printf "No AID tools installed in %s yet - run 'aid add <tool>'.\n" "$cwd_display"
        return 0
    fi

    # Read CLI ref version from $AID_HOME/VERSION.
    local ref_version=""
    if [[ -n "${AID_HOME:-}" && -f "${AID_HOME}/VERSION" ]]; then
        ref_version="$(tr -d '[:space:]' < "${AID_HOME}/VERSION")"
    fi

    _render_tools_block "$manifest" "$ref_version" "Installed tools (in ${cwd_display})"
    return 0
}

# aid_status <target>
# Renders the "aid status" output for the AID project rooted at <target>.
# Reads <target>/.aid/.aid-manifest.json (and .aid/.aid-version).
# Returns:
#   0 - manifest found; status printed to stdout.
#   7 - no manifest in <target>; "not an AID project here" message printed to stdout.
aid_status() {
    local target="${1:-.}"
    local manifest="${target}/.aid/.aid-manifest.json"
    local cwd_display
    cwd_display="$(cd "$target" && pwd)"

    if [[ ! -f "$manifest" ]] || ! grep -q '"manifest_version"' "$manifest" 2>/dev/null; then
        printf "No AID install found in %s. Run 'aid add <tool>' to install.\n" "$cwd_display"
        return 7
    fi

    # Read aid_version from manifest.
    local aid_version=""
    if command -v python3 >/dev/null 2>&1; then
        aid_version="$(python3 - "$manifest" <<'PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get("aid_version", ""))
except Exception:
    pass
PY
)"
    else
        aid_version="$(grep '"aid_version"' "$manifest" | head -1 | \
            sed 's/.*"aid_version"[^:]*:[^"]*"\([^"]*\)".*/\1/')"
    fi

    # Read CLI ref version from $AID_HOME/VERSION.
    local ref_version=""
    if [[ -n "${AID_HOME:-}" && -f "${AID_HOME}/VERSION" ]]; then
        ref_version="$(tr -d '[:space:]' < "${AID_HOME}/VERSION")"
    fi

    printf 'AID %s  (project: %s)\n' "$aid_version" "$cwd_display"

    _render_tools_block "$manifest" "$ref_version" "Installed tools"

    return 0
}

# manifest_exists <manifest> - exits 0 when manifest exists and is parseable; 6 otherwise.
manifest_exists() {
    local manifest="$1"
    if [[ ! -f "$manifest" ]]; then
        return 6
    fi
    # Must have at least one key.
    if grep -q '"manifest_version"' "$manifest" 2>/dev/null; then
        return 0
    fi
    return 6
}

# ---------------------------------------------------------------------------
# Global shared-state provisioning
# ---------------------------------------------------------------------------

# _provision_shared_state_home <shared-home>
# Create <shared-home> (mode 0755) and seed an empty registry.yml (mode 0644,
# atomic, no-clobber) under it.  Every filesystem mutation is routed through
# _aid_priv_run so elevation is applied only when the parent/target is not
# user-writable.  Best-effort: returns non-zero on any failure without aborting
# the caller (install.sh / postinstall.js both swallow a non-zero return).
#
# The exact seed text matches the schema used by bin/aid's registry functions:
#   schema: 1
#   projects:
# (three comment lines + schema line + projects line with no items).
_provision_shared_state_home() {
    local SH="$1"
    local _psh_rc=0

    # Step 1: create the shared-home dir if absent.
    if [[ ! -d "$SH" ]]; then
        _aid_priv_run "$(dirname "$SH")" mkdir -p "$SH" || { _psh_rc=$?; }
        if [[ $_psh_rc -ne 0 ]]; then
            echo "WARN: aid: could not create shared state home ${SH} (rc=${_psh_rc})" >&2
            return $_psh_rc
        fi
        _aid_priv_run "$SH" chmod 0755 "$SH" || { _psh_rc=$?; }
        if [[ $_psh_rc -ne 0 ]]; then
            echo "WARN: aid: could not chmod shared state home ${SH} (rc=${_psh_rc})" >&2
            return $_psh_rc
        fi
    fi

    # Step 2: seed registry.yml if absent (no-clobber).
    local _reg="${SH}/registry.yml"
    if [[ -e "$_reg" ]]; then
        return 0
    fi

    local _tmp
    _tmp="$(mktemp "${SH}/.registry.aid-tmp.XXXXXX")" || {
        echo "WARN: aid: could not create temp file for registry seed in ${SH}" >&2
        return 1
    }
    {
        printf '%s\n' "# AID machine project registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)."
        printf '%s\n' "# Holds ONLY the base folders of projects this CLI install manages. Per-project name and"
        printf '%s\n' "# description come from .aid/settings.yml; version/tools from the manifest, at render time."
        printf '%s\n' "schema: 1"
        printf '%s\n' "projects:"
    } > "$_tmp" || {
        rm -f "$_tmp" 2>/dev/null
        echo "WARN: aid: could not write registry seed to ${SH}" >&2
        return 1
    }
    _aid_priv_run "$SH" mv -f "$_tmp" "$_reg" || {
        _psh_rc=$?
        rm -f "$_tmp" 2>/dev/null
        echo "WARN: aid: could not install registry seed at ${_reg} (rc=${_psh_rc})" >&2
        return $_psh_rc
    }
    _aid_priv_run "$SH" chmod 0644 "$_reg" || {
        _psh_rc=$?
        echo "WARN: aid: could not chmod registry seed at ${_reg} (rc=${_psh_rc})" >&2
        return $_psh_rc
    }
    return 0
}

# ---------------------------------------------------------------------------
# Orphan prune (Pillar 2 - R7)
# ---------------------------------------------------------------------------

# _prune_tool_dirs <target> <tool> <manifest_set_var>
#
# Removes stale AID-owned files from the tool's scoped directories AFTER a
# fresh install/update.  Prune basis = aid- prefix + new-manifest membership.
# Reads NO previous manifest; compares against the path set just written.
#
# Arguments:
#   target           - the repo root (absolute path)
#   tool             - canonical tool id
#   manifest_set_var - name of an associative array (declared by the caller)
#                      mapping each manifest path -> 1 (for O(1) lookup)
#
# Tool-native dirs (agents/, skills/, rules/):
#   (a) aid-prefixed FILE not in the manifest set -> remove
#   (b) aid-prefixed DIRECTORY with NO files in the manifest set -> remove dir
#       (kept when ANY of its files appear in the set)
#   Non-aid-prefixed entries are never touched (user content).
#
# AID-own subtree (aid/ inside the tool root):
#   (c) any FILE under aid/ not in the manifest set -> remove
#   (d) now-empty aid/ subdirs pruned after file removals
#
# Scoping (R1): copilot-cli walks only .github/{agents,skills,aid}, never .github root.
# Never removes directories outside the tool's scoped AID directories.
_prune_tool_dirs() {
    local target="$1"
    local tool="$2"
    local manifest_set_var="$3"

    # _in_set <path> - return 0 when path is in the manifest set
    _in_set() {
        local _p="$1"
        eval "local _v=\"\${${manifest_set_var}[\$_p]+x}\""
        [[ -n "$_v" ]]
    }

    local _prune_removed=0

    # ------------------------------------------------------------------
    # _prune_native_dir <native_dir_abs>
    # Walk one tool-native directory; apply rules (a) and (b).
    # <native_dir_abs> is absolute (e.g. /path/to/repo/.claude/agents).
    # ------------------------------------------------------------------
    _prune_native_dir() {
        local ndir="$1"
        [[ -d "$ndir" ]] || return 0

        # Enumerate immediate children of the native dir.
        local child child_rel
        for child in "$ndir"/aid-*; do
            [[ -e "$child" ]] || continue
            child_rel="${child#${target}/}"

            if [[ -f "$child" ]]; then
                # Rule (a): aid-prefixed file not in manifest -> remove.
                if ! _in_set "$child_rel"; then
                    rm -f "$child"
                    _prune_removed=$((_prune_removed + 1))
                    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Pruned: ${child}"
                fi
            elif [[ -d "$child" ]]; then
                # Rule (b): aid-prefixed dir -> keep only if any file inside is in manifest.
                local has_live=0
                local member
                while IFS= read -r -d '' member; do
                    local member_rel="${member#${target}/}"
                    if _in_set "$member_rel"; then
                        has_live=1
                        break
                    fi
                done < <(find "$child" -type f -print0 2>/dev/null)
                if [[ "$has_live" -eq 0 ]]; then
                    rm -rf "$child"
                    _prune_removed=$((_prune_removed + 1))
                    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Pruned dir: ${child}"
                fi
            fi
        done
    }

    # ------------------------------------------------------------------
    # _prune_aid_subtree <aid_root_abs>
    # Walk the aid/ subtree; apply rule (c) and prune empty subdirs (d).
    # <aid_root_abs> is absolute (e.g. /path/to/repo/.claude/aid).
    # ------------------------------------------------------------------
    _prune_aid_subtree() {
        local adir="$1"
        [[ -d "$adir" ]] || return 0

        # Rule (c): remove files not in manifest.
        local fpath fpath_rel
        while IFS= read -r -d '' fpath; do
            fpath_rel="${fpath#${target}/}"
            if ! _in_set "$fpath_rel"; then
                rm -f "$fpath"
                _prune_removed=$((_prune_removed + 1))
                [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Pruned: ${fpath}"
            fi
        done < <(find "$adir" -type f -print0 2>/dev/null)

        # Rule (d): prune now-empty subdirs (deepest first, skip the root itself).
        local dpath
        while IFS= read -r dpath; do
            [[ "$dpath" == "$adir" ]] && continue
            if [[ -d "$dpath" ]]; then
                local rem
                rem="$(find "$dpath" -mindepth 1 2>/dev/null | head -1)"
                if [[ -z "$rem" ]]; then
                    rmdir "$dpath" 2>/dev/null || true
                    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Pruned dir: ${dpath}"
                fi
            fi
        done < <(find "$adir" -mindepth 1 -type d 2>/dev/null | sort -r)
    }

    # ------------------------------------------------------------------
    # Per-tool scoping: which native dirs + which aid/ root to walk.
    # ------------------------------------------------------------------
    case "$tool" in
        claude-code)
            _prune_native_dir "${target}/.claude/agents"
            _prune_native_dir "${target}/.claude/skills"
            _prune_aid_subtree "${target}/.claude/aid"
            ;;
        codex)
            # .codex ships only agents/; .agents ships skills/ + aid/ subtree.
            _prune_native_dir "${target}/.codex/agents"
            _prune_native_dir "${target}/.agents/skills"
            _prune_aid_subtree "${target}/.agents/aid"
            ;;
        cursor)
            _prune_native_dir "${target}/.cursor/agents"
            _prune_native_dir "${target}/.cursor/skills"
            _prune_native_dir "${target}/.cursor/rules"
            _prune_aid_subtree "${target}/.cursor/aid"
            ;;
        copilot-cli)
            # R1: scope to .github/{agents,skills,aid} ONLY -- never .github root.
            _prune_native_dir "${target}/.github/agents"
            _prune_native_dir "${target}/.github/skills"
            _prune_aid_subtree "${target}/.github/aid"
            ;;
        antigravity)
            _prune_native_dir "${target}/.agent/rules"
            _prune_native_dir "${target}/.agent/skills"
            _prune_aid_subtree "${target}/.agent/aid"
            ;;
    esac

    if [[ "$_prune_removed" -gt 0 ]]; then
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] || echo "  ${_prune_removed} stale AID file(s) pruned"
    fi

    # Unset nested helpers to avoid polluting caller's scope.
    unset -f _in_set _prune_native_dir _prune_aid_subtree
}

# ---------------------------------------------------------------------------
# Version marker
# ---------------------------------------------------------------------------

# write_version_marker <target> <version>
write_version_marker() {
    local target="$1" version="$2"
    mkdir -p "${target}/.aid"
    printf '%s\n' "$version" > "${target}/.aid/.aid-version"
}

# ---------------------------------------------------------------------------
# High-level install_tool
# ---------------------------------------------------------------------------

# install_tool <staging_dir> <tool> <target> <version> <force>
# <staging_dir> - directory produced by extract_tarball (content of profiles/<tool>/)
# Returns:
#   0 - success (all files installed or up-to-date)
#
# Side effects: writes <target>/.aid/.aid-manifest.json and .aid/.aid-version.
install_tool() {
    local staging="$1" tool="$2" target="$3" version="$4" force="${5:-0}"
    local manifest="${target}/.aid/.aid-manifest.json"

    local -a install_paths=()
    local -a root_entries=()

    # Per-tool file counters (incremented by copy_file and _copy_root_agent_file).
    _COPY_COUNT_COPIED=0
    _COPY_COUNT_UPTODATE=0
    _COPY_COUNT_UPDATED=0
    _COPY_COUNT_SKIPPED=0

    local root_agent
    root_agent="$(_root_agent_file "$tool")"

    # Determine which dirs/files this tool installs (mirrors install.sh per-tool dispatch).
    case "$tool" in
        claude-code)
            # .claude/ tree + CLAUDE.md
            if [[ -d "${staging}/.claude" ]]; then
                copy_dir "${staging}/.claude" "${target}/.claude" "$force"
                # Collect paths from .claude/
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.claude" -type f -print0 2>/dev/null | sort -z)
            fi
            ;;
        codex)
            # .codex/ + .agents/ + AGENTS.md
            if [[ -d "${staging}/.codex" ]]; then
                copy_dir "${staging}/.codex" "${target}/.codex" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.codex" -type f -print0 2>/dev/null | sort -z)
            fi
            if [[ -d "${staging}/.agents" ]]; then
                copy_dir "${staging}/.agents" "${target}/.agents" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.agents" -type f -print0 2>/dev/null | sort -z)
            fi
            ;;
        cursor)
            # .cursor/ + AGENTS.md
            if [[ -d "${staging}/.cursor" ]]; then
                copy_dir "${staging}/.cursor" "${target}/.cursor" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.cursor" -type f -print0 2>/dev/null | sort -z)
            fi
            ;;
        copilot-cli)
            # .github/ + AGENTS.md
            if [[ -d "${staging}/.github" ]]; then
                copy_dir "${staging}/.github" "${target}/.github" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.github" -type f -print0 2>/dev/null | sort -z)
            fi
            ;;
        antigravity)
            # .agent/ + AGENTS.md
            if [[ -d "${staging}/.agent" ]]; then
                copy_dir "${staging}/.agent" "${target}/.agent" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.agent" -type f -print0 2>/dev/null | sort -z)
            fi
            ;;
    esac

    # Handle root agent file via in-place region update (Pillar 3).
    local root_src="${staging}/${root_agent}"
    local root_dst="${target}/${root_agent}"

    if [[ -f "$root_src" ]]; then
        _CORE_ROOT_AGENT_STATUS="owned"
        _copy_root_agent_file "$root_src" "$root_dst" "$tool" "$force" "$manifest"

        local inc_sha
        inc_sha="$(sha256_file "$root_src")"
        root_entries+=("${root_agent}|${inc_sha}|${_CORE_ROOT_AGENT_STATUS}")

        # Include root agent path in paths list only when owned (not pending-merge).
        if [[ "${_CORE_ROOT_AGENT_STATUS}" == "owned" ]]; then
            install_paths+=("$root_agent")
        fi
    fi

    # Write manifest (merge).
    manifest_write "$manifest" "$tool" "$version" "install_paths" "root_entries"

    # Prune stale AID-owned files (Pillar 2, R7).
    # Build an associative array from the new manifest path set for O(1) lookup.
    declare -A _prune_manifest_set=()
    local _p
    for _p in "${install_paths[@]+"${install_paths[@]}"}"; do
        _prune_manifest_set["$_p"]=1
    done
    _prune_tool_dirs "$target" "$tool" "_prune_manifest_set"
    unset _prune_manifest_set

    # Write version marker.
    write_version_marker "$target" "$version"

    # Print concise summary (always shown; per-file lines only when AID_VERBOSE=1).
    local _total_files=$((_COPY_COUNT_COPIED + _COPY_COUNT_UPTODATE + _COPY_COUNT_UPDATED + _COPY_COUNT_SKIPPED))
    if [[ "$_total_files" -gt 0 ]]; then
        if [[ "$_COPY_COUNT_COPIED" -gt 0 && "$_COPY_COUNT_UPTODATE" -eq 0 && "$_COPY_COUNT_UPDATED" -eq 0 ]]; then
            echo "  ${_COPY_COUNT_COPIED} files installed"
        elif [[ "$_COPY_COUNT_UPTODATE" -gt 0 && "$_COPY_COUNT_COPIED" -eq 0 && "$_COPY_COUNT_UPDATED" -eq 0 ]]; then
            echo "  up to date (${_COPY_COUNT_UPTODATE} files)"
        else
            local _parts=""
            [[ "$_COPY_COUNT_UPDATED" -gt 0 ]] && _parts="${_COPY_COUNT_UPDATED} updated"
            [[ "$_COPY_COUNT_COPIED" -gt 0 ]] && {
                [[ -n "$_parts" ]] && _parts="${_parts}, "
                _parts="${_parts}${_COPY_COUNT_COPIED} installed"
            }
            [[ "$_COPY_COUNT_UPTODATE" -gt 0 ]] && {
                [[ -n "$_parts" ]] && _parts="${_parts}, "
                _parts="${_parts}${_COPY_COUNT_UPTODATE} unchanged"
            }
            echo "  ${_parts}"
        fi
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

# uninstall_tool <manifest> <tool> <target>
# Removes all files recorded under tools.<tool>.paths that still exist.
# For root agent files: removes only when sha256 still matches recorded value.
# Prunes now-empty AID dirs.  Removes the manifest if no tools remain.
uninstall_tool() {
    local manifest="$1" tool="$2" target="$3"

    manifest_exists "$manifest" || return 6

    # Read all paths for this tool.
    local -a paths=()
    while IFS= read -r p; do
        [[ -n "$p" ]] && paths+=("$p")
    done < <(manifest_read_tool_paths "$manifest" "$tool")

    if [[ "${#paths[@]}" -eq 0 ]]; then
        echo "Nothing to uninstall for ${tool} (no paths recorded)" >&2
        manifest_remove_tool "$manifest" "$tool"
        return 0
    fi

    # Determine root agent file name.
    local root_agent
    root_agent="$(_root_agent_file "$tool")"

    # Per-uninstall counters.
    local _uninst_removed=0
    local _uninst_leftinplace=0

    # Remove each path.
    for p in "${paths[@]}"; do
        local full="${target}/${p}"
        if [[ ! -e "$full" ]]; then
            [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Already absent: ${full}"
            continue
        fi
        # Check if this is the root agent file -> apply FR11 uninstall check.
        local base
        base="$(basename "$p")"
        if [[ "$base" == "$root_agent" && "$p" == "$root_agent" ]]; then
            local recorded_sha
            recorded_sha="$(manifest_read_root_agent "$manifest" "$tool" "$root_agent")"
            if [[ -n "$recorded_sha" ]]; then
                local disk_sha
                disk_sha="$(sha256_file "$full")"
                if [[ "$disk_sha" != "$recorded_sha" ]]; then
                    _uninst_leftinplace=$((_uninst_leftinplace + 1))
                    # "Left in place" always shown (important for user awareness).
                    echo "Left in place (modified or not AID-owned): ${full}"
                    continue
                fi
            fi
        fi
        rm -f "$full"
        _uninst_removed=$((_uninst_removed + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Removed: ${full}"
    done

    # Print concise uninstall summary (always shown).
    if [[ "$_uninst_removed" -gt 0 ]]; then
        echo "  ${_uninst_removed} files removed"
    fi

    # Prune now-empty AID-owned dirs (in reverse depth order).
    local -a aid_dirs=()
    case "$tool" in
        claude-code)  aid_dirs+=(".claude") ;;
        codex)        aid_dirs+=(".codex" ".agents") ;;
        cursor)       aid_dirs+=(".cursor") ;;
        copilot-cli)  aid_dirs+=(".github") ;;
        antigravity)  aid_dirs+=(".agent") ;;
    esac

    for d in "${aid_dirs[@]}"; do
        local full_dir="${target}/${d}"
        if [[ -d "$full_dir" ]]; then
            # Remove if empty (find will list any remaining files).
            local remaining_files
            remaining_files="$(find "$full_dir" -type f 2>/dev/null | head -1)"
            if [[ -z "$remaining_files" ]]; then
                rm -rf "$full_dir"
                [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Removed dir: ${full_dir}"
            fi
        fi
    done

    # Remove this tool from manifest.
    manifest_remove_tool "$manifest" "$tool"

    # If no manifest remains, remove the .aid version marker too.
    if [[ ! -f "$manifest" ]]; then
        local version_marker
        version_marker="$(dirname "$manifest")/.aid-version"
        rm -f "$version_marker"
        # Remove .aid dir if empty.
        local aid_meta_dir
        aid_meta_dir="$(dirname "$manifest")"
        if [[ -d "$aid_meta_dir" ]]; then
            local rem
            rem="$(find "$aid_meta_dir" -type f 2>/dev/null | head -1)"
            [[ -z "$rem" ]] && rmdir "$aid_meta_dir" 2>/dev/null || true
        fi
    fi
}
