# task-372 (task-037b): The flow-chart builder reads "ASK, then HALT" as one ending

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 372 --field State.

**Type:** FIX

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37 (Q158: fix the builder now)

**Depends on:** --

**Why:** `skill-steps.md` writes a hand-off or a final approval as **ASK** then **HALT**: the step asks
the user, then the run stops. The site flow-chart builder (`site/scripts/lib/flow-graph/advance.mjs`,
rule 4) treats the ASK clause and the HALT clause as two terminal clauses, warns "multiple terminal
clauses ... keeping last", and keeps only HALT. The charts then lose that the user is asked before the
stop. The generator gives 73 such warnings (68 on the shortcut engine's APPROVAL-HALT, plus DONE,
FIX-DECISION, RE-RUN, ROUTE and SELECTING).

**Scope:**
- `site/scripts/lib/flow-graph/advance.mjs`: an ASK terminal clause followed by a HALT terminal clause
  in the same Advance (`ASK then HALT`, `ASK, then HALT`, `**ASK** then **HALT**`) is ONE ending: the
  node is an exit, and the ending records that it asks first (for example `advanceType: 'ASK'` with the
  stop kept, or a flag; follow what the chart renderer and the flow JSON already support, and say which
  you chose). No warning for that pair. Two real terminal clauses (for example HALT and HALT, or a
  hand-off on two different arms) still warn as today.
- Whatever reads the terminal (the flow JSON writer and the chart renderer under `site/`) shows that
  the step asks before it stops, if it has a way to show an advance type on an exit; if it has none,
  keep the data in the flow JSON only and say so.
- `site/scripts/__tests__/`: cases in the style of the existing advance tests: the pair gives one exit
  that asks first and no warning; HALT alone is unchanged; two plain terminal clauses still warn. Each
  new case fails against a copy of the builder without the change.
- Do not change any skill or template file.
- **Test step:** `(cd site && npm run gen:skills && npm run gen:reference && npm test)`. Report the
  generator's warning count before and after, and which flow JSONs changed and how.

**Acceptance Criteria:**
- [ ] No "multiple terminal clauses" warning remains for an ASK-then-HALT ending; the generator's warning
      count drops by those warnings and by no others.
- [ ] Every ASK-then-HALT step's chart node is an exit that records it asks first.
- [ ] HALT-only endings and the other flow JSONs change in no other way.
- [ ] The new test cases pass, and each fails against the builder without the change.
- [ ] `(cd site && npm test)` passes after regeneration.
