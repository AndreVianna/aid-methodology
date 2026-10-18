# Filter the note list by tag

## 1. Objective

Let a user list only the notes that carry a given tag, so a long list can be narrowed to one topic.

## 2. Problem Statement

`notes list` prints every note. With many notes, the user scrolls past unrelated notes to find the ones on one topic.

## 3. Users & Stakeholders

- The person who keeps notes on several topics in one notes file.

## 4. Scope

- A `--tag` option on `list`, and a `--tag` option on `add` that stores tags with the new note.
- Out of scope: editing the tags of an existing note, and suggesting tags.

