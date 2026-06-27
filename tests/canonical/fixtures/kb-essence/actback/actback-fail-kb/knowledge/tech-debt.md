---
kb-category: primary
source: hand-authored
objective: Act-back FAIL fixture tech-debt doc -- Gotchas section ABSENT (buried).
summary: Known risks for the EventPipeline project. The gotchas are mentioned as
  prose paragraphs rather than a named Gotchas section, so the presence check
  reports tech-debt.md Gotchas as absent and the M4 reviewer may step on traps.
sources: []
tags: [test-fixture]
---

# Tech Debt and Known Risks

<!-- NOTE: The ## Gotchas section is INTENTIONALLY ABSENT from this doc.
     This is the act-back FAIL fixture: kb-actback-task.sh reports tech-debt.md
     Gotchas as absent. The non-obvious traps are buried in prose paragraphs
     rather than a named, greppable section, so the M4 reviewer cannot reliably
     identify them when planning a contract change.
     tech-debt.md is the default Gotchas owner per the owning-table (C7). -->

This document captures known issues and technical debt in the EventPipeline project.

There are some things to be aware of when making changes. When adding a new required
field to the Event schema you also need to update the entry-stage validator or invalid
events will pass silently. The registry file needs to be updated in the same commit as
the new stage or the stage will be silently skipped. TypeScript unknown payload fields
need type guards or you will get runtime errors. Schema version bumps should be
reflected in the API spec or a CI check may fail. These details are important to
keep in mind but can be found by reading through the source code carefully.
