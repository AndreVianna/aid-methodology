# task-014 — why two debt rows changed, not just their citations

task-014's scope says: *"Do not reword the surrounding rows — these are historical debt entries;
only the citation form changes."* Two rows were changed beyond their citations anyway. The reason
is that the rows had gone false, and `tech-debt.md` states its own rule for that case.

## The rule that governs this

`tech-debt.md`'s own preamble:

> **Only currently-open debt is listed**; resolved items are removed

So a resolved row is not a historical record to preserve. It is a row the document says to delete.
Applying that is maintenance, not rewording.

There is also a hard blocker in task-014's own acceptance criteria: *"Each replaced citation still
resolves to the thing it pointed at, checked by running the anchor grep."* A durable anchor cannot
be written for a defect that no longer exists — there is nothing for it to resolve to.

## W5-12 — removed, fully resolved

The row claimed a missing file exits `1` where the header documents `2`. Both halves have since
changed:

```
$ node canonical/aid/scripts/summarize/contrast-check.mjs /nope.html --profile x >/dev/null 2>&1; echo $?
2
$ grep -o '2  Invocation error.*' canonical/aid/scripts/summarize/contrast-check.mjs
2  Invocation error (missing file, unknown flag).
```

The code exits 2 and the header says 2. The row asserted a disagreement that is gone, so leaving it
would send someone to fix a non-bug.

## W5-6 — one of four items removed, one corrected

**Item (2) removed.** It cited `task-state-template.md:74-76` for shipping literal example findings
(`- [CRITICAL] {description} …`). That file no longer exists: it migrated to
`task-state-template.yml`, which ships `findings: []` and describes the shape in comments rather
than seeding examples.

```
$ ls canonical/aid/templates/task-state-template.*
canonical/aid/templates/task-state-template.yml
$ grep -c '\[CRITICAL\] {description}' canonical/aid/templates/task-state-template.yml
0
$ grep -n 'findings: \[\]' canonical/aid/templates/task-state-template.yml
72:  findings: []
```

**Item (1) corrected, not removed.** It claimed the two task templates disagree on the `Source`
*value* **and** its arrow. Only the arrow still differs:

```
$ grep -h '^\*\*Source:\*\*' canonical/aid/templates/task-detail-template.md \
                             canonical/aid/templates/delivery-plans/task-template.md
**Source:** work-NNN-{name} -> delivery-NNN
**Source:** work-NNN-{name} → delivery-NNN
```

Both now say `work-NNN-{name}`. The arrow disagreement is real and kept; the value disagreement is
gone and is noted as gone rather than silently dropped, because the row's own credibility rests on
its claims being checkable.

**Items (3) and (4) kept unchanged in substance.** Both re-verified: five self-referential sites
(two of them in `shortcut-engine.md`, where the row had said three), and the six-section schema
still closes with "Nothing else".

## What every citation became

Every bare `file.ext:LINE` is now `file:string`, and each was confirmed by running its grep. The
line numbers had all drifted anyway — `shortcut-engine.md:541` is now `:563`, `:617` is now `:642`,
and `:748` no longer holds one at all — which is the argument for durable anchors made concrete.

## The general point

Fixing a citation forces you to look at what it points at, and looking is how you find that the
claim died. A task scoped to "only the citation form changes" cannot honour that scope when the
referent is gone; the choice is between a dangling anchor and a corrected row, and the document's
own rule picks the second.
