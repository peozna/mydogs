import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/error/error_formatter.dart';
import '../domain/saved_dog.dart';
import 'gallery_controller.dart';

class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Dogs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh gallery',
            onPressed: state.isLoading
                ? null
                : () => ref.read(galleryControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                const Text(
                  'Failed to load gallery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  formatErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(galleryControllerProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (dogs) {
          if (dogs.isEmpty) {
            return const _EmptyGallery();
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 900
              ? 4
              : screenWidth > 600
              ? 3
              : 2;

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(galleryControllerProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                final dog = dogs[index];
                return _GalleryCard(savedDog: dog);
              },
            ),
          );
        },
      ),
    );
  }
}

class _GalleryCard extends ConsumerWidget {
  const _GalleryCard({required this.savedDog});

  final SavedDog savedDog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final breedName = savedDog.breeds.isNotEmpty
        ? savedDog.breeds.first.name
        : 'Unknown Breed';
    final file = File(savedDog.localImagePath);
    final fileExists = file.existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/gallery/${savedDog.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fileExists)
                    Semantics(
                      label: 'Saved photo of $breedName',
                      image: true,
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _StaleFileIndicator(),
                      ),
                    )
                  else
                    const _StaleFileIndicator(),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Colors.white,
                        ),
                        tooltip: 'Delete $breedName',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withAlpha(128),
                        ),
                        onPressed: () => _confirmDelete(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    breedName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    savedDog.savedAt.toLocal().toString().split(' ').first,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Saved Dog'),
        content: const Text(
          'Are you sure you want to permanently remove this dog from your gallery and delete the local file?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await ref
            .read(galleryControllerProvider.notifier)
            .deleteSavedDog(savedDog.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed dog from gallery.')),
          );
        }
      }
    });
  }
}

class _StaleFileIndicator extends StatelessWidget {
  const _StaleFileIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer.withAlpha(128),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image,
              color: Theme.of(context).colorScheme.error,
              size: 36,
            ),
            const SizedBox(height: 4),
            Text(
              'File Missing',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '(Tap to clear)',
              style: TextStyle(
                fontSize: 8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Saved Dogs Yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any dog in the Discovery screen to save them to your offline gallery!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
