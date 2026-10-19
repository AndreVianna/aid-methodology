# State: FEATURE-DECOMPOSITION

Requirements are approved and `REQUIREMENTS.md § 11 Features` has no feature sections yet; decompose Functional Requirements (§5) into discrete, independently implementable features, each a `### Feature NNN` subsection of §11.

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specification
bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill aid-define --name FEATURE-DECOMPOSITION
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Agent:** This is design work, not interview work. Dispatch with `subagent_type: aid-architect` (overriding the default `aid-interviewer`). Print before dispatch: `[State 5] Dispatching aid-architect for Feature Decomposition.`

▶ aid-architect starting (~2–4 min)
Read `references/feature-decomposition.md` for the full decomposition process
(analyze, propose, create folders, update meta-documents).
✓ aid-architect done (record actual time) — or ✗ aid-architect failed: {reason}

The approval of the feature list is a blocking question: this step pauses on it until the user answers.
Once it is approved, the same step writes the feature sections and updates the meta-documents
(`feature-decomposition.md` Steps 4 and 5), then goes on.

**Advance:** **CHAIN** → [State: CROSS-REFERENCE] once the feature sections are written (continue inline).
