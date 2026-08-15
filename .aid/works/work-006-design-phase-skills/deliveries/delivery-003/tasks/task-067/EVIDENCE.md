# task-067 EVIDENCE -- the test landscape and the tech-debt figures brought to the finished roster

feature-006 §7's KB table, rows `test-landscape.md` and `tech-debt.md`. Closes two more of
BLUEPRINT criterion **9**'s documents and their share of criterion **4**.

## 1. `test-landscape.md` -- the only place in the KB that describes what tasks 062 and 063 changed

A new section records all four `DMR*` keys at their new values (94 / 94 / 94-paired / 60), and
explains the two things a future reader would otherwise get wrong:

**Why `DMR32`'s expected value is a sentence rather than a zero.** It pairs the alias count with
`ALIAS_FIELD_LINES`, a same-anchor control counting every row that carries an `alias_of:` key.
With a bare `0`, a catalog that had moved, emptied or re-keyed the field would satisfy the
assertion **for the wrong reason** -- the zero would be free. Pairing it is what forces the
assertion to move when the row count moves, even though the alias count itself stays 0.

**Which suite each "count-agnostic by design" note belongs to.** `test-catalog-dirs-parity.sh` is
the count-agnostic one -- it derives its row set from the catalog, holds no expected total, and its
**assertions are never edited for a count**; only its header prose is. `test-deploy-monitor-repurpose.sh`
is the asserting one. Recording the pair together is what stops a later reader "fixing" the
inconsistency by making them match.

The coverage re-bootstrap is recorded with its new shape -- 95 / 95 / 95, 94, and 34 / 34 / 34,
**144 rows added** -- and with the reason it is a re-capture rather than a row edit.

**The three 34s are written as counts, never as key-set identities.** `CDP{i}` is indexed by a
row's *position*, so inserting rows mid-file shifts *which* indices carry `e`/`f`/`g` while leaving
*how many* unchanged. A `comm` over the two key sets legitimately reports both additions and
removals; a sentence claiming the sets are identical would be false, and this is the document a
future reader would trust. The section also records why: a `repurpose: true` row logs `CDP{i}e` as
an exemption and stops, and a `log` is neither `PASS:` nor `FAIL:`, so the collector never indexes
it -- counting raw output reads 94 and misreports the delta, which is the mistake task-063 made
once before catching it.

That unmoved 34 is stated as what it is: a **second, independent witness** that the generated
doorway quantity did not move, derived from the coverage inventory rather than from the catalog.

## 2. `tech-debt.md` -- one figure moved, and one closure deliberately not made

`W1-11`'s machine-derived half **had already been rewritten upstream**: it now records that the
repo-wide count guard was retired, that `test-doc-counts.sh` covers the public-facing docs, and
that `canonical/` and `.aid/knowledge/` markdown is governed by criterion `G-01` -- a reviewer
criterion, not a guard that runs. So the *"today 76 skills"* phrasing the DETAIL expected to move
no longer exists.

The one live figure that did move is the guard-blind sidecar count (mode **M2**, a bare `sidecars`
noun no regex matches): *"all 75 sidecars emit"* -> **111**, matching the regenerated flow sidecars
task-064 produced.

**`W1-11` is not closed here, and that is deliberate.** Its two survivors both stand:

- **`kb.html`** still states the old corpus total. That half closes in **task-071**, when the
  regeneration actually lands -- not before. Hand-patching the assembled file is explicitly not the
  remedy, because a hand edit is neither current nor reproducible and the next assembler run
  overwrites it.
- **`W1-2`'s hand-measured per-shape populations** are still prose, and stay open regardless of
  anything this work does.

A resolved item is removed from the inventory and its detail; an item with a surviving half stays,
with the surviving half stated. `W1-11` has two, so it stays.

`bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` is **green**.
