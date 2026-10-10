# task-008: Stage and validate the release artifacts in the CLI (no destination writes)

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

**Source:** work-001-shared-skills-folder -> delivery-001 -> AC-3, AC-12

**Depends on:** task-004, task-006, task-007

**Scope:**
Bash and PowerShell twins together, per REQUIREMENTS.md § 11 Feature 001 › Feature Flow › 2 and
Data Model › Validation.
- `fetch_artifact` / `Fetch-AidArtifact` (new; `fetch_tarball` becomes a thin wrapper). Online:
  fetch `aid-shared-v<V>.tar.gz`, each target tool's `aid-<tool>-v<V>.tar.gz` and `SHA256SUMS`,
  fail-closed as today; `AID_ALLOW_ENDPOINT_OVERRIDE` gating unchanged. A missing shared artifact
  exits 3 with exactly `release v<V> has no shared payload -- it predates the shared layout and cannot be installed by this CLI; omit --version or use an older aid CLI`.
- `--from-bundle <dir>`: exactly one `aid-shared-v*.tar.gz` (none or several -> exit 2, listing
  what was found); each tool artifact's version equals the shared payload's; each artifact checked by
  `verify_bundle_checksum` (unchanged). `--from-bundle <file>` naming a release artifact uses that
  file's directory.
- `extract_payload` / `Expand-AidPayload` (new): first member is the wrapper, every member under it,
  no absolute path and no `..` segment; returns `<dest>/<wrapper>` as the staging root.
- Descriptor validation before any write, via `read_kv_conf` / `Read-AidKvConf`: `skill_mirror`,
  `worktree_root`, `context_import` (must be `CLAUDE.md`), `layout_format` (must equal `AID_SUPPORTED_FORMAT`; higher prints
  `This release needs a newer aid CLI. Run: aid update self`), `aid_version` (must equal the artifact
  name's version). A violation exits 1 naming the file and key.
- Per-tool allowlist: a tool artifact may contain only `aid-tool.conf` and `<that tool's root>/agents/`.
  This replaces the post-copy manifest-seam gate: delete `_retired_roots` in `install_tool` and its
  PowerShell counterpart.
- `_prepare_release_staging_aid` in `bin/aid` (replaces `_prepare_tool_staging_aid`) and its
  `bin/aid.ps1` twin (replaces `Prepare-AidToolStaging`): stage the shared payload once plus each
  named tool, all before any destination write.
- Fixture recipe for the criteria: `S=$(mktemp -d); bash release.sh --stage-only --out "$S"`;
  `F=$(mktemp -d); git -C "$F" init -q`; run
  `AID_HOME=$(mktemp -d) AID_NO_UPDATE_CHECK=1 bash bin/aid add <tool> --from-bundle <dir> --target "$F"`.
  Each refusal below happens in staging, so it is observable before task-009 rewires the commit.
- Known red: the CLI suites listed in task-006 (same re-key tasks).

**Acceptance Criteria:**
- [ ] A bundle dir with no `aid-shared-v*.tar.gz`, and one with two, each make `aid add cursor` exit `2` with the found names in the output; the fixture's sha256 snapshot is unchanged.
- [ ] A bundle whose shared payload bytes no longer match `SHA256SUMS` makes `aid add cursor` exit non-zero, and the fixture snapshot is unchanged.
- [ ] A shared payload whose `aid-payload.conf` says `layout_format=6` exits `1` with `This release needs a newer aid CLI. Run: aid update self`; an `aid-tool.conf` with `skill_mirror=.agents/skills` exits `1` naming `aid-tool.conf` and `skill_mirror`; a member path containing `..` exits `1`; a tool artifact holding a file outside its `<root>/agents/` exits `1` naming that member. The fixture snapshot is unchanged in every case.
- [ ] A tool artifact at version Y beside a shared payload at version X (X != Y) exits `2`.
- [ ] `--from-bundle "$S/aid-cursor-v<V>.tar.gz"` stages exactly as `--from-bundle "$S"` does.
- [ ] With the endpoint override pointing at a local server that serves no `aid-shared-v<V>.tar.gz`, `aid add cursor` exits `3` with the exact missing-payload message (a `python3 -m http.server` on a port from `find_free_port` in `tests/lib/net.sh`, with `AID_ALLOW_ENDPOINT_OVERRIDE` set as the existing CLI suites set it).
- [ ] `grep -n '_retired_roots\|_prepare_tool_staging_aid\|Prepare-AidToolStaging' lib/ bin/ -r` prints nothing.
- [ ] Each case above gives the same exit code and message under `bin/aid.ps1` where `pwsh` exists; `bash tests/canonical/test-ps51-compat.sh` and `bash tests/canonical/test-ascii-only.sh` exit `0`.
- [ ] All section-6 quality gates pass.
