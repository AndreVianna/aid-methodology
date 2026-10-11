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
#   resolve_version             -> release version to install (stdout); exit 3 on fail.
#                                 CLI-version-aware: a pre-release running CLI
#                                 prefers the newest pre-release release, else
#                                 falls back to the latest stable; a stable CLI
#                                 always resolves the latest stable (unchanged).
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
# Release source. Defaults to GitHub, pinned. The AID_API_BASE / AID_DOWNLOAD_BASE
# env overrides (for an air-gapped / enterprise mirror, or a canonical test's
# local fixture server) are honored ONLY when AID_ALLOW_ENDPOINT_OVERRIDE=1 (or
# 'true') is explicitly set. Combined with the fail-closed SHA256SUMS check in
# fetch_tarball, gating the override this way prevents a stray or malicious
# AID_API_BASE / AID_DOWNLOAD_BASE in the ambient environment from silently
# redirecting a real install to an attacker-controlled host. Canonical tests
# that need a local fixture (file:// or http://127.0.0.1:<port>) set
# AID_ALLOW_ENDPOINT_OVERRIDE=1 alongside the base-URL override.
_AID_DEFAULT_API_BASE="https://api.github.com/repos/${AID_REPO_SLUG}"
_AID_DEFAULT_DOWNLOAD_BASE="https://github.com/${AID_REPO_SLUG}/releases/download"
if [[ "${AID_ALLOW_ENDPOINT_OVERRIDE:-0}" == "1" || "${AID_ALLOW_ENDPOINT_OVERRIDE:-0}" == "true" ]]; then
    AID_API_BASE="${AID_API_BASE:-${_AID_DEFAULT_API_BASE}}"
    AID_DOWNLOAD_BASE="${AID_DOWNLOAD_BASE:-${_AID_DEFAULT_DOWNLOAD_BASE}}"
else
    AID_API_BASE="${_AID_DEFAULT_API_BASE}"
    AID_DOWNLOAD_BASE="${_AID_DEFAULT_DOWNLOAD_BASE}"
fi

# Canonical tool ids.
AID_TOOLS=(claude-code codex cursor copilot-cli antigravity)

# Root agent file per tool.
_root_agent_file() { echo "AGENTS.md"; }

# _root_dir <tool> - print the tool's install-tree root dir name (relative to the
# project root). The AID-own subtree lives at <root>/aid/ (e.g. .claude/aid/).
# Mirrors the per-tool dispatch in install_tool.
_root_dir() {
    case "$1" in
        claude-code)  echo ".claude" ;;
        codex)        echo ".codex" ;;
        cursor)       echo ".cursor" ;;
        copilot-cli)  echo ".github" ;;
        antigravity)  echo ".agent" ;;
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
        echo "ERROR: cannot auto-detect host tool; specify the tool explicitly (e.g. 'aid add <name>')" >&2
        return 2
    else
        local list
        list="$(printf '%s, ' "${found[@]}")"
        list="${list%, }"
        echo "ERROR: ambiguous host tool (found: ${list}); specify the tool explicitly (e.g. 'aid add <name>')" >&2
        return 2
    fi
}

# ---------------------------------------------------------------------------
# Version resolution (online)
# ---------------------------------------------------------------------------

# _aid_is_prerelease <version>
# Mirrors canonical/aid/scripts/release/check-version-sync.sh's _is_prerelease()
# (same pattern in .github/workflows/release.yml) -- kept in sync deliberately,
# do not invent a divergent regex here. True (exit 0) when <version> (bare
# semver, no leading 'v') matches a pre-release shape: an alpha/beta/preview/
# pre/rc/a/b/c suffix (e.g. '2.2.3b1'), or a SemVer '-' pre-release tag.
_aid_is_prerelease() {
    local v="$1"
    local re='^[0-9]+\.[0-9]+\.[0-9]+([._-]?(alpha|beta|preview|pre|rc|a|b|c)[0-9]*|-[0-9A-Za-z.-]+)$'
    [[ "$v" =~ $re ]]
}

# _aid_first_prerelease_tag
# Reads a GitHub /releases list JSON body on stdin (pretty-printed, one key per
# line -- same assumption the existing tag_name grep+sed already relies on;
# GitHub returns the list newest-first, and within each release object
# "tag_name" is emitted before "prerelease"). Prints the tag_name of the FIRST
# entry whose "prerelease" field is true (the newest pre-release) and returns
# 0; prints nothing and returns 1 when no pre-release entry is found.
_aid_first_prerelease_tag() {
    local cur_tag="" line
    while IFS= read -r line; do
        if [[ "$line" == *'"tag_name"'* ]]; then
            cur_tag="$(printf '%s' "$line" | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
        elif [[ "$line" == *'"prerelease"'* && "$line" == *'true'* ]]; then
            if [[ -n "$cur_tag" ]]; then
                printf '%s\n' "$cur_tag"
                return 0
            fi
        fi
    done
    return 1
}

# resolve_version - fetch the release tag to install from the GitHub API.
# Prints the version without leading 'v'.  Exits 3 on failure.
#
# CLI-version-aware (release-v2.2.3b1): when the RUNNING CLI itself is a
# pre-release (its own ${AID_CODE_HOME}/VERSION matches _aid_is_prerelease),
# prefer the newest pre-release release from the GitHub releases LIST; fall
# back to the latest stable (/releases/latest) when no pre-release exists, or
# when the list fetch itself fails (fail-safe -- never hard-error the update
# because of the beta lookup). A stable-CLI install is unaffected: always
# /releases/latest, unchanged.
resolve_version() {
    local url="${AID_API_BASE}/releases/latest"
    local curl_args=(-fsSL)
    # Optional bearer token for rate-limit relief.
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer ${token}")
    fi

    local cli_version=""
    if [[ -n "${AID_CODE_HOME:-}" && -f "${AID_CODE_HOME}/VERSION" ]]; then
        cli_version="$(tr -d '[:space:]' < "${AID_CODE_HOME}/VERSION")"
    fi

    if [[ -n "$cli_version" ]] && _aid_is_prerelease "$cli_version"; then
        local list_url="${AID_API_BASE}/releases"
        local list_response=""
        # Test the command substitution's exit status directly in the `if`
        # condition (not via a separate `$?` read) so a failing fetch is
        # tolerated even under a caller's `set -e` (defensive; bin/aid itself
        # runs with `set -uo pipefail`, no -e, but the lib is sourced and must
        # not assume that).
        if list_response="$(curl "${curl_args[@]}" "$list_url" 2>/dev/null)" && [[ -n "$list_response" ]]; then
            local pre_tag=""
            if pre_tag="$(printf '%s\n' "$list_response" | _aid_first_prerelease_tag)" && [[ -n "$pre_tag" ]]; then
                echo "${pre_tag#v}"
                return 0
            fi
        fi
        # No pre-release found (or the list fetch failed) -- fall through to
        # the stable /releases/latest lookup below.
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

# fetch_artifact <kind> <tool> <version> <dest_dir>
# Fetches one release artifact and its SHA256SUMS. kind is shared or tool.
# A missing shared artifact is the explicit legacy-layout refusal (exit 3).
fetch_artifact() {
    local kind="$1" tool="$2" version="$3" dest_dir="$4"
    local filename
    if [[ "$kind" == shared ]]; then filename="aid-shared-v${version}.tar.gz"; else filename="aid-${tool}-v${version}.tar.gz"; fi
    local url="${AID_DOWNLOAD_BASE}/v${version}/${filename}"
    local sums_url="${AID_DOWNLOAD_BASE}/v${version}/SHA256SUMS"
    local tarball="${dest_dir}/${filename}"
    local sums_file="${dest_dir}/SHA256SUMS"

    local curl_args=(-fsSL)
    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer ${token}")
    fi

    [[ "$kind" == tool ]] && echo "Fetching ${filename} ..." >&2
    local fetch_status=""
    if fetch_status="$(curl "${curl_args[@]}" -w '%{http_code}' -o "$tarball" "$url" 2>/dev/null)"; then
        :
    else
        if [[ "$kind" == shared && "$fetch_status" == 404 ]]; then
            echo "release v${version} has no shared payload -- it predates the shared layout and cannot be installed by this CLI; omit --version or use an older aid CLI" >&2
            return 3
        fi
        echo "ERROR: aid-install-core: failed to download ${url}" >&2
        return 3
    fi

    # Fetch SHA256SUMS -- fail-closed. Every published release (release.sh Step 6:
    # "Emit SHA256SUMS") ships a SHA256SUMS asset alongside every tarball, so a
    # fetch failure, a 404, or an empty response means the release is broken or
    # the request was tampered with/redirected -- never a legitimate "older
    # release without SHA256SUMS". Refuse to install an unverified tarball
    # rather than warn-and-proceed.
    if ! curl "${curl_args[@]}" -o "$sums_file" "$sums_url" 2>/dev/null || [[ ! -s "$sums_file" ]]; then
        echo "ERROR: aid-install-core: could not fetch SHA256SUMS from ${sums_url}; refusing to install unverified tarball (fail-closed)" >&2
        return 3
    fi
    _verify_checksum "$tarball" "$sums_file" || return 4
}

# Backwards-compatible per-tool fetch wrapper.
fetch_tarball() { fetch_artifact tool "$1" "$2" "$3"; }

# extract_payload <tarball> <dest_dir> validates all archive member names before extraction.
# It rejects absolute paths, parent segments, and links, then extracts at the staging root.
extract_payload() {
    local tarball="$1" dest_dir="$2" member normalized
    local list_file
    list_file="$(mktemp)"
    if ! tar -tzf "$tarball" >"$list_file" 2>/dev/null; then
        rm -f "$list_file"; echo "ERROR: aid-install-core: failed to list payload: $tarball" >&2; return 1
    fi
    while IFS= read -r member; do
        normalized="${member%/}"
        if [[ "$normalized" == /* || "$normalized" =~ ^[A-Za-z]: || "$normalized" == *$'\\'* || "/$normalized/" == *"/../"* ]]; then
            rm -f "$list_file"; echo "ERROR: aid-install-core: unsafe payload member: ${member}" >&2; return 1
        fi
    done < "$list_file"
    rm -f "$list_file"
    if tar -tvzf "$tarball" | awk 'substr($0,1,1)=="l" || substr($0,1,1)=="h" { found=1 } END { exit !found }'; then
        echo "ERROR: aid-install-core: payload links are not allowed: $tarball" >&2; return 1
    fi
    mkdir -p "$dest_dir"
    tar -xzf "$tarball" -C "$dest_dir" || { echo "ERROR: aid-install-core: failed to extract $tarball" >&2; return 1; }
}

# validate_release_descriptor <descriptor> <kind> <artifact-version> <tool>
validate_release_descriptor() {
    local file="$1" kind="$2" artifact_version="$3" tool="${4:-}" line key value
    local root
    root="$(_root_dir "$tool")"
    local -A counts=()
    local descriptor_lines=""
    [[ -f "$file" ]] || { echo "ERROR: aid: descriptor $(basename "$file") missing required descriptor" >&2; return 1; }
    if ! descriptor_lines="$(read_kv_conf "$file")"; then
        return 1
    fi
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key="${line%%=*}"; value="${line#*=}"
        counts["$key"]=$(( ${counts["$key"]:-0} + 1 ))
        if [[ "$key" != skill_mirror && "${counts[$key]}" -gt 1 ]]; then
            echo "ERROR: aid: $(basename "$file"): ${key} may appear only once" >&2; return 1
        fi
        case "$key" in
            aid_version)
                [[ "$value" == "$artifact_version" ]] || { echo "ERROR: aid: $(basename "$file"): aid_version must match artifact version ${artifact_version}" >&2; return 1; } ;;
            tool)
                [[ "$kind" == tool && "$value" == "$tool" ]] || { echo "ERROR: aid: $(basename "$file"): invalid tool '${value}'" >&2; return 1; } ;;
            skill_mirror)
                [[ "$kind" == tool && "$value" =~ ^\.[a-z]+/skills$ && "$value" != ".agents/skills" && "$value" == "$root"/* ]] || { echo "ERROR: aid: $(basename "$file"): invalid skill_mirror '${value}'" >&2; return 1; } ;;
            worktree_root)
                [[ "$kind" == tool && ( "$value" == ".aid/.worktrees" || "$value" == "$root/worktrees" ) ]] || { echo "ERROR: aid: $(basename "$file"): invalid worktree_root '${value}'" >&2; return 1; } ;;
            context_import)
                [[ "$kind" == tool && "$value" == "CLAUDE.md" ]] || { echo "ERROR: aid: $(basename "$file"): invalid context_import '${value}'" >&2; return 1; } ;;
            rules_inline)
                [[ "$kind" == tool && "$value" == "true" ]] || { echo "ERROR: aid: $(basename "$file"): rules_inline must be true" >&2; return 1; } ;;
        esac
    done <<< "$descriptor_lines"
    if [[ "$kind" == shared && -z "${counts[aid_version]:-}" ]]; then
        echo "ERROR: aid: $(basename "$file"): missing aid_version" >&2; return 1
    fi
    if [[ "$kind" == tool && -z "${counts[tool]:-}" ]]; then
        echo "ERROR: aid: $(basename "$file"): missing tool" >&2; return 1
    fi
}

_validate_artifact_members() {
    local tarball="$1" kind="$2" tool="${3:-}" member normalized root
    root="$(_root_dir "$tool")"
    local list_file; list_file="$(mktemp)"
    tar -tzf "$tarball" > "$list_file" 2>/dev/null || { rm -f "$list_file"; return 1; }
    while IFS= read -r member; do
        normalized="${member%/}"
        if [[ "$kind" == tool && "$normalized" != aid-tool.conf && "$normalized" != "$root/agents" && "$normalized" != "$root/agents/"* ]]; then
            rm -f "$list_file"; echo "ERROR: aid: tool artifact contains disallowed member: ${normalized}" >&2; return 1
        fi
    done < "$list_file"
    rm -f "$list_file"
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
        if ! cp "$src" "$dst"; then
            echo "ERROR: aid-install-core: copy failed: ${dst}" >&2
            _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
            return 0
        fi
        _COPY_COUNT_COPIED=$((_COPY_COUNT_COPIED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"
        return 0
    fi

    if cmp -s "$src" "$dst"; then
        _COPY_COUNT_UPTODATE=$((_COPY_COUNT_UPTODATE + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Up to date: ${dst}"
        return 0
    fi

    # File exists and differs -> always overwrite (work-007).
    # AID-owned files track the bundle, which is the source of truth, so an
    # add/update must bring them current. `force` is retained in the signature
    # for back-compat and bash<->PS parity but no longer gates this overwrite:
    # skip-on-diff silently left stale files behind on in-place upgrades (e.g. an
    # old flat-path skill surviving next to relocated .aid/ scripts). User-owned
    # root agent files (CLAUDE.md/AGENTS.md) never reach copy_file -- they are
    # handled by _copy_root_agent_file, which keeps its own force gating.
    if ! cp "$src" "$dst"; then
        echo "ERROR: aid-install-core: copy failed: ${dst}" >&2
        _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
        return 0
    fi
    _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst}"
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
# Descriptor reader (aid-payload.conf, aid-tool.conf, host.conf)
# ---------------------------------------------------------------------------

# read_kv_conf <file>
# Prints one "key=value" line per descriptor entry, in file order. A repeated key
# is a list (one line per occurrence). Split at the FIRST '='; '#' lines, blank
# lines and lines without '=' are ignored. Keys are not interpreted, and the file
# is never sourced or evaluated.
# Exit 1, naming the file, on a non-ASCII byte, a CR, or an unreadable file.
read_kv_conf() {
    local f="$1" line key
    if [[ ! -r "$f" ]]; then
        echo "ERROR: aid-install-core: descriptor not readable: ${f}" >&2
        return 1
    fi
    if LC_ALL=C tr -d '\000-\177' < "$f" | LC_ALL=C grep -q . || LC_ALL=C grep -q $'\r' "$f"; then
        echo "ERROR: aid-install-core: descriptor must be ASCII with LF line endings only: ${f}" >&2
        return 1
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        [[ "$line" == *=* ]] || continue
        key="${line%%=*}"
        [[ -z "$key" ]] && continue
        printf '%s\n' "$line"
    done < "$f"
    return 0
}

# ---------------------------------------------------------------------------
# .aid/.trash/ moves and guarded copy (FR-9)
# ---------------------------------------------------------------------------

# _aid_utc_stamp - print the current UTC time as yyyyMMddTHHmmssZ.
_aid_utc_stamp() { date -u +%Y%m%dT%H%M%SZ; }

# trash_file <root> <file> [<utc-stamp>]
# Moves <file> (which must sit under <root>) to <root>/.aid/.trash/<relative path>.
# Collision policy (REQUIREMENTS.md section 11, Feature 001, Data Model):
#   - destination absent                  -> move the file there;
#   - destination holds identical bytes   -> no new copy; the source is removed;
#   - destination holds different bytes   -> rename it to <dest>.<stamp>, or to the
#     first unused <dest>.<stamp>.N (N = 1, 2, ...), then move the source into place.
#     No occupied candidate is ever overwritten.
# <utc-stamp> defaults to the current UTC time; an explicit stamp freezes the clock.
# Rotation happens before the source is touched, so a failed rotation loses nothing.
# Exit 1 (source untouched) when <file> is outside <root> or a step fails.
trash_file() {
    local root="${1%/}" src="$2" stamp="${3:-}"
    local rel dest cand n
    if [[ -z "$stamp" ]]; then stamp="$(_aid_utc_stamp)"; fi
    case "$src" in
        "$root"/*) rel="${src#"$root"/}" ;;
        *)
            echo "ERROR: aid-install-core: trash source is outside the project root: ${src}" >&2
            return 1 ;;
    esac
    if [[ ! -f "$src" ]]; then
        echo "ERROR: aid-install-core: trash source is not a regular file: ${src}" >&2
        return 1
    fi
    dest="${root}/.aid/.trash/${rel}"
    if ! mkdir -p "$(dirname "$dest")"; then
        echo "ERROR: aid-install-core: cannot create trash directory for: ${dest}" >&2
        return 1
    fi
    if [[ -d "$dest" ]]; then
        echo "ERROR: aid-install-core: trash destination is a directory: ${dest}" >&2
        return 1
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            rm -f "$src" || return 1
            return 0
        fi
        cand="${dest}.${stamp}"
        n=0
        while [[ -e "$cand" || -L "$cand" ]]; do
            n=$((n + 1))
            cand="${dest}.${stamp}.${n}"
        done
        if ! mv "$dest" "$cand"; then
            echo "ERROR: aid-install-core: could not rotate trash entry ${dest}; source kept: ${src}" >&2
            return 1
        fi
    fi
    if ! mv "$src" "$dest"; then
        echo "ERROR: aid-install-core: could not move ${src} to ${dest}" >&2
        return 1
    fi
    return 0
}

# copy_file_guarded <src> <dst> [<recorded-sha256>] [<root>]
# Shared-placement copy with drift protection (FR-9). Reports the copy_file counters.
#   destination absent                     -> copy                       (copied)
#   destination bytes identical to <src>   -> leave                      (up to date)
#   differing, destination not drifted     -> overwrite, no trash entry  (updated)
#   differing, destination drifted         -> trash_file <dst>, then copy (updated)
# The destination is DRIFTED when its sha256 differs from <recorded-sha256>; when no
# sha256 is recorded (empty), it is drifted because its bytes differ from <src>.
# <dst> must sit under <root> (default: $PWD) for the trash entry to be placed.
# A failed trash leaves the destination in place and counts as a failure.
copy_file_guarded() {
    local src="$1" dst="$2" recorded="${3:-}" root="${4:-$PWD}"
    local drifted=0 dst_sha
    mkdir -p "$(dirname "$dst")"

    if [[ ! -e "$dst" ]]; then
        if ! cp "$src" "$dst"; then
            echo "ERROR: aid-install-core: copy failed: ${dst}" >&2
            _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
            return 0
        fi
        _COPY_COUNT_COPIED=$((_COPY_COUNT_COPIED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"
        return 0
    fi

    if cmp -s "$src" "$dst"; then
        _COPY_COUNT_UPTODATE=$((_COPY_COUNT_UPTODATE + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Up to date: ${dst}"
        return 0
    fi

    dst_sha="$(sha256_file "$dst" 2>/dev/null)"
    if [[ -z "$recorded" || "$dst_sha" != "$recorded" ]]; then
        drifted=1
    fi
    if [[ "$drifted" -eq 1 ]]; then
        if ! trash_file "$root" "$dst"; then
            echo "ERROR: aid-install-core: drifted file left in place, not overwritten: ${dst}" >&2
            _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
            return 0
        fi
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Trashed: ${dst}"
    fi
    if ! cp "$src" "$dst"; then
        echo "ERROR: aid-install-core: copy failed: ${dst}" >&2
        _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
        return 0
    fi
    _COPY_COUNT_UPDATED=$((_COPY_COUNT_UPDATED + 1))
    [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: ${dst}"
    return 0
}

# ---------------------------------------------------------------------------
# Root agent file region update (Pillar 3)
# ---------------------------------------------------------------------------

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


# Fixed root context regions. Keep these LF-only constants in both install cores.
_AID_AGENTS_POINTER_REGION=$'<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n@.aid/runtime/rules.md\nBefore acting, read and follow `.aid/runtime/rules.md` (AID rules).\n<!-- AID:END -->\n'
_AID_CLAUDE_IMPORT_REGION=$'<!-- AID:BEGIN -->\n@AGENTS.md\n<!-- AID:END -->\n'

# _repair_root_region <file> <region> [project-root]
# Preserve bytes outside exact managed lines; malformed regions are backed up first.
_repair_root_region() {
    local file="$1" region="$2" root="${3:-$(dirname "$1")}" core="${BASH_SOURCE[0]}"
    python3 - "$file" "$region" "$root" "$core" <<'PY'
import os, pathlib, subprocess, sys
path, region, root, core = sys.argv[1], sys.argv[2].encode(), sys.argv[3], sys.argv[4]
expected = region.splitlines()
def content(line): return line[:-2] if line.endswith(b"\r\n") else line[:-1] if line.endswith(b"\n") else line
if not os.path.exists(path):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    pathlib.Path(path).write_bytes(region)
    raise SystemExit(0)
data = pathlib.Path(path).read_bytes()
lines = data.splitlines(keepends=True)
contents = [content(line) for line in lines]
managed = set(expected)
positions = [i for i, line in enumerate(contents) if line in managed]
if not positions:
    pathlib.Path(path).write_bytes(data + (b"" if not data or data.endswith(b"\n") else b"\n") + region)
    raise SystemExit(0)
starts = [i for i in range(len(lines)-len(expected)+1) if contents[i:i+len(expected)] == expected]
if len(starts) == 1 and len(positions) == len(expected): raise SystemExit(0)
subprocess.run(["bash", "-c", 'source "$1"; trash_file "$2" "$3"', "_", core, root, path], check=True)
out = bytearray(); inserted = False
for line, value in zip(lines, contents):
    if value in managed:
        if not inserted: out.extend(region); inserted = True
    else: out.extend(line)
if not inserted: out.extend(region)
pathlib.Path(path).write_bytes(out)
PY
}

# Repair and print the canonical import-region hash.
_ensure_claude_md_region() {
    local file="${1:-$PWD/CLAUDE.md}" root="${2:-$(dirname "${1:-$PWD/CLAUDE.md}")}"
    _repair_root_region "$file" "$_AID_CLAUDE_IMPORT_REGION" "$root" || return 1
    printf '%s\n' "$(printf '%s' "$_AID_CLAUDE_IMPORT_REGION" | sha256sum | awk '{print $1}')"
}

# Remove the exact Claude import region, backing up drift before the surgical edit.
_remove_claude_md_region() {
    local file="$1" recorded="${2:-}" root="${3:-$(dirname "$1")}" core="${BASH_SOURCE[0]}"
    [[ -f "$file" ]] || return 0
    python3 - "$file" "$recorded" "$root" "$core" <<'PY'
import hashlib, os, pathlib, subprocess, sys
path, recorded, root, core = sys.argv[1:]
data=pathlib.Path(path).read_bytes(); lines=data.splitlines(keepends=True)
def content(line): return line[:-2] if line.endswith(b"\r\n") else line[:-1] if line.endswith(b"\n") else line
values=[content(x) for x in lines]
begin=b"<!-- AID:BEGIN -->"; end=b"<!-- AID:END -->"
starts=[i for i,x in enumerate(values) if x==begin]; ends=[i for i,x in enumerate(values) if x==end]
if len(starts)!=1 or len(ends)!=1 or starts[0]>=ends[0]: raise SystemExit(0)
start,finish=starts[0],ends[0]
canonical=b"".join(values[i]+b"\n" for i in range(start,finish+1))
if hashlib.sha256(canonical).hexdigest()!=recorded:
    subprocess.run(["bash", "-c", 'source "$1"; trash_file "$2" "$3"', "_", core, root, path], check=True)
out=b"".join(lines[:start]+lines[finish+1:])
if not out.strip(): os.remove(path)
else: pathlib.Path(path).write_bytes(out)
PY
}
# Writes the shared AGENTS.md pointer region and records its hashes for the caller.
_repair_inline_root_region() {
    local file="$1" region="$2" root="${3:-$(dirname "$1")}" core="${BASH_SOURCE[0]}"
    python3 - "$file" "$region" "$root" "$core" <<'PY'
import os, pathlib, subprocess, sys
path, region, root, core = sys.argv[1], sys.argv[2].encode(), sys.argv[3], sys.argv[4]
begin=b"<!-- AID:BEGIN -->"; end=b"<!-- AID:END -->"
if not os.path.exists(path):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True); pathlib.Path(path).write_bytes(region); raise SystemExit(0)
data=pathlib.Path(path).read_bytes()
lines=data.splitlines(keepends=True)
def value(x): return x[:-2] if x.endswith(b"\r\n") else x[:-1] if x.endswith(b"\n") else x
starts=[i for i,x in enumerate(lines) if value(x)==begin]; ends=[i for i,x in enumerate(lines) if value(x)==end]
if len(starts)==1 and len(ends)==1 and starts[0]<ends[0]:
    start,endline=starts[0],ends[0]
    # Preserve marker terminators and all bytes outside the marked span.
    prefix=b"".join(lines[:start+1]); suffix=b"".join(lines[endline:])
    replacement=region[len(begin)+1:-(len(end)+1)]
    if not lines[start].endswith(b"\n"): prefix += b"\n"
    pathlib.Path(path).write_bytes(prefix+replacement+suffix); raise SystemExit(0)
if not starts and not ends:
    pathlib.Path(path).write_bytes(data+(b"" if not data or data.endswith(b"\n") else b"\n")+region); raise SystemExit(0)
subprocess.run(["bash","-c",'source "$1"; trash_file "$2" "$3"',"_",core,root,path],check=True)
# Malformed marker spans are replaced in place; unrelated lines stay byte-identical.
out=bytearray(); inserted=False
for line in lines:
    v=value(line)
    if v in (begin,end):
        if not inserted: out.extend(region); inserted=True
    else: out.extend(line)
if not inserted: out.extend(region)
pathlib.Path(path).write_bytes(out)
PY
}

_copy_root_agent_file() {
    local src="$1" dst="$2" tool="$3" force="${4:-0}" manifest="${5:-}" root="$(dirname "$2")" inline=0 rules region
    local had_dst=0 before_sha=""
    if [[ -f "$dst" ]]; then had_dst=1; before_sha="$(sha256_file "$dst")"; fi
    _CORE_ROOT_AGENT_STATUS="owned"
    if [[ -f "$(dirname "$src")/aid-tool.conf" ]] && grep -qx 'rules_inline=true' "$(dirname "$src")/aid-tool.conf"; then inline=1; fi
    if [[ -n "$manifest" && -f "$manifest" ]] && command -v python3 >/dev/null 2>&1; then
        python3 - "$manifest" <<'PY' | grep -qx true && inline=1
import json,sys
try: print(str(any(t.get('rules_inline') is True for t in json.load(open(sys.argv[1])).get('tools',{}).values())).lower())
except Exception: pass
PY
    fi
    if [[ "$inline" -eq 1 ]]; then
        rules="$root/.aid/runtime/rules.md"
        [[ -f "$rules" ]] || return 1
        region="$(printf '<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'; cat "$rules"; printf '<!-- AID:END -->\n')"$'\n'
        _repair_inline_root_region "$dst" "$region" "$root" || return 1
    else
        region="$_AID_AGENTS_POINTER_REGION"
        _repair_root_region "$dst" "$region" "$root" || return 1
    fi
    _CORE_ROOT_AGENT_REGION_SHA="$(printf '%s' "$region" | sha256sum | awk '{print $1}')"
    _CORE_ROOT_AGENT_FILE_SHA="$(sha256_file "$dst")"
    if [[ "$had_dst" -eq 0 ]]; then
        _COPY_COUNT_COPIED=$((${_COPY_COUNT_COPIED:-0} + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: $dst"
    elif [[ "$before_sha" == "$_CORE_ROOT_AGENT_FILE_SHA" ]]; then
        _COPY_COUNT_UPTODATE=$((${_COPY_COUNT_UPTODATE:-0} + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Up to date: $dst"
    else
        _COPY_COUNT_UPDATED=$((${_COPY_COUNT_UPDATED:-0} + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Updated: $dst"
    fi
    return 0
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

    # Large tool profiles (~350 paths) can push these lists past the OS
    # command-line length limit (notably Windows' ~32K CreateProcess limit)
    # when passed as argv to the python3 subprocess.  Write each list to its
    # own temp file instead, and pass only the (small) temp-file paths as
    # argv; clean up the temp files regardless of how this function exits.
    local paths_file roots_file
    paths_file="$(mktemp "${TMPDIR:-${TMP:-/tmp}}/aid-manifest-paths.XXXXXX")" || {
        echo "ERROR: aid-install-core: mktemp failed for manifest paths file" >&2
        return 1
    }
    roots_file="$(mktemp "${TMPDIR:-${TMP:-/tmp}}/aid-manifest-roots.XXXXXX")" || {
        rm -f "$paths_file"
        echo "ERROR: aid-install-core: mktemp failed for manifest roots file" >&2
        return 1
    }

    printf '%s\n' "${paths_arr[@]+"${paths_arr[@]}"}" > "$paths_file"
    printf '%s\n' "${root_arr[@]+"${root_arr[@]}"}" > "$roots_file"

    python3 - "$manifest" "$tool" "$version" "$now" "$paths_file" "$roots_file" <<'PY'
import json, sys, os, tempfile

manifest_path = sys.argv[1]
tool          = sys.argv[2]
version       = sys.argv[3]
now           = sys.argv[4]
paths_file    = sys.argv[5]
roots_file    = sys.argv[6]

with open(paths_file, encoding="utf-8") as f:
    paths_raw = f.read()
with open(roots_file, encoding="utf-8") as f:
    roots_raw = f.read()

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
    "format_version": 2,
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
    local py_rc=$?
    rm -f "$paths_file" "$roots_file"
    return "$py_rc"
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
                 grep -v 'manifest_version\|format_version\|aid_version\|installed_at\|version\|paths\|root_agent_files\|sha256\|status\|path\|tools' | \
                 sed 's/"//g' | sed 's/[[:space:]]*://g')
    fi

    # Assemble complete manifest JSON.
    local tmp_file
    tmp_file="$(mktemp "${manifest_dir}/.manifest.tmp.XXXXXX")"

    {
        printf '{\n'
        printf '  "format_version": 2,\n'
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
            printf '  "format_version": 2,\n'
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
        # tr strips any stray CR from Python's text-mode stdout translation
        # on Windows (print() emits \r\n there); on Linux/macOS this is a
        # no-op, so the output stays byte-identical to before.
        python3 - "$manifest" <<'PY' | tr -d '\r'
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
    # (awk emits bare \n natively; tr -d '\r' is a no-op safety net here too.)
    awk '
    BEGIN { in_tools=0; depth=0 }
    /"tools"[[:space:]]*:/ { in_tools=1; depth=0; next }
    in_tools && /\{/ { depth++ }
    in_tools && /\}/ { depth--; if (depth<=0) exit }
    in_tools && depth==1 && /^    "[a-z][a-zA-Z-]*"[[:space:]]*:/ {
        s=$0; gsub(/^[[:space:]]*"/, "", s); gsub(/".*/, "", s)
        if (s != "") print s
    }
    ' "$manifest" | tr -d '\r'
}

# ---------------------------------------------------------------------------
# Format-3 manifest (.aid/.aid-manifest.json, format_version 3)
# ---------------------------------------------------------------------------
#
# Writers take a MODEL file: one record per line, TAB-separated, LF-terminated.
#   aid_version<TAB>V
#   installed_at<TAB>TS
#   host.worktree_root<TAB>DIR                      (absent: .aid/.worktrees)
#   shared.<skills|runtime|agents_md|claude_md>.<root|path|version|users|region_sha256|file_sha256><TAB>VALUE
#       users = comma-separated tool ids, in any order
#   shared.<skills|runtime>.file<TAB>PATH<TAB>SHA256       (repeatable)
#   shared.mirror<TAB>DIR<TAB>VERSION<TAB>USERS            (repeatable)
#   tools.<tool>.<version|installed_at|worktree_root|rules_inline><TAB>VALUE
#   tools.<tool>.mirror<TAB>DIR                            (repeatable)
#   tools.<tool>.file<TAB>PATH<TAB>SHA256                  (repeatable)
# An entry whose users list is empty is absent. rules_inline is only "true".
#
# The python3 and pure-bash writers emit byte-identical JSON: 2-space indent, LF,
# trailing LF, the key order of REQUIREMENTS.md section 11, Feature 001, Data Model,
# files sorted by path (byte order), users and tools in AID_TOOLS order.
#
# Readers print the same record grammar (key<TAB>value, one record per line; record
# order is unspecified). manifest_format prints the bare format_version value.

# _aid_v3_known_tool <id> - exit 0 when <id> is in AID_TOOLS.
_aid_v3_known_tool() {
    local t
    for t in "${AID_TOOLS[@]}"; do
        [[ "$t" == "$1" ]] && return 0
    done
    return 1
}

# _aid_v3_users <csv> <where> - sets _AID_V3_USERS to the named tools in AID_TOOLS order.
# Exit 1 on an unknown tool id.
_aid_v3_users() {
    local rest="$1" where="$2" u t
    local -a named=()
    _AID_V3_USERS=()
    while [[ -n "$rest" ]]; do
        u="${rest%%,*}"
        if [[ "$rest" == *,* ]]; then rest="${rest#*,}"; else rest=""; fi
        [[ -z "$u" ]] && continue
        if ! _aid_v3_known_tool "$u"; then
            echo "ERROR: aid-install-core: manifest model: unknown tool '${u}' in ${where}" >&2
            return 1
        fi
        named+=("$u")
    done
    for t in "${AID_TOOLS[@]}"; do
        for u in "${named[@]+"${named[@]}"}"; do
            if [[ "$u" == "$t" ]]; then
                _AID_V3_USERS+=("$t")
                break
            fi
        done
    done
    return 0
}

# Writer helpers. Every helper that renders JSON takes an output variable name first.
_v3_pad() { printf -v "$1" '%*s' "$2" ''; }

# _v3_quote <outvar> <string> - JSON string literal (escapes backslash, quote, LF, CR, TAB).
_v3_quote() {
    local s="$2"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    printf -v "$1" '"%s"' "$s"
}

# _v3_join <outvar> <piece> - append <piece> to a member list, comma + LF separated.
_v3_join() {
    if [[ -n "${!1}" ]]; then
        printf -v "$1" '%s,\n%s' "${!1}" "$2"
    else
        printf -v "$1" '%s' "$2"
    fi
}

# _v3_member <outvar> <indent> <key> <json-value> - one "key": value member line.
_v3_member() {
    local __pad __kq
    _v3_pad __pad "$2"
    _v3_quote __kq "$3"
    printf -v "$1" '%s%s: %s' "$__pad" "$__kq" "$4"
}

# _v3_obj <outvar> <indent> <members> - object whose members already sit at indent+2.
_v3_obj() {
    local __pad
    if [[ -z "$3" ]]; then
        printf -v "$1" '%s' '{}'
        return 0
    fi
    _v3_pad __pad "$2"
    printf -v "$1" '{\n%s\n%s}' "$3" "$__pad"
}

# _v3_strarr <outvar> <indent> <newline-separated items> - array of strings; empty -> [].
_v3_strarr() {
    local __pad __pad2 __line __q __body=""
    _v3_pad __pad $(($2 + 2))
    while IFS= read -r __line; do
        [[ -z "$__line" ]] && continue
        _v3_quote __q "$__line"
        _v3_join __body "${__pad}${__q}"
    done <<< "$3"
    if [[ -z "$__body" ]]; then
        printf -v "$1" '%s' '[]'
        return 0
    fi
    _v3_pad __pad2 "$2"
    printf -v "$1" '[\n%s\n%s]' "$__body" "$__pad2"
}

# _v3_filesarr <outvar> <indent> <newline-separated "path<TAB>sha256" records, sorted>
# Array of {"path", "sha256"} objects; empty -> [].
_v3_filesarr() {
    local __pad __pad2 __line __p __s __qp __qs __m __om __obj __body=""
    _v3_pad __pad $(($2 + 2))
    while IFS= read -r __line; do
        [[ -z "$__line" ]] && continue
        __p="${__line%%$'\t'*}"
        __s="${__line#*$'\t'}"
        _v3_quote __qp "$__p"
        _v3_quote __qs "$__s"
        __om=""
        _v3_member __m $(($2 + 4)) path "$__qp"
        _v3_join __om "$__m"
        _v3_member __m $(($2 + 4)) sha256 "$__qs"
        _v3_join __om "$__m"
        _v3_obj __obj $(($2 + 2)) "$__om"
        _v3_join __body "${__pad}${__obj}"
    done <<< "$3"
    if [[ -z "$__body" ]]; then
        printf -v "$1" '%s' '[]'
        return 0
    fi
    _v3_pad __pad2 "$2"
    printf -v "$1" '[\n%s\n%s]' "$__body" "$__pad2"
}

# _v3_sorted <outvar> <newline-separated records> - LC_ALL=C sorted copy, empty lines dropped.
_v3_sorted() {
    local __s
    __s="$(printf '%s\n' "$2" | LC_ALL=C sort | LC_ALL=C grep -v '^$')"
    printf -v "$1" '%s' "$__s"
}

# _manifest_write_v3_bash <manifest> <model> - pure-bash format-3 writer.
_manifest_write_v3_bash() {
    local manifest="$1" model="$2"
    local -A sc=() lst=()
    local line rest key k t e u dir ver csv pre out tmp mdir present
    local -a f=()
    local keys items recs sorted_recs frecs mirs paths qv m mm mval arr piece
    local ent_members="" shared_members="" tools_members="" top="" tv sv hv hm

    if [[ ! -r "$model" ]]; then
        echo "ERROR: aid-install-core: manifest model not readable: ${model}" >&2
        return 1
    fi
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        f=()
        rest="$line"
        while [[ "$rest" == *$'\t'* ]]; do
            f+=("${rest%%$'\t'*}")
            rest="${rest#*$'\t'}"
        done
        f+=("$rest")
        key="${f[0]}"
        case "$key" in
            shared.skills.file|shared.runtime.file|tools.*.file)
                lst[$key]+="${f[1]:-}"$'\t'"${f[2]:-}"$'\n' ;;
            shared.mirror)
                lst[$key]+="${f[1]:-}"$'\t'"${f[2]:-}"$'\t'"${f[3]:-}"$'\n' ;;
            tools.*.mirror)
                lst[$key]+="${f[1]:-}"$'\n' ;;
            *)
                sc[$key]="${f[1]:-}" ;;
        esac
    done < "$model"

    for key in "${!sc[@]}" "${!lst[@]}"; do
        case "$key" in
            tools.*)
                t="${key#tools.}"
                t="${t%%.*}"
                if ! _aid_v3_known_tool "$t"; then
                    echo "ERROR: aid-install-core: manifest model ${model}: unknown tool '${t}'" >&2
                    return 1
                fi ;;
        esac
    done

    # shared entries: skills, runtime, agents_md, claude_md (absent when no users).
    for e in skills runtime agents_md claude_md; do
        _aid_v3_users "${sc[shared.${e}.users]:-}" "shared.${e}" || return 1
        [[ "${#_AID_V3_USERS[@]}" -eq 0 ]] && continue
        case "$e" in
            skills|runtime) keys="root version users files" ;;
            agents_md)      keys="path version users region_sha256 file_sha256" ;;
            claude_md)      keys="path version users region_sha256" ;;
        esac
        ent_members=""
        for k in $keys; do
            case "$k" in
                users)
                    printf -v items '%s\n' "${_AID_V3_USERS[@]}"
                    _v3_strarr arr 6 "$items"
                    _v3_member piece 6 users "$arr"
                    _v3_join ent_members "$piece" ;;
                files)
                    _v3_sorted sorted_recs "${lst[shared.${e}.file]:-}"
                    _v3_filesarr arr 6 "$sorted_recs"
                    _v3_member piece 6 files "$arr"
                    _v3_join ent_members "$piece" ;;
                *)
                    if [[ -n "${sc[shared.${e}.${k}]+set}" ]]; then
                        _v3_quote qv "${sc[shared.${e}.${k}]}"
                        _v3_member piece 6 "$k" "$qv"
                        _v3_join ent_members "$piece"
                    fi ;;
            esac
        done
        _v3_obj mval 4 "$ent_members"
        _v3_member piece 4 "$e" "$mval"
        _v3_join shared_members "$piece"
    done

    # shared.mirrors: one object per mirror dir that has users.
    recs="${lst[shared.mirror]:-}"
    if [[ -n "$(printf '%s\n' "$recs" | cut -f1 | LC_ALL=C sort | uniq -d)" ]]; then
        echo "ERROR: aid-install-core: manifest model ${model}: duplicate shared.mirror directory" >&2
        return 1
    fi
    _v3_sorted sorted_recs "$recs"
    ent_members=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        dir="${line%%$'\t'*}"
        rest="${line#*$'\t'}"
        ver="${rest%%$'\t'*}"
        csv="${rest#*$'\t'}"
        _aid_v3_users "$csv" "shared.mirror ${dir}" || return 1
        [[ "${#_AID_V3_USERS[@]}" -eq 0 ]] && continue
        printf -v items '%s\n' "${_AID_V3_USERS[@]}"
        _v3_strarr arr 8 "$items"
        _v3_quote qv "$ver"
        mm=""
        _v3_member m 8 version "$qv"
        _v3_join mm "$m"
        _v3_member m 8 users "$arr"
        _v3_join mm "$m"
        _v3_obj mval 6 "$mm"
        _v3_member m 6 "$dir" "$mval"
        _v3_join ent_members "$m"
    done <<< "$sorted_recs"
    if [[ -n "$ent_members" ]]; then
        _v3_obj mval 4 "$ent_members"
        _v3_member piece 4 mirrors "$mval"
        _v3_join shared_members "$piece"
    fi
    _v3_obj sv 2 "$shared_members"

    # tools: AID_TOOLS order; a tool is present when any of its records exists.
    for t in "${AID_TOOLS[@]}"; do
        pre="tools.${t}."
        present=0
        for key in "${!sc[@]}" "${!lst[@]}"; do
            [[ "$key" == "$pre"* ]] && present=1
        done
        [[ "$present" -eq 1 ]] || continue
        mm=""
        _v3_quote qv "${sc[${pre}version]:-}"
        _v3_member m 6 version "$qv"
        _v3_join mm "$m"
        _v3_quote qv "${sc[${pre}installed_at]:-}"
        _v3_member m 6 installed_at "$qv"
        _v3_join mm "$m"
        _v3_sorted mirs "${lst[${pre}mirror]:-}"
        _v3_strarr arr 6 "$mirs"
        _v3_member m 6 mirrors "$arr"
        _v3_join mm "$m"
        if [[ -n "${sc[${pre}worktree_root]+set}" ]]; then
            _v3_quote qv "${sc[${pre}worktree_root]}"
            _v3_member m 6 worktree_root "$qv"
            _v3_join mm "$m"
        fi
        if [[ -n "${sc[${pre}rules_inline]+set}" ]]; then
            if [[ "${sc[${pre}rules_inline]}" != "true" ]]; then
                echo "ERROR: aid-install-core: manifest model ${model}: rules_inline must be true (${t})" >&2
                return 1
            fi
            _v3_member m 6 rules_inline true
            _v3_join mm "$m"
        fi
        _v3_sorted frecs "${lst[${pre}file]:-}"
        _v3_filesarr arr 6 "$frecs"
        _v3_member m 6 files "$arr"
        _v3_join mm "$m"
        paths="$(printf '%s\n' "$frecs" | cut -f1 | LC_ALL=C grep -v '^$')"
        _v3_strarr arr 6 "$paths"
        _v3_member m 6 paths "$arr"
        _v3_join mm "$m"
        _v3_obj tv 4 "$mm"
        _v3_member m 4 "$t" "$tv"
        _v3_join tools_members "$m"
    done
    _v3_obj tv 2 "$tools_members"

    _v3_member m 2 format_version 3
    _v3_join top "$m"
    _v3_quote qv "${sc[aid_version]:-}"
    _v3_member m 2 aid_version "$qv"
    _v3_join top "$m"
    _v3_quote qv "${sc[installed_at]:-}"
    _v3_member m 2 installed_at "$qv"
    _v3_join top "$m"
    _v3_quote qv "${sc[host.worktree_root]:-.aid/.worktrees}"
    _v3_member hm 4 worktree_root "$qv"
    _v3_obj hv 2 "$hm"
    _v3_member m 2 host "$hv"
    _v3_join top "$m"
    _v3_member m 2 shared "$sv"
    _v3_join top "$m"
    _v3_member m 2 tools "$tv"
    _v3_join top "$m"
    printf -v out '{\n%s\n}\n' "$top"

    mdir="$(dirname "$manifest")"
    mkdir -p "$mdir" || return 1
    tmp="$(mktemp "${mdir}/.manifest.tmp.XXXXXX")" || return 1
    if ! printf '%s' "$out" > "$tmp"; then
        rm -f "$tmp"
        return 1
    fi
    if ! mv "$tmp" "$manifest"; then
        rm -f "$tmp"
        return 1
    fi
    return 0
}

# _manifest_write_v3_python <manifest> <model> - python3 format-3 writer (fast path).
_manifest_write_v3_python() {
    python3 - "$1" "$2" "${AID_TOOLS[@]}" <<'PY'
import json, os, sys, tempfile

manifest, model = sys.argv[1], sys.argv[2]
tools_order = sys.argv[3:]

def fail(msg):
    sys.stderr.write("ERROR: aid-install-core: manifest model %s: %s\n" % (model, msg))
    sys.exit(1)

def users_of(csv, where):
    names = [u for u in csv.split(",") if u != ""]
    for u in names:
        if u not in tools_order:
            fail("unknown tool '%s' in %s" % (u, where))
    return [t for t in tools_order if t in names]

try:
    with open(model, encoding="utf-8", newline="") as fh:
        text = fh.read()
except Exception as e:
    fail("not readable (%s)" % e)

S, L = {}, {}
for raw in text.split("\n"):
    if raw == "":
        continue
    f = raw.split("\t")
    def fld(i):
        return f[i] if len(f) > i else ""
    key = f[0]
    if key == "shared.mirror":
        L.setdefault(key, []).append((fld(1), fld(2), fld(3)))
    elif key.startswith("tools.") and key.endswith(".mirror"):
        L.setdefault(key, []).append(fld(1))
    elif key.endswith(".file") and (key.startswith("tools.") or key in ("shared.skills.file", "shared.runtime.file")):
        L.setdefault(key, []).append((fld(1), fld(2)))
    else:
        S[key] = fld(1)

for key in list(S.keys()) + list(L.keys()):
    if key.startswith("tools."):
        t = key.split(".")[1]
        if t not in tools_order:
            fail("unknown tool '%s'" % t)

ORDER = {
    "skills": ["root", "version", "users", "files"],
    "runtime": ["root", "version", "users", "files"],
    "agents_md": ["path", "version", "users", "region_sha256", "file_sha256"],
    "claude_md": ["path", "version", "users", "region_sha256"],
}
shared = {}
for e in ["skills", "runtime", "agents_md", "claude_md"]:
    users = users_of(S.get("shared.%s.users" % e, ""), "shared.%s" % e)
    if not users:
        continue
    ent = {}
    for k in ORDER[e]:
        if k == "users":
            ent[k] = users
        elif k == "files":
            ent[k] = [{"path": p, "sha256": s} for (p, s) in sorted(L.get("shared.%s.file" % e, []))]
        elif ("shared.%s.%s" % (e, k)) in S:
            ent[k] = S["shared.%s.%s" % (e, k)]
    shared[e] = ent

mrecs = sorted(L.get("shared.mirror", []))
dirs = [d for (d, v, c) in mrecs]
if len(set(dirs)) != len(dirs):
    fail("duplicate shared.mirror directory")
mirrors = {}
for (d, v, c) in mrecs:
    us = users_of(c, "shared.mirror %s" % d)
    if us:
        mirrors[d] = {"version": v, "users": us}
if mirrors:
    shared["mirrors"] = mirrors

tools = {}
for t in tools_order:
    pre = "tools.%s." % t
    if not any(k.startswith(pre) for k in list(S.keys()) + list(L.keys())):
        continue
    ent = {"version": S.get(pre + "version", ""), "installed_at": S.get(pre + "installed_at", "")}
    ent["mirrors"] = sorted(L.get(pre + "mirror", []))
    if (pre + "worktree_root") in S:
        ent["worktree_root"] = S[pre + "worktree_root"]
    if (pre + "rules_inline") in S:
        if S[pre + "rules_inline"] != "true":
            fail("rules_inline must be true (%s)" % t)
        ent["rules_inline"] = True
    files = sorted(L.get(pre + "file", []))
    ent["files"] = [{"path": p, "sha256": s} for (p, s) in files]
    ent["paths"] = [p for (p, s) in files]
    tools[t] = ent

out = {
    "format_version": 3,
    "aid_version": S.get("aid_version", ""),
    "installed_at": S.get("installed_at", ""),
    "host": {"worktree_root": S.get("host.worktree_root") or ".aid/.worktrees"},
    "shared": shared,
    "tools": tools,
}

d = os.path.dirname(manifest) or "."
try:
    os.makedirs(d, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=d, suffix=".tmp")
except Exception as e:
    sys.stderr.write("ERROR: aid-install-core: manifest write failed: %s\n" % e)
    sys.exit(1)
try:
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(out, fh, indent=2)
        fh.write("\n")
    os.replace(tmp, manifest)
except Exception as e:
    try:
        os.unlink(tmp)
    except OSError:
        pass
    sys.stderr.write("ERROR: aid-install-core: manifest write failed: %s\n" % e)
    sys.exit(1)
PY
}

# manifest_write_v3 <manifest> <model> - write a format-3 manifest atomically.
# Uses python3 when available, else the pure-bash writer (byte-identical output).
manifest_write_v3() {
    if command -v python3 >/dev/null 2>&1; then
        _manifest_write_v3_python "$1" "$2"
    else
        _manifest_write_v3_bash "$1" "$2"
    fi
}

# Readers. _aid_v3_flatten prints each scalar and array element of a pretty-printed
# JSON manifest as TAB-separated path segments followed by the value. Array elements
# are numbered from 0. Only the layout the writers emit is supported.
_aid_v3_flatten() {
    awk '
    function jn(a, b) { return (a == "") ? b : a "\t" b }
    {
        if (match($0, /[^ ]/) == 0) next
        lvl = (RSTART - 1) / 2
        body = substr($0, RSTART)
        sub(/,$/, "", body)
        if (lvl == 0) { P[1] = ""; next }
        if (body == "{" || body == "[") {
            n = cnt[P[lvl]]++
            P[lvl + 1] = jn(P[lvl], n)
            next
        }
        if (body ~ /^[]}]/) next
        if (body ~ /^"[^"]*"$/) {
            n = cnt[P[lvl]]++
            print jn(P[lvl], n) "\t" substr(body, 2, length(body) - 2)
            next
        }
        rest = substr(body, 2)
        q = index(rest, "\"")
        key = substr(rest, 1, q - 1)
        val = substr(rest, q + 3)
        if (val == "{" || val == "[") { P[lvl + 1] = jn(P[lvl], key); next }
        if (val == "{}" || val == "[]") next
        if (substr(val, 1, 1) == "\"") val = substr(val, 2, length(val) - 2)
        print jn(P[lvl], key) "\t" val
    }' "$1"
}

# _aid_v3_read_awk <manifest> <mode> [tool] - pure-bash reader (mode: format|host|shared|tool).
_aid_v3_read_awk() {
    _aid_v3_flatten "$1" | awk -v mode="$2" -v tool="${3:-}" '
    BEGIN { FS = "\t"; E[1] = "skills"; E[2] = "runtime"; E[3] = "agents_md"; E[4] = "claude_md" }
    mode == "format" && NF == 2 && $1 == "format_version" { print $2; next }
    mode == "host" && NF == 3 && $1 == "host" && $2 == "worktree_root" { print "host.worktree_root\t" $3; next }
    mode == "shared" {
        if (NF == 4 && $1 == "shared" && $2 ~ /^(skills|runtime|agents_md|claude_md)$/ && $3 ~ /^(root|path|version|region_sha256|file_sha256)$/) {
            print "shared." $2 "." $3 "\t" $4
        } else if (NF == 5 && $1 == "shared" && $2 ~ /^(skills|runtime|agents_md|claude_md)$/ && $3 == "users") {
            if (ucsv[$2] != "") ucsv[$2] = ucsv[$2] ","
            ucsv[$2] = ucsv[$2] $5
        } else if (NF == 6 && $1 == "shared" && $2 ~ /^(skills|runtime)$/ && $3 == "files") {
            if ($5 == "path") pend[$2] = $6
            else if ($5 == "sha256") print "shared." $2 ".file\t" pend[$2] "\t" $6
        } else if (NF == 5 && $1 == "shared" && $2 == "mirrors" && $4 == "version") {
            if (!($3 in mseen)) { mseen[$3] = 1; mord[++nm] = $3 }
            mver[$3] = $5
        } else if (NF == 6 && $1 == "shared" && $2 == "mirrors" && $4 == "users") {
            if (!($3 in mseen)) { mseen[$3] = 1; mord[++nm] = $3 }
            if (mcsv[$3] != "") mcsv[$3] = mcsv[$3] ","
            mcsv[$3] = mcsv[$3] $6
        }
    }
    mode == "tool" && $1 == "tools" && $2 == tool {
        if (NF == 5 && $3 == "mirrors") print "tools." tool ".mirror\t" $5
        else if (NF == 4 && ($3 == "worktree_root" || $3 == "rules_inline")) print "tools." tool "." $3 "\t" $4
        else if (NF == 6 && $3 == "files") {
            if ($5 == "path") tpend = $6
            else if ($5 == "sha256") print "tools." tool ".file\t" tpend "\t" $6
        }
    }
    END {
        if (mode == "shared") {
            for (i = 1; i <= 4; i++) if (E[i] in ucsv) print "shared." E[i] ".users\t" ucsv[E[i]]
            for (i = 1; i <= nm; i++) print "shared.mirror\t" mord[i] "\t" mver[mord[i]] "\t" mcsv[mord[i]]
        }
    }'
}

# _manifest_v3_read_python <manifest> <mode> [tool] - python3 reader (same records as the awk reader).
_manifest_v3_read_python() {
    python3 - "$1" "$2" "${3:-}" <<'PY'
import json, sys

manifest, mode, tool = sys.argv[1], sys.argv[2], sys.argv[3]
try:
    with open(manifest, encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
out = []
if mode == "format":
    if "format_version" in data:
        out.append(str(data["format_version"]))
elif mode == "host":
    host = data.get("host")
    if isinstance(host, dict) and "worktree_root" in host:
        out.append("host.worktree_root\t" + str(host["worktree_root"]))
elif mode == "shared":
    shared = data.get("shared") if isinstance(data.get("shared"), dict) else {}
    for e in ["skills", "runtime", "agents_md", "claude_md"]:
        ent = shared.get(e)
        if not isinstance(ent, dict):
            continue
        for k, v in ent.items():
            if k == "users":
                out.append("shared.%s.users\t%s" % (e, ",".join(v)))
            elif k == "files":
                for f in v:
                    out.append("shared.%s.file\t%s\t%s" % (e, f["path"], f["sha256"]))
            else:
                out.append("shared.%s.%s\t%s" % (e, k, v))
    mirrors = shared.get("mirrors") if isinstance(shared.get("mirrors"), dict) else {}
    for d, m in mirrors.items():
        out.append("shared.mirror\t%s\t%s\t%s" % (d, m.get("version", ""), ",".join(m.get("users", []))))
elif mode == "tool":
    tools = data.get("tools") if isinstance(data.get("tools"), dict) else {}
    t = tools.get(tool)
    if isinstance(t, dict):
        for m in t.get("mirrors", []):
            out.append("tools.%s.mirror\t%s" % (tool, m))
        if "worktree_root" in t:
            out.append("tools.%s.worktree_root\t%s" % (tool, t["worktree_root"]))
        if t.get("rules_inline") is True:
            out.append("tools.%s.rules_inline\ttrue" % tool)
        for f in t.get("files", []):
            out.append("tools.%s.file\t%s\t%s" % (tool, f["path"], f["sha256"]))
for line in out:
    sys.stdout.write(line + "\n")
PY
}

# _manifest_v3_read <manifest> <mode> [tool] - dispatch: python3 when available, else awk.
_manifest_v3_read() {
    [[ -f "$1" ]] || return 0
    if command -v python3 >/dev/null 2>&1; then
        _manifest_v3_read_python "$1" "$2" "${3:-}"
    else
        _aid_v3_read_awk "$1" "$2" "${3:-}"
    fi
}

# manifest_format <manifest> - print the format_version value (empty when absent).
manifest_format() { _manifest_v3_read "$1" format; }

# manifest_read_shared <manifest> - shared.* records (skills, runtime, agents_md, claude_md, mirrors).
manifest_read_shared() { _manifest_v3_read "$1" shared; }

# manifest_read_tool_files <manifest> <tool> - tools.<tool>.* records: mirror, worktree_root,
# rules_inline (only when declared) and file.
manifest_read_tool_files() { _manifest_v3_read "$1" tool "$2"; }

# manifest_read_host <manifest> - host.worktree_root record.
manifest_read_host() { _manifest_v3_read "$1" host; }

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

    if [[ ! -f "$manifest" ]] || ! grep -qE '"(manifest_version|format_version)"' "$manifest" 2>/dev/null; then
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
# Reads <target>/.aid/.aid-manifest.json.
# Returns:
#   0 - manifest found; status printed to stdout.
#   7 - no manifest in <target>; "not an AID project here" message printed to stdout.
aid_status() {
    local target="${1:-.}"
    local manifest="${target}/.aid/.aid-manifest.json"
    local cwd_display
    cwd_display="$(cd "$target" && pwd)"

    if [[ ! -f "$manifest" ]] || ! grep -qE '"(manifest_version|format_version)"' "$manifest" 2>/dev/null; then
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
    if grep -qE '"(manifest_version|format_version)"' "$manifest" 2>/dev/null; then
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
    # New layout (work-005/delivery-001): codex is unified under .codex/;
    # cursor and antigravity no longer ship rules/ dirs.
    # ------------------------------------------------------------------
    case "$tool" in
        claude-code)
            _prune_native_dir "${target}/.claude/agents"
            _prune_native_dir "${target}/.claude/skills"
            _prune_aid_subtree "${target}/.claude/aid"
            ;;
        codex)
            # New unified layout: everything under .codex/ (agents, skills, aid).
            _prune_native_dir "${target}/.codex/agents"
            _prune_native_dir "${target}/.codex/skills"
            _prune_aid_subtree "${target}/.codex/aid"
            ;;
        cursor)
            # rules/ dir removed from new layout; agents/skills/aid remain.
            _prune_native_dir "${target}/.cursor/agents"
            _prune_native_dir "${target}/.cursor/skills"
            _prune_aid_subtree "${target}/.cursor/aid"
            ;;
        copilot-cli)
            # R1: scope to .github/{agents,skills,aid} ONLY -- never .github root.
            _prune_native_dir "${target}/.github/agents"
            _prune_native_dir "${target}/.github/skills"
            _prune_aid_subtree "${target}/.github/aid"
            ;;
        antigravity)
            # rules/ dir removed from new layout; agents/skills/aid remain.
            _prune_native_dir "${target}/.agent/agents"
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
# Retired-root migration sweep (FR7/FR7a)
# ---------------------------------------------------------------------------

# _migrate_retired_layout <target> <tool>
#
# Complete-replacement migration: removes AID-owned content from the static
# list of retired AID roots that no longer exist in the new bundle layout.
# Called from install_tool BEFORE _prune_tool_dirs (same aid update pass).
#
# Retired roots swept per tool:
#   codex:       .agents/                     (split layout retired)
#   cursor:      .cursor/rules/               (rules dir retired)
#   antigravity: .agent/rules/                (rules dir retired)
#   all tools:   .cursor/rules/, .agent/rules/ are cursor/antigravity only
#
# Ownership markers applied (content-isolation.md rules 1+2):
#   Marker 1: filename starts with "aid-" (tool-native dir files)
#   Marker 2: lives inside an "aid/" subtree
#
# Marker 3 (AID:BEGIN/END region in root files) is NOT touched here;
# that is handled by _copy_root_agent_file exclusively.
#
# User content (no marker) is NEVER removed.
# Idempotent: a no-op when the retired path is already absent.
# Returns count of retired items removed (written to _MIGRATE_RETIRED_COUNT).
_migrate_retired_layout() {
    local target="$1"
    local tool="$2"
    local list_only="${3:-0}"   # 1 = dry-run enumeration only (no removals)
    _MIGRATE_RETIRED_COUNT=0

    # Return 1 if a file is AID-owned (marker 1 or 2); 0 if user content.
    _is_aid_owned_file() {
        local f="$1"
        local base
        base="$(basename "$f")"
        # Marker 1: aid- prefix.
        if [[ "$base" == aid-* ]]; then return 0; fi
        # Marker 2: lives inside an aid/ folder (any path component named "aid").
        local dir
        dir="$(dirname "$f")"
        while [[ "$dir" != "$target" && "$dir" != "/" && "$dir" != "." ]]; do
            if [[ "$(basename "$dir")" == "aid" ]]; then return 0; fi
            dir="$(dirname "$dir")"
        done
        # No marker -- user content.
        return 1
    }

    # Move one AID-owned file (marker 1 or 2) to <target>/.aid/.trash/<rel-path>.
    # In list_only mode: print the path instead of moving it (no writes).
    _retire_file() {
        local f="$1"
        [[ -f "$f" ]] || return 0
        if _is_aid_owned_file "$f"; then
            if [[ "$list_only" -eq 1 ]]; then
                echo "  move to trash: ${f}"
                _MIGRATE_RETIRED_COUNT=$((_MIGRATE_RETIRED_COUNT + 1))
            else
                # Move to <target>/.aid/.trash/<rel> under the shared collision policy.
                local rel dest
                rel="${f#${target}/}"
                dest="${target}/.aid/.trash/${rel}"
                trash_file "$target" "$f" || return 1
                _MIGRATE_RETIRED_COUNT=$((_MIGRATE_RETIRED_COUNT + 1))
                if [[ "${AID_VERBOSE:-0}" -eq 1 ]]; then echo "Trashed: ${f} -> ${dest}"; fi
            fi
        fi
        return 0
    }

    # Sweep one retired root directory: remove AID-owned files, then prune
    # now-empty subdirs, then remove the root dir itself if now empty.
    # In list_only mode: enumerate would-be-removed files, make no changes.
    _sweep_retired_root() {
        local rdir="$1"
        [[ -d "$rdir" ]] || return 0
        # Walk all files under the retired root.
        local fpath
        while IFS= read -r -d '' fpath; do
            _retire_file "$fpath"
        done < <(find "$rdir" -type f -print0 2>/dev/null | sort -z)
        if [[ "$list_only" -eq 1 ]]; then return 0; fi
        # Prune now-empty subdirs (deepest first).
        local dpath
        while IFS= read -r dpath; do
            if [[ -d "$dpath" ]]; then
                local rem
                rem="$(find "$dpath" -mindepth 1 2>/dev/null | head -1)"
                if [[ -z "$rem" ]]; then
                    rmdir "$dpath" 2>/dev/null || true
                    if [[ "${AID_VERBOSE:-0}" -eq 1 ]]; then echo "Retired dir: ${dpath}"; fi
                fi
            fi
        done < <(find "$rdir" -mindepth 1 -type d 2>/dev/null | sort -r)
        # Remove the retired root itself if now empty.
        if [[ -d "$rdir" ]]; then
            local rem
            rem="$(find "$rdir" -mindepth 1 2>/dev/null | head -1)"
            if [[ -z "$rem" ]]; then
                rmdir "$rdir" 2>/dev/null || true
                if [[ "${AID_VERBOSE:-0}" -eq 1 ]]; then echo "Retired root dir: ${rdir}"; fi
            fi
        fi
        return 0
    }

    case "$tool" in
        codex)
            # Retired root: .agents/ (old split layout -- skills/ + aid/ lived here).
            _sweep_retired_root "${target}/.agents"
            ;;
        cursor)
            # Retired root: .cursor/rules/ (rules dir no longer in new layout).
            _sweep_retired_root "${target}/.cursor/rules"
            ;;
        antigravity)
            # Retired root: .agent/rules/ (rules dir no longer in new layout).
            _sweep_retired_root "${target}/.agent/rules"
            ;;
        # claude-code and copilot-cli have no retired roots in this migration.
    esac

    if [[ "$list_only" -eq 0 && "$_MIGRATE_RETIRED_COUNT" -gt 0 ]]; then
        echo "  ${_MIGRATE_RETIRED_COUNT} retired AID file(s) moved to .aid/.trash/"
    fi

    unset -f _is_aid_owned_file _retire_file _sweep_retired_root
}

# _migrate_term_exclusions <target>
# One-time migration (work-014): carry user-confirmed term exclusions from the retired KB
# dotfile .aid/knowledge/.term-exclusions.md into settings.yml discovery.term_exclusions,
# then retire the file to .aid/.trash/. No-op when the file is absent.
_migrate_term_exclusions() {
    local target="$1"
    local kb_file="${target}/.aid/knowledge/.term-exclusions.md"
    [[ -f "$kb_file" ]] || return 0

    local settings="${target}/.aid/settings.yml"
    local terms
    terms="$(grep -E '^[[:space:]]*-[[:space:]]' "$kb_file" 2>/dev/null \
        | sed -E 's/^[[:space:]]*-[[:space:]]+//; s/[[:space:]]+#.*$//; s/[[:space:]]+$//' \
        | grep -v '^$' || true)"

    # If there are terms to preserve but no settings.yml to place them in, do NOT
    # retire the file -- that would drop the only copy. Leave it for a later run
    # (settings.yml is normally seeded before this migration).
    [[ -n "$terms" && ! -f "$settings" ]] && return 0

    if [[ -n "$terms" ]]; then
        # Does discovery.term_exclusions ALREADY exist? Scoped to the discovery
        # section so a term_exclusions: under some OTHER section can't cause a
        # false skip (which would drop the terms on retire).
        local has_te
        # Match only the immediate child (exactly 2-space indent) -- the level
        # injection writes at -- so a deeper key (discovery.closure.term_exclusions)
        # cannot be mistaken for discovery.term_exclusions.
        has_te="$(awk '
            /^discovery:[[:space:]]*(#.*)?$/ { in_disc=1; next }
            in_disc && /^[^[:space:]#]/  { in_disc=0 }
            in_disc && /^  term_exclusions:/ { found=1 }
            END { print (found ? "1" : "0") }
        ' "$settings")"

        if [[ "$has_te" != "1" ]]; then
            local tmp="${settings}.aidtmp" inserted=0 line
            : > "$tmp"
            while IFS= read -r line || [[ -n "$line" ]]; do
                printf '%s\n' "$line" >> "$tmp"
                # Match discovery: even with a trailing comment (discovery: # ...).
                if [[ "$inserted" -eq 0 && "$line" =~ ^discovery:[[:space:]]*(#.*)?$ ]]; then
                    printf '  term_exclusions:\n' >> "$tmp"
                    printf '%s\n' "$terms" | sed 's/^/    - /' >> "$tmp"
                    inserted=1
                fi
            done < "$settings"
            [[ "$inserted" -eq 0 ]] && {
                printf 'discovery:\n  term_exclusions:\n' >> "$tmp"
                printf '%s\n' "$terms" | sed 's/^/    - /' >> "$tmp"
            }
            mv -f "$tmp" "$settings"
        fi
    fi

    # Safe to retire now: terms (if any) are placed in discovery.term_exclusions,
    # already present there, or the file carried nothing to preserve.
    local dest="${target}/.aid/.trash/knowledge/.term-exclusions.md"
    mkdir -p "$(dirname "$dest")"
    mv -f "$kb_file" "$dest"
    echo "  Migrated term exclusions to settings.yml; retired .aid/knowledge/.term-exclusions.md to .aid/.trash/"
}

# ---------------------------------------------------------------------------
# Project-level provisioning (work-007): required runtime file + VCS hygiene.
# Both are idempotent and safe to run once per tool during a multi-tool add.
# ---------------------------------------------------------------------------

# seed_settings_yml <target> <tool>
# Seed <target>/.aid/settings.yml from the tool's just-installed template when it
# does not already exist. NEVER overwrites an existing settings.yml -- it holds
# user config (project identity, grades). Not recorded in the manifest: it is
# user data and must survive `aid remove`/prune and never flow through the copy
# engine. Sets _CORE_SEEDED_SETTINGS=1 when a file was created, else 0.
seed_settings_yml() {
    local target="$1" tool="$2"
    local root dst tmpl
    _CORE_SEEDED_SETTINGS=0
    root="$(_root_dir "$tool")"
    [[ -z "$root" ]] && return 0
    dst="${target}/.aid/settings.yml"
    tmpl="${target}/${root}/aid/templates/settings.yml"
    [[ -f "$dst" ]] && return 0        # never clobber user config
    # Template absent -> a tool bundle shipped without aid/templates/settings.yml.
    # Surface it (work-007 C5): a silent skip re-triggers the "no settings.yml"
    # class this seed exists to fix, and the format gate would then warn forever.
    if [[ ! -f "$tmpl" ]]; then
        echo "WARN: aid-install-core: settings template missing (${tmpl}); .aid/settings.yml not seeded for '${tool}'." >&2
        return 0
    fi
    mkdir -p "${target}/.aid"
    # Seed from the template, but STAMP the format_version as the first line so
    # the settings-format gate does not warn on every subsequent command (the raw
    # template ships unstamped; era-b synthesis stamps -- we match it here). The
    # value mirrors bin/aid's AID_SUPPORTED_FORMAT (fallback 5 for install.sh).
    local _fmt _seed_tmp
    _fmt="${AID_SUPPORTED_FORMAT:-5}"
    _seed_tmp="$(mktemp "${dst}.aid-tmp.XXXXXX")" || {
        echo "WARN: aid-install-core: could not create temp file to seed .aid/settings.yml for '${tool}'." >&2
        return 0
    }
    if grep -q '^format_version:' "$tmpl" 2>/dev/null; then
        cp "$tmpl" "$_seed_tmp"
    else
        { printf 'format_version: %s\n' "$_fmt"; cat "$tmpl"; } > "$_seed_tmp"
    fi
    if ! mv -f "$_seed_tmp" "$dst"; then
        rm -f "$_seed_tmp" 2>/dev/null
        echo "WARN: aid-install-core: could not write .aid/settings.yml for '${tool}'." >&2
        return 0
    fi
    _CORE_SEEDED_SETTINGS=1
    return 0
}

# AID-managed .gitignore region markers. The lines BETWEEN the markers are owned
# by the installer and rewritten on every add/update; everything OUTSIDE the
# markers is preserved verbatim (mirrors the root-agent region-update pattern).
_AID_GI_BEGIN="# >>> AID managed -- do not edit (aid add/update maintains this block) >>>"
_AID_GI_END="# <<< AID managed <<<"

# _aid_gitignore_block - print the current AID-managed .gitignore block (markers
# inclusive). The exclusion set is the single source of truth for transient
# .aid/ artifacts that must never be committed.
_aid_gitignore_block() {
    printf '%s\n' "$_AID_GI_BEGIN"
    printf '%s\n' \
        ".aid/.temp/" \
        ".aid/.trash/" \
        ".aid/.heartbeat/" \
        ".aid/.control/" \
        ".aid/generated/" \
        ".aid/knowledge/.cache/"
    printf '%s' "$_AID_GI_END"
}

# update_gitignore <target>
# Ensure <target>/.gitignore carries the AID-managed region with the current
# transient .aid/ exclusions. Creates the file if absent; otherwise strips any
# existing AID region, preserves all user content, and appends a fresh region
# (with a single blank-line separator). Idempotent: a second run produces a
# byte-identical file. Sets _CORE_GITIGNORE_ACTION to created|updated|unchanged.
update_gitignore() {
    local target="$1"
    local gi="${target}/.gitignore"
    local block tmp
    _CORE_GITIGNORE_ACTION="unchanged"
    block="$(_aid_gitignore_block)"

    if [[ ! -f "$gi" ]]; then
        printf '%s\n' "$block" > "$gi"
        _CORE_GITIGNORE_ACTION="created"
        return 0
    fi

    # Normalize the existing file to LF for BOTH processing and comparison, so a
    # line-ending-only difference (a CRLF .gitignore) does NOT force a rewrite
    # every run. Parity with PS Update-AidGitignore, which compares CRLF->LF-
    # normalized content (work-007 C3). If unchanged, the original file is left
    # byte-untouched (CRLF preserved); only a real region change triggers a write.
    local norm
    norm="$(mktemp "${target}/.gitignore.norm.XXXXXX")"
    tr -d '\r' < "$gi" > "$norm"

    tmp="$(mktemp "${target}/.gitignore.aid.XXXXXX")"
    awk -v b="$_AID_GI_BEGIN" -v e="$_AID_GI_END" -v blk="$block" '
        $0==b {inblk=1; next}
        inblk && $0==e {inblk=0; next}
        inblk {next}
        {lines[n++]=$0}
        END {
            while (n>0 && lines[n-1] ~ /^[ \t]*$/) n--
            for (i=0;i<n;i++) print lines[i]
            if (n>0) print ""
            print blk
        }
    ' "$norm" > "$tmp"

    if cmp -s "$tmp" "$norm"; then
        rm -f "$tmp" "$norm"
        _CORE_GITIGNORE_ACTION="unchanged"
    else
        rm -f "$norm"
        mv -f "$tmp" "$gi"
        _CORE_GITIGNORE_ACTION="updated"
    fi
    return 0
}

# ---------------------------------------------------------------------------
# High-level install_tool
# ---------------------------------------------------------------------------

# install_tool <staging_dir> <tool> <target> <version> <force>
# <staging_dir> - directory produced by extract_tarball (content of profiles/<tool>/)
# Returns:
#   0 - success (all files installed or up-to-date)
#
# Side effects: writes <target>/.aid/.aid-manifest.json.
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
    _COPY_COUNT_FAILED=0

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
            # New unified layout: .codex/ only (agents, skills, aid all under .codex/).
            # .agents/ is the RETIRED split layout -- handled by _migrate_retired_layout.
            if [[ -d "${staging}/.codex" ]]; then
                copy_dir "${staging}/.codex" "${target}/.codex" "$force"
                while IFS= read -r -d '' f; do
                    local rel="${f#${staging}/}"
                    install_paths+=("$rel")
                done < <(find "${staging}/.codex" -type f -print0 2>/dev/null | sort -z)
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

    # Abort loudly if any AID-owned file failed to copy -- do NOT proceed to
    # write a manifest that records a partial install as success (work-007 C4).
    if [[ "${_COPY_COUNT_FAILED:-0}" -gt 0 ]]; then
        echo "ERROR: aid-install-core: ${_COPY_COUNT_FAILED} file(s) failed to copy for '${tool}'. Install aborted (incomplete)." >&2
        return 1
    fi

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

    # Write manifest (merge). A failure here MUST abort loudly (parity with PS
    # Write-AidManifest, which throws) -- otherwise a failed manifest write is a
    # silent success and later `aid status`/`aid remove`/prune won't see the tool.
    if ! manifest_write "$manifest" "$tool" "$version" "install_paths" "root_entries"; then
        echo "ERROR: aid-install-core: manifest write failed for ${manifest}. Install aborted (files copied but not recorded)." >&2
        return 1
    fi

    # Retired-root migration sweep (FR7/FR7a).
    # Remove AID-owned content from retired layout dirs BEFORE the normal prune,
    # so that old .agents/, .cursor/rules/, .agent/rules/ trees are cleaned up.
    # A non-zero rc from install_tool is treated as a mid-commit failure (caller
    # prints the "re-run to heal" message); this function returns 0 (WARN-not-fail).
    _migrate_retired_layout "$target" "$tool"

    # Prune stale AID-owned files (Pillar 2, R7).
    # Build an associative array from the new manifest path set for O(1) lookup.
    declare -A _prune_manifest_set=()
    local _p
    for _p in "${install_paths[@]+"${install_paths[@]}"}"; do
        _prune_manifest_set["$_p"]=1
    done
    _prune_tool_dirs "$target" "$tool" "_prune_manifest_set"
    unset _prune_manifest_set

    # Project-level provisioning (work-007): seed the required settings.yml and
    # maintain the .gitignore AID region. Both idempotent; safe per-tool.
    seed_settings_yml "$target" "$tool"
    update_gitignore "$target"
    _migrate_term_exclusions "$target"

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

    # Report project-level provisioning actions (work-007; always shown).
    [[ "${_CORE_SEEDED_SETTINGS:-0}" -eq 1 ]] && echo "  Created .aid/settings.yml from template"
    case "${_CORE_GITIGNORE_ACTION:-unchanged}" in
        created) echo "  Created .gitignore with AID exclusions" ;;
        updated) echo "  Updated .gitignore AID exclusions" ;;
    esac

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

    # If no manifest remains (last tool removed), remove the AID-provisioned
    # project files so a full uninstall leaves .aid/ clean (work-007).
    if [[ ! -f "$manifest" ]]; then
        local aid_meta_dir
        aid_meta_dir="$(dirname "$manifest")"
        # Remove the install-time-seeded settings.yml (symmetric with seed_settings_yml).
        # Only fires when NO tools remain -- a partial uninstall keeps settings.yml
        # for the remaining tools.
        rm -f "${aid_meta_dir}/settings.yml"
        # Remove .aid dir if empty.
        if [[ -d "$aid_meta_dir" ]]; then
            local rem
            rem="$(find "$aid_meta_dir" -type f 2>/dev/null | head -1)"
            [[ -z "$rem" ]] && rmdir "$aid_meta_dir" 2>/dev/null || true
        fi
    fi
}
