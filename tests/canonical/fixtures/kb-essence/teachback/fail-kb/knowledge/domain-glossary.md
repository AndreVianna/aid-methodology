---
kb-category: primary
source: hand-authored
objective: Teach-back FAIL fixture spine -- TokenRouter definition intentionally OMITTED.
summary: Unclosed spine that defines DispatchQueue, PriorityBand, and the dispatch-acknowledgement
  contract, but OMITS the definition of TokenRouter. closure-check output (a) must report
  TokenRouter as ungrounded. Additionally planted as the engine-narration FAIL shape: every
  other concept defers to TokenRouter for the actual routing mechanism, so a coherent end-to-end
  account of how this system works cannot be constructed from this KB alone even though
  DispatchQueue and PriorityBand are lexically defined.
sources: []
tags: [test-fixture]
---

# Domain Glossary

## Concept Spine

<!-- NOTE: TokenRouter is intentionally OMITTED from this spine.
     This is the teach-back FAIL fixture: candidate-concepts.md names TokenRouter
     as a cross-source term (Spread=2), so kb-teachback-questions.sh emits
     "What is TokenRouter?", but this spine does not define it.
     closure-check.sh output (a) MUST report "TokenRouter" as ungrounded.

     ENGINE-NARRATION SHAPE: Every remaining concept defers the actual routing
     mechanism to TokenRouter. DispatchQueue says "owned by the TokenRouter" but
     does not say what the TokenRouter does. PriorityBand says "evaluated by the
     TokenRouter" but defers the routing logic. The dispatch-acknowledgement contract
     says "enforced by the TokenRouter" but cannot explain how without TokenRouter
     being defined. A reviewer attempting the fixed engine question -- "Explain how
     this system works, in its own language" -- cannot construct a coherent account
     because the central mechanism (what the TokenRouter does and how it routes) is
     absent. This is the un-narratable shape the M4 clean-context reviewer assesses. -->

### DispatchQueue

**Definition-as-used-here:** An ordered queue lane that the TokenRouter places tokens
into for downstream delivery. Each lane maps to one PriorityBand. The queue is the
back-pressure unit: when a lane is full, dispatch stalls. For the routing mechanism
that feeds this queue, see the TokenRouter (not defined in this KB).

**Relates-to:** TokenRouter (the queue owner -- see TokenRouter for how routing works),
PriorityBand (one queue lane per band).

**sources:**
- `src/router/token-router.ts`
- `docs/adr/0012-token-router.md`

---

### PriorityBand

**Definition-as-used-here:** A named urgency tier (HIGH, NORMAL, or LOW) that the
TokenRouter uses to select which DispatchQueue lane a token enters. The evaluation
logic lives inside the TokenRouter (not defined in this KB).

**Relates-to:** TokenRouter (the band evaluator -- the routing logic is in TokenRouter),
DispatchQueue (one lane per band).

**sources:**
- `src/router/token-router.ts`
- `docs/adr/0012-token-router.md`

---

### dispatch-acknowledgement contract

**Definition-as-used-here:** The delivery guarantee that a token is not considered
dispatched until the downstream service returns an acknowledgement. The enforcement
mechanism is inside the TokenRouter (not defined in this KB); the contract specifies
only the outcome, not the mechanism.

**Relates-to:** TokenRouter (the contract enforcer -- the enforcement logic is not
described in this KB), DispatchQueue (the re-queue target on timeout).

**sources:**
- `docs/adr/0012-token-router.md`

---
