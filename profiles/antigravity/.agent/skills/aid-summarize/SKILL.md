---
name: aid-summarize
description: >
  Generate a single-file kb.html from .aid/knowledge/. Domain-driven, doc-set-based:
  one section per resolved doc derived from frontmatter (kb-category, objective, summary,
  tags, see_also). Audience: non-technical newcomer (visually rich; no KB authoring-rules
  leakage). Light/dark theme, click-to-expand lightbox, accessibility-first (WCAG AA).
  One grading backend: script-verifiable checks and an interactive human checklist (KB
  completeness, fact-grounding, V1 mandatory human visual check) both write findings to the
  review ledger, and grade.sh derives the single letter from it. APPROVAL requires that grade
  >= minimum AND the checklist to have been completed; an unanswered checklist produces no
  grade at all and pauses for the human.
  Idempotent: re-running on an unchanged KB does nothing. State-machine: PREFLIGHT ->
  STALE-CHECK -> PROFILE -> GENERATE -> VALIDATE -> MANUAL-CHECKLIST -> FIX -> APPROVAL ->
  WRITEBACK -> DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--grade X] override minimum  [--theme default|brand-X]  [--reset]"
---

# Knowledge Base Visual Summary

Generates a single self-contained `kb.html` from a populated and approved
`.aid/knowledge/` Knowledge Base. The output is a **newcomer-facing product** — visually
rich, plain-language, and distinct from the KB itself (which is a dual-audience technical
artifact for humans + AI agents). The KB's authoring rules (no diagrams, tables/bullets)
apply to the KB; they do NOT constrain the summary's format.

The section set is derived **data-drivenly** from the resolved doc-set
(`discovery.doc_set` in `.aid/settings.yml` intersected with docs present on disk),
one section per resolved doc. Each section's attributes (heading, description, component,
tier, keyword pills, cross-links) come from that doc's frontmatter (`kb-category`,
`objective`, `summary`, `tags`, `see_also`). Section order is deterministic and
reproducible from the same inputs.

**Prerequisite:** `/aid-discover` must have reached `DONE` and the user must have
approved the KB. This skill does NOT validate KB content — that is discovery's job.

**Idempotent:** Running `/aid-summarize` repeatedly on an unchanged KB is a no-op.
It only regenerates the HTML when the KB has been re-reviewed since the last
summarization.

---

## ⚠️ Pre-flight Checks

Run `.agent/aid/scripts/summarize/summarize-preflight.sh` before any state. It verifies:

1. `.aid/knowledge/STATE.md` exists.
2. `**User Approved:** yes` is present in `.aid/knowledge/STATE.md`.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in Plan Mode (need write access).
5. Node.js >= 18 is available (required for visual-fidelity validation via `validate-visuals.mjs`).

If any check fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Override the minimum acceptable grade. Format: `[A-F][-+]?`. Without this, runs `bash .agent/aid/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A` (resolves per-skill override → global `review.minimum_grade` → default `A`). When passed, persist to `.aid/settings.yml` `summary.minimum_grade` via `/aid-config`. |
| `--theme palette=X` | Override color palette (e.g., `--theme palette=brand-acme`). Default uses the canonical palette in `.agent/aid/templates/knowledge-summary/design-tokens.md`. |
| `--reset` | Force regeneration regardless of staleness check; clears `## Knowledge Summary Status` in `.aid/knowledge/STATE.md`. |

---

## State Detection

⚠️ **Filesystem is the only source of truth.** Always read actual files on disk.

The state-detection logic determines which mode this run executes:

```
1. PREFLIGHT (synchronous gate). Aborts on failure — no further state runs.

2. Read .aid/knowledge/STATE.md §§ Knowledge Summary Status, Summarization History.

3. STALE-CHECK first (always):
   - Compare LAST_KB_CHANGE_DATE (latest entry in STATE.md ## Review History)
     vs LAST_SUMMARY_DATE (latest entry in STATE.md ## Summarization History,
     or the **Last Run** field in ## Knowledge Summary Status).
   - If --reset → mode = GENERATE (force).
   - If kb.html missing → mode = GENERATE.
   - If ## Summarization History missing/empty → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE > LAST_SUMMARY_DATE → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE <= LAST_SUMMARY_DATE AND HTML exists:
       AND STATE.md's `summary_approved` frontmatter scalar is `yes` (or, for an
       un-migrated file, the legacy `## Knowledge Summary Status` `**User Approved:** yes`
       bold line) → mode = DONE-IDEMPOTENT (exit cleanly)
       OTHERWISE → mode = APPROVAL (HTML is current; just need user sign-off)

4. If mode = GENERATE:
   - ## Knowledge Summary Status absent/no Doc-Set Source → run PROFILE first to read
     discovery.doc_set from .aid/settings.yml + domain from .aid/knowledge/STATE.md,
     resolve the section manifest, then GENERATE.
   - ## Knowledge Summary Status has Doc-Set Source → reuse stored manifest; go straight
     to GENERATE.

5. After GENERATE → VALIDATE.

6. After VALIDATE (script-only checks → findings → grade.sh):
   - grade < minimum → FIX (loops back to VALIDATE).
   - grade >= minimum → MANUAL-CHECKLIST.

7. After MANUAL-CHECKLIST (human-judgment answers → findings → grade.sh):
   - checklist not completed → **PAUSE-FOR-USER-ACTION**: print the `manual-checklist.sh` command
     and exit. No grade is produced. **Not HALT** — HALT is terminal, and this is the one outcome
     designed to be resumed (`references/state-manual-checklist.md`).
   - grade < minimum → FIX (loops back to VALIDATE).
   - grade >= minimum → APPROVAL.

8. After APPROVAL:
   - User says yes → WRITEBACK → DONE.
   - User says no → exit (no writeback; user can fix or --reset).
   - User says changes-needed → record + transition to FIX.
```

**One grading backend.** Machine checks and human-judgment answers both produce **findings** in the review ledger, and `grade.sh` derives the single letter from it — the same path every other AID artifact takes. Neither half computes a grade of its own, and there is nothing to combine.

The checks are unchanged in substance. Coverage emits one `SUMMARY-01` finding per KB document the summary does not represent, naming it, instead of scoring a coverage percentage against a 60% cliff. T1/T2/T3 are the S7 visual-fidelity checks (`validate-visuals.mjs`, Playwright-based) asserting readable text, minimal overlap and correct layout for every authored visual; `SUMMARY-07` asserts the retired Mermaid engine is absent (`validate-html-output.sh`).

**The human visual check is mandatory and no agent may answer it.** When Playwright is unavailable, T1/T2/T3 skip and it carries the full visual-review responsibility — browser rendering, not source inspection. **If the checklist has not been completed, the outcome is no grade at all — pause and ask (PAUSE-FOR-USER-ACTION, not HALT).** Reporting a failing grade for a check nobody performed asserts a result that was never observed.

See `review-rubrics/summary.md` for the rules and `knowledge-summary/grading-rubric.md` for the check definitions and why the two-grade model was retired.

Print the state-entry line and "you are here" map at the start of each mode:

**PREFLIGHT:**
```
[State: PREFLIGHT] — Verifying prerequisites: KB approved, Node.js available, network reachable.
aid-summarize  ▸ you are here
  [● PREFLIGHT ] → [ STALE-CHECK ] → [ PROFILE ] → [ GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**STALE-CHECK:**
```
[State: STALE-CHECK] — Comparing KB review date vs last summary date to determine if regeneration is needed.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [● STALE-CHECK ] → [ PROFILE ] → [ GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**PROFILE:**
```
[State: PROFILE] — Reading doc-set from .aid/settings.yml and domain from .aid/knowledge/STATE.md to derive the section manifest.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [● PROFILE ] → [ GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**GENERATE:**
```
[State: GENERATE] — Building kb.html from resolved doc-set and KB frontmatter (one section per resolved doc).
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [● GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**VALIDATE:**
```
[State: VALIDATE] — Running machine-verifiable quality checks (coverage, links, HTML, accessibility, contrast).
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [✓ GENERATE ] → [● VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**APPROVAL:**
```
[State: APPROVAL] — Grade meets minimum and the checklist is recorded; awaiting user approval.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [✓ GENERATE ] → [✓ VALIDATE ] → [● APPROVAL ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Summary approved and Summarization History updated.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [✓ GENERATE ] → [✓ VALIDATE ] → [✓ APPROVAL ] → [● DONE ]
```

---

## Dispatch

| State | Detail | Worker | Advance |
|-------|--------|--------|---------|
| PREFLIGHT | `references/state-preflight.md` | inline | → STALE-CHECK |
| STALE-CHECK | `references/state-stale-check.md` | inline | → PROFILE |
| PROFILE | `references/state-profile.md` | inline | → GENERATE |
| GENERATE | `references/state-generate.md` | inline | → VALIDATE |
| VALIDATE | `references/state-validate.md` | inline | → MANUAL-CHECKLIST (grade ≥ min) / → FIX (grade < min) |
| MANUAL-CHECKLIST | `references/state-manual-checklist.md` | inline | → APPROVAL |
| FIX | `references/state-fix.md` | inline | → VALIDATE |
| APPROVAL | `references/state-approval.md` | inline | → WRITEBACK |
| WRITEBACK | `references/state-writeback.md` | inline | → DONE |
| DONE | `references/state-done.md` | inline | → halt |

On state entry, print `[State: NAME]` + the "you are here" map from State Detection above.
When a state completes, route by its `**Advance:**` type (per [`state-machine-chaining.md`](../../templates/state-machine-chaining.md)):
- **CHAIN** → begin the next state's reference doc within the same invocation; no exit.
- **PAUSE-FOR-USER-ACTION** / **PAUSE-FOR-USER-DECISION** → print the pause reason + resume command and exit.
- **HALT** → print the closing summary and exit.

> **Note on DONE extraction:** Unlike other AID skills (aid-deploy/aid-execute/aid-detail/aid-plan) which keep DONE inline as a trivial halt-message state, aid-summarize's DONE is a **composite state** (handles both Normal-completion-after-WRITEBACK and DONE-IDEMPOTENT-after-STALE-CHECK branches with distinct messaging). The 38-line state body warrants extraction to `references/state-done.md` per the thin-router principle. This asymmetry is intentional, not a defect.


> **Note — DONE-IDEMPOTENT:** When STALE-CHECK determines the HTML is already
> up-to-date and approved, the router dispatches to the `DONE` row. The
> `references/state-done.md` file contains both the normal-completion body and the
> idempotent-completion body (DONE-IDEMPOTENT variant). The detection logic in
> State Detection step 3 selects which variant to execute.

---

## Quality Gate

The VALIDATE state runs the script-verifiable checks and emits findings before
human review. This includes:

- **S7 visual-fidelity gate** (`validate-visuals.mjs`) — Playwright-renders every authored
  visual (inline `<svg>`, `.diagram-box`, infographic containers) and asserts: text readable
  (T1), minimal/zero element overlap (T2), correct basic layout (T3). A failing visual is a
  `SUMMARY-06` finding at `[HIGH]` and blocks approval. **This validator is not invoked by
  `emit-summary-findings.sh`** — it never has been, including by the `grade-summary.sh` it
  replaced — so run it by hand until it is wired (`references/state-validate.md` carries the
  detail). Either way the MANUAL-CHECKLIST human visual check is **mandatory** and is the live
  safeguard: browser-rendered inspection is required, and HTML/CSS source inspection is not
  sufficient.
- **HTML self-containment + no-Mermaid-engine assertion** (NM check in `validate-html-output.sh`)
  — confirms the Mermaid runtime engine is absent from the output (D-012 guardrail).
- **Accessibility baseline** (A1/A2/A3/A4/A5), **link correctness** (L1/L2), **HTML validity** (H1),
  and **contrast** (C1/C2, via `contrast-check.mjs`).

See `.agent/aid/templates/knowledge-summary/grading-rubric.md` for the per-check definitions and pass criteria. It defines no grade and carries no ladder -- the letter comes from `grade.sh` over the ledger, per `.agent/aid/templates/grading-rubric.md`, AID's single grading rubric.

---

## References

- `.agent/aid/templates/knowledge-summary/prompt.md` — agent guidance for the GENERATE step (long-form)
- `.agent/aid/templates/knowledge-summary/design-tokens.md` — color palette, typography, spacing
- `.agent/aid/templates/knowledge-summary/component-css.css` — full reusable CSS (inlined)
- `.agent/aid/templates/knowledge-summary/lightbox.js` — full reusable JS (theme, lightbox, scrollspy, a11y)
- `.agent/aid/scripts/summarize/validate-visuals.mjs` — §7 visual-fidelity gate (Playwright-based): T1 readable text, T2 minimal overlap, T3 correct layout for every authored visual (inline `<svg>`, `.diagram-box`, infographic container). **Not invoked by `emit-summary-findings.sh`** — run it by hand; see `references/state-validate.md`
- `.agent/aid/templates/knowledge-summary/section-templates/` — `kb-category`-keyed rendering hints (retired as project-type profile selectors)
- `.agent/aid/templates/knowledge-summary/accessibility-checklist.md` — WCAG AA targets, focus trap pattern
- `.agent/aid/templates/knowledge-summary/grading-rubric.md` — the per-check definitions and pass criteria the `SUMMARY-*` rules cite. Defines no grade; `grade.sh` does that from the ledger
- `.agent/aid/templates/knowledge-summary/html-skeleton.html` — doctype, head, semantic landmarks, noscript (with `{{NOSCRIPT_DOC_LIST}}` placeholder for derived doc list)
- `.agent/aid/scripts/summarize/emit-summary-findings.sh` — orchestrates the machine checks and writes a ledger row per failure, citing the rule it breaks. It computes no grade; `grade.sh` does, from the ledger
- `.agent/aid/scripts/summarize/manual-checklist.sh` — records the human-judgment answers (`--input PATH` headless mode; `--interactive` for raw-terminal use). It records; it does not score
- `.agent/aid/scripts/summarize/spot-check-facts.sh` — extracts HTML claims, grep-matches against source KB, writes `.aid/.temp/summarize/spot-check-facts.txt` (aids the user's K2 judgment)

---

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| Preflight aborts: "discovery not approved" | `/aid-discover` not yet at DONE | Run `/aid-discover` until it reaches APPROVAL and approve. |
| PROFILE warns: "discovery.doc_set not found" | KB was produced before feature-014 | Run `/aid-discover` to produce a feature-014-compatible KB, or the skill falls back to reading all `.aid/knowledge/*.md` files alphabetically. |
| GENERATE produces no sections | All doc-set entries missing on disk | Check that `/aid-discover` has run and the KB docs are present in `.aid/knowledge/`. |
| Writeback fails: lock contention | `/aid-discover` running concurrently | Wait, retry; the lock auto-releases. |
| Writeback fails: write error | Disk full / permissions | Manually add the entry to `.aid/knowledge/STATE.md` `## Summarization History`; mark `**Writeback Status:** ok` in `## Knowledge Summary Status`. |
