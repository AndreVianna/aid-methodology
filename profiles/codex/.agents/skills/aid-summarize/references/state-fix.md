# State: FIX

FIX handles objective machine-pool failures autonomously and subjective human-pool failures via the expose-propose-ask loop; it is selected when VALIDATE or MANUAL-CHECKLIST determines the grade is below minimum.

FIX handles two fundamentally different kinds of failure. **Route each failure by kind** — do not treat them the same.

### Machine-pool failures — fix directly (objective; one correct fix)

Read `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation — Machine)`. For each failed AUTO_POOL check there is exactly one correct repair — apply it autonomously:

- **D1 (diagram parse)** — locate the failing `<pre.mermaid>` block, identify the syntax error from the validator output, apply the fix per `.agents/templates/knowledge-summary/mermaid-examples.md` "Common failure patterns" table.
- **D2 (diagram render)** — the block parses but renders trivially / as an error SVG; inspect the jsdom render output, fix the structural issue (often an empty subgraph or an unreachable node).
- **L1 (anchor links)** — fix the `href` or add the missing `id`.
- **L2 (md links)** — correct the relative path.
- **H1 (HTML validity)** — fix the reported markup error (from tidy / html-validate / regex, whichever ran).
- **A1, A2, A3, A4, A5 (accessibility)** — add the missing landmark / ARIA attribute / focus-trap marker / reduced-motion block / focus-visible rule.
- **C1 / C2 (contrast)** — adjust the offending color in the inlined CSS to meet the ratio.

Edit ONLY the failing parts; leave everything else untouched. After all machine-pool fixes are applied, return to VALIDATE.

### Human-pool / subjective failures — expose → propose → ask (NEVER fix silently)

When a MANUAL_POOL item failed (K1 partial/no, K2 partial/no) or the user left a free-text complaint in `## Manual Notes`, there is **no single objective fix** — the user flagged it because their judgment is the input. Do NOT guess-and-apply. Instead, for each such issue, run the **expose → propose → ask** loop:

1. **Expose** — restate the issue precisely. Quote the user's note or the failing checklist item. Name the specific HTML section(s) or claim(s) involved. Example: *"K1 scored partial — your note says the Data Model section only lists artifact names without the per-artifact schemas that `data-model.md` actually contains."*
2. **Propose** — offer a concrete, specific fix. Example: *"Proposed: expand §5 Data Model to include the field-level schema table for each of the 15 artifacts, pulled from `data-model.md §2.1-§2.15`. Adds ~40 lines."*
3. **Ask** — use `AskUserQuestion` to ask the user to (a) approve the proposed fix, (b) provide their own fix / direction, or (c) mark the issue as won't-fix (accept the lower score). Wait for the answer before editing.

Apply only what the user confirms. Capture the resolution in `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Manual Notes`. After all human-pool issues are resolved (or accepted as won't-fix), return to VALIDATE → MANUAL-CHECKLIST so the user can re-score.

**Rationale:** machine-detected issues have one objective fix; human-detected / subjective issues do not — applying the agent's guess silently risks solving the wrong problem or overwriting the user's intent. The user is the judgment input; collaboration produces the right outcome.

Print: `[State: FIX] complete.`

**Advance:** Next: [State: VALIDATE] — run /aid-summarize again
