# task-055 EVIDENCE -- twelve collapse and kind-sibling descriptions, two of them suite-pinned

REQUIREMENTS **AC-12** and FR-11 **CC-9**. Slice 4 of 7: the remaining twelve hand-authored
(`repurpose: true`) rows.

## 1. The slice, measured against the YAML-folded value

Every figure below is read from the **parsed** description, not the raw block -- the oracle
task-054 established after finding that a hyphen-broken skill name survives a raw grep but not the
YAML fold.

| Skill | chars (cap 1024) | banned forms | arrow sequence | neighbours lost |
|---|---|---|---|---|
| `aid-deploy` | 282 | none | no | none |
| `aid-monitor` | 367 | none | no | none |
| `aid-design` | 715 | none | no | none |
| `aid-prototype` | 663 | none | no | none |
| `aid-prototype-ui` | 523 | none | no | none |
| `aid-report` | 693 | none | no | none |
| `aid-research` | 729 | none | no | none |
| `aid-review` | 625 | none | no | none |
| `aid-test` | 511 | none | no | none |
| `aid-test-security` | 317 | none | no | none |
| `aid-test-performance` | 364 | none | no | none |
| `aid-test-data-quality` | 328 | none | no | none |

`aid-deploy` is the **second** of the only two descriptions in the roster that already stated a
trigger (`aid-plan`, slice 1, was the first). Its clause -- *"Use when deliveries are complete and
ready to ship."* -- is preserved verbatim rather than rewritten.

## 2. The two suite-pinned state-machine lines, moved as bytes rather than as text

`tests/canonical/test-deploy-monitor-repurpose.sh` asserts via `assert_file_contains` -- which
matches the **whole file** -- that `aid-deploy` carries the IDLE/SELECTING/VERIFYING/PACKAGING/DONE
spine (DMR10e) and `aid-monitor` the OBSERVE/CLASSIFY/ROUTE/DONE spine (DMR11d). AC-12 bans the
sequence from the **description** only, so each line moves into its body. Deleting either fails
its assertion; leaving it in the description fails AC-12; editing the suite is barred by
feature-001 AC-3.

**Both literals were extracted from the test file programmatically, never retyped**, because their
arrows are **U+2192** (`→`, not ASCII `->`) and the trailing full stop is inside the asserted
string -- so a line rebuilt from a paraphrase would move a byte and fail the assertion while
looking correct to a reader:

```
$ grep -o '"State machine:[^"]*"' tests/canonical/test-deploy-monitor-repurpose.sh
'State machine: IDLE → SELECTING → VERIFYING → PACKAGING → DONE.'
'State machine: OBSERVE → CLASSIFY → ROUTE → DONE.'
```

Placed under each body's H1, matching slices 1-3:

```
aid-deploy    1 occurrence, line 13 (frontmatter closes 9)    U+2192 arrows present
aid-monitor   1 occurrence, line 14 (frontmatter closes 10)   U+2192 arrows present
```

```
$ bash tests/canonical/test-deploy-monitor-repurpose.sh --verbose
PASS: DMR10e aid-deploy frontmatter State machine line unchanged
PASS: DMR11d aid-monitor frontmatter State machine line unchanged
```

## 3. The suite's four failures are task-062's counts, and this slice did not cause them

The suite exits 1 with **51 passed, 4 failed**. All four are the count-bearing assertions that
task-062 retunes, and none is a content failure:

```
FAIL DMR30  catalog carries exactly 58 total rows                    expected 58, got 94
FAIL DMR31  catalog carries exactly 58 canonical rows                expected 58, got 94
FAIL DMR32  zero alias rows out of the 58 carrying an alias_of field got  0 of 94
FAIL DMR33  catalog carries exactly 24 repurpose:true rows           expected 24, got 60
non-count failures: 0
```

Proven not to be this slice's doing by running the suite against the stashed tree:

```
before slice 4:  Tests passed: 51   Tests failed: 4   (the same 4 DMR3x)
after  slice 4:  Tests passed: 51   Tests failed: 4
```

Identical. `git diff origin/master -- tests/canonical/test-deploy-monitor-repurpose.sh` is **0
lines** -- the suite is neither run-as-a-gate nor edited here, exactly as task-050 recorded.

## 4. Three pairs an earlier delivery closed are still closed

Each of these was written by the feature that owns the pair under CC-9 and verified by
delivery-002's task-049. Re-checked against the folded value:

| Pair | Forward | Reverse |
|---|---|---|
| `aid-research` <-> `aid-brainstorm` (FR-7) | present | present |
| `aid-prototype-ui` <-> `aid-design-ui` (FR-6) | present | present |
| kept-versus-throwaway, stated on both sides | `aid-prototype` yes | `aid-design` yes |

And bare `aid-design` keeps what delivery-002's task-028 made it: the catch-all wording is intact
(*"when the subject has no dedicated design row of its own"*) and `architecture sketch` remains
**absent**, which is feature-005 V5's own oracle.

**Zero neighbour removals** across the slice.
