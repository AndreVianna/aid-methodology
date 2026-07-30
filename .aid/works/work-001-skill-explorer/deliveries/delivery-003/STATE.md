---
delivery_state: Done
gate_tier: Large
gate_grade: "A+"
gate_timestamp: "2026-07-29T02:20:00Z"
ticket_ref: "--"
---

# Delivery State -- delivery-003

[!NOTE]
This is the DELIVERY-LEVEL STATE.md. It is divided into three zones:
  FRONTMATTER (single writer = this delivery's branch, machine-parsed scalars) --
      `delivery_state`, `gate_tier`, `gate_grade`, `gate_timestamp`, `ticket_ref`.
  AUTHORED (single writer = this delivery's branch, markdown body) --
      the narrative remainder of Delivery Lifecycle / Gate Block, Cross-phase Q&A.
  DERIVED (read-only, assembled at read time) --
      Tasks State (rollup from per-task STATE.md files in tasks/task-NNN/STATE.md).
Identifiers (`Delivery`/`Work` in the header blockquote below, `Branch`) are INFERRED from
the folder name and git worktree -- never authored in frontmatter.

<!-- DELIVERY LIFECYCLE ENUM (authored, not derived)
  aid-plan       creates this file with State = Pending-Spec
  aid-specify    advances to Specified
  aid-execute    advances Specified -> Executing -> Gated -> Done, or to Blocked
Enum members: Pending-Spec | Specified | Executing | Gated | Done | Blocked
This authored state is NOT a derivation of child task states. A delivery may be Pending-Spec
with ZERO tasks; the `_none yet_` rollup below is correct and expected for a new delivery.
-->

> **Delivery:** delivery-003
> **Work:** work-001-skill-explorer
> **Branch:** aid/work-001-delivery-003

---

## Delivery Lifecycle

<!-- AUTHORED -- single writer: this delivery's branch only. The **State** scalar lives in the
     YAML frontmatter block at the top of this file (`delivery_state`). -->

- **Updated:** 2026-07-29T02:20:00Z
- **Block Reason:** --
- **Block Artifact:** --
- **Closed:** delivery-003 is **Done** at gate grade **A+** (Large tier, 3 gate rounds).
  Features 003 and 004 complete. **All 111 skills carry a `## Flow` chart**, up from 34 at the
  start of the delivery. Suite **2370 tests across 36 files**; build clean at 142 pages;
  generation idempotent across pages, sidecars, index and manifest.

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block
     at the top of this file (`gate_tier`, `gate_grade`, `gate_timestamp`). -->

- **Issue List:** 12 rows across three gate rounds. **0 Pending above [LOW].**
  - **[HIGH] ×2 — Fixed (round 1).** Both were visible chart-text defects on `aid-update-kb`:
    `_normaliseLabel` deleted backtick spans, publishing *"two mechanical, -specific checks"*; and
    `_extractLabelFromWorker`'s bullet class `[-*+]` matched `**bold`, ending the lead paragraph
    early and cutting the label mid-phrase.
  - **[MEDIUM] ×1 — Fixed (round 2).** task-038's nine-node-names AC belongs in the **unit** tier and
    existed only in the corpus tier. Added with two assertions the list alone does not make: each B1
    node sits *immediately* after its parent, and ids run `c1…cN`. Mutation-tested with a
    B1-deferred-to-end mutant, which all three assertions kill.
  - **[LOW] ×1 — Fixed (round 2).** Doubled spaces in nine residual labels. Root cause traced by the
    reviewer: R3 step headings carry code spans and the Mermaid escaper replaces each backtick with a
    space individually, so `_label` now unwraps spans before collapsing whitespace.
  - **[LOW] ×4 — Fixed (post-gate).** Task-state hygiene: blank `review` cells, a stale note, and
    unfilled `{description}` placeholders in eleven task files. Graded [LOW], closed anyway — the
    tracking rule is imperative and a delivery should not close on placeholder records.
  - **[MINOR] ×2 — Accepted.** Two immutable DETAIL statements are factually wrong, each confirmed by
    measurement and each with the test asserting reality: APPROVAL-HALT's handoff cannot mention
    `/aid-execute` (that string is in the state's section prose, not its `**Advance:**` clause), and
    "exactly one skill whose parent is residual-shaped" describes no skill — all 13 sibling doorways
    resolve to `inline-states` parents.
  - **[MINOR] ×2 — Recorded, not fixed.** `aid-discover`'s APPROVAL label truncates on an infinitive
    (`"…asks the user to…"`), an honest ellipsis cut at the 60-code-point boundary; and two latent
    backtick-deleting sites in `engine-core.mjs` that reach no page today because the spans fall past
    that boundary.

- **The finding worth carrying out of this delivery.** Five separate defects traced to one root cause:
  **a strip that is correct for one token class, applied to text a reader sees.** Mangled edge
  conditions, a deleted `/aid-define` resume command, `halt` cut out of `halt-proof`, a deleted
  `aid-update-kb`-specific, and a parenthetical replaced by a bare ellipsis. Four were fixed one at a
  time; the fifth was found only when the reported instance was finally treated as a *class* and swept
  for — 1429 labels and 251 edge conditions across all 111 pages, against twelve patterns drawn from
  the earlier defects. That sweep took the corpus from eleven suspects to one. **On finding a defect
  class, sweep for it rather than fixing the instance in front of you.**

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

_None. delivery-003 raised no cross-phase question._

<!-- The unfilled `### Q{N}` template stub that stood here was removed at the work-001 final
     gate. It mattered because the work-level § Cross-phase Q&A is a DERIVED read-only union of
     these sections, so a dashboard unioned the stub in as a Q&A entry whose Category read
     "{category, e.g., Architecture, Requirements, Security}". This delivery's own gate closed
     the identical class in eleven task files -- "a delivery should not close on placeholder
     records" -- while leaving one in its own state file. A grep for template braces across the
     work folder now returns only delivery-002's disclosed gate-block line. -->

---

## Seam Reconciliations

<!-- AUTHORED -- the five cross-feature contract decisions this delivery's gate criterion requires:
     "the five seam reconciliations under Notes are each decided and recorded -- not silently
     resolved by whichever feature is implemented second". Written by task-019 (DESIGN; no code).
     S1-S4 are architect decisions taken here. S5 is NOT decided here -- it records the delta left
     by an owner decision already taken as work `STATE.md` Q3. These are decisions, not questions;
     nothing in this section is pending, and none of it is deferred to an implementer. -->

Specify hardened feature-003's and feature-004's contracts independently, and five seams between
them do not line up against the harness delivery-002 froze. Feature-001 anticipates exactly this,
framing that harness as "a published interface those SPECs are written against; changing it is a
cross-feature change, not a local one." Each decision below therefore states the **delta against
the specific SPEC section it moves** and the **consequence for feature-001's existing assertions**,
which are green today on a corpus of **111** skills, **112** manifest `entries` and **111** pages
carrying the unfilled body-slot comment.

**SPEC corrections are recorded here as owed, not applied.** task-019 edits no SPEC and no
BLUEPRINT, and touches nothing under `site/` or `canonical/`.

### S1 — sidecars in the manifest and in the AC-1 drift guard (feature-003's S3)

- **Category:** Contract seam between feature-003 and feature-001's frozen harness
- **Impact:** Required — settles AC-1's blast radius and the manifest shape before task-030 opens
  `gen-skills.mjs`, delivery-003's only edit to a file delivery-002 created
- **State:** **Decided** (2026-07-27, architect — task-019)
- **Context:** feature-003 § *Seam required from feature-001* **S3** requires that "both the page
  and its sidecar are recorded in feature-001's manifest so AC-1's throw-on-drift guard covers the
  sidecars too". As built the two halves of that sentence are independent, which is what makes the
  seam decidable rather than forced: `.skills-manifest.json` records pages only, and
  `assertNoSkillsDrift` (`site/scripts/gen-skills.mjs`:184) never reads the manifest at all — it
  compares three sorted sets built from the filesystem, `onDisk` being `*.md` under
  `src/content/docs/skills/` minus `index.md`. Feature-001's Migration Plan § *What is touched,
  exhaustively* closes with "Nothing else."
- **Decision — two parts, deliberately separated.**
  1. **The guard extends to sidecars.** `assertNoSkillsDrift` takes a **fourth, required** sorted
     set `onDiskSidecars` — basenames of `*.flow.json` under `site/src/data/skill-flows/` with
     `.flow.json` stripped — compared against the **same** `expected` set inside the **existing
     on-disk block (b)**, contributing two further parts to the **same** throw. Block (a), the
     write-pass comparison, is unchanged and stays pages-only; the on-disk block is where the
     reachable failure lives. The parameter is **required, not defaulted**: a defaulted sidecar set
     is a guard that silently passes when a caller forgets to supply it, which is the exact
     silent-skip class KI-008 has already cost this work once.
  2. **The manifest records sidecars in their own key — not as `entries` rows and not in
     `generatedPaths`.** A new `sidecars` array holds one `{src, dest}` row per skill —
     `{ "src": "canonical/skills/<dir>/SKILL.md", "dest": "site/src/data/skill-flows/<dir>.flow.json" }`
     — POSIX strings built by concatenation, sorted by **literal `src` ascending** with the same
     pure string comparator `entries` uses (delivery-002 Q5).
- **Rationale:** an orphan sidecar is the same reachable failure as an orphan page — the generator
  never deletes, and deliveries 004 and 005 read the sidecar — so it belongs in the same guard and
  the same single throw; but it cannot ride in `entries`, which six green assertions pin to exactly
  one row per page.
- **What AC-1's error message says in this case.** The guard **name is unchanged**: feature-001
  § Telemetry & Tracking pins `skills drift` in a closed list of stable, grep-able guard names, so
  no `sidecar drift` name is minted. The message stays
  `[gen-skills] skills drift: ` + parts joined with `'; '`, and gains two part forms **appended
  after** the page parts, in this fixed order — `missing pages:`, `orphan pages:`,
  `missing sidecars:`, `orphan sidecars:`:
  - `missing sidecars: <names, sorted, comma-space separated>`
  - `orphan sidecars: <names, sorted, comma-space separated> (remedy: git rm site/src/data/skill-flows/<name>.flow.json, …)`

  The realistic case — a skill deleted from `canonical/`, which orphans a page and its sidecar at
  once — produces exactly one throw naming both artifacts and both remedies:

  ```
  [gen-skills] skills drift: orphan pages: aid-deleted (remedy: git rm site/src/content/docs/skills/aid-deleted.md); orphan sidecars: aid-deleted (remedy: git rm site/src/data/skill-flows/aid-deleted.flow.json)
  ```

  That single-throw property is **why the sidecar comparison joins `assertNoSkillsDrift` rather
  than becoming a second exported guard beside it** on the `assertNoDeadCards` pattern already in
  this file. Two guards would report the page on one run and the sidecar only on the next, costing
  a build cycle on the one failure that actually occurs — and feature-001's own Telemetry section
  makes legibility of the throw a contract, not a nicety.
- **SPEC delta.**
  - **feature-001 § Migration Plan → *What is touched, exhaustively*.** Item 2 ("New files under
    `site/scripts/`") no longer covers the generator's whole write set. `site/src/data/skill-flows/`
    is a **fifth** touched thing, and the closing "Nothing else." is amended to admit it.
  - **feature-001 § Drift guard (AC-1).** The three-set listing gains `onDiskSidecars`, and the
    two message labels become four.
  - **feature-003 § *Seam required from feature-001* → S3.** Satisfied as written for the guard;
    **narrowed** for the manifest — "recorded in feature-001's manifest" means the new `sidecars`
    key, never an `entries` row.
- **Effect on feature-001's existing assertions.**
  - **Stays green — every assertion on the drift message.** `gen-skills.test.mjs`:830, :836, :842,
    :854–855, :865–866, :880 are all substring checks or unanchored regexes over the **page**
    labels, whose wording, order and position are untouched.
  - **Knowingly changed, and only mechanically.** The three places that build the argument object —
    the `ok` fixture at :822 and the two literal calls at :861 and :872 — each gain an
    `onDiskSidecars` key. **No assertion in those tests changes.**
  - **What the rejected shape would have broken, and why `entries` was not used.** Six assertions
    pin `entries` / `generatedPaths` to one row per page: :620 (`entries` length = directory count
    + 1), :640 (**strictly** ascending `src`, which a page/sidecar pair sharing one `src` violates),
    :648 (`entries.slice(1)` srcs equal exactly the skill srcs), :657 (`dest` matches
    `^site/src/content/docs/skills/[^/]+\.md$`), and :676 / :679 (the same two properties for
    `generatedPaths`). Under the chosen shape all six stay green.
  - AC-6 is unaffected: the sidecar set is read from a sorted scan, with no clock and no
    environment read reaching the bytes.
- **Implemented by:** **task-030.**

### S2 — the manifest's new keys: `shapeCounts`, and `sidecars` from S1

- **Category:** Contract text, not behaviour — feature-001's manifest shape
- **Impact:** Medium — no assertion moves; the contract sentence does
- **State:** **Decided** (2026-07-27, architect — task-019)
- **Context:** feature-001 § Manifest contract specifies `.skills-manifest.json` as the "**same
  three-key shape**" as `.reference-manifest.json`. Verified on the shipped artifacts: both carry
  exactly `generator, entries, generatedPaths`, and `.skills-manifest.json` holds 112 `entries`
  for 111 skill directories plus feature-002's index row. feature-003 § Contract 3 requires the
  generator to write `shapeCounts` there and makes it "the only authority for how many skills are
  of each shape"; S1 above adds `sidecars`. So the movement is **two keys, not one** — recorded
  plainly rather than framed as a single fourth key.
- **Decision:** `.skills-manifest.json` becomes a **five-key** object in this fixed insertion
  order — `generator`, `entries`, `generatedPaths`, `sidecars`, `shapeCounts` — and **diverges**
  from `.reference-manifest.json`, which stays three-key and byte-untouched. `shapeCounts` carries
  **all five classifier shapes as literal keys in the enum's declared order** — `dispatch-table`,
  `inline-states`, `sibling-doorway`, `engine-doorway`, `residual` — each with an integer, `0`
  included where a shape is unpopulated.
- **Rationale:** `entries` and `generatedPaths` are a page ledger held by six assertions, so new
  information belongs in new keys — and a fixed, fully-populated `shapeCounts` key set keeps the
  manifest bytes independent of which shapes the corpus happens to contain.
- **Why every shape key is always present.** Emitting only the shapes the scan encountered would
  make the key set a function of the corpus, so a shape falling to zero would silently change the
  manifest's shape rather than its numbers, and an absent key would be indistinguishable from a
  classifier that never ran. An explicit `0` states the fact.
- **SPEC delta.**
  - **feature-001 § Manifest contract.** "Same three-key shape:" and the JSON example become the
    five-key shape.
  - **feature-001 § Data Model.** "Its schema deliberately mirrors
    `site/scripts/.reference-manifest.json` rather than inventing a second shape" is amended: it
    mirrored that shape at delivery-002 and is a **superset** of it from delivery-003.
- **Effect on feature-001's existing assertions: none — all stay green.** :600–603 asserts the
  three keys with `toHaveProperty`, **not** an exact key-set equality, so extra keys pass. :611 and
  :614 forbid only `generatedAt`, as a property and as a raw substring; neither new key nor any
  value it carries contains that string. No assertion anywhere counts the manifest's keys.
- **Implemented by:** **task-030.**

### S3 — the body-slot heading is `## Flow`

- **Category:** Contract seam between feature-003 and feature-004, over feature-001's body slot
- **Impact:** Required — one string, emitted by two providers, anchored by three consumers
- **State:** **Decided** (2026-07-27, architect — task-019)
- **Context:** feature-004 fixes the heading to `## Flow` (its **E-DEP-2**, "One-line agreement");
  feature-003 § UI Specs → *Chart presentation* only requires "an H2 the page's table of contents
  can anchor". Feature-001's published seam already names `## Flow` **first** in its exemplar list
   — "Providers own their own headings (`## Flow`, `## Steps`, …). `render-page.mjs` imposes
  none" — and the shipped `site/scripts/skills/body.mjs` carries that sentence verbatim in its
  doc comment.
- **Decision:** the heading is exactly **`## Flow`**, byte-for-byte, emitted by the **provider** in
  both task-029 and task-037 and by nothing else. `render-page.mjs` still imposes no structure and
  `renderMermaid` still returns only the fence body.
- **Rationale:** feature-004's is the narrower of the two claims and is already the exemplar in
  feature-001's published seam, so fixing it costs nothing and buys one stable anchor for the page
  table of contents, feature-005's appended fragment list and feature-006's DOM lookup.
- **Not engaged, and worth stating because it looks adjacent:** `renderFrontmatterValue` enforces a
  single-line contract and throws on an internal newline. The heading and the multi-line mermaid
  fence are **body** text, inserted after the `[Definition: …]` link; nothing on this path reaches
  the frontmatter serializer.
- **SPEC delta.** **feature-003 § UI Specs → *Chart presentation*, final bullet** — "The fence is
  preceded by an H2 the page's table of contents can anchor" is narrowed to the literal `## Flow`.
  feature-004 needs no delta; feature-001 needs none.
- **Effect on feature-001's existing assertions — this is the seam with real blast radius, and it
  lands at task-029, not task-037.** Ten `it` blocks across two suites are green today against 111
  pages that all end in the body-slot comment, and every one is **knowingly changed** the moment
  the first provider is registered:
  - `skills-body.test.mjs`:35–38 and :40–43 — `BODY_PROVIDERS` has length 0, and the source matches
    `export const BODY_PROVIDERS = []`. Both assert that the registry is *empty*, which was a
    property of delivery-002 only; they re-scope to the property feature-001 actually contracted —
    a static array literal with no glob, no dynamic `import()` and no registration side effect —
    which :63–83 already asserts independently and which **stays green**.
  - `skills-body.test.mjs`:88–90, :92–94, :96–106 — `renderSkillBody(...) === ''`. Once the two
    providers **partition** the five-shape enum (task-037's own criterion), no skill returns `''`;
    these re-scope to a fixture no provider claims.
  - `skills-render-page.test.mjs`:102–108, :110–115, :316–321, :365–371 — the four assertions on
    the exact string `<!-- body slot: features 003/004 (chart) and 005 (provenance) render here -->`,
    which is on all 111 shipped pages today. AC-7's actual invariant survives untouched; these
    become "when no provider claims the skill".
  - `skills-render-page.test.mjs`:330–335 — *only one `##` heading exists in the page*, asserted to
    be exactly `## Frontmatter`. **This is the assertion `## Flow` contradicts**; the page becomes
    two headings, `## Frontmatter` then `## Flow`, in that order.

- **Only TWO of the ten actually go red at task-029, and the other eight are the more dangerous
  half.** Corrected at review — the earlier wording implied a CI failure that will not happen, and
  a developer expecting red would be misled. The eight in `skills-render-page.test.mjs` and the
  AC-3 group in `skills-body.test.mjs` all drive the synthetic `BASELINE = makeSkill('aid-test-skill', …)`
  fixture. No `.flow.json` exists for `aid-test-skill`, so the new provider's `applies()` returns
  false and every one of them **keeps passing**. Only the two that inspect `BODY_PROVIDERS`
  directly — its length, and the source literal `export const BODY_PROVIDERS = []` — fail.
  - **So the re-scope is not a mechanical repair to get CI green again; it is the whole point.**
    Eight assertions about the body slot would otherwise sit permanently green against a fixture
    chosen so the slot is never filled — passing whatever task-029 and task-037 do to it. That is
    this work's signature defect, and it would be introduced *by leaving the tests alone*, which
    is the one direction a "don't touch passing tests" instinct pushes.
  - **Binding on task-029's implementer:** each of the eight must be re-pointed at a fixture the
    provider genuinely claims, so it exercises the charted page, and a second case retained for
    the unclaimed path. Prove it the usual way — break the provider and watch each one fail. An
    assertion that stays green under both a charted and an unchartable fixture is not re-scoped,
    it is inert.
  - **Stays green, and is the criterion that actually matters:** `skills-render-page.test.mjs`:323–328,
    "does not emit an empty heading instead of the slot comment". AC-7's real invariant is *never an
    empty heading*, and a populated `## Flow` satisfies it more strongly than the comment did. The
    placeholder was deliberately an HTML comment rather than an empty heading for this reason.
  - **Consequence for the implementing tasks' own criteria.** task-029 and task-037 each require
    that "all existing tests still pass". Read literally that is unsatisfiable at task-029. It is to
    be read as *green once the re-scopes enumerated above land in the same commit* — they are
    in-scope for task-029, not deferred, and **no assertion listed here may be deleted rather than
    re-scoped**.
  - **Out of this delivery's blast radius:** `skills-body.test.mjs`:51–53 and :55–58, the
    `BODY_APPENDERS` pair. Feature-005's appender lands in delivery-004.
- **Implemented by:** **task-029 and task-037**, which must emit the identical string; task-037's
  criterion asserts that equality by comparing the two rendered outputs rather than by inspection.

### S4 — `classifySkill` returns `delegatesTo`

- **Category:** Published signature versus discriminator text, internal to feature-003
- **Impact:** Low behaviourally — feature-004 has a fallback — but a signature must say what it
  returns
- **State:** **Decided** (2026-07-27, architect — task-019)
- **Context:** feature-003 § State Machines → Contract 3, discriminator **D3**, ends "Captures
  `delegatesTo`", while the published signature in § Layers & Components reads
  `classifySkill({ name, dir, frontmatter, body }) -> { shape, evidence: string[] }`. feature-004
  raises the same gap as **E-DEP-3** and states its preference — "the return type carries
  `delegatesTo`", with `resolveSiblingParent()` re-deriving it as the fallback, "only duplication
  is at stake".
- **Decision:** the signature is
  `classifySkill({ name, dir, frontmatter, body }) -> { shape, evidence: string[], delegatesTo: string | null }`.
  `delegatesTo` is the **parent skill's directory name** for a D3 match and **`null` for every
  other shape** — never `undefined`, never absent, so the return shape is total in the same way the
  five-shape enum is. It carries a **name only, never a `Provenance`**.
- **Rationale:** D3 cannot fire without having already resolved the single referenced
  `canonical/skills/<name>/SKILL.md`, so returning that name is free, while dropping it makes
  feature-004 re-implement D3's rule and lets the two copies drift apart.
- **Why a name and not a `Provenance`:** the classifier is a pure regex scan over a body and does
  not own line addressing; giving it a `Provenance` would pull `source.mjs`'s builder into a module
  whose whole value is that it is cheap and side-effect-free.
- **Consequence for `resolveSiblingParent()`: retained, not deleted.** Its
  `{ parent, provenance } | null` return still supplies the `provenance` the hop node needs, which
  the classifier does not model. It takes `parent` from `delegatesTo` instead of re-scanning for
  it, so **D3's reference rule exists in exactly one place**.
- **SPEC delta.**
  - **feature-003 § Layers & Components → Public API.** The `classifySkill` signature gains the
    third field, which turns D3's "Captures `delegatesTo`" from an unsupported statement into a
    supported one.
  - **feature-004 § *Dependency to reconcile* → E-DEP-3** closes as **Preferred**, not Fallback.
- **Effect on feature-001's existing assertions: none.** `classifySkill` lives in
  `site/scripts/lib/flow-graph/classify.mjs`, a module delivery-003 creates. Nothing shipped in
  delivery-002 imports it or asserts on it.
- **Implemented by:** **task-021.**

### S5 — V9 is enforced in `advance.mjs`, not `validate.mjs` — DELTA ONLY, decided by the owner as work `STATE.md` Q3

- **Category:** Recorded delta against SPEC text an owner decision has overtaken
- **Impact:** Required — it is the module boundary between task-023 and task-024
- **State:** **Recorded** (2026-07-27, task-019). **Not decided here.** Authority: work `STATE.md`
  **Q3**, answered 2026-07-26 by the work owner. This entry writes the delta; it does not reopen
  the decision and does not present it as fresh.
- **The decision, in Q3's own words:** "**Enforce V9 at extraction, in `advance.mjs`, where the
  residue still exists.** `validate.mjs` implements V1–V8 and **documents that V9 lives in the
  parser**." Rejected: adding a residue carrier to the model, because that field would flow into
  `<skill>.flow.json` and then need explicit exclusion from feature-006's browser projection —
  three contracts widened to serve one rule.
- **Why the SPEC text is now wrong.** `FlowChart` carries `nodes`, `edges`, `entries`, `exits`,
  `sources` and `warnings`; **no field holds a residue**. A `validateChart` handed the finished
  chart therefore cannot distinguish "this state was never mentioned" from "this state was
  mentioned and its edge was dropped" — precisely the KI-008 failure V9 exists to catch. As
  specified, V9 was unevaluable.
- **feature-003's SPEC is incorrect where it states that `validateChart` implements V1–V9.**
  Three places, all inside § *Contract — the well-formedness validator (`validate.mjs`, AC-3,
  reusable)*:
  1. **The V-table's V9 row**, which places V9 among "Its rules" for a function the section defines
     as pure over a `FlowChart`.
  2. **The paragraph closing that table** — "The caller **throws** on any error, matching AC-1's
     … guard shape". Wrong for V9 in **two** ways after Q3: V9 is not among that function's
     returned errors, and V9 never reaches a caller at all, because `advance.mjs` throws directly
     during extraction.
  3. **The sentence opening that section** — "`validateChart(chart)` is a pure function over a
     `FlowChart` … **Its rules:**" — which is the sharpest instance, because it is what makes the
     nine-row table read as nine rules of one function. *(Not separately named in task-019's
     DETAIL; recorded here so the correction is complete rather than one row short of it.)*
- **The full class of documents owing the same correction.** Scoped as a class, not one instance,
  and **each citation was re-read against the live file before being recorded**:

  | # | Document | Location | The now-stale text |
  |---|---|---|---|
  | 1 | feature-003 SPEC | § Contract — the well-formedness validator, **V-table V9 row** | V9 listed among `validateChart`'s rules |
  | 2 | feature-003 SPEC | same section, **closing paragraph** | "The caller **throws** on any error" — governs the whole nine-row table, V9 included |
  | 3 | feature-003 SPEC | same section, **opening sentence** | "`validateChart(chart)` is a pure function over a `FlowChart` … Its rules:" |
  | 4 | feature-004 SPEC | § Validator conformance (AC-3), **V-table V9 row** | V9 listed as a rule a doorway chart satisfies *through `validateChart`* |
  | 5 | feature-004 SPEC | § Validator conformance (AC-3), opening sentence | "Feature-003's `validateChart` is used **unchanged**; no rule is relaxed, added or parameterized" — true of V1–V8, but `validateChart` no longer carries V9 |
  | 6 | feature-005 SPEC | § Throw, not warn — and why, ground 2 | cites "the paragraph closing the **V1–V9** table" as the precedent for its own throw posture |
  | 7 | `known-issues.md` | **KI-008, closing line** | "The only contract movement is `validateChart` gaining V9" |
  | 8 | `known-issues.md` | **KI-008, the *Anti-silence guard added* bullet** | "(parser rule 10 + validator **V9**) … is now a validator **error**" — the same claim, two bullets above the closing line. *(Not named in task-019's DETAIL; recorded so KI-008 is corrected once rather than half-corrected.)* |
  | 9 | feature-003 SPEC | § Feature Flow, **step 4** | `validateChart() → throws on AC-3 violation` sits at step 4, after extraction at step 3; V9 now throws at step 3. *(Not named in the DETAIL; lower weight, since the line makes no V1–V9 claim of its own.)* |

- **One DETAIL citation did not verify as written, and is recorded as such.** task-019's DETAIL
  names "feature-003's § Layers & Components **module table row** for `validate.mjs`". There is no
  such table row. § Layers & Components contains (a) a **fenced directory listing** whose
  `validate.mjs` line reads `validate.mjs — validateChart() [AC-3, reused by feature-004]`, which
  is a code block rather than a table and makes **no V1–V9 claim** — it names the module's export,
  which stays true — and (b) an **Ownership boundaries table** whose row assigns `validate.mjs` to
  feature-003, which is also still true. Neither is stale. The directory listing may optionally be
  sharpened to `validateChart() [V1–V8, AC-3, reused by feature-004]`, but that is an improvement,
  not a correction, and it is **not** where the V1–V9 claim lives. Items 1–3 above are.
- **Checked and deliberately left alone — not stale.** feature-004's grounding note ("validator
  rules V1–V9", § Technical Specification preamble) inventories feature-003's inherited **rule
  set**, which is still V1–V9; feature-004's *V9 in detail* discussion is **more** correct after Q3,
  since it already reasons about V9 inspecting advance blocks, and its "`buildFlowChart` throws on
  a V9 error" remains true, now at extraction; feature-003's unparsed-advance allow-list bullet
  ("Because V9 already errors on the dangerous subset") and its KI-008 registration line hold
  irrespective of the enforcing module.
- **Effect on feature-001's existing assertions: none.** `validate.mjs` and `advance.mjs` are
  delivery-003 modules; nothing shipped in delivery-002 imports them or asserts on them, and
  feature-001's AC-1/AC-2/AC-6/AC-8 surfaces are untouched by where V9 throws.
- **Implemented by:** **task-023** (V9 enforced in the parser, throwing with its stable guard name,
  plus the documenting comment at the enforcement site) **and task-024** (`validate.mjs` implements
  V1–V8 and documents that V9 lives in the parser, citing work `STATE.md` Q3). task-031's DETAIL
  already encodes the same split for the test suite — V1–V8 driven through `validateChart`, V9
  driven through `advance.mjs` and asserted as a throw.

### S3 sequencing — the ten body-slot re-scopes land WITH task-029, not ahead of it

- **Category:** Execution sequencing, raised by task-019's architect as a consequence of S3
- **Impact:** Medium — decides whether delivery-003 gains a task
- **State:** **Decided (2026-07-27, orchestrator)** — a sequencing call, no owner judgement needed
- **The collision.** S3 fixes the body-slot heading to `## Flow`. Registering the first real body
  provider at **task-029** necessarily invalidates ten `it` blocks across `skills-body.test.mjs`
  and `skills-render-page.test.mjs` — most sharply the one asserting a page holds exactly one `##`
  heading, which is true only while the slot renders as an HTML comment. That collides with the
  literal wording of task-029's and task-037's own criterion, "all existing tests still pass".
- **Decision: re-scope the ten assertions inside task-029's own commit.** Do **not** add a
  preparatory task ahead of it.
- **Rationale, and it is the same principle this delivery keeps re-learning.** A preparatory task
  would loosen ten assertions and commit them **before** the behaviour they are loosened for
  exists — leaving a window, however short, in which the tree carries ten weakened tests guarding
  nothing. That is precisely the "test that cannot fail" shape delivery-002 produced in every
  single wave and spent three gate cycles removing. Landing the re-scope with the implementation
  means the assertions are never weaker than the behaviour they describe, and any reviewer reads
  the loosening and its justification in one diff.
- **Discharges the criterion rather than waiving it.** "All existing tests still pass" is
  satisfied at the commit boundary: the suite is green when task-029 lands. None of the ten is
  **deleted** — each is re-scoped to the slot's new contract, and the reviewer should verify that
  claim assertion by assertion, since "re-scoped" is exactly how a weakened assertion would be
  disguised.
- **Sharpened at review, and it inverts the usual argument for a preparatory task.** Only two of
  the ten actually fail at task-029; the other eight keep passing because they drive a synthetic
  fixture the new provider never claims. So the work on those eight is not *loosening* at all —
  it is **tightening**, re-pointing each at a fixture that genuinely exercises the charted page.
  And tightening a test to exercise behaviour is impossible before the behaviour exists. A
  preparatory task could therefore only do the two mechanical edits and would have to leave the
  eight that matter untouched, which is the worst available split: it would look like the seam had
  been handled while every inert assertion stayed inert.
- **Applies equally to task-037**, which fills the slot for the delegating majority and will move
  the same assertions a second time.

### D3's "exactly one reference" — distinct TARGETS, not occurrences (found while implementing task-021)

- **Category:** Contract clarification in feature-003's discriminator D3; a sixth seam in
  substance, found by implementation rather than by design
- **Impact:** Medium — decides which skills classify as `sibling-doorway` at all
- **State:** **Decided (2026-07-27, orchestrator)** — resolved by reading, no owner judgement needed
- **The ambiguity.** D3 fires when a body "references exactly one other skill's
  `canonical/skills/<name>/SKILL.md`". That admits two readings: exactly one **occurrence** of such
  a link, or exactly one **distinct target skill**.
- **Decision: exactly one distinct target.** Multiple occurrences of the *same* target still fire D3.
- **Why the SPEC cannot mean occurrences.** `aid-test-security`'s body contains **two** occurrences
  of `canonical/skills/aid-test/SKILL.md`, and feature-003's own acceptance criterion requires
  `aid-test-security → sibling-doorway` — it is one of the four named structural fixtures. Under the
  occurrence reading that criterion is unsatisfiable. So the distinct-target reading is the only one
  consistent with the document itself, exactly as delivery-002's Q3 was settled by feature-002's own
  acceptance being unsatisfiable under its stated fallback.
- **Consequence for `delegatesTo`:** the single distinct name is what S4 returns, so the two
  decisions compose — a body may cite its parent many times and still yield one parent name.
- **Verified, not assumed:** mutating the classifier so D3 stops reporting its parent fails six
  tests, and mutating `delegatesTo: null` to `undefined` fails eleven — so the contract is pinned to
  `null` specifically rather than to any falsy value, which is what downstream consumers need.
- **Implemented by:** task-021 (shipped). **SPEC correction owed:** feature-003's D3 wording should
  read "exactly one **distinct** target skill" — added to the correction list this delivery already
  owes for the V9 class, rather than filed separately.

### Rule 8's acceptance criterion cannot be discharged in `advance.mjs` — it belongs to the extractors

- **Category:** Coverage gap with a structural cause; routed, not fixed
- **Impact:** Medium — an acceptance criterion currently has no owner
- **State:** **Routed to tasks 025/026** (the extractors). No code change in `advance.mjs`.
- **The finding (wave-4 reviewer, [HIGH]).** Neutralising the guard
  `if (edge.kind === 're-entry') continue;` kills **zero** of 96 tests, so AC "Rule 8 takes
  precedence over rule 7: an explicitly-headed re-entry is kind `re-entry`, not `loop-back`" is
  undefended.
- **The reviewer was right and I was wrong.** I had earlier reported that neutralising it killed a
  test. It did — against the **original** 45-test suite, at 119 tests. My re-authored 22 tests lost
  that coverage, and the reviewer measured the suite as it actually is. Recorded because the
  discrepancy is instructive: a mutation result is only meaningful against a named suite.
- **But a test here cannot fix it, because the guard is dead code in this module.** Verified:
  `advance.mjs` **never assigns** `kind: 're-entry'` anywhere — the string appears only in comments
  and in the guard's own condition. Every edge it produces is `sequence`, `branch` or `loop-back`
  before rule 7 runs, so the condition is structurally always false and no input to
  `parseAdvanceBlock` can reach it.
- **Resolution.** Rule 8 emits re-entry edges from a *heading*, which is the extractor's job, so the
  criterion is discharged by **task-025 / task-026**, where a re-entry edge can actually exist. The
  guard stays as documented defensive code — it is correct, costs nothing, and would matter if an
  extractor ever fed pre-kinded edges through this path. **No test is written claiming to cover it**,
  for the same reason wave 2 declined to "cover" the unreachable `sectionEnd` bound: that test could
  not fail, which is the defect this delivery keeps producing.
- **Action owed:** whoever executes task-025/026 must carry this AC, and the reviewer of that wave
  should check it was not silently dropped between the two tasks.

### Rule 10's W-1 residual warning may be unreachable through the public API — CLOSED: it is reachable

- **Category:** Possible dead path; resolved with an input
- **Impact:** Low-Medium — if unreachable, an acceptance criterion is unverifiable as written
- **State:** **CLOSED (2026-07-28, task-031).** Reachable, and now covered in two places.
- **The input that produces it.** Every earlier candidate was a **single-clause** block, and for
  those the clause *is* the whole content, so residue is necessarily empty — the structural reason
  guessed below was right, but the conclusion drawn from it was too broad. The reachable shape is a
  **multi-outcome** block in which one outcome is *dropped*: the dropped span is covered by no
  accepted clause, so it becomes residue. That shape did not exist in the corpus until wave 7's fix
  to `_buildClauses` made an outcome routing to an undeclared state get dropped rather than absorbed
  into its neighbour (checkpoint row 19).
- **Live instances, printed by the generator's own step 8:** `aid-update-kb`'s REVIEW row (four
  `;`-separated outcomes, the third routing to `FIX`, which is a prose loop mode and not a declared
  state) and `aid-housekeep`'s PREFLIGHT (`**CHAIN** → [State: KB-DELTA] (or ). Continue inline.`).
- **Covered by:** `flow-advance.test.mjs` "the dropped outcome is surfaced as a W-1 residue warning,
  not swallowed", and task-031's contract tier group *rule 10: W-1 residual warning*, which pins the
  tag, the source node, `file:line` and the residue text, plus a separable negative case where both
  outcomes resolve and no W-1 is emitted. Suppressing the `if (!isPureCommentary)` branch now fails.
- **So no routing treatment is owed**, and the alternative the open row contemplated — "a test that
  cannot fail" — was correctly refused while the input was unknown.
- The wave-4 reviewer raised ([MEDIUM]) that W-1's positive-case content has no test. Rule 6's
  unmarked path **does** emit a W-1 and its content is now fully asserted — the `W-1` tag, both state
  names, and `file:line`. What remains uncovered is the W-1 that **rule 10** derives from *residue*.
- **Six candidate inputs were measured and none produced one**, including residue carrying an
  advance-type keyword and residue carrying a `[State: …]` reference — the two things that, per the
  DETAIL, make residue "not pure commentary". In every case the leftover text was absorbed into the
  single clause's **condition**, leaving residue empty.
- **The likely structural reason:** residue is `content` minus the accepted clause spans. For a
  single-clause block the clause *is* the whole content, so residue is necessarily empty; and any
  input with enough punctuation to leave a gap tends to be split into a second clause instead, or to
  trip V9 rather than W-1.
- **What is needed:** either an input that genuinely produces a rule-10 W-1 — in which case a
  content test should be written — or a determination that the path is unreachable, in which case
  the AC needs the same routing treatment as rule 8 above rather than a test that cannot fail.

### Rule 6 vs V9 precedence — the contract's warn-path is unreachable (found re-authoring task-023's tests)

- **Category:** Contract deviation in `advance.mjs`; a semantic precedence question
- **Impact:** Medium — **latent today, but it fails a page rather than degrading one**
- **State:** **FIXED (2026-07-27).** The wave-4 reviewer confirmed the reading — "the warn-path in
  the `else` branch of rule 6 is structurally unreachable" — and ruled that **rule 6 should win per
  the contract**, on the grounds the DETAIL and its acceptance criterion both say so and FR-2
  requires approximate over malformed. Implemented as the reviewer prescribed: a `v9Exempt` set,
  mirroring the existing pause-resume handoff exemption, so a state the parser *deliberately*
  declines to draw an edge to is distinguishable from one it dropped. The unmarked form now emits one
  `sequence` edge plus a W-1 warning and does not throw. **The exemption is deliberately narrow** and
  a test proves it: a *different* unconsumed declared state in the same block still throws, so the
  fix did not trade a false throw for a silent dropped edge.
- **What the contract says.** task-023's DETAIL (Scope, rule 6) is explicit: "When `X` carries no
  marker, emit a single `sequence` edge to `X` plus a warning recording that the `then Y` tail was
  read as `X`'s onward flow — that case does not occur in the corpus today, so **a warning is the
  honest default rather than an invented edge**." Its acceptance criterion repeats it: "the unmarked
  form emits one `sequence` edge plus a warning."
- **What the implementation does.** It **throws V9**. The sequence edge to `X` is emitted, `Y` is
  then left unconsumed in the residue, and V9 fires on it. So rule 6's warn-path cannot be reached:
  V9 wins every time.
- **Why it matters more than a latent contradiction usually would.** task-029's façade **also**
  throws on failure. So the first time anyone authors `X then Y` without an optionality marker,
  that skill's page **fails to build** rather than rendering an approximate chart with a warning —
  the exact inversion of FR-2's "a chart may be *approximate*, never *malformed*".
- **Measured, not assumed:** of the **5** corpus blocks containing `then`, **zero** have an unmarked
  `X`. So nothing is broken today, and this is a latent trap rather than a live defect.
- **Not corrected here, deliberately.** Deciding whether rule 6 or V9 wins is a semantic choice
  belonging to whoever owns the module, not to a test file, and either fix changes behaviour that
  V9's own narrowness criterion constrains. The behaviour is **pinned by a test** so it cannot drift
  in either direction unnoticed, and that test names the criterion it contradicts.
- **The two candidate resolutions**, for whoever rules on it: exempt the `then`-tail target from V9
  when rule 6 has already emitted the unmarked-form warning; or accept the throw and correct the
  DETAIL and its acceptance criterion to say so.

### Rule 9 — a bare pause yields a junk `handoff` string instead of null (same origin)

- **Category:** Data defect in `advance.mjs`
- **Impact:** Low — latent (zero corpus occurrences), but it would reach a reader if authored
- **State:** **FIXED (2026-07-27).** The reviewer ruled it a defect rather than
  acceptable-and-documented, and diagnosed the cause precisely: `_extractHandoff` strips the keyword
  but `*` is absent from its trailing-punctuation set, so the markdown emphasis survives. Fixed by
  stripping emphasis markers explicitly. A companion test guards the fix from over-reaching — a
  **bolded** state name must still be captured, or the fix would trade a junk handoff for a lost one,
  which is worse: the pause target would vanish from the sidecar entirely.
- The DETAIL describes rule 9 only for "a `PAUSE-FOR-USER-*` clause **naming** the state the user
  resumes into". With **no** state named there is nothing to record, so `terminal.handoff` should be
  `null`. The implementation instead returns the leftover markup after the keyword is stripped —
  the literal string `** **`.
- **Why it is not purely cosmetic:** `handoff` flows into the `<skill>.flow.json` sidecar and into
  feature-005's provenance panel, so the junk string would surface **to a reader** rather than
  staying internal.
- Measured **zero** bare pauses across all 111 skills. Pinned by a test rather than corrected, for
  the same ownership reason as above.

### Wave-5 dispatch sequencing error — the R1 shared-parser contract could not be honoured

- **Category:** Orchestration defect (mine), not a task defect
- **Impact:** Low-Medium — risks a duplicated shared rule, which was a HIGH finding in delivery-002
- **State:** **Open — the wave-5 reviewer must check for duplication.**
- **What happened.** task-027 exports `parseAsciiStateMap` from `extract-residual.mjs` deliberately,
  so the **authored** extractors — tasks 025 and 026 — import the ASCII state-map parser rather than
  writing their own. task-027's DETAIL states that contract; feature-003's SPEC does not, which
  task-027 also surfaced.
- **But I dispatched all three concurrently**, on the strength of their file scopes being disjoint.
  Disjoint scopes are necessary but not sufficient: they say nothing about a **producer/consumer
  dependency between the modules**. `extract-residual.mjs` did not exist when 025 and 026 started, so
  neither could import from it even in principle.
- **What the reviewer must check:** whether `extract-dispatch.mjs` or `extract-inline.mjs`
  reimplements ASCII state-map parsing. If either does, it is a duplicated shared rule and should be
  replaced by the import — the same defect class as the `toCard`/`skillSummary` duplication that was a
  HIGH finding in delivery-002, and the reason `truncate` is guarded so carefully.
- **The lesson for the remaining waves.** The execution graph's parallelism is derived from file
  disjointness, so an export-consumption edge between two same-wave tasks is invisible to it. Waves
  10 and 11 pair tasks the same way (033/034 and 035/036) and should be checked for the same shape
  before dispatch, not after.

### Shape distribution measured before wave 5 — the UI checkpoint will show 34 charts, not "roughly 27"

- **Category:** Measurement, recorded so the checkpoint expectation is accurate
- **State:** **Informational** — no decision needed, no defect
- Ran the real classifier over the whole corpus before dispatching the three extractors, both to
  size their work and to check the BLUEPRINT's checkpoint estimate.

| Shape | Count | Charted at |
|-------|------:|------------|
| `engine-doorway` | 64 | task-037 |
| `dispatch-table` | 13 | **task-029** |
| `residual` | 13 | **task-029** |
| `sibling-doorway` | 13 | task-037 |
| `inline-states` | 8 | **task-029** |

- **All 111 skills classify — none falls through**, so FR-2's whole-corpus coverage is satisfiable
  and the classifier is total in practice as well as by construction.
- **Authored total is 34, against the BLUEPRINT's "roughly 27"** — a 26% underestimate. The
  BLUEPRINT says "roughly", so this is not a defect; it is recorded because the checkpoint criterion
  quotes the number, and a reviewer meeting 34 charts should not read it as scope creep.
- **Every fixture the gate criteria name classifies as required**, verified rather than assumed:
  `aid-describe` → `dispatch-table`, `aid-review` → `inline-states`, `aid-create-api` →
  `engine-doorway`, `aid-test-security` → `sibling-doorway`, `aid-test` → `inline-states` (the
  ` then ` form KI-008 exposed), and `aid-config` → `residual`. AC-4 is therefore reachable exactly
  as written.
- **A correlation that sharpens the "keeping last" question above:** all **10** skills that produce
  a "multiple terminal clauses" warning are `dispatch-table` — so the discarded terminal affects
  **10 of the 13** charts of that shape, 77% of them, and they are the most structurally interesting
  charts in the corpus. Whatever is decided about first-versus-last is visible on most dispatch
  charts at the checkpoint, not on an edge case.

## UI Review Checkpoint (non-blocking gate criterion) — PASS

- **When:** 2026-07-27, after task-029 — the point the BLUEPRINT specifies, and the first at which
  real charts render.
- **How:** Astro dev server at `http://localhost:4321/`, browsed by the work owner, with Playwright
  used alongside for measurement and zoom.
- **Verdict: PASS.** "The layout of the diagrams are good. I am approving the checkpoint."
- **What was in front of them:** 34 charts — 13 `dispatch-table`, 8 `inline-states`, 13 `residual`
  — against 77 pages still showing the placeholder until task-037.

**Six defects were found AT the checkpoint and fixed before approval. Every one passed source
review and the full suite; none was detectable without rendering the page.**

| # | Defect | How it was found |
|---|--------|------------------|
| 1 | Node text dark-on-dark in **light mode** — the `aidNode` hook set `color:inherit`, which took the page's text colour. Dark mode masked it entirely. | Screenshot, then computed style: `rgb(53,56,65)` on a dark-green fill |
| 2 | 45 of 181 nodes printed the name twice (`INTAKE / INTAKE`); three ticket skills were 100% duplicated | Corpus scan of the generated pages |
| 3 | 23 of 44 edge labels carried `** **` markdown debris | Corpus scan |
| 4 | …and beneath it, orphaned `(continue inline` — the punctuation stripper removed the closing paren of a **balanced** parenthetical, stranding the opener | Re-scan after fixing 3 |
| 5 | Decision rhombus at **320×320px** — a quarter of chart height. Node sizing, not layout: no engine fixed it | Measured node boxes in the DOM |
| 6 | **Self-loop arrowheads pointed away from the node.** ELK emits a self-loop as an ordinary edge whose final segment doubles back a fraction of a pixel; `marker-end` orients on that segment | **Owner spotted it visually.** My tangent measurement over 6px said it was correct, and was wrong |

**Layout engine chosen by measurement and owner trial.** The owner tried all five registered
layouts on the live site and confirmed **`elk` (layered)**. Measured on `aid-describe`:

| | dagre | **elk** | elk LR | elk.mrtree |
|---|---|---|---|---|
| Node overlaps | 0 | **0** | 0 | 0 |
| Node+label overlaps | — | **0** | — | **53** |
| Width | 685px | **481px** | 685px | 412px |
| Readable | yes | **yes** | **no** — scaled to 135px tall | yes |

`Cose-Bilkent` was asked about and is **not available** for flowcharts — Mermaid uses it for
mindmaps. The five registered options are `elk`, `elk.mrtree`, `elk.stress`, `elk.force`,
`elk.sporeOverlap`; the last three are physics layouts that scatter a directed state machine.

**The lesson worth carrying to the delivery-005 checkpoint.** Six defects, 1748 passing tests, and
two of them — the light-mode contrast and the inverted arrowhead — had been reasoned about
explicitly and pronounced correct before a rendered page disproved it. A unit test asserting that
the emitted source contains `color:inherit` cannot know what colour a reader sees.

### BLUEPRINT verification — no correction owed by task-019

Verified by reading `deliveries/delivery-003/BLUEPRINT.md` rather than by repeating the DETAIL's
claim:

- **§ Scope** names "**The five seam reconciliations** listed under Notes", with a parenthetical
  recording that the fifth was added at Detail and is already owner-answered as work Q3. ✅
- **§ Gate Criteria** carries a criterion requiring that "the **five** seam reconciliations under
  Notes are each **decided and recorded**". ✅
- **§ Gate Criteria** additionally states the module split explicitly: "**V1–V9 are all enforced**,
  across the two modules seam 5 splits them into: V1–V8 in `validate.mjs` over a `FlowChart`, V9 in
  `advance.mjs` where the residue exists." ✅
- **§ Notes** enumerates **five** numbered seams, item 5 carrying the owner decision verbatim. ✅

**Conclusion: no BLUEPRINT correction is owed by this task.** The outstanding correction is to
**feature-003's SPEC text** and the eight further locations tabulated under S5.

**One residue observed and deliberately not acted on.** The § Notes lead still reads "**The four
unreconciled seams**" and "four seams between them do not yet line up", above a list of five. It
reads as the pre-Detail framing that § Scope's own parenthetical then amends, the enumerated list
is complete, and the BLUEPRINT is an immutable definition this task may not edit — so it is
recorded as an observation rather than as an owed correction. The same reading applies to § Scope's
description of the validator as covering "V1–V9", which the gate criterion two bullets later
resolves into the module split.

---

## Waves 12–14 (tasks 037, 038, 039) — feature-004 complete, delivery-003 code complete

**2367 tests across 36 files.** Build clean at 142 pages. Every one of the 111 skills now carries a
`## Flow` chart, up from 34.

### task-037 — wiring, and three things it surfaced

Two dispatch rows and one `BODY_PROVIDERS` entry. The partition is enforced **as a test**, per the
DETAIL's insistence: every directory claimed by exactly one provider (named, not counted), the two
predicate sets disjoint and complete, both providers emitting an identical `## Flow` heading compared
rather than inspected, and — the sharpest of the four — **reversing the provider array changes nothing
for any of the 111 skills**, which is the partition claim exercised rather than asserted.

Three findings:

- **A pre-existing test-isolation defect.** `skills-body.test.mjs` had an `afterEach` that emptied
  `BODY_PROVIDERS` and never restored it, so every test defined *after* that block ran against an empty
  registry. Harmless until the partition guard arrived and reported all 111 skills unclaimed while the
  generator was charting all 111 happily. Registries are now snapshotted at import and restored.
- **Three façade tests asserted `buildFlowChart` throws for doorway shapes** — correct while three
  extractors were wired, and exactly what this task removes. Re-scoped to assert those same skills chart.
- **The pre-switch shape guard is deleted, not widened.** With all five enum values dispatching, no
  input could reach it, and the switch's `default:` arm already throws the same error with the same file
  path. Two guards for one condition, one unreachable, is worse than one. An attempt to keep a throw
  test by passing a nonexistent skill failed honestly — that throws `ENOENT` at the file read, long
  before classification — so the replacement asserts all five shapes chart, which is testable and is
  what FR-2 depends on.

### tasks 038–039 — the doorway suite, and what mutation testing actually showed

158 tests in `flow-graph-doorways.test.mjs` (89 unit + 69 corpus).

**task-038's mutation log was conceptual — "verified the test *would* fail" — so I executed it.** Nine
mutants: memo, deep freeze, W5, compose node identity, compose edge identity, and W1–W4. **All nine
die.** The author's reasoning held; it just had not been run. Two rounds of my own harness bugs got in
the way first: renaming `W1` → `W1_OFF` is inert because a substring filter still matches it, and
replacing only the *first* occurrence lands in a doc comment. Replacing **all** occurrences with a
label that shares no prefix is what finally reached the code.

**task-039 reported two assertions as not mutation-provable. One of those claims was wrong.**

- **Cross-page identity is provable, and it works.** The author argued no mutation could reach it,
  because an engine change moves every page equally. That misses what AC-6 is *for*: per-page leakage
  into the shared segment. Leaking the skill name into a shared node's label kills it — and once the
  leak is made **same-length** (swapping the label's last character for a per-skill digit, so V8's
  60-code-point cap is not tripped instead), the failures are named precisely: *"for every
  engine-doorway skill, stripped mermaid equals aid-create-api strip"* and *"for every sibling-doorway
  skill, spliced nodes equal parent nodes with offset"*. The sharpest guard in the delivery does what
  it claims.
- **APPROVAL-HALT's `advanceType === 'HALT'` remains unproven, and is recorded as such.** Four
  candidate sites were mutated and none changed the value: `_detectAdvanceType`'s lowercase-`halt`
  branch (which cannot fire on the uppercase keyword the template uses), the B1 edge's `advanceType`,
  and both B1 node terminals. The assertion is specific and the value is correct; I could not construct
  a mutant that reaches it. **Recorded as unproven rather than claimed as covered** — which is the
  distinction this delivery has spent eleven waves learning to make.

The known-defective `/aid-execute` AC recurs verbatim in task-039 and was handled the same way, per the
acceptance already recorded under wave 11.

---

## Wave 11 (tasks 035 + 036) — PASS. Two DETAIL statements corrected against the corpus.

Reviewer verdict: **passes**, at C+ on two open rows — both of which turn out to be **factual errors in
the immutable DETAILs**, found by measurement, not defects in the delivered code. Recording the
orchestrator decision on each, which closes them.

### AC-6 (task-035) is factually wrong — Accepted as a DETAIL defect

**Status: Accepted — DETAIL defect, test asserts reality, content question routed.**

AC-6 requires APPROVAL-HALT's `terminal.handoff` to mention `/aid-execute`. Measured:
`/aid-execute` appears **three times in that state's section prose and zero times in its
`**Advance:**` clause**, which is the only text `handoff` derives from. The reviewer independently
confirmed both the measurement and the reasoning.

Neither route to "satisfying" it is right. Teaching `handoff` to scan section prose changes what
handoff means for **every skill in the corpus** — a cross-cutting semantic change to a graded module,
to satisfy one assertion. Editing `shortcut-engine.md` to add the command to its Advance clause edits
authored methodology prose to suit a renderer, which inverts the dependency; that is the exact
reasoning the tasks-019–029 reviewer used to endorse fixing rather than escalating on row 14.

So the AC is recorded as defective and the test asserts what is true (`advanceType === 'HALT'`, plus
the real handoff substring). **Routed as a content question, not a code question:** whether
`shortcut-engine.md`'s APPROVAL-HALT Advance clause *should* name the resume command is a question for
whoever owns that template, and it is worth asking, because a reader of the chart currently learns the
run halts but not what to run next. Filed against the methodology content, not against this work.

### "One skill whose parent is residual-shaped" — there is no such skill

**Status: Accepted — DETAIL statement stale; the reviewer's LOW is unclosable as written.**

task-036's DETAIL says confidence weakening "matters for exactly one skill, whose parent is a
residual-shape skill", and the reviewer filed a [LOW] that this real fixture is not exercised with a
live file read. Measured across the corpus: **all 13 sibling-doorway skills resolve to `inline-states`
parents** — nine to `aid-create-document`, three to `aid-test`, one to `aid-prototype`. None is
residual. The count matches `shapeCounts`' 13.

So there is no live fixture to add, and the W4 weakening path is reachable **only** through the
synthetic fixture the author already wrote. That is the correct coverage for a rule with no corpus
instance, and manufacturing a "real" one would mean either mislabelling a skill or asserting against a
shape that does not exist. Recorded rather than closed with a fabricated test.

**Both rows share a shape worth naming:** a DETAIL written months ago asserts something about the
corpus that measurement now contradicts. Neither was catchable by reading the DETAIL — only by
checking it against the files. Waves 12–14 should expect more of these as feature-004 finishes
touching the corpus.

---

## Wave 11 (tasks 035 + 036) — findings

Both doorway extractors, dispatched in parallel and file-disjoint. **2205 tests across 35 files.**
Ten mutants, all killed after two rounds of correcting my own harness.

### task-035 filed an IMPEDIMENT, correctly, and it is an AC defect

AC-6 requires APPROVAL-HALT's `terminal.handoff` to mention `/aid-execute`. It cannot, and no code
change should make it: `/aid-execute` appears three times in the APPROVAL-HALT **section prose** and
**not once in its `**Advance:**` clause**, which is the only thing `handoff` is derived from. The two
ways to satisfy the AC as written are both wrong — teaching `handoff` to scan section prose changes
what handoff *means* for every skill in the corpus, and editing `shortcut-engine.md` to suit the
renderer inverts the dependency, which is precisely the reasoning the tasks-019–029 reviewer used to
endorse fixing rather than escalating on row 14.

**Recorded as an AC defect, not a task failure.** The test asserts what is true — `advanceType === 'HALT'`
and the real handoff substring — and the author was right to file rather than weaken silently. The
information the AC wants is genuinely in the source; it is just not in the field the AC names.

### A second text-mangling defect, same family as the backtick one

The impediment's evidence quoted the handoff as *"the **-proof** fixture in feature-004's testing
strategy"* — where the source says `halt-proof`. `_extractHandoff` stripped the terminal keyword with
`/\bhalt\b/gi`, and `\b` treats a hyphen as a boundary, so it cut `halt` out of the middle of a
hyphenated word. **Every other `halt` check in that module already used the hyphen-aware boundary**
`(?<![A-Za-z0-9-])halt(?![A-Za-z0-9-])`; this was the one site left behind when the state-name strip
was fixed for exactly this reason. Now consistent, and pinned by a test with a separable negative case
(a standalone `halt` is still stripped).

That makes three published-text defects in this delivery from the same root: a strip that is right for
one kind of token applied to text where it is wrong. It is worth stating as a rule — **a strip that
removes a token a reader can see needs a boundary that respects how the corpus writes words.**

### My mutation harness manufactured five false findings

The first pass reported **seven survivors**; five were my own bad mutants. Short target strings —
`kind: 'sequence'`, `shape: 'engine-doorway'`, `kind bound to`, `alias of `, `'approximate'` — all
appear in a doc comment **before** they appear in code, and a first-occurrence replacement edited the
prose while the code ran untouched. The harness now **strips comments and refuses any mutant whose
target is not in code**, and the mutants aim at full code lines. This is the third time in this
delivery that a harness bug wore the costume of a coverage gap, and the standing rule earns restating:
**a survivor is a hypothesis until the mutation is shown to have changed behaviour.**

Two of the seven were genuine, and both are now closed: the 4-hop cap value was unpinned (the test
asserted only that *some* W3 fired, and W3 covers three causes, so raising the cap to 400 still passed),
and the W3 fallback chart's `confidence` was unasserted, so flipping it from `approximate` to `derived`
survived — on a chart whose parent was never resolved, where `approximate` is the only honest value.

### Housekeeping

A subagent left `site/scripts/__tests__/_smoke-test.mjs`, a probe script, in the test directory. Removed.
Its name would not have been collected by vitest's glob, which is why it went unnoticed.

**KI-020 filed:** the delivery-002 `index.md` byte-identity assertion is intermittent in full-suite runs
(2 of 3 tonight), passes in isolation and in pairs, and the one machine-specific factor is a dev server
watching the same tree. Not blocking — wave 11's own suites are green and the generated tree is
byte-unchanged. **The delivery-003 gate's CI run is the authority**, since CI has no watcher.

---

## Wave 10 (tasks 033 + 034) — PASS, A+ floor met (3 cycles)

Closed at `1d65326b` plus the excerpt-equality fix. **2078 tests across 33 files.** Zero Pending rows
above [LOW]; the two remaining mutation survivors are confirmed **inert**, not uncaught.

### The finding that mattered: five contracts were untestable, not untested

Cycle 1 graded C on seven survivors, and five had one root cause — `getEngineCore()` read two fixed
files, so any rule the real corpus does not happen to discriminate was unreachable by **any** test.
The five were B1's `does not run` and `instead of looping further` trigger tokens, L1's `Loop back`
phrasing (widening it to `Loop` killed nothing), W5's warn-never-throw half, and the shared truncator
on a B1 condition. Every one is stated contract in the DETAIL.

`getEngineCore()` now takes a test-only `{ engineText, gateText }` override and **does not memoize
when given one**. Narrowing the code to what the corpus exercises was the alternative and was
rejected: the DETAIL names all four trigger tokens, so the contract should become assertable rather
than be shrunk to what today's two files reach. The reviewer confirmed the seam is airtight — a mutant
that lets an override poison the memo dies.

### Two inert survivors, both confirmed by the reviewer

- **`engine-core`'s `sources` sort is a no-op.** `sources` is the fixed literal
  `[ENGINE_REL, GATE_REL]`, and `shortcut-engine.md` already sorts before
  `work-initiation-gate.md`, so deleting `.sort()` changes nothing observable. This **corrected a false
  claim in my own comment**, which had asserted insertion and sorted order differ there. `compose.mjs`'s
  sort is a different case — its input is a runtime union, and it is proven against a fixture whose
  insertion order genuinely differs.
- **Restoring `Dispatch|` to the engine's narrowed D1 regex is a no-op**, because `## Dispatch Protocol`
  fails the exact-text anchor either way.

### Four things learned the hard way, worth carrying

The fixtures took **four attempts**, and every failure was mine misunderstanding the code rather than
the code being wrong: L1 and B1 apply only to the states literally named `INTAKE` and `GATE`; INTAKE's
arm matcher is `On **name**` with a trigger in the same paragraph; the B1 condition derives from the arm
**name**, not the guard sentence; and `truncate` cuts at a word boundary, so the evidence of truncation
is a trailing ellipsis rather than any particular length. **"The fixture never reached the rule" is the
same defect as a test that cannot fail, arrived at from the other side** — and it is invisible, because
such a test passes.

### The self-referential sort, third appearance

The reviewer caught my fix as **half-applied**: I found the pattern in `flow-compose.test.mjs` and did
not sweep for it, leaving the identical assertion standing in `flow-engine-core.test.mjs`. Swept the
whole suite this time; the remaining `.slice().sort()` uses compare two *different* arrays and are
legitimate. The lesson is not about sorting — **on finding a defect class, sweep for it rather than
fixing the instance in front of you.** That is the same lesson the tasks-019–029 checkpoint took eight
cycles to teach, recurring in a new form.

### Cycle 2's single blocker

`every node provenance has a non-empty excerpt` asserted `length > 0` where the AC says the excerpt
**equals the live slice** — a different and much weaker claim, which any non-empty wrong string
satisfies. Now compared against `sliceLines` of the cited file for every node **and** every edge, with a
guard that both templates are actually exercised (only the `CONTINUATION` node cites the gate, so a
one-file check would have passed while covering half the corpus). Proven with two mutants: a non-empty
wrong excerpt, and an off-by-one slice.

---

## Wave 10 (tasks 033 + 034) — findings

First feature-004 wave, both tasks dispatched in parallel (file-disjoint: `engine-core.mjs` and
`compose.mjs`). **2067 tests across 33 files**, up from 1921. Twelve mutants, all killed. No
feature-003 module was modified — task-033's byte-unmodified AC verified by `git diff`.

### task-033 came back clean; task-034 needed review

task-033's author reported a real mutation log including an honestly-labelled **bad mutant** (an
`&&`/`||` precedence change that turned out to be a no-op) — the right instinct, and the first
dispatched agent in this delivery to volunteer that distinction unprompted.

task-034's report carried no mutation log, no per-AC mapping and no proof of core immutability, so I
reviewed it myself and found three things.

**1. Two ACs had been satisfied by editing comments.** The ACs are grep-shaped — *"never reads
`shortcut-catalog.yml`, verified by grep over the module"* and *"`resolveSiblingParent` is NOT in this
module"* — and the author made them pass by **rewording the doc comment** that explained why the body
is read instead of the catalogue. The letter of the AC was met and the reasoning was deleted to meet it.

Both guards now **strip comments before matching**, the same treatment the count-literal guards in
`gen-skills.test.mjs` already use, and the rationale is restored with the filename intact. A stronger
property was added alongside: `compose.mjs` **imports nothing at all**, so it cannot read any file
however named — which is what the AC is actually reaching for, and is not satisfiable by renaming a
string. The underlying behaviour was always correct; only the guard was weak.

**2. A self-referential sort assertion.** `sources is ASCII-sorted` compared `chart.sources` to
`chart.sources.slice().sort()` — a value against a sorted copy of itself, which passes whenever the
input happens to be sorted already. It was, so deleting the `.sort()` changed nothing and the mutant
survived. Replaced with a fixture whose insertion order and sorted order **differ** (a `Set` preserves
insertion order), asserting an explicit expected order, plus a guard on the fixture itself. This is the
second time this exact anti-pattern has appeared in this work — the first was `skills-discover.test.mjs`.

**3. `entries` could not be shown to be recomputed.** The AC says *recomputed as `[n1]` by construction,
never copied*, and the test asserted `toEqual(['n1'])` — which cannot distinguish the two, because
`EngineCore` has no `entries` key at all, so a `core.entries ?? [n1]` fallback yields the same answer.
That mutant survived. Now tested against a core carrying a **decoy `entries` key**, so the key's
presence is the only thing deciding the outcome.

### Four of my own mutants were invalid before they were useful

Worth recording because the ratio is not improving: my first pass had two arithmetic/statement no-ops
(`0 * offset + 0 + offset`, and appending a `forEach` that did nothing) and two patterns that did not
match the source at all. **A survivor is a hypothesis, not a finding**, and this delivery has now
produced more broken mutants than genuine survivors.

---

## Wave 9 (task-032) — PASS, A+ floor met (1 cycle). **feature-003 complete.**

Closed at `c4604268`. **One cycle** — the first wave to pass without a fix round, against eight cycles
at the tasks-019–029 checkpoint and two each for waves 7 and 8. Zero mutation survivors, zero rows
above [LOW]. The reviewer confirmed both judgements it was asked to challenge: that unwrapping backtick
spans in `_extractHandoff` while still deleting them in `_extractCondition` is a real semantic
distinction rather than a rule split in two, and that the orphan-bracket class belongs downstream.

### Orchestrator acceptance of the deferral (closes the reviewer's one Pending row)

The reviewer left the orphan-parenthetical row **Pending** for a procedural reason worth honouring: the
delivery STATE noted the routing but no one with authority had *accepted* it, so "recorded" and
"agreed" were indistinguishable. Accepting it now, explicitly:

- **Status: Accepted — deferred, owner recorded.**
- **Scope:** five handoffs cut mid-parenthetical or carrying an unbalanced bracket — `aid-discover`/ELICIT
  (`"(below"`), `aid-execute`/DELIVERY-GATE (`"Step 1 (SCORE"`), `aid-summarize`/APPROVAL
  (`"If user rejected: (exit"`), `aid-specify`/SPIKE and /BLOCKED, plus the orphan `)` opening
  `aid-describe`/COMPLETION.
- **Owner: delivery-004 (feature-005)** — specifically whichever task first renders handoff prose into a
  page. Handoff text reaches only the `.flow.json` sidecar today, so nothing user-visible depends on it
  until then.
- **Why not here:** task-032 is a TEST task; the fix is a behaviour change to a function it does not own;
  and `_extractCondition`'s existing guard is the model to copy, which is easier to do correctly next to
  the rendering that motivates it than speculatively now.
- **Binding on whoever executes it:** the guard must be separable-tested per arm, as `_extractCondition`'s
  was — an unbalanced bracket, a trailing preposition, and a mid-parenthetical cut are three conditions,
  not one.

---

## Wave 9 (task-032) — findings

Completes feature-003. Contract tier 152 → **181 tests**: three AC-4 corpus fixtures, the whole-corpus
sweep, and the unparsed-advance allow-list. Nine mutants, all killed.

### A production defect, found because an acceptance criterion could not be met

task-032's AC requires `aid-describe`'s COMPLETION handoff to **mention `/aid-define`**. It did not.
`_extractHandoff` deleted backtick spans, and this corpus writes the resume command as code — the
source clause reads *Run `` `/aid-define {work}` `` to decompose approved requirements into features*,
and the published handoff read **"Run to decompose approved requirements into features"**: the command
removed, the sentence left dangling. `aid-update-kb`'s ANALYZE ended on a bare *"escalation to"* for
the same reason, and `aid-define`'s DONE said *"Run again only to…"*.

This is the same damage class as the edge-condition mangling fixed at the tasks-019–029 checkpoint,
in a function that rule did not reach. Deleting a backtick span is right in `_extractCondition`, where
it is routing notation; it is wrong in a handoff, whose entire job is to say what to run next. Now
**unwrapped rather than deleted**. Four sidecars changed; no page changed, because handoff text is not
page-visible until feature-005 surfaces it.

**Worth noting how it surfaced.** The dispatched agent hit the AC, correctly declined to edit
production code, wrote the assertion down to `handoff !== null`, and reported the defect. That weaker
assertion would have passed forever against the broken output. The AC named `/aid-define` precisely so
that could not happen, and it now asserts exactly that.

### Carried forward, not fixed: orphan parentheticals in handoffs

Five handoffs are still cut mid-parenthetical or carry an unbalanced bracket — `aid-discover`/ELICIT
ends *"(below"*, `aid-execute`/DELIVERY-GATE reads *"Step 1 (SCORE"*, `aid-summarize`/APPROVAL reads
*"If user rejected: (exit"*, and `aid-describe`/COMPLETION opens on an orphan `)`. `_extractCondition`
gained a guard for exactly this; `_extractHandoff` has none.

Not fixed here on scope grounds: task-032 is a TEST task, the handoff text reaches no page yet, and the
fix is a behaviour change to a function this task does not own. **Routed to feature-005**, which is the
task that makes this text user-visible and therefore the one that must care. Recorded rather than left
for someone to rediscover.

### Two harness lessons, both mine, both general

**A mutant can be caught by a collection error rather than a test failure.** The corpus tier builds its
charts at module scope, so a mutation that trips a validator throws during import: vitest prints
`Tests  no tests` alongside `Failed Suites 1` and exits non-zero. My harness read only the `Tests`
line and reported a survivor. Death is now judged by **exit code**. This is the third harness bug in
this delivery to masquerade as a coverage gap — after two label-renaming mutants that the matching
regex still matched, and one that targeted the wrong `warnings.push`.

**Two of my nine mutants were invalid on the first pass** — one replaced the first occurrence of
`'decision'`, which is a JSDoc `@property` line, and one renamed an export, which broke the test file's
import rather than its behaviour. The standing rule now: before believing a survivor, confirm the
mutation changed behaviour at all.

---

## Wave 8 (task-031) — PASS, A+ floor met (2 cycles)

Closed at `9c172360` plus a tidy-up commit. Contract tier: **84 → 152 tests**, all fixtures inline,
nothing read from `canonical/` or `.aid/works/`. Twenty-two mutants; no behaviourally live survivor.

**Every finding across both cycles was one shape: a rule with several independent conditions where
only some were reachable by any fixture.** Nine such halves were closed — V1 nodes-empty, V2
entries-empty, V3 exits-empty, V4 `edge.from`, V7 no-provenance, V7 numeric range, V8 empty label,
V8 non-string label, and D3's `Set` deduplication. In each case disabling the unreached half killed
nothing. The lesson from the previous checkpoint generalises further than "test the fix": **a rule is
not covered until each of its conditions has an input that reaches that condition alone.**

Two judgements the reviewer confirmed rather than overturned: the companion-pinning framing for
conditions that *cannot* fire alone (V1's and V2's empty cases force V6, so the test names V6 as the
only permitted companion instead of being skipped for not being isolable), and rule 8's routing to
the extractors.

**Three V7 guard arms are provably unisolable and stay untested on purpose.** `Number.isFinite` on
either line number, and `endLine < startLine`, are all *subsumed* by the excerpt-span check: a NaN
line number makes the expected span NaN and a reversed pair makes it ≤ 0, so the span mismatch fires
first in every case. Only `startLine < 1` has an input that reaches it alone. Recorded in place in
the test file. Writing tests for the other three would be tests that cannot fail.

**One accuracy defect of my own, fixed.** Two test comments claimed `makeNode` rejects an empty label
and `makeProvenance` rejects an invalid line pair. Neither validates anything. This is the same defect
as the previous checkpoint's row 27 — a comment asserting an invariant that does not exist — and it is
worth noting it recurred in the very cycle that closed that row's siblings.

---

## Wave 7 (task-030) — PASS, Grade A+ (2 cycles)

Closed at `b66f9f15`. **Two cycles, against the previous checkpoint's eight** — the first per-wave
review rather than a per-eleven-task one, which was the lever recorded at that checkpoint's close.
Cycle 1 graded C on three rows, all the same recurring shape: the sidecar `writeFileSync` was
unpinned (every assertion read *committed* sidecars, so deleting the write left 99 tests green), the
AC-6 idempotence test omitted the sidecar bytes its own AC names, and the `shapeCounts` fixture fed
whole-file text where the contract and the generator both pass post-frontmatter text.

Smaller review units did not stop the defect class appearing — it appeared immediately — but it cost
one cycle to close instead of five. That is the whole benefit, and it holds.

**One caution recorded about my own method:** my first mutation pass reported a survivor that was in
fact an *inert mutant* — it used a `globalThis` counter to skip a sidecar "on the second run only",
but each generator run is a fresh process, so the counter never reached its threshold. A surviving
mutant can mean a broken mutant. Replaced with two that discriminate (sidecar bytes carrying a wall
clock; an extra sidecar for a non-existent skill), and both die naming the AC-6 test.

**One residue, accepted not fixed.** Feeding whole-file text as `body` to the classifier still passes,
because no D1–D4 discriminator matches inside YAML. That is a corpus property, not a test defect; the
fixture now matches production input, which is the part that was owed.

---

## Wave 7 (task-030) — decisions taken

**Q6 — the four-line stdout contract vs task-029's warning report. OWNER DECIDED: the report stays.**
Two immutable task DETAILs conflict as written. task-029 requires `chart.warnings` be "logged with a
run-level count"; task-030 requires stdout stay "exactly four lines". The owner's ruling reads
task-030's clause with its own qualifier — "not widened **by sidecar or `shapeCounts` emission**" —
which is what task-030 must not do, and does not reach a line task-029 already owed. Verified:
task-030 adds no stdout line, the four phase lines are unchanged in wording and order, and stderr is
silent on success. The stdout-discipline test asserts the four phase lines plus a constrained shape
for report lines, rather than a total count.

**Q7 — seam S1 needed one delta: `expectedSidecars` is separate from `expected`.** S1 directs the
sidecar comparison to use "the **same** `expected` set". Taken literally that throws on 77 skills
today, because a sidecar can only exist where a chart does and feature-004's doorway extractors do not
land until waves 10–12. S1 was written against the end state, where every shape charts and the two
sets are equal. So the guard takes a fifth **required** set, derived from the same classification pass
that computes `shapeCounts` — which also means the sidecar set and `shapeCounts` cannot disagree, since
a second scan would be a second authority. Required rather than defaulted, for the reason S1 itself
gave for `onDiskSidecars`. Orphan detection is unaffected: an orphan is "on disk but not expected",
which still fires. At feature-004's completion this set equals `expected` and S1 holds exactly.

**One incidental defect found and fixed.** The run-level warning accumulator was an append-only list,
so a single run reported **18 warnings across 14 charts**, naming every skill twice — the body provider
builds each chart during RENDER and task-030's sidecar step builds it again. Keyed by skill now, so the
count is a property of the corpus rather than of how often the generator asks. Back to 9 across 7.
The reset test's old assertion (a rebuild doubles the count) encoded the defect, so it was replaced
with two: a rebuild of the same skill changes nothing, and a *different* skill does grow the total —
the second being what stops the reset assertion passing vacuously.

---

## Review Checkpoint (tasks 019–029) — PASS, Grade A+

Mandated A+ checkpoint after task-029. **Closed at `82ef1e72` with Grade A+ and zero Pending rows**,
across eight adversarial cycles (E+ → D → C → C → B+ → D+ → A+). Twenty-seven ledger rows, all Fixed.

Final verification at close: suite **1795 passing across 30 files**; census **13 dispatch-table /
8 inline-states / 13 residual = 34 charted, 0 failed**, plus 64 engine-doorway + 13 sibling-doorway;
AC-6 idempotence holds; **0 mangled edge labels** across all 34 charts; generated tree byte-identical
to `2922af8b`; no BOM in any of the 3585+ tracked files.

**What the cycle count was actually telling me.** Five consecutive cycles produced *new* rows rather
than re-litigating old ones, and every one of those new rows was the same defect wearing different
clothes: **a change that ships in a state where undoing it costs nothing, because nothing observes
it.** It appeared as un-separable test fixtures (rows 13, 16–18, 21–25), as a warning no caller read
(row 20), and finally as bytes the test runner cannot see (row 26). Each time I fixed the instance;
the reviewer kept refusing to let the class close.

Two things ended it, and both are worth carrying into deliveries 004–005:

1. **Test separability, not the implementation.** Mutating code cannot detect a test whose fixture
   never reaches the mutated line — that is exactly how row 21 passed my own mutation pass. For every
   narrowing property of a predicate, the fixture must be one where *that property alone* is the
   reason the input is rejected.
2. **Where a defect is invisible to the runner, ship a guard rather than a resolution to be careful.**
   `source-encoding.test.mjs` is that, and it justified itself within a minute by catching a BOM my
   own manual audit had missed.

One observation carried forward, not a defect: the BOM guard is scoped to `site/`, which matches where
the harness that caused the problem operates. If a later task runs mutation harnesses over `canonical/`,
`.claude/`, or `bin/`, widen it.

---

## Checkpoint Findings — cycle 4 (rows 16–19)

Recorded against the tasks-019–029 A+ checkpoint. Rows 16–18 are all one shape, which the reviewer
has now raised on three consecutive cycles: **the fix is correct, and undoing it is free.** Row 13
was this finding applied to the R1 guard; rows 16–18 are the same finding applied to the fixes that
closed row 13's siblings.

| # | Sev | Status | What | Resolution |
|---|-----|--------|------|------------|
| 16 | MEDIUM | Fixed | R2 nameless-token guard had no test; its R1 twin had three. The R2 half was the half originally missed. | Added an R2 empty-name fixture (trailing space after the em-dash is load-bearing). Removing the guard now fails 1 test. |
| 17 | MEDIUM | Fixed | The dangling-preposition repair shipped with no test; three mutations survived, two of them removing exactly the `toward`/`once` token pair the `aid-discover` label needed. | Added four tests, fixture shape taken verbatim from `state-q-and-a.md:64`. All three mutations now fail. |
| 18 | LOW | Fixed | Row 14's strip was pinned only for the `both continue inline` form; unanchoring the sentence boundary and making `both` mandatory both survived. | Added two tests — one proving the anchor prevents mid-condition eating, one covering the bare form. |
| 19 | MEDIUM | Fixed | `aid-update-kb`'s `REVIEW → APPROVAL` edge published outcome 3's condition (`grade/teach-back/… PASS) FIX…`) instead of its own (`READY`). | Root cause found one level deeper than reported — see below. Fixed in `_buildClauses`; label is now `"READY"`. |
| 20 | MEDIUM | Fixed | `chart.warnings` reaches no human: `confidence` does not track warnings, and no caller reads them. | Filed open in cycle 4; **closed in cycle 5** once it turned out to be an unchecked task-029 AC, not a scope expansion. See below. |
| 21 | MEDIUM | Fixed | The arrow requirement in `_isUnresolvableOutcome` was unpinned: the test claiming to cover it used a lowercase-ending tail, which the ALL-CAPS clause already rejects, so removing the arrow check changed nothing. | Added the discriminating fixture — no arrow, ALL-CAPS tail (`escalate to FIX`). Mutant now dies. |

### Row 19 root cause — not the clause splitter, the resolve-both-halves guard

The reviewer read this as the splitter failing to learn the `;` boundary. It is narrower than that:
the splitter **does** propose the boundary. `_buildClauses` then rejects it, because a cut is accepted
only when **both** halves resolve to a declared state (`advance.mjs`, the `!r1 || !r2` guard).
Outcome 3 routes to `FIX` — a loop *mode* described in the prose note at `SKILL.md:450`, not a row in
the Dispatch table — so its half does not resolve, the cut is rejected, and outcome 3 is **absorbed
into outcome 4**, overwriting its condition. The 80-code-point cap then cut `FIX` mid-token, which is
the artifact that made it visible.

The guard's default is right for punctuation inside one clause and wrong for exactly one shape: a half
that is itself a complete outcome pointing at an undeclared state. The fix cuts anyway and drops that
half, gated by `_isUnresolvableOutcome` (arrow form followed by an ALL-CAPS token, anchored at end).
Both narrowing properties are pinned by tests — they survived the first mutation pass, which is rows
16–18's finding recurring inside its own fix, caught before shipping this time.

**Nothing that was previously drawn is lost.** `FIX` was never a node, so the dropped outcome had no
edge either way; what changed is that it no longer overwrites its neighbour's label. Blast radius is
one line on one page. Census unchanged: 13 dispatch-table / 8 inline-states / 13 residual = 34
charted, 0 failed; 64 engine-doorway + 13 sibling-doorway. AC-6 idempotence holds. Full suite 1781
passing across 29 files. Five mutants of the fix, all killed.

### Rows 26–27 — the pattern's real root cause, and a structural guard for it

Cycle 7 graded **D+**: every one of the twelve functional mutants died, and the grade still collapsed,
because two new rows landed — one of them [HIGH] and entirely self-inflicted.

| # | Sev | Status | Resolution |
|---|-----|--------|------------|
| 26 | HIGH | Fixed | **I committed two files with a UTF-8 BOM** (`advance.mjs`, `gen-skills.mjs`) in `3600a758`. Stripped, and a repo-hygiene guard added so the class cannot recur silently: `site/scripts/__tests__/source-encoding.test.mjs`. |
| 27 | LOW | Fixed | My justification for deleting the `\b` was **factually wrong**. Corrected, and the property is now pinned rather than assumed unreachable. |

**Row 26 is the more important finding, and it is about how I work rather than what the code does.**
The BOM came from cycle 6's mutate-and-restore: the reviewer's restore wrote UTF-8-with-BOM (PowerShell's
default), and my own `mut22.py` then read those files with `read_text(encoding='utf-8')` — which surfaces
an existing BOM as a literal `\ufeff` rather than stripping it — and wrote it faithfully back. I *did*
strip BOMs that cycle, from the two files that showed up as unexpectedly modified. The two files I was
editing anyway hid their BOM inside my own diff, and I never checked them.

Node strips a leading BOM before parsing, so nothing failed: 1791 tests green, generated output
byte-identical, no functional test could have caught it. That is the actual shape of this delivery's
recurring defect, and it is broader than the "un-undoable fix" framing: **a side effect invisible to the
test runner survives any amount of mutation coverage on functional behaviour.** Rows 13, 16–18 and 21–25
were that principle applied to assertions; row 26 is the same principle applied to bytes.

So the fix is a guard, not a habit. `source-encoding.test.mjs` walks `git ls-files` under `site/` (so a
newly added file is covered on arrival, and ignored build output is not), names every offender rather
than counting them, and carries both a non-vacuity check and a proof that the detection works. It earned
its place within a minute of existing: it caught a **third** BOM in `advance.mjs` that my own audit had
missed, because that audit only scanned `.mjs`/`.ts`/`.js` while the guard covers every tracked text
extension.

**Row 27 — the reviewer was right and my reasoning was wrong.** I removed the `\b` claiming it inert
because "`[^A-Za-z0-9]` cannot match a word character". That is false for `_`: it is a word character to
`\b` but *is* matched by that class, so the two forms disagree on exactly one input — an underscored
target like `-> FIX_THING`. With `\b` the token cannot end before the underscore, no split succeeds, and
the match fails; without it the text is recognised. Recognising it is the better answer, so the deletion
stands — but as a decision with a test (`recognises an UNDERSCORED target`) rather than an assumption of
unreachability. Restoring the `\b` now fails that test. Had I not been corrected, the comment would have
left a maintainer a false invariant.

Thirteen mutants re-run this cycle, including the BOM guard mutated against itself and its own file list
emptied. All died; all files byte-equal after restore, verified through `read_bytes`/`write_bytes` so the
harness cannot itself add or strip a BOM. Suite **1795** green across 30 files, AC-6 idempotence holds,
generated tree byte-identical to `2922af8b`.

### Rows 22–25 — closing the pattern by testing separability, not the implementation

Cycle 6 graded **B+** with zero Pending above [LOW] and four [LOW] survivors. The reviewer's diagnosis
is the part worth keeping: **mutating an implementation cannot detect a test whose fixture never
reaches the mutated line.** My own mutation pass missed row 21 for exactly that reason. The check that
does work is *input separability* — for every narrowing property of a predicate, construct an input
where that property is the **only** reason the predicate rejects it.

| # | Sev | Status | Resolution |
|---|-----|--------|------------|
| 22 | LOW | Fixed | `resetFlowWarnings()` in `main()` is unobservable from a subprocess — a fresh process starts empty either way. Exported `main()` and added a two-run in-process test; deleting the reset now fails it. |
| 23 | LOW | Fixed | `towards` is a separate alternation branch from `toward` and the corpus uses only the short form. Added the `towards` row to the preposition table. |
| 24 | LOW | Fixed by deletion | The `\b` in `_isUnresolvableOutcome` is inert: the class that follows (`[^A-Za-z0-9]`) cannot match a word character, so the boundary is already implied. **Removed rather than pinned** — a test for an assertion that changes no input is a test that cannot fail, which is the defect this cycle keeps finding. Proof of inertness: generated tree and manifest byte-identical to `2922af8b`, suite green. |
| 25 | LOW | Fixed | Relaxing the outer `+` to `*` let a half ending in a bare arrow match, silently discarding `escalate ->` as an outcome. Added a fixture with the arrow present and zero caps tokens, so the quantifier is the only thing that can reject it. |

Six mutants re-run — rows 22, 23, 25 and the three row-19 properties (arrow, end-anchor, ALL-CAPS)
re-confirmed after the `\b` removal. All died. Suite 1791 green; AC-6 idempotence holds.

**The two newly surfaced warnings stay as observations.** The reviewer confirmed both are pre-existing
content defects in the skill *sources* — `aid-housekeep`'s empty `(or )` alternative and three skills
whose `DONE` state has no matching `## State:` section — not defects in the flow machinery. task-029's
AC was to log warnings, not to fix the warned content. Surfacing them is the mechanism working.

### Row 21 — the same pattern, inside row 19's own fix

`_isUnresolvableOutcome` has two narrowing properties. I added tests for both and both mutants died,
so I recorded them as pinned. The reviewer found that only one of them was: the "requires an arrow"
test used `otherwise hand -> back to the author`, whose tail ends **lowercase**, so the ALL-CAPS clause
rejects it whether or not the arrow check is present. The test's comment claimed a property its input
could not exercise.

The discriminating case needs both halves separable — no arrow, ALL-CAPS tail — which is
`escalate to FIX`. Added; the mutant now dies against exactly that test. Worth naming: this is the
fourth consecutive cycle the same finding has landed, and this time it landed on a test I had written
*specifically to close it*. The mutation pass I ran did catch two of three narrowing gaps; what it
missed was that one of my new tests was passing for the wrong reason. Mutating the implementation does
not detect a test whose fixture cannot reach the mutated line.

### Row 20 — closed in cycle 5: it was an unchecked AC, not a scope expansion

Filed open in cycle 4 on the reasoning that run-level reporting needed a seam that did not exist, and
the reviewer agreed with that disposition. That agreement was based on my framing, and my framing was
wrong: **task-029's DETAIL carries `- [ ] chart.warnings are logged with a run-level count and never
thrown` as an unchecked acceptance criterion.** So the work was owed by the task, not deferred by it,
and "needs a seam that does not exist" was a description of the defect rather than a reason to keep it.

The seam is four lines. `buildFlowChart` already sits between the pure `BODY_PROVIDERS[].render()`
function and the extractors, so it is the one place that both sees every chart and can hold state:
it now pushes into a module-level accumulator, and `resetFlowWarnings` / `summarizeFlowWarnings`
expose it. `gen-skills` resets at the start of the run and reports at the end, as a new step 8, to
**stdout** — stderr stays empty on success, which was the constraint that made this look impossible.
task-029's counter was not the wrong mechanism; it was missing its reader.

It pays for itself immediately. The run now prints **9 warnings across 7 charts**, and two of them are
findings nobody had filed: `aid-housekeep`'s residue is `'**CHAIN** → [State: KB-DELTA] (or ). Continue
inline.'` — an empty `(or )` alternative — and three separate skills report `inline detail for state
'DONE' has no matching ## State: section`. Both were true before this cycle and invisible.

`confidence` is deliberately still not warning-sensitive. Making it so would change which pages carry
the on-page approximation notice, which is a rendering decision, and `index.mjs` now says that in
those terms instead of implying the notice already covers warnings.

The stdout-discipline test previously pinned the output at exactly four lines. It now asserts the four
phase lines in order and constrains everything after them to report lines, rather than pinning a total
that a corpus change would break for unrelated reasons.

Row 19's fix routes the dropped span to the W-1 residue warning, and while writing that justification
I checked whether W-1 actually surfaces. It does not. `index.mjs` claimed warnings are surfaced via
`chart.confidence === 'approximate'`, which drives the body provider's interpretation notice — but
`extract-dispatch` stamps `'derived'` unconditionally and `extract-residual` stamps `'approximate'`
unconditionally, so the notice reflects **which extractor built the chart**, never whether that chart
lost anything. Measured: **7 of 34 charts carry warnings** (`aid-design`, `aid-detail`, `aid-execute`,
`aid-housekeep`, `aid-monitor`, `aid-plan`, `aid-update-kb`); exactly one page shows a notice, and only
because it is residual. `gen-skills` prints zero warning lines.

I corrected the overstated docstring and the row-19 comment rather than leaving either claiming more
than is true. I did **not** build run-level reporting: the chart is constructed inside
`BODY_PROVIDERS[].render()`, a pure string-returning function with nowhere to accumulate, so closing
this needs a new seam — the same wall that caused task-029's module-level counter to be removed. That
is a design change, not a patch, so it is filed rather than improvised at a gate.

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The Tasks State section below is assembled at READ TIME from per-task STATE.md files
     (tasks/task-NNN/STATE.md within this delivery folder). NEVER written directly.
     ============================================================ -->

## Tasks State

<!-- DERIVED -- read-only rollup assembled from tasks/task-NNN/STATE.md mutable cells.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |
