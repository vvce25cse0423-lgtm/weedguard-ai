# 🚀 WeedGuard AI - Precision Agriculture Android Application

<p align="center">
  <b>An intelligent, precision agriculture mobile application engineered to detect weeds, minimize chemical costs, and empower farmers with actionable agronomic intelligence.</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/Framework-Flutter%20v3.22.3-blue?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Language-Dart%20v3.4-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase" alt="Supabase"/>
  <img src="https://img.shields.io/badge/Build-GitHub%20Actions-2088FF?logo=githubactions" alt="GitHub Actions"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</p>

---

## 📌 Table of Contents
- [About the Project](#-about-the-project)
- [Key Problem & Solution](#-key-problem--solution)
- [Core Features](#-core-features)
- [Technology Stack](#-technology-stack)
- [System Architecture](#-system-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Configuration & Environment Variables](#-configuration--environment-variables)
- [Building the Release APK](#-building-the-release-apk)
- [Automated CI/CD Pipeline](#-automated-cicd-pipeline)
- [Localization (Kannada, Hindi, English)](#-multi-lingual-accessibility)
- [Security & Data Integrity](#-security--data-integrity)
- [Future Enhancements](#-future-enhancements)
- [Contributing](#-contributing)
- [License](#-license)
- [Project Details & Team](#-project-details--team)

---

## 📖 About the Project

**WeedGuard AI** is a state-of-the-art precision agriculture mobile application designed for farmers, agronomists, and agricultural extension workers. Utilizing computer vision and agro-meteorological analytics, WeedGuard AI transforms any smartphone into a precision weed diagnostic tool.

Instead of applying uniform, wasteful chemical blanket sprays across whole fields, WeedGuard AI enables **targeted spot management**:
- Detects and classifies invasive weed species.
- Dynamically assigns field scans to sequential zones (**Zone A**, **Zone B**, **Zone C**...).
- Maps priority zones directly on top of real captured field photos.
- Provides visual farmland sketches of total priority zones.
- Generates certified chemical and zero-chemical organic prescriptions.
- Computes real-time spray weather suitability windows.

---

## 🎯 Key Problem & Solution

| Traditional Challenge | WeedGuard AI Precision Solution |
| :--- | :--- |
| **Indiscriminate Blanket Spraying** | **Targeted Spot Application:** Allocates detected weeds into priority zones (**Zone A, B, C...**) on field photos. |
| **High Input Costs & Waste** | **40%–75% Cost Reduction:** Calculates precise acreage chemical dosages and ₹ financial savings. |
| **Chemical Resistance & Toxicity** | **Resistance Tracking & Bio-Alternatives:** Day 7/14 kill audits and organic neem/acid prescriptions. |
| **Drift & Rain Wash-off** | **Smart Spray Windows:** 0–100% spray viability score factoring wind speed, temp, and rainfastness. |
| **Language & Accessibility Gaps** | **Native UI & Voice TTS:** Full app operation in **Kannada (ಕನ್ನಡ)**, **Hindi (हिंदी)**, and **English**. |

---

## ✨ Core Features

### 🌿 1. AI Weed Vision & Sequential Zone Allocation
- **Computer Vision Detection:** Real-time multi-weed detection with bounding box annotations and confidence ratings.
- **Smart Sequential Zone Assignment:** The first scan in a field is designated **Zone A**, subsequent scans of the same field or crop become **Zone B**, **Zone C**, etc., preserving zone integrity upon re-analysis.
- **Uploaded Image Background Zone Map:** "View Field Zones" displays the actual captured scan photo as the background, overlaid with priority zone boundaries and an isolated zone-wise summary.

### 🗺️ 2. Total Priority Zones Farmland Sketch
- **Farmland Visual Parcel Sketch:** Accessible directly from the crop field folder, showing a layout grid of all scanned images recorded for that field.
- **Interactive Parcel Cards:** Each parcel card displays the scan thumbnail, zone tag (Zone A, B, etc.), weed count, and severity indicator. Tapping any parcel opens the complete scan inspection sheet.
- **Priority Weeds Ranking:** Dynamically orders zones by weed density (e.g. `Zone A — 12 weeds (Amaranthus, Cyperus) • High Priority`), automatically updating as new scans are captured.

### 🌾 3. Smart Field Management & Auto Crop Grouping
- **Automated Field Grouping:** Scanning a crop (e.g., Onion) automatically associates the scan with that crop folder, avoiding duplicate field creation while keeping history neatly organized.
- **Acreage Management in Acres:** Displays and allows direct in-app editing of field plot sizes in **Acres** (with live conversion to hectares and database sync).
- **Physical Reallocation Points:** Location section plots physical capture coordinates for each zone (Zone A, Zone B) across the farm plot.

### 📜 4. Comprehensive Scan History & Detail Sheet
- **Full Historical Timeline:** Lists past scans with thumbnail previews, crop names, severity chips, and timestamps.
- **Rich Scan Inspector:** Clicking any scan reveals the full photo, Crop Name, Weed Species, certified Herbicide recommendation, and Infestation Level.
- **Resilient Offline & Cloud Caching:** Scans persist both locally and in Supabase storage so image previews are always visible.

### 🌐 5. Multi-Lingual Accessibility (Kannada, Hindi, English)
- **Deep Localization:** Complete translation support for:
  - Crop Names (*ഈരുള്ളി / प्याज / Onion*, *ಭತ್ತ / धान / Paddy*, etc.)
  - Weed Names (*Amaranthus, Cyperus, Parthenium*, etc.)
  - Precise ROI & Savings (*ನಿಖರವಾದ ROI ಮತ್ತು ಉಳಿತಾಯ / सटीक ROI और बचत*)
  - Zero-Chemical Bio Solutions (*ರಾಸಾಯನಿಕ ಮುಕ್ತ ಜೈವಿಕ / शून्य रासायनिक बायो*)
  - Herbicide Resistance Warnings (*ಕಳೆನಾಶಕ ನಿರೋಧಕತೆ ಎಚ್ಚರಿಕೆ / शाकनाशी प्रतिरोध चेतावनी*)
- **Voice Readout (TTS):** Auditory agronomy reports spoken aloud in the selected regional language.

### 💰 6. Precise ROI & Chemical Savings Calculator
- Compares standard blanket application against precision spot spraying based on field acreage.
- Displays chemical volume reduction (Litres) and financial savings (₹).

### 🍃 7. Zero-Chemical Organic Alternatives
- Non-toxic organic recipes (acetic acid + neem oil formulations).
- Cultural management guidance: mechanical weeding schedules and straw bio-mulching.

### ⚠️ 8. Herbicide Resistance Warning System
- Tracks weed kill rate at Day 7 and Day 14 post-treatment.
- Alerts farmers when weeds exhibit tolerance and recommends herbicide class rotation (different MOA).

### 🌦️ 9. Spray-Window Weather Intelligence
- Real-time weather audit calculating an **Optimal Spray Score (0–100%)**.
- Considers wind drift velocity, ambient temperature, humidity, and 3-hour rainfastness probability.

### 📄 10. Agronomy PDF Report Generation
- Generates downloadable and shareable PDF diagnostic reports containing image evidence, detected species, dosage recommendations, and safety precautions.

---

## 🧰 Technology Stack

| Component | Technology | Version / Description |
| :--- | :--- | :--- |
| **Mobile Framework** | [Flutter](https://flutter.dev/) | 3.22.3 (Channel Stable) |
| **Language** | [Dart](https://dart.dev/) | 3.4.4+ |
| **State Management** | [Flutter Riverpod](https://riverpod.dev/) | 2.5+ Reactive State Management |
| **Routing** | [GoRouter](https://pub.dev/packages/go_router) | Declarative URL-based routing |
| **Backend & Cloud DB** | [Supabase](https://supabase.com/) | PostgreSQL, Storage Buckets, Row-Level Security (RLS) |
| **AI Inference** | Groq APIs | Vision LLM & Agronomy classification |
| **Local Persistence** | SharedPreferences & SecureStorage | Offline caching & encrypted auth sessions |
| **Text-to-Speech (TTS)** | FlutterTts | Regional Kannada, Hindi, and English TTS engines |
| **PDF Generation** | PDF & Printing | Dynamic agronomy report generation |
| **CI/CD** | GitHub Actions | Automated release APK builds & artifact deployment |

---

## 🏗️ System Architecture

```text
┌──────────────────────────────────────────────────────────────────────────────────┐
│                             PRESENTATION LAYER (UI/UX)                           │
│  • Field Zone Visualizer     • Farmland Parcel Sketch    • Live Camera Scanner   │
│  • ROI & Savings Dashboard   • Spray Weather Radar       • Scan History Timeline │
│  • Trilingual Interface (Kannada / Hindi / English)      • Voice TTS Readout     │
└────────────────────────────────────────┬─────────────────────────────────────────┘
                                         │
                                         ▼
┌──────────────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION & DOMAIN LOGIC LAYER                         │
│  • Riverpod 2.5 Reactive State Management        • GoRouter Declarative Routing  │
│  • Sequential Zone Allocation Engine             • Acreage & Dosage Calculator   │
│  • 7/14-Day Herbicide Resistance Auditor         • Spray Viability Matrix (0-100)│
└───────────────────────┬──────────────────────────────────┬───────────────────────┘
                        │                                  │
                        ▼                                  ▼
┌───────────────────────────────────────┐  ┌───────────────────────────────────────┐
│       AI & AGRONOMY INFERENCE         │  │         DATA & PERSISTENCE            │
│  • Groq High-Speed Vision LLM API     │  │  • Supabase Cloud PostgreSQL DB       │
│  • Botanical Weed Classification      │  │  • Supabase Secure Storage Buckets    │
│  • Bio-Organic Formulation Engine     │  │  • Offline SharedPreferences Cache    │
│  • On-Device Ecological Classifier    │  │  • Encrypted Auth (FlutterSecureStore)│
└───────────────────────────────────────┘  └───────────────────────────────────────┘
```

### Architecture Highlights
- **Decoupled State Management:** Built on **Flutter Riverpod**, cleanly separating presentation widgets from asynchronous agronomy business logic and reactive state streams.
- **Hybrid AI Pipeline:** Leverages **Groq Vision LLMs** for high-accuracy botanical identification and crop classification, coupled with on-device ecological fallbacks for resilient offline operation.
- **Multi-Tier Persistence:** Scans, field records, and high-resolution images are mirrored across local cache and **Supabase Cloud (PostgreSQL + Storage)** with row-level security (RLS).
- **Agronomic Computation Engine:** Real-time client-side calculation of spot vs. blanket chemical dosages, monetary ROI savings in ₹, and weather-based spray safety windows.

---

## 📂 Project Structure

```text
weedguard-fixed/
├── android/                   # Native Android build configuration & Gradle scripts
├── assets/
│   ├── images/                # Background illustrations, logos, and UI hero assets
│   └── icons/                 # Vector icons & app branding
├── lib/
│   ├── main.dart              # App entry point, Supabase & service initialization
│   ├── core/                  # Theme, routing, services, and multi-lingual localizations
│   │   ├── l10n/              # AppLocalizations (English, Kannada, Hindi translations)
│   │   ├── routing/           # GoRouter route configurations
│   │   ├── services/          # Push notification & TTS services
│   │   └── theme/             # Material 3 colors, typography, and card styling
│   ├── features/
│   │   ├── auth/              # Farmer authentication & profile setup
│   │   ├── dashboard/         # Quick scan actions, weather score, and field summary
│   │   ├── detection/         # Bounding box preview, zone map overlay, PDF export
│   │   ├── fields/            # Field detail, acres editor, total priority zones sketch
│   │   ├── history/           # Scan history cards, comparative viewer, detail sheet
│   │   ├── notifications/     # Alert center for spray windows and 7-day rescans
│   │   ├── organic/           # Bio-herbicide recipes and mechanical weeding guides
│   │   ├── profile/           # User settings with branded farm background
│   │   ├── resistance/        # Weed mortality auditor & chemical resistance tracker
│   │   ├── roi_calculator/    # Spot spray financial & chemical savings calculator
│   │   ├── scanner/           # Camera viewfinder, image upload, zone auto-sequencing
│   │   ├── settings/          # Language selector (Kannada/Hindi/English) & dark mode
│   │   └── spray_window/      # Meteorological spray suitability calculator
│   └── shared/
│       ├── models/            # ScanModel, FieldModel, DetectionResultModel, ZoneData
│       └── widgets/           # Reusable thumbnail loaders, badges, offline banners
├── test/                      # Unit & widget test suites
├── .github/
│   └── workflows/
│       └── android_build.yml  # GitHub Actions automated release APK build pipeline
├── pubspec.yaml               # Package dependencies and asset manifests
└── README.md                  # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.22.3`)
- [Android Studio](https://developer.android.com/studio) or VS Code
- [Java Development Kit (JDK 17)](https://adoptium.net/)
- An Android device (API 21+) or Emulator

### 1. Clone the Repository
```bash
git clone https://github.com/vvce25cse0423-lgtm/weedguard-ai.git
cd weedguard-ai
```

### 2. Verify Environment
```bash
flutter doctor
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run the App
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-supabase-anon-key \
  --dart-define=GROQ_API_KEY=your-groq-key
```

---

## 🔒 Security & Data Integrity

- **Row Level Security (RLS):** Supabase database tables enforce strict RLS policies ensuring users only view and modify their own farm scans and field records.
- **Client Anon Key Isolation:** Only non-privileged public anonymous keys are included on the client side.
- **Encrypted Local Storage:** User authentication tokens and session keys are secured using `flutter_secure_storage`.
- **Runtime Permission Handling:** Device camera, storage, and GPS location permissions are requested transparently with contextual explanations.

---

## 🗺️ Future Enhancements

- 🛰️ **Satellite NDVI Integration:** Incorporate Sentinel-2 satellite imagery for macro-canopy vegetation indexing.
- 📱 **On-Device Offline YOLOv8:** Local TensorRT/TFLite models for real-time offline detection without cellular connectivity.
- 🚜 **Bluetooth Boom Sprayer Controller:** BLE module communication to trigger physical solenoid valves on tractor spray booms.
- 📈 **Predictive Weed Seedbank Modeling:** Machine learning forecasting of weed germination patterns based on micro-climate and historical field data.

---

## 📄 License

This project is licensed under the **MIT License**. See the `LICENSE` file for details.

---

## 👨‍💻 Project Details & Team

| Field | Details |
| :--- | :--- |
| **Developer** | **Nitin Mahadev** |
| **Team Name** | **Root Access** |
| **Event** | **Hacksprint 1.0** |
| **GitHub** | [vvce25cse0423-lgtm](https://github.com/vvce25cse0423-lgtm) |
| **Repository** | [https://github.com/vvce25cse0423-lgtm/weedguard-ai](https://github.com/vvce25cse0423-lgtm/weedguard-ai) |

---

<p align="center">
  🌱 <i>Empowering farmers with precision AI to cultivate healthier fields, reduce chemical impact, and maximize yields.</i>
</p>
