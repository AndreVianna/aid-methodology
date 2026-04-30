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

## Pre-flight Checks

Run `.aid/templates/knowledge-summary/scripts/check-preflight.sh` before any state. It verifies:

1. `.aid/knowledge/DISCOVERY-STATE.md` exists.
2. `**User Approved:** yes` is present in DISCOVERY-STATE.md.
3. At least one populated KB document exists (`.aid/knowledge/*.md` with real content).
4. Not in Plan Mode (need write access).
5. Network reachable to `registry.npmjs.org` (skipped if `--cdn-mermaid`).

If any check fails, the script exits non-zero with a clear actionable message. Do NOT
proceed; do NOT create any state files.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Override the minimum acceptable grade. Format: `[A-F][-+]?`. Without this, reads `**Minimum Grade:**` from `DISCOVERY-STATE.md` (fallback `A`). Persists to `SUMMARY-STATE.md`. |
| `--profile X` | Force a specific profile. One of: `auto` (default), `web-app`, `library`, `cli`, `microservices`, `data-pipeline`. |
| `--theme palette=X` | Override color palette (e.g., `--theme palette=brand-acme`). Default uses the canonical palette in `.aid/templates/knowledge-summary/design-tokens.md`. |
| `--cdn-mermaid` | Load Mermaid from jsdelivr CDN at runtime instead of inlining (drops ~3 MB; loses offline support). |
| `--reset` | Force regeneration regardless of staleness check; clears `SUMMARY-STATE.md`. |

---

## State Detection

⚠️ **Filesystem is the only source of truth.** Always read actual files on disk.

The state-detection logic determines which mode this run executes:

```
1. PREFLIGHT (synchronous gate). Aborts on failure — no further state runs.

2. Read .aid/knowledge/SUMMARY-STATE.md (if it exists) and .aid/knowledge/DISCOVERY-STATE.md.

3. STALE-CHECK first (always):
   - Compare LAST_KB_CHANGE_DATE (latest entry in DISCOVERY-STATE ## Review History)
     vs LAST_SUMMARY_DATE (latest entry in DISCOVERY-STATE ## Summarization History,
     or the **Last Run** field in SUMMARY-STATE.md).
   - If --reset → mode = GENERATE (force).
   - If knowledge-summary.html missing → mode = GENERATE.
   - If ## Summarization History missing/empty → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE > LAST_SUMMARY_DATE → mode = GENERATE.
   - If LAST_KB_CHANGE_DATE <= LAST_SUMMARY_DATE AND HTML exists:
       AND SUMMARY-STATE.md says **User Approved:** yes → mode = DONE-IDEMPOTENT (exit cleanly)
       OTHERWISE → mode = APPROVAL (HTML is current; just need user sign-off)

4. If mode = GENERATE:
   - SUMMARY-STATE.md missing → run PROFILE first to detect/persist project type, then GENERATE.
   - SUMMARY-STATE.md present → reuse stored profile; go straight to GENERATE.

5. After GENERATE → VALIDATE.

6. After VALIDATE:
   - grade < minimum → FIX (loops back to VALIDATE).
   - grade >= minimum → APPROVAL.

7. After APPROVAL:
   - User says yes → WRITEBACK → DONE.
   - User says no → exit (no writeback; user can fix or --reset).
   - User says changes-needed → record + transition to FIX.
```

Print the chosen mode at the start of each run: `[State: PROFILE]`, `[State: GENERATE]`, etc.

---

## Mode: STALE-CHECK

Run `.aid/templates/knowledge-summary/scripts/stale-check.sh`. It outputs one of:

- `STALE` — KB is newer than last summary (or first run). Continue to PROFILE/GENERATE.
- `CURRENT_APPROVED` — HTML is up-to-date and approved. Print:
  ```
  ✅ knowledge-summary.html is already up-to-date with the current KB. Nothing to do.
  ```
  Exit cleanly.
- `CURRENT_UNAPPROVED` — HTML is up-to-date but not yet approved. Print:
  ```
  ℹ️  HTML is current with KB but pending your approval.
  ```
  Skip to APPROVAL.

If STALE: tell the user *why* it's stale:
```
ℹ️  KB was reviewed on {LAST_KB_CHANGE_DATE}, last summary was {LAST_SUMMARY_DATE}.
   Regenerating to match latest KB...
```

---

## Mode: PROFILE

Decide which section template to use. Skip if `SUMMARY-STATE.md` already has a
`**Profile:**` entry (preserved from previous run unless `--reset`).

If `--profile X` was passed (and X is not `auto`), use that. Otherwise auto-detect:

Read `.aid/knowledge/`:
- `ui-architecture.md` — non-empty?
- `api-contracts.md` — REST/GraphQL? exported symbols? subcommands?
- `module-map.md` — count of services? single executable?
- `infrastructure.md` — CLI? deployment manifests? Airflow/dbt?
- `integration-map.md` — inbound HTTP? inter-service? ETL/transforms?

Apply the scoring rules in `.aid/templates/knowledge-summary/section-templates/auto-detect.md` to pick a profile.

Output to user:
```
[PROFILE] Auto-detected: {profile} (score {N}, confidence: {high|medium|low})
          Signals: {brief list}
          Override: re-run with --profile X --reset
```

If confidence is `low` (top score within 1 of second), present the top 2 candidates
and ask the user to choose using the `AskUserQuestion` tool.

Persist:
```
**Profile:** {chosen}
**Profile Source:** auto-detected | user-specified
**Profile Confidence:** {level}
```
to `.aid/knowledge/SUMMARY-STATE.md`.

---

## Mode: GENERATE

This is the bulk of the work. Steps:

### 1. Load minimum grade

```
if --grade present: MIN_GRADE = flag value
elif DISCOVERY-STATE.md has **Minimum Grade:**: read it
else: MIN_GRADE = "A"
```

Persist to `SUMMARY-STATE.md`.

### 2. Fetch Mermaid (latest)

Run `.aid/templates/knowledge-summary/scripts/fetch-mermaid.sh`. It:
1. Calls `https://registry.npmjs.org/mermaid/latest` to discover current version.
2. Compares to cached version at `.aid/knowledge/.cache/mermaid.min.js.meta`.
3. If stale or missing, downloads `https://cdn.jsdelivr.net/npm/mermaid@{ver}/dist/mermaid.min.js`.
4. Writes meta file with version + timestamp + sha256.

Records in SUMMARY-STATE.md:
```
**Mermaid Version:** {ver}
**Mermaid Fetched At:** {iso8601}
**Mermaid Cached:** .aid/knowledge/.cache/mermaid.min.js (sha256: {hash})
```

### 3. Read all KB documents

Read every `.aid/knowledge/*.md` listed in INDEX.md. For each, extract:
- Document purpose (first paragraph after H1)
- Key facts (numbers, names, version pins)
- Diagrams worth promoting (look for ASCII art, mermaid blocks, or strong structural lists)

The KB is **authoritative**. Do not re-grade it, re-validate it, or contradict it.
If the KB says X, the HTML says X.

### 4. Build the HTML

Use `.aid/templates/knowledge-summary/html-skeleton.html` as the document shell. Inject:
- Hero with project name (read from DISCOVERY-STATE.md or `pom.xml` / `package.json` etc.)
- Section structure from `.aid/templates/knowledge-summary/section-templates/{profile}.md`
- Per-section content drawn from KB (cite source via relative `./xxx.md` link)
- 6–8 Mermaid diagrams using syntax patterns from `.aid/templates/knowledge-summary/mermaid-examples.md`
- Inlined CSS from `.aid/templates/knowledge-summary/component-css.css`
- Inlined JS from `.aid/templates/knowledge-summary/lightbox.js` and `.aid/templates/knowledge-summary/mermaid-init.js`
- Inlined Mermaid library from cached file

Build via the part-concatenation pattern (see `.aid/templates/knowledge-summary/scripts/concatenate.sh` or `.ps1`):
1. Generate `part1.html` (everything from `<!DOCTYPE>` up to the opening `<script>` for Mermaid).
2. Cat `part1.html` + cached Mermaid + `part2.html` → final `knowledge-summary.html`.
3. Remove temp files.

**Critical pitfalls — see `.aid/templates/knowledge-summary/mermaid-examples.md` for full list:**
- Never put `<word>` HTML-tag-like tokens in Mermaid labels (use `{word}` instead).
- Use `-. text .->` (with spaces) for dotted-arrow labels, not `-.text.->`.
- Lightbox SVG sizing: chrome on wrapper, SVG fills 100%/100%.
- Use `el.textContent` not `el.innerHTML` when restoring diagram source.

### 5. Write SUMMARY-STATE.md

Initial fields:
```markdown
# Summary State

**Profile:** {profile}
**Profile Source:** {source}
**Profile Confidence:** {level}
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
**Mermaid Cached:** {path} (sha256: {hash})
**Last Reviewed KB Date:** {YYYY-MM-DD}
**Last Summary Date:** {YYYY-MM-DD or N/A}
**Writeback Status:** pending
```

Print: `[State: GENERATE → VALIDATE]`

---

## Mode: VALIDATE

Run `.aid/templates/knowledge-summary/scripts/grade.sh .aid/knowledge/knowledge-summary.html`. It orchestrates:

1. **`.aid/templates/knowledge-summary/scripts/validate-diagrams.mjs`** — extracts every `<pre class="mermaid">` block,
   parses each via `mermaid.parse()`. **Any failure = automatic F.**
2. **`.aid/templates/knowledge-summary/scripts/validate-links.sh`** — verifies all `href="#X"` resolve to in-page IDs and
   all `./*.md` link targets exist in `.aid/knowledge/`.
3. **`.aid/templates/knowledge-summary/scripts/validate-html.sh`** — runs `tidy` (or `html-validate`) for syntax errors.
4. **`.aid/templates/knowledge-summary/scripts/contrast-check.mjs`** — computes WCAG ratios for both themes from the
   inlined CSS variables.
5. Compares against the rubric in `.aid/templates/knowledge-summary/grading-rubric.md`. Prints a per-check
   pass/fail table and the aggregate grade.

Persist `**Current Grade:** {grade}` and the per-check table in SUMMARY-STATE.md
under `## Findings (last validation)`.

If grade ≥ minimum → APPROVAL. Otherwise → FIX.

---

## Mode: FIX

Read `## Findings` in SUMMARY-STATE.md. For each failed check:
- **D1 / D2 (diagrams)** — open the HTML, locate the failing `<pre.mermaid>` block,
  identify the syntax error from the validator output, apply the fix per
  `.aid/templates/knowledge-summary/mermaid-examples.md` "Common failure patterns" table.
- **L1 (anchor links)** — fix the `href` or add the missing `id`.
- **L2 (md links)** — correct the relative path.
- **H1 (HTML validity)** — fix the reported markup error.
- **A1–A5 (accessibility)** — add the missing landmark / ARIA / focus handling.
- **C1 / C2 (contrast)** — adjust the offending color in the inlined CSS to meet ratio.

Edit ONLY the failing parts; leave everything else untouched.

After all fixes applied, return to VALIDATE.

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

Use `AskUserQuestion` to ask:
> Approve this summary?
> - **Approve** — record approval and update DISCOVERY-STATE.md
> - **Reject** — exit without recording
> - **Changes needed** — describe what to change, transition to FIX

On approval: write `**User Approved:** yes` + timestamp to SUMMARY-STATE.md, transition
to WRITEBACK.

On rejection: write `**User Approved:** no`, exit. DISCOVERY-STATE.md is NOT updated.

On changes-needed: capture the user's notes in `## Pending Changes` of SUMMARY-STATE.md,
transition to FIX.

---

## Mode: WRITEBACK

Run `.aid/templates/knowledge-summary/scripts/writeback-discovery-state.sh`. It atomically:

1. Acquires `.aid/knowledge/.discovery-state.lock` (file rename sentinel, 5s timeout).
2. Reads `DISCOVERY-STATE.md`.
3. Locates `## Review History`. If `## Summarization History` does not exist, inserts
   it immediately after the Review History table.
4. Computes next `#` (last entry + 1, or 1 if first).
5. Appends a new row:
   - **#:** {next}
   - **Date:** {YYYY-MM-DD}
   - **Grade:** {final}
   - **Profile:** {profile}
   - **Mermaid:** {version}
   - **Output:** `knowledge-summary.html ({size})`
   - **Notes:** {one-liner — "Initial generation" or "Regenerated after KB review cycle N (date)"}
6. Writes back, preserving everything else byte-for-byte.
7. Releases lock.

On failure (lock timeout, write error): mark `**Writeback Status:** failed` in
SUMMARY-STATE.md, instruct the user to manually add the entry, exit non-zero.

On success: mark `**Writeback Status:** ok`, transition to DONE.

---

## Mode: DONE

Print:
```
✓ DISCOVERY-STATE.md updated:
    ## Summarization History → entry #{N} added ({date}, grade {grade})
✓ SUMMARY-STATE.md → User Approved: yes

[State: DONE]

Open .aid/knowledge/knowledge-summary.html in a browser to view the summary.
```

Exit with success.

---

## Mode: DONE-IDEMPOTENT (when STALE-CHECK says nothing to do)

Print:
```
✅ knowledge-summary.html is already up-to-date with the current KB.
   Last summary: {date} (grade {grade})
   Last KB review: {date}
   Nothing to do. Re-run with --reset to force regeneration.

[State: DONE]
```

Exit with success. SUMMARY-STATE.md and DISCOVERY-STATE.md are NOT modified.

---

## Quality Gate (the strict-syntax requirement)

Mermaid silently accepts invalid input and renders a red error block. The skill MUST
catch every such failure before declaring DONE. The grading rubric makes diagram
parse failure (`D1`) an automatic F.

The validator script (`validate-diagrams.mjs`) is required infrastructure. Without it,
this skill cannot grade. If Node.js is unavailable on the host:
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
- `.aid/templates/knowledge-summary/grading-rubric.md` — A–F rubric with concrete checks
- `.aid/templates/knowledge-summary/html-skeleton.html` — doctype, head, semantic landmarks, noscript

---

## Failure modes and recovery

| Symptom | Cause | Recovery |
|---|---|---|
| Preflight aborts: "discovery not approved" | `/aid-discover` not yet at DONE | Run `/aid-discover` until it reaches APPROVAL and approve. |
| Preflight aborts: "no network" | Cannot reach npm registry | Check connection, or use `--cdn-mermaid`. |
| Validate fails: D1 (parse error) | Bad Mermaid syntax in generated diagram | Skill enters FIX automatically; if it loops, manually inspect the failing block. |
| Writeback fails: lock contention | `/aid-discover` running concurrently | Wait, retry; the lock auto-releases. |
| Writeback fails: write error | Disk full / permissions | Manually add the entry to `## Summarization History`; mark `**Writeback Status:** ok` in SUMMARY-STATE.md. |
| Browser shows red diagram error block | A diagram somehow passed parse but failed render (rare) | Open browser console, find the offending Figure number, manually fix in HTML, re-run with `--reset`. |
