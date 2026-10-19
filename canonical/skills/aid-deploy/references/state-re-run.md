# State: RE-RUN

When work `STATE.md` `## Deploy State` is Done and the user invokes `/aid-deploy` again:

```
[State: RE-RUN] — Prior release found; confirming whether to start a new release or review.
aid-deploy  ▸ you are here
  [✓ IDLE ] → [✓ SELECTING ] → [✓ VERIFYING ] → [✓ PACKAGING ] → [✓ DONE ] → [● RE-RUN ]
```

1. Show package history (from work `STATE.md` `## Deploy State` History section).
2. Ask, through the question protocol: **[1] New release** or **[2] Review package-NNN**? The question
   is blocking, so this step pauses on it until the user answers.
3. If [1] → reset Status to Idle, and go on with Step 1 (only unshipped deliveries eligible).
4. If [2] → read the package file, compare against current state of tasks/deliveries,
   flag any discrepancies (tasks modified after shipping, new known issues).
   Offer to regenerate release notes if content changed. The run then ends here (HALT): the user
   re-invokes the skill when ready.

**Advance:** **CHAIN** → [State: IDLE] on [1] New release. On [2] Review package-NNN the run ends here (HALT).
