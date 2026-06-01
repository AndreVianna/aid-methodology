# Setup Options & Cross-Profile Non-Regression

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-05-31 | Drafted from REQUIREMENTS during FEATURE-DECOMPOSITION | /aid-interview |
| 2026-05-31 | Technical Specification drafted | /aid-specify |
| 2026-05-31 | Specify review fixes (ledger spec-feature-004) | /aid-specify |
| 2026-05-31 | Specify review fix R2 (ledger #6) | /aid-specify |
| 2026-05-31 | Altitude trim (push shell bodies to task) + de-brittle cross-refs (post-specify review) | /aid-specify |
| 2026-05-31 | FR1 loopback: corrected emitted-tree shapes (Copilot native skills home, no mcp-config.json; Antigravity .agent/skills + .md rules); collision + gate mechanism unchanged | /aid-execute |

## Source

- REQUIREMENTS.md §4 (Setup options; Tests + render-drift), §5 FR4 + FR5, §6 (backward compatible), §7 (CI gate, SHA-pinned actions), §9 AC4 + AC5, §10 priorities 3 & 4

## Description

Make the two new providers installable and prove the whole 5-profile pipeline stays clean. First,
extend both end-user installers (`setup.sh` + `setup.ps1`) so the tool-selection menu offers
GitHub Copilot CLI and Google Antigravity alongside the existing three, copying each provider's
committed profile tree (its rendered subtree plus its profile-local context file) to the correct
destination (e.g. for Copilot the `.github/` subtree — `.github/agents/*.agent.md` + the native
`.github/skills/<slug>/` Agent Skills home + `.github/scripts/`/`.github/templates/` — plus root
`AGENTS.md`, and **no `mcp-config.json`** per FR1 Q-B; for Antigravity the `.agent/` subtree —
`.agent/rules/*.md` + `.agent/skills/<slug>/` + `.agent/scripts/`/`.agent/templates/` — plus root
`AGENTS.md`), with the same diff-aware copy semantics (new=copy,
identical=skip, different=ask / `--force`) — the new providers' context files are profile-local
committed files (feature-001 Q-J convention), copied exactly as codex/cursor's `AGENTS.md` is today.
The menu is currently a hard-coded 1/2/3 array in both scripts, so this is real wiring, not free.
Second, finalize non-regression: extend the render-drift gate + canonical/generator self-test suites
to cover both new profiles, keep GitHub Actions SHA-pinned, and verify the existing three profiles
still render byte-identically.

**AGENTS.md multi-install collision (resolved below, Option A):** up to four providers install a
root `$TARGET/AGENTS.md` (pre-existing for codex+cursor; widened by Copilot + Antigravity both
using `AGENTS.md`). A multi-select install collides on that path. The AGENTS.md Multi-Install
Collision Decision section rules this last-writer-wins + explicit warning, with no merge engine.

**Non-regression is a continuous gate, not just this feature's checkbox:** "existing-3
byte-identical" must gate every preceding feature's merge (from feature-002
onward) so an engine change can't silently perturb the existing 3 and be discovered only here. This
feature *finalizes* the all-5-profile gate and owns the setup wiring; it is the integration seam,
sequenced last (needs both new trees to exist).

## User Stories

- As an AID adopter, I want `setup.sh`/`setup.ps1` to let me pick Copilot CLI and/or Antigravity and
  install the correct tree so onboarding is one command, like the existing tools.
- As an AID maintainer, I want the render-drift gate + self-tests to cover all five profiles so
  future canonical edits can never silently break a provider's output.
- As an AID maintainer, I want the existing three profiles byte-identical so adding two providers is
  provably backward compatible.

## Priority

Must

## Acceptance Criteria

- [ ] Given the installer menu, when a user runs `setup.sh` or `setup.ps1`, then Copilot CLI and
      Antigravity appear as selectable targets alongside Claude Code / Codex / Cursor.
- [ ] Given a selected new provider, when setup runs, then it copies that provider's emitted tree to
      the correct destination paths with the existing diff-aware copy semantics (new/identical/
      different + `--force`), in **both** the bash and PowerShell installers.
- [ ] Given all five profiles, when the render-drift gate runs in CI, then it is clean across all
      five (re-render byte-identical) and the generator self-tests + canonical suites are green.
- [ ] Given the existing three profiles, when the full suite runs, then their emitted trees are
      byte-identical to before this work (backward compatible) — and this check has gated every
      prior feature's merge, not only this one.
- [ ] Given the CI workflow, when actions are referenced, then they remain SHA-pinned.

---

## Technical Specification

> This is the **integration-seam** feature in the AID methodology repo's canonical→profiles render
> pipeline. There is no DB / HTTP API / UI. The standard Data Model / Feature Flow / Layers sections
> are replaced by the seam-adapted sections below: **Setup-Menu Extension** (the real `setup.sh` +
> `setup.ps1` wiring), the **AGENTS.md multi-install collision decision**, the **Render-Drift +
> Non-Regression** gate extension, the **Test Plan + AC traceability**, the explicit **Dependencies**
> for /aid-plan, and **Risk / Backward-Compat**.
>
> **Dependencies (hard).** This feature installs and gates the trees produced by feature-002
> (`profiles/copilot-cli/...`) and feature-003 (`profiles/antigravity/...`). It cannot ship until
> both trees exist and are committed — they are this feature's install sources AND its gate inputs.
> See the Dependencies section. Concrete per-tool destination paths owed to research are tagged
> **[FR1-owned]** and not fabricated; the *mechanisms* below are fixed by the real scripts read at
> spec time.

### Grounding (read 2026-05-31)

**Setup scripts.** Both installers are hand-rolled multi-select menus over a hard-coded tool set:

- `setup.sh` — menu state: `# Menu state` comment at **line 27**, `selected[1]/[2]/[3]` declared
  at **lines 28-30** (the new `selected[4]/[5]` land at **line 31**); `tool_name()` case at
  **lines 32-38**; `print_menu()` loops `for i in 1 2 3` at **line 44** and prints `[4] Done` at
  **line 51**; the read-loop accepts `1|2|3` at **line 59** and `4` (break) at **line 66**; the
  "anything selected?" guard loops `for i in 1 2 3` at **line 77**. The diff-aware copy helper
  `copy_file` is at **lines 87-112** (new=`cp`+"Copied", identical=`cmp -s`+"Up to date",
  different=`--force`→`cp`+"Updated" else `read` on `/dev/tty`+"Skipped"); `copy_dir` at
  **lines 115-128**. Per-tool copy blocks: Claude Code **135-139** (`.claude` + `CLAUDE.md`, no
  AGENTS.md), Codex **142-147** (`.codex` + `.agents` + `AGENTS.md`), Cursor **150-154**
  (`.cursor` + `AGENTS.md`).
- `setup.ps1` — menu state `$selected = @{ 1..3 }` at **line 24**; `Get-ToolName` switch
  **26-32**; `Show-Menu` loops `foreach ($i in 1, 2, 3)` at **line 38**, `[4] Done` at **line 42**;
  read-loop matches `'1','2','3'` at **line 50**, `'4'` break at **lines 54/57**; `$any` guard at
  **line 60**. `Copy-Item-Safe` (MD5-hash compare) at **lines 67-99**; `Copy-Dir-Safe` at
  **102-123**. Per-tool blocks: Claude Code **130-134**, Codex **137-142**, Cursor **145-149** —
  one-to-one parity with the bash blocks.

**Render-drift gate (the real one).** `.github/workflows/test.yml`, job `render-drift`
(**lines 24-42**): checkout → `setup-python@…` (SHA-pinned, **line 29**) → `git config
core.fileMode false` → `python run_generator.py` (**line 35**) → **`git diff --exit-code --
profiles/`** (**line 39**). **The byte-identity mechanism is committed-tree + re-render + git diff:**
the rendered install trees under `profiles/` are committed; CI re-renders from `canonical/` and fails
if the working tree differs. So "existing 3 byte-identical" and "new 2 render clean" are the *same*
check — adding two profiles means committing two new subtrees and the diff must stay empty after a
fresh render. `run_generator.py` auto-discovers profiles via `profiles_dir.glob('*.toml')`
(**line 24**), so `copilot-cli.toml` + `antigravity.toml` enter the gate with **no workflow edit**.

**Within-run determinism.** `run_generator.py` runs all five passes per profile then calls
`run_verify` (`verify_deterministic.py`): byte-identical re-render + manifest presence audit
(no missing/extra files) + frontmatter parse. `verify_deterministic.py` self-test is gated in the
`generator-selftests` job (test.yml **lines 90-96**). NB: `verify_deterministic` imports
render_agents/skills/templates/recipes but **not** `render_canonical_scripts`. Feature-002's
re-spec **drops the MCP emitter (E3)** entirely — FR1 Q-B rules MCP `[omit]`, so no new pass is
added and the `_render_all` pass-list is untouched; this feature only verifies the existing gate
stays green end-to-end across all five profiles.

**Canonical suites.** `tests/run-all.sh` discovers suites by glob `tests/canonical/test-*.sh`
(**line 33**) — **adding a suite needs no runner edit**. The setup installers already have suites:
`tests/canonical/test-setup.sh` (full bash install coverage: menu logic, per-tool installs,
multi-select, idempotent re-install, `--force`) and `tests/canonical/test-setup-ps1.sh` (pwsh;
Linux-CI exercises only target-validation + menu loop — the path-joined copy is Windows-only and
covered cross-tool by the bash suite). Both are gated in the `canonical-tests` job
(test.yml **lines 76-80**, via `bash tests/run-all.sh`).

**AGENTS.md collision is real *today*.** `profiles/codex/AGENTS.md` and `profiles/cursor/AGENTS.md`
both install to `$TARGET/AGENTS.md` and they are **not identical** — they diff at line 16
(`.agents/templates/...` vs `.cursor/templates/...`). So a user who multi-selects Codex **and**
Cursor today already gets a silent last-writer-wins clobber with a `/dev/tty` overwrite prompt
(or silent overwrite under `--force`). Copilot CLI (`AGENTS.md`, FR1 Q-A/Q-J) and Antigravity
(`AGENTS.md`, FR1 Q-H — `GEMINI.md` is also read by the tool but `AGENTS.md` is the canonical pick
AID ships) widen this from 2 colliding tools to 4 — all four write a root `AGENTS.md`. **No merge
exists; `copy_file` / `Copy-Item-Safe` only know new/identical/different.**

### Setup-Menu Extension (FR4)

Add two providers to the numbered menu in **both** scripts, keeping bash↔ps1 in exact parity. The
menu is 1-indexed with the terminal "Done" entry numerically last, so the clean extension is:
shift "Done" to `[6]`, add Copilot CLI as `4` and Antigravity as `5`.

**`setup.sh` edits:**

1. **Menu state (after line 30, i.e. at line 31):** add `selected[4]=0` and `selected[5]=0`
   immediately below the existing `selected[1]/[2]/[3]` block (line 27 is the `# Menu state`
   comment; the array elements are 28-30).
2. **`tool_name()` (lines 32-38):** add `4) echo "GitHub Copilot CLI" ;;` and
   `5) echo "Antigravity" ;;`.
3. **`print_menu()` loop (line 44):** `for i in 1 2 3 4 5; do` and change the Done line (51) to
   `echo "  [6] Done"`.
4. **Read-loop (lines 58-72):** widen the toggle case `1|2|3)` → `1|2|3|4|5)`; change the break
   case `4)` → `6)`; update the invalid-choice message (line 70) to
   `"Invalid choice. Enter 1-6."`.
5. **"anything selected?" guard (line 77):** `for i in 1 2 3 4 5; do`.
6. **AGENTS.md collision pre-copy block — insert *after* the "anything selected?" guard `fi`
   (lines 81-84) and *before* the first per-tool copy block (the Claude Code `if` at line 134),
   i.e. at line 85, before the `copy_file` helper is invoked.** This is the single, dedicated home
   for the Option A decision — it runs once, before any per-tool `if` block, and does two things:
   (a) print the collision warning, and (b) make the known multi-tool AGENTS.md collision
   **non-interactive** so a stdin-driven test harness never hits the per-file `/dev/tty`
   diff-prompt for the *expected* multi-install case.

   - Build the list of selected AGENTS.md-writing tools from the `selected[...]` flags — Codex
     (`2`), Cursor (`3`), Copilot CLI (`4`), and Antigravity (`5`). FR1 Q-H rules Antigravity's
     context file is `AGENTS.md` (not `GEMINI.md`), so all four are AGENTS.md-writers and Antigravity
     is included unconditionally. If two or more are selected, set a dedicated `AGENTS_COLLISION` flag and
     `echo` a one-line warning naming the colliding tools and the survivor (the highest-numbered
     selected writer — see warning text in the Decision section).
   - **Non-interactive resolution of the known collision.** In `copy_file`, the "files differ, not
     `--force`" branch currently runs `read … </dev/tty` (lines 102-106). Add an `AGENTS_COLLISION`-
     gated branch to that `else`: when `AGENTS_COLLISION=1` **and** `$(basename "$dst") == AGENTS.md`,
     overwrite (`cp`) last-writer-wins **without** firing the `/dev/tty` prompt (the up-front warning
     is the user's signal); otherwise the existing prompt path is unchanged. This keeps the generic
     diff-prompt for every *unexpected* file difference (idempotent re-install over a manually-edited
     tree still prompts) while the *known* multi-tool AGENTS.md collision resolves deterministically
     and testably (clean exit 0, no `/dev/tty` read). The `--force` path is unchanged.
7. **New per-tool copy blocks** (after the Cursor block at line 154), mirroring the existing
   `copy_dir`/`copy_file` shape and the destination layout owned by feature-002 / feature-003:

   - **Copilot CLI** (`selected[4]`): `copy_dir` its committed `.github` profile subtree (per
     feature-002 — this includes `agents/*.agent.md`, the native `skills/<slug>/SKILL.md` Agent
     Skills home, and `scripts/`/`templates/`) and `copy_file` its root context file (`AGENTS.md`).
     There is **no `mcp-config.json`** to copy — FR1 Q-B rules MCP `[omit]`, and feature-002's
     re-spec dropped the E3 emitter, so its committed tree ships none. The context-file copy goes
     through the same `copy_file` helper as the Codex/Cursor `AGENTS.md` (so the Option-A guarded
     branch applies).
   - **Antigravity** (`selected[5]`): `copy_dir` its committed `.agent` profile subtree (per
     feature-003 — `rules/*.md` + the native `skills/<slug>/SKILL.md` home + `scripts/`/`templates/`)
     and `copy_file` its profile-local root context file (`AGENTS.md`, FR1 Q-H).

   **Profile-local context files (feature-001 Q-J).** Both providers' context files are committed
   profile-tree data, copied exactly as codex/cursor's `AGENTS.md` is today — *not* rendered emitter
   output. The implementer reads the committed `profiles/copilot-cli/` and `profiles/antigravity/`
   trees and copies their top-level subtree(s) + the root context file that actually exists there.

   **Antigravity context filename — resolved by FR1 Q-H to `AGENTS.md`.** The basename is `AGENTS.md`
   (FR1 Q-H rules `AGENTS.md` as the cross-tool canonical pick over `GEMINI.md`); the implementer
   confirms it by reading `profiles/antigravity/` rather than hard-coding it. The collision count
   (step 6) includes Antigravity (it writes `AGENTS.md`).

   **[FR1-owned] / feature-002/003-owned values:** the exact profile-subtree root dirs (`.github`
   for Copilot, `.agent` for Antigravity) and the context-file name (`AGENTS.md` for both, per FR1
   Q-A/Q-H) are owned by feature-002/003 and must match their committed trees. Copilot ships **no**
   `mcp-config.json` (FR1 Q-B `[omit]`; E3 dropped from feature-002), so there is nothing extra to
   copy beyond the `.github` subtree + `AGENTS.md`. This block copies whatever those committed trees
   contain; it does not invent placement — exactly as the Codex block copies `.codex` + `.agents` +
   `AGENTS.md`.

**`setup.ps1` edits (one-to-one parity):**

1. **`$selected` (line 24):** `@{ 1=$false; 2=$false; 3=$false; 4=$false; 5=$false }`.
2. **`Get-ToolName` (lines 26-32):** add `4 { return "GitHub Copilot CLI" }`,
   `5 { return "Antigravity" }`.
3. **`Show-Menu` (line 38):** `foreach ($i in 1, 2, 3, 4, 5)`; Done line (42) → `[6] Done`.
4. **Read-loop (lines 49-58):** toggle case `{ $_ -in '1','2','3','4','5' }`; break/`-eq` checks
   change `'4'` → `'6'` (lines 54 **and** 57 — there are two); invalid message (55) → `"Enter 1-6."`.
5. **AGENTS.md collision pre-copy block — insert *after* the "anything selected?" guard
   (`if (-not $any) { …; exit 0 }` at lines 61-64) and *before* the first copy block (the Claude
   Code `if` at line 130), i.e. at line 65, before `Copy-Item-Safe` is invoked.** Exact parity with
   bash step 6: build the AGENTS.md-writer list from `$selected[2/3/4/5]` (Antigravity writes
   `AGENTS.md` per FR1 Q-H, so `[5]` is included unconditionally), set a script-scope
   `$script:AgentsCollision` flag when ≥2 are selected, and `Write-Host` the same one-line warning
   once (same text as the Decision section).

   **Non-interactive resolution (parity with bash).** In `Copy-Item-Safe`, add an
   `$script:AgentsCollision`-gated branch to the `Read-Host "Overwrite …"` path (lines 87-93): when
   `$script:AgentsCollision` is `$true` **and** `(Split-Path -Leaf $Dst) -eq 'AGENTS.md'`,
   `Copy-Item -Force` last-writer-wins without prompting; otherwise the existing `Read-Host` path is
   unchanged.

6. **New per-tool blocks** after the Cursor block (line 149), using `Copy-Dir-Safe`/`Copy-Item-Safe`
   with `Join-Path` and **backslash** profile sub-paths to match existing convention — one block per
   provider, mirroring bash step 7:

   - **Copilot CLI** (`$selected[4]`): `Copy-Dir-Safe` its committed `.github` subtree (agents
     `.agent.md` + native `skills\<slug>\` Agent Skills home + `scripts\`/`templates\`) and
     `Copy-Item-Safe` its root `AGENTS.md` context file. **No `mcp-config.json`** (FR1 Q-B `[omit]`;
     E3 dropped) — nothing extra to copy.
   - **Antigravity** (`$selected[5]`): `Copy-Dir-Safe` its committed `.agent` subtree (`rules\*.md`
     + native `skills\<slug>\` home + `scripts\`/`templates\`) and `Copy-Item-Safe` its profile-local
     root `AGENTS.md` context file (FR1 Q-H).

   Same [FR1-owned] caveat as bash: the Antigravity context basename (`AGENTS.md`, resolved by FR1
   Q-H) and the subtree roots come from the committed trees (feature-001 Q-J: profile-local committed
   files, not rendered output); the implementer reads `profiles\antigravity\` and copies the context
   file that exists rather than hard-coding it. There is no `mcp-config.json` to copy for Copilot.

**Parity invariant.** Every bash menu/copy change has its ps1 twin and vice versa. The two scripts
must offer the same numbered tools, same destinations, same diff-aware semantics, the same pre-copy
collision warning, and the same guarded last-writer-wins `AGENTS.md` branch in the copy helper —
enforced by the test plan (SU + SPS parallel assertions).

### AGENTS.md Multi-Install Collision — Decision

**The problem, restated against reality.** Four installable providers write a repo-root
`AGENTS.md`: Codex, Cursor (collision exists *today*, trees differ at line 16), plus the two new
ones — Copilot CLI (`AGENTS.md`, FR1 Q-A/Q-J) and Antigravity (`AGENTS.md`, FR1 Q-H). With the current
`copy_file`/`Copy-Item-Safe` semantics, multi-selecting any two AGENTS.md-writing tools triggers a
"files differ" overwrite prompt (or, under `--force`, a silent last-writer-wins clobber). There is
**no merge primitive** in either installer.

**Options considered:**

| # | Option | Pros | Cons |
|---|---|---|---|
| A | **Last-writer-wins + explicit warning** — keep single `AGENTS.md`; when >1 AGENTS.md-writing tool is selected, print a one-line warning naming the collision in a dedicated pre-copy block, and resolve that *known* collision non-interactively (a small guarded branch in `copy_file` overwrites last-writer-wins for `AGENTS.md` instead of prompting) | Tiny, additive; preserves the single canonical `AGENTS.md` each tool reads; reversible; no merge engine; the generic diff-prompt is preserved for every *unexpected* difference; the expected collision is deterministic + testable under a stdin harness | Only one tool's context survives in a single repo; no real coexistence; one small guarded branch added to the copy helper (parity-doubled) |
| B | **Managed section-merge** under `<!-- AID:tool -->` markers — append each tool's AGENTS.md body into one file under per-tool fenced markers, idempotently | True coexistence of multiple tools in one repo | Requires a new merge function in BOTH scripts (bash + pwsh parity), marker-aware idempotency, and re-render determinism handling; the four tools' AGENTS.md bodies are near-identical AID context (not tool-specific config), so merging mostly duplicates the same content; high engine cost for low marginal value |
| C | **Per-tool distinct filenames** (e.g. `AGENTS.copilot.md`) | No collision | Breaks each tool's convention — Copilot/Codex/Cursor/Antigravity all *read* `AGENTS.md` by name; a renamed file is simply not loaded by the tool. Non-starter. |

**Decision — Option A (last-writer-wins + explicit pre-copy warning), defaulted.** Rationale:

- The four AGENTS.md files are AID's *project-context document* rendered per profile, **not**
  tool-specific runtime config. Their bodies are near-identical (codex vs cursor differ only in one
  install-path line). So real coexistence (Option B) buys almost nothing while adding a bespoke,
  parity-doubled merge engine to two shell scripts — squarely against the NFR "convention over
  infrastructure / no new render engine." Option A's only engine touch is a single guarded branch in
  the existing copy helper (no merge logic, no new function), which is well within that NFR.
- Each tool **must** read a file literally named `AGENTS.md` (or `GEMINI.md`), so Option C is
  excluded by the tools' own conventions.
- Option A is the smallest change that removes the *silent* failure: we add a **named pre-copy
  warning** so the user understands the collision and which tools share the file, and we resolve the
  *known* multi-tool `AGENTS.md` collision deterministically (last-writer-wins, no prompt) so the
  expected case is non-interactive and testable. The generic diff-prompt still guards every
  *unexpected* difference. Under `--force` the warning is the only signal, which is acceptable for an
  explicitly-forced run.

**Concrete default semantics (Option A):**

- Single canonical `$TARGET/AGENTS.md` as today (FR1 Q-H resolves Antigravity to `AGENTS.md`, not
  `GEMINI.md`, so there is no second context-file basename in play).
- **Exact location (both scripts have sequential per-tool `if` blocks, *not* a loop):** the count +
  warning + collision flag run **once, in a dedicated pre-copy block placed after the "nothing
  selected" guard and before the first per-tool copy `if`** — `setup.sh` after the guard `fi`
  (lines 81-84), before the Claude Code block (line 134); `setup.ps1` after the guard
  (lines 61-64), before the Claude Code block (line 130). See the FR4 edit recipe (setup.sh step 6,
  setup.ps1 step 5) for the exact insertion and code.
- The count is computed from the `selected[...]` flags for the AGENTS.md-writing tools — Codex,
  Cursor, Copilot, and Antigravity (all four write `AGENTS.md`; FR1 Q-H resolves Antigravity to
  `AGENTS.md`). If the count is ≥2, print once (the survivor is the last-installed tool —
  decided by the **fixed per-tool `if`-block order**, i.e. the highest-numbered selected
  AGENTS.md-writer, *not* the order the user toggled menu items; the warning names that survivor):
  `Note: <tools> all install a shared AGENTS.md; the last-installed tool's version wins — survivor is decided by fixed per-tool install order (highest-numbered selected tool), not the order you toggled them (others are not preserved): <highest-numbered selected tool> wins.`
- **The known multi-tool AGENTS.md collision is resolved non-interactively (last-writer-wins),
  distinct from the generic per-file diff-prompt.** The pre-copy block sets a collision flag; the
  one targeted addition to `copy_file`/`Copy-Item-Safe` is a guarded branch: when the flag is set
  **and** the destination basename is `AGENTS.md`, overwrite without firing the `/dev/tty` /
  `Read-Host` prompt (the up-front warning is the user's signal). This is the *only* engine change —
  the generic new/identical/different/`--force` semantics are otherwise untouched, so every
  *unexpected* file difference still prompts as before. This makes the expected collision testable
  under a stdin-driven harness (clean exit 0, no interactive read) — see SU16.

**Stakes / ratification.** This is **not** a high-stakes irreversible fork — it is a one-line UX
warning plus a small guarded last-writer-wins branch over already-existing behavior, fully reversible
(a future feature can add Option B section-merge without undoing anything). Therefore it is **defaulted here, not escalated.** It is flagged as
**ratifiable later**: if maintainers later want true multi-tool coexistence, Option B is the
follow-on, and this spec's marker convention (`<!-- AID:tool -->`) is the suggested seam. No human
gate is required to proceed.

### Render-Drift + Non-Regression (FR5)

**No gate-code change is required** — the gate is data-driven by `profiles/*.toml` discovery and the
committed-tree diff. The work is to make all five render clean and prove the three existing stay
byte-identical:

1. **Both new profiles committed and render-clean.** After feature-002/003 land,
   `profiles/copilot-cli/` and `profiles/antigravity/` (each: emitted subtree +
   `emission-manifest.jsonl`) are committed. CI's `render-drift` job re-renders via
   `python run_generator.py` and asserts `git diff --exit-code -- profiles/` is empty across **all
   five**. The within-run `verify_deterministic` PASS (byte-identical re-render + manifest presence
   audit + frontmatter parse) covers the two new profiles automatically (auto-discovered).

2. **Existing-3 byte-identity — the mechanism is the committed tree itself.** Because
   `profiles/{claude-code,codex,cursor}/` are committed, *any* engine change that perturbs them shows
   up as a non-empty `git diff` under those subtrees and fails `render-drift`. This is the
   "byte-identical = re-render + git diff against committed golden" mechanism — not a separate hash
   manifest. This feature adds an **explicit existing-3 non-regression assertion** (see Test Plan #4)
   so the guarantee is named, but the enforcing machinery is the existing gate.

3. **Continuous gate from feature-002 onward.** Per the SPEC's Description, the existing-3
   byte-identity must gate *every* preceding feature's merge, not only this one. Because
   `render-drift` runs on every PR to `master` (test.yml **lines 13-17**) and diffs the whole
   `profiles/` tree, this is already structurally continuous — feature-002's and feature-003's PRs
   each had to pass it. This feature **finalizes** the all-5 coverage and **documents** that the
   property has held since feature-002 (it does not need to re-implement a per-feature gate).

4. **SHA-pinned actions preserved.** No workflow edit is required, so the pins at test.yml lines 28,
   29, 48-49, 56, 86-87, 102 remain untouched. If any workflow edit *is* made (none anticipated),
   actions stay pinned to a full commit SHA.

5. **Generator self-tests + canonical suites green.** The `generator-selftests` job
   (render_lib / test_manifest_safety / render_canonical_scripts / verify_deterministic /
   verify_advisory self-tests) and `canonical-tests` job (`tests/run-all.sh`) must stay green with
   the two new profiles present. The setup-suite extensions (below) ride into `canonical-tests` via
   the existing glob discovery.

### Test Plan

**Setup (FR4 → AC4) — extend `tests/canonical/test-setup.sh` (bash, full coverage):**

- **SU12 install Copilot CLI** — `drive "$T" $'4\n6'`; assert exit 0, `$T/.github` created, root
  `$T/AGENTS.md` created, "Copied:" reported.
- **SU13 install Antigravity** — `drive "$T" $'5\n6'`; assert exit 0, `$T/.agent` created (including
  the native `$T/.agent/skills/` Agent Skills home and `$T/.agent/rules/`), root `$T/AGENTS.md`
  created (FR1 Q-H).
- **SU14 content fidelity** — installed Copilot/Antigravity subtree files are byte-identical to their
  `profiles/...` sources (mirror SU06f's `cmp -s`). For Copilot this covers `.github/skills/<slug>/`
  (native Agent Skills) and asserts **no `mcp-config.json`** is present in the installed tree (FR1
  Q-B `[omit]`).
- **SU15 menu still rejects out-of-range** — `drive "$T" $'7\n6'` → "Invalid choice" then "Nothing
  selected" (Done is now 6).
- **SU16 multi-select with AGENTS.md collision (Option A, non-interactive)** — select two
  *different-content* AGENTS.md-writing tools on a **fresh** target, e.g. `drive "$T" $'2\n4\n6'`
  (Codex + Copilot, whose `AGENTS.md` bodies differ). Assert: (a) the run completes with **exit 0**
  (no hang/EOF); (b) the collision **warning** line `Note: … all install a shared AGENTS.md …` is
  present in output (validates Option A) and names the survivor; (c) the **last-installed** writer
  (the highest-numbered selected AGENTS.md-writer — here Copilot, block `4` > Codex block `2`, since
  the per-tool `if` blocks run in fixed numeric order regardless of menu-toggle order) reports
  `Updated: …/AGENTS.md (AGENTS.md last-writer-wins …)` — i.e. the known collision resolved
  **without** an interactive `/dev/tty` prompt; (d) `$T/AGENTS.md` is byte-identical to the
  **last-installed** (highest-numbered selected) tool's source — for this selection that is Copilot,
  so `cmp -s` against `profiles/copilot-cli/AGENTS.md`. (The survivor is fixed by block order, not by
  the order menu items were toggled; `$'2\n4\n6'` happens to toggle in block order too, but
  `$'4\n2\n6'` would still leave Copilot's `AGENTS.md` because block `4` runs after block `2`.)
  **Rationale this is now testable:** the dedicated pre-copy collision block sets the
  `AGENTS_COLLISION` flag, and the guarded `copy_file` branch overwrites `AGENTS.md` deterministically
  instead of issuing `read … </dev/tty`, so the stdin-driven `drive` harness (which supplies only the
  menu inputs) never has to answer an overwrite prompt. **Companion SU16b — unexpected diff still
  prompts:** single-tool re-install over a *manually edited* `$T/AGENTS.md` (no second AGENTS.md tool
  selected, so `AGENTS_COLLISION=0`) must still hit the diff-prompt — assert that path is preserved
  (e.g. piping `n` skips, or `--force` updates), proving the guarded branch is scoped to the known
  collision only.
- **SU17 idempotent re-install + --force** for a new provider (mirror SU10/SU11).
- Update the suite header comment: tools are now Claude/Codex/Cursor/Copilot CLI/Antigravity; Done is
  `6`; menu inputs terminate with `6` not `4`.

**Setup parity (FR4 → AC4) — extend `tests/canonical/test-setup-ps1.sh` (pwsh, Linux-CI = menu only):**

- **SPS05 menu lists 5 tools + Done=6** — `drive "$T" "6"` → exit 0, "Nothing selected"; assert
  output contains "GitHub Copilot CLI" and "Antigravity" (menu render).
- **SPS06 toggle new tool on+off** — `drive "$T" $'4\n4\n6'` → "Nothing selected", `$T/.github`
  absent.
- **SPS07 out-of-range rejected** — `drive "$T" $'7\n6'` → "Invalid choice".
- **SPS08 collision warning parity** — select two AGENTS.md-writing tools (`drive "$T" $'2\n4\n6'` =
  Codex + Copilot); assert the `Note: … all install a shared AGENTS.md …` warning is in output.
  This is platform-independent (the pre-copy block is `Write-Host` only; it runs before the
  Windows-only copy), so it validates ps1↔sh warning parity on Linux CI without exercising the copy.
- (Install-copy of the new trees on Windows is covered cross-tool by the bash suite, per the existing
  suite's scope note.)

**Non-regression (FR5 → AC5):**

- **NR1 all-5 render-drift clean** — `python run_generator.py` then `git diff --exit-code --
  profiles/` is empty (the real CI gate; runnable locally).
- **NR2 within-run determinism** — `python verify_deterministic.py --self-test --canonical-root .`
  PASS with all five profiles discovered.
- **NR3 existing-3 byte-identical (named assertion)** — `git diff` under
  `profiles/{claude-code,codex,cursor}/` (trees + `emission-manifest.jsonl`) is empty after a fresh
  render — i.e. adding the two profiles changed zero bytes of the existing three. This is the
  explicit AC5 backward-compat check.
- **NR4 generator self-tests + canonical suites green** — `generator-selftests` job commands all
  pass; `bash tests/run-all.sh` all suites pass (incl. the extended setup suites).
- **NR5 SHA-pin audit** — every `uses:` in test.yml references a 40-char commit SHA (unchanged).

**AC traceability:**

| AC | Covered by |
|---|---|
| AC4a (menu offers Copilot + Antigravity, both scripts) | SU12/SU13/SU15, SPS05/SPS06 |
| AC4b (correct trees to correct destinations, diff-aware, both scripts) | SU12-SU14/SU17 (bash), SPS05-SPS07 + bash cross-tool copy coverage (ps1) |
| AC5a (all 5 render-drift clean; self-tests + suites green) | NR1, NR2, NR4 |
| AC5b (existing 3 byte-identical; gated every prior feature) | NR3 + the continuous `render-drift` gate (FR5 §3) |
| AC5c (actions SHA-pinned) | NR5 |
| AGENTS.md multi-install collision | Decision = Option A (pre-copy warning + non-interactive last-writer-wins for the known collision; generic diff-prompt preserved for unexpected diffs); SU16 (collision resolved, exit 0, warning present, last-writer source wins) + SU16b (unexpected single-tool diff still prompts) + SPS08 (warning parity in ps1) |

### Dependencies (explicit, for /aid-plan)

- **Depends on feature-002 (Copilot CLI profile) — HARD.** Its committed `profiles/copilot-cli/.github`
  tree (`agents/*.agent.md` + native `skills/<slug>/` Agent Skills home + `scripts/`/`templates/`)
  + root `AGENTS.md` are this feature's install source and a gate input. **No `mcp-config.json`** is
  in that tree (FR1 Q-B `[omit]`; E3 dropped from feature-002). Setup block destinations mirror
  feature-002's emitted tree.
- **Depends on feature-003 (Antigravity profile) — HARD.** Its committed `profiles/antigravity/.agent`
  tree (`rules/*.md` + native `skills/<slug>/` home + `scripts/`/`templates/`) + root `AGENTS.md`
  context file (FR1 Q-H) are the install source and gate input.
- **Sequenced last.** This is the integration seam; both new trees must exist before setup wiring and
  the all-5 gate can be exercised. (feature-001 is upstream of 002/003 transitively.)
- **No dependency on the gate-code being changed** — the `render-drift` job and `tests/run-all.sh`
  are data/glob-driven; the new profiles and new setup suites are picked up automatically.

### Risk / Backward-Compat

- **setup.sh ↔ setup.ps1 parity drift (primary risk).** Two hand-maintained installers must stay in
  lockstep (same numbering, same destinations, same Done=6, same warning). Mitigation: every edit is
  specified as a bash/ps1 pair above; parallel SU/SPS assertions catch divergence in CI; the ps1
  read-loop has **two** `'4'`→`'6'` sites (lines 54 and 57) — both must change or the loop breaks.
- **Off-by-one in menu renumbering.** Moving Done from 4→6 touches the toggle case, the break case,
  the print loop, the guard loop, and the invalid-choice message in *each* script. Mitigation:
  enumerated line-by-line above; SU15/SPS07 assert out-of-range rejection so a stale `4)` break is
  caught.
- **AGENTS.md clobber.** Resolved by Option A: a dedicated pre-copy block
  (warning + `AGENTS_COLLISION` flag) plus one small guarded branch in `copy_file`/`Copy-Item-Safe`
  that overwrites `AGENTS.md` last-writer-wins for the *known* collision without prompting. No merge
  engine; reversible to Option B later. Risk reduced from *silent* loss to a named warning, and the
  expected collision becomes deterministic + harness-testable instead of hanging on `/dev/tty`. The
  generic diff-prompt is preserved for every *unexpected* difference. SU16 asserts the resolved
  collision (exit 0, warning, last-writer source wins); SU16b asserts the generic prompt is intact
  for a non-collision diff. **Parity caveat:** the guarded branch and the pre-copy block exist in
  *both* scripts (bash step 6 / ps1 step 5) — both must change together.
- **Perturbing the existing 3.** This feature touches only `setup.sh`, `setup.ps1`, and the two test
  suites — **no `canonical/`, no engine, no existing `profiles/*.toml`** — so the existing three
  trees cannot change. NR3 asserts byte-identity as a hard backward-compat check; the committed-tree
  `render-drift` gate enforces it on every PR.
- **No new dependencies.** Edits are pure bash + PowerShell + existing test harness; no pip/npm.
  Satisfies the dependency-free NFR.
- **FR1/feature-002/003-owned values not fabricated.** Exact emitted-tree subdir(s) are owned by the
  profile features; the setup blocks copy whatever those committed trees contain. FR1 has resolved
  the previously-open items: both providers' context file is `AGENTS.md` (Q-A/Q-H), Copilot's tree
  includes a native `.github/skills/` Agent Skills home and ships **no** `mcp-config.json` (Q-B
  `[omit]`), and Antigravity's tree is `.agent/rules/*.md` + `.agent/skills/`. Implementation still
  reads the trees rather than guessing, but the shapes are no longer deferred.
