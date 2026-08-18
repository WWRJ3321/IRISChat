import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../i18n/strings.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';

/// 外观设置页：配色 / 深色模式 / OLED / 毛玻璃 / 壁纸 / 圆角字号
class AppearancePage extends ConsumerStatefulWidget {
  const AppearancePage({super.key});

  @override
  ConsumerState<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends ConsumerState<AppearancePage> {
  final _wallpaperController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _wallpaperController.text =
        ref.read(settingsProvider).wallpaperPath ?? '';
  }

  @override
  void dispose() {
    _wallpaperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AppBackground(
        wallpaperPath: settings.wallpaperPath,
        wallpaperOpacity: settings.wallpaperOpacity,
        oledBlack: settings.oledBlack,
        child: Column(
          children: [
            GlassPageBar(title: context.l.appearance),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                children: [
                  // 实时预览
                  _PreviewCard(settings: settings),
                  const SizedBox(height: 12),

                  // 配色
                  SectionCard(
                    title: context.l.accentColor,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: AppSettings.presetAccents.entries.map((e) {
                          final selected =
                              settings.accentColorValue == e.value;
                          return _ColorDot(
                            color: Color(e.value),
                            label: e.key,
                            selected: selected,
                            onTap: () => notifier.setAccentColor(e.value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 明暗模式
                  SectionCard(
                    title: context.l.themeMode,
                    children: [
                      SegmentedButton<int>(
                        segments: [
                          ButtonSegment(
                            value: 0,
                            label: Text(context.l.light),
                            icon: const Icon(Icons.light_mode_outlined, size: 17),
                          ),
                          ButtonSegment(
                            value: 1,
                            label: Text(context.l.dark),
                            icon: const Icon(Icons.dark_mode_outlined, size: 17),
                          ),
                          ButtonSegment(
                            value: 2,
                            label: Text(context.l.followSystem),
                            icon: const Icon(Icons.brightness_auto_outlined, size: 17),
                          ),
                        ],
                        selected: {settings.themeModeIndex},
                        onSelectionChanged: (s) =>
                            notifier.setThemeMode(s.first),
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.rPill),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchRow(
                        label: context.l.oledBlack,
                        desc: context.l.oledBlackHint,
                        icon: Icons.contrast_rounded,
                        value: settings.oledBlack,
                        onChanged: notifier.setOledBlack,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 毛玻璃
                  SectionCard(
                    title: context.l.glass,
                    children: [
                      SwitchRow(
                        label: context.l.glass,
                        desc: context.l.glassHint,
                        icon: Icons.blur_on_rounded,
                        value: settings.glassEnabled,
                        onChanged: notifier.setGlassEnabled,
                      ),
                      if (settings.glassEnabled) ...[
                        const SizedBox(height: 8),
                        SliderRow(
                          label: context.l.blurRadius,
                          value: settings.glassBlur,
                          min: 4,
                          max: 50,
                          divisions: 23,
                          isInt: true,
                          onChanged: notifier.setGlassBlur,
                        ),
                        SliderRow(
                          label: context.l.glassOpacity,
                          desc: context.l.text('数值越大玻璃越不透明', 'Higher values make glass less transparent'),
                          value: settings.glassOpacity,
                          min: 0.02,
                          max: 0.4,
                          divisions: 38,
                          onChanged: notifier.setGlassOpacity,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 壁纸
                  SectionCard(
                    title: context.l.wallpaper,
                    children: [
                      LabeledField(
                        controller: _wallpaperController,
                        label: context.l.text('图片路径', 'Image path'),
                        hint: '/sdcard/Pictures/bg.jpg',
                        suffix: Row(
                          children: [
                            IconButton(
                              tooltip: context.l.text('应用', 'Apply'),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.check_rounded),
                              onPressed: () {
                                final path = _wallpaperController.text.trim();
                                if (path.isEmpty) {
                                  notifier.setWallpaper(null);
                                  return;
                                }
                                if (!File(path).existsSync()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(context.l.text(
                                        '文件不存在，请检查路径',
                                        'File not found. Check the path.',
                                      )),
                                    ),
                                  );
                                  return;
                                }
                                notifier.setWallpaper(path);
                              },
                            ),
                            IconButton(
                              tooltip: context.l.text('清除', 'Clear'),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _wallpaperController.clear();
                                notifier.setWallpaper(null);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l.text(
                          '填写手机上图片的完整路径。留空则使用主色光晕背景。',
                          'Enter the full path to an image on this device. Leave empty for the accent glow background.',
                        ),
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.75),
                        ),
                      ),
                      if (settings.wallpaperPath != null) ...[
                        const SizedBox(height: 12),
                        SliderRow(
                          label: context.l.wallpaperDim,
                          desc: context.l.text('数值越大壁纸越淡，文字越清晰', 'Higher values soften the wallpaper and improve text clarity'),
                          value: settings.wallpaperOpacity,
                          min: 0,
                          max: 0.9,
                          divisions: 18,
                          onChanged: notifier.setWallpaperOpacity,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.text('动画与语言', 'Animation & language'),
                    children: [
                      SwitchRow(
                        label: context.l.animation,
                        desc: context.l.text('关闭后页面和组件不再播放过渡效果', 'Pages and components will not animate when disabled'),
                        icon: Icons.animation_rounded,
                        value: settings.enableAnimation,
                        onChanged: notifier.setEnableAnimation,
                      ),
                      if (settings.enableAnimation) ...[
                        const SizedBox(height: 8),
                        SliderRow(
                          label: context.l.animationSpeed,
                          value: settings.animationSpeed,
                          min: 0.25,
                          max: 3,
                          divisions: 11,
                          onChanged: notifier.setAnimationSpeed,
                        ),
                      ],
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: settings.languageCode,
                        decoration: InputDecoration(
                          labelText: context.l.language,
                          prefixIcon: const Icon(Icons.language_rounded),
                        ),
                        items: [
                          DropdownMenuItem(value: 'system', child: Text(context.l.languageSystem)),
                          DropdownMenuItem(value: 'zh', child: Text(context.l.languageZh)),
                          DropdownMenuItem(value: 'en', child: Text(context.l.languageEn)),
                        ],
                        onChanged: (value) {
                          if (value != null) notifier.setLanguageCode(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.contextManagement,
                    children: [
                      SegmentedButton<int>(
                        segments: [
                          ButtonSegment(
                            value: 0,
                            icon: const Icon(Icons.content_cut_rounded, size: 17),
                            label: Text(context.l.strategyTruncate),
                          ),
                          ButtonSegment(
                            value: 1,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                            label: Text(context.l.strategySummary),
                          ),
                        ],
                        selected: {settings.contextStrategy},
                        onSelectionChanged: (value) =>
                            notifier.setContextStrategy(value.first),
                        showSelectedIcon: false,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.contextStrategy == 0
                            ? context.l.strategyTruncateHint
                            : context.l.strategySummaryHint,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (settings.contextStrategy == 1) ...[
                        const SizedBox(height: 8),
                        SliderRow(
                          label: context.l.summaryTrigger,
                          value: settings.summaryTriggerCount.toDouble(),
                          min: 10,
                          max: 80,
                          divisions: 14,
                          isInt: true,
                          onChanged: (v) => notifier.setSummaryTriggerCount(v.round()),
                        ),
                        SliderRow(
                          label: context.l.summaryKeepRecent,
                          value: settings.summaryKeepRecent.toDouble(),
                          min: 2,
                          max: 20,
                          divisions: 18,
                          isInt: true,
                          onChanged: (v) => notifier.setSummaryKeepRecent(v.round()),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 排版
                  SectionCard(
                    title: context.l.text('排版', 'Typography'),
                    children: [
                      SliderRow(
                        label: context.l.fontScale,
                        value: settings.fontScale,
                        min: 0.8,
                        max: 1.5,
                        divisions: 14,
                        onChanged: notifier.setFontScale,
                      ),
                      SliderRow(
                        label: context.l.bubbleRadius,
                        value: settings.bubbleRadius,
                        min: 6,
                        max: 32,
                        divisions: 26,
                        isInt: true,
                        onChanged: notifier.setBubbleRadius,
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

/// 顶部实时预览：一问一答的缩略气泡
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = settings.bubbleRadius;

    return SectionCard(
      title: context.l.text('预览', 'Preview'),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  Color.lerp(scheme.primary, scheme.tertiary, 0.35) ??
                      scheme.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(radius),
                topRight: Radius.circular(radius),
                bottomLeft: Radius.circular(radius),
                bottomRight: const Radius.circular(6),
              ),
            ),
            child: Text(
              context.l.text('这是我发送的消息', 'This is my message'),
              style: TextStyle(
                fontSize: 14,
                color: scheme.primary.computeLuminance() > 0.55
                    ? const Color(0xFF06322D)
                    : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: GlassContainer(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(radius),
              topRight: Radius.circular(radius),
              bottomLeft: const Radius.circular(6),
              bottomRight: Radius.circular(radius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              context.l.text('AI 的回复看起来是这样', 'This is how an AI reply looks'),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// 配色圆点
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l.text('主题色 $label', 'Accent color $label'),
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppTheme.fast,
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.onSurface : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: selected ? 12 : 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: selected
                    ? Center(
                        child: Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: color.computeLuminance() > 0.55
                              ? Colors.black87
                              : Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}