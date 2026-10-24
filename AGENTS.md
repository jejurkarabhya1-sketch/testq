# Lasalgaon Payroll Android Port — Agent Instructions

## Source of truth
- The original Python application is `Grampanchayat-main/app.py` and its SQLite schema in `Grampanchayat-main/data/payroll.db`.
- Do not replace payroll rules with guessed or simplified calculations.
- Preserve the six workbook outputs and month/year-specific payroll snapshots.
- Never commit real payroll database files or employee/bank information to GitHub.

## Required workflow
1. Read `docs/PARITY_MATRIX.md` and `docs/IMPLEMENTATION_PLAN.md` before changing features.
2. Compare each rule with the Python implementation, especially `calc`, `period_rows`, `save_period_cell`, `daily_wage_rows`, `retirement_schedule`, and `generate_salary_workbook`.
3. Keep SQLite local-first; import the desktop `payroll.db` through an explicit backup-and-rollback flow.
4. Add tests for every payroll rule and workbook sheet. Compare sample results against Python outputs.
5. Do not call a build successful unless `flutter analyze`, `flutter test`, and `flutter build apk --release` actually pass in an environment with Flutter installed.

## Payroll correctness requirements
- Month/year changes must load that period's saved snapshots; editing October must not overwrite September.
- Employee identity and bank details must remain linked to the same employee; preserve all four salary/PPF account+IFSC pairs.
- Preserve Python rounding, professional-tax threshold behavior, recovery-by-days formula, daily-wage rules, and retirement-age defaults.
- Excel export must generate the same six sheets, row ordering, totals, headers, and signature role as Python.
- Any schema change must be versioned and tested against a copy of the supplied desktop database.
