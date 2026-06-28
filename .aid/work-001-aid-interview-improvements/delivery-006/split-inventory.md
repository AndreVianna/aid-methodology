# Split-Execution Inventory -- task-036 (delivery-006)

> Authoritative, RE-DERIVED-from-disk inventory consumed by task-037 (carve),
> task-038 (sweep), task-039 (render + prune + manifests), task-040 (verify).
> Re-derived against the THEN-current tree (post delivery-003/004/005 in-place
> edits to `canonical/skills/aid-interview/`), 2026-06-28. Authors no skill
> content; moves no files. ASCII-only.
>
> Split target: `aid-interview` -> **`aid-describe`** (FIRST-RUN / Q-AND-A /
> TRIAGE / CONTINUE / COMPLETION + the entire lite path + the feature-002 engine
> + the feature-003 seed step) and **`aid-define`** (FEATURE-DECOMPOSITION /
> CROSS-REFERENCE / DONE). Seam = the approved-`REQUIREMENTS.md` gate.
>
> Name-collision pre-check (D3): `canonical/skills/aid-describe`,
> `canonical/skills/aid-define`, `canonical/agents/aid-describe`,
> `canonical/agents/aid-define` do NOT exist -- both new names are collision-free.

---

## Section A -- Final `references/` partition (the carve map, task-037)

The current `canonical/skills/aid-interview/` holds **SKILL.md + README.md + 26
`references/*.md`** and **no `scripts/` dir** (the skill ships no scripts; its
only adjacent script is `canonical/aid/scripts/interview/parse-recipe.sh`, a
recipe-tool surface handled by the external sweep, Section B). Partition is keyed
on the state machine (the RULE), grounded by which state loads each doc -- not a
frozen list -- so it absorbs the delivery-003/004 additions automatically.

### Dir-level / non-reference artifacts

| Artifact | Owner | How (task-037) |
|----------|-------|----------------|
| The directory itself (history carrier) | **aid-describe** | `git mv canonical/skills/aid-interview canonical/skills/aid-describe` -- carries git history for all files |
| `SKILL.md` | **aid-describe** keeps the carried file (re-authored to the describe identity); **aid-define** gets a NEW `SKILL.md` authored | partition State Detection / Dispatch tables |
| `README.md` | **aid-describe** keeps the carried file (re-authored); **aid-define** needs a NEW `README.md` authored | not tracked in `.aid/.aid-manifest.json` today -- see Flag F3 |
| `scripts/` | n/a -- none exists in this skill | -- |
| Dispatch agent `aid-interviewer` | **PRESERVED** (NOT renamed); stays `canonical/agents/aid-interviewer/`; remains aid-describe's FIRST-RUN/Q-AND-A/TRIAGE/CONTINUE/COMPLETION + L1 dispatch agent | substring guard, Section D |
| Dispatch agents `aid-architect`, `aid-reviewer` | unchanged; aid-describe keeps `aid-architect` (L2 TASK-BREAKDOWN) + `aid-reviewer` (L3 LITE-REVIEW); aid-define keeps `aid-architect` (decomposition) + `aid-reviewer` (cross-reference) | -- |

### references/*.md (26 total) -> 20 describe / 6 define

**aid-define (6 -- the approved-REQUIREMENTS -> feature-folders half).** All
present and confirmed unchanged by the content work (none loaded by any
describe-side state):

| File | State / loader | Confirmation |
|------|----------------|--------------|
| `state-feature-decomposition.md` | State 5 FEATURE-DECOMPOSITION | header `# State: FEATURE-DECOMPOSITION` |
| `feature-decomposition.md` | State 5 process doc | "Full process for State 5: decomposing approved Functional Requirements ..." |
| `state-cross-reference.md` | State 6 CROSS-REFERENCE | header `# State: CROSS-REFERENCE` |
| `cross-reference.md` | State 6 process doc | "# Cross-Reference & Refine Process" |
| `reviewer-brief.md` | loaded ONLY by State 6 | header literally "Loaded by `/aid-interview` CROSS-REFERENCE state (State 6)" -- the cross-ref brief, distinct from `aid-discover/references/reviewer-brief.md` (seed review) |
| `state-done.md` | State 7 DONE | "Interview is complete, approved, features decomposed, and cross-references validated ..." |

**aid-describe (20 -- intent-gathering / triage / interview / COMPLETION + the
entire lite path + the feature-002 engine + the feature-003 seed step):**

| File | Bucket | Notes |
|------|--------|-------|
| `state-first-run.md` | FIRST-RUN | scaffolds STATE.md + REQUIREMENTS.md |
| `state-q-and-a.md` | Q-AND-A | requirements-clarification loopback -> TRIAGE (intra-describe) |
| `state-triage.md` | TRIAGE | path/recipe routing (feature-004) |
| `state-continue.md` | CONTINUE | full-path interview loop (feature-002 engine) |
| `state-completion.md` | COMPLETION | describe terminal; the seam edit lives here (Section E) |
| `kb-hydration.md` | COMPLETION | "After interview completion ... extract ... into the Knowledge Base" |
| `state-condensed-intake.md` | L1 lite | lite path (whole lite path in describe) |
| `state-task-breakdown.md` | L2 lite | aid-architect dispatch |
| `state-lite-review.md` | L3 lite | aid-reviewer dispatch |
| `state-lite-done.md` | L4 lite | lite terminal -> /aid-execute |
| `lite-to-full-escalation.md` | lite->full | routes to CONTINUE; both ends in describe (intra) |
| `recipe-to-lite-escalation.md` | recipe->lite | both ends in describe (intra) |
| `interview-loop.md` | engine | filename keeps "interview" (activity, not command) -- NOT renamed |
| `interview-strategies.md` | engine | filename keeps "interview" -- NOT renamed |
| `elicitation-engine.md` | engine (feature-002) | loaded by state-continue/state-triage/state-completion/interview-loop/interview-strategies/state-describe-seed -- ALL describe |
| `move-playbook.md` | engine (feature-002) | loaded by describe-side states only |
| `calibration.md` | engine (feature-002) | loaded by describe-side states only |
| `advisor-stance.md` | engine (feature-002) | loaded by describe-side states only |
| `state-describe-seed.md` | seed step (feature-003) | loaded by SKILL only; the "aid-describe step" |
| `coherence-check.md` | seed step (feature-003) | loaded ONLY by `state-describe-seed.md`; the seed-vs-REQUIREMENTS coherence gate -- describe |

**delivery-003/004 additions captured & classified (not in the SPEC's frozen
table -- the RULE classifies them):** `elicitation-engine.md`, `move-playbook.md`,
`calibration.md`, `advisor-stance.md` (feature-002 engine), `state-describe-seed.md`,
`coherence-check.md` (feature-003 seed step) -- **all 6 -> aid-describe**. None is
loaded by a define-side state; the 6 aid-define refs are unaffected by the content
work. Count check: 20 describe + 6 define = 26 = on-disk `references/` count. PASS.

---

## Section B -- External sweep-target inventory (the blast radius, task-038/039)

Boundary-aware token = `aid-interview` NOT followed by `er` (the protected
`aid-interviewer` agent). Two live token shapes are swept: the `/aid-interview`
command token (-> `/aid-describe` or `/aid-define` per context) and the
`skills/aid-interview/` path token (-> `skills/aid-describe/` or
`skills/aid-define/`). The deliberately-kept reference *filenames*
`interview-loop.md` / `interview-strategies.md` contain "interview" but NOT
"aid-interview", so they are not matched and stay as-is.

**Owner routing rule:** intake / triage / lite / interview / COMPLETION /
KB-hydration -> **`/aid-describe`**; decomposition / cross-reference / DONE ->
**`/aid-define`**.

### B.1 Canonical authored surfaces (hand-swept by task-038)

| Surface | Files (count) | New owner | Notes |
|---------|---------------|-----------|-------|
| Skill carve | `canonical/skills/aid-interview/**` (22 files / 92 matches) | self-ref rewrite during carve (task-037, not 038) | each `/aid-interview` self-ref + `skills/aid-interview/...` example path -> owning new name; `state-feature-decomposition.md` writeback `--value aid-interview` -> `aid-define`; describe writebacks -> `aid-describe` |
| Interviewer agent README | `canonical/agents/aid-interviewer/README.md:22` ("Typically invoked by the **aid-interview** skill") | `/aid-describe` | bare-name ref -> aid-describe (the entry skill that dispatches the interviewer). The DIR + agent NAME `aid-interviewer` are PRESERVED; only this one boundary-aware token is swept |
| Recipes | `canonical/aid/recipes/*.md` (51 files) + `recipes/README.md` | `/aid-describe` | lite/TRIAGE refs -> aid-describe; loaded by TRIAGE which is in describe |
| Recipe + KB tooling | `canonical/aid/scripts/interview/parse-recipe.sh`, `canonical/aid/scripts/kb/recon-classify.sh` | `/aid-describe` | triage/recipe tooling |
| Templates | `canonical/aid/templates/` (14 files): `recipe-template.md`, `work-state-template.md`, `reviewer-ledger-schema.md`, `reviewer-dispatch.md`, `state-machine-chaining.md`, `specs/{spec-template,lite-spec-template}.md`, `requirements/requirements-template.md`, `knowledge-base/{README,pipeline-contracts,integration-map,infrastructure,feature-inventory,domain-glossary}.md` | per context | decomposition/cross-ref/DONE -> /aid-define; intake/triage/lite/interview -> /aid-describe |
| Other canonical skills (15 files) | `aid-plan/{SKILL.md,references/reviewer-brief.md}`, `aid-specify/{SKILL.md,references/reviewer-brief.md}`, `aid-detail/SKILL.md`, `aid-config/README.md`, `aid-deploy/README.md`, `aid-monitor/{SKILL.md,README.md,references/state-route.md}`, `aid-summarize/README.md`, `aid-discover/{README.md,references/path-config.md,references/reviewer-brief.md,references/state-generate.md}` | per context | decomposition/cross-ref -> /aid-define; intake/triage -> /aid-describe. NOTE: the `reviewer-brief.md` files in aid-plan/aid-specify/aid-discover are DISTINCT files (not the moving define one). `aid-discover/references/state-generate.md` = the delivery-005 shared file (sequencing edge) |

### B.2 Front-page / examples / docs / dashboard (hand-swept by task-038)

| Surface | Files | New owner | Notes |
|---------|-------|-----------|-------|
| Root README | `README.md` (5 matches): L31 Mermaid node `2 . aid-interview`, L148 quick-start, L161 brownfield/greenfield flow, L230 TRIAGE blurb | the Interview phase becomes the two-command sequence `/aid-describe -> /aid-define`; intake/TRIAGE/quick-start tokens -> `/aid-describe` | Mermaid node = two-command phase |
| Examples (8 files) | `examples/README.md`, `greenfield/{README.md,samples/REQUIREMENTS.md}`, `brownfield-full-path/{README.md,sample-spec-excerpt.md}`, `brownfield-lite-path/{README.md,sample-spec.md,sample-task-001.md}` | lite samples -> `/aid-describe`; full-path decomposition refs -> `/aid-define` | -- |
| Dashboard UI | `dashboard/home.html` + vendored `.aid/dashboard/home.html` (the `'/aid-interview'` next-step hint) | `/aid-describe` (entry command) | KEEP both copies lockstep |
| Dashboard test + producer | `dashboard/server/tests/test_index_html.py` (asserts exact command string) + `dashboard/reader/derivation.py` (producer comments) | `/aid-describe` | update asserted string to match home.html |
| Docs site source | `site/scripts/gen-reference.mjs` (Define group: replace 1 entry with 2; count 13->14, Section C) | -- | skills-drift guard structurally forces SKILL_GROUPS to match disk |
| Docs site hand-authored (8 files w/ token) | `site/src/content/docs/`: `index.mdx`, `get-started/{first-work,lite-path}.mdx`, `guides/pipeline.mdx`, `concepts/{faq,methodology}.md`, `reference/{glossary,artifacts}.md` | per context | + count surfaces (Section C) |
| Docs site generated | `site/src/content/docs/reference/skills.md` | regenerated (do-not-edit) | by gen-reference.mjs |
| Legacy docs (3 files) | `docs/{aid-methodology.md, faq.md, glossary.md}` | per context | + count surfaces (Section C); methodology L71/75 token `/aid-interview's TRIAGE` -> `/aid-describe's TRIAGE` |
| Tests (4 files) | `tests/canonical/{test-path-fixtures,test-pipeline-status-walkthrough,test-parse-recipe,test-work-state-template}.sh` | per context | update fixtures/expected skill-name strings to the split names |

### B.3 Generated / mirror surfaces (NOT hand-swept -- produced by task-039)

These are regenerated by the FULL generator
(`python .claude/skills/generate-profile/scripts/run_generator.py`) and the
dogfood mirror sync; they must NOT be hand-edited (render-drift CI keys on the
full emission manifests):

| Surface | Files | Action (task-039) |
|---------|-------|-------------------|
| Generated host trees (x5) | `profiles/{antigravity/.agent,claude-code/.claude,codex/.codex,copilot-cli/.github,cursor/.cursor}/skills/aid-interview/**` (506 files / 1567 matches total across the 5 trees) | emit `aid-describe/` + `aid-define/`; prune `aid-interview/` |
| Emission manifests (x5) | `profiles/*/emission-manifest.jsonl` (all 5 carry the token) | rewritten by generator |
| Dogfood mirror | `.claude/skills/aid-interview/**` + other `.claude/` mirror refs (102 files / 261 matches) | remove `aid-interview/`; add `aid-describe/` + `aid-define/`; re-sync mirror of canonical |
| Dogfood install manifest | `.aid/.aid-manifest.json` (21 matches) | path-replace each `.claude/skills/aid-interview/...` -> aid-describe/aid-define path. **SEE FLAG F3 -- manifest is missing 6 new refs; a naive rename strands them** |
| Vendored KB dashboard | `.aid/dashboard/home.html` -- see B.2 (in scope); `.aid/dashboard/kb.html` -- OUT OF SCOPE (generated by /aid-summarize from the dogfood KB -> /aid-housekeep) | home.html swept; kb.html deferred |

### B.4 Explicitly OUT OF SCOPE (must NOT be swept)

Confirmed present-but-excluded on disk:

- `.aid/knowledge/**` -- the dogfood KB (incl. its `N user-facing skills` count
  surfaces) -> deferred to `/aid-housekeep`.
- `.aid/work-*/**` -- historical changelog source-tags + the feature/delivery
  SPECs themselves (incl. THIS work-001 tree).
- `.aid/design/**` -- design seeds.
- `.aid/dashboard/kb.html` -- generated KB dashboard (KB-derived) -> /aid-housekeep.
- `dashboard/reader/tests/test_feature009.py` + `dashboard/server/tests/fixtures/pt1-aid/.aid/work-*/**`
  (`work-001-running-parallel/REQUIREMENTS.md`, `work-002-paused/REQUIREMENTS.md`,
  `work-003-blocked/REQUIREMENTS.md`, `work-004-completed/REQUIREMENTS.md`,
  `work-006-lite-sample/SPEC.md`) -- frozen sample data; no pytest job in CI.
  Sweeping these corrupts the fixtures.
- Reference *filenames* `interview-loop.md` / `interview-strategies.md` -- the
  interviewing activity, not the command (Open Question: recommend NO rename).

### B.5 Surface totals (re-derived 2026-06-28)

- In-scope AUTHORED sweep-target files (canonical authored + site + docs + README
  + examples + tests + in-scope dashboard 3 + `.aid/dashboard/home.html` +
  `.aid/.aid-manifest.json`): **137 files** (of which 22 are the carve dir handled
  by task-037; ~115 are external task-038/039 targets).
- Generated/mirror files (task-039, not hand-swept): profiles x5 = 506,
  `.claude/` mirror = 102, plus the 5 emission manifests.
- Repo-wide files containing any `aid-interview` form (excl `.git`): 896 (the
  remainder beyond the above are the out-of-scope `.aid/**` records).

---

## Section C -- Count-surface inventory (13 -> 14, task-038)

In-scope shipped count surfaces, re-confirmed file:line on the THEN-current tree.
Both NUMERIC and SPELLED-OUT forms:

| # | File:line | Current text | Edit |
|---|-----------|--------------|------|
| 1 | `site/scripts/gen-reference.mjs:154` | `'AID ships **13 user-facing skills** across five pipeline groups...'` | `13 -> 14` |
| 2 | `site/scripts/gen-reference.mjs:177` | `description: 'All 13 AID pipeline skills...'` | `13 -> 14` |
| 3 | `site/scripts/gen-reference.mjs` `SKILL_GROUPS` (Define group, ~L147-151 guard) | 1 entry `aid-interview` | replace with 2: `aid-describe`, `aid-define` (guard enforces vs disk) |
| 4 | `site/src/content/docs/reference/skills.md:9` | `AID ships **13 user-facing skills**...` | regenerated -> `14` |
| 5 | `docs/aid-methodology.md:71` | `*Thirteen user-facing skills, five groups...` (also carries `/aid-interview's TRIAGE` token) | **`Thirteen -> Fourteen`** (spelled-out) |
| 6 | `docs/aid-methodology.md:85` | `*All 13 user-facing skills, their groups...` | `13 -> 14` |
| 7 | `docs/aid-methodology.md:843` | `  |-- skills/        (13 user-facing skills)` (tree diagram) | `13 -> 14` |
| 8 | `site/src/content/docs/concepts/methodology.md:75` | `*Thirteen user-facing skills...` (synced from docs:71; carries TRIAGE token) | **`Thirteen -> Fourteen`** |
| 9 | `site/src/content/docs/concepts/methodology.md:89` | `*All 13 user-facing skills...` | `13 -> 14` |
| 10 | `site/src/content/docs/concepts/methodology.md:847` | `  |-- skills/        (13 user-facing skills)` | `13 -> 14` |
| 11 | `docs/glossary.md:9` | `...delivered by 13 skills across 5 groups...` | `13 -> 14` |
| 12 | `site/src/content/docs/reference/glossary.md:13` | `...delivered by 13 skills across 5 groups...` | `13 -> 14` |
| 13 | `site/src/content/docs/guides/maintainer.mdx:361` | `...the full skill and agent set (13 skills, 9 agents)...` | `13 -> 14` |
| 14 | `site/src/content/docs/index.mdx:68` | `*Eleven user-facing skills . five groups...` | `Eleven -> Twelve` (+1 from its OWN base -- pre-existing 11-vs-13 drift NOT reconciled here) |
| 15 | `site/src/content/docs/index.mdx:81` | `Eleven user-facing skills across five groups deliver these phases.` | `Eleven -> Twelve` (+1 from its own base) |

**Sync note:** docs -> site mirroring (`methodology.md`, `glossary.md`) goes
through `site/scripts/sync-docs.mjs`; edit the `docs/` source then sync, do not
double-edit. `skills.md` is regenerated by `gen-reference.mjs`, never hand-edited.

**Pre-existing drift (do NOT fix here):** `index.mdx` says "Eleven" while
`skills.md`/methodology say "13/Thirteen". This feature increments each in-scope
surface from its OWN current value by +1 (so "Eleven" -> "Twelve"); reconciling
the cross-surface 11-vs-13 inconsistency is the `/aid-housekeep` count pass, not
this feature.

**Deferred to `/aid-housekeep` (NOT swept):** the broad `N user-facing skills`
reconciliation across the dogfood KB (`.aid/knowledge/architecture.md`,
`capability-inventory.md`, `release-tracking.md`, `STATE.md` Q&A,
`summary-src/sections/*.html` badges, `.aid/dashboard/kb.html`) -- precedent
Q26/Q27.

---

## Section D -- `aid-interviewer` substring-guard baseline (task-040 assertion)

`aid-interview` is a prefix of the analyst agent `aid-interviewer`, which is NOT
renamed. The boundary-aware sweep (token followed by non-`-`/non-word char, or
the explicit `/aid-interview` / `skills/aid-interview/` tokens) MUST leave every
`aid-interviewer` token intact. Authoritative PRE-SPLIT baseline (re-derived
2026-06-28):

| Scope | Files | Matches |
|-------|-------|---------|
| SPEC-cited surface set (`canonical/ profiles/ .claude/ site/ docs/`) | **56** | **138** |
| + `.aid/.aid-manifest.json` (1 file / 1 match: `.claude/agents/aid-interviewer.md`) -- the swept manifest | **57** | **139** |
| Repo-wide (excl `.git`, incl `.aid/**`) | 67 | -- |

**Primary guard baseline = 56 files / 138 matches** over the SPEC's 5-dir set
(matches the SPEC's "56 files" citation exactly). Because task-039 also rewrites
`.aid/.aid-manifest.json` (which carries the protected `.claude/agents/aid-interviewer.md`
path), task-040 should assert the **57 files / 139 matches** figure over the
sweep's full surface set (5 dirs + the manifest). task-040 asserts: post-sweep
`grep -rn "aid-interviewer"` count == this baseline (unchanged), and the
`canonical/agents/aid-interviewer/` dir is untouched and still aid-describe's
dispatch agent.

---

## Section E -- Inter-skill seam (informational; built by task-037)

The split makes exactly ONE state-machine edit beyond moving files: COMPLETION
(in aid-describe) is ALREADY a PAUSE-FOR-USER-DECISION today (state-completion.md;
SPEC cites :124/:131) -- it prints `Re-run /aid-interview to continue to [State:
FEATURE-DECOMPOSITION]` + a pipeline `Pause Reason`/resume writeback and EXITS.
It does NOT chain. The edit REDIRECTS that existing resume signpost +
pause-signal writeback from `/aid-interview` to **`/aid-define {work}`**. aid-define's
State Detection precondition is `## Interview State: Approved`. No pause->chain
conversion exists. (Verify exact line numbers in state-completion.md at task-037
build time -- the content deliveries may have shifted them.)

---

## Flags / deviations from the feature SPEC blast-radius table

- **F1 (DEVIATION -- agents narrower than the SPEC table).** The SPEC's
  Layers-&-Components table lists `aid-orchestrator` + `aid-architect` AGENT/README
  as command-token sweep targets. RE-DERIVED: on the current tree these files
  contain ONLY the protected agent token `aid-interviewer` (orchestrator
  README:37 + AGENT:37 "Q&A entry ... aid-interviewer"; architect README:41
  "**aid-interviewer** | Interviewer captures..."), NOT any boundary-aware
  `/aid-interview` command token. They are therefore NOT command-token sweep
  targets and MUST NOT be swept (sweeping would corrupt `aid-interviewer`). The
  ONLY agents-surface sweep target is `aid-interviewer/README.md:22` (the bare
  "aid-interview skill" mention -> aid-describe). `aid-interviewer/AGENT.md` has
  NO boundary-aware command token. task-038: scope agents sweep to that one line.

- **F2 (kb.html scope).** `.aid/dashboard/kb.html` carries the token but is the
  KB-derived summary dashboard (generated by `/aid-summarize` from `.aid/knowledge`)
  -- OUT OF SCOPE, deferred to `/aid-housekeep`, symmetric with the `.aid/knowledge`
  exclusion. Only `.aid/dashboard/home.html` (vendored per-repo home) is swept.

- **F3 (CRITICAL -- dogfood manifest is stale/incomplete).**
  `.aid/.aid-manifest.json` lists only **20** of the 26 `references/*.md` (SKILL.md
  + 20 refs + the `aid-interviewer.md` agent). It is MISSING the 6 delivery-003/004
  additions: `advisor-stance.md`, `calibration.md`, `coherence-check.md`,
  `elicitation-engine.md`, `move-playbook.md`, `state-describe-seed.md`; it also
  does NOT track `README.md`. A naive task-039 "path-replace existing
  `aid-interview` entries -> aid-describe" would STRAND these 6 new describe-side
  files (never added under aid-describe) and would not add aid-define's README.
  **task-039 must regenerate / re-derive the FULL post-split file set into the
  manifest (all 26 partitioned refs + both SKILL.md + both README.md), not merely
  rename the 20 existing entries.** task-040 must assert the manifest enumerates
  the complete aid-describe + aid-define file set.

- **F4 (no `scripts/` in the skill).** The skill ships no `scripts/` dir; the
  only "interview" script is `canonical/aid/scripts/interview/parse-recipe.sh`
  (a recipe-tool surface, swept in B.1, dir name unchanged).

- **F5 (delivery-005 shared file).** `aid-discover/references/state-generate.md`
  is edited by BOTH delivery-005 (adds `output_root`) and this delivery's
  name-sweep -- the documented sequencing edge; d006 runs AFTER d005, never
  parallel.

- **No ambiguous/shared references remain.** Every one of the 26 refs resolves to
  exactly one owner by the state-machine RULE; `reviewer-brief.md` (aid-define)
  and `kb-hydration.md` (aid-describe) -- the SPEC's named boundary cases -- are
  confirmed on disk. The same-named `reviewer-brief.md` files in
  aid-plan/aid-specify/aid-discover are DISTINCT files and stay put (sweep their
  token content only).
