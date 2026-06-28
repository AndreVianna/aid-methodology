# task-036: Re-derived blast-radius inventory + final references/ partition

**Type:** DOCUMENT

**Source:** work-001-aid-interview-improvements -> delivery-006

**Depends on:** -- (none)

**Scope:**
- Produce the authoritative split-execution inventory that tasks 037/038/039 consume, RE-DERIVED
  against the THEN-current tree (after delivery-003/004/005 have merged their in-place edits to
  `canonical/skills/aid-interview/`), per the delivery SPEC note. The feature SPEC's blast-radius
  tables were computed against today's tree; this task refreshes them against the actual post-content
  file set before any file is moved. It authors no skill content and moves no files.
- **(A) Final `references/` partition.** Enumerate the THEN-current
  `canonical/skills/aid-interview/references/*.md` set and assign each file to `aid-describe` or
  `aid-define` by the State-Partition RULE (conversational intent-gathering / triage / full-path
  interview / COMPLETION+KB-hydration / the entire lite path + the feature-002 engine docs
  (`elicitation-engine.md` / `move-playbook.md` / `calibration.md` / `advisor-stance.md`) + the
  feature-003 seed-authoring state -> `aid-describe`; approved-REQUIREMENTS -> feature folders, i.e.
  the 6 define refs `state-feature-decomposition.md`, `feature-decomposition.md`,
  `state-cross-reference.md`, `cross-reference.md`, `reviewer-brief.md`, `state-done.md` ->
  `aid-define`). Flag any file 002/003/004 added/renamed that the SPEC table did not anticipate and
  classify it by the RULE (not a frozen list). Confirm the 6 define refs are present and unchanged by
  the content work.
- **(B) External surface set (the sweep target list).** Refresh the affected-surface inventory
  (calling agents, recipes + recipe tooling, templates, other canonical skills, root `README.md`,
  `examples/`, dashboard `home.html` + vendored copy + paired test + `derivation.py`, docs-site
  source + hand-authored pages, legacy `docs/`, `tests/canonical/` fixtures) by running a
  boundary-aware `grep -rn` for live `/aid-interview` command tokens and `skills/aid-interview/` path
  tokens over the shipped/canonical surface set; list each hit as a sweep target with its intended
  new owner (`/aid-describe` for intake/triage/lite/interview/COMPLETION; `/aid-define` for
  decomposition/cross-reference/DONE). Confirm the explicitly out-of-scope surfaces (`.aid/knowledge/`,
  `.aid/work-*/`, `.aid/design/`, the frozen dashboard fixtures + `test_feature009.py`) are excluded.
- **(C) Count-surface inventory.** List the in-scope skill-count surfaces that must increment 13->14
  (numeric AND the spelled-out `Thirteen -> Fourteen`) with file:line, per the Skill-Count Delta table,
  re-confirmed against the then-current line numbers. Note the deferred-to-/aid-housekeep dogfood-KB
  count drift as explicitly NOT-in-scope.
- **(D) Substring-guard baseline.** Record the authoritative pre-split `grep -rn "aid-interviewer"`
  file/match count over the shipped/canonical surface set (the SPEC cites ~56 files; capture the exact
  then-current number) so task-040 can assert it is unchanged after the sweep.
- **Out of scope:** moving/renaming any file (task-037); rewriting any token (task-038); rendering
  (task-039); the verification run (task-040).

**Acceptance Criteria:**
- [ ] An inventory artifact is written under `delivery-006/` that lists the THEN-current
  `aid-interview/references/*.md` set with each file assigned to `aid-describe` or `aid-define` by the
  State-Partition RULE; the 6 define refs are explicitly named and confirmed present; any
  002/003/004-added describe-side file is captured and classified. *(gate criterion 1 / AC-1)*
- [ ] The artifact lists every external sweep-target surface (boundary-aware `grep` hits for live
  `/aid-interview` + `skills/aid-interview/` tokens) with its intended new owner command, and names the
  explicitly out-of-scope surfaces that must NOT be swept. *(gate criterion 3 / AC-3)*
- [ ] The artifact enumerates the in-scope 13->14 count surfaces (numeric AND spelled-out
  `Thirteen->Fourteen`) with then-current file:line, and flags the dogfood-KB count drift as deferred
  to `/aid-housekeep`. *(gate criterion 3 / AC-3)*
- [ ] The artifact records the authoritative pre-split `aid-interviewer` baseline file/match count for
  task-040's unchanged-count assertion. *(gate criterion 4 / AC-4)*
- [ ] Accuracy verified against the current (post delivery-003/004/005) codebase -- every listed
  file:line and the partition reflect the actual tree at execute time, not the SPEC's pre-content
  snapshot. *(DOCUMENT default)*
- [ ] All applicable REQUIREMENTS.md §6 quality gates pass.
