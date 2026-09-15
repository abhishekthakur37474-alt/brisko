# Brisko Pizza — Flutter + Firebase (RTDB only) + PHP Backend (OTP Auth + Admin)
### Complete Project Specification for AI Development Agent

> Give this entire file to your AI coding agent (or Claude Code / Cursor / etc.) as the single source of truth. **Build in two clear phases, in this order: Phase 1 — the full Flutter customer app. Phase 2 — the Admin Panel (Flutter Web + PHP backend).** Do not start Phase 2 until Phase 1 is functionally complete.
>
> **Exception carved out by the OTP-login change:** two PHP endpoints (`api/send_otp.php`, `api/verify_otp.php`) are customer-facing and required for Phase 1's login screen to work. Build this small "Auth API" slice of the PHP backend early — before the rest of Phase 2 — since Phase 1 can't function without it. Everything else in the PHP backend still waits for Phase 2.

---

## 1. Project Overview

- **App Name:** Brisko Pizza
- **Platform:** Android (Flutter, single codebase — keep iOS-compatible where free)
- **Two separate pieces, two separate stacks:**
  1. **Customer App (Phase 1)** — **Flutter + Firebase**, with one exception: **login/register goes through the PHP backend**, not Firebase Authentication's own providers. Flow: Flutter → PHP (`send_otp.php`, `verify_otp.php`, using Fast2SMS) → PHP mints a Firebase **custom token** → Flutter signs in with that token → from then on, the app talks **directly** to Firebase Realtime Database using the normal `auth.uid`, same as before. Every other screen (menu, cart, orders, tracking) is still direct-to-RTDB, no PHP in the loop.
  2. **Admin Panel (Phase 2)** — a Flutter Web app (deployed free on Firebase Hosting) for the UI, backed by the same **PHP REST API** (hosted separately, on any cheap/free PHP hosting) for the handful of operations that need server-side trust: OTP send/verify, image upload, order status changes + push notifications, loyalty point crediting, broadcast notifications, payment webhook handling, and reports.
- **Auth Method:** Mobile number + OTP, sent via **Fast2SMS** and verified by the PHP backend (no email/password provider, no social login for v1)
- **Delivery Tracking:** Status-based only. **No live GPS / real-time rider tracking** in v1. Because the customer app reads order status live from Realtime Database (`.onValue` stream), the status stepper still updates instantly on-screen the moment admin changes it — that's a free side-benefit of RTDB, not GPS tracking.
- **Core Idea:** Customer opens app → app detects their location → app shows only the single Brisko outlet that serves that area → customer browses menu, customizes pizza, orders, pays, tracks status live, earns loyalty points.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| State Management | Riverpod (preferred) or Bloc |
| Firebase (Spark/free plan) | Authentication (**Custom Token sign-in only** — no Email/Password or Phone providers enabled), Realtime Database (RTDB), Cloud Messaging (FCM), Analytics, Crashlytics |
| OTP Delivery | **Fast2SMS API** — called only from the PHP backend to send the 4–6 digit OTP SMS |
| **Customer App connection** | **Direct for everything except login** — Flutter talks straight to Firebase via `google-services.json` for RTDB/FCM. For login/register, it calls the PHP `send_otp.php` / `verify_otp.php` endpoints, gets back a Firebase custom token, and signs in with `signInWithCustomToken()` — after that it's back to direct RTDB access using the resulting `auth.uid`. |
| **Backend** | **PHP REST API**, used by the customer app (OTP auth endpoints only) and by the Admin Panel + payment gateway webhook (everything else) |
| Backend ↔ RTDB link | PHP talks to Realtime Database via its native REST API (`https://<project>-default-rtdb.<region>.firebasedatabase.app/<path>.json`), authenticated with a Firebase service-account OAuth2 token |
| Backend ↔ Firebase Auth link | PHP uses the **Firebase Admin SDK for PHP** (e.g. `kreait/firebase-php`) with the same service-account credentials to **mint custom sign-in tokens** after OTP verification — this is what lets the app get a normal `auth.uid` without ever using Firebase's own Email/Password or Phone Auth providers |
| Database | Firebase Realtime Database (JSON tree — see §5.2) |
| Image Hosting | **ImgBB API** — called only from the PHP admin backend when admin uploads a product/category/banner image |
| Invoice Storage | Generated PDF invoices saved on the PHP server's disk; URL saved into the order's `invoiceUrl` field in RTDB |
| Push Notifications | Firebase Cloud Messaging (FCM) — sent by the PHP backend (via FCM HTTP v1 API) whenever admin changes an order's status or sends a broadcast |
| Payments | **Gateway TBD** — Cash on Delivery built and finalized now; online payment (UPI/Card) built behind a generic `PaymentGateway` interface so any SDK (Razorpay, Cashfree, PhonePe, etc.) can be plugged in later without touching checkout/order logic |
| Maps/Location | `geolocator` + `geocoding` packages, used directly in the Flutter app (one-time "detect my location" + serviceability check — done client-side against the `/outlets` node, no PHP needed) |
| Admin Panel Frontend | Flutter Web, deployed on **Firebase Hosting** (free, no domain needed — gets a free `*.web.app` URL) |
| Scheduled Jobs | Server cron job on the PHP host (e.g. `cron/expire_loyalty_points.php`, run daily) |
| Crash/Analytics | Firebase Crashlytics + Firebase Analytics |

---

## 3. Branding & Theme (from logo)

The logo is a bold letter **"B"** styled as a 3D pizza slice icon.

**Color Palette:**
- Primary Red: `#E30613`
- Deep Black: `#111111`
- Pure White: `#FFFFFF`
- Accent Grey (for cards/backgrounds): `#F5F5F5`
- Success Green (order delivered): `#2E7D32`
- Warning/Preparing Amber: `#F5A623`

**Typography:**
- Headings: Bold, rounded sans-serif (e.g. `Poppins` or `Baloo 2` — pizza-brand friendly, playful but bold)
- Body: `Inter` or `Roboto`

**UI Style:**
- Dark app bar / bottom nav in Black with Red accents
- White content cards with soft shadows
- Rounded corners (12–16px radius) everywhere — buttons, cards, images
- Red primary CTA buttons, black secondary buttons, white/outline tertiary buttons
- Use the pizza-slice motif (red triangle with pepperoni circles) as a loading spinner / empty-state illustration accent
- App icon: the uploaded "B" pizza-slice logo on a black background, exported at all required Android densities (mipmap-hdpi to xxxhdpi)
- Splash screen: Black background, centered white "B" pizza logo, small tagline "Hot. Fresh. Fast." in white

---

# PHASE 1 — Customer App (Flutter + Firebase only)

Build this entire phase first, fully working end-to-end, before touching Phase 2 (Admin Panel).

## 4. Customer App Architecture

```
lib/
 ├── main.dart
 ├── app.dart                     # MaterialApp, theme, routing
 ├── core/
 │    ├── constants/               # colors, text styles, strings
 │    ├── theme/
 │    ├── utils/
 │    ├── widgets/                 # shared buttons, cards, loaders
 │    └── services/                # firebase_service (RTDB+custom-token sign-in), otp_auth_service (calls PHP send_otp/verify_otp), location_service, payment_service, notification_service
 ├── features/
 │    ├── auth/                    # mobile number entry, OTP verification, register (name + phone)
 │    ├── onboarding/
 │    ├── home/
 │    ├── location/                # detect location, outlet matching (all client-side)
 │    ├── menu/
 │    ├── product_detail/          # customization
 │    ├── cart/
 │    ├── checkout/
 │    ├── payment/
 │    ├── orders/
 │    ├── order_tracking/
 │    ├── notifications/
 │    ├── offers_coupons/
 │    ├── wishlist/
 │    ├── reviews/
 │    ├── support/
 │    ├── loyalty/
 │    ├── profile/
 │    └── addresses/
```

State management: one provider/notifier per feature. Use `go_router` for navigation with named routes and deep-link support (for notification taps → order details, etc.). Use the `firebase_database` Flutter package for RTDB reads/writes/streams (`.onValue` listeners give live UI updates for free — great for order tracking). Enable RTDB's offline persistence so cart/browsing works with a flaky connection.

## 5. Firebase Setup

### 5.1 Firebase Products to Enable (all free, Spark plan)
- Authentication → enable the **"Custom"** sign-in provider only. Do **not** enable Email/Password or Phone Auth — OTP is handled entirely by the PHP backend + Fast2SMS, specifically to avoid Firebase Phone Auth's Blaze (pay-as-you-go) plan requirement and per-SMS billing.
- Realtime Database (start in locked mode, apply rules from §8)
- Cloud Messaging (FCM) — customer app just registers its device token; PHP sends the actual pushes later in Phase 2
- Crashlytics, Analytics
- App Check (recommended)

### 5.2 Realtime Database Structure (JSON Tree)

RTDB has no collections/documents or compound queries — everything is one JSON tree. Flatten data and use small index nodes for lookups. Structure:

```
brisko-db (root)
│
├── users
│   └── {uid}                      # uid = the Firebase custom-token uid PHP assigns at first OTP verify (recommend: normalized phone, e.g. "91XXXXXXXXXX")
│       ├── name, phone (verified, primary identifier), email (optional, unverified), createdAt, defaultAddressId
│       ├── loyaltyPoints: number
│       ├── role: "customer" | "admin" | "outlet_manager"
│       ├── fcmTokens: { "<token1>": true }
│       ├── addresses/{addressId}: { label, fullAddress, lat, lng, outletId, isDefault }
│       ├── cart/{cartItemId}: { productId, name, image, selectedSize, selectedCrust,
│       │                         toppings: {...}, addons: {...}, quantity, unitPrice, totalPrice }
│       ├── wishlist/{productId}: true
│       ├── notifications/{notifId}: { title, body, type, orderId, isRead, createdAt }
│       └── loyaltyHistory/{entryId}: { orderId, pointsEarned, pointsRedeemed, balanceAfter, createdAt }
│
├── otps/{phone}: { otpHash, expiresAt, attempts, lastSentAt }   # transient — PHP-only via service account, never exposed to any client rule, deleted/expired after verify
│
├── outlets/{outletId}: { name, address, lat, lng, serviceRadiusKm, isActive, contactNumber, openTime, closeTime }
│
├── categories/{categoryId}: { name, imageUrl, sortOrder, isActive }
│
├── products/{productId}
│       ├── name, description, categoryId, images: {0: url, 1: url}
│       ├── basePrice, isVeg, isBestSeller, isFeatured, isActive
│       ├── outletIds: { "{outletId}": true }
│       ├── customizations: { sizes:{...}, crusts:{...}, toppings:{...}, addons:{...} }
│       └── avgRating, reviewCount
│
├── coupons/{couponCode}: { description, discountType, discountValue, minOrderValue,
│                            maxDiscount, validFrom, validTo, usageLimitPerUser,
│                            isFirstOrderOnly, isActive }
│
├── orders/{orderId}
│       ├── userId, outletId, items:{0:{...},1:{...}}, addressSnapshot:{...}
│       ├── subtotal, gstAmount, deliveryCharge, couponCode, couponDiscount
│       ├── loyaltyPointsUsed, loyaltyDiscount, finalAmount
│       ├── paymentMethod, paymentStatus
│       ├── orderStatus: "placed"|"confirmed"|"preparing"|"ready"|"out_for_delivery"|"delivered"|"cancelled"
│       ├── statusTimestamps:{...}, orderNotes, createdAt, updatedAt, invoiceUrl
│
├── userOrders/{uid}/{orderId}: true          # index node — RTDB can't query "orders where userId==X"
├── outletOrders/{outletId}/{orderId}: true   # index node — for admin's per-outlet order view
│
├── reviews/{productId}/{userId}: { userName, rating, comment, createdAt }
│
├── supportTickets/{ticketId}: { userId, type, message, status, createdAt }
│
└── loyaltyConfig: { pointsPerRupeeSpent, redemptionValuePerPoint,
                      minPointsToRedeem, maxPointsUsablePerOrder, pointsExpiryDays,
                      minOrderValueForPoints }
```

**Why index nodes (`userOrders`, `outletOrders`):** RTDB can't do a SQL-style `WHERE userId = X`. So the app writes `true` under `/userOrders/{uid}/{orderId}` and `/outletOrders/{outletId}/{orderId}` at the same moment it creates an order — using an RTDB **multi-path update** so all three writes (the order itself + both index entries) succeed or fail together as one atomic operation.

**Why maps instead of arrays** (`outletIds`, `toppings`, `fcmTokens`, `wishlist`, etc.): RTDB arrays are fragile — removing an array element can silently reindex the rest. The safe, Firebase-recommended pattern is a map of `id: true` (or `id: value`), which supports safe add/remove of individual entries.

## 6. Feature Modules (Phase 1 — all direct Flutter ↔ Firebase, except login which goes through the PHP OTP endpoints)

### 6.1 Login & Account (Mobile OTP, via PHP + Fast2SMS)
- **Enter mobile number** → app calls `POST api/send_otp.php { phone }` → PHP generates a 4–6 digit OTP, stores a hash of it at `/otps/{phone}` in RTDB (via service account) with a short expiry (e.g. 5 min) and a resend cooldown, sends it via the **Fast2SMS API**
- **Enter OTP** → app calls `POST api/verify_otp.php { phone, otp }` → PHP checks the hash/expiry/attempt-count at `/otps/{phone}`, and on success:
  - creates the user's `/users/{uid}` record if it doesn't exist yet (new registration, `uid` = normalized phone), or looks it up if it does (returning login)
  - mints a **Firebase custom token** for that `uid` via the Firebase Admin SDK
  - deletes/expires the `/otps/{phone}` entry
  - returns the custom token + basic profile to the app
- App calls `FirebaseAuth.instance.signInWithCustomToken(token)` → from this point on `auth.uid` is set and every RTDB security rule in §8 works exactly as before
- First-time users are asked for their **name** right after OTP verification (phone is already captured/verified); returning users skip straight to Home
- Rate-limit both endpoints server-side (e.g. max N OTP sends per phone per hour) to control Fast2SMS costs and block abuse
- No password, no "forgot password" flow — losing access just means requesting a fresh OTP
- Profile view/edit (name, email now optional), Logout (client-side Firebase sign-out)
- Changing the registered phone number requires re-verifying the new number via the same OTP flow before it's saved
- Saved addresses (add/edit/delete, set default) — `users/{uid}/addresses`

### 6.2 Location & Outlet Matching
- Request location permission → detect lat/lng via `geolocator` → reverse-geocode for display
- Load `/outlets` (small dataset — fine to fetch the whole node) and check radius/distance **client-side in Flutter** to find the matching outlet — no server call needed for this
- **Rule:** exactly one match → auto-select it
- **Rule:** zero matches → "Sorry, Brisko doesn't deliver to your area yet" + notify-me option
- **Rule:** multiple matches (overlap) → pick nearest outlet by distance
- Customer is **locked** to their detected/selected address's outlet for that order
- Manual address change re-runs this same check

### 6.3 Home Screen
- Brisko logo + current delivery address (tap to change) + notification bell
- Search bar, promotional banner carousel, "Best Sellers", Categories grid, "Featured Products"
- Bottom nav: Home | Menu | Cart | Orders | Profile

### 6.4 Menu
- Category tabs: Pizzas, Burgers, Sides, Beverages, Combos, Offers
- Veg/Non-veg filter (client-side, after loading a category's products)
- Product cards: image, name, starting price, veg/non-veg indicator, rating

### 6.5 Product Customization
- Image carousel, size/crust selectors, toppings multi-select, extra cheese toggle, add-ons, quantity stepper
- Live dynamic price calculation (sticky bottom bar)
- "Add to Cart" → writes to `users/{uid}/cart/{cartItemId}`

### 6.6 Cart
- Item list with edit/remove/quantity controls
- Coupon code input (validated client-side against `/coupons/{code}` rules — see the pricing note in §7)
- Price breakdown: Subtotal, GST, Delivery Charge, Loyalty discount, **Final Total**
- "Proceed to Checkout"

### 6.7 Checkout
- Delivery address (re-validates outlet on change), order summary, coupon section
- Loyalty points redemption toggle + live discount preview
- Payment method selection, order notes field, "Place Order" button

### 6.8 Payment

- **Cash on Delivery** — build and finalize fully now, no dependency on any gateway
- **Online payment (UPI/Card/etc.) — gateway not decided yet.** Build this behind an abstraction so the actual SDK can be swapped in later with minimal changes:
  ```dart
  abstract class PaymentGateway {
    Future<PaymentResult> pay({required double amount, required String orderId, required String currency});
  }
  ```
  - Checkout screen and order-placement logic call only this interface, never a specific SDK directly
  - For now, ship a `MockPaymentGateway` (or keep the "Online Payment" option visible but disabled/"Coming soon") so the UI and order flow are fully built and testable
  - Once the client confirms a gateway (Razorpay, Cashfree, PhonePe, etc.), just add one new class implementing `PaymentGateway` (e.g. `RazorpayGateway`) and swap it in — no changes needed to cart, checkout, or order-writing logic
  - On successful payment (once a real gateway is wired in) → app writes `paymentStatus: paid` to RTDB
  - On COD → order written with `paymentStatus: pending`
  - **Note for later:** whichever gateway is chosen will also need a small PHP webhook endpoint (`api/payment_webhook.php`, already scoped in Phase 2, §11) as a server-side double-check — this is a near-universal requirement of payment gateways (they call your server directly), not specific to any one provider

### 6.9 Orders
- Place order: Flutter computes the final price (§7 formula), then writes to `/orders/{orderId}` **and** the two index nodes (`userOrders`, `outletOrders`) in a single RTDB multi-path update
- Order confirmation screen, order history (read `userOrders/{uid}` → fetch each order, or listen live)
- Order details with status timeline
- Cancel order (only while status is "placed" or "confirmed") — customer app can write `orderStatus: cancelled` directly since this is a customer-initiated, low-risk transition (see §8 rules)
- Reorder (re-add same items/customizations to cart, re-validate outlet & recompute price)
- Invoice link (populated later by the admin backend in Phase 2 — show "generating..." until `invoiceUrl` appears)

### 6.10 Order Tracking (Status-Based — No Live GPS)
- Linear stepper: Placed → Confirmed → Preparing → Ready → Out for Delivery → Delivered
- App listens to `orders/{orderId}` with `.onValue` — status updates appear instantly the moment admin changes them in Phase 2, no polling
- (Live GPS/rider tracking explicitly out of scope for v1)

### 6.11 Notifications (FCM)
- App registers its FCM token into `users/{uid}/fcmTokens` on login
- Actual notification *sending* happens from the Phase 2 PHP backend (order status changes, broadcasts) — the customer app's job here is just to register the token and display incoming notifications in an in-app notification center (`users/{uid}/notifications`)

### 6.12 Offers & Coupons
- Coupon codes validated against `/coupons/{code}` client-side (flat/percent discount, min order value, max discount cap, usage limit, validity window, first-order-only check against `userOrders/{uid}` count)
- Combo deals modeled as regular `products` with `categoryId = combos`

### 6.13 Wishlist / Favorites
- Heart icon toggles `users/{uid}/wishlist/{productId}: true`

### 6.14 Reviews & Ratings
- Post-delivery prompt to rate & review → `reviews/{productId}/{userId}`
- Average rating shown on product detail (`products/{id}/avgRating` — recomputed client-side on each new review, or left as a Phase 2 admin-maintained field if you want it more tamper-resistant)
- One review per user per product (key = `{userId}`, so re-submitting = editing)

### 6.15 Customer Support
- WhatsApp deep link (`https://wa.me/<number>`), direct call (`tel:` intent)
- Contact/complaint form → `supportTickets/{ticketId}`

### 6.16 Loyalty / Reward Points (customer-facing side)
- Loyalty screen: current balance, earned/redeemed totals, full history (`users/{uid}/loyaltyHistory`)
- At checkout: redeem points toggle, capped by `loyaltyConfig` rules, discount applied to the order total
- **Points crediting on delivery happens in Phase 2** (admin/PHP side, triggered when admin marks an order delivered) — the customer app only *displays* the balance and history, it does not credit points itself

---

## 7. Pricing Calculation Logic (client-side formula, used consistently everywhere in the app)

```
itemPrice = basePrice + sizeModifier + crustModifier + sum(toppingPrices) + sum(addonPrices)
lineTotal = itemPrice * quantity
subtotal = sum(all lineTotals)
gstAmount = subtotal * gstRate            // e.g. 0.05
deliveryCharge = subtotal >= freeDeliveryThreshold ? 0 : flatDeliveryFee
couponDiscount = per /coupons/{code} rules
loyaltyDiscount = pointsUsed * redemptionValuePerPoint   (capped by loyaltyConfig)
finalAmount = subtotal + gstAmount + deliveryCharge - couponDiscount - loyaltyDiscount
```

**Honest trade-off to flag for the client/owner:** since Phase 1 has no server validating this calculation, a technically sophisticated user could tamper with the app and submit a manipulated price. This is a known, accepted risk for a v1 at this scale — mitigated by:
- RTDB rules (§8) enforcing basic sanity (e.g. `finalAmount` must be a positive number, `orderStatus` on creation must be exactly `"placed"`, a user can only write orders where `userId == auth.uid`)
- Admin panel showing every incoming order's full price breakdown for a quick human sanity-check
- If this risk becomes a real concern later, the fix is to add one PHP endpoint (`validate_price.php`) that recomputes and locks the price before the order write — straightforward to bolt on later without restructuring anything else.

---

## 8. Realtime Database Security Rules (Phase 1 scope)

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid",
        "loyaltyPoints": { ".write": false },
        "role": { ".write": false }
      }
    },
    "orders": {
      "$orderId": {
        ".read": "auth != null && (data.child('userId').val() == auth.uid || root.child('users').child(auth.uid).child('role').val() == 'admin')",
        ".write": "auth != null && ((!data.exists() && newData.child('userId').val() == auth.uid && newData.child('orderStatus').val() == 'placed') || data.child('userId').val() == auth.uid && newData.child('orderStatus').val() == 'cancelled' && (data.child('orderStatus').val() == 'placed' || data.child('orderStatus').val() == 'confirmed') || root.child('users').child(auth.uid).child('role').val() == 'admin')"
      }
    },
    "products": { ".read": true, ".write": "root.child('users').child(auth.uid).child('role').val() == 'admin'" },
    "categories": { ".read": true, ".write": "root.child('users').child(auth.uid).child('role').val() == 'admin'" },
    "outlets": { ".read": true, ".write": "root.child('users').child(auth.uid).child('role').val() == 'admin'" },
    "coupons": { ".read": true, ".write": "root.child('users').child(auth.uid).child('role').val() == 'admin'" },
    "loyaltyConfig": { ".read": true, ".write": "root.child('users').child(auth.uid).child('role').val() == 'admin'" },
    "reviews": {
      "$productId": { "$userId": { ".write": "auth != null && auth.uid == $userId", ".read": true } }
    },
    "userOrders": { "$uid": { ".read": "auth != null && auth.uid == $uid", ".write": "auth != null && auth.uid == $uid" } },
    "outletOrders": {
      ".read": "root.child('users').child(auth.uid).child('role').val() == 'admin'",
      ".write": "auth != null"
    },
    "otps": { ".read": false, ".write": false }
  }
}
```

Note: `orderStatus` is writable by the customer only to create a new order (`placed`) or to cancel their own order while it's still `placed`/`confirmed` — every other transition (`confirmed → preparing → ... → delivered`) is admin-only, enforced by this same rule since it only allows admin writes for anything else. Test all rules in the Firebase Console's Rules Playground before going live.

**Why these rules still work unchanged after the OTP switch:** `auth.uid` is set the same way whether the user signed in via Email/Password or via a custom token — Firebase treats a custom-token sign-in identically to any other for the purposes of `auth != null` and `auth.uid` in Realtime Database rules. Only the *login mechanism* changed; the RTDB trust model didn't. The `/otps` node is locked to `false`/`false` because it's only ever touched server-side by the PHP backend using the service-account token, which bypasses these client rules entirely.

---

# PHASE 2 — Admin Panel (Flutter Web + PHP Backend)

Only start this after Phase 1 (the customer app) is fully built and working.

## 9. Admin Panel Architecture

- **Frontend:** Flutter Web app, deployed on **Firebase Hosting** (free `*.web.app` URL, no domain purchase needed)
- **Backend:** PHP REST API, hosted separately (any cheap/free PHP hosting — free subdomain is fine, e.g. `briskoadmin.infinityfreeapp.com`)
- Admin panel reads/writes most things (products, categories, coupons, outlets) **directly from RTDB** using the Firebase Web SDK with admin-role rules — same pattern as the customer app, just with an admin account
- Admin panel calls the **PHP API** only for the specific operations listed below that need real server trust
- The **customer app** also calls this same PHP API, but only for the two OTP auth endpoints (`send_otp.php`, `verify_otp.php`) — build these first, as part of Phase 1 (see the note at the top of this document)

```
backend/
 ├── config/
 │    ├── firebase-service-account.json   # keep OUTSIDE web root / .htaccess-protected — used for both RTDB access AND minting custom auth tokens
 │    ├── config.php                       # ImgBB key, Razorpay keys, RTDB base URL, Fast2SMS API key
 │    └── rtdb.php
 ├── vendor/                               # composer packages, incl. kreait/firebase-php (Firebase Admin SDK)
 ├── lib/
 │    ├── RtdbClient.php       # GET/PUT/PATCH/POST a JSON path in RTDB via REST + service-account OAuth
 │    ├── FirebaseAuthClient.php # mints a Firebase custom sign-in token for a given uid (via kreait/firebase-php)
 │    ├── Fast2SmsClient.php   # sends an OTP SMS via the Fast2SMS API
 │    ├── FcmClient.php        # send push via FCM HTTP v1 API
 │    ├── ImgbbClient.php      # upload image to ImgBB
 │    └── PdfInvoice.php       # generate invoice PDF (dompdf/tcpdf)
 ├── api/
 │    ├── send_otp.php                   # customer app: generate OTP, store hash+expiry in /otps/{phone}, send via Fast2SMS
 │    ├── verify_otp.php                 # customer app: check OTP, create/fetch user, mint Firebase custom token, return it
 │    ├── upload_image.php               # admin uploads a product/category/banner image → ImgBB → URL
 │    ├── update_order_status.php        # admin moves an order to next stage → RTDB + FCM push
 │    ├── credit_loyalty_points.php      # called automatically by update_order_status.php when status = delivered
 │    ├── send_broadcast_notification.php# admin sends a promo push to all/segment
 │    ├── generate_invoice.php           # builds PDF invoice, saves it, updates invoiceUrl in RTDB
 │    ├── payment_webhook.php            # Razorpay/Cashfree calls this directly (server-to-server)
 │    ├── reports.php                    # sales/outlet/product reports, CSV export
 │    └── auth_middleware.php            # verifies the admin's Firebase ID token on every call (admin endpoints only — send_otp/verify_otp are public/rate-limited instead, since a logged-out user has no token yet)
 └── cron/
      └── expire_loyalty_points.php      # daily cron, expires old points
```

**Why these specific things need PHP and nothing else does:**
- **OTP send/verify** — the Fast2SMS API key and the Firebase service-account credentials (used to mint custom tokens) must never sit on the client
- **Image upload** — keeps the ImgBB API key off the client entirely
- **Order status change** — bundles the RTDB update and the FCM push into one trusted, atomic admin action
- **Loyalty crediting** — should only ever be triggered by a real "delivered" transition, not client-editable
- **Broadcast notifications** — needs the FCM server key/OAuth flow, not safe to embed in a web app
- **Payment webhook** — Razorpay/Cashfree call this URL directly from their servers; this is structurally required by how payment gateways work and can't be replaced by anything client-side
- **Reports** — RTDB has no server-side aggregation, so summarizing sales data is easier done once, server-side, in PHP, rather than pulling the whole `/orders` tree into the browser each time

## 10. Admin Panel Feature Modules

- Dashboard (orders today, revenue, top products — via `api/reports.php`)
- Manage Products (CRUD direct to RTDB; images via `api/upload_image.php`)
- Manage Categories, Prices, Offers/Coupons (direct RTDB CRUD)
- Manage Outlets (service area radius/polygon via a map picker, direct RTDB CRUD)
- Manage Orders (list via `outletOrders`/`userOrders` index nodes; status changes via `api/update_order_status.php`)
- Manage Customers (view/block — direct RTDB, `role`/`isBlocked` field, admin-only write)
- Send Notifications → `api/send_broadcast_notification.php`
- Reports/CSV export → `api/reports.php`
- Manage Loyalty Program config (`/loyaltyConfig` node, direct RTDB write since admin-only)
- Roles: Super Admin (full access) vs Outlet Manager (scoped via `outletOrders/{outletId}`)

## 11. Payment Webhook Note

Even though the customer app calls Razorpay/Cashfree directly and writes `paymentStatus: paid` on success, it's good practice to also let the gateway's webhook hit `api/payment_webhook.php` as a **second, server-verified confirmation** — this catches edge cases where the app closes/crashes right after a successful payment but before it could write to RTDB. The webhook endpoint verifies the payment signature and double-checks/corrects `paymentStatus` on the matching order.

---

## 12. Non-Functional Requirements

- Smooth on low-to-mid range Android devices
- Cached network images (avoid re-downloading)
- RTDB's built-in offline persistence enabled → cart/browsing works with a flaky connection
- Loading skeletons, not blank spinners
- Error states: no internet, no outlet in area, empty cart, payment failure
- Accessibility: high contrast (red/white/black), readable font sizes
- No compound-query designs (RTDB limitation) — use index nodes + light client-side filtering instead

## 13. Explicitly Out of Scope for v1

- Live GPS / real-time delivery rider tracking on a map
- Social login (Google/Facebook, etc.) — only mobile OTP login is supported in v1
- iOS App Store release (cross-platform build fine, but launch target is Android/Play Store only)
- Multi-language support
- Server-side price validation (accepted risk for v1 — see §7)

## 14. App Deployment Checklist

- App name: **Brisko Pizza**; icon from uploaded "B" pizza logo, all densities
- Package name: `com.brisko.pizza` (confirm/adjust)
- Signed release APK/AAB for Play Store
- Play Store listing: screenshots, feature graphic, descriptions
- Privacy Policy, Terms & Conditions, Refund/Cancellation Policy pages
- Data Safety form on Play Console (location, email, order data)
- Firebase RTDB rules locked down (§8) before going live
- Admin Panel deployed on Firebase Hosting (free `*.web.app` URL — no domain purchase required)
- PHP backend deployed on any hosting with PHP 8+, HTTPS, and cron access (free subdomain hosting is fine — no domain purchase required, though a real domain is a nice-to-have for a more professional look, not a requirement)
- `config/firebase-service-account.json` and `config/config.php` kept **outside the public web root**

---

## 15. Build Order (recommended sequence for the AI agent)

### Phase 1 — Customer App (build this fully first)
0. **PHP Auth API slice (pulled forward from Phase 2):** `RtdbClient.php`, `FirebaseAuthClient.php` (Firebase Admin SDK / `kreait/firebase-php`), `Fast2SmsClient.php`, `api/send_otp.php`, `api/verify_otp.php` — deploy this small piece early since Phase 1 login depends on it
1. Flutter project setup + Firebase integration (Realtime Database + custom-token Auth, Spark plan)
2. Theme, colors, fonts, shared widgets, app icon, splash screen
3. Auth flow (mobile number → OTP via `send_otp.php`/`verify_otp.php` → `signInWithCustomToken`, register name on first login) + Profile
4. Location detection + client-side outlet matching
5. Home + Menu + Product listing (seed sample data directly into RTDB for dev)
6. Product customization + dynamic pricing
7. Cart (local + RTDB sync, offline persistence on)
8. Coupons logic
9. Checkout + Address management
10. Payment abstraction: `PaymentGateway` interface + `MockPaymentGateway` (or "Coming soon" UI) for COD + placeholder online-payment flow — real gateway to be wired in later once client decides
11. Order placement (client-computed price + multi-path RTDB write to `orders`/`userOrders`/`outletOrders`)
12. Order tracking (status stepper, live via RTDB `.onValue`)
13. Order history, reorder, cancel
14. Wishlist
15. Reviews & ratings
16. Loyalty points (customer-facing: balance, history, redeem-at-checkout UI)
17. Customer support (WhatsApp/call/form)
18. RTDB security rules (§8) — lock down before considering Phase 1 "done"
19. Full QA pass on every customer flow end-to-end

### Phase 2 — Admin Panel (start only after Phase 1 is complete)
20. Rest of PHP backend skeleton (auth-related pieces already built in step 0 above): `auth_middleware.php`, `FcmClient.php`, `ImgbbClient.php`, `PdfInvoice.php`, `config.php` additions
21. `api/upload_image.php` (ImgBB)
22. Flutter Web admin shell + auth (admin role check) + direct-RTDB CRUD screens (products, categories, coupons, outlets, customers)
23. `api/update_order_status.php` + FCM push wiring + order management screen
24. `api/credit_loyalty_points.php` + `cron/expire_loyalty_points.php` + loyalty config screen
25. `api/send_broadcast_notification.php` + notifications screen
26. `api/payment_webhook.php` (Razorpay/Cashfree webhook receiver)
27. `api/generate_invoice.php`
28. `api/reports.php` + dashboard/reports screens
29. Deploy admin panel to Firebase Hosting; deploy PHP backend to chosen hosting
30. Legal pages + Play Store deployment prep for the customer app
31. Final end-to-end QA across both phases together

---

*End of specification. Agent should ask for clarification only if a rule above is ambiguous for a specific edge case; otherwise proceed to build using the defaults stated here — Phase 1 completely before Phase 2.*
