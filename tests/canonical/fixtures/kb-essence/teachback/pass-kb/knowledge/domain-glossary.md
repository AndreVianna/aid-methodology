---
kb-category: primary
source: hand-authored
objective: Teach-back PASS fixture spine -- all cross-source candidate concepts defined.
summary: Fully-closed spine defining TokenRouter, DispatchQueue, PriorityBand, and the
  dispatch-acknowledgement contract so closure-check output (a) is empty and the
  question set generated from candidate-concepts.md is fully answerable from this KB.
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

### TokenRouter

**Definition-as-used-here:** The project-coined central dispatch component that
accepts inbound tokens from client connections, evaluates each token's target
affinity via its PriorityBand, places it into the appropriate DispatchQueue lane,
and waits for the dispatch-acknowledgement contract to be satisfied before releasing
the next token. No client sends a token directly to a service; all token delivery
is mediated by the TokenRouter.

**Relates-to:** DispatchQueue (receives enqueued tokens), PriorityBand (determines
which queue lane to use), dispatch-acknowledgement contract (the delivery guarantee
enforced per token).

**sources:**
- `src/router/token-router.ts`
- `docs/adr/0012-token-router.md`

---

### DispatchQueue

**Definition-as-used-here:** An ordered, single-consumer queue lane owned by the
TokenRouter. Each lane corresponds to one PriorityBand. Tokens enter the head of
their band's queue and are dispatched to the downstream service in arrival order.
The queue is the unit of back-pressure: if a lane is full the TokenRouter blocks
the client until capacity frees.

**Relates-to:** TokenRouter (the owner), PriorityBand (one queue lane per band).

**sources:**
- `src/router/token-router.ts`
- `docs/adr/0012-token-router.md`

---

### PriorityBand

**Definition-as-used-here:** A named tier that determines the urgency level of a
token and therefore which DispatchQueue lane it enters. Three bands are defined:
HIGH, NORMAL, and LOW. The TokenRouter evaluates each token's band label on
receipt and routes accordingly; the HIGH lane is drained before NORMAL, NORMAL
before LOW.

**Relates-to:** TokenRouter (the band classifier), DispatchQueue (one lane per band).

**sources:**
- `src/router/token-router.ts`
- `docs/adr/0012-token-router.md`

---

### dispatch-acknowledgement contract

**Definition-as-used-here:** The delivery guarantee enforced by the TokenRouter: a
token is not considered dispatched until the downstream service returns an
acknowledgement signal. The TokenRouter holds the slot open until that signal
arrives. If no acknowledgement arrives within the timeout, the token is re-queued
once at the back of its DispatchQueue lane before being marked failed.

**Relates-to:** TokenRouter (the contract enforcer), DispatchQueue (the re-queue target).

**sources:**
- `docs/adr/0012-token-router.md`

---
