# State: DONE

DONE is the terminal state. It is selected after CLEANUP CHAINs forward, confirming
that all three gated stages (KB-DELTA, SUMMARY-DELTA, CLEANUP) have each recorded
`passed` or `skipped` in `## Housekeep Status`.

---

## Closing Summary

Read the following fields from `## Housekeep Status` via `housekeep-state.sh`:

- `**Branch:**` — the `aid/housekeep-*` branch name
- `**KB Stage:**` — result for KB-DELTA
- `**Summary Stage:**` — result for SUMMARY-DELTA
- `**Cleanup Stage:**` — result for CLEANUP

Print the closing summary in this format:

```
✓ /aid-housekeep complete.

  Branch:        aid/housekeep-<slug>
  KB Stage:      <passed | skipped>
  Summary Stage: <passed | skipped>
  Cleanup Stage: <passed | skipped>

  Per-stage commits are on branch aid/housekeep-<slug>.
  Next step: push the branch and open a PR when you are ready to merge.

    git push -u origin aid/housekeep-<slug>
    gh pr create --base master --head aid/housekeep-<slug>

  (The skill never pushes — see REQUIREMENTS.md C3.)
```

---

## Write DONE state

Update `## Housekeep Status` via `housekeep-state.sh`:

```bash
bash .agents/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "DONE"
bash .agents/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
bash .agents/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

**Advance:** **HALT**.
