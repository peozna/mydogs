import 'package:flutter/material.dart';

/// Material 3 light and dark themes for the MyDogs app.
class AppTheme {
  AppTheme._();

  static const _seedColor = Colors.deepPurple;

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  static ThemeData get dark => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}