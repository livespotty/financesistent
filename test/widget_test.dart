import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:financesistent/presentation/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: FinanceSistentApp(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.text('Dashboard'), findsAtLeast(1));
  });
}
