# Android Port Implementation Plan

## Reference application
The source of truth is the supplied Python + SQLite application. The mobile app must reproduce its behavior, not merely present a similar UI.

## Confirmed database entities
`employees`, `payroll_periods`, `payroll_entries`, `daily_wage_employees`, `daily_wage_payroll`, `auth_users`, `auth_sessions`, `email_settings`, `professional_tax_settings`, and `retirement_age_settings`.

The employee schema includes four distinct account/IFSC pairs: Gramnidhi salary, Gramnidhi PPF, water-supply salary, and water-supply PPF. Keep these separate.

## Feature work order

### P0 — Data safety and database compatibility
- Validate desktop database schema before replacement/import.
- Stage imports and validate SQLite integrity plus required payroll tables before replacing the live database.
- Preserve a timestamped backup and rollback on reopen failure; never overwrite the source database.
- Still required: execute import against a copy of the supplied desktop database on Android and verify all row counts/table names.
- Do not ship or commit real payroll records in the source repository or APK.

### P1 — Payroll calculation and monthly snapshots
- Port `app.py::calc` exactly, including rounding and professional-tax behavior.
- Implemented initial month/year snapshots in `periodRows` and `savePeriodPatch`, keyed by `(month, year, employee)`.
- Still required: parity tests against the Python app for employee deactivation, bank-field synchronization, existing historic snapshots, and every edit field.
- Keep bank account/IFSC identity fields synchronized with the current employee record as the Python app does.
- Validate month length, leap year, recovery days, zero values, and tax threshold equality.

### P2 — Daily-wage and employee management
- Match employee add/edit/deactivate fields and validation.
- Match daily-wage rate, absent days, monthly persistence, bank fields, and employee types.
- Match retirement schedule by designation, default age 60, DOB validation, ordering, and days remaining.

### P3 — Six-sheet workbook parity
Generate the same six worksheets as `generate_salary_workbook`:
1. `ग्रामनिधी`
2. `Gramnidhi Salary`
3. `Maharashtra Bank Gramnidhi PPF`
4. `पाणी पुरवठा `
5. `पाणी पुरवठा Salary`
6. `Maha Bank पाणी पुरवठा PPF`

Preserve header rows, formulas/calculated values, column order, bank/PPF account mapping, Terej summary, register certificate, totals, print setup, and signature designation. Compare exported data with Python-generated output for the same sample period.

### P4 — Friendly Android UI and other workflows
- Marathi-first dashboard and mobile-friendly forms.
- Employee search and active/inactive status.
- Month/year picker with explicit selected period.
- Reports preview, Excel export/share, PDF/print, local database backup/import.
- Email settings/export only after secure credential storage and transport behavior are designed.

## Flutter Web support

Web support is **not yet implemented or build-verified**. The current code uses `sqflite`, `dart:io`, and filesystem-based imports/exports. Before enabling a web build, add a browser-compatible SQLite backend and platform-specific import/export/storage adapters, then run a Web release build in CI. Do not advertise the current ZIP as web-ready.

## Release gate
This source is an incomplete Flutter port. It is not ready for official payroll processing until the monthly snapshot, calculation, database import, six-sheet workbook, and export comparison tests pass. Flutter is not installed in the current working environment, so source edits cannot be represented as a verified APK build.

### Workbook export source update
The Flutter export source now creates all six named sheets and populates register/payment data from the selected month's persisted rows. This is an intermediate functional pass. Do not release until the workbook formatting and cell-by-cell parity items in `PARITY_MATRIX.md` are validated against the Python-generated workbook.
