# State: GENERATE

GENERATE generates KB documents that are missing or still at "Pending" status; it is selected when any of the 16 expected KB documents are absent or contain only the init template placeholder.

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

> **Working directory assumption:** All bash commands in this skill (Step 0c, Step 1, etc.) assume the current working directory is the project root (the directory containing `.aid/`). Scripts are invoked by their location in the install tree (`.claude/scripts/kb/...` for Claude Code, `.codex/scripts/kb/...` for Codex, `.cursor/scripts/kb/...` for Cursor). The skill author references them via `scripts/kb/<name>.sh` — the agent resolves to the correct install-tree path.

▶ build-project-index starting (~30 s)
```bash
bash scripts/kb/build-project-index.sh \
  --root . \
  --output .aid/generated/project-index.md
```
✓ build-project-index done (record actual time)

Print: `[0c] Building project index...` then on completion `[0c] Project index ready (N files, M lines)`.

This is a deterministic shell script — no LLM dispatch. It runs fast (typically under 30 seconds even on large repos). The resulting `project-index.md` is markdown so humans can scan it.

If the index fails (e.g., empty repo, permission errors): log a warning and continue. Sub-agents will fall back to direct enumeration.

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

Run `scripts/kb/verify-claims.sh .aid/knowledge/` to check all 16 files exist.

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

Run `scripts/kb/verify-claims.sh .aid/knowledge/` one final time.
Print: `[16/16] Generation complete — Knowledge Base ready. Run /aid-discover again to review.`

Print: `[State: GENERATE] complete.`

**Advance:** Next: [State: REVIEW] — run /aid-discover again
