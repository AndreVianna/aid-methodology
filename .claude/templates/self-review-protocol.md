# Self-Review Protocol

> **Source:** PR #15 review-loop lesson (4 rounds plateaued at grade D because
> agents shipped work that downstream reviewers had to discover bugs in, instead
> of agents adversarially reviewing their own work before handing off).
>
> Every AID agent that produces an artifact (code, docs, configs, KB entries,
> extracted data, rendered output, etc.) follows this protocol. Reviewers
> (`aid-reviewer`) and pure coordinators (`aid-orchestrator`) are
> exempt — they don't produce primary artifacts.

## The posture

The downstream reviewer is **verification, not discovery**. If a reviewer
surfaces an issue you should have caught, that is a self-review gap — not a
normal step of the pipeline. Your objective is to hand work to the reviewer
that contains nothing for it to find.

## The five rules

### 1. Read contracts end-to-end before editing

For every file you modify or produce, understand the contracts it participates
in: the schema, parser, renderer, build step, validator, or downstream consumer
that touches its content. Trace what flows through what. Do not edit by
pattern-match on the bug or task description — read the surrounding code.

If you are editing a file that flows through a transform (renderer, template
engine, regex rewriter, lint, build, formatter), read the transform's source
and confirm what it does and does not touch. The most common self-review gap
is: edited a field assuming the transform would handle it; transform didn't
touch that field; rendered output broken.

### 2. Enumerate the class, not the instance

When fixing or producing anything, ask: "what is the **class** of this change?
what other shapes of this class exist in the codebase?" The reviewer almost
always cites ONE instance of a bug class — your job is to find the rest.

Grep for every plausible shape of the class. Multiple regexes if the class has
multiple syntactic forms. List every match. Address every match — do not leave
siblings for the reviewer to surface.

Example: "this skill body uses bare `bash scripts/...` instead of
`bash .claude/scripts/...`." Don't just fix the cited file. Grep:
`grep -rn "bash scripts/" canonical/` and fix every site. Then grep
`grep -rn "\`scripts/" canonical/` for backtick-quoted siblings. Then grep
`.aid/scripts/` for misrooted variants. Enumerate the class, not the instance.

### 3. Read what you actually produced

Before declaring done, **read the artifact you just produced** — not the
source you wrote, the output that consumers will see. Do not trust the
source-side change to produce the intended output.

- Full agent changing code or docs that flow through a transform (renderer,
  template, regex, build): execute the transform, then `cat` at least one
  rendered file to confirm the output reads sensibly. The "renderer ate its
  own comment" pattern is caught here.
- Full agent producing a test or script: execute it, read the actual output
  (not just the pass/fail summary).
- Utility sub-agent (`aid-clerk`): read the table/list you emitted. Confirm
  the schema matches what the caller requested. Spot-check at least one row
  against the source it was extracted from.
- Doc change that includes prose ABOUT a transform: render the doc, confirm
  the transform did not mangle the prose.

### 4. Confirm the contracts you participate in still hold

Before declaring done, list the contracts your output satisfies (or your
change touches) and confirm each holds. Inventories beat memory.

For full agents producing code, docs, configs, or KB entries:
- Schema invariants — does the YAML/JSON/TOML still parse?
- Path conventions — do all referenced paths resolve in every consuming context?
- Naming conventions — does every name match the project's conventions?
- Cross-file references — do all `file.ext:line` cites still point at real lines?
- Test contracts — do tests still pass for changed AND unchanged behaviors?
- Renderer/build determinism — does a second render produce byte-identical output?

For utility sub-agents producing extracted/formatted data:
- Schema match — does every row carry the fields the caller named?
- Count accuracy — if you reported "47 files searched, 0 matches," does
  the search actually cover 47 files?
- Cite integrity — every row's file/line cite resolves to a real location.
- No interpretation — output is mechanical extraction; no inferences,
  judgments, or fabrications.

### 5. Find nothing more to find before handing off

A task is done when an honest adversarial sweep of your own work surfaces
nothing new — **not** when the items on the original task list are addressed
and the obvious checks pass.

Before declaring complete, ask: "if I were the reviewer entering this with
clean context and a brief to find every problem, what would I find?" Then go
find it. If you find nothing, you can hand off. If you find anything, you are
not done.

## What this is NOT

- This is not "review forever." If after an honest sweep you find nothing,
  hand off. The downstream reviewer is still useful — it's a fresh pair of
  eyes that may catch what your tired ones missed. The point is to make that
  catch the **exception**, not the **expected step**.
- This is not "block on perfection." Some defects are out of scope for the
  current task. Flag them, document them, hand off the in-scope work. The
  rule is "find nothing more to find **in the task's scope**," not "fix
  every defect in the codebase."
- This is not a substitute for the reviewer. The reviewer has clean context,
  no investment in your framing, no commitments to defend. It will catch
  things you cannot see precisely because you authored them. The point is
  to spend your own budget on adversarial reading **of your own work**
  before invoking the reviewer's budget.

## Why this lives at the agent level

Per-agent because every artifact-producing agent has the same failure mode:
edit → run obvious test → ship → let the reviewer discover what was missed.
The discipline cannot live at the skill level because skills dispatch agents
and trust the agent's output — by the time the skill sees the work, the
agent has already declared it done. The posture must be the agent's, not
the dispatcher's.

## See also

- `.claude/templates/reviewer-dispatch.md` — the reviewer's protocol; the
  flip-side of this one (what the reviewer is dispatched to do; this doc is
  what the agent should have done before reviewer dispatch was needed).
- `.claude/templates/subagent-heartbeat-protocol.md` — the heartbeat
  protocol; same authoring pattern (canonical source + per-agent reference).
