# Foundation Artifact Skills

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5.3 (architecture, stack, testing-strategy, cicd rows), FR-2, FR-4 | /aid-define |
| 2026-08-09 | Technical Specification authored | /aid-specify |
| 2026-08-09 | Technical Specification rewritten whole against spec review round 1 (21 findings, 2 CRITICAL). The two criticals drove structural change: the feature-001 dependency on membership **and** on the skill-created-conditional doctrine amendment is now declared as blocking (§12), and the file-level `create` refusal — which made the seed unconsumable on every brownfield project — is replaced by REQUIREMENTS FR-1's region-level rule, so `create` gates on its seed and never on the destination being populated (§6). Also: destinations resolve by **concern**, not by filename (§3); the three cross-destination content collisions are assigned (§4); the eight `create`/`update` skills gain per-artifact destination, region and content rules (§7); the greenfield-seed and no-contention claims in the Description are corrected against disk; acceptance criteria are labelled AC-1..AC-14 and each names an oracle that can fail | /aid-specify |
| 2026-08-09 | Rewritten against spec review round 2 (26 findings, 3 CRITICAL, 5 recurred) and against REQUIREMENTS **FR-11**, which settles nine cross-feature contracts (CC-1..CC-9) this spec now *refers to* rather than restating. Structural: `update` reads and consumes a present seed (CC-3), so AC-5, §6b's repeat-`create` path and §6c's discriminator table are rebuilt around *requires* rather than *consumes*; §6b states how feature-002 §3c's four first-write rows resolve when the owned region is the whole document, instead of omitting them; §8a's registration surfaces are CC-4's four (two of which are already occupied on disk) and the doc-set entry is demoted from "surface" to CC-2 runtime write, with presence `required` per CC-1 and the owner taken from the doc's matrix row; §3b's registration gains the `README.md` completeness row, the doc-set count and the `aid-config` amendment shared with feature-003; §4's collision derivation is re-run over **five** destinations (ten pairs) and yields a fourth contested topic; the twelve `intent` strings are supplied; every AC's oracle was re-read at its own line and four were replaced (AS02, AS07, and two `git diff --exit-code` checks that cannot fail after a commit); two acceptance criteria added so no verification row is orphaned; every cross-spec citation converted to a section anchor and re-verified against the sibling's current text | /aid-specify |

## Source

- REQUIREMENTS.md §5.3 (the skill set — architecture, stack, testing-strategy, cicd rows)
- REQUIREMENTS.md FR-1 (three-verb lifecycle; **the region-level rule for populated
  destinations**), FR-2 (one skill per foundation), FR-4, FR-8
- REQUIREMENTS.md FR-6 (the `testing-strategy` naming decision), FR-9 (conditional docs)
- REQUIREMENTS.md **FR-11** — the cross-feature contracts. This spec **refers to** CC-1
  (resolved presence is `required`), CC-2 (the `create` skill writes the registration),
  CC-3 (`update` reads its seed when one exists), CC-4 (the four registration surfaces),
  CC-5 (a region-owning skill never creates its document), CC-6 (destinations resolve by
  concern) and CC-9 (confusable-pair ownership), and **restates none of them**.
- REQUIREMENTS.md §9 AC-6, **AC-6b** (the brownfield sequence), AC-7, AC-8

## Description

Twelve skills covering the four foundational concerns — the technical standards a
project settles early and every later phase reads:

| Artifact | `design` | `create` | `update` | Concern | Default destination |
|----------|----------|----------|----------|---------|---------------------|
| architecture | `/aid-design-architecture` | `/aid-create-architecture` | `/aid-update-architecture` | C1 | `architecture.md` |
| stack | `/aid-design-stack` | `/aid-create-stack` | `/aid-update-stack` | C0 | `technology-stack.md` |
| testing strategy | `/aid-design-testing-strategy` | `/aid-create-testing-strategy` | `/aid-update-testing-strategy` | C6 | `test-landscape.md` + `quality-gates.md` (conditional, §8) |
| ci/cd | `/aid-design-cicd` | `/aid-create-cicd` | `/aid-update-cicd` | C8 | `infrastructure.md` |

The concern column, not the filename column, is what the skills bind to — **CC-6**, which
this feature implements in §3 and does not restate. The four foundation artifacts are
exactly the population CC-6 names.

Each foundation is its own skill rather than one switch-driven
`/aid-design-foundations`, because each lands in a different destination document with
different content rules and asks genuinely different questions — choosing a testing
strategy has nothing in common with choosing a CI runner. §5 and §7 state those content
rules per artifact; the claim is not left as an assertion.

**The destinations overlap in content in four places, and the overlaps are assigned
rather than denied.** `test-landscape.md` carries its own `## CI/CD Pipeline` section
(`canonical/aid/templates/knowledge-base/test-landscape.md:85`), which collides with
`/aid-*-cicd`'s destination `infrastructure.md`; `technology-stack.md`'s
`## Test Frameworks` (`:95`) collides with `test-landscape.md`'s
`## Test Framework Inventory` (`:36`); `technology-stack.md`'s `## Build System`
(`:57`) collides with `infrastructure.md`'s `## Deployment Pipeline` (`:97`); and the
gate policy in `quality-gates.md` collides with the pipeline stage that enforces it in
the C8 doc. §4 gives each contested topic exactly one owning skill. `testing-strategy`
also writes two documents, but each region still has a single owning skill.

The artifact is named `testing-strategy`, not `test-strategy`, so that it reads as
policy rather than test code and stays distinct from the `test` artifact that already
exists on the create/update grid — and, once feature-005 lands, from `/aid-design-test`.

**The greenfield forward-authored seed is five documents, and it overlaps this feature in
two places, not four.** `/aid-describe`'s DESCRIBE-SEED authors `domain-glossary.md`,
`architecture.md`, `coding-standards.md`, `technology-stack.md`, and `decisions.md`
(`canonical/skills/aid-describe/references/state-describe-seed.md:186-188`; "the 5-element
KB seed", same file `:7`). `test-landscape.md` and `infrastructure.md` are **not**
forward-authored by it. So the design-versus-as-built authority question — and the
`/aid-housekeep` Conformance Lane that reconciles it (§9) — reaches `architecture` and
`stack` by that route, and reaches `testing-strategy` and `cicd` only if some other
producer marks their destinations `forward-authored`.

## User Stories

- As an **adopter starting a project**, I want to decide the stack, architecture, testing
  standards, and CI/CD deliberately and have each decision land in the right KB
  document, so that later phases read a settled foundation rather than guessing.
- As an **adopter on an existing project**, I want to author foundations that were never
  written down, without pretending they are new decisions.
- As an **AI agent**, I want each foundational concern in its conventional document, so
  that existing KB routing continues to work unchanged.

## Priority

Must

## Acceptance Criteria

Each criterion names the oracle that fails if the work is done wrong, and every named
oracle was opened at its own line while this list was written. `<A>` ranges over
`architecture | stack | testing-strategy | cicd`.

- [ ] **AC-1 — Twelve skills, twelve complete rows.**
      `ls -d canonical/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}`
      lists twelve directories, and
      `grep -cE '^  - name: aid-(design|create|update)-(architecture|stack|testing-strategy|cicd)$' canonical/aid/templates/shortcut-catalog.yml`
      returns `12`. Seven of the eight fields are parser-enforced:
      `build-shortcut-skills.py` raises `CatalogError` on a missing member of
      `_REQUIRED_FIELDS` (`:55` — `name`, `verb`, `artifact`, `alias_of`, `default_type`,
      `group`, `intent`) and on a `default_type` outside the closed 8-enum (`:219-224`).
      **`repurpose` is not among them.** A row that loses it raises nothing; `:354` reads
      it with `r.get("repurpose", False)`, so the row silently becomes a generated
      doorway. The oracle for the eighth field is therefore V3's byte-identity diff, not
      the parse.
- [ ] **AC-2 — `design` writes only `.aid/design/`.** After running each of the four
      `design` skills, `git status --porcelain .aid/knowledge/ .github/` is empty and
      `.aid/design/<A>.md` exists.
- [ ] **AC-3 — The brownfield sequence completes (REQUIREMENTS AC-6b).** In this
      repository as it stands — `.aid/knowledge/architecture.md` is 515 lines with
      `source: hand-authored` (`:3`) — running `/aid-design-architecture` then
      `/aid-create-architecture` leaves `test ! -f .aid/design/architecture.md` **true**
      and `git diff --stat .aid/knowledge/architecture.md` **non-empty**. A `create` that
      refuses because the destination is populated fails both halves. The same run is
      repeated for the other three artifacts.
- [ ] **AC-4 — `create` gates on its seed, never on the destination being populated.**
      Four runs per artifact: (a) no seed → refuses, names `/aid-design-<A>`,
      `git status --porcelain .aid/knowledge/` clean; (b) seed whose `## Open questions`
      is non-empty by feature-002 §4's detection rule, no override → refuses, seed still
      present; (c) seed ready, destination populated → destination diff non-empty and
      seed gone (this run is V5's, shared with AC-3); (d) a **repeat** `create` whose seed
      targets content the first run committed → the new part is written, the committed
      part is byte-identical, the run names `/aid-update-<A>` for it, and the seed
      survives with only the unrealized part (§6c). And **no destination-populated refusal
      exists anywhere**: each `create` `SKILL.md`'s CREATE state enumerates exactly the
      three gates of §6c's table (seed-absent, Open-questions, `source: generated`).
      *Oracle for that clause:* for each of the four files, the CREATE state enumerates
      exactly three refusal conditions, and
      `grep -niE 'empty|populated|non-empty|hand-authored|line count'` over that state's
      text returns nothing. A fourth gate keyed on the destination's size, emptiness or
      `source: hand-authored` is the defect this criterion exists to catch — it is how the
      round-1 file-level refusal re-enters.
- [ ] **AC-5 — `update` requires no seed, and consumes one when present (CC-3).**
      (a) With `.aid/design/<A>.md` absent, `/aid-update-<A>` completes and
      `git diff --stat` on the destination is non-empty — it neither refuses nor names a
      missing seed. (b) With the seed present, after the run
      `test ! -f .aid/design/<A>.md` is **true** and the destination diff carries the
      seed's `## Current direction` content. Both halves are required: (a) alone would be
      satisfied by an `update` that ignores seeds, (b) alone by one that demands them.
- [ ] **AC-6 — The contested regions are owned as §4 assigns them.**
      `git diff --name-only .aid/knowledge/` after `/aid-create-cicd` lists the C8 doc and
      **not** the C6 doc(s); after `/aid-create-testing-strategy` it lists the C6 doc(s) —
      `test-landscape.md` and `quality-gates.md` — and **not** the C8 doc; after
      `/aid-create-stack` it lists the C0 doc, **plus the D doc when and only when the
      seed's `## Options considered` carried a rejected alternative** (§7d), and never a
      C1, C6 or C8 doc. Writing into another *artifact's* destination is the failure; the
      D doc is not another artifact's destination — no skill in this feature owns it.
- [ ] **AC-7 — `quality-gates.md` occupies all four of CC-4's registration surfaces.**
      The four surfaces, their state on disk, and the per-surface oracle are the table in
      §8a and are not duplicated here — two are already occupied and must still return
      their hits, two are this feature's to write. The criterion is that all four pass
      together. Two clauses bind in addition: the concern id (**C6**) is asserted on
      surfaces 1 and 2 by grep — the matrix rows' spine-dimension field reads `C6` and the
      `concern-model.md` entry names it — and **not** by `AS07`, which iterates a `find`
      over `canonical/aid/templates/knowledge-base/`
      (`tests/canonical/test-kb-template-authoring-standard.sh:50`, loop at `:117-131`) and
      so can never see a document with no template there (§8); and
      `bash tests/canonical/test-domain-doc-matrix.sh` is green with MT01–MT18
      **unmodified**. *Oracle:* V12.
- [ ] **AC-8 — Every one of the twelve descriptions carries its negative route.** For
      each row in §10's table, every neighbour name assigned there appears literally in
      that skill's `description:` frontmatter, and no description names a neighbour §10
      does not assign. Feature-006 §8a checks the pair set whole (feature-005 §6c); this
      criterion checks the twelve sides this feature owns.
- [ ] **AC-9 — FR-8 asking, and no tracking metadata (REQUIREMENTS AC-7).** Four parts,
      because "asks every run" is not observable from a working-tree listing alone:
      (a) **static** — each `update` `SKILL.md`'s UPDATE state contains the
      derived-outputs prompt as an unconditional step: `grep -n 'derived outputs'` returns
      a hit that is not inside an `if`/`when` clause;
      (b) **behavioral** — run the same `update` twice in one project; run 2 asks the
      question again;
      (c) **no stored answer** —
      `grep -rniE 'derived[-_]outputs|output_list|outputs:' .aid/settings.yml .aid/works/<work>/STATE.md`
      returns nothing, and the skill writes no other state file;
      (d) **no tracking metadata** —
      `grep -rniE 'derived-from|source-doc|generated-by|aid-tracked'` over every file the
      run wrote returns nothing.
      An `update` that never asks fails (a) and (b); one that asks once and remembers
      fails (b) and (c).
- [ ] **AC-10 — No KB frontmatter is forged or restamped.** `git diff` on the destination
      shows no change to `source:` and no change to `approved_at_commit:` (the invariant
      at `canonical/skills/aid-update-kb/references/state-apply.md:262`), and
      `bash canonical/aid/scripts/kb/lint-frontmatter.sh` is green.
- [ ] **AC-11 — `## Contents` stays consistent with the body.** After any `create` or
      `update`, the set of `^## ` headings in the destination (minus `## Contents`
      itself) equals the set of link texts in its `## Contents` list, both directions:
      `comm -3 <(grep '^## ' "$DOC" | sed 's/^## //' | grep -vx 'Contents' | sort) <(awk '/^## Contents$/{f=1;next} /^## /{f=0} f' "$DOC" | grep -oE '\[[^]]+\]' | tr -d '[]' | sort)`
      is empty. **Not `AS02`** — that assertion is a bare existence check,
      `if grep -q '^## Contents$' "$tmpl"` (`test-kb-template-authoring-standard.sh:75-78`),
      with no set comparison in either direction, and it is template-scoped besides.
- [ ] **AC-12 — Conformance-Lane obligations are observable, not just stated.** (a) Each
      of the four `create` skills discloses the lane consequence in its own frontmatter
      `description:`, using the literal phrase **`Conformance Lane`**:
      `grep -c 'Conformance Lane' canonical/skills/aid-create-<A>/SKILL.md` ≥ 1 with the
      hit inside the `description:` block. (b) Given a Conformance-Lane divergence flagged
      on the destination, `/aid-update-<A>` leaves the flag unresolved unless the user
      supplies the resolution: the diff touches only what the user named, and the flag
      survives a re-run of `/aid-housekeep`.
- [ ] **AC-13 — `testing-strategy` and `test` are two artifacts, not one.** The catalog
      contains rows with `artifact: testing-strategy` **and** rows with `artifact: test`,
      and no row anywhere carries `artifact: test-strategy`
      (`grep -c 'artifact: test-strategy' canonical/aid/templates/shortcut-catalog.yml`
      → `0`, which is its value today). `canonical/skills/aid-create-test/` and
      `canonical/skills/aid-create-testing-strategy/` are distinct directories. Mutual
      routing between `/aid-design-test` and `/aid-design-testing-strategy` is AC-8.
- [ ] **AC-14 — `phase:` untouched (C-1, NFR-3).**
      `git diff master -- canonical/aid/templates/work-state-template.md` is empty —
      **not** `git diff --exit-code`, which compares the working tree to `HEAD` and so
      passes trivially once the edit is committed (the same correction feature-002 §7 G2
      makes). Second half, because this feature could break C-1 without touching that
      file: after each of the twelve skills runs, its work's `STATE.md` has no `phase:`
      value (`grep -c '^phase: .' .aid/works/<work>/STATE.md` → `0`).
- [ ] **AC-15 — No seed-count assertion moves.** This feature adds no file under
      `canonical/aid/templates/knowledge-base/`, so `ls canonical/aid/templates/knowledge-base/*.md | wc -l`
      is `14` before and after, and `AS06`, `test-doc-set-read.sh`,
      `test-doc-set-mapping.sh`, `test-domain-doc-matrix.sh` and
      `test-spine-depth-coverage.sh` are green with
      `git diff master --` empty on each of their files and on
      `canonical/skills/aid-discover/references/doc-set-resolve.md`. *Oracle:* V13.
- [ ] **AC-16 — A document this feature creates is registered in the same run (CC-2).**
      On a project whose C8 doc is absent, `/aid-create-cicd` creates it **and**, in that
      run: `.aid/settings.yml` gains exactly one `knowledge.doc_set` entry whose presence
      field is `required` (CC-1) and whose owner is the doc's matrix owner (§3b);
      `.aid/knowledge/README.md` gains exactly one Completeness row and its
      `**Doc-set:** N documents` line (`:21`) increments by one. No hand edit outside the
      skill run performs any of this. *Oracle:* V14.

---

## Technical Specification

> **Section applicability.** Data Model, Feature Flow, and Layers & Components assume a
> code project; this feature authors twelve hand-authored skills. **N/A**. No conditional
> section auto-activates. §5–§7 stand in for Feature Flow; §3 (destination resolution),
> §4 (region ownership) and §8 (destination membership) carry what a Data Model section
> would.
>
> **Citation discipline.** Every path and line number below was opened at that line while
> this revision was written. Cross-feature rules settled by REQUIREMENTS FR-11 are
> **referred to by CC id and never restated** — restatement is what produced the drift the
> contracts exist to end. Cross-spec citations name a **section anchor**, never a line
> number, because sibling specs are being rewritten on the same branch.

### 1. Skill inventory and catalog rows

**1a. Twelve directories under `canonical/skills/`, twelve rows in
`canonical/aid/templates/shortcut-catalog.yml`.** Every field the contract requires is
given. Seven are parse-enforced — `_REQUIRED_FIELDS` in
`.claude/skills/generate-profile/scripts/build-shortcut-skills.py:55` is
`("name", "verb", "artifact", "alias_of", "default_type", "group", "intent")` — and
`repurpose: true` (feature-002 §3f) is the eighth, which the parser does **not** enforce
(AC-1).

| `name` | `verb` | `artifact` | `default_type` | `group` | `alias_of` | `repurpose` |
|--------|--------|-----------|----------------|---------|------------|-------------|
| `aid-design-architecture` | `design` | `architecture` | `DESIGN` | `G3` | `null` | `true` |
| `aid-design-stack` | `design` | `stack` | `DESIGN` | `G3` | `null` | `true` |
| `aid-design-testing-strategy` | `design` | `testing-strategy` | `DESIGN` | `G3` | `null` | `true` |
| `aid-design-cicd` | `design` | `cicd` | `DESIGN` | `G3` | `null` | `true` |
| `aid-create-architecture` | `create` | `architecture` | `DOCUMENT` | `G4` | `null` | `true` |
| `aid-create-stack` | `create` | `stack` | `DOCUMENT` | `G4` | `null` | `true` |
| `aid-create-testing-strategy` | `create` | `testing-strategy` | `DOCUMENT` | `G4` | `null` | `true` |
| `aid-create-cicd` | `create` | `cicd` | `DOCUMENT` | `G4` | `null` | `true` |
| `aid-update-architecture` | `update` | `architecture` | `DOCUMENT` | `G5` | `null` | `true` |
| `aid-update-stack` | `update` | `stack` | `DOCUMENT` | `G5` | `null` | `true` |
| `aid-update-testing-strategy` | `update` | `testing-strategy` | `DOCUMENT` | `G5` | `null` | `true` |
| `aid-update-cicd` | `update` | `cicd` | `DOCUMENT` | `G5` | `null` | `true` |

**The `intent` strings, supplied rather than deferred.** `intent` is one of the seven
fields the parser requires, so a row without it does not render; leaving it as "authored
per row" made the twelve rows unimplementable from this spec. Sibling feature-003 §1
supplies its nine the same way.

| `name` | `intent` |
|--------|----------|
| `aid-design-architecture` | "Develop the system's shape as a design seed (components, boundaries, interactions, invariants); writes no KB document — `/aid-create-architecture` realizes it." |
| `aid-design-stack` | "Develop the technology choice as a design seed (languages, runtimes, frameworks, build and test tooling with versions) plus the alternatives rejected and why." |
| `aid-design-testing-strategy` | "Develop the testing policy as a design seed (levels, coverage expectations, which gates block a merge, who may waive one); not test code." |
| `aid-design-cicd` | "Develop the delivery pipeline as a design seed (stages, triggers, environments, promotion); touches no workflow file." |
| `aid-create-architecture` | "Realize an architecture seed into the project's build-and-shape (C1) Knowledge Base document; rejected alternatives go to the decisions document." |
| `aid-create-stack` | "Realize a stack seed into the project's technology (C0) Knowledge Base document, versions included; rejected alternatives go to the decisions document." |
| `aid-create-testing-strategy` | "Realize a testing-strategy seed into the project's quality (C6) documents — the test landscape and the gate policy — creating the gate document on first use." |
| `aid-create-cicd` | "Realize a CI/CD seed into the project's shipping (C8) Knowledge Base document: stages, triggers, environments, promotion, and the release flow." |
| `aid-update-architecture` | "Revise the project's build-and-shape (C1) Knowledge Base document, plus any previously created outputs." |
| `aid-update-stack` | "Revise the project's technology (C0) Knowledge Base document — versions, dependencies, constraints — plus any previously created outputs." |
| `aid-update-testing-strategy` | "Revise the project's quality (C6) documents — test landscape and gate policy — plus any previously created outputs." |
| `aid-update-cicd` | "Revise the project's shipping (C8) Knowledge Base document — pipeline stages, environments, release flow — plus any previously created outputs." |

Because all twelve are `repurpose: true`, each `SKILL.md` is hand-written rather than
generated from `intent`, so the two are separate texts; §10 fixes the negative-routing
clause each of the twelve `description:` fields must carry.

Three field choices need their reason recorded:

- **`default_type: DESIGN` on the four `design` rows** matches the shipped `aid-design`
  row (`shortcut-catalog.yml:441-448`). **`DOCUMENT` on the eight `create`/`update`
  rows** matches `aid-create-document` / `aid-update-document`
  (`:459-474`) — the existing precedent for a hand-authored `create`/`update` row whose
  product is a document rather than built code. The value is inert for a `repurpose: true`
  row (it is consumed at the engine's DETAIL state, which a hand-authored doorway never
  reaches) but it is required and must not be arbitrary. `IMPLEMENT` would be wrong: these
  rows produce no code.
- **`group: G4`/`G5` for `create`/`update`** follows the same assignment sibling
  feature-003 §1 makes for its nine rows. `group` and the published-index family are
  different axes — see 1b.
- **`alias_of: null`** on all twelve. The field is deprecated-but-required
  (`build-shortcut-skills.py:54-55`); its removal is a scheduled follow-on outside this
  work.

**No `(verb, artifact)` key collides.** `artifact: architecture` already exists on
`aid-document-architecture` (`shortcut-catalog.yml:499-506`), but with `verb: document`,
so the four architecture rows added here are distinct keys. `artifact: cicd`,
`artifact: stack` and `artifact: testing-strategy` are new tokens; each of
`grep -c 'artifact: cicd'`, `grep -c 'artifact: stack'` and
`grep -c 'artifact: testing-strategy'` on the catalog returns `0` today.

**1b. Placement, and its one observable consequence.** The four `design` rows go in the
G3 block after feature-005's fourteen; the four `create` rows at the end of the G4 block;
the four `update` rows at the end of the G5 block. `site/scripts/skills/groups.mjs` derives
family **order** by walking `catalog.rows` in file order and appending each newly-seen
`verb` (`:129-133`, `:244-262`), and orders cards within a family by row order (`:301-304`).
All three verbs are already seen verbs, so no new family section appears on the published
index and only card order within three existing families changes.

**1c. Seed paths.** `.aid/design/architecture.md`, `.aid/design/stack.md`,
`.aid/design/testing-strategy.md`, `.aid/design/cicd.md` — feature-002 §4's
`<token> = artifact` rule; all four `artifact` values are non-empty, so the
confirmed-slug rule for artifact-less writers never applies here.

**1d. No template, no test edit.** This feature adds nothing to
`canonical/aid/templates/knowledge-base/`, so `AS06`'s find-count
(the `find` at `tests/canonical/test-kb-template-authoring-standard.sh:50`, the assertion
at `:56-57`) and every other seed-count assertion are untouched.
`ls canonical/aid/templates/knowledge-base/*.md | wc -l` is `14` before and after.

§8's `quality-gates.md` registration adds only `conditional` matrix rows. Three suites
read that file and none of them moves:

| Suite | Why a conditional row cannot move it |
|---|---|
| `test-domain-doc-matrix.sh` MT01/MT02 | They compare only the **required** sets (`:152-173`), extracting rows via `/\| required/`. `decisions.md`'s six existing conditional rows are the standing proof |
| `test-domain-doc-matrix.sh` MT07/MT08 | Spine coverage asserts each of the eleven dimensions is covered by ≥1 doc (`:227-252`). C6 is already covered in both domains by `test-landscape.md`; a second C6 doc cannot uncover it |
| `test-spine-depth-coverage.sh` SD04/SD05/SD07 | SD04/SD05 assert every non-meta matrix doc's spine dimension resolves to a present, non-empty depth block (`:152-193`) — C6's block exists and is non-empty, and the new rows carry `C6`. SD07 is a `>=58` sanity floor (`:205-211`), which added rows can only raise |

### 2. Why these four are one feature

Not "they share a destination" — three of the four own theirs. What binds them is that
**all four share one unresolved question and a set of content collisions**, and answering
any of them four times over risks four different answers:

1. **The question:** what a `create` skill does when its destination is a populated,
   as-built, `hand-authored` document. That is the state of all five documents in this
   repository today (`architecture.md` 515 lines, `technology-stack.md` 255,
   `test-landscape.md` 555, `infrastructure.md` 315, `quality-gates.md` 394; each
   `source: hand-authored` at line 3). §6 answers it once.
2. **The collisions:** CI/CD content spans the C6 and C8 destinations, test-framework
   content spans C0 and C6, build tooling spans C0 and C8, and gate enforcement spans the
   C6 gate doc and C8 (§4). Every one of the four has one of these skills on each side, so
   all four are settleable inside this feature. Split per artifact, none could be resolved
   without an integration-time negotiation between three separately-graded features.

### 3. Destination resolution — by concern, not by filename

**CC-6 is the contract; this section is its implementation for the four foundation
artifacts.** The KB's own domain matrix is the evidence CC-6 rests on: `test-landscape.md`
appears in exactly two of the eight curated domain sections — `software-cli`
(`domain-doc-matrix.md:142`) and `software-web` (`:171`). The `content` domain realizes C1
as `information-architecture.md` (`:220`), not `architecture.md`; `methodology-tooling`'s
C1 doc is `process-architecture.md` (`:316`).

`architecture.md` itself carries **three** matrix rows —
`software-cli` (`:134`, required), `software-web` (`:163`, required) and `data-ml`
(`:205`, conditional). So a skill that hardcodes the filename is unconditionally correct
in two of the eight domains, conditionally applicable in a third, and wrong or
inapplicable in the remaining five.

**3a. The resolution rule, applied at `design` and recorded in the seed.**

| Skill family | Binds concern | Resolves to |
|--------------|---------------|-------------|
| `/aid-*-architecture` | **C1** — build & shape (`concern-model.md:86`) | the project's C1 doc |
| `/aid-*-stack` | **C0** — technology (`concern-model.md:95`) | the project's C0 doc |
| `/aid-*-testing-strategy` | **C6** — quality & testing (`concern-model.md:91`) | the project's C6 doc(s) |
| `/aid-*-cicd` | **C8** — shipping & operation (`concern-model.md:93`) | the project's C8 doc |

The `design` skill resolves the concern against the project's declared doc-set
(`.aid/settings.yml` `knowledge.doc_set`, falling back to the domain matrix row) and
writes the resolved path into the seed's **`## Destination`** section — which
feature-002 §4 already makes a required section for class-1 seeds. `create` reads it and
writes there. The resolution is confirmed with the user at DESIGN, so a hybrid project
that realizes C6 with two documents (this repository does: `test-landscape.md` **and**
`quality-gates.md`) states both.

**A concern may hold more than one doc, and the extra one is not always a destination.**
C1's default set is `project-structure.md` **and** `architecture.md`
(`concern-model.md:86`). `/aid-*-architecture` resolves to the doc describing the
system's shape and **never writes `project-structure.md`**, which describes the repo
layout. Where a concern's realization is genuinely ambiguous, the `design` skill asks;
it never picks silently.

**3b. When the concern has no doc in the project's set — creation and its registration.**

`create` creates the document and, in the same run, performs the registration. Per **CC-2**
this is an effect of running the skill, not a separate hand edit by any feature; per
**CC-1** the presence value is `required`. **Two** surfaces are runtime writes into the
*project*:

| Where | Entry | Fixed by |
|-------|-------|----------|
| `.aid/settings.yml` `knowledge.doc_set` | `<file>\|<owner>\|required` | **CC-1** for the presence value; `doc-set-resolve.md:28-44` § Field grammar for the field shape |
| `.aid/knowledge/README.md` | One Completeness row (`Concern` = the doc's spine dimension, `Owner` = the same owner, `Status` = the table's authored token), and the `**Doc-set:** N documents` line at `:21` incremented | The table's own rule at `README.md:35` — *"One row per document in the confirmed doc-set"* |

Both follow the R13 append-block idiom `aid-config/SKILL.md:160` records — one entry
appended to the existing list, never a rewrite of the block, never a touch to
`term_exclusions`.

**One canonical edit follows from them, and it is a feature deliverable rather than a
runtime effect.** `canonical/skills/aid-config/SKILL.md:160` records `knowledge.doc_set` as
*"runtime-written by `aid-discover`"*. These `create` skills are a **second** runtime
producer of the same key, so that line must be amended to name them. The amendment is one
row and is **shared with feature-003 §6b**, which states the identical obligation for
`/aid-create-roadmap` and `/aid-create-backlog`; whichever feature lands first writes it
naming both, and the other verifies rather than repeats. Doing it twice would double-count,
which is the failure CC-2 exists to prevent.

**The owner field is not free, and it is not blanket `skill-self`.** `doc-set-resolve.md`
requires field 2 to be one of the five parameterized `aid-researcher` slots, or
`skill-self` *"for generated/meta docs"* (`:32-35`); `domain-doc-matrix.md:59` defines the
same field as *"the freshness-accountable role"* and calls it the same enum. So:

- Where the domain matrix already assigns the document a researcher slot, `create` writes
  **that slot**. On disk: `quality-gates.md` → `aid-researcher-quality` (`:321`),
  `decisions.md` → `aid-researcher-architecture` (`:146`, `:176`, `:229`, `:278`, `:301`,
  `:322`), `infrastructure.md` → `aid-researcher-quality` (`:144`, `:173`, `:203`, `:294`,
  `:325`). Writing `skill-self` for any of these would silently remove the researcher
  discovery dispatches for that doc and contradict every shipped row.
- `skill-self` is written only where **no** matrix row assigns a slot — the case
  feature-003 §6b covers for `roadmap.md` and `backlog.md`. No document in *this* feature
  falls in it.

**Why registration is not optional — stated accurately.** The earlier draft claimed an
unregistered KB file "routes to Extension-Scope". That is wrong: the review rubric routes
on the doc's own `kb-category:` + `source:` pair, not on doc-set membership
(`canonical/skills/aid-discover/references/reviewer-brief.md:22-28`), and §8b supplies the
live counter-example — `quality-gates.md` is `kb-category: extension` **and** a declared
member. The real consequence is narrower and checkable: the declared doc-set is what
`state-review.md` resolves `{{ARTIFACTS}}` from (`:118-120`, via
`read-setting.sh --path discovery.doc_set`), and what the ownership/presence machinery
reads. An unregistered document therefore has no owner, no `README.md` completeness row,
and is absent from the artifact list every later KB review is scoped to — while still
being swept into the M3/M4 keystone surface, which globs the directory
(`doc-set-resolve.md:296-301`). It is reviewed by one path and invisible to the other.

**One naming note, stated once.** The physical key in `.aid/settings.yml` is
`knowledge.doc_set` (`canonical/skills/aid-config/SKILL.md:160`); `doc-set-resolve.md`
documents the same block under the logical name `discovery.doc_set`. They are one block.

### 4. Region ownership — the content collisions, assigned

**How the collision set was derived, so the completeness claim is checkable.** The
derivation covers **five** destinations, not four: `quality-gates.md` is named as a
destination by §7e and by the Description table, and an earlier draft's "four destination
templates" scoping silently dropped it.

Two searches:

1. **A literal-duplicate heading scan.** Over all fourteen KB templates plus the live
   `quality-gates.md` (which has no template, §8):
   `grep -h '^## ' canonical/aid/templates/knowledge-base/*.md .aid/knowledge/quality-gates.md | sort | uniq -c | sort -rn`.
   The only repeats are `## Contents` (15), `## Invariants` (3), `## Conventions` (3) and
   `## Contracts` (3). Of those, only `## Invariants` touches a destination of this
   feature (`architecture.md`), and its two co-holders (`domain-glossary.md`,
   `module-map.md`) are outside the feature. Adding the fifth destination to this scan
   changes nothing but the `## Contents` count: **no two of the five destinations share a
   literal heading.**
2. **A pairwise topical read** of the five destinations' full `^## ` heading sets —
   **ten** pairs, all ten read. For `quality-gates.md` the heading set is the live doc's
   (`.aid/knowledge/quality-gates.md`), since no template exists. This pass is what
   surfaces every overlap below; the first pass alone would have found none of them.

**The pairs that came back clean, and why**, so the completeness claim is not an absence
of effort:

| Pair | Verdict |
|---|---|
| C1 ↔ C6 (test doc), C1 ↔ C8 | No shared topic — the C1 doc describes the system's shape, not how it is tested or shipped |
| C1 ↔ C0 | One *near*-collision that is not one: `architecture.md` `## Dependency Injection` (`:103`) is a wiring **pattern**, `technology-stack.md` `## Key Dependencies` (`:83`) is a package list. The words rhyme; the concerns do not |
| C1 ↔ gate doc | No shared topic — grade scale, ledger and gate loops touch nothing in a component/boundary description |
| C6 test doc ↔ gate doc | A real content boundary, but **not a two-skill contest**: `/aid-*-testing-strategy` owns both. §7e states the split line, taken from the project's own prose |
| C0 ↔ gate doc | `## Validation Commands` (`.aid/knowledge/quality-gates.md:375`) names tools, which the C0 doc also names. Not a new row — row 2's non-owner rule already forbids a version in **the C6 doc(s)**, plural, and that scoping covers the gate doc |

The one cross-concern topic `architecture.md` carries — `## Key Architectural Decisions`
(`:113`) — collides with concern **D**, not with any of the other four destinations, and
§7d settles it.

| # | Contested topic | Sections | Owner | Rule for the non-owner |
|---|-----------------|----------|-------|------------------------|
| 1 | CI/CD pipeline | `test-landscape.md` `## CI/CD Pipeline` (`:85`) vs `infrastructure.md` `## Deployment Pipeline` (`:97`; live form `## CI/CD Pipeline`, `.aid/knowledge/infrastructure.md:99`) | **`/aid-*-cicd`** owns the pipeline itself in the C8 doc: stages, triggers, environments, promotion, release flow | `/aid-*-testing-strategy` writes into the C6 test doc's CI section only the **test-lane mapping** — which suites run in which lane — and points at the C8 doc for the pipeline. It states no stage, trigger, environment or promotion rule |
| 2 | Test frameworks | `technology-stack.md` `## Test Frameworks` (`:95`) vs `test-landscape.md` `## Test Framework Inventory` (`:36`) | **`/aid-*-stack`** owns the framework **choice and version** in the C0 doc | `/aid-*-testing-strategy` writes what the frameworks are **used for** — levels, coverage expectations, gaps — and cites no version **in either C6 doc**. A version in a C6 doc is a duplicate that will drift |
| 3 | Build tooling | `technology-stack.md` `## Build System` (`:57`) vs `infrastructure.md` `## Deployment Pipeline` (`:97`; live `## The Build: Multi-Profile Render`, `.aid/knowledge/infrastructure.md:79`) | **`/aid-*-stack`** owns the build tool and its version; **`/aid-*-cicd`** owns the pipeline stage that invokes it | Neither restates the other's half |
| 4 | Gate enforcement | The gate doc's policy sections (`.aid/knowledge/quality-gates.md:231 ## The Delivery Gate`, `:338 ## Mechanical Gates Run by the Orchestrator`, `:375 ## Validation Commands`) vs the C8 doc's pipeline sections (`.aid/knowledge/infrastructure.md:99`, `:135 ## The Release Pipeline`, `:291 ## Release Commands`) | **`/aid-*-testing-strategy`** owns the **policy** — what blocks, the threshold, who may waive and how | `/aid-*-cicd` writes only the **stage**: its name, its order, its trigger, and that it runs the gate. It states no threshold, no blocking/advisory verdict and no waiver rule, and cites the gate doc instead |

Row 4 is the row the earlier four-destination derivation could not have found, because
both its sides live in documents that scoping excluded from the search.

**Why assignment rather than a byte-range region.** The `roadmap.md`/`## MVP` mechanic in
feature-002 §3c works because both skills write one literal heading in a document whose
shape feature-003 authors. These destinations already exist with project-specific
shapes — this repository's `test-landscape.md` realizes the template's `## CI/CD Pipeline`
as `## CI Lanes and Where They Run` (`.aid/knowledge/test-landscape.md:167`) — so a literal
heading match would silently miss the region on any real project. The ownership rule is
therefore stated over **topics**, resolved to headings at DESIGN time and recorded in the
seed's `## Destination` (§3a), and enforced at the **file** level, which is what AC-6's
`git diff --name-only` oracle measures.

**Write discipline (all twelve).** Read the whole destination, edit in place, write back
with everything outside the edited range byte-identical. Never regenerate or restructure
a document. This is the same guard `/aid-update-kb` places on its own KB writes —
*"a targeted in-place edit … it does not regenerate, restructure, or rewrite the doc
wholesale, even if it judges the doc could be improved elsewhere"*
(`canonical/skills/aid-update-kb/references/state-apply.md:252-258`) — and these skills
bind it rather than inventing a second discipline. Adding a `## ` section obliges updating
the document's `## Contents` list in the same write (AC-11).

### 5. The four `design` skills

Each follows feature-002 §3e's on-demand shape: Work Initiation Gate →
`worktree-lifecycle.sh create` on new work → allocate `pipeline.path: lite`,
`initiator: aid-design-<artifact>`, **`phase` not driven** → dispatch `aid-architect`
tiered → full verify → present → done.

Reads the existing seed if present, plus the KB and the project source. Writes **only**
`.aid/design/<artifact>.md`. Never writes `.aid/knowledge/`; never writes production
config (a `cicd` design does **not** edit a workflow file). Resolves the destination per
§3a and records it in the seed's `## Destination`.

| Skill | Draws out | Records the destination as |
|-------|-----------|----------------------------|
| `aid-design-architecture` | Components, boundaries, interactions, invariants; what is deliberately *not* a component | the project's C1 doc |
| `aid-design-stack` | Languages, runtimes, frameworks and build/test tooling **with versions**; and the rejected alternatives | the C0 doc, plus the D doc for the rejected alternatives (§7d) |
| `aid-design-testing-strategy` | Test levels, coverage expectations, which gates block a merge, who may waive one | the C6 doc(s) — the test-landscape half and the gate-policy half named separately |
| `aid-design-cicd` | Pipeline stages, triggers, environments, promotion and release flow | the C8 doc |

### 6. The four `create` skills — gates, and the realization event

**6a. The rule this replaces, and why.** The previous draft refused any `create` whose
destination held real content. Applied to this feature that rule never fires *correctly*:
all four destinations are populated on every project that has run `/aid-discover`, so
`create` would refuse every time, the seed would never be consumed, and REQUIREMENTS
AC-6b — *"A `create` skill that cannot fire on a populated destination fails this
criterion"* — would fail by construction.

REQUIREMENTS FR-1 settles it: *"A populated destination is the NORMAL case, not a refusal
condition"*; the destination document existing or being populated **never** blocks
`create`; refusal is scoped to the skill's own owned region already carrying committed
content, and the response is to route to `update`, never to halt with nothing done.

**6b. How feature-002 §3c's first-write rule resolves here — stated, not omitted.**
feature-002 §6 lists this feature as consuming its §3g, and §3g's class-1 rows bind both
*"§3c region ownership + write discipline"* and *"§3c first-write rule"*. §3c therefore
binds these twelve skills, and each of its four situations has a resolution here:

| feature-002 §3c situation | Resolution for these four artifacts |
|---|---|
| Destination absent, skill owns the **whole** document | `create` creates it — §6e. All four own their whole destination |
| Destination absent, skill owns only a **region** | **No instance in this feature.** CC-5's only instance is `/aid-create-mvp`, which is feature-003's |
| Destination present and populated, owned region absent | `create` adds the region — the dominant path here, and the one AC-3 exercises |
| Owned region present carrying **committed** content | `create` routes to `/aid-update-<A>` for that content — §6c's repeat-`create` case |

**What "committed content" means here, and why it cannot mean "any content".** For these
four the owned region *is* the whole document, so reading row 4 as "the document has
content" would refuse on every brownfield project — precisely the outcome REQUIREMENTS
AC-6b forbids by name, and the outcome §6a exists to remove. Under FR-1 the content that
triggers row 4 is content **this lifecycle previously committed** — written by an earlier
`create` for this same artifact — not the as-built content `/aid-discover` wrote. The test
is applied at the granularity of the sections the seed's `## Destination` names, which is
what makes it decidable: a seed proposing a section this skill has not written before is
realized; a seed proposing to rewrite one it did is routed.

**6c. The gate set, and the one case where the region refusal really does bite.**

| Condition | `create` behavior |
|-----------|-------------------|
| No seed at `.aid/design/<artifact>.md` | **Refuses**; names `/aid-design-<artifact>`; writes nothing |
| Seed present, `## Open questions` non-empty by feature-002 §4's detection rule, no explicit override | **Refuses**; the seed is left intact |
| Destination `source: generated` (§7a) | **Refuses**; a registered build script owns the content |
| Otherwise — **including a fully populated as-built destination** | **Realizes**: merges the settled content into the destination per §7, offers any additional user-requested output, then deletes the seed |

Exactly three refusal conditions, and none of them reads the destination's size, emptiness
or `hand-authored` status. AC-4's three-refusal-condition oracle (V27) is what keeps a
fourth from appearing.

**The repeat `create`.** A second seed for the same artifact whose `## Destination` targets
content this same skill already committed. FR-1's response applies literally and is not a
halt: `create` writes every part of the seed that is new; for the parts that would
overwrite content it previously committed, it names them and routes the user to
`/aid-update-<artifact>`; and it deletes the seed only when it wrote everything the seed's
`## Destination` named, otherwise leaving the seed in place carrying just the unrealized
parts. **That surviving seed has a consumer: `update` reads and consumes it (CC-3)**, so
it is realized on the next run rather than accumulating. Nothing is silently lost and
nothing is silently overwritten. V26 is the oracle; V5's first-run path is unaffected,
because a first run has nothing to overwrite.

**6d. What still distinguishes `create` from `update`.** Under CC-3 both verbs consume a
seed when they read one, so *consumption* is no longer the discriminator. The
discriminator is what each verb **requires**, and it is observable in both directions:

| | `create` | `update` |
|---|---|---|
| Requires a seed | **Yes** — refuses without one (§6c row 1) | **No** — the user's stated change is a sufficient input |
| Reads a seed | Always; it is the mandatory input | **When one is present** (CC-3) |
| Consumes the seed | Yes, by deleting it | Yes, whenever it read one (CC-3) |
| Source of the change | The seed's settled `## Current direction` | The user's stated change in that run — or a seed routed to it by §6c |
| Asks FR-8's derived-outputs question | Offers additional output for this run | **Asks every run**, no stored answer |

AC-5 is the oracle in both directions: an `update` that refuses without a seed fails (a),
and one that ignores a present seed fails (b).

**6e. Creating a destination that is absent.** Possible for `/aid-create-testing-strategy`
(`quality-gates.md`, §8) and for `/aid-create-cicd` on a `methodology-tooling` project,
where `infrastructure.md` is `conditional:the tooling ships/runs as a deployed artifact`
(`domain-doc-matrix.md:325`). In that case `create` creates the document, sets
`source: forward-authored` and `sources: []` (§7a), and registers it per §3b — presence
`required` (CC-1), owner from the matrix row, both project-side writes in the same run
(CC-2).

### 7. Per-artifact content rules for the eight `create`/`update` skills

The `create` and `update` skills for one artifact share a destination, a region and a
content rule; they differ only as §6d states. So the rules below bind both members of
each pair. `update` additionally binds §4's targeted-edit guard, FR-8's asking obligation,
and §7a's frontmatter invariants. When `update` runs with no seed to read the resolved
destination from, it applies §3a's concern rule itself at INTAKE and confirms the
resolution with the user before writing.

**Read the "Must not write" rows as concern boundaries, not region splits.** They name
content that belongs to a *different concern's document*, which is the KB's own
document-boundary rule (`concern-model.md:202`, § Document boundaries: *"Mixing concerns
is a boundary smell"*). Only §4's four rows are contests between two skills over the
same document, and those are settled there.

**7a. Frontmatter invariants — the same three rules for all eight.**

`frontmatter-schema.md:120-124` defines three production modes:

| Value | Consequence |
|-------|-------------|
| `hand-authored` | Full content review; the doc describes as-built reality |
| `forward-authored` | Full content review; the doc is **design-authoritative** — freshness treats it as never-stale-from-source, and code→design divergence is *flagged* by `/aid-housekeep`'s Conformance Lane rather than overwriting the doc |
| `generated` | Content not graded; `generator:` required |

| Situation | `source:` after the run |
|-----------|------------------------|
| The skill created the document itself (§6e) | `forward-authored` — authored from intent, no code to describe. `sources: []`, because listing code files as sources for a forward-authored doc is forbidden (`state-describe-seed.md:183-184`) |
| The document already existed | **Unchanged**, whatever it was. Neither verb rewrites it |
| `source: generated` | Both verbs **refuse** and write nothing |

Two further invariants, both binding all eight:

- **`approved_at_commit:` is never written or restamped.** It is generator-written by
  `/aid-discover` and `/aid-update-kb` on approval and never hand-authored
  (`frontmatter-schema.md:98`); `/aid-update-kb` repeats the invariant verbatim to its own
  sub-agents (`state-apply.md:262`). These twelve skills are neither of those, so they
  leave it alone. AC-10's `git diff` is the oracle.
- **`sources:` gains only what the run actually used.** If the promoted content describes
  intent rather than a file, no path is added.

**Why merging intent into a `hand-authored` document is admissible.** The KB describes
what **is**, and the readiness gate means only a *settled* decision reaches `create` —
which REQUIREMENTS §5.3 establishes as a present fact ("we have decided to do X" is true
now). The content rule that keeps it honest: in a `hand-authored` document, a decision not
yet realized in code is written **as a decision**, with its unrealized status stated in the
same passage. An unqualified future statement in a doc whose `source:` says it describes
as-built reality is a defect the review rubric will catch.

**7b. `/aid-create-architecture` · `/aid-update-architecture` — concern C1.**

| | |
|---|---|
| Destination | The project's C1 doc; default `architecture.md` (template headings `## Pattern`, `## Layers`, `## Module Boundaries`, `## Data Flow`, `## Dependency Injection`, `## Key Architectural Decisions`, `## Known Architectural Issues`, `## Invariants`) |
| Owned region | The whole document — no other skill in this feature writes the C1 doc |
| Writes | Components and their responsibilities; boundaries and what crosses them; interactions and data flow; invariants a change must not break; what is deliberately *not* a component |
| Into | The document's existing sections wherever one fits; a new `## ` section only when the seed's content maps to none, added with its `## Contents` entry (AC-11) |
| Must not write | Framework or runtime **versions** (C0, §4 row 2) · pipeline stages or environments (C8, §4 row 1) · **rejected alternatives** (concern D, §7d) |

Inline justification of a structure that *is* described belongs in the C1 doc's own
decision section (`architecture.md:113 ## Key Architectural Decisions`). A choice **not**
taken is concern D and leaves the document — see §7d.

**7c. `/aid-create-stack` · `/aid-update-stack` — concern C0.**

| | |
|---|---|
| Destination | The project's C0 doc; default `technology-stack.md` (`## Runtime`, `## Frameworks`, `## Build System`, `## Key Dependencies`, `## Test Frameworks`, `## Version Concerns`) |
| Owned region | The whole document — no other skill in this feature writes the C0 doc. **Among these twelve skills** it is also the only writer of framework/tool **versions** (§4 rows 2 and 3) |
| Writes | Languages, runtimes, frameworks, package managers, build and test tooling — each **with its version** — and version constraints or floors |
| Must not write | Rejected alternatives: `technology-stack.md` has **no** section for them — its full `^## ` set is Contents (`:24`), Runtime (`:35`), Frameworks (`:46`), Build System (`:57`), Key Dependencies (`:83`), Test Frameworks (`:95`), Version Concerns (`:105`) — and inventing one would put concern-D content in a C0 doc. They go to the D doc (§7d) · architecture structure (C1) · CI runner configuration (C8) |

The version-ownership claim is scoped to these twelve deliberately. It is **not** a claim
about who may write versions in the KB at large: REQUIREMENTS FR-1 names four other
legitimate KB writers (`/aid-discover` GENERATE, `/aid-describe`, `/aid-housekeep`
KB-DELTA, `/aid-graph`), and both `technology-stack.md` and `test-landscape.md` are
`source: hand-authored` docs populated by discovery. feature-002 §3c withdrew the
same class of exclusivity claim for the same reason.

**7d. Where rationale and rejected alternatives go.** `concern-model.md:96` assigns
*"what was decided, why, and what was rejected"* to **D**, realized by `decisions.md`, and
`state-describe-seed.md:190-197` gives that document's per-decision entry schema — whose
`:197` is a literal `**Rejected alternative:**` field. So:

| Content | Destination |
|---------|-------------|
| The settled standard itself | The artifact's C0/C1/C6/C8 doc (§7b, §7c, §7e, §7f) |
| Justification of a structure that the C1 doc describes | The C1 doc's own decision section, where the template provides one |
| **A choice not taken, and why not** | The project's **D** doc; `decisions.md` by default |

`decisions.md` is a conditional doc (`concern-model.md:106-113`), so where it is absent
`create` creates and registers it by §3b's rule — presence `required` (CC-1), owner
`aid-researcher-architecture`, which is the value every shipped matrix row for it carries
(`domain-doc-matrix.md:146`, `:176`, `:229`, `:278`, `:301`, `:322`) and which
`concern-model.md:113` states as its declaration form. In this repository it is already
present and declared `required` (`.aid/settings.yml:58`; `domain-doc-matrix.md:322`), so
nothing is created here.

The seed's `## Options considered` section is where these live before `create`; that they
have a destination at all is why §5's `aid-design-stack` row names two. When that section
holds no rejected alternative, the run touches no D doc — which is why AC-6 makes the D
doc's appearance in the diff conditional rather than expected.

**7e. `/aid-create-testing-strategy` · `/aid-update-testing-strategy` — concern C6, two
documents.**

| | |
|---|---|
| Destinations | The project's C6 doc(s): `test-landscape.md` (default seed member) **and** `quality-gates.md` (conditional, §8) |
| Owned region in the C6 test doc | The whole document, with its CI section restricted to the test-lane mapping (§4 row 1) |
| Owned region in the gate doc | The whole document |
| Writes to the test doc | Test levels and what each is for; coverage expectations; which suites run in which CI lane; known gaps |
| Writes to the gate doc | Gate policy: what blocks a merge, the thresholds, who may waive and how (§4 row 4) |
| Must not write | Pipeline stages, triggers, environments or promotion rules (C8, §4 row 1) · framework versions, **in either C6 document** (C0, §4 row 2) |

The split between the two documents is the one this repository already draws in prose:
`quality-gates.md`'s own `summary:` frontmatter says it is *"distinct from the automated
test suites in test-landscape.md"* (`.aid/knowledge/quality-gates.md:5`). The skill
follows the project's existing line rather than imposing a new one — which is also why §4
treats the C6-test ↔ gate-doc boundary as a content split under one owner, not as a
contest between two skills.

**7f. `/aid-create-cicd` · `/aid-update-cicd` — concern C8.**

| | |
|---|---|
| Destination | The project's C8 doc; default `infrastructure.md` (`## Hosting`, `## Environments`, `## Compute`, `## Data Infrastructure`, `## Networking`, `## Deployment Pipeline`, `## Monitoring & Observability`, `## Disaster Recovery`, `## Known Infrastructure Issues`) |
| Owned region | The pipeline sections — `## Deployment Pipeline` / `## CI/CD Pipeline` and `## Environments` — plus whatever else the seed's `## Destination` names within the C8 doc |
| Writes | Stages and their order; triggers; environments and promotion between them; the release flow; **that** a stage runs a gate |
| Must not write | Which test suites run (C6, §4 row 1) · what blocks a merge, any threshold, or any waiver rule (C6 gate doc, §4 row 4) · build-tool versions (C0, §4 row 3) |
| Production config | `design` never touches `.github/` or any workflow file. `create` writes the KB record by default; it may additionally emit a workflow file **only** when the user asks for it in that run (FR-1's "any other output the user wants"), and its description routes a user who wants a provisioned resource to `/aid-create-infra` (§10) |

### 8. `quality-gates.md` — conditional, created on demand (Q4/Q5 resolved)

REQUIREMENTS §5.3 gives `testing-strategy` two destinations. Verified on disk:
`test-landscape.md` is one of the fourteen canonical templates; **`quality-gates.md` is
not** — there is no `canonical/aid/templates/knowledge-base/quality-gates.md`, and a grep
of `canonical/skills/aid-discover/references/doc-set-resolve.md` for `quality-gates`
returns zero. Left unresolved, `/aid-create-testing-strategy` would write a document a
fresh adopter does not have and that `resolve_doc_set` never sees.

**Resolution (FR-9):** `quality-gates.md` is a **conditional** document, created on
demand by `/aid-create-testing-strategy` — the `decisions.md` treatment. The canonical
seed does not move: no template is added, so `AS06` and every seed-count assertion are
untouched (§1d, AC-15).

**8a. The registration surfaces are CC-4's four.** feature-001 §1b defines them once; this
feature substitutes no different set and adds no fifth. Two of the four are already
occupied for `quality-gates.md` on disk, which the earlier draft never stated, so the
work here is smaller than "four surfaces" suggests:

Paths are given once here; AC-7 and V12 cite this table rather than repeating it.

| # (CC-4) | Surface | State today | This feature's entry, and the oracle for it |
|---|---------|-------------|----------------------|
| 1 | `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` | One row: `methodology-tooling`, C6, `aid-researcher-quality`, `required` (`:321`) | Add a `conditional:<when>` row in each domain section whose C6 doc is `test-landscape.md` — `software-cli` and `software-web`, whose C6 rows sit at `:142` and `:171` (those two lines are the `test-landscape.md` rows themselves; the new rows' line numbers are not knowable before the edit) — in the manner of `decisions.md`'s rows. **Not** added to `methodology-tooling`, which already carries it as required, nor to the five domains that realize C6 differently. Owner `aid-researcher-quality`, matching `:321`; the `<when>` hint carries no comma (`doc-set-resolve.md:46-54`). *Oracle:* `grep -n 'quality-gates.md'` returns `:321` plus exactly two new rows, one inside each of those two domain tables |
| 2 | `canonical/aid/templates/kb-authoring/concern-model.md` | **Absent** — `grep -c 'quality-gates' concern-model.md` → `0` | List it with the other conditional docs alongside `decisions.md`, carrying concern **C6**. *Oracle:* the same grep returns ≥1, and the hit names C6 |
| 3 | `canonical/skills/aid-discover/references/document-expectations.md` | **Already occupied** — `### quality-gates.md` at `:632` | No edit; the block stays. *Oracle:* `grep -c '^### quality-gates.md'` → `1` |
| 4 | `_dim_of_filename`, both twins | **Already occupied** — `canonical/aid/scripts/kb/kb-actback-task.sh:216` and `canonical/aid/scripts/kb/kb-dual-intent-probes.sh:237` both list it in the C6 arm | No edit; both entries stay. *Oracle:* `grep -c 'quality-gates.md'` → ≥1 in **each** twin |

**The concern id is C6**, matching this repository's live tags
(`.aid/knowledge/quality-gates.md:15`, `tags: [C6, quality-gates, review, grading, ledger, gates]`)
and the matrix's methodology row. It is asserted on surfaces 1 and 2 by grep; `AS07`
cannot assert it, because that loop runs over `TEMPLATES` built by a `find` over
`canonical/aid/templates/knowledge-base/` (`test-kb-template-authoring-standard.sh:50`,
`:117-131`) and `quality-gates.md` has no template there.

**CC-1's doc-set entry is not a fifth surface.** It is a runtime write by the `create`
skill (CC-2), specified once in §3b and not repeated here.

**Two C6 docs in one project is a deliberate split, not a boundary violation.** The
hybrid composition rule permits it explicitly: when two domain rows realize the same
dimension, discovery proposes *"a deliberate split under the dimension (the three-force
boundary rule)"* and the user confirms at the gate (`domain-doc-matrix.md:366-368`). This
repository is that case, and the split line is the one §7e cites.

**8b. Why this repository needs no dogfood migration.** `.aid/settings.yml:53` already
declares `quality-gates.md|aid-researcher-quality|required`, which is exactly what §3b
would write: the presence value is `required` per **CC-1**, and the owner is the matrix
row's `aid-researcher-quality` (`domain-doc-matrix.md:321`). It is also what the hybrid
composition rule produces independently — AID composes `software-cli` with
`methodology-tooling`, and step 4 says *"If the same dimension is `required` in one row
and `conditional` in another, the composed result is `required` (the stronger
commitment)"* (`domain-doc-matrix.md:369-370`). So this feature edits neither
`.aid/settings.yml` nor `.aid/knowledge/quality-gates.md`.

**One pre-existing inconsistency, named and routed out.** That live doc carries
`kb-category: extension` (`:2`), while `frontmatter-schema.md:110` defines `extension` as
*"outside the project's declared doc-set"* — and it **is** in the declared doc-set at
`.aid/settings.yml:53`. That mismatch predates this work and is not caused by it; it is a
KB-hygiene item for `/aid-housekeep`, recorded here so a reviewer does not read its
absence as an oversight. It is also the live proof that `kb-category:` and doc-set
membership are independent fields, which is the correction §3b makes to the earlier
draft's Extension-Scope claim.

**8c. What an adopter gets.** A project that never runs `/aid-create-testing-strategy` has
no `quality-gates.md`, no doc-set entry, and no gate reporting it missing — correct, since
gate policy is not universal. A project that runs it gets the document **and** the
registration in the same run (§3b).

### 9. Conformance Lane interaction

`/aid-housekeep`'s KB-DELTA routes `source: forward-authored` docs to the Conformance
Lane, which checks code→design and **flags** divergence for human reconciliation instead
of overwriting the design
(`canonical/skills/aid-housekeep/references/state-kb-delta.md:183-196`).

Which of these destinations enter the lane is settled by §7a, not by which skill ran: a
document keeps whatever `source:` it had, and only a document these skills **create** is
set `forward-authored`. Two obligations follow, and AC-12 is the oracle for both:

1. A `create` skill that creates a document is opting it into the lane permanently. That
   is intended, and its `description:` must say so **using the literal phrase
   `Conformance Lane`**, because the user is choosing it. The literal phrase is fixed here
   so AC-12(a) has something to grep for; without it the obligation is unrunnable.
2. No skill here resolves a flagged divergence on its own. Reconciliation is human by the
   lane's design; an `update` that silently "fixes" a divergence defeats it. `update`
   changes only what the user named in that run.

### 10. Negative routing (NFR-4, AC-8)

Per **CC-9**, each pair's routing is written by the feature shipping the newer side, and
the pair set is verified whole only in the close-out feature. Feature-005 §6c hands this
feature two of AC-8's pairs by name (`/aid-create-architecture` ↔
`/aid-update-architecture` ↔ `/aid-document-architecture`, and `/aid-create-cicd` ↔
`/aid-create-infra`) and one side of a third (`/aid-design-test` ↔
`/aid-design-testing-strategy`).

The full set for the twelve — every neighbour verified as a live catalog row:

| Skill | Names as negative route | Because |
|-------|-------------------------|---------|
| `aid-design-architecture` | `/aid-create-architecture` · bare `/aid-design` · `/aid-document-architecture` | Develop the idea here; build it there. Bare `/aid-design` is the catch-all once feature-005 §6a narrows it (`canonical/skills/aid-design/SKILL.md:5` still advertises *"an architecture sketch"*). `/aid-document-architecture` (`shortcut-catalog.yml:499-506`) documents components/boundaries/interactions — near-identical words, opposite side of the KB write boundary |
| `aid-create-architecture` · `aid-update-architecture` | each other · `/aid-document-architecture` | `create` needs a seed, `update` does not (§6d); and that third one produces a user-facing document and never writes `.aid/knowledge/` |
| `aid-design-stack` | `/aid-create-stack` · `/aid-design-config` (feature-005) · `/aid-research` | Develop vs realize; choosing a stack vs configuring one; a decision to make vs a question with an answer |
| `aid-create-stack` · `aid-update-stack` | each other · `/aid-create-config` · `/aid-update-config` | Those change config files; these write the KB record of the choice |
| `aid-design-testing-strategy` | `/aid-create-testing-strategy` · `/aid-design-test` (feature-005) · `/aid-test` | Develop vs realize; designing a test vs designing the policy; and `/aid-test` runs suites (`:378-385`) |
| `aid-create-testing-strategy` · `aid-update-testing-strategy` | each other · `/aid-create-test` · `/aid-update-test` | Those author test code (`:364-377`); these write the strategy and the gate policy |
| `aid-design-cicd` | `/aid-create-cicd` · `/aid-design-infra` (feature-005) · `/aid-design-data-pipeline` (feature-005) · `/aid-deploy` | Develop vs realize; designing the delivery pipeline vs designing a resource vs designing a **data** pipeline; `/aid-deploy` ships an artifact (`:617-624`) |
| `aid-create-cicd` · `aid-update-cicd` | each other · `/aid-create-infra` · `/aid-update-infra` · `/aid-create-data-pipeline` · `/aid-update-data-pipeline` · `/aid-deploy` | Those provision or change a resource (`:225-231`, `:314-320`) or build a **data** pipeline (`:190-196`, `:279-285`); this writes the KB's C8 delivery-pipeline record |

**How the set was checked for completeness — the search, stated so it can be re-run.**
Every catalog row's `name` and `intent` was read against a token set widened from the
earlier draft's four to include the defining noun of this feature's own `cicd` artifact:
`architecture`, `stack`, `test`/`testing-strategy`, `cicd`, `ci`, `infra`, `deploy`,
**`pipeline`**, `gate`, `quality`, `build`, `release`, `monitor`. Command form:

```
grep -nE '^  - name:|^    intent:' canonical/aid/templates/shortcut-catalog.yml \
  | grep -iE 'architect|stack|test|cicd| ci |infra|deploy|pipeline|gate|quality|build|release|monitor'
```

The rows above are the hits that survive judgment. Five hits were considered and
**rejected**, with the reason, so the claim is a decision rather than an omission:
`aid-create-data-pipeline` / `aid-update-data-pipeline` (`:190-196`, `:279-285`) were the
one genuine miss the widened token set found and are **added** above; `aid-test-security`,
`aid-test-performance` and `aid-test-data-quality` (`:386-409`) all delegate to
`aid-test`, which is already routed, so routing them individually would triple the clause
without adding a distinction; `aid-remove` (`:334-340`) shares only the word "dependency";
`aid-experiment` (`:410-416`) shares only the word "test" in "A/B test"; `aid-monitor`
(`:625-632`) observes a live asset and writes no KB record, and the C8 doc's
`## Monitoring & Observability` section is outside every owned region in §7f.

The pair set is only verifiable **whole** in feature-006 §8a, because half of each
cross-feature pair does not exist until feature-005 lands (feature-005 §6c) — which is
CC-9's rule, not a local exception.

### 11. Verification

| # | Check | Oracle | Closes |
|---|-------|--------|--------|
| V1 | Twelve directories | `ls -d canonical/skills/aid-{design,create,update}-{architecture,stack,testing-strategy,cicd}` → 12 lines, exit 0 | AC-1 |
| V2 | Twelve complete rows | `grep -cE '^  - name: aid-(design\|create\|update)-(architecture\|stack\|testing-strategy\|cicd)$' canonical/aid/templates/shortcut-catalog.yml` → `12`; then the full `run_generator.py` completes — its catalog parse raises `CatalogError` on a missing required field or an out-of-enum `default_type` (`build-shortcut-skills.py:55`, `:219-224`), so a malformed row cannot render | AC-1 |
| V3 | Hand-authored, not generated — **the only oracle for `repurpose`** | Each row `repurpose: true`; re-running `build-shortcut-skills.py` leaves all twelve `SKILL.md` files byte-identical (`git diff --exit-code canonical/skills/aid-*-{architecture,stack,testing-strategy,cicd}/`). A row that lost the key parses fine and is silently regenerated (`build-shortcut-skills.py:354`), which only this diff catches | AC-1 |
| V4 | `design` never touches the KB or CI config | Run each `design` skill; `git status --porcelain .aid/knowledge/ .github/` empty | AC-2 |
| V5 | **Brownfield realization** | On this repo as it stands: `/aid-design-architecture` → `/aid-create-architecture`; then `test ! -f .aid/design/architecture.md` **and** `git diff --stat .aid/knowledge/architecture.md` non-empty. Repeat for the other three. This is also AC-4's sub-run (c) | AC-3, AC-4 |
| V6 | Seed-absent refusal | Remove the seed, run `create`: refuses, names the `design` skill, `git status --porcelain .aid/knowledge/` clean | AC-4 |
| V7 | Readiness gate | Seed with non-empty `## Open questions` (feature-002 §4 detection rule), no override → refuses; seed still present | AC-4 |
| V8 | **`update` needs no seed, and consumes one when present** | (a) seed absent → `update` completes, destination diff non-empty, no refusal; (b) seed present → after the run the seed file is gone and the destination diff carries its `## Current direction` content | AC-5 |
| V9 | **Region assignment holds at runtime** | `git diff --name-only .aid/knowledge/` after `/aid-create-cicd` → C8 doc, no C6 doc; after `/aid-create-testing-strategy` → `test-landscape.md` + `quality-gates.md`, no C8 doc; after `/aid-create-stack` → C0 doc, plus the D doc only when the seed carried a rejected alternative, and never a C1/C6/C8 doc | AC-6 |
| V10 | No version duplication | Run `/aid-create-stack` and `/aid-create-testing-strategy` on a project whose seeds both name a test framework and its version; the version string appears in the C0 doc, and **neither** C6 doc's diff contains a version string | AC-6 |
| V11 | Gate policy stays out of the C8 doc | Run `/aid-create-cicd` with a seed naming a blocking gate: the C8 diff names the stage and cites the gate doc, and `grep -niE 'threshold\|blocks the merge\|waive' <C8 diff>` → nothing (§4 row 4) | AC-6 |
| V12 | `quality-gates.md` registered on CC-4's four surfaces | The four per-surface oracles in **§8a's table**, all satisfied — including the two "no edit" surfaces, which must still return their hits; plus the concern-id greps of AC-7; plus `bash tests/canonical/test-domain-doc-matrix.sh` green **and** `git diff master -- tests/canonical/test-domain-doc-matrix.sh` empty | AC-7 |
| V13 | Seed count unmoved | `git diff master --` empty on `tests/canonical/test-kb-template-authoring-standard.sh` (AS06), `test-doc-set-read.sh`, `test-doc-set-mapping.sh`, `test-domain-doc-matrix.sh`, `test-spine-depth-coverage.sh`, and `canonical/skills/aid-discover/references/doc-set-resolve.md`; all five suites green unmodified. `ls canonical/aid/templates/knowledge-base/*.md \| wc -l` → `14`. `git diff master` is required here: `--exit-code` compares the working tree to `HEAD` and passes once an edit is committed | AC-15 |
| V14 | Creation registers, in the same run | On a project without the C8 doc, `/aid-create-cicd` creates it **and** `git diff .aid/settings.yml` shows exactly one added line matching `<file>\|aid-researcher-quality\|required`, `git diff .aid/knowledge/README.md` shows exactly one added Completeness row and a `+1` on the `**Doc-set:** N documents` line at `:21`. No hand edit outside the run does any of it (CC-2) | AC-16 |
| V15 | Negative routing, twelve sides | For each row of §10, every assigned neighbour name appears literally in that skill's `description:`, and no description names an unassigned neighbour | AC-8 |
| V16 | FR-8 asking, no tracking metadata | AC-9's four parts: (a) the prompt is an unconditional step in each `update` `SKILL.md`; (b) run 2 asks again; (c) `grep -rniE 'derived[-_]outputs\|output_list\|outputs:' .aid/settings.yml .aid/works/<work>/STATE.md` → nothing; (d) `grep -rniE 'derived-from\|source-doc\|generated-by\|aid-tracked'` over written files → nothing | AC-9 |
| V17 | `source:` preserved | For each of `hand-authored` and `forward-authored`: run `create` then `update`; `git diff` shows no change to the `source:` line | AC-10 |
| V18 | `source: generated` refused | Set `source: generated`, run `create` and `update`; both refuse, `git diff --exit-code` on the doc clean (a working-tree check on an unrun edit — valid here) | AC-10 |
| V19 | `approved_at_commit:` untouched | `git diff` on the destination shows no change to that line; `bash canonical/aid/scripts/kb/lint-frontmatter.sh` green | AC-10 |
| V20 | Created doc is `forward-authored` with empty `sources:` | Absent destination → `create` → `source: forward-authored`, `sources: []` | AC-10 |
| V21 | `## Contents` consistent | AC-11's `comm -3` command returns empty after every `create`/`update`. Not AS02, which is an existence check and template-scoped | AC-11 |
| V22 | Lane disclosure is greppable | `grep -c 'Conformance Lane' canonical/skills/aid-create-<A>/SKILL.md` ≥ 1 for all four, hit inside the `description:` block | AC-12 |
| V23 | Lane divergence survives | A flagged divergence the user did not point at survives an `update` and a `/aid-housekeep` re-run | AC-12 |
| V24 | Naming distinct | `grep -c 'artifact: test-strategy' canonical/aid/templates/shortcut-catalog.yml` → `0`; `aid-create-test` and `aid-create-testing-strategy` are distinct directories | AC-13 |
| V25 | `phase:` untouched | `git diff master -- canonical/aid/templates/work-state-template.md` empty, **and** `grep -c '^phase: .' .aid/works/<work>/STATE.md` → `0` after each of the twelve runs | AC-14 |
| V26 | Repeat `create` routes, does not overwrite or halt | Run `create` twice; the second seed targets one section already committed by the first plus one new one. The new section is written, the committed one is byte-identical, the run names `/aid-update-<A>` for it, and the seed survives carrying only the unrealized part — which `update` then consumes (CC-3) | AC-4 |
| V27 | No fourth `create` gate | Over each of the four `create` `SKILL.md` files: the CREATE state enumerates exactly three refusal conditions, and `grep -niE 'empty\|populated\|non-empty\|hand-authored\|line count'` over that state's text returns nothing | AC-4 |

**Ten of the twenty-seven rows would catch a real regression** — V5 (the seed reaches a
consumer on the dominant path), V8 (CC-3's two directions), V9, V10 and V11 (the content
collisions stay assigned), V16 (FR-8 has no stored state), V17 and V18 (the `source:`
contract), V26 and V27 (the region rule routes rather than overwrites, and no fourth gate
re-enters). The other seventeen are presence assertions and are labelled as such rather
than presented as equals.

**Coverage, stated as the property that actually holds.** Every acceptance criterion is
closed by at least one row, and every row names the criterion or criteria it closes. It is
not a bijection: V5 closes AC-3 and AC-4's sub-run (c), and AC-4, AC-6, AC-10 and AC-12
each take several rows. The earlier draft's bijection claim was false — two rows served no
criterion at all — and is replaced rather than restated.

| AC | Rows |
|----|------|
| AC-1 | V1, V2, V3 |
| AC-2 | V4 |
| AC-3 | V5 |
| AC-4 | V5, V6, V7, V26, V27 |
| AC-5 | V8 |
| AC-6 | V9, V10, V11 |
| AC-7 | V12 |
| AC-8 | V15 |
| AC-9 | V16 |
| AC-10 | V17, V18, V19, V20 |
| AC-11 | V21 |
| AC-12 | V22, V23 |
| AC-13 | V24 |
| AC-14 | V25 |
| AC-15 | V13 |
| AC-16 | V14 |

### 12. Dependencies and sequencing

- **Depends on feature-002** — binds §3a and §3b (class 1), §3c (region ownership, write
  discipline **and** the first-write rule — see §6b, which states how each of its four
  situations resolves when the owned region is the whole document), §3d (FR-8), §3e (skill
  shape and the `description` contract), §3f (row shape), §3g (the binding table), and §4
  (the seed template, its literal headings, the required `## Destination` section that
  **this spec's** §3a writes into, and the Open-questions detection rule).

  feature-002 §6's consumer table lists this feature's set as *"§3a (both stage tables),
  §3d, §3e, §3f, §3g, §4"*. §3c is not named there, but §3g's class-1 rows bind it, so it
  binds here transitively; **this spec's** §6b discharges it rather than treating the
  omission as an exemption. What this feature does **not** import is §3c's *byte-range
  region mechanic*, which is written for one literal heading (`## MVP`) in a document
  feature-003 authors; these destinations arrive with project-specific shapes, so §4
  states ownership over topics and enforces it at file granularity instead. That is a
  narrower exclusion than "does not consume §3c", and it is the accurate one.
- **Depends on feature-001 — for membership and doctrine, and it is blocking.** Two
  distinct dependencies, both real:
  1. **Registration shape.** feature-001 §1b defines the four registration surfaces —
     which REQUIREMENTS **CC-4** then fixes as the single set no feature may substitute —
     and feature-001 §7 assigns `quality-gates.md`'s completion to this feature
     (*"**Feature-004** … completes `quality-gates.md`'s registration across the four
     surfaces of §1b"*, and it records that surface 1 is partly occupied already). This
     feature performs the registration; feature-001 owns the form.
  2. **Admissibility.** The shipped doctrine admits a conditional doc only *"via the
     propose→confirm gate"* at discovery
     (`canonical/aid/templates/kb-authoring/concern-model.md:106-113`). Every conditional
     document this feature creates — `quality-gates.md` (§8), and a D or C8 doc where
     absent (§7d, §6e) — arrives instead from its **owning skill**. feature-001 §2b is the
     amendment that admits a skill-created conditional document. **Until it lands, a KB
     review can reject documents this feature legitimately created.** Sibling feature-003
     §9 declares the same dependency for the same reason.

  **What it blocks, precisely:** §8a's surface-1 and surface-2 entries and §3b's
  registration rule cannot be authored before the amendment, because they would contradict
  the doctrine text still on disk. The twelve skill bodies and the twelve catalog rows do
  not depend on it and can be authored in parallel.
- **Depends on feature-002 §2 for `.aid/design/` itself.** REQUIREMENTS C-4 records that
  the folder *"is not on `master`"* — confirmed, `ls -d .aid/design` → *No such file or
  directory*. Every one of these twelve skills reads or writes a path inside it, so none
  can be **exercised** before feature-002 §2 lands it; they can be **authored** before.
- **Depends on feature-005 for one description edit.** Bare `/aid-design`'s description
  still advertises *"an architecture sketch"*
  (`canonical/skills/aid-design/SKILL.md:5`), which overlaps `/aid-design-architecture`.
  feature-002 §5 assigns that narrowing to feature-005 §6a; §10 depends on it for the
  routing to be mutual rather than one-sided.
- **Shares one canonical edit with feature-003** — the `aid-config/SKILL.md:160`
  amendment naming the `create` skills as a second runtime producer of
  `knowledge.doc_set` (§3b). feature-003 §6b states the identical obligation; whichever
  feature lands first writes it naming both, and the other verifies rather than repeats.
- **Parallel with feature-003 otherwise** — disjoint directories and disjoint
  destinations. feature-003 writes `roadmap.md`/`backlog.md`; this feature writes C0/C1/C6/C8
  docs.
- **Hands to feature-006** — twelve rows and twelve directories for the render, the
  count sweep, and the whole-set negative-routing check (§10; feature-006 §8a).
- **Internal order:** §3 and §4 first — the destination-resolution rule and the four
  collision assignments — because §7's eight content rules cite them and authoring any
  `create` skill before they are settled would fork them four ways. Then the four `design`
  skills (they define what each seed contains and write its `## Destination`), then
  `create` (it consumes the seed), then `update` (it needs a destination that exists, and
  under CC-3 it is also the consumer of any seed `create` routes). §8a's registration lands
  with, or after, feature-001 §2b's amendment.
