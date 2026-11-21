# Codex benchmark profile

The table selects one plain and one completed lean run for each notes scenario;
all six passed the hidden checks. Two earlier lean fix attempts stopped at
trust and failed their hidden checks; their original results and raw evidence
remain saved as `bench-fix-01-lean` and `bench-fix-02-lean`. The completed lean
runs include factual native-preflight context in their task prompts; the
plain runs do not. The lean fixtures lacked a project card, so those results
do not establish a correct card flow.

| Scenario | Plain model calls | Lean model calls | Plain input | Lean input | Lean preflight input |
|---|---:|---:|---:|---:|---:|
| Fix | 5 | 18 | 76,921 | 775,170 | 105,125 |
| Feature | 5 | 28 | 79,279 | 1,012,055 | 105,102 |
| Complex | 5 | 36 | 92,265 | 1,469,646 | 105,096 |

Input counts include cached input and sum the `last_token_usage` records in
the main session. They are not dollar prices or proof of total helper-agent
usage. The separately recorded preflight is not included in the task total.
The original complex result reported 1,929,486 by adding its first turn to an
already cumulative second-turn total. It is retained unchanged as historical
evidence; 1,469,646 is the raw main-session total.

The fix run made 15 shell calls and returned approximately 109,156 characters
of command output. A broad inventory returned 42,996 characters including Git
internals; a combined file read returned 43,119. The feature and complex runs
made 22 and 23 shell calls and returned about 84,589 and 82,802 output
characters respectively. These observations identify candidates to test, not
a causal breakdown of token use.

The raw results and per-turn transcripts are under
`.aid/.temp/aid-gate-codex-fresh-20261027/.aid/.temp/bench-*.jsonl` and
`codex-benchmark-final-20261027/*/codex-raw/`. Private session rollouts provide
the per-inference usage records. Complex plan approval was simulated by the
driver, not provided by a human during the run.

Candidate reductions: provide a truthful project card; target discovery and
read only relevant sections by default; keep the tests-first, state, checks,
independent whole-result review and safeguard requirements. The reviewer-model
retry in the complex run is a separate host-compatibility issue. A fresh
paired comparison must disclose the changed card and instruction context and
preserve the same application source, scenario and grader.

## Updated paired trials

After adding the card and targeted-discovery guidance, one fresh plain and one
lean run were taken for each of the fix and complex scenarios. The application
source and test Git trees matched the original plain baseline and the same
hidden graders were used. The lean fixture commits and installed context
changed; the plain and lean commits were not identical. The fix used the
previously approved `feature-02` fixture path, relabeled as the fix scenario.

| Scenario | Plain input | Lean input | Plain calls | Lean calls | Hidden checks |
|---|---:|---:|---:|---:|---|
| Fix | 61,415 | 650,316 | 4 | 18 | Both pass |
| Complex | 96,881 | 1,623,820 | 6 | 40 | Both pass |

Inputs include cached tokens. The separate lean preflights reported 105,111
and 105,100 input tokens. USD cost and complete helper-agent usage remain
unavailable. One sample per arm cannot establish a reliable average or prove
that the context changes caused a difference. Both lean fixtures used a
benchmark-provided account of their verified native preflight.

The updated fix read the card and returned approximately 76,243 characters of
command output, versus 109,156 in the earlier lean fix; its discovery listing
fell from 42,996 to 8,174 characters. Both still made 15 shell calls, and
the updated fix made 18 model calls, equal to the earlier lean fix. The
updated complex run used 40 model calls versus 36 previously. The main
workflow overhead therefore remains unresolved.

Complex plan approval was simulated by the driver. The updated complex result
ended asking for final approval, so its hidden-check pass is not approval of
the work. The project card was available, but the agent reported missing
authoring criteria and connector registry files. A later reviewer-model
fallback clarification is outside these measured fixtures and has no new live
behavior proof. Native Windows and non-Git safeguard enforcement remain
unverified.
