import 'package:flutter/material.dart';

/// Placeholder gallery page for Phase 1.
///
/// Will be replaced with the full gallery UI in Phase 5.
class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 64),
            SizedBox(height: 16),
            Text('Saved Dogs Gallery'),
            SizedBox(height: 8),
            Text(
              'Coming in Phase 5',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}