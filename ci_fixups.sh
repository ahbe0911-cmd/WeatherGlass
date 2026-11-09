#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="weather_glass_project"

cat > "$PROJECT_DIR/lib/core/theme/app_theme.dart" <<'DART'
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF76C7E8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: GoogleFonts.vazirmatn().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      primaryTextTheme: base.primaryTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }
}
DART

python3 - <<'PY'
from pathlib import Path
root = Path('weather_glass_project')

service = root / 'lib/data/services/open_meteo_service.dart'
s = service.read_text()
s = s.replace(
    'OpenMeteoService({required http.Client client}) : _client = client;',
    'OpenMeteoService(this._client);',
)
service.write_text(s)

providers = root / 'lib/presentation/providers/app_providers.dart'
s = providers.read_text().replace('OpenMeteoService(client: client)', 'OpenMeteoService(client)')
providers.write_text(s)

screen = root / 'lib/presentation/screens/weather_home_screen.dart'
s = screen.read_text().replace(
    'separatorBuilder: (_, __) => const SizedBox(width: 12),',
    'separatorBuilder: (_, _) => const SizedBox(width: 12),',
)
screen.write_text(s)

bootstrap = root / 'tool/bootstrap_android.sh'
s = bootstrap.read_text()
anchor = '''if [[ ! -d android ]]; then\n  flutter create --platforms=android --org com.weatherglass --project-name weather_glass .\nfi\n\nmkdir -p android/app/src/main\n'''
replacement = '''if [[ ! -d android ]]; then\n  flutter create --platforms=android --org com.weatherglass --project-name weather_glass .\nfi\n\n# Remove Flutter's untouched sample widget test, which targets the template MyApp.\nif [[ -f test/widget_test.dart ]] && grep -q "MyApp" test/widget_test.dart; then\n  rm test/widget_test.dart\nfi\n\nmkdir -p android/app/src/main\n'''
if anchor in s:
    s = s.replace(anchor, replacement)
bootstrap.write_text(s)
PY
