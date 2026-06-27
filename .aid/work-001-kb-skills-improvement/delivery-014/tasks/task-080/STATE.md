# Task State -- task-080

> **Task:** task-080
> **Delivery:** delivery-014
> **Work:** work-001-kb-skills-improvement

---

## Task State

- **State:** Done
- **Review:** Pending
- **Elapsed:** --
- **Notes:** DESIGN-only task. Design of Record for FR-53 (Change 2) recorded below for task-081
  to implement mechanically. No canonical edits made (per scope). Grounded in the live
  `kb-actback-task.sh`, `concern-model.md`'s owning-table, the matrix's `spine-dimension` column,
  and `doc-set-resolve.md`. The byte-stable software baseline was captured by running the current
  script on the full 15-doc seed (see DoR §4) and the design is verified to preserve it.

---

## Quick Check Findings

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** _none yet_

---

## Design of Record

> **Scope:** the design task-081 implements mechanically for FR-53 (Change 2 — generalize the
> operational-sufficiency safeguard from filename-keyed -> spine-dimension-keyed). DESIGN only;
> no canonical edit lands here. Every path is `canonical/...` (DBI: edit canonical, never the
> rendered `.claude/` copy; regen via full `run_generator.py` is task-081's gate).

### 0. The defect being fixed (verified against the live script)

`canonical/aid/scripts/kb/kb-actback-task.sh` is filename-keyed + software-only in two places:

- **`_doc_expects_class` (lines 159-192)** — the owning-table is hardcoded software filenames:
  `Conventions -> coding-standards.md|module-map.md|pipeline-contracts.md`;
  `Invariants -> architecture.md|module-map.md|domain-glossary.md`;
  `Gotchas -> tech-debt.md`; `Contracts -> schemas.md|pipeline-contracts.md|integration-map.md`.
  On a `data-ml`/`design` doc-set NONE of these filenames are present -> every doc's `expected`
  flag is 0 -> the presence check emits **zero owning-table rows** (only opt-in auto-detected
  sections survive). The gate is provably inert off-software.
- **`_run_task` selector (lines 237-258)** — a filename profile (`has_schemas`, `has_module_map`,
  `has_feature_inventory`, …) that falls through to `task_type="endpoint"` when no software
  filename matches. A data/design doc-set degrades to "Add a new endpoint", which is meaningless
  for the domain.

The keying substrate already exists: `domain-doc-matrix.md` carries a `spine-dimension` column
(`C0`..`C9`, `D`, `meta`) for every doc in every row, and D-013 single-sourced the per-dimension
class mapping into `document-expectations.md`'s `## Spine-Dimension Depth Standards` "Owns named
section(s)" column (SD13: copied from `concern-model.md`'s owning-table, MUST-NOT-edit-independently).
This task consumes that substrate; it does NOT grow the spine, change the matrix domain set, touch
`synth_default_seed`, or touch the classifier (per AC-4 + SPEC §7 "Won't").

### 1. Re-keyed owning-table — `_doc_expects_class` from filenames -> spine dimensions

**1a. The authoritative dimension -> class mapping (the single source the script encodes).**
`concern-model.md`'s "The four operational-guidance classes" owning-table (lines 293-298) is
authored Class -> {Owning concern(s)}. Inverted to dimension -> {classes owned} it reads:

| Dimension | Owns operational class(es) | Source cell in concern-model.md owning-table |
|-----------|----------------------------|----------------------------------------------|
| **C1** Build & shape | Invariants | Invariants row -> "C1 Build & shape" |
| **C2** Parts & connections | Conventions, Invariants, Contracts | Conventions row "C2"; Invariants row "C2"; Contracts row "C2" |
| **C3** Conventions | Conventions | Conventions row -> "C3 Conventions" |
| **C4** Vocabulary | Invariants | Invariants row -> "C4 Vocabulary" |
| **C5** Data & contracts | Conventions, Contracts | Conventions row "C5"; Contracts row "C5" |
| **C7** Risk & debt | Gotchas | Gotchas row -> "C7 Risk & debt" |
| C0, C6, C8, C9, D, meta | (none of the four classes) | not named as an owning concern in any class row |

This inversion is **identical** to D-013's already-shipped `## Spine-Dimension Depth Standards`
"Owns named section(s)" cells (C1 `## Invariants`; C2 `## Conventions`+`## Invariants`+`## Contracts`;
C3 `## Conventions`; C4 `## Invariants`; C5 `## Contracts`+`## Conventions`; C7 `## Gotchas`) — so
the safeguard's owning-table and D-013's depth-standard column are the SAME inversion of the SAME
concern-model table. That consistency is the design's correctness anchor (consistent with SD13).

**1b. Single-sourcing form (so it cannot drift, mirroring SD13).** `_doc_expects_class` becomes a
`case "$dim" in` table whose body is the §1a mapping verbatim, with a mandatory header comment that
states it is COPIED from `concern-model.md`'s owning-table (inverted) and MUST-NOT be edited
independently — the exact SD13 convention D-013 used in `document-expectations.md`. The header
comment must enumerate the dimension->class rows so a reviewer/CI can diff it against the source
table. Shape (task-081 to author; ASCII, WinPS-irrelevant — bash):

```
# OWNING-TABLE (dimension-keyed). Single source: concern-model.md
# "The four operational-guidance classes" owning-table, INVERTED to dimension->classes.
# MUST mirror that table + document-expectations.md's "Owns named section(s)" (SD13). Do not edit independently.
#   C1 -> Invariants ; C2 -> Conventions,Invariants,Contracts ; C3 -> Conventions ;
#   C4 -> Invariants ; C5 -> Conventions,Contracts ; C7 -> Gotchas ; (others -> none)
_dim_owns_class() {            # was _doc_expects_class(doc, class); now (dim, class)
  local dim="$1" class="$2"
  case "$dim" in
    C1) case "$class" in Invariants) return 0 ;; esac ;;
    C2) case "$class" in Conventions|Invariants|Contracts) return 0 ;; esac ;;
    C3) case "$class" in Conventions) return 0 ;; esac ;;
    C4) case "$class" in Invariants) return 0 ;; esac ;;
    C5) case "$class" in Conventions|Contracts) return 0 ;; esac ;;
    C7) case "$class" in Gotchas) return 0 ;; esac ;;
  esac
  return 1
}
```

`_run_check` (lines 391-424) calls `_dim_owns_class "$dim" "$class"` instead of
`_doc_expects_class "$fname" "$class"`, where `$dim` is the doc's spine dimension from the substrate
lookup (§2). The opt-in auto-detect branch (a section physically present in a non-owner doc is still
reported `present`) is UNCHANGED — it is filename-independent and dimension-independent. Output row
shape stays `| doc | class | status |` (doc = filename, not dimension) so the table format and the
existing `closure-check.sh`-mirrored shape are byte-unchanged.

### 2. The doc-set substrate dimension-lookup contract (DECISION)

**Constraint.** `kb-actback-task.sh` consumes the doc-set TSV `filename<TAB>owner<TAB>presence`
(verified: `_parse_docset`, lines 199-211, reads field 1 only). `discovery.doc_set` and
`synth_default_seed` are BOTH three-field by contract (`doc-set-resolve.md` §"Field grammar" + the
matrix schema note "When a row is materialized into `discovery.doc_set`, the spine-dimension column
is dropped … recoverable from this matrix or `concern-model.md`"). So the dimension is NOT in the
substrate the script reads — it must be recovered.

**Two candidate forms (from the SPEC):**

- **(A) Extend the TSV with a 4th `spine-dimension` field** (`filename TAB owner TAB presence TAB dim`).
- **(B) Resolve `filename -> dimension` from a shipped lookup table** the script reads at runtime.

**DECISION: (B) — a shipped `filename -> spine-dimension` resolver, NOT a 4th TSV field.**

**Justification (lower-churn; works for ANY domain; preserves byte-stability):**

1. **Byte-stability of the substrate.** A 4th TSV field changes the wire format of
   `discovery.doc_set` AND `synth_default_seed`'s emitted TSV AND every existing test fixture
   (`tests/canonical/fixtures/actback-task/*.tsv` are all 3-field with a `filename owner presence`
   header). `doc-set-resolve.md` explicitly forbids growing the schema (`category`/`expectations`
   "intentionally absent … no-duplication"; the comma/pipe delimiter analysis is built around three
   fields). Form (A) would ripple into `read-setting.sh`'s comma-join/`|`-split round-trip, the four
   accessors, the matrix seed-consistency check, and every TSV consumer — a wide, schema-level churn
   the SPEC's "no spine/matrix/classifier change" + "byte-stable software seed" bars.
2. **The dimension is already canonical + recoverable.** The matrix is the authority for
   `filename -> spine-dimension`; the matrix schema note says the dropped column is "recoverable
   from this matrix or `concern-model.md`". A shipped resolver is the *recovery* the matrix note
   anticipates — not a new source of truth. Form (B) keeps the substrate single-sourced (the matrix)
   instead of duplicating the dimension into every persisted `discovery.doc_set` (which would drift
   from the matrix the moment the matrix is curated).
3. **Domain-general by construction.** The resolver covers EVERY filename any matrix row can emit
   (all 8 domains' rows: `data-schemas.md`->C5, `design-tokens.md`->C5, `content-model.md`->C5,
   `config-schemas.md`->C5, `style-guide.md`->C3, `ops-conventions.md`->C3, `data-pipeline.md`->C2,
   `component-inventory.md`->C2, `model-cards.md`->C9, …), so the presence check fires on the C5 doc
   of a data/design/content/ops project exactly as on software's `schemas.md`. A 4th TSV field would
   only carry a dimension if some upstream writer populated it — which `synth_default_seed` and
   hand-written fixtures do not.

**Substrate-contract change to record in `doc-set-resolve.md` (task-081's edit):** add a short
"Dimension recovery" subsection stating that `discovery.doc_set`/`synth_default_seed` remain
three-field, and that a consumer needing a doc's spine dimension (the safeguard) resolves it via a
shipped `filename -> spine-dimension` map sourced from `domain-doc-matrix.md` (matrix is authority;
the map is a rendered view kept lockstep with it, like the seed-consistency mirror). The TSV wire
format is explicitly UNCHANGED — the existing 4 accessors and all consumers stay green.

**Resolver mechanics (task-081 to implement; coreutils-only, ASCII, deterministic NFR-3).** A
function `_dim_of_filename FN` returning `C0..C9|D|meta|""`:
- **Primary:** a static `filename -> dim` table embedded in the script (or a shipped data file under
  `canonical/aid/scripts/kb/` read via grep/awk), enumerating every matrix-emittable filename ->
  its `spine-dimension` (the matrix is the source; a `test-domain-doc-matrix.sh`-style CI check, or a
  new assertion, diffs the embedded table against the matrix rows so it cannot drift — analogous to
  the matrix seed-consistency guard).
- **Fallback for an unknown/custom filename** (an `auto-researched` doc, or a project-renamed split
  like `module-map-frontend.md`): return `""` -> `_dim_owns_class` returns false for all classes ->
  the doc contributes NO owning-table rows but the opt-in auto-detect branch still reports any
  section physically present. This is the safe degradation (no false-absent on a doc whose dimension
  the script cannot prove), consistent with the existing scoping rule. Custom-doc dimension carriage
  (so a renamed C5 split still fires) is recorded as a follow-up note (§5), not built here — the
  matrix-sourced map covers all curated-row filenames, which is the AC's target.

### 3. C9-derived representative-task selector (replaces the hardcoded case-list)

**Today (lines 248-258):** a filename profile picks `task_type in {contract,module,component,
feature,endpoint}` defaulting to `endpoint`. Off-software it always yields "Add a new endpoint".

**Redesign — dimension-aware + C9-seeded selector.** The task becomes
"add / modify / extend «a capability the project actually has»", where the capability is read from
the **C9 doc** of the resolved doc-set, and the task body is framed by the **load-bearing dimensions
present** (C5 data/contracts, C3 conventions, C2 parts, C6 quality). Two layers:

- **3a. Identify the C9 doc deterministically.** Using §2's resolver, find the doc-set filename whose
  spine dimension is **C9** (software `feature-inventory.md`; data-ml `model-cards.md`/`feature-inventory.md`;
  design `design-overview.md`; content `content-inventory.md`; research `research-questions.md`;
  ops `service-inventory.md`; methodology `capability-inventory.md`). When multiple C9 docs exist,
  pick the **LC_ALL=C-first** filename among them (stable, deterministic — NFR-3). When NO C9 doc is
  in the doc-set, fall back to the dimension profile below (no C9 seed available).
- **3b. Derive the domain-appropriate task NOUN from the C9 doc + dimension profile, not a
  hardcoded "endpoint".** The selector emits a task whose verb is "add/extend" and whose object is
  the project's own unit-of-capability, chosen by the highest-priority load-bearing dimension
  PRESENT in the doc-set (priority C5 -> C2 -> C3 -> C9, mirroring today's "contract beats module
  beats component" order so software stays stable — see §4):
  - **C5 present (the doc realizing C5 exists):** "Add a new field / shape to «the C5 doc's primary
    data contract»" — software `schemas.md` -> a schema field; data-ml `data-schemas.md` -> a dataset
    column/feature; design `design-tokens.md` -> a token; content `content-model.md` -> a content-type
    field; ops `config-schemas.md` -> a config key.
  - **else C2 present:** "Add a new part and wire it in" — software a module; data-ml a pipeline
    stage; design a component variant; content a section/nav node; ops a service/deployment unit.
  - **else C3 present:** "Make a change that must follow the project's conventions" (convention-probe).
  - **else C9 only:** "Add a new capability of the kind «the C9 doc» catalogues."
  The C9 doc supplies the *domain noun* (what the project's capabilities ARE) so the task reads in
  the project's own terms; the dimension profile supplies the *change shape* so the task exercises
  the owning dimensions the presence check (§1) scores. Crucially the default is no longer "endpoint":
  with no software filenames but (e.g.) a `design` doc-set, C5=`design-tokens.md` is present -> "add a
  token", never "add an endpoint".

- **3c. Determinism (NFR-3).** The selector reads only the doc-set TSV (sorted, `_parse_docset`) and
  the C9 doc's filename (not its volatile body — the body is read by the act-back AGENT, not the
  script; the script only NAMES the C9 doc and the change shape). Same doc-set + same C9 filename ->
  byte-identical task spec. The script must NOT read the C9 doc's content to pick a *specific* named
  capability (that would be non-deterministic and is the agent's job under the M4 mandate); it names
  the C9 doc as the seed ("using «design-overview.md», pick a representative capability and …") and
  leaves the concrete pick to the clean-context agent. This keeps the script deterministic while
  making the probe genuinely C9-seeded and domain-appropriate — and aligns with D-015's probe
  derivation, which consumes this same C9 seed.

### 4. How software behavior stays byte-stable (verified)

**Baseline captured** by running the CURRENT script on the full 15-doc `synth_default_seed`
(`filename owner presence`, all required) against an empty KB dir:

- Task shape line: `**Task shape: contract**` (schemas.md present -> contract).
- Presence-check rows (10): `architecture.md|Invariants`, `coding-standards.md|Conventions`,
  `domain-glossary.md|Invariants`, `integration-map.md|Contracts`, `module-map.md|Conventions`,
  `module-map.md|Invariants`, `pipeline-contracts.md|Contracts`, `pipeline-contracts.md|Conventions`,
  `schemas.md|Contracts`, `tech-debt.md|Gotchas` (all `absent` on an empty KB).

**RED FLAG surfaced for task-081 — the dimension-keyed owning-table is NOT row-for-row identical to
the current filename table on software.** The current filename table is a *narrower* hand-assignment
than the faithful dimension inversion. Mapping the 15 seed docs through §1a yields these **extra**
expected rows vs the baseline:

| Doc | Dim | Current expected classes | Dimension-keyed expected classes | Delta (new rows) |
|-----|-----|--------------------------|----------------------------------|------------------|
| `project-structure.md` | C1 | (none — not in filename table) | Invariants | +Invariants |
| `module-map.md` | C2 | Conventions, Invariants | Conventions, Invariants, Contracts | +Contracts |
| `pipeline-contracts.md` | C2 | Conventions, Contracts | Conventions, Invariants, Contracts | +Invariants |
| `integration-map.md` | C2 | Contracts | Conventions, Invariants, Contracts | +Conventions, +Invariants |
| `schemas.md` | C5 | Contracts | Conventions, Contracts | +Conventions |

i.e. a literal dimension re-key would ADD 6 `absent` rows on the software seed — **NOT byte-stable.**
This is load-bearing and must not be glossed. The reconciliation, in order of preference:

1. **PREFERRED — adopt the dimension-keyed table as authoritative and RE-BASELINE the software
   fixtures' EXPECTED output, treating the 6 added rows as a correctness improvement, NOT a behavior
   regression.** Rationale: the concern-model owning-table (the single source) genuinely says C2 owns
   Conventions+Invariants+Contracts and C5 owns Conventions+Contracts; the current filename table is a
   pre-D-013 under-approximation. D-013's `## Spine-Dimension Depth Standards` already SHIPPED this
   exact fuller mapping as the depth floor (C2 owns all three; C5 owns Contracts+Conventions), so the
   safeguard and the depth standard are now CONSISTENT only under the fuller table — keeping the
   narrow table would make the safeguard DISAGREE with the just-shipped D-013 depth contract. The
   "same act-back behavior" the SPEC protects is **the task-shape selection + the gate firing
   non-empty on software** (both preserved — see below); the precise set of `absent` rows for an
   empty-KB fixture is test-internal, and on a REAL AID KB those sections exist so the rows read
   `present` either way. **This requires updating `test-actback-task.sh`'s software expected-rows
   assertions (AT08-AT13 region) to the 16-row set, which task-081 owns; flag explicitly at the
   D-014 A+ gate as an intended, single-sourced correctness change.**
2. **REJECTED alternative — keep a hand-curated per-doc software override table to reproduce the
   exact 10 rows.** This re-introduces the filename keying the feature exists to remove, makes the
   safeguard disagree with D-013's depth standard, and cannot generalize. Do not do this.

**What IS strictly byte-stable under either reconciliation (the behavior the SPEC's "same act-back
behavior" protects):**
- **Task shape on software = `contract`** — UNCHANGED. The §3b priority C5->C2->C3->C9 keeps
  `schemas.md` (C5 present) winning, exactly as the current `has_schemas -> contract` first branch
  (and AT07's "schemas wins over module" priority is preserved: C5 outranks C2). The task BODY text
  ("Add a new field to a data contract or schema") is unchanged for the contract shape.
- **The gate fires non-empty on software** — UNCHANGED (it fired on 10 rows; now 16, still non-empty).
- **`endpoint` default is reachable only when no C5/C2/C3/C9 doc is present** — software always has
  all of them, so software NEVER hits `endpoint`; the AT06 `endpoint` fixture (`tech-debt.md` only,
  C7) still yields `endpoint` because none of C5/C2/C3/C9 is present in that 1-doc fixture. AT06
  stays green. (Off-software the SPEC AC explicitly REQUIRES the non-endpoint task — that is the
  intended behavior change, not a regression.)

**Recommendation to the D-014 implementer (task-081):** adopt reconciliation (1); the 6 added
software rows are an intended, single-sourced correctness alignment with D-013, not a drift — gate
it as such. If the work's owner rules that the empty-KB software fixture rows MUST be byte-identical
(the strictest reading of "same behavior"), escalate at the gate, because option (2) is the only way
to honor that AND it contradicts the feature's own principle + D-013 — a genuine contradictory
constraint for human decision.

### 5. Affected files (task-081 — for reference; NOT edited here)

- `canonical/aid/scripts/kb/kb-actback-task.sh` — `_doc_expects_class` -> `_dim_owns_class` (§1);
  add `_dim_of_filename` resolver (§2); `_run_task` selector dimension-aware + C9-seeded (§3);
  `_run_check` calls the dim resolver per doc.
- `canonical/aid/templates/kb-authoring/concern-model.md` — add the inverted dimension->class
  restatement adjacent to the owning-table as the named single source the script mirrors (the prose
  edit; the §1a table is the exact wording).
- `canonical/skills/aid-discover/references/doc-set-resolve.md` — "Dimension recovery" subsection
  (§2): TSV stays 3-field; dimension recovered via the matrix-sourced resolver.
- `canonical/skills/aid-discover/references/reviewer-prompt-actback.md` — the four-class table +
  task-spec framing follow the dimension keying (per SPEC §2 affected-files).
- `tests/canonical/test-actback-task.sh` + minimal `data-ml.tsv`/`design.tsv` fixtures land in D-014
  (the substrate the owning-table + selector gates assert against); software expected-rows updated
  per §4 reconciliation (1).
- **Follow-up note (NOT this delivery):** custom/auto-researched doc dimension carriage — if a
  project renames or splits a C5 doc (`data-schemas-raw.md`), the matrix-sourced resolver returns
  `""` and the doc contributes no owning-table rows. The matrix-sourced map covers all curated-row
  filenames (the AC target). Carrying the dimension for arbitrary custom docs (e.g. a per-project
  `.review-checklist.md` extension, which concern-model already references for renamed sections) is a
  D-015/later enhancement, recorded so it is not lost.

### 6. Per-AC confirmation

- **AC-1 (owning-table restated in spine-dimension terms; single source the script encodes; exact
  wording fixed):** §1a fixes the exact dimension->class table (C1->Invariants; C2->Conventions/
  Invariants/Contracts; C3->Conventions; C4->Invariants; C5->Conventions/Contracts; C7->Gotchas),
  single-sourced from `concern-model.md`'s owning-table (inverted) and proven identical to D-013's
  shipped "Owns named section(s)" column; §1b fixes the SD13-style single-sourcing form + header
  comment. SATISFIED.
- **AC-2 (substrate dimension-lookup decided + justified; byte-stable seed + existing TSV-consumers
  preserved; `doc-set-resolve.md` contract change specified):** §2 DECIDES form (B) shipped
  matrix-sourced resolver over a 4th TSV field, with a 3-point justification (substrate
  byte-stability, matrix-as-authority/recoverable, domain-generality) and specifies the
  `doc-set-resolve.md` "Dimension recovery" subsection. TSV wire format unchanged -> all 4 accessors
  + consumers green. SATISFIED.
- **AC-3 (C9-derived selector; domain-appropriate not "add an endpoint"; deterministic):** §3
  specifies a dimension-aware + C9-seeded selector (3a C9-doc identification; 3b domain-noun-from-C9
  + change-shape-from-dimension-profile; default reachable only absent C5/C2/C3/C9, so non-software
  never gets "endpoint"); 3c proves determinism (script names the C9 doc + change shape, never reads
  volatile body -> same doc-set + same C9 filename -> byte-identical task). SATISFIED.
- **AC-4 (consumes D-013's dimension keying; no spine growth, no matrix domain-set change, no
  `synth_default_seed` touch):** §1a is proven identical to D-013's SD13 column; §2 keeps the matrix
  the authority and leaves the seed/schema untouched; the spine (11 dims) and matrix domain set are
  read, never modified. SATISFIED.
- **AC-5 (section-6 quality gates; DESIGN: proposal in STATE; no canonical edits -> no regen/DBI):**
  this is a DESIGN-only task — proposal recorded here, zero canonical edits, so no `run_generator.py`
  regen and no DBI run are due at this task. task-081 (the EXECUTE) carries the regen/DBI/ASCII/
  WinPS gates. SATISFIED.

---

## Dispatch Log

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
