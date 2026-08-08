# feature-008 -- citation-accuracy lint

> **Status:** In Discussion
> **Added:** 2026-07-27, after the Specify phase closed on features 001-007.
> **Origin:** not from the original interview. Found by reading **this work's own review
> record** — see STATE.md Q14.

---

## Why this feature exists

> **This section was rewritten on 2026-07-27 after its first draft was found to contain four
> instances of the exact defect class this feature exists to catch** — an uncomputed count
> ("nineteen cycles"), two wrong measured figures, a correlation claim stated without its
> counterexamples, and a citation to a `STATE.md` section that did not exist. Those are recorded
> in STATE.md Q14 rather than quietly fixed, because a motivation document for a
> citation-accuracy lint that cannot survive its own lint is not evidence of anything.

Features 001-007 were driven to A+ across **24 review cycles** — `4 + 3 + 3 + 3 + 2 + 3 + 6`,
per the `## Features State` notes. Seven of those were each feature's final clean pass, so
**17 cycles carried findings.** Every finding in all 17 was a wrong line number, an unverified
count, or a paraphrase presented as a direct quote. Not one structural, design, or completeness
finding was raised in any cycle of any feature.

Three separate times, two successive reviewers returned different answers for the same count, and
the value had to be established by running the command by hand:

| Claim | Cycle N | Cycle N+1 | Established |
|---|---|---|---|
| `test-grade.sh` numbered cases | 14 | 15 | **16** |
| The M2 `[AUTHORING-FM]` anchor range | 189-194 | 148-149 | **149-150** |
| `aid-plan` BLUEPRINT mentions | 4 | 11 | **11 and 12 are both right** — see below |

### What a lint can and cannot recover from that record

**The honest finding is uncomfortable: a range-and-resolution lint would have caught almost none
of those 17 cycles.** The defects were line numbers that *resolved* and were *in range* but
pointed at the wrong content. The `[AUTHORING-FM]` example is the clearest case — `189-194`,
`148-149` and `149-150` all fall inside
`canonical/skills/aid-discover/references/reviewer-prompt-anatomy.md`, which is **226** lines
(`wc -l`), so all three pass a range check. Retro-recoverable cycles on this corpus: **0 of 17.**

> The path above is qualified deliberately. That basename resolves to **eight** files — the
> canonical one, this repository's `.claude/` **and `.cursor/`** renders, and five under
> `profiles/` — so a bare `reviewer-prompt-anatomy.md:189` is exactly the `[AMBIGUOUS]` case §2
> defines. Derive it rather than trusting the figure, which two successive reviews reported as 7
> and 8: `find . -name 'reviewer-prompt-anatomy.md' | wc -l`. The first review of this spec cited
> the `.claude/` render; all copies are 226 lines, so nothing turned on it here, but the spec
> should model its own convention.

So the case for this feature is **not** "it would have saved 17 cycles." It is narrower and it is
still real:

1. **22 live findings on the current corpus** — 4 unresolvable citations and 18 ambiguous ones
   (§5). Each is a citation a reader must guess at.
2. **A latent bug in shipped code.** `kb-citation-lint.sh`'s linespec class uses an ASCII hyphen.
   All **25** range citations in the seven specs use an en-dash (U+2013), so the existing lint
   silently truncates every one to its first number. Harmless for a ban; fatal for a range check.
3. **A false claim in the KB.** `quality-gates.md` lines 353-354 state the citation lint runs in
   CI's `kb-hygiene` job and is *"blocking for merges to master."*
   `grep -rn 'kb-citation-lint' .github/workflows/` returns nothing. It has never run in CI.
4. **Forward cost.** The mechanical subset of this defect class becomes free from here on — caught
   before a reviewer is dispatched, not after a cycle is paid for.

**The correlation with review cost does not hold, and is recorded here rather than dropped.** The
appealing story — more bare citations, more cycles — has two counterexamples in a sample of seven:

| Feature | Cycles | Bare `file:NNN` in its SPEC |
|---|---|---|
| 001 | 4 | **0** |
| 005 | 2 | **13** |
| 007 | 6 | **54** |

feature-001 carried zero bare citations and still needed four cycles; feature-005 carried thirteen
and needed two. Seven features is far too small a sample either way, and the mechanism (semantic
mis-citation, not syntactic) predicts no correlation. The measured totals are **85** bare
citations across the seven specs and **54** in feature-007 — not the 82 and 53 the first draft of
this section claimed.

### AID already knows the answer, and already wrote it down

`canonical/aid/scripts/kb/kb-citation-lint.sh` exists, and its own header states the standard:

> *"The KB authoring standard (kb-authoring principles.md) requires DURABLE anchors: a file
> path plus a grep-recoverable symbol/heading, NOT a bare `file.ext:LINE` (line numbers drift).
> This lint catches the bare-line form MECHANICALLY so it is fixed at the source (GENERATE)
> instead of one phase later (REVIEW) -- the agent's prose instruction + self-report are not
> enough, so the orchestrator gates on this script."*

Quoted from lines 4–8 of `canonical/aid/scripts/kb/kb-citation-lint.sh`, comment prefixes stripped,
line breaks preserved. The first draft of this block silently dropped
`(kb-authoring principles.md)` from line 4 — the same dropped-parenthetical failure that §4's design
note records for a different quote, in a document whose entire subject is that defect. **It is the
strongest available argument for FR-G3**: three separate long quotations in this one spec drifted
from their sources, each caught only by a reviewer opening the file, and a presence check would have
caught all three for free.

That is a precise description of what this work just lived through. The standard exists, the
enforcement exists, the reasoning is written down — and **it is scoped to `.aid/knowledge`.**
Nothing applies it to work artifacts, which is where the citations are.

Two of the seven specs reached the same conclusion independently and switched to content anchors
for their verification oracles. **feature-005** states the reasoning in prose —
*"features 001–004 all edit this file first and every number would have drifted."* **feature-007**
makes the same move without arguing for it, in a verification-oracle comment reading
`# THE SUBTRACTION, by content anchor (001-006 all edit this file first):`. That instinct, arrived
at by hand and three features late, is what this feature makes a rule.

> **Cross-feature references in this document deliberately name the feature, not the section.**
> Four of this spec's review findings were sibling-spec §-numbers that were wrong while the quoted
> string was right — a §-number is a second claim that can drift independently of the thing it
> locates, and every quotation below is self-locating by `grep`. The one exception is §6's
> region-ownership inventory, where the section is part of the claim.

---

## Source

- **FR-G1** -- the citation validator covers work artifacts, not just the KB
- **FR-G2** -- a cited line number must be in range
- **FR-G3** -- a quoted string attributed to a file must appear in that file
- **FR-G4** (SHOULD) -- a count claim carries its producing command
- **FR-G5** (SHOULD) -- line numbers stay permitted where they carry real precision
- **AC-14** -- a citation in a work artifact resolves

---

## Acceptance Criteria

<!-- Carried across from REQUIREMENTS.md section 9: a mapped criterion keeps the modality it had
     there. This feature was added post-Specify (see STATE.md Q14) and shipped with its criteria
     stated only as a Source bullet, so `lint-modality.sh` -- which matches `| AC-N | ... |` rows --
     could see nothing here. Gated by aid/scripts/kb/lint-modality.sh. -->

| ID | Modality | Criterion |
|----|----------|-----------|
| AC-14 | MUST | **A citation in a work artifact resolves.** Every `file:NNN` or "`file` lines NNN–MMM" reference points at an existing file with at least NNN lines, and every string presented as a quotation from a named file appears in that file. Verified by a lint over `REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `BLUEPRINT.md` and task `DETAIL.md`, on fixtures that fail in both directions. |

---

## Scope

**In scope.** Extending the existing lint to work artifacts under a second rule profile; a range
check; a resolution check; an attributed-quote check; one wiring site; and the fix commit on this
work's own seven specs.

**Out of scope.** The `durable` profile's rule, default root, and behaviour on `.aid/knowledge` —
byte-unchanged, asserted by oracle (b). Renaming the script. The count-claim re-runner.

---

## The tension this feature must resolve

A blanket durable-anchor requirement would be **wrong here**, and this is the design question that
needed care.

Line-number precision was doing real work in this work: six of seven features claim regions in
`canonical/agents/aid-reviewer/AGENT.md` **line by line**, and the argument that no region is
touched twice depends on those exact ranges. feature-006 claims `8, 20, 33-34, 37, 105, 108`
precisely because it is the arithmetic complement of what 001-005 took. Ban line numbers and that
mechanism disappears.

So FR-G5 splits the requirement by **purpose**, not by form. An **ownership** claim needs exact
ranges and must only be *in range*. An **evidence** citation should be durable, because it must
survive the edits the work is about to make.

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Eight subsections — smaller than all seven priors
> (9/14/10/12/13/12/12). Dropped: *Migration and compatibility* (nothing migrates; compatibility
> is one byte-diff assertion, in §7), *Render and profile impact* (the script lands in
> `canonical/aid/scripts/kb/`, an existing emitting directory, so NFR-2 collapses to "the
> invocation uses the `canonical/...` path form" — one sentence in §4), *Pointer strategy* (one
> pointer, stated inline), and the sections already filled above the Specify boundary.

### 1. The rule split, and the extension-or-sibling decision

**Extension: one script, two profiles.** `kb-citation-lint.sh` gains
`--profile durable|resolvable` (default `durable`) and `--depth N` (default `1`).

The two rules differ, but they share a **tokenizer** and differ only in a **verdict function** —
`durable` reports every match; `resolvable` reports only matches that fail resolution or range.
That is `read-setting.sh`'s shape, and it is the only arrangement under which the three hard-won
exemptions (`file.ext:symbol`, `concern-model.md:15-doc seed`, `server.mjs:127.0.0.1`) are
provably identical in both rules rather than transcribed once.

| Root | Profile | Rule | Declared in |
|---|---|---|---|
| `.aid/knowledge/` | `durable` (default) | Bare line citations are **forbidden**. Any match is a violation | `kb-authoring/principles.md` P1(d) |
| `.aid/works/` | `resolvable` | Bare line citations are **permitted**; each must resolve to exactly one file whose length is ≥ the linespec's maximum | P1(d), new scoping paragraph (FR-G5) |

**No rename.** The reference count is materially larger than a rename can absorb, and it is
reported as a command rather than a figure because two reviews produced different totals for it
depending on which trees they excluded:

```bash
git ls-files | grep -vE '^(profiles|\.claude|\.cursor|\.codex|packages)/' \
  | xargs grep -ln 'kb-citation-lint' 2>/dev/null | wc -l    # files
git ls-files | grep -vE '^(profiles|\.claude|\.cursor|\.codex|packages)/' \
  | xargs grep -n  'kb-citation-lint' 2>/dev/null | wc -l    # lines
```

**One** of those references sits inside feature-007's claimed regions —
`canonical/skills/aid-discover/references/state-generate.md:850`, whose invocation path form feature-007 §4 corrects. The two in
`.aid/knowledge/quality-gates.md` are at lines **347** and **387**, and feature-007 claims
341–342, 348, 364 and 388 in that file, so neither is claimed. The `kb-` prefix becomes a mild
misnomer; that is accepted debt and a smaller lie than a cross-feature rename touching every one of
those files.

**One tokenizer defect must be fixed, and it is the strongest argument for extending rather than
siblinging.** The linespec class is `[0-9]+([,-][0-9]+)*` with an **ASCII hyphen**:

```bash
# en-dash ranges vs ASCII-hyphen ranges across the seven specs
grep -ohE '[A-Za-z0-9_./-]+\.(md|sh|py|mjs|yml):[0-9]+–[0-9]+' features/feature-00[1-7]*/SPEC.md | wc -l   # 25
grep -ohE '[A-Za-z0-9_./-]+\.(md|sh|py|mjs|yml):[0-9]+-[0-9]+'  features/feature-00[1-7]*/SPEC.md | wc -l   # 0
```

**Twenty-five ranges, every one an en-dash, none an ASCII hyphen.** The current regex truncates all
twenty-five to their first number. Harmless for a ban — the token is flagged either way — and
fatal for a range check, because the upper bound is exactly the number you must test. A sibling
would have inherited the bug by copy.

### 2. The checks

#### FR-G2 — a cited line number resolves and is in range

**Recognition.** The existing tokenizer, plus the en-dash fix, plus one pattern for the
attributable prose form: a backticked filename followed within 40 characters, on the same line, by
`line(s) N`.

**Resolution — three steps, first hit wins.**

1. **Verbatim from repo root** (`test -f`). Catches the qualified form and legitimate citations
   into dev-only trees. `.claude/skills/generate-profile/SKILL.md` exists at 251 lines and
   `canonical/skills/generate-profile/` does not exist, so step 1 is not optional.
2. **Suffix match against `git ls-files`**, excluding the rendered trees (`profiles/`, `.claude/`,
   `.cursor/`, `.codex/`), plus `packages/` and `tests/**/fixtures/**`, behind a `--search-root`
   flag. Exactly one → resolved. **`.claude/` and `.cursor/` are in the exclusion list** — the
   first draft omitted them, which left `coding-standards.md`'s candidate count ambiguous and the
   implementer guessing. Excluding them is consistent: they are renders of `canonical/`, and a
   legitimate citation *into* a dev-only tree arrives as a qualified path and is already resolved
   by step 1. Derive the candidate counts rather than trusting a quoted figure:

   ```bash
   git ls-files '*coding-standards.md'                                  # all candidates
   git ls-files '*coding-standards.md' | grep -vE '^(profiles|\.claude|\.cursor|\.codex|packages)/|/fixtures/'
   ```
3. Zero → `[UNRESOLVED]`. Two or more → `[AMBIGUOUS]`, candidates listed. **Blocking**, not
   advisory: it is 18 of the 22 real findings, and making it advisory turns the feature into a
   warning printer.

Prefer `git ls-files` over a `find` per citation: measured, the per-citation sweep took **194 s**
for 51 lookups on this tree; one index grepped 51 times took **~5 s**. It also inherits
`.gitignore`, excluding `site/node_modules` and `.aid/.temp` for free.

> **A mandatory fallback, found by this spec's own review.** `git ls-files` **fails outright in
> this repository's own worktrees**: run inside
> `.claude/worktrees/work-003-review-subsystem-redesign` under WSL it returns
> `fatal: not a git repository`, because the worktree's `.git` pointer holds a Windows-style
> `gitdir:` path that WSL-native git cannot resolve. That is the known Q3 defect (e), still live,
> and it means the resolver's preferred index is unavailable **on exactly the platform and layout
> this work is being authored in.**
>
> So the resolver **must** fall back to a single `find` sweep — one pass building an in-memory
> basename index, not one `find` per citation — whenever `git ls-files` exits non-zero. With the
> fallback the exclusion list must be applied by path prefix rather than inherited from
> `.gitignore`, so `site/node_modules` and `.aid/.temp` join the explicit exclusions. A
> `git`-only resolver would have shipped and then failed on the maintainer's own machine.

**Range check** runs only on "exactly one": `max(linespec) > wc -l` → `[OUT-OF-RANGE]`.

**Coverage boundary, plainly.** Measured on the seven specs:

| Form | Example | Count | Reached |
|---|---|---|---|
| `path:NNN`, `path:NNN–MMM` | `grade-summary.sh:465–467` | **85** | Yes |
| Prose, filename backticked ≤40 chars earlier, same line | `` `grade.sh` lines 207–212 `` | **27** | Yes |
| Prose, file named in a prior sentence or row header | `Line 133 states…` | **90** | **No** |
| Bare number in a table cell, filename in another column | `\| **75–85** \|` | 43 range-shaped, 78 single | **No** |

**The table-cell form is not claimed and cannot be.** Of 121 bare-number cells in these specs, 78
are single numbers, and most of those are Change Log revision numbers, taxonomy indices, FR counts
or date components. No regex separates them from a line number.

**What covers the unreachable forms instead.** FR-G5's ownership case *is* the table-cell form, and
what protects it is not a lint: it is feature-002 §5's taxonomy class 5 (**Stale reference**,
`Step 2` → `[MEDIUM]` confined / `[HIGH]` escaped) applied by the deep reviewer to the inventory as
a whole, plus the **Cross-check** column all seven inventories already carry. **The lint owns the
evidence citation; the reviewer owns the ownership claim.**

#### FR-G3 — an attributed quote appears in the file

**Recognition: an explicit convention, with proximity as the free bonus.** Measured, proximity
alone reaches 10 of 54 italic-quote constructs (19%); the markdown-blockquote construct reaches 1
line in the whole corpus. Neither suffices alone, so the artifact adopts the form it already uses
in those 10 places:

> A string presented as verbatim from a file is an italic-quoted span immediately preceded on the
> same line by a backticked citation of its source file, with at most 40 characters of connective
> prose between them.

Not invented for the occasion — it is the form of `state-generate.md`'s Step 5a closing sentence
and of feature-007's pre-sanctioned-wiring paragraph. It also works inside table rows, where the
File column and the quote share a line. (A first draft cited feature-002's oracle prose as a third
example; none of its oracles actually uses the pattern, so the claim is dropped rather than
stretched.)

The check: for each `*"…"*` span, if a backticked file citation precedes it on the same line, the
quoted text **must** appear in that file. If none precedes it → `[UNATTRIBUTED-QUOTE]`, advisory,
exit code unchanged.

**Emphasis normalisation is mandatory, and this is measured rather than anticipated.** Both
raw-substring failures in the seven A+ specs are emphasis drift, not paraphrase:

| Citing site | Quoted as | File says |
|---|---|---|
| feature-007, the `A1–A5` row of its points-to-rules table, citing `accessibility-checklist.md:3` | `output **must** meet these criteria` | `output must meet these criteria` |
| feature-005, the `quality-gates.md` row of its affected-artifact inventory | `the **reviewer** sets/updates Status` | `the *reviewer* sets/updates Status` |

So both sides are stripped of `*`/`_`/backtick emphasis runs and whitespace-collapsed before
`grep -F`. **Without that step the check's first two outputs on AID's own corpus are both false
positives**, and a lint whose first two findings are noise does not survive its first FIX cycle.

**Remaining false positives:** an elided quote (`"foo … bar"`), a quote spanning a source line
break, a quote of *rendered* table text. Mitigations: any quote containing `…`/`...` is advisory
only; compare with newlines collapsed to spaces.

**False negatives, which are the majority and must be admitted:** every quote the author did not
attribute per the convention — 44 of 54 here. They surface as advisories, so the gap is visible.
**This check verifies compliance with a convention. It does not verify quotes in general.**

### 3. FR-G4's disposition — a review rule, not a lint check

**Not mechanically reachable, and the reason is sharper than the requirement assumes.** Take the
BLUEPRINT count from the evidence table above:

```bash
grep -rho 'BLUEPRINT'  canonical/skills/aid-plan/ | wc -l   # 12  occurrences
grep -rn  'BLUEPRINT'  canonical/skills/aid-plan/ | wc -l   # 11  matching lines
grep -rhoi 'blueprint' canonical/skills/aid-plan/ | wc -l   # 14  occurrences, case-insensitive
grep -rni  'blueprint' canonical/skills/aid-plan/ | wc -l   # 12  lines, case-insensitive
```

**11 and 12 are both correct.** They answer different questions, and the claim has four defensible
values. Neither reviewer was wrong. **The defect is not an unverified number — it is an unstated
question**, and no lint can supply a missing question.

**Disposition, in two parts.**

**(a) A review rule in feature-002's catalog.** A taxonomy *instance*, not a new class, and
admissible because a criterion already exists: `kb-authoring/principles.md` **P2(b)** — *"the value
must be derived from disk truth at the moment of authoring. No copying old values forward; no
estimating."* That rule has simply never been applied outside `.aid/knowledge/`.

| Cell | Value |
|---|---|
| **Artifact class** | The **Definition** family file (`review-rubrics/definition.md`) — REQ, SPEC, PLAN/BLUEPRINT, TASK. An unverifiable count is an untestable criterion, which is that family's own shared criterion |
| **Modality** | `SHOULD` — inherited from FR-G4, never invented |
| **Mode** | `judgment`. Honest, and the reason it is a rule row rather than a lint check |
| **Severity anchor** | `[LOW]; escaped (>1 artifact) → [MEDIUM]` — feature-002 §5 class 6's form, which is what feature-001's Step 1 gives a SHOULD-modality convention deviation. **Not `Step 2`**: modality is known at authoring, so Step 1 already fixes it, and the cell matches feature-002 oracle (e)'s regex |
| **Rule ID** | feature-002 owns the numbering; this feature contributes row content only |

**(b) The convention, and the one half that is mechanically total.** A lint cannot find count
claims, but the inverse has no recognition problem: *for every count that carries its command,
re-run the command and diff.* The form already exists in this work — feature-005 §12 opens *"Every
baseline below was produced by running the command"*, and feature-002 oracle (g) refuses to inline
a count and gives three commands instead. Written as `<command>   # measured: N`, the anchor is
author-supplied and the check is total over the annotated set.

**Do not build that re-runner here.** It executes strings out of a markdown file — an
arbitrary-code-execution surface inside a linter, which `coding-standards.md`'s Security
Conventions section does not currently speak to. The convention lands here; the re-runner is
deferred **with a named successor**, as feature-006 deferred its Tier 3 dispatches.

### 4. Wiring, and the cost argument

**One site: `aid-deep-review` RESOLVE** — the state that reads the manifest and resolves the
artifacts, and the last one before DISPATCH. The gate sits after that resolution and before any
dispatch. Exit 1 → do not dispatch; return findings to the caller for FIX. That is Step 5a's shape,
and `canonical/skills/aid-discover/references/state-generate.md` lines 862–863 pre-sanction it —
`state-generate.md` says *"This gate is the model for moving any MECHANICAL authoring rule"*, and
goes on to name the self-reported-to-mechanically-gated move and to cite `lint-frontmatter.sh` as
the precedent. feature-007 §4 invoked the same sentence for the frontmatter lint.

> **Quoted deliberately short, and this is a design note rather than an aside.** Two successive
> drafts of this paragraph failed FR-G3 on the *same* sentence: the first changed the source's
> inner double quotes to single, and the fix for that dropped a trailing parenthetical and moved a
> period. The sentence spans a line break and contains nested quotes and a parenthetical — three
> ways for a verbatim quote to drift. **A quote that must survive FR-G3 should be a short fragment
> from a single source line**; anything longer is better cited by anchor and paraphrased openly, as
> the remainder of this sentence now is. That guidance belongs in the `principles.md` P1(d)
> paragraph this feature adds. The invocation uses the `canonical/...` path form, so
`rewrite_install_paths` handles all five profiles and NFR-2 needs nothing further.

**Why not the definition skills' authoring states — contention, measured.** All four are claimed:

| Candidate | Claimed by |
|---|---|
| `aid-specify/references/state-continue.md` | 67–101 (f007), 81 (f001) |
| `aid-plan/references/first-run-loop.md` | the 89/99/142 span (f006), 142 (f007) |
| `aid-detail/references/first-run.md` | 95 (f007), Tier-1 span (f006) |
| all four `state-review.md` | rewritten wholesale by f006's caller migration |

Four edits into four contested spans, versus **one insertion into a file feature-006 creates.** And
feature-006's manifest already carries `artifacts:` *"derived from disk, never memory"* — the
lint's input is that field verbatim, so no new resolution logic and no argument plumbing. Because
f006 migrates eight Tier-1 callers and f007 adds two more review sites, one gate in RESOLVE covers
every definition skill plus `aid-review` plus the shortcut-engine GATE.

**Not `aid-light-review` RESOLVE:** that skill's own REPORT verdict says a clean light pass is
*not* a pass, so it is not the thing a caller pays a review cycle for; a gate there would leave
every deep-review caller ungated.

**CI, and a defect to correct while there.** `quality-gates.md` lines 353–354 claim the citation
lint runs in CI's `kb-hygiene` job and is blocking for merges to master.
`grep -rn 'kb-citation-lint\|closure-check' .github/workflows/` returns nothing — neither it nor
`closure-check.sh` has ever run in CI; only `lint-frontmatter.sh` and `build-kb-index.sh` do. Same
"the KB claims it is wired and it is not" case feature-007's FR-F3 found for the frontmatter lint's
*skill* wiring. feature-007 claims 341–342, 348, 364 and 388 in that file but **not** 353–354, so
the correction is unclaimed and belongs here; §6's inventory row is the authoritative statement of
that claimed set.

**The cost argument, stated at the strength the evidence supports.** The tier-weighted dispatch
form is **unavailable**: this work's `## Calibration Log` and `## Dispatches` sections are both
`_None yet._`, so no per-dispatch agent or tier was recorded for any cycle. AC-13's instrument is
feature-006's delivery D0 and does not exist yet. And as §Why states, retro-recoverable cycles on
this corpus are **0 of 17** — a pre-dispatch gate cannot recover a cycle whose findings were semantic.
**The defensible claim is forward-looking only:** the gate makes the mechanical subset of this
defect class cost zero review dispatches from here on, at the price of one insertion into a file
being created anyway.

### 5. Self-application

**Fail-and-fix. Not retrofit, not grandfather.** The designed checks against the seven Ready A+
specs today:

| Check | Findings |
|---|---|
| FR-G2 resolution — `[UNRESOLVED]` | **4** |
| FR-G2 resolution — `[AMBIGUOUS]` | **18** |
| FR-G2 range, on the uniquely-resolved remainder (**85 − 4 − 18 = 63**) | **0** |
| FR-G3 quote presence, raw substring | 2 — both emphasis drift, both false positives |
| FR-G3 quote presence, after normalisation | **0** |
| **Total blocking** | **22** |

The resolved count is **derived, not measured independently** — it is the 85 total minus the two
resolution-failure classes, so the three FR-G2 rows sum to 85 by construction and cannot drift
apart. Re-derive all four numbers at implementation time; the first draft of this table stated 62
and did not add up.

**FR-G2's range check finds nothing on the corpus that motivated it**, for the reason §Why gives.
Stated here as well as there, because a spec for a citation-accuracy lint that overclaimed its own
yield would be self-refuting.

The 22 are still worth having, and all are cheap:

- **4 `[UNRESOLVED]`.** Three are one authoring pattern: feature-005's evidence list continues
  `reviewer-prompt-correctness.md:NNN` with elliptical continuations (`-anatomy.md:NNN` and
  siblings). A reader recovers the elision; `grep` cannot. The fourth is a bare `render.py:NNN` —
  whose *content* is correct, but the file exists only under
  `.claude/skills/generate-profile/scripts/`, and a bare basename of a dev-only-tree file is
  unrecoverable. One qualified path fixes it.
- **18 `[AMBIGUOUS]`**, dominated by high-fan-out basenames: `state-review.md` ×5 (**four** files
  carry that name in `canonical/`, at 646/413/186/73 lines), `grading-rubric.md` ×4 (two files, 83
  and 330 lines — and in *this* work the distinction between them is the entire subject of
  feature-007 §1), `state-generate.md` ×3, `coding-standards.md` ×2, and one each of `SKILL.md`
  (**111** candidates), `README.md` (29), `reviewer-brief.md` (6), `state-fix.md` (3).
- **Plus the 25 en-dash ranges** whose upper bound nothing has ever checked.

**Why not grandfather:** the seven specs are the only real corpus AID has for this lint, and a
grandfather list is an exclusion list — which **feature-004 §2** rejects by name
(*"exclusion lists rot"*, its only statement of the rule; a first draft of this paragraph also
attributed it to feature-002, which never says it). Running the lint on the seven specs **is** the
acceptance test.

### 6. Affected-artifact inventory and region ownership

`kb-citation-lint.sh` is claimed by no feature: `grep -rn 'kb-citation-lint'` across
`features/feature-00[1-7]*/SPEC.md` returns one hit, feature-007 §4 correcting an invocation path
form in `state-generate.md` — a different file.

| File | Claimed here | Cross-check |
|---|---|---|
| `canonical/aid/scripts/kb/kb-citation-lint.sh` | header block, arg parser, `find` depth, linespec character class, new verdict function | **Unclaimed by 001–007.** Existing emitting directory (14 files ship from `scripts/kb/`), so the new-directory emission caveat 003/004/005 carry does not apply |
| `tests/canonical/test-kb-citation-lint.sh` | **extended, not created** — the file exists | Unclaimed |
| `canonical/aid/templates/kb-authoring/principles.md` | **P1(d)** scoping paragraph; **P2(b)** carry-the-command sentence | `grep -c 'principles.md'` across all seven → **0**. Fully unclaimed |
| `canonical/skills/aid-deep-review/` RESOLVE body | one gate step | **Directory created by feature-006.** Pure insertion into a new file; f006 owns the file name |
| `canonical/aid/templates/review-rubrics/definition.md` | one `Mode: judgment` rule row | **File created by feature-002.** Row content only; f002 owns schema and numbering |
| `.aid/knowledge/quality-gates.md` | one Mechanical-Gates row; one Validation-Commands line; **the 353–354 correction** | f007 claims 341–342, 348, 388, the frontmatter row of 364. **353–354 unclaimed.** The two insertions are declared collateral inside f007's table and command block; ordered after f007. Carries a Change Log row and a `README.md` revision-history entry |
| `.aid/knowledge/authoring-conventions.md` | the rule statement near *"This is mechanically gated by `kb-citation-lint.sh`"*, and the **Durable citations** enforcement row | f002 claims this file's frontmatter `contracts:` only. Disjoint |
| `.aid/knowledge/artifact-schemas.md` | the **KB-doc citations** row of the distributed-validator table | f007 claims 207 and 640; 640 is the adjacent **Frontmatter** row of the same table. Same table, different row — declared, disjoint |
| `.github/workflows/test.yml` | one `kb-hygiene` step | f007 *cites* line 155 as evidence but its inventory does not list the file. Unclaimed |
| The seven `features/feature-00[1-7]*/SPEC.md` | the 22 citation fixes only | Work artifacts; in no feature's inventory |

**Collision verdict: none.** Two declared collaterals in `quality-gates.md` (inside feature-007's
table and command block), one same-table-different-row adjacency in `artifact-schemas.md`, and two
dependencies on files features 002 and 006 create.

**Regenerated, never hand-edited:** `.aid/knowledge/INDEX.md`, `kb.html`, and the seven rendered
trees.

### 7. Verification strategy

Extends `tests/canonical/test-kb-citation-lint.sh`. Exit-code contract unchanged — `0` clean, `1`
violations, `2` usage, per `coding-standards.md`'s Exit Codes section. Advisory findings print
without changing the code, matching the `visual-fidelity` SKIP precedent.

- **(a) Mode separation** — the extension decision made testable. One fixture, a `f.md:NN` that
  resolves and is in range: `--profile durable` → exit 1; `--profile resolvable` → exit 0.
- **(b) KB behaviour byte-unchanged** — `diff -q` of default-profile output on `.aid/knowledge`
  before and after. Measured today: exit 0,
  `kb-citation-lint: clean (no bare line citations under .aid/knowledge).`
- **(c) Depth** — `-maxdepth 1` reaches only work-root files. Measured: on
  `--root .aid/works/work-003-review-subsystem-redesign` the current script reports **6** findings,
  all in `STATE.md`, and **zero** from the seven SPECs, because `features/feature-NNN/SPEC.md` is
  two levels down and task `DETAIL.md` is four. Oracle: a citation at each of depths 0–4;
  `--depth 4` finds five, depth 1 finds one.
- **(d) En-dash ranges** — `f.md:NN–MM` against a 15-line file → exit 1 `[OUT-OF-RANGE]`.
  **Non-trivially false today**: the upper bound is currently invisible and this passes. The
  regression guard on the tokenizer fix.
- **(e) Range, both directions** — `f.md:NN` on a 10-line file → 0; `:11` → 1; `:5,11` → 1;
  `:5-11` → 1; `:5–11` → 1.
- **(f) Resolution, three outcomes** — verbatim-resolvable → OK; zero candidates →
  `[UNRESOLVED]`; two → `[AMBIGUOUS]` with both listed. Per CLAUDE.md's transient-work-folder rule
  the fixture builds its own same-basename pair rather than leaning on the repo's four
  `state-review.md` files.
- **(g) Exemptions preserved in both profiles** — `file.ext:symbol`,
  `concern-model.md:15-doc seed`, `server.mjs:127.0.0.1` silent under `durable` and `resolvable`
  alike. This is the hard-won part being reused; without a fixture per form the reuse is unverified.
- **(h) Quote presence, both directions, with the negative control** — present → 0; absent → 1;
  **present-after-emphasis-normalisation → 0.** The third is the one a weaker suite omits, and
  without it the check ships with two false positives on AID's own specs.
- **(i) Unattributed quote is advisory** — a `*"…"*` with no preceding citation produces a finding
  at advisory severity and does not change the exit code. Proves the coverage boundary is
  *reported*, not hidden.
- **(j) Self-application as the acceptance gate** — `--profile resolvable --depth 4` over
  `features/` → exit 1 before the fix commit, exit 0 after. The baseline is captured by command,
  not quoted, since an inlined count would be stale before implementation starts:

```bash
ls -d features/feature-00[1-7]*/ \
  | xargs -I{} bash canonical/aid/scripts/kb/kb-citation-lint.sh --root {} 2>&1 \
  | grep -c 'SPEC.md:'
```

**What no script can prove, stated plainly.** That a resolvable, in-range line number points at the
content the sentence claims it does. That is the actual defect in essentially all 17
findings-bearing cycles; it is semantic, and no oracle here reaches it. It is covered by
feature-002's `Stale reference` taxonomy row applied by the deep reviewer, and by the ownership
cross-check column the seven inventories already carry.

### 8. Out of scope

- The `durable` profile's rule and default root — byte-unchanged, oracle (b).
- The count-claim re-runner — deferred with a named successor; code execution from markdown, a
  surface `coding-standards.md`'s Security Conventions does not address.
- The table-cell and unattributed-prose citation forms — unreachable; covered by review (§2).
- Renaming `kb-citation-lint.sh` — see §1 for the reference count, reported there as a command
  rather than a figure, and for the single reference that sits inside feature-007's regions. **This
  bullet previously restated "~30 lines across 14 files" after §1 had already replaced that figure
  with its command** — the same leave-a-stale-duplicate-behind defect the review record shows three
  times over. When a figure is replaced by a command, sweep for its other occurrences.
- The rule-row schema, ID numbering, and family files — **feature-002**.
- The `aid-deep-review` skill and its manifest — **feature-006**.
- Whether `.aid/knowledge/STATE.md` and `README.md` should be exempt from the `durable` scan under
  P6. They are scanned today because they are depth-1 `.md` files; changing that is a change to the
  `durable` profile.

### Delivery recommendation

Two. **D1 — the lint:** the en-dash fix, `--depth`, `--profile`, the resolver, the range check,
oracles (a)–(g), the `principles.md` P1(d) scoping paragraph, and the fix commit on the seven specs
(oracle (j)). **D2 — the quote check and the wiring:** FR-G3, oracles (h)/(i), the
`aid-deep-review` RESOLVE gate, the CI step, the `quality-gates.md` rows and the 353–354 correction,
and the FR-G4 rule row.

D2 depends on features 002 and 006 having landed. **D1 depends on nothing and gates nothing** —
unique in this work, and the reason this feature could ship first and reduce the other seven's
implementation cost.
