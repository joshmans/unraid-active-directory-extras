#!/bin/bash
# ./build.sh [version]   builds packages/active.directory-<version>.txz and stamps
# active.directory.plg with the version, SHA-256 and CHANGELOG.md
set -e
NAME=active.directory
VERSION="${1:-$(date +%Y.%m.%d)}"
cd "$(dirname "$0")"

rm -rf package-temp packages
mkdir -p package-temp packages
cp -R "$NAME" package-temp/
find package-temp -name .DS_Store -delete
find package-temp -type d -exec chmod 755 {} \;
find package-temp -type f -exec chmod 644 {} \;
# the plugin's own scripts and event handlers run as programs
chmod 755 "package-temp/$NAME/scripts/"* "package-temp/$NAME/event/"*

# the archive must extract as root:root whoever builds it; bsdtar (macOS) and GNU tar
# spell that differently, and COPYFILE_DISABLE keeps macOS from adding ._ files
if tar --version 2>/dev/null | grep -qi bsdtar; then
    OWNER=(--uid 0 --gid 0 --uname root --gname root)
else
    OWNER=(--owner=root --group=root --numeric-owner)
fi
COPYFILE_DISABLE=1 tar "${OWNER[@]}" -C package-temp -cJf "packages/$NAME-$VERSION.txz" "$NAME"
rm -rf package-temp

if command -v sha256sum >/dev/null; then SHA256=$(sha256sum "packages/$NAME-$VERSION.txz" | cut -d' ' -f1); else SHA256=$(shasum -a 256 "packages/$NAME-$VERSION.txz" | cut -d' ' -f1); fi

# the plg ships the changelog; "]]>" is the one string that would end the CDATA early
python3 - "$VERSION" "$SHA256" <<'PY'
import re, sys
version, sha256 = sys.argv[1:3]
s = open('active.directory.plg').read()
log = open('CHANGELOG.md').read().replace(']]>', ']]]]><![CDATA[>')
# this plg keeps tabs between an entity's name and its value, and calls the hash SHA256
s = re.sub(r'(<!ENTITY version\s+)"[^"]*">', lambda m: f'{m.group(1)}"{version}">', s)
s = re.sub(r'(<!ENTITY SHA256\s+)"[^"]*">', lambda m: f'{m.group(1)}"{sha256}">', s)
s = re.sub(r'(<CHANGES><!\[CDATA\[\n).*?(\n\]\]></CHANGES>)', lambda m: m.group(1) + log.strip() + m.group(2), s, flags=re.S)
open('active.directory.plg', 'w').write(s)
PY
python3 -c "import xml.etree.ElementTree as E; E.parse('active.directory.plg')"
echo "built packages/$NAME-$VERSION.txz (sha256 $SHA256)"
