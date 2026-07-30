# State: MANUAL-CHECKLIST

MANUAL-CHECKLIST elicits the human-judgment answers no machine can produce — KB completeness, fact-grounding, and the mandatory human visual check; it is selected after VALIDATE's grade clears the minimum.

These need human judgment because the script cannot verify them. **This is agent-driven elicitation, not an interactive shell script** (the skill runs inside a host AI tool's chat — the agent gathers the answers, then writes the result file).

**The checklist records answers; it does not score them.** Its answers become ledger findings like any
other, and `grade.sh` derives the letter from the ledger. There is no separate human grade to combine.

### Step 1 — generate the fact spot-check report (helps the user answer K2)

Run `canonical/aid/scripts/summarize/spot-check-facts.sh`. It extracts numeric/named claims from the HTML, greps the source KB, and writes `.aid/.temp/summarize/spot-check-facts.txt` (each line: `[OK|MISS] HTML-claim | KB-evidence`). Show the user the `MISS` lines, if any.

### Step 2 — elicit the human-judgment answers via `AskUserQuestion`

Ask the user (use `AskUserQuestion`; the user must have actually opened the HTML in a browser first — say so):

- **K1 — KB completeness (`SUMMARY-01`):** "Open the generated HTML. Does it represent every populated KB doc you care about?" → Full / Partial / No. A `Partial` or `No` answer becomes one `[MEDIUM]` finding **per document the user names as missing** — ask which ones.
- **K2 — facts grounded (`SUMMARY-05`):** "Using the spot-check report above, are the HTML's numeric/named facts accurate against the source KB?" → Full / Partial / No. Anything short of Full becomes a finding per inaccurate fact; the spot-check report's `MISS` lines are the evidence.
- **V1 — human visual check (`SUMMARY-06`, MANDATORY):** "Open the HTML in a real browser. Confirm ALL of: (a) every diagram renders, no error blocks; (b) diagram + node text is legible in BOTH light AND dark themes — including the EXPANDED lightbox view; (c) theme toggle works; (d) lightbox opens / Esc closes / Tab cycles." → Pass / Fail. A Fail is a `[HIGH]` finding per failing visual and blocks approval. No automated check covers diagram-internal legibility — this is the only safeguard.
- **Free-text:** "Anything else off — framing, depth, tone, missing content?" — capture verbatim.

### Step 3 — write the result file

The agent passes the answers to `manual-checklist.sh`, which **records** them (it no longer scores them):
```
bash canonical/aid/scripts/summarize/manual-checklist.sh \
  --k1 <y|p|n> --k2 <y|p|n> --v1 <y|n> --notes "..." --html .aid/knowledge/kb.html
```
This writes `.aid/.temp/summarize/manual-checklist.json` with the answers, notes, and timestamp. (A contributor in a raw terminal can instead run `manual-checklist.sh --interactive`.)

### Step 4 — append findings, then grade

For each answer short of a clean pass, append a ledger row to `.aid/.temp/review-pending/summarize.md`
citing the rule above, then re-grade the ledger:

```bash
bash canonical/aid/scripts/review/check-gaps.sh --ledger .aid/.temp/review-pending/summarize.md
bash canonical/aid/scripts/grade.sh --explain .aid/.temp/review-pending/summarize.md
```

Persist the grade and findings to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`
`### Findings (last validation)`.

- Grade ≥ minimum → APPROVAL.
- Grade < minimum → FIX. **If the shortfall is in the human-judgment answers** or the free-text notes flagged something, FIX uses the **expose → propose → ask** loop (see `references/state-fix.md`) — never silent guess-fixing.

#### A `V1` failure is three different outcomes, and they must not be conflated

`V1` used to be one boolean that meant all three of these at once, which is how a single `F`
came to stand for a broken visual, a dead page, and a check nobody had run.

| What the human found | Outcome |
|---|---|
| **A specific visual is broken or illegible** — the ordinary case | A `SUMMARY-06` row per failing visual, `[HIGH]`. The grade follows from the rows, exactly like any other finding, and routes to FIX. Do **not** reach for `--non-functional`: the page works, one visual in it does not. |
| **The page produces nothing usable** — nothing renders, the file will not open, the theme toggle is dead | `bash canonical/aid/scripts/grade.sh --non-functional`. This is the flag's declared meaning and its only legitimate use here — `grading-rubric.md § Severity scale` defines it as the whole-artifact verdict *"does not build, does not run, produces no usable output"*. Reaching for it because a diagram is ugly would make `F` mean two things again. |
| **The checklist has not been answered** | **No grade at all.** See below. |

**If the checklist has NOT been completed, do not grade and do not route.** Halt and ask the human. This
is a **pause, not a failing grade** — the previous behaviour reported `F`, which asserts a result nobody
observed and makes an unanswered check indistinguishable from a genuinely failed one. `SUMMARY-06`
cannot be answered by an agent, so an agent proceeding here is the failure this gate exists to prevent.
Note that this is also what keeps `--non-functional` honest: without a separate pause, "unanswered" had
nowhere to go but `F`, and `F` is what `--non-functional` produces.

Print: `[State: MANUAL-CHECKLIST] complete.`

**Advance:** **CHAIN** → [State: APPROVAL] if the grade ≥ minimum; **CHAIN** → [State: FIX] otherwise. Both continue inline. If the checklist is unanswered, neither — halt.
