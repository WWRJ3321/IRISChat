import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_version.dart';
import '../i18n/strings.dart';
import '../state/settings_provider.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';

class ChangelogPage extends ConsumerWidget {
  const ChangelogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            GlassPageBar(title: context.l.changelog),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
                itemCount: AppVersion.changelog.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _ReleaseCard(
                  note: AppVersion.changelog[index],
                  scheme: scheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({required this.note, required this.scheme});

  final ReleaseNote note;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'V${note.version}',
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  note.date,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            _ChangeGroup(
              title: context.l.text('新增', 'Added'),
              items: note.addedFor(context.l.isZh),
              color: scheme.primary,
            ),
            _ChangeGroup(
              title: context.l.text('修复', 'Fixed'),
              items: note.fixedFor(context.l.isZh),
              color: scheme.tertiary,
            ),
            _ChangeGroup(
              title: context.l.text('调整', 'Changed'),
              items: note.changedFor(context.l.isZh),
              color: scheme.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeGroup extends StatelessWidget {
  const _ChangeGroup({
    required this.title,
    required this.items,
    required this.color,
  });

  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '• $item',
                style: TextStyle(
                  color: scheme.onSurface.withValues(alpha: 0.9),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
