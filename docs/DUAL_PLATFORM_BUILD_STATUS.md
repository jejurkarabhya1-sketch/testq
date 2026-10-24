# Android + Web build status

This repository now has one GitHub Actions workflow with independent Android APK and Flutter Web build jobs. The workflow generates missing platform scaffolding, resolves dependencies, checks formatting, runs `flutter analyze` and `flutter test`, and then builds both outputs. Download artifacts from the successful Actions run:

- `lasalgaon-payroll-android-apk` — release APK
- `lasalgaon-payroll-flutter-web` — ZIP containing `build/web/`

## Important compatibility blocker

The current application source is **not yet Web-compatible**. `lib/main.dart` and `lib/database.dart` import `dart:io`; the database uses `sqflite`/`path_provider`; and export flows use native filesystem and printing APIs. These are not interchangeable with browser APIs. The Web build job is deliberately included to expose the actual compiler/dependency errors, but it may fail until the storage and export layers are refactored behind conditional platform implementations.

Do not treat the presence of a workflow or generated `web/` directory as proof that Web support works. Web must use persistent browser storage (for example IndexedDB or a tested SQLite WASM solution), browser downloads for Excel/PDF/backup, and an import/export strategy that never overwrites the only copy of payroll data.

## Release gates

- `dart format --output=none --set-exit-if-changed lib test`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- `flutter build web --release`
- Test persistence, import/backup/restore, authentication, month isolation, and six-sheet workbook generation on each target.
- Compare the generated workbook against the Python reference output before using official payroll data.

The current workspace did not have a working Flutter SDK/network route, so no Flutter compilation or build success is claimed here.
