# task-044 EVIDENCE -- the three `create` refusals and the repeat-`create` route, in scratch projects

Closes the **refusal half** of BLUEPRINT criterion 4 -- the half whose failure mode is a
**fourth** gate re-entering. Rows: feature-004 **V6**, **V7**, **V18**, **V26** and **V27**.

## 0. Isolation and fixtures

Every run happened in a scratch project under `mktemp -d`. The task's write set in the working
tree is **empty**, which is what makes it schedulable beside task-045..047:

```
$ git status --porcelain .aid/knowledge/ .aid/design/ .aid/settings.yml
                                          # (empty) -- all three
$ ls -d .aid/works/*/ | grep -v work-006 | wc -l
0                                         # no work folder allocated in THIS repo
$ git worktree list | wc -l
1
$ git diff --exit-code -- tests/ site/scripts/__tests__/   # clean
```

It rendered nothing and reverted nothing; the throwaway render stayed at its 705 entries
untouched.

**F-pop -- the pristine baseline**, `git init`-ed with a baseline commit. The `git init` premise
is load-bearing: outside a work tree `git status` exits **128**, which is not "empty" and would
be misread as a pass.

```
$ git rev-parse --is-inside-work-tree ; git log --oneline | wc -l
true
1
$ git status --porcelain ; echo "rc=$?"
rc=0                                      # empty AND a real result
```

It carries the rendered dogfood `.claude/` (so the twenty-seven skills are invocable from that
directory -- `ls -d .claude/skills/aid-create-architecture` -> 1), a `.aid/settings.yml`
declaring `architecture.md|aid-researcher-architecture|required`, a **populated** 27-line
`.aid/knowledge/architecture.md` with `source: hand-authored` and a `## Contents` consistent
with its body, a `README.md` with a Completeness table and a `**Doc-set:** N documents` line,
and **no** `.aid/design/`.

Each row below ran on its **own fresh `cp -a`** of F-pop -- `F-noseed`, `F-open`, `F-gen`
(plus `F-gen-create` and `F-gen-update`, one per verb), `F-committed`. No row inherited another
row's mutation, and no row repaired its own precondition.

**Allocation is not part of the realizing/non-realizing distinction: all six invocations
allocated.** Allocation is unconditional skill shape and happens at INTAKE, ahead of the GUARD
that refuses. What the contract scopes to the realizing path is **seed deletion**, which is why
the rows below turn on seed survival rather than on a folder's absence. (An earlier revision of
this task asserted a non-realizing invocation "allocates nothing"; that premise was false and
is the same one that made a criterion unsatisfiable in task-016.)

## 1. V6 -- seed-absent refusal (F-noseed)

```
$ grep -c 'REFUSED (condition 1 of 3)' .v6.transcript        # 1
$ grep -c '/aid-design-architecture' .v6.transcript          # 1  -- it NAMES the design skill
$ git status --porcelain .aid/knowledge/                     # (empty)
$ git diff --exit-code -- .aid/knowledge/architecture.md ; echo $?
0                                                            # destination byte-identical
$ test ! -f .aid/design/architecture.md ; echo $?            # 0 -- nothing fabricated
$ test -f .aid/works/work-001-create-architecture/STATE.yml ; echo $?
0                                                            # allocated anyway (skill shape)
```

**V6 PASS.** Writing nothing is *not* sufficient for this row -- the refusal must name
`/aid-design-architecture`, and it does.

## 2. V7 -- the readiness gate (F-open)

The fixture's `## Open questions` is non-empty **by feature-002 §4's detection rule**: one
non-blank line that is neither the literal `None` nor a whole-line `{...}` placeholder.

```
$ sed -n '/^## Open questions/,/^## /p' .aid/design/architecture.md | sed '1d;$d' \
    | grep -vE '^\s*$' | grep -vE '^None$' | grep -vE '^\{[^}]*\}$'
Is a retry safe when the schema version differs between reader and writer?
$ grep -c 'REFUSED (condition 2 of 3)' .v7.transcript        # 1
$ grep -c 'Is a retry safe' .v7.transcript                   # 1 -- names the question
$ grep -c 'override-open-questions' .v7.transcript           # 2 -- names the override token
$ test -f .aid/design/architecture.md ; echo $?              # 0 -- seed STILL PRESENT
# sha256 before == after, for both files:
  seed byte-identical: TRUE
  destination byte-identical: TRUE
$ git status --porcelain .aid/knowledge/                     # (empty)
```

**V7 PASS.** Worth recording: the refusal can name a *literal* override token
(`--override-open-questions`) only because delivery-001's gate fixed that -- before it, the six
skills ordered a refusal to name "the override flag" with no token defined anywhere, so each run
invented one.

## 3. V18 -- `source: generated` refused by BOTH verbs (two fresh copies of F-gen)

F-gen's destination frontmatter is `source: generated` **and** its seed is ready
(`## Open questions` -> `None`), so production mode is the **only** available reason to refuse.

| Verb | Refused | Destination clean | Seed still present |
|---|---|---|---|
| `/aid-create-architecture` (F-gen-create) | yes | `git diff --exit-code` -> 0 | TRUE |
| `/aid-update-architecture` (F-gen-update) | yes | `git diff --exit-code` -> 0 | TRUE |

**V18 PASS for both verbs.** A working-tree `git diff` check is valid here precisely because the
edit is never made.

## 4. V26 -- the repeat `create` routes, does not overwrite, does not halt (F-committed)

**Authored run 1** realized a ready seed that added `## Invariants` (plus its `## Contents`
entry, in the same write) and the result was **committed** in the scratch repository -- which is
what makes run 2's subject *"content this lifecycle previously committed"* (§6b) rather than
as-built content.

**Authored run 2** received a second seed whose `## Destination` named `## Invariants` (already
committed) **plus** `## Data Flow` (not yet written):

```
$ grep -c '^## Data Flow' .aid/knowledge/architecture.md          # 1  -- the NEW part was written
$ grep -c '\[Data Flow\](#data-flow)' .aid/knowledge/architecture.md
1                                                                 # its Contents entry, same write
$ git diff -U0 .aid/knowledge/architecture.md | grep -c '^[+-].*durable'
0                                                                 # the COMMITTED section untouched
$ grep -c '/aid-update-architecture' .v26.transcript              # 2  -- it NAMES the route
$ git diff --numstat .aid/knowledge/architecture.md | cut -f1
7                                                                 # it did NOT halt with nothing done
# the surviving seed carries ONLY the unrealized part:
  present=TRUE   mentions 'Data Flow'=0   mentions 'Invariants'=2
```

**V26 PASS** on all four conjuncts: wrote the new section, left the committed section
byte-identical, named `/aid-update-architecture` for it, and left the seed carrying only the
unrealized part.

## 5. The routed seed has a consumer (CC-3) -- a **third** authored run

Asserted rather than assumed, because without it a routed seed would accumulate:

```
$ test ! -f .aid/design/architecture.md ; echo $?
0                                                        # /aid-update-architecture consumed it
$ grep -c 'durable before it is acknowledged' .aid/knowledge/architecture.md
1                                                        # its Current direction landed ...
$ sed -n '/^## Invariants/,/^## /p' .aid/knowledge/architecture.md | grep -c 'durable before'
1                                                        # ... inside the section it named
$ ls .aid/design/ | wc -l
0                                                        # no orphan seed left behind
```

Run count: **three authored runs** (V26's two `create` runs plus this `update`) and **four
non-realizing invocations** (V6's `create`, V7's `create`, V18's `create` and `update`).

## 6. V27 -- no fourth `create` gate, read whole over all four bodies

task-035..037 each asserted their own share at authoring time; this is the row read whole:

| Body | refusal conditions | `grep -niE 'empty\|populated\|non-empty\|hand-authored\|line count'` over the CREATE state | `source: generated` present |
|---|---|---|---|
| `aid-create-architecture` | **3** | 0 | yes |
| `aid-create-stack` | **3** | 0 | yes |
| `aid-create-testing-strategy` | **3** | 0 | yes |
| `aid-create-cicd` | **3** | 0 | yes |

**V27 PASS.** And the mandated third condition survives in all four, so V27 is **not** satisfied
by deleting a refusal the spec requires -- the two halves are checked together on purpose,
because each one alone can be gamed by breaking the other.

## 7. Teardown

The `mktemp -d` root and all seven fixture copies are removed on completion. Nothing outside it
was written at any point.
