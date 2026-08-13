# Declarations Across the Trees

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 2, §5 FR-1, FR-7 | /aid-define |
| 2026-08-13 | Second cross-reference pass: buckets re-derived to 159/123/8 = 290 (carve-outs netted out of the buckets, not only the total); field renamed to `review-criteria:` and the withdrawn `severity:` block removed; the `aid-monitor` README's assertion count corrected from one to **three**; the `contracts: []` set scoped to the **8** in scope; C-5's carve-out re-justified on `source: generated` rather than a kb-category neither doc has | /aid-define |
| 2026-08-13 | Technical Specification authored — 7 sections (deletion pass + prep, population walk + type resolution, authoring rule, `contracts: []` correction, on-disk data rename, AC-2 proof, out-of-scope). Application-software sections N/A | /aid-specify |
| 2026-08-13 | Grade gate: aid-reviewer. 1 MEDIUM (§5 "no KB doc gains the key" vs the 2 field-less docs — given explicit §4 disposition) + 1 LOW (kb-authoring/README dangling-link aside — flagged as pre-existing known issue). Both Fixed → **Grade A**. Ledger `review-archive/specify-feature-002.md` | /aid-specify |

## Source

- REQUIREMENTS.md §2 (coverage table), §4 (In Scope, stream 2), §5 FR-1, FR-7
- REQUIREMENTS.md §6 NFR-1, NFR-5; §7 C-1, C-2, C-3, C-4, C-5, C-6, C-7; §9 AC-1, **AC-2**, AC-5

*AC-2 is **shared**, not owned: all three features carry a planted-defect proof criterion for it, so all
three declare it here. An earlier draft carried the criterion without declaring the AC, leaving it
traceable from one feature only.*

*FR-5 is **defined** by feature-001 and **applied** here; it is not claimed twice. NFR-5 — every
declaration derivable from the repo alone — is carried here, because this is where declarations are
authored.*

## Description

With the criteria system built and read (feature-001), this feature is the **exceptions pass**, not
a population pass. Feature-001's global and per-type criteria already cover most files. This feature
walks the corpus, confirms every file resolves to a declared type, and writes a **`review-criteria:`**
block **only where a file has criteria or exclusions its type does not cover**. There is no separate
`severity:` block to write — FR-6 withdrew it, and severity rides on each criterion.

**Most files will end with no block, and that is the intended result.** A file whose type covers it
declares nothing; adding a block that restates a type-level criterion is the duplication the cascade
exists to prevent. How many files end up carrying one is an output of the walk, not a target.

This is also what dissolves the objection that a third of the corpus is unauthorable: a generated
`SKILL.md` rebuilt from `shortcut-catalog.yml`, and a template whose frontmatter slot already holds
the emitted artifact's block, both need **no per-file declaration at all** — their criteria live at
type level, in the KB, where nothing overwrites them.

The starting state — the **survey** of all 315 files, before the deletions and carve-outs that produce
the 290-file population further down:

| bucket | files | has frontmatter | declares a criterion |
|---|---|---|---|
| `skills/*/SKILL.md` | 76 | 76 | 0 |
| `skills/*/references/*.md` | 110 | 0 | 0 |
| `skills/*/README.md` | 11 | 0 | 0 |
| `agents/*/AGENT.md` | 9 | 9 | 0 |
| `agents/*/README.md` | 9 | 0 | 0 |
| `canonical/aid/templates` | 78 | 29 | 1 |
| `.aid/knowledge` | 22 | 22 | 9 |

**The feature opens by deleting, not by writing.** The 20 internal `README.md` files under
`canonical/skills/` and `canonical/agents/` are removed first — none of them ship to an adopter, 18
have no inbound reference at all, and authoring declarations into files that are about to be deleted
is wasted work twice over. That leaves **295** files in the population set, not 315.

Deletion is also a repair. `aid-execute/references/state-execute.md` → the “Mechanical sub-tasks” paragraph tells an
executor *"See `agents/aid-clerk/README.md` for the caller contract"*, and that path exists in no
installed tree — the line is replicated to all five profiles and both dogfood trees, so seven copies
of the pointer resolve to nothing. Two files therefore need preparation before removal: the
`aid-clerk` caller contract moves into `AGENT.md`, which does ship; and the **three** assertions in
`test-deploy-monitor-repurpose.sh` that read the `aid-monitor` README — `DMR00c` (it exists), `DMR03c`
(`BUG` → `/aid-fix`) and `DMR03d` (`Change Request` → `/aid-triage`) — are removed together with the
file. *An earlier draft named only `DMR00c`; removing one of three leaves the suite red.* Because the
two `DMR03*` assertions check **content** rather than existence, the routing mapping must be confirmed
to exist somewhere that ships before the README goes.

Then the population itself. After the 20 deletions and the 5 KB carve-outs — `STATE.md` per C-4,
`INDEX.md` and `relationships.md` per C-5, and the other two of the **three** `kb-category: meta` docs,
`README.md` and `external-sources.md` (`STATE.md` is the third) — **290** files remain, in three
disjoint buckets:

| bucket | files | edit |
|---|---|---|
| **No frontmatter block at all** | **159** | author a whole block — 110 `skills/*/references/*.md` plus 49 templates |
| **Block exists, declares nothing** | **123** | add the field — 76 `SKILL.md`, 9 `AGENT.md`, 28 templates, **10** KB docs |
| **Already declares** | **8** | **verify, do not assume** — 7 KB docs plus `reviewer-ledger-schema.md`. An existing declaration that has gone stale is the worst case: it reads as checked and is not. |

**159 + 123 + 8 = 290.** The carve-outs are netted out of the **buckets**, not only off the total — an
earlier draft wrote 159 / 126 / 10, which are the *survey* figures, and summed to 295 under a stated
total of 290. Where each carve-out sits, derived from its own frontmatter: `STATE.md` and `README.md`
carry no `contracts:` key and `external-sources.md` carries `contracts: []`, so **three leave the middle
bucket** (126 → 123); `INDEX.md` and `relationships.md` carry populated `contracts:`, so **two leave the
last** (10 → 8). The 159 is unchanged — no carve-out lacks frontmatter.

Of the **9** KB docs at `contracts: []`, `external-sources.md` is carved out, so **8** are in scope.
They include `architecture.md`, `tech-debt.md` and `pipeline-contracts.md`, whose stale claims were live
findings in `work-003`.

## User Stories

- As an AID user, I want the procedure files an agent actually executes to declare what they must be
  true against, so that a stale instruction is caught in review rather than followed.
- As an AID user, I want the documents defining how review works to be held to the same standard as
  everything else, so that the rules are not the one place nobody checks.
- As an AID user, I want files that exist for no reason removed rather than annotated, so that the
  amount of surface that can drift goes down instead of up.
- As an AID user, I want a declaration I can verify myself with the repo in front of me, so that
  "verified" never means "asserted somewhere I cannot reach".

## Priority

Must

## Acceptance Criteria

- [ ] Given the 20 internal READMEs, when this feature begins, then they are deleted **before** any
      declaration is authored, with the `aid-clerk` caller contract relocated to `AGENT.md` and **all
      three** `MONITOR_README` assertions (`DMR00c`, `DMR03c`, `DMR03d`) removed alongside their file
      (AC-5).
- [ ] Given `state-execute.md` → “Mechanical sub-tasks”, when the `aid-clerk` README is deleted, then it points at a path
      that exists in an installed tree. `site/src/data/skill-flows/aid-execute.flow.json` is a
      **generated** sidecar: it is regenerated in feature-003's single render, never hand-edited.
- [ ] Given the **290** files remaining after the 20 deletions and the 5 KB carve-outs, when the walk
      completes, then each **resolves to exactly one declared document type**, none is untyped, and
      every one falls into exactly one of the three buckets above — **and the three bucket counts sum
      to 290** (159 + 123 + 8), with the carve-outs netted out of the buckets and not only off the
      total (AC-1).
- [ ] Given a file whose type-level criteria already cover it, when the walk reaches it, then it is
      left **without** a `review-criteria:` block — a block restating a type-level criterion is a
      finding, not a completion.
- [ ] Given the **8 in-scope** KB docs at `contracts: []` (9 carry it; `external-sources.md` is carved
      out), when this feature completes, then each declares real criteria or states why it legitimately
      has none — an empty block is not a passing state.
- [ ] Given any authored `review-criteria:` entry, when a reviewer checks it, then the criterion is
      derivable by an agent with repo access alone — no network call, no credential, no reference to
      a work folder (NFR-5).
- [ ] Given C-4, when this feature enumerates files, then no `STATE.md` at any level in any folder
      receives a declaration or is reviewed.
- [ ] Given C-5, when this feature reaches `INDEX.md` and `relationships.md`, then they take
      build-verify rather than an authored content criterion **on the strength of `source:
      generated`** — both are `kb-category: primary`, not a meta category, so the carve-out cannot be
      justified by kb-category and is a decision of this work.
- [ ] Given a declaration authored in this feature, when it is checked against disk, then it holds —
      a false declaration is worse than none, because it reads as verified.
- [ ] **Proof (AC-2, method per NFR-1):** given a planted contradiction in a file populated by this
      feature, applied in a disposable worktree, when a real review runs, then the finding returns
      citing that file's criterion `id`.
- [ ] Given C-2, when this feature completes, then `profiles/` and the two dogfood trees have **not**
      been re-rendered per edit — the render happens once, at the end of the work.

---

## Technical Specification

*Section set.* Like feature-001, this is a documentation/data change — no database, service, API, or UI —
so the application-software sections are N/A. The content-bearing sections are: the **deletion pass and
its preparation**, the **population walk and type resolution**, the **authoring rule**, the
**`contracts: []` correction**, the **on-disk data rename**, and the **AC-2 proof**. This feature runs
**after** feature-001 (the schema and readers must exist first) and **before** feature-003 (the render).
Every path and count below was derived on this branch.

### 1. Deletion pass and its preparation (runs first)

Ordering is load-bearing: **delete before authoring**, so no declaration is written into a file about to
be removed. The 20 internal READMEs are `canonical/skills/*/README.md` (11) + `canonical/agents/*/README.md` (9),
verified `find canonical/skills canonical/agents -name README.md | wc -l` = 20, 1,802 lines.

**Two files need preparation before deletion, or deletion regresses:**

| prep | action | verify |
|------|--------|--------|
| `aid-clerk` caller contract | move it from `canonical/agents/aid-clerk/README.md` into `aid-clerk/AGENT.md` (which ships); then fix `canonical/skills/aid-execute/references/state-execute.md` line 166 ("Mechanical sub-tasks" → *"See `agents/aid-clerk/README.md`"*) to point at `AGENT.md`; the generated sidecar `site/src/data/skill-flows/aid-execute.flow.json` (1 ref) is **regenerated** in feature-003, never hand-edited | `grep -n "aid-clerk/README" canonical/skills/aid-execute/references/state-execute.md` currently returns line 166 |
| `aid-monitor` README | remove **all three** assertions in `tests/canonical/test-deploy-monitor-repurpose.sh` that read it — `DMR00c` (exists), `DMR03c` (`BUG`→`/aid-fix`), `DMR03d` (`Change Request`→`/aid-triage`); because the two `DMR03*` check **content**, confirm that routing mapping is stated in a shipping file (the skill's `SKILL.md`) before the README goes | `grep -n MONITOR_README tests/canonical/test-deploy-monitor-repurpose.sh` = 3 assertions (lines 66, 96, 97) |

18 of the 20 have zero inbound references (re-derived, both path-style and directory-style — see
REQUIREMENTS FR-7); only these two are reached. The delete set is `skills/` + `agents/` READMEs **only**.

*Pre-existing, out of scope, flagged not fixed:* 6 relative `](README.md)` links under
`canonical/aid/templates/kb-authoring/` (in `concern-model.md`, `domain-doc-matrix.md`, `principles.md`)
point at a `kb-authoring/README.md` that **does not exist on this branch** (`find
canonical/aid/templates/kb-authoring -name README.md` is empty). This is a dangling-link defect of the
same class this feature repairs, but it is a *missing* file, not one of FR-7's existing-README deletions,
so it is recorded as a known issue rather than fixed here.

### 2. The population walk and type resolution

After the 20 deletions and the 5 KB carve-outs, **290** files remain. Each is resolved to **exactly
one** type via feature-001's registry selector (exhaustive by construction), then placed in one of three
disjoint buckets:

| bucket | count | action |
|--------|-------|--------|
| no frontmatter block at all | 159 | author a whole block (110 `skills/*/references/*.md` + 49 templates) — **only if the file has criteria of its own** (§3) |
| block exists, declares nothing | 123 | add the field where warranted; 76 `SKILL.md`, 9 `AGENT.md`, 28 templates, 10 KB docs |
| already declares | 8 | **verify against disk, do not assume** — 7 KB docs + `reviewer-ledger-schema.md`; a stale existing declaration is the worst case |

159 + 123 + 8 = 290 (carve-outs netted out of the buckets, not only the total — see REQUIREMENTS AC-1).
The count that end up carrying a block is an **output, not a target**.

### 3. Authoring rule (the exceptions pass, not a population pass)

A file gets a `review-criteria:` block **only where it has a criterion or exclusion its type does not
already cover**. A block restating a type-level criterion is a **finding**, not a completion (it is the
duplication the cascade exists to remove). Generator-refreshed `SKILL.md` (58) and payload-carrying
templates get **no** file-level block — their criteria live at type level in the KB, where nothing
overwrites them. Consequently most of the 290 end with nothing, and that is the intended result.

Every authored entry must be **derivable by an agent with repo access alone** (NFR-5): no network, no
credential, no reference to a work folder.

### 4. The `contracts: []` correction, and the two field-less KB docs

Eight in-scope KB docs carry an explicitly empty `contracts: []` (9 on disk; `external-sources.md` is
carved out as `kb-category: meta`). Each must either declare real criteria or state why it legitimately
has none — an empty block is not a passing state. These include `architecture.md`, `tech-debt.md`,
`pipeline-contracts.md`, whose stale claims were live findings in `work-003`.

**The two in-scope KB docs that carry no `contracts:` key at all** — `capability-inventory.md` and
`release-tracking.md` (of the 4 field-less docs, `README.md` and `STATE.md` are carved out) — get an
explicit disposition here rather than being swept into the generic middle-bucket action:

| doc | frontmatter | disposition |
|-----|-------------|-------------|
| `capability-inventory.md` | `kb-category: primary`, `source: generated` | build-verify by its type; its content is generator output, not content-graded, so **no file-level block** — the `generated` type-level treatment covers it (C-5 generalised) |
| `release-tracking.md` | `kb-category: extension`, `source: hand-authored` | a cumulative release **log**; its rows are records of a moment (the same reason `check-skill-counts.mjs` excludes it). It takes a file-level **`exclude`** entry — *release rows are historical, not validated against current state* — with that `why` |

Neither is a case of "add the field where warranted" in the drift sense; each is resolved by its type or
by a declared exclusion, which is why §5's rename does not touch them.

### 5. On-disk data rename (`contracts:` → `review-criteria:`)

Feature-001 defines the rename and moves the emitters/parser/definitions; **this feature performs the
on-disk data rename** of the 18 field-bearing KB docs and the 4 test fixtures
(`tests/canonical/fixtures/{dual-intent ×2, kb-essence ×2}`). The 4 fixtures rename only if a consuming
test reads the field name; feature-001's coexistence parser keeps them valid until then.

**The rename adds no new key** — it touches only the 18 files that already have `contracts:`. Whether any
doc *gains* a `review-criteria:` block is a separate question, governed by §3's authoring rule and (for
the two field-less KB docs) resolved in §4 — not by this rename. So the two statements hold together: the
rename creates no KB-doc key, and `capability-inventory.md`/`release-tracking.md` are dispositioned in §4
rather than gaining one in the drift sense.

### 6. AC-2 proof (verification)

Per NFR-1, in a disposable worktree: a planted body-vs-`review-criteria` contradiction in a file this
feature populated returns as a finding citing that file's criterion `id`. The plant class is
self-announcing, so a forgotten one is caught by the next review. No maintained test is added.

### 7. Out of scope for this feature

The single render + dogfood resync (feature-003, C-2/NFR-4) — `profiles/` and the dogfood trees stay
stale until then, which is correct here. READMEs that ship to adopters (`profiles/*/README.md`,
`packages/*/README.md`) and READMEs with real consumers (KB `README.md`, `dashboard/`, `tests/`) are
**not** in the delete set — see REQUIREMENTS §4 Out of Scope. `check-skill-counts.mjs` retirement and
the front face are feature-003.
