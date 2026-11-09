# WeatherGlass

A Persian RTL Flutter weather application for Android.

## Repository status

The GitHub repository is initialized and ready for the Flutter project source. Add the contents of the provided `weather_glass_flutter_source.zip` to the repository root, preserving the `lib/`, `assets/`, `test/`, `tool/`, and `pubspec.yaml` paths.

## API configuration

Before building with live weather data, add a repository Actions secret named `WEATHER_API_KEY` containing your WeatherAPI key. The app reads it using `--dart-define`; never commit the key to source control.

## Local build

```bash
bash tool/bootstrap_android.sh
flutter pub get
flutter run --dart-define=WEATHER_API_KEY=YOUR_WEATHERAPI_KEY
flutter build apk --release --dart-define=WEATHER_API_KEY=YOUR_WEATHERAPI_KEY
```

The generated APK is at `build/app/outputs/flutter-apk/app-release.apk`.

## CI/CD

After adding the project source and the `.github/workflows` configuration, push to `main` to run the Android release build. The APK will be available from the workflow run's Artifacts section.
