# Seeded-defect corpus

Twenty rows, the size task-036 settled on and for the reasons recorded in
`../../../.aid/works/work-013-review-stack-completion/deliveries/delivery-002/tasks/task-036/RESEARCH.md`
§ Corpus size: twenty is the smallest size at which a per-rule-set breakdown has more than a couple
of defects per scope, and forty is where fixtures stop being flat files.

Each row's `signature` appears in its own fixture and **nowhere else in the reviewed tree**. That
is what makes a recall match unambiguous: a signature that also matched real content would score a
review as having found a seeded defect when it had found something else, and would make the class
sweep chase a phantom.

Two files inside this corpus necessarily also carry signatures, and neither is reviewed content:
this catalogue, which indexes them, and `seed-ledger.md`, which must name `D01` for the sweep to
have a second instance to find. Stated precisely because the earlier wording said "nowhere else in
the repository", which is false of both — a corpus whose own index falsifies its uniqueness claim
would fail the first assertion anyone ran.

`--` is the absent marker throughout. No cell contains a pipe.

**The `pair` column names the one deliberate collision.** `D01` and `D02` share a class
(`stale-count`) and a signature family, so a class sweep that fixes one has a genuine second
instance to find. `D20` is also `stale-count` but is a distinct signature family and is not part of
the pair — it exists so the class has a member the pair does not exhaust.

| id | class | band | signature | fixture | pair |
|---|---|---|---|---|---|
| D01 | stale-count | MINOR | `ZQ7-STALECOUNT-ALPHA` | `defects/D01.md` | D02 |
| D02 | stale-count | MINOR | `ZQ7-STALECOUNT-BETA` | `defects/D02.md` | D01 |
| D03 | bare-citation | LOW | `ZQ7-LINEREF-HANDLER` | `defects/D03.md` | -- |
| D04 | bare-citation | LOW | `ZQ7-POSITIONREF-RUNNER` | `defects/D04.md` | -- |
| D05 | dangling-path | MEDIUM | `ZQ7-MISSINGFILE-CONFIG` | `defects/D05.md` | -- |
| D06 | dangling-anchor | MEDIUM | `ZQ7-MISSINGHEAD-README` | `defects/D06.md` | -- |
| D07 | contradiction | HIGH | `ZQ7-GATEBLOCK-CLAIM` | `defects/D07.md` | -- |
| D08 | contradiction | HIGH | `ZQ7-APPENDONLY-CLAIM` | `defects/D08.md` | -- |
| D09 | history-section | LOW | `ZQ7-HISTORY-SECTION` | `defects/D09.md` | -- |
| D10 | unreachable-instruction | HIGH | `ZQ7-UNREACHABLE` | `defects/D10.md` | -- |
| D11 | wrong-exit-code | MEDIUM | `ZQ7-EXITCODE` | `defects/D11.md` | -- |
| D12 | vacuous-check | HIGH | `ZQ7-VACUOUS` | `defects/D12.md` | -- |
| D13 | undeclared-dependency | MEDIUM | `ZQ7-UNDECLARED-DEP` | `defects/D13.md` | -- |
| D14 | severity-without-why | LOW | `ZQ7-NOWHY` | `defects/D14.md` | -- |
| D15 | paraphrased-quote | MEDIUM | `ZQ7-MISQUOTE` | `defects/D15.md` | -- |
| D16 | locale-dependent-sort | MEDIUM | `ZQ7-LOCALE-SORT` | `defects/D16.md` | -- |
| D17 | silent-noop | HIGH | `ZQ7-SILENT-NOOP` | `defects/D17.md` | -- |
| D18 | hardcoded-scope | LOW | `ZQ7-HARDCODED-SCOPE` | `defects/D18.md` | -- |
| D19 | unrunnable-evidence | MEDIUM | `ZQ7-UNRUNNABLE` | `defects/D19.md` | -- |
| D20 | stale-count | MINOR | `ZQ7-TEMPLATECOUNT` | `defects/D20.md` | -- |
