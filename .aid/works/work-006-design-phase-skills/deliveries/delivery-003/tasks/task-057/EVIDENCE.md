# task-057 EVIDENCE -- twelve foundation-artifact descriptions given a trigger clause

REQUIREMENTS **AC-12**. Slice 6 of 7: the twelve foundation-artifact skills delivery-002 authored
-- `aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}`.

## 1. Insert, not rewrite -- and one that had to become a rewrite

As in slice 5, these twelve already met AC-12's other three checks, so the change is a trigger
sentence inserted after the first sentence, preserving delivery-002's CC-9 negative routes by
construction. **Eleven** of the twelve took that treatment unchanged.

**`aid-create-cicd` did not fit.** It carries the most neighbours in the entire roster -- six --
plus the Conformance Lane disclosure feature-004 **V22** requires, and it was already 1003
characters. Inserting a 102-character trigger pushed it to **1105**, over the 1024 hard cap. The
cap is a hard check, so this one was compacted rather than merely extended: prose tightened, the
routing list turned from six full clauses into one parallel series, and the parenthetical
production notes dropped.

```
aid-create-cicd:  1003 (before) -> 1105 (insert, OVER CAP) -> 870 (compacted)
  neighbours: 6 before, 6 after, none lost
  'Conformance Lane' retained (feature-004 V22): yes
  trigger present: yes
```

This is the only description in the whole seven-slice sweep that the trigger insert pushed over
the cap, which is what AC-12's rationale predicted: median length is far below the budget, so the
reallocation fits everywhere except where the routing load is already extreme.

## 2. The twelve, verified against the YAML-folded value

| Skill | chars | trigger | banned | arrow-seq | neighbours lost |
|---|---|---|---|---|---|
| `aid-design-architecture` | 847 | yes | none | no | none |
| `aid-create-architecture` | 892 | yes | none | no | none |
| `aid-update-architecture` | 785 | yes | none | no | none |
| `aid-design-stack` | 770 | yes | none | no | none |
| `aid-create-stack` | 884 | yes | none | no | none |
| `aid-update-stack` | 810 | yes | none | no | none |
| `aid-design-testing-strategy` | 741 | yes | none | no | none |
| `aid-create-testing-strategy` | 944 | yes | none | no | none |
| `aid-update-testing-strategy` | 809 | yes | none | no | none |
| `aid-design-cicd` | 784 | yes | none | no | none |
| `aid-create-cicd` | **870** | yes | none | no | none |
| `aid-update-cicd` | 925 | yes | none | no | none |

**12/12 under the cap, 12/12 carry a trigger, 0 neighbours lost.**

## 3. feature-004 V22 still holds after the sweep

The Conformance Lane disclosure is a delivery-002 criterion that a description edit could silently
break -- checked explicitly, in the description block:

| Body | `Conformance Lane` present |
|---|---|
| `aid-create-architecture` | yes |
| `aid-create-stack` | yes |
| `aid-create-testing-strategy` | yes |
| `aid-create-cicd` | yes |

## 4. The triggers name the state the work is in

As in slice 5, stage is what a caller must choose between, so each trigger names it: **design**
when the shape is still being worked out, **create** when a seed is ready and the document does
not exist, **update** when the document exists and has drifted.
