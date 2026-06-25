# State: PROFILE

PROFILE reads the doc-set and domain from feature-014 outputs to derive the resolved section
manifest; it runs when STALE-CHECK finds the KB is stale and no stored manifest exists.

**Do NOT auto-detect a project TYPE from KB greps.** Profile-as-project-type is retired.
The section set is derived from the resolved doc-set, deterministically, as described below.

---

## Step 1 — Read the two distinct input sources

Read the following two files (they are different files; do not conflate them):

| # | Derived attribute | Source field | Source file |
|---|-------------------|--------------|-------------|
| I1 | **Resolved doc-set** | `discovery.doc_set` (YAML list of `filename\|owner\|presence` entries) | `.aid/settings.yml` |
| I2 | **Domain** | `## Discovery Domain` → `- **Domain:**` line | `.aid/knowledge/STATE.md` |

**Parse I1 — doc-set entries to filenames:**
Each `discovery.doc_set` list item has the shape `filename|owner|presence`.
Split on `|` and take field 1 (the filename, e.g. `architecture.md`). Fields 2 and 3 are
not used for section derivation.

**Parse I2 — domain framing:**
Extract the value after `**Domain:**` (e.g. `hybrid:methodology-tooling+software-cli`).
Split on `:` and `+` to get facet tokens. Domain informs **labels and "what is this"
framing only** — it never reorders, gates, or adds a section.

---

## Step 2 — Resolve the doc-set

The **resolved doc-set** = the subset of I1 filenames that actually exist on disk in
`.aid/knowledge/`. For each `discovery.doc_set` filename, check whether
`.aid/knowledge/{filename}` exists:

- File **present** on disk → included in the resolved doc-set.
- File **absent** on disk → excluded (no phantom section, no placeholder).

A `.aid/knowledge/*.md` file NOT in `discovery.doc_set` is out of scope; the doc-set is
authoritative for membership. The intersection (doc-set ∩ disk) is the resolved doc-set.

---

## Step 3 — Read frontmatter for each resolved doc

For each resolved doc, read its YAML frontmatter and extract:

| Field | Use |
|-------|-----|
| `kb-category` | tier (`primary` \| `extension` \| `meta`); absent → treat as `primary` |
| `objective:` | section heading derivation + "why this matters" blurb |
| `summary:` | one-line section description + `noscript` list label |
| `intent:` | fallback when `objective:`/`summary:` absent (pre-f001 migration window) |
| `tags:` | rendered as keyword pills (omit if absent; no placeholder) |
| `see_also:` | "related" cross-links between sections (omit if absent) |

**Do NOT surface `audience:` as a role-badge** — the KB's agent-framing does not apply to
the summary (the newcomer does not care which agent-role a doc targets). Read the field for
internal use only; do not render it.

---

## Step 4 — Apply the section ordering rule

Order is mechanical (same input → same order):

1. **"At a Glance"** is always first (synthesized, not a doc section — see §5 below).
2. **Concept-first trio** — the three well-known docs appear immediately after "At a Glance",
   regardless of their position in the doc-set list:
   - `domain-glossary.md` (Glossary / concept spine)
   - `decisions.md` (Decision / ADR cards)
   - `capability-inventory.md` (Capability entries)
   Only include a trio member if it is in the resolved doc-set.
3. **Remaining `kb-category: primary` docs** in `discovery.doc_set` list order.
4. **`kb-category: extension` docs** in `discovery.doc_set` list order.
5. **`kb-category: meta` docs** (`external-sources.md`, `README.md`) sort last.
6. **Knowledge Base Index** is always last (full table of resolved docs, one-liner per doc).

---

## Step 5 — Identify bespoke components for well-known docs

Three docs receive bespoke content components (task-066 builds them; PROFILE names them):

| Doc filename | Bespoke component |
|---|---|
| `domain-glossary.md` | Glossary / definition component (term → definition cards) |
| `decisions.md` | Decision / ADR card component (context → decision → rationale → consequence) |
| `capability-inventory.md` | Capability entry component (what · when · how) |

All other resolved docs fall through to the **generic fallback**: table / card / prose /
infographic chosen per-fact (`primary` = full section, `extension` = supporting section,
`meta` = compact reference). No resolved doc is ever dropped.

---

## Step 6 — Derive the "At a Glance" inputs

"At a Glance" is synthesized from:

| Input | Source |
|-------|--------|
| **What this is** (lead) | project name (STATE.md or build file) + domain framing (I2) + `domain-glossary.md`/`capability-inventory.md` `objective:` |
| **What it does** | `capability-inventory.md` `objective:`/`summary:` + top capability rows |
| **Key vocabulary teaser** | first few `domain-glossary.md` terms |
| **Key decisions teaser** | first `decisions.md` ADR title(s) |

"At a Glance" leads with **what the project is and does** (plain language for a newcomer).
It does **not** lead with a software-metric card grid (module count / entity count /
endpoint count / test count). Counts may appear as a small secondary detail but are not
the section's purpose.

---

## Step 7 — Derive the noscript doc list

Collect the resolved doc-set filenames + each doc's `summary:` frontmatter. The noscript
list is the resolved doc-set (not a hardcoded list). Format:

```
Always lead with INDEX.md (the generated KB map), then one entry per resolved doc:
  <li><a href="./{doc}.md">{doc}.md</a> — {summary: value or doc name de-slugified}</li>
```

No hardcoded doc list. The list is injected by the GENERATE step into the noscript region
of html-skeleton.html.

---

## Output

Print:
```
[State: PROFILE] Doc-set/domain read complete.
  Domain:        {I2 value}
  Resolved docs: {N} of {M} doc-set entries present on disk
  Ordered sections: At a Glance | {trio present} | {primary docs} | {extension docs} | {meta docs} | KB Index
```

If `discovery.doc_set` is missing from `.aid/settings.yml` (pre-feature-014 KB), warn:
```
[State: PROFILE] WARNING: discovery.doc_set not found in .aid/settings.yml.
  Falling back to reading all .aid/knowledge/*.md files (no frontmatter ordering).
  Run /aid-discover to produce a feature-014-compatible KB for full section derivation.
```

And treat all present `.aid/knowledge/*.md` files (excluding `STATE.md` and `INDEX.md`)
as the resolved doc-set, ordered alphabetically, with `primary` tier for all.

Persist to `.aid/knowledge/STATE.md` `## Knowledge Summary Status`:
```
**Doc-Set Source:** .aid/settings.yml discovery.doc_set
**Doc-Set Count:** {N resolved} of {M total}
**Domain:** {I2 value}
**Domain Source:** .aid/knowledge/STATE.md ## Discovery Domain
```

Print: `[State: PROFILE] complete.`

**Advance:** **CHAIN** → [State: GENERATE] (continue inline).
