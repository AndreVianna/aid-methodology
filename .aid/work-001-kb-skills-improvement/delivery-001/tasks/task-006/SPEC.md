# task-006: harvest-coined-terms.sh + denylist + candidate-concepts output

**Type:** IMPLEMENT

**Source:** work-001-kb-skills-improvement -> delivery-001

**Depends on:** task-002

**Scope:**
- Author `canonical/aid/scripts/kb/harvest-coined-terms.sh`: the deterministic (no LLM) coined-term
  harvest. Extraction classes E1-E5 (identifiers / CamelCase / snake-kebab / capitalized multi-word
  phrases / quoted strings); the 5 channels (code / docs / config / comments / history) with the
  git-log history channel degrading to empty on a non-git tree and accepting a `--history-file` arg;
  the phrase-survival denylist filter (a candidate survives iff >= 1 component word is NOT in the
  denylist, plus the whole-phrase escape for all-common-word phrases that recur cross-source -- the
  'Relative bus' mechanism); the salience ranking `freq * (1 + 2*(spread-1))` with deterministic
  tie-break (spread desc, then term asc); emit top `--top` (default 60) PLUS every candidate with
  spread >= 3. Reuse `build-project-index.sh`'s prune set + absolute-OUTPUT-before-cd resolution
  (copied, kept in lockstep). Flags: `--root` / `--output` / `--denylist` / `--top` / `--history-file`.
- Emit `.aid/generated/candidate-concepts.md` with the documented columns including the `Source`
  column (`harvest`) and the `Example source` grep-recoverable anchor (the file is later joined by
  task-011's `synthesis`-tagged rows). Emit a `## Summary` section at the foot of the file that
  reports the `Cross-source (spread >= 2)` count (the number of candidates appearing in >= 2 of the
  5 channels) -- the field delivery-004's `recon-classify.sh` RM4 parses to drive path triage.
- Ship `canonical/aid/scripts/kb/coined-term-denylist.txt`: sorted, lowercased, newline-delimited
  ASCII wordlist (common English + common-tech vocabulary); resolves SPIKE-H3 (confirm the trimmed
  seed is 100% ASCII). Support the `.aid/knowledge/.coined-term-denylist.local.txt` project override
  via `comm`-union.
- Add `harvest-coined-terms.sh` + `coined-term-denylist.txt` to the `test-ascii-only.sh` allow-list.
- Edit canonical only; re-run `run_generator.py`; commit regenerated `profiles/`.

**Acceptance Criteria:**
- [ ] `harvest-coined-terms.sh` is deterministic ASCII bash (coreutils + git only; no LLM, no
  embedding model, no python3/pwsh) implementing E1-E5 and the 5 channels.
- [ ] The denylist filter drops a common-tech term (`UserService`), keeps a coined identifier
  (`RelativeBus`), and keeps an all-common-word phrase (`Relative Bus`) that recurs cross-source via
  the phrase-survival + salience floor.
- [ ] Salience = `freq * (1 + 2*(spread-1))`; ranking is stable (tie-break spread desc then term
  asc); top-`N` plus every spread>=3 candidate is emitted (cross-source concepts never truncated).
- [ ] The history channel degrades to empty on a non-git tree without error and accepts
  `--history-file`; absolute-OUTPUT-before-cd resolution matches `build-project-index.sh`.
- [ ] `candidate-concepts.md` is emitted with the documented columns incl. `Source` (= `harvest`)
  and a grep-recoverable `Example source` anchor; a re-run is byte-identical (determinism).
- [ ] `candidate-concepts.md` carries a `## Summary` section reporting the
  `Cross-source (spread >= 2)` count (the field delivery-004's `recon-classify.sh` RM4 consumes).
- [ ] `coined-term-denylist.txt` is sorted/lowercased/100% ASCII; the
  `.coined-term-denylist.local.txt` override `comm`-unions when present.
- [ ] Both new files are on the `test-ascii-only.sh` allow-list and pass the ASCII guard.
- [ ] `run_generator.py` re-run; regenerated `profiles/` committed (render-drift green).
- [ ] All section-6 quality gates pass.
