import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/api_profile.dart';
import '../data/services/chat_service.dart';
import '../i18n/strings.dart';
import '../state/config_providers.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';

/// API 配置页：管理多个 OpenAI 兼容服务商配置
class ApiConfigPage extends ConsumerWidget {
  const ApiConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final profiles = ref.watch(apiProfilesProvider);
    final active = ref.watch(activeApiProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassPageBar(
title: context.l.apiConfig,
               actions: [
                 IconButton(
                   tooltip: context.l.addProfile,
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => _openEditor(context, null),
                ),
              ],
            ),
            Expanded(
              child: profiles.isEmpty
                  ? _buildEmpty(context)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final p = profiles[i];
                        return _ProfileCard(
                          profile: p,
                          isActive: p.id == active?.id,
                          onTap: () => ref
                              .read(settingsProvider.notifier)
                              .setActiveApiProfile(p.id),
                          onEdit: () => _openEditor(context, p),
                          onDelete: () => _confirmDelete(context, ref, p),
                        );
                      },
                    ),
            ),
            if (profiles.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: FilledButton.icon(
                  onPressed: () => _openEditor(context, null),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(context.l.text('添加第一个 API 配置', 'Add your first API provider')),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              context.l.text('还没有 API 配置', 'No API providers yet'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
context.l.text(
                '添加一个 OpenAI 兼容的接口地址和密钥即可开始对话。\n支持 OpenAI、DeepSeek、Moonshot、硅基流动、Ollama 等。',
                'Add an OpenAI-compatible Base URL and API key to start chatting.\nOpenAI, DeepSeek, Moonshot, SiliconFlow and Ollama are supported.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, ApiProfile? profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ApiEditorPage(profile: profile)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ApiProfile p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
title: Text(context.l.text('删除 API 配置', 'Delete API provider')),
         content: Text(context.l.text(
           '「${p.name}」将被删除，包括其中保存的密钥。',
           '“${p.name}” and its saved API key will be deleted.',
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
    if (ok == true) {
      await ref.read(apiProfilesProvider.notifier).remove(p.id);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ApiProfile profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = profile;

    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      tint: isActive ? scheme.primary.withValues(alpha: 0.13) : null,
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(AppTheme.rLg),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: scheme.primary,
                              ),
                            ),
                          Flexible(
                            child: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        p.baseUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Chip(
                            label: p.selectedModel.isEmpty
                                ? context.l.text('未选模型', 'No model selected')
                                : p.selectedModel,
                            highlight: p.selectedModel.isEmpty,
                          ),
                          _Chip(label: p.stream ? context.l.streamOutput : context.l.text('非流式', 'Non-streaming')),
                          _Chip(
                            label: p.apiKey.isEmpty
                                ? context.l.text('无密钥', 'No API key')
                                : context.l.text('已配密钥', 'API key set'),
                            highlight: p.apiKey.isEmpty,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      tooltip: context.l.edit,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      tooltip: context.l.delete,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: scheme.error,
                      ),
                      onPressed: onDelete,
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.highlight = false});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.error.withValues(alpha: 0.14)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.rPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: highlight ? scheme.error : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ================================================================ 编辑页

class ApiEditorPage extends ConsumerStatefulWidget {
  const ApiEditorPage({super.key, this.profile});

  final ApiProfile? profile;

  @override
  ConsumerState<ApiEditorPage> createState() => _ApiEditorPageState();
}

class _ApiEditorPageState extends ConsumerState<ApiEditorPage> {
  late TextEditingController _name;
  late TextEditingController _baseUrl;
  late TextEditingController _apiKey;
  late TextEditingController _model;

  late List<String> _models;
  late bool _stream;
  bool _obscureKey = true;
  bool _fetching = false;
  String? _testResult;
  bool _testOk = false;
  String _modelFilter = '';

  bool get _isNew => widget.profile == null;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _name = TextEditingController(text: p?.name ?? '');
    _baseUrl = TextEditingController(text: p?.baseUrl ?? '');
    _apiKey = TextEditingController(text: p?.apiKey ?? '');
    _model = TextEditingController(text: p?.selectedModel ?? '');
    _models = List<String>.from(p?.models ?? const []);
    _stream = p?.stream ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _model.dispose();
    super.dispose();
  }

  ApiProfile _buildProfile() {
    return (widget.profile ?? ApiProfile()).copyWith(
      name: _name.text.trim().isEmpty
          ? context.l.text('未命名配置', 'Untitled provider')
          : _name.text.trim(),
      baseUrl: _baseUrl.text.trim(),
      apiKey: _apiKey.text.trim(),
      models: _models,
      selectedModel: _model.text.trim(),
      stream: _stream,
    );
  }

  Future<void> _save() async {
    if (_baseUrl.text.trim().isEmpty) {
      _snack(context.l.text('请填写 Base URL', 'Enter a Base URL'));
      return;
    }
    if (_model.text.trim().isEmpty) {
      _snack(context.l.text('请填写或选择模型名', 'Enter or select a model name'));
      return;
    }

    final p = _buildProfile();
    final notifier = ref.read(apiProfilesProvider.notifier);
    if (_isNew) {
      await notifier.add(p);
      // 首个配置自动设为激活
      final all = ref.read(apiProfilesProvider);
      if (all.length == 1) {
        await ref.read(settingsProvider.notifier).setActiveApiProfile(p.id);
      }
    } else {
      await notifier.update(p);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addModel() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l.text('添加模型', 'Add model')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l.text('模型名', 'Model name'),
            hintText: context.l.text('例如 deepseek-chat', 'For example: deepseek-chat'),
          ),
          onSubmitted: (value) => Navigator.pop(ctx, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(context.l.add),
          ),
        ],
      ),
    );
    controller.dispose();
    final model = result?.trim() ?? '';
    if (model.isEmpty) return;
    setState(() {
      if (!_models.contains(model)) _models.add(model);
      _models.sort();
      _model.text = model;
    });
  }

  Future<void> _fetchModels() async {
    if (_baseUrl.text.trim().isEmpty) {
      _snack(context.l.text('请先填写 Base URL', 'Enter a Base URL first'));
      return;
    }
    setState(() {
      _fetching = true;
      _testResult = null;
    });

    try {
      final service = ChatService();
      final list = await service.fetchModels(_buildProfile());
      if (!mounted) return;
      setState(() {
        _models = {..._models, ...list}.toList()..sort();
        _testOk = true;
        _testResult = context.l.text('成功获取 ${list.length} 个模型', 'Fetched ${list.length} models successfully');
        if (_model.text.trim().isEmpty && list.isNotEmpty) {
          _model.text = list.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testResult = e is ApiException
            ? e.messageFor(context.l.isZh)
            : context.l.errorNetwork;
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
            GlassPageBar(
              title: _isNew
                  ? context.l.text('新建 API 配置', 'New API provider')
                  : context.l.text('编辑 API 配置', 'Edit API provider'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    child: Text(context.l.save),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: [
                  // 快速预设
                  SectionCard(
                    title: context.l.text('服务商预设', 'Provider presets'),
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ApiProfile.presets.entries.map((e) {
                          return ActionChip(
                            label: Text(e.key),
                            onPressed: () {
                              setState(() {
                                _baseUrl.text = e.value;
                                if (_name.text.trim().isEmpty) {
                                  _name.text = e.key;
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.text('连接信息', 'Connection'),
                    children: [
                      LabeledField(
                        controller: _name,
                        label: context.l.profileName,
                        hint: context.l.text('例如：我的 DeepSeek', 'For example: My DeepSeek'),
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        controller: _baseUrl,
                        label: context.l.baseUrl,
                        hint: 'https://api.openai.com/v1',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l.text('填到 /v1 为止，不要带 /chat/completions', 'Enter up to /v1; do not include /chat/completions'),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LabeledField(
                        controller: _apiKey,
                        label: context.l.apiKey,
                        hint: 'sk-…',
                        obscure: _obscureKey,
                        suffix: Row(
                          children: [
                            IconButton(
                              tooltip: _obscureKey
                                  ? context.l.text('显示', 'Show')
                                  : context.l.text('隐藏', 'Hide'),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                _obscureKey
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureKey = !_obscureKey),
                            ),
                            IconButton(
                              tooltip: context.l.paste,
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.content_paste_rounded),
                              onPressed: () async {
                                final d = await Clipboard.getData(
                                  Clipboard.kTextPlain,
                                );
                                if (d?.text != null) {
                                  setState(() => _apiKey.text = d!.text!.trim());
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l.text('密钥仅保存在本机，不会上传到任何第三方。', 'Your API key stays on this device and is never uploaded to a third party.'),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

SectionCard(
                    title: context.l.models,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _addModel,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(context.l.add, style: const TextStyle(fontSize: 12.5)),
                        ),
                        TextButton.icon(
                          onPressed: _fetching ? null : _fetchModels,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: _fetching
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.cloud_download_outlined, size: 16),
                          label: Text(
                            _fetching
                                ? context.l.text('获取中', 'Fetching')
                                : context.l.text('拉取', 'Fetch'),
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      LabeledField(
                        controller: _model,
                        label: context.l.text('模型名', 'Model name'),
                        hint: 'gpt-4o-mini / deepseek-chat …',
                      ),
                      if (_models.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l.text('可用模型（点击选择默认）', 'Available models (tap to set default)'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              '${_models.length}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 模型搜索框：列表长时快速筛选
                        if (_models.length > 6)
                          TextField(
                            onChanged: (v) =>
                                setState(() => _modelFilter = v.trim().toLowerCase()),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: scheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              hintText: context.l.text('搜索模型', 'Search models'),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.rSm),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        if (_models.length > 6) const SizedBox(height: 8),
                        Builder(
                          builder: (_) {
                            final shown = _modelFilter.isEmpty
                                ? _models
                                : _models
                                    .where((m) => m
                                        .toLowerCase()
                                        .contains(_modelFilter))
                                    .toList();
                            if (shown.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  context.l.text('没有匹配的模型', 'No matching models'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              );
                            }
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 240),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: shown.map((m) {
                                    final selected = m == _model.text.trim();
                                    return _ModelRow(
                                      name: m,
                                      selected: selected,
                                      onTap: () =>
                                          setState(() => _model.text = m),
                                      onRemove: () => setState(() {
                                        _models.remove(m);
                                        if (_model.text.trim() == m) {
                                          _model.text = '';
                                        }
                                      }),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      if (_testResult != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: (_testOk ? scheme.primary : scheme.error)
                                .withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(AppTheme.rSm),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _testOk
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.error_outline_rounded,
                                size: 17,
                                color: _testOk ? scheme.primary : scheme.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _testResult!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: _testOk
                                        ? scheme.primary
                                        : scheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.text('请求选项', 'Request options'),
                    children: [
                      SwitchRow(
                        label: context.l.streamOutput,
                        desc: context.l.text('逐字显示回复。若接口不支持 SSE 请关闭', 'Show replies as they arrive. Disable if the API does not support SSE'),
                        icon: Icons.bolt_rounded,
                        value: _stream,
                        onChanged: (v) => setState(() => _stream = v),
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
}

/// 模型列表里的一行：点行设为默认（打勾），右侧可删除。
class _ModelRow extends StatelessWidget {
  const _ModelRow({
    required this.name,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.rSm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}