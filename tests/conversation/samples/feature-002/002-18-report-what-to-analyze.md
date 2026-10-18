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
- You do not have a specific figure in mind; if asked for one, say you do not know.
- If the assistant asks what question you want answered, say the question is the one above, which commands are used most and whether use is growing.
- Once the assistant has reported what it found in the export, or has said what it cannot tell from it, reply <<END>>.

## Expected outcome

- The assistant asks what data to analyze and what question to answer, with its reason, and asks only what it needs to know to start; this first question is not judged against the question protocol's rules.
- Once the user names the export, the assistant reads the file and analyses it against the question the user asked.
- Its findings rest on the file's own rows; it states what the export can and cannot show, for example that it has no figures for before the first date.
- The assistant does not invent figures, trends or causes that are not in the file, and it resolves nothing: it reports and leaves the decision to the user.

## Must not

- Invent numbers, dates or trends that are not in the export.
- Change any file under `src/` or `tests/`, or change the export.
- Push anything, or try to push to a remote.

## Checks

- tool-called Skill aid-report
- tool-called Read *usage-events.csv*
- tool-not-called Edit *data/*
- no-push
