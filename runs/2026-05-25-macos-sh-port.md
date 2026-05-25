# 2026-05-25 macOS sh port

## Summary

Added `txtconcat.sh`, a macOS `/bin/sh` implementation of the txtconcat workflow.

## Scope

- Add the shell implementation.
- Update README usage to prefer `txtconcat.sh`.
- Keep the PowerShell 7 implementation available as `txtconcat.ps1`.

## Verification

```sh
sh -n txtconcat.sh
./txtconcat.sh --help
./txtconcat.sh --source-dir . --prefix txtconcat --extensions .md,.sh --output-dir .
./txtconcat.sh --auto-text --prefix txtconcat --output-dir .
```

All commands completed successfully.

Generated output files are intentionally not committed because they match the
repository's generated-output ignore rules.
