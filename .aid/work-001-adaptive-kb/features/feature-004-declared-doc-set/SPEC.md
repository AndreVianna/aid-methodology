# Declared, Project-Shaped Doc-Set

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-30 | Feature drafted from approved (re-scoped) REQUIREMENTS.md | /aid-interview FEATURE-DECOMPOSITION |
| 2026-05-31 | Full-review fixes: atomic ACs; gate→mapping retarget; mechanical non-software AC; absorbed FR-P0-4 (remove fixed doc-count assumption); /aid-plan split note | /aid-interview (full review) |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Review fix (C+→target A): storage form = pipe-delimited discovery.doc_set in settings.yml read via existing read-setting.sh (user-ratified; no dedicated file, no new parser); resolved KNOWN ISSUE #1; fixed citation nits | /aid-specify |
| 2026-05-31 | Review fix (#5): forbid commas in field values incl. the when-hint (comma is the item separator); added validation + test guard | /aid-specify |
| 2026-05-31 | Review fix (#6): corrected §2.1 guard comment to match real behavior (fragment-1 survives with truncated display-only when; fragments 2+ skipped); aligned §4 test to the true safety invariant | /aid-specify |

## Source

- REQUIREMENTS.md §1 Objective, §4 (P1 lean), FR-P0-4, FR-P1-1, FR-P1-2, FR-P1-3, FR-P1-4,
  FR-P1-5, FR-P1-6; §9 AC1–AC6

## Description

Let the KB's *set of authored docs* shape itself to the project, expressed as configuration
rather than an undocumented exception — using the lightest mechanism that resolves H5.

Concretely, this feature introduces a **declared doc-set**: a minimal list of
`{filename, owner, presence (required/conditional, + optional when)}` that **defaults to the
standard software-dev seed set** (enumerated in REQUIREMENTS §8), so projects with no override
behave unchanged. The declared set **replaces the hard-coded doc-filename list** in the
discovery skill/state-generate and the ownership map currently scattered across the discovery
agents + skill tables. **There is no fixed doc-count** (FR-P0-4): the "14"/"16" literals in
`SKILL.md`, `state-generate.md`, `state-review.md`, `build-kb-index.sh`, and `README` are
removed or replaced by references to the declared set, so the number and identity of docs vary
by project — the standard seed set is the fallback, not a universal invariant. It deliberately **reuses what
already exists**: `kb-category` stays in each doc's frontmatter, and per-doc expectations stay
in the (feature-002) consolidated source keyed by filename — the declared set does **not**
re-declare either. The discovery **completeness gate reads the declared set** and therefore does
not hang on an intentionally-omitted doc.

At discovery time, **discovery proposes a doc-set and the user confirms**: it reads
`project-index.md` (already a whole-tree inventory) and proposes a set (default = standard,
with deltas for the actual project — add / remove / rename / repurpose), which the user
confirms or edits. There is **no archetype taxonomy, classifier, seed-file set, or archetype
fixtures** — the propose→confirm step is the derivation.

**Custom docs get an owning agent + expectations and are actually generated and reviewed.** The
`owner` resolves to one of the **existing** discovery agents (a doc that fits no specialist is
assigned to a suitable existing agent — e.g. architect — via its prompt). **No new agent is
introduced by this feature.** The concrete implementation form of the declared set (a section
in the existing `settings.yml` vs. a small dedicated file) is decided in `/aid-specify`, kept as
light as possible, with **no bespoke parser** unless `owner`/`presence` genuinely cannot fit the
existing list-valued settings form (`read-setting.sh` already parses lists).

The primary acceptance test is reproducing this repo's cycle-1 carve-out as configuration
(rename `api-contracts→pipeline-contracts`, `data-model→schemas`, replace
`ui-architecture→repo-presentation`, drop `security-model`) and discovering one non-software
project type with an appropriate non-dev doc-set.

## User Stories

- As an AID adopter, I want one declarative place describing my project's doc-set so I do not
  have to hunt through multiple agent files to understand or change which docs exist and who
  owns them.
- As an AID adopter on a non-software project, I want discovery to propose a doc-set that fits
  my project and let me confirm/edit it, so my KB is not forced into a software-dev mold.
- As a discovery sub-agent, I want a single declarative ownership source instead of triplicated
  prose so that my owned docs are unambiguous.
- As a discovery reviewer, I want the completeness gate to validate exactly the declared set so
  that it does not hang on a doc that was intentionally omitted.
- As an AID adopter with a custom doc, I want it assigned to a competent existing agent with
  expectations so that it is actually generated and reviewed.
- As an existing software-project team, I want the declared set to default to the current
  standard set so that my project behaves unchanged.
- As an AID meta-repo maintainer, I want this repo's cycle-1 carve-out reproduced by
  configuration so that it is no longer an undocumented exception — achieved with minimal new
  machinery (convention over infrastructure).

## Priority

Must

## Acceptance Criteria

- [ ] Given a project with no override, when discovery runs, then it uses the default declared
      set equal to **the standard software-dev seed set enumerated in REQUIREMENTS §8** and
      behaves unchanged (backward compatible). *(FR-P1-2)*
- [ ] Given the tooling, when this feature is complete, then **no hardcoded doc-count/doc-list
      literal remains** — the "14"/"16" in `SKILL.md`, `state-generate.md`, `state-review.md`,
      `build-kb-index.sh`, and `README` are removed or replaced by references to the declared
      set, so the count/identity of docs varies by project (default seed set as fallback).
      *(FR-P0-4)*
- [ ] Given a declared doc-set, when it is read, then each entry exposes `filename`, `owner`,
      and `presence` (with optional `when`). *(FR-P1-1, data-shape)*
- [ ] Given a declared doc-set entry, when it is read, then `category` and `expectations` are
      NOT re-declared — `category` resolves from the doc's frontmatter and `expectations` from
      the feature-002 consolidated source keyed by filename. *(FR-P1-1, no-duplication)*
- [ ] Given the declared set is read at runtime, then it adds no new external dependency,
      reusing the existing settings list form unless `owner`/`presence` cannot fit it.
      *(FR-P1-1, dependency-free)*
- [ ] Given a declared set that intentionally omits (or adds) a doc, when discovery runs, then
      the **agent-to-file mapping** in `state-generate.md`/SKILL.md honors the declared set —
      no agent is dispatched for an omitted doc and an added doc is dispatched to its `owner` —
      so generation neither stalls on the omission nor skips the addition. *(FR-P1-6)*
- [ ] Given a project, when discovery proposes a doc-set, then it derives the proposal from
      `project-index.md` (default = standard + deltas) and the user confirms/edits it — never a
      static pick-list, and with no archetype classifier/seed-files/fixtures involved. *(FR-P1-3)*
- [ ] Given the declared set, when a doc is added / removed / renamed / repurposed, then
      discovery generates and reviews exactly the resulting set. *(FR-P1-4, AC1)*
- [ ] Given a custom doc, when ownership is assigned, then it resolves to one of the existing
      discovery agents with expectations, and the doc is generated and reviewed; no new agent is
      required. *(FR-P1-5, AC2)*
- [ ] Given this meta-repo, when the declared set encodes the cycle-1 carve-out, then discovery
      reproduces the carve-out as configuration (2 renames, 1 replace, 1 drop). *(AC3)*
- [ ] Given a deliberately non-software project (e.g. research / docs-only), when it goes
      through propose→confirm, then the confirmed declared set **mechanically differs** from the
      canonical default (omits ≥1 standard doc and/or adds ≥1 custom doc), the user's edits are
      honored verbatim, and discovery generates and reviews exactly that confirmed set.
      ("Appropriateness" is the human's call at confirm time, not a machine assertion.) *(AC4)*
- [ ] Given the change, when the canonical suites run (including a declared-set parse/resolve
      suite, a propose→default→confirm flow suite, and a mapping-honors-declared-set suite) plus
      the generator self-tests, then the existing suites (13 today) stay green, the new suites
      pass, and render-drift across the 3 profiles is clean (non-regression). *(AC5)*

> **Note for /aid-plan:** this feature is materially larger than the P0 features and bundles
> separable concerns with different risk/testability profiles. Consider splitting at planning
> time into **(a)** the deterministic declared-set artifact + default + mapping-honoring, and
> **(b)** the LLM propose→confirm flow + custom-doc ownership. Kept as one feature at the
> requirements level per the user's "don't re-cut now" decision.

---

## Technical Specification

> Scope of this spec: the **declared-set artifact + default seed + read-path + de-hardcoding +
> mapping-honors-set** (deterministic core) plus the **propose→confirm flow + custom-doc
> ownership** (LLM-judgment surface). `/aid-plan` is recommended to split these into two tasks
> (see *Backward Compatibility & Risks*). All edits land in `canonical/` and are re-rendered to
> the 3 profile trees + the dogfood `.claude/` tree by `run_generator.py`; render-drift across
> the 4 trees must stay clean (`tests/canonical/test-*.sh` are unaffected by tree choice — they
> exercise `canonical/`).

### 1. Declared-set format & location

#### 1.1 Storage form decision (with justification)

**Decision (user-ratified, 2026-05-31): a `discovery.doc_set` section inside the EXISTING
`.aid/settings.yml`, encoded as a block-list of pipe-delimited scalars, read with the EXISTING
`read-setting.sh` (`--path discovery.doc_set`) — NO dedicated `.aid/doc-set.yml`, NO new reader
script, NO bespoke parser.**

The declared set is a list of `{filename, owner, presence (+optional when)}` triples. The
existing list-valued settings form (`canonical/scripts/config/read-setting.sh`, `lookup_list()`
verified at `read-setting.sh:169-207`) returns a block-form list with its **items comma-joined
into a single string** (`--path A.B` direct lookup, verified at `read-setting.sh:13,21-25`). The
existing form carries the set by storing **each entry as one scalar list item** whose internal
structure is a fixed pipe-delimited field sequence `filename | owner | presence[:when]`. The
consumer reads the comma-joined list, splits on `,` to recover items, then splits each item on
`|` to recover the three fields. This is **a field split, not a parser** — it adds no grammar,
no new file, and no new script. It honors FR-P1-1's "reuse the existing list form" and does
**not** reverse the 2026-05-30 re-scope's "no dedicated `.aid/doc-set.yml`."

This is strictly lighter than the prior draft's dedicated-file + `read-doc-set.sh` approach:

- **Zero new files:** the set lives inside the settings file that already exists per project.
- **Zero new scripts:** `read-setting.sh` already returns block-form lists comma-joined; only a
  few lines of caller-side `tr`/`IFS` splitting are needed (§2.1).
- **No new dependency** (AC: dependency-free) — pure bash, consistent with the
  dependency-free-core NFR (REQUIREMENTS §6).
- **Honors the re-scope:** the 2026-05-30 RE-SCOPED row dropped the dedicated file on the theory
  the existing list-valued settings form could carry the set. This form does exactly that, so
  there is no reversal — KNOWN ISSUE #1 is RESOLVED (§6).

#### 1.2 Schema

`discovery.doc_set` inside the existing `.aid/settings.yml` (YAML 1.2; block-list of scalars,
each scalar a pipe-delimited record):

```yaml
discovery:
  doc_set:
    - architecture.md|discovery-architect|required
    - schemas.md|discovery-analyst|required
    - tech-debt.md|discovery-quality|required
    - infrastructure.md|discovery-quality|conditional:project has deployment/CI configuration
    - repo-presentation.md|discovery-architect|conditional
    # each item: filename | owner | presence(required|conditional[:when])
    # category and expectations are NOT declared here:
    #   - category resolves from the doc's own frontmatter `kb-category:` (build-kb-index.sh)
    #   - expectations resolve from references/document-expectations.md keyed by `### <filename>`
    # Absent section → the canonical default seed is used unchanged (backward compatible).
```

Field grammar (each list item is one record, fields separated by `|`):

- **field 1 — `filename`** — basename under `.aid/knowledge/`; the key that joins to frontmatter
  (`kb-category`) and to `document-expectations.md` (`### <filename>`).
- **field 2 — `owner`** — MUST be one of the **5 existing** discovery agents
  (`discovery-scout|discovery-architect|discovery-analyst|discovery-integrator|discovery-quality`),
  or the literal `orchestrator` for generated/meta docs (`feature-inventory.md`, `README.md`,
  `INDEX.md`). No new agent enum value (FR-P1-5).
- **field 3 — `presence`** — `required` | `conditional`. `conditional` MAY carry a free-text
  `when` after a colon (`conditional:<when>`) — a human hint shown at propose→confirm, not
  machine-evaluated; the user's confirm is the gate. The `when` hint **MUST be comma-free**
  (see the delimiter constraint below): rephrase any enumeration with `;` or `/`
  (e.g. `conditional:has CI; CD; or deploy config`), never a comma.
- `category`/`expectations` are intentionally **absent** (AC "no-duplication").

> **Delimiter constraint — no field value may contain a comma.** `read-setting.sh`'s
> `lookup_list` returns the block-list items **comma-joined into one string** (`read-setting.sh:13,21-25`),
> and the §2.1 caller re-splits on `,` to recover the items. The comma is therefore the **item
> separator** and cannot appear inside ANY field value (`filename`, `owner`, `presence`, or the
> free-text `when` hint) — a comma in `when` (e.g. `conditional:has CI, CD, or deploy config`)
> would be shredded by the comma-join/comma-split round-trip into spurious records
> (`…has CI`, `[ CD]`, `[ or deploy config]`) that then route to the unknown-owner fallback.
> Rephrase any list-like `when` with `;` or `/`. The `|` field separator is safe because
> filenames, the agent enum, and `presence` never contain `|`; a `when` hint is free text but is
> the last field, so any residual `|` in it is tolerated (everything after the 3rd `|` is treated
> as part of `presence`/`when`). No quoting or escaping grammar is introduced — `read-setting.sh`'s
> existing `lookup_list` strips trailing `# comments` and quotes from each block-form item already
> (`read-setting.sh:197-198`). The §2.1 read-path **validates** each parsed record and warns on a
> malformed/extra-field item rather than silently mis-dispatching.

#### 1.3 Default seed source

When the `discovery.doc_set` section is **unset/absent**, the **default seed** is derived
deterministically — NOT hardcoded as a literal list — from the canonical template directory
`canonical/templates/knowledge-base/*.md` (the 14 doc templates verified present:
`architecture, coding-standards, domain-glossary, external-sources, feature-inventory,
infrastructure, integration-map, module-map, pipeline-contracts, project-structure, schemas,
tech-debt, technology-stack, test-landscape`, plus `README.md`), with `owner` per entry resolved
from the agent-ownership table (§2.2). The absent-section path is detected by
`read-setting.sh --path discovery.doc_set` returning empty (no `--default`, exit 1 → caller
synthesizes the seed). This makes the default set **self-describing from the templates that exist
on disk** rather than a magic number, directly satisfying FR-P0-4 ("no hardcoded
doc-count/doc-list literal remains"). The generated `INDEX`, `README`, and discovery `STATE` are
meta artifacts owned by `orchestrator`, not template-seeded.

#### 1.4 Concrete carve-out encoding

This repo's cycle-1 carve-out (AC3) expressed as `discovery.doc_set` in `.aid/settings.yml` — the
**generic-software baseline** plus the four deltas (2 renames, 1 replace, 1 drop). The baseline
names that this repo renamed/dropped (`api-contracts`, `data-model`, `ui-architecture`,
`security-model`) are **not** present as canonical templates today (see KNOWN ISSUE #2); the
carve-out is therefore encoded as the **resulting** set this repo actually carries. Provenance is
recorded only in **trailing inline comments** (which `lookup_list` strips at `read-setting.sh:197`
because they are preceded by whitespace on the same item line) — **not** as full-line comment
separators between items, since a non-item line mid-list would terminate `lookup_list`'s
list-accumulation early (`read-setting.sh:204` `in_list { in_list=0 }`):

```yaml
discovery:
  doc_set:
    - architecture.md|discovery-architect|required
    - technology-stack.md|discovery-architect|required
    - module-map.md|discovery-analyst|required
    - coding-standards.md|discovery-analyst|required      # security-model §11 merged here (drop)
    - integration-map.md|discovery-integrator|required
    - domain-glossary.md|discovery-integrator|required
    - test-landscape.md|discovery-quality|required
    - tech-debt.md|discovery-quality|required
    - infrastructure.md|discovery-quality|required
    - project-structure.md|discovery-scout|required
    - external-sources.md|discovery-scout|required
    - feature-inventory.md|orchestrator|required
    - schemas.md|discovery-analyst|required               # rename: data-model.md -> schemas.md
    - pipeline-contracts.md|discovery-integrator|required # rename: api-contracts.md -> pipeline-contracts.md
    - repo-presentation.md|discovery-architect|required   # replace: ui-architecture.md (custom; no template)
    # (drop: security-model.md is simply absent — no entry)
```

> The lone full-line comment above is the **last** line of the block, after the final item, so it
> does not interrupt accumulation. Inline `# …` notes on item lines are stripped per
> `read-setting.sh:197`; never place a full-line comment *between* two items.

A drop is expressed by **omission**; a rename/replace by listing the new `filename`; an addition
(`repo-presentation.md`) by an entry whose `filename` has no canonical template (it is generated
fresh by its `owner` from the agent prompt + its `document-expectations.md` entry).

### 2. Files & edits (all under `canonical/`)

#### 2.1 Read-path — EXISTING `read-setting.sh` + a caller-side field split (NO new script)

There is **no new reader script**. The declared set is read with the existing
`canonical/scripts/config/read-setting.sh`:

```bash
# Resolve the declared set; empty/exit-1 ⇒ section unset ⇒ synthesize default seed.
raw="$(bash "$REPO/canonical/scripts/config/read-setting.sh" \
        --path discovery.doc_set 2>/dev/null || true)"
```

`--path discovery.doc_set` parses `section=discovery`, `key=doc_set`, and (since the value is a
block list, not an inline scalar) falls back to `lookup_list` at `read-setting.sh:252`, returning
the block-list items **comma-joined into one string** (verified `read-setting.sh:13,21-25,169-207,252`),
e.g.
`architecture.md|discovery-architect|required,schemas.md|discovery-analyst|required,…`.

The consumer then splits the list and each record with a few lines of bash — a field split, not
a parser:

```bash
resolve_doc_set() {              # echoes: filename<TAB>owner<TAB>presence  per line
  local raw="$1" item fn owner pres rest
  if [ -z "$raw" ]; then synth_default_seed; return; fi   # §1.3 absent ⇒ default
  local IFS=','
  for item in $raw; do
    IFS='|' read -r fn owner pres rest <<<"$item"
    # Malformed-record guard (delimiter constraint, §1.2): a well-formed item is
    # filename|owner|presence with NO comma in any field. A comma in a `when` hint
    # shreds one record across the comma-join/comma-split round-trip: fragment 1
    # (e.g. `infrastructure.md|discovery-quality|conditional:has CI`) KEEPS its
    # `filename`+`owner` (the comma was consumed by the outer split), so it PASSES
    # this guard and resolves to a VALID owner — only its `when` hint is silently
    # truncated; fragments 2+ (e.g. `[ CD]`, `[ or deploy config]`) carry no `|`
    # (so `owner`/`pres` come back empty) and ARE caught/warned/skipped here.
    # The guard therefore does NOT reject fragment 1; the residual effect is a
    # cosmetically shortened `when`, which is benign because `when` is a
    # display-only hint shown at propose→confirm and is NEVER machine-evaluated
    # (§1.2 ~L199) — so the worst case is a shortened display string, never a
    # wrong/unknown-owner dispatch. The grammar (§1.2) forbids commas outright;
    # this guard is defense-in-depth for the malformed fragments 2+ only.
    if [ -z "$fn" ] || [ -z "$owner" ]; then
      printf 'warn: malformed doc_set record %q (missing field — comma in a value? commas are forbidden, §1.2) → skipped\n' \
        "$item" >&2; continue
    fi
    pres="${pres:-required}"
    case "$owner" in
      discovery-scout|discovery-architect|discovery-analyst|\
      discovery-integrator|discovery-quality|orchestrator) ;;
      *) printf 'warn: unknown owner %s for %s → discovery-architect\n' \
           "$owner" "$fn" >&2; owner='discovery-architect' ;;   # FR-P1-5 fallback
    esac
    printf '%s\t%s\t%s\n' "$fn" "$owner" "$pres"
  done
}
```

The four logical accessors the flow needs are derived from `resolve_doc_set` (no script, just
shell on its TSV output):

- **list-filenames** → `resolve_doc_set "$raw" | cut -f1` (default seed if section unset).
- **owner of `<filename>`** → `resolve_doc_set "$raw" | awk -F'\t' -v f="$fn" '$1==f{print $2}'`.
- **owns `<agent>`** (inverse — "what does discovery-analyst generate in THIS project") →
  `resolve_doc_set "$raw" | awk -F'\t' -v a="$agent" '$2==a{print $1}'`.
- **resolve** → `resolve_doc_set "$raw"` itself (full `filename owner presence` rows).

`synth_default_seed` enumerates `canonical/templates/knowledge-base/*.md` and pairs each with its
owner from the §2.2 ownership map (the backward-compatible default — AC FR-P1-2). Owner enum is
validated above; an unknown owner is a non-fatal warning routed to `discovery-architect` as the
generalist fallback (FR-P1-5 — "a doc that fits no specialist is assigned to a suitable existing
agent, e.g. architect").

These few lines live as a **shared snippet** in the discovery SKILL prose (the SKILL already
embeds inline bash for its state steps) — referenced from `state-generate.md`/`state-review.md`
rather than duplicated. No standalone `canonical/scripts/kb/` script is introduced.

#### 2.2 Ownership: single source replaces ~12 scattered locations

Today ownership is triplicated across (verified): each of the 5 `discovery-*/AGENT.md`
**description frontmatter line** (e.g. `discovery-architect/AGENT.md:3`) **and** body
`## Output Documents` heading+list (`discovery-architect/AGENT.md:85`); the `state-generate.md`
Steps 2-5 mapping table (`state-generate.md:67-72`); and the SKILL.md **Targeted Discovery**
table (`SKILL.md:269-274`). The declared set (via the `owns <agent>` accessor of §2.1) becomes
the **single authority**; the agent/table prose is reduced to a stable narrative that **defers** to
the declared set for the exact filename list ("you own the docs assigned to you in the project's
declared doc-set; in the default seed these are …"). This removes the FR-P0-1 scout/quality
contradiction (`discovery-scout/AGENT.md:3,68` claims `infrastructure.md`+`project-structure.md`
while the SKILL/state-generate tables assign `infrastructure.md`→quality, `external-sources.md`→
scout) by making the declared set the only place ownership is asserted. **NOTE — cross-feature:
FR-P0-1 ownership reconciliation is feature-001's deliverable; this feature consumes its
corrected mapping. Coordinate with F1 so the §2.2 ownership map = F1's reconciled truth.**

#### 2.3 De-hardcoding the count/doc-list literals (enumerated sites)

Each "14"/"16"/literal-list site, with the replacement:

| # | Site (verified) | Today | Replace with |
|---|---|---|---|
| D1 | `SKILL.md:144-148` | "the **14** expected documents: <hardcoded 14-name list>" | "the documents in the project's declared doc-set (`read-setting.sh --path discovery.doc_set` → list-filenames accessor, §2.1); default seed when the section is unset" — drop the inline name list |
| D2 | `SKILL.md:150` | "If all **14** populated …" | "If all declared docs populated …" |
| D3 | `SKILL.md:151` | "If all **14** populated but no STATE.md" | "If all declared docs populated but no STATE.md" |
| D4 | `SKILL.md:322` | "for each of the **16** KB documents plus meta-documents" | "for each declared KB document plus meta-documents" |
| D5 | `SKILL.md:269-274` | Targeted-Discovery ownership table (hardcoded rows) | narrative deferring to the §2.1 owns-`<agent>` accessor (see §2.2); keep a "default seed" example table marked illustrative |
| D6 | `state-generate.md:3` | "any of the **16** expected KB documents" | "any declared KB document is absent or placeholder" |
| D7 | `state-generate.md:8` | "`[0/16] Checking…`" | "`[0/N] Checking…`" where N = declared-set size at runtime |
| D8 | `state-generate.md:9` | "If ALL **16** have real content" | "If ALL declared docs have real content" |
| D9 | `state-generate.md:67-72` | Steps 2-5 mapping table (hardcoded target files) | rows derived from the §2.1 owns-`<agent>` accessor (see §3.2) |
| D10 | `state-generate.md:118-122` | "Verify All **16** Files" + "confirm count == **16**" | "Verify All Declared Files" + "confirm count == declared-set size" (the "(or whatever the project's declared kb-doc-set size is)" hedge becomes the rule) |
| D11 | `state-generate.md:131` | "Table with all **16** documents" | "Table with all declared documents" |
| D12 | `state-generate.md:176` | "`[16/16] Generation complete…`" | "`[N/N] Generation complete…`" |
| D13 | `state-review.md:3` | "grades all **16** KB documents … all **16** documents are populated" | "grades all declared KB documents … all declared docs populated" |
| D14 | `state-review.md:11` | "the list of **16** KB doc paths" | "the list of declared KB doc paths (§2.1 list-filenames accessor over `read-setting.sh --path discovery.doc_set`)" |
| D15 | `build-kb-index.sh:169` | "## Extension — project-specific (outside **canonical 16**)" | "## Extension — project-specific (outside the declared default seed)" — drops the number; build-kb-index already enumerates from disk (`find … -maxdepth 1`, line 150), so it is **already count-agnostic** — only the label string is wrong |
| D16 | `knowledge-base/README.md:73` | "Enterprise monorepo: All **14** documents, possibly more" | "All standard-seed documents, possibly more" (or restate as "the full default seed") |

`grade.sh` and the reviewer ledger schema are unaffected (they grade whatever files the reviewer
was handed — no count literal).

#### 2.4 Expectations & category resolution (NOT re-declared)

- **category** stays in each doc's frontmatter `kb-category:` and is consumed by
  `build-kb-index.sh:159-164` (`extract_field "$f" "kb-category"`). The declared set does not
  carry it. A custom doc declares its own `kb-category: extension` in its frontmatter exactly as
  today.
- **expectations** stay in `references/document-expectations.md`, keyed by `### <filename>`
  headings (verified shape, e.g. `document-expectations.md` `### project-structure.md`). The
  reviewer/FIX path looks up the entry by the declared `filename`. A custom doc (e.g.
  `repo-presentation.md`) requires a **new `### repo-presentation.md` section** added to that
  file. **NOTE — cross-feature: the single-source consolidation of expectations
  (`document-expectations.md` ↔ `discovery-reviewer`) is feature-002's deliverable. This feature
  depends on F2's consolidated, filename-keyed source existing; it adds custom-doc entries to it
  but does not own the consolidation.**

#### 2.5 Mapping-honors-declared-set (FR-P1-6 — the core behavioral fix)

`state-generate.md` Steps 2-5 (lines 53-116) currently dispatch a **fixed** agent→files table.
Change the dispatch to be **data-driven from the declared set**:

1. After Step 0c (project-index built) and the propose→confirm step (§3.1), resolve the set with
   the §2.1 resolve accessor (`read-setting.sh --path discovery.doc_set` + split) → rows of
   `filename owner presence`.
2. For each of the 5 discovery agents, compute its target file list with the §2.1 owns-`<agent>`
   accessor **intersected with the missing-on-disk set**. An agent whose computed list is
   **empty is NOT dispatched** (no hang on an omitted doc — FR-P1-6).
3. An **added** doc whose `owner` is some agent is included in that agent's list and the agent's
   prompt is told to also produce it (dispatch on addition — FR-P1-6). A custom doc owned by the
   architect fallback rides on the `discovery-architect` dispatch.
4. The **Verify All Declared Files** step (D10) confirms `count == size(list-filenames)` and
   cross-checks names against the list-filenames accessor — so an omission lowers the target, an
   addition raises it; neither stalls.

This retargets FR-P1-6 at the **mapping/dispatch**, not the count check (which `state-generate.md:120`
already hedges as soft).

#### 2.6 Custom-doc owner resolution (FR-P1-5)

`owner` is resolved by the §2.1 owner-of-`<filename>` accessor. If the declared owner is one of
the 5, the doc is dispatched to it and that agent's prompt (in `references/agent-prompts.md`) is
extended at runtime with "also produce `<filename>` per its expectations entry." If no natural
specialist fits, the declared `owner` is `discovery-architect` (the generalist fallback) — no new
agent. The custom doc is generated by its owner and **reviewed** because it is in the
list-filenames accessor output (so the REVIEW artifact list D14 includes it) and has a
`document-expectations.md` entry (§2.4).

#### 2.7 Re-render

After every `canonical/` edit, run `python run_generator.py` so the 3 profile trees
(`.claude/`-profile, Codex `.agents/`, Cursor `.cursor/`) and the dogfood `.claude/` tree are
re-rendered, and `verify_deterministic` (invoked at `run_generator.py:76`) confirms render-drift
is clean across the 4 trees. **No new script is added** — the read-path reuses the existing
`canonical/scripts/config/read-setting.sh` (already rendered) plus the §2.1 split snippet that
lives in the discovery SKILL prose. The `discovery.doc_set` section itself lives in each
project's `.aid/settings.yml` and is **per-project data, NOT in `canonical/`** — only its DEFAULT
(synthesized from templates) and the SKILL split/de-hardcoded logic are canonical.

### 3. Flow impact (discovery GENERATE/REVIEW)

#### 3.1 Propose→confirm insertion point

**Before (today):** `state-generate.md` Step 0c builds `project-index.md`; Steps 1-5 dispatch the
**fixed** agent set; "Verify All 16 Files" checks `== 16`.

**After:** insert **Step 0d — Propose & Confirm Doc-Set** between Step 0c and Step 1:

1. Read `.aid/generated/project-index.md` (whole-tree inventory — paths, languages, sizes; built
   at `state-generate.md:25-31`). This is a **file inventory, not a project-type label** — the
   orchestrator (LLM) **infers** a proposed doc-set from it (default seed + deltas: add/remove/
   rename/repurpose). Concrete heuristics live in the SKILL prose (e.g. "no test dirs/`package.json`
   → propose dropping `test-landscape`/`technology-stack` as `conditional`; docs-only tree →
   propose research/docs doc-set"). **No archetype classifier/seed-files/fixtures** — the
   inference is a single LLM judgment step.
2. **Present the proposal to the user** as a diff against the default seed and ask to
   confirm/edit. This is a **PAUSE-FOR-USER-DECISION** state-machine pause (per
   `state-machine-chaining.md`) — the safety net for the heuristic inference.
3. On confirm, write/update the `discovery.doc_set` section in `.aid/settings.yml` with the
   confirmed set. If the user accepts the default unchanged, the section MAY be omitted entirely
   (absent ⇒ default seed).
4. Continue to Step 1 with the confirmed set driving the data-driven dispatch (§2.5).

If `.aid/settings.yml` already carries a `discovery.doc_set` from a prior run, Step 0d **shows the
existing set** for re-confirm rather than re-inferring from scratch (idempotent re-entry).

#### 3.2 Gate/mapping consumption

- GENERATE dispatch (Steps 1-5): each agent's targets = owns-`<agent>` accessor ∩ missing (§2.5).
- Verify step: `count == size(list-filenames)` + name cross-check (§2.3 D10).
- REVIEW: the reviewer artifact list = list-filenames accessor output (§2.3 D14), so the
  completeness/quality gate validates **exactly the declared set** — no hang on an
  intentionally-omitted doc (User Story / AC FR-P1-6).

#### 3.3 Custom-doc dispatch path

A declared addition (e.g. `repo-presentation.md`, owner `discovery-architect`) appears in the
owns-`discovery-architect` accessor output; the architect dispatch prompt is extended to produce it; it lands
on disk; the Verify step counts it; REVIEW grades it against its `document-expectations.md` entry.
End-to-end generated AND reviewed (AC2 / FR-P1-5).

### 4. Test plan

**New canonical suites** (auto-discovered by `tests/run-all.sh` glob `tests/canonical/test-*.sh`
— verified at `run-all.sh:33`; no harness edit needed):

- `tests/canonical/test-doc-set-read.sh` — the read-path (§2.1 split over `read-setting.sh`):
  - **unset** `discovery.doc_set` in a fixture `settings.yml` → `read-setting.sh --path
    discovery.doc_set` returns empty ⇒ list-filenames accessor returns the full default seed
    synthesized from `canonical/templates/knowledge-base/*.md` (backward-compat / FR-P1-2).
  - present section → resolve accessor returns exact `filename owner presence` rows;
    owns-`<agent>` inverse is correct; owner-of-`<filename>` correct; `read-setting.sh` returns
    the items comma-joined and the split recovers each pipe-delimited record.
  - **trailing inline `# comment` on an item is stripped** (no provenance text leaks into
    `owner`/`presence`); a full-line comment **after the last item** does not truncate the list
    (guards the §1.2/§1.4 comment-placement constraint against `read-setting.sh:204`).
  - **comma-in-`when` cannot produce a wrong dispatch** (safety invariant; delimiter
    constraint, §1.2): a fixture item
    `infrastructure.md|discovery-quality|conditional:has CI, CD, or deploy config` ⇒ the
    comma-join/comma-split round-trip shreds it. Assert the TRUE behavior, not a blanket
    rejection: (a) the trailing fragments `[ CD]` and `[ or deploy config]` (no `|`/owner) hit
    the malformed-record guard — assert a `warn: malformed doc_set record …` to stderr and that
    neither surfaces as a resolved owner/filename in the TSV; (b) fragment 1
    (`infrastructure.md|discovery-quality|conditional:has CI`) SURVIVES as a well-formed record
    — it resolves to the VALID owner `discovery-quality` with a truncated (display-only) `when`,
    so do **not** assert it is rejected (that would contradict the round-trip's actual output).
    The invariant under test is the safety property: **no fragment produces a wrong or
    unknown-owner dispatch** (the only resolved owner is the legitimate `discovery-quality`; no
    bogus owner reaches the unknown-owner fallback), and the truncation is harmless because
    `when` is display-only (§1.2). This corrupted state should never ship: the §1.2 grammar
    forbids commas in any field outright — assert (authoring-time intent) that the comma-free
    rephrase `conditional:has CI; CD; or deploy config` parses cleanly into a single well-formed
    record with its full `when` intact (the correct, shipping form).
  - `category`/`expectations` are **not** present in any output (no-duplication assertion).
  - unknown `owner` → routed to `discovery-architect` with a warning, non-fatal (FR-P1-5).
  - dependency-free: runs with only bash+awk via the existing `read-setting.sh` (no yq/python,
    no new script) (dependency-free AC).
- `tests/canonical/test-doc-set-propose-confirm.sh` — flow:
  - default path: no override → resolved set == default seed (propose→default→confirm no-op).
  - user-edit path: a fixture `settings.yml` whose `discovery.doc_set` carries an omission + an
    addition → resolved set honors both **verbatim** (edits-honored assertion of AC4).
- `tests/canonical/test-doc-set-mapping.sh` — mapping-honors-set (FR-P1-6), MECHANICAL:
  - **no-hang on omission:** a set omitting `test-landscape.md` ⇒ owns-`discovery-quality`
    excludes it ⇒ the computed dispatch list for quality does not contain it ⇒ no agent is
    dispatched for the omitted doc; Verify target count drops by 1; assert no nonzero/hang.
  - **dispatch on addition:** a set adding `repo-presentation.md` (owner architect) ⇒
    owns-`discovery-architect` contains it ⇒ it is in the architect dispatch list; assert
    present.
  - **carve-out-as-config (AC3):** load the §1.4 carve-out `discovery.doc_set`; assert the
    list-filenames accessor contains `pipeline-contracts.md`+`schemas.md`+`repo-presentation.md`,
    **excludes** `api-contracts.md`/`data-model.md`/`ui-architecture.md`/`security-model.md`
    (2 renames + 1 replace + 1 drop resolve mechanically).
  - **non-software fixture (AC4), MECHANICAL:** a fixture docs-only `discovery.doc_set` (e.g.
    omits `test-landscape.md`, `schemas.md`; adds a custom `research-notes.md` owned by an
    existing agent) ⇒ assert the resolved set (a) **differs from the default seed** (≥1 omission
    and/or ≥1 addition by set-difference), (b) equals the fixture **verbatim** (user edit
    honored), (c) is exactly what the list-filenames accessor returns (discovery would
    generate+review exactly that set). No "appropriateness" assertion — the difference +
    verbatim-honoring is the mechanical claim.

**Existing suites + generator** (non-regression, AC5):

- `bash tests/run-all.sh` → the existing **13** suites stay green + the new suites pass.
- `python run_generator.py` → render-drift clean across the 3 profile trees + dogfood (the
  `verify_deterministic` gate at `run_generator.py:76`); no new script is added (the read-path
  reuses the already-rendered `read-setting.sh`); the de-hardcoded SKILL/state docs re-render
  clean.

### 5. Backward compatibility & risks

- **No-override projects are unchanged.** An unset `discovery.doc_set` ⇒ the read-path synthesizes
  the default seed from the existing templates; the GENERATE/REVIEW flow dispatches the same agents
  for the same files as today. The only behavioral delta for a standard project is the new Step 0d
  propose→confirm pause — which, on "accept default," is a single confirmation and writes nothing.
- **De-hardcoding is non-behavioral for the default set.** D1-D16 swap literals for declared-set
  references whose resolved value, for the default, equals today's hardcoded set. The reviewer
  grades the same docs; `build-kb-index.sh` already enumerated from disk (only its label changes).
- **Biggest risk: the propose inference is heuristic.** Inferring "this is a research / docs-only
  project" from file/language ratios in `project-index.md` is fallible. **Mitigation = the
  user-confirm safety net** (Step 0d PAUSE-FOR-USER-DECISION): correctness rests on the human
  catching a wrong proposal, not on the inference being right (REQUIREMENTS FR-P1-3). The
  mechanical ACs deliberately test "edit honored verbatim," not "inference correct."
- **`/aid-plan` split recommendation (carried from the SPEC note):** split into
  **(a)** deterministic core — the `discovery.doc_set` schema in `settings.yml` + the §2.1
  read-path (existing `read-setting.sh` + split snippet) + default-seed synthesis + D1-D16
  de-hardcoding + §2.5 mapping-honors-set + the three deterministic test suites; and
  **(b)** LLM surface — Step 0d propose→confirm flow + custom-doc owner resolution + prompt
  extensions + the non-software fixture AC. (a) is fully mechanically testable and de-risks (b);
  (b) carries the heuristic risk. They share the artifact but have different risk/testability
  profiles.

### 6. Known issues (for human decision)

- **KNOWN ISSUE #1 — RESOLVED (2026-05-31, user-ratified).** The earlier draft proposed a
  dedicated `.aid/doc-set.yml` + a new `read-doc-set.sh`, flagging a possible reversal of the
  2026-05-30 RE-SCOPED "no dedicated file" decision. The user ratified the **lighter** form
  instead: the set lives as a pipe-delimited block-list under `discovery.doc_set` **inside the
  existing `.aid/settings.yml`** and is read with the **existing** `read-setting.sh --path
  discovery.doc_set` (`lookup_list` verified at `read-setting.sh:169-207` returns block-form lists
  comma-joined). The consumer splits the returned list on `,` and each item on `|` to recover
  `{filename, owner, presence}` — a field split, not a bespoke parser. This **honors** FR-P1-1's
  "reuse the existing list form," adds **no new file** and **no new script**, and does **not**
  reverse the re-scope's "no dedicated `.aid/doc-set.yml`." No human decision pending.
- **KNOWN ISSUE #2 — carve-out baseline names don't exist as templates.** AC3 says the cycle-1
  carve-out is "2 renames, 1 replace, 1 drop" — but the pre-carve-out names (`api-contracts`,
  `data-model`, `ui-architecture`, `security-model`) are **not** present as canonical templates
  (verified: `canonical/templates/knowledge-base/` has only the post-carve-out 14). The default
  seed synthesized from templates is therefore *already* this repo's post-carve-out set, so the
  carve-out can only be validated as the **resulting** set (the §1.4/§4 mechanical assertion:
  declared set contains the renamed/replaced names and excludes the dropped/old names), NOT as a
  literal transform from a generic baseline that no longer exists on disk. If AC3 must demonstrate
  the *transform* (baseline → deltas), a generic-software baseline doc-set fixture must be added
  as a test fixture (not a shipped template). Recommended interpretation: AC3 = "the resulting set
  is reproducible as config," which the spec satisfies. Needs human confirmation.
- **KNOWN ISSUE #3 — REQUIREMENTS §8 default-seed enumeration vs FR-P0-4.** §8 enumerates the seed
  by name (14 docs); FR-P0-4 forbids hardcoded doc-lists. The spec resolves this by **synthesizing**
  the seed from the on-disk templates (§1.3) rather than hardcoding the §8 list — §8 is read as
  *documentation of* the seed, not as a literal to embed. Confirm this reading is acceptable.

### 7. Cross-feature dependencies

- **feature-001 (ownership reconciliation, FR-P0-1):** owns the corrected scout/quality ownership.
  §2.2's ownership map MUST equal F1's reconciled truth. This feature **consumes** F1, does not own
  the reconciliation. Sequence F1 before (or with) the (a)-split of this feature.
- **feature-002 (expectations consolidation, FR-P0-2):** owns the single filename-keyed
  `document-expectations.md`. §2.4 depends on that consolidated source existing; this feature adds
  custom-doc entries (e.g. `### repo-presentation.md`) to it. Sequence F2 before this feature's
  REVIEW-path work.
- **feature-003 (orphan-stub removal, FR-P0-3):** removes the orphaned `ui-architecture.md` stub +
  rendered stragglers. Independent of the declared-set logic but must land so the default-seed
  synthesis (§1.3, `find canonical/templates/knowledge-base/*.md`) does not pick up an orphan; the
  drop of `security-model`/`ui-architecture` in the carve-out (§1.4) assumes F3's cleanup is done.
