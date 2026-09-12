# Brisko Pizza Auth API (Phase 1)

PHP 8+ endpoints for customer OTP login. **No MySQL.** All OTP and user data live in Firebase Realtime Database.

Deploy the contents of `api/` to `https://delhitrade.in/abhishek/api/` so these URLs exist:

- `POST https://delhitrade.in/abhishek/api/send_otp.php`
- `POST https://delhitrade.in/abhishek/api/verify_otp.php`

Also upload `lib/` and `config/` one level above `api/` (same layout as this folder), or keep the relative `dirname(__DIR__)` structure.

## Required config

1. Copy `config/firebase-service-account.json.example` to `config/firebase-service-account.json` and paste your Firebase service account JSON.
2. Set `BRISKO_FAST2SMS_KEY` (or edit `config/config.php`) to your Fast2SMS API key.
3. Keep `config/` outside the public web root, or rely on `config/.htaccess` which denies HTTP access.

Optional env:

- `BRISKO_RTDB_URL` — defaults to the Brisko RTDB
- `BRISKO_OTP_DEV_ECHO=1` — returns `devOtp` in the send response (local testing only; never enable in production)

## Request bodies

Send OTP:

```json
{ "phone": "9876543210" }
```

Verify OTP:

```json
{ "phone": "9876543210", "otp": "123456" }
```

On success, `verify_otp.php` returns a Firebase custom token. The Flutter app calls `signInWithCustomToken` and then talks to RTDB directly.
