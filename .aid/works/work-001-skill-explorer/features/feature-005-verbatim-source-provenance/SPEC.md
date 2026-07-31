# Verbatim Source Provenance

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-25 | Feature identified from REQUIREMENTS.md §5 (FR-3 layer 1), §6 (NFR-2, NFR-3), §9 (AC-5, AC-7) | /aid-define |
| 2026-07-25 | Technical specification added | /aid-specify |
| 2026-07-25 | Review fix round 1 — feature-003 cross-reference citations corrected after its amendments | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-3 (**the verbatim fragment + deep link**; the in-node derived label
  belongs to feature-003 and the click panel to feature-006), §6 NFR-2, NFR-3, §9 AC-5, AC-7

> **Scope is settled: every node in every chart** — authored-flow **and** doorway. FR-6 was
> **owner-confirmed** at cross-reference (Q2, 2026-07-25), so doorway pages do carry a full
> inline engine chart and its nodes fall inside AC-5's reach. No re-scoping is pending.
> *(Had FR-6 instead been reversed to a stub page, this SPEC would have needed re-scoping to
> authored-flow charts only.)*

## Description

The chart carries shape; this feature carries **exactness**. Every node in every chart —
authored-flow or doorway — exposes the verbatim prompt fragment that composes that step and a
deep link to the exact lines in `canonical/`, rendered as an ordered list beneath the chart, in
chart order.

This is what keeps a derived label from being the last word: a reader who suspects the
interpretation can read the source text, and then the source file. Because a derived label is an
interpretation and can be wrong in a way verbatim text cannot, the deep link is the accepted
corrective and must resolve to **real lines**, not an approximate anchor.

Beyond rendering, this feature owns deep-link construction and line-range verification.

## User Stories

- As an **AID maintainer**, I want to read the exact prompt text behind a step I distrust, and
  then jump to the line in `canonical/` that produced it, so the chart never becomes the
  authority.
- As a **contributor**, I want to follow a chart top-to-bottom in prose form when the diagram is
  too dense to read.
- As an **AID maintainer**, I want a bad line-range to be caught by the build rather than
  discovered by a reader clicking into the wrong file.

## Priority

Must

## Acceptance Criteria

- [ ] **AC-5 — Verbatim reachability.** Given any node in any chart, when its page renders, then
      the node's verbatim prompt fragment is exposed and its source deep link resolves to real
      lines in `canonical/`.
- [ ] **AC-7 — Comprehension spot-check (NON-BLOCKING).** Given a reader unfamiliar with a
      skill, when they read its chart alone, then they can state its step order and exit points
      correctly. A judgement check, not a CI gate. Formalizing it into a repeatable review step
      remains a §10 Could and is explicitly deferred.
- [ ] Given a fragment whose recorded line range does not exist in the cited `canonical/` file,
      when the generator runs, then the build surfaces it rather than emitting a broken link.

---

## Technical Specification

> Grounded in: **feature-003's SPEC** (the `Provenance` interface and the `FlowChart` model —
> binding, graded A+, not re-litigated here), **feature-001's SPEC** (the `BODY_APPENDERS` seam,
> the `.md` output contract, `skills/paths.mjs`), REQUIREMENTS.md §5 FR-3 / FR-6, §6 NFR-2 /
> NFR-3 / NFR-4, §7, §9 AC-5 / AC-7, §10; `.aid/knowledge/` — `architecture.md`,
> `authoring-conventions.md`, `coding-standards.md`, `test-landscape.md`; and direct reading of
> `site/scripts/gen-reference.mjs`, `site/astro.config.mjs`, `site/package.json`,
> `.gitattributes`, `.github/workflows/docs.yml`, plus the locked installs of
> `@astrojs/starlight` 0.39.3, `@expressive-code/*` 0.42.0 and `astro-mermaid` 2.0.2
> (`site/package.json` 22–36; the packages are read from the main checkout's
> `site/node_modules/`, absent in this worktree — feature-001 § Build-integration scope, Part C).
>
> **Cross-reference convention (adopted at review fix round 1).** Citations into the **sibling
> SPECs** name a **stable anchor** — a section heading, a rule or hook name (`V7`, `rule 5`, `H4`,
> `D1–D5`, `R5`), or a schema field — never a line number. Those documents are live and were
> amended twice on 2026-07-25 after this SPEC first cited them, which silently invalidated pins
> that were correct when written; a heading or a rule name survives an amendment that inserts
> lines above it. This is the same reasoning `authoring-conventions.md` § Citation Rule (Durable
> Anchors) applies to KB prose, applied here by choice rather than by lint. Citations into
> **code, config and vendored packages** keep line numbers: those files have no headings to
> anchor to, they are not being amended alongside this work, and every one of them was verified
> against the file at review.

This feature adds **one `BODY_APPENDERS` entry** (feature-001 § Body slot) and the library
behind it. It owns three things and nothing else: the **below-chart ordered fragment list**, the
**`canonical/` deep link**, and **line-range verification**. It derives no chart, classifies no
skill, and renders no diagram.

Its reach is **every node of every chart** — authored-flow, residual, and doorway — because FR-6
was owner-confirmed (REQUIREMENTS.md 184–192) and feature-003's residual extractor guarantees no
skill is chart-less (feature-003 § Extractor 3 — the residual heuristic, whose R5 rung is the
last-resort three-node spine). The appender is shape-blind: it consumes
`FlowChart.nodes`, so feature-004's doorway charts are covered without this SPEC depending on
feature-004's document.

### Data Model

#### Consumed contracts (unchanged by this feature)

| Contract | Owner | Where |
|---|---|---|
| `Provenance` = `{file, startLine, endLine, sourceKind, excerpt}`, repo-root-relative under `canonical/`, POSIX separators, 1-based inclusive | feature-003 | § `Provenance` — the feature-005 interface |
| `detail` — same shape, **no `excerpt`**, pointing at the fuller worker/section range | feature-003 | § `FlowNode` (the `detail` row) + § `Provenance` ("`excerpt` is omitted on `detail`") |
| `FlowChart.nodes` ordered by `order`, ascending, no gaps; `id`, `name`, `label` (≤ 60 code points), `kind`, `terminal` | feature-003 | § `FlowChart` (the `nodes` row) + § `FlowNode` |
| AC-5's cheap equality `excerpt === slice(file, start, end)` | feature-003 | § `Provenance` |
| `BODY_APPENDERS` — all appenders run, in array order, each appended below the provider's output | feature-001 | § Body slot |
| Pages are `.md`, never `.mdx` | feature-001 | § Output contract |
| `GITHUB_BLOB_BASE` in `site/scripts/skills/paths.mjs`, redeclaring `gen-reference.mjs`'s `BLOB` | feature-001 | § Module layout (the `paths.mjs` row) + § Output contract (final bullet) |

Two things this feature adds to those seams, both additive: **one array entry** in
`site/scripts/skills/body.mjs`, and **three guard names** in feature-001's stable-guard-name
vocabulary (§ Telemetry & Tracking below; feature-001 § Telemetry & Tracking, the Failures row).

#### What this feature stores

**No schema changes, no new persisted artifact, no manifest entry.** The page this appender
writes into is already recorded in feature-001's `.skills-manifest.json`
(feature-001 § Manifest contract), and the machine artifact for the same data is feature-003's
`<skill>.flow.json` sidecar (feature-003 § Serialization). This feature emits **page bytes only**.

One in-memory shape, built per node and never serialized:

```js
/**
 * @typedef {object} FragmentEntry
 * @property {number} order          1-based chart position — FlowNode.order
 * @property {string} nodeId         FlowNode.id — also the page anchor suffix
 * @property {string} name           FlowNode.name (verbatim state name)
 * @property {string} label          FlowNode.label (derived, <= 60 code points)
 * @property {string} kind           FlowNode.kind — closed enum
 * @property {string|null} advanceType  node.terminal?.advanceType — closed enum, exits only
 * @property {string} fragment       provenance.excerpt, byte-for-byte
 * @property {SourceRef} source      { file, startLine, endLine, anchor, url }
 * @property {SourceRef|null} detail same, from node.detail — link only, never inlined
 */
```

`anchor` is `#L<start>` when `startLine === endLine`, otherwise `#L<start>-L<end>`. `url` is
`GITHUB_BLOB_BASE + '/' + file + anchor`. Nothing else is derived: the entry is a projection of
the node, so the list and the chart cannot disagree about what a node is — feature-003 states
that obligation as hook **H4 — the node record** (§ UI Specs → Hooks this gives feature-006):
"Feature-005 renders its ordered list from the same array in `order` sequence, so the two
features cannot disagree about what a node is."

**Where the chart comes from.** The appender calls feature-003's façade
`buildFlowChart({ name, dir })` (feature-003 § Layers & Components, the Public API block),
memoized by directory name for the run, and receives the same `FlowChart` object the chart
provider rendered. Feature-003's **Ownership boundaries** table (same section) phrases this as
"reading the sidecar" in its feature-005 row; the substance of that constraint is
(a) feature-005 never re-derives the model and (b) list and chart cannot diverge — both hold
*more* strongly in-process than across a JSON round-trip, which would additionally impose a
write-then-read ordering between two `body.mjs` registry entries that feature-001's registry
contract does not define (it defines execution order only — feature-001 § Body slot).
Determinism (feature-003 § Determinism (NFR-4 / AC-6)) makes the two mechanisms
interchangeable in output; the memo is an
optimization, not a correctness dependency. The sidecar remains exactly what feature-003 says it
is: the artifact **feature-006** reads in the browser.

Verification does read raw bytes of the cited `canonical/` file. That is not "re-parsing
`canonical/`" in feature-003's sense — no markdown structure is derived from it, only a line
slice compared for equality — and it is the only way this feature's third acceptance criterion
can be met at all.

### Feature Flow

Build-time only. No request path, no runtime component, no client JavaScript.

```
gen:skills (feature-001)  →  renderSkillBody(skill)      [feature-001 § Body slot]
        │
        ├─ BODY_PROVIDERS  first match wins  → the mermaid fence      (003 / 004)
        │
        └─ BODY_APPENDERS  all run, in order → THIS FEATURE
                 │
                 1. chart = buildFlowChart({ name, dir })      memoized per skill
                 2. verifyProvenance(chart)                    ← throws; nothing emitted on failure
                 │      per node: path → range → excerpt equality → non-blank
                 │      per node.detail: path → range          (no excerpt to compare)
                 3. entries = buildEntries(chart)              projection, chart order
                 4. renderFragmentList(entries)                → markdown, LF-terminated
                 ▼
        page body: [chart fence] + [this list]  →  writeFileSync (feature-001 step 5)
                 ▼
        astro build → remark → Expressive Code → <figure class="frame"><pre>…</pre>
```

Verification runs **before** any markdown is produced for that skill, so a bad range can never
be written into a page. A failure is an uncaught `throw`: the process exits non-zero,
feature-001's drift guard (step 7) never runs, `prebuild` fails, and `npm run build` fails —
the same blast radius feature-001 specifies for its own guards (§ Feature Flow, closing
paragraph, and § Telemetry & Tracking, the Blast-radius row). Pages
written before the throw may be left on disk; nothing is published, and the next successful run
rewrites them deterministically.

Step 8 of feature-003's flow (browser-side mermaid rendering) is **not** in this path. Nothing
in this feature waits on it — that is what makes the list survive KI-004.

### Layers & Components

A library plus one registry entry, mirroring feature-003's `site/scripts/lib/flow-graph/` layout.

```
site/scripts/lib/provenance/
  deep-link.mjs    — blobUrl(), lineAnchor(), the path-charset guard
  verify.mjs       — verifyProvenance(); the per-run source-file cache
  render-list.mjs  — buildEntries(), renderFragmentList(), the fence sizer, the lead-in escaper
  index.mjs        — provenanceAppender  (the BODY_APPENDERS entry)
site/scripts/skills/body.mjs             — ONE added array entry (feature-001's seam)
site/scripts/__tests__/provenance.test.mjs — vitest suite (AC-5)
```

Public API — signatures only:

```js
lineAnchor(startLine, endLine)                 -> '#L275' | '#L275-L277'
blobUrl(file, startLine, endLine)              -> string          // GITHUB_BLOB_BASE + '/' + file + anchor
verifyProvenance(chart)                        -> void            // throws on the first violation
buildEntries(chart)                            -> FragmentEntry[] // chart order, 1:1 with nodes
renderFragmentList(entries)                    -> string          // markdown, LF-terminated
provenanceAppender = { id: 'source-fragments', render(skill) -> string }
```

`render(skill)` takes feature-001's `SkillRecord` (§ The `SkillRecord`) and uses exactly two of
its fields: `dirName` (→ `buildFlowChart({ name: dirName, … })`) and `sourcePath`. It does **not**
use `bodyStartLine` / `lineCount`, which feature-001 added anticipating this feature (the
bullet under that same typedef naming feature-005 as their consumer): a node's provenance may
cite a `references/state-*.md` worker or
`canonical/aid/templates/shortcut-engine.md`, not only that skill's `SKILL.md`, so range
verification must read whichever file is cited rather than trust a per-skill line count. Those
two fields stay available and correct; this feature simply does not need them.

**Ownership.** Everything above is feature-005's. `body.mjs` stays feature-001's file; this
feature appends one entry to one array literal and edits nothing else in it. `paths.mjs` is
consumed read-only. No file owned by feature-002, 003, 004 or 006 is touched.

**Conventions followed** (`coding-standards.md` § JavaScript / Node Conventions 179–190, with
the same directory-local divergence feature-001 records in § Module layout ("Two deliberate
divergences") and feature-003 in § Layers & Components ("Conventions followed")): ESM `.mjs`,
`node:`-scheme builtins only, **2-space indentation** to match everything
already in `site/scripts/`, kebab-case filenames, no new dependency (`site/package.json` 22–36
is unmodified), pure exported functions with no import-time side effect. Every emitted path is a
**POSIX string built by concatenation, never `path.join`** — the Windows-backslash hazard
feature-001 calls load-bearing for AC-6 (§ Manifest contract). Output is LF-only; no `os.EOL`.

**Ordering and determinism (NFR-4 / AC-6).** `buildEntries` iterates `chart.nodes` in **array
order and does not re-sort**: feature-003 guarantees ascending `order` with no gaps
(§ `FlowChart`, the `nodes` row), and a second sort would create a second ordering authority that
could silently disagree with the chart. Entry count equals node count — no de-duplication even
when two nodes cite the same range (residual R5 spines can; feature-003 § Extractor 3, rung R5),
because the 1:1 node↔entry mapping is what AC-5 is checked against. Self-edges
(feature-003 § The Advance-clause parser, **rule 5**) add no entry: the list is
node-indexed, so a loop cannot duplicate or reorder anything. No clock, no environment, no
randomness, no object-key iteration.

#### Test layer

`site/scripts/__tests__/provenance.test.mjs` — a new file, run by the site's existing
`npm test` → `vitest run` (`site/package.json` 20), kept separate from
`gen-skills.test.mjs` and `flow-graph.test.mjs` for the same reason feature-001 keeps its suite
separate from `gen-reference.test.mjs` (§ Test layer, closing paragraph). It becomes enforceable
on pull requests only once feature-001's CI step lands (feature-001 § Build-integration scope,
Part B; KI-006).

| Group | Covers |
|---|---|
| **AC-5 — whole corpus** | For every directory under `canonical/skills/` (enumerated from disk; **no literal count**, §8), build the chart and assert for **every** node: `provenance.file` exists and is under `canonical/`; `1 <= startLine <= endLine <= lineCount(file)`; and feature-003's equality `excerpt === readFileSync(file,'utf8').split('\n').slice(startLine-1, endLine).join('\n')` (feature-003 § `Provenance`). `detail`, when present, passes the path and range checks (it carries no excerpt to compare). |
| **AC-5 — the link half** | For every node, the emitted entry contains exactly one `[Source: …]` link whose href is `GITHUB_BLOB_BASE + '/' + provenance.file + anchor`, and whose anchor is `#L<n>` for a single-line range and `#L<a>-L<b>` otherwise. The URL is **not fetched** — no test makes a network call — so "resolves to real lines" is proven as: the range exists on disk (row above) **and** the URL is that range's mechanical encoding. That is the honest reading of AC-5 and the only one that is offline-deterministic. |
| **Containment — inline fixtures** | Fixtures written in the test file (feature-003 § Test layer, tier 1 — "They depend on nothing outside the test"): a fragment carrying a 4-backtick run, a pipe, `<div>`, `{braces}`, and a complete ```` ``` ```` fenced block round-trips — extract the emitted fence body and assert `=== fragment`. A fragment containing a `~~~~` line at column 0 forces a 5-tilde fence. Every emitted fence line carries a `title="` meta option — the guard that disarms Expressive Code's line-deleting file-name extraction (§ UI Specs, Layer 2); asserting the meta option is the testable half, since asserting the plugin's own behaviour would mean rendering the page. |
| **Verifier** | Synthetic charts: `endLine` beyond EOF; an `excerpt` differing by one character; a `file` outside `canonical/`; a range whose slice is entirely whitespace. Each throws, and the message contains the stable guard name, the skill, the node id, and `file#L…`. |
| **Determinism (AC-6)** | `renderFragmentList` on the same chart twice returns identical strings; two `gen:skills` runs leave the fragment section byte-identical (feature-001 asserts the whole page by byte comparison — § Test layer, the Idempotence (AC-6) row — while this suite asserts the section in isolation so a failure localises). |
| **No-JS invariant** | The rendered markdown contains no `<script`, no `client:` directive and no `import`; the `[Source: …]` link count equals `chart.nodes.length`. |

#### AC-7 — how a non-blocking judgement check is recorded

AC-7 is **not automated and must not become a gate**. It is wired into nothing: no vitest case,
no `prebuild` step, no `docs.yml` step. REQUIREMENTS.md 337–340 marks it non-blocking, and §10
(374) lists "formalizing AC-7 into a repeatable review step" as a **Could**, explicitly deferred.

| Question | Answer |
|---|---|
| What is checked | A reader unfamiliar with the skill states its step order and its exit points from the page alone. |
| Sample | Two pages, chosen by shape, not by count: one authored-flow (feature-003's fixtures make `aid-describe` the natural pick) and one doorway. Two shapes is what makes the check informative; more is optional. |
| Who | A human who has not read that skill's `SKILL.md` — the owner, or a reviewer at the delivery gate. Which human is OQ-2. |
| When | Once, at the delivery gate, after the pages exist. Not per commit. |
| Recorded as | A dated note in the **work's** delivery record (`.aid/works/work-001-skill-explorer/`), with a Pass / Pass-with-observations / Fail verdict and, on anything but Pass, a filed ticket. |
| Effect of a Fail | None on the gate. It files a ticket or a §10 Could item. A Fail is evidence about chart legibility (feature-003's NFR-1 surface), not about this feature's correctness. |
| Why it lives in the work folder | It is a one-time judgement about a delivery, not durable knowledge. Nothing under `site/` or in the KB reads it, so the transient-work-folder rule is respected. |

### External Integrations

*Activated: the deep link is a contract with an external system (GitHub's blob line-anchor
syntax) whose ref pinning is a decision with a correctness consequence. `integration-map.md`
catalogues GitHub as an integration; the site's only existing use of it is the `BLOB` link
construction this feature extends.*

#### The deep-link contract

| Element | Value | Source |
|---|---|---|
| Base | `GITHUB_BLOB_BASE` from `site/scripts/skills/paths.mjs` = `https://github.com/AndreVianna/aid-methodology/blob/master` | feature-001 § Module layout (the `paths.mjs` row) and § Output contract (the `[Definition: …]` bullet, which names feature-005 as the consumer); the literal is `gen-reference.mjs` 83 |
| Path | `provenance.file`, already repo-root-relative POSIX under `canonical/` | feature-003 § `Provenance`, the `file` field |
| Anchor | `#L<start>` when the range is one line, else `#L<start>-L<end>` | GitHub blob line-anchor syntax |
| Composition | `base + '/' + file + anchor` — string concatenation, the same shape as `` `[Definition: \`${src}\`](${BLOB}/${src})` `` | `gen-reference.mjs` 426, 494 |
| Ref pinned | **`master`** | see below |

**No second scheme is invented.** The `#L…` suffix is the only addition to the construction
already used by the four generated reference pages; there are no other `blob/…#L` links anywhere
in `site/`, `docs/` or `canonical/` today (measured 2026-07-25), so this establishes the form
rather than competing with one.

**Path safety.** `blobUrl` throws if `file` contains any character outside `[A-Za-z0-9._/-]`, or
a `..` segment, or a leading `/`. Every directory under `canonical/skills/` matches
`^[a-z0-9]+(-[a-z0-9]+)*$` (feature-001 § Route and path derivation) and the cited files are `SKILL.md`,
`references/state-*.md` and `canonical/aid/templates/*.md`, so no percent-encoding is needed
today; the guard makes the day that changes a loud build failure rather than a silently broken
URL. Rejected: `encodeURI` — it would paper over a path this generator should never produce.

**Why `master`, and why the links stay correct as `canonical/` changes.**

1. The site is built and deployed **only from `master`**. `docs.yml` triggers are `push` to
   `master`, `pull_request` to `master`, and `workflow_dispatch` (`docs.yml` 10–25); its header
   states the `github-pages` environment rejects a tag/release ref (5–8). So the tree that
   generates the pages and the tree `blob/master` resolves to are the same commit.
2. `npm run build` runs `prebuild` → `gen:skills` (feature-001 § npm wiring), so the deployed
   pages are **regenerated from the checkout being deployed** — a stale committed page cannot
   reach production with stale anchors.
3. Anchors are a pure function of the same input as the page. Any `canonical/` edit that would
   invalidate an anchor necessarily shifts a recorded line, which necessarily changes the
   generated page under `site/**`, which matches `docs.yml`'s path filter and triggers a rebuild.
4. Whenever a build does run, a range that no longer matches its file **throws** (below), so a
   wrong link cannot be published by a green build.

Rejected in one line each: pinning a commit SHA (a permalink, but the SHA is an environment
input — it would change the bytes of every committed page on every commit and break AC-6);
pinning a release tag (the site never builds from a tag, per point 1); emitting a local
filesystem path instead of a URL (unusable from a published page — the reader may not have the
repo).

**Residual risk, stated not assumed.** A commit that edits `canonical/` **without** regenerating
the pages touches no path in `docs.yml`'s filter, so no docs build runs and the deployed page
keeps anchors from the previous generation until the next `site/**` push. The window is bounded
by the next site-touching commit, and any build run in it fails loudly. Closing it entirely
means adding `canonical/**` to that path filter — a `docs.yml` change, and `docs.yml` is
feature-001's file (§ Migration Plan → "What is touched, exhaustively", item 4). Raised as OQ-3.

**Relationship to the KB's citation rule.** `authoring-conventions.md` § Citation Rule (Durable
Anchors) (155–169) bans `file:LINE` citations in favour of grep-recoverable anchors, and
`kb-citation-lint.sh` enforces it — with root `.aid/knowledge` (line 21). That rule governs
**hand-maintained KB prose**, where a line number drifts silently on the next edit above it.
Here the citation is regenerated from the file on every build and mechanically verified against
it, so the exact drift the rule guards against is a build failure rather than a convention. The
rule is respected in scope, not violated; no KB document gains a positional citation from this
feature.

### UI Specs

*Activated: what a reader sees, and the no-JavaScript guarantee, are the substance of AC-5 —
and the list's shape is a contract feature-006 must not break.*

#### Section shape

The appender emits, after the chart the provider produced (feature-001 § Body slot — appenders
"All run, in array order, each appended below the provider's output"):

- one `## Source fragments` H2 — an H2 so Starlight's table of contents anchors it
  (`tableOfContents: { minHeadingLevel: 2, maxHeadingLevel: 3 }`, `astro.config.mjs` 74), as a
  sibling of the chart's H2 (feature-003 § Chart presentation, final bullet);
- one fixed intro sentence, with no count in it (§8): *"Every node in the chart above, in chart
  order, with the exact `canonical/` text it was derived from."*;
- one **entry per node**, in `chart.nodes` array order.

The intro's "the chart above" is safe unconditionally: classification is total (feature-003
§ Contract 3 — the shape classifier, discriminators **D1–D5**, whose D5 is "None of the above")
and every shape has a provider — `dispatch-table`, `inline-states` and
`residual` from feature-003, the two doorway shapes from feature-004 — so no page can carry the
list without a chart. Were a future shape to arrive without a provider, the *chart* would be the
thing missing (an AC-3 / FR-2 failure owned by 003/004); this list would still render and still
satisfy AC-5.

#### Entry anatomy

Each entry is three blocks at **column 0**: a lead-in paragraph, a fenced verbatim block, and a
link line.

```markdown
<a id="fragment-n3"></a>**3 · `CONTINUE`** — Resume the conversational interview · _decision_

~~~~plaintext title="canonical/skills/aid-describe/SKILL.md#L275" wrap
| CONTINUE | `references/state-continue.md` | `aid-interviewer` | → DESCRIBE-SEED (greenfield: no brownfield KB on disk and seed not yet complete) / → COMPLETION (brownfield or seed already complete) |
~~~~

[Source: `canonical/skills/aid-describe/SKILL.md#L275`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/SKILL.md#L275) · [full step: `canonical/skills/aid-describe/references/state-continue.md#L1-L43`](https://github.com/AndreVianna/aid-methodology/blob/master/canonical/skills/aid-describe/references/state-continue.md#L1-L43)
```

*(Real values, measured 2026-07-25: the fragment is line 275 of
`canonical/skills/aid-describe/SKILL.md`, and `state-continue.md` — the `Detail` cell of that
row, hence the `detail` pointer — is 43 lines long. Only the derived label is illustrative, since
feature-003 owns its derivation.)*

| Element | Content | Containment |
|---|---|---|
| Anchor | `<a id="fragment-<nodeId>"></a>` | Inline HTML **on the same line as the lead-in text**, so CommonMark parses it as inline HTML inside a paragraph rather than as an HTML block (which requires the tag to stand alone on its line). Uses feature-003's DOM-safe id contract (§ `FlowNode`, the `id` row). Rejected: an H4 heading — its auto-slug derives from the derived label, so it changes when the label does and collides when two nodes share one. |
| Position | `**<order> · …**` | Integer from the model. |
| `name` | `` `CONTINUE` `` | Code span. If a name ever contains a backtick, it falls back to escaped plain text. |
| `label` | derived text, ≤ 60 code points | Escaped: `&` → `&amp;`, `<` → `&lt;`, then a backslash before each of `` ` ``, `*`, `_`, `[`, `]`, `\` and the pipe character. Escaping is legitimate here precisely because the label is an interpretation, not evidence (NFR-3). |
| `kind` | `_decision_` | Closed enum (feature-003 § `FlowNode`, the `kind` row) — no escaping possible or needed. |
| exit marker | `· PAUSE-FOR-USER-DECISION` when `terminal` is set | The value read is `FlowNode.terminal.advanceType` (feature-003 § `FlowNode`, the `terminal` row); its five-value closed vocabulary is fixed by the `advanceType` row of § `FlowEdge` and § State Machines → Source vocabulary. `terminal.handoff` is **not** rendered inline — it is free text, and it already sits inside the fragment. |
| fragment | `provenance.excerpt`, byte-for-byte | The fenced block — see below. |
| links | `[Source: …]`, plus `[full step: …]` when `detail !== null` | `detail` is **link only, never inlined**: its range can be a whole worker file, and feature-003 omits its excerpt for exactly that reason (§ `Provenance`: "`excerpt` is omitted on `detail` (ranges there can be whole worker files)"). This is the page-weight control. |

Deliberately **not** rendered: outgoing edges, their `condition` prose, and `terminal.handoff`.
All three are free text that would need inline escaping in a list whose whole point is exactness,
and the chart already carries them. The list answers *what each step's source says*; the chart
answers *what follows what*.

#### The verbatim-versus-safe-rendering resolution

Skill bodies contain backticks (longest run measured: 4), pipes, angle brackets, braces and
complete fenced code blocks. Three layers can alter such text on its way to the page; each is
closed explicitly.

**Layer 1 — markdown. Solved by a tilde fence, with zero escaping.** The fragment is emitted
inside a fence opened with `N` tildes, where `N = max(4, 1 + longest run of '~' at the start of
any fragment line)`. Inside a fenced block no character is markdown: backticks, pipes, `<`,
`{`, `#` and an embedded ```` ``` ```` fence are all literal, so **not one byte of the fragment
is escaped, substituted or re-indented**. Tildes rather than backticks because a backtick fence
must out-run the fragment's own backticks (already 4 in this corpus), and because a tilde fence
may carry an info string containing backticks. Measured 2026-07-25: `canonical/skills/**/*.md`
contains **no `~~~` line at all**, so the sizer's floor of 4 is already unambiguous, and the
computed rule keeps it true if that changes.

**Column 0, not a markdown `<ol>`.** Entries are numbered paragraphs, not list items, so every
fence starts at column 0. Rejected: a real ordered list — its fences must be indented to the
marker width, CommonMark strips that indentation *by column*, and a fragment line beginning with
a tab would therefore render de-tabbed (a silent alteration of the one thing this feature
exists to guarantee); the indent would also vary with the item number. Measured 2026-07-25:
`canonical/skills/**/*.md` has **0 lines beginning with a tab**, so the hazard is latent rather
than live — but a feature whose job is to be unfalsifiable should not depend on that staying
true. "Ordered list" is honoured as *a numbered sequence of entries in chart order*, which is
what FR-3, NFR-2 and the user story ask for.

**Layer 2 — Expressive Code's file-name extraction. Solved by always setting `title=`.**
Starlight injects `astro-expressive-code` automatically unless the site already added it
(`@astrojs/starlight/index.ts` 96–100); `astro.config.mjs` does not, so **every** fenced block on
these pages goes through it. Its frames plugin scans the **first four lines** of a block for a
file-name comment and, on a match, **deletes that line** (`@expressive-code/plugin-frames/dist/index.js`
407–446 for the regex, 483–506 for the deletion). That regex fires on lines starting with `#` —
i.e. on markdown headings, which is exactly what an inline-`## State:` fragment starts with.
Measured 2026-07-25 against the plugin's own regex and guard chain: **4 lines under
`canonical/skills/` would be deleted** if they landed in the first four lines of a block — among
them `canonical/skills/aid-discover/references/state-closure.md:54`
(`## Transient work-list: spine-todo.md`) and `canonical/skills/aid-discover/README.md:56`
(`# .NET`). The same scan over every fenced block already in `site/src/content/docs/**` finds
**0 affected blocks**, so this is not a defect in the site today: it is a platform behaviour this
feature would be the first to meet, because it is the first to put arbitrary prompt text inside a
code fence. That is precisely why the suppression is unconditional rather than applied to the
four known lines.

Extraction is skipped when `props.title !== undefined` (same file, line 551), so **every emitted
fence carries `title="<file><anchor>"`** — which doubles as the visible provenance caption on the
code frame. Rejected: `frame="none"`, which also suppresses extraction but throws the caption
away.

**Layer 3 — Expressive Code's whitespace normalization. Declared, not fought.**
`@expressive-code/core/dist/index.js` 1197–1201 `trimEnd()`s every line and drops leading and
trailing blank lines. These touch only whitespace at line ends and blank edge lines, never a
non-whitespace character. Measured 2026-07-25: **no line anywhere under
`canonical/skills/**/*.md` carries trailing whitespace**, so the transform is a no-op on today's
corpus. AC-5's
equality is therefore checked against the model's `excerpt` and the file on disk — never against
rendered HTML — and the deep link remains the final authority (NFR-3). Rejected: emitting a raw
`<pre>` with HTML-entity escaping, which would preserve whitespace exactly but stop the fragment
from being byte-verbatim *in the generated markdown*, and forfeit the site's code-block styling
and its copy button.

**Language, meta and wrapping.** The fence declares `plaintext` — one of Shiki's four hard-coded
plain languages (`@shikijs/primitive/dist/index.mjs` 28–46: `isSpecialLang` ⊇ `isPlainLang` ⊇
`plaintext`), so no grammar is loaded and the "language could not be found" warning the shiki
plugin logs for unknown languages never fires (`@expressive-code/plugin-shiki/dist/index.js`
183, 377–393). The meta string is `title="<file><anchor>" wrap`: Expressive Code parses a
double-quoted value as a string option (delimiters `' " / {…}`, `@expressive-code/core/dist/index.js`
345–400), so the `#` and `/` in the path are ordinary characters, and a **bare** token with no
`=` parses as a boolean `true` (same file 401–428), so `wrap` alone is the flag —
`props.wrap = metaOptions.getBoolean('wrap')` (1204). Wrapping makes a long dispatch row
readable without horizontal scrolling and is presentation-only: it changes no character.
Rejected: `markdown` highlighting — prettier, but it would let a syntax grammar visually
reinterpret the very text whose literalness is the point.

**What a reader sees:** a numbered heading line naming the step, a framed code box captioned
with `canonical/…/SKILL.md#L275` and carrying the source text exactly as written — pipes,
backticks and braces intact, copy button included (`plugin-frames` 568–588) — and beneath it a
link that opens those lines on GitHub.

#### Coexistence with feature-006, and the no-JavaScript guarantee

The list is **static markdown produced at build time**. It contains no `<script>`, no Astro
client directive, no import, and no dependency on the rendered SVG. With JavaScript disabled the
chart degrades to raw `flowchart TB …` text inside `pre.mermaid` (KI-004; feature-003
§ Contract 2 — the rendering substrate, the "Cost accepted" paragraph, which names this list as
the reason AC-5 is unaffected) — and every node's position, name, label, verbatim fragment and
deep link are still on
the page as ordinary HTML. That is why REQUIREMENTS.md §10 (372–373) can call the click panel a
*Should*: "a chart plus a below-chart ordered list of verbatim fragments already satisfies AC-5".

Constraints this places on feature-006, stated here because this feature is the one that pays if
they are broken:

- The section is emitted **unconditionally**, for every skill, and is never gated on a script
  having run. Feature-006 must not make its presence conditional.
- Any collapsing or de-duplication feature-006 wants must be applied **at runtime by its own
  script** and be user-reversible, so a no-JS reader keeps the expanded list. Rejected here:
  wrapping entries in `<details>` at build time — it would work without JavaScript, but it hides
  by default the very evidence NFR-2 requires to be present.
- Feature-006 must **not read the list's DOM as a data source**; its node record is the sidecar
  (feature-003 § UI Specs → hook **H4 — the node record**). That keeps this markup free to change.
- Provided hook: the per-entry anchor `#fragment-<nodeId>`, keyed on the same `FlowNode.id`
  feature-006 already resolves a clicked node by. It may link or scroll to an entry; it need not.

**Accepted cost.** Under FR-6 the doorway pages share one engine chart, so the same fragment list
repeats across the large majority of the corpus, adding both page weight and near-duplicate text
to the Pagefind index. That is the same truthfulness/duplication trade FR-6 was confirmed on
(REQUIREMENTS.md 181–183). Raised as OQ-1.

### Telemetry & Tracking

*Activated: the third acceptance criterion is a build diagnostic — "the build surfaces it" is
only satisfied if what it surfaces is legible in a CI log.*

No product analytics, no runtime instrumentation, no network call.

| Channel | Contract |
|---|---|
| stdout | **Nothing.** feature-001's Telemetry contract fixes "Exactly four lines per successful run" (§ Telemetry & Tracking, the stdout row); an appender that logged would break it. Per-node logging is out of the question at corpus scale. |
| stderr | Nothing on success (`coding-standards.md` § Logging and Output 233–241). |
| Failures | `throw new Error('[gen-skills] <guard>: <detail>')`, uncaught — feature-001's shape (§ Telemetry & Tracking, the Failures row: "Guard names are stable strings"), reusing its `[gen-skills]` prefix because this code runs inside that generator. |
| Guard names (new, stable, greppable, assertable) | `provenance path`, `provenance range`, `provenance excerpt` |
| Exit codes | Unchanged: `0` success, `1` on an uncaught guard throw. No new code — `coding-standards.md` § Exit Codes (212–229) says a new failure mode should reuse an existing code with matching semantics. |

Message shape — actionable, and carrying the resolved detail the way
`coding-standards.md` 196–208 requires (illustrative failure output; neither condition exists on
today's tree):

```
[gen-skills] provenance range: aid-describe node n3 cites canonical/skills/aid-describe/SKILL.md#L275-L277 but that file has 274 lines
[gen-skills] provenance excerpt: aid-review node n5 no longer matches canonical/skills/aid-review/SKILL.md#L184-L186 (first difference at line 185) — re-run gen:skills after editing canonical/
```

#### Throw, not warn — and why

The verifier **throws on the first violation**. Four grounds, in descending weight:

1. **The criterion says so.** This feature's third acceptance criterion is "the build surfaces
   it rather than emitting a broken link" — a warning in a build log that nothing reads emits the
   broken link anyway.
2. **It matches the posture of both features it sits between.** Feature-001's drift guard throws
   (§ Drift guard (AC-1), modelled on `gen-reference.mjs` 377–381) and feature-003's validator
   caller throws on any V-rule error (§ Contract — the well-formedness validator, the paragraph
   closing the V1–V9 table: "The caller **throws** on any error").
3. **FR-2's best-effort boundary does not reach here.** Feature-003 draws that line explicitly in
   that same paragraph: `chart.warnings` are logged and never thrown, because "a chart may be
   *approximate*, never *malformed*". A warning is the right response to a lossy *interpretation*. A
   recorded range that does not match the file is not an interpretation — it is a factual
   inconsistency between the artifact and its own cited source, and it falsifies AC-5 for that
   node.
4. **NFR-3 makes the link the corrective of last resort.** A wrong label is survivable because
   the fragment corrects it; a wrong fragment is survivable because the link corrects it. A wrong
   link has nothing behind it, so it is the one failure with no fallback.

Rejected: warn-and-omit-the-link (produces a page that silently fails AC-5 for one node, which is
strictly worse than a red build) and warn-and-emit (ships the broken link the criterion names).

The checks, in order, per node — first failure throws:

| # | Check | Guard |
|---|---|---|
| P0 | The cited file's text contains no `\r`. `.gitattributes` 11–14 forces `*.md text eol=lf`, and 0 CRLF files were measured under `canonical/skills/` on 2026-07-25; a mis-configured checkout would otherwise fail every excerpt comparison with a confusing diff instead of a one-line cause. | `provenance path` |
| P1 | `file` is non-empty, POSIX, under `canonical/`, free of `..`, and exists on disk. | `provenance path` |
| P2 | `startLine`/`endLine` are integers with `1 <= startLine <= endLine`. (Feature-003's V7 checks the excerpt's internal shape; only this check sees the file.) | `provenance range` |
| P3 | `endLine <= lineCount(file)` — the range exists. | `provenance range` |
| P4 | `excerpt === lines.slice(startLine-1, endLine).join('\n')` — feature-003's equality (§ `Provenance`), safe as a byte comparison because of P0. | `provenance excerpt` |
| P5 | The excerpt contains at least one non-whitespace character. A range citing only blank lines renders as an empty box and exposes nothing, which fails AC-5's "the verbatim prompt fragment is exposed" while passing P4. | `provenance excerpt` |
| P6 | `detail`, when present: P1–P3 only. It carries no excerpt by contract (feature-003 § `Provenance`). | as above |

Each cited file is read **once per run** into a `Map<file, {text, lines}>`, so verification costs
one read per distinct source file rather than one per node — material when a doorway corpus
shares a single engine file.

### Open Questions

- **OQ-1 — Doorway pages repeat one identical fragment list across most of the corpus.** FR-6
  puts the full engine chart on every doorway page, so this feature puts the same engine
  fragments there too: real page weight, and a Pagefind index full of near-identical text.
  **Default taken here:** render them in full, because FR-6 was confirmed precisely on the
  standalone-page promise (REQUIREMENTS.md 181–192). **Alternatives for the owner:** collapse the
  fragment section behind `<details>` on doorway pages only, or mark it
  `data-pagefind-ignore` on doorway pages to keep search clean while the text stays visible.
  Either is a one-line change here; neither can be chosen without an owner call about search and
  page weight.
- **OQ-2 — Who performs AC-7, and when.** The check is specified above as non-blocking, two
  pages, at the delivery gate, recorded in the work folder. Which human — the owner, or a
  reviewer who has not read the fixture skills — is a staffing decision. AC-7 passes or fails the
  delivery either way; only the record differs.
- **OQ-3 — Should `docs.yml`'s path filter gain `canonical/**`?** Today a commit that edits
  `canonical/` without regenerating the pages triggers no docs build, so the deployed page keeps
  the previous generation's line anchors until the next `site/**` push (§ External Integrations,
  Residual risk). Adding `canonical/**` to the two path filters (`docs.yml` 13–17, 20–24) closes
  the window at the cost of rebuilding the site on methodology-only commits. `docs.yml` is
  **feature-001's** file (its § Migration Plan → "What is touched, exhaustively" lists it as
  item 4), so this is a cross-feature decision, not a local one.
