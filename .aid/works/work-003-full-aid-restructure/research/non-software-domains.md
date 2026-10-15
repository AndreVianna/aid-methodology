# Research: how AID could serve work outside software

- **Question from the maintainer:** the action list and the kinds in Feature 009 are about software.
  How could AID apply to health, law, productivity, media, arts and everyday tasks?
- **Scope:** research only. This report designs nothing and changes no source file.
- **Sources read:** the requirements document for this work (sections 1 to 10 and Features 001, 003 and 009),
  the Knowledge Base (KB), the shipped templates under `canonical/aid/templates/`, and web sources.
- **Web access date:** every web source below was reached on 2026-10-15.
- **Confidence tags:** CONFIRMED (seen directly), LIKELY (strong inference), UNCERTAIN (weak or conflicting signal).
- **Reading note:** this report avoids acronyms except KB, PR and CI. Where a source or a kind name uses
  one, it is spelled out, or it appears only inside code font as a literal name (`api`, `ui`, `cli`).

---

## 0. Short answer

1. The seven verbs are mostly reusable. The skills are thin, and the rules live in a catalog that is plain
   data. What is software-only is the content of the catalog, a few code-flavoured words in the action
   descriptions, and the closing step (PR and CI).
2. The pipeline already has most of what other domains need: a work that closes with no repository, a
   snapshot stand-in for commits, a "human merges, never the agent" rule, one question at a time, and a
   reading called `investigation`. The KB's own shape (11 universal questions and a table of domains) is
   already domain-neutral.
3. Four things are genuinely missing for other domains: a place for extra kinds that the installer does not
   delete, a way to mark a kind as high-stakes, a "release" step (send, publish, file, pay) with its own
   approval, and a way to keep private data out of anything that is pushed.
4. Recommendation: generic verbs plus domain packs of kinds in the catalog (candidate 1). In v4.0.0 ship
   only the doors (section 7a). Ship no non-software content. Leave the "work medium" and the settings
   field for a later work (section 7b).
5. One conflict needs a maintainer decision before the documentation pass: the KB and the root README say
   AID is a methodology "for building software", while two shipped KB-authoring templates say AID helps with
   any kind of digital work (section 7c).

---

## 1. What the current design already gives (evidence)

All items are CONFIRMED unless tagged.

| Fact | Where it is | Why it matters here |
|---|---|---|
| The catalog is data. Each kind has `about`, `taken_by`, `ask`, `design`, `tasks`, `checks`, `tests`, `update`, all one-line strings. | Requirements, Feature 009, "The catalog" | A new domain is new rows, not new skills. |
| The action skills are thin. Variations "are kept as data". | Requirements, Feature 009, Description | Same reason. |
| Work readings are: bug fix, refactor, change, new capability, document, operational, knowledge update, investigation. | Requirements, Feature 001, "Technical Specification" (the `intent` block) | These are domain-neutral. |
| A work with no repository is closed "done" at minimum; snapshots stand in for commits. | Requirements, section 5, "The CI phase, and operational works"; Feature 007 "Without git"; Feature 008 close mode `no-git` | A non-git medium already exists in embryo. |
| The project setting `source_control` accepts `none`. | `canonical/aid/templates/settings.yml` | Same. |
| AID never merges; merging is a human act. A PR is opened only on the user's instruction. | Requirements, section 5, "Approvals and the merge boundary" and "The CI phase, and operational works" | This generalises directly to "the agent never sends, files, publishes or pays on its own". |
| Release, publish and deploy are "works of their own, not phases". | Requirements, section 5, "The CI phase, and operational works", last bullet | "Publish/send/file" fits as an operational work. |
| Task types already include `RESEARCH`, `DESIGN` and `DOCUMENT`, with the researcher, architect and tech-writer agents. | Requirements, Feature 006 (task file) and Feature 007 (executor by type) | Non-code tasks already have executors. |
| The question protocol forbids technical questions to non-technical users. | Requirements, section 5, "Question protocol" | Fits lay users in every domain. |
| Depth rule: "security-sensitive work" is `full` whatever the input. | Requirements, Feature 001, depth table | The hook for "high-stakes" already exists in prose. |
| The KB's 11 universal questions and the domain table (software, data and machine learning, content, research, design, ops, methodology) already exist. | `canonical/aid/templates/kb-authoring/concern-model.md`; `canonical/aid/templates/kb-authoring/domain-doc-matrix.md` | The KB is already designed for non-software. |
| Host-tool connectors (mail, calendar, drive) are consumed through the host tool, not by AID. | `.aid/runtime/rules.md` section "Connectors" | Everyday and productivity works need no new engineering to reach them. |

What is software-only today (CONFIRMED):

- Every kind in the catalog, and the task chains `IMPLEMENT, TEST`.
- Action wording: `/aid-refactor` is described as "Restructure code without changing what it does, its tests
  unchanged"; `/aid-fix` names defect, regression, incident, vulnerability (Feature 009, "Components").
- The catalog check allows `taken_by` to name only `brainstorm` or an action (Feature 009, Testing, the row
  about the catalog). So `/aid-review`, `/aid-research` and `/aid-report` cannot read a kind's rules.
- The closing step is the PR and CI; `aid-monitor-pipeline` is the only skill that touches the PR.
- "Done only after its tests pass" (Requirements, acceptance criterion on Building).
- The work-folder setting defaults to `push` (Requirements, section 5, "The CI phase, and operational works", and the minor decision on the work-folder setting).

---

## 2. Domains, typical works, and the verbs

The seven verbs are create, update, fix, refactor, document, test, prototype. For each domain the table says
what the verb means and whether it fits. "Fits" means the same shape as software. "Care" means it works but
the meaning shifts. "Breaks" means the verb implies something the agent must not do, or something that has
no equivalent.

### 2.1 Health

Typical works a person asks an agent for (LIKELY, from the product launches in section 6 and general use):

- Prepare for a doctor visit: a symptom timeline, the medicine list, the questions to ask.
- Understand a test result, a medicine leaflet, or a discharge letter in plain words.
- Keep a health log: sleep, symptoms, medicine taken, measurements.
- Organise records, insurance claims and appeals; draft the appeal letter.
- Plan meals, exercise or a medicine schedule inside what a clinician has already set.
- Summarise research papers on a condition.
- For a clinic: draft visit summaries, patient letters and prior-approval packets for a clinician to review.

| Verb | Meaning in health | Fit |
|---|---|---|
| create | A new log, summary, letter, or visit-preparation sheet | Fits |
| update | Revise the log or plan after new information | Fits |
| fix | Correct an error in a record (a wrong dose copied, a wrong date, a billing mistake) | Care. "Fix my back pain" is treatment, and the agent must refuse it. |
| refactor | Reorganise records or simplify a schedule without changing content | Care. Changing the timing of a medicine changes the treatment, so the "same behaviour" test is a clinician's, not the agent's. |
| document | Visit summary, care instructions written in plain words | Fits |
| test | Check a plan against its sources and a safety list | Breaks by name. A medical test is a real-world procedure ordered by a clinician. Keep the AID meaning ("check what exists") and avoid the word in the person's screen. |
| prototype | A two-week trial routine with a simple measure | Care. Only for low-risk habits (sleep time, walking), never for treatment. |

Missing verbs: explain, prepare, track, remind, escalate (hand to a professional or to emergency help).

### 2.2 Law

Typical works:

- Review a contract, a lease or terms of service and flag the risky clauses.
- Draft a letter: cancellation, complaint, demand, reply to a notice.
- Prepare a form or a filing (small claims, a tenant dispute, a licence application).
- Research a legal question and write a memo with sources.
- Keep a case file and a timeline; track deadlines.
- Build a compliance checklist for a small business.

| Verb | Meaning in law | Fit |
|---|---|---|
| create | Draft a letter, a clause, a memo, a form | Fits |
| update | Amend a draft, mark up changes (redline) | Fits |
| fix | Correct a defect in a document (wrong party name, broken cross-reference, wrong date) | Fits for documents. Breaks for "fix my legal problem". |
| refactor | Reorder and simplify a contract or letter without changing its legal effect | Fits well, with one condition: only a lawyer can confirm "same legal effect", so the check is a flagged list, not a pass. |
| document | A plain-language summary, a case file, a timeline | Fits |
| test | Cross-check defined terms, cross-references, amounts, dates, and every citation | Care. The agent can test the document. It cannot test the law. |
| prototype | A first negotiating position or a term sheet to try on the other side | Care. |

Missing verbs: review (the dominant request), research, send/serve/file, calendar a deadline, negotiate (a person's act, not the agent's).

### 2.3 Productivity

Typical works:

- Plan a day or a week; set goals; run a weekly review.
- Triage an inbox; schedule meetings; write meeting notes and follow-ups.
- Set up a task system or a note system; tidy it.
- Build a routine or a repeatable workflow; automate a recurring chore.
- Prepare a talk or a status report.
- Decide between options and write down the decision.

| Verb | Meaning in productivity | Fit |
|---|---|---|
| create | A new plan, template, system or routine | Fits |
| update | Change the plan when priorities move | Fits |
| fix | Repair something broken (double-booked calendar, lost task, broken rule) | Fits |
| refactor | Reorganise folders, tasks or the calendar with the same commitments | Fits very well ("same commitments, cleaner structure") |
| document | Write down a procedure, a checklist, a decision | Fits (this is the runbook kind) |
| test | Audit: do plan hours fit the week, are there conflicts, is every commitment covered | Fits |
| prototype | Try a routine for a week and measure | Fits |

Missing verbs: plan (as the product), prioritise, triage, schedule, remind, track, communicate.

### 2.4 Media

Typical works:

- Write an article, a newsletter, a script, a press release.
- Edit, tighten, translate or adapt a piece for another channel.
- Plan a content calendar; schedule posts.
- Fact-check and source-check a draft.
- Prepare captions, transcripts, show notes and accessibility text.
- Manage a media library, its metadata and its rights.

| Verb | Meaning in media | Fit |
|---|---|---|
| create | A new piece | Fits |
| update | A new edition or revision | Fits |
| fix | Correct a factual error, a wrong caption, a broken link | Care. A published correction is a public act with its own process. |
| refactor | Restructure or tighten a piece while every claim stays | Fits (this is editing) |
| document | Style guide, editorial notes, show notes | Fits |
| test | Fact-check table, rights check, accessibility check, link check | Fits |
| prototype | A pilot episode, a rough cut, headline variants | Fits |

Missing verbs: research, edit/review (by a human editor), translate/adapt, publish, schedule, distribute, moderate.

### 2.5 Arts

Typical works:

- Develop a story: premise, outline, chapters, continuity notes.
- Design a poster, logo, layout or album cover brief.
- Write an artist statement, a grant application, a portfolio.
- Plan an exhibition, a show or a release.
- Ask for a critique of a piece.
- Keep a "bible" of a fictional world or a brand's look.

| Verb | Meaning in arts | Fit |
|---|---|---|
| create | A new piece or a new draft | Care. The person must stay the author (section 5.4). |
| update | A new revision | Fits |
| fix | Repair a flaw: a continuity error, a plot hole, a wrong colour mode | Fits for craft errors, not for taste |
| refactor | Reorder chapters, rearrange song sections | Care. In art, structure is part of meaning, so "same behaviour" is not checkable. |
| document | Artist statement, process notes, catalogue record, credits | Fits |
| test | A critique, a read-through, a continuity scan, a print preflight | Care. Most of it is taste, so there is no pass or fail; the result is a list of observations. |
| prototype | A sketch, a thumbnail, a demo, a table read | Fits best of all domains |

Missing verbs: critique, explore (many options), curate, perform, exhibit/submit, credit and license.

### 2.6 Everyday tasks

Typical works:

- Plan a trip, a move, a party, a purchase.
- Compare products or services and decide.
- Fill in forms and applications; handle paperwork.
- Dispute a charge, request a refund, cancel a subscription.
- Plan a budget; plan meals and shopping.
- Learn a skill with a study plan.

| Verb | Meaning in everyday tasks | Fit |
|---|---|---|
| create | A plan, list, budget, or itinerary | Fits |
| update | Change the plan when something moves | Fits |
| fix | Sort out a problem (a wrong booking, a duplicate charge) | Care. Fixing means acting on the outside (calling, paying), so it needs the release step. |
| refactor | Reorganise a budget or a packing list, same totals | Fits |
| document | Write the house manual, a how-to for the family | Fits |
| test | A dry run: do the timings connect, do the totals add up, are the documents valid on the dates | Fits |
| prototype | Try the route, the recipe, the routine | Fits |

Missing verbs: research and compare, decide, book, buy, pay, send, track, remind, learn.

### 2.7 Across the six domains: which verbs are missing, and are they really missing?

Finding (CONFIRMED for the AID side, LIKELY for the usage side): the seven AID verbs are mostly verbs that
change a thing. Many non-software requests are about informing, deciding, communicating, tracking, or
learning. Most of those already exist in AID as skills or as readings, only under software wording.

| Missing verb | What exists in AID today | Verdict |
|---|---|---|
| review | `/aid-review` (any artifact, findings only) | Exists. Needs to read kind rules (`taken_by`). |
| research | `/aid-research` | Exists. Same. |
| analyse | `/aid-report` | Exists. |
| plan | `/aid-plan` plans build tasks. A trip plan is a deliverable, so it is a kind (`trip`), not a verb. | Treat as a kind. |
| decide | `/aid-brainstorm` plus `/aid-research`, then a decision record (the `decision` document genre exists) | Treat as a kind plus existing skills. |
| learn / explain | Reading `investigation`; project questions go to the KB | Exists as a reading. |
| track | `/aid-monitor` (production only today) | Extend wording later. AID has no scheduler of its own; the host tool or the person triggers a run. LIKELY. |
| publish | `/aid-deploy` | Extend wording later; also needs the release step (section 4). |
| communicate (send a message to a person) | Nothing. The `ticket` kind writes to a tracker after a confirmed preview. | The one verb that is truly new. It acts on the outside, so it needs the release step. |

Recommendation inside this finding: do not add verbs in v4.0.0. The reading `operational` already covers
"acts on the outside world", and `investigation` covers "learn, decide, explain".

Does the word "refactor" fit lay users? Not by name. The plain-words path (no slash command) already routes
"tidy my budget without changing any number" to the refactor reading by meaning (Requirements, section 5, "Intent interpretation").
Friendly aliases can be added later without breaking anything.

---

## 3. Kinds per domain, and what verification means

### 3.1 The shape of an entry

The existing fields are enough to describe a domain kind. The extra fields below are proposals (marked
"proposed") and are needed only for high-stakes kinds.

```yaml
- kind: legal-letter
  domain: law                    # proposed; default is software
  about: 'a letter that asserts a position to another party: cancel, complain, demand, reply'
  taken_by: 'create, update, review, document'     # review is not allowed today
  ask: 'where the person lives; who the other party is; the facts with dates and proof; what outcome is wanted; the deadline and where it comes from; how it will be delivered'
  design: 'Facts and evidence table'
  tasks: 'RESEARCH, DOCUMENT'
  checks: 'every fact matches a document the person gave; no claim is stated as certain law; the deadline cites its source; no threat the person did not choose'
  tests: 'a line-by-line table: fact, evidence, match; a tone read; a check that nothing was sent'
  risk: high                     # proposed: forces full depth and a sign-off question
  limits: 'does not give legal advice and does not claim the letter is valid; says so in the document'   # proposed
  sign_off: 'a licensed lawyer when money or rights at stake are large; otherwise the person, who confirms they understand it is not advice'  # proposed
  release: 'the person sends it; the agent never sends'   # proposed
```

### 3.2 What "testing" means in each domain

There are five kinds of check. Software uses all five but leans on the first. Other domains lean on 2 to 5.

1. Mechanical check: arithmetic, schedule conflicts, cross-references, link and format checks. A script or a
   reviewer can run it. Closest to a test suite.
2. Source trail: every claim in the output points to a source passage that was opened and read.
3. Checklist: a list with an evidence line per item. Done only when each item has evidence or a named waiver.
4. Dry run or trial: run the thing on past real cases, or try it for a short period (this is prototype).
5. Human judgment: taste, professional sign-off, or the person confirming.

| Domain | Mostly | What replaces "tests must pass" |
|---|---|---|
| Health | 2 and 5 | Every number matches the source; a safety list is clear; a clinician or the person signs off before anything changes |
| Law | 1, 2 and 5 | Defined terms, cross-references and amounts agree; every citation opened and quoted; a lawyer signs off when stakes are high |
| Productivity | 1 and 4 | No conflicts; hours fit; a dry run on ten real past cases |
| Media | 2, 3 and 5 | Fact-check table; rights recorded; accessibility items; an editor signs off |
| Arts | 3 and 5 | Continuity scan or print preflight; the author's read-through; a list of observations (no pass or fail) |
| Everyday | 1, 3 and 4 | Totals add up; timings connect; documents valid on the dates; a dry run |

Prior art for the checklist idea: the World Health Organization surgical safety checklist (19 items, three
pauses) was linked in a multi-hospital study to fewer deaths and complications; the authors stress it works
through team behaviour, not through the paper alone (section 6, item 18). The lesson for AID: a checklist
counts as a check only when someone must show evidence per item.

### 3.3 Catalog entries by domain

Each row is a kind. "Sign-off" is who must approve before the real-world step. "Release" is the step AID
must not do on its own.

**Health** (all `risk: high`; the pack is about organising, explaining and preparing, never recommending treatment)

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `visit-preparation` | Who the visit is with; what changed since the last visit; current medicines and doses copied from a label or the pharmacy list; the three questions that matter most | Doses and dates come from a source the person gave; no likely diagnosis is named; no change of treatment is advised; warning signs are listed with "call emergency services" | Source trail; the person reads it and confirms it matches their life | The person. Nothing is sent to the clinic automatically. |
| `result-explanation` | Which result, which date, which lab; what the clinician already said; what the person wants to understand | Shows the lab's own reference range; says what is not known; never says to start, stop or change a medicine; ends with a question for the clinician | Every number matches the source document; a plain-words read by a non-expert | The clinician for any decision. The agent only explains. |
| `health-log` | What is tracked; how often; where it is stored and who can see it | Units and dates consistent; no entry lost on update; totals match entries; data stays local | Mechanical check on the log; a trial week (prototype) | The person. Never pushed (section 5.2). |

**Law** (`risk: high` for filings and contracts above a small value)

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `contract` | Place and governing law; which party the person is; the deal in a paragraph; amounts and dates; what must not be given away | Each defined term is used and defined once; cross-references resolve; amounts and dates agree everywhere; every risk-shifting clause is flagged; no statement that it is valid | Mechanical (terms, references, amounts); a "what could go wrong" pass; flagged list | A licensed lawyer when stakes are high. The people sign; the agent never does. |
| `legal-letter` | See the example in 3.1 | See 3.1 | Fact table; tone read | The person sends it. |
| `research-memo` | The question; the place; the date the law must be current to; what the memo will be used for | Every authority exists and says what it is cited for, opened and quoted from the source, never from memory | Citation table: citation, source link, quoted passage, match yes or no | A licensed lawyer before reliance in a filing. |

**Productivity**

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `weekly-plan` | Fixed commitments; the three outcomes that matter; hours available; what can slip | No overlaps; each outcome has a first action; planned hours do not exceed available hours | Conflict scan and hour sum | The person. Writing to the calendar is reversible and confirmed. |
| `routine` (inbox rules, weekly review, a recurring chore) | The trigger; the steps; who owns it; what must never happen automatically | No step sends, deletes or shares without approval; deletion means "move to trash" | Dry run on ten real past cases before it goes live | The person. Going live is a release. |
| `decision-record` (reuses the existing `decision` document genre) | The options; the criteria; who decides; the deadline | Options compared on the same criteria; sources dated; the recommendation and the reason stated | Completeness table | The decider. |

**Media**

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `article` | Audience; the claim in one sentence; sources; length; style guide; deadline; what is off-limits | Each factual claim has a source a reader can open; quotes are verbatim; names, figures, dates verified; opinion marked as opinion; the outlet's disclosure rule for automated help is met | Fact-check table; style check; link check; read-aloud | An editor. Publishing is irreversible in practice; the person or editor publishes. |
| `episode` (audio or video) | Format and length; guest consent; music and clip rights | Rights recorded for every clip and track; consent noted; transcript and captions exist | Timing sheet; transcript matches script | The producer. |
| `content-calendar` | Channels; cadence; goals; approvers | Each item has owner, date, channel, approver; no clashes; sponsorship labels present | Calendar conflict scan; pre-publish checklist | The approver. Scheduling a post is a release. |

**Arts**

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `story` | What the author wants the reader to feel; what is already fixed; which text is the author's and which the agent may draft; length; reader | Continuity table (names, ages, places, timeline) has no contradictions; the author's voice sample is matched; nothing copied from a named work; the author's own text is marked | Continuity scan; the author's read-through; reader questions | The author decides all taste questions. |
| `visual-design` | Purpose; audience; size and format; brand rules; who owns each image and font and under what licence | Readable contrast; a licence for every asset; size and colour mode match the print or screen target | Print preflight list; view at small and large size; mock-up in context | The artist. Printing or posting is a release. |
| `grant-application` | The funder; the criteria; budget limits; deadline; attachments | Each criterion is answered with evidence; the budget adds up; word limits are met; attachments listed | Criteria table; arithmetic | The applicant. Submitting is a release. |

**Everyday tasks**

| Kind | What to ask | What to check | Verification | Sign-off and release |
|---|---|---|---|---|
| `trip` | Dates; travellers (ages, documents, mobility); budget; must-haves; what is refundable | Every leg connects with a buffer; documents are valid on the dates; costs add to the budget; cancellation terms recorded for every booking | Timeline walk-through; conflict scan | The person. Each booking or payment is a separate approval. |
| `purchase-decision` | The need; budget; deal-breakers; deadline; return policy | At least three options compared on the same criteria; prices dated; each claim sourced; paid placement disclosed | Comparison table completeness | The person pays; the agent never pays. |
| `paperwork` (tax, school, benefits, forms) | Which form and who it is for; the deadline; where it is submitted | Each field matches a document; totals recompute; the deadline and place are stated with their source | Field-by-field match | The person submits. Sensitive identifiers stay out of the KB. |

### 3.4 Kind-name collisions to expect

Names such as `document`, `test`, `report`, `plan`, `integration` and `architecture` already carry a
software meaning in Feature 009 (its Risks section names the `architecture` and `test` collisions). A pack
that adds `plan` or `report` would collide. Two cheap rules prevent it: kind names stay unique across all
packs, and each kind carries a `domain`.

---

## 4. How the pipeline's software parts map

| Software part | The job it does | Non-software equivalent | Where the mapping is weak |
|---|---|---|---|
| Git branch and worktree | Keep unfinished changes apart from the real thing; keep history; allow discard | A working copy of the document with named versions. Google Docs, for example, offers version history, restore, and up to 40 named versions per document (section 6, item 19). Or a folder of files under git, which many writers already use. Or the snapshots AID already takes when there is no git. Or nothing, for a decision that is only a conversation. | The real thing often lives outside the project folder (a cloud document, a calendar, a mailbox). Then "isolate" means "work on a copy" and the copy must be reconciled by hand. |
| Diff | Show exactly what changed | Tracked changes, a redline, a side-by-side comparison, a table of changed claims | Images, audio and layouts have no readable diff; use before and after previews. |
| Review (code review, reviewer agent) | An independent look, before release | The same reviewer agent, plus a named human: editor, lawyer, clinician, peer, or the person | The human is the point in health and law; the agent cannot replace them. |
| Tests | Executable proof of the acceptance criteria | Checks of the five kinds in section 3.2; "done" needs evidence per item or a named waiver | Arts has no pass or fail. |
| CI pipeline | Automatic gates before merge | Automatic document checks: arithmetic, links, spelling, style rules, citation check, similarity check, accessibility | Each pack must supply its checks; none exist today. |
| PR | A package for a reviewer: the change, the results, the open questions | A review package: the changes, the check results, the open questions, and a sign-off line (who, when, which version) | New: the sign-off record. |
| Merge | Make the change live; the human does it | Release: send, publish, file, sign, pay, post, schedule, or accept into the calendar. The human does it, or the agent does it only with the exact approved version and a per-action approval. | Software merges are mostly reversible; many releases are not (section 5.5). |
| Building (execute and test) | Do the tasks and verify | Draft, gather, compose, then verify. The existing `RESEARCH`, `DESIGN` and `DOCUMENT` task types and their agents cover this. | The checking task is typed `TEST` and run by the developer agent; a pack needs a checking executor (LIKELY gap). |
| Simplify ("never changes behaviour") | Cut clutter without changing what it does | Edit for length and plain words without changing meaning, facts, legal effect or clinical content | The "same behaviour" proof is a table of claims before and after, not a test run. |
| The KB | Project knowledge the agent must follow | A personal, matter, publication or household file: preferences, facts, style guide, constraints, past decisions | Sensitive data (section 5.2). Also, the KB's own doc names are software-flavoured, but the domain table already maps other domains. |
| Question protocol, approvals, milestones | One topic at a time; approve before the push | Unchanged. They suit lay users best. | The approval must name the real-world act it controls (send, file, pay), as the section "Approvals and the merge boundary" names the push. |
| Close (marks done) | Nothing left to monitor | Unchanged for the minimum. A new `release` close is a later addition. | |

CONFIRMED: the minimum close already works with no repository. LIKELY: a `release` close mode is a small
addition to the same step, run by the `aid-operator` agent (its text says it handles "actions with
external consequences", `canonical/agents/aid-operator/AGENT.md`).

---

## 5. Safety and responsibility limits

### 5.1 The three boundaries

Every domain pack needs the same three guards. Only their strength differs.

1. **Advice boundary.** What the agent may do (organise, explain, draft, check against sources) and what it
   must not (diagnose, prescribe, give legal advice, represent someone, decide for the person).
2. **Privacy boundary.** What data the work touches, where it may be stored, who can see it.
3. **Release boundary.** Which steps cannot be undone, and who performs them.

### 5.2 Privacy (applies to all, strongest in health and law)

- **Default to local.** Today the work-folder setting defaults to `push`, and the KB is committed through
  `kb-commit.sh` (Feature 004). For a personal project that would put health or legal facts into a shared
  remote. A pack must default to `keep-local` or `delete` for sensitive kinds. CONFIRMED that `push` is the
  default (Requirements, section 5, "The CI phase, and operational works", and the minor decision on the work-folder setting); the sensitive-kind override is a
  proposal.
- **Special categories.** Health data and some legal data are special categories in data-protection law in
  several places, and the United States has a health-privacy law for providers and payers. I did not open
  those laws; treat the details as UNCERTAIN and have the pack author check the places the pack serves.
- **No carry-over between contexts.** Anthropic's own agent framework warns that agents "might inappropriately
  carry sensitive information from one context to another" (section 6, item 7). Sensitive kinds should not be
  written into general KB documents or remembered across works.
- **Minimal reading.** Read only the records the work needs; ask first before reading a mailbox or a record
  store. Both Anthropic and OpenAI describe opt-in access for health records (section 6, items 6 and 9).
- **Secrets stay out.** Passwords, card numbers and identity numbers are never written into any AID file.
  The Operator-style takeover (the person types the secret themselves) is the prior art (section 6, item 10).
- **Untrusted content.** Mail, web pages and documents can contain instructions aimed at the agent. Personal
  agents have been attacked this way (section 6, item 17). Sensitive works read untrusted text as data only.

### 5.3 Health and law: a professional in the loop

| | Health | Law |
|---|---|---|
| The agent may | Organise records, prepare questions, explain a result in plain words with its reference range, summarise research, keep a log, draft letters for a clinician to review | Draft documents, mark up changes, check internal consistency, summarise, research with sources, track dates, prepare filings for a person or a lawyer to review |
| The agent must not | Diagnose, name a likely condition, advise to start, stop or change a medicine or dose, replace emergency care | Give legal advice, say a document is legally valid, claim to act as a lawyer, choose a legal strategy for the person |
| Required in the output | A short plain disclaimer once per document, the warning signs with "call emergency services", and a question to bring to the clinician | A short plain disclaimer once per document, the jurisdiction used, and a note on what a lawyer should confirm |
| Professional sign-off | The clinician for any change of treatment or any record that enters a clinical file | A licensed lawyer when money, rights or a filing deadline are at stake; the person alone only for low-stakes letters, with an explicit "this is not advice" acknowledgement |
| Special hazards | Automation bias: people and clinicians overlook errors in confident output (World Health Organization guidance and the United States Food and Drug Administration guidance both say this, section 6, items 15 and 16) | Invented citations that look real; sanctions have followed (section 6, item 13); and confidentiality when client facts go to a tool (section 6, item 12) |
| Marketing claims | Do not claim the pack diagnoses or treats | Do not claim the pack performs like a lawyer; the United States Federal Trade Commission required evidence for such claims (section 6, item 14) |
| Pack default (proposal) | Off until the user turns it on and accepts the limits | Off until the user turns it on and accepts the limits |

Notes on regulation (UNCERTAIN; secondary sources only):

- The United States Food and Drug Administration guidance on clinical decision support software, revised in
  January 2026, keeps a criterion that software must let a clinician independently review the basis of any
  recommendation. A pack that stays at organising, explaining and preparing is far from that line; a pack
  that recommends treatment is not. This is the practical reason to forbid recommendations in the health pack.
- The European Union rules for high-risk uses were reported delayed to December 2027 (section 6, item 22).
  Sources disagree on dates; check before relying on them.

### 5.4 Media and arts

- **Rights and consent.** Record the licence of every image, font, clip and track, and the consent of every
  person who appears or speaks.
- **Accuracy and harm.** Published claims about real people carry defamation risk. Mark opinion as opinion.
- **Disclosure.** Many outlets and contests require disclosure of automated help. Content Credentials is an
  open standard that records how a file was made, including degree of human oversight (section 6, item 21).
- **Authorship.** The United States Copyright Office concluded in January 2025 that prompts alone do not give
  enough control for copyright, and that human contribution is what is protected (section 6, item 20). So
  the person should do and mark their own creative choices. The agent drafts only what the person asks it to
  draft, and the kind records which parts are whose.
- **Irreversibility.** Publishing, posting and submitting to a contest are public and copied quickly.

### 5.5 Irreversible actions

Sort every outward step into one of three classes. The class decides the approval.

| Class | Examples | Rule |
|---|---|---|
| Reversible and private | Save a draft; add an entry to your own calendar; move a mail to trash | Ask once per work |
| Reversible but visible | Share a document with named people; send a calendar invitation | Ask each time; show the exact text and the recipients |
| Irreversible or costly | Send a message; file; sign; pay; book non-refundable; post publicly; delete without trash; submit | The human does it; or the agent does it only after approval of the exact version, each time, never batched, never pre-approved |

Prior art agrees: Operator asks for approval before significant actions such as submitting an order or
sending a message, and hands control to the person for passwords and payment (section 6, item 10); Google's
Agent Payments Protocol separates "person present" purchases (the person approves the exact cart) from
"person absent" purchases (pre-set limits) (item 11); Anthropic says agents must ask for human approval
before actions that modify systems and that "humans should retain control over how their goals are pursued,
particularly before high-stakes decisions are made" (item 7). A reported case of a personal agent deleting
many mails that its owner could not stop is a reminder to treat deletion as irreversible (item 17).

AID's existing rule, "AID never merges; a human does", is the right shape. The generalisation is: AID never
performs an irreversible release by itself.

---

## 6. Prior art (web)

All links accessed 2026-10-15. "Opened" means I read the page. "Search only" means I saw a search summary
and the page itself could not be reached from here (some hosts did not resolve), so details are UNCERTAIN
until someone opens the page.

| # | Source | Link | What it shows | How read |
|---|---|---|---|---|
| 1 | Anthropic knowledge-work plugins (open repository) | https://github.com/anthropics/knowledge-work-plugins | A role-based plugin catalog: productivity, sales, customer support, product management, marketing, legal, finance, data, enterprise search, bio-research. A plugin is skills (domain knowledge the agent draws on), commands (explicit actions), and connectors (to the person's tools). The page says "Every component is file-based" and "These plugins are generic starting points." The main page has no statement about professional review or disclaimers. | Opened |
| 2 | The legal plugin of the same repository | https://github.com/anthropics/knowledge-work-plugins/tree/main/legal | Commands to review a contract and triage confidentiality agreements; a disclaimer at the top: it "does not provide legal advice. Always verify conclusions with qualified legal professionals", and output "should be reviewed by licensed attorneys before being relied upon for legal decisions". The default playbook assumes three United States states; other places must customise it in a local file. | Opened |
| 3 | Claude Code plugin marketplaces (documentation) | https://code.claude.com/docs/en/plugin-marketplaces.md | A marketplace is a catalog file listing plugins; plugins can bundle skills, agents, hooks and connectors; a team can require one on every machine; installed plugins are copied to a cache. | Search only |
| 4 | Agent Skills open standard | https://agentskills.io/ | A skill is a folder with a `SKILL.md` file (name and description at minimum); originated at Anthropic and adopted by other tools. Domain-neutral by design. | Search only; host unreachable |
| 5 | Press coverage of the plugin expansion | https://the-decoder.com/anthropic-expands-legal-ai-offerings-with-new-cowork-plugins/ | Legal and finance plugin sets were added after the first eleven. Reports differ on dates and counts (eleven in February 2026, twelve legal plugins later). | Search only; UNCERTAIN on scope |
| 6 | Anthropic, health and life sciences announcement | https://www.anthropic.com/news/healthcare-life-sciences | Opt-in access to personal health data; the person can change or revoke access; "We do not use users' health data to train models"; it is designed to direct people to healthcare professionals; for prior approval, Claude proposes a determination "for the payer's review". | Opened |
| 7 | Anthropic, framework for safe and trustworthy agents | https://www.anthropic.com/news/our-framework-for-developing-safe-and-trustworthy-agents | Human control before high-stakes decisions; read-only by default; approval before actions that modify systems; warning about carrying sensitive information between contexts; per-tool permissions. | Opened |
| 8 | OpenAI usage policies | https://openai.com/policies/usage-policies/ | Prohibits tailored advice that needs a licence, such as legal or medical advice, without appropriate involvement of a licensed professional; prohibits automating high-stakes decisions in sensitive areas without human review. | Search only; page unreachable |
| 9 | Reports on ChatGPT Health (January 2026) | https://www.techradar.com/ai-platforms-assistants/chatgpt/chatgpt-health-is-a-new-space-for-medical-questions-that-works-with-your-health-data-but-openai-insists-its-not-designed-to-replace-your-doctor | Described as not intended for diagnosis or treatment; health conversations kept apart from ordinary chats and not used to train models; criticism from a privacy group. | Search only; secondary |
| 10 | OpenAI Operator announcement | https://openai.com/index/introducing-operator/ | Asks for approval before significant actions such as submitting an order or sending an email; hands control to the person for sign-in and payment; declines some tasks such as banking transactions. | Search only (January 2025 launch) |
| 11 | Agent Payments Protocol | https://ap2-protocol.org | "Person present" purchases need approval of the exact cart; "person absent" purchases use pre-signed limits; the signed approval is the proof. | Search only; secondary write-ups |
| 12 | American Bar Association formal opinion on generative tools (July 2024) | https://technologylaw.fkks.com/post/102jwnl/aba-issues-comprehensive-formal-ethics-opinion-on-lawyers-use-of-generative-ai | Lawyers keep duties of competence, confidentiality and supervision; they remain responsible for the result and must review output. | Search only; secondary summary |
| 13 | Sanctions for invented citations (the Mata case and later cases) | https://www.americanbar.org/groups/litigation/resources/newsletters/appellate-practice/ai-hallucinations-real-how-avoid-them/ | Courts sanctioned lawyers who filed fabricated citations; one lawyer used the same tool to "verify" the cases. Using a tool is not itself improper; failing to check is. | Search only; secondary; amounts UNCERTAIN |
| 14 | Federal Trade Commission action on a "robot lawyer" service | https://sites.suffolk.edu/jhtl/2024/11/19/sue-anyone-with-a-click-of-a-button-ftc-cracks-down-on-donotpays-misleading-ai-claims | The order required evidence for claims that a service performs like a lawyer. The unauthorized-practice question came from a separate state bar matter. | Search only; secondary |
| 15 | United States Food and Drug Administration clinical decision support guidance (January 2026) | https://www.cov.com/en/news-and-insights/insights/2026/01/5-key-takeaways-from-fdas-revised-clinical-decision-support-cds-software-guidance | Keeps the "independent review" criterion; adds language on automation bias and transparency. | Search only; law-firm summaries; the guidance itself not read |
| 16 | World Health Organization guidance on large multimodal models (January 2024) | https://www.who.int/publications-detail-redirect/9789240084759 | Over 40 recommendations; warns that these tools can encourage automation bias, so errors are overlooked. | Search only; the report itself not read |
| 17 | Security coverage of the OpenClaw personal agent | https://www.techradar.com/pro/here-are-the-openclaw-security-risks-you-should-know-about and https://www.malwarebytes.com/blog/news/2026/02/openclaw-what-is-it-and-can-you-use-it-safely | A reported case of a person unable to stop the agent deleting many mails; prompt injection called an unsolved problem; hundreds of malicious skills reported in its plugin repository; a data-protection regulator warned against using it with sensitive data. | Search only; news and vendor posts, not audits |
| 18 | Surgical safety checklist study (2009) | https://news.harvard.edu/gazette/story/2009/01/surgical-safety-checklist-drops-deaths-and-complications-by-more-than-one-third/ | A 19-item checklist at three pauses, linked to fewer deaths and complications; it works through behaviour, "not just a piece of paper". | Search only; figures UNCERTAIN |
| 19 | Google Docs version history | https://support.google.com/docs/answer/190843 | Versioned documents without git: see changes, restore, copy, and name versions (up to 40 per document). | Search only |
| 20 | United States Copyright Office, report on copyrightability (January 2025) | https://www.akingump.com/en/insights/ai-law-and-regulation-tracker/us-copyright-office-releases-part-2-of-ai-report | Human authorship is required; prompts alone are not enough; human arrangement and modification can be protected. | Search only; secondary |
| 21 | Content Credentials (provenance standard) | https://c2pa.org/a-new-implementation-guide-for-content-credentials/ | Signed records of how a file was made, with a disclosure of machine involvement and the degree of human oversight; it shows the record was not altered, not that the content is true. | Search only |
| 22 | Reports on the delay of European Union high-risk rules | https://labs.cloudsecurityalliance.org/research/csa-research-note-eu-ai-act-high-risk-deadline-omnibus-20260/ | High-risk obligations reported moved to December 2027; sources differ on dates. | Search only; UNCERTAIN |

What the prior art says, in short:

- Role-based catalogs of file-based plugins are the dominant pattern (items 1 to 4). They bundle domain
  knowledge, explicit commands and connectors, and are generic starting points to customise. This matches
  "domain packs of kinds in the catalog".
- The vendors that serve health and law put the professional in the loop in words (items 2, 6, 8, 9), and
  put the privacy promises in the product (items 6, 9). The main page of the largest catalog says nothing
  about it (item 1), so AID can do better by making it part of the entry (`risk`, `limits`, `sign_off`).
- Personal agents converge on "approve the exact action, and hand secrets back to the person" (items 7, 10, 11).
- Catalog supply chain is a real risk (item 17). A pack is text that steers an agent, so a malicious pack is
  an attack.

---

## 7. Recommendation

### 7.0 Options compared

| Option | What it buys | Cost in v4.0.0 | Verdict |
|---|---|---|---|
| 1. Generic verbs plus domain packs of kinds in the catalog | New domains are new rows. No new skills. Matches the prior art. | Small, if the catalog has a place for outside rows (7a). | Choose. |
| 2. A "work medium" abstraction (git, documents, none) | A clean place for the version-and-release differences | Medium. Touches Features 006, 007 and 008 (branch, snapshot, close). Not needed until a pack needs a third medium. | Later. v4 already has two media: git, and none with snapshots. |
| 3. A domain field in settings | A project says "I am a legal project" | Small, but wrong shape: one personal project mixes health, law and everyday works. Discovery already records a domain label for the KB doc-set. | Not now. Later, a different shape: a list of enabled packs (opt-in), default software only. |

The domain belongs to the kind (and so to the work), not to the project. What a project needs later is an
enable list, mainly so high-stakes packs are off until chosen.

### 7a. Must be in v4.0.0 so it is not a dead end

These are small text changes to Feature 009 (and one decision). They add no skill, no agent and no
non-software content.

1. **A place for extra kinds that the installer will not delete.** The shipped catalog lives at
   `.aid/runtime/templates/kind-catalog.yml`. The decision on deletion says the installer also deletes unrecorded
   files under `.aid/runtime/`, because the installer owns that folder (`.aid/knowledge/decisions.md`, section
   "D9 — Deletion bounded by the install manifest"). So a pack placed there would be removed by `aid update`. State that
   readers read the shipped catalog first and then every file in `.aid/kinds/` (a user-owned folder, like
   `.aid/connectors/` and `.aid/design/`). Additive only: a user file can add kinds, not change a shipped
   one. CONFIRMED for the deletion rule; LIKELY for the folder name, which is a proposal.
2. **An optional `domain` on every kind, default `software`.** Kind names stay unique across all packs; the
   catalog check enforces it. This prevents the name collisions in section 3.4 and lets routing filter.
3. **Let any existing skill take a kind, not only `brainstorm` and actions.** Change the catalog check so
   `taken_by` may name `review`, `research` and `report`. Review is the dominant verb in law and health, and
   those three skills need the kind's `ask` and `checks`.
4. **Say readers ignore fields they do not know, and keep them on update.** This lets packs add `risk`,
   `limits`, `sign_off` and `release` later without a catalog version change. Reserve those four names in the
   field table with the note "not read in v4".
5. **Keep software words out of the action layer.** In the action rows and skill descriptions, say "a thing"
   or "a work product" unless the meaning truly needs "code", and put code-specific rules in the software kinds
   (for example, the "tests unchanged" sentence of refactor belongs in the software kinds' `update` notes).
   The words are set at build, so this costs nothing now and avoids a rewrite later.
6. **One sample conversation that proves the door is open.** In a project with no repository, the request
   "tidy my monthly budget sheet; no number may change" must: reach the refactor reading by meaning, ask no
   software question, mention no PR, run its checks, and close the work done. It uses only what v4 already
   builds (the no-git close and snapshots), so it passes without any non-software kind.
7. **A maintainer decision on identity (section 7c)**, recorded in `decisions.md`, so the documentation pass
   (which already rewrites `README.md`, `docs/` and the site) can use the true sentence instead of repeating
   "for building software".

Not needed in v4.0.0: the medium abstraction, the enable list, new verbs, new task types, a release close,
any domain pack, any change to settings.

### 7b. Can be a later work (roadmap items), in this order

1. **Pack format and distribution.** A pack is a folder: its kinds file, a domain definition (default medium,
   release acts, sign-off roles, disclaimer text, default work-folder setting), its checklists and checks, its
   KB table row, and an optional agent persona. Installed through the manifest. Pack review is needed before
   install, because a malicious pack is an attack (section 6, item 17).
2. **High-stakes handling.** Read `risk`, `limits` and `sign_off`. A high-risk kind forces `full` depth (the
   existing "security-sensitive" rule widened to "high-stakes"), inserts the disclaimer once per document,
   asks the sign-off question, and keeps the pack off until the user enables it (settings list of packs, default
   software only).
3. **The release step.** A close mode `release`, run by the `aid-operator` agent, for send, publish, file and
   pay, with the three-class approval of section 5.5 and a sign-off record (who, when, which version). Add a
   "communicate" action if usage shows the plain-words route is not enough.
4. **The work medium.** Name `git`, `snapshots`, `external` (a document tool reached through a connector) and
   `none` when the first pack needs `external`. Move all medium differences behind it.
5. **Privacy classes.** A `sensitivity` on kinds; sensitive kinds default the work-folder setting to
   `keep-local`, are never written to a committed KB document, and never pushed.
6. **Task types and executors for checking.** A checking type that is not run by the developer agent;
   possibly editor and reviewer personas.
7. **First packs, lowest risk first.** Productivity and everyday (low risk, high volume, they exercise the
   release step); then media and arts (rights, disclosure, authorship); last health and law (professional
   sign-off, regulation), and consider whether AID ships these itself or leaves them to licensed
   professionals' own packs.
8. **Conversation samples per pack**, including refusal samples: the health pack declines to diagnose, the law
   pack asks the jurisdiction and opens every citation, no pack sends anything without the exact approval.
9. **KB table rows** for the new domains (for example `health-personal`, `legal-matter`, `household`).

### 7c. Where a domain conflicts with the KB's statement that AID is for building software

CONFIRMED statements that say "software":

- `.aid/knowledge/README.md`, opening paragraph: calls AID a full-lifecycle methodology for building software
  with agents.
- `.aid/knowledge/capability-inventory.md`, opening paragraph: the same sentence.
- `.aid/knowledge/architecture.md`, the first item of "what AID is": "a full software-development lifecycle";
  and it cites the root `README.md` and `docs/aid-methodology.md` as evidence.
- Root `README.md` and the project line in `CLAUDE.md`: the same sentence.
- The discovery domain recorded for AID itself: `hybrid:methodology-tooling+software-cli`
  (`.aid/knowledge/STATE.md`).

CONFIRMED statements that say otherwise:

- `canonical/aid/templates/kb-authoring/domain-doc-matrix.md`, "What this artifact is": says AID helps with
  any kind of digital work (software, data, content, research, design, operations, tooling), that a fixed
  software taxonomy is wrong for non-software work, and lists curated rows for content, research, design and
  operations.
- `canonical/aid/templates/kb-authoring/concern-model.md`, "The domain-agnostic dimension spine": the same
  position.
- The requester's own framing for this question: a methodology for doing work with agents, which is broader.

So the shipped KB tooling already claims more than the KB's identity text. This is a contradiction between
sources (the kind the KB's review rule on contradictions covers), independent of this research.

Three positions the maintainer can take:

| Position | Effect |
|---|---|
| A. AID is only for software | Remove the "any kind of digital work" wording from the two templates; drop this whole idea |
| B. AID is built for software first; its pipeline and catalog are not limited to it (recommended) | Edit the identity lines to say so. Non-software stays unsupported until a pack ships, and the sentence says "first supported domain", not "only". |
| C. AID is a general method for work | Rewrite all identity lines and promise packs; this raises the bar for safety claims before any pack exists. Not recommended for v4.0.0. |

Other conflicts a domain pack would raise with current KB or requirements text:

- Building is described as executing and testing, and a task is "Done only after its tests pass"; both assume tests. The pack version is
  "done only after every check has evidence or a named waiver" (needs a one-line reading of `tests`).
- The default `push` for the work folder conflicts with private data (section 5.2).
- The KB document list (architecture, technology stack, module map, coding standards) is software-flavoured;
  the domain table already maps other domains, so this is a doc-set question, not a contradiction.
- `size-and-route` depth rule names "security-sensitive" work only; high-stakes health or law work needs the
  wider wording (7b item 2).

---

## 8. Limits of this research

- Web sources: several hosts did not resolve from here (the OpenAI policy page, the Agent Skills site, a law
  firm site), so those items rest on search summaries and are tagged. Counts, dates and sanction amounts in
  secondary sources are UNCERTAIN.
- I did not read the laws or the guidance documents themselves. Section 5.3 lists the practical rules those
  sources point to; it is not legal or medical advice, and a pack author must have the actual rules checked
  by a qualified person for each place served.
- The "typical works" lists are LIKELY, built from product launches and general use, not from usage data.
- I read the requirements as they stand now. Feature 009 is written, not built, so the catalog fields may
  still change.
- No connector is registered in `.aid/connectors/INDEX.md`, so no connector evidence was gathered.
