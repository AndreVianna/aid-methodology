# Feature-011 — `settings.yml` validate/repair + era-b synthesis contract

> **Type:** DESIGN note (task-074). Advisory only — **no production code**. This pins the
> exact `.aid/settings.yml` "valid" contract, the era-a repair algorithm, the era-b synthesis
> algorithm, the era-a/era-b detection rule, and a test-vector appendix, so that:
> - **task-077** (Wave-2 SETTINGS step of `_aid_migrate_repo`) can implement without re-deriving any contract, and
> - **task-081** (era-a/era-b/idempotency unit tests) can fixture directly from the appendix.
>
> Grounded in: SPEC `feature-011-upgrade-migration/SPEC.md` (DM-1, DD-2, DD-3, DD-6, RC-4, §6 gates),
> grounding brief `feature-011-grounding.md` §1 (schema + readers) + §2 (era-b map), and the live
> source cited inline. **Scope of this note = FF-1 step 0 (DETECT) + step 1 (SETTINGS) only**;
> steps 2-4 (home.html / relocate / register) are out of scope (owned by their own Wave-2 tasks).

---

## 0. The reader set this contract is defined against (the validate-against set)

A settings.yml is **valid** iff *every* reader below parses it **without falling into its
fallback path**. The repair/synthesis output is graded against exactly these five readers
(grounding §1; SPEC DM-1 "Readers" bullet). Their fallback behaviors — what we must **not**
trip — are:

| # | Reader | File:line | Parses | Fallback we must NOT trip |
|---|--------|-----------|--------|---------------------------|
| RDR-1 | `read-setting.sh` `lookup` (scalars) | `canonical/scripts/config/read-setting.sh:138-162` | awk: enter `^<section>:\s*$`, leave on next col-0 `^[a-zA-Z]`, match indented `^\s+<key>:`; strips inline `# …` and surrounding quotes | empty output → caller falls back to `--default` or exits 1/2. A `<section>:` line with a **trailing inline value** (not bare) is not entered (`{ in_section=1; next }` requires `^section:[[:space:]]*$`). |
| RDR-2 | `read-setting.sh` `lookup_list` (lists) | `read-setting.sh:169-207` | awk: same section gate; accepts inline `[a, b]` OR block `\n  - a\n  - b`; comma-joins items | empty output → empty list. A `tools:` block whose `installed:` key is **absent**, or whose value is neither inline-`[…]` nor followed by `  - ` items, yields empty. |
| RDR-3 | server `_read_settings` | `dashboard/server/server.py:189-214` | line-scan: `in_project` set when a `stripped == "project:"` OR `stripped.startswith("project:")`; inside it reads `name:` / `description:`; block ends on a non-`#`, non-indented (`not line.startswith(" ")`) line | returns `(None, None)` on any exception; `name`/`description` stay `None` if the `name:`/`description:` scalar value is empty after stripping quotes/comment. Node twin (`server.mjs`) parses identically. |
| RDR-4 | reader `parse_project_name` | `dashboard/reader/parsers.py:155-199` | line-scan: `in_project` on `stripped == "project:"` OR `startswith("project: ")`; regex `^\s+name:\s+(.+)`; ends block on a new col-0 section key | returns `("", n)` when no `name:` matched → caller uses **dir basename** (`models.py:166`). NOTE the `name:` regex requires **at least one space** after the colon (`name:\s+`); `name:` with no value or a tab-only gap does not match. |
| RDR-5 | reader `parse_kb_baseline` | `parsers.py:231-279` | line-scan for top-level `kb_baseline:`; within block, regex `^\s+branch:\s+(.+)` / `^\s+tip_date:\s+(.+)`; block ends on a non-`#` col-0 `…:` line | returns `None` when no real `kb_baseline:` block (a **commented** `# kb_baseline:` is never entered → correctly treated as "no baseline"). Used here only to assert **repair preserves** a present block. |

**Shape implications the output MUST honor (derived from RDR-1..5):**
- **S1.** Every section header (`project:`, `tools:`, `review:`, `execution:`, `traceability:`)
  is a **bare** line: `^<name>:[[:space:]]*$` (no trailing inline value). RDR-1/RDR-2 require it
  to enter the section.
- **S2.** Every required scalar is **indented** under its section as `  <key>: <value>` with **at
  least one space** after the colon and a **non-empty** value (RDR-3/RDR-4 `name:\s+(.+)`; an empty
  value re-trips the fallback).
- **S3.** `tools.installed` is a list — either inline `installed: [claude-code, codex]` or block
  `installed:\n    - claude-code` (the template uses block form, `settings.yml:23-24`). Either is
  accepted by RDR-2. An **empty list is valid** per DM-1 (≥0 entries) but should be emitted as
  inline `installed: []` so the `installed:` key still exists (the block must exist — DM-1).
- **S4.** Top-level keys are at column 0; section contents are indented (2 spaces, matching the
  template). RDR-3/RDR-4/RDR-5 end a block on a col-0 line, so indentation discipline is what keeps
  `project:` and `kb_baseline:` blocks correctly bounded.

---

## 1. The "valid" contract — per-key matrix (DM-1)

A settings.yml is **valid** iff all REQUIRED rows below are present and well-typed (so RDR-1..5
parse without fallback). OPTIONAL rows are **preserved verbatim** when present and **never
synthesized** when absent (absent ≡ "no baseline"/"no override", which is itself valid).

| Dotted key | Class | Type / validity test | Template default | era-a handling (keep-if-valid-else-default) | era-b synthesis value |
|---|---|---|---|---|---|
| `project.name` | **REQUIRED** | string, single-line, **non-empty** after quote/comment strip | `<project-name>` | keep if present & non-empty; else fill **basename(repo)** | `basename(repo)` |
| `project.description` | **REQUIRED (key present)** | string, single-line, **NO embedded newline**; value MAY be a placeholder | `<project-description>` | keep the line if the `description:` key exists (even placeholder); else add with placeholder | placeholder `<project-description>` |
| `project.type` | **REQUIRED** | enum ∈ {`brownfield`,`greenfield`} | `brownfield` | keep if valid enum; else `brownfield` | `brownfield` |
| `tools.installed` | **REQUIRED (block exists)** | list<string>, ≥0 entries; the `installed:` key must exist under a bare `tools:` | `[claude-code]` (block form) | keep verbatim if the `installed:` list exists (any/empty); else add it | manifest-derived (§3) |
| `review.minimum_grade` | **REQUIRED** | matches `^[A-F][+-]?$` | `A` | keep if matches; else `A` | `A` |
| `execution.max_parallel_tasks` | **REQUIRED** | integer **> 0** | `5` | keep if int>0; else `5` | `5` |
| `traceability.heartbeat_interval` | **REQUIRED** | integer **≥ 0** (`0` disables) | `1` | keep if int≥0; else `1` | `1` |
| `kb_baseline.branch` | **OPTIONAL / PRESERVE** | string | absent (commented) | **byte-intact**; never touch, never add | **never synthesize** |
| `kb_baseline.tip_date` | **OPTIONAL / PRESERVE** | ISO-8601 string | absent (commented) | **byte-intact**; never touch, never add | **never synthesize** |
| `<skill>.minimum_grade` | **OPTIONAL / PRESERVE** | `^[A-F][+-]?$`, `<skill>` ∈ {discover, summary, interview, specify, plan, detail, execute, deploy, monitor} | absent (commented) | **byte-intact**; never touch, never add | **never synthesize** |

Notes on the type tests (these are the *validity* tests; they are deliberately tolerant —
matching how the readers read):
- **`project.name` non-empty.** The template ships the placeholder `<project-name>`. Per DM-1 the
  template placeholder is the *default value* (a non-empty single-line string), so a literal
  `<project-name>` **passes** the non-empty test and is left untouched in era-a (it is what a
  freshly-`aid-config`'d-but-never-INITed repo would carry). Only a **missing `name:` line** or a
  **blank value** (`name:` / `name: ""`) is malformed → fill basename. Rationale: do not second-guess
  a user/`aid-config` placeholder; only repair what the readers would fall back on.
- **`project.description`.** REQUIRED that the *key line* exists and is single-line; the *value* may
  be the placeholder `<project-description>`. A missing `description:` line is the only repair trigger.
- **`tools.installed` empty is valid** (DM-1 "≥0 entries; the block must exist"). The repair trigger
  is a missing `tools:` section or a missing `installed:` key — not an empty list.

---

## 2. Era-a — validate / repair algorithm (DD-3 / R21 — targeted edit, never overwrite)

**Precondition:** `.aid/settings.yml` exists (era-a, per §4 detection). Goal: edit **only** the
missing/malformed REQUIRED keys; leave **every** present `kb_baseline` line and `<skill>` override
**byte-intact**; write crash-safe.

### 2.1 OQ-4 resolution — repair granularity (the recorded decision)

> **DECISION (OQ-4): edit-missing/malformed-keys-in-place — NOT rewrite-from-template-splicing.**

The two candidates from SPEC Residual OQ-4 were (a) edit only the offending keys in place, vs
(b) rewrite the whole file from the template and splice the preserved blocks back. **(a) is the
simplest-correct** and is adopted:

- **Why (a) over (b).** (b) must *re-locate and re-extract* the `kb_baseline` block and every
  `<skill>` override from the old file and re-inject them into a template skeleton — that is
  strictly more parsing of the exact blocks (a) leaves untouched, and any extraction bug **drops
  user data** (the R21 hazard). (a) touches a present optional block **zero** times by construction,
  which is the strongest possible preservation guarantee. (b) also reorders/re-comments the file
  (losing the user's surrounding comments and ordering); (a) preserves them. (b)'s only claimed
  advantage — "guaranteed canonical shape" — is unnecessary because the readers (RDR-1..5) are
  tolerant line-scanners, not strict-schema parsers; canonical *ordering* is not part of "valid".
- **Invariant (fixed for task-077, restated from DD-3/R21):** repair edits **only** REQUIRED keys
  that are missing or malformed; **any present `kb_baseline.*` line and any present
  `<skill>.minimum_grade` override is preserved byte-for-byte**; the write is crash-safe
  (same-directory temp file + `mv -f`, never an in-place truncating rewrite).

### 2.2 The two crash-safe write idioms (reused from `/aid-config`)

Both come from `canonical/skills/aid-config/SKILL.md` and use a **same-directory temp file +
`mv -f`** (POSIX atomic rename; SKILL.md:124). task-077 reuses them verbatim:

- **IDIOM-A — single-line in-place replace** (`aid-config/SKILL.md:124`). Used when a REQUIRED
  *scalar* exists but is **malformed** (e.g. `project.type: prod`, `review.minimum_grade: Z`,
  `execution.max_parallel_tasks: 0`). Read the file, replace the **one** matching line, preserving
  the line's inline comment and all surrounding lines, write temp + `mv -f`.
- **IDIOM-B — append-block** (`aid-config/SKILL.md:126-132`). Used when a REQUIRED *section or key
  is wholly missing* (e.g. no `traceability:` block, or `tools:` present but no `installed:`). Append
  the missing block (bare header + indented key/value) — for a missing **section**, append a fresh
  `\n<section>:\n  <key>: <value>` block at end of file; for a missing **key inside an existing
  section**, IDIOM-A's surgical insertion under that section header (insert an indented line directly
  after the section header line). Append to end-of-file is safe for the readers because they are
  order-independent line scanners (RDR-1..5) — a `tools:` block appended after `traceability:` still
  parses.

### 2.3 The repair decision tree (per key)

For each REQUIRED key, in this order (the SETTINGS step runs these against the in-memory file once,
batching edits into a single temp-file write):

```
load lines = read(.aid/settings.yml)         # in memory; original untouched until mv -f

# --- per-key: keep-if-valid-else-repair ---
for key in REQUIRED (project.name, project.description, project.type,
                     tools.installed, review.minimum_grade,
                     execution.max_parallel_tasks, traceability.heartbeat_interval):

  presence = locate(key, lines)              # section header + indented key line

  case A: key present AND value valid (per §1 type test)
        -> NO EDIT (keep verbatim, including its inline comment)

  case B: key present BUT value malformed     (scalar only)
        -> IDIOM-A single-line replace with the §1 default
           (project.name malformed == missing/blank -> basename; others -> template default)

  case C: scalar key missing, section present
        -> insert indented "  <key>: <default>" under the existing section header (IDIOM-B surgical)

  case D: whole section missing
        -> append bare "<section>:\n  <key>: <default>" block at EOF (IDIOM-B)
           (project: -> name=basename, description=placeholder, type=brownfield, as a 3-line block;
            tools: -> "installed:\n    - <each manifest tool, or [] if none>";
            review:/execution:/traceability: -> single-key blocks)

# --- preserve (never enumerated for edit) ---
# kb_baseline.* lines and <skill>.minimum_grade lines are NEVER located-for-edit:
# the loop above iterates ONLY the 7 REQUIRED keys, so optional blocks are
# structurally outside the edit set -> byte-intact by construction.

if no edits were applied -> NO WRITE (idempotent: a valid era-a file is a no-op; §6 gate 1/6)
else -> write all batched edits to a same-directory temp file; mv -f over the original (crash-safe)
```

### 2.4 The exact value-preservation guarantee (R21)

> **GUARANTEE PV-1.** For any era-a input file `F`, let `O(F)` = the set of byte-ranges occupied by
> lines belonging to a present `kb_baseline:` block (the `kb_baseline:` header line and its indented
> `branch:`/`tip_date:` children) and any present top-level `<skill>:` override block. The repaired
> output `F'` contains every line in `O(F)` **byte-identical and in the same relative position**.
> Repair only **inserts** REQUIRED-key lines/blocks (IDIOM-B) or **replaces** a single malformed
> REQUIRED scalar line (IDIOM-A); it performs **no deletion, no reflow, and no reordering** of any
> existing line. (A repaired commented `# kb_baseline:` example also stays a comment — RDR-5 never
> entered it, and IDIOM-A/B never target a `#` line.)

This is testable by **byte-diffing** `F` vs `F'` restricted to `O(F)` lines (task-081 era-a-preserve
test): the diff over those ranges must be empty.

---

## 3. Era-b — synthesis algorithm (RC-4 / DD-2)

**Precondition:** no `.aid/settings.yml`, but a `.aid/knowledge/{DISCOVERY_STATE.md |
DISCOVERY-STATE.md | STATE.md}` marker exists (era-b, per §4). Goal: write a **fresh
template-derived** `settings.yml` (nothing to preserve), crash-safe.

### 3.1 Field map

| settings.yml key | Era-b value | Source / citation |
|---|---|---|
| `project.name` | `basename(<repo>)` (the repo folder base name) | the dashboard's own fallback, `models.py:166`; RC-4 |
| `project.description` | placeholder `<project-description>` (template default; empty allowed) | template `settings.yml:16`; RC-4 (STATE.md carries none — grounding §2b) |
| `project.type` | `brownfield` | template default `settings.yml:17`; RC-4 |
| `tools.installed` | the **keys of `.aid/.aid-manifest.json` `"tools"`**, one per block-list item | DD-2; via the manifest reader in §3.2 |
| `review.minimum_grade` | `A` | template default `settings.yml:38` |
| `execution.max_parallel_tasks` | `5` | template default `settings.yml:44` |
| `traceability.heartbeat_interval` | `1` | template default `settings.yml:50` |
| `kb_baseline.*` | **omitted** (absent ≡ no baseline; RDR-5 returns None → reader stays approved) | DM-1; never synthesized |
| `<skill>.minimum_grade` | **omitted** | DM-1; never synthesized |

**STATE.md / DISCOVERY_STATE.md are a QUALIFIER ONLY, not a config source (DD-2/RC-4).** They carry
no `project.name`/`description`/`tools` (grounding §2b confirms the template has no such fields).
They are read **only** by the §4 detection presence-test to prove the repo is an AID project; the
synthesizer never extracts a value from them.

### 3.2 The manifest reader (which one, exactly — DD-2)

> **Bash:** use **`manifest_list_tools <manifest>`** from `lib/aid-install-core.sh:1117` (NOT a new
> parser, NOT STATE.md). Contract (`:1114-1144`): prints each installed tool id (the keys of the JSON
> `tools` object) one per line; **exits 0 and prints nothing when the manifest is absent**; python3
> fast-path with a pure-awk fallback. The manifest path is `<repo>/.aid/.aid-manifest.json`.
>
> **PowerShell (parity GAP — task-077 must close it):** `lib/AidInstallCore.psm1` has only *per-tool*
> manifest readers (`Read-ManifestToolPaths`, `Read-ManifestToolVersion`, `Read-ManifestRootAgent*`) —
> there is **no list-all-installed-tools enumerator** equivalent to bash `manifest_list_tools` today.
> So **task-077 must ADD a small PS parity function** (e.g. `Read-ManifestTools <manifest>` returning
> the keys of the JSON `tools` object, empty/none when the manifest is absent — mirroring
> `manifest_list_tools` exactly) and use it for the era-b `tools.installed` derivation. This is a
> required new shared-core function on the PS side, gated by `test-aid-cli-parity.sh` (R17).

Era-b `tools.installed` derivation:
```
tools = manifest_list_tools("<repo>/.aid/.aid-manifest.json")   # newline-separated ids, may be empty
if tools is empty (no manifest OR no tool keys):
     emit  installed: []          # valid empty list (DM-1: block must exist; S3)
else:
     emit  installed:\n    - <id>  (one block-list item per id, preserving manifest order)
```
(An era-b repo with a KB marker but **no** manifest is unusual but tolerated: `installed: []` keeps
the block present so RDR-2 returns an empty list, not a fallback.)

### 3.3 Synthesized file shape (the exact bytes task-077 emits)

Derived from the template (`canonical/templates/settings.yml`) with the §3.1 values filled. It MUST
satisfy S1-S4. Recommended emission (block-list tools; section comments optional but the template
ships them — keeping them is fine and ASCII-only):

```yaml
project:
  name: <basename>
  description: <project-description>
  type: brownfield

tools:
  installed:
    - claude-code        # one block item per manifest tool key; or "installed: []" if none

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
```

Write via same-directory temp file + `mv -f` (crash-safe; SPEC DM-1 crash-safe bullet). No
`kb_baseline:` block and no `<skill>:` override is written (omitted ≡ valid).

---

## 4. Detection / qualify rule (DD-6) — era-a vs era-b vs non-candidate

Read-only presence test (no mutation). This is FF-1 step 0; the SETTINGS step (steps 1) branches on
the era it returns.

```
qualify(<repo>):
  if NOT test -d "<repo>/.aid"              -> NON-CANDIDATE (no .aid/ at all)
  if      test -f "<repo>/.aid/settings.yml"                              -> ERA-A (validate/repair)
  elif    test -f "<repo>/.aid/knowledge/DISCOVERY_STATE.md"
       OR test -f "<repo>/.aid/knowledge/DISCOVERY-STATE.md"
       OR test -f "<repo>/.aid/knowledge/STATE.md"                        -> ERA-B (synthesize)
  else                                                                    -> NON-CANDIDATE
```

- **Era-a takes precedence:** if `settings.yml` exists, it is era-a even when a KB marker is also
  present (validate/repair the existing file; never synthesize over it).
- **Bare `.aid/` is NOT a candidate (DD-6):** a `.aid/` with neither `settings.yml` nor any of the
  three KB markers (e.g. only `.aid/.temp/`) returns NON-CANDIDATE → the SETTINGS step does nothing
  and no file is written (SPEC §6 gate 8; SEC-1 read-only-until-consent).
- **All three KB-marker filenames are accepted** to cover the rename history (DISCOVERY-STATE →
  STATE, grounding §2a) and the UNCERTAIN pre-0.7 exact filename (RC-4).
- This is a **presence test, not a heuristic** (DD-6): each marker is a file the AID pipeline itself
  writes, so qualification is provable, never guessed.

---

## 5. Acceptance-criterion → contract map (for task-077 / task-081)

| task-074 AC | Satisfied by |
|---|---|
| Valid def pinned as REQUIRED-vs-OPTIONAL matrix over every DM-1 key + names the reader set | §1 matrix + §0 RDR-1..5 table |
| era-a repair = targeted-edit-not-overwrite, preserves kb_baseline + overrides byte-intact, crash-safe via temp+`mv -f` reusing IDIOM-A/B | §2.1 decision, §2.2 idioms, §2.3 tree, §2.4 PV-1 |
| era-b field map fully specified (basename / brownfield / placeholder / manifest tools / template defaults); STATE.md qualifier-only | §3.1 map, §3.2 `manifest_list_tools`, §3.3 shape; §3.1 note |
| OQ-4 resolved with a recorded simplest-correct decision; invariant restated | §2.1 (edit-in-place chosen; invariant restated) |
| Seam unambiguous enough that task-077 implements + task-081 asserts without re-deciding | §2.3 tree + §3 + §4 + §6 vectors |

---

## 6. Test-vector appendix (task-081 fixtures + §6 gates 4/5/6/7/8)

Concrete inputs and expected post-SETTINGS-step outputs. Each repo root `<R>` = the fixture base
folder; the SETTINGS step runs on `<R>`. (Steps 2-4 are out of scope for this note.)

### TV-1 — era-a VALID → no-op (§6 gate 4a / gate 6 idempotency)

`<R>/.aid/settings.yml`:
```yaml
project:
  name: My Service
  description: A demo service.
  type: brownfield
tools:
  installed:
    - claude-code
review:
  minimum_grade: A
execution:
  max_parallel_tasks: 5
traceability:
  heartbeat_interval: 1
```
**Expected:** all 7 REQUIRED keys present + well-typed → **no edit, no write** (byte-identical file).
A second run is also a no-op (idempotent).

### TV-2 — era-a MALFORMED + populated `kb_baseline` + per-skill override → repair, preserve (§6 gate 4b; the R21 hazard)

`<R>/.aid/settings.yml` (missing the whole `traceability:` section; `review.minimum_grade` malformed
`Z`; **plus** a populated `kb_baseline` block and a `discover:` override that MUST survive byte-intact):
```yaml
project:
  name: Legacy App
  description: Old repo.
  type: brownfield
tools:
  installed:
    - claude-code
    - codex
review:
  minimum_grade: Z

execution:
  max_parallel_tasks: 5

kb_baseline:
  branch: master
  tip_date: 2026-06-01T10:00:00Z

discover:
  minimum_grade: A+
```
**Repairs applied (and ONLY these):**
- `review.minimum_grade: Z` → IDIOM-A single-line replace → `minimum_grade: A` (case B).
- whole `traceability:` section missing → IDIOM-B append-block at EOF → `traceability:\n  heartbeat_interval: 1` (case D).

**Expected output** (the two REQUIRED fixes applied; `kb_baseline` block and `discover:` override
**byte-identical** to input — PV-1; `traceability:` appended at end since order does not matter to
RDR-1..5):
```yaml
project:
  name: Legacy App
  description: Old repo.
  type: brownfield
tools:
  installed:
    - claude-code
    - codex
review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

kb_baseline:
  branch: master
  tip_date: 2026-06-01T10:00:00Z

discover:
  minimum_grade: A+

traceability:
  heartbeat_interval: 1
```
**Assertions (task-081):** parses clean for RDR-1..5 (no fallback); `parse_kb_baseline` returns
`{branch:master, tip_date:2026-06-01T10:00:00Z}` (NOT None); the `kb_baseline:` + `discover:` line
ranges byte-diff empty vs input (PV-1); `read-setting.sh review minimum_grade` → `A`,
`traceability heartbeat_interval` → `1`. Re-run = no-op (idempotent).

### TV-3 — era-b ABSENT settings + STATE.md + manifest → synthesize (§6 gate 5)

Fixture: **no** `<R>/.aid/settings.yml`; `<R>/.aid/knowledge/STATE.md` present (qualifier);
`<R>` basename = `acme-web`; `<R>/.aid/.aid-manifest.json`:
```json
{ "manifest_version": 1, "aid_version": "0.6.0",
  "tools": { "claude-code": { "version": "0.6.0" }, "cursor": { "version": "0.6.0" } } }
```
**Expected synthesized `<R>/.aid/settings.yml`:**
```yaml
project:
  name: acme-web
  description: <project-description>
  type: brownfield

tools:
  installed:
    - claude-code
    - cursor

review:
  minimum_grade: A

execution:
  max_parallel_tasks: 5

traceability:
  heartbeat_interval: 1
```
**Assertions:** `parse_project_name` → `acme-web` (NOT basename-fallback because the value is now
written); `read-setting.sh tools installed` → `claude-code,cursor` (manifest order, via
`manifest_list_tools`); `parse_kb_baseline` → None (no block, stays approved); parses clean for all
readers. Variant with `DISCOVERY_STATE.md` instead of `STATE.md` qualifies identically.
Era-b variant with **no manifest** → `installed: []` (valid empty list). Re-run after synthesis is
era-a-valid → no-op.

### TV-4 — bare `.aid/` → NON-CANDIDATE (§6 gate 8)

Fixture: `<R>/.aid/.temp/` exists; **no** `settings.yml`, **no** `knowledge/{DISCOVERY_STATE.md |
DISCOVERY-STATE.md | STATE.md}`.
**Expected:** `qualify` returns NON-CANDIDATE → the SETTINGS step writes **nothing**; the `.aid/`
tree is byte-identical after the run (read-only detection, SEC-1).

---

## 7. Cross-checks against §6 quality gates (this note's coverage)

- **Gate 4 (era-a unit tests):** TV-1 (no-op) + TV-2 (repair + preserve). Contract: §1/§2.
- **Gate 5 (era-b unit tests):** TV-3 (synthesize, STATE.md + DISCOVERY_STATE variant + manifest).
  Contract: §3.
- **Gate 6 (idempotency):** TV-1/TV-2/TV-3 all re-run = no-op (era-a "no edits → no write" in §2.3;
  era-b output is era-a-valid).
- **Gate 7 (no-delete):** PV-1 (§2.4) guarantees repair never deletes a line; era-b writes a fresh
  file only when none exists (§3 precondition).
- **Gate 8 (bare-`.aid/` non-candidate):** TV-4 + §4 detection rule.
- **ASCII-only (gate 1):** every literal in §3.3 / §6 (and any prompt/advisory) is ASCII;
  task-077's Bash + PS twin must keep the synthesized/repaired bytes ASCII (MEMORY "ASCII-only").
- **Out of this note's scope:** gates 2 (parity), 3 (vendor-refresh), 9 (sentinel trigger), 10 (R5
  Playwright) — those exercise steps 2-4 / trigger / page, owned by their own tasks. This note pins
  steps 0-1 only.
