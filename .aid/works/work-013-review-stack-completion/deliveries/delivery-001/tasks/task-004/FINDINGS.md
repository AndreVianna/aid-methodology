# task-004 Findings — Catalog Screening: Classes PRE, NAR, INT

> **Corpus:** `git show 8b9e62021:canonical/aid/templates/review-rubrics/presentation.md` (PRE),
> `git show 8b9e62021:canonical/aid/templates/review-rubrics/narrative.md` (NAR),
> `git show 8b9e62021:canonical/aid/templates/review-rubrics/interface.md` (INT)

---

## Row counts (reproduced)

```bash
git show 8b9e62021:canonical/aid/templates/review-rubrics/presentation.md \
  | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
# → 11

git show 8b9e62021:canonical/aid/templates/review-rubrics/narrative.md \
  | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
# → 11

git show 8b9e62021:canonical/aid/templates/review-rubrics/interface.md \
  | grep -cE '^\| `[A-Z]{2,12}-[0-9]{2}` \|'
# → 5
```

Total: **27 rows** across the three classes.

---

## Four-condition screen: rationale

The authoring-conventions.md criteria registry covers the in-scope methodology corpus:
`canonical/skills/`, `canonical/agents/`, `canonical/aid/templates/`, `.aid/knowledge/`.
The four conditions are evaluated relative to that corpus.

**Condition 1 — Uncovered:** Current criteria are G-01..G-08, KB-01..KB-04, SK-01..SK-02,
SR-01, AG-01, TO-01, TP-01 (18 ids). Each row is checked against the actual text of those
criteria (read from `.aid/knowledge/authoring-conventions.md § Review Criteria — Criteria by Level`).

**Condition 3 — Attachable:** Registry types that currently exist: `state`, `kb-generated`,
`kb-meta`, `kb-doc`, `skill-generated`, `skill-authored`, `skill-reference`, `agent`,
`template-payload`, `template-own`, `rendered` (plus the two non-type file classes
`agent-context` and `rendered` used in G-05/G-06 exclusions). A row needing a type not
in this set is `needs a new type — out of scope`.

---

## Per-row screening table

### PRE — Presentation family (11 rows)

Source: `git show 8b9e62021:canonical/aid/templates/review-rubrics/presentation.md`

| Row | Check (brief) | Outcome | Evidence |
|-----|---------------|---------|----------|
| `PRE-01` | Document-level accessibility requirements met | `needs a new type — out of scope` | Applies to UI, THEME, DASHBOARD, DIAGRAM, SUMMARY. Only SUMMARY maps to a methodology artifact (`kb.html`), but that is type `rendered` and excluded from content review (G-06). No registry type exists for any other member. Criterion source (`knowledge-summary/accessibility-checklist.md`) is absent from this installation. |
| `PRE-02` | Semantic landmarks present and correctly nested | `needs a new type — out of scope` | Same family members and same missing criterion source as PRE-01. |
| `PRE-03` | Every interactive element is keyboard reachable | `needs a new type — out of scope` | Same; additionally a runtime-behavior check — not decidable by reading a text file. |
| `PRE-04` | Modal or dialog traps and restores focus correctly | `needs a new type — out of scope` | Same; runtime behavior only verifiable in a browser. No registry type for target artifacts. |
| `PRE-05` | Motion respects the reduced-motion preference | `needs a new type — out of scope` | Same; criterion source absent from this installation. |
| `PRE-06` | Diagrams carry text alternatives | `needs a new type — out of scope` | DIAGRAM type not in registry. authoring-conventions.md § Dual-Audience Standard explicitly bans diagrams from KB docs, so the check cannot fire for any existing type even if scope were broadened. |
| `PRE-07` | Colours come from the declared palette | `needs a new type — out of scope` | Criterion source (`knowledge-summary/design-tokens.md`) absent. No registry type for UI/THEME artifacts. |
| `PRE-08` | Type follows the declared typography scale | `needs a new type — out of scope` | Same criterion source absent; same missing types. |
| `PRE-09` | Spacing follows the declared scale | `needs a new type — out of scope` | Same. |
| `PRE-10` | A project theming override uses the declared mechanism | `needs a new type — out of scope` | Same. |
| `PRE-11` | Every declared token pair meets WCAG AA contrast, in every theme | `needs a new type — out of scope` | Criterion source (`knowledge-summary/accessibility-checklist.md`) absent. No registry type for affected artifacts. |

---

### NAR — Narrative family (11 rows)

Source: `git show 8b9e62021:canonical/aid/templates/review-rubrics/narrative.md`

Note: The NAR family covers KB, DOCUMENTATION, REPORT, RESEARCH, ADR. Only `KB` maps to a
type (`kb-doc`) that exists in the registry. The remaining members have no registry entry.
Rows that pass all four conditions are admitted for `kb-doc` scope; for non-KB narrative types
the attachment gap is noted but does not block admission.

| Row | Check (brief) | Outcome | Evidence |
|-----|---------------|---------|----------|
| `NAR-01` | Every load-bearing claim is grounded | **admit** | (1) Uncovered: G-02 checks citation *form* (anchor vs. bare line number); it does not check whether claims have citations at all. No current criterion addresses claim grounding. (2) Declarable: yes — "Every load-bearing claim is grounded — the reader can reach what makes it true." (3) Attachable: `kb-doc` (declaring section is § Citation Rule which authoring-conventions.md scopes to KB docs); `*` is also valid. Recommend `kb-doc`. (4) Priceable: [MEDIUM] — an ungrounded load-bearing claim sends agents and reviewers to act on unsupported assertions; confined to one doc; a local edit supplies the grounding. Proposed id: **next-free KB (T4-KB-1)**. |
| `NAR-02` | Every citation uses a durable anchor, not a bare line number | `covered by G-02` | G-02 (global `*`): "Every citation is a durable anchor (path plus a grep-recoverable symbol or heading), never a bare `file.ext:LINE`" — identical check, identical criterion source (`authoring-conventions.md § Citation Rule (Durable Anchors)`). The rubric row adds a mechanical command (`kb-citation-lint.sh`) but does not extend the rule's scope or meaning. |
| `NAR-03` | Every cited path and anchor resolves | **admit** | (1) Uncovered: G-02 checks anchor *form*, not *resolution* — as the rubric's own notes confirm ("A durable anchor can still be dead, and a bare line number can still be live"). SR-01 checks pointer resolution but only for `skill-reference` and `template-own` types, not `kb-doc`. No current criterion covers dead citations in KB docs. (2) Declarable: yes. (3) Attachable: `*` (broadest honest attachment, matching SR-01's intent for all authored files) or `kb-doc`. Recommend `*`: a dead cite is harmful regardless of file type, and extending coverage globally closes the same gap SR-01 closes for skill/template files. If `*`, prefix is G. (4) Priceable: [MEDIUM] — one dead citation is confined; widespread dead cites escape. Proposed id: **next-free G (T4-G-1)**. |
| `NAR-04` | No drift-prone content — no value that will silently go stale | **admit** | (1) Uncovered: G-01 (global `*`) covers "cosmetic counts" only — its why says "counts drift every commit; the reader can run wc -l". NAR-04 is broader: the rubric notes include "a count, a version, a file total, a 'currently N of M'" and the authoring-conventions.md § Drift-Prone Content is Banned section additionally bans "dates without semantic anchor" and "other low-value clutter". The date and version classes are NOT covered by G-01. (2) Declarable: yes. (3) Attachable: `kb-doc` (the § Drift-Prone Content section says "primary docs", i.e. kb-category: primary = kb-doc type) or `*`. Recommend `kb-doc` — the declaring section's stated audience is KB primary docs. Note: if admitted at `kb-doc`, G-01 (which covers counts at `*`) is a partial subset for that type; no conflict, but a reviewer of kb-doc applies G-01 for counts and this new criterion for dates and other drift-prone values. (4) Priceable: [LOW] — drift-prone values are correct at write time; the defect is latent; a remove-or-pin edit corrects it (same class as G-01). Proposed id: **next-free KB (T4-KB-2)**. |
| `NAR-05` | No contradiction with a higher-authority source, nor internal self-contradiction | **admit** | (1) Uncovered: none of G-01..G-08, KB-01..KB-02 requires a KB doc to be consistent with its authority sources or internally consistent. (2) Declarable: yes. (3) Attachable: `kb-doc` (recommend) or `*`. (4) Priceable: [MEDIUM] — a contradiction in a KB doc misleads agents and reviewers; confined to the doc's consumers unless the doc is itself a widely-cited authority, in which case the radius escapes. **Flag:** the rubric row's criterion source is `INDEX.md universal taxonomy class 2 (Contradiction)` — this cites the rubric INDEX, not a KB-resident document. If admitted, task-006 must assign a KB-resident criterion source (`kb-authoring/principles.md`, listed in authoring-conventions.md frontmatter `sources:`, is the appropriate anchor). This is an open citation-source question, not a reason to reject admission. Proposed id: **next-free KB (T4-KB-3)**. |
| `NAR-06` | The document serves both its audiences — a human reader and an agent consumer | **admit** | (1) Uncovered: KB-02 checks layout and concern count; no current criterion checks dual-audience fitness. The authoring-conventions.md § Dual-Audience Standard section is prose with no criterion id. (2) Declarable: yes. (3) Attachable: `kb-doc` (the § Dual-Audience Standard section says "Every KB doc is authored for two readers at once"); `*` is also valid. Recommend `kb-doc`. (4) Priceable: [MEDIUM] — a doc that loses one audience fails for half its consumers; confined to the doc; a local rewrite corrects it. Proposed id: **next-free KB (T4-KB-4)**. |
| `NAR-07` | The document holds one concern; no duplication across docs | `covered by KB-02` | KB-02 (`kb-doc`): "Exactly one concern per doc". Criterion source is the same authoring-conventions.md § Concern Model section. Check is identical. |
| `NAR-08` | Layout follows the declared document structure | `covered by KB-02` | KB-02 (`kb-doc`): "the layout holds: frontmatter, title, index, content sections, and no history section" — same check as NAR-08. Criterion source is authoring-conventions.md § KB Document Layout. |
| `NAR-09` | Frontmatter is complete and valid | `covered by KB-01` | KB-01 (`kb-doc`): "Required frontmatter is present and single-line: objective, summary, sources" — same check. Criterion source is authoring-conventions.md § Frontmatter Rules. |
| `NAR-10` | Resolved items leave no trace — no stale "pending" or "TBD" | `covered by G-03` | G-03 (global `*`): "A resolved or closed tracked item leaves no trace — its row, detail, and closure prose are removed" — same check, criterion source authoring-conventions.md § Resolved Items Leave No Trace. |
| `NAR-11` | Prose is preferred where prose suffices; no script standing in for an explanation | **admit** | (1) Uncovered: no current criterion addresses prose preference over code blocks. The authoring-conventions.md § Prose Over Scripts section is prose with no criterion id. (2) Declarable: yes. (3) Attachable: `kb-doc` (the § Prose Over Scripts section appears in the KB-authoring concern chain) or `*`. Recommend `kb-doc`; could reasonably extend to `*` since the preference is universal. (4) Priceable: [MINOR] — a code block where prose suffices adds noise but the doc remains usable; rarely a blocker. This matches the rubric's own COULD/[MINOR] assessment. Proposed id: **next-free KB (T4-KB-5)**. |

---

### INT — Interface family (5 rows)

Source: `git show 8b9e62021:canonical/aid/templates/review-rubrics/interface.md`

| Row | Check (brief) | Outcome | Evidence |
|-----|---------------|---------|----------|
| `INT-01` | Declared contract is honoured — signature, shape and enum values match what is published | `needs a new type — out of scope` | Applies to API, CLI, MESSAGING, DATA MODEL, SCHEMA artifacts. None of these types exist in the authoring-conventions.md registry. The in-scope methodology corpus (`canonical/`, `.aid/knowledge/`) does not contain product interface specifications as typed artifacts. Criterion source (`pipeline-contracts.md § Typed Artifact Contracts`) exists as a KB doc but the artifact types it governs are absent from the registry. |
| `INT-02` | A change to an existing contract is backward compatible, or the break is declared | `needs a new type — out of scope` | Same target artifact types as INT-01 — none in the registry. Criterion source (`integration-map.md § Contracts`) exists but governs artifacts with no registry types. |
| `INT-03` | A closed enum is not extended or narrowed without updating every reader of it | `needs a new type — out of scope` | Same target types. Criterion source is the rubric INDEX universal taxonomy (not KB-resident). Additionally, this check targets code-level enum constructs in interface artifacts, which are outside the in-scope text corpus. |
| `INT-04` | Integration conventions are followed | `needs a new type — out of scope` | Same target types. Criterion source (`integration-map.md § Conventions`) exists but the artifact types it governs (API, CLI, etc.) have no registry entries. |
| `INT-05` | The artifact's own schema is satisfied where one is declared | `covered by KB-01, SK-01, AG-01` | Criterion: `artifact-schemas.md`. For kb-doc type: KB-01 validates frontmatter fields declared in artifact-schemas.md. For skill-authored: SK-01 validates agent dispatch table resolution. For agent: AG-01 validates name/folder match and agent resolution. These three criteria collectively cover schema validation for every currently reviewable type in the registry. INT-05 would be a unified umbrella, but it adds no new enforcement surface for the in-scope corpus. A global INT-05 at `*` would partially conflict with (or subsume) the per-type specifics above, introducing ambiguity without adding coverage. Covered by the three existing criteria. |

---

## Admitted rows — proposed ids, severities, and whys

| Proposal | Source row | Rec. type | Rec. prefix | Ordinal | Severity | One-line why |
|----------|-----------|-----------|-------------|---------|----------|-------------|
| T4-KB-1 | NAR-01 | `kb-doc` | `KB` | next-free KB (1st from this task) | [MEDIUM] | An ungrounded load-bearing claim in a KB doc sends agents and reviewers to act on unsupported assertions; confined to one doc; a local edit supplies the grounding |
| T4-G-1  | NAR-03 | `*`       | `G`  | next-free G (1st from this task) | [MEDIUM] | A dead citation fails the reader who follows it; one dead path is confined; a local edit repairs the pointer (SR-01 sets [HIGH] for runtime procedure pointers; KB doc citations are non-executable) |
| T4-KB-2 | NAR-04 | `kb-doc` | `KB` | next-free KB (2nd from this task) | [LOW] | Drift-prone values are correct at write time but become wrong without a signal; the defect is latent; a remove-or-pin edit corrects it |
| T4-KB-3 | NAR-05 | `kb-doc` | `KB` | next-free KB (3rd from this task) | [MEDIUM] | A contradiction in a KB doc misleads agents and reviewers; confined to the doc's consumers; escalates if the doc is itself cited as an authority by other docs |
| T4-KB-4 | NAR-06 | `kb-doc` | `KB` | next-free KB (4th from this task) | [MEDIUM] | A doc that loses one audience fails for half its consumers; confined to the doc; a local rewrite corrects it |
| T4-KB-5 | NAR-11 | `kb-doc` | `KB` | next-free KB (5th from this task) | [MINOR] | A code block where prose suffices adds noise but the doc remains usable |

**Prefix allocation counts this task proposes:**
- `G`: 1 (T4-G-1, for NAR-03)
- `KB`: 5 (T4-KB-1 through T4-KB-5, for NAR-01, NAR-04, NAR-05, NAR-06, NAR-11)

Task-006 allocates the actual numbers. Tasks 003 and 005 propose concurrently from the same
namespace; the ordinals above are relative to this task's proposals only.

---

## Outcome tally

| Outcome | Count | Rows |
|---------|-------|------|
| `admit` | 6 | NAR-01, NAR-03, NAR-04, NAR-05, NAR-06, NAR-11 |
| `covered by <current-id>` | 6 | NAR-02 (G-02), NAR-07 (KB-02), NAR-08 (KB-02), NAR-09 (KB-01), NAR-10 (G-03), INT-05 (KB-01 + SK-01 + AG-01) |
| `rubric-owned` | 0 | — |
| `needs a new type — out of scope` | 15 | PRE-01..PRE-11 (11), INT-01..INT-04 (4) |
| **Total** | **27** | All rows recorded |

---

## Open items

**NAR-05 criterion-source gap.** The rubric row cites `INDEX.md universal taxonomy class 2
(Contradiction)` — the rubric INDEX, which is not a KB-resident declaring document in
authoring-conventions.md. If task-006 admits this row, the criterion cell must point to a
KB-resident source. `kb-authoring/principles.md` (listed in authoring-conventions.md
frontmatter `sources:`) is the recommended anchor; task-006 should confirm it contains a
principle covering contradiction before allocating the id.

**NAR-03 vs. SR-01 overlap.** If T4-G-1 is admitted at `*`, it applies to `skill-reference`
and `template-own` types as well, where SR-01 already fires. The two checks are compatible
(SR-01 targets instruction-content pointers specifically; T4-G-1 targets all citations) but
a reviewer of those types would apply both. This is redundancy, not a conflict. Task-006
should decide whether SR-01 remains alongside or is scoped down.

**NAR-04 vs. G-01 overlap.** If T4-KB-2 is admitted for `kb-doc`, both G-01 (counts, `*`)
and T4-KB-2 (all drift-prone content, `kb-doc`) apply to KB docs. No conflict; G-01 is a
narrow subset. A reviewer of kb-doc applies G-01 for counts and T4-KB-2 for dates and other
drift-prone values.

---

## Conflicts detected

None. No admitted row contradicts any current criterion. NAR-02 and NAR-10 are exact duplicates
of G-02 and G-03 respectively — those are `covered by` outcomes, not conflicts.
