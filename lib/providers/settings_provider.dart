import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers.dart';

part 'settings_provider.freezed.dart';
part 'settings_provider.g.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    required String ollamaBaseUrl,
    required String ollamaModel,
    required bool enableAi,
  }) = _SettingsState;
}

@riverpod
class Settings extends _$Settings {
  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      ollamaBaseUrl: prefs.getString('ollama_base_url') ?? 'http://localhost:11434',
      ollamaModel: prefs.getString('ollama_model') ?? 'gemma3',
      enableAi: prefs.getBool('enable_ai') ?? true,
    );
  }

  void setOllamaBaseUrl(String url) {
    if (state.ollamaBaseUrl == url) return;
    state = state.copyWith(ollamaBaseUrl: url);
    ref.read(sharedPreferencesProvider).setString('ollama_base_url', url);
  }

  void setOllamaModel(String model) {
    if (state.ollamaModel == model) return;
    state = state.copyWith(ollamaModel: model);
    ref.read(sharedPreferencesProvider).setString('ollama_model', model);
  }

  void setEnableAi(bool enabled) {
    if (state.enableAi == enabled) return;
    state = state.copyWith(enableAi: enabled);
    ref.read(sharedPreferencesProvider).setBool('enable_ai', enabled);
  }
}
