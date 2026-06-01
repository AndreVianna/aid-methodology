# task-017: Setup tests (SU16/SU16b/SPS08 + SU12-SU17/SPS05-SPS07) + finalized all-5 non-regression gate (NR1-NR5)

**Type:** TEST

**Source:** feature-004-setup-and-nonregression → delivery-004

**Depends on:** task-015, task-016, task-010, task-014

**Scope:**
- Extend the two committed setup suites and run the all-5-profile non-regression gate per SPEC §"Test Plan", proving both new providers install in lockstep and the whole 5-profile pipeline stays clean while the existing 3 are byte-identical. This is the integration-seam TEST task — no production code; it edits only the test suites and runs/records the gates. Defects route back to task-015/task-016 (setup) or the delivery-002/003 render/profile tasks — do NOT edit `setup.sh`/`setup.ps1`/renderers/profiles to make a test pass. Read the Q-H/Q-B rulings in `provider-mapping.md` (task-004, transitively via the providers' committed trees) to know the Antigravity context filename and whether Copilot ships `mcp-config.json` before asserting installed paths.
- **Extend `tests/canonical/test-setup.sh` (bash, full copy coverage):**
  - **SU12 install Copilot** — `drive "$T" $'4\n6'`; assert exit 0, `$T/.github` created, root `$T/AGENTS.md` created, `Copied:` reported.
  - **SU13 install Antigravity** — `drive "$T" $'5\n6'`; assert exit 0, `$T/.agent` created, the context file (`AGENTS.md`/`GEMINI.md` per the committed `profiles/antigravity/` tree) created.
  - **SU14 new-provider content fidelity** — installed **Copilot/Antigravity** subtree files are byte-identical (`cmp -s`, mirror SU06f) to their `profiles/copilot-cli/`·`profiles/antigravity/` sources. (Existing-3 byte-identity is owned separately by NR3, not this check.)
  - **SU15 out-of-range still rejected** — `drive "$T" $'7\n6'` → `Invalid choice` then `Nothing selected` (Done is now 6).
  - **SU16 multi-select AGENTS.md collision (Option A, non-interactive)** — on a fresh target select two different-content AGENTS.md-writing tools, e.g. `drive "$T" $'2\n4\n6'` (Codex + Copilot). Assert: (a) exit 0 (no hang/EOF — the harness supplies only menu inputs, never an overwrite answer); (b) the `Note: … all install a shared AGENTS.md …` warning line is present and names the survivor; (c) the highest-numbered selected writer (here Copilot, block 4 > Codex block 2, fixed install-block order) reports the `Updated: …/AGENTS.md (… last-writer-wins …)` line — i.e. resolved WITHOUT a `/dev/tty` prompt; (d) `$T/AGENTS.md` is `cmp -s`-identical to the last-installed (highest-numbered selected) tool's source (`profiles/copilot-cli/AGENTS.md` for this selection). Survivor is fixed by block order, not toggle order.
  - **SU16b unexpected single-tool diff still prompts** — single-tool re-install over a manually-edited `$T/AGENTS.md` with NO second AGENTS.md tool selected (so `AGENTS_COLLISION=0`): assert the generic diff-prompt path is preserved (e.g. piping `n` skips, or `--force` updates), proving the guarded branch is scoped to the known collision only.
  - **SU17 idempotent re-install + --force** for a new provider (mirror SU10/SU11): second run = `Up to date`; `--force` over a diff = `Updated`.
  - Update the suite header comment: tools are Claude/Codex/Cursor/Copilot CLI/Antigravity; Done is `6`; menu inputs terminate with `6` not `4`.
- **Extend `tests/canonical/test-setup-ps1.sh` (pwsh; Linux-CI = menu/warning only):**
  - **SPS05 menu lists 5 tools + Done=6** — `drive "$T" "6"` → exit 0, `Nothing selected`; output contains `GitHub Copilot CLI` and `Antigravity`.
  - **SPS06 toggle new tool on+off** — `drive "$T" $'4\n4\n6'` → `Nothing selected`, `$T/.github` absent.
  - **SPS07 out-of-range rejected** — `drive "$T" $'7\n6'` → `Invalid choice`.
  - **SPS08 collision warning parity** — `drive "$T" $'2\n4\n6'` (Codex + Copilot); assert the `Note: … all install a shared AGENTS.md …` warning is in output (the pre-copy block is `Write-Host`-only and runs before the Windows-only copy, so this validates ps1↔sh warning parity on Linux CI without exercising the copy).
- **Run + record the non-regression gate (FR5 → AC5):**
  - **NR1 all-5 render-drift clean** — `python run_generator.py` then `git diff --exit-code -- profiles/` is empty across all five profiles.
  - **NR2 within-run determinism** — `python verify_deterministic.py --self-test --canonical-root .` PASS with all five profiles discovered.
  - **NR3 existing-3 byte-identical (named AC5 assertion)** — `git diff --exit-code -- profiles/claude-code/ profiles/codex/ profiles/cursor/` (trees + `emission-manifest.jsonl`) is empty after a fresh render — adding the two profiles changed zero bytes of the existing three.
  - **NR4 generator self-tests + canonical suites green** — the `generator-selftests` job commands all pass; `bash tests/run-all.sh` passes all suites including the extended `test-setup.sh`/`test-setup-ps1.sh`.
  - **NR5 SHA-pin audit** — every `uses:` in `.github/workflows/test.yml` references a 40-char commit SHA (unchanged; no workflow edit expected).
- Commit the extended suites; record gate results. Do NOT edit the workflow (the gate is data/glob-driven — new profiles and new suites are auto-discovered).

**Acceptance Criteria:**
- [ ] `test-setup.sh` covers SU12–SU17 with the assertions above; SU12/SU13 install the new providers to their committed destinations, SU14 proves byte-identical copy, SU15 proves out-of-range rejection with Done=6 (AC4a/AC4b).
- [ ] SU16 passes: multi-select Codex+Copilot completes exit 0 with no `/dev/tty` hang, prints the shared-`AGENTS.md` warning naming the survivor, the highest-numbered selected writer reports the last-writer-wins `Updated` line, and `$T/AGENTS.md` is byte-identical to that writer's source — the known collision resolved non-interactively (Option A).
- [ ] SU16b passes: a single-tool diff over a manually-edited `AGENTS.md` (no collision) still hits the generic diff-prompt (skip on `n`, update on `--force`), proving the guarded branch is scoped to the known collision only.
- [ ] `test-setup-ps1.sh` covers SPS05–SPS08; SPS08 asserts the collision warning text is emitted by `setup.ps1` on Linux CI, proving ps1↔sh warning parity (AC4 parity invariant).
- [ ] NR1 (`git diff --exit-code -- profiles/` empty after `run_generator.py`) and NR2 (`verify_deterministic --self-test` PASS, all 5 discovered) both green — all five profiles render-drift clean (AC5a).
- [ ] NR3 (`git diff --exit-code -- profiles/{claude-code,codex,cursor}/` empty after a fresh render) green — existing 3 byte-identical, backward-compatible (AC5b).
- [ ] NR4 (`generator-selftests` commands + `bash tests/run-all.sh` all green, incl. the extended setup suites) and NR5 (every `uses:` in `test.yml` is a 40-char SHA) green (AC5a/AC5c).
- [ ] Tests are deterministic; clean setup/teardown (temp dirs, no leftover state); all acceptance criteria from feature-004 SPEC (AC4a/AC4b/AC5a/AC5b/AC5c + the AGENTS.md collision row) are covered. Defects route to task-015/016 or delivery-002/003 tasks, never patched in the suite. All §6 quality gates pass.
