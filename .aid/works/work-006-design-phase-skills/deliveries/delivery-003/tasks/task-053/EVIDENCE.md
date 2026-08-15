# task-053 EVIDENCE -- curated on-demand descriptions, including the only two at or over the cap

REQUIREMENTS **AC-12**, whose check **1** names both of this slice's outliers explicitly. Slice 2
of 7.

## 0. The slice is eight, not nine

The DETAIL names nine: `aid-graph`, `aid-housekeep`, `aid-summarize`, `aid-update-kb`,
`aid-set-connector`, `aid-unset-connector`, `aid-read-ticket`, `aid-create-ticket`,
`aid-update-ticket`. **`aid-graph` no longer exists** -- removed upstream by `b8b01b1b`, the same
commit behind task-050's directory-count correction and task-052's deleted-suite finding. The
slice is the remaining **eight**. This is the third consequence of that one removal to surface in
this delivery, which is why task-050 logged it against the whole delivery rather than as a local
note.

## 1. The cap problem, re-measured at execution time rather than trusted

The DETAIL requires every figure here to be re-measured. Measured against the current files:

| Skill | before | after | note |
|---|---|---|---|
| `aid-update-ticket` | **1098** | **668** | breached the 1024 hard cap outright (AC-12 recorded 1096; re-measured 1098) |
| `aid-create-ticket` | **1008** | **630** | sat 16 characters under the cap (AC-12 recorded 1006) |
| `aid-read-ticket` | 811 | 650 | third of the three, same pattern |

It was **one fix applied three times**, not three unrelated edits. All three had spent their
budget on the same four things -- a grammar line, a resolution ladder, a per-part behaviour table
and a confirm-gate narrative -- each of which the body already restates. The description keeps the
outcome and the trigger; the mechanics stay in the body where they already were.

Full slice:

| Skill | chars (cap 1024) | banned forms | arrow sequence | neighbours lost |
|---|---|---|---|---|
| `aid-housekeep` | 758 | none | no | none (`/aid-update-kb` kept) |
| `aid-summarize` | 640 | none | no | none |
| `aid-update-kb` | 550 | none | no | none |
| `aid-set-connector` | 686 | none | no | none (`/aid-discover` kept) |
| `aid-unset-connector` | 474 | none | no | none (`/aid-discover` kept) |
| `aid-read-ticket` | 650 | none | no | none |
| `aid-create-ticket` | 630 | none | no | none |
| `aid-update-ticket` | 668 | none | no | none |

**Zero neighbour removals**, so no removal needed a stated reason (FR-11 **CC-9**).

## 2. The one description-anchored assertion in the ticket suite

`tests/canonical/test-ticket-skills-structural.sh` runs its content assertions against the
**whole file**, so most of them read body text and are indifferent to a description rewrite. **T54**
is not: it matches the literal ``closed enum `description | comment | status` ``, and that exact
substring occurs **only** in `aid-update-ticket`'s description -- the body's own statement puts
`**closed enum**` emphasis markers between the noun and the backtick, so it does not match.

Resolved by keeping the literal in the shortened description, which is also the right call on
merit: which parts the skill can change is exactly the triggering information a caller needs.

```
$ grep -cF 'closed enum `description | comment | status`' canonical/skills/aid-update-ticket/SKILL.md
1
$ bash tests/canonical/test-ticket-skills-structural.sh
Tests passed: 88      Tests failed: 0
$ git diff origin/master -- tests/canonical/test-ticket-skills-structural.sh
0 lines                                   # the suite was not edited
```

`T02`, `T08` and `T14` additionally require each of the three to keep a **folded** `description: >`
scalar; the rewriter preserves the folded form, and all **3/3** still carry it.

## 3. Three state-machine sequences relocated, with one deliberate normalisation

`aid-housekeep`, `aid-summarize` and `aid-update-kb` each carried a transition sequence in the
description. Each is relocated into the body rather than deleted -- the sequences are real
contracts, and `docs/glossary.md` and `docs/faq.md` quote them.

**The normalisation, and why it is safe.** These three were the *only* files in the roster using
the label `State-machine:` (hyphen); **47** use `State machine:` (space). The relocated lines use
the space form. Two independent reasons, and the second is what the DETAIL predicted:

- `docs/` quotes the **sequences** (`PREFLIGHT → KB-DELTA` -> 1 hit, `ANALYZE -> SCOPE` -> 1 hit)
  but **never** the label -- `grep -c 'State-machine:' docs/glossary.md` -> **0**. So nothing
  downstream quotes the form being changed.
- `site/scripts/lib/flow-graph/extract-residual.mjs` rung R1 tests `/^State machine:/i`, which the
  hyphen form would **not** match. Relocating verbatim would have left R1 silent and quietly
  falsified the DETAIL's own downstream prediction.

```
aid-housekeep    1 occurrence, line 19 (frontmatter closes 15)   R1 form present
aid-summarize    1 occurrence, line 18 (frontmatter closes 14)   R1 form present
aid-update-kb    1 occurrence, line 17 (frontmatter closes 13)   R1 form present
hyphen form remaining anywhere in canonical/skills/:  0 files
sequences docs/ quotes still intact:  PREFLIGHT → KB-DELTA yes,  ANALYZE -> SCOPE yes
```

Each is placed under the body's H1, matching the placement task-052 used for `aid-describe`, so
the sweep has one rule rather than a per-skill judgement.

**Downstream effect, expected and owned elsewhere.** R1 will now fire for these three (and for
`aid-describe` from slice 1), changing `site/src/data/skill-flows/<name>.flow.json`. That is why
the site regeneration (task-064) is a descendant of every slice rather than a sibling. This task
regenerates nothing: `git status --porcelain site/src/data/skill-flows/` -> **0 entries**.

## 4. Frontmatter shape, scope, and isolation

All eight parse as YAML with `name:` equal to their directory and a non-empty `description`
(8/8), and `bash tests/canonical/test-frontmatter-lint.sh` passes. As in slice 1, the
`test-graph-skill-registration.sh` / `GR01.a3` oracle this task cites no longer exists; the
assertion is discharged directly by the YAML parse above.

```
$ git status --porcelain canonical/skills/ | wc -l
8    # aid-create-ticket aid-housekeep aid-read-ticket aid-set-connector
     # aid-summarize aid-unset-connector aid-update-kb aid-update-ticket
$ git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/   clean
$ git status --porcelain profiles/ .claude/ .cursor/                                    0 entries
```
