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

## 5. Functional Requirements

- FR-1: `list --tag <word>` prints only the notes whose tags include the word.
- FR-2: `add --tag <word>` stores the word with the new note; a note may carry more than one tag.
- FR-3: `list` without `--tag` prints every note, as it does today.

## 6. Non-Functional Requirements

- The listing keeps the columns it prints today.

