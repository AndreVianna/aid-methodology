# Local Auth Registration

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5 (FR-3) + §9 (AC-3, AC-8); see Source for other §refs | /aid-define |
| 2026-07-08 | Technical Specification authored (Security Specs, Layers & Components, Feature Flow, Data Model); binds to feature-001's FROZEN keystone contract (the git-ignored `.aid/connectors/.secrets/<connector>` file store; the `file:`/`env:`/`keychain:` reference forms; the committed connectors-local `.aid/connectors/.gitignore`; the descriptor `secret_reference` field) and realizes its WRITE side — the no-echo/no-persist capture, cross-platform store write, and leak-proofing (FR-3, AC-3, AC-8) | /aid-specify |
| 2026-07-08 | FIX pass (A+ gate C+, 1 MEDIUM + Q7 coherence): resolved the 003↔006 purge-ownership drift per STATE.md Q7 item 2 — feature-003 OWNS the single secret-store twin (`connector-secret.{sh,ps1}`) exposing BOTH `write` and `purge`; feature-006 CALLS `purge` on REMOVE and defines no purge twin. Added the auth-downgrade orphan lifecycle (Q7 item 7): a surviving connector whose `auth_method` drops to `none` (or whose reference leaves the `file:` store) has its orphaned value disposed by feature-003 via the idempotent `purge` op | /aid-specify |
| 2026-07-08 | FIX pass (re-gate, 1 MEDIUM): added the path-confinement guarantee to the `connector-secret` op contract for BOTH `write` and `purge` — the connector key is a filename stem only, the target resolves strictly under `.aid/connectors/.secrets/`, and any stem containing a path separator (`/` or `\`) or `..` is rejected (non-zero exit + stderr) before any read/write/delete; backs the confinement guard feature-006 relies on (feature-006 SPEC.md:270-271) | /aid-specify |

## Source

- REQUIREMENTS.md §5 FR-3 (Local auth registration), §6 (Security & secret hygiene; cross-platform & footprint), §7 (Constraints — reference-not-value is mandatory)
- REQUIREMENTS.md §9 Acceptance Criteria: AC-3, AC-8 (cross-cutting)

## Description

When a declared tool requires authentication, this feature captures the secret and keeps it out
of the repository entirely. The developer is prompted for the secret, and the value is stored in
a local, git-ignored, OS-appropriate location. Only a reference to that secret — an env-var
name, an OS-keychain key, or a path to a git-ignored local file — is recorded in the committed
registry.

Secret hygiene is the point of this feature. The entered secret is never echoed back and is
never persisted into transcripts, STATE files, or the Knowledge Base. The committed artifacts
convey how to connect and where to find the credential, not the credential itself, so the
reference-not-value split can be proven by searching the repo and finding nothing.

Absolute rule: under no circumstance does the Knowledge Base or the committed registry expose
any secret — neither the secrets this feature registers nor any secret encountered while
eliciting or scanning the project. Committed artifacts carry only references; secret values live
only in the local git-ignored store.

Scope boundary: cleaning up or remediating pre-existing secrets that are already committed in the
project's own source or codebase is out of scope for this feature. Such findings are the
discovery phase's concern — flagged as tech-debt or risk — and are not remediated here. This
feature governs only the secrets it registers, not the project's prior hygiene.

The local secret store and its handling must work across Windows, macOS, and Linux, and must
stay within AID's existing shell/Python/Node toolchain — no new heavy runtime dependency is
introduced. The store location and reference formats follow the conventions defined by the
integration-store-placement feature.

## User Stories

- As a developer/adopter, I want to enter a tool's secret once and have it stored locally so
  that my credentials are available to agents without ever being committed to the repo.
- As a developer/adopter, I want only a reference (not the value) recorded in the committed
  registry so that sharing the repo never leaks a secret.
- As a developer/adopter on any of Windows, macOS, or Linux, I want auth registration to behave
  consistently so that secret handling is not platform-specific.

## Priority

Must

## Acceptance Criteria

- [ ] Given a declared tool requires auth, when the developer enters the secret, then it is stored in a local, git-ignored / OS-appropriate location and only a reference is recorded in the committed registry. (FR-3)
- [ ] Given a secret this feature has registered, when the repo, KB, STATE, and transcript are grepped for that registered secret value, then nothing is found and the value exists only in the local git-ignored store (reference-not-value proven for our registered secret; this is not a repo-wide scan for pre-existing committed secrets). (AC-3)
- [ ] Given the local secret store, when auth registration runs on Windows, macOS, and Linux, then it works on all three and introduces no new heavy runtime dependency. (AC-8)

---

## Technical Specification

> Authored by `/aid-specify`. feature-003 **realizes the WRITE side** of feature-001's FROZEN
> keystone contract; it defines NO new store, schema, or reference form. The local secret store
> (`.aid/connectors/.secrets/<connector>`), the committed connectors-local
> `.aid/connectors/.gitignore`, the three `secret_reference` forms (`env:` / `keychain:` /
> `file:`), the descriptor `secret_reference` field, and the P7-exempt `.aid/connectors/` write
> allowlist are all fixed by
> `.aid/work-002-external_sources/features/feature-001-integration-store-placement/SPEC.md`
> (`## Technical Specification`) and are BOUND here, not redefined. This spec adds the one thing
> feature-001 delegated to this feature: the no-echo / no-persist capture-and-write mechanism and
> its leak-proofing (FR-3, AC-3, AC-8).

### Security Specs

Secret hygiene is the point of this feature, so security is specified first and everything else
serves it.

- **No-echo capture (never echoed).** The entered secret is read from an interactive prompt with
  terminal echo **off** — Bash `read -rs`; PowerShell (WinPS 5.1) `Read-Host -AsSecureString`.
  The value never touches the console. `ConvertFrom-SecureString -AsPlainText` is pwsh-7-only and
  is BANNED under the shipped-PowerShell 5.1 / ASCII-only rule
  (`.aid/knowledge/coding-standards.md` §PowerShell Conventions), so the plaintext is materialized
  only in-process via `[Runtime.InteropServices.Marshal]::SecureStringToBSTR` /
  `PtrToStringBSTR`, and the BSTR is zeroed with `ZeroFreeBSTR` immediately after the write.
- **No-persist (never persisted).** The value is written straight to the file store and to
  nowhere else — never to the session transcript, any `STATE.md`, `.aid/knowledge/` (the KB), or
  any committed artifact (REQUIREMENTS §6). Concrete guards: no `set -x` tracing around the read
  (Bash); the secret is **never passed as a process argument** (so it never appears in `ps` /
  shell command history); the in-memory variable is cleared the instant the write returns
  (`unset` in Bash; `Remove-Variable` + BSTR zeroing in PowerShell). Even if a PowerShell
  transcript (`Start-Transcript`) is active, `Read-Host -AsSecureString` does not echo the value,
  so no plaintext is captured.
- **Reference-not-value (feature-001, mandatory).** Only the descriptor's `secret_reference` — a
  `file:` / `env:` / `keychain:` reference (feature-001 §Data Model) — is ever committed. The
  value exists only under the git-ignored `.aid/connectors/.secrets/`.
- **Absolute committed-no-secrets rule (STATE.md Q5c).** Under **no circumstance** does any
  committed artifact — a `.aid/connectors/<connector>.md` descriptor, `.aid/connectors/INDEX.md`,
  or any `.aid/knowledge/` doc — hold a secret **value**, whether one this feature registers or
  one encountered during elicitation/scanning. This is inviolable regardless of which agent or
  code path performs the write.
- **Scope boundary (STATE.md Q5b; REQUIREMENTS §4 Out of Scope).** Pre-existing secrets already
  committed in the project's own source/codebase are **OUT OF SCOPE** for this feature.
  feature-003 governs only the secrets it registers; it performs no repo-wide secret scan and no
  git-history rewrite. Such pre-existing findings are the discovery phase's concern — **surfaced**
  as tech-debt / risk, **not remediated** here.
- **Leak-proof (AC-3).** Acceptance test: after this feature registers a secret, grepping
  **repo + `.aid/knowledge/` (KB) + every `STATE.md` + the session transcript** for the exact
  value returns **nothing**; the value is present only at `.aid/connectors/.secrets/<connector>`.
  Per AC-3's wording (REQUIREMENTS §9), this proves reference-not-value for **our registered**
  secret — it is NOT a repo-wide sweep for pre-existing committed secrets.
- **Fail-closed on the ignore precondition.** Before the FIRST byte of any secret is written, the
  writer asserts the committed `.aid/connectors/.gitignore` exists and ignores `.secrets/`.
  feature-001 guarantees the P7-exempt discover state writes that file as its first action; this
  is defense-in-depth in case that ordering ever regresses. If the assertion fails, the writer
  **refuses to write** and exits non-zero — a missing ignore must never produce a trackable
  secret file.

### Layers & Components

The secret-store mechanism is a dedicated **Bash + PowerShell twin** (`write` + `purge`), invoked
by the P7-exempt discover state (the connector sub-phase introduced by feature-002, per STATE.md
Q6). It writes and purges **only** within feature-001's declared P7 allowlist entry
`.aid/connectors/` — specifically `.aid/connectors/.secrets/<connector>` — so no P7 change beyond
feature-001's carve-out is needed here (feature-001 §Layers & Components, "P7 read-only
carve-out").

**Secret-store twin (feature-003-owned, net-new).** feature-003 **owns** the one secret-store
twin; it is the single home for all `.aid/connectors/.secrets/` I/O.

- **Home:** `canonical/aid/scripts/connectors/` — a net-new sibling of
  `canonical/aid/scripts/config/` and `canonical/aid/scripts/kb/`, rendered to all 5 profiles by
  the canonical→profiles generator like every other shipped script.
- **Twin (feature-003-owned):** `connector-secret.sh` + `connector-secret.ps1` — a language twin
  per the twin rule ("Touching a language twin: change BOTH twins in the same commit",
  `.aid/knowledge/coding-standards.md` §Conventions; existing precedent: `assemble-3part.sh` /
  `.ps1`, `migrate-work-hierarchy.sh` / `.ps1`). **feature-003 owns this twin and defines BOTH
  operations — `write` and `purge`** (STATE.md Q7 item 2; the `purge` op fulfils the removal
  guarantee of STATE.md Q3). There is exactly ONE secret twin: **feature-006 does NOT define its
  own purge twin — on REMOVE it CALLS feature-003's `purge` op** (STATE.md Q7 item 2). Housing both
  ops in this one feature-003-owned twin is what keeps all secret-store I/O in one place. (Names
  are a design proposal; the implementation task finalizes them.)
- **Path confinement (first-class guarantee — BOTH ops).** Every op treats the connector key as a
  **filename stem only**: it resolves the target strictly under `.aid/connectors/.secrets/` and
  **refuses any path that escapes that directory**. Any stem containing a path separator (`/` or
  `\`) or a `..` segment is **rejected with a non-zero exit and an stderr diagnostic, before any
  read / write / delete**. This applies identically to `write` and `purge` — a delete op
  especially must be confined — and is the guarantee feature-006's reconcile relies on
  (feature-006 SPEC.md:270-271, "the op refuses any target escaping `.aid/connectors/.secrets/`").
- **Contract (`write` op):** input = the connector **key** (the descriptor filename stem —
  feature-001's connector key) plus the interactively-prompted value; effect = **after the
  path-confinement check above**, create/overwrite `.aid/connectors/.secrets/<connector>` with the
  exact secret bytes; result = the **`file:` reference** (never the value) is printed to
  **stdout**, diagnostics to **stderr** (`.aid/knowledge/coding-standards.md` §Logging and
  Output). It never prints the value.
- **Contract (`purge` op):** input = the connector **key**; effect = **after the path-confinement
  check above**, delete `.aid/connectors/.secrets/<connector>` if present; **idempotent** — a
  missing value file is a no-op success (an already-removed / never-stored connector must not
  error). Prints nothing to stdout (there is no value to echo); diagnostics to stderr. Callers:
  feature-006 on full REMOVE (STATE.md Q3 / Q7 item 2) and feature-003's own lifecycle on an
  auth-downgrade orphan (see Feature Flow → Secret lifecycle).
- **Exit codes:** reuse the shared exit-code scheme (`0` success — including the idempotent
  `purge` no-op — and `2` usage error); add documented non-zero codes for the fail-closed
  ignore-precondition and the path-confinement rejection, and record them in the script header per
  §Conventions.
- **NOT `read-setting.sh`.** That accessor resolves only 2-level `section.key` paths (KI-001) and
  is read-only; the secret writer is a separate, write-side concern.

**Cross-platform write + restrictive perms (AC-8).**

- **POSIX (Bash):** create the value with owner-only perms from the outset —
  `( umask 077; printf '%s' "$value" > "$file" )` — so there is no window in which the file is
  group/world-readable; `printf '%s'` writes the exact bytes with no trailing newline appended.
  Ensure `.aid/connectors/.secrets/` is mode `700` (owner-only) where supported. On filesystems
  that do not honor POSIX modes, the git-ignore remains the guarantee (feature-001).
- **Windows (WinPS 5.1, ASCII-only):** write exact bytes with
  `[System.IO.File]::WriteAllText($path, $value, (New-Object System.Text.UTF8Encoding($false)))`
  — no BOM, no appended newline (avoid `Set-Content` / `Out-File`, which add a line terminator or
  BOM). Best-effort owner-only ACL tightening where supported (`icacls` / `Set-Acl`); per
  feature-001 the git-ignore is the load-bearing Windows guarantee. Uses only WinPS-5.1-safe
  constructs — no `-Encoding utf8NoBOM`, no ternary / null-coalescing, no `$IsWindows`
  (`.aid/knowledge/coding-standards.md` §PowerShell Conventions).
- **No new heavy runtime dependency (REQUIREMENTS §6, AC-8):** the `file:` store is pure
  Bash+PowerShell on Windows/macOS/Linux with **zero** added runtime dependency (feature-001).
  `keychain:` remains the non-default alternative (OS keychains diverge; the Linux path would need
  an added package — feature-001 §Security Specs), so feature-003 does **not** implement a
  keychain writer.

**Which reference forms actually write a value** (binds feature-001's three forms; does not add a
fourth):

- `file:.aid/connectors/.secrets/<connector>` (feature-001 **default**) — feature-003's write
  path: prompt → write value → reference recorded. This is the ONLY form for which feature-003
  captures and stores a value.
- `env:<VAR_NAME>` — the value lives in the environment, set by the user; AID writes **no** value
  and the `env:` reference is recorded only (set during feature-002 elicitation). No
  prompt-for-value.
- `keychain:<key>` — the value lives in the OS keychain, managed by OS tooling **outside** AID's
  zero-dependency write path; AID writes **no** value to the file store and the `keychain:`
  reference is recorded only.

### Feature Flow

Scoped to the `file:` default — the only reference form that captures a value. The flow runs
inside the P7-exempt discover connector sub-phase (feature-002), **after** feature-002 elicitation
has created the `.aid/connectors/<connector>.md` descriptor with its `auth_method` and intended
reference form.

1. **Guard.** When `auth_method: none`, capture no secret — and if a value is already stored for
   this connector, dispose it as an auth-downgrade orphan (see Secret lifecycle below). If the
   reference form is `env:` or `keychain:`, record the reference only (no value is captured — see
   Layers & Components) and, if a `file:` value was previously stored, dispose that orphan too.
   Continue the capture path only for the `file:` default.
2. **Ignore precondition (fail-closed).** Assert `.aid/connectors/.gitignore` exists and ignores
   `.secrets/`; refuse to proceed otherwise (Security Specs).
3. **Prompt (no echo).** Prompt the developer for the secret with terminal echo off (Bash
   `read -rs`; PowerShell `Read-Host -AsSecureString`). Nothing is echoed or logged.
4. **Write value.** Ensure `.aid/connectors/.secrets/` exists (mode `700` where supported); write
   the exact secret bytes to `.aid/connectors/.secrets/<connector>` with owner-only perms
   (`umask 077` / best-effort ACL), no trailing newline.
5. **Record reference (not value).** Ensure the descriptor's `secret_reference` holds
   `file:.aid/connectors/.secrets/<connector>` — the reference, never the value (feature-001
   §Data Model). The writer prints this reference to stdout as its only result.
6. **Clear.** Zero/clear the in-memory secret immediately (`unset` / `Remove-Variable` + BSTR
   zero).
7. **Regenerate index.** `.aid/connectors/INDEX.md` is (re)built from descriptor frontmatter by
   the connectors-index builder (feature-001; feature-005) — its `Secret Ref` column is composed
   from `secret_reference` (a reference), never the value.

**Descriptor ownership (no double-writer).** feature-002 elicitation creates the descriptor and
sets `secret_reference`; feature-003 writes the **VALUE** into the store and guarantees the
committed field remains a **reference**. This mirrors feature-001 §Feature Flow verbatim
(feature-002 "sets the `secret_reference` field"; feature-003 "writes the actual secret value …
and records only the reference in the descriptor").

**Secret lifecycle (feature-003-owned).** feature-003 owns the full lifecycle of the values it
stores, not only their creation:

- **Create / update** — the `write` op (numbered flow above).
- **Auth-downgrade orphan (STATE.md Q7 item 7).** When a **surviving** connector's `auth_method`
  downgrades to `none` — or its `secret_reference` changes away from the `file:` store (to `env:`
  or `keychain:`) — any value previously stored at `.aid/connectors/.secrets/<connector>` becomes
  unreferenced. Disposing it is **feature-003's concern**: its lifecycle invokes the twin's
  idempotent `purge` op so no orphaned secret lingers in the store. This is distinct from
  **feature-006**, which purges only on **full REMOVE** of a connector (STATE.md Q3 / Q7 item 2);
  an auth-downgrade leaves the connector present, so the orphan is owned here, not by reconcile.

### Data Model

feature-003 introduces **no schema**. The reference-recording shape — the descriptor
`secret_reference` field, its three allowed forms, and the git-ignored
`.aid/connectors/.secrets/<connector>` value file keyed by the descriptor filename stem — is
defined by feature-001 (§Data Model and §Layers & Components) and is BOUND here unchanged. The
only artifact feature-003 writes that is not a feature-001-defined committed artifact is the
git-ignored value file itself, whose "shape" is opaque bytes (the raw secret), not a schema.
