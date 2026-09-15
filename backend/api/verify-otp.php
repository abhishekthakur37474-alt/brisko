<?php

declare(strict_types=1);

require_once __DIR__ . '/../helpers/bootstrap.php';
require_once __DIR__ . '/../helpers/validation.php';
require_once __DIR__ . '/../helpers/otp_store.php';
require_once __DIR__ . '/../helpers/FirebaseAuthClient.php';

require_post();

$body = json_body();
$mobile = normalize_mobile((string) ($body['mobile'] ?? ''));
$otp = normalize_otp((string) ($body['otp'] ?? ''));

if ($mobile === null) {
    throw new ApiException('Enter a valid 10-digit mobile number.', 400);
}
if ($otp === null) {
    throw new ApiException('Enter a valid OTP.', 400);
}

$config = brisko_config();
$maxAttempts = (int) $config['otp']['max_attempts'];

$record = otp_read($mobile);
if ($record === null) {
    throw new ApiException('This OTP has expired. Please request a new OTP.', 400);
}
if (!empty($record['verified'])) {
    otp_delete($mobile);
    throw new ApiException('This OTP has already been used. Please request a new OTP.', 400);
}
if (time() > (int) $record['expires_at']) {
    otp_delete($mobile);
    throw new ApiException('This OTP has expired. Please request a new OTP.', 400);
}
if ((int) $record['attempt_count'] >= $maxAttempts) {
    otp_delete($mobile);
    throw new ApiException('Too many attempts. Please request a new OTP later.', 429);
}

if (!password_verify($otp, (string) $record['otp_hash'])) {
    $record['attempt_count'] = (int) $record['attempt_count'] + 1;
    if ($record['attempt_count'] >= $maxAttempts) {
        otp_delete($mobile);
        throw new ApiException('Too many attempts. Please request a new OTP later.', 429);
    }
    otp_write($mobile, $record);
    throw new ApiException('Incorrect OTP. Please try again.', 400);
}

// Success: OTPs are single-use, so consume it immediately.
$record['verified'] = true;
otp_write($mobile, $record);
otp_delete($mobile);

$fb = new FirebaseAuthClient($config['firebase']);
$user = $fb->findOrCreateUserByPhone($mobile);
$fb->ensureUserRecord($user['uid'], $mobile, $user['isNewUser']);
$customToken = $fb->createCustomToken($user['uid']);

error_log(sprintf(
    '[brisko] otp verified mobile=%s new_user=%s',
    mask_mobile($mobile),
    $user['isNewUser'] ? '1' : '0'
));

json_response([
    'success' => true,
    'message' => 'OTP verified successfully',
    'customToken' => $customToken,
    'isNewUser' => $user['isNewUser'],
    'uid' => $user['uid'],
    'phone' => $mobile,
]);
