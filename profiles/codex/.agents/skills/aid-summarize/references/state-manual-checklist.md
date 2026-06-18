# State: MANUAL-CHECKLIST

MANUAL-CHECKLIST elicits human-judgment answers for the MANUAL_POOL (K1 KB-completeness, K2 fact-grounding, V1 mandatory human visual gate); it is selected after VALIDATE passes the Machine Grade minimum.

The MANUAL_POOL (K1 KB-completeness, K2 fact-grounding) needs human judgment — the script cannot verify it. **This is agent-driven elicitation, not an interactive shell script** (the skill runs inside a host AI tool's chat — the agent gathers the answers, then writes the result file the scoring script consumes).

### Step 1 — generate the fact spot-check report (helps the user answer K2)

Run `.agents/aid/scripts/summarize/spot-check-facts.sh`. It extracts numeric/named claims from the HTML, greps the source KB, and writes `.aid/knowledge/.spot-check-facts.txt` (each line: `[OK|MISS] HTML-claim | KB-evidence`). Show the user the `MISS` lines, if any.

### Step 2 — elicit the human-judgment answers via `AskUserQuestion`

Ask the user (use `AskUserQuestion`; the user must have actually opened the HTML in a browser first — say so):

- **K1 — KB completeness (10 pts):** "Open the generated HTML. Does it represent every populated KB doc you care about?" → Full (10) / Partial (5) / No (0).
- **K2 — facts grounded (15 pts):** "Using the spot-check report above, are the HTML's numeric/named facts accurate against the source KB?" → Full (15) / Partial (8) / No (0).
- **V1 — human visual gate (5 pts, MANDATORY):** "Open the HTML in a real browser. Confirm ALL of: (a) every diagram renders, no error blocks; (b) diagram + node text is legible in BOTH light AND dark themes — including the EXPANDED lightbox view; (c) theme toggle works; (d) lightbox opens / Esc closes / Tab cycles." → Pass (5) / Fail (0). **V1 is a gate: a Fail forces Human Grade = F and blocks APPROVAL.** No automated check covers diagram-internal legibility — this is the only safeguard.
- **Free-text:** "Anything else off — framing, depth, tone, missing content?" — capture verbatim.

### Step 3 — write the result file

The agent passes the answers to `manual-checklist.sh` (non-interactive mode — it computes the scores and writes the JSON, so the script stays the single source of truth for scoring):
```
bash .agents/aid/scripts/summarize/manual-checklist.sh \
  --k1 <y|p|n> --k2 <y|p|n> --v1 <y|n> --notes "..." --html .aid/dashboard/kb.html
```
This writes `.aid/knowledge/.manual-checklist.json` with `K1_score`, `K2_score`, `V1_score`, the answers, notes, and timestamp. (A contributor in a raw terminal can instead run `manual-checklist.sh --interactive`.)

### Step 4 — score and route

Re-run `grade.sh` — it reads `.manual-checklist.json`, computes the Human Grade from MANUAL_POOL (K1+K2+V1, 30 pts), and the Overall Grade = `min(Machine_letter, Human_letter)`. Persist Machine + Human + Overall Grade to `.aid/knowledge/STATE.md` `## Knowledge Summary Status` `### Findings (last validation)`.

- Overall Grade ≥ minimum → APPROVAL.
- **V1 failed → mandatory: Human Grade is forced to F.** Go to FIX; the visual defect must be fixed and V1 re-confirmed before APPROVAL.
- Overall Grade < minimum → FIX. **If the shortfall is in MANUAL_POOL** (K1/K2 partial-or-no, or V1 fail) or the free-text notes flagged something, FIX uses the **expose → propose → ask** loop (see `references/state-fix.md`) — never silent guess-fixing.

Print: `[State: MANUAL-CHECKLIST] complete.`

**Advance:** **CHAIN** → [State: APPROVAL] if Overall Grade ≥ minimum; **CHAIN** → [State: FIX] otherwise. Both continue inline.
