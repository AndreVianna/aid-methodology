# Delivery Issue Log -- delivery-003

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-050 | [HIGH] | **The delivery's directory count is off by one throughout, and this delivery is the one that states it.** BLUEPRINT criterion 4 and its tasks expect **112** skill directories and "eighteen curated skills that own no row"; the true figures are **111** and **17**. Cause established, not guessed: `aid-graph` was removed upstream (`b8b01b1b`) and it was a **curated, rowless** skill -- `git show b8b01b1b^:...shortcut-catalog.yml \| grep -c '^  - name: aid-graph$'` -> 0, and the directory count moved 76 -> 75 in that commit -- so the removal shifted directories by one and rows by zero. The corrected arithmetic closes exactly: `111 = 94 rows + 17 curated`. The other three figures are unaffected and independently confirmed by `build-shortcut-skills.py --check` (`OK: 34 doorway(s) up to date, 60 repurpose row(s) skipped, 0 orphan(s)`). Every count-bearing surface in tasks 059, 062, 069 and 065-068 must state **111**/**17**, and each must re-derive from the file rather than copy this row. | Open |
