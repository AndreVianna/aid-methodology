---
name: aid-summarize
description: >
  Generate a single-file knowledge-summary.html from .aid/knowledge/. Inlines Mermaid
  for offline diagrams, light/dark theme, click-to-expand lightbox, accessibility-first
  (WCAG AA). Includes a built-in quality gate that validates every Mermaid diagram
  parses and renders before granting any grade. Idempotent: re-running on an unchanged
  KB does nothing. State-machine: PREFLIGHT → STALE-CHECK → PROFILE → GENERATE →
  VALIDATE → FIX → APPROVAL → WRITEBACK → DONE.
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
    ├── validate-diagrams.mjs    # Mermaid parse + (optional) render via mmdc
    ├── validate-links.sh
    ├── validate-html.sh
    ├── contrast-check.mjs       # WCAG ratios for both themes
    ├── grade.sh                 # Orchestrator: runs all checks, emits grade
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
6. After VALIDATE: grade < minimum → FIX (loops back to VALIDATE); else → APPROVAL.
7. After APPROVAL: yes → WRITEBACK → DONE; no → exit; changes-needed → FIX.
```

Print the chosen mode at the start of each run: `[State: GENERATE]`, etc.

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
**Current Grade:** Pending
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
It orchestrates:

1. **`scripts/validate-diagrams.mjs`** — extracts every `<pre class="mermaid">` block
   and validates each via Mermaid. **Any failure = automatic F per the rubric.**
2. **`scripts/validate-links.sh`** — anchor + relative md link integrity.
3. **`scripts/validate-html.sh`** — structural / accessibility checks.
4. **`scripts/contrast-check.mjs`** — WCAG ratios for both themes.

Compares against the rubric in `.aid/templates/knowledge-summary/grading-rubric.md`.
Prints a per-check pass/fail table and the aggregate grade.

Persist `**Current Grade:** {grade}` and the per-check table in SUMMARY-STATE.md
under `## Findings (last validation)`.

If grade ≥ minimum → APPROVAL. Otherwise → FIX.

---

## Mode: FIX

Read `## Findings` in SUMMARY-STATE.md. For each failed check, look up the fix in
the relevant template:

- **D1 / D2 (diagrams)** — open the HTML, locate the failing block, identify the
  syntax error from the validator output, apply the fix per the "Common failure
  patterns" table in `.aid/templates/knowledge-summary/mermaid-examples.md`.
- **L1 (anchor links)** — fix the `href` or add the missing `id`.
- **L2 (md links)** — correct the relative path.
- **H1 (HTML validity)** — fix the reported markup error.
- **A1–A5 (accessibility)** — see `.aid/templates/knowledge-summary/accessibility-checklist.md`
  for landmark / ARIA / focus handling requirements.
- **C1 / C2 (contrast)** — adjust the offending color in the inlined CSS to meet
  ratio per `.aid/templates/knowledge-summary/design-tokens.md`.

Edit ONLY the failing parts; leave everything else untouched. Return to VALIDATE.

---

## Mode: APPROVAL

Print summary in the standard format:

```
✅ knowledge-summary.html generated
   Path:         .aid/knowledge/knowledge-summary.html
   Size:         {MB}
   Profile:      {profile} ({source})
   Grade:        {grade} (target: {min})
   Diagrams:     {N}/{N} valid
   Theme:        light + dark, both pass WCAG AA
   Mermaid:      {version}
   Trigger:      {reason}

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
is required infrastructure. Without it, this skill cannot grade. If Node.js is
unavailable on the host:
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
