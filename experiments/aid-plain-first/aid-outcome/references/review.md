# Independent whole-result review

Use a separate reviewer that did not implement the result. Where the host can
start a fresh reviewer session directly, dispatch it without an extra model
whose only job is to relay the answer. Otherwise use the host's independent
reviewer. For Codex trials, use a saved session as the tested workaround for
the observed ephemeral subagent startup failure and verify the reviewer starts.
Protect the selected Codex home's saved records.
Do not alter hook configuration, trust, access controls or user approvals to
make a review run. If independence or a required safeguard is unavailable,
stop and report the missing evidence.

Give the reviewer a concise brief: the one current requirements document,
relevant project facts and source paths, changed files and baseline, checks
with actual results, and known gaps or constraints. The brief is a map, not
proof: the reviewer must inspect the actual result, requirements, relevant KB
and evidence, and may open additional material or request checks. Do not hide
contrary evidence or limit review to changed lines or tests.

Review completeness against every agreed outcome, correctness and testability,
maintainability, and rendered usability where applicable. Record each outcome
as verified, failed or unverified with evidence; missing checks remain
unverified. Record findings in the existing seven-column ledger and use the
existing severity rules and grade script. Resolve relevant global, type and
file criteria; consult the authoritative schema or other guidance whenever
the compact brief is insufficient. An empty ledger or grade alone does not
prove coverage. Report unsupported claims and unavailable review honestly.

The ledger columns are `# | Severity | Status | Doc | Line | Description |
Evidence`. Severity is `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]` or
`[MINOR]`; status is `Pending`, `Fixed`, `Recurred`, `Accepted`, `OOS` or
`Invalid`. Classify severity using the project's actual criteria, not this
short list. A ledger contains only the table.
