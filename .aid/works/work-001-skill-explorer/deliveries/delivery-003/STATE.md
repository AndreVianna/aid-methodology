---
delivery_state: Executing
gate_tier: Small | Medium | Large
gate_grade: "{grade or Pending}"
gate_timestamp: "{YYYY-MM-DDTHH:MM:SSZ}"
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

- **Updated:** 2026-07-27T14:46:50Z
- **Block Reason:** --
- **Block Artifact:** --

---

## Delivery Gate

<!-- AUTHORED -- single writer: the delivery-gate closing step of `aid-execute` on this
     delivery's branch. Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block
     at the top of this file (`gate_tier`, `gate_grade`, `gate_timestamp`). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

---

## Cross-phase Q&A

<!-- AUTHORED -- single writer: this delivery's branch (via the delivery-gate step of aid-execute).
     The work-level ## Cross-phase Q&A is a DERIVED union of all delivery Q&A sections plus any
     work-owner-authored work-level entries. -->

### Q{N}

- **Category:** {category, e.g., Architecture, Requirements, Security}
- **Impact:** High | Medium | Low | Required
- **State:** Pending | Answered | Skipped
- **Context:** {why this matters; what the downstream phase observed}
- **Suggested:** {answer if inferrable, or --}
- **Answer:** {filled when State is Answered}
- **Applied to:** {artifact(s) the answer was applied to}

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
