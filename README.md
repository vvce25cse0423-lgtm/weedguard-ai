# WeedGuard AI

AI-powered weed identification and targeted intervention for farmers.

## Overview

WeedGuard helps farmers identify weeds, understand infestation severity, locate priority zones, and monitor field conditions over time using a smartphone.

The core workflow: **Identify → Quantify → Locate → Monitor**

## Problem

Weed infestation is unevenly distributed across fields. Uniform treatment wastes resources. Farmers need a tool to capture field images, detect weeds, estimate severity by zone, and compare trends across time.

## Solution

A Flutter Android application that:
- Captures or imports field images
- Runs weed detection (mock in development; YOLO-based in production)
- Displays bounding-box overlays, weed counts, and confidence scores
- Divides the image into four zones and rates infestation per zone
- Saves every scan to Supabase for historical comparison
- Provides side-by-side comparison of any two scans

## Features

- Authentication (signup, login, forgot password) via Supabase Auth
- Field management (create, edit, delete, view with crop type, area, GPS location)
- AI-powered weed scanner with mock detection service
- Detection result screen with bounding boxes, severity, zone analysis
- Scan history with all past scans
- Scan comparison between any two timestamps
- Weather via Supabase Edge Function (OpenWeatherMap)
- Offline connectivity detection
- Profile management

## Architecture

```
lib/
├── core/
│   ├── constants/       # App constants, env vars
│   ├── theme/           # AppTheme, AppColors
│   ├── routing/         # GoRouter configuration
│   ├── errors/          # AppError sealed classes
│   ├── network/         # ConnectivityService
│   └── utils/           # DateFormatter
├── features/
│   ├── auth/            # Login, signup, forgot password
│   ├── dashboard/       # Home screen with stats
│   ├── profile/         # Profile editing
│   ├── fields/          # Field CRUD
│   ├── scanner/         # Camera + image picker + analysis
│   ├── detection/       # Results, zone grid, overlay painter
│   ├── history/         # All scans list
│   ├── comparison/      # Side-by-side scan diff
│   ├── weather/         # Weather widget + data
│   └── settings/        # App settings + logout
└── shared/
    ├── models/          # FieldModel, ScanModel, WeedDetectionResult, etc.
    ├── services/        # WeedDetectionService (abstract + mock)
    └── widgets/         # EmptyState, ErrorState, OfflineBanner
```

### AI Service Architecture

```dart
abstract class WeedDetectionService {
  Future<WeedDetectionResult> analyzeImage(File imageFile);
  bool get isMock;
}

// Development / demo:
class MockWeedDetectionService implements WeedDetectionService { ... }

// Production (to implement):
// class RealWeedDetectionService implements WeedDetectionService { ... }
```

Replace `MockWeedDetectionService` in `ScannerScreen` with `RealWeedDetectionService` once the YOLO model endpoint is ready.

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x (Dart) |
| State | Flutter Riverpod |
| Navigation | GoRouter |
| Backend | Supabase (Auth, PostgreSQL, Storage, Edge Functions) |
| Weather | OpenWeatherMap via Supabase Edge Function |
| Maps | flutter_map (OSM tiles) |
| CI/CD | GitHub Actions |

## Database Schema

```
profiles        – user info, linked to auth.users
fields          – farm fields (crop, area, GPS)
scans           – scan results per field
detections      – individual weed bounding boxes per scan
field_zones     – zone-level severity summary per scan
weather_snapshots – weather readings per field
```

Full SQL: `supabase/migrations/001_initial_schema.sql`

## Setup

### 1. Prerequisites

- Flutter SDK 3.19+
- Android Studio or VS Code with Flutter extension
- Supabase account
- (Optional) OpenWeatherMap API key

### 2. Supabase Setup

1. Create a project at https://supabase.com
2. Run `supabase/migrations/001_initial_schema.sql` in the SQL editor
3. Create two storage buckets: `scan-images` and `profile-images` (both private)
4. Deploy the weather edge function:
   ```bash
   supabase functions deploy weather
   supabase secrets set OPENWEATHER_API_KEY=<your_key>
   ```

### 3. Environment Variables

Pass via `--dart-define` at build time or run time:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

**Never commit secrets to the repository.**

### 4. Run locally

```bash
git clone https://github.com/your-org/weedguard.git
cd weedguard
flutter pub get
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

### 5. Run tests

```bash
flutter test
```

### 6. Build APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

## GitHub Actions

Two workflows:

- **`flutter_ci.yml`** — runs on every push/PR: format check, analyze, tests
- **`android_build.yml`** — runs on merge to main: builds release APK and uploads as artifact

Configure repository secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Known Limitations

- Detection uses `MockWeedDetectionService`; production YOLO integration is a placeholder
- Weather falls back to mock data when `OPENWEATHER_API_KEY` is not set
- Zone boundaries are image-frame divisions, not GPS-mapped field sectors
- Severity thresholds are prototype defaults, not validated agronomic standards
- Offline scan queue is detected but not yet persisted across restarts

## Future Improvements

- On-device YOLO model via TFLite / ONNX
- GPS-mapped field zone boundaries
- Treatment recording and outcome tracking
- Multi-language support (Hindi, Tamil, Telugu, Kannada)
- Push notifications for scan reminders
- Export scan reports as PDF
