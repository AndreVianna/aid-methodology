# State: SUMMARY-DELTA

SUMMARY-DELTA checks whether `knowledge-summary.html` needs to be regenerated
after the KB stage and, if so, delegates the regeneration to `/aid-summarize`.
It is entered after KB-DELTA CHAINs forward (resume rows 4) when `**KB Stage:**`
is `passed` or `skipped`. All staleness detection and grading logic belongs to
`/aid-summarize` — this state adds only a three-way result classification.

⚠️ **FILESYSTEM IS THE ONLY SOURCE OF TRUTH.** Do NOT rely on memory from a
previous run. Always read actual files on disk.

---

## Step 0 — C1 guard: assert KB stage is complete

Read `**KB Stage:**` from `## Housekeep Status` via `housekeep-state.sh`:

```bash
KB_STAGE=$(bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --read --field "KB Stage")
```

If `$KB_STAGE` is not `passed` or `skipped`, refuse immediately and exit
non-zero:

```
⚠️  SUMMARY-DELTA requires **KB Stage:** to be 'passed' or 'skipped'.
    Current value: <$KB_STAGE>
    Re-run /aid-housekeep — it will route to the correct stage automatically.
```

This is a defensive restatement of the C1 ordering invariant (feature-001 SPEC
§ Sequencing & Gates). In normal operation the SKILL.md State Detection table
never routes here when `**KB Stage:**` is incomplete — this guard is a
belt-and-suspenders check only.

Note: `/aid-summarize`'s own preflight (`summarize-preflight.sh`) requires
`**User Approved:** yes` in `.aid/knowledge/STATE.md` as a second, independent
confirmation that the KB is approved before any HTML is generated.

---

## Step 1 — State-entry banner

Write the run-state fields and print the state-entry banner.

Write through `housekeep-state.sh` (never hand-edit `## Housekeep Status`):

```bash
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "SUMMARY-DELTA"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Last Run" \
    --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Print the state-entry banner from `SKILL.md § State Detection`:

```
[State: SUMMARY-DELTA] — Checking whether the visual summary needs regeneration.
aid-housekeep  ▸ you are here
  [✓ PREFLIGHT ] → [✓ KB-DELTA ] → [● SUMMARY-DELTA ] → [ CLEANUP ] → [ DONE ]
```

Then warn the user about the possible V1 human gate (NFR3 transparency):

```
ℹ️  If the summary is stale, /aid-summarize will regenerate knowledge-summary.html
   and will ask you to open it in a browser and visually confirm it looks correct
   (V1 human gate). This is mandatory — it cannot be auto-passed.
   If the summary is already current and approved, no action is needed.
```

---

## Step 2 — Delegate to `/aid-summarize`

Invoke `/aid-summarize` with **no staleness flags**. Forward only the
`--grade X` override if the user passed one to `/aid-housekeep`; otherwise pass
no flags at all:

```
/aid-summarize [--grade X]
```

Do NOT pass `--reset` (that would force a needless rebuild when the KB stage
was a no-op, violating NFR2 idempotency). Do NOT pass `--profile` or any other
flag. The minimum-grade resolver inside `/aid-summarize` reads from
`.github/scripts/config/read-setting.sh --skill summary --key minimum_grade
--default A`; a `--grade X` override from the user passes through verbatim.

Let `/aid-summarize` run its own state machine verbatim:

```
PREFLIGHT → STALE-CHECK → (PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST
                           → APPROVAL → WRITEBACK) → DONE
```

or short-circuit via DONE-IDEMPOTENT if the summary is already current and
approved. Do NOT edit anything in `.github/skills/aid-summarize/` — the skill
runs unmodified.

When `/aid-summarize` reaches MANUAL-CHECKLIST and asks the K1/K2/V1
questions, let the user respond naturally — that interaction happens inside this
delegated invocation, exactly as it would on a direct `/aid-summarize` run.

---

## Step 3 — Classify the outcome and write `**Summary Stage:**`

After `/aid-summarize` returns, re-read the filesystem to determine which
outcome occurred. The filesystem is the only source of truth
(`.github/skills/aid-summarize/SKILL.md:60`).

Read the following signals from `.aid/knowledge/STATE.md`:

```bash
# Most recent ## Summarization History entry date (empty if no history).
# That section is a pipe-delimited table: | # | Date | Grade | ... | — read the
# Date column (col 3) of the LAST data row, skipping the em-dash placeholder row.
LAST_SUMMARY_ENTRY=$(grep -E '^\| +[0-9]+ +\|' .aid/knowledge/STATE.md \
    | tail -1 | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')
# User Approved field in ## Knowledge Summary Status
USER_APPROVED=$(awk '/^## Knowledge Summary Status/{f=1} f && /^\*\*User Approved:\*\*/{print; exit}' \
    .aid/knowledge/STATE.md | sed 's/.*\*\*User Approved:\*\* //')
```

Compare `LAST_SUMMARY_ENTRY` against this run's start timestamp (`**Last Run:**` above):
a Summarization-History row dated **on or after** this run's start means
`/aid-summarize` regenerated → Branch A; no such fresh row means nothing was
regenerated → Branch B. (The prose rule is normative; the snippet is the aid.)

Use these signals together with the timestamp of this run's start (recorded in
`**Last Run:**` above) to classify the outcome into one of three branches:

---

### Branch A — Regenerated and approved (`**Summary Stage:** passed`)

**Detection:** a new `## Summarization History` entry dated on or after this
run's start exists in `.aid/knowledge/STATE.md` AND
`## Knowledge Summary Status` shows `**User Approved:** yes`.

This covers two sub-paths:
- **Full regeneration** — STALE-CHECK found the KB newer than the last summary
  → GENERATE → VALIDATE → MANUAL-CHECKLIST → APPROVAL → WRITEBACK; a new
  history entry was written by `/aid-summarize`'s WRITEBACK.
- **`CURRENT_UNAPPROVED` approve-only** — STALE-CHECK found the HTML current
  but not yet signed off → `/aid-summarize` skipped GENERATE and went straight
  to APPROVAL; only the `STATE.md` approval edit was made (no new HTML).

Write the gate field:

```bash
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "passed"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Commit the regenerated HTML and the `STATE.md` history edit in a **single**
`branch-commit.sh` call (one commit per stage — C3; never push):

```bash
bash .github/scripts/housekeep/branch-commit.sh \
    --commit \
    --message "chore(housekeep): summary delta refresh [feature-003]" \
    --add .aid/knowledge/knowledge-summary.html \
    --add .aid/knowledge/STATE.md
```

> **Why housekeep owns the commit:** `/aid-summarize`'s WRITEBACK edits
> `STATE.md` history but makes no git commit (it has no VC boundary). So
> housekeep captures both the regenerated HTML and the `STATE.md` history edit
> in a single `branch-commit.sh` call, keeping C3 (one commit per stage)
> intact. For the `CURRENT_UNAPPROVED` approve-only sub-path only `STATE.md`
> changed (no HTML update), but the same `--add` list is used — git will stage
> only the changed file.

Print:

```
✓ SUMMARY-DELTA: summary regenerated and approved — committed.
```

**Advance:** **CHAIN** → [State: CLEANUP] (continue inline).

---

### Branch B — Already current (`**Summary Stage:** skipped`)

**Detection:** no new `## Summarization History` entry since this run started
AND `## Knowledge Summary Status` shows `**User Approved:** yes` (which means
`/aid-summarize` exited via DONE-IDEMPOTENT after STALE-CHECK returned
`CURRENT_APPROVED`). `.aid/knowledge/STATE.md` and
`.aid/knowledge/knowledge-summary.html` are **unchanged**.

Write the gate field:

```bash
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "skipped"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
```

**No commit** (NFR2 idempotency — nothing changed). Print:

```
✓ SUMMARY-DELTA: knowledge-summary.html is already current — skipped (no commit).
```

**Advance:** **CHAIN** → [State: CLEANUP] (continue inline).

---

### Branch C — Below-minimum grade / V1 fail / declined (`**Summary Stage:** stalled`)

**Detection:** `/aid-summarize` returned without producing a fresh
`**User Approved:** yes` for this run. This covers:
- Machine or Human grade below minimum (e.g. diagram parse failure → auto-F on
  D1; V1 human-visual fail → Human Grade forced F).
- User answered "no" or "changes-needed" at `/aid-summarize`'s APPROVAL prompt.
- `/aid-summarize`'s preflight failed (KB not approved — implies C1 guard
  above was somehow bypassed; the delegated preflight is a second safety net).

Determine the specific reason from context (e.g. from `/aid-summarize`'s last
printed state) and set a `<stall-reason>` string, for example:
- `summary V1 visual gate failed`
- `summary grade <X> < minimum <Y>`
- `summary diagram parse failed (D1)`
- `summary approval declined by user`
- `summarize preflight failed`

Write the stall fields:

```bash
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "stalled"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "stalled"
bash .github/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stall Reason" --value "<stall-reason>"
```

Print the resume banner, then PAUSE:

```
⏸  /aid-housekeep paused at SUMMARY-DELTA — <stall-reason>.
   Fix: <actionable instruction, e.g. "correct the failing diagram and re-run /aid-summarize,
        or re-run /aid-housekeep to retry from SUMMARY-DELTA">.
   Resume: re-run /aid-housekeep — it will pick up at SUMMARY-DELTA (not job 1).
```

**No commit** is made in this branch.

**Advance:** **PAUSE-FOR-USER-ACTION** (re-run resumes at SUMMARY-DELTA via
`SKILL.md § State Detection` row 4).
