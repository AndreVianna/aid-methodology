# Delivery Issue Log -- delivery-002

> Deferred findings from per-task quick checks. Consumed by the per-delivery
> quality gate as prior context. Not graded -- grade.sh runs only on the
> gate reviewer's own issue list.

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-012 | [LOW] | Two G-01 count drifts in decisions.md found by the AC-2 probe: D20's frozen historical shortcut counts, and D4's present-tense '14 short markdown docs' against 17 hand-authored docs on disk. Real, but content corrections outside delivery-002's scope. | Resolved -- fixed under gate row 3 |
| task-012 | [MEDIUM] | Gap the mechanism reported about itself: no criterion id covers removal of a surviving legacy intent: field, so a reviewer that spots one cannot cite it and must report outside the ledger. A scope decision (add a criterion or accept), not a defect. | Resolved -- closed by criterion G-08, added under gate row 4 |
| gate cycle-1 | [MEDIUM] | Registry selector accuracy, not exhaustiveness: canonical/aid/templates/feature-inventory.md resolves to template-own by the registry's recognizers, but tests AS05/AS08 treat it as a KB-doc template whose frontmatter is the EMITTED doc's -- i.e. template-payload. G-07 still holds (it resolves to exactly one type); the type it resolves to is arguable. Recorded rather than re-engineered at the gate. | Accepted -- registry selector accuracy; G-07 holds (the file resolves to exactly one type), only which type is arguable. Out of delivery-002 scope; hands to a follow-on. |
