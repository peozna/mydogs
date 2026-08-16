import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_key_controller.dart';

/// Screen that lets the user enter, update, or clear their TheDogAPI key.
///
/// The key is persisted locally and takes effect immediately, so the app can
/// be configured at runtime without a build-time `--dart-define`.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController _controller;
  bool _obscured = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(apiKeyProvider) ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(apiKeyProvider.notifier).save(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved.')),
      );
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await ref.read(apiKeyProvider.notifier).clear();
      if (!mounted) return;
      _controller.text = ref.read(apiKeyProvider) ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key cleared.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(hasApiKeyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'TheDogAPI key',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your API key to fetch dogs. You can get a free key '
                    'at thedogapi.com.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    obscureText: _obscured,
                    enableSuggestions: false,
                    autocorrect: false,
                    autofillHints: const [],
                    decoration: InputDecoration(
                      labelText: 'API key',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscured
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        tooltip: _obscured ? 'Show key' : 'Hide key',
                        onPressed: () =>
                            setState(() => _obscured = !_obscured),
                      ),
                    ),
                    onSubmitted: (_) => _saving ? null : _save(),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  if (hasKey) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _saving ? null : _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear key'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
