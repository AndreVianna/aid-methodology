# task-003 Findings — Catalog Screening: Classes KB and EXE

**Corpus:** 16 KB rows + 13 EXE rows = 29 rows total  
**Source:** `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` and `git show 8b9e62021:canonical/aid/templates/review-rubrics/executable.md`  
**Current criteria namespace:** G-01..G-08, KB-01..KB-04, SK-01, SK-02, SR-01, AG-01, TO-01, TP-01 (18 ids)  
**Next free:** G-09 / KB-05 (per RECORD.md ledger)

---

## Verification Commands

```
$ git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
16

$ git show 8b9e62021:canonical/aid/templates/review-rubrics/executable.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
13
```

Both counts reproduce. Total corpus: 29 rows.

---

## Four-Condition Screen — Reference

For each row, the four conditions are:

1. **Uncovered** — no current criterion already covers this check  
2. **Declarable** — can be stated as a criterion sentence a reviewer checks, not a procedure  
3. **Attachable** — attaches to an existing registry type or to `*`; a new type would be out of scope  
4. **Priceable** — can carry a severity with a one-line why naming the consequence  

Outcome is exactly one of:  
`admit` · `covered by <id>` · `rubric-owned` · `needs a new type — out of scope`

---

## Current Criteria Referenced in This Screen

Extracted from `.aid/knowledge/authoring-conventions.md § Review Criteria — Criteria by Level`:

- **G-01** — No cosmetic count unless load-bearing and measured from disk  
- **G-02** — Every citation is a durable anchor, never a bare `file.ext:LINE`  
- **G-03** — Resolved tracked item leaves no trace  
- **G-07** — Every in-scope markdown file resolves to exactly one type  
- **G-08** — No superseded frontmatter field survives (`intent:` replaced; `changelog:` not valid)  
- **KB-01** — Required frontmatter present and single-line: `objective`, `summary`, `sources`  
- **KB-02** — Exactly one concern per doc, and the layout holds: frontmatter, title, index, content sections, and no history section  
- **KB-03** — Content not graded (`kb-generated` exclude)  
- **KB-04** — Only top-level fields checked (`kb-meta` spot-check)  

---

## Per-Row Screening Table — KB Class (16 rows)

Source: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md`

### Authoring-Standard Rules (KB-01..KB-09)

| Catalog Row | Check (in brief) | Outcome | Evidence | Proposed ID | Severity | Why |
|---|---|---|---|---|---|---|
| `KB-01` | Frontmatter is the document's first block, before any content | covered by **KB-02** | Current KB-02 "the layout holds: frontmatter, title, index, content sections, and no history section" — "layout holds" entails frontmatter is first, per the KB Document Layout table in authoring-conventions.md | — | — | — |
| `KB-02` | A `## Contents` index is present near the top, for a document with more than three sections | covered by **KB-02** | Current KB-02 "layout holds" subsumes the index requirement; authoring-conventions.md KB Document Layout table row 3 states "required when the doc has more than 3 sections", which is the same condition | — | — | — |
| `KB-03` | The doc carries no history apparatus — no `## Change Log`, no `## Revision History`, no `changelog:` frontmatter field | covered by **KB-02, G-08** | Current KB-02 "no history section" covers the section headings; current G-08 "`changelog:` is not a valid field at all" covers the frontmatter field. Together they cover the full catalog check | — | — | — |
| `KB-04` | The core frontmatter fields are present: `objective:`, `summary:`, `sources:` | covered by **KB-01** | Current KB-01: "Required frontmatter is present and single-line: `objective`, `summary`, `sources`" — exact match | — | — | — |
| `KB-05` | The classification fields are present: `audience:`, `owner:`, `tags:` | **admit** | No current criterion checks for `audience:`, `owner:`, or `tags:` presence. Current KB-01 covers only `objective`, `summary`, `sources`. Authoring-conventions.md § Frontmatter Rules documents these as optional fields with a MUST-by-convention note in `tags:` prose, but no criterion enforces them. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-05 | **KB-05** | `[LOW]; escaped (>1 doc) → [MEDIUM]` | missing classification fields prevent concern-routing and audience-targeting; widespread absence degrades KB navigability |
| `KB-06` | `tags:` carries a concern ID mapping the document to a spine dimension | **admit** | No current criterion checks `tags:` for a concern id token. Authoring-conventions.md § Frontmatter Rules says `tags:` "MUST include the concern/dimension id… by convention", but no criterion id is assigned to enforce it, so a reviewer cannot cite a violation. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-06 | **KB-06** | `[LOW]; escaped (>1 doc) → [MEDIUM]` | a doc without a concern id cannot be verified to cover exactly one spine dimension, making the concern-model mapping untestable |
| `KB-07` | The body carries no diagram blocks — no Mermaid, no ER diagram, no ASCII art | **admit** | No current criterion checks for diagram presence. Authoring-conventions.md § Dual-Audience Standard bans diagrams from KB `.md` docs ("No diagrams (Mermaid/SVG/ASCII art) in KB .md docs") in prose guidance, but no criterion id exists to let a reviewer cite a violation. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-07. Attachment options: `kb-doc` or `*`. Recommend **`kb-doc`** — the no-diagram rule is stated specifically for KB `.md` docs; skill and template files are not covered by the same prose, so `*` would over-scope | **KB-07** | `[LOW]; escaped (>1 doc) → [MEDIUM]` | diagrams degrade in plain-text reading and cannot be grepped, harming the AI-agent half of the dual audience |
| `KB-08` | Prose is plain and concrete enough for a junior professional to follow | **admit** | No current criterion checks prose readability. Authoring-conventions.md § Dual-Audience Standard says "Junior-clear language. Plain words, active voice, short sentences", but no criterion id exists. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-08. Attachment options: `kb-doc` or `*`. Recommend **`kb-doc`** — the dual-audience standard is declared specifically for KB docs; skill reference and template files are procedure bodies, not knowledge docs, so the junior-readability expectation differs | **KB-08** | `[LOW]; escaped (>1 doc) → [MEDIUM]` | prose inaccessible to a junior reader fails the dual-audience standard and degrades KB utility for its human audience |
| `KB-09` | The document answers exactly one concern question, without material from an orthogonal concern | covered by **KB-02** | Current KB-02: "Exactly one concern per doc" — exact match on the one-concern requirement; the catalog's judgment guidance ("Name any section whose subject is another concern doc's declared question") is evidence method, not a separate criterion | — | — | — |

### Insufficiency Rules (KB-20..KB-26)

| Catalog Row | Check (in brief) | Outcome | Evidence | Proposed ID | Severity | Why |
|---|---|---|---|---|---|---|
| `KB-20` | No two KB statements conflict, forcing the agent to choose | **admit** | No current criterion covers intra-KB or cross-KB contradiction. The universal defect taxonomy in `git show 8b9e62021:canonical/aid/templates/review-rubrics/INDEX.md` lists "Contradiction" as a class but does not assign it a criterion id under the KB class. The current authoring-conventions.md criteria table has no id covering this. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-20. Attachment options: `kb-doc` or `*`. Recommend **`kb-doc`** — while contradictions matter in all artifact types, the "forcing the agent to choose" insufficiency is specific to the KB-as-planning-authority role; other artifact types (skills, templates) carry different contradiction consequences and would be covered under their own types once added | **KB-09** | HIGH | a contradiction forces different agents to choose differently, producing silent non-reproducible plan failures |
| `KB-21` | A correct plan is assemblable from the KB, and is right for this project | **admit** | No current criterion covers KB completeness as a planning resource. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-21. Declarable as: "All information needed to assemble a correct task plan is present in the KB doc without gaps requiring inference or reaching to source". This is a judgment criterion with a named evidence method (name the plan step lacking a KB anchor). Attachable to `kb-doc`. | **KB-10** | MEDIUM | if assembling a correct plan requires information not present in the KB, the KB is incomplete for its declared purpose of enabling agent action |
| `KB-22` | Structural shape is stated, so the agent need not reach for the source | **admit** | No current criterion enforces inline contract declaration. Authoring-conventions.md § Signature Exception declares this as policy prose ("A load-bearing operational contract… MUST be stated inline or behind a precise grep-recoverable anchor"), but no criterion id exists. G-02 (durable citations) does not cover this — it addresses citation format, not contract completeness. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-22. Attachment options: `kb-doc` or `*`. Recommend **`kb-doc`** — the Signature Exception is declared in the KB-authoring section of authoring-conventions.md and addresses KB docs specifically | **KB-11** | `[HIGH]` | an agent that must reach outside the KB to infer a contract violates the assertiveness gate and may infer incorrectly |
| `KB-23` | A rule that must hold is stated, rather than guessed | **admit** | No current criterion explicitly requires that invariants be stated in KB docs. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-23. Declarable and attachable to `kb-doc`. | **KB-12** | `[HIGH]` | an agent that guesses an unstated invariant and guesses wrong produces a conformance failure with no KB trail |
| `KB-24` | A non-obvious trap is warned about | **admit** | No current criterion requires gotcha documentation. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-24. Declarable as a judgment criterion (the reviewer names the trap and what it would cost). Attachable to `kb-doc`. | **KB-13** | `[HIGH]` | a trap the KB does not warn about is encountered by every agent that passes through the relevant subsystem |
| `KB-25` | The project's quality contract is conveyed | **admit** | No current criterion requires the quality bar (grades, gates, required checks) to be stated in KB docs. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-25. Declarable and attachable to `kb-doc`. | **KB-14** | `[HIGH]` | an unstated quality bar cannot be enforced by an agent assembling a plan; it also cannot be checked by a reviewer who has no stated standard to measure against |
| `KB-26` | A naming, path or style convention is stated, rather than assumed | **admit** | No current criterion requires that conventions be explicitly stated rather than assumed. Evidence: `git show 8b9e62021:canonical/aid/templates/review-rubrics/kb.md` row KB-26. Declarable and attachable to `kb-doc`. This is the only SHOULD among the insufficiency rules (catalog-assigned). | **KB-15** | `[LOW]; escaped (>1 doc) → [MEDIUM]` | an agent that must invent a missing convention invents inconsistently across runs, producing divergent outputs |

---

## Per-Row Screening Table — EXE Class (13 rows)

Source: `git show 8b9e62021:canonical/aid/templates/review-rubrics/executable.md`

**Ruling applies to all 13 rows:** Every EXE row targets the Executable family: CODE, TEST, CONFIG, INFRA, JOB, PIPELINE, MIGRATION (`git show 8b9e62021:canonical/aid/templates/review-rubrics/executable.md` header). None of these artifact types appear in the current type registry in `.aid/knowledge/authoring-conventions.md § Review Criteria — Type Registry`. The registry's ten types are: `state`, `kb-generated`, `kb-meta`, `kb-doc`, `skill-generated`, `skill-authored`, `skill-reference`, `agent`, `template-payload`, `template-own`.

Attaching any EXE row to `*` (global) would apply CODE/TEST/INFRA-specific checks to KB docs, skill files, and templates — which is incorrect scope. Attaching to an existing type (e.g. `skill-reference`) would mis-scope the check. The correct target types (CODE, TEST, etc.) would need to be added to the registry, which is a new-type addition and is out of scope for this task.

| Catalog Row | Check (in brief) | Outcome | Evidence |
|---|---|---|---|
| `EXE-01` | The project builds (declared build command exits 0) | **needs a new type — out of scope** | Applies to CODE artifacts; `CODE` type absent from current registry (`git show 8b9e62021:canonical/aid/templates/review-rubrics/executable.md` row EXE-01). Attaching to `*` would require this of KB docs, which is incorrect |
| `EXE-02` | Declared linters pass | **needs a new type — out of scope** | Same as EXE-01 — CODE/TEST family; no matching type in current registry |
| `EXE-03` | Declared test suites pass | **needs a new type — out of scope** | Same — CODE/TEST family; no matching type |
| `EXE-04` | New behaviour is covered by a test at the declared level | **needs a new type — out of scope** | Applies to CODE and TEST artifacts; both absent from current registry |
| `EXE-05` | A script's exit codes follow the project's declared alphabet | **needs a new type — out of scope** | Applies to CODE (scripts); `CODE` type absent. Attaching to `*` would assert exit-code conventions on KB docs and templates, which do not have exit codes |
| `EXE-06` | Output goes to the declared stream (results stdout, diagnostics stderr) | **needs a new type — out of scope** | Same — CODE family only; no matching type |
| `EXE-07` | Errors are handled as declared, not swallowed | **needs a new type — out of scope** | Same — CODE family; no matching type |
| `EXE-08` | Names follow the declared conventions | **needs a new type — out of scope** | Naming conventions differ by artifact type; the EXE row cites `coding-standards.md § Naming Conventions` which applies to source identifiers, not KB doc headings or skill names. Attaching to `*` would conflate two unrelated convention scopes |
| `EXE-09` | A script carries the declared file header | **needs a new type — out of scope** | Applies to CODE (scripts); `CODE` type absent. Attaching to `*` would require a shell file header on KB docs |
| `EXE-10` | Language-specific conventions followed for the file's language | **needs a new type — out of scope** | Applies to CODE/TEST per language; no matching type. The catalog row itself names an explicit no-criterion escape ("a file in a language the KB does not cover is a criteria gap") — this criterion is parameterized by registry type and only fires per-language inside the CODE family |
| `EXE-11` | Configuration is read through the declared access path, not re-implemented | **needs a new type — out of scope** | Applies to CODE; CONFIG type also absent. Attaching to `*` would produce false positives on KB docs that reference config values |
| `EXE-12` | Security conventions honoured — no secret in source, no unsafe execution of untrusted input | **needs a new type — out of scope** | The security check bundles two concerns: a broad one (no secrets in source) that could in principle attach to `*`, and a code-specific one (unsafe execution of untrusted input). Splitting the catalog row to extract the secrets-in-source sub-check would be creating a new criterion, not screening the catalog row — which is out of scope here. The full row as written requires a CODE type |
| `EXE-13` | A load-bearing architectural boundary is not crossed | **needs a new type — out of scope** | Applies to CODE/INFRA; both absent from current registry. The catalog row itself includes an explicit no-criterion escape for boundaries the KB does not declare |

---

## Summary

| Outcome | Count |
|---|---|
| `covered by <current-id>` | **5** |
| `admit` | **11** |
| `rubric-owned` | **0** |
| `needs a new type — out of scope` | **13** |
| **Total** | **29** |

### Covered rows (5)

| Catalog Row | Covered by |
|---|---|
| `KB-01` | `KB-02` (layout holds — frontmatter is first) |
| `KB-02` | `KB-02` (layout holds — index required when >3 sections) |
| `KB-03` | `KB-02` (no history section) + `G-08` (changelog: not a valid field) |
| `KB-04` | `KB-01` (objective, summary, sources required) |
| `KB-09` | `KB-02` (exactly one concern per doc) |

### Admitted rows with proposed IDs (11)

All proposed IDs use the `KB` prefix (next free: KB-05). No admitted row warrants a `G` prefix — all checks apply specifically to KB docs (`kb-doc` type), not globally.

| Catalog Row | Proposed ID | Applies to | Severity | One-line why |
|---|---|---|---|---|
| `KB-05` | **KB-05** | `kb-doc` | `[LOW]; escaped (>1 doc) → [MEDIUM]` | missing `audience:`, `owner:`, `tags:` prevents concern-routing and dual-audience identification |
| `KB-06` | **KB-06** | `kb-doc` | `[LOW]; escaped (>1 doc) → [MEDIUM]` | a doc without a concern id in `tags:` cannot be verified to own exactly one spine dimension |
| `KB-07` | **KB-07** | `kb-doc` | `[LOW]; escaped (>1 doc) → [MEDIUM]` | diagrams degrade in plain-text reading and cannot be grepped, harming the AI-agent half of the dual audience |
| `KB-08` | **KB-08** | `kb-doc` | `[LOW]; escaped (>1 doc) → [MEDIUM]` | jargon-dense prose fails the dual-audience standard and reduces KB utility for the junior-human half |
| `KB-20` | **KB-09** | `kb-doc` | HIGH | a contradiction forces agents to choose silently, producing non-reproducible plan failures |
| `KB-21` | **KB-10** | `kb-doc` | MEDIUM | a KB that cannot source every plan step is incomplete for its declared purpose of enabling agent action |
| `KB-22` | **KB-11** | `kb-doc` | `[HIGH]` | an agent that must reach outside the KB to infer a contract may infer incorrectly with no KB trail |
| `KB-23` | **KB-12** | `kb-doc` | `[HIGH]` | an agent that guesses an unstated invariant and is wrong produces a conformance failure with no KB trail |
| `KB-24` | **KB-13** | `kb-doc` | `[HIGH]` | a trap the KB does not warn about is encountered by every agent traversing the relevant subsystem |
| `KB-25` | **KB-14** | `kb-doc` | `[HIGH]` | an unstated quality bar cannot be enforced by an agent and cannot be checked by a reviewer |
| `KB-26` | **KB-15** | `kb-doc` | `[LOW]; escaped (>1 doc) → [MEDIUM]` | an agent that must invent a missing convention invents inconsistently across runs |

### Out-of-scope rows (13)

All 13 EXE rows — the entire Executable family rule set. The blocking condition in every case is the absence of CODE, TEST, CONFIG, INFRA, JOB, PIPELINE, and MIGRATION types from the current type registry. Adding any of these would be a new-type addition, which is out of scope for this screen.

---

## Items That Could Not Be Fully Decided

**None.** Every row yielded a clear outcome. Two notes recorded for transparency:

**EXE-12 partial ambiguity:** The "no secret in source" sub-concern within EXE-12 could in principle be expressed as a global criterion (no hard-coded credential in any in-scope file). However, extracting it from EXE-12 would create a new criterion by decomposing a catalog row — that is beyond the scope of a screening task. The full row as written requires a CODE type and is recorded as `needs a new type — out of scope`.

**KB-20 (proposed KB-09) attachment recommendation:** Both `kb-doc` and `*` were considered. `*` was rejected because: (a) the "forcing the agent to choose from the KB" framing is specific to the KB's role as the planning authority; (b) contradiction consequences differ by artifact type (a contradiction in a SPEC document is covered under the Definition family's rules, not here); (c) the criterion would need restating to be meaningful at `*` scope, which changes the criterion rather than migrates it.

---

## Conflicts Between Current Criteria and Catalog Rows

**None found.** The catalog note on KB-03 records a historical inversion ("KB-03 previously required `## Change Log` as the last section; master retired KB history apparatus entirely at `97d09b1a`"). The CURRENT state of authoring-conventions.md already reflects the ban — its KB Document Layout table has no history-section row, and it states "There is no history section." No conflict exists between the catalog's KB-03 and the current criteria.

All other catalog rows either add new checks not present in the current criteria, or duplicate existing ones with compatible semantics.

---

## Correction — the two unpriced severities

The proposal table carried `Step 2` in the severity cell for `KB-20` and `KB-21`. That is not a
severity: it is the abandoned catalog's own deferral placeholder, meaning "decide this in the
catalog's second step". Carried across it would have handed task-006 two rows with no price, and
a criterion without a severity cannot be graded against.

Both are now priced on the five-band scale, with the consequence named:

- **`KB-09` (from `KB-20`, no contradictions) — HIGH.** Two conflicting KB statements make an agent
  choose silently, and the choice is invisible in the output, so the failure reproduces differently
  each run. That is worse than a missing statement, which at least stops the agent.
- **`KB-10` (from `KB-21`, a plan is assemblable) — MEDIUM.** An incomplete KB makes the agent guess
  a step, which is a real defect, but the gap shows at planning time rather than being silently
  wrong at execution time.

**A correction to this correction.** The first fix changed only the summary table and left the
per-row table untouched, on the belief that its remaining `Step 2` cells were evidence-column
citations. They were not: parsing the row shows cell 6 is the Severity column, so the per-row
table was still carrying the placeholder as a price. Both cells are now HIGH and MEDIUM, matching
the summary table. The lesson is the one this delivery keeps re-learning -- a claim about which
column a value sits in has to be parsed, not eyeballed, because a wide row makes the two look
identical in a terminal.
