# Contributing

Compass carries the current portable agent setup selected by
`manifests/portable-files.json`. Keep the source small, explicit, and directly
installable.

Do not add project guidance, hosted applications, source archives, templates,
runtime state, or compatibility machinery for previous layouts.

Before opening a pull request, run:

```powershell
git diff --check
.\scripts\test-all.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-all.ps1
```

Portable changes must preserve preview-first installation, backups before
replacement, unlisted live state, path containment, and round-trip coverage.
