# STATE YAML-Frontmatter Schema Note

> **Task:** task-001 (DESIGN) · **Work:** work-003-state-schema · **Delivery:** delivery-001
> **Scope:** field -> frontmatter key -> legacy prose location it replaces, for all 4 canonical
> STATE templates. Authoritative mapping for task-002 (reader twins), task-004 (writers), and
> task-005 (on-disk migration). Templates only -- no reader/writer code changed here.

## 1. `work-state-template.md`

New YAML frontmatter block inserted at the very top of the file (before the `# Work State`
title). All values are closed-enum placeholders written verbatim (matching the exact string
forms the reader already/will parse -- no behavior change intended).

| Field | Frontmatter key | Legacy prose location it replaces | Class |
|-------|-----------------|-----------------------------------|-------|
| Pipeline path (lite/full) | `pipeline.path` | **none** -- currently inferred by the reader's `_detect_flat` heuristic (folder-shape sniffing); this is the first authoritative source | Newly captured |
| Pipeline-starting skill | `pipeline.initiator` | **none** -- currently a null `recipe` field / unset | Newly captured |
| Work created date | `started` | Header blockquote `> **Started:** {YYYY-MM-DD}` (also retires the fragile `## Lifecycle History` "Work created" row-scrape used for `created` today) | Relocated (never actually parsed from the header; the row-scrape was the only working path) |
| Per-work minimum grade | `minimum_grade` | Header blockquote `> **Minimum Grade:** {...}` -- **already parsed** by `derivation.py:1065 _RE_MINIMUM_GRADE_LINE` (`\*\*Minimum Grade:\*\*\s*(\S+)`), drives the sub-minimum Blocked gate. Value form (a single-token grade, e.g. `A`) must be preserved verbatim. | Relocated (already parsed) |
| Work-level user approval | `user_approved` | Header blockquote `> **User Approved:** yes \| no` | Newly captured (distinct from KB `summary_approved`) |
| Pipeline lifecycle | `lifecycle` | `## Pipeline State` bullet `- **Lifecycle:** ...` -- parsed by `_RE_PS_LIFECYCLE` | Relocated (already parsed) |
| Pipeline phase | `phase` | `## Pipeline State` bullet `- **Phase:** ...` -- parsed by `_RE_PS_PHASE` | Relocated (already parsed) |
| Active skill | `active_skill` | `## Pipeline State` bullet `- **Active Skill:** ...` -- parsed by `_RE_PS_SKILL` | Relocated (already parsed) |
| Pipeline updated timestamp | `updated` | `## Pipeline State` bullet `- **Updated:** ...` -- parsed by `_RE_PS_UPDATED` | Relocated (already parsed) |
| Pause reason | `pause_reason` | `## Pipeline State` bullet `- **Pause Reason:** ...` -- parsed by `_RE_PS_PAUSE_REASON` | Relocated (already parsed) |
| Pipeline block reason | `block_reason` | `## Pipeline State` bullet `- **Block Reason:** ...` -- parsed by `_RE_PS_BLOCK_REASON` | Relocated (already parsed) |
| Pipeline block artifact | `block_artifact` | `## Pipeline State` bullet `- **Block Artifact:** ...` -- parsed by `_RE_PS_BLOCK_ART` | Relocated (already parsed) |
| Delivery lifecycle state (flattened works only) | `delivery_state` | `## Delivery Lifecycle` bullet `- **State:** ...` | Relocated (already parsed, per `parsers.py` "Reads: ## Delivery Lifecycle: delivery_state...") |
| Delivery gate reviewer tier (flattened works only) | `gate_tier` | `## Delivery Gate` bullet `- **Reviewer Tier:** ...` | Relocated (already parsed) |
| Delivery gate grade (flattened works only) | `gate_grade` | `## Delivery Gate` bullet `- **Grade:** ...` -- parsed by `_RE_GRADE_LINE` | Relocated (already parsed) |
| Delivery gate timestamp (flattened works only) | `gate_timestamp` | `## Delivery Gate` bullet `- **Timestamp:** ...` | Relocated (already parsed) |

**Explicitly NOT relocated (stays markdown body), scoped out by the task DETAIL:**
- `## Delivery Lifecycle` bullets `Updated` / `Block Reason` / `Block Artifact` -- currently
  parsed (`_RE_DL_UPDATED`/`_RE_DL_BLOCK_REASON`/`_RE_DL_BLOCK_ART`) but NOT named in the
  task-001 field list; moving them would require a nested key (e.g. `delivery.block_reason`)
  to avoid colliding with the pipeline-level `block_reason`/`block_artifact` keys above, which
  is out of this task's explicit scope. Left as brittle-but-working prose.
- `## Delivery Gate` bullet `Issue List` -- a variable-length inline list, not a flat scalar;
  stays body (same reasoning as `## Quick Check Findings` / delivery `Cross-phase Q&A` below).
- `## Interview State`, `## Lifecycle History`, `## Deploy State`, `### Tasks lifecycle` table,
  all DERIVED union sections (`## Features State`, `## Plan / Deliveries`, `## Tasks State`,
  `## Delivery Gates`, `## Cross-phase Q&A`, `## Calibration Log`, `## Dispatches`) -- narrative
  or multi-row content; never scalar machine fields.

**Keep INFERRED (do NOT author, per DETAIL):** `number` (folder name), `branch` (git worktree),
`title`/`description`/`objective` (REQUIREMENTS/SPEC content files).

**Keep DERIVED (do NOT author, per DETAIL):** counts, readiness/execution %, `source_mode`.

**Decision (not itemized in DETAIL, left untouched):** the header blockquote's own
`> **State:** Interview Complete | Specifying | ...` and `> **Phase:** Interview | Specify | ...`
lines are a *third*, differently-shaped, unparsed pair (grep of `dashboard/` confirms zero
reader references) predating the `## Pipeline State` section. DETAIL's relocation list for the
header blockquote names only `started`/`minimum_grade`/`user_approved` -- not these two -- so
they are left as-is (dead prose, out of this task's scope; flagged as a possible follow-up
cleanup, not fixed here to avoid scope creep).

## 2. `delivery-state-template.md` (full-path, multi-delivery works)

Same shape as the WORK template's promoted "flattened" group, applied to the always-present
FULL-PATH delivery file (this template has no lite-path ambiguity -- it only exists for full
multi-delivery works).

| Field | Frontmatter key | Legacy prose location it replaces |
|-------|-----------------|-----------------------------------|
| Delivery lifecycle state | `delivery_state` | `## Delivery Lifecycle` bullet `- **State:** ...` |
| Gate reviewer tier | `gate_tier` | `## Delivery Gate` bullet `- **Reviewer Tier:** ...` |
| Gate grade | `gate_grade` | `## Delivery Gate` bullet `- **Grade:** ...` |
| Gate timestamp | `gate_timestamp` | `## Delivery Gate` bullet `- **Timestamp:** ...` |

Not relocated (same reasoning as the WORK template): `## Delivery Lifecycle` Updated/Block
Reason/Block Artifact bullets; `## Delivery Gate` Issue List bullet; `## Cross-phase Q&A`;
`## Tasks State` (DERIVED).

**Keep INFERRED:** the header blockquote `Delivery`/`Work`/`Branch` identifiers (folder name +
git worktree) -- never authored in frontmatter.

## 3. `task-state-template.md` (full-path, per-task)

This file is the sole per-task mutable-state file when the pipeline is NOT flattened, so
(unlike the work-root's aggregating `### Tasks lifecycle` table, which stays a table because it
holds many tasks in one file) its 4 State columns flatten cleanly into scalar frontmatter keys.

| Field | Frontmatter key | Legacy prose location it replaces |
|-------|-----------------|-----------------------------------|
| Task state | `state` | `## Task State` bullet `- **State:** ...` |
| Task review outcome | `review` | `## Task State` bullet `- **Review:** ...` |
| Task elapsed time | `elapsed` | `## Task State` bullet `- **Elapsed:** ...` |
| Task notes | `notes` | `## Task State` bullet `- **Notes:** ...` |

Not relocated: `## Quick Check Findings` (Reviewer Tier is a constant "Small"; Findings is a
variable-length list) and `## Dispatch Log` (multi-row table, source of the DERIVED
`## Calibration Log`/`## Dispatches` unions) -- both stay markdown body.

**Keep INFERRED:** the header blockquote `Task`/`Delivery`/`Work` identifiers (folder path).

## 4. `discovery-state-template.md` (`.aid/knowledge/STATE.md`)

This file is itself a KB document (`kb-category: meta`), so it already carries the
kb-authoring frontmatter block (`kb-category`/`source`/`objective`/`summary`/`tags`/`see_also`/
`owner`/`audience` -- see `canonical/aid/templates/kb-authoring/frontmatter-schema.md`) **in the
live, already-migrated instance** (this repo's own `.aid/knowledge/STATE.md`). The **canonical
template**, however, had never been updated to carry that block (a pre-existing template/reality
gap, confirmed by `discover-preflight.sh`, which still `cp`s the template verbatim with no
frontmatter). This task adds the base 8-field block to the template (mirroring the live
instance) and extends it with the 5 new run-state keys:

| Field | Frontmatter key | Legacy prose location it replaces | Class |
|-------|-----------------|-----------------------------------|-------|
| KB discovery status | `kb_status` | Header blockquote `> **Status:** Initial \| In Progress \| Approved` | Newly captured (never parsed by any reader) |
| KB current grade | `kb_grade` | Header blockquote `> **Current Grade:** {grade or Pending}` | Newly captured |
| KB last review date | `last_kb_review` | Header blockquote `> **Last KB Review:** {YYYY-MM-DD or --}` | Newly captured |
| Summary (kb.html) approval | `summary_approved` | `## Knowledge Summary Status` table row `\| User Approved \| yes \| no \|` -- the row the reader's `_parse_kb_summary_approval` regex (which looks for a **bold line**, `\*\*User Approved:\*\*\s+(.+)`, not a table row) never actually matched; also the ad hoc `**User Approved:** yes (date)` bold line that `state-generate.md`/`state-approval.md` write directly below the table (undocumented by the old template) -- the exact bug trigger this whole work exists to fix | Relocated (already read, brittle) |
| Summary last-run date | `last_summary` | `## Knowledge Summary Status` table row `\| Last Run \| {YYYY-MM-DD or --} \|`, and the parenthesized date on the same ad hoc `**User Approved:** yes (date)` bold line the reader's `_parse_kb_summary_approval` extracts today | Relocated (already read, brittle) |

**Explicitly NOT relocated / kept out of STATE (per DETAIL):**
- `doc_count` (derived from README.md), `kb_baseline` (derived from `.aid/settings.yml`),
  `summary_present` (derived from a `kb.html` file stat), freshness (derived, git-fed) -- all
  computed at read time, never authored.
- `## Knowledge Summary Status` non-approval rows (Profile, Profile Source, Profile Confidence,
  Theme, Machine Grade, Human Grade, Output, Mermaid Version, Mermaid Cached) -- out of this
  task's named scope; stay markdown body.
- `## KB Documents Status`, `## Q&A (Pending)`, `## Review History`, `## Summarization History`,
  `## External Documentation` -- narrative / multi-row content.

**Decision (ambiguity resolved):** the header blockquote's `> **User Approved:** yes | no` line
is a *different* concept from the summary's `summary_approved` -- it gates whether the KB
doc-set itself is approved (read by `summarize-preflight.sh`'s un-scoped
`grep -qE '^(> *)?\*\*User Approved:\*\* yes'`, which would break if this line were removed
without also updating that gate script -- out of scope for a templates-only task). DETAIL's
"genuinely never-parsed" header list names only `kb_status`/`kb_grade`/`last_kb_review`,
deliberately omitting this line, confirming it should stay untouched. Left as-is.

**Decision (ambiguity resolved):** DETAIL pairs `summary_approved` + `last_summary` together as
"currently read by `parse_kb_state`/`_parse_kb_summary_approval`" -- both values are in fact
read off the *same* ad hoc bold line (`**User Approved:** yes (date)`) that
`state-generate.md`/`state-approval.md` write below the table but the OLD template never
documented. Given the table's `User Approved` row was dead prose (reader never reads a table
row here) and `Last Run` names the same "when was the summary last generated" concept, both
rows were removed and replaced by the two frontmatter scalars -- eliminating the entire
table-row-vs-bold-line ambiguity in one move, per the BLUEPRINT Objective's stated bug trigger.

## Design conventions applied uniformly

- Any frontmatter placeholder value that would otherwise start with `{` (a YAML flow-mapping
  indicator) is double-quoted (e.g. `started: "{YYYY-MM-DD}"`) to keep the template's YAML valid;
  closed-enum placeholder strings (e.g. `lifecycle: Running | Paused-Awaiting-Input | ...`) are
  left unquoted since they start with a plain word.
- All existing explanatory HTML comments in the markdown body are kept; each edited section
  gained one added sentence/clause pointing at the new frontmatter home for its relocated
  values, so a template reader isn't left looking at an empty section with no explanation.
- No reader/writer/skill-reference code was touched (task-002/004 scope); no on-disk STATE.md
  files were migrated (task-005 scope).
