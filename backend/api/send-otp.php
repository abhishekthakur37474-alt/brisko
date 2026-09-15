<?php

declare(strict_types=1);

require_once __DIR__ . '/../helpers/bootstrap.php';
require_once __DIR__ . '/../helpers/validation.php';
require_once __DIR__ . '/../helpers/send_otp_flow.php';

require_post();

$body = json_body();
$mobile = normalize_mobile((string) ($body['mobile'] ?? ''));
if ($mobile === null) {
    throw new ApiException('Enter a valid 10-digit mobile number.', 400);
}

$result = otp_generate_and_send($mobile, brisko_config(), false);

json_response([
    'success' => true,
    'message' => 'OTP sent successfully',
    'requestId' => $result['request_id'],
]);
