| # | Severity | Status | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|
| 1 | [LOW] | Fixed | tests/conversation/protocol-checks.md | 48-51 | Check 3 adds a rule the protocol does not state: "A technical term appears in a question only after the user has used it", so a judge could fail a run on a harmless term, a stricter test than FR-17 rule 3 and Rule 3 of question-protocol.md, which only say to assume the lower level and give deeper detail on request | question-protocol.md lines 32-35 and REQUIREMENTS.md FR-17 rule 3 state no such term-first test; severity: judged |
