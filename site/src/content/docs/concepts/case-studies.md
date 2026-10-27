---
title: 'Case studies'
description: 'This page shows you how three projects moved through the AID pipeline, so you can see which way in fits yours.'
---

This page shows you how three projects moved through the AID pipeline, so you can see which way in fits yours.

The accounts come from the [methodology document](https://github.com/AndreVianna/aid-methodology/blob/master/docs/aid-methodology.md) in the AID repository. They are the project's own summaries. Read them as examples of how the phases fit together, not as measurements.

| Case study | Path used | Phases named in the account |
|------------|-----------|-----------------------------|
| VivaVoz desktop app | [Greenfield](/reference/glossary/#greenfield), full path | Describe, Define, Specify, Plan, Detail, Execute, Deploy |
| Enterprise Java search engine | [Brownfield](/reference/glossary/#brownfield), full path | Discover, Describe, Define, Specify |
| Zac pipeline | Brownfield, full path, then the [lite path](/reference/glossary/#lite-path) | Describe, Define, Specify, Execute, Monitor, then `/aid-fix` |

For the phases themselves, see [The pipeline](/concepts/pipeline/).

## A new desktop app: VivaVoz

VivaVoz is a desktop app, built with Avalonia and .NET, that records voice and transcribes it. It was built from scratch.

- **Discover:** skipped, because there was no code. The interview that `/aid-describe` runs on a new project seeded a small [Knowledge Base](/reference/glossary/#knowledge-base).
- **Describe and Define:** full requirements gathering covered user personas, feature priority and platform constraints. The work had several features, so it took the full path, entered with `/aid-describe`.
- **Specify:** each feature got detailed architecture decisions, such as the MVVM pattern, SQLite storage and Whisper integration. The agent proposed them from community conventions rather than from an open-ended prompt.
- **Plan:** the roadmap became ordered deliveries that each ship on their own: a first version that records, then transcription, then export.
- **Detail:** each delivery became task specifications, and each one carried explicit C# interface contracts.
- **Execute:** each task ran through the review loop of `/aid-execute`, and the project had a unit and end-to-end test suite graded against the rubric.
- **Deploy:** the deliveries shipped one at a time, and each was merged on its own.

**What worked.** Planning in two levels separated strategy from tactics. The plan decided what went into the first version, and the detail phase decided how to build each piece. This kept planning from stalling on implementation choices before the overall structure was settled.

**Where the lite path would have fit.** Bugs found along the way could go through `/aid-fix`, which takes a diagnosis and writes one task to implement the fix. It does not re-specify or re-plan. The [shortcuts page](/get-started/lite-path/) explains this way of working.

## An existing enterprise Java codebase

The second project is a very large enterprise Java codebase built with Maven and Tycho, using OSGi bundles. A client needed a developer to understand and extend its search engine.

- **Discover:** a full analysis of the codebase. The Knowledge Base recorded the OSGi bundle manifest structure, the search indexing pattern, the key extension points, the naming conventions and the deployment model.
- **Describe and Define:** the interview was short and aimed at business context and search requirements, because Discover had already recorded the technical context. Each question came with a suggested answer grounded in the Knowledge Base. For example: "Based on `architecture.md`: the search service extends `org.eclipse.search.ui.ISearchPage`. Does the new feature plug in at this extension point?"
- **Specify:** the specification was grounded in the Knowledge Base. It named real packages, existing interfaces and OSGi service bindings.

**What worked.** According to the account, an agent dropped into this codebase without Discover would have hallucinated. The Knowledge Base gave the agents the context to work within the existing architecture instead of against it. It also surfaced constraints on the OSGi service lifecycle that open-ended exploration would not have caught.

## An automation pipeline: Zac

Zac is an e-commerce advertising pipeline. It pulls data from Meta, Google and Klaviyo, validates it, processes it with specialist AI agents and grades the quality of the output.

- **Describe and Define:** the interview asked one question at a time: "What are your brands?", "What platforms?", "What does a good report look like?", "What data don't you agree with?" The last question uncovered a timezone bug in the existing data aggregation before any specification was written.
- **Specify:** the specification covered the data flow, the agent roles and the grading criteria.
- **Execute:** the build used several specialist agents with an orchestrator and an executive-summary generator. A domain-specific quality gate at grade A checked each report for a match with its source, traceability and consistency across agents.
- **Monitor:** `/aid-monitor` watched the quality-gate results across brands. When a report failed, it sorted the failure. A data-processing bug went to `/aid-fix` and then Execute. A change in a source format needed new requirements and a new specification, which is the full path again.

**The lite path in practice.** After the first build, brand-specific issues were handled as `/aid-fix` shortcut works. Each was a single task to implement the fix, so it avoided the longer cycle of the full path. For the routing from Monitor, see [Feedback loops](/concepts/feedback-loops/#routing-from-monitor).
