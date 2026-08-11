# Review discipline for this work — the traps, and the instruction changes they forced

> **Raised:** 2026-08-10, after five `/aid-specify` FIX cycles on `feature-009` graded
> `D+ → D → D- → D → D+`.
> **Consumers:** every reviewer dispatch and every FIX pass in this work. Both roles read this
> before starting.

---

## The measurement

| Cycle | Findings | HIGH | Grade | SPEC lines after the fix |
|---|---|---|---|---|
| 1 | 11 | 1 | `D+` | 405 |
| 2 | 7 | 2 | `D` | 429 |
| 3 | 14 | 7 | `D-` | 449 |
| 4 | 11 | 3 | `D` | 472 |
| 5 | 11 | 1 | `D+` | — |

The artifact grew **52%** (310 → 472 lines) and ended at the grade it started at. Every finding was
fixed and verified on disk before the next cycle ran; none was deferred, accepted or waived.

## The trap, stated exactly

Findings fall into two kinds, and they need **opposite** responses:

| | **Specification defect** | **Prose defect** |
|---|---|---|
| What is wrong | a decision is wrong, missing, contradictory, or cannot be implemented | a supporting claim about something outside the artifact is inaccurate |
| Correct response | fix the decision | **delete the sentence** |
| What I did instead | fixed it | wrote a *more precise* supporting claim |

Cycle 5 was roughly **4 specification defects and 7 prose defects**. All eleven were answered by
editing prose, and seven of those edits added new claims about files this SPEC does not change.

**Why the loop cannot converge under that response.** A justification sentence cites a file the
artifact does not own. That file's contents are not the artifact's to control, and each cite is a new
checkable claim. So the defect surface grows monotonically with the number of findings answered, and
the bar is zero findings. The same mechanism, in a different artifact, produced
`IMPEDIMENT-plan-review.md`.

**The structural cause, which is this work's own subject.** The ledger has no way to say *"this
content should not exist."* Every row says a thing is wrong, which invites making it right. A
reviewer who believes a paragraph is pure liability has to phrase that as an inaccuracy, and the
fixer then repairs the inaccuracy and keeps the paragraph.

---

## Instruction change 1 — the reviewer classifies the response

Every finding row's `Description` **must** open with one of two tags:

- **`[SPEC]`** — a decision is wrong, missing, contradictory, or unimplementable. Fixing it changes
  what gets built.
- **`[PROSE]`** — a supporting, motivating, historical or prior-art claim is inaccurate. Fixing it
  changes nothing about what gets built.

For every `[PROSE]` finding the reviewer answers one further question in `Evidence`:

> **Load-bearing?** Would deleting this sentence lose any content a task `DETAIL.md` or a gate
> criterion needs? **yes** / **no**.

`no` is the reviewer's recommendation to **delete**, and it is not a lesser finding — it is the more
useful one.

**Severity is assigned to the specification, not to the prose.** An inaccurate cite inside a
paragraph that could be deleted without loss is at most `[MINOR]`, however wrong the cite is. Grading
prose accuracy at `[MEDIUM]` is what made the loop expensive: it forced attention onto the sentences
that should simply have gone.

## Instruction change 2 — the fixer deletes before it explains

Seven rules, in priority order. `D1` outranks everything below it.

- **D1 — Answer a `[PROSE]` / not-load-bearing finding by deleting the sentence.** Never by
  correcting it. If a paragraph has been found wrong twice, delete the paragraph; a third repair is
  not a better repair.
- **D2 — Never answer a finding by adding prose.** Permitted responses: delete, narrow, or state a
  decision. "Add a paragraph explaining why" is the move that caused this.
- **D3 — Cite only what the artifact owns.** For a feature SPEC that means the requirements it
  carries and the files its own affected-artifact inventory lists. A cite to anything else is a
  hostage to a file this artifact cannot control, and buys nothing a reader needs.
- **D4 — No prior art, no measured-origin asides, no "why not the alternative" paragraphs.** The
  decision and its consequences are specification. The argument that led to it belongs in the Q&A
  entry that recorded the decision, which is where it already is.
- **D5 — After fixing, the artifact must not be longer.** If it is, the fix added justification.
  Check the line count and say what it is.
- **D6 — A class sweep still applies** (`FR-E2`), and a deletion sweeps like a correction: if a
  deleted claim was restated elsewhere, the restatement goes too.
- **D7 — One normative home per mechanism, inside the artifact too.** A mechanism is specified in
  exactly one section; elsewhere it may be **named** but no behaviour, value, threshold or artifact
  name is restated. **Measured on `feature-009`'s SPEC: 49 of 81 findings over eight cycles were
  internal contradictions**, and the cause was that seven of ten mechanisms were described in three or
  more sections, so every design change needed a sweep across all of them. This is `Q30(a)`'s
  restatement convention applied *within* an artifact rather than across artifacts — the same defect
  class, and it went unnoticed for eight cycles because the convention was written for the
  cross-artifact case.


---

## What this is evidence for, beyond this work

This is a **recall-and-response** gap, not a precision gap, and it is exactly what `feature-009`
exists to measure. The subsystem has one verdict vocabulary — *is this correct?* — and needs a second:
*should this exist?* Without the second, a rigorous reviewer and a diligent fixer can co-operate to
make an artifact steadily worse while every individual exchange is defensible.

Recorded here rather than only in a commit message because both roles have to read it before their
next pass, and because it is the sharpest empirical evidence this work has produced about its own
subject.
