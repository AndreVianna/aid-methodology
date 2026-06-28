#!/usr/bin/env bash
# recon-classify.sh -- deterministic recon pre-pass for AID discover (f006).
#
# Reads two already-generated markdown files (no second tree scan) and emits a
# proposed discovery path (GREENFIELD / BROWNFIELD-SMALL / BROWNFIELD-LARGE) to
# .aid/generated/recon.md (or --output PATH).
#
# Four metrics are computed from the existing generated files:
#   RM1  source-file count  -- sum Files over is_source rows in project-index.md
#   RM2  source LOC         -- sum Lines over the same is_source rows
#   RM3  directory count    -- distinct top-2-level prefixes over is_source files
#                              in the Full File Inventory
#   RM4  concept count      -- Cross-source (spread >= 2) value from candidate-concepts.md
#                              Summary; 0 when the file is missing/empty
#
# Classifier (single indivisible rule, ordered):
#   1. RM1 <= greenfield_max_source_files AND RM2 <= greenfield_max_source_loc
#      -> GREENFIELD (detect + signpost: run /aid-describe; no generation)
#   2. RM2 >= large_min_source_loc OR RM3 >= large_min_dirs OR RM4 >= large_min_concepts
#      -> BROWNFIELD-LARGE (any one large dimension trips)
#   3. else -> BROWNFIELD-SMALL
#
# Threshold defaults (read from .aid/settings.yml via read-setting.sh; absent = these):
#   greenfield_max_source_files: 5
#   greenfield_max_source_loc:   500
#   large_min_source_loc:        20000
#   large_min_dirs:              25
#   large_min_concepts:          40
#
# Degrade-gracefully:
#   missing/empty --candidates => RM4=0 (never an error)
#   missing --index => warn to stderr; propose BROWNFIELD-SMALL (conservative default)
#
# Output (.aid/generated/recon.md):
#   Proposed path, the four metric values, and which threshold(s) tripped.
#   Never writes timestamps in the classification output (byte-reproducible).
#
# Usage:
#   recon-classify.sh \
#     --index     .aid/generated/project-index.md \
#     --candidates .aid/generated/candidate-concepts.md \
#     --settings  .aid/settings.yml \
#     --output    .aid/generated/recon.md
#
# Mirrors the sibling flag shape (build-project-index.sh / harvest-coined-terms.sh).
# ASCII-only bash; no LLM; pure coreutils (awk/grep/sort/wc) + read-setting.sh.

set -euo pipefail

# ---------------------------------------------------------------------------
# is_source -- 23-language classifier, kept in lockstep with
# build-project-index.sh's is_source function.  Changes here MUST be
# mirrored there (and vice-versa).  The lockstep is asserted by
# task-024's shared fixture.
# ---------------------------------------------------------------------------
IS_SOURCE_LANGUAGES="Java|Kotlin|Python|JavaScript|TypeScript|Go|Rust|C#|F#|C/C++|Ruby|PHP|Swift|Scala|Elm|Elixir|Erlang|Clojure|Lua|Shell|PowerShell|Vue|Svelte"

# ---------------------------------------------------------------------------
# Default flag values
# ---------------------------------------------------------------------------
INDEX=""
CANDIDATES=""
SETTINGS=".aid/settings.yml"
OUTPUT=".aid/generated/recon.md"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --index)      INDEX="$2";      shift 2 ;;
    --candidates) CANDIDATES="$2"; shift 2 ;;
    --settings)   SETTINGS="$2";   shift 2 ;;
    --output)     OUTPUT="$2";     shift 2 ;;
    -h|--help)
      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "recon-classify.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve OUTPUT to absolute path BEFORE any cd (mirrors sibling scripts).
# ---------------------------------------------------------------------------
case "$OUTPUT" in
  /*|[A-Za-z]:[/\\]*) ;;
  *) OUTPUT="$PWD/$OUTPUT" ;;
esac

mkdir -p "$(dirname "$OUTPUT")"

# ---------------------------------------------------------------------------
# Resolve SETTINGS to absolute path for read-setting.sh
# ---------------------------------------------------------------------------
case "$SETTINGS" in
  /*|[A-Za-z]:[/\\]*) ;;
  *) SETTINGS="$PWD/$SETTINGS" ;;
esac

# Locate read-setting.sh sibling in the same scripts tree.
# It lives at ../config/read-setting.sh relative to this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
READ_SETTING="${SCRIPT_DIR}/../config/read-setting.sh"

# ---------------------------------------------------------------------------
# Helper: read a triage threshold from settings.yml (with default)
# ---------------------------------------------------------------------------
read_threshold() {
  local path="$1"
  local default="$2"
  if [[ -x "$READ_SETTING" || -f "$READ_SETTING" ]]; then
    bash "$READ_SETTING" --path "$path" --default "$default" --file "$SETTINGS" 2>/dev/null \
      || echo "$default"
  else
    echo "$default"
  fi
}

# ---------------------------------------------------------------------------
# Load configurable thresholds
# ---------------------------------------------------------------------------
GF_MAX_FILES=$(read_threshold "triage.greenfield_max_source_files" "5")
GF_MAX_LOC=$(read_threshold "triage.greenfield_max_source_loc" "500")
LG_MIN_LOC=$(read_threshold "triage.large_min_source_loc" "20000")
LG_MIN_DIRS=$(read_threshold "triage.large_min_dirs" "25")
LG_MIN_CONCEPTS=$(read_threshold "triage.large_min_concepts" "40")

# ---------------------------------------------------------------------------
# Degrade-gracefully: missing --index => warn + brownfield-small
# ---------------------------------------------------------------------------
if [[ -z "$INDEX" || ! -f "$INDEX" ]]; then
  echo "[recon] WARNING: project-index.md not found (--index '${INDEX:-<not set>}'); proposing brownfield-small (conservative default)" >&2
  {
    echo "# Recon Classification"
    echo ""
    echo "## Warning"
    echo ""
    echo "project-index.md missing or not specified. Proposing conservative default."
    echo ""
    echo "## Result"
    echo ""
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Proposed path | BROWNFIELD-SMALL |"
    echo "| RM1 (source files) | 0 (missing index) |"
    echo "| RM2 (source LOC) | 0 (missing index) |"
    echo "| RM3 (directories) | 0 (missing index) |"
    echo "| RM4 (concepts) | 0 |"
    echo "| Tripped thresholds | none (missing-index degradation) |"
    echo ""
    echo "## Rationale"
    echo ""
    echo "project-index.md was not present. The conservative default (BROWNFIELD-SMALL)"
    echo "was selected. The human-confirm gate is the safety net."
  } > "$OUTPUT"
  echo "[recon] Wrote $OUTPUT (degraded: missing index)" >&2
  exit 0
fi

# ---------------------------------------------------------------------------
# RM1 + RM2: sum Files/Lines over is_source rows in Language Breakdown table.
#
# project-index.md Language Breakdown format:
#   | Language | Files | Lines |
#   |----------|-------|-------|
#   | Java     | 42    | 8500  |
#   ...
#
# is_source languages (pipe-separated, same set as build-project-index.sh):
#   Java Kotlin Python JavaScript TypeScript Go Rust C# F# C/C++ Ruby PHP
#   Swift Scala Elm Elixir Erlang Clojure Lua Shell PowerShell Vue Svelte
# ---------------------------------------------------------------------------

LC_ALL=C awk -v is_src="$IS_SOURCE_LANGUAGES" '
BEGIN {
  rm1 = 0; rm2 = 0
  n = split(is_src, langs, "|")
  for (i = 1; i <= n; i++) src_set[langs[i]] = 1
  in_breakdown = 0
}

# Detect Language Breakdown section header
/^## Language Breakdown/ { in_breakdown = 1; next }

# Leave the section when we see the next ## header
in_breakdown && /^## / { in_breakdown = 0; next }

# Parse table rows: | Language | Files | Lines |
# Skip header/separator rows (no digits in field 2)
in_breakdown && /^\|/ {
  # Remove leading/trailing pipes and split on pipe
  line = $0
  gsub(/^\||\|$/, "", line)
  n_fields = split(line, fields, "|")
  if (n_fields >= 3) {
    lang  = fields[1]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", lang)
    files = fields[2]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", files)
    locs  = fields[3]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", locs)
    # Only sum if Language is is_source and Files is a number
    if ((lang in src_set) && (files ~ /^[0-9]+$/) && (locs ~ /^[0-9]+$/)) {
      rm1 += files + 0
      rm2 += locs  + 0
    }
  }
}

END { print rm1 "\t" rm2 }
' "$INDEX" > /tmp/recon_rm12_$$.txt

RM1=$(cut -f1 /tmp/recon_rm12_$$.txt | tr -d '[:space:]')
RM2=$(cut -f2 /tmp/recon_rm12_$$.txt | tr -d '[:space:]')
rm -f /tmp/recon_rm12_$$.txt

# Ensure numeric
RM1="${RM1:-0}"; RM2="${RM2:-0}"
RM1=$(( RM1 + 0 )); RM2=$(( RM2 + 0 ))

# ---------------------------------------------------------------------------
# RM3: distinct top-2-level directory prefixes over is_source files in the
# Full File Inventory.
#
# Full File Inventory format:
#   | Path                       | Language   | Lines | Modified |
#   |----------------------------|------------|-------|----------|
#   | `src/bus/relative.ts`      | TypeScript | 120   | ...      |
#
# Top-2-level prefix of "src/bus/relative.ts" is "src/bus".
# For a file directly in root (e.g. "main.go"), prefix is the filename itself.
# ---------------------------------------------------------------------------

LC_ALL=C awk -v is_src="$IS_SOURCE_LANGUAGES" '
BEGIN {
  n = split(is_src, langs, "|")
  for (i = 1; i <= n; i++) src_set[langs[i]] = 1
  in_inventory = 0
}

/^## Full File Inventory/ { in_inventory = 1; next }
in_inventory && /^## / { in_inventory = 0; next }

in_inventory && /^\|/ {
  line = $0
  gsub(/^\||\|$/, "", line)
  n_fields = split(line, fields, "|")
  if (n_fields >= 3) {
    path_raw = fields[1]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", path_raw)
    lang     = fields[2]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", lang)
    # Strip backticks from path
    gsub(/`/, "", path_raw)
    # Only process is_source files
    if (!(lang in src_set)) next
    # Compute top-2-level prefix
    # Split on /
    n_parts = split(path_raw, parts, "/")
    if (n_parts >= 3) {
      prefix = parts[1] "/" parts[2]
    } else if (n_parts == 2) {
      prefix = parts[1] "/" parts[2]
    } else {
      prefix = path_raw
    }
    if (prefix != "" && !(prefix in seen)) {
      seen[prefix] = 1
      rm3++
    }
  }
}

END { print rm3 + 0 }
' "$INDEX" > /tmp/recon_rm3_$$.txt

RM3=$(cat /tmp/recon_rm3_$$.txt | tr -d '[:space:]')
rm -f /tmp/recon_rm3_$$.txt
RM3="${RM3:-0}"; RM3=$(( RM3 + 0 ))

# ---------------------------------------------------------------------------
# RM4: Cross-source (spread >= 2) from candidate-concepts.md Summary.
# Degrade gracefully: missing/empty file => RM4=0 (no error).
#
# candidate-concepts.md Summary format:
#   | Metric | Value |
#   |--------|-------|
#   | Cross-source (spread >= 2) | 17 |
# ---------------------------------------------------------------------------

RM4=0
if [[ -n "$CANDIDATES" && -f "$CANDIDATES" && -s "$CANDIDATES" ]]; then
  RM4=$(LC_ALL=C awk '
    /Cross-source \(spread >= 2\)/ {
      # Row: | Cross-source (spread >= 2) | N |
      line = $0
      gsub(/^\||\|$/, "", line)
      n = split(line, fields, "|")
      if (n >= 2) {
        val = fields[2]
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
        if (val ~ /^[0-9]+$/) { print val + 0; exit }
      }
    }
  ' "$CANDIDATES" | tr -d '[:space:]')
  RM4="${RM4:-0}"; RM4=$(( RM4 + 0 ))
fi

# ---------------------------------------------------------------------------
# Classifier: single indivisible ordered rule
# 1. Greenfield: RM1 <= GF_MAX_FILES AND RM2 <= GF_MAX_LOC
# 2. Brownfield-large: RM2 >= LG_MIN_LOC OR RM3 >= LG_MIN_DIRS OR RM4 >= LG_MIN_CONCEPTS
# 3. Else: Brownfield-small
# ---------------------------------------------------------------------------
TRIPPED=""
PROPOSED_PATH=""

if [[ $RM1 -le $GF_MAX_FILES && $RM2 -le $GF_MAX_LOC ]]; then
  PROPOSED_PATH="GREENFIELD"
  # No thresholds tripped -- both metrics under the greenfield ceiling (gate satisfied, not tripped)
  TRIPPED="none -- greenfield gate satisfied (source_files <= ${GF_MAX_FILES} AND source_loc <= ${GF_MAX_LOC})"
else
  # Check large dimensions
  LARGE_TRIGGERED=0
  TRIPPED_LIST=""
  if [[ $RM2 -ge $LG_MIN_LOC ]]; then
    LARGE_TRIGGERED=1
    TRIPPED_LIST="${TRIPPED_LIST}large_min_source_loc (>= ${LG_MIN_LOC}), "
  fi
  if [[ $RM3 -ge $LG_MIN_DIRS ]]; then
    LARGE_TRIGGERED=1
    TRIPPED_LIST="${TRIPPED_LIST}large_min_dirs (>= ${LG_MIN_DIRS}), "
  fi
  if [[ $RM4 -ge $LG_MIN_CONCEPTS ]]; then
    LARGE_TRIGGERED=1
    TRIPPED_LIST="${TRIPPED_LIST}large_min_concepts (>= ${LG_MIN_CONCEPTS}), "
  fi
  # Strip trailing comma+space
  TRIPPED="${TRIPPED_LIST%, }"

  if [[ $LARGE_TRIGGERED -eq 1 ]]; then
    PROPOSED_PATH="BROWNFIELD-LARGE"
  else
    PROPOSED_PATH="BROWNFIELD-SMALL"
    TRIPPED="none (all large thresholds under their floors)"
  fi
fi

# ---------------------------------------------------------------------------
# Emit recon.md (no timestamps in classification output -- byte-reproducible)
# ---------------------------------------------------------------------------
{
  echo "# Recon Classification"
  echo ""
  echo "## Result"
  echo ""
  echo "| Field | Value |"
  echo "|-------|-------|"
  echo "| Proposed path | ${PROPOSED_PATH} |"
  echo "| RM1 (source files) | ${RM1} |"
  echo "| RM2 (source LOC) | ${RM2} |"
  echo "| RM3 (directories) | ${RM3} |"
  echo "| RM4 (concepts) | ${RM4} |"
  echo "| Tripped thresholds | ${TRIPPED} |"
  echo ""
  echo "## Thresholds"
  echo ""
  echo "| Threshold | Value |"
  echo "|-----------|-------|"
  echo "| greenfield_max_source_files | ${GF_MAX_FILES} |"
  echo "| greenfield_max_source_loc | ${GF_MAX_LOC} |"
  echo "| large_min_source_loc | ${LG_MIN_LOC} |"
  echo "| large_min_dirs | ${LG_MIN_DIRS} |"
  echo "| large_min_concepts | ${LG_MIN_CONCEPTS} |"
  echo ""
  echo "## Rationale"
  echo ""
  if [[ "$PROPOSED_PATH" == "GREENFIELD" ]]; then
    echo "Source metrics are near-zero (RM1=${RM1} <= ${GF_MAX_FILES} files AND RM2=${RM2} <= ${GF_MAX_LOC} LOC)."
    echo "Nothing to discover yet -- run /aid-describe to define the project;"
    echo "the KB fills in as you build, via re-triage once code lands."
  elif [[ "$PROPOSED_PATH" == "BROWNFIELD-LARGE" ]]; then
    echo "One or more large dimensions tripped: ${TRIPPED}."
    echo "Full machinery: researcher fan-out + full 4-mandate review panel + batched closure loop."
  else
    echo "Source is present (RM1=${RM1} > ${GF_MAX_FILES} or RM2=${RM2} > ${GF_MAX_LOC}) but all"
    echo "large thresholds are under their floors. Collapsed path: single understand-pass;"
    echo "one reviewer runs the mandates as sequential passes + clean-context teach-back."
  fi
} > "$OUTPUT"

DISPLAY_OUTPUT=$(realpath "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
echo "[recon] Proposed path: ${PROPOSED_PATH} (RM1=${RM1}, RM2=${RM2}, RM3=${RM3}, RM4=${RM4})" >&2
echo "[recon] Wrote ${DISPLAY_OUTPUT}" >&2
