# task-027: 'Relative bus' + closed/unclosed-KB fixture corpus

**Type:** TEST

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** -- (none)

**Scope:**
- Author the hand-built, ASCII, checked-in fixture corpus that the AC2/AC3 essence-capture
  suite (task-030) runs over, under `tests/canonical/fixtures/kb-essence/`:
  - `relative-bus/` (f012 SPEC F1) -- a small project tree that plants the coined cross-source
    PHRASE `"Relative Bus"`: a quoted string in `src/bus/relative.ts` (code channel, E5) and again
    in `src/bus/handlers.ts` (recurrence in code), prose in `docs/adr/0007-relative-bus.md` and
    `README.md` (docs channel), so the phrase clears spread `>= 2` on the always-present
    code+docs channels alone (never depending on git history -- [SPIKE-V1] resolution). The
    CamelCase identifier `RelativeBus` MAY appear but is NOT the asserted survival mechanism.
    Include `.gitlog.txt` (history-channel surrogate, optional input only) and
    `expected/candidate-row.txt` recording the asserted harvest row (Term=`Relative Bus`,
    Spread `>= 2`). Plant incidental single-channel capitalized common-word phrase noise (E4 class,
    e.g. `The System`, `This File`) so the precision floor is exercisable.
  - `closed-kb/` (f012 SPEC F1, AC2(b)+AC3) -- a CLOSED spine that DEFINES `Relative Bus`:
    `knowledge/domain-glossary.md` (spine WITH a `Relative Bus` concept entry, definition-as-used-here),
    `knowledge/architecture.md` (a doc that USES `Relative Bus`, resolved by the spine), and
    `generated/candidate-concepts.md` (the term universe `closure-check.sh` reads).
  - `unclosed-kb/` (f012 SPEC F1, AC3 negative) -- same shape but the spine OMITS the
    `Relative Bus` entry while `architecture.md` still USES it (closure must report it ungrounded).
- Every `generated/candidate-concepts.md` MUST replicate f004's emitted table schema verbatim
  (f004 SPEC L275-289): a `## Summary` block carrying the `Cross-source (spread >= 2)` count row,
  and a `## Ranked Candidates` table with the `# | Term | Class | Freq | Spread | Channels |
  Salience | Example source` columns -- so closure-check / teach-back / recon parse a real schema,
  not an ad-hoc shorthand.

**Boundary (f012 EXERCISES, does not RE-SPEC):** this task authors ONLY fixture files. It does
NOT author or edit `harvest-coined-terms.sh` / `closure-check.sh` / the denylist / the phrase-
survival rule (all f004, shipped by delivery-001). The path fixtures (greenfield-detection +
brownfield, task-029) and the AC1 teach-back pass/fail KBs (task-033) are OUT of scope for THIS task
(they are authored by sibling delivery-005 tasks, not here).
The numeric floor VALUES are not chosen here (that is task-030 / [SPIKE-V2]); this task only plants
the inputs that make the separation measurable.

**Acceptance Criteria:**
- [ ] The three fixture trees exist under `tests/canonical/fixtures/kb-essence/{relative-bus,closed-kb,unclosed-kb}/` with the files enumerated in f012 SPEC F1; all files are ASCII and checked into git (no generation step).
- [ ] The phrase `"Relative Bus"` appears in at least two distinct channels of `relative-bus/` (a quoted string in `src/bus/relative.ts` code AND prose in `docs/adr/0007-relative-bus.md` + `README.md`) so a spread `>= 2` is reachable from code+docs alone, with no dependency on `.gitlog.txt`/git history.
- [ ] `relative-bus/` contains at least one incidental single-channel capitalized common-word phrase (E4 class, e.g. `The System`/`This File`) so the precision/noise-floor assertion in task-030 has noise to discriminate against.
- [ ] `closed-kb/knowledge/domain-glossary.md` carries a `Relative Bus` concept entry; `unclosed-kb/knowledge/domain-glossary.md` omits it while both `architecture.md` files USE the term -- so closure passes on closed-kb and fails (reports `Relative Bus`) on unclosed-kb.
- [ ] Every `generated/candidate-concepts.md` carries f004's documented schema: a `## Summary` block with a `Cross-source (spread >= 2)` count row AND a `## Ranked Candidates` table with the exact `# | Term | Class | Freq | Spread | Channels | Salience | Example source` columns (f004 SPEC L275-289).
- [ ] `relative-bus/expected/candidate-row.txt` records Term=`Relative Bus` with Spread `>= 2`.
- [ ] No fixture file is written or harvested at authoring time -- the trees are static read-only inputs (the harvest in task-030 runs over a `mktemp -d` copy, never these committed files).
- [ ] All section-6 quality gates pass.
