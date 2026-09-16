<?php

declare(strict_types=1);

/**
 * POST /api/upload-payment-proof.php
 *
 * Uploads the payment screenshot attached to a manual UPI/QR checkout and
 * returns the hosted image URL. The caller must be a signed-in Firebase user
 * (Bearer ID token); the UID comes from the verified token, never the body.
 *
 * The Flutter app then stores the returned URL on the order (`paymentProofUrl`)
 * so the admin can review it before approving or rejecting the payment.
 */

require_once __DIR__ . '/../helpers/bootstrap.php';
require_once __DIR__ . '/../services/firebase_service.php';
require_once __DIR__ . '/../services/imgbb_uploader.php';
require_once __DIR__ . '/../helpers/auth_guard.php';

require_post();

$uid = require_firebase_uid();

$file = $_FILES['image'] ?? null;
if (!is_array($file) || empty($file['tmp_name'])) {
    throw new ApiException('Choose a payment screenshot to upload.');
}
if ((int) ($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    throw new ApiException('Image upload failed. Please try again.');
}

$maxBytes = 5 * 1024 * 1024;
if ((int) ($file['size'] ?? 0) > $maxBytes) {
    throw new ApiException('Screenshot is too large. Please use an image under 5 MB.');
}

$allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif'];
$mime = mime_content_type((string) $file['tmp_name']) ?: '';
if ($mime !== '' && !in_array($mime, $allowed, true)) {
    throw new ApiException('Please upload a JPG, PNG or WEBP image.');
}

$uploader = new ImgbbUploader(brisko_config()['imgbb']);
$url = $uploader->upload((string) $file['tmp_name'], (string) ($file['name'] ?? 'payment-proof.jpg'));

json_response([
    'success' => true,
    'url' => $url,
    'uid' => $uid,
]);
