# /aid-graph Skill Runtime And Quality Gate

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-30 | **Authored fresh against the amended REQUIREMENTS.md, the frozen 001–007 spine and the passed 008/009 (STATE.md Q24 item 7, Q26 § Fresh authoring); it supersedes the 2026-07-28 pre-decision draft in whole rather than editing it.** Nothing was edited into shape, because a clause keyed on a superseded model stays grammatical while becoming false — this work's founding defect class (Q17, Q21). **The substantive change is the retention correction (STATE.md Q25 item 1): DONE deletes `graph-kb-gaps.md` with every other ledger, and `--reset` does not preserve it.** The draft retained it on the stated authority of "feature-006 §D7"; that authority cited feature-006's *previous* revision, whose retention carve-out feature-006 **withdrew** (Q22), so the citation was expired rather than wrong when made — the Q20 (loader sync) class. Q8 lifted ledger retention out of this work as its own methodology item, and a skill-local exemption is precisely the workaround Q8 removed — sized at D6. The consequence is stated rather than hidden (D6): until D-6 lands, `Fixed` and `Recurred` are unreachable and every run is cycle 1; what survives is `kb_gaps` plus the printed command, which regenerates the ledger by a **full re-run** and not by a read-back. **Further clauses of the draft that are withdrawn rather than corrected, each because the model moved or the clause was wrong on disk:** the staleness digest covered three inputs where FR-11 now lists six, and its `SRC` term omitted the media stream (feature-004 Open Item 7); it stated the digest as a scalar with no component attribution; its preflight **refused** on a missing `external-sources.md`, which contradicts AC-19 and feature-004's own zero-rows-is-not-an-error rule, and is now a notice; it re-assigned severities feature-003's gated validator table already fixes; it named the artifact `.aid/knowledge/graph.html` unconditionally where the view's presence is now a decidable install predicate; it had `--grade` persist to `.aid/settings.yml`, which FR-11 input 4 makes a staleness input, so a grade-floor edit would have forced an unrelated regeneration; its DONE claimed to print feature-006's routing block, which feature-006's own GAP-REPORT prints; and its FIX chained straight back to VALIDATE, which for a generated artifact would have meant hand-editing generated output. **Discharges feature-003 Open Items 2, 4 and 14, feature-004 Open Item 7, feature-005 Open Items 10, 12 and 14, and feature-006 Open Item 3**; adopts feature-002's recommendation posture on NFR-8's comparand without amending a requirement (Open Item 1). § Figures states the no-measurement rule and makes it true, this row included | /aid-specify |
| 2026-07-30 | **First review cycle closed — every `[MEDIUM]` row the gate raised, and each one's class with it.** **D5's human-gate authority is re-attributed**: §5.9's Decision paragraph grades **`kb.html`** behind that gate, contrasting the sibling artifact, so this view's authority is §6.1's Rationale — now cited in § Source and quoted at D5, where the substituted clause was. **D4 gains `V-ST`**, the row for `validate-html-output.sh`'s unlabelled `[Structural checks]` block, without which the script could exit `1` with no ledger row and the run print a grade over it; the closure rule is stated with it — the row set is closed over each validator's `FAIL` flag, not over its ided checks. **SR03's gap-ledger precondition is qualified as pre-deletion**, as SR12's already was, and § Tests states the rule for every path D6 deletes. **The § State Machines schematic is deleted** — the only multi-line block a line-level diff against the draft still found carried verbatim, and it drew the FIX-to-VALIDATE edge difference 5 withdraws — leaving the state table as the sole transition set, which is the only form that cannot drift from it. (What that diff otherwise returns is section and column headers plus single facts re-verified this cycle: the resolver invocation, the `graph_generated_at` row, the `FIRST_RUN` verdict.) Prose was cut where a fix would otherwise have added it — this cell, § Description's close, the closing arguments of D4's emitted-range and check-inventory paragraphs, and D4's duplicated `AUTO_POOL` argument, which § The five scripts already carries. **Re-anchored in the same pass, against `origin/master` merged mid-cycle:** `module-map.md` § Conventions and its never-edit-a-render rule, and `test-landscape.md`'s prompt-driven-state-machine row (its `:29` glob rule did not move); every anchor was re-found by its text, not by offset. **The resolved runtime floor moved with it** — `.aid/settings.yml` now carries `minimum_grade: B-`, so D1 states `B-`, D4's "any row is gating" is re-grounded on the emitted range's `D` and `C` bands rather than on an `A+` floor, D4's advisory argument no longer rests on this project's setting at all, and Open Item 10's drift is now the key's shape **and** its value. Q27's `B-` and the skill's runtime floor are different floors that happen to read the same value; neither derives from the other. The gate's remaining rows are `[LOW]`/`[MINOR]` and defer to the Q24 item-9 pass under Q27's floor; none is touched here | /aid-specify |

## Source

Line citations of the form `:N` are into the cited feature's own `SPEC.md`, read 2026-07-30. Citations
into a script, template or Knowledge Base document name that file and were read on disk the same day —
and always the **canonical** copy, never a profile render, because the two are different artifacts and
only one carries these line numbers (Q23). Unqualified `state-*.md` names are under
`canonical/skills/aid-summarize/references/`; unqualified `summarize-preflight.sh`, `stale-check.sh`,
`grade-summary.sh`, `assemble.sh`, `validate-*` and `package.json` are under
`canonical/aid/scripts/summarize/`.

- REQUIREMENTS.md §5.5 — **FR-7** (a standalone, on-demand skill, sibling of `/aid-summarize`, never
  auto-triggered), **FR-8** (preflight gates on a completed, approved Knowledge Base), **FR-8a**
  (genericity: any project with an approved AID Knowledge Base; graceful degradation where a convention
  is absent), **FR-9** / **FR-9a** (both artifacts land in `.aid/knowledge/`; the `## Coverage notes`
  section on every emitting run), **FR-10** (read-only with respect to Knowledge Base content),
  **FR-11** (idempotence, `--reset`, and the staleness input **list** — authoritative, never its
  cardinality — including **input 6, the tool itself**), **FR-12** (reuse at the script layer)
- REQUIREMENTS.md §5.8 — **FR-30** / **FR-31** / **FR-31a** (the two passes and the bounded agent pass
  this runtime dispatches), **FR-32** *as re-keyed* (byte-identity across runs where **all of FR-11's
  staleness inputs** are unchanged)
- REQUIREMENTS.md §5.9 — **FR-25** (reports, never gates), **FR-26** / **FR-27** (the gap ledger and its
  routing, both feature-006's), **FR-28** (the gate covers this skill's own artifacts only) with its
  Rationale and its Decision paragraph (separate skill, shared scripts; `relationships.md` grades as
  **data**, while that contrast's visual-fidelity half is about **`kb.html`** and not about this view)
- REQUIREMENTS.md §6.1 — **NFR-8** (the ceiling is measured and documented; **the warning is this
  feature's**), **its Rationale** ("leaving the human visual gate to judge whether the graph is legible"
  — **D5's authority for `G1`**), and **NFR-1**/**NFR-4**/**NFR-5**/**NFR-6**/**NFR-7** as things the
  gate *checks* through other features' surfaces and never re-derives
- REQUIREMENTS.md §7 — **C-2** (canonical authoring, rendered per profile), **C-3** (manifest lockstep),
  **C-4** (reuse, never fork), **C-5** *as extended* (Node ≥ 20; Playwright degrades gracefully, and may
  be provisioned and still unable to draw), **C-6** (the 7-column ledger schema at the mandated
  location), **C-7**
- REQUIREMENTS.md §8 — **A-2**, **A-4**, **A-6** (self-built fixtures), **A-5** (**void**; no bench
  figure is stated anywhere and none is stated here), **D-4**, **D-5**, **D-6**
- REQUIREMENTS.md §9 — **AC-11**, **AC-12**, **AC-13**, **AC-16a**, **AC-17**, **AC-20**; and **AC-5**,
  **AC-6**, **AC-14**, **AC-19** as criteria this runtime enables and does not own
- REQUIREMENTS.md §4 Out of Scope — no KB mutation, no gating on completeness, no merge into
  `/aid-summarize`, **no automatic ticket creation**, no dashboard reachability
- STATE.md `## Cross-phase Q&A` — **Q8** (ledger retention is its own methodology item, not a local
  workaround), **Q17** with **Q19** and **Q21** (proxy-keyed clauses; the count-that-**is**-the-contract
  exemption; a prefix is right about **where an id comes from** and wrong about **what class a node
  belongs to**), **Q18 ruling 3**, **Q19** (the extra-row ordering defect), **Q20 (loader sync)** (an
  item routed into a gated SPEC is a pending reopen), **Q20 (A-5 figure)** (requirements state
  derivations, research states figures; read every occurrence), **Q21**, **Q23**, **Q25** (item 1 is
  this SPEC's correction), **Q26** (fresh authoring; mechanism versus editorial; the freeze), **Q27**
  (this work's SPEC-gate floor — **not** the floor this skill resolves at runtime, D1)
- **feature-003 — the artifact this runtime assembles.** The ten-column contract (D1, :239), the `Kind`
  enum (D1a, :334), the id grammars (D2, :387), row ordering and the class-0 prefix (D7, :1284) with
  AC-5's two extractions (:1357–:1362), `## Coverage notes`' shape and its rendered labels (D7a, :1370,
  the skeleton at :1399–:1403), **the extra-row total order** (D7a-1, :1426, its six rules
  :1437–:1449), the class-0 extraction (D7b, :1550), the emitted frontmatter with **the three
  generator-written scalars reserved for siblings and placed outside the byte-identity boundary** (D8,
  :1579, :1637–:1647), the loader surface (D9, :1662), and the validator table whose **`Ledger
  severity` column this feature adopts rather than re-assigns** (:1771–:1787), emitting rubric tags and
  not severities (:1760–:1763) on the `0`/`1`/`2` linter scheme (:1757–:1759)
- **feature-004 — the enumerator this runtime drives.** The four streams plus `coverage.tsv` (Feature
  Flow, :1930–:1938) with its exit codes (:2036), the git prerequisite (:1941–:1943), the ignore-list
  three-state probe and **its ownership table, which leaves this feature only the settings-schema
  change** (D4a, :1583–:1587, :1596–:1598), the coverage contribution's five fields and its exclusion
  **keys** (D7, :1750, :1761–:1767), and **Open Item 7's three obligations on this feature**
  (:2208–:2217)
- **feature-005 — the extraction this runtime sequences.** The producer map for every node kind
  (:226–:239), **Pass 2's two dispatch shapes and their empty tool sets** (D6 part 1, :887–:938, the
  table at :898–:901), the `pass-2-unavailable` degradation (:988–:997), the flow and its exit codes
  (:1281–:1373, :1370–:1371), **step 15, which renders the coverage-notes section this feature
  assembles** (:1361–:1365), the `kb-coverage.tsv` contribution (:1026–:1028), and Open Items 10
  (:1618), 12 (:1631), 14 (:1651) and 16 (:1666)
- **feature-006 — the gap ledger, and the obligation this SPEC discharges.** The two ledger scopes and
  their lifecycle (D7, :774–:777), **the withdrawn retention carve-out** (:782–:791) with the interim
  behaviour (:803–:823) and the correctly-sized unadopted stash (:825–:836), **the correction routed to
  this feature** (:838–:846, Open Item 3 :1209), the state's flow including the routing block it prints
  itself (:848–:883, :911–:925), the four structural FR-25 mechanisms (:896–:901), the `SKILL.md` seam
  (L1, :968–:976), the detector's interface (:1030–:1041), AC-G6 (:168–:171), and GL07/GL08/GL09/GL10/
  GL18/GL20 (:1119–:1132)
- **feature-007 — the view this runtime renders and gates.** The load sequence with **store creation and
  preference detection inside the shell** (Feature Flow step 4, :1500–:1507) and the mount order whose
  canvas half may return nothing (step 6, :1510–:1515), **exactly two live regions** (:1526–:1531), the
  file tree (:1539–:1552), **the reuse table naming `assemble.sh`'s three real flags** (:1561–:1571),
  packaging and the entry point with the **runtime-prerequisite emission** (:1577–:1609), **§ Validator
  surface — which check binds which surface, and that the canvas carries only a text alternative**
  (:1611–:1631), the store surface and the seven consumer rules (:1638–:1697), § Accessibility
  (:1763–:1779), **GV23** (:1817), and Open Items 4 (:1884), 11 (:1974) and 13 (:1985–:1990)
- **feature-008** (passed) — `mode: 'unavailable'` and the static sentence when no WebGL context exists
  (:336, AC-S10 :235, GC19 :655), and its boundary row naming **this feature** as the emitter of NFR-8's
  warning (:269)
- **feature-009** (passed) — the peer table view this run must leave usable with no drawing context; its
  boundary section (:191) names what it does not own. That it mounts **first and unconditionally** is
  feature-007's contract, not this one's (:1510–:1515)
- **feature-002** — Stage 2b (:348), **D5, which owns the ceiling and states the comparand problem
  without resolving it** (:723, :740–:743, Open Item 6 :1249–:1255), and **the rule that no permanent
  artifact and no test may cite its report** (:1060–:1067)
- **feature-011** (validator parameterisation) and **feature-012** (canonical registration) were authored
  alongside this SPEC and are in their own gates, so **neither is cited by line** — a gate may still move
  their lines. They are referred to **by contract name only**: the validator-reuse parameterisation, and
  the render / manifest / count / registration surfaces. This SPEC specifies neither, and where this
  runtime meets theirs the obligation is stated and a coordination Open Item names the owner (Open Items
  5, 6, 11)

**Dependency position.** This feature spans the run: it invokes feature-004 and feature-005, assembles
what feature-003 and feature-006 emit, renders what feature-007 (with 008 and 009) builds, and grades all
of it. It is blocked by none of them for *specification* and by all of them for *delivery*. It depends on
the canonical-registration feature for the render that ships its files, and on the
validator-parameterisation feature for whichever of the reused validators needs a parameter.

**Gate ownership.** FR-28's checks are *implemented* by the feature that produces each artifact; this
feature owns the **rubric, its severity source, and the orchestration**, so the gate has one accountable
owner rather than being distributed with nobody answerable for its scope (D4).

## Description

This feature is the skill: the thing a user invokes, the rules that decide whether it will run at all,
the order it does its work in, and what it leaves behind.

`/aid-graph` is on demand. It occupies the same post-Knowledge-Base slot as the existing summary skill
and is a sibling of it, never a phase of it and never fired by discovery. Before doing anything it checks
that the Knowledge Base is finished and approved, because a graph built from a half-written Knowledge
Base would report gaps that are simply work in progress, and it refuses with a message that says what to
do instead.

It reads widely and writes narrowly. It reads the Knowledge Base, the project source, the
external-sources registry, its own settings and its own installed files; it writes two artifacts, two
reviewer ledgers and its own scratch, and nothing else. That one-way relationship is the whole basis of
its trustworthiness as an observer: it cannot alter the thing it reports on. The guarantee is not a
promise made once per state — it is a fence raised before the first write and verified before the run
ends, over the complement of a declared allowlist, so a write nobody intended is caught rather than
assumed away.

Running it twice on an unchanged project does nothing the second time. Its notion of "unchanged" is wider
than the summary skill's by exactly the list the requirements give — one component per input, and the list
rather than any count of it, because that list has grown three times and each growth closed a way the
artifact could go silently stale.

Finally it grades its own output and only its own output. It checks that identifiers resolve, that
relation pairs agree, that provenance is populated and that the view is valid; it never scores the
Knowledge Base's completeness, because that would fail the skill for reasons outside its control and
would reward under-reporting — which is the one thing the gap signal cannot afford. The gap findings live
in a different file that no grading state can reach, and when the run ends **both** ledgers are deleted,
like every other reviewer ledger in this methodology; what survives is the artifact's own `kb_gaps`.

## User Stories

- As a **maintainer/architect**, I want to invoke the graph when I want it rather than have it fire during
  discovery, so that it neither interrupts my work nor reports on an unfinished Knowledge Base.
- As a **maintainer/architect**, I want a refusal that names what to do, so that I am not guessing why
  nothing happened.
- As the **AID methodology owner**, I want a checked guarantee that no run modifies the Knowledge Base,
  so that the tool can be trusted as an observer of it.
- As a **maintainer/architect**, I want a re-run on an unchanged project to cost nothing and a flag that
  forces a rebuild, so that invoking it habitually is cheap.
- As a **maintainer/architect**, I want to be told *which* input changed when it regenerates, so that
  churn is attributable rather than mysterious.
- As the **AID methodology owner**, I want the skill graded on its own artifacts only, so that a pass
  says something about the tool rather than about the Knowledge Base.
- As a **KB reviewer**, I want to be told, in the run's own output, that the gap ledger does not survive
  the run and what does, so that I do not discover the shortfall by looking for a file that is gone.

## Priority

Must

## Acceptance Criteria

Assertions named below live in **`tests/canonical/test-graph-runtime.sh`**, on the sibling convention of
one suite per feature carrying one prefix — feature-006's `GL*` (its L4, :1105), feature-007's `GV*`
(:1790), feature-008's `GC*` (:153), feature-009's `TV*` (:588). The **`SR*`** series is this feature's,
is contiguous, and collides with none of them or with the `V*` / `R*` / `AC-S<n>` series of features 003,
004 and 005.

- [ ] **AC-11**: Given a project whose Knowledge Base is absent or not approved, when `/aid-graph` is
      invoked, then preflight refuses, writes nothing, and reports what the user must do.
      *Hooks: **SR01**, **SR02**.*
- [ ] **AC-12**: Given **all of FR-11's staleness inputs** unchanged since a run that produced both
      artifacts, when `/aid-graph` is re-run, then the run is a no-op — no artifact byte changes, no
      agent dispatch occurs, and nothing durable is written; given a change to **any one** input, then it
      regenerates and names the component that changed; and given `--reset` with no input change, then it
      regenerates regardless. *Hooks: **SR03**, **SR04**, **SR05**.*
- [ ] **AC-13**: Given any run, when the Knowledge Base files are compared before and after, then none
      outside the declared write allowlist has been added, removed or changed — asserted over a run that
      **produced** its artifacts, and asserted again in the violating direction. *Hooks: **SR06**,
      **SR07**.*
- [ ] **AC-16a** *(NFR-8; the warning is this feature's, the ceiling is feature-002's)*: Given a project
      whose node total exceeds the documented ceiling, when the run reaches the point at which the node
      set is complete, then it warns, names the total and the ceiling, and **still completes** — the exit
      status is unaffected. This SPEC asserts **no figure**: the ceiling is read from its shipped carrier
      and the fixture sets it. *Hook: **SR08**.*
- [ ] **AC-17** *(orchestrator's half; shared with features 007, 008, 009 and the
      validator-parameterisation feature)*: Given this feature's scripts, when they are compared against
      `canonical/aid/scripts/summarize/`, then no assembler or validator check body is duplicated — every
      check is invoked, never reimplemented. *Hook: **SR09**.*
- [ ] **AC-20** *(assembly half; the shape is feature-003's and the content is feature-004's and
      feature-005's)*: Given a run on a project where every carrier convention is present, when
      `relationships.md` is read, then its `## Coverage notes` carries **every** kind in §5.2's enum with
      its status and count and all three FR-22 exclusion rows with their rendered labels, in the fixed
      order, with extra rows below each fixed block in feature-003 D7a-1's order. *Hooks: **SR10**,
      **SR11**.*

Spec-authored criteria, numbered `AC-S<n>` under the scheme feature-003 introduced. **The numbering is
scoped to this SPEC**; a sibling's is cited with its feature number.

- [ ] **AC-S1**: Given the run, when its writes are enumerated, then every one matches the D3 allowlist,
      the fence's snapshot covers exactly the complement of that allowlist inside `.aid/knowledge/`
      (`kb.html` included), and `--verify` **fails closed** when no snapshot exists. *Hooks: **SR06**,
      **SR07**.*
- [ ] **AC-S2**: Given `--reset`, when it is applied, then it forces regeneration by discarding the
      digest comparison alone — it deletes no artifact and preserves no ledger. *Hooks: **SR05**,
      **SR12**.*
- [ ] **AC-S3** *(the retention correction)*: Given a run that produced a non-empty gap ledger, when it
      reaches DONE, then the gate ledger, the gap ledger and the scratch directory are all gone, and
      `relationships.md`'s `kb_gaps` still carries the same id set. *Hook: **SR12**.*
- [ ] **AC-S4**: Given each state transition, when its routing is examined, then the decision is carried
      by an observable — an exit code, a verdict token on stdout, or a printed grade — and by no
      unobservable judgment. *Hooks: **SR02**, **SR03**, **SR07**, **SR13**.*
- [ ] **AC-S5**: Given a completed VALIDATE, when its output is read, then it lists every rubric check as
      run, skipped or failed, so an absent row means a passed check and never an unrun one; and a skipped
      check is repeated in the closing summary. *Hooks: **SR13**, **SR14**.*
- [ ] **AC-S6**: Given the gate, when its inputs are enumerated, then no check's subject is the Knowledge
      Base's completeness and the gap ledger's path is passed to no grading call. *Hook: **SR15**.*
- [ ] **AC-S7**: Given either Pass-2 dispatch, when it is constructed, then it carries the empty tool set
      feature-005 D6 part 1 makes a contract term, and the pass's inputs are inlined. *Hook: **SR16**.*
- [ ] **AC-S8**: Given `--grade X`, when it is passed, then it binds this run only and writes no file.
      *Hook: **SR17**.*
- [ ] **AC-S9**: Given the six digest components, when one file of each is mutated in turn, then exactly
      one component's value changes each time — the components are pairwise disjoint, and each alone is
      sufficient to change the verdict. *Hook: **SR04**.*
- [ ] **AC-S10**: Given an install whose view templates are absent, when the run executes, then RENDER
      and VISUAL-GATE do not run, the `V-*` rubric rows emit nothing, the human pool is **N/A**, and the
      Overall Grade is the Machine Grade. *Hook: **SR18**.*

---

## Technical Specification

> **Written against a frozen spine.** What each artifact *is* — a node, an edge, a column, a lens, a gap
> row, a glyph — is settled upstream and is cited, never restated. What this SPEC contains is the run:
> its arguments, the record that decides whether it runs at all, the fence that makes its read-only
> claim checkable, the rubric its gate applies, the order of its states, and what it deletes.
>
> Governed by `canonical/aid/templates/state-machine-chaining.md`, `canonical/aid/templates/reviewer-ledger-schema.md`,
> `canonical/aid/scripts/grade.sh`, and — as conventions, each read on disk — `.aid/knowledge/coding-standards.md`
> (§ Exit Codes :212, § Logging and Output :233, § Configuration Access :245, § Security Conventions
> :257), `.aid/knowledge/authoring-conventions.md` (§ Prose Over Scripts :245),
> `.aid/knowledge/module-map.md` (§ Conventions :306, :321), `.aid/knowledge/test-landscape.md`
> (:29, :279) and `.aid/knowledge/quality-gates.md` (§ Minimum-Grade Thresholds :158).
> Modelled on `/aid-summarize`, read in full: `canonical/skills/aid-summarize/SKILL.md`, its ten
> `references/state-*.md` files, and `canonical/aid/scripts/summarize/`.
>
> **No figure here is a measurement** (§ Figures).

### The runtime boundary — what this feature does not do

Stated first, because a reader of an orchestrator will otherwise infer scope from everything it touches.

| It does not | Because | Owner |
|---|---|---|
| Decide what a node, an edge, a column, an id or a `Kind` is | The schema is frozen (feature-003 D1, D1a, D2). This feature moves rows it cannot interpret | feature-003 |
| Walk the project source, or decide significance or an exclusion | There is exactly one traversal and it is not this feature's (feature-004's seam, :343 ff.). This feature invokes it and consumes its streams | feature-004 |
| Extract, type or merge a row, or bound Pass 2 at row level | feature-005 owns both passes and all four bounds; this feature constructs the dispatch and honours the tool-set term (AC-S7) | feature-005 |
| Compute a gap, a severity or the routing block | feature-006 owns the predicate, the `qualifier`→severity function and the block it prints itself at GAP-REPORT (:878). This feature deletes the ledger at DONE and nothing else | feature-006 |
| Create the store, detect `prefers-reduced-motion` or `forced-colors`, or write any page DOM | **Detection and store creation are inside the shell** — `createStore(graphModel, initialLens, preferences)` with the pair detected there (feature-007 step 4, :1500–:1507, :1656, :1660). There is no mount code in this feature; RENDER invokes the shell's own assembly and reads its exit status | feature-007 |
| Decide which reused check binds which surface, or assert a DOM check against the canvas | feature-007's § Validator surface fixes the mapping (:1611–:1631), including that the canvas carries **only a text alternative** (:1626). D4 consumes that table and re-derives nothing | feature-007 |
| Write the runtime-prerequisite text, or the WebGL sentence | Emitted at RENDER into the page footer and the run's console output by the shell's generator (feature-007 :1604–:1609), asserted by **GV23** (:1817). DONE neither composes nor suppresses it | feature-007 |
| Measure the bench, the frame rate or the ceiling | feature-002 owns every figure (Stage 2b :348, D5 :723). This feature reads a shipped threshold and compares | feature-002 |
| Parameterise a reused validator, or decide whether a contingency fires | The validator-reuse parameterisation is that feature's; this runtime invokes the validators **as installed** and its rubric rows are unchanged either way (Open Item 5) | validator-parameterisation feature |
| Render canonical → profiles, touch a manifest or a count surface, or register the skill anywhere | Every packaging and registration surface belongs to the canonical-registration feature (Open Item 6) | canonical-registration feature |
| Author documentation, the registration suite or the ship gate | The tests-and-docs feature's (Open Item 7) | tests-and-docs feature |
| Fix a Knowledge Base gap, open a ticket, or write `.aid/knowledge/STATE.md` | FR-27 and §4 Out of Scope; AC-13 forbids the third outright, which is why this skill has **no APPROVAL and no WRITEBACK state** (§ State Machines) | — |
| Author the `external-sources.md` entry format, or the settings ignore-list section | Upstream of this work (D-5, D-4; feature-003 Open Item 1, feature-004 Open Item 8). This feature reports availability and proceeds | `/aid-discover` ELICIT; the settings schema |

### Data Model

#### D1 — Arguments

Following the existing convention: an `## Arguments` table in `SKILL.md` plus an `argument-hint:`
frontmatter string, as `canonical/skills/aid-summarize/SKILL.md`:15, :55–61 does.

| Argument | Effect |
|---|---|
| *(none)* | A full run. No-op when nothing changed (AC-12) |
| `--reset` | Forces regeneration by **discarding the digest comparison** and nothing else: no artifact is deleted, and **no ledger is preserved** — D6's lifecycle is unconditional (AC-S2) |
| `--grade X` | Overrides the minimum acceptable grade **for this run only**, validated against `^[A-F][+-]?$` exactly as `canonical/aid/scripts/summarize/writeback-state.sh`:204 validates its `GRADE` argument (AC-S8) |

**There is no other argument, and two candidates are declined for stated reasons.**

- **`--grade` is not persisted, which diverges from `/aid-summarize` deliberately.** Its sibling writes
  the value into `.aid/settings.yml` (`SKILL.md`:59). Here that file is **FR-11 input 4**, so persisting
  a grade floor would change a staleness input and force an unrelated regeneration on the next run —
  churn with no relation to the artifact. A durable floor is set through `/aid-config`, which owns that
  file; this flag stays a per-run override.
- **`--table-only` is not added.** Whether the view is in scope is already decided by a fact on disk
  (D2's `view_expected` predicate), so a flag would be a second, divergent way to say the same thing.

Without `--grade`, the floor is resolved by the project's single resolver — never by parsing
`.aid/settings.yml`, per `coding-standards.md` § Configuration Access (:250, "never hand-parse the YAML
in another script"):

```bash
bash canonical/aid/scripts/config/read-setting.sh --skill graph --key minimum_grade --default A
```

In this repository that resolves to **`B-`**: `read-setting.sh`'s skill mode tries `graph.minimum_grade`,
then the flat top-level key, then legacy `review.<key>`, then `--default` (:234–:257), and
`.aid/settings.yml`:6 carries `minimum_grade: B-` with no per-skill block. **It is the floor the *skill*
resolves at runtime; Q27's `B-` is this work's SPEC-gate floor — different floors, same value today.**

#### D2 — The staleness record: content-addressed, carried in the artifact

`/aid-summarize` compares two **dates** read from `.aid/knowledge/STATE.md` (`stale-check.sh`:37 ff.).
This skill cannot use that mechanism and should not: AC-13 forbids writing any Knowledge Base file, so
there is nowhere to stamp a last-run date, and a date comparison cannot see a source-tree change, which
FR-11 requires. So staleness is **content-addressed** and the record lives in the artifact this skill
already owns. No new state file is introduced — a durable file outside the two artifacts would be a third
output FR-10 does not admit.

| Field | Home | Value |
|---|---|---|
| `graph_inputs_digest` | `relationships.md` frontmatter | The composite below, as one physical line |
| `graph_generated_at` | `relationships.md` frontmatter | UTC timestamp, informational |

Both are the two scalars feature-003 D8 **reserves for this feature**, stating that "their values, shapes,
semantics, and writers belong to those features" and placing them **outside** the byte-identity boundary
(:1637–:1647). So the shape below needs nothing from that SPEC. This feature computes the values;
feature-003's frontmatter block carries them and its emitter writes them.

**Shape.** One plain single-line scalar, six `name=<hex>` pairs comma-joined in FR-11's own input order,
no spaces:

```yaml
graph_inputs_digest: kb=<sha256>,src=<sha256>,ext=<sha256>,cfg=<sha256>,vocab=<sha256>,tool=<sha256>
```

Equality of the **whole** string is the staleness test — so it is the composite FR-11 asks for — while
its parts are what let STALE-CHECK say *which* input changed instead of printing a bare verdict. A single
opaque hash cannot attribute a change without stored per-component state, and there is nowhere durable to
store it. The scalar stays single-line and pipe-free, which is what `build-kb-index.sh`'s extractors and
feature-003 D8 require of every scalar in that block, and `lint-frontmatter.sh` skips `source: generated`
documents outright (feature-003 D8), so no lint sees it.

**One component per input in FR-11's list, in FR-11's order. FR-11 is the authority for the set; this
table is the authority for each component's file set.** Adding an input to FR-11 adds a component here,
which is itself a tool change (input 6), so the boundary re-baselines visibly (feature-003 D7a-1's
open-set argument, :1504–:1524).

| Component | FR-11 input | Composed from |
|---|---|---|
| `kb` | 1 — the Knowledge Base | `path + sha256` for every `.aid/knowledge/*.md` at depth 1, **minus this component's two exclusions** below |
| `src` | 2 — the project source | `path + sha256` for every artifact in feature-004's enumerated node set: every `nodes.tsv` row, plus the **`int:`-prefixed** rows of `media-nodes.tsv` (feature-004 Open Item 7, :2208–:2213). *The prefix is correct here and is not a Q17 proxy: the clause is about which nodes have bytes on disk to hash, which is Q21's "where an id comes from"; an `ext:` row has no repo path and its content is `ext`'s* |
| `ext` | 3 — the external-sources file | `sha256` of `.aid/knowledge/external-sources.md`, or the literal `absent` where the file does not exist (AC-19; feature-004 step 10 makes a missing registry zero rows, not an error) |
| `cfg` | 4 — `.aid/settings.yml` | `sha256` of the whole file |
| `vocab` | 5 — the relation vocabulary, core **and** project extension | `path + sha256` of `<install-root>/aid/templates/graph/relation-vocabulary.yml`, then of `.aid/graph/relation-vocabulary.yml` or the literal `absent` (feature-003 D4's two files; **this discharges its Open Item 4**, :1932) |
| `tool` | 6 — the installed tool | **Both forms FR-11 offers, not one**: the installed **version string**, read from `.aid/.aid-manifest.json`'s `aid_version` — verified present, carrying `2.3.0` on this project — or the literal `absent` where no manifest exists; **and** `path + sha256` over the installed files that can change a byte of either artifact, by the rule and exclusion list below (**this discharges Open Item 4's second half**, :1937–:1948) |

Each component's value is `sha256` over its `LC_ALL=C`-sorted `path + sha256` lines, and the composite is
the scalar above. Sorting and fixed order are what make it byte-stable across runs and platforms — the
same determinism argument `canonical/EMISSION-MANIFEST.md`:47 makes for sorting its records by `dst`.

**The six file sets are pairwise disjoint**, which is what makes the changed-component report true rather
than approximate (**AC-S9**, **SR04**). Two exclusions from `kb` exist for exactly that reason:

1. **Every allowlisted path** (D3). Without this the run's own output would be an input to its own
   staleness decision, the digest would differ from the stored one immediately after every successful
   run, and the skill could never be idempotent. This is the load-bearing exclusion.
2. **`external-sources.md`**, counted once in `ext`. FR-11 lists it as its own input, and attributing a
   change to input 3 rather than input 1 is the whole point of the component split.

`.aid/knowledge/STATE.md` and `INDEX.md` **are** in `kb`, and the consequence is accepted: a re-review, a
summary run or an index regeneration each cost one attributable regeneration, which the changed-component
line names. Both are correct — a change to the Knowledge Base's own review state is a Knowledge Base
change, and `INDEX.md` is the routing table agents actually read — and excluding either to save one run
would blind the check to a real change.

**`cfg` hashes the whole settings file, and the narrower reading is declined.** Hashing only the resolved
`graph.ignore` value and its availability probe would be more precise and would avoid regenerating on an
unrelated settings edit. It is declined because it re-derives a requirement's input from that
requirement's rationale: FR-11 names the **file**. The trade is asymmetric — over-triggering costs one
attributable run and is visible, while under-triggering is silent staleness, which is the failure inputs
4, 5 and 6 were each added to close.

**Why `tool` carries the version string *and* a digest, when FR-11 offers the string as the primary
form.** FR-11 says "by its version string where one is exposed and otherwise by a digest", and a version
string **is** exposed: `.aid/.aid-manifest.json` records `aid_version` and a per-tool `version` (read on
disk). But a version string is a *claim* about the installed bytes rather than a measurement of them, and
it does not move when an installed file is edited in place — which is the normal condition on this
project's own branches and during `/aid-execute`. Taking only the string would therefore reintroduce the
silent staleness input 6 was added to close, one level up. Taking both costs one file read, keeps the
digest as the thing that is actually true, and makes an upgrade **attributable by name**: the
changed-component line can say the version moved, or that the installed files changed *at* an unchanged
version, which neither form alone can distinguish. Where no manifest exists the string reads `absent` and
the digest carries the component alone (FR-8a: the skill must work on any project with an approved
Knowledge Base, not only on an AID-installed one).

**The digest half's rule: a file is in `tool` iff it can change a byte of `relationships.md` or
`graph.html`.** Default-in over four installed areas, with a declared exclusion list, so a new file is
hashed unless someone writes a visible line excluding it:

| # | Area hashed in |
|---|---|
| TA1 | `<install-root>/aid/scripts/graph/**` |
| TA2 | `<install-root>/aid/templates/graph/**`, minus the two paths `vocab` covers |
| TA3 | `<install-root>/aid/templates/knowledge-graph/**` — the view's own files (feature-007 :1539–:1552) |
| TA4 | The reused files that assemble or are inlined into the page: `summarize/assemble.sh`, and `knowledge-summary/component-css.css`, `lightbox.js` and `design-tokens.md` (feature-007 :1561–:1571) |

| Excluded | Why the rule excludes it |
|---|---|
| Every validator — `validate-relationships.sh`, `validate-html-output.sh`, `validate-visuals.mjs`, `contrast-check.mjs`, `grade.sh` | Each reads an artifact and writes none of it (verified: none of the reused validators writes any file) |
| This feature's own `graph-preflight.sh`, `graph-stale-check.sh`, `kb-write-fence.sh`, `grade-graph.sh` | Each decides a **verdict**, not a byte |
| `<install-root>/aid/templates/graph/scale-ceiling.yml` | It decides a warning on stdout (D5) |
| `report-endpoint-satisfiability.sh` | feature-005's W3 report gates nothing and emits nothing into either artifact (:1459) |
| `.aid/.temp/**` | Scratch, not installed |

**The one thing the digest deliberately cannot see, with its remedy.** A validator upgrade changes no
artifact byte, so it leaves the verdict `CURRENT` and an unchanged artifact goes un-re-graded until the
next real change or `--reset`. That is the honest scope of FR-11 input 6's own wording — "scripts and
templates that **affect output**" — and the residual is a stale *verdict*, never a stale artifact. Both
directions are asserted (**SR04**): mutating a `tool` file yields `STALE`; mutating an excluded validator
yields `CURRENT`.

**`view_expected` — one predicate, three consumers.** The view is in scope for a run iff
`<install-root>/aid/templates/knowledge-graph/graph-skeleton.html` is installed. That single decidable
fact drives RENDER's and VISUAL-GATE's presence (§ State Machines), the `V-*` rubric rows (D4) and the
expected-artifact set below — so the three cannot drift, and the §10 delivery order needs no flag.

**The verdict, and why `graph.html` needs no digest of its own.**

| Verdict | Condition | Route |
|---|---|---|
| `FIRST_RUN` | `relationships.md` absent, or present with no `graph_inputs_digest` | EXTRACT |
| `STALE` | The recomputed scalar differs from the stored one, **or** an expected artifact is missing | EXTRACT |
| `CURRENT` | The scalars are equal **and** every expected artifact is present | DONE (idempotent) |

Expected artifacts are `relationships.md` always, and `graph.html` iff `view_expected`. Companion assets
are not in the presence test — whether the packaging produces any is open (FR-18) — and need not be: they
are inside `tool`, and a render that produced them once produces them again. The view needs no separate
digest because `graph.html` embeds `relationships.md` **verbatim** as its payload (feature-007 step 1),
and no route emits without rendering when the view is in scope; so equality plus presence is sufficient,
and the delivery boundary at which the view first ships is caught twice over — by the presence arm and by
`tool` gaining TA3.

#### D3 — The write allowlist, and the fence that checks it

Exactly these paths are writable for the whole run. Everything else — most of all every other file under
`.aid/knowledge/` — is read-only (FR-10, AC-13).

| # | Path | Written by |
|---|---|---|
| W1 | `.aid/knowledge/relationships.md` | feature-003's emitter (schema + this feature's two scalars) and feature-006 (`kb_gaps`) |
| W2 | `.aid/knowledge/graph.html` | feature-007's render, via the reused assembler |
| W3 | `.aid/knowledge/graph-assets/**` | feature-007's packaging, iff FR-18 produces companions |
| W4 | `.aid/.temp/review-pending/graph.md` and `.aid/.temp/review-pending/graph-kb-gaps.md` | this feature's VALIDATE; feature-006's GAP-REPORT |
| W5 | `.aid/.temp/graph/**` | feature-004, feature-005, feature-006 and this feature — every stream, the assembled coverage section, the visual-gate answer, and the fence snapshot |

W3's *shape* is what makes FR-9's naming requirement hold, and it is structural rather than conventional:
`build-kb-index.sh`:471 selects index rows with
`find "$ROOT" -maxdepth 1 -type f -name '*.md' ! -name '.*'`, so a **subdirectory** is invisible to it
whatever it is called, and `graph.html` is invisible because it is not `*.md`. One concrete rule
follows: **no companion asset may be a `*.md` file sitting directly in `.aid/knowledge/`.**

**The fence turns AC-13 from an assertion into a check.** `kb-write-fence.sh --snapshot` walks
`.aid/knowledge/` **recursively**, and writes `path + sha256` for every file **not** matching the
allowlist into `.aid/.temp/graph/kb-fence.txt`; `--verify` re-walks the same set and diffs. Four
properties are what make it non-vacuous:

| # | Property | What it makes impossible |
|---|---|---|
| KF1 | The fenced set is the **complement** of the allowlist, so `kb.html`, `INDEX.md`, `STATE.md`, every KB document and `.cache/**` are all in it | An over-broad allowlist passing silently: **SR06** asserts `kb.html` is in the snapshot |
| KF2 | `--verify` **exits 2 when no snapshot exists** | A run that never snapshotted "passing" verification — the exact "no error was raised" trap |
| KF3 | The snapshot is non-empty by construction, and **SR06** runs it over a run that **produced** both artifacts | A do-nothing run satisfying AC-13 by having written nothing at all |
| KF4 | Any added, removed or changed path exits `1` naming every offending path, and the closing summary says the artifacts must not be trusted | A stray write outside the allowlist succeeding silently — an accidental index regeneration, or a sub-agent editing a document it was only asked to read |

The precedent for a declared write zone plus a guard is this project's own: `coding-standards.md`
§ Security Conventions (:276–:283) records discovery as read-only on the repo "with one declared
exemption … a category guard in the skill pre-flight". This feature adds the *post*-condition that
bullet lacks, because an allowlist alone cannot see a write that ignores it.

**Why `INDEX.md` regeneration is not this skill's job.** AC-18 requires that regenerating the index leave
it and `relationships.md` consistent; feature-003 satisfies that by emitting valid frontmatter (its D8),
not by anyone running the generator here. `INDEX.md` is a registered generated file whose consumers are
`/aid-discover`'s FIX state and its `state-fix.md` Step 4 (`canonical/aid/templates/generated-files.txt`
:10–:11). If this skill ran it, KF4 would fail by design — which is exactly the signal that the write
belongs elsewhere.

#### D4 — The FR-28 rubric

**The grading algorithm is `canonical/aid/scripts/grade.sh`, unmodified.** Read on disk: it parses the
Severity and Status columns of a 7-column ledger, counts only rows whose Status is `Pending` or
`Recurred` (:215), and applies *worst severity dominates, count determines the modifier* — zero counted
rows `A+`, otherwise `E`/`D`/`C`/`B` banded by the worst severity present, with `+` for exactly one row
of that severity, no modifier for two to five, and `-` above five (:96–:102, :234–:251). There is no
maximum, no percentage and no weight in it. The rubric is therefore a **check → severity** mapping plus
a rule for how many rows a failure emits, and specifying anything else would describe an algorithm the
skill does not run. `grade-summary.sh`'s `AUTO_POOL` shape is **not** copied — its points model has no
counterpart in `grade.sh`, and its `COV`-centred pool is declined on the ground § The five scripts gives.

**Severities are not re-assigned here.** For every check on the table side, feature-003's validator table
already carries a gated `Ledger severity` column (:1771–:1787), and this rubric adopts it — a second
assignment would be a second authority that could drift. What this feature assigns is the severity of the
reused HTML and visual checks, which no frozen SPEC fixes, by **one rule applied once**: a failure that
makes the artifact **invalid**, makes information **unreachable**, or **traps or misdirects** the reader
is `[HIGH]`; a failure that leaves every fact reachable while degrading its **presentation** is
`[MEDIUM]`. The rule is applied per row below, with its reason in the cell. **The row set is closed over
each validator's `FAIL` flag, not over its ided checks** — the unlabelled ones have rows too (`V-ST`).

| ID | Check | Severity | One row per | Surface it binds |
|---|---|---|---|---|
| `R*` | The **gating** checks of `validate-relationships.sh` — V1–V11, V13, V14 | **feature-003's own column**, adopted: `[HIGH]` throughout, on its own stated ground that each maps to a stated acceptance criterion (:1789) | one finding per emitted `[TAG] <doc>: <message>` line (:1750) | `relationships.md` |
| `V-H1` | `validate-html-output.sh` H1 — HTML validity | `[HIGH]` — an invalid document is invalid | reported error | the page |
| `V-A` | `validate-html-output.sh` A1–A5 — landmarks, the lightbox's ARIA, its focus trap, the reduced-motion block, `:focus-visible` | Per sub-check, as `V-T` is: `[HIGH]` for **A2** and **A3**, where a dialog that traps focus or goes unlabelled **denies access** to the rest of the page; `[MEDIUM]` for **A1**, **A4** and **A5**, where every fact stays reachable and the failure is a presentation regression in a reused shared stylesheet — A4 especially, since NFR-4's actual compliance is feature-008's pre-settled layout and this block is a backstop | failing sub-check | **page structure and the table view, never the canvas** |
| `V-ST` | `validate-html-output.sh`'s **`[Structural checks]`** block (`:247`–`:250`) — skip-link, `<noscript>` fallback, `color-scheme: light dark`. These carry **no id**, and the script header's list of them ends in "etc." (`:29`), so the **code** is the authority for the set. Each is a `check()` call, so each raises `FAIL` and drives the script's `exit 1` (`:68`–`:78`, `:410`–`:413`) — a rubric keyed on ided checks alone would leave the run able to print a grade over a zero-row ledger while a validator it invoked failed, which is the one hole "no row = no finding" cannot survive | Per sub-check, by the same rule: `[HIGH]` for the `<noscript>` fallback, without which a reader whose script engine is off or broken gets a page with nothing in it and no route out, and `./INDEX.md` leaves L2's resolvable set (feature-007 :1620); `[MEDIUM]` for the skip-link, because A1's landmarks answer the same bypass duty by a second route and every fact stays reachable, and for `color-scheme`, which only selects which theme paints, each of them already contrast-checked by `V-C` | failing sub-check | **page structure and the table view, never the canvas** |
| `V-L` | L1, L2 — anchor and relative-link resolution | `[HIGH]` — a broken link makes a named document unreachable | broken anchor or link | the page |
| `V-S2` | S2 — no CDN `<script src>` or `<link href>` | `[HIGH]` — an artifact that needs the network to render is unreachable offline | offending reference | the page |
| `V-NM` | NM — no Mermaid engine, all sub-checks | `[HIGH]` — the guardrail exists because a runtime engine misleads a reader about what the page contains | failing sub-check | inline scripts and CDN `src` |
| `V-C` | `contrast-check.mjs` | `[MEDIUM]` — the marks are drawn and named; the contrast of the presentation is what regressed | failing colour pair | the declared CSS custom properties |
| `V-T` | `validate-visuals.mjs` T1–T4 | `[HIGH]` for T1, T3, T4 — text too small to read, a collapsed visual, or a region clipped off the side at a supported width each mean content is **not available**; `[MEDIUM]` for T2, where content is present but crowded | failing check, per visual | authored visuals only — a `<canvas>` matches none of its three selectors |

**The two advisories emit no row, and that is the one place adopting a sibling's column is not enough.**
feature-003's V12 and V15 carry `[LOW]` and are declared **advisory, never gating**, mapped to no
acceptance criterion by design (:1784, :1787, :1792–:1804). A `[LOW]` row lands in `grade.sh`'s `B` band,
which gates at every floor above it, and the floor is a per-project setting this skill reads rather than
fixes (D1) — so laddering an advisory into the ledger would make FR-25's and FR-28's posture depend on a
project's configuration. Their output — and equally feature-005's W3 reachability report and
feature-006's F6 extension-relation counter — is printed in the run's own output and reaches no ledger.

Every surface column above is **read from feature-007's § Validator surface** (:1611–:1631) and
re-derived nowhere: that table is where AC-9's check-to-surface mapping is settled, including that the
canvas carries only a text alternative (:1626), so no row here asserts a DOM check against a bitmap.

**So the emitted range is exactly `[HIGH]` and `[MEDIUM]`, and each of the other three enum values is
excluded for its own reason.** `[CRITICAL]` is reserved by the ledger schema for findings that mislead
downstream phases or break tooling; every failure above is a defect in an artifact this same run is about
to repair, and none escapes the run. `[LOW]` is excluded because the only `[LOW]` checks in scope are the
two advisories, which emit no row at all. `[MINOR]` is excluded from the other side: a validator that
fired found a real defect, so nothing here is cosmetic.

**What the severities buy, given the floor.** Every failed check becomes `Pending` rows in
`.aid/.temp/review-pending/graph.md`; passed checks add none, per `state-validate.md`:50's own rule ("no
row = no finding"). The resolved floor here is `B-` (D1), and this rubric emits only `[HIGH]` and
`[MEDIUM]`, whose bands are `D` and `C` — so **every** row this gate can emit drops the Machine Grade
below the floor and routes to FIX. Severity decides **band and repair order**, which rows FIX takes
first, rather than pass or fail — until a project sets a floor inside the emitted range.

**"No row = no finding" is only safe if every check ran, so the gate reports its own coverage.**
`grade-graph.sh` prints an inventory line per rubric row — `run` / `skip` / `fail` — before the grades.
A check that could not run (Playwright absent; `validate-visuals.mjs` prints `SKIP` and exits 0, its
`:38–:39`, `:128`, `:144`) is recorded as `skip`, repeated in the closing summary, and emits no row. That
is the documented degradation, and naming it is what keeps the grade from being read as stronger evidence
than it is (**AC-S5**, **SR13**, **SR14**).

**What is structurally absent.** No check's subject is the Knowledge Base. The gap rows live in a
different file that no grading call is ever given (feature-006 S1, :898), so the gate is not merely
instructed to ignore gaps — it cannot reach them (**AC-S6**, **SR15**). **When `view_expected` is
false**, the `V-*` rows are not run and emit nothing; under `grade.sh` that needs no mechanism at all,
which is a further reason the severity model is right for this artifact — the rubric shrinks with no
maximum to recompute.

#### D5 — Where a human gate belongs, and where it does not

`/aid-summarize` runs a three-check human pool. Whether that is right here differs **per artifact**, and
REQUIREMENTS settles the halves separately. §5.9's Decision paragraph fixes the data half —
`relationships.md` "grades as *data*", its visual-fidelity clause being about the sibling `kb.html`.
This view's gate is §6.1's Rationale — "the human visual gate to judge whether the graph is legible".

| Artifact | Human grade? | Reasoning |
|---|---|---|
| `relationships.md` | **No** | Every property that matters is decidable: an id resolves or does not, a pair inverts or does not, a provenance value is in the enum or not. There is no judgment to elicit, so a human pool would be ceremony that invites rubber-stamping. `/aid-summarize`'s `K1` and `K2` have **no analogue** — `K1`'s subject is Knowledge Base completeness, which FR-28 forbids grading, and `K2`'s is prose faithfulness, which a machine-checkable relation table does not have. `spot-check-facts.sh` is therefore not reused: it exists to help a human answer `K2` |
| `graph.html` | **Yes — one mandatory check, `G1`** | Whether a live force-directed graph is *legible* is not machine-decidable. `validate-visuals.mjs` does not even collect the canvas (feature-007 :1624). Two project rules already bind this: `.aid/knowledge/tech-debt.md` § Gotchas — "Web-output reviews require Playwright: reviewing `kb.html` or the site by reading HTML/CSS is not a valid review" — and `.aid/knowledge/test-landscape.md` § Known Test Gaps — "Source inspection is not a valid review of rendered pages" |

- **`G1` is the whole human pool and is mandatory.** A fail forces the Human Grade to `F`, exactly as
  `grade-summary.sh`:483–:488 forces it when its `MANUAL_V1` is 0. `G1` asks one question about the
  artifact opened in a real browser: is the graph legible and usable — labels readable at default zoom,
  each lens visibly changing the view, keyboard zoom and pan working (NFR-6), reduced motion yielding a
  settled picture (NFR-4)?
- **One of `G1`'s answers is "it did not render."** That is a real outcome, not a legibility verdict: the
  shell mounts the table first and unconditionally and the canvas may report `mode: 'unavailable'`
  (feature-007 :1510–:1515; feature-008 :336, GC19 :655). The gate records it as a `G1` fail whose
  repair is the WebGL prerequisite, and it is the one `G1` answer FIX routes to the packaging owner
  rather than to a density or label change.
- **Overall Grade = `min(Machine, Human)`**, the composition `grade-summary.sh` already uses. Where
  `view_expected` is false the human pool is **N/A** and Overall = Machine (**AC-S10**) — the honest form
  of "no human gate on a table".
- **The answer lives in `.aid/.temp/graph/visual-gate.json` (W5) and dies with the scratch**, so `G1` is
  re-asked on every regeneration. That is correct: a regenerated view is a different picture, and a
  stored approval would be an assertion about bytes that no longer exist. Nothing is persisted into
  `.aid/knowledge/` — AC-13.

#### D6 — Ledgers, scratch, and the retention correction

Three things this run creates and this run destroys, on one lifecycle with no exception:

| Path | Contents | Graded? | Deleted at DONE |
|---|---|---|---|
| `.aid/.temp/review-pending/graph.md` | This rubric's failures only (D4) | **Yes** — this file is the gate | Yes |
| `.aid/.temp/review-pending/graph-kb-gaps.md` | feature-006's gap rows, one per `kb_gaps` entry | **Never** — its path is passed to no grading call | **Yes — corrected here** |
| `.aid/.temp/graph/**` | Every stream, the assembled section, the fence snapshot, the `G1` answer | — | Yes |

Both ledger paths are registered in the shared schema's location table by feature-006's L3, which is what
keeps them non-bespoke under C-6.

**The correction, and its authority.** The 2026-07-28 draft deleted only `graph.md` and retained
`graph-kb-gaps.md`, citing "feature-006 §D7"; its `--reset` row further asserted that the previous gap
ledger "must survive so the `Fixed` / `Recurred` transitions of feature-006 still work". That authority
no longer exists. feature-006's D7 **withdrew** the retention carve-out it once wrote into the shared
schema (:782–:791; STATE.md Q22) and routed the correction here (:838–:846, Open Item 3 :1209), and the
owner ruled on it directly (**Q25 item 1**): the gap ledger dies at DONE like every other reviewer
ledger. Three independent authorities agree, and the third needs no feature at all —
`canonical/aid/templates/reviewer-ledger-schema.md` says it in its own voice: "**Never:** … Carry a
ledger past skill DONE (clean up on completion)" (:200), with the mechanism at :104 and :159–:161 and the
rule restated at :194. **Q8** is why this skill may not carve out an exception locally: retention is a
methodology defect lifted out of this work, and a skill-local skipped delete is *worse* than the
withdrawn schema amendment, because a schema amendment is visible to everyone reading the schema while a
skipped delete is invisible from it.

**The consequence, stated at its real size rather than hidden.** Until D-6 lands:

1. `Fixed` and `Recurred` are **unreachable**, so every run is cycle 1 and every gap row is `Pending`.
   feature-006's transition logic is still specified and still tested against a fixture that supplies a
   previous ledger (its GL10, :1122); what is missing is the input, not the mechanism.
2. What survives is the **`kb_gaps` list in `relationships.md`'s frontmatter** — durable, outside the
   byte-identity boundary by feature-003 D8's design, and already read by feature-007 — plus the command
   the routing block prints.
3. That command **regenerates the ledger from durable inputs by a full re-run** — `/aid-graph --reset`,
   which discards the digest comparison and runs the pipeline again, FR-31's bounded agent pass included,
   recomputing the gap set and **overwriting** `kb_gaps`. It is **not** a read-back of `kb_gaps`: no mode
   of feature-006's detector takes that list as input (its :1030–:1041). Reproducible-on-demand is a
   weaker guarantee than retained, and calling it that is the point.
4. Deletion happens **after** feature-006's routing block has already told the reader all of the above at
   GAP-REPORT (its :878, :911–:925, AC-G6 :168–:171, GL18 :1130). So the reader is never surprised by an
   absence.

**The cheaper alternative is not adopted, and is sized correctly.** Stashing the previous run's
`kb_gaps` before EMIT overwrites the artifact would make **`Fixed`** derivable and would leave
**`Recurred` undecidable**: a `kb_gaps` entry carries `id`, `name`, `severity` and `qualifier` and **no
`Status`**, so absent-then-present cannot be told from a first-time gap, and `Recurred` is defined over a
prior `Fixed` that only a previous ledger's Status column records. It also needs an interface change,
since `--previous` takes feature-006's own prior *ledger*. feature-006 sizes it the same way and declines
it for the reason that decides it here too: "a partial substitute presented as a fix is how D-6 would
quietly stop being scheduled" (its :825–:836, Open Item 2 :1199). Recorded as an owner decision, not
taken (Open Item 2).

#### D7 — Coverage-note assembly (feature-003 Open Item 14; feature-004 Open Item 7)

feature-003 owns the section's shape, order and validation; feature-004 and feature-005 own its content;
**assembling the rendered section is this feature's**, and feature-005's step 15 reads the result
(:1361–:1365). `assemble-coverage-notes.sh` reads both producer contributions in the five-field TSV shape
`scope | key | status | count | note` (feature-004 D7, :1761–:1767) and writes
`.aid/.temp/graph/coverage-notes.md` (W5).

**Three rules, and each answers a way a naive assembler gets it wrong:**

1. **The fields are reordered, not passed through.** The TSV order is `key, status, count, note`; the
   rendered kind table is `| Kind | Carrier convention | Status | Nodes |` and the exclusions table is
   `| Exclusion | Applied | Note |` (feature-003 D7a's skeleton, :1399–:1403). So a kind row emits
   `key, note, status, count` and an exclusion row emits `label, status, note` — dropping `count`
   entirely. A pass-through implementation produces a section V14 rejects.
2. **Exclusion keys are translated; kind keys are not.** feature-004 emits the keys `generated-trees`,
   `vendored-code` and `ignore-list`; the rendered labels are `generated/derived trees`,
   `vendored third-party code` and `` `.aid/settings.yml` ignore list ``. This is the third obligation of
   feature-004 Open Item 7 (:2214–:2217): the translation table lives here, in one place, and an
   assembler that passed all six keys through verbatim would fail V14 on labels feature-004 cannot see.
3. **Extra rows sort by key across both files.** Each row's host table is its own `scope`; fixed rows
   come first in their fixed order, then every extra row of that scope from **both** producers, in
   `LC_ALL=C` ascending order of key, per feature-003 D7a-1 (:1437–:1449). Because the order keys on the
   row and never on its origin, this feature may read and concatenate the producer files in any order —
   which is precisely the property D7a-1 chose its rule for (:1472–:1492).

**Two assembly failures exit `1` naming the offenders rather than writing a section a validator will
reject afterwards**: a kind table that does not receive exactly one fixed row per `Kind` enum value, and
an extra key that collides with a fixed key or with another extra row in the same table. Both are
V14 violations (:1786) that are cheaper to name at the seam than to diagnose from a validator failure on
an emitted artifact.

**FR-9a's "every run" binds every run that emits.** The idempotent path emits nothing, and the artifact
it leaves in place already carries the notes written by the run that produced it.

### State Machines

Eleven states, counted in the table below. `/aid-summarize` has ten, and every difference is traceable to
a requirement.

**The table is the whole transition set, and no schematic duplicates it** — its rows are in spine
order, every departure named in that row's routing cell, FIX's re-entries in difference 5's table.
A drawing is a second copy that goes stale on the first routing change, as the pre-decision draft's did.

| State | Reference doc | Body | Routing decision, and the observable that carries it |
|---|---|---|---|
| PREFLIGHT | `state-preflight.md` | this feature | `graph-preflight.sh` exit code: `0` → CHAIN to ENUMERATE; `1` aborts the run with the failing check named |
| ENUMERATE | `state-enumerate.md` | invokes feature-004's `scan-source.sh`; mechanics cited, never restated | its exit code (`0`/`1`/`2`, its :2036) → CHAIN to STALE-CHECK |
| STALE-CHECK | `state-stale-check.md` | this feature | `graph-stale-check.sh`'s verdict token on its last stdout line → CHAIN to EXTRACT on `STALE`/`FIRST_RUN`, CHAIN to DONE's idempotent variant on `CURRENT` |
| EXTRACT | `state-extract.md` | this feature's dispatch of feature-005's two passes | `harvest-declared.sh` / `derive-edges.sh` exit codes, then the Pass-2 completion check's (`1` on a shortfall, its :1370) → CHAIN to EMIT |
| EMIT | `state-emit.md` | `assemble-coverage-notes.sh` (D7), then feature-005's `build-relationships.sh` | both exit codes → CHAIN to GAP-REPORT |
| GAP-REPORT | `state-gap-report.md` | **feature-006, outright** (its L1, :968–:976) | its single unconditional `**Advance:**` → CHAIN to RENDER. There is no route from here to FIX or to a non-zero exit (its S3, :900) — which is how FR-25/AC-14's "still completes" holds structurally |
| RENDER | `state-render.md` | invokes feature-007's assembly | the reused `assemble.sh`'s exit code → CHAIN to VALIDATE. **Skipped when `view_expected` is false** (D2) |
| VALIDATE | `state-validate.md` | this feature | `grade-graph.sh`'s printed Machine Grade against the resolved floor → CHAIN to VISUAL-GATE at or above it, to FIX below |
| VISUAL-GATE | `state-visual-gate.md` | this feature | the recorded `G1` answer and the recomputed Overall Grade → CHAIN to DONE or to FIX. **N/A when `view_expected` is false** |
| FIX | `state-fix.md` | this feature | the repaired path's location decides the re-entry state (table below) — printed, and carried in the ledger row's `Evidence` |
| DONE | `state-done.md` | this feature | HALT, in one of two variants |

**Every transition is CHAIN or HALT; none is a pause.** `state-machine-chaining.md`:38 admits CHAIN for
"states whose user interaction is fully `AskUserQuestion`-based", :102 states that a pause "is only
legitimate when the user has to do work outside the chat", and :45 names browsing to an artifact as the
rare case that is normally handled inline by surfacing the file. `/aid-summarize`'s own
MANUAL-CHECKLIST — whose `V1` likewise requires a real browser — chains (`state-manual-checklist.md`:39).
VISUAL-GATE follows that precedent and surfaces the artifact rather than stopping the run.

**Five differences from `/aid-summarize`, each traceable to a requirement.**

1. **No PROFILE state.** Its sibling needs one to resolve `discovery.doc_set` into an ordered section
   manifest. This artifact's section set is the relationship table; there is nothing to profile.
2. **No APPROVAL and no WRITEBACK state.** Both of its sibling's exist to write `.aid/knowledge/STATE.md`
   — `state-approval.md` an approval scalar, `state-writeback.md` a history row. AC-13 forbids writing
   any Knowledge Base file, so neither can exist here. The consequence is deliberate and good: because
   currency is content-addressed rather than approval-addressed (D2), STALE-CHECK has **no
   `CURRENT_UNAPPROVED` branch** — the third verdict `stale-check.sh` emits (its :7) has no counterpart
   — so a re-run on an unchanged project is a true no-op rather than a re-request for sign-off.
3. **VISUAL-GATE carries one check where MANUAL-CHECKLIST carries three** (D5).
4. **STALE-CHECK runs third.** Its sibling can decide staleness from two dates before doing any work;
   FR-11's `src` component is defined over the enumerated node set, and a newly added artifact is
   invisible to any stored path list, so enumeration must precede the decision. Two alternatives were
   considered: hashing a stored path list (rejected — a new file is invisible to it, which is the case
   FR-11 input 2 exists for) and hashing the repository (rejected — FR-22's exclusions are where nearly
   all of this repository's file mass sits, so the digest would churn on every rendered-profile edit).
   What `CURRENT` saves is the expensive half: the two-pass extraction with its bounded agent step and
   the render. ENUMERATE is the cheap, deterministic half, and it writes **only allowlisted scratch** —
   not "nothing", which is why the no-op is stated as *durable* below.
5. **FIX re-enters the pipeline rather than looping straight to VALIDATE.** Both artifacts are generated,
   so hand-editing one is not a repair: the next regeneration re-emits the defect, and the file carries
   an `AUTO-GENERATED` marker naming the command that overwrites it (feature-003 D8). The repair goes to
   the **input**, and re-entry is keyed on where that input lives:

| The repair touched | Re-enter at | Why not earlier or later |
|---|---|---|
| A view input — anything under TA3, the palette, or the assembled page | RENDER | The table is unaffected, and re-running EXTRACT would re-run the bounded agent pass and legitimately churn the `inferred` rows for a CSS fix |
| A table input — the vocabulary, the schema template, an enumeration or extraction script, or `assemble-coverage-notes.sh` | EXTRACT | The row set itself changes |
| Nothing — the row was `Accepted` or `Invalid` under the schema's rules (:96, :103) | VALIDATE | There is nothing to regenerate |

**`G1`'s repair is subjective and uses expose → propose → ask**: restate the legibility complaint
precisely, propose one concrete change — a density default, a label-collision rule, a lens preset — and
wait for confirmation before editing. Never guess-fix a judgment. Machine-pool rows are objective and
have one correct repair each; the fixer does **not** touch the `Status` column, because the next
VALIDATE re-verifies (schema :102, "the fixer fixes, the reviewer verifies").

**DONE has two variants.**

- **Normal completion** — print the artifact paths, the grades, and the check inventory including every
  `skip`; print the node total against the ceiling if it warned; then delete `graph.md`,
  `graph-kb-gaps.md` and `.aid/.temp/graph/`, and `rmdir` `review-pending/` if it is empty — the
  sequence `state-done.md`:9–:10 already performs for its own ledger.
- **Idempotent completion** — print that both artifacts are current, name the components compared, and
  print the `--reset` hint. **No durable file is written**, and the scratch ENUMERATE produced is
  removed. It does **not** re-warn about the ceiling: the ceiling verdict is a function of the node set,
  the node set is a function of the inputs, and the inputs are what this verdict just found unchanged.

### Feature Flow

The FR-10 / AC-13 guarantee is the load-bearing part, so it is a fence around the whole run rather than a
promise inside each state.

1. **PREFLIGHT.** `graph-preflight.sh`, before any state, in `summarize-preflight.sh`'s shape — an
   `err()` helper printing a cause line plus an actionable `→` line, then `exit 1` (its :10–:18).

| # | Check | The message names |
|---|---|---|
| P1 | `.aid/knowledge/STATE.md` exists | run `/aid-config`, then `/aid-discover` |
| P2 | **The Knowledge Base is approved (FR-8).** Read the frontmatter scalar `kb_status`; `Approved` passes. Fall back, only when that key is absent, to `> **User Approved:** yes` **scoped to the region above the first `##` heading** | run `/aid-discover` to APPROVAL and approve the Knowledge Base (AC-11) |
| P3 | At least one populated Knowledge Base document — a `.aid/knowledge/*.md` other than `STATE.md` / `README.md` / `INDEX.md` with more than 30 non-blank lines and no `^❌ Pending` marker, as `summarize-preflight.sh`:37–:57 tests it | run `/aid-discover` to populate the Knowledge Base |
| P4 | Not in Plan Mode (`CLAUDE_PLAN_MODE` is not `1`) — the run writes files | exit Plan Mode and re-run |
| P5 | **Node.js ≥ 20 (C-5)** | install or upgrade Node.js and re-run |
| P6 | The installed graph area is present — `<install-root>/aid/scripts/graph/` and `<install-root>/aid/templates/graph/` | reinstall or upgrade AID; the install is incomplete |
| P7 | Inside a git work tree | feature-004's exclusion classes need `git check-ignore` and `check-attr` (its :1941–:1943), so a non-git checkout cannot produce a reproducible exclusion set |

**P2 differs from `summarize-preflight.sh` on purpose, and the difference is a correctness fix.** That
script matches `^(> *)?\*\*User Approved:\*\* yes` against the whole file (its :30). In this repository
`.aid/knowledge/STATE.md` contains that literal **twice** — once in the blockquoted metadata block at
`:22`, which is the Knowledge Base's approval, and once at `:103`, inside `## Knowledge Summary Status`
(`:87`), which is the *summary's* approval, written by `/aid-summarize` itself. An unscoped grep
therefore passes when the Knowledge Base is unapproved but a stale summary approval is recorded. Reading
the machine scalar first is this project's own established pattern for exactly this migration —
`stale-check.sh`:14–:17 records `summary_approved` being relocated to frontmatter with a
"frontmatter-first, legacy-prose fallback" — and `.aid/knowledge/STATE.md`:10 carries `kb_status:
Approved` today. The `/aid-summarize` defect is reported upstream, not fixed here (Open Item 8).

**P5's floor is 20, and it is the floor the project already enforces**, verified at three sites:
`summarize-preflight.sh`:76 guards `-lt 20`, `state-preflight.md`:11 states ≥ 20, and
`summarize/package.json`:8 declares `"node": ">=20"` for the very validators this skill reuses.
feature-006's detector cites "the floor `graph-preflight.sh` P5 asserts" by name (its :1018), so this
check is an inbound dependency rather than a local preference.

**One non-refusal, stated because refusing here would be a defect.** A missing
`.aid/knowledge/external-sources.md` prints a stderr notice and the run **continues**: feature-004's step
10 makes a missing or key-less registry zero rows and explicitly not an error, AC-19 requires the run to
complete with zero nodes of the affected kind, and the coverage notes report the absence. The 2026-07-28
draft refused on this check; that clause is withdrawn.

2. **Raise the fence.** `kb-write-fence.sh --snapshot` (D3). This is the same recursive walk that
   produces the `kb` digest component, so the snapshot costs nothing extra.
3. **ENUMERATE** → feature-004's four streams plus `coverage.tsv`, invoked and consumed. Its ignore-list
   **availability** is reported by feature-004's own probe and coverage row — its D4a ownership table
   leaves this feature only the settings-schema change (:1583–:1587), which supersedes the older routing
   of "the ignore-list availability check" here (feature-003 Open Item 5, :1949).
4. **STALE-CHECK** computes D2's components, prints the verdict and the changed components, and exits `0`
   for every verdict. The precedent is `stale-check.sh`, whose header states "Exit 0 always (the
   'decision' is informational, not a failure)" (its :9) and whose one non-zero path is an unreadable
   input (:32–:35) — the usage class, not a verdict. `CURRENT` → step 10, then DONE's idempotent variant.
5. **EXTRACT** → feature-005's Pass 1a, Pass 1b, the class-0 freeze, then **Pass 2, dispatched by this
   feature**: one discovery dispatch per manifest document and one typing dispatch, each with its inputs
   **inlined** and **an empty tool set** — the contract term feature-005 D6 part 1 states the bound rests
   on (:898–:910), routed to this feature as its Open Item 14 (:1651). A dispatch holding a file-read or
   fetch tool could read a second document whatever its prompt said, and the read ledger could never see
   it, so this is the enforcement point and it is asserted (**AC-S7**, **SR16**). Where Pass 2 cannot be
   dispatched at all, this feature writes the `pass-2-unavailable` disposition for every candidate and
   the artifact ships class-0 only — feature-005's stated, total degradation (:988–:997), not a
   loophole. Batching documents into one dispatch would weaken the bound from a property of the shape to
   an instruction about inlined text, and is declined (its Open Item 12, :1631; Open Item 3 here).
6. **The node set is complete here, so the ceiling warning is emitted here** (AC-16a): the total node
   count across feature-004's two streams and feature-005's `kb-nodes.tsv` (feature-004 Open Item 7,
   :2213–:2214), compared against the shipped threshold, printed to stdout and repeated at DONE, with
   **no effect on the exit status** — FR-25's posture applied to a warning.
7. **EMIT** → `assemble-coverage-notes.sh` (D7), then feature-005's `build-relationships.sh`, which
   writes W1. Call boundary: this feature supplies the digest values and the assembled section; the
   schema, the ordering and the frontmatter contract are feature-003's.
8. **GAP-REPORT** → feature-006 writes `kb_gaps` into W1 and its ledger into W4, and prints its own
   routing block.
9. **RENDER** (iff `view_expected`) → feature-007's assembly writes W2 and any W3 companions.
10. **Lower the fence.** `kb-write-fence.sh --verify` (D3). It runs on **every** exit path, including the
    idempotent one and the failing ones; and because `--verify` fails closed with no snapshot (KF2), a
    route that skipped step 2 cannot pass it silently.
11. **VALIDATE → VISUAL-GATE → DONE**, as § State Machines describes.

**What "no-op" means precisely, because three of the four claims a reader would want are stronger than
the fourth.** On the `CURRENT` path: **no artifact byte changes**, **no agent dispatch occurs**, **no
ledger is written**, and **nothing durable is written at all** — while the enumeration did write
allowlisted scratch, which DONE removes. That is the honest reading of AC-12, and it is what **SR03**
asserts, artifact bytes included.

### Layers & Components

Authored **once in `canonical/`** and rendered to every host profile by the existing generator (**C-2**);
the rendered copies under `profiles/`, `packages/*/_vendor/` and the dogfood `.claude/` tree are build
output and are never hand-edited (`.aid/knowledge/module-map.md`:337). The test suite lives under
`tests/canonical/`, which is repository test infrastructure and is not rendered.

```
canonical/skills/aid-graph/                      # created by THIS FEATURE (FR-7)
├── SKILL.md
├── references/
│   ├── state-preflight.md      state-stale-check.md   state-validate.md
│   ├── state-visual-gate.md    state-fix.md           state-done.md      # THIS FEATURE
│   ├── state-enumerate.md      state-extract.md       state-emit.md
│   ├── state-render.md                                                   # THIS FEATURE (thin routers)
│   ├── state-gap-report.md                                               # feature-006, outright
│   └── agent-pass.md                                                     # feature-005
└── (no README.md ships — see the ownership seam)

canonical/aid/scripts/graph/                     # shared area; five files are this feature's
├── graph-preflight.sh   graph-stale-check.sh   kb-write-fence.sh
├── grade-graph.sh       assemble-coverage-notes.sh                       # THIS FEATURE
└── (scan-source.sh, significance-rules.sh, relationship-schema.sh, harvest-declared.sh,
    derive-edges.sh, build-relationships.sh, report-endpoint-satisfiability.sh,
    validate-relationships.sh, detect-kb-gaps.mjs, coverage-predicate.mjs)  # features 003–007

canonical/aid/templates/graph/
└── scale-ceiling.yml                            # THIS FEATURE declares the carrier; feature-002 supplies the value
```

**A thin router is not a body.** `state-enumerate.md`, `state-emit.md` and `state-render.md` invoke a
named script belonging to another feature, print the state line and route on its exit code. No mechanic
of that script is restated in them, for the reason the frozen SPECs give repeatedly: a second copy of a
rule is a divergence waiting to happen. `state-extract.md` is the one exception and is genuinely this
feature's, because Pass 2's dispatch construction — the tool set above all — is runtime work no script
performs.

**`scale-ceiling.yml` declares the carrier and no value.** feature-002's D5 measures the ceiling and its
report may be cited by no permanent artifact (its :1060–:1067), which is exactly why the number needs a
shipped home; the file holds one key, its value arrives with that research, and **this SPEC states none**.
It is excluded from the `tool` digest by D2's rule, because it decides a warning and not a byte.

#### The ownership seam — 010 against the three concurrent features

The split is by **file**, and where a file is shared, by **named section**, so `/aid-detail` cannot
produce two tasks editing the same lines.

| File or section | This feature | Other owner |
|---|---|---|
| `SKILL.md` frontmatter (`name`, `description`, `allowed-tools`, `argument-hint`) | **Owns** | — |
| `SKILL.md` — `## Pre-flight Checks`, `## Arguments`, `## State Detection`, `## Dispatch`, `## Quality Gate`, `## Failure modes and recovery` | **Owns**, except the one Dispatch row feature-006 contributes | feature-006 (that row, its :972) |
| `SKILL.md` — `## References` | Ownership is **contested by the pre-decision drafts** and is not resolved unilaterally here | **canonical-registration feature** — Open Item 6 |
| `README.md`, the canonical→profiles render, the emission manifests, the count surfaces, the registration of the skill | — | **canonical-registration feature** |
| `references/*.md` — the six states listed above plus the four thin routers | **Owns** | — |
| `references/state-gap-report.md`, `references/agent-pass.md` | — | feature-006, feature-005 |
| The five scripts above | **Owns** | — |
| `canonical/aid/scripts/summarize/*` | Calls them **as installed** | **validator-parameterisation feature** owns every edit to them and whether any contingency fires |
| `tests/canonical/test-graph-runtime.sh` | **Owns** | — |
| Documentation, the registration suite, the ship gate, the Knowledge Base updates at ship | — | **tests-and-docs feature** |

One-sentence form: **this feature owns what the skill does; one sibling owns how it borrows, one owns how
it ships, and one owns how it is found and proved finished.**

#### The five scripts

All conform to `coding-standards.md`: `#!/usr/bin/env bash`, a Purpose / Usage / Exit-codes header block
with `-h|--help` reprinting a slice of it, `set -euo pipefail` for the writers and `set -uo pipefail` for
the read-only analysers, stdout for results and stderr for diagnostics with a `<script>: ` prefix
(:238, :240), configuration only through `read-setting.sh` (:250), `LC_ALL=C` on every sort, and no new
exit code (:226–:229).

| Script | Purpose | Exit codes |
|---|---|---|
| `graph-preflight.sh` | P1–P7 | `0` pass, `1` a prerequisite failed, `2` usage |
| `graph-stale-check.sh` | D2's six components, the verdict, the changed-component report | `0` for **every** verdict — the decision is informational; `1` an unreadable required input; `2` usage |
| `kb-write-fence.sh` | `--snapshot` / `--verify` (D3) | `0` clean, `1` violation with every path named, `2` usage **including a missing snapshot** |
| `grade-graph.sh` | Runs D4's rubric over the reused leaf validators, prints the check inventory then Machine / Human / Overall | `0` every grade it could compute meets the resolved floor, `1` one does not, `2` usage |
| `assemble-coverage-notes.sh` | D7's assembly | `0` written, `1` an assembly conflict with the offenders named, `2` usage |

**`grade-graph.sh` is a new orchestrator, not a fork (AC-17, C-4).** `grade-summary.sh` is specific to
`kb.html`: it hardcodes `KB_DIR=".aid/knowledge"` (:65), reads
`.aid/.temp/summarize/manual-checklist.json` (:67), and centres its pool on `COV` (:18, :26–:29). Reusing
it would import Knowledge Base completeness grading, which FR-28 forbids. Reuse therefore happens at the
**leaf validator** layer, where every check actually lives, and this orchestrator contains no copied
check body — a claim a reviewer can test by diffing the two orchestrators for shared check logic and
finding none (**SR09**). **`grade-graph.sh`'s exit code is keyed on the resolved floor, not on a
hardcoded band**, which is a deliberate divergence from its sibling's "`0` if Machine ≥ `A-`" (:13–:14): a
fixed band cannot express a project's configured floor, and the floor is already resolvable through the
one resolver.

### Migration Plan

Nothing existing changes shape, and this feature forks nothing. Two pre-existing inconsistencies are
worked around rather than fixed, because fixing either changes another skill's behaviour.

| Item | This feature's position |
|---|---|
| The unscoped approval grep | P2 reads `kb_status` first and scopes its legacy fallback. The disk truth and the reason are stated once, at P2; `/aid-summarize` is left as it is and reported upstream (Open Item 8) |
| The Node floor's fourth site | P5 asserts the floor the project already enforces at the three sites P5 names. A fourth site disagrees — `canonical/skills/aid-summarize/SKILL.md`:50 still says "Node.js >= 18" — and it is another skill's prose, reported and not edited (Open Item 8) |

**Deliberately left open.** Whether the render produces one file or a file plus companions depends on
FR-18 (STATE.md Q2); the allowlist entry W3, the `view_expected` predicate and the `V-*` rows are written
to accommodate either without change.

### Tests

Fixtures are self-built under `mktemp -d` and depend on no work folder's contents (**A-6**). The suite is
**`tests/canonical/test-graph-runtime.sh`**, discovered by `tests/run-all.sh`'s
`tests/canonical/test-*.sh` glob with no runner edit (`test-landscape.md`:29). Every assertion below
exercises a **script**; the prompt-driven state machine itself is not machine-tested, by project design
(`test-landscape.md`:279). Every assertion over a path D6 deletes at DONE observes it **before** the
deletion, whichever path and whichever assertion; the post-DONE absences are SR05's and SR12's subject.

| ID | Assertion | Criterion |
|---|---|---|
| **SR01** | each of P1–P7 refuses on a fixture built to fail it, exits `1`, names the required action, and **writes nothing** — asserted as an empty fixture diff, not merely as a message; and the fixture whose Knowledge Base is unapproved while `## Knowledge Summary Status` records `**User Approved:** yes` is **refused**, which is the P2 scoping fix and the one case the unscoped grep passes | **AC-11** |
| **SR02** | a fixture satisfying P1–P7 exits `0`; and a fixture with **no** `external-sources.md` also exits `0` with the notice on stderr — the non-refusal, without which AC-19 could not hold | **AC-11**, **AC-S4**, AC-19 |
| **SR03** | over a fixture where the first run **produced** both artifacts — asserted first: `relationships.md` non-empty with at least one data row and a `graph_inputs_digest` scalar, `graph.html` present, and the gap ledger present **where GAP-REPORT wrote it, before that same run's DONE deleted it** (D6) — the second run prints `CURRENT`, both artifacts are **byte-identical**, no dispatch record exists, and no file outside `.aid/.temp/` was written | **AC-12**, **AC-S4** |
| **SR04** | **at least one mutation per D2 component, and two where a component has two arms**: a Knowledge Base document (`kb`); an enumerated source artifact **and** an enumerated in-repo **image** (`src`, so a term that omits `media-nodes.tsv` fails); `external-sources.md` (`ext`); `.aid/settings.yml` (`cfg`); a vocabulary file (`vocab`); and both `tool` arms below. Each yields `STALE` and names **exactly one** component as changed, that component being the mutated one, with the other five values byte-unchanged. **`tool` is exercised on both of its arms** — once by editing an installed output-affecting file at an unchanged `aid_version`, and once by bumping `aid_version` alone with every installed file untouched — so an implementation carrying only one arm fails. Two negatives: mutating an **excluded** validator yields `CURRENT`, and adding an empty project vocabulary extension where none existed changes `vocab` | **AC-12**, **AC-S9** |
| **SR05** | `--reset` on the unchanged fixture of SR03 yields `STALE`, and afterwards both artifacts exist and no ledger from the previous run does | **AC-12**, **AC-S2** |
| **SR06** | over a run that produced both artifacts, the snapshot's path list contains `kb.html`, `INDEX.md`, `STATE.md` and every fixture Knowledge Base document, contains **no** allowlisted path, and is non-empty; and `--verify` then exits `0` | **AC-13**, **AC-S1** |
| **SR07** | `--verify` exits `1` naming the path after a fenced document is mutated, after one is deleted, and after one is added; and it exits **`2`** when no snapshot exists — the violation path and the fail-closed path are both the tested paths | **AC-13**, **AC-S1**, **AC-S4** |
| **SR08** | with `scale-ceiling.yml` set to a fixture value the fixture's node total exceeds, the run warns, the message carries both the total and the threshold, and the exit status is `0`; below the threshold no warning is emitted; and the idempotent path emits none. **The suite asserts no ceiling figure** — it writes the fixture's own | **AC-16a** |
| **SR09** | `grade-graph.sh` contains no check body found in `grade-summary.sh` — asserted as the absence of that script's check-implementing constructs and of its `COV`, `KB_DIR` and `manual-checklist.json` literals — while the run's inventory shows each reused validator was **invoked**, so "no duplication" cannot be satisfied by doing nothing | **AC-17** |
| **SR10** | over a fixture with all conventions present, the assembled section carries one row per `Kind` enum value in enum order with its status and count, all three exclusion rows in order with their **rendered labels** (so a key passed through verbatim fails), the field order of each table (so a pass-through of the TSV order fails), and the exclusions table carries **three** columns; a producer file missing one kind row exits `1` naming that kind; and a colliding extra key exits `1` naming both producers | **AC-20** |
| **SR11** | extra rows from **both** producer files appear below their table's fixed block in `LC_ALL=C` key order, interleaved by key rather than grouped by producer; the same inputs presented in reversed file order yield a **byte-identical** section; and no timestamp appears anywhere in it | **AC-20**, AC-5 |
| **SR12** | after DONE over a run whose gap ledger was **non-empty** — asserted before deletion — `graph.md`, `graph-kb-gaps.md` and `.aid/.temp/graph/` are all absent, `review-pending/` is removed if empty, and `relationships.md`'s `kb_gaps` still carries the **same id set** it held before; and the reproduce command the routing block printed is `/aid-graph --reset` and not a read-back | **AC-S2**, **AC-S3** |
| **SR13** | over a fixture whose artifact is deliberately broken in one way per rubric family, `graph.md` carries the expected rows with the severities D4 assigns — feature-003's column for an `R*` row, this rubric's rule for a `V-*` row — and `grade.sh` over that ledger prints the expected letter (one `[HIGH]` → `D+`, one `[MEDIUM]` → `C+`); over a clean fixture it carries **zero** rows and prints `A+`, **and** the inventory names **every** rubric row — none absent — with every `R*` row reported `run`, which needs no browser, so a gate that skipped its validators cannot reach `A+` | **AC-S4**, **AC-S5** |
| **SR14** | with Playwright absent, `V-T` is reported `skip`, emits no row, does not lower the Machine Grade, and the skip is repeated in the closing summary; **and where a drawing context is available it is reported `run`**, so an implementation that reports `skip` unconditionally fails. That second clause is environment-conditional and degrades with a recorded skip of its own, exactly as feature-008 handles its context-dependent assertions (its Open Item 4) | **AC-S5** |
| **SR15** | over a run that **produced** both ledgers, no grading invocation is given `graph-kb-gaps.md`'s path — asserted over the run's own commands — while `graph.md` grades `A+` even though the gap ledger holds `[HIGH]` rows, so the gap rows are unreachable by the gate rather than merely unread | **AC-S6** |
| **SR16** | `state-extract.md` states the empty tool set for **both** dispatch shapes and states that each pass's inputs are inlined; and `agent-pass.md`'s own clause is present, so the contract holds at both ends. This is the only mechanical check a prose contract admits, and it fails loudly if the clause the bound rests on is dropped | **AC-S7** |
| **SR17** | `--grade B` is accepted **and takes effect** — the run's printed floor is `B`, so an implementation that swallows the flag fails — `--grade Z` exits `2`, and neither invocation writes `.aid/settings.yml`, compared byte-for-byte before and after | **AC-S8** |
| **SR18** | on a fixture install whose `graph-skeleton.html` is absent, `view_expected` is false: no `graph.html` is written, `CURRENT` does not demand one, the `V-*` rows emit nothing, the human pool prints `N/A`, and the Overall Grade equals the Machine Grade | **AC-S10** |

**What is deliberately not tested here.** The state machine's prose routing (`test-landscape.md`:279 —
prompt-driven state machines are covered by dogfooding and human/AI review); the rule that a repair goes
to the input rather than to the generated artifact, which is FIX's prompt-driven behaviour and is stated
rather than asserted; every upstream mechanic each state invokes, which each owning suite asserts
(feature-003's V1–V15, feature-004's streams, feature-005's bounds, feature-006's GL01–GL20,
feature-007's GV01–GV28, feature-008's GC01–GC19, feature-009's TV series); the ledger/lens equality,
which is feature-006's and feature-007's mutual obligation; the runtime-prerequisite text, which is
GV23's; and every figure, which is feature-002's.

### Open Items

Each names its owner and its **Q26 class** — a **mechanism** item changes a contract, a field, an
interface, an exit code, an emitted value or an acceptance criterion's truth; an **editorial** item is a
real defect that is collected onto STATE.md's § Editorial queue and fixed in the Q24 item-9 batched pass.
An item that cannot be classified confidently is treated as mechanism. **Features 001–007 are frozen
(Q26 § Freeze), so an item against one of them needs an explicit owner decision, not an automatic
reopen.** None blocks this feature's implementation.

1. **NFR-8's comparand: a node count is implemented; the degree-aware form is the owner's call.**
   feature-002 D5 states the problem without resolving it — the dominant variable is **maximum degree**,
   so a bare node-count comparison warns on a large sparse graph and stays silent on a small hub-heavy
   one, and both quantities are computable from the same table (:740–:743, its Open Item 6 :1249–:1255).
   This feature implements the **node count**, because that is what NFR-8 and AC-16a literally say and
   changing it is a requirements amendment, never something a runtime decides silently. **Owner: the work
   owner**, on feature-002's recommendation. **Q26 class: mechanism** — it changes what AC-16a compares.
2. **Whether `Fixed` should be restored early by stashing `kb_gaps`, at the price of an interface
   change.** D6 sizes it: `Fixed` becomes derivable, `Recurred` stays undecidable, and `--previous`'s
   interface would have to change. Not adopted, on feature-006's own ground (:825–:836, its Open
   Item 2 :1199). **Owner: the work owner**, with **feature-006** (the interface) if it is wanted before
   D-6. **Q26 class: mechanism.**
3. **Pass-2 dispatch volume is one dispatch per Knowledge Base document, and batching is declined here.**
   Batching would keep the tool set empty while weakening the bound from a property of the dispatch shape
   to an instruction about inlined text (feature-005 Open Item 12, :1631). Every bound in its D6 is per
   row, so batching changes no contract — which is why the trade should be made deliberately rather than
   by drift if run time proves unacceptable. **Owner: the work owner**, on the evidence of a real run.
   **Q26 class: mechanism** — it changes what FR-31a part 1 rests on.
4. **The Pass-2 disposition count has no durable home, and this feature declines to give it one.**
   Routed here as the owner of the frontmatter scalars (feature-005 Open Item 10, :1618) after being kept
   out of the coverage notes for byte-identity. Declined: a third generator-written scalar is a schema
   addition to feature-003's D8 — frozen — for a number whose only consumer today reads one run's stdout.
   **Owner: the work owner**, with **feature-003** if the scalar is wanted. **Q26 class: mechanism** — a
   new frontmatter key is a contract.
5. **Where this runtime meets the validator-reuse parameterisation.** VALIDATE invokes the reused
   validators **as installed**, and D4's rows are unchanged whichever contingency fires (feature-007 Open
   Item 4, :1884, specifies the `contrast-check.mjs` pair). Two obligations are recorded so neither SPEC
   invents one: the reused scripts' **exit-code contracts** (`0` pass, `1` failure, `2` invocation) are
   what this orchestrator routes on, so a parameterisation must not change them; and a check that
   degrades must degrade to a **recorded skip**, never to a silent pass, which would defeat AC-S5.
   **Owner: the validator-parameterisation feature.** **Q26 class: mechanism.**
6. **`SKILL.md`'s `## References` section, and every packaging surface.** The pre-decision drafts of this
   feature and of the canonical-registration feature both claim `## References`; it is not resolved
   unilaterally here. The rule is **one writer per named section**, so whichever feature claims it authors
   it and the other does not, and `/aid-detail` must not produce two tasks editing those lines. Everything
   else in that area — the render, the manifest and count lockstep (C-3), the registration surfaces, and
   `README.md`, which no profile render ships — is that feature's outright. **Owner: the
   canonical-registration feature.** **Q26 class: mechanism** — it decides which task edits which lines.
7. **The coverage-notes hand-off path is declared here and read there.** `assemble-coverage-notes.sh`
   writes `.aid/.temp/graph/coverage-notes.md`; feature-005's step 15 renders "the `## Coverage notes`
   section assembled by feature-010" without naming a path (:1361–:1365), so naming it is this feature's
   and nothing in that SPEC contradicts it. Recorded as a confirmation rather than a change, because the
   SPEC that reads the file is frozen. **Owner: feature-005** (confirmation). **Q26 class: mechanism** —
   it fixes an interface.
8. **Two stale sites in `/aid-summarize`, neither fixed here** (Migration Plan): its `SKILL.md`:50 Node
   prose, and its preflight's unscoped approval grep (:30). Fixing either changes another skill's
   behaviour or documentation, outside this work's scope. **Owner: `/aid-summarize`** (upstream), with the
   **validator-parameterisation feature** if it is already editing that area. **Q26 class: editorial** for
   the Node prose, since the enforced floor is already 20 and nothing an implementer builds changes;
   **mechanism** for the grep, which is a real behavioural defect in that skill.
9. **A count standing in for FR-11's input set, in a frozen SPEC.** feature-005's § What guarantees
   FR-32 / AC-5 opens "with **all five** of FR-11's staleness inputs unchanged" (:1377) — the
   count-as-proxy pattern Q17 records and REQUIREMENTS corrected in four of its own clauses, stale since
   input 6. Nothing operative depends on it: that paragraph's mechanisms are enumerated locally and are
   correct, and this SPEC keys its digest on the list and never on a count. Reported, not fixed, per
   Q26 § Freeze. **Owner: feature-005**, by owner decision. **Q26 class: editorial.**
10. **Knowledge Base drift about the grade floor, found while resolving it.**
    `.aid/knowledge/quality-gates.md`:177–:182 gives the global as `review.minimum_grade: A+` with a
    per-skill `summary.minimum_grade: A+` override that "remains", CONFIRMED in `.aid/settings.yml`. On
    disk that file carries a **flat top-level** `minimum_grade: B-` (:6, the owner's lowering recorded at
    :9–:10) and **no per-skill block** — the drift is in the key's shape **and** its value. D1 reads the
    resolver, not the KB, so it is unaffected. **Owner: a `/aid-update-kb` delta**, or the
    **tests-and-docs feature** if it lands with this work's KB updates. **Q26 class: editorial.**
11. **The settings-schema half of FR-22's ignore list.** feature-004 owns the availability probe and the
    commented-out template seed; the **live** `graph:` declaration, the `format_version` question and the
    reconcile rule are routed to this feature and the canonical-registration feature (its D4a
    :1583–:1587, Open Item 8 :2218–:2224; STATE.md Q6, D-4). This runtime needs none of it: `cfg` hashes
    the file whatever it declares. **Owner: the canonical-registration feature**, with the **work owner**
    on the `format_version` bump. **Q26 class: mechanism** — a settings-schema version is a contract.

**Discharged here, and recorded so they are not re-routed.** **feature-003 Open Item 2** — the
`generator:` value — is discharged by accepting feature-003's own: `build-relationships.sh`, the script,
per `frontmatter-schema.md`'s rule and the `build-kb-index.sh` precedent; the draft's `aid-graph` is
withdrawn and this feature emits no competing value. **feature-003 Open Item 4** in both halves — the
vocabulary digest (D2's `vocab`) and input 6's form and file scope (D2's `tool`, resolved to **both**
forms, on the verified fact that a version string is exposed at `.aid/.aid-manifest.json` and the argument
that it cannot see an edited installed file). **feature-003 Open Item 14** and **feature-005 Open Item 16** — the
extra-row sort at assembly (D7, **SR11**). **feature-004 Open Item 7** in all three parts — the `src`
term covering both node streams, the ceiling warning counting all three producer streams, and the
exclusion key→label translation (D2, Feature Flow step 6, D7). **feature-005 Open Item 14** — the tool
restriction, enforced at the dispatch this feature constructs (**AC-S7**). **feature-006 Open Item 3** —
the retention correction (D6). **feature-007 Open Item 13**'s second half — NFR-8's warning is this
feature's, and it is emitted at Feature Flow step 6.

**Not open, and recorded so they are not reopened.** That both ledgers and the scratch die at DONE (Q8,
Q25 item 1, and the schema's own "Never" rule); that the gate's subject is this skill's own artifacts
only (FR-28); that there is no APPROVAL and no WRITEBACK state (AC-13); that staleness is
content-addressed with one component per FR-11 input (FR-11); that ENUMERATE precedes STALE-CHECK (FR-11
input 2); that severities for table-side checks are feature-003's column and not re-assigned here; that
the canvas carries no DOM-level assertion (Q9, feature-007 § Validator surface); and that this feature
writes no browser code, detects no media query and creates no store (feature-007 step 4).

**Figures.** **No quantity in this SPEC is a measurement.** Every quantity above is one of four things,
each labelled where it appears: a **contract count** (feature-003 D1's **ten** columns; the ledger
schema's **seven** columns; `grade.sh`'s modifier boundaries — one row, two to five, above five — read
from its `:96–:102`); a value **read from a cited artifact on disk** (every `:N` citation; the **30**
non-blank-line and `^❌ Pending` tests of `summarize-preflight.sh`:37–:57; the Node floor **20** at its
three verified sites; `grade-summary.sh`'s **`A-`** exit band at its `:13–:14`; the `aid_version` value
`.aid/.aid-manifest.json` carries today, quoted to establish that a version string **is** exposed and not
as a quantity anything here depends on); a **set cited rather
than counted** (FR-11's staleness inputs, §5.2's `Kind` enum, feature-003's validator table, the reused
validators' check ids, `PRESETS`' lens set); or **an enumeration made on the spot and reproducible from
the section that states it** — feature-006's class, adopted verbatim (its :1409–:1414) — which covers
D1's three arguments, D2's six components with their four `tool` areas and five exclusions, D3's five
allowlist entries and four fence properties, D5's one human check, D6's three lifecycle rows and four
consequences, D7's three rules, the **eleven** states of § State Machines' own table, the five
differences from `/aid-summarize`, the seven preflight checks, the five scripts, this SPEC's eleven Open
Items, its ten `AC-S<n>` criteria and its eighteen contiguous `SR*` assertions.

**Outside those four classes this SPEC produces no quantity at all** — no node count, no bench size, no
frame rate, no ceiling value, no payload, no duration, no line count of any artifact including its own or
a sibling's, and no severity tally other than the two worked grade examples in **SR13**, each
reproducible from `grade.sh`'s rubric as cited. The withdrawn delivery-001 bench and the withdrawn A-5
Knowledge Base figure appear **nowhere in this document**, in any form, not even to be retired — quoting
a figure in order to strike it is how the last one kept reappearing (Q20 (A-5 figure); Q23 instance 2).
No count stands in for a set another feature or an external file owns: FR-11's inputs are cited as a list
whose cardinality is explicitly not the contract, the `Kind` values as the enum, the validators as
feature-003's table, and the reused checks by their own ids — never as their cardinalities. Q19's second
direction was checked too: no count that **is** a contract was weakened into a citation.
