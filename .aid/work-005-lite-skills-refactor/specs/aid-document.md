# Behavioral Spec — `document` family restructure (generic `aid-create-document` + hints)

> **Status:** LOCKED for implementation (design agreed 2026-07-15).
> **Tracked under:** `.aid/work-005-lite-skills-refactor/` (branch `work-005-lite-skills-refactor`).
> **Scope:** the 8 shipped `aid-document*` skills → restructured into a `document`
> **artifact** under create/change, plus hint-aliases. Shares the collapse pattern
> ([`aid-review`](aid-review.md)); records the document-specific deltas.
> **Not implemented yet.**

---

## 1. Problem & reframe

- **Mismatch:** all 8 `aid-document*` are generated thin doorways → engine → plan a
  DOCUMENT work and halt. The document is never written.
- **Reframe (two realizations this session):**
  1. **`document` is an artifact, not a verb.** Every skill's description is *"write /
     create a [kind] document."* The operation is `create` (or `change`); "document" is
     the thing. So it belongs in the create/change families, like `test`.
  2. **Neither genre nor format should be the *skill* axis.** The old genre suffixes
     (decision / architecture / runbook / …) are document *structures* — guidance, not
     skills. Framing by *format* instead (diagram / markdown / presentation / …) is a
     better axis but is **open-ended** and would re-introduce the enumeration trap we
     removed from `aid-review`/`aid-test`. The collapse behavior is identical across
     every genre and format; only the producer/tooling and output format vary. So the
     skill is **one generic document-creator**, and genre/format are **hints** the agent
     resolves — not the skill boundary.

## 2. Objective (locked)

`/aid-create-document <subject>` **writes the document now**, and `/aid-change-document`
**updates an existing one** — determining both the **format** (markdown, mermaid diagram,
HTML, table, …) and the **structure** (ADR, runbook, tutorial, …) from the request,
grounded in the KB + codebase, with the human approving placement before it lands.

## 3. Classification note (per-artifact, not per-verb)

**COLLAPSE.** A document is low-cost, reversible prose/markup (side-effect axis ✗,
validity axis ✗ → produce now). This means the create/change families hold **both**
categories: keep-cycle for executable code artifacts (`api`/`ui`/`cli`/`test`/…) and
**collapse for the `document` artifact.** That is the discriminator working per-artifact,
not an exception — contrast `aid-create-test` (keep-cycle: test code runs in CI).

## 4. Topology

- **Canonical:** `aid-create-document` (create new) · `aid-change-document` (update
  existing).
- **Pure aliases:** `aid-add-document` → `aid-create-document` · `aid-update-document` →
  `aid-change-document` (shipped convention: `create`/`change` canonical, `add`/`update`
  alias).
- **Hint-aliases** (thin `repurpose` doorways binding a genre/format hint, delegating to
  the generic body):
  - **Genre (backward-compatible — the 8 shipped names stay working):** `aid-document`
    (general), `aid-document-decision`, `-architecture`, `-guideline`, `-standard`,
    `-runbook`, `-tutorial`, `-changelog`.
  - **Format (capability-gated, extensible):** `aid-create-diagram` (mermaid/graphviz —
    a genuinely distinct, producible format). *Not* adding `presentation`/`spreadsheet`
    as dedicated aliases yet — the generic skill attempts them and **degrades/hands off**
    (see §5) rather than advertising binary-format capability we can't reliably deliver.
    The hint set is trivially extensible later.
- **Removal:** bare `aid-remove` / `aid-delete` (no `aid-remove-document`, same rule as
  every other artifact).
- All the old `aid-document*` rows + the new ones are `repurpose: true`; one shared
  hand-authored body; the 8 old names + the format hints are thin doorways over it.
- **Group:** stays **G8 (Document)** for triage/discoverability (verb drives behavior,
  group drives discovery — same split noted for the test family).

## 5. Behavior (collapse, single-shot)

Same skeleton as the other collapses; document-specific pieces:

- **Producer = `aid-tech-writer`** (tier medium/**sonnet**) — the doc author. Writes
  text-based output natively: markdown, **mermaid** diagrams, HTML, CSV/markdown tables.
- **Format by intelligence.** The controlling agent picks the format from the request
  (or the format hint) and the structure from the genre (or genre hint), using the
  archetype guidance from §7. `aid-change-document` reads the existing doc first and edits
  it.
- **Grounding enforced:** accuracy against KB + codebase (the DOCUMENT rule); `aid-reviewer`
  verifies in clean context; **one deliverable grade** gates (bounded loop).
- **Present-before-place gate (human final say):** draft in the work folder → present the
  draft + the proposed target location → on approval, place it. **Extra care on overwrite
  or on the published `docs/` tree** (inspect the target first; show the diff — never
  silently overwrite).
- **KB boundary (locked):** `aid-*-document` **never writes `.aid/knowledge/`.** The KB is
  `aid-discover`/`aid-update-kb` territory (its own authoring rules + grading). If content
  belongs in the KB, the skill **suggests a handoff to `/aid-update-kb`** (printed
  suggestion) rather than writing there.
- **Capability honesty:** produces text formats natively; for a format it can't cleanly
  emit (e.g. native `.pptx`/`.xlsx`), it produces the best text form (HTML/markdown deck,
  CSV) and **states the conversion handoff** ("open in your tool to export `.pptx`").
- **Handoffs (printed suggestions only):** the ownership-boundary routes still apply — a
  doc describing something not-yet-built suggests `/aid-create*` first; an ADR mandating a
  refactor suggests `/aid-refactor`; KB-bound content suggests `/aid-update-kb`.

## 6. Model/effort tiering

Producer `aid-tech-writer` sonnet by default (docs are the cheapest collapse); bump to
opus/high only for a heavy architecture write-up. Verifier `aid-reviewer` tier ≥ producer.
**Dispatch:** ~5 Opus (today) → **~2 tiered, usually 2× sonnet.**

## 7. Domain knowledge preserved

The 8 archetype structures already in `document.md` scaffolding are **kept as the genre
guidance** the generic skill applies (ADR: Context→Decision→Alternatives→Consequences;
architecture: C4/arc42 + Mermaid; guideline; standard; runbook: trigger→diagnostic→
remediation→escalation; tutorial; changelog: Added/Changed/Fixed/Removed/Security;
general: Diataxis). Nothing is lost — only the skill count changes.

## 8. Files the implementation will touch

1. `shortcut-catalog.yml` — add `aid-create-document`/`aid-add-document`,
   `aid-change-document`/`aid-update-document`; set `repurpose: true` on all document rows
   (new + the 8 existing); add the `aid-create-diagram` hint row; the 8 existing
   `aid-document*` become hint-alias rows.
2. `canonical/skills/` — one shared hand-authored document-collapse body + thin doorways
   (the 8 old names, the format hint(s), the 2 canonical + 2 alias names).
3. `shortcut-engine.md` — detach the `document` verb rows from the family-grouping /
   default-type tables.
4. Repurpose `document.md` scaffolding into the genre-guidance the generic body reads
   (content preserved, §7).
5. Regenerate: `build-shortcut-skills.py` → `run_generator.py` → dogfood `.claude/` resync.

## 9. Settled decisions

Resolved with the user 2026-07-15:

1. **`document` is a create/change artifact**, not a verb → `aid-create-document` /
   `aid-change-document` (+ `add`/`update` aliases).
2. **One generic skill + hint-aliases**, not a skill per genre or per format — genre/format
   are hints the agent resolves (the "defer to intelligence, don't enumerate" principle,
   third application after review + test).
3. **COLLAPSE** classification (per-artifact); create/change families hold a collapse
   member.
4. **KB boundary:** never writes `.aid/knowledge/`; hands off to `/aid-update-kb`.
5. **Capability-honest formats:** text native (markdown/mermaid/HTML/CSV); binary formats
   degrade + handoff; hint-alias set starts small (`aid-create-diagram`) and is extensible.
6. Inherits the collapse skeleton: producer + clean-context verify, one grade gates,
   present-before-place gate, printed-suggestion handoffs, per-call tiering.
