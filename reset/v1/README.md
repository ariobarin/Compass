# Compass v1 reset

This temporary migration retires the global files, directories, config values,
plugins, and marketplaces formerly owned by Compass.

`retire.ps1` previews by default. With `-Apply`, it removes only targets whose
current fingerprint matches the active Compass receipt. `-Adopt` is the explicit
override for a changed or foreign target. Removed material is backed up before
deletion.

`verify.ps1` checks that former targets and reviewed config values are absent.
Runtime-created state is outside this contract.

Run `test-all.ps1` before changing the migration. Delete this directory after
every relevant machine has applied and verified the reset.
