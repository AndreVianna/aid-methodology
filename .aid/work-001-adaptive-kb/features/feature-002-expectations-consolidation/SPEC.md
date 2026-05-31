# Consolidate Per-Doc Expectations Into One Source

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-30 | Feature drafted from approved REQUIREMENTS.md | /aid-interview FEATURE-DECOMPOSITION |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Review fix (D+→target A): made FIX-mode (state-fix.md Step 6) wiring a required edit + test; corrected block count 18→17; {project_context_file} formatting note | /aid-specify |

## Source

- REQUIREMENTS.md §4 (P0 — Pre-work / correctness), FR-P0-2

## Description

The per-document "expectations" (what each KB doc must contain and its red flags) are currently
duplicated near-verbatim between `document-expectations.md` and the `discovery-reviewer` agent
contract. The two copies can drift. This feature consolidates them into one source so that
authoring agents and the reviewer evaluate docs against the same expectations. This is the
surface the lean declared doc-set's per-doc expectations will resolve against (keyed by
filename), so consolidating it first gives the declared set a single clean target — without the
declared set having to re-declare expectations itself.

## User Stories

- As a discovery reviewer, I want one source for per-doc expectations so that I review against
  the same criteria the authoring agents were given.
- As a discovery sub-agent, I want my doc's expectations defined in exactly one place so that I
  am not following stale or divergent guidance.
- As an AID meta-repo maintainer, I want expectations de-duplicated so that the declared
  doc-set can reference a single, non-drifting source keyed by filename.

## Priority

Must

## Acceptance Criteria

- [ ] Given expectations currently live in both `document-expectations.md` and
      `discovery-reviewer`, when consolidated, then **`document-expectations.md` is the single
      canonical source** and `discovery-reviewer` no longer restates the per-doc expectations.
- [ ] Given the reviewer is a dispatched sub-agent that cannot "reference" a file it is not
      given, when consolidated, then the reviewer's dispatch is updated to **load
      `document-expectations.md` at review time** (e.g. read it / include it in the brief) so it
      evaluates against the canonical content rather than an embedded copy.
- [ ] Given the consolidation, when a doc's expectations are read by either an authoring agent
      or the reviewer, then both resolve to the identical expectations content.
- [ ] Given the change, when the generator self-tests and the existing canonical suites (13 today) run, then
      they stay green and render-drift across the 3 profiles is clean (non-regression).

---

## Technical Specification

> This is a methodology/tooling repo (Markdown + bash + a Python renderer), not an application —
> there is no DB/API/UI. The "implementation" is editing `canonical/` source files and re-rendering
> the 3 profiles + the dogfood `.claude/` tree byte-identically via `run_generator.py`.

### 0. Ground truth (verified on disk)

The per-doc "Must have / Red flags" expectations are duplicated in two canonical sources:

- `canonical/skills/aid-discover/references/document-expectations.md` — 17 per-doc blocks
  (verified: `grep -c '^### ' canonical/skills/aid-discover/references/document-expectations.md` = 17;
  `project-structure.md` line 7 … `{project_context_file}` line 102), introduced as *"what the
  reviewer (and FIX mode) should look for in each document"* (line 3). This is the **authoring-side**
  surface; `SKILL.md:319-322` points authoring agents at it.
- `canonical/agents/discovery-reviewer/AGENT.md` — a `## Document Expectations` heading
  (line 196) followed by a near-verbatim copy of the same blocks (`architecture.md` line 198 …
  `{project_context_file}` line 287). This is the **reviewer-side** embedded copy.

The two copies have already drifted (concrete evidence the risk is real, not theoretical):
`document-expectations.md` contains `project-structure.md` (line 7) and `external-sources.md`
(line 86) blocks that `AGENT.md` lacks; `AGENT.md` contains a `{reviewer_output_file}` block
(line 269) that `document-expectations.md` lacks. The doctrine line is also stale: `AGENT.md:294`
says the meta-docs derive from "16 primary KB docs" while `AGENT.md:94` says "14 primary KB docs"
— a 14-vs-16 instance handled by feature-004/FR-P0-4, out of scope here, but noted as a touched
neighbor.

The reviewer is **dispatched as a background sub-agent** (`AGENT.md:6` `background: true`). Its
embedded expectations are the only copy it can see at runtime, because a dispatched sub-agent can
only reference files that are in its tools' reach. There are **two** dispatch sites for
`discovery-reviewer`, both of which assemble the prompt from `references/reviewer-brief.md` +
`references/reviewer-prompt.md` and must therefore each perform the substitution independently
(substitution is agent-performed per state file — there is no shared render step):
(1) the discovery REVIEW state, `state-review.md:9-24` (Step 1); and
(2) the FIX-mode re-review, `state-fix.md:102-112` (Step 6, line 108 reuses `reviewer-prompt.md`).
None of those files currently mention `document-expectations.md` — the reviewer relies solely on the
AGENT.md copy at both sites.

Render targets that carry a copy of these blocks (all derived from the two canonical sources by
`run_generator.py`, so all edits are made in `canonical/` only):

- `document-expectations.md` → 4 rendered copies: `.claude/...`, `profiles/claude-code/.claude/...`,
  `profiles/cursor/.cursor/...`, `profiles/codex/.agents/...`.
- `discovery-reviewer` AGENT.md → rendered as **Markdown** in `.claude/agents/discovery-reviewer.md`,
  `profiles/claude-code/.claude/agents/discovery-reviewer.md`,
  `profiles/cursor/.cursor/agents/discovery-reviewer.md`, **and as a codex `.toml`** at
  `profiles/codex/.codex/agents/discovery-reviewer.toml` (the AGENT.md body becomes the toml
  `developer_instructions` string via `render_agents.py:_render_codex_toml`, line 186; verified the
  toml currently embeds the blocks at line 189). Editing canonical AGENT.md propagates the removal
  to **all four** rendered agent artifacts automatically — no per-profile hand-editing.

### 1. Canonical source decision

**`canonical/skills/aid-discover/references/document-expectations.md` is the single canonical
source** for per-doc expectations. Rationale: it already exists for exactly this purpose, is already
referenced by the authoring side (`SKILL.md:321`), and is keyed by filename — the structure
feature-004 requires (`feature-004/SPEC.md:89-91`).

**Required structure (a contract both sides resolve against):** the file is a flat sequence of
per-doc blocks, each keyed by a level-3 heading that is the doc's exact filename (or a known
placeholder token). The block immediately under the heading contains `Must have:` text and a
`**Red flags**:` line. This contract is what makes the source addressable by feature-004 "keyed by
filename":

```
### <filename>.md            ← key = exact KB doc filename, or a placeholder token
Must have: <criteria...>
**Red flags**: <signals...>
```

Keying rules (preserve current behavior — do not change WHAT is checked):

- One block per KB doc filename present in the default seed set (§8 of REQUIREMENTS.md).
- Placeholder-token keys stay as-is: `### {project_context_file}`, `### {reviewer_output_file}`,
  `### INDEX.md`, `### README.md` — these are resolved by the consuming agent the same way they are
  today (the tokens are substituted at dispatch/read time, not in the canonical file).
- The union of blocks across the two current copies is preserved into the single source so no
  expectation is lost in the merge (see §2, step 1).

This file does NOT gain frontmatter, a parser, or a schema file — it stays human-readable Markdown
(NFR "git-diffable, human-reviewable KB"; "convention over infrastructure"). "Keyed by filename" is
the `### <filename>.md` heading convention, not a new machine format.

### 2. Files & edits (exact)

All edits are in `canonical/`; profiles + dogfood are regenerated by `run_generator.py`.

**Edit 1 — Reconcile + complete the canonical source.**
File: `canonical/skills/aid-discover/references/document-expectations.md`.
Merge any reviewer-only content into it so it is the strict superset, then it becomes the only copy:

- Add a `### {reviewer_output_file}` block (port from `AGENT.md:269-277`) — currently missing from
  `document-expectations.md`, so dropping the AGENT.md copy without porting this would *lose* the
  reviewer-output expectations.
- Keep the existing `### project-structure.md` (line 7) and `### external-sources.md` (line 86)
  blocks — the reviewer gains these (it previously lacked them), which is a correctness improvement,
  not a behavior change to docs it already checked.
- No wording changes to any other block (preserve checked criteria verbatim).
- **Intra-block formatting drift — `### {project_context_file}`.** The two current copies already
  differ in whitespace: the canonical `document-expectations.md` copy splits Must-have/Red-flags with
  a blank line (`document-expectations.md:105`), while the reviewer-side `AGENT.md` copy is contiguous
  (no blank line). Because `document-expectations.md` is the single canonical source and is **kept**
  by this merge, the canonical copy's formatting (blank-line split) is authoritative and wins. The
  reviewer-side contiguous variant is simply dropped with the rest of the AGENT.md block (Edit 2) and
  **must not be reintroduced**. This is whitespace only — no criteria text differs — so no merge
  action is needed beyond keeping the canonical copy as-is; the note exists so the reviewer-side
  variant is not silently re-added during the AGENT.md edit.

**Edit 2 — Remove the duplicated block from the reviewer agent.**
File: `canonical/agents/discovery-reviewer/AGENT.md`.
Delete the entire `## Document Expectations` section and its per-doc blocks (lines 196-290, from the
`## Document Expectations` heading through the end of the `### {project_context_file}` block,
inclusive). Replace with a short pointer that names the canonical file and states the resolution
mechanism, e.g.:

```
## Document Expectations

The per-document "Must have / Red flags" criteria are NOT restated here — they live in a single
canonical source, `aid-discover/references/document-expectations.md`, so authoring agents and this
reviewer evaluate against identical content. The REVIEW-state dispatch includes that file's contents
in your prompt (see the discovery skill's reviewer-prompt). Use those expectations for the
Completeness Check (step 1) and Depth/Usefulness assessment.
```

Leave the `### 1. Completeness Check` step's existing pointer text (`AGENT.md:106` "see Document
Expectations below") retargeted to "see the Document Expectations provided in your dispatch prompt".

**Edit 3 — Make the dispatch load the canonical file (the load-at-review-time mechanism).**
File: `canonical/skills/aid-discover/references/reviewer-prompt.md` (the per-claim rubric body the
REVIEW-state appends to the brief and dispatches — `state-review.md:14-16`).
Add a step that **inlines the canonical expectations into the dispatched prompt**. Because the
reviewer is a background sub-agent, the robust mechanism is for the dispatcher (the skill body
executing the REVIEW state) to **read `references/document-expectations.md` and paste its contents
into the prompt** under a clearly delimited section, rather than relying on the sub-agent to open a
file it may not have in reach. Concretely, add to `reviewer-prompt.md`:

```
> **Document Expectations (authoritative):** The per-doc "Must have / Red flags" criteria are the
> single canonical set in aid-discover/references/document-expectations.md. The dispatcher inlines
> that file's full contents below this line at review time; evaluate Completeness (step 2) and
> Depth/Usefulness (steps 4–5) against exactly those criteria — do not improvise alternatives.
>
> --- BEGIN DOCUMENT EXPECTATIONS ---
> {{DOCUMENT_EXPECTATIONS}}
> --- END DOCUMENT EXPECTATIONS ---
```

**Edit 4 — Wire the substitution at the dispatch site.**
File: `canonical/skills/aid-discover/references/state-review.md`, Step 1 "Dispatch the Reviewer"
(lines 9-24). Add an explicit instruction in the dispatch package list:

> Before dispatch, read `references/document-expectations.md` and substitute its full contents for
> the `{{DOCUMENT_EXPECTATIONS}}` placeholder in the appended `reviewer-prompt.md` body. This
> guarantees the background sub-agent evaluates against the canonical expectations even though it
> cannot resolve the file path on its own.

This mirrors how the brief already substitutes `{{ARTIFACTS}}`/`{{CONTEXT}}` at dispatch time
(`reviewer-brief.md:6`, `:49-67`), so the mechanism is consistent with the existing dispatch model
(`reviewer-prompt.md` already references sibling files via relative path, e.g.
`../../../templates/grading-rubric.md` at line 60; `document-expectations.md` is a same-dir sibling).

**Edit 5 — Wire the substitution at the FIX-mode re-review dispatch site (REQUIRED, not optional).**
File: `canonical/skills/aid-discover/references/state-fix.md`, Step 6 "Re-Review (MANDATORY)"
(lines 102-112). Verified on disk: Step 6 dispatches `discovery-reviewer` and at line 108 says only
"Read `references/reviewer-prompt.md` for the full prompt" — it does **not** instruct any
substitution. Substitution is **agent-performed per state file**, the same model as `{{ARTIFACTS}}`:
each dispatching state file must independently perform its own substitution. There is **no shared
"render step"** that both REVIEW and FIX inherit — rendering `reviewer-prompt.md` (Edit 3) only
places the `{{DOCUMENT_EXPECTATIONS}}` *placeholder* into the body; the substitution that fills it is
done by the state file at dispatch time. Therefore `state-fix.md` Step 6 must add the **identical**
read+substitute instruction that Edit 4 adds to `state-review.md` Step 1, or the FIX re-review
reviewer receives an unsubstituted `{{DOCUMENT_EXPECTATIONS}}` token. Add to Step 6 (immediately
after the line 108 "Read `references/reviewer-prompt.md`" instruction):

> Before dispatch, read `references/document-expectations.md` and substitute its full contents for
> the `{{DOCUMENT_EXPECTATIONS}}` placeholder in the appended `reviewer-prompt.md` body — identical
> to REVIEW Step 1. This guarantees the FIX-mode re-review sub-agent evaluates against the canonical
> expectations even though it cannot resolve the file path on its own.

**Re-render.** After Edits 1-5, run `python run_generator.py` to regenerate the 4 rendered copies of
`document-expectations.md`, the 3 Markdown + 1 codex-toml copies of the reviewer agent, and the
rendered `reviewer-prompt.md`/`state-review.md` references across `profiles/*` and dogfood `.claude/`.
The `## Document Expectations` block must then exist in exactly one canonical place
(`document-expectations.md`) and its renders — not in any `discovery-reviewer` artifact.

### 3. Flow impact

- **Before:** the reviewer carries its own embedded copy of the per-doc expectations
  (`AGENT.md:196-290`, and the codex toml `developer_instructions`). Authoring agents read the
  separate `document-expectations.md`. The two can drift independently — and already have (§0). The
  reviewer's expectations and the authoring expectations are two artifacts that happen to overlap.
- **After:** there is one source. Authoring agents read `document-expectations.md` directly
  (unchanged path, `SKILL.md:321`). The reviewer receives the *same file's contents* inlined into its
  dispatch prompt at review time. Both sides provably resolve to identical text because it is
  literally the same file.
- **What is unchanged:** WHAT the reviewer checks (every Must-have/Red-flag criterion is preserved
  verbatim in the merge), the grading rubric, spot-check minimums, the ledger output contract
  (`AGENT.md:310-332`), and the Q&A behavior. Only WHERE the expectations are *sourced* changes
  (embedded copy → dispatched-in canonical file). No KB doc content, no completeness-gate logic, no
  state transitions change.

### 4. Test plan

Verification is grep-based single-source checks + the existing generator/canonical gates
(non-regression). No application tests apply.

1. **Single-source invariant (the core check).** After re-render, the per-doc blocks exist in
   exactly one canonical place:
   - `grep -rl '^### architecture.md' canonical/` (a stable canary block key) returns **only**
     `canonical/skills/aid-discover/references/document-expectations.md` — not
     `canonical/agents/discovery-reviewer/AGENT.md`.
   - `grep -rc '^## Document Expectations' canonical/agents/discovery-reviewer/AGENT.md` shows the
     heading remains (it now holds only the pointer) but `grep -c '^### .*\.md' ` on that file
     returns 0 per-doc blocks.
   - Repeat the canary grep across `profiles/*` and `.claude/` to confirm renders dropped the blocks
     from every reviewer artifact (Markdown + codex `.toml`).
2. **Reviewer-has-access invariant (BOTH dispatch sites).** `reviewer-prompt.md` contains the
   `{{DOCUMENT_EXPECTATIONS}}` placeholder, AND **both** dispatching state files contain the
   read+substitute instruction naming `references/document-expectations.md`:
   - `grep -n 'DOCUMENT_EXPECTATIONS' canonical/skills/aid-discover/references/reviewer-prompt.md` — placeholder present.
   - `grep -n 'document-expectations.md' canonical/skills/aid-discover/references/state-review.md` — REVIEW Step 1 substitute wiring present.
   - `grep -n 'document-expectations.md' canonical/skills/aid-discover/references/state-fix.md` — FIX Step 6 substitute wiring present (Edit 5).
   Because substitution is agent-performed per state file (no shared render step), the absence of the
   `state-fix.md` instruction would leave the FIX re-review reviewer with an unsubstituted token —
   this grep is the guard against exactly that gap. This demonstrates the dispatch path delivers the
   canonical file to the background sub-agent at **both** review entry points.
3. **Merge-completeness.** `document-expectations.md` after Edit 1 contains a superset of both prior
   copies: it has `### {reviewer_output_file}` (ported from the reviewer) AND retains
   `### project-structure.md` / `### external-sources.md`. Grep for all three keys.
4. **Generator + canonical gates green (non-regression).**
   - `python run_generator.py` exits 0 and leaves `profiles/` with no uncommitted drift
     (the CI `render-drift` job, `test.yml:24-40`).
   - `python .claude/skills/aid-generate/scripts/verify_deterministic.py --self-test
     --canonical-root .` passes (`test.yml:95`).
   - `bash tests/run-all.sh` — the 13 existing canonical suites stay green (none touch these files,
     so this is pure non-regression).
5. **Proposed new canonical suite (optional, lightweight — recommended).** Add
   `tests/canonical/test-expectations-single-source.sh` (auto-discovered by `run-all.sh` per
   REQUIREMENTS §7) that asserts checks 1 + 2 above against `canonical/` so the duplication cannot
   silently return in a future edit. This is a guard-rail suite, not behavior under test; keep it to
   the two grep invariants. Adding it makes the total "13 existing green + 1 new pass" per the
   non-regression doctrine (count is not pinned).

### 5. Backward compatibility & risks

- **Backward compatible.** The reviewer still applies the same criteria with the same rigor — the
  text is preserved verbatim and merely sourced from one file. Authoring-agent path is unchanged.
  Standard-default discovery runs behave identically. No completeness-gate or state-machine change.
- **Risk — a dispatched sub-agent without the file loses its expectations.** This is the central
  risk and the reason the feature exists: simply deleting the AGENT.md copy and telling the reviewer
  to "reference `document-expectations.md`" would silently strip the reviewer of its criteria,
  because the background sub-agent cannot resolve a file path it was not given.
  **Mitigation:** Edit 3 + Edit 4 inline the file's *contents* into the dispatch prompt (not just a
  path reference), so the criteria are physically present in the reviewer's context. Test-plan
  check 2 verifies the wiring exists; check 1 verifies the duplication is gone.
- **Risk — codex render target.** The reviewer is also rendered to a codex `.toml`
  (`developer_instructions` string). Because that toml is generated from the same canonical AGENT.md,
  Edit 2 propagates automatically; check 1's cross-profile grep confirms the toml dropped the blocks.
  No separate codex hand-edit.
- **Risk — FIX-mode re-review (the central wiring trap).** Substitution is agent-performed per state
  file — there is no shared render step that both dispatch sites inherit. If the substitute step is
  wired only into REVIEW Step 1 (Edit 4, `state-review.md`) and not into FIX Step 6
  (`state-fix.md:102-112`, which dispatches the reviewer at line 108 reusing `reviewer-prompt.md`),
  the FIX re-review reviewer receives an unsubstituted `{{DOCUMENT_EXPECTATIONS}}` token and runs
  without expectations. **Mitigation:** Edit 5 makes the identical read+substitute instruction in
  `state-fix.md` Step 6 a REQUIRED edit (not "verify during implementation"); test-plan check 2 greps
  `state-fix.md` for the wiring so the gap cannot ship.
- **Risk — merge drops a block.** Mitigated by the explicit superset requirement (Edit 1) and
  test-plan check 3.

### 6. Cross-feature dependencies

- **feature-004 (declared-doc-set) depends on this feature.** `feature-004/SPEC.md:89-91` states a
  declared-set entry does NOT re-declare `expectations`; they resolve "from the feature-002
  consolidated source keyed by filename." The `### <filename>.md` heading contract in §1 is exactly
  that addressable surface. Shipping feature-002 first (P0) gives feature-004 a single clean target
  and is why P0 sequences before P1 (REQUIREMENTS §10).
- **No dependency on feature-001** (scout/quality ownership reconcile) or **feature-003** (orphan
  ui-architecture stub) — disjoint files. Feature-002 can ship independently within P0.
- **FR-P0-4 (14-vs-16 doc-count, feature-004)** touches the same `AGENT.md` (the stale "14 primary
  KB docs" at line 94 vs "16 primary KB docs" at line 294). Feature-002 does NOT fix those literals
  (out of scope), but the implementer should avoid reintroducing a hardcoded count in the new pointer
  text — keep the replacement pointer count-agnostic to not conflict with feature-004's later edit.
