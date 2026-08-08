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

Same as INITIALIZE Step 1: SPEC.md, REQUIREMENTS.md, KB docs, codebase.

### Review All Sections

For each section in SPEC.md, run step 4 of the loop against current state:

1. **KB drift** — SPEC references KB content that changed?
2. **Requirements drift** — Requirements changed since spec was written?
3. **Codebase drift** — Code changed (renamed, refactored by another feature)?
4. **Missing sections** — New conditional sections should now be activated?
5. **Stale content** — Section contradicts what now exists?

### Modality gate (before dispatching a review)

```bash
bash .codex/aid/scripts/kb/lint-modality.sh --file .aid/works/{work}/features/{feature}/SPEC.md
```

Exit `1` means an acceptance criterion in this SPEC carries no modality. **Fix it before dispatching**,
because the reviewer cannot grade a finding against an untagged criterion — it would have to raise a
criteria gap, which halts the review it just started. Paying a script here is cheaper than paying a
dispatch and a user round trip there.

Exit `2` means the gate inspected **no criterion rows at all**, and is the answer that matters most
here. Until 2026-08-07 the feature template wrote acceptance criteria as a `- [ ]` checklist, which
`lint-modality.sh` cannot see — it matches `| AC-N | MODALITY | ... |` table rows. So a SPEC written to
the shipped template could not produce exit `1` by any route, and this block certified a property it
had no way to observe while its instruction to fix could never fire. A `2` now means the SPEC still
carries the old checklist shape: convert the criteria to the table in `templates/feature.md` before
dispatching, rather than reading the silence as a pass.

### Review

CHAIN to `/aid-deep-review` with this manifest. It owns the dispatch, the ledger, the gap gate, the
grade and the fix loop — this skill no longer carries any of that.

```yaml
scope:         specify-<feature>
artifacts:     <the feature SPEC.md, plus the section list under review>
rule_set:      definition
resume_mode:   new-cycle
depth:         deep
tier:          large            # the executor is the Large aid-architect
context:       |
  SPEC.md for feature-NNN in work-NNN. All sections marked Complete.
```

Fill `ledger` with the scratch path and `minimum_grade` from
`read-setting.sh --skill specify` — both per `reviewer-brief-template.md`.

The two per-skill brief sections come from `references/reviewer-brief.md`.

### On return

`/aid-deep-review` returns the grade and the cycle count.

| Condition | Action |
|-----------|--------|
| Meets minimum | Set feature status to `Ready` in the work STATE.md. Print the summary. |
| Below minimum, fixable sections | Re-enter the loop (Propose → Discuss → Write) for the affected sections. |
| Below minimum, core assumptions wrong | Recommend `--reset`. |

**Advance:** **CHAIN** → [State: DONE] when the spec is Ready and meets the minimum.
