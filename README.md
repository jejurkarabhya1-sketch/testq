# Lasalgaon Gram Panchayat Payroll — Flutter Android

Flutter Android conversion starter for the supplied Python + SQLite payroll application. The app uses a device-local SQLite database (`payroll.db`) and includes a single-device-first structure that can later be moved behind a shared API.

## Build an APK

Install Flutter stable and Android Studio / Android SDK, then run:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK output (after a successful build): `build/app/outputs/flutter-apk/app-release.apk`.

> This workspace did not have Flutter/Dart installed, so the APK could not be built or analyzer-tested here. Do not treat this source ZIP as a compiled APK.

## First launch

- Default password: `admin`
- Change the password immediately in **सेटिंग्ज → पासवर्ड बदला**.
- Data is stored locally in the app's private documents directory as `payroll.db`.
- Use **सेटिंग्ज → जुना डेटाबेस आयात** to select a copy of the desktop app's `data/payroll.db`. The importer creates a `.backup` of the current mobile database before replacement.
- Use **अहवाल → डेटाबेस बॅकअप** to share a database copy before major changes.

## Included in this source version

- Marathi-first Android UI and navigation
- Local SQLite persistence
- Employee records, department selection, basic employee editing, and separate bank/PPF account fields
- Salary calculations for basic, allowances, GP share, recovery by days, PF, professional tax, deductions and net pay
- Month/year selector
- Daily-wage employee management, monthly rate and absence tracking
- Professional tax settings and password change
- Designation-based retirement-age settings storage/editor
- Excel salary summary export, PDF summary print/export, and local database backup
- Legacy SQLite database import with backup/rollback attempt

## Important parity status

This is an initial Flutter port, **not yet a verified one-for-one replacement**. The original Python project has 31 passing unit tests in this environment (`python -m unittest -q`), but Flutter could not be run here. The parity matrix in `docs/PARITY_MATRIX.md` lists functions that still need implementation or verification before production payroll use. In particular, the original app's six fully formatted workbook sheets, complete salary-period snapshot isolation, SMTP email workflow, full print-register layouts/terej footer, complete employee edit fields and retirement schedule view need additional work and side-by-side validation.

## Architecture notes

- `lib/database.dart`: SQLite schema, repository methods, and salary formula port.
- `lib/main.dart`: UI and reports.
- `assets/lasalgaon_logo.jpg`: logo copied from the supplied source archive.
- Keep business logic in repository/service classes, not widgets, as the app grows.
- Future multi-user mode should use a versioned REST API with authentication and server-side authorization. Do not sync a shared SQLite file over a network drive. Add conflict handling, audit logs, encrypted transport, and backups before enabling multi-user writes.

## Data safety

Test imports only with a backup first. Verify every employee, salary month, bank account, professional-tax setting, and daily-wage row after import. Never distribute an APK containing real payroll records.


## Android and Web builds

GitHub Actions workflow: `.github/workflows/build-android-web.yml`. On a successful run, download the `lasalgaon-payroll-android-apk` and `lasalgaon-payroll-flutter-web` artifacts from the Actions run. See `docs/DUAL_PLATFORM_BUILD_STATUS.md` for current Web compatibility limitations and release gates. The current source still contains native-only SQLite/filesystem APIs, so do not assume Web builds until the Web job succeeds and browser persistence/export tests pass.
