/**
 * dashboard/server/reader.mjs
 * Node runtime reader: port of dashboard/reader/ (Python) for the Node thin server.
 *
 * Exports readRepo(root) -> model object (same shape as Python RepoModel serialized).
 *
 * Read-only by construction: uses only fs.readFileSync / fs.readdirSync / fs.statSync,
 * plus fs.openSync/readSync/closeSync opened read-only ("r") for the bounded-read
 * helper (readFileBounded, v2.1.0 security hardening -- FIX-3).
 * No fs.write* / fs.appendFile / fs.unlink / fs.open for write anywhere in this file.
 * No agent/LLM import. No third-party deps. Node built-in modules only.
 *
 * Source MUST be ASCII-only (shipped script posture; coding-standards.md).
 * UTF-8 payload content is emitted at runtime, not in source.
 */

import { readFileSync, readdirSync, statSync, existsSync, openSync, readSync, closeSync } from "fs";
import { resolve, join, basename } from "path";
import { execFileSync } from "child_process";

// ---------------------------------------------------------------------------
// Security hardening (v2.1.0, FIX-3 MEDIUM): shared bounded-read helper.
// Twin of dashboard/reader/io_bounds.py read_bytes_bounded() (byte-parity minded).
//
// Problem: the reader read every STATE.yml / DETAIL.md / BLUEPRINT.md / PLAN.md /
// delivery-NNN-issues.md / KB doc fully into memory with no size cap -- a very
// large (or maliciously large) file at any of these well-known paths could
// exhaust process memory (DoS) -- every reader read site called readFileSync()
// directly with no bound.
//
// Fix: every content-read site routes through readFileBounded() instead of
// readFileSync(). stat() first; size <= MAX_READ_BYTES -> full read (byte-
// identical to readFileSync(path) for every real-world file -- existing
// behavior and the Python<->Node parity contract are unchanged for the common
// case); size > MAX_READ_BYTES -> bounded read of only the first
// MAX_READ_BYTES bytes. The file is NEVER skipped -- the reader's line-
// scanners tolerate a truncated tail (degrade gracefully, never throw, never
// skip -- matches the reader's no-throw posture).
// ---------------------------------------------------------------------------

const MAX_READ_BYTES = 5 * 1024 * 1024; // 5 MB (matches Python io_bounds.MAX_READ_BYTES)

function readFileBounded(path, maxBytes = MAX_READ_BYTES) {
  // Byte-identical to readFileSync(path) when the file is <= maxBytes (the
  // common case for every real repo file). For an oversized file, returns
  // only the first maxBytes bytes (never skips the file).
  const size = statSync(path).size;
  if (size <= maxBytes) {
    return readFileSync(path);
  }
  const fd = openSync(path, "r");
  try {
    const buf = Buffer.alloc(maxBytes);
    const bytesRead = readSync(fd, buf, 0, maxBytes, 0);
    return buf.subarray(0, bytesRead);
  } finally {
    closeSync(fd);
  }
}

// ---------------------------------------------------------------------------
// Enum literals (DM-6 -- mirrors models.py verbatim)
// ---------------------------------------------------------------------------

const Lifecycle = {
  Running: "Running",
  PausedAwaitingInput: "Paused-Awaiting-Input",
  Blocked: "Blocked",
  Completed: "Completed",
  Canceled: "Canceled",
  Unknown: "Unknown",
};

// Faithful numbered pipeline; ends at Execute (mirrors models.py Phase).
// Discover is NOT a member -- aid-discover is KB-level (writes kb_status, never a
// work phase:); it is surfaced from KbStatus instead. Deploy is NOT a member --
// the numbered sequence ends at Execute; /aid-deploy is a separate path (no longer
// a work phase:).
const Phase = {
  Describe: "Describe",
  Define: "Define",
  Specify: "Specify",
  Plan: "Plan",
  Detail: "Detail",
  Execute: "Execute",
  Unknown: "Unknown",
};

const TaskStatus = {
  Pending: "Pending",
  InProgress: "In Progress",
  InReview: "In Review",
  Blocked: "Blocked",
  Done: "Done",
  Failed: "Failed",
  Canceled: "Canceled",
  Unknown: "Unknown",
};

const SourceMode = {
  Normalized: "normalized",
  Fallback: "fallback",
  Mixed: "mixed",
};

// FR32 5-state KB status enum (feature-007 DM-A2, task-064)
// Derived by the reader (FF-A3); never written to disk (NFR2).
const KbStatus = {
  pending:    "pending",    // .aid/knowledge/ absent or empty
  generating: "generating", // KB present but not yet User Approved: yes (SPEC residual-#1)
  preparing:  "preparing",  // KB approved but kb.html absent OR summary not V1-approved
  approved:   "approved",   // KB + kb.html ready, current, approved
  outdated:   "outdated",   // approved but default branch advanced past kb_baseline (FR35)
  unknown:    "unknown",    // reader-only sentinel; never written to disk
};

// ---------------------------------------------------------------------------
// Null-value sentinels (mirrors parsers.py _NULL_SENTINELS)
// ---------------------------------------------------------------------------

const NULL_SENTINELS = new Set(["-", "--", "\u2014", ""]);

function isNull(val) {
  return NULL_SENTINELS.has(val);
}

// ---------------------------------------------------------------------------
// STATE.yml whole-document read (work-009-refactor task-004, porting
// task-003's Python state_schema.py to this Node runtime).
//
// parseStateDocument(text, {fileLabel, allowFrontmatterFence}) is THE single
// hand-rolled parser for the SPEC.md (work-009-refactor) D-3 permitted YAML
// subset: shapes S1-S5, both D-5 quoting/escape modes, inline- and
// full-line-comment handling, and the D-3 reject list. By default (every
// state-file reader in this file) it parses the WHOLE input as one
// YAML-subset document; the CALLER, never the document's own leading bytes,
// opts in to the ORIGINAL fenced-frontmatter-only scan
// (_parseFencedFrontmatterLoose) via allowFrontmatterFence -- the ONE
// legitimate caller is parseKbState, for .aid/knowledge/STATE.md (out of
// scope for this work; SPEC.md D-6). parseBoolYesno / parseHeaderBoldField /
// resolveKind round out the same public surface as the Python twin.
//
// Node twin of dashboard/reader/state_schema.py, which defines the SAME
// functions (parse_state_document / parse_bool_yesno / parse_header_bold_
// field / resolve_kind) across its own module boundary since Python can
// split responsibility into a package while this Node reader is a single
// file. Keep both in lockstep.
// ---------------------------------------------------------------------------

const RE_FM_FENCE_GENERIC = /^---\s*$/;
const RE_TOPLEVEL_KV = /^([A-Za-z0-9_\-]+):\s*(.*)$/;
const RE_NESTED_KV = /^[ \t]+([A-Za-z0-9_\-]+):\s*(.*)$/;
const RE_SECTION_HEADER_GENERIC = /^##\s+/;

function _stripScalarQuotes(raw) {
  // Strip one layer of matching surrounding quotes from a YAML scalar.
  // For a SINGLE-quoted scalar, also collapse YAML's ''-escaping ('' -> '),
  // the exact inverse of the frontmatter writer (task-004 emits a single-quoted
  // scalar with embedded ' doubled). Twin of Python _strip_scalar_quotes.
  const val = raw.trim();
  if (val.length >= 2 && val[0] === val[val.length - 1] &&
      (val[0] === "'" || val[0] === '"')) {
    const inner = val.slice(1, -1);
    return val[0] === "'" ? inner.split("''").join("'") : inner;
  }
  return val;
}

// A '{...}' template token anywhere in the value (matching braces, no nested
// '}'). Every un-instantiated placeholder in the 4 STATE templates carries one.
const RE_PLACEHOLDER_TOKEN = /\{[^}]*\}/;

// Frontmatter keys whose value is human/skill free-text, NOT a closed enum.
// Twin of Python _FREETEXT_FM_KEYS -- the ' | ' enum-list marker is suppressed
// for these so a real free-text value containing ' | ' is not discarded; their
// own placeholders still carry a '{...}' token. Keep in lockstep with Python.
const FREETEXT_FM_KEYS = new Set(["pause_reason", "block_reason", "block_artifact", "notes"]);

function _looksLikeUnfilledPlaceholder(val, isFreetext) {
  // True if val is un-instantiated TEMPLATE placeholder text, not real data.
  // Twin of Python _looks_like_unfilled_placeholder() -- see its docstring for
  // the rollout-safety rationale (BLUEPRINT gate criteria #6). Two markers:
  //   - a '{...}' token anywhere (always a placeholder), and
  //   - a ' | ' enum-alternatives list, but ONLY for closed-enum fields; it is
  //     suppressed when isFreetext (real free-text may contain ' | ').
  if (RE_PLACEHOLDER_TOKEN.test(val)) return true;
  if (!isFreetext && val.includes(" | ")) return true;
  return false;
}

function _parseFencedFrontmatterLoose(text) {
  // The ORIGINAL parseFrontmatterScalars scan, UNCHANGED: tolerant flat +
  // one-level-nested frontmatter scalar scan between the first pair of '---'
  // lines. Never emits parse_warnings (matches the original contract). This
  // is the path `.aid/knowledge/STATE.md` (out of scope, stays markdown, may
  // legitimately carry constructs -- e.g. a flow list `tags: [a, b]` -- the
  // strict D-3 engine below would reject) continues to use verbatim.
  // Twin of Python _parse_fenced_frontmatter_loose(). Returns a plain object:
  //   top-level scalar keys map directly:       {started: "2026-07-10"}
  //   one level of nested mapping is dot-joined: {"pipeline.path": "lite"}
  // Never throws (NFR7). No file I/O. Returns {} when no opening '---' fence.
  const result = {};
  let inFm = false;
  let fmEntered = false;
  let currentPrefix = null;

  // CRLF tolerance: text.split("\n") leaves a trailing "\r" on each line for
  // CRLF-authored files (e.g. edited on Windows); JS's "." and "$" both treat
  // "\r" as a line terminator (unlike Python's splitlines(), which already
  // strips it), so an un-stripped "\r" would silently fail every (.*)$-shaped
  // capture below. Stripping it here keeps this function's behavior identical
  // to the Python twin for both LF-only and CRLF-authored STATE.md files.
  for (const rawLine of text.split("\n")) {
    const line = rawLine.endsWith("\r") ? rawLine.slice(0, -1) : rawLine;
    if (RE_FM_FENCE_GENERIC.test(line)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break; // closing fence
      }
    }
    if (!inFm) break; // no opening fence -- no frontmatter at all

    if (!line.trim()) continue;

    if (line[0] === " " || line[0] === "\t") {
      // Nested continuation line
      if (currentPrefix === null) continue; // orphan indented line; ignore
      const m = line.match(RE_NESTED_KV);
      if (m) {
        const key = m[1];
        const val = _stripScalarQuotes(m[2]);
        if (val !== "" && !_looksLikeUnfilledPlaceholder(val, FREETEXT_FM_KEYS.has(key))) {
          result[`${currentPrefix}.${key}`] = val;
        }
      }
      continue;
    }

    // Top-level line
    const m = line.match(RE_TOPLEVEL_KV);
    if (!m) {
      currentPrefix = null;
      continue;
    }
    const key = m[1];
    const rest = m[2].trim();
    if (rest === "") {
      // Bare 'key:' -- nested mapping follows
      currentPrefix = key;
      continue;
    }
    currentPrefix = null;
    const val = _stripScalarQuotes(rest);
    if (!_looksLikeUnfilledPlaceholder(val, FREETEXT_FM_KEYS.has(key))) {
      result[key] = val;
    }
  }

  return result;
}

// ---------------------------------------------------------------------------
// SPEC.md (work-009-refactor) D-5 quoted-scalar decoding
// Twin of dashboard/reader/state_schema.py _decode_double_quoted / _decode_scalar.
// ---------------------------------------------------------------------------

const DQ_ESCAPES = { '"': '"', "\\": "\\", n: "\n", r: "\r", t: "\t" };

function _decodeDoubleQuoted(inner, lineNo, fileLabel, warnings) {
  // Decode the five-escape subset (\" \\ \n \r \t) inside a double-quoted
  // scalar's INNER text (quotes already stripped). Any other backslash
  // escape (\uXXXX, \x41, ...) is REJECTED per D-3: a parse_warning is
  // emitted naming file/line, and the backslash + following character are
  // kept LITERALLY (never throws, never drops the rest of the value).
  const out = [];
  let i = 0;
  const n = inner.length;
  while (i < n) {
    const c = inner[i];
    if (c === "\\" && i + 1 < n) {
      const nxt = inner[i + 1];
      const mapped = DQ_ESCAPES[nxt];
      if (mapped !== undefined) {
        out.push(mapped);
        i += 2;
        continue;
      }
      warnings.push(
        fileLabel + ":" + lineNo + ": unsupported double-quoted escape '\\" + nxt + "' rejected; kept literally"
      );
      out.push(c);
      out.push(nxt);
      i += 2;
      continue;
    }
    out.push(c);
    i += 1;
  }
  return out.join("");
}

function _decodeScalar(v, lineNo, fileLabel, warnings) {
  // Decode one already comment-stripped, already-trimmed scalar token.
  // Double-quoted -> the D-5 mode-3 five-escape subset (_decodeDoubleQuoted).
  // Single-quoted / bare -> _stripScalarQuotes (unchanged helper).
  if (v.length >= 2 && v[0] === '"' && v[v.length - 1] === '"') {
    return _decodeDoubleQuoted(v.slice(1, -1), lineNo, fileLabel, warnings);
  }
  return _stripScalarQuotes(v);
}

// ---------------------------------------------------------------------------
// Strict SPEC.md (work-009-refactor) D-3 whole-document engine (S1-S5 + reject
// list). Twin of dashboard/reader/state_schema.py's _tokenize / _finalize_value /
// _build_tree / parse_state_document -- keep the two in lockstep.
// ---------------------------------------------------------------------------

const _RE_KEY_LINE = /^([A-Za-z0-9_-]+):\s*(.*)$/;
const _MAX_LEVEL = 3; // S3 (3 mapping levels) / S5 (a sequence at the 2nd level)
const _REJECT = Symbol("REJECT"); // sentinel: "skip this key/item entirely, emit no value"

function _tokenize(numbered, warnings, fileLabel) {
  // Pass 1: classify each line into a token, applying every non-value D-3
  // reject rule decidable from indentation/shape alone (tabs, indent-not-
  // multiple-of-two, nesting-too-deep, a second document marker, a line that
  // is neither a 'key:' line nor a sequence entry). Full-line comments (any
  // indentation) and blank lines are silently skipped (not a reject -- D-3
  // says these are normal, expected constructs).
  const tokens = [];
  for (const [lineNo, raw] of numbered) {
    const leadMatch = raw.match(/^[ \t]*/);
    const lead = leadMatch ? leadMatch[0] : "";
    if (lead.includes("\t")) {
      warnings.push(fileLabel + ":" + lineNo + ": tab indentation rejected; line skipped");
      continue;
    }

    const line = raw.replace(/[\r\n]+$/, "");
    if (!line.trim()) continue; // blank line

    const indentMatch = line.match(/^ */);
    const indent = indentMatch[0].length;
    const content = line.slice(indent);

    if (content.startsWith("#")) continue; // full-line comment, any indentation (D-3)

    if (indent % 2 !== 0) {
      warnings.push(fileLabel + ":" + lineNo + ": indentation not a multiple of two; line skipped");
      continue;
    }

    const level = indent / 2;
    if (level > _MAX_LEVEL) {
      warnings.push(fileLabel + ":" + lineNo + ": nesting deeper than S5; line skipped");
      continue;
    }

    if (content === "---" || content === "...") {
      warnings.push(fileLabel + ":" + lineNo + ": a second document ('" + content + "') is rejected; line skipped");
      continue;
    }

    // A bare (non-'key:') directive/anchor/alias/tag line at column 0 or
    // deeper -- e.g. a YAML directive '%YAML 1.2'. None of these four
    // indicator characters can start a valid key (_RE_KEY_LINE's charset is
    // alnum/underscore/hyphen only), so this check is unambiguous and must
    // run BEFORE the key-line/malformed-line fallback below, which would
    // otherwise report it as a generic malformed line instead of naming the
    // specific rejected construct (D-3).
    if (content.length > 0 && ["%", "&", "*", "!"].includes(content[0])) {
      warnings.push(fileLabel + ":" + lineNo + ": anchor/alias/tag/directive rejected");
      continue;
    }

    if (content === "-" || content.startsWith("- ")) {
      const body = content.startsWith("- ") ? content.slice(2) : "";
      const m = body ? body.match(_RE_KEY_LINE) : null;
      if (m) {
        tokens.push({ lineNo: lineNo, level: level, dash: true, key: m[1], rest: m[2] });
      } else {
        tokens.push({ lineNo: lineNo, level: level, dash: true, key: null, rest: body });
      }
      continue;
    }

    const m = content.match(_RE_KEY_LINE);
    if (!m) {
      warnings.push(fileLabel + ":" + lineNo + ": malformed line (neither a 'key:' line nor a sequence entry); line skipped");
      continue;
    }
    tokens.push({ lineNo: lineNo, level: level, dash: false, key: m[1], rest: m[2] });
  }

  return tokens;
}

function _finalizeValue(rawRest, tok, fileLabel, warnings, opts) {
  // Turn a token's raw value text into a scalar string, [], {}, or _REJECT.
  // Applies, in order: inline-comment stripping (D-3, via the SAME
  // stripYamlInlineComment idiom parseProjectSettings/parseMinimumGrade use),
  // the flow-collection / block-scalar / anchor-alias-tag-directive reject
  // checks (D-3, each on first-character shape so a quoted value is never
  // misdetected), D-5 scalar decoding, and -- for key-based values only,
  // never for a bare sequence-of-scalars item -- the rollout-safety
  // placeholder check.
  const keyName = opts && opts.keyName !== undefined ? opts.keyName : null;
  const isListItem = !!(opts && opts.isListItem);

  const v = stripYamlInlineComment(rawRest).trim();
  const wasQuoted = v.length > 0 && (v[0] === "'" || v[0] === '"');
  let decoded;
  if (v === "") {
    decoded = "";
  } else {
    const first = v[0];
    if (first === "[" || first === "{") {
      if (v === "[]") return [];
      if (v === "{}") return {};
      warnings.push(
        fileLabel + ":" + tok.lineNo + ": flow collection rejected (only the literal [] / {} is permitted)"
      );
      return _REJECT;
    }
    if (first === "|" || first === ">") {
      warnings.push(fileLabel + ":" + tok.lineNo + ": block scalar rejected");
      return _REJECT;
    }
    if (["&", "*", "!", "%"].includes(first)) {
      warnings.push(fileLabel + ":" + tok.lineNo + ": anchor/alias/tag/directive rejected");
      return _REJECT;
    }
    decoded = _decodeScalar(v, tok.lineNo, fileLabel, warnings);
  }

  if (!isListItem) {
    const isFreetext = wasQuoted || (keyName !== null && FREETEXT_FM_KEYS.has(keyName));
    if (_looksLikeUnfilledPlaceholder(decoded, isFreetext)) {
      return _REJECT;
    }
  }

  return decoded;
}

function _buildTree(tokens, warnings, fileLabel) {
  // Pass 2: assemble the token stream into a nested object/array tree. Uses a
  // level-indexed stack of currently-open containers (level 0 == the root
  // mapping; deeper levels are opened by a bare 'key:' mapping opener or by a
  // dash-with-inline-key sequence item, and closed the moment a shallower-or-
  // equal-level token arrives). A bare opener's object-vs-array shape is
  // decided by a single-token lookahead (its first child's dash-ness) --
  // defaulting to an empty mapping when it has no children at all (D-3: "an
  // absent key is semantically identical to an empty collection").
  //
  // Duplicate keys at the same mapping level: last value wins, and a
  // parse_warning is emitted (D-3).
  const root = {};
  const stack = { 0: root };
  const stackKind = { 0: "map" };

  const n = tokens.length;
  for (let i = 0; i < n; i++) {
    const tok = tokens[i];
    const level = tok.level;

    for (const lvl of Object.keys(stack).map(Number).filter((l) => l > level)) {
      delete stack[lvl];
      delete stackKind[lvl];
    }

    const parent = stack[level];
    const parentKind = stackKind[level];
    if (parent === undefined) {
      warnings.push(fileLabel + ":" + tok.lineNo + ": orphan line (no open parent container at this indentation); line skipped");
      continue;
    }

    if (tok.dash) {
      if (parentKind !== "list") {
        warnings.push(fileLabel + ":" + tok.lineNo + ": sequence entry where a mapping key was expected; line skipped");
        continue;
      }
      if (tok.key !== null) {
        const item = {};
        const val = _finalizeValue(tok.rest, tok, fileLabel, warnings, { keyName: tok.key });
        if (val !== _REJECT) {
          item[tok.key] = val;
        }
        parent.push(item);
        stack[level + 1] = item;
        stackKind[level + 1] = "map";
      } else {
        const val = _finalizeValue(tok.rest, tok, fileLabel, warnings, { isListItem: true });
        if (val !== _REJECT) {
          parent.push(val);
        }
      }
      continue;
    }

    // Plain 'key:' line
    if (parentKind !== "map") {
      warnings.push(fileLabel + ":" + tok.lineNo + ": mapping key where a sequence entry was expected; line skipped");
      continue;
    }

    const key = tok.key;
    const rest = tok.rest.trim();
    if (rest === "") {
      const nxt = i + 1 < n ? tokens[i + 1] : null;
      let newContainer, newKind;
      if (nxt !== null && nxt.level === level + 1 && nxt.dash) {
        newContainer = [];
        newKind = "list";
      } else {
        newContainer = {};
        newKind = "map";
      }
      if (Object.prototype.hasOwnProperty.call(parent, key)) {
        warnings.push(fileLabel + ":" + tok.lineNo + ": duplicate key '" + key + "'; last value wins");
      }
      parent[key] = newContainer;
      stack[level + 1] = newContainer;
      stackKind[level + 1] = newKind;
      continue;
    }

    const val = _finalizeValue(rest, tok, fileLabel, warnings, { keyName: key });
    if (val !== _REJECT) {
      if (Object.prototype.hasOwnProperty.call(parent, key)) {
        warnings.push(fileLabel + ":" + tok.lineNo + ": duplicate key '" + key + "'; last value wins");
      }
      parent[key] = val;
    }
  }

  return root;
}

function parseStateDocument(text, options) {
  // Parse a STATE.yml document -- or, ONLY when the caller opts in, a legacy
  // frontmatter block -- into a nested object tree, plus a list of
  // parse_warning strings. Twin of Python parse_state_document().
  //
  // Dispatch is decided by the CALLER, via allowFrontmatterFence, NEVER by
  // sniffing the document's own content. A prior revision of this function
  // decided strict-vs-loose by checking whether text's first line was a bare
  // '---'; that made a malformed STATE.yml that happens to open with a fence
  // (the exact construct D-1/D-3 forbid: "one file, one document" / "a
  // second document ... at column 0") silently take the LOOSE path instead
  // of being rejected. Content can decide WHAT is wrong with a document; it
  // must never decide WHICH GRAMMAR is used to read it.
  //
  //   - allowFrontmatterFence=false (the default -- every state-file reader
  //     in this file uses this): the WHOLE text is parsed by the strict D-3
  //     subset engine (_tokenize + _buildTree): shapes S1-S5, both D-5
  //     quoting/escape modes, inline- and full-line-comment stripping, and
  //     the full reject list. Every reject emits a parse_warning naming
  //     file/line/construct, skips exactly that key, and keeps parsing --
  //     never throws.
  //   - allowFrontmatterFence=true (the ONE legitimate caller: parseKbState,
  //     for .aid/knowledge/STATE.md, which stays markdown-with-frontmatter
  //     by design and is out of scope for this work -- SPEC.md D-6) -- a
  //     leading '---' fence on the text's very first line switches to the
  //     ORIGINAL, unchanged, flat + one-level-nested scan
  //     (_parseFencedFrontmatterLoose), bounded to the region between the
  //     first and second '---' lines (or to EOF if no closing fence is
  //     found). This path emits no parse_warnings, exactly like the original
  //     function. If the caller passes allowFrontmatterFence=true but the
  //     text does NOT open with a fence, the strict engine runs anyway.
  //
  // A leading byte-order mark is stripped and a parse_warning is emitted
  // naming the file, in EITHER path, before fence detection runs.
  //
  // Returns [data, warnings]:
  //   - data: nested object tree in the strict path (S1 scalar keys map to
  //     string; S2/S3 mapping keys map to object; S4/S5 sequence keys map to
  //     array); a FLAT dot-joined object in the fenced-legacy path.
  //   - warnings: array of parse_warning strings; always [] in the
  //     fenced-legacy path.
  //
  // Never throws (NFR7). No file I/O -- pure text -> value.
  const opts = options || {};
  const fileLabel = opts.fileLabel !== undefined ? opts.fileLabel : "STATE";
  const allowFrontmatterFence = opts.allowFrontmatterFence === true;

  const warnings = [];

  if (text.length > 0 && text.charCodeAt(0) === 0xFEFF) {
    text = text.slice(1);
    warnings.push(fileLabel + ": byte-order mark (BOM) stripped");
  }

  const rawLines = text.split("\n");

  if (allowFrontmatterFence && rawLines.length > 0 && RE_FM_FENCE_GENERIC.test(rawLines[0])) {
    // Legacy fenced-frontmatter shape -- unchanged loose scan, bounded to
    // the region between the first and second '---' lines. Reachable ONLY
    // when the caller opted in (parseKbState); every state-file reader
    // leaves allowFrontmatterFence at its strict default, so a state file
    // opening with '---' falls through to the strict engine below and is
    // rejected as a second document, like any other one.
    const bodyLines = [];
    for (let i = 1; i < rawLines.length; i++) {
      if (RE_FM_FENCE_GENERIC.test(rawLines[i])) break;
      bodyLines.push(rawLines[i]);
    }
    const fencedText = "---\n" + bodyLines.join("\n") + "\n---\n";
    const data = _parseFencedFrontmatterLoose(fencedText);
    return [data, warnings];
  }

  const numbered = rawLines.map((ln, idx) => [idx + 1, ln]);
  const tokens = _tokenize(numbered, warnings, fileLabel);
  const data = _buildTree(tokens, warnings, fileLabel);
  return [data, warnings];
}

function parseHeaderBoldField(text, label) {
  // Legacy-prose fallback: scan the pre-first-"##" header-blockquote zone for
  // a '**{label}:** value' line (optionally '>'-prefixed), case-insensitive.
  // Twin of Python parse_header_bold_field(). Returns trimmed value or null.
  const escaped = label.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const pattern = new RegExp("\\*\\*" + escaped + ":\\*\\*\\s*(.+)", "i");
  for (const line of text.split("\n")) {
    if (RE_SECTION_HEADER_GENERIC.test(line)) break;
    const m = line.match(pattern);
    if (m) return m[1].trim();
  }
  return null;
}

function parseBoolYesno(raw) {
  // Normalize a yes/no/true/false (case-insensitive) scalar to bool.
  // Twin of Python parse_bool_yesno() -- see its docstring for the
  // twin-parity landmine rationale (PyYAML 1.1 vs js-yaml 1.2 yes/no coercion).
  // Returns null when raw is null/undefined or an unrecognized token.
  if (raw === null || raw === undefined) return null;
  const v = String(raw).trim().toLowerCase();
  if (v === "yes" || v === "true") return true;
  if (v === "no" || v === "false") return false;
  return null;
}

// pipeline.initiator -> display kind: static mirror of
// canonical/aid/templates/shortcut-catalog.yml's {name: [verb, artifact]} rows.
// NOT read from disk at runtime -- see state_schema.py's SHORTCUT_KIND_MAP
// docstring for the full rationale. Keep in lockstep with the Python twin.
export const SHORTCUT_KIND_MAP = {
  "aid-fix": ["fix", ""],
  "aid-create": ["create", ""],
  "aid-create-api": ["create", "api"],
  "aid-create-ui": ["create", "ui"],
  "aid-create-theme": ["create", "theme"],
  "aid-create-cli": ["create", "cli"],
  "aid-create-data-model": ["create", "data-model"],
  "aid-create-data-pipeline": ["create", "data-pipeline"],
  "aid-create-messaging": ["create", "messaging"],
  "aid-create-integration": ["create", "integration"],
  "aid-create-job": ["create", "job"],
  "aid-create-config": ["create", "config"],
  "aid-create-infra": ["create", "infra"],
  "aid-create-test": ["create", "test"],
  "aid-create-document": ["create", "document"],
  "aid-create-dashboard": ["create", "dashboard"],
  "aid-create-diagram": ["create", "diagram"],
  "aid-add": ["create", ""],
  "aid-add-api": ["create", "api"],
  "aid-add-ui": ["create", "ui"],
  "aid-add-theme": ["create", "theme"],
  "aid-add-cli": ["create", "cli"],
  "aid-add-data-model": ["create", "data-model"],
  "aid-add-data-pipeline": ["create", "data-pipeline"],
  "aid-add-messaging": ["create", "messaging"],
  "aid-add-integration": ["create", "integration"],
  "aid-add-job": ["create", "job"],
  "aid-add-config": ["create", "config"],
  "aid-add-infra": ["create", "infra"],
  "aid-add-test": ["create", "test"],
  "aid-add-document": ["create", "document"],
  "aid-add-dashboard": ["create", "dashboard"],
  "aid-change": ["change", ""],
  "aid-change-api": ["change", "api"],
  "aid-change-ui": ["change", "ui"],
  "aid-change-theme": ["change", "theme"],
  "aid-change-cli": ["change", "cli"],
  "aid-change-data-model": ["change", "data-model"],
  "aid-change-data-pipeline": ["change", "data-pipeline"],
  "aid-change-messaging": ["change", "messaging"],
  "aid-change-integration": ["change", "integration"],
  "aid-change-job": ["change", "job"],
  "aid-change-config": ["change", "config"],
  "aid-change-infra": ["change", "infra"],
  "aid-change-test": ["change", "test"],
  "aid-change-document": ["change", "document"],
  "aid-change-dashboard": ["change", "dashboard"],
  "aid-refactor": ["refactor", ""],
  "aid-update": ["update", ""],
  "aid-update-api": ["update", "api"],
  "aid-update-ui": ["update", "ui"],
  "aid-update-theme": ["update", "theme"],
  "aid-update-cli": ["update", "cli"],
  "aid-update-data-model": ["update", "data-model"],
  "aid-update-data-pipeline": ["update", "data-pipeline"],
  "aid-update-messaging": ["update", "messaging"],
  "aid-update-integration": ["update", "integration"],
  "aid-update-job": ["update", "job"],
  "aid-update-config": ["update", "config"],
  "aid-update-infra": ["update", "infra"],
  "aid-update-test": ["update", "test"],
  "aid-update-document": ["update", "document"],
  "aid-update-dashboard": ["update", "dashboard"],
  "aid-remove": ["remove", ""],
  "aid-delete": ["remove", ""],
  "aid-deprecate": ["deprecate", ""],
  "aid-migrate": ["migrate", ""],
  "aid-test": ["test", ""],
  "aid-test-security": ["test", "security"],
  "aid-test-performance": ["test", "performance"],
  "aid-test-data-quality": ["test", "data-quality"],
  "aid-experiment": ["experiment", ""],
  "aid-prototype": ["prototype", ""],
  "aid-prototype-ui": ["prototype", "ui"],
  "aid-design": ["design", ""],
  "aid-document": ["document", ""],
  "aid-document-decision": ["document", "decision"],
  "aid-document-architecture": ["document", "architecture"],
  "aid-document-guideline": ["document", "guideline"],
  "aid-document-standard": ["document", "standard"],
  "aid-document-runbook": ["document", "runbook"],
  "aid-document-tutorial": ["document", "tutorial"],
  "aid-document-changelog": ["document", "changelog"],
  "aid-report": ["report", ""],
  "aid-show-dashboard": ["show-dashboard", ""],
  "aid-review": ["review", ""],
  "aid-audit": ["review", ""],
  "aid-research": ["research", ""],
  "aid-investigate": ["research", ""],
  "aid-spike": ["research", ""],
  "aid-deploy": ["deploy", ""],
  "aid-monitor": ["monitor", ""],
  "aid-query-kb": ["query", ""],
  "aid-ask": ["query", ""],

  // --- design-phase skill family ------------------------------------------
  // Mirror state_schema.py SHORTCUT_KIND_MAP; see there for why these are seeded
  // ahead of the catalog rows that name them (leg 3 permits a superset, so a key with
  // no row is legal while a row with no key is not).
  "aid-brainstorm": ["brainstorm", ""],

  "aid-create-roadmap": ["create", "roadmap"],
  "aid-create-backlog": ["create", "backlog"],
  "aid-create-mvp": ["create", "mvp"],
  "aid-create-architecture": ["create", "architecture"],
  "aid-create-stack": ["create", "stack"],
  "aid-create-testing-strategy": ["create", "testing-strategy"],
  "aid-create-cicd": ["create", "cicd"],

  "aid-update-roadmap": ["update", "roadmap"],
  "aid-update-mvp": ["update", "mvp"],
  "aid-update-backlog": ["update", "backlog"],
  "aid-update-architecture": ["update", "architecture"],
  "aid-update-stack": ["update", "stack"],
  "aid-update-testing-strategy": ["update", "testing-strategy"],
  "aid-update-cicd": ["update", "cicd"],

  "aid-design-roadmap": ["design", "roadmap"],
  "aid-design-mvp": ["design", "mvp"],
  "aid-design-backlog": ["design", "backlog"],
  "aid-design-api": ["design", "api"],
  "aid-design-ui": ["design", "ui"],
  "aid-design-theme": ["design", "theme"],
  "aid-design-cli": ["design", "cli"],
  "aid-design-data-model": ["design", "data-model"],
  "aid-design-data-pipeline": ["design", "data-pipeline"],
  "aid-design-messaging": ["design", "messaging"],
  "aid-design-integration": ["design", "integration"],
  "aid-design-job": ["design", "job"],
  "aid-design-config": ["design", "config"],
  "aid-design-infra": ["design", "infra"],
  "aid-design-test": ["design", "test"],
  "aid-design-document": ["design", "document"],
  "aid-design-dashboard": ["design", "dashboard"],
  "aid-design-architecture": ["design", "architecture"],
  "aid-design-stack": ["design", "stack"],
  "aid-design-testing-strategy": ["design", "testing-strategy"],
  "aid-design-cicd": ["design", "cicd"],
};

// The FULL-pipeline starting skill -- never a shortcut-catalog.yml row.
const FULL_PATH_INITIATOR = "aid-describe";
const FULL_PATH_KIND = "full path";

function resolveKind(initiator) {
  // Resolve a pipeline.initiator skill name to a human display verb.
  // Twin of Python resolve_kind(). Unknown/absent -> null (caller drops the
  // redundant word instead of rendering a literal "Unknown"/"Lite").
  if (!initiator) return null;
  const trimmed = initiator.trim();
  if (!trimmed) return null;
  if (trimmed === FULL_PATH_INITIATOR) return FULL_PATH_KIND;

  const entry = SHORTCUT_KIND_MAP[trimmed];
  if (!entry) return null;

  const [verb, artifact] = entry;
  let label = verb.replace(/-/g, " ");
  if (label) label = label[0].toUpperCase() + label.slice(1);
  if (artifact) label = `${label} ${artifact.replace(/-/g, " ")}`;
  return label;
}

// ---------------------------------------------------------------------------
// Enum parse helpers (mirrors parsers.py _parse_* functions)
// ---------------------------------------------------------------------------

const LIFECYCLE_MAP = {
  "Running": Lifecycle.Running,
  "Paused-Awaiting-Input": Lifecycle.PausedAwaitingInput,
  "Blocked": Lifecycle.Blocked,
  "Completed": Lifecycle.Completed,
  "Canceled": Lifecycle.Canceled,
};

const PHASE_MAP = {
  "Describe": Phase.Describe,
  "Define": Phase.Define,
  "Specify": Phase.Specify,
  "Plan": Phase.Plan,
  "Detail": Phase.Detail,
  "Execute": Phase.Execute,
};

const TASK_STATUS_MAP = {
  "Pending": TaskStatus.Pending,
  "In Progress": TaskStatus.InProgress,
  "In Review": TaskStatus.InReview,
  "Blocked": TaskStatus.Blocked,
  "Done": TaskStatus.Done,
  "Failed": TaskStatus.Failed,
  "Canceled": TaskStatus.Canceled,
};

function parseLifecycle(raw) {
  return LIFECYCLE_MAP[raw] || Lifecycle.Unknown;
}

function parsePhase(raw) {
  return PHASE_MAP[raw] || Phase.Unknown;
}

function parseTaskStatus(raw) {
  return TASK_STATUS_MAP[raw] || TaskStatus.Unknown;
}

// ---------------------------------------------------------------------------
// Locator (mirrors locator.py locate_aid_root / _enumerate_work_dirs)
// ---------------------------------------------------------------------------

function locateAidRoot(repoRoot) {
  const root = resolve(repoRoot);
  const aidDir = join(root, ".aid");

  const manifestPath = join(aidDir, ".aid-manifest.json");
  const settingsPath = join(aidDir, "settings.yml");
  const kbDir = join(aidDir, "knowledge");
  const heartbeatDir = join(aidDir, ".heartbeat");

  let aidExists = false;
  try {
    const st = statSync(aidDir);
    aidExists = st.isDirectory();
  } catch (_) {
    aidExists = false;
  }

  let workDirs = [];
  if (aidExists) {
    workDirs = enumerateWorkDirs(aidDir);
  }

  return {
    aidDir,
    aidExists,
    manifestPath,
    settingsPath,
    kbDir,
    workDirs,
    heartbeatDir,
  };
}

function enumerateWorkDirs(aidDir) {
  // Enumerate EVERY direct subfolder of the .aid/works/ container -- the
  // container is the discovery selector, so the folder name is no longer a
  // visibility filter (numberless works included). Mirrors locator.py
  // _enumerate_work_dirs.
  const worksDir = join(aidDir, "works");
  let entries;
  try {
    entries = readdirSync(worksDir);
  } catch (_) {
    return [];
  }

  const result = [];
  for (const name of entries) {
    const fullPath = join(worksDir, name);
    try {
      if (statSync(fullPath).isDirectory()) {
        result.push(fullPath);
      }
    } catch (_) {
      // skip unreadable
    }
  }

  result.sort((a, b) => basename(a).localeCompare(basename(b)));
  return result;
}

function statPath(p) {
  try {
    const st = statSync(p);
    if (st.isFile()) return st.size;
    return null;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Level-0: ToolInfo from .aid-manifest.json (mirrors parsers.py parse_tool_info)
// ---------------------------------------------------------------------------

function parseToolInfo(manifestPath) {
  let bytesRead = 0;

  if (existsSync(manifestPath)) {
    let raw;
    try {
      raw = readFileBounded(manifestPath);
      bytesRead += raw.length;
    } catch (_) {
      return [
        { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
        bytesRead,
      ];
    }
    let data;
    try {
      data = JSON.parse(raw.toString("utf-8"));
    } catch (_) {
      return [
        { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
        bytesRead,
      ];
    }

    const aidVersion = data.aid_version != null ? String(data.aid_version) : null;
    const installedAt = data.installed_at != null ? String(data.installed_at) : null;
    const toolsDict = typeof data.tools === "object" && data.tools !== null ? data.tools : {};
    const toolsInstalled = Object.keys(toolsDict);

    return [
      { manifest_present: true, aid_version: aidVersion, installed_at: installedAt, tools_installed: toolsInstalled },
      bytesRead,
    ];
  }

  // No manifest. (The retired .aid/.aid-version marker is no longer consulted;
  // a tool-less project records its AID version in settings.yml, surfaced by the
  // home-grid reader.)
  return [
    { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
    bytesRead,
  ];
}

// ---------------------------------------------------------------------------
// Level-1: RepoInfo helpers (mirrors parsers.py parse_project_name / parse_kb_state)
// ---------------------------------------------------------------------------

// PF-6: strip inline YAML comment from a scalar value.
// Drops everything from the first '#' that is NOT inside a quoted string.
function stripYamlInlineComment(scalar) {
  const s = scalar;
  if (s && (s[0] === '"' || s[0] === "'")) {
    const quote = s[0];
    const end = s.indexOf(quote, 1);
    if (end !== -1) {
      const after = s.slice(end + 1).trimStart();
      if (after.startsWith("#")) {
        return s.slice(0, end + 1);
      }
    }
    return s;
  }
  // Unquoted: first '#' is the comment
  const idx = s.indexOf("#");
  if (idx !== -1) {
    return s.slice(0, idx);
  }
  return s;
}

// parseTopLevelScalar: reads a column-0 `key: value` scalar (the flat settings
// schema where name/description/type/minimum_grade live at the top level).
// Returns the value, or null if absent / empty / an inline list. Twin of
// parsers.py _parse_toplevel_scalar().
function parseTopLevelScalar(text, key) {
  const re = new RegExp("^" + key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + ":\\s*(.*)$");
  for (const line of text.split("\n")) {
    const m = line.match(re);
    if (m) {
      const val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
      if (val.startsWith("[") && val.endsWith("]")) return null;
      return val || null;
    }
  }
  return null;
}

// parseProjectSettings: extracts project.name + project.description from
// .aid/settings.yml. Both scalars live in the SAME 'project:' block, so this
// is one shared line-scan (feature-002, work-017 task-005). Returns
// [name, description, bytesRead]; on any failure ["", null, 0].
// Twin of parsers.py parse_project_settings().
function parseProjectSettings(settingsPath) {
  if (!existsSync(settingsPath)) return ["", null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return ["", null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inProject = false;
  let name = null;
  let description = null;
  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "project:" || stripped.startsWith("project: ")) {
      inProject = true;
      continue;
    }
    if (inProject) {
      if (line.length > 0 && !/^\s/.test(line) && !line.startsWith("#") && line.includes(":")) {
        const key = line.split(":")[0].trim();
        if (key !== "name" && key !== "description") {
          if (!/^\s/.test(line)) break;
        }
      }
      let m = line.match(/^\s+name:\s+(.+)/);
      if (m && name === null) {
        // PF-6: strip inline YAML comment
        name = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        continue;
      }
      m = line.match(/^\s+description:\s+(.+)/);
      if (m && description === null) {
        description = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        continue;
      }
    }
  }
  // Flat-schema fallback: name/description at the top level (project: wrapper
  // removed). Legacy projects have them nested (found above).
  if (name === null) name = parseTopLevelScalar(text, "name");
  if (description === null) description = parseTopLevelScalar(text, "description");
  return [name !== null ? name : "", description, bytesRead];
}

// parseProjectName: thin wrapper over parseProjectSettings (kept for existing
// callers that only need the name). Twin of parsers.py parse_project_name().
function parseProjectName(settingsPath) {
  const [name, , bytesRead] = parseProjectSettings(settingsPath);
  return [name, bytesRead];
}

// parseSettingsMinimumGrade: extracts the GLOBAL review.minimum_grade from
// .aid/settings.yml. Its own 'review:'-section line-scan -- structurally
// SEPARATE from the 'project:' block (a real settings.yml has 'tools:'
// between 'project:' and 'review:', so parseProjectSettings's
// break-on-next-top-level-key logic cannot reach 'review:'). Returns
// [grade, bytesRead]; absent/unreadable -> [null, bytesRead or 0]. Read
// literally as a display scalar -- no resolution. Twin of parsers.py
// parse_minimum_grade() -- named parseSettingsMinimumGrade (not
// parseMinimumGrade) in this flat file only to avoid colliding with the
// pre-existing per-work parseMinimumGrade(text) below (twin of
// derivation.py's _parse_minimum_grade, a STATE.yml-text scan -- Python
// keeps the two apart via module namespacing + the underscore prefix;
// this single-file Node twin needs a distinct name instead).
function parseSettingsMinimumGrade(settingsPath) {
  if (!existsSync(settingsPath)) return [null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let inReview = false;
  let grade = null;
  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === "review:" || stripped.startsWith("review: ")) {
      inReview = true;
      continue;
    }
    if (inReview) {
      if (line.length > 0 && !/^\s/.test(line) && !line.startsWith("#") && line.includes(":")) {
        const key = line.split(":")[0].trim();
        if (key !== "minimum_grade") {
          if (!/^\s/.test(line)) break;
        }
      }
      const m = line.match(/^\s+minimum_grade:\s+(.+)/);
      if (m && grade === null) {
        const val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) grade = val;
        continue;
      }
    }
  }
  // Flat-schema fallback: top-level minimum_grade (review: wrapper removed).
  if (grade === null) grade = parseTopLevelScalar(text, "minimum_grade");
  return [grade, bytesRead];
}

// ---------------------------------------------------------------------------
// task-064: parseKbBaseline -- tolerant line-scan of settings.yml KB baseline
// Twin of dashboard/reader/parsers.py parse_kb_baseline (byte-parity minded, DM-A4)
// ---------------------------------------------------------------------------

function scanBlockPair(text, blockKey, key1, key2) {
  // Tolerant line-scan for a top-level `blockKey` (e.g. 'knowledge:') block,
  // extracting the `key1` and `key2` scalar values found inside it.
  // Returns [key1Value, key2Value, blockFound].
  let inBlock = false;
  let found = false;
  let val1 = null;
  let val2 = null;
  const key1Re = new RegExp("^\\s+" + key1.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\s+(.+)");
  const key2Re = new RegExp("^\\s+" + key2.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\s+(.+)");

  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (stripped === blockKey || stripped.startsWith(blockKey + " ")) {
      inBlock = true;
      found = true;
      continue;
    }
    if (inBlock) {
      // Another top-level key (no leading whitespace) ends the block
      if (line.length > 0 && !/^\s/.test(line) && line.includes(":") && !stripped.startsWith("#")) {
        break;
      }
      let m = line.match(key1Re);
      if (m && val1 === null) {
        let val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) val1 = val;
        continue;
      }
      m = line.match(key2Re);
      if (m && val2 === null) {
        let val = stripYamlInlineComment(m[1]).trim().replace(/^"|"$/g, "").replace(/^'|'$/g, "");
        if (val) val2 = val;
        continue;
      }
    }
  }

  return [val1, val2, found];
}

function parseKbBaseline(settingsPath) {
  // Returns [{branch, tip_date}|null, bytesRead]
  // Tolerant line-scan of the 'knowledge:' nested block in .aid/settings.yml
  // ('source:' -> branch, 'last_update:' -> tip_date), falling back to the
  // legacy 'kb_baseline:' block ('branch:' / 'tip_date:') when 'knowledge:'
  // is absent. Absent/unparseable -> null (skip freshness, stay approved; FF-A2).
  if (!existsSync(settingsPath)) return [null, 0];
  let raw;
  try {
    raw = readFileBounded(settingsPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  let [branch, tipDate, knowledgeFound] = scanBlockPair(text, "knowledge:", "source:", "last_update:");
  if (!knowledgeFound) {
    [branch, tipDate] = scanBlockPair(text, "kb_baseline:", "branch:", "tip_date:");
  }

  if (branch === null && tipDate === null) return [null, bytesRead];
  return [{ branch: branch, tip_date: tipDate }, bytesRead];
}

function parseKbSummaryApproval(text, fm) {
  // Frontmatter-first (task-002): summary_approved/last_summary scalars.
  // Twin of Python _parse_kb_summary_approval(). Returns
  // [approved, date, sourceMode].
  if (fm) {
    const fmApproved = fm.summary_approved;
    if (fmApproved !== undefined) {
      const approved = !!parseBoolYesno(fmApproved);
      const fmLast = fm.last_summary;
      let date = null;
      if (fmLast !== undefined && !isNull(fmLast)) {
        date = fmLast.trim();
      }
      return [approved, date, SourceMode.Normalized];
    }
  }

  // Legacy-prose fallback (UNCHANGED behavior): '## Knowledge Summary Status'
  // bold line (not a table row -- see parsers.py's _parse_kb_summary_approval
  // docstring for why this remains the real legacy-compat path).
  let inSummaryStatus = false;
  for (const line of text.split("\n")) {
    if (/^##\s+Knowledge Summary Status/.test(line)) {
      inSummaryStatus = true;
      continue;
    }
    if (inSummaryStatus) {
      if (/^##\s+/.test(line)) break;
      const m = line.trim().match(/^\*\*User Approved:\*\*\s+(.+)/);
      if (m) {
        const val = m[1].trim();
        const approved = val.toLowerCase().startsWith("yes");
        const dateM = val.match(/\((\d{4}-\d{2}-\d{2})/);
        const date = dateM ? dateM[1] : null;
        return [approved, date, SourceMode.Fallback];
      }
    }
  }
  return [false, null, SourceMode.Fallback];
}

function parseKbDocCount(text) {
  let inCompleteness = false;
  let count = 0;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (/^##\s+Completeness/.test(line)) {
      inCompleteness = true;
      headerSeen = false;
      count = 0;
      continue;
    }
    if (inCompleteness) {
      if (/^##\s+/.test(line)) break;
      if (!line.trim().startsWith("|")) continue;
      if (line.includes("---")) {
        headerSeen = true;
        continue;
      }
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const cols = line.trim().replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length >= 2 && cols[0]) {
        count++;
      }
    }
  }
  return inCompleteness ? count : null;
}

function parseKbState(kbDir) {
  // summary_present is stat'd from kbDir/kb.html: the generated KB summary now
  // lives beside its KB source in .aid/knowledge/ (the .aid/dashboard/ folder was
  // eliminated -- home.html is served by the CLI, kb.html moved here). (task-064)
  let isDir = false;
  try {
    isDir = statSync(kbDir).isDirectory();
  } catch (_) {
    isDir = false;
  }
  if (!isDir) return [null, 0];

  let bytesRead = 0;
  let summaryApproved = false;
  let lastSummaryDate = null;
  let docCount = null;
  let sourceMode = SourceMode.Fallback;
  let kbStatusVal = null;
  let kbGradeVal = null;
  let lastKbReviewVal = null;

  const statePath = join(kbDir, "STATE.md");
  if (existsSync(statePath)) {
    let raw;
    try {
      raw = readFileBounded(statePath);
      bytesRead += raw.length;
      const stateText = raw.toString("utf-8");
      // .aid/knowledge/STATE.md is OUT OF SCOPE for this work (SPEC.md D-6):
      // it stays markdown-with-frontmatter. This is the ONE caller in this
      // file that opts INTO the legacy fenced-frontmatter scan
      // (allowFrontmatterFence: true) -- every state-file reader leaves it
      // at the strict default. Dispatch on the CALLER, not on the document's
      // own leading bytes (see parseStateDocument's docstring).
      const [fm, _kbFmWarnings] = parseStateDocument(stateText, {
        fileLabel: "knowledge/STATE.md",
        allowFrontmatterFence: true,
      });
      [summaryApproved, lastSummaryDate, sourceMode] = parseKbSummaryApproval(stateText, fm);

      // Newly-captured discovery-status scalars (task-002): frontmatter-first,
      // legacy header-blockquote fallback.
      let v = fm["kb_status"];
      if (v !== undefined && !isNull(v)) {
        kbStatusVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Status");
        if (legacy !== null && !isNull(legacy)) kbStatusVal = legacy;
      }

      v = fm["kb_grade"];
      if (v !== undefined && !isNull(v)) {
        kbGradeVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Current Grade");
        if (legacy !== null && !isNull(legacy)) kbGradeVal = legacy;
      }

      v = fm["last_kb_review"];
      if (v !== undefined && !isNull(v)) {
        lastKbReviewVal = v.trim();
      } else {
        const legacy = parseHeaderBoldField(stateText, "Last KB Review");
        if (legacy !== null && !isNull(legacy)) lastKbReviewVal = legacy;
      }
    } catch (_) {
      // ignore
    }
  }

  const readmePath = join(kbDir, "README.md");
  if (existsSync(readmePath)) {
    let raw;
    try {
      raw = readFileBounded(readmePath);
      bytesRead += raw.length;
      const readmeText = raw.toString("utf-8");
      docCount = parseKbDocCount(readmeText);
    } catch (_) {
      // ignore
    }
  }

  // task-064: stat kbDir/kb.html for summary_present (kb.html now lives beside its
  // KB source in .aid/knowledge/, not in the eliminated .aid/dashboard/ folder).
  let summaryPresent = false;
  const kbHtmlPath = join(kbDir, "kb.html");
  try {
    summaryPresent = statSync(kbHtmlPath).isFile();
  } catch (_) {
    summaryPresent = false;
  }

  return [
    {
      summary_approved: summaryApproved,
      last_summary_date: lastSummaryDate,
      doc_count: docCount,
      summary_present: summaryPresent,
      // status and kb_baseline set by readRepo after derivation
      status: KbStatus.unknown,
      kb_baseline: null,
      source_mode: sourceMode,
      kb_status: kbStatusVal,
      kb_grade: kbGradeVal,
      last_kb_review: lastKbReviewVal,
    },
    bytesRead,
  ];
}

// ---------------------------------------------------------------------------
// task-064: UTC-instant normalization helper (R12, FF-A2 step 4)
// Twin of derivation.py _normalize_to_utc_ms (byte-parity minded)
// ---------------------------------------------------------------------------

function normalizeToUtcMs(isoStr) {
  // Parse ISO-8601 string and return UTC milliseconds since epoch.
  // Handles Z-suffix and +/-HH:MM offset forms. Returns null if unparseable.
  // Node: Date.parse() / getTime() -- same UTC epoch for same ISO-8601 input as Python.
  if (!isoStr) return null;
  const ms = Date.parse(isoStr);
  if (isNaN(ms)) return null;
  return ms;
}

// ---------------------------------------------------------------------------
// task-064: FF-A2 git freshness check (read-only bounded subprocess)
// Twin of derivation.py git_freshness_check / _resolve_git_branch / _run_git_log
// ---------------------------------------------------------------------------

const GIT_TIMEOUT_MS = 2000; // 2s timeout (matches Python _GIT_TIMEOUT_S = 2)

function runGitCommand(args, cwd) {
  // Run git with the given args (no shell). Returns stdout string or null on failure.
  // cwd: working directory for the process (null -> use process.cwd()).
  //      When args include -C <path>, cwd is not needed (git changes into <path>).
  // Degradation: ENOENT (git absent), nonzero, timeout, OSError -> null.
  const opts = {
    timeout: GIT_TIMEOUT_MS,
    stdio: ["ignore", "pipe", "pipe"],
    encoding: "utf-8",
  };
  if (cwd !== null && cwd !== undefined) {
    opts.cwd = cwd;
  }
  try {
    const stdout = execFileSync("git", args, opts);
    return (stdout || "").trim() || null;
  } catch (_) {
    return null;
  }
}

function resolveGitBranch(repoRoot, kbBaseline) {
  // DD-A2 branch resolution: prefer baseline.branch, else origin/HEAD, else main/master.
  // Twin of Python derivation.py _resolve_git_branch.
  // Uses -C <repoRoot> to match Python's argv exactly (no shell, no cwd).
  if (kbBaseline && kbBaseline.branch) {
    return kbBaseline.branch;
  }
  // Try: git -C <repoRoot> symbolic-ref --short refs/remotes/origin/HEAD
  const ref = runGitCommand(
    ["-C", repoRoot, "symbolic-ref", "--short", "refs/remotes/origin/HEAD"],
    null  // cwd not needed when using -C
  );
  if (ref) {
    // basename: "origin/main" -> "main"
    return ref.includes("/") ? ref.split("/").pop() : ref;
  }
  // Fallback: first of {main, master} that exists
  // Try: git -C <repoRoot> rev-parse --verify refs/heads/<candidate>
  for (const candidate of ["main", "master"]) {
    const out = runGitCommand(
      ["-C", repoRoot, "rev-parse", "--verify", "refs/heads/" + candidate],
      null
    );
    if (out !== null) return candidate;
  }
  return null;
}

function runGitLog(repoRoot, branch) {
  // Run: git -C <repoRoot> log -1 --format=%cI --end-of-options <branch>
  // argv identical to Python twin (no shell).
  // Returns ISO-8601 date string or null on every failure.
  //
  // SECURITY (HIGH, v2.1.0): branch is read verbatim from an untrusted repo's
  // .aid/settings.yml (kb_baseline.branch). Without --end-of-options, a value
  // like "--output=/path/to/file" is parsed as a git OPTION (not a revision),
  // letting an attacker create/truncate an arbitrary file. --end-of-options
  // (git 2.24+) forces every argument after it to be treated as a revision,
  // never an option, closing the injection.
  return runGitCommand(
    ["-C", repoRoot, "log", "-1", "--format=%cI", "--end-of-options", branch],
    null
  );
}

// ---------------------------------------------------------------------------
// Security/perf hardening (v2.1.0, FIX-4 LOW): per-process freshness cache.
// Twin of derivation.py's git_freshness_check in-process cache (same rationale
// and TTL). See the Python module comment for the full correctness rationale:
// a cache keyed on .aid/knowledge/ mtime ALONE would be unsound (the "outdated"
// verdict tracks the default branch advancing, unrelated to kb_dir mtime), so
// a short TTL bounds staleness while the mtime key gives early invalidation
// when the KB folder itself changes.
// ---------------------------------------------------------------------------
const FRESHNESS_CACHE = new Map();
const FRESHNESS_CACHE_TTL_MS = 5000; // 5s (matches Python _FRESHNESS_CACHE_TTL_S)

function _freshnessCacheKey(repoRoot, kbBaseline) {
  const kbDir = join(repoRoot, ".aid", "knowledge");
  let mtimeMs = null;
  try {
    mtimeMs = statSync(kbDir).mtimeMs;
  } catch (_) {
    mtimeMs = null;
  }
  return [
    resolve(repoRoot),
    kbBaseline.branch || null,
    kbBaseline.tip_date || null,
    mtimeMs,
  ].join("|");
}

function gitFreshnessCheck(repoRoot, kbBaseline) {
  // FF-A2: Check if the default branch has advanced past kb_baseline.
  // Returns "approved" | "outdated" | "skip".
  // Every failure mode (DD-A2 7-mode degradation matrix) -> "skip" -> stay approved.
  // Twin of Python derivation.py git_freshness_check.
  //
  // FIX-4 (LOW, v2.1.0): result is cached in-process for FRESHNESS_CACHE_TTL_MS,
  // keyed on (repoRoot, branch, baseline, kb_dir mtime).

  // Degradation mode 6: kb_baseline absent
  if (!kbBaseline) return "skip";

  const cacheKey = _freshnessCacheKey(repoRoot, kbBaseline);
  const now = Date.now();
  const cached = FRESHNESS_CACHE.get(cacheKey);
  if (cached && (now - cached.at) <= FRESHNESS_CACHE_TTL_MS) {
    return cached.result;
  }

  const branch = resolveGitBranch(repoRoot, kbBaseline);
  let result;
  if (branch === null) {
    result = "skip";
  } else {
    // Run: git -C <repoRoot> log -1 --format=%cI --end-of-options <branch> (via
    // runGitLog; twin of Python git_freshness_check -> _run_git_log). Any
    // failure -> null -> skip.
    const currentTipStr = runGitLog(repoRoot, branch);
    if (!currentTipStr) {
      result = "skip";
    } else {
      // UTC normalization before compare (R12, never raw string compare)
      const currentMs = normalizeToUtcMs(currentTipStr);
      const baselineMs = normalizeToUtcMs(kbBaseline.tip_date || "");
      if (currentMs === null || baselineMs === null) {
        result = "skip";
      } else {
        result = currentMs > baselineMs ? "outdated" : "approved";
      }
    }
  }

  FRESHNESS_CACHE.set(cacheKey, { result, at: now });
  return result;
}

// ---------------------------------------------------------------------------
// task-064: FF-A3 KB 5-state status waterfall (feature-007 DM-A2)
// Twin of derivation.py derive_kb_status (byte-parity minded)
// ---------------------------------------------------------------------------

function deriveKbStatus(kbDir, summaryApproved, summaryPresent, kbBaseline, repoRoot) {
  // Waterfall (outermost-first, DD-A3):
  //   1. .aid/knowledge/ absent or empty                           -> pending
  //   2. KB present but not yet User Approved: yes                 -> generating
  //      (SPEC residual-#1 safe default -- applied verbatim)
  //   3. KB approved but kb.html absent OR summary not V1-approved -> preparing
  //   4. freshness_check == "outdated"                             -> outdated
  //   5. else                                                      -> approved
  // Never throws (NFR7).
  try {
    // Step 1: .aid/knowledge/ absent or empty -> pending
    let isDir = false;
    try { isDir = statSync(kbDir).isDirectory(); } catch (_) { isDir = false; }
    if (!isDir) return KbStatus.pending;
    let entries = [];
    try { entries = readdirSync(kbDir); } catch (_) { entries = []; }
    if (entries.length === 0) return KbStatus.pending;

    // Step 2: KB present but not yet User Approved: yes -> generating
    if (!summaryApproved) return KbStatus.generating;

    // Step 3: KB approved but kb.html absent OR summary not V1-approved -> preparing
    if (!summaryPresent) return KbStatus.preparing;

    // Step 4+5: freshness check (last, only over approved)
    const freshness = gitFreshnessCheck(repoRoot, kbBaseline);
    if (freshness === "outdated") return KbStatus.outdated;

    return KbStatus.approved;
  } catch (_) {
    return KbStatus.unknown;
  }
}

// ---------------------------------------------------------------------------
// f007 / task-042: per-doc freshness (byte-parity twin of derivation.py)
// ---------------------------------------------------------------------------

const RE_FM_FENCE = /^---\s*$/;
const RE_URL_SOURCE = /^[a-z][a-z0-9+.\-]*:\/\//;

function isUrlSource(entry) {
  // Twin of Python parsers.is_url_source() and kb-freshness-check.sh is_url().
  return RE_URL_SOURCE.test(entry);
}

function parseDocFrontmatter(docPath) {
  // Tolerant sources:/approved_at_commit: frontmatter scan for one KB doc.
  // Twin of Python parsers.parse_doc_frontmatter().
  //
  // Returns [approvedAtCommit, sourcesList, sourcesFieldPresent].
  //   approvedAtCommit:      string or null
  //   sourcesList:           string[] (items from sources: list)
  //   sourcesFieldPresent:   boolean (true even if sources: [])
  //
  // Never throws. Handles inline list [a,b] + block list (- a\n  - b).

  let approvedAtCommit = null;
  const sourcesList = [];
  let sourcesFieldPresent = false;

  let raw;
  try {
    raw = readFileBounded(docPath).toString("utf-8");
  } catch (_) {
    return [null, [], false];
  }

  const lines = raw.split("\n");
  let inFm = false;
  let fmEntered = false;
  let inSourcesBlock = false;

  for (const line of lines) {
    const stripped = line.replace(/\r$/, "");
    if (RE_FM_FENCE.test(stripped)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break;
      }
    }
    if (!inFm) {
      break;
    }

    if (inSourcesBlock) {
      // Block-list item: leading whitespace + '-'
      const mItem = /^[ \t]+-[ \t]*(.*)/.exec(stripped);
      if (mItem) {
        const item = mItem[1].trim().replace(/^['"]|['"]$/g, "");
        if (item) sourcesList.push(item);
        continue;
      } else {
        inSourcesBlock = false;
        // fall through to check this line for other fields
      }
    }

    // approved_at_commit: scalar
    const mAac = /^approved_at_commit:\s*(.*)/.exec(stripped);
    if (mAac) {
      const val = mAac[1].trim().replace(/^['"]|['"]$/g, "");
      approvedAtCommit = val || null;
      continue;
    }

    // sources: field
    const mSrc = /^sources:\s*(.*)/.exec(stripped);
    if (mSrc) {
      sourcesFieldPresent = true;
      const rest = mSrc[1].trim();
      if (rest === "[]") {
        // Explicit empty inline list: sources: []
        // sourcesFieldPresent already set; list stays empty
        continue;
      }
      if (!rest) {
        // Bare 'sources:' with nothing after -- block list follows
        inSourcesBlock = true;
        continue;
      }
      if (rest.startsWith("[")) {
        // Inline list: [a, b, c]
        const inner = rest.replace(/^\[/, "").replace(/\].*$/, "").trim();
        if (inner) {
          for (const item of inner.split(",")) {
            const s = item.trim().replace(/^['"]|['"]$/g, "");
            if (s) sourcesList.push(s);
          }
        }
        continue;
      }
      // Block list -- following indented lines are items
      inSourcesBlock = true;
      continue;
    }
  }

  return [approvedAtCommit, sourcesList, sourcesFieldPresent];
}

// ---------------------------------------------------------------------------
// feature-007-connectors-list (work-017 task-019): connectors registry parser
// (byte-parity twin of Python parsers.parse_connectors()).
// ---------------------------------------------------------------------------

// The six connector-descriptor frontmatter scalars (feature-001's frozen
// schema) -- the SAME fields build-connectors-index.sh's ef() and
// connector-registry.sh's read_field address.
const CONNECTOR_FM_FIELDS = [
  "name", "connection_type", "endpoint", "auth_method", "secret_reference", "summary",
];

function _parseConnectorFrontmatterScalars(text) {
  // Extract the six connector-descriptor frontmatter scalars from the FIRST
  // frontmatter block only. Twin of Python
  // parsers._parse_connector_frontmatter_scalars().
  //
  // Same semantics as connector-registry.sh's read_field() / build-connectors-
  // index.sh's ef(): a single-line 'field: value' scalar, with ONE pair of
  // surrounding quotes stripped, first occurrence wins. A body-level
  // thematic-break '---' is never re-entered as frontmatter -- the scan stops
  // the instant the frontmatter block closes.
  //
  // Returns a plain object keyed by field name; a field absent from the
  // frontmatter (or a wholly frontmatter-less file) is simply absent from the
  // returned object. Never throws.
  const result = {};
  let inFm = false;
  let fmEntered = false;

  const lines = text.split("\n");
  for (const rawLine of lines) {
    const line = rawLine.replace(/\r$/, "");
    if (RE_FM_FENCE.test(line)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        // Closing fence -- stop scanning entirely (never re-enter
        // frontmatter for a body-level thematic break).
        break;
      }
    }
    if (!inFm) {
      break;
    }

    for (const fld of CONNECTOR_FM_FIELDS) {
      if (Object.prototype.hasOwnProperty.call(result, fld)) continue; // first occurrence wins
      const prefix = fld + ":";
      if (line.startsWith(prefix)) {
        let val = line.slice(prefix.length).trim();
        if (val.length >= 1 && (val[0] === '"' || val[0] === "'")) {
          val = val.slice(1);
        }
        if (val.length >= 1 && (val[val.length - 1] === '"' || val[val.length - 1] === "'")) {
          val = val.slice(0, -1);
        }
        result[fld] = val;
      }
    }
  }

  return result;
}

export function parseConnectors(connectorsDir) {
  // Enumerate <aid_dir>/connectors/*.md into a stem-sorted array of
  // ConnectorRef-shaped plain objects. Twin of Python parsers.parse_connectors().
  //
  // Uses the EXACT filter connector-registry.sh's `list` op uses
  // (connector-registry.sh lines 151-154): `*.md` files directly under
  // connectorsDir, excluding `INDEX.md` and dotfiles, sorted by stem. A
  // missing connectorsDir -> [] (non-error; mirrors the script's own
  // missing-root behavior).
  //
  // Returns [refs, bytesRead]. Never throws.
  let isDir = false;
  try {
    isDir = statSync(connectorsDir).isDirectory();
  } catch (_) {
    isDir = false;
  }
  if (!isDir) return [[], 0];

  let entries = [];
  try {
    entries = readdirSync(connectorsDir);
  } catch (_) {
    return [[], 0];
  }

  const candidates = entries
    .filter((name) => name.endsWith(".md") && name !== "INDEX.md" && !name.startsWith("."))
    .filter((name) => {
      try {
        return statSync(join(connectorsDir, name)).isFile();
      } catch (_) {
        return false;
      }
    });

  const stemOf = (name) => name.slice(0, -3); // strip trailing ".md"
  candidates.sort((a, b) => {
    const sa = stemOf(a);
    const sb = stemOf(b);
    return sa < sb ? -1 : sa > sb ? 1 : 0;
  });

  let bytesRead = 0;
  const refs = [];
  for (const name of candidates) {
    const stem = stemOf(name);
    const path = join(connectorsDir, name);
    let text = "";
    try {
      const raw = readFileBounded(path);
      bytesRead += raw.length;
      text = raw.toString("utf-8");
    } catch (_) {
      text = "";
    }

    const fm = _parseConnectorFrontmatterScalars(text);
    const name_ = fm.name || stem;
    const connectionType = fm.connection_type !== undefined ? fm.connection_type : "";
    const endpoint = fm.endpoint || null;
    const authMethod = fm.auth_method || null;
    const secretReference = fm.secret_reference || null;
    const summary = fm.summary || null;

    refs.push({
      stem,
      name: name_,
      connection_type: connectionType,
      endpoint,
      auth_method: authMethod,
      secret_reference: secretReference,
      summary,
    });
  }

  return [refs, bytesRead];
}

// ---------------------------------------------------------------------------
// feature-010-external-sources-list (work-017 task-021): external-sources
// registry wrapper (byte-parity twin of Python parsers.parse_external_sources()).
// NO new frontmatter parser -- a thin wrapper over the existing
// parseDocFrontmatter().
// ---------------------------------------------------------------------------

export function parseExternalSources(kbDir) {
  // Twin of Python parsers.parse_external_sources(). Returns the deduped,
  // order-preserved sources: entries of <kbDir>/external-sources.md, with the
  // discovery placeholder "(none)" filtered out. Absent/frontmatter-less file
  // -> parseDocFrontmatter already returns [] for sourcesList -> [].
  //
  // Reader-parity note (feature-010 SPEC): parseDocFrontmatter's block-list
  // continuation only matches CONTIGUOUS leading-whitespace '-' item lines --
  // a comment or blank line between sources: and its items ends the block
  // (and it does not strip a trailing inline '# comment' from a block item).
  // The write-external-source.sh writer (task-020) normalizes the block to
  // contiguous '  - <item>' lines directly under sources:, with no inline
  // comment, so every dashboard-managed entry is reader-visible here (AC2).
  const [, sourcesList] = parseDocFrontmatter(join(kbDir, "external-sources.md"));
  const seen = new Set();
  const result = [];
  for (const item of sourcesList) {
    if (item === "(none)") continue;
    if (seen.has(item)) continue;
    seen.add(item);
    result.push(item);
  }
  return result;
}

function _readRoutingFields(docPath) {
  // Read kb-category and source frontmatter scalars for doc routing.
  // Returns [kbCategory, sourceField]. Absent fields return "".
  // Twin of Python derivation._read_routing_fields().
  // Never throws.

  let raw;
  try {
    raw = readFileBounded(docPath).toString("utf-8");
  } catch (_) {
    return ["", ""];
  }

  const lines = raw.split("\n");
  let inFm = false;
  let fmEntered = false;
  let kbCat = "";
  let srcField = "";

  for (const line of lines) {
    const stripped = line.replace(/\r$/, "");
    if (RE_FM_FENCE.test(stripped)) {
      if (!fmEntered) {
        inFm = true;
        fmEntered = true;
        continue;
      } else {
        break;
      }
    }
    if (!inFm) break;

    const mCat = /^kb-category:\s*(.*)/.exec(stripped);
    if (mCat) {
      kbCat = mCat[1].trim().replace(/^['"]|['"]$/g, "");
      continue;
    }
    const mSrc = /^source:\s*(.*)/.exec(stripped);
    if (mSrc) {
      srcField = mSrc[1].trim().replace(/^['"]|['"]$/g, "");
      continue;
    }
  }

  return [kbCat, srcField];
}

function _runMergeBaseIsAncestor(repoRoot, cSrc, baseline) {
  // Returns "current" | "suspect" | "unknown".
  // execFileSync throws on non-zero exit; status 1 = NOT ancestor = suspect.
  // Any other error (128 bad object, ENOENT, timeout) = unknown.
  //
  // SECURITY (LOW, v2.1.0): baseline is frontmatter-derived (approved_at_commit:)
  // and cSrc comes from a prior git-log lookup; neither is fully trusted input.
  // --end-of-options (git 2.24+) guards both trailing commit-ish arguments from
  // being parsed as options (same rationale as runGitLog's --end-of-options).
  try {
    execFileSync(
      "git",
      ["-C", repoRoot, "merge-base", "--is-ancestor", "--end-of-options", cSrc, baseline],
      {
        timeout: GIT_TIMEOUT_MS,
        stdio: ["ignore", "pipe", "pipe"],
        encoding: "utf-8",
      }
    );
    // exit 0 = ancestor/equal = current
    return "current";
  } catch (err) {
    // execFileSync throws with err.status for non-zero exit
    if (err && err.status === 1) {
      // exit 1 = NOT ancestor = source changed after baseline
      return "suspect";
    }
    // exit 128 (bad object), ENOENT (git absent), timeout, etc. -> unknown
    return "unknown";
  }
}

const SKIP_NAMES = new Set(["INDEX.md", "README.md", "STATE.md"]);

function deriveDocFreshness(kbDir, repoRoot) {
  // f007: Per-doc freshness read for all hand-authored primary/extension KB docs.
  // Twin of Python derivation.derive_doc_freshness().
  //
  // Same algorithm as kb-freshness-check.sh (task-040):
  //   - Same doc routing (skip INDEX.md, README.md, STATE.md, meta, generated)
  //   - Same absence gate (no approved_at_commit: -> unknown; no/empty sources: -> current)
  //   - Same git verbs: git log -1 --format=%H -- <src> + merge-base --is-ancestor
  //   - Same fold rule: suspect > current > unknown
  //   - Same degrade-to-unknown matrix (any git failure -> unknown, never false suspect)
  //
  // Returns array of {doc, verdict, suspect_sources} sorted by doc path.
  // Never throws. No writes.

  const results = [];

  let isDir = false;
  try { isDir = statSync(kbDir).isDirectory(); } catch (_) { isDir = false; }
  if (!isDir) return results;

  let entries = [];
  try { entries = readdirSync(kbDir); } catch (_) { return results; }

  // Sort deterministically (same as Python sorted() + bash sort)
  const mdFiles = entries
    .filter(n => n.endsWith(".md") && !n.startsWith("."))
    .sort();

  for (const name of mdFiles) {
    if (SKIP_NAMES.has(name)) continue;

    const docPath = join(kbDir, name);

    // Check routing fields: kb-category and source
    const [kbCat, srcField] = _readRoutingFields(docPath);
    if (kbCat === "meta") continue;
    if (srcField === "generated") continue;
    // Only primary and extension with hand-authored (or absent) source
    if (kbCat !== "primary" && kbCat !== "extension" && kbCat !== "") continue;

    const rel = name;

    // Parse frontmatter: approved_at_commit + sources
    const [approvedAtCommit, sourcesList, sourcesFieldPresent] =
      parseDocFrontmatter(docPath);

    // Absence gate: missing/empty approved_at_commit -> unknown (never suspect)
    if (!approvedAtCommit) {
      results.push({ doc: rel, verdict: "unknown", suspect_sources: [] });
      continue;
    }

    // sources: absent or empty -> current (nothing to drift against)
    if (!sourcesFieldPresent || sourcesList.length === 0) {
      results.push({ doc: rel, verdict: "current", suspect_sources: [] });
      continue;
    }

    // Per-source staleness checks
    let nCurrent = 0;
    let nSuspect = 0;
    let nUnknown = 0;
    const suspectSources = [];

    for (const entry of sourcesList) {
      const srcVerdict = _checkSourceNode(entry, approvedAtCommit, repoRoot);
      if (srcVerdict === "current") {
        nCurrent++;
      } else if (srcVerdict === "suspect") {
        nSuspect++;
        suspectSources.push(entry);
      } else {
        nUnknown++;
      }
    }

    // Fold rule (identical to script and Python twin)
    let verdict;
    if (nSuspect > 0) {
      verdict = "suspect";
    } else if (nCurrent > 0) {
      verdict = "current";
    } else {
      verdict = "unknown";
    }

    results.push({ doc: rel, verdict, suspect_sources: suspectSources });
  }

  return results;
}

function _checkSourceNode(entry, approvedAtCommit, repoRoot) {
  // Node implementation of check_source (twin of Python _check_source).
  // Returns "current" | "suspect" | "unknown".

  if (isUrlSource(entry)) return "unknown";

  // Get last-changed commit for this path/glob
  const cSrc = runGitCommand(
    ["-C", repoRoot, "log", "-1", "--format=%H", "--", entry],
    null
  );
  if (!cSrc) return "unknown";

  // merge-base --is-ancestor: exit 0 = current, exit 1 = suspect, other = unknown
  return _runMergeBaseIsAncestor(repoRoot, cSrc, approvedAtCommit);
}

// ---------------------------------------------------------------------------
// Derivation helpers (mirrors derivation.py)
// ---------------------------------------------------------------------------

const RE_HISTORY_SECTION = /^##\s+Lifecycle History\s*$/i;
const RE_TABLE_SEP = /^\|[\s\-|]+\|$/;
const CANCEL_RE = /cancel(?:ed)?/i;

function hasCancellationInHistory(text, warnings, workId) {
  let inHistory = false;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (RE_HISTORY_SECTION.test(line)) {
      inHistory = true;
      headerSeen = false;
      continue;
    }
    if (inHistory) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      // Phase Transition / Gate is column index 1
      const gateCol = cols.length > 1 ? cols[1].trim() : "";
      if (CANCEL_RE.test(gateCol)) {
        return true;
      }
      // Check all columns for ambiguous mentions
      if (cols.some(c => CANCEL_RE.test(c))) {
        const prefix = workId ? workId + ": " : "";
        warnings.push(
          prefix + "## Lifecycle History row mentions cancellation outside " +
          "Gate column (ambiguous); check manually: " + stripped
        );
      }
    }
  }
  return false;
}

const RE_DEPLOY_STATUS = /^##\s+Deploy Status\s*$/i;
const RE_PLAN_DELIVERIES = /^##\s+Plan\s*\/\s*Deliveries\s*$/i;
const SHIPPED_RE = /\b(shipped|deployed|done|complete[d]?)\b/i;
const DELIVERY_DONE_RE = /^done$/i;

function deployStatusShipped(text) {
  let inDeploy = false;
  let headerSeen = false;

  for (const line of text.split("\n")) {
    if (RE_DEPLOY_STATUS.test(line)) {
      inDeploy = true;
      headerSeen = false;
      continue;
    }
    if (inDeploy) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const statusCol = cols.length > 1 ? cols[1].trim() : "";
      if (SHIPPED_RE.test(statusCol)) return true;
    }
  }
  return false;
}

function allDeliveriesDone(text) {
  let inPlan = false;
  let headerSeen = false;
  let rowCount = 0;
  let allDone = true;

  for (const line of text.split("\n")) {
    if (RE_PLAN_DELIVERIES.test(line)) {
      inPlan = true;
      headerSeen = false;
      rowCount = 0;
      allDone = true;
      continue;
    }
    if (inPlan) {
      if (/^##\s+/.test(line)) break;
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) continue;
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      if (cols.some(c => c.includes("_none yet_"))) continue;
      const statusCol = cols.length > 1 ? cols[1].trim() : "";
      if (!statusCol) continue;
      rowCount++;
      if (!DELIVERY_DONE_RE.test(statusCol)) {
        allDone = false;
      }
    }
  }
  return inPlan && rowCount > 0 && allDone;
}

function hasOpenTask(tasks) {
  return tasks.some(t => t.status === TaskStatus.InProgress || t.status === TaskStatus.InReview);
}

function isCompleted(text, tasks) {
  if (deployStatusShipped(text)) return true;
  if (allDeliveriesDone(text) && !hasOpenTask(tasks)) return true;
  return false;
}

const IMPEDIMENT_RE = /^IMPEDIMENT-task-\w+\.md$/i;
const RE_DELIVERY_GATES = /^##\s+Delivery Gates\s*$/i;
const RE_GRADE_LINE = /\*\*Grade:\*\*\s*(\S+)/i;
const RE_MINIMUM_GRADE_LINE = /\*\*Minimum Grade:\*\*\s*(\S+)/i;
const GRADE_ORDER = ["F", "D", "C", "B", "A"];

function gradeBelow(grade, minimum) {
  if (!GRADE_ORDER.includes(grade) || !GRADE_ORDER.includes(minimum)) return false;
  return GRADE_ORDER.indexOf(grade) < GRADE_ORDER.indexOf(minimum);
}

function parseMinimumGrade(text) {
  for (const line of text.split("\n")) {
    if (/^##\s+/.test(line)) break;
    const m = line.match(RE_MINIMUM_GRADE_LINE);
    if (m) return m[1].trim().toUpperCase();
  }
  return null;
}

function findSubminimumGate(text) {
  const minimumGrade = parseMinimumGrade(text);
  let inGates = false;
  let currentDelivery = null;

  for (const line of text.split("\n")) {
    if (RE_DELIVERY_GATES.test(line)) {
      inGates = true;
      currentDelivery = null;
      continue;
    }
    if (inGates) {
      if (/^##\s+/.test(line) && !/^###\s+/.test(line)) break;
      const hm = line.match(/^###\s+(\S+)/);
      if (hm) {
        currentDelivery = hm[1];
        continue;
      }
      if (currentDelivery) {
        const gm = line.match(RE_GRADE_LINE);
        if (gm) {
          const grade = gm[1].trim().toUpperCase();
          if (minimumGrade && gradeBelow(grade, minimumGrade)) {
            return currentDelivery;
          }
        }
      }
    }
  }
  return null;
}

function findImpedimentFile(workDir) {
  let entries;
  try {
    entries = readdirSync(workDir);
  } catch (_) {
    return null;
  }
  for (const name of entries) {
    if (IMPEDIMENT_RE.test(name)) {
      const fullPath = join(workDir, name);
      try {
        if (statSync(fullPath).isFile()) return fullPath;
      } catch (_) {
        // skip
      }
    }
  }
  return null;
}

function findBlockSignal(workDir, tasks, stateText) {
  // (a) IMPEDIMENT file
  const impedimentPath = findImpedimentFile(workDir);
  if (impedimentPath !== null) {
    const artifact = basename(impedimentPath);
    return [`IMPEDIMENT file present: ${artifact}`, artifact];
  }

  // (b) Failed task
  const failedTasks = tasks.filter(t => t.status === TaskStatus.Failed);
  if (failedTasks.length > 0) {
    const ids = failedTasks.map(t => t.task_id).join(", ");
    return [`Task(s) failed: ${ids}`, null];
  }

  // (c) Sub-minimum delivery gate
  const gateFail = findSubminimumGate(stateText);
  if (gateFail) {
    return [`Delivery gate below minimum: ${gateFail}`, gateFail];
  }

  return [null, null];
}

function deriveLifecycle({ workDir, tasks, pendingInputs, stateText, workId, latestHistoryDate }) {
  // LC-3 fallback derivation (mirrors derivation.py derive_lifecycle;
  // UNCHANGED aside from the `updated` slot, task-004 note below). Called
  // ONLY when the STATE.yml document carries no `lifecycle` key at all.
  //
  // The `updated` slot (6th return element) is `latestHistoryDate`, computed
  // ONCE by the caller (parseStateMd) via computeLatestHistoryDate() over
  // the already-parsed `lifecycle_history` array -- NOT re-derived per
  // branch. All five branches receive the SAME single value.
  //
  // BOTH TWINS DO THIS, and the symmetry is deliberate. derivation.py's
  // `derive_lifecycle` takes a `latest_history_date` parameter computed by
  // `parse_state_md` via `_compute_latest_history_date()` -- the same
  // max(lifecycle_history[].date) over the parsed sequence, skipping
  // non-string and `--` sentinel dates.
  //
  // It was NOT always so. task-004 landed this side first while
  // derivation.py still called `_extract_latest_history_date(state_text)`, a
  // raw "## Lifecycle History" markdown-table scan with no construct left to
  // match in a STATE.yml document -- dead code that returned None where this
  // side returned a real date. That asymmetry was the delivery's first
  // genuine twin divergence (known-issues.md KI-004): Python had also LOST a
  // fallback it had pre-refactor, which a behavior-preserving restructure
  // forbids. task-021 fixed the Python side toward this one and deleted the
  // dead scan. Worth recording because two independent cross-twin parity
  // harnesses both MISSED it -- the divergence needs three conditions at
  // once (no `lifecycle`, no `updated`, a populated `lifecycle_history`), and
  // any fixture carrying an explicit `updated:` masks it entirely.
  const warnings = [];

  // Prio 1: Canceled
  if (hasCancellationInHistory(stateText, warnings, workId)) {
    return [
      Lifecycle.Canceled, SourceMode.Fallback,
      null, null, null,
      latestHistoryDate,
      warnings,
    ];
  }

  // Prio 2: Completed
  if (isCompleted(stateText, tasks)) {
    return [
      Lifecycle.Completed, SourceMode.Fallback,
      null, null, null,
      latestHistoryDate,
      warnings,
    ];
  }

  // Prio 3: Blocked
  const [blockReason, blockArtifact] = findBlockSignal(workDir, tasks, stateText);
  if (blockReason !== null) {
    return [
      Lifecycle.Blocked, SourceMode.Fallback,
      null, blockReason, blockArtifact,
      latestHistoryDate,
      warnings,
    ];
  }

  // Prio 4: Paused-Awaiting-Input
  if (pendingInputs.length > 0) {
    const qIds = pendingInputs.map(p => p.question_id).join(", ");
    const pauseReason = `Pending Q&A: ${qIds}`;
    return [
      Lifecycle.PausedAwaitingInput, SourceMode.Fallback,
      pauseReason, null, null,
      latestHistoryDate,
      warnings,
    ];
  }

  // Prio 5: Running (default)
  return [
    Lifecycle.Running, SourceMode.Fallback,
    null, null, null,
    latestHistoryDate,
    warnings,
  ];
}

// ---------------------------------------------------------------------------
// REQUIREMENTS.md parser (mirrors parsers.py parse_requirements_md)
// ---------------------------------------------------------------------------

function parseRequirementsMd(reqPath) {
  // Returns [title, description, objective, bytesRead]
  // PF-2: status blockquote lines (^> _..._) are skipped in the Objective body.
  let isFile = false;
  try { isFile = statSync(reqPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, null, null, 0];

  let raw;
  try {
    raw = readFileBounded(reqPath);
  } catch (_) {
    return [null, null, null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_NAME = /^\s*-\s*\*\*Name:\*\*\s*(.+)/i;
  const RE_DESC = /^\s*-\s*\*\*Description:\*\*\s*(.+)/i;
  const RE_OBJ_HDR = /^##\s+(?:\d+\.\s+)?Objective\s*$/i;
  const RE_SECTION_HDR = /^##\s+\S/;
  // PF-2: status blockquote footer: > _..._  (wholly italic blockquote)
  const RE_STATUS_BLOCKQUOTE = /^>\s*_.*_\s*$/;

  // Template seed placeholder: treat *(pending)* as absent (PF-7)
  const PENDING_PLACEHOLDER = "*(pending)*";

  let title = null;
  let description = null;
  const objLines = [];
  let inObjective = false;

  for (const line of text.split("\n")) {
    if (inObjective) {
      if (RE_SECTION_HDR.test(line)) {
        inObjective = false;
      } else {
        // PF-2: skip status blockquote lines
        if (!RE_STATUS_BLOCKQUOTE.test(line.trim())) {
          objLines.push(line);
        }
      }
      continue;
    }

    let m = line.match(RE_NAME);
    if (m && title === null) {
      const val = m[1].trim();
      title = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    m = line.match(RE_DESC);
    if (m && description === null) {
      const val = m[1].trim();
      description = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    if (RE_OBJ_HDR.test(line)) {
      inObjective = true;
      continue;
    }
  }

  let objective = null;
  if (objLines.length > 0) {
    const raw_obj = objLines.join("\n").trim();
    if (raw_obj) objective = raw_obj;
  }

  return [title, description, objective, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-8: parse work-root SPEC.md for identity fields (Lite-path fallback)
// ---------------------------------------------------------------------------

export function parseSpecMd(specPath) {
  // Returns [title, description, h1Title, bytesRead]
  // Mirrors parse_spec_md in parsers.py (byte-parity).
  // - title: value from '- **Name:**' line (null if absent or *(pending)*)
  // - description: value from '- **Description:**' line (null if absent or *(pending)*)
  // - h1Title: text after the first '# ' line (null if absent)
  // Reuses RE_NAME/RE_DESC from parseRequirementsMd and PENDING_PLACEHOLDER.
  let isFile = false;
  try { isFile = statSync(specPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, null, null, 0];

  let raw;
  try {
    raw = readFileBounded(specPath);
  } catch (_) {
    return [null, null, null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_NAME = /^\s*-\s*\*\*Name:\*\*\s*(.+)/i;
  const RE_DESC = /^\s*-\s*\*\*Description:\*\*\s*(.+)/i;
  const RE_H1 = /^#\s+(.+)$/;

  // Template seed placeholder: treat *(pending)* as absent (PF-7)
  const PENDING_PLACEHOLDER = "*(pending)*";

  let title = null;
  let description = null;
  let h1Title = null;

  // Split on \r\n, \r, or \n (mirrors Python splitlines() \r handling) -- CRLF fix
  for (const line of text.split(/\r\n|\r|\n/)) {
    if (h1Title === null) {
      const mh = line.match(RE_H1);
      if (mh) {
        h1Title = mh[1].trim();
        continue;
      }
    }

    let m = line.match(RE_NAME);
    if (m && title === null) {
      const val = m[1].trim();
      title = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }
    m = line.match(RE_DESC);
    if (m && description === null) {
      const val = m[1].trim();
      description = val === PENDING_PLACEHOLDER ? null : val;
      continue;
    }

    // Stop scanning after all three fields are found
    if (title !== null && description !== null && h1Title !== null) break;
  }

  return [title, description, h1Title, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-3: parse task short-name from tasks/task-NNN.md first line
// ---------------------------------------------------------------------------

function parseTaskShortName(taskPath) {
  // Returns [shortName, bytesRead]
  // Parse rule: ^#\s+task-0*\d+\s*:\s*(.+)$  (case-insensitive)
  // Strips trailing period from the title.
  let isFile = false;
  try { isFile = statSync(taskPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [null, 0];

  let raw;
  try {
    raw = readFileBounded(taskPath);
  } catch (_) {
    return [null, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const RE_TITLE = /^#\s+task-0*\d+\s*:\s*(.+)$/i;

  for (const line of text.split("\n")) {
    const stripped = line.trim();
    if (!stripped) continue;
    const m = stripped.match(RE_TITLE);
    if (m) {
      let title = m[1].trim().replace(/\.$/, "");
      return [title || null, bytesRead];
    }
    // First non-blank line didn't match -> no short_name
    break;
  }

  return [null, bytesRead];
}

// ---------------------------------------------------------------------------
// PF-5: parse execution graph from PLAN.md (wave-map + prose fallback)
// ---------------------------------------------------------------------------

function parseExecutionGraph(planPath) {
  // Returns [taskLaneMap, bytesRead]
  // taskLaneMap: { task_id -> lane (int) }
  // Delivery comes from STATE (PF-5c); this only derives the lane.
  let isFile = false;
  try { isFile = statSync(planPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [{}, 0];

  let raw;
  try {
    raw = readFileBounded(planPath);
  } catch (_) {
    return [{}, 0];
  }
  const bytesRead = raw.length;
  const text = raw.toString("utf-8");

  const taskLaneMap = {};
  const lines = text.split("\n");

  // --- PF-5a: scan for wave-map fenced blocks ---
  const RE_WAVEMAP_OPEN = /^```wave-map\s*$/;
  const RE_WAVEMAP_CLOSE = /^```\s*$/;
  const RE_DELIVERY_LINE = /^delivery:\s*(\d+)\s*$/;
  const RE_WAVE_LINE = /^wave\s+(\d+)\s*:\s*(.+)$/i;
  const RE_TASK_ID = /\btask-\d+\b/gi;

  const wavemapDeliveries = new Set();

  let i = 0;
  while (i < lines.length) {
    const line = lines[i].trim();
    if (RE_WAVEMAP_OPEN.test(line)) {
      i++;
      let blockDelivery = null;
      while (i < lines.length) {
        const bline = lines[i].trim();
        if (RE_WAVEMAP_CLOSE.test(bline)) { i++; break; }
        const dm = bline.match(RE_DELIVERY_LINE);
        if (dm) {
          blockDelivery = parseInt(dm[1], 10);
          if (!isNaN(blockDelivery)) wavemapDeliveries.add(blockDelivery);
          i++; continue;
        }
        const wm = bline.match(RE_WAVE_LINE);
        if (wm) {
          const lane = parseInt(wm[1], 10);
          const tasksStr = wm[2];
          let tm;
          const re = /\btask-\d+\b/gi;
          while ((tm = re.exec(tasksStr)) !== null) {
            taskLaneMap[tm[0].toLowerCase()] = lane;
          }
          i++; continue;
        }
        i++;
      }
    } else {
      i++;
    }
  }

  // --- PF-5b: prose fallback for delivery sections with no wave-map ---
  const RE_DELIVERY_SECTION = /^###\s+delivery-(\d+)\s+execution\s+graph/i;
  const RE_WAVE_PROSE = /^(\s*)-\s*Wave\s+(\d+)\b/i;

  const wavemapTaskIds = new Set(Object.keys(taskLaneMap));
  let currentDelivery = null;
  let currentWave = null;
  let waveIndent = null;

  for (const line of lines) {
    const dsm = line.match(RE_DELIVERY_SECTION);
    if (dsm) {
      currentDelivery = parseInt(dsm[1], 10);
      currentWave = null;
      waveIndent = null;
      continue;
    }

    // Only prose-fallback for deliveries without a wave-map
    if (currentDelivery === null || wavemapDeliveries.has(currentDelivery)) {
      currentWave = null;
      waveIndent = null;
      continue;
    }

    const wpm = line.match(RE_WAVE_PROSE);
    if (wpm) {
      currentWave = parseInt(wpm[2], 10);
      waveIndent = wpm[1].length;
      // Collect task ids from the heading line
      const re = /\btask-\d+\b/gi;
      let tm;
      while ((tm = re.exec(line)) !== null) {
        const tid = tm[0].toLowerCase();
        if (!wavemapTaskIds.has(tid)) taskLaneMap[tid] = currentWave;
      }
      continue;
    }

    if (currentWave !== null && waveIndent !== null) {
      const lineIndent = line.length - line.trimStart().length;
      if (line.trim() === "") {
        // blank line: keep wave context
      } else if (lineIndent > waveIndent) {
        // sub-bullet: collect task ids
        const re = /\btask-\d+\b/gi;
        let tm;
        while ((tm = re.exec(line)) !== null) {
          const tid = tm[0].toLowerCase();
          if (!wavemapTaskIds.has(tid)) taskLaneMap[tid] = currentWave;
        }
      } else {
        // dedented -> end of wave sub-bullets
        currentWave = null;
        waveIndent = null;
      }
    }
  }

  return [taskLaneMap, bytesRead];
}

// ---------------------------------------------------------------------------
// Slug extraction (mirrors reader.py _slug_from_work_id)
// ---------------------------------------------------------------------------

function numberFromWorkId(workId) {
  // mirrors reader.py _number_from_work_id
  const m = workId.match(/^work-(\d+)-/);
  if (m) {
    const n = parseInt(m[1], 10);
    if (!isNaN(n)) return n;
  }
  return null;
}

// ---------------------------------------------------------------------------
// STATE.yml parser -- structured document read (work-009-refactor task-004,
// porting task-003's Python parse_state_md). The legacy section-header
// regexes and the section state machine that used to scan '## Pipeline
// State' / '## Tasks State' / '## Cross-phase Q&A' / '## Triage' / '##
// Features State' / '## Plan / Deliveries' / '## Lifecycle History' prose
// are GONE: parseStateDocument already turns the whole file into a nested
// object, so parseStateMd below is parse-document-then-map-keys, not a
// markdown scanner.
// ---------------------------------------------------------------------------

function qaQuestionId(rawId) {
  // Format a qa[].id value as the historical 'Q{N}' display form. Twin of
  // Python _qa_question_id(). Never throws.
  if (rawId === undefined || rawId === null) return "";
  const s = String(rawId).trim();
  if (!s) return "";
  if (s[0].toLowerCase() === "q") return s;
  return "Q" + s;
}

function noneIfNull(val) {
  // Return null for a null-sentinel-or-non-string value, else the string.
  // Twin of Python _none_if_null().
  if (typeof val !== "string") return null;
  return isNull(val) ? null : val;
}

function computeLatestHistoryDate(lifecycleHistory) {
  // max(lifecycle_history[].date) -- the newest AUTHORED history entry's
  // date, sourced from the ALREADY-parsed lifecycle_history array (no
  // second file read, no re-scan of raw text). Replaces the pre-refactor
  // extractLatestHistoryDate()'s raw-markdown "## Lifecycle History" table
  // scan, which has no construct to scan against a STATE.yml document (the
  // table no longer exists; lifecycle_history is now a YAML list).
  if (!Array.isArray(lifecycleHistory)) return null;
  let latest = null;
  for (const entry of lifecycleHistory) {
    if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
    const d = entry.date;
    if (typeof d === "string" && !isNull(d)) {
      const dv = d.trim();
      if (dv && (latest === null || dv > latest)) latest = dv;
    }
  }
  return latest;
}

function _applyPipelineFrontmatter(data, pw) {
  // Map the document's top-level pipeline-state scalar keys onto pw.
  // Returns true iff the 'lifecycle' key was present with a valid (non-null)
  // value -- the caller (parseStateMd) uses this to decide sourceMode
  // (Normalized iff present; Fallback -- via deriveLifecycle -- otherwise).
  // Twin of Python _apply_pipeline_frontmatter().
  let lifecyclePresent = false;

  let v = data.lifecycle;
  if (typeof v === "string" && !isNull(v)) {
    pw.lifecycle = parseLifecycle(v.trim());
    lifecyclePresent = true;
  }

  v = data.phase;
  if (typeof v === "string" && !isNull(v)) {
    pw.phase = parsePhase(v.trim());
  }

  v = data.active_skill;
  if (typeof v === "string") {
    const vv = v.trim();
    pw.activeSkill = (isNull(vv) || vv.toLowerCase() === "none") ? null : vv;
  }

  v = data.updated;
  if (typeof v === "string" && !isNull(v)) {
    pw.updated = v.trim();
  }

  v = data.pause_reason;
  if (typeof v === "string") {
    const vv = v.trim();
    pw.pauseReason = isNull(vv) ? null : vv;
  }

  v = data.block_reason;
  if (typeof v === "string") {
    const vv = v.trim();
    pw.blockReason = isNull(vv) ? null : vv;
  }

  v = data.block_artifact;
  if (typeof v === "string") {
    const vv = v.trim();
    pw.blockArtifact = isNull(vv) ? null : vv;
  }

  return lifecyclePresent;
}

function _applyIdentityFrontmatter(data, pw) {
  // Map the document's pipeline-identity + captured-scalar keys onto pw:
  // pipeline.path -> workPath, pipeline.initiator -> kind, started,
  // minimumGrade, userApproved. No legacy header-blockquote fallback
  // remains -- a legacy STATE.md is diagnosed at the work level (SP-9)
  // before this function is ever reached. Twin of Python
  // _apply_identity_frontmatter().
  const pipeline = data.pipeline;
  if (pipeline && typeof pipeline === "object" && !Array.isArray(pipeline)) {
    let v = pipeline.path;
    if (typeof v === "string" && !isNull(v)) {
      pw.workPath = v.trim().toLowerCase();
    }

    v = pipeline.initiator;
    if (typeof v === "string" && !isNull(v)) {
      pw.kind = resolveKind(v.trim());
    }
  }

  // started (top-level scalar). pw.created is ALSO backfilled from it so
  // existing consumers (home.html work.created, the JSON 'created' key)
  // keep working unchanged -- lifecycle_history's "Work created" entry
  // (read by the caller, parseStateMd) overrides this when present.
  let v = data.started;
  if (typeof v === "string" && !isNull(v)) {
    const startedVal = v.trim();
    pw.started = startedVal;
    pw.created = startedVal;
  }

  v = data.minimum_grade;
  if (typeof v === "string" && !isNull(v)) {
    pw.minimumGrade = v.trim().toUpperCase();
  }

  // userApproved: 'yes'/'no'/'true'/'false' (case-insensitive) -> bool.
  // Work-level approval, distinct from the KB's summary_approved
  // (parseKbState, a different file entirely).
  v = data.user_approved;
  if (typeof v === "string") {
    pw.userApproved = parseBoolYesno(v);
  }
}

function parseStateMd(text, workId, workDir) {
  // Parse a work-root STATE.yml document into a ParsedWork-shaped plain
  // object. Twin of Python parse_state_md() (work-009-refactor task-003,
  // ported to the Node runtime by task-004).
  //
  // Parse-document-then-map-keys: the whole file is parsed ONCE by
  // parseStateDocument (D-3 subset engine) into a nested object;
  // _applyPipelineFrontmatter / _applyIdentityFrontmatter then map that
  // object's keys onto pw -- together they ARE the whole of this function
  // now (no more markdown section state machine).
  //
  // Three things this function still does, beyond the two _apply* mappers:
  //   - falls back to deriveLifecycle() (LC-3, UNCHANGED) when the document
  //     carries no `lifecycle` key at all (an absent/empty/truncated file);
  //   - reads `lifecycle_history` for the work's `created` date (the first
  //     entry whose `event` is "Work created", newest-last per the
  //     template);
  //   - reads `qa` for pendingInputs (flattened-Lite-only AUTHORED
  //     Cross-phase Q&A; DERIVED on the full path, where no `qa` key is
  //     present at all).
  const label = workId ? workId + "/STATE.yml" : "STATE.yml";
  const [data, warnings] = parseStateDocument(text, { fileLabel: label });

  const pw = {
    lifecycle: Lifecycle.Unknown,
    phase: null,
    activeSkill: null,
    updated: null,
    pauseReason: null,
    blockReason: null,
    blockArtifact: null,
    tasks: [],
    pendingInputs: [],
    sourceMode: SourceMode.Fallback,
    parseWarnings: [...warnings],
    workPath: null,
    recipe: null,
    features: [],
    deliverables: [],
    created: null,
    kind: null,
    started: null,
    minimumGrade: null,
    userApproved: null,
  };

  const lifecyclePresent = _applyPipelineFrontmatter(data, pw);

  const lifecycleHistory = Array.isArray(data.lifecycle_history) ? data.lifecycle_history : null;

  if (lifecyclePresent) {
    pw.sourceMode = SourceMode.Normalized;
  } else {
    // LC-3 FALLBACK ADAPTER (task-011, audited task-013 M6; UNCHANGED,
    // deriveLifecycle's own body is out of this task's edit surface): no
    // `lifecycle` key at all -- absent/empty/truncated document.
    // deriveLifecycle scans legacy markdown signals (IMPEDIMENT files, task
    // rollup, Q&A, Deploy Status); against a YAML document it finds none of
    // those and returns Unknown/Fallback -- a safe no-op that still
    // satisfies "best-effort model, never raises" (SP-9). latestHistoryDate
    // is computed from the STRUCTURED lifecycle_history (see
    // computeLatestHistoryDate's own comment for why this replaces the old
    // raw-markdown-table scan).
    const _wd = workDir || ".";
    const latestHistoryDate = computeLatestHistoryDate(lifecycleHistory);
    const [
      derivedLifecycle, derivedSourceMode,
      derivedPauseReason, derivedBlockReason, derivedBlockArtifact,
      derivedUpdated, extraWarnings,
    ] = deriveLifecycle({
      workDir: _wd,
      tasks: pw.tasks,
      pendingInputs: pw.pendingInputs,
      stateText: text,
      workId: workId || "",
      latestHistoryDate,
    });
    pw.lifecycle = derivedLifecycle;
    pw.sourceMode = derivedSourceMode;
    pw.pauseReason = derivedPauseReason;
    pw.blockReason = derivedBlockReason;
    pw.blockArtifact = derivedBlockArtifact;
    if (pw.updated === null) {
      pw.updated = derivedUpdated;
    }
    pw.parseWarnings.push(...extraWarnings);
  }

  _applyIdentityFrontmatter(data, pw);

  // lifecycle_history (AUTHORED) -> pw.created: the first entry (append-only,
  // newest LAST per the template) whose event is "Work created".
  if (lifecycleHistory) {
    for (const entry of lifecycleHistory) {
      if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
      const event = entry.event;
      if (typeof event === "string" && event.trim().toLowerCase() === "work created") {
        const dateVal = entry.date;
        if (typeof dateVal === "string" && !isNull(dateVal)) {
          pw.created = dateVal;
        }
        break;
      }
    }
  }

  // qa (flattened-Lite-only AUTHORED Cross-phase Q&A; absent/DERIVED on the
  // full path, where the hierarchical assembly unions per-delivery Q&A
  // instead) -> pendingInputs, Pending entries only.
  const qaList = data.qa;
  if (Array.isArray(qaList)) {
    for (const entry of qaList) {
      if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
      const stateVal = entry.state;
      if (typeof stateVal === "string" && stateVal.trim().toLowerCase() === "pending") {
        pw.pendingInputs.push({
          question_id: qaQuestionId(entry.id),
          category: noneIfNull(entry.category),
          impact: noneIfNull(entry.impact),
          context: noneIfNull(entry.context),
          suggested: noneIfNull(entry.suggested),
        });
      }
    }
  }

  return pw;
}

// ---------------------------------------------------------------------------
// Slug extraction (mirrors reader.py _slug_from_work_id)
// ---------------------------------------------------------------------------

function slugFromWorkId(workId) {
  const m = workId.match(/^work-\d+-(.+)$/);
  return m ? m[1] : workId;
}

// ---------------------------------------------------------------------------
// readRepo(root) -- main entry point (mirrors reader.py read_repo)
// ---------------------------------------------------------------------------

export function readRepo(root) {
  // Thin wrapper: run full pass, discard STATE.yml cache, return model only.
  // Signature and return type are UNCHANGED (DR-1/DD-3/NFR4 satisfied by _readRepoFull).
  return _readRepoFull(root).model;
}

function _readRepoFull(root) {
  // Run the full always-on repo read pass.
  // Returns { model, stateCache } where stateCache maps workId -> [stateText, statePathLabel].
  // The cache is a by-product (zero extra I/O); readRepoDetail uses it to satisfy
  // DR-1/DD-3/NFR4 (raw_state reuses bytes already read; no re-read of STATE.yml).

  // Normalize: accept repo root or .aid/ dir itself
  let resolvedRoot = resolve(root);
  if (basename(resolvedRoot) === ".aid") {
    resolvedRoot = resolve(resolvedRoot, "..");
  }

  const readAt = new Date().toISOString().replace(/\.\d{3}Z$/, "+00:00");
  const parseWarnings = [];
  let bytesRead = 0;

  // Step 1: RESOLVE
  const loc = locateAidRoot(resolvedRoot);

  if (!loc.aidExists) {
    parseWarnings.push(
      `No .aid/ directory found at ${resolvedRoot}; returning empty model.`
    );
    const emptyModel = _buildRepoModel({
      tool: { manifest_present: false, aid_version: null, installed_at: null, tools_installed: [] },
      repo: { project_name: basename(resolvedRoot), aid_dir: loc.aidDir, kb_state: null },
      works: [],
      read: {
        read_at: readAt,
        work_count: 0,
        fallback_works: [],
        parse_warnings: parseWarnings,
        bytes_read: 0,
      },
    });
    return { model: emptyModel, stateCache: {} };
  }

  // Step 2: LEVEL-0 ToolInfo
  const [toolInfo, br0] = parseToolInfo(loc.manifestPath);
  bytesRead += br0;

  // Step 3: LEVEL-1 RepoInfo
  let [projectName, projectDescription, br1] = parseProjectSettings(loc.settingsPath);
  bytesRead += br1;
  if (!projectName) {
    projectName = basename(resolvedRoot);
  }

  // feature-002 (work-017 task-005): GLOBAL review.minimum_grade -- its own
  // 'review:'-section scan (a real settings.yml has 'tools:' between 'project:'
  // and 'review:', so the project-section scan above cannot reach it).
  const [minimumGrade, brGrade] = parseSettingsMinimumGrade(loc.settingsPath);
  bytesRead += brGrade;

  // task-064: parse kb_baseline from settings.yml (DM-A4)
  const [kbBaseline, brBaseline] = parseKbBaseline(loc.settingsPath);
  bytesRead += brBaseline;

  // task-064: parse kb_state with summary_present (stat of .aid/knowledge/kb.html)
  const [kbState, br2] = parseKbState(loc.kbDir);
  bytesRead += br2;

  // task-064: derive 5-state KB status (FF-A3 waterfall) and attach fields
  if (kbState !== null) {
    const kbStatus = deriveKbStatus(
      loc.kbDir,
      kbState.summary_approved,
      kbState.summary_present,
      kbBaseline,
      resolvedRoot
    );
    kbState.status = kbStatus;
    kbState.kb_baseline = kbBaseline;

    // task-042: per-doc freshness (f007) -- additive; gitFreshnessCheck retained
    const docFreshness = deriveDocFreshness(loc.kbDir, resolvedRoot);
    kbState.doc_freshness = docFreshness;
    kbState.suspect_count = docFreshness.filter(d => d.verdict === "suspect").length;
  }

  // feature-007 (work-017 task-019): parse the project-level connectors registry
  // (.aid/connectors/*.md), sorted by stem. Missing dir -> [] (non-error).
  const [connectors, brConnectors] = parseConnectors(join(loc.aidDir, "connectors"));
  bytesRead += brConnectors;

  // feature-010 (work-017 task-021): parse the project-level external-sources
  // registry (.aid/knowledge/external-sources.md sources: list). A thin wrapper
  // over parseDocFrontmatter (no new parser); absent file -> [] (non-error).
  const externalSources = parseExternalSources(loc.kbDir);

  const repoInfo = {
    project_name: projectName,
    aid_dir: loc.aidDir,
    kb_state: kbState,
    project_description: projectDescription,
    minimum_grade: minimumGrade,
    connectors: connectors,
    external_sources: externalSources,
  };

  // Step 4: ENUMERATE worktrees + work folders (work-004 Pillar 4 / SD-3)
  // _enumerateWorktreeRoots returns [[branchLabel, aidDir], ...] with main root first.
  // Degrades to main-root-only on any git failure (never throws).
  // For each (branchLabel, aidDir) root, locate work-NNN-*/ dirs. Each resulting
  // WorkModel is tagged with branchLabel. Cross-root merge of same work_id is Step 6.
  const worktreeRoots = _enumerateWorktreeRoots(resolvedRoot);

  // Steps 5a-5g: PER WORK -- parse STATE.yml; build WorkModel list (pre-reconcile).
  // Intermediate accumulator: maps work_id -> [[WorkModel, stateText, stateLabel], ...]
  const workCopies = {}; // work_id -> array of [WorkModel, stateText, stateLabel]

  for (const [branchLabel, wtAidDir] of worktreeRoots) {
    const wtRoot = join(wtAidDir, "..");
    const wtLoc = locateAidRoot(wtRoot);
    if (!wtLoc.aidExists) continue;

    for (const workDir of wtLoc.workDirs) {
      const workId = basename(workDir);
      const [workModel, workWarnings, workBytes, stateText, statePathLabel] = readWork(workDir, workId);
      // Tag the work model with the branch that owns this worktree
      workModel.branch_label = branchLabel;
      parseWarnings.push(...workWarnings);
      bytesRead += workBytes;
      if (!(workId in workCopies)) workCopies[workId] = [];
      workCopies[workId].push([workModel, stateText, statePathLabel]);
    }
  }

  // If worktree enumeration yielded NO results (all worktrees had no .aid/), fall back
  // to the main root so a bare repo without worktrees still renders correctly.
  if (Object.keys(workCopies).length === 0 && loc.aidExists) {
    for (const workDir of loc.workDirs) {
      const workId = basename(workDir);
      const [workModel, workWarnings, workBytes, stateText, statePathLabel] = readWork(workDir, workId);
      workModel.branch_label = null; // indeterminate; worktree list gave no data
      parseWarnings.push(...workWarnings);
      bytesRead += workBytes;
      workCopies[workId] = [[workModel, stateText, statePathLabel]];
    }
  }

  // Step 6: RECONCILE -- for each work_id, merge all copies (Pillar 5 / task-011).
  // Single-copy works pass through _reconcileSameWork unchanged (trivial case).
  const works = [];
  const fallbackWorks = [];
  // Build per-work STATE.yml cache as a by-product of the always-on pass.
  const stateCache = {};

  for (const workId of Object.keys(workCopies)) {
    const copies = workCopies[workId];
    const [reconciledWm, winningText, winningLabel] = _reconcileSameWork(copies);
    works.push(reconciledWm);
    stateCache[workId] = [winningText, winningLabel];
    if (reconciledWm.source_mode !== SourceMode.Normalized) {
      fallbackWorks.push(workId);
    }
  }

  // Step 7: ASSEMBLE
  const model = _buildRepoModel({
    tool: toolInfo,
    repo: repoInfo,
    works,
    read: {
      read_at: readAt,
      work_count: works.length,
      fallback_works: fallbackWorks,
      parse_warnings: parseWarnings,
      bytes_read: bytesRead,
    },
  });
  return { model, stateCache };
}

function _taskStopRequested(workDir, workId, taskId) {
  // Derive TaskModel.stop_requested (feature-008-execution-control, work-017
  // task-029): a filesystem `stat` of the cooperative stop-signal file
  // `write-control-signal.sh` (task-028) creates on `task.stop` / removes on
  // `task.resume`.
  //
  // Computed RELATIVE to workDir -- the walked worktree copy of
  // `.aid/works/<work_id>` this read pass is currently processing (WT-1) --
  // NEVER a reconstructed `<served-root>/.aid/.control/<work_id>/` path.
  // `join(workDir, "..", "..", ".control", workId)` is the `.aid/.control/
  // <work_id>/` sibling of workDir's own `.aid/works/`, exactly mirroring
  // `write-control-signal.sh`'s own path derivation (`dashboard/scripts/
  // write-control-signal.sh`: `WORK_DIR/../../.control/WORK_ID`) so the reader
  // stats the identical tree the writer and the `aid-execute` poll act on --
  // the Python twin's `_task_stop_requested` (reader.py) performs the
  // byte-identical stat via `work_dir.parent.parent`.
  //
  // Never parsed from / written to STATE.yml (the control file is a new
  // control-artifact class, outside STATE.yml's C1 single-writer scope -- see
  // feature-008 SPEC.md "C1 scope note"). Fail-safe: a missing `.control/`
  // directory, a missing signal file, or any error all yield false -- never a
  // parse warning, never a thrown exception (mirrors the reader's
  // forward-compat posture for every other derived field).
  try {
    const controlFile = join(workDir, "..", "..", ".control", workId, taskId + ".stop");
    return statSync(controlFile).isFile();
  } catch (_) {
    return false;
  }
}

function readWork(workDir, workId) {
  const statePathLabel = ".aid/works/" + workId + "/STATE.yml";
  const statePath = join(workDir, "STATE.yml");

  // SP-10: one stat here, reused below (the monolithic branch's own
  // presence check and the legacy-detection guard immediately below both
  // consult this SAME result -- never re-stat the same path twice in one
  // readWork call). KI-002 ruling: this is the ONE stat AC-6/SP-10 accepts
  // as newly added -- it is the mechanism the mandated legacy diagnosis
  // requires and cannot be produced from anything else. Mirrors reader.py's
  // state_exists (task-003); the Node twin keeps the SAME single-stat
  // posture rather than an EAFP read-then-catch alternative (KI-002).
  let stateExists = false;
  try {
    stateExists = statSync(statePath).isFile();
  } catch (_) {
    stateExists = false;
  }

  // Legacy detection (SP-9): STATE.md present, STATE.yml absent -> diagnose,
  // don't parse. This runs FIRST, before any layout routing: a work
  // directory holding the retired STATE.md with no sibling STATE.yml is
  // diagnosed regardless of what its OTHER files (BLUEPRINT.md,
  // deliveries/) would otherwise suggest about its layout.
  if (!stateExists) {
    let legacyExists = false;
    try {
      legacyExists = statSync(join(workDir, "STATE.md")).isFile();
    } catch (_) {
      legacyExists = false;
    }
    if (legacyExists) {
      const parseWarnings = [
        workId + ": legacy STATE.md found with no STATE.yml sibling; " +
        "run 'aid update' to migrate this work; returning minimal WorkModel.",
      ];
      return [_minimalWorkModel(workId), parseWarnings, 0, "", statePathLabel];
    }
  }

  // Pillar 6: hierarchy detection (per-work, presence-based)
  if (_detectHierarchy(workDir)) {
    return _readWorkHierarchical(workDir, workId);
  }

  // feature-001: flattened single-delivery layout (per-work, presence-based;
  // mutually exclusive with the deliveries/ wrapper checked above)
  if (_detectFlat(workDir)) {
    return _readWorkFlat(workDir, workId);
  }

  // --- Legacy monolithic path (preserved behavior) ---
  const parseWarnings = [];
  let bytesRead = 0;

  if (!stateExists) {
    parseWarnings.push(workId + ": STATE.yml not found; returning minimal WorkModel.");
    return [_minimalWorkModel(workId), parseWarnings, 0, "", statePathLabel];
  }

  let text;
  let raw;
  try {
    raw = readFileBounded(statePath);
    bytesRead = raw.length;
    text = raw.toString("utf-8");
  } catch (exc) {
    parseWarnings.push(workId + ": STATE.yml read error (" + exc + "); returning minimal WorkModel.");
    return [_minimalWorkModel(workId), parseWarnings, 0, "", statePathLabel];
  }

  const pw = parseStateMd(text, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);

  // Prototype: parse work number from folder prefix (work-NNN-...)
  const workNumber = numberFromWorkId(workId);

  // Prototype: parse REQUIREMENTS.md for identity fields
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  // PF-8: SPEC.md fallback source for Lite-path works (no REQUIREMENTS.md)
  // Resolution order: REQUIREMENTS.md Name -> SPEC.md Name -> SPEC.md H1 -> de-slug
  // Resolution order: REQUIREMENTS.md Description -> SPEC.md Description -> null
  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      // Prefer SPEC.md Name over H1; de-slug is the final fallback (set by 'name')
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // PF-5: parse PLAN.md execution graph to derive lane per task_id
  const planPath = join(workDir, "PLAN.md");
  const [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // PF-3 + PF-5c: enrich each task with short_name, delivery, lane
  const tasksDir = join(workDir, "tasks");
  const RE_DELIVERY = /^delivery-(\d+)$/i;
  const enrichedTasks = pw.tasks.map(task => {
    // PF-5c: delivery from STATE Wave column ("delivery-NNN")
    let delivery = null;
    if (task.wave) {
      const dm = task.wave.trim().match(RE_DELIVERY);
      if (dm) delivery = parseInt(dm[1], 10);
    }

    // PF-5a/5b: lane from PLAN.md wave-map / prose
    const lane = taskLaneMap[task.task_id.toLowerCase()];
    const laneVal = (lane !== undefined) ? lane : null;

    // PF-3: short_name from tasks/task-NNN.md first line
    let shortName = null;
    const taskFile = join(tasksDir, task.task_id + ".md");
    const [sn, snBytes] = parseTaskShortName(taskFile);
    bytesRead += snBytes;
    shortName = sn;

    return Object.assign({}, task, {
      short_name: shortName,
      delivery: delivery,
      lane: laneVal,
      stop_requested: _taskStopRequested(workDir, workId, task.task_id),
    });
  });

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: enrichedTasks,
    pending_inputs: pw.pendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    work_path: pw.workPath,
    recipe: pw.recipe,
    features: pw.features,
    deliverables: pw.deliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, text, statePathLabel];
}

function _minimalWorkModel(workId) {
  return _buildWorkModel({
    work_id: workId,
    name: slugFromWorkId(workId),
    lifecycle: Lifecycle.Unknown,
    phase: null,
    active_skill: null,
    updated: null,
    created: null,
    pause_reason: null,
    block_reason: null,
    block_artifact: null,
    tasks: [],
    pending_inputs: [],
    source_mode: SourceMode.Fallback,
    number: numberFromWorkId(workId),
    title: null,
    description: null,
    objective: null,
    work_path: null,
    recipe: null,
    features: [],
    deliverables: [],
  });
}

// ---------------------------------------------------------------------------
// work-004 Pillar 5 / SD-2: State advancement ordering (LOCKED)
//
// Authoritative ordered list (most-advanced first, index = rank int):
//   Done(0) > Canceled(1) > In Review(2) > In Progress(3) >
//   Blocked(4) > Failed(5) > Pending(6) > Unknown(7)
//
// Rationale (from SPEC.md SD-2):
//   Done/Canceled are terminal-resolved (highest rank).
//   In Review is past In Progress (review is a later pipeline stage).
//   Blocked outranks Failed: blocked = recoverable-in-place + needs attention;
//   Failed = completed-but-rejected attempt (parallel branch may have superseded it).
//   Both Blocked and Failed outrank Pending (work was attempted; more informative).
//   Unknown is the reader-only sentinel and is ranked last.
//
// The Python twin (reader.py) encodes this SAME ordering verbatim.
// ---------------------------------------------------------------------------
const SD2_RANK = {
  "Done":        0,
  "Canceled":    1,
  "In Review":   2,
  "In Progress": 3,
  "Blocked":     4,
  "Failed":      5,
  "Pending":     6,
  "Unknown":     7,
};
const _SD2_RANK_DEFAULT = 7; // sentinel for any state not in SD2_RANK

function _sd2Rank(taskStatus) {
  // Return the SD-2 rank for a task status string. Lower = more advanced.
  // Never throws.
  try {
    const r = SD2_RANK[taskStatus];
    return r !== undefined ? r : _SD2_RANK_DEFAULT;
  } catch (_) {
    return _SD2_RANK_DEFAULT;
  }
}

// ---------------------------------------------------------------------------
// work-004 Pillar 4 / SD-3: Worktree enumeration helpers
//
// Delegates via the EXISTING runGitCommand fixed-argv / execFileSync no-shell
// pattern (verb hard-coded in argv). No allow-list is enforced (none exists in
// reader.mjs today; safety rests on fixed-argv by construction).
// ---------------------------------------------------------------------------

// Branch name label for the main worktree (must match Python _detect_main_branch_label)
function _detectMainBranchLabel(repoRoot) {
  // Try: git -C <repoRoot> symbolic-ref --short HEAD
  const ref = runGitCommand(
    ["-C", repoRoot, "symbolic-ref", "--short", "HEAD"],
    null
  );
  if (ref) return ref;
  return "main"; // fallback default
}

function _isGitToplevel(repoRoot) {
  // Return true if repoRoot is the git worktree toplevel (not a subdirectory of one).
  // Mirrors Python derivation.py _is_git_toplevel (same guard).
  // Prevents a fixture or nested dir from inheriting the host repo's worktrees.
  // Never throws.
  try {
    const toplevel = runGitCommand(
      ["-C", repoRoot, "rev-parse", "--show-toplevel"],
      null
    );
    if (!toplevel) return false;
    // Resolve both paths for reliable comparison
    const resolvedToplevel = resolve(toplevel.trim());
    const resolvedRoot = resolve(repoRoot);
    return resolvedToplevel === resolvedRoot;
  } catch (_) {
    return false;
  }
}

function _runWorktreeList(repoRoot) {
  // Run: git -C <repoRoot> worktree list --porcelain
  // Verb hard-coded in argv (no shell). 2s timeout via runGitCommand.
  // Safety guard: verifies repoRoot IS the git toplevel before running worktree list.
  // If repoRoot is a subdirectory of a git repo (e.g. a fixture directory nested inside
  // a larger repo), git would walk up and report the enclosing repo's worktrees -- wrong.
  // The guard degrades to null (caller falls back to main-root-only).
  // Returns stdout string or null on any failure.
  if (!_isGitToplevel(repoRoot)) return null;
  return runGitCommand(
    ["-C", repoRoot, "worktree", "list", "--porcelain"],
    null
  );
}

function _parseWorktreePorcelain(output) {
  // Parse `git worktree list --porcelain` output.
  // Returns [ [absPath, branchLabel], ... ]
  // absPath is an absolute path string; branchLabel is branch name or "(detached)".
  // Returns [] on any parse failure. Never throws.
  const DETACHED_LABEL = "(detached)";
  try {
    const records = [];
    let currentPath = null;
    let currentBranch = null;

    for (const rawLine of output.split("\n")) {
      const line = rawLine.replace(/\r$/, "");

      if (!line) {
        // Blank line: flush current record
        if (currentPath !== null) {
          const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
          records.push([currentPath, label]);
        }
        currentPath = null;
        currentBranch = null;
        continue;
      }

      const wtM = line.match(/^worktree\s+(.+)$/);
      if (wtM) {
        // Flush pending record without trailing blank
        if (currentPath !== null) {
          const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
          records.push([currentPath, label]);
          currentBranch = null;
        }
        currentPath = wtM[1].trim();
        continue;
      }

      const brM = line.match(/^branch\s+refs\/heads\/(.+)$/);
      if (brM) {
        currentBranch = brM[1].trim();
      }
    }

    // Flush trailing record (output may not end with blank line)
    if (currentPath !== null) {
      const label = currentBranch !== null ? currentBranch : DETACHED_LABEL;
      records.push([currentPath, label]);
    }

    return records;
  } catch (_) {
    return [];
  }
}

function _enumerateWorktreeRoots(repoRoot) {
  // Mirror Python locator.enumerate_worktree_roots.
  // Returns [[branchLabel, aidDir], ...] with main root always first.
  // Degrades to main-root-only on any git failure (never throws).
  const mainAid = join(repoRoot, ".aid");
  const mainLabel = _detectMainBranchLabel(repoRoot);
  const mainFallback = [[mainLabel, mainAid]];

  const porcelain = _runWorktreeList(repoRoot);
  if (porcelain === null) return mainFallback;

  const parsed = _parseWorktreePorcelain(porcelain);
  if (!parsed || parsed.length === 0) return mainFallback;

  const results = [];
  for (const [wtPath, branchLabel] of parsed) {
    const wtAid = join(wtPath, ".aid");
    results.push([branchLabel, wtAid]);
  }

  return results.length > 0 ? results : mainFallback;
}

// ---------------------------------------------------------------------------
// work-004 Pillar 6: Hierarchy detection + hierarchical work read
// ---------------------------------------------------------------------------

const RE_DELIVERY_DIR = /^delivery-(\d+)$/i;
const RE_TASK_DIR_H = /^(task-\d+)$/i;

function _detectHierarchy(workDir) {
  // Return true if this work has the new per-unit STATE.yml hierarchy.
  // Detection: if ANY deliveries/delivery-NNN/tasks/task-NNN/STATE.yml exists under workDir.
  // Presence-based, per-work. Never throws. Filename retargeted only
  // (work-009-refactor task-004, SP-7) -- the rule itself is unchanged.
  try {
    const deliveriesDir = join(workDir, "deliveries");
    let entries;
    try { entries = readdirSync(deliveriesDir); } catch (_) { return false; }
    for (const name of entries) {
      if (!RE_DELIVERY_DIR.test(name)) continue;
      const deliveryPath = join(deliveriesDir, name);
      let isDir = false;
      try { isDir = statSync(deliveryPath).isDirectory(); } catch (_) { isDir = false; }
      if (!isDir) continue;
      const tasksDir = join(deliveryPath, "tasks");
      let tasksDirExists = false;
      try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }
      if (!tasksDirExists) continue;
      let taskEntries;
      try { taskEntries = readdirSync(tasksDir); } catch (_) { continue; }
      for (const tname of taskEntries) {
        if (!RE_TASK_DIR_H.test(tname)) continue;
        const taskStatePath = join(tasksDir, tname, "STATE.yml");
        let isFile = false;
        try { isFile = statSync(taskStatePath).isFile(); } catch (_) { isFile = false; }
        if (isFile) return true;
      }
    }
  } catch (_) {
    // pass
  }
  return false;
}

function _declaredWorkPath(workDir) {
  // Return the work-root STATE.yml `pipeline.path`, or null.
  // Mirror reader.py _declared_work_path.
  //
  // STATE.yml only -- no legacy fallback, deliberately. SP-9 routes a work
  // holding the retired markdown name with no sibling STATE.yml to the
  // legacy-work detector in readWork, which runs BEFORE any layout routing and
  // diagnoses rather than parses. A legacy work therefore never reaches
  // _detectFlat, so a fallback here would be unreachable and contrary to that
  // policy.
  //
  // Reads `pipeline.path` out of the nested tree via parseStateDocument -- the
  // same D-3 subset engine every other state reader uses -- exactly as
  // _applyPipelineIdentity does. Never throws (NFR7).
  try {
    const statePath = join(workDir, "STATE.yml");
    let isFile = false;
    try { isFile = statSync(statePath).isFile(); } catch (_) { isFile = false; }
    if (!isFile) return null;
    const text = readFileBounded(statePath).toString("utf8");
    const [data] = parseStateDocument(text, { fileLabel: "STATE.yml" });
    const pipeline = data && data.pipeline;
    if (!pipeline || typeof pipeline !== "object") return null;
    const v = pipeline.path;
    if (typeof v !== "string") return null;
    const s = v.trim().toLowerCase();
    return s === "" ? null : s;
  } catch (_) {
    return null;
  }
}

function _detectFlat(workDir) {
  // Return true if this work has the FLATTENED single-delivery layout (feature-001).
  // Mirror reader.py _detect_flat.
  //
  // DECLARED FIRST, inferred only as a fallback. The layout is a property of
  // the WHOLE WORK, so it is read from the work-root STATE.yml
  // (`pipeline.path: lite | full`) when that key is present. A declared value
  // cannot be ambiguous; an inferred one can -- and inferring it from a FILE
  // PRESENCE made an ordinary artifact load-bearing, so `BLUEPRINT.md` could
  // not be retired or relocated without silently changing how three separate
  // implementations classified the work.
  //
  // The surviving fallback is the original 3-part presence rule: a work-root
  // BLUEPRINT.md exists AND at least one tasks/task-NNN/DETAIL.md exists
  // directly under the work root AND no `deliveries/` wrapper exists. This
  // layout has no per-task STATE.yml; the check does not look for one.
  //
  // This file already documented exactly this shape for the `workPath` FIELD
  // ("stop inferring via _detectFlat/_detectHierarchy when present ... the
  // fallback default for un-migrated works"); this extends it to the layout
  // DISPATCH, which is what actually made the artifact load-bearing.
  //
  // The 3-part presence rule survives only for un-migrated works whose STATE.md
  // predates the frontmatter block: a work-root BLUEPRINT.md exists AND at
  // least one tasks/task-NNN/DETAIL.md exists directly under the work root AND
  // no `deliveries/` wrapper exists.
  //
  // Mirrors the SAME rule as `is_flat_layout()` in
  // canonical/aid/scripts/execute/writeback-state.sh and reader.py's
  // `_detect_flat` (lockstep Python twin).
  //
  // Mutually exclusive with _detectHierarchy by construction (the fallback
  // explicitly asserts `deliveries/` absence, not just call-site ordering).
  // Never throws.
  try {
    const declared = _declaredWorkPath(workDir);
    if (declared !== null) return declared === "lite";

    let blueprintIsFile = false;
    try { blueprintIsFile = statSync(join(workDir, "BLUEPRINT.md")).isFile(); } catch (_) { blueprintIsFile = false; }
    if (!blueprintIsFile) return false;

    let deliveriesIsDir = false;
    try { deliveriesIsDir = statSync(join(workDir, "deliveries")).isDirectory(); } catch (_) { deliveriesIsDir = false; }
    if (deliveriesIsDir) return false;

    const tasksDir = join(workDir, "tasks");
    let tasksDirIsDir = false;
    try { tasksDirIsDir = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirIsDir = false; }
    if (!tasksDirIsDir) return false;

    let entries;
    try { entries = readdirSync(tasksDir); } catch (_) { return false; }
    for (const name of entries) {
      if (!RE_TASK_DIR_H.test(name)) continue;
      const taskPath = join(tasksDir, name);
      let isDir = false;
      try { isDir = statSync(taskPath).isDirectory(); } catch (_) { isDir = false; }
      if (!isDir) continue;
      let detailIsFile = false;
      try { detailIsFile = statSync(join(taskPath, "DETAIL.md")).isFile(); } catch (_) { detailIsFile = false; }
      if (detailIsFile) return true;
    }
  } catch (_) {
    // pass
  }
  return false;
}

// Hierarchical per-unit STATE.yml parsers (work-009-refactor task-004,
// porting task-003's Python parse_task_state_md / parse_delivery_state_md /
// parse_tasks_lifecycle_md). No more per-section regexes or a legacy prose
// scan: each file is parsed ONCE by parseStateDocument, then every scalar
// and structure is read directly by key.

// Valid SD-8 delivery lifecycle enum values (Pillar 1 / SD-8)
const DELIVERY_STATE_VALUES = new Set([
  "Pending-Spec", "Specified", "Executing", "Gated", "Done", "Blocked",
]);

function _parseTaskStateMd(text, taskId) {
  // Parse a task-level STATE.yml into a ParsedTaskState-shaped plain object.
  // Twin of Python parse_task_state_md(). Structured read: the whole
  // document is parsed once by parseStateDocument, then every top-level
  // scalar and the quick_check / dispatch_log structures are read directly
  // by key -- no prose fallback (a legacy STATE.md this task belongs to is
  // diagnosed at the work level before this function is ever reached,
  // SP-9). Returns { state, review, elapsed, notes, displayName,
  // quickCheckReviewerTier, quickCheckFindings, dispatchLog, parseWarnings }.
  const pts = {
    state: TaskStatus.Unknown,
    review: null,
    elapsed: null,
    notes: null,
    displayName: null,
    quickCheckReviewerTier: null,
    quickCheckFindings: [],
    dispatchLog: [],
    parseWarnings: [],
  };

  try {
    const label = taskId ? taskId + "/STATE.yml" : "STATE.yml";
    const [data, warnings] = parseStateDocument(text, { fileLabel: label });
    pts.parseWarnings.push(...warnings);

    let v = data.state;
    if (typeof v === "string" && !isNull(v)) {
      pts.state = parseTaskStatus(v.trim());
    }

    v = data.review;
    if (typeof v === "string") pts.review = isNull(v) ? null : v;

    v = data.elapsed;
    if (typeof v === "string") pts.elapsed = isNull(v) ? null : v;

    v = data.notes;
    if (typeof v === "string") pts.notes = isNull(v) ? null : v;

    v = data.display_name;
    if (typeof v === "string") pts.displayName = isNull(v) ? null : v;

    const quickCheck = data.quick_check;
    if (quickCheck && typeof quickCheck === "object" && !Array.isArray(quickCheck)) {
      const tier = quickCheck.reviewer_tier;
      if (typeof tier === "string" && !isNull(tier)) pts.quickCheckReviewerTier = tier;

      const rawFindings = quickCheck.findings;
      if (Array.isArray(rawFindings)) {
        for (const f of rawFindings) {
          if (!f || typeof f !== "object" || Array.isArray(f)) continue;
          const severityRaw = f.severity;
          pts.quickCheckFindings.push({
            severity: parseSeverity(typeof severityRaw === "string" ? severityRaw : ""),
            description: typeof f.description === "string" ? f.description.trim() : "",
            location: noneIfNull(f.source),
            disposition: noneIfNull(f.disposition),
            reviewer_tier: pts.quickCheckReviewerTier,
          });
        }
      }
    }

    const dispatchLog = data.dispatch_log;
    if (Array.isArray(dispatchLog)) {
      pts.dispatchLog = dispatchLog.filter((d) => d && typeof d === "object" && !Array.isArray(d));
    }
  } catch (exc) {
    pts.parseWarnings.push(
      taskId + ": error parsing task STATE.yml (" + exc + "); returning best-effort task state"
    );
  }

  return pts;
}

function _parseDeliveryStateMd(text, deliveryId) {
  // Parse a delivery-level STATE.yml into a ParsedDeliveryState-shaped plain
  // object. Twin of Python parse_delivery_state_md(). Structured read:
  //   - delivery_state (top-level scalar, SD-8 enum)
  //   - gate_tier / gate_grade / gate_timestamp (top-level scalars)
  //   - delivery_lifecycle.updated / .block_reason / .block_artifact
  //   - delivery_gate.issue_list
  //   - qa -> pendingInputs (Pending entries only)
  // deliveryState is the INDEPENDENTLY AUTHORED SD-8 enum, NOT derived from
  // the task rollup (SD-9); pds.tasks stays [] always (the derived Tasks
  // State rollup is never authored in this file). Called by BOTH the
  // hierarchical path (deliveries/delivery-NNN/STATE.yml) and the flat path
  // (the work-root STATE.yml itself, whose delivery_lifecycle/delivery_gate/
  // qa keys are AUTHORED directly for the single implicit delivery).
  const pds = {
    deliveryState: null,
    updated: null,
    blockReason: null,
    blockArtifact: null,
    gateGrade: null,
    gateReviewerTier: null,
    gateTimestamp: null,
    deliveryGateIssueList: [],
    pendingInputs: [],
    tasks: [],
    parseWarnings: [],
  };

  try {
    const label = deliveryId ? deliveryId + "/STATE.yml" : "STATE.yml";
    const [data, warnings] = parseStateDocument(text, { fileLabel: label });
    pds.parseWarnings.push(...warnings);

    let v = data.delivery_state;
    if (typeof v === "string" && !isNull(v)) {
      const raw = v.trim();
      if (DELIVERY_STATE_VALUES.has(raw)) {
        pds.deliveryState = raw;
      } else {
        pds.parseWarnings.push(
          deliveryId + ": unknown delivery_state '" + raw + "'; expected one of " +
          Array.from(DELIVERY_STATE_VALUES).sort().join(", ")
        );
      }
    }

    v = data.gate_tier;
    if (typeof v === "string" && !isNull(v)) {
      const split = v.trim().split(/\s+/);
      if (split.length && split[0]) pds.gateReviewerTier = split[0];
    }

    v = data.gate_grade;
    if (typeof v === "string" && !isNull(v)) {
      const split = v.trim().split(/\s+/);
      // Treat "Pending" placeholder as absent grade (pre-existing rule).
      if (split.length && split[0] && split[0].toLowerCase() !== "pending") {
        pds.gateGrade = split[0];
      }
    }

    v = data.gate_timestamp;
    if (typeof v === "string" && !isNull(v)) {
      pds.gateTimestamp = v.trim();
    }

    const deliveryLifecycle = data.delivery_lifecycle;
    if (deliveryLifecycle && typeof deliveryLifecycle === "object" && !Array.isArray(deliveryLifecycle)) {
      v = deliveryLifecycle.updated;
      if (typeof v === "string") pds.updated = isNull(v) ? null : v;
      v = deliveryLifecycle.block_reason;
      if (typeof v === "string") pds.blockReason = isNull(v) ? null : v;
      v = deliveryLifecycle.block_artifact;
      if (typeof v === "string") pds.blockArtifact = isNull(v) ? null : v;
    }

    const deliveryGate = data.delivery_gate;
    if (deliveryGate && typeof deliveryGate === "object" && !Array.isArray(deliveryGate)) {
      const issueList = deliveryGate.issue_list;
      if (Array.isArray(issueList)) {
        pds.deliveryGateIssueList = issueList.filter((i) => typeof i === "string");
      }
    }

    const qaList = data.qa;
    if (Array.isArray(qaList)) {
      for (const entry of qaList) {
        if (!entry || typeof entry !== "object" || Array.isArray(entry)) continue;
        const stateVal = entry.state;
        if (typeof stateVal === "string" && stateVal.trim().toLowerCase() === "pending") {
          pds.pendingInputs.push({
            question_id: qaQuestionId(entry.id),
            category: noneIfNull(entry.category),
            impact: noneIfNull(entry.impact),
            context: noneIfNull(entry.context),
            suggested: noneIfNull(entry.suggested),
          });
        }
      }
    }
  } catch (exc) {
    pds.parseWarnings.push(
      deliveryId + ": error parsing delivery STATE.yml (" + exc + "); returning best-effort delivery state"
    );
  }

  return pds;
}

// ---------------------------------------------------------------------------
// feature-001 (flattened single-delivery layout): `tasks_lifecycle` mapping
// read. Twin of Python parse_tasks_lifecycle_md().
//
// The flat layout has no per-task STATE.yml and no per-delivery STATE.yml --
// the promoted delivery_lifecycle / delivery_gate keys (read above via
// _parseDeliveryStateMd, unchanged) plus a tasks_lifecycle mapping (keyed by
// task-NNN, D-3 shape S3) live directly in the work-root STATE.yml. This
// mapping REPLACES the per-task STATE.yml's top-level scalars for the
// flattened path. Called ONLY by the flat reader path (_readWorkFlat).
// ---------------------------------------------------------------------------

function parseTasksLifecycleMd(text) {
  // Returns [taskIdLowerToState, parseWarnings] where taskIdLowerToState maps
  // task_id.toLowerCase() -> { state, review, elapsed, notes, displayName }.
  // Never throws (NFR7).
  const result = {};
  const warnings = [];

  try {
    const [data, docWarnings] = parseStateDocument(text, { fileLabel: "STATE.yml" });
    warnings.push(...docWarnings);

    const tasksLifecycle = data.tasks_lifecycle;
    if (tasksLifecycle && typeof tasksLifecycle === "object" && !Array.isArray(tasksLifecycle)) {
      for (const [taskId, fields] of Object.entries(tasksLifecycle)) {
        if (!fields || typeof fields !== "object" || Array.isArray(fields)) continue;

        function field(name) {
          const v = fields[name];
          if (typeof v === "string") return isNull(v) ? null : v;
          return null;
        }

        result[String(taskId).toLowerCase()] = {
          state: parseTaskStatus(field("state") || ""),
          review: field("review"),
          elapsed: field("elapsed"),
          notes: field("notes"),
          displayName: field("display_name"),
        };
      }
    }
  } catch (exc) {
    warnings.push("error parsing 'tasks_lifecycle' mapping (" + exc + "); returning best-effort");
  }

  return [result, warnings];
}

function _parseTaskSpecShortName(specText) {
  // Extract the short name from a task-level DETAIL.md.
  // Mirror parsers.py _parse_task_spec_short_name.
  // Reads: '# task-NNN: {Title}' -- returns the title portion, or null.
  try {
    const RE_TITLE = /^#\s+task-\d+\s*:\s*(.+)$/i;
    for (const line of specText.split("\n")) {
      const stripped = line.trim();
      if (!stripped) continue;
      const m = stripped.match(RE_TITLE);
      if (m) {
        const title = m[1].trim().replace(/\.$/, "");
        return title || null;
      }
      break; // first non-blank line didn't match
    }
  } catch (_) {
    // pass
  }
  return null;
}

function _parseTaskSpecType(specText) {
  // Extract the task type from a task-level DETAIL.md.
  // Mirror parsers.py _parse_task_spec_type.
  // Reads: '**Type:** VALUE' line -- returns the type string, or ''.
  try {
    const RE_TYPE = /^\*\*Type:\*\*\s*(.+)/i;
    for (const line of specText.split("\n")) {
      const m = line.trim().match(RE_TYPE);
      if (m) {
        const parts = m[1].trim().split(/\s+/);
        return parts[0] || "";
      }
    }
  } catch (_) {
    // pass
  }
  return "";
}

export function _deriveLanesFromDetails(details) {
  // Derive {taskId: wave} from task DETAIL bodies, by topological sort.
  // Mirror reader.py _derive_lanes_from_details.
  //
  // `details` maps a task id ('task-001') to that task's DETAIL.md text. Each task's
  // `**Depends on:**` field IS the graph, so a work needs no stored execution graph to
  // have one: the flattened/Lite layout has a single delivery and therefore no
  // sequencing decision to record.
  //
  // Mirrors canonical/aid/scripts/execute/derive-waves.sh, whose awk pass is the
  // reference implementation, INCLUDING its two non-obvious rules:
  //   - a dependency naming a task absent from `details` is treated as already
  //     SATISFIED, since deliveries run in series
  //   - waves start at 1 and every task lands in exactly one wave
  //
  // A CYCLE yields {} rather than a partial map or a throw (NFR7): a partial map would
  // show some tasks laned and others not, reading as a problem with the tasks rather
  // than with the graph.
  try {
    const depRe = /^\*\*Depends on:\*\*(.*)$/im;
    const taskRe = /task-\d+/gi;

    const deps = {};
    for (const [taskId, text] of Object.entries(details)) {
      const key = taskId.toLowerCase();
      const found = new Set();
      const m = (text || "").match(depRe);
      if (m) {
        for (const hit of m[1].match(taskRe) || []) found.add(hit.toLowerCase());
      }
      // A task never depends on itself; a self-edge would deadlock the sort.
      found.delete(key);
      deps[key] = found;
    }

    const lanes = {};
    const total = Object.keys(deps).length;
    let wave = 0;
    while (Object.keys(lanes).length < total) {
      wave++;
      const ready = Object.keys(deps).filter((t) => {
        if (t in lanes) return false;
        for (const x of deps[t]) {
          if (!(x in lanes) && x in deps) return false;
        }
        return true;
      });
      if (ready.length === 0) return {};   // cycle
      for (const t of ready) lanes[t] = wave;
    }
    return lanes;
  } catch (_) {
    return {};
  }
}

// Exported for the cross-runtime parity test only (its Python twin is importable as
// a module-level function, so the Node side must be reachable too). Not part of the
// reader's consumed surface -- readRepo/readRepoDetail call it internally.
export function _parsePlanDeliveryTitles(planText) {
  // Map deliveryId -> title from PLAN.md's delivery stanzas.
  // Mirror reader.py _parse_plan_delivery_titles.
  //
  // PLAN.md now carries the delivery DEFINITION, so its stanza is the title's home;
  // the retired per-delivery BLUEPRINT.md H1 is only consulted for works created
  // before the fold.
  //
  // Two spellings, because the two layouts spell the stanza differently and both are
  // current:
  //   - nested:    '### delivery-001: Some Title'
  //   - flattened: '- **Delivery:** delivery-001 -- Some Title'
  // The flattened PLAN.md emits NO '### delivery-NNN' heading by design, so the
  // bullet form is the only one it has.
  //
  // Template placeholders ('{Name}') are rejected, matching _parseDeliverySpecTitle.
  const titles = {};
  try {
    const heading = /^#{2,}\s+(delivery-\d+)\s*:\s*(.+?)\s*$/i;
    // Em dash written as \u2014, not literally: this file is ASCII-only enforced
    // (test-ascii-only.sh). The escape is the same character to the regex engine.
    const bullet = /^[-*]\s+\*\*Delivery:\*\*\s*(delivery-\d+)\s*(?:--|\u2014|-)\s*(.+?)\s*$/i;
    for (const line of planText.split("\n")) {
      const stripped = line.trim();
      const m = stripped.match(heading) || stripped.match(bullet);
      if (!m) continue;
      const deliveryId = m[1].toLowerCase();
      const title = m[2].trim();
      // First stanza wins, as in the Python twin.
      if (title && !title.startsWith("{") && !(deliveryId in titles)) {
        titles[deliveryId] = title;
      }
    }
  } catch (_) {
    return {};
  }
  return titles;
}

function _parseDeliverySpecTitle(specText) {
  // Extract the delivery title from a delivery-level BLUEPRINT.md.
  // Mirror parsers.py _parse_delivery_spec_title.
  // Returns the title portion after '# ... delivery-NNN: Title', or null.
  //
  // LEGACY source, kept for works created before the delivery definition folded
  // into PLAN.md's stanza. Callers prefer the PLAN.md title and only fall back here.
  try {
    for (const line of specText.split("\n")) {
      const stripped = line.trim();
      if (!stripped.startsWith("#")) continue;
      const m = stripped.match(/^#+\s+.*delivery-\d+\s*:\s*(.+)$/i);
      if (m) {
        const title = m[1].trim();
        if (title && !title.startsWith("{")) return title;
      }
      break; // only check the first heading line
    }
  } catch (_) {
    // pass
  }
  return null;
}

function _readWorkFlat(workDir, workId) {
  // Mirror reader.py _read_work_flat.
  //
  // Assemble a WorkModel from the FLATTENED single-delivery layout (feature-001).
  //
  // Reads:
  //   - workDir/STATE.yml                 -- work-level lifecycle/history, PLUS the
  //                                           promoted delivery_lifecycle (tasks_lifecycle)
  //                                           / delivery_gate AUTHORED keys (single writer;
  //                                           no deliveries/ wrapper)
  //   - workDir/tasks/task-NNN/DETAIL.md  -- task type / short-name (no per-task STATE.yml --
  //                                           mutable cells come from the work STATE.yml
  //                                           tasks_lifecycle mapping)
  //   - workDir/BLUEPRINT.md              -- the single delivery's title (synthesized
  //                                           DeliverableRef name)
  //
  // Synthesizes exactly ONE DeliverableRef for delivery-001 (every task gets
  // wave="delivery-001", delivery=1) -- there is no deliveries/ wrapper to enumerate.
  //
  // pendingInputs is taken from pw.pendingInputs ONLY -- see reader.py docstring for
  // why _parseDeliveryStateMd's own qa scan is intentionally NOT unioned here (would
  // double-count the work's single shared qa list).
  //
  // Returns [workModel, parseWarnings, bytesRead, stateText, stateLabel]. Never raises.
  const stateLabel = ".aid/works/" + workId + "/STATE.yml";
  const parseWarnings = [];
  let bytesRead = 0;

  const statePath = join(workDir, "STATE.yml");
  let workText = "";
  let workIsFile = false;
  try { workIsFile = statSync(statePath).isFile(); } catch (_) { workIsFile = false; }

  if (!workIsFile) {
    parseWarnings.push(
      workId + ": STATE.yml not found (flat mode); work-level lifecycle will be Unknown."
    );
  } else {
    try {
      const raw = readFileBounded(statePath);
      bytesRead += raw.length;
      workText = raw.toString("utf-8");
    } catch (exc) {
      parseWarnings.push(
        workId + ": STATE.yml read error (" + exc + "); work-level lifecycle will be Unknown."
      );
    }
  }

  const pw = parseStateMd(workText, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);
  const workNumber = numberFromWorkId(workId);

  // Identity fields: REQUIREMENTS.md -> SPEC.md fallback (PF-8, unchanged)
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // PF-5: parse PLAN.md execution graph for lane assignments. The flat PLAN.md's
  // top-level ## Execution Graph carries no wave-map fence / "### delivery-NNN
  // Execution Graph" prose header, so this yields an empty map. It is no longer the
  // last word: an empty map is filled by deriving lanes from the task DETAILs below,
  // which is why this is `let` and not `const`.
  const planPath = join(workDir, "PLAN.md");
  let [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // Parse the promoted delivery_lifecycle / delivery_gate keys from the SAME
  // work-root STATE.yml text via the existing _parseDeliveryStateMd -- it reads the
  // exact keys regardless of which file they live in. Only pds.deliveryState is
  // used (see function comment for why pds.pendingInputs is not unioned).
  const pds = _parseDeliveryStateMd(workText, "delivery-001");
  parseWarnings.push(...pds.parseWarnings);

  // Parse the promoted tasks_lifecycle mapping (replaces per-task STATE.yml)
  const [tasksLifecycle, tlWarnings] = parseTasksLifecycleMd(workText);
  parseWarnings.push(...tlWarnings);

  // -----------------------------------------------------------------------
  // Enumerate tasks/task-NNN/ directly under the work root (no deliveries/
  // wrapper -- the flat layout's single delivery is implicit/synthesized)
  // -----------------------------------------------------------------------
  const allTasks = [];
  const tasksDir = join(workDir, "tasks");
  let taskDirEntries = [];

  try {
    let tasksDirExists = false;
    try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }
    if (tasksDirExists) {
      const entries = readdirSync(tasksDir);
      for (const tname of entries) {
        if (!RE_TASK_DIR_H.test(tname)) continue;
        const tpath = join(tasksDir, tname);
        let isDir = false;
        try { isDir = statSync(tpath).isDirectory(); } catch (_) { isDir = false; }
        if (isDir) taskDirEntries.push([tname, tpath]);
      }
      taskDirEntries.sort((a, b) => a[0].localeCompare(b[0]));
    }
  } catch (exc) {
    parseWarnings.push(workId + ": could not enumerate flat task dirs (" + exc + "); tasks will be empty.");
    taskDirEntries = [];
  }

  // Read every DETAIL.md ONCE, up front. Mirror reader.py: the per-task fields come
  // from these texts, and the same texts derive the lane map -- the graph is the set of
  // `**Depends on:**` fields, so it cannot be known until all of them are in hand.
  const detailTexts = {};
  for (const [taskIdStr, taskDir] of taskDirEntries) {
    const taskDetailPath = join(taskDir, "DETAIL.md");
    let isFile = false;
    try { isFile = statSync(taskDetailPath).isFile(); } catch (_) { isFile = false; }
    if (!isFile) continue;
    try {
      const raw = readFileBounded(taskDetailPath);
      bytesRead += raw.length;
      detailTexts[taskIdStr] = raw.toString("utf-8");
    } catch (_) {
      // pass
    }
  }

  // Lanes on this layout are DERIVED, not read -- see reader.py for the full rationale.
  // An authored map, where one exists, still wins; this only fills an empty one.
  if (Object.keys(taskLaneMap).length === 0) {
    taskLaneMap = _deriveLanesFromDetails(detailTexts);
  }

  for (const [taskIdStr, taskDir] of taskDirEntries) {
    const detailText = detailTexts[taskIdStr];
    let shortName = null;
    let taskType = "";
    if (detailText !== undefined) {
      shortName = _parseTaskSpecShortName(detailText);
      taskType = _parseTaskSpecType(detailText);
    }

    // Mutable cells from the work-root STATE.yml tasks_lifecycle mapping
    const pts = tasksLifecycle[taskIdStr.toLowerCase()] || {
      state: TaskStatus.Unknown, review: null, elapsed: null, notes: null, displayName: null,
    };

    const laneVal = taskLaneMap[taskIdStr.toLowerCase()];
    const lane = laneVal !== undefined ? laneVal : null;

    allTasks.push({
      task_id: taskIdStr,
      type: taskType,
      wave: "delivery-001",
      status: pts.state,
      review_grade: pts.review,
      elapsed: pts.elapsed,
      notes: pts.notes,
      short_name: shortName,
      delivery: 1,
      lane: lane,
      display_name: pts.displayName,
      stop_requested: _taskStopRequested(workDir, workId, taskIdStr),
    });
  }

  // ---- Synthesize the single DeliverableRef for delivery-001 ----
  const blueprintPath = join(workDir, "BLUEPRINT.md");
  let deliveryName = "delivery-001";
  let blueprintIsFile = false;
  try { blueprintIsFile = statSync(blueprintPath).isFile(); } catch (_) { blueprintIsFile = false; }

  if (blueprintIsFile) {
    try {
      const raw = readFileBounded(blueprintPath);
      bytesRead += raw.length;
      const bpText = raw.toString("utf-8");
      const bpName = _parseDeliverySpecTitle(bpText);
      if (bpName) deliveryName = bpName;
    } catch (_) {
      // pass
    }
  }

  const deliverables = [{
    number: 1,
    name: deliveryName,
    task_count: allTasks.length,
    delivery_state: pds.deliveryState,
  }];

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: allTasks,
    pending_inputs: pw.pendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    work_path: pw.workPath || "lite",
    recipe: pw.recipe,
    features: pw.features,
    deliverables: deliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, workText, stateLabel];
}

function _readWorkHierarchical(workDir, workId) {
  // Mirror reader.py _read_work_hierarchical.
  // Assemble a WorkModel from the per-unit STATE.yml hierarchy.
  // Returns [workModel, parseWarnings, bytesRead, stateText, stateLabel].
  const stateLabel = ".aid/works/" + workId + "/STATE.yml";
  const parseWarnings = [];
  let bytesRead = 0;

  // Read work-level STATE.yml (for lifecycle / lifecycle_history)
  const statePath = join(workDir, "STATE.yml");
  let workText = "";
  let workIsFile = false;
  try { workIsFile = statSync(statePath).isFile(); } catch (_) { workIsFile = false; }

  if (!workIsFile) {
    parseWarnings.push(
      workId + ": STATE.yml not found (hierarchical mode); work-level lifecycle will be Unknown."
    );
  } else {
    try {
      const raw = readFileBounded(statePath);
      bytesRead += raw.length;
      workText = raw.toString("utf-8");
    } catch (exc) {
      parseWarnings.push(
        workId + ": STATE.yml read error (" + exc + "); work-level lifecycle will be Unknown."
      );
    }
  }

  // Parse work-level STATE.yml for pipeline/lifecycle fields
  // (tasks[] from this parse are IGNORED in hierarchical mode; per-unit task STATE.yml files
  // are authoritative)
  const pw = parseStateMd(workText, workId, workDir);
  parseWarnings.push(...pw.parseWarnings);

  const name = slugFromWorkId(workId);
  const workNumber = numberFromWorkId(workId);

  // Parse REQUIREMENTS.md / SPEC.md for identity fields
  const reqPath = join(workDir, "REQUIREMENTS.md");
  let [reqTitle, reqDescription, reqObjective, reqBytes] = parseRequirementsMd(reqPath);
  bytesRead += reqBytes;

  if (reqTitle === null || reqDescription === null) {
    const specPath = join(workDir, "SPEC.md");
    const [specTitle, specDescription, specH1, specBytes] = parseSpecMd(specPath);
    bytesRead += specBytes;
    if (reqTitle === null) {
      if (specTitle !== null) {
        reqTitle = specTitle;
      } else if (specH1 !== null) {
        reqTitle = specH1;
      }
    }
    if (reqDescription === null && specDescription !== null) {
      reqDescription = specDescription;
    }
  }

  // Parse PLAN.md for lane assignments
  const planPath = join(workDir, "PLAN.md");
  const [taskLaneMap, planBytes] = parseExecutionGraph(planPath);
  bytesRead += planBytes;

  // Delivery titles come from the same file. Its bytes are NOT added again --
  // parseExecutionGraph above already counted this exact read, and counting it twice
  // would overstate the byte budget. Mirrors reader.py.
  let planDeliveryTitles = {};
  {
    let planIsFile = false;
    try { planIsFile = statSync(planPath).isFile(); } catch (_) { planIsFile = false; }
    if (planIsFile) {
      try {
        planDeliveryTitles = _parsePlanDeliveryTitles(readFileBounded(planPath).toString("utf-8"));
      } catch (_) {
        planDeliveryTitles = {};
      }
    }
  }

  // Enumerate deliveries and their tasks from the hierarchy
  const allTasks = [];
  const allDeliverables = [];
  const allPendingInputs = [];

  let deliveryEntries = [];
  try {
    const deliveriesDir = join(workDir, "deliveries");
    const entries = readdirSync(deliveriesDir);
    for (const name of entries) {
      if (!RE_DELIVERY_DIR.test(name)) continue;
      const fullPath = join(deliveriesDir, name);
      let isDir = false;
      try { isDir = statSync(fullPath).isDirectory(); } catch (_) { isDir = false; }
      if (isDir) deliveryEntries.push([name, fullPath]);
    }
    deliveryEntries.sort((a, b) => a[0].localeCompare(b[0]));
  } catch (exc) {
    parseWarnings.push(workId + ": could not enumerate delivery dirs (" + exc + "); tasks will be empty.");
    deliveryEntries = [];
  }

  for (const [deliveryId, deliveryDir] of deliveryEntries) {
    const dm = deliveryId.match(RE_DELIVERY_DIR);
    const deliveryNumber = dm ? parseInt(dm[1], 10) : 0;

    // Read delivery-level STATE.yml
    const deliveryStatePath = join(deliveryDir, "STATE.yml");
    let deliveryStateText = "";
    let deliveryStateIsFile = false;
    try { deliveryStateIsFile = statSync(deliveryStatePath).isFile(); } catch (_) { deliveryStateIsFile = false; }

    if (deliveryStateIsFile) {
      try {
        const raw = readFileBounded(deliveryStatePath);
        bytesRead += raw.length;
        deliveryStateText = raw.toString("utf-8");
      } catch (exc) {
        parseWarnings.push(
          workId + "/" + deliveryId + ": STATE.yml read error (" + exc + "); delivery lifecycle will be unknown."
        );
      }
    }

    const pds = _parseDeliveryStateMd(deliveryStateText, deliveryId);
    parseWarnings.push(...pds.parseWarnings);
    allPendingInputs.push(...pds.pendingInputs);

    // Enumerate tasks under this delivery
    const tasksDir = join(deliveryDir, "tasks");
    let taskDirEntries = [];
    let tasksDirExists = false;
    try { tasksDirExists = statSync(tasksDir).isDirectory(); } catch (_) { tasksDirExists = false; }

    if (tasksDirExists) {
      try {
        const entries = readdirSync(tasksDir);
        for (const tname of entries) {
          if (!RE_TASK_DIR_H.test(tname)) continue;
          const tpath = join(tasksDir, tname);
          let isDir = false;
          try { isDir = statSync(tpath).isDirectory(); } catch (_) { isDir = false; }
          if (isDir) taskDirEntries.push([tname, tpath]);
        }
        taskDirEntries.sort((a, b) => a[0].localeCompare(b[0]));
      } catch (exc) {
        parseWarnings.push(workId + "/" + deliveryId + ": could not enumerate task dirs (" + exc + ").");
        taskDirEntries = [];
      }
    }

    let deliveryTaskCount = 0;
    for (const [taskIdStr, taskDir] of taskDirEntries) {
      deliveryTaskCount++;

      // Read task-level STATE.yml
      const taskStatePath = join(taskDir, "STATE.yml");
      let taskStateText = "";
      let taskStateIsFile = false;
      try { taskStateIsFile = statSync(taskStatePath).isFile(); } catch (_) { taskStateIsFile = false; }

      if (taskStateIsFile) {
        try {
          const raw = readFileBounded(taskStatePath);
          bytesRead += raw.length;
          taskStateText = raw.toString("utf-8");
        } catch (exc) {
          parseWarnings.push(
            workId + "/" + deliveryId + "/" + taskIdStr + ": STATE.yml read error (" + exc + "); task state will be Unknown."
          );
        }
      }

      const pts = _parseTaskStateMd(taskStateText, taskIdStr);
      parseWarnings.push(...pts.parseWarnings);

      // Read task DETAIL.md for short_name and type
      const taskSpecPath = join(taskDir, "DETAIL.md");
      let shortName = null;
      let taskType = "";
      let taskSpecIsFile = false;
      try { taskSpecIsFile = statSync(taskSpecPath).isFile(); } catch (_) { taskSpecIsFile = false; }

      if (taskSpecIsFile) {
        try {
          const raw = readFileBounded(taskSpecPath);
          bytesRead += raw.length;
          const specText = raw.toString("utf-8");
          shortName = _parseTaskSpecShortName(specText);
          taskType = _parseTaskSpecType(specText);
        } catch (_) {
          // pass
        }
      }

      // Lane from PLAN.md wave-map
      const laneVal = taskLaneMap[taskIdStr.toLowerCase()];
      const lane = laneVal !== undefined ? laneVal : null;

      allTasks.push({
        task_id: taskIdStr,
        type: taskType,
        wave: deliveryId,        // wave = delivery-NNN in hierarchical works
        status: pts.state,
        review_grade: pts.review,
        elapsed: pts.elapsed,
        notes: pts.notes,
        short_name: shortName,
        delivery: deliveryNumber,
        lane: lane,
        display_name: pts.displayName,
        stop_requested: _taskStopRequested(workDir, workId, taskIdStr),
      });
    }

    // Build DeliverableRef for this delivery.
    // Title resolution: PLAN.md stanza -> legacy BLUEPRINT.md H1 -> deliveryId.
    // PLAN.md's stanza is the delivery definition now, so it is authoritative; the
    // BLUEPRINT read survives only for works predating the fold.
    let deliveryName = deliveryId;
    const planTitle = planDeliveryTitles[deliveryId.toLowerCase()];
    if (planTitle) {
      deliveryName = planTitle;
    } else {
      const deliverySpecPath = join(deliveryDir, "BLUEPRINT.md");
      let deliverySpecIsFile = false;
      try { deliverySpecIsFile = statSync(deliverySpecPath).isFile(); } catch (_) { deliverySpecIsFile = false; }

      if (deliverySpecIsFile) {
        try {
          const raw = readFileBounded(deliverySpecPath);
          bytesRead += raw.length;
          const specText = raw.toString("utf-8");
          const specName = _parseDeliverySpecTitle(specText);
          if (specName) deliveryName = specName;
        } catch (_) {
          // pass
        }
      }
    }

    allDeliverables.push({
      number: deliveryNumber,
      name: deliveryName,
      task_count: deliveryTaskCount,
      delivery_state: pds.deliveryState,
    });
  }

  // Work-level pending_inputs: union of work-level Q&A + per-delivery Q&A
  const unionPendingInputs = [...pw.pendingInputs, ...allPendingInputs];

  const workModel = _buildWorkModel({
    work_id: workId,
    name,
    lifecycle: pw.lifecycle,
    phase: pw.phase,
    active_skill: pw.activeSkill,
    updated: pw.updated,
    created: pw.created,
    pause_reason: pw.pauseReason,
    block_reason: pw.blockReason,
    block_artifact: pw.blockArtifact,
    tasks: allTasks,
    pending_inputs: unionPendingInputs,
    source_mode: pw.sourceMode,
    number: workNumber,
    title: reqTitle,
    description: reqDescription,
    objective: reqObjective,
    // work_path: frontmatter `pipeline.path` first; else "full" -- the
    // hierarchical deliveries/ wrapper only exists for full multi-delivery
    // works, so layout detection is a sound fallback default here (symmetric
    // with _readWorkFlat's `pw.workPath || "lite"` fallback above).
    work_path: pw.workPath || "full",
    recipe: pw.recipe,
    features: pw.features,
    deliverables: allDeliverables,
    kind: pw.kind,
    started: pw.started,
    minimum_grade: pw.minimumGrade,
    user_approved: pw.userApproved,
  });

  return [workModel, parseWarnings, bytesRead, workText, stateLabel];
}

// ---------------------------------------------------------------------------
// work-004 Pillar 5: Same-work reconcile (no winner) -- mirror reader.py
// ---------------------------------------------------------------------------

function _pipelineWinnerSortKey(updated, branchLabel) {
  // Shared Pipeline-State winner-rule sort key (SD-2 / Pillar 5 step 2); mirror
  // reader.py _pipeline_winner_sort_key verbatim.
  //
  // Newest `updated` wins; tie -> branch_label lexical sort, "main" first. This
  // is the SINGLE encoding of the winner rule -- used by BOTH _reconcileSameWork
  // (ranking WorkModel copies) and resolveWorkDir (task-002, WT-1: ranking raw
  // worktree candidates) so the "same winner rule" invariant holds by
  // construction rather than by two independently-maintained copies.
  //
  // Key: [tier, invUpdated, secondary]
  //   tier=0 if updated present, tier=1 if absent.
  //   invUpdated: char-complement so larger (newer) timestamp sorts smaller (ascending).
  //   secondary: [0, ""] for "main", else [1, label].
  const upd = updated || "";
  const label = branchLabel || "";
  const secondary = label === "main" ? [0, ""] : [1, label];
  if (upd) {
    const invUpdated = upd.split("").map(c => {
      const cp = c.charCodeAt(0);
      return String.fromCharCode(0x7F - Math.min(cp, 0x7F));
    }).join("");
    return [0, invUpdated, secondary];
  }
  return [1, "", secondary];
}

function _pipelineWinnerKeyCmp(ka, kb) {
  // Compare two keys returned by _pipelineWinnerSortKey.
  if (ka[0] !== kb[0]) return ka[0] - kb[0];
  if (ka[1] < kb[1]) return -1;
  if (ka[1] > kb[1]) return 1;
  const [sat, sal] = ka[2];
  const [sbt, sbl] = kb[2];
  if (sat !== sbt) return sat - sbt;
  if (sal < sbl) return -1;
  if (sal > sbl) return 1;
  return 0;
}

function _reconcileSameWork(copies) {
  // Merge N WorkModel copies for the same work_id into one reconciled model.
  //
  // copies: array of [WorkModel, stateText, stateLabel] tuples.
  // Returns [reconciledWorkModel, winningStateText, winningStateLabel].
  //
  // Reconcile rules (Pillar 5 / SD-2):
  //   1. Per-task State: most-advanced by SD2_RANK (lower rank wins).
  //   2. Work-level Pipeline State: newest Updated; tie -> branch_label sort, "main" first.
  //   3. Derived views (tasks, pending_inputs, deliverables, features): UNION.
  //   4. Identity fields: from the Pipeline-State winner.
  //   5. source_mode: Normalized if any copy is Normalized.
  //
  // Deterministic and order-independent. Never throws.

  if (copies.length === 1) return copies[0];

  // Step 1: union tasks, picking the most-advanced state per task_id
  const bestTask = {}; // lower-cased task_id -> task model
  for (const [wm] of copies) {
    for (const task of wm.tasks) {
      const tid = task.task_id.toLowerCase();
      if (!(tid in bestTask)) {
        bestTask[tid] = task;
      } else {
        const currentRank = _sd2Rank(bestTask[tid].status);
        const candidateRank = _sd2Rank(task.status);
        if (candidateRank < currentRank) {
          bestTask[tid] = task;
        }
      }
    }
  }
  // Sort deterministically by task_id (input-order-independent)
  const mergedTasks = Object.values(bestTask).sort(
    (a, b) => a.task_id.toLowerCase().localeCompare(b.task_id.toLowerCase())
  );

  // Step 2: pick the Pipeline-State winner by newest Updated timestamp.
  // Tie-break: branch_label lexical sort, "main" sorting first.
  // The sort key itself is the shared _pipelineWinnerSortKey (see its comment
  // above) -- reused verbatim by resolveWorkDir (task-002).
  function _pipelineWinnerKey(entry) {
    const wm = entry[0];
    return _pipelineWinnerSortKey(wm.updated, wm.branch_label);
  }

  function _keyCmp(a, b) {
    return _pipelineWinnerKeyCmp(_pipelineWinnerKey(a), _pipelineWinnerKey(b));
  }

  const sortedCopies = copies.slice().sort(_keyCmp);
  const [winnerWm, winnerText, winnerLabel] = sortedCopies[0];

  // Step 3: union pending_inputs (all copies contribute)
  const seenQIds = new Set();
  const mergedPending = [];
  for (const [wm] of copies) {
    for (const pi of wm.pending_inputs) {
      if (!seenQIds.has(pi.question_id)) {
        seenQIds.add(pi.question_id);
        mergedPending.push(pi);
      }
    }
  }

  // Step 3b: union deliverables (by delivery number; winner's entry wins on duplicates)
  const seenDel = new Set();
  const mergedDeliverables = [];
  for (const dr of winnerWm.deliverables) {
    if (!seenDel.has(dr.number)) {
      seenDel.add(dr.number);
      mergedDeliverables.push(dr);
    }
  }
  for (const [wm] of copies) {
    if (wm === winnerWm) continue;
    for (const dr of wm.deliverables) {
      if (!seenDel.has(dr.number)) {
        seenDel.add(dr.number);
        mergedDeliverables.push(dr);
      }
    }
  }
  mergedDeliverables.sort((a, b) => a.number - b.number);

  // Step 3c: union features (by feature number; winner first)
  const seenFeat = new Set();
  const mergedFeatures = [];
  for (const fr of winnerWm.features) {
    if (!seenFeat.has(fr.number)) {
      seenFeat.add(fr.number);
      mergedFeatures.push(fr);
    }
  }
  for (const [wm] of copies) {
    if (wm === winnerWm) continue;
    for (const fr of wm.features) {
      if (!seenFeat.has(fr.number)) {
        seenFeat.add(fr.number);
        mergedFeatures.push(fr);
      }
    }
  }

  // Step 4 + 5: build reconciled WorkModel from winner's fields + merged views.
  // source_mode: Normalized if any copy is Normalized.
  let mergedSourceMode = winnerWm.source_mode;
  for (const [wm] of copies) {
    if (wm.source_mode === SourceMode.Normalized) {
      mergedSourceMode = SourceMode.Normalized;
      break;
    }
  }

  const reconciled = _buildWorkModel({
    work_id: winnerWm.work_id,
    name: winnerWm.name,
    lifecycle: winnerWm.lifecycle,
    phase: winnerWm.phase,
    active_skill: winnerWm.active_skill,
    updated: winnerWm.updated,
    created: winnerWm.created,
    pause_reason: winnerWm.pause_reason,
    block_reason: winnerWm.block_reason,
    block_artifact: winnerWm.block_artifact,
    tasks: mergedTasks,
    pending_inputs: mergedPending,
    source_mode: mergedSourceMode,
    number: winnerWm.number,
    title: winnerWm.title,
    description: winnerWm.description,
    objective: winnerWm.objective,
    work_path: winnerWm.work_path,
    recipe: winnerWm.recipe,
    features: mergedFeatures,
    deliverables: mergedDeliverables,
    // branch_label: null on a reconciled model (multiple branches contributed)
    branch_label: null,
    kind: winnerWm.kind,
    started: winnerWm.started,
    minimum_grade: winnerWm.minimum_grade,
    user_approved: winnerWm.user_approved,
  });

  return [reconciled, winnerText, winnerLabel];
}

// ---------------------------------------------------------------------------
// Worktree-aware work-directory resolver (WT-1) -- task-002; mirror reader.py
// resolve_work_dir / _peek_work_updated verbatim.
// ---------------------------------------------------------------------------

export function resolveWorkDir(servedRoot, workId) {
  // Resolve workId to the REAL on-disk work directory (worktree-aware; WT-1).
  //
  // Reuses _enumerateWorktreeRoots to walk the served repo's git worktrees,
  // selects every worktree whose <wt>/.aid/works/<workId> exists, and applies
  // the SAME winner rule as _reconcileSameWork step 2 (the shared
  // _pipelineWinnerSortKey: newest `updated` wins; tie -> branch_label lexical,
  // "main" first) -- so the directory returned is the very copy the reader
  // would render for this work_id (a write hits exactly what the reader
  // rendered).
  //
  // Returns null when no worktree of the served repo holds workId (the caller
  // maps this to 404 -- the reader would not have rendered this work either).
  // Inherits the reader's SD-3 degradation (git absent / non-git -> main-root-
  // only) via _enumerateWorktreeRoots, so this resolver can only ever be asked
  // to target a work the reader itself surfaced -- consistency by construction.
  //
  // servedRoot may be the repo root or a path ending in ".aid" (same convention
  // as readRepo). The caller is responsible for validating workId's shape
  // (^work-[0-9]+) before calling -- this function only resolves an
  // already-validated id to a directory; it never reconstructs a served-tree
  // path itself (each candidate directory comes verbatim from
  // _enumerateWorktreeRoots's real on-disk .aid dir).
  //
  // Read-only. Never throws.
  let root = resolve(servedRoot);
  if (basename(root) === ".aid") {
    root = resolve(root, "..");
  }

  const worktreeRoots = _enumerateWorktreeRoots(root);

  // [updated, branchLabel, workDir] for every worktree that actually holds workId.
  const candidates = [];
  for (const [branchLabel, wtAidDir] of worktreeRoots) {
    const workDir = join(wtAidDir, "works", workId);
    let isDir = false;
    try {
      isDir = statSync(workDir).isDirectory();
    } catch (_) {
      isDir = false;
    }
    if (!isDir) continue;
    candidates.push([_peekWorkUpdated(workDir, workId), branchLabel, workDir]);
  }

  if (candidates.length === 0) return null;

  candidates.sort((a, b) =>
    _pipelineWinnerKeyCmp(
      _pipelineWinnerSortKey(a[0], a[1]),
      _pipelineWinnerSortKey(b[0], b[1])
    )
  );
  return candidates[0][2];
}

function _peekWorkUpdated(workDir, workId) {
  // Best-effort read of a work directory's Pipeline State `updated` field.
  // Used only by resolveWorkDir to break ties between worktree copies of the
  // same work_id (the winner rule needs `updated`, not a full WorkModel). Reads
  // workDir/STATE.yml -- present regardless of monolithic/flat/hierarchical
  // layout, since all three read the work-root STATE.yml for lifecycle --
  // and parses it with the SAME parseStateMd() the always-on read path uses.
  //
  // Returns null on a missing STATE.yml or any read/parse failure; never
  // throws. A null result only affects tie-break ordering, never candidate
  // inclusion -- the work_id directory's presence is the sole inclusion test
  // (WT-1).
  const statePath = join(workDir, "STATE.yml");
  let isFile = false;
  try {
    isFile = statSync(statePath).isFile();
  } catch (_) {
    isFile = false;
  }
  if (!isFile) return null;
  try {
    const raw = readFileBounded(statePath);
    const text = raw.toString("utf-8");
    return parseStateMd(text, workId, workDir).updated;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Object builders -- FIELD ORDER matches Python dataclasses EXACTLY (DM-3)
// V8 preserves string-key insertion order; order here IS the serialization order.
// ---------------------------------------------------------------------------

function _buildToolInfo(ti) {
  // ToolInfo field order (models.py): manifest_present, aid_version, installed_at, tools_installed
  return {
    manifest_present: ti.manifest_present,
    aid_version: ti.aid_version,
    installed_at: ti.installed_at,
    tools_installed: ti.tools_installed,
  };
}

function _buildKbBaseline(bl) {
  // KbBaseline field order: branch, tip_date
  if (bl === null || bl === undefined) return null;
  return {
    branch:   bl.branch !== undefined ? bl.branch : null,
    tip_date: bl.tip_date !== undefined ? bl.tip_date : null,
  };
}

function _buildKbStateRef(kb) {
  if (kb === null) return null;
  // KbStateRef field order (DM-A3 deterministic, task-064):
  //   retained: summary_approved, last_summary_date, doc_count
  //   new:      status, summary_present, kb_baseline
  // task-042 additions: doc_freshness, suspect_count
  // work-003-state-schema task-002 additions: source_mode, kb_status, kb_grade,
  //   last_kb_review
  return {
    summary_approved:  kb.summary_approved,
    last_summary_date: kb.last_summary_date,
    doc_count:         kb.doc_count,
    status:            kb.status !== undefined ? kb.status : KbStatus.unknown,
    summary_present:   kb.summary_present !== undefined ? kb.summary_present : false,
    kb_baseline:       _buildKbBaseline(kb.kb_baseline),
    doc_freshness:     Array.isArray(kb.doc_freshness) ? kb.doc_freshness.map(_buildDocFreshness) : [],
    suspect_count:     typeof kb.suspect_count === "number" ? kb.suspect_count : 0,
    source_mode:       kb.source_mode !== undefined ? kb.source_mode : SourceMode.Fallback,
    kb_status:         kb.kb_status !== undefined ? kb.kb_status : null,
    kb_grade:          kb.kb_grade !== undefined ? kb.kb_grade : null,
    last_kb_review:    kb.last_kb_review !== undefined ? kb.last_kb_review : null,
  };
}

function _buildDocFreshness(df) {
  // DocFreshness field order: doc, verdict, suspect_sources
  // Twin of Python DocFreshness dataclass (models.py, task-042).
  return {
    doc:             df.doc,
    verdict:         df.verdict,
    suspect_sources: Array.isArray(df.suspect_sources) ? df.suspect_sources : [],
  };
}

function _buildConnectorRef(cr) {
  // ConnectorRef field order: stem, name, connection_type, endpoint,
  // auth_method, secret_reference, summary (feature-007, task-019).
  // Twin of Python ConnectorRef dataclass (models.py).
  return {
    stem:              cr.stem,
    name:              cr.name,
    connection_type:   cr.connection_type,
    endpoint:          cr.endpoint !== undefined ? cr.endpoint : null,
    auth_method:       cr.auth_method !== undefined ? cr.auth_method : null,
    secret_reference:  cr.secret_reference !== undefined ? cr.secret_reference : null,
    summary:           cr.summary !== undefined ? cr.summary : null,
  };
}

function _buildRepoInfo(ri) {
  // RepoInfo field order: project_name, project_description, minimum_grade,
  // aid_dir, kb_state (feature-002, work-017 task-005: two additive keys
  // inserted after project_name; schema_version stays 3), connectors
  // (feature-007, work-017 task-019: additive key inserted AFTER kb_state;
  // schema_version stays 3), external_sources (feature-010, work-017
  // task-021: additive key inserted AFTER connectors; schema_version stays
  // 3). Surfaced ONLY in the DM-1 model -- the DM-2 /api/home entry builder
  // never calls this function.
  return {
    project_name: ri.project_name,
    project_description: ri.project_description !== undefined ? ri.project_description : null,
    minimum_grade: ri.minimum_grade !== undefined ? ri.minimum_grade : null,
    aid_dir: ri.aid_dir,
    kb_state: _buildKbStateRef(ri.kb_state),
    connectors: Array.isArray(ri.connectors) ? ri.connectors.map(_buildConnectorRef) : [],
    external_sources: Array.isArray(ri.external_sources) ? ri.external_sources : [],
  };
}

function _buildPendingInput(pi) {
  // PendingInput field order: question_id, category, impact, context, suggested
  return {
    question_id: pi.question_id,
    category: pi.category,
    impact: pi.impact,
    context: pi.context,
    suggested: pi.suggested,
  };
}

function _buildTaskModel(t) {
  // TaskModel field order: task_id, type, wave, status, review_grade, elapsed, notes,
  //   short_name, delivery, lane  (schema_version 3 fields -- PF-3/PF-5),
  //   display_name (feature-005, work-017 task-008 -- additive, no schema_version bump),
  //   stop_requested (feature-008, work-017 task-029 -- additive derived field, no
  //   schema_version bump)
  return {
    task_id: t.task_id,
    type: t.type,
    wave: t.wave,
    status: t.status,
    review_grade: t.review_grade,
    elapsed: t.elapsed,
    notes: t.notes,
    short_name: t.short_name !== undefined ? t.short_name : null,
    delivery: t.delivery !== undefined ? t.delivery : null,
    lane: t.lane !== undefined ? t.lane : null,
    display_name: t.display_name !== undefined ? t.display_name : null,
    stop_requested: !!t.stop_requested,
  };
}

function _buildFeatureRef(f) {
  // FeatureRef field order: number, name
  return {
    number: f.number,
    name: f.name,
  };
}

function _buildDeliverableRef(d) {
  // DeliverableRef field order: number, name, task_count
  // NOTE: delivery_state (work-004 Pillar 1) is tracked internally but NOT
  // serialized here -- Python server.py _ser_deliverable_ref omits it for parity.
  // Both runtimes emit the same key set until server.py is updated to serialize it.
  return {
    number: d.number,
    name: d.name,
    task_count: d.task_count,
  };
}

function _buildWorkModel(wm) {
  // WorkModel field order: work_id, name, lifecycle, phase, active_skill, updated, created,
  //   pause_reason, block_reason, block_artifact, tasks, pending_inputs, source_mode,
  //   number, title, description, objective, work_path, recipe, features, deliverables,
  //   kind, started, minimum_grade, user_approved (work-003-state-schema task-002)
  //
  // NOTE: branch_label is an internal reconcile field (work-004 Pillar 4) tracked
  // directly on raw objects between readWork() and _reconcileSameWork(); it is NOT
  // included in the serialized output (Python server.py _ser_work omits it for
  // parity -- both runtimes emit the same key set).
  const built = {
    work_id: wm.work_id,
    name: wm.name,
    lifecycle: wm.lifecycle,
    phase: wm.phase,
    active_skill: wm.active_skill,
    updated: wm.updated,
    created: wm.created !== undefined ? wm.created : null,
    pause_reason: wm.pause_reason,
    block_reason: wm.block_reason,
    block_artifact: wm.block_artifact,
    tasks: (wm.tasks || []).map(_buildTaskModel),
    pending_inputs: (wm.pending_inputs || []).map(_buildPendingInput),
    source_mode: wm.source_mode,
    // prototype: work-overview header fields (declared order matches models.py WorkModel)
    number: wm.number !== undefined ? wm.number : null,
    title: wm.title !== undefined ? wm.title : null,
    description: wm.description !== undefined ? wm.description : null,
    objective: wm.objective !== undefined ? wm.objective : null,
    work_path: wm.work_path !== undefined ? wm.work_path : null,
    recipe: wm.recipe !== undefined ? wm.recipe : null,
    features: (wm.features || []).map(_buildFeatureRef),
    deliverables: (wm.deliverables || []).map(_buildDeliverableRef),
    kind: wm.kind !== undefined ? wm.kind : null,
    started: wm.started !== undefined ? wm.started : null,
    minimum_grade: wm.minimum_grade !== undefined ? wm.minimum_grade : null,
    user_approved: wm.user_approved !== undefined ? wm.user_approved : null,
  };
  // Carry branch_label as a non-enumerable property so the reconcile logic can
  // read it (wm.branch_label) without it appearing in JSON.stringify output.
  // This matches Python server.py _ser_work which omits the field entirely.
  Object.defineProperty(built, "branch_label", {
    value: wm.branch_label !== undefined ? wm.branch_label : null,
    writable: true,
    enumerable: false, // excluded from JSON.stringify
    configurable: true,
  });
  return built;
}

function _buildReadMeta(rm) {
  // ReadMeta field order: read_at, work_count, fallback_works, parse_warnings, bytes_read
  return {
    read_at: rm.read_at,
    work_count: rm.work_count,
    fallback_works: rm.fallback_works,
    parse_warnings: rm.parse_warnings,
    bytes_read: rm.bytes_read,
  };
}

function _buildRepoModel({ tool, repo, works, read }) {
  // RepoModel field order: tool, repo, works, read
  return {
    tool: _buildToolInfo(tool),
    repo: _buildRepoInfo(repo),
    works: works.map(_buildWorkModel),
    read: _buildReadMeta(read),
  };
}

// ---------------------------------------------------------------------------
// LC-TR: TaskDetail sub-parsers (feature-008, task-069)
// Detail-only: these run ONLY when detail_task_ids is supplied to readRepoDetail().
// The always-on readRepo() path does NOT call any function below.
// No write / no LLM / no subprocess (NFR2/NFR7).
// ASCII-only source (shipped script posture; coding-standards.md).
// ---------------------------------------------------------------------------

// Severity normalization (twin of _parse_severity in parsers.py). Accepts
// EITHER the bracketed legacy-bullet form ('[HIGH]') or the bare D-4
// structured-field form ('HIGH', the on-disk quick_check.findings[].severity
// value -- no brackets, per the task-state-template.yml comment "severity:
// CRITICAL | HIGH"). Mirrors feature-002 DM-6: lower/unknown -> [MINOR]
// neutral, never throws (NFR7). This is the twin-parity fix task-003 made in
// Python's _parse_severity (the pre-refactor Node version recognized only
// the bracketed form).
function parseSeverity(tag) {
  let normalized = tag.toUpperCase().trim();
  if (!normalized.startsWith("[")) {
    normalized = "[" + normalized + "]";
  }
  if (normalized === "[CRITICAL]" || normalized === "[HIGH]") return normalized;
  return "[MINOR]";
}

// DR-2: read quick_check.findings for the given task_id. Twin of Python
// parse_quick_check_findings() (work-009-refactor task-003, retargeted to
// keys). `quick_check` exists ONLY in a per-task STATE.yml (deliveries/
// delivery-NNN/tasks/task-NNN/STATE.yml), never in the work-root file
// `stateText` is always called with here (via the always-on pass's
// state-text cache -- DR-1/NFR4, no re-read). So `data.quick_check` is
// always absent for a current-shape work and this still returns [] --
// pre-existing staleness preserved, not repaired (SPEC.md L-12).
function parseQuickCheckFindings(stateText, taskId, parseWarnings) {
  const findings = [];

  try {
    const label = taskId ? taskId + "/STATE.yml" : "STATE.yml";
    const [data, docWarnings] = parseStateDocument(stateText, { fileLabel: label });
    parseWarnings.push(...docWarnings);

    const quickCheck = data.quick_check;
    if (quickCheck && typeof quickCheck === "object" && !Array.isArray(quickCheck)) {
      const reviewerTierRaw = quickCheck.reviewer_tier;
      const reviewerTier = typeof reviewerTierRaw === "string" ? reviewerTierRaw : null;
      const rawFindings = quickCheck.findings;
      if (Array.isArray(rawFindings)) {
        for (const f of rawFindings) {
          if (!f || typeof f !== "object" || Array.isArray(f)) continue;
          const severityRaw = f.severity;
          const descriptionRaw = f.description;
          findings.push({
            severity: parseSeverity(typeof severityRaw === "string" ? severityRaw : ""),
            description: typeof descriptionRaw === "string" ? descriptionRaw.trim() : "",
            location: noneIfNull(f.source),
            disposition: noneIfNull(f.disposition),
            reviewer_tier: reviewerTier,
          });
        }
      }
    }
  } catch (exc) {
    parseWarnings.push(
      taskId + ": error parsing 'quick_check' (" + exc + "); " +
      "returning best-effort findings"
    );
  }

  return findings;
}

// DR-3: read delivery_gate (+ top-level gate_grade/gate_tier/gate_timestamp)
// for grade/tier/timestamp. Twin of Python parse_delivery_gate() (work-009-
// refactor task-003, retargeted to keys). `stateText` here is always the
// work-root document (via the state-text cache -- DR-1/NFR4, no re-read);
// `delivery_gate` only ever carries `issue_list` (D-4), so `delivery_gate.
// grade`/`.reviewer_tier`/`.gate_timestamp` are always absent, and this
// still returns (null, null, null) for a current-shape work -- pre-existing
// staleness preserved, not repaired (SPEC.md L-12). The pre-refactor
// singular-vs-plural "## Delivery Gate" / "## Delivery Gates" markdown
// fallback has no YAML counterpart: `delivery_gate` is always a single
// top-level key regardless of full/flat layout, so that distinction is
// gone, not ported.
function parseDeliveryGate(stateText, deliveryId, parseWarnings) {
  let grade = null;
  let reviewerTier = null;
  let gateTimestamp = null;

  try {
    const label = deliveryId ? deliveryId + "/STATE.yml" : "STATE.yml";
    const [data, docWarnings] = parseStateDocument(stateText, { fileLabel: label });
    parseWarnings.push(...docWarnings);

    const gate = data.delivery_gate;
    if (gate && typeof gate === "object" && !Array.isArray(gate)) {
      let v = gate.grade;
      if (typeof v === "string" && v.trim()) {
        grade = v.trim().split(/\s+/)[0];
      }
      v = gate.reviewer_tier;
      if (typeof v === "string" && v.trim()) {
        reviewerTier = v.trim().split(/\s+/)[0];
      }
      v = gate.gate_timestamp;
      if (typeof v === "string" && v.trim()) {
        gateTimestamp = v.trim();
      }
    }
  } catch (exc) {
    parseWarnings.push(
      deliveryId + ": error parsing 'delivery_gate' (" + exc + "); " +
      "returning best-effort gate fields"
    );
  }

  return [grade, reviewerTier, gateTimestamp];
}

// DR-4: parse delivery-NNN-issues.md and filter rows to Source task == task_id
// Twin of parse_deferred_issues in parsers.py (byte-parity minded)
function parseDeferredIssues(issuesPath, taskId, parseWarnings) {
  let isFile = false;
  try { isFile = statSync(issuesPath).isFile(); } catch (_) { isFile = false; }
  if (!isFile) return [];

  let raw;
  try {
    raw = readFileBounded(issuesPath);
  } catch (exc) {
    parseWarnings.push(
      taskId + ": could not read " + basename(issuesPath) + " (" + exc + "); " +
      "deferred_issues will be empty"
    );
    return [];
  }

  const text = raw.toString("utf-8");
  const deferred = [];
  let headerSeen = false;

  try {
    for (const line of text.split("\n")) {
      const stripped = line.trim();
      if (!stripped.startsWith("|")) continue;
      if (RE_TABLE_SEP.test(stripped)) {
        headerSeen = true;
        continue;
      }
      const cols = stripped.replace(/^\||\|$/g, "").split("|").map(c => c.trim());
      if (cols.length < 4) continue;
      if (!headerSeen) {
        headerSeen = true;
        continue;
      }
      const sourceTask = cols[0].trim();
      const severity = cols[1].trim();
      const description = cols[2].trim();
      const status = cols[3].trim();

      if (sourceTask.toLowerCase() === taskId.toLowerCase()) {
        deferred.push({
          source_task: sourceTask,
          severity: severity || "[HIGH]",
          description: description,
          status: status || "Open",
        });
      }
    }
  } catch (exc) {
    parseWarnings.push(
      taskId + ": error parsing " + basename(issuesPath) + " (" + exc + "); " +
      "returning best-effort deferred issues"
    );
  }

  return deferred;
}

// DR-5: stat log/heartbeat paths for honest DM-4 log inventory
// Twin of parse_log_availability in parsers.py (byte-parity minded)
function parseLogAvailability(aidDir) {
  const serverLogPath = join(aidDir, ".temp", "dashboard.log");
  const heartbeatDir = join(aidDir, ".heartbeat");

  let serverLogPresent = false;
  let heartbeatPresent = false;

  try {
    serverLogPresent = statSync(serverLogPath).isFile();
  } catch (_) {
    serverLogPresent = false;
  }

  try {
    heartbeatPresent = statSync(heartbeatDir).isDirectory();
  } catch (_) {
    heartbeatPresent = false;
  }

  return {
    task_logs: "none",
    server_log_present: serverLogPresent,
    heartbeat_present: heartbeatPresent,
  };
}

// Object builders for TaskDetail sub-model (field order matches Python dataclasses, DM-3)

function _buildFinding(f) {
  // Finding field order: severity, description, location, disposition, reviewer_tier
  return {
    severity: f.severity,
    description: f.description,
    location: f.location !== undefined ? f.location : null,
    disposition: f.disposition !== undefined ? f.disposition : null,
    reviewer_tier: f.reviewer_tier !== undefined ? f.reviewer_tier : null,
  };
}

function _buildDeferredIssue(d) {
  // DeferredIssue field order: source_task, severity, description, status
  return {
    source_task: d.source_task,
    severity: d.severity,
    description: d.description,
    status: d.status,
  };
}

function _buildTaskLedger(l) {
  // TaskLedger field order: delivery_id, grade, reviewer_tier, gate_timestamp, deferred_issues
  return {
    delivery_id: l.delivery_id !== undefined ? l.delivery_id : null,
    grade: l.grade !== undefined ? l.grade : null,
    reviewer_tier: l.reviewer_tier !== undefined ? l.reviewer_tier : null,
    gate_timestamp: l.gate_timestamp !== undefined ? l.gate_timestamp : null,
    deferred_issues: (l.deferred_issues || []).map(_buildDeferredIssue),
  };
}

function _buildRawStateRef(r) {
  // RawStateRef field order: text, byte_len, path
  if (r === null || r === undefined) return null;
  return {
    text: r.text,
    byte_len: r.byte_len,
    path: r.path,
  };
}

function _buildLogAvailability(l) {
  // LogAvailability field order: task_logs, server_log_present, heartbeat_present
  if (l === null || l === undefined) return null;
  return {
    task_logs: l.task_logs,
    server_log_present: l.server_log_present,
    heartbeat_present: l.heartbeat_present,
  };
}

function _buildTaskDetail(d) {
  // TaskDetail field order: task_id, findings, ledger, raw_state, logs
  return {
    task_id: d.task_id,
    findings: (d.findings || []).map(_buildFinding),
    ledger: _buildTaskLedger(d.ledger || {}),
    raw_state: _buildRawStateRef(d.raw_state),
    logs: _buildLogAvailability(d.logs),
  };
}

// ---------------------------------------------------------------------------
// readRepoDetail(root, detailTaskIds) -- LC-TR entry point
// Twin of read_repo_detail in reader.py (byte-parity minded, task-069)
// ---------------------------------------------------------------------------

export function readRepoDetail(root, detailTaskIds) {
  // LC-TR: run full always-on pass then attach TaskDetail for requested task_ids.
  // detailTaskIds: array of composite 'work_id/task_id' strings.
  // Returns { model, details } where details is {} when detailTaskIds is empty.
  //
  // DR-1/DD-3/NFR4: STATE.yml bytes are reused from the always-on pass cache.
  // No disk re-read for raw_state. Read-only / no-LLM / no subprocess (NFR2/NFR7).

  // Step 1: run full pass; get STATE.yml cache as by-product (zero extra I/O).
  const { model, stateCache } = _readRepoFull(root);

  if (!detailTaskIds || detailTaskIds.length === 0) {
    return { model: model, details: {} };
  }

  // Normalize root
  let resolvedRoot = resolve(root);
  if (basename(resolvedRoot) === ".aid") {
    resolvedRoot = resolve(resolvedRoot, "..");
  }
  const aidDir = join(resolvedRoot, ".aid");

  // Build index of work models by work_id
  const workIndex = {};
  for (const w of model.works) {
    workIndex[w.work_id] = w;
  }

  const details = {};
  const extraWarnings = [];

  for (const compositeKey of detailTaskIds) {
    const slashIdx = compositeKey.indexOf("/");
    if (slashIdx < 0) {
      extraWarnings.push(
        "detail_task_ids: invalid key '" + compositeKey + "' " +
        "(expected 'work_id/task_id'); skipping"
      );
      continue;
    }

    const workId = compositeKey.slice(0, slashIdx);
    const taskId = compositeKey.slice(slashIdx + 1);

    if (!workId || !taskId) {
      extraWarnings.push(
        "detail_task_ids: empty work_id or task_id in '" + compositeKey + "'; skipping"
      );
      continue;
    }

    const taskWarnings = [];

    // DR-1: get STATE.yml text from the always-on pass cache (no disk re-read).
    // If work_id was not enumerated (detail for a non-enumerated work), use empty
    // text and add a warning -- never re-read from disk (DR-1/DD-3/NFR4).
    let stateText = "";
    let statePathLabel = ".aid/works/" + workId + "/STATE.yml";

    if (stateCache[workId] !== undefined) {
      [stateText, statePathLabel] = stateCache[workId];
    } else {
      taskWarnings.push(
        workId + "/" + taskId + ": work not found in always-on pass; " +
        "STATE.yml unavailable; raw_state will be empty"
      );
    }

    // byte_len: length of UTF-8 encoded text (mirrors Python len(text.encode('utf-8')))
    const stateBytes = Buffer.byteLength(stateText, "utf-8");
    const rawState = {
      text: stateText,
      byte_len: stateBytes,
      path: statePathLabel,
    };

    // DR-2: parse ## Quick Check Findings
    const findings = parseQuickCheckFindings(stateText, taskId, taskWarnings);

    // DR-3: resolve delivery_id from work model
    let deliveryId = null;
    const workModel = workIndex[workId];
    if (workModel) {
      for (const task of workModel.tasks) {
        if (task.task_id.toLowerCase() === taskId.toLowerCase()) {
          if (task.delivery !== null && task.delivery !== undefined) {
            deliveryId = "delivery-" + String(task.delivery).padStart(3, "0");
          }
          break;
        }
      }
    }

    // DR-3: parse ## Delivery Gates
    let gateGrade = null;
    let gateReviewerTier = null;
    let gateTimestamp = null;
    if (deliveryId !== null && stateText) {
      [gateGrade, gateReviewerTier, gateTimestamp] = parseDeliveryGate(
        stateText, deliveryId, taskWarnings
      );
    }

    // DR-4: read delivery-NNN-issues.md and filter to Source task == task_id
    let deferredIssues = [];
    if (deliveryId !== null) {
      const issuesPath = join(aidDir, "works", workId, deliveryId + "-issues.md");
      deferredIssues = parseDeferredIssues(issuesPath, taskId, taskWarnings);
    }

    const ledger = {
      delivery_id: deliveryId,
      grade: gateGrade,
      reviewer_tier: gateReviewerTier,
      gate_timestamp: gateTimestamp,
      deferred_issues: deferredIssues,
    };

    // DR-5: stat log/heartbeat paths
    const logs = parseLogAvailability(aidDir);

    details[compositeKey] = _buildTaskDetail({
      task_id: taskId,
      findings: findings,
      ledger: ledger,
      raw_state: rawState,
      logs: logs,
    });

    extraWarnings.push(...taskWarnings);
  }

  // Append LC-TR warnings to model's parse_warnings (best-effort)
  if (extraWarnings.length > 0) {
    model.read.parse_warnings.push(...extraWarnings);
  }

  // Sort details ascending by composite key (parity requirement, DM-2 key-order)
  const sortedDetails = {};
  for (const k of Object.keys(details).sort()) {
    sortedDetails[k] = details[k];
  }

  return { model: model, details: sortedDetails };
}
