import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root widget for the MyDogs app.
///
/// Wraps the app in [ProviderScope] (via main.dart), applies Material 3
/// light/dark themes, and connects the centralized [router].
class MyDogsApp extends ConsumerWidget {
  const MyDogsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MyDogs',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}