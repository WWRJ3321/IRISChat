import 'package:uuid/uuid.dart';

import 'character_card.dart';

const _multiAiUuid = Uuid();

enum MultiAiReplyMode { roundRobin, random }

/// 多 AI 群聊配置。成员仍复用已有角色卡，避免复制人格数据。
class MultiAiChat {
  MultiAiChat({
    String? id,
    this.name = '新群聊',
    List<String>? characterIds,
    this.mode = MultiAiReplyMode.roundRobin,
    this.enabled = false,
    this.nextTurn = 0,
    this.maxTurnsPerMessage = 1,
    List<String>? helperCharacterIds,
    Map<String, String>? characterProfiles,
    Map<String, String>? characterModels,
  })  : id = id ?? _multiAiUuid.v4(),
        characterIds = characterIds ?? <String>[],
        helperCharacterIds = helperCharacterIds ?? <String>[],
        characterProfiles = characterProfiles ?? <String, String>{},
        characterModels = characterModels ?? <String, String>{};

  final String id;
  String name;
  List<String> characterIds;
  List<String> helperCharacterIds;
  MultiAiReplyMode mode;
  bool enabled;
  int nextTurn;
  int maxTurnsPerMessage;

  /// 角色 id -> API 配置 id。空表示该角色用全局激活的 API 配置。
  /// 让每个角色可以走不同的供应商。
  Map<String, String> characterProfiles;

  /// 角色 id -> 在所属供应商模型列表中的模型名。空表示用该供应商的默认模型。
  Map<String, String> characterModels;

  MultiAiChat copyWith({
    String? name,
    List<String>? characterIds,
    List<String>? helperCharacterIds,
    MultiAiReplyMode? mode,
    bool? enabled,
    int? nextTurn,
    int? maxTurnsPerMessage,
    Map<String, String>? characterProfiles,
    Map<String, String>? characterModels,
  }) => MultiAiChat(
        id: id,
        name: name ?? this.name,
        characterIds: characterIds ?? List<String>.from(this.characterIds),
        helperCharacterIds:
            helperCharacterIds ?? List<String>.from(this.helperCharacterIds),
        mode: mode ?? this.mode,
        enabled: enabled ?? this.enabled,
        nextTurn: nextTurn ?? this.nextTurn,
        maxTurnsPerMessage: maxTurnsPerMessage ?? this.maxTurnsPerMessage,
        characterProfiles:
            characterProfiles ?? Map<String, String>.from(this.characterProfiles),
        characterModels:
            characterModels ?? Map<String, String>.from(this.characterModels),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterIds': characterIds,
        'helperCharacterIds': helperCharacterIds,
        'mode': mode.name,
        'enabled': enabled,
        'nextTurn': nextTurn,
        'maxTurnsPerMessage': maxTurnsPerMessage,
        'characterProfiles': characterProfiles,
        'characterModels': characterModels,
      };

  factory MultiAiChat.fromJson(Map<String, dynamic> json) => MultiAiChat(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '新群聊',
        characterIds:
            (json['characterIds'] as List?)?.whereType<String>().toList(),
        helperCharacterIds: (json['helperCharacterIds'] as List?)
            ?.whereType<String>()
            .toList(),
        mode: MultiAiReplyMode.values.firstWhere(
          (e) => e.name == json['mode'],
          orElse: () => MultiAiReplyMode.roundRobin,
        ),
        enabled: json['enabled'] as bool? ?? false,
        nextTurn: (json['nextTurn'] as num?)?.toInt() ?? 0,
        maxTurnsPerMessage: (json['maxTurnsPerMessage'] as num?)?.toInt() ?? 1,
        characterProfiles: ((json['characterProfiles'] as Map?) ?? {})
            .map((k, v) => MapEntry(k as String, v.toString())),
        characterModels: ((json['characterModels'] as Map?) ?? {})
            .map((k, v) => MapEntry(k as String, v.toString())),
      );

  List<CharacterCard> resolveCharacters(Iterable<CharacterCard> cards) {
    final byId = {for (final card in cards) card.id: card};
    return characterIds
        .map((id) => byId[id])
        .whereType<CharacterCard>()
        .toList();
  }
}
