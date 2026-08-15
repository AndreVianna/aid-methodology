# task-052 EVIDENCE -- nine curated pipeline and router descriptions given a trigger clause

REQUIREMENTS **AC-12**. Slice 1 of 7 over the seventy-eight hand-authored descriptions: the nine
curated **pipeline-and-router** skills -- `aid-config`, `aid-discover`, `aid-describe`,
`aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute`, `aid-triage`.

## 1. AC-12 checks 1, 2 and 4 over the nine

Asserted over the extracted `description:` block, never the whole file:

| Skill | chars (cap 1024) | banned forms | arrow transition sequence | neighbours lost |
|---|---|---|---|---|
| `aid-config` | 388 | none | no | none |
| `aid-discover` | 547 | none | no | none |
| `aid-describe` | 574 | none | no | none |
| `aid-define` | 440 | none | no | none |
| `aid-specify` | 411 | none | no | none |
| `aid-plan` | 190 | none | no | none |
| `aid-detail` | 498 | none | no | none |
| `aid-execute` | 439 | none | no | none |
| `aid-triage` | 575 | none | no | none |

Longest is 575 against a 1024 cap. Every one names the user-facing outcome in its first sentence
and defers AID-internal vocabulary to later clauses.

## 2. The trigger clause, per skill, quoted

Every one states **when** to use the skill, in the imperative form AC-12 requires:

| Skill | Trigger clause |
|---|---|
| `aid-config` | "Use this skill when you need to see how the pipeline is configured, or change one setting such as the project name, its type, or the minimum grade." |
| `aid-discover` | "Use this skill when you are starting AID on a project with existing code, and its architecture, conventions, and patterns need to be written down before any later phase can rely on them." |
| `aid-describe` | "Use this skill when you know roughly what you want built but the scope, the users, and the acceptance criteria are not yet pinned down." |
| `aid-define` | "Use this skill once /aid-describe has produced an approved REQUIREMENTS.md and the work needs splitting into features before any one of them is specified." |
| `aid-specify` | "Use this skill when a feature has been defined and how it will actually be built needs settling before any task is planned." |
| `aid-plan` | "Use when feature SPECs are complete and you need a delivery roadmap." **(pre-existing, unchanged)** |
| `aid-detail` | "Use this skill when a delivery has been planned and the actual work items are needed before execution starts." |
| `aid-execute` | "Use this skill when tasks have been detailed and you are ready for the work to actually be done." |
| `aid-triage` | "Use this skill when you know what you want to change but not which skill to reach for." |

`aid-plan` is one of only **two** descriptions in the entire roster that already carried a trigger
(AC-12's rationale records the figure). Its clause is preserved verbatim rather than rewritten for
uniformity -- it is the shape the other 110 are being moved toward, so rewriting it would be
rewriting the target.

## 3. `aid-describe`'s `State machine:` line was relocated, not removed

The one hard interaction in this slice. `tests/canonical/test-describe-full-only.sh:71` takes the
**first** `State machine:` line **in the whole file** (`awk '/State machine:/{print; exit}'`) and
asserts DFO01a (it exists), DFO01b (no `TRIAGE`/`CONDENSED-INTAKE`/`LITE-` token) and DFO01c (it
reads `FIRST-RUN -> Q-AND-A -> CONTINUE`). AC-12 check 2 bans that sequence from the
**description** and says nothing about the body -- so the line moves into the body, verbatim.
Deleting it would fail DFO01a; leaving it in the description would fail AC-12.

```
$ grep -c 'State machine:' canonical/skills/aid-describe/SKILL.md
1                                    # still exactly one occurrence
frontmatter closes at line 13   |   State machine: now at line 17   ->   below the close
```

Placed under the H1 rather than immediately after the `---`, so a bare transition line does not
sit above the document's own title:

```
# Conversational Requirements Gathering

State machine: FIRST-RUN -> Q-AND-A -> CONTINUE -> {greenfield: DESCRIBE-SEED ->} COMPLETION [PAUSE -> /aid-define].
```

```
$ bash tests/canonical/test-describe-full-only.sh --verbose
DFO01a PASS    DFO01b PASS    DFO01c PASS
$ git diff origin/master -- tests/canonical/test-describe-full-only.sh
0 lines                              # green with the suite unedited
```

## 4. No negative route was lost

Any neighbour name a description carries was written by the feature that owns that pair under
FR-11 **CC-9**, and delivery-002's task-049 verified the sides it wrote -- so a rewrite that
dropped one would break a criterion already closed. Each description's set of `/aid-` names was
captured before and compared after:

| Skill | `/aid-` names before | after |
|---|---|---|
| `aid-config` | `/aid-config` | preserved |
| `aid-discover` | `/aid-config` | preserved |
| `aid-describe` | `/aid-define` | preserved |
| `aid-define` | `/aid-describe`, `/aid-specify` | both preserved |
| `aid-triage` | `/aid-describe` | preserved |
| `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute` | none | none |

**Zero removals**, so no removal needed a stated reason.

## 5. Frontmatter shape intact on all nine

Each file still opens and closes with `---`, parses as YAML, and declares all four keys with
`name:` equal to its directory:

```
aid-config, aid-discover, aid-describe, aid-define, aid-specify, aid-plan, aid-detail,
aid-execute, aid-triage
  -> YAML ok, name == dir, keys: allowed-tools, argument-hint, description, name   (9/9)
$ bash tests/canonical/test-frontmatter-lint.sh          PASS
```

**One cited oracle no longer exists.** The task names
`tests/canonical/test-graph-skill-registration.sh` and its `GR01.a3` (the `description` key's
presence) as a guard here. That suite was **deleted upstream** by commit `b8b01b1b` *"Completely
remove aid-graph skill"* -- the same removal behind task-050's directory-count correction -- and
is absent from `origin/master`. It has no successor: `test-frontmatter-lint.sh` does not mention
`description` at all (`grep -ci 'description'` -> 0). Rather than report the check as covered by a
suite that cannot run, the role was discharged directly: all nine were parsed as YAML and asserted
to carry a non-empty `description` key, which is exactly what GR01.a3 asserted. Logged for the
delivery.

## 6. Only the nine moved, and nothing outside the declared writes

```
$ git status --porcelain canonical/skills/ | wc -l
9        # aid-config aid-define aid-describe aid-detail aid-discover
         # aid-execute aid-plan aid-specify aid-triage
$ git diff --exit-code -- tests/ site/ canonical/aid/templates/ docs/ .aid/knowledge/    clean
$ git status --porcelain profiles/ .claude/ .cursor/                                     0 entries
```

Every line and assertion id cited above was re-resolved against the files as they stand, not
carried from the DETAIL -- which is how the deleted suite in §5 was caught.
