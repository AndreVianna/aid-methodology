# task-007: Conditional matrix rows and concern-model entries for roadmap, backlog and release-tracking

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-007/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-006, task-010

**Scope:**
- Source spec: `features/feature-001-kb-doc-set-restructure/SPEC.md` §1b (surfaces 1 and 2),
  §1c, §2c, §3a and AC-12; REQUIREMENTS CC-4 (the surface set is exactly four and is defined
  in feature-001), CC-6 (`roadmap.md` / `backlog.md` are domain-agnostic by construction).
- **The `task-010` edge is a shared-state edge, not a content one.** AC-2's oracle here is
  `find canonical/aid/templates -type f …` (the narrowed form this task fixes, below) -- a
  read of the whole `canonical/aid/templates/` **directory**, not of one named file -- and
  task-010 **writes `canonical/aid/templates/shortcut-catalog.yml`**, a path inside it. That
  one path is what makes the two meet; task-010's other writes are three `canonical/skills/`
  directories, which this task's oracle no longer reaches. Running the two concurrently lets
  this task's `find` walk a directory being written. The edge costs nothing: task-010 and
  task-006 both unblock at the same point, so this task's position does not move.
- **Surface 1 --
  `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`**: add **24** four-field rows
  (`filename | spine-dimension | owner | presence`), one per document in each of the eight
  domain sections (`software-cli`, `software-web`, `data-ml`, `content`, `research`,
  `design`, `ops`, `methodology-tooling`):
  `roadmap.md | D | skill-self | conditional:project maintains a forward plan`;
  `backlog.md | C7 | skill-self | conditional:project maintains a defined-and-prioritized backlog`;
  `release-tracking.md | C8 | skill-self | conditional:project cuts versioned releases and records what shipped in each`.
  Use the shipped single-space cell padding so AC-2's `grep -c` anchor matches; no `<when>`
  clause may contain a comma (a comma is shredded by the doc-set parser -- use `;`).
- **The same file's three self-describing tallies** (AC-12), all three falsified by the rows
  above: the `software-cli` prose written as though `decisions.md` were the only conditional
  entry; the `14 required docs (the seed) + 1 conditional` tally; and the Seed-consistency
  bullet list enumerating the known conditional extensions. The three new bullets are
  **added beside** the `decisions.md` bullet, never in place of it -- MT17 greps the whole
  Seed-consistency section for the literal strings `decisions.md` and `NOT`, and is the
  check that catches a replace-instead-of-append edit.
- **Surface 2 -- `concern-model.md` § Seed-coverage check**: name each of the three as
  conditional with its concern id -- `roadmap.md` **D** (a roadmap entry is a committed
  decision, true now, with a rationale; C9 is present-tense realized capability and is
  wrong for it), `backlog.md` **C7** (sibling of `tech-debt.md`; an accepted-but-unshipped
  item is owed), `release-tracking.md` **C8**. `backlog.md` and `release-tracking.md` get
  their own statements rather than being filed under `### D` by proximity.
- Out of scope: **surface 3 (`document-expectations.md`) in full -- all three blocks,
  task-017.** feature-001 §6 **step 2** assigns this task the registration surfaces *"and the
  `### release-tracking.md` block in full"*, i.e. ahead of feature-003's step 4. That one
  block is deliberately **relocated to step 5's task** so the file has a single owning task:
  the other two blocks are content-blocked on feature-003 (§6 step 5), and three edits to one
  file across two waves is the collision the sequencing exists to prevent. The relocation is
  free -- nothing in this delivery gates on that block landing early, and AC-11 is evaluated
  once, in task-017.
- Also out of scope: surface 4 (`_dim_of_filename` -- task-008); any file under
  `canonical/aid/templates/` for the three documents, whose **absence is the mechanism** by
  which the seed stays at 14 (§1a); and `release-tracking.md`'s `doc_set` presence value,
  which already reads what CC-1 prescribes.

**Acceptance Criteria:**
- [ ] AC-2, first half, run in the form AC-2's **own criterion text** fixes -- *"None has a
      file anywhere under `canonical/aid/templates/`"*:
      `find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' \)`
      returns nothing. **The SPEC's printed form,
      `find canonical -iname '*roadmap*' …`, is not used, because it becomes unsatisfiable by
      a correct implementation**: `-iname` matches basenames, so once feature-003 lands its
      directories it matches `canonical/skills/aid-design-roadmap`,
      `aid-create-roadmap`, `aid-update-roadmap` and the three `*-backlog` siblings. The
      narrowed form asserts exactly what the criterion says and nothing it does not
- [ ] AC-2, second half: the domain-scoped
      `awk '/^### Domain:/{d=1} d' domain-doc-matrix.md | grep -c '^| \`<file>\`'` returns
      `8` for each of the three filenames
- [ ] AC-12 oracle: the `software-cli` section's `grep -c '| conditional'` -> `4` (it is `1`
      today), **and** `grep -n '4 conditional' domain-doc-matrix.md` returns the prose tally
      naming all four documents; the `software-cli` prose and the Seed-consistency list agree
      with the counted rows
- [ ] MT17 still green -- the three new Seed-consistency bullets are additions, and the
      literal `decisions.md` bullet is still present
- [ ] `test-domain-doc-matrix.sh` (MT01/MT02/MT06/MT17) and `test-spine-depth-coverage.sh`
      (SD04/SD05/SD07) pass **unmodified**: the added rows carry `conditional:<when>`, so
      MT01/MT02's `/\| required/` filter never sees them, and SD07 asserts `>= 58` so more
      rows only raise the margin
- [ ] Every `<when>` clause is comma-free
- [ ] Each of the three is named as conditional in `concern-model.md` with the concern id
      §3a assigns it, and the seed **count** the Seed-coverage section asserts is unchanged
- [ ] `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` is clean
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
