from __future__ import annotations

import os
import subprocess


def _run_bytes(args: list[str]) -> bytes | None:
    proc = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        return None
    return proc.stdout


def _get_staged_paths() -> list[str]:
    out = _run_bytes([
        "git",
        "diff",
        "--cached",
        "--name-only",
        "--diff-filter=ACMRTUXB",
        "-z",
    ])
    if out is None:
        return []
    return [p.decode("utf-8", errors="replace") for p in out.split(b"\x00") if p]


def _get_staged_blob(path: str) -> bytes | None:
    return _run_bytes(["git", "show", f":{path}"])


def _is_binary(data: bytes) -> bool:
    return b"\x00" in data[:8192]


def main() -> int:
    user_name = os.environ.get("USER_NAME", "").strip()
    if not user_name:
        return 0

    needle = user_name.lower().encode("utf-8", errors="ignore")
    if not needle:
        return 0

    hits: list[str] = []
    for path in _get_staged_paths():
        blob = _get_staged_blob(path)
        if blob is None or _is_binary(blob):
            continue
        if needle in blob.lower():
            hits.append(path)

    if hits:
        print("pre-commit blocked: USER_NAME value detected in staged text files:")
        for path in hits:
            print(f"  - {path}")
        print("Replace the local value with ~, <username>, or another neutral placeholder.")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
