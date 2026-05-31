# State: GENERATE

GENERATE generates KB documents that are missing or still at "Pending" status; it is selected when any declared KB document is absent or contains only the init template placeholder.

> **Shared snippet:** The `synth_default_seed` and `resolve_doc_set` bash functions used
> throughout this state are defined in `references/doc-set-resolve.md`. Inline them into
> any bash context that needs them; they are the shared accessor for the declared doc-set.
> `REPO` must be set to the repository root (e.g. `REPO="$(pwd)"`) before calling.

### Step 0: Check Existing KB

Resolve the declared doc-set (see `references/doc-set-resolve.md`):
```bash
raw="$(bash canonical/scripts/config/read-setting.sh \
        --path discovery.doc_set 2>/dev/null || true)"
# N = number of declared docs (default seed when section unset)
declared_filenames="$(resolve_doc_set "$raw" | cut -f1)"
N="$(echo "$declared_filenames" | grep -c .)"
```

Scan `.aid/knowledge/` — files with only init template (`❌ Pending`) are treated as MISSING.
Print: `[0/N] Checking existing KB...` (where N = declared-set size at runtime)
If ALL declared docs have real content and no `--reset`, skip to Step 6.

### Step 0b: Read External Documentation Paths

Read `.aid/knowledge/STATE.md` `## External Documentation` for paths from `aid-config`. Verify accessible:
```bash
test -r <path> && echo "✅ $path" || echo "❌ $path — no longer accessible"
```
Store accessible paths for the scout prompt. Warn on inaccessible (but continue).

### Step 0c: Build Project Index (Pre-pass)

Run the lightweight file-index pre-pass before dispatching sub-agents. This produces a structured inventory consumed by all 5 sub-agents, eliminating duplicated `find`/`wc` work across parallel agents.

> **Working directory assumption:** All bash commands in this skill assume the current working directory is the project root (the directory containing `.aid/`). Scripts are written here as `canonical/scripts/...` paths; the renderer rewrites them to the profile's install-tree root at render time (`.claude/scripts/...` for Claude Code, `.agents/scripts/...` for Codex assets, `.cursor/scripts/...` for Cursor). No runtime resolution needed.

▶ build-project-index starting (~30 s)
```bash
bash canonical/scripts/kb/build-project-index.sh \
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

### Steps 2-5: Dispatch 4 Subagents in Parallel (data-driven from declared set)

**Only after Step 1 completes.** Dispatch with `background: true`.

**Compute each agent's target list from the declared set** (§2.5 mapping-honors-declared-set):

```bash
# owns-<agent>: filenames assigned to this agent in the declared set
# ∩ missing-on-disk: only dispatch for docs not already on disk with real content
for agent in discovery-architect discovery-analyst discovery-integrator discovery-quality; do
  owns="$(resolve_doc_set "$raw" | awk -F'\t' -v a="$agent" '$2==a{print $1}')"
  # Intersect with missing-on-disk (files absent or containing only "❌ Pending")
  targets=""
  while IFS= read -r fn; do
    [ -z "$fn" ] && continue
    f=".aid/knowledge/$fn"
    if [ ! -f "$f" ] || grep -q '❌ Pending' "$f" 2>/dev/null; then
      targets="${targets:+$targets }$fn"
    fi
  done <<<"$owns"
  # If the computed list is empty, do NOT dispatch this agent (no-hang on omission).
  # If non-empty, include it in the parallel dispatch with its target list.
  eval "targets_${agent//-/_}=\"$targets\""
done
```

- An agent whose computed list is **empty is NOT dispatched** (no hang on an intentionally-omitted doc — FR-P1-6).
- An **added** doc whose `owner` is some agent is included in that agent's list (dispatch on addition — FR-P1-6).
- A custom doc owned by the architect fallback rides on the `discovery-architect` dispatch.

**Every agent receives the foundation reference block** (appended to prompt):
```
REFERENCE DOCUMENTS (read these FIRST before analyzing):
- .aid/knowledge/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
- .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
- .aid/knowledge/external-sources.md — external documentation inventory and findings
```

In the agent prompt, include the computed target file list (from `targets_<agent>` above) and
the prompt section from `references/agent-prompts.md`:

| Step | Agent | Default-seed target files (illustrative — actual targets from declared set) | Prompt Section |
|------|-------|----------------------------------------------------------------------------|----------------|
| [2/5] | discovery-architect | architecture.md, technology-stack.md | `references/agent-prompts.md` → `## Architect` |
| [3/5] | discovery-analyst | module-map.md, coding-standards.md, schemas.md | `references/agent-prompts.md` → `## Analyst` |
| [4/5] | discovery-integrator | pipeline-contracts.md, integration-map.md, domain-glossary.md | `references/agent-prompts.md` → `## Integrator` |
| [5/5] | discovery-quality | test-landscape.md, tech-debt.md, infrastructure.md | `references/agent-prompts.md` → `## Quality` |

The actual target files for each agent are derived at runtime from the declared set, not hard-coded above.

**Sub-agents may delegate mechanical work** to the Small-tier utility agents (`simple-extractor`, `simple-glob`, `simple-formatter`) for high-volume extraction or templating. The synthesis stays at the sub-agent's tier; only the grunt work delegates. See `agents/simple-*/README.md` for the caller contract.

Before dispatching, print the AC4 sub-unit snapshot header for the GENERATE state (listing only agents with a non-empty target list):
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

### Verify All Declared Files

Run the following to confirm all declared docs are present:
```bash
# list-filenames accessor: all filenames in the declared set
declared_filenames="$(resolve_doc_set "$raw" | cut -f1)"
N="$(echo "$declared_filenames" | grep -c .)"
actual="$(ls .aid/knowledge/*.md 2>/dev/null | xargs -I{} basename {} | sort)"
# Cross-check: confirm count == N and each declared filename is on disk
echo "$declared_filenames" | sort | diff - <(echo "$actual" | grep -Ff <(echo "$declared_filenames" | sort))
```

Confirm `count == size(list-filenames)` (not a literal) and cross-check names against the
`list-filenames` accessor — an omission lowers the target, an addition raises it; neither stalls.

**If any missing:** Re-dispatch ONLY the responsible agent per the `owns-<agent>` accessor and
the **Targeted Discovery** section of `SKILL.md`. Wait, verify again. Repeat until all declared files exist.

Semantic verification of the docs (frontmatter compliance, contract claims, cross-doc consistency, spot-checks against source) happens in the **REVIEW** state, dispatched as the `discovery-reviewer` sub-agent — not as a separate shell script.

### Step 6: Generate README.md and INDEX.md

The orchestrator generates these directly — they require reading across all KB documents.

**.aid/knowledge/README.md** — completeness tracking table and revision history:
- Table with all declared documents, status, and notes
- Revision history table with dates and update descriptions

**.aid/knowledge/INDEX.md** — 2-3 line summary of every declared KB document for agent self-service.
Regenerate on every discovery run.

**.aid/knowledge/feature-inventory.md** — copy template from `../../templates/feature-inventory.md`.
Populated during Q&A → FIX cycle, but must exist for state machine.

### Step 6b: Update `.aid/knowledge/STATE.md` with Q&A

**⚠️ Do NOT recreate this file.** It was created by `/aid-config` with metadata. Update only:

1. Read `.aid/knowledge/.scout-questions.tmp` (from scout)
2. Read all KB documents for flagged questions/uncertainties/TODOs
3. Consolidate into `## Q&A (Pending)` section with sequential IDs (Q1, Q2, ...)
4. Delete `.scout-questions.tmp`
5. Set `**Grade:**` to `Pending` (was `Not Started`)
6. **Preserve** `**Project Type:**`, `**User Approved:**`, `## External Documentation` (the `**Minimum Grade:**` field is now in `.aid/settings.yml` — read it via `bash canonical/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A`)
7. If `--grade` provided, update `.aid/settings.yml` via `/aid-config` (NOT STATE.md)

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

### Step 8: Final Wrap-up

Print: `[N/N] Generation complete — Knowledge Base ready. Run /aid-discover again to review.` (where N = declared-set size)

(File-presence was confirmed in the **Verify All Declared Files** step above; semantic quality is the **REVIEW** state's job — no additional pre-REVIEW check needed.)

Print: `[State: GENERATE] complete.`

**Advance:** **CHAIN** → [State: REVIEW] (continue inline).
