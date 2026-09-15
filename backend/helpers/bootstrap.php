<?php

declare(strict_types=1);

/**
 * Common bootstrap for every API entry point:
 *  - loads composer autoloader (Firebase SDK etc.)
 *  - loads config + response helpers
 *  - configures error reporting/logging (never leak details in production)
 *  - emits JSON for any uncaught exception
 *  - applies CORS only for explicitly allowed origins
 */

require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/../config/config.php';
require_once __DIR__ . '/response.php';

$config = brisko_config();

error_reporting(E_ALL);
ini_set('display_errors', $config['debug'] ? '1' : '0');
ini_set('log_errors', '1');

$logFile = $config['storage']['log'];
$logDir = dirname($logFile);
if (!is_dir($logDir)) {
    @mkdir($logDir, 0770, true);
}
ini_set('error_log', $logFile);

header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

// CORS is only needed if a browser frontend consumes this API. Native Flutter
// HTTP calls are unaffected. Never use a wildcard for authenticated endpoints.
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
if ($origin !== '' && in_array($origin, $config['cors']['allowed_origins'], true)) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Access-Control-Allow-Headers: Content-Type, Accept, Authorization');
    header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
    header('Vary: Origin');
}

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

set_exception_handler(static function (Throwable $e): void {
    if ($e instanceof ApiException) {
        json_response(['success' => false, 'message' => $e->getMessage()], $e->status);
    }
    error_log('[brisko] unhandled: ' . $e->getMessage() . ' @ ' . $e->getFile() . ':' . $e->getLine());
    json_response(['success' => false, 'message' => 'Something went wrong. Please try again.'], 500);
});