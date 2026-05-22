---
name: aid-summarize
description: >
  Generate a single-file knowledge-summary.html from .aid/knowledge/. Inlines Mermaid
  for offline diagrams, light/dark theme, click-to-expand lightbox, accessibility-first
  (WCAG AA). Two-grade quality gate (Machine + Human): script-verifiable checks score
  the Machine Grade; an interactive checklist scores the Human Grade (K1 KB-completeness,
  K2 fact-grounding, V1 mandatory human visual gate). APPROVAL requires BOTH grades >= minimum. Idempotent: re-running
  on an unchanged KB does nothing. State-machine: PREFLIGHT → STALE-CHECK → PROFILE →
  GENERATE → VALIDATE → MANUAL-CHECKLIST → FIX → APPROVAL → WRITEBACK → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit
argument-hint: "[--grade X] override minimum  [--profile auto|web-app|library|cli|microservices|data-pipeline]  [--theme default|brand-X]  [--cdn-mermaid]  [--reset]"
---

# Knowledge Base Visual Summary

Generates a single self-contained `knowledge-summary.html` from a populated and
approved `.aid/knowledge/` Knowledge Base. The output works fully offline, supports
light/dark themes, provides keyboard-accessible click-to-expand lightboxes for every
diagram, and meets WCAG AA contrast in both themes.

**Prerequisite:** `/aid-discover` must have reached `DONE` and the user must have
approved the KB. This skill does NOT validate KB content — that is discovery's job.

**Idempotent:** Running `/aid-summarize` repeatedly on an unchanged KB is a no-op.
It only regenerates the HTML when the KB has been re-reviewed since the last
summarization.

---

## Asset Layout

The skill is the orchestrator. The compositional assets — CSS, JS, HTML skeleton,
design tokens, mermaid examples, accessibility checklist, grading rubric, profile
section templates, and validation scripts — live in:

```
.aid/templates/knowledge-summary/
├── design-tokens.md             # Color palette, typography, spacing
├── component-css.css            # Inlined into the output's <style> block
├── lightbox.js                  # Inlined into the output's <script> block
├── mermaid-init.js              # Mermaid theme variables for both modes
├── html-skeleton.html           # Document shell with placeholders
├── mermaid-examples.md          # Syntax patterns + pitfall lookup table
├── accessibility-checklist.md   # WCAG AA targets + focus trap pattern
├── grading-rubric.md            # A–F rubric with concrete pass/fail criteria
├── prompt.md                    # Long-form agent guidance for the GENERATE step
├── section-templates/           # Section structure per profile
│   ├── auto-detect.md           # Profile auto-detection scoring rules
│   ├── web-app.md
│   ├── library.md
│   ├── cli.md
│   ├── microservices.md
│   └── data-pipeline.md
└── scripts/                     # Helpers (executable; require Node.js >= 18)
    ├── check-preflight.sh
    ├── stale-check.sh
    ├── fetch-mermaid.sh
    ├── concatenate.sh           # Unix
    ├── concatenate.ps1          # Windows PowerShell
    ├── validate-diagrams.mjs    # D1 parse + D2 render (jsdom, mmdc fallback)
    ├── validate-links.sh
    ├── validate-html.sh         # H1 cascade + A1/A2/A3/A4/A5 checks
    ├── contrast-check.mjs       # WCAG ratios for both themes
    ├── manual-checklist.sh      # Scores the Human Grade (K1, K2)
    ├── spot-check-facts.sh      # Extracts HTML claims, greps source KB (aids K2)
    ├── grade.sh                 # Orchestrator: two-grade report (Machine + Human)
    └── writeback-discovery-state.sh
```

These templates are installed by `/aid-init`. If `.aid/templates/knowledge-summary/`
does not exist, abort PREFLIGHT with a clear message asking the user to update
`/aid-init` and re-run.

---

## Pre-flight Checks

⚠️ **Filesystem is the only source of truth.** Always read actual files on disk.

Run `.aid/templates/knowledge-summary/scripts/check-preflight.sh` before any state.
It verifies:

1. `.aid/knowledge/DISCOVERY-STATE.md` exists.
2. `**User Approved:** yes` is present in `DISCOVERY-STATE.md`.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in a restrictive mode (need write access).
5. Network reachable to `registry.npmjs.org` (skipped if `--cdn-mermaid`).
6. Node.js ≥ 18 available (required for Mermaid validation).

Additionally verify `.aid/templates/knowledge-summary/` exists and contains the
expected assets. If missing, abort.

If any check fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files.

---

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Override the minimum acceptable grade. Format: `[A-F][-+]?`. Without this, reads `**Minimum Grade:**` from `DISCOVERY-STATE.md` (fallback `A`). Persists to `SUMMARY-STATE.md`. |
| `--profile X` | Force a specific profile. One of: `auto` (default), `web-app`, `library`, `cli`, `microservices`, `data-pipeline`. |
| `--theme palette=X` | Override color palette. Default uses the canonical palette in `.aid/templates/knowledge-summary/design-tokens.md`. |
| `--cdn-mermaid` | Load Mermaid from jsdelivr CDN at runtime instead of inlining (drops ~3 MB; loses offline support). |
| `--reset` | Force regeneration regardless of staleness check; clears `SUMMARY-STATE.md`. |

---

## State Detection

```
1. PREFLIGHT (synchronous gate). Aborts on failure — no further state runs.

2. Read .aid/knowledge/SUMMARY-STATE.md (if it exists) and .aid/knowledge/DISCOVERY-STATE.md.

3. STALE-CHECK first (always):
   - Compare LAST_KB_CHANGE_DATE (latest entry in DISCOVERY-STATE ## Review History)
     vs LAST_SUMMARY_DATE (latest entry in DISCOVERY-STATE ## Summarization History,
     or **Last Run** field in SUMMARY-STATE.md).
   - If --reset → mode = GENERATE (force).
   - If knowledge-summary.html missing → mode = GENERATE.
   - If ## Summarization History missing/empty → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE > LAST_SUMMARY_DATE → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE <= LAST_SUMMARY_DATE AND HTML exists:
       AND SUMMARY-STATE.md says **User Approved:** yes → DONE-IDEMPOTENT (exit cleanly)
       OTHERWISE → APPROVAL (HTML is current; just need user sign-off)

4. If mode = GENERATE:
   - SUMMARY-STATE.md missing → run PROFILE first to detect/persist project type.
   - SUMMARY-STATE.md present → reuse stored profile; go straight to GENERATE.

5. After GENERATE → VALIDATE.
6. After VALIDATE (script checks → Machine Grade):
   Machine < minimum → FIX; else → MANUAL-CHECKLIST.
7. After MANUAL-CHECKLIST (interactive K1/K2/V1 → Human Grade):
   Human < minimum → FIX; else (both grades >= minimum) → APPROVAL.
8. After APPROVAL: yes → WRITEBACK → DONE; no → exit; changes-needed → FIX.
```

Print the chosen mode at the start of each run: `[State: GENERATE]`, etc.

**Two-grade model:** the rubric splits into machine-verifiable checks (AUTO_POOL —
D1/D2/L1/L2/H1/A1/A2/A3/A4/A5/C1/C2/S2 = 73 pts) and human-judgment checks
(MANUAL_POOL — K1/K2/V1 = 30 pts; V1 is a mandatory gate). The script NEVER auto-passes MANUAL_POOL — the
user must run `manual-checklist.sh`. Overall Grade = `min(Machine_letter,
Human_letter)`; A+ requires both. See `grading-rubric.md`.

---

## Mode: STALE-CHECK

Run `.aid/templates/knowledge-summary/scripts/stale-check.sh`. It outputs one of
`STALE`, `CURRENT_APPROVED`, `CURRENT_UNAPPROVED`, or `FIRST_RUN`. Branch accordingly:

- **STALE / FIRST_RUN** → continue to PROFILE/GENERATE.
- **CURRENT_APPROVED** → print "already up-to-date" message and exit DONE.
- **CURRENT_UNAPPROVED** → skip to APPROVAL.

If STALE due to KB changes:
```
ℹ️  KB was reviewed on {LAST_KB_CHANGE_DATE}, last summary was {LAST_SUMMARY_DATE}.
   Regenerating to match latest KB...
```

---

## Mode: PROFILE

Decide which section template to use. Skip if `SUMMARY-STATE.md` already has a
`**Profile:**` (preserved from previous run unless `--reset`).

If `--profile X` was passed (and not `auto`), use that. Otherwise auto-detect using
the scoring rules in `.aid/templates/knowledge-summary/section-templates/auto-detect.md`.

Output:
```
[PROFILE] Auto-detected: {profile} (score {N}, confidence: {high|medium|low})
          Signals: {brief list}
          Override: re-run with --profile X --reset
```

If confidence is **low** (top score within 1 of second), present the top 2
candidates and ask the user to choose.

Persist to `.aid/knowledge/SUMMARY-STATE.md`:
```
**Profile:** {chosen}
**Profile Source:** auto-detected | user-specified
**Profile Confidence:** {level}
```

---

## Mode: GENERATE

Follow the long-form agent prompt at
`.aid/templates/knowledge-summary/prompt.md`. The high-level steps are:

### 1. Load minimum grade

```
if --grade present:        MIN_GRADE = flag value
elif DISCOVERY-STATE.md has **Minimum Grade:**:  read it
else:                       MIN_GRADE = "A"
```
Persist to `SUMMARY-STATE.md`.

### 2. Fetch latest Mermaid

Run `.aid/templates/knowledge-summary/scripts/fetch-mermaid.sh`. It hits
`registry.npmjs.org/mermaid/latest`, compares to cache, downloads if stale, and
records version + sha256 in `.aid/knowledge/.cache/mermaid.min.js.meta`.

Records in SUMMARY-STATE.md:
```
**Mermaid Version:** {ver}
**Mermaid Fetched At:** {iso8601}
**Mermaid Cached:** .aid/knowledge/.cache/mermaid.min.js (sha256: {hash})
```

### 3. Read all KB documents

Read every `.aid/knowledge/*.md` listed in INDEX.md. Extract document purpose, key
facts, tables, and any embedded Mermaid blocks. The KB is **authoritative** — never
invent facts.

### 4. Plan diagrams

Per profile, produce 5–8 Mermaid diagrams. The active section template at
`.aid/templates/knowledge-summary/section-templates/{profile}.md` lists which
diagrams belong in which sections. For diagram syntax patterns and the common
pitfall table, see `.aid/templates/knowledge-summary/mermaid-examples.md`.

### 5. Build the HTML

Use `.aid/templates/knowledge-summary/html-skeleton.html` as the document shell.
Inline:
- CSS from `.aid/templates/knowledge-summary/component-css.css`
- JS from `.aid/templates/knowledge-summary/lightbox.js` (which already includes
  the Mermaid theme variable mapping)

Build via the part-concatenation pattern (see
`.aid/templates/knowledge-summary/scripts/concatenate.sh` or `.ps1`):

1. Generate `part1.html` (everything from `<!DOCTYPE>` up to opening `<script>`
   for Mermaid).
2. Cat `part1.html` + cached Mermaid + `part2.html` → final HTML.
3. Remove temp files.

### 6. Write SUMMARY-STATE.md

Initial fields per the schema below, then transition to VALIDATE.

```markdown
# Summary State

**Profile:** {profile}
**Profile Source:** {auto-detected | user-specified}
**Profile Confidence:** {high | medium | low}
**Theme:** default
**Minimum Grade:** {grade}
**Minimum Grade Source:** {DISCOVERY-STATE.md | --grade flag | default}
**Machine Grade:** Pending
**Human Grade:** Pending (run manual-checklist.sh before APPROVAL)
**Overall Grade:** Pending (= min of Machine and Human letter grades)
**User Approved:** no
**Last Run:** {iso8601}
**Trigger Reason:** {initial | stale-after-review-N | --reset | re-approval-only}
**Output:** .aid/knowledge/knowledge-summary.html
**Output Size:** {MB}
**Mermaid Version:** {ver}
**Mermaid Fetched At:** {iso8601}
**Last Reviewed KB Date:** {YYYY-MM-DD}
**Last Summary Date:** {YYYY-MM-DD or N/A}
**Writeback Status:** pending
```

---

## Mode: VALIDATE

Run `.aid/templates/knowledge-summary/scripts/grade.sh .aid/knowledge/knowledge-summary.html`.
It runs the AUTO_POOL (machine-verifiable) checks only:

1. **`scripts/validate-diagrams.mjs`** — D1 parse (`mermaid.parse()`; any failure =
   automatic F) + D2 render (jsdom or mmdc renders each block, asserts non-trivial
   SVG; `jsdom-fallback` noted if jsdom absent).
2. **`scripts/validate-links.sh`** — L1/L2 anchor + relative-md link integrity.
3. **`scripts/validate-html.sh`** — H1 (tidy → html-validate → regex cascade) +
   A1/A2/A4/A5; **A3 focus trap auto-detected** by grepping the inlined `lightbox.js`
   for `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
4. **`scripts/contrast-check.mjs`** — C1/C2 WCAG ratios for both themes.

It computes the **Machine Grade** from the AUTO_POOL + per-profile diagram-count
enforcement (reads `target_diagrams: N` from the active profile template; caps at
C+ if the HTML has fewer blocks). It does NOT compute a final Overall Grade — that
needs the Human Grade too.

Persist the Machine Grade + per-check table to SUMMARY-STATE.md under
`## Findings (last validation — Machine)`.

If Machine Grade ≥ minimum → MANUAL-CHECKLIST. Otherwise → FIX.

---

## Mode: MANUAL-CHECKLIST

The MANUAL_POOL (K1 KB-completeness, K2 fact-grounding, V1 human visual gate)
needs human judgment. **Agent-driven elicitation — not an interactive shell
prompt** (the skill runs in a host AI tool's chat; the agent gathers answers,
then writes the result file).

1. Run `scripts/spot-check-facts.sh` — writes `.aid/knowledge/.spot-check-facts.txt`
   (HTML claims grep-matched against source KB). Show the user any `MISS` lines.
2. Ask the user (the user must have opened the HTML in a browser first):
   - **K1 (10 pts):** does the HTML represent every populated KB doc? → Full(10) / Partial(5) / No(0).
   - **K2 (15 pts):** using the spot-check report, are the HTML's facts accurate? → Full(15) / Partial(8) / No(0).
   - **V1 — human visual gate (5 pts, MANDATORY):** opened in a real browser, confirm ALL of: every diagram renders (no error blocks); diagram + node text legible in BOTH light AND dark themes (incl. the EXPANDED lightbox view); theme toggle works; lightbox opens / Esc closes / Tab cycles. → Pass(5) / Fail(0). A V1 Fail forces Human Grade = F and blocks APPROVAL — no automated check covers diagram-internal legibility.
   - Free-text: anything else off (framing, depth, tone, missing content)?
3. Pass the answers to `manual-checklist.sh --k1 <y|p|n> --k2 <y|p|n> --v1 <y|n> --notes ".." --html <file>` (non-interactive mode; the script computes scores and writes `.aid/knowledge/.manual-checklist.json`). A contributor in a raw terminal can instead run `manual-checklist.sh --interactive`.
4. Re-run `grade.sh` — it reads `.manual-checklist.json`, computes the Human Grade
   (K1+K2+V1, 30 pts), and the Overall Grade = `min(Machine, Human)`. Persist all
   three to SUMMARY-STATE.md.

If Overall Grade ≥ minimum → APPROVAL. If V1 failed → mandatory: Human Grade is F;
go to FIX. Otherwise (Overall < minimum) → FIX.

---

## Mode: FIX

FIX routes failures by kind — do not treat them the same.

### Machine-pool failures — fix directly (objective; one correct fix)

For each failed AUTO_POOL check in `## Findings`:

- **D1 / D2 (diagrams)** — locate the failing block, apply the fix per the "Common
  failure patterns" table in `.aid/templates/knowledge-summary/mermaid-examples.md`.
- **L1 (anchor links)** — fix the `href` or add the missing `id`.
- **L2 (md links)** — correct the relative path.
- **H1 (HTML validity)** — fix the reported markup error.
- **A1–A5 (accessibility)** — see `.aid/templates/knowledge-summary/accessibility-checklist.md`.
- **C1 / C2 (contrast)** — adjust the offending color per `design-tokens.md`.

Edit ONLY the failing parts. Return to VALIDATE.

### Human-pool / subjective failures — expose → propose → ask (NEVER fix silently)

When a MANUAL_POOL item failed (K1/K2 partial-or-no) or the user left a free-text
complaint, there is no single objective fix — the user's judgment is the input. For
each such issue: **(1) expose** — restate it precisely, quoting the user's note and
naming the HTML section(s) involved; **(2) propose** — offer a concrete fix; **(3)
ask** — use the host's question mechanism for the user to approve the fix, give their
own, or accept it as won't-fix. Apply only what the user confirms. Then return to
VALIDATE → MANUAL-CHECKLIST for re-scoring.

---

## Mode: APPROVAL

**Pre-condition:** both Machine Grade and Human Grade must be computed and ≥ minimum.
If Human Grade is `Pending`, refuse APPROVAL — print: `❌ Cannot approve: Human Grade
not yet scored. Run /aid-summarize again to enter MANUAL-CHECKLIST.`

Print summary in the standard format:

```
✅ knowledge-summary.html ready for approval
   Path:           .aid/knowledge/knowledge-summary.html
   Size:           {MB}
   Profile:        {profile} (target_diagrams: {N})
   Machine Grade:  {grade} ({score}/73) — script-verified AUTO_POOL
   Human Grade:    {grade} ({score}/30) — manual-checklist MANUAL_POOL (K1+K2+V1)
   Overall Grade:  {min of above} (target: {min})
   Diagrams:       {N}/{target} valid (D1 + D2 both passed)
   Theme:          light + dark, both pass WCAG AA
   Mermaid:        {version}
   Trigger:        {reason}

Preview:  python -m http.server 8000   # then open
          http://localhost:8000/.aid/knowledge/knowledge-summary.html
   Or open the file directly in your browser.
```

Ask the user: `Approve this summary? [yes / no / changes-needed]`

- **yes** → write `**User Approved:** yes` + timestamp to SUMMARY-STATE.md, transition
  to WRITEBACK.
- **no** → write `**User Approved:** no`, exit. DISCOVERY-STATE.md is NOT updated.
- **changes-needed** → capture the user's notes in `## Pending Changes` of SUMMARY-STATE.md,
  transition to FIX.

---

## Mode: WRITEBACK

Run `.aid/templates/knowledge-summary/scripts/writeback-discovery-state.sh GRADE PROFILE MERMAID OUTPUT SIZE NOTES`.
It atomically:

1. Acquires a lock on DISCOVERY-STATE.md (5s timeout).
2. Locates `## Review History`. If `## Summarization History` doesn't exist,
   inserts it immediately after.
3. Appends a new row with date, grade, profile, mermaid version, output, notes.
4. Preserves everything else byte-identical.
5. Releases lock.

**Important rules** (encoded in the script, but worth knowing):
- **Do NOT modify `## Review History`** — that belongs to `/aid-discover`.
- **Do NOT modify the document header** (`**Grade:**`, `**Minimum Grade:**`,
  `**User Approved:**`).
- The header pertains to discovery, not summarization. Summarization tracks its own
  state separately.

On failure (lock contention, write error): mark `**Writeback Status:** failed` in
SUMMARY-STATE.md; instruct user to manually add the entry; do not retry automatically.

On success: print confirmation, transition to DONE.

```
✓ DISCOVERY-STATE.md updated:
    ## Summarization History → entry #N added (date, grade)
✓ SUMMARY-STATE.md → User Approved: yes

[State: DONE]
```

---

## Mode: DONE-IDEMPOTENT

When STALE-CHECK reports nothing to do:

```
✅ knowledge-summary.html is already up-to-date with the current KB.
   Last summary: {date} (grade {grade})
   Last KB review: {date}
   Nothing to do. Re-run with --reset to force regeneration.

[State: DONE]
```

Exit. SUMMARY-STATE.md and DISCOVERY-STATE.md are NOT modified.

---

## Quality Gate (the strict-syntax requirement)

Mermaid silently accepts invalid input and renders a red error block. **Every block
must be validated before declaring DONE.** Failure = automatic F.

The validator script (`.aid/templates/knowledge-summary/scripts/validate-diagrams.mjs`)
is required infrastructure. It runs D1 (parse) always; D2 (render) uses `jsdom` —
or falls back to `mmdc` — to render each diagram and assert a non-trivial SVG. If
neither `jsdom` nor `mmdc` is installed, D2 falls back to parse-only and the grade
output flags `D2: jsdom-fallback` (reduced rigor). Without Node.js entirely, this
skill cannot grade. If Node.js is unavailable on the host:
```
❌ Cannot run /aid-summarize.
   Node.js is required for Mermaid diagram validation.
   Install Node.js (>= 18) and re-run, or run the skill on a different machine.
```

There is no "skip validation" mode. The whole point of this skill is that broken
diagrams are caught before publication.

See `.aid/templates/knowledge-summary/grading-rubric.md` for the complete rubric and
grade boundaries.

---

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| Preflight aborts: "discovery not approved" | `/aid-discover` not yet at DONE | Run `/aid-discover` until APPROVAL and approve. |
| Preflight aborts: "no network" | Cannot reach npm registry | Check connection, or use `--cdn-mermaid`. |
| Preflight aborts: "templates folder missing" | `.aid/templates/knowledge-summary/` not installed | Re-run `/aid-init` to scaffold the templates. |
| VALIDATE fails: D1 (parse error) | Bad Mermaid syntax in diagram | Skill enters FIX automatically; uses pitfall table from `mermaid-examples.md`. |
| WRITEBACK fails: lock contention | `/aid-discover` running concurrently | Wait, retry; lock auto-releases. |
| WRITEBACK fails: write error | Disk full / permissions | Manually add entry to `## Summarization History`; mark `**Writeback Status:** ok` in SUMMARY-STATE.md. |
| Browser shows red diagram error block | Diagram passed parse but failed render (rare) | Open browser console, find Figure number, manually fix in HTML, re-run with `--reset`. |

---

## Notes

- **Idempotency.** Running `/aid-summarize` twice on an unchanged KB does nothing.
  Enforced by STALE-CHECK comparing dates.
- **Sole writer to `## Summarization History`.** This skill creates and appends
  to that section. `/aid-discover` does not touch it; the document header is
  also off-limits.
- **Skill = orchestrator, not asset owner.** The compositional assets (CSS, JS,
  HTML skeleton, palette, scripts) live in `.aid/templates/knowledge-summary/`
  and are installed by `/aid-init`. This skill describes the workflow and
  invokes those assets — it does not maintain them.
