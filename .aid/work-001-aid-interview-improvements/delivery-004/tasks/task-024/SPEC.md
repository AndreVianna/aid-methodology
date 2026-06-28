# task-024: Layered seed<->requirements coherence-check reference doc

**Type:** IMPLEMENT

**Source:** work-001-aid-interview-improvements -> delivery-004

**Depends on:** -- (none)

**Scope:**
- Author a new reference doc (e.g. `canonical/skills/aid-interview/references/coherence-check.md`)
  encoding the layered seed<->requirements coherence check (FR-3 / AC-5). Inputs: the just-authored seed
  docs (the 5 elements) + the gathered REQUIREMENTS. BOTH layers always run:
  - **(a) Interview-time concrete-example probe (conversational):** take a concrete requirement and walk
    it through the seed (its terms, boundaries, stack), surfacing any mismatch in dialogue (Example
    Mapping, findings Family 8). A requirement the seed cannot express, or that contradicts a declared
    term/boundary, is a flagged mismatch.
  - **(b) Structural cross-check (deterministic):** every load-bearing term used in REQUIREMENTS maps to a
    seed concept (a `domain-glossary.md` entry or a named `architecture.md` part); every seed concept is
    reachable from a requirement. Output two orphan sets: **Requirement orphan** (a REQUIREMENTS term with
    no seed concept -> a seed gap / under-pinned seed) and **Seed orphan** (a seed concept no requirement
    references -> possible scope drift or unstated requirement).
- **Conflict surfacing:** any mismatch (a) or orphan (b) is surfaced to the user as an NFR-7 question
  (suggested resolution + rationale) and MUST be resolved before the work proceeds [HUMAN GATE];
  resolution is recorded (engine scribe move); the check RE-RUNS after the seed is amended.
- The doc is a self-contained procedure invoked BY the seed-authoring step (task-025) -- it does not itself
  wire into the spine. State the requirement-orphan output is the sufficiency-bar input (zero requirement
  orphans is part of minimal-but-sufficient).
- ASCII-only; single-concern reference doc; full f001 frontmatter if it is a shipped reference (match the
  sibling `references/*.md` convention).
- **Out of scope:** materializing the seed docs / invoking this check + the gate (task-025); the
  greenfield-mode gate internals (task-022/023); render (task-026); the injected-mismatch verification
  (task-027).

**Acceptance Criteria:**
- [ ] The doc specifies BOTH layers -- (a) the conversational concrete-example probe and (b) the deterministic structural cross-check with the Requirement-orphan and Seed-orphan output sets -- and states both always run. *(FR-3 / AC-5; gate criterion 3)*
- [ ] Any mismatch/orphan is surfaced as an NFR-7 question (suggested resolution + rationale), gated [HUMAN GATE] before proceeding, recorded, and the check re-runs after amendment. *(AC-5; gate criterion 3)*
- [ ] The doc declares "zero requirement orphans" as a sufficiency-bar input consumed by task-025's stopping check. *(RQ-A5 sufficiency bar; gate criterion 3)*
- [ ] ASCII-only; single concern; matches the `references/*.md` frontmatter/layout convention. *(authoring standard)*
- [ ] Skill reference is prose-executed (no unit test; IMPLEMENT unit-test default overridden -- the check's blocking behavior is exercised by the injected-mismatch test at task-027). All REQUIREMENTS.md §6 quality gates pass.
