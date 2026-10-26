---
kb-category: primary
source: hand-authored
objective: The one-page card of {project}, covering what it is, its stack, how to build, test and lint it, where things live, and the rules that never bend.
summary: Read this first in every session; open INDEX.md only to find a specific KB document.
sources: [{path/to/build-or-package-manifest}, {path/to/ci-config}]
---

# {Project} -- Project Card

<!-- Delete this comment when filling. One page, about 60 lines in all. Commands run from the repo root and must work as written.
     Say only what an agent needs before its first edit; the detail stays in the KB doc the last section points to. -->

## What it is

{Two lines at most: what the project is, and who uses it.}

## Stack

- {Languages, frameworks and runtimes, each with the version its manifest declares.}

## Commands

Run from the repo root.
- Build: `{command}`
- Test, all: `{command}`; one: `{command with a file or name placeholder}`
- Lint: `{command}`
- {Any other command a change needs, e.g. regenerate}: `{command}`

## Where things live

- `{path/}`: {what is in it, and whether it is edited by hand or generated.}

## Rules that never bend

At most 10, one line each, each naming what enforces it (a test, lint or hook) or the KB doc that explains it.

1. {Rule} (`{check or doc}`).

## Detail

- {A question this card cannot answer}: `{doc}.md`.
