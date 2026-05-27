# State: FIX

FIX applies Q&A answers and reviewer feedback to bring KB documents up to minimum grade; it is selected when the grade is below minimum and no Pending Q&A entries remain.

### Step 0: Partition Findings by KB File (Parallel-FIX prep)

Before dispatching any sub-agent, **partition the reviewer's findings by KB file**. The output is a map `{file: [findings]}` — every finding belongs to exactly one file. Each file's bucket holds its entire finding list.

**Why partition?** FIX dispatches **one sub-agent per affected file**, all in parallel. Each agent owns its file exclusively (single-writer per file is the parallelism-safety invariant). The orchestrator only serializes at the commit/push boundary (Step 4).

### Step 1: Identify Documents Below Threshold

Read `.aid/knowledge/STATE.md` `## KB Documents Status`. List documents below minimum grade.
Prioritize: [CRITICAL] → [HIGH] → [MEDIUM].
Print: `[Fix] {N} documents below {minimum}. Dispatching {N} sub-agents in parallel...`

### Step 2: Dispatch Parallel FIX Agents (one per affected file)

**Single message, multiple `Agent` tool calls** — all agents run concurrently. For each file with findings:

- **Subagent type**: `tech-writer` for narrative KB docs; `researcher` if depth investigation is needed.
- **Prompt contents**:
  1. The file path being edited.
  2. The file's COMPLETE finding list (severity-tagged, source-tagged).
  3. Any Answered Q&A entries from `STATE.md ## Q&A` that this file should incorporate.
  4. Pointer to relevant source files for verification.
  5. **Manual-edits directive** — the agent MUST use the `Edit` tool to apply targeted changes one-by-one. **NO regex scripts.** Scripts generalize and produce new defects:
     - Replace historical-narrative values (e.g. cycle-log entries)
     - Mangle section headers via context-bleed in regex matches
     - Embed authoring annotations (`(line cite stripped...)`) into user-facing prose
     - Miss inline-narrative variants the anchor didn't anticipate
  6. **Commit-stage only** directive — the agent leaves changes unstaged or staged-but-not-committed. The orchestrator owns the final `git commit` + `git push` step.

- **L2+L3 trace per agent** — each agent gets its own pre-created heartbeat file `.aid/.heartbeat/fix-{agent-type}-{file-slug}-{ts}.txt` and three SEPARATE `Bash(..., run_in_background=true)` timer dispatches per the Dispatch Protocol above.

Print before dispatch:
```
[Fix] Dispatching {N} parallel FIX agents:
  ▶ tech-writer (file: architecture.md, ~{ETA}, heartbeat: ...) starting
  ▶ tech-writer (file: module-map.md, ~{ETA}, heartbeat: ...) starting
  ...
```

**Feature Inventory Generation:** if Features Q&A is in the answered set, the file-agent for `feature-inventory.md` should cross-reference api-contracts.md, module-map.md, domain-glossary.md, ui-architecture.md, data-model.md while editing.

### Step 3: Wait for ALL Parallel Agents

Do NOT proceed to Step 4 until every dispatched agent has reported completion. For each completion, surface `✓ tech-writer (file: X) done in {actual}` and append a calibration row.

### Step 4: Aggregate, Verify, Commit (Sequential — single writer)

After ALL parallel agents return:
1. **REMOVE fixed issue lines** from `.aid/knowledge/STATE.md` `## Issues` (orchestrator only — agents never touch STATE.md).
2. Update `**Applied to:**` for each incorporated Q&A answer in `STATE.md ## Q&A`.
3. **Regenerate all registered generated files (per principles.md P3 — auto-gen-last).** Read `.claude/templates/generated-files.txt`. For each non-comment line, parse `output-path|build-command` and execute the build command. This ensures `metrics.md`, `INDEX.md`, `project-index.md` (and any future registered builders) reflect the FINAL post-fix state of the KB:
   ```bash
   while IFS='|' read -r out_path build_cmd; do
     case "$out_path" in ''|\#*) continue ;; esac
     out_path="${out_path#"${out_path%%[![:space:]]*}"}"
     out_path="${out_path%"${out_path##*[![:space:]]}"}"
     echo "[Fix] Regenerating $out_path ..."
     eval "$build_cmd" || echo "[Fix] WARNING: build failed for $out_path"
   done < .claude/templates/generated-files.txt
   ```
4. Run `bash .claude/scripts/kb/verify-claims.sh` — expect exit 0. (The verify script's [GEN-MISSING] check will now find the freshly-regenerated files; if any are still missing, the corresponding build command failed in Step 3.)
5. Run any smoke tests relevant to changes.
6. Single `git commit` listing which files each agent touched + the regenerated outputs in `.aid/generated/`.
7. `git push`.

Print: `[Fix] Improving {document}... {old grade} → {new grade}` for each.

### Step 5: Verify Meta-Documents (MANDATORY after every fix pass)

After ALL primary fixes, verify and update in order:
1. **`.aid/knowledge/STATE.md` Q&A** — resolved questions? new unknowns?
2. **INDEX.md** — summaries still match?
3. **README.md** — completeness table still accurate?
4. **CLAUDE.md** — build commands, conventions, architecture stale?

Print: `[Fix] Verifying 4 meta-documents...`

### Step 6: Re-Review (MANDATORY — Do NOT Self-Evaluate)

**Dispatch discovery-reviewer again.** The fixer CANNOT evaluate its own work.

Print: `[Fix 2/3] Re-reviewing after fixes...`

Read `references/reviewer-prompt.md` for the full prompt. Same contamination prevention rules as REVIEW mode.

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 7: Post-Fix Update

Read new `.aid/knowledge/STATE.md`. Verify Review History preserved (append, not replace under `## Review History`).

Print: `[Fix 3/3] Complete. Grade: {old} → {new}. Run /aid-discover again to {fix remaining issues|proceed}.`

Print: `[State: FIX] complete.`

**Advance:** Next: [State: APPROVAL] — run /aid-discover again
