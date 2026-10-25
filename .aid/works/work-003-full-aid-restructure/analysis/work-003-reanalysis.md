# Work-003 re-analysis (Q199)

Delivery-003 is paused at its gate. This report measures the instruction surface the agent reads,
names why it keeps growing, and proposes how the plan changes. Measured on `57268a3b8` with a
throwaway script over every `canonical/**/*.md` file.

## What the agent reads

| Measure | Value |
|---|---|
| Instruction files / lines | 300 files, 45,147 lines |
| Always loaded (`rules.md`) | 238 lines, every session |
| Skills | 112; 25 have a `SKILL.md` over 200 lines |
| Lines one skill pulls in (rules.md + its `SKILL.md` + every file it cites, one level; an upper bound, since some references load per step) | median 1,319; `aid-discover` 7,186, `aid-update-kb` 3,881, `aid-describe` 3,527, `aid-execute` 3,497 |
| Largest single files | `aid-discover` `state-generate.md` 1,098; `shortcut-engine.md` 1,029; `aid-housekeep` `state-kb-delta.md` 890 |

Current skill practice keeps a skill's main file well under about 500 lines, loads detail per step,
writes only what the model does not already know, and puts fixed steps in scripts. Many AID skills
load several times that.

## Where it comes from

| Source | Size | Already scheduled? |
|---|---|---|
| History in instructions: task, feature, requirement, decision and work ids, and "retired / previously / added by" wording | 826 lines in 188 files (`shortcut-engine.md` 43, `elicitation-engine.md` 37, `state-kb-delta.md` 26) | No. A September commit (`627cdbdc4`) removed dated history from every prompt; nothing tests for it, so it came back, partly written by this work's own tasks |
| The same sentence in several files | 200 sentences of 10+ words repeated across files (1,126 copies) and 1,047 near-identical pairs. Most sit in the 15 `aid-design-*` skills (about 85 shared sentences each) and the generated `aid-create-*` / `aid-update-*` wrappers | Partly: delivery-012 retires the shortcut engine and the action-kind wrappers. The `aid-design-*` family is not scheduled |
| Fixed steps written as prose | 35 code blocks of 2+ commands the agent must type in order (106 command lines), most in `aid-housekeep`, `shortcut-engine.md`, `aid-execute` | No |
| Fix rounds that add rules | Gate fix rounds 1 to 9 of delivery-003 each added text; two were true root-cause changes (the jargon approval written into `shortcut-engine.md`, and a rule of mine that contradicted another) | No |

## Why it keeps growing

1. **Rules without enforcement.** "No history" and "no work id" are tested only for `.aid/knowledge/`
   (`test-kb-no-work-ids.sh`). G-17 ("every line earns its place") is a review criterion, applied to
   changed lines, with the sweep of existing files set for delivery-014 (Q188). Nothing fails when an
   instruction file grows, repeats another, or gains history.
2. **Behaviour fixed by wording.** A sample failure was read as "the rule is not clear enough", so text
   was added. The question that finds the root cause, why a clear rule was not followed, was not asked.
3. **Reviews check the new lines, not the file.** A correct addition passes even when the file grows
   and repeats itself.
4. **Long paths through long files.** Sample 002-14 runs `rules.md`, the question protocol,
   `aid-orchestrate` and the 1,029-line engine, about 2,000 lines plus helper output. Each extra rule is
   one more chance to slip; it fails a different way each run while the short samples pass 3 of 3.

## Proposed change to the plan

Insert one delivery now, before delivery-003 is closed: **instruction hygiene**.

- **Ratchet tests** under `tests/canonical/`, in the shape of the coverage baseline: a per-file count
  that may only go down, and zero for any new file.
  - no history: the id and wording patterns above;
  - no repeats: a sentence of 10+ words in two instruction files;
  - size: a line budget per file, and one for `rules.md`.
- **The full history cleanup** of every instruction file (the maintainer's request), each removal
  checked to keep its rule.
- **`rules.md` slimmed** to what every session needs.
- **Fix rule for the gate:** a fix names the root cause first; a fix that adds lines states why no
  existing line could change instead; a review checks the whole file it touches.
- **The `aid-design-*` repeats** move to one shared reference.
- **Fixed command sequences** become one script call where a writer mode or a small script can carry
  them.

Then one full sample run (10 samples, 3 runs) closes delivery-003 and the hygiene delivery together.
Files that delivery-012 retires (`shortcut-engine.md`, the action-kind wrappers) get the history
cleanup only, not a rewrite. Deliveries 004 to 014 keep their order, and their changes must keep the
ratchets green, so their rewrites shrink files instead of growing them.

Moving delivery-011 and 012 (the retirements) earlier would remove the engine and about 60 wrapper
skills sooner, but 011 depends on delivery-010; that reordering is a separate decision.
