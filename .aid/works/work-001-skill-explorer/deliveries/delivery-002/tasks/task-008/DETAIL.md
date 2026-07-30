# task-008: One-way shortcut-catalog reader


> **§7 AMENDED — read before the §7 references below (2026-07-30, delivery-006).**
> This document was authored while REQUIREMENTS §7 froze `gen-reference.mjs`. The **second
> amendment to §7** (work-level Q4, at `REQUIREMENTS.md` § Constraints) lifted that freeze so
> delivery-006 could **hollow out** `reference/skills.md` — shedding the duplicated roster and
> keeping only the shortcut-engine narrative. Every "§7 freezes/forbids", "frozen generator" and
> "terse family summary" statement below was TRUE WHEN WRITTEN and is kept as the design record;
> none describes the repository today. The grouping divergence they reason about did not vanish
> either — it moved from a competing PAGE to the curated roster, and is now derived (KI-010).

[!NOTE]
This is the TASK-LEVEL DETAIL.md for task-008. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-008/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-skill-explorer -> delivery-002 (feature-002-grouped-skill-index)

**Depends on:** task-004

**Scope:**
- Create `site/scripts/skills/catalog.mjs`: `loadShortcutCatalog(repoRoot) -> { rows, byName }` over `canonical/aid/templates/shortcut-catalog.yml`, where `CatalogRow` is `{ name, verb, artifact, alias_of, group, intent, repurpose? }`. This is the **only** catalog reader in the `skills/` cluster, imported one-way by the generator and by feature-002's AC-8 suite.
- Mirror `gen-reference.mjs`'s two regexes -- the row opener `/^  - name:\s*(.+)$/` (`:102`) and the field line `/^    ([a-zA-Z_]+):\s*(.*)$/` (`:111`) -- plus `stripYamlScalar` (`:120-125`). **Re-implemented, never imported:** `gen-reference.mjs` calls `main()` unconditionally at module scope (`:707`), so importing a constant from it would regenerate all four reference pages and rewrite `.reference-manifest.json` as a side effect. Extracting a genuinely shared module is what REQUIREMENTS section 7 forbids, since it would edit the frozen generator.
- **No `repurpose` filtering.** `gen-reference.mjs` restricts its family table to non-`repurpose` rows because those are the rows its build helper generates; this index cards every skill directory and every catalog row has one, so all rows participate.
- Same conventions as the rest of the cluster: ESM `.mjs`, `node:` builtins only, 2-space indentation, pure exported function with no import-time side effect, no new dependency.

**Acceptance Criteria:**
- [ ] `rows` is returned in **file order** -- load-bearing, because feature-002 derives verb-family ordering from catalog first appearance.
- [ ] A row with no `name`, a row with no `verb`, and a duplicate `name` each throw `[gen-skills] catalog parse: <detail>` with the offending row identified. (`gen-reference.mjs`'s reader silently overwrites a duplicate at `:113`; a `Map` build plus this check cannot.)
- [ ] `byName` covers every row in `rows`, and no row is silently overwritten.
- [ ] No row is filtered out on `repurpose`; the returned `rows` length equals the number of `- name:` rows in the file.
- [ ] Nothing is imported from `site/scripts/gen-reference.mjs`, verified by grep over the new module.
- [ ] Unit tests over inline fixture strings cover file-order preservation and each of the three throws; all existing tests still pass; the build passes.
- [ ] All section-6 quality gates pass
