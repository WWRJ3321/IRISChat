import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/conversation.dart';
import '../data/services/storage_service.dart';
import '../i18n/strings.dart';
import '../state/chat_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';

/// 软删除会话的管理页。条目会在删除 30 天后自动清理。
class TrashPage extends ConsumerWidget {
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final trash = StorageService.instance.loadTrash();
    // Watch this provider so restore/delete refreshes the page.
    ref.watch(conversationsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassPageBar(
              title: context.l.trash,
              actions: [
                if (trash.isNotEmpty)
                  IconButton(
                    tooltip: context.l.emptyTrash,
                    icon: Icon(Icons.delete_sweep_outlined, color: scheme.error),
                    onPressed: () => _confirmEmpty(context, ref),
                  ),
              ],
            ),
            Expanded(
              child: trash.isEmpty
                  ? Center(
                      child: Text(
                        context.l.trashEmpty,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                      itemCount: trash.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final item = trash[index];
                        return GlassContainer(
                          borderRadius: BorderRadius.circular(AppTheme.rMd),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l.text(
                                          '${item.messages.length} 条消息 · ${item.trashDaysLeft ?? 0} 天后自动清除',
                                          '${item.messages.length} messages · ${context.l.daysLeft(item.trashDaysLeft ?? 0)}',
                                       ),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: context.l.restore,
                                  icon: const Icon(Icons.restore_rounded),
                                  onPressed: () => ref
                                      .read(conversationsProvider.notifier)
                                      .restore(item.id),
                                ),
                                IconButton(
                                  tooltip: context.l.deleteForever,
                                  icon: Icon(Icons.delete_forever_outlined, color: scheme.error),
                                  onPressed: () => _confirmDelete(context, ref, item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Conversation item,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('彻底删除对话', 'Delete conversation forever')),
        content: Text(context.l.text(
          '「${item.title}」将永久删除，无法恢复。',
          '“${item.title}” will be deleted permanently and cannot be restored.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.deleteForever),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(conversationsProvider.notifier).deletePermanently(item.id);
    }
  }

  Future<void> _confirmEmpty(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.emptyTrash),
        content: Text(context.l.text(
          '回收站内所有对话都会永久删除，无法恢复。',
          'All conversations in the trash will be deleted permanently and cannot be restored.',
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.text('清空', 'Empty')),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(conversationsProvider.notifier).emptyTrash();
  }
}
