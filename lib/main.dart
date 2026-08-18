import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/services/storage_service.dart';
import 'i18n/strings.dart';
import 'pages/chat_page.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 沉浸式：内容延伸到状态栏与底部手势条区域
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );

  // 本地存储必须在读取设置之前初始化
  await StorageService.instance.init();

  runApp(const ProviderScope(child: AiChatApp()));
}

class AiChatApp extends ConsumerWidget {
  const AiChatApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final motion = settings.animationsActive;

    return MaterialApp(
      title: 'IRIS Chat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings),
      darkTheme: AppTheme.dark(settings),
      themeMode: switch (settings.themeModeIndex) {
        0 => ThemeMode.light,
        1 => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      // 主题切换时平滑过渡（关闭动画时归零）
      themeAnimationDuration: motion ? AppTheme.normal : Duration.zero,
      themeAnimationCurve: AppTheme.ease,
      locale: L.localeOf(settings.languageCode),
      supportedLocales: L.supportedLocales,
      localizationsDelegates: L.delegates,
      home: const ChatPage(),
      builder: (context, child) {
        final base = MediaQuery.of(context);
        // 字号缩放：统一在根节点注入，保证全局生效
        return MediaQuery(
          data: base.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
            disableAnimations: !motion,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}