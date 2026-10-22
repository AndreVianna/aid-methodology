#!/usr/bin/env python3
"""aid-question-form.py -- the AID question-form check, run by the Claude Code Stop hook.

Purpose:
    When the main agent finishes a response, decide whether the message waits on the user.
    If it does, check that it is in the form of .aid/runtime/templates/question-protocol.md
    (first line with a lower-case importance, "Why I ask:", "My recommendation:", a closing
    line) and that the question was recorded first (a writeback-state.sh --ask call in this
    turn, an edit of .aid/knowledge/STATE.md, or an open entry whose question the message shows again).
    A failing message is sent back once, with a short reason naming what is missing.

Usage:
    python3 aid-question-form.py < stop-event.json
    (normally launched by aid-question-form.sh)

    stdin   the Stop-event JSON: session_id, transcript_path, cwd, stop_hook_active,
            last_assistant_message
    env     AID_QUESTION_HOOK=off          pass without checking (one session)
            AID_QUESTION_HOOK_LOG=<file>   append one JSON line per blocked message:
                                           time, session_id, missing (list), message
            CLAUDE_PROJECT_DIR             project root, when cwd holds no .aid folder

Output:
    stdout: exactly one JSON object -- {} to let the turn end, or
            {"decision": "block", "reason": "..."} to make Claude continue.

Exit codes:
    0 -- always. Any error (bad stdin, unreadable transcript) prints {} and exits 0: a
         broken hook must never hold a session.

Python 3.8+, standard library only. The source is ASCII-only.
"""

import datetime
import glob
import json
import os
import re
import sys
import time

DASHES = "(?:--|\\u2013|\\u2014)"
FIRST_LINE_RE = re.compile(
    r"^[\s>*_#`-]*(?P<subject>\S.*?)\s+" + DASHES + r"\s+question\s+\d+\s+of\s+\d+\s+" + DASHES
    + r"\s+importance:\s*[*_`]*(?P<label>[A-Za-z]+)[*_`\s.]*$",
    re.IGNORECASE,
)
LABELS = ("high", "medium", "low")
WHY_RE = re.compile(r"^[\s>*_`-]*Why I ask\s*[*_]*\s*:")
REC_RE = re.compile(r"^[\s>*_`-]*My recommendation\s*[*_]*\s*:")
BREAK_OFFER = "Take a break, or go on to"
WAIVED_SUBJECTS = ("recovery", "cancel work")
TICKET_SKILLS = ("aid-read-ticket", "aid-create-ticket", "aid-update-ticket")
EDIT_TOOLS = ("Edit", "Write", "MultiEdit", "NotebookEdit")
SHELL_TOOLS = ("Bash", "PowerShell")
KB_STATE_SUFFIX = ".aid/knowledge/STATE.md"
OPEN_STATES = ("pending", "skipped")
OVERLAP_MIN = 0.6
WAIT_SECONDS = 2.0
POLL_SECONDS = 0.1

M_FIRST = "the first line (subject -- question n of m -- importance: high, medium or low)"
M_WHY = 'the "Why I ask:" line'
M_REC = 'the "My recommendation:" line'
M_CLOSE = "the closing line (own words, ask me to explain)"
M_RECORD = "the record (no writeback-state.sh --ask ran this turn)"


# --------------------------------------------------------------------------- text helpers

def strip_fences(text):
    """Remove fenced code blocks (``` or ~~~); an unclosed fence removes the rest."""
    out = []
    fence = None
    for line in text.splitlines():
        s = line.lstrip()
        if fence is None:
            if s.startswith("```") or s.startswith("~~~"):
                fence = s[:3]
                continue
            out.append(line)
        elif s.startswith(fence):
            fence = None
    return "\n".join(out)


def strip_inline(text):
    """Remove inline code spans and URLs, so a `?` inside them never counts."""
    text = re.sub(r"`[^`\n]*`", " ", text)
    return re.sub(r"\b[a-zA-Z][a-zA-Z0-9+.-]*://\S+", " ", text)


def last_paragraph(text):
    chunks = re.split(r"\n\s*\n", text.strip())
    return chunks[-1] if chunks else ""


def has_question_sentence(paragraph):
    return re.search(r"\?(?=\s|$|[\"')\]*_])", strip_inline(paragraph)) is not None


LIST_ITEM_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
REQUEST_ANYWHERE_RE = re.compile(
    r"\b(?:tell me|let me know|say (?:if|which|whether)|would you (?:like|prefer|rather)|do you want"
    r"|your call|reply with|which\b[^.!?:;]{0,60}\bwould)\b",
    re.IGNORECASE,
)
REQUEST_LEADING_RE = re.compile(
    r"^(?:(?:and|or|then|please|otherwise|you can|you may|just)\s+)*(?:choose|pick|reply|say)\b",
    re.IGNORECASE,
)
LEAD_IN_RE = re.compile(
    r"\b(?:ways? (?:forward|to (?:go|proceed|continue|move))|paths? forward|options|choices|alternatives"
    r"|how to proceed|where to go from here)\b",
    re.IGNORECASE,
)


def tail_block(text):
    """The final paragraph; when it is only a list, the paragraph that introduces it too."""
    chunks = [c for c in re.split(r"\n\s*\n", text.strip()) if c.strip()]
    if not chunks:
        return ""
    tail = chunks[-1]
    lines = [l for l in tail.splitlines() if l.strip()]
    if len(chunks) > 1 and lines and all(LIST_ITEM_RE.match(l) for l in lines):
        tail = chunks[-2] + "\n" + tail
    return tail


def asks_user(text):
    """True when the end of the message asks the user to choose, reply or tell (no '?' needed)."""
    tail = strip_inline(tail_block(text))
    if not tail.strip():
        return False
    if has_question_sentence(tail):
        return True
    lines = [l for l in tail.splitlines() if l.strip()]
    for i, line in enumerate(lines):
        plain = LIST_ITEM_RE.sub("", line).strip(" \t>*_#")
        for seg in re.split(r"(?<=[.!?:;])\s+", plain):
            seg = seg.strip(" \t>*_#-")
            if REQUEST_ANYWHERE_RE.search(seg) or REQUEST_LEADING_RE.match(seg):
                return True
        if (
            plain.endswith(":")
            and LEAD_IN_RE.search(plain)
            and any(LIST_ITEM_RE.match(l) for l in lines[i + 1:])
        ):
            return True
    return False


def is_closing_line(line):
    low = line.lower()
    return "your own words" in low and "explain" in low


def norm(text):
    return " ".join(re.sub(r"[^0-9a-z]+", " ", text.lower()).split())


# --------------------------------------------------------------------------- transcript

def load_entries(path):
    """Main-thread transcript entries, in order. Unreadable lines are skipped.

    None when the file is missing or holds no readable entry (the caller then fails open).
    """
    entries = []
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    obj = json.loads(raw)
                except ValueError:
                    continue
                if isinstance(obj, dict) and not obj.get("isSidechain"):
                    entries.append(obj)
    except (OSError, IOError):
        return None
    return entries or None


def role_of(entry):
    msg = entry.get("message")
    if isinstance(msg, dict) and msg.get("role"):
        return msg.get("role")
    return entry.get("type")


def blocks_of(entry):
    msg = entry.get("message")
    content = msg.get("content") if isinstance(msg, dict) else entry.get("content")
    if isinstance(content, str):
        return [{"type": "text", "text": content}]
    if isinstance(content, list):
        return [b for b in content if isinstance(b, dict)]
    return []


def text_of(entry):
    return "\n".join(
        str(b.get("text", "")) for b in blocks_of(entry) if b.get("type") == "text"
    )


def is_real_prompt(entry):
    if role_of(entry) != "user" or entry.get("isMeta"):
        return False
    return any(
        b.get("type") == "text" and str(b.get("text", "")).strip() for b in blocks_of(entry)
    )


def last_assistant_text(entries):
    for entry in reversed(entries):
        if role_of(entry) == "assistant":
            text = text_of(entry)
            if text.strip():
                return text
    return ""


def transcript_has(entries, message):
    last = last_assistant_text(entries).strip()
    return bool(last) and message.strip().endswith(last)


def current_turn(entries):
    start = 0
    for i, entry in enumerate(entries):
        if is_real_prompt(entry):
            start = i + 1
    return entries[start:]


def tool_uses(entries):
    for entry in entries:
        if role_of(entry) != "assistant":
            continue
        for b in blocks_of(entry):
            if b.get("type") == "tool_use":
                inp = b.get("input")
                yield b.get("name"), (inp if isinstance(inp, dict) else {})


def last_skill(entries):
    """The session's most recent skill call (Skill tool, or a typed slash command)."""
    found = ""
    for entry in entries:
        if role_of(entry) == "assistant":
            for b in blocks_of(entry):
                if b.get("type") == "tool_use" and b.get("name") == "Skill":
                    inp = b.get("input") if isinstance(b.get("input"), dict) else {}
                    name = inp.get("skill") or inp.get("name") or inp.get("command") or ""
                    found = str(name).strip().lstrip("/").split(":")[-1]
        elif is_real_prompt(entry) or role_of(entry) == "user":
            m = re.search(r"<command-name>\s*/?([^<\s]+)\s*</command-name>", text_of(entry))
            if m and not entry.get("isMeta"):
                found = m.group(1).split(":")[-1]
    return found


def wait_for_transcript(path, message):
    """Wait (at most WAIT_SECONDS) until the transcript ends with the message."""
    deadline = time.time() + WAIT_SECONDS
    entries = load_entries(path)
    while time.time() < deadline:
        if entries is not None and transcript_has(entries, message):
            break
        time.sleep(POLL_SECONDS)
        entries = load_entries(path)
    return entries


# --------------------------------------------------------------------------- record signs

def record_in_turn(turn):
    """R1 (writeback-state.sh --ask) or R2 (an edit of the Knowledge Base state file)."""
    for name, inp in tool_uses(turn):
        if name in SHELL_TOOLS:
            cmd = str(inp.get("command", ""))
            if "writeback-state.sh" in cmd and re.search(r"(^|\s)--ask(\s|$)", cmd):
                return True
        elif name in EDIT_TOOLS:
            path = str(inp.get("file_path") or inp.get("notebook_path") or "").replace("\\", "/")
            if path == KB_STATE_SUFFIX or path.endswith("/" + KB_STATE_SUFFIX):
                return True
    return False


def unquote(value):
    value = value.strip()
    if len(value) >= 2 and value[0] == "'" and value[-1] == "'":
        return value[1:-1].replace("''", "'")
    if len(value) >= 2 and value[0] == '"' and value[-1] == '"':
        return value[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    return value


def yaml_entries(path):
    """The qa entries of a STATE.yml as dicts (a tolerant line reader, no YAML library)."""
    entries = []
    cur = None
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            lines = fh.read().splitlines()
    except (OSError, IOError):
        return entries
    for line in lines:
        m = re.match(r"^\s*-\s+id:\s*(.*)$", line)
        if m:
            cur = {"id": unquote(m.group(1))}
            entries.append(cur)
            continue
        if cur is None:
            continue
        if line.strip() and not line.startswith((" ", "\t")):
            cur = None
            continue
        m = re.match(r"^\s+([A-Za-z_]+):\s*(.*)$", line)
        if m and m.group(1) not in cur:
            cur[m.group(1)] = unquote(m.group(2))
    return entries


def design_entries(path):
    """The rows of the '## Questions' table of a design document, as dicts."""
    rows = []
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            lines = fh.read().splitlines()
    except (OSError, IOError):
        return rows
    in_section = False
    header = None
    for line in lines:
        if re.match(r"^##\s+Questions\s*$", line):
            in_section = True
            header = None
            continue
        if in_section and re.match(r"^##\s", line):
            break
        if not in_section or not line.strip().startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if header is None:
            header = [c.lower() for c in cells]
        elif not all(re.match(r"^:?-+:?$", c) for c in cells if c):
            row = dict(zip(header, cells))
            row["context"] = row.get("question", "")
            rows.append(row)
    return rows


def find_root(cwd):
    here = cwd
    while here:
        if os.path.isdir(os.path.join(here, ".aid")):
            return here
        parent = os.path.dirname(here)
        if parent == here:
            break
        here = parent
    env = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if env and os.path.isdir(os.path.join(env, ".aid")):
        return env
    return ""


def question_candidates(question_text):
    """The shown question as normalised text: the whole of it, then each sentence on its own."""
    whole = norm(question_text)
    found = [(whole, 12)]
    for sentence in re.split(r"(?<=[.?!])\s+", question_text.strip()):
        n = norm(sentence)
        if n and n != whole:
            found.append((n, 20))
    return found


def same_question(question_text, context):
    """True when an entry's context is the question shown: containment either way, or tokens."""
    ctx = norm(context)
    if len(ctx) < 12:
        return False
    for cand, floor in question_candidates(question_text):
        if len(cand) >= floor and (cand in ctx or (len(ctx) >= floor and ctx in cand)):
            return True
    shown = set(norm(question_text).split())
    have = set(ctx.split())
    return bool(shown) and len(shown & have) / float(len(shown | have)) >= OVERLAP_MIN


def shows_open_entry(root, subject, message, question_text):
    """R3: the message offers an open (Pending or Skipped) entry's question again.

    The entry's category never matches by itself: a different, older question under the same
    category is not this question's record. The subject is kept in the signature for callers.
    """
    if not root or not norm(question_text):
        return False
    candidates = list(yaml_entries(os.path.join(root, ".aid", "STATE.yml")))
    for path in sorted(glob.glob(os.path.join(root, ".aid", "works", "*", "STATE.yml"))):
        candidates.extend(yaml_entries(path))
    for path in sorted(glob.glob(os.path.join(root, ".aid", "design", "*.md"))):
        candidates.extend(design_entries(path))
    for entry in candidates:
        if str(entry.get("state", "")).strip().lower() not in OPEN_STATES:
            continue
        if same_question(question_text, entry.get("context", "")):
            return True
    return False


# --------------------------------------------------------------------------- the check

def analyse(message):
    """Return (waits, subject, missing_form_items, question_text) for a message."""
    text = strip_fences(message)
    para = last_paragraph(text)
    if BREAK_OFFER in para:
        return False, "", [], ""
    lines = text.splitlines()
    first_idx = None
    subject = ""
    first_ok = False
    for i, line in enumerate(lines):
        m = FIRST_LINE_RE.match(line.strip())
        if m:
            if first_idx is None:
                first_idx = i
                subject = m.group("subject").strip(" *_`")
            if m.group("label") in LABELS:
                first_ok = True
    has_why = any(WHY_RE.match(l) for l in lines)
    has_rec = any(REC_RE.match(l) for l in lines)
    has_close = any(is_closing_line(l) for l in lines)
    waits = first_idx is not None or has_close or asks_user(text)
    if not waits:
        return False, "", [], ""
    missing = []
    if not first_ok:
        missing.append(M_FIRST)
    if not has_why:
        missing.append(M_WHY)
    if not has_rec:
        missing.append(M_REC)
    if not has_close:
        missing.append(M_CLOSE)
    question = []
    if first_idx is not None:
        for line in lines[first_idx + 1:]:
            if WHY_RE.match(line):
                break
            question.append(line)
    return True, subject, missing, " ".join(question)


def build_reason(missing):
    reason = "AID question check: your message waits on the user but is missing: %s.\n" % "; ".join(missing)
    if M_RECORD in missing:
        reason += (
            "Record the question first (--ask; --ask --design before a work exists; --project --ask in "
            "setup skills), then show it again in full, in the form of "
            ".aid/runtime/templates/question-protocol.md.\n"
            "If you are offering an open question again, show it under its recorded category and do "
            "not record it twice.\n"
        )
    else:
        reason += "Show it again in full, in the form of .aid/runtime/templates/question-protocol.md.\n"
    reason += "If you are not waiting on the user, end the turn without a question."
    return reason


def write_log(path, session_id, missing, message):
    try:
        line = json.dumps(
            {
                "time": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
                "session_id": session_id,
                "missing": missing,
                "message": message,
            }
        )
        with open(path, "a", encoding="utf-8") as fh:
            fh.write(line + "\n")
    except Exception:
        pass


def decide(event):
    """Return the hook output object, or None to pass."""
    if event.get("stop_hook_active") in (True, "true", "True"):
        return None
    if os.environ.get("AID_QUESTION_HOOK", "").strip().lower() == "off":
        return None
    path = event.get("transcript_path") or ""
    message = event.get("last_assistant_message")
    from_event = isinstance(message, str) and bool(message.strip())
    entries = None
    if not from_event:
        if not path:
            return None
        entries = load_entries(path)
        if entries is None:
            return None
        message = last_assistant_text(entries)
    if not message.strip():
        return None

    waits, subject, missing, question = analyse(message)
    if not waits:
        return None

    if not path:
        return None
    if from_event:
        entries = wait_for_transcript(path, message)
    if entries is None:
        return None

    waived = subject.lower() in WAIVED_SUBJECTS or last_skill(entries) in TICKET_SKILLS
    if not waived:
        cwd = event.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
        if not (
            record_in_turn(current_turn(entries))
            or shows_open_entry(find_root(str(cwd)), subject, message, question)
        ):
            missing = missing + [M_RECORD]
    if not missing:
        return None

    log = os.environ.get("AID_QUESTION_HOOK_LOG", "")
    if log:
        write_log(log, str(event.get("session_id", "")), missing, message)
    return {"decision": "block", "reason": build_reason(missing)}


def main():
    try:
        raw = sys.stdin.buffer.read().decode("utf-8", "replace")
        event = json.loads(raw)
        if not isinstance(event, dict):
            result = None
        else:
            result = decide(event)
    except BaseException:
        result = None
    sys.stdout.write(json.dumps(result if result else {}) + "\n")
    sys.stdout.flush()
    return 0


if __name__ == "__main__":
    sys.exit(main())
