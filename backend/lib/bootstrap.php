<?php

declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, Accept');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'Method not allowed']);
    exit;
}

require_once __DIR__ . '/RtdbClient.php';
require_once __DIR__ . '/FirebaseAuthClient.php';
require_once __DIR__ . '/Fast2SmsClient.php';
require_once __DIR__ . '/Phone.php';

function brisko_config(): array
{
    static $config;
    if ($config === null) {
        $config = require dirname(__DIR__) . '/config/config.php';
    }
    return $config;
}

function brisko_json_body(): array
{
    $raw = file_get_contents('php://input') ?: '';
    $data = json_decode($raw, true);
    if (is_array($data)) {
        return $data;
    }
    if (!empty($_POST)) {
        return $_POST;
    }
    return [];
}

function brisko_respond(int $code, array $payload): never
{
    http_response_code($code);
    echo json_encode($payload);
    exit;
}

function brisko_rtdb(): RtdbClient
{
    return new RtdbClient(brisko_config());
}
