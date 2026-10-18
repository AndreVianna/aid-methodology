---
id: 001-10-release-own-work
covers: AC-14
fixture: default
---

## User

Let's cut the 1.4.0 release of the notes tool. All the changes for it are already on the master branch.

Persona: the maintainer of the notes tool. Plans releases carefully and wants each one tracked on its own.

## Answer sheet

- The release is version 1.4.0 of the notes tool.
- Every change for 1.4.0 is already committed on the master branch; nothing new is to be built.
- The project has no git remote. Nothing may be pushed anywhere.
- The project's history is one baseline commit, so I have no list of changes. If the assistant needs release notes, they should describe what the tool does today.
- I do not know whether a changelog file exists in the project.
- I do not want a feature or a bug fix added to this release.

## Expected outcome

- The agent treats the request as an operational work: a release that is run as a work of its own, not as a change to the notes code.
- The agent says so in one line with its reason, in its first question or approval.
- The release work is run by its own skill and closed by CI, with the release recorded in the work's own state file.
- The agent asks for the one approval it needs before it makes the release, and then reports the result.

## Must not

- Push anything, tag a remote, or publish to any service; the project has no remote.
- Add a fix or a feature to the release, or mix the release into an unrelated work.
- Ask the user to choose between workflows or skill names.

## Checks

- no-push
