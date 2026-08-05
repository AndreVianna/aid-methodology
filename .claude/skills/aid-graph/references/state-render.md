# State: RENDER

RENDER builds `.aid/knowledge/graph.html` from the artifact EMIT wrote; it is selected after GAP-REPORT, and again from FIX when the repair touched a view input.

**Skipped entirely when `view_expected` is false** — that is, when the view's own templates
are not installed. Mark it `—` on the map, say so once in the run's output, and CHAIN
straight to VALIDATE. Nothing else in the run changes: the `V-*` rubric rows report as
skips, the human pool is `N/A`, and the expected-artifact set never demanded a page.

**This state is a router.** It writes no page markup, creates no store, detects no media
query and mounts nothing. The view's own assembly — the parse, the store creation with the
`prefers-reduced-motion` and `forced-colors` pair detected inside the shell, the control
generation, and the mount order whose table half is first and unconditional — belongs to
the view. This state invokes that assembly and reads its exit status.

Invoke the view's assembly per the view's own packaging contract, which names the reused
assembler and the three flags it is driven with. Then route on the exit code:

| Exit | Do |
|---|---|
| `0` | CHAIN to VALIDATE |
| `1` | The render failed. CHAIN to VALIDATE anyway **iff a page was written** — an invalid page is a defect this run is about to repair, and it belongs in the ledger where FIX can route it. Where no page was written, abort with the assembler's own message |
| `2` | Abort. An invocation error, not an artifact defect |

**The runtime-prerequisite text is not composed here.** Whether a network is required,
which companion files must travel with the entry point, whether a build output is involved,
and that a working drawing context is required for the live graph while the table view
stays fully usable without one — all of that is emitted by the view's own generator into
the page footer and the run's console output. Surface what it printed; neither compose it
nor suppress it.

Print: `[State: RENDER] complete.` and the page path, or the one-line reason it was skipped.

**Advance:** **CHAIN** → [State: VALIDATE] (continue inline).
