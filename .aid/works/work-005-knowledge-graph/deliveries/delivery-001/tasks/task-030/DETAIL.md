# task-030: Give `read-setting.sh` the `--probe` flag feature-004 owns

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-030/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-004-source-enumeration -> delivery-001 (Wave 1)

> **WHY THIS TASK EXISTS, AND IT IS NOT A SCOPE ADDITION.** feature-004's SPEC assigns this
> deliverable to feature-004 three separate times -- `:1585` ("`read-setting.sh` gains `--probe` |
> **feature-004** | sole caller; additive; **AC-S7/AC-20 depend on it**"), `:2064` ("additive change,
> **owned and implemented by this feature**"), and a gate-round-3 row that exists specifically to
> decide the ownership. **The Detail phase never turned that into a task.** It was found during wave-1
> execution by task-006's executor, and confirmed on disk: `read-setting.sh` contains **zero**
> occurrences of `probe`, and a grep across all 29 original task files finds no task implementing it.
> This is the same defect class as the Detail review's row 1 -- a specified, owned obligation carried
> by no task and therefore caught by no oracle -- and it is an authoring defect of mine, recorded here
> rather than absorbed silently into a neighbouring task. Registered as tech-debt **W5-8**, whose
> *oracle* half this task also closes. Created 2026-08-05 during wave-1 execution, on owner
> instruction.

**Depends on:** task-006

**Scope:**
- Add `--probe` to `canonical/aid/scripts/config/read-setting.sh`, to the contract feature-004's SPEC
  `:2064` states and nothing beyond it: it **prints `declared` / `undeclared` on stdout** using the
  **same `lookup` / `lookup_list` scanners** the existing modes use, and **warns on stderr** for any
  raw list item containing a comma (D4a). **No existing mode changes and no exit code changes** --
  that clause is part of the contract, not advice.
- Close **W5-8's oracle half** in `tests/canonical/test-graph-source-enumeration.sh`: at least one
  assertion must drive the probe through the **real** resolver, so the flag's absence FAILS. Today the
  three ignore-list states are all exercised against a stub the suite builds (`:851`
  `R="$STUB/aid/scripts/config/read-setting.sh"`) while `REAL_RESOLVER` sits defined at `:113` and
  unused for the probe -- which is exactly why AC-S7 read as closed while two of its three states were
  unreachable in production.
- Verify the user-visible consequence is actually repaired: `scan-source.sh:145` must now reach
  `declared` / `undeclared` instead of always falling to `unsupported` at `:173`, so an uncommented
  `graph.ignore` list is genuinely applied rather than reported unavailable.
- **`canonical/` only.** The render to `profiles/` and both dogfood trees belongs to `task-024`, as it
  does for `task-006`. Do not run the profile generator.

**Out of scope, explicitly:**
- **Tech-debt W5-7 is NOT fixed here.** `read-setting.sh` returns a *comment* as the value for a bare
  `key:` line carrying a trailing inline comment (whitespace-stripping consumes the anchor the
  comment-stripping substitution needs). It is pre-existing, general-purpose, latent (task-006 routed
  around it by moving the comment down one line), and re-parsing the methodology-wide settings reader
  deserves its own reviewed change rather than a drive-by inside a graph task. **If the `--probe`
  implementation reuses `lookup_list`, it inherits that behaviour -- do not "improve" it, and do not
  let a new assertion depend on the buggy shape.**
- The *settings-schema* half of the graph settings work, which feature-004's SPEC `:2064` assigns to
  feature-010/012 (its Open Item 5).

**Acceptance Criteria:**
- [ ] `--probe` prints exactly `declared` or `undeclared` on stdout, decided by the same
      `lookup`/`lookup_list` scanners -- not a second, parallel parser, since a divergent parser would
      make the probe's answer and `--path`'s answer disagree about the same file
- [ ] A raw list item containing a comma warns on **stderr**, once per offending item, and the item is
      still reported (D4a: split and reported, never silently kept) -- `significance-rules.sh`'s
      `sig_ignore_note_into` already encodes the note contract this must satisfy
- [ ] **No existing mode changes and no exit code changes.** Proven by byte-identical output on the
      pre-existing paths, not asserted: `test-read-setting.sh` still passes at its current 19/19, and
      the `--path` route over the shipped `settings.yml` returns what it returned before
- [ ] **The absence of the flag would now FAIL a test.** At least one assertion drives the probe
      through `REAL_RESOLVER` (`:113`), not through `$STUB`. Demonstrate it bites by reverting the flag
      in a scratch copy and showing that assertion -- and only it -- goes red
- [ ] `SIG_PROBE` reaches `declared` **and** `undeclared` against the real resolver, so AC-S7's three
      states are all reachable in production rather than two of three being stub-only
- [ ] An uncommented `graph.ignore` list in `settings.yml` is genuinely applied by `scan-source.sh`:
      a matching path is excluded, a non-matching path survives (not a wipe-out), and the
      ignore-unavailable notice at `:173` no longer fires
- [ ] `profiles/`, `.claude/` and `.cursor/` are untouched; the byte-identity gate for
      `read-setting.sh` is expected red until `task-024`, exactly as for `task-006`
- [ ] S1 budget declared in the header of any suite this task adds invocations to, with the count
      updated -- four of four suites in this work were found missing that declaration, so it is stated
      as a criterion rather than left to convention
- [ ] **All existing tests still pass** (IMPLEMENT type-default, `task-decomposition.md`:175). Named
      explicitly because `read-setting.sh` is the methodology-wide settings reader, not a graph script:
      a regression here lands far outside the `test-graph-*` set. Use
      `tests/canonical/select-suites.sh --run` to pick the affected suites by change set
- [ ] All section-6 quality gates pass
