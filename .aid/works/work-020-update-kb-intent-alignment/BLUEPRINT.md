# Delivery BLUEPRINT -- delivery-001: aid-update-kb Scope-Fidelity Redesign

> **Delivery:** delivery-001
> **Work:** work-020-update-kb-intent-alignment
> **Created:** 2026-07-21

---

## Objective

Redesign the `aid-update-kb` skill so its applied KB change is strictly bounded to
the scope of the user's instruction: an analyst step builds an Impact Map, an
architect step builds a minimal Scope Plan (with an explicit Not-Changing list), a
human CONFIRM gate approves scope before any edit, and scope-fidelity verification
plus bounded correction loops keep the change from widening. This delivery is a
single, coherent unit because the eight hard limits interlock — the pre-apply gate
is meaningless without the analysis that feeds it and the review guard that enforces it.

## Scope

- Add a **Pre-flight ISOLATE** step: self-isolate in the skill's own worktree on an `aid/update-kb-<ts>` branch off `master` at invocation — plain `git worktree add -b` + the generic enter step (`worktree-lifecycle.md § Step 2`), **not** the work-NNN-keyed `worktree-lifecycle.sh`/`work-initiation-gate.md` (this off-pipeline skill allocates no `work-NNN`) — mirroring the *isolation* `/aid-fix` gets at INTAKE.
- Rewrite `state-analyze.md`; add `state-scope.md` and `state-confirm.md`.
- Add scope-fidelity guardrails to `state-apply.md`, `state-review.md`, `state-approval.md`, `state-done.md`.
- Update `SKILL.md` (Pre-flight ISOLATE, 7-state machine, banners, resume table, dispatch table, hard-limits section HL-1..HL-8, `description:`) and the run-state schema.
- Re-emit `canonical/` → `profiles/*` and resync dogfood `.claude/`.
- Add tests asserting the hard-limit invariants.

**Out of scope:** the f005 review panel and `grade.sh`; the FR-33/34 aid-housekeep
boundary (strengthened, not redrawn); the human-commit invariant and
`approved_at_commit:` rule; `aid-discover`'s own state machine.

## Gate Criteria

- [ ] All Functional Requirements FR-1..FR-11 (REQUIREMENTS.md §5) are realized in `canonical/skills/aid-update-kb/` — verified by reading each state doc against its FR.
- [ ] AC-1: no edit path exists before a `Confirmed: yes` run-state value (HL-1) — verified by reading the state docs (APPLY entry precondition) + task-004 test.
- [ ] AC-2: ANALYZE/SCOPE encode instruction-traceability + a Not-Changing list; the tag-overlap net is gone (HL-2/HL-5) — verified by reading `state-analyze.md`/`state-scope.md` + task-004 test.
- [ ] AC-3: CONFIRM surfaces contradictions as questions; no silent-correction path (HL-4) — verified by reading `state-confirm.md` + task-004 test.
- [ ] AC-4: REVIEW encodes the scope-diff guard as a hard fail, deriving the edited set from disk (`git status`) vs Confirmed Scope — verified by reading `state-review.md` + task-004 test.
- [ ] AC-5: FIX loop and DONE closure are bounded to Confirmed Scope with a user-escalation branch, and a post-APPLY re-scope reverts out-of-scope edits (HL-7) — verified by reading `state-review.md`/`state-done.md`/`state-approval.md` + task-004 test.
- [ ] AC-6: new-file creation is gated on a `new-file` kind confirmed at CONFIRM (HL-6) — verified by reading `state-scope.md`/`state-confirm.md` + task-004 test.
- [ ] AC-7: f005 gate, human-commit invariant, FR-33/34 boundary intact; generated copies differ from canonical only by path-prefix — verified by task-003 parity check + `test-dogfood-byte-identity`.
- [ ] AC-8: a LIKELY/UNCERTAIN inference is surfaced as a CONFIRM question, never applied silently (HL-3) — verified by reading `state-analyze.md`/`state-confirm.md` + task-004 test.
- [ ] AC-9: session-only content (absent from the instruction, unsupported by KB/code) has no `Traces-to` and can't enter the Scope Plan; ANALYZE/SCOPE dispatch is clean-context (HL-8) — verified by reading `state-analyze.md`/`state-scope.md` + SKILL.md dispatch + task-004 test.
- [ ] AC-10: the skill self-isolates in its own worktree off `master` before any analysis/edit (FR-11) — verified by reading the SKILL.md Pre-flight ISOLATE step + task-004 test.
- [ ] All tasks in delivery-001 are Done or Canceled — verified from the Tasks lifecycle table.
- [ ] All section-6 quality gates pass — verified by `grade.sh` over the delivery gate ledger.

## Tasks

| Task | Type | Title |
|------|------|-------|
| task-001 | IMPLEMENT | Pre-flight ISOLATE (own worktree off master) + Analyst + Confirm front-end (state-analyze rewrite, state-scope, state-confirm, SKILL.md wiring incl. clean-context dispatch, run-state schema) |
| task-002 | IMPLEMENT | Scope-fidelity guardrails (state-apply, state-review, state-approval, state-done) |
| task-003 | CONFIGURE | Re-emit canonical → profiles/* + resync dogfood .claude/ + verify path/byte parity |
| task-004 | TEST | Hard-limit invariant tests covering AC-1..AC-6, AC-8, AC-9 (clean-context/no-session-bleed), AC-10 (worktree isolation) + DONE commits on the Pre-flight worktree branch (no new branch, never push master) + source-doc `Change Plan`→`Scope Plan` sweep + settings-floor verification (AC-7 parity/byte-identity is task-003's) |

## Dependencies

- **Depends on:** -- (none)
- **Blocks:** -- (none)

## Notes

Direct-authored flattened Lite work (fast path, owner-driven). Edit target is
`canonical/skills/aid-update-kb/`; generated copies are re-emitted, never
hand-edited. Owner confirmed hard limits HL-1..HL-8 and D1 = two gates (CONFIRM +
APPROVAL); `approved_at_commit:` left unchanged per owner. Detailed design in SPEC.md § Technical Specification.
