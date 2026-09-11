# Brisko Pizza

Flutter customer app (Phase 1) with Firebase Auth + Realtime Database.

## Run

```bash
flutter pub get
flutter run
```

Web:

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Firebase

Project `brisko-20395` is already wired via `lib/firebase_options.dart` and `android/app/google-services.json`.

Enable:

- Authentication: Email/Password
- Realtime Database (open rules are fine for first seed)

On first launch the app seeds sample outlets, menu, coupons, and loyalty config if `/categories` is empty.

RTDB rules from the spec are in `database.rules.json`. Keep rules open until seed finishes, then paste these rules in Firebase Console.

## Coupons

- `BRISKO50` — Rs 50 off above Rs 299
- `FIRST100` — first order, Rs 100 off above Rs 399
- `PIZZA20` — 20% off up to Rs 120

## Notes

- Location: detect GPS, enter lat/lng, or tap **Use demo outlet (Delhi CP)**
- Payments: Cash on Delivery is live. Online payment is a `PaymentGateway` stub (coming soon)
- Phase 2 admin panel is not built yet
