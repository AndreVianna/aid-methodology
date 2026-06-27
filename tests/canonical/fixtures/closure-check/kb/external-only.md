---
kb-category: primary
source: hand-authored
objective: Test KB doc with URL-only sources: entry.
summary: Used to test that URL sources produce N/A rows (no absent finding).
sources:
  - https://example.com/external-spec.html
tags: [test-fixture]
---

# External Only Doc

This document references Relative Bus but its only source is a URL.

No absent finding should be emitted for URL-sourced docs.
