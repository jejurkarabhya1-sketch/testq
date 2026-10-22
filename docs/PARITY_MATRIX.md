# Feature parity and validation matrix

| Original capability | Flutter status in this build | Acceptance test still required |
|---|---|---|
| Login/password | Local password gate, salted SHA-256 password hash, change-password UI | Confirm password policy and imported desktop password handling; first mobile login uses `admin` |
| Employee records | Add/edit/deactivate; Marathi/English name, designation, department, gender, DOB, pay scale, salary inputs, bank fields and all eight salary/PPF account fields | Validate required fields, IFSC format, date validation, reactivation and inactive history |
| Monthly payroll | Month/year selector and per-period JSON snapshots; edits are written to selected period | Side-by-side comparison for current, past and future periods; verify employees deactivated after month close remain historically correct |
| Payroll formulas | Basic, leave/substitution salary, 10% living allowance toggle, DA, 8.33% GP share/PF, future payable, recovery days, professional tax, loans, insurance, advances, society and other deductions | Compare rounding boundaries, threshold equality, leap years, zero days, and every staff member against Python `calc` |
| Daily-wage payroll | Add employees, daily rate, absent days, gross, recovery, net and Excel export | IFSC validation, absent-day bounds, historical employee deactivation and month persistence |
| Professional tax | Threshold, below/above threshold and women amount settings | Compare all gender/threshold cases with desktop app |
| Retirement | Designation-based retirement age settings and ordered retirement schedule | Compare DOB/date edge cases, leap-day birthdays and retired status |
| Excel workbook | Six sheets: Gramnidhi register, Gramnidhi salary, Gramnidhi PPF, water supply register, water supply salary, water PPF; daily-wage export | Exact desktop workbook formatting, formulas, print layout, all footer certificates/signatures and totals are not yet verified |
| PDF/print | PDF salary summary via Android print/share | Full original register landscape print layouts, repeating headers, signature blocks and Terej sheet still need parity work |
| Email | Sender/recipient/signature settings; SMTP workbook send via Gmail App Password in Android secure storage | Test Gmail 2FA/App Password, network failures, recipient refusal and message content on a real Android device |
| Database import/backup | File picker, SQLite signature check, backup copy, open and rollback attempt | Test all desktop DB versions, schema variants, restore/reopen, row counts and settings after import |
| Multi-user | Single-device local SQLite; documented API migration path | Backend, roles, audit logs, concurrency, conflict resolution, server backups and sync are not implemented |

## Formula tests included

`test/payroll_calculation_test.dart` covers allowance/PF/tax/net calculations, threshold equality, female tax setting, recovery by days, and a non-negative net salary floor. These tests have not been executed locally because Flutter/Dart were unavailable in the build environment. GitHub Actions runs them before producing the APK.

## Release gate

Do not use this version for official salary processing until GitHub Actions succeeds and the formula, six-sheet workbook, import, monthly snapshots, bank registers, PDF print layouts, email workflow and recovery/backup paths pass documented side-by-side acceptance tests.
