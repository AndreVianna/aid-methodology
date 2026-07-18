# Delivery Issue Log -- delivery-001

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-011 | [HIGH] | Pre-existing test_no_shutil test failure: task-004 regression. Test_server_py.py::TestSourceInvariants::test_no_shutil (line 277-279) fails because task-004 added `import shutil` + `shutil.which('bash')` for PATH probe. Task-011 commit message acknowledges this but defers as 'out of scope', leaving broken test in suite. The overly broad substring check cannot distinguish read-only shutil.which() from mutating operations. | Fixed (commit 4b153899): server.py bash-probe hand-rolled to mirror server.mjs; `import shutil` removed; TestSourceInvariants 14/14 green. |
