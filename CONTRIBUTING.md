# Contributing

Compass carries portable configuration infrastructure and the reviewed global
definitions selected by its manifest. Contributions should make that boundary
smaller, clearer, safer, or intentionally more capable.

Do not add project guidance, hosted applications, optional packs, source
archives, templates, generic workflow frameworks, or machine state.

Before opening a pull request, run:

```powershell
git diff --check
.\scripts\test-all.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\test-all.ps1
```

Changes to portable sources must preserve preview-first behavior, exact
fingerprint ownership, unrelated live state, config overlay semantics, and
focused round-trip coverage.
