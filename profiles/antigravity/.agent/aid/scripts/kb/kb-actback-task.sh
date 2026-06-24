#!/usr/bin/env bash
# kb-actback-task.sh -- representative-task selector + operational-structure presence check.
#
# Two functions (f013, task-028):
#
#   Function (1) -- Representative-task selection.
#     Reads the machine-readable doc-set TSV (filename<TAB>owner<TAB>presence, three fields
#     only -- no concern column; see doc-set-resolve.md).  Emits a fixed, reproducible
#     "do this change" representative-task spec keyed to the project's own KB shape.
#
#     Task shape is selected by a small heuristic over present doc-class filenames
#     (priority-ordered, first match wins).  Same KB shape -> byte-identical output.
#     The mapping is calibrated, not load-bearing; adjust via fixture work if needed.
#
#   Function (2) -- Operational-structure presence check.
#     For each doc in the doc-set TSV, grep for the named operational sections and emit:
#       doc | class | present|absent
#     SCOPED PER THE OWNING-TABLE in concern-model.md (canonical/aid/templates/kb-authoring/):
#       each doc is checked ONLY for the classes it is EXPECTED to carry.
#       domain-glossary.md (owns Invariants, not Contracts) is NOT reported
#       "## Contracts absent".
#     Stable-sorted (LC_ALL=C), byte-reproducible (NFR-3).
#
# Usage:
#   kb-actback-task.sh task   --doc-set PATH [--kb-dir PATH] [--output PATH]
#   kb-actback-task.sh check  --doc-set PATH [--kb-dir PATH] [--output PATH]
#   kb-actback-task.sh both   --doc-set PATH [--kb-dir PATH] [--output PATH]
#
#   Subcommands:
#     task   -- emit the representative-task spec (function 1)
#     check  -- emit the operational-structure presence table (function 2)
#     both   -- emit task spec followed by presence table (default)
#
#   --doc-set PATH   TSV file: filename<TAB>owner<TAB>presence (one row per doc).
#                    Accepts the synth_default_seed TSV or a file derived from settings.yml.
#   --kb-dir PATH    Directory containing the KB docs (default: .aid/knowledge).
#   --output PATH    Write output to this file instead of stdout.
#
# Exit codes:
#   0  success (findings are data, not errors)
#   1  input error (required file/dir not found)
#   2  usage error
#
# Invocation path convention (canonical/aid/scripts/kb/kb-actback-task.sh):
#   state-generate.md / state-closure.md render-token convention; full path form.
#   Do NOT drop the aid/ segment (see f013 implementer path-guard note).
#
# Coreutils only (grep/awk/sort/tr/cut/wc/mktemp).
# No LLM, no embedding, no python3, no pwsh.
# ASCII-only (C2; test-ascii-only.sh allow-list entry required).
# Byte-reproducible: LC_ALL=C, sorted, no timestamps (NFR-3).

set -euo pipefail
LC_ALL=C
export LC_ALL

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
SUBCMD="both"
DOC_SET_ARG=""
KB_DIR_ARG=""
OUTPUT_ARG=""

if [[ $# -lt 1 ]]; then
  echo "kb-actback-task.sh: subcommand required (task|check|both)" >&2
  exit 2
fi

case "$1" in
  task|check|both)
    SUBCMD="$1"
    shift
    ;;
  -h|--help)
    sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "kb-actback-task.sh: unknown subcommand: $1 (expected task|check|both)" >&2
    exit 2
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --doc-set)  DOC_SET_ARG="$2"; shift 2 ;;
    --kb-dir)   KB_DIR_ARG="$2";  shift 2 ;;
    --output)   OUTPUT_ARG="$2";  shift 2 ;;
    -h|--help)
      sed -n '2,60p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "kb-actback-task.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
resolve_abs() {
  local p="$1"
  case "$p" in
    /*) echo "$p" ;;
    *)  echo "$PWD/$p" ;;
  esac
}

KB_DIR="${KB_DIR_ARG:-.aid/knowledge}"
KB_DIR="$(resolve_abs "$KB_DIR")"

if [[ -n "$DOC_SET_ARG" ]]; then
  DOC_SET="$(resolve_abs "$DOC_SET_ARG")"
else
  DOC_SET=""
fi

if [[ -n "$OUTPUT_ARG" ]]; then
  OUTPUT_ARG="$(resolve_abs "$OUTPUT_ARG")"
fi

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------
if [[ -z "$DOC_SET" ]]; then
  echo "kb-actback-task.sh: --doc-set is required" >&2
  exit 2
fi

if [[ ! -f "$DOC_SET" ]]; then
  echo "kb-actback-task.sh: --doc-set file not found: $DOC_SET" >&2
  exit 1
fi

if [[ ! -d "$KB_DIR" ]]; then
  echo "kb-actback-task.sh: --kb-dir not found: $KB_DIR" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# OWNING-TABLE (encoded from concern-model.md, "Operational guidance is first-class
# structure" subsection; single source of truth for scoped presence check).
#
# Source: canonical/aid/templates/kb-authoring/concern-model.md
#
# Conventions -> coding-standards.md, module-map.md, pipeline-contracts.md  (C3/C2/C5)
# Invariants  -> architecture.md, module-map.md, domain-glossary.md         (C1/C2/C4)
# Gotchas     -> tech-debt.md (fixed default owner; C7)
# Contracts   -> schemas.md, pipeline-contracts.md, integration-map.md      (C5/C2)
#
# _doc_expects_class DOC CLASS
#   Returns 0 (true) if the owning-table maps DOC as an expected owner of CLASS.
#   Returns 1 (false) otherwise.
#   This prevents over-reporting: a doc not mapped for class X is NOT checked for X.
# ---------------------------------------------------------------------------
_doc_expects_class() {
  local doc="$1"
  local class="$2"

  case "$class" in
    Conventions)
      case "$doc" in
        coding-standards.md|module-map.md|pipeline-contracts.md) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    Invariants)
      case "$doc" in
        architecture.md|module-map.md|domain-glossary.md) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    Gotchas)
      case "$doc" in
        tech-debt.md) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    Contracts)
      case "$doc" in
        schemas.md|pipeline-contracts.md|integration-map.md) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Parse the doc-set TSV into a sorted list of filenames.
# TSV format: filename<TAB>owner<TAB>presence (three fields; no concern column).
# Skips blank lines and comment lines.
# ---------------------------------------------------------------------------
_parse_docset() {
  local tsv="$1"
  awk -F'\t' '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*#/ { next }
    NF >= 1 {
      fn = $1
      sub(/^[[:space:]]+/, "", fn)
      sub(/[[:space:]]+$/, "", fn)
      if (fn != "" && fn != "filename") print fn
    }
  ' "$tsv" | sort -u
}

# ---------------------------------------------------------------------------
# Function (1): Representative-task selection
#
# Parse the doc-set TSV; pattern-match key filenames to pick a task shape
# (heuristic, priority-ordered, first match wins); emit the fixed task spec.
# Same filenames -> byte-identical output.
# ---------------------------------------------------------------------------
_run_task() {
  local tsv="$1"
  local kb_dir="$2"

  # Parse filenames from TSV (sorted for determinism)
  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  # Check which key filenames are present in the doc-set
  local has_schemas=0
  local has_pipeline_contracts=0
  local has_module_map=0
  local has_coding_standards=0
  local has_architecture=0
  local has_feature_inventory=0

  while IFS= read -r fname; do
    case "$fname" in
      schemas.md)            has_schemas=1 ;;
      pipeline-contracts.md) has_pipeline_contracts=1 ;;
      module-map.md)         has_module_map=1 ;;
      coding-standards.md)   has_coding_standards=1 ;;
      architecture.md)       has_architecture=1 ;;
      feature-inventory.md)  has_feature_inventory=1 ;;
    esac
  done < "$files_tmp"

  # Task-shape heuristic (filename profile -> representative change; calibrated, not load-bearing).
  local task_type="endpoint"
  if [[ $has_schemas -eq 1 || $has_pipeline_contracts -eq 1 ]]; then
    task_type="contract"
  elif [[ $has_module_map -eq 1 && $has_coding_standards -eq 1 ]]; then
    task_type="module"
  elif [[ $has_architecture -eq 1 && $has_coding_standards -eq 1 ]]; then
    task_type="component"
  elif [[ $has_feature_inventory -eq 1 ]]; then
    task_type="feature"
  fi

  # Emit the representative-task spec (fixed, labelled block -- byte-reproducible)
  echo "## Representative Task Spec"
  echo ""
  echo "**Act-back mandate (M4) -- clean-context operational probe**"
  echo ""
  echo "Using ONLY the KB docs provided, perform the following representative task"
  echo "for this project.  Produce a correct plan/outline for the change in the"
  echo "project's own conventions, AND flag every point where the KB was insufficient"
  echo "(every assumption made, every invariant guessed, every convention missing,"
  echo "every contract not stated)."
  echo ""
  echo "**Task shape: ${task_type}**"
  echo ""

  case "$task_type" in
    contract)
      echo "**Task:** Add a new field to a data contract or schema."
      echo ""
      echo "Specifically:"
      echo "1. Identify which contract/schema the new field belongs to, using the KB."
      echo "2. Describe the exact steps to add the field: name, type, validation,"
      echo "   and any invariants it must satisfy."
      echo "3. List all downstream consumers of the contract that must be updated,"
      echo "   as described in the KB."
      echo "4. State the conventions for naming and typing the new field (from the KB)."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    module)
      echo "**Task:** Wire a new module into the system."
      echo ""
      echo "Specifically:"
      echo "1. Identify the correct location and naming convention for the new module,"
      echo "   using the KB."
      echo "2. Describe how to register/connect the module to the existing system"
      echo "   (following the project's conventions, as stated in the KB)."
      echo "3. List the invariants the new module must satisfy."
      echo "4. Identify any gotchas or non-obvious steps the KB warns about."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    component)
      echo "**Task:** Add a new component to the architecture."
      echo ""
      echo "Specifically:"
      echo "1. Identify where the new component fits in the architecture, using the KB."
      echo "2. Describe the conventions for naming and structuring the component"
      echo "   (from the KB)."
      echo "3. List the integration points and contracts the component must satisfy."
      echo "4. Identify any architectural invariants that constrain the addition."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    feature)
      echo "**Task:** Add a new user-facing feature to the project."
      echo ""
      echo "Specifically:"
      echo "1. Describe how the new feature fits into the existing feature inventory,"
      echo "   using the KB."
      echo "2. List the conventions for implementing and exposing the feature"
      echo "   (from the KB)."
      echo "3. Identify the contracts (APIs, schemas) the feature must satisfy or extend."
      echo "4. Note any quality/testing expectations the KB describes for new features."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
    endpoint|*)
      echo "**Task:** Add a new endpoint (or equivalent entry point) to the project."
      echo ""
      echo "Specifically:"
      echo "1. Identify the correct location and naming convention for the new endpoint,"
      echo "   using the KB."
      echo "2. Describe the registration/wiring steps following the project's conventions"
      echo "   (as stated in the KB)."
      echo "3. List the contracts (request/response shape, invariants) the endpoint must"
      echo "   satisfy, as described in the KB."
      echo "4. Note any gotchas or non-obvious steps the KB warns about."
      echo "5. Flag every point where the KB did not provide the necessary guidance"
      echo "   and you had to assume or guess."
      ;;
  esac

  echo ""
  echo "**Scoring:**"
  echo "- PASS: a correct, executable plan is producible from the KB alone, with no"
  echo "  insufficiency flags."
  echo "- FAIL: the plan cannot be produced correctly from the KB, OR any insufficiency"
  echo "  flag is raised.  Each flag is a [HIGH] [ACTBACK] finding."
  echo ""
  echo "**Doc set used for this task (machine-readable substrate):**"
  # Emit sorted filename list (from already-sorted files_tmp)
  while IFS= read -r fn; do
    echo "- ${fn}"
  done < "$files_tmp"

  rm -f "$files_tmp"
}

# ---------------------------------------------------------------------------
# Function (2): Operational-structure presence check
#
# For each doc in the doc-set TSV:
#   - Determine which operational classes the doc is EXPECTED to carry
#     (via the owning-table encoded in _doc_expects_class above).
#   - Also auto-detect: if a doc outside the fixed table carries a section,
#     it is reported as present (opt-in ownership).
#   - Grep for the named section headings: ## Conventions / ## Invariants /
#     ## Gotchas / ## Contracts.
#   - Emit: doc | class | present|absent
#     ONLY for expected classes (prevents over-reporting legitimate absences).
#
# Output: stable-sorted (LC_ALL=C sort), byte-reproducible.
# Table format mirrors closure-check.sh's coverage-table shape.
# ---------------------------------------------------------------------------
_run_check() {
  local tsv="$1"
  local kb_dir="$2"

  echo "## Operational-Structure Presence Check"
  echo ""
  echo "| doc | class | status |"
  echo "|-----|-------|--------|"

  # Build rows in a temp file for stable sorting
  local rows_tmp
  rows_tmp="$(mktemp)"

  local files_tmp
  files_tmp="$(mktemp)"
  _parse_docset "$tsv" > "$files_tmp"

  while IFS= read -r fname; do
    local doc_path="${kb_dir}/${fname}"

    for class in Conventions Invariants Gotchas Contracts; do
      # Check owning-table: is this doc expected to carry this class?
      local expected=0
      if _doc_expects_class "$fname" "$class"; then
        expected=1
      fi

      # Check if the section is actually present in the KB doc
      local section_present=0
      if [[ -f "$doc_path" ]]; then
        if LC_ALL=C grep -qE "^## ${class}[[:space:]]*$" "$doc_path" 2>/dev/null; then
          section_present=1
        fi
      fi

      # Emit a row only when:
      #   (a) the owning-table marks this doc as an expected owner (may be absent -> finding)
      #   (b) OR the section is actually present (auto-detect opt-in ownership -> present)
      # This prevents false-absent for non-owner docs (e.g. domain-glossary.md for Contracts)
      # while still surfacing opt-in sections carried outside the default set.
      if [[ $expected -eq 1 || $section_present -eq 1 ]]; then
        local status="absent"
        [[ $section_present -eq 1 ]] && status="present"
        printf '| %s | %s | %s |\n' "$fname" "$class" "$status" >> "$rows_tmp"
      fi
    done
  done < "$files_tmp"

  rm -f "$files_tmp"

  # Stable sort for byte-reproducibility (LC_ALL=C already exported)
  sort "$rows_tmp"
  rm -f "$rows_tmp"
}

# ---------------------------------------------------------------------------
# Main dispatch
# ---------------------------------------------------------------------------
_main() {
  local subcmd="$1"
  local tsv="$2"
  local kb_dir="$3"
  local output="$4"

  local out_tmp
  out_tmp="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '$out_tmp'" EXIT

  case "$subcmd" in
    task)
      _run_task "$tsv" "$kb_dir" > "$out_tmp"
      ;;
    check)
      _run_check "$tsv" "$kb_dir" > "$out_tmp"
      ;;
    both)
      _run_task "$tsv" "$kb_dir" > "$out_tmp"
      echo "" >> "$out_tmp"
      _run_check "$tsv" "$kb_dir" >> "$out_tmp"
      ;;
  esac

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    cp "$out_tmp" "$output"
    echo "[kb-actback-task] Wrote output to $output" >&2
  else
    cat "$out_tmp"
  fi
}

_main "$SUBCMD" "$DOC_SET" "$KB_DIR" "$OUTPUT_ARG"
echo "[kb-actback-task] Done." >&2
