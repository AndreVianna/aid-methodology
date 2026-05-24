---
name: aid-discover
description: >
  Brownfield project discovery with built-in quality gate. Run `/aid-init` first to scaffold
  the KB. Analyzes all repository content (code, configuration, and documentation) to populate
  KB documents. Reviews, collects user input, fixes issues, and gets user approval — one step
  per run. State-machine: GENERATE → REVIEW → Q&A → FIX → APPROVAL → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart"
---

# Brownfield Project Discovery

Analyze an existing project repository — all code, configuration, and documentation — and
produce a structured `.aid/knowledge/` directory by orchestrating 5 specialized discovery subagents.
Includes a built-in quality gate that reviews, grades, and fixes KB documents.

**State machine — each `/aid-discover` run does ONE step and exits.**

## ⚠️ Pre-flight Checks

Run `scripts/check-preflight.sh .aid/knowledge/` to verify:
1. `.aid/knowledge/STATE.md` exists (init has run)
2. Not in Plan Mode (subagents need write access)

If Check 1 fails: `⚠️ Knowledge Base not initialized. Run /aid-init first to set up the project.` — Exit.
If Check 2 fails: Tell user to press `Shift+Tab` to exit Plan Mode, then re-run.

> **State machine for this skill:**
> ```
> aid-discover  ▸ one step per run
>   [ GENERATE ] → [ REVIEW ] → [ Q&A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
> ```
> Each run detects which state to enter from disk and does exactly that step.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Set minimum acceptable grade. Format: `[A-F][-+]?` (e.g., A, A-, B+). Default: `A`. Persists in `.aid/knowledge/STATE.md`. |
| `--reset` | Clear entire `.aid/knowledge/` directory and restart from scratch. |

**Grade persistence:** Saved to `.aid/knowledge/STATE.md` on first run. `--grade` updates it; omitting it reads the stored value.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs. ALWAYS read actual files on disk.

Read the filesystem to determine which mode to enter:

```
State 1: Missing or empty KB docs                     → GENERATE mode
State 2: All docs populated, no GRADE file             → REVIEW mode
State 3: GRADE file, (grade < min AND has Pending Q&A)
         OR has Pending Q&A with Impact: Required       → Q&A mode
State 4: GRADE file, grade < min, no Pending Q&A       → FIX mode
State 5: GRADE file, grade >= min, not user-approved    → APPROVAL mode
State 6: GRADE file, grade >= min, user-approved        → DONE
```

**Detection logic:**

1. Check `.aid/knowledge/` for the 16 expected documents:
   `project-structure.md`, `external-sources.md`, `architecture.md`, `technology-stack.md`,
   `module-map.md`, `coding-standards.md`, `data-model.md`, `api-contracts.md`,
   `integration-map.md`, `domain-glossary.md`, `test-landscape.md`, `security-model.md`,
   `tech-debt.md`, `infrastructure.md`, `ui-architecture.md`, `feature-inventory.md`
2. A document is "populated" only if it contains real content (files with only `❌ Pending` = missing). If any are missing → **GENERATE**
3. If all 16 populated and `.aid/knowledge/STATE.md` has `**Grade:** Pending` or `Not Started` → **REVIEW**
4. If all 16 populated but no `.aid/knowledge/STATE.md` → **REVIEW** (legacy)
5. If `.aid/knowledge/STATE.md` exists with a grade:
   - Read current/minimum grade; if `--grade` provided, update minimum
   - Read `## Q&A (Pending)` section of `.aid/knowledge/STATE.md` for `**Status:** Pending` entries
   - If any Pending with `**Impact:** Required` → **Q&A** (regardless of grade)
   - If grade < minimum: Pending entries → **Q&A**; no Pending → **FIX**
   - If grade >= minimum and no Required Pending Q&A:
     - `**User Approved:** yes` → **DONE**; otherwise → **APPROVAL**

**Grade ordering** (highest to lowest):
`A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F`

Print the state-entry line with description, then the "you are here" state-map. Use one of these depending on the detected state:

**GENERATE:**
```
[State: GENERATE] — Populate missing KB documents by orchestrating parallel discovery sub-agents.
aid-discover  ▸ you are here
  [● GENERATE ] → [ REVIEW ] → [ Q&A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**REVIEW:**
```
[State: REVIEW] — Grade all KB documents for accuracy, completeness, and evidence quality.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [● REVIEW ] → [ Q&A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**Q&A:**
```
[State: Q&A] — Resolve pending questions with the user before attempting automated fixes.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [● Q&A ] → [ FIX ] → [ APPROVAL ] → [ DONE ]
```

**FIX:**
```
[State: FIX] — Apply Q&A answers and reviewer feedback to bring KB documents up to minimum grade.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q&A ] → [● FIX ] → [ APPROVAL ] → [ DONE ]
```

**APPROVAL:**
```
[State: APPROVAL] — KB meets minimum grade; ask the user to confirm it is ready for Interview.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q&A ] → [✓ FIX ] → [● APPROVAL ] → [ DONE ]
```

**DONE:**
```
[State: DONE] — Discovery is complete and user-approved; KB is ready for Interview.
aid-discover  ▸ you are here
  [✓ GENERATE ] → [✓ REVIEW ] → [✓ Q&A ] → [✓ FIX ] → [✓ APPROVAL ] → [● DONE ]
```

---

## Mode: GENERATE

Generate KB documents that are missing or still at "Pending" status.

### Step 0: Check Existing KB

Scan `.aid/knowledge/` — files with only init template (`❌ Pending`) are treated as MISSING.
Print: `[0/16] Checking existing KB...`
If ALL 16 have real content and no `--reset`, skip to Step 6.

### Step 0b: Read External Documentation Paths

Read `.aid/knowledge/STATE.md` `## External Documentation` for paths from `aid-init`. Verify accessible:
```bash
test -r <path> && echo "✅ $path" || echo "❌ $path — no longer accessible"
```
Store accessible paths for the scout prompt. Warn on inaccessible (but continue).

### Step 0c: Build Project Index (Pre-pass)

Run the lightweight file-index pre-pass before dispatching sub-agents. This produces a structured inventory consumed by all 5 sub-agents, eliminating duplicated `find`/`wc` work across parallel agents.

> **Working directory assumption:** All bash commands in this skill (Step 0c, Step 1, etc.) assume the current working directory is the project root (the directory containing `.aid/`). Relative paths like `../../templates/scripts/...` resolve from that root. Verify with `pwd` if unsure.

▶ build-project-index starting (~30 s)
```bash
bash ../../templates/scripts/build-project-index.sh \
  --root . \
  --output .aid/knowledge/project-index.md
```
✓ build-project-index done (record actual time)

Print: `[0c] Building project index...` then on completion `[0c] Project index ready (N files, M lines)`.

This is a deterministic shell script — no LLM dispatch. It runs fast (typically under 30 seconds even on large repos). The resulting `project-index.md` is markdown so humans can scan it.

If the index fails (e.g., empty repo, permission errors): log a warning and continue. Sub-agents will fall back to direct enumeration.

#
---

## Dispatch Protocol (L1+L2+L3 subagent visibility, subagent-visibility-patch)

Every subagent dispatch in this skill MUST follow this protocol so the user
sees mid-wait progress instead of going silent for 10–25+ minutes. The full
protocol lives in two reference docs; this section is a checklist citing them.

**Before each dispatch:**

1. **Look up ETA** in `canonical/templates/rough-time-hints.md` for the
   subagent's operation class. Capture LOW–HIGH band.
2. **Read heartbeat config** from `.aid/knowledge/STATE.md` top-of-file
   `**Heartbeat Interval:** N minutes` (default 1; `0` = disabled).
3. **If ETA LOW > 5 min AND heartbeat enabled:**
   - Pre-create `.aid/.heartbeat/<agent-name>-<unix-ts>.txt`
   - Include `HEARTBEAT_FILE=<path>` + `HEARTBEAT_INTERVAL=Nm` in dispatch prompt
4. **Arm 3 L2 timers** (via `run_in_background: true`):
   - `sleep <LOW/2 in s> && echo "... <agent> still running (Xm elapsed of ~LOW–HIGH)"`
   - `sleep <LOW in s> && echo "... <agent> at estimated time (LOWm elapsed)"`
   - `sleep <1.5×LOW in s> && echo "⚠️ <agent> EXCEEDED estimate (1.5×LOWm elapsed); consider checking on it or cancelling"`

**During dispatch:**

- **On L2 timer fire:** surface the timer output. If heartbeat file exists,
  also read it and append `[from heartbeat] state: <state> · progress: <progress>
  · activity: <activity>` to the narration.

**On completion / failure:**

- **Success:** emit `✓ <agent> done in <actual>` with measured time. Log to
  `STATE.md ## Calibration Log` for L1 calibration. Delete heartbeat file.
- **Failure:** emit `✗ <agent> FAILED after <elapsed> (reason: <one-line>)`.
  Decide whether to re-dispatch, fall back, or surface to user. Delete
  heartbeat file.

**References:**

- `canonical/templates/long-wait-protocol.md` — full L2 spec
- `canonical/templates/subagent-heartbeat-protocol.md` — full L3 spec
- `canonical/templates/rough-time-hints.md` — current measured ETAs
- `canonical/agents/*/AGENT.md ## Heartbeat protocol` — subagent-side contract

The existing `▶ <agent> starting (~<ETA>)` and `✓ <agent> done` bracket-pair
lines elsewhere in this skill body remain in place; this protocol just makes
them more informative by adding mid-wait check-ins + structured progress.

## Step 1: Pre-scan (discovery-scout) — ALWAYS runs first, ALONE

Produces `project-structure.md` and `external-sources.md` — foundation for all other agents.
**Skip** if both already exist. Otherwise:

Print: `[1/5] Pre-scan: mapping project structure and external sources...`

Read `references/agent-prompts.md` section `## Scout` for the full prompt. Substitute the
external docs placeholder with actual paths (or the "no docs" variant).

▶ discovery-scout starting (~2–4 min)
Wait for completion. Verify both files exist. Re-dispatch if missing.
✓ discovery-scout done (record actual time) — or ✗ discovery-scout failed: {reason}

### Steps 2-5: Dispatch 4 Subagents in Parallel

**Only after Step 1 completes.** Dispatch with `background: true`. Only dispatch agents whose target files are missing.

**Every agent receives the foundation reference block** (appended to prompt):
```
REFERENCE DOCUMENTS (read these FIRST before analyzing):
- .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
- .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
- .aid/knowledge/external-sources.md — external documentation inventory and findings
```

**Sub-agents may delegate mechanical work** to the Small-tier utility agents (`simple-extractor`, `simple-glob`, `simple-formatter`) for high-volume extraction or templating. The synthesis stays at the sub-agent's tier; only the grunt work delegates. See `agents/simple-*/README.md` for the caller contract.

| Step | Agent | Target Files | Prompt Section |
|------|-------|-------------|----------------|
| [2/5] | discovery-architect | architecture.md, technology-stack.md, ui-architecture.md | `references/agent-prompts.md` → `## Architect` |
| [3/5] | discovery-analyst | module-map.md, coding-standards.md, data-model.md | `references/agent-prompts.md` → `## Analyst` |
| [4/5] | discovery-integrator | api-contracts.md, integration-map.md, domain-glossary.md | `references/agent-prompts.md` → `## Integrator` |
| [5/5] | discovery-quality | test-landscape.md, security-model.md, tech-debt.md, infrastructure.md | `references/agent-prompts.md` → `## Quality` |

Before dispatching, print the AC4 sub-unit snapshot header for the GENERATE state:
```
GENERATE  Wave 1 of 1 · 0/4 done
  (queued) discovery-architect  ~3–5 min
  (queued) discovery-analyst    ~3–5 min
  (queued) discovery-integrator ~3–5 min
  (queued) discovery-quality    ~3–5 min
```

Print the AC2 bracket-pair before each parallel dispatch:
```
▶ discovery-architect starting (~3–5 min)
▶ discovery-analyst starting (~3–5 min)
▶ discovery-integrator starting (~3–5 min)
▶ discovery-quality starting (~3–5 min)
```

### Wait for ALL Agents

**After dispatching, WAIT. Do not check files. Do not take any action.**

On each agent completion, re-render the AC4 snapshot (coalesce multiple completions within the same second into one render):
```
✓ discovery-architect done in {actual}
GENERATE  Wave 1 of 1 · 1/4 done
  ✓ discovery-architect  {actual}
  ● discovery-analyst    {elapsed} / ~3–5 min
  (queued) discovery-integrator ~3–5 min
  (queued) discovery-quality    ~3–5 min
```

Print each completion with the AC2 bracket close: `✓ {agent} done in {actual time}` (or `✗ {agent} failed: {reason}` on error).

When ALL dispatched agents complete, print the final snapshot:
```
GENERATE  Wave 1 of 1 · 4/4 done
  ✓ discovery-architect  {actual}
  ✓ discovery-analyst    {actual}
  ✓ discovery-integrator {actual}
  ✓ discovery-quality    {actual}
```

**Only proceed when ALL dispatched agents have reported completion.**

### Verify All 16 Files

Run `scripts/verify-kb.sh .aid/knowledge/` to check all 16 files exist.

**If any missing:** Re-dispatch ONLY the responsible agent (see agent-to-file mapping in the script comments).
Wait, verify again. Repeat until all 16 exist.

### Step 6: Generate README.md and INDEX.md

The orchestrator generates these directly — they require reading across all KB documents.

**.aid/knowledge/README.md** — completeness tracking table and revision history:
- Table with all 16 documents, status, and notes
- Revision history table with dates and update descriptions

**.aid/knowledge/INDEX.md** — 2-3 line summary of every KB document for agent self-service.
Regenerate on every discovery run.

**.aid/knowledge/feature-inventory.md** — copy template from `../../templates/feature-inventory.md`.
Populated during Q&A → FIX cycle, but must exist for state machine.

### Step 6b: Update `.aid/knowledge/STATE.md` with Q&A

**⚠️ Do NOT recreate this file.** It was created by `/aid-init` with metadata. Update only:

1. Read `.aid/knowledge/.scout-questions.tmp` (from scout)
2. Read all KB documents for flagged questions/uncertainties/TODOs
3. Consolidate into `## Q&A (Pending)` section with sequential IDs (Q1, Q2, ...)
4. Delete `.scout-questions.tmp`
5. Set `**Grade:**` to `Pending` (was `Not Started`)
6. **Preserve** `**Minimum Grade:**`, `**Project Type:**`, `**User Approved:**`, `## External Documentation`
7. If `--grade` provided, update `**Minimum Grade:**`

**Q&A entry format:**
```markdown
### Q{N}
- **Category:** {e.g., Architecture}
- **Impact:** {High|Medium|Low}
- **Status:** Pending
- **Context:** {why this question matters}
- **Suggested:** {answer if inferrable, or "—"}
- **Question:** {the actual question}
```

**Required Q&A entry** (inject if not present): Category: Features, Impact: Required, Status: Pending.
Adapt question to project type (web app, API, library, mobile, CLI, or generic).

Print: `[STATE.md] Updated with {N} Q&A questions. Grade: Pending.`

### Step 7: Update Project Config Files

Scan for `{project_context_file}`. Replace `<!-- AID-DISCOVER ... -->` placeholders with real data:
project description, overview, build/test commands, conventions, architecture summary.
Keep the comment markers for future re-discoveries.

### Step 8: Final Verification

Run `scripts/verify-kb.sh .aid/knowledge/` one final time.
Print: `[16/16] Generation complete — Knowledge Base ready. Run /aid-discover again to review.`

---

## Mode: REVIEW

All 16 KB documents exist. Grade them.

### Step 1: Dispatch the Reviewer

Print: `[Review 1/2] Reviewing Knowledge Base quality...`

Read `references/reviewer-prompt.md` for the full prompt to pass to the **discovery-reviewer** subagent.

**⚠️ CLEAN CONTEXT:** Do NOT include any info about generation process, which agents ran,
or prior state. The reviewer evaluates purely on what's on disk.

**⚠️ CONTAMINATION PREVENTION (also applies in FIX mode Step 3):**
- Do NOT include previous review results in the prompt
- Do NOT tell the reviewer what was fixed or previous grade
- Do NOT say "re-review" — reviewer must approach fresh

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 2: Post-Process `.aid/knowledge/STATE.md`

Verify `.aid/knowledge/STATE.md` `## KB Documents Status` and `## Issues` sections contain:
- [ ] Grade for every document (16 KB + {project_context_file} + INDEX.md + README.md)
- [ ] Issues with severity levels ([CRITICAL], [HIGH], [MEDIUM], [MINOR])
- [ ] Verification spot-checks (minimum 10) under `## Verification Spot-Checks`
- [ ] Overall grade and recommendation under `## Review History`
- [ ] Cross-cutting concerns

Set Minimum Grade (from `--grade` or default `A`). Add first Review History entry under `## Review History`.

Print: `[Review 2/2] Review complete. Grade: {overall}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.`

---

## Mode: Q&A

Grade below minimum and `## Q&A` has Pending entries.

### Step 1: Load and Filter Questions

Read `## Q&A (Pending)` from `.aid/knowledge/STATE.md`. For each Pending entry:
1. **Check KB** — answer already in another KB doc? → Auto-answer, set `Answered`
2. **Check duplicates** — already answered in a previous cycle? → Skip
3. **Inferrable?** — ensure `**Suggested:**` is populated if possible

Sort remaining: **High → Medium → Low**.
Print: `[Q&A] {N} questions for user input. Asking one at a time...`

### Step 2: Ask One Question at a Time

```
Q{N}: [{Category}: {Impact}] {question text}
Context: {context}
Suggested: {suggested answer, if present}
[1] Skip / Not applicable
[2] Accept suggestion (only if Suggested exists)
[3] Your answer: ___
```

**Wait for user response before asking next question.**

### Step 3: Record the Answer

- **[1] Skip:** Set `**Status:** Skipped`
- **[2] Accept:** Set `**Status:** Answered`, copy suggested to `**Answer:**`
- **[3] Custom:** Set `**Status:** Answered`, record text in `**Answer:**`

**Write to `.aid/knowledge/STATE.md` immediately after each answer.**

### Step 4: Continue or Exit

Repeat for all Pending. When done:
Print: `[Q&A] Complete. {answered} answered, {skipped} skipped. Run /aid-discover again to fix.`

---

## Mode: FIX

Grade below minimum, no Pending Q&A.

### Step 1: Identify Documents Below Threshold

Read `.aid/knowledge/STATE.md` `## KB Documents Status`. List documents below minimum grade.
Prioritize: [CRITICAL] → [HIGH] → [MEDIUM].
Print: `[Fix] {N} documents below {minimum}. Fixing...`

### Step 2: Fix Each Document

For each document below minimum, in priority order:
1. Read issues from `.aid/knowledge/STATE.md` `## Issues`
2. Read Answered Q&A entries from `.aid/knowledge/STATE.md` `## Q&A` applicable to this document
3. Read relevant source code for missing info
4. Edit KB document — combine review findings WITH user answers
5. **REMOVE fixed issue lines** from `.aid/knowledge/STATE.md` `## Issues`
6. Update `**Applied to:**` for each incorporated Q&A answer in STATE.md `## Q&A`
7. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

**Feature Inventory Generation:** When processing Features Q&A answers:
1. Cross-reference with api-contracts.md, module-map.md, domain-glossary.md, ui-architecture.md, data-model.md
2. Generate/update feature-inventory.md with enriched table
3. Mark Features Q&A as Applied to: `feature-inventory.md`

### Step 2b: Verify Meta-Documents (MANDATORY after every fix pass)

After ALL primary fixes, verify and update in order:
1. **`.aid/knowledge/STATE.md` Q&A** — resolved questions? new unknowns?
2. **INDEX.md** — summaries still match?
3. **README.md** — completeness table still accurate?
4. **{project_context_file}** — build commands, conventions, architecture stale?

Print: `[Fix] Verifying 4 meta-documents...`

### Step 3: Re-Review (MANDATORY — Do NOT Self-Evaluate)

**Dispatch discovery-reviewer again.** The fixer CANNOT evaluate its own work.

Print: `[Fix 2/3] Re-reviewing after fixes...`

Read `references/reviewer-prompt.md` for the full prompt. Same contamination prevention rules as REVIEW mode.

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 4: Post-Fix Update

Read new `.aid/knowledge/STATE.md`. Verify Review History preserved (append, not replace under `## Review History`).

Print: `[Fix 3/3] Complete. Grade: {old} → {new}. Run /aid-discover again to {fix remaining issues|proceed}.`

---

## Mode: APPROVAL

Grade meets minimum, not yet user-approved.

### Step 1: Present Summary

- Overall grade and minimum
- Total Q&A items (answered/skipped/pending)
- Fix cycles completed
- Remaining [MINOR] issues

### Step 2: Ask for User Approval

```
The Knowledge Base has reached the minimum grade of {minimum} (current: {grade}).
Please review .aid/knowledge/ and let us know if there is anything else to consider.
[1] Approved — KB is ready for the next phase
[2] Additional consideration: ___
```

### Step 3: Process Response

- **[1] Approved:** Add `**User Approved:** yes` to `.aid/knowledge/STATE.md`. Add Review History entry under `## Review History`.
  Print: `✅ Discovery complete. Grade: {grade}. KB approved and ready for the Interview phase.`
- **[2] Consideration:** Add as new Q&A entry in STATE.md `## Q&A (Pending)` (Category: `User Feedback`, Impact: `High`, Status: `Pending`).
  Print: `[Approval] Consideration recorded as Q{N}. Run /aid-discover again to address it.`

---

## Mode: DONE

Print: _"Discovery is complete and approved (Grade: {grade}). Do you want to reopen it for review?"_

- User confirms → set state to REVIEW
- User has specific concern → record as context for reviewer
- User says no → `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Interview phase.`

After printing the success message, also suggest the optional visual summary:

```
💡 Optional: run /aid-summarize to generate a visual HTML summary of the
   Knowledge Base — a single offline file with diagrams, light/dark theme,
   click-to-expand lightbox, and breadcrumb scrollspy. Idempotent: re-running
   it later on an unchanged KB is a no-op; it auto-detects when discovery has
   added new entries to ## Review History and regenerates accordingly.
```

---

## Targeted Discovery (Re-entry)

When a Q&A entry in `.aid/knowledge/STATE.md` or an IMPEDIMENT triggers re-discovery:

1. Read the Q&A entry in STATE.md `## Q&A (Pending)` or the IMPEDIMENT to understand what's missing
2. Identify which subagent owns the documents (see `scripts/verify-kb.sh` comments for mapping)
3. Dispatch ONLY the relevant subagent
4. Regenerate README.md and INDEX.md
5. Update README.md revision history
6. Reset the `**Grade:**` field in STATE.md to `Pending` so next run re-reviews
7. Report completion

---

## Quality Checklist

- [ ] No overlap between KB documents
- [ ] Claims grounded in code evidence (file paths, line numbers)
- [ ] Inferred info marked with ⚠️
- [ ] `.aid/knowledge/STATE.md` Q&A captures everything needing human input
- [ ] external-sources.md documents all sources (or states none provided)
- [ ] README.md reflects completeness and revision history
- [ ] INDEX.md has 2-3 line summaries per document
- [ ] feature-inventory.md exists (template or populated)
- [ ] {project_context_file} placeholders filled with discovered data
- [ ] All issues have severity: [CRITICAL], [HIGH], or [MEDIUM]
- [ ] Minimum 10 spot-checks in `.aid/knowledge/STATE.md` `## Verification Spot-Checks`

---

## Grading Criteria

| Grade | Meaning |
|-------|---------|
| A+ | Exceptional — comprehensive, accurate, evidence-rich, immediately useful |
| A | Thorough — covers expected scope with solid evidence |
| B+ | Good — minor gaps or missing details that don't block work |
| B | Adequate — covers basics but lacks depth in important areas |
| B- | Shallow — lists things without explaining patterns or relationships |
| C+ | Significant gaps — missing important sections or inaccurate in places |
| C | Barely useful — agent would need to re-discover most information |
| D | Misleading — wrong information that could cause bad decisions |
| F | Missing or empty |

**Overall grade** = weighted average where architecture, module-map, and coding-standards
count double (referenced most by downstream phases).

---

## Document Expectations

Read `references/document-expectations.md` for the full expectations per document,
including "Must have" and "Red flags" for each of the 16 KB documents plus meta-documents.
