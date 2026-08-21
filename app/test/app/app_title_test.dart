import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydogs/app/app_title.dart';
import 'package:mydogs/core/config/app_version.dart';

void main() {
  testWidgets('shows app name with a small version beside it', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appVersionProvider.overrideWithValue('1.0.8')],
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(title: const AppTitle())),
        ),
      ),
    );

    expect(find.text('MyDogs'), findsOneWidget);
    expect(find.text('1.0.8'), findsOneWidget);
  });

  testWidgets('hides version when it is not configured', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appVersionProvider.overrideWithValue('')],
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(title: const AppTitle())),
        ),
      ),
    );

    expect(find.text('MyDogs'), findsOneWidget);
    expect(find.text('1.0.8'), findsNothing);
  });
}
