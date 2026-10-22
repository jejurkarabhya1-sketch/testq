# Lasalgaon Gram Panchayat Payroll — Flutter Android

Android-first Flutter conversion of the supplied Python/SQLite payroll app. It is designed for one device initially, stores records in an app-private SQLite database, and documents a later migration to a versioned shared API for multi-user use.

## Build the APK through GitHub Actions

1. Create a **private** GitHub repository.
2. Extract this ZIP and upload the **contents** of `LasalgaonPayrollFlutter/` to the repository root. Include the hidden `.github` directory.
3. Commit to `main` or `master`.
4. Open **Actions → Build Android APK → Run workflow** (pushes to the main branches also trigger the workflow).
5. Wait for the workflow to complete successfully. Download `lasalgaon-payroll-android-apk` from the run's **Artifacts** section and extract it to get `app-release.apk`.

The workflow provisions the Android platform scaffold, installs Java 17 and Flutter stable, resolves dependencies, runs analysis and calculation tests, builds the release APK, and stores the APK artifact for 30 days. The source archive is not itself an APK.

## App startup

- First-run password: `admin`. Change it immediately in **सेटिंग्ज → पासवर्ड बदला**.
- Data is stored in the Android app's private documents folder as `payroll.db`.
- Use **सेटिंग्ज → जुना डेटाबेस आयात** to import a copy of the desktop application's SQLite database. The importer validates the SQLite header, creates a `.backup`, and attempts rollback if opening the imported database fails.
- Use **अहवाल → डेटाबेस बॅकअप** before importing or changing production data.
- Email reports use Gmail SMTP and an App Password. Configure the sender, recipient and signature role in Settings; the SMTP App Password is stored using Android secure storage. Do not use your normal Gmail password.
- Do not commit a real payroll database, employee records, App Passwords, or signing keys to GitHub.

## Current implementation

- Marathi-first Material 3 interface: dashboard, monthly payroll, employee management, daily-wage payroll, reports, and settings.
- Local SQLite persistence with a migration path for existing desktop database schemas.
- Full employee editor for common salary inputs, personal fields, bank details, and the eight Gramnidhi/water salary/PPF account fields.
- Monthly payroll snapshots so edits to salary inputs are scoped to the selected month; bank and contact details are refreshed from the employee record for payment registers.
- Payroll formula port: 10% living allowance toggle, 8.33% GP share/PF, allowances, recovery by days, professional tax by threshold/gender, loan/insurance/advances/society/other deductions, and non-negative rounded net pay.
- Daily-wage staff, monthly daily rate, absent days, and net payable calculation.
- Six-sheet Excel workbook output for the two payroll registers and four salary/PPF bank sheets, plus daily-wage Excel export.
- PDF salary summary, local database backup/share, SQLite import, password change, professional-tax settings, retirement-age settings and retirement schedule.
- Email recipient and signature-role settings, with SMTP sending of the generated workbook.
- GitHub Actions workflow and payroll calculation tests.

## Release validation — do not skip

The supplied Python baseline previously passed its 31 unit tests in the development environment. This validates the original Python app, not this Flutter port. The current environment did not have Flutter/Dart installed, so no local Flutter build or Android-device test is claimed. The GitHub workflow is the next compile/test gate.

This port is substantially more complete than the initial UI-only draft, but it is **not yet certified as an exact one-for-one replacement**. Before official payroll use, compare all six exported sheets with the original workbook, including column widths, print areas, page setup, formulas, footer certificates and signatures; compare each payroll result against `app.py::calc`; verify imported legacy database records and settings; test SMTP on a real device; and test month isolation for employees who are deactivated or whose records change after a month is closed. The original desktop password hash is not imported as the mobile password; the first-run mobile password remains `admin` until changed.

## Future multi-user architecture

Do not put a shared SQLite database on a network drive or sync a database file between phones. When multi-user access is needed, add a versioned authenticated REST API, server-side authorization, audit history, backup/restore, concurrency control and conflict resolution. Keep the same Dart repository interface so local SQLite can be replaced behind a repository/service layer.
