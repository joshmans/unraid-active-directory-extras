# Active Directory Extras

## 2026.11.24

- Packaging only, no change to how the plugin works: the package is now built and published by GitHub Actions, and the plugin file downloads it from the GitHub release instead of from a file kept in the repository. The package is a `.txz` of the same files.

## 2026.09.26a
- Security: The Rejoin/Leave Domain password is no longer sent through Unraid's
  update.php, which logs every command argument to the syslog. It is POSTed to
  the plugin's own endpoint and given to `net` on stdin: never an argument,
  never logged. The ad_join/ad_leave commands are removed from
  rc.active.directory.
- Security: The TDB backup folder is only used if it is owned by root and not
  writable by group or others (else the flash-drive default is used), and only
  root-owned regular files are restored: a folder inside a writable SMB share
  could otherwise be used to plant a crafted idmap database that is restored as
  root at boot.
- Security: The settings file is read, not sourced, so a value like $(command)
  in a field is no longer run as root; backend and cache-time values are
  validated before they reach the Samba config.
- Fix: Values under "Current AD Settings" are HTML-escaped; the join check on
  the page times out after 15 seconds; smb-shares.conf is written atomically.

## 2026.09.26
- Fix: "Backend Database" and "Backend Range" under "Current AD Settings"
  showed a stray "=" above the real value when a Domain Name idmap was
  configured (the default-domain lookup also matched the named domain's line).

## 2026.09.25a
- Fix: "Current AD Settings" shows the domain's effective idmap backend and
  range as Samba sees them (whoever configured them), or "not set".
- Fix: Corrected the Domain Name help text: domain users are mapped by
  whatever Samba is otherwise configured with; a name set here overrides any
  idmap config for that domain in SMB Extras.

## 2026.09.25
- Fix: The Domain Backend Database/Range settings were written for a domain
  literally named DOMAIN, so they never took effect and winbind logged
  "Lookup domain name 'domain' failed" at every start. They now apply only
  when the new optional Domain Name field is set (empty by default, so
  existing setups are unchanged and the message goes away).

## 2026.09.10
- Fix: Remove stray leading colon next to Rejoin/Leave Domain buttons;
  disable Rejoin when already joined.

## 2026.09.09
- Add: Rejoin/Leave Domain controls, replacing Unraid's stock AD Join/Leave
  form when the security mode is already Active Directory. Rejoin re-joins
  the currently configured domain without stopping the array or restarting
  Samba. Leave Domain requires the same AD login/password. A "Change Domain"
  link reveals the original stock form for joining a different domain.
  Credentials are not persisted; the password is base64-obfuscated
  client-side before submission to avoid Unraid's update.php dispatcher
  logging it to syslog in cleartext.
- Fix: AD Rejoin/Leave now passes the account password to net ads join/
  net ads leave via stdin instead of as a command-line argument, removing
  the last window where the plaintext password was visible via ps/proc.

## 2026.09.04
- Add: Configurable TDB backup destination (flash vs array/cache).
- Fix: Add missing TDB_BACKUP_PATH default to default.cfg, so the
  '#default' button correctly resets the backup path field.

## 2026.09.03
- Add: Live AD join status via wbinfo/net ads testjoin, replacing the built-in indicator.
- Add: Confirmation dialog before Clear Cache, since clearing the cache
  restarts Samba and drops any active SMB connections.
- Change: Remove incomplete LDAP option from Backend Database dropdown.
- Add: Enable and validate Domain Range / Backend Range fields.
- Fix: Surface clear_winbind_cache() success/failure to the GUI instead of failing silently.
- Change: Set max supported Unraid version to 7.3.2 (confirmed working),
  preventing standard installation on untested future Unraid releases.

## 2026.08.25a
- Fork: Rebranded plugin manifest for community fork — updated author,
  gitURL, and supportURL to point at the maintained fork instead of the
  removed upstream repository. See README.md for full provenance.
- Change: Use SHA256 instead of MD5 for package integrity verification.

## 2026.08.25
- Fix: Surface apply_settings() success/failure to the GUI instead of failing silently.

## 2026.08.24
- Fix: Per-file TDB backup retention instead of global retention.
- Fix: Atomic staging for TDB backup and restore to avoid partial-write corruption.
- Fix: Validate TDB integrity before restoring, fall back to older generation.

## 2025.02.15
- Fix: Don't check for AD being enabled on startup or shutdown.

## 2025.01.29
- Fix: Undefined file error.

## 2025.01.18
- Fix: Undefined variable error.

## 2024.01.15
- Fix: Restart Samba when restoring databases.

## 2025.01.09a
- Fix: Some code changes for reliability and robustness.
- Add: Set permissions when restoring the databases.

## 2024.12.28
- Fix: AD Extras page not showing when AD enabled.

## 2024.12.27a
- Fix: Change some php variables to constants that don't need to be variables.
- Add: Database files are stored on the flash drive, so they will be persistent.
- Add: Database files are backuped up to the /flash when Unraid is shut down.
- Add: Database files are restored from the /flash on Unraid startup.
- Add: Database cleanup is performed on shutdown to limit backups to 5.

## 2024.08.08
- Fix: In certain cases "vfs objects" gets set to "vfs objects = vfs objects = acl_xattr".

## 2024.05.12
- Add: Don't apply AD settings if AD is not selected in SMB.

## 2024.04.30
- Fix: Some code cleanup.
- Add: Disable 'Active Directory Extras' page when AD not selected in SMB.

## 2024.04.28
- Add: Samba settings: 'map acl inherit = yes', and 'store dos attributes = yes' to global settings.
- Add: Samba settings: 'vfs objects = acl_xattr' to every share.

## 2023.07.08
- Add: Show default values for 'winbind cache time' and 'idmap cache time' if values are not explicitly set.
- Add: Clear Cache button to clear the winbind cache and restart Samba.

## 2023.07.07a
- Fix: Add icon to settings tab.
- Fix: Plugin not showing correctly on plugins page.
- Add: Submit to CA.

## 2023.04.07
- Fix: Set lowest Unraid version 6.9.0.

## 2023.04.06
- Add: Plugin update detection.
- Add: 'idmap negative cache time' setting.

## 2023.04.05
- Initial Unraid V6.11.5 release.
