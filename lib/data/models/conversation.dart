import 'package:uuid/uuid.dart';

import 'chat_message.dart';

const _uuid = Uuid();

/// 一个会话（对话），内部持有一棵消息树。
///
/// [messages] 为 id -> ChatMessage 的扁平映射，
/// [rootIds] 为根层消息 id（通常只有 1 个，即第一条 user 消息）。
/// [activeChildOf] 记录「某个节点当前选中的是哪个子分支」，
/// key 为 parentId（根层用 '__root__'），value 为选中的 child id。
class Conversation {
  static const defaultTitle = '新对话';
  static const defaultTitleEn = 'New chat';

  Conversation({
    String? id,
    this.title = defaultTitle,
    Map<String, ChatMessage>? messages,
    List<String>? rootIds,
    Map<String, String>? activeChildOf,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.characterId,
    this.pinned = false,
    this.deletedAt,
    this.contextSummary,
    this.summarizedUpTo,
  })  : id = id ?? _uuid.v4(),
        messages = messages ?? <String, ChatMessage>{},
        rootIds = rootIds ?? <String>[],
        activeChildOf = activeChildOf ?? <String, String>{},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  static const rootKey = '__root__';

  final String id;
  String title;

  final Map<String, ChatMessage> messages;
  final List<String> rootIds;
  final Map<String, String> activeChildOf;

  DateTime createdAt;
  DateTime updatedAt;

  /// 绑定的角色卡 id
  String? characterId;

  bool pinned;

  /// 软删除时间。非 null 表示已在回收站中。
  DateTime? deletedAt;

  /// 上下文摘要：早期对话被 AI 压缩后的文本。
  String? contextSummary;

  /// 摘要已覆盖到哪条消息（该消息及其之前的内容都已并入摘要）。
  String? summarizedUpTo;

  /// 是否在回收站中
  bool get isDeleted => deletedAt != null;

  /// 回收站保留天数
  static const trashRetentionDays = 30;

  /// 距离彻底清除还剩多少天（不在回收站时返回 null）
  int? get trashDaysLeft {
    final d = deletedAt;
    if (d == null) return null;
    final left = trashRetentionDays - DateTime.now().difference(d).inDays;
    return left < 0 ? 0 : left;
  }

  /// 是否已超过保留期，应被彻底清除
  bool get isTrashExpired {
    final d = deletedAt;
    if (d == null) return false;
    return DateTime.now().difference(d).inDays >= trashRetentionDays;
  }

  // ---------------------------------------------------------------- 树操作

  /// 当前激活路径（从根到叶）的消息列表，即界面上实际显示的对话线。
  List<ChatMessage> get activePath {
    final path = <ChatMessage>[];
    String? currentId = activeChildOf[rootKey] ??
        (rootIds.isNotEmpty ? rootIds.first : null);

    while (currentId != null) {
      final msg = messages[currentId];
      if (msg == null) break;
      path.add(msg);
      if (msg.childrenIds.isEmpty) break;
      currentId = activeChildOf[msg.id] ?? msg.childrenIds.first;
    }
    return path;
  }

  /// 取某条消息的兄弟分支列表（含自己），用于 1/3 页码显示。
  List<String> siblingsOf(String messageId) {
    final msg = messages[messageId];
    if (msg == null) return const [];
    if (msg.parentId == null) return List<String>.from(rootIds);
    return List<String>.from(messages[msg.parentId]?.childrenIds ?? const []);
  }

  /// 某条消息在兄弟中的序号（0 起）与总数。
  (int index, int total) branchInfoOf(String messageId) {
    final sibs = siblingsOf(messageId);
    final idx = sibs.indexOf(messageId);
    return (idx < 0 ? 0 : idx, sibs.length);
  }

  /// 添加一条消息，挂到 [parentId] 之下（parentId 为 null 则挂到根层），
  /// 并把它设为该层当前激活分支。
  void addMessage(ChatMessage msg, {String? parentId}) {
    msg.parentId = parentId;
    messages[msg.id] = msg;

    if (parentId == null) {
      if (!rootIds.contains(msg.id)) rootIds.add(msg.id);
      activeChildOf[rootKey] = msg.id;
    } else {
      final parent = messages[parentId];
      if (parent != null && !parent.childrenIds.contains(msg.id)) {
        parent.childrenIds.add(msg.id);
      }
      activeChildOf[parentId] = msg.id;
    }
    updatedAt = DateTime.now();
  }

  /// 切换某个节点所在层的激活分支到 [targetId]。
  void switchBranch(String targetId) {
    final target = messages[targetId];
    if (target == null) return;
    final key = target.parentId ?? rootKey;
    activeChildOf[key] = targetId;
    updatedAt = DateTime.now();
  }

  /// 删除消息及其整棵子树。
  void deleteSubtree(String messageId) {
    final msg = messages[messageId];
    if (msg == null) return;

    // 先递归删子节点
    for (final childId in List<String>.from(msg.childrenIds)) {
      deleteSubtree(childId);
    }

    // 从父节点摘除
    if (msg.parentId == null) {
      rootIds.remove(messageId);
      if (activeChildOf[rootKey] == messageId) {
        activeChildOf[rootKey] =
            rootIds.isNotEmpty ? rootIds.first : '';
        if (rootIds.isEmpty) activeChildOf.remove(rootKey);
      }
    } else {
      final parent = messages[msg.parentId];
      parent?.childrenIds.remove(messageId);
      if (activeChildOf[msg.parentId] == messageId) {
        final remaining = parent?.childrenIds ?? const [];
        if (remaining.isNotEmpty) {
          activeChildOf[msg.parentId!] = remaining.first;
        } else {
          activeChildOf.remove(msg.parentId);
        }
      }
    }

    activeChildOf.remove(messageId);
    messages.remove(messageId);
    updatedAt = DateTime.now();
  }

  // ---------------------------------------------------------------- 序列化

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((k, v) => MapEntry(k, v.toJson())),
        'rootIds': rootIds,
        'activeChildOf': activeChildOf,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'characterId': characterId,
        'pinned': pinned,
        'deletedAt': deletedAt?.toIso8601String(),
        'contextSummary': contextSummary,
        'summarizedUpTo': summarizedUpTo,
      };

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final rawMsgs = (json['messages'] as Map?) ?? {};
    return Conversation(
      id: json['id'] as String?,
      title: json['title'] as String? ?? defaultTitle,
      messages: rawMsgs.map(
        (k, v) => MapEntry(
          k as String,
          ChatMessage.fromJson(Map<String, dynamic>.from(v as Map)),
        ),
      ),
      rootIds:
          (json['rootIds'] as List?)?.map((e) => e as String).toList() ?? [],
      activeChildOf: ((json['activeChildOf'] as Map?) ?? {})
          .map((k, v) => MapEntry(k as String, v as String)),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      characterId: json['characterId'] as String?,
      pinned: json['pinned'] as bool? ?? false,
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      contextSummary: json['contextSummary'] as String?,
      summarizedUpTo: json['summarizedUpTo'] as String?,
    );
  }
}