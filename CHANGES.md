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