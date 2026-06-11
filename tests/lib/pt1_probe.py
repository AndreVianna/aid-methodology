#!/usr/bin/env python3
# pt1_probe.py -- probe /api/model on 127.0.0.1:PORT and exit 0 on success.
# Called by test-dashboard-parity.sh wait_for_port() to avoid bash pipefail
# interactions with urllib's internal pipes.
#
# Usage: python3 pt1_probe.py PORT
# Exit 0 = server responded; exit 1 = not yet ready.
import sys
import urllib.request

if len(sys.argv) < 2:
    sys.exit(1)

port = int(sys.argv[1])
try:
    r = urllib.request.urlopen(
        "http://127.0.0.1:%d/api/model" % port, timeout=1
    )
    r.read()
    sys.exit(0)
except Exception:
    sys.exit(1)
