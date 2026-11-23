import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/main.dart';

void main() {
  testWidgets('Bilsan home opens an actual letters activity', (tester) async {
    await tester.pumpWidget(const BilsanKidsApp());
    expect(find.text('عالم بيلسان'), findsOneWidget);
    await tester.ensureVisible(find.text('الحروف'));
    await tester.tap(find.text('الحروف'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('الحروف الهجائية'), findsOneWidget);
    expect(find.text('أسد'), findsOneWidget);
  });
}
