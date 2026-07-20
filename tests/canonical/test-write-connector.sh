#!/usr/bin/env bash
# test-write-connector.sh -- unit tests for
# canonical/aid/scripts/connectors/write-connector.sh (feature-007-connectors-list,
# work-017 task-018): the non-interactive dashboard-dispatchable counterpart to the
# `aid-set-connector` / `aid-unset-connector` skills.
#
# Tests cover:
#   U1   set mcp: happy path -- auth_method forced none, no secret_reference,
#        endpoint informational (blank), exit 0
#   U2   set mcp: .secrets/ gitignore precondition created
#   U3   set mcp: trace line reports 'secret purged'
#   U4   set ssh: missing --endpoint -> exit 5, nothing written
#   U5   set ssh: endpoint required; auth_method forced none, no secret_reference
#        (ssh keys/ssh-agent authenticate externally -- AID stores no credential)
#   U6   set api: missing --endpoint -> exit 5, nothing written
#   U7   set api: missing --auth -> exit 5, nothing written
#   U8   set: --type url is no longer a valid connector type -> exit 4
#   U9   set api: auth token, --secret-ref omitted -> defaults to
#        file:.aid/connectors/.secrets/<stem>
#   U10  set api: explicit --secret-ref (env: form) stored verbatim
#   U11  set api: malformed --secret-ref -> exit 4, nothing written
#   U12  set: invalid --type -> exit 4
#   U13  set: invalid --auth -> exit 4
#   U14  set: missing --name -> exit 5
#   U15  set: missing --type -> exit 5
#   U16  set: missing --root -> exit 5
#   U17  remove: missing --stem -> exit 5
#   U18  remove: missing --root -> exit 5
#   U19  remove: invalid --stem (path traversal) -> exit 4
#   U20  remove: happy path -- descriptor removed, INDEX regenerated
#   U21  remove: idempotent on an already-absent stem -> exit 0, no error
#   U22  stem derivation: mixed-case/punctuation name slugified per the skill's rule
#   U23  upsert: re-set overwrites the SAME stem in place (UPDATE); a sibling
#        descriptor is left byte-for-byte untouched (atomic single-entry, Q7)
#   U24  atomic write: no stray temp file left behind under --root after set
#   U25  INDEX.md idempotence: two rebuilds over an identical descriptor set are
#        byte-identical (AC2)
#   U26  unknown operation -> exit 5
#   U27  no arguments at all -> exit 5
#   U28  -h/--help -> exit 0, usage printed
#   U29  unknown flag -> exit 5
#   U30  --name with an embedded newline -> exit 4
#   U31  --name with an embedded double-quote -> exit 4
#   U32  no secret VALUE prompt/text ever appears in stdout/stderr (this writer
#        never invokes connector-secret.sh's interactive `write` op)
#   U33  --auth given for mcp is silently overridden (forced none), no error
#   U34  --secret-ref given for mcp is dropped (never persisted), no error
#   U35  --secret-ref given for auth=none aid-managed type is dropped
#   U36  set: an existing (non-.secrets-mentioning) .gitignore is left untouched
#        (precondition is create-if-absent, never append/overwrite)
#   U37  self-location: the dashboard co-vendored copy resolves its siblings from
#        its OWN directory (dashboard/scripts/), independent of canonical/
#   U38  orphan-secret purge: an existing on-disk .secrets/<stem> file is
#        actually DELETED (not just the descriptor's secret_reference dropped)
#        when a credentialed connector transitions to mcp on a re-set
#   U39  set: --auth ssh-key is no longer a valid auth_method -> exit 4
#   U40  set cli: endpoint required; --auth NOT required (docker-style);
#        auth_method forced none, no secret_reference
#
# Usage:
#   bash tests/canonical/test-write-connector.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.

set -u

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUT="${SCRIPT_DIR}/../../canonical/aid/scripts/connectors/write-connector.sh"
SUT_DASHBOARD="${SCRIPT_DIR}/../../dashboard/scripts/write-connector.sh"

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

if [[ ! -f "$SUT" ]]; then
    echo "FATAL: SUT not found at $SUT"
    exit 2
fi

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

echo "== write-connector.sh tests =="

# ---------------------------------------------------------------------------
# U1 -- set mcp happy path
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u1/connectors"
out=$(bash "$SUT" set --root "$root" --name "GitHub" --type mcp 2>&1)
ec=$?
assert_exit_zero "$ec" "U1 set mcp exits 0"
assert_file_exists "${root}/github.md" "U1 descriptor written at github.md"
assert_file_contains "${root}/github.md" 'connection_type: mcp' "U1 connection_type mcp"
assert_file_contains "${root}/github.md" 'auth_method: none' "U1 auth_method forced none"
assert_file_not_contains "${root}/github.md" 'secret_reference' "U1 no secret_reference persisted"

# ---------------------------------------------------------------------------
# U2 -- .secrets/ gitignore precondition
# ---------------------------------------------------------------------------
assert_file_exists "${root}/.gitignore" "U2 .gitignore created"
assert_file_contains "${root}/.gitignore" '.secrets/' "U2 .gitignore ignores .secrets/"

# ---------------------------------------------------------------------------
# U3 -- trace reports secret purged for an mcp/none result
# ---------------------------------------------------------------------------
assert_output_contains "$out" "secret purged" "U3 trace reports secret purged"

# ---------------------------------------------------------------------------
# U4 -- set ssh missing --endpoint
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u4/connectors"
out=$(bash "$SUT" set --root "$root" --name "Box" --type ssh 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U4 ssh missing --endpoint exits 5"
if [[ ! -f "${root}/box.md" ]]; then pass "U4 nothing written"; else fail "U4 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U5 -- set ssh: endpoint required; auth_method forced none, no secret_reference
# (ssh keys/ssh-agent authenticate externally -- AID stores no credential)
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u5/connectors"
out=$(bash "$SUT" set --root "$root" --name "Box" --type ssh --endpoint "box.example.com" 2>&1)
ec=$?
assert_exit_zero "$ec" "U5 ssh with endpoint exits 0"
assert_file_contains "${root}/box.md" 'auth_method: none' "U5 auth_method forced none"
assert_file_not_contains "${root}/box.md" 'secret_reference' "U5 no secret_reference persisted for ssh"

# ---------------------------------------------------------------------------
# U6 -- set api missing --endpoint
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u6/connectors"
out=$(bash "$SUT" set --root "$root" --name "Jira" --type api --auth token 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U6 api missing --endpoint exits 5"
if [[ ! -f "${root}/jira.md" ]]; then pass "U6 nothing written"; else fail "U6 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U7 -- set api missing --auth
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u7/connectors"
out=$(bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint "https://x" 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U7 api missing --auth exits 5"
if [[ ! -f "${root}/jira.md" ]]; then pass "U7 nothing written"; else fail "U7 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U8 -- set: --type url is no longer a valid connector type -> exit 4
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u8/connectors"
out=$(bash "$SUT" set --root "$root" --name "Docker" --type url --endpoint "https://x" --auth none 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U8 invalid --type url is rejected (exit 4)"
if [[ ! -f "${root}/docker.md" ]]; then pass "U8 nothing written for rejected type"; else fail "U8 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U9 -- set api auth token, --secret-ref omitted -> default form
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u9/connectors"
out=$(bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint "https://acme.atlassian.net/rest/api/3" --auth token 2>&1)
ec=$?
assert_exit_zero "$ec" "U9 api credentialed exits 0"
assert_file_contains "${root}/jira.md" 'secret_reference: "file:.aid/connectors/.secrets/jira"' "U9 default secret_reference form"

# ---------------------------------------------------------------------------
# U10 -- set api explicit --secret-ref (env: form)
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u10/connectors"
out=$(bash "$SUT" set --root "$root" --name "Slack" --type api --endpoint "https://slack.com/api/" --auth token --secret-ref "env:SLACK_TOKEN" 2>&1)
ec=$?
assert_exit_zero "$ec" "U10 api explicit secret-ref exits 0"
assert_file_contains "${root}/slack.md" 'secret_reference: "env:SLACK_TOKEN"' "U10 explicit secret_reference stored verbatim"

# ---------------------------------------------------------------------------
# U11 -- set api malformed --secret-ref
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u11/connectors"
out=$(bash "$SUT" set --root "$root" --name "Slack" --type api --endpoint "https://slack.com/api/" --auth token --secret-ref "bogus:thing" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U11 malformed --secret-ref exits 4"
if [[ ! -f "${root}/slack.md" ]]; then pass "U11 nothing written"; else fail "U11 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U12/U13 -- invalid --type / --auth
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u12/connectors"
out=$(bash "$SUT" set --root "$root" --name "X" --type bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U12 invalid --type exits 4"

root="${TMPDIR_BASE}/u13/connectors"
out=$(bash "$SUT" set --root "$root" --name "X" --type api --endpoint e --auth bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U13 invalid --auth exits 4"

# ---------------------------------------------------------------------------
# U14/U15/U16 -- missing required args
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u14/connectors"
out=$(bash "$SUT" set --root "$root" --type mcp 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U14 missing --name exits 5"

out=$(bash "$SUT" set --root "$root" --name "X" 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U15 missing --type exits 5"

out=$(bash "$SUT" set --name "X" --type mcp 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U16 missing --root exits 5"

# ---------------------------------------------------------------------------
# U17/U18 -- remove missing required args
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u17/connectors"
out=$(bash "$SUT" remove --root "$root" 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U17 remove missing --stem exits 5"

out=$(bash "$SUT" remove --stem "jira" 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U18 remove missing --root exits 5"

# ---------------------------------------------------------------------------
# U19 -- remove path-confinement rejection
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u19/connectors"
out=$(bash "$SUT" remove --root "$root" --stem "../evil" 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U19 remove path-confinement rejects '../evil' (exit 4)"

# ---------------------------------------------------------------------------
# U20 -- remove happy path
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u20/connectors"
bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e --auth token >/dev/null 2>&1
assert_file_exists "${root}/jira.md" "U20 fixture descriptor exists before remove"
out=$(bash "$SUT" remove --root "$root" --stem "jira" 2>&1)
ec=$?
assert_exit_zero "$ec" "U20 remove exits 0"
if [[ ! -f "${root}/jira.md" ]]; then pass "U20 descriptor removed"; else fail "U20 descriptor still present"; fi
assert_file_not_contains "${root}/INDEX.md" '[Jira]' "U20 INDEX no longer lists jira"

# ---------------------------------------------------------------------------
# U21 -- remove idempotent on an already-absent stem
# ---------------------------------------------------------------------------
out=$(bash "$SUT" remove --root "$root" --stem "jira" 2>&1)
ec=$?
assert_exit_zero "$ec" "U21 remove on already-absent stem exits 0 (idempotent)"

# ---------------------------------------------------------------------------
# U22 -- stem derivation (skill's exact slug rule)
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u22/connectors"
out=$(bash "$SUT" set --root "$root" --name "  My Cool API!!  " --type mcp 2>&1)
ec=$?
assert_exit_zero "$ec" "U22 punctuation/whitespace name exits 0"
assert_file_exists "${root}/my-cool-api.md" "U22 slug derived as 'my-cool-api'"

# ---------------------------------------------------------------------------
# U23 -- upsert overwrites the SAME stem; a sibling descriptor is untouched
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u23/connectors"
bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e1 --auth token >/dev/null 2>&1
bash "$SUT" set --root "$root" --name "GitHub" --type mcp >/dev/null 2>&1
before_github=$(cat "${root}/github.md")
out=$(bash "$SUT" set --root "$root" --name "Jira" --type ssh --endpoint e2 2>&1)
ec=$?
assert_exit_zero "$ec" "U23 re-set (UPDATE) exits 0"
assert_file_contains "${root}/jira.md" 'connection_type: ssh' "U23 jira overwritten in place (new type)"
assert_file_contains "${root}/jira.md" 'endpoint: "e2"' "U23 jira overwritten in place (new endpoint)"
after_github=$(cat "${root}/github.md")
assert_eq "$after_github" "$before_github" "U23 sibling descriptor (github.md) byte-for-byte untouched"

# ---------------------------------------------------------------------------
# U24 -- atomic write: no stray temp file left under --root
# ---------------------------------------------------------------------------
leftover=$(find "$root" -maxdepth 1 -name '.write-connector.*' 2>/dev/null)
if [[ -z "$leftover" ]]; then
    pass "U24 no stray temp file left under --root"
else
    fail "U24 stray temp file found: $leftover"
fi

# ---------------------------------------------------------------------------
# U25 -- INDEX.md idempotence (AC2): two runs over an identical descriptor
# set are byte-identical.
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u25/connectors"
bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e --auth token >/dev/null 2>&1
sha1=$(sha256sum "${root}/INDEX.md" | awk '{print $1}')
bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e --auth token >/dev/null 2>&1
sha2=$(sha256sum "${root}/INDEX.md" | awk '{print $1}')
assert_eq "$sha2" "$sha1" "U25 INDEX.md byte-identical across repeat set of an unchanged descriptor"

# ---------------------------------------------------------------------------
# U26/U27 -- unknown operation / no arguments
# ---------------------------------------------------------------------------
out=$(bash "$SUT" bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U26 unknown operation exits 5"

out=$(bash "$SUT" 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U27 no arguments exits 5"

# ---------------------------------------------------------------------------
# U28 -- -h/--help
# ---------------------------------------------------------------------------
out=$(bash "$SUT" -h 2>&1)
ec=$?
assert_exit_zero "$ec" "U28 -h exits 0"
assert_output_contains "$out" "Usage:" "U28 usage text printed"

# ---------------------------------------------------------------------------
# U29 -- unknown flag
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u29/connectors"
out=$(bash "$SUT" set --root "$root" --name X --type mcp --bogus 2>&1)
ec=$?
assert_exit_eq "$ec" 5 "U29 unknown flag exits 5"

# ---------------------------------------------------------------------------
# U30/U31 -- charset guard on --name
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u30/connectors"
out=$(bash "$SUT" set --root "$root" --name $'bad\nname' --type mcp 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U30 newline in --name exits 4"

root="${TMPDIR_BASE}/u31/connectors"
out=$(bash "$SUT" set --root "$root" --name 'bad"name' --type mcp 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U31 embedded double-quote in --name exits 4"

# ---------------------------------------------------------------------------
# U32 -- no secret VALUE prompt ever appears (this writer never invokes
# connector-secret.sh's interactive `write` op -- only `purge`)
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u32/connectors"
out=$(bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e --auth token 2>&1)
assert_output_not_contains "$out" "Enter secret value" "U32 no secret-capture prompt ever printed"

# ---------------------------------------------------------------------------
# U33 -- --auth given for mcp is silently overridden (forced none)
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u33/connectors"
out=$(bash "$SUT" set --root "$root" --name "GitHub" --type mcp --auth token 2>&1)
ec=$?
assert_exit_zero "$ec" "U33 --auth given for mcp does not error"
assert_file_contains "${root}/github.md" 'auth_method: none' "U33 auth_method still forced none"

# ---------------------------------------------------------------------------
# U34 -- --secret-ref given for mcp is dropped
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u34/connectors"
out=$(bash "$SUT" set --root "$root" --name "GitHub" --type mcp --secret-ref "env:GH_TOKEN" 2>&1)
ec=$?
assert_exit_zero "$ec" "U34 --secret-ref given for mcp does not error"
assert_file_not_contains "${root}/github.md" 'secret_reference' "U34 secret_reference dropped for mcp"

# ---------------------------------------------------------------------------
# U35 -- --secret-ref given for auth=none aid-managed type is dropped
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u35/connectors"
out=$(bash "$SUT" set --root "$root" --name "Docker" --type cli --endpoint "docker" --auth none --secret-ref "env:X" 2>&1)
ec=$?
assert_exit_zero "$ec" "U35 --secret-ref given with auth none does not error"
assert_file_not_contains "${root}/docker.md" 'secret_reference' "U35 secret_reference dropped when auth none"

# ---------------------------------------------------------------------------
# U36 -- an existing .gitignore (without .secrets/) is left untouched
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u36/connectors"
mkdir -p "$root"
printf '%s\n' 'node_modules/' > "${root}/.gitignore"
out=$(bash "$SUT" set --root "$root" --name "X" --type mcp 2>&1)
ec=$?
assert_exit_zero "$ec" "U36 set exits 0"
assert_file_contains "${root}/.gitignore" 'node_modules/' "U36 pre-existing .gitignore content preserved"
assert_file_not_contains "${root}/.gitignore" '.secrets/' "U36 pre-existing .gitignore NOT amended with .secrets/"

# ---------------------------------------------------------------------------
# U37 -- dashboard co-vendored copy self-locates its siblings from its OWN
# directory (independent of canonical/)
# ---------------------------------------------------------------------------
if [[ -f "$SUT_DASHBOARD" ]]; then
    root="${TMPDIR_BASE}/u37/connectors"
    out=$(bash "$SUT_DASHBOARD" set --root "$root" --name "Test" --type mcp 2>&1)
    ec=$?
    assert_exit_zero "$ec" "U37 dashboard co-vendored copy set exits 0"
    assert_file_exists "${root}/test.md" "U37 dashboard copy wrote descriptor"
    assert_file_exists "${root}/INDEX.md" "U37 dashboard copy self-located build-connectors-index.sh"
else
    fail "U37 dashboard co-vendored copy not found at $SUT_DASHBOARD"
fi

# ---------------------------------------------------------------------------
# U38 -- orphan-secret purge actually deletes an existing .secrets/<stem> file
# (not just drops the descriptor's secret_reference field) when a credentialed
# connector transitions to mcp on a re-set.
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u38/connectors"
bash "$SUT" set --root "$root" --name "Jira" --type api --endpoint e --auth token >/dev/null 2>&1
mkdir -p "${root}/.secrets"
printf 'super-secret-value' > "${root}/.secrets/jira"
assert_file_exists "${root}/.secrets/jira" "U38 fixture secret file exists before transition"
out=$(bash "$SUT" set --root "$root" --name "Jira" --type mcp 2>&1)
ec=$?
assert_exit_zero "$ec" "U38 re-set to mcp exits 0"
if [[ ! -f "${root}/.secrets/jira" ]]; then
    pass "U38 orphaned secret file actually deleted on type transition to mcp"
else
    fail "U38 orphaned secret file still present after transition to mcp"
fi

# ---------------------------------------------------------------------------
# U39 -- --auth ssh-key is no longer a valid auth_method -> exit 4
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u39/connectors"
out=$(bash "$SUT" set --root "$root" --name "Box" --type ssh --endpoint "box.example.com" --auth ssh-key 2>&1)
ec=$?
assert_exit_eq "$ec" 4 "U39 --auth ssh-key is rejected (exit 4)"
if [[ ! -f "${root}/box.md" ]]; then pass "U39 nothing written for rejected auth"; else fail "U39 unexpected file written"; fi

# ---------------------------------------------------------------------------
# U40 -- set cli: endpoint required; --auth NOT required (docker-style);
# auth_method forced none, no secret_reference
# ---------------------------------------------------------------------------
root="${TMPDIR_BASE}/u40/connectors"
out=$(bash "$SUT" set --root "$root" --name "Docker" --type cli --endpoint "docker" 2>&1)
ec=$?
assert_exit_zero "$ec" "U40 cli with endpoint and no --auth exits 0"
assert_file_contains "${root}/docker.md" 'connection_type: cli' "U40 connection_type cli"
assert_file_contains "${root}/docker.md" 'auth_method: none' "U40 auth_method forced none"
assert_file_not_contains "${root}/docker.md" 'secret_reference' "U40 no secret_reference persisted for cli"

echo
test_summary
exit $?
