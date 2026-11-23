import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kidslearn/main.dart';

void main() {
  testWidgets('Bilsan home opens a real letters activity', (tester) async {
    // Test the lesson UI separately; the real app entry is guarded by server approval.
    await tester.pumpWidget(const MaterialApp(home: KidsHome()));
    expect(find.text('عالم بيلسان'), findsOneWidget);
    await tester.tap(find.text('هيا نتعلّم'));
    // Advance once to start the route transition, then complete its animation.
    // A single timed pump starts the transition but does not finish it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('الحروف الهجائية'), findsOneWidget);
    expect(find.text('أسد'), findsOneWidget);
  });
}
