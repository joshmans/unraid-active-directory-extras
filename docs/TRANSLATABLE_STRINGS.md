# Translatable Strings Inventory

Every `_(...)_ `-tagged string currently in `ActiveDirectory.page`, for
reference and as groundwork for future localization work.

## What this is, and isn't

Unraid's `_(...)_ ` tags fall back to displaying the raw English text when
no translation file backs them — which is the current, fully functional
state of this plugin. Nothing is broken for English users. This document
exists purely as groundwork: a clean inventory of what would need
translating if non-English support ever becomes worth pursuing.

**This is not a translation file, and neither of us is attempting to
actually translate these strings into other languages here** — doing that
credibly requires bilingual review we can't provide, and machine
translation of Samba/AD terminology risks being confidently wrong in ways
a non-English reader couldn't easily catch.

## If this is ever pursued for real

The established path, per dlandon's own other plugins, is contributing
strings to the community-maintained `unraid/lang-en_US` repository, which
is a separate external project with its own contribution conventions —
worth investigating properly at that time rather than guessing at its
process now. This inventory is the starting point for that, not a
replacement for it.

## Original strings (dlandon's base plugin, unchanged by this fork)

| String |
|---|
| Domain Backend Database |
| Domain Backend Range |
| Backend Database |
| Backend Range |
| Idmap Cache Time |
| Idmap Negative Cache Time |
| Winbind Cache Time |
| When you change a backend database, you will lose your permission settings and you'll have to re-enter them |
| AD permissions are persistent after a reboot |
| Default |
| Apply |
| Done |
| Click on 'Help' for more information |
| Current AD Settings |
| Clear Cache |
| Clear winbind cache and restart Samba |

## Added during this fork's development

| String | Introduced by |
|---|---|
| AD join status | Enhancement #3 (live AD join status) |
| Joined | Enhancement #3 |
| Not joined | Enhancement #3 |
| show details | Enhancement #3 (collapsible error detail) |
| hide details | Enhancement #3 |
| Domain Backend Range must be in the format low-high, e.g. 100000-199999, with low less than high. | Enhancement #2 (range validation) |
| Backend Range must be in the format low-high, e.g. 10000-99999, with low less than high. | Enhancement #2 |
| Domain Backend Range and Backend Range must not overlap. | Enhancement #2 |
| Clearing the cache will restart Samba and drop any active SMB connections. Continue? | Enhancement #4 (Clear Cache confirm) |
| TDB Backup Path | Enhancement #6 (configurable backup path) |

## Maintenance note

Regenerate this list after future changes with:

```bash
grep -oP '_\([^)]+\)_' active.directory/ActiveDirectory.page | sort -u
```

Re-categorize any new entries into the table above so this stays a useful
running record rather than going stale.
