# AID evolution ledger

This is a plain-language record of the changes being made to AID's project and
architecture. It distinguishes changes on the local branch from work still in
progress. A local change is not a release or an approval to retire the current
workflow.

## Direction

- **Plain-agent redesign is a proposal:** the maintainer wants AID to focus on
  project knowledge, one work requirements source and independent whole-result
  verification while agents execute normally. The plan now starts by reusing
  existing KB generation and the grading system, and proposes calibrating
  finding severities against outcomes. It does not approve a rewrite, change
  the grading scale or claim that the new design has been implemented.
- **Opt-in outcome prototype:** a new experimental `aid-outcome` instruction
  connects a single work requirements document, existing KB tools and grading,
  executor self-review and separate whole-result review. An optional small
  coverage checker flags malformed, failed and missing outcome records; it
  cannot verify the evidence, determine reviewer independence or detect a
  requirement omitted from its input. The existing workflows and grade scale
  remain available. The prototype is outside the normal release payload and
  requires an explicit trial.
  Eight WSL coverage tests, the existing 19 grading tests and 23 KB citation
  checks passed; the new tests include an empty-ledger A+ with an unverified
  outcome. An
  independent source review found and verified fixes for test discovery,
  incomplete-result reporting and other compatibility gaps. A subsequent
  offline trial added explicit installation and quarantine-based deactivation,
  an outcome-specific direct state and resume instruction, exclusive document
  creation and changed-document detection. The focused trial suite passed
  16 cases in WSL with its Windows-only junction test skipped; that junction
  case passed natively, along with four other targeted Windows cases. The
  existing work-gate suite passed 94 checks and the direct-state suite passed
  16 tests with one platform skip. The real release bundle and trial
  were installed in a disposable project; state initialization, file protection
  and preservation after deactivation passed there. One approved, bounded Codex
  host-resume diagnostic selected `aid-outcome`, read the requirements and
  preserved their recorded later decision while updating the state. Independent
  review confirmed that narrow result. The fixture lacked a KB; one command
  failed because of that absence, and the event stream did not prove hook
  execution. Available hashes cover the main inputs, not a complete file diff.
  The run reported 198,206 input tokens including 150,016 cached, and 997 output
  tokens; it is not a comparative benchmark or a cost/quality advantage. Full
  live acceptance, KB-generation compatibility and hook enforcement remain
  unverified; no release or default-workflow switch has occurred.
- **Focused reads and KB trial preparation:** the resume trace contained seven
  shell commands and about 56,600 characters of command output; the largest
  response contained about 26,600 characters from the gate, skill, state and
  helper files. Characters are not tokens, so this identifies material to
  investigate rather than a measured cause of the 198,206 input tokens. The
  trial instruction now requests targeted reads without skipping required
  evidence, and its resume reference provides a tested state-writer command.
  A small notes fixture now has an adapted, hand-authored, source-cited KB; it
  explicitly marks an existing pinned-note duplication defect. Existing tests
  pass, the predeclared behavior oracle fails on that defect and passes on a
  fixture-only known-good correction. It checks list contents, add/pin behavior
  and timeouts. The oracle is not proven hidden. Fixture and evidence-snapshot
  checks passed in WSL with a filesystem-mode skip and on Windows with a
  POSIX-only skip; independent review found no remaining focused blocker. The
  snapshot is non-atomic, assumes a quiescent fixture and excludes root Git
  metadata, ownership, ACLs, xattrs and hardlink topology. KB generation itself
  has not been tested here.
- **First source-backed notes task:** the installed trial agent wrote one
  requirements document, read the fixture KB and source, fixed the duplicate
  listing, added tests and updated affected KB pages. Six unit tests and three
  separate acceptance tests passed. Its required independent reviewer could
  not start because Codex reported a thread-store error, so the agent correctly
  stopped with the result unverified. The run reported 346,191 input tokens,
  including 304,640 cached, and 3,170 output tokens; it is one diagnostic, not
  a comparison or proof that the focused-read change reduced costs. The work
  and its installed runtime remain experimental. A later independent reviewer
  in a saved WSL session checked the requirements, code, tests and affected KB
  pages and reported no findings. The reviewer did not run tests in its
  read-only environment; the six unit and three acceptance tests were run
  separately on the same unchanged application, tests and KB. This completes
  the missing review of this small result, not a full workflow benchmark. The
  saved parent session reported 104,455 input tokens including 89,472 cached,
  and 848 output; the child record separately reported 161,416 input including
  134,400 cached, and 824 output. Counter overlap is unknown, so these numbers
  are not combined into a total.
- **Reviewer startup workaround:** the failed notes diagnostic used Codex
  `--ephemeral`, which does not persist session rollout files. A small WSL
  probe in the same isolated home without that flag started an actual
  subagent and received its reply. Future Codex trials that need reviewers
  should use saved sessions in an isolated home and verify the reviewer result.
  A subsequent saved session started the independent notes reviewer. This
  supports the diagnosis but does not prove the cause of other failures.
- **A more direct review path:** the opt-in outcome skill now includes a compact
  brief and guidance for launching a fresh independent reviewer directly when
  the host supports it. The existing whole-result checks, severity scale,
  ledger, safeguards and missing-evidence rules remain. The installer now
  includes the review reference; it does not supply a new host launcher.
  In one small paired WSL case, both approaches found the same three planted
  behavior and KB issues. The direct reviewer used 139,456 input tokens
  (108,672 cached); the baseline reviewer used 137,202 (102,144 cached), plus
  a separate coordinator reporting 126,174 (110,592 cached). Counter overlap
  is unknown, so these are not summed and no percentage or dollar saving is
  claimed. The direct reviewer still read full methodology files, and the test
  output exposed two defects to both reviewers. This one case is not proof of
  equal review quality in general or of reduced reviewer input. Independent
  source review found one overstatement about saved sessions; the guidance now
  calls it a tested workaround and requires checking reviewer startup.
- **Keep the useful parts of AID:** project-specific knowledge, a way to keep
  complex work on track, and independent review of the whole result.
- **Reduce ceremony:** a small, low-risk change should take a direct path;
  larger or riskier work may need a plan and explicit approvals.
- **Judge the result with evidence:** use real tests and hidden checks, and
  compare the work with plain agent runs. Do not treat an unfinished or failed
  run as a pass.

## Changes already on the local branch

- **Less always-loaded material:** the foundation shortened the shared rules,
  introduced a one-page project card and combined kind-specific skill variants
  into family skills. The earlier foundation measurements showed a reduction
  in starting context; they did not establish that full tasks were cheap.
- **A lean entry point alongside the existing skills:**
  [`aid-change`](../canonical/skills/aid-change/SKILL.md) sizes work and routes
  it to a direct or planned path. The existing skills have not been retired.
- **Explicit verification:** lean work retains a failing test for a bug,
  checks against the starting state, and independent review against the
  request and repository. Planned work also has a goal card and separate
  acceptance tests. The change helpers are under
  [`canonical/aid/scripts/change`](../canonical/aid/scripts/change).
- **Benchmarking against plain work:** the measurement drivers run the same
  notes scenarios with and without AID and grade the results with hidden
  checks. Earlier site comparisons and their limitations remain preserved. A
  lean Codex site comparison used the earlier site commit. Its safeguard test
  passed, but the first three task turns repeatedly requested hook trust and
  did not change the site; the driver mislabeled that attempt finished. The
  preserved session resumed after receiving the verified trust result and
  finished the local task. This was Codex rather than the earlier Claude
  models, and its site dependencies were prepared separately.
- **Site-trial result:** an independent build produced 68 pages and the site's
  nine remaining tests passed. Browser grading found visible raw Markdown table
  separators on seven pages; the earlier plain result had them on ten pages
  and the full-AID result had none in the saved re-grade. The same search-button
  accessibility warning appears across all three re-grades. The lean run's own
  generated-HTML check and review had passed without finding the visible table
  defects. The lean result's
  skill pages largely contain headings and source links, and 49 existing test
  files were deleted; some tested removed machinery, but the incomplete old
  test baseline means coverage preservation is not established. The new
  compact-state initializer was not exercised: this run reused an existing
  work record. No site changes were published or merged.
- **Site grading and installation checks:** the site grader was extended to
  inspect rendered table text, and local installation/resync handling was
  corrected for the observed Windows path and checksum issues. These checks
  improve the evidence available for a site evaluation; they do not mean a
  new site benchmark has been approved or accepted.

## Changes currently being developed

- **Connect project knowledge to the result:** the lean site run read the
  project card and searched the KB. One retrieved KB entry said users should be
  able to follow skill steps without opening source, yet the replacement pages
  mainly listed headings and links. Its acceptance test checked for an absent
  warning, rather than demonstrating the workflow was explained. A separate KB
  rule required visual review, but the saved main-agent searches did not return
  that rule and the run reported browser checks unavailable. These facts do not
  establish a single cause or what every helper knew. The lean instructions now
  carry relevant KB facts and rules into outcome checks, require positive checks
  that reject plausible incomplete results, and review replaced behavior against
  user needs. A required outcome without evidence stays unverified and cannot
  be reported complete. Independent review caught and helped fix this missing
  completion gate and an accidental plan requirement for direct work. Instruction
  tests and review cannot prove that a live agent will follow this; no fresh model
  benchmark has been run. The updated skill and review references have been
  resynced into the local Claude and Codex skill mirrors; a disposable rehearsal
  and the local install both matched the canonical text. The resync also updated
  the related in-progress direct-state and safeguard runtime files. Existing
  Python bytecode was excluded from the staged bundle and was not installed.
- **More specific whole-result review:** for site and documentation changes,
  the lean reviewer now checks the built pages for visible broken table
  formatting and compares changed instructional content with its earlier
  version, the request and current source. Headings and links alone do not
  demonstrate that a workflow is explained. Missing browser coverage must be
  reported as unverified; intentionally removed material is not automatically
  a defect. An independent review checked the guidance against the saved site
  evidence, and the lean change suite passed in WSL. The new check verifies
  the instructions, not reviewer behavior. This is review guidance, not an
  automatic guarantee: a fresh end-to-end benchmark is still needed to show
  whether an agent follows it and catches the defects. The local installed
  skills now contain this guidance. The current Codex session read the
  installed instructions and used them on a real follow-up: fixing four
  independently reviewed problems in the new probe. Three behavior tests failed
  before the code fixes and passed afterwards; a separate reviewer verified all
  four fixes. This is one in-session check, not a fresh-session comparison or
  proof of consistent agent compliance.
- **A smaller quality probe is being prepared:** a disposable release-guide
  task supplies a relevant KB fact and asks for useful, readable documentation.
  Its independent static grader checks the ordered commands, a table with data,
  visible-by-markup table separators, and preservation of the release tool.
  Browser presentation, actual usefulness, and whether the agent used the KB
  require separate evidence; the comparison procedure says so. This probe does
  not replace the earlier site benchmark. Its grader and protocol were reviewed,
  and six offline tests passed. One matched pair has now been run with the previous and updated
  instructions. Both generated guides passed all five partial static checks,
  one unit test each, and an independent browser rendering check at desktop and
  mobile widths. Neither completed the whole workflow: the previous run timed
  out during review; the updated run reported that its own browser verification
  was unavailable and left the work incomplete. The previous guide gives a
  more detailed walkthrough and separate command blocks. Both mobile tables
  split command names across lines, and the updated guide relies on that table
  for commands. This single pair does not establish a general quality advantage
  or prove consistent use of the guidance.
  The previous main session recorded at least 704,733 input tokens (633,856
  cached) and 4,836 output before timeout; the updated main session recorded
  730,903 input (656,000 cached) and 4,326 output. The incomplete counter and
  separately reported helper sessions prevent a reliable cost comparison.
  An earlier pair stopped at a read-only Git fixture setup; its usage and the
  separately measured safeguard probes are retained in the experiment report.
  This was an open evaluation: isolation from the grader was not established.
  The updated workflow's complete baseline/compare machinery was not exercised
  in the earlier follow-up.
- **Two-page AID site test:** the updated lean instructions produced detailed
  drafts for `aid-review` and `aid-research`, rather than just headings and
  source links. A manual comparison found their major workflows, evidence,
  approval boundaries and outputs represented, but full source coverage was not
  established: for example, the review guide omits the exact reviewer brief
  sections, and the research diagram omits the optional spike branch. The
  guide accurately calls out a conflicting worktree instruction in the source.
  The guides are separate authored inputs, so the current phrase-level tests do
  not guarantee they stay aligned with later skill changes.
  A separate build and browser check rendered both pages; their cross-links,
  disclosure controls and diagram nodes worked in sampled keyboard checks.
  Mobile navigation was clipped at the screen edge, and full accessibility
  and site-wide coverage were not tested. The normal generator has an existing
  nested-frontmatter parser failure; full-site JUnit recorded 63 failures
  before and after, and the task timed out before final review. The saved build
  used a fixture-only cache override and bypassed normal prebuild generation.
  This one open test cannot establish full-site correctness or completeness.
  Its main session used at least 7,457,814 input tokens including 7,354,880
  cached and 28,788 output; separate helper and hook usage is documented in the
  experiment evidence. This exceeded the goal of low usage. The first task
  attempt also failed because the disposable fixture lacked its required base
  branch; the repaired gate passed before continuation. No product changes from
  this experiment were integrated.
- **Focused design and cost audit:** saved traces show that the latest two-page
  trial used at least 7.46 million main-session input tokens, mostly cached,
  and stopped before finishing. The run included large file dumps, broad
  before/after checks and coordination; the data does not isolate how much
  each AID feature cost. A fixture setup error also caused an early stop and
  must not be counted as a product defect. The baseline helper rejected the
  workflow's own changing state and the test's dependency symlink, prompting a
  manual comparison. A content reviewer caught one invalid example, while the
  safeguard blocked inert push and merge commands in a test fixture. Neither
  establishes a measured advantage over plain work.
  Proposed next steps are to fix the baseline/state/dependency mismatch, reuse
  verified evidence only when its inputs match, bound reads and reviewer inputs,
  and repair the site generator and fixture preflights before another matched
  trial. Keep independent whole-result review, failure evidence, isolation and
  the approval boundary. These are proposals, not applied architecture changes
  or proven savings. The [audit](aid-lean-design-cost-audit.md) records the
  evidence, constraints and suggested order; no model run was started for it.
- **Baseline compatibility:** the change checker now accepts an explicitly
  declared active work state and explicitly declared dependency-directory links.
  The state may change while its identity and hashes remain visible; dependency
  targets, tracked lockfiles and complete trees must stay unchanged during each
  check. Other unexpected files remain visible. Comparisons also require the
  same starting commit. Test reports now have an ownership receipt, so the
  checker refuses to remove existing or altered user files. Older baselines can
  be compared after their unowned reports are preserved and moved aside.
  Independent whole-result review and the existing safeguards remain required.
  The 47-test WSL suite, focused native Windows checks and independent review
  passed, including a real Windows junction check. WSL and native Windows
  read-only probes of the original large site dependency tree did not produce
  a fingerprint within their time budgets, so its compatibility and cost remain
  unverified. The installed runtime has not been resynced. These source changes
  do not yet establish a speed improvement or a quality advantage over plain
  Codex.
- **Codex safeguard:** a WSL/Linux Git-project hook and activation helper are
  being added. In disposable trusted fixtures, native Codex tests allowed a
  fake status command and blocked fake push and merge commands. This is not
  proof of protection for every host or indirect command. Native Windows and
  non-Git enforcement remain unverified; existing user hook configurations are
  not overwritten.
- **Codex measurements:** the benchmark driver uses an isolated Codex home,
  verifies the exact fixture's trusted hook before lean runs, and records its
  probe separately. It now accounts for the observed cumulative usage of
  Codex CLI 0.164.0; unknown versions stop instead of receiving guessed totals.
  Recorded input includes cached input and is not a dollar cost.
- **Usable benchmark context:** the notes fixture now has a project card, and
  the lean entry point asks for targeted discovery instead of printing Git
  internals or whole templates by default. These changes were trialed with
  the original application source and graders; the overall lean fixture
  context and commit changed, so this is not an identical treatment.
- **Reviewer compatibility:** the review guidance now permits one disclosed
  host-default fallback for an explicit unsupported-model error, while keeping
  a separate reviewer and the same criteria. It does not override a model the
  user required or retry quota, authentication or service failures. This
  guidance has offline review and tests, but no new live verification.
- **Direct-work state is under review:** the current trial hand-wrote a partial
  state file and edited it repeatedly. The existing full-work template also
  describes an interview in progress and a pending specification, even when a
  direct change needs neither. A faster initializer must first have a truthful
  representation that existing readers can understand; it must not invent
  an approval, task or completed review. A proposed direction is a compact
  direct-work state with an explicit resume route and compatibility checks
  for existing work. The maintainer selected this direction; implementation
  and verification are in progress. A first compact template and initializer
  now exist in the source; early tests verify truthful initial state and protect
  existing records from replacement. Dashboard readers now recognize the
  direct path and show its real goal; they warn about conflicting old task or
  delivery records. Focused checks cover both readers and older paths. A staged
  Codex installation created direct state in a disposable WSL project, and an
  independent reviewer verified installed/source parity. The test launcher was
  normalized to the exact committed Git version. Review found and helped fix
  allocation, lifecycle, path-change and existing-artifact gaps; initialization
  assumes exclusive ownership of its new directory. A broad Windows reader run
  had failures involving WSL access and platform-specific paths, so it is not a
  compatibility pass. Focused WSL checks passed for existing readers, lite/full
  layouts, the work-initiation gate and state writer. Live compact-state resume
  and its cost/quality impact remain unverified; this is not yet shipped.
- **Fewer duplicate work records:** the direct path now says to record a
  continuation in its genuinely related active work, instead of creating a
  second record. Unrelated, completed and canceled work must not be reused.
  This is instruction-level coverage; a live agent has not yet proved it will
  select and update the right work.

## What the results say so far

- The lean site task took about 24 minutes of recorded driver time, excluding
  setup, the safeguard probe and the trust-handoff delay. Its main session used
  13,974,455 input tokens including 13,826,560 cached, and 36,678 output tokens;
  three helper sessions separately report about 14.5 million input tokens.
  Their overlap with the main counter is unverified. Codex did not supply a
  dollar cost.
  The compared Claude runs used different models and environments, so this is
  not a controlled measurement of AID's causal effect.
- In one fresh pair per scenario, plain and lean both passed the fix and
  complex hidden checks. Lean used substantially more reported input tokens
  and more model calls. The lean complex run ended awaiting final approval;
  the benchmark's earlier plan approval was simulated.
- Two earlier lean fix attempts stopped at the trust step and failed their
  hidden checks. They are retained as failures; a later run that passed does
  not erase them.
- Targeted reads reduced output in one fix trial, but did not reduce its model
  call count. The main workflow still needs simplification. One sample per
  arm, missing fixture context and unavailable dollar costs limit conclusions.
- **Still pending:** simplify direct-work setup without removing state,
  tests, safeguards or independent whole-result review; verify its live use;
  and complete the broader evaluation. The approved lean site trial has run.

Update this ledger when a project or architectural change is made, including
its practical effect and any important verification limit.
