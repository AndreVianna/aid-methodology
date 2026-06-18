# task-007: Root-agent in-place region update + migration, no .aid-new (bash)

**Type:** IMPLEMENT

**Source:** work-003-content-isolation → delivery-001

**Depends on:** task-006

**Scope:**
- Rewrite `_copy_root_agent_file` in `lib/aid-install-core.sh` to update ONLY the `<!-- AID:BEGIN -->`..`<!-- AID:END -->` region in place, preserving everything outside verbatim, and to eliminate the `.aid-new` fallback entirely (no backup/sidecar file under any branch, including non-`--force` divergence).
- Algorithm: dst absent → write full source (markers included); dst has markers → replace only the marked region with the source's marked region; dst has no markers → migrate.
- Migration (marker-less dst): if dst still matches the AID-recorded sha (manifest `root_agent_files`) → clean rewrite to full marked source; else excise the known AID-managed sections (`## Knowledge Base`, `## Review output format`, `## Permissions`) and re-insert them wrapped in markers in place, preserving `## Project`/`## Project Overview` and other user content. Never write a backup file.
- Heading match for the excise is by normalized STEM, not exact string: the committed source heading is `## Review output format (global)` (not `## Review output format`), so match the heading stem and tolerate a trailing parenthetical suffix (e.g. ` (global)`). Use the same matching rule task-008 will mirror in PS.
- Keep `bin/aid` ASCII-only.

**Acceptance Criteria:**
- [ ] Dst with markers + user edits outside markers → only the marked region is replaced; outside content preserved byte-for-byte.
- [ ] No `.aid-new` (or any sidecar/backup) is ever written, including the prior non-`--force` divergence path.
- [ ] Marker-less dst matching the recorded sha → cleanly rewritten to the full marked source.
- [ ] Marker-less dst NOT matching the recorded sha → AID sections excised and re-wrapped in markers in place; `## Project`/`## Project Overview` and user content preserved; no backup file. The excise matches `## Review output format (global)` via stem/prefix matching (NOT exact `## Review output format`), so the live heading is found.
- [ ] `bin/aid` and `lib/aid-install-core.sh` remain ASCII-only; the change is parity-ready for task-008.
- [ ] All §6 quality gates pass.
