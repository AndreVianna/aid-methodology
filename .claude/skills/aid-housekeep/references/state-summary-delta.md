# State: SUMMARY-DELTA

SUMMARY-DELTA checks whether `kb.html` needs to be regenerated
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
KB_STAGE=$(bash .claude/aid/scripts/housekeep/housekeep-state.sh \
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
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "State" --value "SUMMARY-DELTA"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "running"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
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
ℹ️  If the summary is stale, /aid-summarize will regenerate kb.html
   and will ask you to open it in a browser and visually confirm it looks correct
   (V1 human gate). This is mandatory — it cannot be auto-passed.
   If the summary is already current and approved, no action is needed.
```

---

## Step 1b — Migrate legacy summary path (FR31 belt-and-suspenders)

Before delegating to `/aid-summarize`, perform the same guarded migrate that
PREFLIGHT does, as defense-in-depth for paths where housekeep is entered
directly or before PREFLIGHT has had a chance to run in this invocation:

```bash
OLD_SUMMARY=".aid/knowledge/knowledge-summary.html"
NEW_SUMMARY=".aid/knowledge/kb.html"
MIGRATED_THIS_RUN=0
if [ -f "$OLD_SUMMARY" ] && [ ! -f "$NEW_SUMMARY" ]; then
    if mkdir -p .aid/knowledge 2>/dev/null && mv -n "$OLD_SUMMARY" "$NEW_SUMMARY" 2>/dev/null; then
        echo "i  Migrated legacy summary -> $NEW_SUMMARY (FR31 relocation)."
        MIGRATED_THIS_RUN=1
    else
        echo "i  Could not migrate legacy summary (continuing; summary will regenerate)." >&2
    fi
fi
```

This step is **best-effort** (never block on failure) and **idempotent** (if the new path
already exists, the `[ ! -f "$NEW_SUMMARY" ]` guard makes it a no-op). Track whether a
move occurred this run via `MIGRATED_THIS_RUN` for use in the Branch-B commit below.

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
`.claude/aid/scripts/config/read-setting.sh --skill summary --key minimum_grade
--default A`; a `--grade X` override from the user passes through verbatim.

Let `/aid-summarize` run its own state machine verbatim:

```
PREFLIGHT → STALE-CHECK → (PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST
                           → APPROVAL → WRITEBACK) → DONE
```

or short-circuit via DONE-IDEMPOTENT if the summary is already current and
approved. Do NOT edit anything in `.claude/skills/aid-summarize/` — the skill
runs unmodified.

When `/aid-summarize` reaches MANUAL-CHECKLIST and asks the K1/K2/V1
questions, let the user respond naturally — that interaction happens inside this
delegated invocation, exactly as it would on a direct `/aid-summarize` run.

---

## Step 3 — Classify the outcome and write `**Summary Stage:**`

After `/aid-summarize` returns, re-read the filesystem to determine which
outcome occurred. The filesystem is the only source of truth
(`.claude/skills/aid-summarize/SKILL.md:60`).

Read the following signals from `.aid/knowledge/STATE.md`:

```bash
# Most recent ## Summarization History entry date (empty if no history).
# That section is a pipe-delimited table: | # | Date | Grade | ... | — read the
# Date column (col 3) of the LAST data row, skipping the em-dash placeholder row.
LAST_SUMMARY_ENTRY=$(grep -E '^\| +[0-9]+ +\|' .aid/knowledge/STATE.md \
    | tail -1 | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')
# Summary approval: frontmatter-first (`summary_approved`, task-004), legacy
# `## Knowledge Summary Status` **User Approved:** bold line as fallback for an
# un-migrated STATE.md (same dual-format read as stale-check.sh).
USER_APPROVED=$(awk '
    NR==1 && $0 !~ /^---[ \t]*$/ { exit }
    NR==1 { in_fm=1; next }
    in_fm && /^---[ \t]*$/ { exit }
    in_fm && /^summary_approved:/ {
        sub(/^summary_approved:[ \t]*/, ""); gsub(/^"|"$/, ""); print; exit
    }
' .aid/knowledge/STATE.md)
if [ -z "$USER_APPROVED" ]; then
    USER_APPROVED=$(awk '/^## Knowledge Summary Status/{f=1} f && /^\*\*User Approved:\*\*/{print; exit}' \
        .aid/knowledge/STATE.md | sed 's/.*\*\*User Approved:\*\* //')
fi
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
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "passed"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "passed"
```

Commit the regenerated HTML and the `STATE.md` history edit in a **single**
`branch-commit.sh` call (one commit per stage — C3; never push):

```bash
bash .claude/aid/scripts/housekeep/branch-commit.sh \
    --commit \
    --message "chore(housekeep): summary delta refresh [feature-003]" \
    --add .aid/knowledge/kb.html \
    --add .aid/knowledge/STATE.md
```

> **Why housekeep owns the commit:** `/aid-summarize`'s WRITEBACK edits
> `STATE.md` history but makes no git commit (it has no VC boundary). So
> housekeep captures both the regenerated HTML and the `STATE.md` history edit
> in a single `branch-commit.sh` call, keeping C3 (one commit per stage)
> intact. For the `CURRENT_UNAPPROVED` approve-only sub-path only `STATE.md`
> changed (no HTML update), but the same `--add` list is used — git will stage
> only the changed file.

Re-stamp `.aid/settings.yml kb_baseline.tip_date` to the current default-branch
tip (FF-A4, FR36) so the card flips from `outdated` back to `approved` on the
next reader poll (DD-A4):

Resolve the default branch using the same DD-A2 detection order as
`aid-discover` state-done (FR35):
1. Read `kb_baseline.branch` from `.aid/settings.yml` — use it if present and non-empty.
2. Else resolve `origin/HEAD`: `git symbolic-ref --short refs/remotes/origin/HEAD` and take the basename.
3. Else use the first of `{main, master}` that exists: `git branch --list <name>`.

Then read the tip commit date:
```bash
git log -1 --format=%cI <branch>
```

Select the write idiom (R13 — same selection as task-059/aid-discover DONE):
- **`kb_baseline` block already present** in `.aid/settings.yml`: use the
  single-line **"Save in place"** replace (`/aid-config` SKILL.md:124) —
  replace only the `tip_date:` line within the existing block:
```bash
cp .aid/settings.yml .aid/settings.yml.tmp
sed "s|^  tip_date:.*|  tip_date: <ISO-8601-tip-date>|" .aid/settings.yml.tmp > .aid/settings.yml.tmp2
mv -f .aid/settings.yml.tmp2 .aid/settings.yml
rm -f .aid/settings.yml.tmp
```
- **`kb_baseline` block absent** (KB generated before task-059 ran — fallback):
  use the **append-block** idiom (`/aid-config` SKILL.md:126-132) — append the
  full nested block to a temp copy and atomically rename:
```bash
cp .aid/settings.yml .aid/settings.yml.tmp
cat >> .aid/settings.yml.tmp << 'EOF'

kb_baseline:
  branch: <resolved-branch>
  tip_date: <ISO-8601-tip-date>
EOF
mv -f .aid/settings.yml.tmp .aid/settings.yml
```

If git is absent, the repo has no commits, or the branch cannot be resolved,
skip the re-stamp silently (the reader degrades gracefully — FF-A2, DD-A2).

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
`.aid/knowledge/kb.html` are **unchanged**.

Write the gate field:

```bash
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "skipped"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "skipped"
```

**No commit** (NFR2 idempotency — nothing changed), **except** when a FR31 migration
occurred this run (`MIGRATED_THIS_RUN=1`): in that case the relocated file must be
committed so the relocation is captured in VC even on the skip path:

```bash
if [ "${MIGRATED_THIS_RUN:-0}" -eq 1 ]; then
    bash .claude/aid/scripts/housekeep/branch-commit.sh \
        --commit \
        --message "chore(housekeep): migrate kb.html path (FR31 relocation) [feature-007]" \
        --add .aid/knowledge/kb.html
    # Never block on commit failure -- the file is on disk where the reader needs it.
fi
```

Print:

```
✓ SUMMARY-DELTA: kb.html is already current — skipped (no commit).
```

(If a migration commit was made, print it before the above line.)

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
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Summary Stage" --value "stalled"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
    --state <STATE_FILE> --write --field "Stage Status" --value "stalled"
bash .claude/aid/scripts/housekeep/housekeep-state.sh \
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
