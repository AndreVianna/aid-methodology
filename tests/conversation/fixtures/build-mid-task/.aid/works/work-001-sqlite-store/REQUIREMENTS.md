# Keep the notes in a SQLite file

## 1. Objective

Store the notes in a SQLite file instead of the JSON file, so that a long list does not get rewritten on every change.

## 2. Problem Statement

Every command reads and rewrites the whole JSON file. The cost grows with the number of notes.

## 3. Users & Stakeholders

- The person who keeps notes in one notes file.

## 4. Scope

- The store reads and writes a SQLite file in the folder the command runs from.
- Out of scope: moving notes that already exist in the JSON file.

## 5. Functional Requirements

- FR-1: `add`, `list` and `export` work the same on the SQLite file as they do on the JSON file today.

## 6. Non-Functional Requirements

- The command line output does not change.

## 7. Constraints

- Only the Python standard library is used.

## 8. Assumptions & Dependencies

- Python ships with the sqlite3 module.

## 9. Acceptance Criteria

- AC-1: after `add`, `list` prints the new note from the SQLite file.

## 10. Priority

- Must: FR-1.
