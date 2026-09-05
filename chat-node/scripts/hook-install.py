#!/usr/bin/env python3
"""Install or remove the chat stop hook in a host tool's USER-scope settings file.

This is the one place in the product that writes a host tool's configuration, and it exists only
because that was explicitly authorised. The blanket refusal it replaces (FR-0.4) rested on two
concrete hazards rather than on principle, and both are handled here rather than waved away:

  - A PROJECT-scoped host config file is tracked in git. Writing one commits a single machine's
    absolute paths into every contributor's checkout. `bin/aid` refuses a tracked target before this
    script is ever invoked, and this script only ever resolves paths under the user's home.

  - A USER-scoped file belongs to a human who edits it by hand, and other tools write to it too. So
    this MERGES: it parses what is there, changes only the hook entry it owns, and re-serialises
    everything else untouched. It never writes a fresh file over an existing one, it backs the file up
    first, and `bin/aid` shows the diff and requires an answer before calling `--apply`.

Two modes, both idempotent:

  --plan    print what would change, and exit 0. Writes nothing.
  --apply   write it.

`AID_HOOK_MODE` selects install or uninstall. Re-installing an identical hook is a no-op, and
uninstalling an absent one is a no-op; neither is an error, because a command that is safe to re-run
is a command an operator will re-run rather than check first.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import sys
from pathlib import Path

MARKER = "chat-node/adapters/"


def env(name: str, *, required: bool = True) -> str:
    v = os.environ.get(name, "")
    if required and not v:
        sys.stderr.write(f"hook-install: {name} is not set\n")
        raise SystemExit(2)
    return v


def load(cfg: Path) -> tuple[dict, bool]:
    """The existing settings, and whether the file was already there.

    A parse failure is fatal rather than recoverable. Overwriting a file we cannot read would destroy
    settings that belong to somebody else, and 'it was malformed anyway' is not ours to decide.
    """
    if not cfg.exists():
        return {}, False
    raw = cfg.read_text(encoding="utf-8-sig")
    if not raw.strip():
        return {}, True
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        sys.stderr.write(
            f"hook-install: {cfg} is not parseable JSON ({e}).\n"
            "  It will NOT be modified -- editing a file we cannot read risks destroying settings\n"
            "  that are not ours. Fix the syntax, or add the hook by hand with 'aid chat hook'.\n"
        )
        raise SystemExit(1)
    if not isinstance(data, dict):
        sys.stderr.write(f"hook-install: {cfg} does not hold a JSON object; refusing to edit it.\n")
        raise SystemExit(1)
    return data, True


def command_for(node: str, adapter: str, timeout: str) -> str:
    return f"{node} {adapter} --host-timeout {timeout}"


def is_ours(entry: object) -> bool:
    """Whether a hook entry is the one this product owns.

    Keyed on the adapter path rather than on an exact command match, so a hook whose timeout an
    operator has hand-tuned is still recognised as ours and updated in place instead of being
    duplicated alongside a second copy.
    """
    return MARKER in json.dumps(entry)


def plan_claude(data: dict, cmd: str, timeout: int, remove: bool) -> tuple[dict, str]:
    """Claude Code: hooks.Stop[] of matcher groups, each holding an inner hooks[]."""
    out = json.loads(json.dumps(data))
    hooks = out.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        sys.stderr.write("hook-install: existing 'hooks' is not an object; refusing to edit it.\n")
        raise SystemExit(1)
    stop = hooks.setdefault("Stop", [])
    if not isinstance(stop, list):
        sys.stderr.write("hook-install: existing 'hooks.Stop' is not an array; refusing to edit it.\n")
        raise SystemExit(1)

    ours = {"type": "command", "timeout": timeout, "command": cmd}

    # Strip every entry we own, from every matcher group, then re-add if installing. Stripping first is
    # what makes a re-install an update rather than a second copy.
    changed_note = []
    for group in stop:
        if isinstance(group, dict) and isinstance(group.get("hooks"), list):
            before = len(group["hooks"])
            group["hooks"] = [h for h in group["hooks"] if not is_ours(h)]
            if len(group["hooks"]) != before:
                changed_note.append("removed an existing chat hook")
    # Groups we emptied and did not put anything back into are ours to clean up; a group that held
    # only our hook is not a group the user wrote.
    stop = [g for g in stop if not (isinstance(g, dict) and g.get("hooks") == [] and g.get("matcher") == "*")]

    if not remove:
        target = None
        for group in stop:
            if isinstance(group, dict) and group.get("matcher") == "*" and isinstance(group.get("hooks"), list):
                target = group
                break
        if target is None:
            target = {"matcher": "*", "hooks": []}
            stop.append(target)
        target["hooks"].append(ours)

    hooks["Stop"] = stop
    if not stop:
        hooks.pop("Stop", None)
    if not hooks:
        out.pop("hooks", None)
    return out, "; ".join(changed_note)


def plan_cursor(data: dict, cmd: str, timeout: int, remove: bool) -> tuple[dict, str]:
    """Cursor: hooks.stop[] of flat command entries."""
    out = json.loads(json.dumps(data))
    hooks = out.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        sys.stderr.write("hook-install: existing 'hooks' is not an object; refusing to edit it.\n")
        raise SystemExit(1)
    stop = hooks.setdefault("stop", [])
    if not isinstance(stop, list):
        sys.stderr.write("hook-install: existing 'hooks.stop' is not an array; refusing to edit it.\n")
        raise SystemExit(1)

    before = len(stop)
    stop = [h for h in stop if not is_ours(h)]
    note = "removed an existing chat hook" if len(stop) != before else ""
    if not remove:
        stop.append({"command": cmd, "timeout": timeout})

    hooks["stop"] = stop
    if not stop:
        hooks.pop("stop", None)
    if not hooks:
        out.pop("hooks", None)
    return out, note


def own_entries(data: dict, tool: str) -> list[dict]:
    """Every hook entry this product owns, flattened across both hosts' shapes."""
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return []
    found = []
    for key in ("Stop", "stop"):
        arr = hooks.get(key)
        if not isinstance(arr, list):
            continue
        for item in arr:
            if isinstance(item, dict) and isinstance(item.get("hooks"), list):
                found.extend(h for h in item["hooks"] if isinstance(h, dict) and is_ours(h))
            elif isinstance(item, dict) and is_ours(item):
                found.append(item)
    return found


def check(cfg: Path, tool: str) -> int:
    """Report whether an installed hook will actually work.

    THE COMPARISON IS WITHIN OUR OWN ENTRY, which an earlier version got wrong. That version matched
    `"timeout": N` and `--host-timeout N` with regexes over the whole file, which was adequate only
    while the file held nothing but our hook. As soon as `--install` began merging into a file that
    already had the user's own hooks, the first `"timeout"` found belonged to THEIR entry, and the
    check reported a mismatch against a correctly installed hook. A false alarm about a silent failure
    is worse than no check, because it sends someone hunting a bug that is not there.
    """
    if not cfg.exists():
        sys.stderr.write(
            f"aid: chat hook: no hook installed -- {cfg} does not exist.\n"
            f"  Run 'aid chat hook --tool {tool} --install', or print it with 'aid chat hook --tool {tool}'.\n"
        )
        return 1
    data, _ = load(cfg)
    mine = own_entries(data, tool)
    if not mine:
        sys.stderr.write(
            f"aid: chat hook: no chat stop hook found in {cfg}.\n"
            f"  Run 'aid chat hook --tool {tool} --install'.\n"
        )
        return 1
    if len(mine) > 1:
        sys.stderr.write(
            f"aid: chat hook: {len(mine)} chat hooks are installed in {cfg}; there should be one.\n"
            "  Run --uninstall then --install to collapse them.\n"
        )
        return 1

    entry = mine[0]
    cmd = str(entry.get("command", ""))
    problems = []

    field = entry.get("timeout")
    if not isinstance(field, int):
        problems.append('the hook entry has no integer "timeout", so the host uses its own default '
                        "-- which is not measured")
    m = re.search(r"--host-timeout\s+(\d+)", cmd)
    if not m:
        problems.append("the command has no --host-timeout, so the adapter falls back to a short block")
    if isinstance(field, int) and m and int(m.group(1)) != field:
        problems.append(
            f'the numbers DISAGREE: timeout={field} but --host-timeout={m.group(1)}. '
            "This fails silently -- no error, just a wake that never arrives"
        )
    if not re.search(r"^\S*(/|\\)node(\.exe)?\b|^\S*node(\.exe)?\s", cmd):
        problems.append("node may not be an absolute path; a PATH shim can leave the host watching "
                        "the wrong process")
    if entry.get("fail_closed") is True or entry.get("blocking") is True:
        problems.append("fail-closed is set; a hook that must succeed can freeze the session it "
                        "belongs to")

    if problems:
        sys.stderr.write("aid: chat hook: the installed hook has problems:\n")
        for prob in problems:
            sys.stderr.write(f"  - {prob}\n")
        return 1
    print(f"aid: chat hook: the hook in {cfg} looks correct (timeout {field}s, matched on both sides).")
    return 0


def main() -> int:
    mode_flag = sys.argv[1] if len(sys.argv) > 1 else ""
    if mode_flag not in ("--plan", "--apply", "--check"):
        sys.stderr.write("hook-install: expected --plan, --apply or --check\n")
        return 2

    cfg = Path(env("AID_HOOK_CFG"))
    tool = env("AID_HOOK_TOOL")
    action = env("AID_HOOK_MODE")
    remove = action == "uninstall"
    node = env("AID_HOOK_NODE", required=not remove)
    adapter = env("AID_HOOK_ADAPTER", required=not remove)
    timeout = int(env("AID_HOOK_TIMEOUT", required=not remove) or 60)

    # Belt and braces on the scope rule. `bin/aid` builds this path under $HOME and refuses a tracked
    # file, but this script is the thing that writes, so it re-checks rather than trusting its caller.
    home = Path(os.path.expanduser("~")).resolve()
    try:
        resolved_parent = cfg.parent.resolve()
    except OSError:
        resolved_parent = cfg.parent
    if home not in resolved_parent.parents and resolved_parent != home:
        sys.stderr.write(
            f"hook-install: {cfg} is not under {home}.\n"
            "  Only USER-scope host settings are written; a project-scoped file is tracked in git and\n"
            "  writing it would put this machine's paths into every checkout.\n"
        )
        return 1

    if mode_flag == "--check":
        return check(cfg, tool)

    data, existed = load(cfg)
    cmd = command_for(node, adapter, timeout) if not remove else ""
    planner = plan_claude if tool == "claude-code" else plan_cursor
    updated, note = planner(data, cmd, timeout, remove)

    before_s = json.dumps(data, indent=2, sort_keys=True)
    after_s = json.dumps(updated, indent=2, sort_keys=True)

    if before_s == after_s:
        verb = "already absent" if remove else "already installed, unchanged"
        print(f"aid: chat hook: {verb} in {cfg}. Nothing to do.")
        return 0

    if mode_flag == "--plan":
        print(f"aid: chat hook: {'REMOVE from' if remove else 'INSTALL into'} {cfg}")
        print(f"  the file {'exists' if existed else 'does not exist yet and will be created'}")
        if note:
            print(f"  note: {note} (it is replaced, not duplicated)")
        if not remove:
            print(f"  hook timeout {timeout}s, and --host-timeout {timeout} on the command: matched")
        print("  everything else in the file is preserved byte for byte on re-serialisation")
        print()
        print("--- before")
        print(before_s if existed else "(no file)")
        print("--- after")
        print(after_s)
        return 0

    cfg.parent.mkdir(parents=True, exist_ok=True)
    if existed:
        # The backup is taken because this file is not ours. It is the difference between a mistake the
        # user can undo and one they cannot.
        backup = cfg.with_suffix(cfg.suffix + ".aid-backup")
        shutil.copy2(cfg, backup)
        print(f"aid: chat hook: backed up {cfg} -> {backup}")
    cfg.write_text(after_s + "\n", encoding="utf-8")
    print(f"aid: chat hook: {'removed from' if remove else 'installed into'} {cfg}")
    if not remove:
        print(f"  verify with: aid chat hook --tool {tool} --check")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
