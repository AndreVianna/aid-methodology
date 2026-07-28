#!/usr/bin/env bash
# kb-citation-lint.sh -- check bare line-number citations. Two rule profiles.
#
# PROFILE durable (default; root .aid/knowledge)
#   The KB authoring standard (kb-authoring principles.md) requires DURABLE anchors: a file
#   path plus a grep-recoverable symbol/heading, NOT a bare `file.ext:LINE` (line numbers drift).
#   Every bare-line citation is a violation. This lint catches the bare-line form MECHANICALLY so
#   it is fixed at the source (GENERATE) instead of one phase later (REVIEW) -- the agent's prose
#   instruction + self-report are not enough, so the orchestrator gates on this script.
#
# PROFILE resolvable (root .aid/works -- work artifacts: REQUIREMENTS/SPEC/PLAN/BLUEPRINT/DETAIL)
#   Bare-line citations are PERMITTED, because a spec's affected-artifact inventory needs exact
#   ranges to claim region ownership -- banning them would remove the mechanism that keeps
#   sibling features from colliding. Each citation must instead RESOLVE:
#     [UNRESOLVED]   no file matches the cited path
#     [AMBIGUOUS]    more than one file matches; candidates are listed
#     [OUT-OF-RANGE] the linespec's maximum exceeds the file's line count
#
# A finding is `<file>.<ext>:<linespec>` where <linespec> is a pure line number or range/list
# (e.g. :39, :33,47, :106-125, :126-141,228). Ranges written with an EN-DASH (U+2013) are matched
# too -- work artifacts overwhelmingly use it, and the original ASCII-hyphen-only class silently
# truncated every such range to its first number, which is harmless for a ban and fatal for a
# range check. DURABLE anchors are NOT flagged under either profile:
#   - file.ext:symbol_name           (letters right after the colon)
#   - concern-model.md:15-doc seed   (digits followed by letters)
#   - server.mjs:127.0.0.1           (IP / version: digits followed by .digit)
#
# Usage:  kb-citation-lint.sh [--root DIR] [--profile durable|resolvable] [--depth N]
#                             [--search-root DIR]
#         --root         directory to scan            (default .aid/knowledge)
#         --profile      rule set                     (default durable)
#         --depth        find -maxdepth for the scan  (default 1; work artifacts need 4)
#         --search-root  repo root for resolution     (default .)
# Exit:   0 = clean, 1 = violations found, 2 = usage/error.

set -uo pipefail

ROOT=".aid/knowledge"
PROFILE="durable"
DEPTH=1
SEARCH_ROOT="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --depth) DEPTH="$2"; shift 2 ;;
    --search-root) SEARCH_ROOT="$2"; shift 2 ;;
    -h|--help) sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "kb-citation-lint.sh: unknown arg: $1" >&2; exit 2 ;;
  esac
done

case "$PROFILE" in
  durable|resolvable) ;;
  *) echo "kb-citation-lint.sh: --profile must be durable or resolvable (got: $PROFILE)" >&2; exit 2 ;;
esac
[[ "$DEPTH" =~ ^[0-9]+$ ]] || { echo "kb-citation-lint.sh: --depth must be a non-negative integer" >&2; exit 2; }
[[ -d "$ROOT" ]] || { echo "kb-citation-lint.sh: not a directory: $ROOT" >&2; exit 2; }

# Collect the doc set ONCE (find | sort) and scan ALL docs in a SINGLE awk pass.
# awk tracks per-file position itself (FILENAME / FNR reset per file), so batching
# over "${docs[@]}" in the same sorted order emits byte-identical findings to the old
# one-awk-per-doc loop -- while removing the per-doc subprocess spawn that was slow on
# Windows Git Bash / MSYS (one fork per KB doc).
mapfile -t docs < <(find "$ROOT" -maxdepth "$DEPTH" -type f -name '*.md' ! -name '.*' 2>/dev/null | sort)

candidates=""
if [[ ${#docs[@]} -gt 0 ]]; then
  candidates="$(
    awk '
      # Fenced code blocks are SKIPPED, under both profiles. A citation inside a fence is an
      # example or a test fixture, not a claim about the tree -- flagging `f.md:12` in an oracle
      # block is noise, and a lint whose findings are mostly noise does not survive its first FIX
      # cycle. This was found by running the resolvable profile against this work: 3 of its 11
      # UNRESOLVED findings were the lint reporting its own fixtures.
      /^[ \t]*(```|~~~)/ { in_fence = !in_fence; next }
      in_fence { next }
      {
        line = $0
        while (match(line, /[A-Za-z0-9_.\/-]+\.(md|sh|py|mjs|js|ts|yml|yaml|json|toml|txt|ps1):[0-9]+([,\-\xe2\x80\x93][0-9]+)*/)) {
          m  = substr(line, RSTART, RLENGTH)               # e.g. installer-tests.yml:106-125
          a2 = substr(line, RSTART + RLENGTH, 2)           # the 2 chars right after the linespec
          a1 = substr(a2, 1, 1)
          bad = 0
          if (a1 ~ /[A-Za-z]/)        bad = 1              # letter   -> durable anchor
          else if (a2 ~ /^\.[0-9]/)   bad = 1              # .digit   -> IP / version
          else if (a2 ~ /^-[A-Za-z]/) bad = 1              # -letter  -> durable anchor
          if (!bad) printf "%s:%d: %s\n", FILENAME, FNR, m
          line = substr(line, RSTART + RLENGTH)            # advance past this match on the line
        }
      }
    ' "${docs[@]}"
  )"
fi

# ---------------------------------------------------------------------------
# PROFILE durable -- every candidate is a violation. Output byte-identical to
# the pre-profile version of this script.
# ---------------------------------------------------------------------------
if [[ "$PROFILE" == "durable" ]]; then
  if [[ -n "$candidates" ]]; then
    echo "kb-citation-lint: VOLATILE bare line citations found -- use durable file:symbol anchors:" >&2
    printf '%s\n' "$candidates" >&2
    n="$(printf '%s\n' "$candidates" | grep -c .)"
    echo "kb-citation-lint: ${n} violation(s)." >&2
    exit 1
  fi
  echo "kb-citation-lint: clean (no bare line citations under ${ROOT})."
  exit 0
fi

# ---------------------------------------------------------------------------
# PROFILE resolvable -- a citation is a violation only if it fails to resolve
# to exactly one file, or its maximum line exceeds that file's length.
# ---------------------------------------------------------------------------

# Build the path index ONCE. `git ls-files` is preferred: it is one process instead of one
# find per citation (measured 194s -> ~5s for 51 lookups on this tree) and it inherits
# .gitignore. It is NOT always available: it fails outright inside a worktree whose
# registration is broken, which is exactly the platform this is authored on -- so the
# find fallback is mandatory, not defensive.
INDEX_SRC="git"
index="$(git -C "$SEARCH_ROOT" ls-files 2>/dev/null)"
if [[ -z "$index" ]]; then
  INDEX_SRC="find"
  index="$(cd "$SEARCH_ROOT" 2>/dev/null && find . -type f \
             \( -path './.git/*' -o -path './site/node_modules/*' -o -path './.aid/.temp/*' \) -prune -o \
             -type f -print 2>/dev/null | sed 's|^\./||')"
fi

# Rendered trees and vendored copies are excluded from BASENAME resolution: they are copies of
# canonical/, so including them turns every canonical citation ambiguous. A legitimate citation
# INTO one of those trees arrives as a qualified path and is resolved by the verbatim step first.
index="$(printf '%s\n' "$index" | grep -vE '^(profiles|\.claude|\.cursor|\.codex|packages)/' | grep -v '/fixtures/')"

violations=""
add () { violations+="$1"$'\n'; }

while IFS= read -r cand; do
  [[ -z "$cand" ]] && continue
  where="${cand%%: *}"                 # <doc>:<lineno>
  cite="${cand#*: }"                   # <path>:<linespec>
  cpath="${cite%%:*}"
  spec="${cite#*:}"

  # max line number in the linespec (handles N, N,M, N-M, N–M)
  maxline="$(printf '%s\n' "$spec" | tr ',' '\n' | sed 's/\xe2\x80\x93/-/g' | tr '-' '\n' \
             | grep -E '^[0-9]+$' | sort -n | tail -1)"

  # 1. verbatim from the search root
  target=""
  if [[ -f "$SEARCH_ROOT/$cpath" ]]; then
    target="$SEARCH_ROOT/$cpath"
  else
    # 2. suffix match against the index
    mapfile -t hits < <(printf '%s\n' "$index" | grep -E "(^|/)$(printf '%s' "$cpath" | sed 's/[.[\*^$]/\\&/g')$" || true)
    if [[ ${#hits[@]} -eq 0 ]]; then
      add "$where: [UNRESOLVED] $cite"
      continue
    elif [[ ${#hits[@]} -gt 1 ]]; then
      # Cap the candidate list. A bare `SKILL.md` citation matches >100 files, and a finding
      # whose text is 100 paths long is unreadable -- which makes it a bad finding even though
      # the detection is right. Show the first 3 and the total; the count is the actionable part.
      shown="${hits[0]}"
      [[ ${#hits[@]} -gt 1 ]] && shown+=", ${hits[1]}"
      [[ ${#hits[@]} -gt 2 ]] && shown+=", ${hits[2]}"
      if [[ ${#hits[@]} -gt 3 ]]; then
        add "$where: [AMBIGUOUS] $cite -- ${#hits[@]} candidates: $shown, ... (qualify the path)"
      else
        add "$where: [AMBIGUOUS] $cite -- ${#hits[@]} candidates: $shown"
      fi
      continue
    fi
    target="$SEARCH_ROOT/${hits[0]}"
  fi

  # 3. range check
  if [[ -n "$maxline" && -f "$target" ]]; then
    len="$(grep -c '' "$target" 2>/dev/null || echo 0)"
    if (( maxline > len )); then
      add "$where: [OUT-OF-RANGE] $cite -- $(basename "$target") has ${len} lines"
    fi
  fi
done <<< "$candidates"

violations="${violations%$'\n'}"
if [[ -n "$violations" ]]; then
  echo "kb-citation-lint: unresolvable line citations found (profile=resolvable, index=${INDEX_SRC}):" >&2
  printf '%s\n' "$violations" >&2
  n="$(printf '%s\n' "$violations" | grep -c .)"
  echo "kb-citation-lint: ${n} violation(s)." >&2
  exit 1
fi

echo "kb-citation-lint: clean (all line citations under ${ROOT} resolve, index=${INDEX_SRC})."
exit 0
