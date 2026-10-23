import 'package:flutter_test/flutter_test.dart';
import 'package:lasalgaon_payroll/main.dart';

void main() {
  testWidgets('app opens to the Lasalgaon payroll login screen', (tester) async {
    await tester.pumpWidget(const LasalgaonApp());

    expect(find.text('लासलगाव ग्रामपंचायत'), findsOneWidget);
    expect(find.text('वेतन व्यवस्थापन प्रणाली'), findsOneWidget);
    expect(find.text('सुरक्षित लॉगिन'), findsOneWidget);
  });
}
