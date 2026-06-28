> **Human-facing documentation.** Machine source consumed by `/generate-profile` is [`SKILL.md`](SKILL.md) in this folder.

# Feature Definition from Approved Requirements

Decompose approved requirements into discrete feature folders and cross-reference them against the Knowledge Base and codebase. Produces per-feature SPEC.md stubs ready for `/aid-specify`.

## Core Principle

**Approved requirements in, defined features out.** This skill begins only from an approved `REQUIREMENTS.md` (produced by `/aid-describe`). It shapes the loose intent gathered during the interview into a concrete, graded, cross-referenced feature set.

## Precondition

`## Interview State: Approved` must be present in `.aid/{work}/STATE.md`. Run `/aid-describe {work}` first if requirements are not yet approved.

## Workspace

```
.aid/
  knowledge/                    <- shared KB (from Discovery)
  work-NNN-{name}/
    REQUIREMENTS.md             <- approved (produced by /aid-describe)
    features/
      feature-NNN-{name}/
        SPEC.md                 <- requirements side (from Interview) + tech spec (from /aid-specify)
```

## When to Use

- **After approval:** REQUIREMENTS.md is approved; no feature folders exist yet. Runs FEATURE-DECOMPOSITION.
- **After decomposition:** Feature folders exist; cross-reference not done. Runs CROSS-REFERENCE.
- **Re-run decomposition:** pass `--features {work}` to redo feature decomposition.
- **After DONE:** Ready for `/aid-specify`.

## The States

### State 5: Feature Decomposition

After REQUIREMENTS.md is approved, the agent proposes a feature breakdown from §5 Functional Requirements:

1. Analyze functional requirements for natural feature boundaries.
2. Propose a feature list with names, descriptions, and priorities (Must/Should/Could).
3. User approves, adjusts, or adds features.
4. For each approved feature, create a folder (`feature-NNN-{name}/`) with SPEC.md containing:
   - Description (stakeholder perspective)
   - User stories
   - Priority
   - Acceptance criteria
   - Source references to REQUIREMENTS.md sections
   - Empty `## Technical Specification` section (Specify fills this)

### State 6: Cross-Reference

Validates REQUIREMENTS.md against the full KB and codebase:

| Grade | Questions | Meaning |
|-------|-----------|---------|
| A | 0 | Fully consistent, no questions |
| B | 1–3 | Small gaps or minor inconsistencies |
| C | 4–7 | Significant gaps need attention |
| D | 8+ | Serious problems, major rework |

The grade is a snapshot at run start — does NOT change after answering questions. Run again for updated grade.

Questions are presented one at a time. Answers update REQUIREMENTS.md immediately with Change Log entries.

### State 7: DONE

Cross-reference complete. The work is ready for `/aid-specify`.

## Output

- `.aid/{work}/features/feature-NNN-{name}/SPEC.md` — per-feature requirements side (description, user stories, priority, acceptance criteria).
- `.aid/{work}/STATE.md ## Interview State` — cross-reference grade and Q&A entries.

## Feedback Loops

### → Interview (requirements-level changes)

If DONE reveals requirements are wrong or incomplete, run `/aid-describe {work}` to reopen the requirements interview.

### ← Specify / Plan / Detail

Downstream phases find requirements are wrong, incomplete, or contradictory. They write Q&A entries to work `STATE.md`. The next `/aid-describe {work}` run picks them up.

## Related Phases

- **Previous:** [Describe](../aid-describe/) — gathers and approves requirements
- **Next:** [Specify](../aid-specify/) — adds technical specification per feature

## See Also

- [AID Methodology](../../docs/aid-methodology.md) — The complete methodology.
