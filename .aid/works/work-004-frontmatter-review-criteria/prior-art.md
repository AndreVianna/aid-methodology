# Prior art — why this work exists

**This work's evidence base is `work-003-review-subsystem-redesign`, specifically the
`delivery-015` gate cycles 15–18 (branch `work-003`, worktree
`.claude/worktrees/work-003`, HEAD `7a786e70` at the time these numbers were taken).**

`work-003` redesigned the review subsystem and then failed to converge on its own
gate. That failure is the measurement this work is built on. The numbers are recorded
here because `work-003`'s folder is transient by rule and its branch is unpushed — if
either goes, the diagnosis goes with it.

---

## 1. What the loop actually did

Four consecutive review→fix cycles on one delivery:

| Cycle | Findings raised | Grade | Findings whose stated cause was a previous fix |
|---|---|---|---|
| 15 | 9 | E | — (baseline) |
| 16 | 15 | C- | 3 |
| 17 | 14 | D+ | 7 |
| 18 | 9 | D | 4 |

- **47 findings total. All 47 were fixed. Zero recurred.** The fixer was not the
  bottleneck, and severity triage was never the issue — nothing was deferred.
- **14 of the 38 findings in cycles 16–18 (37%) named a previous cycle's fix as their
  cause.**
- **8 of cycle 18's 9 findings were in files the previous cycle's repairs had written or
  touched.**
- Findings converged (15 → 14 → 9) while the grade diverged (C- → D+ → D). The circuit
  breaker watches the grade, so it never tripped on the signal that was actually
  improving.

**The delivery's objective was met around cycle 16** — gate criteria 1–6 verified
independently four cycles running. Every failure after that was criterion 7 going red
from a change made *in that same cycle*.

## 2. The mechanism behind it

Each fix added a guard. Each guard was a new artifact. Each new artifact was inside the
reviewed surface, so it carried its own defects. **The fixes enlarged the thing being
reviewed faster than they closed findings in it.**

Two symptoms worth keeping:

- `rule-authoring.md`'s own header went factually false within an hour of being written
  — it described a refactor ("three documents in one") that its own creation had already
  superseded. **Refactor narration rots.**
- `NF01` in `tests/canonical/test-one-grading-backend.sh` pins `grade.sh` to commit
  `7a9df485` and asserts byte-identity. That is not a durable property; it is the
  sentence *"delivery-015 did not touch grade.sh"* frozen into a committed test. Git
  already records it, with author and date.

## 3. Which rules the 47 findings actually cited

```
16  NAR-05      5  NAR-06      2  NAR-04      1  KB-22
12  EXE-04      3  NAR-03      2  EXE-14      1  EXE-09
                3  KB-20       2  EXE-03
```

- **Zero `AID-*` citations.** The routing table sends all of `canonical/**` to the `AID`
  overlay; no finding in 47 was written against one of its rules.
- **`KB-22` — "for each entry in `contracts:`, derive the asserted fact from disk and
  compare; mismatch = HIGH" — was cited once.** It is the rule that would have caught
  most of the 47, and it went essentially unused.

## 4. Why `KB-22` went unused

The mechanism it depends on — a per-file declaration of what the file must be true
against — exists, is parsed, and is almost entirely unpopulated and unread.

**Coverage of authored markdown** (`site/src/content/docs` excluded: informational
content, different validation):

| bucket | `.md` | has frontmatter | declares a criterion |
|---|---|---|---|
| `canonical/skills/*/SKILL.md` | 78 | 78 | **0** |
| `canonical/skills/*/references/*.md` | 121 | **0** | 0 |
| `canonical/agents/*/AGENT.md` | 10 | 10 | **0** |
| `canonical/agents` (other) | 9 | 0 | 0 |
| `canonical/aid/templates` | 94 | 29 | 1 |
| `docs` | 7 | **0** | 0 |
| `.aid/knowledge` | 22 | 22 | 9 |
| **TOTAL** | **341** | 139 | **10** |

Two distinct gaps:

- **No block at all — 202 files.** Includes all 121 `skills/*/references/*.md` (the
  procedure bodies agents actually execute), and 65 `canonical/aid/templates/*.md`
  (including every `review-rubrics/` file, `reviewer-ledger-schema.md`,
  `grading-rubric.md` — the rubric catalog cannot declare what it must be true against).
- **Block present, declares nothing — 88 files.** All 78 `SKILL.md` carry
  `name / description / allowed-tools / argument-hint`; all 10 `AGENT.md` carry
  `name / description / tier / tools`. No field on either says what the file must be
  true against.

And inside the one tree that does use it, **9 of 22 KB docs carry `contracts: []`** —
explicitly empty: `architecture.md`, `decisions.md`, `domain-glossary.md`,
`external-sources.md`, `integration-map.md`, `pipeline-contracts.md`,
`project-structure.md`, `tech-debt.md`, `technology-stack.md`. `architecture.md`'s stale
skill count and `tech-debt.md`'s malformed `W4-6` row were both `delivery-015` findings.

The `contracts:` keys in `canonical/aid/templates` are (all but one) the **placeholders
in the KB-doc templates**, not declarations about the templates themselves. The field was
built as a KB-doc feature, never as a general property of authored markdown.

**Nothing instructs an agent to read it:**

| Surface | What it says about frontmatter |
|---|---|
| `canonical/agents/aid-reviewer/AGENT.md` | mentions it once — *"No frontmatter"*, about its own ledger. Never says read the artifact's. |
| `aid-execute/references/state-fix.md` (F1–F6) | mentions it once, in F2's impact-chain table, as a source that feeds `INDEX.md` — not as post-edit re-verification |
| reviewer briefs as actually rendered | 0–1 mentions each across four cycles |

That third gap produced cycle 17 finding #3 directly: `quality-gates.md`'s body was
fixed and its own `contracts:` block was left contradicting it.

## 5. The guards that exist instead

Prose-fact checking currently lives in scripts:

| file | lines |
|---|---|
| `tests/canonical/test-one-grading-backend.sh` | 1304 |
| `tests/canonical/check-skill-counts.mjs` | 426 |
| `tests/canonical/test-review-rubrics.sh` | 337 |
| `canonical/aid/scripts/kb/kb-citation-lint.sh` | 279 |
| `tests/canonical/derived-values.mjs` | 275 |
| `tests/canonical/check-derived-values.mjs` | 195 |
| **total** | **2816** |

Roughly **1900 of those lines are contract checks wearing script costumes** — each
encodes one fact-check in code, and can be wrong about the fact. A `contracts:` line
states the fact and delegates the checking to something that can read.

**The genuine mechanical residue is the render/copy diff** —
`tests/canonical/test-dogfood-byte-identity.sh` sha256s every file in the two tracked
dogfood trees against the render manifest. That answers *"was the generator re-run"*,
which is a build question, not a review question, and no declared contract replaces it.

## 6. Operating rules this work inherits

Learned the expensive way in `work-003`; violating any of them reproduces its failure:

1. **A fix that adds a mechanism adds reviewed surface.** Prefer stating the fact where
   it lives over encoding a check for it somewhere else.
2. **Derived artifacts refresh once, at the end.** `profiles/` and both dogfood trees
   being stale mid-change is correct, not a defect. Re-rendering per step generates
   findings about the render.
3. **Do not narrate a refactor inside the artifact it produced.** It is false as soon as
   the next change lands, and git already records the history.
4. **`STATE.md` is never reviewed, at any level, in any folder.** It is bookkeeping; a
   completed run's rows are correct as history and any content check over them fires
   forever.
5. **`source: generated` means build-verify only.** `INDEX.md` and `relationships.md` are
   a special kb-category — meta to the KB — and do not follow the other docs' rules.
6. **A new assertion is not trusted until it has been shown to fail against a planted
   defect.** Several `work-003` guards shipped unreachable or measuring the wrong
   property, and only a mutation control revealed it.

## 7. Scope this evidence points at

Three streams, in this order — the order is load-bearing:

1. **Enforce the mechanism** in `aid-reviewer`, the brief template, the FIX contract and
   the rubric catalog. First, or the declarations authored in stream 2 are read by
   nothing.
2. **Populate and correct the declarations** — the 202 files with no block, the 88 with
   an empty one, the 9 KB docs at `contracts: []`. Includes deciding whether the same
   block declares the file's **severity schema**, which today comes only from a rule's
   anchor or `Step 2` and is therefore uniform across every file a rule touches.
3. **Remove the superseded scripts** — last, or the only checks currently catching drift
   are deleted before the replacement works.
