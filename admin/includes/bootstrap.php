<?php

declare(strict_types=1);

if (session_status() !== PHP_SESSION_ACTIVE) {
    $cfgEarly = require dirname(__DIR__) . '/config/config.php';
    session_name((string) ($cfgEarly['session_name'] ?? 'brisko_admin'));
    session_start();
}

require_once dirname(__DIR__) . '/lib/RtdbClient.php';
require_once dirname(__DIR__) . '/lib/AdminAuth.php';
require_once dirname(__DIR__) . '/lib/FcmClient.php';
require_once dirname(__DIR__) . '/lib/ImgbbClient.php';
require_once dirname(__DIR__) . '/lib/PdfInvoice.php';
require_once dirname(__DIR__) . '/lib/OrderActions.php';

function brisko_config(): array
{
    static $config;
    if ($config === null) {
        $config = require dirname(__DIR__) . '/config/config.php';
    }
    return $config;
}

function brisko_rtdb(): RtdbClient
{
    static $client;
    if ($client === null) {
        $client = new RtdbClient(brisko_config());
    }
    return $client;
}

function brisko_auth(): AdminAuth
{
    static $auth;
    if ($auth === null) {
        $auth = new AdminAuth(brisko_rtdb());
    }
    return $auth;
}

/**
 * True when at least one admin account exists in RTDB.
 */
function brisko_has_admin(): bool
{
    try {
        return brisko_auth()->hasAny();
    } catch (Throwable $e) {
        return false;
    }
}

function brisko_h(?string $value): string
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

function brisko_flash(?string $type = null, ?string $message = null): ?array
{
    if ($type !== null && $message !== null) {
        $_SESSION['flash'] = ['type' => $type, 'message' => $message];
        return null;
    }
    $flash = $_SESSION['flash'] ?? null;
    unset($_SESSION['flash']);
    return is_array($flash) ? $flash : null;
}

function brisko_redirect(string $path): never
{
    header('Location: ' . $path);
    exit;
}

/**
 * Sends a visitor to the correct admin entry point.
 *
 * - No admin provisioned in RTDB -> first-run registration page.
 * - An admin already exists      -> login page.
 */
function brisko_admin_entry_redirect(): never
{
    brisko_redirect(brisko_has_admin() ? 'login.php' : 'register.php');
}

/**
 * Firebase project ID this panel talks to. Prefers the explicit FCM project
 * ID and falls back to parsing the RTDB host name.
 */
function brisko_project_id(): string
{
    $cfg = brisko_config();
    $id = trim((string) ($cfg['fcm_project_id'] ?? ''));
    if ($id !== '') {
        return $id;
    }
    $host = (string) (parse_url((string) ($cfg['rtdb_base_url'] ?? ''), PHP_URL_HOST) ?? '');
    if (preg_match('/^(.+?)(?:-default-rtdb)?\.firebaseio\.com$/', $host, $m)) {
        return $m[1];
    }
    if (preg_match('/^(.+?)-default-rtdb\./', $host, $m)) {
        return $m[1];
    }
    return $host;
}

/**
 * Normalizes a Realtime Database URL for comparison: drops the scheme, any
 * trailing slash and casing so small typos in the scheme do not matter.
 */
function brisko_normalize_rtdb_url(string $url): string
{
    $url = trim($url);
    $url = (string) preg_replace('#^https?://#i', '', $url);
    return strtolower(rtrim($url, '/'));
}

function brisko_map(?array $node): array
{
    if (!is_array($node) || $node === []) {
        return [];
    }
    return $node;
}

function brisko_now_ms(): int
{
    return (int) round(microtime(true) * 1000);
}

function brisko_money($value): string
{
    return 'Rs ' . number_format((float) $value, 2);
}

function brisko_dt($ms): string
{
    $ms = (int) $ms;
    if ($ms <= 0) {
        return '-';
    }
    return date('d M Y, h:i A', (int) ($ms / 1000));
}

function brisko_invoice_url(string $orderId): string
{
    $base = rtrim((string) (brisko_config()['invoice_base_url'] ?? ''), '/');
    if ($base === '') {
        $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        $host = (string) ($_SERVER['HTTP_HOST'] ?? 'localhost');
        $base = $scheme . '://' . $host;
    }
    return $base . '/invoices/' . rawurlencode($orderId) . '.html';
}

function brisko_slug(string $value): string
{
    $value = strtolower(trim($value));
    $value = preg_replace('/[^a-z0-9]+/', '_', $value) ?? '';
    $value = trim($value, '_');
    return $value !== '' ? $value : 'item_' . brisko_now_ms();
}

function brisko_status_label(string $status): string
{
    return ucwords(str_replace('_', ' ', $status));
}

function brisko_order_type_key(string $type): string
{
    $key = preg_replace('/[^a-z0-9]/', '', strtolower(trim($type))) ?? '';
    return match ($key) {
        'takeaway', 'takeout', 'pickup' => 'takeaway',
        'dinein' => 'dineIn',
        default => 'delivery',
    };
}

function brisko_order_type_label(string $type): string
{
    return match (brisko_order_type_key($type)) {
        'takeaway' => 'Takeaway',
        'dineIn' => 'Dine-In',
        default => 'Delivery',
    };
}

function brisko_next_status(string $status): ?string
{
    $flow = ['placed', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered'];
    $i = array_search($status, $flow, true);
    if ($i === false || $i >= count($flow) - 1) {
        return null;
    }
    return $flow[$i + 1];
}

function brisko_user_tokens(array $user): array
{
    $tokens = $user['fcmTokens'] ?? [];
    if (!is_array($tokens)) {
        return [];
    }
    return array_keys($tokens);
}

function brisko_collect_all_tokens(array $users): array
{
    $out = [];
    foreach ($users as $user) {
        if (!is_array($user)) {
            continue;
        }
        foreach (brisko_user_tokens($user) as $t) {
            $out[] = $t;
        }
    }
    return $out;
}

function brisko_csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(16));
    }
    return (string) $_SESSION['csrf'];
}

function brisko_csrf_check(): void
{
    $token = (string) ($_POST['_csrf'] ?? '');
    if ($token === '' || !hash_equals((string) ($_SESSION['csrf'] ?? ''), $token)) {
        http_response_code(400);
        exit('Invalid session token. Refresh and try again.');
    }
}

function brisko_imgbb_upload(array $file): string
{
    $tmp = (string) ($file['tmp_name'] ?? '');
    if ($tmp === '' || !is_uploaded_file($tmp)) {
        throw new RuntimeException('Choose an image file.');
    }
    if ((int) ($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
        throw new RuntimeException('Image upload failed.');
    }
    $client = new ImgbbClient((string) (brisko_config()['imgbb_api_key'] ?? ''));
    return $client->upload($tmp, (string) ($file['name'] ?? 'image.jpg'));
}

function brisko_imgbb_from_request(string $fileKey, string $urlFallback = ''): string
{
    if (!empty($_FILES[$fileKey]['tmp_name'])) {
        return brisko_imgbb_upload($_FILES[$fileKey]);
    }
    return trim($urlFallback);
}

function brisko_attempt_file(string $key): string
{
    $dir = (string) (brisko_config()['attempts_dir'] ?? dirname(__DIR__) . '/storage/attempts');
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    return $dir . '/' . preg_replace('/[^A-Za-z0-9._-]/', '_', $key) . '.json';
}

function brisko_is_locked(string $key): bool
{
    $file = brisko_attempt_file($key);
    if (!is_file($file)) {
        return false;
    }
    $data = json_decode((string) file_get_contents($file), true);
    $until = (int) ($data['lockedUntil'] ?? 0);
    return $until > time();
}

function brisko_fail_attempt(string $key): void
{
    $cfg = brisko_config();
    $file = brisko_attempt_file($key);
    $data = is_file($file) ? (json_decode((string) file_get_contents($file), true) ?: []) : [];
    $count = (int) ($data['count'] ?? 0) + 1;
    $max = (int) ($cfg['login_max_attempts'] ?? 8);
    $lock = (int) ($cfg['login_lock_seconds'] ?? 900);
    $payload = ['count' => $count, 'lockedUntil' => $count >= $max ? time() + $lock : 0];
    file_put_contents($file, json_encode($payload));
}

function brisko_clear_attempts(string $key): void
{
    $file = brisko_attempt_file($key);
    if (is_file($file)) {
        file_put_contents($file, json_encode(['count' => 0, 'lockedUntil' => 0]));
    }
}

function brisko_notify_user(RtdbClient $rtdb, string $uid, string $title, string $body, string $type = 'general', ?string $orderId = null): void
{
    $id = 'n' . brisko_now_ms();
    $rtdb->put('users/' . $uid . '/notifications/' . $id, [
        'title' => $title,
        'body' => $body,
        'type' => $type,
        'orderId' => $orderId,
        'isRead' => false,
        'createdAt' => brisko_now_ms(),
    ]);
}
