#!/usr/bin/env bash
# test-install-provisioning.sh — focused unit tests for the work-007 installer
# behaviors, sourcing lib/aid-install-core.sh directly (no tarball / no 282-file
# copy), so they run fast and are environment-independent:
#
#   1. copy_file overwrite-on-diff (AID-owned files always track the bundle)
#   2. seed_settings_yml            (seed-if-missing; never clobber user config)
#   3. update_gitignore             (create/append/update AID region; idempotent;
#                                    preserves user content)
#
# Usage: bash test-install-provisioning.sh [--verbose]
# Exit: 0 all pass / 1 any fail.

set -uo pipefail

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/lib/aid-install-core.sh"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
newdir() { mktemp -d "${TMP}/d.XXXXXX"; }

# ---------------------------------------------------------------------------
# 1. copy_file — overwrite-on-diff (the skip-on-diff regression)
# ---------------------------------------------------------------------------

# CP1 — dst absent → copied
d=$(newdir)
printf 'new\n' > "${d}/src"
_COPY_COUNT_COPIED=0 _COPY_COUNT_UPTODATE=0 _COPY_COUNT_UPDATED=0 _COPY_COUNT_SKIPPED=0
copy_file "${d}/src" "${d}/dst" 0
assert_file_exists "${d}/dst" "CP1 dst created when absent"
assert_eq "$(cat "${d}/dst")" "new" "CP1b dst has source content"
assert_eq "$_COPY_COUNT_COPIED" "1" "CP1c COPIED counter incremented"

# CP2 — dst differs, force=0 → OVERWRITTEN (was skipped before work-007)
d=$(newdir)
printf 'new\n' > "${d}/src"
printf 'old local edit\n' > "${d}/dst"
_COPY_COUNT_COPIED=0 _COPY_COUNT_UPTODATE=0 _COPY_COUNT_UPDATED=0 _COPY_COUNT_SKIPPED=0
copy_file "${d}/src" "${d}/dst" 0
assert_eq "$(cat "${d}/dst")" "new" "CP2 differing dst OVERWRITTEN without --force"
assert_eq "$_COPY_COUNT_UPDATED" "1" "CP2b UPDATED counter incremented"
assert_eq "$_COPY_COUNT_SKIPPED" "0" "CP2c nothing skipped (skip-on-diff removed)"

# CP3 — dst identical → up-to-date, no rewrite
d=$(newdir)
printf 'same\n' > "${d}/src"
printf 'same\n' > "${d}/dst"
_COPY_COUNT_COPIED=0 _COPY_COUNT_UPTODATE=0 _COPY_COUNT_UPDATED=0 _COPY_COUNT_SKIPPED=0
copy_file "${d}/src" "${d}/dst" 0
assert_eq "$_COPY_COUNT_UPTODATE" "1" "CP3 identical dst counted up-to-date"
assert_eq "$_COPY_COUNT_UPDATED" "0" "CP3b identical dst not rewritten"

# ---------------------------------------------------------------------------
# 2. seed_settings_yml — seed-if-missing; never clobber
# ---------------------------------------------------------------------------

# helper: build a fake installed tree with the settings template present
mk_target_with_template() {
    local t="$1" root="$2"
    mkdir -p "${t}/${root}/aid/templates"
    printf 'project:\n  name: <project-name>\n' > "${t}/${root}/aid/templates/settings.yml"
}

# SE1 — missing settings.yml → seeded from template
t=$(newdir); mk_target_with_template "$t" ".claude"
_CORE_SEEDED_SETTINGS=0
seed_settings_yml "$t" "claude-code"
assert_file_exists "${t}/.aid/settings.yml" "SE1 settings.yml seeded when missing"
assert_eq "$_CORE_SEEDED_SETTINGS" "1" "SE1b seeded flag set"
assert_file_contains "${t}/.aid/settings.yml" "<project-name>" "SE1c seeded from template"
assert_file_contains "${t}/.aid/settings.yml" "format_version:" "SE1d format_version stamped (format gate)"
assert_eq "$(head -1 "${t}/.aid/settings.yml")" "format_version: 3" "SE1e format_version is the first line"

# SE2 — existing settings.yml → NEVER overwritten
t=$(newdir); mk_target_with_template "$t" ".claude"
mkdir -p "${t}/.aid"; printf 'project:\n  name: MyRealProject\n' > "${t}/.aid/settings.yml"
_CORE_SEEDED_SETTINGS=0
seed_settings_yml "$t" "claude-code"
assert_file_contains "${t}/.aid/settings.yml" "MyRealProject" "SE2 existing user config preserved"
assert_file_not_contains "${t}/.aid/settings.yml" "<project-name>" "SE2b template did NOT clobber user config"
assert_eq "$_CORE_SEEDED_SETTINGS" "0" "SE2c seeded flag NOT set (no-op)"

# SE3 — no template present → no-op, no crash
t=$(newdir); mkdir -p "${t}/.cursor/aid/templates"   # dir but no settings.yml
_CORE_SEEDED_SETTINGS=0
seed_settings_yml "$t" "cursor"
assert_eq "$([[ -f "${t}/.aid/settings.yml" ]] && echo yes || echo no)" "no" "SE3 no seed when template absent"
assert_eq "$_CORE_SEEDED_SETTINGS" "0" "SE3b seeded flag not set"

# ---------------------------------------------------------------------------
# 3. update_gitignore — create / idempotent / preserve / update region
# ---------------------------------------------------------------------------

# GI1 — no .gitignore → created with the AID region + all patterns
t=$(newdir)
_CORE_GITIGNORE_ACTION=""
update_gitignore "$t"
assert_file_exists "${t}/.gitignore" "GI1 .gitignore created"
assert_eq "$_CORE_GITIGNORE_ACTION" "created" "GI1b action=created"
assert_file_contains "${t}/.gitignore" ".aid/.temp/" "GI1c has .aid/.temp/"
assert_file_contains "${t}/.gitignore" ".aid/.trash/" "GI1d has .aid/.trash/"
assert_file_contains "${t}/.gitignore" ".aid/knowledge/.cache/" "GI1e has knowledge/.cache/"
assert_file_contains "${t}/.gitignore" "AID managed" "GI1f has region markers"

# GI2 — second run → idempotent (unchanged, byte-identical)
cp "${t}/.gitignore" "${TMP}/gi-snapshot"
_CORE_GITIGNORE_ACTION=""
update_gitignore "$t"
assert_eq "$_CORE_GITIGNORE_ACTION" "unchanged" "GI2 second run action=unchanged"
assert_eq "$(cmp -s "${t}/.gitignore" "${TMP}/gi-snapshot" && echo same || echo diff)" \
    "same" "GI2b .gitignore byte-identical on re-run (idempotent)"

# GI3 — existing user .gitignore → user content preserved, region appended
t=$(newdir)
printf '# my rules\nnode_modules/\n*.log\n' > "${t}/.gitignore"
_CORE_GITIGNORE_ACTION=""
update_gitignore "$t"
assert_file_contains "${t}/.gitignore" "node_modules/" "GI3 user content preserved"
assert_file_contains "${t}/.gitignore" "*.log" "GI3b user content preserved (2)"
assert_file_contains "${t}/.gitignore" ".aid/.temp/" "GI3c AID region appended"
assert_eq "$_CORE_GITIGNORE_ACTION" "updated" "GI3d action=updated"
# idempotent after append
cp "${t}/.gitignore" "${TMP}/gi3-snap"
update_gitignore "$t"
assert_eq "$(cmp -s "${t}/.gitignore" "${TMP}/gi3-snap" && echo same || echo diff)" \
    "same" "GI3e idempotent after append to user file"

# GI4 — stale AID region → replaced in place, user content untouched
t=$(newdir)
{
  printf '# top user rule\nbuild/\n\n'
  printf '# >>> AID managed -- do not edit (aid add/update maintains this block) >>>\n'
  printf '.aid/OLD-STALE-PATTERN/\n'
  printf '# <<< AID managed <<<\n'
  printf '\n# bottom user rule\ndist/\n'
} > "${t}/.gitignore"
_CORE_GITIGNORE_ACTION=""
update_gitignore "$t"
assert_file_not_contains "${t}/.gitignore" "OLD-STALE-PATTERN" "GI4 stale pattern removed"
assert_file_contains "${t}/.gitignore" ".aid/.heartbeat/" "GI4b current patterns present"
assert_file_contains "${t}/.gitignore" "build/" "GI4c user content above region preserved"
assert_file_contains "${t}/.gitignore" "dist/" "GI4d user content below region preserved"
# exactly one AID region (no duplication)
assert_eq "$(grep -c 'AID managed -- do not edit' "${t}/.gitignore")" "1" \
    "GI4e exactly one AID region (no duplicate)"

# ---------------------------------------------------------------------------
# 4. C3 — update_gitignore idempotent on a CRLF file (no churn, bytes preserved)
# ---------------------------------------------------------------------------
t=$(newdir)
printf '# user\r\nnode_modules/\r\n' > "${t}/.gitignore"      # CRLF file
update_gitignore "$t"                                          # first run appends region
cp "${t}/.gitignore" "${TMP}/gi-crlf-snap"
_CORE_GITIGNORE_ACTION=""
update_gitignore "$t"                                          # second run
assert_eq "$_CORE_GITIGNORE_ACTION" "unchanged" "GI5 CRLF file: second run unchanged (C3 idempotent)"
assert_eq "$(cmp -s "${t}/.gitignore" "${TMP}/gi-crlf-snap" && echo same || echo diff)" \
    "same" "GI5b CRLF file: bytes preserved on re-run (no churn)"

# ---------------------------------------------------------------------------
# 5. C1 — C2 migration must NOT duplicate the ## Workflow section
# ---------------------------------------------------------------------------
d=$(newdir)
cat > "${d}/src.md" <<'EOF'
# CLAUDE.md
<!-- AID:BEGIN -->
## Tracking discipline
track
## Knowledge Base
kb
## Workflow
new workflow
## Review output format
rev
## Permissions
perms
<!-- AID:END -->
EOF
# legacy dst: NO markers, carries its own AID-style ## Workflow + user content
cat > "${d}/dst.md" <<'EOF'
# CLAUDE.md
## Project
my project
## Workflow
old workflow
## Permissions
old perms
EOF
_COPY_COUNT_COPIED=0 _COPY_COUNT_UPTODATE=0 _COPY_COUNT_UPDATED=0 _COPY_COUNT_SKIPPED=0 _COPY_COUNT_FAILED=0
_copy_root_agent_file "${d}/src.md" "${d}/dst.md" "claude-code" 0 ""
assert_eq "$(grep -c '^## Workflow' "${d}/dst.md")" "1" "C1 exactly one ## Workflow after C2 migration (no duplicate)"
assert_file_contains "${d}/dst.md" "my project" "C1b user ## Project content preserved"
assert_file_contains "${d}/dst.md" "<!-- AID:BEGIN -->" "C1c region markers inserted"

# ---------------------------------------------------------------------------
# 6. CONN — is_aid_heading recognizes ## Connectors (task-003); C2 migration
#           must NOT duplicate the ## Connectors section (mirrors the C1
#           Workflow-omission regression above; task-004 adds this heading
#           to the shipped managed region).
# ---------------------------------------------------------------------------
d=$(newdir)
cat > "${d}/src.md" <<'EOF'
# CLAUDE.md
<!-- AID:BEGIN -->
## Tracking discipline
track
## Knowledge Base
kb
## Connectors
new connectors
## Workflow
new workflow
## Review output format
rev
## Permissions
perms
<!-- AID:END -->
EOF
# legacy dst: NO markers, carries its own AID-style ## Connectors + user content
cat > "${d}/dst.md" <<'EOF'
# CLAUDE.md
## Project
my project
## Connectors
old connectors
## Permissions
old perms
EOF
_COPY_COUNT_COPIED=0 _COPY_COUNT_UPTODATE=0 _COPY_COUNT_UPDATED=0 _COPY_COUNT_SKIPPED=0 _COPY_COUNT_FAILED=0
_copy_root_agent_file "${d}/src.md" "${d}/dst.md" "claude-code" 0 ""
assert_eq "$(grep -c '^## Connectors' "${d}/dst.md")" "1" "CONN1 exactly one ## Connectors after C2 migration (no duplicate)"
assert_file_contains "${d}/dst.md" "my project" "CONN1b user ## Project content preserved"
assert_file_contains "${d}/dst.md" "<!-- AID:BEGIN -->" "CONN1c region markers inserted"

test_summary
