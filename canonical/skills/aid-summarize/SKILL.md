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

## Pre-flight Checks

Run `.aid/templates/knowledge-summary/scripts/check-preflight.sh` before any state. It verifies:

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
| `--grade X` | Override the minimum acceptable grade. Format: `[A-F][-+]?`. Without this, reads `**Minimum Grade:**` from `.aid/knowledge/STATE.md` (fallback `A`). Persists to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`. |
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

Decide which section template to use. Skip if `.aid/knowledge/STATE.md` `## Knowledge Summary Status` already has a
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
to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`.

---

## Mode: GENERATE

This is the bulk of the work. Steps:

### 1. Load minimum grade

```
if --grade present: MIN_GRADE = flag value
elif .aid/knowledge/STATE.md has **Minimum Grade:**: read it
else: MIN_GRADE = "A"
```

Persist to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`.

### 2. Fetch Mermaid (latest)

Run `.aid/templates/knowledge-summary/scripts/fetch-mermaid.sh`. It:
1. Calls `https://registry.npmjs.org/mermaid/latest` to discover current version.
2. Compares to cached version at `.aid/knowledge/.cache/mermaid.min.js.meta`.
3. If stale or missing, downloads `https://cdn.jsdelivr.net/npm/mermaid@{ver}/dist/mermaid.min.js`.
4. Writes meta file with version + timestamp + sha256.

Records in `.aid/knowledge/STATE.md` `## Knowledge Summary Status`:
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
- Hero with project name (read from `.aid/knowledge/STATE.md` or `pom.xml` / `package.json` etc.)
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

### 5. Write Knowledge Summary Status

Write initial fields to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`:
```markdown
**Profile:** {profile}
**Profile Source:** {source}
**Profile Confidence:** {level}
**Theme:** default
**Minimum Grade:** {grade}
**Minimum Grade Source:** {.aid/knowledge/STATE.md | --grade flag | default}
**Machine Grade:** Pending
**Machine Grade Source:** `grade.sh` AUTO_POOL (68 pts)
**Human Grade:** Pending (run `manual-checklist.sh` before APPROVAL)
**Human Grade Source:** `manual-checklist.sh` MANUAL_POOL (K1+K2+V1, 30 pts)
**Overall Grade:** Pending (= min of Machine and Human letter grades)
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

---

## Mode: VALIDATE

▶ validate-diagrams.mjs starting (~30 s)
▶ validate-links.sh starting (~30 s)
▶ validate-html.sh starting (~30 s)
▶ contrast-check.mjs starting (~30 s)

Run `.aid/templates/knowledge-summary/scripts/grade.sh .aid/knowledge/knowledge-summary.html`. It orchestrates the AUTO_POOL (machine-verifiable) checks only:

1. **`.aid/templates/knowledge-summary/scripts/validate-diagrams.mjs`** — D1: extracts every `<pre class="mermaid">` block, parses each via `mermaid.parse()`. **Any failure = automatic F.** D2: renders each block via `jsdom` + Mermaid and asserts the SVG is non-trivial (>500 bytes, contains `<g>` or `<path>`, no `mermaid-error` marker). If `jsdom` is unavailable, D2 falls back to parse-only and the output flags `D2: jsdom-fallback`.
2. **`.aid/templates/knowledge-summary/scripts/validate-links.sh`** — L1/L2: anchor and `./*.md` link integrity.
3. **`.aid/templates/knowledge-summary/scripts/validate-html.sh`** — H1 (tidy → html-validate → regex cascade — script picks the most rigorous tool available and prints which). A1/A2/A4/A5 (semantic landmarks, lightbox ARIA, reduced-motion, focus-visible). **A3 (focus trap)** is now auto-detected via `grep` of the inlined `lightbox.js` for the markers `trapFocusOnTab`, `lastFocused.focus()`, `key === 'Escape'`.
4. **`.aid/templates/knowledge-summary/scripts/contrast-check.mjs`** — C1/C2: WCAG ratios for both themes.
5. Computes the Machine Grade from the AUTO_POOL tally + per-profile diagram-count enforcement (reads `target_diagrams: N` from the active profile template; caps at C+ if `actual < target`). **Does NOT compute a final Overall Grade** — that requires Human Grade too.

✓ validation scripts done (record actual time) — or ✗ failed: {reason}

Persist Machine Grade + per-check table to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation — Machine)`.

If Machine Grade ≥ minimum → MANUAL-CHECKLIST. Otherwise → FIX.

---

## Mode: MANUAL-CHECKLIST

The MANUAL_POOL (K1 KB-completeness, K2 fact-grounding) needs human judgment — the script cannot verify it. **This is agent-driven elicitation, not an interactive shell script** (the skill runs inside a host AI tool's chat — the agent gathers the answers, then writes the result file the scoring script consumes).

### Step 1 — generate the fact spot-check report (helps the user answer K2)

Run `.aid/templates/knowledge-summary/scripts/spot-check-facts.sh`. It extracts numeric/named claims from the HTML, greps the source KB, and writes `.aid/knowledge/.spot-check-facts.txt` (each line: `[OK|MISS] HTML-claim | KB-evidence`). Show the user the `MISS` lines, if any.

### Step 2 — elicit the human-judgment answers via `AskUserQuestion`

Ask the user (use `AskUserQuestion`; the user must have actually opened the HTML in a browser first — say so):

- **K1 — KB completeness (10 pts):** "Open the generated HTML. Does it represent every populated KB doc you care about?" → Full (10) / Partial (5) / No (0).
- **K2 — facts grounded (15 pts):** "Using the spot-check report above, are the HTML's numeric/named facts accurate against the source KB?" → Full (15) / Partial (8) / No (0).
- **V1 — human visual gate (5 pts, MANDATORY):** "Open the HTML in a real browser. Confirm ALL of: (a) every diagram renders, no error blocks; (b) diagram + node text is legible in BOTH light AND dark themes — including the EXPANDED lightbox view; (c) theme toggle works; (d) lightbox opens / Esc closes / Tab cycles." → Pass (5) / Fail (0). **V1 is a gate: a Fail forces Human Grade = F and blocks APPROVAL.** No automated check covers diagram-internal legibility — this is the only safeguard.
- **Free-text:** "Anything else off — framing, depth, tone, missing content?" — capture verbatim.

### Step 3 — write the result file

The agent passes the answers to `manual-checklist.sh` (non-interactive mode — it computes the scores and writes the JSON, so the script stays the single source of truth for scoring):
```
bash .aid/templates/knowledge-summary/scripts/manual-checklist.sh \
  --k1 <y|p|n> --k2 <y|p|n> --v1 <y|n> --notes "..." --html .aid/knowledge/knowledge-summary.html
```
This writes `.aid/knowledge/.manual-checklist.json` with `K1_score`, `K2_score`, `V1_score`, the answers, notes, and timestamp. (A contributor in a raw terminal can instead run `manual-checklist.sh --interactive`.)

### Step 4 — score and route

Re-run `grade.sh` — it reads `.manual-checklist.json`, computes the Human Grade from MANUAL_POOL (K1+K2+V1, 30 pts), and the Overall Grade = `min(Machine_letter, Human_letter)`. Persist Machine + Human + Overall Grade to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation)`.

- Overall Grade ≥ minimum → APPROVAL.
- **V1 failed → mandatory: Human Grade is forced to F.** Go to FIX; the visual defect must be fixed and V1 re-confirmed before APPROVAL.
- Overall Grade < minimum → FIX. **If the shortfall is in MANUAL_POOL** (K1/K2 partial-or-no, or V1 fail) or the free-text notes flagged something, FIX uses the **expose → propose → ask** loop (see Mode: FIX, "Human-pool / subjective failures") — never silent guess-fixing.

---

## Mode: FIX

FIX handles two fundamentally different kinds of failure. **Route each failure by kind** — do not treat them the same.

### Machine-pool failures — fix directly (objective; one correct fix)

Read `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation — Machine)`. For each failed AUTO_POOL check there is exactly one correct repair — apply it autonomously:

- **D1 (diagram parse)** — locate the failing `<pre.mermaid>` block, identify the syntax error from the validator output, apply the fix per `.aid/templates/knowledge-summary/mermaid-examples.md` "Common failure patterns" table.
- **D2 (diagram render)** — the block parses but renders trivially / as an error SVG; inspect the jsdom render output, fix the structural issue (often an empty subgraph or an unreachable node).
- **L1 (anchor links)** — fix the `href` or add the missing `id`.
- **L2 (md links)** — correct the relative path.
- **H1 (HTML validity)** — fix the reported markup error (from tidy / html-validate / regex, whichever ran).
- **A1, A2, A3, A4, A5 (accessibility)** — add the missing landmark / ARIA attribute / focus-trap marker / reduced-motion block / focus-visible rule.
- **C1 / C2 (contrast)** — adjust the offending color in the inlined CSS to meet the ratio.

Edit ONLY the failing parts; leave everything else untouched. After all machine-pool fixes are applied, return to VALIDATE.

### Human-pool / subjective failures — expose → propose → ask (NEVER fix silently)

When a MANUAL_POOL item failed (K1 partial/no, K2 partial/no) or the user left a free-text complaint in `## Manual Notes`, there is **no single objective fix** — the user flagged it because their judgment is the input. Do NOT guess-and-apply. Instead, for each such issue, run the **expose → propose → ask** loop:

1. **Expose** — restate the issue precisely. Quote the user's note or the failing checklist item. Name the specific HTML section(s) or claim(s) involved. Example: *"K1 scored partial — your note says the Data Model section only lists artifact names without the per-artifact schemas that `data-model.md` actually contains."*
2. **Propose** — offer a concrete, specific fix. Example: *"Proposed: expand §5 Data Model to include the field-level schema table for each of the 15 artifacts, pulled from `data-model.md §2.1-§2.15`. Adds ~40 lines."*
3. **Ask** — use `AskUserQuestion` to ask the user to (a) approve the proposed fix, (b) provide their own fix / direction, or (c) mark the issue as won't-fix (accept the lower score). Wait for the answer before editing.

Apply only what the user confirms. Capture the resolution in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Manual Notes`. After all human-pool issues are resolved (or accepted as won't-fix), return to VALIDATE → MANUAL-CHECKLIST so the user can re-score.

**Rationale:** machine-detected issues have one objective fix; human-detected / subjective issues do not — applying the agent's guess silently risks solving the wrong problem or overwriting the user's intent. The user is the judgment input; collaboration produces the right outcome.

---

## Mode: APPROVAL

**Pre-condition:** Both Machine Grade AND Human Grade must already be computed and ≥ minimum. If Human Grade is `Pending`, refuse to enter APPROVAL — print: `❌ Cannot approve: Human Grade not yet scored. Run /aid-summarize again to enter MANUAL-CHECKLIST.`

Print summary in the standard format:

```
✅ knowledge-summary.html ready for approval
   Path:           .aid/knowledge/knowledge-summary.html
   Size:           {MB}
   Profile:        {profile} (target_diagrams: {N})
   Machine Grade:  {grade} ({score}/68) — script-verified AUTO_POOL
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

Use `AskUserQuestion` to ask:
> Approve this summary?
> - **Approve** — record approval and update `.aid/knowledge/STATE.md` `## Summarization History`
> - **Reject** — exit without recording
> - **Changes needed** — describe what to change, transition to FIX

On approval: write `**User Approved:** yes` + timestamp to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`, transition to WRITEBACK.

On rejection: write `**User Approved:** no` to `## Knowledge Summary Status`, exit. `## Summarization History` is NOT updated.

On changes-needed: capture the user's notes in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Pending Changes`, transition to FIX.

---

## Mode: WRITEBACK

▶ writeback-state.sh starting (~5 s)
Run `.aid/templates/knowledge-summary/scripts/writeback-state.sh`. It atomically:

1. Acquires `.aid/knowledge/.state.lock` (file rename sentinel, 5s timeout).
2. Reads `.aid/knowledge/STATE.md`.
3. Locates `## Review History`. If `## Summarization History` does not exist, inserts
   it immediately after the Review History table.
4. Computes next `#` (last entry + 1, or 1 if first).
5. Appends a new row to `## Summarization History`:
   - **#:** {next}
   - **Date:** {YYYY-MM-DD}
   - **Grade:** {final}
   - **Profile:** {profile}
   - **Mermaid:** {version}
   - **Output:** `knowledge-summary.html ({size})`
   - **Notes:** {one-liner — "Initial generation" or "Regenerated after KB review cycle N (date)"}
6. Writes back, preserving everything else byte-for-byte.
7. Releases lock.

✓ writeback done (record actual time) — or ✗ writeback failed: {reason}
On failure (lock timeout, write error): mark `**Writeback Status:** failed` in
`.aid/knowledge/STATE.md` `## Knowledge Summary Status`, instruct the user to manually add the entry, exit non-zero.

On success: mark `**Writeback Status:** ok` in `## Knowledge Summary Status`, transition to DONE.

---

## Mode: DONE

Print:
```
✓ .aid/knowledge/STATE.md updated:
    ## Summarization History → entry #{N} added ({date}, grade {grade})
✓ ## Knowledge Summary Status → User Approved: yes

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

Exit with success. `.aid/knowledge/STATE.md` `## Knowledge Summary Status` and `## Summarization History` are NOT modified.

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
- `.aid/templates/knowledge-summary/scripts/grade.sh` — orchestrates AUTO_POOL checks, reads `.manual-checklist.json` for MANUAL_POOL, prints Machine + Human + Overall grades
- `.aid/templates/knowledge-summary/scripts/manual-checklist.sh` — validates / scores the MANUAL_POOL result file (`--input PATH` headless mode; `--interactive` for raw-terminal use)
- `.aid/templates/knowledge-summary/scripts/spot-check-facts.sh` — extracts HTML claims, grep-matches against source KB, writes `.spot-check-facts.txt` (aids the user's K2 judgment)

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
