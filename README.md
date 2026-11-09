# WeatherGlass 2.0

A premium Persian-first Android weather application built with Flutter, Riverpod, Open-Meteo, Geolocator, SharedPreferences, Lottie, and WorkManager.

## What's new in 2.0

- Three dedicated bottom-navigation tabs: **امروز**, **هفتگی**, and **تنظیمات**.
- Independent scroll layouts for each tab; no single endless dashboard scroll.
- Full-screen animated backgrounds that react to weather and local time: clouds, rain, snow, fog, lightning flashes, sun glow/lens flares, and night stars.
- Lottie weather illustrations and blurred glassmorphism cards.
- Current humidity, wind speed, and UV index are displayed once in a compact grid.
- Hourly precipitation probability is shown for each forecast hour; daily maximum precipitation probability is shown for each forecast day.
- Exact values returned by Open-Meteo are retained in the UI (temperature and wind are formatted to one decimal place).
- Persian RTL interface with Vazirmatn typography.
- Seven-day forecast, 48-hour hourly forecast, sunrise and sunset.
- Saved GPS coordinates, first-launch-only permission request, significant-movement location updates, offline cache, and best-effort hourly WorkManager refresh.
- No API key, account, or GitHub Secret is required.

## Weather data provider and licence

The app uses the [Open-Meteo Forecast API](https://open-meteo.com/en/docs). The request includes current, hourly, and daily variables, with automatic timezone selection, Celsius, and km/h.

**Important:** Open-Meteo's free public API is limited to non-commercial use and has published fair-use limits of 10,000 calls per day, 5,000 per hour, and 600 per minute. Apps displaying ads, supporting a business, subscriptions, client work, or other commercial use require an appropriate paid plan or permission. The weather data is licensed under CC BY 4.0, and the app links to Open-Meteo attribution. Check the current [terms](https://open-meteo.com/en/terms) before publishing.

Open-Meteo provides forecasts from numerical weather models; forecasts are estimates, not guaranteed measurements. Data availability and accuracy are not warranted by the provider.

## Run locally

Requirements: Flutter stable, Android SDK, and an internet connection.

```bash
flutter pub get
bash tool/bootstrap_android.sh
flutter run
```

No API key or `--dart-define` is required.

## Build a release APK

```bash
flutter build apk --release
```

Output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## GitHub Actions

Every push to `main` triggers `.github/workflows/main.yml`, which calls `.github/workflows/build.yml`. The pipeline installs Java 17 and Flutter stable, extracts the source archive, applies the premium UI patch, runs dependency resolution, analysis and tests, builds the release APK, and uploads the artifact named `weather-glass-release-apk`.

No GitHub Actions secrets are needed.

## Location behavior

- On first launch, the app checks GPS and requests location permission only during the initial onboarding attempt.
- The first successful latitude/longitude and permission state are saved in SharedPreferences.
- On later launches, the app never calls `requestPermission()`; it loads saved coordinates and silently checks the device location only if permission is already granted.
- Saved coordinates are replaced only after movement of at least 5 km.
- If permission is later revoked or GPS is disabled, the app continues to use saved coordinates and offers Android settings shortcuts.
- Android does not allow an app to silently enable GPS or grant itself location permission.

## Background refresh

WorkManager requests an hourly refresh using the saved coordinates. Android controls actual scheduling and may defer work due to Doze, battery optimization, or network conditions. It is best-effort, not an exact-hour guarantee.

## Source layout

The complete Flutter source is in `weather_glass_source.tar.xz`. The GitHub Actions workflow extracts it into `weather_glass_project/` and overlays the premium UI patch stored in `ci/premium-patch/`.

The source project contains:

```text
weather_glass_project/
├── assets/animations/
├── lib/
│   ├── core/
│   ├── data/
│   │   ├── models/
│   │   └── services/
│   └── presentation/
│       ├── providers/
│       ├── screens/
│       │   ├── today_screen.dart
│       │   ├── weekly_screen.dart
│       │   ├── settings_screen.dart
│       │   └── weather_home_screen.dart
│       └── widgets/
├── test/
├── tool/
├── pubspec.yaml
└── analysis_options.yaml
```
