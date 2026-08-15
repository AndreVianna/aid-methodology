# task-066 EVIDENCE -- per-skill contracts, two glossary terms, and the two decisions this work made

feature-006 §7's KB table, rows `pipeline-contracts.md`, `domain-glossary.md` and `decisions.md`.
Closes three more of BLUEPRINT criterion **9**'s documents and their share of criterion **4**.

## 1. `pipeline-contracts.md` -- the lifecycle contract, written once

The thirty-six **bind** `canonical/aid/templates/design-lifecycle.md` rather than restating it, so
the contract is recorded here once rather than as thirty-six per-skill entries. It states the
stage table (precondition / writes / refuses), the **three** `create` refusal conditions and no
fourth, the repeat-`create` routing rule, same-run registration with the owner taken from the
document's matrix row, the frontmatter invariants including `approved_at_commit:` never being
restamped, and `update`'s unconditional derived-outputs question whose answer is stored nowhere.

**No new skill declares a `phase:`, and this is the document where that temptation lives.**
Verified both ways: `grep -lE '^phase:'` over all thirty-six returns **0**, and the section states
it explicitly -- *"None of the thirty-six declares a `phase:` ... C-1's closed enum is **not**
extended by this family."*

**The numbered sequence task-073 diffs is untouched**, and it was read out of the file rather than
retyped. This file uses **ASCII `->`** and says *"six numbered phases"*, writing the pair as
`Describe/Define (Phase 2a/2b)`, where `CLAUDE.md` and `AGENTS.md` use **U+2192** and name seven.
The phase set is identical; only the rendering differs -- so a pattern copied from either agent
context file would have matched nothing here. Both statements are present and unchanged after the
edit (`six numbered phases` at two sites; `Discover -> Describe/Define (Phase 2a/2b) -> Specify ->
Plan -> Detail -> Execute` intact).

## 2. `domain-glossary.md` -- three counts and four entries

Counts moved: the single **58-row** catalog -> **94-row** (twice) and *"Every one of the 58 rows"*
-> **94**. All three are guard-blind by §7's own analysis, one of them mode **M3** -- the right
noun with an intervening word defeating the regex's adjacency -- which is why they are corrected
here by hand rather than reported by a tool.

Four entries added to the KB Authoring lexicon:

| Term | The distinction it draws |
|---|---|
| **seed (design seed)** | a settled direction recorded *before* the thing exists; an input to the build, never a substitute for it |
| **design artifact** | the durable thing a design informs -- *the seed says what to build, the artifact is the thing built, and `create` is the step between* |
| **roadmap.md** | direction, in three horizons plus the forward MVP entry |
| **backlog.md** | inventory not yet scheduled -- explicitly distinguished from roadmap |

## 3. `decisions.md` -- exactly two, both recording reasoning not derivable from the code

**D27 -- `design`/`create`/`update`, not `export` or `document-`.** Records why each alternative
was rejected: `document-` already means *write about something that exists*, so overloading it
would have made the eight genre siblings ambiguous; `export` names a direction of data movement
rather than a stage of work, and implies a lossless transform of something already complete.

**D28 -- forward-looking documents in a Knowledge Base that describes what *is*.** The apparent
contradiction and its resolution: **the line is drawn at commitment, not at tense.** A committed
decision is a present fact even when its subject is the future; a design seed is a proposal that
may be discarded. So `roadmap.md` and `backlog.md` are KB documents, and seeds live outside the KB
in `.aid/design/` -- which is exactly the invariant all 22 `design` bodies state.

Both were added **with their `## Contents` entries in the same write** -- the rule the delivery-002
gate had to fix `decisions.md` for. The set-comparison over headings versus link texts is now
clean in **both** directions.

`bash canonical/aid/scripts/kb/lint-frontmatter.sh --root .aid/knowledge` is **green**.
