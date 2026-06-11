# State: CONTINUE

Work STATE.md `## Features Status` shows this feature `In Discussion`; find first `Pending` or `In Discussion` section in SPEC.md and resume **The Loop** for that section.

Emit pipeline phase (silent state-write only — no output, no gate):
```
bash .github/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value Running
bash .github/scripts/execute/writeback-state.sh --pipeline --field Phase --value Specify
bash .github/scripts/execute/writeback-state.sh --pipeline --field "Active Skill" --value aid-specify
bash .github/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

---

## The Loop — Per Section

### 1. Propose

Read relevant KB and codebase for this section. Then:

```
### {Section Name}

Based on {KB evidence}, here's what I propose:

{Concrete technical proposal — specific files, classes, patterns from the codebase.
Reference conventions from coding-standards.md. Fit architecture.md. Use domain terms.
If changing something that exists, call it out.}

What do you think?
```

Update section status to `In Discussion` in work STATE.md `## Features Status`.

**Proposal quality rules:**
- Reference specific files, classes, patterns from the codebase
- Follow conventions from `coding-standards.md`
- Fit the architecture from `architecture.md`
- Use domain terms from `domain-glossary.md`
- Call out explicitly if changing something that exists
- **Known issues:** If codebase exploration reveals new issues in code this feature
  touches, register them in `.aid/{work}/known-issues.md` before proposing.
  Check existing entries first to avoid duplicates. Check `tech-debt.md` — if already
  catalogued there, reference it: `See tech-debt.md #TD-NNN`.

### 2. Discuss

Free-form conversation. The user may:
- **Agree** → move to Write
- **Adjust** → revise proposal, present again
- **Redirect** → different approach. Adapt.
- **Ask questions** → answer from KB/codebase. If you don't know, say so.
- **Raise concerns** → discuss trade-offs with options and pros/cons

Continue until the user is satisfied.

### 3. Write

When agreed:

1. Write section to SPEC.md under `## Technical Specification`
2. Update work STATE.md `## Features Status` section status → `Written`
3. Add Change Log entry to SPEC.md
4. **KB Seeding (greenfield):** If the decision fills a gap in an empty KB doc,
   update that KB doc + INDEX.md + README.md. Log which KB docs were seeded.

### 4. Review

**Agent:** Dispatch with `subagent_type: aid-reviewer` (overriding the default `aid-architect`). The aid-reviewer must run with clean context — it grades against KB/codebase reality without seeing the aid-architect's working notes. Print before dispatch: `[Review] Dispatching aid-reviewer for SPEC validation.`

▶ aid-reviewer starting (~1–2 min)

Immediately after writing, verify what was written:

- Does it contradict other completed sections in this SPEC?
- Does it align with KB reality (architecture, coding standards, existing patterns)?
- Does it reference real codebase artifacts (not hallucinated paths/classes)?
- Is it concrete enough for implementation (no vague "appropriate pattern" language)?
✓ aid-reviewer done (record actual time) — or ✗ aid-reviewer failed: {reason}

**Grade the section** using the universal rubric (`../../../templates/grading-rubric.md`).
Classify each issue by severity (Minor/Low/Medium/High/Critical). The grade is
calculated — worst issue dominates. Compare to minimum grade from `bash .github/scripts/config/read-setting.sh --skill specify --key minimum_grade --default A`.

| Condition | Action |
|-----------|--------|
| Grade ≥ minimum | Mark `Complete` in work STATE.md `## Features Status`. Next section. |
| Grade < minimum, fixable | Back to Propose with findings. |
| Grade < minimum, systemic | Loopback (KB/Requirements issue). |

```
✅ Data Model section — 2 minor issues (cosmetic naming) → Grade: A.
   Meets minimum B+. Moving to Feature Flow.
```

or:

```
⚠️ Data Model section has an issue: the index strategy contradicts what's
in coding-standards.md §3.2 (composite indices discouraged). Let me re-propose...
```

### Continue or Finish

- More Pending sections → Propose next one (step 1)
- All sections Complete:
  - Set feature status to `Ready` in work STATE.md `## Features Status`
  - Print summary with all completed sections
  - `/aid-specify` on this feature now enters **REVIEW** (step 4 on all sections)

**Advance:** **CHAIN** → [State: REVIEW] when all sections are Complete (continue inline).
