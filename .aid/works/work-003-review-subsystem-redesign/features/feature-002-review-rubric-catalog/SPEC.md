# Review Rubric Catalog

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.B (FR-B4, FR-B5b, FR-B9), §9 (AC-3) | /aid-define |

## Source

- REQUIREMENTS.md §5 group B — FR-B4, FR-B5b, FR-B9
- REQUIREMENTS.md §9 — AC-3
- REQUIREMENTS.md §2 — problem 2 (the reviewer is licensed to use opinion)

## Description

Once severity means one thing, the next question is who decides which severity applies.
Today the reviewer decides, by judgment, every time. This feature moves that decision out
of the reviewer's head and into a written catalog.

The catalog holds rule sets, one per artifact class — code, spec, plan, task set,
requirements, documentation, release. Each rule is a row carrying four things: the check
itself, an anchor saying how to verify it, the severity that applies when it is violated,
and a named tag. A reviewer's job becomes matching a defect to a rule. The rule supplies
the severity.

This shape is not speculative. The Knowledge Base authoring rubric already works this way,
binding named tags to fixed severities, and it demonstrably produces confident, consistent
findings. It has simply never been extended to any other artifact class.

The feature also relocates something that should never have shipped where it did. AID's own
content-isolation rules — profile nesting, `aid-` prefixing, orphan-prune logic — are
currently hardcoded into the reviewer agent body, which renders into every adopter project.
A team reviewing their own application receives instructions about `.codex/aid/` layout and
copilot-cli `.github` scoping. Those rules belong in the catalog as an AID-specific artifact
class, not in the universal agent.

## User Stories

- As an **adopter project**, I want each finding to name the rule it violated so that I can look the rule up, agree or disagree with it, and change it if it is wrong.
- As an **AID maintainer**, I want severity to be a lookup rather than a judgment so that finding quality stops depending on how a reviewer felt that day.
- As an **adopter project**, I want my reviews to apply my project's rules and not AID's internal layout conventions.
- As a **pipeline agent**, I want a routing table from artifact class to rule set so that I know which rules apply before I start reviewing.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-3** — Given a deep review, when it produces a finding, then that finding cites the catalog rule that justifies its severity; a finding with no rule reference is rejected.
- [ ] Given the catalog, when I inspect any rule row, then it carries all four elements: the check, an evidence anchor, a severity anchor, and a named tag.
- [ ] Given an artifact of a known class, when a review begins, then the routing table resolves it to exactly one rule set.
- [ ] Given a rule set, when I read it, then it declares which checks are mechanical (evidence must be a runnable command) and which are named judgment surfaces.
- [ ] Given a defect that matches a rule, when severity is assigned, then it is taken from the rule and not chosen by the reviewer.
- [ ] Given the rendered `aid-reviewer` agent in an adopter project, when I read it, then it contains no AID-specific content-isolation rules.
- [ ] Given AID's own artifacts under review, when content isolation is checked, then the rules are applied from the catalog's AID-specific entry.

## Notes for Specify

- **Blocked on an open decision (STATE.md Q7 #1).** AC-3 requires every finding to cite its rule, but REQUIREMENTS.md §4 freezes the 7-column ledger set and no column holds a rule reference. The options are: embed the tag in Description or Evidence by convention, overload the `#` column, or amend the column set. **This must be resolved before this feature is specified**, because it determines the shape of every rule row. The same unsolved problem blocks the source tags (`[CODE]`, `[TASK]`, `[SPEC]`, `[KB]`, `[ARCHITECTURE]`) the reviewer already mandates — solve both together.
- **This feature edits `canonical/agents/aid-reviewer/AGENT.md`** — it inverts "Severity is your judgment" to severity-as-lookup (FR-B5b) and removes the content-isolation section (FR-B9), including the dangling `content-isolation.md` citation, which references a KB document that does not exist anywhere in the repository.
- Model the rule-row schema on `canonical/aid/templates/kb-authoring/review-rubric.md`, including its density rule ("one occurrence MINOR, widespread MEDIUM" — note this crosses a band, not just a modifier) and its force-floor precedent (`[TEACHBACK]` caps the grade at D).
- Verify five-profile render parity at feature close (STATE.md concern N3).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Adapted sections — this is a methodology
> artifact, so the standard runtime-dependent sections are dropped (no store, no request
> flow, no DI container, no network or UI surface).

### 1. Catalog anatomy and the rule-row schema

New directory `canonical/aid/templates/review-rubrics/` holding `INDEX.md` plus one file
per artifact family, plus class files where a class has criteria a family does not cover.

`kb-authoring/review-rubric.md` **stays where it is** and is referenced from `INDEX.md`
rather than moved — it has roughly eight inbound pointers and belongs to the
`aid-discover` bundle. Its per-check anchors are re-derived in place.

**The rule row — seven cells.**

```
| Rule | Check | Criterion | Modality | Mode | Evidence | Severity |
```

| Cell | Contract |
|---|---|
| **Rule** | The rule ID. This value goes in the ledger's `Rule` column. Format in §2. |
| **Check** | One sentence, stated **positively** — the assertion that must hold. A finding is always "this Check is false here". |
| **Criterion** | A durable citation to the KB doc or spec doc that *declares* the rule. **No Criterion, no row.** This is what stops the catalog becoming a third source of truth. |
| **Modality** | `MUST` / `SHOULD` / `COULD`, copied from the criterion, never invented. |
| **Mode** | `mechanical` or `judgment`. Mechanical rows must carry a runnable command in Evidence; judgment rows must name the surface read and what is read off it. |
| **Evidence** | Per Mode. |
| **Severity** | One of exactly two forms — never prose. Below. |

**The severity anchor has exactly two legal forms.**

Feature-001's scale makes MUST-band severity a function of modality × blast radius ×
reversibility. Modality is knowable when the rule is authored; the other two are
**instance** facts. So a rule cannot always pin one token, and pretending otherwise would
contradict the canonical scale on the first row.

- **Fixed** — a single bracketed token, when the violation always has the same
  radius/reversibility shape. May carry a stated escape threshold. The cell must match
  oracle (e)'s regex in §13, so the only legal escape form is
  `[LOW]; escaped (>1 doc) → [MEDIUM]` — a bracketed token first, never a modality prefix.
- **`Step 2`** — modality is MUST; the two axes are read off the instance per
  `canonical/aid/templates/grading-rubric.md#severity-scale`.

`Step 2` is not a judgment escape hatch: feature-001 made both axes evidence-bearing
(*name the dependent, or the radius is confined*), so the reviewer evaluates two checkable
predicates.

**No force-floor form.** The `· floor:<GRADE>` annotation considered during design was
dropped: `[TEACHBACK]` and `[ACTBACK]` anchor `[HIGH]`, which lands the grade in D-range by
ordinary arithmetic. A catalog feature that looks mechanical but is honoured only by
convention is exactly what this work exists to remove.

**Density is not a separate mechanism.** The KB rubric's "MINOR per occurrence, MEDIUM if
widespread" dissolves when re-derived: those checks are SHOULD-modality, so feature-001's
Step 1 already gives `[LOW]` escaping to `[MEDIUM]`. Where a concrete count is needed it
becomes an escape threshold inside the Severity cell, in scale vocabulary.

### 2. Rule ID namespace and source-tag subsumption

**`<CLASS>-<NN>`** — an uppercase class token, a hyphen, a two-digit sequence unique within
the class. Never reused after retirement.

```
^[A-Z]{2,12}-[0-9]{2}$
```

Single hyphen, no spaces, no pipes — greppable, sortable, and safe inside a markdown cell.
Two digits caps a class at 99 rules; needing more is a signal to split the class.

**The class prefix *is* the source tag.** `[CODE]`→`CODE-*`, `[TASK]`→`TASK-*`,
`[SPEC]`→`SPEC-*`, `[KB]`→`KB-*`. The tag stops being a second thing the reviewer asserts,
so it can no longer contradict the rule.

**`[ARCHITECTURE]` is retired.** It was never an artifact class — it was a *criterion
source* wearing an artifact-tag costume. An architecture finding is always a finding about
code or a spec whose criterion happens to be an architecture mandate, and the Criterion
cell now records that. This also closes a live inconsistency: `aid-reviewer/AGENT.md` and
its README mandate five tags including `[ARCHITECTURE]`; `reviewer-guide.md` defines only
four and omits it.

Two further contracts:

- **Non-finding rows carry `--`** in the Rule column, mirroring how feature-003's `U-NNN`
  and `G-NNN` rows carry `--` in Severity. Coverage rows have no rule.
- **One rule per row.** A defect violating two rules produces two rows. No comma-separated
  lists — the cell stays single-valued, greppable, and countable.

### 3. Review kinds and the two-ladder authority model (FR-B11)

**AID already implements five kinds of review. The catalog names them, and every class
declares which it takes.** Only kind A needs rule rows.

| Kind | What it does |
|---|---|
| **A** | Adversarial content grade — agent grades content, severity findings, `grade.sh` computes the letter |
| **B** | Build-verify only — re-run the generator and diff; content grading skipped, the script is the authority |
| **C** | Spot-check snapshot — current-value fields only; history and ledger rows explicitly not graded |
| **D** | Mechanical gate — a script passes or fails; no agent, no rule rows |
| **E** | Machine score plus a mandatory human checklist |

**Every class also declares two authority ladders**, because the sources of truth shift by
phase:

- **Intent** — *what must this artifact achieve?* Accumulates as the pipeline advances:
  user → REQUIREMENTS → SPEC → BLUEPRINT → DETAIL.
- **Manner** — *how must it be built?* The Knowledge Base. Constant, except during Discover
  where the KB is the artifact being produced and therefore cannot judge itself.

**Conflict rules.** Manner outranks intent on *how*; intent outranks manner on *what*. A
conflict *between* ladders is never the reviewer's to resolve — surface both, escalate.
Within a ladder, the higher rung wins: **artifact versus KB, the KB wins.** Two sources at
equal rank (SPEC versus PLAN) — surface both, pick neither.

Per-class declarations:

| Class | Kind | Intent authority | Manner authority |
|---|---|---|---|
| `KB` | A | User's confirmed statements, then external documents | AID's KB-authoring rubric |
| `REQ` | A | User's confirmed statements | KB |
| `SPEC` | A | REQUIREMENTS | KB |
| `PLAN` | A | SPEC, then REQUIREMENTS | KB |
| `TASK` | A | SPEC / BLUEPRINT | KB |
| `CODE` | A | Task DETAIL's ACs, then SPEC | KB |
| `TEST` | A | The ACs under test, then SPEC | KB (`test-landscape.md`) |
| `DATA` | A | Declared schema | KB (`schemas.md`) |
| `AID` | A | AID's own requirements | `authoring-conventions.md`, `EMISSION-MANIFEST.md` |
| `SUMMARY` | A + E | The KB it summarises | `knowledge-summary/grading-rubric.md`, re-derived as rules |
| `SETTINGS` | D | The user's stated configuration | The settings schema |
| `INDEX`, `METRICS`, `PROJECT-INDEX` | B | — | The generating script |
| `STATE` (all levels) | C | — | The state template's enums |

`SUMMARY` is the only class carrying **two** kinds. That is deliberate and stated here so
it does not read as an error: its machine and human gates remain (kind E), and feature-007
adds an adversarial content pass (kind A). Feature-002 authors the rule set both use.

> **Amended 2026-07-27 at feature-007's request.** `review-rubrics/summary.md` must carry
> **content-truth rows**, not only Presentation-family rows — the summary is graded on whether
> what it says is *true against the KB it summarises*, which is its declared intent authority
> above. `SUMMARY` stays in the **Presentation** family (an artifact resolves to exactly one
> rule set), so the borrowed claim–evidence and durable-citation criteria live in the class
> file rather than by inheriting NARRATIVE. If `summary.md` is not authored with those rows,
> feature-007's FR-F2 has no rule set and becomes a criteria gap.

### 4. Artifact families and the routing table

The artifact set is **not exhaustive and is not meant to be.** An artifact matching no
class is a **criteria gap**, not a defect — so the catalog need not be complete to be
correct, only honest about its edges. Families are what let it grow without duplication.

**Three tiers:** universal (the defect taxonomy, the two ladders, severity derivation,
evidence admissibility — declared once in `INDEX.md`) → family → class.

| Family | Members | Shared criteria |
|---|---|---|
| **Definition** | REQ, SPEC, PLAN/BLUEPRINT, TASK | Traceability upstream, testable criteria, modality tagged, no implementation prose |
| **Executable** | CODE, TEST, CONFIG, INFRA, JOB, PIPELINE, MIGRATION | Build/lint/test green, convention compliance, contract conformance |
| **Interface** | API, CLI, MESSAGING, DATA MODEL, SCHEMA | Declared contract honoured, versioning, backward compatibility |
| **Presentation** | UI, THEME, DASHBOARD, DIAGRAM, SUMMARY | Design tokens, accessibility, responsive behaviour, state coverage |
| **Narrative** | KB, DOCUMENTATION, REPORT, RESEARCH, ADR | Claim-evidence discipline, durable citations, audience fit, single concern |
| **Process** | TICKET, RELEASE, SPIKE, PROTOTYPE | Scope stated, exit criteria defined, disposability declared |

**Graduated fallback (decision taken).** An artifact whose *family* is clear but whose
*class* is unregistered is reviewed against the **family's** declared rules, and the missing
class rule set is recorded as a **non-blocking** gap. Only when no family fits does it
become a full criteria gap. No invention occurs either way — family rules are declared
rules, merely less specific. This softens the earlier hard-halt rule deliberately, so the
catalog is useful from day one rather than after every class is authored.

**No catch-all rule set.** A `GEN` family-of-last-resort was considered and rejected: it
becomes the place reviewers reach when nothing fits, and "established best practice" grows
back inside it.

**Routing key — artifact selector × producing skill**, following the KB rubric's proven
`kb-category × source` precedent. Lives in `review-rubrics/INDEX.md`.

The `AID` class is guarded by the presence of `canonical/EMISSION-MANIFEST.md` at repo
root, which exists only in AID's own repository. The rules ship to every adopter but are
**unreachable** there — which is the structural fix FR-B9 asks for.

**Ship first:** the six families, plus class rule sets only where a declaring document
already exists. Everything else inherits its family and accumulates class rules as the
project declares them — the same improvement loop, applied to the catalog itself.

### 5. The universal defect taxonomy

Declared once in `INDEX.md`, inherited by every kind-A rule set. **Ordered by severity,
first match wins**, so two reviewers classify the same defect identically and no
arbitration is needed.

| # | Class | The artifact… | Modality | Anchor |
|---|---|---|---|---|
| 1 | **Contract violation** | breaks a declared interface, signature, schema, or closed enum | MUST | `Step 2` |
| 2 | **Contradiction** | conflicts with a higher-authority source, or with itself | MUST | `Step 2` |
| 3 | **Unmet criterion** | fails a requirement or AC it is bound by | *inherits the criterion's* | MUST → `Step 2`; SHOULD → `[LOW]`; COULD → `[MINOR]` |
| 4 | **Missing content** | omits a mandated section, field, or element | MUST | `[HIGH]` |
| 5 | **Stale reference** | cites a path, anchor, or identifier that no longer resolves | MUST | `Step 2` — one bad cite is confined → `[MEDIUM]`; widespread → escaped → `[HIGH]` |
| 6 | **Convention deviation** | differs from a declared naming, structure, or format convention | SHOULD | `[LOW]; escaped (>1 artifact) → [MEDIUM]` |

Two of these need no anchor machinery of their own. **Unmet criterion** borrows the
modality of whatever it violated — which is why FR-B5a matters: tag the ACs and this class
grades itself. **Stale reference** needs no density rule: one dead link affects only a
reader of that artifact (confined); dead links throughout mean consumers rely on them
(escaped).

**Two outcomes that are not findings.** *Cannot measure* — a claim no available evidence
can confirm or deny → **ask the user**; never record a softened finding. *No criterion* —
nothing in either ladder speaks to the concern → **criteria gap**, feature-004's Type 2.

**The executor-versus-architecture boundary needs no new mechanism.** Executor guidance
("write clean code", "YAGNI") has no KB criterion declaring it a review rule, so the
catalog's admission rule — no Criterion, no row — makes it inexpressible. Architecture-level
mandates (clean architecture, hexagonal, DDD, BDD, TDD-required) become ordinary rows whose
Criterion cites the KB document declaring them. Where the KB is silent, no row exists, so
the concern is a gap rather than a finding.

### 6. The KB rule set — act-back re-derived

The act-back limb currently emits every failure at flat `[HIGH]` across six insufficiency
classes. Re-derived against the canonical scale, plus one class that did not exist:

| Rule | Class | Modality | Anchor |
|---|---|---|---|
| `KB-20` | **Contradiction** — two KB statements conflict; the agent had to choose | MUST | `Step 2` |
| `KB-21` | **Plan-correctness** — no correct plan assemblable, or the plan is wrong for this project | MUST | `Step 2` |
| `KB-22` | **Contract** — structural shape not stated; the agent reached for source | MUST | `[HIGH]` |
| `KB-23` | **Invariant** — a rule that must hold was not stated; the agent guessed | MUST | `[HIGH]` |
| `KB-24` | **Gotcha** — a non-obvious trap was not warned about | MUST | `[HIGH]` |
| `KB-25` | **Quality-bar** — the KB never conveyed the project's quality contract | MUST | `[HIGH]` |
| `KB-26` | **Convention** — no naming, path, or style convention stated; the agent assumed | **SHOULD** | `[LOW]; escaped (>1 doc) → [MEDIUM]` |

**`KB-20` is new.** All six existing classes describe *absence*. None covered
contradiction, which is worse: silence makes an agent guess and know it is guessing;
contradiction makes it choose confidently, and different agents choose differently.

**`KB-26` is the one genuine SHOULD.** A project runs fine with inconsistent naming; it does
not run fine with unstated contracts. That single modality difference does most of the
differentiating work, and five of seven classes stay at HIGH — closer to today's flat model
than it appears.

**Quality-bar is de-bundled.** It currently means both "the KB stated a bar and the plan
missed it" and "the KB never stated the bar". The first is a plan-correctness failure
(`KB-21`); only the second stays as `KB-25`.

**The reviewer's classification instruction** is the same ordered, first-match-wins shape as
§5: work down `KB-20` to `KB-26` and stop at the first match. One row per gap, naming the
probe and step.

**This respects the binary bar.** "Binary pass/fail per insufficiency" still holds — each
gap fails or it does not, and *almost-states* still fails. What changes is that the class
determines the weight by lookup. No curve, no discretion, no partial credit.

**`[TEACHBACK]` appears dead** — defined in the rubric tag table, counted by
`aid-update-kb/references/state-review.md`, and emitted by nothing;
`aid-discover/references/state-review.md` states M3 tags findings `[FIDELITY]` /
`[ESSENCE-GAP]` — *"NOT `[TEACHBACK]`"*. Retire or re-wire it; do not carry a tag that is
counted but never produced.

### 7. The ledger's eighth column (FR-B10)

```
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
```

**Position is constrained, not chosen.** `grade.sh` parses by column position and requires
Severity at `cols[3]` and Status at `cols[4]` (verify at lines 195–198). Inserting at or
before position 3 breaks the grader and violates NFR-1. Inserting after Status is safe
because the grader reads nothing beyond `cols[4]`.

The shape also groups the table into three readable bands: *classification* (`#`, Severity,
Status, Rule), *location* (Doc, Line), *content* (Description, Evidence). The rule sits next
to the severity it justifies — where a reader asking "why is this HIGH?" will look.

**`grade.sh` is the only positional ledger parser in the tree.** Every other `cols[...]`
site parses STATE tables, task dependency graphs, or its own output.

### 8. Content-isolation relocation (FR-B9)

`canonical/agents/aid-reviewer/AGENT.md` lines **39–57** are deleted entirely — not 44–57.
Lines 39–43 are the `## Standing KB-Convention Checks` wrapper whose only child is the
content-isolation block; deleting only the child leaves an empty section, and the wrapper's
generic instruction ("cite the KB source in the ledger") is now carried by every row's
Criterion cell plus the mandatory Rule column.

The rules become `AID-01`…`AID-06` in `review-rubrics/aid-internal.md`: `aid/` nesting,
`aid-` prefixing, `.github` root scoping, `.codex/` nesting, prune basis, and in-place
`AID:BEGIN`/`AID:END` region update.

**The dangling citation is fixed.** `content-isolation.md` exists nowhere in the repository
— the only references are `AGENT.md` and two identical comments in
`lib/aid-install-core.sh` and `lib/AidInstallCore.psm1`. Replacements, all verified present:

| Rule content | New citation |
|---|---|
| The cornerstone isolation rule | `.aid/knowledge/authoring-conventions.md` § Content Isolation |
| Path mapping | `canonical/EMISSION-MANIFEST.md` (per-profile `src`→`dst` table) |
| copilot-cli `.github` scoping | the `R1` scoping comment in `lib/aid-install-core.sh` / `AidInstallCore.psm1` |
| In-place region update | `_copy_root_agent_file` / `Copy-RootAgentFile` in the same files |

**The `R6` label resolves to nothing anywhere in the repository.** Restate the `.codex/aid/`
rule in terms of the EMISSION-MANIFEST mapping and drop the bare label. The two `lib/`
comments citing the phantom file are corrected in the same pass, so it cannot recur.

### 9. Affected artifact inventory and region ownership

**New files:** `review-rubrics/INDEX.md` plus one file per family, plus class files for
`REQ`, `SPEC`, `PLAN`, `TASK`, `CODE`, `TEST`, `DATA`, `AID`, `SUMMARY` where a declaring
document exists.

**Rule citation replaces source tagging.** All six per-skill `reviewer-brief.md` files:
`RUBRIC:` re-pointed from `grading-rubric.md` (which is the severity→grade *arithmetic*, not
a rule set) to the correct catalog entry, and the source-tag line replaced with the rule-ID
requirement. Five of the six currently point at the wrong kind of document; only
`aid-discover` routes to a real catalog — and it does so via a **bare relative path**, which
the renderer does not rewrite. `reviewer-dispatch.md` §RUBRIC's `(future) code-review-rubric.md`
and `(future) spec-review-rubric.md` placeholders are replaced with the real catalog: this
feature is what that protocol was written expecting.

**Eight columns everywhere.** The migration surface is **eleven files not previously
identified**, and the six briefs — commonly assumed to assert seven columns — carry no such
assertion at all. The real set: `aid-discover`'s `state-review.md` and its five
`reviewer-prompt*.md` files (four embedding the full header row), the `aid-research`,
`aid-test` and `aid-review` SKILL.md files, and two KB docs (`quality-gates.md`,
`authoring-conventions.md`) that carry it in frontmatter **contracts**. Plus
`reviewer-ledger-schema.md`, the reviewer agent body and README, `reviewer-dispatch.md`, and
the AID-managed regions of the root `CLAUDE.md` / `AGENTS.md`.

`grade.sh` changes by **comment only**, at five lines: **10** (`# Table shape expected
(7-column):`), **163** (`# The 7-column ledger schema is:` — a different phrase from line
10), **11** and **164** (the old header row shown in each comment block), and **172**
(`cols[5..8]` → `cols[5..9]`). All five are inside comments; the guard,
the reads, and every branch are byte-unchanged, so NFR-1 holds. These lines are inside
oracle (g)'s scope, so omitting them would leave the oracle failing on the day D3 ships.

**Claimed regions in `canonical/agents/aid-reviewer/AGENT.md`: lines 3, 17, 39–57, 75, 96–99.**

**Line 17 added 2026-07-27**, on feature-004's finding: it mandates the five source tags
including the `[ARCHITECTURE]` that §2 retires, and it was missing from this inventory even
though its README counterparts (11, 33) were already claimed. Its replacement is the rule-ID
requirement, same as the six briefs.
Line 39–57 is uncontested (§8). Lines 3, 75 and 96–99 are **encroachments taken by
decision**, following feature-001's precedent for line 36 — the `description:` frontmatter
claiming "7-column" and "source and severity tags", the literal `Columns:` list, and the
heredoc example's header plus data rows all become false the moment this feature lands.
**Feature-003's and feature-006's edit inventories must drop lines 3, 75 and 96–99.**

Explicitly not claimed: line 8 (stray "The"), 20 (`## Tasks Status` write target), 31/36 and
59–67 (**feature-001**), 33–34 (source authority, cross-reference reconciliation), 69–74 and
76–79 (output-contract prose, feature-003), 81–95 and 100–103 (`## File Writing`,
feature-003), 105–108 (escalation). In `README.md` this feature claims 11, 13, 31, 33;
feature-001 claims 63 and 66; line 52's Large-tier discrepancy is Q3(d) and stays untouched.

**Two pre-existing defects found here, for the Q3 backlog.** `reviewer-dispatch.md` states
"**Six** per-skill briefs are shipped" and then lists **seven** — and `aid-describe`, one of
the seven, has no `reviewer-brief.md` on disk. Correct the count and list, or author the
missing brief.

**Regenerated, never hand-edited:** `.aid/knowledge/INDEX.md` (two KB docs' frontmatter
changes), `site/src/content/docs/reference/agents.md` (sourced from `AGENT.md` frontmatter),
and the seven rendered trees.

**Tests need no rewrite.** `test-grade.sh` (**16** numbered cases, `Test 1` through `Test 16`)
and `test-delivery-gate-aggregate.sh` (4) use 7-column ledgers and all pass unchanged, because
`grade.sh` reads only `cols[3]`/`cols[4]` — which is itself the NFR-1 and NFR-5 proof. Add
**one** 8-column fixture rather than converting the existing ones; covering both shapes is
strictly better.

### 10. Pointer and reference strategy

Every pointer uses the **full `canonical/...` path form**. The renderer's
`rewrite_install_paths` maps `canonical/aid/templates/...` → `<install_root>/aid/templates/...`;
relative forms are untouched and ship broken to all five profiles. The `aid-discover` brief
carries a live instance of this defect and is corrected here.

### 11. Render and profile impact

Seven rendered trees — five profiles plus this repository's own `.claude/` and `.cursor/`
installs. Per STATE concern N3, AC-12 runs as a regression gate **at this feature's close**,
not deferred: `/generate-profile`, then `verify_deterministic.py`, then assert every
rendered tree carries the 8-column shape and renderer-rewritten catalog pointers.

### 12. Migration and compatibility

Existing ledgers remain readable — the new column is additive and the grader ignores
anything past `cols[4]`. A review in flight when this lands keeps its 7-column rows; the
next cycle's reviewer writes 8-column rows. **Feature-003 must state the mixed-shape rule**
for a ledger that spans the change (STATE.md Q7 #10).

### 13. Verification strategy

Ships as `tests/canonical/test-rule-catalog.sh`.

- **(a) Row well-formedness.** Every data row has exactly 7 non-empty cells; `Modality` ∈ `{MUST,SHOULD,COULD}`; `Mode` ∈ `{mechanical,judgment}`.
- **(b) ID shape, uniqueness, prefix conformance.** Every ID matches the regex; no duplicates catalog-wide; every prefix is in the `INDEX.md` class enum; every declared class has at least one rule.
- **(c) Every Criterion resolves** — the cited file exists *and* the quoted anchor is greppable in it. This is the direct regression guard against another phantom `content-isolation.md`.
- **(d) Mechanical rows carry a runnable command** — for every `Mode: mechanical` row, the Evidence cell holds a backticked token whose first word resolves to an existing path or a shell builtin.
- **(e) Severity anchors never restate the scale.** Every Severity cell matches `^(\[(CRITICAL|HIGH|MEDIUM|LOW|MINOR)\]|Step 2)(; escaped .* → \[(HIGH|MEDIUM)\])?$`. No prose. This is what stops the catalog regressing feature-001's AC-1 by growing a sixth severity definition one row at a time.
- **(f) Routing totality** — closed enumeration of the six `reviewer-brief.md` files; each must name a catalog entry in full `canonical/...` form.
- **(g) Eight columns, scoped sweep.** Scope: `canonical/`, `CLAUDE.md`, `AGENTS.md`, `.aid/knowledge/`. Expect zero `7-column` mentions, zero old header rows, and at least one new header row. All three assertions are non-trivially false today — establish the pre-migration baseline with the commands below rather than quoting a count, since an inline count is drift-prone and would be stale before implementation starts:

```bash
grep -rn '7-column\|7 column'          canonical CLAUDE.md AGENTS.md .aid/knowledge | wc -l
grep -rln '7-column\|7 column'         canonical CLAUDE.md AGENTS.md .aid/knowledge | wc -l
grep -rn '| # | Severity | Status | Doc |' canonical CLAUDE.md AGENTS.md .aid/knowledge | wc -l
```

  **The migration set is exactly the files enumerated in §9** — the eleven not previously identified, plus `reviewer-ledger-schema.md`, the reviewer agent body and README, `reviewer-dispatch.md`, and the two root context files, plus the five `grade.sh` comment lines. Any file the baseline sweep reports that §9 does not list is a gap in §9, and §9 is the authority to correct.

  `tests/` is excluded deliberately: two suites legitimately keep 7-column fixtures, and a third says "7-column row" about an unrelated freshness TSV. `profiles/` and `site/` are excluded because they are regenerated — §11 asserts parity there by re-rendering, which is the correct oracle for generated content. `.aid/knowledge/kb.html` is in scope but regenerated by `aid-summarize`; if the baseline reports it, its correction is a regeneration, not an edit.

**What no script can prove, stated plainly.** *"Every finding cites a rule"* is a runtime
property of an agent. No static check reaches it, and no oracle here pretends to. It is
enforced declaratively by the agent body and `reviewer-dispatch.md` §DELIVERABLES, and
**mechanically by feature-003's surgical write helper** — the single writer of ledger rows
and therefore the only thing that can reject a finding row with `--` in Rule. **This is a
dependency this feature creates on feature-003:** until 003 lands, AC-3's runtime half is
contract-enforced, not machine-enforced, and feature-003's spec must pick up that rejection
rule.

### 14. Out of scope

- The canonical severity scale itself, and the `AGENT.md` regions feature-001 claims (31, 36, 59–67) — **feature-001**.
- Ledger row kinds, the surgical write helper, and the mixed-shape migration rule — **feature-003**.
- Type 1 / Type 2 findings, gap batching, and routing. This feature says "report the gap"; how a gap is represented is **feature-004**.
- Retiring `grade-summary.sh`'s weighted-points backend and rewiring `aid-summarize` — **feature-007** (FR-F6). This feature authors the `SUMMARY` rule set those gates grade against.
- The settings gate, the frontmatter-lint wiring, the BLUEPRINT review, and the per-section specify ledger — **feature-007**.
- `task-type-rules.md` — executor guidance, not a review criterion.

### Delivery recommendation

Split at Plan into three:

- **D1 — the catalog skeleton.** `INDEX.md`, the rule-row schema, the ID format, the review kinds, the two ladders, the defect taxonomy, the six families. No class rules yet. Independently verifiable by oracles (a), (b), (e).
- **D2 — the class rule sets**, including the KB re-derivation and the `AID` relocation. Oracles (c), (d), (f).
- **D3 — the eighth column.** The migration set enumerated in §9, the five `grade.sh` comment lines, the new 8-column fixture, and the render parity gate. Oracle (g), with its baseline captured before any edit.

D3 is separable and touches the most files; D1 gates both others.
