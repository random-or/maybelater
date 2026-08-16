import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maybelater/app.dart';

void main() {
  testWidgets('App shell renders without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MaybeLaterApp()));
    await tester.pumpAndSettle();

    // Verify the app shell is rendered.
    expect(find.byType(MaybeLaterApp), findsOneWidget);
  });
}
