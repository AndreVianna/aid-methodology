# Known Issues

<!-- Scoped to this work. Only issues that affect features in this work. -->
<!-- Created/updated by aid-specify during codebase exploration. -->
<!-- Consumed by aid-plan for deliverable sequencing. -->

<!-- Entry format:
## KI-NNN: {Title}
- **Type:** Bug | Security | Deprecated Dependency | Breaking API Contract
- **Severity:** Critical | High | Medium
- **Affects:** feature-NNN-{name}, feature-NNN-{name}
- **Source:** {file path}:{line} or {dependency}:{version}
- **Description:** {what's wrong and why it matters for the affected features}
- **See also:** tech-debt.md #TD-NNN (if already catalogued in KB)
-->

## KI-001: The always-loaded rules send agents to a work state file that no longer exists

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 001 — Ask for Work in Plain Language
- **Source:** `canonical/aid/rules.md` § Tracking discipline (IMPERATIVE) -- the sentence "the work's `.aid/works/work-NNN-*/STATE.md`" and the bullet "whether on the FULL or the LITE path"; installed verbatim as `.aid/runtime/rules.md`
- **Description:** The rules every session reads first name the work's state file as `STATE.md`, but a work's state lives in `STATE.yml` (`canonical/aid/templates/work-state-template.yml`). An agent that follows the rule literally creates or looks for a markdown file that no reader parses. The same section also speaks of a "FULL or LITE path", a split this work removes. Feature 001 rewrites the neighbouring `## Workflow` section into the orchestration section and makes the rules the place every plain request is routed from, so leaving the stale sentence in place undercuts the very file the feature depends on. It does not block the feature, but every new session inherits the wrong pointer until it is fixed.
- **See also:** tech-debt.md #SY-6 (the same stale name in `canonical/skills/**`; that entry does not cover `rules.md`)

## KI-002: Work state written in shapes the dashboard readers silently drop

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 001 — Ask for Work in Plain Language; Feature 002 — Clear, Step-by-Step Decisions
- **Source:** `dashboard/reader/state_schema.py` `_finalize_value` ("flow collection rejected") and `_MAX_LEVEL`; the same rules in the Node twin `dashboard/server/reader.mjs` `parseStateDocument`
- **Description:** Both dashboard readers accept only block-style YAML up to three levels deep: a flow list or mapping (`[a, b]`, `{k: v}`) other than the literal `[]` / `{}` is rejected, and a key nested deeper than three levels is skipped, and a comment on the line of a key that opens a list or mapping turns that key into an empty value (its entries become orphan lines) -- each with only a parse warning. Three live shapes fall outside that: this work's own `STATE.yml` writes `features[].sections` entries as flow mappings (all six of Feature 001's section rows read back as an empty list); Feature 001's approved `intent.phases` sample is a flow list; and Feature 001's `sources[].written_back[]` entries put `part` and `files` at a fourth level, so a reader keeps only `at`. Nothing tells the writer the shape is wrong, so the dashboard shows less than the file holds. Feature 002 settles the single `STATE.yml` layout and owns the dashboard reading it (AC-41), so the layout it defines has to fit the readers' subset (Feature 002 § Work state layout states the rule), and Feature 001's two samples have been reshaped to fit it (`intent.phases` in block style; `written_back` replaced by a top-level `write_backs:` list).
- **See also:** --

## KI-003: Questions are recorded in three different places, one of which no longer exists

- **Type:** Bug
- **Severity:** Medium
- **Affects:** Feature 002 — Clear, Step-by-Step Decisions
- **Source:** `canonical/skills/aid-ask/SKILL.md` § Target-file resolution and `canonical/skills/aid-execute/references/state-delivery-gate.md` § Non-CODE issues (both write the delivery-level `qa` of `deliveries/delivery-NNN/STATE.yml` on a full work); `canonical/skills/aid-detail/references/task-decomposition.md` § Feedback Loops and `canonical/skills/aid-describe/references/state-q-and-a.md` (write to `## Cross-phase Q&A` in a work `STATE.md` that no longer exists)
- **Description:** The question protocol requires every question and answer to be recorded so a skipped question can be resumed later by any user. Today a work's questions are split between the work `STATE.yml` `qa`, each delivery's own `qa`, and a markdown section of a retired file, depending on which skill asked. A resuming session that reads only the work `qa` misses the rest, and the entries sent to the retired file are lost. The delivery-level split existed to keep two delivery branches from colliding on one file; with one branch per work that reason is gone.
- **See also:** tech-debt.md #SY-6 (covers the retired `## Cross-phase Q&A` heading sites, not the delivery-level split)

## KI-004: An idea draft written in one work cannot be found by the next one

- **Type:** Bug
- **Severity:** High
- **Affects:** Feature 003 — Shape an Idea or Ticket into a Clear Work Definition
- **Source:** `canonical/skills/aid-brainstorm/SKILL.md` § State: INTAKE (allocates and enters a new worktree) and § State: DESIGN (writes `.aid/design/<slug>.md` there), § State: PRESENT and § State: DONE (the work is marked `Completed` in the same run); `canonical/aid/templates/work-initiation-gate.md` § 3a NEW (every new work gets a fresh worktree off `master`) and § 3b CONTINUATION (a `Completed` work is not resumed: "suggest a NEW work"); `canonical/aid/scripts/works/worktree-lifecycle.sh` header ("git worktree add cannot carry untracked content"); the same pattern in every `canonical/skills/aid-design-*/SKILL.md`, in `canonical/aid/templates/shortcut-engine.md` § Step 2: Read context (`.aid/design/{artifact}.md`) and in the seed reads of `canonical/skills/aid-create-document/SKILL.md` and `aid-update-document/SKILL.md`
- **Description:** Every brainstorm or design run writes its draft as an untracked file inside its own work's worktree, then closes that work. The skill tells the user to iterate by running it again, and the `create` skills are meant to read the draft, but each of those runs is a new work in a new worktree branched off `master`, which cannot see an untracked file in another worktree. So the next run starts from nothing, with no warning, unless the user happened to commit and merge the draft. FR-9 needs a draft that survives across sessions (and possibly without ever becoming built work), so Feature 003 has to settle where a draft lives with one worktree per work before it can meet AC-17.
- **See also:** --

## KI-005: Bringing the parent branch into a work branch conflicts with the never-merges test

- **Type:** Gap
- **Severity:** Medium
- **Affects:** Feature 008 — Pull Requests Kept on Track Through Reviews and Pipeline Failures
- **Source:** REQUIREMENTS.md § 11 Feature 002 Technical Specification, test NM-01 (forbids any `git merge`); Feature 004 Technical Specification, The view and its "What other features must provide" row for Feature 008 (a `kb.html` / `INDEX.md` collision is resolved by re-rendering and finishing the merge with Feature 008's own merge commit)
- **Description:** Feature 008 has to bring the parent branch into the work branch to resolve a pull-request conflict, and finish that merge with its own commit. NM-01 forbids every `git merge`, but its purpose is that AID never merges the pull request itself. Feature 008's spec must narrow NM-01 to that purpose, or resolve conflicts in a way NM-01 allows.
- **See also:** --
- **Status:** Settled by Feature 008 (Q85): AC-11, AC-34 and NM-01 are narrowed so the only merge AID makes brings the parent branch (or the work branch's own remote copy) into the work branch, in `canonical/aid/scripts/pipeline/merge-parent.sh`, only for a conflict, approved before it is pushed.

## KI-006: The conversation runner drives only Claude Code

- **Type:** Gap
- **Severity:** Medium
- **Affects:** Feature 001 — Ask for Work in Plain Language; Feature 009 — One Skill per Need
- **Source:** `tests/conversation/run.py` (`ADAPTERS` holds only `claude-code`; the "Other hosts" comment); REQUIREMENTS.md § 11 Feature 001 `##### 6. Testing`, Conversation suite ("The other four tools use an adapter with the same three steps"); Feature 009 `##### 6. Risks`, The stand-ins ("one run against a scratch repository on each host is part of the full integration suite before release")
- **Description:** `run.py` accepts `--hosts codex,cursor,copilot-cli,antigravity` but skips each with a NOTICE, because only the Claude Code driver exists. The cloud sessions that build this work have none of those four tools installed, so their adapters cannot be built or tested there. No task before the end of the work runs a host other than Claude Code (every smoke run uses the default `--hosts claude-code`), so the gap blocks nothing until the full integration run at delivery-014's gate. Delivery reviews before then accept the gap as this known issue.
- **See also:** task-365 (builds the four adapters on the maintainer's machine, before task-362); Q144

## KI-007: Feature 001 conversation samples still fail on agent behaviour

- **Type:** Bug
- **Severity:** High
- **Affects:** Feature 001 — Ask for Work in Plain Language
- **Source:** `tests/conversation/samples/feature-001/` (every sample except 001-03, 001-04 and 001-15); per-run results, causes and run folders in `analysis/delivery-001-sample-runs.md` (work folder)
- **Description:** After the delivery-001 fix round (rules wording, size-first routing through `/aid-orchestrate`, harness and sample fixes), all 16 Feature 001 samples were run 3 times each on the real claude CLI (default model `claude-sonnet-5-5`). 23 of 48 runs pass; only 001-03, 001-04 and 001-15 pass 3 of 3. Every remaining failure except 001-16 is agent behaviour against a clear expectation that was in context (001-16's failing run followed the product, see its line below):
  - 001-01 (AC-1), 2/3: the bug reading omits its Knowledge Base basis.
  - 001-02 (AC-2), 0/3: no read-only investigation workflow named with its reason; once asks the user to pick.
  - 001-05 (AC-4), 2/3: a speculative addition in a Knowledge Base answer (borderline).
  - 001-06 (AC-5), 1/3: the Knowledge Base conflict is settled by the agent instead of put to the user.
  - 001-07 (AC-7, AC-21), 0/3: approval asked twice before building; once the Skill tool is not called.
  - 001-08 (AC-7), 0/3: a bare idea is sized `lite`, not `full`; topics asked at once.
  - 001-09 (AC-14), 2/3: the bug-fix reading is given without its one-line reason (EO-1).
  - 001-10 (AC-14), 0/3: the release is done and closed by hand, not by its skill and CI.
  - 001-11 (AC-29), 1/3: the ticket is added to `sources:` as a bare string, not a `ref`/`kind` entry.
  - 001-12 (AC-29), 2/3: a weak recommendation at the tool limit (borderline).
  - 001-13 (AC-29), 1/3: the project source is attached to the work's `sources:`.
  - 001-14 (AC-1), 1/3: the lite path shows no CI step in one run, and another run says the `add` and `list` behaviour is unchanged.
  - 001-16 (AC-14), 2/3: a sample cause, not agent behaviour. EO-1 expected a "closing step" the product does not define; the failing run closed the work with the two write-back script calls of `/aid-orchestrate`'s Close step (phase Execute, then lifecycle Completed), which is what the product defines. The sample's EO-1 now expects that close, so this row is no longer a failure of the agent.
  The judge's six-column table, which the runner read as no table in 001-03 run 3 and 001-14 run 2, is fixed in the harness: both samples were re-run after the fix, and no run in this table fails on a judge-format fault.
- **See also:** backlog item W7-14 (hooks): a pre-approval guard that blocks source edits until the user agrees is the mechanical fix for the compliance-bound cases.
- **Status:** Open. Re-checked at the full integration run at delivery-014's gate. Does not block delivery-001 (Q149).
