import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/api_profile.dart';
import '../data/models/character_card.dart';
import '../data/models/multi_ai_chat.dart';
import '../data/services/chat_service.dart';
import '../data/services/storage_service.dart';
import 'settings_provider.dart';

// ---------------------------------------------------------------- 角色卡

class CharactersNotifier extends StateNotifier<List<CharacterCard>> {
  CharactersNotifier() : super(StorageService.instance.loadCharacters());

  Future<void> add(CharacterCard c) async {
    await StorageService.instance.saveCharacter(c);
    state = StorageService.instance.loadCharacters();
  }

  Future<void> update(CharacterCard c) async {
    await StorageService.instance.saveCharacter(c);
    state = StorageService.instance.loadCharacters();
  }

  Future<void> remove(String id) async {
    await StorageService.instance.deleteCharacter(id);
    state = StorageService.instance.loadCharacters();
  }

  CharacterCard? byId(String? id) {
    if (id == null) return null;
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }
}

final charactersProvider =
    StateNotifierProvider<CharactersNotifier, List<CharacterCard>>((ref) {
  return CharactersNotifier();
});

/// 当前激活的角色卡（找不到则退回内置默认）
final activeCharacterProvider = Provider<CharacterCard>((ref) {
  final settings = ref.watch(settingsProvider);
  final chars = ref.watch(charactersProvider);
  for (final c in chars) {
    if (c.id == settings.activeCharacterId) return c;
  }
  return chars.isNotEmpty ? chars.first : CharacterCard.irisCard();
});

// ---------------------------------------------------------------- API 配置

class ApiProfilesNotifier extends StateNotifier<List<ApiProfile>> {
  ApiProfilesNotifier() : super(StorageService.instance.loadApiProfiles());

  Future<void> add(ApiProfile p) async {
    await StorageService.instance.saveApiProfile(p);
    state = StorageService.instance.loadApiProfiles();
  }

  Future<void> update(ApiProfile p) async {
    await StorageService.instance.saveApiProfile(p);
    state = StorageService.instance.loadApiProfiles();
  }

  Future<void> remove(String id) async {
    await StorageService.instance.deleteApiProfile(id);
    state = StorageService.instance.loadApiProfiles();
  }
}

final apiProfilesProvider =
    StateNotifierProvider<ApiProfilesNotifier, List<ApiProfile>>((ref) {
  return ApiProfilesNotifier();
});

/// 当前激活的 API 配置，未配置时为 null
final activeApiProfileProvider = Provider<ApiProfile?>((ref) {
  final settings = ref.watch(settingsProvider);
  final profiles = ref.watch(apiProfilesProvider);
  if (profiles.isEmpty) return null;
  for (final p in profiles) {
    if (p.id == settings.activeApiProfileId) return p;
  }
  return profiles.first;
});

// ---------------------------------------------------------------- 服务

class MultiAiChatsNotifier extends StateNotifier<List<MultiAiChat>> {
  MultiAiChatsNotifier() : super(StorageService.instance.loadMultiAiChats());

  Future<void> add(MultiAiChat chat) async {
    await StorageService.instance.saveMultiAiChat(chat);
    state = StorageService.instance.loadMultiAiChats();
  }

  Future<void> update(MultiAiChat chat) async {
    if (chat.enabled) {
      for (final other in state) {
        if (other.id != chat.id && other.enabled) {
          await StorageService.instance.saveMultiAiChat(
            other.copyWith(enabled: false),
          );
        }
      }
    }
    await StorageService.instance.saveMultiAiChat(chat);
    state = StorageService.instance.loadMultiAiChats();
  }

  Future<void> remove(String id) async {
    await StorageService.instance.deleteMultiAiChat(id);
    state = StorageService.instance.loadMultiAiChats();
  }
}

final multiAiChatsProvider =
    StateNotifierProvider<MultiAiChatsNotifier, List<MultiAiChat>>((ref) {
  return MultiAiChatsNotifier();
});

final activeMultiAiChatProvider = Provider<MultiAiChat?>((ref) {
  final chats = ref.watch(multiAiChatsProvider);
  for (final chat in chats) {
    if (chat.enabled) return chat;
  }
  return null;
});

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());