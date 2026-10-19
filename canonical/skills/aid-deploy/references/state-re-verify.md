# State: RE-VERIFY

The user chose to fix the failed checks here. Fix them, then run the checks again.

### Step 3b: Fix and re-verify

1. Fix the failing checks (minor fixes only; anything larger loops back to aid-execute at FIX-DECISION).
2. Run the full build, the full test suite and the lint check again, as in VERIFYING Step 3, against the COMBINED scope of all selected deliveries.
3. Log any failure to `{{LEDGER}}` per `.aid/runtime/templates/reviewer-ledger-schema.md`, and run
   `bash .aid/runtime/scripts/grade.sh --explain {{LEDGER}}`.
4. Record the results in the package file (Verification section).

When every check passes (ledger is empty → grade A+): delete the ledger (`rm -f {{LEDGER}}`), update
work `STATE.yml`'s Deploy State (`deploy` key): Status → Packaging.

**Advance:** **CHAIN** → [State: PACKAGING] (continue inline) when every check passes; **CHAIN** → [State: FIX-DECISION] (continue inline) otherwise.
