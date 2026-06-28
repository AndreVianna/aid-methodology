#!/usr/bin/env bash
# test-parse-recipe.sh — smoke-test harness for parse-recipe.sh
#
# Tests all operating modes: --list, --validate, --spec, --tasks, --render,
# and error paths (missing file, malformed front-matter, missing blocks, bad args).
#
# Usage:
#   test-parse-recipe.sh [-v | --verbose]
#
# Test scenarios:
#   Unit 1: --list — emit slot names in order of first appearance
#   Unit 2: --validate — slot-count and task-count match (clean recipe)
#   Unit 3: --validate — slot-count mismatch (warns, exits 0)
#   Unit 4: --validate — task-count mismatch (warns, exits 0)
#   Unit 5: --spec — emit raw spec block
#   Unit 6: --tasks — emit raw tasks block
#   Unit 7: --render — substitute slots + write SPEC.md + task files
#   Unit 8: --render — {!{ -> {{ escape rewrite applied at emit time
#   Unit 9: --render — unmatched slots left as-is
#   Unit 10: --render — multi-task recipe emits multiple task files
#   Unit 11: Error paths — missing file, malformed front-matter, missing blocks
#   Unit 12: Error paths — missing required arguments
#   Unit 13: --render lock file created and released
#   Unit 14: --validate name-vs-filename mismatch warning
#   Unit 15: --validate seed recipe 'fix-application' (task-026 fixture)
#   Unit 16: --validate seed recipe 'add-docs' (task-026 fixture)
#   Unit 17: --validate seed recipe 'change-member' (task-026 fixture)
#   Unit 18: --validate seed recipe 'add-api-endpoint' (task-026 fixture)
#   Unit 19: --validate seed recipe 'add-test-coverage' (task-026 fixture)
#
# Exit codes:
#   0 — all tests passed
#   1 — one or more tests failed

set -u

# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# SUT moved to canonical/scripts/interview/ in 2026-05-26 consolidation
SCRIPT="${SCRIPT_DIR}/../../canonical/aid/scripts/interview/parse-recipe.sh"

VERBOSE=0
[[ "${1:-}" =~ ^(-v|--verbose)$ ]] && VERBOSE=1

source "$(dirname "${BASH_SOURCE[0]}")/../lib/assert.sh"

# ---------------------------------------------------------------------------
# Setup: temporary workspace + fixture recipe files
# ---------------------------------------------------------------------------
TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

RECIPES_DIR="${TMPDIR_BASE}/recipes"
WORK_DIR="${TMPDIR_BASE}/work"
mkdir -p "$RECIPES_DIR"

# ---------------------------------------------------------------------------
# Fixture: clean single-task recipe (bug-fix shape)
# slot-count: 4 — bug-title, bug-description-one-sentence, reproduction-steps, intended-behavior
# task-count: 1
# ---------------------------------------------------------------------------
CLEAN_RECIPE="${RECIPES_DIR}/bug-fix.md"
cat > "$CLEAN_RECIPE" <<'RECIPEOF'
---
name: bug-fix
applies-to: bug-fix
slot-count: 4
task-count: 1
---

## spec

# Fix: {{bug-title}}

**Work:** {{work-name}}
**Created:** {{date}}
**Source:** recipe `bug-fix` via /aid-describe lite path
**Status:** Active

## Goal

Fix the defect described below.

## Context

{{bug-description-one-sentence}}

## Acceptance Criteria

- [ ] The reproduction steps no longer produce the bug.
- [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
- [ ] No regression in adjacent test suites.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Apply the fix |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| {{date}} | Created from recipe `bug-fix` | /aid-describe lite path |

## tasks

### task-001 — Apply the fix

- Type: IMPLEMENT
- Source: {{work-name}} → delivery-001
- Depends on: —
- Scope: Apply the fix for {{bug-title}}. Reproduction: {{reproduction-steps}}.
  Intended behavior: {{intended-behavior}}.
- Acceptance Criteria:
  - [ ] The reproduction steps no longer produce the bug.
  - [ ] A unit test exists that fails on the pre-fix code and passes on the post-fix code.
  - [ ] No regression in adjacent test suites.
RECIPEOF

# Unique slots in bug-fix.md body:
# bug-title, work-name, date, bug-description-one-sentence, reproduction-steps, intended-behavior
# slot-count declared = 4 but actual = 6 → mismatch (for unit 3)
# We'll create a separate clean recipe for valid slot-count tests

# ---------------------------------------------------------------------------
# Fixture: exact-count recipe (slot-count matches actual)
# slot-count: 3 — title, description, criterion
# task-count: 1
# ---------------------------------------------------------------------------
EXACT_RECIPE="${RECIPES_DIR}/exact-count.md"
cat > "$EXACT_RECIPE" <<'RECIPEOF'
---
name: exact-count
applies-to: new-feature
slot-count: 3
task-count: 1
---

## spec

# {{title}}

## Goal

{{description}}

## Acceptance Criteria

- [ ] {{criterion}}

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement the feature |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-05-24 | Initial | /aid-describe |

## tasks

### task-001 — Implement {{title}}

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: {{description}}
- Acceptance Criteria:
  - [ ] {{criterion}}
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: multi-task recipe (3 tasks)
# slot-count: 3 — resource-name, route-prefix, resource-description
# task-count: 3
# ---------------------------------------------------------------------------
MULTI_RECIPE="${RECIPES_DIR}/add-crud-endpoint.md"
cat > "$MULTI_RECIPE" <<'RECIPEOF'
---
name: add-crud-endpoint
applies-to: new-feature
slot-count: 3
task-count: 3
---

## spec

# Add CRUD endpoint: {{resource-name}}

## Goal

Add a full CRUD REST endpoint for the `{{resource-name}}` resource.

## Context

{{resource-description}}

## Acceptance Criteria

- [ ] GET / POST / PUT / DELETE endpoints exist for `/{{route-prefix}}/{{resource-name}}`.
- [ ] All endpoints are covered by integration tests.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Implement {{resource-name}} data layer |
| task-002 | IMPLEMENT | Implement {{resource-name}} API handlers |
| task-003 | TEST | Integration tests for {{resource-name}} endpoints |

## Execution Graph

| Task | Depends On |
|------|-----------|
| task-001 | — |
| task-002 | task-001 |
| task-003 | task-002 |

| Can Be Done In Parallel |
|------------------------|
| — |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-05-24 | Initial | /aid-describe |

## tasks

### task-001 — Implement {{resource-name}} data layer

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: Create the data model and repository layer for `{{resource-name}}`.
- Acceptance Criteria:
  - [ ] Data model defined for `{{resource-name}}`.
  - [ ] Repository CRUD methods implemented and unit-tested.

### task-002 — Implement {{resource-name}} API handlers

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: task-001
- Scope: Add GET / POST / PUT / DELETE handlers at `/{{route-prefix}}/{{resource-name}}`.
- Acceptance Criteria:
  - [ ] All four HTTP methods respond correctly.

### task-003 — Integration tests for {{resource-name}} endpoints

- Type: TEST
- Source: work-001 → delivery-001
- Depends on: task-002
- Scope: Write integration tests covering all four CRUD operations.
- Acceptance Criteria:
  - [ ] Happy-path tests pass for all four operations.
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: recipe with {!{ escape sequences
# ---------------------------------------------------------------------------
ESCAPE_RECIPE="${RECIPES_DIR}/escape-test.md"
cat > "$ESCAPE_RECIPE" <<'RECIPEOF'
---
name: escape-test
applies-to: *
slot-count: 1
task-count: 1
---

## spec

# {{title}}

Use {!{variable} to expand in Bash.
The pattern {!{slot-name} is a slot token.
This is a real slot: {{title}}.

## tasks

### task-001 — Document {!{variable} expansion

- Type: DOCUMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: Document the {!{variable} expansion syntax for {{title}}.
- Acceptance Criteria:
  - [ ] The {!{variable} syntax is explained.
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: task-count mismatch (declares 2 tasks but has 1)
# ---------------------------------------------------------------------------
TASK_COUNT_MISMATCH="${RECIPES_DIR}/task-count-mismatch.md"
cat > "$TASK_COUNT_MISMATCH" <<'RECIPEOF'
---
name: task-count-mismatch
applies-to: bug-fix
slot-count: 1
task-count: 2
---

## spec

# {{title}}

## tasks

### task-001 — Only one task

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: {{title}}
- Acceptance Criteria:
  - [ ] Done.
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: malformed recipe (missing applies-to)
# ---------------------------------------------------------------------------
MALFORMED_RECIPE="${RECIPES_DIR}/bad-frontmatter.md"
cat > "$MALFORMED_RECIPE" <<'RECIPEOF'
---
name: bad-frontmatter
slot-count: 1
task-count: 1
---

## spec

# {{title}}

## tasks

### task-001 — Task

- Type: IMPLEMENT
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: recipe missing ## spec block
# ---------------------------------------------------------------------------
MISSING_SPEC="${RECIPES_DIR}/missing-spec.md"
cat > "$MISSING_SPEC" <<'RECIPEOF'
---
name: missing-spec
applies-to: bug-fix
slot-count: 1
task-count: 1
---

## tasks

### task-001 — Task

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: {{title}}
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: recipe missing ## tasks block
# ---------------------------------------------------------------------------
MISSING_TASKS="${RECIPES_DIR}/missing-tasks.md"
cat > "$MISSING_TASKS" <<'RECIPEOF'
---
name: missing-tasks
applies-to: bug-fix
slot-count: 1
task-count: 0
---

## spec

# {{title}}

Just a spec, no tasks.
RECIPEOF

# ---------------------------------------------------------------------------
# Fixture: name-filename mismatch
# ---------------------------------------------------------------------------
NAME_MISMATCH="${RECIPES_DIR}/actual-name.md"
cat > "$NAME_MISMATCH" <<'RECIPEOF'
---
name: declared-name
applies-to: bug-fix
slot-count: 1
task-count: 1
---

## spec

# {{title}}

## tasks

### task-001 — Task

- Type: IMPLEMENT
- Source: work-001 → delivery-001
- Depends on: —
- Scope: {{title}}
- Acceptance Criteria:
  - [ ] Done.
RECIPEOF

# ---------------------------------------------------------------------------
# Slots JSON files for render tests
# ---------------------------------------------------------------------------
EXACT_SLOTS_JSON="${TMPDIR_BASE}/exact-slots.json"
cat > "$EXACT_SLOTS_JSON" <<'JSONEOF'
{
    "title": "My Feature Title",
    "description": "This feature adds something useful.",
    "criterion": "All acceptance tests pass."
}
JSONEOF

MULTI_SLOTS_JSON="${TMPDIR_BASE}/multi-slots.json"
cat > "$MULTI_SLOTS_JSON" <<'JSONEOF'
{
    "resource-name": "Widget",
    "route-prefix": "api/v1",
    "resource-description": "A widget is a reusable UI component."
}
JSONEOF

ESCAPE_SLOTS_JSON="${TMPDIR_BASE}/escape-slots.json"
cat > "$ESCAPE_SLOTS_JSON" <<'JSONEOF'
{
    "title": "Bash Brace Expansion"
}
JSONEOF

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 1: --list — slot names in order of first appearance ==="

out=$(bash "$SCRIPT" --list "$EXACT_RECIPE")
code=$?
assert_exit_zero "$code" "--list exits 0 on clean recipe"

# Slots in order of first appearance: title, description, criterion
assert_line_exact "$out" 1 "title" "--list: first slot is 'title'"
assert_line_exact "$out" 2 "description" "--list: second slot is 'description'"
assert_line_exact "$out" 3 "criterion" "--list: third slot is 'criterion'"

# No duplicates: title appears twice in body but listed once
line_count=$(echo "$out" | wc -l | tr -d ' ')
if [[ "$line_count" -eq 3 ]]; then
    pass "--list: no duplicate slots (3 unique from 3 declared)"
else
    fail "--list: expected 3 lines, got $line_count"
fi

# Multi-task recipe: 3 unique slots
out_multi=$(bash "$SCRIPT" --list "$MULTI_RECIPE")
multi_count=$(echo "$out_multi" | wc -l | tr -d ' ')
assert_output_contains "$out_multi" "resource-name" "--list (multi): resource-name present"
assert_output_contains "$out_multi" "route-prefix" "--list (multi): route-prefix present"
assert_output_contains "$out_multi" "resource-description" "--list (multi): resource-description present"
if [[ "$multi_count" -eq 3 ]]; then
    pass "--list (multi): 3 unique slots"
else
    fail "--list (multi): expected 3 lines, got $multi_count"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 2: --validate — clean recipe (exact counts) ==="

out=$(bash "$SCRIPT" --validate "$EXACT_RECIPE")
code=$?
assert_exit_zero "$code" "--validate exits 0 on exact-count recipe"
assert_output_contains "$out" "OK: slot-count matches" "--validate: slot-count OK"
assert_output_contains "$out" "OK: task-count matches" "--validate: task-count OK"
assert_output_contains "$out" "all checks passed" "--validate: all checks passed"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 3: --validate — slot-count mismatch (warns, exits 0) ==="

# bug-fix.md declares slot-count: 4 but has 6 unique slots
out=$(bash "$SCRIPT" --validate "$CLEAN_RECIPE" 2>&1)
code=$?
assert_exit_zero "$code" "--validate exits 0 even on slot-count mismatch"
assert_output_contains "$out" "slot-count mismatch" "--validate: slot-count mismatch warning emitted"
assert_output_contains "$out" "declared=4" "--validate: declared count shown"
# actual count includes: bug-title, work-name, date, bug-description-one-sentence, reproduction-steps, intended-behavior = 6
assert_output_contains "$out" "actual=6" "--validate: actual count shown (6 unique slots)"
assert_output_contains "$out" "instantiation continues" "--validate: warning says instantiation continues"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 4: --validate — task-count mismatch (warns, exits 0) ==="

out=$(bash "$SCRIPT" --validate "$TASK_COUNT_MISMATCH" 2>&1)
code=$?
assert_exit_zero "$code" "--validate exits 0 on task-count mismatch"
assert_output_contains "$out" "task-count mismatch" "--validate: task-count mismatch warning"
assert_output_contains "$out" "declared=2" "--validate: declared task-count 2"
assert_output_contains "$out" "actual=1" "--validate: actual task-count 1"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 5: --spec — emit raw spec block ==="

out=$(bash "$SCRIPT" --spec "$EXACT_RECIPE")
code=$?
assert_exit_zero "$code" "--spec exits 0"
assert_output_contains "$out" "{{title}}" "--spec: slot tokens preserved (not substituted)"
assert_output_contains "$out" "{{description}}" "--spec: description slot present"
assert_output_contains "$out" "## Goal" "--spec: ## Goal section in spec block"
assert_output_contains "$out" "## Acceptance Criteria" "--spec: ## Acceptance Criteria in spec block"
# tasks block content must NOT appear in spec output
assert_output_not_contains "$out" "### task-001" "--spec: task headings not in spec block"
assert_output_not_contains "$out" "## tasks" "--spec: ## tasks header not emitted"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 6: --tasks — emit raw tasks block ==="

out=$(bash "$SCRIPT" --tasks "$EXACT_RECIPE")
code=$?
assert_exit_zero "$code" "--tasks exits 0"
assert_output_contains "$out" "### task-001" "--tasks: task-001 heading present"
assert_output_contains "$out" "{{title}}" "--tasks: slot token in tasks block"
assert_output_contains "$out" "IMPLEMENT" "--tasks: task type present"
# spec block content must NOT appear
assert_output_not_contains "$out" "## Goal" "--tasks: ## Goal not in tasks output"
assert_output_not_contains "$out" "## Acceptance Criteria" "--tasks: ## Acceptance Criteria not in tasks output"

# Multi-task: all 3 tasks present
out_multi=$(bash "$SCRIPT" --tasks "$MULTI_RECIPE")
assert_output_contains "$out_multi" "### task-001" "--tasks (multi): task-001 present"
assert_output_contains "$out_multi" "### task-002" "--tasks (multi): task-002 present"
assert_output_contains "$out_multi" "### task-003" "--tasks (multi): task-003 present"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 7: --render — substitute slots + write SPEC.md + task files ==="

RENDER_WORK="${TMPDIR_BASE}/work-exact"
mkdir -p "$RENDER_WORK"

out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --slots-json "$EXACT_SLOTS_JSON" --work-dir "$RENDER_WORK" 2>&1)
code=$?
assert_exit_zero "$code" "--render exits 0 on clean recipe"

# SPEC.md must be written
assert_file_exists "${RENDER_WORK}/SPEC.md" "--render: SPEC.md created"
assert_file_contains "${RENDER_WORK}/SPEC.md" "My Feature Title" "--render: title slot substituted in SPEC.md"
assert_file_contains "${RENDER_WORK}/SPEC.md" "This feature adds something useful." "--render: description substituted in SPEC.md"
assert_file_contains "${RENDER_WORK}/SPEC.md" "All acceptance tests pass." "--render: criterion substituted in SPEC.md"
assert_file_not_contains "${RENDER_WORK}/SPEC.md" "{{title}}" "--render: slot tokens replaced in SPEC.md"
assert_file_not_contains "${RENDER_WORK}/SPEC.md" "{{description}}" "--render: description slot replaced in SPEC.md"

# task-001.md must be written
assert_file_exists "${RENDER_WORK}/tasks/task-001.md" "--render: task-001.md created"
assert_file_contains "${RENDER_WORK}/tasks/task-001.md" "My Feature Title" "--render: title substituted in task-001.md"
assert_file_contains "${RENDER_WORK}/tasks/task-001.md" "IMPLEMENT" "--render: task type preserved"

# Output message
assert_output_contains "$out" "OK: wrote ${RENDER_WORK}/SPEC.md" "--render: stdout confirms SPEC.md written"
assert_output_contains "$out" "OK: wrote ${RENDER_WORK}/tasks/task-001.md" "--render: stdout confirms task-001.md written"
assert_output_contains "$out" "render complete" "--render: completion message"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 8: --render — {!{ -> {{ escape rewrite at emit time ==="

RENDER_ESCAPE_WORK="${TMPDIR_BASE}/work-escape"
mkdir -p "$RENDER_ESCAPE_WORK"

out=$(bash "$SCRIPT" --render --recipe "$ESCAPE_RECIPE" --slots-json "$ESCAPE_SLOTS_JSON" --work-dir "$RENDER_ESCAPE_WORK" 2>&1)
code=$?
assert_exit_zero "$code" "--render (escape) exits 0"

# {!{ must be rewritten to {{ in the output
assert_file_exists "${RENDER_ESCAPE_WORK}/SPEC.md" "--render (escape): SPEC.md created"
assert_file_contains "${RENDER_ESCAPE_WORK}/SPEC.md" "Use {{variable} to expand in Bash." "--render (escape): {!{ rewritten to {{ in SPEC.md"
assert_file_contains "${RENDER_ESCAPE_WORK}/SPEC.md" "The pattern {{slot-name} is a slot token." "--render (escape): second {!{ rewritten"
# The real slot must be substituted
assert_file_contains "${RENDER_ESCAPE_WORK}/SPEC.md" "Bash Brace Expansion" "--render (escape): real slot {{title}} substituted"
# No raw {!{ must remain
assert_file_not_contains "${RENDER_ESCAPE_WORK}/SPEC.md" "{!{" "--render (escape): no raw {!{ remains in SPEC.md"

# tasks file
assert_file_exists "${RENDER_ESCAPE_WORK}/tasks/task-001.md" "--render (escape): task-001.md created"
assert_file_contains "${RENDER_ESCAPE_WORK}/tasks/task-001.md" "{{variable} expansion" "--render (escape): {!{ rewritten in task file heading"
assert_file_not_contains "${RENDER_ESCAPE_WORK}/tasks/task-001.md" "{!{" "--render (escape): no raw {!{ remains in task file"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 9: --render — unmatched slots left as-is ==="

PARTIAL_JSON="${TMPDIR_BASE}/partial-slots.json"
cat > "$PARTIAL_JSON" <<'JSONEOF'
{
    "title": "Only title filled"
}
JSONEOF

RENDER_PARTIAL_WORK="${TMPDIR_BASE}/work-partial"
mkdir -p "$RENDER_PARTIAL_WORK"

out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --slots-json "$PARTIAL_JSON" --work-dir "$RENDER_PARTIAL_WORK" 2>&1)
code=$?
assert_exit_zero "$code" "--render (partial slots) exits 0"
# Slots that had values are substituted
assert_file_contains "${RENDER_PARTIAL_WORK}/SPEC.md" "Only title filled" "--render (partial): filled slot substituted"
# Slots without values remain as {{slot-name}}
assert_file_contains "${RENDER_PARTIAL_WORK}/SPEC.md" "{{description}}" "--render (partial): unmatched slot left as-is"
assert_file_contains "${RENDER_PARTIAL_WORK}/SPEC.md" "{{criterion}}" "--render (partial): unmatched criterion left as-is"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 10: --render — multi-task recipe emits multiple task files ==="

RENDER_MULTI_WORK="${TMPDIR_BASE}/work-multi"
mkdir -p "$RENDER_MULTI_WORK"

out=$(bash "$SCRIPT" --render --recipe "$MULTI_RECIPE" --slots-json "$MULTI_SLOTS_JSON" --work-dir "$RENDER_MULTI_WORK" 2>&1)
code=$?
assert_exit_zero "$code" "--render (multi-task) exits 0"

assert_file_exists "${RENDER_MULTI_WORK}/SPEC.md" "--render (multi): SPEC.md created"
assert_file_exists "${RENDER_MULTI_WORK}/tasks/task-001.md" "--render (multi): task-001.md created"
assert_file_exists "${RENDER_MULTI_WORK}/tasks/task-002.md" "--render (multi): task-002.md created"
assert_file_exists "${RENDER_MULTI_WORK}/tasks/task-003.md" "--render (multi): task-003.md created"

# Slot substitution in all files
assert_file_contains "${RENDER_MULTI_WORK}/SPEC.md" "Widget" "--render (multi): resource-name in SPEC.md"
assert_file_contains "${RENDER_MULTI_WORK}/tasks/task-001.md" "Widget" "--render (multi): resource-name in task-001.md"
assert_file_contains "${RENDER_MULTI_WORK}/tasks/task-002.md" "api/v1" "--render (multi): route-prefix in task-002.md"
assert_file_contains "${RENDER_MULTI_WORK}/tasks/task-003.md" "Widget" "--render (multi): resource-name in task-003.md"
# No raw slot tokens remain
assert_file_not_contains "${RENDER_MULTI_WORK}/SPEC.md" "{{resource-name}}" "--render (multi): slot replaced in SPEC.md"
assert_file_not_contains "${RENDER_MULTI_WORK}/tasks/task-001.md" "{{resource-name}}" "--render (multi): slot replaced in task-001.md"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 11: Error paths — file/structural errors ==="

# 11a: recipe file does not exist
code=0
out=$(bash "$SCRIPT" --list "${RECIPES_DIR}/nonexistent.md" 2>&1) || code=$?
assert_exit_nonzero "$code" "--list missing file → exit 1"
assert_output_contains "$out" "not found" "--list missing file: 'not found' in error"

# 11b: malformed front-matter (missing applies-to)
code=0
out=$(bash "$SCRIPT" --validate "$MALFORMED_RECIPE" 2>&1) || code=$?
assert_exit_nonzero "$code" "--validate malformed front-matter → exit 2"
assert_output_contains "$out" "applies-to" "--validate malformed: 'applies-to' mentioned in error"

# 11c: missing ## spec block
code=0
out=$(bash "$SCRIPT" --validate "$MISSING_SPEC" 2>&1) || code=$?
assert_exit_nonzero "$code" "--validate missing ## spec → exit 3"
assert_output_contains "$out" "## spec" "--validate missing spec: '## spec' mentioned"

# 11d: --spec on recipe missing ## spec block
code=0
out=$(bash "$SCRIPT" --spec "$MISSING_SPEC" 2>&1) || code=$?
assert_exit_nonzero "$code" "--spec on recipe missing spec block → exit 3"

# 11e: --tasks on recipe missing ## tasks block
code=0
out=$(bash "$SCRIPT" --tasks "$MISSING_TASKS" 2>&1) || code=$?
assert_exit_nonzero "$code" "--tasks on recipe missing tasks block → exit 3"

# 11f: --render with nonexistent slots JSON
code=0
RENDER_NONJSON_WORK="${TMPDIR_BASE}/work-nonjson"
mkdir -p "$RENDER_NONJSON_WORK"
out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --slots-json "${TMPDIR_BASE}/nonexistent.json" --work-dir "$RENDER_NONJSON_WORK" 2>&1) || code=$?
assert_exit_nonzero "$code" "--render with missing slots JSON → exit 1"

# 11g: --render with missing recipe file
code=0
RENDER_NOMISSING_WORK="${TMPDIR_BASE}/work-nomissing"
mkdir -p "$RENDER_NOMISSING_WORK"
out=$(bash "$SCRIPT" --render --recipe "${RECIPES_DIR}/doesnotexist.md" --slots-json "$EXACT_SLOTS_JSON" --work-dir "$RENDER_NOMISSING_WORK" 2>&1) || code=$?
assert_exit_nonzero "$code" "--render with missing recipe → exit 1"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 12: Error paths — missing required arguments ==="

# 12a: No arguments → exit non-zero
code=0
out=$(bash "$SCRIPT" 2>&1) || code=$?
assert_exit_nonzero "$code" "no args → exit 5"
assert_output_contains "$out" "no mode specified" "no args: 'no mode specified' in error"

# 12b: --list with no file
code=0
out=$(bash "$SCRIPT" --list 2>&1) || code=$?
assert_exit_nonzero "$code" "--list with no file → exit 5"

# 12c: --validate with no file
code=0
out=$(bash "$SCRIPT" --validate 2>&1) || code=$?
assert_exit_nonzero "$code" "--validate with no file → exit 5"

# 12d: --render with no --recipe
code=0
out=$(bash "$SCRIPT" --render --slots-json "$EXACT_SLOTS_JSON" --work-dir "$WORK_DIR" 2>&1) || code=$?
assert_exit_nonzero "$code" "--render with no --recipe → exit 5"

# 12e: --render with no --slots-json
code=0
out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --work-dir "$WORK_DIR" 2>&1) || code=$?
assert_exit_nonzero "$code" "--render with no --slots-json → exit 5"

# 12f: --render with no --work-dir
code=0
out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --slots-json "$EXACT_SLOTS_JSON" 2>&1) || code=$?
assert_exit_nonzero "$code" "--render with no --work-dir → exit 5"

# 12g: unknown argument
code=0
out=$(bash "$SCRIPT" --unknown-arg 2>&1) || code=$?
assert_exit_nonzero "$code" "unknown argument → exit 4"
assert_output_contains "$out" "unknown argument" "unknown arg: 'unknown argument' in error"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 13: --render lock file created and released ==="

RENDER_LOCK_WORK="${TMPDIR_BASE}/work-lock"
mkdir -p "$RENDER_LOCK_WORK"

out=$(bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" --slots-json "$EXACT_SLOTS_JSON" --work-dir "$RENDER_LOCK_WORK" 2>&1)
code=$?
assert_exit_zero "$code" "--render (lock) exits 0"

# Lock file must NOT exist after render completes (released on exit)
if [[ ! -f "${RENDER_LOCK_WORK}/.parse-recipe.lock" ]]; then
    pass "--render: lock file released after render completes"
else
    fail "--render: lock file still exists after render completed"
fi

# Files still written correctly
assert_file_exists "${RENDER_LOCK_WORK}/SPEC.md" "--render (lock): SPEC.md written despite lock"

# Verify lock file path (lock contention) — simulate held lock
LOCK_FILE_PATH="${RENDER_LOCK_WORK}/.parse-recipe.lock"
echo "99999" > "$LOCK_FILE_PATH"
code=0
AID_PARSE_RECIPE_LOCK_TIMEOUT=2 bash "$SCRIPT" --render --recipe "$EXACT_RECIPE" \
    --slots-json "$EXACT_SLOTS_JSON" --work-dir "$RENDER_LOCK_WORK" 2>/dev/null || code=$?
assert_exit_nonzero "$code" "--render with held lock times out → exit 8"
rm -f "$LOCK_FILE_PATH"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 14: --validate name-vs-filename mismatch warning ==="

out=$(bash "$SCRIPT" --validate "$NAME_MISMATCH" 2>&1)
code=$?
assert_exit_zero "$code" "--validate name mismatch still exits 0"
assert_output_contains "$out" "declared-name" "--validate name mismatch: declared name shown"
assert_output_contains "$out" "actual-name" "--validate name mismatch: filename basename shown"

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 15: --validate seed recipe 'fix-application' ==="
# Seed recipes live at SCRIPT_DIR/../../../recipes/ (canonical/recipes/)
SEED_RECIPES_DIR="${SCRIPT_DIR}/../../canonical/aid/recipes"

SEED_FILE="${SEED_RECIPES_DIR}/fix-application.md"
if [[ -f "$SEED_FILE" ]]; then
    seed_out=$(bash "$SCRIPT" --validate "$SEED_FILE" 2>/dev/null)
    seed_code=$?
    assert_exit_zero "$seed_code" "--validate seed 'fix-application': exits 0"
    assert_output_contains "$seed_out" "OK: all checks passed" "--validate seed 'fix-application': all checks passed"
else
    fail "seed recipe file not found: $SEED_FILE"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 16: --validate seed recipe 'add-docs' ==="

SEED_FILE="${SEED_RECIPES_DIR}/add-docs.md"
if [[ -f "$SEED_FILE" ]]; then
    seed_out=$(bash "$SCRIPT" --validate "$SEED_FILE" 2>/dev/null)
    seed_code=$?
    assert_exit_zero "$seed_code" "--validate seed 'add-docs': exits 0"
    assert_output_contains "$seed_out" "OK: all checks passed" "--validate seed 'add-docs': all checks passed"
else
    fail "seed recipe file not found: $SEED_FILE"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 17: --validate seed recipe 'change-member' ==="

SEED_FILE="${SEED_RECIPES_DIR}/change-member.md"
if [[ -f "$SEED_FILE" ]]; then
    seed_out=$(bash "$SCRIPT" --validate "$SEED_FILE" 2>/dev/null)
    seed_code=$?
    assert_exit_zero "$seed_code" "--validate seed 'change-member': exits 0"
    assert_output_contains "$seed_out" "OK: all checks passed" "--validate seed 'change-member': all checks passed"
else
    fail "seed recipe file not found: $SEED_FILE"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 18: --validate seed recipe 'add-api-endpoint' ==="

SEED_FILE="${SEED_RECIPES_DIR}/add-api-endpoint.md"
if [[ -f "$SEED_FILE" ]]; then
    seed_out=$(bash "$SCRIPT" --validate "$SEED_FILE" 2>/dev/null)
    seed_code=$?
    assert_exit_zero "$seed_code" "--validate seed 'add-api-endpoint': exits 0"
    assert_output_contains "$seed_out" "OK: all checks passed" "--validate seed 'add-api-endpoint': all checks passed"
else
    fail "seed recipe file not found: $SEED_FILE"
fi

# ---------------------------------------------------------------------------
echo ""
echo "=== Unit 19: --validate seed recipe 'add-test-coverage' ==="

SEED_FILE="${SEED_RECIPES_DIR}/add-test-coverage.md"
if [[ -f "$SEED_FILE" ]]; then
    seed_out=$(bash "$SCRIPT" --validate "$SEED_FILE" 2>/dev/null)
    seed_code=$?
    assert_exit_zero "$seed_code" "--validate seed 'add-test-coverage': exits 0"
    assert_output_contains "$seed_out" "OK: all checks passed" "--validate seed 'add-test-coverage': all checks passed"
else
    fail "seed recipe file not found: $SEED_FILE"
fi

# ---------------------------------------------------------------------------
echo ""
echo ""
echo "=== Unit 20: applies-to value extraction (quoted vs bare star) ==="

# Verify the script extracts applies-to consistently — the YAML-required
# quoted-star form `"*"` (since YAML treats bare `*` as anchor reference) must
# parse without error. This guards the recipe-offer filter contract in
# state-triage.md Step 5a-1.

UNIT20_STAR_FILE=$(mktemp --suffix=.md 2>/dev/null || mktemp)
cat > "$UNIT20_STAR_FILE" <<EOF
---
name: u20-star
applies-to: "*"
slot-count: 0
task-count: 1
---

## spec

(empty spec)

## tasks

### task-001

(empty task)
EOF

u20_star_out=$(bash "$SCRIPT" --validate "$UNIT20_STAR_FILE" 2>&1)
u20_star_code=$?
assert_exit_zero "$u20_star_code" "--validate quoted-star applies-to passes"
assert_output_contains "$u20_star_out" "OK: all checks passed" "--validate quoted-star applies-to reports OK"

rm -f "$UNIT20_STAR_FILE"

test_summary
exit $?
