# Impediment — task-001

**Type:** wrong-assumption

## Description

`SPEC.md § Flow A` asserts that the KB-rooted harvest "catches a term coined only in
KB prose — the dominant case in §2". That assertion is false, and two independent
agents reproduced it.

All eight multi-word lowercase terms named in `REQUIREMENTS.md §2` — `load-bearing`,
`render-drift`, `kind-sibling`, `thin doorway`, `fat pipeline`,
`hand-authored collapse`, `lockstep`, `HOME-pinning` — are absent from the harvest
output. The cause is structural, not a tuning problem: every component word is common
English and therefore denylisted, and a KB-only phrase has spread = 1, so the
whole-phrase escape (`spread >= 2`) never fires.

The consequence is that `kb-language-lint.sh`'s `[GLOSSARY-GAP]` check cannot see the
exact class of term that motivated this work. It reliably catches CamelCase and
capitalized coinages, which is what AC-7's fixture pair actually proves. The
mechanical guarantee is therefore narrower than `SPEC.md` claims, and the full
enforcement burden for the §2 class falls on the reviewer-rubric path (Flow C).

This blocks correct completion of task-001's own remaining findings rather than being
a defect in the inventory itself. Ledger rows 2 and 9 require a decision about what
`.glossary-dismissed.txt` is for across 1008 dismissed terms, and that decision
changes shape depending on how much of the rule is mechanically enforced versus
reviewer-enforced. Fixing those rows before the question below is answered risks
doing the wrong work twice.

## Evidence

- `grep -iE 'render-drift|kind-sibling|thin.doorway|fat.pipeline|hand-authored|lockstep|HOME-pinning|load-bearing'`
  over a fresh KB-rooted harvest returns empty.
- `.aid/.temp/review-pending/task-001.md` row 1 `[HIGH]` (reviewer's independent
  reproduction) and rows 2, 9 (the dependent dismissal-scope question).
- `.aid/.temp/review-pending/task-002.md` row 2 `[MEDIUM]` — the related
  `--top` truncation question, same underlying scaling limit in `closure-check.sh`.

## Options

1. **Correct the SPEC to match reality; keep the split as built.**
   Remove the false claim, state plainly which term shapes the mechanical check
   covers (CamelCase / capitalized / hyphenated-with-uncommon-component) and which it
   cannot (multi-word all-lowercase common-word phrases), and assign the uncovered
   class explicitly to the reviewer-rubric check with its own severity. Also records
   the `--top` performance exception. Narrows the mechanical promise; keeps the rule
   enforceable overall, because the reviewer half is a real gate.
   *Cost:* one SPEC edit plus a matching `authoring-conventions.md` statement in
   task-013.

2. **Extend the harvest so the §2 class becomes mechanically detectable.**
   Add a KB-prose channel that recognizes hyphenated and quoted multi-word coinages
   regardless of component-word commonality — for example, treating a hyphenated
   compound or a first-use-quoted phrase as a candidate. Delivers the strong version
   of the guarantee.
   *Cost:* real work in `harvest-coined-terms.sh` (a shipped script with its own test
   suite), a new false-positive tuning problem, and it reopens the `closure-check.sh`
   scaling limit that already caused the `--top` deviation.

3. **Adopt an explicit term list as the mechanical source of truth.**
   Stop inferring coinage statistically for this check. Maintain a curated
   coined-term list beside the glossary; the lint asserts every listed term has a
   definition and every KB doc using an unlisted suspicious phrase is a reviewer
   matter. Makes the check exact and cheap.
   *Cost:* the list must be maintained by hand, and a coinage nobody adds to it stays
   invisible — trading statistical blind spots for human ones.

## Recommendation

**Option 1.** The work's goal is a KB a junior can read, with a rule that stops the
drift returning — not a maximally clever detector. Option 1 makes the contract honest
today and keeps both halves of the enforcement split real, and the reviewer check was
always specified to own the judgment-heavy class. Option 2 is the only path to the
strong mechanical guarantee, but it expands this work from a prose refactor into
shipped-script tuning against a scaling limit already known to bite, and it should be
its own work if it is wanted. Option 3 is a reasonable long-term shape but changes the
enforcement model the SPEC already gated at `A+`.

If Option 1 is chosen, the follow-on edits are small and known: correct `Flow A`,
add the coverage table, fold in the `--top` exception, and resolve the dismissal-scope
question (ledger rows 2 and 9) as "record a dismissal only for terms the mechanical
check can actually surface" — which becomes coherent precisely because the covered
class is then written down.
