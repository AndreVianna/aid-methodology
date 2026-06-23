# task-041: aid-query-kb gap capture into the Q&A (Pending) backlog

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-007

**Depends on:** task-040

**Scope:**
- f008 Part 3 (FR-28, AC8) -- turn the `aid-query-kb` "## Gap" branch (today's
  `aid-ask` SKILL.md lines 116-136, which PRINTS and DISCARDS the gap) into a CAPTURE: on
  insufficient context it ALSO enqueues the gap into the **existing `STATE.md ## Q&A (Pending)`
  backlog**. **No new queue file is invented** -- reuse the same backlog scout-questions, REVIEW
  Q&A, and `aid-housekeep` already use.
- **Target-file resolution** (write into the `## Q&A (Pending)` section of):
  - the in-flight work's `.aid/work-NNN-*/STATE.md` if the query was about that work;
  - otherwise the knowledge backlog `.aid/knowledge/STATE.md`;
  - **default when ambiguous:** `.aid/knowledge/STATE.md`, and name the alternative in the entry's
    Context. (SPIKE-3 default -- a Q&A append is non-destructive, so default-and-name, not ask.)
- **Entry format:** the existing `### Q{N}` schema (Category/Impact/Status/Context/Suggested),
  Category prefixed `Query-Gap / <KB-cannot-answer | KB-contradicts-code>` as the filter tag;
  Impact `High` if KB-contradicts-code, `Medium` if KB-cannot-answer; Status `Pending`; Context
  records the verbatim question + the specific gap (which doc lacks data, OR the exact
  contradicting KB claim + code citation) + sources checked; Suggested points at
  `/aid-update-kb "<gap>"` or the next `/aid-housekeep` KB-DELTA. `N` = next free `Q{N}` in that
  backlog (never renumber).
- **Frontmatter delta:** add `Write, Edit` to `allowed-tools` (now
  `Read, Glob, Grep, Agent, Write, Edit`) -- the one grant beyond the rename.
- **Behavioral guard (in SKILL.md body):** an explicit constraint -- *"writes are restricted to
  appending a Query-Gap entry to a `STATE.md ## Q&A (Pending)` section; no KB doc, settings, or
  code file is ever written."* The answer path stays read-only; only the gap-append branch writes
  (NFR-6/C4: capture-and-flag, never auto-apply / never auto-fix a KB doc).
- Keep the SKILL.md ASCII-only (C2).

**Acceptance Criteria:**
- [ ] On the insufficient-context branch, `aid-query-kb` appends a `### Q{N}` entry tagged
  `Category: Query-Gap / <flavor>` to the resolved `## Q&A (Pending)` backlog (instead of only
  printing the gap).
- [ ] Target-file resolution rule (work-NNN STATE.md vs `.aid/knowledge/STATE.md`, default
  knowledge backlog + name-the-alternative on ambiguity) is specified in the SKILL.md body.
- [ ] Entry uses the existing `### Q{N}` schema with the two Impact flavors (High =
  contradicts-code, Medium = cannot-answer) and the `Query-Gap /` filter-tag prefix; `N` is the
  next free number (never renumbers).
- [ ] `allowed-tools:` now includes `Write, Edit`; the body carries the write-scope constraint
  restricting writes to a `## Q&A (Pending)` append only (no KB doc / settings / code write).
- [ ] The answer path remains read-only; no auto-fix to any KB doc exists.
- [ ] `grep -rn 'aid-ask' canonical/` still returns zero (rename invariant from task-040 held).
- [ ] SKILL.md is ASCII-only.
- [ ] All section-6 quality gates pass.
