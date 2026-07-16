# Agent Dispatch Tiering — difficulty → (model tier, effort)

The single rubric every dispatch site consults to pick a sub-agent's **model tier**
and **reasoning effort** from the task's difficulty. Default to the low end;
escalate only on the listed triggers. Two independent levers — tuning **effort** is
often a better lever than switching model tiers, and lower effort also means fewer
tool calls and less preamble (compounding savings in agentic loops).

## The rubric

| Difficulty | Tier → model | Effort | Signals |
|---|---|---|---|
| **Mechanical** | small | `low` | extract / format / glob / lookup; one small file; deterministic |
| **Routine** (default) | medium | `medium` | the common case: a scoped change, a normal doc, a single-file implementation, a standard review |
| **Retrieval-heavy** | medium | `low` | research / cataloguing / analysis / KB authoring / web search — depth does **not** help retrieval, so keep effort low |
| **Hard** | large | `high` | complex reasoning, security / performance, multi-file / cross-cutting, a full PR or design review, requirement synthesis |
| **Frontier** | large | `xhigh` | long-horizon decomposition, hard architecture, deep multi-step coding |

`max` effort is reserved — never a default; opt in only when evals show headroom at
`xhigh`.

## Rules

- **Default low, escalate the hard minority.** Most work is Routine (medium/medium)
  or Retrieval-heavy (medium/low). Reserve `large` + `high`/`xhigh` for the triggers
  above.
- **Reviewer tier ≥ executor tier — escalate both together.** If a task is Hard or
  Frontier, its executor *and* the reviewer of that output take the higher tier.
  Reviewing a `large`-tier executor's output pulls the reviewer to `large`. (Grade
  is computed by `grade.sh`, not the model — the reviewer's tier affects finding
  quality, not the grade arithmetic.)
- **Effort is applied per host:** on **codex** it is baked into the per-tier
  `model_reasoning_effort` the renderer emits; on the **markdown hosts**
  (claude-code, cursor, copilot-cli, antigravity) the renderer emits no effort field,
  so effort is a **dispatch-time** parameter the dispatcher sets. A dispatch that does
  not set effort inherits the host default (`high`) — so a dispatch site that wants a
  lower default **must set it explicitly** (this is why the skills, not the profiles,
  carry the effort defaults on the markdown hosts).

## Per-agent defaults

The agent's frontmatter `tier:` sets its default model; the dispatch site sets effort
(and may escalate the tier per the rules above).

| Agent | Default tier | Default effort | Escalate |
|---|---|---|---|
| aid-clerk | small | `low` | — |
| aid-orchestrator | medium | `low` | — |
| aid-tech-writer | medium | `low`→`medium` | large / `high` (large or complex docs) |
| aid-operator | medium | `medium` | large / `high` (risky release / verification) |
| aid-developer | medium | `medium` | large / `xhigh` (cross-file / hard implementation) |
| aid-researcher | medium | `low` | large / `high` (genuinely deep analysis only) |
| aid-interviewer | medium | `medium` | large / `high` (complex requirement synthesis) |
| aid-reviewer | medium | `medium` | large / `high`–`xhigh` (complex / security / design / delivery gate, or to match a large executor) |
| aid-architect | large | `medium` | large / `xhigh` (hard design / decomposition) |

## See also

- `.aid/knowledge/architecture.md § Agent / Sub-Agent Dispatch Model` — the tier
  roster and the reviewer ≥ executor invariant this rubric enforces.
- `.codex/aid/templates/dispatch-protocol-checklist.md` — the dispatch *mechanics*
  (ETA lookup, heartbeat file, L2 timers) that run once the tier/effort is chosen.
