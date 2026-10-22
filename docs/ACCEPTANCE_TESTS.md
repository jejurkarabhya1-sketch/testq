# Android acceptance checklist

Run these checks on a test copy of the database before official payroll use.

## Install and security
- [ ] GitHub Actions completes analysis, tests, and release APK build.
- [ ] Install APK on a clean Android device; launch, sign in with `admin`, change password, restart and verify the new password.
- [ ] Confirm payroll data stays in app-private storage and is not bundled in the APK or Git repository.
- [ ] Export a database backup; import a copy and verify rollback after intentionally selecting an invalid/non-payroll SQLite file.

## Employee and monthly payroll
- [ ] Compare every employee's fields and all eight department-specific salary/PPF account fields after importing a desktop database.
- [ ] Compare a month with all allowances/deductions disabled, then enabled, against desktop `calc` results.
- [ ] Test professional-tax values below, equal to and above the threshold, including female employee settings.
- [ ] Test recovery by days for 28-, 29-, 30- and 31-day months.
- [ ] Edit a salary in one month, switch month, and confirm the other month is not changed.
- [ ] Deactivate an employee and verify historical closed payroll remains correct and current-month payroll reflects the deactivation.

## Daily-wage staff
- [ ] Add a daily-wage employee with a valid IFSC and reject an invalid IFSC.
- [ ] Test zero, fractional and maximum absent-day values.
- [ ] Change daily rate and absent days in one month; confirm another month remains unchanged.

## Reports and email
- [ ] Compare all six Excel sheets against the original workbook for names, account numbers, IFSC, amounts, totals and row order.
- [ ] Verify Excel output in Microsoft Excel/LibreOffice; check headers, print setup, formulas, footer certificates and signatures.
- [ ] Verify PDF Marathi glyph rendering on Android and a printed copy.
- [ ] Configure a Gmail App Password and send the workbook to a test recipient; verify attachment opens and errors are surfaced on network/authentication failures.
- [ ] Test backup/restore after an app restart.

## Release decision
Do not use for official payroll until every applicable item passes and the approver records the tested database version, month/year and workbook comparison results.
