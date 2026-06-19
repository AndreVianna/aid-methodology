# Interview Loop

This loop runs during State 1 (First Run) and State 3 (Continue Interview).

### Assess current state

Read STATE.md `## Interview State` Section State table. For each section:
- **Complete** — has substantive content, confirmed by user
- **Partial** — has some content but gaps remain
- **Pending** — empty
- **N/A** — not applicable to this project

### Decide what to ask next

Read `references/interview-strategies.md` for question priority logic, KB inference,
quality gates, and UI-aware probing.

In summary: (1) Infer from KB first — suggest answers with source references, don't fill
silently. (2) Pick the most critical gap. (3) Deepen Partial sections. (4) When all
sections addressed → State 4.

### Rules

- **ONE question per turn.** Never batch.
- Use the user's language, not jargon they haven't used.
- If the user gave direction ("focus on security"), pivot to that area.
- If an answer contradicts the KB, flag it:
  "The codebase shows X, but you're saying Y — which should we go with?"
- Short context before the question (1-2 sentences max). Don't recite everything back.
- If a section is genuinely N/A for this project, mark it `N/A` in STATE.md `## Interview State`
  and move on.

### Update after each answer

1. Update the relevant section(s) in REQUIREMENTS.md
2. Update Section State in STATE.md `## Interview State`
3. If the change is significant, add a Change Log entry in REQUIREMENTS.md
4. If applicable, update `.aid/knowledge/INDEX.md` and
   `.aid/knowledge/README.md`
