# Changelog

## Unreleased
- Fix: Remove a stray leading colon rendered next to the Rejoin/Leave
  Domain buttons, and disable the Rejoin button when already joined
  (it remains a no-op refresh of the trust secret while joined, but
  greying it out makes the intended action clearer - use Leave Domain
  first if you actually need to join a different account).
- Add: Rejoin/Leave Domain controls, replacing Unraid's stock AD Join/Leave
  form when the security mode is already Active Directory. An always-available
  Rejoin button re-joins the currently configured domain without stopping
  the array or restarting Samba (unlike Unraid's built-in Join button, which
  stops the array unconditionally even for a plain rejoin). Leave Domain
  requires the same AD login/password. A "Change Domain" link reveals the
  original stock form for the case of joining a genuinely different domain,
  which this replacement does not otherwise handle. Credentials are not
  persisted to the plugin's config file; the password is base64-obfuscated
  client-side before submission (not real security, but avoids Unraid's own
  update.php dispatcher logging it to syslog in cleartext).
- Fix: AD Rejoin/Leave now passes the account password to `net ads join`/
  `net ads leave` via stdin instead of as a `-U login%password` command-line
  argument. The prior approach was already protected against syslog exposure
  (see the base64 obfuscation note above), but the plaintext password was
  still visible for the process's lifetime to anything able to read
  `/proc/<pid>/cmdline` on the box - confirmed via direct testing, since
  older Samba documentation and mailing-list reports suggested stdin input
  wasn't supported for this command (it is).
- Fork: Continued as community fork after upstream repository was removed
  and the author became unresponsive. See README.md for details.
- Fix: Per-file TDB backup retention instead of global retention. Backups
  are now written with a timestamp suffix per basename, and rc.startup
  restores only the newest generation per file.
- Fix: TDB backup/restore now stages files atomically (temp name + mv)
  instead of copying live, avoiding partial-write corruption on interrupt.
- Fix: Validate TDB integrity with `tdbtool check` before restoring; fall
  back to the next-older generation if the newest fails validation, and
  skip restoration for a database entirely if no generation validates.
- Fix: apply_settings() now echoes success/failure to stdout so errors
  (e.g. missing smbd PID file) are visible in the webGUI's progress frame
  instead of only being logged to syslog.
- Change: Use SHA256 instead of MD5 for package integrity verification.
- Fork: Rebranded plugin manifest (author, gitURL, supportURL) to point at
  the maintained fork instead of the removed upstream repository.
- Add: Live AD join status via `net ads testjoin`, replacing Unraid's
  built-in indicator (frequently inaccurate). Shows a color-coded
  status with expandable diagnostic detail on failure.
- Add: Confirmation dialog before Clear Cache, since clearing the cache
  restarts Samba and drops any active SMB connections.
- Change: Remove incomplete LDAP option from Backend Database dropdown.
- Add: Enable and validate Domain Backend Range / Backend Range fields
  (previously disabled placeholders). Validates format (low-high),
  low < high, and that the two ranges don't overlap - both client-side
  for immediate feedback and server-side in apply_settings() as the
  authoritative check.
- Fix: clear_winbind_cache() now surfaces success/failure to the GUI
  instead of completing silently either way. Verifies the actual outcome
  by checking whether smbd is running after restart, rather than trusting
  rc.samba's own exit code - confirmed via live testing that rc.samba
  restart returns 0 even when smbd fails to start entirely.
- Change: Set max supported Unraid version to 7.3.2 (confirmed working),
  preventing standard installation on untested future Unraid releases.
- Add: Configurable TDB backup destination (flash vs array/cache) via
  TDB_BACKUP_PATH. Validated in rc.shutdown/rc.startup/rc.cleanup with a
  safe fallback to the flash default if unset or invalid. Picker uses
  Unraid's standard folder-browse widget, matching the convention used
  elsewhere in the Unraid ecosystem (e.g. Unassigned Devices).
