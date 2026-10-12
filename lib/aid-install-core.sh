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
#   install_tool <staging> <tool> <target>
#                               -> install one tool's staged agents tree (shared payload and root context go through install_shared)
#   read_upgrade_recovery <target>
#                               -> validates the v3 recovery record; sets ordered tool set + retired state
#   write_upgrade_recovery <target> <retired> <tools...>
#                               -> atomically persists the bounded v3 recovery record
#   clear_upgrade_recovery <target>
#                               -> removes a completed v3 recovery record
#   retire_v3_layout <target> <list-only> <tools...>
#                               -> archives v3-owned paths and strips old root regions
#   manifest_read_tool_paths <manifest> <tool>
#                               -> newline-delimited paths from tools.<tool>.paths (stdout)
#   manifest_read_tool_version <manifest> <tool>
#                               -> version string from tools.<tool>.version (stdout)
#   manifest_read_root_agent <manifest> <tool> <path>
#                               -> sha256 from root_agent_files entry (stdout); empty if absent
#   manifest_read_root_agent_status <manifest> <tool> <path>
#                               -> status field from root_agent_files entry (stdout)
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

# _aid_parse_recovery <file> - validate the v3 recovery record with bash only. Prints
# "<retired>\t<tool>\t<tool>..." (tools in AID_TOOLS order) and exits 0, or exits 2 when the
# record is not exactly {"format_version":1,"tools":[...],"retired":true|false} (any key
# order, JSON whitespace between tokens, unique known tools in AID_TOOLS order).
_aid_parse_recovery() {
    local raw compact fv='"format_version":1' tl='"tools":\[(("[a-z-]+"(,"[a-z-]+")*)?)\]' rt='"retired":(true|false)'
    local list retired tool seen="" prev=-1 idx t n i
    local -a names=()
    raw="$(LC_ALL=C cat -- "$1"; printf x)" || return 2
    raw="${raw%x}"
    # Whitespace is legal only between tokens: none inside a quoted string.
    if ! printf '%s' "$raw" | LC_ALL=C awk -F'"' '{ for (i = 2; i <= NF; i += 2) if ($i ~ /[ \t\r]/) bad = 1 } END { exit bad }'; then return 2; fi
    compact="$(printf '%s' "$raw" | LC_ALL=C tr -d ' \t\r\n')"
    [[ "$compact" =~ ^\{(.*)\}$ ]] || return 2
    compact="${BASH_REMATCH[1]}"
    local p1="$fv,$tl,$rt" p2="$fv,$rt,$tl" p3="$tl,$fv,$rt" p4="$tl,$rt,$fv" p5="$rt,$fv,$tl" p6="$rt,$tl,$fv" ok=0 pat
    for pat in "$p1" "$p2" "$p3" "$p4" "$p5" "$p6"; do
        if [[ "$compact" =~ ^${pat}$ ]]; then ok=1; break; fi
    done
    [[ "$ok" -eq 1 ]] || return 2
    [[ "$compact" =~ \"tools\":\[([^]]*)\] ]] || return 2
    list="${BASH_REMATCH[1]}"
    [[ "$compact" =~ \"retired\":(true|false) ]] || return 2
    retired="${BASH_REMATCH[1]}"
    [[ -n "$list" ]] || return 2
    list="${list//\"/}"
    IFS=',' read -r -a names <<< "$list"
    for tool in "${names[@]}"; do
        idx=-1; n=0
        for t in "${AID_TOOLS[@]}"; do
            if [[ "$t" == "$tool" ]]; then idx=$n; fi
            n=$((n + 1))
        done
        [[ "$idx" -gt "$prev" ]] || return 2
        prev=$idx
    done
    printf '%s' "$retired"
    for tool in "${names[@]}"; do printf '\t%s' "$tool"; done
    printf '\n'
}

# read_upgrade_recovery <target> - validate the durable v3 upgrade record.
# Sets _AID_UPGRADE_TOOLS and _AID_UPGRADE_RETIRED; invalid data returns 2.
read_upgrade_recovery() {
    local target="$1" record="${1}/.aid/.temp/v3-upgrade-tools.json" parsed rc
    _AID_UPGRADE_TOOLS=(); _AID_UPGRADE_RETIRED=""
    [[ -e "$record" || -L "$record" ]] || return 1
    if [[ -L "$record" || ! -f "$record" ]]; then
        echo "ERROR: aid update: invalid recovery data at ${record} (must be a regular file)" >&2; return 2
    fi
    parsed="$(_aid_parse_recovery "$record")" || { echo "ERROR: aid update: invalid recovery data at ${record}" >&2; return 2; }
    IFS=$'\t' read -r _AID_UPGRADE_RETIRED _ <<< "$parsed"
    local rest="${parsed#*$'\t'}" tool
    while [[ -n "$rest" ]]; do tool="${rest%%$'\t'*}"; _AID_UPGRADE_TOOLS+=("$tool"); [[ "$rest" == *$'\t'* ]] || break; rest="${rest#*$'\t'}"; done
    return 0
}

# write_upgrade_recovery <target> <retired:true|false> <ordered tools...>
write_upgrade_recovery() {
    local target="$1" retired="$2" record="${1}/.aid/.temp/v3-upgrade-tools.json" tmp tool comma=""
    shift 2
    [[ "$retired" == true || "$retired" == false ]] || return 2
    [[ $# -gt 0 ]] || return 2
    mkdir -p "$(dirname "$record")" || return 1
    tmp="$(mktemp "$(dirname "$record")/.v3-upgrade-tools.XXXXXX")" || return 1
    { printf '{"format_version":1,"tools":['; for tool in "$@"; do printf '%s"%s"' "$comma" "$tool"; comma=,; done; printf '],"retired":%s}\n' "$retired"; } > "$tmp" || { rm -f "$tmp"; return 1; }
    mv -f "$tmp" "$record" || { rm -f "$tmp"; return 1; }
}

clear_upgrade_recovery() {
    local record="${1}/.aid/.temp/v3-upgrade-tools.json"
    [[ -e "$record" || -L "$record" ]] || return 0
    [[ ! -L "$record" && -f "$record" ]] || { echo "ERROR: aid update: cannot clear invalid recovery data at ${record}" >&2; return 1; }
    rm -f "$record"
}

_copy_to_trash() {
    local root="${1%/}" src="$2" stamp dest cand n tmp
    [[ -f "$src" && ! -L "$src" ]] || return 1
    dest="${root}/.aid/.trash/${src#"$root"/}"; stamp="$(_aid_utc_stamp)"
    mkdir -p "$(dirname "$dest")" || return 1
    [[ ! -d "$dest" ]] || return 1
    tmp="$(mktemp "$(dirname "$dest")/.trash-copy.XXXXXX")" || return 1
    cp -p "$src" "$tmp" || { rm -f "$tmp"; return 1; }
    if [[ -e "$dest" || -L "$dest" ]]; then
        if cmp -s "$src" "$dest"; then rm -f "$tmp"; return 0; fi
        cand="${dest}.${stamp}"; n=0
        while [[ -e "$cand" || -L "$cand" ]]; do n=$((n+1)); cand="${dest}.${stamp}.${n}"; done
        mv "$dest" "$cand" || { rm -f "$tmp"; return 1; }
    fi
    mv "$tmp" "$dest" || { rm -f "$tmp"; return 1; }
}

# ---------------------------------------------------------------------------
# Root-file region primitives (byte-faithful; awk/bash only, python3 not needed)
# ---------------------------------------------------------------------------
# A root file (AGENTS.md, CLAUDE.md, .gitattributes) is a byte string. A LINE is a run of
# bytes up to and including LF (the last line may lack it). A line's VALUE drops that LF and
# one CR before it; an unterminated last line is its own value. Markers match by value. Every
# edit keeps all other bytes unchanged (any 8-bit encoding, a UTF-8 BOM, CRLF, UTF-8
# multibyte text). A file holding NUL bytes (UTF-16/UTF-32/binary) or starting with a UTF-16
# BOM cannot be edited safely: it is refused with a message and nothing is changed. The
# PowerShell twin implements the same rules (Read/Write-AidRootBytes, Test-AidRootFileUnsafe).

# _aid_root_file_unsafe <file> - exit 0 when <file> exists and cannot be edited byte-safely.
_aid_root_file_unsafe() {
    local f="$1" bom
    [[ -f "$f" && -s "$f" ]] || return 1
    bom="$(head -c2 "$f" | od -An -tx1 | tr -d ' \n')"
    [[ "$bom" == fffe || "$bom" == feff ]] && return 0
    LC_ALL=C tr -d '\000' < "$f" | cmp -s - "$f" || return 0
    return 1
}

# _aid_root_file_guard <file> - exit 0 when <file> is absent or safe; else print the refusal.
_aid_root_file_guard() {
    _aid_root_file_unsafe "$1" || return 0
    echo "ERROR: aid: refusing to edit $(basename "$1"): it is UTF-16/UTF-32 or contains NUL bytes, so AID cannot preserve its content. Convert it to UTF-8 and run the command again. No changes were made." >&2
    return 1
}

# _aid_file_endnl <file> - print 1 when <file> is empty or ends with LF, else 0.
_aid_file_endnl() {
    if [[ ! -s "$1" || -z "$(tail -c1 "$1")" ]]; then echo 1; else echo 0; fi
}

# _aid_append_region <file> <region> - append <region>, first completing an unterminated last line.
_aid_append_region() {
    { if [[ -s "$1" && -n "$(tail -c1 "$1")" ]]; then printf '\n'; fi; printf '%s' "$2"; } >> "$1"
}

# _aid_is_blank_file <file> - exit 0 when <file> holds only ASCII whitespace.
_aid_is_blank_file() { [[ -z "$(LC_ALL=C tr -d ' \t\r\n\v\f' < "$1")" ]]; }

# Marker span: prints "S F" (1-based line numbers of the BEGIN and END lines) and exits 0
# only for exactly one BEGIN line, one END line, in that order. AID_CANON_OUT (env) names a
# file that receives the LF-joined values of lines S..F.
_AID_AWK_SPAN='
{ L[++n] = $0 }
END {
    for (i = 1; i <= n; i++) {
        v = L[i]
        if (!(i == n && !endnl)) sub(/\r$/, "", v)
        if (v == mb) { nb++; b = i } else if (v == me) { ne++; e = i }
        V[i] = v
    }
    if (nb != 1 || ne != 1 || b >= e) exit 1
    print b " " e
    out = ENVIRON["AID_CANON_OUT"]
    if (out != "") { for (i = b; i <= e; i++) printf "%s\n", V[i] > out; close(out) }
}'

# Region repair: reads the region file, then the target. Prints noop | append | rewrite
# (rewrite also writes the new content to AID_REWRITE_OUT) | span B E (inline mode only: one
# well-formed marker pair).
_AID_AWK_REPAIR='
FNR == NR { R[++nR] = $0; next }
{ L[++n] = $0 }
END {
    out = ENVIRON["AID_REWRITE_OUT"]
    for (i = 1; i <= n; i++) { v = L[i]; if (!(i == n && !endnl)) sub(/\r$/, "", v); V[i] = v }
    if (inl) { M["<!-- AID:BEGIN -->"] = 1; M["<!-- AID:END -->"] = 1 }
    else for (r = 1; r <= nR; r++) M[R[r]] = 1
    if (xtra != "") M[xtra] = 1
    for (i = 1; i <= n; i++) {
        if (V[i] == "<!-- AID:BEGIN -->") { nb++; b = i } else if (V[i] == "<!-- AID:END -->") { ne++; e = i }
        if (V[i] in M) pos++
    }
    if (inl && nb == 1 && ne == 1 && b < e) { print "span " b " " e; exit }
    if (pos == 0) { print "append"; exit }
    if (!inl) {
        for (i = 1; i + nR - 1 <= n; i++) {
            ok = 1
            for (j = 1; j <= nR; j++) if (V[i + j - 1] != R[j]) { ok = 0; break }
            if (ok) starts++
        }
        if (starts == 1 && pos == nR) { print "noop"; exit }
    }
    for (i = 1; i <= n; i++) {
        if (V[i] in M) {
            if (!ins) { for (r = 1; r <= nR; r++) printf "%s\n", R[r] > out; ins = 1 }
        } else { printf "%s", L[i] > out; if (!(i == n && !endnl)) printf "\n" > out }
    }
    if (!ins) for (r = 1; r <= nR; r++) printf "%s\n", R[r] > out
    close(out)
    print "rewrite"
}'

# _aid_marker_span <file> [begin end] - see _AID_AWK_SPAN.
_aid_marker_span() {
    local mb="${2:-<!-- AID:BEGIN -->}" me="${3:-<!-- AID:END -->}"
    LC_ALL=C awk -v endnl="$(_aid_file_endnl "$1")" -v mb="$mb" -v me="$me" "$_AID_AWK_SPAN" "$1"
}

# _aid_region_decide <file> <region> <inline:0|1> <rewrite-out> [extra-owned-line] - run _AID_AWK_REPAIR.
# The optional line is owned like a region line (a stale copy outside the region is absorbed).
_aid_region_decide() {
    AID_REWRITE_OUT="$4" LC_ALL=C awk -v endnl="$(_aid_file_endnl "$1")" -v inl="$3" -v xtra="${5:-}" "$_AID_AWK_REPAIR" <(printf '%s' "$2") "$1"
}

# _aid_cut_marker_region <file> <check:0|1> <root> <recorded-sha> [begin end]
# Removes the single well-formed marked region (markers included); a file left blank is
# deleted. With check=1 the file is first copied to .aid/.trash/ when the region's canonical
# hash differs from <recorded-sha>. A file without a well-formed region is left alone.
_aid_cut_marker_region() {
    local file="$1" check="$2" root="$3" recorded="$4" mb="${5:-}" me="${6:-}" canon="" tmp span s f
    [[ -f "$file" ]] || return 0
    tmp="$(mktemp)" || return 1
    if [[ "$check" == 1 ]]; then canon="$(mktemp)" || { rm -f "$tmp"; return 1; }; fi
    if ! span="$(AID_CANON_OUT="$canon" _aid_marker_span "$file" ${mb:+"$mb" "$me"})"; then rm -f "$tmp" "$canon"; return 0; fi
    read -r s f <<< "$span"
    if ! { head -n "$((s - 1))" "$file"; tail -n "+$((f + 1))" "$file"; } > "$tmp"; then rm -f "$tmp" "$canon"; return 1; fi
    if [[ "$check" == 1 && "$(sha256_file "$canon")" != "$recorded" ]]; then
        trash_file "$root" "$file" || { rm -f "$tmp" "$canon"; return 1; }
    fi
    if _aid_is_blank_file "$tmp"; then rm -f "$file"; else cat "$tmp" > "$file" || { rm -f "$tmp" "$canon"; return 1; }; fi
    rm -f "$tmp" "$canon"
    return 0
}

_retire_root_agent_region() {
    local target="$1" file="$2" path="${1}/${2}" temp span s f
    _AID_V3_ROOT_REGION_RETIRED=0
    [[ -f "$path" && ! -L "$path" ]] || return 0
    _aid_root_file_guard "$path" || return 1
    span="$(_aid_marker_span "$path")" || return 0
    read -r s f <<< "$span"
    _copy_to_trash "$target" "$path" || return 1
    _AID_V3_ROOT_REGION_RETIRED=1
    temp="$(mktemp "${path}.aid-region.XXXXXX")" || return 1
    if ! { head -n "$((s - 1))" "$path"; tail -n "+$((f + 1))" "$path"; } > "$temp"; then rm -f "$temp"; return 1; fi
    if _aid_is_blank_file "$temp"; then rm -f "$path" "$temp"; else mv "$temp" "$path" || return 1; fi
}

_is_aid_owned_path() {
    local target="${1%/}" path="$2" rel base
    [[ "$path" == "$target/"* ]] || return 1
    rel="${path#"$target"/}"; base="${rel##*/}"
    [[ "$rel" == .agents/aid/* || "$rel" =~ ^\.(claude|codex|cursor|github|agent)/aid/ ]] && return 0
    [[ "$rel" =~ ^\.(claude|codex|cursor|github|agent)/skills/aid-[^/]+/ ]] && return 0
    [[ "$base" == aid-* && ( "$rel" =~ ^\.(claude|codex|cursor|github|agent)/(skills|aid)/ || "$rel" == .agents/aid/* ) ]] && return 0
    # Retired v3 rules dirs (cursor, antigravity): aid-* files are AID-owned (marker 1).
    [[ "$base" == aid-* && "$rel" =~ ^\.(cursor|agent)/rules/ ]] && return 0
    return 1
}

# retire_v3_layout <target> <tool...> - preserves old AID paths under .aid/.trash.
retire_v3_layout() {
    local target="$1" tool root path rel count=0 list_only="${2:-0}"; shift 2
    local -a roots=()
    for tool in "$@"; do roots+=("$(_root_dir "$tool")"); done
    for root in "${roots[@]}"; do
        [[ -d "${target}/${root}" ]] || continue
        while IFS= read -r -d '' path; do
            if _is_aid_owned_path "$target" "$path"; then
                if [[ "$list_only" == 1 ]]; then echo "  move to trash: ${path#"$target"/}"; else trash_file "$target" "$path" || return 1; fi
                count=$((count+1))
            fi
        done < <(find "${target}/${root}" -type f -print0 | sort -z)
        if [[ "$list_only" != 1 ]]; then
            while IFS= read -r path; do [[ -d "$path" ]] && rmdir "$path" 2>/dev/null || true; done < <(find "${target}/${root}" -mindepth 1 -depth -type d | sort -r)
        fi
    done
    if printf '%s\n' "$@" | grep -qx codex; then
        root="${target}/.agents/aid"
        if [[ -d "$root" ]]; then
            while IFS= read -r -d '' path; do
                if [[ "$list_only" == 1 ]]; then echo "  move to trash: ${path#"$target"/}"; else trash_file "$target" "$path" || return 1; fi
                count=$((count+1))
            done < <(find "$root" -type f -print0 | sort -z)
            if [[ "$list_only" != 1 ]]; then find "$root" -mindepth 1 -depth -type d -exec rmdir {} \; 2>/dev/null || true; rmdir "$root" 2>/dev/null || true; fi
        fi
    fi
    for rootfile in AGENTS.md CLAUDE.md; do
        if [[ "$list_only" == 1 ]]; then [[ -f "${target}/${rootfile}" ]] && grep -q '<!-- AID:BEGIN -->' "${target}/${rootfile}" && echo "  preserve root file: ${rootfile}"; else _retire_root_agent_region "$target" "$rootfile" || return 1; count=$((count + _AID_V3_ROOT_REGION_RETIRED)); fi
    done
    if [[ "$list_only" != 1 && "$count" -gt 0 ]]; then echo "${count} old AID file(s) moved to .aid/.trash/ (safe to delete once you have checked them)"; fi
}

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

# _aid_sha256_stdin - print the lower-case hex sha256 of stdin, through the same
# sha256sum / shasum -a 256 fallback chain as sha256_file (region hashes use this).
_aid_sha256_stdin() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 | awk '{print $1}'
    else
        echo "ERROR: aid-install-core: no sha256 utility (need sha256sum or shasum)" >&2
        return 1
    fi
}

# _aid_sha256_batch - read NUL-terminated file paths on stdin and print one
# "<sha256><TAB><path>" line per file hashed, using ONE hashing process for the whole
# list instead of one per file. Files the utility cannot read, and names it would
# have to escape (backslash or newline), are simply absent from the output: callers
# fall back to sha256_file (or cmp) for any path without a line. Prints nothing when
# no sha256 utility exists.
_aid_sha256_batch() {
    local line
    local -a hasher=()
    if command -v sha256sum >/dev/null 2>&1; then hasher=(sha256sum)
    elif command -v shasum >/dev/null 2>&1; then hasher=(shasum -a 256)
    else cat >/dev/null; return 0; fi
    xargs -0 "${hasher[@]}" 2>/dev/null | while IFS= read -r line; do
        [[ "${line:0:64}" =~ ^[0-9a-f]{64}$ && "${line:64:1}" == ' ' ]] || continue
        printf '%s\t%s\n' "${line:0:64}" "${line:66}"
    done
    return 0
}

# _aid_dirname_to <var> <path> - dirname(1) without a fork: assign the directory part
# of <path> to <var> (trailing slashes ignored, "." for a bare name, "/" for the root).
_aid_dirname_to() {
    local _adt_p="$2"
    while [[ "$_adt_p" == */ && "$_adt_p" != / ]]; do _adt_p="${_adt_p%/}"; done
    if [[ "$_adt_p" != */* ]]; then
        _adt_p=.
    else
        _adt_p="${_adt_p%/*}"
        while [[ "$_adt_p" == */ ]]; do _adt_p="${_adt_p%/}"; done
        [[ -n "$_adt_p" ]] || _adt_p=/
    fi
    printf -v "$1" '%s' "$_adt_p"
}

# _aid_same_rels <src-root> <dst-root> [aid-only] - prepare a copy of every file under
# <src-root> to the same relative path under <dst-root> (aid-only=1: aid-*/* paths only).
# Prints one NUL-terminated record per path it settled:
#   S<rel>  the destination already holds the same bytes (one batched hash pass
#           replaces a cmp per file);
#   C<rel>  the destination was absent and is now a copy: missing directories are made
#           in one mkdir batch and the files of each destination directory are copied
#           by one cp (a directory whose cp fails has its new files removed again, so
#           the per-file copy redoes them and reports any error itself).
# A path with no record is simply unknown: the caller handles it itself.
_aid_same_rels() {
    local src="$1" dst="$2" aid_only="${3:-0}" f rel sha path dir i
    local -a rels=() files=() dirs=() new_rels=() new_srcs=() new_dirs=() batch=()
    local -A got=() seen=() group=()
    while IFS= read -r -d '' f; do
        rel="${f#${src}/}"
        [[ "$aid_only" == 1 && "$rel" != aid-*/* ]] && continue
        if [[ ! -e "${dst}/${rel}" ]]; then
            [[ -L "${dst}/${rel}" ]] && continue
            _aid_dirname_to dir "${dst}/${rel}"
            if [[ ! -d "$dir" && -z "${seen[$dir]+x}" ]]; then seen["$dir"]=1; dirs+=("$dir"); fi
            [[ -n "${group[$dir]+x}" ]] || new_dirs+=("$dir")
            group["$dir"]+="${#new_rels[@]} "
            new_rels+=("$rel"); new_srcs+=("$f")
            continue
        fi
        [[ -f "${dst}/${rel}" ]] || continue
        rels+=("$rel"); files+=("$f" "${dst}/${rel}")
    done < <(find "$src" -type f -print0 2>/dev/null)
    if [[ "${#dirs[@]}" -gt 0 ]]; then printf '%s\0' "${dirs[@]}" | xargs -0 mkdir -p -- 2>/dev/null || true; fi
    for dir in "${new_dirs[@]}"; do
        batch=()
        for i in ${group[$dir]}; do batch+=("${new_srcs[i]}"); done
        if cp -- "${batch[@]}" "${dir}/" 2>/dev/null; then
            for i in ${group[$dir]}; do printf 'C%s\0' "${new_rels[i]}"; done
        else
            for i in ${group[$dir]}; do rm -f -- "${dst}/${new_rels[i]}" 2>/dev/null; done
        fi
    done
    [[ "${#files[@]}" -gt 0 ]] || return 0
    while IFS=$'\t' read -r sha path; do got["$path"]="$sha"; done < <(printf '%s\0' "${files[@]}" | _aid_sha256_batch)
    for rel in "${rels[@]}"; do
        sha="${got["${src}/${rel}"]:-}"
        [[ -n "$sha" && "${got["${dst}/${rel}"]:-}" == "$sha" ]] && printf 'S%s\0' "$rel"
    done
    return 0
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
    # codex: .codex only; legacy .agents/aid is handled by clean-slate update.
    if [[ -d "${target}/.codex" ]]; then
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
#   _COPY_COUNT_SKIPPED (caller initialises before iterating; callers read them).
# This function handles NON-root-agent files only.
# Root agent files go through _copy_root_agent_file.
copy_file() {
    local src="$1" dst="$2" force="${3:-0}"
    local dst_dir
    _aid_dirname_to dst_dir "$dst"
    [[ -d "$dst_dir" ]] || mkdir -p "$dst_dir"

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
    local dest_dir; _aid_dirname_to dest_dir "$dest"
    if ! mkdir -p "$dest_dir"; then
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
# <same> is a hint from _aid_same_rels: 1 promises that <src> and an existing <dst> hold
# identical bytes (it replaces the per-file cmp); 2 says <dst> was absent and has just
# been copied from <src> in a batch (it is counted and reported as copied here).
copy_file_guarded() {
    local src="$1" dst="$2" recorded="${3:-}" root="${4:-$PWD}" same="${5:-0}"
    local drifted=0 dst_sha dst_dir precopied=0
    _aid_dirname_to dst_dir "$dst"
    [[ -d "$dst_dir" ]] || mkdir -p "$dst_dir"
    [[ "$same" == 2 && -f "$dst" ]] && precopied=1

    if [[ "$precopied" == 1 || ! -e "$dst" ]]; then
        if [[ "$precopied" != 1 ]] && ! cp "$src" "$dst"; then
            echo "ERROR: aid-install-core: copy failed: ${dst}" >&2
            _COPY_COUNT_FAILED=$((_COPY_COUNT_FAILED + 1))
            return 0
        fi
        _COPY_COUNT_COPIED=$((_COPY_COUNT_COPIED + 1))
        [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Copied: ${dst}"
        return 0
    fi

    if [[ "$same" == 1 ]] || cmp -s "$src" "$dst"; then
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
    # Pure-Bash fallback: the elements of tools.<tool>.paths.
    _aid_v3_flatten "$manifest" | awk -F '\t' -v tool="$tool" '$1 == "tools" && $2 == tool && $3 == "paths" && NF == 5 && $5 != "" { print $5 }'
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
    # Pure-Bash: the tool's version record.
    _aid_v3_flatten "$manifest" | awk -F '\t' -v tool="$tool" '$1 == "tools" && $2 == tool && $3 == "version" && NF == 4 && $4 != "" { print $4; exit }'
}


# Fixed root context regions. Keep these LF-only constants in both install cores.
# AGENTS.md carries a plain read instruction (no '@' line: only Claude Code expands '@' imports);
# CLAUDE.md imports AGENTS.md and the rules directly, or only AGENTS.md when the rules are inline.
_AID_AGENTS_POINTER_REGION=$'<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\nAt the start of every session, before anything else, read `.aid/runtime/rules.md` and follow it (AID rules).\n<!-- AID:END -->\n'
_AID_CLAUDE_IMPORT_REGION=$'<!-- AID:BEGIN -->\n@AGENTS.md\n@.aid/runtime/rules.md\n<!-- AID:END -->\n'
_AID_CLAUDE_IMPORT_REGION_INLINE=$'<!-- AID:BEGIN -->\n@AGENTS.md\n<!-- AID:END -->\n'
_AID_CLAUDE_RULES_IMPORT='@.aid/runtime/rules.md'

# _repair_root_region <file> <region> [project-root] [extra-owned-line]
# Preserve bytes outside exact managed lines; malformed regions are backed up first.
_repair_root_region() {
    local file="$1" region="$2" root="${3:-$(dirname "$1")}" xtra="${4:-}" tmp decision
    if [[ ! -e "$file" ]]; then
        mkdir -p "$(dirname "$file")" || return 1
        printf '%s' "$region" > "$file"
        return
    fi
    [[ -f "$file" ]] || return 1
    _aid_root_file_guard "$file" || return 1
    tmp="$(mktemp)" || return 1
    decision="$(_aid_region_decide "$file" "$region" 0 "$tmp" "$xtra")" || { rm -f "$tmp"; return 1; }
    case "$decision" in
        noop) ;;
        append) _aid_append_region "$file" "$region" || { rm -f "$tmp"; return 1; } ;;
        rewrite)
            trash_file "$root" "$file" || { rm -f "$tmp"; return 1; }
            cat "$tmp" > "$file" || { rm -f "$tmp"; return 1; } ;;
        *) rm -f "$tmp"; return 1 ;;
    esac
    rm -f "$tmp"
}

# Repair and print the canonical import-region hash. A third argument of 1 (rules_inline active)
# selects the @AGENTS.md-only region; the rules import line stays owned either way.
_ensure_claude_md_region() {
    local file="${1:-$PWD/CLAUDE.md}" root="${2:-$(dirname "${1:-$PWD/CLAUDE.md}")}" region="$_AID_CLAUDE_IMPORT_REGION"
    [[ "${3:-0}" == 1 ]] && region="$_AID_CLAUDE_IMPORT_REGION_INLINE"
    _repair_root_region "$file" "$region" "$root" "$_AID_CLAUDE_RULES_IMPORT" || return 1
    printf '%s\n' "$(printf '%s' "$region" | _aid_sha256_stdin)"
}

# Remove the exact Claude import region, backing up drift before the surgical edit.
_remove_claude_md_region() {
    local file="$1" recorded="${2:-}" root="${3:-$(dirname "$1")}"
    [[ -f "$file" ]] || return 0
    _aid_root_file_guard "$file" || return 1
    _aid_cut_marker_region "$file" 1 "$root" "$recorded"
}
# Writes the shared AGENTS.md pointer region and records its hashes for the caller.
# A 4th argument (the recorded region sha256, possibly empty) makes a rewrite of a
# well-formed marked span that differs from that record trash a full copy of the file first
# (the remove path: user text inside the region is never silently discarded).
_repair_inline_root_region() {
    local file="$1" region="$2" root="${3:-$(dirname "$1")}" tmp decision b e repl canon
    if [[ ! -e "$file" ]]; then
        mkdir -p "$(dirname "$file")" || return 1
        printf '%s' "$region" > "$file"
        return
    fi
    [[ -f "$file" ]] || return 1
    _aid_root_file_guard "$file" || return 1
    tmp="$(mktemp)" || return 1
    decision="$(_aid_region_decide "$file" "$region" 1 "$tmp")" || { rm -f "$tmp"; return 1; }
    case "$decision" in
        span\ *)
            # Preserve marker terminators and all bytes outside the marked span.
            read -r _ b e <<< "$decision"
            repl="${region#*$'\n'}"; repl="${repl%'<!-- AID:END -->'$'\n'}"
            { head -n "$b" "$file"; printf '%s' "$repl"; tail -n "+$e" "$file"; } > "$tmp" || { rm -f "$tmp"; return 1; }
            if ! cmp -s "$tmp" "$file"; then
                if [[ $# -ge 4 ]]; then
                    canon="$(mktemp)" || { rm -f "$tmp"; return 1; }
                    AID_CANON_OUT="$canon" _aid_marker_span "$file" >/dev/null
                    if [[ "$(sha256_file "$canon")" != "$4" ]]; then
                        rm -f "$canon"
                        trash_file "$root" "$file" || { rm -f "$tmp"; return 1; }
                    else rm -f "$canon"; fi
                fi
                cat "$tmp" > "$file" || { rm -f "$tmp"; return 1; }
            fi ;;
        append) _aid_append_region "$file" "$region" || { rm -f "$tmp"; return 1; } ;;
        rewrite)
            # Malformed marker spans are replaced in place; unrelated lines stay byte-identical.
            trash_file "$root" "$file" || { rm -f "$tmp"; return 1; }
            cat "$tmp" > "$file" || { rm -f "$tmp"; return 1; } ;;
        *) rm -f "$tmp"; return 1 ;;
    esac
    rm -f "$tmp"
}

_copy_root_agent_file() {
    local src="$1" dst="$2" tool="$3" force="${4:-0}" manifest="${5:-}" root="$(dirname "$2")" inline=0 rules region
    local had_dst=0 before_sha=""
    if [[ -f "$dst" ]]; then had_dst=1; before_sha="$(sha256_file "$dst")"; fi
    _CORE_ROOT_AGENT_STATUS="owned"
    if [[ -f "$(dirname "$src")/aid-tool.conf" ]] && grep -qx 'rules_inline=true' "$(dirname "$src")/aid-tool.conf"; then inline=1; fi
    if [[ -n "$manifest" && -f "$manifest" && "$inline" -eq 0 ]]; then
        local _rt
        while IFS= read -r _rt; do
            if manifest_read_tool_files "$manifest" "$_rt" | awk -F '\t' -v t="$_rt" '$1=="tools." t ".rules_inline" && $2=="true" {found=1} END{exit !found}'; then inline=1; break; fi
        done < <(manifest_list_tools "$manifest")
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
    _CORE_ROOT_AGENT_REGION_SHA="$(printf '%s' "$region" | _aid_sha256_stdin)"
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

# manifest_remove_tool <manifest> <tool>
# Removes a tool's section from the manifest.  If no tools remain, removes the manifest.
manifest_remove_tool() {
    local manifest="$1" tool="$2"
    [[ -f "$manifest" ]] || return 0

    # A format-3 manifest is edited through the shared model (same bytes with or without python3).
    if [[ "$(manifest_format "$manifest")" == 3 ]]; then
        _manifest_remove_tool_v3 "$manifest" "$tool"
        return
    fi

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
    _aid_mc_prime "$manifest"
    if _aid_mc_find "$manifest" && _aid_mc_emit list; then return 0; fi
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
    # Pure-Bash fallback: the tool keys of the "tools" object, in file order.
    _aid_v3_flatten "$manifest" | awk -F '\t' '$1 == "tools" && NF >= 3 && !($2 in seen) { seen[$2] = 1; print $2 }' | tr -d '\r'
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

# _v3_quote <outvar> <string> - JSON string literal, byte-identical to python3's
# json.dump (ensure_ascii): escapes backslash, quote, \b \f \n \r \t, every other control
# character, DEL and every non-ASCII character as \uXXXX (lower-case hex; a surrogate
# pair above U+FFFF). The common all-printable-ASCII value takes the fast path.
_v3_quote() {
    local LC_ALL=C
    local s="$2" out="" c n cp need k b hi lo i len=0 piece
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    if [[ "$s" =~ [^\ -~] ]]; then
        len=${#s}; i=0
        while (( i < len )); do
            c="${s:i:1}"; i=$((i + 1))
            printf -v n '%d' "'$c"
            if (( n >= 32 && n < 127 )); then out+="$c"; continue; fi
            cp=$n; need=0
            case 1 in
                $(( n == 8 )))  out+='\b'; continue ;;
                $(( n == 9 )))  out+='\t'; continue ;;
                $(( n == 10 ))) out+='\n'; continue ;;
                $(( n == 12 ))) out+='\f'; continue ;;
                $(( n == 13 ))) out+='\r'; continue ;;
                $(( n < 32 || n == 127 )))  printf -v piece '\\u%04x' "$n"; out+="$piece"; continue ;;
                $(( n >= 194 && n <= 223 ))) need=1; cp=$(( n & 31 )) ;;
                $(( n >= 224 && n <= 239 ))) need=2; cp=$(( n & 15 )) ;;
                $(( n >= 240 && n <= 244 ))) need=3; cp=$(( n & 7 )) ;;
                *) cp=65533 ;;
            esac
            for (( k = 0; k < need; k++ )); do
                b=-1
                if (( i < len )); then printf -v b '%d' "'${s:i:1}"; fi
                if (( b >= 128 && b <= 191 )); then cp=$(( (cp << 6) | (b & 63) )); i=$((i + 1)); else cp=65533; break; fi
            done
            if (( cp > 65535 )); then
                hi=$(( 55296 + ((cp - 65536) >> 10) )); lo=$(( 56320 + ((cp - 65536) & 1023) ))
                printf -v piece '\\u%04x\\u%04x' "$hi" "$lo"
            else
                printf -v piece '\\u%04x' "$cp"
            fi
            out+="$piece"
        done
        s="$out"
    fi
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

# ---------------------------------------------------------------------------
# Format-3 model helpers (bash + awk; the writer is shared with python3)
# ---------------------------------------------------------------------------

# _manifest_model <manifest> - every record of a manifest as writer-model lines.
_manifest_model() { _aid_v3_flatten "$1" | _aid_v3_view_awk model; }

# _manifest_remove_tool_v3 <manifest> <tool> - drop a tool from a format-3 manifest: its own
# records, its entry in every shared users list and mirror, and re-derive host.worktree_root
# from the tools left. The manifest is deleted when no tool is left.
_AID_AWK_RM_TOOL='
BEGIN { FS = OFS = "\t"; no = split(order, O, " ") }
function drop(csv,   a, na, i, r) {
    na = split(csv, a, ","); r = ""
    for (i = 1; i <= na; i++) if (a[i] != "" && a[i] != tool) r = (r == "" ? a[i] : r "," a[i])
    return r
}
{
    k = $1
    if (k ~ /^tools\./) {
        t = substr(k, 7); sub(/\..*$/, "", t)
        if (t == tool) next
        left[t] = 1
        if (k == "tools." t ".worktree_root" && $2 != "") wr[t] = $2
        rec[++n] = $0; next
    }
    if (k ~ /^shared\.(skills|runtime|agents_md|claude_md)\.users$/) { rec[++n] = k OFS drop($2); next }
    if (k == "shared.mirror") { rec[++n] = k OFS $2 OFS $3 OFS drop($4); next }
    if (k == "host.worktree_root") next
    rec[++n] = $0
}
END {
    nleft = 0
    for (t in left) nleft++
    if (nleft == 0) exit 3
    host = ""
    for (i = 1; i <= no; i++) if (O[i] in wr) { host = wr[O[i]]; break }
    for (i = 1; i <= n; i++) print rec[i]
    print "host.worktree_root" OFS (host != "" ? host : ".aid/.worktrees")
}'
_manifest_remove_tool_v3() {
    local manifest="$1" tool="$2" model rc
    model="$(mktemp "$(dirname "$manifest")/.manifest-model.XXXXXX")" || return 1
    _manifest_model "$manifest" | LC_ALL=C awk -v tool="$tool" -v order="${AID_TOOLS[*]}" "$_AID_AWK_RM_TOOL" > "$model"
    rc=$?
    if [[ "$rc" -eq 3 ]]; then rm -f "$model" "$manifest"; return 0; fi
    if [[ "$rc" -ne 0 ]]; then rm -f "$model"; echo "ERROR: manifest remove failed" >&2; return 1; fi
    manifest_write_v3 "$manifest" "$model" || { rm -f "$model"; return 1; }
    rm -f "$model"
}

# _aid_tree_records <dir> - "rel<TAB>sha256" for every regular file under <dir>, in byte order.
_aid_tree_records() {
    local dir="$1" sha path
    local -A hashed=()
    local -a files=()
    [[ -d "$dir" ]] || return 0
    while IFS= read -r -d '' path; do files+=("$path"); done < <(find "$dir" -type f -print0 | LC_ALL=C sort -z)
    [[ "${#files[@]}" -gt 0 ]] || return 0
    while IFS=$'\t' read -r sha path; do hashed["$path"]="$sha"; done < <(printf '%s\0' "${files[@]}" | _aid_sha256_batch)
    for path in "${files[@]}"; do
        sha="${hashed[$path]:-}"
        [[ -n "$sha" ]] || sha="$(sha256_file "$path")" || return 1
        printf '%s\t%s\n' "${path#"$dir"/}" "$sha"
    done
}

# _aid_build_install_model <manifest> <model> <shared-stage> <target> <version> <now>
#   <new-tools-file> <region-sha> <agents-sha> <claude-sha>
# Writes the writer model of the install install_shared is committing: the old manifest's
# tools (all of them, unless AID_UPGRADE_EXACT=1) overlaid with the newly staged tools.
_aid_build_install_model() {
    local manifest="$1" model="$2" shared_dir="$3" target="$4" version="$5" now="$6" new_file="$7"
    local region_sha="$8" agents_sha="$9" claude_sha="${10}"
    local exact="${AID_UPGRADE_EXACT:-0}" line key rest t stage root k v rel sha dir e ci_set wr_set
    local conf_lines old_iat="" old_iat_set=0 old_claude="" csv host_wr="" claude_csv=""
    local -A has_old=() o_ver=() o_iat=() o_wr=() o_inline=() o_mirrors=() o_files=() n_stage=() ctx=()
    local -A t_ver=() t_iat=() t_wr=() t_inline=() t_mirrors=() t_files=() in_set=() mir_users=()
    local -a mir=() ri=() ordered=()

    if [[ -f "$manifest" ]]; then
        while IFS= read -r line; do
            key="${line%%$'\t'*}"; rest="${line#*$'\t'}"
            case "$key" in
                installed_at) old_iat="$rest"; old_iat_set=1 ;;
                shared.claude_md.users) old_claude="$rest" ;;
                tools.*)
                    t="${key#tools.}"; k="${t#*.}"; t="${t%%.*}"; has_old[$t]=1
                    case "$k" in
                        version) o_ver[$t]="$rest" ;;
                        installed_at) o_iat[$t]="$rest" ;;
                        worktree_root) o_wr[$t]="$rest" ;;
                        rules_inline) o_inline[$t]=1 ;;
                        mirror) o_mirrors[$t]+="$rest"$'\n' ;;
                        file) o_files[$t]+="$rest"$'\n' ;;
                    esac ;;
            esac
        done < <(_manifest_model "$manifest")
    fi
    while IFS=$'\t' read -r t stage; do
        [[ -n "$t" && -n "$stage" ]] && n_stage[$t]="$stage"
    done < "$new_file"

    if [[ "$exact" != 1 ]]; then
        for t in "${!has_old[@]}"; do in_set[$t]=1; done
        csv="$old_claude"
        while [[ -n "$csv" ]]; do
            t="${csv%%,*}"
            if [[ "$csv" == *,* ]]; then csv="${csv#*,}"; else csv=""; fi
            [[ -n "$t" ]] && ctx[$t]=1
        done
    fi
    for t in "${!n_stage[@]}"; do in_set[$t]=1; ctx[$t]=0; done

    for t in "${AID_TOOLS[@]}"; do
        [[ -n "${in_set[$t]:-}" ]] || continue
        ordered+=("$t")
        if [[ -n "${n_stage[$t]:-}" ]]; then
            stage="${n_stage[$t]}"; mir=(); ri=(); wr_set=0; ci_set=0
            t_wr[$t]=""
            conf_lines="$(read_kv_conf "${stage}/aid-tool.conf")" || return 1
            while IFS= read -r line; do
                k="${line%%=*}"; v="${line#*=}"
                case "$k" in
                    skill_mirror) mir+=("$v") ;;
                    worktree_root) if [[ "$wr_set" -eq 0 ]]; then t_wr[$t]="$v"; wr_set=1; fi ;;
                    rules_inline) ri+=("$v") ;;
                    context_import) if [[ "$ci_set" -eq 0 ]]; then ci_set=1; [[ "$v" == CLAUDE.md ]] && ctx[$t]=1; fi ;;
                esac
            done <<< "$conf_lines"
            [[ "$wr_set" -eq 1 ]] || unset "t_wr[$t]"
            if [[ "${#ri[@]}" -eq 1 && "${ri[0]}" == true ]]; then t_inline[$t]=1; fi
            t_ver[$t]="$version"
            if [[ -n "${o_iat[$t]+x}" ]]; then t_iat[$t]="${o_iat[$t]}"; else t_iat[$t]="$now"; fi
            t_mirrors[$t]=""
            if [[ "${#mir[@]}" -gt 0 ]]; then printf -v "t_mirrors[$t]" '%s\n' "${mir[@]}"; fi
            root="$(_root_dir "$t")"
            t_files[$t]=""
            if [[ -d "${stage}/${root}/agents" ]]; then
                while IFS=$'\t' read -r rel sha; do t_files[$t]+="${root}/agents/${rel}"$'\t'"${sha}"$'\n'; done < <(_aid_tree_records "${stage}/${root}/agents")
            fi
        else
            t_ver[$t]="${o_ver[$t]-}"
            if [[ -n "${o_iat[$t]+x}" ]]; then t_iat[$t]="${o_iat[$t]}"; else t_iat[$t]="$now"; fi
            [[ -n "${o_wr[$t]+x}" ]] && t_wr[$t]="${o_wr[$t]}"
            [[ -n "${o_inline[$t]:-}" ]] && t_inline[$t]=1
            t_mirrors[$t]="${o_mirrors[$t]-}"
            t_files[$t]="${o_files[$t]-}"
        fi
    done
    for t in "${ordered[@]}"; do
        if [[ -n "${t_wr[$t]:-}" ]]; then host_wr="${t_wr[$t]}"; break; fi
    done
    [[ -n "$host_wr" ]] || host_wr=".aid/.worktrees"
    local all_csv=""; for t in "${ordered[@]}"; do all_csv+="${all_csv:+,}${t}"; done
    for t in "${ordered[@]}"; do
        [[ "${ctx[$t]:-0}" == 1 ]] && claude_csv+="${claude_csv:+,}${t}"
        while IFS= read -r dir; do
            [[ -n "$dir" ]] && mir_users[$dir]+="${mir_users[$dir]:+,}${t}"
        done <<< "${t_mirrors[$t]}"
    done

    {
        printf 'aid_version\t%s\n' "$version"
        if [[ "$old_iat_set" -eq 1 ]]; then printf 'installed_at\t%s\n' "$old_iat"; else printf 'installed_at\t%s\n' "$now"; fi
        printf 'host.worktree_root\t%s\n' "$host_wr"
        for e in skills runtime; do
            if [[ "$e" == skills ]]; then root=".agents/skills"; else root=".aid/runtime"; fi
            printf 'shared.%s.root\t%s\nshared.%s.version\t%s\nshared.%s.users\t%s\n' "$e" "$root" "$e" "$version" "$e" "$all_csv"
            while IFS=$'\t' read -r rel sha; do
                [[ "$e" == skills && "$rel" != aid-* ]] && continue
                printf 'shared.%s.file\t%s\t%s\n' "$e" "$rel" "$sha"
            done < <(_aid_tree_records "${shared_dir}/${e}")
        done
        if [[ -f "${target}/.aid/runtime/host.conf" ]]; then
            printf 'shared.runtime.file\thost.conf\t%s\n' "$(sha256_file "${target}/.aid/runtime/host.conf")"
        fi
        printf 'shared.agents_md.path\tAGENTS.md\nshared.agents_md.version\t%s\nshared.agents_md.users\t%s\nshared.agents_md.region_sha256\t%s\nshared.agents_md.file_sha256\t%s\n' "$version" "$all_csv" "$region_sha" "$agents_sha"
        for dir in "${!mir_users[@]}"; do printf 'shared.mirror\t%s\t%s\t%s\n' "$dir" "$version" "${mir_users[$dir]}"; done
        if [[ -n "$claude_sha" ]]; then
            printf 'shared.claude_md.path\tCLAUDE.md\nshared.claude_md.version\t%s\nshared.claude_md.users\t%s\nshared.claude_md.region_sha256\t%s\n' "$version" "$claude_csv" "$claude_sha"
        fi
        for t in "${ordered[@]}"; do
            printf 'tools.%s.version\t%s\ntools.%s.installed_at\t%s\n' "$t" "${t_ver[$t]}" "$t" "${t_iat[$t]}"
            while IFS= read -r dir; do [[ -n "$dir" ]] && printf 'tools.%s.mirror\t%s\n' "$t" "$dir"; done <<< "${t_mirrors[$t]}"
            if [[ -n "${t_wr[$t]+x}" ]]; then printf 'tools.%s.worktree_root\t%s\n' "$t" "${t_wr[$t]}"; fi
            if [[ -n "${t_inline[$t]:-}" ]]; then printf 'tools.%s.rules_inline\ttrue\n' "$t"; fi
            while IFS= read -r line; do [[ -n "$line" ]] && printf 'tools.%s.file\t%s\n' "$t" "$line"; done <<< "${t_files[$t]}"
        done
        true
    } > "$model"
}

# Readers. _aid_v3_flatten prints each scalar and array element of a pretty-printed
# JSON manifest as TAB-separated path segments followed by the value. Array elements
# are numbered from 0. Nesting is tracked by the braces, so any indent width works; the
# one-member-per-line layout of json.dump / the writers is required. String escapes
# (\n \t \" \\ \/ \b \f \r and \uXXXX, surrogate pairs included) are decoded to the bytes
# python3's json would yield (UTF-8), so both readers return the same records.
_aid_v3_flatten() {
    LC_ALL=C awk '
    function jn(a, b) { return (a == "") ? b : a "\t" b }
    function hex(h,   i, v) {
        v = 0; h = tolower(h)
        for (i = 1; i <= length(h); i++) v = v * 16 + index("0123456789abcdef", substr(h, i, 1)) - 1
        return v
    }
    function utf8(cp) {
        if (cp < 128) return sprintf("%c", cp)
        if (cp < 2048) return sprintf("%c%c", 192 + int(cp / 64), 128 + cp % 64)
        if (cp < 65536) return sprintf("%c%c%c", 224 + int(cp / 4096), 128 + int(cp / 64) % 64, 128 + cp % 64)
        return sprintf("%c%c%c%c", 240 + int(cp / 262144), 128 + int(cp / 4096) % 64, 128 + int(cp / 64) % 64, 128 + cp % 64)
    }
    function unesc(s,   o, i, n, c, cp, lo) {
        if (index(s, "\\") == 0) return s
        o = ""; n = length(s)
        for (i = 1; i <= n; i++) {
            c = substr(s, i, 1)
            if (c != "\\") { o = o c; continue }
            i++; c = substr(s, i, 1)
            if (c == "n") o = o "\n"
            else if (c == "t") o = o "\t"
            else if (c == "r") o = o "\r"
            else if (c == "b") o = o "\b"
            else if (c == "f") o = o "\f"
            else if (c == "u") {
                cp = hex(substr(s, i + 1, 4)); i += 4
                if (cp >= 55296 && cp <= 56319 && substr(s, i + 1, 2) == "\\u") {
                    lo = hex(substr(s, i + 3, 4))
                    if (lo >= 56320 && lo <= 57343) { cp = 65536 + (cp - 55296) * 1024 + (lo - 56320); i += 6 }
                }
                o = o utf8(cp)
            } else o = o c
        }
        return o
    }
    function endq(s,   i, n, c) {
        n = length(s)
        for (i = 1; i <= n; i++) { c = substr(s, i, 1); if (c == "\\") i++; else if (c == "\"") return i }
        return 0
    }
    {
        if (match($0, /[^ \t]/) == 0) next
        body = substr($0, RSTART)
        sub(/[ \t\r]+$/, "", body)
        sub(/,$/, "", body)
        if (body == "{" || body == "[") {
            if (d == 0) { d = 1; P[1] = ""; next }
            n = cnt[P[d]]++
            P[d + 1] = jn(P[d], n); d++
            next
        }
        if (body == "{}" || body == "[]") { cnt[P[d]]++; next }
        if (body ~ /^[]}]/) { d--; next }
        rest = substr(body, 2)
        q = endq(rest)
        if (q == length(rest)) {
            n = cnt[P[d]]++
            print jn(P[d], n) "\t" unesc(substr(rest, 1, q - 1))
            next
        }
        key = unesc(substr(rest, 1, q - 1))
        val = substr(rest, q + 3)
        if (val == "{" || val == "[") { P[d + 1] = jn(P[d], key); d++; next }
        if (val == "{}" || val == "[]") next
        if (substr(val, 1, 1) == "\"") val = unesc(substr(val, 2, length(val) - 2))
        print jn(P[d], key) "\t" val
    }' "$1"
}

# _aid_v3_view_awk <mode> [tool] - the record views, reading _aid_v3_flatten output on stdin.
# Modes: format | host | shared | tool (one tool) | model (every record: the top-level
# aid_version/installed_at, host, shared and, for every tool, version, installed_at,
# mirrors, worktree_root, rules_inline and files).
_aid_v3_view_awk() {
    LC_ALL=C awk -v mode="$1" -v tool="${2:-}" '
    BEGIN { FS = "\t"; E[1] = "skills"; E[2] = "runtime"; E[3] = "agents_md"; E[4] = "claude_md" }
    mode == "format" && NF == 2 && $1 == "format_version" { print $2; next }
    mode == "host" && NF == 3 && $1 == "host" && $2 == "worktree_root" { print "host.worktree_root\t" $3; next }
    mode == "model" && NF == 3 && $1 == "host" && $2 == "worktree_root" { print "host.worktree_root\t" $3; next }
    mode == "model" && NF == 2 && ($1 == "aid_version" || $1 == "installed_at") { print $1 "\t" $2; next }
    (mode == "shared" || mode == "model") && $1 == "shared" {
        if (NF == 4 && $2 ~ /^(skills|runtime|agents_md|claude_md)$/ && $3 ~ /^(root|path|version|region_sha256|file_sha256)$/) {
            print "shared." $2 "." $3 "\t" $4
        } else if (NF == 5 && $2 ~ /^(skills|runtime|agents_md|claude_md)$/ && $3 == "users") {
            if (ucsv[$2] != "") ucsv[$2] = ucsv[$2] ","
            ucsv[$2] = ucsv[$2] $5
        } else if (NF == 6 && $2 ~ /^(skills|runtime)$/ && $3 == "files") {
            if ($5 == "path") pend[$2] = $6
            else if ($5 == "sha256") print "shared." $2 ".file\t" pend[$2] "\t" $6
        } else if (NF == 5 && $2 == "mirrors" && $4 == "version") {
            if (!($3 in mseen)) { mseen[$3] = 1; mord[++nm] = $3 }
            mver[$3] = $5
        } else if (NF == 6 && $2 == "mirrors" && $4 == "users") {
            if (!($3 in mseen)) { mseen[$3] = 1; mord[++nm] = $3 }
            if (mcsv[$3] != "") mcsv[$3] = mcsv[$3] ","
            mcsv[$3] = mcsv[$3] $6
        }
        next
    }
    $1 == "tools" && ((mode == "tool" && $2 == tool) || mode == "model") {
        t = $2
        if (NF == 5 && $3 == "mirrors") print "tools." t ".mirror\t" $5
        else if (NF == 4 && ($3 == "worktree_root" || $3 == "rules_inline" || (mode == "model" && ($3 == "version" || $3 == "installed_at")))) print "tools." t "." $3 "\t" $4
        else if (NF == 6 && $3 == "files") {
            if ($5 == "path") tpend = $6
            else if ($5 == "sha256") print "tools." t ".file\t" tpend "\t" $6
        }
    }
    END {
        if (mode == "shared" || mode == "model") {
            for (i = 1; i <= 4; i++) if (E[i] in ucsv) print "shared." E[i] ".users\t" ucsv[E[i]]
            for (i = 1; i <= nm; i++) print "shared.mirror\t" mord[i] "\t" mver[mord[i]] "\t" mcsv[mord[i]]
        }
    }'
}

# _aid_v3_read_awk <manifest> <mode> [tool] - pure-bash reader (mode: format|host|shared|tool|model).
_aid_v3_read_awk() { _aid_v3_flatten "$1" | _aid_v3_view_awk "$2" "${3:-}"; }

# _manifest_v3_read_python <manifest> <mode> [tool] - python3 reader (same records as the awk reader).
# Mode "all" (used by _aid_mc_prime only) prints every view at once: for each view a
# \x01<key>\x01 header then the exact bytes the single-view call would print, where
# <key> is format, host, shared, list (manifest_list_tools) or tool:<id>; a final
# \x01END marks a complete render. It prints
# nothing at all -- so nothing is cached -- unless the manifest is plain printable
# ASCII without backslashes (no JSON escapes) and every view renders cleanly.
_manifest_v3_read_python() {
    python3 - "$1" "$2" "${3:-}" "${AID_TOOLS[@]}" <<'PY'
import json, re, sys
import signal
if hasattr(signal, "SIGPIPE"):
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)  # a reader that stops early (head, awk exit) is not an error

manifest, mode, tool = sys.argv[1], sys.argv[2], sys.argv[3]


def render(data, mode, tool):
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
    return "".join(line + "\n" for line in out)


if mode == "all":
    try:
        with open(manifest, "rb") as fh:
            raw = fh.read()
        if re.search(rb"[^\x20-\x5b\x5d-\x7e\t\n\r]", raw):
            sys.exit(0)  # escapes or non-ASCII: let every view parse the file itself
        data = json.loads(raw.decode("ascii"))
        sections = []
        listed = []
        if isinstance(data, dict):
            sections = [(k, render(data, k, "")) for k in ("format", "host", "shared")]
            if isinstance(data.get("tools", {}), dict):
                listed = list(data.get("tools", {}).keys())
            names = []
            for t in listed + sys.argv[4:]:
                if re.fullmatch(r"[a-z0-9-]+", t) and t not in names:
                    names.append(t)
            sections += [("tool:" + t, render(data, "tool", t)) for t in names]
        else:
            sections = [(k, "") for k in ("format", "host", "shared")]
        sections.append(("list", "".join(t + "\n" for t in listed)))
        body = "".join("\x01%s\x01%s" % (k, v) for k, v in sections) + "\x01END"
    except Exception:
        sys.exit(0)
    sys.stdout.write(body)
    sys.exit(0)

try:
    with open(manifest, encoding="utf-8") as fh:
        data = json.load(fh)
except Exception:
    sys.exit(0)
if not isinstance(data, dict):
    sys.exit(0)
sys.stdout.write(render(data, mode, tool))
PY
}

# ---------------------------------------------------------------------------
# Per-run manifest read cache (bin/aid turns it on; sourcing the library does not)
# ---------------------------------------------------------------------------
# Every reader call used to re-parse the manifest (one python3 start each), and a CLI
# run makes dozens of reads, most inside $(...) or <(...) subshells where a cache
# filled by the reader itself would be lost. So the cache is filled in the MAIN shell
# (_aid_mc_prime: one python3 start renders every view), subshells inherit it, and
# EVERY read validates it against the manifest's current bytes: a manifest rewritten
# since -- by any writer, in any shell -- misses and is parsed directly, as before. The
# cache is keyed by content, not path, so the pre-write copy an update or remove keeps
# also hits. Two slots hold the last two distinct contents. Shell variables only:
# nothing is written to disk and nothing outlives the process.
_AID_MC_ON="${_AID_MC_ON:-0}"

# _aid_mc_find <manifest> - set _aid_mc_s to the slot caching <manifest>'s current bytes.
_aid_mc_find() {
    local _mc_c _mc_i _mc_v
    _aid_mc_s=""
    [[ "$_AID_MC_ON" == 1 && -f "$1" && -r "$1" ]] || return 1
    command -v python3 >/dev/null 2>&1 || return 1
    { _mc_c="$(<"$1")"; } 2>/dev/null || return 1
    for _mc_i in 0 1; do
        _mc_v="_AID_MC_SRC_${_mc_i}"
        if [[ -n "${!_mc_v+x}" && "${!_mc_v}" == "$_mc_c" ]]; then _aid_mc_s="$_mc_i"; return 0; fi
    done
    return 1
}

# _aid_mc_emit <mode> [tool] - print the cached view from slot _aid_mc_s; exit 1 when the
# view is not cached (the caller then parses the file itself).
_aid_mc_emit() {
    local _mc_v
    case "$1" in
        format|host|shared|list) _mc_v="_AID_MC_${_aid_mc_s}_$1" ;;
        tool) [[ "${2:-}" =~ ^[a-z0-9-]+$ ]] || return 1; _mc_v="_AID_MC_${_aid_mc_s}_tool_${2//-/_}" ;;
        *) return 1 ;;
    esac
    [[ -n "${!_mc_v+x}" ]] || return 1
    printf '%s' "${!_mc_v}"
}

# _aid_mc_prime <manifest> - cache every view of <manifest> (main shell only; no-op when
# the cache is off, inside a subshell, or when the bytes are already cached).
_aid_mc_prime() {
    [[ "$_AID_MC_ON" == 1 && "${BASH_SUBSHELL:-0}" == 0 ]] || return 0
    local _mc_m="$1" _mc_c _mc_c2 _mc_all _mc_slot _mc_sec _mc_key _mc_n _mc_i _mc_k
    local -a _mc_old=() _mc_parts=()
    _aid_mc_find "$_mc_m" && return 0
    [[ -f "$_mc_m" && -r "$_mc_m" ]] || return 0
    command -v python3 >/dev/null 2>&1 || return 0
    { _mc_c="$(<"$_mc_m")"; } 2>/dev/null || return 0
    _mc_all="$(_manifest_v3_read_python "$_mc_m" all; printf x)" || return 0
    _mc_all="${_mc_all%x}"
    [[ "$_mc_all" == $'\x01'* ]] || return 0
    { _mc_c2="$(<"$_mc_m")"; } 2>/dev/null || return 0
    [[ "$_mc_c2" == "$_mc_c" ]] || return 0
    # One split on \x01 (views never contain it): "", key, view, key, view, ..., "END\n".
    IFS=$'\x01' read -r -d '' -a _mc_parts <<< "$_mc_all"
    _mc_k="${#_mc_parts[@]}"
    [[ "$_mc_k" -ge 3 && $(( _mc_k % 2 )) -eq 0 && "${_mc_parts[0]}" == "" && "${_mc_parts[_mc_k - 1]}" == $'END\n' ]] || return 0
    _mc_slot="${_AID_MC_NEXT:-0}"
    unset -v "_AID_MC_SRC_${_mc_slot}"
    if [[ "$_mc_slot" == 0 ]]; then _mc_old=("${!_AID_MC_0_@}"); else _mc_old=("${!_AID_MC_1_@}"); fi
    [[ "${#_mc_old[@]}" -gt 0 ]] && unset -v "${_mc_old[@]}"
    for (( _mc_i = 1; _mc_i < _mc_k - 1; _mc_i += 2 )); do
        _mc_key="${_mc_parts[_mc_i]}"; _mc_sec="${_mc_parts[_mc_i + 1]}"
        case "$_mc_key" in
            format|host|shared) _mc_n="_AID_MC_${_mc_slot}_${_mc_key}" ;;
            list) _mc_n="_AID_MC_${_mc_slot}_list"; _mc_sec="${_mc_sec//$'\r'/}" ;;
            tool:*) _mc_n="_AID_MC_${_mc_slot}_tool_${_mc_key#tool:}"; _mc_n="${_mc_n//-/_}" ;;
            *) continue ;;
        esac
        printf -v "$_mc_n" '%s' "$_mc_sec"
    done
    printf -v "_AID_MC_SRC_${_mc_slot}" '%s' "$_mc_c"
    _AID_MC_NEXT=$(( 1 - _mc_slot ))
    return 0
}

# _manifest_v3_read <manifest> <mode> [tool] - dispatch: python3 when available, else awk.
_manifest_v3_read() {
    [[ -f "$1" ]] || return 0
    _aid_mc_prime "$1"
    if _aid_mc_find "$1" && _aid_mc_emit "$2" "${3:-}"; then return 0; fi
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

    local fmt
    fmt="$(manifest_format "$manifest")"
    if [[ "$fmt" == 2 ]]; then
        printf 'Layout: format 4 (pre-shared). Run: aid update\n'
        return 0
    fi
    drift_report "$target" "$manifest"
    return 0
}

# Drift view of one root region: CRLF and lone CR count as LF (so a Windows checkout of an
# LF region hashes the same); prints missing, or region and writes the region's lines
# (LF-terminated as in the file) to AID_CANON_OUT.
_AID_AWK_DRIFT_REGION='
{ L[++n] = $0 }
END {
    for (i = 1; i <= n; i++) {
        s = L[i]; term = (i < n) || endnl
        if (sub(/\r$/, "", s)) term = 1
        if (s == "") { m = 1; parts[1] = "" } else m = split(s, parts, "\r")
        for (k = 1; k <= m; k++) { c++; T[c] = parts[k]; TT[c] = (k < m) ? 1 : term }
    }
    for (i = 1; i <= c; i++) { if (T[i] == mb) { nb++; b = i } else if (T[i] == me) { ne++; e = i } }
    if (nb != 1 || ne != 1 || e < b) { print "missing"; exit }
    print "region"
    out = ENVIRON["AID_CANON_OUT"]
    for (i = b; i <= e; i++) printf "%s%s", T[i], (TT[i] ? "\n" : "") > out
    close(out)
}'

# drift_report <target> <manifest> - report shared and tool-file drift without writes.
drift_report() {
    local target="$1" manifest="$2" root="${1%/}"
    local rec rest key rel sha base dir t sec fname decision canon got label abs p x name child folder
    local -A exp=() mirrors=() skill_sha=() has_sec=() sec_sha=() recfile=() recdir=() paths=() labels=() hashes=()
    local -a skill_rels=() issues=() files=() sorted_mirrors=() bases=()
    if [[ "$(manifest_format "$manifest")" == 2 ]]; then
        echo 'Layout: format 4 (pre-shared). Run: aid update'
        return 0
    fi
    while IFS= read -r rec; do
        key="${rec%%$'\t'*}"; rest="${rec#*$'\t'}"
        case "$key" in
            shared.skills.file)
                rel="${rest%%$'\t'*}"; sha="${rest#*$'\t'}"
                if [[ -n "$rel" ]]; then exp[".agents/skills"$'\t'"$rel"]="$sha"; skill_rels+=("$rel"); skill_sha[$rel]="$sha"; fi ;;
            shared.runtime.file)
                rel="${rest%%$'\t'*}"; sha="${rest#*$'\t'}"
                [[ -n "$rel" ]] && exp[".aid/runtime"$'\t'"$rel"]="$sha" ;;
            shared.mirror) mirrors["${rest%%$'\t'*}"]=1 ;;
            shared.agents_md.*|shared.claude_md.*)
                sec="${key#shared.}"; sec="${sec%%.*}"; has_sec[$sec]=1
                [[ "$key" == *.region_sha256 ]] && sec_sha[$sec]="$rest" ;;
        esac
    done < <(manifest_read_shared "$manifest")
    while IFS= read -r t; do
        [[ -n "$t" ]] || continue
        while IFS= read -r rec; do
            key="${rec%%$'\t'*}"; rest="${rec#*$'\t'}"
            case "$key" in
                "tools.${t}.mirror") mirrors[$rest]=1 ;;
                "tools.${t}.file")
                    rel="${rest%%$'\t'*}"; sha="${rest#*$'\t'}"
                    [[ -n "$rel" ]] && exp[$'\t'"$rel"]="$sha" ;;
            esac
        done < <(manifest_read_tool_files "$manifest" "$t")
    done < <(manifest_list_tools "$manifest")
    for dir in "${!mirrors[@]}"; do
        for rel in "${skill_rels[@]+"${skill_rels[@]}"}"; do exp["$dir"$'\t'"$rel"]="${skill_sha[$rel]}"; done
    done

    for key in "${!exp[@]}"; do
        base="${key%%$'\t'*}"; rel="${key#*$'\t'}"
        recfile[$key]=1
        p="$rel"; recdir["${base}"$'\t'"${p}"]=1
        while [[ "$p" == */* ]]; do p="${p%/*}"; recdir["${base}"$'\t'"${p}"]=1; done
        if [[ "$base" == .aid/runtime || ( -z "$base" && "$rel" == .aid/runtime/* ) ]] && [[ "/$rel/" == */node_modules/* ]]; then continue; fi
        if [[ -n "$base" ]]; then abs="${root}/${base}/${rel}"; label="${base}/${rel}"; else abs="${root}/${rel}"; label="$rel"; fi
        paths[$abs]="${exp[$key]}"; labels[$abs]="$label"
    done
    for abs in "${!paths[@]}"; do [[ -f "$abs" ]] && files+=("$abs"); done
    if [[ "${#files[@]}" -gt 0 ]]; then
        while IFS=$'\t' read -r sha p; do hashes[$p]="$sha"; done < <(printf '%s\0' "${files[@]}" | _aid_sha256_batch)
        for abs in "${files[@]}"; do [[ -n "${hashes[$abs]:-}" ]] || hashes[$abs]="$(sha256_file "$abs" 2>/dev/null)"; done
    fi
    for abs in "${!paths[@]}"; do
        if [[ -z "${hashes[$abs]:-}" ]]; then issues+=("1"$'\t'"${labels[$abs]}")
        elif [[ -n "${paths[$abs]}" && "${hashes[$abs]}" != "${paths[$abs]}" ]]; then issues+=("0"$'\t'"${labels[$abs]}"); fi
    done
    for sec in agents_md claude_md; do
        [[ -n "${has_sec[$sec]:-}" ]] || continue
        if [[ "$sec" == agents_md ]]; then fname=AGENTS.md; else fname=CLAUDE.md; fi
        if [[ ! -f "${root}/${fname}" ]]; then issues+=("1"$'\t'"$fname"); continue; fi
        canon="$(mktemp)" || return 1
        decision="$(AID_CANON_OUT="$canon" LC_ALL=C awk -v endnl="$(_aid_file_endnl "${root}/${fname}")" -v mb='<!-- AID:BEGIN -->' -v me='<!-- AID:END -->' "$_AID_AWK_DRIFT_REGION" "${root}/${fname}")"
        if [[ "$decision" != region ]]; then issues+=("1"$'\t'"$fname")
        else
            got="$(sha256_file "$canon")"
            [[ "$got" == "${sec_sha[$sec]:-}" ]] || issues+=("0"$'\t'"$fname")
        fi
        rm -f "$canon"
    done

    bases=(".agents/skills")
    if [[ "${#mirrors[@]}" -gt 0 ]]; then
        while IFS= read -r dir; do [[ -n "$dir" ]] && bases+=("$dir"); done < <(printf '%s\n' "${!mirrors[@]}" | LC_ALL=C sort)
    fi
    for base in "${bases[@]}"; do
        folder="${root}/${base}"
        [[ -d "$folder" ]] || continue
        while IFS= read -r -d '' child; do
            name="${child##*/}"
            if [[ -f "$child" ]]; then
                [[ -n "${recfile[${base}$'\t'${name}]+x}" ]] || issues+=("2"$'\t'"${base}/${name}")
            elif [[ -d "$child" ]]; then
                [[ -n "${recdir[${base}$'\t'${name}]+x}" ]] || issues+=("2"$'\t'"${base}/${name}")
                while IFS= read -r -d '' p; do
                    [[ -f "$p" ]] || continue
                    x="${p#"${folder}"/}"
                    [[ -n "${recfile[${base}$'\t'${x}]+x}" ]] || issues+=("2"$'\t'"${base}/${x}")
                done < <(find "$child" -mindepth 1 \( -type f -o -type l \) -print0)
            fi
        done < <(find "$folder" -mindepth 1 -maxdepth 1 -name 'aid-*' -print0)
    done
    folder="${root}/.aid/runtime"
    if [[ -d "$folder" ]]; then
        while IFS= read -r -d '' p; do
            [[ -f "$p" ]] || continue
            rel="${p#"${folder}"/}"
            [[ "/$rel/" == */node_modules/* ]] && continue
            [[ -n "${exp[.aid/runtime$'\t'${rel}]+x}" ]] || issues+=("2"$'\t'".aid/runtime/${rel}")
        done < <(find "$folder" \( -type f -o -type l \) -print0)
    fi

    if [[ "${#issues[@]}" -eq 0 ]]; then echo 'Shared files: clean'; return 0; fi
    echo 'Shared files'
    printf '%s\n' "${issues[@]}" | LC_ALL=C sort -u | while IFS=$'\t' read -r rec label; do
        case "$rec" in 0) key=modified ;; 1) key=missing ;; *) key=extra ;; esac
        printf '%s: %s\n' "$key" "$label"
    done
    echo 'Run: aid update (drifted files are moved to .aid/.trash/ first)'
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
# Shared-layout prune (format 3)
# ---------------------------------------------------------------------------

# prune_shared <target> <previous-manifest>
# Prune only AID-owned candidates after a shared install has written its new
# manifest. Files matching the previous manifest are deleted; all other bytes
# are preserved in .aid/.trash before their source paths are removed.
prune_shared() {
    local target="$1" previous="$2" current="${target}/.aid/.aid-manifest.json"
    local manifest="$current" line rel sha path root tool child dpath
    local -A wanted=() old=() roots=() previous_roots=() hashed=()
    local -a candidates=() directories=() records=() current_tools=() stale=() empties=()
    [[ -f "$previous" ]] || previous=""
    [[ -n "$previous" ]] && _aid_mc_prime "$previous"
    _aid_mc_prime "$current"
    if [[ -n "$previous" ]]; then
        # One read per manifest view: the records are reused by both passes below.
        mapfile -t records < <(manifest_read_shared "$previous")
        for line in "${records[@]}"; do
            case "$line" in
                shared.skills.file$'\t'*) rel="${line#*$'\t'}"; rel="${rel%%$'\t'*}"; sha="${line##*$'\t'}"; old["${target}/.agents/skills/${rel}"]="$sha" ;;
                shared.runtime.file$'\t'*) rel="${line#*$'\t'}"; rel="${rel%%$'\t'*}"; sha="${line##*$'\t'}"; old["${target}/.aid/runtime/${rel}"]="$sha" ;;
                shared.mirror$'\t'*) IFS=$'\t' read -r _ root _ _ <<< "$line"; previous_roots["$root"]=1 ;;
            esac
        done
        for line in "${records[@]}"; do
            [[ "$line" == shared.skills.file$'\t'* ]] || continue
            rel="${line#*$'\t'}"; rel="${rel%%$'\t'*}"; sha="${line##*$'\t'}"
            for root in "${!previous_roots[@]}"; do old["${target}/${root}/${rel}"]="$sha"; done
        done
        while IFS= read -r tool; do
            while IFS= read -r line; do
                [[ "$line" == "tools.${tool}.file"$'\t'* ]] || continue
                IFS=$'\t' read -r _ rel sha <<< "$line"; old["${target}/${rel}"]="$sha"
            done < <(manifest_read_tool_files "$previous" "$tool")
        done < <(manifest_list_tools "$previous")
    fi
    mapfile -t records < <(manifest_read_shared "$manifest")
    for line in "${records[@]}"; do
        case "$line" in
            shared.skills.file$'\t'*) rel="${line#*$'\t'}"; wanted["${target}/.agents/skills/${rel%%$'\t'*}"]=1 ;;
            shared.runtime.file$'\t'*) rel="${line#*$'\t'}"; wanted["${target}/.aid/runtime/${rel%%$'\t'*}"]=1 ;;
            shared.mirror$'\t'*) IFS=$'\t' read -r _ root _ _ <<< "$line"; roots["$root"]=1 ;;
        esac
    done
    for line in "${records[@]}"; do
        [[ "$line" == shared.skills.file$'\t'* ]] || continue
        rel="${line#*$'\t'}"; rel="${rel%%$'\t'*}"
        for root in "${!roots[@]}"; do [[ "$root" == .agents/skills ]] || wanted["${target}/${root}/${rel}"]=1; done
    done
    mapfile -t current_tools < <(manifest_list_tools "$current")
    if [[ -d "${target}/.aid/runtime" ]]; then
        while IFS= read -r -d '' path; do
            [[ "$path" == */node_modules/* ]] && continue
            candidates+=("$path")
        done < <(find "${target}/.aid/runtime" -type f -print0 2>/dev/null)
    fi
    for tool in "${current_tools[@]}"; do
        while IFS= read -r line; do
            [[ "$line" == "tools.${tool}.file"$'\t'* ]] || continue
            IFS=$'\t' read -r _ rel _ <<< "$line"; wanted["${target}/${rel}"]=1
        done < <(manifest_read_tool_files "$current" "$tool")
    done
    # Collect candidates from the controlled roots, then remove every unrecorded path.
    for root in .agents/skills "${!roots[@]}" "${!previous_roots[@]}" .aid/runtime; do
        [[ -d "${target}/${root}" ]] || continue
        if [[ "$root" == .aid/runtime ]]; then
            while IFS= read -r -d '' path; do [[ "$path" == */node_modules/* ]] || candidates+=("$path"); done < <(find "${target}/${root}" -type f -print0 2>/dev/null)
        else
            while IFS= read -r -d '' path; do rel="${path#${target}/${root}/}"; [[ "$rel" == aid-* || "$rel" == aid-*/* ]] && candidates+=("$path"); done < <(find "${target}/${root}" -type f -print0 2>/dev/null)
        fi
    done
    for tool in "${current_tools[@]}"; do
        root="$(_root_dir "$tool")/agents"; [[ -d "${target}/${root}" ]] || continue
        while IFS= read -r -d '' path; do rel="${path#${target}/${root}/}"; [[ "$rel" == aid-* || "$rel" == aid-*/* ]] && candidates+=("$path"); done < <(find "${target}/${root}" -type f -print0 2>/dev/null)
    done
    # Hash every unwanted candidate in one pass (sha256_file remains the per-file
    # fallback for anything the batch could not hash).
    for path in "${candidates[@]}"; do
        case "$path" in */node_modules/*) continue;; esac
        [[ -z "${wanted[$path]+x}" && -f "$path" ]] && stale+=("$path")
    done
    if [[ "${#stale[@]}" -gt 0 ]]; then
        while IFS=$'\t' read -r sha path; do hashed["$path"]="$sha"; done < <(printf '%s\0' "${stale[@]}" | _aid_sha256_batch)
    fi
    # Unchanged recorded files are deleted in batches (one rm per run of them); a batch is
    # flushed before any trash move so the filesystem sees the same order of operations.
    local -a doomed=()
    local -A doomed_set=()
    _prune_flush() {
        local _pf_p
        [[ "${#doomed[@]}" -gt 0 ]] || return 0
        if ! printf '%s\0' "${doomed[@]}" | xargs -0 rm -f -- 2>/dev/null; then
            # Redo the batch one file at a time for the exact per-file error and stop.
            for _pf_p in "${doomed[@]}"; do
                if [[ -e "$_pf_p" || -L "$_pf_p" ]]; then rm -f "$_pf_p" || return 1; fi
                [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Removed: ${_pf_p}"
            done
        elif [[ "${AID_VERBOSE:-0}" -eq 1 ]]; then
            for _pf_p in "${doomed[@]}"; do echo "Removed: ${_pf_p}"; done
        fi
        doomed=()
        return 0
    }
    for path in "${candidates[@]}"; do
        [[ -f "$path" ]] || continue
        [[ -n "${doomed_set[$path]+x}" ]] && continue
        rel="${path#${target}/}"
        case "$path" in */node_modules/*) continue;; esac
        if [[ -n "${wanted[$path]+x}" ]]; then continue; fi
        if [[ -n "${hashed[$path]:-}" ]]; then sha="${hashed[$path]}"; else sha="$(sha256_file "$path")"; fi
        if [[ -n "${old[$path]:-}" && "${old[$path]}" == "$sha" ]]; then
            doomed+=("$path"); doomed_set["$path"]=1
        else
            _prune_flush || return 1
            trash_file "$target" "$path" || return 1
        fi
    done
    _prune_flush || return 1
    # Remove empty AID directories, but never a placement root.
    for root in .agents/skills .aid/runtime "${!roots[@]}" "${!previous_roots[@]}"; do [[ -d "${target}/${root}" ]] && directories+=("${target}/${root}"); done
    for tool in "${current_tools[@]}"; do root="$(_root_dir "$tool")/agents"; [[ -d "${target}/${root}" ]] && directories+=("${target}/${root}"); done
    for root in "${directories[@]}"; do
        [[ -d "$root" ]] || continue
        empties=()
        while IFS= read -r dpath; do
            [[ "$dpath" == "$root" ]] && continue
            rel="${dpath#${root}/}"
            if [[ "$root" == "${target}/.aid/runtime" ]]; then
                [[ "$dpath" == */node_modules || "$dpath" == */node_modules/* ]] && continue
            else
                child="${rel%%/*}"
                [[ "$child" == aid-* ]] || continue
            fi
            empties+=("$dpath")
        done < <(find "$root" -depth -type d 2>/dev/null)
        # One rmdir for the whole depth-first list: it tries each path in order, so a
        # parent emptied by its children's removal still goes; non-empty ones stay.
        if [[ "${#empties[@]}" -gt 0 ]]; then printf '%s\0' "${empties[@]}" | xargs -0 rmdir -- 2>/dev/null || true; fi
    done
    # A mirror root that no remaining tool declares goes once it is empty (rmdir never
    # removes a non-empty directory, so user content under it is preserved). The tool
    # root that holds it (e.g. .claude/) is never touched.
    for root in "${!previous_roots[@]}"; do
        [[ -n "${roots[$root]+x}" || "$root" == .agents/skills ]] && continue
        rmdir "${target}/${root}" 2>/dev/null || true
    done
    if [[ ! -f "$current" ]]; then rmdir "${target}/.aid/runtime" 2>/dev/null || true; fi
}

# ---------------------------------------------------------------------------
# Retired-root migration sweep (FR7/FR7a)
# ---------------------------------------------------------------------------

# _migrate_retired_layout <target> <tool>
#
# Complete-replacement migration: removes AID-owned content from the static
# list of retired AID roots that no longer exist in the new bundle layout.
# No commit path calls this function (a v3 upgrade retires the old layout through
# retire_v3_layout, and --dry-run lists nothing from here); it stays as a tested primitive.
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
        codex) ;;
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
# does not already exist. When a format-3 manifest has just been committed, advance
# only an older format stamp; the remaining bytes are user config. Not recorded in the manifest: it is
# user data and must survive `aid remove`/prune and never flow through the copy
# engine. Sets _CORE_SEEDED_SETTINGS=1 when a file was created, else 0.
seed_settings_yml() {
    local target="$1" tool="$2"
    local dst tmpl
    _CORE_SEEDED_SETTINGS=0
    dst="${target}/.aid/settings.yml"
    tmpl="${target}/.aid/runtime/templates/settings.yml"
    if [[ -f "$dst" ]]; then
        local manifest="${target}/.aid/.aid-manifest.json" raw stamp tmp updated=0 line read_rc
        if [[ -f "$manifest" ]] && [[ "$(manifest_format "$manifest")" == 3 ]]; then
            raw="$(grep -m1 '^format_version:' "$dst" 2>/dev/null)" || true
            stamp="${raw#format_version:}"
            stamp="${stamp%%#*}"
            stamp="${stamp//[[:space:]]/}"
            stamp="${stamp%\"}"
            stamp="${stamp#\"}"
            stamp="${stamp%\'}"
            stamp="${stamp#\'}"
            if [[ "$stamp" =~ ^[0-4]$ ]]; then
                local stamp_pattern="^(format_version:[[:space:]]*[\"']?)[0-9]+(.*)$"
                tmp="$(mktemp "${dst}.aid-tmp.XXXXXX")" || return 1
                while :; do
                    line=""
                    if IFS= read -r line; then read_rc=0; else read_rc=$?; fi
                    [[ $read_rc -ne 0 && -z "$line" ]] && break
                    if [[ $updated -eq 0 && "$line" =~ $stamp_pattern ]]; then
                        line="${BASH_REMATCH[1]}5${BASH_REMATCH[2]}"
                        updated=1
                    fi
                    printf '%s' "$line" >> "$tmp" || { rm -f "$tmp"; return 1; }
                    if [[ $read_rc -eq 0 ]]; then printf '\n' >> "$tmp" || { rm -f "$tmp"; return 1; }; fi
                done < "$dst"
                if [[ $updated -eq 1 ]]; then
                    cat "$tmp" > "$dst" || { rm -f "$tmp"; return 1; }
                fi
                rm -f "$tmp" || return 1
            fi
        fi
        return 0
    fi
    # Template absent -> a bundle shipped without the shared runtime template.
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
    local manifest="${_AID_PROJECT_TARGET:-$PWD}/.aid/.aid-manifest.json" worktree=".aid/.worktrees"
    if [[ -f "$manifest" ]]; then
        local record
        record="$(manifest_read_host "$manifest" | awk -F '\t' '$1=="host.worktree_root" {print $2; exit}')"
        [[ -n "$record" ]] && worktree="$record"
    fi
    printf '%s\n' "$_AID_GI_BEGIN"
    printf '%s\n' \
        ".aid/.temp/" \
        ".aid/.trash/" \
        ".aid/.heartbeat/" \
        ".aid/.control/" \
        ".aid/generated/" \
        ".aid/knowledge/.cache/" \
        ".aid/.worktrees/"
    [[ "$worktree" == .aid/* ]] || printf '%s\n' "${worktree%/}/"
    printf '%s\n' ".aid/runtime/**/node_modules/"
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
    _AID_PROJECT_TARGET="$target"
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

# write_host_conf <target> <worktree_root>
write_host_conf() {
    local target="$1" worktree="${2:-.aid/.worktrees}" path="${1}/.aid/runtime/host.conf"
    mkdir -p "$(dirname "$path")" || return 1
    printf 'worktree_root=%s\n' "$worktree" > "$path"
}

_AID_GA_BEGIN="$_AID_GI_BEGIN"
_AID_GA_END="$_AID_GI_END"
_aid_gitattributes_block() {
    printf '%s\n' "$_AID_GA_BEGIN" \
        '.agents/skills/aid-*/** text eol=lf' \
        '.claude/skills/aid-*/** text eol=lf' \
        '.aid/runtime/** text eol=lf' \
        '.claude/agents/aid-* text eol=lf' \
        '.codex/agents/aid-* text eol=lf' \
        '.cursor/agents/aid-* text eol=lf' \
        '.github/agents/aid-* text eol=lf' \
        '.agent/agents/aid-* text eol=lf' "$_AID_GA_END"
}

# update_gitattributes <target>; bytes outside the managed span are retained.
# The managed span runs from the begin marker's line start through the end marker's line
# break; with no span the block is appended after one blank line.
update_gitattributes() {
    local LC_ALL=C
    local target="$1" path="${1}/.gitattributes" block blk old="" pre linepre rest pre2 start ls le two new sep tmp found=0
    block="$(_aid_gitattributes_block)"
    blk="${block}"$'\n'
    if [[ -f "$path" ]]; then old="$(cat "$path"; printf x)"; old="${old%x}"; fi
    if [[ "$old" == *"$_AID_GA_BEGIN"* ]]; then
        pre="${old%%"$_AID_GA_BEGIN"*}"; start=${#pre}
        linepre="${pre##*$'\n'}"
        if [[ -z "${linepre//$'\r'/}" ]]; then
            rest="${old:start}"
            if [[ "$rest" == *"$_AID_GA_END"* ]]; then
                pre2="${rest%%"$_AID_GA_END"*}"
                ls=$(( start - ${#linepre} ))
                le=$(( start + ${#pre2} + ${#_AID_GA_END} ))
                two="${old:le:2}"
                if [[ "$two" == $'\r\n' ]]; then le=$((le + 2))
                elif [[ "${two:0:1}" == $'\n' || "${two:0:1}" == $'\r' ]]; then le=$((le + 1)); fi
                found=1
            fi
        fi
    fi
    if [[ "$found" -eq 1 ]]; then
        new="${old:0:ls}${blk}${old:le}"
    else
        sep=""
        if [[ -n "$old" ]]; then
            if [[ "${old: -1}" != $'\n' && "${old: -1}" != $'\r' ]]; then sep=$'\n'; fi
            if [[ "$old" != *$'\n\n' && "$old" != *$'\r\n\r\n' ]]; then sep+=$'\n'; fi
        fi
        new="${old}${sep}${blk}"
    fi
    [[ "$new" != "$old" ]] || return 0
    mkdir -p "$target" || return 1
    tmp="$(mktemp "${target}/.gitattributes.aid-XXXXXX")" || return 1
    if ! printf '%s' "$new" > "$tmp" || ! mv -f "$tmp" "$path"; then rm -f "$tmp"; return 1; fi
}

# ---------------------------------------------------------------------------
# High-level install_tool
# ---------------------------------------------------------------------------

# install_tool <staging_dir> <tool> <target>
# <staging_dir> - directory produced by extract_tarball (content of profiles/<tool>/)
# Installs only the staged agents tree of <tool>: shared skills, runtime and root
# context are committed once by install_shared after every tool.
# Returns:
#   0 - success (all files installed or up-to-date)
#   1 - a file failed to copy
install_tool() {
    local staging="$1" tool="$2" target="$3"
    local manifest="${target}/.aid/.aid-manifest.json"
    _aid_mc_prime "$manifest"

    # Per-tool file counters (incremented by copy_file_guarded).
    _COPY_COUNT_COPIED=0
    _COPY_COUNT_UPTODATE=0
    _COPY_COUNT_UPDATED=0
    _COPY_COUNT_SKIPPED=0
    _COPY_COUNT_FAILED=0

    local agents_src="${staging}/$( _root_dir "$tool" )/agents"
    if [[ -d "$agents_src" ]]; then
        # Read the tool's recorded hashes once (first record per path wins, as before).
        local -A tool_sha=()
        local rec rec_path
        if [[ -f "$manifest" ]]; then
            while IFS= read -r rec; do
                [[ "$rec" == *$'\t'* ]] || continue
                rec="${rec#*$'\t'}"; rec_path="${rec%%$'\t'*}"
                if [[ "$rec" == *$'\t'* ]]; then rec="${rec#*$'\t'}"; rec="${rec%%$'\t'*}"; else rec=""; fi
                [[ -n "${tool_sha[$rec_path]+x}" ]] || tool_sha["$rec_path"]="$rec"
            done < <(manifest_read_tool_files "$manifest" "$tool")
        fi
        while IFS= read -r -d '' f; do
            local rel="${f#${staging}/}"
            local old_sha="${tool_sha[$rel]:-}"
            copy_file_guarded "$f" "${target}/${rel}" "$old_sha" "$target"
        done < <(find "$agents_src" -type f -print0 2>/dev/null | sort -z)
    fi
    [[ "${_COPY_COUNT_FAILED:-0}" -eq 0 ]] || return 1
    local add_total=$((_COPY_COUNT_COPIED + _COPY_COUNT_UPTODATE + _COPY_COUNT_UPDATED + _COPY_COUNT_SKIPPED))
    if [[ "$add_total" -gt 0 && "$_COPY_COUNT_UPTODATE" -eq "$add_total" ]]; then
        echo "  up to date (${add_total} files)"
    elif [[ "$add_total" -gt 0 ]]; then
        echo "  ${_COPY_COUNT_COPIED} installed, ${_COPY_COUNT_UPDATED} updated, ${_COPY_COUNT_UPTODATE} unchanged"
    fi
    return 0
}

# install_shared <shared-stage> <target> <version> <new-tools-file> [force]
# Commits the shared payload and every newly staged agents tree, repairs root
# context once, then records the complete format-3 install atomically.
install_shared() {
    local shared="$1" target="$2" version="$3" new_file="$4" force="${5:-0}" phase="${6:-all}"
    local manifest="${target}/.aid/.aid-manifest.json" now old_shared old_host old_tools
    _aid_mc_prime "$manifest"
    local skills_src="${shared}/skills" runtime_src="${shared}/runtime" f rel old_sha tool stage root conf key value
    local inline=0 claude_users=0 region region_sha agents_sha claude_sha line host_worktree=".aid/.worktrees" previous_manifest=""
    local -A old_hash=() mirrors=() mirror_users=() tool_mirror=() tool_wr=() tool_inline=() tool_context=() tool_stage=()
    local -a all_tools=() new_tools=()

    [[ -f "$manifest" ]] && while IFS= read -r line; do
        case "$line" in
            shared.skills.file$'\t'*) rel="${line#*$'\t'}"; old_hash["skills:${rel%%$'\t'*}"]="${rel#*$'\t'}" ;;
            shared.runtime.file$'\t'*) rel="${line#*$'\t'}"; old_hash["runtime:${rel%%$'\t'*}"]="${rel#*$'\t'}" ;;
            shared.claude_md.users$'\t'*) [[ "${AID_UPGRADE_EXACT:-0}" == 1 ]] || claude_users=1 ;;
        esac
    done < <(manifest_read_shared "$manifest")

    while IFS=$'\t' read -r tool stage; do [[ -n "$tool" ]] && tool_stage["$tool"]="$stage" && new_tools+=("$tool"); done < "$new_file"
    if [[ "${AID_UPGRADE_EXACT:-0}" == 1 ]]; then
        all_tools=("${new_tools[@]}")
    else
        while IFS= read -r tool; do [[ -n "$tool" ]] && all_tools+=("$tool"); done < <({ [[ -f "$manifest" ]] && manifest_list_tools "$manifest"; printf '%s\n' "${new_tools[@]}"; } | sort -u)
    fi
    # Restore the product's declared tool order.
    local ordered=(); for tool in "${AID_TOOLS[@]}"; do for rel in "${all_tools[@]}"; do [[ "$rel" == "$tool" ]] && ordered+=("$tool"); done; done
    all_tools=("${ordered[@]}")

    if [[ "$phase" != finalize && "$phase" != update-finalize ]]; then
    _COPY_COUNT_COPIED=0; _COPY_COUNT_UPTODATE=0; _COPY_COUNT_UPDATED=0; _COPY_COUNT_SKIPPED=0; _COPY_COUNT_FAILED=0
    local -A same=()
    while IFS= read -r -d '' rel; do if [[ "$rel" == S* ]]; then same["${rel#S}"]=1; else same["${rel#C}"]=2; fi; done < <(_aid_same_rels "$skills_src" "${target}/.agents/skills" 1)
    while IFS= read -r -d '' f; do
        rel="${f#${skills_src}/}"
        [[ "$rel" == aid-*/* ]] || continue
        copy_file_guarded "$f" "${target}/.agents/skills/${rel}" "${old_hash[skills:$rel]:-}" "$target" "${same[$rel]:-0}"
    done < <(find "$skills_src" -type f -print0 2>/dev/null | sort -z)

    # Every mirror is declared by the full installed/new tool set. Never touch
    # user-owned names outside the aid-* namespace.
    for tool in "${all_tools[@]}"; do
        local -a declared=()
        if [[ -n "${tool_stage[$tool]:-}" ]]; then conf="${tool_stage[$tool]}/aid-tool.conf"; else conf=""; fi
        if [[ -n "$conf" && -r "$conf" ]]; then
            while IFS= read -r line; do [[ "$line" == skill_mirror=* ]] && declared+=("${line#skill_mirror=}"); done < <(read_kv_conf "$conf")
        elif [[ -f "$manifest" ]]; then
            while IFS= read -r line; do [[ "$line" == "tools.${tool}.mirror"$'\t'* ]] && declared+=("${line#*$'\t'}"); done < <(manifest_read_tool_files "$manifest" "$tool")
        fi
        tool_mirror[$tool]="$(IFS=,; echo "${declared[*]}")"
        for root in "${declared[@]}"; do
            mirror_users[$root]+=" $tool"
            same=()
            while IFS= read -r -d '' rel; do if [[ "$rel" == S* ]]; then same["${rel#S}"]=1; else same["${rel#C}"]=2; fi; done < <(_aid_same_rels "$skills_src" "${target}/${root}" 1)
            while IFS= read -r -d '' f; do
                rel="${f#${skills_src}/}"; [[ "$rel" == aid-*/* ]] || continue
                old_sha=""
                old_sha="${old_hash[skills:$rel]:-}"
                copy_file_guarded "$f" "${target}/${root}/${rel}" "$old_sha" "$target" "${same[$rel]:-0}"
            done < <(find "$skills_src" -type f -print0 2>/dev/null | sort -z)
        done
    done

    same=()
    while IFS= read -r -d '' rel; do if [[ "$rel" == S* ]]; then same["${rel#S}"]=1; else same["${rel#C}"]=2; fi; done < <(_aid_same_rels "$runtime_src" "${target}/.aid/runtime")
    while IFS= read -r -d '' f; do
        rel="${f#${runtime_src}/}"
        copy_file_guarded "$f" "${target}/.aid/runtime/${rel}" "${old_hash[runtime:$rel]:-}" "$target" "${same[$rel]:-0}"
    done < <(find "$runtime_src" -type f -print0 2>/dev/null | sort -z)
    [[ "${_COPY_COUNT_FAILED:-0}" -eq 0 ]] || return 1
    local total=$((_COPY_COUNT_COPIED + _COPY_COUNT_UPTODATE + _COPY_COUNT_UPDATED + _COPY_COUNT_SKIPPED))
    if [[ "$total" -gt 0 && "$_COPY_COUNT_UPTODATE" -eq "$total" ]]; then echo "  up to date (${total} files)"; else echo "  ${_COPY_COUNT_COPIED} copied, ${_COPY_COUNT_UPDATED} updated, ${_COPY_COUNT_UPTODATE} unchanged"; fi
    [[ "$phase" == payload ]] && return 0
    if [[ "$phase" == update-payload ]]; then
        for tool in "${all_tools[@]}"; do
            conf="${tool_stage[$tool]:-}/aid-tool.conf"
            if [[ -r "$conf" ]]; then
                while IFS= read -r line; do [[ "$line" == worktree_root=* ]] && { host_worktree="${line#worktree_root=}"; break 2; }; done < <(read_kv_conf "$conf")
            elif [[ -f "$manifest" ]]; then
                while IFS=$'\t' read -r key value; do [[ "$key" == "tools.${tool}.worktree_root" ]] && { host_worktree="$value"; break 2; }; done < <(manifest_read_tool_files "$manifest" "$tool")
            fi
        done
        write_host_conf "$target" "$host_worktree" || return 1
        return 0
    fi
    fi

    # Record per-tool placement metadata, preserving existing installed choices.
    for tool in "${all_tools[@]}"; do
        if [[ -n "${tool_stage[$tool]:-}" ]]; then
            conf="${tool_stage[$tool]}/aid-tool.conf"
            while IFS= read -r line; do
                key="${line%%=*}"; value="${line#*=}"
                case "$key" in worktree_root) tool_wr[$tool]="$value";; rules_inline) [[ "$value" == true ]] && tool_inline[$tool]=true;; context_import) [[ "$value" == CLAUDE.md ]] && tool_context[$tool]=CLAUDE.md;; esac
            done < <(read_kv_conf "$conf")
        else
            while IFS=$'\t' read -r key value; do
                case "$key" in "tools.${tool}.worktree_root") tool_wr[$tool]="$value";; "tools.${tool}.rules_inline") tool_inline[$tool]=true;; esac
            done < <(manifest_read_tool_files "$manifest" "$tool")
        fi
        [[ -n "${tool_inline[$tool]:-}" ]] && inline=1
        [[ -n "${tool_context[$tool]:-}" ]] && claude_users=1
    done
    for tool in "${all_tools[@]}"; do
        if [[ -n "${tool_wr[$tool]:-}" ]]; then host_worktree="${tool_wr[$tool]}"; break; fi
    done
    [[ "$phase" == update-finalize ]] || write_host_conf "$target" "$host_worktree" || return 1

    region="$_AID_AGENTS_POINTER_REGION"
    if [[ "$inline" -eq 1 ]]; then region="$(printf '<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'; cat "${target}/.aid/runtime/rules.md"; printf '<!-- AID:END -->\n')"$'\n'; fi
    if [[ "$inline" -eq 1 ]]; then
        _repair_inline_root_region "${target}/AGENTS.md" "$region" "$target" || return 1
    else
        _repair_root_region "${target}/AGENTS.md" "$region" "$target" || return 1
    fi
    region_sha="$(printf '%s' "$region" | _aid_sha256_stdin)"
    agents_sha="$(sha256_file "${target}/AGENTS.md")"
    if [[ "$claude_users" -eq 1 ]]; then
        claude_sha="$(_ensure_claude_md_region "${target}/CLAUDE.md" "$target" "$inline")" || return 1
    else claude_sha=""; fi
    [[ "${_COPY_COUNT_FAILED:-0}" -eq 0 ]] || return 1

    now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    local model; model="$(mktemp "${target}/.aid/.manifest-model.XXXXXX")" || return 1
_aid_build_install_model "$manifest" "$model" "$shared" "$target" "$version" "$now" "$new_file" "$region_sha" "$agents_sha" "$claude_sha" || { rm -f "$model"; return 1; }
    if [[ -f "$manifest" ]]; then previous_manifest="$(mktemp "${target}/.aid/.manifest-before-prune.XXXXXX")" || { rm -f "$model"; return 1; }; cp "$manifest" "$previous_manifest" || { rm -f "$model" "$previous_manifest"; return 1; }; fi
    if ! manifest_write_v3 "$manifest" "$model"; then rm -f "$model" "${previous_manifest:-}"; return 1; fi
    rm -f "$model"
    prune_shared "$target" "$previous_manifest" || { rm -f "${previous_manifest:-}"; return 1; }
    rm -f "${previous_manifest:-}"
    seed_settings_yml "$target" "${new_tools[0]:-}" || return 1
    update_gitignore "$target" || return 1
    update_gitattributes "$target" || return 1
    _migrate_term_exclusions "$target" || return 1
}

# ---------------------------------------------------------------------------
# Uninstall
# ---------------------------------------------------------------------------

_remove_gitattributes_block() {
    local target="$1" path="${1}/.gitattributes"
    [[ -f "$path" ]] || return 0
    _aid_cut_marker_region "$path" 0 "$target" "" "$_AID_GA_BEGIN" "$_AID_GA_END"
}

_remove_agents_md_region() {
    local target="$1" recorded="$2" path="${1}/AGENTS.md"
    [[ -f "$path" ]] || return 0
    local actual
    actual="$(sha256_file "$path")"
    if [[ "$actual" != "$recorded" ]]; then
        echo "Left in place (modified or not AID-owned): AGENTS.md"
        return 0
    fi
    _aid_root_file_guard "$path" || return 1
    _aid_cut_marker_region "$path" 0 "$target" ""
}

_AID_AWK_REFRESH='
BEGIN { FS = OFS = "\t" }
$1 == "shared.agents_md.region_sha256" && ars != "" { print $1, ars; next }
$1 == "shared.agents_md.file_sha256" && afs != "" { print $1, afs; next }
$1 == "shared.claude_md.region_sha256" && cs != "" { print $1, cs; next }
$1 == "shared.runtime.file" && $2 == "host.conf" && hs != "" && !done { print $1, $2, hs; done = 1; next }
{ print }'
_refresh_remove_manifest_hashes() {
    local manifest="$1" target="$2" refresh_file_sha="${3:-0}" cs="${4:-}" agents="${2}/AGENTS.md" host="${2}/.aid/runtime/host.conf"
    local canon ars="" afs="" hs="" model
    if [[ -f "$agents" ]]; then
        canon="$(mktemp)" || return 1
        if AID_CANON_OUT="$canon" _aid_marker_span "$agents" >/dev/null; then
            ars="$(sha256_file "$canon")"
            [[ "$refresh_file_sha" == 1 ]] && afs="$(sha256_file "$agents")"
        fi
        rm -f "$canon"
    fi
    [[ -f "$host" ]] && hs="$(sha256_file "$host")"
    model="$(mktemp "$(dirname "$manifest")/.manifest-model.XXXXXX")" || return 1
    _manifest_model "$manifest" | LC_ALL=C awk -v ars="$ars" -v afs="$afs" -v hs="$hs" -v cs="$cs" "$_AID_AWK_REFRESH" > "$model" || { rm -f "$model"; return 1; }
    manifest_write_v3 "$manifest" "$model" || { rm -f "$model"; return 1; }
    rm -f "$model"
}

# _aid_manifest_has_inline <manifest> - 0 when any recorded tool declares rules_inline.
_aid_manifest_has_inline() {
    local t
    while IFS= read -r t; do
        if manifest_read_tool_files "$1" "$t" | awk -F '\t' -v t="$t" '$1=="tools." t ".rules_inline" && $2=="true" {found=1} END{exit !found}'; then return 0; fi
    done < <(manifest_list_tools "$1")
    return 1
}

_uninstall_tool_v3() {
    local manifest="$1" tool="$2" target="$3" format line rel sha full previous pdir root inline_before=0 claude_resync=""
    local -a paths=()
    _aid_mc_prime "$manifest"
    _aid_manifest_has_inline "$manifest" && inline_before=1
    format="$(manifest_format "$manifest")"
    [[ "$format" == 3 ]] || return 2
    previous="$(mktemp "${target}/.aid/.manifest-remove.XXXXXX")" || return 1
    cp "$manifest" "$previous" || { rm -f "$previous"; return 1; }

    while IFS= read -r line; do
        [[ "$line" == "tools.${tool}.file"$'\t'* ]] || continue
        IFS=$'\t' read -r _ rel sha <<< "$line"
        [[ "$rel" == /* || "$rel" == *'..'* ]] && continue
        paths+=("$rel")
        full="${target}/${rel}"
        [[ -f "$full" ]] || continue
        if [[ -n "$sha" && "$(sha256_file "$full")" == "$sha" ]]; then
            rm -f "$full"
            [[ "${AID_VERBOSE:-0}" -eq 1 ]] && echo "Removed: ${full}"
        else trash_file "$target" "$full" || { rm -f "$previous"; return 1; }
        fi
    done < <(manifest_read_tool_files "$manifest" "$tool")
    root="${target}/$(_root_dir "$tool")"
    for p in "${paths[@]}"; do
        _aid_dirname_to pdir "$p"; pdir="${target}/${pdir}"
        while [[ "$pdir" != "$target" && ( "$pdir" == "$root" || "$pdir" == "$root/"* ) ]]; do
            rmdir "$pdir" 2>/dev/null || true
            _aid_dirname_to pdir "$pdir"
        done
    done

    local agents_users agents_sha claude_users claude_sha shared_records agents_region_sha
    shared_records="$(manifest_read_shared "$manifest")"
    agents_users="$(printf '%s\n' "$shared_records" | awk -F '\t' '$1=="shared.agents_md.users" {print $2}')"
    agents_sha="$(printf '%s\n' "$shared_records" | awk -F '\t' '$1=="shared.agents_md.file_sha256" {print $2}')"
    claude_users="$(printf '%s\n' "$shared_records" | awk -F '\t' '$1=="shared.claude_md.users" {print $2}')"
    claude_sha="$(printf '%s\n' "$shared_records" | awk -F '\t' '$1=="shared.claude_md.region_sha256" {print $2}')"
    agents_region_sha="$(printf '%s\n' "$shared_records" | awk -F '\t' '$1=="shared.agents_md.region_sha256" {print $2}')"
    local agents_left= claude_left= u agents_file_refresh=0 agents_recorded_sha agents_current_sha
    IFS=',' read -r -a users <<< "$agents_users"
    for u in "${users[@]}"; do [[ -n "$u" && "$u" != "$tool" ]] && agents_left+="${agents_left:+,}${u}"; done
    if [[ -n "$agents_left" ]]; then
        agents_recorded_sha="$agents_sha"
        agents_current_sha="$(sha256_file "${target}/AGENTS.md" 2>/dev/null || true)"
        [[ -n "$agents_recorded_sha" && "$agents_recorded_sha" == "$agents_current_sha" ]] && agents_file_refresh=1
    fi
    IFS=',' read -r -a users <<< "$claude_users"
    for u in "${users[@]}"; do [[ -n "$u" && "$u" != "$tool" ]] && claude_left+="${claude_left:+,}${u}"; done
    if [[ -n "$agents_users" && -z "$agents_left" ]]; then _remove_agents_md_region "$target" "$agents_sha" || { rm -f "$previous"; return 1; }; fi
    if [[ -n "$claude_users" && -z "$claude_left" ]]; then _remove_claude_md_region "${target}/CLAUDE.md" "$claude_sha" "$target" || { rm -f "$previous"; return 1; }; fi

    manifest_remove_tool "$manifest" "$tool" || { rm -f "$previous"; return 1; }
    prune_shared "$target" "$previous" || { rm -f "$previous"; return 1; }
    rm -f "$previous"
    # The tool root can become empty only once its mirror is pruned (e.g. .claude/skills).
    rmdir "$root" 2>/dev/null || true

    if [[ -f "$manifest" ]]; then
        local worktree inline=0 region t
        worktree="$(manifest_list_tools "$manifest" | while IFS= read -r t; do manifest_read_tool_files "$manifest" "$t" | awk -F '\t' -v t="$t" '$1=="tools." t ".worktree_root" {print $2; exit}'; done | head -1)"
        [[ -n "$worktree" ]] || worktree='.aid/.worktrees'
        write_host_conf "$target" "$worktree" || return 1
        _aid_manifest_has_inline "$manifest" && inline=1
        if [[ "$inline" == 1 ]]; then
            region="$(printf '<!-- AID:BEGIN -->\n<!-- Managed by the AID CLI. Do not edit between the AID markers. -->\n'; cat "${target}/.aid/runtime/rules.md"; printf '<!-- AID:END -->\n')"$'\n'
            _repair_inline_root_region "${target}/AGENTS.md" "$region" "$target" "$agents_region_sha" || return 1
        else
            _repair_inline_root_region "${target}/AGENTS.md" "$_AID_AGENTS_POINTER_REGION" "$target" "$agents_region_sha" || return 1
        fi
        # CLAUDE.md follows the inline state: @AGENTS.md alone while the rules are inline, else it also imports them.
        if [[ -n "$claude_left" && "$inline_before" != "$inline" && -f "${target}/CLAUDE.md" ]]; then
            claude_resync="$(_ensure_claude_md_region "${target}/CLAUDE.md" "$target" "$inline")" || return 1
        fi
        _refresh_remove_manifest_hashes "$manifest" "$target" "$agents_file_refresh" "$claude_resync" || return 1
    else
        rm -f "$(dirname "$manifest")/settings.yml"
        _remove_gitattributes_block "$target" || return 1
    fi
    return 0
}

# uninstall_tool <manifest> <tool> <target>
# Removes all files recorded under tools.<tool>.paths that still exist.
# For root agent files: removes only when sha256 still matches recorded value.
# Prunes now-empty AID dirs.  Removes the manifest if no tools remain.
uninstall_tool() {
    local manifest="$1" tool="$2" target="$3"

    manifest_exists "$manifest" || return 6

    if [[ "$(manifest_format "$manifest")" == 3 ]]; then
        _uninstall_tool_v3 "$manifest" "$tool" "$target"
        return $?
    fi

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
