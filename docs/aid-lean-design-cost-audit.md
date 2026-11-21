# Lean AID: focused design and cost audit

This audit uses existing local runs and source inspection. It did not start a
model or change AID's behavior. The recommendations below are proposals; none is
an approved removal of a safeguard, test, independent whole-result review, or
human approval boundary.

## What the evidence shows

- In one saved Codex fix pair, both arms passed their hidden checks. Plain
  reported 61,415 input tokens, including 54,528 cached, and 749 output tokens
  in 27.3 seconds. Lean reported 650,316 input, including 586,240 cached, and
  2,548 output in 119.2 seconds. Lean's separate safeguard probe reported
  another 105,111 input tokens, including 90,112 cached. These are single
  samples with different installed context, not a controlled estimate of the
  cost of each AID feature; no dollar price was reported.
- In one saved complex pair, both passed the hidden checks. Plain reported
  96,881 input tokens in 53.8 seconds; lean reported 1,623,820 in 327.2 seconds,
  plus a separate 105,100-input safeguard probe. The lean result was still
  awaiting final approval, and an earlier plan approval was simulated.
- In the recent two-page site trial, the main session recorded **at least**
  7,457,814 input tokens, including 7,354,880 cached, and 28,788 output before
  timing out. Subtracting the reported cached input leaves 102,934 input tokens;
  cached input is not necessarily free. One helper separately reported
  954,784 input tokens; its overlap with the main counter is unknown. The
  separate safeguard probe reported 103,517 input. An additional helper had no
  available counter. These figures cannot be summed into a verified account or
  billing total, and Codex supplied no dollar cost.
- The interrupted site retry recorded 67 completed shell commands, of which 13
  returned nonzero; some were intentional red checks or pre-existing failures.
  Their captured output was about 193,199 characters, with about 113,829 from
  the five largest responses. Characters are not tokens, and this does not
  establish how much of the session's usage any individual command caused.
  Large responses included complete generator, state-template and rule excerpts
  despite the current instruction to use targeted reads.
- The initial site turn asked whether to start new work. The next turn stopped
  because the disposable fixture lacked the local `master` branch required by
  the gate. Together those two turns had accumulated 380,217 input tokens,
  including 340,736 cached. The missing branch was **our fixture error**, not
  an AID defect; these cumulative tokens are already in the main-session total.
  A later exact-gate preflight passed after the fixture was corrected.

The older plain/full-AID/lean site runs used different models and environments.
The two-page updated-lean trial had no matching plain arm, an open evaluator,
pre-existing generator/test failures, and no completed final review. Neither
establishes a causal quality advantage or a full-site result.

## Value and simplification opportunities

| Area | Evidence and value | Proposed next step and boundary |
| --- | --- | --- |
| Project knowledge | The site run consulted the project card and KB, but its earlier output still omitted useful skill detail. The newer two-page drafts explain substantially more; no plain control establishes the cause. | Keep targeted KB retrieval and source checks. Return a compact list of relevant facts, locations and conflicts; avoid dumping unrelated files. Measure whether facts reach the outcome check. |
| Whole-result review | A separate content review caught a nonexistent example path in the two-page draft; it was fixed. The earlier site review missed rendered table defects. | Keep the independently performed whole-result review and its evidence. Give it the request, changed result and a small evidence bundle once; require source/content and rendered checks when applicable, with unrun checks disclosed. Do not substitute a build or a headings test for content coverage. |
| Baseline and test comparison | The site task ran broad tests before and after, but the baseline helper rejected its newly created state file and dependency symlink. It allows only stable, individually hashed non-symlink files; the agent instead compared JUnit manually. | Make workflow-owned mutable state and fixture dependencies compatible with baseline capture through narrow, explicit handling. Keep user files protected, verify dependency identity, and compare failure identities and test counts; never broadly ignore untracked files or waive a failure. Use a relevant focused set first and retain any full-suite check required by the project or risk. |
| Starting and resuming work | New direct work invokes the shared gate, while a related continuation can reuse its active state. The compact direct-state path is locally implemented and compatibility-tested in part, but its live cost and resume behavior are not proven. | Pilot one compact state record and reuse it for genuine continuations. Consider avoiding a redundant question only when the user has explicitly chosen new work and the protocol permits it; preserve enumeration, truthful state, isolation and fail-closed behavior. Any exception is a future protocol change, not current behavior. |
| Safeguard and trust | The native fixture probe allowed an inert status command and blocked inert push and merge. This proves that fixture's direct-command behavior, not a production incident prevented or protection on every host. | Keep the approval boundary and the per-fixture trust verification previously requested by the user. The driver already rechecks verified identity on each turn: reuse that identity only within the same unchanged fixture. Investigate a cheaper native verification only if it demonstrates equivalent enforcement; a config hash alone is not proof. Report probe usage separately. |
| Repeated context and coordination | The trace contains large tool responses, two reviewer starts including an unsupported-model fallback, and repeated baseline/build work. The agent did fix one independently identified content issue. | Bound reads and reviewer inputs; resolve supported reviewer selection before dispatch where possible, while preserving independent review and its criteria. Reuse a baseline only when its exact source, commands, dependencies, environment and evidence match. These are hypotheses, not measured savings. |

## Recommended order

1. Fix the site generator's nested-frontmatter incompatibility and repair the
   fixture setup separately, with a real build and tests. A fixture preflight
   must exercise the **actual** worktree gate, browser, generator and chosen
   checks before a model run. Preserve failed attempts and their usage.
2. Design a narrow baseline/state/dependency compatibility change and bounded
   evidence handoff. Verify offline that source changes, new failures and missing
   evidence still fail closed; retain existing review and approval protections.
3. On one small, realistic task, run one matched plain/lean pair with the same
   model, starting source, KB access, tools, limits and explicit quality rubric.
   Preflight before either run, count each fixture's safeguard probe separately,
   and stop after the pair to inspect results before authorizing more runs.
   Check correctness, completeness, rendered usability and unchanged behavior;
   label the evaluation open unless grader isolation is actually verified.
4. Record main, cached and uncached input, output, available helper counters,
   wall time, completion and any reported cost. Do not add overlapping session
   counters or equate cached tokens with dollars. Retain only a proposed
   simplification that shows useful quality or safety at an acceptable cost;
   incomplete results remain inconclusive.

The implementation contracts inspected were
[`aid-change`](../canonical/skills/aid-change/SKILL.md), its
[review reference](../canonical/skills/aid-change/references/review.md), the
[work-initiation gate](../canonical/aid/templates/work-initiation-gate.md),
[`checks.py`](../canonical/aid/scripts/change/checks.py), and the
[measurement driver](../tests/measure/measure.py). Results are recorded from
the local benchmark artifacts available at audit time; those temporary artifacts
may be cleaned, so the observations and limitations are summarized above.
