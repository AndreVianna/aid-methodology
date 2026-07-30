#!/usr/bin/env pwsh
# pwsh-exitcode-probe-child.ps1 -- fixture child for the task-015 spike
# (work-024 delivery-003, feature-004 "DETAIL's first gate" / Risk R4).
#
# Purpose:
#   A throwaway script the probe driver (pwsh-exitcode-probe.ps1) invokes in a
#   FRESH child runspace in FILE mode -- the EXACT form pwsh-responder.ps1 uses.
#   It reports its self-location automatic variables (so the driver can prove
#   $PSCommandPath / $MyInvocation.MyCommand.Path are non-empty => _PipedMode is
#   false => AID_CODE_HOME self-locates), echoes the args it received (so the
#   driver can prove @args splatting survives spaces), then exits with a known
#   code (3) so the driver can prove the exit code is recoverable.
#
# NOT a glob-discovered test-*.sh canonical suite (suite count unaffected).
# ASCII-only + LF. In-box only (no Add-Type).

"PSCommandPath=[$PSCommandPath]"
"MyInvocationPath=[$($MyInvocation.MyCommand.Path)]"
"ArgsSeen=[$($args -join ',')]"
exit 3
