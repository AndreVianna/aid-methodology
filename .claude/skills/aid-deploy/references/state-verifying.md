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

For each failing check, append a row to `{{LEDGER}}` per
`.aid/runtime/templates/reviewer-ledger-schema.md`:

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
bash .aid/runtime/scripts/grade.sh --explain {{LEDGER}}
```

If all pass (ledger is empty → grade A+): delete the ledger on success (`rm -f {{LEDGER}}`),
update work `STATE.yml`'s Deploy State (`deploy` key): Status → Packaging, and proceed to PACKAGING.

If any failures logged (grade below A+): show the failures clearly. The user's fix-or-loop decision
is taken at FIX-DECISION (see `references/state-fix-decision.md`); the Deploy State stays Verifying.

**Advance:** **CHAIN** → [State: PACKAGING] (continue inline) when every check passes; **CHAIN** → [State: FIX-DECISION] (continue inline) when any check fails.
