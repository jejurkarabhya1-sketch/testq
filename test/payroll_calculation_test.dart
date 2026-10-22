import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_payroll/database.dart';

void main() {
  group('Payroll formula parity', () {
    const tax = <String, Object?>{
      'threshold': 10000,
      'below_amount': 175,
      'above_amount': 200,
      'women_amount': 0,
    };

    test('calculates living allowance, GP share, PF, tax and net salary', () {
      final result = calculate({
        'basic': 10000,
        'leave_salary': 0,
        'substitution_salary': 0,
        'living_enabled': 1,
        'da': 0,
        'gp_enabled': 1,
        'future_payable': 0,
        'recovery': 0,
        'recovery_days': 0,
        'gender': 'male',
        'loan': 0,
        'insurance': 0,
        'festival_advance': 0,
        'grain_advance': 0,
        'society': 0,
        'other': 0,
      }, tax, 30);

      expect(result['living'], 1000);
      expect(result['gp'], 833);
      expect(result['gross'], 11833);
      expect(result['professional_tax'], 175); // threshold equality uses below amount
      expect(result['pf_employee'], 833);
      expect(result['pf_employer'], 833);
      expect(result['deductions'], 1841);
      expect(result['net'], 9992);
    });

    test('uses female tax setting and calculates absence recovery by calendar month days', () {
      final result = calculate({
        'basic': 15000,
        'living_enabled': 0,
        'gp_enabled': 0,
        'gender': 'female',
        'recovery_days': 2,
        'recovery': 999,
      }, tax, 31);
      expect(result['professional_tax'], 0);
      expect(result['recovery_amount'], 967.74);
      expect(result['net'], greaterThanOrEqualTo(0));
    });

    test('never returns negative take-home pay', () {
      final result = calculate({
        'basic': 100,
        'living_enabled': 0,
        'gp_enabled': 0,
        'gender': 'male',
        'loan': 5000,
      }, tax, 30);
      expect(result['net'], 0);
    });
  });
}
