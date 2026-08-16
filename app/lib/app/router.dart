import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/dog_discovery/presentation/dog_discovery_page.dart';
import '../features/gallery/presentation/gallery_page.dart';
import '../features/gallery/presentation/saved_dog_detail_page.dart';

/// Centralized route configuration for the MyDogs app.
///
/// Routes:
/// - `/` — Random Dog discovery screen
/// - `/gallery` — local gallery screen
/// - `/gallery/:id` — saved dog detail screen (Phase 5)
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'discovery',
      builder: (context, state) => const DogDiscoveryPage(),
    ),
    GoRoute(
      path: '/gallery',
      name: 'gallery',
      builder: (context, state) => const GalleryPage(),
    ),
    GoRoute(
      path: '/gallery/:id',
      name: 'saved_dog_detail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return SavedDogDetailPage(id: id);
      },
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Page Not Found')),
    body: Center(child: Text('No route found for "${state.uri}"')),
  ),
);
