---
title: Review and grades
description: How AID reviews work with a separate adversarial reviewer, grades it with a fixed rubric, and loops until it meets your minimum grade.
sidebar:
  order: 3
---

AID never lets the agent that wrote something grade it. A second agent, the reviewer, checks the work. A script, not the reviewer, turns the reviewer's findings into a letter grade. Work moves on only when that grade meets your minimum.

This page explains the rules, so you know what to expect when a review runs.

## The rules in short

- **The reviewer is a separate agent.** It starts with a clean context and never sees the writer's working notes.
- **The reviewer only finds problems.** It does not fix anything and does not pick the grade.
- **The full reviewer is never a lower model tier than the writer.** If a hard task takes a stronger model, its reviewer does too. See [Agents reference](/reference/agents/).
- **The grade is computed.** A script counts findings by severity and applies a fixed table. The same findings always give the same grade.
- **Review and fix are separate steps.** All findings are written down first, then fixed.

## Severities and grades

Every finding gets one of five severities.

| Severity | Meaning |
|---|---|
| Minor | Cosmetic or trivial. Does not affect function. |
| Low | A small convention deviation. It works, but it could be better. |
| Medium | Incorrect behavior that is not critical, a missing edge case, or incomplete coverage. |
| High | Blocks function, a security risk, or a data integrity concern. |
| Critical | System failure, data loss, a security breach, or a fundamentally wrong approach. |

The worst severity present decides the letter. The count at that severity decides the modifier.

| Grade | When |
|---|---|
| A+ | No findings |
| A, A- | Worst finding is Minor: one to five gives A, more than five gives A- |
| B+, B, B- | Worst finding is Low: exactly one gives B+, two to five give B, more than five give B- |
| C+, C, C- | Worst finding is Medium, with the same counting |
| D+, D, D- | Worst finding is High, with the same counting |
| E+, E, E- | Worst finding is Critical, with the same counting |
| F | The work does not build, does not run, or produces nothing usable |

The worst finding dominates. Three Minor findings plus one Medium finding is a C+, not an A.

The rubric is one file, `grading-rubric.md`, installed under `.aid/runtime/templates/`. Every phase and every reviewer uses it.

## The minimum grade

The minimum grade is the bar a phase must reach before it exits its review loop. The default is **A**.

You set it once, with `/aid-config minimum_grade`, and it is stored as `minimum_grade` in `.aid/settings.yml`. A skill can also be given its own bar. For example, `/aid-discover --grade A-` and `/aid-summarize --grade B+` set the bar for that run. See [Settings reference](/reference/settings/).

A higher bar means more review loops and a higher cost. A lower bar is faster and lets more findings through. Pick the one that matches the risk of the project.

## The review loop in `/aid-execute`

`/aid-execute` builds one task at a time. Each task goes through the same loop.

1. **Execute.** The right developer or researcher agent does the work, following rules for the task's type.
2. **Quick check.** A small, cheap reviewer looks only for Critical and High problems. A Critical finding is fixed on the spot, once. If it is still there after that one fix, the task stops with an impediment. A High finding is saved for the delivery gate.
3. **Review.** A full reviewer, with a clean context, checks the work against the task's acceptance criteria and the Knowledge Base, and writes a findings ledger.
4. **Grade.** The script computes the grade from the ledger.
5. **Fix or finish.** If the grade is at or above the minimum, the task is done. If not, the issues are fixed and the loop goes back to review with a fresh reviewer.


Findings are tagged by where the problem started: the code, the task, the specification or the Knowledge Base. Code problems are fixed inside the loop. The other kinds are routed back to the phase that owns them, so the root cause gets fixed instead of patched over.

### The circuit breaker

If the grade has not improved after three review cycles in a row (the same or worse), AID stops. Repeating the loop will not help. Look for a systemic cause, such as fixes that touch the wording but not the underlying problem, or a reviewer grading a wider area than the task. Fix that, or raise an impediment.

### The delivery gate

After every task in a delivery is done, one more review runs for the whole delivery. It collects the High findings deferred earlier and reviews the delivery as a unit, using the same grade, loop and circuit breaker. A delivery with a failed or blocked task never reaches the gate.

## Impediments

An impediment is a written stop. When an agent cannot continue honestly, it must not work around the problem silently. It marks the task `Failed` and writes `IMPEDIMENT-task-NNN.md` in the work folder with a type, what happened, its options and a recommendation.

| Type | Meaning | Where it routes |
|---|---|---|
| `kb-gap` | The Knowledge Base is missing something | A targeted `/aid-discover`, then retry |
| `architecture-conflict` | The design does not hold | `/aid-specify` for the feature |
| `missing-dependency` | Another task is needed first | `/aid-detail` |
| `wrong-assumption` | The task or spec assumed something false | Update the task or spec, then retry |

When you have resolved it, the impediment file is deleted and the task goes back to in progress.

## The findings ledger

Every review, whether by an agent, a script or an ad-hoc request, writes the same thing: one Markdown table with seven columns, and nothing else. It lives at `.aid/.temp/review-pending/<scope>.md`, is ignored by git, and is deleted when the skill finishes.

| Column | What it holds |
|---|---|
| `#` | A row number, never renumbered |
| `Severity` | One of `[CRITICAL]`, `[HIGH]`, `[MEDIUM]`, `[LOW]`, `[MINOR]`, with the brackets |
| `Status` | `Pending`, `Fixed`, `Recurred`, `Accepted`, `OOS` or `Invalid` |
| `Doc` | The file the finding is about |
| `Line` | The line or range, or a dash for the whole file |
| `Description` | Which criterion was broken and one sentence on why it matters |
| `Evidence` | The proof, such as a command and its output |

Only rows with status `Pending` or `Recurred` count toward the grade. A row marked `Fixed`, `Accepted` (you agreed to keep it), `OOS` (out of scope, noted for another phase) or `Invalid` (the finding was wrong) does not.

The brackets matter. The grading script counts the bracketed form only, so a finding written as plain "Minor" would count as zero.

## Ad-hoc reviews with `/aid-review`

Use `/aid-review` when you want a second opinion outside the pipeline. Point it at a file or folder, a pull request, a ticket, a commit range, "my changes", a KB document or a whole work.

```text
/aid-review my changes
/aid-review src/billing/
```

It returns a grade, severity-ranked findings with evidence, and recommendations. It is read-only. It does not edit the reviewed code, and it does not fix anything. Fixing is the job of `/aid-fix`. After it shows you the findings, it publishes them as a pull request or ticket comment only if you approve.

## Related pages

- [Choose your entry](/guides/choose-your-entry/) covers the shortcuts that feed into `/aid-execute`.
- [Skill reference for `/aid-execute`](/reference/skills/aid-execute/) has the exact options.
- [How AID works](/concepts/how-it-works/) shows where review sits in the whole flow.
