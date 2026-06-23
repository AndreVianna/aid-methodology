# task-028: Doc-model tightening -- operational guidance first-class (concern-model + principles + document-expectations)

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-005

**Depends on:** task-004 (delivery-001), task-010 (delivery-001)

**Scope:**
- **Extend f003's doc model (do NOT re-spec it)** with one structural rule: operational guidance an
  agent acts on -- **conventions, invariants, gotchas, contracts** -- MUST be **first-class named,
  greppable sections**, not buried in prose. Author into the f003 templates/snippets shipped by
  delivery-001 (task-004 = the doc-model/concern-model authoring; task-010 = the
  `document-expectations.md` open-questions rewrite):
  - **`canonical/aid/templates/kb-authoring/concern-model.md`** -- add an "Operational guidance is
    first-class structure" subsection carrying the **owning-table**: the four classes -> named
    greppable section headings (`## Conventions` / `## Invariants` / `## Gotchas` / `## Contracts`,
    or the project-named equivalents the rule enumerates) -> owning concerns -> docs map
    (Conventions->C3 coding-standards + C2/C5; Invariants->C1/C2 + C4 spine; Gotchas->C7 tech-debt +
    owning concern; Contracts->C5 schemas + C2 pipeline-contracts/integration-map). State the
    "**only the sections relevant to its concern**" rule (a glossary doc need not carry `##
    Contracts`) -- the rule is "where a doc carries operational guidance of class X, it carries it as
    the named section for X," NOT "every doc carries all four." This owning-table is the source
    task-027's presence check consumes for its scoping.
  - **`canonical/aid/templates/kb-authoring/principles.md`** -- add ONE cross-ref principle line
    beside the existing summary+pointer principle ("Operational guidance -- conventions / invariants /
    gotchas / contracts -- is first-class greppable structure, not prose").
  - **`canonical/skills/aid-discover/references/document-expectations.md`** -- add an **operational
    open-question** to the relevant docs' `### <filename>` entries (e.g. architecture/parts: "What
    must a newcomer follow, never break, and watch out for when changing this -- the conventions,
    invariants, and gotchas?") so the researcher surfaces operational guidance AS the named section.
    Prose addition only; same `### <filename>` keying, **no parser change**.
- Touch **NO** f003 machinery: the concern list, the seed mapping, `doc-set-resolve.md`, and
  `aid-summarize` are unchanged. **No** f001 schema change (a named markdown section, NOT a frontmatter
  field). **No** new concern doc added.

**Boundary:** this task authors ONLY the doc-model/expectations rule. It does NOT write
`kb-actback-task.sh` (task-027 -- which *consumes* this owning-table), does NOT wire M6 into the panel
(task-029), and does NOT build the act-back fixture (delivery-006/f012).

**Acceptance Criteria:**
- [ ] `concern-model.md` carries an "Operational guidance is first-class structure" subsection with the
  four-classes -> named greppable section headings -> owning-concerns -> docs **owning-table**, plus the
  "only the sections relevant to its concern" rule (a doc owns only its expected classes).
- [ ] `principles.md` carries ONE new principle line cross-referencing the first-class operational-
  structure rule, beside the existing summary+pointer principle.
- [ ] `document-expectations.md` gains an operational open-question on the relevant `### <filename>`
  entries (conventions/invariants/gotchas/contracts framing); the keying and parser are unchanged.
- [ ] **No** f003 machinery is touched (concern list, seed mapping, `doc-set-resolve.md`,
  `aid-summarize` unchanged) and **no** f001 frontmatter field is added (named section, not schema).
- [ ] The named section headings authored here are byte-identical to the headings task-027's presence
  check greps and task-029's M6 prompt names (single source of truth for the heading set).
- [ ] All section-6 quality gates pass; canonical edits render to all 5 trees (render-drift green).
