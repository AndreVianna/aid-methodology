# .aid/ Cleanup

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-06-02 | Feature identified from REQUIREMENTS.md §5 (FR4), §6 (NFR1), §8 (D2) | /aid-interview |
| 2026-06-02 | Technical Specification authored (scan + tiered classification, (i)/(ii) work-folder safety matrix, active-folder rule, checklist confirm-UI, git rm/rm split, D2 coordination, cancel-all gate, --cleanup-only entry, classification test suite) | /aid-specify |
| 2026-06-02 | FIX (review C+→re-gate): scoped the active-folder guarantee to work-folder-context runs, floor=(c)+signal-(i)-fail for repo-root/cleanup-only (MEDIUM); no-STATE.md work folder → (i)-fail not offered (LOW); dynamic S6 snapshot (LOW); gitignore cite 43–44 (LOW); verify_*.py path prefixes (MINOR) | /aid-specify (review) |

## Source

- REQUIREMENTS.md §5 FR4 (`.aid/` cleanup — checklist, user-confirmed, tiered)
- REQUIREMENTS.md §6 NFR1 (safety / no-data-loss)
- REQUIREMENTS.md §8 D2 (overlap with the known `verify-deterministic-report.json` fix)
- REQUIREMENTS.md §9 AC7–AC8

## Description

The cleanup stage of `/aid-housekeep` — the final, user-controlled sweep of stale `.aid/`
artifacts. It gathers candidates and presents a **tiered checklist**: clearly-safe items
(`.aid/.temp/`, `.aid/.heartbeat/`, stray tool reports like `verify-deterministic-report.json`,
build-only artifacts) start **checked**; higher-risk items (work folders, anything that looks
hand-authored) start **unchecked** and flagged "review." A `work-*` folder is offered only
when it is **merged to `master`** (signal (i), the necessary/primary signal); `STATE.md`
marked Deployed/concluded (signal (ii)) is the secondary confirmation — (i)+(ii) agree → offer
it; (i) passes but (ii) fails → prompt for explicit confirmation (surfacing why); (i) fails →
not offered. The **currently active** work folder is never offered. The user confirms per item;
only confirmed items are removed — tracked items via `git rm` (staged, recoverable), untracked
cruft via plain `rm`, with no separate trash directory. Coordinates with the known D2 fix so it
does not conflict.

## User Stories

- As an AID maintainer, I want a checklist of stale files with safe items pre-selected so that
  I can clean up quickly while keeping control over the risky ones.
- As an AID maintainer, I want only merged-and-concluded work folders offered for deletion (and
  never the active one) so that I never lose in-flight or unmerged work.
- As an AID maintainer, I want deletions of tracked files staged via `git rm` so that they are
  reviewable and recoverable from git history.

## Priority

Must

## Acceptance Criteria

- [ ] **AC7** — Given stale artifacts, when the checklist is presented, then safe items are
  checked and work folders unchecked; only merged-to-`master` folders are offered; an
  (i)-pass/(ii)-fail folder triggers an explicit-confirm prompt; the active work folder is
  never offered.
- [ ] **AC8** — Given confirmed deletions, when they are applied, then tracked items are
  removed via `git rm` (staged) and untracked cruft via `rm`, committed on the
  `aid/housekeep-*` branch, with no push and no commit to `master`.
- [ ] **NFR1** — Given any candidate, when no explicit confirmation is given, then it is not
  removed.

---

## Technical Specification

> Scope note: this feature delivers the **body of the CLEANUP state** — the candidate
> scan, tiered classification, work-folder safety matrix, checklist confirm-UI, and the
> `git rm`/`rm` deletion + single commit. It is the *body* that plugs into the interface
> defined by **feature-001** (`canonical/skills/aid-housekeep/references/state-cleanup.md`
> stub + the `## Housekeep Status` `**Cleanup Stage:**` field + the commit/branch helper
> `canonical/scripts/housekeep/branch-commit.sh`). It is reachable BOTH after the
> SUMMARY-DELTA gate (full sequence) AND directly via `--cleanup-only`
> (feature-001 § Invocation/CLI, AC10). This is the SAFETY feature; every rule below is
> conservative-by-default (NFR1).

### Data Model

**N/A as a relational schema** — AID ships no database (`.aid/knowledge/schemas.md` §1
"There is NO relational database in AID"; §16 "No Migrations, No Indexes, No Soft Deletes").
Cleanup's only persistent write is the gate field `**Cleanup Stage:**` in the work-area
`## Housekeep Status` block (defined by feature-001 SPEC § C-2), written via
`canonical/scripts/housekeep/housekeep-state.sh`. Everything else cleanup reads is
ephemeral filesystem + git state. The classification "data model" is the candidate record
and tier enum defined under *Candidate Gathering & Classification* below.

### Candidate Gathering & Classification (FR4, AC7, NFR3)

The CLEANUP body runs in two phases: a deterministic **scan + classify** (scriptable,
tested — see *Testing*) that emits a candidate list, then a **confirm-UI** that presents it
and acts only on confirmed items.

#### Scan — the inspected paths

The scan inspects a fixed, conservative set of roots under `.aid/` (never the whole repo —
cleanup only sweeps AID's own artifact tree):

| # | Scan target (glob) | On disk today (verified `ls .aid/`) | Notes |
|---|--------------------|-------------------------------------|-------|
| S1 | `.aid/.temp/**` (incl. `.aid/.temp/review-pending/*.md`) | present: `.spot-check-facts.txt`, `h5-interview-brief.md`, `review-pending/*.md` (7 ledgers) | gitignored (`.gitignore` `.aid/.temp/`) → untracked scratch |
| S2 | `.aid/.heartbeat/**` | absent this run; gitignored (`.gitignore` `.aid/.heartbeat/`) | ephemeral L3 heartbeat files (`schemas.md §1` "Ephemeral state") |
| S3 | `.aid/knowledge/.cache/**`, `.aid/knowledge/.manual-checklist.json`, `.aid/knowledge/.spot-check-facts.txt` | gitignored (`.gitignore` lines 40, 43–44) | Mermaid cache + transient summarize review artifacts |
| S4 | stray tool reports: `**/verify-deterministic-report.json`, `**/verify-advisory-report.json` under `.aid/` | none on disk this run | D2 target — see *D2 Coordination* |
| S5 | build-only artifacts under `.aid/generated/**` that are NOT in `canonical/templates/generated-files.txt` | — | only *unregistered* outputs; registered ones (`project-index.md`, `metrics.md`, `INDEX.md` per `schemas.md §14`) are NOT candidates (they are rebuilt, not cruft) |
| S6 | `.aid/work-*/` folders (one candidate per folder) | dynamic — the scan globs `.aid/work-*/` at runtime (e.g. `work-001-aid-housekeep`; transient strays such as `work-002-canonical-generator` may come and go) | the highest-risk class — full safety matrix below |

The scan does NOT touch: `.aid/settings.yml`, `.aid/knowledge/*.md` (the live KB),
`.aid/templates/`, or anything outside `.aid/`. Hand-authored-looking files found loose in
`.aid/` (not matching S1–S5) are surfaced as **Tier-2 review** items, never auto-checked.

#### Candidate record (the unit the scan emits)

Each candidate is `{ path, tier, tracked, default_checked, reason, gate? }`:
- `tracked` ∈ {`tracked`, `untracked`} — resolved per *Deletion Mechanism* (`git ls-files` /
  `git check-ignore`).
- `gate` — only for S6 work folders: the `(i)/(ii)` matrix result.

#### Tier assignment (the classification rule)

| Tier | Membership rule | Default state | Label |
|------|-----------------|---------------|-------|
| **Tier-0 clearly-safe** | S1, S2, S3 (gitignored scratch/heartbeat/cache), S4 stray reports, S5 unregistered build-only outputs | **checked** | (none) |
| **Tier-1 work folders (offered)** | S6 folders that pass the safety matrix below | **unchecked** | `review` |
| **Tier-2 review** | loose `.aid/` files matching none of S1–S5 (hand-authored-looking) | **unchecked** | `review — confirm intent` |
| **(not offered)** | S6 folders failing signal (i); the currently-active work folder (always) | omitted | — |

Tier-0 = "checked" is the only auto-selected class; everything risk-bearing starts
**unchecked** (AC7: "safe items are checked and work folders unchecked"). This mirrors the
conservative posture of `/aid-discover`'s propose→confirm (`canonical/skills/aid-discover/references/state-generate.md`
lines 81, 119 "when uncertain, prefer the default seed … the user-confirm step is the safety net").

### Work-Folder Safety Rules (AC7, NFR1) — the (i)/(ii) decision matrix

A `.aid/work-*/` folder (S6) is the only candidate class with a multi-signal gate. Two
signals are computed; the **currently-active** folder is excluded before either runs.

#### Signal (i) — merged to `master` (necessary / primary)

**What "merged to master" means in this repo.** Critically, the `.aid/work-*` namespace is
**NOT tracked on `origin/master`** — verified: `git ls-tree -d --name-only origin/master .aid/`
returns only `.aid/generated`, `.aid/knowledge`, `.aid/templates`. The established
convention (verified in `git log --all -- '.aid/work-*'`) is that a completed work's
*deliverable* commits merge to `master` and the work folder is then **deliberately removed**
in a follow-up cleanup commit (e.g. `78097e1 chore: remove completed work-001-add-providers
folder`; `cb316e1 chore: remove completed work-001-adaptive-kb work folder`;
`51aca29 chore(work-001): … eliminate work-002`). So presence/absence of the folder *path*
on `origin/master` is NOT a valid merge signal (the convention is to delete it).

**Robust detection (no false positives), in priority order:**

1. **PR-merge check (authoritative).** Read the work's recorded PR number(s) from its
   `STATE.md ## Deploy Status` table (`PR` column — `schemas.md §4` `## Deploy Status`:
   `Delivery | State | PR | KB Updated | Tag | Notes`). For each recorded PR run
   `gh pr view <N> --json state,mergedAt -q .state` and require `MERGED`
   (`gh` is available + the env's auth model — verified `gh pr list --state merged` returns
   data; `integration-map.md` lists `gh` as a registered integration). This is the same
   `gh`-based PR workflow `/aid-deploy` uses (`canonical/skills/aid-deploy/README.md` lines
   154–187 "After the PR is merged").
2. **Ancestry fallback (offline / no recorded PR).** `git fetch origin` then, if the work
   recorded any branch tip or merge SHA, `git merge-base --is-ancestor <work-sha> origin/master`
   (verified: `git merge-base --is-ancestor HEAD origin/master` distinguishes merged vs
   unmerged tips). If no SHA is recorded, signal (i) is treated as **unknown → fail**
   (conservative: not offered).

> **Conservative default.** If neither check can be evaluated (no PR recorded, no SHA, fetch
> denied), signal (i) = **fail** → the folder is **not offered** (FR4 "(i) fail → not offered
> (not merged ⇒ not safe)"). Cleanup never *guesses* a folder is mergeable.
>
> **No-`STATE.md` work folder (e.g. a stray `work-*` like `work-002-canonical-generator`
> created with only a tool report and no `STATE.md`).** Signal (i)'s PR/SHA reads and signal
> (ii)'s status read all depend on `STATE.md`; with none present, both are unevaluable →
> signal (i) = **unknown → fail** → the folder is **not offered** as a Tier-1 work folder.
> (Such a folder's *contents* may still be swept as Tier-0/Tier-2 individual items if they
> match S1–S5 — e.g. the stray report inside it — but the folder is never auto-offered for
> wholesale deletion.)

#### Signal (ii) — STATE.md concluded (secondary confirmation)

Read the work-area `STATE.md` top blockquote `> **Status:**` enum and the `## Deploy Status`
table (`canonical/templates/work-state-template.md` line 3 enum:
`Interview Complete | Specifying | Planning | Detailing | Executing | Deployed`; line 87
`## Deploy Status`). Signal (ii) **passes** iff `> **Status:** Deployed` AND at least one
`## Deploy Status` row reads a terminal state (a non-empty `PR` + `State` indicating merge,
e.g. `Merged`/`Deployed`). Otherwise (ii) **fails** — the folder still claims in-flight work.

#### Decision matrix

| (i) merged-to-master | (ii) STATE concluded | Action | Rationale |
|----------------------|----------------------|--------|-----------|
| ✓ pass | ✓ pass | **Offer, unchecked** (Tier-1, `review`) | both signals agree; safe to delete but never auto-checked (AC7) |
| ✓ pass | ✗ fail | **Do NOT auto-offer; explicit-confirm prompt** surfacing *why (ii) disagrees* (e.g. "Status is `Executing`, no merged Deploy row, but PR #44 is MERGED") | (i) is the necessary signal; (ii) disagreement is a discrepancy the human must adjudicate (FR4) |
| ✗ fail | (any) | **Not offered** | not merged ⇒ not safe (FR4, NFR1) |
| — currently-active folder — | — | **Never offered** (excluded before (i)/(ii)) | absolute rule (FR4, NFR1, AC7) |

The `(i)✓/(ii)✗` row is the only path that can present a work folder to an *explicit* extra
prompt; it is still **unchecked** and requires a per-item confirmation distinct from the
Tier-0 sweep — surfaced via `AskUserQuestion` (see *Checklist UI*).

#### The currently-active work folder — never offered (concrete rule)

The active folder is resolved **conservatively, by union of three cheap checks** (offered for
deletion only if NONE match):

(a) **The housekeep run's own work context** — the `.aid/work-*/` whose `STATE.md` carries the
`## Housekeep Status` block this run wrote (feature-001 § C-1: run-state lives in the
work-area `STATE.md`). This is the safest, primary rule: housekeep *cannot* sweep the folder
it is currently running inside.
(b) **The folder matching the current branch** — if the current branch is
`aid/work-<NNN>-*` or its `## Deploy Status` shows no merged PR, the matching `work-NNN-*` is
active. (Verified: current branch is `aid/work-001-aid-housekeep`.)
(c) **Any folder whose `STATE.md` `> **Status:**` is not `Deployed`** is in-progress and never
offered regardless of (i) (this is just (ii)-fail ⇒ matrix row 3, restated for the active case).

> **Scope of the active-folder guarantee (precise):** rule (a) is a **structural guarantee
> when housekeep runs inside a work-folder context** — i.e. when the run wrote its
> `## Housekeep Status` block into some `.aid/work-*/STATE.md`, that folder always matches (a)
> and can never be offered. feature-001 PREFLIGHT, however, also accepts a **repo-root**
> context, and `--cleanup-only` (resume row 2) can run with **no active work folder** at all;
> in those cases (a) matches nothing and (b) does not match (housekeep runs on
> `aid/housekeep-*`, not `aid/work-NNN-*`). The exclusion floor for those runs is therefore
> **(c) + signal-(i)-fail**: any folder that is not provably merged (signal (i) defaults to
> *fail* on every unevaluable case — see the (i) blockquote above) is simply **not offered**.
> So the *safety* (no active/unmerged folder is ever auto-offered) holds in all entry modes,
> but the absolute "cannot run" framing applies specifically to the work-folder-context run.

### Checklist UI (AC7, NFR1, NFR3)

The CLEANUP body presents the candidate list and acts only on per-item confirmation. It
mirrors the established **propose→confirm** interaction of `/aid-discover`'s doc-set
(`canonical/skills/aid-discover/references/state-generate.md` lines 87–106: "Display … as a
diff … Then ask the user to confirm or edit") and uses the host **`AskUserQuestion`** tool
(in `allowed-tools` per feature-001's `SKILL.md`; precedent: `aid-summarize`
`references/state-manual-checklist.md`, `state-approval.md`).

Flow:
1. **Render the checklist** grouped by tier, each row `[x] path — reason` (Tier-0 pre-checked)
   / `[ ] path — review: reason` (Tier-1/2 unchecked). Untracked vs tracked is annotated
   (`(untracked)` / `(git rm)`) so the user sees the deletion mechanism per item (NFR3).
2. **The user toggles** items (check/uncheck) and confirms the final selection. No item is
   removed without appearing checked at confirm time (NFR1).
3. **`(i)✓/(ii)✗` work folders** are NOT in the togglable list; each gets its own
   `AskUserQuestion` explicit-confirm prompt that *states the discrepancy* before it may be
   added to the deletion set.
4. **Confirm gate.** Only the final checked set is deleted. If the user unchecks everything
   (or cancels), nothing is deleted — see *Gate Output / Cancel-All*.

No silent deletions (NFR1, NFR3): the checklist is always shown before any `rm`/`git rm`.

### Deletion Mechanism (AC8) — the tracked/untracked split

Each confirmed candidate is classified tracked-vs-untracked and removed accordingly; both
mechanisms stage into the **single per-stage commit** made by feature-001's
`canonical/scripts/housekeep/branch-commit.sh`. **No trash directory** (FR4: "No separate
trash directory — it would itself become crud").

| Classification test (deterministic) | Result | Deletion command | Recoverability |
|--------------------------------------|--------|------------------|----------------|
| `git ls-files --error-unmatch <path>` succeeds (or `git ls-files <path>` non-empty) | **tracked** | `git rm -r <path>` (staged) | recoverable from git history (NFR1, AC8) |
| `git check-ignore -q <path>` succeeds, OR `git ls-files <path>` empty | **untracked** | plain `rm -rf <path>` | not in history (was never committed) |

Verified split for this repo's live candidates:
- `.aid/.temp/` → `git check-ignore .aid/.temp` matches, `git ls-files` empty → **untracked → `rm`**.
- `.aid/.heartbeat/` → gitignored → **untracked → `rm`**.
- `.aid/work-*/` folders → `git ls-files` count 0 *currently* (not yet committed on this
  branch) but NOT gitignored (`git check-ignore .aid/work-001-aid-housekeep` → not ignored);
  once a work folder has committed deliverables it is **tracked → `git rm -r`**. The
  classification is computed **at cleanup time per path**, so a folder is `git rm`'d iff git
  actually tracks it then, else `rm`'d — the test, not an assumption, decides.
- stray `verify-deterministic-report.json` (S4) → if it ever appears in `.aid/work-002-*`,
  classify at scan time: tracked → `git rm`, untracked → `rm`.

**Sequence inside CLEANUP:**
1. Partition confirmed candidates into `to_git_rm[]` and `to_rm[]` (the table above).
2. `rm -rf` each `to_rm` path; `git rm -r --quiet` each `to_git_rm` path (staging deletions).
3. Hand off to `branch-commit.sh` for the single commit (e.g.
   `chore(housekeep): cleanup stale .aid artifacts [feature-004]`), one commit, **never push**
   (feature-001 § Git/VC Boundary; C3; NFR1). `branch-commit.sh` already ensures the
   `aid/housekeep-*` branch and contains no `git push`.

### D2 Coordination (already-applied `report_path=None` fix)

The recurring `verify-deterministic-report.json` crud (REQUIREMENTS.md D2;
KB Q&A recorded at `.aid/knowledge/STATE.md` lines ~215, the `report_path=None` resolution)
is **already fixed at the primary source**: `run_generator.py` now calls
`run_verify(str(repo))` (line 76) and `run_advisory(str(repo))` (line 84) **without** a
`report_path`, and `.claude/skills/aid-generate/scripts/verify_deterministic.py:364-368` /
`.claude/skills/aid-generate/scripts/verify_advisory.py:216-220` skip the
JSON write when `report_path` is `None` (verified). Cleanup **does not touch
`run_generator.py`** and does not re-litigate that fix.

However, the report can still be emitted via **other invocation paths** — the standalone CLI
default still writes it (`.claude/skills/aid-generate/scripts/verify_deterministic.py:390-391`
`--report-path` default `.aid/work-002-canonical-generator/verify-deterministic-report.json`),
and the D2 Q&A notes
"investigate later if there are more … files … being generated." So cleanup **still targets
the stray report** as an S4 Tier-0-safe candidate (it reappeared this session per the task
brief). The two mechanisms are complementary: the fix stops the *common* path; cleanup sweeps
*any residual* the way FR4 intends. No conflict.

### Gate Output (`**Cleanup Stage:** passed`) and Cancel-All behavior

On completion, CLEANUP writes `**Cleanup Stage:** passed` to the work-area
`## Housekeep Status` block via `canonical/scripts/housekeep/housekeep-state.sh`, then CHAINs
to DONE (feature-001 § Feature Flow / Dispatch; the field enum is `passed | —`, cleanup being
the terminal stage). The stage is "passed" = **the cleanup step RAN to a user-resolved
conclusion**, not "files were deleted":

| Outcome | Items deleted | Commit made | `**Cleanup Stage:**` | Rationale |
|---------|---------------|-------------|----------------------|-----------|
| User confirmed ≥1 item | yes | one commit via `branch-commit.sh` | `passed` | normal sweep |
| User unchecked everything / cancelled | none | **no commit** (nothing staged) | `passed` | the stage *ran*; the empty result is a valid no-op outcome the user chose (NFR1 — never delete without confirm; NFR2 — idempotent no-op) |
| Scan found zero candidates | none | no commit | `passed` | nothing stale — clean state (NFR2 "nothing to do") |

Cancel-all is therefore **`passed` with no commit** — it is a deliberate "I reviewed, deleted
nothing" outcome, consistent with NFR1/NFR2. It is NOT `stalled` (stalled is reserved for
gates that *cannot* pass — feature-001 § Sequencing; cleanup always *can* conclude). This
keeps a re-run from re-prompting (resume table row 6 "nothing to resume").

### `--cleanup-only` Entry (AC10) — no KB/summary assumptions

When reached via `--cleanup-only` (feature-001 resume table row 2: PREFLIGHT → CLEANUP,
`**Mode:** cleanup-only`, KB/Summary rows left `—`), the CLEANUP body MUST NOT read or assume
any KB-delta or summary run-state. Its inputs are only: the filesystem scan (S1–S6), git
(`ls-files`/`check-ignore`/`merge-base`), `gh` (signal (i) PR check), and each work folder's
own `STATE.md`. It does **not** read any `**Summary Stage:**` field (nor any
`**Approved-At-Commit:**` — that field was removed in the agent-driven pivot). The only `## Housekeep Status` field it
reads is its own gate predecessor check (handled by feature-001's gate logic, which for
cleanup-only is satisfied by the deliberate Mode=cleanup-only path — feature-001 § Resume,
"a deliberate cleanup-only run does not violate C1"). This guarantees `--cleanup-only` works on
a repo where KB/summary state was never written.

### Sequencing constraint honored (C1)

Per feature-001 § Sequencing, CLEANUP may begin only when the upstream `**Summary Stage:**`
reads `passed` or `skipped` (full sequence) OR `**Mode:** cleanup-only` (deliberate skip).
This gate is enforced by feature-001's `housekeep-state.sh` resume logic; this feature's body
assumes it has already been satisfied by the time CLEANUP's body executes and does not
re-implement the gate.

### Testing (NFR5) — classification + safety test suite

This feature owns the deterministic-logic suite for cleanup, authored under
`tests/canonical/` and **auto-discovered** by the `tests/canonical/test-*.sh` glob in
`tests/run-all.sh` (lines 32–33 `suites=( tests/canonical/test-*.sh )`; runs each under
`timeout 300`, sources `tests/lib/assert.sh`) — **no edit to `run-all.sh`** (it discovers by
glob, per its line 7 comment). Style mirrors the existing 18 suites
(`.aid/knowledge/test-landscape.md`); helpers from `tests/lib/assert.sh`
(`assert_eq`, `assert_output_contains`, `assert_file_exists`, etc.).

- `tests/canonical/test-housekeep-classify.sh` — the **tier-assignment** logic against a
  fixture `.aid/` tree (temp dir): asserts S1/S2/S3 → Tier-0 checked; a loose hand-authored
  `.aid/foo.md` → Tier-2 unchecked; an unregistered `.aid/generated/x.json` → Tier-0,
  a *registered* generated file → NOT a candidate.
- `tests/canonical/test-housekeep-workfolder-safety.sh` — the **(i)/(ii) decision matrix**
  against git + `STATE.md` fixtures: builds a throwaway git repo with a fake `origin/master`,
  asserts the four matrix rows ((i)✓(ii)✓ → offer-unchecked; (i)✓(ii)✗ → explicit-confirm
  flag; (i)✗ → not-offered; active-folder → never-offered). Signal (i) is tested via the
  ancestry fallback (`git merge-base --is-ancestor`) so it runs without network/`gh`; the
  `gh`-PR path is guarded `command -v gh` → SKIP if absent (the established node/pwsh-skip
  model per `tech-debt.md` "ps1 setup parity … pwsh-skips" and `test-landscape.md`).
- `tests/canonical/test-housekeep-deletion-split.sh` — the **tracked/untracked split**: in a
  throwaway git repo with a `.gitignore`, asserts `git ls-files`/`git check-ignore`
  classification routes a committed path → `git rm` and an ignored path → `rm`, and that no
  `git push` is invoked (assert no remote interaction).

So that the deterministic logic is testable, the scan/classify/matrix/split MUST be
implemented as a **scriptable helper** (e.g. `canonical/scripts/housekeep/cleanup-classify.sh`,
sibling to feature-001's `housekeep-state.sh` / `branch-commit.sh` under
`canonical/scripts/housekeep/`), invoked by `references/state-cleanup.md`, rather than as prose
the model interprets — matching the "deterministic logic lives in a tested bash helper"
pattern of `canonical/scripts/summarize/stale-check.sh` (feature-001 § Layers).

### Sections marked N/A (this domain)

- **API Contracts** — N/A: AID ships no HTTP/RPC services (`.aid/knowledge/pipeline-contracts.md`
  § "AID ships no HTTP services or RPC endpoints"). Cleanup's contract is its CLEANUP-state
  body + the `**Cleanup Stage:**` gate field + the `cleanup-classify.sh` CLI.
- **UI Specs (web) / Mobile Specs** — N/A: no web/mobile surface; the only "UI" is the
  chat-side checklist via `AskUserQuestion` (covered under *Checklist UI*).
- **Events & Messaging** — N/A: hand-offs are filesystem state, not a broker
  (`.aid/knowledge/integration-map.md` "filesystem state hand-offs").
- **Migration Plan / Cache Strategy / Search-Indexing / Telemetry / Cloud / Hardware** — N/A:
  no runtime infrastructure (`.aid/knowledge/infrastructure.md` § "no conventional runtime
  infrastructure").
- **Distribution** — owned by feature-001 (the whole `aid-housekeep/` folder auto-renders);
  this feature's `references/state-cleanup.md` body + `cleanup-classify.sh` ride along with no
  renderer edit (feature-001 § Distribution).

### Cross-feature contracts honored (feature-001)

- Writes `**Cleanup Stage:** passed` to `## Housekeep Status` via `housekeep-state.sh` (the
  field/enum defined in feature-001 § C-2).
- Commits via `canonical/scripts/housekeep/branch-commit.sh` — exactly **one** commit, on the
  `aid/housekeep-*` branch, **never push**, never `master` (C3, NFR1; feature-001 § Git/VC).
- Authors the body of `canonical/skills/aid-housekeep/references/state-cleanup.md` (the stub +
  interface declared by feature-001 § Layers / Cross-feature contracts) plus the
  `cleanup-classify.sh` helper and the three test suites above.
- Reachable after SUMMARY-DELTA (gate: `**Summary Stage:**` passed/skipped) and directly via
  `--cleanup-only` (Mode=cleanup-only) — no KB/summary state assumed.
