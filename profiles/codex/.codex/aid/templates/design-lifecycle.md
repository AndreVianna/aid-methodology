# Design Lifecycle

The shared contract every one of the 36 `design` / `create` / `update` skills authored
across features 003-005 binds to — authored **once** here, in the manner of
`shortcut-engine.md` or `work-initiation-gate.md`, rather than restated 36 times. Free-form
prose read by a dispatched agent, not machine-parsed.

Three verbs, denoting **stage**, not direction: `design` develops an idea in
`.aid/design/`; `create` realizes it; `update` maintains what exists. The population each
rule below binds differs by rule — a rule stated as if it bound everyone is a rule that
cannot be implemented for two-thirds of the roster. Where a rule is settled once, for every
feature that touches this mechanism, by REQUIREMENTS FR-11's cross-feature contracts
(`CC-1`..`CC-9`), this file refers to that contract **by id** and does not restate it —
restating a shared rule is how its boundary quietly moves.

---

## Before writing a seed: acquire `.aid/design/` on first use

`.aid/design/` is not seeded at install. Every `design`-stage skill run — the first one in
a project, no more — is responsible for this, before it writes anything:

> Before writing a seed, ensure `.aid/design/` exists. If `README.md` is absent from it,
> copy `.codex/aid/templates/design-folder-readme.md` into it as `README.md`. Never
> overwrite an existing `README.md` — it is user data the moment it is written. If the
> template is missing from the installed bundle, write the seed anyway and warn once; a
> missing convention document must never block the user's actual work.

A project that never runs a `design`-stage skill acquires neither the folder nor the
README. The path in the rule above is written in exactly the **canonical** form the
render-time `rewrite_install_paths` idiom resolves per profile
(`.codex/aid/templates/…` → `<install_root>/aid/templates/…`) — there is no per-tool
root to choose among and no five-way runtime decision for the agent to make. Writing that
path in any other form (a variable, an `<agent-root>` placeholder, a relative path) defeats
the rewriter and ships a dangling reference on every profile but one.

---

## The three stages

### `design` — binds all 22 design-stage writers, without exception

The 7 class-1 `design` skills, the 14 class-2 `design` rows, and `/aid-brainstorm` — every
writer this work adds that puts pen to a seed.

| | |
|---|---|
| **Reads** | its own seed if one already exists, the Knowledge Base, and project source |
| **Writes** | its own seed in `.aid/design/` — nothing else |
| **Terminates by** | presenting the seed; the user iterates by re-invoking the same skill |

> **A recorded departure from REQUIREMENTS FR-1.** FR-1's own table gives the `design`
> verb a `Reads` value of `.aid/design/` alone. The row above widens it to "its seed if
> present, the KB, project source." The widening is deliberate — a seed written without
> reading the KB would restate what the project already documents — and it is recorded
> **here, by this contract's owner**, rather than only on the consuming side (feature-003
> §6a records the same decision from there; the two records describe one decision, not
> two).

> **This 22 is not REQUIREMENTS FR-11 CC-7's 22.** CC-7 counts the `design` **family**'s
> catalog rows — bare `/aid-design` + the 14 grid rows + the 7 design artifacts — and
> treats `/aid-brainstorm` as its own single-row `brainstorm` family. The population above
> counts this work's new `design`-stage **writers**: the 7 + the 14 + `/aid-brainstorm`,
> with bare `/aid-design` excluded (its behavior is unchanged by this work). The two sets
> differ by exactly one member — bare `/aid-design` is in CC-7's, out of this one;
> `/aid-brainstorm` is the reverse — and land at the same size, 22, by accident. Use CC-7's
> 22 for any count-bearing claim about the family; use this section's 22 only as the
> population the invariant below binds.

> **`design` never writes `.aid/knowledge/` and never writes production code.** This is
> the hardest invariant in this contract, and the one a dispatched agent will most readily
> violate by "helpfully" finishing the job. It binds all 22 writers above **without
> exception** — the 14 that design code, no less than the 7 that design KB-bound
> artifacts, and `/aid-brainstorm` besides.

### `create` and `update` — bind class 1 only (the 7 design artifacts)

Class 2's `create`/`update` doorways already exist and are not authored by this work — see
The two classes, below.

| Verb | Reads | Writes | Terminates by |
|---|---|---|---|
| `create` | the seed, the KB, project source | its owned region of the destination document, plus any user-requested output | **On the realizing path:** consuming (deleting) the seed. **On a routing path** (Region ownership, rows 2 and 4 below): naming the skill it routes to and stopping — realizing nothing, writing nothing, and leaving the seed **in place** for that skill to consume. Consumption is the realizing path's terminator only, never unconditional |
| `update` | the destination document, previously-created outputs, and its `.aid/design/` seed when one is present (REQUIREMENTS FR-11 **CC-3**) | those same targets | Writing the revision — and consuming (deleting) the seed if one was read. `update` never *requires* a seed |

`update`'s seed clause is REQUIREMENTS CC-3, referred to and not restated here. It is what
gives a **routed** seed a consumer: a `create` that routes has realized nothing, so its
seed survives, and the `update` run it routed to becomes the realization event. Without
CC-3 a routed seed only accumulates.

---

## The two classes of skill this contract binds

Two genuinely different mechanics wear the same three verb names.

**Class 1 — the 7 design artifacts.** `design`, `create`, and `update` are three separate,
hand-authored skills for each artifact. The `create`/`update` table above binds this class
only.

**Class 2 — the 14 code artifacts.** Their `design` row is new (this work); their
`create`/`update` doorways already exist and are not authored here. The class splits into
two sub-cases, derived from whether the artifact's catalog rows carry a `repurpose` key:

| | Class 2a — 13 artifacts | Class 2b — `document` |
|---|---|---|
| `create`/`update` doorway | generated; runs `shortcut-engine.md` | hand-authored collapse skills; **never** runs the engine |
| Seed reaches `create` via | the engine's own read at CAPTURE Step 2 | the two collapse bodies' own reads, added directly to their `SKILL.md` |
| Readiness gate | **No** — the engine has no refusal state | **No** — parity with 2a; the read is non-mutating |
| Verify depth on `create`/`update` | the engine's own GATE state governs; not this contract's to set | the collapse skills' own bodies govern; there is no GATE state to delegate to |
| Seed deleted at `create` | **No** — persists; deletion is manual | **No** — same |

**`/aid-brainstorm` — a third case, not a member of either class.** It writes a seed under
a confirmed slug and has no `create` counterpart at all. Every `create`-stage rule above is
therefore **inapplicable** to it, not waived — there is nothing to route to and nothing to
consume its seed. The seed persists until the user promotes it into one of the
`.aid/design/README.md` lifecycle entries, or deletes it by hand.

---

## Region ownership

**Scope.** This rule binds **the 36 new skills only**. It is not a claim about who may
write the destination documents in general — `/aid-describe`'s greenfield authorship and
`/aid-graph`'s regeneration of `relationships.md` are both legitimate wholesale KB writers
outside this rule's reach. What binds these 36 is the same targeted-edit discipline
`aid-update-kb` and `aid-housekeep` already hold themselves to for their own region: a
targeted edit to the region owned, never a wholesale rewrite of the document.

**The first-write dispatch.** Four situations, each an action, each citing the authority it
dispatches on rather than re-deriving it:

| Situation at `create` | Action | Authority |
|---|---|---|
| Destination absent, this skill owns the **whole document** | Create the document, then write its content into it | REQUIREMENTS FR-1; FR-9's "created on first use" |
| Destination absent, this skill owns only a **region** | Route to the document's owner, name it, leave the seed in place. Do **not** create the document | REQUIREMENTS FR-11 **CC-5**, referred to and not restated |
| Destination present and populated, owned region **absent** | Add the region — a populated destination is the normal case, not a refusal condition | REQUIREMENTS FR-1 |
| Owned region present, carrying **committed content** | Route the user to the corresponding `update` skill and stop | REQUIREMENTS FR-1. This is the contract's only **destination-side** refusal (the seed's readiness gate, below, is the other, and it is seed-side); it never halts with nothing done |

**The standing constraint under all four** (not a fifth branch): any other region of the
destination document is read, preserved byte-identical, and never rewritten.

Two things this section deliberately does not state, because REQUIREMENTS FR-11 assigns
them elsewhere: the registration surfaces a newly created conditional document occupies
(**CC-4**), and the `.aid/settings.yml` `doc_set` entry a `create` skill writes when it
creates one (**CC-1**, discharged as an effect of running the skill, per **CC-2**). No row
above authorizes a different set.

**Mechanics, for the one shared destination — `roadmap.md`, split between `/aid-*-mvp` and
`/aid-*-roadmap`:**

| Question | Rule |
|---|---|
| Region identity | the literal heading `## MVP`, matched exactly |
| Region extent | from that heading to the next heading of level 2 or shallower, or EOF — deeper subsections belong to the region |
| Position when created | immediately after the `## Contents` block, before the first content section — not "before the first other `##`", which would break KB layout order. The exact anchor is feature-003's to place |
| Who may create the region | `/aid-create-mvp` and `/aid-update-mvp` only |
| Who may create the document | `/aid-create-roadmap` only — this destination's instance of the region-owning-skill rule above |
| Minimum document shape | Whatever `/aid-create-roadmap` defines for `roadmap.md`, which must place `## MVP` per the two rows above — no template exists, so the shape is feature-003's to set |
| Write discipline | read the whole file, replace only the owned byte range, write back with every other region byte-identical. Never regenerate |

---

## Derived outputs are resolved by asking, every run

`update` asks the user which previously-created outputs to update — **every run**, fresh.
No frontmatter backlink, no manifest, no registry, no state carried between runs. Stated
explicitly because a manifest is the first thing an implementer reaches for, and it is not
what this contract wants.

---

## Skill shape

Modeled on `.codex/skills/aid-design/SKILL.md`. Binds class 1's 21 skills, class 2's 14
new `design` rows, and `/aid-brainstorm` — with one carve-out: the `create`/`update` verify
depth, which class 2 and `/aid-brainstorm` have no site for (The two classes, above).

**Frontmatter:** `name` (== directory name), `description`, `allowed-tools`,
`argument-hint`.

**The `description` contract.** Every description states what the skill does **and** names
its nearest confusable neighbour as a negative route — the pattern `/aid-design` and
`/aid-prototype` already use on each other. Who writes which side of a confusable pair, and
where the complete pair set is verified whole, is REQUIREMENTS FR-11 **CC-9**, referred to
here and not restated.

**States:** INTAKE → (DESIGN | CREATE | UPDATE) → VERIFY → PRESENT → DONE.

**Allocation.** Consult the Work Initiation Gate
(`.codex/aid/templates/work-initiation-gate.md`) by running
`bash .codex/aid/scripts/works/enumerate-works.sh`; on new work, run
`bash .codex/aid/scripts/works/worktree-lifecycle.sh create <work-id> <name>`, stop on a
non-zero exit or an empty path, otherwise enter the resolved path; then allocate
`pipeline.path: lite`, `initiator: aid-<verb>-<artifact>`, `lifecycle: Running`,
`active_skill: <name>`. **`phase` is not driven** by any of the 36 — that is what keeps
NFR-3 and AC-10 true without touching the enum.

**Dispatch:** `aid-architect`, tiered by complexity
(`.codex/aid/templates/agent-dispatch-tiering.md`); verifier tier is always at least the
producer's tier.

**"Full verify" — defined, not merely named.** Wherever this contract requires full verify
on `design` (Skill shape's own carve-out excuses class 2 and `/aid-brainstorm` on
`create`/`update`), it means this three-step loop:

1. A mechanical grounding check with no dispatch — decisions cite the KB or the source
   they build on.
2. Adversarial verification by a clean-context `aid-reviewer` dispatch, writing a
   review-quality ledger to `.aid/.temp/review-pending/<work>-verify.md`.
3. `bash .codex/aid/scripts/grade.sh --explain <ledger>`; not clean → loop back to the
   producing state; a 3-cycle circuit breaker → IMPEDIMENT + `lifecycle: Blocked`.

Contrast, so the term carries information: `/aid-prototype`'s **light** check is a single
clean-context dispatch with one return-to-BUILD and no loop at all.

---

## Catalog row shape

All 36 rows are hand-authored: `repurpose: true`, so `build-shortcut-skills.py` skips them.
Required fields: `name` (== directory), `verb`, `artifact`, `alias_of: null`, `group`,
`default_type` (the closed 8-value enum — the live `aid-design` row already uses
`DESIGN`), `intent`, `repurpose: true`.

---

## The seed's naming, readiness, and destination rules

`design-seed.md` fixes the shape; this section fixes the rules that shape anchors on.

**Naming.** `.aid/design/<token>.md`, where `<token>` is the writer's catalog `artifact`
field when it is non-empty — the case for 35 of the 36. The one writer whose `artifact` is
`""` is `/aid-brainstorm`; for it, `<token>` is a kebab-case slug derived from the subject
and confirmed with the user at INTAKE, before the seed is written.

**`## Destination` is optional — for that same writer.** Every class-1 and class-2 `design`
skill writes `## Destination`: its destination is fixed at design time, because the
artifact *is* the destination. `/aid-brainstorm` may omit the section: it has no fixed
destination until the user promotes the seed into one of the
`.aid/design/README.md` lifecycle entries.

**Readiness gate (class 1 only — Skill shape's own carve-out; class 2 has no refusal state
to hang one on).** `create` refuses to consume the seed while `## Open questions` is
non-empty, unless the user explicitly overrides. The override the user must supply is the
literal token `--override-open-questions`; a refusal names that exact token (this is what
each skill's refusal contract means by "the override flag"), so the bypass is a fixed,
reachable string rather than one invented per run. This is the *seed*-side gate; it is
orthogonal to Region ownership's destination-side refusal above, and neither one lets
`create` stop merely because the destination file is populated.

**Detection rule — what "non-empty" means, mechanically.** Between the `## Open questions`
heading and the next level-2 heading (or EOF), the section is non-empty when at least one
line there is all three of:

- not blank;
- not the literal token `None`;
- not an unfilled placeholder — a line consisting wholly of a single `{…}` span, per the
  placeholder convention below.

Any single line meeting all three makes the section non-empty and the seed not ready to be
consumed without an explicit override. A section with only blank lines, only the literal
`None`, or only unfilled placeholder lines reads as ready.

**The placeholder convention this rule depends on.** Unfilled content in a shipped seed is
written brace-delimited, `{like this}` — the convention already used throughout
`.codex/aid/templates/` (`work-state-template.md`'s `{phase}`, `{skill}`;
`knowledge-base/architecture.md`'s `{project}`, `{ModuleA}`).

**No `changelog:` and no `## Change Log`.** Not because a seed is transient — class-2 seeds
persist (The two classes, above), so that reasoning would be false for two-thirds of the
roster. The real reasons are two: `## Current direction` is rewritten each iteration, so a
changelog would only be a lower-fidelity duplicate of what git already records; and no
Knowledge-Base-adjacent artifact in this repo carries change-log apparatus. A seed is
neither a pipeline artifact nor a KB document, and follows the latter.

---

## What binds which

A rule stated as if it bound all three populations is a rule that cannot be implemented for
two-thirds of the roster — the two classes above are not a formality. This table is the
checkable form of that claim: one row per rule this contract states, showing exactly which
of Class 1 (the 7 design artifacts), Class 2 (the 14 code artifacts), and `/aid-brainstorm`
it binds.

**Row set, re-derived rather than recalled.** Scanning this contract's own sections in
order: *Before writing a seed* contributes 1 rule (acquisition, with its never-overwrite and
warn-do-not-fail clauses); *The three stages* contributes 3 (`design` stage semantics, the
`design` invariant, `create`/`update` stage semantics); *The two classes* contributes 1
(seed deleted at `create`); *Region ownership* contributes 2 (region ownership + write
discipline, the first-write dispatch); *Derived outputs are resolved by asking* contributes
1; *Skill shape* contributes 5 (frontmatter/states/`description` contract, allocation,
dispatch tiering, verify depth on `design`, verify depth on `create`/`update`); *Catalog row
shape* contributes 1; *The seed's naming, readiness, and destination rules* contributes 5
(seed shape/headings, `## Destination`, naming, readiness gate + detection rule + placeholder
convention, no `changelog:`). Total: **19**. The table below carries exactly 19 data rows —
the count agrees.

| Rule | Class 1 (7) | Class 2 (14) | `/aid-brainstorm` |
|---|---|---|---|
| Acquire `.aid/design/` and seed its `README.md` on first use (never overwrite an existing one; warn, do not fail, on a missing template) | Binds | Binds | Binds |
| `design` stage: reads / writes / terminates | Binds | Binds | Binds |
| `design` never writes `.aid/knowledge/` or production code | Binds | Binds | Binds |
| `create`/`update` stage semantics, including `update`'s seed read + consumption (CC-3) | Binds | No — class 2 is not authored by this work for `create`/`update`; its doorways pre-exist | N/A — no `create` counterpart |
| Seed deleted at `create` — on the realizing path only; a routing exit leaves it for the skill it routes to | Binds | No — class-2 seeds persist; deletion is manual | N/A — no `create` counterpart |
| Region ownership + write discipline | Binds | No — class 2's destination is a built artifact, not a document region | N/A — no `create` counterpart |
| First-write dispatch (four situations plus the standing preserve-other-regions constraint; the region-owning case is CC-5) | Binds | N/A — class 2's destination is a built artifact, not a document region | N/A — no `create` counterpart |
| Derived outputs resolved by asking (`update`) | Binds | N/A — class 2's `update` doorways pre-exist, not authored by this work | N/A — no `create` counterpart |
| Skill shape: frontmatter fields, state list, `description` contract | Binds | Binds — its `design` row | Binds |
| Allocation via the Work Initiation Gate | Binds | Binds | Binds |
| Dispatch: `aid-architect`, tiered by complexity; verifier tier ≥ producer tier | Binds | Binds — its `design` row | Binds |
| Verify depth on `design` | Full verify | Full verify | Full verify |
| Verify depth on `create`/`update` | Full verify | N/A — 2a: the engine's own GATE state governs; 2b: the collapse body governs (no GATE state to delegate to) | N/A — no `create` counterpart |
| Catalog row shape | Binds | Binds — its `design` row | Binds |
| Seed shape and literal headings (fixed by `design-seed.md`) | Binds | Binds — feature-005's engine read and its two collapse-body reads consume it | Binds |
| `## Destination` section | Required | Required | Optional — no fixed destination until promoted into a lifecycle entry |
| Naming: `<token>` = the writer's `artifact` field | Binds | Binds | No — confirmed slug; its `artifact` is `""` |
| Readiness gate + its detection rule + the placeholder convention it depends on | Binds | No — neither class-2 sub-case has a refusal state to hang one on | N/A — no `create` counterpart |
| No `changelog:` and no `## Change Log` | Binds | Binds | Binds |
