#!/usr/bin/env python3
# aid_installer/__main__.py - PyPI channel shim for the AID CLI.
#
# Purpose:
#   Installed as the `aid` entry point when the user runs
#   `pipx install aid-installer` or `pip install --user aid-installer`.
#   Spawns the vendored bin/aid (bash) or bin/aid.ps1 (pwsh/powershell) with
#   AID_INSTALL_CHANNEL=pypi injected into the child environment so that
#   `aid update self` prints the pipx upgrade hint instead of re-bootstrapping.
#
# Runtime selection:
#   Windows  -> try pwsh first, then powershell (with -NoLogo -NonInteractive -File)
#   All else -> bash bin/aid
#
# argv forwarding: sys.argv[1:] is spread as a list into subprocess.run args
#   (no shell=True) so spaces and shell metacharacters in arguments are safe.

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> None:
    # Payload root: _vendor/ lives next to this file.
    vendor_root = Path(__file__).parent / "_vendor"

    # Inject channel so `aid update self` prints the pipx advice.
    os.environ["AID_INSTALL_CHANNEL"] = "pypi"

    user_args = sys.argv[1:]

    if os.name == "nt":
        # Windows: try pwsh (PowerShell 7+) first, fall back to powershell 5.1.
        ps1 = vendor_root / "bin" / "aid.ps1"
        fixed_flags = ["-NoLogo", "-NonInteractive", "-File", str(ps1)]

        pwsh = shutil.which("pwsh")
        if pwsh is not None:
            proc = subprocess.run(
                [pwsh] + fixed_flags + user_args,
                check=False,
            )
            sys.exit(proc.returncode)

        powershell = shutil.which("powershell")
        if powershell is not None:
            proc = subprocess.run(
                [powershell] + fixed_flags + user_args,
                check=False,
            )
            sys.exit(proc.returncode)

        sys.stderr.write(
            "ERROR: aid: neither pwsh nor powershell found on PATH."
            " Install PowerShell to use the aid CLI.\n"
        )
        sys.exit(1)
    else:
        # Unix/macOS: bash + bin/aid.
        bash = shutil.which("bash")
        if bash is None:
            sys.stderr.write(
                "ERROR: aid: bash not found on PATH."
                " Install bash to use the aid CLI.\n"
            )
            sys.exit(1)

        aid_sh = vendor_root / "bin" / "aid"
        proc = subprocess.run(
            [bash, str(aid_sh)] + user_args,
            check=False,
        )
        sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
