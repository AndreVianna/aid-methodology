# Start and resume a trial work

This opt-in prototype reuses the existing shared work-initiation gate for
enumeration and allocation, including its fail-closed worktree rules. It does
not silently allocate alongside another work or replace an existing record.
The old gate can be costly; the trial has not demonstrated a cost improvement.

For new work, the gate itself allocates nothing. Follow its NEW handoff: derive
the work ID from its cross-worktree enumeration, create and enter the indicated
worktree, then exclusively create the empty work directory there. If any step
fails, stop; do not fall back to another directory. Once this operation owns
that new directory exclusively, initialize direct state **before creating any
other file in it**:

```bash
python3 .aid/runtime/scripts/change/state.py --init-work-dir '<work-dir>' --goal '<single-line goal>' --initiator aid-outcome
```

Pass arguments as separate host-tool arguments or safely quote user-provided
values. The initializer reads the existing `aid-change` minimum-grade setting,
or its existing default, and publishes state only after its staged writes
succeed. If allocation or initialization fails, stop and report the error;
do not delete or overwrite existing artifacts or retry a failed state write.
Then create `REQUIREMENTS.md` **exclusively** in that directory, providing the
reviewed content on stdin:

```bash
python3 .agents/skills/aid-outcome/scripts/work_requirements.py create --work '<work-dir>'
```

Run from the entered project root and use the project-relative
`.aid/works/work-NNN-name` path for `<work-dir>`.

If it already exists, do not replace it; inspect and reconcile. After successful
creation use the existing state writer to record the actual next action and
evidence. If the process stops between
state initialization and requirements creation, the state still says that
requirements need recording. On resume inspect the actual files and evidence;
never infer the requirements were written successfully. If this is the
initialized work's first requirements document and it is still absent, create
it exclusively from the confirmed request. If it exists, inspect it instead;
do not replace it or infer that an interrupted write completed.

The same helper supports `inspect --work '<work-dir>'` to print the current
requirements SHA-256 and `check --work '<work-dir>' --expected-sha256 '<sha>'`
to refuse a changed file before an edit. It does not parse the lifecycle, write
updates, or provide an atomic compare-and-swap against unrelated concurrent
editors. Check the state separately and coordinate exclusive editing; if a
conflict is detected, preserve both intentions and reconcile.

For continuation, read the current state and the one requirements document.
The updated gate routes running direct work with `pipeline.initiator:
aid-outcome` to this entry only when the opt-in skill is available; it stops if
the entry is missing. Blocked, paused, completed and canceled work retains the
existing lifecycle boundaries. Other direct work continues to route to
`aid-change`. This is an instruction-level integration; actual host behavior
and hook loading must be tested in the target host before claiming enforcement.
Record state changes with the existing state writer, including the next action
and evidence, without inventing completion, approval or a successful review.
The writer can be called without printing its complete source. From the entered
project root, set `work` to the exact project-relative work directory and
`next_action` to the truthful next action; pass both as shell variables:

```bash
AID_STATE_FILE="$work/STATE.yml" AID_WORK_DIR="$work" \
  bash .aid/runtime/scripts/execute/writeback-state.sh --pipeline \
  --field 'Direct Next Step' --value "$next_action"
```

Use the same writer with `--field 'Direct Evidence'` and the actual evidence.
Consult the applicable gate routing and worktree instructions; read additional
sections when needed rather than assuming a short excerpt is sufficient.
