import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/models/character_card.dart';
import '../data/models/chat_message.dart';
import '../data/models/multi_ai_chat.dart';
import '../data/services/media_service.dart';
import '../data/services/voice_service.dart';
import '../i18n/strings.dart';
import '../state/chat_provider.dart';
import '../state/config_providers.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/glass.dart';
import '../widgets/message_bubble.dart';
import 'character_sheet.dart';
import 'history_sheet.dart';
import 'multi_ai_page.dart';
import 'settings_page.dart';

/// 聊天主界面：上状态栏 / 中消息流 / 下悬浮输入框
class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // 首帧后恢复最近一个会话，没有则建新的
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreOrCreate());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // 距底部 120 内视为「跟随底部」
    final near = pos.maxScrollExtent - pos.pixels < 120;
    if (near != _autoScroll) setState(() => _autoScroll = near);
  }

  Future<void> _restoreOrCreate() async {
    final convs = ref.read(conversationsProvider);
    final notifier = ref.read(chatProvider.notifier);
    final settings = ref.read(settingsProvider);
    if (!settings.startNewChat && convs.isNotEmpty) {
      notifier.openConversation(convs.first);
    } else {
      await notifier.newConversation();
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(
        target,
        duration: AppTheme.normal,
        curve: AppTheme.ease,
      );
    } else {
      _scrollController.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final chat = ref.watch(chatProvider);
    final character = ref.watch(activeCharacterProvider);
    final profile = ref.watch(activeApiProfileProvider);
    final group = ref.watch(activeMultiAiChatProvider);
    final messages = chat.visibleMessages;

    // 流式输出时自动跟随底部
    if (chat.isStreaming && _autoScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            _buildTopBar(context, character.name, character.avatarEmoji,
                profile?.selectedModel, group),

            // 消息流
            Expanded(
              child: Stack(
                children: [
                  if (messages.isEmpty)
                    _buildEmptyState(context, character.avatarEmoji)
                  else
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: messages.length,
                      // 让流式更新只重建变化的那条
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<String>) return null;
                        final idx =
                            messages.indexWhere((m) => m.id == key.value);
                        return idx < 0 ? null : idx;
                      },
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return RepaintBoundary(
                          child: _buildBubble(msg, chat, settings),
                        );
                      },
                    ),

                  // 回到底部按钮
                  if (!_autoScroll && messages.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 12,
                      child: _ScrollToBottomButton(
                        onTap: () {
                          setState(() => _autoScroll = true);
                          _scrollToBottom();
                        },
                      ),
                    ),
                ],
              ),
            ),

            // 错误提示
            if (chat.error != null) _buildErrorBanner(chat.error!),

            // 输入栏
            ChatInputBar(
              isStreaming: chat.isStreaming,
              hintText: profile == null
                  ? context.l.configureApiFirst
                  : context.l.sendHint,
              onSend: (text) {
                setState(() => _autoScroll = true);
                ref.read(chatProvider.notifier).sendMessage(text);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );
              },
              onStop: () => ref.read(chatProvider.notifier).stopStreaming(),
              onAttachImage: () => _pickAndSendImage(context),
              onAttachCamera: () => _pickAndSendPhoto(context),
              onVoice: () => _startVoice(context),
              thinkingEnabled: settings.thinkingEnabled,
              thinkingLevel: settings.thinkingLevel,
              onToggleThinking: () => ref
                  .read(settingsProvider.notifier)
                  .setThinkingEnabled(!settings.thinkingEnabled),
              onSetThinkingLevel: (lv) => ref
                  .read(settingsProvider.notifier)
                  .setThinkingLevel(lv),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- 顶部栏

  Widget _buildTopBar(
    BuildContext context,
    String characterName,
    String emoji,
    String? modelName,
    MultiAiChat? group,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final topPad = MediaQuery.viewPaddingOf(context).top;
    final chat = ref.watch(chatProvider);

    // 群聊启用时，顶部栏显示群聊信息
    final groupMembers = group == null
        ? const <CharacterCard>[]
        : group.resolveCharacters(ref.watch(charactersProvider));
    final isGroup = groupMembers.length > 1;

    return GlassBar(
      padding: EdgeInsets.fromLTRB(8, topPad + 6, 8, 8),
      borderSide: Border(
        bottom: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          // 历史对话
          IconButton(
            tooltip: context.l.history,
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => showHistorySidebar(context),
          ),

          // 角色 / 模型状态（群聊启用时显示群聊信息）
          Expanded(
            child: InkWell(
              onTap: () {
                if (isGroup) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MultiAiPage()),
                  );
                } else {
                  showCharacterSheet(context);
                }
              },
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    if (isGroup)
                      Icon(
                        Icons.groups_rounded,
                        size: 22,
                        color: scheme.onSurfaceVariant,
                      )
                    else
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isGroup
                                      ? group!.name
                                      : characterName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.expand_more_rounded,
                                size: 17,
                                color: scheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              // 状态灯
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: chat.isStreaming
                                      ? scheme.primary
                                      : (modelName == null
                                          ? scheme.error
                                          : scheme.onSurfaceVariant
                                              .withValues(alpha: 0.5)),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  isGroup
                                      ? (chat.isStreaming
                                          ? context.l.generating
                                          : '群聊 · ${groupMembers.length}人 · ${group!.mode == MultiAiReplyMode.roundRobin ? '轮流' : '随机'}')
                                      : (chat.isStreaming
                                          ? context.l.generating
                                          : (modelName ??
                                              context.l.noApiConfigured)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 新建对话
          IconButton(
            tooltip: context.l.newChat,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () async {
              await ref.read(chatProvider.notifier).newConversation();
              setState(() => _autoScroll = true);
            },
          ),

          // 设置
          IconButton(
            tooltip: context.l.settings,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- 气泡

  Widget _buildBubble(ChatMessage msg, ChatState chat, AppSettings settings) {
    final conv = chat.conversation!;
    final (idx, total) = conv.branchInfoOf(msg.id);
    final notifier = ref.read(chatProvider.notifier);

    return MessageBubble(
      key: ValueKey(msg.id),
      message: msg,
      branchIndex: idx,
      branchTotal: total,
      isStreaming: chat.streamingMessageId == msg.id,
      showTimestamp: settings.showTimestamp,
      bubbleRadius: settings.bubbleRadius,
      fontSize: 15,
      onRegenerate: () {
        setState(() => _autoScroll = true);
        notifier.regenerate(msg.id);
      },
      onEdit: (text) {
        setState(() => _autoScroll = true);
        if (msg.role == MessageRole.user) {
          notifier.editUserMessage(msg.id, text);
        } else {
          notifier.updateMessageInPlace(msg.id, text);
        }
      },
      onDelete: () => _confirmDelete(msg.id),
      onPrevBranch: () => notifier.stepBranch(msg.id, -1),
      onNextBranch: () => notifier.stepBranch(msg.id, 1),
    );
  }

  Future<void> _confirmDelete(String messageId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.deleteMessage),
        content: Text(context.l.deleteMessageWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(context.l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(chatProvider.notifier).deleteMessage(messageId);
    }
  }

  // ---------------------------------------------------------------- 其他

  Widget _buildEmptyState(BuildContext context, String emoji) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.28),
                    scheme.primary.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 38)),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l.startNewChat,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l.emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        tint: scheme.errorContainer.withValues(alpha: 0.72),
        padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: scheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: context.l.close,
              iconSize: 17,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, color: scheme.onErrorContainer),
              onPressed: () =>
                  ref.read(chatProvider.notifier).clearError(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(BuildContext context) async {
    try {
      final att = await MediaService.instance.pickImage();
      if (att == null || !mounted) return;
      final notifier = ref.read(chatProvider.notifier);
      setState(() => _autoScroll = true);
      notifier.sendMessage('', attachments: [att]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('图片选择失败', 'Failed to pick image'))),
      );
    }
  }

  Future<void> _pickAndSendPhoto(BuildContext context) async {
    try {
      final att = await MediaService.instance.takePhoto();
      if (att == null || !mounted) return;
      final notifier = ref.read(chatProvider.notifier);
      setState(() => _autoScroll = true);
      notifier.sendMessage('', attachments: [att]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('拍照失败', 'Failed to take photo'))),
      );
    }
  }

  bool _voiceStarted = false;

  /// 语音：已开始时停止并提交识别文本，否则开始录音。
  Future<void> _startVoice(BuildContext context) async {
    final voice = VoiceService.instance;
    if (!_voiceStarted) {
      final ok = await voice.start();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l.text('无法启动语音识别，请检查麦克风权限', 'Cannot start speech recognition. Check microphone permission.')),
          ),
        );
        return;
      }
      setState(() => _voiceStarted = true);
    } else {
      final text = await voice.stop();
      setState(() => _voiceStarted = false);
      if (!mounted) return;
      if (text.trim().isNotEmpty) {
        ref.read(chatProvider.notifier).sendMessage(text.trim());
        setState(() => _autoScroll = true);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    }
  }
}

/// 回到底部悬浮按钮
class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.rPill),
      shadow: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(
              Icons.arrow_downward_rounded,
              size: 20,
              color: scheme.primary,
              semanticLabel: context.l.backToBottom,
            ),
          ),
        ),
      ),
    );
  }
}