#!/usr/bin/env bash
# Focused regression for the migration format stamp while v3 recovery is pending.
set -uo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
mkdir -p "$HOME"

CODE_HOME="$TMP/code"
STATE_HOME="$TMP/state"
mkdir -p "$CODE_HOME/bin" "$CODE_HOME/lib" "$CODE_HOME/dashboard" "$STATE_HOME"
cp "$REPO_ROOT/bin/aid" "$CODE_HOME/bin/aid"
cp "$REPO_ROOT/lib/aid-install-core.sh" "$CODE_HOME/lib/aid-install-core.sh"
printf '0.7.0\n' > "$CODE_HOME/VERSION"
printf '<html></html>\n' > "$CODE_HOME/dashboard/home.html"

new_repo() {
    local repo="$TMP/$1"
    mkdir -p "$repo/.aid/.temp"
    cat > "$repo/.aid/settings.yml" <<'EOF'
project:
  name: stamp-fixture
  description: migration stamp fixture
  type: brownfield

tools:
  installed: []

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 1

traceability:
  heartbeat_interval: 1
EOF
    printf '%s' "$repo"
}

run_migrate() {
    AID_HOME="$STATE_HOME" AID_NO_UPDATE_CHECK=1 \
        bash "$CODE_HOME/bin/aid" __migrate-repo "$1" >/dev/null 2>&1
}

# An empty format-2 manifest is not legacy evidence, but an outstanding
# recovery record still caps the migration stamp until format 3 is committed.
V2_REPO="$(new_repo pending-v2)"
printf '{"format_version":2,"tools":{}}\n' > "$V2_REPO/.aid/.aid-manifest.json"
printf '{}\n' > "$V2_REPO/.aid/.temp/v3-upgrade-tools.json"
run_migrate "$V2_REPO"
assert_eq "$(grep '^format_version:' "$V2_REPO/.aid/settings.yml")" "format_version: 4" \
    "migration stamp: format-2 bare manifest with recovery stays at 4"

# A committed format-3 manifest settles recovery even if the stale record is
# still present; migration advances the settings stamp to 5.
V3_REPO="$(new_repo committed-v3)"
printf '{"format_version":3,"tools":{}}\n' > "$V3_REPO/.aid/.aid-manifest.json"
printf '{}\n' > "$V3_REPO/.aid/.temp/v3-upgrade-tools.json"
run_migrate "$V3_REPO"
assert_eq "$(grep '^format_version:' "$V3_REPO/.aid/settings.yml")" "format_version: 5" \
    "migration stamp: format-3 manifest advances to 5 despite stale recovery"

test_summary
