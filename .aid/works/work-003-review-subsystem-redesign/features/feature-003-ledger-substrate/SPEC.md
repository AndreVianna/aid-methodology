# Ledger Substrate

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-27 | Feature identified from REQUIREMENTS.md §5.D (FR-D1..D3) and §5.B (FR-B8), §9 (AC-9) | /aid-define |

## Source

- REQUIREMENTS.md §5 group D — FR-D1, FR-D2, FR-D3
- REQUIREMENTS.md §5 group B — FR-B8 **cut 2026-07-27**; this feature holds three FRs
- REQUIREMENTS.md §9 — AC-9
- REQUIREMENTS.md §2 — problem 4 (a review cannot be resumed)

## Description

The ledger records what is wrong. It does not record what was examined. That means an
interrupted review cannot tell the difference between "I checked this file and it was clean"
and "I never reached this file" — both look identical, because both are the absence of a row.

This feature turns the ledger into a record that can answer both questions. The same
7-column table gains two more row kinds alongside findings: `U-NNN` rows tracking coverage
unit by unit, and `G-NNN` rows recording gap and interrupt events. Both carry `—` in the
severity column, which the grading script ignores by construction — it counts a row only
when severity is exactly a bracketed enum value and status is exactly `Pending` or
`Recurred`. So the manifest can live in the ledger without touching the grade, and without
changing the grader at all.

It also fixes a live hazard. The reviewer currently writes the ledger by overwriting the
whole file with a heredoc, re-emitting every prior row each time. The agent body itself
warns that getting this wrong silently truncates all previous findings. Checkpointing after
every unit would multiply that risk by the number of units. This feature replaces it with a
surgical row-update helper, modelled on the existing state-writeback helper.

## User Stories

- As a **pipeline agent**, I want to record which units I have examined so that whatever runs next knows where I stopped.
- As an **AID maintainer**, I want coverage tracking to live in the ledger without affecting the grade, so that adding it cannot silently change a project's scores.
- As an **AID maintainer**, I want row updates to be surgical so that a checkpoint cannot truncate the findings recorded before it.
- As an **adopter project**, I want to open a ledger mid-review and see how far it got.

## Priority

Must

## Acceptance Criteria

<!-- Carried across from REQUIREMENTS.md section 9 by the decomposition rule: a mapped criterion keeps
     the modality it had there. Modality is what step 1 of the severity scale reads, so a criterion
     without one makes every finding against it ungradeable. The checklist below elaborates these
     rows; it is not a second set of criteria. Gated by aid/scripts/kb/lint-modality.sh. -->

| ID | Modality | Criterion |
|----|----------|-----------|
| AC-9 | MUST | Adding coverage and gap rows to a ledger does not change the grade `grade.sh` computes for the same findings. |

- [ ] **AC-9** — Given a ledger, when coverage and gap rows are added to it, then the grade computed for the same findings is unchanged.
- [ ] Given a ledger, when it carries all three row kinds, then findings, `U-NNN` and `G-NNN` rows are distinguishable by their `#` prefix and all sit in the same 7-column table.
- [ ] Given a coverage or gap row, when the grader parses it, then it is ignored because its severity column holds `—`.
- [ ] Given a coverage row, when I read it, then its status is one of `Unexamined`, `In Progress`, `Examined`, `Skipped`.
- [ ] Given a gap row, when I read it, then its status is `Open` or `Resolved`, and it records the skill triggered and the resume count.
- [ ] Given the row-update helper, when one row is updated, then the rest of the table is byte-identical and no row is renumbered.
- [ ] Given a review that checkpoints after every unit, when it completes, then the number of full-file rewrites is zero.
- [ ] Given the ledger, when the table shape is inspected, then it remains valid so the grader's legacy prose-counting fallback is never reached.

## Notes for Specify

- **This feature edits `canonical/agents/aid-reviewer/AGENT.md`** — it deletes the entire `## File Writing` section with its `cat >` heredoc instruction and truncation warning (FR-D3), and restates the output contract for three row kinds (FR-D1).
- **It also changes `canonical/aid/templates/reviewer-ledger-schema.md`**, which currently asserts "exactly one markdown table" and "every row is one finding". Both stop being true. This is a specification change, not a parser change. Related: STATE.md Q7 #8 notes that no FR explicitly owns rewriting the schema's lifecycle section, which FR-D5 contradicts — decide here or in feature 5.
- **Verified compatible with `grade.sh` as designed.** Its awk path requires `cols[3]` to equal a bracketed enum value exactly *and* `cols[4]` to equal `Pending` or `Recurred`. Confirm this still holds during implementation; NFR-1 forbids changing that logic.
- **Parallel dispatch:** under `aid-discover`'s parallel mandate reviews each reviewer writes its own scratch ledger, so coverage rows must be partitioned per mandate or the orchestrator's merge will collide.
- **No rule yet for in-flight ledgers** written under the old schema (STATE.md Q7 #10). This feature needs to state one.
- **FR-B8 was CUT (2026-07-27).** This feature holds three FRs and keeps AC-9. It still ships value independently — retiring the live truncation hazard in the current `cat >` ledger write, and making an interrupted review's coverage legible before formal resume exists. If a three-FR substrate feature is judged too thin, the stated fallback is to merge it forward into feature-004, its only consumer.
- **New requirement inherited from feature-002:** the surgical write helper is the single writer of ledger rows, so it is the **only** thing that can mechanically enforce AC-3 — reject a finding row carrying `--` in the `Rule` column. `grade.sh` cannot do this under NFR-1. Feature-002's spec names this as a dependency it creates on this feature; pick it up as a helper requirement.
- **The table is 8 columns, not 7**, once feature-002's FR-B10 lands. This feature's row kinds extend the already-widened table. Non-finding rows (`U-NNN`, `G-NNN`) carry `--` in both `Severity` and `Rule`.
- **This feature must state the mixed-shape migration rule** for a ledger that spans the 7→8 column change mid-review (STATE.md Q7 #10, restated by feature-002 §12).

---

## Technical Specification

> Authored by `/aid-specify` on 2026-07-27. Adapted sections — the "runtime" here is agents
> reading documents plus one shell script. No store, no request flow, no DI container, no
> network or UI surface.

### 1. The row-kind schema

One table, three row kinds, distinguished by the `#` column. **Eight columns** after
feature-002's FR-B10 lands.

```
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
```

| Column | Finding | Coverage unit | Gap / interrupt event |
|---|---|---|---|
| `#` | `NNN` or `<NS>-NNN` | `U-NNN` or `U-<NS>-NNN` | `G-NNN` or `G-<NS>-NNN` |
| `Severity` | one of the five bracketed tokens | `--` | `--` |
| `Status` | `Pending \| Fixed \| Recurred \| Accepted \| OOS \| Invalid` | `Unexamined \| In Progress \| Examined \| Skipped` | `Open \| Resolved` |
| `Rule` | a catalog rule ID; **mandatory** (one exemption, §4) | `--` | `--` |
| `Doc` | the artifact the finding is about | the unit's artifact | the artifact whose review stalled |
| `Line` | line, range, or `--` | `--` | `--` |
| `Description` | one sentence: what is wrong | `rule-set: <name>`, plus a skip reason when `Skipped` | which criterion is missing |
| `Evidence` | disk truth, or the command producing it | UTC checkpoint stamp `; art=<digest>; rs=<rule-set>@<digest>` | the resolution command, plus `resume=N` |

> **Amended 2026-07-27 at feature-005's request.** The coverage row's Evidence cell was
> originally just a UTC stamp. It now also carries two helper-generated digests: `art=` is
> `sha256sum` of the artifact (truncated), and `rs=` is `sha256sum` over the rule-set catalog
> file plus every distinct path appearing in that rule set's `Criterion` cells. Both use the
> idiom already in the tree at `canonical/aid/scripts/kb/kb-dual-intent-probes.sh` with the
> `sha256sum`/`shasum -a 256` fallback from `lib/aid-install-core.sh`. Feature-005 needs them
> for FR-D6's invalidation-on-resume; they are grade-inert because they ride in `Evidence`,
> past `cols[4]`. Same amend-upstream-rather-than-annex precedent as STATE.md Q13.

**ID grammar — one regex for all three kinds:**

```
^(U-|G-)?([A-Z][A-Z0-9]{0,3}-)?[0-9]{1,4}$
```

The optional middle segment is the *writer namespace*, used only when one logical review has
several writers (§7). Absent in the common single-writer case.

**Worked rows** — these are the exact rows run through `grade.sh` during design:

```markdown
| # | Severity | Status | Rule | Doc | Line | Description | Evidence |
|---|---|---|---|---|---|---|---|
| U-001 | -- | Examined | -- | foo.md | -- | rule-set: KB | 2026-07-27T10:00:04Z |
| 1 | [HIGH] | Pending | KB-22 | foo.md | 42 | claim wrong: doc says 7, disk shows 9 | `ls \| wc -l = 9` |
| U-002 | -- | In Progress | -- | bar.md | -- | rule-set: KB | 2026-07-27T10:04:11Z |
| 2 | [MINOR] | Fixed | SPEC-03 | bar.md | 7 | heading level wrong | corrected cycle 2 |
| G-001 | -- | Open | -- | baz.sh | -- | no shell coding standard declared for this class | /aid-update-kb coding-standards; resume=1 |
| 3 | [MEDIUM] | Recurred | CODE-12 | baz.sh | 15 | off-by-one in the loop bound | `wc -l = 8`, code asserts 9 |
| U-003 | -- | Skipped | -- | qux.md | -- | rule-set: SPEC; blocked by G-001 | 2026-07-27T10:09:02Z |
```

Namespaced variant, for `aid-discover`'s M1 mandate: `| M1-007 | [HIGH] | … |` for a finding,
`| U-M1-004 | -- | Examined | … |` for its coverage.

**Two vocabulary decisions.** Non-applicable cells use `--`, matching feature-002's `Rule`
sentinel and the STATE templates' null sentinel — not the em-dash `—` the schema currently
uses in its `Line` examples. `grade.sh` ignores both, so existing `—` cells are not migrated;
the rule binds new rows only. And the checkpoint stamp is generated by **the helper**, not the
agent, via `date -u +%Y-%m-%dT%H:%M:%SZ` — the same shell-generated-timestamp discipline
`subagent-heartbeat-protocol.md` already imposes.

**Collision analysis.**

- `grade.sh` reads `cols[3]` and `cols[4]` only. The `#` column is touched exactly twice, at
  lines 201–202, and both are header guards testing `cols[3]` — never `cols[2]`. The `#`
  content is unread by the grader for any data row. Confirmed by running the fixtures above:
  identical grade whether `#` holds integers or `U-`/`G-` IDs.
- **No other mechanical ledger parser exists.** No script under `canonical/aid/scripts/`
  references `review-pending`; every other reader is an agent reading prose.
- **`aid-discover`'s prefixed IDs keep working.** `state-review.md` step 2a identifies a
  mandate's rows by `#` prefix (`M1-`, `M2-`, `TB-`, `AB-`) and assigns next-free IDs within
  each namespace. `U-`/`G-` collide with none of them.
- **No collision with rule IDs.** Rule IDs live in `Rule` and match
  `^[A-Z]{2,12}-[0-9]{2}$` — two or more uppercase letters, so `U-001` and `G-001` are not
  expressible as rule IDs even if the columns were crossed. Disjoint by construction.

### 2. Grade inertness and its proof

FR-D2 and AC-9. Non-finding rows are ignored **by construction, not by convention**: a row
counts only when `cols[3]` is exactly one of the five bracketed tokens *and* `cols[4]` is
exactly `Pending` or `Recurred`. The severity match is the `if (severity == "[CRITICAL]") …
else next` chain at **`grade.sh` lines 207–212**; the status filter is line **215**
(`if (status != "Pending" && status != "Recurred") next`). Lines 195–198 are the preceding
column reads (`n < 5` guard, then `severity = trim(cols[3])`, `status = trim(cols[4])`), not
the guard itself. A `--` in Severity fails the chain at 207–212, so the Status value at 215
is never reached.

That is why the coverage vocabulary can safely contain words that look grade-bearing — see
the negative controls in §9.

### 3. The surgical write helper

`canonical/aid/scripts/review/writeback-ledger.sh`, following
`execute/writeback-state.sh`'s conventions: long flags only, mode inferred from the flag
combination, `die()` with a numeric exit code, write to `mktemp` → sanity-check → `mv`.

`EMISSION-MANIFEST.md`'s `canonical/aid/scripts/` → `<root>/aid/scripts/` mapping is
**directory-level**, so a new `review/` subdirectory should emit to all five profiles without a
manifest edit.

**That expectation must still be confirmed by rendering — but for a narrower reason than this
paragraph originally gave.** The first draft claimed the five rendered manifests are *stale*,
because they carry `"src": "canonical/scripts/grade.sh"` while the script lives at
`canonical/aid/scripts/grade.sh`. **That was a misreading, retracted during execution on
2026-07-28:** `render.py` deliberately normalizes `canonical/aid/<sub>/` to `canonical/<sub>/` in
the manifest `src` field, with the stated reason *"for manifest src stability (downstream
traceability paths unchanged)"*. The field is a **stable logical identifier, not a filesystem
path**, and is correct as generated. There is no pre-existing defect here and nothing was logged
to the Q3 backlog.

The verification requirement stands on its own footing: **a subdirectory that has never been
emitted has never exercised the mapping**, so implementation must confirm the new `review/`
subdirectory reaches every profile rather than inferring it from the directory-level rule.

The helper locates `grade.sh` as `"$(dirname "$0")/../grade.sh"` — a relative path with no
`canonical/` prefix, so `rewrite_install_paths` has nothing to rewrite and resolution is
identical in canonical and in every rendered tree.

**Four write modes and one query mode:**

```bash
writeback-ledger.sh --ledger PATH --append-finding \
    --severity '[HIGH]' [--status Pending] --rule KB-22 \
    --doc foo.md [--line 42] --description '...' --evidence '...' [--namespace M1]

writeback-ledger.sh --ledger PATH --append-unit \
    --unit foo.md --rule-set KB [--status Unexamined] [--stamp ISO8601] [--namespace M1]

writeback-ledger.sh --ledger PATH --append-gap \
    --gap-key <stable-key> --doc baz.sh --description '...' \
    --resolution '/aid-update-kb coding-standards' [--status Open] [--namespace M2]

writeback-ledger.sh --ledger PATH --set-status --row-id U-002 --status Examined

writeback-ledger.sh --ledger PATH --row-id U-002 --get-status     # read-only
```

**Behaviour that matters:**

- **`#` is assigned by the script, never by the caller.** Next free integer for findings; next
  free `U-NNN`/`G-NNN` within the kind and namespace. Existing rows are never renumbered —
  byte-invariance holds because no prior row's bytes are ever regenerated by the model.
- **`--set-status` is the only in-place mutation and rewrites exactly one cell.** Every other
  cell of the target row is reproduced verbatim; every other row is copied byte-for-byte.
  Status is validated against **the target row's kind**, so
  `--set-status --row-id U-002 --status Recurred` is rejected.
- **`--append-gap` is idempotent on `--gap-key`**, following `--append-issue`'s precedent. A
  repeated key appends no row; it increments `resume=N` on the existing `G-NNN` row and prints
  `OK: … duplicate gap key G-001 (recurrence, resume=2)`. That gives feature-005 a mechanical
  recurrence signal without this feature deciding the halt policy.
- **File creation.** `--append-*` creates the ledger with an 8-column header when absent,
  mirroring `mode_append_issue`. `--set-status` and `--get-status` require an existing file.
- **Pipes are escaped, not rejected.** `writeback-state.sh` rejects `|` because the STATE table
  has no escape; the ledger schema defines one (`\|`), so the helper escapes `|` → `\|` in
  `--description` and `--evidence`. Grader-safe: the closed-vocabulary columns and the path
  column cannot contain a pipe, so an escaped pipe can only land after `cols[4]`.
- **Raw newlines are rejected** (exit 4), same class as `writeback-state.sh`'s newline guard.
- **CRLF and trailing-newline invariance** are inherited wholesale from `wb_set_frontmatter`'s
  guards: normalize to LF, run the awk pass, restore `\r` per line, strip the spurious
  terminator only when the source genuinely lacked one. Ledgers are written on Windows too;
  without this the byte-invariance AC fails on the first Windows checkpoint.
- **A sentinel lock is inherited from `writeback-state.sh`** (~20 lines, already written and
  tested). Today's single-writer invariant makes it unnecessary, but FR-D5 makes the
  orchestrator a second writer of the same file two features from now. Exit 2 is documented as
  a **bug signal**, not a normal path.
- **Post-write sanity checks**, original preserved on any failure: output non-empty; header row
  byte-identical to input; data-row count equals expected (+1 append, +0 set-status); target row
  present. For `--append-unit` and `--append-gap`, additionally **`grade.sh` on the pre-image
  and the post-image must return the same grade** — AC-9 enforced at write time, not only in a
  fixture. **Default-on**, with `--no-verify-grade` as an escape hatch. One extra awk pass over
  a 3–10 KB file is unmeasurable; the property is this feature's headline claim.

**Exit codes**, aligned with `writeback-state.sh`:

| Code | Meaning |
|---|---|
| 0 | success |
| 1 | ledger unreadable, or parent directory absent |
| 2 | lock contention — a bug signal |
| 3 | write produced empty or unverifiable output; original preserved |
| 4 | invalid argument — bad severity token, status illegal for the row kind, `--` in `Rule` on a grade-bearing finding, raw newline, `--rule` against a 7-column ledger |
| 5 | missing required argument |
| 6 | malformed ledger — no header, or a header that is neither 7 nor 8 columns |
| 7 | `--row-id` not found |

**Checkpoint cost, measured.** The 51 real ledger data rows that exist as examples across
`canonical/`, `.aid/knowledge/` and `tests/` average 111 bytes, max 327. A 30-row ledger is
therefore 3.3–10 KB of table.

*Today, per checkpoint:* the reviewer reads the whole ledger and re-emits the entire table
inside a `cat >` heredoc — roughly 0.9–2.5k output tokens, plus a comparable read, plus one
opportunity to truncate every prior finding. Over 21 units (this repo's own KB review size)
that is 20–50k output tokens spent re-typing rows the model already wrote, and 21 truncation
opportunities.

*With the helper:* one Bash call carrying one row's cells, ~200–260 bytes, so ~60–90 output
tokens, and no read at all. Over 21 units, roughly 1.5–2k tokens — a 20–30× reduction — and
the truncation surface is **zero**, because the model never emits a row it did not author in
that call.

*Stated honestly:* the helper still rewrites the file (awk to `mktemp`, then `mv`), exactly as
`writeback-state.sh` does for every task-state field write. "Zero full-file rewrites" means
**zero agent-authored whole-table re-emissions** — prior rows are reproduced by the script,
never by the model. Per-unit checkpointing is viable: it costs 21 extra Bash calls and is
cheaper in total output tokens than a *single* one of today's full rewrites once a review
exceeds about two units.

### 4. Mechanical AC-3 enforcement

Taken from feature-002, with one named exemption.

`--append-finding` rejects a row whose `Rule` is `--`, empty, or fails
`^[A-Z]{2,12}-[0-9]{2}$`, with exit 4. The helper is the only writer of rows, so this is the
only place the rule can be mechanical; `grade.sh` cannot do it under NFR-1.

**The exemption is forced by an upstream decision, not invented here.** STATE.md Q11 decision
3 requires that an unmatched artifact class — before feature-004 exists — be recorded as one
`Status: OOS` row with `--` in `Rule`. So: **a finding row may carry `--` in `Rule` if and only
if its Status is `OOS`.** Every grade-bearing status (`Pending`, `Recurred`) and every status
that was once grade-bearing (`Fixed`, `Accepted`, `Invalid` — all of which begin life as
`Pending` rows that already carried a rule) requires a real rule ID. AC-3 stays intact exactly
where it decides the gate, and **the exemption retires when feature-004 replaces the interim
`OOS` row with a `G-NNN` row.**

### 5. Affected-artifact inventory and region ownership

Line numbers from the work-003 worktree, before features 001 and 002 land.

**New files**

| File | Content |
|---|---|
| `canonical/aid/scripts/review/writeback-ledger.sh` | The helper |
| `tests/canonical/test-writeback-ledger.sh` | Its suite (§9) |

`tests/run-all.sh` discovers suites by glob and needs no edit. `tests/coverage-baseline.tsv`
needs none either: `coverage-parity.sh` fails only on *removed or reduced* assertions, so
adding a suite is gate-clean.

**`canonical/aid/templates/reviewer-ledger-schema.md`** — the largest edit.

| Region | Change |
|---|---|
| after 12 | **Add** a contract line for the three row kinds. Line 12's `7-column` token is feature-002's |
| 14 | Status enum contract becomes per-row-kind |
| 28 | Delete "every row is one finding (or one accepted exception)". "Exactly one markdown table" **stays true** and stays |
| after 37 | **Add** `U-` and `G-` example rows. Rows 31–37 are feature-002's |
| 65, 67 | Columns-table cells for `#` and `Status`. Applied *after* feature-002 inserts its `Rule` row; the column-index numbering is not claimed |
| 87–96 | `## Status values` restructured into three vocabularies. The six finding statuses are unchanged |
| 100 | Workflow step 1 — create/append via the helper. **Step 2 (line 101) not claimed** — §6 |
| after 132 | **Add** to `## grade.sh integration`: non-finding rows ignored by construction, naming the `cols[3]` mechanism. AC-9's documentary home |
| after 139 | **Add** per-unit checkpoint lines to the `First REVIEW` block. **Lines 149–157 not claimed** |
| 166–177 | `## Authoring rules for the reviewer`. Line 167 ("emit the table as the ENTIRE file") and line 170 ("read the existing ledger BEFORE appending") both become false when the helper is the writer |
| after 200 | **Add** one orchestrator rule naming the helper as sole writer of rows. 192–195 unchanged |
| after 217 | **Add** the helper to `## See also` |

**`canonical/agents/aid-reviewer/AGENT.md` — claimed: lines 69–74, 76–79, 81–95, 100–103.**

That is the output-contract prose and the whole `## File Writing` section — precisely the
complement of what 001 and 002 took. Not claimed: 3, 39–57, 75, 96–99 (**feature-002**); 31,
36, 59–67 (**feature-001**); 8, 20, 33–34, 105–108.

Two consequences recorded rather than discovered later:

- **Lines 96–99 are collateral, not a claim.** Deleting the fenced heredoc block removes the
  four lines feature-002 rewrote to 8 columns. Four lines of accepted rework, and unavoidable:
  feature-002 cannot ship an agent body whose own example contradicts the column set it just
  changed, and this feature cannot keep a heredoc example whose mechanism it retires.
  Sequential ordering (002 → 003) makes it safe; STATE.md concern N2 already accepts that these
  features cannot be reordered.
- **Line 103 disappears with the section.** It carries the `## Tasks Status` write-target
  defect that FR-A10 (feature-006) owns. Its identical twin at line 20 survives, so nothing is
  orphaned and feature-006's inventory does not shrink — but the defect is momentarily
  half-removed.

**`canonical/aid/scripts/grade.sh` — one comment addition, distinct from feature-002's five.**
Feature-002 claims 10, 11, 163, 164, 172. This feature claims an addition to the comment at
**205–206** ("Any other value (including bare text) is skipped…"), naming coverage and gap rows
as the second intentional class of skipped rows. Comment-only; the guard, the reads and every
branch are byte-unchanged, so NFR-1 holds.

**`canonical/skills/aid-discover/references/state-review.md`** — one insertion after line 424,
adding merge rule 5 (§7). Line 427's `7-column` token is feature-002's; merge rules 1–4 span
**409–424** (rules 1–3 end at 417; rule 4 runs 418–424) and are unclaimed and unchanged.

**`.aid/knowledge/` — two docs, both additive**, each with the Change Log and `README.md`
revision-history entries feature-001 established as the pattern.

| File | Region | Change |
|---|---|---|
| `authoring-conventions.md` | 300 | "emit the 7-column ledger **as the whole file**" — the write-mechanism half is claimed here; the `7-column` token is feature-002's. Line 202 ("the table is the entire file") stays true |
| `authoring-conventions.md` | after 22 | Frontmatter contract gains the row-kind clause |
| `quality-gates.md` | after 122 | **Add** a row-kinds block to `## The Reviewer Ledger` and a note that the status vocabulary is per-kind. Additive: feature-001 claims 98–100, feature-002 changes the 7→8 token at 107 |

**Deliberately untouched.** `reviewer-dispatch.md` — its deliverable bullet spans lines 43–44,
with the schema path itself on **line 44** (line 43 ends with `per` and wraps), and line 269
names a concrete ledger path in a worked example
(`- Write findings to: .aid/.temp/review-pending/phase-a-foundation-v2.md`) rather than a write
mechanism. Both are mechanism-neutral; the schema pointer carries the change. Its line 196
mentions a "bash heredoc" but that renders the *brief*, not the ledger — a false positive for
any mechanism sweep, and §9's oracle is scoped to avoid it.
`tests/canonical/test-grade.sh` (**16** numbered cases, `Test 1` through `Test 16` — verified by
`grep -o '=== Test [0-9]*' tests/canonical/test-grade.sh`) and
`test-delivery-gate-aggregate.sh` (4 fixtures at lines 230, 239, 248, 258) keep their 7-column
shape — that is the NFR-5 proof, and converting them would destroy it.

### 6. Migration and compatibility

**The mixed-shape rule: shape follows the header.** The helper reads the header row, counts
columns, and writes rows of that width. An 8-column header gets 8-column rows; a 7-column
header gets 7-column rows and `--rule` is rejected with exit 4 and an explanatory message. A
header that is neither is exit 6. **Uniform within a file, chosen by the file, enforced by the
single writer.** No migration script, no auto-widening, no half-converted table.

Two supporting facts, both verified rather than assumed. A ledger that spans the change is
*already* grade-safe: a 7-column ledger carrying `U-` and `G-` rows was run through `grade.sh`
and produced the identical grade, because Severity and Status sit at `cols[3]`/`cols[4]` in
both shapes. So the grader is immune to the mix; human readers and any future
`cols[5]`-and-beyond consumer are not. And auto-widening would be strictly worse: it means
rewriting every prior row's bytes on first touch — the whole-table rewrite this feature exists
to retire — and it would break byte-invariance on the very first checkpoint after the column
lands.

**The operative rule for STATE.md Q7 #10: an in-flight review finishes under the shape it
started.** The ledger is deleted at DONE, so the next invocation gets an 8-column file with no
migration event at all.

**The lifecycle rewrite is split by clause.** This feature takes every clause about **table
shape, row kinds, and write mechanism**: workflow step 1, the `First REVIEW` block, and the
whole `## Authoring rules for the reviewer` section — including "read the ledger before
appending" and "only Status may change", the latter because the helper now *enforces* what was
previously a request.

It **declines** the clause about *who* updates Status: workflow step 2 (line 101), the
`Subsequent REVIEW (cycle N)` block (149–157), the fixer rule at 185, and the orchestrator
rules at 192–194. That is FR-D5's actor reassignment and belongs to **feature-005**. The
boundary held: this feature defines row *shape and enums*; features 004 and 005 define *actors
and semantics*.

**Hard hand-off, because STATE.md Q7 #8 exists precisely because this rewrite was orphaned
once: feature-005 must rewrite `reviewer-ledger-schema.md` lines 101, 149–157, 185 and 192–194,
and must carry that as an explicit acceptance criterion.** If feature-005's Specify does not
pick it up, the orphan recurs and this paragraph is the evidence.

### 7. Multi-writer partitioning

`aid-discover`'s parallel mandate dispatch is the one case where a ledger namespace can
collide. **Coverage and gap rows are excluded from the panel merge**: they stay in the writer's
own scratch ledger, which survives until step 2e, so mandate resume works without any
cross-mandate ID reconciliation, and the merged canonical ledger stays purely findings — which
keeps the essence and act-back verdict derivations (steps 2c/2d) untouched.

One added merge rule after line 424 states this. The `U-<NS>-NNN` namespace form therefore
exists for the genuinely multi-writer case only and is unused in the common path.

### 8. Render and profile impact

Seven rendered trees — five profiles plus this repository's own `.claude/` and `.cursor/`
installs. This feature ships the first new **script** of the work, so the render surface differs
from features 001 and 002: verify the new `review/` subdirectory is emitted under each tool
root, that the helper is executable, and that its relative `grade.sh` resolution works from the
rendered location.

Per STATE.md concern N3, parity is verified **at this feature's close**: `/generate-profile`,
then `verify_deterministic.py`, then a smoke invocation of the rendered helper in one profile.

### 9. Verification strategy

Ships as `tests/canonical/test-writeback-ledger.sh`. **Every oracle below was run against the
real `grade.sh` during design; the results are measured, not predicted.**

**The AC-9 differential oracle — same findings, with and without non-finding rows.**

Four fixtures: (a) 8-column findings only; (b) byte-identical findings plus `U-001`, `U-002`,
`U-003`, `G-001` interleaved *between* them; (c) 7-column findings only; (d) 7-column with
`U`/`G` rows.

```bash
# (1) grade equality
[ "$(grade.sh fixture-a.md)" = "$(grade.sh fixture-b.md)" ]
# (2) the --explain breakdown is byte-identical, not merely the letter
grade.sh --explain fixture-a.md 2>a.err >/dev/null
grade.sh --explain fixture-b.md 2>b.err >/dev/null
diff -q a.err b.err
```

Measured: **a = b = c = d = `D+`**, and the `--explain` breakdowns of a and b are byte-identical
(`CRITICAL 0 / HIGH 1 / MEDIUM 1 / LOW 0 / MINOR 0 / TOTAL 2`). Assertion (2) matters more than
(1): a letter can coincide by accident, a five-way count breakdown cannot.

**Two negative controls, both measured**, either of which a weaker oracle would miss:

```bash
# A coverage row whose Status collides with a grade-bearing status is STILL ignored.
sed 's/Examined/Pending/' fixture-b.md > adversarial-status.md   # measured: D+
# An em-dash sentinel instead of the double hyphen is also ignored.
sed 's/| -- |/| — |/g'    fixture-b.md > adversarial-emdash.md   # measured: D+
```

The first proves the **severity** gate alone carries the inertness — the coverage vocabulary
cannot leak into the grade even when a value collides with `Pending`. The second is why §1's
`--` choice is a readability convention rather than a correctness dependency.

**Helper oracles:**

```bash
# byte-invariance: everything except the touched row is unchanged
cp ledger.md before.md
writeback-ledger.sh --ledger ledger.md --set-status --row-id U-002 --status Examined
diff <(grep -v '^| U-002 ' before.md) <(grep -v '^| U-002 ' ledger.md)   # expect empty

# no renumbering: the multiset of # cells gains exactly the new ID and loses nothing
# rejection: a grade-bearing finding with no rule is refused
writeback-ledger.sh ... --append-finding --severity '[HIGH]' --rule -- ... ; [ $? -eq 4 ]
# the OOS exemption is honoured
writeback-ledger.sh ... --append-finding --severity '[LOW]' --status OOS --rule -- ... ; [ $? -eq 0 ]
# kind-checked status: a finding status on a coverage row is refused
writeback-ledger.sh ... --set-status --row-id U-002 --status Recurred ; [ $? -eq 4 ]
# gap idempotency: a repeated key appends no row and increments resume=N
# mixed shape: --rule against a 7-column header is refused; a 7-column row appends without it
# CRLF and no-trailing-newline fixtures, mirroring writeback-state.sh's existing coverage
```

**The static "zero full-file rewrites" oracle, with its baseline captured rather than quoted:**

```bash
# Mechanism sweep: a heredoc write CO-LOCATED with a ledger path.
grep -rn 'cat >>\? *\.aid/\.temp/review-pending' canonical .aid/knowledge   # expect 0
grep -rn 'LEDGEREOF' canonical .aid/knowledge                              # expect 0
# Positive complement: the helper is named where the mechanism is taught.
for f in canonical/agents/aid-reviewer/AGENT.md \
         canonical/aid/templates/reviewer-ledger-schema.md \
         .aid/knowledge/authoring-conventions.md; do
  grep -q 'canonical/aid/scripts/review/writeback-ledger.sh' "$f" || fail "$f"
done
```

Measured baseline today: the first pattern matches **exactly one line**
(`canonical/agents/aid-reviewer/AGENT.md:95`) and the second matches **two** (95 and 100). Both
are non-trivially false before implementation and both go to zero after it. The co-location
requirement is deliberate: `reviewer-dispatch.md:196` says "bash heredoc" about rendering the
*brief*, and an uncoupled `heredoc` sweep would fail on it forever.

**What none of this proves, stated plainly.** "The reviewer actually checkpoints after every
unit" is a runtime property of an agent and no static check reaches it. These oracles prove the
mechanism exists, is the only sanctioned one, cannot renumber or truncate, and cannot change a
grade. Whether a given reviewer invokes it once per unit is enforced by the agent body and,
once feature-005 lands, observable as `U-NNN` rows in the ledger — a review artifact, not a
test assertion.

### 10. Out of scope

- The canonical severity scale, and `AGENT.md` lines 31/36/59–67 — **feature-001**.
- The `Rule` column itself, the rubric catalog, and `AGENT.md` lines 3/39–57/75/96–99 —
  **feature-002**.
- Type 1 / Type 2 findings, gap batching, routing, and the halt policy. This feature provides
  the `G-NNN` row and a mechanical recurrence signal; **feature-004** decides what to do with them.
- Resume semantics, the resume-vs-new-cycle mode split, orchestrator-owned Status
  reconciliation, unit invalidation, and `reviewer-ledger-schema.md` lines 101 / 149–157 / 185 /
  192–194 — **feature-005**, handed off explicitly in §6.
- `--list-units` and any resume-planning read API — **feature-005**, which has an actual caller.
  Shipping them here would be speculative surface.
- The `aid-screener` write path. The screener holds `Read, Glob, Grep` and no `Bash`, so it
  cannot invoke this helper: it returns rows in its message and the **calling skill** writes
  them. That is consistent with FR-A2 and with "the reviewer never writes", and it is a
  constraint on **feature-006**, recorded here so it is not discovered late.

### Delivery recommendation

Split at Plan into two:

- **D1 — the helper and its suite.** The script, `test-writeback-ledger.sh`, and the AC-9
  differential oracle. Independently verifiable; ships the token saving and removes the
  truncation hazard on its own.
- **D2 — the schema and doc migration.** `reviewer-ledger-schema.md`, the `AGENT.md` regions,
  the `grade.sh` comment, the `aid-discover` merge rule, and the two KB docs. Depends on D1
  existing so the docs can point at a real script.
