# GTA (Global Textile Axis) — Platform-Wide Flow & Integration Review

**Date:** 2026-10-03
**Scope:** Full read-only code review of the Flutter codebase (`lib/src/...`) that compiles to Android, iOS, and Web — i.e. the "app" and the "website" are the same codebase. Covers buyer flows, seller flows, auth/session, real-time chat, push notifications, payments, uploads, maps, and Flutter-Web readiness.
**Method:** Five focused deep-reviews (auth/routing, buyer, seller, chat/notifications/chatbot, payments/infra/web) run in parallel against the current `main` branch. No code was changed as part of this review.

> This document is a findings report only. Nothing in the repository was modified.

---

## 0. Executive Summary

The app is functionally broad (browsing, quoting/negotiation, ordering, payments, chat, complaints) but has several issues severe enough to block real production usage, plus a handful of systemic patterns that repeat across both buyer and seller codebases (meaning a fix in the shared layer fixes many symptoms at once).

**The five most severe, highest-confidence issues, in order:**

1. **Payments are non-functional in production.** Cashfree is hardcoded to `CFEnvironment.SANDBOX` with no build-flavor switch (`buyer_quote_details_screen.dart:1330`). No real payment can ever succeed once shipped.
2. **Buyers cannot negotiate quotes.** All accept/counter/reject logic for a seller's counter-offer exists only in the seller codebase; the buyer side is read-only. A buyer who receives a counter-offer has no in-app way to respond to it.
3. **No authentication guard exists anywhere in the client.** `router.dart` has no `redirect:` callback — every screen (seller dashboard, earnings, bank details, buyer orders, etc.) is reachable by direct URL on the web build with no login check, and no client-side role check stops a buyer from loading seller-only screens or vice versa.
4. **The chat system has no authentication at all**, by design — the client asserts its own `userId`/`userType` on both the socket and REST API, and the codebase literally comments "no auth" next to the chat server config. This is a direct IDOR-class risk to private buyer/seller conversations.
5. **Session/token expiry is never detected anywhere.** `api.dart` treats every HTTP status code identically; there is no 401 handling, so once a session expires, every screen in the app shows a permanent, misleading "something went wrong" error with no path back to login.

Beyond these, there are two **systemic code patterns** repeated independently across unrelated features (found separately by the buyer and seller reviews, which increases confidence they're real and worth a one-time architectural fix — see §6):
- **"Silent failure + unconditional success UI"**: several cancel/update actions (quote cancel, order cancel, order status update) ignore the failure branch of the `Either<Failure, T>` result and show a success message / pop the screen regardless of whether the backend call actually succeeded.
- **"Mutate and forget to invalidate"**: creating a quote or placing an order doesn't invalidate the corresponding list provider, so already-opened tabs show stale data until a manual pull-to-refresh (caused by the home screen's `IndexedStack` keeping tabs alive).

Also notable: the **"Rate the App" screen is a non-functional mock** (fake success animation, no backend call, no store redirect), and the **"Texax Assistant" chatbot is not an AI chatbot** — it's the human complaint/support-ticket system with a robot icon and a misleading "Always active" label.

**Severity counts across all five areas:** 13 Critical · 19 High · 24 Medium · 16 Low (approximate; some findings span categories — see each section for exact detail).

---

## 1. Auth, Session & Routing

**Files reviewed:** `lib/src/utils/router.dart`, `lib/src/commons/views/splashscreen.dart`, `lib/src/features/common_features/auth/**`, `lib/src/commons/controller/shared_prefs_controller.dart`, `lib/src/commons/repository/shared_prefs_repo.dart`, `lib/src/commons/providers/common_providers.dart`, `lib/src/core/token_aware_notifier.dart`, `lib/src/core/api.dart`, `lib/src/core/failure.dart`, `lib/src/services/fcm_service.dart`, `lib/firebase_options.dart`.

### Critical

| # | Issue | Location |
|---|---|---|
| A1 | **No route guard exists anywhere** — `GoRouter` has no `redirect:` callback. Auth gating is only a one-time check in `Splashscreen.initState()` which is bypassed by any direct navigation, deep link, bookmark, or page refresh on the web build. Every screen (seller dashboard/earnings/bank details, buyer orders/wishlist/addresses, product management, chat, complaints) is reachable with no valid session. | `lib/src/utils/router.dart` (whole file) |
| A2 | **No buyer/seller role check anywhere client-side.** `grep` for `userTypeProvider`/`USER_TYPE` in buyer or seller feature code returns zero matches. Combined with A1, a buyer (or a stale buyer token) can fully navigate the seller shell. | `lib/src/features/{buyer,seller}/**` |
| A3 | **Token expiry is never detected.** Every method in `api.dart` returns `Right(response)` for any status code (200/401/403/500 all treated the same); no code anywhere checks for 401. A user whose session expires mid-session sees generic, permanent "something went wrong" errors with no redirect to login and no state cleanup. | `lib/src/core/api.dart:66-281` |
| A4 | **Literal `Cookie: token=null` sent on every unauthenticated request** (string interpolation of a null `_authToken`), e.g. on login/OTP endpoints. | `lib/src/core/api.dart:73,110,146,209,248` |

### High

| # | Issue | Location |
|---|---|---|
| A5 | Four routes **crash on page refresh / shared link on Flutter Web** because they force-cast in-memory `state.extra` with no null handling (`extra` is never encoded into the URL, so it's always null on a hard refresh/new tab). | `router.dart:229` (seller order details), `:246-247` (edit product), `:134-137` & `:210-213` (complaint details) |
| A6 | `logout()` never calls `FirebaseAuth.instance.signOut()` — a Google/Apple-authenticated Firebase session stays alive after "Logout." | `auth_controller.dart:291-297` |
| A7 | FCM push token is **never unregistered on logout** — no unregister endpoint exists at all, only upload endpoints. On a shared device, the previous user may keep receiving notifications. | `auth_controller.dart:291-297`, `lib/src/res/endpoints.dart:156-158` |
| A8 | `logout()` never invalidates the ~20 user-scoped Riverpod providers (`_resetUserScopedProviders()` is only called post-login, by design, to avoid a stale-watcher race) — a real tradeoff today, but a landmine for any future login path that forgets to call it, or any widget that reads a user-scoped provider while on the Login screen. | `auth_controller.dart:291-297` vs `:315-341` |

### Medium / Low

- No request timeout anywhere in the HTTP layer (`api.dart`) — a hung request spins forever.
- Hardcoded `+91` country-code assumption in `auth_repository.dart:24,52` and `otp_screen.dart:214` — double-prefixes if international numbers are ever allowed.
- `AuthState.copyWith` can't clear nullable fields back to null — latent trap for future maintainers.
- `isAuthenticatedProvider` re-uploads the FCM token unconditionally on every cold start (minor inefficiency).
- `SharedPrefsRepo` logs the **raw token value in plaintext** when `AppConfig.devMode` is true (no redaction, unlike `api.dart`'s careful `_redactForLog`).
- `SharedPrefsRepo.clear()` doesn't await `prefs.clear()` itself and wipes *all* prefs (not just auth-scoped keys) on logout.

### Direct answers to the review brief's standing questions

- **Reachable without auth?** Yes — all screens (A1).
- **Token expiry mid-session?** Nothing happens automatically; generic errors forever (A3).
- **Does logout clear everything?** Partially — shared prefs: yes; Riverpod providers: no (A8); FCM token: no (A7); Firebase Auth session: no (A6); chat socket: no (see §3, finding C6).
- **Role check enforced?** No, anywhere (A2).
- **Hardcoded secrets?** None found; the Google `serverClientId` and Firebase web API key are public-by-design client identifiers, not secrets — but both are hardcoded rather than environment/flavor-driven.

### Things confirmed *not* broken
- Firebase Web config (`lib/firebase_options.dart`) does include a proper `web` block — Firebase Auth is correctly wired for the Flutter Web build.
- `google_sign_in: ^7.2.0`'s new API shape (`GoogleSignIn.instance.initialize/authenticate`) is used correctly for mobile (web has a separate issue — see §5, finding P17).

---

## 2. Buyer-Side Flows

**Files reviewed:** all of `lib/src/features/buyer/**`, `lib/src/commons/widgets/product_attribute_rows.dart`, buyer-related models.

### Quotation / Negotiation (most severe group)

| # | Issue | Location |
|---|---|---|
| B1 | **Critical — Buyers have no negotiation UI.** Accept/counter/reject actions for a seller's counter-offer exist only under `lib/src/features/seller/quotes/**`. The buyer's quote-details screen shows negotiation status as a read-only timeline with no action available. | `buyer_quote_details_screen.dart`, entire `buyer/quotes/` and `buyer/quotation/` trees |
| B2 | **Critical — Cashfree hardcoded to `CFEnvironment.SANDBOX`**, unconditionally, no env/flavor branch. Confirmed independently from the payments-focused review (see §5, P1). | `buyer_quote_details_screen.dart:~1329-1333` |
| B3 | **High — Silent failure on quote cancellation.** `cancel()`'s failure branch does nothing; the UI pops the screen unconditionally regardless of actual outcome. Identical bug duplicated for orders (B11) and independently found on the seller side for quote-cancel and order-status-update (§4, S13/S16) — a systemic pattern, see §6. | `buyer_quote_controller.dart:135-138`, `buyer_quote_details_screen.dart:1153-1161` |
| B4 | **High — Stale quote list after submitting a new quote request.** Success path never invalidates `buyerQuotationsProvider`; the Quotations tab (kept alive via `IndexedStack`) won't show the new quote until a manual pull-to-refresh. | `request_quote_sheet.dart:241-249` |
| B5 | Medium — SnackBar is shown via the bottom sheet's own context *after* `Navigator.pop`, so it may never render on the underlying page. | `request_quote_sheet.dart:245-248` |
| B6 | Medium — Unsafe `as String` casts on the order-creation response (`orderNumber`, `orderId`, `paymentSessionId`, `cashfreeOrderId`) outside the try/catch — a missing key throws an uncaught `TypeError`, leaving a dead screen. | `buyer_quote_details_screen.dart:1320-1324` |
| B7 | Medium — Quote request silently substitutes `city` with `state` when the buyer's address has no city, corrupting delivery data sent to the seller with no warning. | `request_quote_sheet.dart:221` |
| B8 | Low — Buyer code directly imports a seller-feature widget (`QuoteItemCard`), blurring the buyer/seller architectural boundary; a seller-side change can silently break the buyer screen. | `buyer_quote_details_screen.dart:15` |
| B9 | Low — The discount badge is taken from the *first* variant row, not the cheapest one, so the displayed "% off" can be paired with a price it doesn't apply to. | `buyer_product_details_screen.dart:308-318` |

### Orders / Payment

| # | Issue | Location |
|---|---|---|
| B10 | **Critical — Dead end for failed payments.** No "Retry Payment" action exists anywhere; once `payment.status == 'failed'`, the order can neither be retried nor cancelled (cancel button only shows for `'pending'`). | `buyer_order_details_screen.dart:80-81` and whole file |
| B11 | High — Same silent-cancel-failure pattern as B3, duplicated for orders. | `buyer_order_controller.dart:134-137`, `buyer_order_details_screen.dart:1412-1420` |
| B12 | High — Order list isn't invalidated after a successful payment/order creation; same `IndexedStack` staleness issue as B4. | `buyer_quote_details_screen.dart:1249-1256` |
| B13 | Medium — `city` can end up null/empty on an order's address via the same root cause as B7, rendering silently (no crash, but an incomplete address shown). | `buyer_order_details_screen.dart:936-1013`, `order_model.dart` |

### Browsing / Product Details

| # | Issue | Location |
|---|---|---|
| B14 | Medium — **No save/wishlist control on the Product Details screen** at all (the share icon is also dead — see B16), even though the home grid's product cards have a fully working heart toggle. | `buyer_product_details_screen.dart` |
| B15 | **High — Wishlist is local-only, unscoped by user.** Persisted to a single fixed SharedPreferences key (`saved_products_v1`) with no backend sync and no per-user namespacing. **A second buyer logging into the same device immediately sees (and can overwrite) the first buyer's wishlist.** It also doesn't survive reinstall or sync across devices. | `saved_products_controller.dart:78,83-103` |
| B16 | Low — Dead "Share" button and two dead "See All" buttons (`onPressed: () {}`). | `buyer_product_details_screen.dart:98`, `home_tabs.dart:159,196` |
| B17 | Low — Image-list ordering logic is duplicated between the model and the view instead of reusing the model's getter — drift risk. | `buyer_product_details_model.dart:146-157` vs `buyer_product_details_screen.dart:53-64` |

### Complaint

- Low — `setState` after dispose is possible in `_sendMessage()` (no `mounted` check on the final `setState`). `complaint_details_screen.dart:94`
- Low — Generic static error message shown on complaint submission failure instead of the real backend message, even though it's captured into state. `create_complaint_screen.dart:71-80`

### Profile / Address

| # | Issue | Location |
|---|---|---|
| B20 | **High — Every buyer address is saved with hardcoded `GeoLocation(coordinates: [0, 0])`** — no geocoding or device location is ever captured. Any backend feature relying on geolocation (delivery estimates, nearest-seller logic, map pins) is silently wrong for every address. | `add_address_screen.dart:62` |
| B21 | Medium — Address form validation only checks "non-empty," with no digit/length checks on phone/pincode, unlike the stricter validation already used in the quote-request form. | `add_address_screen.dart:286-291` vs `request_quote_sheet.dart:397-405` |
| B22 | Medium — Profile/address update failures discard the real backend error message everywhere in `profile_controller.dart` (`updateProfile`, `addAddress`, `removeAddress`, `markAddressPrimary`), so the UI can only ever show a generic failure string. | `profile_controller.dart:74-84,127-165` |
| B23 | Low — Email field on profile edit has no format validation (accepts `"not-an-email"`), unlike the quote-request form which does regex-validate email. | `edit_profile_screen.dart:451-456` |

---

## 3. Seller-Side Flows

**Files reviewed:** all of `lib/src/features/seller/**`, `lib/src/models/product_model.dart`, `lib/src/utils/upload_utils.dart`, `test/color_picker_field_test.dart`.

### Cross-cutting

| # | Issue | Location |
|---|---|---|
| S1 | **Critical — `product_repository.dart` has unguarded `jsonDecode` calls with no try/catch** (every other seller repository wraps this). A non-JSON response (e.g. on session expiry, see A3) throws an uncaught exception instead of becoming a `Failure`. | `product_repository.dart` (`addProduct`, `getSellerProducts`, `getProductById`, `updateProduct`) |
| S2 | Low — Hex-color parsing logic is duplicated in 5+ places (`seller_product_details_screen.dart`, `seller_product_card.dart`, `order_item_card.dart`, `quote_ui_helpers.dart`) instead of all routing through the new `color_hex_utils.dart`, each with slightly different edge-case handling. | multiple |

### Product Management (highest-risk area — most recent changes)

| # | Issue | Location |
|---|---|---|
| S3 | **Critical — A single shared `Form` key spans all 3 steps of the Add/Edit Product `PageView`.** Because `PageView` eagerly builds the adjacent page within its cache extent, step 3's required Price/Stock fields are already mounted and registered with the form while the seller is still on step 2. Tapping "Next" on step 2 silently fails validation against step 3's still-empty fields, with **no error message shown anywhere** (the red error text renders off-screen) — this is the default path for a brand-new, non-variant product, not an edge case. **This can block the core "add a product" flow entirely.** | `add_product_screen.dart:409-460,153-176`, `edit_product_screen.dart:416-466` |
| S4 | High — Price/Stock fields only validate non-empty, not numeric; a typo (e.g. "1O0") silently submits as price/stock `0` with no warning — a live, effectively free listing. | `add_product_screen.dart:300-301,331-332,205-208`, `edit_product_screen.dart`, `add_variant_sheet.dart:205-210` |
| S5 | High — Deleting a product pops the screen unconditionally even when the delete call failed; the "deleted" product is still present on return to the list with no error shown. | `seller_product_details_screen.dart:2066-2069` |
| S6 | Medium — "Quick Stock Edit" only invalidates the product-details provider, not the product list/dashboard — stale stock shown in the list until manual refresh. | `seller_product_details_screen.dart:1899-1906` |
| S7 | Medium — Multi-color products store the literal string `'Multi Color'` as `variantColorCode` instead of using the existing `isMultiColor` boolean — a fragile magic-string sentinel. | `add_product_screen.dart:295`, `edit_product_screen.dart:312` |
| S8 | Medium — Color field defaults silently to Black (`#000000`) with no forced explicit choice, indistinguishable from a deliberate selection. | `add_product_screen.dart:51,716`, `edit_product_screen.dart:49,720` |
| S9 | Medium — Inconsistent "Size is required" behavior between single-variant mode (`isRequired:false`) and `AddVariantSheet` (required by default) — can block adding a variant for color-only (non-sized) products. | `add_product_screen.dart:862-867` vs `add_variant_sheet.dart:123-128` |
| S10 | Low — No duplicate-variant (same color+size) guard — two identical variant rows with different prices can be added silently. | product/variant management screens |
| S11 | Low/Medium — Image upload has no client-side size/type validation, no per-file progress, and orphans already-uploaded images remotely if a later image in the batch fails. | `upload_utils.dart:27-70,76-112` |
| S12 | Low — The new `color_picker_field_test.dart` only exercises named `GtaColors` swatches; it never tests the "custom hex" path or `color_hex_utils.dart` directly, so a regression there wouldn't be caught. | `test/color_picker_field_test.dart` |

### Quotes

| # | Issue | Location |
|---|---|---|
| S13 | **Critical — Cancelling a quotation always shows "Quotation cancelled" even when the cancel failed** (empty failure branch; UI unconditionally pops and shows success). Same bug class as B3/B11 and S16 below — a systemic pattern (§6). Notably, `finalize()`/`startNegotiation()` in the *same controller* correctly handle this — `cancel()` is the inconsistent outlier. | `seller_quote_controller.dart:145-151`, `seller_quote_details_screen.dart:228-240` |
| S14 | Medium — Seller counter-price matching for color-only (no-size) products can fail to match by `variantId` and silently fall back to showing the buyer's original price labeled as "quoted" instead of the seller's actual counter. | `quote_item_card.dart:28-42`, `seller_quote_details_screen.dart:317-329` |
| S15 | Low — Cancel-reason validation doesn't trim whitespace; a whitespace-only reason is accepted. | `seller_quote_details_screen.dart:230` |

### Orders

| # | Issue | Location |
|---|---|---|
| S16 | **Critical — Updating order status always reports success even on failure** — identical bug class to S13. A seller can be shown "Status updated to Shipped" and tell the buyer accordingly when nothing changed server-side. | `seller_order_controller.dart:148-154`, `seller_order_details_screen.dart:478-503` |
| S17 | Low — An `_isUpdating` loading flag is effectively dead code; the bottom sheet it's meant to gate is already popped before the flag could matter. | `seller_order_details_screen.dart:31,481,487` |

### Dashboard

| # | Issue | Location |
|---|---|---|
| S19 | **High — The dashboard hero banner shows a permanently hardcoded fake figure, "₹45,230 today's revenue,"** never bound to any provider, directly contradicting the real revenue numbers shown correctly a few widgets below it via `sellerOrderStatsProvider`. Every seller sees this same fake number regardless of actual sales. | `seller_dashboard_screen.dart:1004-1011` |
| S20 | Low — Stale "Texax" watermark branding instead of "GTA" — likely leftover from a prior app name. | `seller_dashboard_screen.dart:924` |

### Earnings & Complaint
No functional bugs found — these are the most defensively written areas of the seller codebase (proper loading/error/empty states, correct `TokenAwareNotifier` usage in complaints, status-code checks before trusting response bodies). Earnings has no payout/withdrawal action (only stats + bank-details setup) — flagged as a completeness question, not a bug.

### Profile

- Medium — `SellerProfileController.updateProfile()` discards the real backend error message (unlike its siblings `addBankDetails`/`submitVerificationDocuments`, which correctly surface it), so update failures always show a generic message regardless of cause. `seller_profile_controller.dart:61-81`

---

## 4. Chat, Push Notifications & Chatbot

**Files reviewed:** `lib/src/features/chat/**`, `lib/src/models/chat_message_model.dart`, `lib/src/services/fcm_service.dart`, `lib/src/features/common_features/chatbot/views/chatbot_screen.dart`.

### Chat / Socket

| # | Issue | Location |
|---|---|---|
| C1 | **Critical — No authentication on the chat socket or chat REST API.** The client asserts its own `userId`/`userType` on `join_chat` with no token; REST calls (`getConversations`, `getMessages`, `getUploadUrl`, `deleteMessage`) send **no auth header at all**. The codebase's own `base.dart` comment literally says "Chat server — port 5002, no auth." This means any client can potentially read/write another user's private conversation by supplying a different `userId`. | `chat_socket_service.dart:19-46`, `chat_repository.dart:15-129`, `lib/src/res/base.dart:9-14` |
| C2 | High — The shared socket singleton's generic `.off(event)` calls in `dispose()` remove listeners for *all* instances of that event, not just the closing screen's. If two chat screens are ever simultaneously in the nav stack, closing one silently kills the other's live message/typing/block-state updates for the rest of its life. | `chat_detail_screen.dart:644-664` |
| C3 | High — No optimistic UI, no delivery ack, and no offline check for outgoing text messages (unlike file uploads, which do have a pending/retry state). A message sent while disconnected can be **silently and permanently lost** with no trace. | `chat_detail_screen.dart:384-399`, `chat_socket_service.dart:62-78` |
| C4 | High — No resync-on-reconnect. Messages sent by the other party during a disconnect window are never backfilled into an already-open chat screen — the only way to see them is to leave and reopen the screen. | `chat_detail_screen.dart` (listener setup) |
| C5 | Medium — No duplicate-message guard on receive — a future resync fix (or any at-least-once redelivery) would currently produce visibly duplicated bubbles. | `chat_detail_screen.dart:215-241` |
| C6 | Medium — The chat socket is never disconnected on logout (it's a `keepAlive()` provider, absent from the logout invalidation list) — ties to A8. | `auth_controller.dart:291-297`, `chat_socket_service.dart:6-11` |

### Presence

- High — `UserPresenceNotifier.seed()`'s "first write wins forever" guard means a fresh, authoritative REST reload of presence can never correct a stale "Online" status once any value has been seeded for that user — can show a user as online indefinitely after they've actually gone offline. `user_presence_provider.dart:22-28`
- Medium — Two divergent, uncoordinated presence truth sources: a local 5-minute timeout in the chat-detail screen vs. a global provider with no expiry at all — can show contradictory online/offline status for the same person on two different screens. `chat_detail_screen.dart:272-285` vs `user_presence_provider.dart:9-29`
- Low — Presence map isn't cleared on logout, ties to A8/C6.

### Push Notifications (FCM)

| # | Issue | Location |
|---|---|---|
| C10 | **Critical — Tapping a notification does nothing.** Neither `FirebaseMessaging.onMessageOpenedApp`, `getInitialMessage()`, nor a local-notification tap handler is wired up anywhere in the codebase. A push for "new message" or an order/quote status update never deep-links to the relevant screen. | `fcm_service.dart` (entire file) |
| C11 | High — Foreground chat push notifications aren't suppressed when that exact chat is already open, causing a duplicate/redundant notification for a message the user can already see arriving live via the socket. | `fcm_service.dart:94-125` |
| C12 | Medium — The `requestPermission()` result (`authorizationStatus`) is discarded — if an iOS user denies notifications, the app never detects it and never offers a way to re-enable them in-app. | `fcm_service.dart:38-39` |
| C13 | Medium — No `default_notification_channel_id` meta-data in the Android manifest, so background/terminated notifications may land in a lower-importance default channel instead of the app's custom high-importance channel, depending on backend payload. | `AndroidManifest.xml` |

### Chatbot

| # | Issue | Location |
|---|---|---|
| C16 | **High (misleading UX) — "Texax Assistant" is not an AI chatbot.** It's the same human complaint/support-ticket thread (`getChatbotThread`/`sendBuyerComplaintMessage` — identical endpoints to the real complaint feature), displayed with a robot icon and a green "Always active" label implying instant automated replies. In reality, replies come from a human Admin on their own schedule — potentially hours or days later — with no indication in the UI that no bot is actually responding. | `chatbot_screen.dart:35-56,123-153`, `complaint_repository.dart:127-146` |
| C17 | Medium — If the initial thread fetch fails, the screen is stuck on a permanent loading spinner with no retry affordance. | `chatbot_screen.dart:35-56,157-158` |

### Cross-cutting (chat)
- Three separate, incompatible `Attachment` model shapes exist across `attachment_model.dart`, `complaint_model.dart`, and `chat_message_model.dart` — pure duplication risk, not an active bug.
- `senderType`/`receiverType`/`otherUserType` parsing in `chat_message_model.dart` is less defensive (`json['x'] ?? ''`, no `.toString()`) than the rest of the parser — would throw if the backend ever returns a non-string value.

---

## 5. Payments, Uploads, Maps/Location, Web Readiness, App Rating

**Files reviewed:** Cashfree integration in `buyer_quote_details_screen.dart`, `lib/src/utils/upload_utils.dart`, `lib/src/commons/repository/storage_repository.dart`, `lib/src/features/chat/repository/chat_repository.dart` (secondary upload path), `web/index.html`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`, `lib/main.dart`, `lib/src/features/buyer/profile/views/buyer_rate_app_screen.dart`, Maps/location screens under `seller/profile/`.

### Payments (Cashfree)

| # | Issue | Location |
|---|---|---|
| P1 | **Critical — Payment environment hardcoded to `CFEnvironment.SANDBOX`, globally, with no release/flavor switch** (`AppConfig.devMode` isn't even consulted). Every shipped build routes real buyer payments to Cashfree's sandbox. (Confirmed independently by both the payments review and the buyer-flow review — see B2.) | `buyer_quote_details_screen.dart:1330` |
| P2 | High — No app-lifecycle/dispose handling around an in-flight payment, and no "Resume/Retry Payment" action exists anywhere (ties directly to B10) — an interrupted payment (backgrounded app, OS-killed activity) leaves the order stuck in `pending` forever with no in-app recovery path short of cancelling and starting over. | `buyer_quote_details_screen.dart:1206-1352`, `buyer_order_details_screen.dart:80-81` |
| — | *Correctly implemented:* payment confirmation is **not** trusted client-side alone — the success callback triggers a backend `verifyOrderPayment` call, and the app only proceeds if the backend explicitly confirms `PAID`. Good practice, not a finding. | `buyer_order_repository.dart:112-129` |
| P4 | Low — `verifyOrderPayment` breaks the repository's own `Either` contract by returning `Right(data)` unconditionally regardless of the `success` field (works today only because the one caller happens to re-check it itself). | `buyer_order_repository.dart:119-123` |

### File/Image Upload

| # | Issue | Location |
|---|---|---|
| P5 | High — The main upload path always sends `Content-Type: application/octet-stream` regardless of the actual file type. If the backend's signed upload URL was generated with a specific content type baked into its signature, uploads can fail outright; even if they succeed, stored images may be served as a forced download instead of rendering inline in browsers/the web build. | `upload_utils.dart:44-47`, `storage_repository.dart:49`, `api.dart:176-200` |
| P6 | Medium — No client-side file-size limit anywhere in the upload path (images or chat documents) — a large file is read fully into memory and uploaded with no size gate, progress, or cancel option. | `upload_utils.dart:30`, various picker call sites |
| P7 | Medium — No upload progress indication; multi-image (variant gallery) uploads run strictly sequentially, and a failure partway through leaves already-uploaded images orphaned in storage. | `upload_utils.dart:91-110` |
| P8 | Medium — The chat attachment upload path (`chat_repository.dart`) bypasses the shared `API` client entirely, issuing raw `http` calls with **no auth header** at all — compounds the chat-auth gap in C1 and is a glaring inconsistency with the rest of the app's auth model. | `chat_repository.dart:1-10,82-129` |

### Maps / Location

| # | Issue | Location |
|---|---|---|
| P10 | **Critical — `web/index.html` has no Google Maps JavaScript API script tag at all.** `google_maps_flutter` requires this on web; without it, the seller's business-address map picker (onboarding/profile) will fail to render or stay blank on the website build. | `web/index.html` |
| P11 | High — The same Google Maps API key is hardcoded and committed identically for both Android and iOS, with no separate web-restricted key existing at all; `usesCleartextTraffic="true"` is also set in the Android manifest alongside an app that sends its session as a cookie header — a related credential-interception surface if any endpoint is ever reached over plain HTTP. | `AndroidManifest.xml:15-16`, `AppDelegate.swift:11` |
| P12 | Medium — `Geolocator.getCurrentPosition()` in the main map picker has no timeout, so "use current location" can hang indefinitely if GPS can't get a fix; a sibling screen already does this correctly (last-known-position fallback + 8s timeout) and just needs to be copied over. | `seller_map_picker_screen.dart:120` vs `seller_business_address_screen.dart:376-381` |
| P13 | Medium — `deniedForever` location permission gives no recovery path (no `openAppSettings()` call) — the user is stuck re-seeing a snackbar forever once they've denied-and-don't-ask-again. | `seller_map_picker_screen.dart:98-108`, `seller_business_address_screen.dart:368-371` |

### Flutter Web Readiness

The project is a single codebase that must serve as "the website," but web-specific branching is almost entirely absent (`kIsWeb` is used in only one feature file, for Apple Sign-In visibility). Concretely:

| # | Issue | Location |
|---|---|---|
| P15 | **Critical — Unconditional, unguarded `flutter_local_notifications` initialization in `main()` can crash the web build on startup.** `flutter_local_notifications` has no web implementation; the call isn't wrapped in `kIsWeb` or try/catch. | `lib/main.dart:9-12`, `fcm_service.dart:32-74,89-91` |
| P16 | **Critical — The entire payment flow is unusable on web.** `flutter_cashfree_pg_sdk` has no Flutter-Web target at all, and the checkout call path has no `kIsWeb` guard or alternative web checkout. Buyers on the website cannot complete payment at all. | `buyer_quote_details_screen.dart:1340` |
| P17 | High — Google Sign-In's web configuration is incomplete (missing a web `clientId`/meta tag), and the imperative `authenticate()` call pattern used is commonly blocked by browser popup rules on web without a dedicated web sign-in widget — Google Sign-In on the website likely doesn't work. | `auth_controller.dart:147-155`, `web/index.html` |
| P19 | Low — No Firebase web push config / service worker (`firebase-messaging-sw.js`) exists either, so web push won't function even once P15 is fixed defensively. | `web/index.html` |

### App Rating

| # | Issue | Location |
|---|---|---|
| P20 | **Critical — The "Rate the App" feature does nothing.** Tapping submit only sets a local `_submitted` flag and plays a fake "Thank you" animation — it never sends the rating/feedback anywhere (no backend call, no imports beyond UI/formatting) and never deep-links to the Play Store/App Store. Users are misled into thinking their feedback was captured. | `buyer_rate_app_screen.dart:33-37` (whole 312-line file has no network/provider dependency) |
| P21 | Medium — The feature exists only for buyers, not sellers, and is never triggered proactively (e.g. after N completed orders) — only reachable by manually navigating to it from the profile tab. | `buyer_profile_tab.dart:163` |

### Dependency Changes
At review time, `git diff` on `pubspec.yaml`/`pubspec.lock` was clean; the most recent historical dependency change (commit `98f4c90`) was a routine version bump plus minor/patch transitive dependency bumps — reasonable and low-risk, no concerns found.

---

## 6. Systemic Patterns (fix once, fix everywhere)

These were each found **independently by more than one reviewer**, in unrelated parts of the codebase, which is strong evidence they are structural rather than one-off mistakes:

1. **No 401 / session-expiry handling anywhere in `lib/src/core/api.dart`.** Found by the auth review (A3), the buyer review (baseline note underlying nearly every buyer finding), and the seller review (S1). A single fix — detect 401 centrally, clear the token, and redirect to login — would immediately improve the auth-failure UX of every screen in the app at once, instead of each screen separately showing a misleading generic error forever.

2. **"Silent failure + unconditional success UI" on cancel/update actions.** The exact same shape of bug appears four times, in four unrelated controllers, always by the same mechanism: `result.fold((failure) {}, (_) => refresh())` with an empty failure branch, followed by a UI layer that pops the screen / shows a success SnackBar without checking the actual result:
   - Buyer quote cancel (B3), buyer order cancel (B11), seller quote cancel (S13), seller order status update (S16).
   - Notably, in both the buyer-quote and seller-quote controllers, *sibling methods in the same class* (e.g. `finalize()`/`startNegotiation()`) already do this correctly by returning `Future<String?>` and branching on it — the fix pattern already exists in the codebase, it just wasn't applied consistently to `cancel()`/`updateStatus()`.

3. **"Mutate and forget to invalidate the list provider," combined with the home screen's `IndexedStack` keeping tabs alive.** Creating a quote (B4) and placing an order (B12) both fail to invalidate their respective list providers, so an already-visited tab shows stale data until a manual pull-to-refresh. A shared "on successful mutation, invalidate X" helper would close this class of bug everywhere at once.

4. **Repository failure messages are frequently captured correctly at the repository layer (`Either<Failure, T>`) and then discarded at the controller/view layer**, replaced with a generic static string. Found in buyer profile/address updates (B22), buyer complaint submission, and seller profile updates — again, several controllers in the same codebase already do this correctly (return `Future<String?>` with the real message), it's just inconsistently applied.

5. **No `kIsWeb` branching for mobile-only plugins**, despite this codebase being the website. Payments (P16), push/local-notifications (P15), Google Sign-In (P17), and Maps (P10) are all affected by variations of the same root cause: the app was evidently built mobile-first and web support was never systematically retrofitted.

---

## 7. Suggested Fix Priority

If addressing in order of risk-to-the-business:

1. **Before any production payment traffic:** fix P1 (sandbox hardcode) and decide/implement a web checkout strategy (P16) or explicitly block checkout on web until one exists.
2. **Before relying on the web build as "the website" at all:** fix P15 (startup crash risk), P10/P11 (maps), P17 (Google Sign-In), and A5 (crash-on-refresh routes).
3. **Security hardening (needs backend coordination, can't be fully fixed client-side):** C1 (chat has no auth), A1/A2 (no route/role guard), A3 (no 401 handling).
4. **Core transactional correctness:** B1 (buyer can't negotiate — likely the single biggest functional gap for the core B2B quoting workflow), S3 (product creation can get stuck on step 2), the four silent-failure bugs in §6.2, B10/B20 (payment dead-end, fake geolocation on every address).
5. **Trust/credibility:** P20 (fake rate-app flow), S19 (fake dashboard revenue number), C16 (mislabeled chatbot).
6. **Polish:** remaining Medium/Low items per section above (stale lists, validation gaps, duplicated parsing logic, dead buttons).

---

*End of report. No files other than this one were created or modified during this review.*
