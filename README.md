# Active Directory Extras

A settings page for tuning Samba/winbind Active Directory idmap behavior on
Unraid, and persisting winbind's TDB databases across reboots (Unraid's OS
partition is RAM-based, so these are normally lost on every restart).

## Fork Notice / Provenance

This plugin is a continuation of the `active.directory` plugin originally
written by **Dan Landon (dlandon)**.

- The original repository
  ([`github.com/dlandon/active.directory`](https://github.com/dlandon/active.directory))
  was briefly removed from GitHub. It has since been made public again and
  **archived**, and its README now marks the plugin as deprecated and points
  to this repository as the place where development continues.
- This repository is the maintained successor. Bug fixes, new features, and
  compatibility updates for current Unraid releases land here, not upstream.
- If you are still running the original plugin, switch to this one (see
  [Installation](#installation)); the original will no longer receive updates.

This repository is not otherwise affiliated with or endorsed by the original
author beyond the pointer in the archived repository. All original copyright
and license terms are preserved.

## What it does

- Adds a settings section under **Settings → SMB** (visible only when the
  share security mode is set to Active Directory) for tuning:
  - Default idmap backend and range, and (optionally) a backend and range
    for one named domain
  - Idmap positive/negative cache time
  - Winbind cache time
- Adds `map acl inherit = yes` and `store dos attributes = yes` globally,
  and `vfs objects = acl_xattr` to every SMB share, so ACLs set from
  Windows/AD persist correctly on the underlying filesystem.
- Backs up winbind's `.tdb` databases to the flash drive on shutdown and
  restores them on startup, so AD SID↔UID/GID mappings and cached domain
  state survive a reboot instead of resetting every time.

### Domain-specific idmap (optional)

The plugin always writes the default idmap backend and range (`idmap config
*`). Domain users are mapped by whatever Samba is otherwise configured with
for your domain: Unraid's own settings, or `idmap config <domain>` lines in
**SMB Extras**. **Current AD Settings** shows what Samba is actually using.

The **Domain Backend Database** and **Domain Backend Range** apply only if you
enter a **Domain Name** (your domain's NetBIOS name, the workgroup under
Settings → SMB). Leave the name empty unless you need them.

These lines are read after SMB Extras, so they override any `idmap config
<domain>` set there. Changing a domain's backend or range changes how its
users are mapped to Linux UIDs and GIDs, so files already owned by domain
users can end up with the wrong owner. Use it on a new setup, not on one that
already has data owned by domain users.

Earlier versions wrote these settings for a domain literally named `DOMAIN`,
which never matched a real domain, so they had no effect.

## Installation

1. In Unraid, go to **Plugins → Install Plugin** and paste:
   ```
   https://raw.githubusercontent.com/joshmans/unraid-active-directory-extras/main/active.directory.plg
   ```
2. Or search for it by name in the **Apps** tab once it's listed in
   Community Applications.

## Compatibility

- Minimum Unraid version: 6.9.x
- Tested up to version: 7.4.0-beta2

## Changelog

See [`CHANGES.md`](./CHANGES.md) (kept separate from the `.plg`'s embedded
`<CHANGES>` block so it's easier to read on GitHub; the `.plg` block should
stay in sync with this for CA's changelog viewer).

## Contributing

Issues and PRs welcome. Please run `shellcheck` against any `.sh`/`rc.*`
scripts and `php -l` against any PHP before submitting.

## License

GPLv2, same as the original plugin.

Original copyright (C) 2023–2025 Dan Landon.

Maintenance copyright (C) 2026 Josh Mans

## Support

Open an issue on this repository
