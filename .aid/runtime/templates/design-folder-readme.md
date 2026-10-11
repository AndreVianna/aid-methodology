# `.aid/design/` — design seeds

A **seed** is a scoping note for work that has not started yet: the problem, the evidence, the
intended shape, and the constraints — written *before* `/aid-describe` picks it up, so the
pipeline starts from something argued rather than something remembered.

## Lifecycle

```
Entry A — hand-written
  seed written by hand  →  work scoped (/aid-describe)  →  work ships  →  seed deleted

Entry B — skill-authored, design artifacts (7)
  /aid-design-<artifact>   →  seed written / iterated in .aid/design/
  /aid-create-<artifact>   →  realized into a Knowledge Base document, then seed DELETED

Entry C — skill-authored, code artifacts (14)
  /aid-design-<artifact>   →  seed written / iterated in .aid/design/
  /aid-create-<artifact>   →  seed READ as prior context; it PERSISTS.
                              Delete it by hand when the artifact is built.

Entry D — exploratory
  /aid-brainstorm          →  seed written under a confirmed slug
                              No create counterpart. It persists until you promote it
                              into one of the entries above, or delete it by hand.
```

Deletion happens exactly where the block above says it does, and no more broadly. Entries A and
B delete their seed automatically, on realization: the design then lives in the realised code and
KB, and the seed remains recoverable from git history. Entry C's seed persists once the artifact
it seeded is built — remove it by hand. Entry D's seed persists until you promote it into one of
the entries above or remove it by hand yourself. A seed kept past its own entry's point becomes a
second, stale description of a system that has moved on.

Seeds for work that was never started are **kept** — that is the folder's whole purpose.

## What belongs here, and what does not

| Content | Home |
|---|---|
| Not-yet-started work: problem, evidence, intended design, constraints | **here** |
| Conventions and gates that bind *every* future work | `.aid/knowledge/coding-standards.md` |
| Architecture, patterns, how the system *is* | `.aid/knowledge/` |
| Known defects and their remediation | `.aid/knowledge/tech-debt.md` |
| Live pipeline state for work in flight | `.aid/works/work-NNN-*/` (transient) |

The distinction that matters: the KB describes what **is**; a seed describes what **should be**.
Whether — and when — a given seed goes away once it reaches that state is not universal; it is
governed entry by entry in the lifecycle above.
