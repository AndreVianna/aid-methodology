# task-070 EVIDENCE -- `INDEX.md` regenerated from the settled Knowledge Base

feature-006 §7's KB table, row `INDEX.md`. Closes the `INDEX.md` clause of BLUEPRINT criterion
**9**.

## 1. A regeneration, run last

`INDEX.md` is a final-state summary of the Knowledge Base, not a source. Every document it
summarises is final at this point: the two conditional documents delivery-001 created, and the
eight documents tasks 065 through 067 edited.

```
$ bash canonical/aid/scripts/kb/build-kb-index.sh --root .aid/knowledge --output .aid/knowledge/INDEX.md
OK: Wrote .aid/knowledge/INDEX.md (19115 bytes, 65 lines)
```

The script requires both `--root` and `--output`; a bare invocation exits with an argument error
rather than defaulting, which is worth recording because the DETAIL cites it without its flags.

Bytes **did** change, so this was a real regeneration rather than a no-op -- the eight edited
documents' frontmatter had moved.

## 2. Coverage and idempotence

```
doc-set members summarised:                 21 of 21
delivery-001's two new documents indexed:   roadmap.md yes, backlog.md yes
$ bash tests/canonical/test-build-kb-index.sh                    PASS
$ <second identical run>                    byte-identical -- idempotent
```

The resolved doc-set is **21** entries, derived from `.aid/settings.yml` rather than asserted --
19 before this work, plus `roadmap.md` and `backlog.md`, which delivery-001's `create` runs
appended under CC-1 and CC-2, each with presence `required`. (A first count read 20 because the
pattern used to enumerate them was lowercase-only and missed `README.md` -- corrected before it
reached the record.)

It was **not** hand-patched. A hand-edited index is neither current nor reproducible, and the next
regeneration overwrites it.
