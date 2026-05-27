---
name: aid-summarize
description: >
  Generate a single-file knowledge-summary.html from .aid/knowledge/. Inlines Mermaid
  for offline diagrams, light/dark theme, click-to-expand lightbox, accessibility-first
  (WCAG AA). Two-grade quality gate (Machine + Human): script-verifiable checks score
  the Machine Grade; an interactive checklist scores the Human Grade (K1 KB-completeness,
  K2 fact-grounding, V1 mandatory human visual gate). APPROVAL requires BOTH grades >= minimum.
  Idempotent: re-running on an unchanged KB does nothing. State-machine: PREFLIGHT →
  STALE-CHECK → PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST → FIX → APPROVAL →
  WRITEBACK → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--grade X] override minimum  [--profile auto|web-app|library|cli|microservices|data-pipeline]  [--theme default|brand-X]  [--cdn-mermaid]  [--reset]"
---

# Knowledge Base Visual Summary

Generates a single self-contained `knowledge-summary.html` from a populated and
approved `.aid/knowledge/` Knowledge Base. The output works fully offline, includes
8 Mermaid diagrams (or fewer for non-web-app profiles), supports light/dark themes,
provides keyboard-accessible click-to-expand lightboxes for every diagram, and meets
WCAG AA contrast in both themes.

**Prerequisite:** `/aid-discover` must have reached `DONE` and the user must have
approved the KB. This skill does NOT validate KB content — that is discovery's job.

**Idempotent:** Running `/aid-summarize` repeatedly on an unchanged KB is a no-op.
It only regenerates the HTML when the KB has been re-reviewed since the last
summarization.

---

## ⚠️ Pre-flight Checks

Run `.claude/scripts/summarize/preflight.sh` before any state. It verifies:

1. `.aid/knowledge/STATE.md` exists.
2. `**User Approved:** yes` is present in `.aid/knowledge/STATE.md`.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in Plan Mode (need write access).
5. Network reachable to `registry.npmjs.org` (skipped if `--cdn-mermaid`).

If any check fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Override the minimum acceptable grade. Format: `[A-F][-+]?`. Without this, runs `bash .claude/scripts/config/read-setting.sh --skill summary --key minimum_grade --default A` (resolves per-skill override → global `review.minimum_grade` → default `A`). When passed, persist to `.aid/settings.yml` `summary.minimum_grade` via `/aid-config`. |
| `--profile X` | Force a specific profile. One of: `auto` (default), `web-app`, `library`, `cli`, `microservices`, `data-pipeline`. |
| `--theme palette=X` | Override color palette (e.g., `--theme palette=brand-acme`). Default uses the canonical palette in `.aid/templates/knowledge-summary/design-tokens.md`. |
| `--cdn-mermaid` | Load Mermaid from jsdelivr CDN at runtime instead of inlining (drops ~3 MB; loses offline support). |
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
   - If knowledge-summary.html missing → mode = GENERATE.
   - If ## Summarization History missing/empty → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE > LAST_SUMMARY_DATE → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE <= LAST_SUMMARY_DATE AND HTML exists:
       AND ## Knowledge Summary Status says **User Approved:** yes → mode = DONE-IDEMPOTENT (exit cleanly)
       OTHERWISE → mode = APPROVAL (HTML is current; just need user sign-off)

4. If mode = GENERATE:
   - ## Knowledge Summary Status absent/no Profile → run PROFILE first to detect/persist project type, then GENERATE.
   - ## Knowledge Summary Status has Profile → reuse stored profile; go straight to GENERATE.

5. After GENERATE → VALIDATE.

6. After VALIDATE (script-only checks → Machine Grade):
   - Machine Grade < minimum → FIX (loops back to VALIDATE).
   - Machine Grade >= minimum → MANUAL-CHECKLIST.

7. After MANUAL-CHECKLIST (interactive K1/K2/V1 checks → Human Grade):
   - Human Grade < minimum → FIX (loops back to VALIDATE).
   - Human Grade >= minimum AND Machine Grade >= minimum → APPROVAL.

8. After APPROVAL:
   - User says yes → WRITEBACK → DONE.
   - User says no → exit (no writeback; user can fix or --reset).
   - User says changes-needed → record + transition to FIX.
```

**Two-grade model:** the rubric is split into machine-verifiable checks (the AUTO_POOL — D1/D2/L1/L2/H1/A1/A2/A3/A4/A5/C1/C2/S2 = 73 pts) and human-judgment checks (the MANUAL_POOL — K1/K2/V1 = 30 pts). The script can NEVER auto-pass MANUAL_POOL; the user must run `manual-checklist.sh` and answer the prompts honestly. **V1 (human visual gate) is mandatory — a V1 fail forces Human Grade = F.** Overall Grade = `min(Machine_letter, Human_letter)`. A+ requires both Machine and Human grades to be A+ on their respective subsets. See `grading-rubric.md` for the per-subset boundaries.

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
[State: PROFILE] — Auto-detecting project type from KB signals to select the section template.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [● PROFILE ] → [ GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**GENERATE:**
```
[State: GENERATE] — Building knowledge-summary.html from KB content and Mermaid diagrams.
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [● GENERATE ] → [ VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**VALIDATE:**
```
[State: VALIDATE] — Running machine-verifiable quality checks (diagrams, links, HTML, contrast).
aid-summarize  ▸ you are here
  [✓ PREFLIGHT ] → [✓ STALE-CHECK ] → [✓ PROFILE ] → [✓ GENERATE ] → [● VALIDATE ] → [ APPROVAL ] → [ DONE ]
```

**APPROVAL:**
```
[State: APPROVAL] — Both Machine and Human grades meet minimum; awaiting user approval.
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

> **Note on DONE extraction:** Unlike other AID skills (aid-deploy/aid-execute/aid-detail/aid-plan) which keep DONE inline as a trivial halt-message state, aid-summarize's DONE is a **composite state** (handles both Normal-completion-after-WRITEBACK and DONE-IDEMPOTENT-after-STALE-CHECK branches with distinct messaging). The 38-line state body warrants extraction to `references/state-done.md` per the thin-router principle. This asymmetry is intentional, not a defect.


> **Note — DONE-IDEMPOTENT:** When STALE-CHECK determines the HTML is already
> up-to-date and approved, the router dispatches to the `DONE` row. The
> `references/state-done.md` file contains both the normal-completion body and the
> idempotent-completion body (DONE-IDEMPOTENT variant). The detection logic in
> State Detection step 3 selects which variant to execute.

---

## Quality Gate (the strict-syntax requirement)

Mermaid silently accepts invalid input and renders a red error block. The skill MUST
catch every such failure before declaring DONE. The grading rubric makes diagram
parse failure (`D1`) an automatic F.

The validator script (`validate-diagrams.mjs`) is required infrastructure. It runs D1
(parse) always; D2 (render) uses `jsdom` to render each diagram and assert a
non-trivial SVG — if `jsdom` is not installed, D2 falls back to parse-only and the
grade output flags `D2: jsdom-fallback` (D2 still passes but with reduced rigor).
Without Node.js entirely, this skill cannot grade. If Node.js is unavailable on the host:
```
❌ Cannot run /aid-summarize.
   Node.js is required for Mermaid diagram validation.
   Install Node.js (≥ 18) and re-run, or run the skill on a different machine.
```

There is no "skip validation" mode. The whole point of this skill is that broken
diagrams are caught before publication.

See `.aid/templates/knowledge-summary/grading-rubric.md` for the complete rubric and grade boundaries.

---

## References

- `.aid/templates/knowledge-summary/prompt.md` — agent guidance for the GENERATE step (long-form)
- `.aid/templates/knowledge-summary/design-tokens.md` — color palette, typography, spacing
- `.aid/templates/knowledge-summary/component-css.css` — full reusable CSS (inlined)
- `.aid/templates/knowledge-summary/lightbox.js` — full reusable JS (theme, lightbox, scrollspy, a11y)
- `.aid/templates/knowledge-summary/mermaid-init.js` — Mermaid theme variables for both modes
- `.aid/templates/knowledge-summary/mermaid-examples.md` — one valid example per diagram type + pitfalls table
- `.aid/templates/knowledge-summary/section-templates/{profile}.md` — section structure per project type
- `.aid/templates/knowledge-summary/accessibility-checklist.md` — WCAG AA targets, focus trap pattern
- `.aid/templates/knowledge-summary/grading-rubric.md` — two-grade rubric (Machine + Human), per-profile diagram counts
- `.aid/templates/knowledge-summary/html-skeleton.html` — doctype, head, semantic landmarks, noscript
- `.claude/scripts/summarize/run-validators.sh` — orchestrates AUTO_POOL checks, reads `.manual-checklist.json` for MANUAL_POOL, prints Machine + Human + Overall grades
- `.claude/scripts/summarize/manual-checklist.sh` — validates / scores the MANUAL_POOL result file (`--input PATH` headless mode; `--interactive` for raw-terminal use)
- `.claude/scripts/summarize/spot-check-facts.sh` — extracts HTML claims, grep-matches against source KB, writes `.spot-check-facts.txt` (aids the user's K2 judgment)

---

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| Preflight aborts: "discovery not approved" | `/aid-discover` not yet at DONE | Run `/aid-discover` until it reaches APPROVAL and approve. |
| Preflight aborts: "no network" | Cannot reach npm registry | Check connection, or use `--cdn-mermaid`. |
| Validate fails: D1 (parse error) | Bad Mermaid syntax in generated diagram | Skill enters FIX automatically; if it loops, manually inspect the failing block. |
| Writeback fails: lock contention | `/aid-discover` running concurrently | Wait, retry; the lock auto-releases. |
| Writeback fails: write error | Disk full / permissions | Manually add the entry to `.aid/knowledge/STATE.md` `## Summarization History`; mark `**Writeback Status:** ok` in `## Knowledge Summary Status`. |
| Browser shows red diagram error block | A diagram somehow passed parse but failed render (rare) | Open browser console, find the offending Figure number, manually fix in HTML, re-run with `--reset`. |
