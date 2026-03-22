---
name: aid-discover
description: >
  Brownfield codebase discovery with built-in quality gate. Generates KB, reviews it,
  collects user input, fixes issues, and gets user approval — one step per run. State-machine: GENERATE → REVIEW → Q&A → FIX → APPROVAL → DONE.
allowed-tools: Read, Glob, Grep, Bash, Write, Edit, Agent
argument-hint: "[--grade A] minimum acceptable grade (default: A)  [--reset] clear KB and restart"
---

# Brownfield Codebase Discovery

Analyze an existing codebase and produce a structured `knowledge/` directory by orchestrating
5 specialized discovery subagents. Includes a built-in quality gate that reviews, grades,
and fixes KB documents.

**State machine — each `/aid-discover` run does ONE step and exits.**

## ⚠️ Pre-flight Check

**Before starting discovery, verify you are NOT in Plan Mode.**

Plan Mode restricts all operations to read-only — subagents will NOT be able to write KB files.

**How to check:** Look at the permission indicator in your Claude Code interface (bottom of screen).
- ✅ `Default` or `Auto-accept edits` → Proceed with discovery.
- ❌ `Plan mode` → **STOP.** Tell the user: "Discovery needs to write files. Please press `Shift+Tab` to switch out of Plan Mode, then re-run `/aid-discover`."

**Do NOT proceed with discovery while in Plan Mode.** The subagents will analyze the codebase but silently fail to write any files.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Set minimum acceptable grade. Format: `[A-F][-+]?` (e.g., A, A-, B+). Default: `A`. Persists in DISCOVERY-STATE.md — user doesn't need to repeat it. |
| `--reset` | Clear entire `knowledge/` directory and restart from scratch. |

**Grade persistence:**
- When DISCOVERY-STATE.md doesn't exist yet: the `--grade` value is saved into the file as "Minimum Grade"
- When DISCOVERY-STATE.md already exists: if `--grade` is provided, it UPDATES the minimum in the file. If not provided, the minimum is READ from the file.

---

## State Detection

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.**
Do NOT rely on memory from previous runs in this session. Do NOT assume state based on
what happened earlier. ALWAYS read the actual files on disk right now.

Read the filesystem to determine which mode to enter:

```
State 1: Missing KB docs                              → GENERATE mode
State 2: All docs, no GRADE file                       → REVIEW mode
State 3: GRADE file, grade < min, has Pending Q&A      → Q&A mode
State 4: GRADE file, grade < min, no Pending Q&A       → FIX mode
State 5: GRADE file, grade >= min, not user-approved    → APPROVAL mode
State 6: GRADE file, grade >= min, user-approved        → DONE
```

**Detection logic:**

1. Check `knowledge/` for the 13 expected documents:
   ```
   architecture.md, technology-stack.md, module-map.md, coding-standards.md, data-model.md,
   api-contracts.md, integration-map.md, domain-glossary.md, test-landscape.md,
   security-model.md, tech-debt.md, infrastructure.md, additional-info.md
   ```
2. If any are missing → **GENERATE**
3. If all 13 exist but `knowledge/DISCOVERY-STATE.md` does not exist → **REVIEW**
4. If `knowledge/DISCOVERY-STATE.md` exists:
   - Read the current overall grade and minimum grade
   - If `--grade` was provided, update the minimum grade in the file
   - Compare current grade against minimum (use grade ordering below)
   - If current grade < minimum:
     - Read `knowledge/additional-info.md` for entries with `**Status:** Pending`
     - If Pending entries exist → **Q&A**
     - If no Pending entries → **FIX**
   - If current grade >= minimum:
     - Check DISCOVERY-STATE.md for `**User Approved:** yes`
     - If approved → **DONE**
     - If not approved → **APPROVAL**

**Grade ordering** (highest to lowest):
`A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, F`

Print the detected state: `[State: {GENERATE|REVIEW|Q&A|FIX|APPROVAL|DONE}]`

---

## Mode: GENERATE

Generate missing KB documents. Skip any that already exist.

### Step 0: Check Existing KB

Scan `knowledge/` for existing files. Build a list of what exists vs. what's missing.

Print: `[0/13] Checking existing KB...`

If ALL 13 documents exist and no `--reset` was requested, report KB is complete and skip
directly to Step 6 (README.md and INDEX.md regeneration).

---

### Steps 1-5: Dispatch All 5 Subagents in Parallel

Dispatch all 5 agents at once. Each agent has `background: true` so they run in parallel.

**⚠️ CRITICAL: Do NOT check files or take any action until ALL 5 agents have reported completion.**
**⚠️ An agent reporting "completed" does NOT mean all its files were written — verify after ALL finish.**

Only dispatch agents whose target files are missing. Skip agents whose files all exist.

#### [1/5] Architecture Analysis (discovery-architect)

Target files: `architecture.md`, `technology-stack.md`

Print: `[1/5] Dispatching architecture analysis...`

Prompt:
> Analyze this codebase and produce knowledge/architecture.md and knowledge/technology-stack.md.
> Cover: project type, folder structure, architectural patterns, module boundaries, data flow,
> DI registration, entry points, tech stack (languages, frameworks, versions, package managers,
> runtime, build tools, dev tooling). Write only to the knowledge/ directory.

#### [2/5] Module and Convention Analysis (discovery-analyst)

Target files: `module-map.md`, `coding-standards.md`, `data-model.md`

Print: `[2/5] Dispatching module and convention analysis...`

Prompt:
> Analyze this codebase and produce knowledge/module-map.md, knowledge/coding-standards.md,
> and knowledge/data-model.md. Map every module (purpose, size, dependencies, test coverage).
> Mine coding conventions from actual code — naming, error handling, logging, config, file
> organization. Extract data models: schemas, relationships, migrations, indexes, validation.
> Write only to the knowledge/ directory.

#### [3/5] Integration Mapping (discovery-integrator)

Target files: `api-contracts.md`, `integration-map.md`, `domain-glossary.md`

Print: `[3/5] Dispatching integration mapping...`

Prompt:
> Analyze this codebase and produce knowledge/api-contracts.md, knowledge/integration-map.md,
> and knowledge/domain-glossary.md. Map APIs exposed and consumed, message queues, caches,
> webhooks, and third-party services. Build a domain glossary from class names, method names,
> constants, and comments that encode business concepts. Write only to the knowledge/ directory.

#### [4/5] Quality Assessment (discovery-quality)

Target files: `test-landscape.md`, `security-model.md`, `tech-debt.md`

Print: `[4/5] Dispatching quality assessment...`

Prompt:
> Analyze this codebase and produce knowledge/test-landscape.md, knowledge/security-model.md,
> and knowledge/tech-debt.md. Assess test frameworks, test types, coverage, CI/CD integration.
> Evaluate security: auth, authorization, secrets management, OWASP concerns. Audit tech debt:
> large files, TODO/FIXME density, missing tests, outdated packages, dead code. Classify all
> debt items with risk ratings (Critical/High/Medium/Low). Write only to the knowledge/ directory.

#### [5/5] Infrastructure and Gap Analysis (discovery-scout)

Target files: `infrastructure.md`, `additional-info.md`

Print: `[5/5] Dispatching infrastructure and gap analysis...`

Prompt:
> Analyze this codebase and produce knowledge/infrastructure.md and knowledge/additional-info.md.
> Map CI/CD pipelines, Docker/container config, IaC (Terraform, Pulumi, CDK), environments,
> and monitoring. For additional-info.md: capture EVERYTHING that cannot be determined from code
> alone — every uncertainty, assumption, and gap needing human input. Use the structured Q&A
> format: each question gets a unique ID (Q{N}), category tag (e.g., Architecture, Security,
> Data), impact level (High/Medium/Low), Status: Pending, context explaining why it matters,
> and a Suggested answer when inferrable from code patterns. Order by impact (High first).
> Be comprehensive. Write only to the knowledge/ directory.

---

### Wait for ALL Agents

**After dispatching, WAIT. Do not check files. Do not take any action.**

Track agent completions. Print each one as it arrives:
```
Agent "[name]" completed. [N/5] done.
```

**Only proceed to file verification when ALL dispatched agents have reported completion.**

If you see "N local agents still running" in the status bar, you are NOT done. Wait.

---

### Verify All 13 Files

**Only after ALL agents have completed**, check which files exist:

```bash
for f in architecture.md technology-stack.md module-map.md coding-standards.md \
  data-model.md api-contracts.md integration-map.md domain-glossary.md \
  test-landscape.md security-model.md tech-debt.md infrastructure.md additional-info.md; do
  [ -f "knowledge/$f" ] && echo "✅ $f" || echo "❌ $f MISSING"
done
```

**If any files are missing:** Re-dispatch ONLY the specific agent responsible for the missing files.
Wait for that agent to complete. Verify again. Repeat until all 13 exist.

**Agent-to-file mapping for re-dispatch:**
| Agent | Files |
|-------|-------|
| discovery-architect | architecture.md, technology-stack.md |
| discovery-analyst | module-map.md, coding-standards.md, data-model.md |
| discovery-integrator | api-contracts.md, integration-map.md, domain-glossary.md |
| discovery-quality | test-landscape.md, security-model.md, tech-debt.md |
| discovery-scout | infrastructure.md, additional-info.md |

When re-dispatching, target ONLY the missing file(s):
> Analyze this codebase and produce ONLY knowledge/{missing-file}.md. [original prompt for that area]. Write only to the knowledge/ directory.

---

### Step 6: Generate README.md and INDEX.md

The orchestrator (you) generates these two documents directly — they are small and require
reading across all previously produced KB documents.

**knowledge/README.md** — completeness tracking table and revision history:
```markdown
# Knowledge Base

## Completeness

| Document | Status | Notes |
|----------|--------|-------|
| architecture.md | ✅ Complete | |
| technology-stack.md | ✅ Complete | |
| module-map.md | ✅ Complete | |
| coding-standards.md | ✅ Complete | |
| data-model.md | ✅ Complete | |
| api-contracts.md | ✅ Complete | |
| integration-map.md | ✅ Complete | |
| domain-glossary.md | ✅ Complete | |
| test-landscape.md | ✅ Complete | |
| security-model.md | ✅ Complete | |
| tech-debt.md | ✅ Complete | |
| infrastructure.md | ✅ Complete | |
| additional-info.md | ✅ Complete | |

## Revision History

| Date | Documents Updated | Notes |
|------|-------------------|-------|
| {date} | All (initial discovery) | |
```

**knowledge/INDEX.md** — 2-3 line summary of every KB document for agent self-service:
```markdown
# Knowledge Base Index — {Project Name}

Use this index to find the right document before making assumptions.
If your task touches an area covered here, read the relevant document first.

| Document | Summary |
|----------|---------|
| architecture.md | {2-3 line summary of patterns found and structure} |
| technology-stack.md | {2-3 line summary of stack} |
| module-map.md | {2-3 line summary of modules} |
| coding-standards.md | {2-3 line summary of key conventions} |
| data-model.md | {2-3 line summary of data model} |
| api-contracts.md | {2-3 line summary of API surface} |
| integration-map.md | {2-3 line summary of integrations} |
| domain-glossary.md | {2-3 line summary of key terms} |
| test-landscape.md | {2-3 line summary of test coverage} |
| security-model.md | {2-3 line summary of security posture} |
| tech-debt.md | {2-3 line summary of debt and risk} |
| infrastructure.md | {2-3 line summary of infrastructure} |
| additional-info.md | {2-3 line summary of pending Q&A items needing human input} |
```

Regenerate INDEX.md on every discovery run (full or targeted).

---

### Step 7: Update Project Config Files

Scan the project root for `AGENTS.md` and `CLAUDE.md`. Replace any `<!-- AID:DISCOVER ... -->`
placeholders with real data from the analysis:

- **Project Overview** — project name, purpose, tech stack, target platform
- **Build & Test** — actual build, test, and lint commands (from build scripts, CI config, package manager)
- **Code Conventions** — key naming patterns, formatting rules, idioms found in code
- **Architecture** — high-level summary (layers, modules, entry points)
- **Project description** (CLAUDE.md) — project name and one-line description

Keep the `<!-- AID:DISCOVER ... -->` comment above each section so future re-discoveries can update them.
Replace only the `(pending discovery)` placeholder lines with real content.
If a field cannot be determined, leave it as `(not found — check additional-info.md)`.

---

### Step 8: Final Verification

List all 13 expected KB documents. Check each exists. Report any missing.

Print: `[13/13] Generation complete — Knowledge Base ready. Run /aid-discover again to review.`

If any documents are missing, report them and offer to re-dispatch the responsible subagent.

---

## Mode: REVIEW

All 13 KB documents exist. Grade them.

### Step 1: Dispatch the Reviewer

Dispatch **discovery-reviewer** subagent.

Print: `[Review 1/2] Reviewing Knowledge Base quality...`

**⚠️ CLEAN CONTEXT:** Do NOT include any information about the generation process,
which agents ran, what was easy or hard, or any prior state. The reviewer must
evaluate the KB purely on what's on disk — as if a stranger wrote it.

Prompt to pass to the subagent:
> Review every document in knowledge/ for quality. Be AGGRESSIVE — a lenient review is worse
> than useless because it lets bad docs through the quality gate.
>
> For each document, assess:
>
> 1. **Accuracy** (MOST IMPORTANT) — Do NOT trust what the document says. Verify claims
>    against actual source files:
>    - Version numbers → check build configs, lockfiles, dependency manifests, library filenames
>    - File paths → verify they exist on disk
>    - Class/interface/abstract claims → read the actual declaration
>    - Configuration values → check actual config files
>    - Absolute statements ("always", "all modules", "never") → verify scope is correct
>    - Every claim should be traceable to a primary source. If it's not, flag it.
>    - Any factual error is [CRITICAL]. Any value marked "TBD" or "unknown" when
>      extractable from the codebase is [HIGH].
>
> 2. **Completeness** — Does the document cover everything its title promises?
>    - Compare against what a developer working on this codebase would need.
>    - Are edge cases and failure modes documented where relevant?
>    - If a problem is identified (e.g., tech debt), is a next step or mitigation noted?
>    - Are all terms and abbreviations defined or referenced in the glossary?
>
> 3. **Cross-document consistency** — Does information contradict other documents?
>    - If a wrong claim propagates across multiple docs, flag each propagation separately.
>    - Do summaries in INDEX.md match what the primary documents actually say?
>    - Is the same concept called the same name everywhere? (not "bundle" in one doc
>      and "module" in another for the same thing)
>
> 4. **Depth vs. signal** — Quality of information, not quantity.
>    - Does it explain patterns, relationships, and WHY — or just list names?
>    - Is information duplicated from other documents without adding new value?
>    - Is the signal-to-noise ratio high? Could sections be removed without losing
>      anything an agent would need?
>
> 5. **Usefulness** — Imagine you're an agent asked to add a feature, fix a bug, or
>    understand a module in this codebase.
>    - Would this document let you act correctly without re-discovering?
>    - Can you find the specific information you need quickly from the structure?
>    - Are the claims grounded in specific locations (file paths, class names) or
>      generic statements that could apply to any project?
>
> 6. **Meta-document integrity** — INDEX.md, README.md, AGENTS.md, and CLAUDE.md are
>    derived from the 13 primary documents.
>    - Do their summaries and values accurately reflect the current primary doc content?
>    - Is placeholder text or template markers still present?
>    - Are questions marked Pending in additional-info.md actually still unanswerable from code?
>
> Grade each document: A+ (exceptional), A (thorough), B+ (good with minor gaps), B (adequate),
> B- (shallow), C+ (significant gaps), C (barely useful), D (misleading or wrong), F (missing/empty).
>
> **Grade caps (absolute — no exceptions):**
> Multiple [CRITICAL] → max D. One [CRITICAL] → max D+.
> Multiple [HIGH] → max C. One [HIGH] → max C+.
> Multiple [MEDIUM] → max B. One [MEDIUM] → max B+.
> Multiple [MINOR] → max A-. One [MINOR] → max A. Only zero issues = A+.
>
> All issues MUST have severity: [CRITICAL], [HIGH], [MEDIUM], or [MINOR].
>
> **Minimum 15 spot-checks** (verify claims against actual code). At least 5 must be version verifications.
>
> **After grading, add questions to additional-info.md** for any information gaps found during
> review that cannot be resolved from code. These become Q&A items for the user. Use the next
> sequential Q{N} ID, categorize by area, and assign impact levels (High/Medium/Low). Only add
> questions for things genuinely needing human input — if you can grep the answer, fix it in the
> review instead.
>
> Write the full review to knowledge/DISCOVERY-STATE.md using the DISCOVERY-STATE.md template format.

Wait for completion.

---

### Step 2: Post-Process DISCOVERY-STATE.md

Read `knowledge/DISCOVERY-STATE.md`. Verify it contains:
- [ ] Grade for every document (13 KB docs + AGENTS.md + CLAUDE.md + INDEX.md + README.md)
- [ ] Specific issues with severity levels ([CRITICAL], [HIGH], [MEDIUM], [MINOR])
- [ ] Verification spot-checks (minimum 10)
- [ ] Overall grade and recommendation
- [ ] Cross-cutting concerns

Set the Minimum Grade in the file:
- If `--grade` was provided, use that value
- If not, use the default: `A`

Add the first Review History entry.

Print: `[Review 2/2] Review complete. Grade: {overall}. Minimum: {min}. Run /aid-discover again to {fix issues|proceed}.`

**Grade comparison:**
- If overall grade >= minimum → Next run will enter APPROVAL mode (user sign-off)
- If overall grade < minimum and Pending Q&A exists → Next run will enter Q&A mode
- If overall grade < minimum and no Pending Q&A → Next run will enter FIX mode

---

## Mode: Q&A

DISCOVERY-STATE.md exists, the grade is below minimum, and `knowledge/additional-info.md`
contains entries with `**Status:** Pending`.

The Q&A mode presents questions to the user **one at a time**, collects answers, and updates
the additional-info.md document.

### Step 1: Load and Filter Questions

Read `knowledge/additional-info.md`. Collect all entries with `**Status:** Pending`.

**Before presenting each question, apply the filter:**

1. **Check KB** — Is the answer already in another KB document? → Change status to `Answered`,
   fill in the answer from the KB, set `Applied to` field. Skip to next question.
2. **Check additional-info.md** — Was this already asked and answered in a previous cycle?
   → Skip (should not happen if statuses are tracked correctly, but guard against duplicates).
3. **Inferrable from context?** — Can the answer be reasonably deduced from code patterns?
   → Keep the question but ensure it has a `**Suggested:**` answer. The user confirms or corrects.

After filtering, sort remaining Pending questions by impact: **High → Medium → Low**.

Print: `[Q&A] {N} questions for user input. Asking one at a time...`

If zero questions remain after filtering, print: `[Q&A] All questions resolved from KB. Proceeding to Fix.`
and skip to the end of Q&A mode.

### Step 2: Ask One Question at a Time

For each Pending question, present it to the user in this format:

```
Q{N}: [{Category}: {Impact}] {question text}

Context: {context from the additional-info entry}

Suggested: {suggested answer, if present}

[1] Skip / Not applicable
[2] Accept suggestion (only shown if Suggested exists)
[3] Your answer: ___
```

**Wait for the user's response before asking the next question.**

### Step 3: Record the Answer

Based on the user's response, update the entry in `knowledge/additional-info.md`:

- **User chose [1] (Skip):** Set `**Status:** Skipped`
- **User chose [2] (Accept suggestion):** Set `**Status:** Answered`, copy the suggested text to `**Answer:**`
- **User typed an answer [3]:** Set `**Status:** Answered`, record their text in `**Answer:**`

**Important:** Write the update to the file immediately after each answer. Do not batch.

### Step 4: Continue or Exit

After recording, move to the next Pending question. Repeat Steps 2-3.

When all Pending questions have been addressed (answered or skipped):

Print: `[Q&A] Complete. {answered} answered, {skipped} skipped. Run /aid-discover again to fix.`

The next run will detect no Pending Q&A and enter FIX mode. The FIX will use the answers
from additional-info.md to improve the KB documents.

---

## Mode: FIX

DISCOVERY-STATE.md exists but the overall grade is below the minimum.

### Step 1: Identify Documents Below Threshold

Read DISCOVERY-STATE.md. List all documents graded below the minimum grade.
Prioritize: [CRITICAL] issues first, then [HIGH], then [MEDIUM].

Print: `[Fix] {N} documents below {minimum}. Fixing...`

---

### Step 2: Fix Each Document

For each document below the minimum grade, in priority order:

1. Read the specific issues from the Issues Found section of DISCOVERY-STATE.md
2. Read `knowledge/additional-info.md` for Answered entries that apply to this document
3. Read the relevant source code to gather missing information
4. Edit the KB document to address the issues — combining review findings WITH user answers from additional-info.md. A review finding ("auth section is shallow") + a user answer ("OAuth2 with Azure AD") together produce a precise, evidence-backed fix.
5. **REMOVE the fixed issue lines** from the Issues Found section of DISCOVERY-STATE.md
6. For each Answered entry from additional-info.md that was incorporated, update its `**Applied to:**` field with the target document name and cycle number
7. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

**IMPORTANT:** When an issue is fixed, its line MUST be removed from the Issues Found section.
DISCOVERY-STATE.md always reflects the CURRENT state, not history. History is tracked in the
Review History table.

**IMPORTANT:** Answered entries in additional-info.md are fix items too. Treat them with the
same priority as review findings. Cross-reference findings and answers — they often complement
each other (the finding says WHERE something is weak, the answer says WHAT to put there).

---

### Step 2b: Verify Meta-Documents (MANDATORY after every fix pass)

Fixes to primary KB documents can invalidate derived/meta documents. After ALL primary fixes,
verify and update the following 5 meta-documents **in this order:**

1. **additional-info.md** — Do any fixed issues resolve pending questions? Update their status. Did fixes reveal new unknowns? Add them as new Q&A entries with the next sequential ID.
2. **INDEX.md** — Do summaries still match the updated document content? Update any stale summaries.
3. **README.md** — Does the completeness table (status/gaps) still reflect reality? Update statuses.
4. **CLAUDE.md** — Did fixes change conventions, gotchas, or architecture summaries? Update if stale.
5. **AGENTS.md** — Did fixes change build commands, architecture, or conventions summaries? Update if stale.

Print: `[Fix] Verifying 5 meta-documents...`

For each meta-doc, read it, compare against the fixes just made, and update if needed.
If no update is needed, skip silently. If updated, print: `[Fix] Updated {document}`

---

### Step 3: Re-Review (MANDATORY — Do NOT Self-Evaluate)

**After fixing all documents, you MUST dispatch the `discovery-reviewer` subagent again.**
The agent that wrote the fix CANNOT evaluate its own work. This is a hard rule.

Print: `[Fix 2/3] Re-reviewing after fixes...`

Dispatch **discovery-reviewer** with the prompt from REVIEW mode Step 1.
The reviewer will overwrite DISCOVERY-STATE.md with a fresh assessment.

**⚠️ CONTAMINATION PREVENTION:**
- Do NOT include previous review results in the prompt to the reviewer.
- Do NOT tell the reviewer what was fixed or what the previous grade was.
- Do NOT say "re-review" or "verify the fixes" — the reviewer must approach
  the KB as if seeing it for the first time.
- The reviewer's `background: true` gives it an isolated context window — but
  only if you don't inject prior results into its prompt.
- If the reviewer asks about previous grades, respond: "Evaluate fresh. No prior context."

Wait for completion.

---

### Step 4: Post-Fix Update

Read the new DISCOVERY-STATE.md produced by the reviewer.

1. Verify the Review History was preserved (reviewer should append, not replace)
2. If Review History is missing entries from before the re-review, add them back
3. Ensure the new entry reflects this was a Fix + Re-review cycle

Print: `[Fix 3/3] Complete. Grade: {old} → {new}. Run /aid-discover again to {fix remaining issues|proceed}.`

**If the grade is still below minimum:** The next run will check for Pending Q&A entries first (→ Q&A mode) or proceed to FIX mode if none. This is expected — some fixes may introduce new issues or the reviewer may catch things the fixer missed. The cycle continues until the grade meets the minimum.

**If the grade meets the minimum:** The next run will enter APPROVAL mode for user sign-off.

**If documents still have issues after fixing:** The next run will re-enter the appropriate mode (Q&A if new Pending questions, FIX otherwise) to continue.

---

## Mode: APPROVAL

DISCOVERY-STATE.md exists, the grade meets or exceeds the minimum, but the user has not
yet approved the KB.

### Step 1: Present Summary

Print a brief summary of the KB state:
- Overall grade and minimum
- Total Q&A items (answered/skipped/pending)
- Number of fix cycles completed
- Any remaining [MINOR] issues from the grade file

### Step 2: Ask for User Approval

```
The Knowledge Base has reached the minimum grade of {minimum} (current: {grade}).

Please review the documentation in knowledge/ and let us know if there is anything
else we should consider.

[1] Approved — KB is ready for the next phase
[2] Additional consideration: ___
```

**Wait for the user's response.**

### Step 3: Process Response

- **User chose [1] (Approved):**
  - Add `**User Approved:** yes` to the top of DISCOVERY-STATE.md (after the Minimum Grade line)
  - Add a Review History entry: `| {N} | {date} | {grade} | User Approval | User approved KB for next phase |`
  - Print: `✅ Discovery complete. Grade: {grade}. KB approved and ready for the Interview phase.`

- **User provided additional consideration [2]:**
  - Add the consideration as a new entry in `knowledge/additional-info.md` with:
    - Next sequential Q{N} ID
    - `[User Feedback: High]` category and impact
    - `**Status:** Pending`
    - The user's text as the context
  - Print: `[Approval] Consideration recorded as Q{N}. Run /aid-discover again to address it.`
  - The next run will detect Pending Q&A and re-enter the cycle (Q&A or FIX depending on
    whether it needs user input or can be resolved from code).

---

## Mode: DONE

DISCOVERY-STATE.md exists, the grade meets or exceeds the minimum, and the user has approved.

Print: `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Interview phase.`

No action needed. The user can proceed to `/aid-interview`.

---

## Targeted Discovery (Re-entry)

When a GAP.md or IMPEDIMENT.md triggers re-discovery of a specific area:

1. Read the GAP/IMPEDIMENT to understand exactly what's missing
2. Identify which subagent owns the missing documents:
   - `architecture.md`, `technology-stack.md` → dispatch discovery-architect
   - `module-map.md`, `coding-standards.md`, `data-model.md` → dispatch discovery-analyst
   - `api-contracts.md`, `integration-map.md`, `domain-glossary.md` → dispatch discovery-integrator
   - `test-landscape.md`, `security-model.md`, `tech-debt.md` → dispatch discovery-quality
   - `infrastructure.md`, `additional-info.md` → dispatch discovery-scout
3. Dispatch ONLY the relevant subagent for the area that needs updating
4. Regenerate README.md and INDEX.md (orchestrator does this directly)
5. Update `knowledge/README.md` revision history with the targeted update
6. Delete `knowledge/DISCOVERY-STATE.md` so the next run re-reviews
7. Report completion to the calling phase

---

## Quality Checklist

- [ ] No overlap between KB documents
- [ ] Claims grounded in code evidence (file paths, line numbers)
- [ ] Inferred info marked with ⚠️
- [ ] additional-info.md captures everything needing human input in structured Q&A format
- [ ] README.md reflects completeness status and revision history
- [ ] INDEX.md generated with 2-3 line summaries of every KB document
- [ ] AGENTS.md and CLAUDE.md placeholders filled with discovered data
- [ ] All issues in DISCOVERY-STATE.md have severity: [CRITICAL], [HIGH], or [MEDIUM]
- [ ] Minimum 10 spot-checks in DISCOVERY-STATE.md

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
| C | Barely useful — an agent would need to re-discover most information |
| D | Misleading — contains wrong information that could cause bad decisions |
| F | Missing or empty |

**Overall grade** = weighted average where architecture, module-map, and coding-standards
count double (they're referenced most by downstream phases).

---

## Document Expectations

These define what the reviewer (and FIX mode) should look for in each document.

### architecture.md
Must have: project type, folder structure (annotated), architectural patterns with evidence,
module boundaries, data flow (entry→processing→persistence), DI registration, entry points.
**Red flags**: Generic descriptions without file paths. Missing data flow.

### technology-stack.md
Must have: languages with versions, frameworks with versions (from actual config files),
databases, package managers, build tools, runtime, dev tooling.
**Red flags**: "⚠️ Version TBD" on things extractable from pom.xml/package.json/manifests.

### module-map.md
Must have: every module listed with purpose, key classes, dependencies between modules.
**Red flags**: Module listed without purpose explanation. Missing dependency relationships.

### coding-standards.md
Must have: naming conventions (with examples from code), file layout, DI patterns, error
handling, logging patterns, test patterns.
**Red flags**: Generic advice instead of project-specific conventions.

### data-model.md
Must have: entity hierarchy, relationships (1:N, M:N), base classes, key entities with
purpose, database config, migration strategy.
**Red flags**: Entity list without relationships. Missing how entities connect to each other.

### api-contracts.md
Must have: API style, actual endpoint paths/URLs (not just class names), auth mechanism,
request/response formats, error patterns.
**Red flags**: Lists action classes without URLs. Missing how to actually call the API.

### integration-map.md
Must have: external systems with connection details, protocols, config locations, error
handling, retry patterns. NOT just a module list.
**Red flags**: Same content as module-map.md. Missing connection details.

### domain-glossary.md
Must have: business-specific terms, technical terms unique to this project, abbreviations,
product names with explanations.
**Red flags**: Generic programming terms. Missing project-specific vocabulary.

### test-landscape.md
Must have: frameworks, test types, coverage metrics/goals, CI integration, which modules
have real tests vs placeholders, test gaps with severity.
**Red flags**: Too short. Missing per-module coverage assessment.

### security-model.md
Must have: auth mechanisms, authorization model, secrets management, transport security,
OWASP assessment, access logging.
**Red flags**: Generic OWASP checklist without project-specific assessment.

### tech-debt.md
Must have: categorized by severity (Critical/High/Medium/Low), each with location, risk,
and notes. Observations about overall health.
**Red flags**: Missing severity classification. No actionable locations.

### infrastructure.md
Must have: CI/CD pipeline details, container config, deployment process, artifact repos,
source control, release process, runtime config, monitoring, environments.
**Red flags**: Lists tools without explaining how they're configured or connected.

### additional-info.md
Must have: structured Q&A entries with unique IDs (Q{N}), category tags, impact levels
(High/Medium/Low), status (Pending/Answered/Skipped), context explaining why each question
matters, and suggested answers when inferrable from code. Questions ordered by impact.
Should capture EVERYTHING that code analysis alone cannot determine.
**Red flags**: Too few questions. Generic questions that could apply to any project. Missing
impact classification. Missing context. Questions answerable from code still marked Pending.
Answered entries missing Applied to field.

### INDEX.md
Must have: accurate 2-3 line summary per document. Summaries must reflect actual content.
**Red flags**: Generic summaries. Summaries that don't match document content.

### README.md
Must have: completeness table, revision history.
**Red flags**: Missing gap acknowledgment.

### AGENTS.md
Must have: accurate project overview, real build/test commands, conventions from code,
architecture summary. No remaining `(pending discovery)` placeholders.
**Red flags**: Placeholder text still present. Commands that wouldn't actually work.

### CLAUDE.md
Must have: accurate project description, KB reference, conventions summary.
**Red flags**: Placeholder text still present. Missing key gotchas for agents.
