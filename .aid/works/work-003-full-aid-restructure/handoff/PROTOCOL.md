# Claude–Codex coordination for work-003

Two AI sessions share the work-003 build:

- **Claude** runs in a cloud container. It owns the build: tasks, state, resync and gates.
- **Codex** runs on the maintainer's side. It takes jobs that Claude writes here.

The sessions cannot reach each other over the network, so **git is the only channel**: the
`work-003` branch on `origin`. The maintainer relays one short message each way per job.

## Roles

| | Claude | Codex |
|---|---|---|
| Writes the work's state (`STATE.yml`, task `STATE.yml`, `PLAN.md` checkboxes) | Yes, only Claude | Never |
| Runs the resync (`run_generator.py`, `sync_dogfood.py`, `aid update`) and the gates | Yes | Never |
| Edits source (`canonical/`, `bin/`, `lib/`, `tests/`, `site/`, `.aid/knowledge/`) | Yes | Only when a job says so, and only the files it names |
| Writes its own reply and output files under `handoff/replies/` and `analysis/` | | Yes |
| Asks the maintainer a question | Yes | Yes, in its reply file, never by guessing |

## Standing delegation (Q154)

For the rest of work-003, to spread usage, Claude sends Codex:

- **Reviews:** the quick review of every task, batched one job per wave, and each delivery's full
  review. Codex writes each as a 7-column ledger; Claude grades it, fixes and re-asks.
- **Machine-limited runs:** test suites that cannot run on Claude's machine (root, locale).
- **Building:** later, if usage still needs it, whole tasks named in a job.

Claude keeps building (through its own helpers), fixing, state writes, resyncs and gates.

## A job

1. Claude writes a job file `handoff/hNNN-<slug>.md`, points `handoff/NEXT.md` at it, commits and
   pushes. The maintainer tells Codex: "pull work-003 and do handoff/NEXT.md".
2. Codex runs `git pull origin work-003` and reads, in order: this file, `NEXT.md`, the job file.
3. Codex does only what the job says. A job names every file Codex may write.
4. Codex commits only those files, with the message `hNNN: <what it did>`, and pushes to `work-003`.
   If the push is rejected because the branch moved: `git pull --rebase origin work-003`, then push
   again. Never force-push, never rebase anything but your own unpushed commits, never create or
   delete a branch.
5. Codex writes `handoff/replies/hNNN.md` (in the same commit) with: `status: done | blocked | partial`,
   the commit, what it did in a few lines, and any question. Then it tells the maintainer: "hNNN done"
   (or "hNNN blocked: <one line>").
6. The maintainer tells Claude the same line. Claude pulls, reads the reply, and acts.

**While a job is open, Claude pushes nothing that touches the job's files**, so the two sessions
never edit the same file at once.

## Rules that bind Codex (from `.aid/runtime/rules.md` and the work's plan)

- Write only inside the project folder.
- Never merge, never open a pull request, never push to any branch but `work-003`.
- No model id in a commit message. Codex commits end with the line
  `Co-Authored-By: Codex <noreply@openai.com>`.
- No email, credential, token or session URL in any committed file.
- Never name a work id or a work-folder path inside `.aid/knowledge/**`.
- Review output is always the 7-column ledger (`.aid/runtime/templates/reviewer-ledger-schema.md`).
- Delete nothing unless the job names the file to delete.

## Environment Codex needs

| Tool | Version | Used for |
|---|---|---|
| git | any recent | the channel |
| bash | 5.x | every test suite (`tests/run-all.sh`, `tests/canonical/*.sh`) |
| python3 | 3.10 or later, with PyYAML | generator, state writer, conversation runner |
| node and npm | 22 or later (CI pins 24) | site tests (`cd site && npm ci && npm test`), chat node |
| pwsh | 7.x (optional) | PowerShell halves of some suites |
| `en_US.UTF-8` locale | (optional) | 4 suites that check locale independence |
| Playwright with Chromium | (optional) | `test-kb-export`, `test-visual-fidelity` |

A review job needs only git and a shell. A job that runs tests says which suites, and each runs as
`HOME="$(mktemp -d)" bash tests/canonical/<suite>.sh` from the repository root.
