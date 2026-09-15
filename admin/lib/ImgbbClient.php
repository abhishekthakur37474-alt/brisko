<?php

declare(strict_types=1);

class ImgbbClient
{
    private string $apiKey;

    public function __construct(string $apiKey)
    {
        $this->apiKey = $apiKey;
    }

    public function enabled(): bool
    {
        return $this->apiKey !== '';
    }

    public function upload(string $tmpPath, string $name = 'image'): string
    {
        if (!$this->enabled()) {
            throw new RuntimeException('ImgBB API key is not configured.');
        }
        if (!is_file($tmpPath)) {
            throw new RuntimeException('Upload file is missing.');
        }
        $ch = curl_init('https://api.imgbb.com/1/upload?key=' . urlencode($this->apiKey));
        $cfile = new CURLFile($tmpPath, mime_content_type($tmpPath) ?: 'image/jpeg', $name);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 40,
            CURLOPT_POSTFIELDS => ['image' => $cfile],
        ]);
        $raw = curl_exec($ch);
        $code = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        $json = json_decode((string) $raw, true);
        $url = $json['data']['url'] ?? $json['data']['display_url'] ?? null;
        if ($code >= 400 || !$url) {
            throw new RuntimeException('Image upload failed.');
        }
        return (string) $url;
    }
}
