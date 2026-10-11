# task-007: Package one shared payload plus five agents-only artifacts in `release.sh`

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-2

**Depends on:** task-003, task-005

**Scope:**
Per REQUIREMENTS.md § 11 Feature 001 › Data Model › Release artifacts and Feature Flow › 1.
- `release.sh`: `build_shared_payload` writes `aid-shared-v<V>.tar.gz` holding, at the archive
  root: `aid-payload.conf` (`aid_version=<V>` only, from `VERSION`), `skills/**` (=
  `canonical/skills/**` as-is) and `runtime/**` (= `canonical/aid/**` as-is, `rules.md` included).
  The file set is `find canonical/skills canonical/aid -type f`, excluding `node_modules/`, `.git/`
  and dot-files. No transform, line-ending conversion or re-encoding. There is no wrapper
  directory, no `AGENTS.md` member and no layout-format constant.
- `build_tool_artifact` (replaces `build_tarball`) writes `aid-<tool>-v<V>.tar.gz` for each of the
  five tools: `aid-tool.conf` and `<root>/agents/**` from `profiles/<tool>/`. Nothing else.
- Archive layout: members carry no leading `./` and are relative to the archive root.
- The CLI bundle, `aid-install-core.sh` and `AidInstallCore.psm1` are unchanged; the `SHA256SUMS`
  glob is unchanged and covers every artifact.
- New flags `--stage-only [--out DIR]`: run steps 3 to 6 against the working tree as it is,
  skipping the clean-worktree check, tag checks, render, render-drift and every network step.
  `--dry-run` keeps its current preconditions. The release-notes stub and `--help` text describe
  the new artifact set, and the stub states `v4 requires CLI v4` (`VERSION` itself becomes 4.0.0
  through the normal release flow, not in this task).
- `.github/workflows/release.yml` step names/comments (search: "build the 5 profile tarballs") and
  `.claude/skills/release-aid/SKILL.md` (search: "Assets = 5 profile tarballs") describe the new
  artifact set.
- `tests/lib/bundle.sh` (new): a sourced helper, e.g. `aid_test_stage_bundle <out-dir>`, that runs
  `bash release.sh --stage-only --out <out-dir>` from the repo root; every suite that needs a
  release staging directory adopts it in its re-key task.
- `tests/canonical/test-release.sh`: re-key RL01 to RL03 to the new set and add RL cases for every
  AC-2 clause (see criteria); `--stage-only` on an uncommitted file. Renamed or removed keys get rows
  in `tests/coverage-accepted-removals.tsv`.

**Acceptance Criteria:**
- [ ] After `bash release.sh --dry-run`, the `*.tar.gz` files in `.aid/.temp/release-<V>/` are exactly `aid-shared-v<V>.tar.gz`, the five `aid-<tool>-v<V>.tar.gz` and `aid-cli-v<V>.tar.gz`; every one of them, plus both libs, is listed in `SHA256SUMS`, and `sha256sum -c SHA256SUMS` run in that directory passes.
- [ ] For each new artifact, `tar -tzf <artifact> | grep -c '^\./'` prints `0`.
- [ ] With the shared payload extracted to `<x>`, `diff -r -x node_modules -x '.*' <x>/skills canonical/skills` and `diff -r -x node_modules -x '.*' <x>/runtime canonical/aid` print nothing (no extra, missing or differing file under the payload exclusions), and `cmp <x>/runtime/rules.md canonical/aid/rules.md` succeeds.
- [ ] `aid-payload.conf` holds exactly `aid_version=<content of VERSION>`; the shared payload has no `AGENTS.md` member.
- [ ] Every per-tool artifact lists only `aid-tool.conf` and paths under `<that tool's root>/agents/`; `tar -tzf <artifact> | grep -cE '(^|/)skills/|/aid/'` prints `0` for all five.
- [ ] `bash release.sh --stage-only --out "$(mktemp -d)"` exits `0` on a working tree with an uncommitted new file under `canonical/skills/`, without network access, and that file appears in the shared payload; its release-notes stub contains `v4 requires CLI v4`.
- [ ] `bash tests/canonical/test-release.sh` exits `0`, and `bash canonical/aid/scripts/release/check-version-sync.sh` still exits `0`.
- [ ] All section-6 quality gates pass.
