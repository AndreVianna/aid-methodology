# KB Authoring — Frontmatter Schema

> YAML frontmatter specification for `.aid/knowledge/*.md` documents. Loaded by
> `aid-discover` (review classification — the `aid-reviewer` sub-agent validates
> compliance semantically), `aid-config` (scaffolding), and `aid-summarize` (section
> intent extraction).
>
> **One field reaches wider than the KB.** `review-criteria:` carries the same shape on a
> `SKILL.md`, an `AGENT.md` and a template as it does on a KB doc, because all four are
> authored artifacts that can drift from what they claim. Everything else here is
> KB-scoped.

Every KB document MUST begin with a YAML frontmatter block delimited by `---` markers.
Per [principles.md](principles.md) P6, **the frontmatter block is partially exempt from
review** -- the required new fields (`objective:`, `summary:`, `sources:`) are graded for
presence and shape by the lint (see P6 carve-out), while all other fields (legacy and
optional) classify the doc and provide informational metadata without affecting the grade.

## Dual-audience classification

The frontmatter fields below support the **dual-audience authoring standard**
([principles.md](principles.md) P10): machine-parseable classification lets an AI agent
select the exact right doc from INDEX without reading every doc; human-readable fields
let the INDEX render a useful filter table.

| Field | Purpose | Who uses it |
|-------|---------|-------------|
| `audience:` | Who the doc is written for (e.g. `[developer, architect]`) | INDEX filter; boundary-split signal |
| `owner:` | The accountable role for freshness (e.g. `architect`) | Freshness tracking (f007); boundary rule |
| `tags:` | Concrete project keywords (e.g. `[auth, jwt]`) | INDEX tag column; agent retrieval |
| `objective:` | One-line noun-phrase purpose | INDEX Objective column; agent routing |
| `summary:` | One-sentence scope | INDEX Summary column; agent routing |

Together these five fields constitute the **dual-audience classification** an agent uses
to load exactly the relevant doc into context and a junior human uses to find the right
doc from INDEX without reading everything.

**Note on concern/dimension classification:** concern alignment (which spine dimension
C0-C9 / D a doc covers) is declared as a `tags:` value by convention (e.g. `tags:
[C2, modules, dependencies]`) rather than a dedicated field. The Anatomy mandate
checks that every doc is anchored to at least one spine dimension via the concern table
in [concern-model.md](concern-model.md); the `tags:` field carries the machine-readable label.

## Canonical schema

```yaml
---
kb-category: primary
source: hand-authored
objective: One-line noun-phrase purpose (INDEX Objective column).
summary: One-sentence scope of this document (INDEX Summary column).
sources:
  - path/or/glob/to/a/source        # files/dirs this doc summarizes
  - https://vendor.example/spec     # external docs count too
  # use `sources: []` only for a pure-synthesis doc with no underlying source
tags: [native-term, subsystem-name]   # optional -- concrete project keywords
see_also: [other-doc.md]              # optional -- negative-routing pointers
owner: architect                      # optional -- accountable owner-role (free string)
audience: [architect, pm]             # optional -- who the doc is for (free strings)
approved_at_commit: a1b2c3d           # GENERATOR-WRITTEN on approval; never hand-author
review-criteria: []                   # optional -- criteria true of THIS file only; omit when
                                      # the global and per-type levels already cover it
# --- legacy, superseded by objective:/summary:, retained until f011 migration ---
intent: |
  (superseded) One paragraph; kept only during the coexistence window.
---
```

For generated docs:

```yaml
---
kb-category: primary       # or meta, depending on the doc's role
source: generated
generator: build-kb-index.sh
objective: One-line noun-phrase purpose (generator-written for generated docs).
summary: One-sentence scope (generator-written for generated docs).
intent: |
  ...
review-criteria: []
---
```

## Field reference

### New fields at a glance

The 8 new fields introduced by f001 (in addition to `kb-category`, `source`, `generator`,
`review-criteria`, and the legacy `intent`, `changelog` fields):

| Field | YAML type | Class | Default | Semantics | Well-formedness rules |
|-------|-----------|-------|---------|-----------|----------------------|
| `objective:` | scalar string (one line) | **required**, hand-authored | none (lint error if absent when any new field present) | The doc's purpose as a noun-phrase -- the INDEX "Objective" column. Supersedes `intent:` for routing. | Non-empty after trim; single physical line (no `\|`/`>` block); SHOULD be a noun-phrase. Length advisory only. |
| `summary:` | scalar string (one line) | **required**, hand-authored | none (lint error if absent when any new field present) | One-sentence scope -- the INDEX "Summary" column. | Non-empty after trim; single physical line. |
| `sources:` | list of strings | **required**, hand-authored | none (lint error if absent; empty list `sources: []` allowed for pure-synthesis docs) | Files/dirs/external docs/URLs the doc summarizes. Keystone primitive for INDEX go-deeper (f002), freshness (f007), calibration (f005). | A YAML list. Each entry: repo-relative path, glob, or URL. Shape-checked (not resolved) by this lint. |
| `tags:` | list of short strings | optional | `[]` | Concrete project keywords for the INDEX "Tags" column. | If present, a YAML list of short strings (no embedded newlines). Free terms. |
| `see_also:` | list of strings | optional | `[]` | Negative-routing pointers -- "use that doc instead" -- the INDEX "See-instead" column. | If present, a YAML list. Each entry SHOULD be a sibling doc name (`schemas.md`). |
| `owner:` | scalar string | optional | unset (renders blank) | The accountable owner-role for freshness. Free string, not an enum -- see justification. | If present, non-empty single-line scalar. |
| `audience:` | list of short strings | optional | `[]` | Who the doc is for -- the INDEX "Audience" filter column. Free strings, not a closed enum. | If present, a YAML list of short role labels. |
| `approved_at_commit:` | scalar string (git SHA) | **generator-written** | unset (absent on un-migrated/never-approved docs) | The commit at which the doc was last approved; freshness baseline. Written by `aid-discover`/`aid-update-kb` on approval, **never hand-authored**. | If present, a 7-40 char lowercase hex string. Absence is valid (degrades gracefully -- f007 treats as "baseline unknown"). |

See per-field sections below for full detail including examples.

### `kb-category:` (required)

Per-document classification. Determines which review rubric applies.

| Value | Meaning |
|-------|---------|
| `primary` | Load-bearing knowledge doc (architecture, schemas, coding-standards, etc., AND `INDEX.md` — see `source:` for its generation status). Full review against T1+T2 facts; T3/T4 markers banned inline. |
| `meta` | Process / state ledger (`STATE.md`, `README.md`). Exempt from full review per P7-style reasoning. Spot-check current snapshot correctness only. |
| `extension` | Project-specific addition outside the project's declared doc-set (the domain doc-set, or the 15-doc default seed when none is declared) — e.g., `host-tools-matrix.md`. Reviewed but flagged as extension-scope. |

See [review-rubric.md](review-rubric.md) for per-category rubric details.

**INDEX.md is `primary` + `source: generated`** — it carries load-bearing RAG-navigation knowledge (agents depend on it) but the file is produced by `build-kb-index.sh` from each KB doc's `objective:`/`summary:` fields (falling back to `intent:` during the coexistence window). The combination routes to the "Full Primary + Build-Verify" rubric (see [review-rubric.md](review-rubric.md)) — both content correctness AND generator freshness are checked.

### `source:` (required)

Production mode.

| Value | Meaning |
|-------|---------|
| `hand-authored` | Written by humans (or AI agents acting as humans during /aid-discover GENERATE state). Full content review applies. |
| `forward-authored` | Authored from intent before code exists (the greenfield KB seed). **Full content review applies** (same rubric as `hand-authored`). The doc is **design-authoritative** (design->code, FR-4): freshness treats it as never-stale-from-source; code->design divergence is detected by feature-005's separate conformance check, NOT by f007. |
| `generated` | Produced by a registered build script. The script controls content. Reviewer verifies the file was regenerated (existence + freshness) but does not grade content. **`generator:` field MUST be set.** |

### `generator:` (required iff `source: generated`)

Name of the build script (relative to `.agent/aid/scripts/` or as a
project-relative path). Listed in `.agent/aid/templates/generated-files.txt` registry.

Examples: `build-kb-index.sh`, `build-metrics.sh`, `build-project-index.sh`.

### `objective:` (required for hand-authored primary/extension docs)

One-line noun-phrase declaring the doc's purpose. Supersedes `intent:` as the primary
routing source for the INDEX "Objective" column.

**Class:** required, hand-authored. **Default:** none (lint error if absent on a
`source: hand-authored` doc that carries any of the new fields).

**Well-formedness rules:**
- Non-empty after trim
- Single physical line (no `|`/`>` block scalars)
- SHOULD be a noun-phrase, not a sentence (length advisory, not lint-enforced)

**Note for `source: generated` docs:** `objective:` is generator-written; the
hand-authored-required lint does not apply. The generator emits it from its own
template (see `build-kb-index.sh`).

**Good:**
```yaml
objective: Architectural map of the AID-methodology repository and its canonical-to-render pipeline.
```

**Bad:**
```yaml
objective: |
  This document covers architecture.
```

### `summary:` (required for hand-authored primary/extension docs)

One-sentence scope of the document. The INDEX "Summary" column.

**Class:** required, hand-authored. **Default:** none (lint error if absent when any new field present).

**Well-formedness rules:**
- Non-empty after trim
- Single physical line (no `|`/`>` block scalars)
- SHOULD be a complete sentence

Two distinct single-line scalars (`objective:` + `summary:`) rather than reusing the
`intent:` literal block keeps the generator's single-line extractor (`extract_field`)
sufficient and avoids the multi-line `extract_literal` path for routing.

**Good:**
```yaml
summary: Read this to understand how the methodology pieces hang together; for raw file inventory see project-structure.md.
```

### `sources:` (required for hand-authored primary/extension docs)

The files, directories, external docs, or URLs the document summarizes. The keystone
primitive consumed by INDEX go-deeper (f002), per-doc freshness (f007), and calibration
coverage (f005).

**Class:** required, hand-authored. **Default:** none (lint error if absent when any new field present; empty list `sources: []` is valid).

**Well-formedness rules:**
- A YAML list (possibly empty: `sources: []`)
- Each entry is one of:
  - A **repo-relative path** (`src/foo.ts`, `.agent/aid/scripts/kb/`)
  - A **glob** (`src/parsers/*.py`, `.agent/aid/templates/*.md`)
  - A **URL** (`https://vendor.example/spec`)
- Path/glob/URL *resolution* is NOT checked by this lint (that is f007 freshness); the lint checks *shape* only
- A doc with genuinely no sources (e.g. a pure synthesis/glossary) MUST declare `sources: []` explicitly — absence is a lint error

**Mirrors the `review-criteria: []` convention:** absence signals "not yet filled in" (lint error); an explicit empty list signals "intentionally sourceless."

**Special case — `external-sources.md`:** this doc is a registry of external URLs and vendor specs, so its `sources:` entries are those external docs themselves (URLs), NOT `sources: []`.

**Good (repo-relative path):**
```yaml
sources:
  - .agent/aid/templates/knowledge-base/
  - .agent/aid/scripts/kb/build-kb-index.sh
```

**Good (external URL):**
```yaml
sources:
  - https://docs.docker.com/reference/dockerfile/
```

**Good (explicitly sourceless):**
```yaml
sources: []
```

### `tags:` (optional)

Concrete project keywords for the INDEX "Tags" column.

**Class:** optional. **Default:** `[]`.

**Well-formedness rules (if present):**
- A YAML list of short strings (no embedded newlines)
- No controlled vocabulary — free project terms

### `see_also:` (optional)

Negative-routing pointers — "use that doc instead" — the INDEX "See-instead" column.

**Class:** optional. **Default:** `[]`.

**Well-formedness rules (if present):**
- A YAML list
- Each entry SHOULD be a sibling **doc name** (`schemas.md`) so the INDEX can render it as a link; a bare prose pointer is tolerated but not linked

### `owner:` (optional)

The accountable owner-role for freshness tracking.

**Class:** optional. **Default:** unset (renders blank).

**Well-formedness rules (if present):**
- Non-empty single-line scalar (free string — NOT a closed enum)

**`owner:` is a free string, not an enum.** Rationale: the audience roster is explicitly
open-ended across project types, and a fixed enum would force every adopter onto AID's
role names. A project that wants a controlled vocabulary can add it via the existing
`.aid/knowledge/.review-checklist.md` override hook.

### `audience:` (optional)

Who the document is for. Drives the INDEX "Audience" filter column.

**Class:** optional. **Default:** `[]`.

**Well-formedness rules (if present):**
- A YAML list of short role labels (e.g. `[architect, pm]`)
- Free strings, NOT a closed enum (same rationale as `owner:`)

### `approved_at_commit:` (generator-written)

The commit at which the doc was last approved; the freshness baseline.

**Class:** generator-written. Written by `aid-discover`/`aid-update-kb` on approval.
**NEVER hand-authored.** Default: unset on un-migrated/never-approved docs.

**Well-formedness rules (if present):**
- A 7-40 character lowercase hex string (git SHA)
- Absence is valid — un-stamped doc is treated as "approval baseline unknown" by f007,
  NOT as a lint failure

### `intent:` (legacy — superseded, retained during coexistence window)

One paragraph (1-4 sentences) declaring what the doc is FOR.

**Status: SUPERSEDED by `objective:` + `summary:`.** Retained during the f011
coexistence window so existing docs do not break. Once f011 migrates all docs, `intent:`
is retired.

During the coexistence window:
- `build-kb-index.sh` falls back to `intent:` when `objective:` is absent
- New docs SHOULD use `objective:` + `summary:` instead of `intent:`
- The lint does NOT enforce removal of `intent:` (it remains exempt from the required-field check)

**For the f011 migration:** content from `intent:` is split into `objective:` (noun-phrase
summary of purpose) and `summary:` (one-sentence scope statement).

### `review-criteria:` (optional, list of objects)

**The criteria a reviewer validates this file against — and that whoever writes the file
complies with first.** Not a KB-only field: it carries the same shape on a `SKILL.md`, an
`AGENT.md`, a template, and a KB doc, because all four are authored artifacts that can drift
from what they claim.

Renamed from `contracts:`, which held only structural cardinality claims (T2 Structure per
[tier-model.md](tier-model.md)). Those claims are one *kind* of criterion; this field is the
general case, so a T2 cardinality assertion is now a `validate` entry with a severity.

Each entry is an object:

```yaml
review-criteria:
  - id: F-01              # required; a scope-prefixed id (G-/KB-/SK-/...) or F- for file-local
    kind: validate        # required; validate | exclude
    criterion: >          # required; what to check -- or, on an exclude, what must never be checked
      Every task type named here resolves to a section in this document
    severity: HIGH        # required when kind: validate; a schema error on kind: exclude
    why: >                # required always; on an exclude it is the whole point
      An unresolvable task type is dispatched at run time and fails there
```

| Key | Required | Meaning |
|-----|----------|---------|
| `id` | always | Greppable handle a finding cites. `F-` prefix for a criterion local to this file; a scope prefix (`G-`, `KB-`, `SK-`, ...) means the entry restates or overrides one declared in the project's criteria table. |
| `kind` | always | `validate` — a defect to look for. `exclude` — something a reviewer would reasonably check but must not, here. |
| `criterion` | always | The check itself, stated so two reviewers reach the same verdict. |
| `severity` | `validate` only | What a violation costs, from the scale in `grading-rubric.md § Issue Severities`. Absent on an `exclude`: an exclusion is not a defect kind, and there is no severity of zero. |
| `why` | always | The reason. On an `exclude` this is the load-bearing half — without it the next reviewer reinstates the check. |
| `oracle` | never | **Optional.** A path to an executable check that decides this criterion by RUNNING rather than by a reviewer re-reading it. See below. |

#### `oracle:` — deciding a criterion by running it

Every criterion is otherwise verified by a reviewer *reading* it, on every cycle, forever.
For a genuinely semantic criterion that is unavoidable. For a mechanically decidable one it
is both waste and a reliability problem: the same criterion gets re-derived by hand each
cycle, and not always to the same answer.

```yaml
review-criteria:
  - id: G-07
    kind: validate
    criterion: "Every in-scope markdown file resolves to exactly one type in the registry."
    severity: HIGH
    why: "A file matching two rows or none has no resolvable criteria set."
    oracle: scripts/checks/g07-selector-partition.sh
```

**Absence is never a defect.** Most criteria will never carry the key, and that is the
correct outcome rather than an omission to be fixed. Only a `validate` criterion can carry
one — a `kind: exclude` names something a reviewer must *not* check, so it has nothing to
run.

**The value** is a path resolved from the repository root, and the oracle lives **outside**
`canonical/`, so it never enters the render chain.

**Coverage is per FILE, not per criterion.** An oracle reports a verdict for each file it
examined and, separately, the files it could not decide. It never collapses the whole
criterion to one word — otherwise a single undecidable file would make the oracle
indeterminate overall, and it would replace no re-derivation at all.

| Aspect | Contract |
|---|---|
| Invocation | No required arguments, run from the repository root. |
| `stdout` | One line per file worth reporting: `VIOLATION <path> <reason>` or `UNDECIDED <path> <reason>`. A file that passes produces no line. Sorted, so the output is diffable. |
| Exit `0` | No violations **among the files it decided**. `UNDECIDED` lines may be present; they are not a failure. |
| Exit `1` | At least one `VIOLATION` line. `UNDECIDED` lines may appear alongside and are handled as at exit 0. |
| Exit `2` | The oracle could not run at all — its own inputs are missing or malformed. Whole-criterion degradation, and the rare case. |
| Any other exit | Treated as exit 2. "I could not tell" is never recorded as "the criterion holds". |
| Exit `1` with no `VIOLATION` line | **Malformed.** Treated as exit 2 and reported as degradation, never as a finding: a violation nobody can cite is not usable evidence. |
| Runtime bound | Invoked under a **60-second timeout**. Exceeding it is treated as exit 2 and reported. Non-termination is the fourth way to fail, alongside missing, non-executable and crashing. |
| Determinism | Same tree in, same stdout and exit out. No network, no clock, no `$RANDOM`, no unordered traversal — enumeration sorted under a fixed locale. |
| Language | Bash + awk, so the core path needs neither node nor python. |

**How a partial verdict is consumed.** The reviewer takes the decided files as settled and
judges only the `UNDECIDED` remainder by reading. That is what makes a partial oracle worth
having: the replacement it provides is proportional to the files it decides, and the counts
are on stdout, so "what recurring work does this remove" has a number behind it.

**A degraded oracle degrades the whole criterion to reading, and says so.** Missing,
non-executable, crashing, timed out, or malformed — the reviewer judges by reading and
records that the degradation happened. It never silently passes and never silently fails.

**Three levels, resolved as a union; most specific wins.** Criteria are declared **global**
(project-wide) and **per document type** in the project's own conventions KB doc
(`.aid/knowledge/authoring-conventions.md`), and **per file** in this frontmatter field. A
criterion is written **once, at the highest level where it is true** — so most files declare
nothing and are fully covered by their type. An **override** is not a separate shape: a
file-level entry reusing an `id` from a higher level, with a different `severity` and a
mandatory `why`.

**Declare here only what is true of this file and nothing else.** Restating a global or
type-level criterion is the duplication the cascade exists to prevent, and is itself a finding.

**When in doubt, omit.** A missing field is treated as empty, which is the common and correct
case. `review-criteria: []` is valid and says the same thing more loudly.

### `changelog:` (removed)

**Not a valid field.** Per-doc historical entries are not carried in the document at all
-- git records every revision with its author, date, and diff. A `changelog:` block also
became the main route by which transient work references leaked into the KB (see
[principles.md](principles.md) P1(e)), so it is removed rather than merely discouraged.
Delete the field where it still appears; do not author a new one.

**Exempt from review** where it still exists: the block is being removed, not maintained, so
its content is not graded. Deleting it is always correct; adding to it never is.

## `owner:` / `audience:` — enum vs free string (decision + justification)

Both `owner:` and `audience:` are **free strings**, not closed enums. Rationale,
grounded in REQUIREMENTS §1.3 / §3.2: the audience roster is explicitly open-ended
("junior dev, non-tech PM, senior architect, UX designer…") and §1.3 makes
audience/ownership a per-project dimension that a fixed enum would re-introduce the
rejected "project-type catalog" rigidity for. A closed enum would also force every
adopter onto AID's role names. The lint therefore checks *shape* (present → non-empty
scalar / list of short strings), not *membership*. A project that wants a controlled
vocabulary can add it via the existing `.aid/knowledge/.review-checklist.md` override
hook (already documented in this schema and in `review-rubric.md`).

## P6 carve-out — required new fields are lint-graded

The `objective:`, `summary:`, and `sources:` fields are **carved out** of the P6
"frontmatter exempt from review" exemption. For any `source: hand-authored` doc with
`kb-category:` in `{primary, extension}` that already carries any of the new fields,
the lint (`lint-frontmatter.sh`) checks:

- **Presence:** `objective:` and `summary:` are non-empty; `sources:` is present as a
  YAML list (possibly `[]`). Missing → `[FM-MISSING]` (HIGH).
- **Shape:** `objective:`/`summary:` are single-line scalars; `sources:`/`tags:`/
  `see_also:`/`audience:` (when present) are lists; each `sources:` entry matches a
  path/glob/URL shape; `approved_at_commit:` (when present) is 7-40 lowercase hex.
  Violations → `[FM-INVALID]` (HIGH).

**These are the EXISTING rubric tags** — no new tag is introduced. `[FM-INVALID]`'s
"invalid value" semantics already cover shape errors.

The legacy fields (`intent:`, `changelog:`) and all optional new fields (`tags:`,
`see_also:`, `owner:`, `audience:`) **stay fully exempt** from content grading. Prose
quality of `objective:`/`summary:` also stays exempt (no reviewer judgment on prose) —
only presence and mechanical shape are checked.

**`review-criteria:` is the exception, and is graded content.** It was in the exempt list
under its old name `contracts:`, and that exemption is withdrawn — a field whose entire
purpose is to state what a reviewer must check cannot itself be the one thing the reviewer
may not read. Its entries are graded like any other claim the file makes:

- an entry that does not hold against disk is a finding at that entry's own `severity`;
- an entry restating a global or type-level criterion is a finding (the duplication FR-5's
  cascade exists to prevent);
- a `kind: exclude` entry with no `why`, or a `kind: validate` entry with no `severity`, is
  a schema error.

An **unknown** key on an entry is none of the above — it is tolerated (see
[Parsing rules](#parsing-rules-for-tools)) and simply not graded, because there is nothing yet
to grade it against.

The exemption that remains is narrower and mechanical: **the field's presence is never
required.** A file whose type already covers it correctly declares nothing, so absence is
never a finding — only a wrong or redundant declaration is.

**Day-one soft-skip:** docs carrying NONE of the new fields are treated as
pre-migration and skipped by the lint. The lint becomes a hard gate after f011 migrates
AID's own docs. See [principles.md](principles.md) P6 for the full carve-out spec.

## `intent:` coexistence / migration note

During the coexistence window (between f001 and f011):

- `intent:` remains valid in all docs; the lint does NOT enforce its removal
- `build-kb-index.sh` falls back `objective:` → `intent:` for un-migrated docs so the
  INDEX stays valid and CI stays green
- New docs authored after f001 SHOULD use `objective:` + `summary:` and may omit
  `intent:`
- The f011 migration moves `intent:` content into `objective:`/`summary:` and retires
  the field

`approved_at_commit:` is absent on all docs until the first approval post-migration;
absence is never a lint failure (degrade-gracefully per NFR-7).

## Rendering compatibility

YAML frontmatter between `---` markers is the standard convention used by:
- GitHub Markdown (renders as a table at the top of the file)
- Jekyll / Hugo / mdBook
- VS Code Markdown preview
- All major static site generators

Most renderers display the frontmatter; some hide it. Either is acceptable. The
`kb.html` viewer (rendered by `aid-summarize`) extracts `objective:`/`summary:` (falling
back to `intent:` during the coexistence window) for section descriptions and skips
the rest.

## Parsing rules (for tools)

- Block MUST be the first content in the file (no whitespace, no BOM, no comments before)
- Opening `---` on its own line; closing `---` on its own line
- Body MUST be valid YAML 1.2
- Missing fields are treated as default-empty
- Unknown fields are tolerated (forward-compatible with future schema additions)
- **The same tolerance applies one level down, inside a list entry.** An unknown key on a
  `review-criteria:` entry — alongside `id`, `kind`, `criterion`, `severity`, `why` — is
  tolerated, not a schema error, so a later key can be added to a criterion as a pure
  addition rather than a migration across every criterion already declared. This does not
  weaken the required keys: an entry still needs `id`, `kind` and `criterion`, `severity` on
  a `validate`, and `why` always. Tolerating an extra key and omitting a required one are
  different things.
- If parsing fails, the doc is treated as `kb-category: primary, source: hand-authored`
  with empty objective/summary/intent/review-criteria/changelog AND lint emits a HIGH-severity warning

## Project-specific overrides

A project may define `.aid/knowledge/.review-checklist.md` (gitignored by default)
to add project-specific lint rules beyond the canonical defaults. See
[review-rubric.md](review-rubric.md) for the format.

## Doc layout convention

The frontmatter block is always **Position 1** in the required doc layout:

| Position | Section |
|----------|---------|
| 1 | Frontmatter (this block) |
| 2 | Title heading |
| 3 | Index / table of contents |
| 4 | Content sections |

See [principles.md](principles.md) P10 for the full layout specification. The Anatomy
mandate checks this order: frontmatter first, index present. There is no change-log
section -- per-doc history lives in git.

## See also

- [principles.md](principles.md) — P6 (frontmatter carve-out + partial exemption), P5 (mark generated files), P10 (dual-audience authoring standard + layout)
- [tier-model.md](tier-model.md) — T2 structural facts are declared as `review-criteria:` entries
- [review-rubric.md](review-rubric.md) — how the reviewer uses kb-category + source to pick a rubric; how it resolves the three criteria levels; `[FM-MISSING]` / `[FM-INVALID]` tag definitions
