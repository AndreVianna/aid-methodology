# State: STALE-CHECK

STALE-CHECK decides whether this run must regenerate, and names which input changed if it must; it is selected immediately after ENUMERATE.

Run — passing `--reset` through iff the invocation carried it:

```bash
bash .claude/aid/scripts/graph/graph-stale-check.sh
```

**Currency here is content-addressed, not date-addressed, and not approval-addressed.**
No Knowledge Base file may be written by this skill, so there is nowhere to stamp a
last-run date; and a date could not see a source-tree change in any case. The record
therefore lives in the artifact this skill already owns — `relationships.md`'s own
frontmatter — and no new state file is introduced. The digest's components, their file
sets, the exclusions and the composite's shape are all in `graph-stale-check.sh --help`,
which is their single home.

One consequence of that design is worth naming, because it is a *difference* rather than a
detail: there is **no "current but unapproved" branch** here. `/aid-summarize` has one,
because its currency is a date plus an approval scalar. This skill's currency is content,
so a re-run on an unchanged project is a true no-op rather than a re-request for sign-off.

Route on the **verdict token, which is the script's LAST stdout line**:

| Verdict | Do |
|---|---|
| `FIRST_RUN` | CHAIN to EXTRACT |
| `STALE` | CHAIN to EXTRACT |
| `CURRENT` | mode = IDEMPOTENT: CHAIN to DONE's idempotent variant |

The script exits `0` for **every** verdict — the decision is informational, not a failure.
A non-zero exit is a different thing entirely and never a verdict:

| Exit | Do |
|---|---|
| `1` | A required input could not be read. Abort, printing the script's message |
| `2` | A usage error. Abort |

**Surface the attribution, do not paraphrase it.** When the verdict is `STALE`, the script
has already printed which components changed and the value of each. Show those lines: churn
the user can attribute to a named input is the whole reason the digest is composite rather
than a single opaque hash.

**Carry the recomputed digest forward.** The script prints the composite on its
`graph_inputs_digest:` line. EMIT hands that exact string to the emitter, which writes it
into the artifact's frontmatter. Do not recompute it in another state, and do not
reformat it.

Print: `[State: STALE-CHECK] complete.`

**Advance:** **CHAIN** → [State: EXTRACT] on `STALE` or `FIRST_RUN`; **CHAIN** → [State: DONE] (idempotent variant) on `CURRENT`. Both continue inline.
