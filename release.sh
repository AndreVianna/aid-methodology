#!/usr/bin/env bash
# release.sh — Package the five per-profile AID tarballs and cut a GitHub Release.
#
# Purpose:
#   Maintainer-only helper that assembles release artifacts from a clean rendered
#   state. Verifies the committed profiles/ matches canonical/ (reusing the
#   render-drift gate from CI), stages five per-profile tarballs and a SHA256SUMS
#   file under .aid/.temp/release-<VERSION>/, then creates a GitHub Release with
#   those assets via `gh release create`. Never modifies the render pipeline and
#   never commits a render.
#
# Usage:
#   bash release.sh [--version X.Y.Z] [--sign] [--draft] [--dry-run]
#                   [--notes-file FILE] [-h|--help]
#
#   --version X.Y.Z   Release version (default: content of VERSION file). Must
#                     match the VERSION file; FAIL on mismatch.
#   --sign            Also emit a detached signature over SHA256SUMS (deferred
#                     to feature-005; exits non-zero if --sign is passed until
#                     the signing approach is settled).
#   --draft           Create the GitHub Release as a draft (default: published).
#   --dry-run         Assemble tarballs + SHA256SUMS then stop before
#                     `gh release create`. No network I/O.
#   --notes-file FILE Release notes body for `gh release create`.
#   -h|--help         Print this help and exit 0.
#
# Exit codes:
#   0   success (dry-run: staging complete; live: release created)
#   1   general failure (clean-worktree check, render-drift, gh error, etc.)
#   2   usage / argument error
#   3   version mismatch (--version X does not match VERSION file)
#   4   tag already exists (git tag or GitHub Release)
#
# Output:
#   stdout: progress messages
#   stderr: error and remediation messages

set -euo pipefail

# ---------------------------------------------------------------------------
# Python command: prefer `python` (matches CI `actions/setup-python`),
# fall back to `python3` for environments where only python3 is on PATH.
# ---------------------------------------------------------------------------
PYTHON_CMD=""
if command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
elif command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
fi

# ---------------------------------------------------------------------------
# Usage helper (prints the header block as plain text)
# ---------------------------------------------------------------------------
usage() {
    sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------------------
# Error helper
# ---------------------------------------------------------------------------
die() {
    echo "ERROR: release.sh: $1" >&2
    exit "${2:-1}"
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
VERSION_ARG=""
SIGN=0
DRAFT=0
DRY_RUN=0
NOTES_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)    VERSION_ARG="$2"; shift 2 ;;
        --sign)       SIGN=1; shift ;;
        --draft)      DRAFT=1; shift ;;
        --dry-run)    DRY_RUN=1; shift ;;
        --notes-file) NOTES_FILE="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        *)            die "unknown flag: $1" 2 ;;
    esac
done

# --sign is deferred until feature-005 settles the signing approach.
if [[ "$SIGN" -eq 1 ]]; then
    die "--sign is not yet implemented (deferred to feature-005). Omit --sign to continue." 2
fi

# ---------------------------------------------------------------------------
# Step 1: Preconditions
# ---------------------------------------------------------------------------

# Must run from repo root (VERSION file must exist here).
if [[ ! -f "VERSION" ]]; then
    die "Must be run from the repository root (VERSION file not found in: $(pwd))" 1
fi

# Resolve VERSION and TAG.
VERSION_FILE="$(tr -d '[:space:]' < VERSION)"

if [[ -n "$VERSION_ARG" ]]; then
    if [[ "$VERSION_ARG" != "$VERSION_FILE" ]]; then
        echo "ERROR: release.sh: --version $VERSION_ARG does not match VERSION file ($VERSION_FILE)." >&2
        exit 3
    fi
fi

VERSION="$VERSION_FILE"
TAG="v${VERSION}"

echo "release.sh: version=${VERSION}  tag=${TAG}"

# Assert clean git worktree (tracked files only).
if ! git diff --quiet; then
    die "Working tree has uncommitted changes. Commit or stash them before releasing." 1
fi
if ! git diff --cached --quiet; then
    die "Index has staged changes. Commit or stash them before releasing." 1
fi

# Assert the git tag does not already exist.
if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null 2>&1; then
    die "Git tag ${TAG} already exists. Delete it or choose a different version." 4
fi

# Assert no existing GitHub Release for this tag (only when not dry-run and gh is available).
if [[ "$DRY_RUN" -eq 0 ]] && command -v gh >/dev/null 2>&1; then
    if gh release view "${TAG}" >/dev/null 2>&1; then
        die "GitHub Release ${TAG} already exists. Delete it or choose a different version." 4
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: Verify clean rendered state (render-drift gate — reused from CI)
# ---------------------------------------------------------------------------

if [[ -z "$PYTHON_CMD" ]]; then
    die "Python not found. Install Python 3.11+ and ensure 'python' or 'python3' is on PATH." 1
fi

echo "release.sh: verifying render state (${PYTHON_CMD} .claude/skills/aid-generate/scripts/run_generator.py) ..."
if ! "${PYTHON_CMD}" .claude/skills/aid-generate/scripts/run_generator.py; then
    echo "ERROR: release.sh: run_generator.py failed." >&2
    echo "profiles/ is out of sync with canonical/. Run 'python .claude/skills/aid-generate/scripts/run_generator.py' and commit the result." >&2
    exit 1
fi

echo "release.sh: checking for render drift (git diff -- profiles/) ..."
if ! git diff --exit-code -- profiles/ >/dev/null 2>&1; then
    echo "ERROR: release.sh: profiles/ differs from HEAD after running .claude/skills/aid-generate/scripts/run_generator.py." >&2
    echo "profiles/ is out of sync with canonical/. Run 'python .claude/skills/aid-generate/scripts/run_generator.py' and commit the result." >&2
    exit 1
fi

echo "release.sh: render state is clean."

# ---------------------------------------------------------------------------
# Step 3: Stage
# ---------------------------------------------------------------------------

STAGE_DIR=".aid/.temp/release-${VERSION}"
rm -rf "${STAGE_DIR}"
mkdir -p "${STAGE_DIR}"
echo "release.sh: staging dir: ${STAGE_DIR}"

# ---------------------------------------------------------------------------
# Step 4: Package five per-profile tarballs
#
# Tool → profile dir map (fixed five entries; SPEC §S2.2):
#   claude-code  → profiles/claude-code   install roots: .claude/  + CLAUDE.md
#   codex        → profiles/codex         install roots: .agents/ + .codex/ + AGENTS.md
#   cursor       → profiles/cursor        install roots: .cursor/  + AGENTS.md
#   copilot-cli  → profiles/copilot-cli   install roots: .github/  + AGENTS.md
#   antigravity  → profiles/antigravity   install roots: .agent/   + AGENTS.md
#
# Rules:
#   - Flat root (no wrapping aid-<tool>/ dir)
#   - Exclude README.md and emission-manifest.jsonl
# ---------------------------------------------------------------------------

# Absolute path to the repo root (set once after repo-root check succeeds).
REPO_ROOT="$(pwd -P)"

# sha256sum utility — prefer sha256sum, fall back to shasum -a 256
sha256_cmd() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$@"
    elif command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$@"
    else
        die "No sha256 utility found (need sha256sum or shasum)." 1
    fi
}

# build_tarball <tool> <profile_dir> <roots...>
#   Creates ${STAGE_DIR}/aid-<tool>-v<VERSION>.tar.gz
#   flat-rooted, excluding README.md and emission-manifest.jsonl.
build_tarball() {
    local tool="$1"; shift
    local profile_dir="$1"; shift
    local roots=("$@")

    local abs_profile_dir="${REPO_ROOT}/${profile_dir}"
    local abs_tarball="${REPO_ROOT}/${STAGE_DIR}/aid-${tool}-v${VERSION}.tar.gz"
    echo "release.sh:   packaging ${STAGE_DIR}/aid-${tool}-v${VERSION}.tar.gz ..."

    # Build the file list: for each root, collect entries relative to profile_dir,
    # excluding README.md and emission-manifest.jsonl.
    # We use a temp file list so tar can accept it portably.
    local filelist
    filelist=$(mktemp)

    local root
    for root in "${roots[@]}"; do
        local src_path="${abs_profile_dir}/${root}"
        if [[ -f "$src_path" ]]; then
            # Root file (e.g. CLAUDE.md, AGENTS.md)
            local fname
            fname="$(basename "$src_path")"
            if [[ "$fname" == "README.md" || "$fname" == "emission-manifest.jsonl" ]]; then
                # Skip this file without touching the accumulated filelist.
                continue
            fi
            echo "./${root}" >> "$filelist"
        elif [[ -d "$src_path" ]]; then
            # Directory: collect all files recursively, sorted for determinism.
            # Use find -print0 then read with null delimiter for POSIX-safe filenames.
            # Sort with plain sort (null-safe via process substitution) — tr null→newline,
            # sort, then process each line. Filenames in this repo have no newlines.
            while IFS= read -r f; do
                local rel="${f#${abs_profile_dir}/}"
                local fname
                fname="$(basename "$f")"
                if [[ "$fname" == "README.md" || "$fname" == "emission-manifest.jsonl" ]]; then
                    continue
                fi
                echo "./${rel}" >> "$filelist"
            done < <(find "${src_path}" -type f -print0 | tr '\0' '\n' | sort)
        else
            rm -f "$filelist"
            die "Expected install root not found: ${src_path}" 1
        fi
    done

    # Create the tarball from the profile dir with the collected file list.
    # --no-recursion: do not auto-recurse into dirs (we already enumerated files).
    # -T: file list (POSIX-compatible; both GNU tar and BSD tar support -T).
    # We cd into abs_profile_dir so all paths are relative to the install root.
    (cd "${abs_profile_dir}" && tar -czf "${abs_tarball}" --no-recursion -T "${filelist}")

    rm -f "$filelist"
    echo "release.sh:   done: aid-${tool}-v${VERSION}.tar.gz"
}

echo "release.sh: packaging tarballs ..."

# claude-code: .claude/ + CLAUDE.md
build_tarball "claude-code" "profiles/claude-code" ".claude" "CLAUDE.md"

# codex: .agents/ + .codex/ + AGENTS.md
build_tarball "codex" "profiles/codex" ".agents" ".codex" "AGENTS.md"

# cursor: .cursor/ + AGENTS.md
build_tarball "cursor" "profiles/cursor" ".cursor" "AGENTS.md"

# copilot-cli: .github/ + AGENTS.md
build_tarball "copilot-cli" "profiles/copilot-cli" ".github" "AGENTS.md"

# antigravity: .agent/ + AGENTS.md
build_tarball "antigravity" "profiles/antigravity" ".agent" "AGENTS.md"

# ---------------------------------------------------------------------------
# Step 5: Emit SHA256SUMS
# ---------------------------------------------------------------------------

echo "release.sh: generating SHA256SUMS ..."

SUMS_FILE="${STAGE_DIR}/SHA256SUMS"

# Compute checksums for all five tarballs, sorted by filename.
# We cd into the staging dir so filenames in SHA256SUMS are bare (no path prefix).
# Use a glob array (not ls in command substitution) to avoid SC2046/SC2012.
(
    cd "${STAGE_DIR}"
    _tarballs=( aid-*.tar.gz )
    # Sort the glob results by name.
    IFS=$'\n' _sorted=( $(printf '%s\n' "${_tarballs[@]}" | sort) )
    unset IFS
    sha256_cmd "${_sorted[@]}"
) | sort -k2 > "${SUMS_FILE}"

echo "release.sh: SHA256SUMS written:"
cat "${SUMS_FILE}"

# ---------------------------------------------------------------------------
# Step 6: (--sign placeholder — deferred to feature-005)
# ---------------------------------------------------------------------------
# No-op in this feature; --sign exits early at argument-parse time.

# ---------------------------------------------------------------------------
# Dry-run stop
# ---------------------------------------------------------------------------

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo ""
    echo "release.sh: --dry-run: staging complete. Tarballs and SHA256SUMS are in:"
    echo "  ${STAGE_DIR}"
    echo ""
    ls -lh "${STAGE_DIR}"
    echo ""
    echo "release.sh: --dry-run: stopping before gh release create (no network I/O)."
    exit 0
fi

# ---------------------------------------------------------------------------
# Step 7: Create the GitHub Release
# ---------------------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    die "'gh' CLI not found. Install GitHub CLI to create the release, or use --dry-run." 1
fi

# Build the gh release create arguments.
GH_ARGS=("${TAG}" --title "AID v${VERSION}")

if [[ "$DRAFT" -eq 1 ]]; then
    GH_ARGS+=(--draft)
fi

if [[ -n "$NOTES_FILE" ]]; then
    GH_ARGS+=(--notes-file "${NOTES_FILE}")
else
    # Generate a minimal stub notes file.
    STUB_NOTES="${STAGE_DIR}/release-notes-stub.md"
    cat > "${STUB_NOTES}" <<EOF
## AID v${VERSION}

Five per-profile tarballs for the AID methodology installer.

Verify your download:
\`\`\`
sha256sum -c SHA256SUMS
\`\`\`
EOF
    GH_ARGS+=(--notes-file "${STUB_NOTES}")
fi

# Add assets: tarballs + SHA256SUMS
# Use a glob array (not ls in command substitution) to avoid SC2046/SC2012.
ASSETS=()
_gh_tarballs=( "${STAGE_DIR}"/aid-*.tar.gz )
IFS=$'\n' _gh_sorted=( $(printf '%s\n' "${_gh_tarballs[@]}" | sort) )
unset IFS
for _f in "${_gh_sorted[@]}"; do
    ASSETS+=("$_f")
done
ASSETS+=("${SUMS_FILE}")

echo "release.sh: creating GitHub Release ${TAG} ..."
gh release create "${GH_ARGS[@]}" "${ASSETS[@]}"

echo ""
echo "release.sh: Release ${TAG} created successfully."
echo "  Assets uploaded: ${#ASSETS[@]}"
