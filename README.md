# BluePay - Offline Rural Payments

## 🏆 Hackathon Problem Statement
**Theme 3: FinTech & Financial Inclusion**  
**1. Last-Mile Banking Without Internet**

**Problem**  
Millions in rural areas face unreliable or no internet connectivity, limiting access to digital financial services.

**Challenge**  
Build a solution that enables financial transactions without continuous internet using:
- SMS / USSD
- Offline QR systems
- Bluetooth-based payments

**Goal**  
Make UPI-like payments accessible in low-connectivity environments and improve financial inclusion.

---

## 🚀 Project Overview

BluePay is a Flutter-based mobile payment application designed specifically for **OFFLINE rural payments**. It allows users to send and receive money even without internet connectivity, using a clever combination of:

- **Bluetooth + WiFi Direct (Google Nearby Connections)** for device-to-device local transfers.
- **Connectivity Radar (ShareIt Style)** to passively discover active nearby users and initiate fast P2P payments.
- **GSM SMS** as a relay channel to notify the banking backend when a transaction happens.
- **USSD-style dialpad** as a fallback input method (`*#amount#phone#`).
- **QR Code** for receiver identity sharing.

The app targets Android devices and is built to work in areas with poor or zero internet connectivity — a common challenge in rural India.

## 🛠 Tech Stack & Architecture

- **UI Framework**: Flutter (Dart SDK ^3.11.5)
- **Android Platform**: Kotlin (MainActivity + BroadcastReceiver)
- **State Management**: Provider (ChangeNotifier pattern)
- **Local Storage**: SharedPreferences
- **Peer Connectivity**: Google Nearby Connections (`nearby_connections` package, `P2P_CLUSTER` strategy)
- **QR Scanning/Generation**: `mobile_scanner`, `qr_flutter`
- **Background SMS**: `background_sms`, native Android BroadcastReceiver for receiving SMS
- **Network Detection**: `connectivity_plus` with native fallback for Airplane mode
- **Permissions**: `permission_handler`

## 📡 Offline Handling Strategy

The app uses a layered offline strategy:

1. **Layer 1 — Peer-to-Peer (Bluetooth/WiFi Direct)**: Money transferred device-to-device via Nearby Connections. No internet needed AT ALL for the actual transfer. Both parties see an immediate balance change.
2. **Layer 2 — Connectivity Radar**: A ShareIt-style discovery feature that tracks and displays nearby BluePay users who are broadcasting their presence. Users can simply tap a discovered profile on their radar list to instantly initiate a secure local connection and send money.
3. **Layer 3 — SMS Queue (GSM Relay)**: After every transaction, a JSON SMS is sent to the relay phone. If the radio is off (Airplane mode), the SMS is persisted to a queue and auto-flushed when connectivity returns.
4. **Layer 4 — USSD Dialpad**: If Bluetooth/WiFi is unavailable, the user can manually type a USSD pattern to trigger an SMS-only payment.

## 🔄 Payment Flow (End-to-End)

### Sender Flow
`HomeDashboard → [Send Money] → QRScannerScreen → Nearby Discovery → Connect → PinVerificationScreen → Enter Amount → sendBytesPayload() & SMS Queue → SuccessAnimation → Home`

### Radar P2P Flow
`HomeDashboard → [Connectivity Radar] → RadarService Discovers Users → Tap User on List → Connect → PinVerificationScreen → Enter Amount → sendBytesPayload() & SMS Queue → SuccessAnimation → Home`

### Receiver Flow
`HomeDashboard → [Receive Money] → ReceiveScreen → Nearby Advertising + QR Display → Sender Connects → BYTES Payload Received → Idempotency Check → AppState Credit & SMS Queue → SuccessAnimation → Home`

### Dialpad / USSD Fallback (Offline Only)
`HomeScreen [Dialpad] → type *#500#9876543210# → Confirm → SMS sent/queued to relay phone`

### SMS Backend Relay Sync
The Android native layer has a `SmsBalanceReceiver` that listens for incoming messages starting with `"BPAY"`. It streams these events to the Flutter side via an `EventChannel`, allowing the app to sync the confirmed server balance directly to the UI.

## 🛡 Security & Reliability

- **Idempotency**: Transactions are guarded with unique TXN IDs (`"TXN{currentTimeMillis}{random4hexChars}"`) to prevent duplicate credits or debits.
- **PIN Verification**: Payments and sensitive actions (like viewing balance) are secured via a local 4-digit PIN verification.
- **Background Sync**: The app quietly processes background SMS confirmations from the backend to ensure local ledgers reflect the true bank state once GSM is available.

## 🌍 Localization System

Supports multiple Indian languages using a custom state-driven localization framework (no external packages):
- **English** (en) — default
- **Hindi** (hi)
- **Kannada** (kn)

## 🎨 UI & Aesthetics

The application follows a clean, high-contrast, flat design aesthetic (bordered neobrutalism):
- Dark navy, green accents, and soft greys.
- Flat black borders on cards.
- Custom-painted QR corner brackets and smooth transition animations.
