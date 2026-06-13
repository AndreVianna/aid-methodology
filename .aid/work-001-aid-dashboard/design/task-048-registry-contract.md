# task-048 — Registry contract + CAN-1 + DD-1 `<id>` seam (DESIGN, authoritative)

**Type:** DESIGN (no production code modified) — the single seam tasks **049 / 050 / 051 / 053**
cite verbatim. Where this artifact and feature-010 SPEC.md disagree, this artifact governs the
*concrete expressions*; the SPEC governs intent. They are reconciled — no disagreement is intended.

**Source of truth grounded against (read, line-cited):**
- feature-010 SPEC.md — DM-1, DM-2, DD-1..DD-5, DD-REG-FMT, SEC-1..6, CLI-1, CLI-2, FF-1/2/3.
- `task-046-r8-install-wiring.md` — the vendored `$AID_HOME/dashboard/` layout the servers run from.
- `bin/aid:40-47` — `$AID_HOME` self-resolve (uses `pwd -P` — **the contrast case**, see §2).
- `bin/aid:804` — `aid dashboard --target` canonicalization (`cd && pwd`, **no `-P`**).
- `bin/aid:1255` — `aid add/update/remove --target` canonicalization (`cd && pwd`, **no `-P`**).
- `bin/aid:297-305` — the existing `mktemp`+`mv` atomic-rewrite precedent (PATH wiring).
- `bin/aid:871-891` — the dashboard spawn seam (`--root` is already plumbed).
- `bin/aid:1430-1454` — the `add|update)` case; success tail is `exit 0` at **:1453**.
- `bin/aid:1456-1475` — the `remove)` case; success tail is `exit 0` at **:1474**.
- `dashboard/server/server.py:33-41,208-216` and `server.mjs:32-37,87-123` — current single-`--root`
  resolution that both servers must grow into the id→path map.

---

## 0. Scope map — who implements which section

| Section | Pins | Implemented by |
|---|---|---|
| §1 DM-1 registry schema (file bytes) | the exact `registry.yml` shape, lazy-create, absent≡empty, tolerant-higher-schema, paths-only | **049** (writer), read by **050/051** |
| §2 CAN-1 (one rule, 4 sites + PS twin) | `cd && pwd` exactly, at writer / storage / Python map / Node map, + the `pwd -P` contrast | **049** (writer + PS twin), **050** (Python map), **051** (Node map) |
| §3 DD-1 `<id>` addressing | sha256 byte-input, hex grammar, 3-leaf allowlist, mtime+size cache, collision-lengthen | **050** (Python map+routes), **051** (Node map+routes), **053** (consumes `<id>` in links) |
| §4 DD-3 atomic write | read-modify-write `mktemp`+`mv` / `Move-Item -Force`; torn-read tolerance | **049** (writer + PS twin) |
| §5 DD-REG-FMT line-scan parse | `grep -E` posture + the exact Python/Node line-scan; zero YAML lib | **049** (Bash read for idempotency check), **050** (Python), **051** (Node) |
| §6 Consumers table | per-task entry points | all |

---

## 1. DM-1 — `$AID_HOME/registry.yml` schema (file bytes)

### 1.1 The exact file (byte-for-byte template the writer emits)

The writer emits **exactly** these bytes (LF line endings, no BOM, no trailing blank line beyond the
final `\n` after the last repo). The four comment lines + `schema: 1` + `repos:` are fixed ASCII
scaffolding; only the `  - <path>` lines vary.

```yaml
# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit).
# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/
# description/version are read from each repo's own .aid/settings.yml at render time.
schema: 1
repos:
  - /abs/path/to/repoA
  - /abs/path/to/repoB
```

- **Indentation:** block sequence under `repos:` is exactly two spaces then `- ` then the path
  (`  - /abs/...`). The line-scan in §5 keys on `^\s*-\s`, so any leading-space count parses, but the
  **writer always emits two spaces** for determinism / parity.
- **Empty registry:** when `repos` is empty the file is the four comment lines + `schema: 1` +
  `repos:` followed by **nothing** (a bare `repos:` key with no sequence items). Readers treat
  `repos:` with zero `- ` lines as the empty list. The writer **may** instead delete the file entirely
  on last-unregister (see §1.3); both an absent file and a `repos:`-with-no-items file are the empty
  registry. Readers MUST accept both.
- **Path bytes:** repo paths are written **verbatim** as the CAN-1 string (§2). They are NOT quoted,
  NOT escaped. A path may legitimately contain non-ASCII bytes on some hosts — that is user data, not
  CLI scaffolding, and the ASCII-only source gate does not apply to it (mirrors feature-003 DM-3's
  "runtime output vs. source" split). Paths containing a literal newline are out of scope (a directory
  name cannot contain `/` or NUL; embedded `\n` in a dir name is a pathological case AID does not
  support and the line-scan would mis-split — acceptable, NFR10 degrade).

### 1.2 Lazy-create / absent ≡ empty

- The file is created **lazily on the first `registry_register`** (first repo registered on this CLI
  install). A fresh install tree (`bin/`, `lib/`, `VERSION`) does **not** ship `registry.yml`; it
  appears only after the first `aid add`. (Same lazy posture as `$AID_HOME/.update-check`,
  `bin/aid:159,174`.)
- **Absent file ≡ empty registry.** Every reader (049 idempotency check, 050, 051) MUST treat a
  missing `$AID_HOME/registry.yml` as **zero registered repos** and return cleanly — never an error,
  never a 500. The CLI home renders an empty-state; `/api/home` returns `repos: []`.

### 1.3 Lifecycle

- Created lazily on first register (§1.2).
- On `registry_unregister` of the **last** repo, the writer MAY either (a) write a `repos:`-with-no-items
  file, or (b) leave the file present with `repos:` empty. The writer chooses **(a) keep the file with
  an empty `repos:`** for simplicity (no special-case delete path; the read-modify-write in §4 just
  writes a zero-item sequence). Either is contract-valid; readers handle both per §1.2.
- `aid remove self` (`rm -rf $AID_HOME`) removes the whole install tree including `registry.yml`. This
  is acceptable (FR28) — the registry is **derived** state, rebuilt by re-adding repos. There is no
  per-repo unregister step on `remove self`.

### 1.4 Tolerant higher-`schema` read posture (NFR10)

The `schema:` integer is a forward-compat handle. A reader pinned to `schema: 1` MUST NOT crash when
it encounters `schema: 2` (or any higher/unknown value):

- The reader **does not gate on the schema value**. It parses the `schema:` line for diagnostics only
  (it MAY record a parse-note `"registry schema N newer than reader (expected 1); read best-effort"` in
  `read.parse_warnings`), then **proceeds to line-scan `repos:` best-effort** exactly as for schema 1.
- A future `schema: 2` that adds fields under `repos:` items (e.g. inline maps) would not match the
  `^\s*-\s<path>` shape; those lines are simply skipped (best-effort), never throwing. A schema-2
  reader would handle them; a schema-1 reader degrades to "repos it can recognize" + a parse note.
- **Rule: a higher schema is read, never rejected.** No reader returns a non-200 or raises because of
  the schema value. This is the NFR10 stale/forward-tolerance posture applied to the version handle.

### 1.5 Paths-only rule (no metadata duplication)

The registry stores **only** the CAN-1 absolute path of each repo's base folder (the folder that
*contains* `.aid/`, NOT `.aid/` itself). It MUST NOT contain `name`, `description`, `aid_version`,
`tools_installed`, or any per-repo field. Those are read **live** at render time:
`name`/`description` from `<repo>/.aid/settings.yml`; `aid_version`/`tools_installed` from
`<repo>/.aid/.aid-manifest.json`; `has_home`/`has_kb` from `stat` of `<repo>/.aid/dashboard/*.html`.
A repo rename or version bump therefore never touches the registry.

---

## 2. CAN-1 — the one canonicalization rule (one rule, four sites + PS twin)

### 2.1 The rule

> **CAN-1(path) = `cd "$path" && pwd`** — absolutize the path and collapse `.`, `..`, and `//`,
> **WITHOUT `-P`** (symlinks are **NOT** resolved).

This is the EXACT semantics the existing `--target` canonicalization already applies. It is adopted
**unchanged** so no `bin/aid --target` edit is needed and the writer, storage, and both server maps
produce byte-identical path strings.

### 2.2 CRITICAL contrast — CAN-1 (`cd && pwd`) vs `$AID_HOME` self-resolve (`pwd -P`)

These two look almost identical and **MUST NEVER be conflated** (MEMORY "pause on red flags":
folder-path vs repo-slug look-alike discipline). They serve different purposes and produce different
values when symlinks are involved:

| | Purpose | Expression | `-P`? | Symlinks |
|---|---|---|---|---|
| **`$AID_HOME` self-resolve** | locate the *installed CLI tree* from `bin/aid`'s own location | `bin/aid:43` `cd "$(dirname "$_AID_SELF")" && pwd -P` | **YES** | **resolved** |
| **CAN-1 (this rule)** | canonicalize a *registered repo path* | `cd "$path" && pwd` | **NO** | **NOT resolved** |

`$AID_HOME` deliberately resolves symlinks (so a symlinked `aid` on PATH still finds the real install
tree). CAN-1 deliberately does NOT (matching `--target` semantics, so a repo reached through a symlink
keeps its symlinked path as the operator typed/expects it, and the stored path / id stay stable). **Do
not copy the `pwd -P` from line 43 into any CAN-1 site, and do not change line 43 to drop `-P`.** They
are separate values for separate jobs.

> If symlink-resolution were ever wanted for repos it would require changing `--target` at `:804` AND
> `:1255` AND all four CAN-1 sites to `pwd -P` **together**. This spec does NOT do that — it adopts the
> existing no-`-P` semantics, so **zero** `bin/aid --target` change is made.

### 2.3 The four sites + PS twin — exact expression per runtime

CAN-1 MUST be applied **identically** at all four sites so the stored path, its sha256 id (§3), and
every per-request id→path resolution can never diverge.

**Site 1 — the writer (`registry_register` / `registry_unregister` in `bin/aid`, Bash).**
The repo registered is the already-resolved `--target` (`_AID_TARGET` at `bin/aid:1255` is **already**
`cd && pwd`). So at the success-tail hook the value is **already CAN-1** — the writer passes
`$_AID_TARGET` straight through:

```bash
# At the add|update success tail (before `exit 0`, bin/aid:1453) and the
# remove success tail (before `exit 0`, bin/aid:1474), _AID_TARGET is ALREADY
# `cd "$_AID_TARGET" && pwd` from bin/aid:1255. Do NOT re-canonicalize; pass it through:
registry_register   "$_AID_TARGET"     # add|update tail
registry_unregister "$_AID_TARGET"     # remove tail (only when the manifest is now gone)
```

> If a future call site lacks a pre-canonicalized target, canonicalize explicitly with the IDENTICAL
> expression: `canon="$(cd "$path" && pwd)"`. Never `pwd -P`.

**Site 1 (PS twin) — `bin/aid.ps1`.** Resolve to an absolute path **without resolving symlink targets**
(the no-`-P` requirement). The shipped code uses `(Resolve-Path -LiteralPath $Target).Path`, which is
**correct**: PowerShell's `Resolve-Path` is provider-path normalization — it absolutizes and collapses
`.`/`..` but does **NOT** resolve symlink/reparse-point targets. (Empirically verified on pwsh 7.4.6,
both trailing and mid-path symlinks: `Resolve-Path` returns the *logical* path, byte-identical to Bash
`cd && pwd` and to `[System.IO.Path]::GetFullPath`. Symlink-target resolution in PowerShell requires
`Get-Item ... .Target` / `.ResolveLinkTarget` / `readlink -f`, which this code never uses.) Either form
below is an acceptable, equivalent CAN-1 — the shipped code uses (a):

```powershell
# (a) SHIPPED form — Resolve-Path normalizes (absolute, . / .. collapsed) and does NOT follow symlinks;
#     it also validates existence (errors on a missing --target, matching Bash `cd` failing on missing).
$canon = (Resolve-Path -LiteralPath $Target).Path

# (b) Explicit .NET alternative (no existence check) — same logical result, makes the no-symlink intent
#     textually unambiguous. Anchor a RELATIVE target on the current location to mirror `cd "$Target" && pwd`.
$canon = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine((Get-Location).Path, $Target))
```

> **REQUIREMENT (both forms):** absolute, `.`/`..` collapsed, **NO symlink-target resolution**. Never use
> `Get-Item .Target` / `.ResolveLinkTarget` / `readlink -f` / Bash `pwd -P` here — those WOULD diverge from
> `cd && pwd` and break DD-5. `Resolve-Path` is **not** one of those — it is the no-follow normalizer.
>
> Implementation note for 049: reuse `bin/aid.ps1`'s existing `--target` canonicalization
> (`(Resolve-Path -LiteralPath $Target).Path` at the install + dashboard seams) — it already matches
> `cd && pwd`; the registry twin calls that same already-canonical `$_AidTarget` so the twin and Bash
> agree byte-for-byte. Cross-runtime DD-5 parity is anyway carried by the two **servers** hashing the
> identical stored byte-string (proven byte-identical), and on any one machine only one shell writes the
> registry — so writer cross-shell drift is not a DD-5 surface in practice.

**Site 2 — storage (DM-1 `repos[]`).** Paths are stored **already CAN-1** (site 1 wrote them that way).
No re-canonicalization on read. The line-scan (§5) returns the stored string **verbatim**, including no
trailing whitespace (the writer emits none). This verbatim stored string is the sha256 input (§3).

**Site 3 — the Python server id→path map (`server.py`).** When building the map from the loaded
registry, each `repos[]` entry is **already** CAN-1 (site 2). The Python server does **not**
re-canonicalize (re-running `os.path.realpath`/`Path.resolve` would follow symlinks and break parity —
forbidden). It uses the stored string verbatim:

```python
# CAN-1 site 3: the stored path is ALREADY canonical (writer applied `cd && pwd`).
# Use it verbatim. DO NOT call Path(p).resolve() / os.path.realpath(p) -- those follow
# symlinks (`-P` semantics) and would diverge from the writer + Node map.
canon = entry  # the verbatim line-scan result, no normalization
```

**Site 4 — the Node server id→path map (`server.mjs`).** Identical posture:

```js
// CAN-1 site 4: stored path is ALREADY canonical. Use verbatim.
// DO NOT call fs.realpathSync(p) or path.resolve against cwd -- realpath follows symlinks
// (-P) and resolve against a different cwd would diverge. Use the stored string as-is.
const canon = entry; // verbatim line-scan result
```

> **Why no re-canonicalization on the read side:** the only place `cd && pwd` runs is the writer
> (site 1), because that is the only place a possibly-relative, possibly-`..`-laden, possibly-cwd
> path exists. By the time the path is in `repos[]` it is frozen-canonical. Re-canonicalizing on read
> would (a) cost a syscall per repo per rebuild and (b) risk introducing `-P` symlink-following that
> diverges from the stored byte-string and breaks DD-5 id parity. **Read sites use the stored bytes.**

---

## 3. DD-1 — `<id>` addressing

### 3.1 The id derivation (DD-5 cross-runtime parity — exact byte input)

> **id(path) = first 8 hex chars of `sha256(CAN-1(path))`**, lengthenable on collision (§3.5).

The **exact** byte input to sha256 — identical on all runtimes, this is the DD-5 parity contract:

- The input is the **stored CAN-1 path string** (§2 site 2), encoded **UTF-8**, with **NO trailing
  newline**, **no NUL terminator**, **no quoting**, **no normalization**. Just the raw path bytes as
  stored in `repos[]`.
- The output is the lowercase hex digest; the id is its first **8** characters (`[0:8]`), extended only
  on collision (§3.5).

Because every runtime hashes the **same stored byte-string**, the id is byte-identical across Python,
Node, Bash, and PowerShell. A `/r/<id>/...` URL minted by one runtime resolves under any other.

### 3.2 The exact sha256 invocation per runtime

**Python (`server.py`, 050) — `hashlib`:**
```python
import hashlib
def repo_id(canon_path: str) -> str:
    return hashlib.sha256(canon_path.encode("utf-8")).hexdigest()[:8]
```

**Node (`server.mjs`, 051) — `crypto`:**
```js
import { createHash } from "crypto";
function repoId(canonPath) {
  return createHash("sha256").update(canonPath, "utf8").digest("hex").slice(0, 8);
}
```

**Bash (`bin/aid`, 049 — only if the writer needs an id for diagnostics; the writer stores paths, not
ids, so this is optional/diagnostic):**
```bash
# printf %s -> NO trailing newline (critical: echo would append \n and break parity).
repo_id() { printf '%s' "$1" | sha256sum | cut -c1-8; }      # GNU coreutils
# macOS/BSD fallback: shasum -a 256
repo_id() { printf '%s' "$1" | shasum -a 256 | cut -c1-8; }
```

**PowerShell (`bin/aid.ps1`, 049 — diagnostic only):**
```powershell
# Hash the UTF-8 bytes of the path, NO trailing newline.
function Get-RepoId([string]$CanonPath) {
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($CanonPath)   # no newline appended
  $sha   = [System.Security.Cryptography.SHA256]::Create()
  -join ($sha.ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') }) `
    | ForEach-Object { $_.Substring(0, 8) }
}
# NOTE: Get-FileHash hashes a FILE; for a string use SHA256.Create().ComputeHash on UTF8 bytes
# (do NOT write the path to a temp file -- that risks a trailing newline and is unnecessary).
```

> The writer (049) stores **paths**, not ids; the servers (050/051) derive ids. The Bash/PS id helpers
> above exist only if 049 wants to log an id for diagnostics. They are pinned here so any id minted
> anywhere uses the identical `printf %s` / UTF-8-no-newline input.

### 3.3 URL grammar (`/r/<id>/<leaf>`) — structurally traversal-safe

```
/r/<id>/<leaf>
   <id>  = [0-9a-f]{8,}              # hex only: cannot contain '.', '/', or '%'
   <leaf> in EXACTLY { home.html, kb.html, api/model }   # fixed 3-element allowlist
```

- `<id>` is matched against `\A[0-9a-f]{8,}\Z` (Python; `^...$` in JS — note Python must use `\A..\Z`,
  never `^..$`, to avoid the trailing-`\n` accept divergence from Node — see §3.3 route-parse note).
  Hex-only **structurally excludes** path traversal: an id
  cannot encode `.` (no `..`), `/` (no extra segments), or `%` (no percent-encoded escapes). A malformed
  `<id>` → 404.
- `<leaf>` is selected from the **fixed 3-element allowlist**, never echoed from the request. The served
  filesystem path is **constructed**: `registry[id] + "/.aid/dashboard/" + leaf` for the two static
  leaves; `read_repo(registry[id])` for `api/model`. The request contributes ONLY the `<id>` lookup —
  no filename, no segment, no directory component. This is the C6 "structurally refuse" guarantee by
  construction, not by sanitization.
- Anything else under `/r/...` (extra segments, a non-allowlisted leaf, a malformed id) → **404**
  (closed allowlist).

**Exact route parse per runtime** (both must produce the identical accept/reject set — SEC-2/SEC-5):

```python
# Python (050): exact-match a regex; no string-splitting that could be tricked.
import re
# CRITICAL: use \Z, NOT $ — Python's `$` also matches just before a trailing '\n',
# so `/r/<id>/home.html\n` would ACCEPT in Python but 404 in Node (JS `$` is strict).
# \Z anchors at the true end-of-string and matches Node's accept/reject set exactly (DD-5).
_R = re.compile(r"\A/r/([0-9a-f]{8,})/(home\.html|kb\.html|api/model)\Z")
m = _R.match(path)            # path already had ?query stripped
if not m: return self._send_plain(404, b"Not Found")
rid, leaf = m.group(1), m.group(2)
```
```js
// Node (051): identical anchored regex.
const R = /^\/r\/([0-9a-f]{8,})\/(home\.html|kb\.html|api\/model)$/;
const m = R.exec(url);        // url already had ?query stripped
if (!m) { res.writeHead(404, ...); res.end("404 Not Found\n"); return; }
const [, rid, leaf] = m;
```

### 3.4 The mtime+size-keyed map cache (NFR4)

The id→path map is **NOT** rebuilt per request. It is cached, keyed on the registry file's
**(mtime, size)** pair, and rebuilt **only when either changes**:

- Per request: one `stat` of `$AID_HOME/registry.yml` (O(1)). If `(st_mtime, st_size)` equals the
  cached key → use the cached `{id: path}` map (a dict/Map lookup). If it differs (an `aid add`/`remove`
  rewrote the file) → re-parse (§5) + rebuild the map (one sha256 per repo) + update the cached key.
- If the file is **absent** → the cached map is empty `{}` and the key is a sentinel (e.g.
  `(None, None)` / `(-1, -1)`); a later appearance of the file (mtime/size now present) triggers a
  rebuild. Absent ≡ empty (§1.2), never an error.
- This bounds the sha256 rehash to **actual registry mutations**; between mutations every request is a
  `stat` + a map lookup, satisfying NFR4 under the default ~5s multi-tab poll.

```python
# Python (050) cache key:
st = registry_path.stat()                  # raises FileNotFoundError if absent -> treat as empty
key = (st.st_mtime_ns, st.st_size)         # mtime_ns + size; rebuild only when key changes
```
```js
// Node (051) cache key:
const st = statSync(registryPath);         // throws ENOENT if absent -> treat as empty (key = null)
const key = `${st.mtimeMs}:${st.size}`;
```

> Use mtime **and** size together: size guards against the (rare) mtime-granularity collision where two
> writes within the same mtime tick change content but not mtime. A torn read during a concurrent
> rewrite (§4) yields a best-effort list + a parse note, never a 500; the next `stat` after the `mv`
> completes triggers a clean rebuild.

### 3.5 The 8-hex collision-lengthen policy

8 hex chars = 32 bits; for a per-machine repo set collision is astronomically unlikely, but it is
handled deterministically so both runtimes agree:

- At map-build time, compute the **full** sha256 hex for every registered path. Assign each id its
  **8-char** prefix.
- If two (or more) registered paths share the same 8-char prefix, **lengthen the colliding ids to the
  shortest prefix length L (L > 8) at which all colliding paths are unique**, and apply that same L to
  **every member of that collision group** (so the group stays mutually consistent). Non-colliding ids
  stay at 8.
- The grammar accepts `[0-9a-f]{8,}` precisely so a lengthened id (e.g. 9–12 hex) still validates and
  routes.
- Because both runtimes build the map from the **same stored paths** with the **same full sha256** and
  the **same lengthen rule (shortest-unique-prefix per group, applied deterministically)**, both
  derive **identical** ids including lengthened ones — DD-5 parity holds through collisions. The
  `/api/home` `repos[].id` field carries whatever (possibly-lengthened) id the map assigned, so the
  home page links (053) and the route resolver (050/051) always agree.

> Deterministic tie-break for "shortest unique prefix": pick the smallest L in `[9, 64]` such that all
> members of the collision group have distinct L-char prefixes; that L is unique by construction (at
> L=64 the full digest is unique unless two identical CAN-1 paths were registered, which is impossible —
> the registry is a set). Both runtimes compute the same L → same ids.

---

## 4. DD-3 — atomic write contract (writer only; 049)

### 4.1 Read-modify-write under `mktemp`+`mv` (Bash)

The registry is rewritten **whole**, never appended/edited in place, so a concurrent reader always sees
the old-or-new complete file. This reuses the exact `mktemp`+`mv` pattern already in `bin/aid:297-305`
(PATH wiring):

```bash
registry_register() {   # $1 = CAN-1 path (already canonical, §2 site 1)
    local repo="$1" reg="${AID_HOME}/registry.yml" tmp existing
    mkdir -p "$AID_HOME"
    # READ current set (line-scan, §5); absent file -> empty set.
    existing="$(_registry_read_repos "$reg")"     # newline-delimited canonical paths, or empty
    # SET-INSERT: no-op if already present (idempotent).
    if printf '%s\n' "$existing" | grep -qxF "$repo"; then
        return 0                                   # already registered: silent no-op
    fi
    tmp="$(mktemp "${reg}.aid-tmp.XXXXXX")" || { echo "WARN: aid: could not update the machine repo registry (${reg}): mktemp failed" >&2; return 0; }
    {
        printf '%s\n' "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)."
        printf '%s\n' "# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/"
        printf '%s\n' "# description/version are read from each repo's own .aid/settings.yml at render time."
        printf '%s\n' "schema: 1"
        printf '%s\n' "repos:"
        # existing entries (sorted for determinism) + the new one, each `  - <path>`
        { printf '%s\n' "$existing"; printf '%s\n' "$repo"; } | sed '/^$/d' | sort -u \
            | while IFS= read -r p; do printf '  - %s\n' "$p"; done
    } > "$tmp" || { rm -f "$tmp"; echo "WARN: aid: could not update the machine repo registry (${reg}): write failed" >&2; return 0; }
    mv -f "$tmp" "$reg"   # ATOMIC rename on same filesystem ($AID_HOME): reader sees old-or-new whole file
}

registry_unregister() { # $1 = CAN-1 path; called only when the manifest is now gone (last tool removed)
    local repo="$1" reg="${AID_HOME}/registry.yml" tmp existing
    [[ -f "$reg" ]] || return 0                    # absent registry: nothing to remove
    existing="$(_registry_read_repos "$reg")"
    # SET-REMOVE: no-op if absent.
    printf '%s\n' "$existing" | grep -qxF "$repo" || return 0
    tmp="$(mktemp "${reg}.aid-tmp.XXXXXX")" || { echo "WARN: aid: could not update the machine repo registry (${reg}): mktemp failed" >&2; return 0; }
    {
        printf '%s\n' "# AID machine repo registry (managed by 'aid add' / 'aid remove' -- do not hand-edit)."
        printf '%s\n' "# Holds ONLY the base folders of repos this CLI install manages. Per-repo name/"
        printf '%s\n' "# description/version are read from each repo's own .aid/settings.yml at render time."
        printf '%s\n' "schema: 1"
        printf '%s\n' "repos:"
        printf '%s\n' "$existing" | grep -vxF "$repo" | sed '/^$/d' | sort -u \
            | while IFS= read -r p; do printf '  - %s\n' "$p"; done
    } > "$tmp" || { rm -f "$tmp"; echo "WARN: aid: could not update the machine repo registry (${reg}): write failed" >&2; return 0; }
    mv -f "$tmp" "$reg"
}
```

Key points for 049:
- **Temp file lives in `$AID_HOME`** (same filesystem as `registry.yml`) so `mv` is an atomic rename,
  not a cross-device copy. `mktemp "${reg}.aid-tmp.XXXXXX"` puts it beside the target.
- **Failure degrades, never fails the host-tool op.** Any failure (mktemp, write, mv) prints
  `WARN: aid: could not update the machine repo registry (<path>): <reason>` to stderr and **returns 0**
  — the calling `aid add`/`remove` still exits with its host-tool result (NFR10; FF-1). The registry is
  derived state; a failed sync means "not listed until next add", never a failed install.
- **Idempotent set semantics:** register is a set-insert (no-op if present, prints nothing); unregister
  is a set-remove (no-op if absent). `sort -u` keeps the stored set deduplicated and ordered.
- **Output line** (CLI-1): on a real change, print one concise line (`Registered <repo> with the AID
  CLI.` / `Unregistered <repo> from the AID CLI.`); silent when unchanged. Gate detail behind
  `--verbose`.

### 4.2 PS twin — `Move-Item -Force`

```powershell
# Read-modify-write; write to a temp file in $AidHome, then atomic-ish replace.
$reg = Join-Path $AidHome 'registry.yml'
$tmp = Join-Path $AidHome ("registry.yml.aid-tmp." + [System.IO.Path]::GetRandomFileName())
# ... build $lines (same comment header + schema: 1 + repos: + sorted-unique '  - <path>') ...
Set-Content -LiteralPath $tmp -Value $lines -Encoding utf8NoBOM   # ASCII scaffolding; path bytes verbatim
Move-Item -LiteralPath $tmp -Destination $reg -Force              # replace whole file
# On any failure: Write-Warning "aid: could not update the machine repo registry ($reg): $_" ; return (exit with host-tool result)
```

> `Move-Item -Force` over an existing file on the same volume is the PS twin's whole-file replace. It is
> not guaranteed byte-atomic on every Windows filesystem the way POSIX `rename(2)` is, but it replaces
> the file in one operation and a reader sees either the old or the new file — torn-read tolerance (§4.3)
> covers the residual window. ASCII-only source (scaffolding); path bytes verbatim.

### 4.3 Torn-read tolerance (the reader's half of DD-3)

A concurrent reader (server map rebuild, `/api/home` builder, or the Bash idempotency check) MUST:
- Never assume the file is well-formed. It reads best-effort (§5 line-scan), and on a parse anomaly
  records a parse-note (`read.parse_warnings`) and returns the repos it could recognize.
- Because the writer uses `mv`/`Move-Item -Force` (whole-file replace), a reader landing mid-write sees
  **either the old complete file or the new complete file — never a half-written one** on POSIX. It
  therefore never needs to handle a truncated mid-`repos:` file in practice; the best-effort posture is
  the belt-and-suspenders guarantee.
- **A torn/odd read NEVER returns 500.** `/api/home` degrades to a best-effort/empty list; `/r/<id>/...`
  degrades to 404 for an unresolvable id. NFR10 throughout.

---

## 5. DD-REG-FMT — YAML line-scan parse posture (zero YAML library, both runtimes)

The registry is parsed by a **single anchored line-scan** — **no YAML library** on either runtime
(Python stdlib-only, Node built-ins-only). The scan: find sequence items under `repos:`
(`^\s*-\s`), strip the `- ` prefix, trim trailing whitespace, take the rest as the path.

> **Trim-class note (DD-5 boundary):** the three trailing-trim expressions are byte-identical for
> ASCII whitespace, but NOT for non-ASCII whitespace — Bash `sed 's/[[:space:]]*$//'` (POSIX, no
> Unicode) leaves a trailing U+00A0 (NBSP) in place, while Python/Node `\s` strip it. This only
> diverges for a path whose **own stored bytes end in non-ASCII whitespace**, which the writer never
> emits (CAN-1 paths carry no trailing whitespace) and which §1.2 already classes as a pathological
> NFR10-degrade input. Readers MUST NOT add their own Unicode trim to "fix" this — keep the path
> bytes verbatim after the ASCII trim so the sha256 input (and thus DD-5 id parity) holds.

### 5.1 Bash (049 — for the idempotency read in §4)

```bash
_registry_read_repos() {   # $1 = registry path; prints newline-delimited canonical paths (empty if absent)
    local reg="$1"
    [[ -f "$reg" ]] || return 0
    # Lines like '  - /abs/path'. grep the anchored sequence-item shape, strip leading space + '- '.
    grep -E '^[[:space:]]*-[[:space:]]+' "$reg" 2>/dev/null \
        | sed -E 's/^[[:space:]]*-[[:space:]]+//' \
        | sed -E 's/[[:space:]]+$//'
}
```

### 5.2 Python (050)

```python
import re
_ITEM = re.compile(r"^\s*-\s+(.*\S)\s*$")   # anchored sequence item; capture the trimmed path
def load_registry(reg_path) -> tuple[list[str], list[str]]:
    """Return (repos, parse_warnings). Absent file -> ([], []). Never raises."""
    warnings: list[str] = []
    try:
        text = reg_path.read_text(encoding="utf-8", errors="surrogateescape")
    except FileNotFoundError:
        return [], []                       # absent == empty (NFR10)
    except OSError as exc:
        return [], [f"registry unreadable ({exc}); empty best-effort"]
    repos: list[str] = []
    in_repos = False
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("schema:"):
            # diagnostic-only; tolerate higher schema (NFR10) -- do not gate
            val = stripped.split(":", 1)[1].strip()
            if val.isdigit() and int(val) > 1:
                warnings.append(f"registry schema {val} newer than reader (expected 1); read best-effort")
            continue
        if stripped == "repos:" or stripped.startswith("repos:"):
            in_repos = True
            continue
        m = _ITEM.match(line)
        if m:
            repos.append(m.group(1))        # the trimmed, verbatim CAN-1 path
    return repos, warnings
```

> The `in_repos` flag is tracked for clarity but the scan is robust without it (the only `- ` lines in
> the file are repo entries); a strict implementation may require `in_repos` before accepting items.
> Either is contract-valid as long as it never raises and returns the trimmed paths.

### 5.3 Node (051)

```js
import { readFileSync } from "fs";
function loadRegistry(regPath) {
  // returns { repos: string[], warnings: string[] }; absent -> {repos:[],warnings:[]}; never throws
  let text;
  try { text = readFileSync(regPath, "utf8"); }
  catch (e) {
    if (e && e.code === "ENOENT") return { repos: [], warnings: [] };   // absent == empty (NFR10)
    return { repos: [], warnings: [`registry unreadable (${e}); empty best-effort`] };
  }
  const repos = [];
  const warnings = [];
  const ITEM = /^\s*-\s+(.*\S)\s*$/;        // anchored sequence item; capture trimmed path
  for (const line of text.split(/\r?\n/)) {
    const s = line.trim();
    if (s.startsWith("schema:")) {
      const v = s.slice("schema:".length).trim();
      if (/^\d+$/.test(v) && Number(v) > 1)
        warnings.push(`registry schema ${v} newer than reader (expected 1); read best-effort`);
      continue;
    }
    if (s === "repos:" || s.startsWith("repos:")) continue;
    const m = ITEM.exec(line);
    if (m) repos.push(m[1]);                 // trimmed verbatim CAN-1 path
  }
  return { repos, warnings };
}
```

> Both runtimes: comment lines (`#...`) never match `^\s*-\s+` and are ignored. The `schema:` line is
> read for diagnostics only and never gates (§1.4). The capture group `(.*\S)` trims trailing
> whitespace; the writer emits none, so the captured string is the exact stored CAN-1 path → identical
> sha256 input (§3.1) on both runtimes. **DD-5 parity depends on this trimming being identical** — both
> use "strip leading `- ` + trailing whitespace, keep the rest verbatim".

---

## 6. Consumers — which task implements which section

| Task | Type | Implements against | Must NOT |
|---|---|---|---|
| **049** registry writer (`bin/aid` + `bin/aid.ps1`) | DEVELOP | §1 (emit exact file bytes), §2 site 1 + PS twin (CAN-1 pass-through of `_AID_TARGET`; contrast vs `pwd -P` at :43), §4 (atomic `mktemp`+`mv` / `Move-Item -Force`, WARN-and-continue), §5.1 (Bash line-scan for the idempotency check). Hooks land **before** `exit 0` at `bin/aid:1453` (add\|update → register) and `bin/aid:1474` (remove → unregister, only when the manifest is now gone). | re-canonicalize a path with `pwd -P`; fail the host-tool op on a registry-write error; duplicate metadata into the registry; add a new verb/flag |
| **050** Python server (`server.py`) | DEVELOP | §2 site 3 (use stored path verbatim, no `realpath`), §3.1-3.5 (`hashlib` id, regex route parse, mtime+size cache, collision-lengthen), §5.2 (line-scan `load_registry`), §1.4 (tolerant schema). Builds the id→path map + the `/r/<id>/{home.html,kb.html,api/model}` routes + `/api/home` (DM-2). | call `Path.resolve()`/`os.path.realpath` on a stored path; rebuild the map per request; return 500 on a torn/absent registry; serve any path outside `<repo>/.aid/dashboard/` |
| **051** Node server (`server.mjs`) | DEVELOP | §2 site 4 (stored path verbatim, no `realpathSync`), §3.1-3.5 (`crypto` id, identical anchored regex, mtime+size cache, identical collision-lengthen), §5.3 (line-scan `loadRegistry`), §1.4 (tolerant schema). Byte-parity with 050 (PT-1-H). | call `fs.realpathSync`/`path.resolve` against cwd on a stored path; diverge from 050's regex/cache/lengthen rule; 500 on torn/absent registry |
| **053** CLI home page (`$AID_HOME/dashboard/index.html`) | DEVELOP | §3.3 (link target grammar `/r/<id>/home.html` and `/r/<id>/kb.html`), §3.1 (treats `repos[].id` from `/api/home` as opaque — never re-derives it client-side). Renders the machine panel + repo-card grid; each card links by the `id` the server minted. | re-hash paths client-side; construct `/r/...` URLs from a path; render the raw path/id as a card title (use `name`); write to any `.aid/` |

**Cross-cutting parity gate (all of 049/050/051):** the id is byte-identical across runtimes **only if**
every site uses the identical CAN-1 stored byte-string (§2) and the identical UTF-8-no-trailing-newline
sha256 input (§3.1). PT-1-H (SEC-5) verifies this with a checked-in registry fixture across both
servers. Any re-canonicalization (`-P`/`realpath`) or any trailing-newline drift in the hash input
breaks DD-5 parity — these are the two failure modes to guard in review.
