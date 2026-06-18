#!/usr/bin/env bash
# check-version-sync.sh — FR10 version-sync assertion.
#
# Verifies that all four version carriers agree on a single bare semver:
#   1. The VERSION file (repo source of truth)
#   2. packages/npm/package.json   ("version" field)
#   3. packages/pypi/pyproject.toml  ([project].version)
#   4. An optional expected version passed as --expect <VER> (e.g. from a git tag)
#
# When a manifest file is absent and its corresponding channel is not enabled
# (NPM_ENABLED / PYPI_ENABLED are not 'true'), that check is skipped with a notice.
# Once a manifest is present it is ALWAYS checked, regardless of enable flags.
#
# Usage:
#   bash check-version-sync.sh [--expect <version>] [--repo-root <path>]
#
#   --expect <version>   Assert all carriers match this bare semver (e.g. '0.7.5').
#                        If omitted, the carriers are asserted to be mutually consistent
#                        (all present carriers must equal the VERSION file value).
#   --repo-root <path>   Path to the repo root (default: directory of this script's
#                        grandparent, i.e. two levels above canonical/scripts/release/).
#                        Useful in tests with temp fixtures.
#
# Exit codes:
#   0   all checks pass (or gracefully skipped)
#   1   one or more version carriers diverge
#   2   usage error
#
# Environment (optional overrides for tests):
#   NPM_ENABLED    set to 'true' to enforce npm check even if package.json absent
#   PYPI_ENABLED   set to 'true' to enforce PyPI check even if pyproject.toml absent
#
# Output:
#   On mismatch: a ::error:: annotation line naming the diverging carrier + values.
#   On skip:     a notice line.
#   On pass:     a confirmation line per carrier checked.

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
EXPECT=""
REPO_ROOT=""

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --expect)
            [[ $# -ge 2 ]] || { echo "ERROR: --expect requires a value" >&2; exit 2; }
            EXPECT="$2"; shift 2 ;;
        --repo-root)
            [[ $# -ge 2 ]] || { echo "ERROR: --repo-root requires a value" >&2; exit 2; }
            REPO_ROOT="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'
            exit 0 ;;
        *)
            echo "ERROR: check-version-sync.sh: unknown flag: $1" >&2; exit 2 ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve repo root
# ---------------------------------------------------------------------------
if [[ -z "$REPO_ROOT" ]]; then
    # This script lives at canonical/scripts/release/check-version-sync.sh
    # -> grandparent of the script dir is the repo root.
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
fi

if [[ ! -f "${REPO_ROOT}/VERSION" ]]; then
    echo "ERROR: check-version-sync.sh: VERSION file not found under repo root: ${REPO_ROOT}" >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Read VERSION file
# ---------------------------------------------------------------------------
VERSION_FILE_VAL="$(tr -d '[:space:]' < "${REPO_ROOT}/VERSION")"

# ---------------------------------------------------------------------------
# Derive EXPECT: if not supplied, use the VERSION file value.
# ---------------------------------------------------------------------------
if [[ -z "$EXPECT" ]]; then
    EXPECT="${VERSION_FILE_VAL}"
fi

echo "check-version-sync: expected version = '${EXPECT}'"

# ---------------------------------------------------------------------------
# Assertion counter
# ---------------------------------------------------------------------------
fail=0
checked=0

# check_carrier <name> <actual>
# Emits a ::error:: annotation on mismatch (GitHub Actions compatible) and
# also a plain-text error so it's readable outside CI.
check_carrier() {
    local name="$1"
    local actual="$2"
    checked=$((checked + 1))
    if [[ "$actual" == "$EXPECT" ]]; then
        echo "  OK  : ${name} = '${actual}'"
    else
        echo "::error::${name} = '${actual}', expected '${EXPECT}' (from tag v${EXPECT})"
        echo "  FAIL: ${name} = '${actual}', expected '${EXPECT}'"
        fail=1
    fi
}

# ---------------------------------------------------------------------------
# 1. VERSION file
# ---------------------------------------------------------------------------
check_carrier "VERSION" "${VERSION_FILE_VAL}"

# ---------------------------------------------------------------------------
# 2. packages/npm/package.json
# ---------------------------------------------------------------------------
NPM_JSON="${REPO_ROOT}/packages/npm/package.json"
NPM_ENABLED="${NPM_ENABLED:-false}"

if [[ -f "${NPM_JSON}" ]]; then
    # File present: always check, regardless of NPM_ENABLED.
    if command -v node >/dev/null 2>&1; then
        NPM_VER="$(node -p "require('${NPM_JSON}').version" 2>/dev/null)"
    elif command -v python3 >/dev/null 2>&1; then
        NPM_VER="$(python3 -c "import json; print(json.load(open('${NPM_JSON}'))['version'])")"
    else
        echo "  WARN: neither node nor python3 available to read package.json — skipping npm check"
        NPM_VER=""
    fi
    if [[ -n "${NPM_VER}" ]]; then
        check_carrier "packages/npm/package.json" "${NPM_VER}"
    fi
elif [[ "${NPM_ENABLED}" == "true" ]]; then
    echo "::error::packages/npm/package.json not found but NPM_ENABLED=true"
    echo "  FAIL: packages/npm/package.json missing (NPM_ENABLED=true)"
    fail=1
else
    echo "  SKIP: packages/npm/package.json not found and NPM_ENABLED != true"
fi

# ---------------------------------------------------------------------------
# 3. packages/pypi/pyproject.toml
# ---------------------------------------------------------------------------
PYPI_TOML="${REPO_ROOT}/packages/pypi/pyproject.toml"
PYPI_ENABLED="${PYPI_ENABLED:-false}"

if [[ -f "${PYPI_TOML}" ]]; then
    # File present: always check, regardless of PYPI_ENABLED.
    PYPI_VER=""
    if python3 -c "import tomllib" 2>/dev/null; then
        PYPI_VER="$(python3 -c "import tomllib; d=tomllib.load(open('${PYPI_TOML}','rb')); print(d['project']['version'])")"
    elif python3 -c "import tomli" 2>/dev/null; then
        PYPI_VER="$(python3 -c "import tomli; d=tomli.load(open('${PYPI_TOML}','rb')); print(d['project']['version'])")"
    else
        # Fallback: grep + sed (handles standard single-quoted and double-quoted values)
        PYPI_VER="$(grep -E '^version\s*=' "${PYPI_TOML}" | head -1 | sed 's/.*=\s*["'"'"']\(.*\)["'"'"'].*/\1/')"
    fi
    if [[ -n "${PYPI_VER}" ]]; then
        check_carrier "packages/pypi/pyproject.toml" "${PYPI_VER}"
    else
        echo "  WARN: could not extract version from pyproject.toml — skipping PyPI check"
    fi
elif [[ "${PYPI_ENABLED}" == "true" ]]; then
    echo "::error::packages/pypi/pyproject.toml not found but PYPI_ENABLED=true"
    echo "  FAIL: packages/pypi/pyproject.toml missing (PYPI_ENABLED=true)"
    fail=1
else
    echo "  SKIP: packages/pypi/pyproject.toml not found and PYPI_ENABLED != true"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "check-version-sync: checked ${checked} carrier(s)."
if [[ "$fail" -ne 0 ]]; then
    echo "check-version-sync: VERSION SYNC FAILED — one or more carriers diverge from '${EXPECT}'."
    exit 1
fi
echo "check-version-sync: all carriers in sync at '${EXPECT}'."
exit 0
