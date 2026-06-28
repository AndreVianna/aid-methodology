# Interview Strategies Reference

Detailed guidance for deciding what to ask next, how to infer from the Knowledge Base,
and how to design effective questions.

---

## Decide What to Ask Next -- Priority Order

Next-move selection is delegated to `references/elicitation-engine.md`. The engine's
five-step selector (STOP CHECK -> GAP SELECTION -> MOVE SELECTION -> CALIBRATION
SHAPING -> ENVELOPE + EMIT) is the authoritative driver. Consult that document for
the gap-precedence ranking (Step 2) and all firing rules.

**Supplementary guidance for the full-path interview (brownfield context):**

**KB inference.** When a Pending or Partial section can be answered from KB documents,
do NOT fill it silently. When `feature-inventory.md` has content, use it to understand
what already exists and probe for interactions and dependencies with the new work.
Surface KB inferences at gap rank 3 or 4 with a suggested answer and source reference:

```
[From: .aid/knowledge/{source-document}.md]

{Your question about this section}

Suggested: {inferred content from codebase analysis}
Why: {rationale for the inference -- grounded in the KB doc cited above}

[1] Accept this
[2] Not applicable
[3] Your answer: ___
```

Only update REQUIREMENTS.md after the user responds.

**Quality gates inference.** When working on Section 6 (Non-Functional Requirements),
surface these project-level baselines as gaps if not already covered:
- **Unit test minimum** -- coverage target for new code? (e.g., "all public methods",
  "80% line coverage", "critical paths only")
- **Linting standard** -- which linter and ruleset? (e.g., "ESLint + Airbnb",
  "Checkstyle with Sun conventions", "default analyzer warnings-as-errors")
- **Build policy** -- zero warnings required? Specific compiler flags?

These become the project baseline. `/aid-specify` may add feature-specific requirements
on top; `/aid-detail` concretizes them per task.

**UI-aware inference.** If `.aid/knowledge/architecture.md` documents UI/frontend
patterns or the project has frontend code, surface these as gaps when working on
Section 6 if not already covered:
- Target devices and browsers (desktop, tablet, mobile -- which combinations?)
- Accessibility requirements (WCAG level, keyboard navigation, screen reader support)
- Internationalization/localization needs (languages, RTL, date/number formats)
- Responsive behavior expectations (mobile-first, specific breakpoints)
- Design specs or Figma references (existing design system, brand guidelines)
- Offline behavior expectations (PWA, service workers, graceful degradation)

---

## Brownfield vs Greenfield

The skill handles both automatically:

- **Brownfield (KB exists):** Many sections can be pre-filled from KB. Questions come
  with suggestions and source references. Cross-reference is thorough.
- **Greenfield (no KB):** Everything comes from the user. Interview is longer.
  Cross-reference has limited material — may be grade A by default.

---

## Question Design Principles

Question design is governed by `references/move-playbook.md` (the ten moves and their
gap-type firing table) and `references/advisor-stance.md` (the NFR-7 question-envelope
template, the pre-emit self-check, and the five user-move handlers: "I don't know",
"what do you recommend?", "explain the pros and cons", "explain it like I'm a junior",
and mistaken assertion). Every question the engine emits is wrapped in the NFR-7
envelope -- no bare, suggestion-less questions.

Conversational principles that supplement the move and stance docs:

1. **Start wide, narrow down.** Objective -> Scope -> Details -> Constraints.
2. **Follow the energy.** If the user is excited about a particular area, explore it
   first -- the gap-precedence ranking still applies, but the move order is not rigid.
3. **Do not interrogate.** Acknowledge what the user said before asking the next
   question. Short context before the question (1-2 sentences max).
4. **Respect "not applicable."** When a section is genuinely N/A for this project,
   mark it N/A in STATE.md and move on. Do not probe for content that cannot exist.
5. **Capture the WHY.** "Real-time updates" is a feature; "Traders lose money on stale
   data" is a requirement. Use move-playbook.md Move 7 (Bounded why-probe) to surface
   the terminal value.
6. **Use concrete examples.** "Walk me through what a user would do when..." surfaces
   better requirements than "What are the functional requirements?" See move-playbook.md
   Move 8 (Concrete-example probe) for the full specification.
