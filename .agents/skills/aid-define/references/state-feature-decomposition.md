# State: FEATURE-DECOMPOSITION

Requirements are approved and `REQUIREMENTS.md § 11 Features` has no feature sections yet; decompose Functional Requirements (§5) into discrete, independently implementable features, each a `### Feature NNN` subsection of §11.

Emit pipeline phase (silent state-write only — no output; a failed write stops the run):
```
bash .aid/runtime/scripts/execute/writeback-state.sh --step --skill aid-define --name FEATURE-DECOMPOSITION
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specification
bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Agent:** This is design work. Dispatch with `subagent_type: aid-architect`.

▶ aid-architect starting (~2–4 min)
Read `references/feature-decomposition.md`. The worker does Steps 1 and 2 only (analyze, propose): it returns
the proposed feature table and its open questions, and never asks the user. If it fails, say why in one plain line.

The main conversation puts the approval of the feature list to the user (`feature-decomposition.md` Steps 2 and 3),
through the question protocol. It is a blocking question, and an approval: record it first with `--ask --category Approval --covers` as `feature-decomposition.md` Step 2 says, and bring the step detail up to date with `--step` (the list is proposed, the approval is open, with its id). Set the lifecycle to `Paused-Awaiting-Input` and the pause reason to that open question through the writer. This step pauses on it where it stands until the user approves or declines; an approval cannot be skipped. Record the answer with `--answer --id <id>` and set the lifecycle back to `Running`. An adjustment is applied and the list
is put again. Once the list is approved, the same step dispatches aid-architect again to write the feature
sections and update the meta-documents (`feature-decomposition.md` Steps 4 and 5), then goes on.

**Advance:** **CHAIN** → [State: CROSS-REFERENCE] once the feature sections are written (continue inline).
