# Severity Single Source of Truth

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-11 | **The two-step severity lookup is retired.** § 1 keeps the five tokens and one definition site and replaces the modality→band table and the radius × reversibility matrix with a described scale the reviewing agent applies, stating one line of consequence per finding; § 2's flow loses both steps; § 5's modality check becomes advisory and moves to `aid-describe` alone | `REQUIREMENTS.md` `FR-B1`/`FR-B5c`; `STATE.md` Q32, Q33 |
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.B, §9 (AC-1, AC-2), §2 (problems 1 and 2) | /aid-define |
| 2026-07-27 | Technical Specification authored — 9 adapted sections. FR-B7 cut (double-counts the scale's own axes); `SUGGESTION` modality removed; `AGENT.md` line 36 claimed by decision; modality lint made retroactive; architecture-mandate vs executor-guidance boundary added to the two-sources rule | /aid-specify |

## Source

- REQUIREMENTS.md §5 group B — FR-B1, FR-B2, FR-B3, FR-B5a, FR-B6 (FR-B7 **cut** 2026-07-27)
- REQUIREMENTS.md §9 — AC-1, AC-2
- REQUIREMENTS.md §2 — problems 1 (four contradictory severity definitions) and 2 (the reviewer is licensed to use opinion)

## Description

Severity is currently defined four different ways across seven files, and two of those
definitions flatly contradict each other on the band reviewers use most: one says MEDIUM
means "incorrect behavior", the other says MEDIUM means "incomplete but not wrong". A
reviewer facing two incompatible anchors falls back on feel.

Because the grading script derives the grade arithmetically from severity, that fallback
is not a cosmetic problem. It is the single unspecified input to a gate that decides
whether work advances.

This feature makes severity mean one thing. It writes the scale once, deletes every rival
definition in favour of a pointer, and closes the loophole that lets a reviewer invent
criteria: review measures against the Knowledge Base and the work's own spec documents,
and nothing else. "Established best practice" stops being an acceptable source. So do
undefined quality terms like "clean code", "YAGNI", and "no over-engineering" that ship
in today's checklists.

It also establishes two supporting rules: a finding with no evidence is not admitted at
all, and reviewer confidence never adjusts severity.

## User Stories

- As an **AID maintainer**, I want severity defined in exactly one place so that two reviewers looking at the same finding reach the same severity and the grade actually means something.
- As an **adopter project**, I want every review finding traceable to a rule I wrote down, so that I can disagree with the rule instead of arguing with the reviewer's taste.
- As a **pipeline agent**, I want one severity scale to consult so that I am not choosing between contradictory tables.
- As an **AID maintainer**, I want unevidenced findings rejected rather than recorded weakly, so that the ledger never carries claims nobody can check.

## Priority

Must

## Acceptance Criteria

<!-- Carried across from REQUIREMENTS.md section 9 by the decomposition rule: a mapped criterion keeps
     the modality it had there. Modality is what step 1 of the severity scale reads, so a criterion
     without one makes every finding against it ungradeable. The checklist below elaborates these
     rows; it is not a second set of criteria. Gated by aid/scripts/kb/lint-modality.sh. -->

| ID | Modality | Criterion |
|----|----------|-----------|
| AC-1 | MUST | Exactly one severity definition exists in the canonical tree. A grep for competing severity tables returns only pointers. |
| AC-2 | MUST | The string "established best practice" no longer appears as a criterion source, and no shipped checklist contains an undefined quality term. |

- [ ] **AC-1** — Given the canonical tree, when I grep for severity definition tables, then exactly one definition exists and every other location is a pointer to it.
- [ ] Given the canonical tree, when I search for the four known rival definitions (`grading-rubric.md`, `reviewer-ledger-schema.md`, `kb-authoring/review-rubric.md`, `agents/aid-reviewer/AGENT.md` and its `README.md`, `aid-execute/references/reviewer-guide.md`, `quality-gates.md`), then none of them carries its own severity meanings.
- [ ] **AC-2** — Given the canonical tree, when I grep for "established best practice", then it no longer appears as a criterion source; and no shipped checklist contains an undefined quality term.
- [ ] Given the canonical severity scale, when I read it, then it is expressed in artifact-neutral terms — **what the defect costs a consumer** — rather than in code-specific or document-specific language. *(Amended 2026-08-11: the parenthetical read "blast radius and reversibility". Those two proxies are exactly what stopped being neutral outside code, per `STATE.md` Q32.)*
- [ ] Given a review, when the reviewer cannot ground a criterion in the Knowledge Base or the work's spec documents, then it does not invent one.
- [ ] Given a finding with no evidence, when it is produced, then it is inadmissible and never reaches the ledger.
- [ ] Given a reviewer that is uncertain, when it records a finding, then its confidence has not altered the severity — uncertainty about whether a rule applies is a question for the user, not a softer band.
- [ ] Given any finding, when it is written, then it carries **one line naming the consequence** that justifies its band, so the severity can be argued with. *(Added 2026-08-11 with `FR-B5c`.)*
- [ ] Given the requirements and spec templates, when an FR or AC is authored, then it carries an explicit modality (MUST / SHOULD / COULD).
- [ ] Given an existing document written before this feature, when `lint-modality.sh` runs against it, then missing modality is reported — the lint applies retroactively.

## Notes for Specify

- **This feature edits `canonical/agents/aid-reviewer/AGENT.md`** — it deletes the local severity table (FR-B1) and the "or established best practice" clause (FR-B3). Per the ownership rule in STATE.md, those two regions belong to this feature, not to FR-A10. Four other features also edit that file in non-overlapping regions; see STATE.md concern N2.
- **FR-B5a reaches outside the review subsystem.** Authoring explicit modality touches the requirements and spec templates and the skills that author them. Size this feature with that reach in mind — it is not purely the bounded editorial job the rest of the feature is. *(Amended 2026-08-11: the reach is unchanged, but its Tier 3 check is now advisory and lands in `aid-describe` only — see § 5.)*
- **FR-B7 was cut** on 2026-07-27, so this feature ships five FRs and no damage-modifier layer. Neither AC-1 nor AC-2 depended on it. *(This bullet read "undecided cut candidate" until 2026-08-11.)*
- Verify five-profile render parity at feature close rather than deferring it (STATE.md concern N3).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Sections are adapted for a methodology
> artifact: there is no database, no request flow, and no DI container here — the
> "runtime" is agents reading documents. The three core sections appear in adapted form;
> eighteen conditional sections are dropped for lack of a runtime, a UI, or a network
> surface.

### 1. Canonical Severity Scale

This is the normative payload. It ships as `## Severity Scale` in
`canonical/aid/templates/grading-rubric.md`, wrapped in
`<!-- AID:SEVERITY-SCALE:BEGIN -->` / `<!-- AID:SEVERITY-SCALE:END -->` sentinels so its
uniqueness is mechanically checkable. Anchor: `#severity-scale`.

The five bracketed tokens (`[CRITICAL]` … `[MINOR]`) are **unchanged**. Only their
meanings change. This is what keeps `grade.sh` untouched and every existing ledger valid.

---

**AMENDED 2026-08-11.** The three blocks that follow — *"severity is looked up, never
felt"*, the modality→band table, and the radius × reversibility matrix — were the shipped
payload of this section until 2026-08-11. `STATE.md` Q32 retires them and `FR-B5b` with
them. What replaced them is below; the retired machinery is not reproduced here, and
`REQUIREMENTS.md § 5` `FR-B5b` carries the reasons.

**Severity is the reviewing agent's judgment, and the agent states why.** One line per
finding, naming the consequence: `<band> because: <what goes wrong, for whom>`. That
sentence is the whole mechanism. It is not a rule about the answer — it is what makes an
answer arguable, and therefore overturnable, which is what the retired lookup table was
reaching for and missed.

**The five bands, described rather than computed.**

| Token | What it means |
|---|---|
| `[CRITICAL]` | The work cannot proceed, or proceeding produces something actively wrong. |
| `[HIGH]` | The wrong thing gets built, or a gate cannot be decided. |
| `[MEDIUM]` | A real defect a consumer would hit and have to resolve by asking. |
| `[LOW]` | A real defect that changes nothing anyone does. |
| `[MINOR]` | Cosmetic. |

These are **artifact-neutral by being about consequence**, which is what `AC-2`'s
artifact-neutrality bullet asks for. The retired version reached neutrality through two
proxies — blast radius and reversibility — that only behave like consequence in code. On a
document nothing has consumed yet, reversibility is always local and radius is only *"is
this mentioned elsewhere"*, so the proxies collapsed and the band came out of modality
alone.

**Five dimensions the reviewer judges**, against the KB, the documents associated with the
artifact, and the repository as it actually is:

| Dimension | The question |
|---|---|
| **Correctness** | Is what it says true? |
| **Completeness** | Is anything a consumer needs missing? |
| **Clarity** | Can a consumer act on it without asking? |
| **Coherence** | Does it agree with itself and with its inputs? |
| **Necessity** | **Does any part serve nothing?** A part that serves nothing is itself a defect, and reporting it as removable is worth more than making it correct. |

**Stance: adversarial, with a floor.** Look for what is wrong — and **an honest clean pass
reported is worth more than a manufactured finding.** The floor is stated because the
retired scale rewarded the opposite: nine review cycles on this work's own `feature-009`
SPEC produced 89 findings, roughly two thirds of them cosmetic, none of which could move a
grade.

**Blast radius and reversibility survive as questions, not as a matrix.** *What depends on
this? What does repair cost?* Both are still worth asking and both remain evidence-bearing
— **name the dependent, or the radius is confined** — but neither returns a token, and
neither is required to be answered before a severity may be written.

**Modality is not a severity input.** A `MUST` can carry a `[LOW]` finding when the defect
changes nothing; a `SHOULD` can carry a `[HIGH]` one when it breaks a gate. `FR-B5a` keeps
modality for what it is — a statement of how binding a requirement is, which the reviewer
weighs like any other evidence.

**Three rules that hold in every band.**

1. **No evidence, no finding.** A finding must cite the disk truth that contradicts the
   artifact's claim, or the command that produces it. A finding that cannot be evidenced
   is **inadmissible** — not recorded at a lower severity, not recorded at all.
2. **Confidence never modifies severity.** Uncertainty about whether a rule applies is a
   question for the user, not a reason to soften a band.
3. **No criterion, no finding.** If no rule in the Knowledge Base or the work's
   specification documents speaks to the concern, you have found a gap in the criteria,
   not a defect in the artifact. Report the gap. Do not invent the rule, and do not
   substitute general practice for it.

`F` remains outside this scale. It is not a severity but a whole-artifact verdict — does
not build, does not run, produces no usable output — set via `grade.sh --non-functional`.

---

**Why this resolves the live contradiction.** The two rival definitions both described
*what the artifact is like* — "incorrect behavior (non-critical)" versus "incomplete but
not wrong". This scale describes *what the defect costs*. Neither survives as a competing
anchor, because neither is asking the scale's question. That holds unchanged under the
2026-08-11 amendment: `AC-1` is about there being **one** definition, not about whether the
definition is a table or a description.

### 2. Finding Admission & Severity Assignment

The flow, in the sense that matters here — rule to graded row:

```
criterion (KB | REQUIREMENTS/SPEC/BLUEPRINT/DETAIL)
    │
    ├─ no criterion speaks to the concern ──────────> criteria gap (Type 2, feature-004)
    │                                                  NOT a finding
    ▼
violation observed
    │
    ├─ cannot be evidenced ─────────────────────────> inadmissible; discarded
    ▼
evidence attached (disk truth, or the command producing it)
    │
    ▼
the agent judges the five dimensions and assigns a band,
stating in one line what goes wrong and for whom
    │
    ▼
                          ledger row (8-column)
                                    │
                                    ▼
                     grade.sh: counts cols[3] × cols[4]
```

**Amended 2026-08-11.** The two `Step` boxes are gone with the lookup they belonged to. The
column count is also corrected to `8`: `FR-B10` added the `Rule` column, and the diagram
still said `7` because it was authored before that landed.

**The two-sources rule, sharpened.** FR-B2 says criteria come only from the KB and the
work's spec documents. One clarification belongs in the shipped wording, because it is the
distinction reviewers get wrong:

- **Executor guidance** — how to write the code — is *not* a review criterion. "Write
  clean code", "small methods", "meaningful names" instruct the developer; the reviewer
  does not grade against them.
- **Architecture-level mandates** — clean architecture, hexagonal, DDD, BDD, TDD-required
  — *are* review criteria, **but only when the Knowledge Base declares them.** Where the
  KB declares one, its absence is a finding. Where the KB is silent, its absence is a
  **criteria gap**, not an invented finding.

The reviewer identifies the absence; the architect or executor applies the pattern.

### 3. Affected Artifact Inventory & Region Ownership

Line numbers are from the work-003 worktree.

**3a — the scale becomes one definition and six pointers**

| File | Region | Change |
|---|---|---|
| `canonical/aid/templates/grading-rubric.md` | 5–13 | **Replaced** by §1 above, sentinel-wrapped. Lines 15–63 (tagging convention, grade calculation, ordering) unchanged. |
| `canonical/aid/templates/reviewer-ledger-schema.md` | 75–85 | **Deleted** → pointer. Frontmatter contract (13) and the Columns table's Severity row (66) stay — they carry tokens, not meanings. |
| `canonical/aid/templates/kb-authoring/review-rubric.md` | 57–67 | **Deleted** → pointer. |
| `canonical/agents/aid-reviewer/AGENT.md` | 59–67 | **Deleted** → one-line pointer. |
| `canonical/agents/aid-reviewer/README.md` | 68–76 | **Deleted** → pointer. |
| `canonical/skills/aid-execute/references/reviewer-guide.md` | 6–14 | **Deleted** → pointer. |
| `.aid/knowledge/quality-gates.md` | 98–100 | **Replaced** → pointer. Add a Change Log row and a `.aid/knowledge/README.md` Revision History entry — this is the work's first real KB content change. |

**3b — the taste licence**

| File | Region | Change |
|---|---|---|
| `canonical/agents/aid-reviewer/AGENT.md` | 31 | Delete "or established best practice". Restate as the two-sources rule and add the no-criterion-no-finding line. |
| `canonical/agents/aid-reviewer/AGENT.md` | **36** | **No change. Line 36 already says the right thing.** *(Amended 2026-08-11.)* It reads "Severity is your judgment. Grade is the script's job.", and this row used to turn it into severity-is-a-lookup. `FR-B5b` is retired and `FR-B5c` says exactly what line 36 says, so the edit is withdrawn — what the line needs is the **addition** `FR-B5c` requires, a stated reason per finding, not a reversal. **Claimed by decision, 2026-07-27** — see 3d. |
| `canonical/agents/aid-reviewer/README.md` | 63, **66** | Same two changes, human-facing wording. |
| `canonical/skills/aid-execute/references/reviewer-guide.md` | 35 | **Delete** `4. Code Quality — clean code? YAGNI? No over-engineering?` and renumber. Fully subsumed by items 2 and 3, which cite real KB documents. |

**3c — pointer hygiene (load-bearing for AC-1, see §4)**

| File | Line | Change |
|---|---|---|
| `canonical/aid/templates/reviewer-dispatch.md` | 170 | Point at the canonical scale; state that a named rubric supplies rule→severity *bindings*, not severity *meanings*. |
| `canonical/skills/aid-define/references/cross-reference.md` | 42 | Relative → full canonical path form. |
| `canonical/skills/aid-specify/references/state-continue.md` | 81 | Same. |
| `canonical/skills/aid-execute/references/state-delivery-gate.md` | 196 | Same. |

**3d — region ownership in `aid-reviewer/AGENT.md`**

This feature claims lines **31, 36, and 59–67**. Nothing else.

Line 36 is a deliberate encroachment on ground nominally belonging to FR-B5b (feature-002)
and FR-A10 (feature-006). Taken by decision on 2026-07-27: the moment the severity table
beside it becomes a pointer, that line actively contradicts the canonical scale, and
leaving it would ship a known contradiction standing across four features. **The other
features' edit inventories must be updated to remove line 36.**

**AMENDED 2026-08-11 — the contradiction that justified the claim has evaporated, and the
claim is kept anyway.** `FR-B5b` is retired, so line 36's "Severity is your judgment" no
longer contradicts anything; it is now the shipped position. The claim stands because the
line still needs an **addition** — `FR-B5c`'s one-line-reason duty and the five dimensions
— and one owner for one line is still the right arrangement. Note what this means for the
edit's risk: it went from a reversal of a shipped sentence to an extension of it, which is
strictly smaller. `AC-1` and `AC-2` are unaffected either way.

Explicitly **not** claimed: line 3 (`description:` frontmatter), line 8 (opening line,
stray "The"), line 20 (`## Tasks Status` write target), lines 33–34 (source authority,
cross-reference reconciliation), lines 39–57 (content isolation — FR-B9, feature-002),
lines 69–79 (output contract — feature-003), lines 81–103 (`## File Writing` —
feature-003), lines 105–108 (escalation).

**3e — deliberately untouched**

`kb-authoring/review-rubric.md`'s per-check severity anchors (checks 1–13), the CAL-1…CAL-4
table (79–97), and the lint-tag→severity table (247–286) are **rule→severity bindings**,
not rival scale definitions. They stay untouched by this feature, and what happens to them
is feature-002's `FR-B4` — doing it here would straddle a feature boundary.

**Amended 2026-08-11:** this said they "need re-deriving against the new scale". Under the
amended `FR-B4` they are **deleted** rather than re-derived: a rule row no longer carries a
severity at all. Which makes the boundary sharper, not blurrier — this feature leaves them
alone either way, and `AC-1` is satisfied in the stronger direction, since 85 per-rule
anchors were the largest remaining collection of severity values outside the one definition
site.

`canonical/aid/scripts/grade.sh` — **verified, no change** (NFR-1). Its awk path trims
`cols[3]`/`cols[4]`, exact-matches `cols[3]` against the five bracketed literals, and skips
any row whose `cols[4]` is not exactly `Pending` or `Recurred`. It reads tokens, never
meanings.

### 4. Pointer & Reference Strategy

**Every pointer must use the full canonical path form.** The renderer's
`rewrite_install_paths` maps `canonical/aid/templates/...` → `<install_root>/aid/templates/...`.
Relative forms such as `../../../templates/grading-rubric.md` are **not** rewritten and
ship broken to all five profiles. This is Q3 defect (c), generalised — three further
instances are corrected in §3c.

Standard pointer text, used verbatim at every site:

```
Severity definitions live in exactly one place:
`canonical/aid/templates/grading-rubric.md#severity-scale`. Do not restate them here.
```

### 5. Modality Enforcement (FR-B5a)

Three tiers.

**Tier 1 — authored in the template.** Make modality part of the artifact's shape, so the
right thing is the default rather than a rule to remember.

- `canonical/aid/templates/requirements/requirements-template.md` — §5, §6, §9 gain the
  `ID | Modality | Requirement` shape plus the convention note. This work's own
  REQUIREMENTS.md already dogfoods it; lift that.
- `canonical/aid/templates/requirements.md` — same headers under §5, §6, §9.
- `canonical/aid/templates/specs/spec-template.md` — the Given/When/Then criterion gains a
  modality token.
- `canonical/aid/templates/feature.md` — same change to its acceptance criteria.

**Tier 2 — the skills and the engine that fill those templates.**

- `canonical/skills/aid-describe/references/state-completion.md` — the §5/§9 completion
  checklist gains "every FR, NFR and AC carries a modality".
- `canonical/skills/aid-describe/references/interview-loop.md` and
  `elicitation-engine.md` — elicitation asks for or assigns modality at capture.
- `canonical/skills/aid-specify/references/state-continue.md` — the per-section loop that
  writes acceptance criteria.
- `canonical/aid/templates/shortcut-engine.md` — **CAPTURE** and **SPEC** states. The Lite
  path authors REQUIREMENTS and SPEC without ever invoking `aid-describe` or
  `aid-specify`, so **every shortcut skill in the generated catalog** would otherwise
  produce modality-free requirements. Deliberately stated without a count: the entry total
  in `canonical/aid/templates/shortcut-catalog.yml` includes alias rows, and the subset
  that reaches CAPTURE/SPEC is not derivable from the catalog alone. Implementation should
  derive the affected set from the engine's own invocation contract rather than from a
  catalog row count.

**Tier 3 — a check at authoring time, advisory.** A new
`canonical/aid/scripts/lint-modality.sh`, following `kb/lint-frontmatter.sh`'s conventions:
given a REQUIREMENTS.md or a feature SPEC.md, assert every §5/§6 row and every §9 criterion
carries exactly one of `MUST | SHOULD | COULD`. Wired at **`aid-describe` completion only,
and it does not block a grade.**

**AMENDED 2026-08-11 (`STATE.md` Q32/Q33).** This tier previously gated `aid-specify`
REVIEW as well, with a non-zero exit. Both changes follow from what the script actually
does: **it checks that one of three literal tokens is present.** Whether `SHOULD` was the
right choice for a given requirement is untouched by it, and cannot be checked by a script
— so a grade gated on it was gated on typing. Its stated reason for gating was that Step 1
could not run without a modality; Step 1 no longer exists.

It keeps its place at authoring time, and that is not a consolation prize: an author who
has not said whether a rule is mandatory has usually not decided. Catching that while the
document is being written is worth more than catching it at review, when the answer gets
guessed.

**No longer a precondition gap either.** A missing modality used to be Type 2 territory
because Step 1 needed it. Now it is evidence a reviewer weighs and can report on like any
other omission — `FR-I5` leaves exactly one mechanical blocker, an open criteria gap.

**Retroactive.** Decided 2026-07-27: the lint applies to existing documents, not
forward-only. Back-fill required for this work's own REQUIREMENTS.md (its 12 ACs in §9
carry no modality), all six feature SPECs, and work-001 and work-002.

**Vocabulary.** `SUGGESTION` was removed. Modality is `MUST / SHOULD / COULD` — the same
three values feature-level `## Priority` already uses. One vocabulary, not two.

### 6. Render & Profile Impact

Seven rendered trees: `profiles/{claude-code,codex,cursor,copilot-cli,antigravity}/**`
plus this repository's own `.claude/**` and `.cursor/**` installs. Each carries a copy of
`grading-rubric.md` and of the reviewer agent body.

All are regenerated, never hand-edited. Per N3, AC-12 runs as a regression gate **at this
feature's close**, not deferred to feature-006: run `/generate-profile`, then
`verify_deterministic.py`, then assert each rendered tree carries exactly one sentinel pair
and the correctly rewritten pointer form for its root.

### 7. Migration & Compatibility

**Existing ledgers remain valid** (NFR-5). The five bracketed tokens do not change, and
`grade.sh` matches tokens rather than meanings, so a ledger written yesterday grades
identically today. What changes is which severity a reviewer *would assign* to a new
finding — not how any recorded row is counted.

**In-flight reviews.** A review mid-cycle when this lands may hold rows severitised under
the old meanings. They stay as they are; the next cycle's reviewer re-verifies against the
new scale as part of its normal pass. No migration script, no re-severitisation sweep.

**Retroactive modality** (§5) is the one genuine migration, and it is documentary rather
than structural.

### 8. Verification Strategy

AC-1 and AC-2 are unfalsifiable as written. They ship as a new suite,
`tests/canonical/test-severity-single-source.sh`, alongside `test-grade.sh`.

**AC-1 — three assertions.**

```bash
# (a) exactly one canonical definition
[ "$(grep -rl 'AID:SEVERITY-SCALE:BEGIN' canonical/ | wc -l)" -eq 1 ]

# (b) none of the six former hosts still DEFINES severity.
#     Closed enumeration, deliberately not a tree-wide sweep -- see the note below.
#     Five hosts head their definition with a section heading; quality-gates.md does
#     not, so it needs its own content assertion (b2).

HEADING_HOSTS="canonical/aid/templates/reviewer-ledger-schema.md
canonical/aid/templates/kb-authoring/review-rubric.md
canonical/agents/aid-reviewer/AGENT.md
canonical/agents/aid-reviewer/README.md
canonical/skills/aid-execute/references/reviewer-guide.md"

# (b1) heading-hosted definitions
for f in $HEADING_HOSTS; do
  grep -qiE '^#+ *(Issue )?Severit(y|ies)|^\*\*Severity (scale|values)\*\*' "$f" \
    && fail "$f still carries a severity-defining heading"
done

# (b2) quality-gates.md carries its definition as PROSE under `## The Grade Scale`
#      (no severity heading of its own), so the heading sweep is blind to it.
grep -q 'Severity meanings' .aid/knowledge/quality-gates.md \
  && fail "quality-gates.md still restates severity meanings inline"

# (c) every former host carries the pointer, in renderer-rewritable form
FORMER_HOSTS="$HEADING_HOSTS
.aid/knowledge/quality-gates.md"

for f in $FORMER_HOSTS; do
  grep -q 'canonical/aid/templates/grading-rubric.md' "$f" || fail "$f"
done

# (d) ADVISORY drift check -- NOT a gate, and not part of AC-1.
#     Surfaces a severity table introduced somewhere new. Known-benign matches are
#     excluded; a non-zero count is a prompt to look, not a failure.
grep -rnE '^\| *(Severity|Tag) *\| *(Meaning|When) *\|' canonical/ \
  | grep -vE 'grading-rubric\.md|reviewer-prompt-actback\.md'
```

**Why (b) enumerates rather than sweeps.** No single pattern can reliably identify a
severity-definition table, and attempting one fails in both directions. The six hosts head
their tables five different ways — `## Issue Severities`, `## Severity values`,
`## Severity Classification`, `## Issue Severity`, and a bold `**Severity scale**` — and
their first cells take three forms: `**Minor**`, `` `[CRITICAL]` ``, and bare `CRITICAL`.
In the other direction, a header-shape sweep produces false positives on unrelated tables:
`canonical/skills/aid-discover/references/reviewer-prompt-actback.md` line 94 carries a
`| Tag | Meaning |` header for a `STATED`/`ASSUMED`/`REACH` work-simulation table that has
nothing to do with severity. The host set is closed and known, so enumerate it.

**Why `quality-gates.md` needs its own assertion.** Its severity definition is not a
table under a heading — it is a prose sentence at lines 98–100 beginning "Severity
meanings (from the rubric):", sitting under `## The Grade Scale`. The heading sweep in
(b1) returns zero matches for that file both before and after implementation, so it
passes trivially and proves nothing. Without (b2), a partial implementation — pointer
added, prose retained — would pass every oracle while leaving a rival definition in place.

**(c) is the stronger negative-to-positive complement.** A host that still carries its
own definition but also gained a pointer would pass (c) and fail (b); a host that renamed
its heading would pass (b) and fail (c). All of (b1), (b2) and (c) must pass.

**(d) is advisory only** and deliberately excluded from AC-1. It exists to surface a rival
table appearing somewhere new in future, and its exclusion list will need maintaining.
Treat a non-zero result as a prompt to look, never as a gate failure.

**AC-2 — scoped denylist.** "No undefined quality term" needs a closed term list *and* a
closed surface list, or it is an opinion rather than a test.

```bash
REVIEW_SURFACES="canonical/agents/aid-reviewer/ \
                 canonical/aid/templates/grading-rubric.md \
                 canonical/aid/templates/reviewer-ledger-schema.md \
                 canonical/aid/templates/reviewer-dispatch.md \
                 canonical/aid/templates/kb-authoring/review-rubric.md \
                 canonical/skills/*/references/reviewer-brief.md \
                 canonical/skills/aid-execute/references/reviewer-guide.md"

grep -rin 'established best practice' canonical/ | wc -l   # expect 0, tree-wide
grep -rinwE 'YAGNI|over-engineering|clean code|best practices?|idiomatic|elegant|well-structured|readable|maintainable|reasonable|as appropriate' \
     $REVIEW_SURFACES | wc -l                              # expect 0
```

The narrow surface list matters. `preset-catalog.md` and `connector-registry.sh` use
"YAGNI" in legitimate design-rationale prose and must not be caught.

**Modality lint** — `lint-modality.sh` gets its own fixture cases: a compliant document, a
document missing modality on one FR, and a document using a retired `SUGGESTION` token.

### 9. Out of Scope

Named so features 002–006 inherit clean boundaries:

- **Rule→severity bindings.** Re-deriving `kb-authoring/review-rubric.md`'s per-check
  anchors against the new scale is feature-002 (FR-B4).
- **The "silence" axis.** Survives FR-B7's cut as a feature-002 rule-authoring input: a
  rule whose violation fails silently is anchored one band higher.
- **The rule-reference carrier.** Where a finding records *which* rule it cites is
  feature-002, blocked on Q7 #1.
- **`grade.sh` changes of any kind**, including FR-B8's conformance lint (feature-003).
- **Ledger row kinds and the write helper** (feature-003).
- **Type 1 / Type 2 findings.** This feature says "report the gap"; *how* a gap is
  represented, batched, and routed is feature-004.
- **Every other region of `aid-reviewer/AGENT.md`** (see §3d).
- **`task-type-rules.md`.** Executor guidance, not a review criterion — decided
  2026-07-27.

### Delivery recommendation

Split at Plan into two deliveries:

- **D1 — severity single source + taste licence.** §§1–4, 6–8 minus the modality lint.
  Self-contained, fully grep-verifiable, satisfies AC-1 and AC-2.
- **D2 — modality enforcement.** §5 alone: the out-of-subsystem reach across four
  templates, four skills/engine sites, one new lint, and the retroactive back-fill.

D1 has no dependency on D2, and D2 is the part whose blast radius is hard to bound.
