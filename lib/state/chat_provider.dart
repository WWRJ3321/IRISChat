import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/api_profile.dart';
import '../data/models/app_settings.dart';
import '../data/models/attachment.dart';
import '../data/models/character_card.dart';
import '../data/models/chat_message.dart';
import '../data/models/conversation.dart';
import '../data/models/multi_ai_chat.dart';
import '../data/services/chat_service.dart';
import '../data/services/storage_service.dart';
import 'config_providers.dart';
import 'settings_provider.dart';

/// 会话列表状态
class ConversationsNotifier extends StateNotifier<List<Conversation>> {
  ConversationsNotifier() : super(StorageService.instance.loadConversations());

  void refresh() {
    state = StorageService.instance.loadConversations();
  }

  Future<Conversation> create({String? characterId, String? title}) async {
    final c = Conversation(
      characterId: characterId,
      title: title ?? Conversation.defaultTitle,
    );
    await StorageService.instance.saveConversation(c);
    refresh();
    return c;
  }

  Future<void> save(Conversation c) async {
    await StorageService.instance.saveConversation(c);
    refresh();
  }

  /// 将会话移入回收站，30 天内可恢复。
  Future<void> remove(String id) async {
    await StorageService.instance.moveToTrash(id);
    refresh();
  }

  Future<void> restore(String id) async {
    await StorageService.instance.restoreFromTrash(id);
    refresh();
  }

  Future<void> deletePermanently(String id) async {
    await StorageService.instance.deleteConversation(id);
    refresh();
  }

  Future<void> emptyTrash() async {
    await StorageService.instance.emptyTrash();
    refresh();
  }

  Future<void> moveAllToTrash() async {
    for (final conversation in List<Conversation>.from(state)) {
      await StorageService.instance.moveToTrash(conversation.id);
    }
    refresh();
  }

  Future<void> rename(Conversation c, String title) async {
    c.title = title.trim().isEmpty ? c.title : title.trim();
    await save(c);
  }

  Future<void> togglePin(Conversation c) async {
    c.pinned = !c.pinned;
    await save(c);
  }

  Future<void> clearAll() async {
    await StorageService.instance.clearConversations();
    refresh();
  }

  Conversation? byId(String? id) {
    if (id == null) return null;
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }
}

final conversationsProvider =
    StateNotifierProvider<ConversationsNotifier, List<Conversation>>((ref) {
  return ConversationsNotifier();
});

/// 当前打开的会话 id
final currentConversationIdProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------- 聊天状态

/// 聊天界面的运行时状态
class ChatState {
  const ChatState({
    this.conversation,
    this.isStreaming = false,
    this.streamingMessageId,
    this.error,
    this.revision = 0,
  });

  final Conversation? conversation;
  final bool isStreaming;

  /// 正在流式写入的 assistant 消息 id
  final String? streamingMessageId;
  final String? error;

  /// 用于强制刷新 UI（消息树内部是可变对象，改内容不换引用）
  final int revision;

  /// 界面上实际显示的消息线
  List<ChatMessage> get visibleMessages =>
      conversation?.activePath ?? const <ChatMessage>[];

  ChatState copyWith({
    Conversation? conversation,
    bool? isStreaming,
    String? streamingMessageId,
    bool clearStreamingId = false,
    String? error,
    bool clearError = false,
    int? revision,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingMessageId: clearStreamingId
          ? null
          : (streamingMessageId ?? this.streamingMessageId),
      error: clearError ? null : (error ?? this.error),
      revision: revision ?? this.revision,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref) : super(const ChatState());

  final Ref _ref;
  StreamSubscription<StreamChunk>? _sub;
  var _isPreparingRequest = false;

  ChatService get _service => _ref.read(chatServiceProvider);

  bool get _isZh {
    final code = _ref.read(settingsProvider).languageCode;
    if (code == 'zh') return true;
    if (code == 'en') return false;
    return PlatformDispatcher.instance.locale.languageCode != 'en';
  }

  String _errorText(Object error) => switch (error) {
        ApiException exception => exception.messageFor(_isZh),
        _ => _isZh ? '请求失败' : 'Request failed.',
      };

  // -------------------------------------------------------------- 会话切换

  void openConversation(Conversation c) {
    _cancelStream();
    state = ChatState(conversation: c);
    _ref.read(currentConversationIdProvider.notifier).state = c.id;
  }

  Future<void> newConversation() async {
    _cancelStream();
    final activeChar = _ref.read(activeCharacterProvider);
    final title = _isZh
        ? Conversation.defaultTitle
        : Conversation.defaultTitleEn;
    final c = await _ref
        .read(conversationsProvider.notifier)
        .create(characterId: activeChar.id, title: title);

    // 有开场白则作为第一条 assistant 消息
    if (activeChar.greeting.trim().isNotEmpty) {
      c.addMessage(
        ChatMessage(
          role: MessageRole.assistant,
          content: activeChar.greeting.trim(),
        ),
      );
      await _ref.read(conversationsProvider.notifier).save(c);
    }
    openConversation(c);
  }

  void _touch() {
    final c = state.conversation;
    if (c == null) return;
    state = state.copyWith(revision: state.revision + 1);
    StorageService.instance.saveConversation(c);
  }

  Future<void> _persistAndRefreshList() async {
    final c = state.conversation;
    if (c == null) return;
    await _ref.read(conversationsProvider.notifier).save(c);
  }

  // -------------------------------------------------------------- 发送消息

  /// 发送用户消息并请求 AI 回复
  Future<void> sendMessage(
    String text, {
    List<Attachment>? attachments,
  }) async {
    final content = text.trim();
    final atts = attachments ?? <Attachment>[];
    if ((content.isEmpty && atts.isEmpty) ||
        state.isStreaming ||
        _isPreparingRequest) {
      return;
    }

    var conv = state.conversation;
    if (conv == null) {
      await newConversation();
      conv = state.conversation;
      if (conv == null) return;
    }

    final path = conv.activePath;
    final parentId = path.isEmpty ? null : path.last.id;

    final userMsg = ChatMessage(
      role: MessageRole.user,
      content: content,
      attachments: List<Attachment>.from(atts),
    );
    conv.addMessage(userMsg, parentId: parentId);

    // 首条消息自动作为标题
    if (conv.title == Conversation.defaultTitle ||
        conv.title == Conversation.defaultTitleEn) {
      conv.title = content.length > 20 ? '${content.substring(0, 20)}…' : content;
    }

    state = state.copyWith(
      conversation: conv,
      revision: state.revision + 1,
      clearError: true,
    );
    await _persistAndRefreshList();

    final group = _ref.read(activeMultiAiChatProvider);
    final groupSize = group == null
        ? 0
        : group.resolveCharacters(_ref.read(charactersProvider)).length;
    if (group != null && groupSize > 1) {
      await _requestMultiAi(group: group, parentId: userMsg.id);
    } else {
      await _requestAssistant(parentId: userMsg.id);
    }
  }

  /// 重新生成某条 assistant 消息：在它的父节点下新建一个兄弟分支
  Future<void> regenerate(String assistantMessageId) async {
    final conv = state.conversation;
    if (conv == null || state.isStreaming || _isPreparingRequest) return;

    final target = conv.messages[assistantMessageId];
    if (target == null || target.role != MessageRole.assistant) return;

    await _requestAssistant(parentId: target.parentId);
  }

  /// 编辑用户消息：在其父节点下创建新分支（保留原分支，形成 1/N）
  Future<void> editUserMessage(String messageId, String newContent) async {
    final conv = state.conversation;
    if (conv == null || state.isStreaming || _isPreparingRequest) return;

    final target = conv.messages[messageId];
    if (target == null) return;

    final text = newContent.trim();
    if (text.isEmpty || text == target.content) return;

    final newMsg = ChatMessage(role: target.role, content: text);
    conv.addMessage(newMsg, parentId: target.parentId);

    state = state.copyWith(
      conversation: conv,
      revision: state.revision + 1,
      clearError: true,
    );
    await _persistAndRefreshList();

    if (target.role == MessageRole.user) {
      await _requestAssistant(parentId: newMsg.id);
    }
  }

  /// 原地修改消息内容（不产生新分支）
  Future<void> updateMessageInPlace(String messageId, String newContent) async {
    final conv = state.conversation;
    if (conv == null) return;
    final msg = conv.messages[messageId];
    if (msg == null) return;
    msg.content = newContent;
    _touch();
    await _persistAndRefreshList();
  }

  /// 切换分支（页码切换）
  Future<void> switchBranch(String targetMessageId) async {
    final conv = state.conversation;
    if (conv == null) return;
    conv.switchBranch(targetMessageId);
    state = state.copyWith(revision: state.revision + 1);
    await _persistAndRefreshList();
  }

  /// 切到相邻分支：[delta] 为 -1 上一个，+1 下一个
  Future<void> stepBranch(String messageId, int delta) async {
    final conv = state.conversation;
    if (conv == null) return;
    final sibs = conv.siblingsOf(messageId);
    if (sibs.length <= 1) return;
    final idx = sibs.indexOf(messageId);
    final next = (idx + delta) % sibs.length;
    await switchBranch(sibs[next < 0 ? next + sibs.length : next]);
  }

  /// 删除消息及其子树
  Future<void> deleteMessage(String messageId) async {
    final conv = state.conversation;
    if (conv == null) return;
    conv.deleteSubtree(messageId);
    state = state.copyWith(revision: state.revision + 1);
    await _persistAndRefreshList();
  }

  // -------------------------------------------------------------- 多 AI 群聊

  /// 群聊：用户发一句后，群里每个成员按顺序各发言一次（轮数可配置）。
  ///
  /// 核心是「视角化上下文」：每个成员看到的历史里，只有自己说过的话是
  /// assistant，别人（含用户）说的话都是带名字前缀的 user 消息。
  /// 这样模型不会把别人的发言当成自己说过的，也不会去模拟别人发言。
  Future<void> _requestMultiAi({
    required MultiAiChat group,
    required String parentId,
  }) async {
    final conv = state.conversation;
    if (conv == null) return;

    // 成员角色卡可能已被删除，只保留真实存在的
    final members = group.resolveCharacters(_ref.read(charactersProvider));
    if (members.length < 2) {
      await _requestAssistant(parentId: parentId);
      return;
    }

    final speakers = List<CharacterCard>.from(members);
    if (group.mode == MultiAiReplyMode.random) {
      speakers.shuffle(Random());
    }

    final globalProfile = _ref.read(activeApiProfileProvider);
    final profilesById = {
      for (final p in _ref.read(apiProfilesProvider)) p.id: p
    };
    ApiProfile? profileFor(CharacterCard c) {
      final pid = group.characterProfiles[c.id];
      final bound = (pid == null || pid.isEmpty) ? null : profilesById[pid];
      return bound ?? globalProfile;
    }

    if (speakers.any((c) => profileFor(c) == null)) {
      state = state.copyWith(
        error: _isZh
            ? '群聊里有成员没有可用的 API 配置，请在群聊设置里为它绑定供应商'
            : 'A member has no usable API profile. Bind a provider in group settings.',
        revision: state.revision + 1,
      );
      return;
    }

    final settings = _ref.read(settingsProvider);
    final rounds = group.maxTurnsPerMessage.clamp(1, 3).toInt();
    var branchParent = parentId;

    state = state.copyWith(isStreaming: true, clearError: true);
    try {
      for (var round = 0; round < rounds; round++) {
        for (final speaker in speakers) {
          final profile = profileFor(speaker)!;
          final model = _resolveModel(speaker, profile, group);

          final payload = <Map<String, dynamic>>[
            {
              'role': 'system',
              'content': _groupSystemPrompt(speaker, profile, group, members),
            },
            ..._buildGroupContext(
              conv,
              branchParent,
              settings.contextStrategy == 1 ? 20 : 40,
              selfId: speaker.id,
              includeSummary: settings.contextStrategy == 1,
            ),
          ];

          final raw = await _service.completeChat(
            profile: profile,
            card: speaker,
            model: model,
            messages: payload,
            thinkingEnabled: settings.thinkingEnabled,
            thinkingLevel: settings.thinkingLevel,
          );

          final content = _sanitizeGroupReply(raw, speaker, members);
          // 成员可以选择本轮不发言
          if (content.isEmpty) continue;

          final reply = ChatMessage(
            role: MessageRole.assistant,
            content: content,
            modelName: model,
            characterId: speaker.id,
            characterName: speaker.name,
          );
          conv.addMessage(reply, parentId: branchParent);
          branchParent = reply.id;

          state = state.copyWith(
            conversation: conv,
            revision: state.revision + 1,
          );
          await _persistAndRefreshList();
        }
      }
    } catch (e) {
      state = state.copyWith(error: _errorText(e), revision: state.revision + 1);
    } finally {
      state = state.copyWith(isStreaming: false, clearStreamingId: true);
      await _persistAndRefreshList();
    }
  }

  /// 站在 [selfId] 这个成员的视角构造群聊上下文。
  List<Map<String, dynamic>> _buildGroupContext(
    Conversation conv,
    String? leafId,
    int limit, {
    required String selfId,
    required bool includeSummary,
  }) {
    var remaining = _contextMessages(conv, leafId);
    if (limit > 0 && remaining.length > limit) {
      remaining = remaining.sublist(remaining.length - limit);
    }

    final result = <Map<String, dynamic>>[];
    if (includeSummary && conv.contextSummary?.trim().isNotEmpty == true) {
      result.add({
        'role': 'system',
        'content': _isZh
            ? '此前对话摘要：${conv.contextSummary!.trim()}'
            : 'Earlier conversation summary: ${conv.contextSummary!.trim()}',
      });
    }

    for (final m in remaining) {
      // 自己说过的话：保持 assistant，不加名字前缀
      if (m.role == MessageRole.assistant && m.characterId == selfId) {
        result.add({'role': 'assistant', 'content': m.content});
        continue;
      }

      final who = m.role == MessageRole.user
          ? (_isZh ? '用户' : 'User')
          : (m.characterName?.trim().isNotEmpty == true
              ? m.characterName!.trim()
              : (_isZh ? '其他成员' : 'Another member'));
      final labelled = _isZh ? '$who：${m.content}' : '$who: ${m.content}';

      final payload = _messageToPayload(m);
      final content = payload['content'];
      if (content is List) {
        // 多模态：说话人写进文本片段，图片片段原样保留
        final parts = <Map<String, dynamic>>[
          {'type': 'text', 'text': labelled},
        ];
        for (final part in content) {
          if (part is Map<String, dynamic> && part['type'] != 'text') {
            parts.add(part);
          }
        }
        result.add({'role': 'user', 'content': parts});
      } else {
        result.add({'role': 'user', 'content': labelled});
      }
    }
    return result;
  }

  /// 群聊 system prompt：角色人设 + 明确的群聊行为约束。
  String _groupSystemPrompt(
    CharacterCard self,
    ApiProfile profile,
    MultiAiChat group,
    List<CharacterCard> members,
  ) {
    final name = self.name;
    final model = _resolveModel(self, profile, group) ?? '-';
    final others =
        members.where((c) => c.id != self.id).map((c) => '「${c.name}」');
    final otherList = others.isEmpty
        ? (_isZh ? '（暂无）' : '(none)')
        : others.join(_isZh ? '、' : ', ');

    final rules = _isZh
        ? '''# 群聊设定

你是「$name」，这个群聊里的一名独立成员（当前使用 ${profile.name} / $model）。

## 你的身份
你是「$name」，一个有自己独立人格、思维方式和说话风格的 AI。你不是主持人的角色，也不是助手团队的一员。你只代表你自己。

## 群里有谁
- 你：$name
- 其他 AI 成员：$otherList
- 用户：一位真人，也在这个群里

## 必须遵守
1. **你是独立的个体**：你有自己独特的人格、观点和说话方式。不要模仿其他成员的语气或风格。你的回答应该反映出你作为 $name 这个角色的特点。
2. **你只代表你自己发言**：绝对不要替其他成员说话，也不要写出「某某：……」这种模拟别人发言的段落。你只能输出你自己的内容。
3. **历史消息是别人的话**：历史里以「用户：」或「某成员名：」开头的消息是别人说的。你自己说过的话没有名字前缀，不要把别人的话当成自己的。
4. **轮到你时只说一段**：不要长篇大论。像真人发微信群那样，1-3 句话，最多一小段。简洁有力，言之有物。
5. **不代劳、不总结**：其他成员会自己发言，不需要你替他们说话，也不用替他们总结。
6. **开头不要写名字**：界面会自动显示你的名字，直接说内容即可。
7. **被点名时闭嘴**：如果用户明确点名让别的成员回答，而你确实没有要补充的，就只回复一个英文句点 . 表示跳过本轮。不要抢着答。'''
        : '''# Group chat setup

You are "$name", an independent member of this group chat (running ${profile.name} / $model).

## Your identity
You are "$name", an AI with your own unique personality, thinking style, and way of speaking. You are not a moderator or part of an assistant team. You represent only yourself.

## Who is here
- You: $name
- Other AI members: $otherList
- The user: a real person, also in this group

## Rules
1. **You are an independent individual**: You have your own unique personality, viewpoints, and speaking style. Do not imitate other members' tones or styles. Your responses should reflect your character as $name.
2. **Speak only as yourself**: Never speak for another member, and never write simulated lines like "SomeName: ...". You can only output your own content.
3. **History belongs to others**: Lines starting with "User:" or "<MemberName>:" in history were said by someone else. Your own past lines have no name prefix—do not confuse them.
4. **One short turn at a time**: When it is your turn, say only one short paragraph. Like texting in a group chat—1-3 sentences, concise and meaningful.
5. **No taking over**: Other members will speak for themselves. Do not speak on their behalf or summarize their contributions.
6. **Do not prefix your name**: The UI already shows it. Just say your content directly.
7. **Stay quiet when not addressed**: If the user explicitly asked another member to respond and you have nothing to add, reply with a single . to pass this turn. Do not jump in.''';

    final persona = self.systemPrompt.trim();
    return persona.isEmpty ? rules : '$persona\n\n$rules';
  }

  /// 清理群聊回复：去掉自己的名字前缀，截断模型模拟他人发言的部分。
  String _sanitizeGroupReply(
      String raw, CharacterCard self, List<CharacterCard> members) {
    var out = raw.trim();
    if (out.isEmpty) return '';

    // 1) 去掉开头的「自己名字：」
    out = out
        .replaceFirst(
          RegExp('^[\\[「]?${RegExp.escape(self.name)}[\\]」]?[ \\t]*[:：][ \\t]*'),
          '',
        )
        .trim();

    // 2) 从第一处「别人名字：」或「用户：」处截断，避免自导自演
    var cut = out.length;
    void tryCut(String label) {
      final m = RegExp(
        '(^|\\n)[ \\t]*[\\[「]?${RegExp.escape(label)}[\\]」]?[ \\t]*[:：]',
      ).firstMatch(out);
      if (m != null && m.start < cut) cut = m.start;
    }

    for (final other in members) {
      if (other.id != self.id) tryCut(other.name);
    }
    tryCut(_isZh ? '用户' : 'User');
    if (cut < out.length) out = out.substring(0, cut).trim();

    // 3) 只剩标点或明确表示跳过，视为放弃本轮
    final bare = out.replaceAll(RegExp('[\\s.。．…]'), '').toLowerCase();
    if (bare.isEmpty || bare == 'pass' || bare == 'skip' || bare == '跳过') {
      return '';
    }
    return out;
  }


  /// 解析角色实际使用的模型名：角色卡覆盖 > 群聊绑定 > profile 默认。
  String? _resolveModel(CharacterCard character, ApiProfile profile, MultiAiChat group) {
    if (character.modelOverride?.trim().isNotEmpty == true) {
      return character.modelOverride!.trim();
    }
    final bound = group.characterModels[character.id];
    if (bound != null && bound.trim().isNotEmpty) return bound.trim();
    return profile.selectedModel;
  }

  // -------------------------------------------------------------- 请求核心

  Future<void> _requestAssistant({required String? parentId}) async {
    final conv = state.conversation;
    if (conv == null) return;

    final profile = _ref.read(activeApiProfileProvider);
    final card = _ref.read(activeCharacterProvider);

    if (profile == null) {
      state = state.copyWith(
        error: _isZh
            ? '尚未配置 API：请到设置里添加一个 API 配置'
            : 'No API is configured. Add an API provider in Settings.',
      );
      return;
    }

    final settings = _ref.read(settingsProvider);

    // 摘要模式会先压缩过长的旧上下文；请求失败时不影响正常对话。
    if (settings.contextStrategy == 1) {
      _isPreparingRequest = true;
      try {
        await _summarizeIfNeeded(conv, parentId, profile, card, settings);
      } finally {
        _isPreparingRequest = false;
      }
    }

    // 构造上下文：沿 parentId 往上回溯，得到这一分支的历史。
    final history = _buildContext(
      conv,
      parentId,
      card.contextLimit,
      includeSummary: settings.contextStrategy == 1,
    );
    final payload = <Map<String, dynamic>>[];
    if (card.systemPrompt.trim().isNotEmpty) {
      payload.add({'role': 'system', 'content': card.systemPrompt.trim()});
    }
    payload.addAll(history);

    // 先插入一条空的 assistant 消息用于承载流式内容
    final placeholder = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      modelName: (card.modelOverride?.isNotEmpty ?? false)
          ? card.modelOverride
          : profile.selectedModel,
    );
    conv.addMessage(placeholder, parentId: parentId);

    state = state.copyWith(
      conversation: conv,
      isStreaming: true,
      streamingMessageId: placeholder.id,
      revision: state.revision + 1,
      clearError: true,
    );

    if (!profile.stream) {
      // 非流式路径
      try {
        final text = await _service.completeChat(
          profile: profile,
          card: card,
          messages: payload,
          thinkingEnabled: settings.thinkingEnabled,
          thinkingLevel: settings.thinkingLevel,
        );
        placeholder.content = text;
      } catch (e) {
        placeholder
          ..content = '⚠️ ${_errorText(e)}'
          ..isError = true;
      } finally {
        state = state.copyWith(
          isStreaming: false,
          clearStreamingId: true,
          revision: state.revision + 1,
        );
        await _persistAndRefreshList();
      }
      return;
    }

    // 流式路径
    final buffer = StringBuffer();
    final reasoningBuffer = StringBuffer();

    _sub = _service
        .streamChat(
          profile: profile,
          card: card,
          messages: payload,
          thinkingEnabled: settings.thinkingEnabled,
          thinkingLevel: settings.thinkingLevel,
        )
        .listen(
      (chunk) {
        if (chunk.content.isNotEmpty) {
          buffer.write(chunk.content);
          placeholder.content = buffer.toString();
        }
        if (chunk.reasoning.isNotEmpty) {
          reasoningBuffer.write(chunk.reasoning);
          placeholder.reasoning = reasoningBuffer.toString();
        }
        state = state.copyWith(revision: state.revision + 1);
      },
      onError: (Object e) {
        final errorText = _errorText(e);
        placeholder
          ..content = buffer.isEmpty
              ? '⚠️ $errorText'
              : '${buffer.toString()}\n\n⚠️ $errorText'
          ..isError = buffer.isEmpty;
        state = state.copyWith(
          isStreaming: false,
          clearStreamingId: true,
          error: errorText,
          revision: state.revision + 1,
        );
        _persistAndRefreshList();
      },
      onDone: () {
        if (placeholder.content.trim().isEmpty && !placeholder.isError) {
          placeholder
            ..content = _isZh
                ? '（模型没有返回内容）'
                : '(The model returned no content)'
            ..isError = true;
        }
        state = state.copyWith(
          isStreaming: false,
          clearStreamingId: true,
          revision: state.revision + 1,
        );
        _persistAndRefreshList();
      },
      cancelOnError: true,
    );
  }

  /// 自动压缩超出阈值的旧消息。保留最近原文，旧内容存为一个系统摘要。
  Future<void> _summarizeIfNeeded(
    Conversation conv,
    String? leafId,
    ApiProfile profile,
    CharacterCard card,
    AppSettings settings,
  ) async {
    final ordered = _contextMessages(conv, leafId);
    final trigger = settings.summaryTriggerCount;
    final keep = settings.summaryKeepRecent.clamp(2, trigger - 1).toInt();
    if (trigger < 4 || ordered.length <= trigger || ordered.length <= keep) return;

    final cutoff = ordered[ordered.length - keep - 1];
    final previousIndex = conv.summarizedUpTo == null
        ? -1
        : ordered.indexWhere((m) => m.id == conv.summarizedUpTo);

    // 已有摘要时，只统计超出「保留原文」的新增消息；积累到阈值后再压缩，
    // 避免每一轮对话都追加摘要请求。
    final pendingCount = ordered.length - previousIndex - 1 - keep;
    if (previousIndex >= 0 && pendingCount <= trigger) return;

    final newlyCovered = ordered.sublist(
      previousIndex + 1,
      ordered.length - keep,
    );
    final text = newlyCovered
        .map((m) {
          final role = m.role == MessageRole.user
              ? (_isZh ? '用户' : 'User')
              : (_isZh ? '助手' : 'Assistant');
          return '$role${_isZh ? '：' : ': '}${m.content}';
        })
        .join('\n\n');
    if (text.trim().isEmpty) return;

    final existingSummary = previousIndex >= 0
        ? conv.contextSummary?.trim()
        : null;
    final source = existingSummary?.isNotEmpty == true
        ? _isZh
            ? '已有摘要：\n$existingSummary\n\n需要并入的新对话：\n$text'
            : 'Existing summary:\n$existingSummary\n\nNew conversation to merge:\n$text'
        : text;

    try {
      final result = await _service.completeChat(
        profile: profile,
        card: card,
        messages: [
          {
            'role': 'system',
            'content': _isZh
                ? '将下面对话压缩成简洁、准确的长期上下文。保留用户偏好、已确认事实、未完成任务、关键结论和约束；不要编造；用中文输出。'
                : 'Summarize the conversation below into concise, accurate long-term context. Preserve user preferences, confirmed facts, unfinished tasks, key conclusions, and constraints. Do not invent information. Write in English.',
          },
          {'role': 'user', 'content': source},
        ],
      );
      if (result.trim().isEmpty) return;
      conv.contextSummary = result.trim();
      conv.summarizedUpTo = cutoff.id;
      await _persistAndRefreshList();
    } catch (_) {
      // 摘要是节省 token 的优化，失败时不应中断实际回复。
    }
  }

  List<ChatMessage> _contextMessages(Conversation conv, String? leafId) {
    final chain = <ChatMessage>[];
    var cursor = leafId;
    while (cursor != null) {
      final m = conv.messages[cursor];
      if (m == null) break;
      if ((m.content.trim().isNotEmpty || m.attachments.isNotEmpty) &&
            !m.isError) {
          chain.add(m);
        }
      cursor = m.parentId;
    }
    return chain.reversed.toList();
  }

  /// 沿分支回溯构造上下文消息（不含角色卡 system prompt）。
  List<Map<String, dynamic>> _buildContext(
    Conversation conv,
    String? leafId,
    int limit, {
    required bool includeSummary,
  }) {
    final ordered = _contextMessages(conv, leafId);
    final summaryEnd = conv.summarizedUpTo;
    var startIndex = 0;
    var useSummary = false;
    if (includeSummary && summaryEnd != null) {
      final index = ordered.indexWhere((m) => m.id == summaryEnd);
      if (index >= 0) {
        startIndex = index + 1;
        useSummary = true;
      }
    }

    var remaining = ordered.sublist(startIndex);
    if (limit > 0 && remaining.length > limit) {
      remaining = remaining.sublist(remaining.length - limit);
    }

    final result = <Map<String, dynamic>>[];
    if (useSummary && conv.contextSummary?.trim().isNotEmpty == true) {
      result.add({
        'role': 'system',
        'content': _isZh
            ? '此前对话摘要：${conv.contextSummary!.trim()}'
            : 'Earlier conversation summary: ${conv.contextSummary!.trim()}',
      });
    }
    result.addAll(
      remaining.map((m) => _messageToPayload(m)),
    );
    return result;
  }

  /// 将一条 ChatMessage 转为 API 请求格式的消息。
  /// 如果消息携带图片附件，content 会变成多模态数组（OpenAI Vision 格式）。
  Map<String, dynamic> _messageToPayload(ChatMessage m) {
    final images = m.attachments
        .where((a) => a.kind == AttachmentKind.image)
        .toList();
    if (images.isEmpty) {
      return {'role': roleToString(m.role), 'content': m.content};
    }

    // 多模态：content 为数组，包含文本和图片
    final parts = <Map<String, dynamic>>[];
    if (m.content.trim().isNotEmpty) {
      parts.add({'type': 'text', 'text': m.content});
    }
    for (final img in images) {
      final dataUrl = _imageToDataUrl(img.localPath);
      if (dataUrl != null) {
        parts.add({
          'type': 'image_url',
          'image_url': {'url': dataUrl},
        });
      }
    }
    return {'role': roleToString(m.role), 'content': parts};
  }

  /// 读取本地图片文件并转为 base64 data URL。
  String? _imageToDataUrl(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = file.readAsBytesSync();
      final b64 = base64Encode(bytes);
      final ext = path.toLowerCase();
      String mime;
      if (ext.endsWith('.png')) {
        mime = 'image/png';
      } else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
        mime = 'image/jpeg';
      } else if (ext.endsWith('.gif')) {
        mime = 'image/gif';
      } else if (ext.endsWith('.webp')) {
        mime = 'image/webp';
      } else {
        mime = 'image/jpeg';
      }
      return 'data:$mime;base64,$b64';
    } catch (_) {
      return null;
    }
  }

  /// 清除错误提示
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// 停止生成
  void stopStreaming() {
    _service.cancel();
    _cancelStream();
    state = state.copyWith(
      isStreaming: false,
      clearStreamingId: true,
      revision: state.revision + 1,
    );
    _persistAndRefreshList();
  }

  void _cancelStream() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});