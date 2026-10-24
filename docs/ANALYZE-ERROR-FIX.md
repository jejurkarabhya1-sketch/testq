# Flutter analyzer error repair

## Changes

- Rewrote the salary-edit dialog with balanced widget constructors and a typed patch map.
- Rewrote the employee bank-detail dialog with balanced widget constructors.
- Restored top-level class boundaries for `PayrollScreen`, `EmployeesScreen`, `DailyScreen`, `ReportsScreen`, and `SettingsScreen` so screen classes are not parsed as nested declarations.
- Hid the Excel package's `Border` symbol to remove the name collision with Flutter Material's `Border`.

## Validation honesty

This workspace does not have the Flutter/Dart SDK installed and network DNS access to SDK downloads is unavailable. Therefore `dart format`, `flutter analyze`, `flutter test`, and release builds have not been run here. The patch addresses the errors visible in the supplied analyzer log, but must be confirmed by GitHub Actions before it is considered build-verified.
