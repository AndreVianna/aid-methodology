# task-010 — a scope line refused, and why

One of task-010's three scope lines rests on a false premise. It is recorded here rather than
carried out, because carrying it out would have written a wrong statement into the Knowledge Base.

## The line

> Stop the grade domain naming `F`, which `grade.sh` cannot emit.

## Why it is false

`grade.sh` **can** emit `F`. It is the very first thing the script does:

```
$ sed -n '78,82p' .cursor/aid/scripts/grade.sh
if [[ "$NON_FUNCTIONAL" -eq 1 ]]; then
  echo "F"
  [[ "$EXPLAIN" -eq 1 ]] && echo "non-functional flag set: build/run failed or produced no usable output" >&2
  exit 0
fi

$ bash .cursor/aid/scripts/grade.sh --non-functional /dev/null
F
```

It is also already documented as reachable, in a KB document this task did not touch:

```
$ grep -n 'non-functional' .aid/knowledge/quality-gates.md
163:a ledger — the reviewer must create one). A `--non-functional` flag forces `F`.
430:# Force F for a non-functional artifact (build/run failed)
431:bash .claude/aid/scripts/grade.sh --non-functional
```

So removing `F` from the documented domain would have made `artifact-schemas.md` contradict both
`grade.sh` and `quality-gates.md`, and would have left a reader unable to explain a real `F`.

## What the premise was probably reaching for

The whole domain, exercised rather than read:

```
$ for s in CRITICAL HIGH MEDIUM LOW MINOR; do for n in 1 3 9; do  # ledger with n rows at severity s
    bash .cursor/aid/scripts/grade.sh "$ledger"; done; done
  (empty)   -> A+
  CRITICAL  x1 -> E+   x3 -> E   x9 -> E-
  HIGH      x1 -> D+   x3 -> D   x9 -> D-
  MEDIUM    x1 -> C+   x3 -> C   x9 -> C-
  LOW       x1 -> B+   x3 -> B   x9 -> B-
  MINOR     x1 -> A    x3 -> A   x9 -> A-
```

Sixteen values: `A+ A A- B+ B B- C+ C C- D+ D D- E+ E E- F`.

The real defect in the old text was never `F` itself. It was the notation `Valid: A+..F`, which
hides two things that actually bite a reader:

1. there is an **`E`** band between `D` and `F`, which almost nobody expects; and
2. **`F` is not reachable by counting findings** — only by the `--non-functional` flag — so a
   ledger alone can never produce it.

## What was done instead

`artifact-schemas.md § settings.yml` now enumerates all sixteen values, names the `E` band, and
states that `F` is flag-only. `F` is kept, because it is real.

## The general point

A scope line is an instruction, not a fact. This one was checkable in two commands, and it was
wrong. Executing it faithfully would have produced a confidently incorrect Knowledge Base, and the
error would have been invisible afterwards — the doc would simply have read as if `F` did not
exist. Where a task's premise and the source disagree, the source wins and the disagreement gets
written down.
