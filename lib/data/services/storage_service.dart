import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/api_profile.dart';
import '../models/app_settings.dart';
import '../models/character_card.dart';
import '../models/conversation.dart';
import '../models/multi_ai_chat.dart';

/// 本地存储。
///
/// 采用「Hive box + JSON 字符串」的方式，不依赖 code generation，
/// 这样模型改字段时不用重新跑 build_runner，工程更精简。
class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const _boxConversations = 'conversations';
  static const _boxCharacters = 'characters';
  static const _boxApiProfiles = 'api_profiles';
  static const _boxSettings = 'settings';
  static const _boxMultiAiChats = 'multi_ai_chats';

  static const _keyDismissedBuiltIn = 'dismissed_builtin_chars';

  late Box<String> _conversations;
  late Box<String> _characters;
  late Box<String> _apiProfiles;
  late Box<String> _settings;
  late Box<String> _multiAiChats;

  bool _ready = false;
  bool get isReady => _ready;

  /// 应用私有目录，用于存放头像/壁纸副本
  Directory? _mediaDir;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _conversations = await Hive.openBox<String>(_boxConversations);
    _characters = await Hive.openBox<String>(_boxCharacters);
    _apiProfiles = await Hive.openBox<String>(_boxApiProfiles);
    _settings = await Hive.openBox<String>(_boxSettings);
    _multiAiChats = await Hive.openBox<String>(_boxMultiAiChats);

    // 首次启动写入内置角色卡
    if (_characters.isEmpty) {
      for (final c in CharacterCard.builtIns()) {
        await saveCharacter(c);
      }
    } else {
      // 版本升级补齐新增的内置角色卡（如 1.1.0 引入的虹月）。
      // 用户主动删除过的内置角色卡不会被恢复。
      final dismissed = _dismissedBuiltInIds;
      for (final c in CharacterCard.builtIns()) {
        if (!_characters.containsKey(c.id) && !dismissed.contains(c.id)) {
          await saveCharacter(c);
        }
      }
    }

    // 清理超过保留期的回收站条目
    await purgeExpiredTrash();

    _ready = true;
  }

  // ------------------------------------------------------------ 媒体文件

  /// 把外部选中的图片复制进应用私有目录，避免原文件被删导致头像丢失。
  Future<String?> importMedia(String sourcePath, {String prefix = 'img'}) async {
    try {
      _mediaDir ??= Directory(
        '${(await getApplicationDocumentsDirectory()).path}/media',
      );
      if (!await _mediaDir!.exists()) {
        await _mediaDir!.create(recursive: true);
      }
      final src = File(sourcePath);
      if (!await src.exists()) return null;

      final ext = sourcePath.contains('.')
          ? sourcePath.substring(sourcePath.lastIndexOf('.'))
          : '.png';
      final dest =
          '${_mediaDir!.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
      await src.copy(dest);
      return dest;
    } catch (_) {
      // 复制失败时退回原路径，至少当次可用
      return sourcePath;
    }
  }

  /// 删除应用私有目录里的媒体文件（换头像/移除壁纸时清理）
  Future<void> deleteMedia(String? path) async {
    if (path == null || path.isEmpty) return;
    _mediaDir ??= Directory(
      '${(await getApplicationDocumentsDirectory()).path}/media',
    );
    if (!path.startsWith(_mediaDir!.path)) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ------------------------------------------------------------ 会话

  List<Conversation> _decodeAll() {
    final list = <Conversation>[];
    for (final raw in _conversations.values) {
      try {
        list.add(
          Conversation.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        );
      } catch (_) {
        // 单条损坏不影响整体加载
      }
    }
    return list;
  }

  /// 正常会话列表（不含回收站），置顶优先、按更新时间倒序。
  List<Conversation> loadConversations() {
    final list = _decodeAll().where((c) => !c.isDeleted).toList();
    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  /// 回收站列表，按删除时间倒序（最近删的在前）。
  List<Conversation> loadTrash() {
    final list = _decodeAll().where((c) => c.isDeleted).toList();
    list.sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return list;
  }

  Future<void> saveConversation(Conversation c) =>
      _conversations.put(c.id, jsonEncode(c.toJson()));

  /// 软删除：移入回收站，保留 30 天。
  Future<void> moveToTrash(String id) async {
    final raw = _conversations.get(id);
    if (raw == null) return;
    try {
      final c = Conversation.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      c.deletedAt = DateTime.now();
      c.pinned = false; // 进回收站就不再置顶
      await saveConversation(c);
    } catch (_) {}
  }

  /// 从回收站恢复。
  Future<void> restoreFromTrash(String id) async {
    final raw = _conversations.get(id);
    if (raw == null) return;
    try {
      final c = Conversation.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
      c.deletedAt = null;
      c.updatedAt = DateTime.now();
      await saveConversation(c);
    } catch (_) {}
  }

  /// 彻底删除单条（不可恢复）。
  Future<void> deleteConversation(String id) => _conversations.delete(id);

  /// 清空回收站。
  Future<void> emptyTrash() async {
    for (final c in loadTrash()) {
      await _conversations.delete(c.id);
    }
  }

  /// 清理超过保留期的回收站条目。启动时自动调用。
  Future<int> purgeExpiredTrash() async {
    var count = 0;
    for (final c in _decodeAll()) {
      if (c.isTrashExpired) {
        await _conversations.delete(c.id);
        count++;
      }
    }
    return count;
  }

  /// 清空全部会话（含回收站）。
  Future<void> clearConversations() => _conversations.clear();

  // ------------------------------------------------------------ 角色卡

  List<CharacterCard> loadCharacters() {
    final list = <CharacterCard>[];
    for (final raw in _characters.values) {
      try {
        list.add(
          CharacterCard.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        );
      } catch (_) {}
    }
    list.sort((a, b) {
      if (a.isBuiltIn != b.isBuiltIn) return a.isBuiltIn ? -1 : 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  Future<void> saveCharacter(CharacterCard c) =>
      _characters.put(c.id, jsonEncode(c.toJson()));

  Future<void> deleteCharacter(String id) {
    // 记录用户主动删除的内置角色 id，避免下次启动时被补齐逻辑恢复
    final builtInIds = CharacterCard.builtIns().map((e) => e.id).toSet();
    if (builtInIds.contains(id)) {
      final ids = _dismissedBuiltInIds..add(id);
      _settings.put(_keyDismissedBuiltIn, jsonEncode(ids));
    }
    return _characters.delete(id);
  }

  /// 用户主动删除过的内置角色卡 id 集合
  Set<String> get _dismissedBuiltInIds {
    final raw = _settings.get(_keyDismissedBuiltIn) as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as List).map((e) => e as String).toSet();
    } catch (_) {
      return {};
    }
  }

  // ------------------------------------------------------------ API 配置

  List<ApiProfile> loadApiProfiles() {
    final list = <ApiProfile>[];
    for (final raw in _apiProfiles.values) {
      try {
        list.add(
          ApiProfile.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
          ),
        );
      } catch (_) {}
    }
    return list;
  }

  Future<void> saveApiProfile(ApiProfile p) =>
      _apiProfiles.put(p.id, jsonEncode(p.toJson()));

  Future<void> deleteApiProfile(String id) => _apiProfiles.delete(id);

  // ------------------------------------------------------------ 多 AI 群聊

  List<MultiAiChat> loadMultiAiChats() {
    final list = <MultiAiChat>[];
    for (final raw in _multiAiChats.values) {
      try {
        list.add(MultiAiChat.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        ));
      } catch (_) {}
    }
    return list;
  }

  Future<void> saveMultiAiChat(MultiAiChat chat) =>
      _multiAiChats.put(chat.id, jsonEncode(chat.toJson()));

  Future<void> deleteMultiAiChat(String id) => _multiAiChats.delete(id);

  // ------------------------------------------------------------ 设置

  AppSettings loadSettings() {
    final raw = _settings.get('app');
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings s) =>
      _settings.put('app', jsonEncode(s.toJson()));

  // ------------------------------------------------------------ 导入导出

  /// 导出全部数据为 JSON 字符串（备份用）
  String exportAll() {
    return jsonEncode({
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': loadSettings().toJson(),
      'characters': loadCharacters().map((e) => e.toJson()).toList(),
      'apiProfiles': loadApiProfiles().map((e) => e.toJson()).toList(),
      'conversations': _decodeAll().map((e) => e.toJson()).toList(),
    });
  }

  /// 从备份 JSON 恢复。[merge] 为 false 时先清空原有数据。
  Future<void> importAll(String raw, {bool merge = true}) async {
    final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (!merge) {
      await _conversations.clear();
      await _characters.clear();
      await _apiProfiles.clear();
    }

    for (final c in (json['characters'] as List? ?? [])) {
      await saveCharacter(
        CharacterCard.fromJson(Map<String, dynamic>.from(c as Map)),
      );
    }
    for (final p in (json['apiProfiles'] as List? ?? [])) {
      await saveApiProfile(
        ApiProfile.fromJson(Map<String, dynamic>.from(p as Map)),
      );
    }
    for (final c in (json['conversations'] as List? ?? [])) {
      await saveConversation(
        Conversation.fromJson(Map<String, dynamic>.from(c as Map)),
      );
    }
    if (json['settings'] != null) {
      await saveSettings(
        AppSettings.fromJson(
          Map<String, dynamic>.from(json['settings'] as Map),
        ),
      );
    }

    // 导入后确保内置角色卡仍在（用户主动删除过的不恢复）
    final dismissed = _dismissedBuiltInIds;
    for (final c in CharacterCard.builtIns()) {
      if (!_characters.containsKey(c.id) && !dismissed.contains(c.id)) {
        await saveCharacter(c);
      }
    }
  }
}