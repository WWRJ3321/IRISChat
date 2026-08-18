import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 通用毛玻璃容器。
///
/// 会自动读取主题里的 [GlassSpec]：
/// - 关闭毛玻璃时退化为普通半透明卡片（省性能）
/// - 开启时使用 BackdropFilter 做真实背景模糊
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blur,
    this.tint,
    this.showBorder = true,
    this.width,
    this.height,
    this.alignment,
    this.shadow = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  /// 覆盖主题模糊半径
  final double? blur;

  /// 覆盖玻璃填充色
  final Color? tint;

  final bool showBorder;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// 是否加一层柔和阴影（悬浮元素用）
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassSpec>() ??
        GlassSpec(
          enabled: true,
          blur: 24,
          opacity: 0.14,
          isDark: theme.brightness == Brightness.dark,
          radius: AppTheme.rLg,
        );

    final radius = borderRadius ?? BorderRadius.circular(AppTheme.rLg);
    final fill = tint ??
        (glass.enabled
            ? glass.tint
            : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.96));

    Widget content = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: radius,
        border:
            showBorder ? Border.all(color: glass.border, width: 0.8) : null,
      ),
      child: child,
    );

    if (glass.enabled) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          // decal 模式让模糊只作用于容器内部区域，
          // 避免边缘外溢出现「黑雾」拖影
          blendMode: BlendMode.srcOver,
          filter: ImageFilter.blur(
            sigmaX: blur ?? glass.blur,
            sigmaY: blur ?? glass.blur,
            tileMode: TileMode.decal,
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(borderRadius: radius, child: content);
    }

    if (shadow) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: glass.isDark ? 0.38 : 0.09),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

/// 顶部/底部的毛玻璃条（状态栏、输入栏背景）。
/// 与 GlassContainer 的区别是它贴边使用，圆角通常为零。
class GlassBar extends StatelessWidget {
  const GlassBar({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.borderSide,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// 例如只画底边分割线
  final Border? borderSide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassSpec>();
    final enabled = glass?.enabled ?? true;
    final radius = borderRadius ?? BorderRadius.zero;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: enabled
            ? (glass!.isDark
                ? Colors.black.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.60))
            : theme.colorScheme.surface.withValues(alpha: 0.97),
        borderRadius: radius,
        border: borderSide,
      ),
      child: child,
    );

    if (enabled) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass!.blur,
            sigmaY: glass.blur,
            tileMode: TileMode.decal,
          ),
          child: content,
        ),
      );
    }
    return content;
  }
}

/// 背景层：主色光晕渐变 +（可选）用户自定义壁纸。
///
/// 放在 Scaffold 的最底层，让上方的毛玻璃有东西可以「糊」。
/// 光晕整体裁剪在屏幕内并且不参与滚动，避免被上层模糊拖出拖影。
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.wallpaperPath,
    this.wallpaperOpacity = 0.35,
    this.oledBlack = false,
  });

  final Widget child;
  final String? wallpaperPath;
  final double wallpaperOpacity;
  final bool oledBlack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final base = oledBlack && isDark ? Colors.black : scheme.surface;
    final hasWallpaper = wallpaperPath != null && wallpaperPath!.isNotEmpty;
    final showGlow = !(oledBlack && isDark) && !hasWallpaper;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底色 + 光晕：整层裁剪，杜绝溢出到边界之外
        Positioned.fill(
          child: ClipRect(
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: base),

                  // 自定义壁纸
                  if (hasWallpaper)
                    Positioned.fill(
                      child: Image.file(
                        File(wallpaperPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),

                  // 壁纸蒙层：保证前景文字可读
                  if (hasWallpaper)
                    Positioned.fill(
                      child: ColoredBox(
                        color: base.withValues(
                          alpha: wallpaperOpacity.clamp(0.0, 1.0),
                        ),
                      ),
                    ),

                  // 主色光晕：只在无壁纸、非纯黑时出现，且只放在顶部
                  // （底部光晕会被输入框的毛玻璃反复采样，形成「黑雾」跟随感）
                  if (showGlow)
                    Positioned(
                      top: -150,
                      right: -110,
                      child: _Glow(
                        color: scheme.primary
                            .withValues(alpha: isDark ? 0.20 : 0.26),
                        size: 360,
                      ),
                    ),
                  if (showGlow)
                    Positioned(
                      top: 120,
                      left: -140,
                      child: _Glow(
                        color: scheme.tertiary
                            .withValues(alpha: isDark ? 0.13 : 0.18),
                        size: 320,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}