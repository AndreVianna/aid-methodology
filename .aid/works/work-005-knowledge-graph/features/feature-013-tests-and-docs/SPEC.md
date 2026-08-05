# Skill Discoverability And Ship-Time Verification

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-31 | **Fix pass 1** — gate D, rows 1–7 and 9 (rows 8 and 10–16 are LOW/MINOR editorial and stay Pending per Q26's mechanism/editorial split). **Row 1 is an `F1` failure and is recorded as one:** the site roster's move to `site/src/content/docs/skills/` was found while authoring and the *instance* was corrected — a class 4 row was added for the new tree — but the **class** was not swept, so three further clauses plus **AC-T6** still described `reference/skills.md` as the catalogue, and **GR09's first clause would have failed against a correct implementation**. That page renders no per-skill entry and names `aid-summarize` nowhere; every clause resting on it is re-written and the negative is now checked rather than assumed. **Rows 2, 3, 9 are one audit:** GR07(a) is re-quantified over **sites** (a file-granular version was satisfied for `docs/aid-methodology.md` by its table A row alone and for `docs/glossary.md` by its `:60` entry alone, leaving the rest of both files' class 1 sites asserted nowhere); **GR01(b)** is a new preflight that asserts each canonical root and the profile set non-empty, because GR02–GR05(a) were universals over sets derived from undelivered directories and held vacuously; GR03 and GR05(a) move from containment to **set equality**, GR05(b) gains a file-presence clause, GR09's skip-pin becomes a dependency on the preflight; and the per-row residual accounting is rebuilt from the cells (now: every row but GR06). **Row 4:** D3 carries feature-002's *Fires-when* cells across verbatim — the `technology-stack.md` rows fire *Always* and `infrastructure.md`'s two-part condition is split into two rows. **Row 5:** the shared-line set is **derived**, not sampled — every D1 class 1 line plus M2's read for a numeral that moves when a curated skill lands — giving three shared lines in five shared files. **Row 6:** the documentation obligation is re-grounded off §5.9's *duplicated preflight/writeback prose* (that clause is skill-body prose, feature-010's) onto the Knowledge Base's maintenance contracts, FR-7 and this delivery's definition. **Row 7:** every feature-012 citation is now by section, Open Item number or row name; none by line | gate ledger `feature-013-spec.md` |
| 2026-07-30 | **Authored fresh** against the amended REQUIREMENTS, the frozen 001–007 spine and the settled 008–011, per STATE.md **Q26 § Fresh authoring**. Supersedes the 2026-07-28 pre-decision draft entirely; that draft was opened once as a checklist of concerns and used as a base document nowhere. **Ten of its claims are not carried forward because they are false on disk**, and the first is the one that shaped it: it cited REQUIREMENTS **§9** for "the two criteria feature-011 carried" about documentation surfaces and test-coverage parity — **§9 contains neither**, and the words *README*, *catalogue* and *docs/* appear nowhere in REQUIREMENTS.md, so the documentation obligation is **not requirement-derived at all** — §5.9's accepted cost assigns the render and the manifests to feature-012 and its *duplicated prose* to feature-010's skill body, leaving the Knowledge Base's own maintenance contracts, FR-7's sibling rule and this delivery's definition as the three sources (§ Source). It attributed the manifest lockstep story to `tech-debt.md` item **L4** (L4 is the *test-effectiveness gap*; the `io_bounds.py` manifest incident is evidence *inside* it). It listed `docs/install.md` as a roster surface (it names no skill — count only, hence feature-012's) and README's **R1** diagram as needing a node (R1 carries no on-demand KB skill at all). It gave feature-010 three suites (it ships **one**) and feature-011 two contingent ones (it ships **one, unconditional**). It stated the aggregate gate as a single command (`tests/run-all.sh` never reaches `site/`, which is where the merge's fail-by-name guard against an unregistered skill directory lives). It placed the site roster in `gen-reference.mjs` (three rosters now, in two new modules plus the test). Its `GR05` asserted unconditional byte-identity for a **transformed** file, which feature-012 D3 makes conditional. And it said nothing mechanical guards a Knowledge Base count — `tests/canonical/check-skill-counts.mjs` now walks `.aid/knowledge/` | /aid-specify |

## Source

- **REQUIREMENTS.md `:697–:705`** — §5.9's *Decision — separate skill, shared scripts*, cited for what
  it assigns **elsewhere**. Its accepted cost — "one more skill in the canonical→profiles render and the
  install manifests, plus some duplicated preflight/writeback prose" — lands nothing here: the render and
  the manifests are feature-012's, and the duplicated prose is **skill-body** prose (preflight is FR-8's
  gate, writeback the artifact write, both inside `SKILL.md`), which § *The boundary* assigns to
  feature-010. **REQUIREMENTS demands no project-documentation surface anywhere** — the §9 bullet below
  establishes it, and *README*, *catalogue* and *docs/* appear nowhere in the document. So this
  feature's documentation obligation is **not requirement-derived**; its three sources are all cited
  below: the **Knowledge Base's own maintenance contracts** (§ Knowledge-Base grounding), **FR-7's
  sibling rule**, and **this delivery's definition** as the ship gate.
- **REQUIREMENTS.md `:776–777` (C-2)** and **`:778–779` (C-3)** — consumed as the reason the shipped
  result needs a standing check, not as this feature's work: feature-012 performs the render and the
  manifest reconcile, and this feature lands the suite that proves it happened.
- **REQUIREMENTS.md `:333–335` (FR-7)** — `/aid-graph` is "a standalone, on-demand skill — a **sibling
  of `/aid-summarize`** occupying the same post-KB slot in the lifecycle". This is the load-bearing
  clause for every placement decision below: where the sibling is documented is where this skill is
  documented, which makes placement derivable rather than a matter of taste.
- **REQUIREMENTS.md `:813–814` (A-6)** — test fixtures are self-built and depend on no work folder.
- **REQUIREMENTS.md §9** — **cited for what it does not contain.** Read end to end (`AC-1`–`AC-21`):
  no criterion mentions a documentation surface, discoverability, a readme, a catalogue or
  test-coverage parity. *(Every occurrence of "document" in §9 was read rather than counted: each is
  either the **node kind** `document` — AC-1, AC-15, AC-16 — or "documented" describing the graph
  artifact's own runtime prerequisites — AC-6, AC-6a, AC-16a. Neither is a project-documentation
  obligation.)* The acceptance criteria below are therefore **this feature's own**, derived from the
  three sources the first bullet names — not restatements of a requirement. Stated explicitly because
  the pre-decision draft claimed the opposite and built its entire scope on it.

### Inbound obligations routed to this feature

Every row was re-read in the routing SPEC this session, and the claim resting on each citation was
re-checked rather than the anchor alone. Dispositions are **discharged**, **decided**, or **routed
onward**; nothing is silently absorbed.

| From | Where | Obligation | Disposition |
|---|---|---|---|
| feature-001 | SPEC.md`:1513` | `artifact-schemas.md` gains `relationships.md` and the relation-vocabulary contract — the **eight-key** entry with kind-keyed endpoints | **Discharged** — D3 |
| feature-001 | SPEC.md`:1514` | `domain-glossary.md`, **only if** the research coins a spine term; two candidates named | **Discharged as conditional** — D3, with the firing condition kept as the research's, not this feature's |
| feature-001 | Open Item 13, SPEC.md`:1600–:1603` | The same two items; "the content they must carry is what changed" | **Discharged** — the eight-key contract is what D3 states, not the withdrawn seven-key one |
| feature-002 | SPEC.md`:1092–:1094` | `technology-stack.md` § *Frameworks & Tooling*, § *Key Dependencies* (with the zero-runtime-dependency claim scoped, not left ambiguous), § *Version Concerns*. All three **Fires-when** cells read *Always* | **Discharged** — D3, carried across at that firing condition; all three sections verified present |
| feature-002 | SPEC.md`:1095`, Open Item 9 SPEC.md`:1278` | `infrastructure.md` § *The Build* / § *CI/CD Pipeline* — the vendoring procedure **including D7's upstream-equality check**, and any CI lane the headless answer requires. Its **Fires-when** cell is two-part: *"Always for the procedure; the CI lane only if D4b resolves against a headless-only gate"* | **Discharged** — D3, with both parts carried across separately rather than collapsed; the check itself is feature-012 G6, the *procedure text* is here |
| feature-002 | SPEC.md`:1100` | `capability-inventory.md` — the `/aid-graph` entry | **Discharged** — D3 |
| feature-002 | SPEC.md`:115`, `:336` | This feature is **gated transitively** on the rendering research | **Accepted** — § Dependency position; the gate is on those rows' **content**, not on whether they fire |
| feature-005 | Open Item 6, SPEC.md`:1594` | Adding `**Aliases:**` to the shipped glossary template | **Routed onward** — Open Item 3; the item itself names an owner decision this SPEC cannot make |
| feature-005 | Open Item 13(b), SPEC.md`:1647` | A `tested-components:` frontmatter field | **Routed onward** — Open Item 3 |
| feature-005 | Open Item 15, SPEC.md`:1663` | Anchored `see_also:` as a stated convention | **Routed onward** — Open Item 3 |
| feature-006 | SPEC.md`:965` | "**feature-013** owns the documentation surfaces" | **Accepted** — D1 |
| feature-006 | Migration step 4, SPEC.md`:1151`, ownership at `:1154` | A `graph/` row in `module-map.md` § *Script Modules by Area* at ship time | **Discharged** — D3, and widened: the same omission exists in a second document |
| feature-006 | Open Item 9, SPEC.md`:1307` | A Knowledge Base authoring change, **if** the owner decides `site/src/**` coverage grain that way | **Routed onward** — Open Item 3 |
| feature-009 | Open Item 3, SPEC.md`:645–:646` | Where the two-surface parity assertions live — "**Owner: feature-008**, with **feature-013** (test placement)" | **Decided** — L2: they belong in feature-008's suite, and the reason is mechanical. Open Item 2 names feature-008 as the implementing owner |
| feature-010 | Open Item 10, SPEC.md`:1050–:1056` | `quality-gates.md` grade-floor drift, "or the **tests-and-docs feature** if it lands with this work's KB updates" | **Discharged** — D3; the drift is re-verified first-hand below |
| feature-011 | SPEC.md`:156`, `:489` | Cross-feature assertion placement, ship-time documentation, **aggregate lane wiring** | **Discharged, with a decision:** no CI lane is added. D2 states the grounds |
| feature-011 | Open Item 2, SPEC.md`:586–:588` | "**feature-013** for the graph's own lane, which must not be added until the skip is recorded rather than absorbed" | **Discharged by declining the lane** — D2. The condition is satisfiable; the reason not to add one is independent of it and stronger |
| feature-012 | § Feature Flow, closing paragraph; § Tests | The shipped-result suite, the ship-time Knowledge Base updates and the aggregate HOME-pinned run are this feature's | **Accepted** — L1, D2, D3 |
| feature-012 | L3, the **012 / 013** row | The 012/013 seam | **Discharged** — L2, as a **rule** rather than a mirrored table, with 012's text quoted as read this session |
| feature-012 | Open Item 1 | `canonical/skills/aid-graph/README.md` "**with feature-013** if the `README.md` is wanted as a documentation surface" | **Declined, with the reason it supplies** — D1 |
| feature-012 | Open Item 6 | `kb.html`'s stale skill count is explicitly **not** this feature's | **Accepted as not this feature's** — D1 records the exclusion and names the owner |

### Knowledge-Base grounding

- `.aid/knowledge/test-landscape.md` `:113–:114` (glob discovery — "adding a suite requires no edit to
  the runner"), `:173` (the CI lanes and their triggers), `:279` and `:309` (prompt-driven state
  machines are not machine-tested, **by design**), `:307` (full `run-all.sh` runs on master/tag only —
  "Run `bash tests/run-all.sh` + `site` build locally before merge"), `:310` (source inspection is not
  a valid review of a rendered page), `:319–:320` (the HOME-pinned aggregate command and why the pin is
  not optional).
- `.aid/knowledge/tech-debt.md` `:69` and `:163–:175` — **L4, the test-effectiveness gap**: "suite-
  presence + dogfooding is the floor, not the target", with the `io_bounds.py` incident as its proof
  ("five install manifests plus two installer-test lists all asserted each other … The tests ran; they
  did not bite"). `:232–:234` — the rule that incident produced: **anchor to ground truth, not a
  sibling copy**. Both are design constraints on this feature's suite, not decoration.
- `.aid/knowledge/module-map.md` `:186–:196` (§ *Script Modules by Area*, the table D3 amends),
  `:310–:316` (where a new skill goes, and the four required frontmatter keys), `:321–:324` (where a
  new helper script goes), `:337–:338` (never edit a rendered copy).
- `.aid/knowledge/capability-inventory.md` `:190–:199` (§ *On-demand skills*, where the sibling's row
  is) and `:254–:260` (§ *Where each capability lives*, the second site of D3's script-area omission).
- `.aid/knowledge/artifact-schemas.md` `:626–:627` — § *Conventions*, "**Adding an artifact type:** add
  a template under `.claude/aid/templates/`, name its producer/consumer skills, and document its
  required vs optional sections here." This is the shape feature-001's routed item must take.
- `docs/diagram-content-reference.md` `:14–:15` — the maintenance rule ("if you add, remove, or
  relabel a diagram, update this reference in the same change") — and `:24`, the skill-add trigger row.

### Dependency position

**Last, and that is the point.** Every surface here describes something another feature built, so each
can only be written truthfully once that feature has landed, and the suite can only run once
feature-012 has rendered. This is the ship gate: the single place a reviewer can stand and ask *is this
actually finished?*

Two dependencies are on **findings** rather than artifacts, and they differ in kind. **feature-002's
research gates D3's `technology-stack.md` / `infrastructure.md` rows transitively** (its `:115`,
`:336`) — but on their **content, not their firing**: those rows fire *Always*, because the
architecture's third-party adoption is settled rather than open (its `:120–:121`), and what feature-002
supplies is the text they carry. The one part conditional on a finding is the CI lane inside the
`infrastructure.md` routing, which fires only if that feature's **D4b** resolves against a
headless-only gate. **feature-001's research gates the `domain-glossary.md` row's firing** — whether a
term belongs to the spine is its judgment, not this feature's. Everything else here depends on
artifacts.

## Description

A skill that ships but cannot be found has not really shipped. That is the half of this feature a
reader expects. The half that decides whether it works is narrower and less obvious: **where** the
skill is documented is not a judgment call, because FR-7 already fixed it. `/aid-graph` is a sibling of
`/aid-summarize` in the same post-Knowledge-Base slot, so every surface that names `/aid-summarize`
owes a corresponding entry, and every surface that does not, does not. That turns a taste question into
a derivation — and a derivation can be asserted, where a list of surfaces can only be maintained.

Maintaining it is exactly what fails. The Knowledge Base records the failure mode inside
`tech-debt.md`'s **L4** — which is the *test-effectiveness gap*, and the `io_bounds.py` incident is the
evidence it rests on (`:173–:175`): five install manifests and two installer-test lists all asserted
each other, all passed, and every one of them was missing the same shipped file. The rule that incident
produced is the design constraint here — **anchor to ground truth, not a sibling copy**
(`:232–:234`). So the surfaces are not checked against a list
written into this SPEC; they are checked against the sibling skill's own placement, and the set of
surfaces is itself checked, so a surface that appears later cannot appear unnoticed.

The other half is proving the thing arrived. Each feature in this work brings the tests for its own
mechanism, and three properties are left over because no feature that builds one can observe it: that
the skill genuinely reached every host profile tree and the dogfood tree, **as a set of files derived
from the canonical source rather than from the manifest that claims to describe it**; that the whole
canonical suite is still green when run the way the project documents; and that the site's own suite —
which `tests/run-all.sh` never reaches — is green too, because that is where the guard that fails **by
name** for an unregistered skill directory now lives.

One thing this feature deliberately does not do is add a CI lane. The reasoning is in D2 and it is not
a shortcut: the lanes that would carry it run on `master` only, and the one lane that would be the
natural home has been passing by skipping for as long as the summary has lived at its current path.

## User Stories

- As a **newcomer to the project**, I want the new skill listed wherever its closest sibling is
  listed, so that I find it in the place I already know to look.
- As a **maintainer/architect**, I want the surfaces derived from the sibling rather than enumerated
  by hand, so that the list cannot silently fall out of date the way the install manifests did.
- As a **maintainer/architect**, I want a suite that asserts the skill arrived in every rendered tree
  by comparing each tree to the **canonical source**, so that a missed render fails mechanically
  instead of being caught by a reader.
- As a **maintainer/architect**, I want the Knowledge Base to describe the toolkit as it stands the
  moment this work ships, so that the next feature starts from an accurate map.
- As the **AID methodology owner**, I want the ship gate to run every gate the project actually has —
  including the one outside `run-all.sh` — so that "green" means what it says.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-T1** Given the shipped skill, when every hand-authored documentation surface carrying an
      `/aid-summarize` roster slot is checked **at the granularity of the slot rather than of the
      file**, then each slot has a peer `/aid-graph` slot — and any hand-authored file naming
      `/aid-summarize` that this SPEC has not classified fails the check **by name**, so the surface
      set cannot grow unnoticed.
- [ ] **AC-T2** Given those surfaces, when the placement is checked, then `/aid-graph` sits in the same
      group, table and block as `/aid-summarize` rather than merely appearing somewhere in the file —
      asserted mechanically wherever placement is decidable from the text, and read back where only a
      human can judge it, with the SPEC stating which sites are which.
- [ ] **AC-T3** Given the diagram maintenance contract, when it is read after this work, then its
      skill-add trigger row is accurate for a **curated on-demand** skill — naming the diagrams such a
      skill actually appears in — and any diagram this work changed is reflected in the same change,
      per that document's own maintenance rule.
- [ ] **AC-T4** Given the completed render, when the registration suite runs, then for every profile
      the generator enumerates, and for the dogfood tree, the set of shipped `aid-graph` files **equals
      the set derived from `canonical/skills/aid-graph/` under the generator's own emission rules** —
      a set comparison against the canonical source, never against another rendered tree or against
      the manifest.
- [ ] **AC-T5** Given the shared script area, when the registration suite runs, then each rendered
      tree's graph-script set **equals** the canonical one — with the canonical area asserted non-empty
      first, so an unbuilt area fails rather than satisfying the comparison — and the coverage
      predicate, the one file executed in **two** runtimes, is byte-identical to its canonical
      original, with the precondition that makes that guarantee sound asserted alongside it rather
      than assumed.
- [ ] **AC-T6** Given the generated documentation surfaces that carry a **per-skill entry** — the site's
      skill roster and the synced methodology copy — when they are checked, then each carries
      `/aid-graph` in the sibling's place, so a generation step that was never run fails here instead of
      shipping. The generated surfaces that carry **no** per-skill entry are excluded **by name** in
      D1 class 4, with the generator behaviour that puts them there, rather than by omission.
- [ ] **AC-T7** Given the branch immediately before it ships, when **both** gates the project documents
      are run locally — the HOME-pinned canonical suite and the site suite and build — then both pass,
      and the run is local because neither gate fires on a feature branch.
- [ ] **AC-T8** Given the shipped work, when the Knowledge Base is checked, then `/aid-graph` has a
      capability entry, the new script area appears in **every** document that enumerates script areas,
      the artifact schema set covers `relationships.md`, and the release ledger records the addition.
- [ ] **AC-T9** Given this work's test coverage, when the census is run at ship time, then it **reports
      the set** of suites and what each proves, names any behaviour with no suite that fails when it
      breaks, and raises that gap against the owning feature rather than patching it here.

---

## Technical Specification

> **Assertion prefix: `GR*`** (graph registration), which feature-012 already declares for this feature
> (its § Technical Specification prefix note) and which no other document in this work uses. Criteria
> carry **`AC-T*`**, unused elsewhere — siblings hold `AC-G` (006), `AC-R` (012) and `AC-S` (003/005/010).
>
> **Citation convention, from STATE.md Q23.** `canonical/`, the `profiles/` renders and the dogfood
> `.claude/` tree are **different artifacts**. Every source path below is cited at the tree the claim
> is about, and where a claim is about the rendered result it says so. The repository is in render
> drift as this is written — verified here rather than taken on report: the canonical
> `graph/relation-vocabulary.yml` committed in `3fc7cdb4` is present in no profile tree, no emission
> manifest and not in the dogfood tree, which is what feature-012's **D1** also records. That is
> precisely why the distinction matters.
>
> **Every line citation below was read on disk after the `origin/master` merge (`00194684`), and the
> argument resting on each was re-checked rather than the anchor alone.** Grounded in `README.md`,
> `docs/{aid-methodology,repository-structure,glossary,install,diagram-content-reference}.md`,
> `site/scripts/{gen-reference,gen-skills,sync-docs}.mjs`, `site/scripts/.synced-manifest.json`,
> `site/scripts/skills/{curated-roster,groups,skill-counts}.mjs`,
> `site/scripts/__tests__/gen-reference.test.mjs`, `site/package.json`,
> `tests/{run-all.sh,coverage-parity.sh}`, `tests/canonical/{test-doc-counts.sh,check-skill-counts.mjs}`,
> `tests/lib/sandbox.sh`, `.github/workflows/{test.yml,docs.yml,coverage-parity.yml}`,
> `profiles/*.toml`, `profiles/*/emission-manifest.jsonl`, `.aid/settings.yml`, and the KB documents
> named in § Knowledge-Base grounding.
>
> **What this SPEC cannot verify, stated once.** `canonical/aid/scripts/graph/`,
> `canonical/skills/aid-graph/` and the `knowledge-graph/` template set are **undelivered**. Every
> clause about them is reviewable as *specification* — a contract an implementer must satisfy — never
> as *behaviour*. Where an assertion depends on a property of a file that does not exist yet, it is
> written so the property is **asserted rather than assumed**, which is the only form available.

### The boundary — what this feature does not do

Stated first, because "tests and docs" reads as a catch-all.

| It does not | Because | Owner |
|---|---|---|
| Edit a count, or increment one | A count edit is keyed on a **number**; both count gates decide completeness for that class | feature-012 (its D4) |
| Edit any site roster module or its test mirror | Same rule: a roster row is 012's; the **read-back** of the rendered page is this feature's | feature-012 (its D4 Class 2) |
| Run the profile generator, touch a manifest, or add a `.gitattributes` rule | Registration | feature-012 |
| Regenerate `.aid/knowledge/kb.html` | Build output, hand-edit-forbidden, and explicitly **not** this feature's (feature-012 Open Item 6) | a `/aid-housekeep` SUMMARY-DELTA run |
| Write a test for another feature's mechanism | A suite lives with the mechanism it proves; one authored elsewhere goes stale the moment its subject changes, because its author is not the person editing the subject. A gap the census finds is **raised**, not patched | the owning feature |
| Add or modify a CI lane | D2 | — |
| Assert anything about the canvas, the table view, a frame rate, or how a page looks | This suite has no browser and must not acquire one: `test-landscape.md:310` sends rendered-page review through the Playwright visual gate, which is a **separate lane**, never a canonical suite | features 002, 008, 009; feature-010's `V-T` rubric row |
| Author `SKILL.md`, its `description` frontmatter, or any `references/*.md` | Skill content | feature-010 |
| Fix `validate-html-output.sh`'s `--kb-dir` documentation, or the skipping visual-fidelity lane | Both already routed; neither is owed here | feature-011 (its D2 closes the first; its Open Item 2 carries the second), the work owner |

### Data Model

#### D1 — The discoverability surfaces, derived rather than listed

**The derivation is the contract.** FR-7 makes `/aid-graph` a sibling of `/aid-summarize` in the same
post-Knowledge-Base slot, so a hand-authored documentation surface owes an `/aid-graph` entry **iff it
carries an `/aid-summarize` entry as a roster slot** — a row in a skill table, a node in a skill
diagram, a member of a skill list, or its own definition. A mention that is *about* the sibling rather
than *a slot for* it owes nothing. No count of surfaces appears in this SPEC; the rule is what a reader
re-derives, and **GR07** is what stops the derivation and the disk from parting company.

**Why a bare grep is the wrong instrument, with the counter-examples on disk.**
`docs/aid-methodology.md` names the sibling at several sites and **two** are not slots: `:730` compares
`aid-housekeep` to it ("This mirrors `aid-summarize` — an optional skill in the Knowledge Base
Maintenance group"), and `:783` names it as the command `SUMMARY-DELTA` invokes.
`docs/diagram-content-reference.md:63` names it as the *generator* of the kb.html diagrams. Adding
`/aid-graph` at any of those three sites would be wrong. So the classification is declared below, and
**GR07's second clause is a clamp** — modelled on the one the merge added at
`site/scripts/__tests__/gen-reference.test.mjs:188–:190`, which fails **by name** for an on-disk skill
directory no roster knows about — failing by name for any hand-authored document that names the
sibling and appears in neither class 1 nor class 2.

**Class 1 — roster surfaces. This feature's edit.**

| Surface | Where the sibling sits | This feature's entry |
|---|---|---|
| `docs/aid-methodology.md` §1 *Skill Inventory* **table A**, `:104–:122` | `:108`, group *Knowledge Base Maintenance* | One row, same group, `Phase` = `—`, mandatory-pipeline cell in the sibling's shape. **Table A and no other**: B is `/aid-triage`, C is `/aid-ask`, D is the shortcut catalog's rows — and `/aid-graph` is curated and hand-authored, so D is structurally wrong for it. *(The pre-decision draft left this "deliberately open"; it is decidable from the tables' own definitions and is decided here.)* |
| `docs/aid-methodology.md` §4 *The Phases* table, `:389–:404` | `:393` | One row whose `Output` cell names both artifacts |
| `docs/aid-methodology.md` §1 Mermaid flow, **`G1` group box**, `:47–:51` | node `Sum` at `:49` | One node in `G1`, styled as the sibling's `:::aux` is. This is the "site **methodology skill diagrams**" target `docs/diagram-content-reference.md:24` names |
| `docs/aid-methodology.md` group prose `:408`, cross-reference `:432` | each names the sibling in the group's on-demand list | The name added to each list |
| `docs/aid-methodology.md` deep-dive `:481–:485` | `#### aid-summarize — Optional KB Viewer` | A sibling subsection. Its **presence** is asserted as a peer `####` under the same parent heading (GR07(a)); its **adequacy** is a read-back — prose presence is checkable, prose adequacy is not |
| `docs/repository-structure.md:73` | inside the curated breakdown, "the optional `aid-summarize` viewer" | The name added to that breakdown. **That same line carries the count**, so it takes one edit from each feature — see L2 |
| `docs/glossary.md` | its own entry at `:60`; the on-demand family list at `:54` | One `**aid-graph:**` entry in the sibling's shape, and the name added to `:54`'s list. **`:54` also carries the curated total**, so it takes one edit from each feature — see L2 |
| `README.md` on-demand list, the fenced block at `:132–:152` | `:146` | One `/aid-graph` line in the same block |

**Class 2 — names the sibling, owes nothing.** `docs/aid-methodology.md:730` and `:783`;
`docs/diagram-content-reference.md:63`. Declared so GR07's clamp can tell them from a surface that was
missed.

**Class 3 — count-only. feature-012's, listed only so nobody folds them into this diff.**
`docs/install.md:411`, `README.md:13` and `:45`, `docs/aid-methodology.md:100` and `:102`,
`docs/repository-structure.md:73`'s numerals, `docs/diagram-content-reference.md:24`, `:102`, `:107`
and `:109` (Open Item 6 — that file takes an edit from each feature at `:24`), and every further site
the two count gates report. **None of them names an individual skill.** *(`docs/aid-methodology.md:128` looks like a member and is not:
its figures are the shortcut catalog's rows, canonical names, aliases and `repurpose` entries, none of
which a curated hand-authored skill moves — `test-doc-counts.sh:47–:51` derives them from
`shortcut-catalog.yml`, which takes no row here.)* A curated skill landing moves the derivation at
`tests/canonical/test-doc-counts.sh:44` — `find canonical/skills -mindepth 1 -maxdepth 1 -type d | wc -l`
— automatically; it is those hand-written literals that go stale, which is why the class is a count
class and not a roster class.

**Class 4 — generated. Read-back, never an edit.** One of these is the site's skill roster and one
renders no per-skill entry at all — **which is which is a property of the generator, read rather than
assumed.** Stated that way because this SPEC's own first pass carried the pre-decision draft's answer,
which the merge had already invalidated.

| Surface | Generator | This feature |
|---|---|---|
| `site/src/content/docs/skills/aid-graph.md`, and the grouped roster `site/src/content/docs/skills/index.md` | `site/scripts/gen-skills.mjs` | **This is the site's skill roster.** Read back that the per-skill page exists and that the index lists `aid-graph` under the same `##` group heading the sibling sits under — *Knowledge Base Maintenance*, cited by heading rather than by line because this very change moves the lines. Both texts are `SKILL.md`'s `description` frontmatter, which is **feature-010's**; if the entry reads badly, raise it there rather than editing the page. This tree arrived with the merge and did not exist when the pre-decision draft was written |
| `site/src/content/docs/reference/skills.md` | `site/scripts/gen-reference.mjs`, `generateSkillsPage()` | **No entry is owed, and that is checked rather than assumed.** This page is the *shortcut-engine* narrative, not a roster: `generateSkillsPage()` (`:228–:270`) returns frontmatter, a pointer to `/skills/`, and `generateShortcutEngineSection`, touching the skills tree only for a drift guard (`:237–:248`) and for the skill total in that pointer (`:265`). It renders **no per-skill entry and no group**, and names `aid-summarize` nowhere — so under D1's derivation `/aid-graph` owes it nothing. The one thing this work moves on it is the skill total inside that pointer, which the generator recomputes from disk — a **generated** count, so it is no feature's edit. *(The pre-decision draft treated this page as the catalogue; the roster moved to `/skills/` with the merge, and the page's own pointer at `:9–:11` says so.)* |
| `site/src/content/docs/concepts/methodology.md` | `site/scripts/sync-docs.mjs`, per `site/scripts/.synced-manifest.json` | **Never hand-edit.** It follows from the `docs/aid-methodology.md` edit plus the sync, which `npm run prebuild` also chains |
| `.aid/knowledge/kb.html` four-plane module map | `/aid-summarize` | **Not this feature's** — feature-012 Open Item 6 routes the regeneration to a `/aid-housekeep` SUMMARY-DELTA run, and `test-doc-counts.sh:18–20` excludes `.aid/knowledge/` from that guard by design |

**Two decisions this classification forces, both against the pre-decision draft.**

1. **README's `R1` diagram gets no node, and the maintenance contract is what changes instead.** Read
   in full (`README.md:17–:44`), `R1` contains **no** `/aid-summarize` node and no `/aid-housekeep`
   node: it carries the entry points, the numbered path, the shortcut engine and the two Monitor
   loopbacks. `docs/diagram-content-reference.md:45–:52` states exactly that as its content contract,
   and its update-trigger list at `:56–:57` names shortcut families, `/aid-triage` routing, the
   engine's phase list and Monitor's loopbacks — none of which a curated on-demand skill touches. But
   the quick-index row at `:24` says a skill add updates "README **R1**". **Those two clauses disagree
   for this class of skill**, and adding a node to satisfy the index would put a diagram in conflict
   with its own stated contract — which that document itself calls a defect (`:14–:15`). The
   resolution is to correct the trigger row so it distinguishes a catalog/shortcut add (which does
   reach `R1`) from a curated on-demand add (which does not), **in the same change**, per the
   maintenance rule. That is **AC-T3**. It is the only place this feature edits a diagram *contract*;
   the only *diagram* it edits is the methodology `G1` group box, which class 1 already names.
2. **`canonical/skills/aid-graph/README.md` is declined as a documentation surface.** feature-012 Open
   Item 1 offers it here conditionally and supplies the fact that settles it: `render.py:536–609` emits
   `SKILL.md`, `references/*.md` and a verbatim `scripts/` directory **and nothing else**, so a
   canonical skill `README.md` never reaches a profile, an adopter or the site. It can satisfy no
   discoverability obligation, and wanting one here would be wanting a file no reader ever sees.
   Declined — and **GR02**'s set comparison fails if one ever ships, which makes the decline a check
   rather than a preference.

#### D2 — The ship gate: two commands, no new CI lane, and a census that reports a set

**The gate is two commands, not one, and the pre-decision draft's single command misses the half that
matters most for this work.** Verified: `tests/run-all.sh` discovers suites by the glob
`suites=( tests/canonical/test-*.sh )` (`:112`; `test-landscape.md:113–:114` states the same contract),
and it references `site/` **nowhere** — no canonical suite invokes `vitest` or `npm test`, checked
across `tests/canonical/*.sh`. The site has its own suite and its own gate, declared in
`site/package.json`: `test` is `vitest run`, and `build` is preceded by `prebuild`, which chains
`sync:docs → gen:reference → gen:skills → fetch:release`. **That is where the guard that fails by name
for an unregistered skill directory lives** (`gen-reference.test.mjs:188–:190`), so a ship gate that
runs only `run-all.sh` cannot observe the single most likely omission this work can make.

```bash
# 1 — the canonical suite. The HOME pin is not stylistic.
HOME="$(mktemp -d)" bash tests/run-all.sh

# 2 — the site suite and build, which run-all.sh never reaches.
cd site && npm ci && npm test && npm run build
```

The HOME pin is required by `test-landscape.md:319–:320`, which gives this exact command, and by its
HOME-pinning hazard at `:295–:298`: the migration scan defaults its root to `$HOME`, so an unpinned run
migrates the developer's real repositories. Command 2 is the same sequence
`.github/workflows/docs.yml`'s build job performs — `npm ci`, then `npm test` before `npm run build` so
a red suite never produces an artifact.

**Both gates run locally because neither fires on a feature branch.** `.github/workflows/test.yml:13–:18`
triggers on `pull_request` and `push` to `master` only; `docs.yml:11–:22` likewise, additionally
path-filtered. `test-landscape.md:307` records the consequence as a known gap in the project's own
words: "Full `run-all.sh` runs on master/tag only … Run `bash tests/run-all.sh` + `site` build locally
before merge." A green feature branch is therefore evidence of nothing, which is why this is an
acceptance criterion (**AC-T7**) and not a checklist line.

**No CI lane is added, and this discharges feature-011's aggregate-lane routing (its `:156`, `:489`)
rather than deferring it.** Three grounds:

1. **A lane added here would not run here.** Both workflows are master-only, so a lane wired on this
   branch proves nothing about this branch and would first execute after the merge it was meant to
   gate.
2. **The natural home is a lane that cannot fail.** `.github/workflows/test.yml:105` sets
   `SUMMARY=".aid/dashboard/kb.html"` and the step exits 0 with a SKIP when that file is absent
   (`:106–:110`). That path does not exist — verified on disk; the summary lives at
   `.aid/knowledge/kb.html`. So the `visual-fidelity` lane has been SKIPping unconditionally, and
   wiring the graph into it would import a false green. feature-011 Open Item 2 carries the defect and
   names the work owner for the existing lane. **No assertion or acceptance criterion in this SPEC
   draws coverage from that lane**, and the census reports it as a lane that runs nothing rather than
   as a lane that passes.
3. **Nothing this work adds needs one.** Every new suite is a `tests/canonical/test-*.sh` file, so the
   `canonical-tests` job picks it up through the existing glob with no workflow edit — the same
   property that let `test-skill-counts.sh` reach the runner unwired. The only checks that would need
   a browser are the canvas's and the frame-rate floor, and those are feature-002's harness, feature-
   008's assertions and feature-010's `V-T` rubric row, all outside the canonical suite by design.

**The condition under which this decision changes** is stated so it is a decision and not an
omission: if feature-002's **D4b** resolves against a headless-only gate — the exact condition its
`infrastructure.md` § *CI/CD Pipeline* routing cell states (its `:1095`) and the one D3's last row
carries — the lane is added **then**, with feature-011 Open Item 2's precondition satisfied first: a
skip recorded rather than absorbed.

**One runner-adjacent gate, and the pre-decision draft's concern about it is stale.**
`tests/coverage-parity.sh` compares an executed-assertion inventory against `tests/coverage-baseline.tsv`
(present and committed) and fails on any un-excused **net-removed or reduced** assertion; net-adds are
reported, not failed (`:503`). Adding suites is therefore safe by construction. The draft's caveat —
that feature-011's *contingent* suites might not appear and leave a removal behind — no longer applies:
feature-011 ships **one unconditional** suite, `tests/canonical/test-validator-profiles.sh` (its
`:476`), and only three *mechanisms* inside it are contingent, each asserted **absent** until its
trigger fires (its `PV20`). Nothing in this work removes an assertion.

**What that check does and does not cover, because a verification's scope is itself a claim.** The
baseline files are present and the gate's rule was read at `coverage-parity.sh:11` and `:503`. The
`diff` was **not run**: that command re-collects the whole corpus serially, and the lane's own header
records that "the corpus hangs under the local Windows/cygwin shell"
(`.github/workflows/coverage-parity.yml:15–:18`), which is why the baseline is captured on CI and never
from an authoring worktree. So the claim above is
about the **rule** — net-adds do not fail it — and not a statement that the live corpus currently
self-diffs clean against a baseline captured before the `origin/master` merge. That is the lane's own
question, not this feature's.

**The census: a set, reported, never a number.** No acceptance criterion in REQUIREMENTS §9 asks for
it; it exists because `test-landscape.md`'s Coverage Assessment measures **suite-presence per
subsystem** and `tech-debt.md`'s **L4** records that suite-presence "has proven insufficient on its
own" — the `io_bounds.py` incident being the proof. The total is the one thing no individual feature
can see, and this is the last feature that touches the branch.

At ship time the census is derived, not recited: read each feature SPEC's own § Tests section in this
work, and report one row per suite it declares — the suite path, its assertion-id prefix, the
behaviour it proves — plus every behaviour a § Tests section marks as **deliberately not tested**, so
the accepted gaps sit in one place. Then assert, against disk, that every declared suite exists and
exits 0, and that no declared suite is missing. A suite a feature declared and never landed is exactly
the failure the total exists to catch.

Two properties of that procedure are load-bearing:

- **It reports what is there rather than asserting a number.** The suite set is whatever the SPECs
  declare; a numeral here would be a count standing in for a set (Q19) and would be wrong the moment a
  feature splits or merges a suite.
- **It is a ship-time procedure, not a suite assertion, and the reason is A-6.** Deriving the set
  requires reading `.aid/works/…/features/*/SPEC.md`, and a committed suite may contain **no**
  work-folder path — it has to keep working after the work folder is pruned. The procedure is
  transient and may read the work folder; its **durable output** is the `test-landscape.md` row D3
  lands, which states the enduring fact (these suites exist, they cover these areas) without citing
  the folder they were derived from.

**One check the census must not silently skip.** Prompt-driven skill state machines are not
machine-tested, by project design (`test-landscape.md:279`, `:309`), so no suite drives `/aid-graph`
end to end and none should be written. The census reports that as an accepted gap with its authority,
rather than leaving a reader to infer that the state machine is covered.

#### D3 — The ship-time Knowledge Base updates

These land **after** the artifacts they describe exist. Each row names the document, the section, and
the condition under which it fires; nothing here is unconditional-by-omission.

| Document · section | Update | Fires |
|---|---|---|
| `module-map.md` § *Script Modules by Area*, `:186–:196` | A `graph/` row naming the scripts features 003–007 and 010 place there and the skill that consumes them | Always |
| `module-map.md` § *Module Inventory* row `:87` | That row enumerates the script areas in prose — `(config, connectors, execute, housekeep, kb, migrate, release, summarize)` — so `graph` is added there too | Always |
| `capability-inventory.md` § *Where each capability lives*, `:260` | The **same** prose enumeration of script areas, third site | Always |
| `capability-inventory.md` § *On-demand skills*, `:190–:199` | One capability row beside `/aid-summarize`'s at `:199`, in that table's three-column shape | Always |
| `artifact-schemas.md` | `relationships.md` and the relation-vocabulary contract added as artifact types, in the shape § *Conventions* `:626–:627` prescribes — a template named, producer/consumer skills named, required-vs-optional sections documented. **The contract is the eight-key entry with kind-keyed endpoints** (feature-001 `:1513`), never the withdrawn seven-key prefix-keyed one | Always |
| `test-landscape.md` | A row for this work's suites in § *The Canonical Helper Suites*, and the canonical-suite figure refreshed at its live sites `:88` and `:125`. **`:96–:97` needs a judgment, not a substitution:** it states a live total *and* a historical decomposition of it into surviving pre-existing suites plus work-024's own, so bumping the total alone breaks the arithmetic. Either the decomposition moves with it or the sentence is re-framed as a record of that work — decided at ship time by whoever writes the row, not prescribed here | Always |
| `release-tracking.md` § *Unreleased*, `:24` | One `[NEW]` item leading with the feature name, per that document's own rule at `:18–:22` | Always |
| `quality-gates.md` `:177–:182` | The grade-floor drift feature-010 Open Item 10 routes here | Only if it lands with this work's updates — see below |
| `technology-stack.md` §§ *Frameworks & Tooling* `:88`, *Key Dependencies* `:215`, *Version Concerns* `:235` | feature-002's drafted content (its `:1092–:1094`), with the zero-runtime-dependency claim **scoped rather than left ambiguous** | Always — carried across from all three source cells verbatim. The architecture's third-party adoption is **settled**, not open (its `:120–:121`); what is gated is the content, not the firing |
| `infrastructure.md` § *The Build: Multi-Profile Render* `:84` | The vendoring procedure **including feature-002 D7's upstream-equality check** (its `:1095`, Open Item 9 `:1278`) | Always for the procedure — the first half of that cell's two-part condition |
| `infrastructure.md` § *CI/CD Pipeline* `:104` | Any CI lane the headless-admissibility answer requires | Only if feature-002's **D4b** resolves against a headless-only gate — the second half, kept separate rather than collapsed into the first. D2's reversal condition is the same one |
| `domain-glossary.md` § *Concept Spine* `:69` | Up to two spine concepts — the core/extension split and the standards-attribution rule (feature-001 `:1514`) | Only if the research coins a term that belongs to the spine; that judgment stays feature-001's |

**The suite figure is a derivation, not a prediction.** It is
`ls tests/canonical/test-*.sh | wc -l`, stated as the live value at ship time, and no numeral for it
appears in this SPEC. `tech-debt.md`'s **L4** carries the same figure at `:69` and `:167` and moves
with it. Worth stating because it changes what the edit is: those sites already disagree with the
derivation **before this work adds a suite** — run this session, the command does not return the
figure they state — so the refresh is a **correction** the row already owed, not a bump. **Dated
change-log rows are left alone**: `test-landscape.md:392` and `tech-debt.md:385` record what was
corrected when, and editing them would make them lie about the past. That is the reasoning
`check-skill-counts.mjs:147–:158` already applies to `release-tracking.md` and
`.aid/knowledge/STATE.md`, adopted here rather than invented.

**The grade-floor drift, re-verified first-hand rather than inherited.** `quality-gates.md:177–:182`
states the global as `review.minimum_grade: A+` with a per-skill `summary.minimum_grade: A+` override
that "remains", and closes "CONFIRMED in `.aid/settings.yml`". On disk that file carries a **flat
top-level** `minimum_grade: B-` at `:6`, with the owner's lowering recorded in the comment at `:9–:10`,
and **no per-skill block at all** — `grep` for `^summary:` and `^review:` returns nothing. So both the
key's shape and its value have drifted, and the "CONFIRMED" tag is what makes it worth fixing rather
than leaving: a stated verification suppresses the scrutiny that would catch it. feature-010 Open Item
10 classifies it **editorial** and offers it here or as a `/aid-update-kb` delta; it lands here only if
this feature's KB pass is the next thing to touch that file, and it is not owed if a delta lands first.

**What still has no mechanical guard, stated precisely rather than as a blanket.** Two things changed
with the merge and the pre-decision draft's blanket claim is now half wrong. A stale **skill count**
inside `.aid/knowledge/` **is** caught: `tests/canonical/check-skill-counts.mjs` walks `docs`,
`.aid/knowledge`, `canonical` and `site/src/content/docs` plus `README.md` (`INCLUDE_FILES` at `:145`,
`INCLUDE_TREES` at `:160–:165`) and fails on any stated count that disagrees with the derivation and is
not marked as history. A **missing row** is still caught by nothing: `test-doc-counts.sh:18–20`
excludes `.aid/knowledge/` from the doc-count guard by design, naming `/aid-housekeep` as its
reconciler, and no gate reads a capability table or a script-area list for completeness. That absence
is why these updates are an acceptance criterion (**AC-T8**) rather than a step in a list.

### Feature Flow

Runs after feature-012's render and reconcile sequence, and after every other feature's suites are
green. Steps 1 and 2 are preconditions owned elsewhere, named so the ordering is explicit.

1. **(Precondition, elsewhere)** feature-012's Feature Flow completes — the render, the presence and
   parity assertions, the dogfood resync, the count and roster reconcile, and its
   `gen-reference` / `gen-skills` / `npm test` run.
2. **(Precondition, elsewhere)** Each feature's own suite is green.
3. **Add the roster entries** — every D1 class 1 site, and no class 2, class 3 or class 4 file. The
   deep-dive subsection's **prose** is read back here, by whoever writes it: GR07(a) asserts the
   subsection exists, and adequacy is not mechanically decidable.
4. **Correct the diagram maintenance contract** (`docs/diagram-content-reference.md:24`) so its
   skill-add trigger distinguishes a catalog/shortcut add from a curated on-demand add, **in the same
   change** as step 3, per its own maintenance rule at `:14–:15`.
5. **Sync the site copy** of the methodology document — never hand-edit it:
   ```bash
   node site/scripts/sync-docs.mjs
   git diff --stat -- site/src/content/docs/
   ```
   The diff must show `concepts/methodology.md` and nothing else. Steps 3 and 5 are inseparable: the
   source edit without the sync leaves the site showing the previous toolkit. This step is **this
   feature's** rather than feature-012's because the source it syncs is a roster edit this feature
   makes; feature-012's step 9 runs the two skill generators and does not run `sync-docs.mjs`.
6. **Read back the generated roster.** Confirm `site/src/content/docs/skills/aid-graph.md` exists and
   that `site/src/content/docs/skills/index.md` lists `aid-graph` under the same `##` group heading as
   `aid-summarize`, with a description that reads as a complete summary beside its sibling's. The text
   comes from `SKILL.md`'s `description` frontmatter — raise a defect against **feature-010** if it
   reads badly; do not edit the generated page, which the next build would revert.
   `site/src/content/docs/reference/skills.md` is **not** a roster (D1 class 4) and is read back for
   nothing.
7. **Land and run the registration suite** (L1):
   ```bash
   bash tests/canonical/test-graph-skill-registration.sh
   ```
8. **Run the census** (D2) and raise every gap against its owning feature.
9. **Run both ship gates, locally** (D2). `npm run build`'s `prebuild` chain re-runs `sync:docs`,
   `gen:reference` and `gen:skills`, so a clean
   `git status --porcelain -- site/src/content/docs/` afterwards is also the fixed-point confirmation
   for step 5 and for feature-012's step 9. Scoped to that path because the build also writes
   `site/dist/`, which `site/.gitignore:2` excludes.
10. **Land the Knowledge Base updates** (D3), last, because every row describes something the steps
    above made true.

### Layers & Components

#### L1 — The registration suite

`tests/canonical/test-graph-skill-registration.sh`, discovered by the `tests/canonical/test-*.sh` glob
(`tests/run-all.sh:112`; `test-landscape.md:113–:114`) with **no edit to the runner and no workflow
edit**. It sources `tests/lib/assert.sh` and uses the `ID + description` label convention
`tests/canonical/test-guardrails-d012.sh` follows.

**It reads the repository directly, and that is the one legitimate exception to the self-built-fixture
rule.** A `mktemp -d` fixture cannot observe a missed render, because the thing under test **is** the
rendered repository. The precedent is on disk and is not an invention:
`tests/canonical/test-dogfood-byte-identity.sh` walks the real repo-root `.claude/` tree against the
real committed manifest for exactly this reason. `test-landscape.md`'s § *Test Data Strategy* records
temp-dir isolation as the practice for suites that need a throwaway target, which this suite does not:
it writes nothing.

**A-6 holds by construction.** The suite contains **no `.aid/works/` path** and no reference to a work
folder in any form, so it keeps working after this work folder is pruned. Its expectations come from
`canonical/` and from `profiles/*.toml`, both permanent.

**It invokes no PowerShell and no browser, and the rule was checked rather than assumed.**
`tests/lib/sandbox.sh:28–:33` and `:73–:75` pin `USERPROFILE`, `HOMEDRIVE` and `HOMEPATH` in addition
to `HOME`, because a native `pwsh` derives `$HOME` from `USERPROFILE` and a HOME-only sandbox would
reach the developer's real `~/.aid`. That helper binds suites that invoke `bin/aid.ps1` or another
native PowerShell entry point; this suite invokes neither, and takes no sandbox because it needs none.
It likewise launches no browser — `test-landscape.md:310` routes rendered-page verification through
the Playwright visual gate, which is a separate lane and never a canonical suite.

Its assertions are in § Tests.

#### L2 — The 012 / 013 seam, stated as a rule

**Deliberately not a mirrored table.** feature-012 is at an open gate as this SPEC is written and its
last pass moved three claims, so a table asserting byte-identity with it would be a promise nothing
keeps. Its **L3 `012 / 013` row** read, when it was read this session:

> | **012 / 013** | A documentation edit whose reason is **a number or a roster row**: the surfaces both
> count gates report, and every site roster surface D4 Class 2 names | **feature-013** owns every test
> suite (including the shipped-result registration suite), the ship-time Knowledge Base updates —
> `module-map.md`'s `graph/` row (feature-006 Migration step 4, its SPEC.md`:1151`),
> `artifact-schemas.md`, `capability-inventory.md`, `technology-stack.md`, `infrastructure.md`,
> `release-tracking.md` — and the discoverability documents |

**The rule, in one line:** a documentation edit is **feature-012's** when its reason is a *number* or a
*site roster row*, and **this feature's** when its reason is a *prose entry naming the skill*. Every
classification in D1 follows from it, and this SPEC introduces no second rule.

Five files take one edit from each feature, so the rule has to keep them off the same line — and on
**three lines it cannot**, because the number and the prose entry sit in the same sentence. The shared
set was derived rather than sampled: every D1 class 1 line, plus M2's line, was read for a numeral that
**moves when a curated on-demand skill lands**. The corpus total and the curated total move; the
shortcut-catalog figures (the row total, the verb-first doorways, the `repurpose` skills) and the
pipeline-phase figure do not, so a line carrying only those is not shared.

| File | feature-012's line | This feature's line | Same line? |
|---|---|---|---|
| `README.md` | the count captions at `:13` and `:45` | the on-demand list entry inside `:132–:152` | No — the fenced block carries only a shortcut figure, which does not move |
| `docs/aid-methodology.md` | the count sentences at `:100` and `:102` — **not** `:128`, whose figures are the shortcut catalog's and do not move (D1 class 3) | the table A row, the §4 row, the `G1` node, the two prose lists, the deep-dive | No — `:408`'s only numeral is the shortcut figure |
| `docs/repository-structure.md` | the numerals in `:73` — both the corpus total and the curated total move | the skill name in the same sentence at `:73` | **Yes, `:73`** |
| `docs/glossary.md` | the curated total inside `:54` | the family-list name on `:54`, and the new `**aid-graph:**` entry beside `:60` | **Yes, `:54`** — `:60` is this feature's alone |
| `docs/diagram-content-reference.md` | the totals and their decomposition at `:24`, `:102`, `:107`, `:109` (Open Item 6) | M2's trigger-row correction at `:24` | **Yes, `:24`** |

**`/aid-detail` must not parallelise the two edits to any of those three lines** — each is one sentence
holding a figure only 012 may move and a name only this feature may add.

`/aid-detail` should sequence feature-012's count edit **first**: the doc-count guard and
`check-skill-counts.mjs` are the cheaper gates and give a clean mechanical signal before prose lands
on top of them. That is the same ordering feature-012's L3 recommends, reached independently here.

**Two boundaries the rule does not settle, and both are recorded rather than assumed.** The
`SKILL.md` `## References` section is contested between feature-010 and feature-012 (feature-010 Open
Item 6, feature-012 Open Item 1) and is **neither feature's here** — this feature authors no skill
content. And `kb.html`'s stale count is explicitly **not** this feature's by feature-012's own
**Open Item 6**; D1 class 4 records the exclusion and its owner.

**Where feature-009's routed assertions go, decided rather than deferred.** feature-009 Open Item 3
(its `:645–:646`) leaves the two-surface parity assertions "in whichever suite feature-008 or
feature-013 places them". They belong in **feature-008's** suite, and the reason is mechanical rather
than a preference: the pairing asserts the canvas's **emitted DOM** and a single shared projection
against the table's, which requires a rendered page and the store — feature-008's `GC*` surface — while
this suite reads the rendered *repository* and holds no browser by design. Placing them here would
force a browser into a canonical suite, which `test-landscape.md:310`'s routing of rendered-page
verification to the separate visual gate forbids. Recorded as Open Item 2 with feature-008 as the
implementing owner.

### Migration Plan

Nothing changes shape. Every row adds a name to a list or a row to a table, with one exception: M2
corrects a clause in a maintenance contract.

| # | Change | Blast radius | Verification |
|---|---|---|---|
| M1 | Roster entries across every D1 class 1 surface — `README.md`, `docs/aid-methodology.md` (six sites), `docs/repository-structure.md`, `docs/glossary.md` (two sites) | User-facing documentation | **GR07**, **GR08**; both ship gates |
| M2 | `docs/diagram-content-reference.md:24`'s skill-add trigger row corrected to distinguish a catalog/shortcut add from a curated on-demand add — **in the same change as M1**, per `:14–:15` | The diagram maintenance contract | Read-back (**AC-T3**). No mechanical guard exists for this file's *content* claims, which is why the maintenance rule is a rule |
| M3 | `node site/scripts/sync-docs.mjs` | `site/src/content/docs/concepts/methodology.md` | `git diff --stat -- site/src/content/docs/` shows that file and nothing else; **GR09**; and the ship gate's `prebuild` chain re-running clean is the fixed point |
| M4 | New `tests/canonical/test-graph-skill-registration.sh` (L1) | Additive. Discovered by the glob — no runner and no workflow edit | The suite itself. `tests/coverage-parity.sh` reports it as a net-add and fails only on removals (`:503`), so it cannot trip that gate |
| M5 | Knowledge Base updates — every D3 row whose *Fires* cell reads **Always**, which includes the `technology-stack.md` rows and `infrastructure.md`'s procedure half | The Knowledge Base | The KB's own review gate. `check-skill-counts.mjs` guards **counts only**; nothing reads a capability table or a script-area list for completeness, so **AC-T8** is the check |
| M6 | *Conditional* — the three D3 rows whose *Fires* cell names a condition: `quality-gates.md`, `infrastructure.md` § *CI/CD Pipeline* (feature-002 D4b) and `domain-glossary.md` § *Concept Spine* (feature-001's judgment) | The Knowledge Base | Same. For the two feature-002/001 rows the source of the content is that feature's report, never this SPEC |

M1 and M2 are inseparable, and so are M1 and M3. `/aid-detail` must schedule feature-012's count edit
before M1 (L2), and must not parallelise the two edits to any of L2's **three shared lines** —
`docs/repository-structure.md:73`, `docs/glossary.md:54` and `docs/diagram-content-reference.md:24`.

### Tests

All assertions carry the prefix **`GR`** (graph registration), unused elsewhere in this work, and they
live in the one suite L1 describes.

**None of them is a pin, and none of them is vacuous — the second was the harder property.** No
assertion below is an invariance claim whose subject is "nothing changed". But GR02, GR03, GR04 and
GR05(a) are universals quantified over a set **derived from a canonical directory this SPEC cannot
verify** (see the § *What this SPEC cannot verify* note), and a universal over the empty set is *true*
— so as first drafted each of them passed in a tree where nothing had been built. They are made
non-vacuous **explicitly, rather than by trusting another row to fail first**: **GR01(b)** is the
suite's preflight, asserting each canonical root and the profile set present and non-empty before any
set derived from them is compared, and **GR05(b)** adds its own file-level presence clause because a
non-empty script area does not imply the one file it names. **GR09** carried the same defect in a
different shape — it was *pinned on* that canonical directory existing, which is a skip rather than an
assertion — and now rests on the preflight instead. **GR06** is the row that reads like a pin, a
universal negative; its precondition is on the *rendered* trees, a different set, so it keeps its own.
With those in place a **do-nothing** implementation fails, by name, at the preflight.

**Each also has to survive a fully populated but wrong implementation, and where a row's reach ends
that row says so** rather than claiming a coverage it does not have. The third column carries both:
the wrong implementation the assertion catches, and the residual it does not. **Every row but GR06
names a residual in its own cell**; GR06 names none and none is known, because it is a negative over
exactly the one artifact feature-006 withdrew.

**Every expectation is derived from an independent source** — `canonical/`, `profiles/*.toml`, or the
sibling skill's own placement — and never from a neighbouring field of the artifact being checked.
GR04 is partly record-internal and says so in its own row instead of presenting the whole as
independent.

| ID | Assertion | The wrong implementation it catches |
|---|---|---|
| **GR01** | **The preflight, and the reason every set comparison below is non-vacuous.** (a) `canonical/skills/aid-graph/SKILL.md` exists and its frontmatter declares all four of `name`, `description`, `allowed-tools`, `argument-hint` — the keys `module-map.md:312–:314` names as the convention and feature-010's ownership seam (its `:891`) assigns. (b) `canonical/skills/aid-graph/`, `canonical/aid/scripts/graph/` and the profile set `run_generator.py:24` enumerates are each **present and non-empty**, asserted **before** any set derived from them is compared | A skill authored with a partial frontmatter block. The *file's* absence is already a loud generator failure (`render.py:549–551`; feature-012 D2 P3), so (a) earns its place on the **keys**, which nothing else reads. (b) earns its place on the *empty set*: without it GR02, GR03, GR04 and GR05(a) each hold trivially in a tree where the canonical source was never authored — exactly the tree this suite exists to fail in. **Residual:** it asserts the keys' presence, not their content — `description`'s quality is feature-010's and is a Feature Flow step 6 read-back, because "reads as a complete summary" is not mechanically decidable |
| **GR02** | For **every** profile the generator enumerates — `sorted(profiles_dir.glob('*.toml'))` at `run_generator.py:24`, each profile's skills root taken from its own `root_dir` key — the set of paths under `profiles/<p>/<root_dir>/skills/aid-graph/`, relative to that directory, **equals** the set derived from `canonical/skills/aid-graph/` under the generator's own emission rules: `SKILL.md`, `references/*.md`, and direct children of `scripts/` (`render.py:536–609`) | A **partial** render — one `references/*.md` emitted and another not; a file hand-added to one tree; a canonical `README.md` shipping (D1 decision 2); a nested `scripts/` subdirectory silently dropped by feature-012 D2's P5. A **set** comparison, not a count, so adding a state file later cannot leave it trivially true, and non-empty by GR01(b) so it cannot be satisfied by ∅ = ∅. The expectation is derived from `canonical/` — never from the manifest and never from a second rendered tree, per `tech-debt.md:232–:234`. **Residual:** the *set*, not the bytes — content is GR04's `sha256` clause and feature-012's CR06 |
| **GR03** | The same canonically-derived set, under the repo-root `.claude/skills/aid-graph/`, **equals** it — the same comparison GR02 makes per profile, resting on the same GR01(b) precondition | A skipped dogfood resync, **and** a file in the dogfood tree that no canonical source explains. feature-012's Feature Flow step 8 is a stated manual step that no repository script automates, which makes it the step most likely to be missed. Equality rather than containment because equality is the property that tree already owes: `test-dogfood-byte-identity.sh:4–:21` walks it forward, in reverse, **and** as a repo-orphan sweep. Ground truth is `canonical/`, **not** `profiles/claude-code/`: anchoring the dogfood tree to the render would be the sibling-copy comparison the invariant-anchoring rule forbids. **Residual:** as GR02's — the set, not the bytes |
| **GR04** | For every profile and every canonical path GR02 derives, that profile's `emission-manifest.jsonl` carries **exactly one** record whose `src` is that path — unnormalised, since the skills branch records `src` verbatim (`render.py:569`) — and the file at that record's `dst` exists under `profiles/<p>/` carrying that record's `sha256` | A canonical file with **no** manifest record (the L4 class: a manifest that describes a set it does not cover), and a duplicate record. **Half of this assertion is record-internal and saying so is the point:** the `sha256`-versus-`dst` clause catches a record naming an absent or since-edited file. **Residual:** it does **not** catch a consistent record describing wrongly-rendered bytes. The independent part is the quantifier, which comes from `canonical/`. Content is feature-012's CR06, and GR05 is where a content property is actually decided here |
| **GR05** | (a) For every profile, the set of files under `<root_dir>/aid/scripts/graph/` **equals** the set `canonical/aid/scripts/graph/` yields under the generator's own emission rules for that tree — the `translate="none"` branch's whole-tree `rglob`, minus dot-prefixed names and its excluded directories (`render.py:611–:627`) — non-empty by GR01(b). (b) `coverage-predicate.mjs`'s rendered bytes equal its canonical bytes in every profile and in the dogfood tree, **and** the canonical file carries none of feature-012 D3's substitution triggers on a non-comment line — both asserted only after `canonical/aid/scripts/graph/coverage-predicate.mjs` is confirmed present, since GR01(b)'s non-empty directory does not imply this file | A profile whose copy of the **one file executed in two runtimes** has been silently rewritten — imported by the Node-side detector and inlined into the browser page (feature-007 `:1551–:1556`), so a divergent copy makes the two runtimes disagree while the render-drift gate stays green (feature-002 Open Item 9). **Clause (b)'s second half is why this is sound rather than lucky:** `.mjs` is transformed class (`render.py:77–79`), so byte-identity holds **iff** no in-scope trigger is present. Asserting the consequent alone — which the pre-decision draft did — asserts a conditional guarantee unconditionally. With both, a file that later gains a trigger fails **loudly** and the guarantee is weakened deliberately instead of by drift. **Residual:** `detect-kb-gaps.mjs` is covered by (a) only — it is Node-side alone, and no verified basis exists for a byte claim about a file that does not yet exist; (a) decides the file *set*, and no assertion here decides the bytes of any script but the coverage predicate |
| **GR06** | No `package.json` exists under any rendered `aid/templates/knowledge-graph/` directory, in any profile tree or the dogfood tree — asserted only after that directory is confirmed present in each | Reinstating the ESM marker feature-006 `:1083–:1085` withdrew with the `.mjs` repoint. feature-012's L2 states the consequence: a manifest inside a *template* directory renders into every adopter's install, where their own tooling could read it. The presence precondition is what stops the negative passing in a tree where the template set never shipped |
| **GR07** | **(a) is quantified over sites, at D1 class 1's own granularity — one clause per site that table names, not one per file.** For each class 1 site, `aid-graph` occupies a **peer** of the unit the sibling occupies there: a row in the table holding `docs/aid-methodology.md:108`; a row in the table holding `:393`; a node inside the `subgraph G1` block holding `:49`; a member of the same inline list, on the same line, at `:408`, at `:432`, at `docs/glossary.md:54` and at `docs/repository-structure.md:73`; a `####` subsection under the same `###` parent as `:481` (`### Knowledge Base Maintenance`, `:428`); a top-level `**aid-graph:**` entry beside `docs/glossary.md:60`'s; a line inside the fenced block holding `README.md:146`. Each unit is located **by the sibling's own occurrence**, never by a line number written into the suite. **(b) is quantified over files, and says so:** the set of hand-authored documentation files containing `aid-summarize` — `README.md` plus `docs/*.md`, excluding everything under `site/` — **equals** the file set of D1 class 1 ∪ class 2, and any file outside both fails **by name** | (a) catches a do-nothing implementation and, because it is per site, every *partial* one — the failure a file-granular version missed, where editing `docs/aid-methodology.md`'s table A alone satisfied a whole-file check that had to stand for every class 1 site in that document, and `docs/glossary.md`'s `:60` entry alone stood for `:54` as well. (b) catches the failure this SPEC cannot otherwise prevent: a documentation surface added **after** this SPEC was written, which would otherwise be missed silently forever. The clamp shape is the merge's own at `gen-reference.test.mjs:188–:190`, which fails by name rather than reporting a whole-corpus diff. Both are set comparisons; no numeral appears. **Residual:** a class 1 surface *mis-declared* as class 2 passes both clauses — stated rather than left. That is a review property, and D1 makes it disprovable from the SPEC alone by justifying each class 2 site individually rather than listing them |
| **GR08** | Placement **beyond peer-presence**, at the sites where a stronger property than GR07(a)'s is decidable from the text: in `docs/aid-methodology.md` table A **and** in its §4 table, the `aid-graph` row's `Group` cell equals the `aid-summarize` row's; in `docs/glossary.md`, `aid-graph`'s entry follows the shape the sibling's `:60` entry uses rather than sitting inside another entry's body | The fully-populated-but-wrong implementation that GR07(a) still admits: a row placed in the right table under the wrong group, and a glossary definition folded into a neighbour. Anchored to **FR-7's sibling claim**, not to a group name this SPEC picks — so if the sibling is ever regrouped, the assertion follows it instead of contradicting it. **Residual:** the methodology deep-dive is deliberately not asserted beyond GR07(a)'s peer-subsection check — prose *presence* is checkable and prose *adequacy* is not, so the subsection's content is a **Feature Flow step 3** read-back, at the step that writes it, and no assertion here claims otherwise |
| **GR09** | Resting on GR01(b) rather than skipping when canonical is absent: `site/src/content/docs/skills/aid-graph.md` exists; `site/src/content/docs/skills/index.md` lists `aid-graph` under the **same `##` group heading** as `aid-summarize`; and `site/src/content/docs/concepts/methodology.md` passes the **same site-granular check GR07(a) runs on `docs/aid-methodology.md`**, since `sync-docs.mjs` copies that document whole and rewrites only links and images | A generator that was never run, or whose output was never committed — the first two. The third catches the two failure modes that leave the site showing the previous toolkit: a source edit with no `sync-docs.mjs` run, and a hand-edit of the synced copy. Site-granular rather than "names it", because a whole-file presence check on the synced copy passes when only one of the source's sites was edited and synced. `reference/skills.md` is **absent from this row on purpose** — it renders no per-skill entry (D1 class 4), so asserting one there would fail against a correct implementation. **Residual:** this asserts **presence in committed output**, not that the generators are fixed points; the fixed point is the ship gate's `npm run build`, and the roster guards are feature-012's CR09 |

### Open Items

Each names its owner and its **Q26 class** — a **mechanism** item changes a contract, a field, an id
grammar, a predicate, an interface, an exit code, an emitted value or an acceptance criterion's truth;
an **editorial** item is a real defect collected onto STATE.md's § Editorial queue and fixed in the
Q24 item-9 batched pass. An item that cannot be classified confidently is treated as **mechanism**.
**Features 001–007 are frozen (Q26 § Freeze)**, so an item against one of them needs an explicit owner
decision rather than an automatic reopen. None blocks this feature's implementation.

1. **The 012/013 seam is stated against a document that is still moving.** feature-012 is at an open
   gate as this SPEC is written and its previous pass changed three claims, so L2 quotes its L3 row as
   read on disk this session and states the seam as a **rule** rather than as a mirrored table — a
   table claiming byte-identity with a moving document is a promise nothing keeps. If its next pass
   changes that row, L2's rule and D1's four-class split must be re-checked against it, not assumed.
   **Owner: feature-012** (concurrent — **every citation to it in this SPEC is by section, Open Item
   number or row name, and none is by line**, for the same reason; the practice was made to match this
   claim rather than the claim softened) **and this feature** at its next touch. **Q26 class:
   mechanism** — the seam decides which feature edits which line.
2. **The two-surface parity assertions belong in feature-008's suite.** Decided in L2 with the
   mechanical reason: they need a rendered page and the store, which this suite has neither of and
   must not acquire. Nothing is owed to this feature; feature-008 implements them. **Owner:
   feature-008** (settled at B-, not frozen — no automatic reopen). **Q26 class: mechanism** — it
   fixes where a shared assertion runs. *(Inbound: feature-009 Open Item 3, discharged as a decision.)*
3. **Three Knowledge Base authoring-convention questions are routed here and none is decidable
   without an owner decision.** feature-005 routes `**Aliases:**` in the shipped glossary template
   (its Open Item 6, `:1594`), a `tested-components:` frontmatter field (Open Item 13(b), `:1647`) and
   anchored `see_also:` as a stated convention (Open Item 15, `:1663`) here as "KB authoring-convention
   and template content", each explicitly **with the work owner** on whether the capability is wanted.
   This feature declines to decide any unilaterally, and the ground is not deference: each widens a
   **shipped template's contract** for every adopter, and FR-8a forbids relying on a convention no
   template defines — so adding one is a methodology change, not a documentation edit. If any is
   wanted, the template edit is this feature's and the map row that consumes it stays feature-005's or
   feature-004's. **Owner: the work owner**, with **feature-005**. **Q26 class: mechanism** — each adds
   a marker or a field to a shipped schema.
4. **feature-006 Open Item 9's Knowledge Base half.** Whether the Knowledge Base should cover
   `site/src/**` at the grain the gap ledger will ask for, or whether a coarser `sources:` entry should
   cover it, is an owner decision (its `:1307`). If the answer is a Knowledge Base authoring change it
   lands with D3; nothing is owed until then. **Owner: the work owner**, with **feature-006**.
   **Q26 class: mechanism** — it changes what the ledger reports as a gap.
5. **The `works/` script area is absent from all three enumerations this feature edits, and the
   correction is deliberately not folded in.** Verified this session: `canonical/aid/scripts/` holds
   `config`, `connectors`, `execute`, `housekeep`, `kb`, `migrate`, `release`, `summarize` **and
   `works`**, while `module-map.md:186–:196`, `module-map.md:87` and `capability-inventory.md:260` each
   enumerate the set without `works`. D3 adds `graph` at all three sites; adding `works` in the same
   pass would be an **unrequested widening of a targeted Knowledge Base edit**, which is the
   scope-fidelity failure targeted updates exist to prevent, so it is named rather than performed.
   **Owner: the work owner**, or a `/aid-update-kb` delta. **Q26 class: editorial** — a missing row in
   a descriptive table changes no contract and no criterion's truth.
6. **`docs/diagram-content-reference.md` states the skill total and its composition as literals**, at
   `:24` and again at `:102`, `:107` and `:109`. Those are **count** surfaces and therefore
   feature-012's, and they are reachable by `check-skill-counts.mjs` because `docs` is an
   `INCLUDE_TREES` member (`:160–:165`). Recorded only because M2 edits `:24` for a different reason,
   so `/aid-detail` must not produce two tasks editing that line — it is **L2's third shared line**.
   **Owner: feature-012.**
   **Q26 class: mechanism** — it decides which task edits which line.
7. **The diagram contract's own `S1` description has drifted from the diagram, and this feature adds a
   node to the part that drifted.** `docs/diagram-content-reference.md:126–:127` says the methodology
   §1 flow shows "phase groups `G1 Prepare · G2 Describe → Define · G3 Map · G4 Execute · G5 Deliver`".
   On disk that diagram declares `GE` *Entry*, `GS` *Support*, `G1` **Knowledge Base Maintenance**,
   `G2` *Definition* and `G4` *Execution* (`docs/aid-methodology.md:37–:61`) — no `G3`, no `G5`, and
   `G1` is a **group**, not a stage. D1 class 1 puts the new node in that `G1`, so a contributor
   following the contract would look for a group the diagram no longer has. Pre-existing and not
   caused by this work, and **deliberately not folded into M2**, which corrects the trigger row at
   `:24` for a stated reason and must not become an open-ended repair of the file. **Owner: the work
   owner**, or a documentation-maintenance pass. **Q26 class: editorial** — the contract describes a
   diagram wrongly; no mechanism and no criterion's truth moves.

**`canonical/skills/aid-graph/README.md` is declined as a documentation surface** (feature-012 Open
Item 1's conditional half), with the evidence in **D1 decision 2** and not restated here; **GR02**
fails if one ever ships, which makes the decline a check.

**A CI lane is declined rather than deferred**, with its grounds and its reversal condition in D2, and
with feature-011 Open Item 2's precondition — a recorded skip rather than an absorbed one — stated as
necessary but not sufficient.

**Every inbound disposition is in the § Source table and is not restated here.** A second list would
be the sibling copy `tech-debt.md:232–:234` forbids, and it is the exact drift this feature exists to
prevent.

### Figures

**No quantity in this SPEC is a measurement.** Every quantity above is one of three things, each
identifiable where it appears.

A **value read from a cited artifact on disk**, at the tree the claim is about: every `:N` line
citation, `.aid/settings.yml:6`'s `B-`, the merge commit `00194684`, and every passage quoted verbatim
from a cited file — feature-012's L3 row, `test-landscape.md`'s known-gap row,
`docs/aid-methodology.md:730`'s comparison sentence, and the coverage-parity lane's hang note.

A **set cited rather than counted**: the profile set is "every profile `run_generator.py:24`
enumerates from `profiles/*.toml`", never a numeral; the skill count is
`tests/canonical/test-doc-counts.sh:44`'s `find` derivation; the canonical-suite figure is
`ls tests/canonical/test-*.sh | wc -l`, stated as the live value at ship time and **nowhere given a
value here**, including where D3 observes that the documents disagree with it; the documentation
surfaces are D1's four declared classes with **GR07's** clamp rather than a count of surfaces; the
shipped file set is derived from `canonical/skills/aid-graph/` under the generator's emission rules;
the suites this work adds are whatever each feature's own § Tests section declares; and the assertions
of every sibling suite are cited by their id prefixes — `GL`, `GV`, `GC`, `TV`, `SR`, `PV`, `CR` —
never by their cardinalities.

And **an enumeration made on the spot and reproducible from the section that states it** — feature-006's
class, adopted here — covering the remaining counts: the change log's **ten** superseded claims, each
named in the same row; D1's four classes and its two forced decisions; the two ship-gate commands;
D2's three grounds for declining a lane; the four `SKILL.md` frontmatter keys (a **contract** count:
`module-map.md:312–:314` names exactly those, and changing the set is a convention change by design);
the three sites GR08 checks beyond GR07(a); the five files L2 splits and the three lines inside them
that both features must edit; the nine script-area directories Open Item 5 lists; this SPEC's nine
`GR` assertions, its nine `AC-T` criteria and its seven Open Items.

**Outside those three classes this SPEC produces no quantity at all** — no node count, no bench size,
no frame rate, no payload, no line count of any document including its own, no skill total, no suite
total, no roster length and no severity tally. The withdrawn delivery-001 bench and the withdrawn A-5
Knowledge Base figure appear **nowhere**, in any form, not even to be retired — quoting a figure in
order to strike it is how the last one kept reappearing (Q20 (A-5 figure); Q23 instance 2). Two kinds
of statement that could be mistaken for measurements are neither: **line numbers** are locations,
disproved by opening the file rather than by re-measuring; and the pass/fail and presence statuses this
SPEC rests universal negatives on — that `tests/run-all.sh` references `site/` nowhere, that no
canonical suite invokes `vitest`, that `.aid/dashboard/kb.html` does not exist, that `.aid/settings.yml`
carries no `review:` or `summary:` block, that `README.md`'s `R1` diagram contains no on-demand
Knowledge Base skill, that `docs/install.md` names no individual skill, that
`site/src/content/docs/reference/skills.md` names `aid-summarize` nowhere and renders no per-skill
entry, that `canonical/skills/aid-graph/` and `canonical/aid/scripts/graph/` do not yet exist, that
`canonical/aid/templates/graph/relation-vocabulary.yml` reaches no profile tree, manifest or dogfood
tree, and that the methodology §1 flow declares no `G3` and no `G5` — are **statuses re-checkable with
one command each**, stated without the counts those commands printed. Each was reached by reading
**every** occurrence rather than by counting hits or truncating a search (Q23).
