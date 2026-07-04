#!/usr/bin/env bash
# build-project-index.sh — generate a structured project inventory
# for AID discovery sub-agents.
#
# Runs once before discovery sub-agents dispatch in parallel. The
# resulting markdown index gives every sub-agent a shared view of what
# files exist, eliminating duplicated `find` + `wc` work across 5
# parallel agents.
#
# Output is markdown by design: humans can read it, agents can parse it.
#
# Usage:
#   build-project-index.sh                           # writes to .aid/knowledge/project-index.md
#   build-project-index.sh --output PATH             # write to a different path
#   build-project-index.sh --root PATH               # scan a different root (default: cwd)
#   build-project-index.sh --top-largest 30          # how many largest files to call out (default: 20)
#
# Skips: .git, node_modules, target/build/dist, .idea/.vscode, vendored deps.

set -euo pipefail

OUTPUT=".aid/knowledge/project-index.md"
ROOT="."
TOP_N=20

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)       OUTPUT="$2"; shift 2 ;;
    --root)         ROOT="$2"; shift 2 ;;
    --top-largest)  TOP_N="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "build-project-index.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# Directories to prune from the scan
SKIP_DIRS=(
  .git .svn .hg
  node_modules vendor target build dist out
  .idea .vscode .vs
  __pycache__ .pytest_cache .tox
  .gradle .m2
  bin obj
  .next .nuxt
  .aid
)

# Build the find prune expression
build_prune_expr() {
  local first=1
  for d in "${SKIP_DIRS[@]}"; do
    if [[ $first -eq 1 ]]; then
      printf -- "-name %s " "$d"
      first=0
    else
      printf -- "-o -name %s " "$d"
    fi
  done
}

PRUNE_EXPR=$(build_prune_expr)

# Detect platform-appropriate mtime extraction. We use stat to get
# epoch seconds (portable form: GNU stat -c %Y, BSD stat -f %m), then
# format with date. Both stat flags are detected at startup; missing
# both returns "?".
if stat --version >/dev/null 2>&1; then
  # GNU coreutils (Linux, git-bash on Windows)
  get_mtime() {
    local epoch
    epoch=$(stat -c %Y "$1" 2>/dev/null) || { echo "?"; return; }
    date -d "@$epoch" +%Y-%m-%d 2>/dev/null || echo "?"
  }
elif stat -f %m / >/dev/null 2>&1; then
  # BSD stat (macOS)
  get_mtime() {
    local epoch
    epoch=$(stat -f %m "$1" 2>/dev/null) || { echo "?"; return; }
    date -r "$epoch" +%Y-%m-%d 2>/dev/null || echo "?"
  }
else
  get_mtime() { echo "?"; }
fi

# NOTE: language detection now lives in the awk pass that builds FILES_DATA (Step 3
# below), so the previous per-file shell `detect_lang` -- which forked a subshell per
# file via `lang=$(detect_lang ...)` -- has been removed. The ext->name mapping is
# kept in lockstep inside that awk function.

# Whether a language is "source code" (vs config/data/docs)
is_source() {
  case "$1" in
    Java|Kotlin|Python|JavaScript|TypeScript|Go|Rust|"C#"|"F#"|"C/C++"|Ruby|PHP|Swift|Scala|Elm|Elixir|Erlang|Clojure|Lua|Shell|PowerShell|Vue|Svelte)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Notable manifest/config files (filename only — matched against the file's
# basename, NOT subpaths). Repo-level files like README.md, LICENSE,
# CHANGELOG.md are matched only at root depth (handled by NOTABLE_ROOT below).
NOTABLE_PATTERNS=(
  "package.json" "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
  "tsconfig.json" "jsconfig.json"
  "pom.xml" "build.gradle" "build.gradle.kts" "settings.gradle" "gradle.properties"
  "Cargo.toml" "Cargo.lock"
  "go.mod" "go.sum"
  "requirements.txt" "pyproject.toml" "Pipfile" "poetry.lock" "setup.py" "setup.cfg"
  "Gemfile" "Gemfile.lock"
  "composer.json" "composer.lock"
  "*.csproj" "*.fsproj" "*.sln" "global.json" "Directory.Build.props"
  "Dockerfile" "docker-compose.yml" "docker-compose.yaml"
  ".dockerignore"
  "Makefile" "Rakefile"
  ".gitlab-ci.yml" "Jenkinsfile" "azure-pipelines.yml"
)

# Notable files matched only at repo root (no subpath). These would otherwise
# match too aggressively (every nested README.md, every LICENSE in a vendored dep).
NOTABLE_ROOT=(
  "README.md" "LICENSE" "LICENSE.md" "LICENSE.txt" "CHANGELOG.md" "CONTRIBUTING.md"
)

# Notable files matched by full subpath glob.
NOTABLE_PATH_PATTERNS=(
  ".github/workflows/*.yml"
  ".github/workflows/*.yaml"
)

# Resolve OUTPUT to an absolute path BEFORE we cd into ROOT — otherwise a
# relative output path like ./project-index.md gets written to ROOT instead
# of the caller's cwd.
case "$OUTPUT" in
  /*|[A-Za-z]:[/\\]*)
    # Already absolute (POSIX or Windows drive letter)
    ;;
  *)
    OUTPUT="$PWD/$OUTPUT"
    ;;
esac

# Output destination directory must exist
mkdir -p "$(dirname "$OUTPUT")"

TMP=$(mktemp)
LINE_COUNTS=$(mktemp)
FILES_DATA=$(mktemp)
trap 'rm -f "$TMP" "$LINE_COUNTS" "$FILES_DATA"' EXIT

# Step 1: Collect path + mtime in one find call.
# `find -printf` is a GNU extension (Linux, git-bash on Windows). For BSD
# (macOS), we fall back to per-file mtime via the get_mtime function.
echo "[index] Collecting file paths..." >&2

cd "$ROOT"

if find . -maxdepth 0 -printf '' >/dev/null 2>&1; then
  # GNU find — fast path
  # shellcheck disable=SC2086
  find . \( $PRUNE_EXPR \) -prune -o -type f -printf '%P\t%TY-%Tm-%Td\n' 2>/dev/null \
    | grep -v '^$' \
    | sort > "$TMP"
else
  # BSD find — slower fallback, one mtime call per file
  # shellcheck disable=SC2086
  find . \( $PRUNE_EXPR \) -prune -o -type f -print 2>/dev/null \
    | sed 's|^\./||' \
    | grep -v '^$' \
    | sort > "$TMP.paths"
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    printf '%s\t%s\n' "$f" "$(get_mtime "$f")"
  done < "$TMP.paths" > "$TMP"
  rm -f "$TMP.paths"
fi

TOTAL_FILES=$(wc -l < "$TMP" | tr -d ' ')
echo "[index] Found $TOTAL_FILES files. Counting lines (batched)..." >&2

# Step 2: Batched line counts via xargs wc -l.
# wc -l on N files emits "N count1 path1\n... \n total" — one subprocess
# instead of N. Use NUL separators in case any paths contain spaces.
if [[ $TOTAL_FILES -gt 0 ]]; then
  cut -f1 "$TMP" | tr '\n' '\0' | xargs -0 wc -l 2>/dev/null \
    | sed -E 's/^[[:space:]]+//' \
    | awk 'NF >= 2 && $NF != "total" {
        lines = $1
        $1 = ""
        sub(/^[[:space:]]+/, "")
        print $0 "\t" lines
      }' > "$LINE_COUNTS"
fi

# Step 3: Join path+mtime with line count, plus language detection.
# Build an associative map of path → lines, then walk the path/mtime list.
echo "[index] Detecting languages..." >&2

# Join path+mtime with line-count + language detection in ONE awk pass.
# The previous per-file loop ran `lang=$(detect_lang "$path")` -- a command
# substitution that forks a subshell for EVERY file. On ~1400 files under Windows
# Git Bash / MSYS (~0.5-1.8s/fork) that cost 1-2 min. awk derives the language from
# the extension inline (same ext->name mapping as the shell detect_lang), so there
# are zero per-file spawns. Output (FILES_DATA) is byte-identical to the old loop.
awk -F'\t' -v lcf="$LINE_COUNTS" '
  function detect_lang(path,   ext) {
    ext = path; if (sub(/.*\./, "", ext) == 0) ext = path; ext = tolower(ext)
    if      (ext=="java")                                                              return "Java"
    else if (ext=="kt"||ext=="kts")                                                    return "Kotlin"
    else if (ext=="py")                                                                return "Python"
    else if (ext=="js"||ext=="mjs"||ext=="cjs"||ext=="jsx")                            return "JavaScript"
    else if (ext=="ts"||ext=="tsx"||ext=="mts"||ext=="cts")                            return "TypeScript"
    else if (ext=="go")                                                                return "Go"
    else if (ext=="rs")                                                                return "Rust"
    else if (ext=="cs")                                                                return "C#"
    else if (ext=="fs"||ext=="fsx")                                                    return "F#"
    else if (ext=="cpp"||ext=="cc"||ext=="cxx"||ext=="hpp"||ext=="hxx"||ext=="c"||ext=="h") return "C/C++"
    else if (ext=="rb")                                                                return "Ruby"
    else if (ext=="php")                                                               return "PHP"
    else if (ext=="swift")                                                             return "Swift"
    else if (ext=="scala"||ext=="sc")                                                  return "Scala"
    else if (ext=="elm")                                                               return "Elm"
    else if (ext=="ex"||ext=="exs")                                                    return "Elixir"
    else if (ext=="erl"||ext=="hrl")                                                   return "Erlang"
    else if (ext=="clj"||ext=="cljs"||ext=="cljc")                                     return "Clojure"
    else if (ext=="lua")                                                               return "Lua"
    else if (ext=="sh"||ext=="bash"||ext=="zsh")                                       return "Shell"
    else if (ext=="ps1")                                                               return "PowerShell"
    else if (ext=="sql")                                                               return "SQL"
    else if (ext=="yaml"||ext=="yml")                                                  return "YAML"
    else if (ext=="json")                                                              return "JSON"
    else if (ext=="toml")                                                              return "TOML"
    else if (ext=="xml")                                                               return "XML"
    else if (ext=="md"||ext=="markdown")                                               return "Markdown"
    else if (ext=="css"||ext=="scss"||ext=="sass"||ext=="less")                        return "CSS"
    else if (ext=="html"||ext=="htm")                                                  return "HTML"
    else if (ext=="vue")                                                               return "Vue"
    else if (ext=="svelte")                                                            return "Svelte"
    else                                                                               return "Other"
  }
  BEGIN {
    # path -> line-count map, from LINE_COUNTS (each line: "<path>\t<count>").
    # Split on the FIRST tab (matches the old `read -r p n` with IFS=tab).
    while ((getline line < lcf) > 0) {
      t = index(line, "\t")
      if (t > 0) LINES[substr(line, 1, t-1)] = substr(line, t+1)
    }
  }
  {
    path = $1; mtime = $2
    if (path == "") next
    lines = (path in LINES) ? LINES[path] : 0
    print path "\t" detect_lang(path) "\t" lines "\t" mtime
  }
' "$TMP" > "$FILES_DATA"

# Aggregate by language: count, total lines
LANG_BREAKDOWN=$(awk -F'\t' '
  is_source[$2]==0 && !($2 in seen) { seen[$2]=1 }
  { count[$2]++; total[$2]+=$3 }
  END {
    for (k in count) print k "\t" count[k] "\t" total[k]
  }
' "$FILES_DATA" | sort -t$'\t' -k3 -nr)

TOTAL_LINES=$(awk -F'\t' '{ s+=$3 } END { print s+0 }' "$FILES_DATA")

# Top N largest files (by lines, source code only)
# `head -n N` closes the pipe after N lines; under `set -euo pipefail` the upstream
# `sort` then catches SIGPIPE (exit 141) and would abort the whole script. The captured
# top-N lines are already complete by then, so swallow the benign SIGPIPE with `|| true`.
TOP_LARGEST=$(awk -F'\t' -v src="Java|Kotlin|Python|JavaScript|TypeScript|Go|Rust|C#|F#|C/C++|Ruby|PHP|Swift|Scala|Elm|Elixir|Erlang|Clojure|Lua|Shell|PowerShell|Vue|Svelte" '
  {
    split(src, arr, "|"); is_src=0
    for (i in arr) if ($2==arr[i]) { is_src=1; break }
    if (is_src) print
  }
' "$FILES_DATA" | sort -t$'\t' -k3 -nr | head -n "$TOP_N" || true)

# Notable files (manifests, build configs).
# Three matching modes:
#   1. NOTABLE_PATTERNS — match the basename anywhere in the tree
#   2. NOTABLE_ROOT — match the basename only at repo root (no slash in path)
#   3. NOTABLE_PATH_PATTERNS — match the full relative path against a glob
NOTABLE_FILES=$(mktemp)
trap 'rm -f "$TMP" "$LINE_COUNTS" "$FILES_DATA" "$NOTABLE_FILES"' EXIT

while IFS=$'\t' read -r path lang lines mtime; do
  fname="${path##*/}"
  matched=0

  # Mode 1: basename match anywhere
  for pattern in "${NOTABLE_PATTERNS[@]}"; do
    case "$fname" in
      $pattern) matched=1; break ;;
    esac
  done

  # Mode 2: basename match only at root (path has no slash)
  if [[ $matched -eq 0 && "$path" != */* ]]; then
    for pattern in "${NOTABLE_ROOT[@]}"; do
      case "$fname" in
        $pattern) matched=1; break ;;
      esac
    done
  fi

  # Mode 3: full-path glob match
  if [[ $matched -eq 0 ]]; then
    for pattern in "${NOTABLE_PATH_PATTERNS[@]}"; do
      case "$path" in
        $pattern) matched=1; break ;;
      esac
    done
  fi

  if [[ $matched -eq 1 ]]; then
    printf '%s\t%s\t%s\n' "$path" "$lines" "$mtime" >> "$NOTABLE_FILES"
  fi
done < "$FILES_DATA"

NOTABLE_OUT=$(sort -u "$NOTABLE_FILES" 2>/dev/null || true)

# Emit the markdown index
{
  echo "# Project Index"
  echo
  echo "> Generated by \`.claude/aid/scripts/kb/build-project-index.sh\` for AID discovery."
  echo "> Consumed by all 5 discovery sub-agents to avoid duplicated file enumeration."
  echo
  echo "## Summary"
  echo
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Total files | $TOTAL_FILES |"
  echo "| Total lines | $TOTAL_LINES |"
  echo "| Generated | $(date +%Y-%m-%d) |"
  echo "| Root | \`$ROOT\` |"
  echo
  echo "## Language Breakdown"
  echo
  echo "| Language | Files | Lines |"
  echo "|----------|-------|-------|"
  echo "$LANG_BREAKDOWN" | awk -F'\t' '{ printf "| %s | %s | %s |\n", $1, $2, $3 }'
  echo
  echo "## Notable Files"
  echo
  echo "Manifest, build config, and CI files identified by name."
  echo
  if [[ -z "$NOTABLE_OUT" ]]; then
    echo "_None detected._"
  else
    echo "| Path | Lines | Modified |"
    echo "|------|-------|----------|"
    echo "$NOTABLE_OUT" | awk -F'\t' '{ printf "| `%s` | %s | %s |\n", $1, $2, $3 }'
  fi
  echo
  echo "## Top $TOP_N Largest Source Files"
  echo
  echo "| Path | Language | Lines | Modified |"
  echo "|------|----------|-------|----------|"
  echo "$TOP_LARGEST" | awk -F'\t' '{ printf "| `%s` | %s | %s | %s |\n", $1, $2, $3, $4 }'
  echo
  echo "## Full File Inventory"
  echo
  echo "All files, sorted alphabetically by path. Paths are relative to root."
  echo
  echo "| Path | Language | Lines | Modified |"
  echo "|------|----------|-------|----------|"
  awk -F'\t' '{ printf "| `%s` | %s | %s | %s |\n", $1, $2, $3, $4 }' "$FILES_DATA"
} > "$OUTPUT"

DISPLAY_OUTPUT=$(realpath "$OUTPUT" 2>/dev/null || echo "$OUTPUT" | sed 's|/\./|/|g; s|/\.$||')
echo "[index] Wrote $DISPLAY_OUTPUT ($TOTAL_FILES files, $TOTAL_LINES lines)" >&2
