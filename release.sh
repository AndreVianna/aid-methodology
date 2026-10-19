#!/usr/bin/env bash
# release.sh — Package the shared payload, five tool artifacts, and CLI bundle.
#
# Purpose:
#   Maintainer-only helper that stages one byte-verbatim shared payload, five
#   descriptor-plus-agents tool artifacts, the CLI bundle, and SHA256SUMS.
#   Normal release mode verifies a clean rendered state before publishing via gh.
#
# Usage:
#   bash release.sh [--version X.Y.Z] [--sign] [--draft] [--prerelease]
#                   [--dry-run | --stage-only [--out DIR]] [--notes-file FILE] [-h|--help]
#
#   --version X.Y.Z   Release version (default: content of VERSION file). Must
#                     match the VERSION file; FAIL on mismatch.
#   --sign            Also emit a detached signature over SHA256SUMS (deferred
#                     to feature-005; exits non-zero if --sign is passed until
#                     the signing approach is settled).
#   --draft           Create the GitHub Release as a draft (default: published).
#   --prerelease      Mark the GitHub Release as a pre-release (beta): it carries
#                     the beta skill tarballs but is excluded from /releases/latest,
#                     so a normal `aid update` still resolves the stable release.
#   --dry-run         Assemble artifacts + SHA256SUMS then stop before
#                     `gh release create`. No network I/O; keeps normal preconditions.
#   --stage-only      Stage against the working tree without clean-tree, tag,
#                     render, render-drift, or network checks.
#   --out DIR         Staging directory for --stage-only (default:
#                     .aid/.temp/release-<VERSION>).
#   --notes-file FILE Release notes body for `gh release create`.
#   -h|--help         Print this help and exit 0.
#
# Exit codes:
#   0   success (dry-run: staging complete; live: release created)
#   1   general failure (precondition, render-drift, gh error, etc.)
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
STAGE_ONLY=0
OUT_DIR=""
PRERELEASE=0
NOTES_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version)    VERSION_ARG="$2"; shift 2 ;;
        --sign)       SIGN=1; shift ;;
        --draft)      DRAFT=1; shift ;;
        --prerelease) PRERELEASE=1; shift ;;
        --dry-run)    DRY_RUN=1; shift ;;
        --stage-only) STAGE_ONLY=1; shift ;;
        --out)        OUT_DIR="$2"; shift 2 ;;
        --notes-file) NOTES_FILE="$2"; shift 2 ;;
        -h|--help)    usage; exit 0 ;;
        *)            die "unknown flag: $1" 2 ;;
    esac
done

if [[ -n "$OUT_DIR" && "$STAGE_ONLY" -ne 1 ]]; then
    die "--out requires --stage-only." 2
fi

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
if [[ "$STAGE_ONLY" -eq 0 ]]; then
    if ! git diff --quiet; then
        die "Working tree has uncommitted changes. Commit or stash them before releasing." 1
    fi
    if ! git diff --cached --quiet; then
        die "Index has staged changes. Commit or stash them before releasing." 1
    fi
fi

# Assert the git tag does not already exist at a CONFLICTING commit.
# --dry-run only stages artifacts (it never creates a tag or Release), so skip this.
# The CD is tag-triggered: the release tag is pushed first and legitimately points at
# HEAD, so allow that case; die only on a genuine conflict (tag at a different commit).
# A duplicate already-published Release is caught by the gh check below.
if [[ "$STAGE_ONLY" -eq 0 && "$DRY_RUN" -eq 0 ]] && git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null 2>&1; then
    if [[ "$(git rev-list -n 1 "${TAG}")" != "$(git rev-parse HEAD)" ]]; then
        die "Git tag ${TAG} already exists at a different commit. Delete it or choose a different version." 4
    fi
fi

# A pre-existing GitHub Release for this tag is NOT fatal. The tag-triggered CD may
# re-run after a PARTIAL publish (e.g. github-release succeeded but npm/PyPI failed on
# a transient error); since npm-publish/pypi-publish depend on github-release, dying
# here would strand the release with no way to finish via a re-run. Instead we RECORD
# that it exists and refresh the assets idempotently in Step 8, so the dependent jobs
# can complete. The genuine-conflict case (tag at a DIFFERENT commit) is already caught
# above; a same-commit re-run is a safe, idempotent recovery.
RELEASE_EXISTS=0
if [[ "$STAGE_ONLY" -eq 0 && "$DRY_RUN" -eq 0 ]] && command -v gh >/dev/null 2>&1; then
    if gh release view "${TAG}" >/dev/null 2>&1; then
        RELEASE_EXISTS=1
        echo "release.sh: GitHub Release ${TAG} already exists -- recovery re-run; assets will be refreshed (--clobber)." >&2
    fi
fi

# ---------------------------------------------------------------------------
# Step 2: Verify clean rendered state (render-drift gate — reused from CI)
# ---------------------------------------------------------------------------

if [[ "$STAGE_ONLY" -eq 0 && -z "$PYTHON_CMD" ]]; then
    die "Python not found. Install Python 3.11+ and ensure 'python' or 'python3' is on PATH." 1
fi

if [[ "$STAGE_ONLY" -eq 0 ]]; then
    echo "release.sh: verifying render state (${PYTHON_CMD} .claude/skills/generate-profile/scripts/run_generator.py) ..."
    if ! "${PYTHON_CMD}" .claude/skills/generate-profile/scripts/run_generator.py; then
        echo "ERROR: release.sh: run_generator.py failed." >&2
        echo "profiles/ is out of sync with canonical/. Run 'python .claude/skills/generate-profile/scripts/run_generator.py' and commit the result." >&2
        exit 1
    fi

    echo "release.sh: checking for render drift (git diff -- profiles/) ..."
    # Ignore exec-bit changes, which differ across developer and CI checkouts.
    if ! git -c core.fileMode=false diff --exit-code -- profiles/ >/dev/null 2>&1; then
        echo "ERROR: release.sh: profiles/ differs from HEAD after running run_generator.py." >&2
        echo "profiles/ is out of sync with canonical/. Run 'python .claude/skills/generate-profile/scripts/run_generator.py' and commit the result." >&2
        exit 1
    fi

    echo "release.sh: render state is clean."
fi

# ---------------------------------------------------------------------------
# Step 2b: Release checks (live publish only; --dry-run and --stage-only skip them)
#
# Each suite runs with AID_RELEASE_CHECK=1, which turns on its release assertion:
# the deferred-tests list must be empty (DT-02), and so must the shared skill-steps
# exempt list and the SG-04 description exempt list. A non-empty list stops the
# release before anything is staged.
# ---------------------------------------------------------------------------

if [[ "$STAGE_ONLY" -eq 0 && "$DRY_RUN" -eq 0 ]]; then
    echo "release.sh: running the release checks (AID_RELEASE_CHECK=1) ..."
    for _release_check in test-deferred-tests test-skill-steps test-skill-guide; do
        if ! AID_RELEASE_CHECK=1 bash "tests/canonical/${_release_check}.sh" </dev/null; then
            die "release check ${_release_check} failed; nothing was staged." 1
        fi
    done
    echo "release.sh: release checks passed."
fi

# ---------------------------------------------------------------------------
# Step 3: Stage
# ---------------------------------------------------------------------------

STAGE_DIR="${OUT_DIR:-.aid/.temp/release-${VERSION}}"
REPO_ROOT="$(pwd -P)"
if [[ "${STAGE_DIR}" != /* ]]; then
    STAGE_DIR="${REPO_ROOT}/${STAGE_DIR}"
fi
if [[ -n "${OUT_DIR}" ]]; then
    mkdir -p "${STAGE_DIR}"
    if find "${STAGE_DIR}" -mindepth 1 -maxdepth 1 -print -quit | grep -q .; then
        die "--out directory must be empty: ${STAGE_DIR}" 2
    fi
else
    rm -rf "${STAGE_DIR}"
    mkdir -p "${STAGE_DIR}"
fi
echo "release.sh: staging dir: ${STAGE_DIR}"

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

# build_shared_payload — copy canonical files byte-for-byte, applying the
# explicit release exclusions, then archive at the required payload roots.
build_shared_payload() {
    local tmp="${STAGE_DIR}/.shared-payload-tmp"
    local source rel destination file target
    mkdir -p "${tmp}/skills" "${tmp}/runtime"
    printf 'aid_version=%s\n' "${VERSION}" > "${tmp}/aid-payload.conf"

    for source in canonical/skills canonical/aid; do
        local target="skills"
        [[ "$source" == "canonical/aid" ]] && target="runtime"
        while IFS= read -r -d '' file; do
            rel="${file#${REPO_ROOT}/${source}/}"
            destination="${tmp}/${target}/${rel}"
            mkdir -p "$(dirname "${destination}")"
            cp "${file}" "${destination}"
        done < <(find "${REPO_ROOT}/${source}" \
            \( -type d \( -name node_modules -o -name .git -o -name '.*' \) -prune \) -o \
            \( -type f ! -name '.*' -print0 \))
    done

    tar -czf "${STAGE_DIR}/aid-shared-v${VERSION}.tar.gz" \
        -C "${tmp}" aid-payload.conf skills runtime
    rm -rf "${tmp}"
    echo "release.sh:   done: aid-shared-v${VERSION}.tar.gz"
}

# build_tool_artifact <tool> <profile-root>
#   Archives exactly aid-tool.conf and the rendered agents below the tool root.
build_tool_artifact() {
    local tool="$1"
    local root="$2"
    local profile="${REPO_ROOT}/profiles/${tool}"
    local tmp="${STAGE_DIR}/.${tool}-artifact-tmp"
    local agents="${profile}/${root}/agents"
    local tarball="${STAGE_DIR}/aid-${tool}-v${VERSION}.tar.gz"
    local file rel

    [[ -f "${profile}/aid-tool.conf" ]] || die "Expected tool descriptor not found: ${profile}/aid-tool.conf" 1
    [[ -d "${agents}" ]] || die "Expected agents directory not found: ${agents}" 1
    mkdir -p "${tmp}/${root}/agents"
    cp "${profile}/aid-tool.conf" "${tmp}/aid-tool.conf"
    while IFS= read -r -d '' file; do
        rel="${file#${agents}/}"
        mkdir -p "${tmp}/${root}/agents/$(dirname "${rel}")"
        cp "${file}" "${tmp}/${root}/agents/${rel}"
    done < <(find "${agents}" -type f -print0)

    tar -czf "${tarball}" -C "${tmp}" aid-tool.conf "${root}/agents"
    rm -rf "${tmp}"
    echo "release.sh:   done: aid-${tool}-v${VERSION}.tar.gz"
}

echo "release.sh: packaging shared payload and tool artifacts ..."
build_shared_payload
build_tool_artifact "claude-code" ".claude"
build_tool_artifact "codex" ".codex"
build_tool_artifact "cursor" ".cursor"
build_tool_artifact "copilot-cli" ".github"
build_tool_artifact "antigravity" ".agent"

# ---------------------------------------------------------------------------
# Step 5: Build the CLI bundle tarball
#
# aid-cli-v<VERSION>.tar.gz — extraction root IS the $AID_HOME layout:
#   bin/aid, bin/aid.ps1, bin/aid.cmd,
#   lib/aid-install-core.sh, lib/AidInstallCore.psm1,
#   VERSION
#
# The piped-bootstrap (curl|bash / irm|iex) fetches this bundle when the
# local bin/aid is absent, verifies it against SHA256SUMS, extracts to a
# temp dir, and installs into $AID_HOME.
# ---------------------------------------------------------------------------

echo "release.sh: building CLI bundle (aid-cli-v${VERSION}.tar.gz) ..."

CLI_BUNDLE_STAGE="${STAGE_DIR}/.cli-bundle-tmp"
mkdir -p "${CLI_BUNDLE_STAGE}/bin" "${CLI_BUNDLE_STAGE}/lib" \
         "${CLI_BUNDLE_STAGE}/dashboard" \
         "${CLI_BUNDLE_STAGE}/chat-node"

cp "${REPO_ROOT}/bin/aid"              "${CLI_BUNDLE_STAGE}/bin/aid"
cp "${REPO_ROOT}/bin/aid.ps1"          "${CLI_BUNDLE_STAGE}/bin/aid.ps1"
cp "${REPO_ROOT}/bin/aid.cmd"          "${CLI_BUNDLE_STAGE}/bin/aid.cmd"
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${CLI_BUNDLE_STAGE}/lib/aid-install-core.sh"
cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${CLI_BUNDLE_STAGE}/lib/AidInstallCore.psm1"
printf '%s\n' "${VERSION}" > "${CLI_BUNDLE_STAGE}/VERSION"

# Dashboard server+reader unit -- derived from the single-source manifest
# dashboard/MANIFEST (shared with install.sh, install.ps1, vendor.js and vendor.py;
# guarded by tests/canonical/test-dashboard-manifest.sh). MANIFEST is itself bundled so
# the piped-bootstrap installer reads its file set from the fetched, checksum-verified
# tarball. Deriving from the one manifest keeps every channel in lockstep, so no source
# file (e.g. home.html, io_bounds.py) is ever silently dropped from one channel -- the
# historical H1 failure mode.
_DASH_MANIFEST="${REPO_ROOT}/dashboard/MANIFEST"
_DASH_FILES=()
while IFS= read -r _mline || [[ -n "$_mline" ]]; do
    _mline="${_mline%%#*}"
    _mline="${_mline#"${_mline%%[![:space:]]*}"}"
    _mline="${_mline%"${_mline##*[![:space:]]}"}"
    [[ -n "$_mline" ]] && _DASH_FILES+=("$_mline")
done < "$_DASH_MANIFEST"
cp "${_DASH_MANIFEST}" "${CLI_BUNDLE_STAGE}/dashboard/MANIFEST"
for _df in "${_DASH_FILES[@]}"; do
    mkdir -p "$(dirname "${CLI_BUNDLE_STAGE}/dashboard/${_df}")"
    cp "${REPO_ROOT}/dashboard/${_df}" "${CLI_BUNDLE_STAGE}/dashboard/${_df}"
done

# Agent chat node -- derived from the single-source manifest chat-node/MANIFEST (shared with
# install.sh, install.ps1, vendor.js and vendor.py; guarded by
# tests/canonical/test-chat-node-manifest.sh), on the same terms and for the same reason as
# the dashboard block above. MANIFEST is itself bundled so the piped-bootstrap installer
# reads its file set from the fetched, checksum-verified tarball.
_NODE_MANIFEST="${REPO_ROOT}/chat-node/MANIFEST"
_NODE_FILES=()
while IFS= read -r _mline || [[ -n "$_mline" ]]; do
    _mline="${_mline%%#*}"
    _mline="${_mline#"${_mline%%[![:space:]]*}"}"
    _mline="${_mline%"${_mline##*[![:space:]]}"}"
    [[ -n "$_mline" ]] && _NODE_FILES+=("$_mline")
done < "$_NODE_MANIFEST"
cp "${_NODE_MANIFEST}" "${CLI_BUNDLE_STAGE}/chat-node/MANIFEST"
for _nf in "${_NODE_FILES[@]}"; do
    mkdir -p "$(dirname "${CLI_BUNDLE_STAGE}/chat-node/${_nf}")"
    cp "${REPO_ROOT}/chat-node/${_nf}" "${CLI_BUNDLE_STAGE}/chat-node/${_nf}"
done

CLI_BUNDLE="${STAGE_DIR}/aid-cli-v${VERSION}.tar.gz"

# Build deterministically from cli-bundle-tmp/: flat layout (no wrapping dir prefix).
(
    cd "${CLI_BUNDLE_STAGE}"
    _cli_fl=$(mktemp)
    {
        printf '%s\n' \
            "./bin/aid" \
            "./bin/aid.ps1" \
            "./bin/aid.cmd" \
            "./lib/aid-install-core.sh" \
            "./lib/AidInstallCore.psm1" \
            "./VERSION" \
            "./dashboard/MANIFEST" \
            "./chat-node/MANIFEST"
        for _df in "${_DASH_FILES[@]}"; do
            printf './dashboard/%s\n' "$_df"
        done
        # The node's files must be in the TAR LIST, not merely staged: staging without
        # listing produced a bundle that omitted the component entirely while every
        # manifest-reading check still passed.
        for _nf in "${_NODE_FILES[@]}"; do
            printf './chat-node/%s\n' "$_nf"
        done
    } > "$_cli_fl"
    tar -czf "${CLI_BUNDLE}" --no-recursion -T "$_cli_fl"
    rm -f "$_cli_fl"
)

rm -rf "${CLI_BUNDLE_STAGE}"
echo "release.sh:   done: aid-cli-v${VERSION}.tar.gz"

# ---------------------------------------------------------------------------
# Step 6: Emit SHA256SUMS
# ---------------------------------------------------------------------------

echo "release.sh: copying installer libs into staging dir ..."

# Copy the two lib files into the staging directory so they become release assets
# and their checksums can be included in SHA256SUMS.  The bootstrap installers
# (install.sh / install.ps1) fetch these libs from the pinned release tag and
# verify them against this SHA256SUMS before sourcing/importing.
cp "${REPO_ROOT}/lib/aid-install-core.sh" "${STAGE_DIR}/aid-install-core.sh"
cp "${REPO_ROOT}/lib/AidInstallCore.psm1" "${STAGE_DIR}/AidInstallCore.psm1"

echo "release.sh: generating SHA256SUMS ..."

SUMS_FILE="${STAGE_DIR}/SHA256SUMS"

# Compute checksums for all seven tarballs (shared + 5 tools + CLI bundle) + the two
# lib files, sorted by filename.
# We cd into the staging dir so filenames in SHA256SUMS are bare (no path prefix).
# Use a glob array (not ls in command substitution) to avoid SC2046/SC2012.
(
    cd "${STAGE_DIR}"
    _tarballs=( aid-*.tar.gz )
    # Sort the glob results by name.
    IFS=$'\n' _sorted=( $(printf '%s\n' "${_tarballs[@]}" | sort) )
    unset IFS
    sha256_cmd "${_sorted[@]}" aid-install-core.sh AidInstallCore.psm1
) | sort -k2 > "${SUMS_FILE}"

echo "release.sh: SHA256SUMS written:"
cat "${SUMS_FILE}"

STUB_NOTES="${STAGE_DIR}/release-notes-stub.md"
cat > "${STUB_NOTES}" <<EOF
## AID v${VERSION}

One shared payload, five agents-only tool artifacts, and the CLI bundle for the AID methodology installer.

v4 requires CLI v4

Verify your download:
\`\`\`
sha256sum -c SHA256SUMS
\`\`\`
EOF

# ---------------------------------------------------------------------------
# Step 7: (--sign placeholder — deferred to feature-005)
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

if [[ "$STAGE_ONLY" -eq 1 ]]; then
    echo ""
    echo "release.sh: --stage-only: artifacts and SHA256SUMS are in:"
    echo "  ${STAGE_DIR}"
    exit 0
fi

# ---------------------------------------------------------------------------
# Step 8: Create the GitHub Release
# ---------------------------------------------------------------------------

if ! command -v gh >/dev/null 2>&1; then
    die "'gh' CLI not found. Install GitHub CLI to create the release, or use --dry-run." 1
fi

# Build the gh release create arguments.
GH_ARGS=("${TAG}" --title "AID v${VERSION}")

if [[ "$DRAFT" -eq 1 ]]; then
    GH_ARGS+=(--draft)
fi

# --prerelease marks the GitHub Release as a pre-release: it carries the beta
# shared payload and tool artifacts for testers but is EXCLUDED from `/releases/latest`, so a normal
# `aid update` (which resolves latest) still gets the stable release. Testers opt
# in with `aid update --version <X.Y.Zb1>` or `aid update --pre`.
if [[ "$PRERELEASE" -eq 1 ]]; then
    GH_ARGS+=(--prerelease)
fi

if [[ -n "$NOTES_FILE" ]]; then
    GH_ARGS+=(--notes-file "${NOTES_FILE}")
else
    # Use the staged release-notes stub unless the maintainer supplied full notes.
    GH_ARGS+=(--notes-file "${STUB_NOTES}")
fi

# Add assets: every aid-*.tar.gz in the stage dir (the shared payload, one agents-only
# artifact per tool, and the CLI bundle) + lib files + SHA256SUMS
# Use a glob array (not ls in command substitution) to avoid SC2046/SC2012.
ASSETS=()
_gh_tarballs=( "${STAGE_DIR}"/aid-*.tar.gz )
IFS=$'\n' _gh_sorted=( $(printf '%s\n' "${_gh_tarballs[@]}" | sort) )
unset IFS
for _f in "${_gh_sorted[@]}"; do
    ASSETS+=("$_f")
done
ASSETS+=("${STAGE_DIR}/aid-install-core.sh")
ASSETS+=("${STAGE_DIR}/AidInstallCore.psm1")
ASSETS+=("${SUMS_FILE}")

if [[ "$RELEASE_EXISTS" -eq 1 ]]; then
    # Idempotent recovery path: the Release already exists (re-run after a partial
    # publish). Refresh its assets with --clobber instead of failing, so the dependent
    # npm-publish / pypi-publish jobs run on the re-run and the npm idempotency guard
    # can take over. Existing notes/title are left untouched.
    echo "release.sh: GitHub Release ${TAG} exists -- uploading/refreshing assets (--clobber) ..."
    gh release upload "${TAG}" "${ASSETS[@]}" --clobber
    echo ""
    echo "release.sh: Release ${TAG} assets refreshed (idempotent recovery re-run)."
    echo "  Assets uploaded: ${#ASSETS[@]}"
else
    echo "release.sh: creating GitHub Release ${TAG} ..."
    gh release create "${GH_ARGS[@]}" "${ASSETS[@]}"
    echo ""
    echo "release.sh: Release ${TAG} created successfully."
    echo "  Assets uploaded: ${#ASSETS[@]}"
fi
