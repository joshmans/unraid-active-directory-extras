<?php
/* The password-safe join/leave endpoint's library, against a fake `net`. Needs only php-cli. */
require __DIR__ . '/../active.directory/include/join_leave_lib.php';

$pass = 0; $fail = 0;
function check(string $label, bool $ok, string $detail = ''): void {
	global $pass, $fail;
	if ($ok) { $pass++; return; }
	$fail++; echo "FAIL: $label" . ($detail !== '' ? "\n      $detail" : '') . "\n";
}

$d = sys_get_temp_dir() . '/ad-test-' . getmypid();
mkdir($d);
$fakeNet = "$d/net";
file_put_contents($fakeNet, <<<'SH'
#!/bin/bash
echo "$*" >> "$FAKE_DIR/argv"
if [ "$1" = ads ] && { [ "$2" = join ] || [ "$2" = leave ]; }; then
  read -r pw
  printf '%s' "$pw" > "$FAKE_DIR/stdin"
  case "$pw" in
    goodpass*) echo "Success from fake net"; exit 0 ;;
    slow) sleep 5; exit 0 ;;
    *) echo "NT_STATUS_LOGON_FAILURE for $pw"; exit 1 ;;
  esac
fi
exit 0
SH);
chmod($fakeNet, 0755);
file_put_contents("$d/smbcontrol", "#!/bin/bash\necho \"\$*\" >> \"\$FAKE_DIR/smbcontrol.log\"\n"); chmod("$d/smbcontrol", 0755);
file_put_contents("$d/smbd.pid", "4242\n");
putenv("FAKE_DIR=$d"); putenv("AD_NET_BIN=$fakeNet"); putenv("AD_SMBCONTROL_BIN=$d/smbcontrol"); putenv("AD_SMBD_PID=$d/smbd.pid");

$r = ad_join_leave('join', 'Administrator', 'goodpass');
check('join succeeds', $r['ok'] === true && strpos($r['message'], 'Successfully joined') === 0, json_encode($r));
$argv = file_get_contents("$d/argv");
check('the password is never in a command-line argument', strpos($argv, 'goodpass') === false, $argv);
check('the password reached net on stdin', file_get_contents("$d/stdin") === 'goodpass');
check('net was called without a shell-built line: ads join -U login', strpos($argv, 'ads join -U Administrator') === 0, $argv);
check('the cache is flushed and Samba told to reload after a join', strpos($argv, 'cache flush') !== false && trim((string)@file_get_contents("$d/smbcontrol.log")) === '4242 reload-config');

@unlink("$d/argv"); @unlink("$d/smbcontrol.log");
$r = ad_join_leave('leave', 'admin', 'goodpass-2');
check('leave succeeds and says so', $r['ok'] === true && strpos($r['message'], 'Successfully left') === 0 && strpos(file_get_contents("$d/argv"), 'ads leave -U admin') === 0, json_encode($r));

@unlink("$d/argv"); @unlink("$d/smbcontrol.log");
$r = ad_join_leave('join', 'admin', 'wrong-Password1');
check('a failure reports net\'s message', $r['ok'] === false && strpos($r['message'], 'NT_STATUS_LOGON_FAILURE') !== false, json_encode($r));
check('the password is redacted if net echoes it back', strpos($r['message'], 'wrong-Password1') === false && strpos($r['message'], '***') !== false, $r['message']);
check('nothing is reloaded after a failure', !is_file("$d/smbcontrol.log"));

foreach ([['', 'x'], ['a', ''], ['-U', 'x'], ["a\nb", 'x'], ['a%b', 'x'], [str_repeat('a', 300), 'x']] as [$l, $p]) {
	@unlink("$d/argv");
	$r = ad_join_leave('join', $l, $p);
	check('rejects login ' . json_encode(substr($l, 0, 12)) . ' / password ' . json_encode($p), $r['ok'] === false && !is_file("$d/argv"), json_encode($r));
}
$r = ad_join_leave('join', 'admin', "pw\nsecond");
check('a password with a line break is refused instead of being cut short', $r['ok'] === false && !is_file("$d/argv"));
check('an unknown action is refused', ad_join_leave('delete', 'a', 'b')['ok'] === false);
check('a login with spaces and unicode is passed as one argument', (function () use ($d) {
	@unlink("$d/argv"); ad_join_leave('join', 'José Nuñez', 'goodpass'); return strpos(file_get_contents("$d/argv"), 'ads join -U José Nuñez') === 0;
})());

putenv('AD_NET_TIMEOUT=1');
$t0 = microtime(true);
$r = ad_join_leave('join', 'admin', 'slow');
check('a net that does not answer is stopped', $r['ok'] === false && strpos($r['message'], 'did not answer') !== false && microtime(true) - $t0 < 4, json_encode($r) . ' ' . round(microtime(true) - $t0, 1) . 's');

putenv('AD_NET_BIN=' . "$d/does-not-exist");
$r = ad_join_leave('join', 'admin', 'goodpass');
check('a missing net binary fails cleanly', $r['ok'] === false, json_encode($r));

foreach (glob("$d/*") as $f) unlink($f);
rmdir($d);
echo "join_leave_test: $pass passed, $fail failed\n";
exit($fail ? 1 : 0);
