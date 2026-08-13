# Declarations Across the Trees

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-08-12 | Feature identified from REQUIREMENTS.md §4 stream 2, §5 FR-1, FR-7 | /aid-define |

## Source

- REQUIREMENTS.md §2 (coverage table), §4 (In Scope, stream 2), §5 FR-1, FR-7
- REQUIREMENTS.md §6 NFR-1, NFR-5; §7 C-1, C-2, C-3, C-4, C-5, C-6, C-7; §9 AC-1, AC-5

*FR-5 is **defined** by feature-001 and **applied** here; it is not claimed twice. NFR-5 — every
declaration derivable from the repo alone — is carried here, because this is where declarations are
authored.*

## Description

With the criteria system built and read (feature-001), this feature is the **exceptions pass**, not
a population pass. Feature-001's global and per-type criteria already cover most files. This feature
walks the corpus, confirms every file resolves to a declared type, and writes a `contracts:` /
`severity:` block **only where a file has criteria or exclusions its type does not cover**.

**Most files will end with no block, and that is the intended result.** A file whose type covers it
declares nothing; adding a block that restates a type-level criterion is the duplication the cascade
exists to prevent. How many files end up carrying one is an output of the walk, not a target.

This is also what dissolves the objection that a third of the corpus is unauthorable: a generated
`SKILL.md` rebuilt from `shortcut-catalog.yml`, and a template whose frontmatter slot already holds
the emitted artifact's block, both need **no per-file declaration at all** — their criteria live at
type level, in the KB, where nothing overwrites them.

The starting state, derived on this branch:

| bucket | files | has frontmatter | declares a criterion |
|---|---|---|---|
| `skills/*/SKILL.md` | 76 | 76 | 0 |
| `skills/*/references/*.md` | 110 | 0 | 0 |
| `skills/*/README.md` | 11 | 0 | 0 |
| `agents/*/AGENT.md` | 9 | 9 | 0 |
| `agents/*/README.md` | 9 | 0 | 0 |
| `canonical/aid/templates` | 78 | 29 | 1 |
| `.aid/knowledge` | 22 | 22 | 9 |

**The feature opens by deleting, not by writing.** The 20 internal `README.md` files under
`canonical/skills/` and `canonical/agents/` are removed first — none of them ship to an adopter, 18
have no inbound reference at all, and authoring declarations into files that are about to be deleted
is wasted work twice over. That leaves **295** files in the population set, not 315.

Deletion is also a repair. `aid-execute/references/state-execute.md` → the “Mechanical sub-tasks” paragraph tells an
executor *"See `agents/aid-clerk/README.md` for the caller contract"*, and that path exists in no
installed tree — the line is replicated to all five profiles and both dogfood trees, so seven copies
of the pointer resolve to nothing. Two files therefore need preparation before removal: the
`aid-clerk` caller contract moves into `AGENT.md`, which does ship; and
the `DMR00c` assertion in `test-deploy-monitor-repurpose.sh` is removed together with the
`aid-monitor` README it guards.

Then the population itself. After the 20 deletions and the 5 KB carve-outs (`STATE.md` per C-4,
`INDEX.md` and `relationships.md` per C-5, and the two `kb-category: meta` docs), **290** files
remain, in three disjoint buckets — the partition must not double-count, and every file must land in
exactly one:

| bucket | files | edit |
|---|---|---|
| **No frontmatter block at all** | 159 | author a whole block — 110 `skills/*/references/*.md` plus 49 templates |
| **Block exists, declares nothing** | 126 | add the field — 76 `SKILL.md`, 9 `AGENT.md`, 28 templates, 13 KB docs (**the 9 at `contracts: []` are inside this bucket**, not a fourth one) |
| **Already declares** | 10 | **verify, do not assume** — 9 KB docs plus `reviewer-ledger-schema.md`. An existing declaration that has gone stale is the worst case: it reads as checked and is not. |

The 9 empty `contracts: []` docs include `architecture.md`, `tech-debt.md` and
`pipeline-contracts.md`, whose stale claims were live findings in `work-003`.

## User Stories

- As an AID user, I want the procedure files an agent actually executes to declare what they must be
  true against, so that a stale instruction is caught in review rather than followed.
- As an AID user, I want the documents defining how review works to be held to the same standard as
  everything else, so that the rules are not the one place nobody checks.
- As an AID user, I want files that exist for no reason removed rather than annotated, so that the
  amount of surface that can drift goes down instead of up.
- As an AID user, I want a declaration I can verify myself with the repo in front of me, so that
  "verified" never means "asserted somewhere I cannot reach".

## Priority

Must

## Acceptance Criteria

- [ ] Given the 20 internal READMEs, when this feature begins, then they are deleted **before** any
      declaration is authored, with the `aid-clerk` caller contract relocated to `AGENT.md` and the
      `DMR00c` assertion removed alongside its file (AC-5).
- [ ] Given `state-execute.md` → “Mechanical sub-tasks”, when the `aid-clerk` README is deleted, then it points at a path
      that exists in an installed tree. `site/src/data/skill-flows/aid-execute.flow.json` is a
      **generated** sidecar: it is regenerated in feature-003's single render, never hand-edited.
- [ ] Given the **290** files remaining after the 20 deletions and the 5 KB carve-outs, when the walk
      completes, then each **resolves to exactly one declared document type**, none is untyped, and
      every one falls into exactly one of the three buckets above — none counted twice, none left
      over (AC-1).
- [ ] Given a file whose type-level criteria already cover it, when the walk reaches it, then it is
      left **without** a `contracts:` block — a block restating a type-level criterion is a finding,
      not a completion.
- [ ] Given the 9 KB docs at `contracts: []`, when this feature completes, then each declares real
      assertions or states why it legitimately has none — an empty block is not a passing state.
- [ ] Given any authored `contracts:` entry, when a reviewer checks it, then the assertion is
      derivable by an agent with repo access alone — no network call, no credential, no reference to
      a work folder (NFR-5).
- [ ] Given C-4, when this feature enumerates files, then no `STATE.md` at any level in any folder
      receives a declaration or is reviewed.
- [ ] Given C-5, when this feature reaches `INDEX.md` and `relationships.md`, then they are treated
      as generated/meta and take build-verify, not an authored content criterion.
- [ ] Given a declaration authored in this feature, when it is checked against disk, then it holds —
      a false declaration is worse than none, because it reads as verified.
- [ ] **Proof (AC-2, method per NFR-1):** given a planted contradiction in a file populated by this
      feature, applied in a disposable worktree, when a real review runs, then the finding returns
      citing that file's contract.
- [ ] Given C-2, when this feature completes, then `profiles/` and the two dogfood trees have **not**
      been re-rendered per edit — the render happens once, at the end of the work.

---

## Technical Specification

*(Added by /aid-specify — do not fill during interview.)*
