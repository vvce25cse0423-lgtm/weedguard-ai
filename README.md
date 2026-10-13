# 🚀 WeedGuard AI - Android Application

<p align="center">
  <b>A modern, precision agriculture Android application built to detect weeds, minimize chemical costs, and empower farmers with actionable agronomic intelligence.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/Framework-Flutter-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Language-Dart-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Build-GitHub%20Actions-2088FF?logo=githubactions" alt="GitHub Actions"/>
</p>

---

## 📌 Table of Contents
- [About the Project](#-about-the-project)
- [Objectives](#-objectives)
- [Features](#-features)
- [Technology Stack](#-technology-stack)
- [System Architecture](#-system-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Build the APK](#-build-the-apk)
- [GitHub Actions](#-github-actions)
- [Security](#-security)
- [Future Enhancements](#-future-enhancements)
- [Contributing](#-contributing)
- [License](#-license)

---

## 📖 About the Project

**WeedGuard AI** is an intelligent precision agriculture mobile application engineered to help farmers diagnose weed infestations, optimize herbicide application, prevent crop damage, and maximize agricultural yields using smartphone cameras.

Uniform blanket spraying across agricultural fields wastes expensive chemicals, pollutes groundwater, and leaves toxic chemical residue in food supplies. WeedGuard AI shifts agriculture from wasteful blanket spraying to **targeted precision management**: identifying specific weed species, assessing spatial density across 4 field zones, providing certified herbicide and organic prescriptions, and guiding farmers on optimal meteorological spray windows.

---

## 🎯 Objectives
- **Empower Farmers:** Provide real-time AI computer vision identification of invasive weeds directly from mobile phone cameras.
- **Economic ROI:** Cut chemical expenditures by 40%–75% through targeted spot spraying vs blanket spraying.
- **Environmental Sustainability:** Promote non-toxic bio-herbicide alternatives, cultural mulching, and mechanical weeding.
- **Precision Timing:** Prevent dangerous drift and wash-off using hyper-local weather intelligence.
- **Regional Inclusivity:** Multi-lingual voice assistance in **Kannada**, **Hindi**, and **English** for seamless rural accessibility.

---

## ✨ Features

- 🌿 **AI Weed Vision & Spatial Zone Mapping:** Detects invasive weed species with bounding box overlays, confidence metrics, and 4-quadrant field severity heatmaps.
- 🎙️ **Voice Assistant (Read Aloud):** Multi-lingual auditory agronomy reports read aloud in **Kannada (ಕನ್ನಡ)**, **Hindi (हिंदी)**, and **English** for low-literacy field conditions.
- 🌦️ **Spray-Window Weather Intelligence:** Calculates an **Optimal Spray Score (0–100%)** considering wind drift velocity, ambient temperature, relative humidity, and 3-hour rainfastness probability.
- 💰 **Chemical Cost & ROI Savings Calculator:** Real-time financial audit contrasting standard blanket spraying against AI spot spraying, highlighting money saved (₹) and chemical toxicity reduction.
- 🍃 **Zero-Chemical Organic & Bio-Weed Solutions:** Dedicated eco-mode with recipes for natural contact bio-herbicides (acetic acid + neem oil), mechanical weeding timelines, and straw bio-mulching.
- 🔄 **Weed Growth Timeline & Resistance Tracker:** Audits post-treatment weed mortality at Day 7/14; triggers early alerts if weeds show chemical tolerance/resistance.
- 📄 **Agronomy PDF Report Generation:** Formats complete diagnostic summaries with treatment prescriptions shareable via WhatsApp and email.
- 🔔 **Mobile Push Notifications & Alert Center:** In-app and system status-bar notifications for optimal spray windows, weather warnings, and 7-day follow-up rescan reminders.
- 🗺️ **Field Plot Management:** GPS geofencing, crop categorization, and multi-field acreage tracking.
- 📊 **Scan History & Comparison:** Historical scan timeline with side-by-side comparative analysis of weed progression over time.

---

## 🧰 Technology Stack

| Component | Technology |
| :--- | :--- |
| **Frontend Framework** | [Flutter](https://flutter.dev/) (v3.22+) |
| **Programming Language** | [Dart](https://dart.dev/) (v3.4+) |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) |
| **Backend & Database** | [Supabase](https://supabase.com/) (PostgreSQL with Row Level Security) |
| **Authentication** | Supabase Auth (Email / Magic Link / Secure Tokens) |
| **Local Storage** | SharedPreferences & FlutterSecureStorage |
| **Notifications** | FlutterLocalNotifications & Android Notification Channels |
| **Text-to-Speech (TTS)** | FlutterTts (Kannada, Hindi, English regional voices) |
| **Document Engine** | PDF & Printing package |
| **Navigation** | GoRouter |
| **Version Control & CI/CD** | Git, GitHub & GitHub Actions |
| **Build Target** | Android Release APK / AAB (API 21 to 34) |

---

## 🏗️ System Architecture

```text
                  ┌────────────────────────────────────────┐
                  │          Android Mobile App            │
                  │             (Flutter UI)               │
                  └──────────────────┬─────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│   Presentation   │       │  Business Logic  │       │   Agronomy AI    │
│  - Dashboards    │       │  - Riverpod State│       │  - Bounding Box  │
│  - Result Cards  │ <───> │  - Weather Tele. │ <───> │  - Zone Density  │
│  - Voice Player  │       │  - Spray Window  │       │  - ROI Analytics │
│  - Notifications │       │  - ROI Math      │       │  - Resistance    │
└──────────────────┘       └─────────┬────────┘       └──────────────────┘
                                     │
                                     ▼
                  ┌────────────────────────────────────────┐
                  │       Data Layer & Local Cache         │
                  │ - SharedPreferences   - SecureStorage  │
                  └──────────────────┬─────────────────────┘
                                     │
                                     ▼
                  ┌────────────────────────────────────────┐
                  │      Supabase Cloud Backend (BaaS)     │
                  │  - PostgreSQL DB      - Auth & RLS     │
                  │  - Scans & Fields     - Edge Functions │
                  └────────────────────────────────────────┘
```

---

## 📂 Project Structure

```text
weedguard-fixed/
├── android/                   # Native Android configuration & Gradle builds
├── assets/
│   ├── images/                # UI illustrations, icons, and hero banners
│   └── icons/                 # Application vector assets
├── lib/
│   ├── main.dart              # Application entrypoint & Service initialization
│   ├── core/                  # Global utilities, theme, routing & services
│   │   ├── l10n/              # Multi-lingual translations (EN, KN, HI)
│   │   ├── routing/           # GoRouter route declarations
│   │   ├── services/          # Push & In-app NotificationService
│   │   └── theme/             # Material 3 theme & color schemes
│   ├── features/
│   │   ├── auth/              # Login, register, and password reset screens
│   │   ├── dashboard/         # Central hub, weather pill, and alert counter
│   │   ├── detection/         # Result screen, voice script, PDF generator
│   │   ├── fields/            # Field plot registration and polygon map
│   │   ├── history/           # Scan log list & comparative side-by-side view
│   │   ├── notifications/     # In-app Notification & Alert Center
│   │   ├── organic/           # Bio-herbicide & mechanical weed cards
│   │   ├── resistance/        # Efficacy auditor & resistance warning tracker
│   │   ├── roi_calculator/    # Spot spray vs blanket spray financial math
│   │   ├── scanner/           # Camera viewfinder & crop photo upload
│   │   ├── settings/          # Language picker, theme toggle, and account
│   │   └── spray_window/      # Meteorological spray suitability calculator
│   └── shared/
│       └── models/            # ScanModel, FieldModel, DetectionResultModel
├── test/                      # Unit and widget test suite
├── .github/
│   └── workflows/
│       └── build-apk.yml      # CI/CD Automated Android Release APK builder
├── pubspec.yaml               # Package manifests and asset registrations
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
Before building the project, ensure you have installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.22.0`)
- [Android Studio](https://developer.android.com/studio) or VS Code
- [Java Development Kit (JDK 17)](https://adoptium.net/)
- [Git](https://git-scm.com/)
- An Android Device (running Android 5.0 Lollipop or newer) or Emulator

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/weedguard-ai.git
cd weedguard-ai
```

### 2. Verify Flutter Environment
```bash
flutter doctor
```
Resolve any missing Android toolchain or license requirements.

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the Application
Connect your Android phone with USB Debugging enabled, then run:
```bash
flutter run
```

### 5. Analyze and Test Code
```bash
flutter analyze
flutter test
```

---

## ⚙️ Configuration

WeedGuard AI relies on environment definitions for Supabase connectivity and OpenRouter vision endpoints.

When building or running locally, provide configuration definitions using `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key \
  --dart-define=OPENROUTER_API_KEY=your-openrouter-api-key
```

> [!IMPORTANT]
> Never commit service role keys, database administrator passwords, or keystore signing secrets to public repositories.

---

## 📦 Build the APK

### Build Release APK
To compile a standalone, optimized release APK:
```bash
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-public-key \
  --dart-define=OPENROUTER_API_KEY=your-openrouter-api-key
```

The compiled APK will be output to:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Build Android App Bundle (Google Play)
```bash
flutter build appbundle --release
```
The resulting bundle will be located at:
```text
build/app/outputs/bundle/release/app-release.aab
```

---

## ⚙️ GitHub Actions

Automated builds and tests are configured in `.github/workflows/`:
1. Checks out the repository code.
2. Sets up JDK 17 and caches Flutter SDK 3.22.x.
3. Resolves packages via `flutter pub get`.
4. Executes static verification: `flutter analyze` and `flutter test`.
5. Compiles `flutter build apk --release` with repository secrets.
6. Uploads the final release APK as a downloadable artifact.

Download the latest APK build directly from the **Actions** tab of the GitHub repository.

---

## 🔒 Security
- **Row Level Security (RLS):** Supabase database tables enforce RLS so farmers only access their own scans and field plots.
- **Client Key Isolation:** Only public `anon` keys are used within client code.
- **Permission Restraint:** Camera, storage, and location permissions are requested on-demand with context rationale.
- **Encrypted Storage:** User tokens and authentication sessions are secured using Android Keystore via `flutter_secure_storage`.

---

## 🗺️ Future Enhancements
- 🛰️ Satellite NDVI imagery overlays for multi-hectare canopy indexing.
- 📦 Direct offline YOLOv8 TFLite on-device inference without internet requirements.
- 🤖 Automated autonomous tractor boom section controller via Bluetooth Low Energy (BLE).
- 🌾 Weed seedbank prediction modeling based on historical seasonal scans.

---

## 🤝 Contributing
Contributions, issue reports, and feature proposals are welcome!
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/PrecisionFeature`).
3. Commit your Changes (`git commit -m "feat: Add PrecisionFeature"`).
4. Push to the Branch (`git push origin feature/PrecisionFeature`).
5. Open a Pull Request.

---

## 📄 License
This project is licensed under the **MIT License**. See the `LICENSE` file for full terms and conditions.

<p align="center">
  ⭐ If you find WeedGuard AI helpful, please consider starring the repository!
</p>
