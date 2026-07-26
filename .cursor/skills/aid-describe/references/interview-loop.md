# Interview Loop

This loop runs during State 1 (First Run) and State 3 (Continue Interview).

### Assess current state

Read STATE.md `## Interview State` Section State table. For each section:
- **Complete** — has substantive content, confirmed by user
- **Partial** — has some content but gaps remain
- **Pending** — empty
- **N/A** — not applicable to this project

### Decide what to ask next

Delegate to `references/elicitation-engine.md`. The engine runs its five-step
next-move selector every turn after the D1 opener:

1. **STOP CHECK** -- Is the work minimal-but-sufficient? If yes, exit to COMPLETION.
2. **GAP SELECTION** -- Pick the highest-priority open gap (gap-precedence table in
   elicitation-engine.md Step 2). Gap inventory for the full-path interview: the
   REQUIREMENTS.md section status table read in "Assess current state" above.
3. **MOVE SELECTION** -- Map the gap type to a playbook move
   (`references/move-playbook.md` gap-type firing table).
4. **CALIBRATION SHAPING** -- Shape the chosen move's depth by calibration state
   (`references/calibration.md` depth-shaping table).
5. **ENVELOPE + EMIT** -- Wrap in the NFR-7 question envelope and run the pre-emit
   self-check (`references/advisor-stance.md`); emit one question; wait for the
   answer; record to the record sink; re-read calibration; return to Step 1.

For the full-path interview the stop predicate is: every REQUIREMENTS.md section is
Complete or N/A and no unresolved coherence conflict is open.

`references/interview-strategies.md` carries supplementary brownfield guidance on KB
inference, quality gates, and UI-aware probing. Consult it when the gap inventory or
context warrants.

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
