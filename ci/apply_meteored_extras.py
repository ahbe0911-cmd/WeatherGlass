#!/usr/bin/env python3
"""Apply Meteored-inspired features without deleting the original WeatherGlass screens."""
from pathlib import Path
import shutil

root = Path("weather_glass_project")
screen = root / "lib/presentation/screens/weather_home_screen.dart"
target = root / "lib/presentation/screens/meteored_details_screen.dart"
feature = Path("ci/meteored_details_screen.dart")

if not screen.is_file() or not feature.is_file():
    raise SystemExit("WeatherGlass home screen or extension file not found.")

shutil.copyfile(feature, target)

# Do not change pre-existing UI, controllers, branding or source archive.
src = screen.read_text(encoding="utf-8")
import_line = "import 'meteored_details_screen.dart';\n"
if import_line not in src:
    src = import_line + src

shortcut = """floatingActionButton: FloatingActionButton.extended(
    heroTag: 'meteored_details',
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MeteoredDetailsScreen(),
      ),
    ),
    icon: const Icon(Icons.radar_rounded),
    label: const Text('رادار و ۱۴ روزه'),
  ),
"""
if "heroTag: 'meteored_details'" not in src:
    if 'return Scaffold(' in src:
        src = src.replace('return Scaffold(', 'return Scaffold(\n  ' + shortcut, 1)
    elif 'Scaffold(' in src:
        src = src.replace('Scaffold(', 'Scaffold(\n  ' + shortcut, 1)
    else:
        raise SystemExit("Cannot safely find a Scaffold to add feature shortcut.")
screen.write_text(src, encoding="utf-8")

pubspec = root / "pubspec.yaml"
yaml = pubspec.read_text(encoding="utf-8")
for name, version in (
    ("flutter_map", "^7.0.2"),
    ("latlong2", "^0.9.1"),
):
    if name + ":" not in yaml:
        if "dev_dependencies:" not in yaml:
            raise SystemExit("pubspec.yaml has no dev_dependencies anchor")
        yaml = yaml.replace(
            "dev_dependencies:",
            "  " + name + ": " + version + "\n\ndev_dependencies:",
            1,
        )
pubspec.write_text(yaml, encoding="utf-8")
print("WeatherGlass extended with 14-day forecast, radar, air quality and city search.")
