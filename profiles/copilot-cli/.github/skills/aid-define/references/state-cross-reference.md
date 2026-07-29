# State: CROSS-REFERENCE

Requirements are approved and features exist but cross-reference validation has not yet been completed; validate REQUIREMENTS.md against KB documents and codebase, grade findings, and create Q&A entries for gaps.

**Review:** invoke `/aid-deep-review`. It owns the dispatch, the clean context, the ledger, the gap
gate, the grade and the fix loop.

```yaml
scope:         interview-<work>-cross-ref
artifacts:     REQUIREMENTS.md and the feature decomposition
rule_set:      definition
depth:         deep
tier:          large
fix_agent:     aid-architect
```

`minimum_grade` resolves from `read-setting.sh --skill define`; the two brief sections come from
`references/reviewer-brief.md`.


**Advance:** **CHAIN** → [State: DONE] when cross-reference completes (continue inline).
