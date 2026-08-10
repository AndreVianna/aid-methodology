# Design Grid and Brainstorm

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md FR-5, FR-6, FR-7, NFR-4 | /aid-define |
| 2026-08-09 | Technical Specification authored. Three corrections to the requirements half recorded in §4b, §7a and §7c: FR-10's engine read reaches 13 of the 14 paired artifacts (the `document` pair is `repurpose: true` and never runs the engine), `/aid-design-ui` is a new row rather than a shipped skill, and three of REQUIREMENTS AC-8's four pairs are cross-feature and verifiable only in feature-006 | /aid-specify |
| 2026-08-09 | Rewritten against review round 1 (21 findings, 0 CRITICAL, 4 HIGH), and against REQUIREMENTS FR-11, which settled nine cross-feature contracts after this spec was written. The "unpaired artifact" exclusion rule is **deleted**, not patched (CC-8): §2 is now a positive selection and the exclusions table is gone. §6 is new — the fifteen `SKILL.md` bodies were declared deliverables with no content specification and no binding to `design-lifecycle.md`. §7c's pair ownership rebuilt on CC-9; §7a gains two shipped description edits so the `document` trio is mutual. Blast-radius figure corrected 58 → 34. The acceptance criteria are numbered, and §8 gains a Kind column so every row is a script, a suite or a review | /aid-specify |

## Source

- REQUIREMENTS.md FR-5 (the `design` verb across the full create/update grid)
- REQUIREMENTS.md FR-6 (overlap resolutions), FR-7 (`/aid-brainstorm`), FR-4, FR-10
- REQUIREMENTS.md §6 NFR-2, NFR-4 (discoverability over count); §9 AC-8, AC-10
- REQUIREMENTS.md **FR-11** — CC-3 (`update` and the seed), CC-6 (destinations resolve by
  concern), CC-7 (the `design` family's row count), CC-8 (the selection is positive, not an
  exclusion), CC-9 (confusable-pair ownership). Each is **referred to, never restated**, per
  FR-11's own instruction.

## Description

Everything defined by its relationship to a skill that **already exists** — which is
what binds these four otherwise-different pieces into one feature.

**(a) The fourteen grid rows.** Every artifact that already holds both a `create` and an
`update` catalog row also receives a `design` row, so the lifecycle is uniform across the
whole catalog rather than special to the seven new artifacts:

`api`, `ui`, `theme`, `cli`, `data-model`, `data-pipeline`, `messaging`, `integration`,
`job`, `config`, `infra`, `test`, `document`, `dashboard`

That set is a **positive selection** — the artifacts carrying both rows — not the residue
of an exclusion rule (CC-8). §2 derives it. `aid-update-kb` and the three ticket skills are
worth naming for a different reason: they are on-disk skills with **no catalog row at all**,
so they are outside the grid rather than inside it and unselected.

**The `design` stage is uniform; the `create` stage is not.** These fourteen artifacts
produce *built artifacts* (thirteen of them via the shortcut engine; the `document` pair
is hand-authored — §4b), not KB documents — so FR-1's
`create` contract does not apply to them, and their existing doorways are **not**
modified. What this feature does add is FR-10's single additive read: the engine loads
a `.aid/design/` seed at CAPTURE when one exists, so `design` and `create` compose.

**(b) `/aid-brainstorm`.** The one genuinely new exploratory skill, serving the case
`/aid-research` cannot: a problem not yet formed into a question. Its output is a
`.aid/design/` seed.

**(c) The FR-10 engine read.** One additive bullet in `shortcut-engine.md`, plus the two
hand-authored reads that reach the one paired artifact the engine does not (§4b). This is
the highest-blast-radius change in the work.

**(d) Description edits to shipped skills.** Bare `/aid-design` narrows from advertising
"an architecture sketch" to being the catch-all it must now be, matching the existing
bare-verb convention. `/aid-research` gains the negative route to `/aid-brainstorm`.
`/aid-prototype-ui` states the `design` = kept versus `prototype` = throwaway route to
`/aid-design-ui` — whose own new description states the reverse. `/aid-document` and
`/aid-create-document` gain the route to `/aid-design-document` (§7a).

With thirty-six additions, discoverability is the risk that matters more than count.
Every confusable pair must name its neighbour, following the precedent already set
between `/aid-design` and `/aid-prototype`.

## User Stories

- As an **adopter**, I want to develop an API or data model in `.aid/design/` before
  building it, using the same lifecycle as every other artifact.
- As an **adopter with an unformed problem**, I want a skill that helps me diverge before
  converging, rather than one that demands a well-formed question up front.
- As an **adopter facing 112 skills**, I want each description to tell me when to reach
  for its neighbour instead, so that a larger roster does not mean a harder choice.

## Priority

Must

## Acceptance Criteria

An unqualified **AC-n** anywhere in this document is a criterion in *this* list.
REQUIREMENTS.md's own criteria are always written **REQUIREMENTS AC-n**. Each criterion
names the §8 oracle row that fails when it is not met.

- [ ] **AC-1 — The fifteen new rows are well-formed (NFR-2).** Each of the fourteen
      `design` rows and the `/aid-brainstorm` row has a `name` equal to its directory name
      and to its frontmatter `name:`, and `alias_of: null`. *Oracles:* §8 V1, V3, V4.
- [ ] **AC-2 — `/aid-brainstorm` needs no question.** Invoked on an unformed problem, it
      produces a `.aid/design/` seed and does not require a well-formed question.
      *Oracle:* §8 V11.
- [ ] **AC-3 — `/aid-research` ↔ `/aid-brainstorm` is mutual.** Each description names
      the other as the negative route. Both sides are written by this feature.
      *Oracle:* §8 V7.
- [ ] **AC-4 — Bare `/aid-design` is the catch-all.** Its `SKILL.md` no longer advertises
      an architecture sketch **anywhere** — neither in `description` nor in
      `argument-hint` — and presents as the catch-all for subjects with no dedicated
      `design` row. *Oracles:* §8 V5, V6.
- [ ] **AC-5 — `/aid-design-ui` ↔ `/aid-prototype-ui` is mutual.** The kept-versus-
      throwaway distinction is stated on both. Both sides are written by this feature.
      *Oracle:* §8 V8.
- [ ] **AC-6 — The selection is exactly the paired set, and nothing outside it is
      touched.** The set of artifacts receiving a `design` row *from this feature* equals,
      both directions, the set of artifacts carrying both a `create` and an `update` row in
      the catalog **as it stands before this work lands** (§2). `aid-update-kb` and the
      three ticket skills, which carry no catalog row at all, acquire none.
      *Oracles:* §8 V2, V17, V18.
- [ ] **AC-7 — The seed read reaches all fourteen, and is additive.** Given a
      `.aid/design/` seed for one of the fourteen, its `/aid-create-*` doorway loads the
      seed as prior context; given no seed, engine behavior is unchanged
      (REQUIREMENTS AC-10). *Oracles:* §8 V12, V13, V14.
- [ ] **AC-8 — Every side this feature writes carries its neighbour's name.** For each
      row of §7b and §7c, the neighbour's literal skill name appears in that skill's
      `description:` frontmatter. The **whole** pair set is verified only by feature-006's
      sweep, because three pairs have their counterpart written in feature-004 (§7c).
      *Oracles:* §8 V9, V10.
- [ ] **AC-9 — The fifteen bodies bind the shared contract rather than forking it.** Each
      of the fifteen new `SKILL.md` files names
      `canonical/aid/templates/design-lifecycle.md` and restates none of its rules; its own
      content is the four artifact-specific items of §6b. *Oracles:* §8 V15, V16.

---

## Technical Specification

**Citation discipline.** Every path and line number below was opened at that line while
this section was written. Where a claim is a completeness claim, the search that produced
it is printed beside it, so a reviewer can re-run it rather than trust it.

### 1. What this feature changes, and what it deliberately does not

Four changes bound by one property: every one of them is defined by its relationship
to something **already on disk**. The letters match the Description's.

| # | Change | File(s) | Kind |
|---|---|---|---|
| a | 14 `design` catalog rows | `canonical/aid/templates/shortcut-catalog.yml` | additive rows |
| a | 14 hand-authored doorways | `canonical/skills/aid-design-<artifact>/SKILL.md` | new dirs |
| b | `/aid-brainstorm` row + doorway | catalog + `canonical/skills/aid-brainstorm/` | additive |
| c | One additive engine read | `canonical/aid/templates/shortcut-engine.md` | 1 bullet + 1 note |
| c | Two hand-authored seed reads | `aid-create-document`, `aid-update-document` | 1 line each |
| d | Description edits, shipped skills | `aid-design`, `aid-research`, `aid-prototype-ui`, `aid-document`, `aid-create-document` | text only |

**Not changed, and why.** The 14 `create` and 14 `update` doorways themselves are not
modified. They produce *built artifacts* — 26 of them through the shortcut engine, the
`document` pair through its own hand-authored bodies (§4b) — not KB documents,
so FR-1's `create` contract (realize a design into a KB document) does not describe
them and must not be imposed on them. The composition point between `design` and
`create` for these fourteen is §4's engine read alone — a doorway rewrite is neither
required by FR-10 nor permitted by C-6. Two of those 28 doorways *are* touched, and only
in the two places §1's table names: `aid-create-document` and `aid-update-document` gain
the one-line seed read of §4b, and `aid-create-document` additionally gains the routing
clause of §7a. Neither edit is a rewrite.

### 2. The fourteen paired artifacts — a positive selection, derived

The set is derived, so it is checkable rather than trusted. From the catalog, take every
**non-empty** `artifact` value that appears on **both** a `verb: create` row and a
`verb: update` row:

```
# $1 = the catalog to derive from, so the same command serves §8 V2 against a
# `git show master:canonical/aid/templates/shortcut-catalog.yml > /tmp/master-catalog.yml`
python - "$1" <<'PY'
import re, sys, collections
rows, cur = [], None
for line in open(sys.argv[1], encoding='utf-8'):
    m = re.match(r'^  - name: (\S+)', line)
    if m: cur = {}; rows.append(cur)
    elif cur is not None:
        f = re.match(r'^    (\w+): (.*)$', line)
        if f: cur[f.group(1)] = f.group(2).strip().strip('"')
by = collections.defaultdict(set)
for r in rows: by[r.get('artifact', '')].add(r.get('verb'))
print(sorted(a for a, v in by.items() if a and {'create', 'update'} <= v))
PY
```

```
api  ui  theme  cli  data-model  data-pipeline  messaging  integration
job  config  infra  test  document  dashboard
```

Fourteen. **The non-empty filter is part of the rule, not a later refinement:** bare
`/aid-create` (`shortcut-catalog.yml:148`) and bare `/aid-update` (`:237`) both carry
`artifact: ""`, so the unfiltered intersection has **fifteen** members, the extra one
being the empty string. A derivation that omitted the filter would make §8 V2 fail by
construction.

**The derivation's input is pinned to the pre-work catalog.** It is run against the 58-row
catalog as it stands before any row from this work lands — equivalently
`git show master:canonical/aid/templates/shortcut-catalog.yml`, verified at 58 rows.
Re-running it over the *finished* catalog returns **twenty-one**, not fourteen, because
feature-003 adds three `create`/`update` pairs and feature-004 adds four. That is not a
defect: those seven artifacts receive their `design` rows from features 003 and 004, and
the arithmetic closes at CC-7's figure — 21 paired artifacts with a `design` row, plus the
bare `aid-design` row. So the uniformity claim ("every artifact with a create/update pair
has a `design` stage") is true of the *work*, while *this feature* owns exactly fourteen
of the rows that make it true.

**There is no exclusion rule (CC-8).** An earlier draft of this section carried one —
"`diagram` is the only row-bearing unpaired artifact" — and it was false twice over. The
catalog holds **eleven** row-bearing artifacts outside the paired set (`architecture`,
`changelog`, `data-quality`, `decision`, `diagram`, `guideline`, `performance`, `runbook`,
`security`, `standard`, `tutorial`, by the derivation above with the membership test
inverted), and `architecture` **does** receive a `design` row — feature-004 SPEC §1a. Being
outside the paired set therefore implies nothing about whether an artifact gets a `design`
row, which is precisely what CC-8 settles. The rule is deleted rather than corrected.

**What is worth recording is a different fact:** two groups of on-disk skills carry **no
catalog row at all**, so they are outside the grid rather than unselected within it.

| Outside the catalog | Evidence |
|---|---|
| `aid-update-kb` | `grep -cE '^  - name: aid-update-kb$'` on the catalog → `0`; present in `CURATED_GROUPS` (`site/scripts/skills/groups.mjs:85`, Knowledge Base Maintenance) |
| `aid-read-ticket`, `aid-create-ticket`, `aid-update-ticket` | `grep -cE '^  - name: aid-(read\|create\|update)-ticket$'` → `0`; all three in `CURATED_GROUPS` (`groups.mjs:72-74`, Support) |

The catalog's only textual mention of any of them is a comment at `shortcut-catalog.yml:457`
(`aid-update-kb`'s territory), which is why the oracle in §8 V18 anchors on the
`^  - name:` row form rather than on a bare name match.

### 3. The fourteen `design` rows

#### 3a. Row shape

Each row is hand-authored (`repurpose: true`, per NFR-2 and feature-002 SPEC §3f), so
`build-shortcut-skills.py` skips it and the doorway is written by hand. The shape
follows the shipped `aid-design` row (`shortcut-catalog.yml:441-448`) field for field,
differing only in `name`, `artifact` and `intent`:

```yaml
  - name: aid-design-api
    verb: design
    artifact: api
    alias_of: null
    default_type: DESIGN
    group: G3
    intent: "Develop an API design in .aid/design/ before building it; writes a seed, builds nothing."
    repurpose: true
```

- **`name`** equals the directory name and the rendered `/command` name — `render.py:545`
  sets `skill_slug = skill_dir.name` and carries frontmatter `name:` through untouched,
  so there is no redirect layer and the three must agree.
- **`alias_of: null`** on every row. The field is deprecated-but-required
  (`build-shortcut-skills.py:54-55`); its removal is a scheduled follow-on and is
  explicitly **not** in this work's scope. §8 V4 records which oracle actually asserts it,
  and which one does not.
- **`default_type: DESIGN`** on all fourteen, matching the shipped `aid-design` row and
  inside the closed 8-enum (`build-shortcut-skills.py:50-52`, enforced at `:219-224`).
  The value is inert for a `repurpose` row (it is consumed at the engine's DETAIL state,
  which these doorways never reach) but the field is required by `_REQUIRED_FIELDS`
  (`:55`), and a value inconsistent with its sibling would be a latent trap for a later
  reader.
- **`group: G3`** — the group `aid-design` and `aid-prototype` already occupy.

#### 3b. Placement in the file

Immediately after the existing `aid-design` row (`shortcut-catalog.yml:441-448`), in
the same order as §2's derivation. Placement is not cosmetic: `site/scripts/skills/groups.mjs`
derives family order by walking `catalog.rows` in **file order** and appending each
newly-seen verb (`:255-262`). `design` is already a seen verb at that point (the
`aid-design` row), so the family's position on the published index is unchanged and card
order within the family follows row order (`:133`).

#### 3c. What the `design` verb does *not* acquire

The engine's **Current verb → family-file groupings** table
(`shortcut-engine.md:183-189`) gains **no** `design` entry, and no
`shortcut-scaffolding/design.md` is written (feature-002 SPEC §1e owns that scope
decision and its reasons).

**Correctness does not depend on the note this feature adds.** The engine already states
the general rule: *"A verb absent from the table falls back to the generic rules stated in
this file"* (`shortcut-engine.md:175-176`, with the mechanism at `:206`). Absence is
routine — ten of the catalog's eighteen verbs are absent from that table today, including
`document` (8 rows), `test` (4) and `prototype` (2), none of them noted. So the earlier
draft's reason — that the omission is "self-evidently harmless because `design` has exactly
one row" — was false on disk and is withdrawn.

What the `query` paragraph (`shortcut-engine.md:191-194`) records is a *different* fact:
that the `aid-ask` row never enters the engine at all, its doorway being hand-authored
rather than a generated thin doorway. That fact is about to become true of a family that
grows from one row to CC-7's figure, so this feature extends that paragraph to name
`design` alongside `query`. It is a **comment-only** edit that prevents a future reader
from reading the gap as an oversight and "fixing" it; nothing behavioral rests on it, and
§8 V13 bounds it to that.

### 4. FR-10 — the single additive engine read

#### 4a. Where it goes

`shortcut-engine.md`, **State: CAPTURE → Step 2: Read context** (`:379-386`). That step
already reads two optional context sources and already carries the "if it does not
exist, fall back unmodified" idiom. The change is a third bullet in the same shape:

```markdown
- `.aid/design/{artifact}.md`, if it exists and `{artifact}` is non-empty -- the seed a
  prior `/aid-design-{artifact}` run developed. Read it as PRIOR CONTEXT for the slot
  set below: it is an input to the write-up, never a substitute for it, and it is never
  edited, moved, or deleted by this run. If the file is absent, or `{artifact}` is `""`,
  CAPTURE proceeds exactly as before.
```

**Why CAPTURE Step 2 and not INTAKE.** INTAKE resolves the catalog row, the
description, and the work-NNN allocation; it has no context-reading step and no
consumer for a seed. CAPTURE Step 3 (`:388-397`) is the first point where prior context
changes an outcome (which slots are genuinely open). Placing the read at INTAKE would
load a file one state before anything could use it.

**Blast radius.** The engine is the shared template for the **34** generated thin
doorways — the other 24 of the catalog's 58 rows are `repurpose: true` and never enter it
(`tests/canonical/test-catalog-dirs-parity.sh:24-27`; `DMR33` asserts the 24 at
`tests/canonical/test-deploy-monitor-repurpose.sh:324`). *Correcting the requirements
half:* REQUIREMENTS FR-10's blast-radius paragraph calls it "the shared template every
one of the 58 existing catalog rows depends on" — 58 is the catalog size, not the engine's
reach. The corrected figure does not change the conclusion: at 34 doorways this is still
the highest-blast-radius edit in the work, and the only one that touches shipped behavior.

Three properties bound it: the read is **conditional** (absent file ⇒ byte-identical
behavior), **non-mutating** (no write path is added), and **additive** (no existing
bullet, rule, or state transition is altered). REQUIREMENTS AC-10's "given no seed exists,
engine behavior is unchanged" is the criterion; §8 V13 and V14 are its oracles.

#### 4b. Which doorways this actually reaches — stated, not left implicit

**The bullet is verb-agnostic.** Its only condition is that `{artifact}` is non-empty, so
it fires on every generated doorway with an artifact — which is **26** of the 34: 13
`create` and 13 `update`. (Verified by the §2 derivation with the `repurpose` key read:
every non-`repurpose` row carrying a non-empty artifact is a `create` or an `update` row,
and the remaining 8 are bare, `artifact: ""` — `aid-create`, `aid-update`, `aid-fix`,
`aid-refactor`, `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`. 26 + 8 = 34.)

FR-10 and REQUIREMENTS AC-10 are worded around `create`. The `update` half of the reach is
therefore **intended and stated here** rather than an accident of the insertion point:
REQUIREMENTS FR-11 CC-3 settles what `update` does with a seed that exists, and the
engine's read is non-mutating, so a class-2 seed is read and persists under both verbs
alike (feature-002 SPEC §3b, §3g). A verb-conditional bullet was the alternative and is
rejected: it would make the 13 `update` doorways ignore a seed sitting beside them, which
CC-3 forecloses.

**The one paired artifact the engine does not reach.** Of the fourteen, thirteen have
generated create/update doorways. **`document` is not:** `aid-create-document` and
`aid-update-document` are `repurpose: true` hand-authored skills (the G8 collapse skills,
`shortcut-catalog.yml:459-474`) and never execute `shortcut-engine.md`.

Leaving this implicit would make AC-7 false for one of the fourteen while appearing
satisfied. So this feature adds the equivalent one-line read to both hand-authored
skills, phrased for their own flow and carrying the same three properties
(conditional, non-mutating, additive):

> If `.aid/design/document.md` exists, read it as prior context before drafting; it is
> an input, never a substitute, and is not modified by this run.

That is two files (`canonical/skills/aid-create-document/SKILL.md`,
`canonical/skills/aid-update-document/SKILL.md`), and it makes AC-7 true for all
fourteen rather than thirteen.

#### 4c. Seed path

`.aid/design/<token>.md`, `<token>` = the row's `artifact` (feature-002 SPEC §4, *Naming*).
For all fourteen rows here `artifact` is non-empty, so the token is always the artifact and
feature-002's confirmed-slug rule for artifact-less writers never applies to them. It does
apply to `/aid-brainstorm` (§5b).

### 5. `/aid-brainstorm`

#### 5a. Why it is a new skill rather than a mode of `/aid-research`

`/aid-research` opens by requiring "an open technical **question**" and returns "a
curated, verified answer in one pass" — a convergent contract, stated in its own
description (`canonical/skills/aid-research/SKILL.md:3-14`). A problem not yet formed
into a question has nothing to put in that slot. Making `/aid-research` accept one
would mean weakening the contract that makes it useful. The divergent case gets its
own doorway instead.

#### 5b. Row and doorway

```yaml
  - name: aid-brainstorm
    verb: brainstorm
    artifact: ""
    alias_of: null
    default_type: DESIGN
    group: G3
    intent: "Diverge on an unformed problem, then converge to a .aid/design/ seed; resolves nothing."
    repurpose: true
```

Hand-authored (`repurpose: true`), single-shot, and it **allocates a `work-NNN` folder**
like every other skill in this family (feature-002 SPEC §3e, *Allocation*; §6 there records
that this spec and that one now agree). Output path uses feature-002 SPEC §4's
artifact-less rule: `.aid/design/<slug>.md` with the kebab-case slug **confirmed with the
user**, since `artifact` is `""`.

> **Correcting an earlier draft of this section**, which said `/aid-brainstorm` allocates
> no work folder on the grounds that the seed is its whole output. REQUIREMENTS FR-3 is
> explicit that these skills run "in the same shape `/aid-design` and `/aid-prototype`
> already have: allocate a `work-NNN` folder, run single-shot, get graded", and
> feature-002 SPEC §3e binds all 36 skills to it. The seed being the deliverable does not
> remove the need for the folder — the folder is where `STATE.md` and the review gate
> live, which is how FR-3 makes an on-demand skill "first-class and tracked" without
> extending the `phase:` enum.

`brainstorm` is a **new verb**. Two consequences, both verified rather than assumed:

- `site/scripts/skills/groups.mjs` derives families from catalog rows (`:255-262`), and
  `aid-brainstorm` is not in `CURATED_GROUPS` (`:63-111`), so a `brainstorm` family section
  with one card appears on the published index automatically, with no code change.
  **Single-card families are the norm:** counting each verb's non-curated rows, twelve of
  the sixteen rendered families have exactly one — `fix`, `refactor`, `remove`,
  `deprecate`, `migrate`, `experiment`, `design`, `report`, `review`, `research`,
  `deploy`, `monitor`. *Correcting an earlier draft*, which named `query` among them:
  `query`'s only row is `aid-ask`, which **is** curated (`groups.mjs:86`), and a verb whose
  every member is curated produces no section at all (`:246`, `:255`). `query` is the one
  verb in the catalog with that property, so it is a counterexample to the claim it was
  cited for rather than an instance of it.
- The engine's verb→family table gains no `brainstorm` entry, for the same `repurpose`
  reason as §3c.

#### 5c. Not in the pipeline

`/aid-brainstorm` adds no value to the `phase:` enum and no step to the numbered
sequence. It is an on-demand skill. Feature-006's closing sweep (its SPEC §8b) is the
oracle.

### 6. The fifteen new `SKILL.md` bodies

Fourteen `aid-design-<artifact>/SKILL.md` plus `aid-brainstorm/SKILL.md`. They are the
bulk of this feature's authored output, and specifying them is what keeps fifteen authors
from writing fifteen different lifecycles.

#### 6a. Every body binds the contract; no body restates it

`canonical/aid/templates/design-lifecycle.md` — authored by feature-002 (its SPEC §1a and
§3) — is the contract. Feature-002 SPEC §3g is the binding table, and its Class 2 (the 14)
and `/aid-brainstorm` columns state exactly which rules reach these fifteen: §2d
(create `.aid/design/` and seed its `README.md` on first use), §3a (the `design` stage's
reads/writes/termination **and** the invariant that `design` never writes
`.aid/knowledge/` or production code), §3e (frontmatter fields, state list, the
`description` contract, allocation via the Work Initiation Gate, full verify on `design`),
§3f (row shape), and §4 (the seed's literal headings, the `<token>` naming rule, and — for
the fourteen — the required `## Destination` section).

Each body therefore carries a binding line, in the shape the generated doorways already
use for the engine (`canonical/skills/aid-create-api/SKILL.md:18`) but pointing at the
contract, because these are not engine doorways:

> Bind **VERB=`design`**, **ARTIFACT=`<artifact>`** — the `design` *stage* in the
> contract's vocabulary — then follow the shared contract at
> `canonical/aid/templates/design-lifecycle.md`.

`VERB`/`ARTIFACT` rather than `STAGE`, because those are the catalog's own field names and
the tokens `test-catalog-dirs-parity.sh` looks for in a body (`:151-167`). That suite exempts
`repurpose: true` rows from the body assertion (`:143-145`), so these fifteen are not
*required* to carry the tokens — using them anyway costs nothing and keeps one vocabulary
across the catalog, the generated doorways and these hand-authored ones.

and its state headings, modeled on `canonical/skills/aid-design/SKILL.md` — the skill
feature-002 SPEC §3e models the shape on:

| State | Content |
|---|---|
| `## State: INTAKE` | Require a subject; classify complexity for the `aid-architect` tier; consult the Work Initiation Gate and allocate, per the contract's Allocation rule (`aid-design/SKILL.md:45-53` is the shape) |
| `## State: DESIGN` | Dispatch `aid-architect` to write or iterate `.aid/design/<token>.md` in the seed shape (feature-002 SPEC §4) |
| `## State: VERIFY` | Full verify, as the contract defines it |
| `## State: PRESENT` | Hard stop; the user iterates by re-invoking |
| `## State: DONE` | `lifecycle: Completed`; the seed persists (feature-002 SPEC §2c Entry C) |

**No body restates a rule the contract states.** A body that spells out the invariant, the
allocation steps, or the seed's headings is the fifteen-way fork feature-002 exists to
prevent; it points at them instead. §8 V15 checks the binding is present, V16 checks the
restatement is absent.

#### 6b. The four things that vary per body

Everything else is identical across the fifteen. The variation is exactly:

1. **The bound `{stage, artifact}` pair and the seed path** — `.aid/design/<artifact>.md`
   for the fourteen (§4c); a confirmed slug for `/aid-brainstorm` (§5b).
2. **The `description`'s negative route** — §7b assigns it per skill.
3. **The `argument-hint`** — names a subject, never a question. For `/aid-brainstorm` this
   is load-bearing: it is half of AC-2's oracle (§8 V11).
4. **The DESIGN state's artifact-specific slot hints** — one to three lines naming what
   this artifact's seed must actually settle (for `api`: the resource shape, the contract,
   the error model; for `data-model`: entities, relationships, migration impact; and so
   on). The seed's six headings supply the *structure* (feature-002 SPEC §4), so this is
   content guidance only, never a second shape.

`/aid-brainstorm` differs from the fourteen in three places, all of them already settled
by feature-002 SPEC §3g's `/aid-brainstorm` column: the confirmed-slug name, the
**optional** `## Destination` section, and the absence of any `create` counterpart to
route to — which is why its `description`'s neighbour is `/aid-research` (§7b) rather than
a `create` skill.

### 7. Description edits and negative routing

#### 7a. The five shipped descriptions that change

| Skill | Change | Why |
|---|---|---|
| `aid-design` (bare) | Drop "an architecture sketch" from **both** the `description` (`canonical/skills/aid-design/SKILL.md:5`) and the `argument-hint` (`:14`); present as the catch-all for subjects with no dedicated `design` row | With 14 dedicated rows plus `/aid-design-architecture` (feature-004), advertising an architecture sketch routes users away from the specific doorway. Bare verbs are catch-alls by existing convention (`aid-create`, `aid-update`). `grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md` returns `2` today — both hits are in this file, and a description-only edit would leave the second standing |
| `aid-research` | Add the negative route to `/aid-brainstorm` | FR-6 mutual routing; the pair is confusable by construction (§5a) |
| `aid-prototype-ui` | State the kept-vs-throwaway route to `/aid-design-ui` | AC-5 |
| `aid-document` | Add the route to `/aid-design-document` | AC-8 mutuality on a pair this feature owns under CC-9 (§7c). Hand-authored (`repurpose: true`), so the description is editable in place |
| `aid-create-document` | Add the route to `/aid-design-document` | Same. This file is already touched by §4b's seed read, so the edit adds no new file to the change set |

**Precision on AC-5.** `/aid-design-ui` is **not** a shipped skill — it is one of this
feature's own fourteen new rows (§2), confirmed by `ls canonical/skills/ | grep design-ui`
returning nothing and by the catalog carrying no such row. So AC-5 is satisfied by one
*edit* (to shipped `aid-prototype-ui`) and one *authoring obligation* (on new
`aid-design-ui`, §6). Only `aid-prototype-ui` belongs in this table — and the Description
section (d) is worded to match.

Bare `/aid-design`'s **behavior** is unchanged — this is a description edit only.
Feature-002 SPEC §5 settled that its output is not redirected to `.aid/design/`, and its
§7 G1 is the scoped diff that fails if this edit reaches beyond the frontmatter.

#### 7b. The per-skill neighbour assignments (NFR-4)

NFR-4 binds each *description*: every new skill names its nearest confusable neighbour as
a negative route. It is an obligation on the skill being written, not on the pair — AC-8 is
what makes a *pair* mutual, and §7c handles those.

| Skill(s) | Names as negative route | Because |
|---|---|---|
| each `/aid-design-<artifact>` (all 14) | `/aid-create-<artifact>` | "develop the idea here; build it there" — the stage confusion, which is the nearest one for every artifact in the grid |
| `/aid-design-ui` | additionally `/aid-prototype-ui` | kept vs throwaway (FR-6); AC-5 |
| `/aid-design-test` | additionally `/aid-design-testing-strategy` (feature-004) and `/aid-test` | one designs a test, the second designs the policy, the third *runs* suites (`shortcut-catalog.yml:378`) |
| `/aid-design-config` | additionally `/aid-design-stack` (feature-004) | configuring a stack vs choosing one — assigned by feature-004 SPEC §10, whose `aid-design-stack` row names `/aid-design-config` |
| `/aid-design-infra` | additionally `/aid-design-cicd` (feature-004) | designing a resource vs designing the pipeline that ships to it — assigned by feature-004 SPEC §10, whose `aid-design-cicd` row names `/aid-design-infra` |
| `/aid-design-document` | additionally bare `/aid-document` and `/aid-create-document` | design the document vs write it |
| `/aid-brainstorm` | `/aid-research` | FR-7's table; it has no `create` counterpart to route to |

**How this list was checked for completeness.** Two searches, both re-runnable:

1. Every catalog row's `name` and `intent` was read for an overlap with one of the fifteen
   subjects (`grep -nE '^  - name:|^    intent:' canonical/aid/templates/shortcut-catalog.yml`,
   58 rows). Beyond the `create`/`update` rows the table's first line already covers, the
   hits are: `aid-prototype-ui` (`ui`), the eight-row G8 `document` family plus bare
   `aid-document` (`document`), `aid-test` (`test`), and `aid-deploy` (`infra`/`cicd`). The
   first three are carried in the table above. `aid-deploy` is carried by feature-004 on
   `/aid-design-cicd` (its SPEC §10, `:644`) and is not a nearer neighbour of
   `/aid-design-infra` than `/aid-design-cicd` is, so it is deliberately not added here.
2. Both sibling assignment tables were read for a row naming a feature-005 skill.
   `grep -n 'feature-005' features/feature-004-foundation-artifact-skills/SPEC.md` returns
   its §10 rows at `:640`, `:642`, `:644` — the three now carried above. The same search
   over feature-003's SPEC returns no assignment row at all; its §6d neighbours are
   confined to its own nine skills.

**The reverse direction on the fourteen `create` doorways is deliberately not written**,
and the reason is concrete rather than convenience: those doorways are *generated*, and
their `description` is produced from the catalog row's `intent`
(`canonical/skills/aid-create-api/SKILL.md:4` embeds its row's `intent` verbatim in
parentheses). Writing the reverse route would mean editing fourteen shipped `intent`
strings and re-rendering fourteen shipped descriptions — a change to shipped skills that
§1 excludes. NFR-4's own wording ("name its **nearest** neighbour") is satisfied without
it: for `/aid-create-api` the nearest confusion remains bare `/aid-create`, not a design
skill. AC-8's pairs are unaffected — none of them is a `design-X` ↔ `create-X` pair (§7c).

#### 7c. AC-8 pair ownership

Ownership follows REQUIREMENTS FR-11 **CC-9**; this section applies that rule rather than
handing pairs out. (Feature-004 SPEC §10's preamble at `:630-633` reads the assignment as a
hand-off *from this section*. The assignments coincide, but the source is CC-9 — a spec
cannot allocate work to a sibling.)

| Pair | Owner under CC-9 | Side(s) written here | Verifiable at this feature's close |
|---|---|---|---|
| `/aid-brainstorm` ↔ `/aid-research` | this feature | both | **yes** — §8 V7 |
| `/aid-design-ui` ↔ `/aid-prototype-ui` | this feature | both | **yes** — §8 V8 |
| `/aid-design-document` ↔ `/aid-document` ↔ `/aid-create-document` | this feature | all three | **yes** — §8 V9 |
| bare `/aid-design` ↔ this feature's fourteen `design` rows | this feature | both | **yes** — §8 V6, V10 |
| `/aid-design-test` ↔ `/aid-design-testing-strategy` | feature-004 | `/aid-design-test` | no — counterpart lands in feature-004 |
| `/aid-design-config` ↔ `/aid-design-stack` | feature-004 | `/aid-design-config` | no — same |
| `/aid-design-infra` ↔ `/aid-design-cicd` | feature-004 | `/aid-design-infra` | no — same |
| bare `/aid-design` ↔ features 003/004's `design` rows | those features | the bare side only (§7a) | no — counterparts land there |

**This feature writes one side of exactly three cross-feature pairs**, which is what
feature-006 SPEC §8a already assumes of it. Pairs in which this feature writes **no** side
— the `/aid-*-architecture` trio and `/aid-create-cicd` ↔ `/aid-create-infra`, both
feature-004's under CC-9 — are not this feature's to assert, and AC-8 makes no claim about
them. An earlier draft listed them here and distinguished them by hardcoded destination
filenames (`architecture.md`, `infrastructure.md`); CC-6 settles that destinations resolve
by concern, so both the claim and its filenames are withdrawn.

**The bare-verb pair is discharged at class level, not by enumeration.** One side of it is
twenty-two rows, which no `description` can list. Bare `/aid-design`'s narrowed text names
the *class* ("use the dedicated `/aid-design-<artifact>` row when one exists"), and each
artifact row names its own nearest neighbour per §7b. §8 V6 is the oracle for the bare
side.

### 8. Verification

Every row is a **script** (a runnable command), a **suite** (a named existing test), or a
**review** (a judgement a reviewer makes). No row is a restatement of intent.

| # | Check | Oracle | Kind | Closes |
|---|---|---|---|---|
| V1 | Fifteen directories exist | `ls -d canonical/skills/aid-design-{api,ui,theme,cli,data-model,data-pipeline,messaging,integration,job,config,infra,test,document,dashboard} canonical/skills/aid-brainstorm` → 15 lines, exit 0 | script | AC-1 |
| V2 | The fourteen are the right fourteen | Run §2's derivation against `git show master:canonical/aid/templates/shortcut-catalog.yml`; `comm -3` its sorted output against the sorted `artifact` values of this feature's fourteen new `design` rows → empty, both directions | script | AC-6 |
| V3 | `name` == directory == frontmatter `name:` | `bash tests/canonical/test-catalog-dirs-parity.sh` green. It asserts exactly this, per row, at `:126` (dir exists), `:135` (SKILL.md exists) and `:141` (`CDP{i}d` frontmatter `name:` == directory == row name), and it is count-agnostic by design (`:21-23`), so it extends by data with **no edit** | suite | AC-1 |
| V4 | `alias_of: null` on every new row | With `C=canonical/aid/templates/shortcut-catalog.yml`: `[ "$(grep -c '^    alias_of: null$' "$C")" = "$(grep -c '^  - name:' "$C")" ]` — count-free, and it fails if any new row omits, misspells or aliases the field. **`test-catalog-dirs-parity.sh` is not an oracle for this**: `:72-77` records `alias_of` as dead input there, parsed and never asserted. The shipped assertions are `DMR31`/`DMR32` (`tests/canonical/test-deploy-monitor-repurpose.sh:320-323`), which pair the `alias_of: null` count against the row total — but their expected values are count-bearing and are retuned by feature-006 (§9), so they are the oracle from feature-006 onward, not at this feature's close | script | AC-1 |
| V5 | No architecture sketch survives | `grep -c 'architecture sketch' canonical/skills/aid-design/SKILL.md` → `0` (today `2`: `:5`, `:14`) | script | AC-4 |
| V6 | Bare `/aid-design` reads as the catch-all | Its `description` names the dedicated `design` rows as the route away from itself (§7c) — grep for `aid-design-` in the frontmatter block, then a reviewer confirms the text reads as a catch-all rather than an artifact list | script + review | AC-4 |
| V7 | `research` ↔ `brainstorm` mutual | `grep -q 'aid-brainstorm' canonical/skills/aid-research/SKILL.md` **and** `grep -q 'aid-research' canonical/skills/aid-brainstorm/SKILL.md`, both within the frontmatter `description:` block | script | AC-3 |
| V8 | `design-ui` ↔ `prototype-ui` mutual | Same name-presence shape over `canonical/skills/aid-prototype-ui/SKILL.md` and `canonical/skills/aid-design-ui/SKILL.md`; **plus** a reviewer read confirming each states the kept-vs-throwaway distinction, which AC-5 requires and a name grep does not establish | script + review | AC-5 |
| V9 | The `document` trio is mutual | `/aid-design-document`'s description names both neighbours; `aid-document/SKILL.md` and `aid-create-document/SKILL.md` each name `/aid-design-document` | script | AC-8 |
| V10 | Every side this feature writes | For each row of §7b and §7c, the neighbour's literal name appears in that skill's `description:` — the 15 new descriptions, plus the four of §7a's five shipped edits that name a literal neighbour (bare `/aid-design` names a class instead; V6 covers it). A description naming a neighbour §7b does not assign fails too | script | AC-8 |
| V11 | `/aid-brainstorm` needs no question | Its `argument-hint` names a subject, not a question, **and** its INTAKE state has no step that refuses on a non-question argument. Both halves are readings of the authored body, and "names a subject, not a question" is a judgement no grep settles | review | AC-2 |
| V12 | The seed read reaches all fourteen | `grep -c '\.aid/design/{artifact}\.md' canonical/aid/templates/shortcut-engine.md` → `1`, **and** `grep -l '\.aid/design/document\.md' canonical/skills/aid-{create,update}-document/SKILL.md` → both files | script | AC-7 |
| V13 | The engine edit is additive, and bounded | `git diff --numstat master -- canonical/aid/templates/shortcut-engine.md` shows **0 deletions**, and the added lines fall in exactly two hunks: the CAPTURE Step 2 bullet (§4a) and the `query`-paragraph extension (§3c). Deletions ≠ 0 means an existing rule was altered. A whole-file `--exit-code` diff would be unsatisfiable — this feature does edit the file — so the base ref is explicit and the assertion is on the diff's shape | script | AC-7 |
| V14 | Absent seed ⇒ unchanged behavior | Two runs of `/aid-create-api` on the same scratch project with **no** `.aid/design/`: one from `master`'s engine, one from the changed engine; the CAPTURE slot set is identical. The baseline must be **captured first** — the slot set is agent judgment (`shortcut-engine.md:388-397`), not a recorded artifact, so there is nothing to compare against after the fact | review (behavioral; the baseline capture is the part that is skippable and must not be skipped) | AC-7, REQUIREMENTS AC-10 |
| V15 | The fifteen bodies bind the contract | `grep -L 'canonical/aid/templates/design-lifecycle.md' canonical/skills/aid-design-*/SKILL.md canonical/skills/aid-brainstorm/SKILL.md` → empty output | script | AC-9 |
| V16 | No body forks the contract | A reviewer reads the fifteen against feature-002's `design-lifecycle.md`: no body restates the `design` invariant, the allocation steps, the seed headings or the verify depth. Prose conformance has no script | review | AC-9 |
| V17 | No row outside the selection | This feature's `design` rows are exactly the fourteen of §2 — in particular it adds none for `architecture`, `stack`, `testing-strategy` or `cicd`, which are feature-004's (its SPEC §1a) | script (the V2 `comm`) | AC-6 |
| V18 | `kb` and the ticket skills stay outside the catalog | `grep -cE '^  - name: (aid-update-kb\|aid-(read\|create\|update)-ticket)$' canonical/aid/templates/shortcut-catalog.yml` → `0`. Anchored on the row form, because the catalog mentions `aid-update-kb` in a comment at `:457` | script | AC-6 |
| V19 | The `brainstorm` family renders | `groups.mjs` derives it from the row (`:255-262`) and `aid-brainstorm` is absent from `CURATED_GROUPS` (`:63-111`), so a one-card section appears. The run-time oracle is feature-006's site guard (its SPEC §10) | review | — |

Counts are not verified here: `DMR30`/`DMR31`/`DMR33` and `check-skill-counts.mjs` are
aggregates over the finished set of thirty-six and are retuned once, by feature-006 (§9).

### 9. Boundaries

**Depends on feature-002** — and on four named parts of it, not on the folder alone:

| Consumed | For |
|---|---|
| feature-002 SPEC §2 (`.aid/design/` landed, README corrected) and §2d (first-use acquisition) | the folder the seeds live in; the rule every body inherits |
| feature-002 SPEC §3 — the `design-lifecycle.md` contract, via §3a, §3b, §3e, §3f and the §3g binding table | §6's fifteen bodies and §3a's row shape |
| feature-002 SPEC §4 — `design-seed.md`, its literal headings and the `<token>` naming rule | §4a's engine read consumes that shape; §4c and §5b resolve the token |
| feature-002 SPEC §5 | the bare `/aid-design` description edit this feature owns (§7a) |

Feature-002 SPEC §6 lists this feature as consuming exactly that set, and §4 there is
**frozen once this feature starts** — the engine read and the two `document` doorway reads
consume seeds in that shape. Rows and doorways can be authored before feature-002 lands;
the seed reads cannot be *exercised* until it does.

**Depends on feature-004 for three counterpart descriptions** — `/aid-design-testing-strategy`,
`/aid-design-stack`, `/aid-design-cicd` (§7c). This feature's three sides are written
regardless; only the *mutuality* waits.

**Deferred to feature-006, deliberately:** every count-bearing assertion (`TOTAL_ROWS`,
`CANONICAL_ROWS`, the repurpose decomposition, `check-skill-counts.mjs`), the full render,
the byte-identity gate, and the whole-set mutual-routing sweep. Each is an aggregate over
the finished set of thirty-six; computing it here yields a number that is wrong the moment
feature-003 or feature-004 lands.

**Explicitly out of scope:** removing `alias_of`; adding a `design` family scaffolding
file (feature-002 SPEC §1e); changing bare `/aid-design`'s behavior; the reverse routing
direction on the fourteen generated `create` doorways (§7b); and modifying any of the 28
paired create/update doorways beyond the two `document` files named in §1's table.
