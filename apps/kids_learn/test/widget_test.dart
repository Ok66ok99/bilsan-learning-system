import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/main.dart';

void main() {
  testWidgets('Bilsan home opens a real letters activity', (tester) async {
    await tester.pumpWidget(const BilsanKidsApp());
    expect(find.text('عالم بيلسان'), findsOneWidget);
    await tester.tap(find.text('هيا نتعلّم'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('الحروف الهجائية'), findsOneWidget);
    expect(find.text('أسد'), findsOneWidget);
  });
}
