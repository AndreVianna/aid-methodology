---
title: 'Case studies'
description: 'Three real projects and the path each took through the AID pipeline.'
---

## 8. Case Studies

*Three real projects, three different paths through the pipeline.*

| **Case study** | Path used | Key phases | Key insight |
|---------------|-----------|------------|-------------|
| VivaVoz Desktop App | Greenfield · full path | Describe → Define → Specify → Plan → Detail → Execute | Two-level planning (Plan = strategy, Detail = tactics) prevented planning sessions from bogging down in micro-decisions before macro-structure was settled |
| Brownfield Enterprise Java | Brownfield · full path | Discover → Describe → Define → Specify | Without Discovery, an agent dropped into a 21 GB Java codebase hallucinates; the KB gave agents context to work within the existing OSGi architecture rather than against it |
| Zac Pipeline | Brownfield · full path + lite path | All phases; Monitor → `/aid-fix` → Execute for post-launch fixes | After the initial build, individual brand-specific issues were handled as `/aid-fix` shortcut works — 20–30 minutes end to end vs. the multi-day cycle a full path would require |

### Greenfield — VivaVoz Desktop Application

**Context:** MVVM desktop app (Avalonia/.NET) for voice recording and transcription. Built from scratch.

**How AID applied:**

- **Discovery:** Skipped (greenfield). Minimal KB populated during interview.
- **Describe → Define:** Full requirements gathering. User personas, feature priority, platform constraints. Multiple features and multi-week scope — the full path, entered directly via `/aid-describe`.
- **Specify:** Detailed architecture decisions per feature: MVVM pattern, SQLite storage, Whisper integration. Agent proposed based on community conventions, not open-ended prompting.
- **Plan:** Sequenced the roadmap — MVP (core recording), v2 (transcription), v3 (export) — into ordered, independently shippable deliveries.
- **Detail:** Decomposed each delivery into task specs, each carrying explicit C# interface contracts.
- **Execute:** Agent-per-task execution with the built-in review loop — parallel work on independent features, a full unit + E2E test suite graded against the rubric.
- **Deploy:** Incremental deliveries. Each delivery merged independently.

**What worked:** The two-level planning (Plan → Detail) meant strategic decisions were separated from tactical decomposition. The plan defined "what goes in MVP" while detail defined "how to build each piece." Without this separation, planning sessions routinely get bogged down debating implementation micro-decisions before the macro-structure is settled.

**What would have been faster with lite path:** Individual bug fixes discovered during Execute were routed through `/aid-fix` — a diagnosis from Monitor plus a single IMPLEMENT task, no re-spec, no re-plan.

### Brownfield Enterprise Java

**Context:** 21 GB enterprise Java codebase (Maven/Tycho, OSGi bundles). Client needed a developer to understand and extend the search engine.

**How AID applied:**

- **Discovery:** Full codebase analysis. Module listing across hundreds of packages. Architecture report covering 15 sections. The KB captured: OSGi bundle manifest structure, search indexing pattern, key extension points, naming conventions, and the deployment model (target platform).
- **Describe → Define:** Targeted — client explained business context, search requirements. Short interview because Discovery pre-filled all technical context. The agent's questions came with suggested answers: "Based on `architecture.md`: the search service extends `org.eclipse.search.ui.ISearchPage`. Does the new feature plug in at this extension point? [Y/N/custom]"
- **Specify:** Spec grounded in the KB. Referenced actual package names, existing interfaces, OSGi service bindings.

**Key insight:** Without Discovery, an agent dropped into this codebase would have hallucinated. The KB gave agents the context they needed to work within the existing architecture rather than against it. The Specify session took 40 minutes; the equivalent effort without a KB would have been a multi-day exploration that still wouldn't have caught the OSGi service lifecycle constraints that the KB surfaced in its first section.

### Operational Automation — Zac Pipeline

**Context:** E-commerce advertising pipeline. Pull data from Meta/Google/Klaviyo, validate, process with specialist AI agents, grade output quality.

**How AID applied:**

- **Describe → Define:** One question at a time. "What are your brands?" → "What platforms?" → "What does a good report look like?" → "What data don't you agree with?" That last question discovered a timezone bug in the existing data aggregation — before a line of spec was written.
- **Specify:** Pipeline spec with data flow, agent roles, grading criteria.
- **Execute:** Multi-agent orchestration — 4 specialist agents + orchestrator + executive-summary generator — validated against a domain-specific quality gate (Grade A): source match (1% tolerance), traceability, cross-agent consistency.
- **Monitor:** Watches quality-gate results across brands. When a report fails, Monitor classifies it — a data-processing bug (short path: `/aid-fix` → Execute) or a source-format change (full cycle: new requirements → new spec). Nothing falls through.

**The lite path in practice:** After the initial build, individual brand-specific issues were handled as `/aid-fix` shortcut works — each a single IMPLEMENT task taking 20-30 minutes end to end, vs. the multi-day cycle the full path would require.
