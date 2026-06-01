# Encoding Guidance

AutoLoop scripts and templates should be boring to inspect from Windows PowerShell.

## Script Rules

- Use `Get-Content -Encoding UTF8` when scripts read Markdown or template files.
- Use `Set-Content -Encoding UTF8` when scripts create or update Markdown files.
- Prefer ASCII for core operational templates and command examples when it does not reduce clarity.
- Keep Chinese prompts or explanatory documents as UTF-8 Markdown when they are useful, but read them with `-Encoding UTF8` from Windows PowerShell.

## Operator Notes

If Chinese text looks like mojibake in Windows PowerShell, rerun the read with explicit UTF-8:

```powershell
Get-Content -Encoding UTF8 -LiteralPath <file.md>
```

Do not treat display mojibake as proof that the file content is corrupted. Verify with explicit UTF-8 first.
