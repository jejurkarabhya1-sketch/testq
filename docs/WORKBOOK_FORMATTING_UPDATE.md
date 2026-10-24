# Workbook formatting update

## Changes in this source revision

- Register worksheet title rows are merged across columns A:Z.
- Register title rows use centered Arial typography and dark-green title color.
- Register column headers use a pale-green fill, bold text, centered alignment, and wrapping.
- Register column widths are explicitly set, with wider employee-name/designation/pay-scale columns.
- Bank and PPF worksheets merge the two heading rows across A:G.
- Bank/PPF title rows use centered typography; column headers use dark-green fill with white bold text.
- Bank/PPF column widths are explicitly set to fit account numbers and names.

## Important limitations

This is an incremental formatting improvement, not proof of exact visual parity with the Python-generated workbook. Full cell-by-cell comparison, border and number-format parity, print settings, and signature-role parity remain release gates. The Flutter/Dart SDK was not available in the editing environment, so compile/test/build validation must be performed by GitHub Actions before using this revision for payroll.
