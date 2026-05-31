---
name: prefer-derived-over-fixed
description: User strongly prefers derived/variable conventions over fixed/hardcoded assumptions in AID
metadata:
  type: feedback
---

In AID design decisions, the user consistently prefers **deriving things from
context over hardcoding fixed conventions**. Examples from work-001-adaptive-kb:
no fixed KB source-folder (discovery identifies sources), no fixed doc-count
(the 14/16 literals must be removed; the set varies by project type), and
derive-the-doc-set-then-confirm rather than a static menu.

**Why:** AID's whole thesis is that the KB should shape itself to whatever the
project is. Hardcoded counts/lists/folders contradict that and are treated as
bugs, not conveniences.

**How to apply:** When proposing a mechanism, default to "derive it + let the
user confirm" and avoid baking in fixed cardinalities, filenames, or folder
conventions. If a fixed default is needed, frame it explicitly as a *seed/
fallback*, not a universal invariant. Relates to [[always-recommend-with-rationale]].
