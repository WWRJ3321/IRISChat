import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_version.dart';
import '../i18n/strings.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/form_widgets.dart';
import '../widgets/glass.dart';
import 'changelog_page.dart';


/// 关于页
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

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
            GlassPageBar(title: context.l.about),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 40),
                children: [
                  // 应用头部
                  Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.rXl - 4),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.32),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: scheme.primary,
                            child: const Center(
                              child: Text('🌙',
                                  style: TextStyle(fontSize: 42)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.l.appName,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${context.l.version} ${AppVersion.current}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SectionCard(
                    title: context.l.version,
                    children: [
                      NavRow(
                        label: context.l.changelog,
                        desc: context.l.text('查看各版本的新增、修复与调整', 'View additions, fixes and adjustments by version'),
                        icon: Icons.history_rounded,
                        trailingText: 'V${AppVersion.current}',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangelogPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.text('这是什么', 'What is this?'),
                    children: [
                      Text(
                        context.l.text(
                          '一个纯本地的 AI 对话客户端。你自己填 API 地址和密钥，应用只负责把消息发给你指定的服务，不经过任何中间服务器。所有对话、角色卡与配置都保存在这台设备上。',
                          'A local-first AI chat client. You provide your API URL and key; the app sends messages directly to the service you choose, with no intermediary server. Conversations, characters and settings stay on this device.',
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.65,
                          color: scheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.coreFeatures,
                    children: [
                      _FeatureRow(
                        icon: Icons.bolt_rounded,
                        title: context.l.streamOutput,
                        desc: context.l.text('逐字显示回复，可随时中断生成', 'Show replies as they arrive; stop generation at any time'),
                      ),
                      _FeatureRow(
                        icon: Icons.account_tree_outlined,
                        title: context.l.text('对话分支', 'Conversation branches'),
                        desc: context.l.text('重新生成或编辑消息会创建新分支，用 1/3 页码自由切换', 'Regenerating or editing creates a branch; switch with the 1/3 pager'),
                      ),
                      _FeatureRow(
                        icon: Icons.code_rounded,
                        title: context.l.text('Markdown 与代码高亮', 'Markdown and code highlighting'),
                        desc: context.l.text('表格、列表、公式块与代码块一键复制', 'Copy tables, lists, math blocks and code blocks in one tap'),
                      ),
                      _FeatureRow(
                        icon: Icons.person_outline_rounded,
                        title: context.l.characters,
                        desc: context.l.text('系统提示词与采样参数打包管理，随时切换', 'Bundle system prompts and sampling parameters, then switch anytime'),
                      ),
                      _FeatureRow(
                        icon: Icons.palette_outlined,
                        title: context.l.text('外观自定义', 'Appearance customization'),
                        desc: context.l.text('主色、OLED 纯黑、毛玻璃强度、自定义壁纸', 'Accent color, OLED black, glass strength and custom wallpaper'),
                      ),
                      _FeatureRow(
                        icon: Icons.lock_outline_rounded,
                        title: context.l.text('本地存储', 'Local storage'),
                        desc: context.l.text('数据不出设备，可导出备份 JSON', 'Data stays on-device and can be exported as JSON'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SectionCard(
                    title: context.l.text('隐私', 'Privacy'),
                    children: [
                      Text(
                        context.l.text(
                          'API 密钥仅以明文保存在应用私有存储中，不会上传。对话内容只发送给你自己配置的 API 服务商。导出备份包含密钥，请注意保管。',
                          'API keys are stored in the app private storage as plaintext and are never uploaded. Conversation content is sent only to the API provider you configure. Exports include API keys, so store them carefully.',
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: Text(
                      context.l.text('由 WWRJ 与虹月共同构建', 'Built together by WWRJ and IRIS Selene'),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppTheme.rSm),
            ),
            child: Icon(icon, size: 18, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
