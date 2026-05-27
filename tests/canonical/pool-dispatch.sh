#!/usr/bin/env bash
# test-pool-dispatch.sh — symbolic simulation of feature-009 PD-2..PD-4 pool semantics.
#
# Verifies pool-dispatch state machine invariants WITHOUT actually dispatching
# subagents (which would require host integration). The Python simulator walks
# synthetic Execution Graphs through PD-2..PD-4 and prints PASS/FAIL per test.
#
# Asserts:
#   T1: simple chain runs serially even with MaxConcurrent=2
#   T2: fan-out respects MaxConcurrent cap
#   T3: failure marks transitive descendants Blocked
#   T4: failure on one chain does not block independent chains
#   T5: FIFO admission (lowest-numbered task first)
#   T6: no MaxConcurrent violations across pool sizes 1/2/3/5
#   T7: fixed-point exits cleanly with all-failed graph
#
# Usage: bash test-pool-dispatch.sh

set -u

# Write simulator to temp file
SIM_PY=$(mktemp --suffix=.py 2>/dev/null || mktemp)
trap 'rm -f "$SIM_PY"' EXIT

cat > "$SIM_PY" <<'PYEOF'
"""Pool-dispatch simulator — implements PD-2..PD-4 over a deterministic graph."""
from collections import deque

def simulate(graph, max_concurrent, failures=None):
    failures = failures or set()
    rev_graph = {t: [] for t in graph}
    for t, deps in graph.items():
        for d in deps:
            rev_graph.setdefault(d, []).append(t)

    status = {t: "Pending" for t in graph}
    in_flight = []
    order = []
    max_in_flight = 0

    def descendants(t):
        result = set()
        q = deque([t])
        while q:
            cur = q.popleft()
            for child in rev_graph.get(cur, []):
                if child not in result:
                    result.add(child)
                    q.append(child)
        return result

    def fill_pool():
        ready = sorted(
            t for t in graph
            if status[t] == "Pending"
            and all(status[d] == "Done" for d in graph[t])
        )
        for t in ready:
            if len(in_flight) >= max_concurrent:
                break
            in_flight.append(t)
            status[t] = "InFlight"
            order.append(("dispatch", t))

    fill_pool()
    max_in_flight = max(max_in_flight, len(in_flight))

    while in_flight:
        t = in_flight.pop(0)
        if t in failures:
            status[t] = "Failed"
            order.append(("fail", t))
            for d in descendants(t):
                if status[d] == "Pending":
                    status[d] = "Blocked"
                    order.append(("block", d))
        else:
            status[t] = "Done"
            order.append(("complete", t))
        fill_pool()
        max_in_flight = max(max_in_flight, len(in_flight))

    return {"order": order, "final_status": status, "max_in_flight": max_in_flight}


def report(name, ok):
    print(f"  [{'PASS' if ok else 'FAIL'}] {name}")
    return 1 if ok else 0


total = 0
passed = 0

# T1
r = simulate({"task-001": [], "task-002": ["task-001"], "task-003": ["task-002"]}, 2)
ok = (r["max_in_flight"] == 1 and r["final_status"]["task-003"] == "Done")
passed += report("T1_chain_serial_even_at_cap_2", ok); total += 1

# T2
g = {"task-001": []}
g.update({f"task-00{i}": ["task-001"] for i in range(2, 7)})
r = simulate(g, 3)
ok = (r["max_in_flight"] == 3 and all(r["final_status"][f"task-00{i}"] == "Done" for i in range(1, 7)))
passed += report("T2_fanout_respects_cap_3", ok); total += 1

# T3
r = simulate({"task-001": [], "task-002": ["task-001"], "task-003": ["task-002"]}, 2,
             failures={"task-002"})
ok = (r["final_status"]["task-001"] == "Done"
      and r["final_status"]["task-002"] == "Failed"
      and r["final_status"]["task-003"] == "Blocked")
passed += report("T3_failure_blocks_descendant", ok); total += 1

# T4
g = {
    "task-001": [], "task-002": ["task-001"], "task-003": ["task-002"],
    "task-004": [], "task-005": ["task-004"],
}
r = simulate(g, 3, failures={"task-002"})
ok = (r["final_status"]["task-003"] == "Blocked"
      and r["final_status"]["task-004"] == "Done"
      and r["final_status"]["task-005"] == "Done")
passed += report("T4_failure_isolated_to_one_chain", ok); total += 1

# T5
g = {"task-001": []}
for i in range(2, 7):
    g[f"task-00{i}"] = ["task-001"]
r = simulate(g, 2)
dispatches = [t for ev, t in r["order"] if ev == "dispatch"]
ok = (dispatches[:3] == ["task-001", "task-002", "task-003"])
passed += report("T5_FIFO_lowest_first", ok); total += 1

# T6
ok = all(simulate({"task-001": [], "task-002": ["task-001"]}, n)["max_in_flight"] <= n
         for n in [1, 2, 3, 5])
passed += report("T6_no_max_concurrent_violations", ok); total += 1

# T7
r = simulate({"task-001": []}, 2, failures={"task-001"})
ok = (r["final_status"]["task-001"] == "Failed")
passed += report("T7_fixed_point_with_all_failed", ok); total += 1

print()
print(f"Results: {passed} passed, {total - passed} failed")
import sys
sys.exit(0 if passed == total else 1)
PYEOF

echo "test-pool-dispatch.sh — symbolic pool simulation"
echo "================================================="
python "$SIM_PY"
exit $?
