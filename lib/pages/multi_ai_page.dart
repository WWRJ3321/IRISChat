import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/api_profile.dart';
import '../data/models/character_card.dart';
import '../data/models/multi_ai_chat.dart';
import '../i18n/strings.dart';
import '../state/config_providers.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';

/// 多 AI 群聊配置页。
///
/// 一个群聊 = 若干角色卡 + 发言顺序 + 每条消息的发言轮数。
/// 每个成员可单独绑定供应商与模型；同一时间只能启用一个群聊。
class MultiAiPage extends ConsumerWidget {
  const MultiAiPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final chats = ref.watch(multiAiChatsProvider);
    final chars = ref.watch(charactersProvider);
    final profiles = ref.watch(apiProfilesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassPageBar(title: context.l.text('多 AI 群聊', 'Group chat')),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
                children: [
                  if (chars.length < 2)
                    _Notice(
                      icon: Icons.info_outline_rounded,
                      text: context.l.text(
                        '群聊至少需要两个角色卡。先到「角色」里多建几个角色。',
                        'A group needs at least two character cards. Create more in Characters first.',
                      ),
                    ),
                  SectionCard(
                    title: context.l.text('群聊列表', 'Groups'),
                    children: [
                      if (chats.isEmpty)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.groups_outlined,
                            color: scheme.onSurfaceVariant,
                          ),
                          title: Text(
                            context.l.text('还没有群聊', 'No groups yet'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      for (final chat in chats)
                        _GroupTile(
                          chat: chat,
                          memberCount: chat.resolveCharacters(chars).length,
                          onToggle: (v) => ref
                              .read(multiAiChatsProvider.notifier)
                              .update(chat.copyWith(enabled: v)),
                          onEdit: () =>
                              _edit(context, ref, chat, chars, profiles),
                          onDelete: () => _confirmDelete(context, ref, chat),
                        ),
                      const Divider(height: 6),
                      ListTile(
                        leading: Icon(
                          Icons.add_circle_outline_rounded,
                          color: scheme.primary,
                        ),
                        title: Text(
                          context.l.text('新建群聊', 'New group'),
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: chars.length < 2
                            ? null
                            : () => _edit(context, ref, null, chars, profiles),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Notice(
                    icon: Icons.lightbulb_outline_rounded,
                    text: context.l.text(
                      '启用群聊后，你发一句话，群里成员会按顺序各自发言。'
                          '每个成员只以自己的身份说话，并能看到别人说过的内容。',
                      'When a group is enabled, every member replies in turn after your message. '
                          'Each member speaks only as itself and can see what others said.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ 删除确认

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, MultiAiChat chat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('删除群聊', 'Delete group')),
        content: Text(context.l.text(
          '「${chat.name}」将被删除，历史对话不受影响。',
          '“${chat.name}” will be deleted. Existing conversations are kept.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(multiAiChatsProvider.notifier).remove(chat.id);
    }
  }

  // ------------------------------------------------------------ 新建 / 编辑

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MultiAiChat? chat,
    List<CharacterCard> chars,
    List<ApiProfile> profiles,
  ) async {
    final defaultName = context.l.text('新群聊', 'New group');
    final nameCtrl = TextEditingController(text: chat?.name ?? defaultName);
    final selected = <String>{...(chat?.characterIds ?? const <String>[])};
    final charProfiles =
        Map<String, String>.from(chat?.characterProfiles ?? const {});
    final charModels =
        Map<String, String>.from(chat?.characterModels ?? const {});
    var mode = chat?.mode ?? MultiAiReplyMode.roundRobin;
    var rounds = (chat?.maxTurnsPerMessage ?? 1).clamp(1, 3).toInt();

    // 清掉已删除角色的残留 id，避免「成员数虚高」
    selected.removeWhere((id) => !chars.any((c) => c.id == id));

    final result = await showDialog<MultiAiChat>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) {
          final scheme = Theme.of(ctx).colorScheme;
          return AlertDialog(
            title: Text(chat == null
                ? context.l.text('新建群聊', 'New group')
                : context.l.text('编辑群聊', 'Edit group')),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            content: SizedBox(
              width: 380,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: context.l.text('群聊名称', 'Group name'),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.rSm),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(context.l.text('发言顺序', 'Speaking order')),
                    const SizedBox(height: 6),
                    _Segmented<MultiAiReplyMode>(
                      value: mode,
                      onChanged: (v) => setState(() => mode = v),
                      items: {
                        MultiAiReplyMode.roundRobin:
                            context.l.text('按顺序', 'In order'),
                        MultiAiReplyMode.random: context.l.text('随机', 'Random'),
                      },
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(
                        context.l.text('每条消息发言轮数', 'Rounds per message')),
                    const SizedBox(height: 6),
                    _Segmented<int>(
                      value: rounds,
                      onChanged: (v) => setState(() => rounds = v),
                      items: const {1: '1', 2: '2', 3: '3'},
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l.text(
                        '轮数越多，成员之间会多来回几句，也更花 token。',
                        'More rounds means members talk back and forth more, and costs more tokens.',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 22),
                    Row(
                      children: [
                        _FieldLabel(context.l.text('成员', 'Members')),
                        const Spacer(),
                        Text(
                          '${selected.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected.length < 2
                                ? scheme.error
                                : scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (selected.length < 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          context.l.text(
                            '至少选择两个成员才能保存。',
                            'Select at least two members to save.',
                          ),
                          style:
                              TextStyle(fontSize: 11.5, color: scheme.error),
                        ),
                      ),
                    const SizedBox(height: 6),
                    for (final c in chars)
                      _MemberRow(
                        card: c,
                        checked: selected.contains(c.id),
                        profiles: profiles,
                        profileId: charProfiles[c.id],
                        model: charModels[c.id],
                        onCheck: (v) => setState(() {
                          if (v) {
                            selected.add(c.id);
                          } else {
                            selected.remove(c.id);
                            charProfiles.remove(c.id);
                            charModels.remove(c.id);
                          }
                        }),
                        onProfile: (id) => setState(() {
                          if (id == null) {
                            charProfiles.remove(c.id);
                            charModels.remove(c.id);
                          } else {
                            charProfiles[c.id] = id;
                            final p = profiles.firstWhere((x) => x.id == id);
                            final def = p.selectedModel.trim();
                            if (def.isNotEmpty) {
                              charModels[c.id] = def;
                            } else {
                              charModels.remove(c.id);
                            }
                          }
                        }),
                        onModel: (m) => setState(() {
                          if (m == null) {
                            charModels.remove(c.id);
                          } else {
                            charModels[c.id] = m;
                          }
                        }),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.l.cancel),
              ),
              FilledButton(
                onPressed: selected.length < 2
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          (chat ?? MultiAiChat()).copyWith(
                            name: nameCtrl.text.trim().isEmpty
                                ? defaultName
                                : nameCtrl.text.trim(),
                            characterIds: selected.toList(),
                            mode: mode,
                            maxTurnsPerMessage: rounds,
                            characterProfiles: charProfiles,
                            characterModels: charModels,
                          ),
                        ),
                child: Text(context.l.save),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
    if (result == null || result.characterIds.length < 2) return;
    final notifier = ref.read(multiAiChatsProvider.notifier);
    if (chat == null) {
      await notifier.add(result);
    } else {
      await notifier.update(result);
    }
  }
}

// ---------------------------------------------------------------- 子组件

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.chat,
    required this.memberCount,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final MultiAiChat chat;
  final int memberCount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final broken = memberCount < 2;
    final order = chat.mode == MultiAiReplyMode.roundRobin
        ? context.l.text('按顺序', 'in order')
        : context.l.text('随机', 'random');

    return ListTile(
      leading: Icon(
        chat.enabled && !broken
            ? Icons.groups_rounded
            : Icons.group_outlined,
        color: chat.enabled && !broken
            ? scheme.primary
            : scheme.onSurfaceVariant,
      ),
      title: Text(
        chat.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: chat.enabled && !broken ? scheme.primary : scheme.onSurface,
        ),
      ),
      subtitle: Text(
        broken
            ? context.l.text('成员不足两人，无法启用', 'Fewer than two members')
            : context.l.text(
                '$memberCount 人 · $order · ${chat.maxTurnsPerMessage} 轮',
                '$memberCount members · $order · ${chat.maxTurnsPerMessage} round(s)',
              ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: broken ? scheme.error : scheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillSwitch(
            value: chat.enabled && !broken,
            onChanged: broken ? null : onToggle,
          ),
          IconButton(
            tooltip: context.l.delete,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onEdit,
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.card,
    required this.checked,
    required this.profiles,
    required this.profileId,
    required this.model,
    required this.onCheck,
    required this.onProfile,
    required this.onModel,
  });

  final CharacterCard card;
  final bool checked;
  final List<ApiProfile> profiles;
  final String? profileId;
  final String? model;
  final ValueChanged<bool> onCheck;
  final ValueChanged<String?> onProfile;
  final ValueChanged<String?> onModel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final follow = context.l.text('沿用全局配置', 'Use global profile');
    final pickFirst = context.l.text('先选供应商', 'Pick a provider first');
    final defModel = context.l.text('默认模型', 'Default model');

    ApiProfile? bound;
    for (final p in profiles) {
      if (p.id == profileId) bound = p;
    }
    final models = bound == null
        ? const <String>[]
        : (bound.models.isNotEmpty
            ? bound.models
            : (bound.selectedModel.trim().isNotEmpty
                ? <String>[bound.selectedModel.trim()]
                : const <String>[]));

    return AnimatedContainer(
      duration: AppTheme.fast,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
      decoration: BoxDecoration(
        color:
            checked ? scheme.primary.withValues(alpha: 0.07) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.rSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppTheme.rSm),
            onTap: () => onCheck(!checked),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  visualDensity: VisualDensity.compact,
                  onChanged: (v) => onCheck(v ?? false),
                ),
                Text(card.avatarEmoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    card.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          if (checked)
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 2, bottom: 2),
              child: Column(
                children: [
                  _MiniDropdown<String?>(
                    label: context.l.text('供应商', 'Provider'),
                    value: bound == null ? null : profileId,
                    hint: follow,
                    items: <String?, String>{
                      null: follow,
                      for (final p in profiles) p.id: p.name,
                    },
                    onChanged: onProfile,
                  ),
                  const SizedBox(height: 6),
                  _MiniDropdown<String?>(
                    label: context.l.text('模型', 'Model'),
                    value:
                        (model != null && models.contains(model)) ? model : null,
                    hint: bound == null ? pickFirst : defModel,
                    items: <String?, String>{
                      null: bound == null ? pickFirst : defModel,
                      for (final m in models) m: m,
                    },
                    onChanged: bound == null ? null : onModel,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 统一风格的小号下拉框，避免各处样式不一致。
class _MiniDropdown<T> extends StatelessWidget {
  const _MiniDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final String hint;
  final Map<T, String> items;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.rSm),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppTheme.rSm),
                hint: Text(hint, style: const TextStyle(fontSize: 12.5)),
                style: TextStyle(fontSize: 12.5, color: scheme.onSurface),
                items: [
                  for (final e in items.entries)
                    DropdownMenuItem<T>(
                      value: e.key,
                      child: Text(
                        e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                ],
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged!(v as T),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 轻量分段选择器：比 SegmentedButton 更紧凑，窄屏也不会换行。
class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.primary.computeLuminance() > 0.55
        ? const Color(0xFF06322D)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Row(
        children: [
          for (final e in items.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: AppTheme.fast,
                  curve: AppTheme.ease,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        e.key == value ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.rPill),
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: e.key == value ? onPrimary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.rMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}