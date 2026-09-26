<?php
/* POST-only endpoint for the Rejoin / Leave Domain buttons. Unraid's own request filter checks the CSRF token of
 * every POST before this runs. The password is read from the request body and handed to `net` on stdin: see
 * join_leave_lib.php for why it does not go through /update.php. */
require_once __DIR__ . '/join_leave_lib.php';

header('Content-Type: application/json');
header('Cache-Control: no-store');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
	http_response_code(405);
	echo json_encode(['ok' => false, 'message' => 'POST only.']);
	exit;
}

$s = fn($k) => isset($_POST[$k]) && is_string($_POST[$k]) ? $_POST[$k] : '';
$result = ad_join_leave($s('action'), $s('login'), $s('password'));
unset($_POST['password']);
echo json_encode($result);
