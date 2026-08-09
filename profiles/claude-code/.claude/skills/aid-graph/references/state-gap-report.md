# State: GAP-REPORT

GAP-REPORT reports which structurally significant source artifacts no Knowledge Base node covers, writes that finding to a ledger and to the artifact's own frontmatter, and routes the reader onward; it is selected after EMIT has written the final post-Pass-2 table.

**This state reports. It never gates, never fixes and never opens a ticket.** Four
independent mechanisms make that structural rather than conventional, and the third of them
is this document's own single unconditional `**Advance:**` line — there is no route from here
to FIX, to a blocked lifecycle, or to a non-zero skill exit.

## Step 1 — the previous ledger, if there is one

Read `.aid/.temp/review-pending/graph-kb-gaps.md` if it exists, so existing row numbers,
severities and descriptions are preserved and only `Status` moves. An absent file means this
is cycle 1 and every row starts `Pending` — which, while the ledger does not survive skill
DONE, is **every** run.

## Step 2 — the detector

```bash
node .claude/aid/scripts/graph/detect-kb-gaps.mjs \
  --table .aid/knowledge/relationships.md \
  --nodes .aid/.temp/graph/nodes.tsv \
  --output .aid/.temp/review-pending/graph-kb-gaps.md
```

Add `--previous <path>` iff a previous ledger was found in step 1.

The coverage predicate has exactly one implementation, shared with the view so the ledger and
the view's coverage lens can never disagree, and the detector holds it rather than restating
it. So do the severity derivation, the row form and the candidate-kind assertions: every one
of them is the detector's, and this state re-derives none.

Two things about its interface are worth stating because they decide routing:

- **Every path is explicit and there is no baked-in default.** The four flags above are the
  whole write mode.
- **`media-nodes.tsv` is named by no flag**, and that is deliberate: it is not a candidate
  source. Do not pass it.

| Exit | Do |
|---|---|
| `0` | continue — **whatever the gap count.** Zero gaps and five hundred gaps are the same exit status. The count is on stdout and never in the exit code |
| `2` | A usage, argument or input-contract error — a malformed candidate stream, or a row of the wrong kind. No ledger was written. Report it and abort: this is a defect in an upstream stream, not a gap |

There is no exit `1`. A gap is not a failure.

## Step 3 — the routing block

Print it. It is the reader's only notice of what survives this run, and printing it **before**
DONE deletes the ledger is what keeps the reader from discovering the shortfall by looking for
a file that is gone.

```
KB gaps: <n> (<h> HIGH, <m> MEDIUM, <l> LOW) — <k> with no relationships at all
         most in one subtree: <path> (<c>)
Ledger:  .aid/.temp/review-pending/graph-kb-gaps.md   (not graded; the run succeeded)
         NOT RETAINED past skill DONE until the ledger-retention change lands.
         Durable copy of the findings: kb_gaps: in .aid/knowledge/relationships.md
         Reproduce the ledger:  /aid-graph --reset
Rows typed by a project-extension relation: <n>   (coverage is evaluated over the core vocabulary only)

Route onward — /aid-graph does not fix gaps:
  Targeted, one gap or a named few:
    /aid-update-kb "<what to document, naming the artifact and the KB document>"
  Broad sweep, many gaps or a whole subsystem:
    /aid-housekeep          # KB-DELTA re-discovers drifted docs against the repo
```

Omit the subtree line when no group holds more than one row.

**The reproduce command is a full re-run, not a read-back**, and calling it that is the
point: `--reset` discards the digest comparison and runs the pipeline again, the bounded
agent pass included, recomputing the gap set and overwriting `kb_gaps`. No mode of the
detector takes that list as input. Reproducible-on-demand is a weaker guarantee than
retained.

**The two named targets are the skills that own Knowledge Base repair.** This state runs
neither of them, opens no ticket, and writes nothing into `.aid/knowledge/STATE.md` — the
last would breach the run's read-only guarantee outright.

## Where the gap count is deliberately not recorded

Not in the artifact's `## Coverage notes`. That section sits inside the byte-identity
guarantee, and a gap count legitimately varies between runs over an unchanged tool, so a count
there would break the guarantee for a reason that is not drift. The count goes to stdout,
which is transient; the gap **list** goes to `kb_gaps`, which is durable and outside the
boundary by design.

Print: `[State: GAP-REPORT] complete.`

**Advance:** **CHAIN** → [State: RENDER] (continue inline).
