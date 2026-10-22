# Feature parity and validation matrix

| Original capability | Flutter source status | Validation still required |
|---|---|---|
| Login/password | Local password gate and change-password dialog | Existing desktop password hashes are not imported; first import initializes mobile `admin` password. Verify secure password storage policy before release. |
| Employee list / add | Implemented for common employee fields | Complete edit coverage for all original fields, validation, inactive history, gender and DOB validation |
| Separate salary/PPF accounts | UI fields included | Confirm all four account/IFSC pairs import and export correctly |
| Month/year payroll | Month/year selector | Full original per-month snapshots and month-to-month isolation are not implemented in this initial port |
| Gross, allowance, PF, deductions, net | Formula port included | Compare rounding edge cases against `app.py::calc` for all staff and month lengths |
| Recovery by days | Included | Test values, leap years, zero days and manual recovery interactions |
| Professional tax settings | Included | Test threshold equality, women amount, and negative/invalid inputs |
| Daily-wage staff and payroll | Included | Test IFSC validation, absent-day bounds, type validation and monthly persistence |
| Retirement age by designation | Basic settings editor and storage | Complete retirement schedule table, DOB validation, ordering and remaining-days display |
| Excel export | Basic one-sheet summary | Original six sheets (Gramnidhi, terej, bank, PPF and water-supply variants), formulas, headers, formatting and signatures |
| PDF/print | Basic salary summary | Original register landscape layouts, repeating headers, footer, Terej and signature role |
| Email SMTP | Not implemented in Flutter UI | Secure configuration and provider-specific SMTP support |
| Logo/watermark | Logo asset included, not yet shown as watermark | Login/app branding and print watermark |
| Legacy SQLite import | File picker, header check, backup and replace attempt | Validate import against real desktop DB variants and rollback/reopen behavior on Android devices |
| Multi-user future | Documented migration path | API/backend, user roles, audit history, concurrency, backups and sync conflict resolution |

## Baseline validation of original application

The supplied original Python application was tested with `python -m unittest -q`: **31 tests passed**. One test intentionally logs a simulated workbook failure message before the test suite reports success. This validates the source baseline only, not the Flutter implementation.

## Release gate

Do not use the Flutter app for official salary processing until the formula comparison, import verification, monthly snapshot behavior, exports, and all payroll registers have passed documented side-by-side acceptance tests.
