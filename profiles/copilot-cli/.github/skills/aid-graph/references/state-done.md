# State: DONE

DONE lowers the write fence, reports what the run produced, and deletes everything the run created that is not an artifact; it is selected after VISUAL-GATE (normal completion) or directly from STALE-CHECK on a `CURRENT` verdict (idempotent completion).

## First, on both variants: lower the fence

```bash
bash .github/aid/scripts/graph/kb-write-fence.sh --verify
```

This runs on **every** exit path — the idempotent one and the failing ones included — and
because `--verify` fails closed with no snapshot, a route that skipped raising the fence
cannot pass it silently.

| Exit | Do |
|---|---|
| `0` | continue |
| `1` | Print every offending path the script named **and its closing summary verbatim**: the Knowledge Base was modified outside the allowlist, so this run's artifacts must not be trusted. Do not soften this into a warning, and do not print a success line under it |
| `2` | No snapshot: the fence was never raised. Report it as a defect in the run, not as a clean result |

---

## Normal completion (after VISUAL-GATE)

Print, in this order:

1. **The artifact paths** — `.aid/knowledge/relationships.md`, and `.aid/knowledge/graph.html`
   where the view was in scope.
2. **The three grades** — Machine, Human, Overall — and the resolved floor they were measured
   against.
3. **The check inventory, including every `skip`.** Repeat it here rather than leaving it
   behind in VALIDATE's output: a grade whose skips are out of sight reads as stronger
   evidence than it is.
4. **The ceiling verdict, iff EXTRACT warned** — the same node total and threshold it already
   printed. Do not recompute either, and do not re-read the carrier: this is a repeat of a
   verdict the run has already reached.
5. **How to open the view**, where one exists.

Then delete everything this run created that is not an artifact:

```bash
rm -f .aid/.temp/review-pending/graph.md .aid/.temp/review-pending/graph-kb-gaps.md
rm -rf .aid/.temp/graph/
rmdir --ignore-fail-on-non-empty .aid/.temp/review-pending/ 2>/dev/null || true
```

**Both ledgers go, and the gap ledger is not an exception.** Every reviewer ledger in this
methodology is deleted at skill DONE, and a skill-local exception would be worse than an
exception written into the shared schema — a schema amendment is visible to everyone reading
the schema, while a skipped delete is invisible from it. The shortfall this creates is real
and is named at its true size rather than hidden: while the ledgers do not survive, the
gap findings' Status can never move off `Pending`, so every run is cycle 1.

**What survives is the `kb_gaps` list in `relationships.md`'s frontmatter** — durable,
outside the byte-identity boundary by design, and read by the view. The reader was told all
of this at GAP-REPORT, which printed the command that regenerates the ledger, so an absence
here is never a surprise. Do not print a second copy of that block.

Exit with success — or with failure iff the fence check failed.

---

## Idempotent completion (after a `CURRENT` STALE-CHECK)

Print:

```
✅ .aid/knowledge/relationships.md and .aid/knowledge/graph.html are current.
   Every staleness input compared unchanged:
     {the per-component values STALE-CHECK printed}
   Nothing to do. Re-run with /aid-graph --reset to force regeneration.

[State: DONE]
```

Where the view is not in scope, name only the artifact that exists.

Then remove the scratch the enumeration produced:

```bash
rm -rf .aid/.temp/graph/
```

**No durable file is written on this path** — no artifact byte changes, no agent dispatch
occurred, and no ledger was written. The enumeration did write allowlisted scratch, which
this step removes; that is why the guarantee is stated as *nothing durable* rather than
*nothing at all*.

**Do not re-warn about the ceiling here.** The ceiling verdict is a function of the node set,
the node set is a function of the inputs, and the inputs are exactly what this verdict just
found unchanged.

Exit with success.

---

**Advance:** **HALT**.
