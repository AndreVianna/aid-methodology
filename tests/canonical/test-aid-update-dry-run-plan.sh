#!/usr/bin/env bash
# Focused wave-10 regression for update dry-run copy/trash/prune planning.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/../lib/bundle.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
BUNDLE="${TMP}/bundle"
TARGET="${TMP}/repo"
mkdir -p "$TARGET"
aid_test_stage_bundle "$BUNDLE" >/dev/null
export HOME="${TMP}/home"
mkdir -p "$HOME"
bash "${REPO_ROOT}/bin/aid" add claude-code,cursor --from-bundle "$BUNDLE" --target "$TARGET" >/dev/null
# Retain an old mirror root in the baseline to exercise cleanup after its config is retired.
python3 - "$TARGET/.aid/.aid-manifest.json" <<'PY'
import json, sys
p=sys.argv[1]
d=json.load(open(p, encoding='utf-8'))
d['shared']['mirrors']={'.claude/skills': {'version': d['aid_version'], 'users':['claude-code']}}
json.dump(d, open(p,'w',encoding='utf-8'), indent=2)
PY
printf 'drift\n' >> "$TARGET/.claude/agents/aid-clerk.md"
mkdir -p "$TARGET/.agents/skills/aid-review-stray" "$TARGET/.claude/agents" "$TARGET/.claude/skills/aid-review-stray"
printf 'stray skill\n' > "$TARGET/.agents/skills/aid-review-stray/SKILL.md"
printf 'stray mirror\n' > "$TARGET/.claude/skills/aid-review-stray/SKILL.md"
printf 'stray agent\n' > "$TARGET/.claude/agents/aid-review-stray.md"
printf 'runtime keep\n' > "$TARGET/.aid/runtime/host.conf"
printf 'runtime stray\n' > "$TARGET/.aid/runtime/stray.txt"
mkdir -p "$TARGET/.aid/runtime/scripts/summarize/node_modules/pkg"
printf 'runtime dependency\n' > "$TARGET/.aid/runtime/scripts/summarize/node_modules/pkg/index.js"
find "$TARGET" -type f -print0 | sort -z | xargs -0 sha256sum > "$TMP/before"
bash "${REPO_ROOT}/bin/aid" update --from-bundle "$BUNDLE" --target "$TARGET" --dry-run > "$TMP/plan"
find "$TARGET" -type f -print0 | sort -z | xargs -0 sha256sum > "$TMP/after"
cmp -s "$TMP/before" "$TMP/after"
grep -F 'move to trash: .claude/agents/aid-clerk.md' "$TMP/plan" >/dev/null
grep -F 'prune: .agents/skills/aid-review-stray/SKILL.md' "$TMP/plan" >/dev/null
grep -F 'prune: .claude/skills/aid-review-stray/SKILL.md' "$TMP/plan" >/dev/null
grep -F 'prune: .claude/agents/aid-review-stray.md' "$TMP/plan" >/dev/null
grep -F 'prune: .aid/runtime/stray.txt' "$TMP/plan" >/dev/null
grep -F 'prune: .aid/runtime/stray.txt (move to trash; modified or untracked)' "$TMP/plan" >/dev/null
! grep -F 'prune: .aid/runtime/host.conf' "$TMP/plan" >/dev/null
! grep -F 'prune: .aid/runtime/scripts/summarize/node_modules/' "$TMP/plan" >/dev/null
bash "${REPO_ROOT}/bin/aid" update cursor --from-bundle "$BUNDLE" --target "$TARGET" > "$TMP/update"
test ! -e "$TARGET/.agents/skills/aid-review-stray/SKILL.md"
test ! -e "$TARGET/.claude/skills/aid-review-stray/SKILL.md"
test ! -e "$TARGET/.claude/agents/aid-review-stray.md"
test ! -e "$TARGET/.aid/runtime/stray.txt"
test -f "$TARGET/.aid/.trash/.claude/agents/aid-clerk.md"
test -f "$TARGET/.aid/.trash/.agents/skills/aid-review-stray/SKILL.md"
test -f "$TARGET/.aid/.trash/.claude/skills/aid-review-stray/SKILL.md"
test -f "$TARGET/.aid/.trash/.claude/agents/aid-review-stray.md"
test -f "$TARGET/.aid/.trash/.aid/runtime/stray.txt"
test "$(cat "$TARGET/.aid/runtime/scripts/summarize/node_modules/pkg/index.js")" = 'runtime dependency'
test -f "$TARGET/.aid/runtime/host.conf"
! grep -F 'drift' "$TARGET/.claude/agents/aid-clerk.md" >/dev/null
echo 'PASS: update dry-run reports guarded tool drift and stale AID files without changing the target'
