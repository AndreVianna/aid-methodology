#!/usr/bin/env bash
# verify-claims.sh — grep KB markdown for verifiable claims and check each
# against actual disk state. Catches count drift, broken file:line citations,
# meta-doc summary tables that age out of sync with primary docs, missing
# standard KB files, frontmatter compliance, and generated-file freshness.
#
# Authored per DISCOVERY-STATE Q105 / tech-debt.md R29. Folded in the
# 16-file existence check from former verify-kb.sh (2026-05-26 script
# consolidation). Designed to be wired into the discovery-reviewer FIX
# cycle so the reviewer has ground truth instead of inferring counts from
# prior Q&A entries (which describe historical state).
#
# Usage:
#   verify-claims.sh [--kb PATH] [--root PATH] [--format human|tsv]
#                       [--include-state] [--quiet]
#
# Flags:
#   --kb PATH         KB directory (default: .aid/knowledge)
#   --root PATH       Project root for resolving cited paths (default: .)
#   --format FORMAT   human (default) | tsv
#   --include-state   Also verify citations inside .aid/knowledge/STATE.md
#                     (the consolidated Discovery area STATE, per FR2; pre-FR2
#                     this was DISCOVERY-STATE.md). Default: skip it — it
#                     documents historical state by design and would generate
#                     false positives.
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
      echo "$(basename "$0"): unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

[[ -d "$KB_DIR" ]] || { echo "$(basename "$0"): KB dir not found: $KB_DIR" >&2; exit 2; }
[[ -d "$ROOT" ]]   || { echo "$(basename "$0"): root not found: $ROOT" >&2; exit 2; }

# Temp files for collecting findings + per-section counters.
# All initialized to empty strings up front so the consolidated trap (set below the
# extended-lint section's mktemp calls) can rm -f every slot whether or not it
# was assigned by the time the script exits.
BROKEN=""
COUNT_DRIFTS=""
KB_MISSING_FILE=""
FM_ERRORS=""
T34_WARNINGS=""
GENERATED_MISSING=""
trap 'rm -f "$BROKEN" "$COUNT_DRIFTS" "$KB_MISSING_FILE" "$FM_ERRORS" "$T34_WARNINGS" "$GENERATED_MISSING"' EXIT
BROKEN=$(mktemp)
COUNT_DRIFTS=$(mktemp)
KB_MISSING_FILE=$(mktemp)

# ---------------------------------------------------------------------------
# PART 0 — Standard KB file presence (folded in from former verify-kb.sh)
# ---------------------------------------------------------------------------
# Verifies the 16 standard primary KB documents exist in the KB directory.
# Missing files are reported as [KB-MISSING] findings; subsequent parts will
# not produce useful results if standard files are absent. Does not abort
# early (runs remaining checks for completeness).
#
# Agent-to-file mapping (for re-dispatch by aid-discover):
#   discovery-scout:      project-structure.md, external-sources.md
#   discovery-architect:  architecture.md, technology-stack.md, ui-architecture.md
#   discovery-analyst:    module-map.md, coding-standards.md, data-model.md
#   discovery-integrator: api-contracts.md, integration-map.md, domain-glossary.md
#   discovery-quality:    test-landscape.md, security-model.md, tech-debt.md, infrastructure.md
#   orchestrator:         feature-inventory.md

STANDARD_KB_FILES=(
  project-structure.md
  external-sources.md
  architecture.md
  technology-stack.md
  module-map.md
  coding-standards.md
  data-model.md
  api-contracts.md
  integration-map.md
  domain-glossary.md
  test-landscape.md
  security-model.md
  tech-debt.md
  infrastructure.md
  ui-architecture.md
  feature-inventory.md
)

kb_present=0
kb_missing=0
for f in "${STANDARD_KB_FILES[@]}"; do
  if [[ -f "$KB_DIR/$f" ]]; then
    kb_present=$((kb_present + 1))
  else
    kb_missing=$((kb_missing + 1))
    echo "[KB-MISSING] $f (standard primary KB document not found in $KB_DIR/)" >> "$KB_MISSING_FILE"
  fi
done

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
  # Post-FR2: the consolidated Discovery area state lives in STATE.md.
  # Pre-FR2 it was DISCOVERY-STATE.md; we still skip both names so the
  # script works on legacy projects that haven't migrated yet.
  if [[ $SKIP_STATE -eq 1 && ( "$base" == "STATE.md" || "$base" == "DISCOVERY-STATE.md" ) ]]; then
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
                    "canonical/" ".claude/scripts/" \
                    ".claude/scripts/kb/" ".claude/scripts/execute/" \
                    ".claude/scripts/summarize/" ".claude/scripts/interview/" \
                    ".claude/skills/" ".claude/agents/" ".claude/recipes/" \
                    ".claude/templates/" ".claude/templates/knowledge-base/" \
                    ".claude/templates/knowledge-summary/" \
                    ".claude/templates/kb-authoring/" ".claude/templates/reports/" \
                    ".claude/templates/specs/" ".claude/templates/delivery-plans/" \
                    ".claude/templates/feedback-artifacts/" \
                    "templates/" "templates/knowledge-summary/" \
                    "scripts/" "scripts/kb/" "scripts/execute/" "scripts/summarize/" "scripts/interview/" \
                    "templates/knowledge-base/" "templates/requirements/" \
                    "templates/specs/" "templates/delivery-plans/" \
                    "templates/feedback-artifacts/" "templates/reports/" \
                    "profiles/claude-code/.claude/skills/" "profiles/claude-code/.claude/agents/" \
                    "profiles/claude-code/.claude/templates/" \
                    "profiles/claude-code/.claude/templates/knowledge-summary/" \
                    "profiles/claude-code/.claude/scripts/" \
                    "profiles/codex/.codex/agents/" "profiles/codex/.agents/skills/" \
                    "profiles/codex/.agents/templates/" \
                    "profiles/cursor/.cursor/agents/" "profiles/cursor/.cursor/rules/" \
                    "profiles/cursor/.cursor/skills/" "profiles/cursor/.cursor/templates/" \
                    "tests/" "tests/canonical/" "tests/skills/" \
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
# FRONTMATTER + KB AUTHORING LINT (.claude/templates/kb-authoring/)
# ---------------------------------------------------------------------------
# Per .claude/templates/kb-authoring/principles.md P4, the lint enforces
# what the frontmatter declares. We check:
#   - Every KB doc starts with YAML frontmatter
#   - Required fields (kb-category, source, intent) present + valid values
#   - generator: present iff source: generated
#   - For primary docs: warn on inline T3 (line counts) and T4 (date stamps)
#   - For generated docs: AUTO-GENERATED header present
#   - Registered generated files (per .claude/templates/generated-files.txt) exist

FM_ERRORS="$(mktemp)"
T34_WARNINGS="$(mktemp)"
GENERATED_MISSING="$(mktemp)"
# Trap registered above (consolidated) cleans these too.

fm_errors=0
t34_warnings=0
generated_missing=0
fm_checked=0

# Helper: extract single-line YAML field from first --- ... --- block
extract_fm_field() {
    awk -v field="$2" '
        BEGIN { in_fm=0 }
        /^---$/ { in_fm = !in_fm; if (NR > 1 && !in_fm) exit; next }
        in_fm && $0 ~ "^"field":" {
            sub("^"field":[[:space:]]*", "")
            print
            exit
        }
    ' "$1"
}

# Iterate hand-authored KB docs (skip dot-prefixed; skip generated subdir)
for f in "$KB_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    name=$(basename "$f")
    # Skip the consolidated STATE.md unless --include-state was set
    if [[ "$name" == "STATE.md" && "${INCLUDE_STATE:-0}" -eq 0 ]]; then
        continue
    fi
    fm_checked=$((fm_checked + 1))

    # Quick check: file must start with ---
    first_line=$(head -1 "$f")
    if [[ "$first_line" != "---" ]]; then
        fm_errors=$((fm_errors + 1))
        echo "[FM-MISSING] $name: no YAML frontmatter (first line != '---')" >> "$FM_ERRORS"
        continue
    fi

    kb_cat=$(extract_fm_field "$f" "kb-category")
    src=$(extract_fm_field "$f" "source")
    intent=$(extract_fm_field "$f" "intent")
    generator=$(extract_fm_field "$f" "generator")

    # kb-category required + valid
    case "$kb_cat" in
        primary|meta|extension) ;;
        "")
            fm_errors=$((fm_errors + 1))
            echo "[FM-MISSING] $name: kb-category not declared" >> "$FM_ERRORS"
            continue
            ;;
        *)
            fm_errors=$((fm_errors + 1))
            echo "[FM-INVALID] $name: kb-category='$kb_cat' (must be primary|meta|extension)" >> "$FM_ERRORS"
            continue
            ;;
    esac

    # source required + valid
    case "$src" in
        hand-authored|generated) ;;
        "")
            fm_errors=$((fm_errors + 1))
            echo "[FM-MISSING] $name: source not declared" >> "$FM_ERRORS"
            ;;
        *)
            fm_errors=$((fm_errors + 1))
            echo "[FM-INVALID] $name: source='$src' (must be hand-authored|generated)" >> "$FM_ERRORS"
            ;;
    esac

    # generator required iff source: generated
    if [[ "$src" == "generated" && -z "$generator" ]]; then
        fm_errors=$((fm_errors + 1))
        echo "[FM-MISSING] $name: source=generated but generator: not declared" >> "$FM_ERRORS"
    fi

    # intent should be non-empty AND have actual content under the literal block.
    # A doc with `intent: |` followed by nothing (or whitespace only) must NOT pass.
    if [[ -z "$intent" || "$intent" == "|" ]]; then
        if ! grep -qE "^intent:[[:space:]]*\|" "$f"; then
            fm_errors=$((fm_errors + 1))
            echo "[FM-MISSING] $name: intent: not declared" >> "$FM_ERRORS"
        else
            # Literal block declared — verify at least one non-blank indented content line follows
            # (peek next 5 lines after the `intent: |` line; require at least one indented non-blank)
            intent_content=$(awk '
                /^intent:[[:space:]]*\|/ { in_literal=1; n=0; next }
                in_literal && /^[[:space:]]+[^[:space:]]/ { print; n++; if (n >= 1) exit }
                in_literal && /^[^[:space:]]/ { exit }
            ' "$f")
            if [[ -z "$intent_content" ]]; then
                fm_errors=$((fm_errors + 1))
                echo "[FM-MISSING] $name: intent: literal block declared but body is empty/whitespace-only" >> "$FM_ERRORS"
            fi
        fi
    fi

    # AUTO-GENERATED header required for generated docs
    if [[ "$src" == "generated" ]]; then
        if ! grep -qE "<!--[[:space:]]*AUTO-GENERATED" "$f"; then
            fm_errors=$((fm_errors + 1))
            echo "[FM-MISSING] $name: source=generated but no <!-- AUTO-GENERATED ... --> header" >> "$FM_ERRORS"
        fi
    fi

    # T3/T4 inline-marker warnings — ONLY for primary + hand-authored docs
    if [[ "$kb_cat" == "primary" && "$src" == "hand-authored" ]]; then
        # Extract body (lines AFTER closing ---). Use awk.
        body=$(awk '/^---$/{c++; next} c==2' "$f" 2>/dev/null || true)
        # Per tier-model.md, T3 and T4 inline markers are BANNED in primary docs.
        # Threshold > 0 → one is too many; matches the spec's "Inline? NO" rule.
        # T4: bare date stamps like "2026-05-25", "as of 2026-05-22", "verified during cycle-N"
        t4_dates=$(echo "$body" | grep -cE "\b20[0-9]{2}-[01][0-9]-[0-3][0-9]\b" 2>/dev/null || echo 0)
        t4_cycles=$(echo "$body" | grep -cE "\bcycle[- ]?[0-9]+\b" 2>/dev/null || echo 0)
        t4_total=$((t4_dates + t4_cycles))
        if [[ "$t4_total" -gt 0 ]]; then
            t34_warnings=$((t34_warnings + 1))
            echo "[T4-WARN] $name: $t4_total inline temporal marker(s) (dates+cycle-tags) in primary doc body — banned per tier-model.md; move to changelog: frontmatter" >> "$T34_WARNINGS"
        fi
        # T3: bare line-counts like "(307 lines)"
        t3_lines=$(echo "$body" | grep -cE "\([0-9,]+ lines?\)" 2>/dev/null || echo 0)
        if [[ "$t3_lines" -gt 0 ]]; then
            t34_warnings=$((t34_warnings + 1))
            echo "[T3-WARN] $name: $t3_lines inline line-count marker(s) in primary doc body — banned per tier-model.md; move to metrics.md" >> "$T34_WARNINGS"
        fi
    fi
done

# Verify registered generated files exist
REGISTRY="$ROOT/.claude/templates/generated-files.txt"
if [[ -f "$REGISTRY" ]]; then
    while IFS='|' read -r out_path build_cmd; do
        # Skip comments + blanks
        case "$out_path" in
            ''|\#*) continue ;;
        esac
        # Trim whitespace
        out_path="${out_path#"${out_path%%[![:space:]]*}"}"
        out_path="${out_path%"${out_path##*[![:space:]]}"}"
        if [[ ! -f "$ROOT/$out_path" ]]; then
            generated_missing=$((generated_missing + 1))
            echo "[GEN-MISSING] $out_path: registered generated file does not exist (run: $build_cmd)" >> "$GENERATED_MISSING"
        fi
    done < "$REGISTRY"
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
echo "Standard KB files present: $kb_present/16"
echo "  Missing standard files:  $kb_missing"
echo ""
echo "Frontmatter checked:       $fm_checked KB docs"
echo "  FM errors:               $fm_errors"
echo "  T3/T4 inline warnings:   $t34_warnings"
echo "Generated files missing:   $generated_missing"
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

if [[ -s "$FM_ERRORS" ]]; then
  echo "--- Frontmatter Errors ---"
  cat "$FM_ERRORS"
  echo ""
fi

if [[ -s "$T34_WARNINGS" ]]; then
  echo "--- T3/T4 Inline-Marker Warnings (non-blocking) ---"
  cat "$T34_WARNINGS"
  echo ""
fi

if [[ -s "$GENERATED_MISSING" ]]; then
  echo "--- Missing Generated Files ---"
  cat "$GENERATED_MISSING"
  echo ""
fi

if [[ -s "$KB_MISSING_FILE" ]]; then
  echo "--- Missing Standard KB Files ---"
  cat "$KB_MISSING_FILE"
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

if [[ "$broken_cite" -gt 0 || "$oor_cite" -gt 0 || "$linecount_drifts" -gt 0 \
      || "$spotcheck_drifts" -gt 0 || "$fm_errors" -gt 0 || "$generated_missing" -gt 0 \
      || "$kb_missing" -gt 0 ]]; then
  echo "RESULT: drifts / FM errors / missing files detected — exit 1"
  if [[ "$t34_warnings" -gt 0 ]]; then
    echo "       (also $t34_warnings T3/T4 inline-marker warnings — informational, not failure)"
  fi
  exit 1
fi

if [[ "$t34_warnings" -gt 0 ]]; then
  echo "RESULT: all hard checks passed — exit 0 ($t34_warnings T3/T4 warnings — informational)"
else
  echo "RESULT: all checks passed — exit 0"
fi
exit 0
