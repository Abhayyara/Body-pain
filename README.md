# BodyWise 3D - Pain & Wellness Guide

Flutter/Android app: pick a body area, answer a guided questionnaire, pass a
deterministic safety screen, and (only when eligible) see gentle general
wellness suggestions. It does not diagnose and is not a medical device.

## Honest status

| Area | Status |
|------|--------|
| Clickable UI: Home, Explore Body, My Plan, Progress, Profile | Written |
| **2D fallback** body selector (front/back, 36 regions, list alternative) | Written |
| **Real 3D skeleton**, camera controls, mesh selection | **Not started** (Phase 2). No GLB asset is included |
| Questionnaire, validation, results screen (sections A-E) | Written |
| Deterministic safety engine (E1-E9, C1-C13, I1-I9) | Written, **unreviewed by a clinician** |
| Exercise (22) and nutrition (27) libraries | Written as **draft placeholder content**, hidden in release builds |
| Local storage, saved plan, pain log, hydration, delete-all | Written |
| AI explanations, backend, Firebase/Supabase accounts | **Not started** (Phases 5-6); `ai_service.dart` is an interface stub |
| Android project files, APK | **Not generated.** Run `scripts/bootstrap.sh` |
| `flutter analyze`, `flutter test`, device testing | **Never run** (no Flutter SDK in the authoring environment) |

Phases 3 and 4 were pulled forward in basic form because the prototype flow
needs them end to end.

## Build and run

Prerequisites: Flutter SDK (stable, Dart >= 3.3), Android Studio with the
Android SDK, and a device or emulator.

    ./scripts/bootstrap.sh        # one-off: generates android/ without touching lib/ or test/
    flutter pub get
    flutter analyze
    flutter test
    flutter run                   # debug build, draft content visible
    flutter build apk --debug

Dependency versions in `pubspec.yaml` (`shared_preferences`, `flutter_lints`)
were chosen without network access and have not been resolved. If
`flutter pub get` complains, run `flutter pub upgrade --major-versions`.

### Draft content gating

Exercise and nutrition text is placeholder content with no review date. It is
shown in debug builds, and hidden in release builds unless you pass
`--dart-define=ALLOW_DRAFT_CONTENT=true`. Do not ship that flag to real users.
To publish content, have a clinician (exercises) and a dietitian (meals) review
each record, then set its `reviewedSource` and `reviewDate`.

### Release APK

Create a keystore, add `android/key.properties` (git-ignored), wire it into
`android/app/build.gradle`, then `flutter build apk --release`.

## Project layout

    lib/app/        app shell, theme, routing, config, AppController (state)
    lib/models/     assessment, body region, safety, exercise, meal, plan, records
    lib/data/       body_regions, exercises, nutrition (static libraries)
    lib/services/   anatomy (lookup + hit-testing), storage (on-device), ai stub
    lib/features/   home, body_selector, assessment, safety, recommendations,
                    plan, progress, profile
    test/           unit + widget tests
    docs/           SAFETY_RULES.md
    tools/          static_check.py (structural checks only; not a compiler)

## Privacy (current build)

All data stays on the device (SharedPreferences). No account, no network calls,
no analytics. Free-text notes are never stored with saved assessments and are
reserved from any future AI payload. "Delete all saved data" is in Profile.

## Next steps

1. Run the commands above on a machine with Flutter; fix whatever the
   analyzer and tests report.
2. Phase 2: source a licensed skeleton GLB (see `assets/models/README.md`),
   choose a 3D viewer, map meshes to region IDs, and test touch selection on a
   real Android device. Keep the 2D selector as the fallback.
3. Clinician review of `docs/SAFETY_RULES.md` and all content.
