# AID Examples

Real-world examples of AID applied to production projects. All identifying details have been anonymized.

## Brownfield Enterprise

**Scenario:** A 21GB Java/OSGi enterprise monorepo — no documentation, no architect available, three days to understand and contribute.

→ [brownfield-enterprise/](brownfield-enterprise/) — Discovery phase artifacts, Knowledge Base excerpts, and the resulting architecture report.

**Key takeaway:** Discovery on a system this size took one AI-assisted session, not two weeks. The Knowledge Base became the foundation for every subsequent PR review and feature implementation.

## Desktop Application

**Scenario:** A Windows desktop transcription app using .NET/Avalonia/MVVM — greenfield features added in incremental deliveries with full test coverage.

→ [desktop-app/](desktop-app/) — Delivery plan structure, task specs, and the progression from 0 to 1,100+ tests across 6 deliveries.

**Key takeaway:** The Plan→Detail→Implement→Review→Test cycle produced consistent quality. Each delivery was self-contained, testable, and shippable.

## Data Pipeline

**Scenario:** A multi-brand e-commerce analytics pipeline with 12 specialist AI agents pulling from 5 data sources, validated against source data at 1% tolerance.

→ [data-pipeline/](data-pipeline/) — Pipeline architecture, agent specialization, quality gates, and the feedback loop that caught data accuracy issues before the client did.

**Key takeaway:** Track→Triage→Implement in action. Production monitoring caught a timezone mismatch and metric selection error. Formal triage led to targeted fixes, not a rebuild.
