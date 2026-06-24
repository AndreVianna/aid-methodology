#!/usr/bin/env bash
# harvest-coined-terms.sh -- deterministic coined-term harvest for AID essence capture.
#
# Scans all source types (code / docs / config / comments / history) and emits a
# ranked candidate-concept list (project-coined x recurring x cross-source) to
# .aid/generated/candidate-concepts.md (or --output PATH).
#
# Extraction classes:
#   E1  Identifiers:              [A-Za-z_][A-Za-z0-9_]* tokens from source-code files
#   E2  CamelCase / PascalCase:   [A-Z][a-z]+([A-Z][a-z0-9]+)+ (>=2 humps); kept both
#                                  joined (RelativeBus) AND split (Relative Bus)
#   E3  snake / kebab compounds:  [a-z0-9]+([_-][a-z0-9]+)+ (>=1 separator)
#   E4  Capitalized multi-word:   runs of 2-4 [A-Z][a-z]+ words from prose
#   E5  Quoted strings:           single/double/backtick-quoted strings (<=4 words)
#
# Channels (each file classified into exactly one):
#   code     source-code files (is_source languages)
#   docs     .md/.rst/.txt/.adoc + anything under docs/ adr*/ doc/
#   config   .yml/.yaml/.toml/.json/.ini + notable manifests
#   comments comment lines extracted from code files
#   history  git log subjects/bodies (degrade-gracefully on non-git trees)
#
# Denylist filter: a candidate survives iff at least one component word is NOT in
# the denylist.  Whole-phrase escape: a phrase whose every word is common survives
# if the phrase itself is not in the denylist AND it clears cross-source spread>=2
# (the 'Relative Bus' mechanism).
#
# Salience = freq * (1 + 2*(spread-1))
# Ranking: salience desc, spread desc, term asc (stable, CI-reproducible).
# Emits: top --top (default 60) PLUS every candidate with spread>=3.
#
# Project local override: .aid/knowledge/.coined-term-denylist.local.txt (comm-unioned).
#
# Usage:
#   harvest-coined-terms.sh [--root PATH] [--output PATH] [--denylist PATH]
#                           [--top N] [--history-file PATH]
#
# Mirrors build-project-index.sh flag shape; copies its SKIP_DIRS prune set and
# absolute-OUTPUT-before-cd resolution (lines kept in lockstep with that script).

set -euo pipefail

OUTPUT=".aid/generated/candidate-concepts.md"
ROOT="."
DENYLIST=""
TOP_N=60
HISTORY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)       OUTPUT="$2";       shift 2 ;;
    --root)         ROOT="$2";         shift 2 ;;
    --denylist)     DENYLIST="$2";     shift 2 ;;
    --top)          TOP_N="$2";        shift 2 ;;
    --history-file) HISTORY_FILE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "harvest-coined-terms.sh: unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Directories to prune (kept in lockstep with build-project-index.sh)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Resolve OUTPUT to absolute path BEFORE cd into ROOT (mirrors build-project-index.sh)
# ---------------------------------------------------------------------------
case "$OUTPUT" in
  /*|[A-Za-z]:[/\\]*)
    ;;
  *)
    OUTPUT="$PWD/$OUTPUT"
    ;;
esac

# Similarly resolve DENYLIST and HISTORY_FILE to absolute paths before cd
if [[ -n "$DENYLIST" ]]; then
  case "$DENYLIST" in
    /*|[A-Za-z]:[/\\]*) ;;
    *) DENYLIST="$PWD/$DENYLIST" ;;
  esac
fi

if [[ -n "$HISTORY_FILE" ]]; then
  case "$HISTORY_FILE" in
    /*|[A-Za-z]:[/\\]*) ;;
    *) HISTORY_FILE="$PWD/$HISTORY_FILE" ;;
  esac
fi

mkdir -p "$(dirname "$OUTPUT")"

# ---------------------------------------------------------------------------
# Language detection (kept in lockstep with build-project-index.sh)
# ---------------------------------------------------------------------------
detect_lang() {
  local ext="${1##*.}"
  ext="${ext,,}"
  case "$ext" in
    java)                   echo "Java" ;;
    kt|kts)                 echo "Kotlin" ;;
    py)                     echo "Python" ;;
    js|mjs|cjs|jsx)         echo "JavaScript" ;;
    ts|tsx|mts|cts)         echo "TypeScript" ;;
    go)                     echo "Go" ;;
    rs)                     echo "Rust" ;;
    cs)                     echo "C#" ;;
    fs|fsx)                 echo "F#" ;;
    cpp|cc|cxx|hpp|hxx|c|h) echo "C/C++" ;;
    rb)                     echo "Ruby" ;;
    php)                    echo "PHP" ;;
    swift)                  echo "Swift" ;;
    scala|sc)               echo "Scala" ;;
    elm)                    echo "Elm" ;;
    ex|exs)                 echo "Elixir" ;;
    erl|hrl)                echo "Erlang" ;;
    clj|cljs|cljc)          echo "Clojure" ;;
    lua)                    echo "Lua" ;;
    sh|bash|zsh)            echo "Shell" ;;
    ps1)                    echo "PowerShell" ;;
    sql)                    echo "SQL" ;;
    yaml|yml)               echo "YAML" ;;
    json)                   echo "JSON" ;;
    toml)                   echo "TOML" ;;
    xml)                    echo "XML" ;;
    md|markdown)            echo "Markdown" ;;
    css|scss|sass|less)     echo "CSS" ;;
    html|htm)               echo "HTML" ;;
    vue)                    echo "Vue" ;;
    svelte)                 echo "Svelte" ;;
    *)                      echo "Other" ;;
  esac
}

# Whether a language is "source code" (vs config/data/docs)
is_source() {
  case "$1" in
    Java|Kotlin|Python|JavaScript|TypeScript|Go|Rust|"C#"|"F#"|"C/C++"|Ruby|PHP|Swift|Scala|Elm|Elixir|Erlang|Clojure|Lua|Shell|PowerShell|Vue|Svelte)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

# Classify a file path into one of the 5 channels.
# Returns: code | docs | config | comments | (empty = skip)
# Note: "comments" is synthesized from code-file lines, not a separate file class.
classify_channel() {
  local path="$1"
  local lang="$2"

  if is_source "$lang"; then
    echo "code"
    return
  fi

  local ext="${path##*.}"
  ext="${ext,,}"
  local base="${path##*/}"
  local base_lower="${base,,}"

  # docs: prose files
  case "$ext" in
    md|markdown|rst|txt|adoc|asciidoc) echo "docs"; return ;;
  esac

  # docs: path-based
  case "$path" in
    docs/*|doc/*|documentation/*|adr*/*|adrs/*|.github/*)
      echo "docs"; return ;;
  esac

  # config: well-known extensions + manifests
  case "$ext" in
    yml|yaml|toml|json|ini|cfg|conf|properties|lock|xml)
      echo "config"; return ;;
  esac

  # config: notable manifest basenames
  case "$base_lower" in
    makefile|rakefile|dockerfile|gemfile|pipfile|podfile|\
    cmakelists.txt|build.gradle|pom.xml|cargo.toml|go.mod|\
    requirements.txt|setup.py|pyproject.toml|composer.json|\
    package.json|tsconfig.json|jsconfig.json)
      echo "config"; return ;;
  esac

  # fallback: skip (binary, unknown, etc.)
  echo ""
}

# ---------------------------------------------------------------------------
# Comment-line extraction patterns (used to synthesize the "comments" channel)
# ---------------------------------------------------------------------------
is_comment_line() {
  local line="$1"
  # Strip leading whitespace, then check for common comment prefixes
  local stripped
  stripped=$(echo "$line" | sed 's/^[[:space:]]*//')
  case "$stripped" in
    "#"*|"//"*|"--"*|";"*) return 0 ;;
    "/*"*|"*"*) return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Word splitting helpers
# ---------------------------------------------------------------------------

# Split a CamelCase/PascalCase token into space-separated words (lowercase).
# RelativeBus -> relative bus
split_camel() {
  echo "$1" | sed -E \
    's/([a-z0-9])([A-Z])/\1 \2/g;
     s/([A-Z]+)([A-Z][a-z])/\1 \2/g' | tr '[:upper:]' '[:lower:]'
}

# Split a snake/kebab compound into space-separated words (lowercase).
# relative_bus -> relative bus
split_compound() {
  echo "$1" | tr '_-' ' ' | tr '[:upper:]' '[:lower:]'
}

# Lower-case a phrase for denylist lookup.
lowercase_phrase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# ---------------------------------------------------------------------------
# Load denylist into a temp file for fast lookup.
# ---------------------------------------------------------------------------
DENYLIST_FILE=$(mktemp)
trap 'rm -f "$DENYLIST_FILE"' EXIT

if [[ -n "$DENYLIST" && -f "$DENYLIST" ]]; then
  # Start with the supplied denylist, already sorted+lowercased
  cat "$DENYLIST" > "$DENYLIST_FILE"
fi

# Check for local override in root (resolved after cd since it's inside the project)
# We store the path for post-cd check.
LOCAL_DENYLIST_REL=".aid/knowledge/.coined-term-denylist.local.txt"

# ---------------------------------------------------------------------------
# Denylist lookup: is a single word in the denylist?
# Returns 0 (true) if in denylist, 1 if not.
# ---------------------------------------------------------------------------
word_in_denylist() {
  local word
  word=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  # grep -qFx for exact line match
  grep -qFx "$word" "$DENYLIST_FILE" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Filter a candidate term.
# Returns 0 (survive unconditionally) if at least one component word is NOT
# in the denylist -- the term is genuinely project-coined.
# Returns 1 (needs-phrase-escape or drop) for all-common-word terms.
#   - If ALL words are common AND term is a multi-word phrase not in the
#     denylist, the caller applies the salience floor (spread>=2) to decide.
#   - If ALL words are common AND (single word OR phrase is in denylist), drop.
#
# The caller handles the phrase-escape case:
#   if ! candidate_survives term class; then
#     # multi-word AND phrase not in denylist AND spread>=2 -> survive
#     # otherwise -> drop
#   fi
# ---------------------------------------------------------------------------
# Args: $1=term, $2=class (camel|snake|phrase|quoted|identifier)
candidate_survives() {
  local term="$1"
  local class="$2"

  # Split into component words
  local words
  case "$class" in
    camel)
      words=$(split_camel "$term")
      ;;
    snake)
      words=$(split_compound "$term")
      ;;
    phrase)
      words=$(echo "$term" | tr '[:upper:]' '[:lower:]')
      ;;
    quoted)
      # Remove quotes, lowercase
      words=$(echo "$term" | tr -d '"'"'"'`' | tr '[:upper:]' '[:lower:]')
      ;;
    identifier)
      words=$(echo "$term" | tr '[:upper:]' '[:lower:]')
      ;;
    *)
      words=$(echo "$term" | tr '[:upper:]' '[:lower:]')
      ;;
  esac

  # Check if ANY word is NOT in denylist
  local all_common=1
  for word in $words; do
    [[ -z "$word" ]] && continue
    if ! word_in_denylist "$word"; then
      all_common=0
      break
    fi
  done

  if [[ $all_common -eq 0 ]]; then
    # At least one word is project-coined -> survive unconditionally
    return 0
  fi

  # All words are common.
  # Return 1 so the caller can apply the phrase-escape + spread>=2 floor.
  return 1
}

# ---------------------------------------------------------------------------
# Check if a term qualifies for the whole-phrase escape.
# A multi-word phrase whose every component word is common survives if:
#   (a) the phrase itself is NOT in the denylist, AND
#   (b) it has spread >= 2 (enforced at emission time by the caller).
# Returns 0 if the phrase qualifies for the escape; 1 otherwise.
# ---------------------------------------------------------------------------
# Args: $1=term, $2=class
phrase_escape_qualifies() {
  local term="$1"
  local class="$2"

  # Only multi-word terms qualify
  local word_count
  word_count=$(echo "$term" | wc -w | tr -d ' ')
  # For CamelCase, the split may be multi-word even if the token has no spaces
  if [[ "$class" == "camel" ]]; then
    local split_words
    split_words=$(split_camel "$term")
    word_count=$(echo "$split_words" | wc -w | tr -d ' ')
  fi

  [[ "$word_count" -le 1 ]] && return 1

  # The phrase itself must NOT be in the denylist
  local phrase_lower
  phrase_lower=$(lowercase_phrase "$term")
  if word_in_denylist "$phrase_lower"; then
    return 1
  fi

  # Qualifies for the escape (caller still must check spread>=2)
  return 0
}

# ---------------------------------------------------------------------------
# Temporary files for accumulating extracted terms
# ---------------------------------------------------------------------------
TERMS_FILE=$(mktemp)
COMMENTS_FILE=$(mktemp)
HISTORY_FILE_TMP=$(mktemp)
trap 'rm -f "$DENYLIST_FILE" "$TERMS_FILE" "$COMMENTS_FILE" "$HISTORY_FILE_TMP"' EXIT

# ---------------------------------------------------------------------------
# cd into ROOT for scanning
# ---------------------------------------------------------------------------
cd "$ROOT"

# Now check for local denylist override
if [[ -f "$LOCAL_DENYLIST_REL" ]]; then
  # comm-union: merge sorted lists (both must be sorted+lowercased)
  local_sorted=$(mktemp)
  sort -f "$LOCAL_DENYLIST_REL" | tr '[:upper:]' '[:lower:]' | sort > "$local_sorted"
  if [[ -s "$DENYLIST_FILE" ]]; then
    comm -23 "$local_sorted" "$DENYLIST_FILE" >> "$DENYLIST_FILE" 2>/dev/null || true
    sort -o "$DENYLIST_FILE" "$DENYLIST_FILE"
  else
    cp "$local_sorted" "$DENYLIST_FILE"
  fi
  rm -f "$local_sorted"
fi

echo "[harvest] Scanning files under $ROOT ..." >&2

# ---------------------------------------------------------------------------
# Channel scan: iterate all files under ROOT
# ---------------------------------------------------------------------------

# We accumulate lines of: TERM<TAB>CHANNEL<TAB>FILE
# for later aggregation.

# shellcheck disable=SC2086
while IFS= read -r filepath; do
  [[ -z "$filepath" ]] && continue
  # Skip non-readable files
  [[ -r "$filepath" ]] || continue
  # Skip binary files (heuristic: null bytes in first 512 bytes)
  if LC_ALL=C grep -qP '\x00' "$filepath" 2>/dev/null; then
    continue
  fi

  lang=$(detect_lang "$filepath")
  channel=$(classify_channel "$filepath" "$lang")
  [[ -z "$channel" ]] && continue

  # E1: Identifiers from source code files (code channel)
  # E2: CamelCase/PascalCase from code + docs
  # E3: snake/kebab compounds from code + config
  # E4: Capitalized multi-word phrases from docs + comments + history
  # E5: Quoted strings from code + docs

  if [[ "$channel" == "code" ]]; then
    # E1: all [A-Za-z_][A-Za-z0-9_]* tokens (identifiers)
    # We extract and emit them, then filter denylist later
    LC_ALL=C grep -oE '[A-Za-z_][A-Za-z0-9_]+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          # Only keep tokens with >=4 chars (drop short noise)
          [[ ${#tok} -ge 4 ]] || continue
          printf '%s\tcode\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

    # E2: CamelCase (>=2 humps) from code - emit both joined and split
    LC_ALL=C grep -oE '[A-Z][a-z]+([A-Z][a-z0-9]+)+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          printf '%s\tcode\t%s\n' "$tok" "$filepath"
          # Also emit split form as phrase
          split=$(split_camel "$tok")
          # Capitalize first letter of each word for the phrase form
          phrase=$(echo "$split" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
          printf '%s\tcode\t%s\n' "$phrase" "$filepath"
        done >> "$TERMS_FILE" || true

    # E3: snake/kebab compounds from code
    LC_ALL=C grep -oE '[a-z0-9]+([_-][a-z0-9]+)+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          [[ ${#tok} -ge 5 ]] || continue
          printf '%s\tcode\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

    # E5: quoted strings (short, <=4 words) from code
    LC_ALL=C grep -oE '"[A-Za-z][A-Za-z0-9 _-]{2,30}"' "$filepath" 2>/dev/null \
      | sed 's/"//g' \
      | while IFS= read -r tok; do
          word_count=$(echo "$tok" | wc -w | tr -d ' ')
          [[ "$word_count" -le 4 ]] || continue
          printf '%s\tcode\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

    # Comments channel: extract comment lines from code files
    LC_ALL=C grep -nE '^\s*(#|//|--|;|/\*|\*)' "$filepath" 2>/dev/null \
      | sed 's/^[0-9]*://' >> "$COMMENTS_FILE" || true

  elif [[ "$channel" == "docs" ]]; then
    # E2: CamelCase from docs
    LC_ALL=C grep -oE '[A-Z][a-z]+([A-Z][a-z0-9]+)+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          printf '%s\tdocs\t%s\n' "$tok" "$filepath"
          split=$(split_camel "$tok")
          phrase=$(echo "$split" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
          printf '%s\tdocs\t%s\n' "$phrase" "$filepath"
        done >> "$TERMS_FILE" || true

    # E4: Capitalized multi-word phrases (2-4 words) from docs
    # Match 2-4 consecutive capitalized words
    LC_ALL=C grep -oE '([A-Z][a-z]+[[:space:]]+){1,3}[A-Z][a-z]+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          tok=$(echo "$tok" | sed 's/[[:space:]]*$//')
          word_count=$(echo "$tok" | wc -w | tr -d ' ')
          [[ "$word_count" -ge 2 && "$word_count" -le 4 ]] || continue
          printf '%s\tdocs\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

    # E5: quoted strings from docs
    LC_ALL=C grep -oE '"[A-Za-z][A-Za-z0-9 _-]{2,30}"' "$filepath" 2>/dev/null \
      | sed 's/"//g' \
      | while IFS= read -r tok; do
          word_count=$(echo "$tok" | wc -w | tr -d ' ')
          [[ "$word_count" -le 4 ]] || continue
          printf '%s\tdocs\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

  elif [[ "$channel" == "config" ]]; then
    # E3: snake/kebab from config
    LC_ALL=C grep -oE '[a-z0-9]+([_-][a-z0-9]+)+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          [[ ${#tok} -ge 5 ]] || continue
          printf '%s\tconfig\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true

    # E2: CamelCase from config (e.g. class names in YAML/JSON)
    LC_ALL=C grep -oE '[A-Z][a-z]+([A-Z][a-z0-9]+)+' "$filepath" 2>/dev/null \
      | while IFS= read -r tok; do
          printf '%s\tconfig\t%s\n' "$tok" "$filepath"
        done >> "$TERMS_FILE" || true
  fi

# shellcheck disable=SC2086
done < <(find . \( $PRUNE_EXPR \) -prune -o -type f -print 2>/dev/null | sed 's|^\./||' | sort)

# ---------------------------------------------------------------------------
# Extract from comments channel (from collected comment lines above)
# ---------------------------------------------------------------------------
if [[ -s "$COMMENTS_FILE" ]]; then
  # E4: Capitalized multi-word phrases from comments
  LC_ALL=C grep -oE '([A-Z][a-z]+[[:space:]]+){1,3}[A-Z][a-z]+' "$COMMENTS_FILE" 2>/dev/null \
    | while IFS= read -r tok; do
        tok=$(echo "$tok" | sed 's/[[:space:]]*$//')
        word_count=$(echo "$tok" | wc -w | tr -d ' ')
        [[ "$word_count" -ge 2 && "$word_count" -le 4 ]] || continue
        printf '%s\tcomments\tcomments\n' "$tok"
      done >> "$TERMS_FILE" || true

  # E2: CamelCase from comments
  LC_ALL=C grep -oE '[A-Z][a-z]+([A-Z][a-z0-9]+)+' "$COMMENTS_FILE" 2>/dev/null \
    | while IFS= read -r tok; do
        printf '%s\tcomments\tcomments\n' "$tok"
        split=$(split_camel "$tok")
        phrase=$(echo "$split" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
        printf '%s\tcomments\tcomments\n' "$phrase"
      done >> "$TERMS_FILE" || true
fi

# ---------------------------------------------------------------------------
# History channel: git log (degrade-gracefully on non-git trees)
# ---------------------------------------------------------------------------
HISTORY_TERMS=$(mktemp)
trap 'rm -f "$DENYLIST_FILE" "$TERMS_FILE" "$COMMENTS_FILE" "$HISTORY_FILE_TMP" "$HISTORY_TERMS"' EXIT

if git rev-parse --git-dir >/dev/null 2>&1; then
  # Git tree: harvest from commit subjects and bodies.
  # Strip commit-trailer lines and bot-signature lines before harvesting so that
  # model names (Claude Sonnet, Claude Opus), author names, session hashes, and
  # the "Generated with" bot signature do not dominate the ranked output.
  # Excluded prefixes (case-insensitive):
  #   Co-Authored-By: / Co-authored-by:  -- authorship trailers
  #   Claude-Session:                     -- session-URL trailers
  #   Signed-off-by:                      -- DCO/SOB trailers
  # Excluded substrings:
  #   "Generated with"                    -- bot signature line
  #   "<noreply@"                         -- email addresses in trailers
  git log --format='%s%n%b' -n 500 2>/dev/null \
    | grep -viE '^(co-authored-by|co-authored_by|claude-session|signed-off-by|reviewed-by):' \
    | grep -viF 'Generated with' \
    | grep -viF '<noreply@' \
    > "$HISTORY_FILE_TMP" || true
fi

# Also include --history-file if supplied
if [[ -n "$HISTORY_FILE" && -f "$HISTORY_FILE" ]]; then
  # Apply the same trailer-strip filter to externally-supplied history files
  grep -viE '^(co-authored-by|co-authored_by|claude-session|signed-off-by|reviewed-by):' "$HISTORY_FILE" \
    | grep -viF 'Generated with' \
    | grep -viF '<noreply@' \
    >> "$HISTORY_FILE_TMP" || true
fi

if [[ -s "$HISTORY_FILE_TMP" ]]; then
  # E4: Capitalized multi-word phrases from history
  LC_ALL=C grep -oE '([A-Z][a-z]+[[:space:]]+){1,3}[A-Z][a-z]+' "$HISTORY_FILE_TMP" 2>/dev/null \
    | while IFS= read -r tok; do
        tok=$(echo "$tok" | sed 's/[[:space:]]*$//')
        word_count=$(echo "$tok" | wc -w | tr -d ' ')
        [[ "$word_count" -ge 2 && "$word_count" -le 4 ]] || continue
        printf '%s\thistory\tgit-log\n' "$tok"
      done >> "$TERMS_FILE" || true

  # E2: CamelCase from history
  LC_ALL=C grep -oE '[A-Z][a-z]+([A-Z][a-z0-9]+)+' "$HISTORY_FILE_TMP" 2>/dev/null \
    | while IFS= read -r tok; do
        printf '%s\thistory\tgit-log\n' "$tok"
        split=$(split_camel "$tok")
        phrase=$(echo "$split" | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2); print}')
        printf '%s\thistory\tgit-log\n' "$phrase"
      done >> "$TERMS_FILE" || true
fi

echo "[harvest] Aggregating and ranking candidates..." >&2

# ---------------------------------------------------------------------------
# Aggregation: compute freq, spread, channels, example_source per term
# ---------------------------------------------------------------------------
# TERMS_FILE format: TERM<TAB>CHANNEL<TAB>FILE
# We need to:
#   1. Count freq (total occurrences) per term
#   2. Count distinct channels per term (spread)
#   3. Collect distinct channels list per term
#   4. Pick one example source file per term

# Use awk to aggregate
AGGREGATED=$(mktemp)
trap 'rm -f "$DENYLIST_FILE" "$TERMS_FILE" "$COMMENTS_FILE" "$HISTORY_FILE_TMP" "$HISTORY_TERMS" "$AGGREGATED"' EXIT

if [[ -s "$TERMS_FILE" ]]; then
  awk -F'\t' '
  {
    term = $1
    channel = $2
    file = $3
    freq[term]++
    channels[term][channel] = 1
    if (!(term in example)) example[term] = file
  }
  END {
    for (term in freq) {
      # Build channel list and count spread
      spread = 0
      chan_list = ""
      for (ch in channels[term]) {
        spread++
        if (chan_list == "") chan_list = ch
        else chan_list = chan_list "," ch
      }
      print term "\t" freq[term] "\t" spread "\t" chan_list "\t" example[term]
    }
  }
  ' "$TERMS_FILE" > "$AGGREGATED"
fi

# ---------------------------------------------------------------------------
# Apply denylist filter + compute salience + classify each term
# ---------------------------------------------------------------------------
RANKED=$(mktemp)
trap 'rm -f "$DENYLIST_FILE" "$TERMS_FILE" "$COMMENTS_FILE" "$HISTORY_FILE_TMP" "$HISTORY_TERMS" "$AGGREGATED" "$RANKED"' EXIT

if [[ -s "$AGGREGATED" ]]; then
  while IFS=$'\t' read -r term freq spread chan_list example_src; do
    [[ -z "$term" ]] && continue

    # Determine class for denylist check
    # Priority: CamelCase (2+ humps), snake/kebab (separator), phrase (spaces), else identifier
    class="identifier"
    if echo "$term" | grep -qE '^[A-Z][a-z]+([A-Z][a-z0-9]+)+$'; then
      class="camel"
    elif echo "$term" | grep -qE '^[a-z0-9]+([_-][a-z0-9]+)+$'; then
      class="snake"
    elif echo "$term" | grep -qE '^[A-Z][a-z]+ ([A-Z][a-z]+)'; then
      class="phrase"
    fi

    # Apply denylist filter
    if ! candidate_survives "$term" "$class"; then
      # All-common-word term. Check whole-phrase escape ('Relative Bus' mechanism):
      #   - term must be multi-word (phrase or split CamelCase >= 2 words)
      #   - the phrase itself must not be in the denylist
      #   - spread must be >= 2 (cross-source salience floor for all-common phrases)
      if ! phrase_escape_qualifies "$term" "$class"; then
        # Single-word OR phrase is in denylist -> drop unconditionally
        continue
      fi
      if [[ "$spread" -lt 2 ]]; then
        # All-common phrase but not cross-source -> drop
        continue
      fi
      # Phrase with spread>=2 qualifies for whole-phrase escape -> survive
    fi

    # Compute salience = freq * (1 + 2*(spread-1))
    salience=$(( freq * (1 + 2 * (spread - 1)) ))

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$term" "$freq" "$spread" "$chan_list" "$salience" "$example_src"
  done < "$AGGREGATED" | sort -t$'\t' -k5 -nr -k3 -nr -k1 > "$RANKED"
fi

# ---------------------------------------------------------------------------
# Emit candidates: top-N plus every spread>=3 (never truncated)
# ---------------------------------------------------------------------------
EMIT=$(mktemp)
trap 'rm -f "$DENYLIST_FILE" "$TERMS_FILE" "$COMMENTS_FILE" "$HISTORY_FILE_TMP" "$HISTORY_TERMS" "$AGGREGATED" "$RANKED" "$EMIT"' EXIT

if [[ -s "$RANKED" ]]; then
  # First pass: collect all spread>=3 terms (never truncated)
  spread3_terms=$(mktemp)
  awk -F'\t' '$3 >= 3 { print }' "$RANKED" > "$spread3_terms"

  # Second pass: top-N (which may already include spread>=3 terms)
  head_terms=$(mktemp)
  head -n "$TOP_N" "$RANKED" > "$head_terms"

  # Union: top-N + all spread>=3 (deduplicated, stable order by salience)
  # Use awk to deduplicate while preserving order
  cat "$head_terms" "$spread3_terms" | awk -F'\t' '!seen[$1]++' > "$EMIT"
  rm -f "$spread3_terms" "$head_terms"
fi

# ---------------------------------------------------------------------------
# Count statistics
# ---------------------------------------------------------------------------
total_post_denylist=0
cross_source_count=0
top_harvest_count=0

if [[ -s "$RANKED" ]]; then
  total_post_denylist=$(wc -l < "$RANKED" | tr -d ' ')
fi
if [[ -s "$RANKED" ]]; then
  cross_source_count=$(awk -F'\t' '$3 >= 2' "$RANKED" | wc -l | tr -d ' ')
fi
if [[ -s "$EMIT" ]]; then
  top_harvest_count=$(wc -l < "$EMIT" | tr -d ' ')
fi

# SOURCE_DATE_EPOCH override for byte-reproducible output in tests/CI.
# If set, use it instead of wall-clock date so re-runs are byte-identical.
if [[ -n "${SOURCE_DATE_EPOCH:-}" ]]; then
  GEN_DATE=$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%d 2>/dev/null \
             || date -u -r "${SOURCE_DATE_EPOCH}" +%Y-%m-%d 2>/dev/null \
             || date +%Y-%m-%d)
else
  GEN_DATE=$(date +%Y-%m-%d)
fi

echo "[harvest] Emitting ${top_harvest_count} candidates (${cross_source_count} cross-source) to $OUTPUT" >&2

# ---------------------------------------------------------------------------
# Determine class label for output
# ---------------------------------------------------------------------------
get_class_label() {
  local term="$1"
  if echo "$term" | grep -qE '^[A-Z][a-z]+([A-Z][a-z0-9]+)+$'; then
    echo "camel"
  elif echo "$term" | grep -qE '^[a-z0-9]+([_-][a-z0-9]+)+$'; then
    echo "snake"
  elif echo "$term" | grep -qE ' '; then
    echo "phrase"
  else
    echo "identifier"
  fi
}

# ---------------------------------------------------------------------------
# Count synthesis rows already present in any pre-existing output file.
# Harvest emits only harvest rows, so this will be 0 on a fresh run.
# Computed (not hardcoded) so the Summary stays accurate if synthesis rows
# were appended by aid-architect and the file is re-examined.
# ---------------------------------------------------------------------------
synthesis_count=0
if [[ -s "$OUTPUT" ]]; then
  synthesis_count=$(grep -cE '^\| [0-9]+ \| synthesis \|' "$OUTPUT" 2>/dev/null || true)
fi

# ---------------------------------------------------------------------------
# Emit markdown output
# ---------------------------------------------------------------------------
{
  echo "# Candidate Concepts"
  echo
  echo "> Generated by \`canonical/aid/scripts/kb/harvest-coined-terms.sh\` (harvest rows; deterministic,"
  echo "> no LLM) + the conceptual-synthesis channel (synthesis rows; LLM judgment, source-anchored)."
  echo "> The anchor for essence capture (FR-12). Each row is a load-bearing concept the KB MUST"
  echo "> explain or explicitly dismiss. The \`Source\` column marks provenance: \`harvest\`"
  echo "> (mechanical/lexical) vs \`synthesis\` (judgment, with a cited supporting span)."
  echo
  echo "## Summary"
  echo "| Metric | Value |"
  echo "|--------|-------|"
  echo "| Candidates (post-denylist) | ${total_post_denylist} |"
  echo "| Cross-source (spread >= 2) | ${cross_source_count} |"
  echo "| Top harvest emitted | ${top_harvest_count} |"
  echo "| Synthesis concepts | ${synthesis_count} |"
  echo "| Generated | ${GEN_DATE} |"
  echo
  echo "## Ranked Candidates"
  echo "| # | Source | Term | Class | Freq | Spread | Channels | Salience | Example source |"
  echo "|---|--------|------|-------|------|--------|----------|----------|----------------|"

  if [[ -s "$EMIT" ]]; then
    row_num=0
    while IFS=$'\t' read -r term freq spread chan_list salience example_src; do
      [[ -z "$term" ]] && continue
      row_num=$(( row_num + 1 ))
      class=$(get_class_label "$term")
      # Sort channels alphabetically for determinism
      chan_sorted=$(echo "$chan_list" | tr ',' '\n' | sort | tr '\n' ',' | sed 's/,$//')
      printf '| %s | harvest | `%s` | %s | %s | %s | %s | %s | `%s` |\n' \
        "$row_num" "$term" "$class" "$freq" "$spread" "$chan_sorted" "$salience" "$example_src"
    done < "$EMIT"
  fi
} > "$OUTPUT"

DISPLAY_OUTPUT=$(realpath "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
echo "[harvest] Wrote ${DISPLAY_OUTPUT}" >&2
