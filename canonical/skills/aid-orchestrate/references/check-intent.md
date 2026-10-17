# Check the Reading

Use this after a plain request is matched and before a work is created. It says what kind of
change the request is. The user's words are a hint only: the check against the Knowledge Base
and the code decides.

## 0. Question shortcut

When the request is a question about the project -- interrogative phrasing ("why", "where",
"how", "does", "which", ...) asking for information, and naming no artifact to build, change,
fix, remove, test or document -- it is not a unit of work. Hand it to `start-or-resume.md`
step 1, which answers it and stops the flow.

Otherwise continue with step 1.

## 1. Read the Knowledge Base

Read these four documents in this order:

1. `.aid/knowledge/INDEX.md` -- says which document holds what.
2. `.aid/knowledge/capability-inventory.md` -- what the system already does.
3. `.aid/knowledge/module-map.md` -- where each part lives.
4. `.aid/knowledge/architecture.md` -- how the parts fit together.

Read only the sections the request touches, once the index and the inventory have pointed to
them. When `.aid/knowledge/` does not exist, go on with step 2 alone and say in the reading that
the Knowledge Base is missing. `size-and-route.md` says when Preparation is offered.

## 2. Search the code

Search for what the user named: a symbol, a route, a file, a term from the request. Use Grep and
Glob. Note what already exists and what the change would touch. A name that matches nothing is
itself a fact to report.

## 3. Classify by observable effect

Classify by what a user would see after the change, not by the words the user chose:

| Observable effect | Reading |
|-------------------|---------|
| Broken against what the Knowledge Base says should hold | bug fix |
| Same behaviour, different structure | refactor |
| Existing behaviour changes as the user asked | change |
| Behaviour that does not exist yet | new capability |
| Only documentation changes | document |
| A release, a deploy or a monitor | operational |
| A fact in the Knowledge Base moves (a tool, a decision, a name) | knowledge update |
| A check, prototype, research or review; nothing lands in the project | investigation |

A "refactor" that adds an endpoint changes behaviour, so it is a new capability. The label the
user gave is a hint; the observable effect decides.

The first pass uses the user's broad type as a narrowing hint, and the effect confirms it:
a broken behaviour points at a bug fix; a net-new artifact points at a new capability; a change
or rename of an existing artifact points at a refactor or a change.

## 4. Match the shortcut catalog

Read `.aid/runtime/templates/shortcut-catalog.yml` -- one plain read of a static file. Take the
rows whose `alias_of` is `null`. Compare each row's `intent:` with the request, and break a tie
between rows that share a `verb` by the target artifact the request names.

This is also the kind hook: a request that names a kind of thing (an API, a UI, a job) matches
the row whose `intent:` names that kind.

Record one of three outcomes:

- `single clear winner` -- one row fits the request.
- `several plausible` -- two rows fit; keep the best two.
- `none` -- no row fits, or the request is broad.

## 5. Hand the reading on

Pass the reading, the observable effect that supports it, the matched row (if any) and the
outcome to `start-or-resume.md` step 5, which sizes the work with `size-and-route.md` and
records the reading.
