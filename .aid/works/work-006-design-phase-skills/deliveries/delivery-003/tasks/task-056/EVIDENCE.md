# task-056 EVIDENCE -- nine planning-artifact descriptions given a trigger clause

REQUIREMENTS **AC-12**. Slice 5 of 7: the nine planning-artifact skills delivery-001 authored --
`aid-{design,create,update}-{roadmap,backlog,mvp}`.

## 1. What was actually missing, and why this is an insert rather than a rewrite

Measured before touching anything, these nine already satisfied **three** of AC-12's four
authoring checks: every one was under the 1024 cap (444-650), none carried a banned form, none
carried an arrow sequence, and each already led with its user-facing outcome. The single thing
missing was the **trigger** -- `grep` for a `Use ... when` clause across all nine returned **0**.

So the change is a surgical **insert of one sentence after the first sentence**, not a rewrite.
That matters for correctness, not just economy: delivery-001 wrote each of these descriptions'
negative routes under FR-11 **CC-9**, and delivery-002's task-049 verified them. An insert
preserves every one of those names **by construction**, where a rewrite would preserve them only
if re-checked afterwards. Placing the trigger after the first sentence also keeps the outcome
leading, which is AC-12 check 4.

## 2. The nine, verified against the YAML-folded value

| Skill | chars (cap 1024) | trigger | banned | arrow-seq | neighbours lost |
|---|---|---|---|---|---|
| `aid-design-roadmap` | 738 | yes | none | no | none |
| `aid-create-roadmap` | 605 | yes | none | no | none |
| `aid-update-roadmap` | 739 | yes | none | no | none |
| `aid-design-backlog` | 765 | yes | none | no | none |
| `aid-create-backlog` | 559 | yes | none | no | none |
| `aid-update-backlog` | 609 | yes | none | no | none |
| `aid-design-mvp` | 639 | yes | none | no | none |
| `aid-create-mvp` | 609 | yes | none | no | none |
| `aid-update-mvp` | 697 | yes | none | no | none |

**9/9 now carry a trigger; 0 neighbours lost.**

## 3. The triggers follow the lifecycle stage, because that is what distinguishes the three

The nine are three artifacts times three stages, and the stage is precisely what a caller has to
choose between -- so each trigger names the state the work is in rather than restating the
artifact:

- **design** -- the thinking is not settled yet: *"when the direction for the coming horizons is
  still being argued out, and you want it settled as a seed before it becomes the roadmap"*.
- **create** -- a seed exists and the document does not: *"when a roadmap seed is ready and the
  project needs its roadmap document written for the first time"*.
- **update** -- the document exists and has drifted: *"when the roadmap already exists and
  something has moved between horizons"*.

`aid-create-mvp` and `aid-update-mvp` are phrased against the roadmap's `## MVP` **section**
rather than a document of their own, which is the CC-5 distinction their bodies already carry:
they register no document.
