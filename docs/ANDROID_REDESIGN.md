# Android-first UI redesign (Fix6)

## Design intent
- Marathi-first, touch-friendly Material 3 interface with a warm neutral canvas, deep burgundy brand colour and restrained brass accents.
- Responsive navigation: five concise destinations on phones, with Reports and Settings in a labelled More sheet; six-destination NavigationRail on wider screens.
- Compact app bar with logo, current section and month/year pickers.
- Redesigned login with logo, clearer password interaction, visibility toggle, busy state and readable errors.
- Dashboard prioritizes selected period, estimated net payroll, employee counts and quick routes into payroll, staff, daily wages and reports.
- Cards, controls, buttons and form fields share consistent spacing, rounded corners, contrast and touch targets.

## Payroll logic and existing workflows retained
The redesign changes presentation and navigation only. It retains the existing Flutter database/API calls and calculation helper rather than replacing payroll logic. The source Python `app.py` remains the behavioral reference for gross pay, living allowance, GP/PF calculation, recovery by days, professional tax, deductions and net-pay rounding.

## Source-of-truth review
The original Python app has monthly payroll snapshots (`payroll_periods` / `payroll_entries`), daily-wage employees and per-month rate/absence records, professional-tax settings, retirement-age settings, password/session logic, SMTP email settings, and a six-sheet formatted workbook with department salary/tereJ/bank/PPF registers. The current Flutter parity matrix documents which of these are only partial or not yet implemented in the mobile port. UI redesign must not be interpreted as completion of those parity gaps.

## Verification status
- Original Python baseline: `python -m unittest -q` — 31 tests passed on 2026-10-22.
- Archive integrity: validated after packaging.
- Flutter analyze / flutter test / APK build for this redesigned revision: not run in this environment because the Flutter SDK is unavailable here. Use the repository's GitHub Actions workflow to verify this revision before official payroll use.

## Release gates still required
1. Compare Flutter calculations against Python `calc` for both departments, every month length, threshold equality, female professional tax, recovery days and rounding boundaries.
2. Implement and validate monthly snapshot isolation, rather than recalculating historical periods from current employee data.
3. Match all six workbook sheets, formatting, bank/PPF account variants, register footers and print layouts.
4. Validate import/rollback using a copy of the real desktop SQLite database; never test against the only production copy.
5. Validate password hash compatibility, SMTP settings/email delivery, retirement-age schedule and backup restore.
