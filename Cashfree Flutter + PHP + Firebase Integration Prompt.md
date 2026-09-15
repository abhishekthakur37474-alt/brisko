# Cashfree Payment Gateway Integration — Flutter + PHP + Firebase

I have an existing Flutter application with a PHP backend and Firebase Authentication + Firebase Realtime Database.

I want to integrate **Cashfree Payment Gateway** using the official Cashfree Flutter SDK.

## Important Security Rules

- Cashfree Client Secret / Secret Key must NEVER be stored inside Flutter.
- Cashfree Client Secret must NEVER be stored in Firebase.
- Cashfree Secret Key must only exist on the PHP backend/server `.env`.
- Do not hardcode credentials anywhere in the source code.
- Do not expose the Secret Key through any API response.
- Payment success must NOT be trusted only from the Flutter callback.
- The PHP backend must verify the Cashfree order/payment status server-side before marking an order as paid.
- Use Cashfree Sandbox/Test environment initially.

## Cashfree Credentials

The credentials have already been provided by the client.

Configure them through the PHP `.env` file:

```env
CASHFREE_CLIENT_ID=CLIENT_ID_HERE
CASHFREE_CLIENT_SECRET=CLIENT_SECRET_HERE
CASHFREE_ENVIRONMENT=SANDBOX
CASHFREE_API_VERSION=2025-01-01
```

Do NOT put the actual Secret Key into Flutter code.

If the project already has a `.env` file, extend the existing `.env` instead of creating an unnecessary second environment file.

---

# Architecture

Use this flow:

Flutter App
→ PHP Backend
→ Cashfree Create Order API
→ PHP returns order_id + payment_session_id
→ Flutter opens Cashfree Checkout
→ User completes payment
→ Flutter receives Cashfree callback
→ Flutter asks PHP to verify payment
→ PHP verifies order/payment with Cashfree
→ PHP updates Firebase Realtime Database
→ Flutter displays final payment status

Do not allow Flutter to directly call Cashfree's protected Create Order API.

---

# STEP 1 — Inspect Existing Project

Before changing anything:

1. Inspect the existing Flutter project.
2. Inspect the existing PHP backend.
3. Inspect the existing `.env`.
4. Inspect existing Firebase configuration.
5. Inspect the current Firebase Realtime Database structure.
6. Identify the existing user authentication flow.
7. Identify how the currently logged-in Firebase user's UID is obtained.
8. Do not unnecessarily modify existing functionality.

Reuse the existing architecture wherever possible.

---

# STEP 2 — Flutter Cashfree SDK

Add the official Cashfree Flutter SDK dependency compatible with the current project.

Use the official Cashfree Flutter integration documentation as the source of truth:

https://www.cashfree.com/docs/payments/online/mobile/flutter

Do not use outdated or unofficial SDK implementation patterns.

Configure Android/iOS requirements exactly according to the current Cashfree documentation.

---

# STEP 3 — PHP Cashfree Configuration

Read Cashfree credentials from `.env`.

Expected variables:

```env
CASHFREE_CLIENT_ID=
CASHFREE_CLIENT_SECRET=
CASHFREE_ENVIRONMENT=SANDBOX
CASHFREE_API_VERSION=2025-01-01
```

Create a centralized Cashfree configuration/helper so that credentials and API configuration are not duplicated across PHP files.

The Cashfree API base URL must automatically depend on:

```text
SANDBOX
PRODUCTION
```

Do not hardcode production credentials.

---

# STEP 4 — Create Order API

Create a PHP endpoint such as:

```text
POST /api/cashfree/create-order.php
```

The Flutter app will call this endpoint when the user clicks the Pay button.

Request example:

```json
{
  "amount": 100,
  "currency": "INR"
}
```

The endpoint should obtain the authenticated Firebase user's UID from the request/authentication mechanism already used by the project.

Do not blindly trust a user ID sent from Flutter.

Generate a unique merchant order ID on the server.

Example:

```text
CF_XXXXXXXXXXXX
```

Create the Cashfree order from PHP using the Cashfree API.

The PHP server should send the required headers, including:

```text
x-client-id
x-client-secret
x-api-version
Content-Type: application/json
```

The exact request body and API behavior must follow the current official Cashfree documentation.

The order should contain:

- order_id
- order_amount
- order_currency
- customer_details
- customer_id
- customer phone/email where available

Use the currently authenticated Firebase user's information where appropriate.

---

# STEP 5 — Create Firebase RTDB Order

Before or immediately after creating the Cashfree order, create an order record in Firebase Realtime Database.

Use a structure similar to:

```text
orders
  └── {cashfree_order_id}
       ├── orderId
       ├── userId
       ├── amount
       ├── currency
       ├── paymentStatus
       ├── cashfreeOrderStatus
       ├── paymentSessionId
       ├── createdAt
       ├── updatedAt
       └── paidAt
```

Initial status:

```text
paymentStatus = "PENDING"
```

Do not mark the order as PAID when it is created.

---

# STEP 6 — PHP Response to Flutter

After successful Cashfree order creation, return only the required information.

Example:

```json
{
  "success": true,
  "order_id": "CF_XXXXXXXX",
  "payment_session_id": "xxxxxxxxxxxxxxxx",
  "amount": 100,
  "currency": "INR"
}
```

Never return:

```text
CASHFREE_CLIENT_SECRET
```

or any other sensitive backend credential.

---

# STEP 7 — Flutter Payment Screen

Create/reuse the existing payment screen.

When the user taps:

```text
Pay ₹XXX
```

Flutter should:

1. Call PHP `create-order.php`.
2. Receive:
   - order_id
   - payment_session_id
3. Create the Cashfree session using the official Flutter SDK.
4. Open Cashfree Web Checkout.

Use the official SDK classes/API documented by Cashfree.

Do not create the Cashfree order directly from Flutter.

---

# STEP 8 — Cashfree Payment Callback

Implement the Cashfree Flutter callback.

The callback should only be treated as a signal that payment processing has completed/changed.

Do NOT immediately mark the order as PAID based only on:

```text
SUCCESS
```

or any client-side callback.

After the callback, call the PHP verification endpoint.

---

# STEP 9 — Payment Verification API

Create:

```text
GET /api/cashfree/verify-payment.php?order_id=CF_XXXXXXXX
```

The PHP backend must verify the order directly with Cashfree using the Secret Key.

Use the official Cashfree order/payment verification API documented here:

https://www.cashfree.com/docs/payments/online/mobile/flutter

The PHP server should retrieve the actual Cashfree order/payment status.

Only when Cashfree confirms the required successful status should the backend update Firebase:

```text
paymentStatus = "PAID"
```

Also save:

```text
cashfreeOrderStatus
paidAt
updatedAt
```

If payment is not successful, keep the appropriate status such as:

```text
PENDING
FAILED
USER_DROPPED
```

Do not incorrectly mark failed/pending transactions as paid.

---

# STEP 10 — Webhook

Also implement a Cashfree webhook endpoint:

```text
POST /api/cashfree/webhook.php
```

Example:

```text
https://YOUR_DOMAIN/api/cashfree/webhook.php
```

The webhook should be used as an additional server-side payment notification mechanism.

Implement proper webhook verification/signature validation according to the CURRENT Cashfree documentation.

Do not trust arbitrary webhook requests.

The webhook should update the corresponding Firebase RTDB order.

Important:

The webhook and verify-payment endpoint must be **idempotent**.

If the same successful event arrives multiple times, it must not create duplicate effects.

---

# STEP 11 — Firebase

Use the existing Firebase project.

Do not create a second Firebase project.

If the PHP backend currently has Firebase Admin SDK integration, reuse it.

If Firebase Admin SDK is not currently configured for PHP, implement the safest supported server-side method for writing to Firebase Realtime Database.

Flutter should not be responsible for changing:

```text
paymentStatus = PAID
```

The server should control payment status.

---

# STEP 12 — Firebase RTDB Security

Review the existing Firebase Realtime Database rules.

Users should be able to read only the order/payment information they are authorized to see.

Users must NOT be able to modify:

```text
paymentStatus
cashfreeOrderStatus
paidAt
cashfree payment information
```

from the client.

The backend/server must control these fields.

Do not weaken Firebase security rules just to make payment integration work.

---

# STEP 13 — Error Handling

Implement proper handling for:

### PHP

- Missing credentials
- Invalid request
- Invalid amount
- Invalid user
- Cashfree API error
- Network error
- Invalid order
- Duplicate order
- Firebase error
- Verification failure

### Flutter

Show user-friendly messages such as:

```text
Unable to start payment.
Please try again.
```

```text
Payment verification is in progress.
Please wait.
```

```text
Payment failed.
Please try again.
```

Do not display:

- Client Secret
- PHP stack traces
- API secrets
- internal server errors
- Cashfree authentication headers

to the user.

---

# STEP 14 — Amount Validation

Do not blindly trust the payment amount sent by Flutter.

If the app is purchasing a product/order:

```text
Flutter → product/order ID
PHP → retrieves actual price/order amount
PHP → creates Cashfree order using server-controlled amount
```

The server must determine the final payable amount.

Do not allow a malicious client to change:

```text
₹1000
```

into:

```text
₹1
```

by modifying the Flutter request.

---

# STEP 15 — Order ID Handling

Generate unique order IDs server-side.

Do not allow the client to arbitrarily choose an existing Cashfree order ID.

Store the mapping:

```text
Firebase UID
        ↓
Internal Order ID
        ↓
Cashfree Order ID
```

This allows the backend to verify that the Cashfree order belongs to the correct user/order.

---

# STEP 16 — Production Readiness

Initially use:

```env
CASHFREE_ENVIRONMENT=SANDBOX
```

After testing is complete, production configuration should use production credentials.

Do not mix Sandbox and Production credentials.

Production Secret Key must remain server-side only.

---

# STEP 17 — Files

Keep the implementation organized.

For example:

```text
PHP Backend

/api
  /cashfree
    create-order.php
    verify-payment.php
    webhook.php

/config
  cashfree.php

/services
  cashfree_service.php
  firebase_service.php
```

Use the project's existing structure if it already has an established architecture. Do not unnecessarily restructure the whole backend.

Flutter can have something similar to:

```text
lib/
  services/
    cashfree_service.dart
    payment_service.dart

  screens/
    payment_screen.dart
```

Again, reuse the existing project structure where appropriate.

---

# STEP 18 — Do Not Break Existing Features

This is an existing project.

Before implementation:

- Inspect current code.
- Reuse existing authentication.
- Reuse existing Firebase configuration.
- Reuse existing API service.
- Reuse existing `.env`.
- Do not remove unrelated features.
- Do not replace working code unnecessarily.
- Do not introduce unnecessary dependencies.

---

# STEP 19 — Testing Checklist

After implementation, test the complete Sandbox flow:

### Test 1

Flutter → PHP Create Order

Expected:

```text
200 OK
order_id received
payment_session_id received
```

### Test 2

Flutter opens Cashfree Checkout.

### Test 3

Complete a Sandbox payment.

### Test 4

Cashfree callback is received.

### Test 5

Flutter calls PHP verification endpoint.

### Test 6

PHP verifies payment directly with Cashfree.

### Test 7

Firebase RTDB changes:

```text
PENDING → PAID
```

only after successful server-side verification.

### Test 8

Test failed payment.

Expected:

```text
paymentStatus = FAILED
```

### Test 9

Test user closing/canceling payment.

Expected:

```text
paymentStatus != PAID
```

### Test 10

Test duplicate webhook/callback.

Expected:

No duplicate order/payment effect.

---

# Final Requirement

Do not just give me theoretical instructions.

Actually implement the integration in the existing project.

First inspect the existing project structure and existing authentication/Firebase/PHP setup.

Then make the minimum required code changes.

After implementation, provide:

1. Files created/modified
2. Exact `.env` variables required
3. PHP API endpoints
4. Flutter integration steps
5. Firebase RTDB structure
6. Firebase security-rule changes, if required
7. Cashfree Dashboard configuration required for webhook
8. Sandbox testing steps
9. Any Android/iOS configuration required
10. Any remaining credentials/configuration I need to provide

Use the **current official Cashfree Flutter documentation** as the source of truth and do not rely on outdated SDK/API examples.