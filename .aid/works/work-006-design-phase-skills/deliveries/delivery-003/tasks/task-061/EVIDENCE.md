# task-061 EVIDENCE -- the render proved fresh, which byte-identity structurally cannot do

feature-006 §6 step 5 and its §10 row *Render fresh*. Closes BLUEPRINT criterion **3**.

## 1. Why this is a separate task from task-060, and not a formality

`test-dogfood-byte-identity.sh`'s own header records that all three artifacts each of its
directions compares -- the manifest, the profile tree, the dogfood tree -- are outputs of the
**same** generator run, and that `canonical/`, the generator's *input*, is not among them:

> *"if all three artifacts are consistently stale, this suite is green."*

That is not speculation in the header; it records that the suite **was** green over the stale
trees a previous re-render existed to replace, both before and after. So byte-identity cannot fail
on a stale or partial render, and this is the only oracle in the delivery that can.

## 2. The check

Precondition established first -- `profiles/` clean at **0** entries after task-060's commit, so a
non-empty diff below could only come from the re-run:

```
$ python3 .claude/skills/generate-profile/scripts/run_generator.py
  [1/3] Byte-identical re-render...  PASS
  [2/3] File-presence audit...       PASS
  [3/3] Frontmatter parse...         PASS
Done. Install trees updated.                                       exit 0

$ git diff --exit-code -- profiles/
                                     # CLEAN
$ git status --porcelain profiles/ | wc -l
0                                    # including untracked
```

**The render is fresh.** Regenerating from `canonical/` reproduces `profiles/` byte-for-byte, so
what is committed is what the current inputs produce -- not a stale tree that merely agrees with
itself.

## 3. This is CI's `render-drift` job, run locally

`.github/workflows/test.yml:44-63` runs exactly these two steps and turns a non-empty diff into an
error:

```yaml
- name: Regenerate install trees from canonical/
  run: python .claude/skills/generate-profile/scripts/run_generator.py
- name: Assert profiles/ has no uncommitted render drift
  run: if ! git diff --exit-code -- profiles/; then ... exit 1
```

Running it here means the property is established **at this gate**, rather than discovered when
the pull request is opened.

**The exec-bit caveat.** CI sets `git config core.fileMode false` explicitly (`test.yml:51-53`,
*"repo is maintained with core.fileMode=false"*) because a checkout can differ from a local tree
in the executable bit alone. Checked rather than assumed: this run produced **no** mode-change
entries in `git diff --summary -- profiles/`, so the clean result above does not depend on that
setting either way.
