---
name: always-recommend-with-rationale
description: When presenting a multiple-choice decision, always mark a recommended option and give the rationale
metadata:
  type: feedback
---

When asking the user to choose between options (e.g. AskUserQuestion design
decisions), always indicate which option I recommend and give a short rationale —
don't present neutral options and leave the choice fully open.

**Why:** The user wants my engineering judgment surfaced, not just a menu. A bare
list of trade-offs makes them do the synthesis I should have done.

**How to apply:** Make the recommended option first, append "(Recommended)" to its
label, and put the rationale in its description (and/or the question text). Still
present the real alternatives honestly.
