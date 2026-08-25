ARTIFACTS UNDER REVIEW:
  VERIFY (full):
    - .aid/works/work-013-review-stack-completion/deliveries/delivery-001/tasks/task-020/RESEARCH.md

  HUNT (scoped -- NEW findings only here):
    - the new "A second grammar limit" section
    - the rewritten "Reproducing this" recipe

CYCLE 2 -- ONE ROW (do not re-litigate the rest, which you passed):
  Row 1 [MINOR] -- the recipe said "insert the four rows" without giving them, and you found that
    the natural `**/*` spelling silently matches nothing. FIX, in two parts:
      (a) the recipe now contains the four rows in full, as a runnable heredoc;
      (b) the quirk is recorded as a finding in its own right, in a new section, because it
          narrows what the registry can express beyond the missing OR and it fails QUIETLY.

    Run the recipe verbatim, copy-pasted, in a scratch copy. It should exit 1 with every
    non-candidate work file unresolved and ZERO candidate files among the violations. Confirm the
    quoted glob_match excerpt reproduces from the line numbers given, and that the explanation of
    WHY `*` after `**` is literal is correct rather than plausible-sounding.

    The document now warns that the violation count will exceed the figure it quotes, since the
    tree grows as tasks execute. Confirm that is what you observe rather than a discrepancy.

  Read the existing ledger at .aid/.temp/review-pending/execute-d001-wave8.md FIRST. Update row 1
  in place. Append any genuinely NEW finding as a Pending row.

CONTEXT:
  Wave 8 of delivery-001, work-013. task-020 is a RESEARCH task: its deliverable is a finding,
  not a change. Nothing was written to the registry or the oracle, and that is itself checkable --
  verify it.

  The finding is a REFUSAL of its own task title. task-020 was scoped to "determine which
  work-folder artifacts should resolve to a registry type", and the answer it reaches is "none of
  them, via the registry". Its own AC anticipates this: "If the proposed selector would break the
  partition, that is the finding, and the recommendation is to narrow rather than to widen the
  partition rule." So a negative answer is in scope -- but only if it is TRUE. Attack it.

  It also narrows task-021, which is a downstream task, from "give work artifacts a registry home"
  to "declare two criteria per file on four artifact kinds". Judge whether that narrowing is
  justified by the evidence or whether it dodges work task-021 legitimately owns.

  The document deliberately reports its counts as drifting rather than fixed, because writing it
  changed the tree it was measuring. Judge whether that is honest or whether it is an excuse for
  imprecision.

  Reviewer self-check: if CONTEXT contains downstream-phase concerns, flag it as an OOS observation
  and bound your review to the artifact listed.

RUBRIC: .cursor/aid/templates/grading-rubric.md (universal severity -> grade table)
  Grade for:
    - **Reproducibility.** Re-run every command in the document. The scratch experiment is
      reproducible from the recipe at the end -- actually run it and confirm you get the same three
      rows in the results table (exit 0 / exit 1 with 103 / exit 0 with a catch-all).
    - **Truth of the reasoning, not just the numbers.** Three claims carry the conclusion: that the
      Match grammar has no OR; that G-07 is total over its corpus so widening is all-or-nothing;
      and that a catch-all would demand durable anchors of review artifacts. Test each.
    - **The 46-of-63 split.** Re-derive it. If the candidate set is NOT well chosen, the
      recommendation's premise fails.
    - **Is the recommendation actually implementable?** It claims per-file `review-criteria:`
      frontmatter needs no registry change, no new type and no grammar extension. Verify the
      cascade really resolves per-file declarations that way, on a file that is OUTSIDE the
      registry's corpus -- that is the load-bearing part, and if per-file criteria only resolve for
      in-corpus files the whole recommendation collapses.
    - **Did it actually leave the tree untouched?** git diff the registry and the oracle.
    - Anything task-021 or the delivery gate would act on and find false.

DECLARED REVIEW CRITERIA (resolve; do not invent):
  Resolve the union -- global, then document type, then the artifact's own `review-criteria:`
  frontmatter; most specific wins on an id collision. Registry:
  .aid/knowledge/authoring-conventions.md.
  - Cite the criterion `id` as a prefix in the Description cell; an id resolving nowhere is a defect
    in the review.
  - A `kind: exclude` criterion binds you.
  - If a criterion carries an `oracle:`, RUN it under a 60s timeout instead of re-reading it.
  - Files under `.aid/works/**` resolve to no registry type -- which is precisely what this task is
    about. Where no declared criterion reaches a real defect, report it and say so in Evidence.
    Do not invent an id.

OUT OF SCOPE (do NOT grade against):
  - The 13 pre-existing suite failures. Baseline is exactly 13 of 142.
  - Whether the 63 work-artifact citation violations should be fixed.
  - PR #185 (closed) and the /aid-graph removal (done).
  - task-021, task-025 and all of delivery-002 -- except where this document makes a claim about
    task-021 that is false.

OUT-OF-SCOPE FINDINGS POLICY:
  Log OOS findings as Status: OOS rows in the same ledger, noting the routing destination. They do
  NOT count toward severity totals and do NOT affect the grade.

DELIVERABLES:
  - Ledger at `.aid/.temp/review-pending/execute-d001-wave8.md` per
    `.cursor/aid/templates/reviewer-ledger-schema.md`.
  - ONE markdown table, 7 columns, no narrative in the file.
  - Severity tags bracketed: [CRITICAL] / [HIGH] / [MEDIUM] / [LOW] / [MINOR].
  - Then run and report:
    `bash .cursor/aid/scripts/grade.sh --explain .aid/.temp/review-pending/execute-d001-wave8.md`
  - Minimum grade: A.
  - You NEVER fix anything -- you grade and list.
