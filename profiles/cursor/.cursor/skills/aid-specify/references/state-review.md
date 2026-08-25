# State: REVIEW

All sections complete; re-review entire spec against current KB and codebase.

The spec was completed previously (feature status `Ready` in work STATE.md `## Features State`).

**Ask first:** _"This feature spec is marked Ready. Do you want to reopen it for review?
Is there something specific you want to re-examine?"_

If user confirms → set feature status to `In Discussion`, continue below.
If user has a specific concern → record it as context for the review.

Re-run enters **the same loop at step 4** —
reviewing all sections against current reality.

### Load Current Context

Same as INITIALIZE Step 1: SPEC.md, the REQUIREMENTS.md **slice** this feature traces to
(from its `## Source`, never the whole document), KB docs, codebase.

### Review All Sections

For each section in SPEC.md, run step 4 of the loop against current state:

1. **KB drift** — SPEC references KB content that changed?
2. **Requirements drift** — Requirements changed since spec was written?
3. **Codebase drift** — Code changed (renamed, refactored by another feature)?
4. **Missing sections** — New conditional sections should now be activated?
5. **Stale content** — Section contradicts what now exists?

### Dispatch the Reviewer

Render `references/reviewer-brief.md` with:
- `{{ARTIFACTS}}` = `SPEC.md` path + the section list under review (or "full SPEC")
- `{{CONTEXT}}` = `SPEC.md for feature-NNN-{name} in work-NNN-{name}. All sections marked Complete in the work STATE.md \`## Features State\` row. This is the final review pass before the feature is marked Ready.`

Include in the prompt:
- **Ledger lifecycle:** "Read `.aid/.temp/review-pending/specify-<feature>.md` if it
  exists. For each existing row: verify on disk, update Status (Pending→Fixed if
  resolved; Fixed→Recurred if regressed). Append new findings with Status: Pending."
- **Schema reference:** "Output per `.cursor/aid/templates/reviewer-ledger-schema.md`.
  The ledger is the entire file — ONE markdown table, no headers, no narrative."

Dispatch the `aid-reviewer` subagent **at Large tier** (the executor is the Large
`aid-architect`; reviewer tier >= executor tier per
`.cursor/aid/templates/agent-dispatch-tiering.md`) with the rendered brief.

### Grade Overall

After the aid-reviewer returns, run grade.sh on the ledger:

```bash
bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/specify-<feature>.md
```

Compare to minimum grade from `bash .cursor/aid/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Print summary, done. Set feature status to `Ready` in work STATE.md. |
| Grade < minimum, fixable sections | List findings, re-enter loop for affected sections. |
| Grade < minimum, core assumptions wrong | Recommend `--reset`. |

### Review the delivery BLUEPRINT.md this feature refines

**Full path only.** `aid-plan` writes each `deliveries/delivery-NNN/BLUEPRINT.md` as a stub; this
state is where that stub is refined, so it is where the refinement is reviewed. On the Lite path
the blueprint is authored by the shortcut engine's PLAN step and reviewed there — that review is
untouched by this one.

Run this only for a blueprint this feature's SPEC actually changed. A blueprint no feature touched
is still the stub `aid-plan` gated, and re-reviewing it buys nothing.

Render `references/reviewer-brief.md` with:
- `{{ARTIFACTS}}` = the `deliveries/delivery-NNN/BLUEPRINT.md` path(s) refined in this pass
- `{{CONTEXT}}` = `Delivery BLUEPRINT.md refined while specifying feature-NNN-{name}. The blueprint is the immutable delivery definition; check that its objective, scope and gate criteria still match the SPEC just approved, and that nothing in it contradicts a sibling delivery's blueprint.`

Same ledger discipline as above, on its own scope:

- **Ledger lifecycle:** "Read `.aid/.temp/review-pending/blueprint-delivery-NNN.md` if it exists.
  For each existing row: verify on disk, update Status (Pending→Fixed if resolved; Fixed→Recurred
  if regressed). Append new findings with Status: Pending."
- **Schema reference:** "Output per `.cursor/aid/templates/reviewer-ledger-schema.md`. The
  ledger is the entire file — ONE markdown table, no headers, no narrative."

```bash
bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/blueprint-delivery-NNN.md
```

Graded against the same `--skill specify` minimum. A blueprint below it blocks the feature from
`Ready`, because a SPEC approved against a blueprint that no longer describes its delivery is
approved against nothing.

```
Reviewing {work}/{feature} against current KB and codebase...

Issues found: 1 [LOW] (stale DB column ref), 3 [MINOR] (naming) → **Grade: B+**
Minimum: B+. ✅ Meets minimum.
```

For grades below minimum: re-enter the loop (Propose → Discuss → Write → Review)
for affected sections. When all resolved, set status back to Ready.

**Advance:** **CHAIN** → [State: DONE] when spec is Ready and meets minimum grade (continue inline).
