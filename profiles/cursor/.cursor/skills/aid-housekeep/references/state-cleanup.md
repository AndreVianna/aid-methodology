# State: CLEANUP

> **STUB NO-OP — delivery-001 skeleton.**
> This file is a placeholder body for the CLEANUP stage. It will be replaced
> by the real body in delivery-003 (task-012 / feature-004).
> The stub does NO work, makes NO commit, and does NOT pause. It records
> `skipped` and CHAINs straight through to DONE so that a delivery-001 run
> terminates cleanly at DONE.
>
> A stub `skipped` is distinct from a *runtime* skip that a fully-implemented
> stage might decide (e.g., nothing to clean up). The real body will classify
> stale work-area artifacts and present a per-item confirmation checklist.

---

## Stub body

Write the following fields to `## Housekeep Status` via `housekeep-state.sh`.
Do not hand-edit `## Housekeep Status` directly.

```bash
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "CLEANUP"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Cleanup Stage" --value "skipped"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
bash .cursor/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Print:
```
[State: CLEANUP] stub no-op — skipped (delivery-001; real body in delivery-003).
```

No work is performed. No commit is made.

---

**Advance:** **CHAIN** → [State: DONE] (continue inline).
