#!/usr/bin/env bash
# verify-kb-claims.sh — grep KB markdown for verifiable claims and check each
# against actual disk state. Catches count drift, broken file:line citations,
# and meta-doc summary tables that age out of sync with their primary docs.
#
# Authored per DISCOVERY-STATE Q105 / tech-debt.md R29. Designed to be wired
# into the discovery-reviewer FIX cycle so the reviewer has ground truth
# instead of inferring counts from prior Q&A entries (which describe historical
# state and trigger reviewer hallucination in long iteration chains).
#
# Usage:
#   verify-kb-claims.sh [--kb PATH] [--root PATH] [--format human|tsv]
#                       [--include-state] [--quiet]
#
# Flags:
#   --kb PATH         KB directory (default: .aid/knowledge)
#   --root PATH       Project root for resolving cited paths (default: .)
#   --format FORMAT   human (default) | tsv
#   --include-state   Also verify citations inside DISCOVERY-STATE.md
#                     (default: skip it — it documents historical state by
#                     design and would generate false positives).
#   --quiet           Suppress per-doc output; only show summary + broken findings.
#
# Exit codes:
#   0 — all checks passed (no broken citations, no count drifts)
#   1 — at least one broken citation or count drift
#   2 — usage error / KB dir missing

set -uo pipefail

KB_DIR=".aid/knowledge"
ROOT="."
FORMAT="human"
SKIP_STATE=1
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --kb) KB_DIR="$2"; shift 2 ;;
    --root) ROOT="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --include-state) SKIP_STATE=0; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "verify-kb-claims.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

[[ -d "$KB_DIR" ]] || { echo "verify-kb-claims.sh: KB dir not found: $KB_DIR" >&2; exit 2; }
[[ -d "$ROOT" ]]   || { echo "verify-kb-claims.sh: root not found: $ROOT" >&2; exit 2; }

# Temp files for collecting findings + per-section counters
BROKEN=$(mktemp)
COUNT_DRIFTS=$(mktemp)
trap 'rm -f "$BROKEN" "$COUNT_DRIFTS"' EXIT

# ---------------------------------------------------------------------------
# PART 1 — file:line citation validity
# ---------------------------------------------------------------------------
# Pattern: a path-like token with a known extension followed by :NN[-MM].
# Strip URLs first so we don't trip on things like "http://host:80/path".
#
# Recognised extensions: limit to a small set to reduce false positives.

EXT_RE='(md|sh|ps1|py|js|mjs|cjs|toml|json|yaml|yml|css|html|htm|java|kt|kts|go|rs|cs|fs|cpp|c|h|hpp|rb|php|swift|scala|tsx|ts|jsx|sql|xml|mdc)'

total_cite=0
ok_cite=0
broken_cite=0
oor_cite=0

if [[ $QUIET -eq 0 ]]; then
  echo "=================================================="
  echo "KB Citation Verification — file:line references"
  echo "=================================================="
fi

for kb_file in "$KB_DIR"/*.md; do
  [[ -f "$kb_file" ]] || continue
  base=$(basename "$kb_file")
  if [[ $SKIP_STATE -eq 1 && "$base" == "DISCOVERY-STATE.md" ]]; then
    continue
  fi

  # Read the file once, strip URLs line-by-line
  per_doc=0
  while IFS= read -r raw_line; do
    line_num="${raw_line%%:*}"
    line_text="${raw_line#*:}"
    cleaned=$(echo "$line_text" | sed -E 's|https?://[A-Za-z0-9_./?=&%+:#-]+||g')

    # Extract each citation
    while IFS= read -r cite; do
      [[ -z "$cite" ]] && continue
      cited_path="${cite%:*}"
      range="${cite##*:}"
      cited_line="${range%%-*}"

      total_cite=$((total_cite+1))
      per_doc=$((per_doc+1))

      # Try multi-location resolution. KB authors commonly cite short paths
      # assuming the reader will resolve via convention. Prefix list below
      # covers the major locations; if all fail, a single `find` fallback
      # locates the file's basename anywhere in the project (excluding .git,
      # .aid, node_modules, etc.).
      full=""
      for prefix in "" ".aid/knowledge/" \
                    "templates/" "templates/knowledge-summary/" \
                    "templates/knowledge-summary/scripts/" "templates/scripts/" \
                    "templates/knowledge-base/" "templates/requirements/" \
                    "templates/specs/" "templates/delivery-plans/" \
                    "templates/feedback-artifacts/" "templates/reports/" \
                    "claude-code/.claude/skills/" "claude-code/.claude/agents/" \
                    "claude-code/.claude/templates/" \
                    "claude-code/.claude/templates/knowledge-summary/" \
                    "claude-code/.claude/templates/scripts/" \
                    "codex/.codex/agents/" "codex/.agents/skills/" \
                    "codex/.agents/templates/" \
                    "cursor/.cursor/agents/" "cursor/.cursor/rules/" \
                    "cursor/.cursor/skills/" "cursor/.cursor/templates/" \
                    "methodology/" "agents/" "skills/" "docs/"; do
        candidate="$ROOT/${prefix}${cited_path}"
        if [[ -f "$candidate" ]]; then
          full="$candidate"
          break
        fi
      done

      # Final fallback — basename find across the whole project (slow, last resort)
      if [[ -z "$full" ]]; then
        basename_only=$(basename "$cited_path")
        # Only attempt find if cited_path has no slash (likely a basename)
        if [[ "$cited_path" != */* ]]; then
          first_match=$(find "$ROOT" -type d \( -name ".git" -o -name ".aid" -o -name "node_modules" -o -name "worktrees" \) -prune -o -type f -name "$basename_only" -print 2>/dev/null | head -1)
          if [[ -n "$first_match" ]]; then
            full="$first_match"
          fi
        fi
      fi

      if [[ -z "$full" ]]; then
        broken_cite=$((broken_cite+1))
        echo "[MISSING-FILE] $base:$line_num cites \`$cited_path:$range\` — file not found in project" >> "$BROKEN"
      else
        actual_lines=$(wc -l < "$full" | tr -d ' ')
        if [[ "$cited_line" =~ ^[0-9]+$ ]] && [[ "$cited_line" -gt "$actual_lines" ]]; then
          oor_cite=$((oor_cite+1))
          echo "[OUT-OF-RANGE] $base:$line_num cites \`$cited_path:$range\` but resolved file (\`$full\`) has only $actual_lines lines" >> "$BROKEN"
        else
          ok_cite=$((ok_cite+1))
        fi
      fi
    done < <(echo "$cleaned" | grep -oE "[A-Za-z0-9_/.-]+\.${EXT_RE}:[0-9]+(-[0-9]+)?" || true)
  done < <(grep -nE "[A-Za-z0-9_/.-]+\.${EXT_RE}:[0-9]+" "$kb_file" || true)

  if [[ $QUIET -eq 0 && $per_doc -gt 0 ]]; then
    printf "  %-30s %3d citation(s) scanned\n" "$base" "$per_doc"
  fi
done

# ---------------------------------------------------------------------------
# PART 2 — README.md line-count column vs actual file line counts
# ---------------------------------------------------------------------------

readme="$KB_DIR/README.md"
linecount_drifts=0

if [[ -f "$readme" ]]; then
  if [[ $QUIET -eq 0 ]]; then
    echo ""
    echo "=================================================="
    echo "README.md line-count column vs disk"
    echo "=================================================="
  fi

  while IFS= read -r line; do
    # Match table rows: | filename.md [marker] | status | LINES | source | ...
    # Cell separator is `|`. We want col 1 (filename) and col 3 (lines).
    if [[ "$line" =~ ^\|\ ([A-Za-z0-9_.-]+\.md)(\ +[^|]+)?\ \|[^|]+\|\ +([0-9]+|—|\~[0-9]+)\ +\| ]]; then
      fname="${BASH_REMATCH[1]}"
      claimed="${BASH_REMATCH[3]}"
      # Resolve actual line count — search in KB dir first, then project root
      if [[ -f "$KB_DIR/$fname" ]]; then
        actual=$(wc -l < "$KB_DIR/$fname" | tr -d ' ')
      elif [[ -f "$ROOT/$fname" ]]; then
        actual=$(wc -l < "$ROOT/$fname" | tr -d ' ')
      else
        if [[ $QUIET -eq 0 ]]; then
          printf "  ?     %-30s claimed=%-5s  (file not found)\n" "$fname" "$claimed"
        fi
        continue
      fi
      # Compare
      if [[ "$claimed" == "—" || "$claimed" == "-" ]]; then
        if [[ $QUIET -eq 0 ]]; then
          printf "  SKIP  %-30s claimed=dash    actual=%s\n" "$fname" "$actual"
        fi
      elif [[ "$claimed" =~ ^~([0-9]+)$ ]]; then
        approx="${BASH_REMATCH[1]}"
        diff=$((approx > actual ? approx - actual : actual - approx))
        if [[ $diff -le 5 ]]; then
          [[ $QUIET -eq 0 ]] && printf "  OK    %-30s claimed=%-5s  actual=%s\n" "$fname" "$claimed" "$actual"
        else
          linecount_drifts=$((linecount_drifts+1))
          echo "[LINECOUNT-DRIFT] README.md: $fname claims ~$approx but actual is $actual (diff $diff > 5)" >> "$COUNT_DRIFTS"
          [[ $QUIET -eq 0 ]] && printf "  DRIFT %-30s claimed=%-5s  actual=%s\n" "$fname" "$claimed" "$actual"
        fi
      elif [[ "$claimed" =~ ^[0-9]+$ ]]; then
        diff=$((claimed > actual ? claimed - actual : actual - claimed))
        if [[ $diff -le 1 ]]; then
          [[ $QUIET -eq 0 ]] && printf "  OK    %-30s claimed=%-5s  actual=%s\n" "$fname" "$claimed" "$actual"
        else
          linecount_drifts=$((linecount_drifts+1))
          echo "[LINECOUNT-DRIFT] README.md: $fname claims $claimed lines but actual is $actual (diff $diff)" >> "$COUNT_DRIFTS"
          [[ $QUIET -eq 0 ]] && printf "  DRIFT %-30s claimed=%-5s  actual=%s\n" "$fname" "$claimed" "$actual"
        fi
      fi
    fi
  done < "$readme"
fi

# ---------------------------------------------------------------------------
# PART 3 — Spot-checks: specific count claims that are commonly drift-prone
# ---------------------------------------------------------------------------

spotcheck_drifts=0

# Helper to record a spot-check
record_spotcheck() {
  local label="$1"
  local file="$2"
  local actual="$3"
  local claimed_in="$4"
  local pattern="$5"   # the literal claim text to find in claimed_in
  local expected="$6"  # the value we expect to find in that claim text

  if [[ ! -f "$claimed_in" ]]; then
    return
  fi
  if grep -q "$pattern" "$claimed_in"; then
    if [[ "$pattern" == *"$expected"* ]]; then
      [[ $QUIET -eq 0 ]] && printf "  OK    %s in %s: %s (actual=%s)\n" "$label" "$(basename "$claimed_in")" "$pattern" "$actual"
    else
      spotcheck_drifts=$((spotcheck_drifts+1))
      echo "[SPOT-CHECK] $(basename "$claimed_in"): $label — pattern matched but expected '$expected' (actual on disk = $actual)" >> "$COUNT_DRIFTS"
    fi
  fi
}

# Spot-check: domain-glossary term count
if [[ -f "$KB_DIR/domain-glossary.md" ]]; then
  actual_terms=$(grep -c "^| \*\*" "$KB_DIR/domain-glossary.md" || echo 0)
  for meta in README.md INDEX.md; do
    if [[ -f "$KB_DIR/$meta" ]]; then
      # Look for "N terms" or "N AID-specific terms" claims (across whole doc; brittle by design)
      claimed=$(grep -oE "[0-9]+ (AID-specific )?terms" "$KB_DIR/$meta" | head -1 | grep -oE "^[0-9]+")
      if [[ -n "${claimed:-}" && "$claimed" != "$actual_terms" ]]; then
        spotcheck_drifts=$((spotcheck_drifts+1))
        echo "[SPOT-CHECK] $meta: claims '$claimed terms' for domain-glossary; actual is $actual_terms" >> "$COUNT_DRIFTS"
      fi
    fi
  done
fi

# Spot-check: tech-debt item counts
# Find the tech-debt row IN-CONTEXT — grep for lines containing 'tech-debt' AND a 'N HIGH' nearby.
if [[ -f "$KB_DIR/tech-debt.md" ]]; then
  td_high=$(grep -cE "^### \[HIGH\]" "$KB_DIR/tech-debt.md" || echo 0)
  td_med=$(grep -cE "^### \[MEDIUM\]" "$KB_DIR/tech-debt.md" || echo 0)
  td_low=$(grep -cE "^### \[LOW\]" "$KB_DIR/tech-debt.md" || echo 0)
  td_total=$((td_high + td_med + td_low))
  for meta in README.md INDEX.md; do
    if [[ -f "$KB_DIR/$meta" ]]; then
      # Find the FIRST line that mentions tech-debt.md AND contains 'N HIGH'.
      # Then extract that N. This is much more targeted than the generic "first N HIGH in doc".
      tech_debt_row=$(grep -n "tech-debt.md" "$KB_DIR/$meta" | grep -E "[0-9]+ HIGH" | head -1)
      if [[ -n "$tech_debt_row" ]]; then
        claimed_high=$(echo "$tech_debt_row" | grep -oE "[0-9]+ HIGH" | head -1 | grep -oE "^[0-9]+")
        if [[ -n "${claimed_high:-}" && "$claimed_high" != "$td_high" ]]; then
          spotcheck_drifts=$((spotcheck_drifts+1))
          echo "[SPOT-CHECK] $meta: tech-debt row claims '$claimed_high HIGH' but actual is $td_high" >> "$COUNT_DRIFTS"
        fi
      fi
    fi
  done
fi

# Spot-check: security-model severity counts (line-start [TAG])
if [[ -f "$KB_DIR/security-model.md" ]]; then
  sec_high=$(grep -cE "^\[HIGH\]" "$KB_DIR/security-model.md" || echo 0)
  sec_med=$(grep -cE "^\[MEDIUM\]" "$KB_DIR/security-model.md" || echo 0)
  sec_low=$(grep -cE "^\[LOW\]" "$KB_DIR/security-model.md" || echo 0)
  sec_info=$(grep -cE "^\[INFO\]" "$KB_DIR/security-model.md" || echo 0)
fi

# ---------------------------------------------------------------------------
# REPORT
# ---------------------------------------------------------------------------

echo ""
echo "=================================================="
echo "Summary"
echo "=================================================="
echo "Citations checked:         $total_cite"
echo "  Valid:                   $ok_cite"
echo "  Missing file:            $broken_cite"
echo "  Line out of range:       $oor_cite"
echo ""
echo "README line-count drifts:  $linecount_drifts"
echo "Spot-check drifts:         $spotcheck_drifts"
echo ""

if [[ -s "$BROKEN" ]]; then
  echo "--- Broken Citations ---"
  cat "$BROKEN"
  echo ""
fi

if [[ -s "$COUNT_DRIFTS" ]]; then
  echo "--- Count Drifts ---"
  cat "$COUNT_DRIFTS"
  echo ""
fi

# Verified ground-truth pane for downstream consumers
echo "--- Verified Ground Truth (this run) ---"
if [[ -f "$KB_DIR/domain-glossary.md" ]]; then
  echo "domain-glossary.md term count:        $actual_terms"
fi
if [[ -f "$KB_DIR/tech-debt.md" ]]; then
  echo "tech-debt.md severity tags:           HIGH=$td_high MEDIUM=$td_med LOW=$td_low TOTAL=$td_total"
fi
if [[ -f "$KB_DIR/security-model.md" ]]; then
  echo "security-model.md severity tags:      HIGH=$sec_high MEDIUM=$sec_med LOW=$sec_low INFO=$sec_info"
fi
echo ""

if [[ "$broken_cite" -gt 0 || "$oor_cite" -gt 0 || "$linecount_drifts" -gt 0 || "$spotcheck_drifts" -gt 0 ]]; then
  echo "RESULT: drifts detected — exit 1"
  exit 1
fi

echo "RESULT: all checks passed — exit 0"
exit 0
