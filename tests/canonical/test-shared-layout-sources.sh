#!/usr/bin/env bash
# test-shared-layout-sources.sh -- source invariants for shared skills/runtime.
#
# One generator invocation (in a throwaway git clone); all other assertions inspect
# source once or run against copies under mktemp. See work-001 task-016.
# Usage: HOME=$(mktemp -d) bash tests/canonical/test-shared-layout-sources.sh [--verbose]
# Exit codes: 0 all pass / 1 any fail.
set -u
VERBOSE=0
[[ "${1:-}" == "--verbose" ]] && VERBOSE=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/assert.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="${HOME:-$TMP/home}"
mkdir -p "$HOME"

echo "== test-shared-layout-sources.sh =="

# AC-1: generator is run once on a clone. Plant preservation sentinels before it.
CLONE="$TMP/clone"
git clone --no-hardlinks --quiet "$REPO" "$CLONE" || { echo "FATAL: clone failed" >&2; exit 2; }
mkdir -p "$CLONE/profiles/claude-code/stray-dir"
echo stray > "$CLONE/profiles/claude-code/stray.txt"
echo readme > "$CLONE/profiles/claude-code/stray-dir/README.md"
GEN_OUT="$(cd "$CLONE" && python .claude/skills/generate-profile/scripts/run_generator.py 2>&1)"; GEN_RC=$?
assert_exit_zero "$GEN_RC" "AC-1 generator exits successfully in throwaway clone"
assert_output_contains "$GEN_OUT" "VERIFY (deterministic): PASS" "AC-1 generator reports deterministic verification"
[[ ! -e "$CLONE/profiles/claude-code/stray.txt" && ! -e "$CLONE/profiles/claude-code/stray-dir/README.md" ]] \
  && pass "AC-1 generator removes planted stray file and README" \
  || fail "AC-1 generator removes planted stray file and README"
BAD=0
while IFS= read -r -d '' f; do
  rel="${f#"$CLONE/"}"
  # profiles/<tool>.toml are generator inputs; generated trees live below
  # profiles/<tool>/ and contain only agents plus aid-tool.conf.
  case "$rel" in profiles/*.toml) ;; profiles/*/agents/*|profiles/*/aid-tool.conf) ;; *) BAD=1; [[ "$VERBOSE" -eq 1 ]] && echo "unexpected: $rel";; esac
done < <(find "$CLONE/profiles" -type f -print0)
[[ $BAD -eq 0 ]] && pass "AC-1 regenerated profiles contain only agents and aid-tool.conf" || fail "AC-1 regenerated profiles contain only agents and aid-tool.conf"
if find "$CLONE/profiles" -type f -name '*.jsonl' -print -quit | grep -q .; then fail "AC-1 regenerated profiles contain no .jsonl manifest"; else pass "AC-1 regenerated profiles contain no .jsonl manifest"; fi
if find "$CLONE/profiles" -type d \( -name skills -o -name aid \) -print -quit | grep -q .; then fail "AC-1 profiles have no skills or aid directories"; else pass "AC-1 profiles have no skills or aid directories"; fi

# AC-4: execute the five documented checks, recording each independently.
ac4_check() { local name="$1" pattern="$2" root="${3:-$REPO/canonical/skills}" count; count="$(grep -rlE "$pattern" "$root" 2>/dev/null | wc -l | tr -d ' ')"; assert_eq "$count" 0 "$name"; }
ac4_check "AC-4 no canonical source tokens in skills" '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/'
ac4_check "AC-4 no filename placeholders in skills" '\{(project_context_file|reviewer_output_file|open_questions_file)\}'
ac4_check "AC-4 no host install roots in skills" '\.(claude|codex|cursor|agent)/'
ac4_check "AC-4 no GitHub install roots in skills" '\.github/(aid|skills|agents)/'
ac4_check "AC-4 no claude worktrees token in canonical" '\.claude/worktrees' "$REPO/canonical"

# AC-5: build matching allowlist rules by path; classify comments only for the
# five documented code types. Markdown and other files count every line.
ac5_violations() {
  local root="$1" allow="$2" f line n ext pattern found
  while IFS= read -r -d '' f; do
    ext="${f##*.}"; n=0
    while IFS= read -r line || [[ -n "$line" ]]; do
      n=$((n + 1)); [[ "$line" =~ ^[[:space:]]*# ]] && [[ "$ext" =~ ^(sh|py|ps1|yml|yaml)$ ]] && continue
      if [[ "$line" =~ canonical/(aid/)?(scripts|templates|skills|agents|recipes)/|\.(claude|codex|cursor|agent)/ ]]; then
        found=0
        while IFS=$'\t' read -r path pattern why; do
          [[ -z "$path" || "$path" == \#* ]] && continue
          [[ "$path" == "${f#"$root/"}" ]] || continue
          [[ -n "$why" ]] || continue
          if grep -Eq -- "$pattern" <<< "$line"; then found=1; break; fi
        done < "$allow"
        [[ $found -eq 1 ]] || printf '%s:%d:%s\n' "${f#"$root/"}" "$n" "$line"
      fi
    done < "$f"
  done < <(find "$root/canonical/aid" -type f -print0)
}
ALLOW="$REPO/tests/canonical/fixtures/runtime-source-path-allowlist.tsv"
source_snapshot() {
  find "$REPO/canonical/aid" "$REPO/canonical/skills" -type f -print0 \
    | sort -z | xargs -0 sha256sum | sha256sum
}
SOURCE_BEFORE="$(source_snapshot)"
V="$(ac5_violations "$REPO" "$ALLOW")"
[[ -z "$V" ]] && pass "AC-5 non-comment runtime lines are neutral or allowlisted" || { fail "AC-5 non-comment runtime lines are neutral or allowlisted"; [[ "$VERBOSE" -eq 1 ]] && printf '%s\n' "$V"; }
allowlist_ok() {
  local file="$1" path pattern why bad=0
  while IFS=$'\t' read -r path pattern why; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    [[ -n "$why" ]] || { bad=1; continue; }
    [[ -f "$REPO/$path" ]] && grep -Eq -- "$pattern" "$REPO/$path" || bad=1
  done < "$file"
  [[ $bad -eq 0 ]]
}
ALLOW_BAD=0; allowlist_ok "$ALLOW" || ALLOW_BAD=1
[[ $ALLOW_BAD -eq 0 ]] && pass "AC-5 allowlist why fields are non-empty and patterns are current" || fail "AC-5 allowlist why fields are non-empty and patterns are current"

# AC-6: inspect every skill's actual allowed-tools declaration and metadata keys.
AC6_BAD_COMMA=0; BASH_COUNT=0; PHRASE_COUNT=0; META_COUNT=0
while IFS= read -r -d '' f; do
  while IFS= read -r line; do
    [[ "$line" =~ ^allowed-tools: ]] || continue
    [[ "$line" == *,* ]] && AC6_BAD_COMMA=1
    [[ "$line" =~ (^|[[:space:],])Bash([[:space:],]|$) ]] && BASH_COUNT=$((BASH_COUNT + 1))
    [[ "$line" == *"Bash Shell Terminal"* ]] && PHRASE_COUNT=$((PHRASE_COUNT + 1))
  done < "$f"
  if grep -qE '^(context|agent):' "$f"; then META_COUNT=$((META_COUNT + 1)); fi
done < <(find "$REPO/canonical/skills" -name SKILL.md -type f -print0)
assert_eq "$AC6_BAD_COMMA" 0 "AC-6 allowed-tools lines contain no comma"
assert_eq "$BASH_COUNT" "$PHRASE_COUNT" "AC-6 Bash count matches Bash Shell Terminal count"
assert_eq "$META_COUNT" 0 "AC-6 skills contain no context or agent key"

# Rules source invariants.
RULES="$REPO/canonical/aid/rules.md"
assert_file_exists "$RULES" "rules source exists"
if grep -qE '\.(claude|codex|cursor|agent)/|\.github/aid/|canonical/|^@|AID[- ](START|END)|<!--.*AID' "$RULES"; then fail "rules source contains no host path, canonical token, import, or AID marker"; else pass "rules source contains no host path, canonical token, import, or AID marker"; fi

# Negative controls: run only the relevant invariant against private fixture copies.
NEG="$TMP/negative"
mkdir -p "$NEG/canonical/aid/templates" "$NEG/canonical/skills/aid-x" "$NEG/tests/canonical/fixtures"
cp -R "$REPO/canonical/aid/." "$NEG/canonical/aid/"
cp -R "$REPO/canonical/skills/." "$NEG/canonical/skills/"
cp "$ALLOW" "$NEG/tests/canonical/fixtures/allow.tsv"
echo 'canonical/aid/scripts/hidden.sh' > "$NEG/canonical/skills/aid-x/SKILL.md"
ac4_bad="$(grep -rlE '(^|[^A-Za-z0-9_])canonical/(aid/)?(scripts|templates|skills|agents|recipes)/' "$NEG/canonical/skills" | wc -l | tr -d ' ')"
[[ "$ac4_bad" -gt 0 ]] && pass "negative control AC-4 detects planted canonical/aid/scripts token" || fail "negative control AC-4 detects planted canonical/aid/scripts token"
echo 'unlisted .claude/install/path' > "$NEG/canonical/aid/templates/negative.md"
NEG_V="$(ac5_violations "$NEG" "$NEG/tests/canonical/fixtures/allow.tsv")"
[[ -n "$NEG_V" ]] && pass "negative control AC-5 detects unlisted host path" || fail "negative control AC-5 detects unlisted host path"
echo 'allowed-tools: Bash, Read' > "$NEG/canonical/skills/aid-x/SKILL.md"
grep -qE '^allowed-tools:.*,' "$NEG/canonical/skills/aid-x/SKILL.md" && pass "negative control AC-6 detects comma-separated allowed-tools" || fail "negative control AC-6 detects comma-separated allowed-tools"
awk -F '\t' 'BEGIN{OFS="\t"} !/^#/ && NF>=3 {$3=""} {print}' "$ALLOW" > "$NEG/tests/canonical/fixtures/empty-why.tsv"
if allowlist_ok "$NEG/tests/canonical/fixtures/empty-why.tsv"; then fail "negative control empty allowlist why is rejected"; else pass "negative control empty allowlist why is rejected"; fi
SOURCE_AFTER="$(source_snapshot)"
assert_eq "$SOURCE_AFTER" "$SOURCE_BEFORE" "negative controls leave source skills and runtime unchanged"

test_summary
