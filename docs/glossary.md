# AID Glossary

Terms and concepts used throughout the AID methodology.

---

## Core Concepts

**AID (AI-Integrated Development):** A structured methodology for building and maintaining software with AI agents. 12 phases, 5 groups, 11 feedback loops. Human and AI co-execute every phase.

**Knowledge Base (KB):** Up to 13 markdown documents that capture the living understanding of a project. The gravitational center of AID — not the spec, not the code. Updated continuously across phases.

**Feedback Loop:** A formal pathway for a downstream phase to revise upstream artifacts. Produces an artifact (GAP.md, IMPEDIMENT.md, TRIAGE.md, or CORRECTION.md) with a revision trail.

**Phase Gate:** A human decision point between phases. The human reviews the phase output and approves advancement. "OK?" is the gate.

**Iron Man Model:** The human-AI collaboration philosophy. The AI is the suit (amplifies capability). The human is the pilot (sets direction, makes decisions). The human never leaves the cockpit.

---

## Phases

| Phase | Group | Produces |
|-------|-------|----------|
| **Discover** | Problem Mapping | Knowledge Base (13 documents) |
| **Interview** | Problem Mapping | REQUIREMENTS.md |
| **Specify** | Planning | SPEC.md |
| **Plan** | Planning | PLAN.md (strategy: MVP, modules, deliverables) |
| **Detail** | Planning | DETAIL.md (tactics: stories, tasks, precedence) |
| **Implement** | Implementation | Code + tests |
| **Review** | Implementation | REVIEW.md (grade A+ to F) |
| **Test** | Implementation | TEST-REPORT.md |
| **Deploy** | Production | Delivery summary, KB update, PR |
| **Track** | Production | TRACK-REPORT.md |
| **Triage** | Maintenance | TRIAGE.md (BUG / CR / Infrastructure / No Action) |
| **Correct** | Maintenance | CORRECTION.md → routes to Implement |

---

## Artifacts

**SPEC.md:** Formal specification grounded in the Knowledge Base. Treated as a hypothesis — refined by evidence from implementation.

**GAP.md:** Filed when any phase discovers the Knowledge Base is incomplete. Triggers targeted discovery (not a full restart).

**IMPEDIMENT.md:** Filed when implementation discovers the plan or spec is wrong. Contains: what was assumed, what's true, proposed revision, and impact assessment.

**TRIAGE.md:** Filed when production monitoring identifies an issue. Classifies as BUG (short path → Correct), CR (full cycle → Discover), Infrastructure (ops team), or No Action (monitor only).

**CORRECTION.md:** Root cause analysis and patch scope for a triaged bug. Defines the minimal fix, test requirements, and affected areas.

**Grading (A+ to F):** The review phase's quality scale. A+ (exemplary) through F (doesn't build). Evaluates spec compliance, architecture adherence, and convention conformance. Domain-specific quality checks (e.g., data accuracy thresholds) are defined per project in the SPEC.md.

---

## Groups

| Group | Phases | Focus |
|-------|--------|-------|
| **Problem Mapping** | Discover, Interview | Understanding the system and gathering requirements |
| **Planning** | Specify, Plan, Detail | From requirements to executable task list |
| **Implementation** | Implement, Review, Test | Build, verify, validate |
| **Production** | Deploy, Track | Ship and monitor |
| **Maintenance** | Triage, Correct | Classify issues and fix bugs |

---

## Related Terms

**SDD (Spec-Driven Development):** A methodology where specifications drive code generation. AID contains SDD as a subset (phases 3-6) and extends it with discovery, feedback loops, and post-deployment phases.

**Brownfield:** An existing codebase with history, technical debt, and undocumented knowledge. AID's Discovery phase is specifically designed for brownfield systems.

**Greenfield:** A new project with no existing code. In AID, greenfield projects skip Discovery and start at Interview.

**Determinism Test:** Can you write a complete set of rules to validate the outcome? If yes, automate fully. If no, keep a human in the loop. Used to decide automation depth per phase.
