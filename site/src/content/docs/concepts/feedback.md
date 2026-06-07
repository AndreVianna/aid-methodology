---
title: "Feedback & reporting issues"
description: "How to report documentation issues or give feedback on AID — a no-backend, prefilled-GitHub-issue path with no account required beyond GitHub."
reportIssue: false
sidebar:
  order: 99
  label: "Feedback"
---

Found a problem with the AID documentation? Have a suggestion? Use the **"Report an issue"** link at
the bottom of any page, or the button below, to open a prefilled GitHub issue — no backend, no extra
account, just GitHub.

## How it works

Every documentation page carries a **"Report an issue with this page"** link in the footer.
Clicking it opens GitHub's issue-creation form with:

- The **page title** pre-filled in the issue title (e.g. `[Docs] Installation`).
- The **originating page URL** pre-filled in the *Originating page* field.
- Labels `documentation` and `feedback` applied automatically.
- A structured form (type, description, expected outcome) to keep triage consistent.

You review the pre-filled details, add anything missing, and submit directly on GitHub.
No token, no server, no hidden data collection.

## What happens after you submit

Issues land in the [AID methodology repository](https://github.com/AndreVianna/aid-methodology/issues)
labelled `documentation` + `feedback`. Maintainers triage them alongside code issues and update
the documentation in a future release.

## General feedback (not tied to a specific page)

Use the link below to open a blank feedback issue — the type, description, and expected fields
are ready for you to fill in:

<a href="https://github.com/AndreVianna/aid-methodology/issues/new?template=feedback.yml&title=%5BDocs%5D%20Feedback&labels=documentation%2Cfeedback&description=" target="_blank" rel="noopener">Open a feedback issue on GitHub &rarr;</a>

## Scope note

The **"Report an issue"** link is for documentation feedback only. For bugs in AID itself,
use the same form and select **"Bug in AID itself"** as the type — it routes to the same
triage queue.

"Edit this page" links are intentionally absent: the documentation is generated from
canonical sources, and direct edits to rendered pages would be overwritten. If you spot a
problem, a feedback issue is the right path.
