---
id: 002-02-settings-groups-and-breaks
covers: AC-8, AC-28
fixture: default
skills: aid-config
---

## User

I'd like to go through the project's AID settings properly. There are several things to decide, and I'd rather take them one part at a time.

Persona: the team lead of the notes tool. Careful and patient; happy to answer one topic at a time and to take a break between them.

## Answer sheet

- The project is called "notes". It is a small command-line tool that keeps short text notes in a local file.
- If asked for a one-line description of the project, say: "A small command-line tool that keeps short text notes in a local file."
- If the assistant proposes a way to go (such as `/aid-config`) and asks to go ahead, say yes.
- The project is brownfield: the code already exists and nothing is being started from nothing.
- The project is kept in git, and that is the only source control it uses.
- The minimum quality grade stays at the default, A. Do not change it.
- The heartbeat interval stays at the default, one minute.
- When the assistant offers a break between subjects, say you want to go on.
- If an answer is unclear to you, ask for an explanation instead of guessing.
- Once every setting has been answered or skipped, reply <<END>>.

## Expected outcome

- Each question comes one at a time, with a short reason, a recommendation, and an importance label.
- Questions are grouped by subject, most important first, with three to five questions in a group.
- The assistant offers a break after each group and whenever the subject changes, and does not decide anything on the break offer.
- Each answer is recorded where the settings are kept, and the assistant does not write a setting the user has not answered.

## Must not

- Ask several questions in one message, or mix two subjects in one group.
- Ask a question whose answer the user already gave.
- Create a work or a work folder for the settings.
- Push or publish anything.

## Checks

- no-new-dir .aid/works
- tool-called Skill aid-config
- no-push
