#!/bin/bash
# Shared helpers for the Active Directory Extras scripts (sourced, not run).

AD_CFG_KEYS="IDMAP_DOMAIN IDMAP_DOMAIN_BACKEND IDMAP_DOMAIN_RANGE IDMAP_BACKEND IDMAP_RANGE IDMAP_CACHE_TIME IDMAP_NEGATIVE_CACHE_TIME WINBIND_CACHE_TIME TDB_BACKUP_PATH"
AD_TDB_BACKUP_PATH_DEFAULT="/boot/config/plugins/active.directory/database"

# Reads the settings file WITHOUT executing it. Unraid's update.php writes KEY="value" with no escaping, so
# sourcing the file would run a value such as $(cmd) or "; cmd; " as root, every time the settings are applied
# and at every boot and shutdown. Only the known keys are read, and a value containing a quote, $, backtick,
# backslash or control character is ignored, so the script's own default applies.
load_cfg() {
	local file="$1" line key val
	[ -f "$file" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		line=${line%$'\r'}
		key=${line%%=*}
		[ "$key" = "$line" ] && continue
		case " $AD_CFG_KEYS " in *" $key "*) ;; *) continue ;; esac
		val=${line#*=}
		if [[ "$val" == \"*\" && ${#val} -ge 2 ]]; then val=${val:1:${#val}-2}; fi
		case "$val" in
			*[\"\$\`\\]* | *[[:cntrl:]]*) continue ;;
		esac
		printf -v "$key" '%s' "$val"
	done < "$file"
}

# 0 if the path looks like a backup location this plugin accepts: under /boot or /mnt, no "..".
tdb_path_valid() {
	local p="$1"
	[ -n "$p" ] || return 1
	[[ "$p" != *".."* ]] || return 1
	[[ "$p" =~ ^/(boot|mnt)/[A-Za-z0-9_./-]+$ ]] || return 1
	return 0
}

# "uid octalmode" of a path (GNU stat, or BSD stat for the tests).
_ad_stat() {
	stat -c '%u %a' "$1" 2>/dev/null || stat -f '%u %Lp' "$1" 2>/dev/null
}

# 0 if the folder is a real folder (not a link) owned by root that group and others cannot write to.
# The backups are read back as root at boot, so a folder anyone else could have written to (for example a
# folder inside an SMB share) could be used to plant a crafted idmap database.
tdb_dir_safe() {
	local d="$1" info uid mode
	[ -d "$d" ] && [ ! -L "$d" ] || return 1
	info=$(_ad_stat "$d") || return 1
	uid=${info%% *}
	mode=${info##* }
	[ "$uid" = "${AD_ROOT_UID:-0}" ] || return 1
	(( (8#$mode & 8#022) == 0 )) || return 1
	return 0
}

# 0 if the file is a regular file (not a link) owned by root.
tdb_file_ok() {
	local f="$1" info
	[ -f "$f" ] && [ ! -L "$f" ] || return 1
	info=$(_ad_stat "$f") || return 1
	[ "${info%% *}" = "${AD_ROOT_UID:-0}" ]
}

# Prints the folder to use for the backups: the configured one when it is valid and safe, otherwise the
# default on the flash drive (which is only accessible to root). $1 = configured path, $2 = "create" to make
# the configured folder (private to root) if it does not exist yet.
tdb_backup_dir() {
	local want="$1" mode="$2"
	if [ -z "$want" ]; then printf '%s\n' "$AD_TDB_BACKUP_PATH_DEFAULT"; return 0; fi
	if ! tdb_path_valid "$want"; then
		logger "active.directory: invalid TDB_BACKUP_PATH '$want', falling back to default." -t active.directory
		printf '%s\n' "$AD_TDB_BACKUP_PATH_DEFAULT"; return 0
	fi
	if [ ! -e "$want" ] && [ "$mode" = create ]; then
		(umask 077; mkdir -p "$want") 2>/dev/null
	fi
	if [ -e "$want" ] && ! tdb_dir_safe "$want"; then
		logger "active.directory: TDB_BACKUP_PATH '$want' is not a folder owned by root that only root can write to, falling back to default." -t active.directory
		printf '%s\n' "$AD_TDB_BACKUP_PATH_DEFAULT"; return 0
	fi
	printf '%s\n' "$want"
}
