# task-060 EVIDENCE -- build helper, full five-profile render, both dogfood trees, byte-identity green

feature-006 §6 steps 1-4, REQUIREMENTS **C-5**, **NFR-1**, **AC-1**. Closes BLUEPRINT criterion
**2**. **This is the committed render** -- delivery-002's task-039 produced a throwaway that
task-048 reverted; this is the real one, and it runs after every `canonical/` edit in the work has
landed, which is why it sits here.

## 1. The two commands, in C-5's order

```
$ python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py
Generated/refreshed 0 doorway(s) (34 already up to date), skipped 60 repurpose row(s), removed 0 orphan(s).

$ python3 .claude/skills/generate-profile/scripts/run_generator.py       # FULL run, never partial
  Profiles: ['antigravity', 'claude-code', 'codex', 'copilot-cli', 'cursor']
  [1/3] Byte-identical re-render...  PASS
  [2/3] File-presence audit...       PASS
  [3/3] Frontmatter parse...         PASS
Done. Install trees updated.
```

`0 doorway(s)` written by the helper is the correct result, not a skipped step: task-051 already
regenerated all thirty-four, so the tree was byte-current before this task began. The render wrote
**845** files, **169 per profile**, evenly across all five.

## 2. The dogfood trees are not written by the render -- which is why an explicit resync exists

Measured immediately after the full render, before any resync:

```
$ git status --porcelain .claude/ .cursor/
0 entries   and   0 entries
```

That is the load-bearing property feature-006 §6 step 3 relies on: `run_generator.py` writes
`profiles/` and nothing else.

**A correction to that step, made by resolving its basename against disk.** §6 step 3 attributes
the dogfood trees to `setup.sh` -- *"the dogfood trees are reached only by `setup.sh`"*. **There is
no `setup.sh` anywhere in this repository.** The repo-root installers are `install.sh` and
`install.ps1`, and `install.sh` bootstraps the global `aid` CLI rather than writing a project tree.
What `project-structure.md` actually says of `.claude/` and `.cursor/` is *"a rendered claude-code
profile"* / *"a rendered cursor profile"*, each marked **"No (regenerate via install)"**. So the
mechanism is the install path, not a named script -- and the conclusion §6 draws is unchanged and
correct.

## 3. The resync is a merge, and the allowlist is why

`rsync` is not installed in this environment, so the merge is done directly: copy every profile
file into the dogfood tree, then delete only what the profile does **not** have **and** the
tuple's own allowlist does **not** protect.

```
.claude/   source= 354   copied/updated=121   orphans removed= 0   allowlisted kept=17
.cursor/   source= 354   copied/updated=121   orphans removed= 0   allowlisted kept= 1
```

The two allowlists are transcribed from `test-dogfood-byte-identity.sh` and are **not
interchangeable** -- copying the `.claude/` list onto `.cursor/` is feature-006 risk 8, because six
of its seven patterns have no `.cursor/` counterpart and would excuse files that do not exist.
`.cursor/`'s list is `worktrees/*` plus `rules/*` only.

A `rm -rf`-style resync would have destroyed **this task's own toolchain** and delivery-001's
committed deliverable. Both verified intact afterwards:

```
.claude/skills/release-aid/SKILL.md   present, byte-identical, git diff HEAD clean
                                      grep -c Unreleased -> 0   (feature-001 AC-7/AC-8)
.claude/skills/generate-profile/scripts/   9 files before, 9 after
```

## 4. Byte-identity, both tuples, all three directions

The suite reports **6 passed, 1 failed** -- and the one failure is the known environment gap, not
a content defect:

```
FAIL: DBI01 manifest contains no .claude/ entries -- is the manifest empty?
$ grep -c '"dst": "\.claude/' profiles/claude-code/emission-manifest.jsonl
354                                        # the manifest is not empty
$ awk -W version   ->  mawk 1.3.4          # gawk absent; the loader needs it
```

This is the third symptom of the `[MEDIUM]` gawk finding the delivery-002 gate adjudicated, and it
was pre-existing there too. So the criterion is discharged the way that gate discharged MT01/MT02
-- by an independent check rather than by accepting a blocked one:

| Tuple | D1 profile -> dogfood mismatches | D2 manifest dsts / mismatches | D3 unallowlisted orphans |
|---|---|---|---|
| `.claude/` | **0** | 354 / **0** | **0** |
| `.cursor/` | **0** | 354 / **0** | **0** |

**Both tuples, all three directions: GREEN.**

## 5. The repurpose rows and the five-profile reach

All **60** `repurpose: true` rows came out byte-identical -- the build helper rewrote none of them
(`git status --porcelain canonical/skills/` -> **0** entries). That is the *only* oracle for the
`repurpose` field, which the parser reads permissively with `r.get("repurpose", False)`.

The thirty-six new descriptions and the thirty-four regenerated ones reached **all five** profile
roots -- the prefix matters, because three of the five bare root names do not exist at the
repository root and a fourth is the GitHub config directory:

| Profile root | `aid-design-api` | carries its new trigger | `aid-brainstorm` |
|---|---|---|---|
| `profiles/claude-code/.claude/` | yes | yes | yes |
| `profiles/codex/.codex/` | yes | yes | yes |
| `profiles/cursor/.cursor/` | yes | yes | yes |
| `profiles/copilot-cli/.github/` | yes | yes | yes |
| `profiles/antigravity/.agent/` | yes | yes | yes |

and the regenerated doorway wording (`"so run /aid-execute to carry the plan out"`) is present in
**5/5**.

Task-061 owns the freshness oracle, which is a *different* check: a consistently stale render
passes byte-identity and fails render-drift.
