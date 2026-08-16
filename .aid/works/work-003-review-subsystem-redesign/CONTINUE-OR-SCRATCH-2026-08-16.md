# Continue vs scratch — strategic call

**Date:** 2026-08-16  
**Question:** Are we still building an effective *and simpler* review system, or is work-003 too mixed to continue?  
**Prior decisions:** master is base; T1→T2→T3; migrate catalog rows; default-delete scripts.

---

## 1. Original intent (still good)

From `REQUIREMENTS.md` Objective:

1. **Make the grade mean something** — less feel, declared criteria, honest gaps.
2. **Stop copy-pasting review** — one shared review capability.

Six problems named: contradictory severity, opinion license, no “cannot review,” no resume, duplicated logic, (plus later) no recall denominator.

**That intent is still right.** Master did not retire it.

---

## 2. What is already true without finishing work-003

| Intent piece | On master today? |
|---|---|
| Declared criteria (not invent) | **Yes** — cascade |
| Cheaper re-review | **Yes** — VERIFY/HUNT + cost meter |
| Shared dispatch shape | **Mostly** — per-skill briefs + dispatch |
| One review entry | **Mostly** — `/aid-review` exists; rivals also exist |
| Severity = judgment + why (B5c) | **No** — cascade still supplies `severity:`; lookup cells still on branch |
| Say “cannot review” (gaps) | **Partial** — “no invented criteria”; not full interrupt/register |
| Resume / claim coverage / clean context | **No** (file hunt ≠ claim worklist; I7 unmeasured) |
| Recall / class sweep / coverage gates | **No** |

So: **half the original problem is solved by newer work.** Continuing work-003 as designed would *re-solve* solved problems with a second mechanism.

---

## 3. What “continue work-003” actually looks like on disk

Measured rivals **right now**:

| Rival | Count |
|---|---|
| Review skills | 3 (`aid-review`, `deep`, `light`) |
| Rubric catalog files | 10 (all still carry `Severity`) |
| Step-2 lookup cells | 48 |
| Call sites still CHAIN to deep-review | 8 |
| Extra scripts (default-delete) | 7 |
| Work pipeline artifacts | ~239 files / 2.3M |
| `aid-review` SKILL still says | 8-column ledger |

Plus: 12 deliveries marked **Done** that shipped some of those rivals, and 16 more SPECs written for a world before cascade/VERIFY/HUNT.

**Continuing inside that vehicle** means every next task must say “ignore the Done stamp / ignore the SPEC / ignore the catalog.” That is not simplicity. That is archaeology.

---

## 4. Effective vs simple

| Path | Effective? | Simpler? |
|---|---|---|
| **Execute old deliveries with fold notes** | Risky — easy to reintroduce rivals | **No** — two histories forever |
| **T1→T2→T3 inside work-003, SPECs dead** | Yes if disciplined | Better, but work folder + Done stamps still confuse agents |
| **Stop work-003 as vehicle; new thin work from intent + master** | Yes — only unsolved problems | **Yes** — one story, one stack |
| **Hard scratch (throw away all learnings)** | Wasteful | False simplicity — re-learns Q32/I7/recall the hard way |

---

## 5. Recommendation

**Stop work-003 as the *execution vehicle*. Do not hard-scratch the *intent* or the audit.**

Concrete shape:

1. **Close / supersede** work-003’s delivery plan (001–028 as living work). Keep the folder as **history + evidence** (STATE, audit, merge notes). Do not Detail from old BLUEPRINTs.
2. **Open a thin successor work** whose requirements are only what master still lacks:
   - **Align:** one path on disk (delete deep/light, catalog loader, stale CHAINs); migrate useful catalog rows into cascade once.
   - **Gaps:** settings/frontmatter, one grade backend, kb.html, BLUEPRINT/specify, citations — only if still missing after Align.
   - **Judge & measure:** B5c why-line, gap interrupt (if still needed), I7 clean context, recall + class sweep.
3. **Default-delete** the seven scripts unless the successor work’s cost-meter case brings one back.
4. First shippable outcome of Align: **one review system on disk** that matches master docs — that *is* the simplicity win.

That is **not** “abandon months of thought.” It is **refuse to keep building on a contradictory map.**

---

## 6. When I would say “continue work-003” instead

Only if you need the same work id for process/audit reasons *and* you accept a full PLAN rewrite that marks 001–028 superseded in one page. Functionally that is the successor work wearing the old jersey — higher confusion for agents reading Done stamps.

---

## 7. Owner choice

| | Option |
|---|---|
| **A** | Successor work (recommended) — close work-003 plan; new thin work from §5 |
| **B** | Same work id — rewrite PLAN to T1–T3 only; stamp old deliveries Superseded |
| **C** | Keep folding delivery-by-delivery inside current SPECs |

**Recommend A** for effective + simpler. **B** if work-id continuity matters more than clarity.
