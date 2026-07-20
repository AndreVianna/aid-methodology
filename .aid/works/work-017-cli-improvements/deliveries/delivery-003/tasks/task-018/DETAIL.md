# task-018: write-connector.sh atomic single-entry writer + connector co-vendor

[!NOTE]
This is the TASK-LEVEL DETAIL.md template. It is the IMMUTABLE DEFINITION for this task.
Written once by aid-detail; not a state file. State lives in task-NNN/STATE.md.
Shape: 6 sections matching .claude/aid/templates/delivery-plans/task-template.md.

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

**Source:** feature-007-connectors-list -> delivery-003

**Depends on:** task-004 (delivery-001)

**Scope:**
- Add one new canonical bash writer `aid/scripts/connectors/write-connector.sh` -- the
  non-interactive counterpart to the `aid-set-connector` / `aid-unset-connector` skills (which the
  LLM-free server cannot run: `aid-set-connector` requires `AskUserQuestion`, SKILL.md line 12 --
  SEC-4). Bash-only, no `.ps1` twin (a deliberate departure from the connectors-area
  Bash+PowerShell-twins convention: server-dispatched, never on the PowerShell CLI path; recorded
  as a KB follow-up, not a defect). Contract:
  `write-connector.sh set --root <dir> --name <N> --type <T> [--endpoint <E>] [--auth <A>] [--secret-ref <R>]`
  and `write-connector.sh remove --root <dir> --stem <STEM>`.
- `set` subcommand -- derive `<stem>` from `--name` via the skills' slug rule verbatim
  (`aid-set-connector/SKILL.md` Step 1:
  `tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'`) so dashboard- and
  skill-authored stems are byte-identical. Author/overwrite `<root>/<stem>.md` as an **atomic
  single-descriptor write** (temp-file + `mv`; per Q7 the dashboard is a subordinate atomic
  single-entry maintainer, never a wholesale rewrite of the registry) with the full frontmatter the
  skill produces (`name, connection_type, endpoint, auth_method, secret_reference?, preset: custom,
  objective, summary, tags: [connector, <type>], audience: [developer, architect]`) plus a
  `# <Name>` heading and a `> Connection: … · Mode: <tool-managed|aid-managed> · Auth: <auth>` line,
  templated deterministically from the supplied fields (no LLM prose composition). Upsert semantics
  (re-`set` of an existing stem overwrites in place), matching the skill's single-stem UPDATE.
- Per-type normalize + fail-closed enforcement (question-sets.md §mcp/§api-url/§ssh/§cli, via
  `canonical/skills/aid-set-connector/references/question-sets.md`): `mcp` forces
  `auth_method: none`, drops `secret_reference`, `endpoint` informational; `ssh` forces
  `auth_method: ssh-key`; `api`/`url`/`cli` REQUIRE both `--endpoint` and `--auth`, and `--endpoint`
  is likewise required for `ssh`. A missing required field fail-closes (exit `5`) rather than
  persisting a descriptor the skill would never author.
- `secret_reference` default -- a credentialed connector (`ssh` always, since `auth_method` is
  forced `ssh-key`; `api`/`url`/`cli` when `auth != none`) MUST carry a `secret_reference`
  (`artifact-schemas.md` "yes iff aid-managed AND `auth_method != none`", line 438); when
  `--secret-ref` is omitted the writer defaults it to the skill's
  `file:.aid/connectors/.secrets/<stem>` form (never fabricating a value), so a credentialed
  descriptor can never persist without a reference. `mcp` / any `auth_method: none` connector carries
  none (dropped). Reference form only -- never accept, echo, prompt for, or store a secret VALUE.
- `.secrets/` gitignore precondition on `set` (the load-bearing write `aid-set-connector` Step 4
  performs): `mkdir -p <root>; [ -f <root>/.gitignore ] || printf '%s\n' '.secrets/' > <root>/.gitignore`
  so a later out-of-band `connector-secret.sh write` never fail-closes.
- Orphan-secret purge -- on `set` when the result is `mcp` / `auth_method: none`, run
  `connector-secret.sh purge <stem>` (mirrors `aid-set-connector` Step 5b). On `remove`,
  `connector-secret.sh purge <stem>` is the disposal step (purge-before-delete, interrupt-safe:
  `connector-secret.sh` lines 184-187).
- INDEX regeneration -- both subcommands end by rebuilding the routing table via
  `build-connectors-index.sh --root <root> --output <root>/INDEX.md`. That generator emits no run
  timestamp / dated field (header lines 24-27 / 68-70), so two runs over an identical descriptor set
  are byte-identical (AC2 idempotence). `write-connector.sh` self-locates and invokes its two
  siblings (`connector-secret.sh`, `build-connectors-index.sh`) from its own directory; it never
  invokes the read-only `connector-registry.sh`.
- `remove` subcommand -- `connector-secret.sh purge <stem>` -> `rm -f <root>/<stem>.md` ->
  `build-connectors-index.sh`; a 1:1 non-interactive port of `aid-unset-connector` Steps 2-3.
  Idempotent: an already-absent stem is a clean no-op (exit 0).
- Exit-code alphabet -- feature-001's shared alphabet VERBATIM so feature-001's generic OP_TABLE
  dispatcher maps exit->HTTP with no per-op remapping: `0` ok; `4` invalid value (bad enum / bad
  value / path-confinement bad stem); `5` missing required arg; `3` (or `6`/other) runtime / I-O
  failure / unverifiable write / INDEX rebuild failed. Never emit `1` (`not-found`) or `2` (`busy`)
  -- feature-001-reserved. Normalize the helpers' native codes into this alphabet (e.g.
  `connector-secret.sh`'s exit `2`/usage and exit `3`/path-confinement, and any
  `build-connectors-index.sh` failure, surface as `4` or `3` here).
- Co-vendor with the dashboard unit via a single `dashboard/MANIFEST` edit: add `write-connector.sh`,
  `connector-secret.sh`, and `build-connectors-index.sh` (one path per line). `vendor.js`,
  `vendor.py`, `install.sh`, `install.ps1`, and `release.sh`'s CLI bundle all derive from that single
  source (guarded by `tests/canonical/test-dashboard-manifest.sh`), version-locking the connector
  machinery to the running server+reader unit; the scripts self-locate from `$AID_CODE_HOME`.

**Acceptance Criteria:**
- [ ] `write-connector.sh set` derives the stem from `--name` with the skill's exact slug rule and
  atomically (temp-file + `mv`) authors/overwrites exactly one `<root>/<stem>.md` with the full
  deterministic frontmatter + `# <Name>` heading + `> Connection: …` line; re-`set` of an existing
  stem overwrites in place (upsert) and no other descriptor in `<root>` is touched (atomic
  single-entry, Q7). (feature-007 AC1)
- [ ] Per-type normalize holds: `mcp` -> `auth_method: none` + no `secret_reference` +
  informational `endpoint`; `ssh` -> `auth_method: ssh-key`; `api`/`url`/`cli` with a missing
  `--endpoint` or `--auth` (or `ssh` with a missing `--endpoint`) exits `5` and writes nothing.
- [ ] A credentialed connector (`ssh`; or `api`/`url`/`cli` with `auth != none`) with `--secret-ref`
  omitted persists `secret_reference: file:.aid/connectors/.secrets/<stem>`; `mcp` / `auth none`
  persists no `secret_reference`; no secret VALUE is ever written, echoed, or prompted for.
- [ ] On `set` the `.secrets/` gitignore precondition is met (`<root>/.gitignore` contains
  `.secrets/`), and a `mcp` / `auth none` result runs `connector-secret.sh purge <stem>`.
- [ ] Both subcommands regenerate `INDEX.md` via `build-connectors-index.sh`; two runs over an
  identical descriptor set produce a byte-identical `INDEX.md` (determinism/idempotence). (feature-007 AC2)
- [ ] `write-connector.sh remove` purges the secret, `rm -f`s the descriptor, and rebuilds
  `INDEX.md`; an already-absent stem is a clean no-op returning exit 0.
- [ ] Exit codes emitted are exactly feature-001's alphabet (`0`/`4`/`5`/`3`|`6`), never `1` or `2`;
  helper native codes are normalized rather than propagated raw.
- [ ] `dashboard/MANIFEST` lists `write-connector.sh`, `connector-secret.sh`, and
  `build-connectors-index.sh`; `tests/canonical/test-dashboard-manifest.sh` passes, and
  `write-connector.sh` resolves its two siblings relative to its own directory.
- [ ] Unit tests for all new public methods/endpoints
- [ ] All existing tests still pass
- [ ] Build passes
- [ ] All section-6 quality gates pass
