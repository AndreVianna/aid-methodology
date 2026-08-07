# State: RENDER

RENDER builds `.aid/knowledge/graph.html` **and `.aid/knowledge/table.html`** from the
artifact EMIT wrote; it is selected after GAP-REPORT, and again from FIX when the repair
touched a view input.

**Two pages, one state, the second gated on nothing of its own.** `table.html` is
task-033's own accessible surface — the relationship table alone, loaded on demand, with
no graph — and WCAG's conforming-alternate-version mechanism requires it be *reachable*
from `graph.html`, not merely present somewhere. So it is rendered in the SAME state and
under the SAME `view_expected` gate as `graph.html`: the two are two views over the one
input this skill already produced, never a second decidable fact and never a second flag.

**Skipped entirely when `view_expected` is false** — that is, when the view's own templates
are not installed. Mark it `—` on the map, say so once in the run's output, and CHAIN
straight to VALIDATE. Nothing else in the run changes: the `V-*` rubric rows report as
skips, the human pool is `N/A`, and the expected-artifact set never demanded a page.

**This state is a router.** It writes no page markup, creates no store, detects no media
query and mounts nothing. The view's own assembly — the parse, the store creation with the
`prefers-reduced-motion` and `forced-colors` pair detected inside the shell, the control
generation, and the mount order whose table half is first and unconditional — belongs to
the view. This state invokes that assembly and reads its exit status, for EACH page.

Invoke `graph.html`'s assembly per the graph view's own packaging contract
(`render-graph-view.sh`), which names the reused assembler and the three flags it is driven
with. Then invoke `table.html`'s assembly the identical way, through its own sibling
packaging contract (`render-table-view.sh` — a sibling script and a sibling producer,
`build-table-src.mjs`, keyed on its own skeleton rather than a fork of the graph view's).
Route EACH invocation's exit code independently, by the same table:

| Exit | Do |
|---|---|
| `0` | That page rendered; continue to the other page's invocation (or, once both have run, CHAIN to VALIDATE) |
| `1` | That page's render failed. CHAIN to VALIDATE anyway **iff that page was written** — an invalid page is a defect this run is about to repair, and it belongs in the ledger where FIX can route it. Where no page was written, abort with that assembler's own message |
| `2` | Abort. An invocation error, not an artifact defect |

A failure on one page's invocation does not skip the other's: `graph.html` and `table.html`
read the same `relationships.md` but assemble independently, so one page's defect says
nothing about the other's, and skipping the second on the first's failure would silently
under-produce the run's own expected-artifact set.

**The runtime-prerequisite text is not composed here.** Whether a network is required,
which companion files must travel with the entry point, whether a build output is involved,
and that a working drawing context is required for the live graph while the table view
stays fully usable without one — all of that is emitted by each view's own generator into
its own page footer and the run's console output. Surface what each one printed; neither
compose it nor suppress it.

Print: `[State: RENDER] complete.` and BOTH page paths, or the one-line reason the whole
state was skipped.

**Advance:** **CHAIN** → [State: VALIDATE] (continue inline).
