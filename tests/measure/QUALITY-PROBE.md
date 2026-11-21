# Lean AID: small documentation quality probe

This is a low-cost follow-up to the site trial. It prepares a disposable local
release-guide task, without starting a model. The fixture has a project card,
one relevant KB document, a local-only release tool, an existing test and a
guide with a broken table. The requested result must be useful to a new
maintainer, not merely free of a warning.

## Prepare and validate

From the repository root, with Python 3.8 or later:

```sh
python3 tests/measure/test_quality_probe.py
python3 tests/measure/quality_probe.py prepare .aid/.temp/quality-probe-trial
python3 tests/measure/quality_probe.py grade .aid/.temp/quality-probe-trial/project
```

`prepare` refuses to overwrite an existing directory. It writes a public task
to `request.txt` outside `project/`; give the task to the agent, not this grader
or its example answer. The initial guide must fail the grader. Initialize the
project's own Git repository and install the selected AID version using the
normal installer before running an agent. Preserve the prepared starting tree,
installed skill hashes, configuration, exact prompt and complete event stream.
Trust a new fixture and its hooks only with the owner's authorization.

## Compare

Start with one pair as a diagnostic: the previous lean instructions and the
updated instructions, each in a fresh fixture from the same prepared inputs.
Use the same host, model, settings, task prompt, tests and time/turn limit for
both. Keep the grader and its answer example outside both agent workspaces.
Outside the workspace does not necessarily mean unreadable: verify filesystem
read isolation and inspect the event stream for grader access. If isolation
cannot be established, label the evaluation open rather than hidden and report
possible answer exposure.
Record any extra instructions, approval replies, unavailable tools, interrupted
runs and setup/probe usage separately. Do not silently retry a failed run or
pick a later success. If results are inconclusive, decide whether additional
paired runs justify their usage before running them.

For each result, run the existing fixture tests and the `grade` command above.
The grader checks an ordered example workflow, mention of human approval, a
table with a scoped header and nonempty data, absence of a visible-by-markup
raw table separator, and an unchanged release tool. Its
`automated_pass` is **partial**: it does not prove semantic accuracy, KB use,
browser rendering or accessibility. It always reports browser visual checking
as not run.

Independently inspect the rendered page in a real browser where available, and
check that a maintainer can actually follow the guide and that approval is
required before publication. Inspect the event stream for the KB read, its use
in the checks, and truthful treatment of unexecuted checks; a correct page alone
does not prove how the agent produced it. Record each as pass, fail or not run
with evidence. A browser, transcript, or other required evidence that is
missing remains not run; do not infer success from the static grader.

Report both task correctness and the limits of the comparison. Record wall time,
model usage including cached input and helper calls when known, and actual cost
only when the host reports it. One pair cannot establish a reliable cost or
quality improvement. Do not change the original site benchmark or its results.
