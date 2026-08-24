# task-033 — every site classified before it was touched

The test, from task-031: **an instruction is executed, documentation is read.** A literal path in
an instruction silently hardcodes a scope. A literal path in documentation is the concrete example
that makes the abstraction legible, and replacing it with a token costs the reader the thing the
example is for.

Classified first, converted second. The order matters: deciding while editing is how a
documentation site gets tokenised because it looked like the others.

## The sites

| File | Site | Classification | Reason |
|---|---|---|---|
| `aid-discover/state-fix.md` | the unconditional read at Step 0 | **instruction** | it is the read that starts the FIX state; hardcoding `discovery.md` is what made this state unusable by any other scope |
| `aid-discover/state-done.md` | the cleanup `rm -f` | **instruction** | it deletes a file; deleting a literal is deleting the wrong file when the scope differs |
| `aid-update-kb/state-done.md` | the cleanup `rm -f` | **instruction** | same |
| `aid-update-kb/state-review.md` | the four per-mandate ledgers, the merge target, the `grade.sh` call, the Step 5 read — 9 sites | **instruction** | each is executed; each is a scope substituted into a shared template, which is exactly what a parameter is for |
| `aid-update-kb/state-review.md` | the passage explaining why Step 5 does not delegate to `aid-discover` | **documentation** | it explains a design decision to a reader; it executes nothing |
| `aid-discover/state-review.md` | 50 sites | **already parameterised** | all use `{{SCOPE}}`; untouched by this task |

Instruction sites in this group: **13, now all `{{LEDGER}}`**. Literal count in the instruction
surface: **0**, measured at 13 before.

## The documentation site was falsified by the conversion, and that is the finding

The passage classified as documentation said:

> `state-fix.md` has no ledger-path parameter of any kind (its Step 0 unconditionally hardcodes
> `Read .aid/.temp/review-pending/discovery.md`, with no `{{SCOPE}}`/`{{LEDGER}}` token anywhere in
> the file)

It was true when written and this task made it false, because the file it describes is the file
this task parameterised. Classifying it as documentation and leaving it alone would have preserved
a literal path *and* a claim that had just stopped being true — the worse of the two outcomes,
since a reader would have trusted the explanation.

So it was rewritten in the same pass. This is the same failure the wave-3 gate caught one wave
earlier: changing a thing without asking who else describes it. Here it was found by classification
rather than by a reviewer, which is the point of classifying before touching.

## Retiring the duplicated FIX loop — out of scope, named not carried

`aid-update-kb` Step 5 duplicates `aid-discover`'s FIX loop. It did so for a reason that no longer
exists: delegating would have run a loop hardcoded to `discovery.md`. Now that `state-fix.md` takes
`{{LEDGER}}`, delegation is possible and the duplication is a choice.

**Retiring it is explicitly out of scope for task-033** and is recorded here as a follow-up rather
than silently carried. It is a behaviour change to a state machine, not a path substitution, and it
wants its own task and its own gate. What this task did is remove the reason the duplication was
mandatory; what it deliberately did not do is act on that.
