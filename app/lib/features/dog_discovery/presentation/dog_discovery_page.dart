import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/api_key_controller.dart';
import '../../../core/error/error_formatter.dart';
import '../../gallery/data/gallery_repository.dart';
import '../domain/dog_image.dart';
import 'dog_discovery_controller.dart';

final isDogSavedProvider = FutureProvider.family<bool, String>((ref, id) {
  final repo = ref.watch(galleryRepositoryProvider);
  return repo.isSaved(id);
});

final isSavingDogProvider = StateProvider.autoDispose<bool>((ref) => false);

class DogDiscoveryPage extends ConsumerWidget {
  const DogDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(hasApiKeyProvider)) {
      return const _ConfigurationError();
    }

    final state = ref.watch(dogDiscoveryControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyDogs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'View Gallery',
            onPressed: () => context.push('/gallery'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          ...state.maybeWhen(
            data: (dogImage) => [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Fetch a new dog',
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(dogDiscoveryControllerProvider.notifier)
                        .fetchNewDog(),
              ),
            ],
            orElse: () => [],
          ),
        ],
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      formatErrorMessage(error),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
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
          onPressed: isLoading
              ? null
              : () => ref
                  .read(dogDiscoveryControllerProvider.notifier)
                  .fetchNewDog(),
          icon: const Icon(Icons.pets),
          label: const Text('New Dog'),
        ),
        orElse: () => null,
      ),
    );
  }
}

class _DogDiscoveryView extends ConsumerWidget {
  const _DogDiscoveryView({required this.dogImage});

  final DogImage dogImage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breed = dogImage.breeds.first;
    final isSavedAsync = ref.watch(isDogSavedProvider(dogImage.id));
    final isSaving = ref.watch(isSavingDogProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dogDiscoveryControllerProvider.notifier).fetchNewDog(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
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
                      child: Semantics(
                        label: 'Photo of a ${breed.name} dog',
                        image: true,
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
                            color: Theme.of(
                              context,
                            ).colorScheme.errorContainer.withAlpha(128),
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      isSavedAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                        data: (isSaved) {
                          if (isSaved) {
                            return OutlinedButton.icon(
                              onPressed: null,
                              icon: Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: const Text('Saved to Gallery'),
                            );
                          }

                          return ElevatedButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    ref
                                        .read(isSavingDogProvider.notifier)
                                        .state = true;
                                    try {
                                      await ref
                                          .read(galleryRepositoryProvider)
                                          .saveDog(dogImage);
                                      ref.invalidate(
                                        isDogSavedProvider(dogImage.id),
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Saved to offline gallery!',
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              formatErrorMessage(e),
                                            ),
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.error,
                                          ),
                                        );
                                      }
                                    } finally {
                                      ref
                                          .read(
                                            isSavingDogProvider.notifier,
                                          )
                                          .state = false;
                                    }
                                  },
                            icon: isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.favorite),
                            label: Text(
                              isSaving ? 'Saving...' : 'Save to Gallery',
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        breed.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      if (breed.breedGroup != null &&
                          breed.breedGroup!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          breed.breedGroup!,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _BreedInfoSection(
                        title: 'About the Breed',
                        icon: Icons.info_outline,
                        children: [
                          if (breed.description != null &&
                              breed.description!.isNotEmpty)
                            _InfoRow(
                              label: 'Description',
                              value: breed.description!,
                            ),
                          if (breed.temperament != null &&
                              breed.temperament!.isNotEmpty)
                            _InfoRow(
                              label: 'Temperament',
                              value: breed.temperament!,
                            ),
                          if (breed.lifeSpan != null &&
                              breed.lifeSpan!.isNotEmpty)
                            _InfoRow(
                              label: 'Life Span',
                              value: breed.lifeSpan!,
                            ),
                          if (breed.origin != null && breed.origin!.isNotEmpty)
                            _InfoRow(label: 'Origin', value: breed.origin!),
                          if (breed.bredFor != null &&
                              breed.bredFor!.isNotEmpty)
                            _InfoRow(label: 'Bred For', value: breed.bredFor!),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _BreedInfoSection(
                        title: 'Physical Characteristics',
                        icon: Icons.straighten,
                        children: [
                          if (breed.heightMetric != null ||
                              breed.heightImperial != null)
                            _InfoRow(
                              label: 'Height',
                              value:
                                  '${breed.heightMetric ?? ''} cm (${breed.heightImperial ?? ''} in)',
                            ),
                          if (breed.weightMetric != null ||
                              breed.weightImperial != null)
                            _InfoRow(
                              label: 'Weight',
                              value:
                                  '${breed.weightMetric ?? ''} kg (${breed.weightImperial ?? ''} lbs)',
                            ),
                        ],
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
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
                'Add your TheDogAPI key to start discovering dogs.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings),
                label: const Text('Configure API Key'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
