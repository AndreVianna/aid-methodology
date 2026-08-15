# task-048 EVIDENCE -- throwaway render reverted, working tree restored to `HEAD`

Owner of BLUEPRINT § Notes' standing obligation: the throwaway local render is *"not committed,
with `git status --porcelain profiles/ .claude/ .cursor/` clean at this gate"*. This task is the
**single** reverter, as task-039 is the single renderer. Its four dependencies (task-044 through
task-047) are the four leaves of the scratch-project fan -- the last consumers -- so no revert
landed while a consumer was still reading the tree.

## 1. The revert

Pre-revert: **705** entries across the three trees (432 modified, 273 untracked).

```
$ git checkout HEAD -- profiles/ .claude/ .cursor/     # tracked -> current HEAD
$ git clean -fdq profiles/ .claude/ .cursor/           # render-generated untracked -> removed
```

| Assertion | Result |
|---|---|
| `git status --porcelain profiles/ .claude/ .cursor/` | **empty** (0 entries) |
| `git diff --exit-code -- profiles/ .claude/ .cursor/` | clean |
| untracked files remaining under the three trees | 0 |

**No conjunct is stated on the HEAD sha.** Tasks committed between task-039 and this one, so HEAD
has advanced by design and an unchanged-sha assertion would be unsatisfiable. The restoration
target is *current* `HEAD`, in words, not bytes.

## 2. delivery-001's committed file survives the teardown

`.claude/skills/release-aid/SKILL.md` is the one committed deliverable lying **inside** a tree this
task restores wholesale, which is why it is guarded by name -- every other committed path is
outside the three trees, so only this one can be destroyed by a wholesale restore:

```
$ git diff --exit-code HEAD -- .claude/skills/release-aid/SKILL.md      # clean
$ grep -c Unreleased .claude/skills/release-aid/SKILL.md                # 0
   file present: TRUE      bytes changed by the revert: none
```

A restore that put the file back to its pre-render bytes would have silently undone feature-001
AC-7/AC-8. It did not.

## 3. The manifest cross-check -- and why it is a cross-check

task-039's `PRE-RENDER-MANIFEST.md` holds **2644** `sha256sum` entries. Run against the restored
tree:

```
$ sha256sum -c <manifest>
matching: 1486        mismatched: 1158
```

A 1158-path mismatch is the **expected** result, not a defect, and this is exactly why the
manifest was recorded as a cross-check rather than a restoration target. Verified as a set
difference rather than 1158 per-path logs:

```
$ comm -23 <mismatched paths> <paths changed by commits in 574f3d3a..HEAD> | wc -l
0
```

**Zero unexplained mismatches.** Every one is accounted for by a commit that landed between
task-039's pre-render sha `574f3d3a` and current `HEAD` -- five `origin/master` merges, work-009's
`STATE.md` -> `STATE.yml` migration and its re-renders, work-004's render, and the `aid-graph`
removal:

```
edf5a853  Merge remote-tracking branch 'origin/master' into work-006
a9513c71  work-009: re-render profiles after merging origin/master (#190)
6d65abde  work-009: resync dogfood .claude/ + .cursor/ from rendered profiles
b8b01b1b  Completely remove aid-graph skill
98a4926b  work-004 task-015: the single render -- both chains, and what it caught
   ... 14 more
```

Had the manifest bytes been restored literally, all 1158 of those legitimately-updated paths would
have been rolled back -- including `.claude/skills/release-aid/SKILL.md`. Restoring to current
`HEAD` preserves them by construction, with no enumeration to maintain.

## 4. Residue checks -- confirmed, not repaired

Each of these is owned by another task's own restoration criterion; this task's job is to
**confirm**, and to repair-and-record only a residue actually found. **No residue was found
anywhere**, so nothing was repaired here:

| Check | Result |
|---|---|
| `git diff --exit-code HEAD -- canonical/skills/` + untracked | clean, 0 untracked -- `build-shortcut-skills.py` left nothing (all 36 rows are `repurpose: true`, so its output is byte-identical) |
| the six mutated KB docs (`architecture`, `technology-stack`, `test-landscape`, `quality-gates`, `infrastructure`, `decisions`) | `git diff --exit-code HEAD` clean |
| `.aid/design/` | diff clean, 0 untracked -- no seed survived |
| `.aid/settings.yml` and `.aid/knowledge/README.md` | porcelain empty -- **CC-2's registration path never fired in this repository**, as expected: the creation path is unreachable here (all five foundation docs are present and declared), which is why task-045 needed scratch projects |
| work folders in `.aid/works/` other than `work-006` | **0** -- no behavioral run left one behind |
| `git worktree list` | 1 (the main tree only) -- no run created a worktree |
| `.aid/works/` porcelain | 0 entries |
| `.aid/connectors/.secrets/` | unchanged, porcelain empty -- no plaintext secret created, modified or deleted |

## 5. Nothing delivered was reverted

The guard is stated over **paths**, not over a committer list, so it survives a later pass adding
another committer:

```
$ git diff --exit-code HEAD -- canonical/ .aid/knowledge/ .aid/settings.yml \
      .claude/skills/release-aid/SKILL.md
clean
```

The delivery's actual work is intact:

| Committed artifact | Count |
|---|---|
| `aid-design-<grid artifact>` skill directories | 14 |
| `aid-design-<foundation>` | 4 |
| `aid-create-<foundation>` | 4 |
| `aid-update-<foundation>` | 4 |
| `aid-brainstorm` | 1 |
| **total new skill directories** | **27** |
| their `- name:` rows in `shortcut-catalog.yml` | **27** |
| the engine edit (CAPTURE Step 2 seed bullet) | present |
| the two `kb-authoring` doctrine files carrying `quality-gates.md` | 2 |

## 6. Idempotency, and nothing new committed

```
$ git checkout HEAD -- profiles/ .claude/ .cursor/ && git clean -fdq profiles/ .claude/ .cursor/
exit code: 0     porcelain before = 0, after = 0     changed nothing: TRUE
three trees still clean after the re-run: ''
$ git diff --cached --name-only          # (empty)
```

The restore is idempotent: re-running it on an already-restored tree changes nothing and exits
successfully.

**delivery-003's precondition is now met** -- the three trees are clean at this gate, and
task-049's static sweep will audit a clean tree.
