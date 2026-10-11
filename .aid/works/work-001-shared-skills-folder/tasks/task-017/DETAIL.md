# task-017: Shared-install suite: byte-identical skills and runtime for every tool

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** TEST

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-3, AC-7, AC-14

**Depends on:** task-012, task-013, task-014

**Scope:**
- `tests/canonical/test-shared-install.sh` (new; S1 to S5 conventions, `HOME` pinned, fixtures
  built per run, staging via `tests/lib/bundle.sh`).
- AC-3, for each of the five tools in a fresh fixture: `aid add <tool> --from-bundle <staging>`;
  every `canonical/skills/<rel>` equals `.agents/skills/<rel>` byte-for-byte (and
  `.claude/skills/<rel>` for claude-code); the `aid-*` file count under `.agents/skills` equals
  `find canonical/skills -type f | wc -l`. Negative control: mutate one byte of one staged skill
  inside a copy of the shared payload (re-packed and `SHA256SUMS` dropped),
  install it, and assert the byte comparison fails.
- AC-7, for each tool: every file in `.aid/runtime/{scripts,templates}/` equals its
  `canonical/aid/{scripts,templates}/` source and `.aid/runtime/rules.md` equals `canonical/aid/rules.md`; no `aid/` directory under `.claude`, `.codex`,
  `.cursor`, `.github` or `.agent`; pre-seeded `.aid/knowledge/x.md`, `.aid/works/w/STATE.yml` and
  `.aid/design/d.md` keep identical sha256 across `aid add`, `aid update` and `aid remove`; a stray
  file placed in `.aid/runtime/` is gone after the next `aid update`; a fixture file
  `.aid/runtime/scripts/summarize/node_modules/x.js` survives `aid update`, nothing from it lands
  in `.aid/.trash/`, and `aid status` prints no `extra:` line for it. The byte-for-byte comparison
  with `canonical/aid/{scripts,templates}` ignores the FR-6 runtime-local paths and applies the payload exclusions (dot-files, `node_modules/`, `.git/`). After
  `aid add cursor` in a fixture holding a user `.gitattributes` line, `.gitattributes` contains
  the managed block with the three `text eol=lf` lines and the user line is unchanged.
- AC-14 cases (a), (b), (e) and (f), as worded in REQUIREMENTS.md § 9 (the § 11 test plan places
  them here): (a) `aid add claude-code` into a fixture with no `CLAUDE.md` creates one whose bytes
  equal the import region (`<!-- AID:BEGIN -->`, `@AGENTS.md`, `<!-- AID:END -->`, each
  LF-terminated) and the fixture's `AGENTS.md` equals the five-line pointer region, and
  `aid add cursor` into a second such fixture creates no `CLAUDE.md`; (b) with a no-marker,
  LF-terminated user `CLAUDE.md`, the pre-add bytes are a byte-exact prefix and only the import
  region follows, and a following `aid update` leaves its sha256 unchanged; (e) a user `AGENTS.md`
  with no markers holding a `## Workflow` section keeps that section byte-for-byte, with the pre-add
  bytes as a byte-exact prefix followed by the pointer region; (f) repair by content, three
  fixtures -- a user `CLAUDE.md` holding `<!-- AID:BEGIN -->` with no `<!-- AID:END -->` followed by
  user text, a user `AGENTS.md` holding two copies of the pointer region around user text, and a
  user `CLAUDE.md` holding a lone `@AGENTS.md` line: after `aid add claude-code` each file holds
  exactly one well-formed region, every other line is present unchanged and in its original order,
  and a full copy of the pre-add file exists at `.aid/.trash/<file>`; a following `aid update`
  leaves each file's sha256 unchanged and adds no trash entry. In each fixture, while Claude Code
  is installed, `CLAUDE.md` has exactly one `@AGENTS.md` line and `AGENTS.md` exactly one
  `<!-- AID:BEGIN -->` line.
- Deferred review note (definition-gate ledger row 22): Tree-walk equality checks against `canonical/aid/` must apply the payload exclusions (dot-files, `node_modules/`, `.git/`), since CI runs `npm ci` inside `canonical/aid/scripts/summarize/`.

**Acceptance Criteria:**
- [ ] `HOME=$(mktemp -d) bash tests/canonical/test-shared-install.sh --verbose` exits `0`, with a `PASS:` line per tool for the AC-3 byte comparison, the AC-3 file count, each AC-7 clause (including the `rules.md` equality and the `node_modules/` survival), one for the negative control, one per AC-14 (a)/(b) clause, one for AC-14 (e), one per AC-14 (f) fixture, and one for the AC-7 `.gitattributes` block with its preserved user line.
- [ ] Reverting the payload mutation guard (forcing the negative control to install unmutated bytes) in a scratch copy makes the negative-control assertion fail, proving the control is live.
- [ ] The suite reads no file under `.aid/works/` of this repository and leaves the real repo's `git status --porcelain` unchanged.
- [ ] All section-6 quality gates pass.
