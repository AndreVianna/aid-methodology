# State: FIX

FIX applies Q&A answers and reviewer feedback to bring KB documents up to minimum grade; it is selected when the grade is below minimum and no Pending Q&A entries remain.

### Step 1: Identify Documents Below Threshold

Read `.aid/knowledge/STATE.md` `## KB Documents Status`. List documents below minimum grade.
Prioritize: [CRITICAL] → [HIGH] → [MEDIUM].
Print: `[Fix] {N} documents below {minimum}. Fixing...`

### Step 2: Fix Each Document

For each document below minimum, in priority order:
1. Read issues from `.aid/knowledge/STATE.md` `## Issues`
2. Read Answered Q&A entries from `.aid/knowledge/STATE.md` `## Q&A` applicable to this document
3. Read relevant source code for missing info
4. Edit KB document — combine review findings WITH user answers
5. **REMOVE fixed issue lines** from `.aid/knowledge/STATE.md` `## Issues`
6. Update `**Applied to:**` for each incorporated Q&A answer in STATE.md `## Q&A`
7. Re-grade the document

Print: `[Fix] Improving {document}... {old grade} → {new grade}`

**Feature Inventory Generation:** When processing Features Q&A answers:
1. Cross-reference with api-contracts.md, module-map.md, domain-glossary.md, ui-architecture.md, data-model.md
2. Generate/update feature-inventory.md with enriched table
3. Mark Features Q&A as Applied to: `feature-inventory.md`

### Step 2b: Verify Meta-Documents (MANDATORY after every fix pass)

After ALL primary fixes, verify and update in order:
1. **`.aid/knowledge/STATE.md` Q&A** — resolved questions? new unknowns?
2. **INDEX.md** — summaries still match?
3. **README.md** — completeness table still accurate?
4. **CLAUDE.md** — build commands, conventions, architecture stale?

Print: `[Fix] Verifying 4 meta-documents...`

### Step 3: Re-Review (MANDATORY — Do NOT Self-Evaluate)

**Dispatch discovery-reviewer again.** The fixer CANNOT evaluate its own work.

Print: `[Fix 2/3] Re-reviewing after fixes...`

Read `references/reviewer-prompt.md` for the full prompt. Same contamination prevention rules as REVIEW mode.

▶ discovery-reviewer starting (~2–3 min)
Wait for completion.
✓ discovery-reviewer done (record actual time) — or ✗ discovery-reviewer failed: {reason}

### Step 4: Post-Fix Update

Read new `.aid/knowledge/STATE.md`. Verify Review History preserved (append, not replace under `## Review History`).

Print: `[Fix 3/3] Complete. Grade: {old} → {new}. Run /aid-discover again to {fix remaining issues|proceed}.`

Print: `[State: FIX] complete.`

**Advance:** Next: [State: APPROVAL] — run /aid-discover again
