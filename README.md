# WeatherGlass

A Persian RTL Flutter weather application for Android.

## Project source

The complete Flutter source project is packaged in [`weather_glass_flutter_source.zip`](./weather_glass_flutter_source.zip). Extract it to work with the full `lib/`, `assets/`, `test/`, and Android bootstrap files.

## Build in GitHub Actions

The workflow at `.github/workflows/build.yml` extracts the project, installs Flutter and Java, runs analysis and tests, builds the release APK, and uploads it as the `weather-glass-release-apk` artifact.

## API configuration

Add a repository Actions secret named `WEATHER_API_KEY` with your WeatherAPI key. The app reads it using `--dart-define`; never commit the key to source control.

## Local build

```bash
unzip weather_glass_flutter_source.zip
cd weather_glass_project
bash tool/bootstrap_android.sh
flutter pub get
flutter run --dart-define=WEATHER_API_KEY=YOUR_WEATHERAPI_KEY
flutter build apk --release --dart-define=WEATHER_API_KEY=YOUR_WEATHERAPI_KEY
```

The generated APK is at `build/app/outputs/flutter-apk/app-release.apk`.
