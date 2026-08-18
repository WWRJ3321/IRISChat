import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models/app_settings.dart';

/// 青色主题体系。
///
/// 设计原则：
/// - 主色可自定义，默认 #14E2CE
/// - 深色模式下支持 OLED 纯黑
/// - 圆角统一走大圆角（圆润卡片）
/// - 所有过渡动画统一时长与曲线，且受设置里的速度倍率控制
class AppTheme {
  AppTheme._();

  static const Color magicCyan = Color(0xFF14E2CE);

  // ------------------------------------------------------------ 动效基准值
  static const Duration fastBase = Duration(milliseconds: 160);
  static const Duration normalBase = Duration(milliseconds: 260);
  static const Duration slowBase = Duration(milliseconds: 400);

  /// 当前生效的动效时长，由 [applyMotion] 根据设置刷新。
  ///
  /// 之所以做成全局静态量，是因为大量无状态组件里直接引用 AppTheme.fast，
  /// 让它们全部去 watch 设置会带来不必要的重建成本。
  static Duration fast = fastBase;
  static Duration normal = normalBase;
  static Duration slow = slowBase;

  /// 动画是否启用（关闭时所有时长归零）
  static bool motionEnabled = true;

  static const Curve ease = Curves.easeOutCubic;
  static const Curve springy = Curves.easeOutBack;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  /// 根据设置刷新动效时长。在构建主题时调用。
  static void applyMotion(AppSettings s) {
    motionEnabled = s.animationsActive;
    if (!motionEnabled) {
      fast = Duration.zero;
      normal = Duration.zero;
      slow = Duration.zero;
      return;
    }
    // 速度倍率越大越快，所以是除法
    final k = s.animationSpeed.clamp(0.25, 3.0);
    fast = _scale(fastBase, k);
    normal = _scale(normalBase, k);
    slow = _scale(slowBase, k);
  }

  static Duration _scale(Duration base, double k) =>
      Duration(microseconds: (base.inMicroseconds / k).round());

  // ------------------------------------------------------------ 圆角常量
  // 参考「圆润卡片」风格：整体比 Material 默认更大，视觉更柔和。
  static const double rSm = 14;
  static const double rMd = 20;
  static const double rLg = 28;
  static const double rXl = 36;
  static const double rPill = 999;

  /// 亮色主题
  static ThemeData light(AppSettings s) {
    applyMotion(s);
    final accent = Color(s.accentColorValue);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.light,
    ).copyWith(
      primary: accent,
      secondary: accent,
    );
    return _build(scheme, s, isDark: false);
  }

  /// 深色主题（可 OLED 纯黑）
  static ThemeData dark(AppSettings s) {
    applyMotion(s);
    final accent = Color(s.accentColorValue);
    var scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      primary: accent,
      secondary: accent,
    );

    if (s.oledBlack) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF080808),
        surfaceContainer: const Color(0xFF0D0D0D),
        surfaceContainerHigh: const Color(0xFF141414),
        surfaceContainerHighest: const Color(0xFF1A1A1A),
      );
    }
    return _build(scheme, s, isDark: true);
  }

  static ThemeData _build(
    ColorScheme scheme,
    AppSettings s, {
    required bool isDark,
  }) {
    final radius = s.bubbleRadius;
    final motion = s.animationsActive;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark && s.oledBlack ? Colors.black : scheme.surface,
      splashFactory:
          motion ? InkSparkle.splashFactory : NoSplash.splashFactory,
      visualDensity: VisualDensity.standard,

      // 圆润卡片
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rLg),
        ),
        margin: EdgeInsets.zero,
      ),

      // 透明 AppBar，交给毛玻璃层去画背景
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),

      // 输入框：无边框胶囊，配合毛玻璃容器
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rPill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rPill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rPill),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
          fontSize: 15,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rSm),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rPill),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rSm),
          ),
        ),
      ),

      // 底部弹窗：顶部大圆角
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(rXl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rXl),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rPill),
        ),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary.withValues(alpha: 0.18),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.primary.withValues(alpha: 0.18),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        trackHeight: 4,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? Colors.white
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (st) => st.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 0.6,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
        ),
        elevation: 0,
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(rSm),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),

      // 页面切换动画：淡入 + 轻微上移；关闭动画时用无转场
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: motion
                ? const _FadeUpTransitionBuilder()
                : const _NoTransitionBuilder(),
        },
      ),
    ).copyWith(
      extensions: [
        GlassSpec(
          enabled: s.glassEnabled,
          blur: s.glassBlur,
          opacity: s.glassOpacity,
          isDark: isDark,
          radius: radius,
        ),
      ],
    );
  }
}

/// 自定义页面转场：淡入 + 从下轻微滑入，比默认更柔和。
class _FadeUpTransitionBuilder extends PageTransitionsBuilder {
  const _FadeUpTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppTheme.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    // 退出时轻微缩放，让层级关系更清晰
    final outgoing = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 0.985).animate(outgoing),
          child: child,
        ),
      ),
    );
  }
}

/// 关闭动画时使用：直接切换，无过渡。
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      child;
}

/// 毛玻璃规格，通过 ThemeExtension 下发给各组件，避免到处传参。
class GlassSpec extends ThemeExtension<GlassSpec> {
  const GlassSpec({
    required this.enabled,
    required this.blur,
    required this.opacity,
    required this.isDark,
    required this.radius,
  });

  final bool enabled;
  final double blur;
  final double opacity;
  final bool isDark;
  final double radius;

  /// 玻璃层的填充色
  Color get tint => isDark
      ? Colors.white.withValues(alpha: opacity * 0.55)
      : Colors.white.withValues(alpha: 0.35 + opacity);

  /// 玻璃边框色
  Color get border => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.white.withValues(alpha: 0.55);

  @override
  GlassSpec copyWith({
    bool? enabled,
    double? blur,
    double? opacity,
    bool? isDark,
    double? radius,
  }) {
    return GlassSpec(
      enabled: enabled ?? this.enabled,
      blur: blur ?? this.blur,
      opacity: opacity ?? this.opacity,
      isDark: isDark ?? this.isDark,
      radius: radius ?? this.radius,
    );
  }

  @override
  GlassSpec lerp(ThemeExtension<GlassSpec>? other, double t) {
    if (other is! GlassSpec) return this;
    return GlassSpec(
      enabled: t < 0.5 ? enabled : other.enabled,
      blur: (blur + (other.blur - blur) * t),
      opacity: (opacity + (other.opacity - opacity) * t),
      isDark: t < 0.5 ? isDark : other.isDark,
      radius: (radius + (other.radius - radius) * t),
    );
  }
}