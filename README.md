# 🌸 Mahila Bachat Gat (महिला बचत गट)

> **Women's Self-Help Savings Group Management App**  
> Private client app — not an official government application.

---

## 📋 Overview

A Flutter-based Android application to manage **Mahila Bachat Gat** (Women's Self-Help Groups / SHGs). It supports full group lifecycle management: member onboarding, monthly savings, loans, meetings, bank records, and PDF reports — all in **Marathi, Hindi, and English**.

---

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter 3.x (Android first) |
| State Management | Riverpod 2.x |
| Architecture | Clean Architecture |
| Auth | Firebase Auth (Phone OTP) |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging (FCM) |
| Localization | flutter_localizations + ARB |
| PDF Export | `pdf` + `printing` packages |
| Encryption | AES-256 (`encrypt` package) |

---

## 📁 Project Structure

```
mahila_bachat_gat/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase config (replace with your own)
│   ├── app_router.dart              # GoRouter navigation
│   ├── core/
│   │   ├── constants/               # Colors, strings, Firestore keys
│   │   ├── errors/                  # AppException
│   │   ├── extensions/              # Date helpers
│   │   ├── theme/                   # App theme (green/purple)
│   │   ├── utils/                   # Aadhaar encryption, PDF, validators
│   │   └── widgets/                 # Reusable widgets
│   ├── l10n/                        # ARB translation files
│   │   ├── app_mr.arb              # Marathi (default)
│   │   ├── app_hi.arb              # Hindi
│   │   └── app_en.arb              # English
│   ├── data/
│   │   ├── models/                  # Freezed data models
│   │   └── repositories/            # Firestore data access
│   ├── domain/
│   │   └── usecases/               # Business logic
│   └── presentation/
│       ├── providers/               # Riverpod providers
│       └── screens/                 # All app screens
├── firestore.rules                  # Firestore security rules
├── pubspec.yaml
└── README.md
```

---

## 🚀 Setup Instructions

### Step 1: Prerequisites

- Flutter SDK ≥ 3.19.0 ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Android Studio or VS Code with Flutter plugin
- Node.js (for Firebase CLI)
- Java JDK 17+

```bash
# Verify Flutter
flutter doctor

# Install Firebase CLI
npm install -g firebase-tools
firebase login
```

### Step 2: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** → Name it `MahilaBachatGat`
3. Enable **Google Analytics** (optional)

### Step 3: Enable Firebase Services

In your Firebase project:

**Authentication:**
- Go to **Authentication → Sign-in method**
- Enable **Phone** authentication
- Add your country (India `+91`)

**Firestore:**
- Go to **Firestore Database → Create database**
- Start in **Production mode**
- Choose region: `asia-south1` (Mumbai)

**Storage:**
- Go to **Storage → Get started**
- Production mode
- Same region: `asia-south1`

**Cloud Messaging:**
- Go to **Project Settings → Cloud Messaging**
- Note down the **Server key** (for sending notifications)

### Step 4: Register Android App

1. In Firebase Console → **Project Overview → Add app → Android**
2. Package name: `com.mahilabachatgat`
3. App nickname: `Mahila Bachat Gat`
4. Download `google-services.json`
5. Place it at: `android/app/google-services.json`

### Step 5: Generate `firebase_options.dart`

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (run from project root)
flutterfire configure
```

This will generate `lib/firebase_options.dart` automatically. **Replace the placeholder file**.

### Step 6: Install Dependencies

```bash
flutter pub get
```

### Step 7: Generate Freezed/JSON Code

```bash
# Run build_runner to generate .g.dart and .freezed.dart files
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 8: Generate Localization Files

```bash
flutter gen-l10n
```

This generates `lib/l10n/generated/` from the ARB files.

### Step 9: Deploy Firestore Security Rules

```bash
# Login to Firebase
firebase login

# Initialize in project (if not done)
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

### Step 10: Run the App

```bash
# Run on connected Android device or emulator
flutter run

# Run in release mode
flutter run --release
```

---

## 📦 Build APK

```bash
# Build debug APK
flutter build apk --debug

# Build release APK (requires signing setup)
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔑 Signing the Release APK

1. Generate a keystore:
```bash
keytool -genkey -v -keystore mahila_bachat_gat.keystore \
  -alias mahila_bachat_gat -keyalg RSA -keysize 2048 -validity 10000
```

2. Create `android/key.properties`:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=mahila_bachat_gat
storeFile=../mahila_bachat_gat.keystore
```

3. Update `android/app/build.gradle` to use the keystore (already configured in the file).

---

## 🔒 Privacy & Security

- **Aadhaar**: Only last 4 digits stored in plain text. Full number is AES-256 encrypted before storage. Users must give explicit consent via checkbox.
- **Firestore Rules**: Users can only access their own group's data. Financial records can only be written by the Leader (or Deputy if enabled).
- **Audit Log**: Every financial change is recorded in `auditLogs` collection (append-only, no delete).
- **Offline Support**: Firestore offline persistence is enabled. Data entered offline syncs automatically when internet returns.

---

## 👥 User Roles

| Role | Marathi | Permissions |
|---|---|---|
| Leader | अध्यक्ष | Full access: create group, approve members, all financial operations |
| Deputy | उपाध्यक्ष | View all + write if Leader enables "Deputy Can Write" |
| Member | सदस्य | View own data, apply for loan, read group summary |

---

## 📊 Firestore Collections

| Collection | Purpose |
|---|---|
| `users` | User profiles (aadhaar encrypted) |
| `groups` | Group details and settings |
| `memberships` | Member join requests and status |
| `savings` | Monthly savings records |
| `loans` | Loan applications and status |
| `repayments` | Loan repayment records |
| `meetings` | Meeting details |
| `attendance` | Meeting attendance records |
| `bankTransactions` | Bank deposits/withdrawals/cash |
| `auditLogs` | Immutable audit trail |

---

## 🌐 Languages

| Language | Code | Default |
|---|---|---|
| मराठी (Marathi) | `mr` | ✅ Yes |
| हिंदी (Hindi) | `hi` | |
| English | `en` | |

Language is chosen on first launch and can be changed in Settings.

---

## 📱 Screen Flow

```
Splash → Language Selection (first launch)
       → Login (Phone + OTP)
       → Registration (new user)
       → Create Group (Leader) or Join Group (Member)

Leader: Leader Dashboard → Pending Requests
                        → Monthly Savings Collection
                        → Loan Management
                        → Meetings
                        → Bank Book
                        → Group Settings
                        → Reports

Member: Member Dashboard → Passbook
                        → Apply for Loan
                        → Meeting History
                        → Settings
```

---

## ⚙️ Group Rules (Configurable by Leader)

- Max members: **11** (including leaders) — configurable
- Monthly savings: **₹100** — configurable
- Loan interest: **1% per month** (reducing balance) — configurable
- Late fee: Optional, configurable amount

---

## 📄 Reports Available

1. **Monthly Report** — member savings, loans, interest (PDF)
2. **Yearly Report** — month-by-month summary (PDF)
3. **Member Passbook** — individual savings history (PDF)
4. **Loan Statement** — loan + repayment history (PDF)
5. **Attendance Report** — member attendance percentage (PDF)

All reports can be **exported as PDF** and **shared via WhatsApp**.

---

## 🔔 Notifications

- Monthly due date reminder
- Meeting reminder
- Loan approval/rejection notification

(Requires FCM setup and a backend function or Firebase Scheduled Functions to trigger)

---

## 🐛 Troubleshooting

**Build fails with "google-services.json not found"**
→ Download from Firebase Console and place at `android/app/google-services.json`

**OTP not received**
→ Ensure phone auth is enabled in Firebase Console. Check SHA-1 fingerprint is added.

**Freezed files not generated**
→ Run `flutter pub run build_runner build --delete-conflicting-outputs`

**Localization not working**
→ Run `flutter gen-l10n` after modifying ARB files

---

## 📞 Support

This is a private client application. For support, contact the developer directly.

---

*महिला बचत गट — महिलांच्या आर्थिक सशक्तीकरणासाठी* 🌸
