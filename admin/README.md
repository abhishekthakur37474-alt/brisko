# Brisko Admin (PHP + Bootstrap 5)

Server-rendered admin panel for the Brisko Pizza Flutter app. It reads and writes the same Firebase Realtime Database.

## First run

1. Copy `config/firebase-service-account.json.example` to `config/firebase-service-account.json` and paste your Firebase service account (needed for FCM and locked RTDB rules).
2. Product and category images upload via ImgBB (`imgbb_api_key` in `config/config.php`).
3. Open `register.php` once to create the first admin. After that, registration is closed.
4. Sign in at `login.php`.
5. Password reset is `reset_credentials.php` (direct URL only, not linked anywhere).
6. To let a legacy gateway call `api/payment_webhook.php`, set `BRISKO_PAYMENT_WEBHOOK_SECRET` and send it as the `X-Webhook-Secret` header. Without it the endpoint rejects every request. Cashfree uses the signed `backend/api/cashfree/webhook.php` instead.

## Local preview

```bash
php -S 0.0.0.0:8000 -t admin admin/router.php
```

## Cron

Daily loyalty expiry:

```bash
php admin/cron/expire_loyalty_points.php
```

## Pages

Dashboard, orders (status + invoice), products, categories, outlets, coupons, customers, support tickets, broadcasts, loyalty config, reports/CSV.
