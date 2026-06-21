# task-010: `aid add` same-version invariant and CLI-ahead-of-repo skew notice (FR11)

**Type:** IMPLEMENT

**Source:** work-005-profile-generator-simplify -> delivery-002

**Depends on:** task-009

**Scope:**
- **Both twins.** Land every change in BOTH the `add` branch of `bin/aid` (`bin/aid:3109-3146`) and its PowerShell twin in `bin/aid.ps1` with byte-equivalent semantics (C6 parity).
- **First-tool version (FR11):** when the manifest is absent or has no `tools.*` entries, install the tool at the **CLI's own version** (`$AID_CODE_HOME/VERSION`), unless `--version <v>` / `--from-bundle` overrides.
- **Additional-tool version (FR11):** when the manifest already has ≥1 tool, install at the **existing tools' version** (`manifest_read_tool_version` of any existing tool — they are uniform by invariant). `add` does **NOT** force a repo-wide update; there is no repo-wide version escalation.
- **CLI-ahead-of-repo skew notice:** when the CLI version > the repo's existing-tools version (e.g. CLI v1.2.0, repo at v1.1.0) and the user runs `aid add <tool>`, install the new tool at the **repo (existing-tools) version** (honor FR11 literally) and print a one-line notice — e.g. "repo is at v1.1.0; <tool> installed at v1.1.0. Run `aid update` to advance all tools to v1.2.0." This keeps `add` non-escalating and makes the skew visible.
- **`--version` override on `add`:** when provided, it must apply to **ALL** requested tools **or error** — it may not produce a mixed-version repo. (Atomicity: stage-all-first across the requested tools, consistent with task-009.)
- **`--dry-run` is INHERITED** from task-009's shared add/update parser (`_AID_DRY_RUN`). Do **NOT** re-plumb the flag — reuse the shared `_AID_DRY_RUN` so `aid add` previews with the same semantics (print plan, exit 0, no writes).
- Retain the existing writability pre-check (B-table, `bin/aid:3112-3119`) and `registry_register` — never create a root-owned `.aid/`.
- **Out of scope:** the `aid update` command shape / staging-loop split / `--dry-run` flag definition (task-009 owns those); the prune/migration engine (task-011); tests (task-012/013).
- ASCII-only for both shipped scripts.

**Acceptance Criteria:**
- [ ] First-tool `aid add` (no existing `tools.*`) installs at the **CLI version** (`$AID_CODE_HOME/VERSION`), overridable only by `--version` / `--from-bundle`.
- [ ] Additional-tool `aid add` installs at the **existing repo tools' version**, with no repo-wide escalation; the post-condition keeps all `tools.*.version` uniform.
- [ ] `aid add` never produces a mixed-version repo (additional-tool matches existing version; `--version` applies to all-or-errors).
- [ ] When CLI > repo version on an additional-tool `add`, the new tool is installed at the repo version AND a one-line CLI-ahead-of-repo notice is printed.
- [ ] `--version` on `add` applies to ALL requested tools or errors out (no partial/mixed result).
- [ ] `--dry-run` on `add` previews the plan and writes nothing, using the **inherited** shared `_AID_DRY_RUN` flag (not a re-plumbed copy).
- [ ] bash + PowerShell parity for every changed function; both shipped scripts are ASCII-only.
- [ ] IMPLEMENT defaults: unit tests for all new/changed public functions; all existing tests still pass; build passes.
- [ ] All §6 quality gates pass.
