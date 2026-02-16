import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current values
    final settings = ref.read(settingsProvider);
    _baseUrlController.text = settings.ollamaBaseUrl;
    _modelController.text = settings.ollamaModel;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // Update controllers if state changes externally (optional, but good practice)
    if (_baseUrlController.text != settings.ollamaBaseUrl) {
      _baseUrlController.text = settings.ollamaBaseUrl;
    }
    if (_modelController.text != settings.ollamaModel) {
      _modelController.text = settings.ollamaModel;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader(theme, 'AI Integration (Ollama)'),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Enable AI Features'),
                    subtitle: const Text('Use local LLM for auto-categorization'),
                    value: settings.enableAi,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setEnableAi(value);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Ollama Base URL',
                      helperText: 'Default: http://localhost:11434',
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: FaIcon(FontAwesomeIcons.server, size: 16),
                      ),
                    ),
                    onSubmitted: (value) {
                      ref.read(settingsProvider.notifier).setOllamaBaseUrl(value);
                    },
                    onChanged: (value) {
                       // Optional: Save on every keystroke or debounce.
                       // For now, let's rely on onSubmitted or save explicitly.
                       // Actually, better to save on focus loss or explicit button.
                       // For simplicity in this demo, let's just save on changed with debounce?
                       // Or simple "Save" button? 
                       // Let's just use onSubmitted for now, or add a save button.
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model Name',
                      helperText: 'e.g., gemma3, llama3, mistral',
                      border: OutlineInputBorder(),
                      prefixIcon: Padding(
                        padding: EdgeInsets.all(12),
                        child: FaIcon(FontAwesomeIcons.brain, size: 16),
                      ),
                    ),
                    onSubmitted: (value) {
                      ref.read(settingsProvider.notifier).setOllamaModel(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                       FilledButton.icon(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setOllamaBaseUrl(_baseUrlController.text);
                          ref.read(settingsProvider.notifier).setOllamaModel(_modelController.text);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved')),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Configuration'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          _buildSectionHeader(theme, 'About'),
          const SizedBox(height: 16),
          Card(
             elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.github),
                  title: const Text('Source Code'),
                  subtitle: const Text('View on GitHub'),
                  onTap: () {
                    // Launch URL
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.info),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0+1'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
