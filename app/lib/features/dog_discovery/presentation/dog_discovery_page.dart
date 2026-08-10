import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/dog_image.dart';
import 'dog_discovery_controller.dart';

class DogDiscoveryPage extends ConsumerWidget {
  const DogDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.hasApiKey) {
      return const _ConfigurationError();
    }

    final state = ref.watch(dogDiscoveryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyDogs'),
        actions: state.maybeWhen(
          data: (dogImage) => [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'New Dog',
              onPressed: () => ref
                  .read(dogDiscoveryControllerProvider.notifier)
                  .fetchNewDog(),
            ),
          ],
          orElse: () => null,
        ),
      ),
      body: state.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching a cute dog...'),
            ],
          ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Occurred',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceFirst(RegExp(r'^.*?:\s*'), ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref
                      .read(dogDiscoveryControllerProvider.notifier)
                      .fetchNewDog(),
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (dogImage) => _DogDiscoveryView(dogImage: dogImage),
      ),
      floatingActionButton: state.maybeWhen(
        data: (_) => FloatingActionButton.extended(
          onPressed: () =>
              ref.read(dogDiscoveryControllerProvider.notifier).fetchNewDog(),
          icon: const Icon(Icons.pets),
          label: const Text('New Dog'),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _DogDiscoveryView extends StatelessWidget {
  const _DogDiscoveryView({required this.dogImage});

  final DogImage dogImage;

  @override
  Widget build(BuildContext context) {
    final breed = dogImage.breeds.first;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: AspectRatio(
                aspectRatio: dogImage.width / dogImage.height,
                child: CachedNetworkImage(
                  imageUrl: dogImage.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withAlpha(128),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withAlpha(128),
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  breed.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                if (breed.breedGroup != null && breed.breedGroup!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    breed.breedGroup!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                _BreedInfoSection(
                  title: 'About the Breed',
                  icon: Icons.info_outline,
                  children: [
                    if (breed.description != null && breed.description!.isNotEmpty)
                      _InfoRow(label: 'Description', value: breed.description!),
                    if (breed.temperament != null && breed.temperament!.isNotEmpty)
                      _InfoRow(label: 'Temperament', value: breed.temperament!),
                    if (breed.lifeSpan != null && breed.lifeSpan!.isNotEmpty)
                      _InfoRow(label: 'Life Span', value: breed.lifeSpan!),
                    if (breed.origin != null && breed.origin!.isNotEmpty)
                      _InfoRow(label: 'Origin', value: breed.origin!),
                    if (breed.bredFor != null && breed.bredFor!.isNotEmpty)
                      _InfoRow(label: 'Bred For', value: breed.bredFor!),
                  ],
                ),
                const SizedBox(height: 16),
                _BreedInfoSection(
                  title: 'Physical Characteristics',
                  icon: Icons.straighten,
                  children: [
                    if (breed.heightMetric != null || breed.heightImperial != null)
                      _InfoRow(
                        label: 'Height',
                        value: '${breed.heightMetric ?? ''} cm (${breed.heightImperial ?? ''} in)',
                      ),
                    if (breed.weightMetric != null || breed.weightImperial != null)
                      _InfoRow(
                        label: 'Weight',
                        value: '${breed.weightMetric ?? ''} kg (${breed.weightImperial ?? ''} lbs)',
                      ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreedInfoSection extends StatelessWidget {
  const _BreedInfoSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 15),
          ),
        ],
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
