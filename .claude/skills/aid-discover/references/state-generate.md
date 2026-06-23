# State: GENERATE

GENERATE generates KB documents that are missing or still at "Pending" status; it is selected when any declared KB document is absent or contains only the init template placeholder.

> **Shared snippet:** The `synth_default_seed` and `resolve_doc_set` bash functions used
> throughout this state are defined in `references/doc-set-resolve.md`. Inline them into
> any bash context that needs them; they are the shared accessor for the declared doc-set.
> `REPO` must be set to the repository root (e.g. `REPO="$(pwd)"`) before calling.

### Step 0: Check Existing KB

Resolve the declared doc-set (see `references/doc-set-resolve.md`):
```bash
raw="$(bash .claude/aid/scripts/config/read-setting.sh \
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

> **Working directory assumption:** All bash commands in this skill assume the current working directory is the project root (the directory containing `.aid/`). Scripts are written in `canonical/scripts` form in the source; the renderer rewrites them to the profile's install-tree nested path at render time (`.claude/aid/scripts/...` for Claude Code, `.codex/aid/scripts/...` for Codex, `.cursor/aid/scripts/...` for Cursor). No runtime resolution needed.

▶ build-project-index starting (~30 s)
```bash
bash .claude/aid/scripts/kb/build-project-index.sh \
  --root . \
  --output .aid/generated/project-index.md
```
✓ build-project-index done (record actual time)

Print: `[0c] Building project index...` then on completion `[0c] Project index ready (N files, M lines)`.

This is a deterministic shell script — no LLM dispatch. It runs fast (typically under 30 seconds even on large repos). The resulting `project-index.md` is markdown so humans can scan it.

If the index fails (e.g., empty repo, permission errors): log a warning and continue. Sub-agents will fall back to direct enumeration.

### Step 0d: Propose & Confirm Doc-Set

**PAUSE-FOR-USER-DECISION** (contracted checkpoint per SPEC feature-004 §3.1 and
`.claude/aid/templates/state-machine-chaining.md`).

#### Idempotent re-entry

Check whether `.aid/settings.yml` already carries a `discovery.doc_set` section from a prior run:

```bash
raw="$(bash .claude/aid/scripts/config/read-setting.sh \
        --path discovery.doc_set 2>/dev/null || true)"
```

- **Prior set exists (`raw` non-empty):** Skip the inference step below — show the existing set as a diff against the default seed and ask the user to confirm or edit it. This is idempotent re-entry.
- **No prior set (`raw` empty):** Proceed to the inference step.

#### Inference step (first run only)

Read `.aid/generated/project-index.md` — a **file inventory** (paths, sizes, languages, directory tree) built in Step 0c. This is NOT a project-type label. Use it to **infer** a proposed doc-set as: default seed + deltas (add / remove / rename / repurpose).

Inference heuristics (agent judgment — not a classifier, no seed-files, no archetype fixtures):

- **No test directories and no test-framework config** (e.g., no `package.json`/`pytest.ini`/`*.test.*`) → propose marking `test-landscape.md` as `conditional` or dropping it from the required set.
- **No external service integrations, no API surface** → propose `integration-map.md` as `conditional`.
- **Docs-only or research tree** (no source files, only `.md`/text) → propose a research-oriented set: drop `technology-stack.md`, `schemas.md`, `coding-standards.md`; add any project-specific docs evident from the file tree.
- **Non-trivial CI/CD configuration present** → ensure `infrastructure.md` is `required`.
- **Custom doc evident in the tree** (e.g., a docs sub-directory with a non-standard name) → propose adding it with an appropriate existing agent as owner.
- **When uncertain, prefer the default seed.** The user-confirm step is the safety net; a conservative proposal is always acceptable.

The inferred deltas are expressed relative to the default seed (as defined by `synth_default_seed`). No static pick-list, no archetype taxonomy.

#### Present the proposal

Display the proposed doc-set as a **diff against the default seed**:

```
Proposed doc-set (diff vs. default seed)
─────────────────────────────────────────
  (no change)  architecture.md           aid-researcher-architecture    required
  (no change)  technology-stack.md       aid-researcher-architecture    required
  (no change)  module-map.md             aid-researcher-analyst         required
  ...
- (drop)       test-landscape.md         aid-researcher-quality         required
+ (add)        research-notes.md         aid-researcher-analyst         required
```

(Omit unchanged lines if the list is long; a summary line "N unchanged" is acceptable.)

Then ask the user to confirm or edit:

> **Doc-set proposal ready.** Review the diff above.
> - Type **`confirm`** (or press Enter) to accept as proposed.
> - Or provide edits in the pipe-delimited format: `filename|owner|presence[:when]` — one entry per line — and the confirmed set will be written to `.aid/settings.yml`.

**This is a genuine PAUSE-FOR-USER-DECISION.** Stop here after presenting the proposal.

**Advance:** Stop here (contracted checkpoint per SPEC feature-004 §3.1 and
`.claude/aid/templates/state-machine-chaining.md`). Re-run `/aid-discover` after confirming the
proposed doc-set to continue to [State: GENERATE — Step 1].

#### On confirm (resume path)

When the user re-runs `/aid-discover` and the session resumes after the pause:

1. Read the user's response:
   - **`confirm` or default (no change to proposal):** If the proposal equals the default seed, **write nothing** to `.aid/settings.yml` (absent section ⇒ default seed — AC: accepting default writes nothing). If the proposal differs from the default, write the confirmed set to `.aid/settings.yml` as described below.
   - **User-provided edits:** Accept the edits verbatim; write the resulting set to `.aid/settings.yml`.

2. Write/update `discovery.doc_set` in `.aid/settings.yml` (only when the confirmed set differs from the default):

   ```yaml
   discovery:
     doc_set:
       - architecture.md|aid-researcher-architecture|required
       - technology-stack.md|aid-researcher-architecture|required
       # ... one entry per line: filename|owner|presence[:when]
       # (inline comments are stripped by read-setting.sh:197 — safe)
   ```

   Write is idempotent: if the section already exists (re-entry), overwrite it with the confirmed set.

3. Re-resolve `raw` from the (now-updated) `.aid/settings.yml`:

   ```bash
   raw="$(bash .claude/aid/scripts/config/read-setting.sh \
           --path discovery.doc_set 2>/dev/null || true)"
   declared_filenames="$(resolve_doc_set "$raw" | cut -f1)"
   N="$(echo "$declared_filenames" | grep -c .)"
   ```

4. **CHAIN → Step 1** with the confirmed set driving the data-driven dispatch (Steps 2-5 §2.5).

### Step 0e: Harvest Coined Terms

Run the deterministic coined-term harvest after the doc-set is confirmed and before the
researcher fan-out. This step has zero LLM cost and produces the
`.aid/generated/candidate-concepts.md` anchor that all deep-dive agents receive.

Print: `[0e] Harvesting coined terms...`

```bash
bash .claude/aid/scripts/kb/harvest-coined-terms.sh \
  --root . \
  --output .aid/generated/candidate-concepts.md \
  --denylist .claude/aid/scripts/kb/coined-term-denylist.txt \
  --top 60
```

On completion print: `[0e] Candidate concepts ready (K candidates, M cross-source)`.

**Degrade-gracefully:** if the script fails (empty repo, no git, permission error) log a
warning and continue with an empty `candidate-concepts.md` (same pattern as Step 0c). Never
block the fan-out on a harvest failure.

> The `harvest` partition of `candidate-concepts.md` is deterministic and byte-reproducible.
> The `synthesis` partition (tagged `Source = synthesis`) is appended by `aid-architect` in
> Step 5b. Both partitions feed the closure loop term universe and f005's teach-back gate.

### Step 0f: Recon Classify + Triage (path decision)

Run the deterministic recon pre-pass after Step 0e (RM4 is now available) and before Step 1
(the fan-out is what the path scales -- decide before dispatching any agent).

Print: `[0f] Recon: measuring project shape...`

```bash
bash .claude/aid/scripts/kb/recon-classify.sh \
  --index .aid/generated/project-index.md \
  --candidates .aid/generated/candidate-concepts.md \
  --settings .aid/settings.yml \
  --output .aid/generated/recon.md
```

On completion, read `.aid/generated/recon.md` and print:
`[0f] Proposed path: <path> (source-files=N, LOC=M, dirs=D, concepts=C)`

**Degrade-gracefully:** if the script fails, log a warning and default to `brownfield-small`
(conservative). The human-confirm gate is the safety net.

#### Idempotent re-entry

Before presenting the proposal, check whether `.aid/knowledge/STATE.md` already has a
`## Discovery Triage` section from a prior run:

```bash
prior_path="$(grep -m1 '^\*\*Path:\*\*' .aid/knowledge/STATE.md 2>/dev/null \
  | sed 's/^\*\*Path:\*\* *//' | tr -d '[:space:]')"
```

- **Prior path exists** (re-run): show the prior path alongside the freshly-measured proposal
  as a diff (e.g. "was brownfield-small; now measures brownfield-large -- N new dirs since last
  run") and ask the human to confirm the transition or keep the prior path. This is the
  re-triage lifecycle made visible (FR-22 -- the path is re-measured every run).
- **No prior path** (first run): proceed to the triage gate below.

#### Present the proposal (PAUSE-FOR-USER-DECISION)

Display the measured metrics + the proposed path + the threshold rationale, then present the
three choices (example for a brownfield-large proposal):

```
Recon measured this project:
  source files : 142        (greenfield <= 5)
  source LOC   : 38,400     (large >= 20,000)   <-- tripped LARGE
  directories  : 31         (large >= 25)       <-- tripped LARGE
  coined concepts: 47       (large >= 40)       <-- tripped LARGE

Proposed discovery path: brownfield-large
  (full machinery: researcher fan-out + full 5-mandate review panel + batched closure loop)

[1] Confirm  brownfield-large  (as proposed)
[2] Override brownfield-small  (collapsed: single understand-pass; one reviewer runs the mandates as sequential passes + clean-context teach-back)
[3] Override greenfield        (no source yet => signpost + HALT: run /aid-interview to define the project; the KB fills in as you build)
```

**This is a genuine PAUSE-FOR-USER-DECISION** (C4 human-gated; the path is measured but
confirmed, never auto-decided -- FR-20). Stop here after presenting. The human's choice (not a
static `project.type`) is authoritative; an override is recorded as such. Escalation/uncertainty
defaults to the proposed path on a bare confirm, exactly like Step 0d's conservative default.

**Advance:** Stop here after presenting the triage proposal. Re-run `/aid-discover` after
confirming the path to continue to Step 1.

#### On confirm (resume path) -- write the decision

Write the confirmed path to `## Discovery Triage` in `.aid/knowledge/STATE.md`. This is the
trackable record for this run and the anchor that idempotent re-entry reads on the next run.

```markdown
## Discovery Triage

- **Path:** brownfield-large
- **Measured:** source-files=142, source-LOC=38400, dirs=31, concepts=47
- **Proposed:** brownfield-large (tripped: large_min_source_loc, large_min_dirs, large_min_concepts)
- **Decision rationale:** measured -> proposed brownfield-large -> confirmed
- **Re-triaged:** <date> (run N)
```

(`**Override:** yes` is added when the human picked a path other than the proposed one,
mirroring `state-triage.md`'s override record. `**Re-triaged:**` records the date/run-number
so consecutive re-runs are traceable.)

Then **branch on the confirmed path**:

- **Brownfield (small or large):** CHAIN -> Step 1 with the confirmed path parameterizing the
  rest of GENERATE (Steps 2-5 fan-out + Step 5b closure caps; see `references/path-config.md`).

- **Greenfield:** **do NOT chain to Step 1.** Print the **signpost and HALT** --

  ```
  [0f] Greenfield detected: ~no source to discover yet.
       Nothing to discover yet -- run /aid-interview to define the project;
       the KB fills in as you build, via re-triage once code lands.
  ```

  The `## Discovery Triage` record is still written (so the next run re-triages from a known
  prior path), but GENERATE ends here. No fan-out, no closure, no review panel runs. Greenfield
  is a detect+signpost outcome, not a generation path.

## Step 1: Pre-scan (aid-researcher, pre-scan doc-set) — ALWAYS runs first, ALONE

Produces `project-structure.md` and `external-sources.md` — foundation for all other agents.
**Skip** if both already exist. Otherwise:

Print: `[1/5] Pre-scan: mapping project structure and external sources...`

Read `references/agent-prompts.md` section `## Scout` for the full prompt. Substitute the
external docs placeholder with actual paths (or the "no docs" variant).

▶ aid-researcher (pre-scan) starting (~2–4 min)
Wait for completion. Verify both files exist. Re-dispatch if missing.
✓ aid-researcher (pre-scan) done (record actual time) — or ✗ aid-researcher (pre-scan) failed: {reason}

### Steps 2-5: Deep-Dive Fan-Out (path-branched from confirmed path)

**Only after Step 1 completes.** Dispatch with `background: true`.

**Greenfield never reaches this step** -- GENERATE halted at the Step 0f signpost. Steps 2-5
only ever run for the two brownfield paths.

**Branch on the confirmed path (from `## Discovery Triage` in `.aid/knowledge/STATE.md`):**

- **brownfield-large:** run the **full 4-way parallel fan-out** (below) -- 4 parallel
  `aid-researcher` dispatches, one per concern lane.
- **brownfield-small:** **skip the 4-way fan-out.** Dispatch **ONE `aid-researcher`** with the
  full declared-set target list as a single understand-pass over the (small) source. The
  single-pass researcher receives all targets from all concern lanes (architecture + analyst +
  integrator + quality docs) in one prompt, covering the declared set in one pass. Skip the
  per-lane target-list computation below; instead assemble all declared-set targets and dispatch
  one agent. The prompt it receives is the combined foundation reference block (below) plus the
  full target list. Print `[2-5/5] Single understand-pass (brownfield-small): covering all targets in one pass...`

For **brownfield-large** (full fan-out) -- compute each agent's target list from the declared
set (§2.5 mapping-honors-declared-set):

```bash
# owns-<agent>: filenames assigned to this agent in the declared set
# ∩ missing-on-disk: only dispatch for docs not already on disk with real content
for agent in aid-researcher-architecture aid-researcher-analyst aid-researcher-integrator aid-researcher-quality; do
  # Map the parameterized slot name to its doc-set owner key
  case "$agent" in
    aid-researcher-architecture) owner_key="aid-researcher-architecture" ;;
    aid-researcher-analyst)      owner_key="aid-researcher-analyst"      ;;
    aid-researcher-integrator)   owner_key="aid-researcher-integrator"   ;;
    aid-researcher-quality)      owner_key="aid-researcher-quality"      ;;
  esac
  owns="$(resolve_doc_set "$raw" | awk -F'\t' -v a="$owner_key" '$2==a{print $1}')"
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
- A custom doc owned by the fallback rides on the `aid-researcher` (architecture doc-set) dispatch.

**Custom-doc prompt extension (§2.6):** After computing each agent's target list, identify any
**custom docs** — filenames that are in the target list but do NOT appear in the default seed
(i.e., not synthesized from `.claude/aid/templates/knowledge-base/*.md` by `synth_default_seed`).
For each such custom doc, **append** the following line to that agent's base prompt (from
`references/agent-prompts.md`) before dispatching:

```
Also produce .aid/knowledge/<filename> per its expectations entry in
references/document-expectations.md (keyed by ### <filename>).
```

Append one such line per custom doc in the agent's target list. The base prompt text is
unchanged; this is a runtime-only extension. Owner resolution: use the `owner-of <filename>`
accessor; unknown owners fall back to the `aid-researcher` (architecture doc-set) slot (FR-P1-5 — no new agent).
See `references/agent-prompts.md` § "Custom-Doc Runtime Extension" for the full protocol.

**Every agent receives the foundation reference block** (appended to prompt):
```
REFERENCE DOCUMENTS (read these FIRST before analyzing):
- .aid/generated/project-index.md — full file inventory with metadata (sizes, languages, mtimes, notable files)
- .aid/generated/candidate-concepts.md — ranked candidate concepts (harvest + synthesis rows); the essence anchor — every term here MUST be grounded in the spine or explicitly dismissed
- .aid/knowledge/project-structure.md — repository structure map (architectural narrative)
- .aid/knowledge/external-sources.md — external documentation inventory and findings
```

In the agent prompt, include the computed target file list (from `targets_<agent>` above) and
the prompt section from `references/agent-prompts.md`:

| Step | Agent | Default-seed target files (illustrative — actual targets from declared set) | Prompt Section |
|------|-------|----------------------------------------------------------------------------|----------------|
| [2/5] | `aid-researcher` (architecture doc-set) | architecture.md, technology-stack.md | `references/agent-prompts.md` → `## Architect` |
| [3/5] | `aid-researcher` (analyst doc-set) | module-map.md, coding-standards.md, schemas.md | `references/agent-prompts.md` → `## Analyst` |
| [4/5] | `aid-researcher` (integrator doc-set) | pipeline-contracts.md, integration-map.md, domain-glossary.md | `references/agent-prompts.md` → `## Integrator` |
| [5/5] | `aid-researcher` (quality doc-set) | test-landscape.md, tech-debt.md, infrastructure.md | `references/agent-prompts.md` → `## Quality` |

The actual target files for each agent are derived at runtime from the declared set, not hard-coded above.

**Sub-agents may delegate mechanical work** to `aid-clerk` (with `operation: extract`, `operation: glob`, or `operation: format` as appropriate) for high-volume extraction or templating. The synthesis stays at the sub-agent's tier; only the grunt work delegates.

Before dispatching, print the AC4 sub-unit snapshot header for the GENERATE state (listing only agents with a non-empty target list):
```
GENERATE  Wave 1 of 1 · 0/4 done
  (queued) aid-researcher (architecture doc-set)  ~3–5 min
  (queued) aid-researcher (analyst doc-set)       ~3–5 min
  (queued) aid-researcher (integrator doc-set)    ~3–5 min
  (queued) aid-researcher (quality doc-set)       ~3–5 min
```

Print the AC2 bracket-pair before each parallel dispatch:
```
▶ aid-researcher (architecture doc-set) starting (~3–5 min)
▶ aid-researcher (analyst doc-set) starting (~3–5 min)
▶ aid-researcher (integrator doc-set) starting (~3–5 min)
▶ aid-researcher (quality doc-set) starting (~3–5 min)
```

### Wait for ALL Agents

**After dispatching, WAIT. Do not check files. Do not take any action.**

On each agent completion, re-render the AC4 snapshot (coalesce multiple completions within the same second into one render):
```
✓ aid-researcher (architecture doc-set) done in {actual}
GENERATE  Wave 1 of 1 · 1/4 done
  ✓ aid-researcher (architecture doc-set)  {actual}
  ● aid-researcher (analyst doc-set)       {elapsed} / ~3–5 min
  (queued) aid-researcher (integrator doc-set) ~3–5 min
  (queued) aid-researcher (quality doc-set)    ~3–5 min
```

Print each completion with the AC2 bracket close: `✓ {agent} done in {actual time}` (or `✗ {agent} failed: {reason}` on error).

When ALL dispatched agents complete, print the final snapshot:
```
GENERATE  Wave 1 of 1 · 4/4 done
  ✓ aid-researcher (architecture doc-set)  {actual}
  ✓ aid-researcher (analyst doc-set)       {actual}
  ✓ aid-researcher (integrator doc-set)    {actual}
  ✓ aid-researcher (quality doc-set)       {actual}
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

Semantic verification of the docs (frontmatter compliance, contract claims, cross-doc consistency, spot-checks against source) happens in the **REVIEW** state, dispatched as the `aid-reviewer` sub-agent — not as a separate shell script.

### Step 5b: SYNTHESIS + CLOSURE

**Run after ALL deep-dive agents (Steps 2-5) complete, before Step 6.**

**Greenfield never reaches this step** -- GENERATE halted at the Step 0f signpost. Step 5b
only ever runs for the two brownfield paths.

Dispatch `aid-architect` to run the comprehension/closure loop. The loop body is defined in
`references/state-closure.md` (thin-router pattern). The orchestrator invokes it with the
cap-override argument interface (defaults from `discovery.closure` in `.aid/settings.yml`):

```
--max-clean-passes <N>   default: discovery.closure.max_clean_passes (2)
--max-rounds <N>         default: discovery.closure.max_rounds (4)
--token-budget <N>       default: discovery.closure.token_budget (0 = use pass/round caps)
```

**Per-path closure-cap wiring (f006 path-config -- `references/path-config.md`):**

Read the confirmed path from `## Discovery Triage` in `.aid/knowledge/STATE.md`, then read the
`discovery.closure` defaults from `.aid/settings.yml` (NOT via `read-setting.sh`, which
resolves only 2-level `section.key` paths -- the 3-level `discovery.closure.max_clean_passes`
is outside its reach). Apply the per-path override per the matrix:

```bash
# Read confirmed path
confirmed_path="$(grep -m1 '^\*\*Path:\*\*' .aid/knowledge/STATE.md 2>/dev/null \
  | sed 's/^\*\*Path:\*\* *//' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

# Read discovery.closure defaults (3-level keys; read-setting.sh is 2-level only)
max_clean_passes="$(grep -A5 'closure:' .aid/settings.yml 2>/dev/null \
  | awk '/max_clean_passes:/{print $2; exit}')"
max_rounds="$(grep -A5 'closure:' .aid/settings.yml 2>/dev/null \
  | awk '/max_rounds:/{print $2; exit}')"
token_budget="$(grep -A5 'closure:' .aid/settings.yml 2>/dev/null \
  | awk '/token_budget:/{print $2; exit}')"
# Apply settings defaults if absent
max_clean_passes="${max_clean_passes:-2}"
max_rounds="${max_rounds:-4}"
token_budget="${token_budget:-0}"

# Apply per-path override (path-config.md -- no yq, no nested settings read)
# brownfield-large: use defaults (no override args needed)
# brownfield-small: override to single-pass (max_rounds=1, max_clean_passes=1)
CLOSURE_OVERRIDE_ARGS=""
if [[ "$confirmed_path" == "brownfield-small" ]]; then
  max_rounds=1
  max_clean_passes=1
  CLOSURE_OVERRIDE_ARGS="--max-rounds 1 --max-clean-passes 1"
fi
# greenfield: never reaches here (GENERATE halted at Step 0f signpost)
```

The `CLOSURE_OVERRIDE_ARGS` are the runtime arguments passed to f004's Step 5b closure step.
For brownfield-large they are empty (use settings defaults); for brownfield-small they are
`--max-rounds 1 --max-clean-passes 1`. This is the cap-override interface specified and owned
in f004's SPEC (Step 5b); f006 supplies the per-path values through it. No nested settings
mutation; no `yq`.

Print: `[5b] SYNTHESIS + CLOSURE starting (path=${confirmed_path}, max_clean_passes=${max_clean_passes}, max_rounds=${max_rounds})...`

▶ aid-architect (SYNTHESIS + CLOSURE) starting (~variable)
Follow `references/state-closure.md` for the full loop body.
✓ aid-architect (SYNTHESIS + CLOSURE) done — or ✗ aid-architect (SYNTHESIS + CLOSURE) failed: {reason}

**Ungroundable terms** discovered during the closure loop that cannot be grounded from any
artifact after investigation are appended to `.aid/knowledge/.scout-questions.tmp` using the
existing Q&A format (Category: `Concept`, Impact: `High`, Status: Pending) so Step 6b
consolidates them into `STATE.md ## Q&A (Pending)`. **Step 6b is unchanged** -- the closure
loop simply feeds the same pipe.

Print on completion: `[5b] CLOSURE complete -- {N} concepts grounded, {M} terms escalated to Q&A.`

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
6. **Preserve** `**Project Type:**`, `**User Approved:**`, `## External Documentation` (the `**Minimum Grade:**` field is now in `.aid/settings.yml` — read it via `bash .claude/aid/scripts/config/read-setting.sh --skill discover --key minimum_grade --default A`)
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

Scan for `CLAUDE.md`. Replace `<!-- AID-DISCOVER ... -->` placeholders with real data:
project description, overview, build/test commands, conventions, architecture summary.
Keep the comment markers for future re-discoveries.

### Step 8: Final Wrap-up

**Persist the resolved doc-set TSV** so REVIEW's M6 pre-dispatch step has its required input.
This MUST run on every brownfield path (large and small). Greenfield never reaches Step 8 — it
halted at the Step 0f signpost — so the TSV is never written for a greenfield outcome (M6 is
unreachable on greenfield).

```bash
mkdir -p .aid/generated
# Re-use the already-resolved $raw from Step 0d / Step 0f on-confirm.
# Sort for byte-reproducibility (NFR-3); LC_ALL=C already in effect.
LC_ALL=C resolve_doc_set "$raw" | sort > .aid/generated/doc-set.tsv
```

The TSV format is `filename<TAB>owner<TAB>presence` — the exact shape `kb-actback-task.sh`
consumes. Writing it here (producer-side, once, at the end of GENERATE) ensures the consumer
in REVIEW always finds a fresh, authoritative copy that matches the confirmed doc-set for this
run.

Print: `[N/N] Generation complete — Knowledge Base ready. Run /aid-discover again to review.` (where N = declared-set size)

(File-presence was confirmed in the **Verify All Declared Files** step above; semantic quality is the **REVIEW** state's job — no additional pre-REVIEW check needed.)

Print: `[State: GENERATE] complete.`

**Advance:** **CHAIN** → [State: REVIEW] (continue inline).
