import 'package:flutter_test/flutter_test.dart';
import 'package:parentcontrol/main.dart';

void main() {
  testWidgets('Parent dashboard accurately reports no cloud connection', (tester) async {
    await tester.pumpWidget(const BilsanParentApp());
    expect(find.text('متابعة طفلتي'), findsOneWidget);
    expect(find.textContaining('الجهاز غير مربوط'), findsOneWidget);
  });
}
