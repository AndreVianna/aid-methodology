# Catalog Screening Findings — Classes SUMMARY, DEF, AID, PRO

**Task:** task-005 — Catalog screening, classes SUMMARY (9), DEF (9), AID (6), PRO (5)
**Corpus commit:** `8b9e62021` (abandoned rubric branch)
**Current namespace baseline:** 18 ids — `G-01..G-08`, `KB-01..KB-04`, `SK-01`, `SK-02`, `SR-01`, `AG-01`, `TO-01`, `TP-01`

---

## Row-count verification

All counts are reproduced below. The grep anchors on the Rule-cell prefix so it cannot match
prose that happens to contain a matching token.

```
$ cd /workspace/.claude/worktrees/work-013-review-stack-completion

$ git show 8b9e62021:canonical/aid/templates/review-rubrics/summary.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
9

$ git show 8b9e62021:canonical/aid/templates/review-rubrics/definition.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
9

$ git show 8b9e62021:canonical/aid/templates/review-rubrics/aid.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
6

$ git show 8b9e62021:canonical/aid/templates/review-rubrics/process.md \
    | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
5
```

**Total: 29 rows.** All 29 appear in the per-row table below.

Current-namespace verification:

```
$ awk -F'|' '/^\| ID \| Applies to/,/^$/ {gsub(/ /,"",$2); if ($2 ~ /^[A-Z]+-[0-9]{2}$/) print $2}' \
    .aid/knowledge/authoring-conventions.md
G-01  G-02  G-03  G-04  G-05  G-06  G-07  G-08
KB-01 KB-02 KB-03 KB-04
SK-01 SK-02
SR-01
AG-01
TO-01
TP-01
```

18 ids confirmed. Next-free per prefix from `RECORD.md`: G-09, KB-05, SK-03, SR-02, AG-02, TO-02, TP-02.

---

## Scoping context

The type registry in `.aid/knowledge/authoring-conventions.md § Review Criteria — Type Registry`
covers the **in-scope corpus**: markdown under `canonical/skills/`, `canonical/agents/`,
`canonical/aid/templates/`, and `.aid/knowledge/`. The registered types are: `state`, `kb-generated`,
`kb-meta`, `kb-doc`, `skill-generated`, `skill-authored`, `skill-reference`, `agent`,
`template-payload`, `template-own`.

**No type covers `kb.html`** (it is `.html`, not `.md`). No type covers work-pipeline artifacts
(`REQUIREMENTS.md`, `SPEC.md`, `PLAN.md`, `DETAIL.md` under `.aid/works/`). No type covers
process artifacts (`TICKET`, `RELEASE`, `SPIKE`, `PROTOTYPE`). These are the three gaps that drive
the majority of "needs a new type" outcomes below.

---

## Per-row screening table

Four conditions evaluated for each row:

1. **Uncovered** — no current criterion (the 18 ids) and no agent-body check already covers it.
2. **Declarable** — expressible as a positive criterion sentence, not a procedure.
3. **Attachable** — attaches to an existing registry type or to `*`. A new type is out of scope.
4. **Priceable** — carries a severity with a one-line why naming the consequence.

`Cov?` = answer to condition 1 (U = uncovered, P = partially covered, C = covered).

| Row | Check (condensed) | Cov? | Declarable? | Attachable? | Priceable? | Outcome | Evidence |
|---|---|---|---|---|---|---|---|
| `SUMMARY-01` | Every doc-set document is represented in the summary | U | Yes | No — `kb.html` has no registry type; `*` would need it to be .md | — | needs a new type — out of scope | `git show 8b9e62021:canonical/aid/templates/review-rubrics/summary.md` row 1; `.aid/knowledge/authoring-conventions.md § Review Criteria — Type Registry` (no html type) |
| `SUMMARY-02` | Summary markup is valid | U | Yes | No — same: kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-03` | Summary is self-contained, no external fetch | U | Yes | No — kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-04` | No claim contradicts the KB it summarises | U | Yes | No — specific to kb.html relationship to KB; kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-05` | Every load-bearing claim is grounded in a KB doc | U | Yes | No — kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-06` | Every visual renders and is legible | U | Yes | No — kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-07` | Summary carries no retired diagram runtime | U | Yes | No — kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-08` | Every in-page anchor resolves | U | Yes | No — specific to HTML `href="#X"` anchors; kb.html has no type | — | needs a new type — out of scope | same sources |
| `SUMMARY-09` | Every relative document link points at a file that exists | U | Yes | No — kb.html has no type; if reframed for .md it would duplicate DEF-06 / G-09 territory | — | needs a new type — out of scope | same sources; DEF-06 row covers link resolution for in-scope .md files |
| `DEF-01` | Every requirement and feature AC carries explicit modality | U | Yes | No — REQUIREMENTS.md, SPEC.md have no registry type | — | needs a new type — out of scope | `git show 8b9e62021:canonical/aid/templates/review-rubrics/definition.md` row 1; authoring-conventions.md type registry |
| `DEF-02` | Every AC is decidable | U | Yes | No — same: definition artifacts have no type | — | needs a new type — out of scope | definition.md row 2 |
| `DEF-03` | Every requirement traces upstream; every spec section traces to a requirement | U | Yes | No — same | — | needs a new type — out of scope | definition.md row 3 |
| `DEF-04` | Artifact does not contradict what it derives from, nor itself | U | Yes | No — "derives from" is a definition-artifact relationship; no type exists; would not apply meaningfully at `*` (in-scope files do not formally derive from other artifacts in the pipeline sense) | — | needs a new type — out of scope | definition.md row 4 |
| `DEF-05` | Every mandated section of the governing schema is present | U | Yes | No — check cites artifact-schemas.md § REQUIREMENTS.md / SPEC.md / DETAIL.md; no type for these | — | needs a new type — out of scope | definition.md row 5 |
| `DEF-06` | Every cited path, anchor and identifier resolves | U | Yes | Yes — `*`: declaring criterion is `authoring-conventions.md § Citation Rule (Durable Anchors)`, a global section; G-02 checks citation FORM (durable anchor shape) but not RESOLUTION; SR-01 checks instruction-content pointers only for `skill-reference` + `template-own`; the gap — resolution for all in-scope file types — is real and uncovered | Yes — MEDIUM (one broken citation is confined; correction is local) | **admit** | definition.md row 6; authoring-conventions.md § Citation Rule; G-02 text ("durable anchor… never a bare file.ext:LINE" — form only); SR-01 scope (`skill-reference, template-own` only); oracle `canonical/aid/scripts/kb/kb-citation-lint.sh` exists on current tree |
| `DEF-07` | Artifact carries no drift-prone content (no value that will silently go stale) | P | Yes | Yes, at `*` — as a `*` criterion this row subsumes G-01 (cosmetic counts) and G-02 (positional citations) while adding dates/clutter; admitting it duplicates two existing criteria; for definition artifacts, no type exists | — | rubric-owned | G-01 text ("No cosmetic count…"); G-02 text ("Every citation is a durable anchor…"); definition.md row 7; authoring-conventions.md § Drift-Prone Content is Banned (4 classes listed; 2 of the 4 are already declared in G-01/G-02; dates-without-semantic-anchor gap is real but requires a separate narrower row, not this one) |
| `DEF-08` | Every gate criterion of the governing BLUEPRINT.md is discharged by at least one task | U | Yes | No — specific to BLUEPRINT/TASK delivery structure; no type for BLUEPRINT or DETAIL.md exists | — | needs a new type — out of scope | definition.md row 8 |
| `DEF-09` | Every factual claim the artifact makes about the repository holds on disk | U | Yes | No as-written — this row's declaring criterion (`authoring-conventions.md § Citation Rule`) addresses form/resolution, not claim truth; DEF-09 itself states "A claim whose identifiers all resolve can still be false — resolution is DEF-06, truth is this rule," meaning truth is a separate check without a named declaring anchor in authoring-conventions.md; for definition artifacts, no type exists | — | needs a new type — out of scope | definition.md row 9 ("resolution is DEF-06, truth is this rule"); authoring-conventions.md § Citation Rule text (about durable-anchor form, not truth of claims); note: the factual-claim gap for `kb-doc` is real but DEF-09's criterion cell does not ground it cleanly enough for a `kb-doc` admission without a new authoring-conventions.md anchor |
| `AID-01` | Every AID-own dir is nested under an `aid/` subtree | C | — | — | — | **admit** | `canonical/agents/aid-reviewer/AGENT.md § Standing KB-Convention Checks §§ Content isolation` lines 119–122: "AID-own dirs (scripts/, templates/) live under <assets-root>/aid/; flag any AID-own dir emitted at the un-nested path" |
| `AID-02` | Every AID file inside a tool-native dir carries the `aid-` prefix | C | — | — | — | **admit** | same section: "AID files inside tool-native dirs (agents/, skills/, rules/) carry the aid- prefix; flag any un-prefixed AID file inside a tool-native dir" |
| `AID-03` | No new AID content at the `.github` root | C | — | — | — | **admit** | same section: "Any new AID content placed at the .github root level (copilot-cli scoping violation — R1)" |
| `AID-04` | No AID-own content at `.codex/` root outside `.codex/aid/` | C | — | — | — | **admit** | same section: "Any AID-own content placed at the .codex/ root level but NOT nested under aid/ (R6 revised — .codex/aid/ is the correct AID-own location)" |
| `AID-05` | Orphan pruning uses manifest membership, not diff or directory alone | C | — | — | — | rubric-owned | same section: "Any prune logic that diffs old-manifest instead of using aid- prefix + new-manifest membership as the prune basis" |
| `AID-06` | Root-agent updates perform in-place region replacement — no `.aid-new` sidecar | C | — | — | — | rubric-owned | same section: "Any root-agent update that writes a .aid-new sidecar instead of performing an in-place region update between <!-- AID:BEGIN --> / <!-- AID:END --> markers" |
| `PRO-01` | Scope is stated (in-scope and out-of-scope) | U | Yes | No — TICKET / RELEASE / SPIKE / PROTOTYPE have no registry type | — | needs a new type — out of scope | `git show 8b9e62021:canonical/aid/templates/review-rubrics/process.md` row 1; authoring-conventions.md type registry |
| `PRO-02` | Exit criteria are stated and decidable | U | Yes | No — same | — | needs a new type — out of scope | process.md row 2 |
| `PRO-03` | Disposability is declared (spike/prototype says it is not production code) | U | Yes | No — same | — | needs a new type — out of scope | process.md row 3 |
| `PRO-04` | A release artifact's version carriers agree | U | Yes | No — RELEASE artifacts have no registry type | — | needs a new type — out of scope | process.md row 4 |
| `PRO-05` | An external tracker reference resolves, where the artifact carries one | U | Yes | No — none of the current in-scope registry types (skills, agents, templates, KB docs) carry `ticket_ref`; the check is specific to process artifacts which have no type | — | needs a new type — out of scope | process.md row 5; authoring-conventions.md type registry (no process or ticket type) |

---

## Proposed admits

### DEF-06 → proposed id: next free in prefix G (G-09)

**Both attachment options considered** (acceptance criterion: state both where either could work):

| Attachment | Scope | Reason |
|---|---|---|
| `*` (global) | Every in-scope file (canonical/, .aid/knowledge/) | G-02 (form) is already at `*`; consistency and completeness favor applying the complementary resolution check at the same level. Citations appear in skill files, agent files, template files and KB docs alike. |
| `kb-doc` | Hand-authored KB docs only | The oracle (`kb-citation-lint.sh`) is already wired for KB docs. Narrower; misses citation resolution in `skill-authored`, `agent`, and `template-own` files. |

**Recommendation: `*`.** G-02 and this check form one logical rule (form + resolution) and should
live at the same scope. Narrowing to `kb-doc` would leave other file types without a resolution
check while still having a form check — an inconsistency visible in one table row.

**Declaring criterion:** `authoring-conventions.md § Citation Rule (Durable Anchors)` — the
same section G-02 cites. G-02 declares the FORM rule (a citation must be a durable anchor);
DEF-06 closes the complementary RESOLUTION rule (a durable-anchor citation must also resolve).
Together they form the complete citation contract.

**Gap evidence:** G-02 text — "Every citation is a durable anchor… never a bare `file.ext:LINE`" —
names the structural requirement but says nothing about whether the target exists. SR-01 covers
instruction-content pointer resolution only for `skill-reference` and `template-own`. No current
criterion checks resolution for citations in `kb-doc`, `agent`, `skill-authored`, `template-own`
(beyond SR-01's subset), or `skill-generated` files.

**Oracle:** `canonical/aid/scripts/kb/kb-citation-lint.sh` — already cited in DEF-06's Evidence
cell and listed in authoring-conventions.md `## Enforcement`.

**Severity:** MEDIUM

**Why:** A broken citation sends a reader or agent to a target that does not exist; correction
is local (one file) but the defect silently misleads until corrected.

**Ordinal note:** Tasks 003 and 004 propose concurrently from the same G namespace. This proposal
claims "next free in prefix G" (currently G-09), not a specific number — task-006 assigns the
actual id after all three tasks' proposals are reconciled.

---

## AID class — recommendation on form

The six AID rows are correctly in the agent body today. The rubric catalog proposed relocating
them from `aid-reviewer/AGENT.md` into declared AID-* ids, which would give violations a citable
criterion id. That relocation is sound in principle but faces one structural obstacle: no `AID`
type exists in the current registry, and the task-instruction language ("a NEW registry type is
out of scope") bars opening one here.

**Recommended end state (not this task's scope):**

- **AID-01..AID-04** (file-placement checks: nested path, `aid-` prefix, `.github` root,
  `.codex/aid/`) are file-content properties — any in-scope file either satisfies isolation or it
  does not. These four could migrate to `*` criteria with proper ids, allowing violations to be
  cited by id in findings ledgers. The severity the rubric assigns (`[HIGH]`) translates directly
  to a table entry.
- **AID-05 and AID-06** (orphan-pruning logic, root-agent region-replacement mechanism) are
  checks against install LOGIC (a script's algorithm), not against a file's content properties.
  They are procedural and cannot be stated as "this file satisfies…" They should remain in the
  agent body, or be expressed as named oracle scripts.

Until a path is opened (either a new `AID` type or a deliberate decision to promote AID-01..AID-04
to `*`), all six remain in the agent body. The current form works; the only cost is that a reviewer
citing one of these cannot write an id-prefixed description — they cite the agent-body section
instead.

---

## Tally

| Outcome | Count | Rows |
|---|---|---|
| admit | 5 | DEF-06; AID-01, AID-02, AID-03, AID-04 |
| covered by `<current-id>` | 0 | — |
| rubric-owned | 3 | DEF-07; AID-05, AID-06 |
| needs a new type — out of scope | 21 | SUMMARY-01..09 (9); DEF-01..05, DEF-08..09 (7); PRO-01..05 (5) |
| **Total** | **29** | all rows accounted for |

---

## Open questions / genuine conflicts

None. Every row resolves to exactly one outcome with evidence. Admitting zero rows would also
have been valid; the one admission (DEF-06) is supported by a clear gap between G-02 (form) and
the missing resolution check.

The dates-without-semantic-anchor gap (DEF-07 residual after G-01/G-02 coverage) is real and
unaddressed by any current criterion, but it needs a new, narrowly-scoped row — not admission of
DEF-07, which would duplicate G-01 and G-02. That row is a separate criteria gap, outside this
task's scope.

---

## Corrections — two outcomes outside the declared set, and a tally that never summed

**The AID rows used a fifth outcome.** The declared set is `admit` / `covered by <current-id>` /
`rubric-owned` / `needs a new type — out of scope`; "covered by the agent body" is none of them.
The observation was right and is kept, now expressed inside the set and split the way this
document's own recommendation already argued:

- **`AID-01`–`AID-04` → `admit`.** File-placement properties, enforced today inside the reviewer
  agent's body — so a violation is caught but cannot be *cited*, because no id exists for a ledger
  row to name. Admitting them at `*` is what turns an uncitable practice into a criterion.
- **`AID-05`–`AID-06` → `rubric-owned`.** They check an algorithm — orphan pruning by manifest
  membership, and in-place region replacement — not a property of a file. A criterion a reviewer
  reads cannot decide them; a script can.

**`DEF-07` was out of scope on the wrong ground.** Its own Attachable cell read "as a `*` criterion
this row subsumes G-01 and G-02", which concedes `*` attachment works. The objection is redundancy,
not attachability, and redundancy is `rubric-owned`.

**And the tally never added up.** The old block summed to 28 against a 29-row corpus: it had no
`admit` line at all, so `DEF-06` — the one row this screen admits, and the document's own headline
finding — appeared in the prose and in no count. The corrected tally is 5 + 0 + 3 + 21 = 29.

A duplicate row is also removed from the tally. The block briefly carried two `admit` lines --
an older bolded one counting `DEF-06` alone, and the corrected one counting all five -- so the
Count cells summed to 30 against a 29-row corpus while the Total said 29. One row, five admits.
