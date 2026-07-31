# Portable Scripts

The scripts implement one product boundary:

- `install.ps1` previews or applies the manifest allowlist and safe retirements.
- `verify-live.ps1` checks reviewed source against live agent homes.
- `diff-live.ps1` shows exact source-to-live differences.
- `snapshot.ps1` previews or refreshes only allowlisted source paths.
- `test-all.ps1` runs config, plugin, active bundle, and reset round trips.

`common.ps1`, `portable-data.py`, receipt helpers, config helpers, and plugin
helpers are internal implementation shared by those commands.
