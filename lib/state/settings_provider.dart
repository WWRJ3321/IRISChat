import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/services/storage_service.dart';

/// 全局设置状态。任何外观变更都会即时写盘并刷新主题。
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(StorageService.instance.loadSettings());

  Future<void> _persist(AppSettings next) async {
    state = next;
    await StorageService.instance.saveSettings(next);
  }

  Future<void> setAccentColor(int value) =>
      _persist(state.copyWith(accentColorValue: value));

  Future<void> setThemeMode(int index) =>
      _persist(state.copyWith(themeModeIndex: index));

  Future<void> setOledBlack(bool v) => _persist(state.copyWith(oledBlack: v));

  Future<void> setGlassEnabled(bool v) =>
      _persist(state.copyWith(glassEnabled: v));

  Future<void> setGlassBlur(double v) => _persist(state.copyWith(glassBlur: v));

  Future<void> setGlassOpacity(double v) =>
      _persist(state.copyWith(glassOpacity: v));

  Future<void> setWallpaper(String? path) => _persist(
        path == null
            ? state.copyWith(clearWallpaper: true)
            : state.copyWith(wallpaperPath: path),
      );

  Future<void> setWallpaperOpacity(double v) =>
      _persist(state.copyWith(wallpaperOpacity: v));

  Future<void> setFontScale(double v) => _persist(state.copyWith(fontScale: v));

  Future<void> setBubbleRadius(double v) =>
      _persist(state.copyWith(bubbleRadius: v));

  Future<void> setShowTimestamp(bool v) =>
      _persist(state.copyWith(showTimestamp: v));

  Future<void> setEnableAnimation(bool v) =>
      _persist(state.copyWith(enableAnimation: v));

  Future<void> setAnimationSpeed(double v) =>
      _persist(state.copyWith(animationSpeed: v));

  Future<void> setLanguageCode(String code) =>
      _persist(state.copyWith(languageCode: code));

  Future<void> setContextStrategy(int value) =>
      _persist(state.copyWith(contextStrategy: value));

  Future<void> setSummaryTriggerCount(int value) =>
      _persist(state.copyWith(summaryTriggerCount: value));

  Future<void> setSummaryKeepRecent(int value) =>
      _persist(state.copyWith(summaryKeepRecent: value));

  Future<void> setActiveApiProfile(String? id) =>
      _persist(state.copyWith(activeApiProfileId: id));

  Future<void> setActiveCharacter(String id) =>
      _persist(state.copyWith(activeCharacterId: id));

  Future<void> setStartNewChat(bool v) =>
      _persist(state.copyWith(startNewChat: v));

  Future<void> setThinkingEnabled(bool v) =>
      _persist(state.copyWith(thinkingEnabled: v));

  Future<void> setThinkingLevel(int v) =>
      _persist(state.copyWith(thinkingLevel: v.clamp(1, 3)));

  Future<void> reset() => _persist(AppSettings());
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});