# task-035 — three attempts to reach a prior cycle's ledger

The requirement was that a new review cycle starts from a clean context. That was previously a
**request** — the brief told the reviewer not to read the previous cycle's findings — and the
intent was defeated the first time it was tested. Being told is not the same as being unable.

Three attempts, each recorded with its exit code. The target is
`.aid/.temp/review-pending/execute-d002-wave1.md`, a ledger **an earlier cycle of this delivery
actually wrote**. An arbitrarily absent path would prove nothing: of course you cannot open a file
nobody created.

## Attempt 1 — name it directly from a FIX state

```
$ grep -c 'review-pending/execute-d002-wave1' canonical/skills/aid-discover/references/state-fix.md
0
```

**0 matches** (`grep -c` prints `0`; grep's own shell exit is `1` on no-match, which the suite
absorbs with `|| true`). No instruction anywhere names a prior cycle's ledger. Before task-033 this
state read a hardcoded `discovery.md`; it now reads `{{LEDGER}}`.

## Attempt 2 — resolve it through the parameter

```
$ grep -rn '{{LEDGER}}' canonical/skills --include='*.md' | grep -c 'execute-d002-wave1'
0
```

**0 matches**, same convention as above. `{{LEDGER}}` is resolved per scope at dispatch. A wave-6 dispatch resolves it
to wave-6's path; there is no instruction by which it resolves to wave-1's. The naming is closed.

## Attempt 3 — the preflight, against a seeded leftover

The only structural one. A temporary copy is seeded with a file at the resolved path, and the
cycle-1 preflight is run:

```
$ preflight "$LEFTOVER" 1
PREFLIGHT FAILED: cycle 1 but a ledger already exists at /tmp/.../review-pending/scope-x.md
$ echo $?
1
```

**Exit: 1, naming the file.** It fails rather than warning, because a warning is satisfiable by
ignoring it and the leftover is still sitting there for the reviewer to read.

`LI03` also asserts the mirror: cycle 1 with no leftover proceeds, so the check is not simply
always-fail. And removing the preflight changes the outcome, which is what makes the assertion
non-vacuous.

## What this closes, and what it does not

**The design closes the naming, not the filesystem.** A process that can run `cat` can read any
file on the disk. Nothing here sandboxes a reviewer, and a suite implying otherwise would be lying
about its own guarantee. What is closed is that no instruction hands a reviewer a prior cycle's
path, and a collision at its own path stops the dispatch.

**The structural claim rests on the CI hygiene step, not on ignore rules.** This distinction gets
blurred easily, so it is stated plainly:

```
$ grep -n 'git ls-files .aid/.temp/' .github/workflows/test.yml
146:          [ -z "$(git ls-files .aid/.temp/)" ] || { echo "::error::tracked files under .aid/.temp/"; exit 1; }
```

`.gitignore` keeps a ledger out of a commit **by default**, and a default is exactly what someone
overrides with `git add -f`. The CI step fails the build if anything under `.aid/.temp/` is tracked
at all, which is what stops a ledger from becoming a durable artifact that a later cycle could find
sitting in the tree. The ignore rule is a backstop; the CI step is the enforcement.
