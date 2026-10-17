#!/usr/bin/env bash
# Generates the Android/Gradle scaffolding with `flutter create` WITHOUT
# touching the hand-written lib/, test/ or pubspec.yaml.
# Requires: Flutter SDK on PATH (flutter doctor should be clean for Android).
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "flutter not found on PATH"; exit 1; }

tmp="$(mktemp -d)"
cp -R lib test pubspec.yaml analysis_options.yaml "$tmp"/
flutter create . --platforms=android --org com.bodywise --project-name bodywise3d
# flutter create may rewrite these; restore ours.
rm -rf lib test
cp -R "$tmp"/lib "$tmp"/test .
cp "$tmp"/pubspec.yaml "$tmp"/analysis_options.yaml .
rm -rf "$tmp"
echo "Android scaffolding generated. Next: flutter pub get && flutter analyze && flutter test"
