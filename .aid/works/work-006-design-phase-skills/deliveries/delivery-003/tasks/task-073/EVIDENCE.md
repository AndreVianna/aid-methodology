# task-073 EVIDENCE -- the pipeline proved untouched: three scoped diffs and the `phase:` grep

Closes BLUEPRINT criterion **12**. Every diff is stated against **`origin/master`**, per the
standing instruction the delivery-002 gate recorded.

## Property 1 -- the `phase:` enum is unchanged

The file the DETAIL names, `work-state-template.md`, **no longer exists**: it migrated to
`work-state-template.yml` upstream. Read against the file that does exist:

```
$ git diff origin/master -- canonical/aid/templates/work-state-template.yml
0 lines
```

The compared text, quoted so a reader can see what was checked -- the closed enum at `:102` and
the seeded default beneath it:

```
# [W] Describe | Define | Specify | Plan | Detail | Execute
phase: Describe
```

Neither line appears in the diff. **The enum was not extended.**

## Property 2 -- the work / delivery / task hierarchy is unchanged

```
$ git diff origin/master -- .aid/knowledge/artifact-schemas.md
0 lines
```

The compared region is that document's definition of the required shape of any AID artifact --
*"work/delivery/task `STATE.yml`, discovery `STATE.md`, REQUIREMENTS ..."*. The whole file is
byte-identical to `origin/master`, so the hierarchy definition inside it necessarily is.

## Property 3 -- the numbered sequence, extracted per file

**The pattern is never reused across the three**, because the three render the same phase set
differently, and a pattern copied from one matches nothing in another:

| File | Rendering | The literal text compared | Diff |
|---|---|---|---|
| `CLAUDE.md` | U+2192, **seven** | `Discover → Describe → Define → Specify → Plan → Detail → Execute` | **0 lines** |
| `AGENTS.md` | U+2192, **seven** | `Discover → Describe → Define → Specify → Plan → Detail → Execute` | **0 lines** |
| `.aid/knowledge/pipeline-contracts.md` | ASCII `->`, **six** with 2a/2b merged | `The six numbered phases run Discover -> Describe/Define (Phase 2a/2b) -> Specify -> Plan -> Detail -> Execute` | 56 lines -- **scoped** |

The phase set is identical in all three; only the rendering differs, and recording the literal text
per file is what shows a per-file rendering difference was not mistaken for a change in the set.

**`pipeline-contracts.md` is diffed scoped, not with `--exit-code`, and that is by design** -- this
is the document task-066 edits on purpose. What is asserted is that the sequence inside it is
unchanged, not that the file is:

```
diff touching 'Discover -> Describe/Define'   : no
diff touching 'six numbered phases'           : no
the 56 lines are                              : 45 added, 0 removed  (task-066's lifecycle section)
```

**Zero removals** -- so nothing in the file was displaced, only appended to.

## Property 4 -- no new skill declares a `phase:`

Over all **36** skills this work adds -- the 9 planning and 27 design/foundation rows:

```
files checked                                : 36
declaring '^phase:'                          : 0
carrying a `phase` frontmatter key (YAML)    : 0
declaring 'phase is not driven'              : 36
```

Checked two ways, because a grep alone would miss a `phase` nested under another key: every one of
the 36 was parsed as YAML and its frontmatter keys inspected. **None carries one**, and all 36 say
so explicitly in their bodies.
