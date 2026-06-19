# State: VERIFYING

Full build, tests, and lint are run against the combined scope of all selected deliveries.

### Step 3: Verify

Run full verification against the COMBINED scope of all selected deliveries:

1. **Full build** (not incremental) — using commands from `technology-stack.md § Commands`
2. **Full test suite** — ALL tests, not just ones added by selected deliveries
3. **Lint/format check** — zero warnings

All three must pass. Record results in the package file (Verification section).

▶ full build + test suite + lint starting (~30 s – 5 min depending on project)
✓ verification done (record actual time) — or ✗ verification failed: {reason}

### Log failures to schema ledger

For each failing check, append a row to `.aid/.temp/review-pending/deploy.md` per
`.agents/aid/templates/reviewer-ledger-schema.md`:

| Check type | Severity |
|---|---|
| Build failure (compile error, link error, build exit non-zero) | `[CRITICAL]` |
| Test failure (any test fails) | `[HIGH]` |
| Lint/format warning or error | `[MEDIUM]` |

One row per distinct failing check/test/warning. Example row:
```
| 1 | [HIGH] | Pending | src/Foo.cs | 42 | test TestBar fails: NullReferenceException | `dotnet test` output: "Test 'TestBar' failed: System.NullReferenceException" |
```

After logging failures, run grade.sh on the ledger:

```bash
bash .agents/aid/scripts/grade.sh --explain .aid/.temp/review-pending/deploy.md
```

If any failures logged (grade below A+):
- Show the failure clearly
- Ask user: fix here (minor) or loop back to aid-execute (non-trivial)?
- If fixing here: fix → re-verify → re-run grade.sh (max 3 attempts, then must loop to execute)
- If looping back: set work `STATE.md` `## Deploy State` → Idle, keep package file as Draft
  Delete ledger: `rm -f .aid/.temp/review-pending/deploy.md`

If all pass (ledger is empty → grade A+): proceed to PACKAGING.
Delete ledger on success: `rm -f .aid/.temp/review-pending/deploy.md`

Update work `STATE.md` `## Deploy State`: Status → Packaging.

**Advance:** **CHAIN** → [State: PACKAGING] (continue inline).
