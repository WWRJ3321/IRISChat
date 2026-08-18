import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// 悬浮毛玻璃输入栏。
///
/// 左侧附件扩展按钮，中间自适应多行输入，右侧发送/停止按钮。
/// 流式输出中发送键变为「停止」。
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.isStreaming,
    this.onStop,
    this.onAttachImage,
    this.onAttachCamera,
    this.onVoice,
    this.enabled = true,
    required this.hintText,
    this.thinkingEnabled = false,
    this.thinkingLevel = 2,
    this.onToggleThinking,
    this.onSetThinkingLevel,
  });

  final ValueChanged<String> onSend;
  final bool isStreaming;
  final VoidCallback? onStop;
  final VoidCallback? onAttachImage;
  final VoidCallback? onAttachCamera;
  final VoidCallback? onVoice;
  final bool enabled;
  final String hintText;
  final bool thinkingEnabled;
  final int thinkingLevel;
  final VoidCallback? onToggleThinking;
  final ValueChanged<int>? onSetThinkingLevel;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isStreaming) return;
    _controller.clear();
    setState(() {
      _hasText = false;
      _expanded = false;
    });
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, 10 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 扩展面板
          AnimatedSize(
            duration: AppTheme.normal,
            curve: AppTheme.ease,
            child: _expanded
                ? _buildExpandPanel(scheme)
                : const SizedBox(width: double.infinity, height: 0),
          ),

          // 输入行
          GlassContainer(
            borderRadius: BorderRadius.circular(AppTheme.rXl),
            shadow: true,
            padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 附件/扩展
                _CircleButton(
                  icon: _expanded
                      ? Icons.close_rounded
                      : Icons.add_rounded,
                  tooltip: _expanded ? context.l.collapse : context.l.more,
                  onTap: widget.enabled
                      ? () => setState(() => _expanded = !_expanded)
                      : null,
                  rotated: _expanded,
                ),

                // 思考开关
                if (widget.onToggleThinking != null)
                  _ThinkingButton(
                    enabled: widget.thinkingEnabled,
                    level: widget.thinkingLevel,
                    onTap: widget.enabled ? widget.onToggleThinking : null,
                    onLevelChange: widget.onSetThinkingLevel,
                  ),

                // 输入区
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 132),
                    child: Scrollbar(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        enabled: widget.enabled,
                        minLines: 1,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 11,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                ),

                // 语音（无文本时显示）
                if (!_hasText && !widget.isStreaming)
                  _CircleButton(
                    icon: Icons.mic_none_rounded,
                    tooltip: context.l.voiceInput,
                    onTap: widget.enabled ? widget.onVoice : null,
                  ),

                // 发送 / 停止
                _SendButton(
                  isStreaming: widget.isStreaming,
                  active: _hasText,
                  onTap: widget.isStreaming
                      ? widget.onStop
                      : (_hasText && widget.enabled ? _send : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandPanel(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PanelAction(
              icon: Icons.photo_library_outlined,
              label: context.l.gallery,
              onTap: widget.onAttachImage,
            ),
            _PanelAction(
              icon: Icons.photo_camera_outlined,
              label: context.l.camera,
              onTap: widget.onAttachCamera,
            ),
            _PanelAction(
              icon: Icons.mic_none_rounded,
              label: context.l.voice,
              onTap: widget.onVoice,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.rotated = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool rotated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: AnimatedRotation(
            turns: rotated ? 0.125 : 0,
            duration: AppTheme.fast,
            child: Icon(
              icon,
              size: 22,
              color: onTap == null
                  ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
                  : scheme.onSurfaceVariant,
              semanticLabel: tooltip,
            ),
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.isStreaming,
    required this.active,
    this.onTap,
  });

  final bool isStreaming;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final bg = isStreaming
        ? scheme.error
        : (enabled ? scheme.primary : scheme.surfaceContainerHighest);
    final fg = isStreaming
        ? scheme.onError
        : (enabled
            ? (scheme.primary.computeLuminance() > 0.55
                ? const Color(0xFF06322D)
                : Colors.white)
            : scheme.onSurfaceVariant.withValues(alpha: 0.5));

    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Tooltip(
        message: isStreaming ? context.l.stopGenerating : context.l.send,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.ease,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: bg.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: AnimatedSwitcher(
                  duration: AppTheme.fast,
                  child: Icon(
                    isStreaming
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    key: ValueKey(isStreaming),
                    size: 21,
                    color: fg,
                    semanticLabel: isStreaming ? context.l.stopGenerating : context.l.send,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.rMd),
              ),
              child: Icon(icon, size: 21, color: scheme.primary),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 思考模式按钮：点击开关，长按切换深度 1-3 档。
class _ThinkingButton extends StatefulWidget {
  const _ThinkingButton({
    required this.enabled,
    required this.level,
    this.onTap,
    this.onLevelChange,
  });

  final bool enabled;
  final int level;
  final VoidCallback? onTap;
  final ValueChanged<int>? onLevelChange;

  @override
  State<_ThinkingButton> createState() => _ThinkingButtonState();
}

class _ThinkingButtonState extends State<_ThinkingButton> {
  bool _showLevels = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.enabled ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Tooltip(
          message: '思考 ${widget.enabled ? "L${widget.level}" : "关"}',
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: () => setState(() => _showLevels = !_showLevels),
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(
                Icons.psychology_outlined,
                size: 22,
                color: color,
              ),
            ),
          ),
        ),
        if (_showLevels) ...[
          Positioned(
            bottom: 48,
            left: -8,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppTheme.rSm),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int lv = 1; lv <= 3; lv++)
                      GestureDetector(
                        onTap: () {
                          widget.onLevelChange?.call(lv);
                          setState(() => _showLevels = false);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: widget.level == lv
                                ? scheme.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppTheme.rSm),
                          ),
                          child: Center(
                            child: Text(
                              'L$lv',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.level == lv
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}