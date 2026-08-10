import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mydogs/app/app.dart';

void main() {
  testWidgets('App launches and shows discovery placeholder', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyDogsApp(),
      ),
    );

    // Without an API key, the app should show the configuration error
    // rather than crashing.
    expect(find.text('API Key Required'), findsOneWidget);
    expect(find.text('MyDogs'), findsOneWidget);
  });
}