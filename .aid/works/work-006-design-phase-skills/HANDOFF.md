# Handoff — work-006-design-phase-skills

Written for a fresh session picking this work up mid-pipeline with no prior context.
Read it end to end before acting. It is a work-folder artifact and is deleted when the
work ships; nothing permanent depends on it.

**Branch:** `work-006` (start from its tip) · **Phase:** Execute

---

## 1. Where the work stands

| Delivery | Tasks | State |
|---|---|---|
| delivery-001 | 001–025 | **25/25 `Done`.** Its quality gate has NOT run — that is your first job |
| delivery-002 | 026–049 | 24 `Pending`, delivery `Specified` |
| delivery-003 | 050–074 | 25 `Pending`, delivery `Specified` |

The three deliveries are one chain — delivery-002 enters through the single edge
`026 → 020`, delivery-003 through `050 → 049` — so there is no cross-delivery
parallelism to exploit.

**What delivery-001 shipped:** the nine planning-artifact skills
(`aid-{design,create,update}-{roadmap,mvp,backlog}`) with their nine
`shortcut-catalog.yml` rows; the three spine-dimension arms
(`roadmap.md`→`D`, `backlog.md`→`C7`, `release-tracking.md`→`C8`) in both KB script
twins; this repository's own `roadmap.md` (with its `## MVP` region) and `backlog.md`,
both registered as **conditional**, leaving the canonical seed unmoved at 14 templates;
the retirement of `release-tracking.md`'s `## Unreleased` with its item migrated to
`backlog.md` as `W5-21`; `release-aid`'s drain rewired onto `backlog.md`; three
`document-expectations.md` blocks; and regenerated `INDEX.md` / `relationships.md`.

---

## 2. Your immediate next action

Run **delivery-001's quality gate**, per
`.claude/skills/aid-execute/references/state-delivery-gate.md`.

Two of its steps are already done and need not be repeated:

- **AGGREGATE** — `delivery-001-issues.md` holds **14 findings, 13 open** (11 `[HIGH]`,
  2 `[MEDIUM]`) plus 1 `[MEDIUM]` already `Fixed`. Verify with
  `bash .aid/.temp/count-ledger.sh` after recreating it, or count the file directly —
  do not trust this number if the file has moved on.
- **SCORE** — `tasks=25 depth=23 consults=0`, **tier = Large**. Note the caveat in §6.

**The specific next action:** write `.aid/.temp/review-pending/execute-delivery-001.md`
as ONE seven-column markdown table — `# | Severity | Status | Doc | Line | Description |
Evidence` — no prose, no headings. Seed it with the open rows from
`delivery-001-issues.md`, adjudicating each against disk, then add your own fresh
findings. Then:

```bash
bash .claude/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-delivery-001.md
```

Minimum grade is **A** (`.aid/settings.yml`). Below that → fix cycle → re-review, with a
3-cycle circuit breaker.

---

## 3. Read this before your first state write

Every state write goes through `.claude/aid/scripts/execute/writeback-state.sh`, which
defaults its target to a placeholder and **fails silently** unless you export the work's
location. The calls are documented as "silent state-write — no output", so a missing
export looks exactly like success while recording nothing. This is the repo's own
tech-debt item **W5-5**.

Create this wrapper first — `.aid/.temp/` is gitignored, so it never survives a fresh
checkout and must be recreated every session:

```bash
mkdir -p .aid/.temp
cat > .aid/.temp/wb.sh <<'EOF'
#!/usr/bin/env bash
export AID_STATE_FILE=".aid/works/work-006-design-phase-skills/STATE.md"
export AID_WORK_DIR=".aid/works/work-006-design-phase-skills"
exec bash .claude/aid/scripts/execute/writeback-state.sh "$@"
EOF
```

Verify it before trusting it: run one write and confirm it prints `OK: … updated`.

---

## 4. Binding process rules

- **State-write protocol, no exceptions.** A task's `State` is written the moment it
  changes: `In Progress` before work starts, `In Review` before the reviewer is
  dispatched, a terminal `Done`/`Failed` at the end. This binds you whether you execute
  directly or dispatch. A task sitting at `Pending` through its whole execution and then
  jumping to `Done` is the exact failure the rule exists to prevent.
- **Reviewer ≠ executor.** After each task's EXECUTE, dispatch a separate clean-context
  reviewer for a quick check reporting only `[CRITICAL]` and `[HIGH]`. `[CRITICAL]` → fix
  on spot; `[HIGH]` → defer to the delivery gate via
  `wb.sh --delivery-id NNN --append-issue "| task-NNN | [HIGH] | … | Open |"`. No grade is
  computed per task.
- **`canonical/` is the SOURCE.** `profiles/*` and the dogfood `.claude/` tree are
  RENDERS — never hand-edit a render. One exception: `.claude/skills/release-aid/SKILL.md`
  is a repo-local maintainer-only ops skill with no canonical source, and the
  byte-identity suite allowlists it.
- **The Knowledge Base names no work id and no work-folder path**, and carries no
  `## Change Log` or `changelog:` frontmatter.
- **Commit per task with explicit paths** (`git add <path>`, never `git add -A`), and
  **push after every task.** Earlier in this work the repository was re-cloned and nine
  unpushed commits were lost permanently. Do not accumulate unpushed work.

---

## 5. The most important pattern in this work

**Three acceptance criteria have now proved unsatisfiable by any correct implementation.**
Each time, the resolution was to correct the oracle, never to bend the shipped code, and
each time the executor was right to stop rather than force green.

1. **task-016** asserted a "non-realizing" invocation (a readiness refusal or a routing
   exit) allocates no `work-NNN` folder. False: allocation is unconditional skill shape and
   happens at `INTAKE`, ahead of the `GUARD` that refuses and the `REALIZE` that routes.
   Corrected in three DETAILs by commit `1c6b20c4` — including delivery-002's **task-044**,
   which carried the same premise, so that one is already fixed for you.
2. **task-020** required a vitest drift-check to be green whose subject pages the PLAN
   assigns to delivery-003 task-064. Resolved by a narrow owner exception: delivery-001
   refreshed only the drift its own work caused.
3. **Open, awaiting decision** — the two `aid-update-{roadmap,mvp}` description findings
   look like an oracle defect rather than a code defect. All nine descriptions were audited
   against SPEC §6d: seven match exactly. But §6d assigns `aid-update-backlog` its own
   absent-destination route while §6c (`SPEC.md:860-862`) requires all three `update`
   skills to route to the document's owner on absence — so §6d's omission for the two
   roadmap rows is the anomaly, and V25's ceiling clause then conflicts with AC-8's
   mutuality requirement. **Do not force the descriptions.** Put it to the owner.

**If you hit a fourth instance: stop, raise an IMPEDIMENT, report it.** Never weaken a
test or edit a shipped skill to make a criterion pass.

---

## 6. Traps that will cost you hours if you rediscover them

- **`complexity-score.sh` silently reports `risk=0`** for any hierarchical delivery — its
  `--tasks-dir` scan is `find -maxdepth 1 -name '*.md'`, which matches nothing under
  `tasks/task-NNN/DETAIL.md`. delivery-001's honest score is **56**, not 48. Tier is
  `Large` either way, so no gate decision changes.
- **`kb-citation-lint.sh` exits 1 with 11 violations** — all in `tech-debt.md` and
  `test-landscape.md`, all pre-dating this work. Verified against a `git archive` of
  `95fe9cfb`. Delivery-001 introduced none. Do not "fix" them here.
- **`check-skill-counts.mjs` is red by design** — stale counts in `site/` and
  `generate-profile`. delivery-003 owns the re-bootstrap (task-069 raises the ratchets).
  Do not fix it early.
- **Expensive operations, budget for them and never run speculatively:** the full profile
  render, and `/aid-summarize` (~24 minutes, and its automated visual gate does not run at
  all, so the gate is an orchestrator step). delivery-003 owns both.
- **`/aid-graph` is being retired** — the owner has ruled its output needs no verification.
  Do not spend effort grading `relationships.md`.
- **Keep `git status --porcelain profiles/ .claude/ .cursor/` clean at every delivery
  gate.** delivery-003 owns the only committed render.

---

## 7. Open findings, with what is already established

All 12 open rows live in `delivery-001-issues.md`. These are verified on disk — reuse the
evidence rather than re-deriving it:

- **`.aid/knowledge/roadmap.md:90` AND `:49`** both route readers to the `## Unreleased`
  section task-018 retired, so a shipped KB doc states a falsehood in two places. `:49` is
  the newer find — fix both in one pass. `roadmap.md` is a **fifth carrier** feature-001
  AC-6 never enumerated (`SPEC:198-207` lists four), and **no task in the plan owns the
  fix**.
- **`.aid/knowledge/roadmap.md:155`** cites `decisions.md` for a claim that document
  contradicts — D19 (`decisions.md:346-370`) records the opposite.
- **The override flag is unreachable.** Six skills tell a refusal to name "the override
  flag", but no literal token exists anywhere in `canonical/`, so every run invents one.
- **V23 coverage is 8 of 9.** `aid-create-backlog` has no work-folder + no-`phase:` run
  record anywhere, because task-015 and task-021 both closed `Done` with `notes: "--"` in
  breach of their own criteria. Verified pre-existing, not an artifact of the recovery in
  §8. Remedy: task-021 supplies the record, or the gate reassigns it.
- **Two evidence-quality rows:** task-016's `EVIDENCE.md` §4.7 records the V6/V16
  determinism replay with no command; task-023's `EVIDENCE.md:664` claims 23 invocation
  records where its own table enumerates 19.

---

## 8. One piece of history that explains odd-looking artifacts

Mid-execution the repository was **re-cloned**, destroying the local object store: nine
unpushed commits, the local branch, and several local-only branches were lost, with
`git reflog` showing only `clone:`. `origin/work-006` still sat at the session's starting
point.

Recovery ran off the session transcripts rather than by re-doing the work: the six
`SKILL.md` bodies, both twin-script edits, four catalog rows, the `aid-config` amendment,
`roadmap.md` with its `## MVP` insertion and every registration were replayed
**byte-for-byte** from recorded tool-call payloads. One file — `.aid/knowledge/backlog.md`
— had no recorded payload and was reconstructed from a read of it, then validated against
its reviewer's independently recorded checks.

Why it matters to you: those artifacts are restorations, not fresh authorship, so treat
them as you would any other code — but do not be surprised that their commits post-date
the tasks that logically produced them. Everything has been pushed after every task since.

---

## 9. After the gate

Execute delivery-002 (tasks 026–049), then delivery-003 (tasks 050–074), each with its own
gate at minimum grade **A**. delivery-003 is where the committed profile render, the
generated site pages, the count re-bootstrap and the single `/aid-summarize` re-run land.

Work state lives in `STATE.md` at the work root (pipeline header + lifecycle history),
`deliveries/delivery-NNN/STATE.md` (delivery lifecycle + gate), and
`deliveries/delivery-NNN/tasks/task-NNN/STATE.md` (per-task cells). The work-root
`## Tasks State` and `## Delivery Gates` sections are DERIVED read-only views — never
write them directly.
