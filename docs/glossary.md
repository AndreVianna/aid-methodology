# AID Glossary

Terms and concepts used throughout the AID methodology.

---

## Core Concepts

**AID (AI-Integrated Development):** A structured methodology for building and maintaining software with AI agents. 8 phases, 5 groups. Human and AI co-execute every phase.

**Knowledge Base (KB):** 16 standard markdown documents (plus 3 meta-documents) that capture the living understanding of a project. The gravitational center of AID — not the spec, not the code. Updated continuously across phases.

**Feedback Loop:** A formal pathway for a downstream phase to revise upstream artifacts. Produces a formal record (a Q&A entry in a STATE file, an IMPEDIMENT file, or a MONITOR-STATE finding) with a revision trail.

**Phase Gate:** A human decision point between phases. The human reviews the phase output and approves advancement. "OK?" is the gate.

**Iron Man Model:** The human-AI collaboration philosophy. The AI is the suit (amplifies capability). The human is the pilot (sets direction, makes decisions). The human never leaves the cockpit.

---

## Setup

**aid-config:** Bootstrapping step that runs before the pipeline begins. Asks greenfield or brownfield, collects project metadata, and scaffolds the `.aid/knowledge/` directory with 16 empty KB document templates. Also creates `AGENTS.md`, `CLAUDE.md`, `DISCOVERY-STATE.md`, `README.md`, and `INDEX.md` placeholders. Not a methodology phase — it prepares the project so Discovery (or Interview) can begin cleanly.

---

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Prepare | Knowledge Base (16 documents) |
| **Interview** | Define | REQUIREMENTS.md + per-feature SPEC.md stubs |
| **Specify** | Define | SPEC.md technical specification |
| **Plan** | Map | PLAN.md (sequenced deliveries) |
| **Detail** | Map | Typed task files + execution graph in PLAN.md |
| **Execute** | Execute | Reviewed, graded code (8 task types, built-in review loop) |
| **Deploy** | Deliver | Shipped delivery, PR, KB update |
| **Monitor** | Deliver | MONITOR-STATE.md (BUG → Execute / CR → Discover / Infrastructure / No Action) |

---

## Artifacts

**SPEC.md:** Formal specification grounded in the Knowledge Base. Treated as a hypothesis — refined by evidence from implementation.

**Q&A entry:** Appended to a STATE file (`DISCOVERY-STATE.md`, `INTERVIEW-STATE.md`, or a feature's `STATE.md`) when a phase finds the Knowledge Base or an upstream artifact deficient. The owning phase resolves it on its next run — targeted, not a full restart.

**IMPEDIMENT.md:** Filed when implementation discovers the plan or spec is wrong. Contains: what was assumed, what's true, proposed revision, and impact assessment.

**MONITOR-STATE.md:** Filed when production monitoring identifies an issue. Classifies as BUG (short path → Execute), CR (full cycle → Discover), Infrastructure (ops team), or No Action (monitor only). For bugs, includes root cause analysis, patch scope, and test requirements.

**Grading (A+ to F):** The review phase's quality scale. A+ (exemplary) through F (doesn't build). Evaluates spec compliance, architecture adherence, and convention conformance. Domain-specific quality checks (e.g., data accuracy thresholds) are defined per project in the SPEC.md.

---

## Groups

| Group | Phases | Focus |
|-------|--------|-------|
| **Prepare** | Discover (+ aid-config, aid-summarize) | Set up the workspace and understand the system |
| **Define** | Interview, Specify | Define the problem and how to solve it |
| **Map** | Plan, Detail | From requirements to an executable task list |
| **Execute** | Execute | Build, review, and test |
| **Deliver** | Deploy, Monitor | Ship, monitor, and route what breaks |

---

## Related Terms

**SDD (Spec-Driven Development):** A methodology where specifications drive code generation. AID contains SDD as a subset — the spec-and-build layer — and extends it with discovery, two-level planning, feedback loops, and post-deployment phases.

**Brownfield:** An existing codebase with history, technical debt, and undocumented knowledge. AID's Discovery phase is specifically designed for brownfield systems.

**Greenfield:** A new project with no existing code. In AID, greenfield projects run Init first, then skip Discovery and start at Interview.

**Determinism Test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide automation depth per phase.
