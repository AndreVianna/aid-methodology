# Requirements

- **Name:** Profile Generator Simplification
- **Description:** Replace AID's over-engineered five-way profile-render pipeline with a simple copy-based generator on a symmetric per-tool layout and uniform format, so skills and agents behave consistently across every host tool.

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Initial interview started; seeded from A+ intake description | /aid-interview |
| 2026-06-20 | Q1 resolved: commit uniform markdown (verify-first); added behavioral-consistency north star + FR4a gating capability study + AC4a | /aid-interview CONTINUE |
| 2026-06-20 | Decision: single `aid update`, all tools one version (FR10) + same-version invariant across install/add (FR11); AC8 confirmed | /aid-interview CONTINUE |
| 2026-06-20 | Q3 resolved [a]: routing directive DROPPED (FR9/AC7 N/A); FR11 add-rules pinned (first→CLI ver, additional→existing-tools ver) | /aid-interview CONTINUE |
| 2026-06-20 | Agreed: format ⊥ behavior, but behavioral metadata (activation/execution/capability/dispatchability) is behavior → FR4-distinction + FR4a sharpened to preserve/translate it | /aid-interview CONTINUE |
| 2026-06-20 | Q4 resolved [a]: migration = complete replacement, auto-migrate + prune; FR7 manifest-driven prune by 3 AID-ownership markers + FR7a per-version manifest; AC5 updated. All sections complete. | /aid-interview CONTINUE |
| 2026-06-20 | COMPLETION: quality check passed (added AC4b for FR4a study); KB hydrated — format⊥behavior term added to domain-glossary.md (rest deferred to ship-time) | /aid-interview COMPLETION |
| 2026-06-20 | Interview complete — approved | /aid-interview |
| 2026-06-20 | Cross-ref Q1 [1]: FR1/AC1/§1 reworded — symmetry = uniform internal `{agents,skills,aid}` shape under host-required root dir (not literal `.{tool}/`) | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | Cross-ref Q2 [1]: FR3 scoped to Cursor only (cursor `[extras]` + `.cursor/rules/`); `canonical/rules/` + mechanism RETAINED for Antigravity | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | Cross-ref Q3 [1]: FR2 consciously supersedes content-isolation cornerstone R6 for Codex; C1/D1 noted; feature-004 owns the content-isolation.md update | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | Cross-ref Q&A (Q1–Q3) all resolved; REQUIREMENTS + feature SPECs updated; ready for re-grade | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | All-tools rules/format research (5 tools) → consolidated update: FR3 drops ALL rules folders + deletes `canonical/rules`/mechanism (supersedes Q2), folds always-on into root context file; FR1 reworded (no AID extras folder); FR10 deliberate-change note; FR4a Codex-TOML + cursor-reliability inputs; A1/A3 updated. Resolves Q4. | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | Softened over-claimed research to "research-indicated, verified in FR4a" (FR1/FR3/A1/A3/FR4a + feature-001/002 SPECs); cross-reference re-graded **A+** (zero findings) — PASSED | /aid-interview CROSS-REFERENCE |
| 2026-06-20 | AC4a widened (intent-fidelity review correction): behavioral sample is the work's actual 3-tool scenario (Cursor + Claude Code + Codex), not 2-plus-maybe-Codex; Copilot CLI + Antigravity parity explicitly named as *asserted via Finding-D1 content-identity, not exercised* (CI can't run 5 live runtimes) | intent-fidelity review |

## 1. Objective

AID renders one `canonical/` source into install trees for **5 host tools** (Claude Code, Cursor, Codex, GitHub Copilot CLI, Antigravity). The render pipeline has grown into a *compiler that emits the same content five different ways* — **13 Python scripts, ~7,000 LOC**. This over-engineering is both a maintenance burden and the root cause of cross-tool inconsistency (a tool picking up another tool's stale/foreign tree).

**Objective:** AID's skills and agents reach **every** tool **consistently**, produced by a **radically simpler, copy-based generator** resting on three pillars:
1. **Symmetric per-tool layout** — the uniform **internal** shape `{agents, skills, aid}` under each tool's **host-required** root dir (`.claude`/`.cursor`/`.codex`/`.github`/`.agent`) + a root context file + a shared, tool-agnostic `.aid/`. (Outer dirs are host-mandated and not renamed; symmetry is the internal structure, not the dir name.)
2. **Uniform agent/skill format** — markdown for both skills and agents (no per-tool format variants), subject to per-tool capability verification.
3. **Tool-agnostic content** — content references its own tree relatively / via a single placeholder, eliminating per-tool path rewriting.

The generator should collapse from 13 scripts toward a single small generator + a tiny per-tool config, while preserving every current guarantee (deterministic output, prune manifest, render-drift CI, content isolation, dogfood byte-identity, ASCII-only shipped scripts).

**North star — behavioral consistency, not format uniformity.** The goal is that a developer gets a consistent AID *experience and behavior* regardless of which host tool they choose. Developers choose **freely**: in the user's company the contracted tools are mostly **Cursor and Claude Code**, with **no rule** mandating either — a dev may use one, the other, or both. Other adopters may use any combination of the 5 supported tools, or tools added in the future. Uniform format is only a *means*; what matters is that a given skill or agent **behaves the same way in each tool**, whatever language/format it happens to be defined in. The **per-tool capability research** — what each tool natively supports and how it discovers/executes agents, skills, and rules — is therefore a **first-class, gating deliverable**: the format decision follows *from* it, not the other way around.

## 2. Problem Statement

The complexity lives almost entirely in **per-tool *difference* handling**:

| Concern | Where (script / LOC) | Eliminable under symmetry + uniform format? |
|---|---|---|
| Same agent emitted in **4 formats** (markdown / TOML / copilot-agent `.agent.md` / antigravity-rule) | `render_agents.py` (865) | Collapse to 1 (markdown) |
| **Format-branch conformance tests** (copilot, antigravity) | `test_copilot_emitter.py` 1004 + `test_antigravity_emitter.py` 1129 | Mostly removed with the branches |
| **Path / placeholder rewriting** (`.claude/…`→`.cursor/…` in content) | `render_lib.py` (846) | Removed if content is tool-agnostic |
| Per-type renderers (skills, agents, templates, recipes, canonical-scripts) | 5 scripts (~2,300) | Collapse into one copy pass |
| **Split layout** (Codex `.agents/` + `.codex/`) + **extras** (Cursor / Antigravity rules) | configs + `render_skills.py` | This is the symmetry change |
| Determinism / manifest-safety / advisory checks | `verify_deterministic.py` 515, `verify_advisory.py` 358, `test_manifest_safety.py` 254 | Keep the *guarantees*; the checks shrink (a copy is trivially deterministic) |
| Profile config parser + driver | `aid_profile.py` 586, `run_generator.py` 89 | Shrinks with the config surface |

Symptoms that motivated this work:
- A production bug: in a multi-tool repo, Cursor executed the **old `.claude/` skills** instead of `.cursor/`.
- The Codex **split layout** (`.agents/` + `.codex/`) is asymmetric and unique among tools, breaking the mental model and the prune logic.
- `AGENTS.md` is now the Linux-Foundation cross-tool standard (read natively by Cursor, Codex, Copilot, Windsurf, Gemini); Cursor also reads `CLAUDE.md`. AID's fully-rendered parallel trees run against that grain.

## 3. Users & Stakeholders

- **AID adopters / company developers** — the primary beneficiaries. Different developers prefer different host tools (some Cursor, some Claude Code, some Codex); multi-tool coexistence in one repo is a real, supported requirement. They need each tool to use *its own* content consistently, with no cross-tool contamination.
- **AID maintainers** — must maintain the generator; the current ~7,000 LOC / 13-script pipeline is a maintenance and review burden.
- **AID methodology itself (dogfood)** — the repo's own `.claude/` tree is produced by this generator and must stay byte-identical to `profiles/claude-code/.claude/` (§7a invariant).

## 4. Scope

### In Scope
*(Items marked ❓ depend on scope-boundary decisions currently with the user.)*

1. **Symmetric layout:** Codex unify (`.agents/` → `.codex/{agents,skills,aid}`); remove **all** AID rules folders (`.cursor/rules/` + Antigravity `.agent/rules/`) and **delete `canonical/rules/` + the extras mechanism entirely**; fold always-on guidance into the root context file (all tools); re-render all profiles.
2. **Per-tool format verification** → decide uniform-markdown per tool (keep a native format only where a tool *provably* requires it). ❓ depth depends on Decision 1.
3. **Collapse the generator** — merge per-type renderers; drop unneeded format branches + their conformance tests; minimize path rewriting — into a copy-based generator that preserves determinism + manifest + render-drift guarantees.
4. **Migration = complete replacement, auto-migrate + prune** (CONFIRMED): existing installs move `.agents/`→`.codex/` and drop `.cursor/rules/`; AID-owned orphans (FR7 markers) absent from the new version's manifest (FR7a) are pruned automatically.
5. **Update all dependents:** `release.sh` tarball roots, install libs (`lib/aid-install-core.sh` + `lib/AidInstallCore.psm1`) + vendored copies, emission manifests, `tests/canonical/*` + `tests/windows/*`, `docs/*` + synced `site/*`, `.aid/knowledge/*`, `canonical/EMISSION-MANIFEST.md`, profile READMEs.
6. ~~Root-agent multi-tool routing directive~~ — **DROPPED 2026-06-20** (FR9); same-version + uniform behavior make it unnecessary.
7. **Single `aid update`, all installed tools kept at one version** (no per-tool selection) — **CONFIRMED 2026-06-20** (FR10 + FR11). Includes aligning `aid add` / initial install to the same-version invariant.

### Out of Scope
- Changing what each host tool natively supports / how each tool *executes* skills (AID controls content, not tool runtimes).
- A wholesale move to the single-source `AGENTS.md` + symlink industry model (note for a future work).
- Adding host tools beyond the current 5.

## 5. Functional Requirements

- **FR1 — Symmetric layout.** All 5 tools render the uniform **internal** shape `{agents, skills, aid}` under each tool's **host-required** root dir (`.claude`, `.cursor`, `.codex`, `.github`, `.agent` — host-mandated, **not** renamed) + a root context file (`CLAUDE.md` for Claude Code, `AGENTS.md` for the rest) + a shared `.aid/`. Symmetry is the internal structure + root file + shared `.aid/`, not the outer dir name. No split layouts. **AID emits no tool-only rules/extras folder** — always-on guidance lives in the root context file, which every supported tool reads as always-on context (see FR3; the always-on *guarantee* is verified per tool in FR4a — note the Cursor background-agent caveat). Tools may *offer* an optional rules folder for conditional/glob rules; AID uses none.
- **FR2 — Codex unify.** Codex assets and agents both live under `.codex/{agents, skills, aid}`; `.agents/` is retired. **This consciously supersedes the work-003 content-isolation rule R6/D1** (which mandated Codex AID content under `.agents/aid/` and `.codex/` carrying only `agents/`) — retiring the split is the entire point of the unification. `content-isolation.md` R6 is updated to match via **feature-004's KB lockstep**, so the cornerstone evolves on purpose with a paper trail, not silently.
- **FR3 — All AID rules folders removed; always-on guidance consolidated into the root context file (all tools).** Delete **both** `.cursor/rules/` **and** Antigravity's `.agent/rules/` outputs, and **delete `canonical/rules/` + the `[[extras.rules]]` extras mechanism entirely**. The always-on methodology + review guidance moves into the root context file (`CLAUDE.md` for claude-code; `AGENTS.md` for cursor/codex/copilot/antigravity), which **every supported tool reads as always-on context** (research-indicated 2026-06-20; the always-on *guarantee* is verified per tool in FR4a). **No glob-scoped/conditional rules for now** (future work; note each tool's conditional mechanism *differs* — `.claude/rules` `paths:`, `.cursor/rules` `globs:`, `.github/instructions` `applyTo:`, `.agents/rules` `trigger:glob`; Codex has none — so re-introducing them later is per-tool, not uniform). *(This **supersedes the earlier Q2 decision** to retain `canonical/rules/` for Antigravity: the all-tools research indicates `AGENTS.md` carries Antigravity's always-on rules natively, so a dedicated rules folder is unnecessary — verified in FR4a before the build locks. The `.agent/` vs `.agents/` folder-name currency is a separate FR4a verify-item and is moot here since the folder is removed regardless.)*
- **FR4 — Uniform format (verified).** Skills and agents are uniform markdown across tools, *unless* a per-tool capability check proves a tool needs its native format; any retained native format is a documented exception. **(Confirmed 2026-06-20: commit to uniform markdown as the target, verify-first, native format kept only where provably required.)**
- **FR4-distinction — Format ⊥ behavior, but metadata is behavior (agreed 2026-06-20).** The *prose/body* of a skill or agent re-encodes freely between formats without affecting behavior. But **behaviorally-significant metadata is behavior wearing a format's clothes, not formatting**, and MUST be preserved and translated into each tool's idiom across any re-encoding — never dropped. It comprises: **activation** (`alwaysApply` / glob / `trigger` / a skill's `description`), **execution** (`model`, `reasoning_effort`), **capability** (`allowed-tools` / permissions), and **dispatchability** (invocable agent vs background reading). "Uniform format" governs the container and prose only; it must not flatten this metadata away. Net: *behavior = (instruction content + behavioral metadata), executed within each tool's capability ceiling.*
- **FR4a — Per-tool capability study (gating deliverable).** Before any format-branch change, produce a documented study of each of the 5 tools: how it discovers and executes agents, skills, and rules; which formats it natively supports; and what is required for *behaviorally-consistent* execution. **Its core job is to identify, per tool, the behaviorally-significant metadata (per FR4-distinction: activation, execution/model, capability/permissions, dispatchability) and define how each item is preserved/translated when content is re-encoded to the uniform format** — so the re-encoding cannot silently change behavior. The FR4 format decision is **gated** on this study. It is a tracked deliverable, not an assumption, and is structured so a future/6th tool can be assessed the same way.
  - **Early FR4a inputs (all-tools rules/format research, 2026-06-20 — verify against live docs in the study):** (1) **Codex agents are TOML-native** — markdown agents are not discovered as native Codex subagents (GitHub codex #15250); the study must determine whether AID relies on Codex-native **named dispatch** (→ keep TOML as the FR4 documented exception) or **injects agents as prose** (→ uniform markdown is fine). Codex is the **only** tool whose agent format truly diverges (Copilot `.agent.md`, Antigravity, Cursor are all markdown-ish). (2) **Cursor reliability:** `AGENTS.md` is reportedly not always auto-loaded for background agents — verify the always-on guarantee, not just that the file is read. (3) **Token cost:** always-on root-file content loads every request — keep it lean. (4) Re-verify **Antigravity**'s always-on guarantee (`AGENTS.md`, v1.20.3+) and **which rules-folder name is current** (`.agents/` plural vs `.agent/` singular — sources conflict; the repo profile comment and the research disagree) against live docs.
- **FR5 — Tool-agnostic content.** Canonical content references its own tree relatively / via a single placeholder; the generator performs no per-tool path rewriting (or the minimum that remains irreducible).
- **FR6 — Copy-based generator.** "Render profile X" = copy `canonical/{skills,agents,aid}` into `.X/`, write the root context file, emit a prune manifest. Per-tool config reduces to `{dir name, root filename, capabilities}`.
- **FR7 — Migration = complete replacement, auto-migrate + prune (CONFIRMED 2026-06-20).** `aid update` fully **replaces** the prior AID-delivered content with the current version's content: old layouts (Codex `.agents/` split, Cursor `.cursor/rules/`) are migrated/removed and orphaned AID files pruned automatically, in the same pass that moves the repo to latest (FR10). No stranded or duplicate trees; user content untouched.
  - **Prune/replace authority — the per-version manifest is the source of truth.** Anything that (a) is **AID-owned** AND (b) is **not present in the current version's manifest** may be pruned or changed. AID-ownership is established by **any** of three independent markers (content-isolation cornerstone, work-003):
    1. filename starts with **`aid-`**, OR
    2. located **inside an `aid/` folder**, OR
    3. located **inside an AID region** (`AID:BEGIN` → `AID:END`) of a shared / root-agent file.
  - Content matching **none** of the three markers is user content and is never pruned or modified.
- **FR7a — Every shipped version carries a manifest.** Each AID version ships a manifest enumerating its complete AID-delivered file set (per tool). Migration/prune diffs the on-disk AID-owned content (by the FR7 markers) against this manifest; the diff is what gets pruned/replaced. The layout change (`.agents/`→`.codex/`, drop `.cursor/rules/`) is therefore handled automatically: those paths are AID-owned and absent from the new manifest.
- **FR8 — Dependents in lockstep.** Release packaging, install/uninstall/prune (bash + PowerShell parity), emission manifests, tests, docs, KB stay consistent with the new layout.
- **FR9 — Routing directive: DROPPED (2026-06-20).** No per-tool routing/scoping steer in the root files. Same-version (FR10) + uniform behavior (FR4) make a cross-read benign, so an explicit directive is unnecessary. *(Conditional on the FR4a study confirming uniform behavior actually holds; revisit only if a tool is found that cannot share behavior.)*
- **FR10 — Single `aid update`, all tools, one version (CONFIRMED 2026-06-20).** There is one update command, `aid update`, with **no per-tool selection** (no tool-name positional). All AID tools installed in a repo are **always kept at the same version**. Behavior:
  1. **Outside an AID project/repo:** try to update only the **CLI** to the latest version (no-op if already latest).
  2. **Inside an AID project/repo:** (a) update the **CLI** first, then (b) update **all** of the repo's installed tools to the latest version.
  - **Arguments:** `--from-bundle`, `--dry-run`, `--version <version>` (pin **all** tools to a specific version), `--target <dir>` (operate on the given repo/project dir), `--force`.
  - **Note (deliberate behavior changes vs the prior CLI, flagged for feature-003 / aid-specify):** FR10 intentionally (a) **removes** the existing `aid update [<tool>...]` positional (no per-tool selection) and (b) **broadens `--dry-run`** to the main update path. These are designed changes, not parity regressions (evidence: `bin/aid:147-148`).
- **FR11 — Same-version invariant across all entry points.** The "all installed tools at one version" invariant (FR10) holds wherever a tool can be introduced or change version, not only on `aid update`:
  - **`aid add <tool>` — first tool in the repo:** install it at the **CLI's** version.
  - **`aid add <tool>` — additional tool (repo already has tools):** install it at the **existing tools'** version (preserve repo consistency; `add` does **not** force an update — `aid update` is what advances the whole repo to latest).
  - A partial failure must not silently leave a repo at mixed versions (atomic, or a clear error naming the inconsistent state).

## 6. Non-Functional Requirements

- **NFR1 — Simplicity (primary goal).** Substantial reduction in generator script count and LOC (target: from 13 scripts / ~7,000 LOC toward a small handful / one core generator) **with every guarantee intact**.
- **NFR2 — Determinism.** Re-rendering `canonical/` is byte-deterministic; render-drift CI stays green.
- **NFR3 — Behavioral consistency (the primary goal).** A skill or agent must *behave* consistently in each tool, independent of the language/format it is defined in. The work delivers the same content/instructions to every tool and maximizes behavioral parity within each tool's capabilities. Where a tool's runtime genuinely cannot match another's, that gap is **identified by the FR4a study and documented**, never hidden. Free tool choice (one tool, another, or both simultaneously) must not change the dev's AID experience.
- **NFR4 — Backward compatibility.** Existing installs across all channels (curl / npm / pypi / offline) and both shells migrate cleanly.
- **NFR5 — Maintainability.** A new host tool should be addable via config (dir name, root filename, capabilities), not new emitter code.

## 7. Constraints

- **C1 — Content-isolation cornerstone (work-003).** `aid-` prefix on tool-native files; AID-owned dirs nested under `aid/`; prune by prefix + manifest membership; root-agent files updated **in place** between `<!-- AID:BEGIN/END -->` markers (no `.aid-new`). *(This work consciously **revises** cornerstone rule R6 for Codex — see FR2 — to permit `.codex/{agents,skills,aid}`; the `content-isolation.md` update is owned by feature-004's KB lockstep. All other cornerstone rules remain binding.)*
- **C2 — Dogfood byte-identity (§7a).** Repo-root `.claude/` stays byte-identical to `profiles/claude-code/.claude/`.
- **C3 — ASCII-only shipped scripts** (`bin/*`, `lib/*`, `install.sh`/`.ps1`, `release.sh`) — CI-guarded.
- **C4 — render-drift CI gate** — `profiles/` must regenerate clean from `canonical/`.
- **C5 — Prune manifest** — safe orphan removal (aid-prefixed, not in new manifest) must keep working through the layout change.
- **C6 — Bash + PowerShell parity** for all install/update/prune/migration logic.
- **C7 — master is PR-protected** — work lands via PR from a delivery branch; the agent pushes as the non-admin bot; the user merges + tags.

## 8. Assumptions & Dependencies

- **A1** — All 5 tools can consume uniform markdown skills/agents referenced via their root context file. **To be verified** per tool before any native-format branch is deleted (this is the gating research). *(Research 2026-06-20: research-indicated for cursor/copilot/antigravity — markdown-ish formats + `AGENTS.md` read as always-on context (the always-on *guarantee* is pending FR4a verification, incl. the Cursor background-agent caveat); **Codex is the exception — TOML-native agents** — pending FR4a's named-dispatch-reliance determination.)*
- **A2** — Codex agents do not require native TOML auto-discovery for AID's use; to be confirmed in A1.
- **A3** — Antigravity's always-on rules **fold into `AGENTS.md`** (research-indicated 2026-06-20: read as always-on context, v1.20.3+; the always-on guarantee is verified in FR4a); its `.agent/rules/` folder is dropped with the rest (FR3). The `.agent/` vs `.agents/` folder-name currency is moot — the folder is removed entirely (it remains an FR4a verify-item only for completeness).
- **D1** — Depends on the content-isolation cornerstone (work-003) prune/marker model being in place. **This work revises that cornerstone's rule R6 for Codex** (FR2): the unified `.codex/{agents,skills,aid}` layout replaces the old `.agents/aid/` + `.codex/agents/`-only split; the `content-isolation.md` doc update is owned by feature-004.
- **D2** — Touches release/install machinery shared with the v1.1.x line; sequencing vs. the next release must be coordinated.
- **D3** — Blast-radius map (40+ files) from the pre-interview investigation is the starting inventory.

## 9. Acceptance Criteria

- **AC1** — All 5 tools render the uniform internal `{agents, skills, aid}` shape under their host-required root dir; the same canonical skill/agent content is provably present in each tool's tree.
- **AC2** — Generator script count + LOC reduced substantially, with determinism + prune manifest + render-drift guarantees intact.
- **AC3** — All CI green: render-drift, `tests/run-all.sh` (53+ suites), generator self-tests, installer (Windows + Linux), docs (Astro) build, version-sync.
- **AC4** — A real multi-tool repo (claude-code + cursor + codex) verified: each tool uses its own tree; no cross-tree contamination.
- **AC4a** — Behavioral-consistency check: for a representative skill and a representative agent, behavior is verified consistent across the **three tools this work's own scenario actually uses — Cursor + Claude Code + Codex** — against the parity criteria from the FR4a study. **Copilot CLI + Antigravity behavioral parity is *asserted by the Finding-D1 content-identity argument, not exercised*** (CI cannot run five live host-tool runtimes); that residual is named here, not buried in a confidence column.
- **AC4b** — The FR4a per-tool capability study is **produced and documented** before any format-branch is deleted: for each tool it records discovery/execution, natively-supported formats, and the behaviorally-significant metadata (activation / execution / capability / dispatchability) plus how each item is preserved/translated under the uniform format. The FR4 decision cites it.
- **AC5** — Existing installs with old layouts (`.agents/`, `.cursor/rules/`) migrate by **complete replacement** on `aid update`: AID-owned orphans (by `aid-` prefix / inside `aid/` / inside an AID region) absent from the new version's manifest are pruned; no stranded or duplicate trees; user content untouched. Verified on old-layout fixtures.
- **AC6** — §7a byte-identity, ASCII-only, and content-isolation invariants all hold post-change.
- **AC7** — N/A (routing directive dropped, FR9).
- **AC8** — `aid update` updates all installed tools to one version (CONFIRMED). Verified: one command, no per-tool selection; outside-repo updates the CLI only; inside-repo updates the CLI then all tools; the five arguments behave as specified; no repo ends in a mixed-version state (including via `aid add` / initial install).

## 10. Priority

**High.** Foundational for the supported multi-tool coexistence story and a prerequisite for confidently shipping further releases on the v1.1.x line. Must be done carefully (full path) — correctness and backward-compatible migration outrank speed.
