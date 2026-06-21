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

> ## ⚠️ Corrections applied (2026-06-21) — TWO of the three drafted wins collapsed on verification
>
> An earlier draft ranked **W1** (de-duplicate the manifest parsers) the highest-value win
> and **W2** (`Set-StrictMode Latest → 3`) the clear top win. **Both premises proved false
> on verification** and are recorded here, not silently edited away:
> - **W1** assumed no-`python3` machines are *rare* and the pure-shell parser is redundant.
>   The opposite is true — it is the deliberate no-dependency baseline, and the Windows twin
>   has *no* python3 path at all. The "win" is a capability trade, not a simplification.
> - **W2** assumed `-Version 3` is "less aggressive about property access." Empirically
>   (`pwsh` on this box) `Latest ≡ 3.0` (so the change is a **no-op**), and only `-Version 1.0`
>   avoids the throw — at the cost of real protection. Drop it.
>
> **Net result: only W3 (reversible migration) survives — and it is the marginal "optional
> hardening" item, not a real simplification.** The honest finding is that work-005's
> install layer has **essentially no free simplification left**; its complexity is largely
> irreducible (the price of a dependency-free, two-platform install). See [W1](#w1)/[W2](#w2).

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

### W2 — `Set-StrictMode -Version Latest` → `-Version 3` — ❌ DROP (premise false on verification) {#w2}

> **⚠️ Correction applied (2026-06-21).** An earlier draft ranked this the *clear top
> win* ("downgrade to `-Version 3` drops the aggressive absent-property throwing"). That is
> **wrong** — verified empirically on the repo's pwsh. Recorded, not silently edited.

**The idea (as drafted):** the PowerShell install core runs `Set-StrictMode -Version Latest`
(4 directives); AID reads heterogeneous JSON manifests where properties are legitimately
absent, forcing **42** `PSObject.Properties['key']` guard idioms. The draft claimed
downgrading to `-Version 3` would stop the absent-property throwing and let the guards go.

**Why it does NOT hold up (empirical, `pwsh` on this box):**
- `-Version Latest` **currently resolves to `3.0`** — so `Latest → 3` is a **no-op** (both
  THREW `PropertyNotFoundException` on absent-property access in the test).
- Absent-property throwing was introduced in **`2.0`**, so `2.0` and `3.0` both throw; only
  **`-Version 1.0`** returns `$null` instead of throwing.
- The empty-array→`$null` failure (delivery-002 bug #3, `[Array]::Sort($null)`) is
  **StrictMode-*independent*** — `$null` under both `1.0` and `Latest` — so its `Count -gt 0`
  guard must stay regardless of version. (Only bug #1, absent-property, was version-related;
  bug #2 `return if` was a parser issue.)

**So the realizable change is `Latest → 1.0`, and that is a net-negative trade:** to delete
~42 absent-property guards you give up StrictMode's genuine protection across a ~2,000-line
install core — non-existent-property typos (2.0), out-of-bounds array indexes (3.0),
method-call-syntax mistakes, uninitialized variables. The guards are not a "tax"; under any
StrictMode ≥ 2.0 they are the **correct** way to read heterogeneous JSON.

| Pros (of `Latest → 1.0`) | Cons |
|---|---|
| Could remove ~42 absent-property guard idioms | Loses property-typo + array-bounds + method-syntax detection across the whole install core |
| | The empty-array guards must stay anyway (StrictMode-independent) |
| | `Latest → 3` (as drafted) is a pure no-op — zero benefit |

**Verdict: DROP.** Keep `Set-StrictMode -Version Latest` and the guards — they are correct
defensive code earning their keep, not removable tax. This is the second drafted "win"
(after W1) to collapse under verification.

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
| 1 | **W3** — reversible migration (`rm`→`.aid/.trash/`) | Low (safety/recoverability) | Very low | Optional hardening — the only survivor; being implemented |
| ✗ | **W2** — `Set-StrictMode Latest → 3` | None (`Latest ≡ 3`, no-op); `→ 1.0` is net-negative | — | **Dropped** — premise false on verification |
| ✗ | **W1** — drop pure-shell manifest parser | ~0 / negative | Medium–High (loses dependency-free; nothing for Windows) | **Dropped** — capability trade, not a win |
| — | Symlinks; delete Codex TOML branch | Negative | Very high | Over-simplification traps — avoid |

**Bottom line (post-verification).** work-005 landed near the right point on the generator
and did **not** over-simplify anywhere (it correctly *kept* the Codex branch and the layout
dispatch, dormant/documented). Crucially, on closer inspection the install layer has
**essentially no free simplification left**: the ~1,200 lines of "duplicated" JSON parsing
are irreducible (the price of a dependency-free, two-platform install — W1), and the
`Set-StrictMode` guards are correct defensive code, not removable tax (W2 is a no-op as
drafted and a net-negative trade as `→1.0`). Of the three drafted "wins," **two collapsed
under verification and only W3 (reversible migration) survives — and it is hardening, not
simplification.** The corrected posture: **make the migration reversible (W3) and otherwise
leave the system at rest — it is already close to its irreducible minimum.** The broader
lesson: file-count/LOC "simplification" candidates must be verified against what the code
actually requires (dependency-free installs; heterogeneous-JSON safety) before they are
called wins.
