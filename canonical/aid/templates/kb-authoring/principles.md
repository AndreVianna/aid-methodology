# KB Authoring — Principles

> Normative rules for authoring `.aid/knowledge/` Knowledge Base documents.
> See [README.md](README.md) for the index and the list of tools that consume these docs.

These principles exist because **review effort scales with what's in the KB, not with
what's useful in the KB**. Every claim a reviewer must verify is a tax on the discovery
cycle. The principles below remove information that adds review cost without adding
knowledge value — and keep the information that's actually load-bearing.

## P1. No drift-prone information unless it carries semantic value

Four classes of content are commonly inlined into KB docs but rarely carry value:

- **(a) Cosmetic counting** — line counts, byte counts, method counts, "this file has
  N functions". The number drifts every commit; the reader can run `wc -l` themselves.
  **Banned from primary docs.** Replace with structural assertions where the count is
  load-bearing (see [tier-model.md](tier-model.md) T2 Structure).
- **(b) Dates without semantic anchor** — "as of 2026-05-22", "verified during cycle-N",
  inline timestamps in historical narratives. Git log carries this with higher fidelity.
  **Banned from primary docs.** Allowed in: `STATE.md` Review History (which is exempt
  from review), per-doc `changelog:` field (frontmatter, exempt from review), and as a
  semantic anchor only when the date marks a load-bearing inflection
  (e.g., "post-FR2 retirement, 2026-05") — even then, justify case-by-case.
- **(c) Other low-value clutter** — requires judgment. When unclear whether something is
  load-bearing, ask the user. Default to removal.
- **(d) Positional citations** — a bare `file.ext:LINE` line number is drift-prone (the
  line moves on the next edit above it) and carries nothing a `grep` can't recover. Cite
  the **durable anchor** instead: the file path plus a grep-recoverable symbol, heading,
  or unique string (e.g., `auth.ts` → `verifyToken`) — never a bare line number. The fact
  worth storing is that the symbol EXISTS in that file; a consuming agent greps the anchor
  to find its current location. **Bare line numbers banned from primary docs.** (Line
  *counts* are (a); this is the *pointer* form of the same drift class.)

  **Signature exception (P1(d)-SIG):** a load-bearing operational contract — the
  structural signature an agent must satisfy to ACT — is explicitly exempt from the
  altitude rule that lets a doc defer volatile detail to `sources:`. Work-critical
  contracts (data-schema field types, exit/error codes, host-tool capability flags,
  interface argument shapes, mode/option invariants) must be stated **INLINE** or behind a
  **precise grep-recoverable anchor** (the durable-anchor form above). A bare `sources:`
  file pointer is never sufficient for a contract of this class. **Rationale:** a
  `sources:`-deferred contract forces an agent to REACH for the source — which the
  assertiveness gate classifies as a load-bearing REACH insufficiency. The KB must carry
  the signature itself so an agent can plan and complete work from the KB alone.

  | Form | Verdict | Example |
  |------|---------|---------|
  | Schema field types + constraints stated inline in `schemas.md` | **Correct** — agent reads the contract directly from the KB |
  | Exit-code table with meaning per code stated in `pipeline-contracts.md` | **Correct** — agent acts on the exact codes without reaching |
  | `sources: [schemas/foo.json]` with no inline field types | **Wrong** — altitude rule does NOT apply to field-type contracts; the agent must REACH |
  | Linking to a large auto-generated schema file with a grep-recoverable anchor (`foo.json` → `## FooSchema`) | **Correct** — the anchor is precise and the agent can grep the exact contract |

  The altitude rule still de-bloats *narrative* volatility (historical rationale, prose
  elaboration, illustrative examples that add no contract obligation). Only
  work-critical operational contracts fall under P1(d)-SIG.

## P2. Proper metric

When a numerical fact IS load-bearing, it must follow three rules:

- **(a) Relevance** — the metric must serve a concrete purpose (driving an agent's
  decision, enforcing a contract, signaling a constraint). If you can't state what
  consumes it, it isn't proper.
- **(b) Measure before registering** — the value must be derived from disk truth at
  the moment of authoring. No copying old values forward; no estimating.
- **(c) No retroactive changes** — once a metric is correctly measured and registered,
  do NOT update it in historical contexts. A statement like
  "pre-canonical-generator the trees diverged at 453 / 1,078 / 1,090 lines" is a
  HISTORICAL FACT and must stay accurate to that point in time, regardless of present-day
  file sizes. Retroactive edits corrupt historical narrative into present-tense lies.

## P3. Plan first, change later

Review and fix are SEPARATE phases. Never blend them.

The discipline is encoded as a temp-file ledger pattern at
`.aid/.temp/review-pending/<skill-name>.md`:

1. **REVIEW phase** — as findings are identified, **upsert** each one to the ledger file.
   Each entry has: id, severity, source-doc + line, claim/issue, fix-tier (T1/T2/T3/T4),
   status (`pending` initially).
2. **FIX phase** — process the ledger top-to-bottom. For each entry, mark `in-progress`,
   apply the fix, mark `fixed`, then remove the entry from the file (or move to a
   resolved section if you want to inspect later).
3. **Completion** — when the file is empty, FIX is done. Delete the file. Move to next state.

**Rationale:** restart-safe (a session crash leaves the ledger intact for resume);
prevents cascade-fixing (you see ALL findings before applying ANY); enables batched
commits per scope; allows deferral (mark `deferred: <reason>` instead of fixing if
out of cycle scope).

**Auto-generated files refresh LAST.** Hand-edits land first; generated files
(metrics.md, INDEX.md, project-index.md) regenerate at the end of FIX, so they reflect
the final state. Refresh is driven by `canonical/templates/generated-files.txt`
registry.

## P4. Enforce via review, not by mechanical lint

Convention alone won't survive contributor turnover, but a brittle shell-script
linter doesn't either. The principles are enforced by the **`aid-reviewer`
sub-agent** in the REVIEW state:

- The reviewer reads each KB doc, validates its frontmatter against the schema in
  [frontmatter-schema.md](frontmatter-schema.md), checks declared `contracts:`
  against actual source, flags inline T4 markers in primary-category docs, and
  spot-checks claims. A semantic agent doing this holistically per doc is faster
  and more accurate than a per-claim shell loop.
- Generated-file existence (`.aid/generated/*`) is the only check that warrants a
  mechanical pre-commit gate; see `state-fix.md` Step 4 for the `test -f` loop
  over `generated-files.txt`.
- A per-project checklist may extend the reviewer's rubric. See
  [review-rubric.md](review-rubric.md) for the rubric the reviewer applies.

The checklist itself is intentionally adaptable per project profile — a CLI project's
KB has different shape than a web-app's. The checklist template lives at
[review-rubric.md](review-rubric.md) and may be extended via per-project `.aid/knowledge/.review-checklist.md`
overrides (gitignored by default; see [frontmatter-schema.md](frontmatter-schema.md)).

## P5. Mark auto-generated / temporary files clearly

Two kinds of non-curated files exist:

- **Generated content** (`.aid/generated/*`) — persistent build artifacts produced by
  registered scripts. Each file MUST carry an HTML-style comment at the top:

  ```html
  <!-- AUTO-GENERATED 2026-05-27T12:34:56Z by build-kb-index.sh — DO NOT EDIT — regenerate with `bash canonical/scripts/kb/build-kb-index.sh` -->
  ```

  The `source: generated` + `generator: <script>` frontmatter fields also declare this.
- **Temporary state** (`.aid/.temp/*`) — transient ledger / scratch files used during
  a skill's state machine execution. Gitignored. Lifecycle = "exists during a skill
  cycle; deleted when complete".

Skills MUST NOT review files in `.aid/.temp/`. Skills MUST verify generated files were
regenerated (existence check + build-script run) but do not grade the content beyond
spot-check correctness — see [review-rubric.md](review-rubric.md).

The canonical-default excluded paths are listed in [review-rubric.md](review-rubric.md).
Per-project additions are declared via `kb-category` + `source` frontmatter on each doc
(per P6); the lint reads frontmatter to determine review treatment.

## P6. Per-doc review metadata via frontmatter

Every KB doc carries YAML frontmatter declaring how it should be reviewed:

```yaml
---
kb-category: primary | meta | extension
source: hand-authored | generated
generator: <script>            # required iff source: generated
objective: One-line noun-phrase purpose (required for hand-authored primary/extension).
summary: One-sentence scope (required for hand-authored primary/extension).
sources:
  - path/or/glob                # required for hand-authored primary/extension
intent: |
  (superseded) Kept during coexistence window; see frontmatter-schema.md.
contracts:
  - "Structural claim 1 (verified by lint)"
  - "Structural claim 2"
changelog:
  - 2026-05-26: Migrated to v2 format (KB Authoring overhaul)
---
```

**The frontmatter block is partially exempt from review.** Most fields are exempt —
the reviewer reads them for classification only and does not grade their content. However,
there is a **P6 carve-out**: the required new fields (`objective:`, `summary:`,
`sources:`) are graded for presence and shape by the lint (`lint-frontmatter.sh`), not
by human reviewer judgment.

**What stays exempt (no review impact):**
- Legacy fields: `intent:`, `contracts:`, `changelog:`
- Optional new fields: `tags:`, `see_also:`, `owner:`, `audience:`
- Prose *quality* of `objective:` / `summary:` (only presence and mechanical shape are checked)

**What the lint checks (P6 carve-out, for `source: hand-authored` docs with `kb-category:`
in `{primary, extension}` that already carry any of the new fields):**
- `objective:` and `summary:` are present and non-empty (single-line scalars).
  Missing → `[FM-MISSING]` (HIGH).
- `sources:` is present as a YAML list (possibly `[]`). Missing → `[FM-MISSING]` (HIGH).
- Shape well-formedness of present fields. Malformed → `[FM-INVALID]` (HIGH).

**Day-one soft-skip:** docs carrying NONE of the new fields (`objective:`, `summary:`,
`sources:`, `tags:`, `see_also:`, `owner:`, `audience:`) are treated as pre-migration
and skipped by the lint. This ensures CI stays green on un-migrated KBs (the lint
becomes a hard gate only after f011 migrates AID's own docs).

This gives docs a way to carry self-describing metadata without polluting the review
surface, while ensuring the required routing/freshness primitive fields are mechanically
enforced once a doc adopts the new schema.

See [frontmatter-schema.md](frontmatter-schema.md) for the full schema specification.

## P7. Review is read-only on the repo

`/aid-discover` and the discovery skill family READ the repository and WRITE to
`.aid/knowledge/`. They MUST NOT modify any file outside `.aid/knowledge/`,
`.aid/generated/`, or `.aid/.temp/`.

If a review finds the repo is wrong (a citation points to a missing line; a contract
mismatches disk), the response is:

- **Fix the KB** — if the KB's assertion was wrong (the file was reorganized; the
  claim was stale); or
- **Raise a tech-debt entry** in `.aid/knowledge/tech-debt.md` — if the repo is
  genuinely missing the documented behavior.

The KB follows the repo, never the reverse. **Modifying repo code, configs, skills,
templates, or installers from within a `/aid-discover` cycle is a category violation
and a hard guard in the skill's pre-flight.**

Exception (one-time migration): the one-time KB-format migration (when these principles
are first applied to an existing project) is a separate operation — not a review. It may
touch KB doc content liberally because the act of migration is structural, not corrective.

Exception (connector sub-phase): the P7-exempt connector sub-phase of `/aid-discover` —
feature-002's `ELICIT` state, which restores external-source and external-tool elicitation —
is a declared, narrowly-scoped write exemption. It may write ONLY to:

- `.aid/connectors/` — the connectors registry: `INDEX.md`, the `<connector>.md` descriptors,
  the git-ignored `.secrets/` value store, and the connectors-local `.gitignore`; and
- the per-host MCP-config paths of **installed** hosts (feature-004 wiring; today only
  `claude-code` → the repo-root `.mcp.json`).

It writes nowhere else outside `.aid/knowledge/`, `.aid/generated/`, or `.aid/.temp/`. This
carve-out is a **declared authoring boundary, not a new pre-flight script guard**:
`discover-preflight.sh` still checks only STATE.md presence and Plan Mode, so adherence to
this allowlist is the sub-phase's own contract, not a mechanically enforced one.

## P8. Rigor follows value — verify the core, not the scaffolding

A KB doc is not uniform. Most of its truth-and-intent value lives in a small core of
load-bearing claims (T1 Concept + T2 Structure); the rest is scaffolding — frontmatter,
`changelog:`, navigation, decorative prose. The reviewer's (and author's) **first job on
each file is to locate that valuable core and spend maximum rigor THERE.** Scaffolding
gets light-touch: frontmatter and `changelog:` are present-and-parseable checks only
(per P6), never deep-verified. Effort spent verifying metadata is effort stolen from the
claims a downstream execution agent actually depends on.

---

## P9. Resolved items leave no trace

A KB doc records **current state only**. When a tracked item is resolved — a `tech-debt.md`
entry fixed, a Q&A answered, an open question closed — its record is removed **entirely**
from the doc: the inventory row, the detailed entry, any "closed items" roll-call, and any
closure prose in the frontmatter `changelog:`. Do **not** retain a closure record in the doc
("kept for history"); that clutter misleads readers into thinking a closed item is still
live, and it drifts. **git history (and the originating work's artifacts) is the only retained
audit trail.** This applies most visibly to `tech-debt.md` (open debt only) but holds for any
doc that tracks a working set. A resolved item still visible anywhere in the doc — or in a
generated view of it (e.g. `kb.html`) — is a defect.

---

## P10. Dual-audience authoring standard

Every KB document is authored for **two audiences at once**: a junior human reader and
an AI agent consuming the KB. These audiences have compatible needs -- small, focused,
clearly-written docs serve both -- and the standard below makes both audiences first-class.

### Granularity

| Rule | Meaning |
|------|---------|
| One concern per doc | Each document answers exactly one concern question (see [concern-model.md](concern-model.md)); mixing concerns is a boundary smell. |
| Minimal overlap | Content that belongs to a concern lives in that concern's doc, not repeated in others. |
| Small-and-focused default | Prefer a shorter, tightly scoped doc over a large catch-all. A junior reader finishes a short doc; an agent loads a small doc without bloating its context. |
| Split oversized docs | When a single concern grows too large, split into per-subsystem or per-aspect docs under the same concern -- use the propose->confirm gate (see [concern-model.md](concern-model.md) "Split a large concern"). |

### Language

- Write for a **junior professional**: plain, clear, concrete. Avoid jargon where plain words work.
- Use **active voice** and short sentences. One idea per sentence.
- Clarity over completeness: a shorter, clear doc is more useful than a long, jargon-dense one.
- Define project-specific terms in `domain-glossary.md` on first use; do not assume familiarity.

### Format

- Use **tables and bullet lists** as the primary structure for reference material.
- **Avoid diagrams** (Mermaid, SVG, ASCII art) in KB `.md` documents. Diagrams degrade
  in plain-text rendering, cannot be grepped, and add maintenance cost without adding
  greppable content.
  - Exception: the `kb.html` visual summary generated by `aid-summarize` is a
    deliberately-visual artifact designed for browser rendering -- the no-diagram rule does
    **not** apply to `kb.html`. Code examples (` ``` ` blocks) are not diagrams and are
    permitted.
- Named greppable sections (see [concern-model.md](concern-model.md) "Operational guidance is first-class structure") over interleaved prose.

### Layout (every doc, no exceptions)

Every KB document MUST follow this top-to-bottom layout order:

| Position | Section | Notes |
|----------|---------|-------|
| 1 | **Frontmatter** | YAML block between `---` markers (see [frontmatter-schema.md](frontmatter-schema.md)) |
| 2 | **Title** | `# Doc Title` heading |
| 3 | **Index / table of contents** | A brief contents list or section-navigation aid (may be a short intro paragraph linking the sections). Required when the doc has more than 3 sections; encouraged for all. |
| 4 | **Content sections** | The concern's substance -- the bulk of the document |
| 5 | **Change Log** | `## Change Log` section, always LAST |

The Change Log section MUST be the final section of every doc. Place it after all content sections. If a doc currently has its change log elsewhere, move it to the end.

### Why both audiences benefit from the same standard

An agent loads a small, single-concern, table-structured doc into context without
wading through a large mixed doc or an unreadable diagram. A junior human reads the
same short focused doc and understands it without decoding jargon. The summary+pointer
model (synthesis in the doc; volatile detail left in `sources:`) further dissolves the
agent-vs-human fork: a junior reader stops at the summary; an agent follows `sources:`
into the code for detail. Audience decides which docs exist -- not layered depth within
a doc or duplicate per-audience docs. **Exception:** load-bearing operational contracts
(field types, exit codes, interface signatures) are stated inline even when other volatile
detail is deferred -- both audiences need them without reaching into source files (see
P1(d)-SIG and "Signature exception" in the Document boundary rule section).

---

## How the principles interact

- **P1 + P6** — frontmatter exemption gives docs a place to carry historical / metric /
  temporal info without exposing it to review. The principles ban inlining; the
  frontmatter accepts it.
- **P2 + P5** — proper metrics live in generated files (metrics.md), regenerated from
  disk truth; inlined "proper metrics" are still drift-prone.
- **P3 + P5** — the temp ledger pattern is itself a temporary file convention.
- **P4 + P6** — the lint enforces what the frontmatter declares.
- **P6 + P8** — frontmatter exemption is a special case of the general rule: rigor follows
  value; scaffolding (frontmatter, `changelog:`) gets present-and-parseable checks, while
  the load-bearing core gets full review.
- **P7 + P3** — review is observation only; the temp ledger is the action queue, but
  it acts on the KB, never on the repo.
- **P10 + P6** — dual-audience classification is enforced via the frontmatter fields
  `audience:`, `owner:`, `tags:` (concern/dimension classification). P10 sets the
  standard; P6 carries the machine-parseable fields; the Anatomy mandate (see
  `canonical/skills/aid-discover/references/state-review.md`) checks compliance.

## Document boundary rule

When authoring or splitting KB docs, the three-force boundary rule from
[concern-model.md](concern-model.md) applies: a doc boundary falls where **coverage**
(coherent concern), **fit** (right-sized), and **audience & ownership** (a natural
owner-role + readable audience) agree. A concern that no owner can maintain is a boundary
smell; a doc that serves two incompatible audiences is a split signal. See
[concern-model.md](concern-model.md) for the full rule, the propose->confirm flow, and
the audience-vs-tier axis distinction.

The summary+pointer model (durable synthesis in the doc; volatile detail left in
`sources:`) is the altitude rule: a doc synthesises *why* and *how parts interact*, it
does not transcribe source. **Operational guidance -- conventions / invariants / gotchas /
contracts -- is first-class greppable structure, not prose:** where a doc carries
operational guidance of class X, it carries it as the named section for X (see
[concern-model.md](concern-model.md) "Operational guidance is first-class structure").
These two rules are complementary: summary+pointer governs altitude; named-sections
govern findability of the guidance an agent acts on.

**Signature exception:** the summary+pointer altitude rule has one hard carve-out — the
**P1(d)-SIG signature exception** (see P1(d) above). Load-bearing operational contracts an
agent must honor to ACT (data-schema field types, exit codes, host-tool capability
matrices, interface argument shapes) are stated **inline or with a precise
grep-recoverable anchor**, never deferred to a bare `sources:` file pointer. The altitude
rule is about de-bloating *narrative* volatility; it does not apply to *work-critical
contracts*. See [concern-model.md](concern-model.md) "Operational guidance is first-class
structure" for the cross-reference on C5 Data & contracts and C0 Technology dimensions,
which are the primary carriers of signature contracts in a software project KB.

## See also

- [concern-model.md](concern-model.md) — 11 universal concerns + boundary rule + propose->confirm
- [tier-model.md](tier-model.md) — T1-T4 stability tiers for individual facts within a doc
- [frontmatter-schema.md](frontmatter-schema.md) — schema specification + per-field rules (dual-audience classification fields)
- [review-rubric.md](review-rubric.md) — per-category review treatment
- [README.md](README.md) — index of the kb-authoring docs
