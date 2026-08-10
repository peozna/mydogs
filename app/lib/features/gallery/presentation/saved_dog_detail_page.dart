import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/saved_dog.dart';
import 'gallery_controller.dart';

final savedDogByIdProvider = Provider.family.autoDispose<SavedDog?, String>((ref, id) {
  final galleryState = ref.watch(galleryControllerProvider);
  return galleryState.maybeWhen(
    data: (list) {
      final matches = list.where((dog) => dog.id == id);
      return matches.isNotEmpty ? matches.first : null;
    },
    orElse: () => null,
  );
});

class SavedDogDetailPage extends ConsumerWidget {
  const SavedDogDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedDog = ref.watch(savedDogByIdProvider(id));

    if (savedDog == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(
          child: Text('Saved dog not found or has been deleted.'),
        ),
      );
    }

    final breed = savedDog.breeds.isNotEmpty ? savedDog.breeds.first : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(breed?.name ?? 'Dog Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete saved dog',
            onPressed: () => _confirmDeletion(context, ref, savedDog),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  aspectRatio: savedDog.width / savedDog.height,
                  child: Image.file(
                    File(savedDog.localImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withAlpha(128),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 64, color: Colors.red),
                            SizedBox(height: 12),
                            Text(
                              'Local file missing or corrupt',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (breed != null) ...[
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
                    _InfoSection(
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
                    _InfoSection(
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
                  ] else ...[
                    Text(
                      'Unknown Breed',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('No breed details were available when this dog was saved.'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _InfoSection(
                    title: 'Storage Snapshot',
                    icon: Icons.folder_open,
                    children: [
                      _InfoRow(label: 'Original API ID', value: savedDog.id),
                      _InfoRow(label: 'Original URL', value: savedDog.url),
                      _InfoRow(label: 'Local File Path', value: savedDog.localImagePath),
                      _InfoRow(
                        label: 'Saved On',
                        value: savedDog.savedAt.toLocal().toString().split('.').first,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(BuildContext context, WidgetRef ref, SavedDog savedDog) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Saved Dog'),
        content: const Text(
          'Are you sure you want to permanently remove this dog from your offline gallery and delete the local file?',
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
        // Go back to gallery first, then delete, to ensure UI context remains valid
        if (context.mounted) {
          context.pop();
          await ref.read(galleryControllerProvider.notifier).deleteSavedDog(savedDog.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed dog from gallery.')),
            );
          }
        }
      }
    });
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
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
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
