# Reviewer Prompt

Full prompt for the discovery-reviewer subagent. Used in REVIEW mode Step 1 and FIX mode Step 3.

**⚠️ CLEAN CONTEXT:** Do NOT include any information about the generation process,
which agents ran, what was easy or hard, or any prior state. The reviewer must
evaluate the KB purely on what's on disk — as if a stranger wrote it.

---

## Prompt

> Review every document in .aid/knowledge/ for quality. Be AGGRESSIVE — a lenient review is worse
> than useless because it lets bad docs through the quality gate.
>
> For each document, assess:
>
> 1. **Accuracy** (MOST IMPORTANT) — Do NOT trust what the document says. Verify claims
>    against actual source files:
>    - Version numbers → check build configs, lockfiles, dependency manifests, library filenames
>    - File paths → verify they exist on disk
>    - Class/interface/abstract claims → read the actual declaration
>    - Configuration values → check actual config files
>    - Absolute statements ("always", "all modules", "never") → verify scope is correct
>    - Every claim should be traceable to a primary source. If it's not, flag it.
>    - Any factual error is [CRITICAL]. Any value marked "TBD" or "unknown" when
>      extractable from the repository is [HIGH].
>
> 2. **Completeness** — Does the document cover everything its title promises?
>    - Compare against what a developer working on this project would need.
>    - Are edge cases and failure modes documented where relevant?
>    - If a problem is identified (e.g., tech debt), is a next step or mitigation noted?
>    - Are all terms and abbreviations defined or referenced in the glossary?
>
> 3. **Cross-document consistency** — Does information contradict other documents?
>    - If a wrong claim propagates across multiple docs, flag each propagation separately.
>    - Do summaries in INDEX.md match what the primary documents actually say?
>    - Is the same concept called the same name everywhere? (not "bundle" in one doc
>      and "module" in another for the same thing)
>
> 4. **Depth vs. signal** — Quality of information, not quantity.
>    - Does it explain patterns, relationships, and WHY — or just list names?
>    - Is information duplicated from other documents without adding new value?
>    - Is the signal-to-noise ratio high? Could sections be removed without losing
>      anything an agent would need?
>
> 5. **Usefulness** — Imagine you're an agent asked to add a feature, fix a bug, or
>    understand a module in this project.
>    - Would this document let you act correctly without re-discovering?
>    - Can you find the specific information you need quickly from the structure?
>    - Are the claims grounded in specific locations (file paths, class names) or
>      generic statements that could apply to any project?
>
> 6. **Meta-document integrity** — INDEX.md, README.md, and CLAUDE.md are
>    derived from the 16 primary documents.
>    - Do their summaries and values accurately reflect the current primary doc content?
>    - Is placeholder text or template markers still present?
>    - Are questions marked Pending in the Q&A section of DISCOVERY-STATE.md actually still unanswerable from the repository?
>
> **Grading:** Use the universal rubric (read `../../../templates/grading-rubric.md`).
> Classify every issue as [MINOR], [LOW], [MEDIUM], [HIGH], or [CRITICAL].
> Grade is CALCULATED from worst issue severity + quantity. Worst issue dominates.
> A+ = zero issues. F = missing/empty/non-functional.
>
> **Minimum 15 spot-checks** (verify claims against actual code). At least 5 must be version verifications.
>
> **After grading, add new questions to the `## Q&A` section of DISCOVERY-STATE.md** for any
> information gaps found during review that cannot be resolved from the repository. These become
> Q&A items for the user. Use the next sequential Q{N} ID (continuing from existing entries),
> categorize by area, and assign impact levels (High/Medium/Low). Only add questions for things
> genuinely needing human input — if you can grep the answer, fix it in the review instead.
>
> Write the review results (grades, issues, spot-checks) to .aid/knowledge/DISCOVERY-STATE.md,
> preserving the existing `## Q&A` section and adding to it. Update `**Grade:**` from `Pending`
> to the actual grade.
