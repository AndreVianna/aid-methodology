# Requirements

- **Name:** aid-update-kb Scope-Fidelity Redesign
- **Description:** Redesign the `/aid-update-kb` skill so it analyzes and confirms scope with the user before applying any KB edit, and never changes more than the instruction requests

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-21 | Initial capture from AID DEBUG session (owner-confirmed HL-1..HL-7) | direct session |

## 1. Objective

Make `/aid-update-kb` do what it was always intended to do: given a user's
instruction describing what to update, first **analyze how and where that
change lands in the Knowledge Base** (surfacing contradictions, mismatches, and
gaps between the instruction and the KB), **confirm the correct understanding
and the exact scope with the user**, and only then apply edits — **strictly
limited to the scope of the instruction**. A change may touch one file, several
files, or create a new file, but never more than the instruction requires.

## 2. Problem Statement

A user ran `/aid-update-kb` with an instruction naming what to change, and the
skill applied a change set **broader in scope** than requested. The current
design causes this by construction: scope is built by fuzzy tag-overlap over the
KB index plus "what the prompt *implies*", with no minimality rule, and the only
human checkpoint (APPROVAL) happens **after** the edits already exist — so the
user can never veto scope before work is done. The intended analyst role
(`aid-researcher`/`aid-architect` mapping the change and confirming understanding)
is absent from the flow; those agents appear only as authors in APPLY.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID adopter / maintainer | Runs `/aid-update-kb` to keep the KB current after a change | Edits confined to exactly what they asked; visibility + veto over scope before anything is written |
| KB owner | Owns `.aid/knowledge/` accuracy | No silent, unrequested edits; contradictions surfaced, not auto-resolved |
| AID methodology (this repo) | Dogfoods and ships the skill | Redesign preserves existing quality gate, grading, human-commit invariant, and the aid-housekeep boundary |

## 4. Scope

### In Scope

- Redesign the `aid-update-kb` state machine to: `ANALYZE → SCOPE → CONFIRM → APPLY → REVIEW → APPROVAL → DONE`.
- Introduce an analyst step (Impact Map) and a minimal Scope Plan with an explicit *Not-Changing* list.
- Introduce a **pre-apply human CONFIRM gate** (the root fix).
- Add scope-fidelity verification (scope-diff guard + traceability mandate) and bound the FIX/closure loops to confirmed scope.
- Encode the seven owner-confirmed hard limits (HL-1..HL-7).
- Author changes in `canonical/skills/aid-update-kb/` and re-emit to every `profiles/*` copy + dogfood `.claude/`.

### Out of Scope

- Changing the f005 four-mandate review panel or `grade.sh` grading machinery.
- Changing the FR-33/FR-34 boundary with `aid-housekeep` (this redesign *strengthens* it via HL-5, does not redraw it).
- Changing the human-gated-commit invariant (NFR-6/C4/AC13) or the `approved_at_commit:` restamp rule.
- Modifying `aid-discover`'s own state machine (reused read-only, as today).

## 5. Functional Requirements

- **FR-1 — ANALYZE (aid-researcher).** Map the instruction onto concrete KB locations and produce an **Impact Map**: for each location, the current KB statement (cited `file:line`), its relation to the instruction (`MATCHES | CONTRADICTS | MISMATCH | GAP | ABSENT`), and a confidence tag (`CONFIRMED | LIKELY | UNCERTAIN`). Read-only; no candidate ballooning.
- **FR-2 — SCOPE (aid-architect).** Turn the Impact Map into the **minimal Scope Plan**: each item traces to an explicit instruction clause or a closure need, and is kind-tagged (`in-scope | closure | new-file`). Emit an explicit **Not-Changing** list of considered-but-excluded docs with reasons.
- **FR-3 — CONFIRM (human gate).** Before any edit, present understanding + scope plan + contradictions/questions; options `[1] Confirm`, `[2] Adjust (free text)`, `[3] Cancel`. Freeze the confirmed doc set as the scope contract.
- **FR-4 — APPLY (bounded).** Edit only confirmed Scope Plan items; sub-agent authors inherit the "targeted edit, not a rewrite" guard; remove the open-ended "add cross-references as needed" cascade.
- **FR-5 — REVIEW (scope-fidelity + quality).** A mechanical **scope-diff guard** — the edited-doc set is **derived from disk** (`git status --porcelain .aid/knowledge/`), never from APPLY's self-report, and must equal the confirmed set (hard fail otherwise) — and a **traceability mandate** (each edit maps to a confirmed item) run alongside the unchanged f005 panel.
- **FR-6 — Bounded correction.** The REVIEW FIX loop and the DONE closure re-check may only edit within confirmed scope; anything requiring an out-of-scope addition escalates to the user rather than auto-expanding. A post-APPLY re-scope that shrinks the confirmed set reverts (`git restore`) the now-out-of-scope edits before re-applying.
- **FR-7 — APPROVAL.** Show the scope-fidelity result; `[2] Additional consideration` re-scopes (routes back to CONFIRM/SCOPE), not blindly back to APPLY.
- **FR-8 — De-scope the net.** Remove the tag-overlap candidate net in ANALYZE; treat freshness verdicts as advisory context only; a `suspect`-but-uninstructed doc stays out of scope (→ `aid-housekeep`).
- **FR-9 — Schema + wiring.** Run-state gains `Impact Map`, `Scope Plan` (replaces `Change Plan`), `Confirmed`/`Confirmed Scope`/`Adjustments`; `SKILL.md` state diagram, banners, resume table, and dispatch table updated to 7 states; `description:` frontmatter updated; a Hard-Limits section added.
- **FR-10 — Propagation.** Edits authored in `canonical/`, then re-emitted via the generator to all `profiles/*` and the dogfood `.claude/` copy.

## 6. Non-Functional Requirements

- **NFR-1 Preservation.** f005 quality gate, `grade.sh`, the human-commit invariant, and the `approved_at_commit:` rule are unchanged.
- **NFR-2 Boundary integrity.** The FR-33/FR-34 non-overlap with `aid-housekeep` is preserved or strengthened.
- **NFR-3 Backward compatibility.** `aid-update-kb` has no per-skill `update-kb` override in `.aid/settings.yml`, so its floor resolves to the project's global `minimum_grade` (currently `A+`); the skill's hardcoded fallback is `A`. This work does not change the floor and introduces no settings break.
- **NFR-4 Byte/path parity.** Generated copies differ from canonical only by the profile path-prefix rewrite (test-dogfood-byte-identity stays green).

## 7. Constraints

- Edits land ONLY in `canonical/skills/aid-update-kb/`; generated copies are never hand-edited.
- The skill stays a markdown state-machine driven by reference docs; no new runtime scripts unless a hard limit cannot be enforced without one.
- The seven owner-confirmed hard limits HL-1..HL-7 govern the design (see SPEC §2).

## 8. Assumptions & Dependencies

- The generator (`canonical/EMISSION-MANIFEST.md`) renders `canonical/` → `profiles/<tool>/…`; `setup.sh` syncs dogfood `.claude/` from `profiles/claude-code/`.
- `aid-researcher` (sonnet), `aid-architect` (opus), `aid-reviewer` (sonnet) are available with pinned models.
- REVIEW reuses `aid-discover`'s `state-review.md` / `state-fix.md` machinery (f005), as today.
- **D1 resolved:** two human gates (CONFIRM for scope, APPROVAL for edits) — owner may collapse to one later (SPEC §9 D1).

## 9. Acceptance Criteria

- **AC-1** No KB file is edited before a `Confirmed: yes` exists in run-state (HL-1).
- **AC-2** A pinpoint instruction yields a Scope Plan touching only instruction-traceable docs (+ confirmed closure); a domain-overlapping but uninstructed doc appears under Not-Changing (HL-2/HL-5).
- **AC-3** An instruction that contradicts the KB produces a CONFIRM question, not a silent edit (HL-4).
- **AC-4** REVIEW hard-fails when the **disk-derived** edited-doc set ≠ Confirmed Scope (scope-diff guard).
- **AC-5** The FIX loop and DONE closure check never edit a doc outside Confirmed Scope; a post-APPLY re-scope that shrinks Confirmed Scope reverts the now-out-of-scope edits (HL-7).
- **AC-6** A new file is created only after appearing as `new-file` kind at CONFIRM (HL-6).
- **AC-7** f005 quality gate, human-commit invariant, and the FR-33/34 boundary remain intact; generated copies stay byte/path-parity clean.
- **AC-8** An item ANALYZE cannot ground as CONFIRMED-from-instruction (a LIKELY/UNCERTAIN inference) is surfaced as a CONFIRM question, never applied silently (HL-3).

## 10. Priority

Must.
