import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

/// 毛玻璃分组卡片，设置页与编辑页共用
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.rLg),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: scheme.primary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// 带标签的输入框
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextAlign textAlign;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

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
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  minLines: minLines,
                  maxLength: maxLength,
                  textAlign: textAlign,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
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
              if (suffix != null) suffix!,
            ],
          ),
        ),
      ],
    );
  }
}

/// 带数值徽标的滑块行
class SliderRow extends StatelessWidget {
  const SliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.desc,
    this.divisions,
    this.isInt = false,
    this.suffixText = '',
  });

  final String label;
  final String? desc;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final bool isInt;
  final String suffixText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final display =
        (isInt ? '${value.round()}' : value.toStringAsFixed(2)) + suffixText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppTheme.rPill),
                ),
                child: Text(
                  display,
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
            label: display,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 开关行
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.desc,
    this.icon,
  });

  final String label;
  final String? desc;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(AppTheme.rSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19, color: scheme.onSurfaceVariant),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (desc != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        desc!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            PillSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// 饱满的胶囊开关：比 Material 默认 Switch 更圆润、对比更强。
///
/// 关闭时轨道用中性灰、圆钮偏左；开启时轨道填主色、圆钮偏右并微微放大。
class PillSwitch extends StatelessWidget {
  const PillSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.width = 52,
    this.height = 30,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onChanged != null;
    final pad = height * 0.11;
    final knob = height - pad * 2;

    final track = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.18)
        : (value
            ? scheme.primary
            : scheme.onSurfaceVariant.withValues(alpha: 0.30));
    // 开启时圆钮用深色，在亮主色上更清晰
    final knobColor = value
        ? (scheme.primary.computeLuminance() > 0.55
            ? const Color(0xFF06322D)
            : Colors.white)
        : scheme.surface;

    return Semantics(
      toggled: value,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          curve: AppTheme.ease,
          width: width,
          height: height,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(AppTheme.rPill),
            boxShadow: value && enabled
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: AppTheme.fast,
            curve: AppTheme.ease,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: knob,
              height: knob,
              decoration: BoxDecoration(
                color: knobColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 可点击的设置行
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.label,
    this.desc,
    this.icon,
    this.trailingText,
    this.onTap,
    this.danger = false,
  });

  final String label;
  final String? desc;
  final IconData? icon;
  final String? trailingText;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.rSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 19,
                color: danger ? scheme.error : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 11),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                  if (desc != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        desc!,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color:
                              scheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );
  }
}

/// 顶部毛玻璃标题栏（子页面共用）
class GlassPageBar extends StatelessWidget {
  const GlassPageBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GlassBar(
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.viewPaddingOf(context).top + 6,
        8,
        8,
      ),
      borderSide: Border(
        bottom: BorderSide(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.35),
          width: 0.6,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: context.l.text('返回', 'Back'),
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}