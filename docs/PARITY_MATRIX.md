# Feature parity and validation matrix

| Original capability | Flutter source status | Validation still required |
|---|---|---|
| Login/password | Local password gate and change-password dialog | Existing desktop password hashes are not imported; first import initializes mobile `admin` password. Verify secure password storage policy before release. |
| Employee list / add | Implemented for common employee fields | Complete edit coverage for all original fields, validation, inactive history, gender and DOB validation |
| Separate salary/PPF accounts | UI fields included | Confirm all four account/IFSC pairs import and export correctly |
| Month/year payroll | Month/year snapshots now stored in `payroll_entries` and salary edits target the selected snapshot | Needs automated side-by-side tests for month isolation and employee deactivation semantics |
| Gross, allowance, PF, deductions, net | Formula port included | Compare rounding edge cases against `app.py::calc` for all staff and month lengths |
| Recovery by days | Included | Test values, leap years, zero days and manual recovery interactions |
| Professional tax settings | Included | Test threshold equality, women amount, and negative/invalid inputs |
| Daily-wage staff and payroll | Included | Test IFSC validation, absent-day bounds, type validation and monthly persistence |
| Retirement age by designation | Basic settings editor and storage | Complete retirement schedule table, DOB validation, ordering and remaining-days display |
| Excel export | Basic one-sheet summary | Six named sheets and the original 26-column register structure are present. Register/bank title merges, header styling and column widths added in the latest source revision. Exact output comparison, borders, number formats, print setup, and signature-role parity remain pending |
| PDF/print | Basic salary summary | Original register landscape layouts, repeating headers, footer, Terej and signature role |
| Email SMTP | Not implemented in Flutter UI | Secure configuration and provider-specific SMTP support |
| Logo/watermark | Logo asset included, not yet shown as watermark | Login/app branding and print watermark |
| Legacy SQLite import | Staged import checks SQLite header, `integrity_check`, required tables and non-empty employee records; preserves timestamped backup and attempts rollback | Must test on Android with a disposable copy of the real DB, including migration/reopen failures |
| Multi-user future | Documented migration path | API/backend, user roles, audit history, concurrency, backups and sync conflict resolution |

## Baseline validation of original application

The supplied original Python application was tested with `python -m unittest -q`: **31 tests passed**. One test intentionally logs a simulated workbook failure message before the test suite reports success. This validates the source baseline only, not the Flutter implementation.

## Flutter Web status

Not supported in this source revision. `dart:io`, path-based file operations, and the mobile SQLite plugin require web-specific adapters before a browser build can pass.

## Release gate

Do not use the Flutter app for official salary processing until the formula comparison, import verification, monthly snapshot behavior, exports, and all payroll registers have passed documented side-by-side acceptance tests.

## Workbook milestone (source implementation; build verification pending)

The Excel export now constructs the six named workbook sheets from the selected month's saved payroll rows:

1. `ग्रामनिधी`
2. `Gramnidhi Salary`
3. `Maharashtra Bank Gramnidhi PPF`
4. `पाणी पुरवठा `
5. `पाणी पुरवठा Salary`
6. `Maha Bank पाणी पुरवठा PPF`

The two register sheets include the original 26-column register structure, calculated payroll values, a total row, a Gramnidhi department summary, the sanctioned-staff and essential-services categories, and certificate/signature text. The four payment sheets use separate salary and PPF account/IFSC fields by department. The original Python workbook writes calculated values rather than live Excel formulas, so the Flutter export follows that model.

**Not yet release-verified:** exact cell-by-cell comparison against a Python-generated workbook, border and number-format parity, print setup, signature-role parity, and all bank-account fixtures. The original Python generator embeds the Terej summary in the Gramnidhi register; it does not create a seventh standalone worksheet. Flutter analysis, tests, Android build and Web build must still run in CI before this can be considered verified.


## Latest workbook formatting pass

See [WORKBOOK_FORMATTING_UPDATE.md](WORKBOOK_FORMATTING_UPDATE.md). This source pass adds merged title rows, typography, header fills, wrapping, and explicit column widths for register and bank/PPF sheets. These changes are not compile-verified until Flutter CI runs.
