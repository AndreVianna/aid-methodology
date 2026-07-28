# Requirements

- **Name:** Review Subsystem Redesign
- **Description:** Make AID's review process objective and resumable, and extract it
  from individual skills into a reusable light/deep review capability.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Initial interview started | /aid-describe |
| 2026-07-27 | Consolidated from the Q1-Q6 discussion recorded in STATE.md | /aid-describe |
| 2026-07-27 | Resolved the three open decisions: two review skills (FR-A1), gap sequencing replaces call-and-return (FR-C9), criteria-vs-evidence boundary for greenfield (FR-C10/C11) | /aid-describe |
| 2026-07-27 | Agent decisions: split into `aid-screener` + `aid-reviewer` (roster 9->10), boilerplate split (FR-A9), explicit `aid-reviewer` rewrite (FR-A10), content-isolation relocation (FR-B9); FR-B5 split into B5a/B5b | /aid-define (decomposition review) |

> **Modality convention.** Every requirement below carries an explicit modality --
> **MUST** / **SHOULD** / **COULD**. This is itself one of the decisions in this work
> (FR-B5a): modality is a primary severity input, so it must be stated, not inferred.
> This document dogfoods that rule.
>
> `SUGGESTION` was removed on 2026-07-27. It could never be grade-bearing, and dropping
> it collapses modality onto the same three values feature-level `## Priority` already
> uses -- one vocabulary instead of two.

---

## 1. Objective

Make the review grade mean something.

Today the grade is computed by a script, which makes it look objective. But the
script's only real input is a severity judgment the reviewer makes by feel, against
four contradictory definitions. So the determinism is a facade: subjective in,
arithmetic out.

The goal is to reduce that subjectivity far enough that the grade becomes what it
should be -- a **distance from the ideal state**, cheap for both a human and a script
to read.

Secondarily: review logic is copy-pasted across the pipeline skills. Extracting it
into a shared light/deep capability shrinks those skills and makes review reusable.

## 2. Problem Statement

Six problems, all observed in the current codebase:

1. **Severity is defined four different ways** across seven files. Two directly
   contradict each other on the most-used band: one says MEDIUM is "incorrect
   behavior", the other says MEDIUM is "incomplete but not wrong".
2. **The reviewer is licensed to use opinion.** Its own constraint reads "Objective
   criteria only. Every issue cites: TASK criterion, SPEC constraint, KB convention,
   or established best practice." The last clause is the leak. A shipped checklist
   asks for "clean code? YAGNI? No over-engineering?" -- none defined anywhere.
3. **There is no way to say "I cannot review this."** Every ledger row asserts
   something about the artifact. A missing coding standard has no representation, so
   the reviewer invents a standard instead of reporting the gap.
4. **A review cannot be resumed.** The ledger records findings, not coverage, so an
   interrupted review cannot distinguish "examined and clean" from "never reached".
5. **Review logic is duplicated.** Six near-identical dispatch blocks, six
   near-identical brief templates, and the REVIEW->GRADE->FIX loop reimplemented in at
   least four places.
6. **The grade has an unguarded bypass.** Marking a finding `OOS` removes it from the
   grade, and unlike `Accepted` it requires no authorization.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| AID maintainer | Owns the methodology and its canonical source | A review process that is consistent, cheap to maintain, and free of duplicated logic |
| Adopter project | Any project that installs AID | Grades that reflect real quality; reviews that improve their KB instead of guessing around it |
| Greenfield adopter | A project with no standards yet | Review that helps establish standards rather than inventing them silently |
| Pipeline agents | The skills and sub-agents that dispatch reviews | One reusable review capability with a clear contract |

## 4. Scope

### In Scope

- Extraction of review into a light (screening) and deep (gate) capability, over two agents.
- Rewriting the `aid-reviewer` agent body, and splitting `agent-boilerplate.md`.
- Revising the KB's agent roster from nine to ten.
- A single canonical severity scale plus a per-artifact-class rubric catalog.
- Removal of "established best practice" and other undefined criteria as valid sources.
- The criteria-gap interrupt: halt, resolve the source of truth, restart.
- Resume: coverage manifest in the ledger, per-unit checkpointing, loop detection.
- The review-path defects catalogued in STATE.md Q3.

### Out of Scope

- The grading arithmetic itself (`grade.sh` counting logic is correct and verified).
- ~~The 7-column ledger's column set.~~ **Now in scope** (2026-07-27): the ledger gains a
  `Rule` column, taking it to eight. Severity and Status must stay at positions 3 and 4
  because `grade.sh` parses by position, so the new column is inserted after Status.
- Rewriting the automated test suites.
- Any change to what the phases themselves produce (REQUIREMENTS / SPEC / PLAN / DETAIL content).

**Deliberately deferred, pending a decision:** closing the `OOS` authorization bypass
(problem 6). Related but separable -- see STATE.md.

## 5. Functional Requirements

### A. Review extraction

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-A1 | MUST | Review is extracted into **two skills** -- `aid-light-review` (screening) and `aid-deep-review` (gate) -- over **two agents**: a new `aid-screener` (small tier; read-only `Read, Glob, Grep` with **no** `Bash`) and the retained `aid-reviewer` (deep). Pipeline skills chain-call the skills instead of carrying review logic inline. The agent roster grows from 9 to 10 -- a deliberate revision of a KB-recorded count, not a violation of it. |
| FR-A2 | MUST | `aid-light-review` computes **no grade**, runs a single pass at cheap tier/effort, and reports findings above a configurable severity floor plus any precondition gaps. |
| FR-A3 | MUST | `aid-deep-review` runs the full severity sweep, writes the ledger, computes the grade via `grade.sh`, and drives the FIX loop with its circuit breaker. |
| FR-A4 | MUST | A clean light pass never shortens, replaces, or pre-clears the deep pass. It may only add findings. |
| FR-A5 | MUST | Deep review performs its own gap detection. It must not assume light review already ran. |
| FR-A6 | MUST | Calling skills invoke the two review skills instead of carrying their own dispatch logic and brief template. Each calling skill gets measurably shorter. |
| ~~FR-A7~~ | ~~SHOULD~~ | ~~Both skills are invocable by any skill, including ones that do not exist yet.~~ **CUT 2026-07-27.** An aspiration with no test — "invocable by a skill that does not exist" cannot be falsified. Nothing else in feature-006 depends on it; the feature drops to 11 FRs. |
| FR-A8 | SHOULD | Review is the terminal portion of a calling phase, so a calling skill **chains forward** into the review skill rather than expecting control to return. This keeps the extraction inside the existing forward-only state contract. |
| FR-A9 | MUST | `agent-boilerplate.md` splits into an **operational** block (heartbeat, cooperative stop-poll -- every agent) and a **discipline** block (adversarial self-review, "enumerate the class", "find nothing more to find" -- deep-review agents only). `aid-screener` must NOT inherit the exhaustiveness mandate: an instruction to be exhaustive is behaviourally incompatible with a cheap bounded pass, and the exhaustive instruction wins. |
| FR-A10 | MUST | `aid-reviewer`'s agent body is rewritten, not merely retained. Required: delete the "or established best practice" clause; delete the local severity table in favour of a pointer to the canonical scale; invert "severity is your judgment" to severity-is-a-lookup; delete the `cat >` File Writing section; restate the output contract for three row kinds; drop reviewer-side Status reconciliation; add Type 1/Type 2 findings, the rule-citation requirement, evidence admissibility, and per-unit coverage checkpointing. Fix the stray "The" in its opening line, the dangling `content-isolation.md` citation, and the `## Tasks Status` write target (renamed to `## Tasks State`, which is DERIVED and must not be written at all). Its `README.md` and `description` frontmatter carry the same errors and are corrected with it. |

*Open: naming against the existing on-demand `/aid-review` + `/aid-audit`; whether both agents are new or one reuses `aid-reviewer`; how the 5-section brief is passed through a skill invocation; who owns the FIX loop and how the executor to dispatch is parameterised. See STATE.md Q1.*

### B. Objective criteria

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-B1 | MUST | One canonical severity scale exists. All other definitions are deleted and replaced by pointers to it. |
| FR-B2 | MUST | Review criteria come **only** from the two sources of truth: the Knowledge Base, and the work's own spec documents (REQUIREMENTS / SPEC / BLUEPRINT / DETAIL). |
| FR-B3 | MUST | "Established best practice" is removed as a criterion source, along with undefined quality terms in shipped checklists. |
| FR-B4 | MUST | A per-artifact-class rubric catalog exists. Each rule row carries: the check, an evidence anchor, a severity anchor, and a named tag. |
| FR-B5a | MUST | FRs and ACs carry **explicit modality** (MUST / SHOULD / COULD), and modality is a primary severity input. Enforcement is authored-in-template plus a new `lint-modality.sh`, **not** reviewer-checked -- a missing modality prevents severity lookup entirely, which makes it a precondition gap (feature-004's Type 2), not a finding. Applies **retroactively** to existing documents. |
| FR-B5b | MUST | Severity is **looked up from the matched rubric rule**, not judged by the reviewer. |
| FR-B6 | MUST | A finding with no evidence is inadmissible. Reviewer confidence never modifies severity. |
| ~~FR-B7~~ | ~~SHOULD~~ | ~~Damage axes -- reach, reversibility, silence -- act as severity modifiers.~~ **CUT 2026-07-27.** It double-counts: *reach* is blast radius and *reversibility* is reversibility, both already axes **inside** the canonical scale, so the same fact would move severity twice. A reviewer-applied modifier also reopens the judgment surface FR-B5b closes. The third axis, *silence*, is real but is a property of the **rule** (knowable when the rule is authored), not of the reviewer's read -- it moves to feature-002 as a rule-authoring input to FR-B4: a rule whose violation fails silently is anchored one band higher. |
| ~~FR-B8~~ | ~~COULD~~ | ~~`grade.sh` validates each row's severity against its rule's declared severity.~~ **CUT 2026-07-27.** Poorly targeted: feature-002 gave severity anchors two forms, and this lint can only check **`Fixed`** ones — roughly half the catalog. Mis-assignment on a `Fixed` anchor is a transcription slip (low probability, the token is in the rule row); the real risk sits on **`Step 2`** anchors, where the reviewer must judge whether the blast radius escaped — and there this lint cannot help at all. It also brushes against NFR-1 by adding validation to `grade.sh`. And at an A+ floor any non-MINOR finding fails the gate regardless of band, so this protects the *metric*, not the *gate*. **Successor idea, not scheduled:** check that a finding claiming *escaped* actually **named a dependent** — that targets the high-probability case. |
| FR-B9 | MUST | AID's own content-isolation checks move **out of** the `aid-reviewer` agent body and **into** an AID-specific entry in the rubric catalog. They currently render into every adopter project, so a team reviewing their own application receives instructions about `.codex/aid/` nesting and copilot-cli `.github` scoping. This is dogfood leaking into the shipped product. |
| FR-B11 | MUST | The catalog declares the **five review kinds** AID already implements, and every registered class declares which kind it takes: **A** adversarial content grade, **B** build-verify only (re-run the generator; content grading skipped), **C** spot-check snapshot (current-value fields only; history not graded), **D** mechanical gate (script passes/fails, no agent), **E** machine score plus a mandatory human checklist. Only kind **A** needs rule rows; B, C, D and E need a validator and a declared authority. A class also declares its **intent** and **manner** authorities (the two-ladder model), which is what lets one reviewer serve every artifact type. |
| FR-B10 | MUST | The ledger gains a **`Rule`** column, giving the shape `# \| Severity \| Status \| Rule \| Doc \| Line \| Description \| Evidence`. It is inserted **after Status** because `grade.sh` parses by column position and requires Severity at `cols[3]` and Status at `cols[4]`; anything earlier breaks the grader. The column carries a rule ID namespaced by artifact class (e.g. `CODE-12`, `KB-07`), which **subsumes the existing source tags** — the source becomes derivable from the rule and the two can no longer contradict. Every "7-column" assertion in the tree moves to eight: the ledger schema, the reviewer agent body and README, the six per-skill reviewer briefs, `reviewer-dispatch.md`, and the AID-managed regions of the root `CLAUDE.md` / `AGENTS.md`. |

### C. Criteria-gap interrupt

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-C1 | MUST | Two finding types are distinguished: **Type 1** (about the artifact, gradeable) and **Type 2** (a gap in the review's own preconditions, not gradeable). |
| FR-C2 | MUST | No grade is computed while any Type 2 finding is open. |
| FR-C3 | MUST | On detecting a gap the reviewer proposes options and the calling skill discusses with the user. Once defined, the review **halts** and prints the exact command to resolve it. It does not attempt to invoke a long, human-gated update skill and resume in place. |
| FR-C4 | MUST | Routing follows the user's one-time-vs-canon answer: **canon** -> KB -> `/aid-update-kb`; **one-time** -> the work's own documents -> `/aid-define`, `/aid-specify`, `/aid-plan`, or `/aid-detail`. |
| FR-C5 | MUST | A "no" answer is followed by two questions: *what to do instead*, and *one-time or canon*. The result is recorded durably and never re-asked. |
| FR-C6 | MUST | The reviewer never writes the fix. Another agent performs the update. |
| FR-C7 | MUST | Gap-resolution reviews run in a restricted mode with a depth limit, so a gap raised while resolving a gap cannot recurse without bound. |
| FR-C8 | MUST | Gaps are batched -- detect all, ask once -- never one interruption per gap. |
| FR-C9 | MUST | `aid-light-review` is the up-front precondition scan that produces the batch. Resolving gaps **before** the graded pass is the primary path, so the common case needs no mid-review interruption at all. |
| FR-C10 | MUST | Missing **criteria** halts and asks, universally -- including `aid-discover`. There is no relax-and-continue exception. |
| FR-C11 | MUST | Missing **evidence** is a different axis and does not halt. Greenfield evidence-substitution is retained, because a greenfield project cannot produce as-built evidence for a design it has not built yet. |

**Resolved sequencing (replaces the call-and-return problem).** The primary flow is
`aid-light-review` -> gaps batched -> HALT with the resolution commands -> user resolves
-> `aid-deep-review` -> grade. This uses only forward chaining and halts. The coverage
manifest in the ledger survives the halt (the ledger is deleted only at DONE), so
re-invoking resumes rather than restarting. When deep review finds a gap anyway
(FR-A5), it halts and re-invokes -- already the house idiom for "another skill must
run", per the work-initiation gate and the delivery gate's non-CODE path.

### D. Resume and loop detection

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-D1 | MUST | The ledger carries a **coverage manifest** (`U-NNN` rows) and **gap/interrupt events** (`G-NNN` rows) alongside findings, in the same table — **8 columns** after FR-B10 lands. |
| FR-D2 | MUST | Coverage and gap rows carry `--` in the Severity column, so the grader ignores them. Verified: `grade.sh` counts a row only when Severity is exactly a bracketed enum value **and** Status is exactly `Pending` or `Recurred`. |
| FR-D3 | MUST | The reviewer checkpoints **after every unit**, via a surgical row-update helper. Full-file rewrites are retired. |
| FR-D4 | MUST | Two modes are distinguished. **Resume** (same review, interrupted) may see its own prior progress and findings. **New cycle** (after FIX) is a fresh clean-context pass with no prior findings. |
| FR-D5 | MUST | The **orchestrator**, not the cycle-N reviewer, reconciles new findings against the existing ledger and updates Status. |
| FR-D6 | MUST | On resume: a changed artifact invalidates its unit; changed criteria invalidate every unit the changed rule touches. |
| FR-D7 | MUST | All three interruption types are handled: halt-to-ask, user stop, and involuntary (crash / timeout / context exhaustion). `In Progress` units are treated as unexamined on resume. |
| FR-D8 | SHOULD | A repeated gap ID auto-halts with a possible-loop flag, rather than relying on the user to notice. |
| FR-D9 | **MUST** | `G-NNN` rows are promoted to `STATE.md` before the ledger is deleted, so loop detection survives across invocations. **Promoted from SHOULD to MUST on 2026-07-27:** three of feature-004's acceptance criteria (AC-5, AC-10, and its depth limit) rest on this promotion, so leaving it a SHOULD would close that feature with unsatisfied MUSTs — the MUST-depending-on-SHOULD defect recorded in STATE.md Q7 #7. Owned by feature-004, not feature-005. |

### E. Defect cleanup

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-E1 | SHOULD | The review-path defects catalogued in STATE.md Q3 are fixed once the target process is settled. |

### F. Review coverage gaps

*Five artifacts that a review should cover and does not. Found by the artifact inventory in STATE.md Q12.*

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-F1 | MUST | **`.aid/settings.yml` gains a kind-D mechanical gate.** It carries `minimum_grade`, `discovery.doc_set`, and `term_exclusions`, and nothing reviews it — so a wrong value silently loosens every gate in the project. The highest-leverage unreviewed artifact in the system, in a system whose whole premise is gated quality. |
| FR-F2 | MUST | **`kb.html` gains a kind-A adversarial content pass**, in addition to its existing machine validators and human checklist. It is currently the only major deliverable never seen by a reviewer: the machine suite can prove the HTML is well-formed and accessible, but cannot tell you the content is wrong. |
| FR-F3 | MUST | **`lint-frontmatter.sh` is wired as a runtime gate.** It exists, is documented as *the* mechanical frontmatter check, and is invoked by no skill state — only by tests and the dashboard. Frontmatter is currently agent-checked in the M2 mandate, paying agent prices for a mechanical check. |
| FR-F4 | SHOULD | **`BLUEPRINT.md` gets its own review.** Today it is read for gate criteria at DELIVERY-GATE but never independently graded — a definition artifact that escaped the definition-phase reviews. |
| FR-F5 | SHOULD | **`aid-specify`'s per-section review gains a ledger path and a `grade.sh` call**, matching the discipline of its own final REVIEW state. Two different review disciplines inside one skill is a drift source. |
| FR-F6 | MUST | **One grading backend.** `grade.sh` becomes the only producer of a letter grade in AID. Three exist today: the universal ledger (`grade.sh` + `grading-rubric.md`), the KB panel's binary verdict gates layered on top of it, and `grade-summary.sh`'s **weighted-points** model for `kb.html` (68 machine + 30 human → percentage → letter). The points model is retired: summarize's validators emit **ledger rows with rule-anchored severities** instead, and `grade.sh` grades them like everything else. Binary verdicts (essence PASS-iff-zero, act-back PASS-iff-zero, the V1 visual gate) are expressed as **rule anchors** — `[CRITICAL]` where the grade must fail — or, where the artifact genuinely produces nothing usable, via the existing `grade.sh --non-functional` flag. No second arithmetic, no override channel. **NFR-1 is unaffected:** `grade.sh`'s counting logic does not change; only the set of callers feeding it does. |

### Group G -- Citation and quote accuracy

*Added 2026-07-27, after the Specify phase, on evidence from this work's own review record.
See STATE.md Q14.*

| ID | Modality | Requirement |
|----|----------|-------------|
| FR-G1 | MUST | **A citation validator covers work artifacts, not just the KB.** `kb-citation-lint.sh` already enforces the durable-anchor standard — but only under `.aid/knowledge`. Work artifacts (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md`, task `DETAIL.md`) are unchecked, and they are where the citations actually are. |
| FR-G2 | MUST | **A cited line number must be in range.** If an artifact cites `file:NNN` or "`file` lines NNN–MMM", the file must exist and be at least NNN lines long. This catches the whole class where a citation points past the end of a file, or at the wrong file of two sharing a basename. |
| FR-G3 | MUST | **A quoted string attributed to a file must appear in that file.** Not necessarily at the cited line — line-position matching would be drift-brittle and is not the defect being targeted. Presence alone catches paraphrase-presented-as-quote, which the review record shows is the single most common review finding. |
| FR-G4 | SHOULD | **A count claim must carry its producing command.** A bare number asserted about the tree ("18 files", "16 cases") is unverifiable at read time and drifts silently. Where an artifact states a count, it states the command beside it. Advisory, not blocking — this one is a convention a lint can only partially reach. |
| FR-G5 | SHOULD | **Line-number citations remain permitted where they carry real precision**, notably a spec's affected-artifact inventory, where region ownership across features depends on exact ranges. FR-G1's durable-anchor requirement therefore applies to *evidence* citations, not to *ownership* claims. A blanket ban would have removed the mechanism that kept this work's seven features from colliding. |

## 6. Non-Functional Requirements

| ID | Modality | Requirement |
|----|----------|-------------|
| NFR-1 | MUST | No change to `grade.sh`'s counting logic. Verified compatible as designed. |
| NFR-2 | MUST | Works identically across all five profiles (claude-code, cursor, codex, copilot-cli, antigravity). |
| NFR-3 | MUST | Light review is genuinely cheaper than deep review -- measured in tier, effort, and dispatch count, not just intent. **Sharpened 2026-07-27:** as originally written this compares the two passes to each other, which is trivially true and is not the question the work was started to answer. The claim that matters is the **pipeline** claim — that light + deep costs less than deep alone — and it is now carried by **AC-13**. |
| NFR-4 | SHOULD | Adding a triage pass must not increase total cost on small artifacts. Gate it behind a size or complexity threshold. **Note:** a threshold satisfies this by *avoidance*, not by measurement, and it covers only small inputs. AC-13 covers the normal case. |
| NFR-5 | SHOULD | Existing ledgers remain readable; the row-kind extension is additive. |
| NFR-6 | MUST | Every review remains reproducible: the same artifact + same rules + same ledger state yields the same grade. |
| NFR-7 | MUST | Exactly one component produces a letter grade. Any check that can fail a phase does so by contributing a severity-anchored finding to a ledger, never by computing a grade of its own. |

## 7. Constraints

These are existing invariants the design must respect, not preferences:

- **The state-advance contract is closed.** Four advance types (CHAIN / PAUSE-FOR-USER-ACTION / PAUSE-FOR-USER-DECISION / HALT), and the spec says "Do not invent a third pattern." This governs **state transitions within a skill**, and CHAIN is forward-only.
- **Skill-to-skill delegation is narrower than it looks.** Invoke-and-use-the-result does have precedent, but only for short, read-only, non-interactive delegations (`aid-query-kb` -> `/aid-read-ticket`; `aid-review` -> `/aid-update-ticket`). There is **no** precedent for delegating to a long, human-gated skill with its own review cycle and approval gate, and doing so would nest two human gates. Hence FR-C3's halt-and-route.
- **Reviewer never writes, and never fixes.** Separation of reviewer from executor is load-bearing.
- **Reviewer tier >= executor tier.** Currently stated unconditionally; may need a carve-out for non-grading passes.
- **The ledger is deleted at skill DONE**, and `.aid/.temp/` is gitignored.
- ~~**Nine agents, three tiers**~~ -- **no longer a constraint.** This is a meta-work on AID itself, so the roster is in scope. It grows to **ten** (`aid-screener` added). The consequent KB revisions -- `architecture.md`'s roster and tier table, `agent-dispatch-tiering.md`'s per-agent defaults, a `decisions.md` entry, and the rendered `kb.html` -- are deliverables of this work, not costs to avoid.
- **Sub-agents cannot hold a multi-turn user conversation.** The calling skill must own any dialogue.
- **The profile renderer rewrites tool-root paths.** New references must survive the render.

## 8. Assumptions & Dependencies

**Assumptions**

- Skill chaining is available on the target hosts. Confirmed for cursor and claude-code; **not yet verified** for codex, copilot-cli, antigravity.
- The recursive cost of gap-resolution (update skills running their own review cycles) is acceptable, per an explicit decision.
- The user is always available to answer a blocking gap question. Reviews halt rather than proceeding on assumption.

**Dependencies**

- `grade.sh` -- unchanged, but its parsing behavior is depended upon.
- `writeback-state.sh` -- the precedent pattern for the new surgical ledger helper.
- `/aid-update-kb`, `/aid-define`, `/aid-specify`, `/aid-plan`, `/aid-detail` -- gap-resolution targets.
- The subagent heartbeat and `STOP_FILE` protocols -- reused for interruption handling.

## 9. Acceptance Criteria

| # | Criterion |
|---|-----------|
| AC-1 | Exactly one severity definition exists in the canonical tree. A grep for competing severity tables returns only pointers. |
| AC-2 | The string "established best practice" no longer appears as a criterion source, and no shipped checklist contains an undefined quality term. |
| AC-3 | Every finding produced by a deep review cites a rule from the rubric catalog. A finding with no rule reference is rejected. |
| AC-4 | Reviewing an artifact whose standard is undefined produces a Type 2 gap and halts before grading -- it never produces an invented finding. |
| AC-5 | Answering a gap with "no" records the decision durably; a re-run of the same review does not re-ask. |
| AC-6 | A review interrupted at any point resumes without re-examining Examined units and without skipping Unexamined ones. |
| AC-7 | A review killed mid-unit (involuntary) resumes correctly, re-examining only the interrupted unit. |
| AC-8 | Changing a criterion invalidates and re-reviews exactly the affected units -- verifiable on a fixture. |
| AC-9 | Adding coverage and gap rows to a ledger does not change the grade `grade.sh` computes for the same findings. |
| AC-10 | The same gap raised twice halts with a loop flag without user intervention. |
| AC-11 | A pipeline skill that previously carried its own review logic invokes the shared capability instead, and is measurably shorter. |
| AC-12 | The full render produces identical review behavior on all five profiles. |
| AC-13 | **The split is measurably cheaper on a normal artifact, not just on paper.** For a fixture artifact taken through one full gate passage, measure total dispatch count and FIX-cycle count. **Amended at delivery-001, 2026-07-28:** this criterion originally said the numbers come from *"the always-on `## Dispatch Log` / `## Calibration Log` telemetry"*. **They do not — that telemetry is not written.** Verified: across 49 sub-agent dispatches in this work's own pipeline, every one of those sections holds a header row and zero data rows, despite the templates describing them as "always-on, never optional". So **populating the Dispatch Log is a prerequisite of this criterion, not an input to it**, and the **per-dispatch tier is dropped from the measure** — it was never recorded and the weighting was never defined. Dispatch count and FIX cycles are counted identically before and after, so that comparison is valid and it catches the failure mode that matters: a split that adds dispatches without removing cycles. Pre-migration baseline and the nominated fixture (feature-005's Specify gate: 3 dispatches, 1 FIX cycle) are recorded in `deliveries/delivery-001/BASELINE-ac13.md`. Post-migration, the tier-weighted dispatch cost and the FIX-cycle count must both be **no greater** than the pre-migration baseline on the same artifact. The baseline is captured in feature-006's delivery D0, alongside AC-11's B and C metrics, and before any edit. **This is the acceptance criterion NFR-3 lacked** — a MUST about cost with nothing testing it. Without AC-13 the work can pass every other gate and still be a net cost increase, which would defeat the reason it was started. |
| AC-14 | **A citation in a work artifact resolves.** Every `file:NNN` or "`file` lines NNN–MMM" reference points at an existing file with at least NNN lines, and every string presented as a quotation from a named file appears in that file. Verified by a lint over `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md` and task `DETAIL.md`, on fixtures that fail in both directions. |

## 10. Priority

| Order | Group | Rationale |
|-------|-------|-----------|
| 1 | **B -- Objective criteria** | Everything else measures against these rules. Severity collapse is also the single highest-value, lowest-risk change, and it corrects a live correctness bug in the gate. |
| 2 | **C -- Criteria-gap interrupt** | Needs B's catalog to know what "missing" means. Unblocks greenfield adopters. |
| 3 | **D -- Resume and loop detection** | Independent of B and C in principle, but C's halt-and-restart flow depends on it working. |
| 4 | **A -- Review extraction** | Highest structural value, but cheapest to do *after* B/C/D settle what the shared capability must contain. Building the shared skill first would mean rebuilding it three times. |
| 5 | **E -- Defect cleanup** | Explicitly deferred by decision until the target process is settled. |
| 6 | **F -- Review coverage gaps** | Sequenced **last**, after A. Its new gates must be built on the shared review capability that group A delivers, and against the rule sets group B delivers. Building them earlier would add dispatch sites that group A then has to migrate — the same rework trap §10 exists to avoid. |

> **Note on ordering.** A is the requirement that started this work, and it is
> sequenced last on purpose. The discussion established that the light/deep split is
> a *container* for B, C, and D -- so its contents must be known before it is built.
>
> **Exception (decided during decomposition):** the ledger *substrate* -- row kinds,
> `--` severity, the surgical write helper (FR-D1..D3) -- moves **ahead of group C**.
> A Type 2 gap needs a `G-NNN` row to live in, batching needs somewhere to accumulate,
> and FR-C9's primary path rests on the manifest surviving the halt. Group D's
> *semantics* (FR-D4..D9) stay after C as originally intended, so the stated rationale
> is preserved -- only the substrate moves.

> **Cut candidates.** **FR-B7 is CUT** (2026-07-27) -- see its struck row in §5.B for the
> reasoning; feature-001 drops to five FRs and nothing else changes, because reach and
> reversibility were folded *into* the scale rather than bolted beside it.
> **FR-B8 is CUT** (2026-07-27) — see its struck row in §5.B. feature-003 drops to three FRs.
> **FR-A7** (still open) is an aspiration with no test; it affects feature-006 only.
