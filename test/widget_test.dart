import 'package:flutter_test/flutter_test.dart';
import 'package:book_app/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const GrowthCompanionApp());
    expect(find.byType(GrowthCompanionApp), findsOneWidget);
  });
}
