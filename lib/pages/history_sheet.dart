import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/models/conversation.dart';
import '../i18n/strings.dart';
import '../state/chat_provider.dart';
import '../theme/app_theme.dart';

/// 从左侧滑入的历史对话侧边栏。
///
/// 用 Drawer + 全屏 Scaffold 承载，避免之前 showGeneralDialog 手搓布局
/// 带来的把手条错位、黄色下划线等渲染问题。
Future<void> showHistorySidebar(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppTheme.normal,
    pageBuilder: (_, __, ___) => const _HistorySidebar(),
    transitionBuilder: (context, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: AppTheme.ease);
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(curved),
        child: child,
      );
    },
  );
}

class _HistorySidebar extends ConsumerStatefulWidget {
  const _HistorySidebar();

  @override
  ConsumerState<_HistorySidebar> createState() => _HistorySidebarState();
}

class _HistorySidebarState extends ConsumerState<_HistorySidebar> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = ref.watch(conversationsProvider);
    final currentId = ref.watch(currentConversationIdProvider);
    final width = (MediaQuery.sizeOf(context).width * 0.82).clamp(0.0, 380.0);

    final q = _query.trim().toLowerCase();
    final list = q.isEmpty
        ? all
        : all.where((c) {
            if (c.title.toLowerCase().contains(q)) return true;
            // 关键词也匹配消息正文
            return c.messages.values
                .any((m) => m.content.toLowerCase().contains(q));
          }).toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Material(
          color: scheme.surface,
          elevation: 16,
          child: SafeArea(
            right: false,
            child: Column(
              children: [
                _buildHeader(scheme, all.length),
                _buildSearch(scheme),
                const Divider(height: 1),
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Text(
                            q.isEmpty
                                ? context.l.noHistory
                                : context.l.text('没有匹配的对话', 'No matches'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) {
                            final c = list[i];
                            return _ConversationTile(
                              conversation: c,
                              isActive: c.id == currentId,
                              onTap: () {
                                ref
                                    .read(chatProvider.notifier)
                                    .openConversation(c);
                                Navigator.pop(context);
                              },
                              onPin: () => ref
                                  .read(conversationsProvider.notifier)
                                  .togglePin(c),
                              onRename: () => _renameDialog(c),
                              onDelete: () => _confirmDelete(c),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
      child: Row(
        children: [
          Text(
            context.l.history,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppTheme.rPill),
            ),
            child: Text(
              '$total',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: context.l.newChat,
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(chatProvider.notifier).newConversation();
            },
          ),
          if (total > 0)
            IconButton(
              tooltip: context.l.clearAllChats,
              icon: Icon(Icons.delete_sweep_outlined, color: scheme.error),
              onPressed: _confirmClearAll,
            ),
        ],
      ),
    );
  }

  Widget _buildSearch(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          hintText: context.l.text('搜索标题或内容', 'Search title or content'),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.rPill),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _renameDialog(Conversation c) async {
    final controller = TextEditingController(text: c.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('重命名对话', 'Rename conversation')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
              hintText: context.l.text('对话标题', 'Conversation title')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.trim().isNotEmpty) {
      await ref.read(conversationsProvider.notifier).rename(c, result);
    }
  }

  Future<void> _moveToTrash(Conversation c) async {
    final wasCurrent = ref.read(currentConversationIdProvider) == c.id;
    await ref.read(conversationsProvider.notifier).remove(c.id);
    if (wasCurrent) {
      final remaining = ref.read(conversationsProvider);
      final notifier = ref.read(chatProvider.notifier);
      if (remaining.isNotEmpty) {
        notifier.openConversation(remaining.first);
      } else {
        await notifier.newConversation();
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l.text(
          '已将「${c.title}」移入回收站',
          '“${c.title}” moved to trash',
        )),
        action: SnackBarAction(
          label: context.l.undo,
          onPressed: () =>
              ref.read(conversationsProvider.notifier).restore(c.id),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Conversation c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('删除对话', 'Delete conversation')),
        content: Text(context.l.text(
          '「${c.title}」将移入回收站，30 天内可恢复。',
          '“${c.title}” will be moved to trash and can be restored within 30 days.',
        )),
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
    if (ok == true) await _moveToTrash(c);
  }

  Future<void> _confirmClearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('清空全部对话', 'Delete all conversations')),
        content: Text(context.l.text(
          '所有历史对话会移入回收站，30 天内可以恢复。',
          'All conversations will be moved to trash and can be restored within 30 days.',
        )),
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
            child: Text(context.l.text('全部删除', 'Delete all')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(conversationsProvider.notifier).moveAllToTrash();
    await ref.read(chatProvider.notifier).newConversation();
    if (mounted) Navigator.pop(context);
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.isActive,
    required this.onTap,
    required this.onPin,
    required this.onRename,
    required this.onDelete,
  });

  final Conversation conversation;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = conversation;
    final msgCount = c.messages.length;
    final preview = c.activePath.isEmpty
        ? context.l.text('（空对话）', '(Empty conversation)')
        : c.activePath.last.content.replaceAll('\n', ' ');

    return Material(
      color: isActive
          ? scheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.rMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (c.pinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Icon(Icons.push_pin_rounded,
                                size: 13, color: scheme.primary),
                          ),
                        Expanded(
                          child: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  isActive ? scheme.primary : scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l.text(
                        '$msgCount 条 · ${_formatTime(context, c.updatedAt)}',
                        '$msgCount msgs · ${_formatTime(context, c.updatedAt)}',
                      ),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
                tooltip: context.l.more,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.rMd),
                ),
                onSelected: (v) {
                  switch (v) {
                    case 'pin':
                      onPin();
                    case 'rename':
                      onRename();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          c.pinned
                              ? Icons.push_pin_outlined
                              : Icons.push_pin_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(c.pinned ? context.l.unpin : context.l.pin),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 18),
                        const SizedBox(width: 10),
                        Text(context.l.rename),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: scheme.error),
                        const SizedBox(width: 10),
                        Text(context.l.delete,
                            style: TextStyle(color: scheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return context.l.text('刚刚', 'Just now');
    if (diff.inHours < 1) {
      return context.l.text('${diff.inMinutes} 分钟前', '${diff.inMinutes} min ago');
    }
    if (diff.inDays < 1) {
      return context.l.text('${diff.inHours} 小时前', '${diff.inHours} hr ago');
    }
    if (diff.inDays < 7) {
      return context.l.text('${diff.inDays} 天前', '${diff.inDays} days ago');
    }
    return DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(t);
  }
}