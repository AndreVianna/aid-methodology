# State: RE-RUN

When work `STATE.md` `## Deploy State` is Done and the user invokes `/aid-deploy` again:

1. Show package history (from work `STATE.md` `## Deploy State` History section).
2. Ask, as one question in the protocol's form (recorded first with `writeback-state.sh --ask --category Release --asked-by aid-deploy --step RE-RUN`, and answered with `--answer`): a new release (option 1, **[1] New release**) or a review of package-NNN (option 2, **[2] Review package-NNN**)? The question
   is blocking, so this step pauses on it until the user answers.
3. If [1] → reset Status to Idle, and go on with Step 1 (only unshipped deliveries eligible).
4. If [2] → read the package file, compare against current state of tasks/deliveries,
   flag any discrepancies (tasks modified after shipping, new known issues).
   Offer to regenerate release notes if content changed.

**Advance:** **CHAIN** → [State: IDLE] on [1] New release; **HALT** on [2] Review package-NNN.
