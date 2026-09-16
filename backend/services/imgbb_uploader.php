<?php

declare(strict_types=1);

/**
 * Small ImgBB client used to host the customer's payment screenshot.
 *
 * The API key lives only in backend config (IMGBB_API_KEY) and is never sent to
 * the Flutter app. The app uploads the file to our own authenticated endpoint,
 * which in turn uploads it here and returns the hosted URL.
 */
class ImgbbUploader
{
    private string $apiKey;
    private int $timeout;

    /** @param array<string, mixed> $config */
    public function __construct(array $config)
    {
        $this->apiKey = trim((string) ($config['api_key'] ?? ''));
        $this->timeout = max(5, (int) ($config['timeout'] ?? 40));
    }

    public function isConfigured(): bool
    {
        return $this->apiKey !== '';
    }

    /**
     * Uploads a local temp file and returns the public image URL.
     */
    public function upload(string $tmpPath, string $name = 'payment-proof.jpg'): string
    {
        if (!$this->isConfigured()) {
            throw new ApiException('Payment proof upload is not configured right now.', 503);
        }
        if ($tmpPath === '' || !is_file($tmpPath)) {
            throw new ApiException('Upload file is missing.');
        }

        $ch = curl_init('https://api.imgbb.com/1/upload?key=' . urlencode($this->apiKey));
        $cfile = new CURLFile($tmpPath, mime_content_type($tmpPath) ?: 'image/jpeg', $name);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => $this->timeout,
            CURLOPT_POSTFIELDS => ['image' => $cfile],
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($raw === false) {
            throw new ApiException('Could not reach the image host. Please try again.', 502);
        }

        $json = json_decode((string) $raw, true);
        $url = $json['data']['url'] ?? $json['data']['display_url'] ?? null;
        if ($code >= 400 || !is_string($url) || $url === '') {
            error_log('[brisko] imgbb upload failed (' . $code . '): ' . ($error !== '' ? $error : (string) $raw));
            throw new ApiException('Image upload failed. Please try again.');
        }
        return $url;
    }
}
