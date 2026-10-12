# State: RE-RUN

When work `STATE.md` `## Deploy State` is Done and the user invokes `/aid-deploy` again:

```
[State: RE-RUN] — Prior release found; confirming whether to start a new release or review.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [✓ DONE ] → [● RE-RUN ]
```

1. Show package history (from work `STATE.md` `## Deploy State` History section).
2. Ask: **[1] New release** or **[2] Review package-NNN**?
3. If [1] → reset Status to Idle, proceed with Step 1 (only unshipped deliveries eligible).
4. If [2] → read the package file, compare against current state of tasks/deliveries,
   flag any discrepancies (tasks modified after shipping, new known issues).
   Offer to regenerate release notes if content changed.

**Advance:** **HALT** (terminal — user re-invokes the skill when ready).
