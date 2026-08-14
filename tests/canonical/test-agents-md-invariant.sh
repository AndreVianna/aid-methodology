#!/usr/bin/env bash
# test-agents-md-invariant.sh — FR12 guard: root AGENTS.md must be byte-identical
# across codex, cursor, copilot-cli, and antigravity profiles.
#
# Rationale: when an adopter installs two of these tools into the same repo, both
# installers write AGENTS.md to the project root.  If the files differ, the
# second install triggers a false-positive protect-on-diff warning (FR11).
# Making the content byte-identical eliminates that collision.
#
# This guard fails if any maintainer re-introduces a tool-specific token into one
# of the four hand-maintained root AGENTS.md files.
#
# Usage:
#   bash test-agents-md-invariant.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "=== FR12 root AGENTS.md invariant guard ==="

PROFILES=(codex cursor copilot-cli antigravity)

# AG01 — all four files must exist.
for tool in "${PROFILES[@]}"; do
    assert_file_exists "${REPO_ROOT}/profiles/${tool}/AGENTS.md" \
        "AG01 profiles/${tool}/AGENTS.md exists"
done

# AG02 — single sha256 across all four (byte-identical).
uniq_hashes=$(sha256sum \
    "${REPO_ROOT}/profiles/codex/AGENTS.md" \
    "${REPO_ROOT}/profiles/cursor/AGENTS.md" \
    "${REPO_ROOT}/profiles/copilot-cli/AGENTS.md" \
    "${REPO_ROOT}/profiles/antigravity/AGENTS.md" \
    | awk '{print $1}' | sort -u | wc -l | tr -d ' ')

assert_eq "$uniq_hashes" "1" \
    "AG02 FR12 root AGENTS.md byte-identical across all four profiles (unique hashes: ${uniq_hashes})"

# AG03 — the invariant line must use the tool-agnostic wording, not a hard-coded install root.
INVARIANT_LINE='`templates/reviewer-ledger-schema.md` (under this tool'"'"'s install root). Write the ledger as a single'
TOOL_ROOTS=(".agents" ".cursor" ".github" ".agent")

for tool in "${PROFILES[@]}"; do
    file="${REPO_ROOT}/profiles/${tool}/AGENTS.md"
    if [[ ! -f "$file" ]]; then
        continue  # AG01 already failed for this tool
    fi

    # Must contain the invariant wording.
    assert_file_contains "$file" \
        'templates/reviewer-ledger-schema.md` (under this tool' \
        "AG03 profiles/${tool}/AGENTS.md uses invariant schema-path wording"

    # Must NOT contain any hard-coded tool install-root prefix on that path.
    for root in "${TOOL_ROOTS[@]}"; do
        assert_file_not_contains "$file" \
            "${root}/templates/reviewer-ledger-schema.md" \
            "AG03 profiles/${tool}/AGENTS.md has no hard-coded '${root}/' prefix"
    done
done

test_summary
