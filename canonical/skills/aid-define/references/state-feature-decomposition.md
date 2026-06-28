# State: FEATURE-DECOMPOSITION

Requirements are approved and no feature folders exist yet; decompose Functional Requirements (§5) into discrete, independently implementable features with SPEC.md files.

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Phase --value Interview
bash canonical/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-define
bash canonical/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Agent:** This is design work, not interview work. Dispatch with `subagent_type: aid-architect` (overriding the default `aid-interviewer`). Print before dispatch: `[State 5] Dispatching aid-architect for Feature Decomposition.`

▶ aid-architect starting (~2–4 min)
Read `references/feature-decomposition.md` for the full decomposition process
(analyze, propose, create folders, update meta-documents).
✓ aid-architect done (record actual time) — or ✗ aid-architect failed: {reason}

**Advance:** **CHAIN** → [State: CROSS-REFERENCE] when decomposition completes (continue inline).
