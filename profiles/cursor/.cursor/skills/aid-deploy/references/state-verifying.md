# State: VERIFYING

Full build, tests, and lint are run against the combined scope of all selected deliveries.

### Step 3: Verify

Run full verification against the COMBINED scope of all selected deliveries:

1. **Full build** (not incremental) — using commands from `technology-stack.md § Commands`
2. **Full test suite** — ALL tests, not just ones added by selected deliveries
3. **Lint/format check** — zero warnings

All three must pass. Record results in the package file (Verification section).

▶ full build + test suite + lint starting (~30 s – 5 min depending on project)
If any fails:
- Show the failure clearly
- Ask user: fix here (minor) or loop back to aid-execute (non-trivial)?
- If fixing here: fix → re-verify (max 3 attempts, then must loop to execute)
- If looping back: set work `STATE.md` `## Deploy Status` → Idle, keep package file as Draft
✓ verification done (record actual time) — or ✗ verification failed: {reason}

Update work `STATE.md` `## Deploy Status`: Status → Packaging.

**Advance:** Next state is `PACKAGING` — when this state's work completes, router prints `Next: [State: PACKAGING] — run /aid-deploy again` and exits.
