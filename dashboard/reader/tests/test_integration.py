"""
test_integration.py -- Producer<->consumer round-trip integration test (feature-002, task-012).

PART 3 of the task-012 implementation.

Drives a realistic sequence of state transitions using the REAL
`canonical/scripts/execute/writeback-state.sh --pipeline` producer (invoked as a
subprocess FROM THE TEST -- the reader itself must not shell out).

This test proves that feature-001's producer and feature-002's consumer AGREE
end-to-end: a STATE.md written by writeback-state.sh is correctly read back by
read_repo() with the expected lifecycle, source_mode, phase, active_skill, and
conditional fields (pause_reason / block_reason / block_artifact).

Round-trip sequence:
  1. Seed a fresh scratch STATE.md from canonical/templates/work-state-template.md
  2. Producer: write Running + Execute + aid-execute -> Consumer: assert Running / normalized
  3. Producer: write Paused-Awaiting-Input + Pause Reason -> Consumer: assert Paused + pause_reason
  4. Producer: write Blocked + Block Reason + Block Artifact -> Consumer: assert Blocked + artifact
  5. Producer: write Running (transition back) -> Consumer: assert Running + conditional fields cleared

Skip behavior:
  - If writeback-state.sh is not found at the expected path, the whole class is
    SKIPPED (unittest.skip), not failed. The path IS present in this repo so a
    skip is a signal the test environment is non-standard.
  - If bash is not available, also skip.

The reader's contract (NFR2): read_repo() itself never calls subprocess.
The TEST may call subprocess -- that is the point (it drives the PRODUCER).

Python 3.11+ stdlib only. No third-party deps.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Optional

# Make the dashboard package importable when run directly or via python3 -m unittest.
# parents[3] is the AID repo root (AID/dashboard/reader/tests/<this file>).
# parents[4] also works for Python imports (sibling dir context), but we need
# parents[3] for filesystem path resolution (writeback-state.sh, template, etc.).
_REPO_ROOT = Path(__file__).resolve().parents[3]  # AID/
sys.path.insert(0, str(_REPO_ROOT))

from dashboard.reader import (
    Lifecycle,
    Phase,
    read_repo,
)
from dashboard.reader.models import SourceMode

# ---------------------------------------------------------------------------
# Locate the producer script and bash
# ---------------------------------------------------------------------------

_WRITEBACK_PATH = _REPO_ROOT / "canonical" / "scripts" / "execute" / "writeback-state.sh"
_WORK_STATE_TEMPLATE = _REPO_ROOT / "canonical" / "templates" / "work-state-template.md"

_BASH = shutil.which("bash")
_PRODUCER_AVAILABLE = _WRITEBACK_PATH.is_file() and _BASH is not None


def _skip_if_no_producer(test_class):
    """Class decorator: skip the whole class if the producer is not available."""
    if not _PRODUCER_AVAILABLE:
        reasons = []
        if not _WRITEBACK_PATH.is_file():
            reasons.append(f"writeback-state.sh not found at {_WRITEBACK_PATH}")
        if _BASH is None:
            reasons.append("bash not found in PATH")
        return unittest.skip("; ".join(reasons))(test_class)
    return test_class


# ---------------------------------------------------------------------------
# Producer helper
# ---------------------------------------------------------------------------

def _run_pipeline(
    state_file: Path,
    lock_dir: Path,
    field: str,
    value: str,
    timeout: int = 30,
) -> None:
    """Invoke writeback-state.sh --pipeline --field FIELD --value VALUE.

    This is the ONLY place in this file that calls subprocess.
    The reader (read_repo) is NEVER passed a subprocess; it reads only files.

    Raises subprocess.CalledProcessError on non-zero exit.
    """
    env = os.environ.copy()
    env["AID_STATE_FILE"] = str(state_file)
    env["AID_LOCK_DIR"] = str(lock_dir)
    # Reduce lock timeout for tests (quicker failure on contention)
    env["AID_LOCK_TIMEOUT"] = "5"

    result = subprocess.run(
        [_BASH, str(_WRITEBACK_PATH), "--pipeline", "--field", field, "--value", value],
        capture_output=True,
        text=True,
        timeout=timeout,
        env=env,
    )
    if result.returncode != 0:
        raise subprocess.CalledProcessError(
            result.returncode,
            f"writeback-state.sh --pipeline --field {field!r} --value {value!r}",
            output=result.stdout,
            stderr=result.stderr,
        )


# ---------------------------------------------------------------------------
# Integration test class
# ---------------------------------------------------------------------------

@_skip_if_no_producer
class TestProducerConsumerRoundTrip(unittest.TestCase):
    """PART 3: Feature-001 producer <-> Feature-002 consumer end-to-end round trip.

    Drives writeback-state.sh --pipeline (the REAL producer) to write STATE.md
    and then runs read_repo() (the REAL consumer) to verify the reader correctly
    interprets what the producer wrote.

    This test proves the state-architecture change is consumable as intended.
    """

    def setUp(self):
        """Create a fresh scratch repo seeded from the real work-state-template.md."""
        self.tmp = tempfile.mkdtemp()
        self.root = Path(self.tmp)

        # Build the minimal .aid/ tree
        self.aid_dir = self.root / ".aid"
        self.aid_dir.mkdir(parents=True)

        # Manifest
        manifest = {
            "manifest_version": 1,
            "aid_version": "1.0.0",
            "installed_at": "2026-06-10T00:00:00Z",
            "tools": {
                "claude-code": {
                    "version": "1.0.0",
                    "installed_at": "2026-06-10T00:00:00Z",
                    "paths": [],
                    "root_agent_files": [],
                }
            },
        }
        (self.aid_dir / ".aid-manifest.json").write_text(
            json.dumps(manifest), encoding="utf-8"
        )

        # Settings
        (self.aid_dir / "settings.yml").write_text(
            "project:\n  name: IntegrationTestProject\n",
            encoding="utf-8",
        )

        # Work folder seeded from the real template
        self.work_dir = self.aid_dir / "work-001-integration-test"
        self.work_dir.mkdir()
        self.state_file = self.work_dir / "STATE.md"

        if _WORK_STATE_TEMPLATE.is_file():
            template_text = _WORK_STATE_TEMPLATE.read_text(encoding="utf-8")
            # Replace the placeholder work name with our test work name
            seeded_text = template_text.replace(
                "work-NNN-{name}", "work-001-integration-test"
            )
            self.state_file.write_text(seeded_text, encoding="utf-8")
        else:
            # Fallback: write a minimal STATE.md if template not found
            self.state_file.write_text(
                "# Work State -- work-001-integration-test\n\n",
                encoding="utf-8",
            )

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _produce(self, field: str, value: str) -> None:
        """Call writeback-state.sh --pipeline; fail the test on error."""
        try:
            _run_pipeline(self.state_file, self.work_dir, field, value)
        except subprocess.CalledProcessError as exc:
            self.fail(
                f"writeback-state.sh failed for field={field!r} value={value!r}: "
                f"exit={exc.returncode}\nstdout: {exc.output}\nstderr: {exc.stderr}"
            )
        except subprocess.TimeoutExpired:
            self.fail(
                f"writeback-state.sh timed out for field={field!r} value={value!r}"
            )

    # -------------------------------------------------------------------------
    # Step 2: Running -> read -> assert Running / normalized
    # -------------------------------------------------------------------------

    def test_step2_running_execute_aid_execute(self):
        """Step 2: Producer writes Running + Execute + aid-execute.
        Consumer reads it back and returns Running (source_mode=normalized).

        Proves:
        - writeback-state.sh --pipeline creates a parseable ## Pipeline Status block
        - read_repo() returns Lifecycle.Running from the normalized block
        - Phase = Execute, active_skill = aid-execute
        - source_mode = normalized (block present)
        - work not in fallback_works
        """
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Execute")
        self._produce("Active Skill", "aid-execute")
        self._produce("Updated", "2026-06-10T15:00:00Z")

        model = read_repo(self.root)

        self.assertEqual(model.read.work_count, 1)
        w = model.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running,
                         "Reader must return Running after producer wrote Running")
        self.assertEqual(w.source_mode, SourceMode.Normalized,
                         "Pipeline Status block present -> source_mode=normalized")
        self.assertEqual(w.phase, Phase.Execute,
                         "Phase must match what the producer wrote")
        self.assertEqual(w.active_skill, "aid-execute",
                         "Active Skill must match what the producer wrote")
        self.assertNotIn("work-001-integration-test", model.read.fallback_works,
                         "Normalized work must not appear in fallback_works")

    # -------------------------------------------------------------------------
    # Step 3: Paused-Awaiting-Input -> read -> assert Paused + pause_reason
    # -------------------------------------------------------------------------

    def test_step3_paused_with_pause_reason(self):
        """Step 3: Producer writes Paused-Awaiting-Input + Pause Reason.
        Consumer reads it back and returns PausedAwaitingInput with pause_reason.

        Proves:
        - Lifecycle change to Paused-Awaiting-Input is correctly read
        - Pause Reason field is surfaced in the model
        - source_mode remains normalized
        """
        # Seed with Running first (the typical prior state)
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Specify")
        self._produce("Active Skill", "aid-specify")
        self._produce("Updated", "2026-06-10T14:00:00Z")

        # Transition to Paused
        self._produce("Lifecycle", "Paused-Awaiting-Input")
        self._produce("Pause Reason", "Awaiting user decision on architecture choice")

        model = read_repo(self.root)
        w = model.works[0]

        self.assertEqual(w.lifecycle, Lifecycle.PausedAwaitingInput,
                         "Reader must return PausedAwaitingInput after producer wrote it")
        self.assertEqual(w.source_mode, SourceMode.Normalized)
        self.assertIsNotNone(w.pause_reason,
                             "pause_reason must be populated from the Pause Reason field")
        self.assertIn("architecture", w.pause_reason.lower(),
                      "pause_reason content must match what the producer wrote")
        # block fields must be absent (Paused is not Blocked)
        self.assertIsNone(w.block_reason)
        self.assertIsNone(w.block_artifact)

    # -------------------------------------------------------------------------
    # Step 4: Blocked + Block Reason + Block Artifact -> read -> assert Blocked
    # -------------------------------------------------------------------------

    def test_step4_blocked_with_artifact(self):
        """Step 4: Producer writes Blocked + Block Reason + Block Artifact.
        Consumer reads it back and returns Blocked with block_reason + block_artifact.

        Proves:
        - Lifecycle.Blocked is correctly consumed
        - Block Reason field surfaced in model
        - Block Artifact path surfaced in model
        """
        # Seed through a Running state first
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Execute")
        self._produce("Active Skill", "aid-execute")

        # Transition to Blocked
        self._produce("Lifecycle", "Blocked")
        self._produce("Block Reason", "Reviewer found critical security issue")
        self._produce("Block Artifact", "IMPEDIMENT-task-007.md")

        model = read_repo(self.root)
        w = model.works[0]

        self.assertEqual(w.lifecycle, Lifecycle.Blocked,
                         "Reader must return Blocked after producer wrote it")
        self.assertEqual(w.source_mode, SourceMode.Normalized)
        self.assertIsNotNone(w.block_reason,
                             "block_reason must be populated from Block Reason field")
        self.assertIn("security", w.block_reason.lower(),
                      "block_reason must match what the producer wrote")
        self.assertIsNotNone(w.block_artifact,
                             "block_artifact must be populated from Block Artifact field")
        self.assertEqual(w.block_artifact, "IMPEDIMENT-task-007.md",
                         "block_artifact must match the artifact path the producer wrote")
        # pause_reason must be absent (Blocked is not Paused)
        self.assertIsNone(w.pause_reason)

    # -------------------------------------------------------------------------
    # Step 5: Transition back to Running -> conditional fields cleared
    # -------------------------------------------------------------------------

    def test_step5_running_clears_conditional_fields(self):
        """Step 5: Produce Blocked then transition back to Running.
        The reader must see Running with no block/pause fields.

        This proves the conditional-field clearing mechanism of the producer
        (writeback-state.sh clears Block Reason + Block Artifact on Lifecycle change
        away from Blocked) is reflected in the consumer.
        """
        # Blocked state
        self._produce("Lifecycle", "Blocked")
        self._produce("Block Reason", "Impediment raised in task-007")
        self._produce("Block Artifact", "IMPEDIMENT-task-007.md")

        # Verify it reads as Blocked first
        model = read_repo(self.root)
        self.assertEqual(model.works[0].lifecycle, Lifecycle.Blocked)

        # Transition back to Running (producer clears conditional fields)
        self._produce("Lifecycle", "Running")

        model = read_repo(self.root)
        w = model.works[0]

        self.assertEqual(w.lifecycle, Lifecycle.Running,
                         "After transitioning back to Running, reader must see Running")
        self.assertIsNone(w.block_reason,
                          "block_reason must be cleared after transition to Running")
        self.assertIsNone(w.block_artifact,
                          "block_artifact must be cleared after transition to Running")
        self.assertIsNone(w.pause_reason,
                          "pause_reason must be absent after transition to Running")

    # -------------------------------------------------------------------------
    # Full sequence: Running -> Paused -> Blocked -> Running
    # -------------------------------------------------------------------------

    def test_full_sequence_round_trip(self):
        """Full round-trip: Running -> Paused -> Blocked -> Running.

        Each state is verified immediately after the producer writes it.
        Proves the entire state-architecture change is consumable end-to-end
        in the sequence a real pipeline would execute.
        """
        # --- Running ---
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Execute")
        self._produce("Active Skill", "aid-execute")
        self._produce("Updated", "2026-06-10T12:00:00Z")

        m = read_repo(self.root)
        w = m.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running, "Step 1: must be Running")
        self.assertEqual(w.source_mode, SourceMode.Normalized, "Step 1: normalized path")
        self.assertEqual(w.phase, Phase.Execute, "Step 1: phase Execute")
        self.assertEqual(w.active_skill, "aid-execute", "Step 1: active skill")

        # --- Paused ---
        self._produce("Lifecycle", "Paused-Awaiting-Input")
        self._produce("Pause Reason", "Waiting for DB technology decision")

        m = read_repo(self.root)
        w = m.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.PausedAwaitingInput, "Step 2: must be Paused")
        self.assertIsNotNone(w.pause_reason, "Step 2: pause_reason set")
        self.assertIn("DB", w.pause_reason, "Step 2: pause_reason content preserved")

        # --- Blocked ---
        self._produce("Lifecycle", "Blocked")
        self._produce("Block Reason", "Task 009 review failed")
        self._produce("Block Artifact", "IMPEDIMENT-task-009.md")

        m = read_repo(self.root)
        w = m.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Blocked, "Step 3: must be Blocked")
        self.assertIsNotNone(w.block_reason, "Step 3: block_reason set")
        self.assertIsNotNone(w.block_artifact, "Step 3: block_artifact set")
        self.assertEqual(w.block_artifact, "IMPEDIMENT-task-009.md",
                         "Step 3: block_artifact path correct")
        # Pause Reason must have been cleared by the Blocked transition
        self.assertIsNone(w.pause_reason, "Step 3: pause_reason cleared on Blocked transition")

        # --- Back to Running (impediment resolved) ---
        self._produce("Lifecycle", "Running")

        m = read_repo(self.root)
        w = m.works[0]
        self.assertEqual(w.lifecycle, Lifecycle.Running, "Step 4: back to Running")
        self.assertIsNone(w.block_reason, "Step 4: block_reason cleared")
        self.assertIsNone(w.block_artifact, "Step 4: block_artifact cleared")
        self.assertIsNone(w.pause_reason, "Step 4: pause_reason still cleared")
        self.assertNotIn("work-001-integration-test", m.read.fallback_works,
                         "Step 4: still normalized throughout")

    # -------------------------------------------------------------------------
    # Idempotency: multiple reads of the same STATE.md return the same result
    # -------------------------------------------------------------------------

    def test_idempotent_read(self):
        """read_repo() is idempotent: reading the same STATE.md twice gives the same result."""
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Execute")
        self._produce("Active Skill", "aid-execute")

        model1 = read_repo(self.root)
        model2 = read_repo(self.root)

        self.assertEqual(model1.works[0].lifecycle, model2.works[0].lifecycle)
        self.assertEqual(model1.works[0].source_mode, model2.works[0].source_mode)
        self.assertEqual(model1.works[0].phase, model2.works[0].phase)
        self.assertEqual(model1.works[0].active_skill, model2.works[0].active_skill)

    # -------------------------------------------------------------------------
    # bytes_read and provenance fields
    # -------------------------------------------------------------------------

    def test_bytes_read_after_producer_write(self):
        """bytes_read must be > 0 after the producer has written STATE.md."""
        self._produce("Lifecycle", "Running")
        model = read_repo(self.root)
        self.assertGreater(model.read.bytes_read, 0,
                           "bytes_read must be positive after producer has written STATE.md")

    def test_read_at_is_iso8601(self):
        """read_at must be a valid ISO-8601 timestamp."""
        self._produce("Lifecycle", "Running")
        model = read_repo(self.root)
        self.assertIn("T", model.read.read_at, "read_at must contain 'T' (ISO-8601)")

    def test_work_id_correct(self):
        """work_id must match the directory name exactly."""
        self._produce("Lifecycle", "Running")
        model = read_repo(self.root)
        self.assertEqual(model.works[0].work_id, "work-001-integration-test")

    def test_name_slug_extracted(self):
        """WorkModel.name must be the slug portion (work-NNN- stripped)."""
        self._produce("Lifecycle", "Running")
        model = read_repo(self.root)
        self.assertEqual(model.works[0].name, "integration-test")

    # -------------------------------------------------------------------------
    # M6: Completed emit (task-013) -- normalized Completed path
    # -------------------------------------------------------------------------

    def test_m6_completed_emit_normalized(self):
        """M6 (task-013): Producer writes Lifecycle: Completed (state-done.md pattern).
        Consumer reads it back as Lifecycle.Completed with source_mode=normalized.

        This proves the M6 Completed emit added to state-done.md is correctly consumed
        by the reader. A work that reaches the DONE state will emit Completed to the
        ## Pipeline Status block; the reader must return Completed (not Running forever).

        Without the M6 emit, a finished work would have read as Running indefinitely
        (the last Running emit from state-idle.md / state-execute.md). This test
        confirms the integration gap is closed.
        """
        # Simulate full pipeline flow: work runs, then completes (state-done.md emit)
        self._produce("Lifecycle", "Running")
        self._produce("Phase", "Deploy")
        self._produce("Active Skill", "aid-deploy")
        self._produce("Updated", "2026-06-11T10:00:00Z")

        # Verify Running before completion
        model = read_repo(self.root)
        self.assertEqual(model.works[0].lifecycle, Lifecycle.Running)

        # Emit Completed (mirrors state-done.md Step 10)
        self._produce("Lifecycle", "Completed")
        self._produce("Active Skill", "none")
        self._produce("Updated", "2026-06-11T10:05:00Z")

        model = read_repo(self.root)
        w = model.works[0]

        self.assertEqual(w.lifecycle, Lifecycle.Completed,
                         "Reader must return Completed after state-done.md emits Lifecycle: Completed")
        self.assertEqual(w.source_mode, SourceMode.Normalized,
                         "Completed via ## Pipeline Status -> source_mode=normalized")
        self.assertIsNone(w.active_skill,
                          "active_skill must be none after DONE state (state-done.md sets it to none)")
        self.assertIsNone(w.block_reason,
                          "Completed work must have no block_reason")
        self.assertIsNone(w.pause_reason,
                          "Completed work must have no pause_reason")
        self.assertNotIn("work-001-integration-test", model.read.fallback_works,
                         "Completed normalized work must not appear in fallback_works")

    def test_m6_completed_not_in_fallback_works(self):
        """M6: A work that emits Completed via ## Pipeline Status is NOT in fallback_works.

        ReadMeta.fallback_works accurately reflects the reduced fallback surface:
        a normalized Completed work is not a fallback work.
        """
        # Seed a Completed state via the normalized path
        self._produce("Lifecycle", "Completed")
        self._produce("Active Skill", "none")

        model = read_repo(self.root)

        self.assertEqual(model.works[0].lifecycle, Lifecycle.Completed)
        self.assertEqual(model.works[0].source_mode, SourceMode.Normalized)
        self.assertEqual(model.read.fallback_works, [],
                         "fallback_works must be empty for a normalized Completed work")


# ---------------------------------------------------------------------------
# Verify the test module itself doesn't import forbidden modules
# (meta-test: the TEST may use subprocess; the READER must not)
# ---------------------------------------------------------------------------

class TestIntegrationModuleSelfCheck(unittest.TestCase):
    """Self-check: confirm this module correctly uses subprocess ONLY in the test,
    never in the reader modules.

    This is a meta-check that:
    1. The reader modules (verified exhaustively in test_fixtures.py) are still clean
    2. This test module itself correctly shells out only for the PRODUCER
    """

    def test_reader_modules_still_clean_after_integration(self):
        """Reader modules must still pass the read-only check after integration.

        A regression guard: if someone accidentally added a subprocess call
        to a reader module while implementing the integration test, this catches it.
        """
        import ast

        reader_dir = Path(__file__).resolve().parents[1]
        modules = [
            reader_dir / "locator.py",
            reader_dir / "parsers.py",
            reader_dir / "reader.py",
            reader_dir / "models.py",
            reader_dir / "derivation.py",
        ]

        for mod_path in modules:
            source = mod_path.read_text(encoding="utf-8")
            # Check no subprocess import was added
            self.assertNotIn(
                "import subprocess",
                source,
                f"{mod_path.name}: subprocess must not be imported in reader modules",
            )
            # Check no Popen was added
            self.assertNotIn(
                "Popen",
                source,
                f"{mod_path.name}: Popen must not appear in reader modules",
            )

    def test_this_module_uses_subprocess_only_in_test(self):
        """Sanity: this test module DOES import subprocess (for the producer).
        That is correct and expected. The reader modules must NOT.
        """
        # Confirm subprocess IS imported in this test module (expected)
        this_source = Path(__file__).read_text(encoding="utf-8")
        self.assertIn("import subprocess", this_source,
                      "test_integration.py must import subprocess (for the producer)")

    def test_producer_available_or_skip_reported(self):
        """Confirm that the producer either exists or the round-trip tests are skipped."""
        # This test itself always runs (not decorated with @_skip_if_no_producer).
        # It verifies that the skip mechanism is in place.
        if not _PRODUCER_AVAILABLE:
            # If producer is not available, the round-trip class must be skipped.
            # This test passes because we document the skip rather than failing.
            self.skipTest(
                f"Producer not available -- "
                f"writeback_found={_WRITEBACK_PATH.is_file()}, bash_found={_BASH is not None}. "
                f"Round-trip tests are SKIPPED (not failed)."
            )
        else:
            # Producer is available -- confirm the path is correct
            self.assertTrue(
                _WRITEBACK_PATH.is_file(),
                f"writeback-state.sh must exist at {_WRITEBACK_PATH}",
            )
            self.assertIsNotNone(_BASH, "bash must be available in PATH")


if __name__ == "__main__":
    unittest.main(verbosity=2)
