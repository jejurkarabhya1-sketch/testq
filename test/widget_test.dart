import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:lasalgaon_payroll/main.dart';

void main() {
  test('LasalgaonApp can be constructed as the application root', () {
    const app = LasalgaonApp();
    expect(app, isA<Widget>());
  });
}
