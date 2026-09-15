<?php

declare(strict_types=1);

$uri = urldecode(parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/');
$file = __DIR__ . $uri;
if ($uri !== '/' && is_file($file)) {
    return false;
}
if ($uri === '/' || $uri === '') {
    require __DIR__ . '/login.php';
    return true;
}
http_response_code(404);
echo 'Not found';
