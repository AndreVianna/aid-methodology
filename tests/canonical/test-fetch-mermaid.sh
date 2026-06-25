#!/usr/bin/env bash
# test-fetch-mermaid.sh -- RETIRED (D-012 / Change 7 / FR-51).
#
# fetch-mermaid.sh was removed in D-012 because the Mermaid runtime engine is
# no longer used. Visuals are pre-rendered as inline SVG / HTML+CSS at build
# time. This test suite is retained as a no-op stub so test runners that
# enumerate tests/canonical/ do not break on a missing file.
#
# Usage:
#   tests/canonical/test-fetch-mermaid.sh [--verbose]
# Exit codes:
#   0 -- SKIP (always; the file under test was removed)

set -u

echo "SKIP: fetch-mermaid.sh was removed in D-012 (Change 7 / FR-51)."
echo "      The Mermaid runtime engine is retired; visuals are pre-rendered as"
echo "      inline SVG / HTML+CSS at build time. Nothing to test here."
exit 0
