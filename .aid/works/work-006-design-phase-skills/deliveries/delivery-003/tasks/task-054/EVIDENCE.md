# task-054 EVIDENCE -- twelve `document`-family and `query` descriptions

REQUIREMENTS **AC-12** and FR-11 **CC-9**. Slice 3 of 7: the twelve hand-authored
(`repurpose: true`) rows of the `document` family plus the single `query` row.

## 1. A defect this slice caught, in its own first attempt

The rewriter wrapped each description with `textwrap.fill`, which **breaks on hyphens**. A folded
YAML scalar rejoins its lines with a **space**, so a skill name split across a wrap point does not
survive the fold:

```
raw block:   ... that is /aid-
             update-kb's territory ...
folded value: ... that is /aid- update-kb's territory ...     <- a broken name
```

Four names were damaged this way, all in this slice -- `/aid-update-kb` and `/aid-create-diagram`
in `aid-create-document`, `/aid-create-document` in `aid-create-diagram`, and
`/aid-create-document` in `aid-document-changelog`. **A grep over the raw block reports them
present**, because the substring `/aid-create-` is there; only a check against the *folded* value
sees the break. That is what makes this worth recording rather than just fixing: the obvious
oracle is the wrong one.

Both halves are fixed. The wrapper now passes `break_on_hyphens=False`, and **every neighbour
assertion in this slice is made against the YAML-parsed description**, which is what a consuming
agent actually reads. A repo-wide scan confirmed slices 1 and 2 were unaffected:

```
$ <scan all canonical/skills/*/SKILL.md folded descriptions for /aid[a-z-]*- [a-z]>
before: 4 broken (all in this slice)          after: NONE
```

## 2. The slice, measured

| Skill | chars (cap 1024) | banned forms | arrow sequence | neighbours lost |
|---|---|---|---|---|
| `aid-create-document` | 826 | none | no | none |
| `aid-update-document` | 600 | none | no | none |
| `aid-create-diagram` | 666 | none | no | none |
| `aid-document` | 694 | none | no | none |
| `aid-ask` | 716 | none | no | none |
| `aid-document-decision` | 624 | none | no | none |
| `aid-document-architecture` | 639 | none | no | none |
| `aid-document-guideline` | 612 | none | no | none |
| `aid-document-standard` | 610 | none | no | none |
| `aid-document-runbook` | 602 | none | no | none |
| `aid-document-tutorial` | 604 | none | no | none |
| `aid-document-changelog` | 587 | none | no | none |

## 3. The seven genre siblings are one template, instantiated seven times

Each delegates to `/aid-create-document` with a genre hint, so this is a single trigger-clause
template with the genre named -- not seven independent authoring decisions:

> Write **{genre}** in one pass -- *{gloss}*. Use this skill when you already know the document
> you need is *{genre}*, and want it drafted now rather than planned. [...] A thin kind-sibling of
> `/aid-create-document`, which defines its full behavior.

The three non-siblings (`aid-create-document`, `aid-update-document`, `aid-create-diagram`) and
`aid-ask` are authored individually.

**Arrow-separated outlines became prose.** Four glosses carried them -- an ADR's
`Context -> Decision -> Alternatives -> Consequences`, a guideline's
`principle -> rationale -> do/don't`, a standard's `rule -> scope -> compliance -> exceptions`, a
runbook's `trigger -> diagnostic -> remediation -> escalation`. These are document outlines rather
than state machines, but they are indistinguishable from one to any mechanical arrow check, so
each is now written as prose ("the context, the decision itself, the alternatives considered, and
the consequences"). No description in the slice carries an arrow sequence.

**`aid-ask` was the genuine reallocation case**, not a trim: 861 characters of query contract in
the description while the body restates it. The description now carries the outcome and the
trigger at 716; the contract stays in the body.

## 4. Nothing delivery-002 closed was reopened

Two of the twelve were edited by delivery-002 -- task-027 wrote the `document` pair's routing
clause, task-028 narrowed `aid-document` -- and delivery-002's BLUEPRINT criterion 9 and task-049
closed on those names. Verified against the folded value:

```
aid-create-document   -> /aid-create-diagram, /aid-document-decision, /aid-update-kb,
                         /aid-design-document          all present
aid-update-document   -> /aid-update-kb                all present
aid-create-diagram    -> /aid-create-document          all present
aid-document          -> /aid-create-document, /aid-design-document   all present
genre siblings naming /aid-create-document              7/7
```

And feature-005 **V9**, the `document` trio's mutual routing, still holds in both directions:

| Direction | Present |
|---|---|
| `aid-design-document` -> `/aid-document` | yes |
| `aid-design-document` -> `/aid-create-document` | yes |
| `aid-document` -> `/aid-design-document` | yes |
| `aid-create-document` -> `/aid-design-document` | yes |

**Zero neighbour removals** across the slice.

## 5. Shape and scope

All twelve parse as YAML with `name:` equal to their directory and a non-empty `description`;
`bash tests/canonical/test-frontmatter-lint.sh` passes. As in slices 1 and 2, the cited
`test-graph-skill-registration.sh` / `GR01.a3` oracle no longer exists, and the assertion is
discharged by that YAML parse.

```
$ git status --porcelain canonical/skills/ | wc -l                                    12
$ git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/  clean
```
