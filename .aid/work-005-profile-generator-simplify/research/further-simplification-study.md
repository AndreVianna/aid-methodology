---
title: Further-simplification study (post-completion)
work: work-005-profile-generator-simplify
status: analysis only — FUTURE WORK, not part of the shipped deliveries
date: 2026-06-21
sources:
  - .claude/skills/generate-profile/scripts/{render.py,render_lib.py,aid_profile.py}
  - lib/aid-install-core.sh, lib/AidInstallCore.psm1
  - .aid/work-005-profile-generator-simplify/research/capability-study.md
  - .aid/knowledge/{host-tool-capabilities,content-isolation}.md
  - docs/install.md, install.sh
---

# Further-simplification study — can work-005 be simplified more, and where does that become over-simplification?

**Scope:** read-only design analysis of the *shipped* system (deliveries 001/002/003).
Recommendations here are FUTURE WORK — none were applied to the shipping deliveries.

## Context

work-005 replaced an over-engineered generator (~13 Python files, per-format emitters,
asymmetric layouts) with a copy-based generator (~7 files) on a uniform
`{agents,skills,aid}` layout across 5 host tools, plus a complete-replacement migration.
The simplification is **real but partial**: the genuine core-logic reduction is
~1,100–1,400 LOC; the work *added* complexity in the install/migration layer
(bash + PowerShell twins, a destructive migration, a `Set-StrictMode` tax). Two
residual generator complexities survive by design: the **Codex TOML branch** and the
**`aid/`-nest layout dispatch**.

> ## ⚠️ Correction applied (2026-06-21) — the python3 premise was wrong
>
> An earlier draft of this study ranked "de-duplicate the install-core manifest
> parsers" as the **highest-value win**, on the assumption that machines without
> `python3` are *rare* and the pure-shell JSON parser is a redundant fallback.
> **That assumption is false** — the evidence shows the opposite, and the win largely
> collapses (see [W1](#w1)). The corrected top win is the `Set-StrictMode` downgrade
> ([W2](#w2)). This correction is recorded here rather than silently edited away.

---

## Part A — Install-layer simplification candidates

The generator is already at (or slightly past) the right simplicity point — every
surviving piece is load-bearing per the capability study. The only place real
remaining complexity lives is the install/migration layer.

### W1 — De-duplicate the manifest JSON parsers — ❌ MOSTLY OFF THE TABLE {#w1}

**The idea:** each install core appears to ship two JSON manifest parsers — a `python3`
fast-path and a hand-rolled pure-shell parser (~600 LOC each) — so make `python3` a
prerequisite and delete the pure-shell copies (~1,200 LOC).

**Why it does NOT hold up (evidence):**
- The pure-shell parser is the **deliberate no-dependency baseline**, not a rare
  fallback: `aid-install-core.sh:557` — `# Manifest - pure-Bash reader (no jq/python
  required)`; `:715` — python3 is the *"fast-path"*.
- `python3` is required by **only the PyPI channel** (`docs/install.md:105`, under
  `### PyPI channel` — pipx is itself a Python tool). The **`curl|bash` and `npm`
  channels do not require Python**; all 8 python3 uses in bash are guarded
  (`command -v python3 … || <pure-bash>`).
- **On Windows there is no python3 path at all** — the PowerShell twin has **0** python3
  code uses (`grep` = 0). The hand-rolled PowerShell parser is the *sole* implementation
  for every Windows install; there is nothing to de-duplicate against.

**Conclusion:** the ~1,200 lines are *conceptually* duplicated (two languages parse JSON)
but not *redundantly* duplicated — neither copy can be deleted without losing a
capability (dependency-free `curl|bash`/`npm` install) or a whole platform (Windows).
This is an **over-simplification boundary**, not a win.

| Pros (best case) | Cons |
|---|---|
| Deleting *only* the bash pure-shell parser would remove ~600 LOC of dense code | Forces `python3` as a hard prereq for the two deliberately dependency-free channels — a real regression on minimal/fresh boxes (Alpine/distroless, macOS w/o Xcode CLT, fresh Windows) |
| | Does **nothing** for the PowerShell twin (no python3 there to take over) |
| | Net: a capability trade, not a free simplification |

**Verdict: do not pursue as a simplification.** At most a deliberate capability decision
(drop dependency-free bash installs) — and even then only half the LOC, none on Windows.

### W2 — `Set-StrictMode -Version Latest` → `-Version 3` — ✅ THE CLEAR TOP WIN {#w2}

**The idea:** the PowerShell install core runs `Set-StrictMode -Version Latest` (4
directives), the strictest mode, which throws on access to any absent property. AID reads
heterogeneous-shape JSON manifests (old vs new format) where properties are *legitimately*
sometimes absent, so every such read needs a `PSObject.Properties['key']` guard — **42**
such idioms. Worse, `Latest` *caused* 3 of the delivery-002 Windows bugs (absent-property
throw; `[Array]::Sort($null)` on an empty collection) while catching nothing of value.
Downgrade to `-Version 3`, which keeps the genuinely useful checks (undefined variables /
bad references) but drops the aggressive absent-property throwing.

| Pros | Cons |
|---|---|
| Removes the 42-site guard tax and the exact failure mode behind 3 shipped Windows bugs | Slightly less strict — gives up missing-property detection (which was net-negative here) |
| Keeps the real safety (undefined-variable protection) | Must re-run the **Windows-only** installer suite (not in run-all) — same surface those bugs hit |
| Low risk, no capability loss | — |

**Verdict: do it.** `Latest` created more bugs than it prevented and imposed a real tax;
`-Version 3` (or scoping `Latest` to a few hot functions) is a clean win. Re-verify on a
Windows runner.

### W3 — Reversible migration (`rm -f` → move-to-`.aid/.trash/`) — ✅ CHEAP HARDENING {#w3}

**The idea:** the migration *deletes* retired AID files (`rm -f`). The deletion is already
*safe* (marker-scoped: only files AID owns, never user content) but **irreversible**. Move
them to `.aid/.trash/` instead — same end state, recoverable.

| Pros | Cons |
|---|---|
| Turns a destructive op into an undoable one (~5 LOC per twin) | Leaves a `.aid/.trash/` to eventually clean up |
| Cheap insurance against a future edge case | Marginal value today (the sweep is already correctly scoped) — hardening, not simplification |

**Verdict: optional / nice-to-have.** Lowest priority; de-risks rather than simplifies.

---

## Part B — Over-simplification traps (do NOT do)

- **Single-source `AGENTS.md` + OS symlinks** (the model deferred in REQUIREMENTS §4):
  **not a simplification — a capability trade.** A symlink serves identical bytes to every
  tool, but the generator's surviving work is exactly the *per-tool divergence* a symlink
  cannot do — `tools:` remap (`Bash`→`Terminal`/`shell`) and `model:` resolution
  (`opus`→`gpt-5.x`/`gemini`/`claude-literal`), both marked **`translate, high`** (proven
  load-bearing) in the capability study. It would also *add* a privileged Windows symlink
  code path and break byte-identity + render-drift verification. The §4 deferral was
  correct.
- **Deleting the Codex TOML branch** (uniform markdown for all 5): highest-risk /
  lowest-reward — ~50 lines of *dormant, zero-cost, guarded* code traded for the risk of
  **silently-broken Codex agents that CI structurally cannot catch** (no codex CLI on any
  host; the `E-CODEX-1` probe was never run). Keep it dormant; gate deletion on actually
  running the probe.

---

## Part C — The irreducible core (the boundary)

Four things must stay or capability/safety is lost:
1. **Per-tool translations** (`_remap_tools`, `_resolve_model`) — remove → broken tool
   invocation + wrong model selection on 4 of 5 tools.
2. **The `aid/`-nest layout dispatch** (`render_lib.py:204-219`) — remove → lose the
   content-isolation prune invariant (can't tell AID files from user files), or force a
   canonical-content rewrite (strictly worse).
3. **Migration ownership markers + manifest-seam guard** — remove → delete user data.
4. **The bash + PowerShell twins** — drop one → lose POSIX or Windows. (Distinct from W1:
   the *twinning* is irreducible; the within-twin parser code is also load-bearing per W1.)

---

## Verdict & corrected ranking

| Rank | Candidate | Value | Risk | Verdict |
|---|---|---|---|---|
| 1 | **W2** — `Set-StrictMode Latest → 3` | Medium (−42 guards, kills a bug class) | Low (re-test Windows) | **Do it** |
| 2 | **W3** — reversible migration | Low (safety) | Very low | Optional hardening |
| 3 | **W1** — drop pure-shell manifest parser | ~0 / negative | Medium–High (loses dependency-free + does nothing for Windows) | **Do not** — capability trade, not a win |
| — | Symlinks; delete Codex TOML branch | Negative | Very high | Over-simplification traps — avoid |

**Bottom line.** work-005 landed near the right point on the generator and did **not**
over-simplify anywhere (it correctly *kept* the Codex branch and the layout dispatch,
dormant/documented). The install layer carries genuine complexity, but most of it —
including the ~1,200 lines of "duplicated" JSON parsing — is **irreducible**: it is the
price of AID's dependency-free, two-platform install promise. The one clean remaining win
is **W2 (the StrictMode downgrade)**; W3 is cheap hardening; W1 and the symlink/Codex cuts
would cross into capability or safety loss. The corrected posture: **downgrade StrictMode,
optionally make the migration reversible, and otherwise leave the system at rest.**
