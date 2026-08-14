#!/usr/bin/env python3
# tests/cost-meter.py -- static token-cost inventory + regression gate for the
# AID instruction surface.
#
# Purpose:
#   Make the methodology's own token cost measurable, so a cost optimization can
#   be proven rather than argued. `collect` walks canonical/ and emits a
#   deterministic inventory of every metric that drives per-session and per-run
#   input cost. `diff` compares an after-inventory to a baseline and fails on
#   un-excused growth -- the same shape as coverage-parity.sh, which proves a
#   test-suite optimization removes no coverage.
#
#   The metrics answer three questions:
#     always-on     What does a session pay before the user types anything?
#                   (skill frontmatter descriptions + host context files -- these
#                   load into every system prompt whether or not a skill runs.)
#     skill-surface When a skill runs, how many instruction bytes can it pull in?
#                   Reported as `self` (its own SKILL.md), `refs` (its
#                   references/ bodies) and `reachable` -- the transitive closure
#                   of .md files the skill and its references NAME. `reachable`
#                   is the metric that catches a doorway skill delegating into a
#                   50KB shared engine that in turn names a dozen templates.
#     template      Weight of each shared template, which every skill naming it
#                   pays, and every sub-agent dispatched with it pays AGAIN
#                   (fresh context per dispatch -- duplication is real cost).
#
#   `reachable` is a static UPPER BOUND on the named-file surface, not a
#   guaranteed runtime read set: a skill may name a file it only reads
#   conditionally. That is the correct bias for a regression gate -- it moves
#   when the instruction surface grows, which is the thing that grew unnoticed.
#
#   This tool lives at the tests/ ROOT, NOT under tests/canonical/, so it is
#   never matched by the `tests/canonical/test-*.sh` glob in run-all.sh and thus
#   never runs itself as a suite.
#
#   The baseline is passed ONLY as a --baseline parameter, and the optional work
#   scan ONLY as --work-dir, so no permanent artifact hard-depends on a transient
#   work folder (CLAUDE.md transient-work-folder invariant).
#
# Usage:
#   cost-meter.py collect --out FILE [--root DIR]
#       Write a sorted, deterministic inventory (<metric>\t<key>\t<chars>) to
#       FILE plus a provenance sidecar (<FILE without .tsv>.meta).
#
#   cost-meter.py diff --baseline FILE (--collect | --after FILE) [--root DIR]
#                      [--tolerance PCT] [--fail-on-new]
#       Compare an after-inventory to the baseline. Exits 1 on any metric that
#       grew by more than --tolerance percent (default 0 -- any growth fails).
#
#   cost-meter.py model [--root DIR] [--from-work DIR] [--shape SHAPE]...
#                       [--features N] [--deliveries N] [--tasks N] [--cycles N]
#       Price one or more PIPELINE SHAPES over identical inputs. Gates are 60-65%
#       of a full-path work's cost, and `collect` cannot see them -- a gate's cost
#       is a multiplication (features x deliveries x cycles), not a file size.
#
#       Shapes:
#         today          a gate per feature after specify, a gate per delivery
#                        after detail; each task grounds on REQUIREMENTS + its
#                        own feature SPEC
#         batched        same documents, gates batched into one per stage
#         folded         the per-feature technical design becomes SECTIONS of
#                        REQUIREMENTS: one oracle document, one gate over it
#         folded-sliced  as folded, but a task reads only the section it traces
#                        to (needs a task -> AC/section traceability field, which
#                        does not exist yet -- a DETAIL currently cites its
#                        delivery, not an acceptance criterion)
#
#       Prefer --from-work so artifact sizes are measured rather than assumed.
#       Indicative in absolute terms; the RATIO between shapes is the signal.
#
#   cost-meter.py report [--root DIR] [--work-dir DIR] [--top N]
#       Human-readable summary. `--work-dir` additionally scans a work folder for
#       artifact bloat (Change Log / history sections) and review-cycle churn.
#       Never used as a gate; `collect`/`diff` are the gate.
#
# Read-only by construction: only Path.stat() / Path.read_text().
# Python 3.11+ stdlib only. Zero third-party deps.

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Chars per token. Crude but deterministic and dependency-free. CHARS is the
# authoritative unit in the TSV (exact, reproducible); tokens are a derived
# convenience for humans reading `report`. A real tokenizer would change the
# constant, not the conclusions -- and a gate on an exact byte count is stronger
# than a gate on an estimate.
CHARS_PER_TOKEN = 4

# Skip generated / vendored trees. profiles/ is a render of canonical/, so
# counting it would multiply every canonical metric by five.
SKIP_DIRS = {".git", "node_modules", "profiles", "site", "dashboard", ".aid"}

# A .md path mentioned inside an instruction file. Anchored on the four trees an
# instruction can legitimately point at, plus bare `references/...` which
# resolves against the naming skill's own directory.
PATH_RE = re.compile(
    r"(?:canonical/(?:skills|agents|aid)/[A-Za-z0-9._/-]+\.md"
    r"|\.aid/knowledge/[A-Za-z0-9._-]+\.md"
    r"|references/[A-Za-z0-9._-]+\.md)"
)

MAX_DEPTH = 6


def read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def frontmatter(text: str) -> str:
    """Return the raw YAML frontmatter block, or '' when absent."""
    if not text.startswith("---"):
        return ""
    end = text.find("\n---", 3)
    return "" if end == -1 else text[3:end]


def description_chars(text: str) -> int:
    """Chars of the frontmatter `description:` value.

    This is the always-on cost: the host loads every skill's description into the
    system prompt so the agent can choose a skill, whether or not one is invoked.
    """
    fm = frontmatter(text)
    if not fm:
        return 0
    m = re.search(r"^description:[ \t]*(>-?|\|-?)?[ \t]*\n?(.*?)(?=\n[A-Za-z][A-Za-z0-9_-]*:|\Z)",
                  fm, re.S | re.M)
    return len(m.group(2)) if m else 0


def resolve(mention: str, owner: Path, root: Path) -> Path | None:
    """Resolve a path mention to a real file, or None."""
    cand = owner.parent / mention if mention.startswith("references/") else root / mention
    return cand if cand.is_file() else None


def reachable(seeds: list[Path], root: Path, max_depth: int = MAX_DEPTH) -> set[Path]:
    """Transitive closure of .md files named by `seeds`, excluding the seeds.

    `max_depth=1` gives only what the seeds name directly. That is the sensitive,
    actionable metric: it moves when THIS skill's own instructions change. The
    full closure is near-saturating (the instruction graph is almost fully
    connected through the shared templates), so it is reported for structure, not
    used as the primary gate signal.
    """
    seen: set[Path] = set(seeds)
    frontier = [(s, 0) for s in seeds]
    while frontier:
        cur, depth = frontier.pop()
        if depth >= max_depth:
            continue
        for mention in PATH_RE.findall(read(cur)):
            nxt = resolve(mention, cur, root)
            if nxt and nxt not in seen:
                seen.add(nxt)
                frontier.append((nxt, depth + 1))
    return seen - set(seeds)


def split_reach(paths: set[Path], root: Path) -> tuple[int, int]:
    """Partition reachable bytes into (instruction, project-data).

    `.aid/knowledge/` content varies per project and includes generated files
    (relationships.md is ~1MB here), so folding it into the instruction metric
    would make the baseline project-specific and drown real instruction growth.
    """
    instr = kb = 0
    for p in paths:
        try:
            rel = p.relative_to(root).as_posix()
        except ValueError:
            continue
        n = len(read(p))
        if rel.startswith(".aid/knowledge/"):
            kb += n
        else:
            instr += n
    return instr, kb


def collect(root: Path) -> list[tuple[str, str, int]]:
    """Build the deterministic (metric, key, chars) inventory."""
    rows: list[tuple[str, str, int]] = []
    skills_dir = root / "canonical" / "skills"

    # --- always-on: paid by every session before any skill runs ---------------
    desc_total = 0
    skills = sorted(p for p in skills_dir.glob("*/SKILL.md")) if skills_dir.is_dir() else []
    for sk in skills:
        desc_total += description_chars(read(sk))
    rows.append(("always-on", "skill-descriptions", desc_total))
    rows.append(("always-on", "skill-count", len(skills)))

    for name in ("AGENTS.md", "CLAUDE.md"):
        f = root / name
        if f.is_file():
            rows.append(("always-on", f"context-file:{name}", len(read(f))))

    # --- per-skill surface ----------------------------------------------------
    for sk in skills:
        slug = sk.parent.name
        refs = sorted(sk.parent.glob("references/*.md"))
        seeds = [sk, *refs]
        rows.append(("skill-self", slug, len(read(sk))))
        rows.append(("skill-refs", slug, sum(len(read(r)) for r in refs)))

        # Depth 1: what this skill names directly -- the sensitive gate signal.
        d1_instr, d1_kb = split_reach(reachable(seeds, root, max_depth=1), root)
        rows.append(("skill-names-instr", slug, d1_instr))
        rows.append(("skill-names-kb", slug, d1_kb))

        # Full closure: structural connectivity, reported in file COUNT rather
        # than bytes. Bytes here saturate near the whole tree for every skill,
        # so the count is the legible signal ("this skill can pull in N files").
        rows.append(("skill-closure-files", slug, len(reachable(seeds, root))))

    # --- shared templates + agents -------------------------------------------
    for sub, metric in (("aid/templates", "template"), ("agents", "agent")):
        base = root / "canonical" / sub
        if not base.is_dir():
            continue
        for f in sorted(base.rglob("*.md")):
            if any(part in SKIP_DIRS for part in f.parts):
                continue
            rows.append((metric, str(f.relative_to(base)), len(read(f))))

    return sorted(rows)


def write_inventory(rows: list[tuple[str, str, int]], out: Path, root: Path) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", encoding="utf-8") as fh:
        for metric, key, chars in rows:
            fh.write(f"{metric}\t{key}\t{chars}\n")

    def sh(*cmd: str) -> str:
        try:
            return subprocess.run(cmd, cwd=root, capture_output=True, text=True,
                                  timeout=10).stdout.strip() or "unknown"
        except (OSError, subprocess.SubprocessError):
            return "unknown"

    meta = out.with_suffix(".meta")
    meta.write_text(
        "# cost-meter baseline provenance (auto-generated -- do not edit)\n"
        f"captured_utc: {datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')}\n"
        f"commit_sha: {sh('git', 'rev-parse', 'HEAD')}\n"
        f"python3_version: {sys.version.split()[0]}\n"
        f"chars_per_token: {CHARS_PER_TOKEN}\n"
        f"metric_rows: {len(rows)}\n",
        encoding="utf-8",
    )


def load_inventory(path: Path) -> dict[tuple[str, str], int]:
    out: dict[tuple[str, str], int] = {}
    for line in read(path).splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) != 3:
            continue
        try:
            out[(parts[0], parts[1])] = int(parts[2])
        except ValueError:
            continue
    return out


def cmd_collect(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    rows = collect(root)
    write_inventory(rows, Path(args.out).resolve(), root)
    # skill-count is a cardinality row, not a byte count -- never sum it.
    total = sum(c for m, k, c in rows if m == "always-on" and k != "skill-count")
    print(f"cost-meter: wrote {len(rows)} metric rows to {args.out}")
    print(f"cost-meter: always-on surface = {total:,} chars (~{total // CHARS_PER_TOKEN:,} tokens)")
    return 0


def cmd_diff(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    base = load_inventory(Path(args.baseline).resolve())
    if not base:
        print(f"cost-meter: baseline {args.baseline} is empty or unreadable", file=sys.stderr)
        return 2

    after = ({(m, k): c for m, k, c in collect(root)} if args.collect
             else load_inventory(Path(args.after).resolve()))

    grew: list[tuple[str, str, int, int, float]] = []
    added: list[tuple[str, str, int]] = []
    shrank_total = 0

    for key, now in sorted(after.items()):
        if key not in base:
            if now > 0:
                added.append((key[0], key[1], now))
            continue
        was = base[key]
        if now > was:
            pct = 100.0 * (now - was) / was if was else 100.0
            if pct > args.tolerance:
                grew.append((key[0], key[1], was, now, pct))
        elif now < was:
            shrank_total += was - now

    for key, was in sorted(base.items()):
        if key not in after:
            shrank_total += was

    if shrank_total:
        print(f"cost-meter: net reduction of {shrank_total:,} chars "
              f"(~{shrank_total // CHARS_PER_TOKEN:,} tokens) across shrunk/removed metrics")

    if added:
        print(f"\ncost-meter: {len(added)} NEW metric(s):")
        for metric, key, now in added[:20]:
            print(f"  + {metric:18} {key:44} {now:>9,}")

    if grew:
        print(f"\ncost-meter: {len(grew)} metric(s) GREW beyond tolerance ({args.tolerance}%):")
        for metric, key, was, now, pct in sorted(grew, key=lambda r: -(r[3] - r[2])):
            print(f"  ! {metric:18} {key:44} {was:>9,} -> {now:>9,}  (+{pct:.1f}%)")

    fail = bool(grew) or (args.fail_on_new and added)
    print("\ncost-meter: FAIL -- instruction surface grew" if fail
          else "\ncost-meter: PASS -- no un-excused growth")
    return 1 if fail else 0


# --- report ------------------------------------------------------------------

CHANGELOG_RE = re.compile(r"^## Change Log$(.*?)(?=^## |\Z)", re.M | re.S)
HISTORY_RE = re.compile(r"^## (?:Lifecycle History|Cross-phase Q&A)$(.*?)(?=^## |\Z)", re.M | re.S)
GRADE_CHAIN_RE = re.compile(
    r"((?:\*\*)?[A-E][+-]?(?:\*\*)?(?:\s*(?:->|\u2192)\s*(?:\*\*)?[A-E][+-]?(?:\*\*)?){1,8})")


def scan_work(work: Path) -> None:
    """Report artifact bloat and review-cycle churn for one work folder."""
    md = sorted(p for p in work.rglob("*.md"))
    if not md:
        print(f"\n  (no .md files under {work})")
        return

    total = changelog = history = 0
    for p in md:
        t = read(p)
        total += len(t)
        changelog += sum(len(m.group(1)) for m in CHANGELOG_RE.finditer(t))
        history += sum(len(m.group(1)) for m in HISTORY_RE.finditer(t))

    print(f"\n  {len(md)} .md files, {total:,} chars (~{total // CHARS_PER_TOKEN:,} tokens)")
    if total:
        print(f"  Change Log sections : {changelog:>9,} chars ({100 * changelog / total:.1f}%)")
        print(f"  History / Q&A logs  : {history:>9,} chars ({100 * history / total:.1f}%)")
        dead = changelog + history
        print(f"  --> git-redundant   : {dead:>9,} chars "
              f"(~{dead // CHARS_PER_TOKEN:,} tokens, {100 * dead / total:.1f}%)")

    cycles = waste = 0
    for p in md:
        for line in read(p).splitlines():
            if not line.startswith("| 20"):
                continue
            for m in GRADE_CHAIN_RE.finditer(line):
                g = [x.strip() for x in re.sub(r"\*", "", m.group(1)).replace("\u2192", "->").split("->")]
                if len(g) < 2:
                    continue
                cycles += len(g)
                waste += sum(1 for i in range(1, len(g)) if g[i] == g[i - 1])
    if cycles:
        print(f"  review cycles recorded: {cycles}  "
              f"(zero-grade-movement: {waste}, {100 * waste / cycles:.0f}%)")


# --- gate model ---------------------------------------------------------------
# `collect`/`report` measure the instruction surface a skill loads. That is real
# cost, but it is not where the money goes: on a full-path work, REVIEW GATES are
# 60-65% of total, because a gate multiplies three ways -- per feature, per
# delivery, and per review cycle.
#
# `model` makes that arithmetic reproducible. It is a MODEL, not a measurement:
# it multiplies real file sizes by an assumed dispatch shape. Its value is
# COMPARATIVE -- run two gate shapes over identical inputs and the ratio between
# them is trustworthy even where the absolute number is not.
#
# Dispatch floors are derived from the tree rather than hardcoded, so a change
# that shrinks an AGENT.md or a template shows up here automatically.

# Default artifact sizes. Overridden by --from-work, which is strongly preferred:
# these were measured once and will drift.
DEFAULT_ARTIFACTS = {"REQ": 88276, "SPEC": 21191, "PLAN": 5075, "BP": 3359, "DET": 2075}

# Bytes of code/context a task's execution review reads beyond its DETAIL.
CODE_PER_TASK = 12000


def dispatch_floors(root: Path) -> dict[str, int]:
    """Fresh-context floor for one dispatch of each agent, derived from disk.

    Every sub-agent starts clean, so it re-reads its own definition, the shared
    boilerplate, and whatever contract its role obliges. That floor is paid once
    per dispatch and dominates any gate whose artifact is small.
    """
    t = root / "canonical" / "aid" / "templates"
    a = root / "canonical" / "agents"
    shared = len(read(t / "agent-boilerplate.md")) + len(read(t / "self-review-protocol.md"))
    kb_index = len(read(root / ".aid" / "knowledge" / "INDEX.md"))
    reviewer_contract = len(read(t / "reviewer-ledger-schema.md")) + len(read(t / "grading-rubric.md"))
    return {
        "architect": len(read(a / "aid-architect" / "AGENT.md")) + shared + kb_index,
        "reviewer": len(read(a / "aid-reviewer" / "AGENT.md")) + shared + reviewer_contract,
        "developer": len(read(a / "aid-developer" / "AGENT.md")) + shared + kb_index,
    }


def artifacts_from_work(work: Path) -> tuple[dict[str, int], set[str]]:
    """Measure real artifact sizes from a work folder.

    Returns (sizes, measured_keys). Any key NOT in measured_keys fell back to a
    built-in default because that artifact is absent -- a flat/Lite work has no
    `features/` and no BLUEPRINT, for instance. The caller must mark those,
    because a default presented as a measurement is how a wrong number survives
    into a decision.
    """
    def avg(paths: list[Path]) -> int:
        sizes = [len(read(p)) for p in paths]
        return sum(sizes) // len(sizes) if sizes else 0

    out = dict(DEFAULT_ARTIFACTS)
    measured: set[str] = set()
    if (req := work / "REQUIREMENTS.md").is_file():
        out["REQ"] = len(read(req)); measured.add("REQ")
    if (plan := work / "PLAN.md").is_file():
        out["PLAN"] = len(read(plan)); measured.add("PLAN")
    if specs := sorted(work.glob("features/*/SPEC.md")):
        out["SPEC"] = avg(specs); measured.add("SPEC")
    if bps := sorted(work.rglob("BLUEPRINT.md")):
        out["BP"] = avg(bps); measured.add("BP")
    if dets := sorted(work.rglob("tasks/*/DETAIL.md")):
        out["DET"] = avg(dets); measured.add("DET")
    return out, measured


SHAPES = ("today", "batched", "folded", "folded-sliced")


def gate_shape(name: str, F: int, D: int, T: int, c: int, art: dict[str, int]
               ) -> list[tuple[str, int, int, int, str, str]]:
    """A shape as data: (label, points, artifact_bytes, cycles, role, kind).

    kind="gate"   a review cycle: reviewer floor + fixer floor + 2 x artifact
                  (the reviewer reads it, then the fixer reads it again).
    kind="read"   an artifact read folded into a dispatch that already happens,
                  so no floor and one pass. This is how the ORACLE cost is
                  counted: every task execution reads the statement of intent to
                  know what it is building. Gate rows alone cannot answer whether
                  merging documents helps, because merging moves cost between the
                  gate stage and the grounding stage.
    """
    dt = max(1, T // max(1, D))          # tasks per delivery
    exec_gate = ("per-task exec check", T, art["DET"] + CODE_PER_TASK, 1, "developer", "gate")

    if name == "today":
        # A gate per feature after specify, a gate per delivery after detail.
        # Each task grounds on REQUIREMENTS plus its own feature SPEC.
        #
        # The per-task exec check is in this shape too, not only in `batched`:
        # aid-execute already runs a 1-cycle, ungraded quick-check per task
        # ("No grade is computed, no loop" -- state-review.md), and the delivery
        # gate already reviews the full branch diff. Omitting it here understated
        # `today` and therefore understated every alternative's saving.
        return [
            ("gate REQUIREMENTS", 1, art["REQ"], c, "architect", "gate"),
            ("gate define", 1, art["REQ"], c, "architect", "gate"),
            ("gate SPEC (per feature)", F, art["REQ"] + art["SPEC"], c, "architect", "gate"),
            ("gate PLAN", 1, art["PLAN"] + F * art["SPEC"], c, "architect", "gate"),
            ("gate DETAIL (per delivery)", D, art["BP"] + dt * art["DET"], c, "architect", "gate"),
            exec_gate,
            ("delivery gate", D, art["BP"] + dt * art["DET"], c, "developer", "gate"),
            ("task grounding", T, art["REQ"] + art["SPEC"], 1, "developer", "read"),
        ]

    if name == "batched":
        # Same documents, fewer gate points. Grounding is unchanged -- batching
        # gates does not move where the oracle lives.
        return [
            ("gate REQUIREMENTS", 1, art["REQ"], c, "architect", "gate"),
            ("gate SPEC (batched)", 1, art["REQ"] + F * art["SPEC"], c, "architect", "gate"),
            ("gate PLAN", 1, art["PLAN"], c, "architect", "gate"),
            ("gate DETAIL (all)", 1, T * art["DET"], c, "architect", "gate"),
            exec_gate,
            ("delivery gate (diff)", 1, T * art["DET"] + CODE_PER_TASK, 3, "developer", "gate"),
            ("task grounding", T, art["REQ"] + art["SPEC"], 1, "developer", "read"),
        ]

    # folded: the per-feature technical design becomes sections of REQUIREMENTS,
    # so there is ONE oracle document and one gate over it. Two consequences the
    # numbers do not show: the cross-document contradiction class disappears
    # (there is no second document to contradict), and the oracle stays prior to
    # and independent of the implementation, which folding into task DETAILs
    # would not.
    if name in ("folded", "folded-sliced"):
        oracle = art["REQ"] + F * art["SPEC"]
        # sliced: a task reads only the section it traces to. Requires the task to
        # cite an AC or section -- today a DETAIL cites its delivery, not an AC,
        # so this variant is gated on that traceability field existing.
        grounding = (art["REQ"] // max(1, F) + art["SPEC"]) if name.endswith("sliced") else oracle
        return [
            ("gate REQUIREMENTS+design", 1, oracle, c, "architect", "gate"),
            ("gate PLAN", 1, art["PLAN"], c, "architect", "gate"),
            ("gate DETAIL (all)", 1, T * art["DET"], c, "architect", "gate"),
            exec_gate,
            ("delivery gate (diff)", 1, T * art["DET"] + CODE_PER_TASK, 3, "developer", "gate"),
            ("task grounding", T, grounding, 1, "developer", "read"),
        ]

    raise ValueError(f"unknown shape: {name}")


def price_shape(rows, floors: dict[str, int]) -> tuple[int, int, list[tuple[str, int, int]]]:
    """Return (total_bytes, gate_points, [(label, points, bytes), ...])."""
    out, total, points = [], 0, 0
    for label, n, artifact, cycles, role, kind in rows:
        if kind == "gate":
            per_cycle = floors["reviewer"] + floors[role] + 2 * artifact
            points += n
        else:
            per_cycle = artifact
        cost = n * cycles * per_cycle
        out.append((label, n, cost))
        total += cost
    return total, points, out


def cmd_model(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    floors = dispatch_floors(root)
    if args.from_work:
        art, measured = artifacts_from_work(Path(args.from_work).resolve())
    else:
        art, measured = dict(DEFAULT_ARTIFACTS), set()

    print("Gate-cost MODEL -- real file sizes x an assumed dispatch shape.")
    print("Absolute numbers are indicative; the ratio between shapes is the signal.\n")
    print(f"  inputs: features={args.features} deliveries={args.deliveries} "
          f"tasks={args.tasks} cycles={args.cycles}")
    src = args.from_work if args.from_work else "built-in defaults"
    print(f"  artifact sizes from: {src}")
    # A `*` marks a size that FELL BACK to a built-in default because the work
    # has no such artifact. Unmarked values were measured on disk.
    print("    " + "  ".join(f"{k}={v:,}" + ("" if k in measured or not args.from_work else "*")
                             for k, v in art.items()))
    if args.from_work and (fell_back := sorted(set(art) - measured)):
        print(f"    * = not present in that work; built-in default used: {', '.join(fell_back)}")
    print("  dispatch floors (derived from tree):")
    print("    " + "  ".join(f"{k}={v:,}" for k, v in floors.items()))

    results = {}
    for shape in args.shape:
        rows = gate_shape(shape, args.features, args.deliveries, args.tasks, args.cycles, art)
        total, points, detail = price_shape(rows, floors)
        results[shape] = total
        print(f"\n{'='*70}\nshape: {shape}   ({points} gate points)\n{'='*70}")
        for label, n, cost in detail:
            print(f"  {label:<26} x{n:<3} {cost:>12,} B  ~{cost//CHARS_PER_TOKEN//1000:>5}k tok")
        print(f"  {'TOTAL':<30} {total:>12,} B  ~{total//CHARS_PER_TOKEN//1000:>5}k tok")

    if len(results) > 1:
        base = results[args.shape[0]]
        print(f"\n{'='*70}\ncomparison vs '{args.shape[0]}'\n{'='*70}")
        for shape, total in list(results.items())[1:]:
            delta = base - total
            sign = "saves" if delta > 0 else "COSTS"
            print(f"  {shape:<22} {sign} {abs(delta):>12,} B  "
                  f"({100*abs(delta)/base:>4.0f}%)  ~{abs(delta)//CHARS_PER_TOKEN//1000}k tok")
    return 0


def cmd_report(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    rows = collect(root)
    idx: dict[str, list[tuple[str, int]]] = {}
    for metric, key, chars in rows:
        idx.setdefault(metric, []).append((key, chars))

    def tok(n: int) -> str:
        return f"{n:>9,} chars (~{n // CHARS_PER_TOKEN:,} tokens)"

    print("=" * 78)
    print("ALWAYS-ON SURFACE -- paid by every session before the user types")
    print("=" * 78)
    ao = dict(idx.get("always-on", []))
    n_skills = ao.pop("skill-count", 0)
    for key, chars in sorted(ao.items()):
        print(f"  {key:34} {tok(chars)}")
    print(f"  {'TOTAL':34} {tok(sum(ao.values()))}   across {n_skills} skills")

    print("\n" + "=" * 78)
    print(f"HEAVIEST SKILL SURFACES (top {args.top})")
    print("  self+refs = its own bytes.  names = what it points at directly.")
    print("  closure   = files it can transitively pull in (connectivity, not bytes).")
    print("=" * 78)
    self_ = dict(idx.get("skill-self", []))
    refs_ = dict(idx.get("skill-refs", []))
    names = dict(idx.get("skill-names-instr", []))
    closure = dict(idx.get("skill-closure-files", []))
    combined = sorted(((s, self_.get(s, 0) + refs_.get(s, 0) + names.get(s, 0))
                       for s in self_), key=lambda r: -r[1])
    print(f"  {'skill':26} {'self':>8} {'refs':>9} {'names':>9} {'total':>10} {'closure':>8}")
    for slug, tot in combined[:args.top]:
        print(f"  {slug:26} {self_.get(slug, 0):>8,} {refs_.get(slug, 0):>9,} "
              f"{names.get(slug, 0):>9,} {tot:>10,} {closure.get(slug, 0):>8}")

    if closure:
        avg = sum(closure.values()) / len(closure)
        worst = max(closure.values())
        print(f"\n  Instruction-graph connectivity: a skill can reach {avg:.0f} .md files "
              f"on average, {worst} at worst.")

    print("\n" + "=" * 78)
    print(f"HEAVIEST SHARED TEMPLATES -- every naming skill and dispatch pays these (top {args.top})")
    print("=" * 78)
    for key, chars in sorted(idx.get("template", []), key=lambda r: -r[1])[:args.top]:
        print(f"  {key:56} {chars:>9,}")

    if args.work_dir:
        print("\n" + "=" * 78)
        print("WORK-ARTIFACT SCAN")
        print("=" * 78)
        for w in args.work_dir:
            p = Path(w).resolve()
            print(f"\n{p.name}:" if p.exists() else f"\n{w}: (not found)")
            if p.exists():
                scan_work(p)
    return 0


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        prog="cost-meter.py",
        description="Static token-cost inventory + regression gate for the AID instruction surface.")
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("collect", help="write a deterministic inventory + .meta sidecar")
    c.add_argument("--out", required=True)
    c.add_argument("--root", default=".")
    c.set_defaults(fn=cmd_collect)

    d = sub.add_parser("diff", help="compare an inventory to a baseline; non-zero on growth")
    d.add_argument("--baseline", required=True)
    src = d.add_mutually_exclusive_group(required=True)
    src.add_argument("--collect", action="store_true", help="collect from the current tree")
    src.add_argument("--after", help="read a pre-collected inventory")
    d.add_argument("--root", default=".")
    d.add_argument("--tolerance", type=float, default=0.0,
                   help="percent growth allowed per metric (default 0)")
    d.add_argument("--fail-on-new", action="store_true",
                   help="also fail when a new metric appears")
    d.set_defaults(fn=cmd_diff)

    m = sub.add_parser("model", help="model gate cost for one or more gate shapes")
    m.add_argument("--root", default=".")
    m.add_argument("--from-work", help="measure artifact sizes from this work folder")
    m.add_argument("--features", type=int, default=3)
    m.add_argument("--deliveries", type=int, default=4)
    m.add_argument("--tasks", type=int, default=16)
    m.add_argument("--cycles", type=int, default=5)
    m.add_argument("--shape", action="append", choices=list(SHAPES),
                   help="shape to price (repeatable; first is the comparison base)")
    m.set_defaults(fn=cmd_model)

    r = sub.add_parser("report", help="human-readable summary (never a gate)")
    r.add_argument("--root", default=".")
    r.add_argument("--work-dir", action="append", default=[],
                   help="also scan this work folder for artifact bloat (repeatable)")
    r.add_argument("--top", type=int, default=15)
    r.set_defaults(fn=cmd_report)

    args = ap.parse_args(argv)
    if getattr(args, "cmd", None) == "model" and not args.shape:
        args.shape = list(SHAPES)
    return int(args.fn(args))


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
