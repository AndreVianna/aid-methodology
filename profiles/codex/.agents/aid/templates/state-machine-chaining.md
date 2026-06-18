---
kb-category: meta
source: hand-authored
intent: |
  Defines the auto-chain rule that all AID skills follow when their state machines
  advance. Each AID skill (`/aid-discover`, `/aid-summarize`, etc.) is internally
  organized as a state machine — states are useful conceptual phases — but a single
  invocation of the skill drives through as many states as it can until it hits a
  natural pause point. Without this rule, every state boundary forces a re-invocation,
  which becomes red tape on happy-path runs (e.g., 5+ `/aid-summarize` invocations
  to take a fresh KB through PREFLIGHT → DONE). This doc is the single source the
  per-skill SKILL.md files cite.
contracts: []
changelog:
  - 2026-05-28: Initial — codifies the chain-when-possible rule across all skills
---

# State Machine Chaining Rule

**One skill invocation drives the state machine to the next natural pause point — not to the next state boundary.**

States exist for organizational clarity (grouping related work, defining transitions, giving names to phases). They do NOT exist to gate user attention. Forcing the user to re-type `/aid-<skill>` between every state is red tape: on a clean happy-path run of `/aid-summarize`, the user would need to re-invoke 7 times (PREFLIGHT → STALE-CHECK → PROFILE → GENERATE → VALIDATE → MANUAL-CHECKLIST → APPROVAL → WRITEBACK → DONE) for a single Knowledge Base summarization. That's wrong.

## The four advance types

Every `**Advance:**` line in a `state-*.md` reference doc declares one of four advance types:

### 1. CHAIN (auto-advance inline)

The state's work is done; the next state can begin immediately within the same invocation. The orchestrator does NOT exit — it begins executing the next state's reference doc.

```
**Advance:** → [State: X] (continue inline).
```

Use for:
- Mechanical states (validators, file operations, computations).
- States whose user interaction is fully `AskUserQuestion`-based (the question is asked inline; the answer is collected inline; the next state proceeds inline).
- Any transition where there is no reason for the user to type `/aid-<skill>` again.

### 2. PAUSE-FOR-USER-ACTION

The next state requires the user to do something OUTSIDE the chat that the orchestrator cannot trigger:
- Run an external tool, deploy script, or CI job that takes time.
- Browse to an artifact for a manual inspection (rare — most visual inspections can happen inline if the orchestrator surfaces the file via `SendUserFile`).
- Edit a file the orchestrator should not edit (per the [[dogfood-setup-only]] rule, or any user-owned content).
- Run another `/aid-<other-skill>` first (cross-skill loopback).

```
**Advance:** Stop here. Re-run `/aid-<skill>` after {one-line condition} to continue to [State: X].
```

The orchestrator prints the pause reason and exits.

### 3. PAUSE-FOR-USER-DECISION

The next state depends on a decision the user is expected to deliberate on rather than answer reactively — usually because they want to look at findings, sleep on it, run their own analysis, or it's a contracted checkpoint (e.g., feature-002 SPEC §IQ9 in `aid-interview`). Even though the underlying action might be a single `AskUserQuestion`, the methodology specifies a deliberate stop.

```
**Advance:** Stop here (contracted checkpoint per {citation}). Re-run `/aid-<skill>` to continue to [State: X].
```

This type is rare — use only when a SPEC or memory rule explicitly requires the pause.

### 4. HALT

Terminal state. State machine is finished for this run.

```
**Advance:** → halt.
```

## How orchestrators apply this

On entering a state's reference doc:

1. Execute the state's work (including any inline `AskUserQuestion` exchanges).
2. Read the `**Advance:**` line.
3. If CHAIN: print a short transition line (e.g., `→ Advancing to [State: X]`), then begin executing the next state's reference doc within the same response cycle.
4. If PAUSE-FOR-USER-ACTION or PAUSE-FOR-USER-DECISION: before printing the pause reason, emit the pipeline pause signal (silent state-write — no output, no gate):
   ```
   bash .agents/aid/scripts/execute/writeback-state.sh --pipeline --field Lifecycle --value "Paused-Awaiting-Input"
   bash .agents/aid/scripts/execute/writeback-state.sh --pipeline --field "Pause Reason" --value "<short reason — the same condition the state's Advance line names>"
   bash .agents/aid/scripts/execute/writeback-state.sh --pipeline --field Updated --value "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
   ```
   Then print the pause reason, the resume command, and exit.
5. If HALT: print the closing summary and exit.

## Failure and FIX-loop semantics

When a grade is below minimum or a check fails, the natural advance is to a FIX state. The FIX state itself follows the same chain rule:

- If FIX work is mechanical (apply a known fix, re-run the validator) → CHAIN back to the previous validation state.
- If FIX requires user deliberation about what to change → PAUSE-FOR-USER-DECISION.

Do not invent a third pattern. The four advance types above are exhaustive.

## Anti-patterns

❌ **Per-state re-invocation as a "safety pause".** The state machine is not a UI throttle. If the user wants to interrupt, they can — `AskUserQuestion` and standard chat interruption already provide that surface.

❌ **PAUSE-FOR-USER-ACTION when the action is just answering a question.** Questions belong in `AskUserQuestion`, which is inline. A pause is only legitimate when the user has to do work outside the chat.

❌ **Mixing CHAIN and PAUSE in the same Advance line.** Each transition is exactly one type. If a state's next-step depends on a condition, split: "if X → CHAIN to [State: A]; if Y → PAUSE to [State: B]". Both branches must be explicit.

## Cite this doc from each SKILL.md

Every skill's `SKILL.md` Dispatch section should include the line:

```
> **State-machine chaining:** Each `/aid-<skill>` invocation drives the state
> machine until it hits a natural pause point per
> `.agents/aid/templates/state-machine-chaining.md`. Mechanical and inline-question
> states auto-chain; only PAUSE-FOR-USER-ACTION / -DECISION / HALT stop the run.
```

This replaces the legacy "each `/aid-<skill>` run does ONE step and exits" rule.
