# Plain-first opt-in trial

This is an experimental source-tree trial, not part of the ordinary AID
release. Use a disposable project first. It reuses existing AID state, knowledge,
grading and safeguards; it does not replace the default workflow.

The target must already have AID installed, with the state initializer, work
gate, direct template, settings reader, state writer, grader and safeguard
scripts matching the current trial source. Shell prerequisites must use LF.
The installer reads and compares these files; it does not execute project code
for its preflight or update an older installation. It refuses linked runtime
paths and an existing `aid-outcome` skill.

```bash
python3 experiments/aid-plain-first/trial_install.py install --project '<project-root>'
```

Installation places the skill and its helpers under that project's
`.agents/skills/aid-outcome/`. The skill contains a Claude hook declaration.
The installer does not modify host hook configuration or trust settings; follow
the host's trust and authorization process before allowing the hook to run.
File presence alone does not prove a host loaded the skill or enforced the hook.

To reverse the trial's filesystem installation:

```bash
python3 experiments/aid-plain-first/trial_install.py remove --project '<project-root>'
```

Removal first refuses changed, missing, linked or extra trial files. It then
moves the entire trial directory to a fresh `.aid/.temp/aid-outcome-quarantine-*`
directory and reports its path; it does not recursively delete files. An edit
arriving after the check is preserved in the moved directory. Running host
sessions may retain a loaded skill or hook, and the command does not alter
hook configuration or trust. Inspect the quarantined files before any separate
cleanup or restoration. If installation stops partway, it preserves the partial
directory and reports it instead of overwriting or automatically removing it.
Removal also refuses when the experiment's source files have changed since
installation; inspect the installed files and use the matching source version
or handle their preservation explicitly before removing them.

The installed work gate distinguishes `aid-outcome` from `aid-change` only if
the matching gate update is present. The trial installer checks the gate's
source bytes. One Codex diagnostic selected the intended route for an existing
work; that observation does not establish consistent routing or full workflow
acceptance. Host-specific trust, enforcement, worktree allocation and agent
behavior must be separately verified; unavailable evidence remains unverified.

For Codex CLI trials that require a subagent review, use a normal persisted
session rather than `codex exec --ephemeral`: an isolated WSL trial with
ephemeral mode failed to start its reviewer because no rollout was found,
while a small saved-session probe started a subagent and received its reply.
This is a tested workaround, not a guarantee that every review will start.
Session records persist in the selected `CODEX_HOME`; choose an appropriately
isolated home and protect its contents. Verify the actual review result and
keep the work unverified if the reviewer cannot start or does not finish.

The skill's compact `references/review.md` describes a fresh independent
reviewer, evidence map and unchanged whole-result checks. The host must provide
the direct-session dispatch; the trial installer does not create a new host
launcher or change the normal workflow.
