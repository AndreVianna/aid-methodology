# KB Documents for Commitment and Backlog

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-09 | Feature identified from REQUIREMENTS.md §5.1, §7 C-3/C-6, §9 AC-3/AC-4/AC-5 | /aid-define |
| 2026-08-09 | Technical Specification authored | /aid-specify |
| 2026-08-09 | Rewritten against spec review round 1 (E, 21 findings) | /aid-specify |
| 2026-08-09 | Re-scoped per Q5 after round 2 (E, 22 new findings, 0 recurred): documents become conditional and created on demand, seed stays 14, `## Change Log` doctrine conflict deferred to its own work | /aid-specify |
| 2026-08-09 | Merged master (PR #183 removed the KB history apparatus): the deferred Change Log conflict is resolved upstream, so the new **documents** carry no Change Log; `tech-debt.md`'s work-named section is already gone; `release-aid` gains a dead-instruction fix. (Wording corrected in the r5 pass: this row originally said "the new templates", a noun §1a exists to forbid — the AS03 clause it carried is separately superseded by the row below) | /aid-specify |
| 2026-08-09 | Rewritten whole against review round 4 (22 findings, 11 recurred). Supersedes the row above on one point: AS03/AS03b/AS03c are **template-scoped** and cannot see a document with no template, so AC-5's oracle is a direct grep over the instances. Also: matrix rows corrected to the real four-field `conditional:<when>` shape across all eight domains; `decisions.md`'s precedent corrected from "ten rows" to six (one of them `required`); two registration surfaces added (`document-expectations.md`, `_dim_of_filename` in both twins); document creation moved to feature-003, which owns shape; the Seed-coverage check acknowledged as changed; the promotion criterion restated as a scheduling decision; AC-10/AC-11 added; five stale citations fixed | /aid-specify |
| 2026-08-09 | Closed spec review round 5 (19 findings, 3 recurred) against REQUIREMENTS.md **FR-11**. Structural: `release-tracking.md`'s conditional registration **restored** (r4's deletion dropped FR-9 and STATE.md Q5 and left it unowned) — three documents now register across CC-4's four surfaces; the `.aid/settings.yml` + `README.md` count edits **removed** from this feature per CC-2; the resolved-`doc_set` value settled by citing CC-1 rather than re-deriving it; AC-4 replaced with a criterion that can fail; AC-9's remedy moved from the dogfood-only `authoring-conventions.md` to the `### backlog.md` block adopters actually receive; AC-3's clean-diff scoped to the suite scripts; AC-10 given an oracle that runs; AC-6/AC-1 given oracles; AC-12 added for the matrix's own conditional tallies; two false claims (universal `document-expectations.md` coverage; the `data-ml`/`research` `decisions.md` rationale) corrected against disk | /aid-specify |
| 2026-08-10 | **AC-2's and §1a's printed `find` oracles corrected during Detail**, from `find canonical -iname …` to `find canonical/aid/templates -type f \( -iname … \)`. The old form contradicted the criterion text it was printed under (*"None has a file anywhere under `canonical/aid/templates/`"*): `-iname` matches basenames, so once feature-003 lands `canonical/skills/aid-{design,create,update}-{roadmap,backlog}` the unscoped form returns six directories this feature has no objection to, and a correct implementation would fail its own oracle. Both instances swept; both forms return nothing today, and only the narrowed one still does after feature-003 lands. Raised as **Q8** in the work `STATE.md` | /aid-detail |
| 2026-08-09 | **Owner decision on `kb.html`** (the `## Unreleased` migration's fourth carrier): it **is** regenerated in this work, so AC-6's `grep -c Unreleased .aid/knowledge/kb.html` → `0` oracle is satisfiable and no carrier is dropped. Nothing in this spec had hedged against the old "unregenerable" claim — §1d, §4a and §6 already said *regenerated* — so the change is one of **ownership and timing**, now stated where it was previously implicit: the regeneration is an authored ~24-minute `/aid-summarize` run, not a script like `INDEX.md`/`relationships.md`, and final-state summaries are refreshed once, so it runs in feature-006 § *KB and methodology refresh* and §5 row 10's `kb.html` conjunct is evaluated there. §6 step 6, §7 *Outbound*, §1d, §4a and AC-6 all say so now | owner decision / /aid-plan |

## Source

- REQUIREMENTS.md §5.1 (Knowledge Base doc-set additions), **FR-9** (conditional, created on demand)
- REQUIREMENTS.md **FR-11** — **CC-1** (resolved doc-set presence), **CC-2** (the `create`
  skill writes the registration), **CC-4** (the four registration surfaces — *defined in this
  feature*, §1b), **CC-6** (`roadmap.md` / `backlog.md` are domain-agnostic)
- REQUIREMENTS.md §4 (In Scope — the governance-artifact doctrine amendment)
- REQUIREMENTS.md §7 C-3, C-6; §9 AC-3, AC-3a, AC-4, AC-5
- Work `STATE.md` Q5 (owner-approved: `roadmap.md`, `backlog.md`, `quality-gates.md`,
  `release-tracking.md` become conditional documents)

## Description

The Knowledge Base can describe what a project **is**, but not what it has
**committed to** or what it has **defined but not scheduled**. This feature adds the
two documents that close that gap, amends the doctrine that currently forbids them, and
migrates the existing content that belongs in them.

`roadmap.md` holds direction — where the project is going and why. `backlog.md` holds
items that have been properly defined and prioritized — the internal tracker the project
lacks. **Items** move through three documents, never duplicated:

```
observed but unscheduled  →  defined + prioritized  →  shipped
    tech-debt.md                  backlog.md          release-tracking.md
```

An item leaves `tech-debt.md` for `backlog.md` exactly when it is accepted into the plan
(§3c), and leaves `backlog.md` for `release-tracking.md` when it ships. `roadmap.md` is
deliberately **not** a stage in that flow: it operates at a coarser granularity than items,
so an item never sits in it.

**Three documents are registered here, not two.** `roadmap.md` and `backlog.md` are new;
`release-tracking.md` already exists on disk but has **never been registered** on any of the
four surfaces — zero matrix rows (§1c), no mention in `concern-model.md`, no
`### release-tracking.md` block among `document-expectations.md`'s 24 blocks, and both
`_dim_of_filename` twins resolve it to the empty dimension. FR-9 and STATE.md Q5 both admit
it as conditional; this feature is where that lands. `quality-gates.md` — the fourth document
those two name — belongs to feature-004 (§7).

**The documents are conditional, not seed members** — and conditional is followed in its
shipped particulars, not merely invoked. Like `decisions.md`, none gets a template under
`canonical/`, none enters `synth_default_seed`, and all three are carried as conditional rows
in `domain-doc-matrix.md`. `roadmap.md` and `backlog.md` are created on first use by their
own `create` skill; `release-tracking.md` keeps whatever creates it today. A project that
never runs those skills never acquires them — correct, because not every project has a
roadmap. The **seed** count stays at 14, so no seed-count assertion, ownership-map entry, or
site mirror moves.

**On the resolved `.aid/settings.yml` `doc_set` value: per CC-1.** This spec asserts no
reasoning of its own about it. Consequences here are only two: `release-tracking.md`'s live
entry (`.aid/settings.yml:56`, `release-tracking.md|skill-self|required`) is already what CC-1
prescribes and is therefore **not edited**, and the entries for the two new documents are
written by their `create` skill, not by this feature (**CC-2**, §1e).

**Two doctrine amendments are required** (§2). The first: `concern-model.md`
§ "Why product-concerns, not governance-artifacts" names *"a plan, a backlog, a
register"* as a scope smell, so without amendment the documents fail the KB's own
rubric however they are admitted. The second: the shipped model admits a conditional doc
*"via the propose→confirm gate"* at discovery, whereas these arrive from their owning
skill — the doctrine must admit **skill-created** conditional documents too.

**Resolved upstream while this work was in Specify.** The `## Change Log` conflict this
feature briefly owned, then deferred, was settled by master's PR #183: no KB doc or
template carries the section, and `AS03`/`AS03b`/`AS03c` now assert its absence along
with the absence of `changelog:` and of work references. Both new documents are authored
to that standard.

## User Stories

- As an **AI agent consuming the KB**, I want to read what the project has committed to
  and what it has defined but not scheduled, so that I do not have to infer direction
  from code and release history.
- As an **adopter**, I want defined-and-prioritized work to have a durable home that
  survives a pruned work folder, so that decisions are not lost when a work ships.
- As an **adopter with no roadmap**, I want no roadmap document and no gate complaining
  about its absence.
- As an **adopter cutting releases without `release-aid`**, I want the drain step written
  down in a document my own toolchain installs, so the item flow does not stall at
  `backlog.md`.
- As the **AID maintainer**, I want one item to live in exactly one document at a time,
  so that inventories do not drift against each other.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-1 — Doctrine amended, in both files, each with its own oracle.**
      `concern-model.md` and `.aid/knowledge/authoring-conventions.md` § Concern Model permit
      project-level (not per-work) forward-looking documents, with the
      transient-pipeline-artifact reasoning stated in place of — not appended to — the
      premise it overturns. The two files state the rule at different depths and are checked
      separately because their current texts differ: `concern-model.md:71` carries the
      "which already exist" premise; `authoring-conventions.md:236-238` carries only the
      one-sentence restatement and no such premise, so `concern-model.md`'s oracle does not
      transfer.
      *Oracle A (canonical), section-scoped:*
      ```bash
      S() { awk '/^### Why product-concerns/{f=1;next} f&&/^---/{exit} f' \
              canonical/aid/templates/kb-authoring/concern-model.md; }
      S | grep -c 'which already exist'   # → 0   (1 today)
      S | grep -c 'project-level'         # → >=1 (0 today)
      grep -c 'skill-created' canonical/aid/templates/kb-authoring/concern-model.md  # → >=1 (0 today, §2b)
      ```
      The scoping is not cosmetic: a whole-file `grep -c 'per-work'` would already return `1`
      today (`:70`, *"the per-work `STATE.md`"*), and `project-level` already appears twice at
      `:144` and `:150` in the T2-cardinality section — both would make an unscoped oracle
      vacuously true. Each of the three clauses fails on today's file.
      *Oracle B (dogfood):* `grep -n 'governance artifact' .aid/knowledge/authoring-conventions.md`
      returns a sentence that names the per-work / project-level split, and
      `grep -c 'project-level' .aid/knowledge/authoring-conventions.md` → `>= 1` (it is `0`
      today; the current text at `:236` is *"A doc that is really a governance artifact (a plan,
      a backlog, a register) is out of KB scope"*, which draws no such split).
- [ ] **AC-2 — Conditional admission across CC-4's four surfaces, for all three documents.**
      `roadmap.md`, `backlog.md` and `release-tracking.md` each occupy all four surfaces
      defined in §1b (the definition CC-4 refers to). None has a file anywhere under
      `canonical/aid/templates/`; none is added to `synth_default_seed`'s ownership map
      (AC-4); each is carried as a four-field row with a `spine-dimension` and a
      `conditional:<when>` presence value in all eight domains; each is named as conditional
      in `concern-model.md`.
      *Oracle:* `find canonical/aid/templates -type f \( -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' \)`
      returns nothing (it returns nothing today, and the criterion is that it still returns
      nothing after the feature lands). **The oracle is scoped to `canonical/aid/templates`
      and to files, because that is exactly what the criterion above says** -- *"None has a
      file anywhere under `canonical/aid/templates/`"*. An unscoped `find canonical -iname …`
      would be **unsatisfiable by a correct implementation**: `-iname` matches basenames, so
      once feature-003 lands its skill directories it returns
      `canonical/skills/aid-{design,create,update}-roadmap` and the three `*-backlog`
      siblings -- six directories this feature has no objection to. **And** for each of the
      three filenames the count of matrix rows is 8:
      `awk '/^### Domain:/{d=1} d' canonical/aid/templates/kb-authoring/domain-doc-matrix.md | grep -c '^| `roadmap.md`'`
      → `8`, likewise for `backlog.md` and `release-tracking.md`.
- [ ] **AC-3 — The seed does not move: no test script is edited and every count-bearing
      assertion stays green.** `AS06`, `test-doc-set-read.sh` T02, `test-doc-set-mapping.sh`
      T02, `test-domain-doc-matrix.sh` MT01/MT02/MT06, `test-spine-depth-coverage.sh`
      SD04/SD05/SD07, and `site/scripts/__tests__/gen-reference.test.mjs` all pass
      **unmodified**. Adding *conditional* rows does not disturb them: MT01/MT02 extract
      required rows via the `/\| required/` filter at `test-domain-doc-matrix.sh:85`, so a
      `conditional:<when>` row never enters the byte-exact diff; SD07 asserts `>= 58`, so more
      rows only raise the margin.
      *Oracle:* the five bash suites green **plus** the one vitest spec green
      (`npx vitest run gen-reference` from `site/`), **and**
      `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/` clean.
      **The clean-diff is scoped to the suite scripts, never to the files under test.** Two
      files this feature edits are inputs those suites read —
      `domain-doc-matrix.md` (`test-domain-doc-matrix.sh:49`, `test-spine-depth-coverage.sh:50`)
      and `document-expectations.md` (`test-spine-depth-coverage.sh:51`) — so a diff assertion
      over "their files" would be unsatisfiable by construction. It is the *test code* that
      must not move; that is what makes "the conditional decision cost nothing" checkable.
- [ ] **AC-4 — None of the three documents enters `synth_default_seed`'s ownership map.**
      This is the structural reason REQUIREMENTS AC-3a holds: the presence check at
      `kb-actback-task.sh:479-502` iterates the doc-set TSV, so a document that is not in the
      resolved doc-set is never even looked for, and a document that is not in the ownership
      map is never in the default doc-set. That non-membership is the thing at risk of being
      got wrong, and it is checkable; "no finding names `roadmap.md`" is not, because no
      implementation choice could make such a finding appear.
      *Oracle:* over the two ownership-map regions only —
      ```
      awk '/^### Ownership map/{t=1} t&&/^`INDEX.md` is generated meta/{t=0} t;
           /^  local -a MAP=\(/{m=1} m; m&&/^  \)$/{m=0}' \
        canonical/skills/aid-discover/references/doc-set-resolve.md \
        | grep -cE 'roadmap\.md|backlog\.md|release-tracking\.md'
      ```
      → `0`. The extractor is anchor-based rather than line-numbered (the regions are the
      doc table under `### Ownership map` and the `local -a MAP=(...)` array), and it is
      verified to select both copies: the same command with `tech-debt.md` returns `2`. A
      whole-file grep would be wrong — `doc-set-resolve.md:19-21` carries a
      conditional-declaration example and `:371-391` carries propose→confirm prose, either of
      which could legitimately name a new doc.
- [ ] **AC-5 — C-3 compliance of the two new instances.** The `roadmap.md` and `backlog.md`
      *instances* in `.aid/knowledge/` carry no `## Change Log` / `## Revision History`
      section, no `changelog:` frontmatter field, no work id and no work-folder path.
      *Oracle:* `grep -cE '^## (Change Log|Revision History)|^changelog:|work-[0-9]{3}'`
      over the two files → `0`. **Not** `AS03`/`AS03b`/`AS03c` — those assertions are scoped
      by a `find` over `canonical/aid/templates/knowledge-base/`
      (`test-kb-template-authoring-standard.sh:42,50`) and can never see a document that has
      no template there. Citing them would make this criterion vacuously true.
      `release-tracking.md` is out of this criterion's scope: it legitimately carries work
      references as release history (§4c).
- [ ] **AC-6 — `## Unreleased` removed, from the section and from every carrier that
      describes it.** `release-tracking.md` carries no `## Unreleased` section **and no prose
      describing one**; the four dependent carriers are updated: its own `objective:` /
      `summary:` frontmatter and the body rule in its lede, the duplicated
      `release-tracking.md` summary at `INDEX.md:61`, the three
      `kb:release-tracking.md#unreleased` rows in `relationships.md`, and the eight
      occurrences on seven lines of `kb.html` (`:3648`, `:3724`, `:3731`, `:3736`, `:3740`,
      `:3741` ×2, `:3751`) — that last carrier cleared by feature-006's single
      `/aid-summarize` re-run rather than by a run here (§6 step 6). The historical Q&A entry
      at `.aid/knowledge/STATE.md:203` is **not** touched.
      *Oracle:* `grep -c Unreleased .aid/knowledge/release-tracking.md` → `0` (it is `6`
      today — lines 4, 5, 18, 20, 21, 24 — so a `## Unreleased`-only search would pass while
      five lines still described the section); `grep -c Unreleased .aid/knowledge/INDEX.md`
      → `0`; `grep -c 'release-tracking.md#unreleased' .aid/knowledge/relationships.md` →
      `0`; `grep -c Unreleased .aid/knowledge/kb.html` → `0`; and
      `git diff --exit-code -- .aid/knowledge/STATE.md` clean.
- [ ] **AC-7 — Release flow rewired.** `release-aid` drains committed `backlog.md` items
      into a new `release-tracking.md` version section at tag time; its Step 9
      clean-Unreleased close-out check is resolved.
      *Oracle:* `grep -c Unreleased .claude/skills/release-aid/SKILL.md` → `0` (it is `4`
      today — `:103`, `:104`, `:107`, `:251`), and
      `grep -n 'backlog.md' .claude/skills/release-aid/SKILL.md` names it inside § 3.1 as the
      drain source. The zero is deliberate and reachable: the skill is an instruction set for
      the *next* release, not a history, so it keeps no explanatory mention of the retired
      section — that record lives in `release-tracking.md`'s own version sections.
- [ ] **AC-8 — `release-aid`'s dead Change Log instruction removed.** § 3.1 no longer
      instructs adding a row to a `## Change Log` table that PR #183 deleted.
      *Oracle:* `grep -c 'Change Log' .claude/skills/release-aid/SKILL.md` → `0`. The count
      is `1` today (`:105`), so the assertion is both currently-failing and stable — unlike a
      line-anchored form, which the removal itself would invalidate by shifting every
      subsequent line.
- [ ] **AC-9 — The adopter drain path is documented on a surface adopters receive.**
      `release-aid` is repo-local and absent from `canonical/skills/`, so adopters have no
      drain skill; the drain is therefore recorded as a **documented manual step**. It lands
      in the `### backlog.md` block of
      `canonical/skills/aid-discover/references/document-expectations.md` — the block that
      tells a reader how items enter and leave that document, and a canonical file that
      renders to all five profiles. It does **not** land in
      `.aid/knowledge/authoring-conventions.md`: verified, that file has no template under
      `canonical/aid/templates/` (the `kb-authoring/` directory holds only `concern-model.md`,
      `domain-doc-matrix.md`, `frontmatter-schema.md`, `principles.md`, `review-rubric.md`,
      `tier-model.md`, and the 14 `knowledge-base/` templates do not include it) and no copy
      under `profiles/`, so an adopter never receives its text. Giving the drain an executable
      canonical home — a skill — remains **out of scope** and routed to tech-debt.
      *Oracle:* `grep -c drain canonical/skills/aid-discover/references/document-expectations.md`
      → `>= 1` with the hit inside the `### backlog.md` block, **and** the same count is
      `>= 1` in all five renders
      (`profiles/{claude-code/.claude,codex/.codex,cursor/.cursor,copilot-cli/.github,antigravity/.agent}/skills/aid-discover/references/document-expectations.md`).
      Today the count is `0` in canonical and in every render.
- [ ] **AC-10 — The filename→dimension map resolves all three documents, in both twins.**
      None of `roadmap.md`, `backlog.md`, `release-tracking.md` resolves to an empty spine
      dimension in `_dim_of_filename`.
      *Oracle:* the function is **not exported and not callable from a fresh shell**, and the
      two twins use different output globals (`kb-actback-task.sh:193-234` sets `_DIM`;
      `kb-dual-intent-probes.sh:214-255` sets `_DIM_OUT`) — neither echoes. Both scripts also
      invoke `_main` at load, so they cannot simply be sourced. The oracle therefore extracts
      the function and evaluates it:
      ```bash
      for f in kb-actback-task kb-dual-intent-probes; do
        eval "$(awk '/^_dim_of_filename\(\) \{/,/^\}$/' canonical/aid/scripts/kb/$f.sh)"
        for d in roadmap.md backlog.md release-tracking.md; do
          _DIM=""; _DIM_OUT=""; _dim_of_filename "$d"
          echo "$f $d -> ${_DIM}${_DIM_OUT}"
        done
      done
      ```
      Expected: `roadmap.md -> D`, `backlog.md -> C7`, `release-tracking.md -> C8`, six lines,
      identical across the two twins. Verified to run in this worktree: it prints `D` for
      `decisions.md`, `C7` for `tech-debt.md`, `C8` for `infrastructure.md`, and an empty
      dimension for all three of the documents above — so the oracle fails today and is
      satisfiable only by the edit.
- [ ] **AC-11 — `document-expectations.md` carries a block for each of the three.** The
      per-doc expectations file the matrix schema names as its join target
      (`domain-doc-matrix.md:58`) has a `### roadmap.md`, a `### backlog.md` and a
      `### release-tracking.md` block, each carrying the full four-part block anatomy the
      existing blocks use (§1b). Block content and its ownership split with feature-003 are
      specified in §3e.
      *Oracle:* `grep -cE '^### (roadmap|backlog|release-tracking)\.md' canonical/skills/aid-discover/references/document-expectations.md`
      → `3`, and no block is a bare heading: for each, the lines between the heading and the
      next `---` include a `**Red flags:**` line, matching the anatomy of the 24 blocks that
      exist today.
- [ ] **AC-12 — The matrix's own conditional tallies still describe the matrix.** Adding
      conditional rows falsifies three self-describing statements inside
      `domain-doc-matrix.md`; all three are corrected (§1d):
      `:124-126` (*"`decisions.md` is an **additive conditional** entry"* — written as though
      it were the only one in the `software-cli` row), `:148` (*"14 required docs (the seed) +
      1 conditional (`decisions.md`)"*), and the Seed-consistency bullet list at `:410-418`
      (inside `## Seed-consistency check`, `:381-429`), which enumerates the known conditional
      extensions. No test catches any of the three:
      `test-domain-doc-matrix.sh` filters on `\| required` (MT01/MT02, `:85`), MT06 counts only
      the 14 rows of the Seed-consistency *table* (`:213-216`), and MT17 (`:283-287`) asserts
      only that the section still contains the strings `decisions.md` and `NOT`.
      *Oracle:* the counted conditional rows and the prose tally agree —
      ```
      awk '/^### Domain: `software-cli`/{f=1} /^### Domain: `software-web`/{f=0} f' \
        canonical/aid/templates/kb-authoring/domain-doc-matrix.md | grep -c '| conditional'
      ```
      → `4` (it is `1` today), and `grep -n '4 conditional' domain-doc-matrix.md` returns the
      `:148` tally naming all four documents.
      **Constraint on the `:410-418` edit:** MT17 greps the whole Seed-consistency section for
      the literal strings `decisions.md` and `NOT`, so the three new bullets are **added**
      beside the `decisions.md` bullet, never in place of it. MT17 green is part of AC-3, and
      is the check that would catch a replace-instead-of-append edit here.

---

## Technical Specification

> **Section applicability.** Data Model, Feature Flow, and Layers & Components assume a
> code project; this feature produces a doctrine amendment, four registration surfaces,
> and three migrations. **N/A**. No conditional section auto-activates.

### 1. What this feature produces

**1a. No file under `canonical/aid/templates/` — that absence IS the mechanism.**

The `decisions.md` precedent settles it, and it was verified rather than assumed:
`find canonical/aid/templates -type f \( -iname '*decisions*' -o -iname '*roadmap*' -o -iname '*backlog*' -o -iname '*release-tracking*' -o -iname '*quality-gates*' \)`
returns **nothing**. The scope is `canonical/aid/templates` and files, matching this
section's own claim; an unscoped `find canonical …` also returns nothing today but stops
doing so the moment feature-003 lands its `aid-{design,create,update}-{roadmap,backlog}`
skill directories, whose basenames `-iname` matches -- so it cannot serve as a criterion that
survives the work. A conditional document has no template, and that is precisely how it
stays out of the four oracles that glob `canonical/aid/templates/knowledge-base/` (`AS06`'s
find-count, `test-doc-set-read.sh` T02, `test-domain-doc-matrix.sh` MT01/MT02's
byte-exact diff, and `gen-reference.test.mjs`'s `toHaveLength(14)` at `:260`).

**There is therefore no such thing as "the templates" in this feature** — not two, not three. Any
sentence in this spec — including its Change Log — in a task, or in a commit that speaks of
authoring, instantiating or verifying a template for `roadmap.md`, `backlog.md` or
`release-tracking.md` is describing the exact artifact §1a exists to prevent. The word does
not appear anywhere in this document in that sense; the one surviving instance in the
Change Log was corrected in the r5 pass rather than left standing behind a scoped
supersession.

**1b. The four registration surfaces.** CC-4 fixes the set at four and names this section as
the definition; every conditional KB document this work admits occupies all four or its
registration is partial. `decisions.md` occupies all four today, which is the precedent.

| # | Surface | Entry for `roadmap.md` / `backlog.md` / `release-tracking.md` |
|---|---------|----------------------------------------|
| 1 | `domain-doc-matrix.md` | A four-field row per domain (§1c) |
| 2 | `concern-model.md` | Named as conditional, each with its concern id (§2) |
| 3 | `document-expectations.md` | A `### <filename>` block — the join target the matrix schema names (`domain-doc-matrix.md:58`). Content and anatomy: §3e |
| 4 | `_dim_of_filename` | An entry in the filename→spine-dimension map, in **both** twins: `canonical/aid/scripts/kb/kb-actback-task.sh:193-234` and `canonical/aid/scripts/kb/kb-dual-intent-probes.sh:214-255`. Without it all three documents fall through to the catch-all (`_DIM=""` / `_DIM_OUT=""`) and contribute no owning-table rows to the presence check |

> **Correcting a claim r4 used to justify surface 3, and sizing the gap properly.** That draft
> asserted *"every conditional and extension doc on disk has one"*. False — and the review
> that caught it named six conditional docs plus three required non-seed ones as counter-
> examples, which is the visible tip. The full class was computed rather than sampled:
>
> ```bash
> awk '/^### Domain:/{d=1;next} /^## /{d=0} d && /^\| `/ {
>   split($0,f,"|"); gsub(/[ `]/,"",f[2]); if (f[2] ~ /\.md$/) print f[2] }' \
>   canonical/aid/templates/kb-authoring/domain-doc-matrix.md | sort -u > /tmp/matrixdocs
> grep -oE '^### [A-Za-z0-9._-]+\.md' \
>   canonical/skills/aid-discover/references/document-expectations.md \
>   | sed 's/^### //' | sort -u > /tmp/blocks
> comm -23 /tmp/matrixdocs /tmp/blocks | wc -l
> ```
>
> **58** distinct filenames appear across the eight domain tables; **24** `### <filename>`
> blocks exist; **36** of the 58 have no block — including every doc the review named
> (`experiment-log.md` matrix `:206`, `content-map.md` `:227`, `methodology.md` `:243`,
> `findings-log.md` `:248`, `limitations.md` `:250`, `evidence-map.md` `:251`,
> `dissemination.md` `:252`, `design-system.md` `:269`, `delivery-pipeline.md` `:277`) and 27
> more. The surface is mandatory because **CC-4 makes it mandatory** for the documents this
> work admits — not because the file is already exhaustive. It is not, and closing the
> 36-doc gap is a pre-existing defect this feature neither created nor widens, routed to
> tech-debt (§7).

**1c. The matrix row shape — four fields, not three.**

`domain-doc-matrix.md:53-61` defines a doc record as **four** fields:
`filename | spine-dimension | owner | presence`, where presence is
`required | conditional[:<when>]`. The three-field form
(`filename | owner | presence`) is the `discovery.doc_set` shape, not the matrix shape
(`:69-75`). Every conditional row on disk carries a `:<when>` clause, and no `<when>` may
contain a comma (`doc-set-resolve.md:41,51` — a comma is shredded by the parser; use `;`).

Rows to add, in the same column order the domain tables already use. The column padding below
is presentational only; the shipped domain tables use single spaces around each cell, and the
new rows follow that so AC-2's `grep -c` anchor matches. (Both matrix suites trim whitespace
and backticks when splitting fields, so padding would not break them — it would only make the
diff noisy.)

```
| `roadmap.md`           | D  | `skill-self` | conditional:project maintains a forward plan |
| `backlog.md`           | C7 | `skill-self` | conditional:project maintains a defined-and-prioritized backlog |
| `release-tracking.md`  | C8 | `skill-self` | conditional:project cuts versioned releases and records what shipped in each |
```

**Which domains.** All **eight** for all three
(`software-cli`, `software-web`, `data-ml`, `content`, `research`, `design`, `ops`,
`methodology-tooling` — the sections at `:121`, `:151`, `:183`, `:208`, `:231`, `:257`,
`:280`, `:303`). **24 rows.**

For `roadmap.md` and `backlog.md` this is not a judgment call: **CC-6** exempts them by name
as *"domain-agnostic and filename-stable by construction"*. `release-tracking.md` is not
named in CC-6, so its eight-domain treatment is this feature's decision, made on disk
evidence: `grep -n release domain-doc-matrix.md` returns four hits and **not one is a release
ledger** — `:11` is prose about the render pipeline, `:335` is a provenance-table cell, and
`:252` / `:277` are the `<when>` clauses of `dissemination.md` and `delivery-pipeline.md`,
which use the word *released* about publishing an artifact, not about recording what shipped.
No domain realizes a release ledger under any filename, so the filename-stability premise
CC-6 relies on holds for it too. The `<when>` clause carries the applicability, which is what
a conditional row is for.

> **Correcting r4's rationale for diverging from `decisions.md`'s row count.** That draft said
> `decisions.md` is absent from `data-ml` and `research` because *"a decision log is arguably
> domain-specific"*. That misreads the matrix. Both domains realize D — with a
> **domain-specific filename**, not with nothing: `data-ml` carries
> `experiment-log.md | D | ... | conditional:project records experiment results and the
> decisions drawn from them` (`:206`) and `research` carries `findings-log.md | D | ... |
> required` (`:248`), with the note at `:254-255` that *"`research` is the one common domain
> where `D` ... is **required** ... in research the rationale *is* the deliverable."* The real
> precedent is therefore CC-6's rule — **a concern resolves to whichever filename the domain
> uses** — and the divergence is that `roadmap.md` is filename-stable where the D *rationale*
> doc is not. `roadmap.md` sits alongside those docs under D rather than replacing them;
> multiple docs per dimension are already normal (`software-cli` C1 carries both
> `project-structure.md` and `architecture.md`).

> **Correcting a claim carried by three earlier drafts.** They asserted "`decisions.md`'s ten
> rows". `grep -n 'decisions.md' domain-doc-matrix.md` returns ten **lines**, of which only
> **six** are table rows (`:146`, `:176`, `:229`, `:278`, `:301`, `:322`); the other four are
> prose (`:124`, `:148`, `:384`, `:410`). And one of the six — `:322`, `methodology-tooling`,
> this repository's own declared domain — is `required`, not conditional.

**1d. Files this feature edits, and the adopter reach of each.**

The Reach column is load-bearing, not decoration: a change with `dogfood only` reach cannot
discharge an adopter-facing obligation (that is exactly the defect AC-9 corrects).

| File | Reach | Change |
|------|-------|--------|
| `canonical/aid/templates/kb-authoring/concern-model.md` | **canonical template → all five profiles** | Both amendments (§2), plus all three docs named as conditional |
| `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` | **canonical template → all five profiles** | The 24 conditional rows from §1c, **and** the three self-describing tallies AC-12 names: `:124-126`, `:148`, `:410-418` |
| `canonical/skills/aid-discover/references/document-expectations.md` | **canonical skill reference → all five profiles** | The three `### <filename>` blocks (§3e), including AC-9's manual drain paragraph in `### backlog.md` |
| `canonical/aid/scripts/kb/kb-actback-task.sh` | **canonical script → all five profiles** | Three arms added to `_dim_of_filename` (D / C7 / C8) |
| `canonical/aid/scripts/kb/kb-dual-intent-probes.sh` | **canonical script → all five profiles** | The identical three arms; the twins must not diverge (`:206` and `kb-actback-task.sh:183`, both *"Do not edit independently of domain-doc-matrix.md"*) |
| `.aid/knowledge/authoring-conventions.md` | **dogfood only** — no template under `canonical/`, no copy under `profiles/`; the file exists in this repo's KB and in three test fixtures only | Restates the amended doctrine for this repo's own KB (AC-1 oracle B). **It carries no adopter-facing obligation** |
| `.aid/knowledge/release-tracking.md` | **dogfood only** | `## Unreleased` removed; `objective:` / `summary:` / lede body rule updated (§4a) |
| `.claude/skills/release-aid/SKILL.md` | **dogfood only** — repo-local, not in `canonical/skills/` | §4b |
| `.aid/knowledge/INDEX.md` | dogfood only | **Regenerated**, never hand-edited (§4a) |
| `.aid/knowledge/relationships.md` | dogfood only | Regenerated via `/aid-graph` |
| `.aid/knowledge/kb.html` | dogfood only | Regenerated via `/aid-summarize` — the single re-run in feature-006 § *KB and methodology refresh*, not a second run here |

**What is genuinely unchanged:** `synth_default_seed`'s ownership map (AC-4), the seed count,
every required-set assertion, and every test script (AC-3). **Not** the Seed-coverage check —
see §2c.

**1e. What this feature does NOT edit, and why**

- **`.aid/settings.yml` `knowledge.doc_set` and `.aid/knowledge/README.md`'s two counts
  (`:21` and the Completeness table defined at `:35`) — per CC-2.** Those writes are effects
  of running `/aid-create-roadmap` and `/aid-create-backlog`; specifying them here as well
  would double-count. r4 assigned them to this feature in both §1e and §6; both assignments
  are removed.
- **`release-tracking.md`'s `doc_set` presence value.** `.aid/settings.yml:56` already reads
  `release-tracking.md|skill-self|required`, which is what CC-1 prescribes. No edit. Its
  *matrix* row is `conditional:<when>` (§1c) — the two answer different questions, per CC-1,
  and this spec does not re-argue that.
- **`roadmap.md` and `backlog.md` themselves — feature-003 creates them**, including this
  repo's instances. This feature has no shape to instantiate (§1a), so a step here ordering
  "instantiate them" would have no headings, no `kb-category`, and no `objective:` /
  `summary:` for `build-kb-index.sh` to read (`:293` emits *"(no objective declared)"* when
  `objective:` is absent). See §6.
- **`tech-debt.md`** — PR #183 already removed every work-named section; verified,
  `grep -cE '^### work-' .aid/knowledge/tech-debt.md` = `0`. Nothing for this feature to do.
- **`quality-gates.md`'s registration** — feature-004 (§7). It is partly registered already:
  `domain-doc-matrix.md:321` carries one row (`methodology-tooling`, C6, `required`), a
  `### quality-gates.md` block exists at `document-expectations.md:632`, and both
  `_dim_of_filename` twins resolve it to `C6`. Outstanding for feature-004: surface 2
  (`grep -c quality-gates concern-model.md` → `0`) and the other seven domains on surface 1.

**1f. Tests** — none change. That is the point of AC-3.

### 2. The two doctrine amendments

**2a. Governance artifacts.** Current text (`concern-model.md:63-73`,
§ "Why product-concerns, not governance-artifacts"):

> ... they map to AID's own **pipeline artifacts** (`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`,
> the per-work `STATE.md` tracking), which already exist. The KB is the product layer; the
> pipeline is the governance layer. A doc proposed for the KB that is really a governance
> artifact (a plan, a backlog, a register) is a scope smell -- route it to the pipeline, not
> the doc-set.

Keep the rule; add the distinguishing test it lacks — **scope**, not genre:

- **Per-work governance** (a sprint backlog, a work plan, a task register) remains
  banned. It maps to `REQUIREMENTS.md` / `SPEC.md` / `PLAN.md` / per-work `STATE.md`.
- **Project-level governance** (the roadmap, the backlog, the release ledger) is
  **admissible as a conditional document**, because the pipeline artifacts it would otherwise
  route to are per-work and transient — pruned when the work ships — leaving no durable home.

The rationale is **edited, not appended to**: the clause *"which already exist"* is the
premise the amendment overturns, so it is replaced rather than qualified. That is why AC-1's
oracle A is a zero-count on that exact string.

**2b. How a conditional doc arrives.** The shipped model admits a conditional doc
*"via the propose->confirm gate"* at discovery (`concern-model.md:110-112`) — an
`aid-researcher`-owned path. `roadmap.md` and `backlog.md` arrive differently: their owning
`create` skill writes them on first use, and no researcher can derive them from code. The
doctrine must admit **skill-created** conditional documents (`skill-self` as declared owner)
alongside discovery-proposed ones, or the mechanism FR-9 specifies has no home in the model
it cites. `release-tracking.md` is the third `skill-self` case and the reason the amendment
is written as a general rule rather than as two named exceptions.

**2c. §1d's "unchanged" list has one exception — the Seed-coverage check DOES change.**
`concern-model.md:161` is the `## Seed-coverage check` heading and the section runs to the
`---` at `:195`. The conditional statements live at `:181-188` (*"D (Decisions) is
conditional, NOT a seed doc"*) and `:189-193` (`repo-presentation.md` as a conditional
extension example) — **inside** it. So naming the three documents "alongside `decisions.md`
as conditional" necessarily edits that section. Three earlier drafts listed it as explicitly
unchanged while also requiring the edit; that contradiction is retired here.

What the edit does **not** do is change the seed **count** the section asserts. Adding
conditional statements to a section that already distinguishes conditional from seed
leaves the count alone — which is what AC-3 checks.

`backlog.md` (C7) and `release-tracking.md` (C8) additionally have no home in the `### D`
subsection at `:98-113`, the only conditional prose outside the check. They get their own
statements rather than being filed under D by proximity.

> **Pre-existing drift, not this feature's to fix.** `concern-model.md` says the seed is
> **15** docs in nine places (`:80`, `:82`, `:111`, `:153`, `:157`, `:163`, `:178`, `:183`,
> `:185`) while the matrix (`:148`) and `AS06` say **14**. This feature edits the
> Seed-coverage section without touching any of the nine, and routes the drift to
> `/aid-housekeep` (§7). Touching it would break AC-3.

### 3. Content model

**3a. Concern assignment.** `concern-model.md:94` defines **C9** as present-tense
realized capability, so it is wrong for a roadmap. **D (Decisions)** is right, and is
available precisely because these documents are conditional: `concern-model.md:96`
defines D's doc as *"conditional, not a seed doc"*. A roadmap entry is a committed
decision — "we have decided to do X next", true now, with a rationale — the same
argument §2a rests on. `backlog.md` takes **C7**, as a sibling of `tech-debt.md`
(`:92` — *"What is risky, owed, or worked around?"*; an accepted-but-unshipped item is
owed). `release-tracking.md` takes **C8** (`:93` — *"How does it ship and run?"*), matching its own
frontmatter (`tags: [C8, ...]`) and its `README.md` Completeness row (`| 16 |
release-tracking.md | C8 | skill-self |`).

**3b. Shape belongs to feature-003, wholly, for the two new documents.** Because there is no
template, the structure of `roadmap.md` (including the `## MVP` anchor, whose ownership is
CC-5's) and `backlog.md` is defined by `/aid-create-roadmap` and `/aid-create-backlog` — the
same way `decisions.md`'s shape lives with whatever authors it. This feature owns
**membership and doctrine**; feature-003 owns **shape and creation**, including this repo's
instances. `release-tracking.md` is the exception: it already exists with a settled shape, so
this feature owns its block content outright (§3e).

**3c. The promotion criterion is a decision, not a derivable property.**

An earlier draft said an item moves from `tech-debt.md` to `backlog.md` once it "has a
definition and a priority". That criterion is degenerate against the artifact it
triages: `.aid/knowledge/tech-debt.md:73`'s header is
`| ID | Type | Description | Location | Risk | Effort | Priority |` and **every** inventory
row already carries both — so the rule promotes the entire inventory on day one.

The real distinction REQUIREMENTS.md draws is *scheduling*: `tech-debt.md` holds items
nobody has committed to, `backlog.md` holds items someone has. That is an explicit human
decision, not a property readable off the row. So the criterion is stated as such — an
item moves when it is **accepted into the plan**, and the acceptance is the event. The
mechanism belongs to `/aid-*-backlog` (feature-003), not here.

**3d. Neither new document carries a `## Change Log`, a `changelog:` field, or a work
reference.** PR #183 resolved the edit-history doctrine on master while this work was in
Specify: zero KB docs and zero canonical templates carry the section, and the standard
now asserts its **absence** via `AS03`, `AS03b` and `AS03c`. Verified in this worktree
(merge `9260fc88`).

But see AC-5: those three assertions are **template-scoped**. They cannot judge a
document with no template, so the oracle for the two instances is a direct grep, not a
citation of AS03.

**3e. What the three `document-expectations.md` blocks contain, and who writes each part.**

Every existing block follows a fixed four-part anatomy — verified against
`### decisions.md` (`:667-682`), `### quality-gates.md` (`:632`) and
`### capability-inventory.md` (`:649`):

1. A bold **what is this document** paragraph, phrased as the question the doc answers.
2. An italic `*(Investigate: ...)*` clause naming what to ground it in.
3. An **Operational open question:** line naming a `##` section to surface.
4. A **Red flags:** line, whose first clause is almost always *"Duplicates `<sibling>.md`"* —
   the boundary against the nearest neighbour.

Parts 1–3 are shape, so for `### roadmap.md` and `### backlog.md` they come from feature-003
(§7, inbound). This feature owns, in every case:

- **Part 4 for all three**, because the red flags are boundary statements between documents
  and boundaries are membership: `roadmap.md` vs `backlog.md` (direction vs items),
  `backlog.md` vs `tech-debt.md` (accepted vs merely observed), `backlog.md` vs
  `release-tracking.md` (pending vs shipped), and `roadmap.md` § MVP vs the rest of
  `roadmap.md` (CC-5).
- **The item-flow sentence** in `### backlog.md` — how an item enters (from `tech-debt.md`,
  §3c) and how it leaves.
- **AC-9's manual drain paragraph**, in `### backlog.md`, stating that at release time the
  committed items are moved out of `backlog.md` into a new `release-tracking.md` version
  section, that AID ships no adopter-facing skill that does this, and that it is therefore a
  manual step. This is the same operation §4b automates for this repo only.
- **All four parts of `### release-tracking.md`**, since that document's shape is already
  settled and no other feature owns it.

The three blocks are appended after `### decisions.md`, the current last block
(`document-expectations.md:667-682`), preserving the `---`-separated block form the file uses
throughout.

### 4. Migrations

**4a. `## Unreleased` → `backlog.md`.** Carriers beyond the section itself:

| Carrier | Detail | Hand-edited or regenerated |
|---|---|---|
| `release-tracking.md` frontmatter + lede | `objective:` (`:4`), `summary:` (`:5`), body rule (`:18`, `:20`, `:21`) | hand |
| `INDEX.md:61` | The duplicated `release-tracking.md` summary — **`:61`, not `:63`**; line 63 is the closing `---` rule | **regenerated** |
| `relationships.md` | Three `kb:release-tracking.md#unreleased` rows (`:2555`, `:2859`, `:3467`) | regenerated |
| `kb.html` | **Eight occurrences on seven lines** (`:3648`, `:3724`, `:3731`, `:3736`, `:3740`, `:3741` ×2, `:3751`) | **regenerated** — by feature-006's single `/aid-summarize` re-run (its § *KB and methodology refresh*), which is where AC-6's `kb.html` conjunct is evaluated. Not hand-patched here, and not a second run here |

`INDEX.md` is **regenerated, not hand-edited** — `build-kb-index.sh:276-296` composes each
row from the doc's own `objective:` / `summary:` frontmatter and `:451` stamps
*"DO NOT EDIT - regenerate with: ..."*. A hand edit here is reverted by §6's own final
step. Three earlier drafts classified it as hand-edited in this section while listing it
as regenerated eleven lines earlier.

**Not touched:** `.aid/knowledge/STATE.md:203` mentions `## Unreleased` inside a
historical, append-only Q&A entry recording what was true then. AC-6's oracle asserts a
clean diff on that file precisely so a repo-wide sweep cannot quietly eat it.

**4b. `release-aid` rewire.** In `.claude/skills/release-aid/SKILL.md`, whose relevant step is
**"Step 3 — Update documentation & release notes"** (`:96`), sub-steps `### 3.1 — Release
notes / changelog ledger` (`:101`) and `### 3.2 — Documentation sync` (`:111`):

| Location | Today | After |
|----------|-------|-------|
| § 3.1, `:103-105` | Renames `## Unreleased` to the version heading, opens a fresh empty one | Reads committed items from **`backlog.md`**, writes a new `release-tracking.md` version section, removes them from `backlog.md` |
| § 3.1, `:105` | *"Add a row to the file's trailing `## Change Log` table."* — dead since PR #183 | Removed (AC-8) |
| § 3.1, `:106-109` sanity check (still inside 3.1 — § 3.2 begins at `:111`) | *"Unreleased holds already-shipped items"* | Restated against `backlog.md`'s committed slice |
| Step 4, `:157` | `git add .aid/knowledge/release-tracking.md  # ledger rename (Step 3.1)` | Also stages `.aid/knowledge/backlog.md` |
| Step 9, `:251` | Verifies *"the next run starts from a clean Unreleased"* | Verifies the drained items are absent from `backlog.md` and present in the new version section |

`backlog.md` is the source, not `roadmap.md`. Feature-003 must match this; its earlier
draft had `release-aid` draining from `roadmap.md`, citing this section for a claim this
section does not make.

This is a **dogfood-only** rewire (§1d). The adopter-facing counterpart is AC-9's documented
manual step; a canonical skill for it is out of scope (§7).

**4c. `tech-debt.md`** — nothing to do; PR #183 removed every work reference. The only
two `.aid/knowledge/*.md` files still matching `work-[0-9]{3}` are `relationships.md`
(generated) and `release-tracking.md` (release history, where a work reference is a
historical fact rather than a citation) — verified by
`grep -lE 'work-[0-9]{3}' .aid/knowledge/*.md`.

### 5. Verification

Every row below backs exactly the criterion named in its **AC** column, and each of the twelve
criteria has at least one row: AC-1 → 2, 3; AC-2 → 4; AC-3 → 1; AC-4 → 7; AC-5 → 9; AC-6 →
10, 14; AC-7 → 11; AC-8 → 12; AC-9 → 13; AC-10 → 6; AC-11 → 5; AC-12 → 8. Row 15 carries `—`
because it is a hand-off to feature-006, not a criterion of this feature.

| # | Check | AC | Oracle |
|---|---|---|---|
| 1 | **No test script moved** | AC-3 | `test-kb-template-authoring-standard.sh`, `test-doc-set-read.sh`, `test-doc-set-mapping.sh`, `test-domain-doc-matrix.sh`, `test-spine-depth-coverage.sh` green, plus `npx vitest run gen-reference` from `site/` — six oracles, five of them bash and one not; **and** `git diff --exit-code -- tests/canonical/ site/scripts/__tests__/`. Scoped to the suite scripts, never to the files under test (AC-3) |
| 2 | Doctrine amended — canonical | AC-1 | AC-1's three section-scoped counts: `which already exist` → `0` (1 today), `project-level` → `>= 1` (0 today, section-scoped — it is 2 file-wide), `skill-created` → `>= 1` (0 today) |
| 3 | Doctrine amended — dogfood | AC-1 | `grep -c 'project-level' .aid/knowledge/authoring-conventions.md` → `>= 1` (`0` today), with the hit in the sentence at `:236` that currently states the unqualified ban |
| 4 | Matrix rows + concern-model entries | AC-2 | 8 rows per document × 3 documents = 24; each named as conditional in `concern-model.md` |
| 5 | Expectations blocks | AC-11 | `grep -cE '^### (roadmap\|backlog\|release-tracking)\.md' document-expectations.md` → `3`, each with a `**Red flags:**` line |
| 6 | Dimension map resolves | AC-10 | The extract-and-eval loop in AC-10: `D` / `C7` / `C8`, six lines, both twins |
| 7 | Not in the ownership map | AC-4 | The anchor-scoped `awk`+`grep -c` in AC-4 → `0` |
| 8 | Matrix self-tallies | AC-12 | `software-cli` conditional row count `4` **and** the `:148` prose says 4, naming all four; `:124-126` and `:410-418` updated; MT17 still green |
| 9 | C-3 compliance of the two instances | AC-5 | Direct grep over the two files; **not** AS03/AS03b/AS03c, which cannot see them |
| 10 | `## Unreleased` gone, everywhere it was described | AC-6 | `grep -c Unreleased` → `0` in `release-tracking.md` (from 6), `INDEX.md`, `kb.html`; `grep -c 'release-tracking.md#unreleased' relationships.md` → `0`; `git diff --exit-code -- .aid/knowledge/STATE.md` clean. **When each conjunct is evaluated:** the hand-edited and script-regenerated carriers at this feature's close; the `kb.html` conjunct after feature-006's `/aid-summarize` re-run (§6 step 6, §7 *Outbound*) — it is satisfiable rather than deferred-indefinitely, since the file is regenerated from the very `release-tracking.md` this feature drains |
| 11 | Release flow rewired | AC-7 | `grep -c Unreleased .claude/skills/release-aid/SKILL.md` → `0`; § 3.1 names `backlog.md` |
| 12 | Dead Change Log instruction gone | AC-8 | `grep -c 'Change Log' .claude/skills/release-aid/SKILL.md` → `0` (from 1) |
| 13 | Manual drain documented where adopters get it | AC-9 | `grep -c drain` → `>= 1` in canonical `document-expectations.md` inside `### backlog.md`, **and** in all five profile renders |
| 14 | Index regenerated | AC-6 | `bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md` leaves no diff when re-run |
| 15 | Render parity | — | Full `run_generator.py` + byte-identity gate (feature-006). The four canonical files in §1d render to all five profiles |

Row 1 is load-bearing: if any of those six oracles needed *editing*, the conditional decision
was not implemented. There is deliberately **no** doc-set-count row: per CC-2 this feature
writes no `doc_set` entry and no `README.md` count, so it has nothing to assert about them.

### 6. Sequencing

1. **§2** — the doctrine amendments. They must land before the documents are *reviewed*,
   and before §1b surface 2 can name them as conditional.
2. **§1b–§1d** — the four registration surfaces for all three documents, the matrix
   self-tallies (AC-12), and the `### release-tracking.md` block in full (§3e).
3. **§4a–4b** — the `## Unreleased` migration and the `release-aid` rewire. Depends on step 2
   only for doctrine; the drain paragraph it references is written in step 5.
4. *(feature-003)* — `roadmap.md` and `backlog.md` are created, with their shape, and the
   `create` skills perform CC-2's `settings.yml` + `README.md` registration.
5. **§3e completion** — the shape-derived parts of `### roadmap.md` and `### backlog.md`
   land, together with AC-9's drain paragraph. This step is **after** step 4 by necessity:
   parts 1–3 of those two blocks are feature-003's to supply (§7).
6. Regenerate the two **script**-generated summaries — `INDEX.md`
   (`build-kb-index.sh`) and `relationships.md` (`/aid-graph`). **`kb.html` is not
   regenerated here.** It is the one summary whose regeneration is an authored
   `/aid-summarize` run rather than a script (~24 min, and its visual gate is an
   orchestrator step because Playwright is not installed in the summarize package), and
   the KB convention is that final-state summaries are refreshed **once**, after the
   roster settles. So it runs exactly once, in feature-006 § *KB and methodology
   refresh*, and §5 row 10's `kb.html` conjunct is evaluated there. This is a hand-off,
   not a dropped carrier: the file is rebuilt from the same `release-tracking.md` this
   feature drains, so the migration reaches it.

Steps 5 and 6 sit downstream of a feature-003 deliverable. That hand-off is real, is stated
rather than hidden, and is recorded in §7 as an inbound dependency.

No atomic-group constraint applies, because no test assertion changes — the direct
dividend of the conditional decision.

### 7. Dependencies

**Outbound — what this feature blocks.**

- **Blocks feature-003** on doctrine and membership: `/aid-*-roadmap` and `/aid-*-backlog`
  cannot legitimately write a KB document until §2b admits skill-created conditional docs,
  and cannot be registered until §1c's rows exist. There is **no template** for feature-003
  to depend on.
- **Blocks feature-003** on §4b's drain source (`backlog.md`, not `roadmap.md`) and on the
  `## MVP` anchor's existence as a concept — though its position is feature-003's to define
  (§3b) and its ownership is CC-5's.
- **Blocks feature-004** on §2b, for the same reason, and defines the four surfaces
  (**CC-4**) that feature-004 must occupy for `quality-gates.md`. Its partial existing
  registration is inventoried in §1e.
- **Hands to feature-006** — the render and the byte-identity gate for the four canonical
  files in §1d. **No count sweep**, since no skill count and no seed count moves.
- **Hands to feature-006** — the `kb.html` regeneration (§6 step 6). It is the `## Unreleased`
  migration's one remaining carrier, and it is discharged by feature-006's single
  `/aid-summarize` re-run rather than by a run here, because it is an authored ~24-minute
  run over a KB that is still moving until the roster settles. §5 row 10 names it as the
  conjunct evaluated there.

**Inbound — what this feature depends on.**

- **Depends on feature-003** for the `roadmap.md` and `backlog.md` **instances**. This
  feature registers membership for documents it does not create (§1e), which is legitimate
  only because conditional membership does not require the file to exist.
- **Depends on feature-003** for **parts 1–3 of the `### roadmap.md` and `### backlog.md`
  blocks** (§3e). feature-003's own spec states it hands that content back here; this is the
  matching inbound edge, and §6 step 5 is where it lands. Without it AC-11 can only be
  satisfied by bare headings, which its oracle rejects.
- **Delegates to feature-003 — not a blocking dependency —** CC-2's `settings.yml` +
  `README.md` registration. This feature has no obligation left there, which is why §1e
  *removes* those edits rather than merely reordering them, and why §5 carries no
  doc-set-count row. feature-003's V15 is the check that they happen.
- **Independent of feature-002** — touches no skill machinery.

**Out of scope, routed to tech-debt.**

- Giving the adopter-facing release drain an **executable** canonical home (a skill). AC-9
  documents it as a manual step on an adopter-reaching surface; automating it is a separate
  work.
- The **36 of 58** matrix docs with no `### <filename>` block in `document-expectations.md`
  (§1b, computed not sampled) — a pre-existing gap this feature neither created nor widens.
  It does not block anything here: `test-spine-depth-coverage.sh` SD04/SD05 resolve a doc's
  depth contract through its `### C<N>` dimension block, and the per-filename block is
  additive on top of that floor (`document-expectations.md:77-78`).
- The pre-existing stale 15-vs-14 seed drift between `concern-model.md` and the matrix
  (§2c) — route to `/aid-housekeep`.
