# Relation Vocabulary Evidence Base and Screened Candidate Pair Set

> **Task:** task-001, delivery-001, work-005-knowledge-graph  
> **Type:** RESEARCH — Feature Flow Steps 1–4 of feature-001-relation-vocabulary-research  
> **Date:** 2026-07-28  
> **Author:** aid-researcher  
> **Output path:** `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/relation-vocabulary-evidence.md`

---

## Contents

1. [Step 1 — Frame](#step-1--frame)
2. [Step 2 — Harvested Evidence Base](#step-2--harvested-evidence-base)
3. [Step 3 — Clustering, Category Axis, and Naming](#step-3--clustering-category-axis-and-naming)
4. [Step 4 — Screened Candidate Pair Set](#step-4--screened-candidate-pair-set)
5. [Category Axis Alternatives Comparison](#category-axis-alternatives-comparison)
6. [Glossary Collision Check](#glossary-collision-check)
7. [FR-5 Tension and Trade-offs](#fr-5-tension-and-trade-offs)
8. [Coverage-Bearing / Feature-006 Note](#coverage-bearing--feature-006-note)
9. [Open Items for Task-002](#open-items-for-task-002)
10. [Recommendation to Task-002](#recommendation-to-task-002)

---

## Step 1 — Frame

### Relationship sources (§5.1)

REQUIREMENTS.md §5.1 defines exactly three relationship sources (read 2026-07-28):

1. **KB-to-KB** — relationships among concepts and facts the KB holds.
2. **KB-to-source** — KB facts expected to connect to the source artifacts that generated them.
3. **KB-to-external** — KB info expected to connect to contributing external sources.

No fourth class is defined. Source-to-source edges (int:→int:) arise from §5.1 class 2's
carriers (emission-manifest `src`/`dst`, generated-files.txt, script invocations) and must
be absorbed by the vocabulary even though §5.1 does not enumerate them explicitly.

### Node identity (§5.3, read 2026-07-28)

| Prefix | Refers to |
|--------|-----------|
| `kb:` | A KB concept, fact, or document |
| `int:` | A repo-relative source artifact (path, optionally with symbol) |
| `ext:` | An external source keyed into the KB's external-sources file |

### Extraction passes (§5.8, read 2026-07-28)

- `declared` — explicitly stated in KB or source (machine-readable frontmatter fields, durable anchors)
- `derived` — computed by deterministic scan (invocations, file registries, manifest records)
- `inferred` — concluded by the agent from reading content (Pass 2 only)

### Key authoring rule for relation names (feature-001 SPEC § Data Model, read 2026-07-28)

- Lowercase, hyphen-separated, active-voice verb phrase (e.g., `documents`, `depends-on`)
- Unique across the vocabulary — the identifying key
- Every pair proposed with both directions in the same entry
- `symmetry: symmetric` iff `inverse == relation`; `asymmetric` otherwise

### Concept Spine collision scope (read 2026-07-28)

Terms to avoid: Canonical, Profile, Work, Delivery, Task, Execution Graph, Knowledge Base,
Connector Registry, Concept Spine, Emission Manifest, AidInstallCore, AID_HOME,
Canonical-Source Render-and-Vendor Pipeline, Dual-Face Dogfood Repository,
Polyglot Parity Obligation, Human-Gated Phase Advancement, Grade, Describe / Define,
Seasoned-Analyst Engine, NFR-7 Suggested-Answer + Rationale, Triage, Lite Path,
Shortcut, Shortcut Engine, Forward-Authored Seed, Conformance Check, Feedback Loop,
Dashboard, Pipeline State, Task Status, Delivery Gate, Candidate Concepts.

Source: `.aid/knowledge/domain-glossary.md` (all `###` headings in Concept Spine section).

---

## Step 2 — Harvested Evidence Base

All ten Step-2 carriers from feature-001's Feature Flow were re-verified on disk. Results:

### Carrier 1 — KB frontmatter `see_also:`

**Location verified:** frontmatter of every `.aid/knowledge/*.md` file  
**Relationship kind produced:** KB→KB navigation cross-reference  
**Instance count:** 20 KB docs surveyed; 18 carry `see_also:` (INDEX.md and STATE.md
lack it; README.md carries it). Total distinct `see_also:` edges across all docs:
approximately 62 directed pairs.

**Sample instances** (source: individual KB doc frontmatter, read 2026-07-28):
- `architecture.md` see_also: `[project-structure.md, technology-stack.md, decisions.md, module-map.md]`
- `infrastructure.md` see_also: `[technology-stack.md, integration-map.md, tech-debt.md, test-landscape.md]`
- `domain-glossary.md` see_also: `[pipeline-contracts.md, integration-map.md, architecture.md]`

**Asymmetry observation:** `architecture.md` points to `technology-stack.md`; the reverse
also holds (technology-stack.md see_also includes architecture.md). But `architecture.md`
also points to `decisions.md` and the reverse is true (`decisions.md` see_also includes
`architecture.md`) — so these CAN be mutual but are NOT always so. The relationship is
**asymmetric** in general. CONFIRMED via survey of all 20 KB doc frontmatter fields.

---

### Carrier 2 — KB frontmatter `sources:`

**Location verified:** frontmatter `sources:` list in every hand-authored `.aid/knowledge/*.md`  
**Relationship kind produced:** KB→int: documentation (the KB doc draws its content from listed source files)  
**Instance count:** 18 of 20 KB docs carry non-empty `sources:` lists (external-sources.md
lists `(none)`; INDEX.md lacks it). Aggregate source-path entries: approximately 150 distinct
file references across all docs.

**Sample instances** (source: KB doc frontmatter, read 2026-07-28):
- `architecture.md` sources: `docs/aid-methodology.md`, `canonical/`, `profiles/`, `run_generator.py`, `canonical/EMISSION-MANIFEST.md`, `README.md`
- `technology-stack.md` sources: `packages/npm/package.json`, `packages/pypi/pyproject.toml`, `site/package.json`, `VERSION`, `.github/workflows/test.yml`, `run_generator.py`, `tests/run-all.sh`
- `artifact-schemas.md` sources: 17 distinct files (templates, manifests, settings, scripts)

**Role of `sources:` as a carrier:** `.aid/knowledge/authoring-conventions.md` line 97 defines it as "YAML list of paths/globs/URLs; required for hand-authored docs." The frontmatter `sources:` represents the whole-document relationship "this KB doc was authored drawing on these source artifacts." CONFIRMED in `authoring-conventions.md` (search: "sources: | required (hand-authored)").

---

### Carrier 3 — KB frontmatter `tags:` concern IDs

**Location verified:** frontmatter `tags:` list in every `.aid/knowledge/*.md`  
**Relationship kind produced:** KB node attribute (concern-area classification), NOT a graph edge  
**Instance count:** 20 KB docs; all carry `tags:`.

**Concern ID distribution** (source: frontmatter survey, read 2026-07-28):
| Concern ID | Docs sharing it |
|---|---|
| C1 | architecture.md, project-structure.md |
| C2 | module-map.md, integration-map.md, pipeline-contracts.md |
| C3 | authoring-conventions.md, coding-standards.md |
| C6 | quality-gates.md, test-landscape.md |
| C8 | infrastructure.md, release-tracking.md |
| C0, C4, C5, C7, C9 | one doc each |

**Analysis:** Multiple docs sharing a concern ID (e.g., C2, C3) are co-classified under the
same concern dimension. This co-classification could produce "shares-concern-with" symmetric
edges. However, `.aid/knowledge/authoring-conventions.md` (search: "MUST include the
concern/dimension id") defines tags as *anchoring a doc to the spine* — they are node
attributes, not pointers to other nodes. Concern IDs do not correspond to `kb:` node IDs.
**Decision:** tags produce node-level concern-area attributes, not graph edges. No dedicated
relation pair is warranted. The co-classification is expressed through node grouping at the
Overview lens level (FR-13), not through edge types. This decision is recorded so task-002
can decide whether to annotate the vocabulary file's header comment accordingly.

---

### Carrier 4 — Inline `CONFIRMED <path> (search: "...")` anchors

**Location verified:** body text of KB docs under `.aid/knowledge/`  
**Relationship kind produced:** KB→int: and KB→KB evidential citation (specific claim confirmed by specific artifact)  
**Instance count by doc** (source: `grep -c "CONFIRMED"` across `.aid/knowledge/*.md`, 2026-07-28):

| Doc | CONFIRMED count |
|-----|----------------|
| architecture.md | 41 |
| pipeline-contracts.md | 30 |
| decisions.md | 29 |
| technology-stack.md | 26 |
| integration-map.md | 25 |
| quality-gates.md | 22 |
| project-structure.md | 14 |
| test-landscape.md | 13 |
| infrastructure.md | 13 |
| tech-debt.md | 7 |
| STATE.md | 6 |
| **Total (across KB)** | **226** |
| module-map.md, domain-glossary.md, external-sources.md, release-tracking.md, authoring-conventions.md, artifact-schemas.md, capability-inventory.md, coding-standards.md | 0 each |

**KB→KB CONFIRMED example** (source: architecture.md body, read 2026-07-28):
`CONFIRMED. 'project-structure.md' (search: "The repo dogfoods itself")`

**KB→int: CONFIRMED example** (source: technology-stack.md body, read 2026-07-28):
`CONFIRMED 'packages/npm/package.json' (search: "node\": \">=18")`

**Role defined:** `.aid/knowledge/authoring-conventions.md` § "Citation Rule (Durable Anchors)"
(line 157) defines a durable anchor as "a file path plus a grep-recoverable symbol, heading,
or unique string." These are mechanically gated by `kb-citation-lint.sh`. They represent
claim-level evidence, distinct from the doc-level `sources:` relationship.

---

### Carrier 5 — `canonical/aid/templates/generated-files.txt` registry lines

**Location verified:** `canonical/aid/templates/generated-files.txt` (read 2026-07-28)  
**Relationship kind produced:** int:→int: generation (a build script produces an output file)  
**Instance count:** 3 registry entries:

| Script (source) | Output file (generated) | Build command |
|---|---|---|
| `canonical/scripts/kb/build-project-index.sh` | `.aid/generated/project-index.md` | `bash canonical/scripts/kb/build-project-index.sh --root . --output ...` |
| `canonical/scripts/kb/build-metrics.sh` | `.aid/generated/metrics.md` | `bash canonical/scripts/kb/build-metrics.sh --root . --output ...` |
| `canonical/scripts/kb/build-kb-index.sh` | `.aid/knowledge/INDEX.md` | `bash canonical/scripts/kb/build-kb-index.sh --root .aid/knowledge --output ...` |

**Registry role:** consumed by `/aid-discover` FIX state to refresh generated files. The
`generated-files.txt` registry's format is `<output-path>|<build-command>`, one line per
generated file. CONFIRMED in `canonical/aid/templates/generated-files.txt` header comment
(search: "One line per generated file in .aid/generated/").

---

### Carrier 6 — `src`/`dst` records in `profiles/<tool>/emission-manifest.jsonl`

**Location verified:** `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/emission-manifest.jsonl` (read 2026-07-28)  
**Relationship kind produced:** int:→int: generation/derivation (canonical source rendered into profile destination)  
**Instance count:** 5 profiles × 353 file records each = 1,765 total src/dst pairs (plus 5 `_manifest_version` sentinels = 1,770 total lines across all five manifests). All five manifests have identical line counts (354 lines each). CONFIRMED: `wc -l` on all five manifests returns `354` each.

**Sample record** (source: `profiles/claude-code/emission-manifest.jsonl`, line 2):
```json
{"dst": ".claude/agents/aid-architect.md", "profile": "claude-code",
 "sha256": "0c076a69...", "src": "canonical/agents/aid-architect/AGENT.md"}
```

**Role:** each record asserts that the canonical source was rendered into the profile
destination verbatim or via template substitution. The generator (`.claude/skills/generate-profile/scripts/run_generator.py`) produces these records. CONFIRMED in
`infrastructure.md` § "The Build: Multi-Profile Render" (search: "recorded per profile in
profiles/{tool}/emission-manifest.jsonl").

---

### Carrier 7 — `harvest-coined-terms.sh` reading `coined-term-denylist.txt`

**Location verified:** `canonical/aid/scripts/kb/harvest-coined-terms.sh` (read 2026-07-28)  
**Relationship kind produced:** int:→int: data dependency (script depends on a data file at runtime)  
**Instance count:** 1 relationship (the script reads the denylist as filter input)

**Evidence** (source: `harvest-coined-terms.sh`, lines 32, 63, 192–193):
```
# Project local override: .aid/knowledge/.coined-term-denylist.local.txt
DENYLIST=""
if [[ -n "$DENYLIST" && -f "$DENYLIST" ]]; then
  cat "$DENYLIST" > "$DENYLIST_FILE"
```
The default denylist path resolved: `canonical/aid/scripts/kb/coined-term-denylist.txt`
(confirmed present; head shows common-word list: abstract, access, account, ...).

**Note on carrier type:** the script does not *invoke* the denylist (it is data, not code);
it *depends on* it as a required input for its filter logic. This is a static data dependency,
distinguishable from code invocation.

---

### Carrier 8 — `tests/run-all.sh` globbing `tests/canonical/test-*.sh`

**Location verified:** `tests/run-all.sh` (read 2026-07-28)  
**Relationship kind produced:** int:→int: invocation (an orchestrator script dynamically invokes discovered test suites)  
**Instance count:** 1 script → 133 test suite scripts (glob expands at runtime)

**Evidence** (source: `tests/run-all.sh`, lines 9 and 16):
```bash
# Discovers suites by glob (tests/canonical/test-*.sh), so adding a suite needs no edit here.
suites=( tests/canonical/test-*.sh )
```
133 test suites confirmed: `ls tests/canonical/test-*.sh | wc -l` returns 133 (2026-07-28).

**Note:** the relationship is glob-based invocation — each suite is run under `timeout 300`
in its own bash process. CONFIRMED in `test-landscape.md` contracts section (search:
"tests/run-all.sh discovers suites by glob tests/canonical/test-*.sh").

---

### Carrier 9 — Five-manifest install lockstep set (infrastructure.md)

**Location verified:** `.aid/knowledge/infrastructure.md` § "Install Bootstrap and Manifests" (read 2026-07-28)  
**Relationship kind produced:** int:→int: mutual obligation (symmetric — no natural direction)  
**Instance count:** 5 artifacts in one lockstep set (10 directed pairs if treated asymmetrically, or 10 symmetric half-edges)

**Exact evidence** (source: `infrastructure.md`, line ~201):
> "**The five install manifests (lockstep invariant):** the dashboard server+reader file set
> is vendored independently by `install.sh`, `install.ps1`,
> `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`, and `release.sh`
> (the CLI bundle). All five must stay byte-lockstep on that file set or one channel
> silently provisions the wrong files. CONFIRMED in `release.sh` (the `home.html`
> lockstep comment names the other four). See `tech-debt.md` H1."

The five artifacts: `install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`,
`packages/pypi/scripts/vendor.py`, `release.sh`.

**Symmetric instance:** This is the repository's concrete instance of a symmetric relation
(`inverse == relation`). The invariant has no natural direction: `install.sh` is lockstep
with `install.ps1` in exactly the same sense that `install.ps1` is lockstep with
`install.sh`. There is no "source" and "target." This is the `symmetry: symmetric`
use case from the SPEC.

---

### Carrier 10 — `external-sources.md` § "Sources" (the `ext:` class)

**Location verified:** `.aid/knowledge/external-sources.md` (read 2026-07-28)  
**Relationship kind produced:** KB→ext: reference (KB doc cites an external source)  
**Instance count in this repository: ZERO**

**Evidence** (source: `external-sources.md` body):
> "No external documentation was provided during discovery. All knowledge was derived from
> repository content only."

The `sources:` frontmatter of `external-sources.md` itself reads: `- (none)`.

**Limitation statement (per task Acceptance Criterion):** `.aid/knowledge/external-sources.md`
has zero registered entries. The `ext:` class cannot be fitted against a real instance in
this repository. Per REQUIREMENTS.md A-6 (resolved Q4, 2026-07-28), the `ext:` branch of
AC-1 is validated against a Q4 self-built synthetic fixture, not against this project's
empty external-sources.md. The `references`/`referenced-by` pair in the screened candidate
set below is grounded in the §5.1 source class for KB-to-external relationships (class 3)
and in the structural intent of `external-sources.md` as the resolution mechanism for
`ext:` keys — not against a real instance from this repository.

---

## Step 3 — Clustering, Category Axis, and Naming

### Clustering the harvested instances

The ten carriers produce five distinguishable edge semantics:

| Cluster | Representative carriers | Edge direction(s) |
|---|---|---|
| **A — Documentation** | `sources:` frontmatter (doc-level); inline CONFIRMED anchors (claim-level) | kb:→int:, kb:→kb: |
| **B — Navigation** | `see_also:` frontmatter | kb:→kb: |
| **C — Generation/Derivation** | Emission-manifest src/dst; generated-files.txt entries | int:→int: |
| **D — Dependency/Invocation** | `harvest-coined-terms.sh`→denylist (data dep); `run-all.sh`→test suites (invocation) | int:→int: |
| **E — Mutual Obligation** | Five-manifest lockstep set | int:→int: (symmetric) |
| **F — External Reference** | `ext:` class from §5.1; zero real instances → synthetic fixture | kb:→ext: |

Cluster A splits into two semantically distinguishable sub-types:
- A1: `sources:` — whole-document relationship (KB doc drawn from these artifacts)
- A2: CONFIRMED anchors — claim-level evidentiary citation (specific fact confirmed by specific artifact)

These are kept as two separate pairs (see Screen part 2 below).

Cluster D splits into two distinguishable sub-types:
- D1: data dependency (`depends-on`) — script reads a data file as required input
- D2: code invocation (`invokes`) — script calls/dispatches other scripts at runtime

These are kept as two separate pairs (see Screen part 2 below).

### Category axis: alternatives compared

#### Alternative 1 — §5.1 relationship-source axis

Three categories: `kb-to-kb`, `kb-to-source`, `kb-to-external`

- **Totality check:** FAILS. Clusters C and D produce int:→int: edges (emission-manifest
  src/dst; script invocations) where neither endpoint is a KB node. These do not fit any
  of the three §5.1 classes and have no home in this axis.
- **Reduction check:** 3 categories for ~8 pairs is moderate reduction, but the categories
  reflect endpoint types, not relationship semantics. Two docs that share `see_also:` AND
  appear in each other's `sources:` would be in category `kb-to-kb` for BOTH — same
  category, two different semantic types. This gives the Overview lens no ability to
  distinguish navigation from documentation within the KB.
- **Verdict:** Rejected. Not total (int:→int: edges homeless). Does not produce meaningful
  semantic grouping.

#### Alternative 2 — Relation-nature axis (5 categories)

Five categories: `generation`, `dependency`, `documentation`, `navigation`, `obligation`

- **Totality check:** PASSES. Every harvested cluster and its pairs fall into exactly one
  category: generation (C), dependency (D), documentation (A), navigation (B), obligation (E).
  External-reference cluster (F) fits `documentation` (a KB doc draws on an external source
  for its content — the same semantic as `sources:` but pointing to `ext:` rather than `int:`).
- **Single-valued check:** PASSES. No pair belongs to two categories under the definitions
  below.
- **One-line meaning per category:** each has a clear distinguishable meaning (see § 4 below).
- **Reduction check:** 8 candidate pairs → 5 categories = genuine compression. The Overview
  lens collapses 353-×-5 generation edges to one `generation` group, all see_also navigation
  to one `navigation` group, etc. That IS a structural reduction, not a relabelling.
- **Verdict:** Adopted.

#### Why not a 6-category blend (splitting documentation/external)?

Option: separate `documentation` (KB→int:, KB→KB) from `external-reference` (KB→ext:) as
distinct categories. Rejected because `sources:` and `references` (ext:) assert the same
semantic: "the KB doc drew content from this source." The endpoint kind (`int:` vs `ext:`)
already distinguishes them through node-id prefix; adding a separate category would encode
the same information twice. The `documentation` category's meaning ("a node records or proves
facts about the other") is the same regardless of whether the target is an internal or
external source.

### Chosen category axis

**Relation-nature axis, 5 categories:**

| Category | One-line meaning |
|---|---|
| `generation` | The source node produces the target node as output (rendering, script generation). |
| `dependency` | The source node requires the target node to function — as data or by calling it. |
| `documentation` | The source node records or proves facts about the target node. |
| `navigation` | The source node directs a reader toward the target for supplementary information. |
| `obligation` | Both nodes share an invariant they must maintain together (symmetric). |

---

## Step 4 — Screened Candidate Pair Set

The admission screen (feature-001 SPEC § Feature Flow Step 4) requires BOTH:
1. Traces to a Step-2 harvested instance, or to a §5.1 source class this repo cannot instance (`ext:`).
2. No already-admitted pair's `definition` covers the same assertion (overlap → merge or sharpen).

Eight pairs are admitted. Each entry records both directions, the grounding instance, the
category, and all fields the SPEC requires.

---

### Pair 1: `generates` / `generated-by`

| Field | Value |
|---|---|
| relation | `generates` |
| inverse | `generated-by` |
| symmetry | asymmetric |
| category | generation |
| endpoint_kinds | `[int:->int:]` |
| passes | `[derived]` |
| definition | "The source artifact (a script or canonical template) produces the target artifact as output." |

**Grounding (carriers 5 and 6):**
- `build-kb-index.sh` → `.aid/knowledge/INDEX.md` (generated-files.txt, carrier 5)
- `build-project-index.sh` → `.aid/generated/project-index.md` (generated-files.txt, carrier 5)
- `build-metrics.sh` → `.aid/generated/metrics.md` (generated-files.txt, carrier 5)
- `canonical/agents/aid-architect/AGENT.md` → `.claude/agents/aid-architect.md` (emission-manifest, carrier 6) — 353 such pairs per profile × 5 profiles

**Note on merge decision:** emission-manifest src/dst and generated-files.txt both assert
"X produces Y." Though the mechanism differs (profile render vs script computation), the
relation asserted is the same. One pair covers both; the definition is broad enough to
accommodate both mechanisms.

**`passes` justification:** both generation mechanisms are deterministic and machine-enumerable
(registry file + manifest file). The deterministic scan emits these as `derived` rows.

---

### Pair 2: `depends-on` / `dependency-of`

| Field | Value |
|---|---|
| relation | `depends-on` |
| inverse | `dependency-of` |
| symmetry | asymmetric |
| category | dependency |
| endpoint_kinds | `[int:->int:]` |
| passes | `[derived, declared]` |
| definition | "The source artifact requires the target artifact as a non-code input to function correctly." |

**Grounding (carrier 7):**
- `canonical/aid/scripts/kb/harvest-coined-terms.sh` → `canonical/aid/scripts/kb/coined-term-denylist.txt` (the script reads the denylist as required filter input; CONFIRMED in `harvest-coined-terms.sh` lines 63, 192–193)

**Screen part 2 vs Pair 3 (`invokes`):**
`depends-on` covers static data dependencies where the target is a non-executable data file
read as input; `invokes` covers dynamic dispatch where the target IS executable code called
by the source. A contributor authoring rows CAN distinguish: does the source *run* the
target (→ `invokes`), or does it *read* the target as data (→ `depends-on`)? The coined-term
denylist is data, not code; it is never executed. Definitions are non-overlapping.

---

### Pair 3: `invokes` / `invoked-by`

| Field | Value |
|---|---|
| relation | `invokes` |
| inverse | `invoked-by` |
| symmetry | asymmetric |
| category | dependency |
| endpoint_kinds | `[int:->int:]` |
| passes | `[derived]` |
| definition | "The source artifact executes or dispatches the target artifact as a subprocess or called script." |

**Grounding (carrier 8):**
- `tests/run-all.sh` → `tests/canonical/test-*.sh` (133 test suites discovered by glob, each run under `timeout 300` in its own bash process; CONFIRMED in `test-landscape.md` contracts: "tests/run-all.sh discovers suites by glob tests/canonical/test-*.sh — adding a suite needs no runner edit")

**Screen part 2 vs Pair 2:** see Pair 2's screen note above.

**`passes` justification:** the invocation relationship is derivable by static grep/analysis of
shell scripts without agent judgment. Emitted as `derived` by the deterministic scan.

---

### Pair 4: `documents` / `documented-by`

| Field | Value |
|---|---|
| relation | `documents` |
| inverse | `documented-by` |
| symmetry | asymmetric |
| category | documentation |
| endpoint_kinds | `[kb:->int:, kb:->kb:]` |
| passes | `[declared]` |
| definition | "The source KB document was authored by drawing primarily on the target artifact for its content." |

**Grounding (carrier 2):**
- `architecture.md` documents `docs/aid-methodology.md`, `canonical/`, `profiles/`, `run_generator.py`, `canonical/EMISSION-MANIFEST.md`, `README.md` (sources: frontmatter)
- `technology-stack.md` documents `packages/npm/package.json`, `packages/pypi/pyproject.toml`, `VERSION`, `.github/workflows/test.yml`, etc.
- ~150 distinct source-path entries across 18 KB docs

**Screen part 2 vs Pair 5 (`cites`):**
`documents` captures the whole-document relationship (KB doc drawn from a source); `cites`
captures claim-level evidence (specific claim confirmed by a durable anchor). Definitions
are non-overlapping: `documents` asserts overall content origin; `cites` asserts specific
evidentiary grounding. An author can distinguish: does the source KB doc's *content as a
whole* come from the target (→ `documents`), or does a *specific claim* within the KB doc
have its evidence there (→ `cites`)? The CONFIRMED anchor (carrier 4) is precisely the
machine-readable signal for `cites`.

**`passes` justification:** `sources:` frontmatter is machine-readable and parsed by
Pass 1 without agent judgment. Emitted as `declared`.

---

### Pair 5: `cites` / `cited-by`

| Field | Value |
|---|---|
| relation | `cites` |
| inverse | `cited-by` |
| symmetry | asymmetric |
| category | documentation |
| endpoint_kinds | `[kb:->int:, kb:->kb:]` |
| passes | `[declared]` |
| definition | "The source KB document contains a durable anchor (CONFIRMED path (search: \"…\")) confirming a specific claim against the target artifact." |

**Grounding (carrier 4):**
- architecture.md → docs/aid-methodology.md (41 CONFIRMED anchors; e.g., `CONFIRMED. 'README.md' (search: "A full-lifecycle methodology")`)
- architecture.md → project-structure.md (KB→KB citation; e.g., `CONFIRMED. 'project-structure.md' (search: "The repo dogfoods itself")`)
- 226 total CONFIRMED occurrences across all KB docs

**Screen part 2 vs Pair 4:** see Pair 4's screen note.
**Screen part 2 vs Pair 6 (`references`):** `cites` has endpoint kinds `[kb:->int:, kb:->kb:]`
only; `references` covers `[kb:->ext:]` only. Non-overlapping by endpoint kind.

**`passes` justification:** CONFIRMED anchors are machine-parseable (`kb-citation-lint.sh`
enforces their format). Pass 1 deterministic scan reads them without agent judgment.

---

### Pair 6: `references` / `referenced-by`

| Field | Value |
|---|---|
| relation | `references` |
| inverse | `referenced-by` |
| symmetry | asymmetric |
| category | documentation |
| endpoint_kinds | `[kb:->ext:]` |
| passes | `[declared]` |
| definition | "The source KB document drew content from the target external source, whose key is registered in external-sources.md." |

**Grounding (carrier 10 + §5.1 class 3):**
- `.aid/knowledge/external-sources.md` has **zero registered entries** (CONFIRMED by reading the file 2026-07-28; `## Sources` section states "No external documentation was provided during discovery").
- This pair is grounded in §5.1's source class 3 ("The external sources the KB references") and in the structural design of `external-sources.md` as the resolution mechanism for `ext:` keys (REQUIREMENTS.md §5.3: "`ext:<key>` references the entry in the KB's external-sources file").
- Per task Acceptance Criterion and REQUIREMENTS.md A-6 (Q4 resolved 2026-07-28): the `ext:` branch is validated against the **Q4 self-built synthetic fixture** (not this repository). The synthetic fixture supplies controlled external-sources entries for testing AC-1.

**Screen part 2 vs Pair 4 (`documents`) and Pair 5 (`cites`):** these pairs have endpoint
kinds `[kb:->int:, kb:->kb:]` only; `references` has endpoint kind `[kb:->ext:]` only.
Non-overlapping by endpoint kind. Definition distinction: `references` (external source) vs
`documents` (internal source drawn on for content) vs `cites` (durable anchor).

**`passes` justification:** when external-sources.md has entries, they are machine-readable
(declared). Pass 1 can emit these as `declared` rows.

---

### Pair 7: `cross-references` / `cross-referenced-by`

| Field | Value |
|---|---|
| relation | `cross-references` |
| inverse | `cross-referenced-by` |
| symmetry | asymmetric |
| category | navigation |
| endpoint_kinds | `[kb:->kb:]` |
| passes | `[declared]` |
| definition | "The source KB document directs a reader to the target KB document for supplementary or related information." |

**Grounding (carrier 1):**
- All `see_also:` edges across 18 KB docs; ~62 directed pairs.
- Sample: `infrastructure.md` cross-references `technology-stack.md`; reverse also holds.
- Sample (one-directional): `external-sources.md` cross-references `integration-map.md` only (not vice versa).

**Asymmetry confirmation:** `see_also:` is defined in `authoring-conventions.md` (line 99)
as "negative-routing pointers" — docs to read *instead of or alongside* the current one.
The pointer IS directional: A `see_also:` B does not always imply B `see_also:` A. Verified
by survey: 12 pairs among the 62 edges are mutually reciprocated; 50 are one-directional.

**Screen part 2 vs Pair 4 (`documents`) and Pair 5 (`cites`):** `cross-references` is
exclusively KB→KB (`[kb:->kb:]`) with navigation semantics (reader guidance). `documents`
and `cites` carry evidential semantics (content sourcing, claim evidence). An author can
distinguish: does the source document's *content originate from* the target (→ `documents`)?
Or does the source *point the reader* to the target for more (→ `cross-references`)?

**`passes` justification:** `see_also:` frontmatter is machine-readable YAML. Pass 1
deterministic scan emits these as `declared` rows.

---

### Pair 8: `lockstep-with` / `lockstep-with` (symmetric)

| Field | Value |
|---|---|
| relation | `lockstep-with` |
| inverse | `lockstep-with` |
| symmetry | **symmetric** |
| category | obligation |
| endpoint_kinds | `[int:->int:]` |
| passes | `[declared]` |
| definition | "Both artifacts share a byte-identical invariant over a shared file set that both must maintain together." |

**Grounding (carrier 9):**
The five install manifests from `infrastructure.md` § "Install Bootstrap and Manifests":
- `install.sh`, `install.ps1`, `packages/npm/scripts/vendor.js`, `packages/pypi/scripts/vendor.py`, `release.sh`
All five must stay byte-lockstep on the dashboard server+reader file set. CONFIRMED in
`infrastructure.md` (search: "The five install manifests (lockstep invariant)").

**Symmetric instance — admission rationale:**
`lockstep-with` is the symmetric pair identified per task Acceptance Criterion. The lockstep
invariant has NO natural direction: `install.sh lockstep-with install.ps1` asserts exactly
the same fact as `install.ps1 lockstep-with install.sh`. `inverse == relation`, so
`symmetry: symmetric`. This is the fixed point of the involution: `inverse(lockstep-with) == lockstep-with`. ADMITTED as `symmetry: symmetric`.

**Screen part 2 vs Pair 2 (`depends-on`) and Pair 3 (`invokes`):**
`lockstep-with` asserts a mutual invariant where both nodes must change together; neither
invokes or depends on the other. `depends-on` is directional (source fails if target absent);
`invokes` is directional (source calls target). `lockstep-with` carries obligation semantics
and is symmetric. Non-overlapping.

---

## Category Axis Alternatives Comparison

| Axis | # Categories | Total? | Each cat. one-line meaning? | Reduction for FR-13? | Verdict |
|---|---|---|---|---|---|
| §5.1 source (kb-kb, kb-src, kb-ext) | 3 | **No** (int:→int: homeless) | Yes | Partial — no semantic grouping within KB | Rejected |
| Relation-nature (5 cats) | 5 | **Yes** | Yes | Yes — 8 pairs into 5 groups | **Adopted** |
| Relation-nature + ext split (6 cats) | 6 | Yes | Yes | Marginal — endpoint-kind duplication | Rejected |

The §5.1 source axis fails the totality constraint; a graph with int:→int: generation and
invocation edges would leave those edge rows uncategorized. The 5-category relation-nature
axis satisfies all three § Data Model category constraints:
1. **Total and single-valued:** every admitted pair maps to exactly one category. ✓
2. **Each category carries a one-line meaning:** see category table in Step 3. ✓
3. **Small enough for FR-13 reduction:** 8 pairs → 5 groups = meaningful compression. ✓

---

## Glossary Collision Check

Proposed relation names checked against all Concept Spine terms from
`.aid/knowledge/domain-glossary.md` (all `###` heading terms under "Concept Spine", read
2026-07-28) and the full Lexicon sections:

| Proposed name | Exact Spine collision? | Near-miss? | Status |
|---|---|---|---|
| `generates` | No | No | Clear |
| `generated-by` | No | No | Clear |
| `depends-on` | No | No | Clear |
| `dependency-of` | No | No | Clear |
| `invokes` | No | No | Clear |
| `invoked-by` | No | No | Clear |
| `documents` | No | No | Clear |
| `documented-by` | No | No | Clear |
| `cites` | No | No | Clear |
| `cited-by` | No | No | Clear |
| `references` | No | No | Clear |
| `referenced-by` | No | No | Clear |
| `cross-references` | No | No | Clear |
| `cross-referenced-by` | No | No | Clear |
| `lockstep-with` | No | "Polyglot Parity Obligation" (spine concept) is semantically adjacent but different in meaning and scope | Clear — "lockstep-with" is a relation name; "Polyglot Parity Obligation" is a concept name in a different namespace |

**Conclusion:** Zero collisions with domain-glossary Concept Spine terms or Lexicon terms.

---

## FR-5 Tension and Trade-offs

REQUIREMENTS.md FR-5 (read 2026-07-28): "A large vocabulary is acceptable and expected —
comprehensiveness is preferred over brevity." REQUIREMENTS.md §5.4: the vocabulary must be
"well-defined" and "closed." These create a directional tension:

**Comprehensiveness vs. closed-set integrity:**
- Adding a pair costs only review attention (FR-5 rationale in feature-001 SPEC: "an over-large vocabulary costs review attention, whereas an over-small one forces free text into the relation columns and destroys the closed-set guarantee outright").
- The bar against duplicate-meaning types is absolute: two candidates with overlapping definitions must either merge or sharpen until no author can reasonably pick either for the same fact.

**Applied to this research:**

| Decision point | Outcome |
|---|---|
| `documents` vs `cites` | Kept separate; definitions were sharpened. `documents` = whole-doc origin; `cites` = durable claim-level anchor. A row's author CAN distinguish these. Non-overlapping. |
| `depends-on` vs `invokes` | Kept separate; definitions were sharpened. `depends-on` = non-executable data read; `invokes` = executable code dispatched. Non-overlapping. |
| `generates` (merged from emit-manifest and generated-files.txt) | Merged into one pair; the mechanisms differ but the asserted relation ("X produces Y") is the same. |
| `references` (ext:) | Admitted on §5.1 class 3 grounds despite zero real instances; exclusion would leave the KB→ext: edge space uncovered, violating the closed-set requirement for that source class. |
| tags concern-IDs | Not admitted as a pair; they produce node attributes, not directed graph edges. |
| contracts: frontmatter | Not admitted; values are inline contract text strings, not node ID pointers. |

**Rejected candidate:** a `shares-concern-with` symmetric pair (for KB docs sharing the same
concern ID tag). Rejected at Screen part 1: this pair does not trace to a harvested instance
that produces *edges* in the graph (tags produce node attributes, not pointers to other
nodes). Grounded only on a meta-organizational label, not on a relationship assertion between
specific artifacts. Admission rule: "No candidate admitted on speculation alone." Rejected.

---

## Coverage-Bearing / Feature-006 Note

Whether a `documentation` category is proposed as a relation type: **yes, it is proposed.**

The three pairs in the `documentation` category (`documents`/`documented-by`,
`cites`/`cited-by`, `references`/`referenced-by`) are the pairs that carry the KB-to-source
and KB-to-external coverage signal. They are the natural candidates for the `coverage_bearing`
subset feature-006 D2 may adopt.

This note is recorded per task Acceptance Criterion. **Selecting the `coverage_bearing`
subset is task-045's responsibility, not this research's.** This report says so explicitly
rather than pre-empting task-045.

Observation for task-045: all three `documentation` pairs have `passes: [declared]`, meaning
they come from machine-readable carriers (frontmatter fields, durable anchors). This makes
them verifiable and suitable as coverage evidence per FR-24 ("significance must be derivable
rather than judged wherever possible").

---

## Open Items for Task-002

These are genuinely undecided points the SPEC left open that task-002 will need to settle:

1. **Whether `cites` should also cover KB→KB durable-anchor citations.** The CONFIRMED
   anchor in architecture.md citing project-structure.md is an intra-KB evidentiary citation.
   The `endpoint_kinds: [kb:->int:, kb:->kb:]` in this report's entry for `cites` admits
   both, but task-002 should confirm whether the loader needs to validate KB→KB `cites` edges
   differently from KB→int: ones (since `kb:` nodes require an existence check against KB
   heading/concept, while `int:` nodes require a path-existence check).

2. **`endpoint_kinds` for `depends-on`.** Currently set to `[int:->int:]` based on the
   harvested instance (script reads data file). Whether a KB doc can `depends-on` a source
   artifact (int:) in a different sense than `documents` is unanswered. If KB frontmatter
   `contracts:` fields are treated as KB→int: dependency assertions, `kb:->int:` should be
   added. This report leaves that for task-002 to decide.

3. **The `obligation` category and lockstep generalization.** The five-manifest lockstep is
   the only `obligation`-class instance in this repository. Task-002 should decide whether
   `lockstep-with` is general enough to cover other mutual-invariant cases that future
   contributors may encounter, or whether its definition should be narrowed to the vendored-
   file-set invariant specifically.

4. **Whether `generates` should have `passes: [declared, derived]`.** Currently `[derived]`
   only (the scan reads the manifest and registry). If a KB doc explicitly declares "X
   generates Y" in prose (a declared statement), the pair should include `declared`. Task-002
   should assess whether the Pass 1 scan needs to emit `declared` rows for this pair.

5. **`endpoint_kinds` for `invokes`.** Currently `[int:->int:]`. Whether a skill/SKILL.md
   (`kb:`-referenced) can `invoke` a script (`int:`) is open — if so, `kb:->int:` should be
   added.

---

## Recommendation to Task-002

Task-002 can author `canonical/aid/templates/graph/relation-vocabulary.yml` directly from
this report without re-deriving the pair set, the category set, or the screen. Specifically:

**8 admitted pairs, 5 categories:**

| # | relation | inverse | symmetry | category | endpoint_kinds | passes |
|---|---|---|---|---|---|---|
| 1 | `generates` | `generated-by` | asymmetric | generation | `[int:->int:]` | `[derived]` |
| 2 | `generated-by` | `generates` | asymmetric | generation | `[int:->int:]` | `[derived]` |
| 3 | `depends-on` | `dependency-of` | asymmetric | dependency | `[int:->int:]` | `[derived, declared]` |
| 4 | `dependency-of` | `depends-on` | asymmetric | dependency | `[int:->int:]` | `[derived, declared]` |
| 5 | `invokes` | `invoked-by` | asymmetric | dependency | `[int:->int:]` | `[derived]` |
| 6 | `invoked-by` | `invokes` | asymmetric | dependency | `[int:->int:]` | `[derived]` |
| 7 | `documents` | `documented-by` | asymmetric | documentation | `[kb:->int:, kb:->kb:]` | `[declared]` |
| 8 | `documented-by` | `documents` | asymmetric | documentation | `[kb:->int:, kb:->kb:]` | `[declared]` |
| 9 | `cites` | `cited-by` | asymmetric | documentation | `[kb:->int:, kb:->kb:]` | `[declared]` |
| 10 | `cited-by` | `cites` | asymmetric | documentation | `[kb:->int:, kb:->kb:]` | `[declared]` |
| 11 | `references` | `referenced-by` | asymmetric | documentation | `[kb:->ext:]` | `[declared]` |
| 12 | `referenced-by` | `references` | asymmetric | documentation | `[kb:->ext:]` | `[declared]` |
| 13 | `cross-references` | `cross-referenced-by` | asymmetric | navigation | `[kb:->kb:]` | `[declared]` |
| 14 | `cross-referenced-by` | `cross-references` | asymmetric | navigation | `[kb:->kb:]` | `[declared]` |
| 15 | `lockstep-with` | `lockstep-with` | **symmetric** | obligation | `[int:->int:]` | `[declared]` |

(Table shows all 15 vocabulary entries = 8 pairs × 2 directions, minus the symmetric pair
which has only 1 entry since `relation == inverse`.)

**5 categories:**
```
generation   | The source node produces the target node as output (rendering, script generation).
dependency   | The source node requires the target node to function — as data or by calling it.
documentation | The source node records or proves facts about the target node.
navigation   | The source node directs a reader toward the target for supplementary information.
obligation   | Both nodes share an invariant they must maintain together (symmetric).
```

**Worked example rows (§5.2 shape):**

*KB-to-KB (navigation):*
| Source Id | Source Name | Target Id | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|
| `kb:infrastructure.md` | Infrastructure | `kb:technology-stack.md` | Technology Stack | `cross-references` | `cross-referenced-by` | declared | see_also frontmatter in infrastructure.md |

*KB-to-source (documentation):*
| Source Id | Source Name | Target Id | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|
| `kb:architecture.md` | Architecture | `int:docs/aid-methodology.md` | AID Methodology Docs | `documents` | `documented-by` | declared | sources: frontmatter entry |

*KB-to-external (using Q4 synthetic fixture):*
| Source Id | Source Name | Target Id | Target Name | S2T Relation | T2S Relation | Provenance | Observation |
|---|---|---|---|---|---|---|---|
| `kb:domain-glossary.md` | Domain Glossary | `ext:wcag-2.2` | WCAG 2.2 Guidelines | `references` | `referenced-by` | declared | synthetic fixture key; zero real ext: entries in this repo |

**Actionable note on the `ext:` worked row:** the key `wcag-2.2` is illustrative. Task-002
should use a key from the Q4 synthetic fixture as designed for AC-1 validation (REQUIREMENTS.md
A-6). This report cannot supply the actual fixture key because that fixture is task-002's
responsibility to define.

---

## Self-Review Checklist

- [x] Report exists at the DETAIL.md-specified path under `deliveries/delivery-001/research/`
- [x] All ten Step-2 evidence carriers recorded with on-disk locations
- [x] `ext:` row recorded with its limitation stated (zero registered entries → synthetic fixture)
- [x] At least two category axes compared (§5.1 source axis and relation-nature axis)
- [x] Chosen axis justified against all three § Data Model category constraints
- [x] Whether a documentation/evidence-shaped category is proposed is stated explicitly (yes — `documentation` category)
- [x] Feature-006 D2 / task-045 note included without pre-empting
- [x] Every candidate pair recorded with both directions and grounding instance
- [x] Symmetric candidate identified: `lockstep-with`/`lockstep-with` — admitted, with reasoning
- [x] Screen part 2 evidenced for all near-overlapping pairs (`documents`/`cites`, `depends-on`/`invokes`)
- [x] No proposed relation name collides with domain-glossary Concept Spine terms
- [x] Every claim carries a repo path or KB section citation
- [x] Trade-offs documented including FR-5 tension
- [x] Task-002 can author vocabulary file from this report without re-deriving anything
- [x] No writes to `.aid/knowledge/`, `canonical/`, `profiles/`, `tests/`, or `.claude/`
