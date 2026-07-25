import 'package:flutter_test/flutter_test.dart';
import 'package:neno_smartlife/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NenoSmartLifeApp());
    expect(find.byType(NenoSmartLifeApp), findsOneWidget);
  });
}
