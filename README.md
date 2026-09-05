# Active Directory Extras (Community Fork)

A settings page for tuning Samba/winbind Active Directory idmap behavior on
Unraid, and persisting winbind's TDB databases across reboots (Unraid's OS
partition is RAM-based, so these are normally lost on every restart).

## ⚠️ Fork Notice / Provenance

This is a **community-maintained fork** of the `active.directory` plugin
originally written by **Dan Landon (dlandon)**.

- The original repository (`github.com/dlandon/active.directory`) has been
  removed from GitHub.
- The original support thread on the Unraid forums has had no response from
  the author — including direct questions about the plugin's status — since
  his last post on **February 14, 2025**.
- As of **August 23, 2026**, the author's GitHub profile shows a reduced
  repository count compared to earlier, consistent with other plugins being
  taken down as well, not just this one.

Given the lack of a live upstream to contribute to, this fork exists to keep
the plugin functional and maintained on current Unraid releases. It is
**not** affiliated with or endorsed by the original author. If Dan Landon
resumes maintenance of the original, users should prefer his version and
this fork will be marked as superseded.

All original copyright and license terms are preserved.

## What it does

- Adds a settings section under **Settings → SMB** (visible only when the
  share security mode is set to Active Directory) for tuning:
  - Domain/default idmap backend and range
  - Idmap positive/negative cache time
  - Winbind cache time
- Adds `map acl inherit = yes` and `store dos attributes = yes` globally,
  and `vfs objects = acl_xattr` to every SMB share, so ACLs set from
  Windows/AD persist correctly on the underlying filesystem.
- Backs up winbind's `.tdb` databases to the flash drive on shutdown and
  restores them on startup, so AD SID↔UID/GID mappings and cached domain
  state survive a reboot instead of resetting every time.

## Installation

1. In Unraid, go to **Plugins → Install Plugin** and paste:
   ```
   https://raw.githubusercontent.com/joshmans/unraid-active-directory-extras/master/active.directory.plg
   ```
2. Or search for it by name in the **Apps** tab once it's listed in
   Community Applications.

## Compatibility

- Minimum Unraid version: 6.9.x
- Tested up to version: 7.3.2

## Changelog

See [`CHANGES.md`](./CHANGES.md) (kept separate from the `.plg`'s embedded
`<CHANGES>` block so it's easier to read on GitHub; the `.plg` block should
stay in sync with this for CA's changelog viewer).

## Contributing

Issues and PRs welcome. Please run `shellcheck` against any `.sh`/`rc.*`
scripts and `php -l` against any PHP before submitting.

## License

GPLv2, same as upstream.

Original copyright (C) 2023–2025 Dan Landon.

Fork maintenance copyright (C) 2026 Josh Mans

## Support

Open an issue on this repository
