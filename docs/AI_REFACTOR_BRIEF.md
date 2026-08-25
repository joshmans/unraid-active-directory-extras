# Engineering Brief: Refactor "Active Directory Extras" Unraid Plugin

Paste this whole document into Open WebUI as your system/first message,
then **attach the actual plugin files** listed in "Source files" below
(paste their contents inline if your model doesn't support attachments).
Model routing suggestions are at the bottom.

---

## 1. Project context

This is an Unraid 6.x/7.x plugin, GPLv2 licensed, originally written by
Dan Landon. It is being continued as a community fork because the upstream
GitHub repository was removed and the author has gone unresponsive to
maintenance questions. **Preserve all original copyright notices** and add
a new copyright line for fork changes — do not remove or replace the
original author's attribution anywhere.

The plugin is a settings page (under Unraid's Settings → SMB tab) for
tuning Samba/winbind Active Directory idmap behavior, and for persisting
winbind's `.tdb` databases across reboots, since Unraid's OS partition is
tmpfs/RAM-based and normally wipes them on every restart.

Stack: Bash (Unraid `rc.*` script conventions), PHP (Unraid's `.page`
templating system, using `_(...)_ ` for translatable strings and helper
functions like `mk_option()` that are provided by Unraid's webGUI
framework — don't try to redefine these), plain XML for the `.plg`
installer manifest.

## 2. Source files (attach/paste these)

```
active.directory/
├── ActiveDirectory.page          # Settings page: menu metadata + embedded PHP/HTML
├── README.md
├── LICENSE.md
├── default.cfg                   # Default settings values
├── icons/activedirectoryextras.png
├── event/
│   ├── started                   # Fired when Unraid array starts
│   └── stopping_svcs             # Fired when Unraid array stops
└── scripts/
    ├── rc.active.directory       # Core logic: apply settings, get current values
    ├── config_vfs                # PHP: adds acl_xattr to every SMB share's vfs objects
    ├── rc.startup                # Restore .tdb files from flash on boot
    ├── rc.shutdown                # Backup .tdb files to flash on shutdown
    └── rc.cleanup                 # Trim old .tdb backups, keep N most recent

active.directory.plg               # XML installer manifest (top level)
active.directory.cfg               # A live example of user settings (IDMAP_BACKEND etc.)
```

## 3. Constraints — do not violate these

- **No new network calls.** Everything must remain local-only (file I/O,
  local Samba tooling like `testparm`, `smbcontrol`, `net cache flush`).
  Do not add telemetry, update-phone-home, or remote fetches beyond the
  existing signed `.plg` download mechanism.
- **No secrets or credentials handling added.** This plugin does not (and
  should not) handle AD join credentials — that's Unraid core's job. Keep
  scope to idmap/samba tuning and TDB persistence.
- **Preserve config file compatibility.** Existing installs have a
  `/boot/config/plugins/active.directory/active.directory.cfg` with keys
  `IDMAP_DOMAIN_BACKEND`, `IDMAP_DOMAIN_RANGE`, `IDMAP_BACKEND`,
  `IDMAP_RANGE`, `IDMAP_CACHE_TIME`, `IDMAP_NEGATIVE_CACHE_TIME`,
  `WINBIND_CACHE_TIME`. Any new setting must be additive with a safe
  default if missing — don't break upgrades for existing users.
- **Follow Unraid plugin conventions.** `.page` files use Unraid's own
  templating (`_(...)_ `, `mk_option()`, `#file`/`#command`/`#arg[]` form
  fields posting to `/update.php`) — don't rewrite this into a generic PHP
  framework, just work within it.
- **Scripts must remain POSIX-Unraid-compatible bash** — the base image is
  Slackware-derived; don't assume GNU-only coreutils flags without
  checking they exist in Unraid's userspace.
- **`shellcheck` clean and `php -l` clean** on every file you touch.

## 4. Known bugs to fix

For each, implement the fix, and add a one-line comment explaining *why*
(not just what) at the point of the fix.

1. **`rc.cleanup`'s retention logic is global, not per-file.**
   Currently: `ls -1t "$TDB_BACKUP_DIR"/*.tdb` sorts ALL `.tdb` files
   together and keeps only the 5 newest overall. Since Samba writes
   several distinct `.tdb` files with different update frequencies, this
   can silently delete the only backup of a less-frequently-touched file.
   **Fix:** group backups by base filename (e.g. everything matching
   `group_mapping.tdb*`) and keep the N most recent generations *per
   basename*, not globally. Note: current files aren't timestamped/
   versioned in their names at all (just overwritten via `cp -u`) — you
   may need to redesign the backup naming scheme (e.g.
   `group_mapping.tdb.<timestamp>`) to make per-file retention meaningful
   at all. Flag this as a design decision in your response rather than
   silently assuming.

2. **No atomicity on backup or restore.** `rc.shutdown` copies live
   `.tdb` files while Samba may still be shutting down; `rc.startup`
   copies into place then restarts Samba, with no staging step. **Fix:**
   copy to a temp filename in the destination directory, then atomically
   `mv` into place. On restore, stop Samba (already done) → stage →
   validate (see #3) → move into place → start Samba.

3. **No corruption check on restore.** A truncated/corrupted `.tdb` (e.g.
   from a power loss mid-backup) gets blindly restored. **Fix:** before
   trusting a restored file, validate it with Samba's own `tdbdump` or
   `tdbtool check` (both ship with Samba, already present on Unraid). If
   validation fails, fall back to the next-most-recent generation for
   that file, log a warning via `logger`, and if none are valid, skip
   restoring that file entirely rather than crash-looping Samba.

4. **Silent failure on `apply_settings()`.** If the smbd PID file is
   missing, it logs to syslog but the GUI's "Apply" button appears to
   succeed. **Fix:** have the script return a distinguishable exit code /
   message, and have `ActiveDirectory.page`'s form submission surface a
   visible error state to the user (Unraid's `.page` update mechanism
   supports showing command output/errors in the progress frame — use
   that rather than inventing new UI).

## 5. Enhancements to implement

Implement these as separable, reviewable changes (don't combine into one
giant diff) so they can be tested/rolled back independently.

1. **LDAP idmap backend completeness.** The GUI currently offers `ldap`
   as a Backend Database choice with zero supporting fields — selecting
   it produces a broken config. Either:
   (a) add the missing fields (`ldap:ldap suffix`, `ldap:ldap base dn`,
   `ldap:ldap url` at minimum) with basic input validation, or
   (b) remove `ldap` from the dropdown until it's properly supported.
   Pick (b) as the default unless you have a way to test against a real
   LDAP backend — don't ship a half-working option.

2. **Enable the Domain Range / Backend Range fields.** They're currently
   `disabled` in the HTML despite having real backing config values.
   Wire them up with validation: must match `^\d+-\d+$`, low bound <
   high bound, and the Domain Range and default Range should not overlap
   (warn, don't silently allow, if they do).

3. **Add live AD join status.** Add a read-only section showing output
   from `wbinfo -t` (trust secret test) and/or `net ads testjoin`,
   refreshed on page load, so this page is useful as a lightweight
   diagnostic, not just a blind settings form.

4. **Confirm before Clear Cache.** `clear_cache` restarts Samba, dropping
   active SMB connections. Add a JS confirm dialog before the form
   submits.

5. **SHA256 over MD5 in the `.plg`.** Not a code change to the plugin
   payload itself, but update the packaging step / build notes to compute
   and embed a `<SHA256>` entity instead of `<MD5>`.

6. **Configurable backup destination.** Currently hardcoded to
   `/boot/config/plugins/active.directory/database` (the flash drive).
   Add a config option to instead write to a path on the array/cache pool,
   for users who reboot often and are USB-write-endurance-conscious.
   Default should remain the flash drive for backward compatibility.

## 6. Deliverable format

For each file you modify, respond with:
1. The filename
2. A short rationale (2–4 sentences) tied back to the specific bug/
   enhancement number above
3. The full updated file contents (not a diff, unless explicitly asked) —
   full files are easier to drop straight back into the repo
4. A one-line changelog entry formatted for the `.plg`'s `<CHANGES>` block,
   e.g. `- Fix: Per-file TDB backup retention instead of global retention.`

Do not modify files you weren't asked to touch. Do not invent new files
unless a fix genuinely requires one (e.g. a new validation helper) — state
why if you do.

## 7. Model routing suggestions (for your Open WebUI setup)

- **qwen3-coder or deepseek-coder** — best for sections 4 and 5 (the
  actual bash/PHP code changes). Feed them this brief plus the specific
  file(s) relevant to one bug/enhancement at a time rather than the whole
  tree at once — smaller, scoped diffs are easier to verify by hand
  against the constraints in section 3.
- **gpt-oss** — good for turning the output of the above into the
  `CHANGES.md`/`.plg` changelog entries, drafting the PR description, and
  doing a second-pass review of whether a proposed change actually
  respects section 3's constraints (it's a decent "did the coder model
  quietly violate a constraint" check).
- Regardless of model, **run `shellcheck` and `php -l` yourself** on
  whatever comes back before merging — don't trust model output as
  lint-clean by default.
