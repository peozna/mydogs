import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';

/// Placeholder discovery page for Phase 1.
///
/// Shows a configuration error if no API key is provided, otherwise a
/// placeholder that will be replaced with the full discovery UI in Phase 3.
class DogDiscoveryPage extends ConsumerWidget {
  const DogDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.hasApiKey) {
      return const _ConfigurationError();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('MyDogs')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 64),
            SizedBox(height: 16),
            Text('Random Dog Discovery'),
            SizedBox(height: 8),
            Text(
              'Coming in Phase 3',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigurationError extends StatelessWidget {
  const _ConfigurationError();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyDogs')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'API Key Required',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Launch the app with:\n'
                'flutter run --dart-define=DOG_API_KEY=your-key',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
