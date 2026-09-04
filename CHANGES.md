# Changelog

## Unreleased
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
