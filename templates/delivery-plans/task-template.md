# task-NNN: {Title}

**Type:** RESEARCH | DESIGN | IMPLEMENT | TEST | DOCUMENT | MIGRATE | REFACTOR | CONFIGURE

**Source:** feature-NNN-{name} → delivery-NNN

**Depends on:** task-NNN [, task-NNN] | — (none)

**Scope:**
- {What this task produces or modifies — depends on Type. Specific and bounded. One type per task; never mix types.}

**Acceptance Criteria:**
- [ ] {Criterion 1 — concrete and testable}
- [ ] {Criterion 2 — concrete and testable}
- [ ] All §6 quality gates pass

---

Six sections — the `# task-NNN` title, Type, Source, Depends on, Scope, Acceptance Criteria. Nothing else. The Type drives both how the executor works and how the reviewer evaluates the task. Every task except the first declares at least one `Depends on` entry; the first uses `— (none)`.
