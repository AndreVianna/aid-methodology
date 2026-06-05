# State: PREFLIGHT

PREFLIGHT is the synchronous gate that verifies all prerequisites before any
housekeeping state runs; it is selected on every invocation before state
detection proceeds to the resume-detection table.

**Do NOT create any `## Housekeep Status` state during this state.** If PREFLIGHT
fails, the skill exits non-zero with an actionable message and the work-area
STATE.md is left untouched.

---

## Checks

Run the following verifications in order. Stop at the first failure.

### Check 1 — `.aid/` directory exists

```bash
[ -d ".aid" ] || exit 1
```

If `.aid/` is absent, print and exit non-zero:
```
⚠️  /aid-housekeep requires a .aid/ directory.
    Run /aid-config first to initialise the project.
```

### Check 2 — Knowledge Base is present

`/aid-housekeep` is **project-level maintenance** — it does NOT require any
work-area folder to exist (its run-state lives in `.aid/.temp/`, not in a work
folder). It does need a Knowledge Base to reconcile, so verify
`.aid/knowledge/STATE.md` exists:

```bash
[ -f ".aid/knowledge/STATE.md" ] || exit 1
```

If absent, print and exit non-zero:
```
⚠️  /aid-housekeep requires a Knowledge Base (.aid/knowledge/STATE.md).
    Run /aid-config then /aid-discover to populate the KB first.
```

The `STATE_FILE` (the project-level run-state file `.aid/.temp/HOUSEKEEP_STATE_<ts>.md`)
is resolved/created by `SKILL.md § State Detection`, not here — PREFLIGHT must not
create it. Ensure the `.aid/.temp/` directory exists so later states can write it:

```bash
mkdir -p .aid/.temp
```

### Check 3 — Not in Plan Mode

Plan Mode prevents writes. Check whether the current environment is Plan Mode
(the skill context provides this information). If in Plan Mode, print and exit
non-zero:
```
⚠️  /aid-housekeep cannot run in Plan Mode — stages need write access.
    Press Shift+Tab to exit Plan Mode, then re-run /aid-housekeep.
```

### Check 4 — Git repository present and clean enough to branch

```bash
git rev-parse --git-dir > /dev/null 2>&1 || exit 1
```

If not in a git repository, print and exit non-zero:
```
⚠️  /aid-housekeep requires a git repository.
    Initialise git (git init) and make at least one commit, then re-run.
```

Check that the current branch is either `master` or an existing
`aid/housekeep-*` branch (i.e., a safe branching base):

```bash
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
```

If the current branch is neither `master` nor `aid/housekeep-*`, print and
exit non-zero:
```
⚠️  /aid-housekeep must start from 'master' or resume from an 'aid/housekeep-*'
    branch. Currently on: <CURRENT_BRANCH>.
    Switch to master (git checkout master) and re-run, or push and merge the
    current branch first.
```

Check for uncommitted changes that could conflict with branching:

```bash
git diff --quiet && git diff --cached --quiet || echo "dirty"
```

If the working tree has uncommitted changes and the current branch is `master`
(i.e., a new branch would need to be created), print and exit non-zero:
```
⚠️  /aid-housekeep requires a clean working tree on 'master' before creating
    an aid/housekeep-* branch.
    Commit or stash your changes (git stash), then re-run.
```

If the current branch is already an `aid/housekeep-*` branch (resume case),
uncommitted changes are permitted — housekeeping is resuming mid-run.

---

## On Success

Print: `[State: PREFLIGHT] complete.`

**Advance:** **CHAIN** → [State: KB-DELTA] (or [State: CLEANUP] if `--cleanup-only`
was set, but `--cleanup-only` is rejected in delivery-001 — see `SKILL.md § Arguments`).
Continue inline.
