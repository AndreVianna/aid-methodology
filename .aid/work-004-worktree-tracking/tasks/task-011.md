# task-011: Reader (Python) — same-work reconcile (no winner)

**Type:** IMPLEMENT

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-009, task-010

**Scope:**
- Implement the same-work merge in the Python reader: when one `work_id` appears across N worktree/main roots, union into a single work model:
  - per task → most-advanced `State` using the SD-2 ordering `Done > In Review > In Progress > Blocked > Failed > Pending` (Canceled ranked just below Done);
  - work-level `## Pipeline State` → the copy with the newest `Updated:` timestamp; **on a timestamp TIE, break deterministically by a stable secondary key** (branch-label lexical sort, main root sorting first) so the result is order-independent regardless of root enumeration order;
  - derived views (Tasks State, gates, findings, dispatch logs) → union of all roots' contributions.
- Encode the SD-2 ordering as a single ordered list/rank map (the authoritative source from task-001); the Node twin (task-012) must use an identical rank map.
- The merged model retains per-branch provenance where the model already carries labels (so the dashboard can show which branch a contribution came from), without inventing new schema beyond what is needed.

**Acceptance Criteria:**
- [ ] A `work_id` present on N roots merges into one model: per-task most-advanced State by SD-2; Pipeline State by newest `Updated:`; derived views unioned.
- [ ] The SD-2 ordering is encoded once as a rank map and matches the authoritative task-001 list.
- [ ] No "winner" is picked at the work level — the result is the union; merge is deterministic and order-independent, INCLUDING equal-`Updated:` ties (broken by the stable branch-label secondary key, main first).
- [ ] Read-only; never throws.
- [ ] All §6 quality gates pass.
