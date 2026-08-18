import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/storage_service.dart';
import '../i18n/strings.dart';
import '../state/chat_provider.dart';
import '../state/config_providers.dart';
import '../state/settings_provider.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';
import 'about_page.dart';
import 'api_config_page.dart';
import 'appearance_page.dart';
import 'character_sheet.dart';
import 'trash_page.dart';
import 'multi_ai_page.dart';

/// 设置总入口
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final profiles = ref.watch(apiProfilesProvider);
    final active = ref.watch(activeApiProfileProvider);
    final characters = ref.watch(charactersProvider);
    final activeChar = ref.watch(activeCharacterProvider);
    final conversations = ref.watch(conversationsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassPageBar(title: context.l.settings),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: [
                  SectionCard(
                    title: context.l.text('模型与接口', 'Models & API'),
                    children: [
                      NavRow(
                        label: context.l.apiConfig,
                        desc: active == null
                            ? context.l.text('尚未配置，点击添加', 'Not configured. Tap to add')
                            : '${active.name} · ${active.selectedModel}',
                        icon: Icons.cloud_outlined,
                        trailingText: context.l.text('${profiles.length} 个', '${profiles.length}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ApiConfigPage(),
                          ),
                        ),
                      ),
const Divider(height: 6),
                       NavRow(
                         label: context.l.text('多 AI 群聊', 'Multi-AI group chat'),
                         desc: context.l.text('让多个角色轮流或随机参与对话', 'Let multiple characters take turns or reply randomly'),
                         icon: Icons.groups_outlined,
                         trailingText: context.l.text('配置', 'Configure'),
                         onTap: () => Navigator.of(context).push(
                           MaterialPageRoute(builder: (_) => const MultiAiPage()),
                         ),
                       ),
                       const Divider(height: 6),
                       NavRow(
                         label: context.l.text('角色卡与参数', 'Characters & parameters'),
                        desc: context.l.text('当前：${activeChar.name} · T ${activeChar.temperature}', 'Active: ${activeChar.name} · T ${activeChar.temperature}'),
                        icon: Icons.person_outline_rounded,
                        trailingText: context.l.text('${characters.length} 张', '${characters.length}'),
                        onTap: () => showCharacterSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.appearance,
                    children: [
                      NavRow(
                        label: context.l.appearance,
                        desc: context.l.text('主色、深色模式、OLED 纯黑、毛玻璃、壁纸', 'Accent color, dark mode, OLED black, glass and wallpaper'),
                        icon: Icons.palette_outlined,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AppearancePage(),
                          ),
                        ),
                      ),
                      const Divider(height: 6),
                      SwitchRow(
                        label: context.l.showTimestamp,
                        icon: Icons.schedule_rounded,
                        value: settings.showTimestamp,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setShowTimestamp(v),
                      ),
                      SwitchRow(
                        label: context.l.animation,
                        desc: context.l.text('关闭可略微提升低端设备性能', 'Disable to slightly improve performance on lower-end devices'),
                        icon: Icons.animation_rounded,
                        value: settings.enableAnimation,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setEnableAnimation(v),
                      ),
                      const Divider(height: 6),
                      SwitchRow(
                        label: context.l.text('启动时新建对话', 'Start new chat on launch'),
                        desc: context.l.text('关闭则继续上次的对话', 'Turn off to resume the last conversation'),
                        icon: Icons.fiber_new_rounded,
                        value: settings.startNewChat,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setStartNewChat(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.dataAndBackup,
                    children: [
                      NavRow(
                        label: context.l.exportData,
                        desc: context.l.text('将全部对话、角色卡与配置复制到剪贴板', 'Copy all conversations, characters and settings to the clipboard'),
                        icon: Icons.upload_file_outlined,
                        onTap: () => _exportData(context),
                      ),
                      const Divider(height: 6),
                      NavRow(
                        label: context.l.importData,
                        desc: context.l.text('读取剪贴板中的备份 JSON 并合并', 'Read and merge backup JSON from the clipboard'),
                        icon: Icons.download_outlined,
                        onTap: () => _importData(context, ref),
                      ),
                      const Divider(height: 6),
                      NavRow(
                        label: context.l.trash,
                        desc: context.l.trashHint,
                        icon: Icons.delete_outline_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TrashPage()),
                        ),
                      ),
                      const Divider(height: 6),
                      NavRow(
                        label: context.l.clearAllChats,
                        desc: context.l.text('共 ${conversations.length} 个对话，将移入回收站', '${conversations.length} conversations will be moved to trash'),
                        icon: Icons.delete_sweep_outlined,
                        danger: true,
                        onTap: () => _confirmClearConversations(context, ref),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.about,
                    children: [
                      NavRow(
                        label: context.l.about,
                        desc: context.l.text('版本信息、功能说明与使用提示', 'Version info, features and usage tips'),
                        icon: Icons.info_outline_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutPage(),
                          ),
                        ),
                      ),
                      const Divider(height: 6),
                      NavRow(
                        label: context.l.reset,
                        desc: context.l.text('仅重置外观与偏好，不删除对话数据', 'Reset appearance and preferences without deleting conversations'),
                        icon: Icons.restart_alt_rounded,
                        onTap: () => _confirmReset(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final json = StorageService.instance.exportAll();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l.text(
          '备份已复制到剪贴板（${(json.length / 1024).toStringAsFixed(1)} KB）',
          'Backup copied to clipboard (${(json.length / 1024).toStringAsFixed(1)} KB)',
        )),
      ),
    );
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim();
    if (raw == null || raw.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('剪贴板为空', 'Clipboard is empty'))),
      );
      return;
    }

    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.importData),
        content: Text(context.l.text(
          '将把剪贴板中的数据合并到现有数据中。同 ID 的条目会被覆盖。',
          'Backup data from the clipboard will be merged. Items with matching IDs will be replaced.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.importData),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await StorageService.instance.importAll(raw);
      ref.read(conversationsProvider.notifier).refresh();
      ref.invalidate(charactersProvider);
      ref.invalidate(apiProfilesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('导入成功，重启应用后完全生效', 'Import complete. Restart the app to apply all changes.'))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('导入失败：$e', 'Import failed: $e'))),
      );
    }
  }

  Future<void> _confirmClearConversations(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.clearAllChats),
        content: Text(context.l.text(
          '所有对话会移入回收站，30 天内可以恢复；角色卡与 API 配置保留。',
          'All conversations will be moved to trash and can be restored within 30 days. Characters and API providers are kept.',
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
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l.text('已清空所有对话', 'All conversations moved to trash'))),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.reset),
        content: Text(context.l.text(
          '外观、配色、字号等偏好将恢复初始值。对话与配置数据不受影响。',
          'Appearance, colors and text size will reset. Conversations and providers are not affected.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.reset),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(settingsProvider.notifier).reset();
  }
}