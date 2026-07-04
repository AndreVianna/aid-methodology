# Work State -- work-008-build-index-perf

> **State:** Executing
> **Phase:** Execute
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill execute --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-07-04
> **User Approved:** yes

Scoped, user-approved lite bug-fix (v2.0.2): eliminate the per-file subprocess fork in
`build-project-index.sh` that the work-007 #7 adopter measured at ~1-2 min on ~1400 files.
Sibling to the work-007 harvest fix (shipped v2.0.1); same anti-pattern class.

---

## Pipeline State

- **Lifecycle:** Running
- **Phase:** Execute
- **Active Skill:** none (direct-prompt fix)
- **Updated:** 2026-07-04

---

## Triage

- **Path:** lite
- **Work Type:** bug-fix
- **Sub-path:** LITE-BUG-FIX
- **Decision rationale:** Single per-file-fork perf defect in a shipped KB helper; no new surface.
- **Override:** no
- **Recipe:** none

---

## Root cause (evidence)

`build-project-index.sh:249` runs `lang=$(detect_lang "$path")` inside the per-file loop
that builds FILES_DATA. `$( )` is a COMMAND SUBSTITUTION -> it forks a subshell for EVERY
file, on the GNU/Windows fast path (NOT just the BSD fallback, as work-007's RC3 wrongly
assumed). On ~1400 files under Windows Git Bash / MSYS (~0.5-1.8s/spawn) that is ~1400 forks
-> the adopter's measured ~1-2 min. It never HANGS (linear; no backtracking), so it wasn't
the critical bug -- but it is the same anti-pattern the work-007 ticket flagged for
"the same batched-pass treatment."

Correction to work-007 STATE RC3: build-project-index DOES have a per-file fork on the
Windows/GNU path (the `$(detect_lang ...)` command substitution), re-confirmed by reading
line 249 + the adopter's measurement.

---

## Fix

Move language detection into the single awk pass that already joins line-counts + mtime into
FILES_DATA (port detect_lang's ext->name mapping to an awk function; look up line-counts from
LINE_COUNTS in awk). Zero per-file spawns. Byte-identical FILES_DATA (same ext->lang mapping,
same TMP order, same line-count lookup) -> byte-identical project-index.md. Remove the now-dead
bash `detect_lang` function. BSD-fallback `get_mtime` per-file loop left unchanged (macOS forks
cheaply; untestable here -- validate-the-premise).

## Acceptance

byte-identical project-index.md (old vs new, modulo Generated date) on a fixture; large-repo
time drops from ~1-2 min to seconds; `bash -n` clean; regenerate 5 profiles (VERIFY pass, drift
= build-index only); resync dogfood `.claude/` (work-007 lesson); version 2.0.1 -> 2.0.2 across
VERSION + npm + pypi; release via merge -> dry-run -> tag v2.0.2.

---

## Lifecycle History

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-04 | Work created | -- | Lite perf fix; from work-007 #7 adopter feedback (build-index ~1-2 min); RC3 corrected (per-file fork is on the GNU/Windows path, not BSD-only) |
| 2026-07-04 | Implemented + verified | -- | Batched lang detection into the FILES_DATA awk pass; removed dead bash detect_lang. Byte-identical output old==new (canonical/ fixture); OLD 1m15s → NEW 12s on ~280 files (fork storm gone; remainder is inherent file-read I/O). test-build-kb-index 40/40, test-dogfood-byte-identity 571/571, render-drift clean, version-sync 2.0.2. 5 profiles regenerated + dogfood .claude/ + .aid markers resynced/bumped. Ready for PR → v2.0.2. |
