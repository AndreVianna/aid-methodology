#!/usr/bin/env bash
# bundle.sh — focused release staging helper for canonical suites.
#
# Purpose: Stage release artifacts hermetically for tests.
# Usage: source tests/lib/bundle.sh; aid_test_stage_bundle <out-dir>
# Exit codes: release.sh status (0 success, non-zero failure).

_AID_TEST_BUNDLE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_AID_TEST_BUNDLE_REPO_ROOT="$(cd "${_AID_TEST_BUNDLE_LIB_DIR}/../.." && pwd)"

aid_test_stage_bundle() {
    if [[ $# -ne 1 ]]; then
        echo "usage: aid_test_stage_bundle <out-dir>" >&2
        return 2
    fi
    (cd "${_AID_TEST_BUNDLE_REPO_ROOT}" && bash ./release.sh --stage-only --out "$1")
}
