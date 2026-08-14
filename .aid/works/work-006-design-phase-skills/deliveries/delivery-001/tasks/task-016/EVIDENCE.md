# task-016 -- EVIDENCE

Durable evidence log for the behavioral verification of the `design` and `create` stages and
the deferred acquisition oracles. Every row named in this task's `DETAIL.md § Scope` appears
below with **the command that produced it** and **its observed output**. Nothing is reported
as covered without its oracle and result.

This task authored no test script under `tests/` and minted no bash assertion id -- both are
out of scope per § Scope. The runs were driven from throwaway shell drivers under
`.aid/.temp/` (gitignored, removed at teardown); this file is the durable record.

---

## 1. Execution model, and what is a deviation

| Aspect | How it ran |
|---|---|
| Session | One agent session, as § Scope anticipates (*"which is what keeps this task inside one agent session"*) |
| Skill bodies | Read from the **rendered** dogfood tree task-024 produced (`profiles/claude-code/.claude/...` copied into each scratch project as its installed bundle). This task rendered nothing and reverted nothing |
| Producer role (`DESIGN` / `REALIZE`) | Performed inline by the executing agent |
| Verifier role (`VERIFY` step 2) | **Clean-context `aid-reviewer` sub-agent dispatches** -- 7 in total (run 1: 3 cycles, run 2: 3 cycles, run 3: 1 cycle). The ledger each returned was written to `.aid/.temp/review-pending/<work>-verify.md` inside the scratch project and graded with the installed `grade.sh` |
| Scratch root | `mktemp -d`, with `TMPDIR` pinned to a persistent base (`$HOME/.aid-t016-tmpbase`). **Deviation, and its reason:** WSL's `/tmp` is wiped between shell invocations on this host (the distro cold-starts), so a bare `/tmp` scratch does not survive from one oracle to the next. The root is still `mktemp -d`-created, everything lives under it, and it is removed on completion |

Resolved scratch root for this run: `/home/andre/.aid-t016-tmpbase/tmp.pRbgijVmKC`.

**Allocation leaves a git worktree as well as a work folder.** Every one of the five
invocations ran the Work Initiation Gate, and `worktree-lifecycle.sh create` produced a
worktree under `<project>/.claude/worktrees/` alongside the `work-NNN` folder. This is the
already-filed `W5-20` (`.aid/knowledge/backlog.md`), not a new finding, and it matches the
precedent task-015 § Scope records. Artifact writes landed in the invoking project tree, as
that same precedent establishes.

---

## 2. Fixtures

Built once, before any row started. No row repaired its own precondition.

### F-base -- the pristine baseline

Command (`00-build-fbase.sh`): `mktemp -d`; copy `profiles/claude-code/.claude` in as the
installed bundle; copy four KB templates (`architecture`, `project-structure`,
`technology-stack`, `module-map`) plus an authored `README.md` Completeness table; a
`settings.yml` from the canonical template; `src/main.py`; a `.gitignore` carrying
`.claude/worktrees/` and the AID-managed block; then `git init -q -b master`, `git add -A`,
`git commit`.

```
--- ORACLE: F-base is a git work tree with a baseline commit ---
86e187b baseline: scratch AID project fixture
--- ORACLE: git status --porcelain in F-base (expect empty, exit 0) ---
[end-status rc=0]
--- ORACLE: .aid/design absent in F-base ---
ABSENT
--- ORACLE: no KB planning documents in F-base ---
README.md
architecture.md
module-map.md
project-structure.md
technology-stack.md
roadmap.md=absent
backlog.md=absent
```

### The run sequence and the two snapshots

| Fixture | How produced | Invariants verified at build time |
|---|---|---|
| `W` | `cp -a F-base` | inherits `.git`; `git status --porcelain` empty, rc=0 |
| `F-seeded` | `cp -a W` **immediately after run 1** | exactly one seed (`roadmap.md`); its `## Open questions` **NON-EMPTY**; no KB planning doc |
| `F-designed` | `cp -a W` **after run 3** | all three seeds + `README.md`; mvp seed's `## Open questions` **EMPTY**; roadmap seed's still non-empty; no KB planning doc |
| V6 row dir | **fresh** `cp -a F-seeded` | -- |
| V16 row dir | **fresh** `cp -a F-designed` | -- |

F-seeded's `## Open questions` state needed **no** fixture edit -- run 1 left it non-empty:

```
--- F-seeded invariant 2: roadmap seed's ## Open questions is NON-EMPTY per the detection rule ---
section body:
   |
   |- Does the "Now" horizon commit to a specific argument-parsing library, or only to the
   |  behavior (arguments accepted, non-zero exit on failure)?
   |
qualifying (non-blank, not None, not a lone {placeholder}) lines: 2
DETECTION RULE VERDICT: NON-EMPTY
```

F-designed's mvp seed **did** need the sanctioned fixture edit (run 2 left two questions), so
the section was cleared to the literal `None` **before** the V16 row began:

```
--- FIXTURE EDIT (sanctioned, pre-row): clear F-designed's mvp seed ## Open questions ---
state BEFORE the edit:
   |- Should "exits non-zero when it fails" be pinned to a specific exit code, ...
   |- What counts as the "minimal argument surface" the roadmap seed's Now horizon commits to? ...
cleared -> literal token None
--- F-designed invariant 3: mvp seed ## Open questions is EMPTY per the detection rule ---
section body:
   |
   |None
   |
qualifying lines: 0
DETECTION RULE VERDICT: EMPTY (ready)
--- F-designed invariant 4 (cross-check): roadmap seed's ## Open questions still non-empty ---
qualifying lines: 2 -> NON-EMPTY
```

---

## 3. The five invocations -- work folder and `phase:` record

Captured **before** any scratch project was torn down. This is the V23 evidence task-023
aggregates. All five allocate: allocation happens at INTAKE step 2, ahead of both the GUARD
refusal and the REALIZE routing exit.

Oracle per row: `grep -n '^phase:' <work>/STATE.md` (no match = the key is absent).

| # | Invocation | Kind | Allocated work folder | `phase:` in its `STATE.md` | Worktree also allocated |
|---|---|---|---|---|---|
| 1 | `/aid-design-roadmap` | authored run (realizing) | `W/.aid/works/work-001-design-roadmap` | **ABSENT** (no such key) | `W/.claude/worktrees/work-001-design-roadmap` |
| 2 | `/aid-design-mvp` | authored run (realizing) | `W/.aid/works/work-002-design-mvp` | **ABSENT** (no such key) | `W/.claude/worktrees/work-002-design-mvp` |
| 3 | `/aid-design-backlog` | authored run (realizing) | `W/.aid/works/work-003-design-backlog` | **ABSENT** (no such key) | `W/.claude/worktrees/work-003-design-backlog` |
| 4 | `/aid-create-roadmap` (V6) | **non-realizing** -- readiness refusal | `V6/.aid/works/work-002-create-roadmap` | **ABSENT** (no such key) | `V6/.claude/worktrees/work-002-create-roadmap` |
| 5 | `/aid-create-mvp` (V16 = E1) | **non-realizing** -- routing exit | `V16/.aid/works/work-004-create-mvp` | **ABSENT** (no such key) | `V16/.claude/worktrees/work-004-create-mvp` |

Work-id derivation, per gate step 3a.1 (max over the records `enumerate-works.sh` returned):

```
run 1  enumerate-works.sh rc=0, stdout:[]              -> empty => NEW, no prompt; work-001
run 2  work-001-design-roadmap  --  Completed  master  -> ASK; answered NEW; work-002
run 3  work-001..., work-002-design-mvp                -> ASK; answered NEW; work-003
V6     work-001-design-roadmap (inherited from F-seeded)   -> ASK; answered NEW; work-002
V16    work-001, work-002, work-003 (from F-designed)      -> ASK; answered NEW; work-004
```

`worktree-lifecycle.sh create` returned rc=0 with a non-empty path on all five; the
fail-closed guard never fired.

**Tally:** authored runs **3**, non-realizing invocations **2**, total invocations **5**.

---

## 4. Acceptance criteria -- oracle, observed output, verdict

### AC-1 -- every row run and recorded with the command that produced it

Rows in scope and where each is discharged below: **V4** (§4.2), **B3** (§4.3),
**V6** (§4.4), **V16 = feature-002 E1** (§4.5), **B2(b)** (§4.6). No other row is claimed.
Rows explicitly *not* this task's, per § Scope, are untouched here: V5 (task-015/021),
V18/V20 (task-020), V7/V8 (task-022), V17/V21-V24/V27 (task-023), feature-002 E2/G1/H1,
V26/V28. **PASS**

### AC-2 -- V4: `design` never touches the KB

Oracle, run after **each** of the three `design` runs:
`git status --porcelain .aid/knowledge/`

```
after run 1 (/aid-design-roadmap):   [end rc=0]     <- empty
after run 2 (/aid-design-mvp):       [end rc=0]     <- empty
after run 3 (/aid-design-backlog):   [end rc=0]     <- empty
```

Scoped to `.aid/knowledge/` alone, exactly as feature-003 §8 states it. The wider tree
correctly shows the two new paths a first `design` run is bound to create:

```
--- full git status --porcelain in W (after run 1) ---
?? .aid/design/
?? .aid/works/
```

**PASS**

### AC-3 -- V6 names the questions and the override

Covered in §4.4 below. **PASS**

### AC-4 -- every row runs against its assigned fixture; every mutating row gets a fresh `cp -a`

| Row | Fixture the § Scope table assigns | What it ran against | Fresh copy? |
|---|---|---|---|
| V4 | `W` itself | `W` | n/a (the sequence's own copy) |
| B3 | `W`, at run 1 | run 1 in `W` | n/a |
| V6 | fresh copy of F-seeded | `rm -rf V6; cp -a F-seeded V6` | yes |
| V16 | fresh copy of F-designed | `rm -rf V16; cp -a F-designed V16` | yes |

Each fixture's invariants were confirmed **at the moment its row began** (§4.4 and §4.5
"PRECONDITION" blocks). No row repaired its own precondition; the only edit was the
pre-row fixture edit in §2. **PASS**

### AC-5 -- F-base is a git work tree before run 1

```
86e187b baseline: scratch AID project fixture
git status --porcelain -> [end-status rc=0]
```

and `W`, inheriting `.git` from the copy:

```
--- ORACLE: W inherits .git (copy of a git work tree); status is a real result ---
[end-status rc=0]
86e187b baseline: scratch AID project fixture
```

Every empty `git status --porcelain` reported in this file is therefore a real result at
exit 0, not an exit-128 misread. **PASS**

### AC-6 -- V16 (= feature-002 E1)

Covered in §4.5. **PASS**

### AC-7 -- B2(b)

Covered in §4.6. **PASS**

### AC-8 -- B3

Covered in §4.3. **PASS**

### AC-9 -- all five invocations recorded before teardown

Covered in §3, captured before teardown (§5). **PASS**

### AC-10 -- V6 refuses, V16 routes, each recorded non-realizing

Covered in §4.4 and §4.5. The evidence is what the contract scopes to the realizing path --
destination unwritten, seed still present, no verify loop. **No assertion is made against the
presence or absence of an allocated `work-NNN` folder**; §3 records that all five allocate.
**PASS**

### AC-11 -- determinism and teardown; the two counts

Covered in §4.7 and §5. **PASS**

### AC-12 -- both `## Open questions` fixture states established before their rows

Covered in §2, by inspecting each seed at fixture-build time. **PASS**

### AC-13 -- this task mutates no shared tree

Covered in §6. **PASS**

### AC-14 -- `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`

Covered in §6. **PASS**

---

### 4.2 V4 -- see AC-2 above

### 4.3 B3 -- first run creates `.aid/design/` and seeds its `README.md`

Asserted on **run 1 in `W`**, a project with no `.aid/design/` before that run (F-base
invariant, §2), not on a run of its own.

```
--- INTAKE 3: acquire .aid/design/ per design-lifecycle.md 'Before writing a seed' ---
.aid/design absent -> creating
copied installed template -> .aid/design/README.md
```

Oracle: `cmp .aid/design/README.md .claude/aid/templates/design-folder-readme.md`

```
--- ORACLE B3: .aid/design/README.md vs installed template (cmp) ---
cmp rc=0
```

rc=0 is byte-identity against the **installed** template (the rendered `.claude/` bundle
inside the scratch project), not the canonical source. Re-confirmed at determinism replay
(§4.7). Runs 2 and 3 correctly left it alone (*"README.md already present -> left
untouched"*). **PASS**

### 4.4 V6 -- the readiness gate

Fixture: a fresh `cp -a` of F-seeded.

```
--- PRECONDITION: fixture invariants at the moment the row begins ---
seeds present: README.md  roadmap.md
destination .aid/knowledge/roadmap.md: absent
seed ## Open questions, by the detection rule:
  qualifying lines: 2 -> NON-EMPTY
  QUESTION-LINE: - Does the "Now" horizon commit to a specific argument-parsing library, or only to the
  QUESTION-LINE: behavior (arguments accepted, non-zero exit on failure)?
```

INTAKE allocated (§3), then GUARD refused. Refusal transcript (verbatim, abridged to the two
clauses the row turns on):

```
REFUSED. `.aid/design/roadmap.md` is not ready to be consumed: its `## Open questions`
section is non-empty by the detection rule ...

Unresolved question(s) blocking realization:
  1. Does the "Now" horizon commit to a specific argument-parsing library, or only to the
     behavior (arguments accepted, non-zero exit on failure)?

To bypass this gate you must supply the override explicitly on the invocation:

    /aid-create-roadmap --override-open-questions "<direction>"
...
lifecycle: Paused-Awaiting-Input
```

Oracles and observed output:

| # | Oracle | Observed | Verdict |
|---|---|---|---|
| a | `test -e .aid/knowledge/roadmap.md` | `absent` | PASS |
| b | `diff` of `sha256sum` over all of `.aid/knowledge/`, before vs after | `diff rc=0 -- IDENTICAL` | PASS |
| c | `sha256sum -c` over the seed, `.aid/design/README.md`, `.aid/settings.yml` | `.aid/design/roadmap.md: OK` / `README.md: OK` / `settings.yml: OK`, `rc=0`; seed still listed by `ls -1 .aid/design` | PASS |
| d | no verify loop: `test -e .aid/.temp/review-pending/work-002-create-roadmap-verify.md` | `absent -- PASS` (the only ledger present is run 1's, inherited via the snapshot); `grade.sh` never invoked | PASS |
| e | `grep -qF 'argument-parsing library'` / `grep -qiE 'override'` over the transcript | `names the question text: YES` / `names an override: YES` | PASS |
| f | `git status --porcelain .aid/settings.yml .aid/knowledge/` | `[end rc=0]` -- empty | PASS |

A refusal that wrote nothing but named neither would fail this row; this one names both.
**PASS**

### 4.5 V16 (= feature-002 E1) -- the routing exit

Fixture: a fresh `cp -a` of F-designed.

```
--- PRECONDITION: fixture invariants at the moment the row begins ---
seeds present: README.md  backlog.md  mvp.md  roadmap.md
destination .aid/knowledge/roadmap.md: absent
mvp seed ## Open questions, by the detection rule (must be EMPTY so the ROUTE, not the gate, fires):
  qualifying lines: 0 -> EMPTY (ready)
```

That last line is what makes the row test **routing** rather than the readiness gate: the
GUARD advanced, and REALIZE routed on the destination's absence.

Routing transcript (verbatim, abridged):

```
ROUTED. `.aid/knowledge/roadmap.md` does not exist, and an MVP is a section of a roadmap, not
a document of its own (REQUIREMENTS CC-5; feature-002 first-write rule). ...

Run this next:

    /aid-create-roadmap
...
lifecycle: Paused-Awaiting-Input
```

Oracles and observed output:

| # | Oracle | Observed | Verdict |
|---|---|---|---|
| a | `grep -qF '/aid-create-roadmap'` over the transcript | `names /aid-create-roadmap: YES` | PASS |
| b | `test -e .aid/knowledge/roadmap.md` | `absent -- PASS` | PASS |
| c | `grep -rn '^## MVP' .aid/knowledge/` -- did not scaffold a document it does not own (CC-5) | `grep rc=1 (1 = no match)` | PASS |
| d | `ls -1 .aid/design` + `test -e .aid/design/mvp.md` | `mvp.md present -- PASS` | PASS |
| e | `diff` of `sha256sum` over `.aid/knowledge/`, before vs after | `diff rc=0 -- IDENTICAL` | PASS |
| f | `sha256sum -c` over all three seeds + `.aid/settings.yml` | all `OK`, `rc=0` | PASS |
| g | no verify loop: ledger for `work-004-create-mvp` | `no ledger for this work -- PASS` | PASS |
| h | did not stop silently: transcript line count | `20` lines, naming the next act | PASS |
| j | `git status --porcelain .aid/settings.yml .aid/knowledge/` | `[end rc=0]` -- empty | PASS |

**PASS**

### 4.6 B2(b) -- the acquisition rule survives the render, per profile

Oracle, for each profile root `R`, over `profiles/<profile>/<R>/aid/templates/design-lifecycle.md`:
`grep -cF "R/aid/templates/design-folder-readme.md"` must be >= 1 and
`grep -cF 'canonical/aid/templates/design-folder-readme.md'` must be 0.

| Profile | Root `R` | `grep -cF "<R>/…"` | `grep -cF "canonical/…"` | Hit | Verdict |
|---|---|---|---|---|---|
| claude-code | `.claude` | 1 | 0 | `:24` | PASS |
| codex | `.codex` | 1 | 0 | `:24` | PASS |
| cursor | `.cursor` | 1 | 0 | `:24` | PASS |
| copilot-cli | `.github` | 1 | 0 | `:24` | PASS |
| antigravity | `.agent` | 1 | 0 | `:24` | PASS |

Sample hit line (claude-code):

```
24:> copy `.claude/aid/templates/design-folder-readme.md` into it as `README.md`. Never
```

The locative qualifier is load-bearing, and the run confirms why -- the bare root names do
not all resolve at the repository root:

```
  .claude -> exists at repo root
  .codex  -> does NOT exist at repo root
  .cursor -> exists at repo root
  .github -> exists at repo root      (the GitHub config directory, not a profile root)
  .agent  -> does NOT exist at repo root
```

Part (a) -- the five rendered copies -- is task-024's and is not re-asserted here.
**B2(b) overall: PASS**

### 4.7 Determinism

**Method -- re-evaluation, never re-invocation (same rule task-023 §9 states).** The V6 and
V16 outcomes are pure functions of a fixed input: the detection-rule verdict is a pure
function of the seed's `## Open questions` section (`design-lifecycle.md § Detection rule`),
and the GUARD/REALIZE decision plus post-state follow deterministically from it. Determinism
is therefore demonstrated by **re-evaluating those oracles twice over the recorded post-run
states on `cp -a` copies of them -- the skills are NOT re-invoked.** This is deliberate, not a
convenience: re-invoking a non-realizing skill would add invocations to a count that is itself
an acceptance criterion (AC-11's cap of two non-realizing invocations, V6 + V16), so the
replay must not run the skill. The two non-realizing invocations recorded elsewhere in this
document remain the only two; this section adds none.

Command form (per pass, over the recorded copy `$C`):

```
detect="$(bash detect-open-questions.sh "$C/.aid/design/<seed>.md")"   # detection-rule verdict
decision="$(classify_guard_realize "$detect")"                          # GUARD vs REALIZE
sha256sum "$C"/.aid/knowledge/* "$C/.aid/design/<seed>.md"              # post-state fingerprint
# pass A and pass B each emit {detect, decision, fingerprints}; diff the two:
--- V6: pass A vs pass B ---   diff rc=0 -- IDENTICAL OUTCOMES
--- V16: pass A vs pass B ---  diff rc=0 -- IDENTICAL OUTCOMES
```

The authored-run oracles are pure file-state checks and were likewise re-evaluated (not
re-run) twice over `W`:

```
pass 1:  V4 -> []   B3 cmp rc=0
pass 2:  V4 -> []   B3 cmp rc=0
```

**PASS**

---

## 5. Verify loops, grades, and teardown

Full verify ran on each of the three authored runs and on **neither** non-realizing
invocation. Ledgers at `.aid/.temp/review-pending/<work>-verify.md`, graded with the
installed `grade.sh --explain`.

| Run | Cycle 1 | Cycle 2 | Cycle 3 | Final |
|---|---|---|---|---|
| 1 `/aid-design-roadmap` | `B` (2 x [LOW]) | [HIGH] + [MEDIUM] Pending | all Fixed | **A+** |
| 2 `/aid-design-mvp` | `B+` (1 x [LOW]) | 1 x [LOW] Pending | all Fixed | **A+** |
| 3 `/aid-design-backlog` | no findings | -- | -- | **A+** |

The circuit breaker (3 cycles) was approached but not tripped; no IMPEDIMENT was raised.

Teardown: the entire scratch root -- F-base, `W`, both snapshots, both row copies, the two
determinism copies, and every worktree nested inside them -- was removed on completion. See
§6 for the post-teardown tree assertions.

---

## 6. This task mutated no shared tree

All five invocations ran inside scratch projects under the `mktemp -d` root. No path under
`.aid/knowledge/`, `.aid/design/` or `.aid/settings.yml` in this working tree was written,
and neither `profiles/`, `.claude/` nor `.cursor/` was rendered or reverted.

| Oracle | Observed | Verdict |
|---|---|---|
| `git status --porcelain -- .aid/knowledge/ .aid/design/ .aid/settings.yml profiles/ .claude/ .cursor/` | `113` entries -- exactly what task-024's render left, before and after | PASS |
| `git status --porcelain` (whole tree) | `113` -- every dirty entry is inside the six scoped paths; nothing else moved | PASS |
| `git status --porcelain -- .aid/.temp/` | `0` -- the throwaway drivers are gitignored and invisible to git | PASS |
| `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` | `rc=0` -- clean | PASS |
| `git status --porcelain -- .aid/works/` | empty before this task's own commit | PASS |

---

## 7. Observations (recorded, not blocking)

1. **The override flag has no literal token anywhere.** `aid-create-roadmap/SKILL.md:63-64`
   requires the refusal to name *"the override flag the user must supply"*, but neither that
   body, nor `design-lifecycle.md`'s readiness-gate section, nor feature-003 §8 V6 fixes what
   that flag **is**. The V6 run therefore named one (`--override-open-questions`). V6's own
   criterion is satisfied either way -- it requires the transcript to name the unresolved
   question(s) **and** the override, and it does -- so this is under-specification, not a
   contradiction. Recorded here so a later run does not silently invent a different token.
2. **`W5-20` was observed live, five times over.** Every invocation, refusal and routing exit
   included, left a `work-NNN` folder **and** a registered git worktree that nothing cleans
   up. Already filed at P3 in `.aid/knowledge/backlog.md`; nothing new is raised here.
