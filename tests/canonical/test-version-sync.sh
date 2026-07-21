#!/usr/bin/env bash
# test-version-sync.sh — Unit tests for canonical/aid/scripts/release/check-version-sync.sh
# and structural validation of .github/workflows/release.yml.
#
# FR10 acceptance check: version-sync becomes a permanent CI invariant, running on
# every PR (via tests/run-all.sh → test.yml), not only at release time.
#
# Test cases:
#   VS01  All four carriers agree         → pass (exit 0)
#   VS02  package.json version differs    → fail (exit 1, names the carrier)
#   VS03  pyproject.toml version differs  → fail (exit 1, names the carrier)
#   VS04  Missing manifest, channel not
#         enabled                         → skip-with-notice (exit 0)
#   VS05  Tag v1.2.3 → EXPECT=1.2.3       → pass when carriers all = 1.2.3
#   VS06  VERSION file differs from --expect → fail
#   VS07  Missing manifest, channel
#         enabled (NPM_ENABLED=true)      → fail
#   VS08  real repo is in-sync at its declared VERSION   → pass
#   WF01  release.yml is valid YAML       → pass
#   WF02  release.yml has gate job        → pass
#   WF03  publish jobs need gate          → pass
#   WF04  permissions least-privilege     → pass
#   WF05  all actions are SHA-pinned      → pass (no moving-tag references)
#
# Uses temp fixtures (mktemp); does NOT mutate real files.
#
# Usage:
#   bash test-version-sync.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
SUT="${REPO_ROOT}/canonical/aid/scripts/release/check-version-sync.sh"
RELEASE_YML="${REPO_ROOT}/.github/workflows/release.yml"

[[ -f "$SUT" ]] || { echo "ERROR: check-version-sync.sh not found at $SUT" >&2; exit 1; }
[[ -f "$RELEASE_YML" ]] || { echo "ERROR: release.yml not found at $RELEASE_YML" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Fixture builder: make_fixture_root <dir> [npm_version] [pypi_version]
#   Creates a minimal fixture tree:
#     <dir>/VERSION            — always present, value = "1.2.3"
#     <dir>/packages/npm/package.json   — present when npm_version is non-empty
#     <dir>/packages/pypi/pyproject.toml — present when pypi_version is non-empty
# ---------------------------------------------------------------------------
make_fixture_root() {
    local root="$1"
    local npm_ver="${2:-}"
    local pypi_ver="${3:-}"
    local ver_val="${4:-1.2.3}"

    mkdir -p "${root}"
    printf '%s\n' "${ver_val}" > "${root}/VERSION"

    if [[ -n "${npm_ver}" ]]; then
        mkdir -p "${root}/packages/npm"
        cat > "${root}/packages/npm/package.json" <<EOF
{
  "name": "@aid/installer",
  "version": "${npm_ver}"
}
EOF
    fi

    if [[ -n "${pypi_ver}" ]]; then
        mkdir -p "${root}/packages/pypi"
        cat > "${root}/packages/pypi/pyproject.toml" <<EOF
[project]
name = "aid-installer"
version = "${pypi_ver}"
EOF
    fi
}

# run_check <fixture_root> [extra args...]
# Returns the exit code and stdout+stderr via OUT variable.
run_check() {
    local root="$1"; shift
    OUT="$(bash "${SUT}" --repo-root "${root}" "$@" 2>&1)"
    return $?
}

# ---------------------------------------------------------------------------
# VS01: All four carriers agree → exit 0
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs01"
make_fixture_root "${FIXTURE}" "1.2.3" "1.2.3"
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_zero "$RC" "VS01 all carriers agree → exit 0"
assert_output_contains "$OUT" "all carriers in sync" "VS01 output confirms in-sync"

# ---------------------------------------------------------------------------
# VS02: package.json version differs → exit 1, names the carrier
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs02"
make_fixture_root "${FIXTURE}" "9.9.9" "1.2.3"
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_nonzero "$RC" "VS02 package.json drift → exit 1"
assert_output_contains "$OUT" "package.json" "VS02 error names package.json carrier"
assert_output_contains "$OUT" "9.9.9" "VS02 error shows the actual drifted value"
assert_output_contains "$OUT" "1.2.3" "VS02 error shows the expected value"

# ---------------------------------------------------------------------------
# VS03: pyproject.toml version differs → exit 1, names the carrier
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs03"
make_fixture_root "${FIXTURE}" "1.2.3" "8.8.8"
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_nonzero "$RC" "VS03 pyproject.toml drift → exit 1"
assert_output_contains "$OUT" "pyproject.toml" "VS03 error names pyproject.toml carrier"
assert_output_contains "$OUT" "8.8.8" "VS03 error shows the actual drifted value"

# ---------------------------------------------------------------------------
# VS04: Missing manifest, channel NOT enabled → skip-with-notice, exit 0
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs04"
make_fixture_root "${FIXTURE}" "" ""   # no npm, no pypi manifests
OUT=""; RC=0
NPM_ENABLED=false PYPI_ENABLED=false run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_zero "$RC" "VS04 missing manifests + channels disabled → exit 0"
assert_output_contains "$OUT" "SKIP" "VS04 output includes SKIP notice for missing manifests"

# ---------------------------------------------------------------------------
# VS05: Tag v1.2.3 → EXPECT=1.2.3 (strip 'v' at caller), carriers all match
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs05"
make_fixture_root "${FIXTURE}" "1.2.3" "1.2.3"
# The workflow strips 'v' before calling the script; the script receives bare semver.
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_zero "$RC" "VS05 tag v1.2.3 → expect=1.2.3, all carriers match → exit 0"
assert_output_contains "$OUT" "1.2.3" "VS05 output shows expected version"

# ---------------------------------------------------------------------------
# VS06: VERSION file differs from --expect → exit 1
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs06"
make_fixture_root "${FIXTURE}" "" "" "2.0.0"   # VERSION=2.0.0
OUT=""; RC=0
NPM_ENABLED=false PYPI_ENABLED=false run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_nonzero "$RC" "VS06 VERSION file differs from --expect → exit 1"
assert_output_contains "$OUT" "VERSION" "VS06 error names VERSION carrier"
assert_output_contains "$OUT" "2.0.0" "VS06 error shows actual VERSION value"
assert_output_contains "$OUT" "1.2.3" "VS06 error shows expected value"

# ---------------------------------------------------------------------------
# VS07: Missing manifest but channel is enabled → exit 1
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs07"
make_fixture_root "${FIXTURE}" "" ""   # no package.json
OUT=""; RC=0
NPM_ENABLED=true run_check "${FIXTURE}" --expect "1.2.3" || RC=$?
assert_exit_nonzero "$RC" "VS07 NPM_ENABLED=true but package.json absent → exit 1"
assert_output_contains "$OUT" "package.json" "VS07 error mentions package.json"

# ---------------------------------------------------------------------------
# VS08: Real repo is in-sync at its declared VERSION (read dynamically so the
# test does not need editing on every version bump / release).
# ---------------------------------------------------------------------------
OUT=""; RC=0
REPO_VER="$(tr -d ' \t\r\n' < "${REPO_ROOT}/VERSION")"
bash "${SUT}" --repo-root "${REPO_ROOT}" --expect "${REPO_VER}" > "${TMP}/vs08_out.txt" 2>&1 || RC=$?
OUT="$(cat "${TMP}/vs08_out.txt")"
assert_exit_zero "$RC" "VS08 real repo is in-sync at its VERSION (${REPO_VER}) → exit 0"
assert_output_contains "$OUT" "all carriers in sync" "VS08 real repo output confirms in-sync"

# ---------------------------------------------------------------------------
# VS08b  Self-derived repo root (NO --repo-root) — the EXACT release.yml gate path.
# Regression guard: the gate calls the script WITHOUT --repo-root, so it must resolve
# the repo root from its own location. A fixed `../../..` depth silently broke this
# when the scripts moved canonical/scripts/ → canonical/aid/scripts/ (it landed on
# canonical/ and failed "VERSION not found"), yet every fixture case above passed
# because they all pass --repo-root. This case invokes the bare CI path.
# ---------------------------------------------------------------------------
OUT=""; RC=0
( cd "${REPO_ROOT}" && bash "canonical/aid/scripts/release/check-version-sync.sh" --expect "${REPO_VER}" ) > "${TMP}/vs08b_out.txt" 2>&1 || RC=$?
OUT="$(cat "${TMP}/vs08b_out.txt")"
assert_exit_zero "$RC" "VS08b self-derived repo root (no --repo-root, CI gate path) → exit 0"
assert_output_contains "$OUT" "all carriers in sync" "VS08b CI-path invocation finds VERSION and passes"

# ---------------------------------------------------------------------------
# WF01: release.yml is valid YAML
# ---------------------------------------------------------------------------
# Requires python3 AND the PyYAML module. A clean setup-python (e.g. the release.yml
# gate runner) has no PyYAML, so skip rather than fail there; test.yml validates the
# YAML on the runner's system python, and GitHub itself rejects an invalid workflow.
if command -v python3 >/dev/null 2>&1 && python3 -c "import yaml" >/dev/null 2>&1; then
    WF_PARSE_OUT="$(python3 -c "import yaml,sys; yaml.safe_load(open('${RELEASE_YML}')); print('OK')" 2>&1)"
    WF_PARSE_RC=$?
    assert_exit_zero "$WF_PARSE_RC" "WF01 release.yml is valid YAML"
    assert_output_contains "$WF_PARSE_OUT" "OK" "WF01 yaml.safe_load returns without error"
else
    echo "  SKIP: python3 or PyYAML not available — skipping WF01 YAML validation"
fi

# ---------------------------------------------------------------------------
# WF02: release.yml has a gate job
# ---------------------------------------------------------------------------
WF_CONTENT="$(cat "${RELEASE_YML}")"
assert_output_contains "$WF_CONTENT" "gate:" "WF02 release.yml has a gate job"

# ---------------------------------------------------------------------------
# WF03: publish jobs declare needs: gate
# Verify each publish job section contains 'needs:' that references 'gate'.
# ---------------------------------------------------------------------------
# github-release needs gate
assert_output_contains "$WF_CONTENT" "needs: [gate]" "WF03a github-release needs gate"
# npm-publish needs gate (and github-release)
assert_output_contains "$WF_CONTENT" "needs: [gate, github-release]" "WF03b npm-publish needs gate"
# pypi-publish needs gate (and github-release)
# pypi-publish uses the same needs, tested via structural check below
if grep -q "pypi-publish:" "${RELEASE_YML}" && grep -A5 "pypi-publish:" "${RELEASE_YML}" | grep -q "needs:"; then
    pass "WF03c pypi-publish has a needs: block"
else
    fail "WF03c pypi-publish does not declare needs:"
fi

# ---------------------------------------------------------------------------
# WF04: permissions block is least-privilege
#   Must have contents: write and id-token: write; must NOT have
#   packages: write or pull-requests: write.
# ---------------------------------------------------------------------------
assert_output_contains "$WF_CONTENT" "contents: write" "WF04 permissions contains contents: write"
assert_output_contains "$WF_CONTENT" "id-token: write" "WF04 permissions contains id-token: write"
assert_output_not_contains "$WF_CONTENT" "packages: write" "WF04 permissions does not grant packages: write"
assert_output_not_contains "$WF_CONTENT" "pull-requests: write" "WF04 permissions does not grant pull-requests: write"

# ---------------------------------------------------------------------------
# WF05: all `uses:` lines are SHA-pinned (no moving tags like @v1, @main, @master,
# @release/v1, @latest).
# A valid pinned line looks like: uses: owner/repo@<40-hex-chars>  # vX.Y.Z
# We reject any uses: line that ends in @<non-hex-segment> (e.g. @v1, @v2.1, @main).
# ---------------------------------------------------------------------------
UNPINNED_USES="$(grep -n 'uses:' "${RELEASE_YML}" | grep -vE 'uses:.*@[0-9a-f]{40}' || true)"
if [[ -z "${UNPINNED_USES}" ]]; then
    pass "WF05 all uses: lines are SHA-pinned"
else
    fail "WF05 found unpinned uses: lines in release.yml:
${UNPINNED_USES}"
fi

# ---------------------------------------------------------------------------
# VS09  Shipped READMEs carry NO hardcoded release version (regression guard).
#   Version strings baked into README badges / prose / download URLs go stale on
#   every release and are NOT covered by check-version-sync.sh (it only checks
#   VERSION + package.json + pyproject + tag). v1.1.0/v1.1.1 shipped a stale
#   "Current release: v1.1.0" line on the npm page AND a root-README offline-install
#   example pointing at the (later broken) v1.1.0 download. The READMEs are now
#   de-versioned (dynamic shields.io github/v/release badge, latest-tag resolution,
#   no "Current release: vX"); this guard fails if a hardcoded version is reintroduced.
#   Forbidden: "Current release: vX.Y.Z" | releases/download/vX.Y.Z/ | badge/version-X.Y.Z
#   (Historical headings like "What's New in v1.1.0" are intentionally NOT matched.)
# ---------------------------------------------------------------------------
VS09_HITS=""
for _rdme in "${REPO_ROOT}/README.md" "${REPO_ROOT}/packages/npm/README.md" "${REPO_ROOT}/packages/pypi/README.md"; do
    [[ -f "$_rdme" ]] || continue
    _h="$(grep -nE 'Current release:.*v[0-9]+\.[0-9]+\.[0-9]+|releases/download/v[0-9]+\.[0-9]+\.[0-9]+/|badge/version-[0-9]+\.[0-9]+\.[0-9]+' "$_rdme" 2>/dev/null || true)"
    [[ -n "$_h" ]] && VS09_HITS+="${_rdme}:"$'\n'"${_h}"$'\n'
done
if [[ -z "${VS09_HITS}" ]]; then
    pass "VS09 shipped READMEs carry no hardcoded release version (de-versioned)"
else
    fail "VS09 hardcoded version string(s) in shipped README(s) -- de-version (dynamic badge / latest-tag / drop 'Current release: vX'):
${VS09_HITS}"
fi

# ---------------------------------------------------------------------------
# VS10  Pre-release (PyPI-only beta): npm carrier is EXEMPT.
#   A beta bumps only VERSION + pyproject.toml + the tag; package.json legitimately
#   stays on the last stable. check-version-sync must PASS: VERSION == pyproject ==
#   expect, npm exempt (not required to equal expect). Betas publish to PyPI only.
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs10"
make_fixture_root "${FIXTURE}" "1.2.2" "1.2.3b1" "1.2.3b1"   # npm=stale stable, pypi=VERSION=1.2.3b1
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3b1" || RC=$?
assert_exit_zero "$RC" "VS10 pre-release 1.2.3b1: PASS with stale npm (npm carrier exempt)"
assert_output_contains "$OUT" "PRE-RELEASE" "VS10 output flags the pre-release"
assert_output_contains "$OUT" "exempt" "VS10 output notes npm carrier exempt"

# ---------------------------------------------------------------------------
# VS11  Pre-release still ENFORCES the PyPI (pyproject) carrier — betas DO ship to
#   PyPI, so a stale pyproject must FAIL even though npm is exempt.
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs11"
make_fixture_root "${FIXTURE}" "1.2.2" "1.2.2" "1.2.3b1"   # VERSION=1.2.3b1 but pyproject stale 1.2.2
OUT=""; RC=0
run_check "${FIXTURE}" --expect "1.2.3b1" || RC=$?
assert_exit_nonzero "$RC" "VS11 pre-release with stale pyproject → FAIL (PyPI carrier still enforced)"
assert_output_contains "$OUT" "pyproject.toml" "VS11 error names the pyproject carrier"

# ---------------------------------------------------------------------------
# VS12  SemVer-form pre-release (2.2.3-beta.1) is also detected as a pre-release.
# ---------------------------------------------------------------------------
FIXTURE="${TMP}/vs12"
make_fixture_root "${FIXTURE}" "" "1.2.3-beta.1" "1.2.3-beta.1"   # no npm manifest; pypi=VERSION
OUT=""; RC=0
NPM_ENABLED=false run_check "${FIXTURE}" --expect "1.2.3-beta.1" || RC=$?
assert_exit_zero "$RC" "VS12 SemVer-form pre-release 1.2.3-beta.1 → PASS"
assert_output_contains "$OUT" "PRE-RELEASE" "VS12 SemVer-form flagged as pre-release"

# ---------------------------------------------------------------------------
# WF06  release.yml wires the CLI+skills pre-release (beta) path:
#   - the gate job exposes an `is_prerelease` output,
#   - github-release RUNS on a pre-release, marking the Release --prerelease
#     (it carries the beta skill tarballs; excluded from /releases/latest),
#   - npm-publish is skipped on a pre-release (npm ships no betas),
#   - pypi-publish runs (the CLI beta).
# ---------------------------------------------------------------------------
assert_output_contains "$WF_CONTENT" "is_prerelease:" "WF06a release.yml gate exposes is_prerelease output"
assert_output_contains "$WF_CONTENT" "--prerelease" "WF06b github-release marks the Release --prerelease on a pre-release (beta skills)"
assert_output_contains "$WF_CONTENT" "needs.gate.outputs.is_prerelease != 'true'" "WF06c npm-publish skips on a pre-release"
assert_output_contains "$WF_CONTENT" "!cancelled()" "WF06d pypi-publish runs (CLI beta) regardless of github-release skip state"

test_summary
