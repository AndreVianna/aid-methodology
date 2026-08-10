# task-003: `design-lifecycle.md` -- the three-stage `design -> create -> update` contract

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-003/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Type:** DOCUMENT

**Source:** work-006-design-phase-skills -> delivery-001

**Depends on:** task-002

**Scope:**
- Source spec: `features/feature-002-design-lifecycle-machinery/SPEC.md` §2d, §3a-§3f and
  §4's rule set (AC-2, AC-4, AC-5, AC-6, AC-7, AC-10). Author
  `canonical/aid/templates/design-lifecycle.md` as free-form prose read by a dispatched
  agent, in the manner of an existing `state-*.md` reference.
- **§2d -- first-use acquisition**, stated **exactly once**: before writing a seed, ensure
  `.aid/design/` exists; if `README.md` is absent, copy
  `canonical/aid/templates/design-folder-readme.md` into it as `README.md`; never overwrite
  an existing one; if the template is missing from the bundle, write the seed anyway and
  warn once. The path is written in the **canonical** form the render-time
  `rewrite_install_paths` idiom resolves per profile -- any other form defeats the rewriter
  and ships a dangling reference.
- **§3a -- stage semantics, split by stage.** The `design` stage table binds all 22
  design-stage writers (7 class-1 `design`, 14 class-2 `design`, `/aid-brainstorm`), and
  carries the hardest invariant: *`design` never writes `.aid/knowledge/` and never writes
  production code*. Record the deliberate widening of FR-1's `Reads` column here, by the
  contract's owner. The `create` / `update` table binds class 1 only, with `create`'s
  terminator split into the realizing exit (consume the seed) and the routing exit (name
  the skill, write nothing, leave the seed), and `update`'s seed read + consumption per
  REQUIREMENTS CC-3.
- **§3b -- the two classes**, class 2's `2a` (13 generated doorways) / `2b` (`document`,
  hand-authored collapse skills that never run the engine) split, and `/aid-brainstorm` as
  a third case with every `create`-stage rule inapplicable rather than waived.
- **§3c -- region ownership**: the scope statement (this rule binds the 36 new skills only,
  and is not a claim about who may write the destination documents in general), the
  four-situation first-write dispatch with its Authority column, the standing
  preserve-other-regions constraint, and the `## MVP` mechanics table -- with the
  *Position when created* row deferring the exact anchor to feature-003.
- **§3d** derived outputs resolved by asking, every run -- no backlink, manifest, registry
  or state between runs. **§3e** skill shape: frontmatter fields, the `description`
  negative-routing contract, the state list, allocation via the Work Initiation Gate with
  its ``phase` is not driven` clause, dispatch tiering (`aid-architect`, verifier tier >=
  producer tier), and "full verify" **defined** as the three-step loop (mechanical grounding
  check, clean-context `aid-reviewer` dispatch writing a ledger, `grade.sh --explain` with a
  3-cycle circuit breaker). **§3f** catalog row shape.
- **§4's rules, as the contract's own**: seed naming (`<token>` = the row's `artifact`;
  a confirmed kebab-case slug when `artifact` is `""`), `## Destination` optional for such a
  writer, the readiness gate, its detection rule (non-blank, not the literal `None`, not a
  line consisting wholly of a single `{...}` span), and the placeholder convention the rule
  depends on.
- Refer to REQUIREMENTS FR-11 CC-1..CC-9 **by id**; never restate one. Restating a shared
  rule is how a boundary quietly moves (PLAN § Cross-Cutting Risks, risk 4).
- Out of scope: §3g's binding table (task-004, written last from the finished §3 and §4);
  every `SKILL.md`; `shortcut-engine.md`; `shortcut-scaffolding/`; and both installer twins
  (§1d, §1f).

**Acceptance Criteria:**
- [ ] §7 B1: `grep -c 'design-folder-readme.md' canonical/aid/templates/design-lifecycle.md`
      captured to a variable -> `1`. A second mention means the acquisition rule has already
      forked
- [ ] The acquisition rule names the template as
      `canonical/aid/templates/design-folder-readme.md` and names no per-tool root, so the
      render resolves one root per bundle with no five-way runtime choice (§2d). The
      rendered half of that claim is §7 B2 and is evaluated in task-016
- [ ] §7 F1: all three of `grep -q 'grounding'`, `grep -q 'aid-reviewer'` and
      `grep -q 'grade.sh --explain'` succeed against the contract -- "full verify" is
      defined, not merely named
- [ ] §7 G2(b): `grep -cF 'is not driven'` over the contract captured to a variable -> `1`,
      **and** `grep -nE '^[[:space:]]*phase:|phase: *(Describe|Define|Specify|Plan|Detail|Execute|Design|Brainstorm)'`
      over `design-{lifecycle,seed,folder-readme}.md` returns nothing
- [ ] §7 D1 (review): the naming rule resolves a path for a writer whose catalog `artifact`
      is `""` without the implementer inventing one
- [ ] §7 D2 (review): an implementer can code the readiness detection rule from the contract
      alone, including the `None`-token and unfilled-placeholder clauses
- [ ] No CC-1, CC-2, CC-4, CC-5 or CC-9 rule is restated -- each is referred to by id
      (REQUIREMENTS FR-11's governing rule)
- [ ] The `design`-stage invariant is stated as binding **all 22** writers without
      exception, and the note distinguishing that population from CC-7's 22-row `design`
      family is present -- the two sets differ by one member and coincide in size by accident
- [ ] This task's diff modifies nothing under `lib/`, no `canonical/skills/*/SKILL.md`,
      `canonical/aid/templates/shortcut-engine.md` or
      `canonical/aid/templates/shortcut-scaffolding/` (§1d; the range-level assertion is
      task-005's §7 G3)
- [ ] Accuracy verified against the current codebase
- [ ] All section-6 quality gates pass
