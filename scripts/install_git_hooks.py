from __future__ import annotations

import os
import subprocess
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    subprocess.run(["git", "config", "core.hooksPath", ".githooks"], check=True, cwd=repo_root)

    hook = repo_root / ".githooks" / "pre-commit"
    if not hook.exists():
        print("missing hook file: .githooks/pre-commit")
        return 1

    if os.name != "nt":
        hook.chmod(hook.stat().st_mode | 0o111)

    print("Configured git hooks:")
    print("  core.hooksPath = .githooks")
    print("  hook: pre-commit")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
