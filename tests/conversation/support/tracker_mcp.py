#!/usr/bin/env python3
"""Purpose: closed, read-only MCP tracker fixture; never contacts a remote tracker.
Usage: python3 tests/conversation/support/tracker_mcp.py (newline JSON-RPC on stdio).
Exit codes: 0 on stdin EOF. Requires Python 3.10+; standard library only.
"""

from __future__ import annotations

import json
import re
import sys

PROTOCOLS = ("2025-11-25", "2025-06-18", "2025-03-26", "2024-11-05")
TRACKERS = {"jira_read_ticket": "Jira", "linear_read_ticket": "Linear"}
TICKET_ID = r"[A-Z][A-Z0-9]*-[1-9][0-9]*"


def tool_definitions() -> list[dict]:
    """Only ticket reads are exposed, without paths, credentials or account selectors."""
    return [
        {"name": name, "description": f"Read a {tracker} ticket by ID (isolated test tracker).",
         "inputSchema": {"type": "object", "properties": {"ticket_id": {"type": "string", "pattern": "^" + TICKET_ID + "$"}},
                         "required": ["ticket_id"], "additionalProperties": False},
         "annotations": {"readOnlyHint": True, "destructiveHint": False,
                         "idempotentHint": True, "openWorldHint": False}}
        for name, tracker in TRACKERS.items()
    ]


def request_params(params: object) -> dict | None:
    """Validate optional MCP metadata separately from the closed method parameters."""
    if not isinstance(params, dict):
        return None
    metadata = params.get("_meta", {})
    if not isinstance(metadata, dict):
        return None
    if "progressToken" in metadata:
        token = metadata["progressToken"]
        integer_value = isinstance(token, int) or (isinstance(token, float) and token.is_integer())
        if isinstance(token, bool) or not (isinstance(token, str) or integer_value):
            return None
    return {key: value for key, value in params.items() if key != "_meta"}


def serve() -> int:
    """Serve the minimal MCP lifecycle and closed tool set; stdout is JSON-RPC only."""
    initialized = False
    ready = False
    for line in sys.stdin:
        request_id = None
        try:
            request = json.loads(line)
        except ValueError:
            response = {"error": {"code": -32700, "message": "Parse error"}}
        else:
            if (not isinstance(request, dict) or request.get("jsonrpc") != "2.0" or not isinstance(request.get("method"), str)
                or ("id" in request and (isinstance(request["id"], bool) or not isinstance(request["id"], (str, int))))):
                response = {"error": {"code": -32600, "message": "Invalid request"}}
            else:
                request_id = request.get("id")
                method = request["method"]
                if "id" not in request:
                    if method == "notifications/initialized" and initialized:
                        ready = True
                    continue  # JSON-RPC notifications never receive a response.
                params = request_params(request.get("params", {}))
                response = {"error": {"code": -32602, "message": "Invalid params"}}
                if not isinstance(params, dict):
                    pass
                elif method == "initialize" and not initialized:
                    version = params.get("protocolVersion")
                    if isinstance(version, str) and isinstance(params.get("capabilities"), dict) and isinstance(params.get("clientInfo"), dict):
                        initialized = True
                        response = {"result": {"protocolVersion": version if version in PROTOCOLS else PROTOCOLS[0],
                                               "capabilities": {"tools": {}},
                                               "serverInfo": {"name": "aid-test-trackers", "version": "1.0.0"}}}
                elif method == "ping" and not params:
                    response = {"result": {}}
                elif not ready:
                    response = {"error": {"code": -32600, "message": "Initialize the fixture first"}}
                elif method == "tools/list" and not params:
                    response = {"result": {"tools": tool_definitions()}}
                elif method == "tools/call":
                    name = params.get("name")
                    arguments = params.get("arguments")
                    if isinstance(name, str) and name not in TRACKERS:
                        response = {"error": {"code": -32602, "message": "Unknown tool"}}
                    elif (isinstance(name, str) and name in TRACKERS and set(params) == {"name", "arguments"}
                          and isinstance(arguments, dict) and set(arguments) == {"ticket_id"}
                          and isinstance(arguments["ticket_id"], str) and re.fullmatch(TICKET_ID, arguments["ticket_id"])):
                        text = f"{TRACKERS[name]} is unavailable. Ticket {arguments['ticket_id']} could not be read."
                        response = {"result": {"content": [{"type": "text", "text": text}], "isError": True}}
                elif method not in ("initialize", "tools/list"):
                    response = {"error": {"code": -32601, "message": "Method not found"}}
        print(json.dumps({"jsonrpc": "2.0", "id": request_id, **response}), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(serve())
