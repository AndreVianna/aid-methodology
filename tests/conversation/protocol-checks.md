# Question protocol checks

The judge applies this checklist to every sample whose `covers` holds AC-8 or AC-28, in addition to the
sample's `## Expected outcome` and `## Must not`. It has one check for each rule of the question protocol
(FR-17, rules 1 to 10) and one for the importance label. The protocol itself is
`.aid/runtime/templates/question-protocol.md`; these checks test a run against it.

The judge reads only `transcript.md`, `files.diff` and `checks.txt`, as `judge.md` says. Each check below
names the evidence to read. A check the run breaks is an unmet expected outcome or a must-not, so it is
recorded only through the EO-n or MN-n item it bears on, as `judge.md` says. A broken check that no item
bears on gets no row.

Read every question in the transcript as the agent asked it: a question is a question the agent put to the
user, whatever its wording.

## The intake exception

Questions asked **while a user starts or chooses a work** are intake questions. They are asked before the
work has a record, so they are not written as `Pending` before they are shown. These are the intake
questions:

- what the user wants, when a start gives no request;
- which kind of work fits, when the reading of the request is unsure;
- whether the request is a new work or the continuation of an existing one;
- the short name of a work;
- the confirmation to cancel a named work, which touches no record until the user answers.

The outcome of an intake question is recorded where it lands: in the new work's intent and name when the
work is created, or in the chosen work's own record on resume. If the user does not answer an intake
question, nothing is created and nothing needs resuming.

Check 10 does not apply to an intake question's missing `Pending` entry or its missing outcome entry. The
judge does not fail a sample on that basis. Every other check applies to intake questions.

Questions asked while setting up the project's settings or connections, and questions asked while building
the knowledge base, are **not** intake questions. Check 10 applies to them in full.

## The checks

1. **One question at a time.** Each agent turn that asks the user asks one question on one topic. A question
   that answers several topics at once fails.
   - Evidence: `transcript.md`, the question text of each agent turn.

2. **Short, with a reason.** Each question is short and clear, and carries a short reason for asking it: a
   "Why I ask" line or the same reason in plain words. A question with no reason fails.
   - Evidence: `transcript.md`, the question text and its reason line.

3. **Respects the user's technical level.** The agent does not ask a technical question of a user who shows
   no technical knowledge, and gives deeper technical detail only when the user asks for it. A technical
   term appears in a question only after the user has used it, or after the user asked for detail.
   - Evidence: `transcript.md`, the agent's questions and explanations read against the user's own turns.

4. **Always a recommendation.** Each question states the agent's recommendation or proposed answer, with its
   reason ("My recommendation: ..."). A confirmation ("I'll do X because Y -- all right?") counts as a
   recommendation. A question with no recommendation fails.
   - Evidence: `transcript.md`, the recommendation line of each question.

5. **Only valid options.** Read the five sub-points together.
   - (a) When the recommendation is the only valid option, the question is a confirmation, not a choice.
   - (b) When two or more options are equally valid and good, all of them are listed, the recommended one
     first, and the question says which is best.
   - (c) No obvious question is asked: a question whose answer the user has already given, or that needs no
     confirmation, fails.
   - (d) No option could lead to an error or a worse result.
   - (e) The closing line of every question that is not an approval lets the user answer in their own words,
     ask for an explanation, or skip the question. An approval offers no skip, and its closing line still lets
     the user answer in their own words or ask for an explanation.
   - Evidence: `transcript.md`, the numbered options and the closing line of each question.

6. **Grouped by subject, most important first, in groups of 3 to 5.** Questions come in groups by subject,
   one subject per group, the most important question of a group first. A group holds 3 to 5 questions. A
   small subject stands as a group of its own, or merges only with a subject it is genuinely related to.
   - Evidence: `transcript.md`, the subject and the position ("question n of m") in each question's first
     line, and the order in which the questions come.

7. **Break offered.** After each group, and at each change of subject, the agent offers a break and names the
   next subject, for example "That's all on {subject}. Take a break, or go on to {next}?". A break offer
   decides nothing; an answer to it is not a question answer.
   - Evidence: `transcript.md`, the agent turn that ends a group or changes the subject.

8. **Follow-ups come at once.** A follow-up question comes straight after the question that raised it, inside
   the same group. A follow-up asked later, or in another group, fails.
   - Evidence: `transcript.md`, the order of the questions and the groups they sit in.

9. **Answered questions are skipped.** When an earlier answer settles a question, or makes it trivial, the
   agent does not ask it again. The decision is recorded as `Assumed`, with its reason, and is confirmed with
   the next approval that covers it. A settled question asked again fails.
   - Evidence: `transcript.md`, the absence of a repeat question; `files.diff`, the record entry with
     `state: Assumed` and its reason.

10. **Every question and answer is recorded.** Each question is written to the record as `Pending` before it is
    shown: the record write appears in `transcript.md` before the question turn. Its outcome is written right
    after the answer, with `answered_by` set. A skipped question is recorded `Skipped`, stays open, and can be
    resumed later by the same user or another one. A question shown with no record write, or an answer with no
    outcome written, fails. The intake exception above applies to intake questions only.
    - Evidence: `transcript.md`, the record writes (tool calls with their target paths) and their order
      against the question turns; `files.diff`, the record's `qa` entries (`id`, `state`, `impact`, `answer`,
      `answered_by`).

11. **Importance label.** Each question carries one importance label, `High`, `Medium` or `Low` (written in
    lower case in the question's first line, as "importance: high", and as `impact:` in the record). The most
    important question of a group comes first. The label `Required` is retired and fails.
    - Evidence: `transcript.md`, the first line of each question; `files.diff`, the `impact` value of each
      record entry.
