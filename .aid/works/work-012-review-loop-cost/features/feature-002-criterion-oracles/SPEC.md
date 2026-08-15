# Criterion Oracles

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-15 | Feature identified from REQUIREMENTS.md §5 FR-8–FR-13, §9 AC-5–AC-8 and AC-11, §6 NFR-1 | /aid-define |
| 2026-08-15 | **FR-9 and FR-11 given explicit criteria.** A coverage sweep found both carried only by the range "FR-8 to FR-13" in `## Source` and demanded by nothing — FR-11's ledger mapping had no criterion anywhere in the work. This is the `tech-debt.md` W5-10 class (an obligation no artifact owns), caught here rather than by an executor mid-build | /aid-define |
| 2026-08-15 | **AC-14, AC-15 and AC-16 adopted** (for FR-9, FR-10, FR-11), promoted to numbered criteria in REQUIREMENTS.md §9 after cross-reference cycle 1. `## Source` updated to list them — cycle 2 found them present in the criteria list but absent from Source, where a per-feature specify reviewer looks to see what is in scope | /aid-define |
| 2026-08-15 | Technical Specification authored: the `oracle:` key, the exit contract, `G-07`'s oracle and the sibling-copy argument, and the NFR-1 accounting | /aid-specify |
| 2026-08-15 | **Specify gate cycle 1 (C+) — coverage made per-file.** The draft's exit contract was whole-criterion, so a single undecidable file made the oracle indeterminate overall; since `template-payload` files are always present, `G-07`'s oracle would always degrade, replace nothing, and be forbidden by AC-11. An oracle now reports `VIOLATION`/`UNDECIDED` **per file**, the reviewer reads only the undecided remainder, and the decided-vs-undecided count becomes AC-11's evidence. Also: the selector grammar specified so the C-5 request is evaluable, a 60s timeout added for non-termination, exit-1-with-no-violation defined as malformed, the `scripts/checks/` directory named as a deliverable, and the grep claim corrected | /aid-specify |
| 2026-08-15 | **Specify gate cycle 2 (C+) — a third grammar clause, and an invented threshold withdrawn.** The `path`/`fm` grammar could not express `skill-generated`'s catalog lookup, which would have left ~75 `SKILL.md` files undecided and made the C-5 request materially incomplete. Added `name-in`, which decides them; `skill-authored` needs no negation, because first-match-wins already handles it exactly as the registry itself notes. `template-payload` is now the only inexpressible row. Also: the `Match`/`Selector` drift hazard named, with an editing rule and a diff-based detector rather than a second oracle guarding the first; `UNDECIDED` at exit 1 disambiguated; and the arbitrary "majority-undecided is not shipped" rule withdrawn in favour of AC-11's own test | /aid-specify |
| 2026-08-15 | **Specify gate cycle 3 (D+) — the no-`Match`-cell algorithm was never specified, and the coverage claim was wrong.** Cycle 2's "`template-payload` is the only inexpressible row" did not survive contact with `template-own`, the catch-all over the *same* path space: reaching it means walking past a row with no `Match` cell, and the two natural implementations disagree — *stop* leaves all 73 template files undecided, *skip* silently reports payload templates as `template-own` and the reviewer never reads them. The stop rule is now specified, both template rows are declared inexpressible, and the coverage figure is measured rather than asserted: **203 of 276 decided, 74%.** A content-pattern clause that would rescue the remainder is explicitly refused | /aid-specify |
| 2026-08-15 | **Specify gate cycle 4 (C+) — the stop rule given a path bound, and an off-by-one corrected.** The unbounded stop rule would have caught a genuine orphan outside `canonical/aid/templates/` and reported it `UNDECIDED` — softening the exact finding `G-07` exists to make. An inexpressible row now declares its expressible path half (`path canonical/aid/templates/** AND <inexpressible>`), so the stop fires only inside that bound and a true orphan anywhere else still reports `VIOLATION`. Also: the C-5 statement said "nine rows gain a `Match` cell" against a registry of ten; the correct split is eight expressible, two not | /aid-specify |
| 2026-08-15 | **Specify gate cycle 5 (B+) — two editorial gaps in the grammar section.** The prose still said "two clause kinds" after `name-in` made it three, and `<inexpressible>` was used in a worked example without being defined where an implementor would look for it. It is now declared as a reserved token that is not a clause: never a match, never a non-match, but the boundary that triggers the stop rule | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-8 to FR-13 (the `oracle:` key, its runner, and the worked example)
- REQUIREMENTS.md §6 NFR-1 (the exit criterion this feature is measured against),
  NFR-2 (bash + awk on the core path), NFR-3 (determinism)
- REQUIREMENTS.md §9 AC-5, AC-6, AC-7, AC-8, AC-11, AC-14, AC-15, AC-16
- REQUIREMENTS.md §8 (a criterion entry tolerates unknown keys, so this is an addition
  rather than a migration)
- STATE.yml Q-01 (what justifies an oracle), Q-02 (where one lives), Q-04 (when one is written)

## Description

Today every criterion is re-decided by a reviewer reading it, on every cycle, forever. For
a genuinely semantic criterion that is unavoidable. For a mechanically decidable one it is
both waste and a reliability problem — the same criterion gets re-derived by hand each
cycle, expensively, and not always to the same answer.

This feature adds **one optional key** to a `review-criteria:` entry, naming an executable
check. A criterion carrying one is decided by *running* it: cheap, deterministic, and
identical every cycle. A criterion without one behaves exactly as it does today.

Three properties make it safe to add:

- **Absence is never a defect.** Most criteria will never carry the key, and that is the
  correct outcome, not an omission to be fixed.
- **Failure degrades rather than lies.** An oracle that is missing, not executable, or that
  crashes falls back to the existing read-based judgment and reports that it did. It never
  silently passes and never silently fails the criterion.
- **It is a pure addition.** A criterion entry already tolerates unknown keys, so no
  criterion already declared has to change.

`G-07` is the worked example, and deliberately so: it is the criterion whose evaluation
needs the whole corpus, which makes it the worst case for feature-003's scoping — and
therefore the best demonstration that an oracle removes the problem rather than dodging it.

**This feature is where NFR-1 bites.** Every oracle is a script, so this is the executable
surface the work adds by design. The exit criterion is not "add nothing" but "replace
something recurring, and measure the trade" — which is why AC-11 is an acceptance criterion
of this feature and not a footnote.

## User Stories

- As a reviewer, I want a mechanically decidable criterion answered by running a check, so
  that my cycles go to judgment instead of to re-deriving the same answer.
- As the repo owner, I want each oracle to name the recurring work it removes, so that
  added machinery is a trade I can audit rather than one I have to trust.
- As an author declaring a criterion, I want to declare it without owning a script, so that
  the absence of an oracle never blocks me.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-5** Given a criterion with no `oracle:` key, when it is reviewed, then it
      produces no finding and grades exactly as it does today. Absence is not a defect.
- [ ] **AC-6** Given a corpus where every in-scope markdown file resolves to exactly one
      registry type, when `G-07`'s oracle runs, then it exits 0; and given a corpus
      containing an untyped or double-typed file, then it exits non-zero and names the
      offending file.
- [ ] **AC-7** Given an unchanged tree, when `G-07`'s oracle runs twice, then its output is
      byte-identical (NFR-3).
- [ ] **AC-8** Given a criterion whose oracle is missing or not executable, when it is
      reviewed, then the criterion is judged by reading and the degradation is reported in
      the ledger (FR-12).
- [ ] **AC-11** Given each oracle shipped, when the work closes, then that oracle names the
      recurring re-derivation it replaces and the measured per-cycle cost of it, and the
      work reports the net trade. An oracle with no recorded replacement is not shipped.
- [ ] **AC-14 (FR-9)** Given a criterion that carries an oracle, when it is decided, then
      the recorded verdict traces to the oracle's exit status rather than to a reviewer
      re-reading the criterion — that re-reading is the waste this feature removes.
- [ ] **AC-15 (FR-10)** Given a criterion a reviewer has re-derived only once, when
      authoring is considered, then no oracle exists for it yet: the SECOND re-derivation is
      the trigger (Q-04). `G-07` is the recorded exception — its recurrence predates the
      rule (FR-13).
- [ ] **AC-16 (FR-11)** Given an oracle verdict, when it is recorded, then it lands in the
      existing 7-column ledger with the criterion `id` as a `Description` prefix and the
      oracle's invocation and output in `Evidence` — no new column, and no change to the
      shape `grade.sh` parses (C-3).
- [ ] Given an `oracle:` value, when it is resolved, then it resolves from the repository
      root and the oracle lives outside `canonical/` — so no oracle enters the render chain
      (Q-02, NFR-5).

---

## Technical Specification

### What exists today, and what that means for the design

Criteria resolution has **no script.** `review-rubric.md § Resolving review criteria`
defines a four-step resolution — type, global, type-level, file-level — performed by the
**reviewer agent reading prose**. A grep for `review-criteria` across `canonical/` and
`.claude/aid/scripts/` returns documents, two index builders, and one migration script
(`migrate/migrate-kb-frontmatter.sh`, which renames the field from its legacy `contracts:`
name). Every hit either *describes* the field or *rewrites* it. **Nothing resolves criteria
for a review**, which is the claim this design rests on.

That single fact settles most of this feature's shape:

- **No resolver, no runner framework, no registry of oracles is needed.** The reviewer
  already reads each criterion during resolution. If a criterion carries an `oracle:`, the
  reviewer runs it. The mechanism is one added step in an activity that already happens.
- **The executable surface this feature adds is therefore the oracle scripts and nothing
  else.** That is what makes NFR-1 answerable per-oracle instead of amortised across a
  framework — see *NFR-1 accounting* below.

### Data Model

**1. The `oracle:` key.**

One optional key on a `review-criteria:` entry, alongside `id`, `kind`, `criterion`,
`severity`, `why`:

```yaml
review-criteria:
  - id: G-07
    kind: validate
    criterion: "Every in-scope markdown file resolves to exactly one type in the registry."
    severity: HIGH
    why: "A file matching two rows or none has no resolvable criteria set."
    oracle: scripts/checks/g07-selector-partition.sh
```

| Property | Value |
|---|---|
| Required? | **No.** Absence is never a defect and never a finding (AC-5). |
| Value | A path resolved from the repository root, outside `canonical/` (Q-02). |
| Applies to | A `validate` criterion. A `kind: exclude` criterion names something a reviewer must *not* check, so it has nothing to run. |
| Where declared | At any of the three levels, following the existing cascade unchanged (C-4). |

Adding it is a pure addition: `frontmatter-schema.md § Parsing rules` states that an unknown
key on a `review-criteria:` entry is tolerated, "so a later key can be added to a criterion
as a pure addition rather than a migration across every criterion already declared." That
is the rule's own stated purpose, and this is the case it was written for.

**2. The oracle's contract.** A criterion's oracle is an executable with a fixed, tiny
interface, so the reviewer needs no per-oracle knowledge:

**Coverage is per-file, not per-criterion.** This is the single most important line in the
contract. An oracle reports a verdict *for each file it examined* and, separately, the files
it could not decide. It does **not** collapse the whole criterion to one word. Without this,
any corpus containing even one undecidable file would make the oracle indeterminate overall,
it would replace no re-derivation, and AC-11 would forbid shipping it — which for `G-07` is
not hypothetical, since `template-payload` files are always present in this repository.

| Aspect | Contract |
|---|---|
| Invocation | `<oracle>` with no required arguments, run from the repository root. |
| `stdout` | One line per file the oracle has something to say about: `VIOLATION <path> <reason>` or `UNDECIDED <path> <reason>`. Files that pass produce no line. Sorted, so the output is diffable. |
| Exit `0` | **No violations among the files the oracle decided.** `UNDECIDED` lines may still be present, and their existence is not a failure. |
| Exit `1` | **At least one `VIOLATION` line.** The criterion is violated for those files. `UNDECIDED` lines may appear alongside them and are handled exactly as at exit 0 — a violation somewhere in the corpus does not make the undecided remainder any more or less decided. |
| Exit `2` | **The oracle could not run at all** — its own inputs are missing or malformed, so it decided nothing. This is whole-criterion degradation, and it is the rare case, not the normal one. |
| Any other exit | Treated as exit 2. "I could not tell" is never recorded as "the criterion holds". |
| Exit `1` with no `VIOLATION` line | **Malformed oracle.** Treated as exit 2 and reported as a degradation, never as a finding: a violation nobody can cite is not usable evidence, and inventing one would put an uncitable row in the ledger. |
| Runtime bound | The reviewer invokes every oracle under a **60-second timeout**. Exceeding it is treated as exit 2 and reported. FR-12 names missing, non-executable and crashing oracles; non-termination is the fourth way to fail and is bounded here rather than left to the determinism constraints, which prevent *variability* but not a traversal bug. |
| Determinism | Same tree in, same stdout and exit out (NFR-3). No network, no clock, no `$RANDOM`, no unordered traversal — enumeration sorted under a fixed locale (`LC_ALL=C`). |
| Language | Bash + awk (NFR-2). |

**How a partial verdict is consumed.** The reviewer takes the oracle's decided files as
settled and judges **only the `UNDECIDED` remainder** by reading. That is what makes a
partial oracle worth shipping: the replacement it provides is proportional to the files it
decides, and it is measurable — the count of decided files versus undecided is on stdout,
so AC-11's "what re-derivation does this replace" has a number rather than a claim behind
it.

### G-07's oracle, and the one hard problem in this feature

`G-07` — *every in-scope markdown file resolves to exactly one type in the registry* — is
the worked example because L5 picked the hardest case on purpose: it needs the whole corpus,
which is the worst case for feature-003's scoping.

Its difficulty is not enumeration. It is that **the registry's selectors are prose.** The
type registry in `authoring-conventions.md` describes each type in a `Selector` column
written for a human: *"any `STATE.md`, at any depth in any folder"*, *"a `.md` under
`.aid/knowledge/` with `source: generated`"*, and hardest of all `template-payload`'s three
alternative recognizers (placeholder tokens; an unquoted choice-list in a value position; an
opening key drawn from the emitted artifact's schema).

**The trap, named so it is not walked into.** The obvious implementation hardcodes the
selectors in bash. That produces a *sibling copy* of the registry that can drift from it
silently — a guard and a document asserting the same thing independently. This is exactly
the failure `tech-debt.md § L4` calls out in its invariant-anchoring measure ("anchor to
ground truth, not a sibling copy"), the mechanism behind the `io_bounds.py` escape, and the
shape of the guard `work-004` deliberately retired. An oracle that can disagree with the
criterion it enforces is worse than no oracle, because it is trusted.

**The design, therefore: one source, parsed.** The registry table stays the single source of
truth, and each row's selector gains a machine-readable form the oracle parses. The oracle
enumerates the in-scope corpus, applies the selectors **in table order, first match wins**
(the registry's own stated rule), and reports as a `VIOLATION` any file that matches zero
rows — subject to the inexpressible-row bound defined below, which is the one case where a
file is reported `UNDECIDED` instead.

**The shape of that form, stated here so the C-5 request is evaluable.** An owner cannot
authorize "a machine-readable form"; they can authorize a specific one. The proposal is a
deliberately small grammar — three clause kinds, joined by `AND`, one line per registry row,
carried in a new `Match` column beside the existing prose `Selector` (which stays, because
the prose is what a human reads):

| Clause | Form | Meaning |
|---|---|---|
| Path | `path <glob>` | the file's repo-relative path matches the glob |
| Frontmatter | `fm <key> == <value>` | the file's frontmatter has that key with that scalar value |
| Membership | `name-in <file>` | the file's **parent directory name** appears as a `name:` value in `<file>` |

One reserved token, which is **not** a clause and is never evaluated:

| Token | Meaning |
|---|---|
| `<inexpressible>` | This row's selector cannot be fully expressed in the grammar. The oracle parses the row's other clauses to get its **path bound**, then stops for any file inside that bound and reports it `UNDECIDED`. A row carrying it is never a match and never a non-match — it is a boundary. |

```
state            path **/STATE.md
kb-generated     path .aid/knowledge/*.md AND fm source == generated
kb-meta          path .aid/knowledge/*.md AND fm kb-category == meta
kb-doc           path .aid/knowledge/*.md
skill-generated  path canonical/skills/*/SKILL.md AND name-in canonical/aid/templates/shortcut-catalog.yml
skill-authored   path canonical/skills/*/SKILL.md
agent            path canonical/agents/*/AGENT.md
```

**Ordering does the work that negation would otherwise do.** `skill-authored`'s prose
selector is *"whose `<name>` is **not** a row in `shortcut-catalog.yml`"*, and the grammar
has no negation. It does not need one: `skill-generated` precedes `skill-authored` in the
registry, and resolution is first-match-wins, so `skill-authored` is simply the remaining
`SKILL.md` files. The registry already says this is deliberate — *"Ordering is what makes
the selectors mutually exclusive in practice rather than by careful wording."* The grammar
inherits that property instead of re-implementing it.

**The third clause exists because omitting it was expensive.** An earlier draft had only
`path` and `fm`, which left every `canonical/skills/*/SKILL.md` undecidable — roughly 75
files, the single largest block in the corpus. `name-in` is one bounded lookup against a
file the registry already cites by name, and it moves those 75 from undecided to decided.
The grammar is kept small, but not smaller than the corpus requires.

Three properties make this the right size:

- **It cannot express a selector it should not.** No regex, no negation, no disjunction, no
  arithmetic. A row needing more is a row the oracle leaves `UNDECIDED`.
- **A human can check a row against its prose neighbour by eye.** `Match` and `Selector` sit
  side by side.

**The residual hazard, named rather than waved at.** Making the oracle parse `Match`
eliminates the original sibling copy — the oracle can no longer disagree with the registry,
because it reads it. It creates a smaller one in its place: `Match` and `Selector` state the
same selector in two notations, so an edit to the prose that forgets the `Match` cell leaves
the oracle silently classifying by the old rule. That is a real cost of this design and it
is not fully eliminated. Two things bound it:

1. **A stated editing rule:** `Selector` and `Match` are one unit. Changing either without
   the other is a defect, and this is written into the registry section itself, not left as
   folklore.
2. **A cheap detector that needs no new mechanism:** the oracle prints its full
   classification, so re-running it across a registry edit and diffing the output shows
   exactly which files changed type. An intended edit produces an expected diff; a forgotten
   `Match` cell produces none where one was expected, and a mistyped one produces a
   surprising diff. The classification output *is* the regression test.

This is deliberately not solved with a second oracle checking the first. FR-10's lazy rule
forbids authoring one before the re-derivation has recurred, and a guard whose only job is
guarding a guard is the accumulation NFR-1 exists to prevent.
- **`template-payload` is expected NOT to fit, and that is the design working.** Its three
  recognizers test frontmatter *shape* — placeholder tokens, an unquoted choice-list in a
  value position, an opening key from the emitted artifact's schema — which no `key ==
  value` clause can express. It carries no `Match` cell.

**A row whose selector is inexpressible still declares its PATH BOUND, and stops the walk
only inside it.** A row with no discriminator is not a row with no information:
`template-payload`'s selector is *"a file under `canonical/aid/templates/` whose frontmatter
belongs to the artifact the template emits"*. The path half is expressible; only the
frontmatter-shape half is not. So the cell carries the bound and marks the rest
inexpressible:

```
template-payload   path canonical/aid/templates/** AND <inexpressible>
template-own       path canonical/aid/templates/**
```

**Why the bound matters, and it is not a detail.** Without it, "stop at a row with no
`Match`" fires for *any* file that exhausts the expressible rows — including a genuine
orphan sitting outside `canonical/aid/templates/` entirely. That file would be reported
`UNDECIDED` when it is in fact a `VIOLATION`: a file matching zero rows is exactly the
defect `G-07` exists to catch, and reporting it as merely undecided would soften the one
finding the oracle most needs to make. With the bound, the stop applies only within
`canonical/aid/templates/`, and an orphan anywhere else still reports `VIOLATION`.

**Inside that bound, the walk stops.** This rule has to be stated, because the two natural
implementations disagree and one of them is silently wrong:

- *Stop* — the file is reported `UNDECIDED`. Correct: within the bound, the oracle cannot
  tell whether the file belongs to this row or to a later one, and a guess either way is
  unfounded.
- *Skip and continue* — **wrong, and dangerously so.** The file falls through to a later
  row and is reported as classified. For `template-payload` that means every payload
  template is silently reported as `template-own`, no `UNDECIDED` line is emitted, and the
  reviewer never reads the files the oracle could not actually decide. A wrong answer
  delivered confidently is worse than the manual reading it replaced.

**The full inexpressible set, stated so the C-5 request is complete — and it is larger than
one row.** `template-payload` carries no `Match` cell, and `template-own` is the catch-all
for the *same path space* (`canonical/aid/templates/`), reachable only by walking past
`template-payload`. Under the stop rule, **no file under `canonical/aid/templates/` is
decided at all.** Both rows are inexpressible, and `template-own` is inexpressible as a
consequence of its neighbour rather than of anything about itself.

Measured over the current corpus (`LC_ALL=C find … -name '*.md'`):

| Region | Files | Oracle |
|---|---|---|
| `canonical/skills/` | 173 | decided |
| `.aid/knowledge/` | 21 | decided |
| `canonical/agents/` | 9 | decided |
| `canonical/aid/templates/` | 73 | **UNDECIDED** |
| **Total in scope** | **276** | **74% decided, 26% undecided** |

That is the honest scope of the C-5 request. The registry has **ten** type rows: **eight
gain a `Match` cell** (`state`, `kb-generated`, `kb-meta`, `kb-doc`, `skill-generated`,
`skill-authored`, `skill-reference`, `agent`) and **two do not** (`template-payload`,
`template-own`). Roughly a quarter of the corpus still gets read by a human. Whether 74% is
worth the oracle is AC-11's question, answered with this number rather than around it.

**Deliberately not rescued.** `template-payload` could be made expressible by adding a
content-pattern clause, and that is refused. Its recognizers are three alternatives, any one
sufficient, one of which ("an opening key drawn from the emitted artifact's own schema")
requires knowing another artifact's schema. Expressing that needs regex or structural
frontmatter analysis — a qualitatively different grammar, and the beginning of growing it
until everything fits. 74% decided at a two-and-a-half-clause grammar is a better trade than
100% decided at a grammar nobody can check by eye.

Two consequences to be explicit about:

- **This edits `.aid/knowledge/authoring-conventions.md`.** That is expected — it is one of
  the four edit sites L5 names — but `C-5` reserves KB edits for **explicit owner
  authorization**, so this is a gate for `/aid-execute`, not something a task may assume.
- **It must not change what any selector *means*.** Formalising a selector is a
  representation change; if a row's meaning shifts, the registry has been edited under cover
  of a mechanical task, and `§4` puts the criteria cascade out of scope. The acceptance test
  is that the oracle's classification of the current corpus is identical before and after.

**Where an honest fallback is required.** `template-payload`'s three recognizers cannot be
expressed without changing their meaning, so the oracle must **not** approximate them. It
emits `UNDECIDED <path>` for each file under `canonical/aid/templates/` — 73 files, both
template rows — and exits 0 if nothing else is violated. That is a **per-file** boundary,
not a whole-criterion surrender: the other 203 in-scope files are still decided. G-07 keeps
being judged by reading for exactly the undecided ones and no others. An oracle that guessed
instead would be the sibling-copy failure again, wearing a different hat.

**And this is where the oracle earns its place, or does not.** An oracle that decides almost
nothing has replaced almost nothing, and AC-11 forbids shipping it. The test is
AC-11's own and no other: *does it replace recurring human re-derivation, measured rather
than asserted?* The measurement is the decided-versus-undecided count over the real corpus,
produced by running it, fed to feature-001's meter as the per-cycle cost removed.

**No percentage threshold is invented here.** An earlier draft added "a majority-undecided
oracle is not shipped", which is arbitrary in two ways: it makes file count the proxy for
re-derivation cost, when the undecided files may be the cheap ones or the expensive ones,
and it draws a line at 50% that nothing justifies — 51% decided is not meaningfully
different from 49%. AC-11 asks whether the trade is favourable and requires a number
supporting the answer; it does not ask for a ratio to clear. The count is the input to that
judgment, not a rule that pre-empts it.

### Feature Flow

```
Reviewer resolves criteria for a file (existing 4-step cascade, unchanged)
  └─ for each resolved `validate` criterion:
       ├─ no `oracle:` key      → judge by reading, exactly as today   (AC-5)
       └─ `oracle:` present     → run it from the repository root, 60s timeout
              ├─ exit 0         → no violation among the files it decided
              ├─ exit 1         → one finding per VIOLATION line: severity from
              │                   the criterion, Description prefixed with the
              │                   criterion id, Evidence = the invocation and
              │                   that line                                (AC-16)
              ├─ exit 2, timeout, missing, not executable, or exit 1 with no
              │   VIOLATION line
              │                 → DEGRADE the WHOLE criterion: judge by reading,
              │                   and record that the degradation happened  (AC-8)
              └─ in every non-degraded case, any UNDECIDED lines
                                → judge THOSE FILES ONLY by reading; the decided
                                  files are settled. Partial coverage is normal,
                                  not a degradation.
```

The ledger shape is untouched: 7 columns, criterion `id` as a `Description` prefix, oracle
invocation and output in `Evidence`. `grade.sh` is not read from, not written to, and not
modified (C-3).

### Layers & Components

| Component | Path | Responsibility |
|---|---|---|
| Schema | `canonical/aid/templates/kb-authoring/frontmatter-schema.md` | Declare `oracle:` as an optional key on a criterion entry, with the exit-code contract. |
| Criteria table | `.aid/knowledge/authoring-conventions.md` | The `oracle:` column/field for a declared criterion, plus the machine-readable selector form. **Owner-authorized (C-5).** |
| Reviewer instruction | `canonical/agents/aid-reviewer/AGENT.md` and the six `reviewer-brief.md` files | The run-it-rather-than-read-it step and the degradation rule. Authored instruction — not executable surface. |
| `G-07`'s oracle | `scripts/checks/g07-selector-partition.sh` | The only executable artifact this feature ships. Outside `canonical/`, so it never enters the render chain (Q-02, NFR-5). |
| New directory | `scripts/checks/` | **Does not exist yet** (`ls scripts` exits 1) — creating it is a deliverable of this feature, named here so no task discovers it mid-build. |

**Why a new `scripts/checks/` rather than the existing `tests/`.** `tests/` is where
feature-001's meter goes, and reusing it would avoid a new directory. It is the wrong home
for an oracle: everything in `tests/` is run by the test harness and answers "is the code
correct", whereas an oracle is invoked by a reviewer mid-review and answers "does this
artifact satisfy a declared criterion". Filing oracles under `tests/` would put them in the
harness's path and imply the suite runs them. The cost of the distinction is one directory;
`L5`'s worked example uses this same path.

`canonical/` edits here **do** trigger the NFR-5 render, unlike feature-001. That render is
folded into feature-003's close-out (C-7), not run per feature.

### NFR-1 accounting

NFR-1 is answered per-oracle, and this feature ships exactly one.

| | |
|---|---|
| Oracle | `g07-selector-partition.sh` |
| Recurring re-derivation it replaces | Reading the registry, reading the corpus definition, enumerating every in-scope markdown file, and applying each selector in order — by hand, every cycle, in every gate that reviews an in-scope file. |
| How much of it, measured | **203 of 276 in-scope files decided, 73 undecided — 74%.** Everything under `canonical/aid/templates/` is undecided, because `template-payload` has no expressible `Match` and `template-own` sits behind it in the same path space. A number produced by running the oracle, not an estimate; re-measured at execution rather than trusted from this SPEC. No ratio threshold is imposed — AC-11 asks whether the trade is favourable and requires a number behind the answer, which this is. |
| Evidence the re-derivation recurs | `tech-debt.md § L5` records `G-07` as "re-derived by hand each cycle … expensive and inconsistent between cycles". Its recurrence therefore predates the lazy rule, which is why FR-13 exempts it from FR-10's second-re-derivation trigger. |
| Measured how | By feature-001's meter, on the same before/after basis as everything else. AC-11 requires the per-cycle cost of the replaced re-derivation to be recorded, not asserted. |

No second oracle is authored in this feature. Under FR-10 a further oracle appears only when
some criterion has been re-derived twice, which is a fact about future cycles rather than a
deliverable of this one.

### Sections not applicable

No data store, no API, no UI, no events, no DDD/CQRS, no state machine, no auth change, no
cache, no external integration, no scheduled work, no mobile, no search, no AI component, no
recovery or cloud concern. No migration plan: `oracle:` is a pure addition, so nothing on
disk has to be rewritten.

### Known issues touched

None new. The sibling-copy hazard discussed above is `tech-debt.md § L4`'s existing
invariant-anchoring concern, designed around here rather than newly discovered.
