# Review Skills

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.A (FR-A1..A10), §5.C (FR-C9), §5.E (FR-E1), §9 (AC-11, AC-12) | /aid-define |

## Source

- REQUIREMENTS.md §5 group A — FR-A1 through FR-A10
- REQUIREMENTS.md §5 group C — FR-C9
- REQUIREMENTS.md §5 group E — FR-E1
- REQUIREMENTS.md §9 — AC-11, AC-12
- REQUIREMENTS.md §2 — problem 5 (review logic is duplicated)

## Description

Review logic is copy-pasted across the pipeline. Six near-identical dispatch blocks, six
near-identical brief templates, and the review-grade-fix loop reimplemented in at least four
places. Every skill that reviews carries its own copy, and they have drifted.

This feature extracts review into two skills over two agents.

`aid-light-review` screens. It runs cheap, computes no grade, makes one pass, and reports
findings above a configurable floor plus any missing criteria. `aid-deep-review` gates. It
sweeps every severity, writes the ledger, computes the grade, and drives the fix loop.

They are separate skills rather than one skill with a depth flag because the guarantee matters
more than the tidiness: a light pass must never be mistaken for clearing a gate, and with two
skills that is structural — the light skill contains no grading state at all and *cannot*
produce a grade. With one skill and a parameter, the guarantee rests on the parameter.

They are separate agents for a sharper reason. `aid-reviewer`'s body mandates exhaustiveness —
"enumerate the class, not the instance", "find nothing more to find before handing off". A
cheap bounded pass cannot be obtained from that prompt; the exhaustive instruction wins. A
screener needs a different instruction set, not a subset of this one. So `aid-screener` is new
(small tier, read-only — no shell access), and `aid-reviewer` is retained as the deep reviewer
so all six existing dispatch sites keep working. The roster grows from nine to ten, which this
meta-work is entitled to change.

The shared boilerplate splits accordingly: an operational block every agent keeps, and a
discipline block only deep reviewers inherit.

`aid-reviewer`'s body is rewritten rather than merely kept — including three defects found
during analysis: it cites a Knowledge Base document that does not exist, and it instructs
writing to a `STATE.md` section that was renamed and is derived read-only.

Finally, the callers migrate, and the light pass becomes the up-front precondition scan that
makes the whole gap-resolution sequence work without mid-review interruption.

## User Stories

- As an **AID maintainer**, I want review logic in one place so that fixing it once fixes it everywhere, instead of drifting across six copies.
- As an **AID maintainer**, I want a cheap screening pass whose prompt is actually built for screening, so that "make it cheaper" is not fighting "be exhaustive".
- As an **adopter project**, I want a clean screening result never mistaken for a passed gate.
- As a **pipeline agent**, I want to invoke a shared review capability rather than carry my own dispatch block and brief template.
- As an **AID maintainer**, I want the screening agent to be read-only, so that a cheap pre-check cannot execute anything.
- As an **AID maintainer**, I want gaps resolved before the graded pass begins, so that the common case never needs a mid-review halt.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-11** — Given a pipeline skill that previously carried its own review logic, when it is migrated, then it invokes the shared capability and is measurably shorter.
- [ ] **AC-12** — Given a full render, when review behaviour is compared across all five profiles, then it is identical.
- [ ] Given `aid-light-review`, when it completes, then no grade was computed and no ledger status lifecycle was driven.
- [ ] Given `aid-light-review` returning clean, when the deep pass runs, then it is neither shortened, replaced, nor pre-cleared.
- [ ] Given `aid-deep-review`, when it runs, then it sweeps all severities, writes the ledger, computes the grade via the grading script, and drives the fix loop with its circuit breaker.
- [ ] Given `aid-screener`, when its tool grants are inspected, then it holds `Read`, `Glob`, `Grep` and no shell access.
- [ ] Given `aid-screener`, when its rendered body is read, then it does not inherit the exhaustiveness discipline block.
- [ ] Given `agent-boilerplate.md`, when it is split, then all ten agents render correctly across all five profiles.
- [ ] Given `aid-deep-review` with no prior screening pass, when it runs, then it performs its own gap detection.
- [ ] Given the rewritten `aid-reviewer` body, when it is read, then the stray opening word is gone, the `content-isolation.md` citation is gone, and the write target is corrected to a section that is permitted to be written.
- [ ] Given the KB, when the agent roster is read, then it lists ten agents and the tier table includes `aid-screener` at small tier.
- [ ] Given a calling skill, when review begins, then it chains forward into the review skill rather than expecting control to return.
- [ ] Given the review-path defects catalogued in STATE.md Q3, when this feature closes, then each is either fixed or explicitly retired as no longer applicable.

## Notes for Specify

- **FR-A10 is owned solely by this feature.** Four other features edit `canonical/agents/aid-reviewer/AGENT.md` in non-overlapping regions (features 1, 2, 3, 5). This feature owns the residual edits, the structural rewrite for the two-agent world, and a final conformance check that the body matches the target state. Its spec must carry an explicit **verify, do not redo** list covering what upstream features already delivered.
- **The boilerplate split is the highest-blast-radius item in the work** (STATE.md concern N1). All nine agents include `agent-boilerplate.md`, and `reviewer-dispatch.md` references it. Splitting it re-renders every agent across all five profiles — a full-roster regression inside a feature whose other work is review-specific. Consider shipping FR-A9 as its own delivery with its own render check.
- **Uncommitted divergence:** `canonical/agents/aid-reviewer/AGENT.md` currently differs between the main tree (123 lines, modified) and this work's worktree (108 lines). Reconcile before implementation, or the rewrite will be authored against a stale base.
- **AC-11 has no metric and no baseline** (STATE.md Q7 #9). Define the measure — lines, tokens, or reference-file count — and capture the pre-migration numbers as this feature's first act, or the criterion is unverifiable afterwards.
- **Spike needed before specifying** (STATE.md Q7 #4): skill chaining is confirmed on cursor and claude-code but unverified on codex, copilot-cli and antigravity. NFR-2 and AC-12 require parity on all five. If chaining is missing anywhere, FR-A1 and FR-A8's mechanism needs a fallback design.
- **Naming still open** (STATE.md Q1): `aid-light-review` and `aid-deep-review` land beside the existing on-demand `/aid-review` and `/aid-audit`. Four review-ish commands invites the wrong guess. Also open: how the five-section brief is passed through a skill invocation, and who owns the fix loop including how the executor to dispatch is parameterised.
- **FR-E1 note:** Q3 item (e) — the WSL `worktree-lifecycle.sh` gitdir bug — is not a review-path defect and should be re-triaged out of this work rather than carried as review scope (STATE.md concern N4).
- **FR-A7 is an undecided cut candidate.** If cut, this feature drops to eleven FRs; nothing else here depends on it.
- **Size:** twelve FRs. The skills-plus-agents versus caller-migration seam is legal but shipping the first half alone would deliver a capability no skill calls. Manage the bulk at Plan time by decomposing into several deliveries.

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. The three core sections survive in adapted form
> (`Data Model` → §2's contracts, `Feature Flow` → §2's state machines, `Layers & Components` →
> §§3–4's agent/include topology). All 19 conditional sections are dropped: no store, request
> flow, DI container, API surface, UI, network boundary, cache, telemetry sink, or hardware
> target. Unlike feature-005 this spec does **not** keep `State Machines` separately — §2 *is*
> the state machines.

### 1. Base reconciliation, and three findings that reshape the feature

**(i) The boilerplate split can be made byte-identical.** The renderer's `_resolve_includes`
substitutes each `{{include:<name>}}` token with the template's content **after passing it
through `rewrite_install_paths(content, install_root)`** — `render.py:268`, the final statement of
`_replace_include` (defined at 264, inside `_resolve_includes` at 257) — it is not a raw byte
substitution. The byte-identity conclusion survives regardless, because that rewrite is
**distributive over the concatenation**: it operates on path tokens within lines, and no path
token straddles the line-32/34 boundary, so
`rewrite(A) + "\n" + rewrite(B) == rewrite(A + "\n" + B)`. Verified by direct test, not inferred:

```
fileA (lines 1–32, operational) + "\n" + fileB (lines 34–59, discipline) == agent-boilerplate.md
```

So if every existing agent carries the two tokens on consecutive lines, **all nine rendered
bodies are byte-unchanged**. STATE.md concern N1's "full-roster regression" collapses into a
zero-diff assertion. This is the single biggest de-risking available in this feature, and §9
oracle (a) is what makes it a check rather than a hope.

**(ii) The stray "The" is not in the committed base.** `canonical/agents/aid-reviewer/AGENT.md`
is 123 lines and `M` in the main tree, 108 in the worktree. The divergence is an accidental
markdown-formatter run (blank lines after headings, table padding, bold markers moved) that
*introduced* `The You are the Reviewer`. It never reached `profiles/`, `.claude/`, `.cursor/`, or
this worktree. **Reconciliation is `git checkout --`, not an edit**, and FR-A10's "fix the stray
The" becomes a verify-absent item (V1 in §4).

**(iii) `reviewer-dispatch.md` does not reference `agent-boilerplate.md`.** This feature's own
Notes and STATE.md N1 both say it does. `grep -rn 'agent-boilerplate' canonical/ lib/ tools/`
returns only the nine `{{include:}}` sites. The blast radius is real; its stated cause is not.

**Everything downstream is authored against the committed base**, reconciled in delivery D0.

### 2. The two skills

Both are **curated** (non-catalog) skills. The shortcut catalog is untouched.

#### `aid-light-review` — screens

```
INTAKE ──(below threshold)──> DONE
  │
  └─> SCREEN ─> RECORD ─> GAPS ──(open criteria gap)──> PAUSE-FOR-USER-ACTION
                            │
                            └─(clean)─> REPORT ─> DONE (HALT)
```

| State | Work | Advance |
|---|---|---|
| `INTAKE` | Read the invocation manifest (§5). Resolve artifacts, rule set, severity floor, ledger scope. **NFR-4 gate:** below the configured artifact threshold, skip the screen and record `screen: skipped (below threshold)` | CHAIN → SCREEN, or CHAIN → DONE |
| `SCREEN` | **One** dispatch of `aid-screener` at small/low. Rows return in the message | CHAIN → RECORD |
| `RECORD` | **The skill** writes the returned rows via `writeback-ledger.sh`. The screener has no `Bash`; the skill does | CHAIN → GAPS |
| `GAPS` | Subtract resolved keys, ask **once** for the whole batch (FR-C8 — a skill can hold a dialogue, a sub-agent cannot), promote | PAUSE-FOR-USER-ACTION with the printed commands, or CHAIN → REPORT |
| `REPORT` | Print findings at or above the floor. **No `grade.sh`. No `check-gaps.sh`** — there is no grade to gate | CHAIN → DONE |
| `DONE` | HALT. It never chains into deep review | HALT |

**What it may see:** the artifact set, the rule set, the floor. Not a prior grade, not a prior
ledger, not the deep attempt's scratch.

**FR-A4 made structural, not instructional.** Light review writes findings into the canonical
ledger as ordinary `Pending` rows — FR-A4's "may only add findings", and feature-005 §3's
reconciliation handles them correctly. It writes **no `U-NNN` coverage rows at all.** Coverage is
a deep concept. Because the deep pass's attempt scratch is therefore empty at its start whether
or not light ran, `plan-resume.sh` reports every unit unexamined and the deep pass examines
everything. **A clean light pass cannot shorten, replace, or pre-clear the deep pass, because it
leaves behind nothing any deep state reads as coverage.** Had light written `U-` rows into the
same scope, a deep resume could silently skip a unit — the exact hazard FR-A4 exists to prevent,
and invisible unless FR-A4 is read alongside feature-005 §4.

Light findings still need a `Rule` (feature-002 AC-3, enforced by `--append-finding` exit 4), so
the screener cites rules and cannot invent criteria either.

#### `aid-deep-review` — gates

```
INTAKE ─> RESUME-PLAN ─> REVIEW ─> RECONCILE ─> GAP-GATE ──(exit 1)──> PAUSE-FOR-USER-ACTION
                           ▲                        │
                           │                     (exit 0)
                           │                        ▼
                           └── FIX <── ROUTE <── GRADE
                                │         │
                    (max_cycles)│         └─(grade ≥ min)─> DONE (HALT)
                                ▼
                          IMPEDIMENT + lifecycle: Blocked
```

| State | Work |
|---|---|
| `INTAKE` | Read the manifest. Resolve the minimum grade via `read-setting.sh`, the FIX executor spec (§5), the cycle counter |
| `RESUME-PLAN` | Feature-005 §2: one `test -f` selects `resume` vs `new-cycle`; `plan-resume.sh`; apply with `--set-status` |
| `REVIEW` | Dispatch `aid-reviewer` with the rendered brief — `{{RESUME_MODE}}`, `{{GAP_DEPTH}}`, `GAP POLICY`, per-unit checkpointing |
| `RECONCILE` | Feature-005 §3: the orchestrator joins scratch → canonical on `(Doc, Rule)`. The reviewer never reconciles |
| `GAP-GATE` | `check-gaps.sh`. **This is FR-A5** — deep does its own gap detection unconditionally, whether or not light ran |
| `GRADE` | `grade.sh --explain`, reachable only on `check-gaps.sh` exit 0 (feature-004 §2) |
| `ROUTE` | ≥ min → DONE. < min → FIX |
| `FIX` | Dispatch the parameterised executor (§5). Circuit breaker at `max_cycles` → IMPEDIMENT + `lifecycle: Blocked`. Increment cycle; CHAIN → REVIEW as a new cycle |
| `DONE` | Delete the attempt scratch, write the caller's terminal state field, HALT |

**How a caller invokes either:** one line, one argument, a manifest path.

```
CHAIN → /aid-deep-review .aid/.temp/review-request/specify-feature-006.yml
```

### 3. The two agents, and the boilerplate split

#### `aid-screener` (new)

```yaml
---
name: aid-screener
description: Pipeline-internal — invoked by a phase skill, not by a user. Bounded
  first-pass screener. Makes ONE cheap pass over a named artifact set against a named
  rule set and returns findings at or above a severity floor, plus any missing criteria.
  Computes NO grade, writes NO file, drives no status lifecycle. Returns ledger-shaped
  rows in its message; the calling skill writes them.
tier: small
tools: Read, Glob, Grep
---
```

No `Bash`, no `Write`, no `Edit`. Includes `{{include:agent-boilerplate}}` **only**.

Its body is a **counter-instruction set, not a subset** of `aid-reviewer`'s:

- One pass. Do not re-read a file you have already read.
- **Report the first instance of a class, not every instance.** Naming the class once is the
  deliverable — the deliberate inverse of *"enumerate the class, not the instance"*.
- Stop at the floor. Findings below it are not yours to report.
- **A clean screen is not an all-clear.** It means "nothing above the floor in one pass". It
  never clears a gate.
- You compute no grade, run no script, and write no file. Return rows; the caller writes them.

#### `aid-reviewer` (retained)

`tier: medium`, `tools: Read, Glob, Grep, Bash` — unchanged. Gains the second include token; its
body changes come from FR-A10 (§4), not FR-A9.

#### The split (FR-A9)

**`agent-boilerplate.md` keeps its name.** Renaming would edit nine agent files for no benefit
and invalidate `.aid/knowledge/coding-standards.md:241`, which cites it for the heartbeat idiom
that stays.

| File | Content | Included by |
|---|---|---|
| `agent-boilerplate.md` | Lines **1–32**: `## Heartbeat protocol`, including the `STOP_FILE` stop-poll paragraph at 24–32 | all **10** agents |
| `agent-discipline-boilerplate.md` (new) | Lines **34–59**: `## Self-review discipline`, its five rules, and the `self-review-protocol.md` pointer | **9** agents — all but `aid-screener` |

Each of the nine existing agents gets both tokens on consecutive lines and renders
byte-identically, per §1(i).

**Why `aid-screener` must not inherit it.** Rules 2 and 5 are the operative ones — *"Grep for
every shape of the change; address every instance"* and *"A task is done when an honest
adversarial sweep surfaces nothing new"*. Both are unbounded-work mandates. STATE.md Q1's
deciding reason is that when an unbounded instruction and a bounded budget share a prompt, the
unbounded one wins — so a cheap screen is **not** obtainable by lowering the tier of an agent
that carries them. Excluding the block is what makes the screener's tier and effort defaults
actually bind.

**This also resolves STATE.md Q7 #3, which is still listed as blocking.** The reviewer ≥ executor
invariant binds *the agent that produces the graded ledger*. `aid-screener` structurally is not
that agent: no `Bash`, so it cannot run `grade.sh`; no write path, so it cannot produce a ledger.
The carve-out is therefore a statement about which agent the invariant applies to, not a weakening
of it anywhere it does apply.

**A live contradiction FR-A9's wording would deepen.** `self-review-protocol.md:7–10` states:
*"Reviewers (`aid-reviewer`) and pure coordinators (`aid-orchestrator`) are exempt — they don't
produce primary artifacts."* Yet the block ships to all nine, and `aid-reviewer/README.md:15`
celebrates that fact. FR-A9's parenthetical — *"deep-review agents only"* — read literally would
strip the block from the seven producers the protocol names and keep it only on the one agent the
protocol exempts. **Decided: the byte-neutral reading, nine of ten.** The AC only constrains
`aid-screener` and is satisfied either way. The protocol/boilerplate exemption mismatch is logged
as a **new Q3 item** rather than widening this feature into a nine-agent behavioural change.

`agent-dispatch-tiering.md` gains one row:

```
| aid-screener | small | `low` | — never escalates: an escalated screen is a deep review, which is a different agent |
```

### 4. `aid-reviewer`'s residual edits, and the verify-do-not-redo list

The union of 001–005's claims is `3, 17, 21, 31, 36, 39–57, 59–67, 69–74, 75, 76–79, 81–95,
96–99, 100–103, 106–107`, plus insertions after 79 and after that section, plus feature-005's
clause-level claim inside line 79. Lines **58, 68 and 80 are blank separators** nobody claims
(feature-004 §7).

#### Residual edits — what FR-A10 actually has left

| Line | Change |
|---|---|
| **8** | Rewritten for the two-agent world: name the deep/screen division, state that this agent is the graded one. Unclaimed by 001–005. Also where the "stray The" would have been — per §1(ii) it is not in the base |
| **20** | Rewritten. Two defects in one line: the section was renamed to `## Tasks State`, **and** it is `DERIVED` and must not be written at all. Replace with the sanctioned write, or delete the clause. Its twin at 103 disappears with feature-003's `## File Writing` deletion; 20 survives, so nothing is orphaned |
| **33–34** | Retained, re-anchored. Line 34's *"an internal contradiction is `[CRITICAL]`"* now contradicts feature-001's scale, where `[CRITICAL]` needs an escaped radius **and** non-local correction. Re-express as a catalog rule reference with a `Step 2` anchor. **A cross-feature contradiction none of 001–005 caught** |
| **18** | **Added 2026-07-27 at feature-007's request.** *"Tag every issue by severity: `[CRITICAL]`, `[HIGH]`, …"* — it instructs the reviewer to **assign** severity, which contradicts feature-001's line-36 replacement (severity-as-lookup) and feature-002's severity-as-a-property-of-the-rule. Feature-002 claims 17 (the *source*-tag bullet) but nobody claimed 18, leaving a live contradiction in the shipped body. Rewrite as: cite the rule; the rule supplies the severity |
| **37** | Retained, extended — depth is now a parameter too, and the depth choice is a *different agent*, not a flag |
| **105, 108** | Retained. Feature-004 explicitly left both alone |
| structural | New `## Depth and Division of Labour` section before feature-004's `## Finding Types`: this agent is the deep reviewer; a screening pass is `aid-screener`, a different agent; a screening result never substitutes for this pass. Claims no existing line |

`README.md`: **line 52** — the Large-tier claim contradicting canonical `tier: medium`. Both
feature-002 §9 and feature-005 §9 say *"52 is Q3(d) and stays"*, so it lands here by elimination
— and it is no longer a doc nit, because §3's tier carve-out is authored here. Also **line 15**,
which asserts the self-review block is *"present uniformly"* — false the moment `aid-screener`
exists, claimed as collateral on the same argument features 001 and 002 used for theirs.

#### The verify, do not redo list

Nine assertions, not edits. A failure means the upstream feature regressed and the finding belongs
to it.

| # | Assert | Delivered by |
|---|---|---|
| V1 | Line 8 has no leading `The`; `git diff` on this file in the **main tree** is empty | Nobody — §1's reconciliation. Never a defect in the committed base |
| V2 | No local severity table; a pointer to `grading-rubric.md#severity-scale` present | feature-001 (59–67) |
| V3 | `grep -c 'established best practice'` is 0; the two-sources rule and no-criterion-no-finding are present | feature-001 (31) |
| V4 | `Severity is your judgment` absent; severity stated as a lookup | feature-001 (36) |
| V5 | No `## Standing KB-Convention Checks`; no `content-isolation.md` citation anywhere | feature-002 (39–57, §8) |
| V6 | `description:` says eight columns, not seven, and mandates no source tags | feature-002 (3, 17) |
| V7 | No `## File Writing`; no `cat >`, no `LEDGEREOF`; `writeback-ledger.sh` named as the mechanism | feature-003 (81–95, 100–103) |
| V8 | `## Finding Types` exists with Type 1/Type 2 and the `[GAP:*]` tokens; the gap-record contract at 21 and the criteria-gap route at 106–107 | feature-004 |
| V9 | The Status-reconciliation clause of line 79 is gone; `## Cycles and Resume` exists with both modes and the paired checkpoint | feature-005 |

The conformance check asserts all nine plus the residual edits **against content anchors, not line
numbers** — following feature-005 §8's precedent, because 001–005 all edit this file first and
every number will have drifted.

### 5. Brief passing, and FIX-loop ownership

#### An invocation manifest, not a free-text brief

The problem is real and worsening. `reviewer-dispatch.md:20` says *"EXACTLY these 5 sections"*
(repeated at 179 and 213) and ships **six** — verified two ways: the fenced block at 23–55, and
`awk 'NR>=60 && NR<=175 && /^### /'`. Feature-004 adds `GAP POLICY` (seventh); feature-005 adds
`{{RESUME_MODE}}` and `{{GAP_DEPTH}}`. Skills take one free-form argument.

**The caller renders a manifest to `.aid/.temp/review-request/<scope>.yml` and passes its path.**
The review skill reads it and renders the reviewer brief itself, from one shared template.

```yaml
scope: specify-feature-006
caller: aid-specify
artifacts:                       # derived from disk, never memory
  - .aid/works/work-003-.../features/feature-006-review-skills/SPEC.md
rule_set: review-rubrics/spec.md
context: |
  SPEC.md for feature-006 in work-003. All sections marked Complete.
out_of_scope:
  - Other features in the same work
  - PLAN.md sequencing
ledger: .aid/.temp/review-pending/specify-feature-006.md
severity_floor: '[MEDIUM]'       # light only
minimum_grade_key: specify
reviewer_tier: large
gap_depth: 0
fix:
  executor: aid-architect
  tier: large
  fan_out: single
  scope_filter: 'SPEC-*'
  max_cycles: 3
```

Six grounded reasons: it is the only option under which the six brief files can actually shrink,
which is where most of AC-11's saving lives; `reviewer-dispatch.md:206–207` already requires *"the
rendered brief is logged with the dispatch record"* and nothing produces one today; `.aid/.temp/`
is the established gitignored transient location; `read-setting.sh` already parses flat YAML with
awk and no `yq`, so the reader needs no new dependency; a single-token argument eliminates the
free-text quoting problem; and `{{ARTIFACTS}}`-derived-from-disk becomes *enforceable* because the
field is written by a shell command rather than recalled by a model.

**Do not delete the six brief files. Shrink them in place**, at the same paths, to the two
genuinely per-skill sections — `RUBRIC` and `OUT OF SCOPE`, the two `reviewer-dispatch.md:185–192`
already marks *"Static per skill"*. `OOS POLICY`, `DELIVERABLES`, `GAP POLICY` and the mode slots
are static-global and move to one shared `canonical/aid/templates/reviewer-brief-template.md`.

Keeping the paths preserves feature-002 §9's `RUBRIC:` re-point target and — critically — keeps
feature-005 §12 oracle (b) non-vacuous: its `for f in $(ls canonical/skills/*/references/reviewer-brief.md …)`
loop would **pass trivially on an empty glob** if the files were deleted, silently ceasing to test
anything.

**Two hand-offs, in writing, because the Q7 #8 orphan already happened once:**

- **feature-004's `GAP POLICY` oracle must invert.** It asserts each of six briefs carries the
  section; after this feature the section lives once, in the shared template, and the six must
  **not** restate it. Carried as an AC here.
- **feature-005's `{{RESUME_MODE}}` oracle (b) must be re-pointed.** Its measured 12-file surface
  (6 briefs + 5 `reviewer-prompt*.md` + the protocol) becomes 7 (the shared template + 5 prompts +
  the protocol). Carried as an AC here.

#### FIX-loop ownership

**`aid-deep-review` owns the loop** — REVIEW → RECONCILE → GAP-GATE → GRADE → ROUTE → FIX →
REVIEW, with the circuit breaker. The caller's REVIEW state ends at the invocation and keeps no
loop of its own. That is what makes AC-11 achievable: the loop is the bulk of what callers
duplicate.

**The executor is not one parameter.** Read against the four live implementations it varies on
three axes:

| Caller | executor | tier | fan-out | non-matching findings |
|---|---|---|---|---|
| `aid-specify` / `aid-plan` / `aid-detail` / `aid-define` | `aid-architect` | large | single, or inline loop-back | — |
| `aid-execute` DELIVERY-GATE | the type that executed the tasks; `aid-developer` default | score-selected | single | non-CODE halts to the user |
| `aid-discover` / `aid-update-kb` | `aid-tech-writer`, or `aid-researcher` if depth is needed | medium | **N parallel, one per affected file** | — |
| `shortcut-engine` GATE | `aid-architect` | large | single | — |

Hence the five-field `fix:` block. **`fan_out: per-doc` is the field a single-parameter design
would have missed**, and omitting it would silently serialise `aid-discover`'s parallel FIX — a
performance regression disguised as a refactor.

**`aid-review` is a deliberate exception.** Its VERIFY state dispatches a *second* `aid-reviewer`
to review the first's findings, and its loop-back asks for a **revision**, not a fix. That is a
meta-review, not a fix loop. `aid-review` migrates its REVIEW state to `aid-deep-review` for the
target and keeps its own VERIFY loop.

### 6. Caller migration, AC-11's measure and baseline

#### Sites — three tiers

**Tier 1 — the eight dispatch owners, in scope.**

| Caller | Review state(s) | Becomes |
|---|---|---|
| `aid-define` | `state-cross-reference.md` | manifest + CHAIN → `/aid-deep-review` |
| `aid-specify` | `state-review.md` **only** | same. **Amended 2026-07-27 at feature-007's request:** `state-continue.md` step 4 is **excluded** from this migration. A terminal CHAIN cannot serve an in-loop per-section review — both review skills HALT at DONE, so handing off from inside the per-section loop would end the skill after the first section. Step 4 stays an inline dispatch and receives feature-007's FR-F5 mechanics instead (a `aid-screener` dispatch, the shared ledger, `check-gaps.sh` then `grade.sh`). Consequently **AC-11's per-caller strict-decrease excludes `state-continue.md`** — FR-F5 deliberately *adds* review-mechanics lines there — so aid-specify's fall must come entirely from `state-review.md`, and its C is re-measured after feature-007 lands |
| `aid-plan` | `review-deliverables.md`, `first-run-loop.md` | same |
| `aid-detail` | `review.md`, `first-run.md` | same |
| `aid-execute` | `state-review.md` Step 1.5, `state-delivery-gate.md` | Step 1.5 → `/aid-light-review`; the gate → `/aid-deep-review`. **The one caller using both**, and Step 1.5 is the closest thing to a light pass that exists today |
| `aid-discover` | `state-review.md` | `/aid-deep-review` with `fan_out: per-doc`, four mandates preserved |
| `aid-describe` | `state-describe-seed.md` step 5 | `/aid-deep-review`; resolves the missing-seventh-brief defect by needing no brief file |
| `shortcut-engine` (Lite) | GATE Step 4 | `/aid-deep-review`. **Must not be skipped** — feature-004 §2 already found that omitting it leaves every shortcut skill able to grade over an open gap |

`aid-update-kb` needs **no** separate migration: its REVIEW reuses `aid-discover`'s panel verbatim
with `{{SCOPE}} = update-kb`, so it inherits the migration.

**Tier 2 — `/aid-review` and `/aid-audit`.** Both keep their names, argument shapes, work-folder
allocation, PRESENT-FINDINGS gate, and publish router. Only the REVIEW state changes: it writes a
manifest and invokes `/aid-deep-review`. **`aid-audit` needs zero edits** — it carries no logic
and delegates entirely to `aid-review/SKILL.md`, which is exactly why the
alias-is-a-full-directory convention was chosen.

**Tier 3 — explicitly deferred, and named so the boundary is not accidental.** The hand-authored
`repurpose` skills with an inline clean-context VERIFY dispatch (`aid-create-document`,
`aid-change-document`, `aid-update-document`, `aid-add-document`, `aid-create-diagram`,
`aid-design`, `aid-report`, `aid-research`/`aid-investigate`/`aid-spike`,
`aid-prototype`/`aid-prototype-ui`, `aid-test` and its three siblings). FR-A6 scopes migration to
callers that carry *"their own dispatch logic **and** brief template"* — these carry a dispatch
but no brief template, and they are single-shot verifications with no ledger→grade→FIX loop.
**The authoritative Tier 3 set must be derived at implementation time**; regex sweeps disagreed
with each other (4 files by one pattern, 30 by another), which is why no count is quoted.

#### AC-11's measure and baseline

Two disjoint, mechanically derived numbers. **Both must fall.**

**B — the shared review-asset budget:**

```bash
wc -l canonical/aid/templates/reviewer-dispatch.md \
      canonical/skills/*/references/reviewer-brief.md \
      canonical/skills/aid-execute/references/reviewer-guide.md | tail -1
# measured: 876
```

**C — per-caller review-mechanics lines**, by a **fixed** pattern written into the spec so it
cannot be tuned after the fact:

```bash
PAT='aid-reviewer|reviewer-brief|reviewer-dispatch|reviewer-ledger-schema|grade\.sh|ARTIFACTS UNDER REVIEW|OUT OF SCOPE|OUT-OF-SCOPE|review-pending|Ledger lifecycle|minimum_grade|subagent_type|RUBRIC:|CONTEXT:|DELIVERABLES:'
grep -hcE "$PAT" <caller files> | awk '{t+=$1} END{print t}'
```

| Caller | C (measured) |
|---|---|
| `aid-define` | 11 |
| `aid-specify` | 11 |
| `aid-plan` | 19 |
| `aid-detail` | 19 |
| `aid-execute` | 21 |
| `aid-discover` | 70 |
| `aid-describe` | 6 |
| `shortcut-engine` | 41 |
| `aid-review` | 14 |
| **total** | **212** |

**Threshold.** (a) every migrated caller's C strictly decreases; (b) `B_after + lines(new shared
review assets) < B_before` — **the anti-gaming clause**, without which "shorter" is achieved by
moving lines into a new file; (c) aggregate C falls by ≥ 40%.

**Captured in delivery D0, before any edit**, written into this SPEC as above, and carried in the
test as **literals with the producing command in a comment** — following feature-003 §9's
measured-fixture precedent. Deliberately **not** read from the work folder at test time:
CLAUDE.md's work-folders-are-transient rule forbids a permanent artifact depending on work-folder
contents, and tests must build their own fixtures.

**C's honest limit.** It is a proxy: it counts lines mentioning review machinery, not "review
logic", and it under-counts prose. It was chosen over three worse alternatives — whole-file counts
over-state wildly (the eight Tier-1 callers total 4059 lines, most not review), token counts are
not reproducible, and a sentinel-delimited region cannot be measured at baseline without first
editing the baseline. C's virtue is that it is fixed, cheap, reproducible by anyone, and monotone
in the thing being removed.

#### The four names, disambiguated

| What you type | The question it answers | Grades? | Who types it |
|---|---|---|---|
| `/aid-review`, `/aid-audit` | "Review this thing for me, now." Any target; allocates a work folder; presents findings; offers to publish | informational only | **a human** |
| `/aid-deep-review` | "Is this artifact good enough to pass its gate?" | yes, gate-bearing | a phase skill |
| `/aid-light-review` | "Is anything obviously wrong, and do I have the rules I need?" | never | a phase skill |
| `aid-screener`, `aid-reviewer` | agents, not commands | | nobody — dispatched |

**The one-line user rule: `/aid-review` is the one you type; the other two are the ones the
pipeline types.** Three mechanisms enforce it rather than hoping documentation does. The two new
skills' `description:` opens with *"Pipeline-internal — invoked by a phase skill, not by a user."*
Their `argument-hint` is a `.aid/.temp/review-request/<scope>.yml` path, which no human would
type. And `aid-triage` — the existing suggest-only router — gains a routing row sending every
human review request to `/aid-review`.

### 7. Roster growth 9 → 10

**The blast radius is a live CI gate, not a documentation chore.**
`tests/canonical/test-doc-counts.sh` derives `AGENTS` and `SKILLS` from the canonical tree and
asserts that 13 user-facing surfaces state the current number:

```bash
bash tests/canonical/test-doc-counts.sh                                            # 31 passed, 0 failed today
awk '/^ASSERTIONS=\(/,/^\)/' tests/canonical/test-doc-counts.sh | grep -c AGENTS   # 10
awk '/^ASSERTIONS=\(/,/^\)/' tests/canonical/test-doc-counts.sh | grep -c SKILLS   # 11
awk '/^ASSERTIONS=\(/,/^\)/' tests/canonical/test-doc-counts.sh | grep -c '"'      # 29
ls -1d canonical/agents/*/ | wc -l                                                 # 9
ls -1d canonical/skills/*/ | wc -l                                                 # 111
```

Adding one agent breaks **10** assertions; adding two skills breaks **11** — **21 of 29** — across
`README.md`, `docs/repository-structure.md`, `docs/aid-methodology.md`, `docs/glossary.md`,
`docs/diagram-content-reference.md`, `docs/install.md`, and the five `profiles/*/README.md`. Plus,
outside that gate: `site/src/content/docs/concepts/methodology.md:104, 876`,
`site/src/content/docs/guides/maintainer.mdx:361`,
`.claude/skills/generate-profile/SKILL.md:118, **123**, 245` — **not 121**: line 121 is the shell
command `ls canonical/agents/ | wc -l`, which has no hardcoded count to bump, while line 123 is
the assertion `Expected: 9 directories.` An implementer following a list naming 121 would edit a
shell command to no effect and silently leave the assertion wrong. Plus two hardcoded
`toHaveLength(9)` literals in `site/scripts/__tests__/gen-reference.test.mjs` at lines **147 and
151**.
`docs/diagram-content-reference.md:28` additionally names the two diagrams to regenerate.

**This is good news:** the regression is *already* mechanically caught, so the spec need not
invent an oracle for it — it must only ship the doc updates in the same delivery. The two
`toHaveLength(9)` literals should be **derived from the directory listing** rather than bumped to
10, so they never drift again.

**Codex renders agents as TOML, not markdown** — `profiles/codex/.codex/agents/*.toml`, so
`render.py`'s TOML branch is live despite its "DORMANT" comment. The body goes raw into a
`"""…"""` literal. The split changes no characters, so the risk is nil, but the render check must
include a TOML parse of `aid-screener.toml`, whose body it produces for the first time.

### 8. Chaining, and the AC-12 parity model

**FR-A8's "chains forward" — a new *use* of CHAIN, not a new type.** There is **no** cross-skill
CHAIN in the tree today: every cross-skill transition is a PAUSE or a HALT, and
`state-machine-chaining.md:96` forbids inventing a fifth advance type. So one line is added under
CHAIN's `Use for:` list defining a **terminal hand-off** — *"the calling skill's state machine
ends and the invoked skill's begins; no control returns"*. Line 96 stays untouched, which is the
whole point of the phrasing (feature-004 §7 set this precedent). Existing precedent for
skill-invokes-skill: `aid-review → /aid-read-ticket` and `aid-review → /aid-update-ticket`.

**One fallback design, not five.** `skill_chaining = true` on all five profiles — verified in
every `profiles/*.toml` — and `grep -rn capabilities .claude/skills/generate-profile/scripts/render.py`
returns **nothing**: the renderer does not branch on capabilities at all. A per-profile render
branch would therefore *create* the AC-12 divergence it was meant to prevent. Instead the
hand-off line is written so it doubles as a `PAUSE-FOR-USER-ACTION` resume command: if a host
does not auto-execute the invocation, the degradation is "the user types the printed command", not
a broken flow. **The chaining spike becomes a confirmation task on three hosts, not a design
fork.**

### 9. Verification strategy

Ships as `tests/canonical/test-review-extraction.sh`. Every baseline measured today.

```bash
# (a) FR-A9 is byte-neutral for the nine existing agents. THE headline oracle.
/generate-profile                                  # re-render all seven trees
git diff --stat profiles/ .claude/ .cursor/         # expect: ONLY aid-screener additions
#   any other diff means the split changed a rendered body -> FR-A9 regressed

# (b) roster totality, glob-derived (no exclusion list to rot)
[ "$(ls -1d canonical/agents/*/ | wc -l)" -eq 10 ]
for d in profiles/*/*/agents .claude/agents .cursor/agents; do
  [ "$(ls -1 "$d" | wc -l)" -eq 10 ] || fail "$d"
done
python3 -c "import tomllib; tomllib.load(open('profiles/codex/.codex/agents/aid-screener.toml','rb'))"

# (c) the screener's grants, read off the RENDERED body in every tree
grep -q 'Read, Glob, Grep' <rendered screener> && ! grep -qw 'Bash' <rendered screener>

# (d) the screener does NOT inherit the exhaustiveness block -- the discriminating case
grep -q 'Enumerate the class, not the instance' <rendered aid-reviewer>   # present
grep -q 'Enumerate the class, not the instance' <rendered aid-screener> && fail

# (e) determinism and the count gate, both existing
python3 .claude/skills/generate-profile/scripts/verify_deterministic.py
bash tests/canonical/test-doc-counts.sh            # must still be 31 passed / 0 failed
```

**(a) is the assertion that matters**, and the one a weaker suite would omit: it converts "the
split did not change nine agents" from a hope into a byte comparison across seven trees, and it is
checkable *before* implementation because §1(i) already proved the string identity holds.

**(d) is the discriminating case.** A parity check asserting only "all trees are identical" passes
trivially if the split gave every agent the block, or none of them. (d) asserts a *difference*
that must exist in every tree.

**Non-trivially-false baselines, all measured:** `grep -rn 'aid-light-review' canonical/ | wc -l`
→ 0; `aid-deep-review` → 0; `grep -rn 'aid-screener' canonical/ .aid/knowledge/ | wc -l` → 0;
`grep -rl '{{include:agent-boilerplate}}' canonical/agents | wc -l` → 9;
`ls canonical/skills/*/references/reviewer-brief.md | wc -l` → 6;
`grep -rn 'Enumerate the class, not the instance' canonical/` → 2 files, 3 lines.

**What no oracle proves, stated plainly.** *"The screener actually made one pass"* and *"the deep
reviewer honoured the resume plan"* are runtime properties of an agent. These oracles prove the
screener **cannot** grade (no `Bash`, no write path, no ledger tool), **cannot** inherit the
exhaustiveness mandate (the token is absent from its body in all seven trees), and that a clean
light pass leaves **no coverage artifact** a deep pass could mistake for clearance.

### 10. FR-E1 — the Q3 re-triage

**Seven survive**, each in a file features 001–005 do not rewrite, or one this feature rewrites
anyway:

| Item | Verdict |
|---|---|
| **Q3(a)** `aid-execute/references/state-review.md` self-contradicts | **Fix here.** Line 3 says the reviewer *"produces the full grade"*; line 177 says *"No grade is computed at the task level."* No `## Step 1` or `## Step 2` heading exists. A Tier-1 caller, rewritten by the migration. **Count correction:** Q3 says "four times"; `grep -c 'Step 2'` returns **2** (lines 68, 117) |
| **Q3(b)** `reviewer-guide.md:3` points at the removed Step 2 | **Survives.** feature-001 deletes 6–14 and 35; line 3 is untouched by all five. Resolved by retiring the file |
| **Q3(c)** the `references/reviewer-guide.md` pointer is renderer-blind | **Survives.** `reviewer-brief.md:35` still carries the bare relative path. feature-001 fixes four *other* pointers; feature-002 fixes the `aid-discover` brief's. This one is nobody's |
| **Q3(d)** `README.md:52` Large tier vs canonical `medium` | **Fix here.** 002 and 005 both explicitly declined it; now load-bearing because §3's carve-out is authored here |
| *"Six per-skill briefs"* then seven listed; `aid-describe` has none | **Resolved here** by §5's redesign. `ls … \| wc -l` = 6; `aid-describe` needs no brief file |
| *"EXACTLY these 5 sections"* but six ship | **Resolved here**, wholesale, by the shared template |
| `shortcut-engine.md:765–766` lists five, omitting `DELIVERABLES` | **Resolved here** — a Tier-1 caller |

**Six retire from FR-E1:** the WSL worktree gitdir bug (not review-path; still live, and a `git`
call inside this worktree reproduced it), the stale emission manifests (build/render defect;
003/004/005 already handle the consequence), `/aid-update-kb`'s branch base (feature-004 §4
absorbed it), the `test-grade.sh` count note (a process lesson, not a defect), `[TEACHBACK]`
defined-but-never-emitted (feature-002 §6 owns it), and `PROJECT-INDEX` unexpressible in the
rule-ID regex (logged as a non-blocking implementation note).

**Decided: `aid-execute/references/reviewer-guide.md` is retired.** Its per-Type checklists
(IMPLEMENT / TEST / RESEARCH / DESIGN / DOCUMENT / MIGRATE / REFACTOR / CONFIGURE) are exactly the
class rule sets feature-002's catalog is built to hold. Retiring the file resolves Q3(b) and Q3(c)
by deletion. **Cost, stated:** it discards feature-001's edits at 6–14 and 35, and feature-002
must absorb the checklist content — a hand-off carried as an AC here.

### 11. Affected-artifact inventory and region ownership

**New files (6):** the two skill directories, `canonical/agents/aid-screener/{AGENT.md,README.md}`,
`canonical/aid/templates/agent-discipline-boilerplate.md` (lines 34–59 verbatim),
`canonical/aid/templates/reviewer-brief-template.md`, and
`tests/canonical/test-review-extraction.sh`.

| File | Claimed here | Cross-check |
|---|---|---|
| `canonical/agents/aid-reviewer/AGENT.md` | **8, 20, 33–34, 37, 105, 108** + a new `## Depth and Division of Labour` | The exact complement of the 001–005 union. Confirms N2: no region touched twice. 58/68/80 stay blank |
| `canonical/agents/aid-reviewer/README.md` | **15, 52** | 11/13/31/33 feature-002; 63/66 feature-001; 80–81 + "after 34" feature-004; "after 64" feature-005 |
| `canonical/aid/templates/agent-boilerplate.md` | **34–59 removed** (relocated) | Unclaimed by 001–005 |
| The other **8** `canonical/agents/*/AGENT.md` | one inserted include token each | Unclaimed. Rendered bytes unchanged — §9(a) |
| `agent-dispatch-tiering.md` | **insertion after 54**, **insertion after 31** | Line 54 is `aid-reviewer`'s row and stays |
| `reviewer-dispatch.md` | **20, 174–208, 215–246**, **277–301** | **Narrowed** from 174–214 to avoid feature-004's 209–214 claim (its claim there is semantic — the invention licence; mine is structural). 122–123/170 feature-001; 43–44/196/269 declined by 003; 133–134/247–254 feature-004; **49** feature-005 |
| The six `reviewer-brief.md` | **whole-file rewrite** to the two per-skill sections | Inverts feature-004's `GAP POLICY` oracle and re-points feature-005's oracle (b); both carried as ACs |
| The 8 Tier-1 callers' review states | the review span in each | Feature-005 §9 claims lifecycle lines inside these spans. Sequential ordering (005 → 006) makes it safe: rewritten once by 005, relocated by 006. Four to six lines of accepted collateral, same precedent as feature-003 §5's 96–99 |
| `canonical/skills/aid-review/SKILL.md` | **122–143** (REVIEW state) | Unclaimed. `aid-audit/SKILL.md` unchanged |
| `canonical/skills/aid-triage/SKILL.md` | one routing row | Unclaimed |
| `state-machine-chaining.md` | **insertion after 39** (under CHAIN's `Use for:`) | Feature-004 claims after 47, under PAUSE. Disjoint. Line 96 untouched |
| `canonical/aid/templates/settings.yml` | additive: `review.light_severity_floor`, `review.light_min_artifacts` | Unclaimed. NFR-4's threshold and FR-A2's floor |
| `aid-execute/references/reviewer-guide.md` | **retired** | §10 |
| `.aid/knowledge/architecture.md` | **129, 311–322**, and the invariant paragraph at ~334–337 | Unclaimed by 001–005 |
| `.aid/knowledge/module-map.md` | **82, 120, 245** | Unclaimed |
| `.aid/knowledge/decisions.md` | **88** (D15) + a new decision row | Unclaimed |
| `.aid/knowledge/pipeline-contracts.md` | **400** | Feature-004 claims 293–298. Disjoint |
| The 13 count surfaces + 2 test literals | §7 | Mechanically gated by `test-doc-counts.sh` |

**Regenerated, never hand-edited:** `.aid/knowledge/INDEX.md`, `kb.html`,
`site/src/content/docs/reference/agents.md`, and the seven rendered trees.

### 12. Out of scope

- Everything features 001–005 own; this feature consumes all of it.
- **FR-A7 is CUT** — "invocable by skills that do not exist yet" has no test and is an aspiration.
- Tier 3's ~19 `repurpose` VERIFY dispatches — deferred with a named successor, not dropped.
- The settings gate, frontmatter-lint wiring, BLUEPRINT review, per-section specify ledger, and
  the single-grading-backend consolidation — **feature-007**.
- Six Q3 items re-triaged out (§10), and one **new** Q3 item logged: the
  `self-review-protocol.md` exemption mismatch (§3).

### Delivery recommendation

Five. **D0** — base reconciliation (§1) and the AC-11 baseline; hours, and everything else is
authored against it. **D1** — the boilerplate split alone: two template files, nine token
insertions, the `aid-screener` agent, the roster docs and the 21 count assertions; oracle (a)'s
empty diff is its whole gate. **D2** — the two skills, the shared brief template, the six
shrunken briefs, and the two inherited-oracle inversions. **D3** — the eight Tier-1 migrations
plus `aid-review`; largest file count, smallest per-file change, and where AC-11 is earned.
**D4** — the FR-A10 rewrite, the README, and the nine-item conformance check; last, because it is
the only delivery that must see 001–005 fully landed. D1 gates D2; D2 gates D3; D4 is independent
of D2/D3.
