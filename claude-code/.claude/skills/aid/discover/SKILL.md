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

### Check 1: Verify Init Has Run

Check if `.aid/knowledge/DISCOVERY-STATE.md` exists. If it doesn't:
```
⚠️ Knowledge Base not initialized. Run /aid-init first to set up the project.
```
Exit. Do not proceed.

If it exists but has `**Grade:** Not Started`, that's expected — init ran, discovery hasn't.

### Check 2: Verify Not in Plan Mode

**Before starting discovery, verify you are NOT in Plan Mode.**

Plan Mode restricts all operations to read-only — subagents will NOT be able to write KB files.

**How to check:** Look at the permission indicator in your Claude Code interface (bottom of screen).
- ✅ `Default` or `Auto-accept edits` → Proceed with discovery.
- ❌ `Plan mode` → **STOP.** Tell the user: "Discovery needs to write files. Please press `Shift+Tab` to switch out of Plan Mode, then re-run `/aid-discover`."

**Do NOT proceed with discovery while in Plan Mode.** The subagents will analyze the repository but silently fail to write any files.

## Arguments

| Argument | Effect |
|----------|--------|
| `--grade X` | Set minimum acceptable grade. Format: `[A-F][-+]?` (e.g., A, A-, B+). Default: `A`. Persists in DISCOVERY-STATE.md — user doesn't need to repeat it. |
| `--reset` | Clear entire `.aid/knowledge/` directory and restart from scratch. |

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
   ```
   project-structure.md, external-sources.md,
   architecture.md, technology-stack.md, module-map.md, coding-standards.md, data-model.md,
   api-contracts.md, integration-map.md, domain-glossary.md, test-landscape.md,
   security-model.md, tech-debt.md, infrastructure.md,
   ui-architecture.md, feature-inventory.md
   ```
2. A document is "populated" only if it contains real content — NOT just the init template
   (files containing only `❌ Pending` are treated as missing). If any are missing or
   unpopulated → **GENERATE**
3. If all 16 are populated and `.aid/knowledge/DISCOVERY-STATE.md` has `**Grade:** Pending` or
   `**Grade:** Not Started` → **REVIEW**
4. If all 16 are populated but `.aid/knowledge/DISCOVERY-STATE.md` does not exist → **REVIEW** (legacy)
5. If `.aid/knowledge/DISCOVERY-STATE.md` exists with a grade other than Pending:
   - Read the current overall grade and minimum grade
   - If `--grade` was provided, update the minimum grade in the file
   - Compare current grade against minimum (use grade ordering below)
   - Read DISCOVERY-STATE.md `## Q&A` section for entries with `**Status:** Pending`
   - If any Pending entry has `**Impact:** Required` → **Q&A** (regardless of grade)
   - If current grade < minimum:
     - If Pending entries exist → **Q&A**
     - If no Pending entries → **FIX**
   - If current grade >= minimum AND no Required Pending Q&A:
     - Check DISCOVERY-STATE.md for `**User Approved:** yes`
     - If approved → **DONE**
     - If not approved → **APPROVAL**

**Grade ordering** (highest to lowest):
`A+, A, A-, B+, B, B-, C+, C, C-, D+, D, D-, E+, E, E-, F`

Print the detected state: `[State: {GENERATE|REVIEW|Q&A|FIX|APPROVAL|DONE}]`

---

## Mode: GENERATE

Generate KB documents that are missing or still at "Pending" status.

### Step 0: Check Existing KB

Scan `.aid/knowledge/` for existing files. A document counts as "exists" only if:
- The file is present on disk, AND
- It contains real content (not just the init template with "Pending Discovery" or "Pending")

A file with only the init template header (containing `❌ Pending`) is treated as MISSING
and will be regenerated.

Print: `[0/16] Checking existing KB...`

If ALL 16 documents have real content and no `--reset` was requested, report KB is complete
and skip directly to Step 6 (README.md and INDEX.md regeneration).

---

### Step 0b: Read External Documentation Paths

Read `.aid/knowledge/DISCOVERY-STATE.md` section `## External Documentation` for paths registered
by `aid-init`. If paths are listed, verify they are still accessible:

```bash
test -r <path> && echo "✅ $path" || echo "❌ $path — no longer accessible"
```

If any path is no longer accessible, warn (but continue — the scout will note it in
external-sources.md). Store the accessible paths for the scout prompt.

If DISCOVERY-STATE.md doesn't exist or has no external docs section, proceed without
external documentation.

---

### Step 1: Pre-scan (discovery-scout) — ALWAYS runs first, ALONE

The discovery-scout runs **before** all other agents. It produces two foundation documents
that every subsequent agent will use as reference:

1. **`project-structure.md`** — shallow map of the repository: directory tree, key files,
   detected languages/frameworks, entry points, build files, test directories. NOT deep analysis
   — just a structural inventory so other agents know where to look.

2. **`external-sources.md`** — map of all external documentation provided by the user (if any).
   For each source: path, type, accessibility, content inventory, key findings, and discrepancies
   with code. If no external sources were provided, states that all knowledge comes from the
   repository only.

**Skip this step** if both `project-structure.md` AND `external-sources.md` already exist
(e.g., re-dispatch for missing main-phase files). Go directly to Step 2.

Print: `[1/5] Pre-scan: mapping project structure and external sources...`

Prompt:
> Analyze this project's repository structure and any external documentation to produce TWO
> foundation documents:
>
> **.aid/knowledge/project-structure.md:**
> Map the repository structure — directory tree (top 3-4 levels), key files and their purpose,
> detected languages and frameworks, build system files, entry points, test directories,
> configuration files, and documentation files. This is an inventory, not deep analysis.
> Include file counts per major directory and note any unusual structure.
>
> **.aid/knowledge/external-sources.md:**
> {If external docs were provided: "The user provided additional documentation outside the repository: {paths}. Read ALL of these thoroughly. For each source, document: path, type (file/directory), content inventory (list every significant document with topic and key findings), and discrepancies between documentation and code. This is critical — other agents will use this document to find information that is NOT in the code."}
> {If NO external docs: "No external documentation was provided. Write: 'No external documentation was provided during discovery. All knowledge was derived from repository content only. If external documentation becomes available, re-run discovery or add paths during Q&A.'"}
>
> **Additionally**, while analyzing, collect questions about anything that cannot be determined
> from the repository alone — uncertainties, assumptions, and gaps needing human input. For each
> question, use the structured Q&A format: unique ID (Q{N}), category tag (e.g., Architecture,
> Security, Data), impact level (High/Medium/Low), Status: Pending, context explaining why it
> matters, and a Suggested answer when inferrable from repository content. Order by impact
> (High first). Be comprehensive. Write these questions to a TEMPORARY file:
> `.aid/knowledge/.scout-questions.tmp`
>
> Write only to the .aid/knowledge/ directory.

**Wait for the scout to complete.** Verify both files exist:
```bash
[ -f ".aid/knowledge/project-structure.md" ] && echo "✅ project-structure.md" || echo "❌ MISSING"
[ -f ".aid/knowledge/external-sources.md" ] && echo "✅ external-sources.md" || echo "❌ MISSING"
```
If either is missing, re-dispatch the scout targeting only the missing file.

---

### Steps 2-5: Dispatch 4 Subagents in Parallel

**Only after Step 1 is complete**, dispatch the 4 remaining agents in parallel.
Each agent has `background: true` so they run in parallel.

**⚠️ CRITICAL: Do NOT check files or take any action until ALL 4 agents have reported completion.**
**⚠️ An agent reporting "completed" does NOT mean all its files were written — verify after ALL finish.**

Only dispatch agents whose target files are missing. Skip agents whose files all exist.

**Every agent receives the foundation reference:**
All 4 agent prompts include this block at the end (before "Write only to the .aid/knowledge/ directory"):
```
REFERENCE DOCUMENTS (read these FIRST before analyzing):
- .aid/knowledge/project-structure.md — repository structure map
- .aid/knowledge/external-sources.md — external documentation inventory and findings
Use these to orient your analysis. External sources may contain information directly relevant
to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
and note any discrepancies.
```

#### [2/5] Architecture Analysis (discovery-architect)

Target files: `architecture.md`, `technology-stack.md`, `ui-architecture.md`

Print: `[2/5] Dispatching architecture analysis...`

Prompt:
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/architecture.md,
> .aid/knowledge/technology-stack.md, and .aid/knowledge/ui-architecture.md.
> Cover: project type, folder structure, architectural patterns, module boundaries, data flow,
> DI registration, entry points, tech stack (languages, frameworks, versions, package managers,
> runtime, build tools, dev tooling).
> For ui-architecture.md: component architecture (tree, composition, shared vs page),
> state management (framework, patterns, server state sync), design system (tokens, palette,
> typography, existing library), routing & navigation (router, guards, deep linking),
> responsive & adaptive strategy (breakpoints, mobile-first), accessibility approach
> (WCAG level, aria patterns, keyboard nav), styling approach (CSS modules, Tailwind,
> styled-components, theming), and build & bundle config (bundler, code splitting, lazy loading).
> If the project has no frontend, write "No frontend detected — this project is backend-only"
> in ui-architecture.md.
> When repository documentation describes intended architecture and code shows different
> implementation, note the discrepancy — documentation reveals intent, code reveals reality.
> Both are valuable. Pay special attention to external-sources.md — external documentation
> often contains architecture decisions and design rationale absent from the code.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-structure.md — repository structure map
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

#### [3/5] Module and Convention Analysis (discovery-analyst)

Target files: `module-map.md`, `coding-standards.md`, `data-model.md`

Print: `[3/5] Dispatching module and convention analysis...`

Prompt:
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/module-map.md,
> .aid/knowledge/coding-standards.md, and .aid/knowledge/data-model.md.
> Map every module (purpose, size, dependencies, test coverage).
> Mine coding conventions from actual code — naming, error handling, logging, config, file
> organization. Extract data models: schemas, relationships, migrations, indexes, validation.
> When repository documentation describes conventions and code shows different patterns, note
> the discrepancy — documentation reveals intent, code reveals reality. Pay special attention
> to external-sources.md — external documentation often contains coding standards and data
> model definitions absent from the code.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-structure.md — repository structure map
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

#### [4/5] Integration Mapping (discovery-integrator)

Target files: `api-contracts.md`, `integration-map.md`, `domain-glossary.md`

Print: `[4/5] Dispatching integration mapping...`

Prompt:
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/api-contracts.md,
> .aid/knowledge/integration-map.md, and .aid/knowledge/domain-glossary.md.
> Map APIs exposed and consumed, message queues, caches, webhooks, and third-party services.
> Build a domain glossary from class names, method names, constants, comments, and documentation
> that encode business concepts.
> When documentation describes integrations and code shows different implementations, note the
> discrepancy — documentation reveals intent, code reveals reality. Pay special attention to
> external-sources.md — external documentation often contains API specs, integration diagrams,
> and domain definitions absent from the code.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-structure.md — repository structure map
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

#### [5/5] Quality and Infrastructure Assessment (discovery-quality)

Target files: `test-landscape.md`, `security-model.md`, `tech-debt.md`, `infrastructure.md`

Print: `[5/5] Dispatching quality and infrastructure assessment...`

Prompt:
> Read the reference documents first, then analyze this project's repository — all code,
> configuration, and documentation — and produce .aid/knowledge/test-landscape.md,
> .aid/knowledge/security-model.md, .aid/knowledge/tech-debt.md, and .aid/knowledge/infrastructure.md.
> Assess test frameworks, test types, coverage, CI/CD integration.
> Evaluate security: auth, authorization, secrets management, OWASP concerns. Audit tech debt:
> large files, TODO/FIXME density, missing tests, outdated packages, dead code. Classify all
> debt items with risk ratings (Critical/High/Medium/Low).
> Map CI/CD pipelines, Docker/container config, IaC (Terraform, Pulumi, CDK), environments,
> and monitoring.
> When documentation describes testing strategy, security policies, or infrastructure and
> code shows different reality, note the discrepancy — both are valuable findings. Pay special
> attention to external-sources.md — external documentation often contains security policies,
> compliance requirements, deployment guides, and test strategies absent from the code.
>
> REFERENCE DOCUMENTS (read these FIRST before analyzing):
> - .aid/knowledge/project-structure.md — repository structure map
> - .aid/knowledge/external-sources.md — external documentation inventory and findings
> Use these to orient your analysis. External sources may contain information directly relevant
> to YOUR documents that is NOT in the code. Cross-reference external findings with code reality
> and note any discrepancies.
>
> Write only to the .aid/knowledge/ directory.

---

### Wait for ALL Agents

**After dispatching, WAIT. Do not check files. Do not take any action.**

Track agent completions. Print each one as it arrives:
```
Agent "[name]" completed. [N/4] done.
```

**Only proceed to file verification when ALL dispatched agents have reported completion.**

If you see "N local agents still running" in the status bar, you are NOT done. Wait.

---

### Verify All 16 Files

**Only after ALL agents have completed**, check which files exist:

```bash
for f in project-structure.md external-sources.md \
  architecture.md technology-stack.md module-map.md coding-standards.md \
  data-model.md api-contracts.md integration-map.md domain-glossary.md \
  test-landscape.md security-model.md tech-debt.md infrastructure.md \
  ui-architecture.md feature-inventory.md; do
  [ -f ".aid/knowledge/$f" ] && echo "✅ $f" || echo "❌ $f MISSING"
done
```

**If any files are missing:** Re-dispatch ONLY the specific agent responsible for the missing files.
Wait for that agent to complete. Verify again. Repeat until all 16 exist.

**Agent-to-file mapping for re-dispatch:**
| Agent | Files |
|-------|-------|
| discovery-scout | project-structure.md, external-sources.md |
| discovery-architect | architecture.md, technology-stack.md, ui-architecture.md |
| discovery-analyst | module-map.md, coding-standards.md, data-model.md |
| discovery-integrator | api-contracts.md, integration-map.md, domain-glossary.md |
| discovery-quality | test-landscape.md, security-model.md, tech-debt.md, infrastructure.md,
   ui-architecture.md |

When re-dispatching, target ONLY the missing file(s):
> Analyze this project's repository and produce ONLY .aid/knowledge/{missing-file}.md. [original prompt for that area]. Write only to the .aid/knowledge/ directory.

---

### Step 6: Generate README.md and INDEX.md

The orchestrator (you) generates these two documents directly — they are small and require
reading across all previously produced KB documents.

**.aid/knowledge/README.md** — completeness tracking table and revision history:
```markdown
# Knowledge Base

## Completeness

| Document | Status | Notes |
|----------|--------|-------|
| project-structure.md | ✅ Complete | Pre-scan: repository structure map |
| external-sources.md | ✅ Complete | Pre-scan: external documentation inventory |
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
| ui-architecture.md | ✅ Complete | |
| feature-inventory.md | ⚠️ Pending Q&A | Populated after user provides feature list |

## Revision History

| Date | Documents Updated | Notes |
|------|-------------------|-------|
| {date} | All (initial discovery) | |
```

**.aid/knowledge/INDEX.md** — 2-3 line summary of every KB document for agent self-service:
```markdown
# Knowledge Base Index — {Project Name}

Use this index to find the right document before making assumptions.
If your task touches an area covered here, read the relevant document first.

| Document | Summary |
|----------|---------|
| project-structure.md | {2-3 line summary of repo structure, key directories, detected tech} |
| external-sources.md | {2-3 line summary of external documentation sources, or "none provided"} |
| architecture.md | {2-3 line summary of patterns found and structure} |
| technology-stack.md | {2-3 line summary of stack — mention that it contains build + lint commands} |
| module-map.md | {2-3 line summary of modules} |
| coding-standards.md | {2-3 line summary of key conventions} |
| data-model.md | {2-3 line summary of data model} |
| api-contracts.md | {2-3 line summary of API surface} |
| integration-map.md | {2-3 line summary of integrations} |
| domain-glossary.md | {2-3 line summary of key terms} |
| test-landscape.md | {2-3 line summary of test coverage — mention that it contains test commands} |
| security-model.md | {2-3 line summary of security posture} |
| tech-debt.md | {2-3 line summary of debt and risk} |
| infrastructure.md | {2-3 line summary of infrastructure} |
| ui-architecture.md | {2-3 line summary of UI architecture, or "backend-only — no frontend"} |
| feature-inventory.md | {2-3 line summary of features listed, or "Pending — awaiting user input via Q&A"} |
```

Regenerate INDEX.md on every discovery run (full or targeted).

**.aid/knowledge/feature-inventory.md** — copy the template from `../templates/feature-inventory.md`.
This file is populated during the Q&A → FIX cycle (not during GENERATE), but must exist
for the state machine to count all 16 documents as present.

---

### Step 6b: Update DISCOVERY-STATE.md with Q&A

After README.md and INDEX.md are generated, **update** the existing
`.aid/knowledge/DISCOVERY-STATE.md` with Q&A questions collected from the subagents.

**⚠️ Do NOT recreate this file from the template.** It was created by `/aid-init` with
Minimum Grade, Project Type, and External Documentation from the user. Overwriting it
would lose that metadata.

1. Read `.aid/knowledge/.scout-questions.tmp` (written by discovery-scout)
2. Read ALL other KB documents and extract any questions, uncertainties, or TODOs they flagged
3. Consolidate all questions into the DISCOVERY-STATE.md `## Q&A` section with sequential IDs (Q1, Q2, ...)
4. Delete `.aid/knowledge/.scout-questions.tmp`

**Update the existing DISCOVERY-STATE.md:**

- Set `**Grade:**` to `Pending` (was `Not Started`)
- **Preserve** `**Minimum Grade:**`, `**Project Type:**`, `**User Approved:**`, and
  `## External Documentation` — these come from init and must not be changed
- If `--grade` was provided, update `**Minimum Grade:**` to the new value
- Replace `## Q&A` section content with consolidated questions from scouts and KB docs.
  Each question follows this format:

  ```markdown
  ### Q1
  - **Category:** {e.g., Architecture}
  - **Impact:** {High|Medium|Low}
  - **Status:** Pending
  - **Context:** {why this question matters}
  - **Suggested:** {answer if inferrable from repository, or "—"}
  - **Question:** {the actual question}
  ```

**Required Questions:**

After consolidating subagent questions, inject the following Required Q&A entry
if not already present:

- **Category:** Features
- **Impact:** Required
- **Status:** Pending
- **Context:** The feature inventory cannot be generated without user input.
- **Suggested:** {If the scout or other agents identified likely features from routes,
  controllers, or UI screens, list them here as a starting point. Otherwise "—"}
- **Question:** (adapt to project type from DISCOVERY-STATE.md)
  - Web app / SaaS: "What are the main features or capabilities users can access in this application?"
  - API / Backend service: "What are the main services or capabilities this system provides to its consumers?"
  - Library / SDK: "What are the main capabilities or modules this library offers?"
  - Mobile app: "What are the main features or screens in this app?"
  - CLI tool: "What are the main commands or workflows this tool supports?"
  - If project type is unclear: "What are the main features or capabilities of this system?"

Print: `[DISCOVERY-STATE] Updated with {N} Q&A questions. Grade: Pending.`

---

### Step 7: Update Project Config Files

Scan the project root for `CLAUDE.md`. Replace any `<!-- AID:DISCOVER ... -->`
placeholders with real data from the analysis:

- **Project description** — project name and one-line description
- **Project Overview** — project name, purpose, tech stack, target platform
- **Build & Test** — actual build, test, and lint commands (from build scripts, CI config, package manager)
- **Code Conventions** — key naming patterns, formatting rules, idioms found in code
- **Architecture** — high-level summary (layers, modules, entry points)

Keep the `<!-- AID:DISCOVER ... -->` comment above each section so future re-discoveries can update them.
Replace only the `(pending discovery)` placeholder lines with real content.
If a field cannot be determined, leave it as `(not found — see DISCOVERY-STATE.md Q&A)`.

---

### Step 8: Final Verification

List all 16 expected KB documents. Check each exists. Report any missing.

Print: `[16/16] Generation complete — Knowledge Base ready. Run /aid-discover again to review.`

If any documents are missing, report them and offer to re-dispatch the responsible subagent.

---

## Mode: REVIEW

All 16 KB documents exist. Grade them.

### Step 1: Dispatch the Reviewer

Dispatch **discovery-reviewer** subagent.

Print: `[Review 1/2] Reviewing Knowledge Base quality...`

**⚠️ CLEAN CONTEXT:** Do NOT include any information about the generation process,
which agents ran, what was easy or hard, or any prior state. The reviewer must
evaluate the KB purely on what's on disk — as if a stranger wrote it.

Prompt to pass to the subagent:
> Review every document in .aid/knowledge/ for quality. Be AGGRESSIVE — a lenient review is worse
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
>      extractable from the repository is [HIGH].
>
> 2. **Completeness** — Does the document cover everything its title promises?
>    - Compare against what a developer working on this project would need.
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
>    understand a module in this project.
>    - Would this document let you act correctly without re-discovering?
>    - Can you find the specific information you need quickly from the structure?
>    - Are the claims grounded in specific locations (file paths, class names) or
>      generic statements that could apply to any project?
>
> 6. **Meta-document integrity** — INDEX.md, README.md, and CLAUDE.md are
>    derived from the 16 primary documents.
>    - Do their summaries and values accurately reflect the current primary doc content?
>    - Is placeholder text or template markers still present?
>    - Are questions marked Pending in the Q&A section of DISCOVERY-STATE.md actually still unanswerable from the repository?
>
> **Grading:** Use the universal rubric (read `../templates/grading-rubric.md`).
> Classify every issue as [MINOR], [LOW], [MEDIUM], [HIGH], or [CRITICAL].
> Grade is CALCULATED from worst issue severity + quantity. Worst issue dominates.
> A+ = zero issues. F = missing/empty/non-functional.
>
> **Minimum 15 spot-checks** (verify claims against actual code). At least 5 must be version verifications.
>
> **After grading, add new questions to the `## Q&A` section of DISCOVERY-STATE.md** for any
> information gaps found during review that cannot be resolved from the repository. These become
> Q&A items for the user. Use the next sequential Q{N} ID (continuing from existing entries),
> categorize by area, and assign impact levels (High/Medium/Low). Only add questions for things
> genuinely needing human input — if you can grep the answer, fix it in the review instead.
>
> Write the review results (grades, issues, spot-checks) to .aid/knowledge/DISCOVERY-STATE.md,
> preserving the existing `## Q&A` section and adding to it. Update `**Grade:**` from `Pending`
> to the actual grade.

Wait for completion.

---

### Step 2: Post-Process DISCOVERY-STATE.md

Read `.aid/knowledge/DISCOVERY-STATE.md`. Verify it contains:
- [ ] Grade for every document (16 KB docs + CLAUDE.md + INDEX.md + README.md)
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

DISCOVERY-STATE.md exists, the grade is below minimum, and the `## Q&A` section of
DISCOVERY-STATE.md contains entries with `**Status:** Pending`.

The Q&A mode presents questions to the user **one at a time**, collects answers, and updates
DISCOVERY-STATE.md directly.

### Step 1: Load and Filter Questions

Read the `## Q&A` section of `.aid/knowledge/DISCOVERY-STATE.md`. Collect all entries with `**Status:** Pending`.

**Before presenting each question, apply the filter:**

1. **Check KB** — Is the answer already in another KB document? → Change status to `Answered`,
   fill in the answer from the KB, set `Applied to` field. Skip to next question.
2. **Check Q&A section** — Was this already asked and answered in a previous cycle?
   → Skip (should not happen if statuses are tracked correctly, but guard against duplicates).
3. **Inferrable from context?** — Can the answer be reasonably deduced from repository content?
   → Keep the question but ensure it has a `**Suggested:**` answer. The user confirms or corrects.

After filtering, sort remaining Pending questions by impact: **High → Medium → Low**.

Print: `[Q&A] {N} questions for user input. Asking one at a time...`

If zero questions remain after filtering, print: `[Q&A] All questions resolved from KB. Proceeding to Fix.`
and skip to the end of Q&A mode.

### Step 2: Ask One Question at a Time

For each Pending question, present it to the user in this format:

```
Q{N}: [{Category}: {Impact}] {question text}

Context: {context from the Q&A entry}

Suggested: {suggested answer, if present}

[1] Skip / Not applicable
[2] Accept suggestion (only shown if Suggested exists)
[3] Your answer: ___
```

**Wait for the user's response before asking the next question.**

### Step 3: Record the Answer

Based on the user's response, update the Q&A entry in `.aid/knowledge/DISCOVERY-STATE.md`:

- **User chose [1] (Skip):** Set `**Status:** Skipped`
- **User chose [2] (Accept suggestion):** Set `**Status:** Answered`, copy the suggested text to `**Answer:**`
- **User typed an answer [3]:** Set `**Status:** Answered`, record their text in `**Answer:**`

**Important:** Write the update to the file immediately after each answer. Do not batch.

### Step 4: Continue or Exit

After recording, move to the next Pending question. Repeat Steps 2-3.

When all Pending questions have been addressed (answered or skipped):

Print: `[Q&A] Complete. {answered} answered, {skipped} skipped. Run /aid-discover again to fix.`

The next run will detect no Pending Q&A and enter FIX mode. The FIX will use the answers
from DISCOVERY-STATE.md Q&A section to improve the KB documents.

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
2. Read the `## Q&A` section of DISCOVERY-STATE.md for Answered entries that apply to this document
3. Read the relevant source code to gather missing information
4. Edit the KB document to address the issues — combining review findings WITH user answers from DISCOVERY-STATE.md Q&A. A review finding ("auth section is shallow") + a user answer ("OAuth2 with Azure AD") together produce a precise, evidence-backed fix.
5. **REMOVE the fixed issue lines** from the Issues Found section of DISCOVERY-STATE.md
6. For each Answered Q&A entry that was incorporated, update its `**Applied to:**` field with the target document name and cycle number
7. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

**IMPORTANT:** When an issue is fixed, its line MUST be removed from the Issues Found section.
DISCOVERY-STATE.md always reflects the CURRENT state, not history. History is tracked in the
Review History table.

**IMPORTANT:** Answered Q&A entries in DISCOVERY-STATE.md are fix items too. Treat them with the
same priority as review findings. Cross-reference findings and answers — they often complement
each other (the finding says WHERE something is weak, the answer says WHAT to put there).

**Feature Inventory Generation:** When processing Q&A answers with **Category: Features**:
1. Cross-reference the user's feature list with: `api-contracts.md`, `module-map.md`,
   `domain-glossary.md`, `ui-architecture.md`, `data-model.md`
2. Generate/update `.aid/knowledge/feature-inventory.md` with an enriched table
3. Each feature row: sequential #, feature name, description, Status (Active), key modules
   from module-map, key endpoints from api-contracts, data entities from data-model
4. Mark the Features Q&A entry as Applied to: `feature-inventory.md`

---

### Step 2b: Verify Meta-Documents (MANDATORY after every fix pass)

Fixes to primary KB documents can invalidate derived/meta documents. After ALL primary fixes,
verify and update the following 5 meta-documents **in this order:**

1. **DISCOVERY-STATE.md Q&A** — Do any fixed issues resolve pending questions? Update their status. Did fixes reveal new unknowns? Add them as new Q&A entries with the next sequential ID.
2. **INDEX.md** — Do summaries still match the updated document content? Update any stale summaries.
3. **README.md** — Does the completeness table (status/gaps) still reflect reality? Update statuses.
4. **CLAUDE.md** — Did fixes change build commands, conventions, architecture, or other AID placeholders? Update if stale.

Print: `[Fix] Verifying 4 meta-documents...`

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

Please review the documentation in .aid/knowledge/ and let us know if there is anything
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
  - Add the consideration as a new Q&A entry in the `## Q&A` section of `.aid/knowledge/DISCOVERY-STATE.md` with:
    - Next sequential Q{N} ID
    - `[User Feedback: High]` category and impact
    - `**Status:** Pending`
    - The user's text as the context
  - Print: `[Approval] Consideration recorded as Q{N}. Run /aid-discover again to address it.`
  - The next run will detect Pending Q&A and re-enter the cycle (Q&A or FIX depending on
    whether it needs user input or can be resolved from the repository).

---

## Mode: DONE

DISCOVERY-STATE.md exists, the grade meets or exceeds the minimum, and the user has approved.

**Ask first:** _"Discovery is complete and approved (Grade: {grade}). Do you want to reopen it for review?
Is there something specific you want to re-examine?"_

If user confirms → set state to REVIEW, proceed to State 2.
If user has a specific concern → record it as context for the reviewer.
If user says no → print: `✅ Discovery complete. Grade: {grade}. Minimum: {minimum}. KB approved and ready for the Interview phase.`

---

## Targeted Discovery (Re-entry)

When a GAP.md or IMPEDIMENT.md triggers re-discovery of a specific area:

1. Read the GAP/IMPEDIMENT to understand exactly what's missing
2. Identify which subagent owns the missing documents:
   - `project-structure.md`, `external-sources.md` → dispatch discovery-scout
   - `architecture.md`, `technology-stack.md` → dispatch discovery-architect
   - `module-map.md`, `coding-standards.md`, `data-model.md` → dispatch discovery-analyst
   - `api-contracts.md`, `integration-map.md`, `domain-glossary.md` → dispatch discovery-integrator
   - `test-landscape.md`, `security-model.md`, `tech-debt.md`, `infrastructure.md` → dispatch discovery-quality
   - `feature-inventory.md` → route through DISCOVERY-STATE Q&A with Category: Features
3. Dispatch ONLY the relevant subagent for the area that needs updating
4. Regenerate README.md and INDEX.md (orchestrator does this directly)
5. Update `.aid/knowledge/README.md` revision history with the targeted update
6. Delete `.aid/knowledge/DISCOVERY-STATE.md` so the next run re-reviews
7. Report completion to the calling phase

---

## Quality Checklist

- [ ] No overlap between KB documents
- [ ] Claims grounded in code evidence (file paths, line numbers)
- [ ] Inferred info marked with ⚠️
- [ ] DISCOVERY-STATE.md Q&A section captures everything needing human input in structured format
- [ ] external-sources.md documents all external sources (or states none were provided)
- [ ] README.md reflects completeness status and revision history
- [ ] INDEX.md generated with 2-3 line summaries of every KB document
- [ ] feature-inventory.md exists (template or populated after Q&A)
- [ ] CLAUDE.md placeholders filled with discovered data
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

### project-structure.md
Must have: directory tree (top 3-4 levels with annotations), file counts per major directory,
key files and their purpose (entry points, build files, configs, tests), detected languages
and frameworks, documentation files found in the repository. This is an inventory/map — not
deep analysis. Other agents use this to know WHERE to look.
**Red flags**: Too shallow (just a tree dump without annotations). Missing file counts.
Too deep (analyzing patterns instead of mapping structure). Missing key build/config files.

### architecture.md
Must have: project type, folder structure (annotated), architectural patterns with evidence,
module boundaries, data flow (entry→processing→persistence), DI registration, entry points.
**Red flags**: Generic descriptions without file paths. Missing data flow.

### technology-stack.md
Must have: languages with versions, frameworks with versions (from actual config files),
databases, package managers, build tools, runtime, dev tooling.
Must have: **Build Commands** section with exact build command(s), **Lint Commands** section
with exact lint command(s). These are critical for aid-execute — agents need runnable
commands, not just tool names.
**Red flags**: "⚠️ Version TBD" on things extractable from pom.xml/package.json/manifests.
Missing or vague Build/Lint Commands (e.g., just "Maven" without `mvn clean package`).

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
Must have: **Test Commands** section with exact commands to run all unit tests, per-module
tests, and coverage reports. These are critical for aid-execute — agents need runnable
commands, not just framework names.
**Red flags**: Too short. Missing per-module coverage assessment. Missing or vague Test
Commands (e.g., just "JUnit" without `mvn test`).

### security-model.md
Must have: auth mechanisms, authorization model, secrets management, transport security,
OWASP assessment, access logging.
**Red flags**: Generic OWASP checklist without project-specific assessment.

### tech-debt.md
Must have: categorized by severity (Critical/High/Medium/Low), each with location, risk,
and notes. Observations about overall health.
**Red flags**: Missing severity classification. No actionable locations.

### infrastructure.md
Must have: Source Control section (VCS type, hosting, branch/commit commands), CI/CD pipeline
details, container config, Deployment section (build output type, packaging, publishing target,
versioning scheme, release process), Project Management section (tool or "none", access method,
entity mapping if applicable), artifact repos, runtime config, monitoring, environments.
**Red flags**: Lists tools without explaining how they're configured or connected. Missing Source
Control section or assuming Git without verifying. Missing Deployment section. Project Management
section absent (should explicitly say "none" if no tool is used).

### ui-architecture.md
Must have (if frontend exists): component architecture (tree, composition patterns),
state management (framework, data flow), design system (tokens, library),
routing (router, guards), responsive strategy (breakpoints, device targets),
accessibility (WCAG level, ARIA patterns), styling approach (method, conventions),
build & bundle (bundler, code splitting, lazy loading).
If backend-only: explicitly states "No frontend detected."
**Red flags**: Lists frameworks without explaining patterns. Missing component tree.
Missing state management data flow. No accessibility section.

### feature-inventory.md
Must list ALL features identified by the user. Each feature has description, status, modules,
endpoints, data entities. Red flag: features without module mapping, features with placeholder
descriptions, features obviously missing from user's original list.

### external-sources.md
Must have: list of all external documentation sources provided by the user (if any), with
path, type (file/directory), date provided, accessibility status, and summary of key content.
If no external sources were provided, must explicitly state that all knowledge was derived
from repository content only.
**Red flags**: Missing when external paths were registered in aid-init. No summary of what
was found in external sources. Not reflecting which KB documents reference external content.

### INDEX.md
Must have: accurate 2-3 line summary per document. Summaries must reflect actual content.
**Red flags**: Generic summaries. Summaries that don't match document content.

### README.md
Must have: completeness table, revision history.
**Red flags**: Missing gap acknowledgment.

### CLAUDE.md
Must have: accurate project description, project overview, real build/test commands,
conventions from code, architecture summary, KB reference. No remaining `(pending discovery)` placeholders.
**Red flags**: Placeholder text still present. Commands that wouldn't actually work. Missing key gotchas for agents.
