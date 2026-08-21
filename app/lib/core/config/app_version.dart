import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Version shown in the UI, taken from `--dart-define=APP_VERSION=...`.
///
/// Release builds set this from the git tag that triggered the workflow
/// (e.g. `v1.0.8` → `1.0.8`). Local runs fall back to an empty string so
/// the title does not show a stale pubspec version.
const appVersionFromBuild = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '',
);

/// The version label to display next to the app name.
final appVersionProvider = Provider<String>((ref) => appVersionFromBuild);
