# Delivery Issue Log -- delivery-001

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-011 | [HIGH] | Pre-existing test_no_shutil test failure: task-004 regression. Test_server_py.py::TestSourceInvariants::test_no_shutil (line 277-279) fails because task-004 added `import shutil` + `shutil.which('bash')` for PATH probe. Task-011 commit message acknowledges this but defers as 'out of scope', leaving broken test in suite. The overly broad substring check cannot distinguish read-only shutil.which() from mutating operations. | Fixed (commit 4b153899): server.py bash-probe hand-rolled to mirror server.mjs; `import shutil` removed; TestSourceInvariants 14/14 green. |

## Post-gate dogfood UI findings (found by live browser dogfooding after the A+ gate)

> The gate + per-task quick-checks validated the backend thoroughly but could not see runtime UI behavior (the "UI tests" are static Python parses of home.html). These were caught by clicking the live dashboard and fixed post-gate, then verified in a real browser via Playwright.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-006 (feature-002) | [MEDIUM] | Grade `<select>` reused `.interval-input` (built for numeric inputs); its native `<option>` popup renders on a system-white background, so the dark-theme light `--text` was light-on-white / unreadable. | Fixed (commit d7364e4f): `.interval-input option { color: var(--text); background-color: var(--bg-elev); }`. Playwright-verified readable + selectable. |
| task-006/008/010 (feature-002/005/006) | [HIGH] | Edit buttons for project name, project description, task rename, and task notes did NOTHING: each handler set the editing flag then called a render whose poll-loop-preservation guard (`if (editing) return;`) bailed before drawing the editor. 4 of 6 interactive edit surfaces broken; pipeline rename + grade unaffected. | Fixed (commit 41ea5d28): one-shot "explicit render" flags consumed inside each guard so edit-entry bypasses it while the poll loop still preserves in-progress edits; +14 static regression tests. **Playwright-verified**: all 6 surfaces open their editor from a clean state; name persisted a full write round-trip to `.aid/settings.yml` and re-rendered from disk. |
| task-003 (feature-001) | [MINOR] | `write-setting.sh` surgically rewrites the whole `  <key>: <value>` line, so it DROPS any trailing inline comment on the edited line (confirmed isolated: `  name: OldName  # keep me?` -> `  name: NewName`). Editing a setting from the dashboard silently strips that line's inline comment (e.g. `# set during /aid-config INIT`). Value is correct; only the inline comment is lost. Byte-preservation gap (KI-001-adjacent). | Open (deferred, decision pending): accept comment-loss on edited lines, OR teach `write-setting.sh` to preserve a trailing ` #...` comment on the rewritten line. Non-blocking; surfaced by browser dogfooding. |
