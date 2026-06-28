# task-038: Boundary-aware external skill-name sweep + 13->14 count-increment surfaces

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-006

**Depends on:** task-037

**Scope:**
- Execute Flow steps 3 + 6 (source side) of the feature SPEC: rewrite every EXTERNAL skill-name
  reference surface (outside the two carved dirs that task-037 owns) so the single `aid-interview`
  command splits across the correct new command, and INCREMENT every in-scope skill-count surface by
  one (13->14), driven by the task-036 sweep-target + count-surface inventory. Edits source files only;
  it runs no generator (task-039 does all rendering/regeneration). The replacement is
  **boundary-aware** -- match the `/aid-interview` command token and the `skills/aid-interview/` path
  token (and `aid-interview` followed by a non-`-`/non-word char), NEVER a naive global replace, so
  every `aid-interviewer` agent token is left verbatim.
- **External skill-name surfaces (route each mention to the correct half -- intake/triage/lite/
  interview/COMPLETION -> `/aid-describe`; decomposition/cross-reference/DONE -> `/aid-define`):**
  - Calling agents: `canonical/agents/{aid-orchestrator,aid-interviewer,aid-architect}/{AGENT,README}.md`
    (the `aid-interviewer` dir/name itself stays UNCHANGED -- only its skill mentions are rewritten).
  - Recipes + tooling: `canonical/aid/recipes/*.md`, `canonical/aid/scripts/interview/parse-recipe.sh`,
    `canonical/aid/scripts/kb/recon-classify.sh` (lite/triage refs -> `/aid-describe`).
  - Templates: `canonical/aid/templates/**` (requirements, specs, work-state, reviewer-*,
    recipe-template, state-machine-chaining, KB templates).
  - Other canonical skills: `aid-discover` (incl. `references/state-generate.md`), `aid-detail`,
    `aid-monitor`, `aid-config`, `aid-deploy`, `aid-specify` READMEs/SKILLs/refs that name the skill.
  - Root `README.md`: the Mermaid pipeline node + quick-start + flow + TRIAGE blurb -- the single
    `/aid-interview` node becomes the two-command Interview phase (`/aid-describe -> /aid-define`).
  - `examples/` (README + greenfield + brownfield-full + brownfield-lite) -- lite samples ->
    `/aid-describe`; full-path decomposition refs -> `/aid-define`.
  - Dashboard empty-state: `dashboard/home.html` + vendored `.aid/dashboard/home.html` next-step hint
    `'/aid-interview'` -> the FIRST step `/aid-describe` (kept in lockstep); update the paired assertion
    in `dashboard/server/tests/test_index_html.py` and refresh `dashboard/reader/derivation.py`
    producer comments to match.
  - Docs-site source: in `site/scripts/gen-reference.mjs` replace the single `Define`-group entry
    `{ name: 'aid-interview', ... }` with TWO entries (`aid-describe`, `aid-define`; group becomes
    `aid-describe, aid-define, aid-specify`) -- the skills-drift guard enforces SKILL_GROUPS against the
    on-disk `canonical/skills/` listing task-037 produced; increment the `**13 user-facing skills**`
    intro string (~line 154) and the `All 13 AID pipeline skills` description (~line 177) to **14**.
  - Hand-authored site pages: `site/src/content/docs/{index.mdx, get-started/{first-work,lite-path}.mdx,
    guides/pipeline.mdx, guides/maintainer.mdx, concepts/{faq,methodology}.md, reference/{glossary,
    agents,artifacts}.md}` -- rewrite skill-name mentions to the correct half.
  - Legacy docs: `docs/{aid-methodology.md, faq.md, glossary.md}` -- rewrite mentions.
  - Tests: `tests/canonical/{test-pipeline-status-walkthrough,test-path-fixtures,test-parse-recipe,
    test-work-state-template}.sh` -- update fixtures/expected skill-name strings to the split names.
- **Count-increment surfaces (numeric AND spelled-out, per the Skill-Count Delta):** increment each
  in-scope surface from its OWN current value by +1: `docs/aid-methodology.md` + synced
  `site/.../concepts/methodology.md` -- BOTH the spelled-out `**Thirteen** user-facing skills` opener
  -> `**Fourteen**` AND any `13 user-facing skills`/`(13 user-facing skills)` numeric -> `14` (a
  numeric-only edit would ship a "Thirteen.../14" contradiction); `glossary.md` (site + legacy)
  `13 skills` -> `14`; `maintainer.mdx` `13 skills, 9 agents` -> `14`; `index.mdx` increment from its
  own base (the pre-existing 11-vs-13 drift is NOT silently reconciled here -- left to /aid-housekeep).
- **Substring guard (carried forward).** After the sweep, `grep -rn "aid-interviewer"` over the
  shipped/canonical surface set must equal the task-036 baseline (unchanged); verify before declaring
  done (task-040 re-asserts at the gate).
- **Out of scope:** the two carved dirs' self-references (task-037); running ANY generator -- the
  `run_generator.py` host-tree render, the `gen-reference.mjs`/`sync-docs.mjs` docs regen, the
  generated `skills.md`, and the dogfood `.aid/.aid-manifest.json` path-replace all happen in task-039;
  the out-of-scope surfaces (`.aid/knowledge/`, `.aid/work-*/`, `.aid/design/`, frozen dashboard
  fixtures + `test_feature009.py`).

**Acceptance Criteria:**
- [ ] Every external sweep-target surface in the task-036 inventory has its live `/aid-interview` +
  `skills/aid-interview/` tokens rewritten to the correct new command (intake/triage/lite/interview/
  COMPLETION -> `/aid-describe`; decomposition/cross-reference/DONE -> `/aid-define`); `grep -rn`
  finds zero live `/aid-interview` command tokens or `skills/aid-interview/` path tokens across the
  swept source surfaces. *(gate criterion 1,3 / AC-1,AC-3)*
- [ ] `gen-reference.mjs` SKILL_GROUPS Define group is `aid-describe, aid-define, aid-specify` (two
  entries replace one) and the two intro count strings read **14**; the dashboard home.html (both
  copies) hint reads `/aid-describe` with the paired `test_index_html.py` assertion + `derivation.py`
  comments updated to match. *(gate criterion 3 / AC-3)*
- [ ] Count surfaces incremented for +1 -- both numeric (`13 -> 14`) AND spelled-out (`Thirteen ->
  Fourteen`) in methodology (site + legacy); glossary/maintainer/index incremented from their own
  base; no "Thirteen.../14" contradiction ships; the dogfood-KB count drift is left to /aid-housekeep.
  *(gate criterion 3 / AC-3)*
- [ ] Boundary-aware sweep: `grep -rn "aid-interviewer"` over the shipped/canonical surface set equals
  the task-036 baseline (unchanged before/after); the `aid-interviewer` agent dir/name is untouched.
  *(gate criterion 4 / AC-4)*
- [ ] No generator was run by this task (source edits only); shipped scripts/content stay ASCII-only.
  *(scope boundary; ASCII-only gate)*
- [ ] Unit/structural: edited shell scripts + JS parse; all REQUIREMENTS.md §6 quality gates that
  apply pre-render pass (full CI incl. docs/Astro + installer runs at task-040).
