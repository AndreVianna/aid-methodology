# Handoff: independent review of delivery-001

**From:** the Claude session building work-003. **To:** the Codex session on branch `work-003`.
**Job id:** `h001`. **Type:** review only. You change no file except the one ledger named below.

## Before you start

1. `git pull origin work-003`. Work on the branch head; do not create another branch.
2. Read `AGENTS.md`, `.aid/runtime/rules.md` and `.aid/runtime/templates/reviewer-ledger-schema.md`.
3. Read the delivery's contract:
   - `.aid/works/work-003-full-aid-restructure/PLAN.md` § `### delivery-001: Ask in plain words`
     (Scope and Gate Criteria) and § `## Common Gate (G0)`;
   - `.aid/works/work-003-full-aid-restructure/REQUIREMENTS.md` § Feature 001 and the acceptance
     criteria it cites (AC-1 to AC-7, AC-14, AC-21, AC-23, AC-29);
   - `.aid/knowledge/authoring-conventions.md` for the review criteria of each file type.

## What to review

The delivery-001 change, from the merge base to the resync commit:

```sh
git diff 63aed809 8ead21e8 -- canonical bin lib tests .github .aid/knowledge site
```

Review **the source files only**. Skip `profiles/`, `.claude/`, `.agents/`, `.cursor/`, `.aid/runtime/`,
`AGENTS.md` and `CLAUDE.md`: the resync generates them from `canonical/`, and a test already proves
they match.

Look for:

- an acceptance criterion or gate criterion the change claims but does not meet;
- a defect: wrong behaviour, a broken reference, a script or test that would fail or pass wrongly;
- text that contradicts another file, the Knowledge Base or the requirements;
- a breach of the review criteria for that file's type.

## Already decided: do not report these

- The Feature 001 conversation samples that still fail (known issue KI-007, `known-issues.md`).
- The four other-host runner adapters, deferred to task-365 (KI-006).
- The edit guards cannot see shell or sub-agent edits (accepted as D10; backlog W7-14).
- The resume fallback in the conversation runner is conditional (accepted as D12).
- The 9 suites that fail only on a machine running as root, without the `en_US.UTF-8` locale or
  without Playwright (listed in `analysis/delivery-001-gate.md`).
- Anything already in `analysis/delivery-001-review-c1.md` to `c5.md` with status Fixed or Accepted.

## Output

- Write **one file**: `.aid/works/work-003-full-aid-restructure/analysis/delivery-001-review-codex.md`.
- Its content is a single 7-column ledger table, as the schema says:
  `# | Severity | Status | Doc | Line | Description | Evidence`. Status is `Pending` for every row.
  No narrative and no summary sections. An empty review is a header row with no data rows.
- Report only what you can show with a file path and a line. Give the evidence a reader can check.
- Do not fix anything, do not compute a grade, and do not edit any other file (no state file, no
  `STATE.yml`, no source).
- Do not run `run_generator.py`, `release.sh` or any `aid update`; they rewrite the installed trees.

## When done

```sh
git add .aid/works/work-003-full-aid-restructure/analysis/delivery-001-review-codex.md
git commit -m "h001: Codex review ledger for delivery-001"
git push origin work-003
```

If the push is rejected because the branch moved, run `git pull --rebase origin work-003` (your only
commit is the new ledger file) and push again. Never force-push.

Then tell the maintainer: "h001 done".
