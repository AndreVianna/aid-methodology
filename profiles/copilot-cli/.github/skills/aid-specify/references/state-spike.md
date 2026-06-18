# State: SPIKE

> **Source:** `references/handling-outcomes.md` §"Spike Needed (State 3)" (the body below is preserved verbatim from there for state-file self-containment).

Feature STATUS is `Spike Needed`; a knowledge gap must be resolved before specification can continue.

1. Update STATE.md: `**Status:** Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in SPEC.md, resume loop.

Emit pipeline pause signal (silent state-write — no output, no gate):
```
bash .github/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
bash .github/aid/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "Spike needed — awaiting investigation results before /aid-specify can continue"
bash .github/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

**Advance:** **PAUSE-FOR-USER-ACTION** → spike work happens outside /aid-specify (separate investigation task). Re-run `/aid-specify` after recording spike results in SPEC.md to continue to [State: CONTINUE].
