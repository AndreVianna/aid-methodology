# State: SPIKE

> **Source:** `references/handling-outcomes.md` §"Spike Needed (State 3)" (the body below is preserved verbatim from there for state-file self-containment).

Feature STATUS is `Spike Needed`; a knowledge gap must be resolved before specification can continue.

1. Update STATE.md: `**Status:** Spike Needed` with What/Why/Scope/Blocked Sections
2. Print spike details and exit

On return: read spike results, record in SPEC.md, resume loop.

**Advance:** Next state is `CONTINUE` — when spike results are recorded and the loop resumes, router prints `Next: [State: CONTINUE] — run /aid-specify again` and exits.
