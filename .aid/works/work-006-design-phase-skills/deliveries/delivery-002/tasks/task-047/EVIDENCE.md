# task-047 EVIDENCE -- engine additivity: absent seed => unchanged behavior

feature-005 §8 row **V14**, closing its **AC-7** and REQUIREMENTS **AC-10** -- the one criterion
in this work that is about **shipped behavior of existing skills**. It also carries the
behavioral half of BLUEPRINT criterion 3, which V12's grep establishes only statically.

## 0. The baseline, captured before the comparison run

V14 says the baseline *"must be captured first -- the slot set is agent judgment, not a recorded
artifact, so there is nothing to compare against after the fact"*. This task runs after the engine
edit landed, so "first" is achieved by **running the unedited engine first**, and the baseline copy
is overwritten with `master`'s **rendered** engine:

```
$ git show master:profiles/claude-code/.claude/aid/templates/shortcut-engine.md \
    > F-noseed-master/.claude/aid/templates/shortcut-engine.md
$ diff <master's rendered engine> F-noseed-master/.claude/aid/templates/shortcut-engine.md
                                          # byte-identical, asserted BEFORE run 1 started
$ grep -c '\.claude/aid/'   -> 32         # install paths already rewritten
$ grep -c 'canonical/aid/'  -> 0          # so the baseline is not the canonical file
```

That last pair is the AC's own stated reason for using the rendered copy: the **canonical**
master file would carry unrewritten `canonical/...` paths and differ from the run-2 engine in more
than the change under test.

### Oracle drift, recorded rather than papered over

The AC's rationale expects the two engines to differ in *"exactly the two hunks task-026 added
and in nothing else"*. They no longer do:

```
$ diff <master's rendered engine> <this branch's rendered engine> | grep -c '^[0-9]'
44 differing blocks
  of which task-026's:  the "`design` family is deliberately absent" paragraph  -> 1
                        the CAPTURE Step 2 `.aid/design/{artifact}.md` bullet   -> 1
  all the rest:         the STATE.md -> STATE.yml migration (43 diff lines name one or the other)
```

The migration landed on this branch after this task was written, so the AC's prescribed baseline
now falls foul of the AC's own rationale. **It weakens nothing, and here is why:** the row's
result is *identity* -- run 2's slot set equals run 1's. An identical outcome across a **superset**
of engine differences is a **stronger** result than identity across the two hunks alone: 42 extra
differing blocks had the opportunity to move the slot set and none did. A confound that could
only have *changed* the outcome did not. Logged `[LOW]` for the gate as a stale premise in the
DETAIL, not a failed criterion.

## 1. Fixtures

Four copies, each under `mktemp -d`, each `git init`-ed with a baseline commit (so
`git status --porcelain` inside one is a real result rather than an exit-128 misread), each
carrying the rendered dogfood `.claude/`, a `.aid/knowledge/INDEX.md` and a `.aid/settings.yml`:

| Fixture | Engine | `.aid/design/` |
|---|---|---|
| F-noseed-master | `master`'s rendered copy | **absent entirely** |
| F-noseed-head | this branch as rendered | **absent entirely** |
| F-seed-api | this branch as rendered | `api.md`, distinctive `## Current direction` |
| F-seed-document | this branch as rendered | `document.md`, its own distinctive one |

The `create` family scaffolding file is identical in every copy (only the engine file was
swapped), so the `api` slot list -- *resource; endpoint path; request/response schema; security
notes* -- is the same input to every run.

## 2. V14 / AC-7 / REQUIREMENTS AC-10 -- absent seed, unchanged behavior

Both runs were `/aid-create-api "add an endpoint to list widgets"`, carried to CAPTURE Step 3 and
abandoned. **Run 1 preceded run 2.** The slot set is recorded verbatim, because it is agent
judgment and a bare "they matched" claim would be unfalsifiable:

```
  Step 3 -- MINIMAL SLOT SET:
    ANSWERABLE without asking:
      §1 Objective / §2 Problem   <- {description}, lightly restated
      §3 Users & Stakeholders     <- inferred: the requesting developer/maintainer
      §4 Scope                    <- bounded by {verb=create, artifact=api} + description
      §6 Non-Functional           <- N/A (no target named)
      §7 Constraints              <- N/A (none named in description or KB)
      §8 Assumptions & Deps       <- best-effort from .aid/knowledge/INDEX.md
      §10 Priority                <- Must (default)
      api slot "resource"         <- widgets
    GENUINE GAPS (load-bearing for §5 / §9):
      api slot "endpoint path"
      api slot "request/response schema"
      api slot "security notes"
    ESCALATION: ONE combined question folding all three gaps into a single turn.
```

Run 1 recorded it with no design-seed bullet in its engine at all. Run 2's engine **does** carry
the bullet (`grep -c 'design/{artifact}.md'` -> 1), so the absent-file branch was genuinely
evaluated -- `{artifact}` is `"api"`, non-empty, and the file is absent, which is the guard's
*"CAPTURE proceeds exactly as before"* leg.

```
$ diff <run 1's Step 3 block> <run 2's Step 3 block>
                                          # identical
$ test ! -d R1/.aid/design ; test ! -d R2/.aid/design      # both TRUE
```

**V14 PASS.** The three properties §4a fixes are each measured: **conditional** and **additive**
by run 2 (an absent seed leaves behavior byte-identical, and no existing bullet, rule or state
transition changed its effect -- the same 8 answerable slots, the same 3 gaps, the same single
combined question), and **non-mutating** by runs 3 and 4 below.

**Not claimed:** run 2 exercised the absent-**file** fallback only. `/aid-create-api` carries
`artifact: api`, so the empty-`{artifact}` half of the guard was **not** behaviorally covered
here; it is asserted statically by task-026 over the bullet's own text. Stating it as covered
would be false.

## 3. BLUEPRINT criterion 3, the seed-present half, behaviorally (run 3)

`/aid-create-api` in F-seed-api. The seed's `## Current direction` is distinctive: `GET
/v1/widgets` returning `{ "items": [Widget], "next": string|null }`, bearer token with the
`widgets:read` scope, 403 without it.

The run **loaded it as prior context** and its own output **cites that direction verbatim**.
The slot set is **narrowed relative to run 2, not replaced**:

| `api` slot | run 2 | run 3 |
|---|---|---|
| resource | answerable | answerable |
| endpoint path | **gap** | answered from the seed (`GET /v1/widgets`) |
| request/response schema | **gap** | answered from the seed (`{ items, next }`) |
| security notes | **gap** | answered from the seed (bearer + `widgets:read`) |
| page size | -- | **the one remaining gap** (the seed's own `## Open questions`) |

Escalation went from one combined question over three gaps to one question on page size alone --
**3 gaps -> 1**. The same slot inventory was applied, the same §1-§10 sections were still authored
from `{description}` + KB, and the write-up was still produced. The seed supplied answers; it did
not stand in for the write-up.

## 4. Run 4 -- the hand-authored half, reaching the fourteenth pair

`/aid-create-document` in F-seed-document. `aid-create-document` is a G8 collapse skill with
`repurpose: true` (`shortcut-catalog.yml:770`) whose hand-authored body **never executes**
`shortcut-engine.md`, so the engine's CAPTURE Step 2 bullet cannot reach this pair. The read
under test is the one task-027 added to the body itself:

```
canonical/skills/aid-create-document/SKILL.md:62
  6. **Read the design seed, if present.** If `.aid/design/document.md` exists, read it as
     prior context before drafting; it is an input, never a substitute, and is not modified
     by this run.
```

INTAKE step 6 read the seed **before drafting** and the run cites its `## Current direction`: a
Diataxis explanation page titled "How a request travels", ordered by the hops a request makes,
one Mermaid sequence diagram, no API reference material -- all four the seed's own words. Without
run 4 the read would be demonstrated for **thirteen** of the fourteen paired artifacts.

## 5. Non-mutating, in both directions of the read

```
run 3:  .aid/design/api.md       sha256 identical to fixture; still in place
        git status --porcelain .aid/design/   -> ''   (no modification, no deletion)
run 4:  .aid/design/document.md  sha256 identical to fixture; still in place
        git status --porcelain .aid/design/   -> ''
```

## 6. Run discipline, determinism, isolation, teardown

**Four runs and no fifth**, each stopped at CAPTURE Step 3 (run 4 before AUTHOR) and its copy
discarded. None proceeded into the engine's authoring states:

```
$ find R1 R2 R3 R4 -name 'REQUIREMENTS.md' -o -type d -name 'work-0*' | wc -l
0
```

A run that scaffolded a whole Lite work would have left this task's subject.

**Determinism** -- replaying runs 1 and 2 over the same inputs reproduced both transcripts
exactly, and the run-1 vs run-2 slot-set identity held on the replay too.

**Isolation.** The repository's own `.claude/aid/templates/shortcut-engine.md` was never
overwritten -- only the scratch copies were. Proven positively rather than by absence: the repo's
copy is **not** byte-identical to `master`'s (so no contamination) and **does** carry task-026's
two hunks, i.e. it is the branch render task-039 owns.

```
$ git status --porcelain .aid/knowledge/ .aid/design/ .aid/settings.yml .aid/works/ \
      profiles/ .claude/ .cursor/ | wc -l
705       # identical before and after -- task-039's live render, nothing else
$ git diff --cached --name-only          # (empty)
$ git diff --exit-code -- tests/ site/scripts/__tests__/    # clean
```

No `git add -A` / `git add .` / `git add -u` / `git commit -a` while the render is live. It
rendered nothing and reverted nothing -- task-039 owns the render and task-048 the revert. The
`mktemp -d` root and all six directories under it are removed on completion, including on failure.
