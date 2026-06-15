# Per-Repo Format Stamp and Fail-Safe Migration Gate

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-15 | Feature identified from REQUIREMENTS.md §5 (FR3), §4, §9 (AC3), §10 (Priority 2) | /aid-interview |
| 2026-06-15 | Technical Specification authored | /aid-specify |
| 2026-06-15 | Spec fixes (review cycle 1): corrected parsing-primitive reuse claims (replicate not reuse) | /aid-specify |

## Source

- REQUIREMENTS.md §5 (FR3 Per-repo format stamp)
- REQUIREMENTS.md §4 Scope (in-scope: per-repo format stamp with fail-safe comparison)
- REQUIREMENTS.md §9 (AC3)
- REQUIREMENTS.md §10 Priority 2 (the coherent model)
- Design note §3.4 (per-repo stamp, git model), §6 (per-repo stamp touch points)

## Description

A repo's migration state is a property of the repo, so it should live with the
repo — not with the CLI. This feature gives each repo a `format_version: <int>`
key in its own `.aid/settings.yml`, decoupled from the CLI's semantic version and
bumped only on a breaking `.aid/` layout change. The current layout is
`format_version: 1`; the CLI ships a `AID_SUPPORTED_FORMAT = 1` constant. A
legacy/unstamped repo is treated as format `0` (needs migration to `1`).

Comparison is fail-safe, following the git "repository format version" model: if a
repo's stamp is **greater** than the supported format the CLI refuses to operate
(the data is newer than this CLI understands — never risk corrupting it); if the
stamp is **less than** supported or absent, the repo needs migration and the CLI
warns and offers `aid update` rather than silently changing anything. This stamp
replaces the old era-by-file-presence detection and becomes the single
migration-done record (no machine marker), which is why the root-owned-marker
re-prompt bug cannot recur. A successful migration writes the new stamp. The
`extensions:` key is reserved but unused.

## User Stories

- As an **end user**, I want `aid` to refuse to operate on a repo whose format is
  newer than my CLI understands, so my repo data is never silently corrupted.
- As an **end user with a legacy/unstamped repo**, I want `aid` to warn me and
  offer to migrate (not change anything silently), so migration is always a
  visible, consented action.
- As an **AID maintainer**, I want each repo's migration-done state stored in its
  own user-writable `.aid/settings.yml`, so there is no machine-level marker that
  an unprivileged install can fail to write.

## Priority

Must (Priority 2 — the coherent model)

## Acceptance Criteria

- [ ] Given a repo whose `.aid/settings.yml` has `format_version` greater than
  `AID_SUPPORTED_FORMAT`, when any `aid` command runs there, then it refuses to
  operate with a clear fail-safe message (AC3).
- [ ] Given a repo with a `format_version` older than supported, or with no stamp
  at all, when `aid` runs there, then it triggers a migration **offer** (warn +
  offer `aid update`), never a silent change (AC3).
- [ ] Given a fresh `.aid/` layout, when written, then `.aid/settings.yml` records
  `format_version: 1`, and the CLI's `AID_SUPPORTED_FORMAT` constant is `1` (FR3).
- [ ] Given an unstamped (legacy) repo, when its format is evaluated, then it is
  treated as format `0` (needs migration to `1`) (FR3).
- [ ] Given a successful migration of a repo, when it completes, then the new
  `format_version` is written into that repo's `.aid/settings.yml` and that stamp
  is the only migration-done record (no machine marker) (FR3, AC7 reinforcement).
- [ ] Given the prior era-by-file-presence detection branch, when this feature
  lands, then it is replaced by stamp comparison (FR3).
- [ ] Given `bin/aid` and `bin/aid.ps1`, when the stamp logic changes, then they
  remain at parity and ASCII-only (AC8).

> **Cross-cutting NFRs (apply to all ACs):** bash/ps1 parity, ASCII-only shipped
> scripts (CI-enforced), no data loss / fail-safe (mandatory — never operate on a
> newer-format repo), backward compatibility (no hard failure on a missing stamp).
>
> **Dependencies:** independent of the registry; benefits from but does not
> require feature-001 (the stamp logic itself is repo-local). It is the lazy
> catch-all that feature-004's registry migration relies on for unregistered repos.

---

## Technical Specification

### Scope of this spec

This spec defines the **per-repo format stamp primitive and the fail-safe
migration gate** (FR3). Concretely it owns four code changes, in both
`bin/aid` (bash) and `bin/aid.ps1` (PowerShell):

1. The `AID_SUPPORTED_FORMAT` constant and its bash/ps1 parity home (Q3).
2. The `format_version` key in the `.aid/settings.yml` template that migration
   writes.
3. A read+compare helper (`_aid_repo_format` / `_aid_format_gate`) that
   classifies a repo's format against `AID_SUPPORTED_FORMAT`.
4. Wiring that gate into the repo-command entry points (bare `aid`, `status`,
   `update`, dashboard), **replacing** the version-sentinel call sites.

Out of this spec's boundary (owned by sibling features, referenced only):

- The **removal** of `_aid_check_migrate_sentinel`, `_aid_write_migrated_marker`,
  `_aid_scan_for_repos`, `$AID_HOME/.migrated` and the `$HOME` scan belongs to
  **feature-001** (FR8). This spec consumes that removal: where feature-001
  deletes the sentinel call site, this feature inserts the format gate. The two
  features touch the same call sites (bin/aid:1918, 1978) and must land together
  or sequence feature-001 first.
- The **bootstrap** that stamps `format_version: 1` into existing v1.0/v1.1
  repos on first touch is **feature-005** (FR9). This spec provides the *write
  primitive* (item 2) that feature-005 invokes; it does not own the bootstrap
  walk.
- The **registry** and `update self` batch migration are **feature-004** (FR4,
  FR6). This stamp is the lazy catch-all those features rely on for unregistered
  repos.

### Approach

**The stamp.** Each repo records a single integer key at the top of its own
`.aid/settings.yml`:

```yaml
format_version: 1
# extensions:        # reserved (git forward-compat model) — unused, do not emit
project:
  name: <repo>
  ...
```

`format_version` is a **top-level** (column-0) scalar key, deliberately placed
above the `project:` block so it parses with a simple `^format_version:`
first-match read (no section descent needed) and is visible at a glance. It is decoupled from CLI semver: it is bumped
only on a breaking `.aid/` layout change, not on every release. The current
layout is `format_version: 1`. The reserved `extensions:` key is **mentioned in
a comment only**; no code reads or writes it (REQUIREMENTS.md §4 out-of-scope).

**The supported-format constant (Q3).** Each language entrypoint defines the
constant **exactly once**, as a near-top readonly constant adjacent to the
`AID_HOME` resolution:

- `bin/aid`: `readonly AID_SUPPORTED_FORMAT=1` immediately after the
  `AID_HOME` resolution block (after bin/aid:47).
- `bin/aid.ps1`: `Set-Variable -Name AidSupportedFormat -Value 1 -Option Constant`
  (or `$script:AidSupportedFormat = 1`) immediately after the `$env:AID_HOME`
  resolution (near bin/aid.ps1:892).

There is **no third definition** anywhere (no lib/, no installer). A
canonical-suite parity assertion (see Testing) greps both entrypoints for the
literal value and fails if they differ — the constant has one parity home per
language and the two integers must always match.

**Parsing.** The stamp is read with a **small new top-level scalar reader**, not
a new YAML parser and not the existing era-a closure. There is **no existing
column-0 scalar reader to reuse**: the only YAML strip helper in the codebase is
`_get_scalar_value`, a **function-local closure defined inside
`_aid_migrate_repair_settings_era_a` (bin/aid:1416-1441)** and used only for
**section-nested indented keys** (its comment reads "scalar value of an indented
`  key: value` line"; all five call sites — bin/aid:1499/1535/1565/1582/1599 —
pass section-nested keys). It is not callable from the new top-level
`_aid_repo_format` helper. Because `format_version` is a column-0 (top-level)
key, the new helper greps the first `^format_version:` line and **replicates a
minimal version of that strip logic inline** — strip the `format_version:`
prefix, trim leading/trailing whitespace, strip an inline `# comment`,
quote-unwrap — yielding a raw string. (If a shared top-level reader is later
wanted, the era-a closure could be lifted to a top-level helper that both
call; this spec only requires the replicated inline strip in `_aid_repo_format`.)
The string is then validated as a non-negative integer (`^[0-9]+$`); anything
else (absent line, empty value, non-integer, negative) collapses to the
**legacy default of `0`** (see Edge cases). The ps1 twin replicates the same
strip logic from its `$getScalarValue` closure (defined at bin/aid.ps1:1426
inside `Invoke-AidRepairSettingsEraA`, not reused from there) plus
`-match '^\d+$'`.

**Comparison (fail-safe, git model).** Let `repo` be the parsed integer (0 when
absent/malformed) and `sup = AID_SUPPORTED_FORMAT`:

| Relation | Class | CLI behavior |
|----------|-------|--------------|
| `repo > sup` | **newer** | **Refuse to operate** — clear fail-safe message; non-zero exit. Never read/write `.aid/`. |
| `repo < sup` or absent/malformed | **needs-migration** | Warn + offer `aid update` (this repo). **Still operate** the requested command — the offer is non-blocking. |
| `repo == sup` | **current** | Operate normally; no message. |

### Format-state model

The repo's format is a 3-valued classification derived from a single integer
comparison; there is no other state and no machine-side record:

- **current (`repo == sup`)** — steady state, silent.
- **needs-migration (`repo < sup`, including the legacy `0`)** — the CLI prints
  a one-line warning and offers `aid update`, then proceeds with the requested
  read/operation. Migration is never silent and never automatic on a plain repo
  command; it is a visible, consented action (the offer). A *successful*
  migration (feature-005 / feature-004 path, invoking the write primitive here)
  writes `format_version: <sup>` into that repo's `.aid/settings.yml`, after
  which the repo is **current**. That stamp is the **only** migration-done
  record (no machine marker — FR8).
- **newer (`repo > sup`)** — the CLI refuses to operate on the repo at all
  (git's "must not operate / risks losing data" rule). The message names the
  repo's format and the CLI's supported format and directs the user to upgrade
  the CLI. No `.aid/` mutation occurs.

The `extensions:` key is **reserved** for a future partial-compatibility
mechanism (git's `extensions.*` model) and is **not implemented** here: a repo
with an unknown `extensions:` entry is treated exactly as its `format_version`
dictates today. (Mentioned per design note §3.4; building it is out of scope per
REQUIREMENTS.md §4.)

### Affected components

| # | Component | Location (verified) | Change |
|---|-----------|---------------------|--------|
| C1 | `AID_SUPPORTED_FORMAT` constant (bash) | `bin/aid:44-47` (after `AID_HOME` block) | Add `readonly AID_SUPPORTED_FORMAT=1`. |
| C1' | `$AidSupportedFormat` constant (ps1) | `bin/aid.ps1:~892` (after `$env:AID_HOME`) | Add the parity constant `= 1`. |
| C2 | Era-b settings synthesizer (bash) | `_aid_migrate_synthesize_settings_era_b`, `bin/aid:1629-1670` | Emit `format_version: <sup>\n` as the **first** printed line (before `project:`). |
| C2' | Era-b settings synthesizer (ps1) | `bin/aid.ps1:1563-1596` region | Same: prepend `format_version: <sup>` line. |
| C3 | Era-a settings repair (bash) | `_aid_migrate_repair_settings_era_a`, called at `bin/aid:1318` | Add a `format_version` ensure-key step. If a `^format_version:` line exists, IDIOM-A single-line replace (`_replace_line`, bin/aid:1474). If absent, a **new top-of-file column-0 insert** (prepend `format_version: <sup>` at index 0 of `_lines`, above `project:`) — this is NEW logic: the existing `_append_block` (IDIOM-B, bin/aid:1458) is an **EOF append** and `_insert_after` inserts *indented* lines after a section header, so neither places a column-0 key at the top of file. |
| C3' | Era-a settings repair (ps1) | ps1 twin of C3 (the `minimum_grade`/`heartbeat_interval` ensure pattern, bin/aid.ps1:1507-1544) | Same ensure-key step. |
| C4 | **NEW** `_aid_repo_format <repo>` (bash) | new helper near the migrate helpers (~bin/aid:1276) | Read+validate the stamp; echo the integer (0 on absent/malformed). |
| C4' | **NEW** `_aid_repo_format` (ps1) | ps1 twin | Same. |
| C5 | **NEW** `_aid_format_gate <repo>` (bash) | new helper, calls C4 | Classify current/needs-migration/newer; emit warn-offer or refuse; return a status (0 = proceed, non-zero = refuse). |
| C5' | **NEW** `_aid_format_gate` (ps1) | ps1 twin | Same. |
| C6 | Repo-command gate wiring (bash) | replaces `_aid_check_migrate_sentinel` calls at `bin/aid:1918` (`_cmd_dashboard`) and `bin/aid:1978` (`status`); add to bare-`aid` (`_cmd_dashboard` covers it via 1924) and the `update` repo path | Call `_aid_format_gate "$target"`; on refuse, exit non-zero before operating. |
| C6' | Repo-command gate wiring (ps1) | ps1 twin of the dashboard/status/update dispatch | Same. |

> Note on line drift: the binding-contract line refs (era detection
> "1417-1427", template "1764-1787") are stale against the current `bin/aid`.
> The **verified** current locations are: era detection by file-presence lives
> in `_aid_migrate_repo` STEP 0 (bin/aid:1295-1305), `_aid_scan_for_repos`
> (bin/aid:1715-1720) and `_aid_check_repo_compliant` (bin/aid:1738-1740); the
> settings template lives in the era-a repair + era-b synthesizer
> (bin/aid:1318, 1629-1670). The gate call sites are the sentinel call sites
> (bin/aid:1918, 1978). This spec cites the verified locations.

### Behavior / Flow (per-command)

This stamp gate is **the sole migration trigger** (Q2). With the machine
sentinel and `$HOME` scan removed (feature-001), there is intentionally **no
machine-level first-run trigger**; the gate fires on every repo command,
deriving everything from the cwd repo's own stamp.

Per repo command (`aid` bare, `status`, `update <this repo>`, `dashboard`):

1. **Resolve repo** — the command resolves its target repo root as it does today
   (`aid_status_body`/`aid_status` use `cd "$target" && pwd`, lib:1306/1333;
   bare `aid`/`dashboard` use `.`). If there is no `.aid/` at the target, this is
   **not** a format question — fall through to the existing "no AID project
   here — set it up? (`aid add`)" path (design §4 row C-last). The gate only runs
   when `.aid/` exists.
2. **Read stamp** — `_aid_repo_format "$repo"` reads `<repo>/.aid/settings.yml`,
   greps the first `^format_version:` line, strips/validates → integer (0 if the
   file or key is absent or the value is malformed).
3. **Branch** (`_aid_format_gate`):
   - `repo > sup` → print the refuse message to stderr, return non-zero; the
     caller **exits** without operating.
   - `repo < sup` (incl. 0) → print the warn+offer line (stdout, non-blocking),
     return 0; the command **continues** and operates.
   - `repo == sup` → silent, return 0; operate.
4. **Operate** — the command runs its normal body.

The gate replaces the `_aid_check_migrate_sentinel` calls that previously sat at
the tail of `_cmd_dashboard` (bin/aid:1918) and the `status` path
(bin/aid:1978); unlike the old sentinel it runs **before** operating (so a
newer-format repo is refused up front) rather than as a trailing notice.

### Edge cases & fail-safes

- **Absent `settings.yml`, era-b knowledge dir present.** A legacy repo with
  only `.aid/knowledge/{DISCOVERY_STATE.md|DISCOVERY-STATE.md|STATE.md}` and no
  `settings.yml` → `format_version` is absent → treated as **0** → needs-migration
  → warn+offer, operate. The era-b synthesizer (C2) writes the stamp when that
  repo is migrated.
- **`settings.yml` present, no `format_version` key.** Existing v1.1 era-a repo
  → absent key → **0** → needs-migration. (Backward compatibility section.)
- **Malformed / non-integer value** (`format_version: x`, `format_version: 1.2`,
  empty, negative, quoted-non-numeric). The `^[0-9]+$` validation fails →
  collapse to **0** (needs-migration), **never** to "newer". A garbled stamp must
  err toward migrate, not toward refuse-or-corrupt. (Rationale: a non-integer can
  never be proven `> sup`, so it can never silently trip the refuse path.)
- **Duplicate `format_version:` lines.** Read the **first** match only (parity
  with the existing first-match reader idiom); migration's ensure-key step
  normalizes to a single line.
- **Never silently rewrite a newer-format repo.** The refuse path performs **no**
  `.aid/` write of any kind (no stamp, no settings repair, no dashboard provision).
- **Migration write atomicity.** The stamp write rides the existing crash-safe
  `mktemp` + `mv -f` idiom of the synthesizer/repair (`mktemp` bin/aid:1639,
  `mv -f` bin/aid:1668); the
  stamp is never written by a partial file.
- **Opt-out.** `AID_NO_MIGRATE=1` (existing env, bin/aid:260) suppresses the
  warn+offer notice (needs-migration stays operable, just quiet). It does **not**
  suppress the **refuse** path — fail-safe is non-negotiable and cannot be
  opted out.

### bash ↔ ps1 parity

- The read+validate+compare logic is **identical** in shape: same first-match
  `^format_version:` grep, the same replicated scalar-strip steps in each
  language (modeled on each entrypoint's era-a closure but defined fresh in the
  new top-level helper, not reused from the closure), same
  `^\d+$`/`^[0-9]+$` validation, same three-way comparison and the same three
  messages (refuse / warn-offer / silent).
- **`AID_SUPPORTED_FORMAT` parity home (Q3):** defined once per entrypoint
  (bin/aid:~47, bin/aid.ps1:~892). A canonical-suite assertion extracts the
  integer from each entrypoint and asserts equality; drift fails CI.
- **ASCII-only** (NFR): all new strings, messages, and comments are ASCII; no
  non-ASCII glyphs in the refuse/offer text (CI-enforced by `test-ascii-only.sh`).
- Windows has no `sudo`; the gate is read-only classification + a non-blocking
  notice, so no elevation difference applies — the parity is exact.

### Testing (canonical assertions)

Extend the canonical suite (HOME-pinned per the migration-safety rule):

1. **Constant parity (Q3).** Assert the integer extracted from `bin/aid`'s
   `AID_SUPPORTED_FORMAT` equals the one in `bin/aid.ps1`'s constant, and both
   equal `1`. (New assertion in `test-aid-cli-parity.sh`.)
2. **Stamp written on migrate.** After `aid __migrate-repo` (or the era-b
   synthesizer) runs on a fixture repo, `.aid/settings.yml` contains
   `format_version: 1` as a top-level key. Both era-a (repair) and era-b
   (synthesize) fixtures. (Extend `test-aid-migrate.sh` / `test-aid-cli-parity.sh`.)
3. **format_version=1 round-trips.** A repo stamped `1` with `AID_SUPPORTED_FORMAT=1`
   → gate is silent, command operates, no rewrite of the stamp.
4. **Refuse-on-newer.** A fixture with `format_version: 2` (sup=1) → bare `aid`
   / `status` exits non-zero with the refuse message and performs **no** write
   to `.aid/` (assert mtime/byte-identity of settings.yml unchanged).
5. **Offer-on-older / absent.** A fixture with `format_version: 0` and one with
   no key → gate prints the warn+offer line and the command still operates
   (exit 0). era-b-only (no settings.yml) fixture → treated as 0, operates.
6. **Malformed value.** `format_version: abc` / `1.5` / empty → classified as 0
   (needs-migration), never as newer; command operates. Guards the
   refuse-vs-migrate direction.
7. **bash/ps1 behavioral parity.** The refuse/offer/silent outcomes match
   across `bin/aid` and `bin/aid.ps1` for the same fixtures
   (`test-aid-cli-ps1.sh` / `test-aid-cli-parity.sh`).

### Backward compatibility

- **Existing v1.1 repos** (era-a `settings.yml`, no `format_version` key) →
  parsed as **0** → needs-migration → warn+offer, **still operable**. No hard
  failure on a missing stamp (NFR). On the next `aid update` of that repo the
  era-a repair step (C3) inserts `format_version: 1`, after which it is current.
- **Era-b legacy repos** (knowledge `*STATE.md`, no settings) → 0 →
  needs-migration; the synthesizer (C2) writes the stamp on migration.
- **No machine marker dependency.** Removing `$AID_HOME/.migrated`
  (feature-001) does not strand any repo: the done-state is each repo's own
  stamp, so the root-owned-marker re-prompt bug cannot recur (design §3.4).
- The new top-level `format_version:` line is additive YAML; existing readers
  that key on `project:`/`tools:`/`review:` sections are unaffected (it sits
  above them at column 0).
