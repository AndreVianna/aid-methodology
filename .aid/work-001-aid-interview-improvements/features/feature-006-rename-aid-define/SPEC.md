# Split aid-interview into aid-describe + aid-define

> Folder name `feature-006-rename-aid-define` is legacy (this feature began as a pure rename).
> Per owner decision D3 the feature is now a SPLIT, not a rename; the folder name is kept for
> traceability, the title and content are re-specified to the split.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-27 | Feature identified from REQUIREMENTS.md SS5 FR-6, SS6 NFR-6, SS8 D-3, SS9 AC-8, SS10 P3 | /aid-interview |
| 2026-06-27 | Technical Specification authored -- name-agnostic rename mechanics, blast-radius inventory, sequencing constraint, AC-8 DoD; grounded in aid-ask->aid-query-kb precedent | /aid-specify |
| 2026-06-27 | Spec revised post-review: blast radius +README.md/examples/dashboard(+vendored copy); DoD step-2 made true whole-repo; accurate whole-repo vs authored-subset counts; recon-classify path fixed; Open Questions added (dangling ref removed) | /aid-specify |
| 2026-06-27 | Spec re-review fixes: DoD step-2 closure carved to shipped/canonical surface set; count decomposition corrected (~493 generated profiles, ~99 dogfood mirror, ~26 .aid not-swept) | /aid-specify |
| 2026-06-27 | Cross-ref round-3 fix: `dashboard/` scope made symmetric to `.aid/`; frozen `dashboard/.../fixtures/**` + `test_feature009.py` marked out-of-scope | /aid-specify |
| 2026-06-27 | Cycle-4 re-verify (A+ gate): prose count decomposition fixed; all ledger rows Fixed -> **A+** | /aid-specify |
| 2026-06-27 | **RE-SPEC rename -> SPLIT (owner decision D3).** Feature changed from `aid-interview -> aid-define` (rename) to `aid-interview -> aid-describe + aid-define` (split at the approval gate). Rewrote Description, User Stories, Acceptance Criteria (FR-6 re-opened), and the entire Technical Specification: state partition (describe = TRIAGE/interview/COMPLETION + entire lite path; define = FEATURE-DECOMPOSITION/CROSS-REFERENCE), inter-skill seam at the approval gate, skill-count surfaces now **INCREMENT +1** (was held fixed), two skill dirs / split `references/` / two manifest entries / two docs-site entries. Carried forward the prior rename spec's propagation machinery (DBI / full-generator render / orphan-prune / install manifests / docs site) and the `aid-interviewer` substring-collision guard. Names fixed by D3 (`aid-describe`/`aid-define`); sequenced AFTER content features 002/003/004. | /aid-specify |
| 2026-06-27 | Gate cycle-1 fixes: (HIGH) corrected the inter-skill seam mechanism -- COMPLETION is ALREADY PAUSE-FOR-USER-DECISION on disk (state-completion.md:124/131), NOT a CHAIN; the edit is redirecting its existing resume signpost + pause-signal writeback from `/aid-interview` to `/aid-define`, not "converting CHAIN->HALT" (fixed 3 spots); (MEDIUM) added the spelled-out `Thirteen -> Fourteen` methodology surface (docs/aid-methodology.md:71 + synced site copy) to the count-increment enumeration, alongside the numeric 13->14 | /aid-specify |

## Source

- REQUIREMENTS.md SS5 FR-6 (RE-OPENED by D3), SS6 NFR-6, SS8 D-3, SS9 AC-8, SS10 P3
- `STATE.md ## Cross-phase Q&A` decision **D3** (the authority for the split) + context decisions D1/D2
- The finalized content specs feature-002 / feature-003 / feature-004 (in-place edits to the skill;
  the split operates on their FINAL file set)

## Description

`aid-interview` today is one skill that runs the whole "define the work" arc -- from the first
conversational turn through to graded, decomposed feature folders. Per owner decision **D3** this
feature **splits** it into **two** user-facing skills at the natural seam, the approved-requirements
gate, named for the informal-to-formal progression of the work:

- **`aid-describe`** -- the conversational, intent-gathering half. It owns FIRST-RUN, Q-AND-A,
  TRIAGE, the full-path interview (CONTINUE), COMPLETION (KB hydration + approval), **and the entire
  lite path** (CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW -> LITE-DONE; lite is full-path
  independent). It ends at an **approved `REQUIREMENTS.md`** (full path) or a ready lite task set.
  The user *describes* the need in their own words -- this is the half the [[D1]] opener
  ("describe the pieces the way you'd naturally name them") and the [[D2]] elicitation engine live
  in.
- **`aid-define`** -- the shaping half. It begins from the approved `REQUIREMENTS.md` and owns
  FEATURE-DECOMPOSITION + CROSS-REFERENCE -> graded feature folders, then DONE. It feeds
  `aid-specify`. The loose description is given *definite shape* as the concrete feature set.

This is **not** the rename the prior spec described, and the contrast is load-bearing: a rename is
count-neutral, a split is **+1 skill** -- one skill becomes two, so every skill-count surface must
**INCREMENT** (the prior spec deliberately held them fixed). The split otherwise **re-uses the prior
rename spec's full propagation machinery**: byte-identical render to the 5 host trees + dogfood
mirror (DBI), the FULL `run_generator.py` emission, orphan-prune of the old `aid-interview/` dir, the
install-manifest updates, the docs-site updates, and -- crucially -- the **`aid-interviewer`
substring-collision guard** (the `aid-interviewer` analyst *agent* is NOT renamed and `aid-interview`
is a prefix of it). **Sequencing:** this feature lands AFTER content features 002/003/004, which edit
`canonical/skills/aid-interview/` in place; the split partitions their FINAL file set, not today's.

## User Stories

- As an AID adopter, I want the informal "tell me what you want" step and the formal "shape it into
  features" step to be two clearly named commands (`aid-describe` then `aid-define`) so that the
  pipeline reads as the natural progression from intent to a defined feature set.
- As an AID maintainer, I want `aid-interview` split into `aid-describe` + `aid-define` with the
  state machine partitioned correctly, both new skills propagated byte-identically across all 5 host
  trees with the old directory orphan-pruned, the install manifests / docs site / skill-count
  surfaces updated for **+1 skill**, the `aid-interviewer` agent untouched, and CI green -- so no
  channel ships a stale, broken, or miscounted reference.

## Priority

Should  *(REQUIREMENTS.md SS10 P3 -- a minor, ride-along change; gated AFTER the P1 content work)*

## Acceptance Criteria

- [ ] Given the split, when it ships, then `aid-interview` is replaced by **two** skills --
  `aid-describe` (FIRST-RUN / Q-AND-A / TRIAGE / CONTINUE / COMPLETION + the entire lite path) and
  `aid-define` (FEATURE-DECOMPOSITION / CROSS-REFERENCE / DONE) -- with the state machine and
  `references/` partitioned to match, and the inter-skill hand-off at the approved-`REQUIREMENTS.md`
  gate working (aid-describe halts at approval; aid-define begins from it). *(AC-8, re-scoped by D3)*
- [ ] Given the two new skills, when the generator runs, then `aid-describe/` and `aid-define/` are
  rendered **byte-identically** across the 5 host trees and the dogfood mirror, and the old
  `aid-interview/` directory is **orphan-pruned** from every tree. *(AC-8, NFR-6)*
- [ ] Given the split is one-skill-becomes-two, when it ships, then the install manifests, the
  docs-site entries, and the skill-count surfaces are updated for **+1 skill** (the count goes UP by
  one), and the two new skill dirs each have a manifest + docs-site entry. *(AC-8, D3)*
- [ ] Given `aid-interview` is a prefix of the `aid-interviewer` agent (which is NOT renamed), when
  the old token is removed, then the boundary-aware sweep leaves every `aid-interviewer` token intact
  (its count is unchanged before/after). *(AC-8)*
- [ ] Given the split, when CI runs, then CI is green -- render-drift, DBI, the `gen-reference.mjs`
  skills-drift guard, ASCII-only, installer (incl. Windows lane), and the docs/Astro build, including
  the master-only heavy gates. *(AC-8, NFR-6)*

---

## Technical Specification

> Re-authored by `/aid-specify` to owner decision **D3** (`STATE.md ## Cross-phase Q&A`), which
> supersedes the prior rename spec. This is an infra/tooling **split** -- the skill's conversational
> behavior is unchanged (it is partitioned, not rewritten); features 002/003/004 own the behavior
> changes and run first. Sections are adapted to the change-type: **Data Model** -> schema impact;
> **Feature Flow** -> the split execution sequence; **State Partition** -> the heart of the split;
> **Layers & Components** -> the affected-surface inventory; **State Machines** -> the inter-skill
> seam; **DoD / Verification** -> AC-8.

### Name decision (FIXED by D3 -- no longer deferred)

The prior spec left the new name a deferred work-time choice. **D3 fixes both names**: the
conversational half is **`aid-describe`** (command `/aid-describe`) and the shaping half is
**`aid-define`** (command `/aid-define`). Both:
- are `aid-`-prefixed (content-isolation cornerstone) and kebab-case (match all sibling skills);
- do not collide with an existing canonical skill dir (`aid-config`, `aid-deploy`, `aid-detail`,
  `aid-discover`, `aid-execute`, `aid-housekeep`, `aid-monitor`, `aid-plan`, `aid-query-kb`,
  `aid-specify`, `aid-summarize`, `aid-update-kb`) or any agent (`aid-interviewer`, `aid-architect`,
  `aid-reviewer`, `aid-orchestrator`, ...);
- are NOT a prefix of `aid-interviewer` (the un-renamed agent), so the *new* tokens introduce no
  substring collision (the only collision risk is in *removing* the old `aid-interview` token --
  Substring Guard below). D3 rejected `aid-start` (names a position, not an outcome -- repeats the
  flaw the original rename was meant to fix). No further owner ratification is required for the names.

### Data Model

**No schema changes.** This is a directory/identifier split; it touches no KB doc schema, no
frontmatter `source:` enum (feature-003 owns the `forward-authored` marker; this feature shares no
files with it), no `.aid` state shape, and no settings keys. The work-state template's `Active
Skill` enum (`aid-{skill} | none`) is generic and needs no change -- only the literal value the
split's states write changes (see State Machines).

### State Partition (the heart of the split)

D3 sets the seam at the approval gate. Every current `aid-interview` state and reference doc maps to
exactly one new skill. The partition is a **rule keyed on the state machine**, not a frozen file list
-- so it absorbs whatever describe-side files content features 002/003/004 add (engine docs, a
seed-authoring state, etc.):

> **Rule.** Conversational intent-gathering, triage, the full-path interview, COMPLETION/KB-hydration,
> and the **entire** lite path -> **`aid-describe`**. Approved-requirements -> feature folders
> (decomposition + cross-reference + the full-path terminal) -> **`aid-define`**.

| Current state | New skill | Reference doc(s) | Rationale |
|---------------|-----------|------------------|-----------|
| FIRST-RUN | aid-describe | `state-first-run.md` | Conversational entry; scaffolds STATE.md + REQUIREMENTS.md |
| Q-AND-A | aid-describe | `state-q-and-a.md` | Requirements-clarification loopback (interview re-entry); advances to TRIAGE (intra-describe). See Boundary refs |
| TRIAGE | aid-describe | `state-triage.md` | Path/recipe routing; engine-driven (feature-004) |
| CONTINUE | aid-describe | `state-continue.md` | Full-path interview loop (the feature-002 engine) |
| COMPLETION | aid-describe | `state-completion.md`, `kb-hydration.md` | KB hydration + present REQUIREMENTS for approval -- the describe terminal |
| L1 CONDENSED-INTAKE | aid-describe | `state-condensed-intake.md` | Lite path (entirely in describe) |
| L2 TASK-BREAKDOWN | aid-describe | `state-task-breakdown.md` | Lite path (aid-architect dispatch) |
| L3 LITE-REVIEW | aid-describe | `state-lite-review.md` | Lite path (aid-reviewer dispatch) |
| L4 LITE-DONE | aid-describe | `state-lite-done.md` | Lite terminal -> hand to /aid-execute |
| (lite escalation) | aid-describe | `lite-to-full-escalation.md`, `recipe-to-lite-escalation.md` | lite->full escalation routes to CONTINUE -- both ends are in describe, so escalation stays INTRA-describe (no cross-skill complexity) |
| (engine, feature-002) | aid-describe | `interview-loop.md`, `interview-strategies.md`, + the NEW `elicitation-engine.md` / `move-playbook.md` / `calibration.md` / `advisor-stance.md` | The elicitation engine lives wholly in the interview/CONTINUE half (D3 "Builds on" note) |
| (seed authoring, feature-003) | aid-describe | the additive seed-authoring state feature-003 adds inside the skill (the "aid-describe step") | feature-003 already names it the `aid-describe` step (its Placement note) |
| 5 FEATURE-DECOMPOSITION | aid-define | `state-feature-decomposition.md`, `feature-decomposition.md` | Approved REQUIREMENTS -> feature folders (aid-architect) |
| 6 CROSS-REFERENCE | aid-define | `state-cross-reference.md`, `cross-reference.md`, `reviewer-brief.md` | Grade feature decomposition vs KB/codebase (aid-reviewer) |
| 7 DONE | aid-define | `state-done.md` | Full-path terminal after cross-reference -> hand to /aid-specify |

**Shared / boundary refs (resolved):**
- `reviewer-brief.md` is loaded ONLY by CROSS-REFERENCE (State 6) -> **aid-define** (confirmed on
  disk: its header reads "Loaded by `/aid-interview` CROSS-REFERENCE state (State 6)"). Note the
  *seed* review (feature-003 / NFR-3) uses `aid-discover/references/reviewer-brief.md`, a different
  file -- not this one -- so there is no cross-skill contention.
- `kb-hydration.md` is loaded by COMPLETION -> **aid-describe** (its body: "After interview
  completion ... extract ... into the Knowledge Base").
- `state-q-and-a.md` (Q-AND-A) -> **aid-describe**: it is the *requirements*-clarification loopback
  and its dispatch advance is `-> TRIAGE` (both intra-describe). Q-AND-A may also touch feature
  `SPEC.md` files when a downstream answer affects a feature; that file-write is a describe action on
  define-owned artifacts and is acceptable (the interview is the single re-entry point for
  requirements Q&A). No file moves to aid-define on its account.
- `state-done.md` (DONE) -> **aid-define**: its `[1] Add more information` sub-action can edit
  REQUIREMENTS.md; in the split that path SHOULD point the user back to `/aid-describe` for
  requirements-level changes (a Detail-phase wording nuance, flagged in Open Questions -- it does not
  move the state).

**The hand-off (how describe ends and define begins):**
- **aid-describe terminal (full path):** COMPLETION runs KB hydration, presents REQUIREMENTS for
  approval; on approval (`## Interview State: Approved`) it pauses-and-exits with the hand-off prompt
  `Requirements approved. Run /aid-define {work} to decompose into features.` (COMPLETION is **already
  PAUSE-FOR-USER-DECISION** today -- the only explicit no-auto-advance gate -- and already exits with
  a `Re-run /aid-interview to continue to [State: FEATURE-DECOMPOSITION]` signpost + a pipeline
  `Pause Reason`/resume writeback (state-completion.md:124,131). It does NOT chain. The split does
  NOT change the pause itself; the ONE state-machine edit is **redirecting that resume signpost + the
  pause-signal writeback from `/aid-interview` to `/aid-define`**; see State Machines.)
- **aid-define entry:** its State Detection **precondition is `## Interview State: Approved`** (an
  approved `REQUIREMENTS.md` on disk -- the filesystem-is-truth contract is preserved). It then
  detects FEATURE-DECOMPOSITION (no feature folders) -> CROSS-REFERENCE (features exist, cross-ref
  not done) -> DONE, exactly the current sub-state logic, lifted verbatim. If invoked before approval
  it HALTs with `Run /aid-describe {work} first to gather and approve requirements.`
- **Composability rule:** each skill's State Detection owns ONLY its own states; when it detects a
  state belonging to the sibling, it prints a one-line hand-off pointer to the sibling command and
  HALTs (the two cross-pointers above). This keeps the two skills cleanly composable and preserves
  the lite path's full independence inside aid-describe.

### Feature Flow (the split execution sequence)

Canonical is the single source of truth; the 5 host trees are generated, never hand-edited. The
split re-uses the proven `aid-ask -> aid-query-kb` propagation precedent (work-001 f008/f009),
extended for **two emitted dirs + one removed dir**:

1. **Carve the canonical dirs (history-preserving).** `git mv
   canonical/skills/aid-interview canonical/skills/aid-describe` (the larger, conversational half --
   carries history for all files). Then create `canonical/skills/aid-define/` and `git mv` the
   define-owned files into `aid-define/references/`: `state-feature-decomposition.md`,
   `feature-decomposition.md`, `state-cross-reference.md`, `cross-reference.md`, `reviewer-brief.md`,
   `state-done.md`. All remaining `references/*.md` stay in `aid-describe/`.
2. **Author the two SKILL.md identities + partition the State Detection / Dispatch tables.**
   - `aid-describe/SKILL.md`: frontmatter `name: aid-describe`; the State Detection block keeps
     FIRST-RUN / Q-AND-A / TRIAGE / CONTINUE / COMPLETION + L1-L4; the frontmatter state-machine line
     becomes `FIRST-RUN -> Q-AND-A -> TRIAGE -> {full: CONTINUE -> COMPLETION [PAUSE -> /aid-define] |
     lite: CONDENSED-INTAKE -> TASK-BREAKDOWN -> LITE-REVIEW -> LITE-DONE}`; the COMPLETION dispatch
     row keeps its **PAUSE-FOR-USER-DECISION** advance (unchanged) -- only its resume signpost +
     pause-signal writeback retarget from `/aid-interview` to `/aid-define`; keep the `aid-interviewer` /
     `aid-architect` / `aid-reviewer` dispatch agents unchanged.
   - `aid-define/SKILL.md`: frontmatter `name: aid-define`; State Detection precondition `Interview
     State: Approved`, owning FEATURE-DECOMPOSITION / CROSS-REFERENCE / DONE; the state-machine line
     becomes `(Approved REQUIREMENTS) -> FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE [HALT ->
     /aid-specify]`; dispatch rows keep `aid-architect` (decomposition) and `aid-reviewer`
     (cross-reference).
   - In each renamed dir, rewrite the skill's own identity self-references: every `/aid-interview`
     command token and `aid-interview` self-reference, and any `.claude/skills/aid-interview/...`
     example path, to the owning new name. The `state-feature-decomposition.md` writeback (`--field
     "Active Skill" --value aid-interview`) becomes `aid-define`; describe-side writebacks become
     `aid-describe`.
3. **Update external skill-name reference surfaces** (callers, recipes, templates, docs) -- now
   **two** names replace one, and the **skill count INCREMENTS +1** (see Skill-Count Delta + Layers
   & Components).
4. **Render to the 5 host trees + orphan-prune the old dir.** Run the FULL generator `python
   .claude/skills/generate-profile/scripts/run_generator.py` (NOT per-script renderers -- render-drift
   CI keys on the full emission manifests). The deletion pass prunes the now-absent `aid-interview/`
   dir from each profile tree and emits BOTH `aid-describe/` and `aid-define/` byte-identically;
   it rewrites each `profiles/*/emission-manifest.jsonl`.
5. **Sync the dogfood mirror.** Remove `.claude/skills/aid-interview/`; add `.claude/skills/aid-describe/`
   and `.claude/skills/aid-define/` (byte-identical to the claude-code profile tree); update the
   dogfood install manifest `.aid/.aid-manifest.json` -- replace every `.claude/skills/aid-interview/...`
   path with the correct `.claude/skills/aid-describe/...` or `.claude/skills/aid-define/...` path
   (two entry sets, one removed).
6. **Update the docs site.** In `site/scripts/gen-reference.mjs`, replace the single `Define`-group
   entry `{ name: 'aid-interview', ... }` with **two** entries `{ name: 'aid-describe', ... }` and
   `{ name: 'aid-define', ... }` (the group becomes `aid-describe, aid-define, aid-specify`), and
   increment the hardcoded `13 user-facing skills` intro string + the `All 13 AID pipeline skills`
   description to **14** (Skill-Count Delta). The `gen-reference.mjs` **skills-drift guard** (it
   throws when `SKILL_GROUPS` != the on-disk `canonical/skills/` listing) STRUCTURALLY forces
   `SKILL_GROUPS` to match the two new dirs -- a missed entry fails the build. Regenerate
   `site/src/content/docs/reference/skills.md` (do-not-edit generated file) and update the
   hand-authored site/docs count + command surfaces (inventory below).
7. **Verify** (DBI byte-identity for both dirs, render-drift, old dir pruned, count surfaces +1,
   substring guard intact, green CI) -- see DoD.

### Skill-Count Delta (the key contrast with the prior rename spec)

The prior rename spec held the skill count **fixed** ("a rename does NOT change N user-facing
skills"). **D3 inverts this:** one skill becomes two, so the count goes **13 -> 14**. The in-scope
shipped count surfaces that MUST increment by one:

| Surface | Locus | Edit |
|---------|-------|------|
| Generated skills page intro | `site/scripts/gen-reference.mjs` line ~154 `**13 user-facing skills**` + line ~177 `All 13 AID pipeline skills` | `13 -> 14` (then regenerate `skills.md`) |
| Skills-drift guard | `site/scripts/gen-reference.mjs` `SKILL_GROUPS` (Define group) | replace 1 entry with 2 (`aid-describe`, `aid-define`); the guard at lines ~147-151 enforces it against disk |
| Generated skills page | `site/src/content/docs/reference/skills.md` `13 user-facing skills` | regenerated -> `14` |
| Methodology (site + legacy) | `docs/aid-methodology.md` + its synced `site/src/content/docs/concepts/methodology.md` -- BOTH numeric AND **spelled-out**: the `**Thirteen** user-facing skills` opener (docs:71 / site:75) PLUS any `13 user-facing skills` / `(13 user-facing skills)` numeric forms | **`Thirteen -> Fourteen`** (spelled-out) AND `13 -> 14` (numeric) -- the numeric-only edit would ship a "Thirteen ... / 14" contradiction; sync docs->site via `sync-docs.mjs` |
| Glossary totals (site + legacy) | `site/src/content/docs/reference/glossary.md`, `docs/glossary.md` (`13 skills across 5 groups`) | `13 -> 14` |
| Maintainer guide | `site/src/content/docs/guides/maintainer.mdx` (`13 skills, 9 agents`) | `13 -> 14` |
| Landing page total | `site/src/content/docs/index.mdx` (`Eleven user-facing skills` -- see drift note) | increment from its own base |

**Deferred to `/aid-housekeep` (NOT swept by this feature, per precedent).** The broad `N
user-facing skills` reconciliation across the **dogfood KB** (`.aid/knowledge/architecture.md`,
`capability-inventory.md`, `release-tracking.md`, `STATE.md` Q&A, `summary-src/sections/*.html`
badges, etc.) is handled separately by `/aid-housekeep` -- exactly as the prior spec deferred
`.aid/knowledge/` drift, and per the standing precedent that adding/removing a canonical skill leaves
"N user-facing skills" counts stale across ~10 KB docs and is reconciled by `/aid-housekeep`
(precedent Q26/Q27), not inline. **Pre-existing drift flagged:** `index.mdx` already says "Eleven"
while `skills.md` says "13" -- this feature increments each in-scope surface from its own current
value by +1; reconciling the cross-surface 11-vs-13 inconsistency itself is part of the
`/aid-housekeep` count pass, not this feature (it must not be silently "fixed" here). The DoD
count-check is scoped to this same in-scope surface set (not a whole-repo literal), exactly as the
sweep is.

### Substring Guard (carried forward, unchanged)

`aid-interview` is a **prefix of `aid-interviewer`** -- the analyst *agent* persona, which is **NOT
renamed by this feature** (its dir `canonical/agents/aid-interviewer/` stays; it is the dispatch
agent for aid-describe's FIRST-RUN/Q-AND-A/TRIAGE/CONTINUE/COMPLETION + L1, so aid-describe's SKILL.md
KEEPS referencing it). A naive global `aid-interview` -> {new} replacement would corrupt every
`aid-interviewer` token. The *new* names introduce no collision (neither is a prefix of
`aid-interviewer`); the risk is entirely in **removing** the old `aid-interview` token. The split
MUST therefore use a **boundary-aware match** (e.g. `aid-interview` followed by a non-`-`/non-word
char, or the explicit `/aid-interview` command token and the `skills/aid-interview/` path token) and
MUST verify with a post-pass `grep -rn "aid-interviewer"` count that is **unchanged** before/after
(baseline: 56 files carry the token across `canonical/`, `profiles/`, `.claude/`, `site/`, `docs/`).

### Layers & Components -- affected-surface inventory (blast radius)

The surface set mirrors the prior spec's (scoped via boundary-aware `grep`), with three structural
deltas from the split: **(a)** TWO emitted skill dirs + ONE removed dir (was one renamed dir);
**(b)** the `references/` set is **partitioned** between the two; **(c)** count surfaces
**INCREMENT** (was fixed) and the `aid-interview` command-token surfaces now **split across two
commands** (`/aid-describe` for intake/triage/lite, `/aid-define` for decomposition/cross-reference).

| Surface | Files / locus | Action |
|---------|---------------|--------|
| Canonical skill dirs | `canonical/skills/aid-interview/` -> `aid-describe/` (SKILL.md + describe refs) + new `aid-define/` (SKILL.md + the 6 define refs) | `git mv` carve + self-ref rewrite (Flow 1-2) |
| Generated host trees (x5) | `profiles/{antigravity/.agent,claude-code/.claude,codex/.codex,copilot-cli/.github,cursor/.cursor}/skills/{aid-describe,aid-define}/` (and removed `.../aid-interview/`) | regenerated, NOT hand-edited (Flow 4) |
| Emission manifests (x5) | `profiles/*/emission-manifest.jsonl` | rewritten by generator (Flow 4) |
| Dogfood mirror + manifest | `.claude/skills/aid-interview/` removed; `aid-describe/` + `aid-define/` added; `.aid/.aid-manifest.json` path-replace (two entry sets) | sync + path-replace (Flow 5) |
| Calling agents | `canonical/agents/{aid-orchestrator,aid-interviewer,aid-architect}/{AGENT,README}.md` | rewrite skill-name mentions -> the correct new command per context (both agents now reference both skills); `aid-interviewer` dir/name itself UNCHANGED (substring guard) -- re-render via generator |
| Recipes + recipe tooling | `canonical/aid/recipes/*.md`, `canonical/aid/scripts/interview/parse-recipe.sh`, `canonical/aid/scripts/kb/recon-classify.sh` | rewrite skill-name mentions (lite/triage refs -> `/aid-describe`) -- re-render via generator |
| Templates | `canonical/aid/templates/**` (requirements, specs, work-state, reviewer-*, recipe-template, state-machine-chaining, KB templates) | rewrite skill-name mentions to the correct new command |
| Other canonical skills | `aid-discover`, `aid-detail`, `aid-monitor`, `aid-config`, `aid-deploy`, `aid-specify` READMEs/SKILLs/refs that name the skill | rewrite mentions (decomposition/cross-ref -> `/aid-define`; intake/triage -> `/aid-describe`) |
| Repo front page | root `README.md` -- the Mermaid pipeline node + quick-start + flow + TRIAGE blurb | the single `/aid-interview` node becomes the **two-command Interview phase** (`/aid-describe -> /aid-define`); rewrite the command tokens to the correct half |
| Examples | `examples/` (README + greenfield + brownfield-full + brownfield-lite samples) | rewrite `/aid-interview` command refs to the correct half (lite samples -> `/aid-describe`; full-path decomposition refs -> `/aid-define`) |
| Dashboard empty-state UI | `dashboard/home.html` + vendored `.aid/dashboard/home.html` (the `'/aid-interview'` next-step hint) -- keep both in lockstep | rewrite the literal command string to the **first** step `/aid-describe` (the entry command) in both copies |
| Dashboard paired test + producer comments | `dashboard/server/tests/test_index_html.py` (asserts the exact command string) + `dashboard/reader/derivation.py` producer comments | update the asserted string to match home.html (`/aid-describe`); refresh comments |
| Docs site (generated) | `site/scripts/gen-reference.mjs` (source: split entry + count+1), `site/src/content/docs/reference/skills.md` (regen) | two entries, count 13->14, regen (Flow 6) |
| Docs site (hand-authored) | `site/src/content/docs/{index.mdx, get-started/{first-work,lite-path}.mdx, guides/pipeline.mdx, concepts/{faq,methodology}.md, reference/{glossary,agents,artifacts}.md}` | rewrite skill-name mentions to the correct half; increment count surfaces (Skill-Count Delta) |
| Legacy docs | `docs/{aid-methodology.md, faq.md, glossary.md}` | rewrite mentions + increment count surfaces |
| Tests | `tests/canonical/{test-pipeline-status-walkthrough,test-path-fixtures,test-parse-recipe,test-work-state-template}.sh` | update fixtures/expected skill-name strings to the new split names |

**Pipeline phase mapping (D3 consequence 3).** The pipeline "Interview" phase, today delivered by
one skill, now maps to **two** skills in order: `aid-describe -> aid-define` (then `aid-specify` is
the separate Specify phase). The `gen-reference.mjs` `Define` group becomes `aid-describe,
aid-define, aid-specify`. Any pipeline-diagram / phase-table surface (README Mermaid,
methodology phase list, dashboard pipeline view) that renders the Interview phase as a single command
must render the two-command sequence.

**Out-of-scope surfaces (carried forward, unchanged from the prior spec):** `.aid/knowledge/` (the
dogfood KB -- deferred to `/aid-housekeep`, including its count surfaces), `.aid/work-*/` +
`.aid/design/` (historical changelog source-tags + the feature SPECs themselves), and
`dashboard/server/tests/fixtures/**/.aid/work-*` + `dashboard/reader/tests/test_feature009.py`
(frozen sample data; no pytest job runs in CI). Sweeping these would corrupt records/fixtures. The
deliberately-kept reference *filenames* carrying the substring "interview" (`interview-loop.md`,
`interview-strategies.md`) are content artifacts (the interviewing *activity*, not the command) and
stay as-is unless features 002/003/004 already restructured them (Open Questions).

### State Machines (the inter-skill seam)

The skill's conversational *behavior* is unchanged -- the states are **partitioned, not altered**
(internal state names `state-first-run.md`, `state-triage.md`, etc. are unchanged; any behavior
change belongs to features 002-005). The split introduces exactly **one** state-machine edit beyond
moving files: **redirecting the existing approval-gate pause signpost** to the sibling skill.

- **Today:** COMPLETION is **PAUSE-FOR-USER-DECISION** (the only no-auto-advance gate in the
  methodology): on approval it prints `[Pause] ... Re-run /aid-interview to continue to [State:
  FEATURE-DECOMPOSITION]` + the pipeline `Pause Reason`/resume writeback (state-completion.md:124,131)
  and EXITS -- it already does NOT chain; FEATURE-DECOMPOSITION is reached by a fresh `/aid-interview`
  re-invocation that detects `Interview State: Approved` + no feature folders.
- **After the split:** COMPLETION (in aid-describe) pauses-and-exits **identically**; the ONE edit is
  that its resume signpost + pause-signal writeback now point to **`/aid-define {work}`** instead of
  `/aid-interview`. FEATURE-DECOMPOSITION (in aid-define) is the entry of that new invocation, whose
  State Detection precondition is `Interview State: Approved`. The pause stays a pause (no chain ever
  existed to convert); only its target skill changes. All other advances (Q-AND-A -> TRIAGE, TRIAGE -> CONTINUE/CONDENSED-INTAKE,
  FEATURE-DECOMPOSITION -> CROSS-REFERENCE, CROSS-REFERENCE -> DONE) are unchanged within their
  owning skill. The lite path's terminal (LITE-DONE -> HALT -> /aid-execute) and the lite->full
  escalation (-> CONTINUE) are wholly within aid-describe, unchanged.
- The `Pipeline State` writeback `Active Skill` value follows the owning skill (`aid-describe` for
  describe-side states; `aid-define` for FEATURE-DECOMPOSITION/CROSS-REFERENCE -- e.g.
  `state-feature-decomposition.md`'s `writeback-state.sh --field "Active Skill" --value` line);
  `Phase` stays `Interview` for both.

### Sequencing constraint (hard ordering)

**This feature MUST land AFTER content features 002/003/004** (REQUIREMENTS.md SS10 P3 + the D3
consequence 5). Those features edit `canonical/skills/aid-interview/` **in place** (C-2 -- extend,
don't fork): feature-002 rewrites SKILL.md + `interview-loop.md` / `interview-strategies.md` /
`state-continue.md` / `state-triage.md` and **adds** `elicitation-engine.md` / `move-playbook.md` /
`calibration.md` / `advisor-stance.md`; feature-003 adds an additive seed-authoring state (the
"aid-describe step") + edits `aid-discover` files; feature-004 edits `state-triage.md` +
`state-continue.md`. **The split partitions the FINAL `references/` set after 002/003/004 merge, not
today's** -- and every file they add or change is on the **describe** side (interview / CONTINUE /
TRIAGE / seed authoring), so aid-define's six files are unaffected by the content work. A directory
carve run concurrently with those in-place edits would collide or strand them. The aid-plan execution
graph MUST place feature-006 strictly downstream of 002/003/004 (it is NOT gated by the feature-001
spike).

### DoD / Verification -- operationalizes AC-8

The feature is **Done** when ALL hold (the split task's acceptance gate):

1. **Two canonical skills, partitioned + self-clean.** `canonical/skills/aid-describe/` and
   `canonical/skills/aid-define/` both exist (history preserved via `git mv`); the `references/` set
   is partitioned per State Partition (aid-define holds exactly the 6 define refs; all else in
   aid-describe). `grep -rn "aid-interview\b" canonical/skills/aid-describe/ canonical/skills/aid-define/`
   returns **zero** stale command/name self-references.
2. **Inter-skill seam works.** aid-describe's COMPLETION HALTs at approved REQUIREMENTS with the
   `/aid-define` hand-off; aid-define's State Detection requires `Interview State: Approved` and
   detects FEATURE-DECOMPOSITION -> CROSS-REFERENCE -> DONE; each skill's State Detection prints a
   hand-off pointer when it detects a sibling-owned state. The lite path completes entirely within
   aid-describe (LITE-DONE -> /aid-execute).
3. **Zero stale references -- scoped sweep matching the inventory.** A boundary-aware `grep -rn
   "aid-interview"` over the **shipped/canonical surface set** (`canonical/`, the 5 `profiles/`
   trees, the `.claude/` dogfood mirror, the install manifests = 5 `emission-manifest.jsonl` +
   `.aid/.aid-manifest.json`, `site/`, `docs/`, `tests/`, root `README.md`, `examples/`,
   `dashboard/home.html` + `.aid/dashboard/home.html`) returns **zero** live `/aid-interview` command
   tokens and `skills/aid-interview/` path tokens. The ONLY permitted remaining `aid-interview`-prefixed
   matches are the protected `aid-interviewer` agent (its `grep -rn "aid-interviewer"` count is
   **unchanged** vs pre-split -- baseline 56 files) and the deliberately-kept reference *filenames*
   (`interview-loop.md` / `interview-strategies.md`). Explicitly NOT in this sweep (consistent with
   the inventory): `.aid/knowledge/` (deferred to `/aid-housekeep`), `.aid/work-*/` + `.aid/design/`
   (historical records + the SPECs), and the frozen dashboard fixtures + `test_feature009.py`.
4. **5 trees rendered (both dirs) + old dir pruned.** Each `profiles/*/skills/aid-describe/` and
   `profiles/*/skills/aid-define/` exists, each `profiles/*/skills/aid-interview/` is gone, and each
   `emission-manifest.jsonl` reflects the swap (generator full run, clean).
5. **DBI byte-identity (both skills).** The DBI test passes -- `aid-describe/` is byte-identical
   across the 5 host trees and the dogfood mirror, and `aid-define/` likewise.
6. **Manifests + docs site current + count +1.** `.aid/.aid-manifest.json` paths updated for both
   dirs (old removed); `gen-reference.mjs` has two `Define`-group entries and the skills-drift guard
   passes against disk; the intro count is `14` and `skills.md` is regenerated to `14`; the in-scope
   hand-authored count surfaces (methodology / glossary / maintainer / index) are incremented;
   `grep aid-interview site/` returns zero live refs. The `.aid/knowledge` + `summary-src` count
   surfaces are left for `/aid-housekeep` (documented, not a gate failure).
7. **Substring guard intact.** `grep -rn "aid-interviewer"` count unchanged before/after; the
   `aid-interviewer` agent dir is untouched and is still aid-describe's dispatch agent.
8. **CI green.** render-drift, DBI, the `gen-reference.mjs` skills-drift guard, ASCII-only,
   installer (incl. Windows lane), and the docs/Astro build all pass on the PR -- the master-only
   heavy gates included (run `tests/run-all.sh` with HOME pinned + the `site` Astro build locally
   before claiming green, per the master-CI-only-on-master constraint).

Maps directly to AC-8 (re-scoped by D3: `aid-interview` split into two skills, byte-identical
propagation across 5 trees + mirror, old dir orphan-pruned, manifests/docs-site/skill-count surfaces
updated for **+1 skill**, `aid-interviewer` guard intact, CI green) and NFR-6 (DBI cross-tool parity).

### Open Questions

- **Final names.** RESOLVED by D3 -- `aid-describe` (intake/triage/lite/interview/COMPLETION) and
  `aid-define` (decomposition/cross-reference/DONE). No residual ratification needed; confirm at the
  Detail/Execute gate that no new sibling skill or agent collides (current set listed in *Name
  decision*).
- **DONE `[1] Add more information` re-entry (minor, Detail-phase).** `state-done.md` (aid-define) can
  edit REQUIREMENTS.md on `[1]`; in the split that requirements-level change ought to point the user
  back to `/aid-describe`. This is a hand-off-wording nuance, not a state move -- confirm the exact
  prompt at Detail.
- **Reference-filename rename (deliberately deferred -- recommend NO).** `interview-loop.md` /
  `interview-strategies.md` (now in aid-describe) carry the substring "interview". They name the
  interviewing *activity* (content), not the command; leave them unrenamed -- renaming is cosmetic
  churn with no functional effect and would also touch `.aid/.aid-manifest.json` path entries. Two
  caveats for aid-plan/aid-detail: (a) features 002/003/004 may already restructure these in place,
  so the split operates on their final `references/` set; (b) if a future naming-coherence pass
  renames them, it is a separate content change with its own self-reference + manifest updates.
