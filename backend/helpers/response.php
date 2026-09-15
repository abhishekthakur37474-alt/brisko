<?php

declare(strict_types=1);

/**
 * Shared helpers: JSON responses, request parsing and a typed API exception.
 */

if (!class_exists('ApiException')) {
    class ApiException extends RuntimeException
    {
        public int $status;

        public function __construct(string $message, int $status = 400)
        {
            parent::__construct($message);
            $this->status = $status;
        }
    }
}

if (!function_exists('json_response')) {
    function json_response(array $payload, int $status = 200): void
    {
        if (!headers_sent()) {
            http_response_code($status);
            header('Content-Type: application/json; charset=utf-8');
        }
        echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
        exit;
    }
}

if (!function_exists('require_post')) {
    function require_post(): void
    {
        $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if ($method !== 'POST') {
            throw new ApiException('Invalid request method.', 405);
        }
    }
}

if (!function_exists('json_body')) {
    /** @return array<string, mixed> */
    function json_body(): array
    {
        $raw = file_get_contents('php://input');
        if (is_string($raw) && trim($raw) !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }
        if (!empty($_POST)) {
            return $_POST;
        }
        return [];
    }
}
