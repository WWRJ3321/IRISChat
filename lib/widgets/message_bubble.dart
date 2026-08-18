import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/models/attachment.dart';
import '../data/models/chat_message.dart';
import '../i18n/strings.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'markdown_message.dart';

/// 单条消息气泡。
///
/// - user：右侧，主色渐变实心气泡
/// - assistant：左侧，毛玻璃气泡 + Markdown 渲染
/// - 底部操作条：复制 / 重新生成 / 编辑 / 删除 / 分支页码 1/3
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.branchIndex,
    required this.branchTotal,
    required this.isStreaming,
    this.showTimestamp = true,
    this.bubbleRadius = 22,
    this.fontSize = 15,
    this.onCopy,
    this.onRegenerate,
    this.onEdit,
    this.onDelete,
    this.onPrevBranch,
    this.onNextBranch,
  });

  final ChatMessage message;

  /// 当前分支序号（0 起）与总数，用于 1/3 显示
  final int branchIndex;
  final int branchTotal;

  /// 该条消息是否正在流式输出
  final bool isStreaming;

  final bool showTimestamp;
  final double bubbleRadius;
  final double fontSize;

  final VoidCallback? onCopy;
  final VoidCallback? onRegenerate;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPrevBranch;
  final VoidCallback? onNextBranch;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showActions = false;
  bool _editing = false;
  bool _reasoningExpanded = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.message.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  bool get _isUser => widget.message.role == MessageRole.user;

  void _startEdit() {
    _editController.text = widget.message.content;
    setState(() {
      _editing = true;
      _showActions = false;
    });
  }

  void _submitEdit() {
    final text = _editController.text.trim();
    setState(() => _editing = false);
    if (text.isNotEmpty && text != widget.message.content) {
      widget.onEdit?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final msg = widget.message;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(widget.bubbleRadius),
      topRight: Radius.circular(widget.bubbleRadius),
      bottomLeft: Radius.circular(_isUser ? widget.bubbleRadius : 6),
      bottomRight: Radius.circular(_isUser ? 6 : widget.bubbleRadius),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Column(
        crossAxisAlignment:
            _isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 头部：角色标识 + 模型名（群聊时显示角色名）
          if (!_isUser)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: msg.isError ? scheme.error : scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    msg.characterName?.isNotEmpty == true
                        ? msg.characterName!
                        : (msg.modelName?.isNotEmpty == true
                            ? msg.modelName!
                            : 'AI'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // 气泡本体
          GestureDetector(
            onLongPress: () => setState(() => _showActions = !_showActions),
            onTap: _editing
                ? null
                : () {
                    if (_showActions) setState(() => _showActions = false);
                  },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.86,
              ),
              child: _editing
                  ? _buildEditor(scheme, radius)
                  : (_isUser
                      ? _buildUserBubble(scheme, radius)
                      : _buildAssistantBubble(scheme, radius)),
            ),
          ),

          // 操作条 + 分支页码
          AnimatedSize(
            duration: AppTheme.fast,
            curve: AppTheme.ease,
            alignment: _isUser ? Alignment.topRight : Alignment.topLeft,
            child: (_showActions || widget.branchTotal > 1)
                ? _buildActionBar(scheme)
                : const SizedBox(width: double.infinity, height: 0),
          ),

          // 时间戳
          if (widget.showTimestamp && !_editing)
            Padding(
              padding: EdgeInsets.only(
                top: 3,
                left: _isUser ? 0 : 5,
                right: _isUser ? 5 : 0,
              ),
              child: Text(
                DateFormat('HH:mm').format(msg.createdAt),
                style: TextStyle(
                  fontSize: 10.5,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 用户气泡

  Widget _buildUserBubble(ColorScheme scheme, BorderRadius radius) {
    final images = widget.message.attachments
        .where((a) => a.kind == AttachmentKind.image)
        .toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.35) ?? scheme.primary,
          ],
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty) ...[
            for (final img in images)
              Padding(
                padding: EdgeInsets.only(bottom: widget.message.content.trim().isEmpty ? 0 : 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(img.localPath),
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: _onPrimaryFor(scheme.primary),
                    ),
                  ),
                ),
              ),
          ],
          if (widget.message.content.trim().isNotEmpty)
            SelectableText(
              widget.message.content,
              style: TextStyle(
                color: _onPrimaryFor(scheme.primary),
                fontSize: widget.fontSize,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  /// 主色偏亮时用深色文字，保证对比度（无障碍）
  Color _onPrimaryFor(Color bg) {
    return bg.computeLuminance() > 0.55 ? const Color(0xFF06322D) : Colors.white;
  }

  // ------------------------------------------------------------ AI 气泡

  Widget _buildAssistantBubble(ColorScheme scheme, BorderRadius radius) {
    final msg = widget.message;
    final hasReasoning = (msg.reasoning?.trim().isNotEmpty ?? false);

    return GlassContainer(
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      tint: msg.isError
          ? scheme.errorContainer.withValues(alpha: 0.55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 思维链折叠区
          if (hasReasoning) ...[
            InkWell(
              onTap: () =>
                  setState(() => _reasoningExpanded = !_reasoningExpanded),
              borderRadius: BorderRadius.circular(AppTheme.rSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      context.l.reasoning,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 2),
                    AnimatedRotation(
                      turns: _reasoningExpanded ? 0.5 : 0,
                      duration: AppTheme.fast,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: AppTheme.normal,
              curve: AppTheme.ease,
              alignment: Alignment.topCenter,
              child: _reasoningExpanded
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 6, bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppTheme.rSm),
                      ),
                      child: SelectableText(
                        msg.reasoning!.trim(),
                        style: TextStyle(
                          fontSize: widget.fontSize - 2,
                          height: 1.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
            if (!_reasoningExpanded) const SizedBox(height: 4),
          ],

          // 正文
          if (msg.content.trim().isEmpty && widget.isStreaming)
            const _TypingIndicator()
          else
            MarkdownMessage(
              text: msg.content,
              fontSize: widget.fontSize,
              textColor: msg.isError ? scheme.onErrorContainer : null,
            ),

          // 流式光标
          if (widget.isStreaming && msg.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _BlinkingCursor(color: scheme.primary),
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 编辑态

  Widget _buildEditor(ColorScheme scheme, BorderRadius radius) {
    return GlassContainer(
      borderRadius: radius,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _editController,
            autofocus: true,
            maxLines: null,
            style: TextStyle(fontSize: widget.fontSize, height: 1.5),
decoration: InputDecoration(
               isDense: true,
               contentPadding: EdgeInsets.zero,
               border: InputBorder.none,
               hintText: context.l.editMessage,
             ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => setState(() => _editing = false),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(context.l.cancel, style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: _submitEdit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(_isUser
                    ? context.l.text('保存并重发', 'Save & resend')
                    : context.l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ 操作条

  Widget _buildActionBar(ColorScheme scheme) {
    final items = <Widget>[];

    // 分支页码：1/3
    if (widget.branchTotal > 1) {
      items.add(
        Container(
          margin: const EdgeInsets.only(right: 2),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.rPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: context.l.prevBranch,
                onTap: widget.onPrevBranch,
                color: scheme.primary,
              ),
              Text(
                '${widget.branchIndex + 1}/${widget.branchTotal}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              _MiniIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: context.l.nextBranch,
                onTap: widget.onNextBranch,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      );
    }

    if (_showActions) {
      items.addAll([
        _MiniIconButton(
          icon: Icons.copy_rounded,
          tooltip: context.l.copy,
          onTap: () {
            Clipboard.setData(ClipboardData(text: widget.message.content));
            setState(() => _showActions = false);
            widget.onCopy?.call();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l.text('已复制到剪贴板', 'Copied to clipboard'))),
            );
          },
        ),
        if (widget.onEdit != null)
          _MiniIconButton(
            icon: Icons.edit_outlined,
            tooltip: _isUser
                ? context.l.text('编辑并新建分支', 'Edit as new branch')
                : context.l.editMessage,
            onTap: _startEdit,
          ),
        if (!_isUser && widget.onRegenerate != null)
          _MiniIconButton(
            icon: Icons.refresh_rounded,
            tooltip: context.l.regenerate,
            onTap: () {
              setState(() => _showActions = false);
              widget.onRegenerate!.call();
            },
          ),
        if (widget.onDelete != null)
          _MiniIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: context.l.text('删除此消息及后续', 'Delete this message and later messages'),
            color: scheme.error,
            onTap: () {
              setState(() => _showActions = false);
              widget.onDelete!.call();
            },
          ),
      ]);
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: _isUser ? 0 : 2,
        right: _isUser ? 2 : 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: items,
      ),
    );
  }
}

/// 小号图标按钮，操作条里用
class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.rPill),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 17,
            color: color ?? scheme.onSurfaceVariant,
            semanticLabel: tooltip,
          ),
        ),
      ),
    );
  }
}

/// 等待首个 token 时的三点跳动
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: 20,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = ((_c.value + i * 0.22) % 1.0);
              final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.45 + 0.55 * scale),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

/// 流式输出时的闪烁光标
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});

  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 7,
        height: 15,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}