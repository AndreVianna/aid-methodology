# task-005: Rendering-approach decision record and drafted stack/infrastructure entries

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** RESEARCH

**Source:** work-005-knowledge-graph -> delivery-001

**Depends on:** task-004

**Scope:**
- Execute feature-002's Feature Flow **Steps 6-8** and write the decision record to
  `.aid/works/work-005-knowledge-graph/deliveries/delivery-001/research/rendering-decision-record.md`.
  This record is the durable artifact of feature-002 and resolves STATE.md **Q2**.
- **Step 6 -- confront the tension.** Work feature-002 § The tension this research must resolve
  explicitly: node counts are bounded to the hundreds (FR-22, FR-23, A-5) while NFR-1 sets a hard
  WCAG AA bar, so "maximum rendering power" and "best achievable artifact" may point in opposite
  directions. A recommendation landing on SVG or DOM must justify why the owner's widened option
  space was *used* rather than quietly re-deriving the pre-amendment answer; one landing on Canvas
  or WebGL must show AA is cleared **as measured** and price the hand-built proxy layer into
  feature-008's and feature-009's size.
- **Step 7 -- decide and record.** Write all **fifteen** parts of feature-002 § The decision record:
  (1) question and scope, (2) research inputs, (3) bench scale and derivation, (4) the comparison
  matrix, (5) the recommendation, (6) the rejected alternatives, (7) runtime prerequisites,
  (8) payload/licence/attribution placement, (9) the update story, (10) the accessibility
  confirmation, (11) the accessibility cost of the recommended renderer, (12) the resolved
  scale-versus-accessibility tension, (13) the drafted `technology-stack.md` entry, (14) the drafted
  `infrastructure.md` implications if a build step is recommended, (15) the implication for
  feature-008's size.
- **Part 7 is written as prose a reader can act on**, naming network access, companion asset files,
  or a build output. It is the sentence **AC-6 is checked against** -- by task-074 in delivery-004,
  which verifies the artifact's footer prerequisites against this prose. AC-6 itself is satisfied by
  feature-007 there, not here.
- Parts 13 and 14 are **drafted, not landed.** Landing them is task-095's, in delivery-006. This
  task writes no Knowledge Base file. The drafted `technology-stack.md` entry covers § "Frameworks &
  Tooling", § "Key Dependencies" -- scoping the standing "AID deliberately ships zero runtime
  dependencies for the CLI" claim explicitly rather than leaving it ambiguous -- and § "Build
  Commands" / § "Version Concerns" if a build step is recommended.
- **Step 8 -- hand off.** Record what each of the five consumers takes from this record: feature-008
  (the recommendation itself; the only feature this research blocks, and its size swings on the
  answer), feature-007 (the runtime-prerequisite statement and the packaging shape), feature-009
  (the accessibility-model finding), feature-011 (whether its validator carve-outs fire at all), and
  feature-012 (the drafted stack entry and the manifest impact).
- **This task writes no product code, no Knowledge Base file, and commits no spike harness.**
- Out of scope: landing the drafted KB entries (task-095); implementing the recommendation
  (delivery-005 tasks 078-082); the conditional packaging gate (task-083) and the conditional
  validator carve-outs (tasks 076/077 and 084/085) -- this task only makes their firing conditions
  decidable.

**Acceptance Criteria:**
- [ ] The record exists at `.../deliveries/delivery-001/research/rendering-decision-record.md` and
      carries all fifteen numbered parts, each present and non-empty, and each traceable to the
      completion criterion or Q2 deliverable it discharges.
- [ ] Part 5 names **exactly one** approach.
- [ ] Part 6 states why each rejected alternative was rejected, covering at minimum the four renderer
      classes (minimal layout/zoom modules, a higher-level graph library, a WebGL-class renderer,
      hand-rolled) **and** the rejected packaging shapes, including CDN delivery and build-step
      output.
- [ ] Part 3 restates the bench scale and how it was derived from this repository, plus the
      order-of-magnitude overshoot bench.
- [ ] Part 8 reports payload and packaging cost, the licence and attribution obligations, and **the
      place in the artifact where attribution must appear** if any is required -- a visible footer,
      an HTML comment, an about panel, or a companion file -- not merely that attribution is
      required.
- [ ] Part 9 names *who or what notices* upstream movement as a **mechanism**, not an intention (a
      new dependabot ecosystem entry, a scoped manifest, a CI check, or a named human
      responsibility), and records the current baseline: `.github/dependabot.yml` declares only
      `package-ecosystem: "github-actions"`, so today nothing notices.
- [ ] Part 10 **demonstrates** rather than asserts reduced-motion settling, keyboard zoom and pan,
      and non-colour encoding, citing task-004's measurements.
- [ ] Part 11 states the accessibility cost of the recommended renderer against §6's WCAG AA bar --
      specifically whether it yields accessibility-tree semantics natively or requires a hand-built
      proxy layer -- and what that implies for feature-009's effort. It is distinct from part 10:
      part 10 confirms the behaviours are reachable, part 11 prices reaching them.
- [ ] Part 12 resolves the scale-versus-accessibility tension explicitly at this project's **measured**
      node count, names which of the two poles was chosen, and states the cost of choosing it.
- [ ] Part 7 is prose a reader can act on and names the runtime prerequisites explicitly; a
      recommendation that leaves its prerequisites implicit is not accepted.
- [ ] Part 15 states the implication for feature-008's size, so delivery-005 can be sequenced
      honestly.
- [ ] Parts 13 and 14 are drafts **inside the report**: `git status --porcelain` shows no file
      created or modified under `.aid/knowledge/`.
- [ ] The hand-off records what each of the five consumers takes, and states explicitly whether each
      conditional task fires -- task-076/077 (feature-011's `S2` carve-out, fires only under CDN
      packaging), task-083 (feature-012's dependency-packaging gate, fires only on third-party
      adoption) and task-084/085 (feature-011's `validate-visuals.mjs` T2 exclusion, fires only for
      an SVG live surface) -- so each one's recorded-no-op condition is decidable without re-reading
      the matrix.
- [ ] Sources cited, trade-offs documented explicitly, and an actionable recommendation delivered
      (RESEARCH defaults). The "at least 2 alternatives compared" default is satisfied by part 6.
- [ ] `git status --porcelain` shows no change outside `.aid/works/work-005-knowledge-graph/` -- no
      product code, no Knowledge Base write, no committed spike harness.
- [ ] Quality gate: this task's reviewer ledger grades **A+** under `grade.sh` -- the resolved
      `review.minimum_grade` (`.aid/settings.yml`, and this work's `STATE.md` `minimum_grade: "A+"`)
      -- i.e. zero rows with Status `Pending` or `Recurred`. The code baseline is
      `.aid/knowledge/coding-standards.md` and the gate is `.aid/knowledge/quality-gates.md`;
      REQUIREMENTS.md §6 holds only the six accessibility NFRs and is **not** a code or lint baseline.
