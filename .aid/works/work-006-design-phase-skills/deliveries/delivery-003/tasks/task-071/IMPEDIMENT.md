# task-071 IMPEDIMENT -- `kb.html` needs a full authored GENERATE, which is a run of its own scale

**State: Blocked.** Not a failure and not a missing capability -- a scoped one. The task is a long
**authored** run rather than a command, which its own DETAIL says outright: *"it is a long authored
run, not a command ... Size it accordingly."*

## 1. The scale -- corrected, because the first sizing here was wrong

**An earlier revision of this file claimed the artifact is "~3.9x what the task was sized against",
comparing the DETAIL's recorded 178 KB against the current 671 KB. That comparison is invalid: both
are whole-file figures, and the file grew almost entirely in its *mechanical shell*, not in
authored content.** Measured properly:

| Component | Bytes | Share | Who produces it |
|---|---|---|---|
| inlined `<script>` (lightbox etc.) | 492 KB | **72%** | assembler / shell -- mechanical |
| inlined `<style>` | 35 KB | 5% | assembler / shell -- mechanical |
| **`<section>` content** | **157 KB** | **23%** | **the LLM authors this** |
| -- of which inline `<svg>` | 20 KB | | |

`state-generate.md` §5 is explicit about the split: *"The LLM authors the per-component content of
each section file ... The LLM does NOT hand-write the page HTML shell, section ordering, or
assembly logic -- those are mechanical and handled by the assembler from the manifest."*

So the authoring load is **157 KB across 21 sections** -- median **4.6 KB** per section, largest
25 KB -- which is comparable to, not four times, what the 24m20s run produced. The honest blocker
is that this is a **multi-turn authoring job**, not that it is disproportionate to the task's own
sizing.

**And attempting it is inherently safe, which the earlier revision also failed to say.** GENERATE
stages everything into `.aid/.temp/summarize/summary-src/`, which is **gitignored** scratch, and
`assemble.sh` writes `.aid/knowledge/kb.html` only as its final step. An incomplete attempt
therefore leaves `kb.html` byte-untouched -- there is **no** degraded-artifact risk, and the
earlier claim that attempting it "would produce a degraded file" was wrong.

## 2. What is stale, measured rather than recalled

```
$ grep -c '75 skills'     .aid/knowledge/kb.html   -> 3
$ grep -c '58-row'        .aid/knowledge/kb.html   -> 2
$ grep -c '34 verb-first' .aid/knowledge/kb.html   -> 2   # CORRECT today, and must survive the run
```

The file was already two roster generations stale before this work began. After the regeneration the
first two must read **0** and the third must still be **>= 1** -- the run has to reproduce 34, not
move it.

## 3. Hand-patching those five strings is forbidden, and was not done

The task is explicit: *"`kb.html` is not hand-patched. Hand-editing an assembled artifact makes it
neither current nor reproducible, and the next assembler run silently overwrites the edit."* Five
`sed` substitutions would have made the criterion's greps pass while leaving the other twenty
sections describing a 75-skill roster -- a file that looks current and is not. `git diff --exit-code
-- .aid/knowledge/kb.html` is clean; nothing was touched.

This is also the only route that closes mode **M6**: the retired count guard's `EXT` filter admitted
no `.html`, so no `CLAIMS` entry could ever reach this file, and task-069 correctly did not try.

## 4. The premise that this file could not be regenerated is false, and that correction did land

`tech-debt.md` `W1-11` claimed the assembler's input tree no longer exists. It is wrong, and
task-067 records the correction in the KB: GENERATE reads `.aid/knowledge/*.md` **directly** and
**writes** `.aid/.temp/summarize/` itself during the run. That path is gitignored scratch, so its
absence between runs is the expected end-state of the previous run, not a missing input --

```
$ test -d .aid/.temp/summarize   -> absent (expected)
$ grep -c 'stale rather than unregenerable' .aid/knowledge/tech-debt.md   -> 1
```

So the blocker is **cost**, not feasibility. Everything the run needs is in place and the
Knowledge Base it reads is final: tasks 065-067 settled the eight documents and task-070
regenerated `INDEX.md` last of all.

## 5. What this leaves open, stated plainly

- **BLUEPRINT criterion 10 is not closed.** It should be recorded as open at the delivery gate, not
  quietly counted.
- **`tech-debt.md` `W1-11` keeps its `kb.html` survivor.** task-067 deliberately did not close that
  half, precisely because it closes only when a regeneration lands. That decision now holds.
- **V1 is unaffected either way.** Playwright is absent from the summarize package
  (`require.resolve('playwright')` fails), so `validate-visuals.mjs` is SKIPPED and the visual gate
  is an orchestrator step. The criterion already says so and promises no automated gate.

## 6. Runbook

1. Confirm the Knowledge Base is final (it is -- tasks 065-067, then task-070's `INDEX.md`).
2. Run `/aid-summarize`. Budget a long authored GENERATE: 24m20s at 178 KB, and the file is now
   671 KB.
3. Let GENERATE write `.aid/.temp/summarize/summary-src/` -- skeleton, per-doc sections,
   `section-manifest.txt` -- then `canonical/aid/scripts/summarize/assemble.sh` concatenate it into
   `.aid/knowledge/kb.html`.
4. Assert `grep -c '75 skills'` -> **0**, `grep -c '58-row'` -> **0**, `grep -c '34 verb-first'`
   -> **>= 1**, and that `section-manifest.txt` matches the resolved 21-entry doc-set.
5. Record the **orchestrator-run** V1 verdict and add a `## Summarization History` row to
   `.aid/knowledge/STATE.md` naming the output.
6. Close `W1-11`'s `kb.html` half in `tech-debt.md`; `W1-2`'s prose survivor stays open.
