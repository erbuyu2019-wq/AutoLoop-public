## Summary

- Describe the change.

## Scope

- Changed:
- Not changed:

## Verification

- [ ] `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\verify-autoloop.ps1`
- [ ] `git diff --check`

## Boundary Check

- [ ] This change keeps AutoLoop focused on lightweight coordination and evidence gates.
- [ ] This change does not add daemon, GUI, automatic Codex Desktop thread control, automatic dispatch, merge, release, deployment, credential handling, hardware handling, or production behavior.
- [ ] This change does not include private project data, credentials, generated runtime artifacts, or target-project files.
