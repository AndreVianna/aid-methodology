# AID Glossary

Terms and concepts used throughout the AID methodology.

---

## Core Concepts

**AID (AI-Integrated Development):** A structured methodology for building and maintaining software with AI agents. 11 phases, 4 groups, 11 feedback loops. Human and AI co-execute every phase.

**Knowledge Base (KB):** Up to 14 markdown documents that capture the living understanding of a project. The gravitational center of AID — not the spec, not the code. Updated continuously across phases.

**Feedback Loop:** A formal pathway for a downstream phase to revise upstream artifacts. Produces an artifact (GAP.md, IMPEDIMENT.md, or TRIAGE.md) with a revision trail.

**Phase Gate:** A human decision point between phases. The human reviews the phase output and approves advancement. "OK?" is the gate.

**Iron Man Model:** The human-AI collaboration philosophy. The AI is the suit (amplifies capability). The human is the pilot (sets direction, makes decisions). The human never leaves the cockpit.

---

## Setup

**aid-init:** Bootstrapping step that runs before the pipeline begins. Asks greenfield or brownfield, collects project metadata, and scaffolds the `knowledge/` directory with 14 empty KB document templates. Also creates `AGENTS.md`, `CLAUDE.md`, `DISCOVERY-STATE.md`, `README.md`, and `INDEX.md` placeholders. Not a methodology phase — it prepares the project so Discovery (or Interview) can begin cleanly.

---

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Define | Knowledge Base (14 documents) |
| **Interview** | Define | REQUIREMENTS.md |
| **Specify** | Define | SPEC.md |
| **Plan** | Map | PLAN.md (strategy: MVP, modules, deliverables) |
| **Detail** | Map | DETAIL.md (tactics: stories, tasks, precedence) |
| **Implement** | Execute | Code + tests |
| **Review** | Execute | REVIEW.md (grade A+ to F) |
| **Test** | Execute | TEST-REPORT.md |
| **Deploy** | Deliver | Delivery summary, KB update, PR |
| **Track** | Deliver | TRACK-REPORT.md |
| **Triage** | Deliver | TRIAGE.md (BUG → Implement / CR → Discover / Infrastructure / No Action) |

---

## Artifacts

**SPEC.md:** Formal specification grounded in the Knowledge Base. Treated as a hypothesis — refined by evidence from implementation.

**GAP.md:** Filed when any phase discovers the Knowledge Base is incomplete. Triggers targeted discovery (not a full restart).

**IMPEDIMENT.md:** Filed when implementation discovers the plan or spec is wrong. Contains: what was assumed, what's true, proposed revision, and impact assessment.

**TRIAGE.md:** Filed when production monitoring identifies an issue. Classifies as BUG (short path → Implement), CR (full cycle → Discover), Infrastructure (ops team), or No Action (monitor only). For bugs, includes root cause analysis, patch scope, and test requirements.

**CORRECTION.md (Deprecated):** Formerly produced by the Correct phase for root cause analysis. Root cause analysis is now part of Triage and documented directly in TRIAGE.md.

**Grading (A+ to F):** The review phase's quality scale. A+ (exemplary) through F (doesn't build). Evaluates spec compliance, architecture adherence, and convention conformance. Domain-specific quality checks (e.g., data accuracy thresholds) are defined per project in the SPEC.md.

---

## Groups

| Group | Phases | Focus |
|-------|--------|-------|
| **Define** | Discover, Interview, Specify | Define the problem before touching code |
| **Map** | Plan, Detail | From requirements to executable task list |
| **Execute** | Implement, Review, Test | Build, verify, validate |
| **Deliver** | Deploy, Track, Triage | Ship, monitor, and route what breaks |

---

## Related Terms

**SDD (Spec-Driven Development):** A methodology where specifications drive code generation. AID contains SDD as a subset (phases 3-6) and extends it with discovery, feedback loops, and post-deployment phases.

**Brownfield:** An existing codebase with history, technical debt, and undocumented knowledge. AID's Discovery phase is specifically designed for brownfield systems.

**Greenfield:** A new project with no existing code. In AID, greenfield projects run Init first, then skip Discovery and start at Interview.

**Determinism Test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide automation depth per phase.
