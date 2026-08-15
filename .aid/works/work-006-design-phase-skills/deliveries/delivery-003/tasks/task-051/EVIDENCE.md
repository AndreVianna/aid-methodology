# task-051 EVIDENCE -- the generated doorway's description template: one f-string, thirty-four doorways

REQUIREMENTS **AC-12**, checks **3**, **2**, **1** and **4**. The generated half of the one
description sweep this delivery runs -- cut first so the seventy-eight hand-authored slices that
follow (task-052..058) can be written in the same voice. task-072 verifies routing and triggering
together.

## 1. What the template said before, and why every clause had to go

`.claude/skills/generate-profile/scripts/build-shortcut-skills.py`, the `frontmatter = (`
assignment, emitted this for all thirty-four:

```
Direct-entry Lite-path shortcut ({intent}) -- skips the aid-describe
interview/triage. Binds VERB=`{verb}` {artifact_bind} and runs the shared
shortcut engine, producing a fully-graded flattened Lite work that halts for
approval.
State machine: delegated to canonical/aid/templates/shortcut-engine.md
(INTAKE -> CAPTURE -> SPEC -> PLAN -> DETAIL -> GATE -> APPROVAL-HALT).
```

It contained **all four** banned forms at once -- the `Direct-entry Lite-path shortcut` opener,
`VERB=`, `ARTIFACT=` (via `artifact_bind`), and the `INTAKE -> CAPTURE` transition sequence -- and
it buried the row's `intent` in parentheses, which is exactly what AC-12 check 3 exists to
correct. This is a maintainer-only helper with **no `canonical/` source**
(`ls -d canonical/skills/generate-profile` -> absent), so `.claude/` is where it legitimately
lives and is edited; it is not a render target.

## 2. The new template

```python
description = (
    f"{intent} Use this skill when you already know what to {verb} and want it scoped, "
    "specified, and broken into reviewable tasks in a single pass, with no requirements "
    "interview. You approve the resulting plan before anything is built: this skill "
    "plans and stops, so run /aid-execute to carry the plan out."
)
```

wrapped with `textwrap.fill(..., width=90)` so the emitted YAML stays tidy whatever the intent's
length (they range 21-134 characters).

**One decision worth recording.** A first pass put the artifact into the trigger clause -- *"when
you already know which api to create"* -- which reads badly for every acronym artifact and would
have needed a per-skill casing map. The artifact is dropped from the trigger instead, because
`intent` **already** names it in natural English (*"Create an API endpoint / middleware (contract,
handler, validation)."*). One template, no per-skill wording, which is the whole point of editing
an f-string rather than thirty-four files.

## 3. AC-12 checks 1-4, over the extracted description block

Asserted over the block between `description:` and the next top-level frontmatter key -- **never**
over the whole file, because the body legitimately keeps all four banned strings:

| Check | Oracle | Result |
|---|---|---|
| **3** -- leads with the row's `intent` | each block's normalised text `startswith(row['intent'])` | **34/34** |
| **2** -- no banned form | `Direct-entry Lite-path shortcut`, `VERB=`, `ARTIFACT=`, `INTAKE -> CAPTURE` over each block | **NONE** in any of the 34 |
| **1** -- budget | longest / shortest description | **429** / **315** against a 1024 cap |
| **4** -- outcome before internals | reviewer read; the intent is the first sentence and the only AID-internal token (`/aid-execute`) is the last clause | holds |

The longest and shortest quoted in full, as the criterion requires:

**Longest -- `aid-migrate`, 429 characters:**

> Migrate data, a dependency, framework, or platform, with a rollback plan (non-schema; schema
> migrations use create/update-data-model). Use this skill when you already know what to migrate
> and want it scoped, specified, and broken into reviewable tasks in a single pass, with no
> requirements interview. You approve the resulting plan before anything is built: this skill
> plans and stops, so run /aid-execute to carry the plan out.

**Shortest -- `aid-create-cli`, 315 characters:**

> Create a CLI command. Use this skill when you already know what to create and want it scoped,
> specified, and broken into reviewable tasks in a single pass, with no requirements interview.
> You approve the resulting plan before anything is built: this skill plans and stops, so run
> /aid-execute to carry the plan out.

Median stays far under the cap, which is what AC-12's rationale predicted: the fix is a
reallocation of the existing budget, not an expansion.

## 4. The body-side assertions survive -- the failure this task was most likely to cause

`test-catalog-dirs-parity.sh` reads the **whole file** (`body=$(cat "$skill_md")`), so a
description-only edit that also stripped the body bindings would pass a frontmatter grep and fail
here:

```
$ bash tests/canonical/test-catalog-dirs-parity.sh --verbose
CDP{i}e (body binds VERB=`<verb>`)                        PASS x34
CDP{i}f (body binds ARTIFACT=`<artifact>` / bare verb)    PASS x34
CDP{i}g (body delegates to shortcut-engine.md)            PASS x34
Tests passed: 485      Tests failed: 0
$ git diff origin/master -- tests/canonical/test-catalog-dirs-parity.sh
0 lines                                                   # green UNMODIFIED
```

The `_GENERATED_MARKER` survives too -- read out of the script rather than retyped, then counted:

```
$ grep -l -- "$MARKER" canonical/skills/*/SKILL.md | wc -l
34
```

which matters because `find_orphans` and `CDP-ORPHAN` both key on it, and an orphan sweep that
stopped recognising a directory it generated would **delete** it.

## 5. The regeneration is total and byte-current

```
$ python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py
Generated/refreshed 34 doorway(s) ..., skipped 60 repurpose row(s), removed 0 orphan(s).
$ python3 ... --check
OK: 34 doorway(s) up to date, 60 repurpose row(s) skipped, 0 orphan(s).
$ python3 ...                        # second run
Generated/refreshed 0 doorway(s) (34 already up to date), skipped 60 repurpose row(s), removed 0 orphan(s).
```

Exit 0, a line beginning `OK:`, and **0** written on the re-run.

## 6. Only the thirty-four moved

Scoped to this task's own diff rather than to `origin/master` -- which necessarily also carries
delivery-001's and delivery-002's committed work:

```
$ git status --porcelain canonical/skills/ | wc -l
34
  all 34 are SKILL.md                                     : 34/34
  all 34 carry the generated marker                       : 34/34
  directories added or removed                            : 0
```

No hand-authored body moved. (Against `origin/master` one non-`SKILL.md` file also differs --
`aid-discover/references/document-expectations.md` -- which is delivery-002's committed CC-4
surface edit, not this task's.)

## 7. The `:12` count comment, corrected from a re-derived figure

```
$ grep -c '^    repurpose: true$' canonical/aid/templates/shortcut-catalog.yml
60
```

The comment read *"`repurpose: true` rows (24 total after work-004) are SKIPPED"*. It now reads
**60**, and carries the derivation beside it so the next reader re-derives rather than trusts:
*"re-derive with `grep -c '^    repurpose: true$'` on the catalog rather than trusting this
figure"*. Corrected here, not in task-069, so that one file has one writer.

## 8. Nothing outside the declared writes moved

```
$ git diff --exit-code -- canonical/aid/templates/ docs/ .aid/knowledge/ site/     clean
$ git diff --exit-code -- tests/ site/scripts/__tests__/                           clean
$ git status --porcelain profiles/ .cursor/                                         0 entries
```

No new test file was authored -- barred by feature-001 AC-3; coverage for this change is the
existing parity suite plus the helper's own `--check` mode. `.claude/` shows exactly one entry,
the helper script itself, which is this task's declared write and has no `canonical/` source; the
render trees (`profiles/`, `.cursor/`) are untouched, and task-060 owns the render.

Full change set: **34** doorway `SKILL.md` files + **1** helper script + this task's own
`STATE.yml`.
