---
kb-category: primary
source: hand-authored
objective: Act-back FAIL fixture coding standards -- Conventions section ABSENT (buried).
summary: Coding standards for the EventPipeline project. The naming and registration
  conventions are described in prose paragraphs rather than a named Conventions section,
  so the operational-structure presence check reports Conventions as absent and the M4
  reviewer must guess or reach for source.
sources: []
tags: [test-fixture]
---

# Coding Standards

<!-- NOTE: The ## Conventions section is INTENTIONALLY ABSENT from this doc.
     This is the act-back FAIL fixture: the kb-actback-task.sh presence check
     reports coding-standards.md Conventions as absent, which is the structural
     cause of a sufficiency-limb FAIL during the M4 act-back review.
     The guidance is buried in prose below so a reader can find it only by
     careful reading -- not by grep or named section lookup. -->

This document describes code quality expectations for the EventPipeline project.

In general, new pipeline stages should use lowercase-hyphen naming and be registered
in the central registry file after implementation. Handler functions follow a standard
async signature pattern. Errors should be wrapped in a project error type. Fields added
to contracts should follow the project naming style and use optional markers where
appropriate. More details are available in the source files themselves.
