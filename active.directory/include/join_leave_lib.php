<?php
/* Join or leave the domain with the login and password the user typed.
 *
 * The password goes to `net` on its standard input. It is never a command-line argument and it never goes
 * through Unraid's /update.php, which writes every argument of the command it runs to the syslog (and syslog
 * ends up in diagnostics that people post on forums). It is not written to disk or logged here either.
 */

const AD_NET = '/usr/bin/net';
const AD_SMBCONTROL = '/usr/bin/smbcontrol';
const AD_SMBD_PID = '/var/run/smbd.pid';
const AD_NET_TIMEOUT = 90;

/** Path of a helper program; the test replaces them through environment variables (command line only). */
function ad_bin(string $default, string $env): string {
	if (PHP_SAPI === 'cli' && ($v = getenv($env)) !== false && $v !== '') return $v;
	return $default;
}

function ad_net_timeout(): int {
	if (PHP_SAPI === 'cli' && ($v = getenv('AD_NET_TIMEOUT')) !== false && ctype_digit($v) && (int)$v > 0) return (int)$v;
	return AD_NET_TIMEOUT;
}

/** null when the login is acceptable, otherwise the reason. */
function ad_check_login(string $login): ?string {
	if ($login === '') return 'Login and password are required.';
	if (strlen($login) > 256) return 'The login is too long.';
	if (preg_match('/[\x00-\x1f\x7f%]/', $login)) return 'The login contains a character that is not allowed.';
	if ($login[0] === '-') return 'The login may not start with "-".';
	return null;
}

/** null when the password is acceptable, otherwise the reason. */
function ad_check_password(string $password): ?string {
	if ($password === '') return 'Login and password are required.';
	if (strlen($password) > 512) return 'The password is too long.';
	if (preg_match('/[\x00\r\n]/', $password)) return 'The password contains a character that cannot be sent.';
	return null;
}

/**
 * Runs a program without a shell. $stdin, if given, is written to it. Returns [exit code, output (stdout and stderr)];
 * exit code -1 means it could not be started, 124 that it was stopped after $timeout seconds.
 */
function ad_run(array $argv, ?string $stdin = null, int $timeout = 30): array {
	$p = @proc_open($argv, [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['redirect', 1]], $pipes);
	if (!is_resource($p)) return [-1, ''];
	if ($stdin !== null) fwrite($pipes[0], $stdin);
	fclose($pipes[0]);
	stream_set_blocking($pipes[1], false);
	$out = ''; $deadline = time() + $timeout; $timedOut = false;
	while (true) {
		$st = proc_get_status($p);
		$chunk = fread($pipes[1], 8192);
		if ($chunk !== false && $chunk !== '') $out .= $chunk;
		if (!$st['running']) break;
		if (time() >= $deadline) { proc_terminate($p, 9); $timedOut = true; break; }
		if ($chunk === '' || $chunk === false) usleep(50000);
	}
	$rest = stream_get_contents($pipes[1]);
	if ($rest !== false) $out .= $rest;
	fclose($pipes[1]);
	$rc = proc_close($p);
	if (!empty($st) && isset($st['exitcode']) && $st['exitcode'] >= 0 && !$st['running']) $rc = $st['exitcode'];
	return [$timedOut ? 124 : $rc, $out];
}

/** @return array{ok: bool, message: string} */
function ad_join_leave(string $action, string $login, string $password): array {
	if (!in_array($action, ['join', 'leave'], true)) return ['ok' => false, 'message' => 'Unknown action.'];
	$err = ad_check_login($login) ?? ad_check_password($password);
	if ($err !== null) return ['ok' => false, 'message' => 'Error: ' . $err];

	$net = ad_bin(AD_NET, 'AD_NET_BIN');
	[$rc, $out] = ad_run([$net, 'ads', $action, '-U', $login], $password . "\n", ad_net_timeout());
	$out = trim(str_replace($password, '***', $out));
	$word = $action === 'join' ? 'join' : 'leave';
	if ($rc === 124) return ['ok' => false, 'message' => "Error: Failed to $word the domain. It did not answer within " . ad_net_timeout() . ' seconds.'];
	if ($rc !== 0) {
		// The detail goes to this one browser response only, never to the syslog.
		@exec('logger -t active.directory ' . escapeshellarg("Error: net ads $word failed (see the page for detail)."));
		return ['ok' => false, 'message' => "Error: Failed to $word the domain." . ($out !== '' ? ' ' . $out : '')];
	}
	ad_run([$net, 'cache', 'flush']);
	$pid = trim((string)@file_get_contents(ad_bin(AD_SMBD_PID, 'AD_SMBD_PID')));
	if ($pid !== '' && ctype_digit($pid)) ad_run([ad_bin(AD_SMBCONTROL, 'AD_SMBCONTROL_BIN'), $pid, 'reload-config']);
	$done = $action === 'join' ? 'joined' : 'left';
	return ['ok' => true, 'message' => "Successfully $done the domain. Array and Samba were not restarted."];
}
