import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/character_card.dart';
import '../data/services/storage_service.dart';
import '../i18n/strings.dart';
import '../state/config_providers.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

/// 打开角色卡面板
Future<void> showCharacterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _CharacterSheet(),
  );
}

class _CharacterSheet extends ConsumerWidget {
  const _CharacterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final cards = ref.watch(charactersProvider);
    final active = ref.watch(activeCharacterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        return GlassContainer(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.rXl),
          ),
          blur: 34,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 10, 8),
                child: Row(
                  children: [
                    Text(
                      context.l.characters,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openEditor(context, ref, null),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l.text('新建', 'New')),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final c = cards[i];
                    return _CharacterTile(
                      card: c,
                      isActive: c.id == active.id,
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .setActiveCharacter(c.id);
                        Navigator.pop(context);
                      },
                      onEdit: () => _openEditor(context, ref, c),
                      onDuplicate: () => _duplicateCard(context, ref, c),
                      onDelete: () => _confirmDelete(context, ref, c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, CharacterCard? card) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CharacterEditorPage(card: card),
      ),
    );
  }

  Future<void> _duplicateCard(
    BuildContext context,
    WidgetRef ref,
    CharacterCard source,
  ) async {
    String? avatarPath;
    if (source.hasImageAvatar) {
      avatarPath = await StorageService.instance.importMedia(
        source.avatarImagePath!,
        prefix: 'avatar',
      );
    }
    final copy = CharacterCard(
      name: '${source.name} ${context.l.text('副本', 'Copy')}',
      avatarEmoji: source.avatarEmoji,
      avatarImagePath: avatarPath,
      systemPrompt: source.systemPrompt,
      greeting: source.greeting,
      temperature: source.temperature,
      topP: source.topP,
      maxTokens: source.maxTokens,
      presencePenalty: source.presencePenalty,
      frequencyPenalty: source.frequencyPenalty,
      contextLimit: source.contextLimit,
      modelOverride: source.modelOverride,
    );
    await ref.read(charactersProvider.notifier).add(copy);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CharacterCard c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('删除角色卡', 'Delete character')),
        content: Text(context.l.text(
          '「${c.name}」将被删除，已有对话不受影响。',
          '“${c.name}” will be deleted. Existing conversations are unaffected.',
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
    if (ok != true) return;

    await ref.read(charactersProvider.notifier).remove(c.id);
    // 若删的是当前激活卡，切回第一张
    final settings = ref.read(settingsProvider);
    if (settings.activeCharacterId == c.id) {
      final remaining = ref.read(charactersProvider);
      if (remaining.isNotEmpty) {
        await ref
            .read(settingsProvider.notifier)
            .setActiveCharacter(remaining.first.id);
      }
    }
  }
}

class _CharacterTile extends StatelessWidget {
  const _CharacterTile({
    required this.card,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDuplicate,
    this.onDelete,
  });

  final CharacterCard card;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prompt = card.systemPrompt.trim().isEmpty
        ? context.l.text('（无系统提示词）', '(No system prompt)')
        : card.systemPrompt.replaceAll('\n', ' ');

    return AnimatedContainer(
      duration: AppTheme.fast,
      decoration: BoxDecoration(
        color: isActive
            ? scheme.primary.withValues(alpha: 0.13)
            : scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        border: Border.all(
          color: isActive
              ? scheme.primary.withValues(alpha: 0.45)
              : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                  ),
                  child: card.hasImageAvatar
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.rSm),
                          child: Image.file(
                            File(card.avatarImagePath!),
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(
                                card.avatarEmoji,
                                style: const TextStyle(fontSize: 21),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            card.avatarEmoji,
                            style: const TextStyle(fontSize: 21),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.name,
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
                          if (card.isBuiltIn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.onSurfaceVariant
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.rPill),
                              ),
                              child: Text(
                                context.l.builtIn,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prompt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Tag(label: 'T ${card.temperature}'),
                          _Tag(label: 'top_p ${card.topP}'),
                          _Tag(label: '${card.maxTokens} tok'),
                          _Tag(label: '${context.l.contextLimit} ${card.contextLimit}'),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  tooltip: context.l.more,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.rMd),
                  ),
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        onEdit();
                      case 'duplicate':
                        onDuplicate();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(context.l.edit),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          const Icon(Icons.copy_all_outlined, size: 18),
                          const SizedBox(width: 10),
                          Text(context.l.duplicate),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 10),
                            Text(context.l.delete, style: TextStyle(color: scheme.error)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ================================================================ 编辑页

/// 角色卡编辑页：提示词 + 采样参数
class CharacterEditorPage extends ConsumerStatefulWidget {
  const CharacterEditorPage({super.key, this.card});

  /// null 表示新建
  final CharacterCard? card;

  @override
  ConsumerState<CharacterEditorPage> createState() =>
      _CharacterEditorPageState();
}

class _CharacterEditorPageState extends ConsumerState<CharacterEditorPage> {
  late TextEditingController _name;
  late TextEditingController _emoji;
  late TextEditingController _prompt;
  late TextEditingController _greeting;
  late TextEditingController _modelOverride;

  late double _temperature;
  late double _topP;
  late double _presence;
  late double _frequency;
  late int _maxTokens;
  late int _contextLimit;
  String? _avatarImagePath;
  String? _newAvatarImagePath;
  var _saved = false;

  bool get _isNew => widget.card == null;

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    _name = TextEditingController(text: c?.name ?? '');
    _emoji = TextEditingController(text: c?.avatarEmoji ?? '🌙');
    _prompt = TextEditingController(text: c?.systemPrompt ?? '');
    _greeting = TextEditingController(text: c?.greeting ?? '');
    _modelOverride = TextEditingController(text: c?.modelOverride ?? '');
    _temperature = c?.temperature ?? 0.7;
    _topP = c?.topP ?? 1.0;
    _presence = c?.presencePenalty ?? 0.0;
    _frequency = c?.frequencyPenalty ?? 0.0;
    _maxTokens = c?.maxTokens ?? 2048;
    _contextLimit = c?.contextLimit ?? 20;
    _avatarImagePath = c?.avatarImagePath;
  }

  @override
  void dispose() {
    if (!_saved && _newAvatarImagePath != null) {
      unawaited(StorageService.instance.deleteMedia(_newAvatarImagePath));
    }
    _name.dispose();
    _emoji.dispose();
    _prompt.dispose();
    _greeting.dispose();
    _modelOverride.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    final imported = await StorageService.instance.importMedia(
      picked.path,
      prefix: 'avatar',
    );
    if (!mounted || imported == null) return;
    if (_newAvatarImagePath != null && _newAvatarImagePath != imported) {
      await StorageService.instance.deleteMedia(_newAvatarImagePath);
    }
    setState(() {
      _avatarImagePath = imported;
      _newAvatarImagePath = imported;
    });
  }

  Future<void> _removeAvatar() async {
    if (_newAvatarImagePath != null) {
      await StorageService.instance.deleteMedia(_newAvatarImagePath);
    }
    setState(() {
      _avatarImagePath = null;
      _newAvatarImagePath = null;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.text('请填写角色名称', 'Enter a character name'))),
      );
      return;
    }

    final emoji = _emoji.text.trim().isEmpty ? '🌙' : _emoji.text.trim();
    final override =
        _modelOverride.text.trim().isEmpty ? null : _modelOverride.text.trim();

    final notifier = ref.read(charactersProvider.notifier);

    if (_isNew) {
      final card = CharacterCard(
        name: name,
        avatarEmoji: emoji,
        avatarImagePath: _avatarImagePath,
        systemPrompt: _prompt.text,
        greeting: _greeting.text,
        temperature: _temperature,
        topP: _topP,
        maxTokens: _maxTokens,
        presencePenalty: _presence,
        frequencyPenalty: _frequency,
        contextLimit: _contextLimit,
        modelOverride: override,
      );
      await notifier.add(card);
    } else {
      final updated = widget.card!.copyWith(
        name: name,
        avatarEmoji: emoji,
        avatarImagePath: _avatarImagePath,
        clearAvatarImage: _avatarImagePath == null,
        systemPrompt: _prompt.text,
        greeting: _greeting.text,
        temperature: _temperature,
        topP: _topP,
        maxTokens: _maxTokens,
        presencePenalty: _presence,
        frequencyPenalty: _frequency,
        contextLimit: _contextLimit,
        modelOverride: override,
        clearModelOverride: override == null,
      );
      await notifier.update(updated);
      final previous = widget.card!.avatarImagePath;
      if (previous != null && previous != _avatarImagePath) {
        await StorageService.instance.deleteMedia(previous);
      }
    }

    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassBar(
              padding: EdgeInsets.fromLTRB(
                4,
                MediaQuery.viewPaddingOf(context).top + 6,
                12,
                8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: context.l.text('返回', 'Back'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _isNew ? context.l.newCharacter : context.l.text('编辑角色卡', 'Edit character'),
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(context.l.save),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: [
                  _SectionCard(
                    title: context.l.text('基本信息', 'Basic information'),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickAvatar,
                            borderRadius: BorderRadius.circular(AppTheme.rMd),
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.rMd),
                                border: Border.all(
                                  color: scheme.primary.withValues(alpha: 0.28),
                                ),
                              ),
                              child: _avatarImagePath == null
                                  ? Center(
                                      child: Text(
                                        _emoji.text.trim().isEmpty ? '🌙' : _emoji.text,
                                        style: const TextStyle(fontSize: 27),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(AppTheme.rMd),
                                      child: Image.file(
                                        File(_avatarImagePath!),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              children: [
                                _Field(
                                  controller: _name,
                                  label: context.l.characterName,
                                  hint: context.l.text('例如：编程助手', 'For example: Coding assistant'),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    TextButton.icon(
                                      onPressed: _pickAvatar,
                                      icon: const Icon(Icons.image_outlined, size: 16),
                                      label: Text(context.l.pickImage),
                                    ),
                                    if (_avatarImagePath != null)
                                      TextButton(
                                        onPressed: _removeAvatar,
                                        child: Text(context.l.removeImage),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _Field(
                        controller: _emoji,
                        label: context.l.text('备用 Emoji（图片加载失败时显示）', 'Fallback emoji (shown if the image cannot load)'),
                        hint: '🌙',
                        maxLength: 2,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _prompt,
                        label: context.l.systemPrompt,
                        hint: context.l.text('定义 AI 的角色、语气与行为规则…', 'Define the AI role, tone and behavior…'),
                        maxLines: 8,
                        minLines: 4,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _greeting,
                        label: context.l.text('开场白（可选）', 'Greeting (optional)'),
                        hint: context.l.text('新对话时 AI 主动说的第一句话', 'The first message sent by the AI in a new chat'),
                        maxLines: 3,
                        minLines: 2,
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _modelOverride,
                        label: context.l.text('指定模型（可选）', 'Model override (optional)'),
                        hint: context.l.text('留空则使用全局默认模型', 'Leave blank to use the global default model'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: context.l.text('采样参数', 'Sampling parameters'),
                    children: [
                      _SliderRow(
                        label: 'Temperature',
                        desc: context.l.text('越高越随机有创意，越低越稳定保守', 'Higher is more creative and random; lower is more stable'),
                        value: _temperature,
                        min: 0,
                        max: 2,
                        divisions: 40,
                        onChanged: (v) => setState(() => _temperature = v),
                      ),
                      _SliderRow(
                        label: 'Top P',
                        desc: context.l.text('核采样阈值，一般与 Temperature 只调一个', 'Nucleus sampling threshold; usually adjust only this or Temperature'),
                        value: _topP,
                        min: 0,
                        max: 1,
                        divisions: 20,
                        onChanged: (v) => setState(() => _topP = v),
                      ),
                      _SliderRow(
                        label: context.l.presencePenalty,
                        desc: context.l.text('抑制重复出现相同话题', 'Discourages repeating the same topics'),
                        value: _presence,
                        min: -2,
                        max: 2,
                        divisions: 40,
                        onChanged: (v) => setState(() => _presence = v),
                      ),
                      _SliderRow(
                        label: context.l.frequencyPenalty,
                        desc: context.l.text('抑制重复用词', 'Discourages repetitive wording'),
                        value: _frequency,
                        min: -2,
                        max: 2,
                        divisions: 40,
                        onChanged: (v) => setState(() => _frequency = v),
                      ),
                      _SliderRow(
                        label: context.l.maxTokens,
                        desc: context.l.text('单次回复的最大长度', 'Maximum length for one reply'),
                        value: _maxTokens.toDouble(),
                        min: 256,
                        max: 32768,
                        divisions: 127,
                        isInt: true,
                        onChanged: (v) =>
                            setState(() => _maxTokens = v.round()),
                      ),
                      _SliderRow(
                        label: context.l.contextLimit,
                        desc: context.l.text('每次请求携带的历史消息数量，越多越费 token', 'History messages sent with each request; more uses more tokens'),
                        value: _contextLimit.toDouble(),
                        min: 2,
                        max: 100,
                        divisions: 49,
                        isInt: true,
                        onChanged: (v) =>
                            setState(() => _contextLimit = v.round()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l.text(
                      '提示：Temperature 和 Top P 建议只调整其中一个。上下文条数过大会显著增加费用与响应时间。',
                      'Tip: adjust either Temperature or Top P, not both. Too many context messages noticeably increase cost and response time.',
                    ),
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
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
}

// ---------------------------------------------------------------- 复用组件

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppTheme.rSm),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            maxLength: maxLength,
            textAlign: textAlign,
            style: const TextStyle(fontSize: 14, height: 1.45),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.desc,
    this.divisions,
    this.isInt = false,
  });

  final String label;
  final String? desc;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool isInt;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppTheme.rPill),
                ),
                child: Text(
                  isInt ? '${value.round()}' : value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
          if (desc != null)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                desc!,
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: isInt ? '${value.round()}' : value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}