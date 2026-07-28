# Review Coverage Gaps

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from the artifact inventory in STATE.md Q12; REQUIREMENTS.md §5 group F | /aid-define |

## Source

- REQUIREMENTS.md §5 group F — FR-F1, FR-F2, FR-F3, FR-F4, FR-F5
- REQUIREMENTS.md §5 group B — FR-B11 (the review-kind taxonomy this feature's gates are typed against; authored by feature-002)
- STATE.md Q12 — the artifact inventory and the five gaps it found

## Description

A sweep of every artifact AID produces — persistent, generated, and transient — found five
places where a review should exist and does not. They are unrelated to each other in
mechanism but identical in shape, which is why they belong together.

**Settings are ungoverned.** `.aid/settings.yml` carries `minimum_grade`,
`discovery.doc_set`, and `term_exclusions`. Nothing checks it. Set the minimum grade to `C`
and every quality gate in the project quietly loosens, with no finding, no warning, and no
record. In a methodology whose entire premise is gated quality, the file that sets the gates
is the one artifact nobody inspects.

**The summary is never adversarially read.** `kb.html` has a thorough machine suite —
accessibility, contrast, visual regression, diagram content — and a mandatory human
checklist. What it has never had is a reviewer asking whether the content is *true*. Machine
validators prove the HTML is well-formed; they cannot notice that it describes the wrong
architecture.

**A built gate was never wired.** `lint-frontmatter.sh` exists, and the KB authoring
principles name it as *the* mechanical frontmatter check. No skill state invokes it. Only the
test suite and the dashboard call it. So frontmatter presence and shape are checked by an
agent inside the M2 mandate — paying agent prices, with agent variance, for something a
script already does deterministically.

**A definition artifact escaped the definition phases.** `BLUEPRINT.md` is authored by
`aid-plan`, refined by `aid-specify`, and read at DELIVERY-GATE for its gate criteria. It is
never itself graded. Every sibling definition artifact — REQUIREMENTS, SPEC, PLAN, DETAIL —
has a review state. This one does not.

**One skill runs two disciplines.** `aid-specify` reviews each section as it is written, and
reviews the whole spec at the end. The final review writes a ledger and computes a grade. The
per-section review does neither. Same skill, same reviewer, two standards.

## User Stories

- As an **AID maintainer**, I want the file that sets every quality gate to be checked, so that a typo or a well-meant loosening cannot silently disable the methodology's own enforcement.
- As an **adopter project**, I want someone to read my knowledge summary for correctness, not just for valid markup.
- As an **AID maintainer**, I want mechanical checks performed by scripts rather than agents, so that they are deterministic and cheap.
- As an **AID maintainer**, I want every definition artifact graded, so that no phase output reaches Execute ungraded.
- As an **AID maintainer**, I want one review discipline per skill, so that findings and grades are comparable across its states.

## Priority

Should — FR-F1 through FR-F3 are Must within the feature; FR-F4 and FR-F5 are Should.

## Acceptance Criteria

- [ ] Given a `.aid/settings.yml` with an invalid `minimum_grade`, when the gate runs, then it fails with a non-zero exit and names the offending key.
- [ ] Given a `.aid/settings.yml` with a malformed `discovery.doc_set` row, when the gate runs, then it fails and names the row.
- [ ] Given a valid `.aid/settings.yml`, when the gate runs, then it exits zero and emits no finding.
- [ ] Given a settings change that loosens `minimum_grade`, when the gate runs, then the change is surfaced rather than applied silently.
- [ ] Given a generated `kb.html`, when the adversarial pass runs, then it produces a rule-cited findings ledger against **`review-rubrics/summary.md`, inheriting the universal defect taxonomy**, separate from the existing machine score and human checklist. *(Corrected 2026-07-27: the Notes originally said "NARRATIVE-family", but feature-002 §4 assigns `SUMMARY` to the **Presentation** family, and its AC requires an artifact to resolve to exactly one rule set. The content-truth criteria live in the `SUMMARY` class file.)*
- [ ] Given `kb.html` content that contradicts a KB document, when the adversarial pass runs, then it is reported as a contradiction with the KB winning per the authority ladder.
- [ ] Given a KB document with missing or malformed frontmatter, when the phase gate runs, then `lint-frontmatter.sh` fails the phase — and the M2 mandate no longer performs that check by hand.
- [ ] Given a `BLUEPRINT.md`, when its phase completes, then it has been graded against a rule set, not merely read for gate criteria.
- [ ] Given an `aid-specify` per-section review, when it completes, then it has written to a ledger and computed a grade, using the same path discipline as the final REVIEW state.

## Notes for Specify

- **Sequenced last, after feature-006.** Every gate here should be built on the shared review capability (`aid-light-review` / `aid-deep-review`) and against feature-002's rule sets. Building them earlier would add review dispatch sites that feature-006's caller migration then has to rewrite — the rework trap §10 exists to avoid.
- **Depends on FR-B11** (feature-002) for the review-kind taxonomy. FR-F1 and FR-F3 are **kind D** (mechanical gate, no agent, no rule rows). FR-F2 is **kind A** *added alongside* the existing **kind E** — `kb.html` becomes the only artifact carrying two review kinds, which is deliberate and should be stated explicitly in the class registry.
- **FR-F2 needs a NARRATIVE-family rule set** to grade against. If that family is not authored by feature-002, this requirement cannot be met and becomes a criteria gap.
- **FR-F1 placement question for Specify:** does the settings gate run at `aid-config` completion only, at every skill that reads a gate-relevant value, or both? A gate that runs only at authoring time will not catch a later hand-edit — which is the actual risk.
- **FR-F3 has a knock-on:** wiring the lint means *removing* the corresponding hand-check from the M2 Anatomy mandate, or the same defect gets reported twice at two different severities. Name the M2 checks that retire.
- **FR-F6 is the largest item here.** Retiring the weighted-points model touches: `knowledge-summary/grading-rubric.md` (its 68 machine + 30 human points become rule rows with severity anchors — **authored by feature-002**, applied here), `grade-summary.sh` (stops computing a score; either emits ledger rows or is retired in favour of the validators emitting rows directly), `aid-summarize`'s VALIDATE and MANUAL-CHECKLIST states (grade via `grade.sh`), and `manual-checklist.json` (human answers become human-authored ledger rows).
- **The argument for FR-F6, so Specify does not relitigate it:** weighted points were a proxy for per-check severity anchoring. A score of "60% of the accessibility points" only exists because no rule declared what an accessibility violation is *worth*. Once each rule carries an anchor, the weights are redundant — and worse than redundant, because they are a second arithmetic that can disagree with the first.
- **What is genuinely lost:** partial credit. The points model can express "most of the way there"; severity counting cannot. That is consistent with a decision already taken (the binary bar — *do not grade on a curve*), and the severity anchors carry the weight the points used to. If an accessibility rule is MUST-modality in the KB, its violations anchor HIGH and a pile of them fails the gate, exactly as the points model intended.
- **The three binary verdict gates need explicit re-expression**, not deletion: the essence gate (PASS iff zero open `[FIDELITY]` rows), the act-back gate (PASS iff zero open `[ACTBACK]` rows), and summarize's V1 visual gate. The first two are already *derivable* from the ledger — "zero findings of this rule class" needs no separate mechanism. V1 is the one true hard stop, and it maps onto the existing `grade.sh --non-functional` flag when the summary genuinely produces nothing usable.
- Verify five-profile render parity at feature close (STATE.md concern N3).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Six independent gates over one shared substrate. All
> nineteen conditional sections are dropped — no store, request flow, DI container, API surface,
> UI, network boundary, cache, telemetry sink, or hardware target. `Migration Plan` is kept
> (§9), because retiring a scored backend has a live coverage-baseline consequence.

### 1. FR-F6 — one grading backend

#### 1a. What the 68 points actually are

```bash
awk '/^declare -A WEIGHTS=\(/,/^\)/' canonical/aid/scripts/summarize/grade-summary.sh \
  | grep -oE '=[0-9]+' | tr -d '=' | paste -sd+ | bc      # 68
```

Fourteen scored checks. The MANUAL_POOL's 30 is `K1 10 + K2 15 + V1 5`
(`manual-checklist.sh` lines 88, 97, 107).

**Ten of the 68 points cannot be lost.** `grade-summary.sh:248–249` sets `RESULTS[D1]=pass` and
`RESULTS[D2]=pass` **unconditionally** — the Mermaid engine was retired, so D1 and D2 are 5 points
each of dead weight inflating every Machine Grade. The cleanest subtraction in the feature: no
rule row, no coverage loss, pure deletion.

#### 1b. The points-to-rules mapping

| Check | Pts | Becomes |
|---|---|---|
| **COV** | 15 (partial 0/3/8/15; <60% → forced F) | `SUMMARY-01` — *every resolved doc-set doc is referenced in the summary.* MUST. `Step 2` → `[MEDIUM]`, **one row per unreferenced doc** |
| **D1, D2** | 5 + 5 | **Deleted.** A check that cannot fail is not a rule |
| **L1, L2** | 5 + 5 | **No SUMMARY rule.** They are feature-002 §5's universal class 5 (*Stale reference*) verbatim — `Step 2`, one bad link confined → `[MEDIUM]`, widespread → `[HIGH]`. Inherited, not authored |
| **H1** | 5 | `SUMMARY-02` — HTML validity. MUST, `Step 2` |
| **A1–A5** | 5+3+5+2+3 | `SUMMARY-10…14`. MUST — `accessibility-checklist.md:3` reads *"Every `/aid-summarize` output **must** meet these criteria"*, the declaring document Step 1 needs. `Step 2` → `[MEDIUM]` |
| **C1, C2** | 4 + 4 | `SUMMARY-20/21` — WCAG ratios, one row per failing token pair. MUST, `[MEDIUM]` |
| **S2** | 2 | `SUMMARY-03` — self-contained, no external fetch. MUST, `[HIGH]`: an offline reader gets a broken page, so the radius has escaped the artifact |
| **T1, T2, T3** | `block` (**0 pts**) | `SUMMARY-30/31/32` — visual fidelity, `[HIGH]` per failing visual |
| **NM** | `block` (**0 pts**) | `SUMMARY-04` — no Mermaid runtime, `[HIGH]` |
| **K1** | 10 | **The same rule as COV**, at *judgment* evidence instead of mechanical: the human names the docs whose information is absent; each becomes a row |
| **K2** | 15 | Universal class 2 (*Contradiction*) — `SUMMARY`'s intent authority is "the KB it summarises", so the KB wins. `Step 2`. This is also FR-F2 (§3) |
| **V1** | 5 | Split three ways — §1d |

Two results worth stating rather than leaving as side effects. **COV and K1 were one criterion
wearing two hats**, worth 25 of 98 points between them; under the catalog they are one rule with
two Evidence modes — exactly the mechanical/judgment distinction feature-002 already requires
every rule set to declare. And **four checks that "block DONE" carried zero grade weight**; their
blocking status was prose only. Under rule rows they carry `[HIGH]`, so the rule set is **smaller
than the points table and strictly stronger**.

**The mapping is not invented here.** `state-validate.md:26–39` already carries a check→severity
translation table, and for A1–A5, A3, C1 and C2 it already says `[MEDIUM]` — which is what
feature-001's Step 2 independently produces. FR-F6 mostly **ratifies** that table into the
catalog. It disagrees in exactly two places: COV is currently `[CRITICAL]`, which under
feature-001's scale requires an escaped radius **and** non-local correction (regenerating
`kb.html` is local, so it cannot be CRITICAL); and L1/L2/H1 are `[HIGH]` where the universal
taxonomy gives `[MEDIUM]` for a confined instance. Both are re-derived.

#### 1c. The fate of each script

| Artifact | Fate |
|---|---|
| `grade.sh` | **Byte-unchanged.** Feature-002 claims five comment lines, feature-003 one; this feature claims **none**. NFR-1 holds trivially |
| `grade-summary.sh` | **Retained, gutted, and renamed `emit-summary-findings.sh`.** *Keeps:* the COV `doc_set` awk parse (91–103), the four validator invocations, the per-check pass/fail detection (257–313, 333–354). *Loses:* `WEIGHTS`, `PARTIAL_SCORES`, `letter_grade()`, `grade_order()`, `grade_from_order()`, `MACHINE_GRADE`, `HUMAN_GRADE`, `OVERALL_GRADE`, the `manual-checklist.json` read (366–377), and the A-−or-better exit semantics (593–598). *Gains:* one `writeback-ledger.sh --append-finding --rule SUMMARY-NN` call per failed check. *Exit codes* move to the linter alphabet — `0` clean, `1` findings emitted, `2` usage — per `.aid/knowledge/coding-standards.md:226–229`, matching `check-gaps.sh` and `plan-resume.sh`. **The rename is not cosmetic:** a script named for a grade it no longer computes is exactly the drift this feature exists to remove, and a misnamed script is how the second backend grew |
| `manual-checklist.sh` | **Retained, de-scored.** `score_k1/score_k2/score_v1` and the three `*_score` JSON keys go. Keeps `K1_answer`, `K2_answer`, `V1_answer`, `notes`, `html_file`, `timestamp`. Becomes an **answer recorder** — which its own header already describes. `--input` becomes a schema validator rather than a rescorer |
| `manual-checklist.json` | **Retained as a precondition artifact**, not a score carrier. Its `*_answer` values drive human-authored ledger rows; its *existence* gates APPROVAL (§1d item 3) |
| `knowledge-summary/grading-rubric.md` | The Two-Grade Model (17–45), the weight column of the check table (48–72), the percentage ladder (85–123), and the four hard rules (125–147) are **deleted**; the file becomes a pointer to `review-rubrics/summary.md` plus the per-check *pass criteria* prose (176–265), which is genuinely useful and is what feature-002 re-derives the rules from |

#### 1d. The three binary verdicts, each with its replacement

**Verdict 1 — the essence gate** (`canonical/skills/aid-discover/references/state-review.md:442–466`). Its condition 1 is *"zero open
`[FIDELITY]` rows"*, and the file already says the gate *"is realized entirely through the merged
rows. No separate boolean, no AND to reconcile."* So STATE.md Q12's "third backend" claim is
overstated for the derivation and correct for one part: **condition 2 is a ratio** —
*"load-bearing essence-coverage ≥ 90%"* — whose denominator is a runtime claim by an agent with no
ledger carrier. That is the same unfalsifiable-assertion class feature-005 §4 rejected for
per-rule invalidation.

*Replacement:* condition 1's derivation moves from Description-substring matching to
**`Rule`-column matching** over feature-002's eighth column — a closed enum instead of a
substring, strictly more robust. Condition 2 is **retired in favour of the conservative rule
already written beside it** (*"any open `[ESSENCE-GAP]` row … caps the verdict at FAIL"*). The
argument is REQUIREMENTS' own argument for cutting FR-B8: at an A+ floor any open non-MINOR
finding fails the gate regardless, so the ratio protects the *metric*, not the *gate*.

**Verdict 2 — the act-back gate** (`canonical/skills/aid-discover/references/state-review.md:468–495`). Identical shape, identical
treatment. Condition 1 becomes *zero open rows whose `Rule` matches `^KB-2[0-6]$`* — the set
feature-002 §6 already authored. Condition 2 (STATED-coverage ≥ 90%) retires on the same argument.
Condition 3 (quality-contract section presence) is already an ordinary `[ACTBACK]` row; it becomes
a `Mode: mechanical` rule row with a runnable grep in Evidence.

**Verdict 3 — summarize's V1.** The one true hard stop, and it is three different things wearing
one name:

1. **A specific visual is illegible or broken** → a `SUMMARY-30/31/32` row, `[HIGH]`, the
   human-evidence counterpart of T1/T2/T3. Grade ≤ `D+`, fails any sane minimum, routes to FIX.
   The ordinary case, and the one `knowledge-summary/grading-rubric.md:161–174`'s dogfood
   incident describes.
2. **The page produces nothing usable** — nothing renders, the toggle is dead, the file will not
   open → **`grade.sh --non-functional`**. This matches the flag's documented meaning: its
   `--explain` output at **`grade.sh:80`** reads *"non-functional flag set: build/run failed or
   produced no usable output"*, and the usage comment at **`:29`** carries the shorter
   *"forces F (build/run failed)"*. Nothing else in the tree means this.
3. **The checklist has not been answered.** Today `grade-summary.sh:465–467` sets
   `HUMAN_GRADE="F"`, conflating *unanswered* with *failed* — and contradicting its own rubric at
   `knowledge-summary/grading-rubric.md:29–31` and `:123`, which say Overall should read
   *"Pending Human Review"*. → **not a grade at
   all.** APPROVAL requires `manual-checklist.json` to exist; absent → `PAUSE-FOR-USER-ACTION`
   printing the `manual-checklist.sh` command. No grade is produced, so NFR-7 holds and "F means
   two things" disappears.

#### 1e. What is lost, plainly

**Partial credit, and it existed in exactly one place: COV.** Every other AUTO check is already
binary; K1 and K2 have three-valued answers but those become row *counts*, which is finer-grained
counting, not partial credit.

COV's loss is real and asymmetric, and the honest way to state it is with the numbers. Today, on a
22-doc doc-set, one unreferenced doc scores 15/15 (95.5% ≥ 95%) and the run reports **A+**. Under
`SUMMARY-01`, one unreferenced doc is one `[MEDIUM]` row → **C+**. **That is a large tightening,
and it is the point.** The ≥95% band was itself a curve, and *do not grade on a curve* is a
decision already taken. A KB document whose information is absent from the project summary is a
defect; scoring it at zero cost was the bug, not the feature.

The severity anchors carry the weight the points used to, exactly as Q12 predicted: nine
unreferenced docs out of 22 (the old <60% forced-F threshold) is nine `[MEDIUM]` rows → `C-`,
which fails every configured minimum in the tree. **The operational outcome is preserved; the
arithmetic that produced it is gone.** Shipped un-softened, and noted in the changelog — the fix
for a newly-failing summary is FIX adding the missing section, not a lowered bar.

### 2. FR-F1 — the settings gate

#### What it asserts

`.aid/settings.yml` carries `minimum_grade`, and **nothing rejects a wrong value**:

```bash
sed 's/A+/BOGUS-GRADE/' .aid/settings.yml > /tmp/s.yml
bash canonical/aid/scripts/config/read-setting.sh --file /tmp/s.yml \
     --skill specify --key minimum_grade --default A
# prints: BOGUS-GRADE      exit 0
```

**A key-name correction the requirement needs:** `discovery.doc_set` is a **legacy alias**.
`read-setting.sh:306–308` maps `discovery.doc_set` and `discovery.term_exclusions` onto
`knowledge.doc_set` / `knowledge.term_exclusions`, which is where the live file stores them. The
gate validates the canonical `knowledge:` block and accepts the dotted path as a read alias only.

Ships as `canonical/aid/scripts/config/lint-settings.sh`, asserting:

| Key | Assertion | Enum source |
|---|---|---|
| `minimum_grade` (global + every `<skill>.minimum_grade`) | membership in the **closed 16-value ordered set** | `canonical/aid/templates/grading-rubric.md:62` |
| `type` | `brownfield \| greenfield` | `aid-config/SKILL.md:143` |
| `source_control` | `none \| git \| svn \| mercurial` | `aid-config/SKILL.md:144` |
| `heartbeat_interval` | non-negative integer | `aid-config/SKILL.md:146` |
| `name` | non-empty, no whitespace | `aid-config/SKILL.md:141` |
| `description` | non-empty, single-line | `aid-config/SKILL.md:142` |
| `knowledge.doc_set` rows | `<file>.md\|<owner>\|required\|optional` — three pipe-delimited fields, first ends `.md`, third in a closed enum | the live file's shape; `grade-summary.sh:91–103` is its only parser today |
| `knowledge.term_exclusions` | a YAML block list of non-empty scalars | — |
| `knowledge.source` | non-empty scalar | `aid-config/SKILL.md:160` |
| `format_version` | integer **if present** — not required | absent from the template, `3` in the live file |
| unknown top-level key | reported, not failed (advisory) | forward-compatibility |

**Do not invent the grade check — and do not reuse the existing one.** `^[A-F][+-]?$` already
exists five times (`execute/writeback-state.sh:1161` and `:1420`,
`summarize/writeback-state.sh:155` and `:204`, `dashboard/scripts/write-setting.sh:103`), and
`execute/writeback-state.sh:109` calls it *"grade.sh's own output alphabet"* — which is wrong by
exactly two values: it admits `F+` and `F-`, not in the canonical 16. Those five validate grade
*outputs*, where over-permissiveness is harmless. **The settings file is an input to every gate,
where it is not** — so `lint-settings.sh` uses the closed enum, and the five regex sites are
logged as a consistency note rather than edited.

`/aid-config` already has a Validation table (`canonical/skills/aid-config/SKILL.md:137–146`), so FR-F1 is **mechanising an
agent-enforced prose table** and extending it to the four `knowledge.*` keys that same file
explicitly excludes (*"deliberately does not expose these"*, line 152).

#### Where it runs — both, and the second half is affordable only because feature-006 landed

```bash
grep -rhoE 'read-setting\.sh (--skill [a-z-]+ --key [a-z_]+|--path [a-z_.]+)' canonical/ \
  | sort | uniq -c | sort -rn
# measured: 27 minimum_grade reads across 10 skills, 3 discovery.doc_set,
#           2 discovery.term_exclusions. Re-derive rather than trusting these numbers.
```

| # | Site | Catches | Required |
|---|---|---|---|
| 1 | `/aid-config` Step 6, after each write, and Mode-1 INIT completion | the writer's own mistakes | **yes** |
| 2 | `aid-discover` GENERATE, beside Step 5a's citation lint | the *other* writer — `knowledge.doc_set` / `term_exclusions` are discovery-written | **yes** |
| 3 | `aid-deep-review` INTAKE | **a later hand-edit, at the moment it is about to loosen a gate** | **yes** |
| 4 | `aid-summarize` VALIDATE (reads `doc_set` for COV) | a hand-edited doc-set reaching the coverage check | optional |

**Site 3 is the answer to the placement question, and it is cheap for one reason:**
feature-006 §2 collapses every `minimum_grade` read into `aid-deep-review`'s INTAKE. Before 006
this would have been 32 call sites and a maintained exclusion list; after it, one invocation per
graded review. **Sequencing this feature last is what makes consumption-time validation
affordable rather than a design compromise.**

`aid-config` is not a `grade.sh` site, so no `check-gaps.sh` gate is needed at site 1.

#### Exit codes, and the fourth AC's honest reading

Linter alphabet per `.aid/knowledge/coding-standards.md:226–229` — the same reasoning feature-004 §7 used to
split `check-gaps.sh` from `gap-register.sh`: `0` valid, no output; `1` violations, each printed as
`<dotted.path>\t<value>\t<expected>` on stdout with diagnostics on stderr; `2` usage error or
unreadable file.

**No `--fix`, and no diff-against-prior mechanism.** The AC *"a settings change that loosens
`minimum_grade` is surfaced rather than applied silently"* cannot mean diffing against a prior
value, because nothing records one. It is satisfiable in exactly one honest way: **the gate names
the resolved minimum in its output at every site**, so a loosened bar is printed at the moment it
is used. Anything stronger needs a settings-history file — new durable state for a SHOULD-shaped
concern. The AC's wording is amended to match.

### 3. FR-F2 — the adversarial summary pass

#### It is not a gate beside K2; it is K2's evidence, upgraded

`state-manual-checklist.md:16` already asks a human *"are the HTML's numeric/named facts accurate
against the source KB?"*, backed by `spot-check-facts.sh` and a **5-to-10-fact spot-check**
(`knowledge-summary/grading-rubric.md:187` — **not** the top-level
`canonical/aid/templates/grading-rubric.md`, which is **83** lines (`wc -l`); two files share that
basename and every citation below is qualified accordingly). FR-F2 replaces the spot-check with an agent sweep of the whole document,
invoked as `/aid-deep-review` with a manifest whose `artifacts:` is `.aid/knowledge/kb.html` and
whose `rule_set` is `review-rubrics/summary.md`. **K2's question stays** — the human confirms or
extends the agent's rows — because Q12 decided kind A comes *in addition to* kind E.

That is what makes "the only artifact carrying two review kinds" concrete rather than a label:
kind A produces rows; kind E confirms them and adds V1, which no agent can produce because no
agent sees a rendered page.

#### The dependency, stated precisely — and it is not the one the Notes named

The Notes said FR-F2 needs a **NARRATIVE-family** rule set. Read against feature-002 §4 that is
wrong in a way that matters: `SUMMARY` is assigned to the **Presentation** family, NARRATIVE is
*KB, DOCUMENTATION, REPORT, RESEARCH, ADR*, and feature-002's AC requires the routing table to
resolve an artifact to **exactly one** rule set. So `SUMMARY` cannot inherit both.

The resolution needs no change to feature-002's design: **family = Presentation, and the
content-truth criteria live in the `SUMMARY` class file** — which feature-002 §9 already commits
to authoring, and whose §3 already declares `SUMMARY`'s intent authority as *"the KB it
summarises"*. **feature-002's spec has been amended** to require those content-truth rows
explicitly.

The dependency splits, and only one half blocks:

- **Blocking:** `review-rubrics/summary.md` must exist with the universal taxonomy inherited —
  specifically class 2 (*Contradiction*). That is FR-F2's minimum viable criterion. Absent it,
  **FR-F2 is a criteria gap.**
- **Non-blocking:** the borrowed claim–evidence and durable-citation rows. Absent, FR-F2 runs
  against the Presentation family plus the `SUMMARY` class rows and records the missing criteria
  as `[GAP:CRITERIA:NB]` under feature-002 §4's graduated fallback — the decision that exists
  precisely so the catalog is useful before every class is complete.

### 4. FR-F3 — the frontmatter-lint wiring, and the M2 subtraction

#### The invokers today, corrected

STATE.md Q12 says *"only the test suite and the dashboard call it"*. Measured, that is imprecise
in both directions:

```bash
grep -rn 'lint-frontmatter' canonical tests dashboard .github .aid/knowledge
```

- `canonical/aid/scripts/migrate/migrate-kb-frontmatter.sh:826` — a post-APPLY verification pass.
  **An invoker Q12 missed.**
- `tests/canonical/test-frontmatter-lint.sh`, `test-kb-forward-authored-marker.sh:59`,
  `test-migrate-kb-frontmatter.sh:41`, `dashboard/server/tests/…:121`.
- `.github/workflows/test.yml:155` — the `kb-hygiene` CI job, plus a repo-local strict guard at
  `:158`. **This is what Q12 called "the dashboard".** The dashboard only mentions it in comments.
- **No skill state.** `grep -c lint-frontmatter canonical/skills/` → `1`, a prose cross-reference
  at `canonical/skills/aid-discover/references/state-generate.md:863`.

And the KB already *claims* it is wired: `quality-gates.md:340–342` heads a table *"Mechanical
Gates Run by the Orchestrator … so a defect is caught at GENERATE rather than one phase later at
REVIEW"* and lists the frontmatter lint at line 348. That holds for the citation lint (Step 5a) and
closure (Step 5b) and is **false for this one**. FR-F3 makes the KB true rather than correcting it
downward.

#### The wiring site is pre-sanctioned

`canonical/skills/aid-discover/references/state-generate.md:863` reads: *"This gate is the model for moving any MECHANICAL authoring rule
from 'self-reported in GENERATE / caught in REVIEW' to 'mechanically gated in GENERATE' (cf.
`lint-frontmatter.sh` for frontmatter)."*

So: a new **Step 5a-ii — Frontmatter Lint Gate**, immediately after Step 5a, in the same shape —
run; exit 0 → CHAIN; exit 1 → partition findings by doc, resolve each doc's owner from the declared
doc-set, re-dispatch the owning agents in parallel with the finding list, re-run, cap at 2 rounds,
residual escalates to a Q&A entry. `aid-update-kb` inherits it for free.

**One path-form correction, because it would ship broken otherwise.** `canonical/skills/aid-discover/references/state-generate.md:850`
invokes the citation lint as `bash .claude/aid/scripts/kb/kb-citation-lint.sh`.
`rewrite_install_paths` rewrites only `canonical/...` forms, so a hardcoded `.claude/aid/` path in
a canonical body ships literally to codex, cursor, copilot-cli and antigravity — Q3 defect (c)
generalised. `grep -rn '\.claude/aid/' canonical/ | wc -l` → **12 lines across 8 files.** The new
gate uses the `canonical/...` form; line 850 is corrected as collateral since the step beside it
is being edited.

#### The subtraction — the named M2 checks that retire

From `canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md`:

| M2 check | Lines | Verdict |
|---|---|---|
| **8. Frontmatter completeness** — *"Missing required field = `[HIGH]` `[FM-MISSING]`. Invalid field value = `[HIGH]` `[FM-INVALID]`."* | **87–89** | **Retires in full.** The lint's required set is exactly `objective`, `summary`, `sources` (`lint-frontmatter.sh:360–400`) and it emits the identical two tags. This is the "same defect at two severities" case: today M2 writes a `[HIGH]` row while CI fails the build |
| Check 8's own severity anchors | inline at **88–89** (line 87 is check 8's header) | **There is no separate anchor-list entry for check 8.** `[FM-MISSING]` and `[FM-INVALID]` appear nowhere else in the file — confirm with `grep -n 'FM-MISSING\|FM-INVALID' canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md` — so they retire *with* check 8 and need no second edit |
| The `[AUTHORING-FM]` severity anchors | **149** and **150** | **Split, and only one moves.** Line 149 (`Missing audience:/owner:/tags:`) is check 12's anchor and follows check 12's partial retirement below. **Line 150 (`No concern tag in tags:`) is check 13's anchor and STAYS**, because check 13 stays. Neither is at 148 (`[AUTHORING-LAYOUT]`, index absence) nor in the 189–194 region (the altitude/KB-coverage anchors `[KB-MISSING]`, `[CAL-COVERAGE]`, `[CAL-HOLLOW]`, `[CAL-TRANSCRIPTION]`, `[CAL-DEFERRAL]`) |
| **12. Required frontmatter fields `[AUTHORING-FM]`** — `audience:`, `owner:`, `tags:` *"in addition to the required `objective:`, `summary:`, `sources:` **checked by item 8 above**"* | **113–116** | **Partially retires.** The lint validates `owner` non-empty and `tags`/`audience` list-shape **only if present** — it does not require presence. The shape half retires; the presence half stays unless the lint gains `--fail-on-skip`. Its own wording already routes the other three to item 8 |
| **13. Concern tag in `tags:`** | 118–122 | **Stays** — needs `concern-model.md` semantics the lint does not model |
| 9/10/11 layout, 14 diagram absence, 15/16 judgment | 98–111, 124–128, 132–143 | **Stay.** Not frontmatter |

**The residue, stated because a reviewer will look for it.** `lint-frontmatter.sh:14–19` has a
day-one **soft-skip**: a doc carrying *none* of the structured fields is skipped as pre-migration.
So wiring the lint does not catch a doc with no structured frontmatter at all — the worst case. On
this repo the hole is not exercised:

```bash
bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge --verbose
# Checked: 16 docs | Skipped: 5 docs | Findings: 0 -- exit 0
# all five skips are category/source skips; ZERO "SKIP (pre-migration)" lines
```

Two consequences: the gate is **safe to wire today** (it passes clean, so it does not fail the
phase on landing), and **`lint-frontmatter.sh` gains `--fail-on-skip`, additive and default-off**,
so check 8 retires with no remainder. The flag is safe precisely because no doc in this repo
triggers the skip.

### 5. FR-F4 — the BLUEPRINT review

#### What is actually missing

`BLUEPRINT.md` is created at `aid-plan/references/first-run-loop.md:89` (step 4a), immediately
*before* the per-deliverable review at step 4 — and it is in neither review's artifact set:

- `first-run-loop.md:142` — `{{ARTIFACTS}}` = *"the deliverable section just appended to
  `PLAN.md` + the SPECs of the features it assigns"*.
- `review-deliverables.md:37` — `{{ARTIFACTS}}` = *"full `PLAN.md` + every
  `.aid/works/{work}/features/feature-*/SPEC.md`"*.

So the fix is **not a new state, not a new dispatch, not a new ledger.** The BLUEPRINT is authored
one step before a review that already runs, already writes `.aid/.temp/review-pending/plan.md`, and
already grades it. It is a one-line edit per site — and after feature-006, an `artifacts:` entry in
the manifest rather than prose.

#### Two touchpoints, because the artifact is authored in two phases

The Tasks table is legitimately empty at Plan (`first-run-loop.md:99`, `:102–103`). So one review
cannot cover the whole file:

| Site | Line | In scope | Out of scope |
|---|---|---|---|
| `aid-plan` per-deliverable | `first-run-loop.md:142` | Objective, Scope, Gate Criteria, Dependencies | `## Tasks` — legitimately `_none yet_` |
| `aid-plan` whole-plan | `review-deliverables.md:37` | every delivery's BLUEPRINT, same scope | `## Tasks` |
| `aid-detail` per-delivery | `first-run.md:95` | `## Tasks` against the DETAIL files just written | the rest, already graded |
| `aid-detail` whole-detail | `review.md:40` | `## Tasks` across all deliveries | the rest |

#### One authorship gap FR-F4 exposes, and must close

`grep -rc BLUEPRINT canonical/skills/aid-detail/` returns **zero**. `aid-detail` never mentions
`BLUEPRINT.md`, so on the Full path the Tasks table stays `_none yet_` forever despite
`first-run-loop.md:99` promising otherwise. Adding the BLUEPRINT to `aid-detail`'s artifact set
would therefore land a **guaranteed-failing gate** (universal class 4, *Missing content*,
`[HIGH]`).

**So FR-F4 also makes `aid-detail` write the Tasks table. This is a parity fix, not new design:**
`shortcut-engine.md:636` already implements exactly this on the Lite path (*"Completes
BLUEPRINT.md's real `## Tasks` table"*, and `:915` promotes
`| task-001 | Pending | -- | -- | -- |`). The Full path is the one missing it.

Two stale claims in the same neighbourhood, both unclaimed by 001–006:
`delivery-blueprint-template.md:5` says *"Written once by aid-plan / aid-specify"* —
`grep -rc BLUEPRINT canonical/skills/aid-specify/` is **zero**; correct to `aid-plan`
(Objective/Scope/Gate Criteria) + `aid-detail` (Tasks). And line 27 says *"The grade.sh pass uses
these as the rubric"* — Gate Criteria are *criteria*, not a rubric, and after feature-002 the
rubric is a catalog entry and `grade.sh` uses neither.

### 6. FR-F5 — the per-section specify review

#### Three missing mechanics, one worse than missing

`aid-specify/references/state-continue.md` step 4 (67–101) versus its own `state-review.md`:

| | per-section (step 4) | final REVIEW |
|---|---|---|
| Ledger path | **none** | `.aid/.temp/review-pending/specify-<feature>.md` (`:37`, `:52`) |
| Grade call | **none** — *"The grade is calculated"* (`:82`) is an agent assertion | `bash canonical/aid/scripts/grade.sh --explain …` (`:52`) |
| Severity vocabulary | `Minor/Low/Medium/High/Critical` — **bare words** (`:82`) | bracketed tokens |

**The third is the one that bites.** `canonical/aid/templates/grading-rubric.md:27` states it outright: *"An issue written
`Minor: missing comment` will be counted as zero issues, producing a silent A+."* So the
per-section review's vocabulary is the exact form the grading rubric names as producing a false
pass — and with no ledger and no `grade.sh` call, nothing catches it.

#### The structural problem feature-006 did not see

Feature-006 §6 listed `aid-specify | state-review.md, state-continue.md | manifest + CHAIN →
/aid-deep-review`. **That is unimplementable for `state-continue.md`.** Feature-006 §8 defines
CHAIN's new use as a *terminal hand-off* — *"no control returns"* — and both review skills HALT at
DONE. Step 4 sits **inside a per-section loop** that must return to step 1 for the next section, so
a terminal hand-off would end the skill after the first section. **feature-006's spec has been
amended** to exclude `state-continue.md` from its migration.

Two alternatives were considered and rejected. *Restructure the loop* — write all sections, then
one deep review — defers all feedback to the end, so a bad first section is discovered after the
whole spec is written; the loop exists for that reason. *Make the per-section pass a coverage unit
of the eventual deep review* fails on correctness: step 4's own first check is *"Does it contradict
other completed sections in this SPEC?"*, so a section reviewed at time *T* is not the same
artifact at *T+n*, and per-section coverage must never pre-clear the final pass — the exact FR-A4
hazard feature-006 §2 made structural.

#### The design

Step 4 becomes an inline **screen** with `aid-light-review`'s three internals and none of its skill
wrapper:

1. **Dispatch `aid-screener` at small tier**, replacing today's Large `aid-reviewer`.
   Independently justified: a section-level pass wants the bounded prompt, and `aid-reviewer` at
   Large is the most expensive agent in the roster run once per section.
2. **The skill writes the returned rows** via `writeback-ledger.sh --append-finding` into
   `.aid/.temp/review-pending/specify-<work>-<feature>.md` — **the same ledger the final REVIEW
   state grades.** That is FR-F5's ledger path, and it means the per-section pass now *feeds* the
   one arithmetic instead of running a private one. (The screener has no `Bash`, so the skill must
   be the writer.)
3. **`check-gaps.sh` then `grade.sh`** on that ledger, routing against
   `read-setting.sh --skill specify --key minimum_grade`. That is FR-F5's grade call, and it is
   `grade.sh` — so NFR-7 holds.

The bare-word vocabulary at line 82 is replaced by bracketed tokens; the relative rubric path at
line 81 is feature-001's edit, absorbed here.

`check-gaps.sh` is not optional: FR-F5 makes `state-continue.md` the **19th** `grade.sh` site, and
feature-004's totality oracle asserts every file invoking `grade.sh` mentions `check-gaps.sh` at an
earlier line. That oracle is total over a mechanically derived file set, so it requires the gate
automatically — **a hand-off consumed, not created.**

### 7. Affected-artifact inventory and region ownership

Cross-checked mechanically against features 001–006.

**New files (4):** `canonical/aid/scripts/config/lint-settings.sh` — which lands in an **existing**
emitting directory (`read-setting.sh` is already present under every tool root), so the emission
caveat features 003/004/005 carry for the new `review/` **directory** does not apply;
`canonical/aid/templates/review-rubrics/summary.md` (**authored by feature-002**, listed so the
dependency is visible); `tests/canonical/test-review-coverage-gaps.sh`;
`tests/canonical/test-lint-settings.sh`.

| File | Claimed | Cross-check |
|---|---|---|
| `summarize/grade-summary.sh` | `18–30`, `200–237`, `242–249`, `359–495`, `497–598` + the rename | **Unclaimed by 001–006.** Feature-002 §14 explicitly defers it here |
| `summarize/manual-checklist.sh` | `4–7`, `86–111`, `149–187`, `189–206` | Unclaimed |
| `knowledge-summary/grading-rubric.md` | `1–5`, `17–45`, the weight column of `48–72`, `85–123`, `125–147` | Unclaimed. Feature-002 §3 *cites* it as `SUMMARY`'s manner authority and claims no edits |
| `aid-summarize/references/state-validate.md` | `3`, `6`, `21–58`, `62` | Feature-004 claims one inserted `check-gaps.sh` line before 55. Disjoint from the severity table |
| `.../state-manual-checklist.md` | `3`, `17`, `22–27`, `29–39` | Unclaimed. Line 31 carries a verified defect: *"Re-run `grade.sh` — it reads `manual-checklist.json`"* — `grep -c manual-checklist canonical/aid/scripts/grade.sh` → **0**. It means `grade-summary.sh` |
| `.../state-approval.md`, `.../state-generate.md` | `3`, `5`, `15–17`; `353–357` | Unclaimed |
| `aid-summarize/{SKILL.md,README.md}` | `SKILL.md` 9, 99–105, 113, 202, 231–232; `README.md` 13–14, 34 | Unclaimed |
| `discovery-state-template.md` | `62–63` (Machine/Human Grade rows → one `Grade` row) | Feature-004 claims *insertion after 80*. Disjoint |
| `aid-housekeep/references/state-summary-delta.md` | `320` | Unclaimed |
| `aid-discover/references/state-review.md` | `447–466`, `473–495` | 7–11 / after-427 / 575–576 feature-004; after-424 feature-003; 355 / after-357 / 404–411 feature-005. **Disjoint** |
| `.../reviewer-prompt-anatomy.md` | `87–89`, the FM anchor entries, `113–116` (partial) | Feature-005 claims **223–224** only. Disjoint |
| `.../state-generate.md` | **insertion after 862**; `850` corrected as collateral | Unclaimed |
| `aid-config/SKILL.md` | `137–146`, `181–190` | Unclaimed. **Two verified defects:** line 189's documented `read-setting.sh --key minimum_grade --default A` **exits non-zero** (the script requires `--skill X --key Y` or `--path A.B`), and 181–184 states a *two*-tier resolution where the script and `canonical/aid/templates/grading-rubric.md:75` both state three |
| `grading-rubric.md` | `66–68` | Feature-001 claims 5–13 and states 15–63 unchanged. 66–68 documents `review.minimum_grade` as the storage location, which `read-setting.sh:245`/`:303` treats as **legacy**. Collateral, unavoidable: FR-F1's gate cannot cite a retired key path |
| `aid-specify/references/state-continue.md` | `67–101` | Feature-001 claims line 81; feature-006 §6 now **excludes** this file. Collateral on 81 accepted |
| `aid-plan/references/first-run-loop.md` | `142` | One line inside feature-006's span — declared collateral |
| `aid-plan/references/review-deliverables.md` | `37` | Feature-005 claims 42–43. Disjoint |
| `aid-detail/references/first-run.md` | `95` + the Tasks-table write | Feature-006 Tier-1; feature-004 gate. Collateral |
| `aid-detail/references/review.md` | `40` | Feature-005 claims 45–46. Disjoint |
| `delivery-blueprint-template.md` | `3–5`, `27`, `33–40` | **Zero mentions across 001–006.** Fully unclaimed |
| `canonical/aid/templates/settings.yml` | additive: `format_version`, a schema comment naming the lint | Feature-006 adds two `review.*` keys. Both additive, disjoint |
| `.aid/knowledge/quality-gates.md` | `341–342`, `348`, `388`, the frontmatter row of `364` | Disjoint from 001–005's claims. Carries a Change Log row + a `README.md` revision-history entry |
| `.aid/knowledge/artifact-schemas.md` | `207`, `640` | Unclaimed |
| `tests/canonical/test-grade-summary.sh` | rewritten, not deleted — §9 | Unclaimed |

**`aid-reviewer/AGENT.md` — this feature claims nothing.** The union of 001–006's claims leaves
18 unclaimed content lines, all behaviour-neutral leftovers **except line 18** — *"Tag every issue
by severity: `[CRITICAL]`, …"* — which instructs the reviewer to *assign* severity, contradicting
feature-001's line-36 replacement and feature-002's severity-as-lookup. Feature-002 claims 17 (the
*source*-tag bullet) but nobody claimed 18. **It belongs to feature-006's FR-A10 residual set by
that feature's own charter, and feature-006's spec has been amended to add it** — handed back, not
annexed. The review-kind taxonomy and the two-kinds statement live in feature-002's
`review-rubrics/INDEX.md`, not the agent body, so FR-F2 needs no agent edit either.

**Regenerated, never hand-edited:** `.aid/knowledge/INDEX.md`, `kb.html`,
`site/src/content/docs/reference/skills.md`, and the seven rendered trees.

### 8. Hand-offs and amendments to features 001–006

Written down because STATE.md Q7 #8 exists precisely because one was left implicit. **All five
have been applied.**

| # | To | Amendment |
|---|---|---|
| 1 | feature-006 §6 | `aid-specify`'s migration is **`state-review.md` only**; `state-continue.md` is excluded and receives FR-F5's mechanics |
| 2 | feature-006 §6 | AC-11's per-caller decrease **excludes `state-continue.md`**; re-measure after this feature |
| 3 | feature-006 §4 | `AGENT.md` **line 18** added to FR-A10's residual list |
| 4 | feature-002 §3 | `review-rubrics/summary.md` must carry **content-truth rows**; `SUMMARY` stays Presentation family |
| 5 | this feature's own AC | *"NARRATIVE-family rule set"* → *"`review-rubrics/summary.md`, inheriting the universal defect taxonomy"* |

Consumed, not created: feature-004's 18-site gate oracle (FR-F5 makes 19; the oracle is total, so
it enforces the new gate itself), feature-003's `writeback-ledger.sh` and its `--rule` rejection,
feature-005's `plan-resume.sh`, and feature-006's manifest plus its collapse of 32 `minimum_grade`
reads into one.

### 9. Migration and compatibility

**NFR-1** — `grade.sh` is byte-unchanged; §10 oracle (d) asserts it.
**NFR-5** — existing ledgers are unaffected: nothing here changes a cell `grade.sh` reads.
**NFR-6** — reproducibility improves, because the second arithmetic is gone.

**In-flight summaries.** A `kb.html` graded under the points model has its grade recorded in
`.aid/knowledge/STATE.md`'s Machine/Human Grade rows, which §7 collapses to one `Grade` row. A
historical two-grade value is **not back-converted** — it is left as recorded history with the
model change noted in the Change Log. Re-deriving a letter for a run whose findings were never
itemised would be fabrication.

**The coverage baseline.** `test-grade-summary.sh` has 47 keys in
`tests/coverage-baseline.tsv`. `coverage-parity.sh` fails only on **removed or reduced**
assertions, so the suite is **rewritten, not deleted** — the scoring assertions become
row-emission assertions one-for-one, and the rename re-bases the keys with one `sed`.

### 10. Verification strategy

Ships as `tests/canonical/test-review-coverage-gaps.sh` plus `test-lint-settings.sh`. **Every
baseline was produced by running the command.**

**FR-F1**

```bash
# (a) BEHAVIOUR. Non-trivially false today: read-setting.sh returns BOGUS-GRADE with exit 0.
lint-settings.sh --file fx-bad-grade.yml   ; [ $? -eq 1 ]
lint-settings.sh --file fx-bad-docset.yml  ; [ $? -eq 1 ]
lint-settings.sh --file fx-good.yml        ; [ $? -eq 0 ]
lint-settings.sh --file .aid/settings.yml  ; [ $? -eq 0 ]    # the live file must pass
lint-settings.sh --file /nonexistent       ; [ $? -eq 2 ]

# (b) ENUM FIDELITY -- the enum is DERIVED from the rubric, not restated.
sed -n '/^## Grade Ordering/,+3p' canonical/aid/templates/grading-rubric.md \
  | grep -oE '\b[A-F][+-]?\b' | sort -u                      # 16 values
for g in $(that list); do lint-settings.sh --grade-only "$g" || fail "$g rejected"; done
for g in F+ F- Z A++ ''; do lint-settings.sh --grade-only "$g" && fail "$g accepted"; done

# (c) TOTALITY over the gate-relevant key set, mechanically derived.
grep -rhoE 'read-setting\.sh (--skill [a-z-]+ --key [a-z_]+|--path [a-z_.]+)' canonical/ | sort -u

# (d) PLACEMENT -- the three required sites name the lint.
```

**(b) is the assertion a weaker suite would omit.** Without it the gate restates the alphabet and
becomes the *sixth* rival definition — the exact regression feature-001's AC-1 exists to prevent.
Its negative half is non-trivially **true** today: `^[A-F][+-]?$` accepts `F+` and `F-` at five
sites.

**FR-F2** — `summary.md` exists and is routed; the kind-A pass is dispatched and is separate from
the machine/human gates; the class registry states `SUMMARY | A + E`; a contradiction fixture
yields a row with the KB as winner. **(a) is deliberately a gate on feature-002:** if `summary.md`
is absent the suite fails and the criteria gap is *visible* rather than silently unmeasured.

**FR-F3**

```bash
grep -rc 'lint-frontmatter' canonical/skills/                     # measured: 1 (prose cross-ref)
grep -c '\.claude/aid/scripts/kb/' \
        canonical/skills/aid-discover/references/state-generate.md # measured: 1 -> expect 0
grep -rn '\.claude/aid/' canonical/ | wc -l                       # measured: 12 across 8 files
# THE SUBTRACTION, by content anchor (001-006 all edit this file first):
for r in "required field is absent" "[FM-MISSING]" "[FM-INVALID]"; do
  grep -qF "$r" .../reviewer-prompt-anatomy.md && fail "M2 still hand-checks: $r"; done
grep -q 'lint-frontmatter' .../reviewer-prompt-anatomy.md   # the POSITIVE complement
bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge   # measured: 0 findings, exit 0
```

The positive complement is what a one-sided oracle misses: a subtraction that removes the check
**and** the pointer leaves the defect unowned.

**FR-F4** — the BLUEPRINT is in all four artifact sets. The load-bearing baseline is not a total
but a **co-location**: `aid-plan` mentions `BLUEPRINT` in several places and **none of them is on
an `{{ARTIFACTS}}` line**, while `aid-detail` does not mention it at all. Derive both rather than
trusting a quoted figure — three successive reviews of this spec disagreed on the raw total:

```bash
grep -rn 'BLUEPRINT' canonical/skills/aid-plan/                      # several; check each
grep -rn 'BLUEPRINT' canonical/skills/aid-plan/ | grep 'ARTIFACTS'   # expect 0 before, >0 after
grep -rc 'BLUEPRINT' canonical/skills/aid-detail/                    # expect 0 before, >0 after
```
`aid-detail` writes the Tasks table; `## Tasks` is out of scope at Plan and in scope at Detail.
**The last two are the assertions a weaker suite would skip** — the first alone, shipped without
them, produces a review that always fails.

**FR-F5**

```bash
f=canonical/skills/aid-specify/references/state-continue.md
grep -q 'review-pending/specify-' "$f"; grep -q 'writeback-ledger.sh' "$f"
grep -q 'bash canonical/aid/scripts/grade\.sh' "$f"; grep -q 'check-gaps\.sh' "$f"
grep -qE 'Minor/Low/Medium/High/Critical' "$f" && fail 'bare-word severities survive'
grep -rln 'bash canonical/aid/scripts/grade\.sh' canonical/ | wc -l   # measured: 18 -> expect 19
```

**FR-F6**

```bash
# (a) EXACTLY ONE GRADE PRODUCER -- the headline oracle. Two exist today.
grep -c 'letter_grade\|grade_order\|grade_from_order' \
        canonical/aid/scripts/summarize/grade-summary.sh          # expect 0

# (b) THE TWO-GRADE MODEL IS GONE, glob-derived.
grep -rln 'Machine Grade\|Human Grade\|Overall Grade' canonical/ .aid/knowledge/ | wc -l
#   measured: 13 -> expect 0   (site/ regenerated; tests/ rewritten by (e))

# (c) THE POINTS MODEL IS GONE.
awk '/^declare -A WEIGHTS=\(/,/^\)/' .../grade-summary.sh \
  | grep -oE '=[0-9]+' | tr -d '=' | paste -sd+ | bc            # measured: 68 -> expect empty

# (d) NFR-1 -- grade.sh byte-identical.
git diff --stat canonical/aid/scripts/grade.sh                   # expect empty

# (e) COVERAGE PARITY.
grep -c '^test-grade-summary.sh' tests/coverage-baseline.tsv     # measured: 47 keys
bash tests/coverage-parity.sh                                    # must stay clean

# (f) THE VERDICT REPLACEMENTS -- ratios retired, derivation on the Rule column.
grep -qE 'essence-coverage >= 90|STATED-coverage >= 90' .../state-review.md && fail

# (g) V1's THREE-WAY SPLIT -- the discriminating case.
grep -q 'PAUSE-FOR-USER-ACTION' .../state-manual-checklist.md
grep -rqE 'Human Grade.*F|forced to F' canonical/skills/aid-summarize/ && fail 'unanswered == F survives'
grep -q 'grade.sh --non-functional' .../state-validate.md
```

**(a) and (d) are the pair that matters:** (a) proves the second backend is gone, (d) proves the
first was not touched to achieve it. **(g) is the discriminating case** — an oracle asserting only
"no second grade producer" passes trivially on an implementation that keeps `HUMAN_GRADE="F"` for
an unanswered checklist, which is the defect, not the fix.

**What no oracle proves, stated plainly.** *"The adversarial pass actually read the content for
truth"* and *"the human actually opened the browser"* are runtime properties of an agent and a
person. These oracles prove that no second letter grade can be produced, that the ledger is the
only path from a failed check to a grade, that the settings file cannot carry an out-of-enum bar,
that the frontmatter check exists in exactly one place, and that the BLUEPRINT is inside the
artifact set it is graded from.

### 11. Render and profile impact

Per STATE.md concern N3, verified **at this feature's close**: `/generate-profile`, then
`verify_deterministic.py`, then assert `lint-settings.sh` is emitted and executable under each of
the five tool roots plus this repo's own `.claude/` and `.cursor/` installs. **Unlike features
003–005, no emission caveat applies** — `canonical/aid/scripts/config/` is an existing emitting
directory (`read-setting.sh` is already present under every tool root), so only a file is added,
not a directory.

### 12. Out of scope

- Everything features 001–006 own; this feature consumes all of it.
- `grade.sh` itself — **no change of any kind**.
- Back-converting historical two-grade values (§9).
- Editing the five `^[A-F][+-]?$` grade-output regex sites — logged as a consistency note (§2).
- Three Q3-backlog items surfaced here and not fixed: `aid-config/SKILL.md:189`'s documented
  `read-setting.sh` invocation exits non-zero; its 181–184 two-tier resolution contradicts the
  script's three; `state-manual-checklist.md:31` claims `grade.sh` reads `manual-checklist.json`
  when it never has.

### Delivery recommendation

Five, ordered so the largest item is not entangled with the five small ones.

- **D1 — FR-F1.** `lint-settings.sh`, its suite, the three wiring sites, the `aid-config`
  validation table, and `canonical/aid/templates/grading-rubric.md:66–68`. Fully self-contained; ships the
  highest-leverage gap alone.
- **D2 — FR-F3.** The Step 5a-ii gate, the M2 subtraction, `--fail-on-skip`, the
  `quality-gates.md` correction, and the renderer-blind path fix. Independent of D1.
- **D3 — FR-F4 + FR-F5.** Five artifact-set edits, the `aid-detail` Tasks write, and
  `state-continue.md` step 4. Grouped: both are one-line-per-site changes over the same caller
  set, and both consume feature-006's manifest.
- **D4 — FR-F6.** The `SUMMARY` rule application, both scripts gutted, the rename, the rubric
  retirement, the 13 two-grade surfaces, the three verdict replacements, `aid-summarize`'s state
  routing, and the rewritten suite. Largest by far, and the only one whose oracle is a tree-wide
  "exactly one grade producer" sweep.
- **D5 — FR-F2.** The kind-A pass. Last, because it cannot start until feature-002's
  `review-rubrics/summary.md` exists **and** D4 has removed the rival backend it would otherwise
  be graded beside.

D4 gates D5. D1, D2 and D3 are mutually independent and independent of D4.
