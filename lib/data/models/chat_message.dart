import 'package:uuid/uuid.dart';

import 'attachment.dart';

const _uuid = Uuid();

/// 消息角色
enum MessageRole { system, user, assistant }

MessageRole roleFromString(String s) {
  switch (s) {
    case 'system':
      return MessageRole.system;
    case 'assistant':
      return MessageRole.assistant;
    default:
      return MessageRole.user;
  }
}

String roleToString(MessageRole r) => r.name;

/// 单条消息。
///
/// 消息以「树」的形式组织：每条消息记录 [parentId] 与 [childrenIds]。
/// 同一个 parent 下的多个 child 就是互为「兄弟分支」，
/// UI 上表现为 1/3 这样的页码切换。
class ChatMessage {
  ChatMessage({
    String? id,
    required this.role,
    required this.content,
    this.parentId,
    List<String>? childrenIds,
    DateTime? createdAt,
    this.modelName,
    this.isError = false,
    this.reasoning,
    this.characterId,
    this.characterName,
    List<Attachment>? attachments,
  })  : id = id ?? _uuid.v4(),
        childrenIds = childrenIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now(),
        attachments = attachments ?? <Attachment>[];

  final String id;
  MessageRole role;
  String content;

  /// 父消息 id，null 表示位于会话根层
  String? parentId;

  /// 子消息 id 列表（多个即多分支）
  List<String> childrenIds;

  DateTime createdAt;

  /// 生成该消息所用的模型名（仅 assistant 有意义）
  String? modelName;

  /// 是否为错误占位消息
  bool isError;

  /// 思维链内容（部分模型返回 reasoning_content）
  String? reasoning;

  /// 群聊中该条 assistant 消息所属的角色卡 id（单聊为 null）
  String? characterId;

  /// 群聊中该条 assistant 消息所属的角色名（用于身份标注，单聊为 null）
  String? characterName;

  /// 消息附件（图片/音频/文件）。用户消息可携带图片与文件，AI 回复暂不携带。
  List<Attachment> attachments;

  ChatMessage copyWith({
    MessageRole? role,
    String? content,
    String? parentId,
    List<String>? childrenIds,
    String? modelName,
    bool? isError,
    String? reasoning,
    String? characterId,
    String? characterName,
    List<Attachment>? attachments,
  }) {
    return ChatMessage(
      id: id,
      role: role ?? this.role,
      content: content ?? this.content,
      parentId: parentId ?? this.parentId,
      childrenIds: childrenIds ?? List<String>.from(this.childrenIds),
      createdAt: createdAt,
      modelName: modelName ?? this.modelName,
      isError: isError ?? this.isError,
      reasoning: reasoning ?? this.reasoning,
      characterId: characterId ?? this.characterId,
      characterName: characterName ?? this.characterName,
      attachments: attachments ?? List<Attachment>.from(this.attachments),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': roleToString(role),
        'content': content,
        'parentId': parentId,
        'childrenIds': childrenIds,
        'createdAt': createdAt.toIso8601String(),
        'modelName': modelName,
        'isError': isError,
        'reasoning': reasoning,
        'characterId': characterId,
        'characterName': characterName,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String?,
        role: roleFromString(json['role'] as String? ?? 'user'),
        content: json['content'] as String? ?? '',
        parentId: json['parentId'] as String?,
        childrenIds:
            (json['childrenIds'] as List?)?.map((e) => e as String).toList() ??
                <String>[],
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        modelName: json['modelName'] as String?,
        isError: json['isError'] as bool? ?? false,
        reasoning: json['reasoning'] as String?,
        characterId: json['characterId'] as String?,
        characterName: json['characterName'] as String?,
        attachments: ((json['attachments'] as List?) ?? [])
            .map((e) => Attachment.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
