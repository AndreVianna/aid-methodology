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
#   E5  Quoted strings:           double-quoted strings (<=4 words)
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
# PERFORMANCE / PORTABILITY (see .aid/work-007 issue #7):
#   Extraction is BATCHED -- a handful of matcher invocations over whole file lists,
#   never one-grep-per-file and never a shell subprocess per token/match. All token
#   splitting, word-counting, denylist filtering, and salience/ranking happen inside
#   awk (zero per-token/per-term spawns). This keeps the run to O(1) process spawns
#   instead of O(files x tokens) -- the difference between seconds and 15-40 min (or a
#   hang) on Windows Git Bash / MSYS, where fork()/exec is ~10-50 ms each.
#
#   `rg` (ripgrep) is used for extraction when present (its regex engine is linear --
#   no catastrophic backtracking on pathological single-long-line inputs); otherwise a
#   coreutils `grep` fallback is used. The choice is CAPABILITY-based, not OS-based
#   (WSL reports Linux and forks cheaply; no OS special-casing needed). rg and the
#   grep fallback share IDENTICAL awk post-processing and scan the IDENTICAL file set
#   (rg is fed the explicit `find` list, so .gitignore/hidden filtering never applies),
#   so output is byte-identical regardless of which engine ran -- a repo discovered on
#   Windows-with-rg produces the same KB as Linux-without-rg. Set AID_HARVEST_NO_RG=1
#   to force the grep fallback (used by the CI equivalence test).
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
      sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'
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
  node_modules vendor target build dist out bower_components
  .idea .vscode .vs .history
  __pycache__ .pytest_cache .tox .venv venv .mypy_cache .ruff_cache .eggs .ipynb_checkpoints
  .gradle .m2
  bin obj
  .next .nuxt .cache .turbo .parcel-cache .svelte-kit .angular .pnpm-store
  coverage htmlcov .nyc_output
  Pods .dart_tool .terraform
  # log/temp scratch dirs (minor collision risk: a project could name a source
  # dir "temp"/"logs"; .gitignore catches genuine output dirs per-project anyway)
  logs tmp temp .tmp .temp
  .aid
  # AID tool-install ("dogfood") trees at the repo root -- the AID install itself,
  # never target-project source; the KB makes no claims about them (same reason
  # .aid is pruned). Pruning them keeps the harvest/index scoped to the target
  # project and byte-reproducible across AID updates. Covers every AID profile's
  # install dir: .claude (claude-code), .cursor, .codex, .agent (antigravity).
  # NOT .github (copilot-cli installs under .github/aid/, but .github is a
  # standard project dir with legitimate content, so it is not pruned wholesale).
  .claude .cursor .codex .agent
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
# Capability detection: prefer rg (linear-time regex engine; no backtracking) when
# present. Choice is capability-based, NOT OS-based -- both paths are byte-identical.
# ---------------------------------------------------------------------------
HAVE_RG=0
if [[ -z "${AID_HARVEST_NO_RG:-}" ]] && command -v rg >/dev/null 2>&1; then
  HAVE_RG=1
fi

# ---------------------------------------------------------------------------
# Single scratch dir for every temp artifact (one trap; auto-cleaned).
# ---------------------------------------------------------------------------
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT

DENYLIST_FILE="$TMPD/denylist.txt"
AWK_CLASSIFY="$TMPD/classify.awk"
AWK_EXTRACT="$TMPD/extract.awk"
AWK_RANK="$TMPD/rank.awk"
FILELIST="$TMPD/filelist.txt"
CLASSIFIED="$TMPD/classified.tsv"
PATHIDX_FILE="$TMPD/pathidx.tsv"
CODE_NUL="$TMPD/code.nul"
DOCS_NUL="$TMPD/docs.nul"
CONFIG_NUL="$TMPD/config.nul"
RAW="$TMPD/raw-terms.tsv"
TERMS_FILE="$TMPD/terms.tsv"
COMMENTS_FILE="$TMPD/comments.txt"
HISTORY_FILE_TMP="$TMPD/history.txt"
AGGREGATED="$TMPD/aggregated.tsv"
RANKED="$TMPD/ranked.tsv"
EMIT="$TMPD/emit.tsv"
: > "$DENYLIST_FILE"
: > "$RAW"

# ---------------------------------------------------------------------------
# Load denylist (already sorted+lowercased by convention; we lowercase again on use).
# ---------------------------------------------------------------------------
if [[ -n "$DENYLIST" && -f "$DENYLIST" ]]; then
  cat "$DENYLIST" > "$DENYLIST_FILE"
fi

# Local override lives inside the project; resolved after cd.
LOCAL_DENYLIST_REL=".aid/knowledge/.coined-term-denylist.local.txt"

# ---------------------------------------------------------------------------
# awk program: classify a file path into a channel (port of detect_lang +
# is_source + classify_channel; SAME case order so results are identical).
# Input: one relative path per line. Output: <idx>\t<channel>\t<path> (idx = NR).
# ---------------------------------------------------------------------------
cat > "$AWK_CLASSIFY" <<'CLASSIFY_AWK'
function is_source_ext(e) {
  return (e=="java"||e=="kt"||e=="kts"||e=="py"||e=="js"||e=="mjs"||e=="cjs"||e=="jsx"||
          e=="ts"||e=="tsx"||e=="mts"||e=="cts"||e=="go"||e=="rs"||e=="cs"||e=="fs"||e=="fsx"||
          e=="cpp"||e=="cc"||e=="cxx"||e=="hpp"||e=="hxx"||e=="c"||e=="h"||e=="rb"||e=="php"||
          e=="swift"||e=="scala"||e=="sc"||e=="elm"||e=="ex"||e=="exs"||e=="erl"||e=="hrl"||
          e=="clj"||e=="cljs"||e=="cljc"||e=="lua"||e=="sh"||e=="bash"||e=="zsh"||e=="ps1"||
          e=="vue"||e=="svelte")
}
{
  path=$0
  if (path=="") next
  # ext = ${path##*.} lowercased; if no dot anywhere, ext=path (matches bash)
  ext=path
  if (sub(/.*\./,"",ext)==0) ext=path
  ext=tolower(ext)
  # base = ${path##*/}; base_lower
  base=path; sub(/.*\//,"",base); base_lower=tolower(base)

  channel=""
  if (is_source_ext(ext)) channel="code"
  else if (ext=="md"||ext=="markdown"||ext=="rst"||ext=="txt"||ext=="adoc"||ext=="asciidoc") channel="docs"
  else if (path ~ /^docs\// || path ~ /^doc\// || path ~ /^documentation\// || path ~ /^adr.*\// || path ~ /^\.github\//) channel="docs"
  else if (ext=="yml"||ext=="yaml"||ext=="toml"||ext=="json"||ext=="ini"||ext=="cfg"||ext=="conf"||ext=="properties"||ext=="lock"||ext=="xml") channel="config"
  else if (base_lower=="makefile"||base_lower=="rakefile"||base_lower=="dockerfile"||base_lower=="gemfile"||base_lower=="pipfile"||base_lower=="podfile"||
           base_lower=="cmakelists.txt"||base_lower=="build.gradle"||base_lower=="pom.xml"||base_lower=="cargo.toml"||base_lower=="go.mod"||
           base_lower=="requirements.txt"||base_lower=="setup.py"||base_lower=="pyproject.toml"||base_lower=="composer.json"||
           base_lower=="package.json"||base_lower=="tsconfig.json"||base_lower=="jsconfig.json") channel="config"

  if (channel!="") print NR "\t" channel "\t" path
}
CLASSIFY_AWK

# ---------------------------------------------------------------------------
# awk program: turn raw matches into TERM<TAB>CHANNEL<TAB>FILE rows, prefixed with a
# file-order index so global first-occurrence (the 'Example source' column) is
# deterministic regardless of matcher emission order.
#
# Input records are NUL-delimited "path\0match" (from rg --null / grep -oHZ), one per
# match. It replicates every per-token transform the old shell loop did:
#   ident      len>=4 identifiers
#   snake      len>=5 snake/kebab compounds
#   camel_join joined CamelCase only (config channel)
#   camel_both joined CamelCase AND split-capitalized phrase (RelativeBus + Relative Bus)
#   phrase     2-4 capitalized words (trailing space stripped)
#   quoted     double-quoted string, <=4 words, quotes stripped
# For real files idx/file come from the path->idx map; comments/history pass a fixed
# idx (> all file indices) and a fixed file label.
# ---------------------------------------------------------------------------
cat > "$AWK_EXTRACT" <<'EXTRACT_AWK'
function splitcamel(s,   i,cur,prev,nxt,out) {
  # pass 1: insert space between [a-z0-9] and [A-Z]  (sed s/([a-z0-9])([A-Z])/\1 \2/g)
  out=""
  for (i=1;i<=length(s);i++) {
    cur=substr(s,i,1)
    if (i>1) { prev=substr(s,i-1,1); if (prev ~ /[a-z0-9]/ && cur ~ /[A-Z]/) out=out " " }
    out=out cur
  }
  # pass 2: split acronym boundary  (sed s/([A-Z]+)([A-Z][a-z])/\1 \2/g)
  s=out; out=""
  for (i=1;i<=length(s);i++) {
    cur=substr(s,i,1); nxt=substr(s,i+1,1); prev=(i>1?substr(s,i-1,1):"")
    if (prev ~ /[A-Z]/ && cur ~ /[A-Z]/ && nxt ~ /[a-z]/) out=out " "
    out=out cur
  }
  return tolower(out)
}
function capitalize(s,   n,a,i,out) {
  n=split(s,a,/[[:space:]]+/); out=""
  for (i=1;i<=n;i++) {
    if (a[i]=="") continue
    a[i]=toupper(substr(a[i],1,1)) substr(a[i],2)
    out=(out==""?a[i]:out" "a[i])
  }
  return out
}
function wcount(s,   a,n) {
  gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
  if (s=="") return 0
  return split(s,a,/[[:space:]]+/)
}
function emit(term,   idx,file) {
  if (fixedidx!="") { idx=fixedidx; file=fixedfile }
  else { file=$1; idx=PI[file]; if (idx=="") return }
  print idx "\t" term "\t" channel "\t" file
}
BEGIN {
  FS="\0"
  if (pimap!="") { while ((getline ln < pimap) > 0) { n=split(ln,a,"\t"); if (n>=2) PI[a[1]]=a[2] } }
}
{
  m=$2
  if (m=="") next
  if (mode=="ident")      { if (length(m)>=4) emit(m) }
  else if (mode=="snake") { if (length(m)>=5) emit(m) }
  else if (mode=="camel_join") { emit(m) }
  else if (mode=="camel_both") { emit(m); sp=capitalize(splitcamel(m)); if (sp!="") emit(sp) }
  else if (mode=="phrase") { t=m; sub(/[[:space:]]+$/,"",t); c=wcount(t); if (c>=2 && c<=4) emit(t) }
  else if (mode=="quoted") { t=m; gsub(/"/,"",t); c=wcount(t); if (c<=4) emit(t) }
}
EXTRACT_AWK

# ---------------------------------------------------------------------------
# cd into ROOT for scanning
# ---------------------------------------------------------------------------
cd "$ROOT"

# Merge the project-local denylist override (comm-union with the supplied one).
if [[ -f "$LOCAL_DENYLIST_REL" ]]; then
  local_sorted="$TMPD/local_denylist.txt"
  sort -f "$LOCAL_DENYLIST_REL" | tr '[:upper:]' '[:lower:]' | sort > "$local_sorted"
  if [[ -s "$DENYLIST_FILE" ]]; then
    comm -23 "$local_sorted" "$DENYLIST_FILE" >> "$DENYLIST_FILE" 2>/dev/null || true
    sort -o "$DENYLIST_FILE" "$DENYLIST_FILE"
  else
    cp "$local_sorted" "$DENYLIST_FILE"
  fi
fi

echo "[harvest] Scanning files under $ROOT ..." >&2

# ---------------------------------------------------------------------------
# 1. Enumerate the file set ONCE (same prune + sort as build-project-index.sh).
# ---------------------------------------------------------------------------
# shellcheck disable=SC2086
find . \( $PRUNE_EXPR \) -prune -o -type f -print 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort > "$FILELIST"

# ---------------------------------------------------------------------------
# Scope refinement (kept in lockstep with build-project-index.sh): drop
# non-source FILES the SKIP_DIRS dir-prune can't catch. Every check is
# DETERMINISTIC + git-native + machine-neutralized, so the harvest stays
# byte-reproducible across machines/OSes/AID-updates; each only REMOVES from the
# set (order-independent); each is a single batched process (no per-file spawn).
#   (1) minified bundles + sourcemaps  -- never hand-authored source
#   (2) .gitignore    -- git check-ignore with the global core.excludesFile
#       neutralized, so exclusions come from the COMMITTED .gitignore (git also
#       consults the per-clone $GIT_DIR/info/exclude, which has no override flag
#       but is empty by default -> in practice output is reproducible across
#       machines). Tracked files are never reported, so committed source that
#       matches a pattern still scans.
#   (3) .gitattributes linguist-generated / linguist-vendored (project-DECLARED;
#       NOT linguist-documentation -- the docs channel harvests prose terms)
#   (4) @generated / DO NOT EDIT header marker (first 2 lines only; portable
#       full-read awk -- NOT `nextfile`, which macOS awk lacks and would make the
#       check silently no-op there, breaking cross-OS byte-identity)
# ---------------------------------------------------------------------------
if [[ -s "$FILELIST" ]]; then
  EXCLUDE="$TMPD/scan-exclude.txt"; : > "$EXCLUDE"
  grep -E '\.min\.(js|css)$|\.map$' "$FILELIST" >> "$EXCLUDE" 2>/dev/null || true
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git -c core.excludesFile=/dev/null check-ignore --stdin < "$FILELIST" 2>/dev/null >> "$EXCLUDE" || true
    git check-attr --stdin linguist-generated linguist-vendored < "$FILELIST" 2>/dev/null \
      | sed -n -E 's/: linguist-(generated|vendored): (set|true)$//p' >> "$EXCLUDE" || true
  fi
  tr '\n' '\0' < "$FILELIST" \
    | LC_ALL=C xargs -0 awk 'FNR<=2 && /@generated|DO NOT EDIT|DO NOT MODIFY/ { print FILENAME }' 2>/dev/null >> "$EXCLUDE" || true
  if [[ -s "$EXCLUDE" ]]; then
    LC_ALL=C sort -u "$EXCLUDE" -o "$EXCLUDE"
    LC_ALL=C comm -23 "$FILELIST" "$EXCLUDE" > "$FILELIST.keep" 2>/dev/null && mv "$FILELIST.keep" "$FILELIST"
  fi
fi

NFILES=$(wc -l < "$FILELIST" | tr -d ' ')
COMMENTS_IDX=$(( NFILES + 1 ))
HISTORY_IDX=$(( NFILES + 2 ))

# 2. Classify every file into a channel in ONE awk pass (no per-file spawns).
awk -f "$AWK_CLASSIFY" "$FILELIST" > "$CLASSIFIED"

# 3. Exclude binary files (any file containing a NUL byte) -- matches the old
#    per-file `grep -qP '\x00'` skip, batched. Both engines then see the same set.
if [[ -s "$CLASSIFIED" ]]; then
  binset="$TMPD/binary.txt"
  { cut -f3 "$CLASSIFIED" | tr '\n' '\0' \
      | LC_ALL=C xargs -0 grep -lZ -P '\x00' -- 2>/dev/null \
      | tr '\0' '\n' > "$binset"; } || true
  if [[ -s "$binset" ]]; then
    awk -F'\t' 'NR==FNR{bin[$0]=1;next} !($3 in bin)' "$binset" "$CLASSIFIED" > "$CLASSIFIED.f" \
      && mv "$CLASSIFIED.f" "$CLASSIFIED"
  fi
fi

# 4. Build the path->idx map + per-channel NUL-delimited file lists.
awk -F'\t' '{ print $3 "\t" $1 }'          "$CLASSIFIED" > "$PATHIDX_FILE"
awk -F'\t' '$2=="code"   { printf "%s\0",$3 }' "$CLASSIFIED" > "$CODE_NUL"
awk -F'\t' '$2=="docs"   { printf "%s\0",$3 }' "$CLASSIFIED" > "$DOCS_NUL"
awk -F'\t' '$2=="config" { printf "%s\0",$3 }' "$CLASSIFIED" > "$CONFIG_NUL"

# ---------------------------------------------------------------------------
# Extraction patterns (E1-E5)
# ---------------------------------------------------------------------------
PAT_IDENT='[A-Za-z_][A-Za-z0-9_]+'
PAT_CAMEL='[A-Z][a-z]+([A-Z][a-z0-9]+)+'
PAT_SNAKE='[a-z0-9]+([_-][a-z0-9]+)+'
PAT_PHRASE='([A-Z][a-z]+[[:space:]]+){1,3}[A-Z][a-z]+'
PAT_QUOTED='"[A-Za-z][A-Za-z0-9 _-]{2,30}"'

# run_matcher: reads a NUL-delimited file list on stdin, prints "path\0match" per
# match. rg when available (linear engine); coreutils grep otherwise. Identical
# output on non-pathological input; rg is fed explicit files so ignore rules never
# apply and the scanned set matches the grep fallback exactly.
run_matcher() {
  local pat="$1"
  if [[ $HAVE_RG -eq 1 ]]; then
    LC_ALL=C xargs -0 rg --no-config --no-messages -o --no-heading --with-filename --null -N -e "$pat" -- 2>/dev/null || true
  else
    LC_ALL=C xargs -0 grep -oHZE -e "$pat" -- 2>/dev/null || true
  fi
}

# extract: matcher over a channel file list -> TERM rows (real-file idx via map).
# Usage: extract <list.nul> <channel> <mode> <pattern>  ; appends to $RAW by caller.
extract() {
  local list="$1" channel="$2" mode="$3" pat="$4"
  [[ -s "$list" ]] || return 0
  run_matcher "$pat" < "$list" \
    | awk -F'\0' -v mode="$mode" -v channel="$channel" -v pimap="$PATHIDX_FILE" -f "$AWK_EXTRACT"
}

# extract_fixed: matcher over a single synthesized file (comments/history) with a
# fixed idx (> all file indices) and fixed file label.
# Usage: extract_fixed <srcfile> <channel> <mode> <pattern> <idx> <filelabel>
extract_fixed() {
  local src="$1" channel="$2" mode="$3" pat="$4" fidx="$5" flabel="$6"
  [[ -s "$src" ]] || return 0
  printf '%s\0' "$src" | run_matcher "$pat" \
    | awk -F'\0' -v mode="$mode" -v channel="$channel" -v fixedidx="$fidx" -v fixedfile="$flabel" -f "$AWK_EXTRACT"
}

# --- code channel: E1 identifiers, E2 camel (joined+split), E3 snake, E5 quoted ---
extract "$CODE_NUL"   code   ident      "$PAT_IDENT"  >> "$RAW"
extract "$CODE_NUL"   code   camel_both "$PAT_CAMEL"  >> "$RAW"
extract "$CODE_NUL"   code   snake      "$PAT_SNAKE"  >> "$RAW"
extract "$CODE_NUL"   code   quoted     "$PAT_QUOTED" >> "$RAW"

# --- docs channel: E2 camel (joined+split), E4 phrases, E5 quoted ---
extract "$DOCS_NUL"   docs   camel_both "$PAT_CAMEL"  >> "$RAW"
extract "$DOCS_NUL"   docs   phrase     "$PAT_PHRASE" >> "$RAW"
extract "$DOCS_NUL"   docs   quoted     "$PAT_QUOTED" >> "$RAW"

# --- config channel: E3 snake, E2 camel (JOINED ONLY) ---
extract "$CONFIG_NUL" config snake      "$PAT_SNAKE"  >> "$RAW"
extract "$CONFIG_NUL" config camel_join "$PAT_CAMEL"  >> "$RAW"

# --- comments channel: comment lines from code files, then E4 + E2 ---
if [[ -s "$CODE_NUL" ]]; then
  LC_ALL=C xargs -0 grep -hE '^[[:space:]]*(#|//|--|;|/\*|\*)' -- < "$CODE_NUL" 2>/dev/null > "$COMMENTS_FILE" || true
fi
extract_fixed "$COMMENTS_FILE" comments phrase     "$PAT_PHRASE" "$COMMENTS_IDX" comments >> "$RAW"
extract_fixed "$COMMENTS_FILE" comments camel_both "$PAT_CAMEL"  "$COMMENTS_IDX" comments >> "$RAW"

# ---------------------------------------------------------------------------
# History channel: git log (degrade-gracefully on non-git trees)
# ---------------------------------------------------------------------------
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

extract_fixed "$HISTORY_FILE_TMP" history phrase     "$PAT_PHRASE" "$HISTORY_IDX" git-log >> "$RAW"
extract_fixed "$HISTORY_FILE_TMP" history camel_both "$PAT_CAMEL"  "$HISTORY_IDX" git-log >> "$RAW"

echo "[harvest] Aggregating and ranking candidates..." >&2

# ---------------------------------------------------------------------------
# Restore deterministic file order (min-idx-first) so the 'Example source' column
# is the earliest source in find|sort order, then drop the idx prefix.
# ---------------------------------------------------------------------------
LC_ALL=C sort -t$'\t' -k1,1n "$RAW" | cut -f2- > "$TERMS_FILE"

# ---------------------------------------------------------------------------
# Aggregation: compute freq, spread, channels, example_source per term.
# TERMS_FILE format: TERM<TAB>CHANNEL<TAB>FILE
# ---------------------------------------------------------------------------
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
# awk program: denylist filter + phrase-escape + salience (port of the old
# candidate_survives / phrase_escape_qualifies shell functions; runs once over the
# aggregated term set instead of spawning ~10 processes per unique term).
# Input:  TERM\tFREQ\tSPREAD\tCHANNELS\tEXAMPLE
# Output: TERM\tFREQ\tSPREAD\tCHANNELS\tSALIENCE\tEXAMPLE  (survivors only)
# ---------------------------------------------------------------------------
cat > "$AWK_RANK" <<'RANK_AWK'
function splitcamel(s,   i,cur,prev,nxt,out) {
  out=""
  for (i=1;i<=length(s);i++) {
    cur=substr(s,i,1)
    if (i>1) { prev=substr(s,i-1,1); if (prev ~ /[a-z0-9]/ && cur ~ /[A-Z]/) out=out " " }
    out=out cur
  }
  s=out; out=""
  for (i=1;i<=length(s);i++) {
    cur=substr(s,i,1); nxt=substr(s,i+1,1); prev=(i>1?substr(s,i-1,1):"")
    if (prev ~ /[A-Z]/ && cur ~ /[A-Z]/ && nxt ~ /[a-z]/) out=out " "
    out=out cur
  }
  return tolower(out)
}
function splitcompound(s) { gsub(/[_-]/," ",s); return tolower(s) }
function wcount(s,   a,n) {
  gsub(/^[[:space:]]+|[[:space:]]+$/,"",s)
  if (s=="") return 0
  return split(s,a,/[[:space:]]+/)
}
function any_not_in_dl(wstr,   a,n,i) {
  n=split(wstr,a,/[[:space:]]+/)
  for (i=1;i<=n;i++) { if (a[i]=="") continue; if (!(a[i] in DL)) return 1 }
  return 0
}
BEGIN {
  FS="\t"
  if (dlf!="") { while ((getline w < dlf) > 0) { gsub(/^[[:space:]]+|[[:space:]]+$/,"",w); if (w!="") DL[tolower(w)]=1 } }
}
{
  term=$1; freq=$2+0; spread=$3+0; chan=$4; example=$5
  if (term=="") next

  # class detection (identical to the shipped ranking loop)
  class="identifier"
  if (term ~ /^[A-Z][a-z]+([A-Z][a-z0-9]+)+$/) class="camel"
  else if (term ~ /^[a-z0-9]+([_-][a-z0-9]+)+$/) class="snake"
  else if (term ~ /^[A-Z][a-z]+ ([A-Z][a-z]+)/) class="phrase"

  # candidate_survives: any component word NOT in denylist -> survive unconditionally
  if (class=="camel") ws=splitcamel(term)
  else if (class=="snake") ws=splitcompound(term)
  else ws=tolower(term)

  if (!any_not_in_dl(ws)) {
    # all words common -> whole-phrase escape (the 'Relative Bus' mechanism)
    if (class=="camel") wc=wcount(splitcamel(term)); else wc=wcount(term)
    qualifies=1
    if (wc<=1) qualifies=0
    else if (tolower(term) in DL) qualifies=0
    if (!qualifies) next          # single-word OR phrase in denylist -> drop
    if (spread<2) next            # all-common phrase but not cross-source -> drop
    # else: qualifies AND spread>=2 -> survive
  }

  salience = freq * (1 + 2 * (spread - 1))
  print term "\t" freq "\t" spread "\t" chan "\t" salience "\t" example
}
RANK_AWK

# ---------------------------------------------------------------------------
# Apply denylist filter + salience, then rank (salience desc, spread desc, term asc).
# ---------------------------------------------------------------------------
if [[ -s "$AGGREGATED" ]]; then
  awk -v dlf="$DENYLIST_FILE" -f "$AWK_RANK" "$AGGREGATED" \
    | LC_ALL=C sort -t$'\t' -k5 -nr -k3 -nr -k1 > "$RANKED"
fi

# ---------------------------------------------------------------------------
# Emit candidates: top-N plus every spread>=3 (never truncated)
# ---------------------------------------------------------------------------
if [[ -s "$RANKED" ]]; then
  # First pass: collect all spread>=3 terms (never truncated)
  spread3_terms="$TMPD/spread3.tsv"
  awk -F'\t' '$3 >= 3 { print }' "$RANKED" > "$spread3_terms"

  # Second pass: top-N (which may already include spread>=3 terms)
  head_terms="$TMPD/head.tsv"
  head -n "$TOP_N" "$RANKED" > "$head_terms"

  # Union: top-N + all spread>=3 (deduplicated, stable order by salience)
  cat "$head_terms" "$spread3_terms" | awk -F'\t' '!seen[$1]++' > "$EMIT"
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
  echo "> Generated by \`.claude/aid/scripts/kb/harvest-coined-terms.sh\` (harvest rows; deterministic,"
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
    # Row-number + class-label + channel-sort in ONE awk pass. (The old per-row shell
    # loop spawned ~7 processes per row -- get_class_label greps + a tr|sort|tr|sed
    # channel sort -- which, at ~1s/spawn on Windows Git Bash, cost minutes on a full
    # candidate list. This is byte-identical to that loop's output.)
    awk -F'\t' '
      function classlabel(t) {
        if (t ~ /^[A-Z][a-z]+([A-Z][a-z0-9]+)+$/) return "camel"
        else if (t ~ /^[a-z0-9]+([_-][a-z0-9]+)+$/) return "snake"
        else if (t ~ / /) return "phrase"
        else return "identifier"
      }
      {
        term=$1; freq=$2; spread=$3; chan=$4; sal=$5; ex=$6
        if (term=="") next
        # sort the (tiny) channel list alphabetically for determinism
        n=split(chan, c, ",")
        for (i=2;i<=n;i++) { key=c[i]; j=i-1; while (j>=1 && c[j]>key) { c[j+1]=c[j]; j-- } c[j+1]=key }
        cs=""; for (i=1;i<=n;i++) cs=(cs==""?c[i]:cs","c[i])
        row++
        printf "| %s | harvest | `%s` | %s | %s | %s | %s | %s | `%s` |\n", row, term, classlabel(term), freq, spread, cs, sal, ex
      }
    ' "$EMIT"
  fi
} > "$OUTPUT"

DISPLAY_OUTPUT=$(realpath "$OUTPUT" 2>/dev/null || echo "$OUTPUT")
echo "[harvest] Wrote ${DISPLAY_OUTPUT}" >&2
