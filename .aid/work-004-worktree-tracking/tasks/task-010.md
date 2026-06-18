# task-010: Reader (Python) — worktree enumeration (fixed-argv) + degrade + optional verb-guard

**Type:** IMPLEMENT

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-009

**Scope:**
- Extend `dashboard/reader/locator.py` to enumerate persistent worktrees: run read-only `git -C <repo_root> worktree list --porcelain` using the EXISTING fixed-argv / no-shell subprocess pattern (twin of `derivation.py` `_run_git_log`: `subprocess.run(["git", "-C", root, "worktree", "list", "--porcelain"], ...)`, verb hard-coded in argv, no shell). Parse `worktree <path>` + `branch refs/heads/<branch>` records, and for each worktree path locate its `.aid/` and enumerate `work-*` folders. Emit a list of `(branch_label, aid_dir)` roots (the main root always included). Relax the `:1-7` "stat+iterdir only" contract comment to "stat+iterdir + read-only `git worktree list`".
- Reuse the 2 s timeout + the DD-A2 degradation pattern: if git missing / non-git / timeout / parse failure → fall back to the main root only. Never throws. Safety rests on the fixed-argv pattern, NOT on a verb allow-list.
- **Allow-list (corrects a false premise; OPTIONAL hardening).** Python's `_GIT_ALLOWED_VERBS` (`derivation.py:101`) is DEFINED but NEVER referenced/enforced — purely documentary. The worktree call does NOT require it. IF the team wants a verb-guard as defense-in-depth, this task must make it REAL: actually enforce `_GIT_ALLOWED_VERBS` at the git call site(s) and add `worktree` (alongside `rev-parse`/`symbolic-ref`/`log`). Do NOT write an AC that assumes the guard already exists. If hardening is deferred, drop the allow-list ACs and rely on the fixed-argv pattern.
- Wire `read_repo` to read each `(branch_label, aid_dir)` root and tag each work model with its branch label (server layer unchanged). Merge across roots is task-011.

**Acceptance Criteria:**
- [ ] The locator enumerates worktrees via `git -C <root> worktree list --porcelain` using the fixed-argv / no-shell pattern and returns per-worktree `(branch_label, aid_dir)` roots including main.
- [ ] The subprocess is read-only (verb hard-coded in argv), 2 s-bounded, and degrades to main-root-only on any failure mode (git missing / non-git / timeout / parse failure).
- [ ] (IF hardening adopted) `_GIT_ALLOWED_VERBS` is actually ENFORCED at the git call site and includes `worktree`; otherwise no allow-list claim is made.
- [ ] read_repo reads each root and labels work models by branch; the server interface is unchanged.
- [ ] Read-only; never throws.
- [ ] All §6 quality gates pass.
