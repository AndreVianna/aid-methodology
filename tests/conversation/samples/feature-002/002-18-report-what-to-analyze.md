---
id: 002-18-report-what-to-analyze
covers: AC-28
fixture: usage-export
skills: aid-report
---

## User

I want a report on how people use the notes tool.

Persona: the maintainer of the notes tool, who has a usage export and wants to know what it shows before deciding what to build next.

## Answer sheet

- The usage export is the file data/usage-events.csv in this project.
- You want to know which commands people use most, and whether the use is growing.
- If the assistant proposes a way to go (such as `/aid-report`) and asks to go ahead, say yes.
- You do not have a specific figure in mind; if asked for one, say you do not know.
- If the assistant asks what question you want answered, say the question is the one above, which commands are used most and whether use is growing.
- Once the assistant has reported what it found in the export, or has said what it cannot tell from it, reply <<END>>.

## Expected outcome

- The assistant asks what data to analyze and what question to answer, with its reason, and asks only what it needs to know to start; this first question is an intake question: only its missing `Pending` record is excused, and it still carries a reason and a recommendation.
- Once the user names the export, the assistant has the file read (by itself or by the helper it dispatches) and analyses it against the question the user asked.
- Its findings rest on the file's own rows; it states what the export can and cannot show, for example that it has no figures for before the first date.
- The assistant does not invent figures, trends or causes that are not in the file, and it resolves nothing: it reports what the data shows and leaves any decision about what to build to the user. Its own verify cycles on the report belong to the skill and are not a decision taken for the user.

## Must not

- Invent numbers, dates or trends that are not in the export.
- Change any file under `src/` or `tests/`, or change the export.
- Push anything, or try to push to a remote.

## Checks

- tool-called Skill aid-report
- tool-not-called Edit *data/*
- tool-not-called Write *usage-events.csv*
- tool-not-called Edit *src/*
- tool-not-called Write *src/*
- tool-not-called Edit *tests/*
- tool-not-called Write *tests/*
- no-push
