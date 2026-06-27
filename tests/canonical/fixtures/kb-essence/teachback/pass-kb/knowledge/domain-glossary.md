---
kb-category: primary
source: hand-authored
objective: Teach-back PASS fixture spine -- all cross-source and synthesis candidate concepts defined.
summary: Fully-closed spine defining TokenRouter, DispatchQueue, PriorityBand,
  dispatch-acknowledgement contract, and event-fanout contract so closure-check output (a)
  is empty and the question set generated from candidate-concepts.md is fully answerable
  from this KB. The event-fanout contract is the synthesis-class concept that the fail-kb
  omits -- its presence here keeps the pass-kb fully closed even with the synthesis concept
  added to both candidate-concepts.md files.
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
Each token delivery fans out to all registered downstream listeners under the
event-fanout contract. The queue is the unit of back-pressure: if a lane is full
the TokenRouter blocks the client until capacity frees.

**Relates-to:** TokenRouter (the owner), PriorityBand (one queue lane per band),
event-fanout contract (the fanout guarantee enforced per delivery).

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

### event-fanout contract

**Definition-as-used-here:** The delivery guarantee that each token dispatched by the
TokenRouter is forwarded to all registered downstream listeners, not just the primary
consumer. The DispatchQueue enforces this contract on each dequeue: a token is only
removed from the queue head once all registered listeners have received their copy.
Listeners that do not acknowledge within the timeout are retried once; persistent
failures are logged and bypassed.

**Relates-to:** DispatchQueue (the fanout entry point), TokenRouter (the fanout
orchestrator), dispatch-acknowledgement contract (each fanout leg requires its own
acknowledgement).

**sources:**
- `src/router/token-router.ts`

---
