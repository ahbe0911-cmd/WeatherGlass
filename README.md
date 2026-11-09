# WeatherGlass

A Persian RTL Flutter weather application for Android. Weather data is provided by Open-Meteo, so the app does **not** require an API key, account, GitHub Secret, or paid developer registration for eligible non-commercial use.

## Repository contents

The complete Flutter project is stored as a compressed source archive in `source_parts/`. GitHub Actions reconstructs it automatically before building. To extract it locally:

```bash
cat source_parts/part-*.b64 | base64 --decode > weather_glass_source.tar.xz
tar -xJf weather_glass_source.tar.xz
cd weather_glass_project
```

You can also use the ZIP source package shared in the ChatGPT conversation.

## Run locally

Install Flutter stable and the Android SDK, then run:

```bash
cd weather_glass_project
bash tool/bootstrap_android.sh
flutter pub get
flutter run
```

No `--dart-define` and no API key are needed.

## Build APK locally

```bash
cd weather_glass_project
bash tool/bootstrap_android.sh
flutter pub get
flutter build apk --release
```

APK output: `weather_glass_project/build/app/outputs/flutter-apk/app-release.apk`.

## GitHub Actions

Every push to `main` triggers `.github/workflows/main.yml`, which calls `.github/workflows/build.yml`. The workflow installs Java 17 and Flutter stable, reconstructs the source archive, generates Android host files, runs `flutter analyze` and `flutter test`, builds the release APK, and uploads the `weather-glass-release-apk` artifact. No GitHub Secrets are required.

Open **Actions → Build Android APK → Artifacts** to download the APK after a successful run.

## Weather provider and license

The app uses the [Open-Meteo Forecast API](https://open-meteo.com/en/docs) for current weather, hourly forecasts, daily forecasts, UV index, and sunrise/sunset data. Its free public API is restricted to non-commercial use. The published limits are fewer than 10,000 calls per day, 5,000 per hour, and 600 per minute. Apps displaying ads, offering subscriptions, promoting commercial products, or otherwise used commercially need an appropriate Open-Meteo commercial plan or permission. Weather data is licensed under CC BY 4.0; the app includes a clickable Open-Meteo attribution link. Review the current [terms](https://open-meteo.com/en/terms) before public release.

## Location and background refresh

- The first successful onboarding requests location permission and stores latitude/longitude locally.
- Later launches reuse saved coordinates and never call the permission request method again.
- If location permission remains granted, the app checks for movement and updates the saved location after a move of at least 5 km.
- If permission is denied or GPS is disabled later, saved coordinates remain usable and the app provides a shortcut to Android settings.
- WorkManager requests an hourly background refresh, but Android may delay periodic jobs due to battery optimization, Doze mode, or network availability.

Android does not allow an app to silently turn on GPS or grant itself location permission.
