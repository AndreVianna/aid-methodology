# task-069 EVIDENCE -- every count-bearing surface states its true value, under the surviving guard and G-01

Re-scoped by owner decision (2026-08-14). The original subject -- extend `CLAIMS`, raise
`MARKER_CAP` and `CLAIM_FLOOR`, drive the stage-2 replay to zero -- targeted constructs inside
`tests/canonical/check-skill-counts.mjs`, **deleted upstream**. No constant survives to raise and
no replay survives to run. Authoritative record: `../../RESCOPE-COUNT-GUARD.md`.

## 1. Oracle 1 -- the surviving guard is green

`bash tests/canonical/test-doc-counts.sh`, before and after:

```
before:  exit 1    Tests passed: 23    Tests failed: 8
after:   exit 0    Tests passed: 31    Tests failed: 0
```

All eight failures were `DC02` count-drift reports, and the guard named each surface itself, so the
work list was **read off the run** rather than taken from the plan.

## 2. The derived figures, read from the guard rather than asserted

From the passing run's own log line:

```
[LOG] derived: SKILLS=111 AGENTS=9 PROFILES=5 ROWS=94 CANON=94 ALIAS=0 REPURPOSE=60 SHORTCUTS=34
PASS: DC01a catalog: canonical(94) + alias(0) == total rows(94)
PASS: DC01b canonical counts derive cleanly (skills=111 agents=9 profiles=5 shortcuts=34)
```

**`SKILLS=111`** -- the guard's own derivation, which is a fourth independent confirmation of
task-050's correction and of the figure the DETAILs get wrong as 112. `DC01`'s internal consistency
check passes: canonical + alias == total.

## 3. The work list, resolved per surface

**13 sites** across seven files:

| Surface | Now states |
|---|---|
| `README.md` | 111 skills |
| `docs/repository-structure.md` | 111 skill definitions, 94-row catalog (2 sites + 2 `58-row` phrasings) |
| `profiles/claude-code/README.md` | 111 skills (2 sites) |
| `profiles/codex/README.md` | 111 skills (2 sites) |
| `profiles/cursor/README.md` | 111 skills (2 sites) |
| `profiles/copilot-cli/README.md` | 111 skills (2 sites) |
| `profiles/antigravity/README.md` | 111 skills (2 sites) |

`docs/repository-structure.md` is in `sync-docs.mjs`'s `MANIFEST`, so its site mirror was
regenerated rather than hand-edited -- the same mechanism task-068 established.

## 4. A criterion whose premise is false, and what was done instead

The AC requires *"the five profile READMEs were fixed at their `canonical/` source, not in place ...
their correction arrives through the render"*. **There is no such source.** Established three ways:

```
$ find canonical -name 'README*'                                  # (nothing)
$ grep -h 'README' profiles/*/emission-manifest.jsonl | wc -l     # 0 -- in no manifest
render.py contains no README handling; the five files are byte-DISTINCT from one another
```

and confirmed historically: the last commit to touch them is `dd3d0367` *"Correct stale skill
counts ..."*, which edited them **in place** for exactly this reason. The render had already run
twice in this delivery (tasks 060 and 061) leaving `profiles/` clean, while the READMEs still said
75 -- so the render demonstrably does not write them.

They are therefore **hand-maintained per profile** and were corrected in place. Recorded as a
correction to the criterion rather than a deviation from it.

## 5. The `G-01` half, discharged per surface with a verdict

| Surface | Verdict |
|---|---|
| `canonical/skills/aid-triage/references/state-classify.md:85` | **REMOVED as cosmetic.** It read *"today all 58 rows read `alias_of: null`"*. The sentence's point is that the filter selects the whole catalog **because no aliases exist** -- the row count is incidental to it. Rewritten to *"today every row reads `alias_of: null`"*, which retires a count-bearing surface outright instead of creating another one to maintain. |
| `.claude/skills/release-aid/SKILL.md` | **No count present.** `grep` for a figure beside a skills/rows/catalog/directories noun returns **0**; its only numeric matches are line references. Nothing to re-measure, and no edit made. |
| `README.md` | **Re-measured**, and the measurement is the guard's: `DC02` derives `SKILLS` from `ls -1d canonical/skills/*/` and asserts the document states it. Recorded from the guard's output, not from a hand count. |

## 6. The canonical edit was carried through the render, not left behind

`state-classify.md` lives under `canonical/`, so it renders to all five profiles:

```
$ python3 .claude/skills/generate-profile/scripts/run_generator.py     4 gates PASS
profiles/ : 15 files          # the edit reached all five
$ <re-render again>            profiles/ : 15 files (stable -- idempotent)
```

Both dogfood trees were then merge-resynced (1 file each), with `release-aid` verified intact
afterwards (`git diff HEAD` clean, `grep -c Unreleased` -> 0). `test-doc-counts.sh` is still green
after every one of these steps.
