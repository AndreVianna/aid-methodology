# Symmetric Copy-Based Generator

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-20 | Feature identified from REQUIREMENTS.md §5 FR1/FR2/FR3/FR5/FR6, §4 In-Scope 1, §7 C1/C2/C3/C4, §9 AC1/AC2/AC6 | /aid-interview |
| 2026-06-20 | Cross-ref Q1: layout reworded — uniform internal `{agents,skills,aid}` shape under host-required root dir (not literal `.{tool}/`) | /aid-interview |
| 2026-06-20 | Cross-ref Q2: cursor-rules removal scoped to Cursor; `canonical/rules/` + mechanism retained for Antigravity | /aid-interview |
| 2026-06-20 | All-tools research: SUPERSEDES Q2 — drop ALL rules folders (cursor + antigravity) + delete `canonical/rules/`/mechanism entirely; fold always-on into root context file | /aid-interview |
| 2026-06-20 | Technical Specification drafted (aid-specify): 13→4 scripts (~7,000→~900–1,300 LOC); Finding G1 (root file is install-merged, not a generator output); 8 decisions confirmed — A3=(a) single `{AID_ROOT}` placeholder + delete `rewrite_install_paths`, A4=`canonical/aid/` reshape, A1=reconcile rules into root file, A2=dir constants, A6=4-script set, A7=E-CODEX-1 in-PR, A8=bash byte-identity suite, A5=verify_advisory re-point | /aid-specify |
| 2026-06-20 | A+ review (B+ → fix): softened always-on over-claim in Description ("verified by feature-001"→"feature-001's verify-item, AC4a, to be verified"); corrected `_copy_root_agent_file` cite to 388–554 | /aid-specify REVIEW |
| 2026-06-20 | FR5 reversed A3 from Option (a) FULL to Option (c) MINIMAL (intent-fidelity review correction): canonical source is already tool-agnostic + `rewrite_install_paths` is already one regex keyed on `{root}`; (a)'s `{AID_ROOT}` rewrite would churn ~93 files + risk the §7a byte-identity invariant for an aesthetic gain. `rewrite_install_paths` now *reduced* to the minimal one-line `{root}`-prefix substitution (multi-dir branching removed), not deleted; no canonical content rewritten; A4 (`canonical/aid/` reshape) unchanged | intent-fidelity review |

## Source

- REQUIREMENTS.md §5 (FR1, FR2, FR3, FR5, FR6)
- REQUIREMENTS.md §4 (In Scope 1)
- REQUIREMENTS.md §7 (C1, C2, C3, C4)
- REQUIREMENTS.md §9 (AC1, AC2, AC6)

## Description

Replace the over-engineered 13-script, ~7,000-LOC render pipeline with a small,
copy-based generator that rests on a symmetric per-tool layout. "Render profile X"
becomes: copy the canonical skills, agents, and aid content into each tool's
host-required root dir, write the tool's root context file, and emit a prune manifest —
with no per-tool *content* rewriting (the canonical source is already tool-agnostic);
the only surviving path transform is the irreducible one-line `{root}`-prefix
substitution (FR5 Option (c) MINIMAL). Every one of the five tools renders the same
uniform **internal** shape `{agents, skills, aid}` under its host-required root dir
(`.claude`/`.cursor`/`.codex`/`.github`/`.agent` — host-mandated, not renamed) plus a root
context file (CLAUDE.md for Claude Code, AGENTS.md for the rest) and a shared `.aid/`.

Symmetry means retiring the special cases: Codex's split `.agents/` + `.codex/` layout
is unified under `.codex/`, and **all AID rules folders are removed** — both Cursor's
`.cursor/rules/` and Antigravity's `.agent/rules/` outputs, plus `canonical/rules/` and
the `[[extras.rules]]` mechanism, are **deleted entirely**. The always-on methodology +
review guidance is folded into the root context file (`CLAUDE.md` / `AGENTS.md`), which
every supported tool reads as always-on context (the per-tool always-on guarantee is
feature-001's verify-item, AC4a — to be verified there). No glob-scoped/conditional rules for now.
Per-tool configuration shrinks to just `{dir name, root filename, capabilities}`.

This feature also owns the work that falls out directly from collapsing the generator:
deleting the now-dead format-branch conformance tests and de-wiring them from CI,
re-rendering the dogfood `.claude/` tree, and adding a mechanized guard for the §7a /
C2 byte-identity invariant. The generator preserves every existing guarantee —
deterministic output, prune manifest, render-drift CI, content isolation, ASCII-only
shipped scripts.

## User Stories

- As an AID maintainer, I want one small copy-based generator instead of a 13-script compiler, so that maintaining and reviewing the render pipeline stops being a burden.
- As an AID adopter using several tools in one repo, I want every tool to render the same uniform internal `{agents, skills, aid}` shape (under its host-required root dir) with the same content, so that there are no asymmetric special cases that confuse the mental model or cause cross-tool contamination.
- As the AID dogfood repo, I want my own `.claude/` tree re-rendered and guarded for byte-identity with the canonical profile, so that the methodology provably eats its own cooking after the simplification.

## Priority

Must

## Acceptance Criteria

- [ ] Given the new copy-based generator, when all 5 tools are rendered, then each renders the uniform internal `{agents, skills, aid}` shape under its host-required root dir with a root context file and shared `.aid/`, and the same canonical skill/agent content is provably present in each tool's tree. (AC1)
- [ ] Given the generator replaces the 13-script pipeline, when its script count and LOC are measured, then they are substantially reduced while determinism, the prune manifest, and the render-drift CI guarantees remain intact. (AC2)
- [ ] Given the change is complete, when the §7a byte-identity, ASCII-only, and content-isolation invariants are checked (including the mechanized §7a/C2 byte-identity guard), then all hold. (AC6)

---

## Technical Specification

> **Feature character.** This is the **generator-collapse** feature — the largest, most
> technical slice of work-005. It replaces the 13-script / ~7,000-LOC compiler with a small
> **copy-based generator** resting on a symmetric per-tool layout (FR1/FR5/FR6), unifies the
> Codex split (FR2), deletes all rules-folder machinery (FR3), preserves every guarantee
> (NFR2, C4, C5, content-isolation), and adds a mechanized §7a/C2 dogfood byte-identity guard.
> It **acts on feature-001's settled FR4 decision** (uniform markdown, verify-first) and does
> **NOT** re-litigate it — but it retains a single conditional TOML branch gated on
> feature-001's `E-CODEX-1` (see §"Codex Unify"). **Install-time migration of user repos is
> feature-003, not here** — this feature reshapes only the *committed `profiles/*` output trees*
> and the generator that produces them.

### Section Applicability

| Section | Status | Rationale |
|---------|--------|-----------|
| **Data Model** | **Activated** | No relational DB (`schemas.md`). The "data model" = the **shrunk per-tool config schema** (`{dir, root-file, capabilities, tool-name map}`) + the **unchanged emission-manifest JSONL schema** (C5/NFR2). |
| **Feature Flow** | **Activated** | The new render pipeline: **load profile → copy three trees → (translate metadata in place) → manifest → diff/prune → verify**. Replaces the 5-renderer fan-out. |
| **Layers & Components** | **Activated** | The new script set + the explicit **delete / merge / survive** list for all 13 scripts (NFR1 evidence) + CI de-wiring. |
| **AI Enhancements** | **Activated** | How uniform-markdown agents/skills carry behavioral metadata under the copy model, and where the surviving per-tool **translate** step (`allowed-tools` Bash→Terminal/shell) lives (Finding D1 + feature-001 `_remap_tools_list`). |
| **Migration Plan** | **Activated (output-tree only)** | How `profiles/*` rendered trees reshape (Codex unify, rules removal). The *install-time* user-repo migration mechanism (`aid update` prune) is **feature-003** — explicitly excluded. |
| **Telemetry & Tracking** | **Activated (light)** | The render run's PASS/FAIL surface (`verify_deterministic`, render-drift CI, the new §7a guard) — the only "telemetry" a maintainer-tool has. |
| API Contracts · UI Specs · Events & Messaging · DDD/CQRS/State Machines · BDD · Security · Cache/Search/Batch/Mobile/Cloud/Hardware/Recovery · External Integrations | **N/A** | AID ships no runtime app/API/UI/events/auth/perf surface (`pipeline-contracts.md`, `integration-map.md`). The generator is offline maintainer tooling. The relevant "contract" — the Renderer Contract + emission-manifest — is covered under Data Model + Feature Flow. |

---

### Target Architecture — The Copy-Based Generator

#### What "render profile X" becomes

```
render(profile):
  root = profile.root_dir            # ".claude" | ".cursor" | ".codex" | ".github" | ".agent"
  copy   canonical/agents/  → {root}/agents/     (per-tool agent metadata translation, below)
  copy   canonical/skills/  → {root}/skills/     (per-tool skill metadata translation, below)
  copy   canonical/aid/     → {root}/aid/        (verbatim — tool-agnostic, no rewriting)
  emit   manifest record per copied file → {profile}/emission-manifest.jsonl
  diff   prev-manifest vs curr → delete removed_dst (pure-mirror, unchanged C5 semantics)
```

Every tool renders the **uniform internal shape `{agents, skills, aid}`** under its
host-required root dir (FR1). The root context file (`CLAUDE.md`/`AGENTS.md`) is **NOT
emitted by the generator** — see the load-bearing finding below.

#### Finding G1 (load-bearing) — the root context file is already out of the generator's scope

The generator today emits only `agents/skills/scripts/templates/recipes`. The committed
`profiles/{tool}/CLAUDE.md` and `profiles/{tool}/AGENTS.md` are **profile-local hand-maintained
files, NOT render outputs** (antigravity.toml Q-J: *"the AGENTS.md doc itself is a profile-local
committed file, NOT emitted"*; no `run_generator.py` pass writes them; `tests/canonical/test-agents-md-invariant.sh`
guards them as hand-maintained). The **AID:BEGIN/END region merge into the user's repo root file**
is performed by the **install libs** (`lib/aid-install-core.sh:388–554` `_copy_root_agent_file`, mirrored in
`AidInstallCore.psm1`), not the generator.

> **Implication for FR3 ("fold always-on guidance into the root context file"):** the *render
> pipeline change* this feature owns is purely the **rules-folder deletion** (drop `canonical/rules/`,
> `_render_cursor_extras`, `[extras]`, the `.cursor/rules/` + `.agent/rules/` outputs). The *content*
> of the always-on guidance already lives in the committed `CLAUDE.md`/`AGENTS.md` files and the
> install-lib region-merge — **no generator code emits it**. This feature must (a) confirm the
> methodology/review guidance that lived in the two `.mdc` rules is **already present** in the
> committed root context files (or move it there as a content edit, not a code path), and (b) delete
> the rules machinery. It does **not** add a "write root file" generator step, because none is needed.

> **Confirmed (2026-06-20) — A1:** the two canonical rules (`aid-methodology.mdc`, `aid-review.mdc`)
> are retired by (i) deleting `canonical/rules/` + the extras mechanism, and (ii) ensuring their
> always-on substance survives in the committed `CLAUDE.md`/`AGENTS.md` AID:BEGIN/END region
> (a content reconciliation, owned here as a one-time edit). Confirm this is the intended home and
> that no separate generator "write-root-file" step is wanted. *(Recommended: yes — matches G1 and
> the FR1/FR3 "always-on guidance lives in the root context file" wording.)*

#### Per-tool config — reduced to `{dir, root-file, capabilities, tool-name map}`

| Field | Today (TOML keys) | After collapse |
|-------|-------------------|----------------|
| Root dir | `output_root` / `agents_root` + `assets_root` (split) | **single `root_dir`** basename (`.claude`/`.cursor`/`.codex`/`.github`/`.agent`) — Codex no longer split (FR2) |
| Root filename | `project_context_file` + `filename_map.project_context_file` | `root_file` (`CLAUDE.md` for claude-code, `AGENTS.md` for the rest) — used only by the install lib, retained for it |
| Capabilities | `[capabilities]` 4 flags | unchanged (consumed by skills' graceful-degradation, e.g. `background_execution`) |
| Tool-name map | `[tool_names]` | **retained** — the one surviving translation (cursor `Bash→Terminal`, copilot `Bash→shell`); see AI Enhancements |
| `[agent].format` | `markdown`/`toml`/`copilot-agent`/`antigravity-rule` | **collapses to `markdown` for 4 tools**; **`toml` retained as a dormant branch** for Codex, gated by E-CODEX-1 (FR4 / feature-001) |
| `agents_dir`/`skills_dir`/`templates_dir`/`recipes_dir`/`scripts_dir`/`rules_dir`/`[extras]`/`filename_map`/`model_tiers` | per-profile | **`rules_dir`+`[extras]` DELETED** (FR3); `*_dir` become **fixed internal constants** (`{agents,skills,aid}` shape is uniform — NFR5); `model_tiers` retained (feeds the metadata translation); `filename_map` minimized (see FR5 below) |

> **Confirmed (2026-06-20) — A2:** the sub-dir names (`agents`, `skills`, `aid`) become **hardcoded
> constants in the generator**, not per-profile keys, since FR1 makes the internal shape uniform
> across all 5 tools. A 6th tool is added by one config row of `{root_dir, root_file, capabilities,
> tool_names}` (NFR5) — never new dir keys. *(Recommended: yes.)*

---

### FR5 — How content becomes tool-agnostic (the path-rewrite question)

Today `render_lib.rewrite_install_paths` is **already a single regex keyed on one variable — the
`{root}` basename** — rewriting `canonical/{scripts,templates,recipes}/…` → `{root}/aid/{…}/` and
`canonical/{skills,agents,rules}/…` → `{root}/{…}/` in text files, per profile. The canonical
source is **already tool-agnostic**; the **only** per-tool divergence is that one `{root}` prefix
token. Two facts frame the FR5 reduction:

1. **The internal shape is now uniform** (`{agents, skills, aid}` under *every* root) — so the
   multi-dir branching that maps several canonical sub-dirs to several output sub-dirs collapses to
   one uniform mapping; the surviving substitution is a single `{root}`-prefix regex, the **same
   shape for all 5 tools**.
2. The **only** thing that differs per tool is the `{root}` basename — so the substitution reduces
   to that one prefix token. There is **no need to rewrite canonical content** to a placeholder
   (Option (a)); the irreducible one-line `{root}`-prefix substitution suffices (Option (c)).

**Decision (FR5, intent-review → Option (c) MINIMAL):** `rewrite_install_paths` is **reduced to
the minimal one-line `{root}`-prefix substitution** — *not deleted*. Only its **multi-dir branching
logic is removed**; the single regex keyed on the `{root}` basename (the irreducible minimum FR5
explicitly permits) stays, because the canonical source is already tool-agnostic and the per-tool
difference is just that one prefix token. No `{AID_ROOT}` placeholder is introduced and **no
canonical content is rewritten** (Option (a) FULL would have churned ~93 files + risked the §7a
byte-identity invariant for an aesthetic gain). `substitute_filenames` (the
`{project_context_file}`/`{reviewer_output_file}`/`{open_questions_file}` placeholders) is the
**other** remaining text transform on copied files; even those collapse toward a single value since
all non-claude tools share `AGENTS.md`/`STATE.md`/`additional-info.md` (claude-code differs only on
`CLAUDE.md`).

> **Confirmed (2026-06-20, intent-review) → Option (c) MINIMAL selected:** keep the existing
> one-line `{root}`-prefix substitution (the irreducible minimum FR5 explicitly permits) and
> **delete only the multi-dir branching logic** in `rewrite_install_paths`. Do **NOT** introduce
> an `{AID_ROOT}` placeholder and do **NOT** rewrite canonical content. **Rationale:** the
> canonical source is **already tool-agnostic**, and `rewrite_install_paths` is **already a single
> regex keyed on one variable — the `{root}` basename**; the only per-tool difference is that one
> prefix token. Option (a) FULL would churn ~93 canonical files for aesthetic byte-purity AND add
> §7a byte-identity-invariant risk, for an aesthetic gain; option (c) meets FR5's objective
> (consistency) with **~zero canonical churn**. Original options for reference —
> **(a) FULL** — rewrite canonical content to a single `{AID_ROOT}`-style placeholder, delete
> `rewrite_install_paths` outright (maximal FR5; touches every canonical file that references
> `canonical/scripts|templates|recipes/`); **(b) RELATIVE** — make references self-relative (no
> placeholder), delete the rewrite; **(c) MINIMAL (selected)** — keep the one-line `{root}`-prefix
> substitution as the "irreducible minimum" FR5 explicitly permits, deleting only the multi-dir
> branching logic. The choice sets how much canonical content this feature edits — (c) edits none.

> **Note:** `substitute_filenames` is retained regardless (it is tool-agnostic-friendly and tiny);
> FR5's reduction concerns the **path** rewriter (`rewrite_install_paths`, reduced to the one-line
> `{root}`-prefix substitution per Option (c)), not the filename placeholders.

---

### Data Model — Per-tool config schema + the (unchanged) manifest schema

#### Shrunk profile schema (replaces `aid_profile.py`'s ~10-field dataclass tree)

```toml
# profiles/<tool>.toml — after collapse
root_dir   = ".claude"            # host-required root basename (FR1)
root_file  = "CLAUDE.md"          # AGENTS.md for the other 4 (used by install lib, not the copy)
agent_format = "markdown"         # "markdown" for 4 tools; "toml" retained ONLY for codex iff E-CODEX-1 forces it
[tool_names]                      # the one surviving translation map (empty = identity)
Bash = "Terminal"                 # cursor; copilot has Bash="shell"; claude/codex/antigravity empty
[model_tiers] …                   # retained — feeds agent execution-metadata translation
[capabilities] …                  # retained — 4 flags consumed by skills' degradation logic
```

`output_root`/`agents_root`/`assets_root`/`*_dir`/`rules_dir`/`[extras]`/`[extras.rules]`/
`filename_map` (beyond the 3 placeholders, themselves candidates to inline) are **removed or
demoted to constants**. `LayoutConfig.common_parent()`/`install_root()`/`agents_root` split logic
is deleted with the Codex unify.

#### Emission-manifest schema — UNCHANGED (C5/NFR2 preservation)

The JSONL schema (`{_manifest_version:1}` sentinel + `{profile, src, dst, sha256}` records sorted
by `dst`, LF-only, binary write) stays **byte-for-byte as specified in `EMISSION-MANIFEST.md`**.
The copy generator still `add()`s one record per emitted file and still `diff()`s prev-vs-curr to
get `removed_dst` for pure-mirror deletion. **The safety boundary and its semantics do not change** —
only the code that *populates* the manifest shrinks (one copy walk instead of five renderers).
`EMISSION-MANIFEST.md`'s "Asset Kinds" table is updated to drop the `rules` row and collapse the
Codex split-layout column to a single `.codex/` root; the per-profile manifest **location** for
Codex moves from `codex/` (common parent of two roots) to `codex/` (now the single `.codex/`
parent) — location string is unaffected.

---

### Feature Flow — Load → Copy → Translate → Manifest → Diff/Prune → Verify

```
run_generator.py (slimmed):
  for profile in sorted(profiles/*.toml):
    cfg          = load(profile)                      # tiny schema (above)
    prev         = EmissionManifest.load(...)         # unchanged
    curr         = EmissionManifest(cfg.name)
    copy_tree(canonical/agents → {root}/agents, translate=agent_metadata)   # see AI Enhancements
    copy_tree(canonical/skills → {root}/skills, translate=skill_frontmatter)
    copy_tree(canonical/aid    → {root}/aid,    translate=none)             # verbatim
    deleted = curr.diff(prev).removed → unlink + prune empty parents        # unchanged C5 pass
    curr.write(...)                                                         # unchanged manifest write
  run_verify()                                          # verify_deterministic (slimmed; see below)
```

The driver loses the 5-renderer import block; gains one `copy_tree(translate=…)` helper. The
**deletion/prune pass and manifest write are lifted verbatim** from today's `run_generator.py`
(lines 49–69) — that logic is already copy-model-shaped and needs no change.

> **Confirmed (2026-06-20) — A4:** `canonical/aid/` is the **new home for the AID-own trees**
> (`scripts`, `templates`, `recipes`) so the copy is a literal `canonical/aid/ → {root}/aid/`
> mirror (today they live at `canonical/{scripts,templates,recipes}/` and the renderer *nests*
> them under `aid/` in output). Reshaping canonical to pre-nest under `canonical/aid/` makes the
> copy a pure mirror with **zero path computation** — the cleanest copy model. *(Recommended: yes;
> it is the structural move that lets "copy" literally mean copy. Alternative: keep canonical flat
> and nest in the copy helper — one line, but less symmetric.)*

---

### Layers & Components — The new script set + the delete/merge/survive list

**Before → after (NFR1 evidence). 13 scripts → target 4.**

| # | Script (LOC) | Verdict | Rationale |
|---|--------------|---------|-----------|
| 1 | `render_agents.py` (865) | **MERGE → `render.py`** | The 4 format branches collapse to 1 (markdown) + 1 dormant TOML (E-CODEX-1). `_remap_tools`/`_remap_tools_list` (metadata translation) survive into the copy helper; `_build_frontmatter_md_copilot`, `_build_frontmatter_md_antigravity`, `_render_codex_toml` (markdown form) deleted; `_resolve_includes` retained if `{{include}}` still used. |
| 2 | `render_skills.py` (586) | **MERGE → `render.py`** | SKILL.md frontmatter translation (`allowed-tools` remap, `claude_code_optional` strip) survives; **`_render_cursor_extras` + `_build_trigger_frontmatter` + `_split_rule_body` DELETED** (FR3). |
| 3 | `render_templates.py` (256) | **MERGE → `render.py`** (verbatim copy) | Becomes part of the single `canonical/aid/` copy walk. |
| 4 | `render_recipes.py` (263) | **MERGE → `render.py`** (verbatim copy) | Same — folded into the `canonical/aid/` copy. |
| 5 | `render_canonical_scripts.py` (229) | **MERGE → `render.py`** (verbatim copy + exec-bit) | The exec-bit preservation logic is the only non-trivial bit; carries into the copy helper. |
| 6 | `render_lib.py` (846) | **SHRINK → `render.py` core** | `EmissionManifest` + `sha256_hex` + `read/write` survive (manifest is preserved). `substitute_filenames` survives (tiny). **`rewrite_install_paths` is reduced to the minimal one-line `{root}`-prefix substitution; its multi-dir branching + 6-dir constants are removed** (FR5, per A3 → Option (c) MINIMAL). |
| 7 | `aid_profile.py` (586) | **SHRINK** | Dataclass tree collapses to the 4-field schema; `LayoutConfig` split-root logic, `ExtrasConfig`, `RuleEntry`, `_KNOWN_AGENT_FORMATS` pruned to `{markdown, toml}`. Validator shrinks accordingly. |
| 8 | `run_generator.py` (89) | **SURVIVE (slimmed)** | The driver — loses the 5 renderer imports, keeps the load/diff/prune/manifest/verify spine. |
| 9 | `verify_deterministic.py` (515) | **SURVIVE (shrink)** | All 3 sub-checks kept (byte-identical re-render, presence audit, frontmatter parse) — they protect NFR2/C4. `_render_all` rewires to the single copy pass; `_profile_output_dirs` loses the Codex split branch. |
| 10 | `verify_advisory.py` (358) | **SURVIVE (re-point)** | Advisory checks retained; re-pointed at the new layout. *(Assumption A5 — confirm whether any advisory check was rules/extras-specific and should be dropped.)* |
| 11 | `test_manifest_safety.py` (254) | **SURVIVE (unchanged logic)** | The two safety-boundary tests operate on `EmissionManifest.diff` + the deletion pass — both preserved. Fixture paths stay valid (`.claude/agents/…`). |
| 12 | `test_copilot_emitter.py` (1004) | **DELETE** | Conformance test for the deleted `copilot-agent` branch (FR3 / feature-002 owns dead-test deletion). De-wire from `test.yml:97` + `release.yml:166`. |
| 13 | `test_antigravity_emitter.py` (1129) | **DELETE** | Conformance test for the deleted `antigravity-rule` branch. De-wire from `test.yml:98` + `release.yml:167`. |

**Resulting script set (4):** `render.py` (the copy generator: config load + copy + metadata
translate + manifest + diff/prune), `run_generator.py` (driver), `verify_deterministic.py`,
`verify_advisory.py` — plus the surviving test `test_manifest_safety.py`. **~7,000 LOC → est.
~900–1,300 LOC** (deletes ~2,133 LOC of dead conformance tests outright + the 4 format branches +
`rewrite_install_paths`'s multi-dir branching; the bulk that remains is the manifest + verify gates
that must stay).

> **Confirmed (2026-06-20) — A6 (script decomposition):** consolidate to the **4-script set above**
> (one `render.py` core). Alternatives: keep `render_lib.py` + `render.py` as 2 files (manifest lib
> vs copy logic) for a 5-script set; or fully inline verify into `render.py` for a 2–3 script set.
> *(Recommended: the 4-script set — keeps the manifest/verify gates as named, independently
> self-testable CI units, which `test.yml` invokes by name, while collapsing the 5 emitters + lib
> into one `render.py`.)*

**CI de-wiring (this feature owns it):** remove lines 97–98 from `.github/workflows/test.yml`
(`generator-selftests` job) and lines 166–167 from `.github/workflows/release.yml`; update the
remaining self-test invocations to the new script names (`render.py --self-test` replaces the per-
emitter `--self-test` calls). The `render-drift` job (test.yml:34, release.yml:123) is **unchanged
in shape** — it still runs `run_generator.py` and `git diff --exit-code -- profiles/`.

---

### AI Enhancements — Behavioral metadata under the copy model

Per **Finding D1** (feature-001): AID dispatches agents by **name string** through the host's
generic `Agent(subagent_type: aid-<name>, …)` tool — there is **no host-native dispatch**, so the
agent's *format* (markdown vs TOML) is irrelevant to dispatchability; only its **discoverability
under its name** + its **behavioral metadata** matter. Under uniform markdown:

- **The uniform-markdown agent/skill body carries the metadata in YAML frontmatter** (`name`,
  `description`, `tools`/`allowed-tools`, `model`, `permissionMode`, `background`; skills add
  `argument-hint`). The copy is **byte-identical bodies** across tools (the §7a invariant).
- **Where per-tool translation still happens (preserved):** exactly the `tool_names` remap that
  `_remap_tools`/`_remap_tools_list` perform today — `allowed-tools`/`tools` `Bash→Terminal`
  (cursor) and `Bash→shell` (copilot). This is the **one proven `translate` step** (feature-001 AI
  Enhancements) and it **survives into the copy helper's frontmatter pass**. claude-code/codex/
  antigravity have empty `tool_names` → identity → the frontmatter is copied verbatim.
- **Execution metadata** (`model`, and Codex `model_reasoning_effort`): the markdown frontmatter
  carries `model` resolved per-tool from `[model_tiers]` (kept). Codex's `model_reasoning_effort`
  is the **one execution-axis item that may need the dormant TOML branch** — see Codex Unify.
- **Activation** (`alwaysApply`/glob/`trigger`/skill `description`): with rules folders gone (FR3),
  always-on activation is the root context file (install-lib region merge, G1), not a render
  artifact. Skill `description` (the skill-activation trigger) is carried verbatim in SKILL.md
  frontmatter.

Net: the copy model preserves the FR4-distinction metadata by (a) copying frontmatter verbatim for
identity-map tools and (b) running the single surviving `tool_names` translation for cursor/copilot.

---

### Codex Unify (FR2) + the dormant TOML branch (FR4 / E-CODEX-1 dependency)

**Layout (FR2):** `profiles/codex/.agents/{skills,aid}` + `profiles/codex/.codex/agents/` → unified
**`profiles/codex/.codex/{agents, skills, aid}`**. `.agents/` is retired. This deletes
`LayoutConfig`'s `agents_root`/`assets_root` split, `common_parent()`'s two-root logic, and
`_profile_output_dirs`'s split branch. The Codex emission-manifest stays at `codex/…` (now the
single `.codex/` parent). **This consciously supersedes content-isolation R6** (REQUIREMENTS FR2/C1);
the `content-isolation.md` doc edit is **feature-004's** job, not here.

**Agent format (FR4, inherited from feature-001):** the **expected outcome is uniform markdown for
Codex agents** — feature-001's Finding D1 closed the *dispatch* gap (AID never uses Codex-native
named dispatch). The **only open sub-question is discovery** (`E-CODEX-1`: does Codex *read* a
markdown agent's instructions + `model_reasoning_effort` from frontmatter?).

**Conditional design (the contingency this feature must handle without re-litigating FR4):**
- **If E-CODEX-1 is resolved `high`-confidence PASS** (markdown agents work for Codex) → Codex
  uses `agent_format = "markdown"` like the other 4; `_render_codex_toml` is **deleted**; the
  `toml` value is removed from the validator. Clean 1-format generator.
- **If E-CODEX-1 is unresolved or FAILs** → **retain exactly one dormant branch**: `agent_format =
  "toml"` for Codex only, keeping a **minimized `_render_codex_toml`** (the markdown-body →
  `developer_instructions` TOML wrapper) and the `[model_tiers.large]` detailed form for
  `model_reasoning_effort`. All other format branches (`copilot-agent`, `antigravity-rule`) are
  deleted regardless — they are not gated on anything.

> **Dependency (explicit):** this feature's Codex agent-format step **cannot be graded
> complete until feature-001 records the E-CODEX-1 verdict** in the decision section of
> `capability-study.md` (feature-001's single study doc; the separate `format-decision.md` was
> folded into it per the intent-review correction). The spec
> retains the TOML branch as the safe default (verify-first) and the build deletes it only on a
> `high`-confidence PASS — matching feature-001's "do not delete the TOML branch until the row is
> `high`" ordering gate.

> **Confirmed (2026-06-20) — A7:** if E-CODEX-1 lands PASS during this feature's build, delete the
> TOML branch in the same PR (cleanest); if it is still `docs`-only/`medium`, ship the dormant TOML
> branch and open a tracked follow-up to delete it once E-CODEX-1 is `high`. *(Recommended: yes —
> this keeps feature-002 shippable without blocking on a live Codex probe.)*

---

### Preserved Guarantees (NFR2, C4, C5) — how each survives the collapse

| Guarantee | Mechanism today | After collapse |
|-----------|-----------------|----------------|
| **Determinism (NFR2)** | `verify_deterministic` byte-identical re-render | Kept. A copy is *more* trivially deterministic than a render; the sub-check is unchanged, re-pointed at the copy pass. Sorted-walk ordering preserved. |
| **Prune manifest (C5)** | `EmissionManifest.diff` → `removed_dst` → unlink + prune empty parents | **Byte-for-byte unchanged** — the manifest schema, write, load, diff, and the deletion pass are lifted verbatim. `test_manifest_safety.py`'s two boundary tests still pass (user-file-untouched + canonical-removal-cascades). |
| **Render-drift CI (C4)** | `render-drift` job: regenerate + `git diff --exit-code profiles/` | **Unchanged in shape.** It runs `run_generator.py` (now the copy driver) and asserts no drift. The committed `profiles/*` trees are re-rendered once (the FR3/FR2 reshape) and committed; thereafter drift-free. |
| **File-presence audit** | `verify_deterministic` sub-check 2 (manifest ⇄ disk) | Kept; `_profile_output_dirs` loses the Codex split branch. |
| **Frontmatter parse** | sub-check 3 | Kept; markdown path only (+ TOML if the dormant branch is retained). |
| **Content isolation (C1)** | `aid/`-nest + `aid-` prefix + manifest membership | Kept — the `{root}/aid/` nest is now structural (copy of `canonical/aid/`), agents/skills keep `aid-` prefix; R6 Codex exception is the *intended* FR2 change. |
| **ASCII-only shipped scripts (C3)** | CI guard | Unaffected — the generator scripts stay ASCII; the new `render.py` must too. |

---

### The §7a / C2 Dogfood Byte-Identity Guard (NEW — this feature owns it)

**Problem (C2):** repo-root `.claude/` must stay byte-identical to `profiles/claude-code/.claude/`,
but `.claude/` is **hand-maintained, NOT written by `run_generator.py`** (coding-standards §7a:
the dogfood is the 7th physical copy, deliberately hand-editable). Today **nothing mechanically
asserts** repo `.claude/` == `profiles/claude-code/.claude/` — the closest existing guard,
`test-agents-md-invariant.sh`, only checks the four root `AGENTS.md` files are mutually identical,
not the dogfood tree.

**This feature adds the missing guard.** Proposed: a new bash suite
`tests/canonical/test-dogfood-byte-identity.sh` (T-prefixed assertions, sources `tests/lib/assert.sh`,
discovered by `tests/run-all.sh` glob → runs in the `canonical-tests` CI job, no workflow edit
needed). It asserts:

- every file under `profiles/claude-code/.claude/` has a byte-identical counterpart under repo-root
  `.claude/` (and vice-versa — no extra/missing files), via per-file `sha256sum` comparison;
- it excludes nothing in the AID-owned tree (the whole `{agents,skills,aid}` shape must match);
- it fails loudly naming the first divergent path.

> **Confirmed (2026-06-20) — A8 (guard mechanism):** add a **bash test suite under
> `tests/canonical/`** (auto-discovered by `run-all.sh`, runs in the existing `canonical-tests`
> job — zero workflow YAML churn, consistent with §7d per-test colocation and
> `test-agents-md-invariant.sh` precedent). Alternatives: a Python check inside
> `verify_deterministic` (couples dogfood-identity to the generator gate, but the dogfood is
> explicitly *not* a generator output, so this conflates concerns); or a dedicated `render-drift`-
> style workflow step. *(Recommended: the bash suite — it matches the existing FR12 invariant guard
> pattern exactly and keeps "is the hand-maintained dogfood in sync" separate from "does the
> generator drift".)*

> **Re-render obligation:** this feature re-renders the repo's own `.claude/` tree (drop the rules
> folder — note `.claude/` never had a rules output, so the dogfood change is the `canonical/aid/`
> reshape per A4 + any FR5 content edits) and commits it, then the new guard locks it. AC6's
> "mechanized §7a/C2 byte-identity guard" is satisfied by `test-dogfood-byte-identity.sh`.

---

### Migration Plan (output-tree reshape only — NOT install-time user migration)

This feature reshapes the **committed `profiles/*` rendered trees**:

- **Codex (FR2):** `profiles/codex/.agents/` is deleted; its `{skills, aid}` content moves under
  `profiles/codex/.codex/{skills, aid}`; agents stay at `.codex/agents/`. One unified root.
- **Cursor (FR3):** `profiles/cursor/.cursor/rules/` deleted.
- **Antigravity (FR3):** `profiles/antigravity/.agent/rules/` — the `aid-*.md` methodology/review
  rule outputs deleted. (The sub-agent personas that were reshaped *into* `.agent/rules/` via
  `antigravity-rule` now render as **markdown agents under `.agent/agents/`** — the uniform shape;
  this is the FR4-uniform-markdown change for antigravity.)
- **All tools:** the `canonical/rules/` source dir + `_render_cursor_extras` + `[extras]` are gone,
  so no rules output anywhere.

The **install-time migration of *user* repos** (moving an installed `.agents/`→`.codex/`, pruning
`.cursor/rules/` on `aid update` via the FR7/FR7a manifest-diff prune) is **feature-003** and is
**out of scope here**. This feature only guarantees the *new manifest* correctly omits the retired
paths (so feature-003's prune has the right target set) — which it does automatically, since the
retired paths simply stop being emitted and thus drop out of the per-version manifest.

---

### Telemetry & Tracking (light)

The render run's only "telemetry" is its gate output: `run_generator.py` prints emitted/deleted
counts + `VERIFY (deterministic): PASS/FAIL`; CI surfaces `render-drift`, the `generator-selftests`
job (now invoking `render.py --self-test`), the `canonical-tests` job (now including the new
dogfood-identity suite), and `verify_advisory` skip/check counts. Work state is tracked in the
work `STATE.md` per AID discipline (orchestrator owns the writes).

---

### Acceptance-Criteria Coverage

| AC | Where satisfied |
|----|-----------------|
| **AC1** — 5 tools render uniform `{agents,skills,aid}` under host root + root file + `.aid/`; same content present | Target Architecture + FR1 layout + the copy pass; root file via G1/install-lib |
| **AC2** — script count + LOC reduced; determinism + manifest + render-drift intact | Layers (13→4 inventory, ~7k→~1k LOC) + Preserved Guarantees table |
| **AC6** — §7a byte-identity, ASCII-only, content-isolation hold incl. the **mechanized §7a/C2 guard** | The §7a Guard section (new `test-dogfood-byte-identity.sh`) + Preserved Guarantees (C1/C3) |
| **FR2/FR3/FR5/FR6** | Codex Unify; Migration Plan (rules removal) + Layers (delete `_render_cursor_extras`/extras); FR5 section; Target Architecture |
| **NFR1/NFR2/NFR5** | Layers (NFR1 evidence); Preserved Guarantees (NFR2); shrunk config schema + hardcoded dirs (NFR5) |
| **C1/C4/C5** | Preserved Guarantees table |
| **Codex contingency (FR4/E-CODEX-1)** | Codex Unify — dormant TOML branch, feature-001 dependency |
