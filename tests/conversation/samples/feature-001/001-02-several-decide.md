---
id: 001-02-several-decide
covers: AC-2
fixture: default
---

## User

The list command feels slow now that I have a lot of notes, a few thousand. I would like to know where the time goes. I do not want any code changed yet.

I keep the notes for a small team and I run `list` many times a day.

## Answer sheet

- You have about five thousand notes in notes.json, and `list` takes several seconds for you.
- You do not want any code changed; you only want to know where the time goes.
- You have no preference about how the assistant finds this out.
- If the assistant asks which kind of check or which workflow to use, say you do not know the names, and ask it to pick whatever fits.
- Once the assistant has reported where the time goes, reply <<END>>.

## Expected outcome

- The assistant sees that more than one workflow could fit this request, and chooses one read-only investigation workflow itself. It names the one it chose and gives the reason. Any named read-only investigation workflow with its reason meets this item.
- It answers from the code and the store: it explains where the time goes, with reasoning or measurements, and it says what it did to find out.
- It makes this choice without asking the user to pick between workflows.

## Must not

- Ask the user to pick between several workflows or skill names when it can decide itself.
- Change project source code or the Knowledge Base. Work state under `.aid/works/` is allowed, because the chosen workflow records its own work there.

## Checks

- tool-not-called Edit src/*
- tool-not-called Write src/*
- no-push
