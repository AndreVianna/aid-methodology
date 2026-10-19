| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [LOW] | Fixed | tests/canonical/test-deferred-tests.sh | 1 | The suite is committed with mode 100644 while every other tests/canonical/*.sh is 100755, so a direct `./test-deferred-tests.sh` run fails with permission denied (run-all.sh invokes it through `bash` and chmods, so only direct runs break) | `git ls-files -s tests/canonical/*.sh` gives 174 at 100755 and this one at 100644; severity: judged |
