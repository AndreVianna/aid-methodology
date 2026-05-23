# Interview Strategies Reference

Detailed guidance for deciding what to ask next, how to infer from the Knowledge Base,
and how to design effective questions.

---

## Decide What to Ask Next — Priority Order

1. **Infer from KB** — If a Pending/Partial section can be answered from KB documents,
   **do NOT fill it silently.** When `feature-inventory.md` has content, use it to
   understand what already exists and probe for interactions/dependencies with the new work.
   Ask with a suggested answer and source reference:
   ```
   [From: .aid/knowledge/{source-document}.md]

   {Your question about this section}

   Based on the codebase analysis: {inferred content}

   [1] Accept this
   [2] Not applicable
   [3] Your answer: ___
   ```
   Only update REQUIREMENTS.md after the user responds.

   **Quality gates inference:** When working on §6 Non-Functional Requirements, proactively
   ask about these project-level baselines (if not already covered):
   - **Unit test minimum** — coverage target for new code? (e.g., "all public methods",
     "80% line coverage", "critical paths only")
   - **Linting standard** — which linter and ruleset? (e.g., "ESLint + Airbnb", "Checkstyle
     with Sun conventions", "default analyzer warnings-as-errors")
   - **Build policy** — zero warnings required? Specific compiler flags?

   These become the project baseline. `/aid-specify` may add feature-specific requirements
   on top, and `/aid-detail` concretizes them per task.

   **UI-aware inference:** If `.aid/knowledge/ui-architecture.md` exists and has real content
   (not "backend-only"), proactively ask about these topics when working on §6 Non-Functional
   Requirements (if not already covered):
   - Target devices and browsers (desktop, tablet, mobile — which combinations?)
   - Accessibility requirements (WCAG level? Keyboard navigation? Screen reader support?)
   - Internationalization/localization needs (languages? RTL? Date/number formats?)
   - Responsive behavior expectations (mobile-first? Specific breakpoints?)
   - Design specs or Figma references (existing design system? Brand guidelines?)
   - Offline behavior expectations (PWA? Service workers? Graceful degradation?)

2. **Most critical gap** — Among remaining Pending/Partial sections, pick the one that:
   - Depends on the least other information (can be answered now)
   - Unblocks the most other sections
   - Is most relevant given what the user has already said

3. **Deepen Partial sections** — If no sections are fully Pending but some are Partial,
   ask a follow-up to complete them.

4. **All sections addressed** → State 4 (Completion & Approval).

---

## Brownfield vs Greenfield

The skill handles both automatically:

- **Brownfield (KB exists):** Many sections can be pre-filled from KB. Questions come
  with suggestions and source references. Cross-reference is thorough.
- **Greenfield (no KB):** Everything comes from the user. Interview is longer.
  Cross-reference has limited material — may be grade A by default.

---

## Question Design Principles

1. **Start wide, narrow down.** Objective → Scope → Details → Constraints.
2. **Follow the energy.** User excited about feature X? Explore it first.
3. **Don't interrogate.** Acknowledge what they said before asking the next thing.
4. **Respect "I don't know."** Mark as assumption, move on.
5. **Respect "not applicable."** Mark N/A, move on.
6. **Capture the WHY.** "Real-time updates" is a feature. "Traders lose money on
   stale data" is a requirement. Push for the why.
7. **Use concrete examples.** "Walk me through what a user would do when..." produces
   better requirements than "What are the functional requirements?"
