| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [LOW] | Fixed | tests/conversation/run.py | 1155 | The `--briefs-dir` help text still says the folder holds "simulated-user.md and judge.md", but run.py now also reads protocol-checks.md from it and exits 2 when it is missing, so a user reading `--help` is not told why a run exits 2 | line 1155 vs lines 1202-1209; severity: judged |
