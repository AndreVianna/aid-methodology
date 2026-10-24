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

A fault report does not by itself settle whether the user wants a repair or only findings. When both
are plausible, keep both readings for SHOW-READING; do not silently turn "look into it" into permission
to change code. Show the two outcomes in plain words, the recommended one first, with the observed
problem as the reason for that recommendation.

## 5. Hand the reading on

Pass the reading, the observable effect that supports it, the matched row (if any) and the
outcome to `size-and-route.md` section 1, which sizes it. SKILL.md steps 3 and 4 then size and show the
reading, and the user answers, except when `size-and-route.md` section 6 starts the skill at once and
nothing is asked. After that, an action-skill reading goes to that skill (SKILL.md steps ACTION-HANDOVER and
START-ACTION), and any other reading goes to `start-or-resume.md` section 3, which finds or creates the work,
and then to its section 6, which records the `intent:` block.
