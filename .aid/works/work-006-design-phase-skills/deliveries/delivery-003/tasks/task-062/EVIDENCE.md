# task-062 EVIDENCE -- eight catalog edit sites moved together across two test files

REQUIREMENTS **AC-11**, feature-006 §4a and §4b. Closes BLUEPRINT criterion **5**.

`tests/` is outside the count guard's scan entirely, so nothing catches a stale integer below it.
**The suites themselves are the only oracle**, which is why the evidence here is a green run rather
than a grep.

## 1. The split, stated explicitly

feature-006 §4 records that an earlier framing blurred this, so it is stated plainly:

| File | assertions edited | comment blocks edited |
|---|---|---|
| (a) `tests/canonical/test-deploy-monitor-repurpose.sh` | **4** | **2** |
| (b) `tests/canonical/test-catalog-dirs-parity.sh` | **0** | **2** |

File (b) is **count-agnostic by design** -- it derives its row set from the catalog and holds no
expected total -- and that survives this work untouched. Its *header prose* did not, which is the
whole reason it appears here. Proven rather than asserted: its assertion-line count is **18 before
and 18 after**, and every changed line in it begins with `#`.

## 2. File (a) -- four assertions, each expected literal and its message

| Assertion | Was | Now |
|---|---|---|
| `DMR30` `TOTAL_ROWS` | 58 | **94** |
| `DMR31` `CANONICAL_ROWS` | 58 | **94** |
| `DMR32` paired expected sentence | `0 alias of 58 rows carrying an alias_of field` | `0 alias of **94** rows ...` |
| `DMR33` `REPURPOSE_ROWS` | 24, message `24 + 34 = 58` | **60**, message `60 + 34 = 94` |

**`DMR32` is the site a sweep misses, and its zero is not the moving part.** Its expected value
pairs the alias count with `ALIAS_FIELD_LINES`, a same-anchor control that stops *"0 alias rows"*
passing for the wrong reason: `ALIAS_FIELD_LINES` counts every row carrying an `alias_of:` key, so
at 94 rows it reads 94 and the hardcoded `58` fails. The zero itself stays **0** -- every new row
carries `alias_of: null` -- and the assertion still had to move. A sweep looking only for changed
integers in the *subject* of each assertion would have skipped it.

Plus two comment blocks: the Part 4 header (`58/58/24/34` -> `94/94/60/34`), and the *Catalog
size, by version* record, which is **appended to, never rewritten** -- it says so itself
(*"deliberately preserved, not overwritten"*). One sentence added for this work; the work-004 and
work-005 narration is byte-untouched:

> work-006 then added the design stage: 36 hand-authored rows landed (58 -> 94 rows), all of them
> repurpose:true (24 -> 60), so the generated thin-doorway count did not move and stays at 34.

## 3. File (b) -- two comment blocks, no assertion

- the `repurpose` scope note: `24 repurpose rows` -> **60**, with `3 classic re-registered
  pipeline skills` deliberately left at **3** (verified present and unchanged)
- the post-change composition block: `measured 2026-07-31` -> **2026-08-15**, `58-row catalog = 58
  canonical names + 0 aliases` -> **94 / 94 / 0**, and `24 repurpose + 34 shortcuts -- 58 - 24 =
  34` -> **60 repurpose + 34 shortcuts -- 94 - 60 = 34**, with the independent awk pass still
  reaching 34

## 4. Every figure re-derived from the catalog, not copied from the plan

```
94 = grep -c '^  - name:'                      -> 94
94 = grep -c '^    alias_of: null$'            -> 94      alias_of field lines: 94   alias rows: 0
60 = grep -c '^    repurpose: true$'           -> 60      94 - 60 = 34  (the emitting count, unmoved)
```

## 5. Both suites green, together

```
test-deploy-monitor-repurpose.sh    PASS    (55 passed, 0 failed -- was 51/4)
test-catalog-dirs-parity.sh         PASS    (485 passed, 0 failed)
```

The four `DMR3x` failures that task-050 recorded as "expected at this point in the delivery" and
task-055 proved were unchanged by the description sweep are now **closed** -- which is what
"the eight sites move together" means in practice.
