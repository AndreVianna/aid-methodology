# Requirements

- **Name:** Plain-Language Knowledge Base Rewrite
- **Description:** Rewrite the Knowledge Base's hand-authored primary and extension docs in plain language without changing the knowledge they record, and tighten the canonical KB-authoring rule so jargon and undefined coined terms cannot come back

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-11 | Initial capture (shortcut: aid-refactor) | /aid-refactor |

## 1. Objective

In the requester's words: *"The jargon in this repo is too cryptic and unclear; the text in the Knowledge Base is hard to understand. Rewrite the Knowledge Base docs in plain language, and tighten the authoring rule that lets jargon back in so the problem cannot regress."*

This is a **prose refactor of the Knowledge Base plus a rule tightening**. Two outcomes:

1. Every hand-authored KB doc reads clearly for a junior professional — the standard the KB already claims to hold itself to.
2. The canonical KB-authoring rule that mandates that standard becomes an **enforced, checked condition** rather than advisory prose, so the KB cannot drift back.

Refactor target: the hand-authored primary + extension docs under `.aid/knowledge/`, plus the canonical KB-authoring rule set that governs them.
Refactor kind: `restructure` (prose restructure — not `rename`, not `performance`).

## 2. Problem Statement

The KB breaches a rule it already publishes. `.aid/knowledge/authoring-conventions.md` § Dual-Audience Standard mandates *"Junior-clear language. Plain words, active voice, short sentences, one idea per sentence. Define project-specific terms in `domain-glossary.md` on first use"* and lists *"jargon a junior could not follow"* as a red flag. The same rule exists upstream in `canonical/aid/templates/kb-authoring/principles.md` § P10 → Language. Neither is enforced by anything mechanical — the review rubric's Full Primary checklist has no plain-language or glossary-coverage check — so the rule is advisory and the KB has drifted away from it.

Concrete evidence from the analysis that motivated this work:

| Symptom | Evidence |
|---|---|
| Coined metaphors used heavily, defined nowhere | "load-bearing", "Concept Spine", "dogfood", "kind-sibling", "thin doorway", "fat pipeline", "hand-authored collapse", "lockstep", "render-drift", "HOME-pinning" — roughly 450 hits of this term family across `.aid/knowledge/*.md`, while `domain-glossary.md` defines only 32 terms (`### ` headings) |
| Jargon stacking | `architecture.md` frontmatter `objective:` chains four abstractions before a concrete noun ("the canonical→profiles→packages render-and-distribute architecture, and the six-phase gated process architecture (pipeline, skill state machines, agent dispatch)") |
| Over-long frontmatter sentences | `test-landscape.md`'s `summary:` is one ~90-word sentence with six em-dash asides |
| The damage compounds in the routing table | `INDEX.md` concatenates every doc's `objective:` + `summary:` into one wall of text, so unreadable frontmatter degrades the file every agent loads first |
| Shouted bare codes with no legend | `CONFIRMED`, `SYNTHESIS`, `ELICIT E1/E2`, `S1-S5`, `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT` used as opaque tokens |

The cost lands on both audiences the KB serves: a junior human cannot read it, and an agent routing over undefined terms has no anchor to resolve them against.

## 3. Users & Stakeholders

| Role | Description | Primary Needs |
|------|-------------|---------------|
| Repo maintainer (requester) | Owns the AID methodology repo | A KB he can read without decoding it; a rule that keeps it that way |
| Junior human reader / new contributor | The KB's declared first audience (`principles.md` P10) | Docs understandable without prior AID vocabulary; every project term defined on first use |
| AI agent consuming the KB | Loads `INDEX.md` then routes to a doc (RAG-by-convention) | Unambiguous, defined terms; short scannable frontmatter that routes correctly |
| `aid-reviewer` | Grades KB docs against `kb-authoring/review-rubric.md` | A checkable plain-language / glossary-coverage condition with a stated severity, not a judgment call with no rubric line |
| Architect | Declared `owner:` of `authoring-conventions.md` | The KB-mirror doc stays consistent with the tightened canonical rule |

## 4. Scope

### In Scope

- **Plain-language rewrite of the hand-authored primary + extension KB docs** under `.aid/knowledge/`. The knowledge must not change — only how it is worded. In-scope docs (current word counts, for sequencing and for the growth budget in §6):

  | Doc | Words | Category |
  |---|---|---|
  | `domain-glossary.md` | 6741 | primary |
  | `architecture.md` | 4127 | primary |
  | `artifact-schemas.md` | 5081 | primary |
  | `authoring-conventions.md` | 2386 | primary |
  | `capability-inventory.md` | 2803 | primary |
  | `coding-standards.md` | 2252 | primary |
  | `infrastructure.md` | 2290 | primary |
  | `integration-map.md` | 2720 | primary |
  | `module-map.md` | 4193 | primary |
  | `pipeline-contracts.md` | 4309 | primary |
  | `project-structure.md` | 2505 | primary |
  | `tech-debt.md` | 9674 | primary |
  | `technology-stack.md` | 1652 | primary |
  | `test-landscape.md` | 5125 | primary |
  | `decisions.md` | 4856 | extension |
  | `quality-gates.md` | 3052 | extension |
  | `release-tracking.md` | 4942 | extension |

- **Frontmatter rewrite** (`objective:`, `summary:`) on those same docs — this is what `INDEX.md` is composed from.
- **Glossary completion**: every coined term the rewritten KB retains gets a definition in `domain-glossary.md`; terms not worth defining are replaced with plain words.
- **Tightening the canonical rule** so the problem cannot regress: make the existing "junior-clear language" expectation **enforceable rather than advisory**, and make **glossary coverage of coined terms a checked condition**. The canonical home of the KB-authoring rules and the reviewer rubric is `canonical/aid/templates/kb-authoring/` (`principles.md` § P10 → Language; `review-rubric.md` § Rubric: Full Primary + § Lint output → severity mapping), with `canonical/skills/aid-discover/references/` carrying the state-level reviewer wiring. The exact insertion points are a SPEC decision.
- **Mirroring the tightened rule** into `.aid/knowledge/authoring-conventions.md` (§ Dual-Audience Standard and the § Enforcement table), which is the KB's own restatement of the canonical rule.
- **Re-rendering `canonical/` changes to `profiles/`** with the generator.
- **Regenerating `INDEX.md`** from the rewritten frontmatter with `build-kb-index.sh`.

### Out of Scope

- **A style sweep of the shipped skills/templates prose under `canonical/skills/**`.** Only the authoring **rule** changes there; the surrounding prose is not rewritten.
- **`.aid/knowledge/relationships.md` and `.aid/knowledge/kb.html`** — both generated.
- **The body of `.aid/knowledge/INDEX.md`** — generated by `build-kb-index.sh` from each doc's frontmatter. It is fixed by fixing the source docs' frontmatter, never by editing `INDEX.md`.
- **Any change to the knowledge the KB records** — no new facts, no removed facts, no re-scoped claims. This includes leaving pre-existing factual defects and contradictions in place (see §8).
- **Hand-edits to the five profile renders** under `profiles/` — they are build output.
- **Meta docs** (`README.md`, `STATE.md`, `external-sources.md`) — review-exempt process/ledger files, not knowledge prose.

## 5. Functional Requirements

- **FR-1 — Rewrite for plain language.** Each of the 17 in-scope docs is rewritten so its prose meets the existing dual-audience standard: plain words, active voice, short sentences, one idea per sentence, no undefined project term.
- **FR-2 — Preserve the knowledge exactly.** Every factual claim, contract, enum, table row, path, command, and citation present before the rewrite is present after it, with the same meaning and the same scope. The rewrite adds no fact and drops none. This is the behavior-preservation guarantee for this refactor; it is verified per doc by a before/after claim comparison plus the existing lint and review gates (§9).
- **FR-3 — Define or eliminate every coined term.** For each coined/metaphorical term appearing in the rewritten KB, either add a `### ` definition to `domain-glossary.md` or replace the term with plain words. The list in §2 is a starting point, not the full set — the rewrite enumerates the whole class rather than the cited examples.
- **FR-4 — Give every shouted bare code a resolvable meaning.** Codes such as `CONFIRMED`, `SYNTHESIS`, `ELICIT E1/E2`, `S1-S5`, `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT` are expanded on first use in their doc or resolve to a named legend/glossary entry.
- **FR-5 — Rewrite frontmatter so `INDEX.md` reads well.** `objective:` and `summary:` on every in-scope doc are rewritten to the readability bounds in §6, then `INDEX.md` is regenerated with `build-kb-index.sh`.
- **FR-6 — Sequence the glossary first.** `domain-glossary.md` is rewritten and completed before the other docs, because the rest of the rewrite depends on the settled term set.
- **FR-7 — Make the plain-language rule enforceable.** The canonical KB-authoring rule stops being advisory: the plain-language expectation becomes a stated, checked condition with a defined severity, wired into the KB review path so a violation produces a ledger finding (or a failing lint) rather than passing silently.
- **FR-8 — Make glossary coverage a checked condition.** A coined term used in a KB doc with no `domain-glossary.md` definition is a detectable violation, not a matter of reviewer recall.
- **FR-9 — Mirror the rule into the KB.** `authoring-conventions.md` § Dual-Audience Standard and its § Enforcement table state the tightened rule and name what enforces it, consistent with the canonical source.
- **FR-10 — Re-render, never hand-edit.** Every `canonical/` change is propagated to `profiles/` by running the generator; `profiles/` is never edited by hand.

## 6. Non-Functional Requirements

- **Frontmatter readability (measurable):** `objective:` is a single line of at most 25 words, naming a concrete subject before any chain of abstractions; `summary:` is at most two sentences, each at most 30 words, with at most one em-dash aside.
- **Growth budget:** no rewritten doc exceeds its §4 baseline word count by more than 15%. Plain language may cost a few words; it must not become padding.
- **No new toolchain dependency:** any enforcement check runs on the toolchain already declared in `technology-stack.md` (Bash / Python / the existing KB scripts). No new runtime dependency.
- **Determinism preserved:** the generator render stays deterministic — a re-run produces no diff.
- **Quality bar:** the resulting KB clears the resolved `minimum_grade` of `A`.

## 7. Constraints

- **`canonical/` is the only editable source.** `profiles/` is generated build output and must never be hand-edited; changes reach it only through `python .claude/skills/generate-profile/scripts/run_generator.py`.
- **`.aid/knowledge/**` must never name a work id or a work-folder path** — not `work-008`, not `.aid/works/work-008-*/`, not "added in work-008" — in prose, tables, headings, or frontmatter. The reviewer treats any `work-[0-9]{3}` hit as a HIGH finding with no exception.
- **All existing KB authoring conventions still bind the rewrite:** required frontmatter fields (`objective:`, `summary:`, `sources:`), the fixed doc layout order, tables-and-lists over prose, no diagrams, durable (grep-recoverable) citations instead of `file:LINE`, current-state-only content.
- **Generated files stay generated:** `INDEX.md`, `relationships.md`, and `kb.html` are refreshed by their generators, never authored.
- **Shipped-script constraints apply** if the enforcement check touches shipped scripts: ASCII-only, and Windows PowerShell 5.1 compatibility for any PowerShell twin.
- **Host environment:** Windows, with `bash` available via WSL; all work happens in the work's git worktree.

## 8. Assumptions & Dependencies

**Assumptions**

- The KB's current *content* is accepted as correct. This work changes wording only, so pre-existing factual defects and internal contradictions are carried forward untouched — for example, `authoring-conventions.md` § KB Document Layout requires `## Change Log` as the last section while `canonical/aid/templates/kb-authoring/principles.md` § P10 → Layout says a KB doc has no change-log section. Resolving that belongs to a separate work.
- The coined-term and shouted-code lists in §2 are illustrative samples drawn from the motivating analysis, not a complete inventory; the rewrite is responsible for enumerating the full class.
- Whether enforcement lands as a mechanical lint, a reviewer-rubric check, or both is a design decision for SPEC. This document requires only that a violation be *detected*, not how.
- A prose-only rewrite does not require re-running `/aid-discover`; the doc set and its approval state are unchanged.

**Dependencies**

- `canonical/aid/templates/kb-authoring/` — `principles.md` (P1/P9/P10), `review-rubric.md`, `frontmatter-schema.md`, `concern-model.md`: the canonical rule set being tightened.
- `canonical/skills/aid-discover/references/` — `document-expectations.md`, `state-review.md`, `reviewer-prompt*.md`: the reviewer wiring the tightened rule must reach.
- `.claude/aid/scripts/kb/lint-frontmatter.sh`, `.claude/aid/scripts/kb/kb-citation-lint.sh`, `.claude/aid/scripts/kb/build-kb-index.sh`, `.claude/aid/scripts/grade.sh` — the existing mechanical gates.
- `python .claude/skills/generate-profile/scripts/run_generator.py` — the canonical → profiles render.
- `aid-reviewer` — grades the rewritten KB against the tightened rubric.

## 9. Acceptance Criteria

- **AC-1 — Knowledge unchanged.** *Given* a rewritten KB doc and its pre-rewrite version, *when* the two are compared claim by claim, *then* every fact, contract, enum value, table row, path, command, and citation present before is present after with unchanged meaning and scope, and nothing new is asserted.
- **AC-2 — No undefined coined term.** *Given* the rewritten `.aid/knowledge/*.md`, *when* the coined-term set is checked against `domain-glossary.md`, *then* every coined term used in the KB has a `### ` definition there, and every term listed in §2 either has a definition or no longer appears in the KB.
- **AC-3 — No opaque bare code.** *Given* any shouted token (`CONFIRMED`, `SYNTHESIS`, `ELICIT E1/E2`, `S1-S5`, `T1-T6`, `P1`/`P9`/`P10`, `C0`-`C9`, `APPROVAL-HALT`, or any other), *when* a reader meets its first occurrence in a doc, *then* it is expanded there or resolves to a named legend or glossary entry.
- **AC-4 — Frontmatter within bounds.** *Given* each in-scope doc's frontmatter, *when* `objective:` and `summary:` are measured, *then* `objective:` is one line of ≤ 25 words and `summary:` is ≤ 2 sentences of ≤ 30 words each with ≤ 1 em-dash aside; `architecture.md`'s `objective:` and `test-landscape.md`'s `summary:` specifically satisfy this.
- **AC-5 — INDEX regenerated, not edited.** *Given* the rewritten frontmatter, *when* `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md` runs, *then* it succeeds, `INDEX.md` reflects the new frontmatter, and re-running it produces no further diff.
- **AC-6 — Growth budget respected.** *Given* each rewritten doc, *when* its word count is compared to its §4 baseline, *then* it exceeds the baseline by no more than 15%.
- **AC-7 — The rule is enforceable.** *Given* a deliberate negative fixture — a KB doc that introduces a coined term with no `domain-glossary.md` entry — *when* the KB check/review path runs, *then* it fails: a non-zero lint exit or a ledger finding at the defined severity. *And given* the same doc with the term defined, *then* it passes.
- **AC-8 — Canonical and KB agree.** *Given* the tightened rule, *when* `canonical/aid/templates/kb-authoring/` and `.aid/knowledge/authoring-conventions.md` (§ Dual-Audience Standard, § Enforcement) are read side by side, *then* they state the same rule and name the same enforcement mechanism, with no contradiction.
- **AC-9 — Render is clean.** *Given* the `canonical/` changes, *when* `python .claude/skills/generate-profile/scripts/run_generator.py && git diff --exit-code -- profiles/` runs, *then* it exits 0 — the render is current and `profiles/` contains no hand edits.
- **AC-10 — Existing lints pass.** *Given* the rewritten docs, *when* `lint-frontmatter.sh` and `kb-citation-lint.sh` run over `.aid/knowledge/`, *then* both pass with no `[FM-MISSING]`, `[FM-INVALID]`, or positional-citation finding.
- **AC-11 — No work references in the KB.** *Given* `.aid/knowledge/**`, *when* it is grepped for `work-[0-9]{3}`, *then* there are no hits.
- **AC-12 — Grade gate cleared.** *Given* the rewritten KB, *when* `aid-reviewer` grades it against the tightened rubric, *then* no plain-language or glossary-coverage finding remains above MINOR and the resulting grade is at least `A` (the resolved `minimum_grade`).

## 10. Priority

**Must** — all of §5 FR-1 through FR-10.

Ordering within the Must set (dependency-driven, not importance-ranked):

1. FR-7, FR-8 — settle the tightened rule first, so the rewrite is written against the standard it will be graded by.
2. FR-6, FR-3 — `domain-glossary.md` and the coined-term decisions, which every other doc's wording depends on.
3. FR-1, FR-4, FR-5 — the per-doc prose and frontmatter rewrite (largest docs — `tech-debt.md`, `domain-glossary.md`, `test-landscape.md`, `artifact-schemas.md` — carry the most work).
4. FR-9, FR-10 — mirror the rule into the KB, then re-render `profiles/`.
