import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_payroll/database.dart';

void main() {
  const tax = <String, Object?>{
    'threshold': 10000,
    'below_amount': 175,
    'above_amount': 200,
    'women_amount': 0,
  };

  Map<String, Object?> employee({
    double basic = 10000,
    String gender = 'unspecified',
    double recoveryDays = 0,
    double recovery = 0,
  }) => {
        'id': 1,
        'name_marathi': 'Test',
        'department': 'ग्रामनिधी',
        'basic': basic,
        'leave_salary': 0,
        'substitution_salary': 0,
        'living_enabled': 1,
        'da': 0,
        'gp_enabled': 1,
        'future_payable': 0,
        'recovery': recovery,
        'recovery_days': recoveryDays,
        'loan': 0,
        'insurance': 0,
        'festival_advance': 0,
        'grain_advance': 0,
        'society': 0,
        'other': 0,
        'gender': gender,
      };

  test('professional tax uses the Python threshold rule: equality is below', () {
    final result = calculate(employee(basic: 10000), tax, 31);
    expect(result['professional_tax'], 175);
  });

  test('professional tax above threshold uses configured amount', () {
    final result = calculate(employee(basic: 10001), tax, 31);
    expect(result['professional_tax'], 200);
  });

  test('female employee uses configured women tax', () {
    final result = calculate(employee(basic: 12000, gender: 'female'), tax, 30);
    expect(result['professional_tax'], 0);
  });

  test('recovery by days uses actual month length and rounds to two decimals', () {
    final result = calculate(employee(basic: 10000, recoveryDays: 2), tax, 31);
    expect(result['recovery_amount'], closeTo((11833 / 31 * 2), 0.01));
  });

  test('manual recovery is used when recovery days are zero', () {
    final result = calculate(employee(basic: 10000, recovery: 125.5), tax, 30);
    expect(result['recovery_amount'], 125.5);
  });

  test('net salary never falls below zero', () {
    final person = employee(basic: 1000, recovery: 999999);
    final result = calculate(person, tax, 30);
    expect(result['net'], 0);
  });
}
