<?php

declare(strict_types=1);

require_once __DIR__ . '/auth_middleware.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'POST required']);
    exit;
}

try {
    if (empty($_FILES['image']['tmp_name'])) {
        throw new RuntimeException('Choose an image file.');
    }
    $client = new ImgbbClient((string) (brisko_config()['imgbb_api_key'] ?? ''));
    if (!$client->enabled()) {
        throw new RuntimeException('ImgBB API key is not set in config.php.');
    }
    $url = $client->upload((string) $_FILES['image']['tmp_name'], (string) ($_FILES['image']['name'] ?? 'image.jpg'));
    echo json_encode(['ok' => true, 'url' => $url]);
} catch (Throwable $e) {
    http_response_code(400);
    echo json_encode(['ok' => false, 'error' => $e->getMessage()]);
}
