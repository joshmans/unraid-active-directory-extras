#!/bin/bash
# Tests for active.directory/scripts/common.sh (safe settings loader, backup-folder checks) and a syntax check
# of every script. Needs only bash.
cd "$(dirname "$0")/.." || exit 1
pass=0; fail=0
check() { if [ "$2" = ok ]; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1${3:+ ($3)}"; fi; }
yes_() { [ "$1" = "$2" ] && echo ok || echo no; }

# shellcheck source=../active.directory/scripts/common.sh
source active.directory/scripts/common.sh
T=$(mktemp -d)
export AD_ROOT_UID; AD_ROOT_UID=$(id -u)   # the test is not root: treat the current user as "root"

for s in active.directory/scripts/rc.* active.directory/scripts/common.sh active.directory/event/*; do
  bash -n "$s" 2>/dev/null; check "syntax: $s" "$(yes_ $? 0)"
done
for s in active.directory/scripts/config_vfs active.directory/include/*.php; do
  php -l "$s" >/dev/null 2>&1; check "php -l: $s" "$(yes_ $? 0)"
done

## load_cfg
cat > "$T/good.cfg" <<'CFG'
IDMAP_DOMAIN="MYDOMAIN"
IDMAP_DOMAIN_BACKEND="rid"
IDMAP_RANGE="10000-99999"
IDMAP_CACHE_TIME=43200
WINBIND_CACHE_TIME="300"
TDB_BACKUP_PATH="/mnt/user/appdata/active.directory/database"
UNKNOWN_KEY="ignored"
CFG
( unset IDMAP_DOMAIN IDMAP_DOMAIN_BACKEND IDMAP_RANGE IDMAP_CACHE_TIME WINBIND_CACHE_TIME UNKNOWN_KEY
  load_cfg "$T/good.cfg"
  [ "$IDMAP_DOMAIN" = MYDOMAIN ] && [ "$IDMAP_DOMAIN_BACKEND" = rid ] && [ "$IDMAP_RANGE" = 10000-99999 ] && [ "$IDMAP_CACHE_TIME" = 43200 ] && [ "$WINBIND_CACHE_TIME" = 300 ] && [ "$TDB_BACKUP_PATH" = /mnt/user/appdata/active.directory/database ] && [ -z "$UNKNOWN_KEY" ] ) 2>/dev/null
check "load_cfg reads quoted and unquoted values and ignores unknown keys" "$(yes_ $? 0)"

printf 'IDMAP_DOMAIN="A"\r\nIDMAP_RANGE="1-2"\r\n' > "$T/crlf.cfg"
( load_cfg "$T/crlf.cfg"; [ "$IDMAP_DOMAIN" = A ] && [ "$IDMAP_RANGE" = 1-2 ] )
check "load_cfg copes with CRLF line ends" "$(yes_ $? 0)"

printf 'IDMAP_DOMAIN="a"\nIDMAP_DOMAIN="b"\n' > "$T/dup.cfg"
( load_cfg "$T/dup.cfg"; [ "$IDMAP_DOMAIN" = b ] ); check "load_cfg: the last assignment wins, like source" "$(yes_ $? 0)"

load_cfg "$T/missing.cfg"; check "load_cfg: a missing file is fine" "$(yes_ $? 0)"

# injection attempts: none of these may run, and the unsafe values must be dropped
: > "$T/pwned"
rm -f "$T/pwned"
cat > "$T/evil.cfg" <<CFG
IDMAP_DOMAIN="\$(touch $T/pwned1)"
IDMAP_DOMAIN_BACKEND="\`touch $T/pwned2\`"
IDMAP_BACKEND="tdb"; touch $T/pwned3; "
IDMAP_RANGE="1-2\"
touch $T/pwned4
"
IDMAP_CACHE_TIME="12\\34"
TDB_BACKUP_PATH="/mnt/x"
CFG
( unset IDMAP_DOMAIN IDMAP_DOMAIN_BACKEND IDMAP_BACKEND IDMAP_RANGE IDMAP_CACHE_TIME TDB_BACKUP_PATH
  load_cfg "$T/evil.cfg"
  [ -z "$IDMAP_DOMAIN" ] && [ -z "$IDMAP_DOMAIN_BACKEND" ] && [ -z "$IDMAP_BACKEND" ] && [ -z "$IDMAP_RANGE" ] && [ -z "$IDMAP_CACHE_TIME" ] && [ "$TDB_BACKUP_PATH" = /mnt/x ] )
check "load_cfg drops values with \$(), backticks, quotes, backslashes and line breaks" "$(yes_ $? 0)"
ls "$T"/pwned* >/dev/null 2>&1; [ $? -ne 0 ]; check "load_cfg never runs anything from the file" "$(yes_ $? 0)"

## tdb_path_valid
for p in /boot/config/plugins/active.directory/database /mnt/user/appdata/ad /mnt/disk1/x; do tdb_path_valid "$p"; check "path ok: $p" "$(yes_ $? 0)"; done
for p in "" /etc/x /boot /mnt/ /mnt/user/../../etc /mnt/a\ b '/mnt/a;b' '/mnt/$x' relative/path; do tdb_path_valid "$p"; check "path rejected: '$p'" "$(yes_ $? 1)"; done

## tdb_dir_safe / tdb_file_ok
mkdir "$T/d700" "$T/d755" "$T/d775" "$T/d777" "$T/d757"
chmod 700 "$T/d700"; chmod 755 "$T/d755"; chmod 775 "$T/d775"; chmod 777 "$T/d777"; chmod 757 "$T/d757"
tdb_dir_safe "$T/d700"; check "dir mode 700 is safe" "$(yes_ $? 0)"
tdb_dir_safe "$T/d755"; check "dir mode 755 is safe" "$(yes_ $? 0)"
tdb_dir_safe "$T/d775"; check "dir writable by the group is not safe" "$(yes_ $? 1)"
tdb_dir_safe "$T/d777"; check "dir writable by everyone is not safe" "$(yes_ $? 1)"
tdb_dir_safe "$T/d757"; check "dir writable by others is not safe" "$(yes_ $? 1)"
ln -s "$T/d700" "$T/link"; tdb_dir_safe "$T/link"; check "a symlink to a safe dir is not accepted" "$(yes_ $? 1)"
tdb_dir_safe "$T/nothing"; check "a missing dir is not safe" "$(yes_ $? 1)"
if [ "$(id -u)" != 0 ]; then AD_ROOT_UID=0 tdb_dir_safe "$T/d700"; check "a dir not owned by root is not safe" "$(yes_ $? 1)"; fi
touch "$T/d700/a.tdb.20260101-000000"; ln -s "$T/d700/a.tdb.20260101-000000" "$T/d700/b.tdb.1-1"
tdb_file_ok "$T/d700/a.tdb.20260101-000000"; check "a regular file is accepted" "$(yes_ $? 0)"
tdb_file_ok "$T/d700/b.tdb.1-1"; check "a symlink is not accepted as a backup file" "$(yes_ $? 1)"
tdb_file_ok "$T/d700"; check "a directory is not a backup file" "$(yes_ $? 1)"
if [ "$(id -u)" != 0 ]; then AD_ROOT_UID=0 tdb_file_ok "$T/d700/a.tdb.20260101-000000"; check "a file not owned by root is not accepted" "$(yes_ $? 1)"; fi

## tdb_backup_dir
[ "$(tdb_backup_dir "" 2>/dev/null)" = "$AD_TDB_BACKUP_PATH_DEFAULT" ]; check "empty setting: the default (flash) folder" "$(yes_ $? 0)"
[ "$(tdb_backup_dir "/etc/evil" 2>/dev/null)" = "$AD_TDB_BACKUP_PATH_DEFAULT" ]; check "an invalid path falls back to the default" "$(yes_ $? 0)"
[ "$(tdb_backup_dir "/mnt/user/appdata/not-created-yet" 2>/dev/null)" = "/mnt/user/appdata/not-created-yet" ]; check "a valid path that does not exist yet is kept (the caller creates it)" "$(yes_ $? 0)"

rm -rf "$T"
echo "common_test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
