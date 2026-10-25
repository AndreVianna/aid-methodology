#!/usr/bin/env python3
"""aid-question-form.py -- the AID question-form check, run by the Claude Code Stop hook.

Purpose:
    When the main agent finishes a response, decide whether the message waits on the user.
    If it does, check that it is in the form of .aid/runtime/templates/question-protocol.md
    (first line with a lower-case importance, "Why I ask:", "My recommendation:", a closing
    line) and that the question was recorded first (a writeback-state.sh --ask call in this
    turn whose --context is the question shown, an edit of .aid/knowledge/STATE.md, or an open
    entry whose question the message shows again). When every user message is in plain words,
    the question itself must name no internal identifier (a skill name, a script, an .aid/ path).
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
M_APPROVAL = "the approval closing line (a go-ahead offers no skip: 'Or answer in your own words, or ask me to explain.')"
GO_AHEAD_RE = re.compile(
    r"^\W*(?:shall i|may i|should i (?:start|go|run|apply|create|make|set|write|save|publish|post|push|delete|change)"
    r"|can i go ahead|do you approve|is it ok(?:ay)? (?:to|if)|ok to)\b",
    re.IGNORECASE,
)
M_RECORD = "the record (no writeback-state.sh --ask ran this turn)"
M_RECORD_OTHER = "the record (the --ask this turn recorded another question than the one shown)"
RECORD_ITEMS = (M_RECORD, M_RECORD_OTHER)
M_PLAIN = "plain words in the question (it names %s, but the user writes in plain words: say what happens instead)"
# A user message with code-like text (a code span, a /command, a --flag, a file name, snake_case) is
# technical; a question names an internal identifier when it holds a skill name, a script or an .aid/ path.
TECH_RE = re.compile(r"`|(?:^|[\s>(])/[a-z]|(?:^|\s)--[a-z]|\b[\w-]+\.(?:py|sh|ps1|md|json|ya?ml|toml|js|ts|cs)\b|\b[a-z]+_[a-z_]+\b")
INTERNAL_RE = re.compile(r"\baid-[a-z]+(?:-[a-z]+)*\b|\b[\w-]+\.(?:sh|py|ps1)\b|\.aid/")


# --------------------------------------------------------------------------- text helpers

def shows_form(body):
    """True when a fenced block is a question shown in the form (agents copy the protocol's fenced example)."""
    return any(FIRST_LINE_RE.match(l.strip()) for l in body) and any(is_closing_line(l) for l in body)


def strip_fences(text):
    """Remove fenced code blocks (``` or ~~~), except one that shows a question in the form.

    An unclosed fence runs to the end of the text.
    """
    out = []
    body = []
    fence = None
    for line in text.splitlines():
        s = line.lstrip()
        if fence is None:
            if s.startswith("```") or s.startswith("~~~"):
                fence = s[:3]
                body = []
                continue
            out.append(line)
        elif s.startswith(fence):
            fence = None
            if shows_form(body):
                out.extend(body)
        else:
            body.append(line)
    if fence is not None and shows_form(body):
        out.extend(body)
    return "\n".join(out)


def strip_inline(text):
    """Remove inline code spans and URLs, so a `?` inside them never counts."""
    text = re.sub(r"`[^`\n]*`", " ", text)
    return re.sub(r"\b[a-zA-Z][a-zA-Z0-9+.-]*://\S+", " ", text)


def has_question_sentence(paragraph):
    return re.search(r"\?(?=\s|$|[\"')\]*_])", strip_inline(paragraph)) is not None


LIST_ITEM_RE = re.compile(r"^\s*(?:[-*+]|\d+[.)])\s+")
REQUEST_ANYWHERE_RE = re.compile(
    r"\b(?:tell me|let me know|say (?:if|which|whether)|would you (?:like|prefer|rather)|do you want"
    r"|your call|reply with|which\b[^.!?:;]{0,60}\bwould|from you|need you to|point me"
    r"|(?:paste|send|share|give) me|if you can (?:paste|send|share|give|tell|point|provide|confirm))\b",
    re.IGNORECASE,
)
TAIL_PARAGRAPHS = 3
NEED_RE = re.compile(r"\bI(?:'d|\u2019d|\s+would)?\s+need\b(?!\s+to\b)", re.IGNORECASE)
NEED_OBJECT_RE = re.compile(
    r"\b(?:one of (?:these|the following)|(?:two|three|a few|some) (?:more )?(?:things|details|items)"
    r"|the following|from you)\b",
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
    """The last TAIL_PARAGRAPHS paragraphs, so a request followed by a closing remark still counts.

    A paragraph that is only a list brings the paragraph that introduces it too.
    """
    chunks = [c for c in re.split(r"\n\s*\n", text.strip()) if c.strip()]
    if not chunks:
        return ""
    start = max(0, len(chunks) - TAIL_PARAGRAPHS)
    lines = [l for l in chunks[start].splitlines() if l.strip()]
    if start > 0 and lines and all(LIST_ITEM_RE.match(l) for l in lines):
        start -= 1
    return "\n\n".join(chunks[start:])


def asks_user(text):
    """True when the end of the message asks the user to choose, reply, tell or provide (no '?' needed)."""
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
        # "I need one of these:" / "I'd need two things" -- the agent needs something from the user.
        # Only the present tense counts: "I needed to ..." is a report about the past.
        if NEED_RE.search(plain) and (
            NEED_OBJECT_RE.search(plain)
            or (plain.endswith(":") and any(LIST_ITEM_RE.match(l) for l in lines[i + 1:]))
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


def plain_user(entries):
    """True when the session's user messages hold no code-like text (hook feedback excluded)."""
    texts = [text_of(e) for e in entries if is_real_prompt(e)]
    texts = [t for t in texts if "AID question check:" not in t]
    return bool(texts) and not any(TECH_RE.search(t) for t in texts)


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

def read_word(cmd, i):
    """The shell word at cmd[i:] as (value, ok); ok is False when it cannot be read literally."""
    out = []
    n = len(cmd)
    while i < n and not cmd[i].isspace() and cmd[i] not in ";&|<>()":
        c = cmd[i]
        if c == "'":
            j = cmd.find("'", i + 1)
            if j < 0:
                return "", False
            out.append(cmd[i + 1:j])
            i = j + 1
        elif c == '"':
            i += 1
            while True:
                if i >= n:
                    return "", False
                c = cmd[i]
                if c == '"':
                    i += 1
                    break
                if c == "\\" and i + 1 < n and cmd[i + 1] in '"\\$`':
                    out.append(cmd[i + 1])
                    i += 2
                    continue
                if c == "`" or (c == "$" and i + 1 < n and (cmd[i + 1] in "({_" or cmd[i + 1].isalpha())):
                    return "", False
                out.append(c)
                i += 1
        elif c == "$" and cmd[i + 1:i + 2] == "'":
            i += 2
            while True:
                if i >= n:
                    return "", False
                c = cmd[i]
                if c == "'":
                    i += 1
                    break
                if c == "\\" and i + 1 < n:
                    i += 1
                    c = {"n": "\n", "t": "\t"}.get(cmd[i], cmd[i] if cmd[i] in "'\"\\" else "\\" + cmd[i])
                out.append(c)
                i += 1
        elif c == "\\" and i + 1 < n:
            out.append(cmd[i + 1])
            i += 2
        elif c in "$`\\":
            return "", False
        else:
            out.append(c)
            i += 1
    return "".join(out), True


CONTEXT_FLAG_RE = re.compile(r"(?:^|\s)--context(?:=|\s+)")


def ask_matches(cmd, question):
    """True when a --ask call in cmd records the question shown.

    A call whose --context is missing, cannot be read, or is too short to compare counts as before.
    """
    if not norm(question):
        return True
    found = False
    for m in CONTEXT_FLAG_RE.finditer(cmd):
        found = True
        value, ok = read_word(cmd, m.end())
        if not ok or len(norm(value)) < 12 or same_question(question, value):
            return True
    return not found


def record_in_turn(turn, question):
    """R1 (a writeback-state.sh --ask of the shown question) or R2 (an edit of the KB state file).

    Returns "ok", "other" (an --ask ran, but for another question) or "none".
    """
    saw_ask = False
    for name, inp in tool_uses(turn):
        if name in SHELL_TOOLS:
            cmd = str(inp.get("command", ""))
            if "writeback-state.sh" in cmd and re.search(r"(^|\s)--ask(\s|$)", cmd):
                if ask_matches(cmd, question):
                    return "ok"
                saw_ask = True
        elif name in EDIT_TOOLS:
            path = str(inp.get("file_path") or inp.get("notebook_path") or "").replace("\\", "/")
            if path == KB_STATE_SUFFIX or path.endswith("/" + KB_STATE_SUFFIX):
                return "ok"
    return "other" if saw_ask else "none"


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
    # A break offer anywhere in the tail window (last three paragraphs) is not a question, unless
    # the message also asks in the form's sense (a form first line, or the form's closing line).
    if BREAK_OFFER in tail_block(text) and first_idx is None and not has_close:
        return False, "", [], ""
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
    # A go-ahead is an approval: its closing line offers no skip.
    asked = " ".join(l.strip() for l in question if l.strip())
    if has_close and GO_AHEAD_RE.match(asked) and any(
        is_closing_line(l) and "skip" in l.lower() for l in lines
    ):
        missing.append(M_APPROVAL)
    return True, subject, missing, asked


def build_reason(missing):
    reason = "AID question check: your message waits on the user but is missing: %s.\n" % "; ".join(missing)
    if any(item in missing for item in RECORD_ITEMS):
        reason += (
            "Record the question first (--ask; --ask --design before a work exists; --project --ask in "
            "setup skills), then show it again in full, in the form of "
            ".aid/runtime/templates/question-protocol.md.\n"
            "If you are offering an open question again, show it with its recorded question text and do "
            "not record it twice.\n"
        )
    else:
        reason += "Show it again in full, in the form of .aid/runtime/templates/question-protocol.md.\n"
    if any(item.startswith(M_PLAIN.split("%")[0]) for item in missing):
        reason += (
            "Reword the question in plain words and record the new wording with --ask; close the entry "
            "recorded for the old wording with --answer --state Assumed --value 'reworded in plain words' "
            "(with the same --project or --design flag as its --ask).\n"
        )
    reason += (
        "The user sees only your new message, not this one: repeat everything this message told them "
        "(results, what was recorded, whether a work was needed), then the question.\n"
    )
    reason += (
        "Never drop a question your skill requires, or a break offer. Only a message that truly asks "
        "nothing may end without a question."
    )
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
        status = record_in_turn(current_turn(entries), question)
        if status != "ok" and not shows_open_entry(find_root(str(cwd)), subject, message, question):
            missing = missing + [M_RECORD_OTHER if status == "other" else M_RECORD]
    names = sorted(set(m.group(0) for m in INTERNAL_RE.finditer(question)))
    if names and plain_user(entries):
        missing = missing + [M_PLAIN % ", ".join(names)]
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
